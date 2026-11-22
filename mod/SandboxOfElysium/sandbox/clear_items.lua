-- Batch orchestration only. Each actor is one native verified transaction;
-- a failure does not undo successfully completed actors or rebuild the field.
local M=require('sandbox.model')
local Loadout=require('sandbox.loadout')
local B={}
function B.available(r)
    if not r or type(r.clearHeldItems)~='function' or not Loadout.available(r.api) or type(r.api.testFieldEditorCapabilities)~='function' then return false end
    local ok,caps=pcall(r.api.testFieldEditorCapabilities)
    return ok and type(caps)=='table' and (caps.clearHeldItems==1 or caps.clearHeldItems==true)
end
function B.plan(r,s)
    if not B.available(r) then return nil,'Clear All Held Items needs the updated experimental equipment API. Current setup kept.' end
    local ready,why=r:ready(s);if not ready then return nil,why end
    local plan={actors={},units=M.count(s,1)+M.count(s,2),teamA=0,teamB=0,items=0,cursed=0,implanted=0}
    for _,u in ipairs(s.units) do if not u.scenery then
        local native=r.live[u.id];local state;state,why=Loadout.read(r,native)
        if not state then return nil,'Cannot verify '..M.displayName(u)..' #'..u.id..': '..tostring(why) end
        if type(state.generation)~='number' or type(state.organInjuryFlags)~='number' then return nil,'Native equipment identity/injury readback is incomplete. Current setup kept.' end
        local expected={unit=native,generation=state.generation,items={},known=M.copy(state.known),memorized=M.copy(state.memorized),schools={},organInjuryFlags=state.organInjuryFlags}
        local held,cursed,implanted=0,0,0
        for _,slot in ipairs(state.items) do
            expected.items[#expected.items+1]=slot.id
            if slot.id>=0 then
                held=held+1;if slot.cursed then cursed=cursed+1 end;if slot.permanentEffects then implanted=implanted+1 end
            end
        end
        for _,school in ipairs(state.schools) do expected.schools[#expected.schools+1]={path=school.path,base=school.base} end
        if held>0 then
            plan.actors[#plan.actors+1]={model_id=u.id,native_id=native,name=M.displayName(u),team=u.team,items=held,expected=expected}
            if u.team==1 then plan.teamA=plan.teamA+1 else plan.teamB=plan.teamB+1 end
        end
        plan.items=plan.items+held;plan.cursed=plan.cursed+cursed;plan.implanted=plan.implanted+implanted
    end end
    return plan
end
function B.run(r,s,plan)
    local result={ok=true,completed=0,removed=0,total=#plan.actors,remaining=#plan.actors}
    for _,row in ipairs(plan.actors) do
        local u;for _,candidate in ipairs(s.units) do if candidate.id==row.model_id then u=candidate;break end end
        local ok,why,detail
        if not u or r.live[row.model_id]~=row.native_id then
            ok=false;why='The actor identity changed after confirmation.';detail={rollbackVerified=true}
        else ok,why,detail=r:clearHeldItems(s,u,row.expected) end
        if not ok then
            result.ok=false;result.reason=tostring(why);result.failed=row;result.rollbackVerified=type(detail)=='table' and detail.rollbackVerified==true
            result.detail=detail
            break
        end
        result.completed=result.completed+1;result.removed=result.removed+row.items;result.remaining=result.total-result.completed
    end
    return result
end
function B.describe(result)
    local progress=('Cleared %d/%d actors (%d held items), across both teams.'):format(result.completed,result.total,result.removed)
    if result.ok then return progress..' Spells and existing injuries were preserved.' end
    local failed=result.failed
    return progress..' Stopped at '..tostring(failed and failed.name or 'unknown actor')..' #'..tostring(failed and failed.model_id or '?')..'. '..
        (result.rollbackVerified and 'Failed actor verified unchanged. ' or 'Failed actor state is unverified; editing must remain locked. ')..
        tostring(result.remaining)..' actors were not cleared. '..result.reason
end
return B
