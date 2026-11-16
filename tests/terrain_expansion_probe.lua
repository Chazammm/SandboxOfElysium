-- Explicit private real-game module. The launcher/test driver must invoke run;
-- normal Sandbox startup neither loads this module nor enables candidate maps.
local Probe={}
function Probe.run(api,options)
    options=options or {}
    local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local D=require('sandbox.diagnostics');local Report=require('sandbox.report')
    local catalog=C.read(api)
    local cycles=math.max(0,math.min(2,math.floor(tonumber(options.cycles)or 2)))
    local result={environment={scope='Actual isolated CoE5 native API; neutral Elysium test fields',candidate_build=options.candidateBuild and 1 or 'unknown',
        requested_fights_per_terrain=cycles,campaign_equivalence='Seasons, climate gradients, neighbors, enchantments and faction/world effects are not reproduced or claimed'}}
    local output=options.output or 'terrain-expansion-results'
    local rows={{id=12,name='Mountains',ground=0,tag='mountain'},{id=107,name='Swamp',ground=5,tag='swamp'},{id=117,name='Desert',ground=4,tag='desert'}}
    if catalog.testFieldTerrains[115]then rows[#rows+1]={id=115,name='Jungle',ground=2,requiredFlag=0x800000000000}end
    if options.includeBaseline then table.insert(rows,1,{id=2,name='Forest',ground=0,tag='forest'});table.insert(rows,1,{id=0,name='Plain',ground=0})end
    local selected={};for id in tostring(options.only or ''):gmatch('[^,%s]+')do selected[tonumber(id) or id]=true end
    local activeRuntime,fighting,movements=nil,false,0
    local steps={}
    local function save()assert(api.writeIni(output,result))end
    local function world()
        local state={}
        for _,key in ipairs({'activePlayer','worldW','worldH','battleDelay'})do state[key]=tostring(api.get(key))end
        for _,key in ipairs({'squareTerrain','squareGround','squareTemperature','squareArmy','squareOwner','squareArmyOwner','squarePlane'})do state[key]=tostring(api.get(key,1,1))end
        state.teamA=tostring(api.get('slotTeam',0));state.teamB=tostring(api.get('slotTeam',24))
        for _,key in ipairs({'planeX','planeY','planeWidth','planeHeight'})do state[key]=tostring(api.get(key,0))end
        state.lastPlane=tostring(api.get('planeLastIndex'));return state
    end
    local function equal(a,b)
        if type(a)~=type(b)then return false end
        if type(a)~='table'then return a==b end
        for key,value in pairs(a)do if not equal(value,b[key])then return false end end
        for key in pairs(b)do if a[key]==nil then return false end end;return true
    end
    local function flat(row)
        local out={};for key,value in pairs(row or {})do
            if type(value)=='boolean'then out[key]=value and 1 or 0 elseif type(value)=='string' or type(value)=='number'then out[key]=value end
        end;return out
    end
    api.observe('BATTLE_ADVANCE_UNIT',function(unit)
        if fighting then steps[unit]={x=api.get('unitBattleX',unit),y=api.get('unitBattleY',unit)}end
    end,function(_,unit)
        local before=steps[unit]
        if fighting and before and (before.x~=api.get('unitBattleX',unit) or before.y~=api.get('unitBattleY',unit))then movements=movements+1 end
        steps[unit]=nil
    end)
    local function checked(r,scene,previous)
        local ok,state=r:check(scene,true,previous);assert(ok,tostring(state));return state
    end
    local function close(label,r,ids,beforeWorld)
        local ok,why=r:close();assert(ok,tostring(why))
        local life,reason=api.testFieldLifecycle();assert(life,tostring(reason))
        result[label..'_cleanup']=flat(life)
        assert(life.complete and not life.open and #life.issues==0,'native cleanup incomplete')
        assert(life.creationDepth==0 and life.uniqueOverrideDepth==0,'temporary creation state leaked')
        for _,id in ipairs(ids or {})do assert((api.get('unitHp',id)or 0)<=0,'owned actor remains alive after terrain cleanup')end
        for i,row in ipairs(life.beforeCleanup or {})do result[label..'_cleanup_before'..i]=flat(row)end
        for i,row in ipairs(life.afterCleanup or {})do result[label..'_cleanup_after'..i]=flat(row)end
        local after=world();result[label..'_world_after']=after
        assert(equal(beforeWorld,after),'borrowed public square/plane/world context changed')
        result[label..'_cleanup'].public_context_restored=1;save()
    end
    local function inspectEnvironment(label,row,r,scene)
        local state=assert(api.testFieldState());assert(state.complete and #state.issues==0)
        local summary={terrain=api.get('squareTerrain',1,1),ground=api.get('squareGround',1,1),temperature=api.get('squareTemperature',1,1),plane=api.get('squarePlane',1,1),
            width=r.width,height=20,objects=0,object_records=0,standable=0,blocked=0,occupancy_scope='Complete native field query before combat'}
        assert(summary.terrain==row.id and summary.ground==row.ground and summary.temperature==25 and summary.plane==0,'native terrain environment differs from validated neutral setup')
        local objects,grounds={},{}
        local unit=r.live[scene.units[1].id]
        for _,cell in ipairs(state.grid)do
            grounds[cell.ground]=(grounds[cell.ground]or 0)+1
            if cell.object>=0 then summary.objects=summary.objects+1;objects[cell.object]=true end
            if api.battleCanStand(unit,cell.x,cell.y,0)then summary.standable=summary.standable+1 else summary.blocked=summary.blocked+1 end
        end
        for id in pairs(objects)do
            summary.object_records=summary.object_records+1
            local monster=api.get('unitMonster',id)
            result[label..'_object'..summary.object_records]={native_id=id,monster=monster,name=api.get('monsterName',monster),hp=api.get('unitHp',id)}
        end
        for ground,count in pairs(grounds)do result[label..'_ground'..ground]={ground=ground,cells=count}end
        result[label..'_environment']=summary;save();return state
    end
    for _,row in ipairs(rows)do if not next(selected) or selected[row.id] or selected[row.name]then
        local label='terrain'..row.id;local beforeWorld=world();result[label..'_world_before']=beforeWorld
        local ok,why=xpcall(function()
            assert(api.get('terrainName',row.id)==row.name,'loaded terrain identity changed')
            local identity={id=row.id,name=row.name,batmap=api.get('terrain',row.id,'batmap')}
            for _,tag in ipairs({'desert','swamp','mountain','forest','water','ug','cave','walls','citadel','apcost'})do
                local value=api.get('terrain',row.id,tag);identity[tag]=type(value)=='boolean' and (value and 1 or 0) or value or 'unknown'
            end
            assert(identity.batmap==0,'non-general native battle map is unsupported')
            assert(identity.water==0 and identity.ug==0 and identity.cave==0 and identity.walls==0 and identity.citadel==0,'water/fort/cave/other-plane terrain refused')
            if row.requiredFlag then assert((api.get('terrainFlags',row.id)&row.requiredFlag)~=0,'required observed terrain flag missing')end
            if row.tag then assert(identity[row.tag]==1,'required native land identity flag missing')end
            result[label..'_identity']=identity
            assert(catalog.testFieldTerrains[row.id],'candidate build did not advertise this exact native terrain')
            local scene=M.new();scene.terrain=row.id
            local spear=api.findMonster('Spearman');local goblin=api.findMonster('Goblin')
            M.add(scene,spear,catalog.byId[spear].name,1,8,9);M.add(scene,goblin,catalog.byId[goblin].name,2,18,9)
            local seraph=M.add(scene,206,catalog.byId[206].name,1,10,4);local rider=M.add(scene,201,catalog.byId[201].name,2,22,4)
            local d=D.new(api);local r=R.new(api,catalog,d);activeRuntime=r
            local opened,reason=r:build(scene,true);assert(opened,tostring(reason));checked(r,scene)
            inspectEnvironment(label,row,r,scene)
            for _,large in ipairs({seraph,rider})do
                local id=r.live[large.id];local native=assert(api.testFieldUnitState(id));local size=large.monster==206 and 2 or 3
                assert(native.width==size and native.height==size and #native.occupied==size*size,'large native deployment footprint not verified')
                for _,cell in ipairs(native.occupied)do assert(api.battleUnitAt(cell.x,cell.y)==id,'large unit interior hit differs')end
                result[label..'_large'..size]={native_id=id,monster=large.monster,width=native.width,height=native.height,occupied_cells=#native.occupied,x=large.x,y=large.y}
                local accepted,nextScene=r:remove(scene,large);assert(accepted,tostring(nextScene));scene=nextScene
                assert((api.get('unitHp',id)or 0)<=0,'removed large fixture remains alive')
                for _,cell in ipairs(native.occupied)do assert(api.battleUnitAt(cell.x,cell.y)~=id,'removed large fixture still hit-tests')end
                checked(r,scene)
            end
            -- The large-placement fixture used a four-unit native deployment.
            -- Establish the final two-unit test roster's own native anchors
            -- before testing exact Save/Load/Reset; do not save a test-only edge
            -- move or anchors chosen for a different deployment roster.
            opened,reason=r:build(scene,true);assert(opened,tostring(reason));checked(r,scene)
            inspectEnvironment(label..'_two_roster',row,r,scene)
            local canonical=M.copy(scene)
            result[label..'_fixture_deployment']={roster_units=#scene.units,
                scope='Explicit native deployment of the final two-unit test roster; these observed anchors are the exact persistence reference'}
            for i,unit in ipairs(scene.units)do result[label..'_canonical_unit'..i]={model_id=unit.id,monster=unit.monster,team=unit.team,x=unit.x,y=unit.y}end
            local first=scene.units[1];local native=r.live[first.id];local moved=false
            for y=0,19 do for x=0,r.width-1 do
                if api.battleUnitAt(x,y)<0 and api.battleCanStand(native,x,y,0)then
                    local accepted=r:move(first,x,y);if accepted then moved=true;break end
                end
            end;if moved then break end end
            assert(moved,'no native valid placement found');checked(r,scene)
            local before=checked(r,scene);local blocked,objectCell=false,nil;local field=api.testFieldState()
            for _,cell in ipairs(field.grid)do
                if cell.object>=0 and api.battleUnitAt(cell.x,cell.y)<0 and not api.battleCanStand(native,cell.x,cell.y,0)then objectCell=cell;break end
            end
            if objectCell then
                local accepted=r:move(first,objectCell.x,objectCell.y);assert(not accepted and not r.blocked,'blocking terrain placement was accepted or unverified')
                checked(r,scene,before);blocked=true
            end
            local edge=r:move(first,-1,0);assert(not edge and not r.blocked);checked(r,scene,before)
            result[label..'_placement']={valid_move=1,blocking_object_tested=blocked and 1 or 0,outside_refused=1,
                obstacle_scope=blocked and 'Actual native blocking object refused; original unit unchanged' or 'No blocking object in this scatter; no obstacle-blocking claim for this run'}
            result[label..'_placement'].temporary_move_x=first.x;result[label..'_placement'].temporary_move_y=first.y
            local restored,restoreWhy=r:move(first,canonical.units[1].x,canonical.units[1].y);assert(restored,tostring(restoreWhy));checked(r,scene)
            assert(equal(M.encode(scene,catalog.mods),M.encode(canonical,catalog.mods)),'temporary placement test did not restore its original native anchors/configuration')
            result[label..'_placement'].native_anchor_restored_before_save=1
            result[label..'_placement'].persistence_scope='Temporary test move reverted; arbitrary moved cell is not the Save/Load reference; no user scenario was redeployed'
            local snapshot=M.copy(scene);local scenarioName=label..'-expansion-scenario'
            assert(api.writeIni(scenarioName,M.encode(snapshot,catalog.mods)))
            local loaded,loadWhy=M.decode(api.readIni(scenarioName),catalog,catalog.mods);assert(loaded,loadWhy)
            assert(equal(M.encode(loaded,catalog.mods),M.encode(snapshot,catalog.mods)),'Save/Load changed saved terrain/configuration')
            opened,reason=r:build(loaded);assert(opened,tostring(reason));scene=loaded;checked(r,scene)
            local report=Report.new(api)
            for cycle=1,cycles do
                local unitIds={};for _,u in ipairs(scene.units)do unitIds[#unitIds+1]=r.live[u.id]end
                inspectEnvironment(label..'_cycle'..cycle,row,r,scene)
                movements=0;steps={};fighting=true;report:start(scene,r)
                if options.onFight then options.onFight(true)end
                api.fightTestField()
                if options.onFight then options.onFight(false)end
                fighting=false;report:finish(scene,r)
                local winner=api.get('battleWinner');assert((api.get('battleRound')or 0)>0 and (winner==0 or winner==24),'native battle did not complete')
                local archive,archiveWhy=report:archive();assert(archive,tostring(archiveWhy))
                result[label..'_fight'..cycle]={round=api.get('battleRound'),winner=winner,movement_transitions=movements,report=archive,
                    movement_scope='Observed native cell transitions, not a campaign movement-cost comparison'}
                assert(movements>0,'no actual native movement observed')
                close(label..'_cycle'..cycle,r,unitIds,beforeWorld)
                scene=M.copy(snapshot);opened,reason=r:build(scene);assert(opened,tostring(reason));checked(r,scene)
                assert(equal(M.encode(scene,catalog.mods),M.encode(snapshot,catalog.mods)),'exact Reset/Rematch changed saved setup')
            end
            local finalIds={};for _,u in ipairs(scene.units)do finalIds[#finalIds+1]=r.live[u.id]end
            close(label..'_final',r,finalIds,beforeWorld)
            local diagnostic,path=d:export({fixture=row.name..' native environment/placement/SaveLoad/exact reset/rematch'},r:snapshot(scene));assert(diagnostic,path)
            result[label..'_diagnostic']={name=diagnostic};activeRuntime=nil
        end,function(e)return tostring(e)end)
        fighting=false
        if options.onFight then options.onFight(false)end
        if activeRuntime then
            local closed,closeWhy=activeRuntime:close();if not closed then ok=false;why=tostring(why)..' | cleanup: '..tostring(closeWhy)end
            activeRuntime=nil
        end
        result[label]={status=ok and (cycles==2 and 'PASS' or 'PARTIAL') or 'FAIL',name=row.name,
            detail=ok and (cycles==2 and 'Actual native API matrix; neutral test-field scope only' or 'Environment/placement/SaveLoad checked; two-fight Reset/Rematch matrix incomplete') or tostring(why)}
        save()
        if not equal(beforeWorld,world())then result[label].status='FAIL';result[label].detail=result[label].detail..' | borrowed public world context did not restore';save();break end
    end end
    return result
end
return Probe
