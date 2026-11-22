-- Contract tests only: native lifecycle/combat must also run in the real game.
local cache={}
function require(name)
    if not cache[name] then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))() end
    return cache[name]
end
local M=require('sandbox.model');local R=require('sandbox.runtime');local I=require('sandbox.integrity')
local F=require('sandbox.final_view');local U=require('sandbox.ui');local D=require('sandbox.diagnostics')
local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local catalog={byId={[13]={id=13,name='Spearman'}},terrainById={},mods={}}
for id,name in pairs(M.terrainNames)do catalog.terrainById[id]={id=id,name=name}end
test('empty and either one-sided scenario roundtrip without a dummy record',function()
    for _,team in ipairs({0,1,2})do
        local s=M.new();if team>0 then M.add(s,13,'Spearman',team,4,4)end
        local loaded,why=M.decode(M.encode(s,{}),catalog,{});assert(loaded,why)
        assert(#loaded.units==(team==0 and 0 or 1) and M.count(loaded,team==1 and 2 or 1)==0)
    end
end)
test('terrain identity is exact and capability does not replace identity',function()
    for _,id in ipairs({0,2,12,107,117})do
        local s=M.new();s.terrain=id;assert(M.decode(M.encode(s,{}),catalog,{}))
    end
    local c=M.copy(catalog);c.terrainById[117].name='Changed Desert';local s=M.new();s.terrain=117
    assert(not M.decode(M.encode(s,{}),c,{}));s.terrain=118;assert(not M.decode(M.encode(s,{}),catalog,{}))
end)
test('legacy empty refusal occurs before native close or rebuild',function()
    local calls=0;local r=R.new({},catalog);r._build=function()calls=calls+1 end
    local ok,why=r:build(M.new());assert(not ok and calls==0 and why:find('Empty teams require',1,true))
end)
local function buildFixture(team)
    local s=M.new();if team>0 then M.add(s,13,'Spearman',team,4,4)end
    local spec,closed
    local api={testFieldEditorCapabilities=function()return {emptyEditor=1}end,
        testFieldTerrains=function()return {0}end,closeTestField=function()closed=(closed or 0)+1;return true end,
        openTestField=function(value)spec=value;return true,{commander=-1,friends=team==1 and {91} or {},enemies=team==2 and {92} or {}}end,
        get=function(key)return key=='squareTerrain' and 0 or key=='battleWidth' and 32 or 0 end,set=function()end}
    local r=R.new(api,catalog);r.place=function()return true end;r.configure=function(self,u,id)assert(id==(team==1 and 91 or 92));return true end;r.cacheObjects=function()end
    return r,s,function()return spec,closed end
end
test('empty editor passes no commander and maps every actor through ordinary lists',function()
    for _,team in ipairs({0,1,2})do
        local r,s,read=buildFixture(team);assert(r:_build(s));local spec=read()
        assert(spec.emptyEditor==true and spec.commander==nil and spec.spell==nil and r.primaryId==nil)
        assert(#spec.friends==M.count(s,1) and #spec.enemies==M.count(s,2))
        if team>0 then assert(r.live[s.units[1].id]==(team==1 and 91 or 92))end
    end
end)
test('unexpected hidden commander from empty mode closes and refuses the field',function()
    local r,s,read=buildFixture(0);r.api.openTestField=function()return true,{commander=99,friends={},enemies={}}end
    local ok,why=r:_build(s);assert(not ok and not r.open and why:find('unexpected commander'));local _,closed=read();assert(closed==1)
end)
test('empty integrity still refuses a hidden living native actor',function()
    local state={complete=true,units={},issues={}};local r=R.new({testFieldState=function()return state end},catalog)
    assert(I.inspect(r,M.new(),true));state.units={{unit=7,alive=true,hp=1}}
    local ok,why=I.inspect(r,M.new(),true);assert(not ok and why=='orphaned_native_unit')
end)
local function uiFixture()
    local api={wrap=function()return {}end,observe=function()return {}end,readIni=function()end,get=function(key)
        if key=='screenW'then return 800 elseif key=='screenH'then return 600 elseif key=='uiPointerX'then return 100 elseif key=='uiPointerY'then return 210 else return 0 end
    end,set=function()end}
    local u=U.new(api);u.phase='prepare';u.runtime={open=true};u.scenario=M.new();return u
end
test('battle start with either empty team changes no setup or snapshot and never calls native fight',function()
    for _,team in ipairs({0,1,2})do
        local u=uiFixture();if team>0 then M.add(u.scenario,13,'Spearman',team,4,4)end
        local calls=0;u.runtime.ready=function()calls=calls+1;error('must not reach native state')end;u.api.fightTestField=function()error('must not fight')end
        local original=u.scenario;assert(not u:fight() and u.scenario==original and u.snapshot==nil and u.phase=='prepare' and calls==0 and u.noticeText:find('each team'))
    end
end)
test('Clear removes the former primary too and produces a verified empty scenario',function()
    local u=uiFixture();M.add(u.scenario,13,'Spearman',1,4,4);M.add(u.scenario,13,'Spearman',2,18,4)
    local removed=0;u.runtime.primaryId=1;u.runtime.emptyEditorAvailable=function()return true end
    u.runtime.remove=function(_,s,unit)local candidate=M.copy(s);M.remove(candidate,unit.id);removed=removed+1;return true,candidate end
    assert(u:dispatch('clear') and #u.scenario.units==0 and removed==2)
end)
local function snapshot()
    local cells={};for x=4,6 do for y=4,6 do cells[#cells+1]={x=x,y=y}end end
    return {source='post_aftermath_before_upkeep',complete=true,sceneComplete=false,width=32,height=20,issues={},grid={},units={
        {unit=17,kind='actor',alive=true,hp=50,monster=141,owner=24,anchorCount=1,anchors={{x=4,y=4}},width=3,height=3,occupied=cells,createdDuringFight=true,ownerChanged=true},
        {unit=18,kind='actor',alive=true,hp=1,anchorCount=0,anchors={},occupied={}},
        {unit=19,kind='actor',alive=false,hp=0,anchorCount=0},
        {unit=20,kind='terrain',alive=true,hp=10,monster=1388,owner=31,anchorCount=1,anchors={{x=2,y=2}},width=1,height=1,occupied={}}}}
end
test('final snapshot uses full native footprint and actual owner, includes summons and separate terrain anchors',function()
    local p=F.prepare(snapshot());assert(p.complete and #p.rows==2 and #p.actors==1 and p.teamA==0 and p.teamB==1 and p.offField==1 and p.dead==1)
    assert(F.at(p,6,6).native==17 and not F.at(p,2,2) and not F.at(p,7,6))
end)
test('proven structures render separately and never inflate army, dead or off-field counters',function()
    local s=snapshot();s.classificationVersion=1
    local structure={unit=23,kind='structure',creationSource='native_gate_replacement',provenanceVerified=true,alive=true,hp=25,monster=1436,owner=24,anchorCount=1,anchors={{x=12,y=9}},width=1,height=2,occupied={{x=12,y=9},{x=12,y=10}}}
    s.units[#s.units+1]=structure;local plan=F.prepare(s);assert(plan.complete and plan.byUnit[23] and #plan.actors==1 and plan.teamB==1 and not F.at(plan,12,9))
    structure.alive=false;structure.hp=0;structure.anchorCount=0;assert(F.prepare(s).dead==1)
    structure.alive=true;structure.hp=25;assert(F.prepare(s).offField==1)
    structure.anchorCount=1;structure.provenanceVerified=false;plan=F.prepare(s);assert(not plan.complete and plan.invalid==1 and not plan.byUnit[23])
end)

test('missing snapshot cells are partial and never displayed at guessed setup positions',function()
    local s=snapshot();table.remove(s.units[1].occupied);local p=F.prepare(s)
    assert(not p.complete and #p.actors==0 and not F.at(p,4,4))
    assert(F.prepare(nil).source=='unavailable')
end)
test('post-battle right click offers only snapshot Inspect without scheduling placement',function()
    local u=uiFixture();u.phase='after';u.finalPlan=F.prepare(snapshot());u.grid={x=10,y=120,cell=20,width=32};u.buttons={}
    assert(u:input(2));assert(u.pending==nil and u.finalContext.entry.native==17 and not u.context)
end)
test('diagnostics distinguish post-cleanup live state from timed snapshot and bounded export',function()
    local u=uiFixture();local final=snapshot();for i=5,70 do final.units[i]=M.copy(final.units[1]);final.units[i].unit=100+i end
    local d=D.new(u.api);local snap=d:snapshot(M.new(),{open=true,live={},phase='after',finalState=final})
    assert(snap.summary.observation_phase=='after' and snap.final.summary.units_total==70 and #snap.final.units==48 and snap.final.summary.scene_complete==false)
end)
test('bounded final exports preserve late-created actors before dense terrain without changing capture',function()
    local s={units={}};for i=1,90 do s.units[i]={unit=i,kind='terrain'}end
    s.units[91]={unit=91,kind='actor',createdDuringFight=true}
    local rows=F.exportUnits(s,48);assert(#rows==48 and rows[1].unit==91 and s.units[1].unit==1 and #s.units==91)
end)
print(count..' offline empty-editor/final-view/terrain contracts passed; no native combat simulated')
