-- Explicit isolated native acceptance; never run during a campaign or ordinary BAT launch.
local api=coe5;local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local L=require('sandbox.loadout');local Condition=require('sandbox.condition');local D=require('sandbox.diagnostics');local U=require('sandbox.ui');local B=require('sandbox.battlefields')
local started,active,fighting=false,nil,false;local out={environment=api.readIni('launcher-context').environment}
local function save()assert(api.writeIni('results',out))end
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function healthy(r,s)local ok,why=r:ready(s);assert(ok,tostring(why));local state=assert(api.testFieldState());assert(state.complete and #state.issues==0);return state end
local function at(s,id)for _,u in ipairs(s.units)do if u.id==id then return u end end end
local function open(c,s,native)local r=R.new(api,c,D.new(api));active=r;local ok,why=r:build(s,native~=false);if not ok then
 local e=r.diag.lastError;local detail=type(e)=='table'and(e.message or e.reason or tostring(e))or tostring(e);local name=r.diag:export({fixture='open failure',reason=tostring(why),detail=tostring(detail)},r:snapshot(s));error(tostring(why)..' | '..tostring(detail)..' | '..tostring(name))
 end;healthy(r,s);return r end
local function free(r,w,h)
 for x=1,r.width-w-1 do for y=1,19-h do local clear=true
  for dx=0,w-1 do for dy=0,h-1 do if api.battleUnitAt(x+dx,y+dy)>=0 or api.battleObjectAt(x+dx,y+dy)>=0 then clear=false end end end
  if clear then return x,y end
 end end;error('No native empty footprint available')
end
local function test(name,fn)
 local ok,why=xpcall(fn,tostring);local clean,detail=true
 if active then clean,detail=active:close();active=nil end
 out[name]={status=ok and clean~=false and'PASS'or'FAIL',detail=not clean and('cleanup: '..tostring(detail))or ok and'Actual production Lua + native calls/readback'or why};save();assert(clean~=false,'Cleanup unverified; stop suite')
end
api.wrap('BATTLE_WAIT',function(next,...)local id=next(...);if fighting and id==0 and(api.get('battleDelay')or 0)>2 then return 1 end;return id end)
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local menu=next(...);if started then return menu end;started=true;local c=C.read(api)
 test('verified_neutral_presets_and_size_changes_keep_supported_state',function()
  assert(c.testFieldTerrains[115]and c.environment.minimumWidthVersion==1)
  for _,terrain in ipairs({0,2,12,107,115,117})do
   local s=M.new();s.terrain=terrain;M.add(s,594,"Druid's Apprentice",1,8,9);M.add(s,953,'Goblin',2,18,9);assert(B.selectSize(c,s,B.sizes[3]));local r=open(c,s)
   assert(r.width==50 and api.get('squareTerrain',1,1)==terrain);local before=M.copy(s);assert(B.selectSize(c,s,B.sizes[4]));local requested=M.copy(s);local rebuilt,why=r:build(s,false)
   if not rebuilt then
    assert(r.open and r.width==50,'A rejected exact-position resize failed to restore the previous field');healthy(r,r.current)
    assert(same(M.encode(r.current,c.mods),M.encode(before,c.mods)))
    s=requested;assert(r:build(s,true));healthy(r,s)
    out['resize_'..terrain]={exact='refused; previous field verified',explicit_native_deployment='accepted'}
   else healthy(r,s);out['resize_'..terrain]={exact='accepted'}end
   assert(r.width==70)
   for i,u in ipairs(s.units)do assert(u.id==before.units[i].id and same(u.condition,before.units[i].condition)and same(u.baseline,before.units[i].baseline)and same(u.spells,before.units[i].spells)and same(u.equipment,before.units[i].equipment))end
   assert(r:close());active=nil
  end
 end)
 test('starting_items_normal_cursed_formation_and_saved_copies',function()
  local normal=assert(api.findMonster('Sandbox Normal Starting Kit QA'));local cursed=assert(api.findMonster('Sandbox Cursed Starting Kit QA'));local caster=assert(api.findMonster('Sandbox Caster Starting Kit QA'))
  assert(c.byId[normal]and c.byId[cursed]and c.byId[caster]);local s=M.new();local initial=M.add(s,normal,c.byId[normal].name,1,8,9);M.add(s,953,'Goblin',2,18,9);local r=open(c,s);assert(#initial.equipment>0,'Native startitem fixture did not initialize equipment')
  local original=M.copy(initial);s.startingItems=false
  for _,monster in ipairs({normal,cursed,caster})do
   local x,y=free(r,1,1);local spells;local nativeAdd=r.api.addTestFieldUnits
   local proxy=setmetatable({addTestFieldUnits=function(...)local units,why=api.addTestFieldUnits(...);if units then spells=assert(api.testFieldSpellState(units[1]))end;return units,why end},{__index=api});r.api=proxy
   local ok,new,u=r:add(s,monster,1,x,y);r.api=api
   if ok then s=new;assert(#u.equipment==0 and #u.items==0);local actual=assert(api.testFieldSpellState(r.live[u.id]));assert(same(actual.known,spells.known)and same(actual.memorized,spells.memorized));healthy(r,s)
   else assert(monster==caster,'Ordinary/cursed nonimplant omission failed: '..tostring(new));healthy(r,s);out.caster_omission={result='refused unchanged',detail=tostring(new)}end
  end
  assert(same(at(s,original.id),original),'Existing starting equipment/configuration changed')
  for _,cell in ipairs(M.cells('Horizontal Row',3,2,15))do local ok,new,u=r:add(s,normal,2,cell[1],cell[2]);assert(ok,new);s=new;assert(#u.equipment==0)end
  local x,y=free(r,1,1);local ok,new,copy=r:add(s,normal,2,x,y,at(s,original.id));assert(ok,new);s=new;assert(#copy.equipment==#original.equipment and same(copy.equipment,original.equipment)and same(copy.condition,original.condition))
  local encoded=M.encode(s,c.mods);local loaded,why=M.decode(encoded,c,c.mods);assert(loaded,why);assert(r:build(loaded,false));s=loaded;healthy(r,s);assert(#at(s,original.id).equipment>0 and #at(s,copy.id).equipment>0)
 end)
 test('implanted_starting_equipment_refuses_without_ghost_or_old_state_change',function()
  local id=assert(api.findMonster('Sandbox Implanted Starting Kit QA'));assert(c.byId[id]);local s=M.new();M.add(s,594,"Druid's Apprentice",1,8,9);M.add(s,953,'Goblin',2,18,9);local r=open(c,s);s.startingItems=false;local before=M.copy(s);local x,y=free(r,3,3)
  local ok,why=r:add(s,id,1,x,y);assert(not ok,'Implant omission was silently accepted');assert(same(s,before));healthy(r,s);assert(#api.testFieldState().units==2)
  local name=r.diag:export({fixture='intentional implanted starting-item refusal',omission='refused, original native state preserved'},r:snapshot(s));assert(name);out.implant_refusal={message=tostring(why),diagnostic=name}
  local added,new=r:add(s,13,1,x,y);assert(added,new);s=new;healthy(r,s)
 end)
 test('restoration_health_injury_identity_spells_items_battle_reset_rematch',function()
  local s=M.new();s.terrain=0;s.allowMultipleUnique=true;assert(B.selectSize(c,s,B.sizes[4]));local druid=M.add(s,594,"Druid's Apprentice",1,8,9);local dragon=M.add(s,1830,'Arcane Frost Dragon',1,3,2);M.add(s,201,'Apocalyptic Rider',2,22,9);M.add(s,201,'Apocalyptic Rider',2,22,3)
  local r=open(c,s);assert(L.raise(r,druid,39));local unit=r.live[dragon.id];assert(api.giveItem(unit,'Crystal Heart'));L.capture(r,dragon,assert(L.read(r,unit)));local good,obs=r:check(s);assert(good,obs);r:accept(s,obs)
  local pos;for _,slot in ipairs(L.read(r,unit).items)do if slot.name=='Crystal Heart'then pos=slot.position end end;assert(pos);assert(L.equip(r,dragon,pos,nil,185));assert(dragon.condition.injuryFlags&0x400000~=0)
  unit=r.live[druid.id];api.set('unitHp',unit,math.max(1,api.get('unitHp',unit)-1));api.set('unitXp',unit,150);api.set('unitKills',unit,3);assert(Condition.capture(r,druid,unit));local good,obs=r:check(s);assert(good,obs);r:accept(s,obs)
  local expected=M.copy(druid);local x,y=free(r,1,1);assert(r:move(druid,x,y));expected.x,expected.y=x,y;s.startingItems=false
  x,y=free(r,1,1);local ok,new,copy=r:add(s,594,2,x,y,druid);assert(ok,new);s=new;assert(same(copy.condition,expected.condition)and same(copy.baseline,expected.baseline)and same(copy.spells,expected.spells));healthy(r,s)
  local target=at(s,3);local oldNative=r.live[target.id];local ax,ay=target.x,target.y;local removed,new=r:remove(s,target);assert(removed,new);s=type(new)=='table'and new.units and new or r.current;assert(not at(s,3));assert(api.battleUnitAt(ax,ay)~=oldNative)
  local added,new=r:add(s,13,1,ax,ay);assert(added,new);s=new;healthy(r,s)
  local name='release-next-'..out.environment.session:sub(1,16)..'-saved';assert(api.writeIni(name,M.encode(s,c.mods)));local loaded,why=M.decode(api.readIni(name),c,c.mods);assert(loaded,why);assert(loaded.units[1].id==s.units[1].id and loaded.nextId==s.nextId and not at(loaded,3));assert(r:build(loaded,false));s=loaded;healthy(r,s)
  local frozen=M.copy(s);for _,u in ipairs(s.units)do assert(Condition.matches(r,u,r.live[u.id]))end;assert(at(s,dragon.id).condition.injuryFlags&0x400000~=0)
  local ui=U.new(api);ui.catalog=c;ui.runtime=r;ui.scenario=s;ui.diag=r.diag
  for cycle=1,2 do fighting=true;assert(ui:fight());fighting=false;assert(api.get('battleRound')>0);assert(ui:reset(cycle==1));s=ui.scenario;healthy(r,s);assert(same(M.encode(s,c.mods),M.encode(frozen,c.mods)))end
  local bad=M.copy(s);bad.units[1].condition.maxHp=bad.units[1].condition.maxHp+1;local ok,why=r:build(bad,false);assert(not ok,'Unverifiable actor restoration was reported as success');s=r.current;healthy(r,s);assert(same(M.encode(s,c.mods),M.encode(frozen,c.mods)))
  out.restoration={model_id=expected.id,hp=expected.condition.hp,xp=expected.condition.xp,kills=expected.condition.kills,injury_flags=at(s,dragon.id).condition.injuryFlags,scope='supported bounded subset, not complete native state',failed_restore=tostring(why),saved=name}
 end)
 local passed=true;for _,row in pairs(out)do if type(row)=='table'and row.status=='FAIL'then passed=false end end;out.complete={status=passed and'PASS'or'FAIL',scope='Native editor9 production integration; explicit QA fixture and incomplete state scope'};save();return menu
end,-100)
