-- Offline metadata/serialization/refusal contracts only. No native water,
-- terrain geometry, ships, passengers or combat are simulated here.
local cache={}
function require(name)
    if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end
    return cache[name]
end
local M=require('sandbox.model')
local C=require('sandbox.catalog')
local R=require('sandbox.runtime')
local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function same(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local function catalog()
    local c={terrainById={},byId={[13]={id=13,name='Spearman'},[953]={id=953,name='Goblin'}},
        itemNames={Amulet=153},byItemId={[153]={id=153,name='Amulet'}},
        spellKeys={['1:First']=1,['3:Third']=3,['7:Seventh']=7},mods={},testFieldTerrains={}}
    for id,name in pairs(M.terrainNames)do c.terrainById[id]={id=id,name=name};c.testFieldTerrains[id]=true end
    return c
end
local function catalogApi(ids,changed)
    return{
        get=function(key,id)
            if key=='terrainLastIndex'then return 117
            elseif key:find('LastIndex',1,true)then return -1
            elseif key=='terrainName'then return id==78 and changed or M.terrainNames[id]
            elseif key=='terrain'then return 0 end
        end,
        testFieldTerrains=function()return ids end,
        testFieldEditorCapabilities=function()return{structureProvenance=1}end,
        testFieldEnvironmentInfo=function()return{waterContextVersion=1,minimumWidthVersion=1}end,
        testFieldWaterState=function()error('Offline metadata checks must not query native actor water state.')end,
        spellInfo=function()end,
    }
end
local function scenario(n,terrain)
    local s=M.new();s.terrain=terrain or 78;s.minimumWidth=50;s.size='Minimum width'
    s.startingItems=false;s.allowMultipleUnique=true;s.colors={3,6}
    if n>0 then
        local u=M.add(s,13,'Spearman',1,8,9)
        u.nativeName='Küstenwache';u.baseline={known={'7:Seventh','1:First','3:Third'}};u.spells={'3:Third','7:Seventh'}
        u.items={'Amulet'};u.equipment={{position=2,id=153,name='Amulet'}}
        u.schools={{path=1,name='Fixture School',base=2}}
        u.condition={version=1,monster=13,width=1,height=1,maxHp=20,hp=12,xp=17,kills=3,injuryFlags=0x00100000}
    end
    if n>1 then local u=M.add(s,953,'Goblin',2,28,7);u.nativeName='Other Shore'end
    return s
end

test('accepted coast identity is explicit and is not a siege',function()
    assert(M.terrainNames[78]=='Coastal Hamlet','The public coast matrix requires the accepted production identity for terrain78.')
    assert(not M.isSiegeTerrain(78))
end)
test('coast requires exact version1 water metadata and the real actor query function',function()
    assert(not M.terrainCapabilityAvailable({},78))
    for _,version in ipairs({0,2,true,'1'})do
        assert(not M.terrainCapabilityAvailable({testFieldEnvironmentInfo=function()return{waterContextVersion=version}end,testFieldWaterState=function()end},78))
    end
    assert(not M.terrainCapabilityAvailable({testFieldEnvironmentInfo=function()return{waterContextVersion=1}end},78))
    assert(not M.terrainCapabilityAvailable({testFieldEnvironmentInfo=function()error('unavailable')end,testFieldWaterState=function()end},78))
    assert(M.terrainCapabilityAvailable({testFieldEnvironmentInfo=function()return{waterContextVersion=1}end,testFieldWaterState=function()end},78))
end)
test('unaccepted open water and compound coastal contexts are not advertised by name alone',function()
    for _,id in ipairs({10,69,48,79,146,161,168,218,280,316})do assert(not M.terrainNames[id],'A separate native acceptance is required for terrain '..id)end
end)
test('catalogue requires actual native coast advertisement and exact loaded identity',function()
    local c=C.read(catalogApi({0,78,10,69,146}))
    assert(c.testFieldTerrains[0]and c.testFieldTerrains[78])
    assert(not c.testFieldTerrains[10]and not c.testFieldTerrains[69]and not c.testFieldTerrains[146])
    c=C.read(catalogApi({0,78},'Changed Coastal Hamlet'))
    assert(c.testFieldTerrains[0]and not c.testFieldTerrains[78])
    c=C.read(catalogApi({0}));assert(not c.testFieldTerrains[78])
end)
test('missing throwing malformed or string native lists never advertise coast',function()
    local a=catalogApi({0});a.testFieldTerrains=nil;assert(not C.read(a).testFieldTerrains[78])
    a.testFieldTerrains=function()error('unavailable')end;assert(not C.read(a).testFieldTerrains[78])
    a.testFieldTerrains=function()return true end;assert(not C.read(a).testFieldTerrains[78])
    a.testFieldTerrains=function()return{'78'}end;assert(not C.read(a).testFieldTerrains[78])
end)
test('old extender refuses coast before any current-field replacement',function()
    for _,method in ipairs({'build','_build'})do
        local closes=0;local api={testFieldTerrains=function()return{0,2}end,
            closeTestField=function()closes=closes+1;error('An unsupported terrain must not close the old field.')end}
        local r=R.new(api,catalog());local previous=M.new();r.current=previous;r.open=true
        local s=M.new();s.terrain=78;local saved=M.copy(s)
        local ok,why=r[method](r,s)
        assert(not ok and why:find('requires',1,true)and closes==0 and r.open and r.current==previous and same(s,saved))
    end
end)
test('empty one-sided and both-team coast setups round-trip schema4 without changing configuration',function()
    for _,n in ipairs({0,1,2})do
        local s=scenario(n);local encoded=M.encode(s,{})
        local loaded,why=M.decode(encoded,catalog(),{});assert(loaded,why)
        assert(loaded.terrain==78 and #loaded.units==n and same(encoded,M.encode(loaded,{})))
        if n>0 then
            assert(same(loaded.units[1].baseline.known,{'7:Seventh','1:First','3:Third'}))
            assert(same(loaded.units[1].spells,{'3:Third','7:Seventh'}))
            assert(loaded.units[1].condition.hp==12 and loaded.units[1].condition.injuryFlags==0x00100000)
        end
    end
end)
test('all tested size presets retain coast identity and exact stored width option',function()
    for _,width in ipairs({32,50,70,160})do
        local s=scenario(0);s.minimumWidth=width
        local loaded,why=M.decode(M.encode(s,{}),catalog(),{});assert(loaded,why)
        assert(loaded.terrain==78 and loaded.minimumWidth==width and loaded.size=='Minimum width')
    end
end)
test('changed terrain item and unit identities reject a copy without rewriting its records',function()
    local encoded=M.encode(scenario(2),{});local saved=M.copy(encoded)
    for _,change in ipairs({
        function(c)c.terrainById[78].name='Changed Coast'end,
        function(c)c.byItemId[153].name='Changed Amulet'end,
        function(c)c.byId[13].name='Changed Spearman'end,
    })do
        local c=catalog();change(c);assert(not M.decode(encoded,c,{}));assert(same(encoded,saved))
    end
end)
test('all previously accepted terrains keep their saved identities and actor configuration',function()
    local old={[0]='Plain',[2]='Forest',[12]='Mountains',[107]='Swamp',[115]='Jungle',[117]='Desert',
        [5]='Farm',[18]='Village',[70]='Hoburg Village',[98]='Oasis',[109]='Tent Village',
        [1]='Fortified Hoburg',[20]='Guard tower',[72]='Watch Tower',[22]='Castle',[23]='Citadel',[17]='Town',[9]='City'}
    for id,name in pairs(old)do
        assert(M.terrainNames[id]==name)
        local encoded=M.encode(scenario(2,id),{});local loaded,why=M.decode(encoded,catalog(),{});assert(loaded,why)
        assert(same(encoded,M.encode(loaded,{})))
    end
end)

-- Only exercise the probe's preflight dispatch here. No fake unit/grid state,
-- native placement, transport semantics or successful native field is supplied.
local function blockedProbe(run,c,waterFunction)
    local oldApi,oldRead=coe5,C.read;local hooks,writes={},{};local reads=0
    coe5={
        readIni=function(name)if name=='request'then return{run=run}elseif name=='launcher-context'then return{environment={session='offline-gate'}}end end,
        observe=function()end,wrap=function(name,callback)hooks[name]=callback end,
        writeIni=function(name,value)writes[name]=value;return true end,
        set=function()error('Blocked dispatch must not mutate native state')end,
        openTestField=function()error('Blocked dispatch must not open a native field')end,
        closeTestField=function()error('Blocked dispatch must not close a native field')end,
    }
    coe5.testFieldWaterState=waterFunction
    C.read=function()reads=reads+1;return c or{testFieldTerrains={},environment={minimumWidthVersion=1}}end
    local ok,why=pcall(function()
        assert(loadfile('tests/water_coast_probe.lua'))()
        assert(hooks.MAIN_MENU_WAIT(function()return 123 end)==123)
        assert(writes.results and writes.results.complete.status=='BLOCKED')
        -- One-shot guard must not reopen/rewrite after its first result.
        local first=writes.results;assert(hooks.MAIN_MENU_WAIT(function()return 124 end)==124 and writes.results==first)
    end)
    coe5,C.read=oldApi,oldRead;assert(ok,why)
    return writes.results,reads
end
test('open-water probe placeholders are blocked before reading a field catalogue',function()
    for _,id in ipairs({10,27})do
        local out,reads=blockedProbe({terrain=id,minimum=50})
        assert(reads==0 and out.request.terrain==id and out['terrain'..id].status=='BLOCKED')
        assert(out['terrain'..id].detail:find('not accepted',1,true))
    end
end)
test('probe rejects unknown contexts and unsupported minimum widths without field mutation',function()
    local out,reads=blockedProbe({terrain=161});assert(out.request.terrain==161 and reads==0)
    for _,width in ipairs({0,49,51,1537})do local out,reads=blockedProbe({terrain=78,minimum=width});assert(reads==0 and out.request.minimum==width)end
end)
test('coast probe defaults to terrain78 minimum50 and cannot bypass missing advertisement',function()
    local out,reads=blockedProbe({})
    assert(reads==1 and out.request.terrain==78 and out.request.minimum==50)
    assert(out.terrain78.detail:find('capability',1,true))
end)
test('public coast probe also requires the native minimum-width contract',function()
    local out=blockedProbe({terrain=78,minimum=70},{testFieldTerrains={[78]=true},environment={}})
    assert(out.request.minimum==70 and out.terrain78.detail:find('minimum%-width'))
end)
test('public coast probe refuses a missing or wrong water context before any native mutation',function()
    for _,version in ipairs({false,0,2,true,'1'})do
        local out=blockedProbe({terrain=78},{testFieldTerrains={[78]=true},environment={minimumWidthVersion=1,waterContextVersion=version}},function()end)
        assert(out.terrain78.detail:find('water%-context'))
    end
    for _,missing in ipairs({false,true,'function'})do
        local out=blockedProbe({terrain=78},{testFieldTerrains={[78]=true},environment={minimumWidthVersion=1,waterContextVersion=1}},missing)
        assert(out.terrain78.detail:find('water%-context'))
    end
end)
test('transport refusal uses native movement and abilities rather than unit names or IDs',function()
    local flags,ability=0,nil
    local api={get=function(key,id,path)if key=='monsterMoveFlags'then return flags elseif key=='monsterAbility'then return path==ability and 1 or 0 end end}
    assert(not M.waterMonsterProblem(api,78,118)) -- An ID does not establish transport.
    flags=1<<40;assert(M.waterMonsterProblem(api,78,13):find('passenger',1,true));flags=0
    for _,path in ipairs({0x1cf,0x1d2,0x1d3})do ability=path;assert(M.waterMonsterProblem(api,78,13):find('passenger',1,true))end
    assert(not M.waterMonsterProblem({get=function()error('Land behavior must be unchanged')end},0,13))
    assert(M.waterMonsterProblem({get=function()return nil end},78,13):find('unknown',1,true))
end)
test('unsupported transport refuses both rebuild entry points before closing the existing field',function()
    for _,method in ipairs({'build','_build'})do
        local closes=0;local api={testFieldEnvironmentInfo=function()return{waterContextVersion=1}end,testFieldWaterState=function()end,
            testFieldTerrains=function()return{78}end,closeTestField=function()closes=closes+1;error('Must not close')end,
            get=function(key)if key=='monsterMoveFlags'then return 1<<40 end;return 0 end}
        local r=R.new(api,catalog());local old=M.new();r.current=old;r.open=true
        local s=M.new();s.terrain=78;M.add(s,13,'Spearman',1,5,5);M.add(s,953,'Goblin',2,20,5)
        local ok,why=r[method](r,s);assert(not ok and why:find('passenger',1,true)and closes==0 and r.current==old and r.open)
    end
end)
test('water messages report native hazards and unknown answers without changing native rules',function()
    local state={version=1,cellWater=true,willDrown=true,moveFlags=0,scope='native corners'}
    local api={testFieldWaterState=function(unit,x,y)assert(unit==123 and x==7 and y==8);return state end}
    local r=R.new(api,catalog());r.current=M.new();r.current.terrain=78
    assert(r:waterWarning(123,7,8):find('drown',1,true));state.willDrown=false;assert(not r:waterWarning(123,7,8))
    state.ship=true;assert(r:waterWarning(123,7,8):find('unsupported',1,true))
    api.testFieldWaterState=function()return nil,'declared unknown'end;assert(r:waterWarning(123,7,8):find('could not be checked',1,true))
    r.current.terrain=0;api.testFieldWaterState=function()error('Land must not query water')end;assert(not r:waterWarning(123,7,8))
end)
test('accepted independent-actor water identities require exact native admission and preserve schema4 state',function()
    for id,name in pairs({[27]='Sea',[68]='Deep Sea',[78]='Coastal Hamlet'})do
        assert(M.terrainNames[id]==name and M.isWaterTerrain(id)and not M.isSiegeTerrain(id))
        assert(not M.terrainCapabilityAvailable({},id))
        local api=catalogApi({id});local c=C.read(api);assert(c.testFieldTerrains[id])
        api.testFieldWaterState=nil;assert(not C.read(api).testFieldTerrains[id])
        local s=scenario(2,id);local encoded=M.encode(s,{});local loaded=assert(M.decode(encoded,catalog(),{}));assert(same(encoded,M.encode(loaded,{})))
    end
end)
print(count..' offline water/coast metadata, persistence and early-refusal contracts passed; native water and transport remain untested')
