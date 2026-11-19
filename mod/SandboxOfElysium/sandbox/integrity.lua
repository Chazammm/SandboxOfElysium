-- Validate the model against a complete, guarded native test-field observation.
-- Pure validation below does not approximate native placement rules.
local Loadout=require('sandbox.loadout')
local I={}
local function alive(row)return row.alive==true or row.alive==1 end
local function fail(code,details,state)
    details=details or {};details.code=code
    return false,code,details,state
end
local function snapshotSignature(r,id,state)
    local observed,why=Loadout.validate(state,id);if not observed then return nil,why end
    local parts={items={},known={},memorized={},monster=r.api.get('unitMonster',id),owner=r.api.get('unitOwner',id),hp=r.api.get('unitHp',id)}
    local items={}
    for _,row in ipairs(observed.items)do
        items[#items+1]=tostring(row.id)
        if row.id>=0 then parts.items[#parts.items+1]=row.name end
    end
    for _,row in ipairs(observed.schools)do items[#items+1]='school:'..row.path..':'..row.base end
    for _,pair in ipairs({{observed.known,parts.known},{observed.memorized,parts.memorized}})do
        for _,spell in ipairs(pair[1])do
            local info=r.api.spellInfo(spell)
            if type(info)~='table'or type(info.name)~='string'then return nil,'Native spell identity is unavailable: '..tostring(spell)end
            pair[2][#pair[2]+1]=spell..':'..info.name
        end
    end
    return table.concat({tostring(parts.monster),tostring(parts.owner),tostring(parts.hp),
        table.concat(parts.known,'|'),table.concat(parts.memorized,'|'),table.concat(items,',')},';'),parts
end
function I.signature(r,id,observed)
    if observed~=nil then
        local signature,why=snapshotSignature(r,id,observed)
        if signature then return signature end
        return nil,why
    end
    -- Keep the public two-argument/older-extender signature format unchanged.
    local items={};for slot=0,type(r.api.testFieldLoadoutState)=='function' and 19 or 7 do items[#items+1]=tostring(r.api.get('unitItem',id,slot)) end
    if type(r.api.testFieldLoadoutState)=='function' then
        local state=r.api.testFieldLoadoutState(id)
        if type(state)=='table' then for _,row in ipairs(state.schools or {}) do items[#items+1]='school:'..row.path..':'..row.base end end
    end
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
    local rows,modelIds,used,signatures,structures={},{},{},{},{}
    for _,row in ipairs(state.units or {}) do rows[row.unit]=row end
    for _,u in ipairs(s.units or {}) do
        local id=r.live[u.id]
        if modelIds[u.id] then return fail('duplicate_model_id',{model_id=u.id},state) end
        modelIds[u.id]=true
        if type(id)~='number' then return fail('missing_native_handle',{model_id=u.id},state) end
        if used[id] then return fail('aliased_native_handle',{model_id=u.id,other_model_id=used[id],native_id=id},state) end
        used[id]=u.id
        local row=rows[id]
        if row and row.kind and row.kind~='actor' then return fail('model_structure_mismatch',{model_id=u.id,native_id=id,kind=row.kind},state) end
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
        -- One fresh read belongs only to this actor in this verification. Never
        -- reuse it from a prior check, mutation or recovery attempt.
        local loadout,parts
        if Loadout.available(r.api)then
            local why;loadout,why=Loadout.read(r,id)
            if not loadout then return fail('native_loadout_snapshot_incomplete',{model_id=u.id,native_id=id,reason=why},state)end
            if row.generation~=nil and loadout.generation~=row.generation then
                return fail('native_identity_mismatch',{model_id=u.id,native_id=id,reason='loadout generation changed'},state)
            end
            signatures[id],parts=snapshotSignature(r,id,loadout)
            if not signatures[id]then return fail('native_loadout_snapshot_incomplete',{model_id=u.id,native_id=id,reason=parts},state)end
            -- The complete field observation precedes the loadout read; these
            -- fresh identity getters must still match after that read.
            if parts.monster~=row.monster or parts.owner~=row.owner or parts.hp~=row.hp then
                return fail('native_identity_mismatch',{model_id=u.id,native_id=id,actual_monster=parts.monster,actual_owner=parts.owner,actual_hp=parts.hp},state)
            end
        else signatures[id]=I.signature(r,id)end
        if configuration~=false and u.baseline then
            if u.equipment then
                local matched,why=Loadout.matches(r,u,id,loadout)
                if not matched then return fail('saved_loadout_mismatch',{model_id=u.id,native_id=id,reason=why},state) end
            end
            local actualItems,savedItems=parts and parts.items or r:inventory(id),{}
            for _,item in ipairs(u.items or {}) do savedItems[#savedItems+1]=item end
            table.sort(actualItems);table.sort(savedItems)
            if table.concat(parts and parts.known or r:spellList(id,'unitKnownSpell',59),'|')~=table.concat(u.baseline.known,'|') or
                table.concat(parts and parts.memorized or r:spellList(id,'unitMemorizedSpell',29),'|')~=table.concat(u.spells or {},'|') or
                table.concat(actualItems,'|')~=table.concat(savedItems,'|') then
                return fail('saved_configuration_mismatch',{model_id=u.id,native_id=id},state)
            end
        end
        if previous and previous.signatures[id] and previous.signatures[id]~=signatures[id] then
            return fail('existing_configuration_changed',{model_id=u.id,native_id=id},state)
        end
    end
    for _,row in ipairs(state.units or {}) do
        if alive(row) and not used[row.unit] then
            -- Only a generation classified at the native constructor boundary
            -- may be outside the scenario/model bijection. Ownership/name/ID
            -- alone cannot make an unexplained actor safe.
            if row.kind~='structure' then return fail('orphaned_native_unit',{native_id=row.unit,monster=row.monster},state) end
            if state.classificationVersion~=1 or type(state.session)~='number' or state.session<1 or
                row.provenanceVerified~=true or row.creationSource~='native_gate_replacement' or
                type(row.generation)~='number' or row.generation<1 or row.anchorLayer~='unit' or
                row.anchorCount~=1 or #(row.anchors or {})~=1 or row.hp<=0 or
                (row.owner~=0 and row.owner~=24) or type(row.width)~='number' or type(row.height)~='number' or
                row.width<1 or row.width>3 or row.height<1 or row.height>3 or row.width%1~=0 or row.height%1~=0 or #(row.occupied or {})~=row.width*row.height then
                return fail('native_structure_unverified',{native_id=row.unit},state)
            end
            local anchor=row.anchors[1];local cells={}
            if type(anchor.x)~='number' or type(anchor.y)~='number' then return fail('native_structure_footprint',{native_id=row.unit},state) end
            for _,cell in ipairs(row.occupied)do
                if type(cell.x)~='number' or type(cell.y)~='number' then return fail('native_structure_footprint',{native_id=row.unit},state) end
                local key=cell.x..':'..cell.y
                if cells[key] or cell.x<anchor.x or cell.x>=anchor.x+row.width or cell.y<anchor.y or cell.y>=anchor.y+row.height or
                    cell.x<0 or cell.y<0 or cell.x>=state.width or cell.y>=state.height then
                    return fail('native_structure_footprint',{native_id=row.unit},state)
                end
                cells[key]=true
            end
            local signature=table.concat({state.session,row.generation,row.monster,row.owner,row.hp,anchor.x,anchor.y,row.width,row.height},':')
            if previous and previous.structures and previous.structures[row.unit]~=signature then
                return fail('native_structure_changed',{native_id=row.unit},state)
            end
            structures[row.unit]=signature
        end
    end
    if previous and previous.structures then for id in pairs(previous.structures)do
        if not structures[id]then return fail('native_structure_missing',{native_id=id},state)end
    end end
    for id in pairs(previous and previous.structures or {})do if not structures[id] then return fail('native_structure_changed',{native_id=id},state) end end
    for modelId,id in pairs(r.live) do if not modelIds[modelId] then return fail('orphaned_model_handle',{model_id=modelId,native_id=id},state) end end
    return true,{native=state,signatures=signatures,used=used,rows=rows,structures=structures}
end
-- This observation is never an editable/accepted field. It is the narrow input
-- to a one-shot native repair of authenticated initial actor packing. Ordinary
-- inspect above deliberately keeps rejecting exactly the same overlaps.
function I.initialIntake(r,s,receipt,state)
    local function reject(code,details)return fail(code,details,state)end
    local function integer(v)return type(v)=='number'and v%1==0 end
    local function key(x,y)return x..':'..y end
    if type(receipt)~='table'or receipt.version~=1 or receipt.fresh~=true or receipt.eligible~=true or
        receipt.sourceHealthy~=false or receipt.actorOverlapOnly~=true or receipt.completeRoster~=true or
        not integer(receipt.session)or receipt.session<1 or not integer(receipt.token)or receipt.token<1 then
        return reject('initial_receipt_unavailable',{reason=type(receipt)=='table'and receipt.reason or 'missing receipt'})
    end
    if type(state)~='table'or(state.complete~=true and state.complete~=1)or state.classificationVersion~=1 or
        state.session~=receipt.session or not integer(state.width)or state.width<1 or state.width>1536 or state.height~=20 or
        type(state.units)~='table'or type(state.grid)~='table'or #state.grid~=state.width*state.height or
        type(state.issues)~='table'or #state.issues==0 or type(receipt.actors)~='table'or type(receipt.overlaps)~='table'or #receipt.overlaps==0 then
        return reject('initial_snapshot_unverified')
    end
    if (state.allowMultipleUnique==true or state.allowMultipleUnique==1)~=(s.allowMultipleUnique==true)then return reject('native_unique_mode_mismatch')end
    local rows,used,modelIds,signatures,structures={},{},{},{},{}
    local anchors,coverage,hits={},{},{}
    for _,row in ipairs(state.units)do
        if type(row)~='table'or not integer(row.unit)or row.unit<0 or rows[row.unit]or not alive(row)or type(row.hp)~='number'or row.hp<=0 or
            not integer(row.generation)or row.generation<1 or not integer(row.monster)or row.monster<0 or not integer(row.owner)or
            row.provenanceVerified~=true or row.anchorLayer~='unit'or
            row.anchorCount~=1 or type(row.anchors)~='table'or #row.anchors~=1 or
            not integer(row.width)or not integer(row.height)or row.width<1 or row.width>3 or row.height<1 or row.height>3 then
            return reject('initial_actor_unverified',{native_id=type(row)=='table'and row.unit})
        end
        local anchor=row.anchors[1]
        if type(anchor)~='table'or not integer(anchor.x)or not integer(anchor.y)or anchor.x<0 or anchor.y<0 or
            anchor.x+row.width>state.width or anchor.y+row.height>state.height or anchors[key(anchor.x,anchor.y)]then
            return reject('initial_anchor_unverified',{native_id=row.unit})
        end
        if row.kind=='actor'then
            if row.creationSource~='owned_actor_creation'then return reject('initial_actor_provenance',{native_id=row.unit})end
        elseif row.kind~='structure'or row.creationSource~='native_gate_replacement'or(row.owner~=0 and row.owner~=24)then
            return reject('initial_nonroster_unverified',{native_id=row.unit})
        end
        rows[row.unit]=row;anchors[key(anchor.x,anchor.y)]=row.unit
        for x=anchor.x,anchor.x+row.width-1 do for y=anchor.y,anchor.y+row.height-1 do
            local cell=key(x,y);coverage[cell]=coverage[cell]or{};coverage[cell][row.unit]=true
        end end
        local seen={}
        if type(row.occupied)~='table'then return reject('initial_occupied_unverified',{native_id=row.unit})end
        for _,cell in ipairs(row.occupied)do
            if type(cell)~='table'or not integer(cell.x)or not integer(cell.y)then return reject('initial_occupied_unverified',{native_id=row.unit})end
            local position=key(cell.x,cell.y)
            if seen[position]or hits[position]or not(coverage[position]and coverage[position][row.unit])then return reject('initial_occupied_unverified',{native_id=row.unit,x=cell.x,y=cell.y})end
            seen[position]=true;hits[position]=row.unit
        end
        if row.kind=='structure'then
            if #row.occupied~=row.width*row.height then return reject('native_structure_footprint',{native_id=row.unit})end
            structures[row.unit]=table.concat({state.session,row.generation,row.monster,row.owner,row.hp,anchor.x,anchor.y,row.width,row.height},':')
        end
    end
    for index,cell in ipairs(state.grid)do
        if type(cell)~='table'or cell.x~=math.floor((index-1)/state.height)or cell.y~=(index-1)%state.height or
            cell.unit~=(anchors[key(cell.x,cell.y)]or-1)or not integer(cell.object)or cell.object< -1 then return reject('initial_grid_unverified')end
    end
    for _,u in ipairs(s.units or{})do
        local id=r.live[u.id];local row=rows[id]
        if modelIds[u.id]or type(id)~='number'or used[id]or not row or row.kind~='actor'then return reject('initial_roster_unverified',{model_id=u.id,native_id=id})end
        if row.monster~=u.monster or row.owner~=(u.team==1 and 0 or 24)then return reject('native_identity_mismatch',{model_id=u.id,native_id=id})end
        modelIds[u.id]=true;used[id]=u.id
    end
    local receiptIds={}
    if #receipt.actors~=#(s.units or{})then return reject('initial_roster_unverified')end
    for _,entry in ipairs(receipt.actors)do
        local row=type(entry)=='table'and rows[entry.unit]
        if not row or not used[entry.unit]or receiptIds[entry.unit]or entry.kind~='actor'or entry.creationSource~='owned_actor_creation'or entry.provenanceVerified~=true or
            entry.generation~=row.generation or entry.monster~=row.monster or entry.owner~=row.owner or entry.width~=row.width or entry.height~=row.height or
            entry.x~=row.anchors[1].x or entry.y~=row.anchors[1].y then return reject('initial_receipt_roster_mismatch')end
        receiptIds[entry.unit]=true
    end
    for id,row in pairs(rows)do if row.kind=='actor'and not used[id]then return reject('orphaned_native_unit',{native_id=id})end end
    for modelId,id in pairs(r.live)do if not modelIds[modelId]then return reject('orphaned_model_handle',{model_id=modelId,native_id=id})end end
    local overlaps,expectedIssues={},{}
    for _,overlap in ipairs(receipt.overlaps)do
        if type(overlap)~='table'or not integer(overlap.x)or not integer(overlap.y)or not used[overlap.unit]or not used[overlap.otherUnit]or overlap.unit==overlap.otherUnit then return reject('initial_overlap_unverified')end
        local position=key(overlap.x,overlap.y);local owners=coverage[position]
        local issue=overlap.unit..'@'..position
        if not owners or not owners[overlap.unit]or not owners[overlap.otherUnit]or hits[position]~=overlap.otherUnit or overlaps[issue]then return reject('initial_overlap_unverified')end
        overlaps[issue]=true
    end
    for position,owners in pairs(coverage)do
        local hit=hits[position];local number,structural=0,false
        for id in pairs(owners)do number=number+1;structural=structural or rows[id].kind=='structure'end
        if not hit or not owners[hit]or(number>1 and structural)then return reject('initial_coverage_unverified')end
        for id in pairs(owners)do if hit~=id then
            local issue=id..'@'..position
            if not overlaps[issue]then return reject('initial_overlap_unverified',{native_id=id})end
            expectedIssues[issue]=true
        end end
    end
    for position in pairs(hits)do if not coverage[position]then return reject('initial_coverage_unverified')end end
    local found={}
    for _,issue in ipairs(state.issues)do
        if type(issue)~='table'or not integer(issue.unit)or not integer(issue.x)or not integer(issue.y)then return reject('initial_issue_unverified')end
        local name=issue.unit..'@'..key(issue.x,issue.y)
        if issue.code~='overlapping_footprint'or not expectedIssues[name]or found[name]then return reject('initial_issue_unverified')end
        found[name]=true
    end
    for name in pairs(expectedIssues)do if not found[name]then return reject('initial_issue_unverified')end end
    for name in pairs(overlaps)do if not expectedIssues[name]then return reject('initial_overlap_unverified')end end
    -- Read every actor's real configuration, preserving its actual ordered
    -- spell signature. Native receipt freshness is checked again at commit.
    for _,u in ipairs(s.units or{})do
        local id=r.live[u.id];local row=rows[id]
        if type(r.api.testFieldSpellState)=='function'and u.baseline and #(u.baseline.known or{})>0 then
            local caster,reason=r.api.testFieldSpellState(id)
            if type(caster)~='table'or caster.complete~=true or caster.valid~=true then return reject('native_caster_snapshot_incomplete',{model_id=u.id,native_id=id,reason=reason})end
        end
        if Loadout.available(r.api)then
            local loadout,why=Loadout.read(r,id);if not loadout then return reject('native_loadout_snapshot_incomplete',{model_id=u.id,native_id=id,reason=why})end
            if loadout.generation~=row.generation then return reject('native_identity_mismatch',{model_id=u.id,native_id=id})end
            local parts;signatures[id],parts=snapshotSignature(r,id,loadout)
            if not signatures[id]or parts.monster~=row.monster or parts.owner~=row.owner or parts.hp~=row.hp then return reject('native_identity_mismatch',{model_id=u.id,native_id=id})end
        else
            signatures[id]=I.signature(r,id)
            if r.api.get('unitMonster',id)~=row.monster or r.api.get('unitOwner',id)~=row.owner or r.api.get('unitHp',id)~=row.hp then return reject('native_identity_mismatch',{model_id=u.id,native_id=id})end
        end
    end
    return true,{native=state,signatures=signatures,used=used,rows=rows,structures=structures,
        provisionalInitial=true,initialReceipt=receipt}
end
return I
