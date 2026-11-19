-- Focused failure-boundary contracts; native setup/check are explicitly stubbed.
local cache={}
function require(name)
    if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end
    return cache[name]
end
local M=require('sandbox.model');local R=require('sandbox.runtime');local U=require('sandbox.ui')
local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function fixture()
    local catalog={byId={[13]={id=13,name='Spearman'}},terrainById={[0]={name='Plain'}},testFieldTerrains={[0]=true},mods={}}
    local s=M.new();local actor=M.add(s,13,'Spearman',1,5,4);M.add(s,13,'Spearman',2,18,4)
    local api={get=function()return 0 end,testFieldState=function()return{}end,
        testFieldTerrains=function()return{0}end,testFieldEditorCapabilities=function()return{emptyEditor=1}end}
    local r=R.new(api,catalog);r.open=true;r.current=s;r.lastKnownGood=M.copy(s);r.live={[1]=101,[2]=102}
    r.snapshot=function()return{}end;r.failure=function(self,_,_,_,_,rollback)self.recordedRollback=rollback end
    return r,s,actor,api,catalog
end
test('busy-square refusal latches a readable reason and later retries make no native call',function()
    local r,s,_,api=fixture();r.open=false;r.current=nil;r.lastKnownGood=nil
    local opens,closes=0,0;r.close=function()closes=closes+1;return true end
    api.openTestField=function()opens=opens+1;return false,'temporary_square_busy'end
    local ok,why=r:build(s);assert(not ok and why:find('scenario is kept')and opens==1)
    local called,accepted,message=pcall(r.build,r,s)
    assert(called and not accepted and message:find('temporary_square_busy')and opens==1 and closes==1)
    assert(#s.units==2 and s.units[1].x==5)
end)
test('legacy boolean cleanup latch refuses without a Lua error or engine call',function()
    local r,s=fixture();r.cleanupFailed=true;r._build=function()error('must not rebuild')end
    local called,ok,why=pcall(r.build,r,s);assert(called and not ok and why:find('cleanup')and #s.units==2)
end)
test('a busy first rebuild does not retry native open during rollback and keeps its recovery setup',function()
    local r,s,_,api=fixture();local opens,closes=0,0
    r.close=function(self)closes=closes+1;self.current=nil;self.open=false;return true end
    r.quarantine=function(self)self.blocked=true end
    api.closeTestField=function()error('the injected runtime close owns cleanup')end
    api.openTestField=function()opens=opens+1;return false,'temporary_square_busy'end
    local ok,why=r:build(M.copy(s));assert(not ok and opens==1 and closes==1 and r.blocked and r.recordedRollback=='failed')
    assert(r.recovery.units[1].x==5 and #r.recovery.units==2 and not why:find('Previous army restored'))
end)
test('an advertised capability list is authoritative even for Plain',function()
    for _,reply in ipairs({false,{},function()return{}end,function()return{2}end,function()return'incompatible'end,function()error('unavailable')end})do
        local r,s,_,api=fixture();api.testFieldTerrains=reply
        r._build=function()error('must not touch current field')end
        local ok,why=r:build(s);assert(not ok and type(why)=='string'and r.open and r.current==s)
        r._build=nil;r.close=function()error('must not close')end
        ok,why=r:_build(s);assert(not ok and type(why)=='string')
    end
end)
test('failed Load preserves UI scenario and actor identity after verified native rollback',function()
    local r,s,actor,api,catalog=fixture();local candidate=M.copy(s);candidate.units[1].x=8
    api.listIni=function()return{'candidate.ini'}end;api.readIni=function()return M.encode(candidate,{})end
    local builds=0;r._build=function()builds=builds+1;return builds~=1,'injected exact-placement refusal'end
    r.check=function()return true,{}end
    local u=setmetatable({scenario=s,runtime=r,api=api,catalog=catalog},U)
    u.menu=function()return 1 end;u.notice=function()end;u:load()
    assert(builds==2 and r.recordedRollback=='restored'and r.current==u.scenario and s.units[1]==actor and actor.x==5)
    assert(r:setLabel(actor,'Still editable'))
end)
test('rollback restores old values and removes pending fields without aliasing the checkpoint',function()
    local r,s,actor,api=fixture();api.testFieldTerrains=function()return{0,2}end
    api.testFieldEnvironmentInfo=function()return{minimumWidthVersion=1}end
    s.terrain=2;s.minimumWidth=70;actor.label='Pending label'
    local builds=0;r._build=function()builds=builds+1;return builds~=1,'injected refusal'end
    r.check=function(self,value)assert(value.terrain==0 and value.minimumWidth==nil and value.units[1].nativeName==nil);return true,{}end
    assert(not r:build(s));assert(r.current==s and s.units[1]==actor and actor.label==nil and builds==2)
    actor.label='Later';assert(r.lastKnownGood.units[1].label==nil)
end)
test('failed first open discards partial native configuration captures while retaining the requested setup',function()
    local r,s,actor=fixture();r.open=false;r.current=nil;r.lastKnownGood=nil
    r._build=function(self,value)value.units[1].baseline={known={'generated'},memorized={'generated'}};value.units[1].condition={hp=7};return false,'later actor configuration refused'end
    local ok,why=r:build(s)
    assert(not ok and why:find('scenario is kept')and s.units[1]==actor and actor.baseline==nil and actor.condition==nil and actor.x==5 and #s.units==2)
end)
test('a failed second verification is quarantined and never called restored',function()
    local r,s=fixture();local candidate=M.copy(s);candidate.units[1].x=8
    local builds,checks=0,0;r._build=function()builds=builds+1;return builds~=1,'injected refusal'end
    r.check=function()checks=checks+1;return checks==1,checks==1 and{}or'identity verification failed'end
    local quarantined=false;r.quarantine=function(self,preserved)quarantined=true;self.blocked=true;assert(preserved.units[1].x==5)end
    local ok,why=r:build(candidate);assert(not ok and not why:find('Previous army restored')and quarantined and r.recordedRollback=='failed')
end)
print(count..' offline runtime audit contracts passed; injected native boundaries, no game simulated')
