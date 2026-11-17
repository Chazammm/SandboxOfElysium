-- Opt-in isolated native regression. Never enabled by an ordinary Sandbox launch.
local api=coe5;local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local D=require('sandbox.diagnostics');local U=require('sandbox.ui');local L=require('sandbox.loadout');local Bulk=require('sandbox.clear_items')
local request=api.readIni('request')or{};local only=request.run and request.run.only or'all';local out={environment=api.readIni('launcher-context').environment};local started,fighting=false,false;local requested=false;api.addMainMenuButton("Run controls native checks",function()requested=true end);local ui;local beforeDraw,afterDraw,frameError
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function encode(v)if type(v)=='boolean'then return v and 1 or 0 end;if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=encode(x)end;return t end
local function write()assert(api.writeIni('results',encode(out)))end
local function actor(s,id)for _,u in ipairs(s.units)do if u.id==id then return u end end end
local function healthy(s)local ok,why=ui.runtime:ready(s);assert(ok,why);local state=assert(api.testFieldState());assert(state.complete and #state.issues==0 and #state.units==#s.units);return state end
local function scene(s,native)ui.snapshot=nil;ui.noticeText=nil;ui.scenario=s;ui.phase='menu';ui.runtime.phase=nil;assert(ui.runtime:build(s,native));ui.phase='prepare';ui.native=true;healthy(s);return ui.runtime end
local function small(terrain,width)local s=M.new();s.terrain=terrain or 0;if width then s.minimumWidth=width;s.size='Minimum width'end;local a=M.add(s,13,'Spearman',1,8,9);local b=M.add(s,953,'Goblin',2,20,9);return s,a,b end
local function free(r,unit,w,h)for x=1,r.width-w-1 do for y=1,19-h do local clear=true;for dx=0,w-1 do for dy=0,h-1 do if api.battleUnitAt(x+dx,y+dy)>=0 or api.battleObjectAt(x+dx,y+dy)>=0 then clear=false end end end;if clear and api.battleCanStand(unit,x,y,0)then return x,y end end end;error('No verified free native footprint')end
local function frame(pre,post)beforeDraw=pre;afterDraw=post;frameError=nil;api.drawTestField();assert(not frameError,frameError);assert(not beforeDraw and not afterDraw,'Native draw callback did not run')end
local function inFrame(fn)local ok,why=xpcall(fn,tostring);if not ok then frameError=why end end
api.wrap('BATTLE_DRAW',function(next,...)if beforeDraw then local fn=beforeDraw;beforeDraw=nil;inFrame(fn)end;local v=next(...);if afterDraw then local fn=afterDraw;afterDraw=nil;inFrame(fn)end;return v end,-200)
api.wrap('BATTLE_WAIT',function(next,...)local v=next(...);if fighting and v==0 and(api.get('battleDelay')or 0)>2 then return 1 end;return v end)
local function test(name,fn)if only~='all'and only~='none'and not(','..only..','):find(','..name..',',1,true)then return end;out.progress={stage=name};write();local ok,why=xpcall(fn,tostring);beforeDraw=nil;afterDraw=nil;if ui then ui.phase='menu';local closed,reason=ui.runtime:close();if not closed then ok=false;why=tostring(why)..'; cleanup '..tostring(reason)end end;out[name]={status=ok and'PASS'or'FAIL',detail=ok and'Actual production Lua/native API and verified cleanup'or tostring(why)};write()end
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local v=next(...);if started or(request.run and request.run.defer=='1'and not requested)then return v end;started=true;ui=U.new(api);ui:ensureCatalog();ui.notice=function(self,text)self.message=text end
 test('user_replay',function()
  local data=assert(api.readIni('user-recovery-copy'),'Private copied user recovery fixture is required');local s,why=M.decode(data,ui.catalog,ui.catalog.mods);assert(s,why);assert(#s.units==15 and s.terrain==70);local r=scene(s,false);local frozen=M.encode(s,ui.catalog.mods);local retired={}
  for pass=1,3 do for _,p in ipairs({{15,10},{14,11}})do local ok,why=r:add(s,962,2,p[1],p[2]);assert(not ok and not r.blocked,why);healthy(s);assert(equal(frozen,M.encode(s,ui.catalog.mods)));for _,row in ipairs(api.testFieldLifecycle().created)do if row.createdMonster==962 then local state=assert(api.testFieldUnitState(row.unit));assert(not state.alive and state.hp==-9999 and state.worldX==-1 and state.worldY==-1 and #state.anchors==0 and #state.occupied==0);retired[row.generation]=row.unit end end end end
  local rejected=0;for _ in pairs(retired)do rejected=rejected+1 end;assert(rejected>=2);local diagnostic=assert(r.diag:export({fixture='actual user recovery after intentional Troll rejection'},r:snapshot(s)));out.user_rejection={attempts=6,model=#s.units,native=#api.testFieldState().units,retired_generations=rejected,diagnostic=diagnostic}
  for cycle=1,5 do fighting=true;assert(ui:fight());fighting=false;local final=assert(api.testFieldFinalState());for _,row in ipairs(final.units or{})do assert(row.monster~=962,'Unexpected Troll in native final capture')end;assert(ui:reset(cycle>1),ui.message);s=ui.scenario;healthy(s);assert(equal(frozen,M.encode(s,ui.catalog.mods)));for _,row in ipairs(api.testFieldState().units)do assert(row.monster~=962)end;out['user_battle'..cycle]={round=api.get('battleRound'),winner=api.get('battleWinner'),model=#s.units,native=#api.testFieldState().units}end
  local file='controls-user-'..out.environment.session:sub(1,12);assert(api.writeIni(file,M.encode(s,ui.catalog.mods)));local loaded,why=M.decode(api.readIni(file),ui.catalog,ui.catalog.mods);assert(loaded,why);assert(r:build(loaded,false));healthy(loaded);assert(equal(frozen,M.encode(loaded,ui.catalog.mods)))
 end)
 test('retirement',function()
  local s,a,b=small(0,70);local r=scene(s,true);local x,y=free(r,r.live[a.id],1,1);local ok,new,u=r:add(s,962,2,x,y);assert(ok,new);s=new;ui.scenario=s;healthy(s);local id=r.live[u.id];local fp=assert(api.testFieldFootprint(962));assert(fp.width==3 and fp.height==3)
  for dx=0,2 do for dy=0,2 do assert(api.battleUnitAt(u.x+dx,u.y+dy)==id)end end
  local px,py=u.x,u.y;local removed,new=r:remove(s,u);assert(removed,new);s=new;ui.scenario=s;assert(r:retirementVerified(id));healthy(s);for dx=0,2 do for dy=0,2 do assert(api.battleUnitAt(px+dx,py+dy)<0)end end
  local placed,new,replacement=r:add(s,13,1,px,py);assert(placed,new);s=new;ui.scenario=s;healthy(s);assert(r.live[replacement.id]and #s.units==3)
  local before=M.encode(s,ui.catalog.mods);for pass=1,5 do local accepted,why=r:add(s,962,2,r.width-1,19);assert(not accepted and not r.blocked,why);assert(equal(before,M.encode(s,ui.catalog.mods)));healthy(s)end
  out.retirement_detail={large_footprint='3x3',deleted_native=id,immediate_reuse=1,rejected=5,model=#s.units,native=#api.testFieldState().units}
 end)
 test('unique',function()
  local pending=small(2,70);local closed=R.new(api,ui.catalog,ui.diag)
  assert(closed:setMultipleUnique(pending,true));assert(closed:setMultipleUnique(pending,false));assert(not closed.open)
  local s,a,b=small(2,70);local r=scene(s,true);assert(r:setNativeName(a,'Stable Guard'));local before=api.testFieldState();local life=api.testFieldLifecycle();local camera
  frame(nil,function()camera=api.battleView();assert(camera);local current=api.testFieldState();assert(r:setMultipleUnique(s,true));local changed=api.testFieldState();changed.allowMultipleUnique=current.allowMultipleUnique;assert(equal(current,changed));assert(equal(camera,api.battleView()))end)
  assert(api.testFieldLifecycle().session==life.session and api.testFieldLifecycle().createdCount==life.createdCount)
  local unique=assert(api.findMonster('Arch Devil'));local x,y=free(r,r.live[a.id],3,3);local ok,new,one=r:add(s,unique,1,x,y);assert(ok,new);s=new;ui.scenario=s;x,y=free(r,r.live[a.id],3,3);local ok,new,two=r:add(s,unique,2,x,y);assert(ok,new);s=new;ui.scenario=s;assert(r.live[one.id]~=r.live[two.id]);one=assert(actor(s,one.id));assert(r:setNativeName(one,'First Devil'));assert(r:setNativeName(two,'Second Devil'));healthy(s)
  local frozen=M.encode(s,ui.catalog.mods);local ids=M.copy(r.live);local native=api.testFieldState();local off,why=r:setMultipleUnique(s,false);assert(not off and not r.blocked and s.allowMultipleUnique and equal(ids,r.live)and equal(frozen,M.encode(s,ui.catalog.mods))and equal(native,api.testFieldState()),why)
  local removed,new=r:remove(s,two);assert(removed,new);s=new;ui.scenario=s;assert(r:setMultipleUnique(s,false));local same=M.copy(r.live);local x,y=free(r,r.live[a.id],3,3);local accepted,why=r:add(s,unique,2,x,y);assert(not accepted and not r.blocked and equal(same,r.live));healthy(s)
  out.unique_detail={in_place=1,independent_native_ids=1,duplicate_off_refused=1,duplicates_after_off_refused=1}
 end)
 test('items',function()
  local s=M.new();local dragon=assert(api.findMonster('Arcane Frost Dragon'));local a=M.add(s,dragon,'Arcane Frost Dragon',1,8,9);local b=M.add(s,13,'Spearman',2,20,9);s.minimumWidth=70;s.size='Minimum width';local r=scene(s,true)
  assert(api.giveItem(r.live[a.id],'Crystal Heart'));assert(api.giveItem(r.live[b.id],'Amulet of Anti Magic'));assert(L.capture(r,a,assert(L.read(r,r.live[a.id]))));assert(L.capture(r,b,assert(L.read(r,r.live[b.id]))));assert(r:setNativeName(a,'Heart Keeper'));healthy(s)
  local before={};for _,u in ipairs(s.units)do local state=assert(L.read(r,r.live[u.id]));before[u.id]={known=M.copy(state.known),memorized=M.copy(state.memorized),injuries=state.organInjuryFlags,name=api.testFieldUnitName(r.live[u.id]).shown}end
  local plan=assert(Bulk.plan(r,s));assert(plan.teamA>0 and plan.teamB>0 and plan.cursed>0 and plan.implanted>0);local result=Bulk.run(r,s,plan);assert(result.ok,Bulk.describe(result));healthy(s)
  for _,u in ipairs(s.units)do local state=assert(L.read(r,r.live[u.id]));for _,slot in ipairs(state.items)do assert(slot.id==-1)end;assert(equal(state.known,before[u.id].known)and equal(state.memorized,before[u.id].memorized)and state.organInjuryFlags==before[u.id].injuries and api.testFieldUnitName(r.live[u.id]).shown==before[u.id].name)end
  out.items_detail={both_teams=1,cursed=plan.cursed,implanted=plan.implanted,cleared=result.removed,injuries_spells_names_unchanged=1}
 end)
 test('items_bonus',function()
  local priest=assert(api.findMonster('Shell Priest'));assert(ui.catalog.byId[priest].name=='Shell Priest','Separately installed CrabCult is required');local fragment;for _,item in ipairs(ui.catalog.items)do if item.name=='Abyss Fragment'then fragment=item end end;assert(fragment)
  local s=M.new();local first=M.add(s,13,'Spearman',1,8,9);local u=M.add(s,priest,'Shell Priest',2,20,9);local r=scene(s,true);assert(api.giveItem(r.live[first.id],'Amulet of Anti Magic'));assert(L.capture(r,first,assert(L.read(r,r.live[first.id]))))
  local state=assert(L.read(r,r.live[u.id]));local position;for _,slot in ipairs(state.items)do if slot.slotType==7 and slot.id<0 then position=slot.position;break end end;assert(position);assert(L.equip(r,u,position,fragment,-1))
  for _,key in ipairs(M.copy(u.spells))do assert(r:memorize(u,key,false))end
  local high;for _,spell in ipairs(ui.catalog.spells)do if spell.path==4 and spell.level==2 then high=spell;break end end;assert(high)
  local known=false;for _,key in ipairs(u.baseline.known)do if key==high.id..':'..high.name then known=true end end;if not known then assert(L.learn(r,u,high))end;assert(r:memorize(u,high.id..':'..high.name,true));local before=assert(L.read(r,r.live[u.id]));local saved=M.copy(u)
  local result=Bulk.run(r,s,assert(Bulk.plan(r,s)));assert(not result.ok and result.completed==1 and result.rollbackVerified and not r.blocked,Bulk.describe(result));assert(equal(before,L.read(r,r.live[u.id]))and equal(saved,u));healthy(s)
  assert(r:memorize(u,high.id..':'..high.name,false));local result=Bulk.run(r,s,assert(Bulk.plan(r,s)));assert(result.ok,Bulk.describe(result));local state=assert(L.read(r,r.live[u.id]));local kept=false;for _,id in ipairs(state.known)do if id==high.id then kept=true end end;assert(kept);healthy(s)
  out.items_bonus_detail={prior_actor_cleared=1,failed_actor_verified_unchanged=1,spell_not_trimmed=1,explicit_deselection_then_clear=1}
 end)
 test('zoom',function()
  local s,a,b=small(0,70);local r=scene(s,true);frame();local initial=assert(api.testFieldZoom());local invalid,why=api.setTestFieldZoom(0.75);assert(not invalid and why=='not_battle_frame','Zoom setter unexpectedly wrote between frames')
  local frozen=api.testFieldState();local mapped=0
  for _,zoom in ipairs({0.5,0.75,1,1.5,2})do
   ui.requestedZoom=zoom;frame();frame(nil,function()
    local value=assert(api.testFieldZoom());local view=assert(api.battleView());out['zoom_'..tostring(zoom)]={zoom=value.zoom,cell=view.cellSize,camera_x=view.cameraX,camera_y=view.cameraY,origin_x=view.originX,origin_y=view.originY,pointer_x=api.get('uiPointerX'),pointer_y=api.get('uiPointerY')};write();assert(math.abs(value.zoom-zoom)<0.0001 and math.abs(view.cellSize-(initial.cellSize/initial.zoom)*zoom)<0.001,('Zoom requested %.3f actual %.3f cell %.3f initial %.3f'):format(zoom,value.zoom,view.cellSize,initial.cellSize))
    for x=0,r.width-1 do for y=0,19 do local sx,sy=api.battleCellToScreen(x,y);if sx and sx>=1 and sx<view.screenW-311 and sy>=1 and sy<view.screenH-40 then local cx,cy=api.battleScreenToCell(sx,sy);assert(cx==x and cy==y,'Native projection roundtrip mismatch');mapped=mapped+1;local model=ui:unitAt(x,y);if model then assert(r.live[model.id]==api.battleUnitAt(x,y))end end end end
    assert(equal(frozen,api.testFieldState()),'Zoom mutated the native field')
   end)
  end
  ui.requestedZoom=0.5;frame();local kept=assert(api.testFieldZoom());local x,y=free(r,r.live[a.id],3,3);local made,new,u=r:add(s,962,2,x,y);assert(made,new);s=new;ui.scenario=s;local native=r.live[u.id]
  frame(nil,function()assert(math.abs(api.testFieldZoom().zoom-kept.zoom)<0.0001);for dx=0,2 do for dy=0,2 do local cx,cy=api.battleCellToScreen(u.x+dx,u.y+dy);if cx>=0 and cx<api.get('screenW')and cy>=0 and cy<api.get('screenH')then local x,y=api.battleScreenToCell(cx,cy);assert(api.battleUnitAt(x,y)==native and ui:unitAt(x,y).id==u.id)end end end end)
  local removed,new=r:remove(s,u);assert(removed,new);s=new;ui.scenario=s;frame(nil,function()assert(math.abs(api.testFieldZoom().zoom-kept.zoom)<0.0001)end);healthy(s);assert(mapped>30,'Only '..mapped..' native cells visible; see camera/pointer metadata')
  local wheel,why=api.testFieldPointerWheel();assert(wheel==nil and why=='not_battle_frame')
  for cycle=1,2 do
   fighting=true;assert(ui:fight());fighting=false
   assert(ui:reset(cycle>1));s=ui.scenario;frame();frame(nil,function()assert(math.abs(api.testFieldZoom().zoom-kept.zoom)<0.0001,'Battle Reset/Rematch lost accepted zoom')end);healthy(s)
  end
  out.zoom_detail={native_roundtrips=mapped,min=0.5,max=2,large_interior_hits=1,no_actor_grid_changes=1,delete_reset_preserved=1,battle_reset_rematch=2}
 end)

 local passed=true;for _,value in pairs(out)do if type(value)=='table'and value.status=='FAIL'then passed=false end end;out.progress={stage='complete'};out.complete={status=passed and'PASS'or'FAIL',scope='Actual isolated native APIs; visible mouse tests reported separately'};write();return v
end,-100)
