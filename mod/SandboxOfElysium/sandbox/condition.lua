local C={}
local fields={'version','monster','width','height','maxHp','hp','xp','kills','injuryFlags'}
function C.available(api)
    return type(api.testFieldActorState)=='function' and type(api.setTestFieldActorState)=='function'
end
function C.read(r,unit)
    if not C.available(r.api)then return nil,'Health/injury restoration requires the separate release-next experimental API.'end
    local state,why=r.api.testFieldActorState(unit)
    if type(state)~='table' or state.complete~=true or state.fullState~=false or state.version~=1 or state.unit~=unit then
        return nil,why or 'Native supported actor-state readback is incomplete.'
    end
    for _,key in ipairs(fields)do if type(state[key])~='number' or state[key]%1~=0 then return nil,'Invalid native actor-state field: '..key end end
    if state.hp<1 or state.hp>32767 or state.xp<0 or state.xp>32767 or state.kills<0 or state.kills>32767 or
        state.injuryFlags<0 or state.injuryFlags&(~0x7ff00000)~=0 or state.maxHp<1 or state.width<1 or state.width>3 or state.height<1 or state.height>3 then
        return nil,'Native actor state exceeds the supported bounded restoration contract.'
    end
    return state
end
function C.save(state)
    local saved={};for _,key in ipairs(fields)do saved[key]=state[key]end;return saved
end
function C.capture(r,u,unit)
    if not C.available(r.api)then return true end
    local state,why=C.read(r,unit);if not state then return false,why end
    u.condition=C.save(state);return true
end
function C.matches(r,u,unit)
    if not u.condition then return true end
    local state,why=C.read(r,unit);if not state then return false,why end
    for _,key in ipairs(fields)do if state[key]~=u.condition[key]then return false,'Supported actor state differs: '..key end end
    return true,state
end
function C.restore(r,u,unit,saved)
    if not C.available(r.api)then return false,'Saved health/injury state needs the release-next experimental API; setup kept.'end
    local ok,why,detail=r.api.setTestFieldActorState(unit,saved)
    u.condition=saved
    if not ok then return false,'Supported actor-state restoration refused: '..tostring(why),detail end
    local matched,state=C.matches(r,u,unit)
    if not matched then return false,state,{rollbackVerified=false}end
    return true
end
return C
