-- Keep every existing per-actor retirement/integrity transaction while yielding
-- large Clear operations to real native frames. No execution guard is changed.
local M=require('sandbox.model')
local Window=require('sandbox.config_window')
local B={}
local function exact(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not exact(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function barrier(ui)
    ui.pending=nil;ui.buttons={};ui.releaseBarrier=true;ui.dragBlocked=true
    ui.lastMouse=0;ui.lastPhysicalButtons=nil;ui.lastCell=nil;ui.dragOrigin=nil;ui.dragVisited=nil;ui.lastWheel=nil
end
function B.wait(ui)
    ui.pending=nil;ui.lastCell=nil;ui.dragOrigin=nil;ui.dragVisited=nil
    ui.api.set('mouseButtons',0);return 0
end
function B.draw(ui)
    local api=ui.api;local w,h=api.get('screenW'),api.get('screenH');local busy=ui.clearBusy
    ui.buttons={};ui.grid=nil;ui.previewInfo=nil
    api.ui.drawRect(0,h-72,w,72,0.08,0.11,0.14,0.98)
    api.ui.drawText(12,h-28,13,'Clearing battlefield: '..busy.removed..' / '..busy.total..' removed',1,0.95,0.75,1)
    api.ui.drawText(12,h-51,10,'Editing is paused. Each removal is verified; native map structures are kept.',0.9,0.9,0.87,1)
end
local function preserve(ui,original)
    local mods=ui.catalog and ui.catalog.mods or{}
    local encoded=M.encode(original,mods)
    local name,path=ui.diag:preserve(original,mods)
    if not name then return false,path or 'original setup backup could not be written'end
    ui.clearRecoveryFile=name;ui.clearRecoveryPath=path
    local read,data=pcall(ui.api.readIni,name)
    if not read then return false,'original setup backup could not be read back'end
    local decoded,why=M.decode(data,ui.catalog,mods)
    if not decoded then return false,'original setup backup could not be decoded: '..tostring(why)end
    if not exact(encoded,M.encode(decoded,mods))then return false,'original setup backup did not match the complete recorded configuration'end
    return true
end
function B.run(ui)
    if ui.clearBusy then return false,'Clear is already running.'end
    local r=ui.runtime;local total=#ui.scenario.units;local cooperative=total>4
    local function refuse(why)
        ui.clearResult={ok=false,removed=0,total=total,reason=why}
        ui.message='Clear not started: '..why;ui:notice(ui.message);return false,why
    end
    if not r:emptyEditorAvailable()then return refuse('A completely empty battlefield requires the updated experimental empty-editor API. Current setup kept.')end
    if cooperative and type(ui.api.drawTestField)~='function'then return refuse('Large-army Clear needs native frame refresh support. Current army kept.')end
    if type(r.ready)=='function'then local healthy,why=r:ready(ui.scenario);if not healthy then return refuse(tostring(why))end end
    ui:setSearchFocus(false);ui.context=nil;ui.moving=nil;ui.copyTemplate=nil
    ui.pending=nil;Window.close(ui)
    ui.clearRecovery=nil;ui.clearRecoveryFile=nil;ui.clearRecoveryPath=nil
    local busy={total=total,removed=0,runtime=r,generation=r.generation,expected=ui.scenario}
    ui.clearBusy=busy;ui.clearResult=nil;barrier(ui)
    local original,complete,reason,started
    local worked,err=xpcall(function()
        -- Freeze the original before a refreshed frame can run any other hook.
        original=M.copy(busy.expected);ui.clearRecovery=original
        if cooperative then ui.api.drawTestField()end
        if cooperative then
            local saved,why=preserve(ui,original)
            if not saved then reason=why;return end
            ui.diag:record('clear_started',{units=total,original_setup_recovery=ui.clearRecoveryFile,mode='one verified retirement per refreshed native frame'})
        end
        started=true
        for _,actor in ipairs(original.units)do
            ui.message='Clearing battlefield: '..busy.removed..' / '..total..' removed'
            if cooperative then ui.api.drawTestField()end
            if ui.runtime~=r or not r.open or r.generation~=busy.generation or ui.scenario~=busy.expected then
                error('clear_field_changed')
            end
            local ok,candidate=r:remove(ui.scenario,actor)
            if not ok then reason=tostring(candidate);return end
            ui.scenario=candidate;busy.expected=candidate;busy.removed=busy.removed+1
        end
        if type(r.ready)=='function'then
            local healthy,why=r:ready(ui.scenario)
            if not healthy then reason=tostring(why);return end
        end
        complete=#ui.scenario.units==0
        if not complete then reason='The final actor list was not empty.'end
    end,tostring)
    ui.clearBusy=nil;barrier(ui)
    if not worked then
        reason='Clear was interrupted; native state requires verification.'
        if ui.runtime==r and type(r.quarantine)=='function'and not r.blocked then
            r:quarantine(ui.scenario,'clear_interrupted',nil,{detail=tostring(err),completed=busy.removed,total=total,original_setup_recovery=ui.clearRecoveryFile or 'not written'})
        end
    end
    ui.clearResult={ok=worked and complete==true,removed=busy.removed,total=total,reason=reason,
        originalRecovery=cooperative and ui.clearRecoveryFile or nil,cooperative=cooperative}
    if not ui.clearResult.ok then
        local prefix=started and('Clear stopped after '..busy.removed..' / '..total..' removals. ')or'Clear not started. '
        ui.message=prefix..tostring(reason or 'No completion was verified.')
        if cooperative and ui.clearRecoveryFile then ui.message=ui.message..' Original setup backup: '..ui.clearRecoveryFile..'.ini.'end
        ui.diag:record('clear_stopped',{removed=busy.removed,total=total,reason=reason,detail=err,
            editing_locked=r.blocked and 1 or 0,original_setup_recovery=cooperative and ui.clearRecoveryFile or 'in-memory original'})
        ui:notice(ui.message);return false,ui.message
    end
    ui.message=M.isSiegeTerrain(ui.scenario.terrain)and 'No army units remain. Native fort structures stay; place either team. A battle needs both teams.'or'Battlefield is empty. Place units on either team; a battle needs at least one unit per team.'
    ui.diag:record('clear',{units=0,team_a=M.count(ui.scenario,1),team_b=M.count(ui.scenario,2),removed=busy.removed,
        original_setup_recovery=cooperative and ui.clearRecoveryFile or 'not needed',cooperative_frames=cooperative and 1 or 0})
    return true
end
return B
