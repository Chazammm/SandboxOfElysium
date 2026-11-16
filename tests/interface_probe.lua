-- Explicit isolated, real-process lifecycle/interface probe.
local api=coe5
local request=api.readIni('request');if not request or not request.run then return end
local mode=request.run.mode
local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local D=require('sandbox.diagnostics')
local c=C.read(api);local results={environment={scope='actual isolated CoE5 API',mode=mode}}
local fastFight=false -- reserved; baseline must run actual combat, never stopTestFight
local activeRuntime,fatalCleanup
local selectedCases={}
for name in tostring(request.run.only or ''):gmatch('[^,%s]+') do selectedCases[name]=true end
api.wrap('BATTLE_WAIT',function(next,b,m)
    local id=next(b,m)
    return id
end)
local function save()assert(api.writeIni('interface-results',results))end
local function raw(id)
    return {native_id=id,hp=api.get('unitHp',id),monster=api.get('unitMonster',id),owner=api.get('unitOwner',id),
        world_x=api.get('unitX',id),world_y=api.get('unitY',id),anchor_x=api.get('unitBattleX',id),anchor_y=api.get('unitBattleY',id)}
end
local function capture(label,ids)
    results[label]={last_unit=api.get('unitLastIndex'),round=api.get('battleRound'),winner=api.get('battleWinner')}
    for i,id in ipairs(ids) do results[label..'_unit'..i]=raw(id) end
    save()
end
local function test(name,fn)
    if next(selectedCases) and not selectedCases[name] then return end
    if fatalCleanup then results[name]={status='SKIP',detail='An earlier cleanup was not verified; isolated process restart required.'};save();return end
    local ok,why=xpcall(fn,function(e)return tostring(e)end);fastFight=false
    if mode~='baseline' and activeRuntime then
        local called,closed,reason=pcall(activeRuntime.close,activeRuntime)
        if not called or closed==false then ok=false;why='Cleanup failed: '..tostring(reason or closed);fatalCleanup=true end
        local lifecycle=type(api.testFieldLifecycle)=='function' and api.testFieldLifecycle()
        if lifecycle and not lifecycle.open and not lifecycle.complete then fatalCleanup=true end
        activeRuntime=nil
    end
    results[name]={status=ok and 'PASS' or 'FAIL',detail=ok and 'actual native calls' or why};save()
end
if mode=='baseline' then
    test('user_seven_unit_battle_close_reopen',function()
        local s,why=M.decode(api.readIni('replay'),c,c.mods);assert(s,why);assert(#s.units==7)
        local d=D.new(api);local r=R.new(api,c,d);local ok;ok,why=r:build(s);assert(ok,why)
        local ids={};for _,u in ipairs(s.units) do ids[#ids+1]=r.live[u.id] end
        capture('before_fight',ids)
        fastFight=true;api.fightTestField();fastFight=false
        assert((api.get('battleRound') or 0)>0 and (api.get('battleWinner')==0 or api.get('battleWinner')==24),'native fight was not completed')
        capture('after_fight',ids)
        r:close();capture('after_close',ids)
        ok,why=r:build(M.copy(s));results.reopen={accepted=ok and 1 or 0,reason=tostring(why)}
        capture('after_reopen_attempt',ids)
        if r.open then r:close() end
    end)
else
    local function flat(row)
        local out={}
        for key,value in pairs(row or {}) do
            if type(value)=='boolean' then out[key]=value and 1 or 0
            elseif type(value)=='number' or type(value)=='string' then out[key]=value end
        end
        return out
    end
    local function lifecycle(label)
        assert(type(api.testFieldLifecycle)=='function','lifecycle API unavailable')
        local state,why=api.testFieldLifecycle();assert(state,tostring(why))
        results[label..'_lifecycle']=flat(state)
        for _,key in ipairs({'created','beforeCleanup','afterCleanup','issues'}) do
            results[label..'_lifecycle'][key..'_count']=#(state[key] or {})
            for i,row in ipairs(state[key] or {}) do results[label..'_'..key..i]=flat(row) end
        end
        save();return state
    end
    local function checked(r,s,previous)
        local ok,state=r:check(s,true,previous);assert(ok,tostring(state));return state
    end
    local function start(s,nativeDeployment)
        local d=D.new(api);local r=R.new(api,c,d);activeRuntime=r
        local ok,why=r:build(s,nativeDeployment);assert(ok,tostring(why));checked(r,s)
        local ids,seen={},{}
        for _,u in ipairs(s.units) do local id=assert(r.live[u.id]);assert(not seen[id],'aliased native unit handle');seen[id]=true;ids[#ids+1]=id end
        return r,d,ids
    end
    local function roster(s,r)
        local ids={};for _,u in ipairs(s.units) do ids[#ids+1]=assert(r.live[u.id]) end;return ids
    end
    local function addModel(s,id,team,x,y)
        return M.add(s,id,assert(c.byId[id],'vanilla monster missing').name,team,x,y)
    end
    local function verifySetup(s,reference,positions)
        assert(s.allowMultipleUnique==reference.allowMultipleUnique,'multiple-unique flag changed')
        assert(#s.units==#reference.units,'roster changed')
        for i,u in ipairs(s.units) do local expected=reference.units[i]
            assert(u.monster==expected.monster and u.name==expected.name and u.team==expected.team,'saved unit assignment changed')
            if positions~=false then assert(u.x==expected.x and u.y==expected.y,'saved unit position changed') end
            assert(table.concat(u.items,'|')==table.concat(expected.items,'|'),'saved inventory changed')
            assert(table.concat(u.spells,'|')==table.concat(expected.spells,'|'),'saved memorization changed')
            assert(table.concat(u.baseline.known,'|')==table.concat(expected.baseline.known,'|'),'saved known spells changed')
        end
    end
    local function completedFight(label,ids)
        capture(label..'_before',ids)
        api.fightTestField()
        local winner=api.get('battleWinner');assert((api.get('battleRound') or 0)>0 and (winner==0 or winner==24),'fight did not complete naturally')
        capture(label..'_after',ids);lifecycle(label..'_after_fight')
    end
    local function closed(label,r,ids)
        local ok,why=r:close();capture(label..'_raw_after_close',ids)
        local state=lifecycle(label..'_after_close')
        assert(ok,tostring(why));assert(not state.open and state.complete,'cleanup not complete')
        assert(state.creationDepth==0 and state.uniqueOverrideDepth==0,'native temporary state leaked')
        assert(#state.issues==0,'cleanup issues remain')
        for _,id in ipairs(ids) do assert((api.get('unitHp',id) or 0)<=0,'saved test-field slot remains alive after cleanup: '..id) end
        for _,row in ipairs(state.afterCleanup or {}) do
            if row.identityMatches then assert((row.hp or 0)<=0,'owned lifecycle record still alive after cleanup') end
        end
        return state
    end
    local caps=type(api.testFieldEditorCapabilities)=='function' and api.testFieldEditorCapabilities() or {}
    results.capabilities=flat(caps);save()
    test('user_seven_unit_battle_close_reopen',function()
        local s,why=M.decode(api.readIni('replay'),c,c.mods);assert(s,why);assert(#s.units==7)
        local r,d,ids=start(s);local snapshot=M.copy(s)
        completedFight('user_seven',ids);closed('user_seven',r,ids)
        local ok;ok,why=r:build(M.copy(snapshot));assert(ok,tostring(why));assert(not r.blocked)
        checked(r,r.current);verifySetup(r.current,snapshot)
        results.reopen={accepted=1,reason='original seven-unit setup restored and native integrity verified'}
        capture('user_seven_reopened',roster(r.current,r))
        local name,path=d:export({fixture='user seven-unit natural fight / cleanup / exact reopening'},r:snapshot(r.current));assert(name,path)
        results.user_replay_diagnostic={name=name};closed('user_seven_reopened',r,roster(r.current,r))
    end)
    for _,team in ipairs({1,2}) do
        test('surviving_god_team'..team..'_cycles',function()
            local s=M.new()
            addModel(s,team==1 and 207 or 13,1,8,9);addModel(s,team==2 and 207 or 953,2,18,9)
            local r,_,ids=start(s);local snapshot=M.copy(s);local god=team==1 and s.units[1] or s.units[2]
            local cycles=team==1 and 2 or 1
            for cycle=1,cycles do
                local label='survivor_team'..team..'_cycle'..cycle
                local godId=r.live[god.id];completedFight(label,ids)
                assert((api.get('unitHp',godId) or 0)>0,'God did not survive the intended weak-opponent fixture')
                closed(label,r,ids)
                local ok,why=r:build(M.copy(snapshot));assert(ok,tostring(why));assert(not r.blocked);checked(r,r.current);verifySetup(r.current,snapshot)
                ids=roster(r.current,r)
            end
            closed('survivor_team'..team..'_final',r,ids)
        end)
    end
    test('multiple_unique_independent_save_load_reset_delete',function()
        assert(caps.multipleUnique==1 and caps.lifecycle==1,'required sandbox-scoped native capabilities missing')
        local uniqueGod=api.get('monsterAbility',207,'unique');local uniqueRider=api.get('monsterAbility',202,'unique')
        local s=M.new();s.allowMultipleUnique=true
        addModel(s,13,1,3,9);addModel(s,953,2,25,9)
        local godA=addModel(s,207,1,5,3);local godB=addModel(s,207,2,22,3)
        local riderA=addModel(s,202,1,6,12);local riderB=addModel(s,202,2,20,12)
        local priest=addModel(s,208,1,3,17)
        local r,d,ids=start(s);local before=checked(r,s)
        local state=lifecycle('multi_initial');assert(state.allowMultipleUnique and state.complete and state.creationDepth==0 and state.uniqueOverrideDepth==0)
        assert(api.testFieldState().allowMultipleUnique,'native mode missing from field state')
        assert(r.live[godA.id]~=r.live[godB.id] and r.live[riderA.id]~=r.live[riderB.id])
        assert(api.get('unitOwner',r.live[godA.id])==0 and api.get('unitOwner',r.live[godB.id])==24)
        for label,u in pairs({godA=godA,godB=godB,riderA=riderA,riderB=riderB}) do
            local row=api.testFieldUnitState(r.live[u.id]);assert(row and row.alive and row.anchorCount==1)
            assert(#row.occupied==row.width*row.height,'large unique footprint incomplete')
            local cells={}
            for _,cell in ipairs(row.occupied) do
                assert(api.battleUnitAt(cell.x,cell.y)==r.live[u.id],'large unique interior hit selection mismatched')
                cells[#cells+1]=cell.x..','..cell.y
            end
            results['multi_footprint_'..label]={model_id=u.id,native_id=r.live[u.id],team=u.team,x=u.x,y=u.y,width=row.width,height=row.height,cells=table.concat(cells,';')}
        end
        local godBState=before.signatures[r.live[godB.id]]
        local spell=godA.spells[1];assert(spell,'God has no memorized spell for independence test')
        assert(r:memorize(godA,spell,false),'God spell edit refused')
        api.giveItem(r.live[godA.id],'A Chest Full of Fire');godA.items=r:inventory(r.live[godA.id]);assert(#godA.items>0,'God item not assigned')
        if godA.equipment then local L=require('sandbox.loadout');L.capture(r,godA,assert(L.read(r,r.live[godA.id])))end
        assert(#priest.spells>0 and r:memorize(priest,priest.spells[1],false),'custom priest state unavailable')
        before=checked(r,s);assert(before.signatures[r.live[godB.id]]==godBState,'editing God A changed God B')
        local godTemplate=M.copy(godA);local godOld=r.live[godA.id];local ok,candidate=r:remove(s,godA);assert(ok,tostring(candidate));s=candidate
        local after=checked(r,s,before);assert(after.signatures[r.live[godB.id]]==godBState and (api.get('unitHp',godOld) or 0)==0,'deleting God A changed God B')
        local vacant=api.testFieldUnitState(godOld);assert(vacant and vacant.anchorCount==0 and #vacant.occupied==0,'deleted unique footprint remains')
        ok,candidate,godA=r:add(s,207,1,5,3,godTemplate);assert(ok,tostring(candidate));s=candidate
        checked(r,s,after);assert(r.live[godA.id]~=r.live[godB.id],'replacement God aliased opposite team')
        local denied=M.copy(s);denied.allowMultipleUnique=false;local stable=checked(r,s);local last=api.get('unitLastIndex')
        ok=r:build(denied);assert(not ok and not r.blocked and r.current==s,'disabling duplicate mode mutated live setup')
        checked(r,s,stable);assert(api.get('unitLastIndex')==last,'Off rejection allocated a unit')
        local snapshot=M.copy(s);assert(api.writeIni('interface-multiple-unique-setup',M.encode(s,c.mods)))
        local loaded,why=M.decode(api.readIni('interface-multiple-unique-setup'),c,c.mods);assert(loaded,why);assert(loaded.allowMultipleUnique)
        ok,why=r:build(loaded);assert(ok,tostring(why));checked(r,loaded);verifySetup(loaded,snapshot)
        capture('multi_loaded',roster(loaded,r));closed('multi_loaded',r,roster(loaded,r))
        local reset=M.copy(snapshot);ok,why=r:build(reset);assert(ok,tostring(why));checked(r,reset);verifySetup(reset,snapshot)
        assert(api.get('monsterAbility',207,'unique')==uniqueGod and api.get('monsterAbility',202,'unique')==uniqueRider,'monster definition changed')
        local name,path=d:export({fixture='distinct duplicate uniques, edit/delete/reuse, Off refusal, Save/Load/reset'},r:snapshot(reset));assert(name,path)
        results.multi_diagnostic={name=name,distinct_instances=1,spell_item_independence=1,off_refused_before_mutation=1}
        closed('multi_reset',r,roster(reset,r))
        local allowed,reason=api.openTestField{commander=207,spell=-1,enemies={{207,1}},terrain=0}
        assert(not allowed and reason=='unique_count','default unique semantics were changed: '..tostring(reason))
        local final=lifecycle('multi_default_guard');assert(final.creationDepth==0 and final.uniqueOverrideDepth==0)
    end)
    test('duplicate_gods_actual_combat_cleanup',function()
        local s=M.new();s.allowMultipleUnique=true
        addModel(s,207,1,8,9);addModel(s,207,2,18,9)
        local r,_,ids=start(s);local snapshot=M.copy(s)
        completedFight('duplicate_gods',ids)
        local dead,alive=0,0
        for _,id in ipairs(ids) do if (api.get('unitHp',id) or 0)>0 then alive=alive+1 else dead=dead+1 end end
        results.duplicate_gods_outcome={dead_original_gods=dead,surviving_original_gods=alive,
            scope='Original saved records after natural combat; no death is assumed. Defeat with post-combat relocation is checked separately.'}
        local state=lifecycle('duplicate_gods_completed')
        assert(state.complete and state.creationDepth==0 and state.uniqueOverrideDepth==0,'God duel tracking not complete')
        closed('duplicate_gods',r,ids)
        local ok,why=r:build(M.copy(snapshot));assert(ok,tostring(why));checked(r,r.current);verifySetup(r.current,snapshot)
        closed('duplicate_gods_reopened',r,roster(r.current,r))
    end)
    test('defeated_unique_actual_combat_cleanup',function()
        assert((api.get('monsterAbility',201,'unique') or 0)>0,'Rider201 fixture is not unique in this catalog')
        local s=M.new();s.allowMultipleUnique=true
        addModel(s,201,1,8,9)
        for _,y in ipairs({1,5,9,13,17}) do addModel(s,201,2,18,y) end
        local r,_,ids=start(s,true);local snapshot=M.copy(s)
        results.defeated_unique_deployment={initial='Native deployment; actual collision-free anchors adopted before snapshot'}
        local loserBefore=raw(ids[1])
        completedFight('defeated_unique',ids)
        local dead,alive,deadA,deadB=0,0,0,0
        for i,id in ipairs(ids) do
            if (api.get('unitHp',id) or 0)<=0 then
                dead=dead+1;if s.units[i].team==1 then deadA=deadA+1 else deadB=deadB+1 end
            else alive=alive+1 end
        end
        local loserAfter=raw(ids[1]);local loserDead=type(loserAfter.hp)=='number' and loserAfter.hp<=0
        local positionsKnown=type(loserBefore.world_x)=='number' and type(loserBefore.world_y)=='number' and
            type(loserAfter.world_x)=='number' and type(loserAfter.world_y)=='number'
        local loserRelocated=positionsKnown and (loserAfter.world_x~=loserBefore.world_x or loserAfter.world_y~=loserBefore.world_y)
        results.defeated_unique_outcome={monster=201,starting_unique_records=#ids,dead_original_uniques=dead,
            surviving_original_uniques=alive,dead_teamA=deadA,dead_teamB=deadB,
            winner=api.get('battleWinner'),losing_native_id=ids[1],losing_hp=loserAfter.hp,
            losing_world_x_before=loserBefore.world_x,losing_world_y_before=loserBefore.world_y,
            losing_world_x_after=loserAfter.world_x,losing_world_y_after=loserAfter.world_y,
            world_coordinates_complete=positionsKnown and 1 or 0,
            losing_record_relocated=loserRelocated and 1 or 0,
            defeated_alive_relocated=not loserDead and loserRelocated and 1 or 0,
            mortality_coverage=dead>0 and 'Original unique HP <= 0 observed before cleanup' or 'No dead original unique observed before cleanup; defeated living relocated record is covered',
            scope='Actual natural-combat result, HP and world-coordinate readback before cleanup; relocation does not assert its underlying flee mechanic.'}
        save()
        assert(api.get('battleWinner')==24,'intended Team B victory was not observed')
        assert(loserDead or loserRelocated,'losing original unique was neither dead nor relocated; defeat lifecycle coverage incomplete')
        closed('defeated_unique',r,ids)
        local ok,why=r:build(M.copy(snapshot));local exact=ok
        results.defeated_unique_deployment.exact_reopen_accepted=ok and 1 or 0
        if not ok then
            results.defeated_unique_deployment.exact_reopen_reason=tostring(why)
            assert(not r.blocked,'exact-position retry left unverified state')
            ok,why=r:build(M.copy(snapshot),true)
        end
        assert(ok,tostring(why));checked(r,r.current);verifySetup(r.current,snapshot,exact)
        results.defeated_unique_deployment.reopen=exact and 'Exact saved positions restored' or 'Explicit native redeployment; roster, teams, unique mode, spells and items verified; positions intentionally changed'
        closed('defeated_unique_reopened',r,roster(r.current,r))
    end)
end
save()
