-- Opt-in native open-water acceptance; never loaded by ordinary Sandbox startup.
-- Only advertised production identities (or an explicitly private candidate
-- wrapper) may reach native setup. No ship/passenger contract is simulated.
local api=coe5;local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime')
local D=require('sandbox.diagnostics');local U=require('sandbox.ui');local L=require('sandbox.loadout');local Condition=require('sandbox.condition')
local request=(api.readIni('request')or{}).run or{}
local terrain=tonumber(request.terrain or request.only)or 27;local minimum=tonumber(request.minimum)or 50
local fixtures={[27]={name='Sea',ground=11},[68]={name='Deep Sea',ground=12}}
local result={environment=api.readIni('launcher-context').environment,request={terrain=terrain,minimum=minimum}}
local started,fighting,r,s=false,false,nil,nil;local steps={};local movements,drowning=0,0;local watch,turnUnit,damageBefore
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function ini(v)if type(v)=='boolean'then return v and 1 or 0 end;if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=ini(x)end;return t end
local function world()
 local t={};for _,k in ipairs({'worldW','worldH','activePlayer','battleDelay','planeLastIndex','battleAtSea'})do t[k]=tostring(api.get(k))end
 for x=0,2 do for y=0,2 do for _,k in ipairs({'squareTerrain','squareGround','squareTemperature','squareArmy','squareOwner','squareArmyOwner','squarePlane'})do t[k..x..'_'..y]=tostring(api.get(k,x,y))end end end
 for _,k in ipairs({'planeX','planeY','planeWidth','planeHeight'})do t[k]=tostring(api.get(k,0))end;return t
end
local function healthy()
 local ok,why=r:ready(s);assert(ok,why);local state=assert(api.testFieldState());assert(state.complete and #state.issues==0)
 local env=assert(api.testFieldEnvironmentState());assert(env.atSea and env.boatCountA==0 and env.boatCountB==0)
 for _,row in ipairs(state.units)do assert(row.kind=='actor'and row.provenanceVerified and row.anchorCount==1)end
 return state
end
local function at(id)for _,u in ipairs(s.units)do if u.id==id then return u end end;error('Missing model identity')end
local function vacant(w,h)
 for x=1,r.width-w-1 do for y=1,19-h do local clear=true
  for dx=0,w-1 do for dy=0,h-1 do if api.battleUnitAt(x+dx,y+dy)>=0 or api.battleObjectAt(x+dx,y+dy)>=0 then clear=false end end end
  if clear then return x,y end
 end end;error('No free native footprint')
end
api.observe('BATTLE_ADVANCE_UNIT',function(u)if fighting then steps[u]={api.get('unitBattleX',u),api.get('unitBattleY',u)}end end,function(_,u)
 local p=steps[u];if fighting and p and(p[1]~=api.get('unitBattleX',u)or p[2]~=api.get('unitBattleY',u))then movements=movements+1 end;steps[u]=nil
end)
api.observe('BATTLE_TURN_EFFECTS',function(u)if fighting then turnUnit=u end end,function()turnUnit=nil end)
api.observe('DAMAGE_UNIT',function(u,amount)
 if fighting and u==watch and turnUnit==u and amount==1 then damageBefore=api.get('unitHp',u)end
end,function(_,u)
 if fighting and u==watch and damageBefore then if damageBefore-(api.get('unitHp',u)or 0)==1 then drowning=drowning+1 end;damageBefore=nil end
end)
api.wrap('BATTLE_WAIT',function(next,...)local v=next(...);if fighting and v==0 and(api.get('battleDelay')or 0)>2 then return 1 end;return v end)
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local v=next(...);if started then return v end;started=true
 local c=C.read(api);local f=fixtures[terrain]
 if not f or M.terrainNames[terrain]~=f.name or not c.testFieldTerrains[terrain]or not M.terrainCapabilityAvailable(api,terrain)then
  result.complete={status='BLOCKED',detail='Requires separately accepted native open-water identity and water API.'};assert(api.writeIni('results',ini(result)));return v
 end
 local before=world();api.set('traceLevel',1);api.keepTraceLines({'bt','bfsize','damagefromdrowning','willdrown'})
 local ok,why=xpcall(function()
  assert(minimum==32 or minimum==50 or minimum==70 or minimum==160,'Untested requested minimum')
  for id,name in pairs({[731]='Deep One',[732]='Deep One Warrior',[685]='Triton',[1031]='Kappa Shaman',[13]='Spearman',[118]='Ship'})do assert(c.byId[id]and c.byId[id].name==name,'Fixture identity changed: '..name)end
  local high=api.get('unitLastIndex');local opened,reason=api.openTestField{emptyEditor=true,terrain=terrain,friends={{118,1}}}
  assert(not opened and reason=='water_transport_unavailable'and api.get('unitLastIndex')==high and equal(world(),before),'Ship request changed the unopened field')
  s=M.new();s.terrain=terrain;s.minimumWidth=minimum;s.size='Minimum width';r=R.new(api,c,D.new(api));assert(r:build(s,true));healthy()
  local env=assert(api.testFieldEnvironmentState());assert(env.terrain==terrain and env.plane==0 and env.temperature==25 and env.ground==f.ground and env.nativeTemplate==''and env.nativeTemplateObserved and env.setupReturned and not env.customMapReplaced and not env.siege and not env.tower and not env.underground and env.fortParts==0 and env.width>=minimum)
  local state=healthy();for _,cell in ipairs(state.grid)do assert(cell.ground==f.ground and cell.object<0)end;result.context=env
  local frozenState=api.testFieldState();local made,reason=api.addTestFieldUnits('friends',{{118,1}});assert(not made and reason=='water_transport_unavailable'and equal(frozenState,api.testFieldState()))
  result.transport={raw_open_refused=1,raw_add_refused=1,field_unchanged=1,scope='Independent actors only; no ships, boat composites or passenger state'}
  for _,team in ipairs({1,2})do
   local added,new,u=r:add(s,731,team,team==1 and 8 or r.width-8,8);assert(added,new);s=new;healthy()
   local file='water-one-'..team..'-'..result.environment.session:sub(1,10);assert(api.writeIni(file,M.encode(s,c.mods)));local loaded=assert(M.decode(api.readIni(file),c,c.mods));assert(r:build(loaded,false));s=loaded;healthy()
   local fight,reason=api.fightTestField();assert(fight==false and reason==(team==1 and'missing_team_b'or'missing_team_a'))
   local removed,new=r:remove(s,s.units[1]);assert(removed,new);s=new;healthy()
  end
  local emptyFile='water-empty-'..result.environment.session:sub(1,10);assert(api.writeIni(emptyFile,M.encode(s,c.mods)));local loaded=assert(M.decode(api.readIni(emptyFile),c,c.mods));assert(r:build(loaded,false));s=loaded;healthy()
  result.empty={empty_save_load=1,one_sided_save_load=2,missing_side_refused=2}
  assert(r:close());r=nil
  s=M.new();s.terrain=terrain;s.minimumWidth=minimum;s.size='Minimum width'
  for i=1,6 do M.add(s,732,'Deep One Warrior',1,6,i*2)end
  local caster=M.add(s,1031,'Kappa Shaman',1,5,17)
  for i=1,4 do M.add(s,685,'Triton',2,24,i*2)end
  r=R.new(api,c,D.new(api));local opened,reason=r:build(s,true);assert(opened,reason);healthy()
  local a=s.units[1];assert(r:setNativeName(a,'Sea Guard'));assert(r:setNativeName(caster,'Tide Sage'))
  local loadout=assert(L.read(r,r.live[caster.id]));assert(#loadout.schools>0,'Aquatic caster has no school');assert(loadout.schools[1].base<3);assert(L.raise(r,caster,loadout.schools[1].path));assert(api.giveItem(r.live[caster.id],'Amulet of Anti Magic'));assert(L.capture(r,caster,assert(L.read(r,r.live[caster.id]))))
  local condition=Condition.save(assert(Condition.read(r,r.live[a.id])));condition.hp=math.max(1,condition.hp-1);condition.xp=3;condition.kills=1;assert(Condition.restore(r,a,r.live[a.id],condition));healthy()
  for _,u in ipairs(s.units)do local row=assert(api.testFieldWaterState(r.live[u.id],u.x,u.y));assert(row.cellWater and row.waterMobile and not row.willDrown and not row.ship)end
  local id=r.live[a.id];local x,y=vacant(1,1);assert(r:move(a,x,y));assert(r.live[a.id]==id and api.testFieldUnitName(id).name=='Sea Guard');healthy()
  local expectedCaster=M.copy(caster);local old=M.copy(s);local rejected,reason=r:add(s,731,2,a.x,a.y);assert(not rejected and equal(s,old));healthy()
  for i=1,3 do assert(not r:add(s,731,2,a.x,a.y));healthy()end
  result.rejection={diagnostic=assert(r.diag:export({fixture='intentionally rejected water actor overlap',terrain=terrain},r:snapshot(s))),retries=3}
  x,y=vacant(1,1);local copied,new,copy=r:add(s,a.monster,2,x,y,a);assert(copied,new);s=new;assert(copy.nativeName=='Sea Guard');assert(r:setNativeName(copy,'Other Tide'));a=at(a.id);caster=at(caster.id);assert(equal(caster,expectedCaster));healthy()
  local large
  for _,name in ipairs({'Kraken','Giant Crocodile','Crocodile'})do local monster=api.findMonster(name);if monster and monster>=0 and api.get('monsterName',monster)==name then local fp=api.testFieldFootprint(monster);if fp and fp.width*fp.height>1 and not M.waterMonsterProblem(api,terrain,monster)and api.get('monsterMoveFlags',monster)&64~=0 then large={monster=monster,name=name,fp=fp};break end end end
  assert(large,'No native aquatic multi-cell actor');local unchanged=M.copy(s.units);x,y=vacant(large.fp.width,large.fp.height)
  local added,new,u=r:add(s,large.monster,1,x,y);assert(added,new);s=new;healthy();local native=r.live[u.id];local row=api.testFieldUnitState(native);assert(#row.occupied==large.fp.width*large.fp.height)
  for dx=0,large.fp.width-1 do for dy=0,large.fp.height-1 do assert(api.battleUnitAt(x+dx,y+dy)==native)end end
  local removed,new=r:remove(s,u);assert(removed,new);s=new;healthy();assert(r:retirementVerified(native));local reused,new,u=r:add(s,731,2,x,y);assert(reused,new);s=new;local removed,new=r:remove(s,u);assert(removed,new);s=new;healthy();assert(equal(s.units,unchanged))
  result.large={monster=large.monster,name=large.name,width=large.fp.width,height=large.fp.height,delete_reuse=1}
  -- A separate independent land actor deliberately demonstrates native hazard
  -- damage; no damage/position/movement wrapper changes the simulation.
  x,y=vacant(1,1);local added,new,hazard=r:add(s,13,1,x,y);assert(added,new);s=new;healthy();assert(r.lastPlacementWarning and r.lastPlacementWarning:find('drown',1,true))
  local wet=assert(api.testFieldWaterState(r.live[hazard.id],x,y));assert(wet.cellWater and wet.willDrown and not wet.waterMobile)
  for _,p in ipairs({{-1,0},{r.width,0},{0,20}})do local rejected,reason=api.testFieldWaterState(r.live[a.id],p[1],p[2]);assert(not rejected and reason=='bad_anchor')end
  local file='water-'..terrain..'-'..minimum..'-'..result.environment.session:sub(1,12);assert(api.writeIni(file,M.encode(s,c.mods)));local loaded,reason=M.decode(api.readIni(file),c,c.mods);assert(loaded,reason);assert(r:build(loaded,false));s=loaded;healthy();local frozen=M.copy(s)
  local ui=U.new(api);ui.catalog=c;ui.runtime=r;ui.scenario=s;ui.diag=r.diag
  -- Controlled, reversible invalid native-context refusal through the real UI.
  api.set('battleAtSea',false);local refused=ui:fight();api.set('battleAtSea',true)
  assert(not refused and ui.phase=='prepare'and not ui.report.result and equal(s,frozen));ui.noticeText=nil;healthy();result.refused_battle={native_context_mismatch=1,no_final_report=1,setup_preserved=1}
  for cycle=1,2 do
   watch=r.live[hazard.id];turnUnit=nil;damageBefore=nil;fighting=true;assert(ui:fight());fighting=false
   local final=assert(api.testFieldFinalState());assert(final.complete and require('sandbox.final_view').prepare(final).complete)
   result['battle'..cycle]={round=api.get('battleRound'),winner=api.get('battleWinner'),movement_events=movements};assert(api.get('battleRound')>0)
   assert(ui:reset(cycle==1));s=ui.scenario;healthy();assert(equal(M.encode(s,c.mods),M.encode(frozen,c.mods)))
  end
  assert(movements>0 and drowning>0);result.native_damage={one_hp_turn_effect_losses=drowning,scope='Observed native one-HP turn-effect damage on a preclassified drowning actor; no general damage-source API'}
  assert(ui:dispatch('clear'));s=ui.scenario;healthy();assert(#s.units==0);local finalEmpty=file..'-clear';assert(api.writeIni(finalEmpty,M.encode(s,c.mods)));local loaded=assert(M.decode(api.readIni(finalEmpty),c,c.mods));assert(r:build(loaded,false));s=loaded;healthy()
  local added,new,u=r:add(s,731,2,r.width-8,8);assert(added,new);s=new;healthy();local removed,new=r:remove(s,u);assert(removed,new);s=new;healthy()
  assert(r:close());r=nil;local life=assert(api.testFieldLifecycle());assert(life.complete and #life.issues==0 and not life.open);assert(equal(world(),before))
  result.workflow={file=file,names_items_magic_condition_preserved=1,clear_empty_save_load=1,add_after_clear=1,world_readback_unchanged=1,cleanup_verified=1}
 end,tostring)
 fighting=false
 if not ok and r then result.diagnostic={name=r.diag:export({fixture='native independent-actor water acceptance',error=tostring(why)},r:snapshot(r.current or s))or'unavailable'}end
 if r then local called,closed,detail=pcall(function()return r:close()end);if not called or not closed then ok=false;why=tostring(why)..';cleanup:'..tostring(detail or closed)end end
 result.complete={status=ok and'PASS'or'FAIL',detail=ok and'Native independent-actor water context; two natural battles, exact restoration and verified cleanup'or tostring(why)};assert(api.writeIni('results',ini(result)));api.set('traceLevel',0);return v
end,-100)
