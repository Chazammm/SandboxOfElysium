-- Opt-in isolated acceptance for each supported siege; not ordinary startup.
-- Battles use native simulation to completion; WAIT fast-forward skips display delays only.
local api=coe5;local M=require('sandbox.model')
local L=require('sandbox.loadout');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local D=require('sandbox.diagnostics');local U=require('sandbox.ui')
local terrain,minimum=((api.readIni('request').run or{}).only or'20'):match('^(%d+),?(%d*)$');terrain=tonumber(terrain)or 20;minimum=tonumber(minimum)or 50
local fixtures={[1]={'palisaden',1546,false},[20]={'stonetower',1548,true},[72]={'woodentower',1549,true},[22]={'greatwall',2821,false},[23]={'citadel',2568,false},[17]={'town',1574,false},[9]={'city',1831,false}};local expected=assert(fixtures[terrain],'No accepted siege fixture')

local result={environment=api.readIni('launcher-context').environment};local started,fighting=false,false;local r,s;local gates={};local hits={};local damage,broken,moves=0,0,0;local steps={}
local function ini(v)if type(v)=='boolean'then return v and 1 or 0 end;if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=ini(x)end;return t end
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function healthy()local ok,why=r:ready(s);assert(ok,why);local state=assert(api.testFieldState());assert(state.complete and #state.issues==0);return state end
local function scanGates(state)
 gates={};local count,walls=0,0
 for _,row in ipairs(state.units)do if row.kind=='structure'then
  assert(row.creationSource=='native_gate_replacement' and row.provenanceVerified and row.anchorLayer=='unit')
  gates[row.unit]={monster=row.monster,hp=row.hp,x=row.anchorX,y=row.anchorY};count=count+1
 end end
 for _,cell in ipairs(state.grid)do if cell.flags~=0 then walls=walls+1 end end
 assert(count>0,'No constructor-proven native structure');assert(walls>0,'No native wall/ground flags');return count,walls
end
api.observe('DAMAGE_UNIT',function(unit)if fighting and gates[unit]then hits[unit]=api.get('unitHp',unit)end end,function(_,unit)if fighting and hits[unit]then local after=api.get('unitHp',unit);local lost=math.max(0,hits[unit]-math.max(0,after or 0));damage=damage+lost;if hits[unit]>0 and after and after<=0 then broken=broken+1 end;hits[unit]=nil end end)
api.observe('BATTLE_ADVANCE_UNIT',function(unit)if fighting then steps[unit]={x=api.get('unitBattleX',unit),y=api.get('unitBattleY',unit)}end end,function(_,unit)local b=steps[unit];if fighting and b and(b.x~=api.get('unitBattleX',unit)or b.y~=api.get('unitBattleY',unit))then moves=moves+1 end;steps[unit]=nil end)
api.wrap('BATTLE_WAIT',function(next,...)local v=next(...);if fighting and v==0 and(api.get('battleDelay')or 0)>2 then return 1 end;return v end)
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local value=next(...);if started then return value end;started=true;api.set('traceLevel',1);api.keepTraceLines({'bt','bfsize','fs '})
 local ok,why=xpcall(function()
  local c=C.read(api);assert(c.testFieldTerrains[terrain]and M.isSiegeTerrain(terrain));assert(api.testFieldEnvironmentInfo().towerContextVersion==1)
  local function vacant(unit,w,h)
   for x=0,r.width-w do for y=0,20-h do local clear=true
    for dx=0,w-1 do for dy=0,h-1 do if api.battleUnitAt(x+dx,y+dy)>=0 or api.battleObjectAt(x+dx,y+dy)>=0 then clear=false end end end
    if clear and api.battleCanStand(unit,x,y,0)then return x,y end
   end end;error('No native free footprint')
  end
  local function emptySideCell(team)
   local lo=team==1 and 1 or math.floor(r.width/2);local hi=team==1 and math.floor(r.width/2)-1 or r.width-2
   for x=lo,hi do for y=1,18 do if api.battleUnitAt(x,y)<0 and api.battleObjectAt(x,y)<0 then return x,y end end end
   error('No empty native cell on requested side')
  end
  s=M.new();s.terrain=terrain;s.minimumWidth=minimum;s.size='Minimum width';r=R.new(api,c,D.new(api));assert(r:build(s,true));local initial=healthy();scanGates(initial)
  local ok,why=api.fightTestField();assert(not ok and why=='missing_team_a');assert(#s.units==0)
  for _,team in ipairs({1,2})do
   local x,y=emptySideCell(team);local ok,new,u=r:add(s,13,team,x,y);assert(ok,new);s=new;healthy();local emptyFile='fort-one-'..team..'-'..result.environment.session:sub(1,8)
   assert(api.writeIni(emptyFile,M.encode(s,c.mods)));local loaded=assert(M.decode(api.readIni(emptyFile),c,c.mods));assert(r:build(loaded,false));s=loaded;healthy()
   local accepted,reason=api.fightTestField();assert(not accepted and reason==(team==1 and'missing_team_b'or'missing_team_a'))
   local removed,new=r:remove(s,s.units[1]);assert(removed,new);s=new;healthy();assert(#s.units==0)
  end
  local emptyFile='fort-empty-'..result.environment.session:sub(1,8);assert(api.writeIni(emptyFile,M.encode(s,c.mods)));local loaded=assert(M.decode(api.readIni(emptyFile),c,c.mods));assert(r:build(loaded,false));s=loaded;healthy()
  local gate;for _,row in ipairs(api.testFieldState().units)do if row.kind=='structure'then gate=row;break end end;assert(gate)
  local made,new,u=r:add(s,gate.monster,1,8,5);if made then s=new;healthy();local native=r.live[u.id];local row=api.testFieldUnitState(native);assert(row.kind=='actor'and row.creationSource=='owned_actor_creation');local removed,new=r:remove(s,u);assert(removed,new);s=new else assert(not r.blocked);local found=false;for _,row in ipairs(api.testFieldLifecycle().created)do if row.createdMonster==gate.monster and row.createdOwner==0 then assert(row.kind=='actor'and row.creationSource=='owned_actor_creation');found=true end end;assert(found)end
  healthy();assert(r:close());r=nil;result.empty={zero_roster_with_native_structure=1,one_sided_save_load=2,empty_save_load=1,missing_side_refused=3,same_monster_creation_classified_by_provenance=1}
  local ogre=assert(api.findMonster('Ogre'));s=M.new();s.terrain=terrain;s.minimumWidth=minimum;s.size='Minimum width'
  for i=1,6 do M.add(s,ogre,c.byId[ogre].name,1,8,i*2)end;local caster=M.add(s,594,"Druid's Apprentice",1,6,17);for i=1,4 do M.add(s,13,'Spearman',2,24,i*2)end
  r=R.new(api,c,D.new(api));local opened,reason=r:build(s,true);assert(opened,reason);local state=healthy();local env=assert(api.testFieldEnvironmentState());result.context=env;assert(env.nativeTemplate==expected[1]and env.siege and not env.atSea and not env.underground and env.fortParts==expected[2] and env.plane==0 and env.temperature==25 and env.tower==expected[3])
  assert(api.testFieldEnvironmentInfo().towerContextVersion==1 and env.tower==(terrain==20 or terrain==72));local count,walls=scanGates(state);result.structures={gates=count,walls=walls};assert(r:setNativeName(s.units[1],'Gate Breaker'));assert(r:setNativeName(caster,'Siege Sage'));local frozen=M.copy(s)
  local gate;for _,g in pairs(gates)do gate=g;break end;local rejected,message=r:add(s,13,1,gate.x,gate.y);assert(not rejected,'Native gate accepted an actor');healthy();result.obstacle={reason=tostring(message),source='native_gate_replacement'};result.diagnostic={name=assert(r.diag:export({fixture='intentional rejected gate overlap'},r:snapshot(s)))}
  local wall;local live=r.live[s.units[1].id];for _,cell in ipairs(healthy().grid)do if cell.flags&2~=0 and cell.unit<0 then wall=cell;break end end;assert(wall,'No native wall/parapet cell found')
  local nativeAllowed=api.battleCanStand(live,wall.x,wall.y,0);local accepted,new,parapet=r:add(s,13,2,wall.x,wall.y)
  assert(accepted==nativeAllowed,'Editor wall placement disagrees with native strict footprint rule')
  if accepted then s=new;healthy();local removed,nextSetup=r:remove(s,parapet);assert(removed,nextSetup);s=nextSetup else healthy()end
  result.wall={x=wall.x,y=wall.y,flags=wall.flags,native_allowed=nativeAllowed,editor_matched=1}
  for attempt=1,3 do local rejected,message=r:add(s,13,1,gate.x,gate.y);assert(not rejected,'Gate overlap succeeded on retry');healthy()end
  result.obstacle.repeated_rejections=3
  local mediumMonster
  for _,name in ipairs({'Giant Spider','Elephant','Mammoth','Troll'})do local monster=api.findMonster(name);if monster and monster>=0 then local f=api.testFieldFootprint(monster);if f and f.width==2 and f.height==2 then mediumMonster=monster;break end end end
  assert(mediumMonster,'No actual2x2 fixture available');local px,py=vacant(r.live[s.units[1].id],2,2)
  local placed,nextSetup,medium=r:add(s,mediumMonster,2,px,py);assert(placed,nextSetup);s=nextSetup;healthy()
  local mediumState=api.testFieldUnitState(r.live[medium.id]);assert(mediumState.width==2 and mediumState.height==2 and #mediumState.occupied==4)
  result.medium={monster=medium.monster,name=medium.name,width=mediumState.width,height=mediumState.height,occupied=#mediumState.occupied}
  local removed,nextSetup=r:remove(s,medium);assert(removed,nextSetup);s=nextSetup;healthy()
  local troll=962;assert(c.byId[troll]);result.large={monster=troll,name=c.byId[troll].name};local sample=r.live[s.units[1].id];local x,y=vacant(sample,3,3);local accepted,new,large=r:add(s,troll,2,x,y);assert(accepted,new);s=new;healthy()
  local native=r.live[large.id];local row=api.testFieldUnitState(native);assert(row.width==3 and row.height==3 and #row.occupied==9)
  local removed,new=r:remove(s,large);assert(removed,new);s=new;healthy();assert(r:retirementVerified(native));local added,new,replacement=r:add(s,13,2,x,y);assert(added,new);s=new;healthy();local removed,new=r:remove(s,replacement);assert(removed,new);s=new
  local state=assert(L.read(r,r.live[caster.id]));assert(#state.schools>0);assert(L.raise(r,caster,state.schools[1].path));assert(api.giveItem(r.live[caster.id],'Amulet of Anti Magic'));assert(L.capture(r,caster,assert(L.read(r,r.live[caster.id]))));healthy();frozen=M.copy(s)
  result.regressions={large_footprint='3x3',delete_reuse=1,custom_base_school=1,custom_item=1,random_known_memorized_preserved=1}
  local file='siege-'..terrain..'-'..result.environment.session:sub(1,12);assert(api.writeIni(file,M.encode(s,c.mods)));local loaded,reason=M.decode(api.readIni(file),c,c.mods);assert(loaded,reason);assert(r:build(loaded,false));s=loaded;healthy();assert(equal(M.encode(s,c.mods),M.encode(frozen,c.mods)))
  local ui=U.new(api);ui.catalog=c;ui.runtime=r;ui.scenario=s;ui.diag=r.diag
  for cycle=1,2 do local count,walls=scanGates(healthy());fighting=true;assert(ui:fight());fighting=false;local final=assert(api.testFieldFinalState());assert(final.complete);local plan=require('sandbox.final_view').prepare(final);assert(plan.complete);for _,row in ipairs(final.units)do if row.kind=='structure'then assert(row.creationSource=='native_gate_replacement'and row.provenanceVerified)end end;result['battle'..cycle]={round=api.get('battleRound'),winner=api.get('battleWinner'),gate_hp_lost=damage,gates_broken=broken,movement_events=moves};assert(api.get('battleRound')>0);assert(ui:reset(cycle==1));s=ui.scenario;healthy();assert(equal(M.encode(s,c.mods),M.encode(frozen,c.mods)))end
  assert(damage>0 and broken>0 and moves>0,'No actual gate breach/movement observed');result.workflow={file=file,gate_hp_lost=damage,gates_broken=broken,movement_events=moves};assert(ui:dispatch('clear'));s=ui.scenario;healthy();assert(#s.units==0 and M.count(s,1)==0 and M.count(s,2)==0);local structures=scanGates(api.testFieldState());assert(structures>0);result.workflow.clear_keeps_native_structures=1;assert(r:close());r=nil;local life=api.testFieldLifecycle();assert(life.complete and #life.issues==0)
 end,tostring)
 if not ok and r then local d=r.diag:export({fixture='accepted siege regression failure',error=tostring(why)},r:snapshot(r.current or s));result.diagnostic={name=d or'unavailable'}end
 if r then local closed,detail=r:close();if not closed then ok=false;why=tostring(why)..'; cleanup:'..tostring(detail)end end
 result.fort={status=ok and'PASS'or'FAIL',detail=ok and'Native siege, gate damage/breach, placement refusal, SaveLoad/two battles/ResetRematch'or tostring(why)};result.complete={status=ok and'PASS'or'FAIL'};assert(api.writeIni('results',ini(result)));api.set('traceLevel',0);return value
end,-100)
