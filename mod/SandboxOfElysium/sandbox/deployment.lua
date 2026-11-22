-- Complete-roster anchor transactions, with a verified legacy fallback owned by
-- Runtime:place only when the newer native operation is absent.
local M=require('sandbox.model')
local D={}
local function describe(s,r,detail,reason)
    local actor
    for _,u in ipairs(s.units or{})do if r.live[u.id]==detail.unit then actor=u;break end end
    local name=actor and M.displayName(actor)or 'a saved unit'
    local where=type(detail.x)=='number'and detail.x>=0 and type(detail.y)=='number'and detail.y>=0 and(' at ('..detail.x..', '..detail.y..')')or''
    if(reason=='native_terrain_rejected'or reason=='native_stand_rejected')and detail.blockerKind=='terrain'then
        return 'Native terrain rules reject the saved footprint'..where..' for '..name..'. Saved setup kept; export diagnostics.'
    elseif reason=='blocked'and detail.blockerKind=='terrain'then
        return 'Exact position'..where..' for '..name..' is blocked by native terrain. Saved setup kept; export diagnostics.'
    elseif reason=='blocked'and detail.blockerKind=='structure'then
        return 'Exact position'..where..' for '..name..' is blocked by a native structure. Saved setup kept; export diagnostics.'
    elseif reason=='target_overlap'or(reason=='blocked'and detail.blockerKind=='target_overlap')then
        return 'Saved unit footprints overlap'..where..' for '..name..'. Saved setup kept; export diagnostics.'
    elseif reason=='off_field'then
        return 'Saved footprint'..where..' for '..name..' is outside the native field. Saved setup kept.'
    end
    return 'Exact native deployment refused: '..tostring(reason or 'unknown reason')..'. Saved setup kept; export diagnostics.'
end
local function record(r,detail,result)
    local fields={result=result,scope='complete actor roster; anchor transaction only'}
    for _,key in ipairs({'version','phase','rollbackVerified','byteRollbackVerified','rollbackResult','sourceHealthy','finalHealthy','initialReceiptUsed','initialSession','anchorsRestored','wroteAnchors','units','unit','x','y','object','objectScope','blockerKind','objectGeneration','objectMonster','objectOwner','objectSource','passabilityMode','nativeStand0','nativeStand4'})do
        local value=detail[key];fields[key]=type(value)=='boolean'and(value and 1 or 0)or value
    end
    r.lastDeployment=M.copy(fields);r.lastConfig=r.lastConfig or{}
    for key in pairs(r.lastConfig)do if key:sub(1,11)=='deployment_'then r.lastConfig[key]=nil end end
    for key,value in pairs(fields)do r.lastConfig['deployment_'..key]=value end
    if r.diag then r.diag:record('exact_deployment',fields)end
end
function D.place(r,s,observed)
    local available=type(r.api.setTestFieldDeployment)=='function'
    local caps
    if type(r.api.testFieldEditorCapabilities)=='function'then
        local ok,value=pcall(r.api.testFieldEditorCapabilities);if ok and type(value)=='table'then caps=value end
    end
    local version=caps and caps.exactDeploymentVersion
    local provisional=observed.provisionalInitial==true
    if provisional and(not available or version~=1 or caps.initialDeploymentVersion~=1 or type(observed.initialReceipt)~='table')then
        return true,false,'Repairing native initial packing requires matching initial-deployment API version 1. Saved setup kept.'
    end
    if not available and(version==nil or version==0 or version==false)then return false end
    if not available or version~=1 then return true,false,'Exact deployment requires matching native API version 1. Current field kept.'end
    local rows,source={},M.copy(s)
    for i,u in ipairs(s.units or{})do
        local id=r.live[u.id];local native=observed.rows[id]
        if type(native)~='table'or #(native.anchors or{})~=1 then
            local _,why=r:quarantine(s,'deployment_source_unverified',nil,{model_id=u.id,native_id=id})
            return true,false,why
        end
        if not u.scenery then rows[#rows+1]={unit=id,x=u.x,y=u.y,generation=native.generation} end
        source.units[i].x=native.anchors[1].x;source.units[i].y=native.anchors[1].y
    end
    local options=provisional and{initialReceipt=observed.initialReceipt.token}or nil
    local called,ok,reason,detail=pcall(r.api.setTestFieldDeployment,rows,options)
    if type(detail)~='table'then detail={}end
    local contract=called and detail.version==1 and detail.rollbackVerified==true
    if not called or ok~=true then
        local unchanged,why=false,'native result not verified'
        -- Restoring an overlapping initial source byte-for-byte is not a
        -- healthy rollback. It must never be accepted as ready/unchanged.
        if contract and not provisional then unchanged,why=r:check(source,true,observed,false)end
        record(r,detail,called and tostring(reason or 'refused')or'call failed')
        if not unchanged then
            local _,message=r:quarantine(s,'exact_deployment_rollback_unverified',nil,{native_reason=called and reason or 'call failed',verification_detail=tostring(why),native_rollback_verified=detail.rollbackVerified==true and 1 or 0})
            return true,false,called and(describe(s,r,detail,reason)..' '..message)or message
        end
        return true,false,describe(s,r,detail,reason)
    end
    local valid,why=false,'native success contract is incomplete'
    local initialContract=not provisional or(detail.initialReceiptUsed==true and detail.initialSession==observed.initialReceipt.session and detail.finalHealthy==true)
    if contract and initialContract and detail.phase=='committed'and detail.units==#rows then
        local final;valid,final=r:check(s,true,observed,false);why=valid and nil or final
        if valid then
            if observed.native.session~=nil and final.native.session~=observed.native.session then valid=false;why='native session changed during deployment'end
            for _,entry in ipairs(rows)do
                if not final.rows[entry.unit]or final.rows[entry.unit].generation~=entry.generation then valid=false;why='native generation changed during deployment';break end
            end
        end
    end
    record(r,detail,valid and 'committed; exact readback verified'or'success not verified')
    if not valid then
        local _,message=r:quarantine(s,'exact_deployment_readback_unverified',nil,{verification_detail=tostring(why)})
        return true,false,message
    end
    return true,true
end
return D
