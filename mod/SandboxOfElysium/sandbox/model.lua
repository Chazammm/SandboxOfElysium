local M = {}
function M.copy(value)
    if type(value) ~= 'table' then return value end
    local out = {}; for k,v in pairs(value) do out[k] = M.copy(v) end; return out
end
function M.new()
    return {version=1, terrain=0, size='Native automatic', colors={1,2}, units={}, nextId=1}
end
M.colors = {
    {'Blue',0.15,0.40,1}, {'Red',1,0.18,0.16}, {'Green',0.20,0.8,0.25},
    {'Yellow',1,0.85,0.15}, {'Purple',0.70,0.25,0.9}, {'Orange',1,0.50,0.10},
    {'Turquoise',0.10,0.85,0.85},
}
function M.cells(kind, n, x, y)
    local out = {}; n = math.max(1,math.min(15,math.floor(n or 1)))
    local w,h = 1,1
    if kind=='Horizontal Row' then w=n elseif kind=='Vertical Row' then h=n
    elseif kind=='Square' then w=math.max(2,math.min(4,n)); h=w end
    for dy=0,h-1 do for dx=0,w-1 do out[#out+1]={x+dx,y+dy} end end
    return out
end
function M.at(s,x,y)
    for _,u in ipairs(s.units) do if u.x==x and u.y==y then return u end end
end
function M.count(s,team,monster)
    local n=0; for _,u in ipairs(s.units) do
        if (not team or u.team==team) and (not monster or u.monster==monster) then n=n+1 end
    end; return n
end
function M.add(s,monster,name,team,x,y,template)
    local u=template and M.copy(template) or {monster=monster,name=name,items={},spells={}}
    u.id=s.nextId; s.nextId=s.nextId+1; u.team=team; u.x=x; u.y=y
    s.units[#s.units+1]=u; return u
end
function M.remove(s,id)
    for i,u in ipairs(s.units) do if u.id==id then table.remove(s.units,i); return u end end
end
function M.encode(s,mods)
    local t={scenario={schema=1,terrain=s.terrain,size=s.size,a_color=s.colors[1],b_color=s.colors[2],count=#s.units},mods={}}
    for i,name in ipairs(mods) do t.mods[tostring(i)]=name end
    for i,u in ipairs(s.units) do
        local row={monster=u.monster,name=u.name,team=u.team,x=u.x,y=u.y,item_count=#u.items,spell_count=#u.spells}
        for j,v in ipairs(u.items) do row['item'..j]=v end
        for j,v in ipairs(u.spells) do row['spell'..j]=v end
        -- A baseline is evidence about native initialization, not an arbitrary serialized unit.
        if u.baseline then
            row.known_count=#u.baseline.known
            for j,v in ipairs(u.baseline.known) do row['known'..j]=v end
        end
        t['unit'..i]=row
    end; return t
end
local function integer(v,low,high)
    v=tonumber(v); if not v or v%1~=0 or v<low or v>high then return nil end; return v
end
function M.decode(t,catalog,activeMods)
    if type(t)~='table' or type(t.scenario)~='table' then return nil,'Missing scenario section' end
    local h=t.scenario
    if tonumber(h.schema)~=1 or tonumber(h.terrain)~=0 or h.size~='Native automatic' then return nil,'Unsupported scenario schema, terrain or field size' end
    local n=integer(h.count,0,2000); if not n then return nil,'Invalid unit count (maximum 2000)' end
    local mods={}; for _,name in ipairs(activeMods) do mods[name]=true end
    for _,name in pairs(t.mods or {}) do if not mods[name] then return nil,'Required active mod missing: '..name end end
    local s=M.new(); s.colors={integer(h.a_color,1,7),integer(h.b_color,1,7)}
    if not s.colors[1] or not s.colors[2] then return nil,'Invalid team color' end
    for i=1,n do
        local r=t['unit'..i]; if type(r)~='table' then return nil,'Missing unit '..i end
        local id=integer(r.monster,0,100000); local m=id and catalog.byId[id]
        if not m or m.name~=r.name then return nil,'Missing or changed unit: '..tostring(r.name)..' (#'..tostring(r.monster)..')' end
        local team,x,y=integer(r.team,1,2),integer(r.x,0,999),integer(r.y,0,19)
        if not team or not x or not y or M.at(s,x,y) then return nil,'Invalid or overlapping position for unit '..i end
        local ni,ns=integer(r.item_count,0,8),integer(r.spell_count,0,30)
        if not ni or not ns then return nil,'Invalid equipment/spell list' end
        if not r.known_count and (ni>0 or ns>0) then return nil,'Configured unit is missing its native baseline' end
        local u=M.add(s,id,r.name,team,x,y)
        for j=1,ni do local v=r['item'..j]; if not catalog.itemNames[v] then return nil,'Missing item: '..tostring(v) end; u.items[j]=v end
        for j=1,ns do local v=r['spell'..j]; if not catalog.spellKeys[v] then return nil,'Missing or changed spell: '..tostring(v) end; u.spells[j]=v end
        if r.known_count then
            local nk=integer(r.known_count,0,60); if not nk then return nil,'Invalid known spells' end
            u.baseline={known={}}
            for j=1,nk do local v=r['known'..j]; if not catalog.spellKeys[v] then return nil,'Missing or changed known spell: '..tostring(v) end; u.baseline.known[j]=v end
        end
    end; return s
end
return M
