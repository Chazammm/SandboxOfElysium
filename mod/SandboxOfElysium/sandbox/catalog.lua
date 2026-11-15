local C={}
local M=require('sandbox.model')
-- SDL text is UTF-8. Keep editing/truncation on codepoint boundaries and fold
-- the Latin characters used by the German UI without depending on OS locale.
function C.fold(text)
    text=(text or ''):lower()
    if not utf8 then return text end
    local ok,result=pcall(function()
        local out={}
        for _,cp in utf8.codes(text) do
            if cp>=0xC0 and cp<=0xD6 or cp>=0xD8 and cp<=0xDE then cp=cp+32
            elseif cp==0x1E9E then cp=0xDF end
            out[#out+1]=utf8.char(cp)
        end
        return table.concat(out)
    end)
    return ok and result or text
end
function C.textLimit(text,count,tail)
    text=text or '';tail=tail or ''
    if utf8 then
        local ok,at=pcall(utf8.offset,text,count+1)
        if ok then return at and at<=#text and text:sub(1,at-1)..tail or text end
    end
    return #text>count and text:sub(1,count)..tail or text
end
function C.backspace(text)
    if text=='' then return text end
    if utf8 then local ok,at=pcall(utf8.offset,text,-1);if ok and at then return text:sub(1,at-1) end end
    return text:sub(1,-2)
end
function C.origin(api,kind,id)
    if type(api.loadedContentOrigin)=='function'then
        local ok,value=pcall(api.loadedContentOrigin,kind,id)
        if ok and type(value)=='table' and value.id==id and type(value.kind)=='string' and type(value.modded)=='boolean'then return value end
    end
    return {id=id,kind='unknown',modded=false,observed=false,scope='loaded-content provenance unavailable'}
end
function C.schoolOrigin(c,api,path)
    c.schoolOrigins=c.schoolOrigins or {}
    if not c.schoolOrigins[path]then c.schoolOrigins[path]=C.origin(api,'spellschool',path)end
    local origin=M.copy(c.schoolOrigins[path]);local spells=c.modSpellSchools and c.modSpellSchools[path]
    if spells then origin.modded=true;origin.hasModSpells=true;origin.spellMods=spells end
    return origin
end
function C.read(api)
    local c={monsters={},byId={},items={},itemNames={},itemSlots={},spells={},spellNames={},spellKeys={},mods={},terrains={},terrainById={},testFieldTerrains={},rangedUnknown=0}
    if type(api.testFieldTerrains)=='function' then
        local ok,ids=pcall(api.testFieldTerrains)
        if ok and type(ids)=='table' then for _,id in ipairs(ids) do
            if M.terrainNames[id] then c.testFieldTerrains[id]=true end
        end end
    end
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
            local ranged=api.monsterHasRanged(i)
            if ranged==true then m.categories.ranged=true
            elseif ranged~=false then c.rangedUnknown=c.rangedUnknown+1 end
            c.monsters[#c.monsters+1]=m; c.byId[i]=m
        end
    end
    table.sort(c.monsters,function(a,b) local x,y=C.fold(a.name),C.fold(b.name); return x==y and a.id<b.id or x<y end)
    for i=0,api.get('itemLastIndex') do
        local name=api.get('itemName',i)
        if name and name~='' then
            local slot=api.get('itemSlotType',i)
            local item={id=i,name=name,slot=slot,origin=C.origin(api,'item',i)};c.items[#c.items+1]=item
            c.byItemId=c.byItemId or {};c.byItemId[i]=item
            if c.itemNames[name]~=nil then c.itemNames[name]=false else c.itemNames[name]=i end
            if slot~=nil then slots[slot]=true end
        end
    end
    table.sort(c.items,function(a,b)return a.name:lower()<b.name:lower() end)
    for slot in pairs(slots) do c.itemSlots[#c.itemSlots+1]=slot end;table.sort(c.itemSlots)
    -- Extended tables may exceed the old hard-coded 3000-ID scan. Read the
    -- actual loaded capacity when the local API exposes it, including holes.
    local spellLast=2999
    if type(api.testFieldEditorCapabilities)=='function' then
        local ok,caps=pcall(api.testFieldEditorCapabilities)
        local records=ok and type(caps)=='table' and caps.spellRecords
        if type(records)=='number' and records%1==0 and records>0 and records<=4096 then spellLast=records-1 end
    end
    for i=0,spellLast do local info=api.spellInfo(i); if info then
        info.origin=C.origin(api,'spell',i)
        if info.origin.modded then
            c.modSpellSchools=c.modSpellSchools or {};c.modSpellSchools[info.path]=c.modSpellSchools[info.path]or {}
            local source=info.origin.lastModifiedBy or info.origin.definedBy or 'observed mod spell'
            c.modSpellSchools[info.path][source]=true
        end
        info.id=i; c.spells[#c.spells+1]=info
        c.spellKeys[i..':'..info.name]=i
        if c.spellNames[info.name]~=nil then c.spellNames[info.name]=false else c.spellNames[info.name]=i end
    end end
    for i=0,api.get('terrainLastIndex') do
        local name=api.get('terrainName',i)
        if name and name~='' then local t={id=i,name=name,batmap=api.get('terrain',i,'batmap')};c.terrains[#c.terrains+1]=t;c.terrainById[i]=t end
    end
    for id in pairs(c.testFieldTerrains) do
        if not c.terrainById[id] or c.terrainById[id].name~=M.terrainNames[id] then c.testFieldTerrains[id]=nil end
    end
    return c
end
function C.filter(c,search,category)
    local out={}; search=C.fold(search)
    for _,m in ipairs(c.monsters) do
        if C.fold(m.name):find(search,1,true) and (category=='All' or m.categories[category]) then out[#out+1]=m end
    end; return out
end
return C
