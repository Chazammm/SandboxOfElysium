-- Opt-in real native projection/input-routing checks with controlled Lua input samples.
-- Does not inject operating-system input or claim a visible mouse gesture.
local api=coe5;local U=require('sandbox.ui');local M=require('sandbox.model')
local out={environment=api.readIni('launcher-context').environment};local started,ui=false,nil
local post,frameError;local get,buttons,wheel=api.get,api.testFieldPointerButtons,api.testFieldPointerWheel
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
api.wrap('BATTLE_DRAW',function(next,...)
 local value=next(...);if post then local fn=post;post=nil;local ok,why=xpcall(fn,tostring);if not ok then frameError=why end end;return value
end,-200)
local function frame(fn)post=fn;frameError=nil;api.drawTestField();assert(not frameError,frameError);assert(not post)end
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local value=next(...);if started then return value end;started=true
 local ok,why=xpcall(function()
  ui=U.new(api);ui:ensureCatalog();local s=M.new();M.add(s,13,'Spearman',1,8,9);M.add(s,13,'Spearman',2,20,9)
  ui.scenario=s;assert(ui.runtime:build(s));ui.phase='prepare';ui.native=true;ui.selected=13;ui.team=1;ui.formation=1;ui.n=1
  frame();frame();local count=#api.testFieldState().units
  frame(function()
   local px,py=api.battleCellToScreen(3,3);local cx,cy=api.battleScreenToCell(px,py);assert(cx==3 and cy==3)
   local x,y=get('screenW')-60,300
   api.get=function(key,...)if key=='uiPointerX'then return x elseif key=='uiPointerY'then return y elseif key=='mouseButtons'then return 0 end;return get(key,...)end
   ui.releaseBarrier=nil;ui.context=nil;ui.lastMouse=0;ui.dragBlocked=false;ui.pending=nil
   ui:input(2);x,y=px,py;ui:input(2);assert(not ui.pending and #api.testFieldState().units==count)
   ui:input(0);ui:input(2);assert(ui.pending and ui.pending.place and ui.pending.x==3 and ui.pending.y==3)
   local requested=ui.pending;ui.pending=nil;ui:dispatch(requested);s=ui.scenario
   assert(#api.testFieldState().units==count+1 and api.battleUnitAt(3,3)==ui.runtime.live[s.units[#s.units].id]);ui:input(0)
   out.panel_drag={status='PASS',native_projection=1,panel_tail_placed=0,new_map_press_placed=1}
   local frozen=api.testFieldState();ui.releaseBarrier=nil;ui.zoomAwaitingDraw=nil;ui.requestedZoom=nil;ui.lastWheel=100
   api.testFieldPointerWheel=function()return 101 end;api.testFieldPointerButtons=function()return nil,'Injected unavailable physical buttons'end
   ui:wheelZoom();assert(ui.requestedZoom==nil and ui.lastWheel==101)
   api.testFieldPointerButtons=function()return 0 end;ui:wheelZoom();assert(ui.requestedZoom==nil,'Unavailable wheel delta replayed')
   api.testFieldPointerWheel=function()return 102 end;ui:wheelZoom();assert(ui.requestedZoom~=nil,'Fresh map wheel input no longer works')
   assert(equal(frozen,api.testFieldState()));ui.requestedZoom=nil
   out.partial_input={status='PASS',fault='Injected nil physical-buttons reply',stale_engine_fallback_refused=1,no_wheel_replay=1,next_map_wheel_accepted=1}
   api.get=get;api.testFieldPointerButtons=buttons;api.testFieldPointerWheel=wheel
  end)
  assert(ui.runtime:ready(s));ui.phase='menu';assert(ui.runtime:close())
 end,tostring)
 api.get=get;api.testFieldPointerButtons=buttons;api.testFieldPointerWheel=wheel
 if ui then ui.phase='menu';ui.runtime:close()end
 out.complete={status=ok and'PASS'or'FAIL',detail=tostring(why or'Native projection and controlled input samples checked')};assert(api.writeIni('results',out));return value
end,-100)
