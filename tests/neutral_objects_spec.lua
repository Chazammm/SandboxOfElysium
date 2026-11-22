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
local Catalog=require('sandbox.catalog')
local Integrity=require('sandbox.integrity')
local UI=require('sandbox.ui')
local cases=0
local function test(name,fn)
    fn();cases=cases+1;print('PASS '..name)
end
test('neutral placement requires an exact building identity and native scenery capability',function()
    assert(Objects.neutralBuilding({id=1404,name='Stone Wall',scenery=true}))
    assert(Objects.neutralBuilding({id=1448,name='Palisade Wall',scenery=true}))
    assert(not Objects.neutralBuilding({id=1404,name='Stone Wall'}))
    assert(not Objects.neutralBuilding({id=1404,name='A Different Wall',scenery=true}))
    assert(not Objects.neutralBuilding({id=1404,name='Stone Wall',scenery=true,definitionMod='Example'}))
    assert(not Objects.neutralBuilding({id=9000,name='Stone Wall',scenery=true}))
    assert(not Objects.neutralBuilding({id=1634,name='Cabbage',scenery=true}))
    assert(not Objects.neutralBuilding({id=1436,name='Wooden Gate',observedObjectRoles={structure=true}}))
end)

test('neutral groups keep search local and preserve the army filter',function()
    local ui=UI.new({observe=function()end,wrap=function()end})
    local wall={id=1404,name='Stone Wall',scenery=true,categories={}}
    local stair={id=1511,name='Stone Stairs',scenery=true,sceneryStandable=true,categories={}}
    local plant={id=1634,name='Cabbage',scenery=true,categories={animal=true}}
    local unverified={id=1462,name='Wooden Stairs',scenery=true,categories={}}
    ui.runtime={open=true}
    ui.catalog={monsters={wall,stair,plant,unverified},byId={[1404]=wall,[1511]=stair}}
    ui.category=4
    ui.team=3;ui:refresh()
    assert(#ui.filtered==2 and ui.category==4)
    ui.search='Stone';ui:dispatch('filter');assert(#ui.filtered==1 and ui.filtered[1]==wall)
    ui:dispatch('filter');assert(#ui.filtered==0 and not ui.neutralGroupAvailable)
    ui:dispatch('filter');assert(#ui.filtered==1 and ui.filtered[1]==stair)
    ui.search='Wall';ui:refresh();assert(#ui.filtered==0 and ui.neutralGroupAvailable)
    ui:dispatch('filter');assert(#ui.filtered==0 and not ui.neutralGroupAvailable)
    ui.search='';ui.team=2;ui:refresh()
    assert(#ui.filtered==1 and ui.filtered[1]==plant and ui.category==4)
end)
test('neutral searches exact IDs independently of identical names and sprite variants',function()
    local ui=UI.new({observe=function()end,wrap=function()end})
    ui.runtime={open=true}
    local a={id=1396,name='Stone Wall',scenery=true,sceneryRole='wall',sprite=3052}
    local b={id=1397,name='Stone Wall',scenery=true,sceneryRole='wall',sprite=3053}
    local plant={id=1634,name='Cabbage',scenery=true,sceneryRole='other'}
    local gate={id=1437,name='Iron Gate',scenery=true,sceneryRole='gate'}
    local mod={id=2028,name='Stone Wall',scenery=true,sceneryRole='wall',definitionMod='Example'}
    ui.catalog={monsters={a,b,plant,gate,mod}}
    ui.team=3;ui.search='Stone Wall';ui:refresh()
    assert(#ui.filtered==2 and ui.filtered[1]==a and ui.filtered[2]==b)
    ui.search='#1397';ui:refresh()
    assert(#ui.filtered==1 and ui.filtered[1]==b)
    ui.search='1396';ui:refresh()
    assert(#ui.filtered==1 and ui.filtered[1]==a)
    ui.search='';ui:refresh()
    assert(#ui.filtered==2)
end)
test('neutral placement rejects the older actor API and partial scenery APIs',function()
    local api={addTestFieldNeutralActor=function()end,testFieldEditorCapabilities=function()return {neutralActorVersion=1}end}
    assert(not M.neutralAvailable(api))
    api.testFieldEditorCapabilities=function()return {sceneryVersion=1}end
    assert(not M.neutralAvailable(api))
    for _,name in ipairs({'testFieldSceneryTypes','testFieldSceneryState','addTestFieldScenery','moveTestFieldScenery','removeTestFieldScenery'}) do api[name]=function()end end
    assert(M.neutralAvailable(api))
end)

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
    r.verified.native.session=8;object,role=r:fieldObjectAt(2,4)
    assert(role=='unverified' and object.monster==nil and object.owner==nil)
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
test('scenery scenarios keep the explicit role and refuse to convert legacy Neutral actors',function()
    local catalog={byId={[13]={id=13,name='Spearman'},[1404]={id=1404,name='Stone Wall',scenery=true}},terrainById={[0]={name='Plain'}}}
    local s=M.new()
    M.add(s,13,'Spearman',1,2,3)
    assert(M.encode(s,{}).scenario.schema==4)
    local u=M.add(s,1404,'Stone Wall',3,4,3)
    local old=M.encode(s,{})
    local invalid,reason=M.decode(old,catalog,{})
    assert(not invalid and reason==M.legacyNeutralProblem and old.scenario.schema==5)
    u.scenery=true
    local encoded=M.encode(s,{})
    local restored=assert(M.decode(encoded,catalog,{}))
    assert(encoded.scenario.schema==6 and #restored.units==2 and restored.units[2].team==3 and restored.units[2].scenery)
    assert(M.count(restored,2)==0 and M.count(restored,3)==1)
    encoded.unit2.object_role='actor'
    assert(not M.decode(encoded,catalog,{}))
    encoded.unit2.object_role='scenery'
    encoded.scenario.neutral_role='foreign'
    assert(not M.decode(encoded,catalog,{}))
    encoded.scenario.schema=4;encoded.scenario.neutral_role=nil
    assert(not M.decode(encoded,catalog,{}))
end)

test('saved Neutral plants and units are refused without rewriting the scenario',function()
    local catalog={byId={
        [13]={id=13,name='Spearman',scenery=true},[1634]={id=1634,name='Cabbage',scenery=true},
    },terrainById={[0]={name='Plain'}}}
    for _,entry in pairs(catalog.byId) do
        local s=M.new()
        local unit=M.add(s,entry.id,entry.name,3,4,3);unit.scenery=true
        local encoded=M.encode(s,{})
        local restored,reason=M.decode(encoded,catalog,{})
        assert(not restored and reason:find(entry.name..' is unavailable in Neutral',1,true))
        assert(reason:find('original scenario file is kept',1,true))
        assert(encoded.scenario.schema==6 and encoded.unit1.monster==entry.id and
            encoded.unit1.team==3 and encoded.unit1.object_role=='scenery')
    end
end)

test('restoration allows one army anchor over standable scenery in either file order',function()
    local catalog={byId={
        [13]={id=13,name='Spearman'},
        [1395]={id=1395,name='Stone Parapet (Heavy Cover)',scenery=true,sceneryStandable=true},
        [1404]={id=1404,name='Stone Wall',scenery=true},
    },terrainById={[0]={name='Plain'}}}
    for _,objectFirst in ipairs({true,false}) do
        local s=M.new()
        local function scenery() M.add(s,1395,catalog.byId[1395].name,3,4,3).scenery=true end
        if objectFirst then scenery() end
        M.add(s,13,'Spearman',1,4,3)
        if not objectFirst then scenery() end
        local valid=assert(M.decode(M.encode(s,{}),catalog,{}))
        assert(M.at(valid,4,3,true).monster==1395)
        assert(M.at(valid,4,3,false).monster==13)
        local blocking=M.at(s,4,3,true);blocking.monster,blocking.name=1404,'Stone Wall'
        local invalid,reason=M.decode(M.encode(s,{}),catalog,{})
        assert(not invalid and reason:find('blocking object',1,true))
    end
end)

test('neutral ownership without generation provenance and unit layer is refused',function()
    local unit=nativeRow(5,'actor','owned_neutral_actor',31,4)
    unit.anchorLayer='unit';unit.generation=3
    assert(Objects.role(unit)=='neutral')
    local s=M.new();local u=M.add(s,13,'Spearman',3,4,4)
    local r=Runtime.new({testFieldState=function()return {complete=true,width=32,height=20,units={unit}}end},{})
    r.live[u.id]=5
    for _,case in ipairs({{'creationSource','owned_actor_creation'},{'anchorLayer','object'},{'provenanceVerified',false},{'owner',24}}) do
        local original=unit[case[1]]
        unit[case[1]]=case[2]
        assert(Objects.role(unit)==nil)
        local ok,why=Integrity.inspect(r,s,true,nil,false)
        assert(not ok and why=='native_identity_mismatch')
        unit[case[1]]=original
    end
end)

test('the final field counts a verified owned neutral independently from same-owner scenery',function()
    local scenery=nativeRow(0,'terrain','native_map_loader',31,2)
    local neutral=nativeRow(1,'actor','owned_neutral_actor',31,4)
    neutral.anchorLayer='unit'
    local plan=Final.prepare({source='post_aftermath_before_upkeep',complete=true,classificationVersion=1,width=8,height=20,
        units={scenery,neutral},grid={{x=2,y=4,object=0},{x=4,y=4,object=-1}}})
    assert(plan.complete and plan.neutral==1 and plan.teamA==0 and plan.teamB==0)
    assert(Final.at(plan,4,4).role=='neutral' and plan.objects['2:4'].role=='scenery')
end)

test('observed object evidence is keyed by loaded ID even for duplicate names',function()
    local first={name='Wall',categories={}}
    local second={name='Wall',categories={object_candidate=true}}
    local catalog={byId={[1]=first,[2]=second}}
    Catalog.recordObjectRole(catalog,1,'scenery')
    assert(first.categories.object_candidate and first.observedObjectRoles.scenery)
    assert(second.categories.object_candidate and not second.observedObjectRoles)
end)
print(cases..' offline battlefield object and report checks passed')
