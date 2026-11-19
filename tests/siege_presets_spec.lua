-- Metadata, persistence and UI contracts only. No native siege is simulated.
local cache={}
function require(name)
    if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end
    return cache[name]
end
local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local U=require('sandbox.ui');local count=0
local sieges={[1]='Fortified Hoburg',[20]='Guard tower',[72]='Watch Tower',[22]='Castle',[23]='Citadel',[17]='Town',[9]='City'}
local neutral={[0]='Plain',[2]='Forest',[12]='Mountains',[107]='Swamp',[115]='Jungle',[117]='Desert',[5]='Farm',[18]='Village',[70]='Hoburg Village',[98]='Oasis',[109]='Tent Village'}
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function same(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function catalog()
    local c={terrainById={},byId={[13]={id=13,name='Spearman'},[953]={id=953,name='Goblin'}},mods={},testFieldTerrains={[0]=true,[1]=true,[5]=true},
        itemNames={Amulet=153},byItemId={[153]={id=153,name='Amulet'}},spellKeys={['1:Known I']=1,['3:Known III']=3},monsters={}}
    for id,name in pairs(M.terrainNames)do c.terrainById[id]={id=id,name=name};c.testFieldTerrains[id]=true end
    return c
end
local function uiFixture(terrain)
    local api={get=function(key)if key=='screenW'then return 800 elseif key=='screenH'then return 600 elseif key=='uiPointerX'then return 100 elseif key=='uiPointerY'then return 200 elseif key=='modLastIndex'then return -1 end;return 0 end,
        readIni=function()end,wrap=function()return true end,observe=function()end,set=function()end,
        ui={drawRect=function()end,drawText=function()end,drawMonsterIconFit=function()return true end}}
    local u=U.new(api);u.scenario=M.new();u.scenario.terrain=terrain;u.catalog=catalog();u.filtered={};u.selected=nil
    u.runtime={open=true,width=32,live={},objects={},verified={structures={[77]='declared native structure signature'}},emptyEditorAvailable=function()return true end}
    u.runtime.remove=function(_,s,actor)local next=M.copy(s);M.remove(next,actor.id);return true,next end
    u.notice=function(self,text)self.noticeText=text end
    return u,api
end
test('the explicit siege set contains exactly the seven accepted loaded identities',function()
    local n=0;for id,v in pairs(M.siegeTerrains)do n=n+1;assert(sieges[id]and v==true and M.terrainNames[id]==sieges[id])end
    for id,name in pairs(sieges)do assert(M.isSiegeTerrain(id)and M.terrainNames[id]==name)end
    assert(n==7 and not M.isSiegeTerrain(0)and not M.isSiegeTerrain(70))
    for _,id in ipairs({13,21,25,26,30,154})do assert(not M.isSiegeTerrain(id)and not M.terrainNames[id],'Unaccepted candidate or duplicate variant leaked into product metadata.')end
end)
test('siege capability requires exact numeric version1 and neutral metadata does not query it',function()
    for id in pairs(sieges)do
        assert(not M.terrainCapabilityAvailable({},id))
        for _,value in ipairs({0,2,true,'1'})do assert(not M.terrainCapabilityAvailable({testFieldEditorCapabilities=function()return{structureProvenance=value}end},id))end
        assert(not M.terrainCapabilityAvailable({testFieldEditorCapabilities=function()error('declared unavailable')end},id))
        assert(M.terrainCapabilityAvailable({testFieldEditorCapabilities=function()return{structureProvenance=1}end},id))
    end
    local api={testFieldEditorCapabilities=function()error('neutral capability must not be queried')end}
    for id,name in pairs(neutral)do assert(M.terrainNames[id]==name and not M.isSiegeTerrain(id)and M.terrainCapabilityAvailable(api,id))end
end)
test('requirements derive from the explicit set rather than a second synchronized ID list',function()
    -- Existing Farm is marked in this isolated metadata fixture only; no native
    -- context or product identity is added or advertised by the test.
    local saved=M.siegeTerrains[5];M.siegeTerrains[5]=true
    local ok,why=pcall(function()
        assert(M.isSiegeTerrain(5)and not M.terrainCapabilityAvailable({},5))
        assert(M.terrainCapabilityAvailable({testFieldEditorCapabilities=function()return{structureProvenance=1}end},5))
    end)
    M.siegeTerrains[5]=saved;assert(ok,why);assert(not M.isSiegeTerrain(5))
end)
test('all seven sieges refuse missing or wrong capabilities before any Runtime close',function()
    for terrain in pairs(sieges)do for _,value in ipairs({false,0,2,true,'1'})do
        local closes=0;local api={testFieldTerrains=function()return{0,terrain}end,closeTestField=function()closes=closes+1;error('must not close')end}
        if value~=false then api.testFieldEditorCapabilities=function()return{structureProvenance=value}end end
        local r=R.new(api,catalog());local old=M.new();r.current=old;r.open=true;local s=M.new();s.terrain=terrain
        local ok,why=r:build(s);assert(not ok and why:find('structure%-provenance')and closes==0 and r.current==old and r.open)
        local ok,why=r:_build(s);assert(not ok and why:find('structure%-provenance')and closes==0 and r.current==old)
    end end
end)
test('catalogue uses exact identity and generic siege capability without affecting neutral presets',function()
    local api={get=function(key,id)
        if key=='terrainLastIndex'then return 117 elseif key:find('LastIndex',1,true)then return -1 elseif key=='terrainName'then return M.terrainNames[id]elseif key=='terrain'then return 0 end
    end,spellInfo=function()end,testFieldTerrains=function()local ids={0,5,70,13};for id in pairs(sieges)do ids[#ids+1]=id end;return ids end}
    local c=C.read(api);for id in pairs(sieges)do assert(not c.testFieldTerrains[id])end
    assert(c.testFieldTerrains[0]and c.testFieldTerrains[5]and c.testFieldTerrains[70]and not c.testFieldTerrains[13])
    api.testFieldEditorCapabilities=function()return{structureProvenance=1}end;c=C.read(api)
    for id in pairs(sieges)do assert(c.testFieldTerrains[id])end
    local get=api.get
    for changed in pairs(sieges)do
        api.get=function(key,id)if key=='terrainName'and id==changed then return 'Changed fortified identity'end;return get(key,id)end
        c=C.read(api);assert(not c.testFieldTerrains[changed]and c.testFieldTerrains[5])
        for id in pairs(sieges)do if id~=changed then assert(c.testFieldTerrains[id])end end
    end
end)
test('known siege names and provenance capability cannot substitute for native preset advertisement',function()
    for terrain in pairs(sieges)do
        local closed=0;local api={testFieldTerrains=function()return{0}end,testFieldEditorCapabilities=function()return{structureProvenance=1}end,
            closeTestField=function()closed=closed+1;error('must not close')end}
        local r=R.new(api,catalog());local old=M.new();r.current=old;r.open=true;local s=M.new();s.terrain=terrain
        local ok,why=r:build(s);assert(not ok and why:find('requires the matching experimental terrain API',1,true)and closed==0 and r.current==old and r.open)
    end
end)
test('schema4 preserves each siege identity, native names and exact actor configuration/state',function()
    for terrain in pairs(sieges)do
    local s=M.new();s.terrain=terrain;s.startingItems=false;s.allowMultipleUnique=true
    local a=M.add(s,13,'Spearman',1,6,7);M.add(s,953,'Goblin',2,20,9)
    a.nativeName='Siege Sage';a.baseline={known={'3:Known III','1:Known I'}};a.spells={'1:Known I'}
    a.equipment={{position=6,id=153,name='Amulet'}};a.items={'Amulet'};a.schools={{path=39,name='Druidism',base=2}}
    a.condition={version=1,monster=13,width=1,height=1,maxHp=10,hp=9,xp=21,kills=3,injuryFlags=0x100000}
    local encoded=M.encode(s,{});local loaded,why=M.decode(encoded,catalog(),{});assert(loaded,why)
    assert(encoded.scenario.schema==4 and same(M.encode(loaded,{}),encoded)and M.isSiegeTerrain(loaded.terrain))
    assert(#loaded.units==2 and loaded.units[1].nativeName=='Siege Sage'and loaded.units[1].baseline.known[1]=='3:Known III')
    local changed=catalog();changed.terrainById[terrain].name='Changed identity'
    assert(not M.decode(encoded,changed,{}))
    end
end)
test('all eleven neutral identities retain their schema4 persistence and stay outside the siege set',function()
    for terrain in pairs(neutral)do
        local s=M.new();s.terrain=terrain;local actor=M.add(s,13,'Spearman',2,20,5);actor.nativeName='Neutral Guard'
        local encoded=M.encode(s,{});local loaded,why=M.decode(encoded,catalog(),{});assert(loaded,why)
        assert(not M.isSiegeTerrain(loaded.terrain)and same(M.encode(loaded,{}),encoded))
    end
end)
test('siege hint adds no action or control and neutral setup keeps the same navigation IDs',function()
    for terrain in pairs(sieges)do
    local siege=uiFixture(terrain);local neutral=uiFixture(5);local ids={}
    for _,row in ipairs(neutral:setupRows())do if row[1]and row[1]~=0 then ids[row[1]]=true end end
    local found=false;for _,row in ipairs(siege:setupRows())do
        if row[1]and row[1]~=0 then assert(ids[row[1]]);ids[row[1]]=nil end
        if row[2]and row[2]:find('Team A attacks',1,true)then found=true end
    end
    assert(found and next(ids)==nil)
    for _,row in ipairs(neutral:setupRows())do assert(not(row[2]and row[2]:find('Team A attacks',1,true)))end
    end
end)
test('Clear keeps native structures outside both army rosters and uses the metadata helper for its message',function()
    local terrains={0};for id in pairs(sieges)do terrains[#terrains+1]=id end
    for _,terrain in ipairs(terrains)do
        local u=uiFixture(terrain);M.add(u.scenario,13,'Spearman',1,5,5);M.add(u.scenario,953,'Goblin',2,20,5)
        local structures=M.copy(u.runtime.verified.structures);assert(u:dispatch('clear')and #u.scenario.units==0)
        assert(same(structures,u.runtime.verified.structures))
        assert((u.message:find('Native fort structures stay',1,true)~=nil)==M.isSiegeTerrain(terrain))
    end
end)
test('clear and setup hints follow a fixture siege flag without any terrain1 special case',function()
    local saved=M.siegeTerrains[5];M.siegeTerrains[5]=true
    local ok,why=pcall(function()
        local u=uiFixture(5);local hint=false;for _,row in ipairs(u:setupRows())do if row[2]and row[2]:find('Team A attacks',1,true)then hint=true end end
        assert(hint and u:dispatch('clear')and u.message:find('Native fort structures stay',1,true))
    end)
    M.siegeTerrains[5]=saved;assert(ok,why)
end)
test('limitations count comes from currently advertised validated presets',function()
    local u=uiFixture(1);u.catalog.testFieldTerrains={[0]=true,[1]=true,[5]=true};u.ensureCatalog=function()end;local calls=0
    u.menu=function()calls=calls+1;return calls==1 and 6 or 999 end
    u:setup();assert(calls==2 and u.noticeText:find('3 verified battlefield contexts',1,true)and not u.noticeText:find('Twelve',1,true))
end)
test('battlefield actions and Single/row/square controls remain available unchanged',function()
    local u=uiFixture(1);u.phase='prepare';u.native=false;u:draw();local seen={}
    for _,b in ipairs(u.buttons)do seen[b.key]=true end
    for _,key in ipairs({'fight','save','load','clear','clearitems','startingitems','unique','formation','search','filter','back'})do assert(seen[key],key)end
    assert(not seen.number and not seen.numberdown)
    u:dispatch('formation');u:draw();seen={};for _,b in ipairs(u.buttons)do seen[b.key]=true end
    assert(seen.number and seen.numberdown and u.formation==2 and u.n==1)
    u:dispatch('number');u:dispatch('numberdown');assert(u.n==1)
    u:dispatch('formation');u:dispatch('formation');assert(u.formation==4 and u.n==2)
end)
print(count..' offline generic siege metadata/capability/persistence/UI contracts passed; these checks do not validate native siege behavior')
