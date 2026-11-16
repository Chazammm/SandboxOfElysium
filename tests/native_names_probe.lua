-- Explicit isolated native acceptance. Never enabled by an ordinary Sandbox launch.
local api=coe5;local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local D=require('sandbox.diagnostics');local L=require('sandbox.loadout');local U=require('sandbox.ui')
local started,fighting=false,false;local out={environment=api.readIni('launcher-context').environment};local active
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function save()assert(api.writeIni('results',out))end
local function healthy(r,s)local ok,why=r:ready(s);assert(ok,why);local state=assert(api.testFieldState());assert(state.complete and #state.issues==0);return state end
local function free(r,unit)for x=8,r.width-2 do for y=3,17 do if api.battleUnitAt(x,y)<0 and api.battleObjectAt(x,y)<0 and api.battleCanStand(unit,x,y,0)then return x,y end end end;error('No native free cell')end
local function test(name,fn)local ok,why=xpcall(fn,tostring);local clean,detail=true;if active then clean,detail=active:close();active=nil end;out[name]={status=ok and clean~=false and'PASS'or'FAIL',detail=clean==false and tostring(detail)or ok and'Production Lua with actual native naming, configuration and battles'or why};save()end
api.wrap('BATTLE_WAIT',function(next,...)local value=next(...);if fighting and value==0 and(api.get('battleDelay')or 0)>2 then return 1 end;return value end)
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local v=next(...);if started then return v end;started=true;local c=C.read(api);api.set('traceLevel',1);assert(api.keepTraceLines({'bt','showstats'}))
 test('individual_names_move_copy_unicode_limits_save_load_reset_rematch',function()
  local s=M.new();local a=M.add(s,13,'Spearman',1,8,9);local b=M.add(s,13,'Spearman',1,8,11);local caster=M.add(s,594,"Druid's Apprentice",1,6,5);M.add(s,953,'Goblin',2,18,9);M.add(s,953,'Goblin',2,18,11)
  local r=R.new(api,c,D.new(api));active=r;assert(r:build(s,true));healthy(r,s);local before=M.copy(s);local template=api.get('monsterName',13)
  assert(r:setNativeName(a,'Sir Klaus'));assert(r:setNativeName(b,'Lady Mara'));assert(r:setNativeName(caster,'Oak Sage'));assert(api.get('monsterName',13)==template)
  assert(api.testFieldUnitName(r.live[a.id]).shown=='Sir Klaus'and api.testFieldUnitName(r.live[b.id]).shown=='Lady Mara')
  for i,u in ipairs(s.units)do assert(same(u.condition,before.units[i].condition)and same(u.baseline,before.units[i].baseline)and same(u.spells,before.units[i].spells)and same(u.equipment,before.units[i].equipment))end
  local x,y=free(r,r.live[a.id]);assert(r:move(a,x,y));assert(api.testFieldUnitName(r.live[a.id]).name=='Sir Klaus')
  x,y=free(r,r.live[a.id]);local ok,new,copy=r:add(s,a.monster,2,x,y,a);assert(ok,new);s=new;for _,u in ipairs(s.units)do if u.id==a.id then a=u elseif u.id==b.id then b=u elseif u.id==caster.id then caster=u end end;assert(copy.nativeName=='Sir Klaus'and copy.id~=a.id and r.live[copy.id]~=r.live[a.id]);assert(api.testFieldUnitName(r.live[copy.id]).name=='Sir Klaus');assert(r:setNativeName(copy,'Klaus Junior'))
  local rejected,why=r:setNativeName(a,string.rep('x',33));assert(not rejected and why:find('33/32 characters',1,true));assert(a.nativeName=='Sir Klaus'and api.testFieldUnitName(r.live[a.id]).name=='Sir Klaus')
  assert(r:setNativeName(a,string.rep('L',32)));assert(api.testFieldUnitName(r.live[a.id]).shown==string.rep('L',32));assert(r:setNativeName(a,' Kläus Ægir Ω '))
  local name='native-names-'..out.environment.session:sub(1,16);assert(api.writeIni(name,M.encode(s,c.mods)));local loaded,reason=M.decode(api.readIni(name),c,c.mods);assert(loaded,reason);assert(loaded.units[1].nativeName==' Kläus Ægir Ω ');assert(r:build(loaded,false));s=loaded;a=s.units[1];b=s.units[2];caster=s.units[3];healthy(r,s);assert(api.testFieldUnitName(r.live[a.id]).shown==' Kläus Ægir Ω ');assert(r.diag:export({fixture='native Unicode naming with outer spaces'},r:snapshot(s)))
  assert(r:setLabel(a,'Old Banner'));assert(r:setNativeName(a,''));assert(M.displayName(a)=='Spearman'and a.label=='Old Banner'and api.testFieldUnitName(r.live[a.id]).shown=='Spearman')
  local cleared=M.encode(s,c.mods);assert(api.writeIni(name..'-clear',cleared));assert(M.decode(api.readIni(name..'-clear'),c,c.mods).units[1].nativeName=='')
  assert(r:setNativeName(a,'Sir Klaus'));assert(r:setNativeName(b,' Lady Mara '));local frozen=M.copy(s);local ui=U.new(api);ui.catalog=c;ui.runtime=r;ui.scenario=s;ui.diag=r.diag
  for cycle=1,2 do fighting=true;assert(ui:fight());fighting=false;assert(api.get('battleRound')>0);assert(ui.report.result.unit1.native_name=='Sir Klaus'and ui.report.result.unit2.native_name=='[ Lady Mara ]'and ui.report.result.unit2.native_name_hex=='204c616479204d61726120');assert(ui.report.result.unit1.display_name=='Sir Klaus')
   local report=assert(ui.report:archive());out['fight'..cycle]={round=api.get('battleRound'),winner=api.get('battleWinner'),report=report};assert(ui:reset(cycle==1));s=ui.scenario;healthy(r,s);assert(same(M.encode(s,c.mods),M.encode(frozen,c.mods)));for _,u in ipairs(s.units)do if u.nativeName and u.nativeName~=''then assert(api.testFieldUnitName(r.live[u.id]).name==u.nativeName)end end
  end
  out.workflow={file=name,schema=4,native_name='Sir Klaus',copy_initial_name='Sir Klaus',copy_after_rename='Klaus Junior',unicode_saved='hex:204b6cc3a4757320c38667697220cea920',long_characters=32,excess_rejection=why,spells_items_hp_unchanged=1}
 end)
 test('named_deletion_reuses_vacated_cell_without_name_leak_or_caster_change',function()
  local s=M.new();local a=M.add(s,13,'Spearman',1,8,9);local caster=M.add(s,594,"Druid's Apprentice",1,6,5);M.add(s,953,'Goblin',2,18,9)
  local r=R.new(api,c,D.new(api));active=r;assert(r:build(s,true));assert(r:setNativeName(a,'Delete Me'));assert(r:setNativeName(caster,'Keep My Spells'));local expected=M.copy(caster);local unit=r.live[a.id];local ax,ay=a.x,a.y
  local ok,new=r:remove(s,a);assert(ok,new);s=new;assert(not r.live[a.id]and api.battleUnitAt(ax,ay)~=unit);local changed,reason,detail=api.setTestFieldUnitName(unit,'Retired actor');assert(not changed and detail.rollbackVerified)
  local added,new,placed=r:add(s,13,2,ax,ay);assert(added,new);s=new;healthy(r,s);local info=assert(api.testFieldUnitName(r.live[placed.id]));assert(not info.custom and info.shown=='Spearman'and placed.nativeName==nil)
  for _,u in ipairs(s.units)do if u.id==caster.id then assert(same(u,expected));assert(api.testFieldUnitName(r.live[u.id]).name=='Keep My Spells')end end
  out.named_deletion={retired=unit,replacement=r.live[placed.id],replacement_custom=0,refused_dead_rename=tostring(reason),scope='Vacated cell reused; actual allocation ID may differ; no name inherited'}
 end)
 test('existing_schema3_and_sandbox_only_labels_remain_separate',function()
  local s=M.new();local a=M.add(s,13,'Spearman',1,8,9);M.add(s,953,'Goblin',2,18,9);a.label='Legacy Banner';local data=M.encode(s,c.mods);data.scenario.schema=3
  local legacy,why=M.decode(data,c,c.mods);assert(legacy,why);assert(legacy.migrationRequired and legacy.units[1].label=='Legacy Banner'and legacy.units[1].nativeName==nil)
  local r=R.new(api,c,D.new(api));active=r;assert(r:build(legacy,true));healthy(r,legacy);assert(api.testFieldUnitName(r.live[legacy.units[1].id]).shown=='Spearman');assert(M.displayName(legacy.units[1])=='Legacy Banner')
  assert(r:setNativeName(legacy.units[1],legacy.units[1].label));assert(api.testFieldUnitName(r.live[legacy.units[1].id]).shown=='Legacy Banner');assert(legacy.units[1].label=='Legacy Banner')
  out.legacy={scope='Explicit promotion only; no automatic native rename',original_schema=3,label='Legacy Banner'}
 end)
 api.set('traceLevel',0);local passed=true;for _,row in pairs(out)do if type(row)=='table'and row.status=='FAIL'then passed=false end end;out.complete={status=passed and'PASS'or'FAIL'};save();return v
end,-100)
