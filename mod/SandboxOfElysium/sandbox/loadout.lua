-- Exact, identity-based equipment/base-school configuration. All mutations go
-- through the separate owned-test-field native transaction, never templates.
local M=require('sandbox.model')
local Condition=require('sandbox.condition')
local L={}
L.slotNames={[0]='Unavailable',[1]='Weapon',[2]='Missile weapon',[3]='Helmet',[4]='Body armor',[5]='Gauntlets',[6]='Boots',[7]='Misc'}
function L.available(api)
    if type(api.testFieldLoadoutState)~='function' or type(api.setTestFieldConfiguration)~='function' then return false end
    if type(api.testFieldEditorCapabilities)=='function' then
        local ok,caps=pcall(api.testFieldEditorCapabilities)
        if ok and type(caps)=='table' and (caps.configuration==0 or caps.configuration==false) then return false end
    end
    return true
end
function L.read(r,unit)
    if not L.available(r.api) then return nil,'Equipment and base-school editing need the newer experimental Extender.' end
    local state,why=r.api.testFieldLoadoutState(unit)
    if type(state)~='table' or state.complete~=true then return nil,why or 'Native configuration readback is incomplete.' end
    if state.unit~=unit or type(state.items)~='table' or #state.items~=20 or type(state.schools)~='table' or
        #state.schools>16 or type(state.known)~='table' or #state.known>60 or type(state.memorized)~='table' or #state.memorized>30 then
        return nil,'Native configuration snapshot does not satisfy the complete-state contract.'
    end
    for p,row in ipairs(state.items) do
        if type(row)~='table' or row.position~=p-1 or type(row.id)~='number' or row.id%1~=0 or row.id < -1 or
            type(row.slotType)~='number' or row.slotType%1~=0 or row.slotType<0 or row.slotType>7 or
            (row.id>=0 and type(row.name)~='string') then return nil,'Native equipment positions are incomplete or invalid.' end
    end
    return state
end
function L.capture(r,u,state)
    local condition
    if Condition.available(r.api)then
        local why;condition,why=Condition.read(r,state.unit)
        if not condition then return false,why end
    end
    u.equipment={};u.schools={};u.items={}
    for _,row in ipairs(state.items) do if row.id>=0 then
        u.equipment[#u.equipment+1]={position=row.position,id=row.id,name=row.name}
        u.items[#u.items+1]=row.name
    end end
    for _,row in ipairs(state.schools) do u.schools[#u.schools+1]={path=row.path,name=row.name,base=row.base} end
    u.baseline=u.baseline or {};u.baseline.known=r:spellList(state.unit,'unitKnownSpell',59)
    u.spells=r:spellList(state.unit,'unitMemorizedSpell',29)
    if condition then u.condition=Condition.save(condition)end
    return true
end
function L.wanted(r,u,state)
    local wanted={items={},schools={},known={},memorized={}}
    for p=1,20 do wanted.items[p]=-1 end
    if u.equipment then
        for _,row in ipairs(u.equipment) do
            local item=r.catalog.byItemId and r.catalog.byItemId[row.id]
            if not item or item.name~=row.name then return nil,'Missing or changed item: #'..tostring(row.id)..' '..tostring(row.name) end
            if wanted.items[row.position+1]~=-1 then return nil,'Duplicate saved equipment position.' end
            wanted.items[row.position+1]=row.id
        end
    else
        -- Legacy scenarios did not retain positions or reliable item IDs.
        -- Prefer unchanged native positions; remaining unique names use an
        -- anatomical slot and still undergo the full native transaction.
        local pending=M.copy(u.items or {})
        for _,name in ipairs(pending) do
            if r.catalog.itemNames[name]==nil or r.catalog.itemNames[name]==false then return nil,'Legacy item name is missing or ambiguous: '..name end
        end
        for _,row in ipairs(state.items) do
            for i,name in ipairs(pending) do if row.id>=0 and row.name==name then
                wanted.items[row.position+1]=row.id;table.remove(pending,i);break
            end end
        end
        for _,name in ipairs(pending) do
            local id=r.catalog.itemNames[name]
            if id==nil or id==false then return nil,'Legacy item name is missing or ambiguous: '..name end
            local item=r.catalog.byItemId[id];local at
            for _,row in ipairs(state.items) do if row.slotType==item.slot and wanted.items[row.position+1]<0 then at=row.position+1;break end end
            if not at then return nil,'No anatomical slot for legacy item: '..name end
            wanted.items[at]=id
        end
    end
    local schools={};for _,row in ipairs(state.schools) do schools[row.path]=row end
    if u.schools and #u.schools~=#state.schools then return nil,'The native base-school list changed. Saved configuration kept.' end
    for _,row in ipairs(u.schools or state.schools) do
        if not schools[row.path] or schools[row.path].name~=row.name then return nil,'Missing or changed native school: '..tostring(row.name) end
        wanted.schools[#wanted.schools+1]={path=row.path,level=row.base}
    end
    for _,pair in ipairs({{u.baseline.known,wanted.known},{u.spells,wanted.memorized}}) do
        for _,key in ipairs(pair[1]) do local id=r.catalog.spellKeys[key]
            if id==nil then return nil,'Missing or changed spell: '..tostring(key) end
            pair[2][#pair[2]+1]=id
        end
    end
    return wanted
end
local function listSame(a,b)
    if #a~=#b then return false end
    for i,v in ipairs(a) do if v~=b[i] then return false end end
    return true
end
function L.matches(r,u,unit)
    local state,why=L.read(r,unit);if not state then return false,why end
    local wanted;wanted,why=L.wanted(r,u,state);if not wanted then return false,why end
    for _,row in ipairs(state.items) do if wanted.items[row.position+1]~=row.id then return false,'Equipment position/identity mismatch.' end end
    local bases={};for _,row in ipairs(state.schools) do bases[row.path]=row.base end
    for _,row in ipairs(wanted.schools) do if bases[row.path]~=row.level then return false,'Base-school level mismatch.' end end
    if not listSame(state.known,wanted.known) or not listSame(state.memorized,wanted.memorized) then return false,'Known/memorized spell identity or order mismatch.' end
    return state.valid==true,state.valid==true and state or 'Native spell rules rejected the configuration.'
end
local function clearCursedDefaults(r,unit,state,wanted)
    local removals={}
    local oldCounts,wantedCounts={},{}
    for _,slot in ipairs(state.items)do if slot.id>=0 then oldCounts[slot.id]=(oldCounts[slot.id]or 0)+1 end end
    for _,id in ipairs(wanted.items)do if id>=0 then wantedCounts[id]=(wantedCounts[id]or 0)+1 end end
    for _,slot in ipairs(state.items)do
        local retainedImplant=slot.permanentEffects and wantedCounts[slot.id]==oldCounts[slot.id]
        if slot.cursed and slot.id~=wanted.items[slot.position+1] and not retainedImplant then removals[#removals+1]=slot end
    end
    if #removals==0 then return true end
    local caps=type(r.api.testFieldEditorCapabilities)=='function' and r.api.testFieldEditorCapabilities() or {}
    if caps.cursedRemoval~=1 then return false,'cursed_removal_unavailable',{rollbackVerified=true,stage='restore_cursed_defaults'} end
    -- Only freshly-created reconstruction actors take this path. Their random
    -- native selections are replaced by the exact saved choices after cleanup.
    local initial={};local captured,captureWhy=L.capture(r,initial,state);if not captured then return false,captureWhy,{rollbackVerified=true}end
    local stage,why=L.wanted(r,initial,state)
    if not stage then return false,why,{rollbackVerified=true,stage='restore_cursed_defaults'}end
    stage.memorized={}
    local ok,reason,detail=r.api.setTestFieldConfiguration(unit,stage)
    if not ok then return false,reason,detail end
    for _,slot in ipairs(removals)do
        stage.items[slot.position+1]=-1;stage.removeCursed={position=slot.position,item=slot.id}
        ok,reason,detail=r.api.setTestFieldConfiguration(unit,stage)
        if not ok then return false,reason,detail end
        stage.removeCursed=nil
    end
    if r.diag then r.diag:record('restore_cursed_defaults',{native_id=unit,count=#removals,result='new actor only; saved spells restored next'})end
    return true
end
function L.omitStartingItems(r,unit)
    if not L.available(r.api)then return false,'Omitting starting items needs the equipment configuration API.'end
    local state,why=L.read(r,unit);if not state then return false,why end
    local present=0
    for _,slot in ipairs(state.items)do if slot.id>=0 then
        present=present+1
        if slot.permanentEffects then return false,'Starting equipment cannot be omitted safely: native initialization implanted '..slot.name..'. Existing army kept.'end
    end end
    if present==0 then return true end
    local initial={};local captured,captureWhy=L.capture(r,initial,state);if not captured then return false,captureWhy end
    local wanted;wanted,why=L.wanted(r,initial,state);if not wanted then return false,why end
    for _,slot in ipairs(state.items)do if slot.id>=0 and slot.cursed then
        wanted.items[slot.position+1]=-1;wanted.removeCursed={position=slot.position,item=slot.id}
        local ok,reason,detail=r.api.setTestFieldConfiguration(unit,wanted)
        if not ok then return false,'Cannot omit starting equipment without changing the native spell/organ state: '..tostring(reason),detail end
        wanted.removeCursed=nil
    end end
    for i=1,20 do wanted.items[i]=-1 end
    local ok,reason,detail=r.api.setTestFieldConfiguration(unit,wanted)
    if not ok then return false,'Cannot omit starting equipment without changing the native spell state: '..tostring(reason),detail end
    local after;after,why=L.read(r,unit);if not after then return false,why end
    for _,slot in ipairs(after.items)do if slot.id>=0 then return false,'Native starting-item removal was not verified.',{rollbackVerified=false}end end
    if not listSame(state.known,after.known)or not listSame(state.memorized,after.memorized)or state.organInjuryFlags~=after.organInjuryFlags then
        return false,'Starting-item removal changed unrelated native state.',{rollbackVerified=false}
    end
    if r.diag then r.diag:record('omit_starting_items',{native_id=unit,count=present,result='all positions empty; original spell order and organ flags retained'})end
    return true
end
function L.configure(r,u,unit,restoring,options)
    local state,why=L.read(r,unit);if not state then return false,why end
    if not u.baseline then
        local captured,captureWhy=L.capture(r,u,state);if not captured then return false,captureWhy end
        r:observeSpellSelection(u,unit)
        return state.valid==true,state.valid==true and nil or 'Native starting configuration is invalid.'
    end
    local wanted;wanted,why=L.wanted(r,u,state);if not wanted then return false,why end
    if restoring then wanted.restoreKnown=true end
    if options and options.removeCursed then wanted.removeCursed=M.copy(options.removeCursed) end
    if options and options.clearHeldItems then wanted.clearHeldItems=true end
    local ok,reason,detail=true
    if restoring then ok,reason,detail=clearCursedDefaults(r,unit,state,wanted)end
    if ok then ok,reason,detail=r.api.setTestFieldConfiguration(unit,wanted)end
    r.lastConfig={model_id=u.id,native_id=unit,name=u.name,configuration_result=ok and 'committed' or reason,
        rollback_verified=type(detail)=='table' and detail.rollbackVerified==true}
    if wanted.removeCursed then
        r.lastConfig.configuration_remove_cursed_position=wanted.removeCursed.position
        r.lastConfig.configuration_remove_cursed_item=wanted.removeCursed.item
    end
    if type(detail)=='table' then for _,key in ipairs({'stage','path','spell','actual','allowed','allowance','level'}) do
        r.lastConfig['configuration_'..key]=detail[key]
    end end
    r:observeSpellSelection(u,unit,ok and nil or reason,detail)
    if not ok then return false,'Configuration refused: '..tostring(reason),detail end
    local matched;matched,why=L.matches(r,u,unit)
    if not matched then return false,why,{rollbackVerified=false} end
    local observed;observed,why=L.read(r,unit);if not observed then return false,why,{rollbackVerified=false}end
    local captured;captured,why=L.capture(r,u,observed);if not captured then return false,why,{rollbackVerified=false}end
    return true
end
function L.change(r,u,edit,action)
    local ready,why=r:ready(r.current);if not ready then return false,why end
    local before=r:snapshot(r.current)
    local unit=r.live[u.id];local old=M.copy(u);local candidate=M.copy(u)
    local state;state,why=L.read(r,unit);if not state then return false,why end
    if not candidate.equipment then local captured;captured,why=L.capture(r,candidate,state);if not captured then return false,why end end
    local accepted,options;accepted,why,options=edit(candidate,state);if not accepted then return false,why end
    local ok,detail;ok,why,detail=L.configure(r,candidate,unit,false,options)
    if not ok then
        local unchanged=L.matches(r,old,unit)
        r:failure(action,why,r.current,before,unchanged and 'verified unchanged' or 'unverified')
        if not unchanged or (type(detail)=='table' and detail.rollbackVerified==false) then return r:quarantine(r.current,why,before,{operation=action}) end
        return false,why..'. Previous configuration kept.'
    end
    for k in pairs(u) do u[k]=nil end;for k,v in pairs(candidate) do u[k]=v end
    if r.current then for i,v in ipairs(r.current.units) do if v.id==u.id then r.current.units[i]=u end end end
    local good,observed,details=r:check(r.current)
    if not good then return r:quarantine(r.current,observed,nil,details) end
    r:accept(r.current,observed)
    if r.diag then r.diag:record(action,{model_id=u.id,native_id=unit,result='native readback verified'}) end
    return true
end
function L.equip(r,u,position,item,expected)
    return L.change(r,u,function(candidate,state)
        local slot=state.items[position+1]
        if not slot or slot.position~=position then return false,'Unknown equipment position.' end
        if slot.id~=expected then return false,'This slot changed. Review it again before replacing its item.' end
        local options
        if not item and slot.cursed then
            local caps=type(r.api.testFieldEditorCapabilities)=='function' and r.api.testFieldEditorCapabilities() or {}
            if caps.cursedRemoval~=1 then return false,'Removing a cursed item needs the updated experimental Extender. Previous configuration unchanged.' end
            options={removeCursed={position=position,item=slot.id}}
        end
        local found=false
        for i,row in ipairs(candidate.equipment) do if row.position==position then
            if item then row.id=item.id;row.name=item.name else table.remove(candidate.equipment,i) end
            found=true;break
        end end
        if item and not found then candidate.equipment[#candidate.equipment+1]={position=position,id=item.id,name=item.name} end
        table.sort(candidate.equipment,function(a,b)return a.position<b.position end)
        return true,nil,options
    end,'equipment_change')
end
function L.raise(r,u,path)
    return L.change(r,u,function(candidate)
        for _,row in ipairs(candidate.schools) do if row.path==path then
            if row.base>=3 then return false,'This school is already at the supported base-level limit (3).' end
            row.base=row.base+1;return true
        end end
        return false,'Only an existing base school can be increased.'
    end,'school_level_change')
end
function L.learn(r,u,spell)
    local key=spell.id..':'..spell.name
    return L.change(r,u,function(candidate)
        for _,known in ipairs(candidate.baseline.known) do if known==key then return false,'This spell is already known.' end end
        if #candidate.baseline.known>=60 then return false,'Native known-spell capacity reached (60).' end
        candidate.baseline.known[#candidate.baseline.known+1]=key;return true
    end,'learn_spell')
end
function L.setLevel(r,u,path,level)
    if type(level)~='number' or level%1~=0 or level<1 or level>3 then return false,'Choose a supported base level from 1 to 3.' end
    return L.change(r,u,function(candidate)
        for _,row in ipairs(candidate.schools)do if row.path==path then row.base=level;return true end end
        return false,'Only an existing base school can be changed.'
    end,'school_level_change')
end
function L.unlock(r,u,path)
    return L.change(r,u,function(candidate,state)
        local school;for _,row in ipairs(state.schools)do if row.path==path then school=row end end
        if not school then return false,'Only an existing base school can be unlocked.' end
        local known={};for _,key in ipairs(candidate.baseline.known)do known[key]=true end
        local count=0
        for _,spell in ipairs(r.catalog.spells)do
            local key=spell.id..':'..spell.name
            if spell.path==path and spell.level>=1 and spell.level<=math.min(school.base,school.level) and not known[key] then
                candidate.baseline.known[#candidate.baseline.known+1]=key;known[key]=true;count=count+1
            end
        end
        if count==0 then return false,'All eligible spells up to this base level are already known.' end
        if #candidate.baseline.known>60 then return false,'Unlocking would exceed the native known-spell capacity (60). No spells changed; learn individual spells instead.' end
        return true
    end,'unlock_school_spells')
end
return L
