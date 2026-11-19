local cache={}
function require(name)
    if not cache[name] then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))() end
    return cache[name]
end

local M=require('sandbox.model')
local Runtime=require('sandbox.runtime')
local Final=require('sandbox.final_view')
local Objects=require('sandbox.battlefield_objects')
local Report=require('sandbox.report')
local cases=0
local function test(name,fn)
    fn();cases=cases+1;print('PASS '..name)
end

local function nativeRow(unit,kind,source,owner,x)
    return {unit=unit,monster=13,kind=kind,creationSource=source,owner=owner,provenanceVerified=true,
        hp=5,alive=true,anchorCount=1,width=1,height=1,anchors={{x=x,y=4}},occupied={{x=x,y=4}}}
end

test('identical monster types have independent roster and environment roles',function()
    local scenery=nativeRow(0,'terrain','native_map_loader',31,2)
    local gate=nativeRow(1,'structure','native_gate_replacement',24,3)
    local actor=nativeRow(2,'actor','owned_actor_creation',24,4)
    assert(Objects.role(scenery)=='scenery' and Objects.role(gate)=='structure' and Objects.role(actor)==nil)
    assert(Objects.label('scenery',31):find('Neutral',1,true))
    assert(Objects.label('structure',24):find('defender side',1,true))
    scenery.owner=24;assert(Objects.role(scenery)==nil)
    gate.provenanceVerified=false;assert(Objects.role(gate)==nil)
    gate.provenanceVerified=true;gate.creationSource='owned_actor_creation';assert(Objects.role(gate)==nil)
end)

test('preparation uses same-session scenery and verified structures only',function()
    local scenery=nativeRow(0,'terrain','native_terrain_placement',31,2)
    local gate=nativeRow(1,'structure','native_gate_replacement',24,3)
    local lifecycle={open=true,complete=true,session=7,created={scenery,gate}}
    local api={
        battleObjectAt=function(x,y) return x==2 and y==4 and 0 or -1 end,
        testFieldLifecycle=function()return lifecycle end,
        battleUnitAt=function(x,y) return x==3 and y==4 and 1 or -1 end,
    }
    local r=Runtime.new(api,{})
    r.width=8
    r:cacheObjects()
    r.verified={native={classificationVersion=1,session=7},structures={[1]='verified'},rows={[1]=gate}}
    local object,role=r:fieldObjectAt(2,4);assert(object==scenery and role=='scenery')
    object,role=r:fieldObjectAt(3,4);assert(object==gate and role=='structure')
    r.verified.native.session=8;assert(r:fieldObjectAt(2,4)==nil)
    r.verified.structures={};assert(r:fieldObjectAt(3,4)==nil)
end)

test('final overlay retains native owner while keeping structures out of both teams',function()
    local scenery=nativeRow(0,'terrain','native_map_loader',31,2)
    local gate=nativeRow(1,'structure','native_gate_replacement',24,3)
    local actor=nativeRow(2,'actor','owned_actor_creation',24,4)
    local plan=Final.prepare({source='post_aftermath_before_upkeep',complete=true,classificationVersion=1,width=8,height=20,
        units={scenery,gate,actor},grid={{x=2,y=4,object=0},{x=3,y=4,object=-1},{x=4,y=4,object=-1}}})
    assert(plan.complete and plan.teamA==0 and plan.teamB==1)
    assert(plan.objects['2:4'].row==scenery and plan.objects['3:4'].row==gate)
    assert(plan.byUnit[1].team==0 and gate.owner==24 and Final.at(plan,3,4)==nil)
    assert(Final.at(plan,4,4).row==actor)
end)

test('a recycled unit handle cannot be reported as the original army survivor',function()
    local api={observe=function()return true end}
    api.get=function(key,id)
        if key=='ticksMs' then return 100 end
        if key=='battleWinner' then return 24 end
        if key=='battleRound' then return 4 end
        if key=='terrainName' then return 'Plain' end
        if key=='unitKills' then return 0 end
        error('Report read a recycled or unavailable native handle: '..key..' '..tostring(id))
    end
    api.testFieldFinalState=function()
        return {complete=true,units={
            {unit=5,kind='actor',generation=99,identityMatches=true,hp=25,owner=24},
            {unit=6,kind='actor',generation=31,identityMatches=false,readable=true,hp=0,owner=24},
            {unit=7,kind='structure',generation=32,identityMatches=true,hp=5,owner=24},
        }}
    end
    local s=M.new()
    local a=M.add(s,13,'Spearman',1,1,1)
    local b=M.add(s,13,'Spearman',2,5,1)
    local r={live={[a.id]=5,[b.id]=6},verified={rows={[5]={generation=30},[6]={generation=31}}}}
    local report=Report.new(api)
    report:start(s,r)
    local outcome=report:finish(s,r)
    assert(outcome.teamA.start==1 and outcome.teamA.unverified==1 and outcome.teamA.survivors==0 and outcome.teamA.losses==0)
    assert(outcome.teamB.start==1 and outcome.teamB.losses==1 and outcome.teamB.unverified==0)
    assert(outcome['unit'..a.id].alive=='unavailable' and outcome['unit'..a.id].captured_x=='unavailable')
    assert(outcome['unit'..b.id].outcome_scope=='original generation at final snapshot')
    assert(outcome.summary.winner==24)
end)
print(cases..' offline battlefield object and report checks passed')
