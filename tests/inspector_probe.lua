-- Explicit private process probe; never enabled by a normal BAT launch.
local api=coe5
local request=api.readIni('request');if not request or not request.run then return end
local mode=request.run.mode
local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local D=require('sandbox.diagnostics')
local c=C.read(api);local results={environment={mode=mode,scope='actual isolated CoE5 process'}}
local function save()assert(api.writeIni('inspector-results',results))end
local function ids(keys)local out={};for _,key in ipairs(keys)do out[#out+1]=assert(c.spellKeys[key],key)end;return out end
local function spellState(label,r,u)
    local id=r.live[u.id];local known=r:spellList(id,'unitKnownSpell',59);local mem=r:spellList(id,'unitMemorizedSpell',29)
    results[label]={model_id=u.id,native_id=id,monster=u.monster,hp=api.get('unitHp',id),owner=api.get('unitOwner',id),known=table.concat(known,'|'),memorized=table.concat(mem,'|'),world_x=api.get('unitX',id),world_y=api.get('unitY',id)}
    local paths={};for _,key in ipairs(known)do local p=api.spellInfo(assert(c.spellKeys[key])).path;paths[p]=paths[p] or {path=p,known=0,memorized=0};paths[p].known=paths[p].known+1 end
    for _,key in ipairs(mem)do local p=api.spellInfo(assert(c.spellKeys[key])).path;paths[p]=paths[p] or {path=p,known=0,memorized=0};paths[p].memorized=paths[p].memorized+1 end
    for path,row in pairs(paths)do row.allowance=api.memorizeAllowance(id,path);results[label..'_school'..path]=row end
    save()
end
local function test(name,fn)
    local ok,why=xpcall(fn,function(e)return tostring(e)end)
    results[name]={status=ok and 'PASS' or 'FAIL',detail=ok and 'actual native calls' or why}
    api.closeTestField();save()
end
local s,decodeWhy=M.decode(api.readIni('replay'),c,c.mods);assert(s,decodeWhy)
if mode=='baseline' then
    test('primitive_edit_can_exceed_native_allowance',function()
        local valid=M.copy(s)
        -- Explicit TEST fixture undoing only the four additions proven by the user log.
        valid.units[4].spells={table.unpack(valid.units[4].spells,1,8)}
        valid.units[6].spells={table.unpack(valid.units[6].spells,1,8)}
        local d=D.new(api);local r=R.new(api,c,d);local ok,why=r:build(valid);assert(ok,why)
        spellState('before_raw_edit',r,valid.units[4]);spellState('other_instance_before',r,valid.units[5])
        for _,change in ipairs({{6,268},{6,267},{4,268},{4,266}})do api.memorizeSpell(r.live[valid.units[change[1]].id],change[2])end
        spellState('after_raw_edit',r,valid.units[4]);spellState('other_instance_after',r,valid.units[5])
        local unit=r.live[valid.units[4].id]
        local accepted,reason=api.setTestFieldSpells(unit,{known=ids(s.units[4].baseline.known),memorized=ids(s.units[4].spells)})
        results.bulk_refusal={accepted=accepted and 1 or 0,reason=tostring(reason)}
        assert(not accepted and reason=='memorize_limit','old bulk setter did not reject the ten-spell set')
        for _,i in ipairs({4,6})do valid.units[i].spells=r:spellList(r.live[valid.units[i].id],'unitMemorizedSpell',29);assert(#valid.units[i].spells==10)end
        local healthy=r:ready(valid);results.old_integrity_accepts_matching_but_overquota={accepted=healthy and 1 or 0};assert(healthy)
        results.before_fight={units=#valid.units};save()
        api.fightTestField()
        assert((api.get('battleRound') or 0)>0 and (api.get('battleWinner')==0 or api.get('battleWinner')==24),'fight was aborted')
        results.after_fight={round=api.get('battleRound'),winner=api.get('battleWinner')};save()
        ok,why=r:build(M.copy(valid));results.rebuild={accepted=ok and 1 or 0,reason=tostring(why),locked=r.blocked and 1 or 0}
        assert(not ok and r.blocked,'old scenario unexpectedly restored')
        local name=d:export({fixture='original six-unit scene with four recorded raw Edit additions'},r:snapshot(valid));results.diagnostic={name=name or 'failed'}
    end)
else
    local Report=require('sandbox.report')
    -- Exercise the real native Speed-up action (menu ID 1), never Skip/Stop.
    -- Native branch halves the render delay and clamps at 2 microseconds.
    local speedActive,speedRequests,speedMinimum=false,0,false
    api.wrap('BATTLE_WAIT',function(next,b,m)
        local id=next(b,m)
        if speedActive then
            local delay=api.get('battleDelay')
            if delay==2 then speedMinimum=true end
            if id==0 and type(delay)=='number' and delay>2 then speedRequests=speedRequests+1;return 1 end
        end
        return id
    end)
    local selected={};for name in tostring(request.run.only or ''):gmatch('[^,%s]+')do selected[name]=true end
    local activeRuntime
    local function regression(name,fn)
        if next(selected) and not selected[name] then return end
        test(name,function()
            local ok,why=xpcall(fn,function(e)return tostring(e)end)
            if activeRuntime then
                local closed,reason=activeRuntime:close();activeRuntime=nil
                assert(closed,'native cleanup failed: '..tostring(reason))
            end
            assert(ok,why)
        end)
    end
    local function flat(row)
        local out={};for key,value in pairs(row or {})do
            if type(value)=='boolean'then out[key]=value and 1 or 0
            elseif type(value)=='string' or type(value)=='number'then out[key]=value end
        end;return out
    end
    local function equal(a,b)
        if type(a)~=type(b)then return false end
        if type(a)~='table'then return a==b end
        for key,value in pairs(a)do if not equal(value,b[key])then return false end end
        for key in pairs(b)do if a[key]==nil then return false end end
        return true
    end
    local original=M.copy(s)
    local function testCopy()
        local copy=M.copy(s)
        for index,removed in pairs({[4]={[268]=true,[266]=true},[6]={[268]=true,[267]=true}})do
            assert(copy.units[index].monster==141 and #copy.units[index].spells==10,'unexpected original God Emperor fixture')
            local spells,count={},0
            for _,key in ipairs(copy.units[index].spells)do
                if removed[assert(c.spellKeys[key])]then count=count+1 else spells[#spells+1]=key end
            end
            assert(count==2 and #spells==8,'recorded user additions did not match preserved setup')
            copy.units[index].spells=spells
        end
        assert(equal(s,original),'original replay was modified')
        return copy
    end
    local function runtime()
        local d=D.new(api);local r=R.new(api,c,d);activeRuntime=r;return r,d
    end
    local function checked(r,scene,previous)
        assert(r.emptyEditor and r.primaryId==nil,'inspector regression did not use the commander-free editor')
        local ok,state=r:check(scene,true,previous);assert(ok,tostring(state));return state
    end
    local function openCopy()
        local scene=testCopy();local r,d=runtime();local ok,why=r:build(scene);assert(ok,tostring(why));checked(r,scene);return r,scene,d
    end
    local function detailedSpell(label,r,u)
        spellState(label,r,u)
        local state,why=api.testFieldSpellState(r.live[u.id]);assert(state,tostring(why))
        results[label..'_native']=flat(state)
        results[label..'_native'].known_ids=table.concat(state.known,'|');results[label..'_native'].memorized_ids=table.concat(state.memorized,'|')
        for i,row in ipairs(state.schools)do results[label..'_native_school'..i]=flat(row)end
        for i,row in ipairs(state.issues or {})do results[label..'_native_issue'..i]=flat(row)end
        save();return state
    end
    local function closeChecked(label,r,nativeIds)
        local ok,why=r:close();assert(ok,tostring(why))
        local life,reason=api.testFieldLifecycle();assert(life,tostring(reason));results[label..'_lifecycle']=flat(life)
        assert(not life.open and life.complete and #life.issues==0 and life.creationDepth==0 and life.uniqueOverrideDepth==0,'cleanup was not fully verified')
        for i,row in ipairs(life.beforeCleanup or {})do results[label..'_before'..i]=flat(row)end
        for i,row in ipairs(life.afterCleanup or {})do results[label..'_after'..i]=flat(row)end
        for _,id in ipairs(nativeIds or {})do assert((api.get('unitHp',id)or 0)<=0,'original test actor remains alive after close')end
        save()
    end
    regression('invalid_original_rejected_explicit_copy_repaired',function()
        local r,d=runtime();r.sourceScenarioFile='replay'
        local ok,why=r:build(M.copy(s));assert(not ok,'invalid ten-spell scene was accepted')
        results.invalid_original={accepted=0,reason=tostring(why),original_units=#s.units,original_preserved=equal(s,original) and 1 or 0}
        local problems=r:spellRepairCandidates(s);assert(#problems==2,'both independent invalid casters were not diagnosed')
        for i,row in ipairs(problems)do
            assert(#row.spells==10 and #row.known>0);local solar=false
            for _,school in ipairs(row.schools)do
                results['invalid_problem'..i..'_school'..school.path]=flat(school)
                if school.path==19 then assert(school.selected_count==6 and school.allowance==4);solar=true end
            end
            assert(solar,'Solar allowance evidence missing')
        end
        r.recovery=M.copy(s);r.recoveryFile='replay'
        local chosen=testCopy();local repaired,scene,details=r:repairSpellSelection(chosen);assert(repaired,tostring(scene))
        assert(details and details.name and api.readIni(details.name).scenario,'verified repair was not saved separately')
        assert(details.name~='replay' and equal(s,original) and equal(r.originalSpellRecovery,s),'original recovery provenance changed')
        assert(equal(M.encode(scene,c.mods),M.encode(chosen,c.mods)),'repair silently changed chosen scene')
        checked(r,scene);detailedSpell('repaired_unit4',r,scene.units[4]);detailedSpell('repaired_unit6',r,scene.units[6])
        assert(r.live[scene.units[4].id]~=r.live[scene.units[6].id],'independent God Emperors alias')
        local saved,loadWhy=M.decode(api.readIni(details.name),c,c.mods);assert(saved,loadWhy)
        assert(equal(M.encode(saved,c.mods),M.encode(chosen,c.mods)),'saved repaired copy differs')
        results.repaired_copy={name=details.name,path=details.path or 'unknown',removed_unit4='268,266',removed_unit6='268,267',scope='EXPLICIT TEST COPY ONLY; original ten-spell recovery unchanged'}
        local name,path=d:export({fixture='original invalid six units refused; explicit recorded-addition removal in separate test copy'},r:snapshot(scene));assert(name,path)
        results.repair_diagnostic={name=name};save()
    end)
    regression('guarded_memorization_atomic_and_instance_independent',function()
        local r,scene=openCopy();local target,other=scene.units[4],scene.units[6]
        local before=checked(r,scene);local id=r.live[target.id];local otherId=r.live[other.id]
        local native=detailedSpell('guard_before',r,target);assert(native.valid and native.complete and #native.memorized==8)
        local accepted,why,detail=api.memorizeTestFieldSpell(id,268,true)
        results.guard_refusal={accepted=accepted and 1 or 0,reason=tostring(why)}
        for key,value in pairs(flat(detail))do results.guard_refusal[key]=value end
        assert(not accepted and why=='memorize_limit','ninth total / fifth Solar spell was not safely rejected')
        checked(r,scene,before)
        assert(equal(native,api.testFieldSpellState(id)),'guard refusal changed actual spell arrays or allowances')
        local removed
        for _,key in ipairs(target.spells)do if api.spellInfo(c.spellKeys[key]).path==19 then removed=key;break end end
        assert(removed and r:memorize(target,removed,false),'Solar removal failed')
        local added=assert(api.spellInfo(268));local addedKey='268:'..added.name
        assert(r:memorize(target,addedKey,true),'known Solar replacement at allowance was refused')
        local after=checked(r,scene);assert(after.signatures[otherId]==before.signatures[otherId],'editing one unique caster changed the other instance')
        api.giveItem(id,'A Chest Full of Fire');target.items=r:inventory(id);assert(#target.items>0,'explicit custom-item fixture unavailable')
        checked(r,scene);detailedSpell('guard_after_swap',r,target)
        local snapshot=M.copy(scene);assert(api.writeIni('inspector-valid-configured-copy',M.encode(snapshot,c.mods)))
        local loaded,reason=M.decode(api.readIni('inspector-valid-configured-copy'),c,c.mods);assert(loaded,reason)
        local ok;ok,why=r:build(loaded);assert(ok,tostring(why));checked(r,loaded)
        assert(equal(M.encode(loaded,c.mods),M.encode(snapshot,c.mods)),'Save/Load changed configured spells/items/teams/anchors')
        results.guard_independence={distinct_native_ids=1,refusal_unchanged=1,solar_swap_verified=1,other_instance_unchanged=1,custom_item_save_load=1};save()
    end)
    regression('valid_six_unit_battle_reset_rematch',function()
        local r,scene,d=openCopy();local snapshot=M.copy(scene);local report=Report.new(api)
        for cycle=1,2 do
            local nativeIds={};for _,u in ipairs(scene.units)do nativeIds[#nativeIds+1]=r.live[u.id]end
            report:start(scene,r);speedActive=true;speedRequests=0;speedMinimum=false
            api.fightTestField();speedActive=false;report:finish(scene,r)
            results['valid_battle_speed'..cycle]={source='native BATTLE_WAIT Speed-up menu ID 1',requests=speedRequests,minimum_delay_observed=speedMinimum and 1 or 0,skip_or_stop_used=0}
            local winner=api.get('battleWinner');assert((api.get('battleRound')or 0)>0 and (winner==0 or winner==24),'battle did not complete naturally')
            local archive,why=report:archive();assert(archive,tostring(why))
            results['valid_battle_cycle'..cycle]={round=api.get('battleRound'),winner=winner,report=archive,scope='Six original units, explicit valid test selection; natural combat, no stopTestFight'}
            for i,id in ipairs(nativeIds)do results['valid_battle_cycle'..cycle..'_unit'..i]={native_id=id,hp=api.get('unitHp',id),monster=api.get('unitMonster',id),owner=api.get('unitOwner',id),world_x=api.get('unitX',id),world_y=api.get('unitY',id)}end
            closeChecked('valid_cycle'..cycle,r,nativeIds)
            scene=M.copy(snapshot);local ok,reason=r:build(scene);assert(ok,tostring(reason));checked(r,scene)
            assert(equal(M.encode(scene,c.mods),M.encode(snapshot,c.mods)),'exact reset/rematch configuration changed')
            detailedSpell('valid_cycle'..cycle..'_restored4',r,scene.units[4]);detailedSpell('valid_cycle'..cycle..'_restored6',r,scene.units[6])
        end
        assert(equal(s,original),'original invalid recovery was modified by test combat')
        local name,path=d:export({fixture='two natural six-unit fights; exact valid-copy reset/rematch; original invalid recovery unchanged'},r:snapshot(scene));assert(name,path)
        results.battle_diagnostic={name=name};save()
    end)
    regression('readonly_footprints_and_frame_preflight',function()
        local scene=M.new();scene.terrain=2
        for i,row in ipairs({{13,1},{206,1},{201,2},{141,2}})do M.add(scene,row[1],c.byId[row[1]].name,row[2],i*4,8)end
        local r=runtime();local ok,why=r:build(scene,true);assert(ok,tostring(why));local before=checked(r,scene)
        local last=api.get('unitLastIndex');local nonsquare,measured=0,0
        for _,monster in ipairs(c.monsters)do
            local foot=api.testFieldFootprint(monster.id)
            if foot then
                measured=measured+1
                if foot.width~=foot.height and nonsquare<5 then nonsquare=nonsquare+1;results['nonsquare'..nonsquare]=flat(foot);results['nonsquare'..nonsquare].name=monster.name end
            end
        end
        results.footprint_catalog={measured=measured,nonsquare_examples=nonsquare,scope=nonsquare>0 and 'Read-only monster rules; instances not spawned by this scan' or 'No non-square template found by read-only catalog scan; non-square native placement not claimed'}
        local footprints={}
        for i,u in ipairs(scene.units)do
            local id=r.live[u.id];local foot,reason=api.testFieldFootprint(u.monster,id);assert(foot,tostring(reason))
            local native=assert(api.testFieldUnitState(id));assert(foot.width==native.width and foot.height==native.height and foot.anchor=='positive_xy')
            if u.monster==13 then assert(foot.width==1 and foot.height==1)elseif u.monster==206 then assert(foot.width==2 and foot.height==2)elseif u.monster==201 then assert(foot.width==3 and foot.height==3)end
            results['footprint_unit'..i]=flat(foot);results['footprint_unit'..i].name=u.name;footprints[i]=foot
        end
        local done,frameOk,frameWhy=false
        local hook=api.wrap('BATTLE_DRAW',function(next,...)
            local value=next(...)
            if not done then
                done=true
                frameOk,frameWhy=xpcall(function()
                    for i,u in ipairs(scene.units)do
                        local id=r.live[u.id];local foot=footprints[i]
                        local occupied,reason=api.testFieldPlacementPreflight(u.monster,u.x,u.y,id,false);assert(occupied,tostring(reason))
                        assert(occupied.partial and #occupied.cells==foot.width*foot.height and not occupied.valid)
                        for _,cell in ipairs(occupied.cells)do assert(cell.status=='occupied' and cell.unit==id and api.battleUnitAt(cell.x,cell.y)==id,'footprint occupancy differs from native hit test')end
                        local move=assert(api.testFieldPlacementPreflight(u.monster,u.x,u.y,id,true));assert(#move.cells==#occupied.cells)
                        for _,cell in ipairs(move.cells)do assert(cell.unit~=id,'Move self-ignore left its own handle')end
                        results['frame_preflight_unit'..i]={native_id=id,monster=u.monster,width=foot.width,height=foot.height,cells=#occupied.cells,copy_occupied=1,move_ignores_only_self=1,partial=1}
                    end
                    local edge=assert(api.testFieldPlacementPreflight(201,r.width-1,19))
                    local outside=0;local view=assert(api.battleView())
                    for _,cell in ipairs(edge.cells)do
                        assert(type(cell.screenX)=='number' and type(cell.screenY)=='number','outside projection missing')
                        if cell.status=='out_of_bounds'then outside=outside+1 end
                    end
                    assert(#edge.cells==9 and outside==8 and edge.partial and not edge.valid)
                    results.frame_edge={footprint='3x3',cells=#edge.cells,outside=outside,projection='native linear view including outside cells',cell_size=view.cellSize,partial=1}
                    local state=assert(api.testFieldState());local obstacle
                    for _,cell in ipairs(state.grid)do if cell.object>=0 and api.battleUnitAt(cell.x,cell.y)<0 then obstacle=cell;break end end
                    assert(obstacle,'Forest did not provide a native obstacle fixture')
                    local blocked=assert(api.testFieldPlacementPreflight(13,obstacle.x,obstacle.y));assert(blocked.cells[1].status=='terrain' and not blocked.valid)
                    results.frame_obstacle={x=obstacle.x,y=obstacle.y,status=blocked.cells[1].status,partial=1}
                    checked(r,scene,before);assert(api.get('unitLastIndex')==last,'read-only preview allocated a unit')
                end,function(e)return tostring(e)end)
            end
            return value
        end)
        assert(hook,'BATTLE_DRAW hook unavailable')
        for frame=1,3 do if not done then api.drawTestField()end end
        assert(done and frameOk,tostring(frameWhy or 'native drawing hook did not run'))
        checked(r,scene,before);assert(api.get('unitLastIndex')==last,'footprint scan/preflight changed native table')
        save()
    end)
end
save()
