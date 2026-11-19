-- Offline contracts and geometry only. No native card, sprites or game are simulated.
local cache={}
function require(name)
    if not cache[name] then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))() end
    return cache[name]
end
local P=require('sandbox.preview');local M=require('sandbox.model');local U=require('sandbox.ui')
assert(loadfile('tests/inspector_probe.lua'))
local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function fixture()
    local state={x=200,y=200,cellX=6,cellY=6,hit=-1,buttons=0,width=3,height=3,focus=false,queries={},adds={},preflightVersion=2,cellSize=10,cameraX=0,cameraY=0}
    local api={get=function(key)
        if key=='screenW'then return 800 elseif key=='screenH'then return 600 elseif key=='uiPointerX'then return state.x elseif key=='uiPointerY'then return state.y
        elseif key=='unitHp'then return 100 elseif key=='mouseButtons'then return state.buttons elseif key=='modLastIndex'then return -1 end;return 0
    end,set=function()end,readIni=function()end,writeIni=function()return true end,listIni=function()return {} end,
        wrap=function()return true end,observe=function()end,
        setTestFieldTextFocus=function(on)state.focus=on;return true end,takeTestFieldTextEvents=function()return {focused=state.focus,events={}}end,
        battleScreenToCell=function()return state.cellX,state.cellY end,battleUnitAt=function()return state.hit end,
        testFieldFootprint=function(monster,unit)return {monster=monster,unit=unit,width=state.width,height=state.height,source=unit and 'native_unit' or 'native_monster_rules',exact=true,anchor='positive_xy'}end,
        testFieldPlacementPreflight=function(monster,x,y,unit,ignoreSelf)
            state.queries[#state.queries+1]={monster=monster,x=x,y=y,unit=unit,ignoreSelf=ignoreSelf}
            local cells={}
            for dy=0,state.height-1 do for dx=0,state.width-1 do local cx,cy=x+dx,y+dy
                local status=(cx<0 or cx>=30 or cy<0 or cy>=20) and 'out_of_bounds' or 'clear'
                if state.cellStatus then status=state.cellStatus(cx,cy,status)end
                cells[#cells+1]={x=cx,y=cy,status=status,screenX=(cx+0.5)*state.cellSize+state.cameraX,screenY=(cy+0.5)*state.cellSize+state.cameraY}
            end end
            return {version=state.preflightVersion,width=state.width,height=state.height,partial=true,source='native_grid',cells=cells}
        end}
    local u=U.new(api);u.phase='prepare';u.native=true;u.selected=206;u.scenario=M.new();u.runtime={open=true,width=30,live={},objects={}}
    u.catalog={byId={[206]={name='Seraph',id=206}},mods={},testFieldTerrains={}}
    u.runtime.add=function(_,s,monster,team,x,y)
        state.adds[#state.adds+1]={x=x,y=y,monster=monster,team=team};return true,M.copy(s)
    end
    return u,state,api
end
test('formations tile the whole footprint without intersecting copies',function()
    for _,size in ipairs({{1,1},{2,2},{3,3},{1,3},{3,1}})do
        for _,kind in ipairs({'Single','Horizontal Row','Vertical Row','Square'})do
            local anchors=P.anchors(kind,3,4,5,size[1],size[2]);local used={}
            for _,cell in ipairs(P.cells(anchors,size[1],size[2]))do
                local key=cell.x..':'..cell.y;assert(not used[key],'formation footprints overlap');used[key]=true
            end
            local columns,rows=P.shape(kind,3);assert(#anchors==columns*rows)
            local width,height=P.span(kind,3,size[1],size[2]);assert(width==columns*size[1] and height==rows*size[2])
        end
    end
    assert(not P.anchors('Square',2,1,1,nil,3) and #P.cells({},0,0)==0,'unknown size was invented')
end)
test('drag grid uses footprint and full formation span in both directions',function()
    local x,y=P.snap(12,13,{x=10,y=10},3,3);assert(x==10 and y==13)
    x,y=P.snap(9,9,{x=10,y=10},3,3);assert(x==7 and y==7)
    local sx,sy=P.span('Horizontal Row',3,3,2);assert(sx==9 and sy==2)
    x,y=P.snap(18,11,{x=10,y=10},sx,sy);assert(x==10 and y==10)
end)
test('preview draws every native-footprint cell and exposes partial validity',function()
    local u,state=fixture();state.cellStatus=function(x,y,status)if x==6 and y==6 then return 'occupied'elseif x==7 and y==6 then return 'terrain'end;return status end
    local plan=u:placementPreview(6,6)
    assert(#plan.cells==9 and plan.width==3 and plan.height==3 and plan.blocked==2 and plan.clear==7 and plan.partial)
    assert(plan.source=='native_monster_rules' and plan.label:find('partial'))
    plan=u:placementPreview(29,19);assert(plan.outside==8 and #plan.cells==9)
    assert(plan.cells[9].screenX==315 and plan.cells[9].screenY==215,'outside native projection was lost')
end)
test('missing preflight or footprint stays explicitly unknown without a new unit',function()
    local u,state,api=fixture();api.testFieldPlacementPreflight=nil
    local plan=u:placementPreview(6,6);assert(plan.unknown==9 and plan.partial and #state.adds==0)
    api.testFieldFootprint=nil;plan=u:placementPreview(6,6);assert(#plan.cells==0 and plan.label:find('unknown') and #state.adds==0)
    u.formation=2;assert(not u:placementAnchors(1,1),'unknown dimensions allowed overlapping formation spacing')
end)
test('Copy measures source geometry but never borrows instance terrain permissions on either target team',function()
    local u,state=fixture();u.copyTemplate={id=4,monster=206};u.runtime.live[4]=101
    for _,team in ipairs({1,2})do
        u.team=team;local plan=u:placementPreview(6,6);local query=state.queries[#state.queries]
        assert(plan.source=='native_unit' and query.unit==nil and query.ignoreSelf==false)
        assert(#state.adds==0 and u.runtime.live[4]==101)
    end
    u.moving=u.copyTemplate;u:placementPreview(6,6);local query=state.queries[#state.queries]
    assert(query.unit==101 and query.ignoreSelf==true,'Move lost its own instance/self-occupancy authority')
end)
test('revision 2 retains hard blockers and explicit unknown template passability',function()
    local u,state,api=fixture();local original=api.testFieldPlacementPreflight
    api.testFieldPlacementPreflight=function(...)
        local row=original(...)
        row.cells[1].status='unknown';row.cells[1].reason='template_object_passability_unverified';row.cells[1].objectDecision='requires_instance'
        row.cells[2].status='terrain';row.cells[3].status='occupied';row.cells[4].status='out_of_bounds'
        return row
    end
    local plan=u:placementPreview(6,6)
    assert(plan.unknown==1 and plan.blocked==2 and plan.outside==1 and plan.clear==5 and plan.partial)
    assert(plan.cells[1].objectDecision=='requires_instance' and plan.cells[1].reason=='template_object_passability_unverified')
    assert(plan.label:find('native placement decides.',1,true) and #state.adds==0)
end)
test('legacy template object warnings become unknown without hiding actor or edge rejection',function()
    for _,version in ipairs({false,1,3})do
        local u,state=fixture();state.preflightVersion=version or nil
        state.cellStatus=function(x,y,status)if x==6 and y==6 then return'terrain'elseif x==7 and y==6 then return'occupied'elseif x==8 and y==6 then return'out_of_bounds'end;return status end
        local plan=u:placementPreview(6,6)
        assert(plan.unknown==1 and plan.blocked==1 and plan.outside==1 and plan.clear==6 and plan.partial)
        assert(plan.cells[1].status=='unknown' and plan.cells[1].reason=='legacy_object_passability_unverified' and #state.adds==0)
    end
end)
test('legacy actual Move keeps instance blockers instead of turning them optimistic',function()
    local u,state=fixture();state.preflightVersion=nil;u.moving={id=4,monster=206};u.runtime.live[4]=101
    state.cellStatus=function(x,y,status)if x==6 and y==6 then return'terrain'end;return status end
    local plan=u:placementPreview(6,6)
    assert(plan.blocked==1 and plan.unknown==0 and state.queries[1].unit==101 and state.queries[1].ignoreSelf)
end)
test('unknown terrain does not change footprint-aware formation anchors or native projections across zoom and pan',function()
    for _,view in ipairs({{30,0,38},{12,-173,180},{3,2,250}})do
      for _,size in ipairs({{1,1},{2,2},{3,3},{1,3}})do
        local u,state=fixture();state.cellSize,state.cameraX,state.cameraY=table.unpack(view)
        state.width,state.height=size[1],size[2]
        u.formation=2;u.n=2;state.cellStatus=function()return'unknown'end
        local plan=u:placementPreview(1,5)
        assert(#plan.anchors==2 and #plan.cells==2*size[1]*size[2] and plan.unknown==#plan.cells and plan.partial)
        assert(plan.anchors[1].x==1 and plan.anchors[2].x==1+size[1] and plan.anchors[2].y==5)
        for _,cell in ipairs(plan.cells)do
            assert(cell.screenX==(cell.x+0.5)*view[1]+view[2] and cell.screenY==(cell.y+0.5)*view[1]+view[3])
        end
        assert(#state.adds==0,'Preview allocated an actor while deciding terrain')
      end
    end
end)
test('malformed preflight cell rows remain unknown without a preview exception or actor allocation',function()
    local u,state,api=fixture();api.testFieldPlacementPreflight=function()return{version=2,width=3,height=3,cells='incomplete'}end
    local plan=u:placementPreview(6,6);assert(plan.unknown==9 and plan.partial and #state.adds==0)
end)
test('formation execution and preview use identical footprint-aware anchors',function()
    local u,state=fixture();u.formation=2;u.n=3
    local plan=u:placementPreview(1,5);assert(#plan.anchors==3 and #plan.cells==27)
    u:dispatch({place=true,x=1,y=5});assert(#state.adds==3)
    for i,anchor in ipairs(plan.anchors)do assert(state.adds[i].x==anchor.x and state.adds[i].y==anchor.y)end
    assert(state.adds[1].x==1 and state.adds[2].x==4 and state.adds[3].x==7)
end)
test('large drag schedules each footprint tile once until released',function()
    local u,state=fixture();u:input(2);assert(u.pending.x==6 and u.pending.y==6);u.pending=nil
    state.cellX=7;state.cellY=7;u:input(2);assert(not u.pending)
    state.cellX=9;u:input(2);assert(u.pending.x==9 and u.pending.y==6);u.pending=nil
    state.cellX=6;u:input(2);assert(not u.pending,'revisited footprint retried during one held gesture')
    u:input(0);u:input(2);assert(u.pending.x==6,'a new intentional gesture was suppressed')
end)
test('existing native interior hit has priority over placement and names the exact copy',function()
    local u,state=fixture();local a=M.add(u.scenario,206,'Seraph',1,4,4);local b=M.add(u.scenario,206,'Seraph',2,20,4)
    u.runtime.live[a.id]=101;u.runtime.live[b.id]=102;state.hit=102;state.cellX=21;state.cellY=5
    u:input(2);assert(u.context and u.context.unit.id==b.id and not u.pending)
    local called
    u.runtime.inspect=function(_,s,unit)called=unit;assert(u.inNativeMenu and not state.focus);return true,M.copy(s),{mode='read_only',changed=false}end
    u:dispatch('context:Inspect');assert(called==b and not u.inNativeMenu and u.releaseBarrier)
end)
test('Inspect close owns both held tails and failure preserves the model',function()
    local u,state=fixture();local unit=M.add(u.scenario,206,'Seraph',1,4,4);u.runtime.live[unit.id]=101
    local before=u.scenario;u.runtime.inspect=function()return false,'native inspect refused'end
    local notice;u.notice=function(_,text)notice=text end
    assert(not u:inspect(unit) and u.scenario==before and notice=='native inspect refused')
    assert(u:input(3) and not u.pending);assert(u:input(2) and not u.pending);assert(u:input(0) and not u.pending)
    state.hit=-1;u:input(2);assert(u.pending and u.pending.place,'new gesture after Inspect did not resume')
end)
local function repairFixture()
    local u,state,api=fixture();local god=M.add(u.scenario,407,'God Emperor',1,4,4)
    god.baseline={known={}};god.spells={};god.items={'Saved item'}
    for i=1,10 do local key=i..':Spell '..i;god.baseline.known[i]=key;god.spells[i]=key end
    api.spellInfo=function(id)return {path=id<=6 and 1 or 2}end
    u.runtime.recovery=M.copy(u.scenario);u.runtime.spellRepairProblems={[god.id]={}}
    u.runtime.spellRepairCandidates=function()return {{model_id=god.id,name=god.name,known=M.copy(god.baseline.known),spells=M.copy(god.spells),
        schools={{path=1,name='Solar',allowance=4,selected_count=6},{path=2,name='Other',allowance=4,selected_count=4}}}}end
    return u,state,api,god
end
test('repair edits a copy only and Cancel keeps original invalid evidence',function()
    local u,_,_,god=repairFixture();local before=u.scenario;local verified=false
    u.runtime.repairSpellSelection=function()verified=true;error('cancel attempted verification')end
    local steps={101,101,999,999};local index=0
    u.menu=function()index=index+1;return assert(steps[index])end
    assert(not u:repairSpells() and not verified and u.scenario==before and #god.spells==10 and #u.runtime.recovery.units[1].spells==10)
end)
test('repair verifies only explicit selected spells and keeps old report/recovery',function()
    local u,_,_,god=repairFixture();local old=u.scenario;local report={preserved=true};u.report.result=report
    local steps={101,101,102,999,1};local index=0
    u.menu=function(_,_,rows)
        index=index+1
        if index==1 then local found=false;for _,row in ipairs(rows)do if row[2]:find('Original Solar: 6 selected / native allowance 4',1,true)then found=true end end;assert(found)end
        return assert(steps[index])
    end
    u.runtime.repairSpellSelection=function(_,candidate)
        assert(candidate~=old and #candidate.units[1].spells==8 and #god.spells==10)
        assert(candidate.units[1].spells[1]=='3:Spell 3' and #candidate.units[1].baseline.known==10 and candidate.units[1].items[1]=='Saved item')
        return true,candidate,{name='repaired-session-1',path='isolated/repaired-session-1.ini'}
    end
    assert(u:repairSpells() and u.scenario~=old and #u.snapshot.units[1].spells==8 and u.report.result==report)
    assert(#u.runtime.recovery.units[1].spells==10 and u.message:find('repaired%-session%-1'))
end)
test('invalid repaired copy is rejected without silently changing any spell',function()
    local u,_,_,god=repairFixture();local old=u.scenario;local checked=0;local notice
    u.runtime.repairSpellSelection=function(_,candidate)checked=checked+1;assert(#candidate.units[1].spells==10);return false,'Solar 6 exceeds native allowance 4'end
    u.notice=function(_,text)notice=text end
    local steps={1,999};local index=0;u.menu=function()index=index+1;return assert(steps[index])end
    assert(not u:repairSpells() and checked==1 and u.scenario==old and #god.spells==10 and notice:find('Solar 6'))
end)
test('newly diagnosed second caster can be repaired without losing first copy edits',function()
    local u,_,_,god=repairFixture();local second=M.add(u.scenario,god.monster,god.name,2,20,4,god)
    u.runtime.recovery=M.copy(u.scenario);local verifies=0
    u.runtime.spellRepairCandidates=function()
        local unit=verifies==0 and god or second
        return {{model_id=unit.id,name=unit.name,known=M.copy(unit.baseline.known),spells=M.copy(unit.spells),
            schools={{path=1,name='Solar',allowance=4,selected_count=6},{path=2,name='Other',allowance=4,selected_count=4}}}}
    end
    local steps={101,101,102,999,1,101,101,102,999,1};local index=0
    u.menu=function()index=index+1;return assert(steps[index])end;u.notice=function()end
    u.runtime.repairSpellSelection=function(_,candidate)
        verifies=verifies+1;assert(#candidate.units[1].spells==8,'first explicit edit was discarded')
        if verifies==1 then assert(#candidate.units[2].spells==10);return false,'Second caster also exceeds allowance'end
        assert(#candidate.units[2].spells==8);return true,candidate,{name='repaired-two-casters'}
    end
    assert(u:repairSpells() and verifies==2 and #u.scenario.units[1].spells==8 and #u.scenario.units[2].spells==8)
    assert(#god.spells==10 and #second.spells==10 and #u.runtime.recovery.units[2].spells==10)
end)
test('failed loaded scenario repair targets its copy while healthy current army stays intact',function()
    local u,_,_,god=repairFixture();local bad=M.copy(u.scenario);local healthy=M.new();M.add(healthy,13,'Spearman',1,6,6)
    u.scenario=healthy;u.runtime.recovery=M.copy(healthy);u.runtime.spellRepairScenario=bad
    local diagnosis=u.runtime.spellRepairCandidates
    u.runtime.spellRepairCandidates=function(_,candidate)
        assert(candidate~=bad and candidate.units[1].monster==god.monster and #candidate.units[1].spells==10,'healthy army was mistaken for the failed loaded scene')
        return diagnosis()
    end
    u.runtime.repairSpellSelection=function()error('Cancel must not build or commit a repair')end
    u.menu=function()return 999 end
    assert(not u:repairSpells() and u.scenario==healthy and #bad.units[1].spells==10 and u.runtime.recovery.units[1].monster==13)
end)
test('diagnostics label cached map hover and reject another field generation',function()
    local u,state=fixture();u.runtime.generation=7
    local plan=u:placementPreview(6,6);assert(plan.fieldGeneration==7 and plan.anchorX==6 and plan.anchorY==6)
    u.previewInfo=plan;u.lastPreviewInfo=plan;local context
    u.runtime.snapshot=function()return {} end;u.diag.export=function(_,row)context=row;return 'test-diagnostic','isolated/test-diagnostic.ini'end
    u.notice=function()end
    u:exportDiagnostics();assert(context.preview_snapshot=='current' and context.preview_width==3 and context.preview_partial==1)
    state.x=400;state.y=580 -- Export button: current map hover is no longer true, even before another draw.
    u:exportDiagnostics();assert(context.preview_snapshot=='last map hover' and context.preview_monster==206 and context.preview_field_generation==7)
    assert(context.preview_anchor_x==6 and context.preview_anchor_y==6 and u.lastPreviewInfo==plan)
    u.previewInfo=nil;u:exportDiagnostics();assert(context.preview_snapshot=='last map hover')
    u.runtime.generation=8;u:exportDiagnostics()
    assert(context.preview_snapshot=='unknown' and context.preview_width=='unknown' and context.preview_anchor_x=='unknown' and context.preview_partial==1)
end)
print(count..' offline preview/Inspect/repair checks passed; native footprint, card and spells require real-game verification')
