-- Validate the model against a complete, guarded native test-field observation.
-- Pure validation below does not approximate native placement rules.
local I={}
local function alive(row)return row.alive==true or row.alive==1 end
local function fail(code,details,state)
    details=details or {};details.code=code
    return false,code,details,state
end
function I.signature(r,id)
    local items={};for slot=0,7 do items[#items+1]=tostring(r.api.get('unitItem',id,slot)) end
    return table.concat({tostring(r.api.get('unitMonster',id)),tostring(r.api.get('unitOwner',id)),tostring(r.api.get('unitHp',id)),
        table.concat(r:spellList(id,'unitKnownSpell',59),'|'),table.concat(r:spellList(id,'unitMemorizedSpell',29),'|'),table.concat(items,',')},';')
end
function I.inspect(r,s,positions,previous,configuration)
    if type(r.api.testFieldState)~='function' then return fail('editor_state_api_missing') end
    local ok,state=pcall(r.api.testFieldState)
    if not ok or type(state)~='table' then return fail('native_state_unavailable',{detail=tostring(state)}) end
    r.latestNative=state
    if state.allowMultipleUnique~=nil and (state.allowMultipleUnique==true or state.allowMultipleUnique==1)~=(s.allowMultipleUnique==true) then
        return fail('native_unique_mode_mismatch',nil,state)
    end
    if state.complete~=true and state.complete~=1 then return fail('native_snapshot_incomplete',nil,state) end
    if #(state.issues or {})>0 then
        local issue=state.issues[1]
        return fail('native_integrity_issue',{issue=issue.code,native_id=issue.unit,x=issue.x,y=issue.y},state)
    end
    local rows,modelIds,used,signatures={},{},{},{}
    for _,row in ipairs(state.units or {}) do rows[row.unit]=row end
    for _,u in ipairs(s.units or {}) do
        local id=r.live[u.id]
        if modelIds[u.id] then return fail('duplicate_model_id',{model_id=u.id},state) end
        modelIds[u.id]=true
        if type(id)~='number' then return fail('missing_native_handle',{model_id=u.id},state) end
        if used[id] then return fail('aliased_native_handle',{model_id=u.id,other_model_id=used[id],native_id=id},state) end
        used[id]=u.id
        local row=rows[id]
        if not row or not alive(row) or not row.hp or row.hp<=0 then return fail('model_unit_not_alive',{model_id=u.id,native_id=id},state) end
        if row.monster~=u.monster or row.owner~=(u.team==1 and 0 or 24) then
            return fail('native_identity_mismatch',{model_id=u.id,native_id=id,actual_monster=row.monster,actual_owner=row.owner},state)
        end
        if type(r.api.testFieldSpellState)=='function' and u.baseline and #(u.baseline.known or {})>0 then
            local caster,reason=r.api.testFieldSpellState(id)
            if type(caster)~='table' or caster.complete~=true then return fail('native_caster_snapshot_incomplete',{model_id=u.id,native_id=id,reason=reason},state) end
            if caster.valid~=true then
                local issue=(caster.issues or {})[1] or {}
                return fail('native_spell_selection_invalid',{model_id=u.id,native_id=id,reason=issue.code,path=issue.path,actual=issue.actual,allowed=issue.allowed},state)
            end
        end
        if row.anchorCount~=1 or not row.anchors or #row.anchors~=1 then return fail('invalid_anchor_count',{model_id=u.id,native_id=id},state) end
        local anchor=row.anchors[1]
        if positions and (anchor.x~=u.x or anchor.y~=u.y) then
            return fail('native_position_mismatch',{model_id=u.id,native_id=id,saved_x=u.x,saved_y=u.y,actual_x=anchor.x,actual_y=anchor.y},state)
        end
        if type(row.width)~='number' or type(row.height)~='number' or row.width<1 or row.height<1 then return fail('invalid_footprint',{native_id=id},state) end
        local cells={}
        for _,cell in ipairs(row.occupied or {}) do cells[cell.x..':'..cell.y]=true end
        if #(row.occupied or {})~=row.width*row.height then return fail('native_footprint_mismatch',{model_id=u.id,native_id=id},state) end
        for x=anchor.x,anchor.x+row.width-1 do for y=anchor.y,anchor.y+row.height-1 do
            if not cells[x..':'..y] then return fail('native_footprint_mismatch',{model_id=u.id,native_id=id,x=x,y=y},state) end
        end end
        signatures[id]=I.signature(r,id)
        if configuration~=false and u.baseline then
            local actualItems,savedItems=r:inventory(id),{}
            for _,item in ipairs(u.items or {}) do savedItems[#savedItems+1]=item end
            table.sort(actualItems);table.sort(savedItems)
            if table.concat(r:spellList(id,'unitKnownSpell',59),'|')~=table.concat(u.baseline.known,'|') or
                table.concat(r:spellList(id,'unitMemorizedSpell',29),'|')~=table.concat(u.spells or {},'|') or
                table.concat(actualItems,'|')~=table.concat(savedItems,'|') then
                return fail('saved_configuration_mismatch',{model_id=u.id,native_id=id},state)
            end
        end
        if previous and previous.signatures[id] and previous.signatures[id]~=signatures[id] then
            return fail('existing_configuration_changed',{model_id=u.id,native_id=id},state)
        end
    end
    for _,row in ipairs(state.units or {}) do
        if alive(row) and not used[row.unit] then return fail('orphaned_native_unit',{native_id=row.unit,monster=row.monster},state) end
    end
    for modelId,id in pairs(r.live) do if not modelIds[modelId] then return fail('orphaned_model_handle',{model_id=modelId,native_id=id},state) end end
    return true,{native=state,signatures=signatures,used=used,rows=rows}
end
return I
