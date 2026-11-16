-- Explicit isolated native stock-map acceptance; never enabled by a normal launch.
local api=coe5;local M=require('sandbox.model');local preset=tonumber(api.readIni('request').run.only)or 5;local templates={[5]='farm',[18]='village',[70]='hoburgh',[109]='tentvillage',[98]='oasis'};assert(M.terrainNames[preset], 'Unverified preset is not part of the editor')
local C=require('sandbox.catalog');local R=require('sandbox.runtime');local D=require('sandbox.diagnostics');local U=require('sandbox.ui');local L=require('sandbox.loadout')
local started,fighting=false,false;local result={environment=api.readIni('launcher-context').environment};local moves=0;local steps={};local active
local function ini(v)if type(v)=='boolean'then return v and 1 or 0 end;if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=ini(x)end;return t end
local function save()assert(api.writeIni('results',ini(result)))end
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function healthy(r,s)local ok,why=r:ready(s);assert(ok,why);local state=assert(api.testFieldState());assert(state.complete and #state.issues==0);return state end
local function at(s,id)for _,u in ipairs(s.units)do if u.id==id then return u end end end
local function free(r,id)for x=2,r.width-3 do for y=2,17 do if api.battleUnitAt(x,y)<0 and api.battleObjectAt(x,y)<0 and api.battleCanStand(id,x,y,0)then return x,y end end end;error('No native free cell')end
local function world()local t={};for _,k in ipairs({'worldW','worldH','activePlayer','battleDelay','planeLastIndex'})do t[k]=tostring(api.get(k))end;for x=0,2 do for y=0,2 do for _,k in ipairs({'squareTerrain','squareGround','squareTemperature','squareArmy','squareOwner','squareArmyOwner','squarePlane'})do t[k..x..'_'..y]=tostring(api.get(k,x,y))end end end;for _,k in ipairs({'planeX','planeY','planeWidth','planeHeight'})do t[k]=tostring(api.get(k,0))end;return t end
api.observe('BATTLE_ADVANCE_UNIT',function(unit)if fighting then steps[unit]={x=api.get('unitBattleX',unit),y=api.get('unitBattleY',unit)}end end,function(_,unit)local b=steps[unit];if fighting and b and(b.x~=api.get('unitBattleX',unit)or b.y~=api.get('unitBattleY',unit))then moves=moves+1 end;steps[unit]=nil end)
api.wrap('BATTLE_WAIT',function(next,...)local v=next(...);if fighting and v==0 and(api.get('battleDelay')or 0)>2 then return 1 end;return v end)
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local value=next(...);if started then return value end;started=true;api.set('traceLevel',1);api.keepTraceLines({'bt','bfsize','fs ','defaultground','trees'})
 local before=world();local ok,why=xpcall(function()
  local c=C.read(api);assert(c.testFieldTerrains[preset]);local s=M.new();s.terrain=preset;s.minimumWidth=50;s.size='Minimum width';local a=M.add(s,13,'Spearman',1,8,9);M.add(s,13,'Spearman',1,8,11);local caster=M.add(s,594,"Druid's Apprentice",1,6,5);M.add(s,953,'Goblin',2,18,9);M.add(s,953,'Goblin',2,18,11)
  local r=R.new(api,c,D.new(api));active=r;local opened,reason=r:build(s,true);assert(opened,reason);local state=healthy(r,s);local env=assert(api.testFieldEnvironmentState());assert(env.version==1 and env.terrain==preset and env.plane==0 and env.temperature==25 and env.nativeTemplateObserved and env.nativeTemplate==templates[preset]and env.setupReturned and not env.customMapReplaced and not env.siege and not env.atSea and not env.underground and env.fortParts==api.get('terrain',preset,'batmap'))
  result.context=env;local object;local objects=0;for _,g in ipairs(state.grid)do if g.object>=0 then objects=objects+1;if not object and not api.battleCanStand(r.live[a.id],g.x,g.y,0)then object={monster=api.get('unitMonster',g.object),anchors={{x=g.x,y=g.y}}}end end end;assert(objects>0 and object,'Native farm blocking template/scatter objects missing')
  assert(r:setNativeName(a,'Farm Guard'));assert(r:setNativeName(caster,'Field Sage'));assert(api.giveItem(r.live[caster.id],'Amulet of Anti Magic'));assert(L.capture(r,caster,assert(L.read(r,r.live[caster.id]))));local good,observation=r:check(s);assert(good,observation);r:accept(s,observation);local expected=M.copy(caster);local id=r.live[a.id];local x,y=free(r,id);assert(r:move(a,x,y));assert(r.live[a.id]==id and api.testFieldUnitName(id).name=='Farm Guard')
  local old=M.copy(s);local p=object.anchors[1];local accepted,message=r:add(s,13,1,p.x,p.y);assert(not accepted,'Native obstacle accepted a ground actor');healthy(r,s);assert(equal(s,old));local diagnostic=assert(r.diag:export({fixture='intentional native template obstacle rejection',terrain=preset},r:snapshot(s)));result.rejection_diagnostic={name=diagnostic};result.obstacle={monster=object.monster,name=api.get('monsterName',object.monster),x=p.x,y=p.y,rejection=tostring(message)}
  x,y=free(r,id);local copied,new,copy=r:add(s,13,2,x,y,a);assert(copied,new);s=new;a=at(s,a.id);caster=at(s,caster.id);assert(copy.nativeName=='Farm Guard');assert(r:setNativeName(copy,'Other Guard'));assert(equal(caster,expected));healthy(r,s)
  local file='native-template-'..result.environment.session:sub(1,12);assert(api.writeIni(file,M.encode(s,c.mods)));local loaded,reason=M.decode(api.readIni(file),c,c.mods);assert(loaded,reason);assert(r:build(loaded,false));s=loaded;healthy(r,s);local frozen=M.copy(s)
  local ui=U.new(api);ui.catalog=c;ui.runtime=r;ui.scenario=s;ui.diag=r.diag
  for cycle=1,2 do fighting=true;assert(ui:fight());fighting=false;assert(api.get('battleRound')>0);result['battle'..cycle]={round=api.get('battleRound'),winner=api.get('battleWinner'),movement_events=moves};assert(ui:reset(cycle==1));s=ui.scenario;healthy(r,s);assert(equal(M.encode(s,c.mods),M.encode(frozen,c.mods)))end
  local unchanged=M.copy(s.units);local large=assert(api.findMonster('Apocalyptic Rider'));local fp=assert(api.testFieldFootprint(large));local px,py
  for tx=1,r.width-fp.width-1 do for ty=1,19-fp.height do local clear=true
   for dx=0,fp.width-1 do for dy=0,fp.height-1 do if api.battleUnitAt(tx+dx,ty+dy)>=0 or api.battleObjectAt(tx+dx,ty+dy)>=0 then clear=false end end end
   if clear then px,py=tx,ty;break end
  end;if px then break end end;assert(px,'No large footprint available')
  local placed,new,u=r:add(s,large,1,px,py);assert(placed,new);s=new;healthy(r,s);local native=r.live[u.id]
  for dx=0,fp.width-1 do for dy=0,fp.height-1 do assert(api.battleUnitAt(px+dx,py+dy)==native)end end
  local removed,new=r:remove(s,u);assert(removed,new);s=new;healthy(r,s);assert(not r.live[u.id]and api.battleUnitAt(px,py)~=native and equal(s.units,unchanged))
  local reused,new,u=r:add(s,13,2,px,py);assert(reused,new);s=new;healthy(r,s);local removed,new=r:remove(s,u);assert(removed,new);s=new;healthy(r,s);assert(equal(s.units,unchanged));result.large={width=fp.width,height=fp.height,all_hit_cells_verified=1,deleted_reused=1}
  while #s.units>0 do local removed,new=r:remove(s,s.units[1]);assert(removed,new);s=new end
  local empty=healthy(r,s);assert(#empty.units==0);local emptyFile=file..'-empty';assert(api.writeIni(emptyFile,M.encode(s,c.mods)));local loaded,reason=M.decode(api.readIni(emptyFile),c,c.mods);assert(loaded,reason);assert(r:build(loaded,false));s=loaded;healthy(r,s)
  ui.scenario=s;local kept=M.encode(s,c.mods);assert(not ui:fight()and equal(M.encode(s,c.mods),kept)and #api.testFieldState().units==0);ui.noticeText=nil
  local ex,ey;for _,g in ipairs(api.testFieldState().grid)do if g.x>0 and g.y>0 and g.unit<0 and g.object<0 then ex,ey=g.x,g.y;break end end;assert(ex)
  local added,new,u=r:add(s,13,2,ex,ey);assert(added,new);s=new;healthy(r,s);assert(M.count(s,1)==0 and M.count(s,2)==1);local removed,new=r:remove(s,u);assert(removed,new);s=new;healthy(r,s)
  result.empty={saved=emptyFile,both_teams_empty=1,battle_refused_unchanged=1,new_teamB_actor_after_clear=1}
  assert(moves>0);result.matrix={objects=objects,movement_events=moves,saved=file,names_spells_items_preserved=1};assert(r:close());active=nil;assert(equal(world(),before),'Borrowed square/neighbor/plane context changed');local life=api.testFieldLifecycle();assert(life.complete and #life.issues==0 and not life.open)
 end,tostring)
 if not ok and active then local name=active.diag:export({fixture='unverified native template context',error=tostring(why)},active:snapshot(active.current or{}));result.failure_diagnostic={name=name or'unavailable'}end
 if active then local closed,detail=active:close();if not closed then ok=false;why=tostring(why)..'; cleanup:'..tostring(detail)end end
 result['terrain'..preset]={status=ok and'PASS'or'FAIL',detail=ok and'Actual native template, placement/obstacle/movement, two battles, SaveLoad Reset Rematch and context cleanup'or tostring(why)};result.complete={status=ok and'PASS'or'FAIL'};save();api.set('traceLevel',0);return value
end,-100)
