-- Serialization and file-write decisions using production Save/Load logic.
-- The default API fixture stores data in memory. An optional private host may
-- inject persistenceAuditFile for anonymous-file preservation checks. Neither
-- fixture runs CoE5 or reproduces its native I/O; no user file is opened.
local cache={};function require(name)if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end;return cache[name]end
local M=require('sandbox.model');local U=require('sandbox.ui');local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local catalog={byId={[13]={id=13,name='Spearman'}},terrainById={[0]={name='Plain'}},itemNames={Amulet=153},byItemId={[153]={id=153,name='Amulet'}},spellKeys={['7:Seventh']=7,['1:First']=1},mods={'CoE5SE','SandboxOfElysium'}}
local function fixture(s,mode)
 local original='ORIGINAL VALID TARGET\n';local target=original
 local function disk(action,value)
  if persistenceAuditFile then return persistenceAuditFile(action,value)end
  if action=='reset'or action=='replace'then target=value elseif action=='read'then return target end
 end
 disk('reset',original)
 local calls={writes=0,reads=0,prompts=0,failures={},records={}};local stored=M.encode(M.new(),catalog.mods)
 local api={listIni=function()return{}end}
 api.writeIni=function(name,value)
  calls.writes=calls.writes+1;assert(name=='chosen')
  if mode=='refused'then return false end
  disk('replace','REPLACED TARGET DATA\n');stored=M.copy(value)
  if mode=='exception'then error('Injected native write exception after replacement')end
  if mode=='wrong_readback'then stored.scenario.a_color=4 end
  return true
 end
 api.readIni=function()
  calls.reads=calls.reads+1;if mode=='missing_readback'then return nil end;if mode=='read_exception'then error('Injected native read exception')end
  local function nativeStrings(v)if type(v)=='table'then local out={};for k,value in pairs(v)do out[k]=nativeStrings(value)end;return out end;return type(v)=='number'and tostring(v)or v end
  return mode=='string_readback'and nativeStrings(stored)or M.copy(stored)
 end
 local u=setmetatable({api=api,scenario=s,catalog=catalog,runtime={snapshot=function()return{}end},diag={
  record=function(_,action,data)calls.records[#calls.records+1]={action=action,data=data}end,
  failure=function(_,action,message,details,before,after,restored)calls.failures[#calls.failures+1]={action=action,message=message,details=details,restored=restored}end}},U)
 u.prompt=function()calls.prompts=calls.prompts+1;return 'chosen'end
 u.notice=function(self,text)self.noticeText=text end
 calls.target=function()return disk('read')end;calls.close=function()disk('close')end;calls.original=original
 return u,calls,stored
end
local function configured()
 local s=M.new();s.minimumWidth=160;s.size='Minimum width';s.colors={2,1}
 local u=M.add(s,13,'Spearman',1,12,7);u.id=902;s.nextId=903;u.nativeName='海 Tide';u.label='Legacy banner'
 u.items={'Amulet'};u.equipment={{position=6,id=153,name='Amulet'}};u.schools={{path=1,name='Fixture School',base=2}}
 u.baseline={known={'7:Seventh','1:First'}};u.spells={'7:Seventh'}
 u.condition={version=1,monster=13,width=1,height=1,maxHp=20,hp=11,xp=3,kills=2,injuryFlags=0x00100000}
 s.sourceSchema=3;s.migrationRequired=true
 return s
end
test('an over-limit roster refuses Save before overwriting an existing target',function()
 local s=M.new();for i=1,2001 do M.add(s,13,'Spearman',i%2+1,(i-1)%160,math.floor((i-1)/160))end
 local before=M.copy(s);local u,c=fixture(s);u:save()
 assert(c.writes==0 and c.target()==c.original,'Invalid scenario overwrote the existing target before validation')
 assert(equal(s,before)and u.noticeText:find('2000',1,true));c.close()
end)
test('native maximum-width anchors round-trip and anchors beyond1535 refuse',function()
 for _,x in ipairs({999,1000,1535})do local s=M.new();M.add(s,13,'Spearman',1,x,9);local encoded=M.encode(s,catalog.mods);local loaded,why=M.decode(encoded,catalog,catalog.mods);assert(loaded,why);assert(loaded.units[1].x==x and equal(encoded,M.encode(loaded,catalog.mods)))end
 local s=M.new();M.add(s,13,'Spearman',1,1536,9);assert(not M.decode(M.encode(s,catalog.mods),catalog,catalog.mods))
end)
test('invalid recorded names refuse before writing and keep migration metadata',function()
 local s=configured();s.units[1].nativeName=string.rep('x',33);local before=M.copy(s);local u,c=fixture(s);u:save()
 assert(c.writes==0 and c.target()==c.original and equal(s,before)and s.migrationRequired);c.close()
end)
test('serialization exceptions are shown without writing or losing the editor setup',function()
 local s=M.new();local a=M.add(s,13,'Spearman',1,5,6);a.items=nil;local u,c=fixture(s)
 local ok,why=pcall(u.save,u);assert(ok,why);assert(c.writes==0 and c.target()==c.original and a.items==nil and u.noticeText);c.close()
end)
test('configuration normalization refuses before writing instead of silently changing source order',function()
 local s=configured();local a=s.units[1];a.items={'Amulet','Amulet'};a.equipment={{position=6,id=153,name='Amulet'},{position=0,id=153,name='Amulet'}}
 local before=M.copy(s);local u,c=fixture(s);u:save()
 assert(c.writes==0 and c.target()==c.original and equal(s,before)and s.migrationRequired and u.noticeText:find('round-trip',1,true));c.close()
end)
test('valid exact Save retains ordered configuration and clears migration only after verification',function()
 local s=configured();local expected=M.encode(s,catalog.mods);local u,c=fixture(s);u:save()
 assert(c.writes==1 and c.reads==1 and u.message:find('Scenario saved',1,true)and not s.migrationRequired and s.sourceSchema==4)
 assert(equal(expected,M.encode(s,catalog.mods))and #c.failures==0);c.close()
end)
test('native INI numeric strings verify without rejecting the unchanged semantic payload',function()
 local s=configured();local expected=M.encode(s,catalog.mods);local u,c=fixture(s,'string_readback');u:save()
 assert(c.writes==1 and c.reads==1 and u.message:find('Scenario saved',1,true)and equal(expected,M.encode(s,catalog.mods))and #c.failures==0);c.close()
end)
test('different but valid readback never counts as a verified Save',function()
 local s=configured();local before=M.copy(s);local u,c=fixture(s,'wrong_readback');u:save()
 assert(c.writes==1 and c.reads==1 and equal(s,before)and s.migrationRequired)
 assert(u.message:find('could not be verified',1,true)and c.failures[1].restored:find('unverified',1,true));c.close()
end)
test('missing readback leaves migration metadata and reports file uncertainty',function()
 local s=configured();local before=M.copy(s);local u,c=fixture(s,'missing_readback');u:save()
 assert(c.writes==1 and equal(s,before)and u.message:find('could not be verified',1,true))
 assert(c.failures[1].restored:find('unverified',1,true));c.close()
end)
test('readback exceptions keep the editor scenario and disclose unverified target state',function()
 local s=configured();local before=M.copy(s);local u,c=fixture(s,'read_exception');local ok,why=pcall(u.save,u);assert(ok,why)
 assert(c.writes==1 and c.reads==1 and equal(s,before)and u.message:find('could not be verified',1,true)and c.failures[1].restored:find('unverified',1,true));c.close()
end)
test('native write refusal preserves the target and does not clear migration metadata',function()
 local s=configured();local before=M.copy(s);local u,c=fixture(s,'refused');u:save()
 assert(c.writes==1 and c.reads==0 and c.target()==c.original and equal(s,before)and not u.message:find('Scenario saved',1,true));c.close()
end)
test('a write exception cannot escape or pretend the target was unchanged',function()
 local s=configured();local before=M.copy(s);local u,c=fixture(s,'exception');local ok,why=pcall(u.save,u);assert(ok,why)
 assert(c.writes==1 and c.target()~=c.original and equal(s,before)and u.noticeText and c.failures[1].restored:find('unverified',1,true));c.close()
end)
test('cancel and migration name collision preserve the target without writing',function()
 for _,mode in ipairs({'cancel','collision'})do local s=configured();local before=M.copy(s);local u,c=fixture(s)
  if mode=='cancel'then u.prompt=function()return nil end else u.api.listIni=function()return{'chosen.ini'}end end
  u:save();assert(c.writes==0 and c.reads==0 and c.target()==c.original and equal(s,before));c.close()
 end
end)
print(count..' persistence audit contracts passed ('..(persistenceAuditFile and 'anonymous file' or 'memory')..' fixture); native geometry and I/O remain separate acceptance scopes')
