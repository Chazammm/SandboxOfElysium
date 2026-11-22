-- Opt-in isolated CoE5 test. Combat decisions and damage remain native.
local api=coe5
local M=require('sandbox.model')
local U=require('sandbox.ui')
local Objects=require('sandbox.battlefield_objects')
local fixture=api.readIni('request').run.only
local out={environment=api.readIni('launcher-context').environment}
local started,fighting,editor=false,false,nil
local objectHandles,damage={},{}
api.wrap('BATTLE_WAIT',function(next,...)
    local v=next(...)
    if fighting and v==0 and api.get('battleDelay')>2 then return 1 end
    return v
end)
api.observe('DAMAGE_UNIT',function(id)
    if fighting and objectHandles[id] then damage[id]=(damage[id] or 0)+1 end
end)
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local function free(r,start)
    for x=start,r.width-1 do for y=5,14 do
        if api.battleUnitAt(x,y)<0 and api.battleObjectAt(x,y)<0 then return x,y end
    end end
    error('No open fixture cell')
end

api.wrap('MAIN_MENU_WAIT',function(next,...)
    local v=next(...)
    if started then return v end
    started=true
    local ok,why=xpcall(function()
        editor=U.new(api);editor:ensureCatalog()
        editor.notice=function(self,message)self.message=message end
        editor.results=function()return 'controls' end
        local r=editor.runtime
        local s=M.new()
        local terrains={castle=22,town=17,city=9,citadel=23,water=27,farm=5}
        s.terrain=terrains[fixture] or 0
        s.minimumWidth,s.size=50,'Minimum width'
        s.colors={3,3};editor.scenario=s
        local discovered=assert(api.testFieldSceneryTypes())
        assert(discovered.version==1)
        local nativeTypes={}
        for i,row in ipairs(discovered.types) do
            nativeTypes[row.monster]=true
            out['type'..i]={status='PASS',id=row.monster,name=api.get('monsterName',row.monster),layer=row.layer}
        end
        assert(nativeTypes[1404] and nativeTypes[1448] and nativeTypes[1634],'Expected native types unavailable')
        assert(r:build(s,M.isSiegeTerrain(s.terrain)))
        if fixture=='water' then
            local id,reason=api.addTestFieldScenery(1404,10,10)
            assert(not id and reason=='water_scenery_unverified',reason)
            assert(r:ready(s))
            out.water={status='PASS',detail=reason}
            return
        end
        editor.phase,editor.native='prepare',true;editor:prepareLog()
        api.drawTestField()
        local spear=assert(api.findMonster('Spearman'))
        local function place(monster,team,start,copy)
            local x,y=free(r,start)
            local good,next,unit=r:add(editor.scenario,monster,team,x,y,copy)
            assert(good,next);editor.scenario=next
            return unit
        end
        editor:dispatch('team3')
        local id,refusal=api.addTestFieldScenery(spear,10,10)
        assert(not id and refusal=='unsupported_scenery',refusal)
        for _,unavailable in ipairs({spear,1634}) do
            local typeInfo=assert(editor.catalog.byId[unavailable])
            editor.search=typeInfo.name;editor:refresh();assert(#editor.filtered==0)
            editor.filtered={typeInfo}
            assert(editor:dispatch('unit:1') and editor.selected==nil)
            editor.selected=unavailable;editor.formation=2;editor.n=3
            assert(editor:dispatch({place=true,x=10,y=10}) and M.count(editor.scenario,3)==0)
            assert(not r:add(editor.scenario,unavailable,3,10,10))
            local copy={id=99,team=3,scenery=true,monster=unavailable,name=typeInfo.name}
            assert(not r:add(editor.scenario,unavailable,3,10,10,copy))
            editor.context={unit=copy};editor.selected=nil
            assert(editor:dispatch('context:Copy') and editor.copyTemplate==nil and editor.selected==nil)
            for _,team in ipairs({1,2}) do
                editor:dispatch('team'..team)
                local found=false
                for _,entry in ipairs(editor.filtered) do if entry.id==unavailable then found=true end end
                assert(found)
            end
            assert(editor:dispatch('team3'))
            api.drawTestField()
        end
        editor.search='';editor:refresh()
        assert(#editor.filtered==142)
        for _,count in ipairs({107,25,10,0,142}) do
            assert(editor:dispatch('filter') and #editor.filtered==count)
        end
        assert(editor:dispatch('filter'))
        editor.search='Stairs';editor:refresh();assert(#editor.filtered==0 and editor.neutralGroupAvailable)
        assert(editor:dispatch('filter') and #editor.filtered==0)
        assert(editor:dispatch('filter') and #editor.filtered==10)
        editor.search='';editor:dispatch('filter');editor:dispatch('filter')
        local monster=fixture=='town' and 1448 or 1404
        local second=monster==1448 and 1404 or 1448
        local object=place(monster,3,12)
        assert(not editor:fight() and editor.message:find('each team',1,true))
        local accepted,detail=api.fightTestField();assert(not accepted and detail=='missing_team_a',detail)
        local a=place(fixture=='farm' and assert(api.findMonster('Pyromancer')) or spear,1,7)
        local b=place(spear,2,30)
        if fixture=='farm' then
            place(assert(api.findMonster('Archer')),2,22)
            place(spear,1,18)
        end
        api.drawTestField()
        local function verify(u)
            local good,verified=r:ready(editor.scenario);assert(good,verified)
            local handle=r.live[u.id]
            local row=assert(verified.rows[handle])
            assert(row.owner==31 and row.creationSource=='owned_scenery_placement' and row.monster==u.monster)
            assert(api.battleObjectAt(u.x,u.y)==handle and api.battleUnitAt(u.x,u.y)<0)
            assert(editor:unitAt(u.x,u.y).id==u.id)
            return handle,row,verified
        end
        local handle,row,verified=verify(object)
        assert(not r:move(object,a.x,a.y))
        assert(not r:add(editor.scenario,monster,3,object.x,object.y))
        assert(not r:add(editor.scenario,monster,1,13,14,object))
        local stale=api.moveTestFieldScenery(handle,verified.native.session,row.generation+1,22,10);assert(not stale)
        local x,y=free(r,20)
        local fromX,fromY=object.x,object.y
        assert(r:move(object,x,y))
        local moved,movedRow=verify(object)
        assert(moved==handle and movedRow.generation==row.generation and api.battleObjectAt(fromX,fromY)<0)
        assert(verify(object)==handle)
        editor.context={unit=object};editor:dispatch('context:Copy')
        x,y=free(r,21)
        editor.formation=1;assert(editor:dispatch({place=true,x=x,y=y}))
        local copied=assert(M.at(editor.scenario,x,y))
        assert(copied.scenery and copied.id~=object.id and copied.monster==object.monster)
        local copyHandle=verify(copied);assert(copyHandle~=handle)
        local removed,next=r:remove(editor.scenario,copied);assert(removed,next);editor.scenario=next
        assert(api.battleObjectAt(x,y)<0 and api.get('unitHp',copyHandle)==-9999)
        place(second,3,19)
        api.drawTestField()
        for i,kind in ipairs({1394,1395,1446,1462,1511}) do
            local feature=place(kind,3,14+i)
            local id,original=verify(feature)
            local tx,ty=free(r,25+i)
            assert(r:move(feature,tx,ty))
            local _,moved=verify(feature)
            assert(moved.generation==original.generation)
            local copied=place(kind,3,16+i,feature)
            local copyId=verify(copied)
            assert(copyId~=id)
            local retired,after=r:remove(editor.scenario,copied)
            assert(retired,after);editor.scenario=after
            assert(api.battleObjectAt(copied.x,copied.y)<0 and api.get('unitHp',copyId)==-9999)
            local team=i%2+1
            local success,next,occupant=r:add(editor.scenario,spear,team,tx,ty)
            assert(success,next);editor.scenario=next
            local actor=r.live[occupant.id]
            assert(api.battleUnitAt(tx,ty)==actor and api.battleObjectAt(tx,ty)==id)
            assert(api.battleCanStand(actor,tx,ty,0) and api.battleCanStand(actor,tx,ty,4))
            local _,why=r:remove(editor.scenario,feature)
            assert(why:find('Move the unit off',1,true),why)
            local _,why=r:move(feature,tx,ty+1)
            assert(why:find('Move the unit off',1,true),why)
            out['shared'..kind]={status='PASS',id=kind,team=team,generation=moved.generation,
                hp=moved.hp,cover=api.battleWallCover(actor,0),second_cover=api.battleWallCover(actor,1),
                occupied_refusals=1,copy_retired=1}
            api.drawTestField()
        end
        assert(r:place(M.copy(editor.scenario)))
        assert(r:ready(editor.scenario))
        api.drawTestField()
        out.edit={status='PASS',move_identity=1,copy=1,retired=1,neutral_catalog='1394,1395,1404,1446,1448,1462,1511',
            excluded_plants=1,excluded_ordinary_units=1}
        local filename='scenery-fixture-'..fixture..'-'..api.get('ticksMs')
        local encoded=M.encode(editor.scenario,editor.catalog.mods)
        assert(encoded.scenario.schema==6)
        editor.prompt=function()return filename end;editor:save()
        assert(equal(api.readIni(filename),encoded) or M.decode(api.readIni(filename),editor.catalog,editor.catalog.mods))
        editor.menu=function(_,_,rows)for _,r in ipairs(rows) do if r[2]==filename then return r[1] end end;return 999 end
        editor:load()
        assert(equal(M.encode(editor.scenario,editor.catalog.mods),encoded))
        local unsupported=M.copy(editor.scenario)
        for _,u in ipairs(unsupported.units) do
            if u.scenery then u.monster,u.name=1634,'Cabbage';break end
        end
        local unsupportedFile='scenery-unsupported-'..fixture..'-'..api.get('ticksMs')
        assert(api.writeIni(unsupportedFile,M.encode(unsupported,editor.catalog.mods)))
        local original=assert(api.readIni(unsupportedFile))
        editor.menu=function(_,_,rows)for _,r in ipairs(rows) do if r[2]==unsupportedFile then return r[1] end end;return 999 end
        local active=editor.scenario
        editor:load()
        assert(editor.message:find('Cabbage is unavailable in Neutral',1,true)
            and editor.message:find('original scenario file is kept',1,true))
        assert(editor.scenario==active and equal(api.readIni(unsupportedFile),original))
        local rebuilt,unsupportedReason=r:build(unsupported)
        assert(not rebuilt and unsupportedReason:find('Cabbage is unavailable in Neutral',1,true),unsupportedReason)
        assert(r:ready(active))
        out.unsupported_save={status='PASS',scenario_unchanged=1,file_unchanged=1,rebuild_refused=1}
        api.drawTestField()
        local prior=M.copy(editor.scenario);local invalid=M.copy(prior)
        for _,u in ipairs(invalid.units) do if u.scenery then u.x=r.width;break end end
        local rebuilt,reason=r:build(invalid)
        assert(not rebuilt and reason:find('Previous army restored',1,true),reason)
        assert(r:ready(editor.scenario))
        local legacy=M.copy(prior)
        for _,u in ipairs(legacy.units) do if u.scenery then u.scenery=nil end end
        local opened,legacyReason=M.decode(M.encode(legacy,editor.catalog.mods),editor.catalog,editor.catalog.mods)
        assert(not opened and legacyReason==M.legacyNeutralProblem)
        local fixed,natural={},{}
        local authoredTypes={}
        for _,u in ipairs(prior.units) do if u.scenery then authoredTypes[u.monster]=true end end
        for _,entry in ipairs(assert(api.testFieldLifecycle()).created) do
            if Objects.role(entry)=='structure' then fixed[#fixed+1]=entry.unit
            elseif Objects.role(entry)=='scenery' and authoredTypes[entry.monster] then
                objectHandles[entry.unit]=true
                natural[entry.unit]=entry.monster
            end
        end
        if M.isSiegeTerrain(s.terrain) then assert(#fixed>0,'Native gate missing') end
        for _,u in ipairs(editor.scenario.units) do if u.scenery then objectHandles[r.live[u.id]]=true end end
        local function fight(rematch)
            fighting=true
            local good=rematch and editor:postBattle('rematch') or editor:fight()
            fighting=false
            assert(good and editor.phase=='after',editor.message)
            local report=editor.report.result
            assert(report.teamA.start==M.count(prior,1) and report.teamB.start==M.count(prior,2) and report.neutral.start==0)
            assert(report.summary.winner~=31)
            return report
        end
        local report=fight(false)
        local final=assert(r.finalState)
        assert(final.complete,'Native capture incomplete')
        local authored,naturalMatched=0,0
        for _,row in ipairs(final.units) do if row.creationSource=='owned_scenery_placement' then
            authored=authored+1
            out['final'..authored]={status='PASS',id=row.monster,hp=row.hp,anchors=row.anchorCount,layer=row.anchorCount>0 and row.anchorLayer or 'off_field',
                life=row.status,damage_calls=damage[row.unit] or 0}
        elseif natural[row.unit] and row.monster==natural[row.unit] and Objects.role(row)=='scenery' then
            naturalMatched=naturalMatched+1
            if naturalMatched<=4 then out['natural'..naturalMatched]={status='PASS',id=row.monster,owner=row.owner,
                hp=row.hp,anchors=row.anchorCount,layer=row.anchorCount>0 and row.anchorLayer or 'off_field',life=row.status,damage_calls=damage[row.unit] or 0} end
        end end
        assert(authored==M.count(prior,3))
        assert(editor:postBattle('restore') and r:ready(editor.scenario))
        assert(equal(M.encode(editor.scenario,editor.catalog.mods),encoded))
        assert(editor:reset(false));fight(true)
        assert(editor:postBattle('restore') and r:ready(editor.scenario))
        assert(equal(M.encode(editor.scenario,editor.catalog.mods),encoded))
        out.battle={status='PASS',winner=report.summary.winner,round=report.summary.final_round,
            fixed_gates=#fixed,final_objects=authored,matching_natural_objects=naturalMatched,
            restore=1,reset=1,rematch=1,save_load=1,rejected_restore=1}
    end,tostring)
    if editor and editor.runtime.open then
        local cleaned,detail=editor.runtime:close()
        local life=api.testFieldLifecycle()
        out.cleanup={status=cleaned and life and life.complete and not life.open and 'PASS' or 'FAIL',detail=detail}
        if out.cleanup.status~='PASS' then ok=false;why=why or 'Cleanup failed' end
    end
    out.complete={status=ok and 'PASS' or 'FAIL',detail=tostring(why or 'Verified scenery editor workflow')}
    assert(api.writeIni('results',out))
    return v
end,-100)
