-- Explicit callable private native probe. Normal Sandbox startup never loads it.
-- Empty means zero field actors/commander; native terrain objects may still exist.
local Probe={}
function Probe.run(api,options)
    options=options or {}
    local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local D=require('sandbox.diagnostics');local Report=require('sandbox.report')
    local catalog=C.read(api);local output=options.output or 'empty-editor-results'
    local cycles=math.max(0,math.min(2,math.floor(tonumber(options.cycles)or 2)))
    local result={environment={scope='Actual isolated CoE5 API with production model/runtime/integrity',requested_fights=cycles,
        empty_definition='No commander, dummy or living field actor; normal native terrain objects are permitted'}}
    local activeRuntime,allIds
    local function save()assert(api.writeIni(output,result))end
    local function equal(a,b)
        if type(a)~=type(b)then return false end
        if type(a)~='table'then return a==b end
        for key,value in pairs(a)do if not equal(value,b[key])then return false end end
        for key in pairs(b)do if a[key]==nil then return false end end;return true
    end
    local function flat(row)
        local out={};for key,value in pairs(row or {})do
            if type(value)=='boolean'then out[key]=value and 1 or 0 elseif type(value)=='number' or type(value)=='string'then out[key]=value end
        end;return out
    end
    local context=api.readIni('launcher-context');local session=context and context.environment and context.environment.session or 'local'
    session=tostring(session):gsub('[^%w%-]',''):sub(1,20);if session==''then session='local'end
    local function saveUnique(label,data)
        local used={};for _,name in ipairs(api.listIni())do used[name:gsub('%.ini$',''):lower()]=true end
        for index=1,10000 do
            local name='empty-qa-'..session..'-'..label..'-'..index
            if not used[name:lower()]then assert(api.writeIni(name,data),'private QA file save refused');return name end
        end
        error('No unused private QA file name available')
    end
    local function checked(r,scene,previous)
        local ready,why=r:ready(scene);assert(ready,tostring(why))
        local ok,state=r:check(scene,true,previous);assert(ok,tostring(state));return state
    end
    local function counts(label,r,scene)
        local checkedState=checked(r,scene);local native=checkedState.native;local a,b,living=0,0,0
        assert(native.complete and #native.issues==0 and native.emptyEditor,'complete native empty-editor contract missing')
        for _,row in ipairs(native.units)do if row.alive then
            living=living+1;if row.owner==0 then a=a+1 elseif row.owner==24 then b=b+1 else error('unexpected living field owner')end
        end end
        assert(a==M.count(scene,1) and b==M.count(scene,2) and living==#scene.units,'native/model team count mismatch')
        assert(r.primaryId==nil and r.emptyEditor,'empty-editor created or retained a primary commander')
        local objectCells=0;for _,cell in ipairs(native.grid)do if cell.object>=0 then objectCells=objectCells+1 end end
        result[label]={model_units=#scene.units,team_a=a,team_b=b,living_native_actors=living,native_actor_rows=#native.units,
            native_terrain_object_cells=objectCells,primary_commander='none',native_complete=1}
        save();return checkedState
    end
    local function closeChecked(label,r)
        local ok,why=r:close();assert(ok,tostring(why))
        local lifecycle,reason=api.testFieldLifecycle();assert(lifecycle,tostring(reason))
        assert(lifecycle.complete and not lifecycle.open and #lifecycle.issues==0 and lifecycle.creationDepth==0 and lifecycle.uniqueOverrideDepth==0,'cleanup was not fully verified')
        result[label]=flat(lifecycle)
        for i,row in ipairs(lifecycle.afterCleanup or {})do result[label..'_unit'..i]=flat(row);if row.identityMatches then assert((row.hp or 0)<=0,'owned actor/object still alive after cleanup')end end
        for id in pairs(allIds or {})do assert((api.get('unitHp',id)or 0)<=0,'created test actor remains alive after close')end
        save()
    end
    local function newEmpty(label)
        label=label or 'empty'
        local r=R.new(api,catalog,D.new(api));activeRuntime=r;allIds={}
        local scene=M.new();assert(#scene.units==0,'model added an unsolicited initial unit')
        local ok,why=r:build(scene);assert(ok,tostring(why));counts(label..'_opened_empty',r,scene)
        assert(next(r.live)==nil and #api.testFieldState().units==0,'empty editor retained a native actor')
        local life=assert(api.testFieldLifecycle());local actors,terrain=0,0
        for _,row in ipairs(life.created or {})do if row.kind=='actor'then actors=actors+1 elseif row.kind=='terrain'then terrain=terrain+1 end end
        assert(actors==0,'empty setup created a dummy/commander actor')
        result[label..'_empty_creation']={created_actor_records=actors,created_terrain_records=terrain,scope='Terrain records are separate from playable unit records'}
        return r,scene
    end
    local function find(scene,id)for _,unit in ipairs(scene.units)do if unit.id==id then return unit end end;error('model unit missing')end
    local function resolve(name)
        local id=api.findMonster(name);assert(id and catalog.byId[id] and catalog.byId[id].name==name,'loaded monster identity missing: '..name);return id
    end
    local function add(r,scene,monster,team,template,anchor)
        local footprint=assert(api.testFieldFootprint(monster));local candidates={}
        if anchor then candidates[1]=anchor else
            local state=assert(api.testFieldState())
            for _,cell in ipairs(state.grid)do
                if cell.x>0 and cell.y>0 and cell.x+footprint.width<r.width and cell.y+footprint.height<=19 then
                    local free=true
                    for dx=0,footprint.width-1 do for dy=0,footprint.height-1 do
                        if api.battleUnitAt(cell.x+dx,cell.y+dy)>=0 or api.battleObjectAt(cell.x+dx,cell.y+dy)>=0 then free=false end
                    end end
                    if free then candidates[#candidates+1]={x=cell.x,y=cell.y};if #candidates==12 then break end end
                end
            end
        end
        local lastReason
        for _,cell in ipairs(candidates)do
            local ok,candidate,unit=r:add(scene,monster,team,cell.x,cell.y,template)
            if ok then local id=r.live[unit.id];assert(id);allIds[id]=true;checked(r,candidate);return candidate,unit end
            lastReason=candidate;assert(not r.blocked,'placement cleanup/rollback became unverified: '..tostring(candidate))
        end
        error('No verified fixture placement: '..tostring(lastReason or 'no native free anchor'))
    end
    local function remove(label,r,scene,unit)
        local id=assert(r.live[unit.id]);local before=assert(api.testFieldUnitState(id))
        local ok,candidate=r:remove(scene,unit);assert(ok,tostring(candidate))
        assert(r.live[unit.id]==nil and (api.get('unitHp',id)or 0)<=0,'deleted unit retained model/native life')
        for _,cell in ipairs(before.occupied)do assert(api.battleUnitAt(cell.x,cell.y)~=id,'deleted unit still hit-tests in vacated footprint')end
        counts(label,r,candidate);return candidate
    end
    local function refusedFight(label,r,scene,expected)
        local before=checked(r,scene);local native=M.copy(api.testFieldState());local model=M.encode(scene,catalog.mods)
        local life=M.copy(api.testFieldLifecycle());local round,winner,last=api.get('battleRound'),api.get('battleWinner'),api.get('unitLastIndex')
        local accepted,why=api.fightTestField()
        assert(accepted==false and why==expected,'wrong native missing-team refusal: '..tostring(why))
        assert(api.get('battleRound')==round and api.get('battleWinner')==winner and api.get('unitLastIndex')==last,'refused battle changed round/winner/allocation')
        assert(equal(native,api.testFieldState()) and equal(life,api.testFieldLifecycle()),'refused battle changed native field/lifecycle')
        assert(equal(model,M.encode(scene,catalog.mods)),'refused battle changed saved configuration')
        checked(r,scene,before);result[label]={accepted=0,reason=why,state_unchanged=1,round_unchanged=1,hp_spells_items_unchanged=1};save()
    end
    local function roundtrip(label,r,scene)
        local encoded=M.encode(scene,catalog.mods);local name=saveUnique(label,encoded)
        local written=assert(api.readIni(name));assert(tonumber(written.scenario.count)==#scene.units,'serialized empty/one-sided count wrong')
        local loaded,why=M.decode(written,catalog,catalog.mods);assert(loaded,tostring(why))
        assert(equal(M.encode(loaded,catalog.mods),encoded),'INI decode silently changed scene')
        local ok;ok,why=r:build(loaded);assert(ok,tostring(why));counts(label..'_loaded',r,loaded)
        for _,unit in ipairs(loaded.units)do allIds[r.live[unit.id]]=true end
        result[label..'_file']={name=name,count=#loaded.units,team_a=M.count(loaded,1),team_b=M.count(loaded,2)};save();return loaded
    end
    local function group(name,fn)
        local ok,why=xpcall(fn,function(e)return tostring(e)end)
        if options.onFight then options.onFight(false)end
        if activeRuntime then
            local closed,closeWhy=pcall(closeChecked,name..'_cleanup',activeRuntime)
            if not closed then ok=false;why=tostring(why)..' | cleanup: '..tostring(closeWhy)end
            activeRuntime=nil
        end
        result[name]={status=ok and (name=='empty_to_battle_reset_rematch' and cycles<2 and 'PARTIAL' or 'PASS') or 'FAIL',
            detail=ok and 'Actual production runtime + native API assertions; requested fight count recorded separately' or tostring(why)};save()
    end
    group('empty_and_one_sided_guard_save_load',function()
        local r,scene=newEmpty('guard');refusedFight('refused_zero_zero',r,scene,'missing_team_a')
        scene=roundtrip('zero-zero',r,scene);assert(#scene.units==0)
        local a;scene,a=add(r,scene,resolve('Spearman'),1);counts('only_a',r,scene);refusedFight('refused_only_a',r,scene,'missing_team_b')
        scene=roundtrip('only-a',r,scene);scene=remove('last_a_removed',r,scene,scene.units[1]);assert(#scene.units==0 and next(r.live)==nil)
        local b;scene,b=add(r,scene,resolve('Goblin'),2);counts('only_b',r,scene);refusedFight('refused_only_b',r,scene,'missing_team_a')
        scene=roundtrip('only-b',r,scene);scene=remove('last_b_removed',r,scene,scene.units[1]);assert(#scene.units==0 and next(r.live)==nil)
        scene,a=add(r,scene,resolve('Spearman'),1);scene,b=add(r,scene,resolve('Goblin'),2);counts('both_after_empty',r,scene)
        assert(r.live[a.id]~=r.live[b.id],'new teams share a native handle')
    end)
    group('empty_editor_unique_guard_before_allocation',function()
        local r,scene=newEmpty('unique');local monster=resolve('God Emperor');assert((api.get('monsterAbility',monster,'unique')or 0)>0,'fixture is not a native unique')
        local unit;scene,unit=add(r,scene,monster,1);local before=checked(r,scene);local state=M.copy(api.testFieldState());local life=M.copy(api.testFieldLifecycle());local last=api.get('unitLastIndex')
        local made,why=api.addTestFieldUnits('enemies',{{monster,1}})
        assert(not made and why=='unique_exists','native duplicate unique was not rejected')
        assert(api.get('unitLastIndex')==last and equal(life,api.testFieldLifecycle()) and equal(state,api.testFieldState()),'native unique refusal allocated or changed a record')
        local accepted=r:add(scene,monster,2,unit.x+4,unit.y);assert(not accepted and not r.blocked,'model unique guard failed')
        assert(api.get('unitLastIndex')==last and equal(life,api.testFieldLifecycle()));checked(r,scene,before)
        result.unique_guard={monster=monster,native_reason=why,model_refused=1,before_allocation=1,other_state_unchanged=1}
        scene=remove('unique_last_a_removed',r,scene,unit);assert(#scene.units==0 and next(r.live)==nil)
    end)
    group('configured_caster_survives_other_removals_and_reuse',function()
        local r,scene=newEmpty('caster');local priestId=resolve('Anointed Priestess');local priest,a,b
        scene,priest=add(r,scene,priestId,1);local modelId=priest.id
        scene,a=add(r,scene,resolve('Spearman'),1);scene,b=add(r,scene,resolve('Goblin'),2);priest=find(scene,modelId)
        local native=r.live[modelId];assert(#priest.baseline.known>0 and #priest.spells>0,'loaded Anointed Priestess has no native spell fixture')
        api.giveItem(native,'A Chest Full of Fire');priest.items=r:inventory(native);assert(#priest.items>0,'custom item assignment unavailable')
        local removed=priest.spells[1];assert(r:memorize(priest,removed,false),'explicit spell customization refused')
        local before=checked(r,scene);local signature=before.signatures[native];local template=M.copy(priest)
        result.configured_caster={monster=priestId,model_id=modelId,native_id=native,known=table.concat(priest.baseline.known,'|'),memorized=table.concat(priest.spells,'|'),items=table.concat(priest.items,'|'),removed_spell=removed}
        scene=remove('caster_after_other_a_removed',r,scene,find(scene,a.id));assert(checked(r,scene).signatures[native]==signature,'other A removal changed caster')
        scene=remove('caster_after_last_b_removed',r,scene,find(scene,b.id));assert(checked(r,scene).signatures[native]==signature,'last B removal changed caster')
        refusedFight('refused_configured_a_only',r,scene,'missing_team_b')
        scene=remove('configured_last_a_removed',r,scene,find(scene,modelId));assert(#scene.units==0)
        scene,priest=add(r,scene,priestId,1,template,{x=template.x,y=template.y})
        assert(equal(priest.baseline.known,template.baseline.known) and equal(priest.spells,template.spells) and equal(priest.items,template.items),'vacated-cell recreation changed configured spells/items')
        scene=roundtrip('configured-a',r,scene);assert(#scene.units==1)
        scene=remove('configured_loaded_last_a_removed',r,scene,scene.units[1]);assert(#scene.units==0)
    end)
    group('legacy_commander_slot_reuse_does_not_attach_empty_actors',function()
        local spear,goblin=resolve('Spearman'),resolve('Goblin')
        local legacy=R.new(api,catalog,D.new(api));activeRuntime=legacy;allIds={}
        local opened,units=api.openTestField{commander=spear,spell=-1,enemies={{goblin,1}},terrain=0}
        assert(opened,tostring(units));legacy.open=true
        assert(type(units.commander)=='number' and units.commander>=0,'legacy fixture has no real commander')
        allIds[units.commander]=true;for _,id in ipairs(units.enemies)do allIds[id]=true end
        local last=api.get('commanderLastIndex');assert(type(last)=='number' and last%1==0 and last>=0 and last<=9989,'commander table extent unavailable')
        result.legacy_commander_fixture={native_commander_unit=units.commander,commander_last_index=last}
        closeChecked('legacy_before_empty',legacy);activeRuntime=nil
        local r,scene=newEmpty('after_legacy');assert(api.get('commanderLastIndex')==last,'empty setup allocated a commander record')
        local a,b;scene,a=add(r,scene,spear,1);scene,b=add(r,scene,goblin,2)
        assert(api.get('commanderLastIndex')==last,'adding empty-editor actors allocated a commander')
        local actorA,actorB=assert(r.live[a.id]),assert(r.live[b.id]);local scanned=0
        for index=0,last do
            local linked=api.get('commanderUnit',index);assert(type(linked)=='number','commanderUnit readback unavailable')
            assert(linked~=actorA and linked~=actorB,'new empty actor inherited an old commander record')
            scanned=scanned+1
        end
        local leaderA,leaderB=api.get('unitCommander',actorA),api.get('unitCommander',actorB)
        assert(type(leaderA)=='number' and type(leaderB)=='number','unitCommander readback unavailable')
        assert(leaderA==-1 and leaderB==-1,'empty-editor actor was assigned a leader')
        counts('after_legacy_both_teams',r,scene)
        result.commander_reuse_guard={new_actor_a=actorA,new_actor_b=actorB,commander_last_before_empty=last,
            commander_last_after_add=api.get('commanderLastIndex'),commander_records_scanned=scanned,matching_commander_references=0,
            unit_commander_a=leaderA,unit_commander_b=leaderB,proof_scope='Global commanderUnit references checked; unitCommander=-1 alone is not used as proof'}
    end)
    group('empty_to_battle_reset_rematch',function()
        local r,scene=newEmpty('battle');local a,b
        scene,a=add(r,scene,resolve('Spearman'),1);scene,b=add(r,scene,resolve('Goblin'),2);counts('fight_roster',r,scene)
        local snapshot=M.copy(scene);local report=Report.new(api)
        for cycle=1,cycles do
            report:start(scene,r);if options.onFight then options.onFight(true)end
            api.fightTestField() -- Successful native calls may return no Lua value.
            if options.onFight then options.onFight(false)end
            report:finish(scene,r)
            local winner=api.get('battleWinner');assert((api.get('battleRound')or 0)>0 and (winner==0 or winner==24),'native fight did not finish naturally')
            local archive,why=report:archive();assert(archive,tostring(why))
            result['battle_cycle'..cycle]={round=api.get('battleRound'),winner=winner,report=archive,starting_a=1,starting_b=1,scope='Natural 1/1 battle after true empty setup; no stopTestFight'}
            closeChecked('battle_cycle'..cycle..'_cleanup',r)
            scene=M.copy(snapshot);local ok,reason=r:build(scene);assert(ok,tostring(reason));counts('battle_cycle'..cycle..'_restored',r,scene)
            for _,unit in ipairs(scene.units)do allIds[r.live[unit.id]]=true end
            assert(equal(M.encode(scene,catalog.mods),M.encode(snapshot,catalog.mods)),'exact Reset/Rematch changed setup')
        end
        if cycles<2 then result.empty_to_battle_reset_rematch_coverage={status='PARTIAL',detail='Fewer than two natural fights requested; full Reset/Rematch cycle not claimed'}end
        if options.exportDiagnostics then local name,path=r.diag:export({fixture='True empty, native guard, placement and exact natural battle Reset/Rematch'},r:snapshot(scene));assert(name,path);result.battle_diagnostic={name=name}end
    end)
    return result
end
return Probe
