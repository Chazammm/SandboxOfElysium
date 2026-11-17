-- Opt-in isolated real-game probe; never loaded by an ordinary Sandbox launch.
local api=coe5;local U=require('sandbox.ui');local M=require('sandbox.model')
local out={environment=api.readIni('launcher-context').environment};local ui,started,fighting,stage,battle=false,false,false,0,0
local beforeDraw,afterDraw,beforeWait,frameError
local function same(a,b)
 if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not same(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function frame(pre,post)
 beforeDraw=pre;afterDraw=post;frameError=nil;api.drawTestField();assert(not frameError,frameError);assert(not beforeDraw and not afterDraw)
end
local function invoke(fn)local ok,why=xpcall(fn,tostring);if not ok then frameError=why end end
local function mutate(fn)beforeWait=fn;frame();assert(not beforeWait,'Native WAIT callback did not run')end
api.wrap('BATTLE_WAIT',function(next,...)if beforeWait then local fn=beforeWait;beforeWait=nil;invoke(fn)end;return next(...)end,-300)
api.wrap('BATTLE_DRAW',function(next,...)
 if beforeDraw then local fn=beforeDraw;beforeDraw=nil;invoke(fn)end
 local v=next(...);if afterDraw then local fn=afterDraw;afterDraw=nil;invoke(fn)end;return v
end,-200)
local function toggle(value)
 local actors=api.testFieldState();local view=api.battleView()
 assert(ui:readLogState().visible~=value);assert(ui:requestLogToggle());ui:applyRequestedLog()
 assert(api.testFieldLogState().visible==value and same(actors,api.testFieldState())and same(view,api.battleView()))
end
api.wrap('BATTLE_WAIT',function(next,...)
 local v=next(...)
 if fighting then
  assert(type(api.testFieldPointerButtons())=='number','Physical pointer getter unavailable in combat WAIT')
  if stage==0 then
   local state=api.testFieldLogState();assert(state.visible,'Production fight did not show the native log')
   toggle(false);out['battle'..battle..'_hidden']={start_lines=state.lineCount,round=api.get('battleRound')};stage=1
  -- Native battleRound can retain the previous battle until the rematch
  -- simulation starts. Wait for new messages rather than treating it as fresh.
  elseif stage==1 and api.get('battleRound')>=1 and api.testFieldLogState().lineCount>out['battle'..battle..'_hidden'].start_lines then
   local state=api.testFieldLogState();assert(not state.visible and state.lineCount>out['battle'..battle..'_hidden'].start_lines,
    ('Hidden state/generation: battle=%d visible=%s round=%s lines=%s start=%s startRound=%s'):format(battle,tostring(state.visible),tostring(api.get('battleRound')),tostring(state.lineCount),tostring(out['battle'..battle..'_hidden'].start_lines),tostring(out['battle'..battle..'_hidden'].round)))
   out['battle'..battle..'_hidden'].end_lines=state.lineCount;toggle(true);stage=2
  elseif stage==2 and api.get('battleRound')>=2 then assert(api.testFieldLogState().visible);stage=3 end
  if stage>=3 and v==0 and(api.get('battleDelay')or 0)>2 then return 1 end
 end
 return v
end,200)
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local v=next(...);if started then return v end;started=true
 local ok,why=xpcall(function()
  ui=U.new(api);ui:ensureCatalog();ui.notice=function(self,text)self.message=text end
  local s=M.new();s.terrain=1;s.minimumWidth=50;s.size='Minimum width'
  for i=1,6 do M.add(s,947,'Ogre',1,8,i*2)end
  M.add(s,594,"Druid's Apprentice",1,6,17)
  for i=1,4 do M.add(s,13,'Spearman',2,28,i*2)end
  ui.scenario=s;assert(ui.runtime:build(s,true));ui.phase='prepare';ui.native=true
  ui:prepareLog();assert(not api.testFieldLogState().visible)
  frame();frame();local frozen=M.encode(s,ui.catalog.mods);local actors=api.testFieldState()
  for _,zoom in ipairs({0.25,0.5,1})do
   mutate(function()
    assert(api.setTestFieldZoom(zoom));local view=api.battleView()
    assert(ui:setLogVisibility(true,'native probe transient'));ui:prepareLog()
    assert(not api.testFieldLogState().visible and same(view,api.battleView())and same(actors,api.testFieldState()))
   end)
   frame(nil,function()
    local viewport=api.testFieldViewport();local p={x=viewport.x+viewport.width/2,y=viewport.y+viewport.height/2}
    local x,y=api.battleScreenToCell(p.x,p.y)
    if x then local sx,sy=api.battleCellToScreen(x,y);local rx,ry=api.battleScreenToCell(sx,sy);assert(rx==x and ry==y)end
   end)
  end
  assert(same(frozen,M.encode(s,ui.catalog.mods)))
  for iteration=1,2 do
   battle=iteration;stage=0;fighting=true;assert(ui:fight());fighting=false;assert(stage==3)
   assert(ui.phase=='after'and api.testFieldLogState().phase=='after'and ui.runtime.finalState.complete)
   frame();toggle(false);frame();local bounds=ui:usableViewport();toggle(true);frame();assert(same(bounds,ui:usableViewport()))
   assert(same(frozen,M.encode(ui.scenario,ui.catalog.mods)))
   local report=ui.report.result;assert(report and report.summary.final_snapshot_complete==1)
   assert(ui:reset(iteration==2));assert(ui.phase=='prepare'and not api.testFieldLogState().visible)
   assert(same(frozen,M.encode(ui.scenario,ui.catalog.mods)));assert(ui.runtime:ready(ui.scenario));frame();frame()
  end
  out.geometry={screenW=api.get('screenW'),screenH=api.get('screenH'),unchanged_actors_and_projection=1,setup_hidden=1,post_actual_visibility=1,battles=2,reset=1,rematch_rebuild=1}
  assert(ui.runtime:close());assert(api.testFieldLifecycle().complete)
 end,tostring)
 if ui and ui.runtime.open then local closed,reason=ui.runtime:close();if not closed then ok=false;why=tostring(why)..'; cleanup '..tostring(reason)end end
 out.integrated={status=ok and'PASS'or'FAIL',detail=ok and'Production Sandbox hooks, combat pointer getter, actual native overlay/messages, post view, Reset and rematch rebuild'or tostring(why)}
 out.complete={status=ok and'PASS'or'FAIL'};assert(api.writeIni('results',out));return v
end,-100)
