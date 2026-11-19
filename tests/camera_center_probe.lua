-- Opt-in owned native camera/guide acceptance. No actor relocation or fake result.
local api=coe5;local U=require('sandbox.ui');local M=require('sandbox.model');local V=require('sandbox.unit_view')
local request=((api.readIni('request')or{}).run or{}).only or'0:160:1'
local terrain,minimum,zoom=request:match('^(%d+):(%d+):([%d%.]+)$');terrain=tonumber(terrain);minimum=tonumber(minimum);zoom=tonumber(zoom)
local out={environment=api.readIni('launcher-context').environment};local started,fighting=false,false;local ui;local setZoom=false;local seen=0
local function encoded(t)local out={};for k,v in pairs(t)do out[k]=type(v)=='boolean'and(v and 1 or 0)or type(v)=='table'and encoded(v)or v end;return out end
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
api.wrap('BATTLE_WAIT',function(next,...)
 local v=next(...)
 if setZoom then setZoom=false;assert(api.setTestFieldZoom(zoom));assert(api.panTestFieldViewport(1000,0))end
 if fighting and v==0 and(api.get('battleDelay')or 0)>2 then return 1 end;return v
end,500)
api.wrap('BATTLE_DRAW',function(next,...)
 local v=next(...)
 if fighting then
  seen=seen+1;local view=assert(api.battleView());local state=assert(api.testFieldBattleCenterState())
  if seen<=4 then out['draw'..seen]={width=view.width,cell=view.cellSize,x=view.originX,y=view.originY,screenW=api.get('screenW'),screenH=api.get('screenH'),center_error=view.originX+view.width*view.cellSize/2-api.get('screenW')/2,applied=state.applied and 1 or 0}end
  if seen==1 then assert(state.applied,'No applied native center at first draw: '..tostring(state.reason));assert(math.abs(out.draw1.center_error)<0.01,'First actual battle view is not centered')end
 end
 return v
end,1000)
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local v=next(...);if started then return v end;started=true
 local ok,why=xpcall(function()
  assert(terrain and minimum and zoom)
  ui=U.new(api);ui:ensureCatalog();ui.notice=function(self,text)self.message=text end
  local s=M.new();s.terrain=terrain;s.minimumWidth=minimum;s.size='Minimum width'
  local first,second=terrain==27 and 732 or 947,terrain==27 and 685 or 13
  local friends=6
  if minimum==32 then first=634;friends=200 end
  for i=1,friends do M.add(s,first,api.get('monsterName',first),1,8,i*2%20)end
  for i=1,3 do M.add(s,second,api.get('monsterName',second),2,28,i*3)end
  ui.scenario=s;assert(ui.runtime:build(s,true));ui.native=true;ui.phase='prepare';ui:prepareLog()
  for i=1,3 do api.drawTestField()end
  setZoom=true;api.drawTestField();api.drawTestField();local before=assert(api.testFieldState());local encoded=M.encode(s,ui.catalog.mods)
  ui:dispatch('centerguide');api.drawTestField();assert(ui.centerGuideVisible);assert(same(before,api.testFieldState()))
  local actual=assert(api.testFieldEnvironmentState());out.request={terrain=terrain,minimum=minimum,actual_width=actual.width,zoom=zoom}
  local queried={13,594,api.findMonster('Apocalyptic Rider')};local mod
  for _,m in ipairs(ui.catalog.monsters)do if m.definitionMod=='CrabCult'then mod=m;break end end
  if mod then queried[#queried+1]=mod.id;out.mod={name=mod.name,monster=mod.id,definitionMod=mod.definitionMod}end
  local high=api.get('unitLastIndex')
  for _,id in ipairs(queried)do local state=assert(V.read(api,id,ui.catalog));assert(state.name==api.get('monsterName',id));assert(same(before,api.testFieldState()));assert(api.get('unitLastIndex')==high);out['view'..id]={name=state.name,stats=#state.stats,abilities=#state.abilities,attacks=#state.attacks,unknown=state.unknown}end
  assert(api.requestTestFieldBattleCenter());assert(same(before,api.testFieldState()),'Queued camera request changed actors or terrain')
  fighting=true;assert(ui:fight());fighting=false;assert(seen>0);local state=assert(api.testFieldBattleCenterState());out.center=state
   assert(same(encoded,M.encode(ui.snapshot,ui.catalog.mods)))
   local reset=ui:reset(false);out.reset={accepted=reset and 1 or 0,detail=ui.message or'unknown'}
   if not reset and minimum==32 then
    local file=assert(ui.runtime.recoveryFile,'Refused exact restore lost recovery');local recovery=assert(api.readIni(file));local kept=assert(M.decode(recovery,ui.catalog,ui.catalog.mods))
    assert(same(encoded,M.encode(kept,ui.catalog.mods)),'Recovery differs from the pre-battle scenario')
    out.reset.recovery_verified=1;out.reset.scope='Exact restoration refused; original scenario recovery verified. No native redeployment fallback.'
   else assert(reset,ui.message)end
   assert(ui.centerGuideVisible);assert(same(encoded,M.encode(ui.scenario,ui.catalog.mods)))
  out.battle={winner=api.get('battleWinner'),round=api.get('battleRound'),draws=seen};assert(ui.runtime:close())
 end,tostring)
 fighting=false;if ui and ui.runtime.open then ui.runtime:close()end
 out.complete={status=ok and'PASS'or'FAIL',detail=tostring(why or'Actual native battle midpoint, no-actor template reads and exact Reset checked')};assert(api.writeIni('results',encoded(out)));return v
end,-100)
