-- Opt-in isolated native preview checks. Never loaded by an ordinary mod launch.
-- Candidate cells are discovered in this fixture; none are claimed to be the
-- user's screenshot frame. The baseline mode observes the older raw API reply.
if coe5==nil then
    print('PARSE ONLY: native CoE5 API absent; no game checks performed')
    return
end
local api=coe5
local M=require('sandbox.model')
local U=require('sandbox.ui')
local Clear=require('sandbox.clear_battlefield')
local request=api.readIni('request')or{}
local only=request.run and request.run.only or'all'
local baseline=only=='baseline'
local out={environment=(api.readIni('launcher-context')or{}).environment}
local ui,started,requested,halted
local beforeDraw,afterDraw,beforeWait,frameError
api.addMainMenuButton('Run placement preview native checks',function()requested=true end)

local function equal(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not equal(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local function encoded(value)
    if type(value)=='boolean'then return value and 1 or 0 end
    if type(value)~='table'then return value end
    local result={};for key,item in pairs(value)do result[key]=encoded(item)end;return result
end
local function write()assert(api.writeIni('results',encoded(out)))end
local function invoke(fn)local ok,why=xpcall(fn,tostring);if not ok then frameError=why end end
api.wrap('BATTLE_DRAW',function(next,...)
    if beforeDraw then local fn=beforeDraw;beforeDraw=nil;invoke(fn)end
    local value=next(...)
    if afterDraw then local fn=afterDraw;afterDraw=nil;invoke(fn)end
    return value
end,-200)
api.wrap('BATTLE_WAIT',function(next,...)
    if beforeWait then local fn=beforeWait;beforeWait=nil;invoke(fn)end
    return next(...)
end,-300)
local function frame(pre,post)
    beforeDraw=pre;afterDraw=post;frameError=nil
    api.drawTestField()
    assert(not frameError,frameError)
    assert(not beforeDraw and not afterDraw,'Native DRAW callback did not run')
end
local function mutate(fn)beforeWait=fn;frame();assert(not beforeWait,'Native WAIT callback did not run')end
local function modelActor(id)
    for _,actor in ipairs(ui.scenario.units)do if actor.id==id then return actor end end
end
local function healthy()
    local yes,why=ui.runtime:ready(ui.scenario);assert(yes,why)
    local state=assert(api.testFieldState());assert(state.complete and #state.issues==0)
    local actors=0
    for _,row in ipairs(state.units)do
        if row.kind=='actor'then actors=actors+1
        else assert(row.kind=='structure'and row.provenanceVerified,'Unexplained non-roster actor')end
    end
    assert(actors==#ui.scenario.units,'Model/native actor count differs')
    return state
end
local function scene(terrain,godTeam)
    local s=M.new();s.terrain=terrain;s.minimumWidth=70;s.size='Minimum width'
    local first=M.isWaterTerrain(terrain)and assert(api.findMonster('Triton'))or 13
    local second=M.isWaterTerrain(terrain)and first or 953
    local a=M.add(s,first,assert(ui.catalog.byId[first]).name,1,8,9)
    local b=M.add(s,second,assert(ui.catalog.byId[second]).name,2,24,9)
    local god
    if godTeam then god=M.add(s,207,assert(ui.catalog.byId[207]).name,godTeam,12,4)end
    ui.phase='menu';ui.snapshot=nil;ui.context=nil;ui.copyTemplate=nil;ui.moving=nil
    ui.noticeText=nil;ui.previewInfo=nil;ui.lastPreviewInfo=nil;ui.scenario=s
    local ok,why=ui.runtime:build(s,true);assert(ok,why)
    ui.phase='prepare';ui.native=true;ui.team=godTeam or 1;ui.selected=godTeam and 207 or first
    healthy();frame();frame()
    return s,a,b,god
end
local function adopt(s)ui.scenario=s;healthy();return s end
local function free(unit,w,h,avoid)
    for x=1,ui.runtime.width-w-1 do for y=1,19-h do
        local empty=not avoid or x~=avoid.x or y~=avoid.y
        for dx=0,w-1 do for dy=0,h-1 do
            if api.battleUnitAt(x+dx,y+dy)>=0 or api.battleObjectAt(x+dx,y+dy)>=0 then empty=false end
        end end
        if empty and api.battleCanStand(unit,x,y,0)then return x,y end
    end end
    error('No object-free native footprint in this fixture')
end
local function counts(row)
    local result={version=row.version or'legacy',cells=#row.cells,partial=row.partial and 1 or 0,
        clear=0,occupied=0,terrain=0,out_of_bounds=0,unknown=0,requires_instance=0}
    for _,cell in ipairs(row.cells)do
        result[cell.status]=(result[cell.status]or 0)+1
        if cell.objectDecision=='requires_instance'then result.requires_instance=result.requires_instance+1 end
    end
    return result
end
local function sameField(before,after)
    return before.width==after.width and equal(before.units,after.units)and equal(before.grid,after.grid)
end
local function rejection(monster,team,x,y,label)
    local frozen=M.encode(ui.scenario,ui.catalog.mods);local native=healthy()
    local ok,why=ui.runtime:add(ui.scenario,monster,team,x,y)
    assert(not ok and not ui.runtime.blocked,'Rejected placement was accepted or left recovery locked: '..tostring(why))
    assert(equal(frozen,M.encode(ui.scenario,ui.catalog.mods))and sameField(native,healthy()),'Refusal changed the existing model/native field')
    local name,path=ui.diag:export({fixture=label,expected='Intentional refusal with original field verified'},ui.runtime:snapshot(ui.scenario))
    assert(name,path);out[label]={reason=tostring(why),diagnostic=name,model_and_native_unchanged=1}
end
local function test(name,fn)
    if halted then return end
    if only~='all'and not baseline and not(','..only..','):find(','..name..',',1,true)then return end
    if baseline and name~='guard_team1'and name~='guard_team2'then return end
    out.progress={stage=name};write()
    local ok,why=xpcall(fn,tostring)
    beforeDraw=nil;afterDraw=nil;beforeWait=nil
    if ui then
        ui.phase='menu';local closed,detail=ui.runtime:close()
        if not closed then ok=false;why=tostring(why)..'; cleanup '..tostring(detail)end
        local life=assert(api.testFieldLifecycle())
        if life.open or not life.complete or #life.issues>0 then ok=false;why=tostring(why)..'; lifecycle cleanup unverified'end
        out[name..'_cleanup']={complete=life.complete and 1 or 0,open=life.open and 1 or 0,issues=#life.issues}
    end
    out[name]={status=ok and'PASS'or'FAIL',detail=ok and'Actual native preview/placement and verified cleanup; visible observations separate'or tostring(why)}
    halted=not ok;write()
end

local function guard(team,visible)
    local s,_,_,god=scene(20,team);local r=ui.runtime;local source=r.live[god.id]
    local foot=assert(api.testFieldFootprint(207,source));assert(foot.width==3 and foot.height==3)
    local target,sourceState;local scanned,accepted=0,0
    frame(nil,function()
        sourceState=healthy();local tried={}
        for _,cell in ipairs(sourceState.grid)do
            if cell.object>=0 then
                for dx=0,2 do for dy=0,2 do
                    local x,y=cell.x-dx,cell.y-dy;local key=x..':'..y
                    if not tried[key]and x>=0 and y>=0 and x+3<=r.width and y+3<=20 then
                        tried[key]=true;scanned=scanned+1;local freeActors,covered=true,0
                        for ox=0,2 do for oy=0,2 do
                            if api.battleUnitAt(x+ox,y+oy)>=0 then freeActors=false end
                            if api.battleObjectAt(x+ox,y+oy)>=0 then covered=covered+1 end
                        end end
                        if freeActors and covered>0 and api.battleCanStand(source,x,y,0)then
                            local actual=assert(api.testFieldPlacementPreflight(207,x,y,source,true))
                            local detail=counts(actual)
                            if detail.clear==9 then
                                accepted=accepted+1
                                if not target or covered>target.covered_cells then target={x=x,y=y,object=cell.object,covered_cells=covered}end
                            end
                        end
                    end
                end end
            end
        end
    end)
    assert(target,'No actor-free object-intersecting native-accepted God footprint in Guard Tower')
    local removed,remaining=r:remove(s,god);assert(removed,remaining);s=adopt(remaining)
    assert(r:retirementVerified(source),'Scan-source God was not permanently retired')
    local frozen=M.encode(s,ui.catalog.mods);local native=healthy();local created=api.testFieldLifecycle().createdCount
    local raw,plan
    frame(nil,function()
        raw=assert(api.testFieldPlacementPreflight(207,target.x,target.y))
        plan=ui:placementPreview(target.x,target.y)
        local detail=counts(raw)
        assert(#raw.cells==9 and raw.partial and detail.occupied==0 and detail.out_of_bounds==0)
        if baseline then assert(raw.version==nil and detail.terrain==target.covered_cells,'Baseline did not reproduce its conservative raw object warning')
        else assert(raw.version==2 and detail.unknown==target.covered_cells and detail.requires_instance==detail.unknown and detail.terrain==0,'Revision 2 did not distinguish unverified template passability')end
        assert(plan.unknown>0 and plan.blocked==0 and plan.outside==0 and plan.partial)
        assert(equal(frozen,M.encode(s,ui.catalog.mods))and sameField(native,healthy())and api.testFieldLifecycle().createdCount==created,'Read-only preview changed actors or the scenario')
        detail.covered_cells=target.covered_cells;detail.scanned_anchors=scanned;detail.native_accepted_anchors=accepted
        out['guard_raw_team'..team]=detail
    end)
    if visible then
        -- Leave the exact production editor open. The task owner observes mouse
        -- actions separately; entering this loop is not a visible-test PASS.
        mutate(function()assert(api.setTestFieldZoom(0.8))end)
        mutate(function()
            local viewport=assert(api.testFieldViewport());local sx,sy=api.battleCellToScreen(target.x+1,target.y+1)
            assert(api.panTestFieldViewport(viewport.x+viewport.width/2-sx,viewport.y+viewport.height/2-sy))
        end)
        frame(nil,function()
            local sx,sy=api.battleCellToScreen(target.x+1,target.y+1)
            out.visible_target={team=team,monster=207,x=target.x,y=target.y,width=3,height=3,covered_cells=target.covered_cells,
                screen_center_x=sx,screen_center_y=sy,scope='Discovered empty target; selected God in production editor, no screenshot equivalence'}
        end)
        out.ready={status='READY',scope='Production editor remains open for separately observed hover/placement checks'};write()
        ui:prepare(false,true)
        out.visible_return={editor_closed=not r.open and 1 or 0,scope='Mouse and visual observations are reported separately'}
        return
    end
    local ok,new,placed=r:add(s,207,team,target.x,target.y);assert(ok,new);s=adopt(new)
    local placedId=r.live[placed.id]
    for dx=0,2 do for dy=0,2 do assert(api.battleUnitAt(target.x+dx,target.y+dy)==placedId,'God interior hit differs from its model footprint')end end
    out['guard_placement_team'..team]={monster=207,team=team,x=target.x,y=target.y,width=3,height=3,
        covered_cells=target.covered_cells,source_retired=1,actual_add_verified=1,read_only_preview=1,scope='Dynamically discovered fixture; not the user screenshot frame'}
    if not baseline then
        local x,y=free(placedId,3,3);ui.moving=placed
        frame(nil,function()local move=ui:placementPreview(x,y);assert(move.clear==9 and move.unknown==0 and move.blocked==0)end)
        assert(r:move(placed,x,y));ui.moving=nil;healthy()
        out['guard_move_team'..team]={x=x,y=y,verified=1}
        local frozen=M.encode(s,ui.catalog.mods);local native=healthy();local projected=0
        for index,zoom in ipairs({0.1,0.5,1,1.5,2})do
            mutate(function()assert(api.setTestFieldZoom(zoom))end)
            mutate(function()
                local viewport=assert(api.testFieldViewport());local sx,sy=api.battleCellToScreen(placed.x+1,placed.y+1)
                assert(api.panTestFieldViewport(viewport.x+viewport.width/2-sx,viewport.y+viewport.height/2-sy))
            end)
            frame(nil,function()
                ui.moving=placed;local plan=ui:placementPreview(placed.x,placed.y);ui.moving=nil
                assert(plan.clear==9 and #plan.cells==9 and plan.blocked==0 and plan.unknown==0)
                for _,cell in ipairs(plan.cells)do
                    local sx,sy=api.battleCellToScreen(cell.x,cell.y);local cx,cy=api.battleScreenToCell(sx,sy)
                    assert(cx==cell.x and cy==cell.y and api.battleUnitAt(cx,cy)==placedId)
                    assert(ui:unitAt(cx,cy).id==placed.id)
                    assert(math.abs(cell.screenX-sx)<0.01 and math.abs(cell.screenY-sy)<0.01)
                    projected=projected+1
                end
                assert(equal(frozen,M.encode(s,ui.catalog.mods))and sameField(native,healthy()))
                local view=assert(api.battleView())
                out['guard_team'..team..'_zoom'..index]={zoom=zoom,cell=view.cellSize,camera_x=view.cameraX,camera_y=view.cameraY,cells=9}
            end)
        end
        out['guard_move_team'..team].zoom_pan_cells=projected
        -- A native structural gate is an actor blocker, never a passable object.
        local gate
        for _,row in ipairs(healthy().units)do if row.kind=='structure'and row.provenanceVerified then gate=row;break end end
        assert(gate and gate.anchorX and gate.anchorY,'No authenticated native gate in Guard Tower')
        frame(nil,function()
            local block=assert(api.testFieldPlacementPreflight(13,gate.anchorX,gate.anchorY));assert(counts(block).occupied==1 and not block.valid)
        end)
        rejection(13,team,gate.anchorX,gate.anchorY,'guard_gate_refusal_team'..team)
    end
end

api.wrap('MAIN_MENU_WAIT',function(next,...)
    local value=next(...)
    if started or(request.run and request.run.defer=='1'and not requested)then return value end
    started=true;ui=U.new(api);ui:ensureCatalog();ui.notice=function(self,text)self.message=text end
    if only=='visible'then
        local ok,why=xpcall(function()guard(1,true)end,tostring)
        if ui.runtime.open then local closed,detail=ui.runtime:close();if not closed then ok=false;why=tostring(why)..'; '..tostring(detail)end end
        local life=assert(api.testFieldLifecycle());assert(life.complete and not life.open and #life.issues==0)
        out.complete={status=ok and'PASS'or'FAIL',detail=tostring(why or'Visible editor loop returned and cleanup verified; visual observations separate')};write();return value
    end
    test('guard_team1',function()guard(1)end)
    test('guard_team2',function()guard(2)end)
    test('plain_copy_move_clear_zoom',function()
        local s,a,b=scene(0);local r=ui.runtime;local native=healthy()
        ui.selected=a.monster
        local x,y=free(r.live[a.id],1,1)
        frame(nil,function()
            local clear=ui:placementPreview(x,y);assert(clear.clear==1 and clear.blocked==0 and clear.unknown==0)
            local blocked=assert(api.testFieldPlacementPreflight(a.monster,a.x,a.y));assert(counts(blocked).occupied==1)
            local edge=assert(api.testFieldPlacementPreflight(207,r.width-1,19));assert(counts(edge).out_of_bounds==8 and #edge.cells==9)
        end)
        rejection(207,1,r.width-1,19,'plain_edge_refusal')
        local copied=M.copy(a);ui.copyTemplate=copied;ui.team=2
        frame(nil,function()local plan=ui:placementPreview(x,y);assert(plan.clear==1 and plan.partial)end)
        local ok,new,copy=r:add(s,copied.monster,2,x,y,copied);assert(ok,new);s=adopt(new);ui.copyTemplate=nil
        local copiedId=r.live[copy.id];local nx,ny=free(copiedId,1,1)
        assert(r:move(copy,nx,ny));healthy()
        local frozen=M.encode(s,ui.catalog.mods);native=healthy();local mapped=0
        for _,zoom in ipairs({0.1,0.5,1,1.5,2})do
            mutate(function()assert(api.setTestFieldZoom(zoom))end)
            mutate(function()
                local viewport=assert(api.testFieldViewport());local sx,sy=api.battleCellToScreen(copy.x,copy.y)
                assert(api.panTestFieldViewport(viewport.x+viewport.width/2-sx,viewport.y+viewport.height/2-sy))
            end)
            frame(nil,function()
                local view=assert(api.battleView());local sx,sy=api.battleCellToScreen(copy.x,copy.y)
                local cx,cy=api.battleScreenToCell(sx,sy)
                assert(cx==copy.x and cy==copy.y and api.battleUnitAt(cx,cy)==copiedId and ui:unitAt(cx,cy).id==copy.id)
                ui.moving=copy;local plan=ui:placementPreview(copy.x,copy.y);ui.moving=nil
                assert(#plan.cells==1 and plan.cells[1].status=='clear')
                assert(math.abs(plan.cells[1].screenX-sx)<0.01 and math.abs(plan.cells[1].screenY-sy)<0.01)
                assert(equal(frozen,M.encode(s,ui.catalog.mods))and sameField(native,healthy()))
                mapped=mapped+1;out['plain_zoom'..mapped]={zoom=zoom,cell=view.cellSize,camera_x=view.cameraX,camera_y=view.cameraY,screen_x=sx,screen_y=sy}
            end)
        end
        local removed,remaining=r:remove(s,copy);assert(removed,remaining);s=adopt(remaining);assert(r:retirementVerified(copiedId))
        assert(Clear.run(ui));s=ui.scenario;assert(#s.units==0 and #healthy().units==0)
        for _,team in ipairs({1,2})do local ok,new=r:add(s,13,team,team==1 and 8 or 24,9);assert(ok,new);s=adopt(new)end
        out.plain_lifecycle={copy_to_other_team=1,move=1,delete=1,clear_empty=1,add_both_after_clear=1,zoom_pan_roundtrips=mapped}
    end)
    test('forest_blocked',function()
        local s,a=scene(2);local target
        for _,cell in ipairs(healthy().grid)do if cell.object>=0 and api.battleUnitAt(cell.x,cell.y)<0 then target=cell;break end end
        assert(target,'No native Forest object fixture')
        frame(nil,function()
            local row=assert(api.testFieldPlacementPreflight(a.monster,target.x,target.y));assert(row.version==2 and counts(row).terrain==1)
            ui.selected=a.monster;local plan=ui:placementPreview(target.x,target.y);assert(plan.blocked==1 and plan.unknown==0)
        end)
        rejection(a.monster,1,target.x,target.y,'forest_object_refusal')
    end)
    test('footprint_formations',function()
        for _,kind in ipairs({{13,1},{206,2},{207,3}})do
            local s,a=scene(0);local r=ui.runtime;local monster,size=kind[1],kind[2]
            local foot=assert(api.testFieldFootprint(monster));assert(foot.width==size and foot.height==size)
            -- God is unique. This fixture explicitly opts into the existing
            -- duplicate-unique mode; preview must never bypass that policy.
            assert(r:setMultipleUnique(s,true))
            ui.selected=monster;ui.formation=2;ui.n=2
            local x,y=free(r.live[a.id],size*2,size);local plan
            frame(nil,function()
                plan=ui:placementPreview(x,y)
                assert(#plan.anchors==2 and #plan.cells==size*size*2 and plan.clear==#plan.cells and plan.blocked==0 and plan.unknown==0)
                assert(plan.anchors[2].x-plan.anchors[1].x==size,'Formation spacing did not use the actual full footprint')
            end)
            local placed={}
            for index,anchor in ipairs(plan.anchors)do
                local ok,new,u=r:add(s,monster,index,anchor.x,anchor.y);assert(ok,new);s=adopt(new);placed[#placed+1]=u
                for dx=0,size-1 do for dy=0,size-1 do assert(api.battleUnitAt(u.x+dx,u.y+dy)==r.live[u.id])end end
            end
            for _,u in ipairs(placed)do local id=r.live[u.id];local ok,new=r:remove(s,u);assert(ok,new);s=adopt(new);assert(r:retirementVerified(id))end
            assert(#s.units==2);ui.formation=1;ui.n=1
            out['formation_size'..size]={monster=monster,width=size,height=size,actors=2,teams=2,preview_cells=#plan.cells,actual_placement_and_delete=1,multiple_unique_explicitly_enabled=1}
            assert(r:close())
        end
    end)
    local function water(terrain)
        local s,a=scene(terrain);local r=ui.runtime;local unit=r.live[a.id];local foot=assert(api.testFieldFootprint(a.monster,unit))
        local env=assert(api.testFieldEnvironmentState())
        assert(env.terrain==terrain and env.atSea==(terrain==27 or terrain==68),'Wrong native water/coastal context')
        local x,y=free(unit,foot.width,foot.height)
        frame(nil,function()
            ui.selected=a.monster;local plan=ui:placementPreview(x,y)
            assert(plan.clear==foot.width*foot.height and plan.blocked==0 and plan.unknown==0 and plan.partial)
        end)
        local ok,new,u=r:add(s,a.monster,2,x,y);assert(ok,new);s=adopt(new)
        local removed,remaining=r:remove(s,u);assert(removed,remaining);adopt(remaining)
        out['water_detail'..terrain]={terrain=terrain,name=M.terrainNames[terrain],monster=a.monster,template_preview_clear=1,independent_add_delete=1,transport_workflow_tested=0}
    end
    test('sea_independent',function()water(27)end)
    test('deep_independent',function()water(68)end)
    test('coastal_independent',function()water(78)end)
    out.progress={stage='complete'}
    out.complete={status=halted and'FAIL'or'PASS',scope='Opt-in isolated native preview/placement; no screenshot-frame equivalence or visible mouse acceptance'}
    write();return value
end,-100)
