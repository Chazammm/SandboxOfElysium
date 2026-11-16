-- Offline coverage for persistence boundaries; real engine behavior is tested separately.
local cache={}
function require(name)if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end;return cache[name]end
local M=require('sandbox.model');local B=require('sandbox.battlefields');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local U=require('sandbox.ui')
local count=0;local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local catalog={byId={[13]={id=13,name='Spearman'}},terrainById={[0]={name='Plain'}},itemNames={},spellKeys={['1:Spell']=1},mods={}}
local function actor(s,x)local u=M.add(s,13,'Spearman',1,x,4);u.baseline={known={'1:Spell'}};u.spells={'1:Spell'};u.condition={version=1,monster=13,width=1,height=1,maxHp=6,hp=4,xp=7,kills=2,injuryFlags=0x100000};return u end
local function encoded()local s=M.new();actor(s,2);actor(s,6);M.remove(s,1);actor(s,9);s.startingItems=false;s.size='Minimum width';s.minimumWidth=50;return M.encode(s,{})end
local function decode(t)return M.decode(t,catalog,{})end
local function bad(mutator)local t=encoded();mutator(t);local s=decode(t);assert(not s)end
test('schema3 preserves model identity gaps, health, injuries and the next identity',function()
 local t=encoded();local s,why=decode(t);assert(s,why);assert(s.units[1].id==2 and s.units[2].id==3 and s.nextId==4)
 assert(s.units[1].condition.hp==4 and s.units[1].condition.injuryFlags==0x100000 and s.units[1].condition.xp==7 and s.minimumWidth==50 and not s.startingItems)
 local u=M.add(s,13,'Spearman',2,18,4);assert(u.id==4 and u.omitStartingItems)
end)
test('copies keep independent supported state and captured configuration despite the new-unit toggle',function()
 local s=M.new();local a=actor(s,2);s.startingItems=false;local b=M.add(s,13,'Spearman',2,8,4,a)
 assert(b.id~=a.id and not b.omitStartingItems and b.condition.hp==4);b.condition.hp=1;b.baseline.known[1]='other';assert(a.condition.hp==4 and a.baseline.known[1]=='1:Spell')
end)
test('per-actor planned omission survives later changes to the global policy',function()
 local s=M.new();s.startingItems=false;local u=M.add(s,13,'Spearman',1,3,4);s.startingItems=true
 local restored=assert(decode(M.encode(s,{})));assert(restored.startingItems and restored.units[1].omitStartingItems and not restored.units[1].baseline)
end)
test('duplicate model IDs and reused next identities are rejected',function()bad(function(t)t.unit2.model_id=t.unit1.model_id end);bad(function(t)t.scenario.next_id=2 end)end)
test('incomplete and falsely complete actor-state coverage is refused',function()bad(function(t)t.unit1.state_hp=nil end);bad(function(t)for k in pairs(t.unit1)do if k:match('^state_')then t.unit1[k]=nil end end end);bad(function(t)t.scenario.full_native_state=1 end)end)
test('unknown injury bits, changed body identity and dead HP cannot be substituted',function()bad(function(t)t.unit1.state_injuryFlags=0x100001 end);bad(function(t)t.unit1.state_monster=14 end);bad(function(t)t.unit1.state_hp=0 end)end)
test('legacy schemas retain explicit migration scope and normal defaults',function()
 for _,schema in ipairs({1,2})do local s=M.new();local t=M.encode(s,{});t.scenario.schema=schema;local v=assert(decode(t));assert(v.legacyState and v.startingItems and v.sourceSchema==schema and #v.units==0)end
end)
test('empty and one-sided schema3 setups roundtrip',function()
 local s=M.new();assert(#assert(decode(M.encode(s,{}))).units==0);M.add(s,13,'Spearman',2,3,4);local v=assert(decode(M.encode(s,{})));assert(M.count(v,1)==0 and M.count(v,2)==1)
end)
test('missing experimental APIs refuse a saved actor or size before closing a field',function()
 local calls=0;local r=R.new({closeTestField=function()calls=calls+1 end},catalog);local s=assert(decode(encoded()));local ok,why=r:build(s);assert(not ok and why:find('size API',1,true)and calls==0)
 s.minimumWidth=nil;s.size='Native automatic';ok,why=r:build(s);assert(not ok and why:find('health/injury',1,true)and calls==0)
end)
test('minimum sizes require explicit supported API metadata and retain automatic default',function()
 local s=M.new();local before=M.copy(s);assert(not B.selectSize({},s,B.sizes[3]));assert(s.size==before.size and not s.minimumWidth)
 local c={environment={minimumWidthVersion=1,rows=20,minimumColumns=32,maximumColumns=1536}};assert(B.selectSize(c,s,B.sizes[3])and s.minimumWidth==50);assert(B.selectSize(c,s,B.sizes[1])and not s.minimumWidth)
end)
test('unit origin is read from the defining-mod getter, without numeric or name guesses',function()
 local names={[2]='A vanilla-looking name',[5999]='Crab-looking vanilla name'}
 local api={get=function(key,id)if key=='monsterLastIndex'then return 5999 elseif key=='modLastIndex'or key=='itemLastIndex'or key=='terrainLastIndex'then return -1 elseif key=='monsterName'then return names[id]elseif key=='monsterMod'then return id==2 and'CrabCult'or nil end end,spellInfo=function()end,monsterHasRanged=function()return false end}
 local c=C.read(api);assert(#C.filter(c,'','modded')==1 and C.filter(c,'','modded')[1].id==2);assert(#C.filter(c,'','unknown_origin')==1 and not c.byId[5999].categories.modded)
end)
test('legacy migration refuses an existing filename without writing or touching the original',function()
 local writes=0;local original={scenario={schema=1}}
 local ui=setmetatable({scenario={legacyState=true},catalog=catalog,api={listIni=function()return{'original.ini'}end,writeIni=function()writes=writes+1 end},prompt=function()return'original'end,notice=function(self,text)self.refusal=text end},{__index=U})
 ui:save();assert(writes==0 and ui.refusal:find('unused name',1,true)and original.scenario.schema==1)
end)
test('rollback uses last verified size rather than mutated pending menu settings',function()
 local old=M.new();old.minimumWidth=50;old.size='Minimum width';local pending=M.copy(old);pending.minimumWidth=70
 local r=R.new({testFieldEnvironmentInfo=function()return{minimumWidthVersion=1}end,testFieldTerrains=function()return{0}end,testFieldEditorCapabilities=function()return{emptyEditor=1}end,testFieldState=function()end},catalog)
 r.open=true;r.current=pending;r.lastKnownGood=M.copy(old);local calls=0
 r._build=function(self,s)calls=calls+1;if calls==1 then assert(s.minimumWidth==70);return false,'explicit test refusal'end;assert(s.minimumWidth==50);return true end
 r.check=function()return true,{}end
 local ok=r:build(pending);assert(not ok and calls==2 and r.current.minimumWidth==50 and not r.blocked)
end)
test('unsupported native actor state refuses capture before changing the saved actor',function()
 local L=require('sandbox.loadout');local u={items={'preserved'},condition={hp=5}}
 local r={api={testFieldActorState=function()return nil,'unsupported_state'end,setTestFieldActorState=function()end}}
 local ok,why=L.capture(r,u,{unit=3});assert(not ok and why=='unsupported_state'and u.items[1]=='preserved'and u.condition.hp==5)
end)
print(count..' release-next persistence/API-boundary tests passed; no native engine was simulated')
