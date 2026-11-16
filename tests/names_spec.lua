-- Offline validation/persistence and transaction decisions; no native game simulated.
local cache={};function require(name)if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end;return cache[name]end
local M=require('sandbox.model');local N=require('sandbox.names');local R=require('sandbox.runtime');local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local c={byId={[13]={id=13,name='Spearman'}},terrainById={[0]={name='Plain'}},itemNames={},spellKeys={},mods={}}
local function scene()local s=M.new();local a=M.add(s,13,'Spearman',1,5,4);local b=M.add(s,13,'Spearman',2,18,4);return s,a,b end
local function nativeApi(read,set)return{testFieldEditorCapabilities=function()return{individualNameVersion=1,individualNameMaxBytes=47}end,testFieldUnitName=read,setTestFieldUnitName=set}end
local function fixture(mode)
 local s,a,b=scene();a.nativeName='Old';a.baseline={known={'preserved'}};local native='Old';local calls,locked=0,false
 local function state()return{version=1,unit=10,generation=7,commander=-1,name=native,custom=native~='',storage='owned_native_formatter_override',shown=native~=''and native or'Spearman'}end
 local api=nativeApi(function()return state()end,function(unit,value)calls=calls+1;assert(unit==10);if mode=='refuse'then return false,'test_refusal',{rollbackVerified=true}elseif mode=='false_success'then return true elseif mode=='bad_rollback'then native='Wrong';return false,'restore_failed',{rollbackVerified=false}end;native=value;return true,nil,{rollbackVerified=true}end)
 local r={api=api,current=s,live={[a.id]=10,[b.id]=11},ready=function()return true,{token='previous'}end,check=function(_,current,positions,previous)assert(current==s and positions and previous.token=='previous');return true,{}end,accept=function()end,failure=function()end,snapshot=function()return{}end,quarantine=function()locked=true;return false,'locked'end}
 return r,a,b,function()return calls,native,locked end
end
test('32-character limit accepts the boundary and explains rejection without truncation',function()
 assert(M.validNativeName(string.rep('x',32)));local ok,why=M.validNativeName(string.rep('x',33));assert(not ok and why:find('Name too long',1,true)and why:find('33/32 characters',1,true))
end)
test('UTF-8 byte ceiling is separate from Unicode character count',function()
 assert(M.validNativeName(string.rep('ä',23)));assert(not M.validNativeName(string.rep('ä',24)));assert(M.validNativeName(string.rep('軍',15)));assert(not M.validNativeName(string.rep('軍',16)));assert(M.validNativeName('Kläus Ægir Ω'))
end)
test('empty names clear, whitespace/control/invalid UTF-8 and native format characters refuse',function()
 assert(M.validNativeName(''));for _,v in ipairs({'  ','\n',string.char(0),'a%b','a,b',string.char(0xc0,0xaf),utf8.char(0x85),utf8.char(0x202e)})do assert(not M.validNativeName(v))end
end)
test('schema4 retains Unicode, surrounding spaces, independent names and explicit clear with a legacy label',function()
 local s,a,b=scene();a.nativeName=' Sir Kläus ';a.label='old label';b.nativeName='Lady Mara';local t=M.encode(s,{});assert(t.scenario.schema==4 and t.unit1.native_name_hex:match('^20')and t.unit1.native_name_hex:match('20$'))
 local decoded=assert(M.decode(t,c,{}));assert(decoded.units[1].nativeName==a.nativeName and decoded.units[2].nativeName==b.nativeName and decoded.units[1].label==a.label)
 a.nativeName='';decoded=assert(M.decode(M.encode(s,{}),c,{}));assert(decoded.units[1].nativeName==''and decoded.units[1].label=='old label'and M.displayName(decoded.units[1])=='Spearman')
end)
test('copy retains chosen name without aliasing or changing the shared type identity',function()
 local s,a=scene();a.nativeName='Sir Klaus';local b=M.add(s,a.monster,a.name,2,20,7,a);assert(b.id~=a.id and b.nativeName==a.nativeName);b.nativeName='Lady Mara';assert(a.nativeName=='Sir Klaus'and a.name=='Spearman')
end)
test('schemas1-3 and long Sandbox-only labels are readable without native promotion',function()
 for _,schema in ipairs({1,2,3})do local s,a=scene();a.label=string.rep('ä',48);local t=M.encode(s,{});t.scenario.schema=schema;local loaded=assert(M.decode(t,c,{}));assert(loaded.migrationRequired and not loaded.units[1].nativeName and loaded.units[1].label==a.label and M.displayName(loaded.units[1])==a.label)end
end)
test('invalid hex, scope, native version and partial naming coverage are refused',function()
 for _,change in ipairs({function(t)t.unit1.native_name_hex='gg'end,function(t)t.unit1.native_name_hex='1'end,function(t)t.unit1.native_name_scope='fake'end,function(t)t.scenario.native_name_version=2 end,function(t)t.scenario.native_name_count=0 end,function(t)t.unit1.native_name_hex=nil end})do local s,a=scene();a.nativeName='Sir Klaus';local t=M.encode(s,{});change(t);assert(not M.decode(t,c,{}))end
end)
test('missing naming capability refuses reconstruction before closing the existing field',function()
 local s,a=scene();a.nativeName='Sir Klaus';local closes=0;local r=R.new({closeTestField=function()closes=closes+1 end},c);local ok,why=r:build(s);assert(not ok and why:find('naming API',1,true)and closes==0)
end)
test('successful rename verifies native readback and preserves the other actor and saved spells',function()
 local r,a,b,status=fixture();assert(N.set(r,a,'Sir Klaus'));local calls,native,locked=status();assert(calls==1 and native=='Sir Klaus'and a.nativeName=='Sir Klaus'and not b.nativeName and a.baseline.known[1]=='preserved'and not locked)
end)
test('oversized player input never reaches the native setter and retains the previous name',function()
 local r,a,b,status=fixture();local ok,why=N.set(r,a,string.rep('x',33));local calls,native,locked=status();assert(not ok and why:find('33/32 characters',1,true)and calls==0 and native=='Old'and a.nativeName=='Old'and not locked)
end)
test('native refusal retains the previous verified name',function()
 local r,a,b,status=fixture('refuse');assert(not N.set(r,a,'New'));local calls,native,locked=status();assert(calls==1 and native=='Old'and a.nativeName=='Old'and not locked)
end)
test('false success or failed rollback locks instead of accepting an unverified rename',function()
 for _,mode in ipairs({'false_success','bad_rollback'})do local r,a,b,status=fixture(mode);assert(not N.set(r,a,'New'));local calls,native,locked=status();assert(calls==1 and locked and a.nativeName=='Old')end
end)
test('Name tab retains explicit rejection feedback and clears it after a valid edit',function()
 local W=require('sandbox.config_window');local r,a,b,status=fixture();local old=W.target;W.target=function()return a end
 r.setNativeName=R.setNativeName;local ui={runtime=r,textTarget='native_name',editWindow={}}
 assert(W.text(ui,{type='text',text=string.rep('x',33)}));assert(ui.editWindow.nameError:find('Name too long',1,true)and ui.message==ui.editWindow.nameError and a.nativeName=='Old')
 assert(W.text(ui,{type='backspace'}));assert(not ui.editWindow.nameError and a.nativeName=='Ol');W.target=old
end)
test('invalid recorded names refuse before the current native field is closed',function()
 local s,a=scene();a.nativeName=string.rep('x',33);local closed=0
 local api=nativeApi(function()end,function()end);api.closeTestField=function()closed=closed+1 end
 local r=R.new(api,c);local ok,why=r:build(s);assert(not ok and why:find('Name too long',1,true)and closed==0)
end)
print(count..' offline individual-name contracts passed; native Inspect/combat require real-game tests')
