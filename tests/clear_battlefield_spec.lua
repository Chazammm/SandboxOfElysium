-- Cooperative-clear coordination and preservation contracts; no native frame
-- timing or retirement is simulated by this fixture.
local cache={}
function require(name)
    if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end
    return cache[name]
end
local M=require('sandbox.model');local U=require('sandbox.ui');local Clear=require('sandbox.clear_battlefield')
local passed=0
local function test(name,fn)fn();passed=passed+1;print('PASS '..name)end
local function same(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function fixture(n)
    local st={frame=0,removed=0,lastRemovalFrame=-1,ready=0,quarantined=0,drawText={},hooks={},files={}}
    local api={get=function(key)if key=='screenW'then return 800 elseif key=='screenH'then return 600 end;return 0 end,
        set=function(key,value)st[key]=value end,readIni=function(name)return M.copy(st.files[name])end,
        wrap=function(site,fn)st.hooks[site]=fn;return true end,observe=function()return true end,
        ui={drawRect=function()end,drawText=function(x,y,size,text)st.drawText[#st.drawText+1]=text end}}
    local ui=U.new(api);ui.phase='prepare';ui.scenario=M.new();ui.selected=13
    ui.catalog={byId={[13]={id=13,name='Spearman'}},mods={},terrainById={},spellKeys={['2:Second']=2,['1:First']=1},byItemId={[100]={id=100,name='Recorded item'}},itemNames={['Recorded item']=100}}
    for id,name in pairs(M.terrainNames)do ui.catalog.terrainById[id]={id=id,name=name}end
    for i=1,n do
        local u=M.add(ui.scenario,13,'Spearman',i%2+1,math.floor((i-1)/20)+1,(i-1)%20)
        u.nativeName='Actor '..i;u.label='Display '..i;u.baseline={known={'2:Second','1:First'}};u.spells={'1:First','2:Second'}
        u.items={'Recorded item'};u.equipment={{position=0,id=100,name='Recorded item'}};u.schools={{path=2,name='Recorded school',base=2}}
        u.condition={version=1,monster=13,width=1,height=1,maxHp=20,hp=18,xp=7,kills=3,injuryFlags=0}
    end
    local r={open=true,current=ui.scenario,generation=9,verified={structures={[900]='verified structure'}}}
    r.emptyEditorAvailable=function()return true end
    r.ready=function(self,scene)st.ready=st.ready+1;return not self.blocked,self.blocked and 'locked'or{}end
    r.build=function()error('Clear must never rebuild or change native scenery')end
    r.quarantine=function(self,scene,why)self.blocked=true;st.quarantined=st.quarantined+1;return false,why end
    r.remove=function(self,scene,u)
        if n>4 then assert(st.frame>st.lastRemovalFrame,'No refreshed frame between retirement transactions')end
        st.lastRemovalFrame=st.frame
        local candidate=M.copy(scene);M.remove(candidate,u.id);st.removed=st.removed+1;self.current=candidate;return true,candidate
    end
    ui.runtime=r;ui.notice=function(self,text)self.noticeText=text end
    ui.diag.preserve=function(self,scene)
        if st.backupFail then return nil,'injected backup refusal'end
        st.files['clear-original']=M.encode(scene,ui.catalog.mods)
        if st.backupMismatch then st.files['clear-original'].unit1.native_name_hex='58'end
        return 'clear-original','test/clear-original.ini'
    end
    api.drawTestField=function()
        st.frame=st.frame+1
        assert(ui.clearBusy and not ui.pending)
        ui:draw()
        if st.frameCallback then st.frameCallback(ui,st)end
        assert(st.hooks.BATTLE_WAIT(function()return 18 end)==0,'Busy WAIT leaked a native action')
    end
    return ui,r,st
end

test('large Clear retains every retirement check and polls native frames between actors',function()
    local ui,r,st=fixture(12);local original=M.encode(ui.scenario,ui.catalog.mods);local structures=M.copy(r.verified.structures)
    assert(Clear.run(ui)and #ui.scenario.units==0 and st.removed==12 and st.frame>=13 and not ui.clearBusy)
    assert(ui.clearResult.ok and ui.clearResult.removed==12 and ui.releaseBarrier and ui.dragBlocked)
    assert(same(structures,r.verified.structures)and same(original,M.encode(M.decode(st.files['clear-original'],ui.catalog,{}),{})))
    assert(st.ready>=2 and #st.drawText>=2)
end)
test('the backup retains names teams items ordered spells schools and supported condition state',function()
    local ui,r,st=fixture(12);local original=M.copy(ui.scenario);assert(Clear.run(ui))
    local saved=assert(M.decode(st.files['clear-original'],ui.catalog,{}))
    assert(same(M.encode(original,{}),M.encode(saved,{}))and same(original,ui.clearRecovery))
end)
test('nested actions placement input fight and stale queued clicks are suppressed while busy',function()
    local ui,r,st=fixture(12);local originalSelected=ui.selected
    st.frameCallback=function(self)
        self.pending='fight';assert(self:dispatch('fight'));assert(not self.pending and not self:fight())
        assert(self:dispatch('team2')and self.team==1);assert(self:dispatch('clear'))
        assert(self:input(3)and not self.pending and self.selected==originalSelected)
    end
    assert(Clear.run(ui)and st.removed==12 and ui.phase=='prepare'and ui.lastWheel==nil)
    assert(ui:input(3)and not ui.pending and ui.releaseBarrier)
    assert(ui:input(0)and not ui.pending and not ui.releaseBarrier)
end)
test('a refused removal reports the completed count and preserves remaining and original setups',function()
    local ui,r,st=fixture(12);local original=M.encode(ui.scenario,{})local remove=r.remove
    r.remove=function(self,scene,u)if st.removed==3 then return false,'declared unchanged native refusal'end;return remove(self,scene,u)end
    assert(not Clear.run(ui)and st.removed==3 and #ui.scenario.units==9 and not r.blocked)
    assert(not ui.clearResult.ok and ui.clearResult.removed==3 and ui.message:find('3 / 12',1,true)and not ui.clearBusy)
    assert(same(original,M.encode(M.decode(st.files['clear-original'],ui.catalog,{}),{})))
end)
test('an unexpected removal exception quarantines the partial result and retains its original backup',function()
    local ui,r,st=fixture(12);local remove=r.remove
    r.remove=function(self,scene,u)if st.removed==3 then error('injected transaction exception')end;return remove(self,scene,u)end
    assert(not Clear.run(ui)and r.blocked and st.quarantined==1 and st.removed==3 and #ui.scenario.units==9)
    assert(not ui.clearBusy and ui.clearResult.originalRecovery=='clear-original'and ui.releaseBarrier)
end)
test('missing refresh support or an unverified backup refuses before deleting any actor',function()
    for _,problem in ipairs({'refresh','write','readback'})do
        local ui,r,st=fixture(12);local original=ui.scenario
        if problem=='refresh'then ui.api.drawTestField=nil elseif problem=='write'then st.backupFail=true else st.backupMismatch=true end
        assert(not Clear.run(ui)and st.removed==0 and #ui.scenario.units==12 and ui.scenario==original and not ui.clearBusy)
        assert(not ui.clearResult.ok and not r.blocked)
    end
end)
test('a generation change during refresh stops before deleting from the replacement field',function()
    local ui,r,st=fixture(12)
    st.frameCallback=function()r.generation=r.generation+1 end
    assert(not Clear.run(ui)and st.removed==0 and r.blocked and st.quarantined==1 and #ui.scenario.units==12)
end)
test('an unverified final empty state is not reported as a successful Clear',function()
    local ui,r,st=fixture(12);local ready=r.ready
    r.ready=function(self,scene)if #scene.units==0 then self.blocked=true;return false,'hidden native actor detected'end;return ready(self,scene)end
    assert(not Clear.run(ui)and st.removed==12 and #ui.scenario.units==0 and r.blocked and not ui.clearResult.ok)
    assert(ui.message:find('12 / 12',1,true)and ui.noticeText:find('hidden native actor',1,true))
end)
test('ordinary small and empty Clears stay immediate and retain the existing siege message',function()
    for _,n in ipairs({0,2})do
        local ui,r,st=fixture(n);ui.api.drawTestField=nil;ui.scenario.terrain=1
        assert(ui:dispatch('clear')and #ui.scenario.units==0 and st.removed==n and st.frame==0)
        assert(ui.clearResult.ok and ui.message:find('Native fort structures stay',1,true))
    end
end)
test('a stale backup filename cannot be attributed to a later refused Clear',function()
    local ui,r,st=fixture(12);ui.clearRecoveryFile='old-unrelated-backup';st.backupFail=true
    assert(not Clear.run(ui)and st.removed==0 and not ui.clearRecoveryFile and not ui.message:find('old-unrelated',1,true))
end)
print(passed..' offline cooperative Clear preservation/input contracts passed; native frame-budget acceptance requires the real game')
