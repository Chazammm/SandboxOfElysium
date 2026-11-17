local M=require('sandbox.model')
local D={};D.__index=D
local secretPatterns={}
for _,word in ipairs({'token','password','secret','apikey','api_key'}) do
    secretPatterns[#secretPatterns+1]=word:gsub('%a',function(c)return '['..c:lower()..c:upper()..']' end)
end
local function text(v)
    local s=tostring(v==nil and 'unavailable' or v)
    s=s:gsub('%a:[/\\][^\r\n]*','[local path]'):gsub('\\\\[^\r\n]*','[network path]')
    for _,key in ipairs(secretPatterns) do
        s=s:gsub('('..key..')%s*[:=]%s*[^%s;,]+','%1=[redacted]')
    end
    return s:sub(1,4096)
end
local function get(api,key,...)
    local ok,value=pcall(api.get,key,...);return ok and value or nil
end
local function flat(values)
    local out={};for k,v in pairs(values or {}) do if type(v)~='table' then
        local key=tostring(k);local lower=key:lower()
        out[key]=(lower:find('password',1,true) or lower:find('token',1,true) or lower:find('secret',1,true) or lower=='api_key') and '[redacted]' or text(v)
    end end;return out
end
function D.new(api)
    local ok,context=pcall(api.readIni,'launcher-context')
    return setmetatable({api=api,context=ok and context and context.environment or {},events={},sequence=0,
        started=get(api,'ticksMs') or 0,exports=0,version=require('sandbox.version')},D)
end
function D:record(action,details)
    self.sequence=self.sequence+1
    local event=flat(details);event.action=text(action);event.sequence=self.sequence;event.ticks_ms=get(self.api,'ticksMs') or 'unknown'
    self.events[#self.events+1]=event;if #self.events>64 then table.remove(self.events,1) end
end
function D:snapshot(s,runtime)
    local units=s.units or {}
    local native,rows={},{}
    if runtime.open and type(self.api.testFieldState)=='function' then
        local ok,value=pcall(self.api.testFieldState);if ok and type(value)=='table' then native=value end
    end
    for _,row in ipairs(native.units or {}) do rows[row.unit]=row end
    local aliases={};for _,u in ipairs(units) do local id=runtime.live[u.id];if id then aliases[id]=aliases[id] or {};aliases[id][#aliases[id]+1]=u.id end end
    local function cells(values)
        local result={};for _,p in ipairs(values or {}) do result[#result+1]=p.x..','..p.y end;return table.concat(result,';')
    end
    local out={summary={units=#units,terrain=s.terrain,open=runtime.open and 1 or 0,width=runtime.width or 'unknown',limit=24,
        observation_phase=runtime.phase or 'prepare',observation_scope=runtime.phase=='after' and 'native state after cleanup; saved model is pre-battle setup' or 'editable native field versus saved model',
        field_generation=runtime.generation or 'unknown',editing_locked=runtime.blocked and 1 or 0,
        recovery_file=runtime.recoveryFile or 'not written or not needed',allow_multiple_unique=s.allowMultipleUnique and 1 or 0,
        native_classification_version=native.classificationVersion,native_session=native.session,native_query_complete=native.complete==true and 1 or 0,native_rows=#(native.units or {}),native_issues=#(native.issues or {}),
        limits='24 model rows; 48 native rows; 256 nonempty raw grid cells; capped export, not complete engine state'},units={},nativeUnits={},cells={}}
    if runtime.open and type(self.api.testFieldEnvironmentState)=='function'then
        local ok,value,why=pcall(self.api.testFieldEnvironmentState)
        if ok and type(value)=='table'then
            for _,key in ipairs({'version','plane','ground','temperature','fortParts','nativeTemplate','nativeTemplateObserved','customMapReplaced','setupReturned','atSea','boatCountA','boatCountB','siege','tower','underground','scope'})do
                local v=value[key];out.summary['environment_'..key]=type(v)=='boolean'and(v and 1 or 0)or v
            end
        else out.summary.environment_result=tostring(why or value)end
    end
    for i=1,math.min(24,#units) do
        local u=units[i];local live=runtime.live[u.id]
        local row={id=u.id,model_id=u.id,monster=u.monster,name=u.name,sandbox_label=u.label or '',label_scope='legacy sandbox-only label; separate from native personal name',display_name_hex=M.displayName(u):gsub('.',function(c)return('%02x'):format(c:byte())end),saved_native_name_hex=u.nativeName and u.nativeName:gsub('.',function(c)return('%02x'):format(c:byte())end)or 'not configured',native_name_scope='native_individual_v1; hex preserves whitespace and UTF-8',team=u.team,saved_x=u.x,saved_y=u.y,live=live or 'none',native_id=live or 'none',
            saved_known=table.concat(u.baseline and u.baseline.known or {},'|'),saved_memorized=table.concat(u.spells or {},'|'),saved_items=table.concat(u.items or {},'|')}
        row.actor_state_scope='bounded supported subset; not full native unit state'
        if u.condition then for _,key in ipairs({'hp','xp','kills','injuryFlags','maxHp','width','height'})do row['saved_actor_'..key]=u.condition[key]end end
        if live and type(self.api.testFieldActorState)=='function'then
            local ok,state,why=pcall(self.api.testFieldActorState,live)
            row.actor_state_result=ok and type(state)=='table'and 'bounded snapshot'or tostring(why or state)
            if ok and type(state)=='table'then
                row.actor_state_complete=state.complete and 1 or 0;row.full_native_state=state.fullState and 1 or 0
                for _,key in ipairs({'hp','xp','kills','injuryFlags','maxHp','width','height'})do row['actual_actor_'..key]=state[key]end
            end
        end
        if live and type(self.api.testFieldUnitName)=='function'then
            local ok,state,why=pcall(self.api.testFieldUnitName,live)
            row.native_name_result=ok and type(state)=='table'and 'observed'or tostring(why or state)
            if ok and type(state)=='table'then
                row.native_name_hex=state.name:gsub('.',function(c)return('%02x'):format(c:byte())end)
                row.native_name_shown_hex=state.shown:gsub('.',function(c)return('%02x'):format(c:byte())end)
                row.native_name_custom=state.custom and 1 or 0;row.native_name_storage=state.storage
                row.native_name_generation=state.generation;row.native_name_commander=state.commander
                row.native_name_formatter_reads=state.formatterReads;row.native_name_combat_reads=state.combatReads
            end
        end
        if live then
            row.hp=get(self.api,'unitHp',live);row.x=get(self.api,'unitBattleX',live);row.y=get(self.api,'unitBattleY',live)
            row.world_x=get(self.api,'unitX',live);row.world_y=get(self.api,'unitY',live)
            row.native_monster=get(self.api,'unitMonster',live);row.native_owner=get(self.api,'unitOwner',live)
            local function list(fn,...)
                local ok,value=pcall(fn,runtime,...);return ok and type(value)=='table' and table.concat(value,'|') or 'unavailable'
            end
            row.actual_known=list(runtime.spellList,live,'unitKnownSpell',59)
            row.actual_memorized=list(runtime.spellList,live,'unitMemorizedSpell',29)
            row.actual_items=list(runtime.inventory,live)
            local savedEquipment,savedSchools={},{}
            for _,v in ipairs(u.equipment or {}) do savedEquipment[#savedEquipment+1]=v.position..':'..v.id..':'..v.name end
            for _,v in ipairs(u.schools or {}) do savedSchools[#savedSchools+1]=v.path..':'..v.name..':base='..v.base end
            row.saved_item_positions=table.concat(savedEquipment,'|');row.saved_base_schools=table.concat(savedSchools,'|')
            if type(self.api.testFieldLoadoutState)=='function' then
                local ok,state,reason=pcall(self.api.testFieldLoadoutState,live)
                row.loadout_scope='owned editable field only; unavailable after battle or while fighting'
                row.loadout_result=ok and type(state)=='table' and (state.complete and 'complete' or 'partial') or tostring(reason or state)
                if ok and type(state)=='table' then
                    local equipment,schools={},{}
                    for _,v in ipairs(state.items or {}) do equipment[#equipment+1]=v.position..':type='..v.slotType..':item='..v.id end
                    for _,v in ipairs(state.schools or {}) do schools[#schools+1]=v.path..':base='..v.base..':template='..v.templateBase..':bonus='..v.bonus..':effective='..v.level..':allowance='..v.allowance end
                    row.actual_item_positions=table.concat(equipment,'|');row.actual_base_schools=table.concat(schools,'|')
                end
            end
            row.life_status=row.hp and (row.hp>0 and 'alive' or 'dead_or_retired') or 'unknown'
            row.model_ids_for_native=table.concat(aliases[live] or {},',')
            local n=rows[live]
            if n then
                row.native_monster=n.monster;row.native_owner=n.owner;row.anchor_count=n.anchorCount
                row.anchors=cells(n.anchors);row.footprint_w=n.width;row.footprint_h=n.height
                row.native_occupied=cells(n.occupied);row.occupied_count=#(n.occupied or {})
                row.world_x=n.worldX;row.world_y=n.worldY
            else row.native_query_row='not present (retired, foreign, or unavailable); see completeness' end
        else row.native_state='unavailable' end
        out.units[#out.units+1]=flat(row)
    end
    for i,n in ipairs(native.units or {}) do if i>48 then break end
        out.nativeUnits[#out.nativeUnits+1]=flat({native_id=n.unit,kind=n.kind,creation_source=n.creationSource,provenance_verified=n.provenanceVerified,generation=n.generation,anchor_layer=n.anchorLayer,hp=n.hp,monster=n.monster,owner=n.owner,alive=n.alive,
            anchor_count=n.anchorCount,anchors=cells(n.anchors),footprint_w=n.width,footprint_h=n.height,occupied=cells(n.occupied),
            model_ids=table.concat(aliases[n.unit] or {},','),world_x=n.worldX,world_y=n.worldY})
    end
    local nonempty=0
    for _,g in ipairs(native.grid or {}) do if (g.unit and g.unit>=0) or (g.object and g.object>=0) then
        nonempty=nonempty+1
        if #out.cells<256 then out.cells[#out.cells+1]=flat({x=g.x,y=g.y,raw_unit=g.unit,raw_object=g.object}) end
    end end
    out.summary.nonempty_raw_cells=nonempty;out.summary.raw_cells_exported=#out.cells
    local issues={};for i,issue in ipairs(native.issues or {}) do if i>32 then break end;issues[#issues+1]=tostring(issue.code)..':'..tostring(issue.unit or '')..'@'..tostring(issue.x or '')..','..tostring(issue.y or '') end
    out.summary.native_issue_details=table.concat(issues,';')
    out.summary.truncated=#units>#out.units and 1 or 0
    local final=runtime.finalState
    if type(final)=='table' then
        out.final={summary={source=final.source,phase=final.phase,complete=final.complete,scene_complete=false,
            units_total=#(final.units or {}),units_exported=math.min(48,#(final.units or {})),cells_total=#(final.grid or {}),
            width=final.width,height=final.height,round=final.round,winner=final.winner,issues=#(final.issues or {}),
            limits='48 captured unit rows, actors before terrain; native unit/cell completeness is separate from bounded export; no effects/projectiles'},units={}}
        for _,n in ipairs(require('sandbox.final_view').exportUnits(final,48)) do
            local row={};for k,v in pairs(n) do if type(v)~='table' then row[k]=v end end
            row.anchors=cells(n.anchors);row.occupied=cells(n.occupied)
            out.final.units[#out.final.units+1]=flat(row)
        end
    end
    return out
end
function D:preserve(s,mods)
    local data=M.encode(s,mods)
    data.recovery={status='preserved model; reopen explicitly and verify native state',source='last verified setup or model at first integrity failure'}
    local used={};for _,name in ipairs(self.api.listIni()) do used[name]=true end
    local stamp=(self.context.session or tostring(self.started)):gsub('[^%w%-]',''):sub(1,20)
    local n=0;local name
    repeat n=n+1;name='recovery-'..stamp..'-'..n until not used[name]
    if not self.api.writeIni(name,data) then return nil,'Recovery file could not be written; in-memory setup is kept. Export Diagnostics.' end
    return name,(self.context.data_folder or '<Sandbox data folder>')..'/'..name..'.ini'
end
function D:saveRepair(s,mods,original)
    local data=M.encode(s,mods)
    data.repair={status='explicit user-selected spell correction; verified native setup',exact_restoration_of_original=0,original_recovery=original or 'in-memory original preserved'}
    local used={};for _,name in ipairs(self.api.listIni()) do used[name]=true end
    local stamp=(self.context.session or tostring(self.started)):gsub('[^%w%-]',''):sub(1,20)
    local n=0;local name
    repeat n=n+1;name='repaired-'..stamp..'-'..n until not used[name]
    if not self.api.writeIni(name,data) then return nil,'Verified repaired copy could not be saved. Original recovery is kept; save this setup under a new name.' end
    return name,(self.context.data_folder or '<Sandbox data folder>')..'/'..name..'.ini'
end
function D:failure(action,message,details,before,after,restored)
    self.lastError={message=text(message),action=text(action),details=flat(details),before=M.copy(before),after=M.copy(after),restored=text(restored)}
    self:record('error',{operation=action,message=message,restored=restored})
end
function D:export(context,snapshot)
    local api=self.api
    local data={environment={sandbox_version=self.version,game_version=self.context.game_version or 'unknown',
        extender_version=self.context.extender_version or 'unknown',extender_build=self.context.extender_build or 'unknown',
        sandbox_source_hash=self.context.sandbox_source_hash or 'unknown',launcher_utc=self.context.launcher_utc or 'unknown',
        export_wall_clock='unavailable; launcher UTC and monotonic ticks are separate',
        elapsed_since_diagnostics_ms=((get(api,'ticksMs') or self.started)-self.started)%4294967296,
        limits='64 recent actions; 24 model/48 native rows and 256 nonempty raw cells per snapshot; values limited to 4096 chars; not a complete engine snapshot'},
        selection=flat(context),limitations={mod_versions='No supported per-mod version getter; unknown',
            spells='IDs and names from saved scenario and native getters',privacy='No full logs, credentials, keys, profile config or absolute paths included'}}
    for k,v in pairs(data.environment) do data.environment[k]=text(v) end
    local last=get(api,'modLastIndex') or -1
    for i=0,last do if get(api,'modEnabled',i)~=0 then data['mod'..i]={name=text(get(api,'modName',i)),version='unknown'} end end
    for i,event in ipairs(self.events) do data[('action%03d'):format(i)]=flat(event) end
    local function addSnapshot(prefix,value)
        if not value then data[prefix]={state='unavailable'};return end
        data[prefix]=flat(value.summary)
        for i,row in ipairs(value.units or {}) do data[prefix..'_unit'..i]=flat(row) end
        for i,row in ipairs(value.nativeUnits or {}) do data[prefix..'_native'..i]=flat(row) end
        for i,row in ipairs(value.cells or {}) do data[prefix..'_cell'..i]=flat(row) end
        if value.final then
            data[prefix..'_final']=flat(value.final.summary)
            for i,row in ipairs(value.final.units or {}) do data[prefix..'_final_unit'..i]=flat(row) end
        end
    end
    addSnapshot('current',snapshot)
    local validations=0
    for _,v in pairs(self.spellValidation or {}) do
        validations=validations+1;if validations>24 then break end
        local prefix='caster_'..validations
        data[prefix]=flat({model_id=v.model_id,native_id=v.native_id,monster=v.monster,name=v.name,reason=v.reason or 'accepted',
            saved_known=table.concat(v.saved_known or {},'|'),saved_memorized=table.concat(v.saved_memorized or {},'|'),
            actual_known_ids=table.concat(v.native.known or {},','),actual_memorized_ids=table.concat(v.native.memorized or {},','),
            native_complete=v.native.complete,native_valid=v.native.valid})
        data[prefix..'_detail']=flat(v.detail)
        for i,row in ipairs(v.schools or {}) do data[prefix..'_school'..i]=flat(row) end
    end
    data.caster_limits={max_casters=24,scope='bounded saved/actual spell IDs grouped by school with native allowances; not a complete engine snapshot'}
    local lifecycle=self.lifecycle
    if type(api.testFieldLifecycle)=='function' then
        local ok,value=pcall(api.testFieldLifecycle)
        if ok and type(value)=='table' then lifecycle=value end
    end
    local function addLifecycle(prefix,value)
        if type(value)~='table' then data[prefix]={state='native lifecycle observation unavailable'};return end
        data[prefix]=flat(value)
        data[prefix].limits='128 rows per phase; capped provenance ledger, not complete world state'
        for _,phase in ipairs({'created','beforeCleanup','afterCleanup','issues'}) do
            local rows=value[phase] or {}
            data[prefix][phase..'_total']=#rows;data[prefix][phase..'_exported']=math.min(128,#rows)
            for i=1,math.min(128,#rows) do data[prefix..'_'..phase..'_'..i]=flat(rows[i]) end
        end
    end
    addLifecycle('lifecycle',lifecycle)
    if self.lifecycle and (not lifecycle or self.lifecycle.session~=lifecycle.session) then
        addLifecycle('previous_cleanup',self.lifecycle)
    end
    if self.lastError then
        data.error={action=self.lastError.action,message=self.lastError.message,restored=self.lastError.restored}
        data.error_context=flat(self.lastError.details)
        addSnapshot('before',self.lastError.before);addSnapshot('after',self.lastError.after)
    else data.error={state='no recorded error in this session'} end
    if self.firstIntegrity then
        data.first_integrity={action=self.firstIntegrity.action,message=self.firstIntegrity.message,restored=self.firstIntegrity.restored}
        data.first_integrity_context=flat(self.firstIntegrity.details)
        addSnapshot('first_integrity_before',self.firstIntegrity.before);addSnapshot('first_integrity_after',self.firstIntegrity.after)
    end
    local used={};for _,name in ipairs(api.listIni()) do used[name]=true end
    local stamp=(self.context.session or tostring(self.started)):gsub('[^%w%-]',''):sub(1,20)
    local name
    repeat self.exports=self.exports+1;name='diagnostics-'..stamp..'-'..self.exports until not used[name]
    if not api.writeIni(name,data) then return nil,'The game refused the diagnostic export (file quota or storage error).' end
    local folder=self.context.data_folder or '<Sandbox data folder>'
    return name,folder..'/'..name..'.ini'
end
return D
