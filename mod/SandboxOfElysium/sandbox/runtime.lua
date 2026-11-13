local M=require('sandbox.model')
local R={}; R.__index=R
local function same(a,b)
    if #a~=#b then return false end
    local x,y=M.copy(a),M.copy(b); table.sort(x);table.sort(y)
    for i,v in ipairs(x) do if y[i]~=v then return false end end; return true
end
function R.new(api,catalog)
    return setmetatable({api=api,catalog=catalog,live={},open=false},R)
end
function R:inventory(unit)
    local t={}; for i=0,7 do local item=self.api.get('unitItem',unit,i)
        if item and item>=0 then t[#t+1]=self.api.get('itemName',item) end
    end; return t
end
function R:spellList(unit,key,max)
    local t={}; for i=0,max do local id=self.api.get(key,unit,i); if not id or id<0 then break end
        local info=self.api.spellInfo(id); if info then t[#t+1]=id..':'..info.name end
    end; return t
end
function R:configure(u,unit)
    local known=self:spellList(unit,'unitKnownSpell',59)
    if u.baseline and not same(known,u.baseline.known) then return false,'Native starting spells changed for '..u.name..'; exact restoration unavailable' end
    if not u.baseline then
        u.baseline={known=known}; u.items=self:inventory(unit); u.spells=self:spellList(unit,'unitMemorizedSpell',29)
    else
        for _,name in ipairs(u.items) do if not self.catalog.itemNames[name] then return false,'Missing or ambiguous item: '..name end end
        for _,name in ipairs(u.spells) do if not self.catalog.spellKeys[name] then return false,'Missing or changed spell: '..name end end
        -- Never silently replace existing intrinsic/random inventory on restoration.
        local current=self:inventory(unit)
        if not same(current,u.items) then
            for _,name in ipairs(current) do self.api.takeItem(unit,name) end
            for _,name in ipairs(u.items) do self.api.giveItem(unit,name) end
            if not same(self:inventory(unit),u.items) then return false,'Equipment restoration refused by game: '..u.name end
        end
        for _,name in ipairs(self:spellList(unit,'unitMemorizedSpell',29)) do
            if not self.catalog.spellKeys[name] then return false,'Missing or changed spell: '..name end
            self.api.unmemorizeSpell(unit,self.catalog.spellKeys[name])
        end
        for _,name in ipairs(u.spells) do
            local found=false; for _,k in ipairs(known) do if name==k then found=true end end
            if not found then return false,'Spell is no longer known: '..name end
            self.api.memorizeSpell(unit,self.catalog.spellKeys[name])
        end
        if not same(self:spellList(unit,'unitMemorizedSpell',29),u.spells) then return false,'Spell memorization rejected: '..u.name end
    end
    return true
end
function R:close()
    if self.open then self.api.closeTestField() end; self.open=false; self.live={}
    if self.savedColors then
        for team,slot in ipairs({0,24}) do for j,key in ipairs({'slotColorRed','slotColorGreen','slotColorBlue'}) do self.api.set(key,slot,self.savedColors[team][j]) end end
        self.savedColors=nil
    end
end
function R:build(s)
    self:close()
    local a,b={},{}; for _,u in ipairs(s.units) do local list=u.team==1 and a or b; list[#list+1]=u end
    if #a==0 or #b==0 then return false,'Place at least one unit on each team' end
    local spec={commander=a[1].monster,spell=-1,friends={},enemies={}}
    for i=2,#a do spec.friends[#spec.friends+1]={a[i].monster,1} end
    for _,u in ipairs(b) do spec.enemies[#spec.enemies+1]={u.monster,1} end
    local ok,units=self.api.openTestField(spec)
    if not ok then return false,'The extender refused to open the test field' end
    self.open=true; self.width=self.api.get('battleWidth'); self.live[a[1].id]=units.commander
    for i=2,#a do self.live[a[i].id]=units.friends[i-1] end
    for i,u in ipairs(b) do self.live[u.id]=units.enemies[i] end
    self.savedColors={}; for team,slot in ipairs({0,24}) do
        self.savedColors[team]={}; local color=M.colors[s.colors[team]]
        for j,key in ipairs({'slotColorRed','slotColorGreen','slotColorBlue'}) do self.savedColors[team][j]=self.api.get(key,slot); self.api.set(key,slot,color[j+1]) end
    end
    -- Stage all units in free native cells before resolving permutations of occupied cells.
    -- Repeated passes handle acyclic moves; a no-progress cycle is refused, never auto-deployed.
    local waiting={}; for _,u in ipairs(s.units) do waiting[#waiting+1]=u end
    while #waiting>0 do
        local rest={}; local progress=false
        for _,u in ipairs(waiting) do
            local unit=self.live[u.id]
            if self.api.get('unitBattleX',unit)==u.x and self.api.get('unitBattleY',unit)==u.y or self.api.moveTestFieldUnit(unit,u.x,u.y) then progress=true else rest[#rest+1]=u end
        end
        if not progress then
            -- One parked unit can break a cycle, but never leave it at a fallback position.
            local parked=false
            for _,u in ipairs(rest) do
                for y=0,19 do for x=0,self.width-1 do
                    if not M.at(s,x,y) and self.api.moveTestFieldUnit(self.live[u.id],x,y) then parked=true; break end
                end; if parked then break end end
                if parked then break end
            end
            if not parked then self:close(); return false,'Native field rejected deployment (blocked, outside field or large footprint)' end
            self.parkCount=(self.parkCount or 0)+1
            if self.parkCount>#s.units+1 then self:close(); return false,'Native field cannot realize these positions' end
        end
        waiting=rest
    end
    self.parkCount=0
    for _,u in ipairs(s.units) do local good,why=self:configure(u,self.live[u.id]); if not good then self:close();return false,why end end
    return true
end
function R:move(u,x,y)
    if not self.api.moveTestFieldUnit(self.live[u.id],x,y) then return false,'Cell blocked, outside field, or unit does not fit' end
    u.x=x;u.y=y;return true
end
function R:add(s,monster,team,x,y,template)
    if M.at(s,x,y) or x<0 or x>=self.width or y<0 or y>=20 then return false,'Occupied or invalid cell' end
    -- The public API has no harmless removal of a deployed test unit. Rebuild a candidate transaction.
    local candidate=M.copy(s); local m=self.catalog.byId[monster]
    local u=M.add(candidate,monster,m.name,team,x,y,template)
    local ok,why=self:build(candidate)
    if ok then return true,candidate,u end
    local restored,reason=self:build(s)
    return false,why..(restored and '' or '; restore failed: '..tostring(reason))
end
function R:memorize(u,spellName,on)
    local unit=self.live[u.id];local spell=self.catalog.spellKeys[spellName]
    if not spell then return false end
    if on then self.api.memorizeSpell(unit,spell) else self.api.unmemorizeSpell(unit,spell) end
    u.spells=self:spellList(unit,'unitMemorizedSpell',29)
    for _,name in ipairs(u.spells) do if name==spellName then return on end end
    return not on
end
return R
