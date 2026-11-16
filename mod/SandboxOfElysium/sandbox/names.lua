local M=require('sandbox.model')
local N={}
function N.available(api)
    if type(api.testFieldUnitName)~='function'or type(api.setTestFieldUnitName)~='function'or type(api.testFieldEditorCapabilities)~='function'then return false end
    local ok,caps=pcall(api.testFieldEditorCapabilities)
    return ok and type(caps)=='table'and caps.individualNameVersion==1 and caps.individualNameMaxBytes==M.nativeNameBytes
end
function N.read(r,unit)
    if not N.available(r.api)then return nil,'Native individual naming needs the separate experimental naming API. Previous name kept.'end
    local ok,state,why=pcall(r.api.testFieldUnitName,unit)
    if not ok then return nil,tostring(state)end
    if type(state)~='table'or state.version~=1 or state.unit~=unit or type(state.name)~='string'or type(state.shown)~='string'or type(state.custom)~='boolean'then return nil,why or 'Native name readback is incomplete.'end
    return state
end
function N.matches(r,u,unit)
    if u.nativeName==nil then return true end
    local state,why=N.read(r,unit);if not state then return false,why end
    if u.nativeName==''then return not state.custom,not state.custom and state or 'Native name override was not cleared.'end
    if not state.custom or state.name~=u.nativeName then return false,'Native individual name differs from the recorded setup.'end
    return true,state
end
function N.apply(r,u,unit)
    if u.nativeName==nil then return true end
    local valid,why=M.validNativeName(u.nativeName);if not valid then return false,why end
    if not N.available(r.api)then return false,'Recorded individual names need the experimental naming API. Existing setup kept.'end
    local called,ok,reason,detail=pcall(r.api.setTestFieldUnitName,unit,u.nativeName)
    if not called then return false,tostring(ok),{rollbackVerified=false}end
    if not ok then return false,'Native rename refused: '..tostring(reason),detail end
    local matched,state=N.matches(r,u,unit)
    return matched,matched and nil or state,matched and detail or {rollbackVerified=false}
end
local function sameName(a,b)
    if not a or not b then return false end
    for _,key in ipairs({'name','custom','commander','storage','generation','shown'})do if a[key]~=b[key]then return false end end
    return true
end
function N.set(r,u,name)
    local valid,why=M.validNativeName(name);if not valid then return false,why end
    local ready,previous=r:ready(r.current);if not ready then return false,previous end
    local found=false;for _,actor in ipairs(r.current.units)do if actor==u then found=true;break end end
    if not found or not r.live[u.id]then return false,'Selected unit changed; reopen its editor.'end
    local unit=r.live[u.id];local before;before,why=N.read(r,unit);if not before then return false,why end
    local candidate=M.copy(u);candidate.nativeName=name
    local ok,detail;ok,why,detail=N.apply(r,candidate,unit)
    if not ok then
        local after=N.read(r,unit);local unchanged=sameName(before,after)and not(type(detail)=='table'and detail.rollbackVerified==false)
        r:failure('native_name',why,r.current,r:snapshot(r.current),unchanged and 'verified unchanged'or'unverified')
        if not unchanged then return r:quarantine(r.current,why,nil,{operation='native rename'})end
        return false,why
    end
    u.nativeName=name
    local good,observed,details=r:check(r.current,true,previous)
    if not good then return r:quarantine(r.current,observed,nil,details)end
    r:accept(r.current,observed)
    if r.diag then r.diag:record('native_name',{model_id=u.id,native_id=unit,bytes=#name,scope='native_individual_v1',storage=before.storage,result='native readback verified'})end
    return true
end
return N
