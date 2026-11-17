local M=require('sandbox.model')
local Integrity=require('sandbox.integrity')
local Loadout=require('sandbox.loadout')
local Condition=require('sandbox.condition')
local Names=require('sandbox.names')
local R={}; R.__index=R
local function same(a,b)
    if #a~=#b then return false end
    local x,y=M.copy(a),M.copy(b); table.sort(x);table.sort(y)
    for i,v in ipairs(x) do if y[i]~=v then return false end end; return true
end
function R.new(api,catalog,diagnostics)
    return setmetatable({api=api,catalog=catalog,diag=diagnostics,live={},objects={},open=false},R)
end
function R:multipleUniqueAvailable()
    if type(self.api.testFieldEditorCapabilities)~='function' then return false end
    local ok,caps=pcall(self.api.testFieldEditorCapabilities)
    return ok and type(caps)=='table' and caps.multipleUnique==1
end
local function exactValue(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not exactValue(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local function clearItemsIdentity(state)
    local value={unit=state.unit,generation=state.generation,items={},known=M.copy(state.known),memorized=M.copy(state.memorized),schools={},organInjuryFlags=state.organInjuryFlags}
    for _,slot in ipairs(state.items or{})do value.items[#value.items+1]=slot.id end
    for _,school in ipairs(state.schools or{})do value.schools[#value.schools+1]={path=school.path,base=school.base}end
    return value
end
function R:setMultipleUnique(s,enabled)
    if type(enabled)~='boolean'then return false,'Unique policy must be On or Off.',{rollbackVerified=true}end
    local caps=type(self.api.testFieldEditorCapabilities)=='function'and self.api.testFieldEditorCapabilities()or{}
    if caps.multipleUniquePolicy~=1 or type(self.api.setTestFieldMultipleUnique)~='function'then
        return false,'Changing unique policy without rebuilding needs the updated experimental Extender. Field kept.',{rollbackVerified=true}
    end
    if self.blocked or self.cleanupFailed then return false,'Editing is locked; the preserved setup was kept.',{rollbackVerified=false}end
    if not self.open then
        local seen={}
        if not enabled then for _,u in ipairs(s.units)do
            if (self.api.get('monsterAbility',u.monster,'unique')or 0)>0 then
                if seen[u.monster]then return false,'Remove the extra copies before switching Off. Setup kept.',{rollbackVerified=true}end
                seen[u.monster]=true
            end
        end end
        s.allowMultipleUnique=enabled
        if self.diag then self.diag:record('multiple_unique_native',{enabled=enabled and 1 or 0,scope='pending setup; no native field',result='verified'})end
        return true,nil,{rollbackVerified=true}
    end
    local healthy,previous=self:ready(s);if not healthy then return false,previous,{rollbackVerified=not self.blocked}end
    local before=self:snapshot(s);local accepted,why=self.api.setTestFieldMultipleUnique(enabled)
    local candidate=M.copy(s);if accepted then candidate.allowMultipleUnique=enabled end
    local ok,observed,detail=self:check(candidate,true,previous)
    if not ok then return self:quarantine(s,observed,before,detail)end
    if not accepted then return false,'Unique policy refused: '..tostring(why)..'. Field kept.',{rollbackVerified=true}end
    s.allowMultipleUnique=enabled;self:accept(s,observed)
    if self.diag then self.diag:record('multiple_unique_native',{enabled=enabled and 1 or 0,field_generation=self.generation,in_place=1,result='verified'})end
    return true,nil,{rollbackVerified=true}
end
function R:clearHeldItems(s,u,expected)
    local caps=type(self.api.testFieldEditorCapabilities)=='function'and self.api.testFieldEditorCapabilities()or{}
    if caps.clearHeldItems~=1 then return false,'Atomic held-item clearing needs the updated experimental Extender.',{rollbackVerified=true}end
    local healthy,why=self:ready(s);if not healthy then return false,why,{rollbackVerified=not self.blocked}end
    local unit=self.live[u.id];local state;state,why=Loadout.read(self,unit)
    if not state then return false,why,{rollbackVerified=true}end
    local original=clearItemsIdentity(state)
    if not exactValue(original,expected)then return false,'This actor or its equipment/spells changed after confirmation. Review again.',{rollbackVerified=true}end
    local accepted,message=Loadout.change(self,u,function(candidate,current)
        if not exactValue(clearItemsIdentity(current),expected)then return false,'The confirmed native configuration changed.'end
        candidate.equipment={}
        return true,nil,{clearHeldItems=true}
    end,'clear_held_items')
    if accepted then return true,nil,{rollbackVerified=true}end
    if self.blocked then return false,message,{rollbackVerified=false}end
    local actual=Loadout.read(self,unit);local unchanged=actual and exactValue(clearItemsIdentity(actual),original)
    local verified=self:check(s)
    if not unchanged or not verified then return self:quarantine(s,'Held-item removal rollback could not be verified.',nil,{model_id=u.id,native_id=unit})end
    return false,message,{rollbackVerified=true}
end
function R:emptyEditorAvailable()
    if type(self.api.testFieldEditorCapabilities)~='function' then return false end
    local ok,caps=pcall(self.api.testFieldEditorCapabilities)
    return ok and type(caps)=='table' and caps.emptyEditor==1
end
function R:inventory(unit)
    local t={}; for i=0,Loadout.available(self.api) and 19 or 7 do local item=self.api.get('unitItem',unit,i)
        if item and item>=0 then t[#t+1]=self.api.get('itemName',item) end
    end; return t
end
function R:spellList(unit,key,max)
    local t={}; for i=0,max do local id=self.api.get(key,unit,i); if not id or id<0 then break end
        local info=self.api.spellInfo(id); if info then t[#t+1]=id..':'..info.name end
    end; return t
end
function R:configureNative(u,unit)
    if Loadout.available(self.api) then return Loadout.configure(self,u,unit,true) end
    if u.equipment or u.schools then return false,'This scenario requires the newer experimental equipment/base-school API. Saved setup kept.' end
    local known=self:spellList(unit,'unitKnownSpell',59)
    if not u.baseline then
        u.baseline={known=known}; u.items=self:inventory(unit); u.spells=self:spellList(unit,'unitMemorizedSpell',29)
        self:observeSpellSelection(u,unit)
    else
        self.lastConfig={name=u.name,monster=u.monster,unit=unit,saved_known=table.concat(u.baseline.known,'|'),actual_known=table.concat(known,'|'),saved_memorized=table.concat(u.spells,'|'),actual_memorized=table.concat(self:spellList(unit,'unitMemorizedSpell',29),'|')}
        for _,name in ipairs(u.items) do if not self.catalog.itemNames[name] then return false,'Missing or ambiguous item: '..name end end
        for _,name in ipairs(u.spells) do if not self.catalog.spellKeys[name] then return false,'Missing or changed spell: '..name end end
        -- Never silently replace existing intrinsic/random inventory on restoration.
        local current=self:inventory(unit)
        if not same(current,u.items) then
            for _,name in ipairs(current) do self.api.takeItem(unit,name) end
            for _,name in ipairs(u.items) do self.api.giveItem(unit,name) end
            if not same(self:inventory(unit),u.items) then return false,'Equipment restoration refused by game: '..u.name end
        end
        if type(self.api.setTestFieldSpells)=='function' then
            local state={known={},memorized={}}
            for _,key in ipairs(u.baseline.known) do
                if not self.catalog.spellKeys[key] then return false,'Missing or changed known spell: '..key end
                state.known[#state.known+1]=self.catalog.spellKeys[key]
            end
            for _,key in ipairs(u.spells) do state.memorized[#state.memorized+1]=self.catalog.spellKeys[key] end
            local accepted,why,detail=self.api.setTestFieldSpells(unit,state)
            self:observeSpellSelection(u,unit,accepted and nil or why,detail)
            if not accepted then return false,'Exact spell restoration refused for '..u.name..': '..tostring(why) end
            if table.concat(self:spellList(unit,'unitKnownSpell',59),'|')~=table.concat(u.baseline.known,'|') or
                table.concat(self:spellList(unit,'unitMemorizedSpell',29),'|')~=table.concat(u.spells,'|') then return false,'Exact spell readback failed for '..u.name end
            return true
        end
        if not same(known,u.baseline.known) then return false,'Native starting spells changed for '..u.name..'; exact restoration unavailable' end
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
function R:configure(u,unit)
    local saved=u.condition and M.copy(u.condition)
    local fresh=not u.baseline
    if saved and not Condition.available(self.api)then return false,'Saved health/injury state requires the release-next API. Existing setup kept.'end
    if fresh and u.omitStartingItems then
        local ok,why,detail=Loadout.omitStartingItems(self,unit);if not ok then return false,why,detail end
    end
    local ok,why,detail=self:configureNative(u,unit)
    if not ok then u.condition=saved;return false,why,detail end
    if saved then
        ok,why,detail=Condition.restore(self,u,unit,saved)
        if not ok then self.lastConfig=self.lastConfig or {};self.lastConfig.actor_state_error=why;return false,why,detail end
    elseif fresh then
        ok,why=Condition.capture(self,u,unit);if not ok then return false,why end
    else
        self.legacyStateNotice='Legacy setup has no recorded health/injury state; only its recorded configuration can be restored.'
    end
    return Names.apply(self,u,unit)
end
function R:observeSpellSelection(u,unit,reason,detail)
    if type(self.api.testFieldSpellState)~='function' then return end
    local native=self.api.testFieldSpellState(unit)
    if type(native)~='table' then return end
    local schools={}
    for _,row in ipairs(native.schools or {}) do
        schools[row.path]={path=row.path,name=row.name,level=row.level,bonus=row.bonus,allowance=row.allowance,
            actual_known=row.knownCount,actual_memorized=row.memorizedCount,saved_known=0,selected_count=0}
    end
    for _,pair in ipairs({{u.baseline and u.baseline.known or {},'saved_known','saved_known_ids'},{u.spells or {},'selected_count','saved_memorized_ids'}}) do
        for _,key in ipairs(pair[1]) do
            local id=self.catalog.spellKeys[key];local info=id and self.api.spellInfo(id)
            if info then
                if not schools[info.path] then
                    schools[info.path]={path=info.path,name=info.pathName or ('School '..info.path),allowance=self.api.memorizeAllowance(unit,info.path),saved_known=0,selected_count=0}
                end
                schools[info.path][pair[2]]=schools[info.path][pair[2]]+1
                local row=schools[info.path];row[pair[3]]=row[pair[3]] or {};row[pair[3]][#row[pair[3]]+1]=id
            end
        end
    end
    for _,pair in ipairs({{native.known,'actual_known_ids'},{native.memorized,'actual_memorized_ids'}}) do
        for _,id in ipairs(pair[1] or {}) do
            local info=self.api.spellInfo(id);local row=info and schools[info.path]
            if row then row[pair[2]]=row[pair[2]] or {};row[pair[2]][#row[pair[2]]+1]=id end
        end
    end
    local rows={};for _,row in pairs(schools) do
        for _,key in ipairs({'saved_known_ids','saved_memorized_ids','actual_known_ids','actual_memorized_ids'}) do row[key]=table.concat(row[key] or {},',') end
        rows[#rows+1]=row
    end;table.sort(rows,function(a,b)return a.path<b.path end)
    local observation={model_id=u.id,native_id=unit,name=u.name,monster=u.monster,reason=reason,detail=M.copy(detail),schools=rows,
        saved_known=M.copy(u.baseline and u.baseline.known or {}),saved_memorized=M.copy(u.spells),native=M.copy(native)}
    self.spellValidation=self.spellValidation or {};self.spellValidation[u.id]=observation
    if self.diag then self.diag.spellValidation=M.copy(self.spellValidation) end
    if reason=='memorize_limit' or reason=='spell_level' or reason=='memorized_not_known' then
        self.spellRepairProblems=self.spellRepairProblems or {};self.spellRepairProblems[u.id]=observation
        if self.lastConfig then
            self.lastConfig.spell_stage=type(detail)=='table' and detail.stage or 'native_validation'
            if type(detail)=='table' then for _,key in ipairs({'path','requested','allowance','spell'}) do self.lastConfig['spell_'..key]=detail[key] end end
        end
    end
end
function R:spellRepairCandidates(s)
    local out={}
    for _,u in ipairs(s.units or {}) do
        local p=self.spellRepairProblems and self.spellRepairProblems[u.id]
        if p and p.monster==u.monster and table.concat(p.saved_memorized or {},'|')==table.concat(u.spells or {},'|') then out[#out+1]={model_id=u.id,name=u.name,known=M.copy(u.baseline and u.baseline.known or {}),spells=M.copy(u.spells),schools=M.copy(p.schools)} end
    end
    return out
end
function R:repairSpellSelection(candidate)
    if not self.spellRepairProblems or not next(self.spellRepairProblems) then return false,'No saved spell-selection problem is available.' end
    local original=M.copy(self.originalSpellRecovery or self.spellRepairScenario or self.recovery or self.lastKnownGood or candidate)
    local originalFile=self.spellRepairSource or self.recoveryFile
    local chosen=M.copy(candidate)
    local ok,why=self:build(chosen)
    if not ok then return false,'The selected repair was not accepted. Original recovery kept. '..tostring(why) end
    self.originalSpellRecovery=original;self.originalSpellRecoveryFile=originalFile;self.recovery=M.copy(chosen)
    local name,path
    if self.diag and self.diag.saveRepair then name,path=self.diag:saveRepair(chosen,self.catalog.mods or {},originalFile) end
    if name then self.recoveryFile=name;self.recoveryPath=path end
    if self.diag then self.diag:record('spell_repair',{result='verified user selection',original_recovery=originalFile or 'in-memory',repaired_file=name or 'not saved'}) end
    return true,chosen,{name=name,path=path,warning=not name and (path or 'Verified repair is in memory only; save it as a new scenario.') or nil}
end
function R:inspect(s,u)
    local ready,previous=self:ready(s);if not ready then return false,previous end
    if type(self.api.inspectTestFieldUnit)~='function' then return false,'Native Inspect requires the updated experimental extender.' end
    local id=self.live[u.id];local ok,detail,nativeResult=self.api.inspectTestFieldUnit(id,{readOnly=true})
    local good,observed,problem=self:check(s,true,previous)
    if not good then return self:quarantine(s,observed,nil,problem) end
    if not ok then
        if type(nativeResult)=='table' and nativeResult.verified~=true then return self:quarantine(s,'inspect_changed_unverified',nil,{native_id=id,model_id=u.id,reason=detail}) end
        return false,'Native Inspect refused: '..tostring(detail)
    end
    if type(detail)~='table' or detail.readOnly~=true or detail.verified~=true then return self:quarantine(s,'inspect_readonly_unverified',nil,{native_id=id,model_id=u.id}) end
    self:accept(s,observed)
    if self.diag then self.diag:record('inspect',{model_id=u.id,native_id=id,name=u.name,read_only=1,result='native card closed; state verified',spells_restored=detail.spellsRestored and 1 or 0}) end
    detail.mode='read_only';return true,s,detail
end
function R:close()
    local preserved=self.current and M.copy(self.current) or self.lastKnownGood and M.copy(self.lastKnownGood)
    local wasOpen=self.open
    local closed,why=true
    if self.open then
        local result,reason=self.api.closeTestField()
        -- Legacy extenders returned no value; new lifecycle-capable builds must confirm cleanup.
        if result==false then closed=false;why=reason or 'Native cleanup could not be verified' end
    end
    if type(self.api.testFieldLifecycle)=='function' then
        local ok,state=pcall(self.api.testFieldLifecycle)
        if ok and type(state)=='table' then
            if self.diag then self.diag.lifecycle=state end
            if wasOpen and (state.open or (state.complete~=true and state.complete~=1) or #(state.issues or {})>0) then
                closed=false;why=why or 'Native lifecycle readback did not confirm cleanup'
            end
        elseif wasOpen then closed=false;why=why or 'Native lifecycle readback unavailable' end
    end
    self.open=false; self.live={};self.objects={};self.finalState=nil;self.phase=nil
    if self.savedColors then
        for team,slot in ipairs({0,24}) do for j,key in ipairs({'slotColorRed','slotColorGreen','slotColorBlue'}) do self.api.set(key,slot,self.savedColors[team][j]) end end
        self.savedColors=nil
    end
    self.current=nil
    if not closed then
        self.cleanupFailed=tostring(why)
        self:quarantine(preserved or M.new(),'test_field_cleanup_unverified',nil,{native_reason=why,recovery='restart isolated game and load preserved setup'})
    end
    return closed,why
end
function R:snapshot(s)
    return self.diag and self.diag:snapshot(s,self) or nil
end
function R:failure(action,why,s,before,restored,details)
    if self.diag then
        local context=M.copy(self.lastConfig or {});for k,v in pairs(details or {}) do context[k]=v end
        self.diag:failure(action,why,context,before,self:snapshot(s),restored)
    end
end
function R:accept(s,observed)
    self.current=s;self.lastKnownGood=M.copy(s);self.verified=observed;self.blocked=false
end
function R:quarantine(s,why,before,details)
    if not self.blocked then
        self.blocked=true;self.recovery=M.copy(self.lastKnownGood or s)
        self:failure('integrity',why,s,before,'unverified; editing locked',details)
        if self.diag then
            self.diag.firstIntegrity=self.diag.firstIntegrity or M.copy(self.diag.lastError)
            self.recoveryFile,self.recoveryPath=self.diag:preserve(self.recovery,self.catalog.mods or {})
        end
    end
    return false,'Native state could not be verified. Editing locked. Export Diagnostics, then Reopen preserved setup.'
end
function R:check(s,positions,previous,configuration)
    local ok,observed,details=Integrity.inspect(self,s,positions~=false,previous,configuration)
    if not ok then return ok,observed,details end
    if configuration~=false and self.phase~='after' then
        for _,u in ipairs(s.units or {})do
            local named,nameWhy=Names.matches(self,u,self.live[u.id]);if not named then return false,nameWhy,{model_id=u.id,native_id=self.live[u.id],scope='native name'}end
            if u.condition then
            local matched,why=Condition.matches(self,u,self.live[u.id])
            if not matched then return false,why,{model_id=u.id,native_id=self.live[u.id],scope='supported actor state'}end
        end end
    end
    return ok,observed,details
end
function R:ready(s)
    if self.phase=='after' then return false,'The final battle snapshot is read only. Back to Sandbox restores the saved setup.' end
    if not self.open or not s then return false,'Open a verified battlefield before editing.' end
    if self.blocked then return false,'Editing is locked. Export Diagnostics or Reopen preserved setup.' end
    local ok,observed,details=self:check(s)
    if not ok then return self:quarantine(s,observed,self:snapshot(s),details) end
    self.verified=observed;self.lastKnownGood=M.copy(s)
    return true,observed
end
function R:recover()
    if self.cleanupFailed then return false,'Native cleanup could not be verified. Export Diagnostics, restart the isolated game and load the preserved recovery file. Saved setup was kept.' end
    local saved=self.recovery and M.copy(self.recovery)
    if not saved then return false,'No preserved setup is available.' end
    local ok,why=self:build(saved)
    if ok then
        self.blocked=false
        if self.diag then self.diag:record('recovery',{result='verified',units=#saved.units,field_generation=self.generation}) end
        return true,saved
    end
    self.blocked=true
    return false,'Preserved setup could not be reopened exactly. Editing stays locked; recovery file and diagnostics remain available. '..tostring(why)
end
function R:setLabel(u,label)
    local valid,why=M.validLabel(label);if not valid then return false,why end
    local ready,observed=self:ready(self.current);if not ready then return false,observed end
    local found=false;for _,actor in ipairs(self.current.units)do if actor==u then found=true;break end end
    if not found or not self.live[u.id] then return false,'Selected unit changed; reopen its window.' end
    u.label=label~='' and label or nil;self:accept(self.current,observed)
    if self.diag then self.diag:record('sandbox_label',{model_id=u.id,native_id=self.live[u.id],length=#label,scope='sandbox_display_label'})end
    return true
end
function R:setNativeName(u,name)return Names.set(self,u,name)end
function R:build(s,nativeDeployment)
    for _,u in ipairs(s.units or {})do if u.nativeName~=nil then
        local valid,why=M.validNativeName(u.nativeName);if not valid then return false,why end
        if not Names.available(self.api)then return false,'Recorded individual names need the experimental naming API. Current setup kept.'end
    end end
    if s.minimumWidth then
        local info=type(self.api.testFieldEnvironmentInfo)=='function'and self.api.testFieldEnvironmentInfo()
        if type(info)~='table'or info.minimumWidthVersion~=1 then return false,'Selected field size needs the release-next experimental size API. Current setup kept.'end
    end
    for _,u in ipairs(s.units or {})do if u.condition and not Condition.available(self.api)then return false,'Saved health/injury state requires the release-next experimental API. Current setup kept.'end end
    local function reject(message,details)
        local current=self.current or s;local snapshot=self:snapshot(current)
        self:failure('rebuild',message,current,snapshot,'unchanged',details)
        return false,message
    end
    if self.cleanupFailed then return reject('Native cleanup could not be verified: '..self.cleanupFailed..'. Export Diagnostics, restart the isolated game and load the preserved recovery file.') end
    local supported=false
    if type(self.api.testFieldTerrains)=='function' then
        local ok,ids=pcall(self.api.testFieldTerrains)
        if ok and type(ids)=='table' then for _,id in ipairs(ids) do if id==s.terrain then supported=true end end end
    end
    if not M.terrainCapabilityAvailable(self.api,s.terrain)then return reject('This fortified preset requires the matching structure-provenance API. Current setup kept.')end
    if s.terrain~=0 and not supported then return reject((M.terrainNames[s.terrain] or 'This terrain')..' requires the matching experimental terrain API. Current field kept.') end
    if not s.units then return reject('Scenario unit list is missing. Current field kept.') end
    if (M.count(s,1)==0 or M.count(s,2)==0) and not self:emptyEditorAvailable() then
        return reject('Empty teams need the updated experimental empty-editor API. Setup kept; restart with SandboxOfElysium-Testen.bat.')
    end
    for _,u in ipairs(s.units) do
        if (u.equipment or u.schools) and not Loadout.available(self.api) then return reject('This saved equipment/base-school setup needs the newer experimental Extender. Current army kept.') end
        local m=self.catalog.byId[u.monster]
        if not m or m.name~=u.name then return reject('Required unit is missing or changed. Current field kept.',{name=u.name,monster=u.monster}) end
        if u.baseline and #u.baseline.known>0 and type(self.api.setTestFieldSpells)~='function' then
            local before=self:snapshot(self.current or s)
            self:failure('rebuild','Missing deterministic spell restoration API',self.current or s,before,'unchanged',{name=u.name})
            return false,'Keeping saved caster spells requires the experimental editor API. Current army kept; Export Diagnostics for details.'
        end
    end
    if s.allowMultipleUnique and not self:multipleUniqueAvailable() then
        return reject('Multiple unique units require the updated experimental extender. Setup kept; restart with SandboxOfElysium-Testen.bat.')
    end
    local unique={}
    for _,u in ipairs(s.units) do
        if (self.api.get('monsterAbility',u.monster,'unique') or 0)>0 then
            if unique[u.monster] and not s.allowMultipleUnique then return reject('This setup contains the same unique creature more than once. Setup kept.',{monster=u.monster,name=u.name}) end
            unique[u.monster]=true
        end
    end
    if type(self.api.testFieldState)~='function' then return reject('This editor needs the updated experimental integrity API. Restart with SandboxOfElysium-Testen.bat.') end
    self.spellRepairProblems=nil;self.spellRepairScenario=nil;self.spellRepairSource=nil
    -- The UI may already have changed pending terrain/size options on current.
    -- Rollback must use the last verified native setup, including its dimensions.
    local old=self.open and (self.lastKnownGood or self.current) and M.copy(self.lastKnownGood or self.current) or nil
    local before=old and self:snapshot(old) or self:snapshot(s)
    self.lastConfig=nil
    -- Configuration may upgrade earlier legacy actors before a later actor is
    -- rejected. Recovery provenance must retain the exact requested scenario.
    local requested=M.copy(s)
    local ok,why=self:_build(s,nativeDeployment)
    if ok then local good,observed=self:check(s);if good then self:accept(s,observed);self.spellRepairProblems=nil;return true end;ok=false;why=observed end
    local rejectedSpells=M.copy(self.spellRepairProblems)
    local rejectedScene=rejectedSpells and next(rejectedSpells) and requested or nil
    if rejectedScene and not self.originalSpellRecovery then self.originalSpellRecovery=M.copy(requested) end
    local failureContext=M.copy(self.lastConfig or {})
    local restored,restoreWhy=false,'no previous open field'
    if old then restored,restoreWhy=self:_build(old);if restored then
        local good,observed=self:check(old);restored=good
        if good then self:accept(old,observed) else restoreWhy=observed end
    end end
    self.lastConfig=failureContext
    self.spellRepairProblems=rejectedSpells;self.spellRepairScenario=rejectedScene;self.spellRepairSource=rejectedScene and self.sourceScenarioFile or nil
    self:failure('rebuild',why,old or s,before,old and (restored and 'restored' or 'failed') or 'not applicable',{restore_detail=restoreWhy or 'ok'})
    self.recovery=old
    if not restored and old then self:quarantine(old,why,before,{restore_detail=restoreWhy}) end
    return false,restored and 'The new setup could not be opened. Previous army restored; Export Diagnostics for details.' or
        'The field could not be opened. Your scenario is kept; Export Diagnostics for details.'
end
function R:_build(s,nativeDeployment)
    local supported=false
    if type(self.api.testFieldTerrains)=='function' then
        local ok,ids=pcall(self.api.testFieldTerrains)
        if ok and type(ids)=='table' then for _,id in ipairs(ids) do if id==s.terrain then supported=true end end end
    end
    if not M.terrainCapabilityAvailable(self.api,s.terrain)then return false,'This fortified preset requires the matching structure-provenance API. Current setup kept.'end
    if s.terrain~=0 and not supported then return false,(M.terrainNames[s.terrain] or 'This terrain')..' requires the matching experimental terrain API. Current field kept.' end
    local closed,closeWhy=self:close()
    if not closed then return false,'Previous test field cleanup failed: '..tostring(closeWhy)..'. Scenario preserved; Export Diagnostics and restart the isolated game.' end
    local a,b={},{}; for _,u in ipairs(s.units) do local list=u.team==1 and a or b; list[#list+1]=u end
    local emptyEditor=self:emptyEditorAvailable()
    if (#a==0 or #b==0) and not emptyEditor then return false,'Empty teams require the experimental empty-editor API.' end
    local spec={friends={},enemies={}}
    if emptyEditor then spec.emptyEditor=true else spec.commander=a[1].monster;spec.spell=-1 end
    if s.allowMultipleUnique then spec.allowMultipleUnique=true end
    if supported then spec.terrain=s.terrain end
    if s.minimumWidth then spec.minimumWidth=s.minimumWidth end
    for i=emptyEditor and 1 or 2,#a do spec.friends[#spec.friends+1]={a[i].monster,1} end
    for _,u in ipairs(b) do spec.enemies[#spec.enemies+1]={u.monster,1} end
    local ok,units=self.api.openTestField(spec)
    if not ok then
        if units=='temporary_square_busy' then
            self.cleanupFailed=true
            return false,'The temporary field square still contains a native actor whose safe cleanup is unverified. Setup preserved. Export Diagnostics, restart the isolated game, then load the recovery file; do not keep retrying this process.'
        end
        return false,'The extender refused to open the test field: '..tostring(units or 'unknown reason')
    end
    if supported and self.api.get('squareTerrain',1,1)~=s.terrain then self.open=true;self:close();return false,'Extender terrain support is incompatible; selected terrain was not applied' end
    self.open=true;self.generation=(self.generation or 0)+1; self.width=self.api.get('battleWidth')
    if s.minimumWidth and self.width<s.minimumWidth then self:close();return false,'The requested minimum field width was not applied; setup kept.'end
    self.emptyEditor=emptyEditor;self.primaryId=nil
    if emptyEditor then
        if units.commander~=-1 then self:close();return false,'Empty-editor contract returned an unexpected commander. Scenario kept.' end
        for i,u in ipairs(a) do self.live[u.id]=units.friends[i] end
    else
        self.live[a[1].id]=units.commander;self.primaryId=a[1].id
        for i=2,#a do self.live[a[i].id]=units.friends[i-1] end
    end
    for i,u in ipairs(b) do self.live[u.id]=units.enemies[i] end
    self.savedColors={}; for team,slot in ipairs({0,24}) do
        self.savedColors[team]={}; local color=M.colors[s.colors[team]]
        for j,key in ipairs({'slotColorRed','slotColorGreen','slotColorBlue'}) do self.savedColors[team][j]=self.api.get(key,slot); self.api.set(key,slot,color[j+1]) end
    end
    if nativeDeployment then
        -- Only an explicit editor action adopts the engine's initial deployment.
        -- Saved scenarios, Reset and Rematch continue to require exact cells.
        for _,u in ipairs(s.units) do
            local unit=self.live[u.id]
            local x,y=self.api.get('unitBattleX',unit),self.api.get('unitBattleY',unit)
            if not x or not y then self:close();return false,'Native deployment has no cell for '..u.name end
            u.x=x;u.y=y
        end
    else
    local placed,why=self:place(s)
    if not placed then self:close();return false,why end
    end
    local configurationFailure,failureContext
    for _,u in ipairs(s.units) do local good,why=self:configure(u,self.live[u.id]);if not good and not configurationFailure then configurationFailure=why;failureContext=M.copy(self.lastConfig) end end
    if configurationFailure then self.lastConfig=failureContext;self:close();return false,configurationFailure end
    self:cacheObjects()
    return true
end
function R:place(s)
    local valid,observed=self:check(s,false,nil,false)
    if not valid then return false,observed end
    -- Parking must avoid every desired FOOTPRINT, not just model anchors.
    local targets,footprints={},{}
    for _,u in ipairs(s.units)do
        local row=observed.rows[self.live[u.id]];footprints[u.id]={width=row.width,height=row.height}
        for x=u.x,u.x+row.width-1 do for y=u.y,u.y+row.height-1 do
            if x<0 or x>=self.width or y<0 or y>=20 then return false,'Saved footprint is outside the native field: '..u.name end
            local key=x..':'..y
            if targets[key] then return false,'Saved unit footprints overlap: '..targets[key]..' / '..u.id end
            targets[key]=u.id
        end end
    end
    local waiting,parkedOnce={},{};for _,u in ipairs(s.units)do waiting[#waiting+1]=u end
    while #waiting>0 do
        local rest={}; local progress=false
        for _,u in ipairs(waiting) do
            local unit=self.live[u.id]
            if self.api.get('unitBattleX',unit)==u.x and self.api.get('unitBattleY',unit)==u.y or self.api.moveTestFieldUnit(unit,u.x,u.y) then progress=true else rest[#rest+1]=u end
        end
        if not progress then
            -- The first blocked unit may be outside the actual cycle. Evacuate
            -- each remaining actor once; repeatedly parking the same actor can
            -- never release a cycle between other large units.
            local parked=false
            for _,u in ipairs(rest) do
                if not parkedOnce[u.id]then
                    local foot=footprints[u.id];local moved=false
                    for y=0,20-foot.height do for x=0,self.width-foot.width do
                        local free=true
                        for px=x,x+foot.width-1 do for py=y,y+foot.height-1 do if targets[px..':'..py]then free=false end end end
                        if free and self.api.moveTestFieldUnit(self.live[u.id],x,y)then
                            moved=true
                            if self.diag then self.diag:record('deployment_parking',{model_id=u.id,native_id=self.live[u.id],x=x,y=y,width=foot.width,height=foot.height,result='temporary; exact final deployment still required'})end
                            break
                        end
                    end;if moved then break end end
                    if moved then parkedOnce[u.id]=true;parked=true end
                end
            end
            if not parked then return false,'Native field rejected exact deployment (blocked target or no safe footprint parking space)' end
        end
        waiting=rest
    end
    local valid,why=self:check(s,true,nil,false)
    return valid,valid and nil or why
end
function R:cacheObjects()
    self.objects={}
    if type(self.api.battleObjectAt)=='function' then
        for x=0,self.width-1 do for y=0,19 do local object=self.api.battleObjectAt(x,y)
            if object and object>=0 then self.objects[x..':'..y]=true end
        end end
    end
end
function R:move(u,x,y)
    self.lastConfig=nil
    local good,previous=self:ready(self.current)
    if not good then return false,previous end
    if not self.api.moveTestFieldUnit(self.live[u.id],x,y) then
        local unchanged,observed,details=self:check(self.current,true,previous)
        if not unchanged then return self:quarantine(self.current,observed,nil,details) end
        local snapshot=self.current and self:snapshot(self.current)
        if self.current then self:failure('move','native move refused',self.current,snapshot,'unchanged',{name=u.name,id=u.id,unit=self.live[u.id],x=x,y=y}) end
        return false,'Cell blocked, outside field, or unit does not fit. Original unit kept.'
    end
    u.x=x;u.y=y
    if self.current then for _,v in ipairs(self.current.units) do if v.id==u.id then v.x=x;v.y=y end end end
    local valid,observed,details=self:check(self.current,true,previous)
    if not valid then return self:quarantine(self.current,observed,self:snapshot(self.lastKnownGood),details) end
    self:accept(self.current,observed)
    if self.diag then self.diag:record('move',{name=u.name,id=u.id,model_id=u.id,native_id=self.live[u.id],x=x,y=y,result='verified'}) end
    return true
end
function R:add(s,monster,team,x,y,template)
    if template and template.nativeName~=nil and not Names.available(self.api)then return false,'Copy needs the experimental native-name API. Existing units kept.'end
    self.lastConfig=nil
    local before=self:snapshot(s)
    local function refused(why,restored)
        self:failure(template and 'copy' or 'place',why,s,before,restored or 'unchanged',{monster=monster,team=team,x=x,y=y})
        return false,why
    end
    if not self.open then return refused('Open the battlefield before placing units.') end
    local healthy,previous=self:ready(s)
    if not healthy then return false,previous end
    if M.at(s,x,y) or x<0 or x>=self.width or y<0 or y>=20 then return refused('Cell occupied or outside the field. Existing army kept.') end
    if type(self.api.removeTestFieldUnit)~='function' then return refused('Safe placement requires the experimental editor API. Existing army kept; Export Diagnostics for details.') end
    if template and template.baseline and type(self.api.setTestFieldSpells)~='function' then return refused('Copying saved caster configuration requires the experimental editor API. Existing army kept.') end
    local candidate=M.copy(s); local m=self.catalog.byId[monster]
    if not m or (team~=1 and team~=2) then return refused('Invalid unit or team. Existing army kept.') end
    if s.allowMultipleUnique and not self:multipleUniqueAvailable() then return refused('Multiple unique units require the updated experimental extender. Existing army kept.') end
    if not s.allowMultipleUnique and (self.api.get('monsterAbility',monster,'unique') or 0)>0 then
        for _,old in ipairs(s.units) do if old.monster==monster then
            return refused('This creature is unique and is already on the field. Choose another creature; existing unit kept.')
        end end
    end
    local u=M.add(candidate,monster,m.name,team,x,y,template)
    local made,createWhy=self.api.addTestFieldUnits(team==1 and 'friends' or 'enemies',{{monster,1}})
    if not made or #made~=1 then
        local kept,observed,details=self:check(s,true,previous)
        if not kept then return self:quarantine(s,observed,before,details) end
        return refused('The game refused this unit ('..tostring(createWhy or 'creation unavailable')..'). Existing army verified unchanged.')
    end
    local unit=made[1]
    if previous.used[unit] then
        -- Never delete or configure a returned handle which belongs to an old actor.
        return self:quarantine(s,'allocation_returned_existing_handle',before,{native_id=unit,model_id=previous.used[unit],monster=monster})
    end
    self.live[u.id]=unit;local oldWidth=self.width;self.width=self.api.get('battleWidth')
    local ok,why=self.api.moveTestFieldUnit(unit,x,y)
    local stage='move'
    if ok and self.width~=oldWidth then stage='restore_positions_after_resize';ok,why=self:place(candidate) end
    if ok then stage='configure';ok,why=self:configure(u,unit) end
    if ok then stage='verify';local verified,observed=self:check(candidate,true,previous);ok=verified;why=verified and nil or observed end
    if not ok then
        local removed,removeWhy=self.api.removeTestFieldUnit(unit);self.live[u.id]=nil
        local retired,retirementWhy=self:retirementVerified(unit)
        if not retired or (not removed and removeWhy~='dead_unit') then
            self.cleanupFailed=true
            return self:quarantine(s,'The rejected actor could not be permanently retired. Restart the isolated game with the updated Extender and load the recovery file.',before,
                {model_id=u.id,native_id=unit,remove_result=removed and 1 or 0,remove_detail=removeWhy or 'ok',retirement_verified=retired and 1 or 0,retirement_detail=retirementWhy})
        end
        local restored,restoreWhy=self:check(s,true,previous)
        if not restored then
            local movable=self:check(s,false,previous)
            if movable then self:place(s);restored,restoreWhy=self:check(s,true,previous) end
        end
        if self.width~=oldWidth then self:cacheObjects() end
        local kept=restored
        self:failure(template and 'copy' or 'place',why or 'native target blocked',s,before,kept and 'existing army kept' or 'restore failed',
            {stage=stage,model_id=u.id,native_id=unit,monster=monster,name=u.name,team=team,x=x,y=y,
                remove_result=removed and 1 or 0,remove_detail=removeWhy or 'ok',rollback_verified=kept and 1 or 0,
                restore_detail=kept and 'old model/native identities, HP, spells, items, anchors and footprints match' or tostring(restoreWhy)})
        if not kept then return self:quarantine(s,'placement_rollback_unverified',before,{stage=stage,native_id=unit,
            operation_error=why or 'native target blocked',cleanup_result=removed and 1 or 0,cleanup_detail=removeWhy or 'ok',
            rollback_verified=0,detail=tostring(restoreWhy)}) end
        return false,kept and ('Placement refused: '..tostring(why or 'native target blocked')..'. Existing army kept; Export Diagnostics for details.') or
            'Placement failed and the previous positions could not be confirmed. Stop editing and Export Diagnostics.'
    end
    if self.width~=oldWidth then self:cacheObjects() end
    local good,observed,details=self:check(candidate,true,previous)
    if not good then return self:quarantine(s,observed,before,details) end
    self:accept(candidate,observed)
    if self.diag then self.diag:record(template and 'copy' or 'place',{name=u.name,id=u.id,model_id=u.id,live=unit,native_id=unit,team=team,x=x,y=y,old_width=oldWidth,width=self.width,result='verified'}) end
    return true,candidate,u
end
function R:retirementVerified(unit)
    if type(self.api.testFieldUnitState)~='function'then return false,'retirement query unavailable'end
    local ok,row,why=pcall(self.api.testFieldUnitState,unit)
    if not ok or type(row)~='table'then return false,tostring(why or row)end
    local retired=row.alive==false and row.hp==-9999 and row.worldX==-1 and row.worldY==-1 and
        type(row.anchors)=='table'and #row.anchors==0 and type(row.occupied)=='table'and #row.occupied==0
    return retired,retired and 'native tombstone, detached world coordinates and no occupied cells' or 'native permanent retirement not confirmed'
end
function R:remove(s,u)
    local before=self:snapshot(s)
    local healthy,previous=self:ready(s)
    if not healthy then return false,previous end
    local unit=self.live[u.id]
    if type(self.api.removeTestFieldUnit)~='function' then return false,'Safe removal requires the experimental editor API. Army kept.' end
    local ok,why=self.api.removeTestFieldUnit(unit)
    if not ok then
        local unchanged,observed,details=self:check(s,true,previous)
        if not unchanged then return self:quarantine(s,observed,before,details) end
    end
    if not ok and why=='primary_commander' then
        if M.count(s,1)<=1 or M.count(s,2)==0 then return false,'Keep one Team A unit as field commander. Add a replacement before removing this unit.' end
        local candidate=M.copy(s);M.remove(candidate,u.id)
        local good,reason=self:build(candidate)
        if good then return true,candidate end
        return false,reason
    elseif not ok then self:failure('delete',why,s,before,'unchanged',{name=u.name,id=u.id});return false,'The game refused removal. Army kept; Export Diagnostics for details.' end
    local retired,retirementWhy=self:retirementVerified(unit)
    if not retired then
        self.cleanupFailed=true
        return self:quarantine(s,'Native removal was not permanent. Restart the isolated game with the updated Extender and load the recovery file.',before,{model_id=u.id,native_id=unit,retirement_verified=0,retirement_detail=retirementWhy})
    end
    local candidate=M.copy(s);M.remove(candidate,u.id);self.live[u.id]=nil
    local good,observed,details=self:check(candidate,true,previous)
    if not good then self.live[u.id]=unit;return self:quarantine(s,observed,before,details) end
    self:accept(candidate,observed)
    if self.diag then self.diag:record('delete',{name=u.name,id=u.id,model_id=u.id,native_id=unit,result='permanently retired; native tombstone and world detachment verified; no anchor or hit cells'}) end
    return true,candidate
end
function R:memorize(u,spellName,on)
    local ready,previous=self:ready(self.current)
    if not ready then return false end
    local unit=self.live[u.id];local spell=self.catalog.spellKeys[spellName]
    if not spell then return false end
    if type(self.api.memorizeTestFieldSpell)=='function' then
        local ok,why,detail=self.api.memorizeTestFieldSpell(unit,spell,on)
        if not ok then
            local unchanged,observed,problem=self:check(self.current,true,previous)
            if not unchanged then return self:quarantine(self.current,observed,nil,problem) end
            self:observeSpellSelection(u,unit,nil,detail)
            if self.diag then self.diag:record('memorize_refused',{model_id=u.id,native_id=unit,spell=spell,reason=why,path=type(detail)=='table' and detail.path or 'unknown',allowance=type(detail)=='table' and detail.allowance or 'unknown'}) end
            return false,'Spell selection refused: '..tostring(why)
        end
    else
        -- The public primitive accepts over-quota spells; never call it unchecked.
        if on then
            local info=self.api.spellInfo(spell)
            if not info or type(self.api.memorizeAllowance)~='function' then return false,'Safe spell editing requires the experimental caster API.' end
            local count=0
            local known=false;for _,name in ipairs(self:spellList(unit,'unitKnownSpell',59)) do if name==spellName then known=true end end
            if not known or info.level>self.api.memorizeAllowance(unit,info.path)-1 then return false,'Spell is not known at the native caster level. Existing selection kept.' end
            for _,name in ipairs(self:spellList(unit,'unitMemorizedSpell',29)) do
                if name==spellName then return true end
                local other=self.api.spellInfo(self.catalog.spellKeys[name]);if other and other.path==info.path then count=count+1 end
            end
            if count>=self.api.memorizeAllowance(unit,info.path) then return false,'Native spell-school limit reached. Existing selection kept.' end
        end
        if on then self.api.memorizeSpell(unit,spell) else self.api.unmemorizeSpell(unit,spell) end
    end
    local actual=self:spellList(unit,'unitMemorizedSpell',29)
    local present=false;for _,name in ipairs(actual) do if name==spellName then present=true end end
    if present~=on then return false end
    u.spells=actual
    if self.current then for _,v in ipairs(self.current.units) do if v.id==u.id then v.spells=M.copy(u.spells) end end end
    if self.diag then self.diag:record('memorize',{name=u.name,id=u.id,spell=spellName,on=on and 1 or 0}) end
    local good,observed,details=self:check(self.current)
    if not good then self:quarantine(self.current,observed,nil,details);return false end
    self:accept(self.current,observed)
    for _,name in ipairs(u.spells) do if name==spellName then return on end end
    return not on
end
return R
