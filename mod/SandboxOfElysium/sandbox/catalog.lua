local C={}
function C.read(api)
    local c={monsters={},byId={},items={},itemNames={},itemSlots={},spells={},spellNames={},spellKeys={},mods={},terrains={}}
    local slots={}
    for i=0,api.get('modLastIndex') do
        if api.get('modEnabled',i)~=0 then c.mods[#c.mods+1]=api.get('modName',i) end
    end
    for i=0,api.get('monsterLastIndex') do
        local name=api.get('monsterName',i)
        if name and name~='' then
            local m={id=i,name=name,sprite=api.get('monsterSprite',i),categories={}}
            for _,word in ipairs({'undead','demonic','animal','human','flying'}) do
                if api.get('monster',i,word) then m.categories[word]=true end
            end
            if api.monsterHasRanged(i) then m.categories.ranged=true end
            c.monsters[#c.monsters+1]=m; c.byId[i]=m
        end
    end
    table.sort(c.monsters,function(a,b) local x,y=a.name:lower(),b.name:lower(); return x==y and a.id<b.id or x<y end)
    for i=0,api.get('itemLastIndex') do
        local name=api.get('itemName',i)
        if name and name~='' then
            local slot=api.get('itemSlotType',i)
            c.items[#c.items+1]={id=i,name=name,slot=slot}
            if c.itemNames[name]~=nil then c.itemNames[name]=false else c.itemNames[name]=i end
            if slot~=nil then slots[slot]=true end
        end
    end
    table.sort(c.items,function(a,b)return a.name:lower()<b.name:lower() end)
    for slot in pairs(slots) do c.itemSlots[#c.itemSlots+1]=slot end;table.sort(c.itemSlots)
    -- spellInfo returns nil for holes. spellLastIndex is not a documented variable.
    for i=0,2999 do local info=api.spellInfo(i); if info then
        info.id=i; c.spells[#c.spells+1]=info
        c.spellKeys[i..':'..info.name]=i
        if c.spellNames[info.name]~=nil then c.spellNames[info.name]=false else c.spellNames[info.name]=i end
    end end
    for i=0,api.get('terrainLastIndex') do
        local name=api.get('terrainName',i)
        if name and name~='' then c.terrains[#c.terrains+1]={id=i,name=name,batmap=api.get('terrain',i,'batmap')} end
    end
    return c
end
function C.filter(c,search,category)
    local out={}; search=(search or ''):lower()
    for _,m in ipairs(c.monsters) do
        if m.name:lower():find(search,1,true) and (category=='All' or m.categories[category]) then out[#out+1]=m end
    end; return out
end
return C
