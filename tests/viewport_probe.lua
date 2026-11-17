-- Opt-in isolated native regression. Never enabled by an ordinary Sandbox launch.
local api=coe5;local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local D=require('sandbox.diagnostics');local U=require('sandbox.ui');local L=require('sandbox.loadout');local Bulk=require('sandbox.clear_items')
local request=api.readIni('request')or{};local only=request.run and request.run.only or'all';local out={environment=api.readIni('launcher-context').environment};local started,fighting=false,false;local requested=false;api.addMainMenuButton("Run viewport native checks",function()requested=true end);local ui;local beforeDraw,afterDraw,frameError
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
local beforeWait
local function mutate(fn)beforeWait=fn;frame();assert(not beforeWait,'Native WAIT callback did not run')end
api.wrap('BATTLE_WAIT',function(next,...)if beforeWait then local fn=beforeWait;beforeWait=nil;inFrame(fn)end;return next(...)end,-300)
api.wrap('BATTLE_WAIT',function(next,...)local v=next(...);if fighting and v==0 and(api.get('battleDelay')or 0)>2 then return 1 end;return v end)
local function test(name,fn)if only~='all'and only~='none'and not(','..only..','):find(','..name..',',1,true)then return end;out.progress={stage=name};write();local ok,why=xpcall(fn,tostring);beforeDraw=nil;afterDraw=nil;if ui then ui.phase='menu';local closed,reason=ui.runtime:close();if not closed then ok=false;why=tostring(why)..'; cleanup '..tostring(reason)end end;out[name]={status=ok and'PASS'or'FAIL',detail=ok and'Actual production Lua/native API and verified cleanup'or tostring(why)};write()end
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local v=next(...);if started or(request.run and request.run.defer=='1'and not requested)then return v end;started=true;ui=U.new(api);ui:ensureCatalog();ui.notice=function(self,text)self.message=text end
 test('viewport',function()
  local s,a,b=small(0,70);local r=scene(s,true);local lx,ly=free(r,r.live[a.id],3,3);local made,new,large=r:add(s,962,1,lx,ly);assert(made,new);s=new;ui.scenario=s;local largeId=r.live[large.id];healthy(s);frame();local W,H=api.get('screenW'),api.get('screenH');local rect={x=0,y=38,width=W-310,height=H-76}
  mutate(function()assert(api.setTestFieldViewport(rect));assert(api.fitTestFieldViewport())end)
  frame(nil,function()
   local v=assert(api.testFieldViewport());assert(v.fits and v.fitsX and v.fitsY);local z=assert(api.testFieldZoom());out.fit={zoom=z.zoom,originX=v.originX,originY=v.originY,cell=v.cellSize,width=v.width,height=v.height,screenW=W,screenH=H};assert(math.abs(z.zoom-(W-314)/70/(H/20))<0.0001)
   for _,p in ipairs({{0,0},{69,0},{0,19},{69,19}})do local x,y=api.battleCellToScreen(p[1],p[2]);assert(x>=v.x and x<=v.x+v.width and y>=v.y and y<=v.y+v.height,'Fit corner hidden')end
  end)
  frame(function()local accepted,reason=api.setTestFieldViewport(rect);assert(not accepted and reason=='draw_read_only')end)
  mutate(function()local before=api.testFieldViewport();local accepted,reason=api.setTestFieldViewport({x=-1,y=38,width=100,height=100});assert(not accepted and reason=='bad_viewport');local accepted,reason=api.panTestFieldViewport(0/0,0);assert(not accepted and reason=='bad_pan');assert(equal(before,api.testFieldViewport()))end)
  local frozen=api.testFieldState();local mapped,largeCells=0,0
  for _,z in ipairs({0.1,0.25,0.5,0.75,1,1.5,2})do
   mutate(function()assert(api.setTestFieldZoom(z))end)
   for _,corner in ipairs({{0,0,1e6,1e6},{69,0,-1e6,1e6},{0,19,1e6,-1e6},{69,19,-1e6,-1e6}})do
    mutate(function()assert(api.panTestFieldViewport(corner[3],corner[4]))end)
    frame(nil,function()
     local v=assert(api.testFieldViewport());local x,y=api.battleCellToScreen(corner[1],corner[2]);assert(x>=v.x and x<=v.x+v.width and y>=v.y and y<=v.y+v.height,'Pan cannot reach corner at '..z)
     local cx,cy=api.battleScreenToCell(x,y);assert(cx==corner[1]and cy==corner[2]);mapped=mapped+1
     assert(v.originX>=v.minOriginX-0.01 and v.originX<=v.maxOriginX+0.01 and v.originY>=v.minOriginY-0.01 and v.originY<=v.maxOriginY+0.01)
     assert(equal(frozen,api.testFieldState()),'View mutated actors/grid')
    end)
   end
   mutate(function()local v=api.testFieldViewport();local x,y=api.battleCellToScreen(large.x+1,large.y+1);assert(api.panTestFieldViewport(v.x+v.width/2-x,v.y+v.height/2-y))end)
   frame(nil,function()
    for dx=0,2 do for dy=0,2 do
     local x,y=api.battleCellToScreen(large.x+dx,large.y+dy);local cx,cy=api.battleScreenToCell(x,y);assert(cx==large.x+dx and cy==large.y+dy and api.battleUnitAt(cx,cy)==largeId)
     local get=api.get;api.get=function(key,...)if key=='uiPointerX'then return x elseif key=='uiPointerY'then return y else return get(key,...)end end
     ui.context=nil;ui.lastMouse=0;ui.releaseBarrier=nil;ui.dragBlocked=false;ui:input(2);assert(ui.context and ui.context.unit.id==large.id);ui:input(0);ui.context=nil;api.get=get
     largeCells=largeCells+1
    end end
    local plan=assert(api.testFieldPlacementPreflight(large.monster,large.x,large.y,largeId,true));assert(plan.valid and #plan.cells==9);for _,cell in ipairs(plan.cells)do local cx,cy=api.battleScreenToCell(cell.screenX,cell.screenY);assert(cx==cell.x and cy==cell.y)end
   end)

  end
  out.viewport_detail={native_corner_roundtrips=mapped,min=0.1,max=2,complete_fit=1,all_extremes_reachable=1}
 end)
 local passed=true;for _,value in pairs(out)do if type(value)=='table'and value.status=='FAIL'then passed=false end end;out.progress={stage='complete'};out.complete={status=passed and'PASS'or'FAIL',scope='Actual isolated native APIs; visible mouse tests reported separately'};write();return v
end,-100)
