-- Own native regression, activated explicitly in the private launcher profile.
local api=coe5
-- coe5.setTestFieldSpells became part of coe5.setTestFieldConfiguration (CoE5SE pull request #2):
-- this keeps the unit's own items and school levels and sets only the two spell lists.
local function setSpells(unit,state)
    local loadout,why=api.testFieldLoadoutState(unit)
    if not loadout then return false,why end
    local items={}
    for i=1,20 do local slot=loadout.items[i];items[i]=slot and slot.id or -1 end
    local schools={}
    for _,school in ipairs(loadout.schools) do schools[#schools+1]={school.path,school.base} end
    return api.setTestFieldConfiguration(unit,{items=items,schools=schools,known=state.known,memorized=state.memorized})
end
local M=require('sandbox.model')
local C=require('sandbox.catalog')
local results={environment={scope='actual native game API, no simulated combat'}}
local probeFight,probeProjection=false,false
local function save() api.writeIni('editing-results',results) end
local function spells(unit,key,max)
    local out={};for i=0,max do local id=api.get(key,unit,i);if not id or id<0 then break end
        local info=api.spellInfo(id);out[#out+1]=id..':'..(info and info.name or '?')
    end;return table.concat(out,'|')
end
local function signature(unit)
    local items={};for i=0,7 do items[#items+1]=tostring(api.get('unitItem',unit,i)) end
    return table.concat({tostring(unit),tostring(api.get('unitHp',unit)),spells(unit,'unitKnownSpell',59),spells(unit,'unitMemorizedSpell',29),table.concat(items,','),tostring(api.get('unitBattleX',unit)),tostring(api.get('unitBattleY',unit))},';')
end
local function scenario()
    local s=M.new();M.add(s,api.findMonster('Anointed Priestess'),'Anointed Priestess',1,8,9)
    M.add(s,api.findMonster('Goblin'),'Goblin',2,18,9);return s
end
local function test(name,fn)
    local ok,err=xpcall(fn,function(e)return tostring(e) end)
    probeFight=false;probeProjection=false
    results[name]=results[name] or {};results[name].status=ok and 'PASS' or 'FAIL';results[name].detail=ok and 'actual native calls' or err
    api.closeTestField();save()
end
local function baseline()
    local R=require('baseline.runtime');local c=C.read(api)
    local configure=R.configure;local mismatches=0
    function R:configure(u,unit)
        local actual=self:spellList(unit,'unitKnownSpell',59)
        if u.baseline and table.concat(actual,'|')~=table.concat(u.baseline.known,'|') then
            mismatches=mismatches+1;results['mismatch'..mismatches]={name=u.name,unit=unit,saved_known=table.concat(u.baseline.known,'|'),actual_known=table.concat(actual,'|'),saved_memorized=table.concat(u.spells,'|'),actual_memorized=spells(unit,'unitMemorizedSpell',29)}
        end
        return configure(self,u,unit)
    end
    test('old_rebuild_priestess',function()
        local s=scenario();local r=R.new(api,c);assert(r:build(s,true))
        results.original={unit=r.live[1],known=spells(r.live[1],'unitKnownSpell',59),memorized=spells(r.live[1],'unitMemorizedSpell',29)}
        local failure
        for i=1,12 do
            local ok,nextScenario=r:add(s,api.findMonster('Spearman'),1,3+i,3)
            results['old_add'..i]={accepted=ok and 1 or 0,field_open=r.open and 1 or 0,detail=tostring(nextScenario),unit=tostring(r.live[1])}
            if not ok then failure=tostring(nextScenario);break end;s=nextScenario
        end
        assert(failure and failure:find('starting spells changed'),'priestess mismatch was not reproduced in this sequence')
    end)
    test('existing_incremental_add',function()
        local r=R.new(api,c);local s=scenario();assert(r:build(s,true))
        local original=r.live[1];assert(api.moveTestFieldUnit(original,6,6));s.units[1].x=6;s.units[1].y=6
        local before=signature(original)
        for i=1,5 do
            local added=api.addTestFieldUnits('friends',{{api.findMonster('Spearman'),1}});assert(added and #added==1)
            assert(signature(original)==before,'existing priestess changed during native add')
        end
        results.incremental={original_unit=original,known=spells(original,'unitKnownSpell',59),preserved=1}
    end)
end
local function regression()
    local R=require('sandbox.runtime');local D=require('sandbox.diagnostics');local Report=require('sandbox.report');local c=C.read(api)
    local function fresh(terrain)
        local d=D.new(api);local r=R.new(api,c,d);local s=scenario();s.terrain=terrain or 0
        local ok,why=r:build(s,true);assert(ok,why);return r,s,d
    end
    test('incremental_priestess_both_teams_and_copy_move',function()
        local r,s,d=fresh();local original=r.live[1]
        api.giveItem(original,'A Chest Full of Fire');s.units[1].items=r:inventory(original)
        if s.units[1].equipment then local L=require('sandbox.loadout');L.capture(r,s.units[1],assert(L.read(r,original)))end
        assert(#s.units[1].items>0,'configured item fixture not accepted')
        local spell=s.units[1].spells[1];if spell then assert(r:memorize(s.units[1],spell,false)) end
        assert(r:move(s.units[1],6,6));local before=signature(original)
        for i=1,12 do
            local ok,nextScenario=r:add(s,api.findMonster('Spearman'),i%2+1,3+i,3)
            assert(ok,nextScenario);s=nextScenario
            assert(r.live[1]==original and signature(original)==before,'old priestess changed on add '..i)
        end
        local ok,nextScenario,copy=r:add(s,s.units[1].monster,1,10,8,s.units[1]);assert(ok,nextScenario);s=nextScenario
        assert(r:move(copy,12,8));assert(signature(original)==before)
        assert(table.concat(r:spellList(r.live[copy.id],'unitKnownSpell',59),'|')==table.concat(s.units[1].baseline.known,'|'))
        assert(table.concat(r:spellList(r.live[copy.id],'unitMemorizedSpell',29),'|')==table.concat(s.units[1].spells,'|'))
        assert(table.concat(r:inventory(r.live[copy.id]),'|')==table.concat(s.units[1].items,'|'))
        ok,nextScenario=r:remove(s,copy);assert(ok,nextScenario);s=nextScenario;assert(signature(original)==before)
        results.incremental_fixed={adds=12,both_teams=1,existing_id=original,existing_state_unchanged=1,copy=1,move=1,item='A Chest Full of Fire',known=spells(original,'unitKnownSpell',59)}
        r:close()
    end)
    test('native_spell_validation_and_primary_guard',function()
        local r,s=fresh();local unit=r.live[1];local before=signature(unit)
        assert(r.emptyEditor and r.primaryId==nil,'production runtime did not use the commander-free editor')
        local id=tonumber(s.units[1].baseline.known[1]:match('^(%d+):'))
        local bad={{known={id,id},memorized={}},{known={-1},memorized={}},{known={[2]=id},memorized={}},{known={},memorized={id}},{known={'1'},memorized={}},{known=true,memorized={}}}
        for i,state in ipairs(bad) do local ok,why=setSpells(unit,state);assert(not ok and why,'bad state accepted '..i);assert(signature(unit)==before) end
        local ok,why=setSpells(-1,{known={},memorized={}});assert(not ok and why=='bad_unit')
        local removed,candidate=r:remove(s,s.units[1]);assert(removed,tostring(candidate));s=candidate
        assert(#s.units==1 and M.count(s,1)==0 and M.count(s,2)==1 and r.live[1]==nil,'first ordinary Team A unit could not be removed')
        local ready,reason=r:ready(s);assert(ready,tostring(reason));assert((api.get('unitHp',unit)or 0)<=0)
        local closed,closeWhy=r:close();assert(closed,tostring(closeWhy))
        -- Legacy callers still deliberately create a protected commander. That
        -- contract must be tested with a legacy call, not with the new editor.
        local opened,legacy=api.openTestField{commander=api.findMonster('Anointed Priestess'),spell=-1,enemies={{api.findMonster('Goblin'),1}},terrain=0}
        assert(opened,tostring(legacy));assert(legacy.emptyEditor==false and legacy.commander>=0)
        local legacyBefore=signature(legacy.commander)
        removed,reason=api.removeTestFieldUnit(legacy.commander)
        assert(not removed and reason=='primary_commander','legacy primary commander was not protected')
        assert(signature(legacy.commander)==legacyBefore,'legacy primary refusal changed its configuration')
        closed,closeWhy=api.closeTestField();assert(closed,tostring(closeWhy))
        results.spell_guards={refused=#bad+2,original_unchanged=1,original_unchanged_before_removal=1,new_mode_first_a_removed=1,new_mode_remaining_b=1,legacy_primary_refused=1,
            scope='Malformed-spell refusals leave the ordinary actor unchanged; its subsequent deliberate removal is permitted; legacy commander protection is separate'}
    end)
    test('save_load_rollback_reset_rematch_priestess',function()
        local r,s=fresh();local known=table.concat(s.units[1].baseline.known,'|');local mem=table.concat(s.units[1].spells,'|')
        local name='priestess-scenario-'..tostring(api.get('ticksMs'))
        assert(api.writeIni(name,M.encode(s,c.mods)));local loaded,why=M.decode(api.readIni(name),c,c.mods);assert(loaded,why)
        local ok;ok,why=r:build(loaded);assert(ok,why);s=loaded
        assert(spells(r.live[1],'unitKnownSpell',59)==known and spells(r.live[1],'unitMemorizedSpell',29)==mem)
        local bad=M.copy(s);bad.units[1].x=-1;ok,why=r:build(bad);assert(not ok and r.open,'bad rebuild did not keep previous army')
        assert(spells(r.live[1],'unitKnownSpell',59)==known and spells(r.live[1],'unitMemorizedSpell',29)==mem)
        local snapshot=M.copy(s);local denied=0
        local observer=api.observe('BATTLE_ADVANCE_UNIT',function()
            if not probeFight then return end
            local accepted,reason=setSpells(r.live[1],{known={},memorized={}})
            if not accepted and reason=='in_fight' then denied=denied+1 end
        end)
        local report=Report.new(api)
        for i=1,2 do
            report:start(s,r);probeFight=true;api.fightTestField();probeFight=false;report:finish(s,r);assert(report:export('priestess-fight-'..i))
            ok,why=r:build(M.copy(snapshot));assert(ok,why)
            assert(spells(r.live[1],'unitKnownSpell',59)==known and spells(r.live[1],'unitMemorizedSpell',29)==mem)
            for _,u in ipairs(snapshot.units) do assert(api.get('unitBattleX',r.live[u.id])==u.x and api.get('unitBattleY',r.live[u.id])==u.y) end
        end
        results.restore_fixed={save_load=1,failed_rebuild_restored=1,reset=1,rematch=1,in_fight_refusals=denied,known=known,memorized=mem}
        assert(denied>0,'in-fight guard not exercised');r:close()
    end)
    test('diagnostics_error_export_no_overwrite',function()
        local r,s,d=fresh();local unit=r.live[1];local before=signature(unit)
        local ok=r:add(s,api.findMonster('Spearman'),1,-1,0);assert(not ok);assert(signature(unit)==before)
        local first,path=d:export({team=1,terrain=s.terrain,phase='prepare'},r:snapshot(s));assert(first,path)
        local firstData=api.readIni(first);assert(firstData.error and firstData.before_unit1 and firstData.after_unit1)
        assert(firstData.before_unit1.saved_known~='' and firstData.after_unit1.actual_known~='')
        local second=d:export({team=1,terrain=s.terrain},r:snapshot(s));assert(second and first~=second);assert(api.readIni(first))
        results.diagnostics={first=first,second=second,error=firstData.error.message,restored=firstData.error.restored,
            version=firstData.environment.sandbox_version,extender=firstData.environment.extender_version,unique=1,before_after=1}
        r:close()
    end)
    test('native_projection_and_terrain',function()
        local checked,waitChecked=0,0
        api.wrap('BATTLE_WAIT',function(next,b,m)
            local id=next(b,m)
            if probeProjection then
                local v=api.battleView();assert(v and v.cellSize>0,'view unavailable after WAIT next')
                local sx,sy=api.battleCellToScreen(4,4);local x,y=api.battleScreenToCell(sx,sy)
                assert(x==4 and y==4,'post-WAIT coordinate conversion failed')
                waitChecked=waitChecked+1
                results.wait_projection={after_next=1,checks=waitChecked,cell_x=x,cell_y=y}
            end
            return id
        end)
        local wrapper=api.wrap('BATTLE_DRAW',function(next)
            local result=next();if not probeProjection then return result end;local v=api.battleView();assert(v and v.cellSize>0)
            local roundtrips=0
            for x=0,v.width-1 do for y=0,19 do local sx,sy=api.battleCellToScreen(x,y)
                if sx>=0 and sy>=0 and sx<v.screenW and sy<v.screenH then local cx,cy=api.battleScreenToCell(sx,sy);assert(cx==x and cy==y,'native projection mismatch');roundtrips=roundtrips+1 end
            end end
            assert(roundtrips>0);checked=checked+1
            results['projection'..checked]={cells=roundtrips,cell_size=v.cellSize,origin_x=v.originX,origin_y=v.originY,screen_w=v.screenW,screen_h=v.screenH,window_w=v.windowW,window_h=v.windowH}
            return result
        end)
        for _,terrain in ipairs({0,2}) do local r,s=fresh(terrain);probeProjection=true;api.drawTestField();probeProjection=false;assert(api.get('squareTerrain',1,1)==terrain);r:close() end
        assert(checked>=2 and waitChecked>=2)
    end)
end
local request=api.readIni('request')
if request and request.run then
    if request.run.mode=='baseline' then baseline()
    elseif request.run.defer=='1' then
        local started=false
        api.addMainMenuButton('Editing regression (private)',function()if not started then started=true;regression()end end)
    else regression()end
end
