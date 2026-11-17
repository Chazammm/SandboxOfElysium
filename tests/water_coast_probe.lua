-- Opt-in isolated real-game acceptance. A normal Sandbox launch never loads this.
-- request.ini [run]: terrain=78, minimum=50. Open-water acceptance is a
-- separate matrix in water_field_probe.lua, never inferred from this coast test.
local api=coe5
local M=require('sandbox.model')
local C=require('sandbox.catalog')
local R=require('sandbox.runtime')
local D=require('sandbox.diagnostics')
local U=require('sandbox.ui')
local L=require('sandbox.loadout')
local request=(api.readIni('request')or{}).run or{}
local preset=tonumber(request.terrain or request.only)or 78
local minimum=tonumber(request.minimum)or 50
local fixtures={
    [78]={name='Coastal Hamlet',template='coastville',atSea=false,accepted=true},
    [10]={name='Lake',accepted=false,reason='Open-water actor/context contract is not accepted by this probe.'},
    [27]={name='Sea',accepted=false,reason='Sea is not accepted by this coast-only matrix; use water_field_probe.lua.'},
}
local fixture=fixtures[preset]
local launcher=api.readIni('launcher-context')or{}
local result={environment=launcher.environment or{},request={terrain=preset,minimum=minimum},
    scope={transport='Not tested: no ships, passengers or transport state are created.',
        world_readback='Borrowed center, adjacent 3x3 square getters, plane0 and listed global getters only.'}}
local started,fighting,active=false,false,nil
local movements,steps=0,{}
local waterWatch,damageBefore={},{}
local waterDamageEvents,waterOneHpEvents=0,0
local function equal(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not equal(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local function ini(v)
    if type(v)=='boolean'then return v and 1 or 0 end
    if type(v)~='table'then return v end
    local out={};for k,value in pairs(v)do out[k]=ini(value)end;return out
end
local function save()assert(api.writeIni('results',ini(result)))end
local function finish(status,detail)
    result['terrain'..preset]={status=status,detail=detail}
    result.complete={status=status};save()
end
local function healthy(r,s)
    local ok,why=r:ready(s);assert(ok,why)
    local state=assert(api.testFieldState())
    assert(state.complete and #state.issues==0,'Incomplete native unit/grid snapshot')
    return state
end
local function actor(s,id)
    for _,u in ipairs(s.units)do if u.id==id then return u end end
    error('Model actor disappeared: '..tostring(id))
end
local function free(r,id)
    for x=2,r.width-3 do for y=2,17 do
        if api.battleUnitAt(x,y)<0 and api.battleObjectAt(x,y)<0 and api.battleCanStand(id,x,y,0)then return x,y end
    end end
    error('No native standable free cell')
end
local function world()
    local t={}
    for _,key in ipairs({'worldW','worldH','activePlayer','battleDelay','planeLastIndex'})do t[key]=tostring(api.get(key))end
    for x=0,2 do for y=0,2 do
        for _,key in ipairs({'squareTerrain','squareGround','squareTemperature','squareArmy','squareOwner','squareArmyOwner','squarePlane'})do t[key..x..'_'..y]=tostring(api.get(key,x,y))end
    end end
    for _,key in ipairs({'planeX','planeY','planeWidth','planeHeight'})do t[key]=tostring(api.get(key,0))end
    return t
end
api.observe('BATTLE_ADVANCE_UNIT',function(unit)
    if fighting then steps[unit]={x=api.get('unitBattleX',unit),y=api.get('unitBattleY',unit)}end
end,function(_,unit)
    local previous=steps[unit]
    if fighting and previous and(previous.x~=api.get('unitBattleX',unit)or previous.y~=api.get('unitBattleY',unit))then movements=movements+1 end
    steps[unit]=nil
end)
-- The retained upstream hook contract supplies unit before the call and
-- (returnValue, unit) afterwards. A one-HP delta is observed, never fabricated
-- or attributed exclusively to drowning without a native damage-source API.
api.observe('DAMAGE_UNIT',function(unit)
    local watched=waterWatch[unit]
    if fighting and watched and api.get('unitBattleX',unit)==watched.x and api.get('unitBattleY',unit)==watched.y then
        damageBefore[unit]=api.get('unitHp',unit)
    end
end,function(_,unit)
    local before=damageBefore[unit];damageBefore[unit]=nil
    if fighting and before then
        local after=api.get('unitHp',unit)
        if type(after)=='number'and after<before then
            waterDamageEvents=waterDamageEvents+1
            if before-after==1 then waterOneHpEvents=waterOneHpEvents+1 end
        end
    end
end)
api.wrap('BATTLE_WAIT',function(next,...)
    local value=next(...)
    if fighting and value==0 and(api.get('battleDelay')or 0)>2 then return 1 end
    return value
end)
api.wrap('MAIN_MENU_WAIT',function(next,...)
    local value=next(...);if started then return value end;started=true
    -- Blocked means untested, not a successful rejection/acceptance matrix. In
    -- particular, neither these placeholders nor a missing native capability
    -- can invoke openTestField, close an existing field or synthesize metadata.
    if not fixture or not fixture.accepted then
        finish('BLOCKED',fixture and fixture.reason or'No accepted fixture for this terrain ID.')
        return value
    end
    if minimum~=32 and minimum~=50 and minimum~=70 and minimum~=160 then
        finish('BLOCKED','minimum must be one of the editor presets: 32, 50, 70, 160.')
        return value
    end
    local c=C.read(api)
    if M.terrainNames[preset]~=fixture.name or not c.testFieldTerrains[preset]then
        finish('BLOCKED','Exact production terrain identity and native capability advertisement are required.')
        return value
    end
    local environment=c.environment
    if type(environment)~='table'or environment.minimumWidthVersion~=1 then
        finish('BLOCKED','The native minimum-width API is required for this matrix.')
        return value
    end
    if environment.waterContextVersion~=1 or type(api.testFieldWaterState)~='function'then
        finish('BLOCKED','The version1 native water-context and actor-water query APIs are required.')
        return value
    end
    api.set('traceLevel',1);api.keepTraceLines({'bt','bfsize','fs ','defaultground','trees'})
    local before=world()
    local ok,why=xpcall(function()
        for id,name in pairs({[13]='Spearman',[953]='Goblin',[594]="Druid's Apprentice"})do
            assert(c.byId[id]and c.byId[id].name==name,'Loaded fixture identity changed: '..name)
        end
        local s=M.new();s.terrain=preset;s.minimumWidth=minimum;s.size='Minimum width'
        local a=M.add(s,13,'Spearman',1,8,9);M.add(s,13,'Spearman',1,8,11)
        local caster=M.add(s,594,"Druid's Apprentice",1,6,5)
        M.add(s,953,'Goblin',2,18,9);M.add(s,953,'Goblin',2,18,11)
        local r=R.new(api,c,D.new(api));active=r
        local opened,reason=r:build(s,true);assert(opened,reason)
        local state=healthy(r,s);local env=assert(api.testFieldEnvironmentState())
        assert(env.version==1 and env.terrain==preset and env.plane==0 and env.temperature==25)
        assert(env.nativeTemplateObserved and env.nativeTemplate==fixture.template and env.setupReturned and not env.customMapReplaced)
        assert(not env.siege and env.atSea==fixture.atSea and not env.underground and env.fortParts==api.get('terrain',preset,'batmap'))
        assert(env.width>=minimum,'Requested minimum width was not applied')
        result.context=env
        local object,objects=nil,0
        for _,g in ipairs(state.grid)do if g.object>=0 then
            objects=objects+1
            if not object and not api.battleCanStand(r.live[a.id],g.x,g.y,0)then object={monster=api.get('unitMonster',g.object),x=g.x,y=g.y}end
        end end
        assert(objects>0 and object,'Native coast template blocking objects missing')
        assert(r:setNativeName(a,'Coast Guard'));assert(r:setNativeName(caster,'Shore Sage'))
        assert(api.giveItem(r.live[caster.id],'Amulet of Anti Magic'))
        assert(L.capture(r,caster,assert(L.read(r,r.live[caster.id]))))
        local good,observation=r:check(s);assert(good,observation);r:accept(s,observation)
        local expected=M.copy(caster);local id=r.live[a.id];local x,y=free(r,id)
        assert(r:move(a,x,y));assert(r.live[a.id]==id and api.testFieldUnitName(id).name=='Coast Guard')
        local waterBefore=assert(api.testFieldState());local wet,dry
        for _,cell in ipairs(waterBefore.grid)do
            if cell.unit<0 and cell.object<0 and api.battleCanStand(id,cell.x,cell.y,0)then
                local water,why=api.testFieldWaterState(id,cell.x,cell.y);assert(water,why)
                assert(water.version==1 and water.unit==id and water.monster==a.monster and not water.ship)
                if water.cellWater and water.willDrown then wet=wet or water
                elseif not water.cellWater and not water.willDrown then dry=dry or water end
            end
            if wet and dry then break end
        end
        assert(equal(waterBefore,assert(api.testFieldState())),'Read-only native water classification changed the field')
        assert(wet and dry,'The coast must expose both native wet hazard and dry standable cells')
        assert(not wet.waterMobile,'The land fixture unexpectedly has effective native water movement')
        local beforeSwimmer=M.copy(s.units)
        local swimmer=assert(api.findMonster('Deep One'));assert(c.byId[swimmer]and c.byId[swimmer].name=='Deep One')
        local added,nextSetup,swimmerActor=r:add(s,swimmer,2,wet.x,wet.y);assert(added,nextSetup);s=nextSetup;healthy(r,s)
        local swimmerNative=r.live[swimmerActor.id]
        local swimState,swimWhy=api.testFieldWaterState(swimmerNative,wet.x,wet.y);assert(swimState,swimWhy)
        assert(swimState.version==1 and swimState.cellWater and swimState.waterMobile and not swimState.willDrown and not swimState.ship)
        result.swimmer={monster=swimmer,name='Deep One',move_flags=swimState.moveFlags,cell_water=swimState.cellWater,
            will_drown=swimState.willDrown,scope=swimState.scope}
        local removed,nextSetup=r:remove(s,swimmerActor);assert(removed,nextSetup);s=nextSetup;healthy(r,s)
        assert(equal(s.units,beforeSwimmer)and not r.live[swimmerActor.id])
        a=actor(s,a.id);caster=actor(s,caster.id)
        assert(r:move(a,wet.x,wet.y));healthy(r,s)
        result.hazard={unit=id,monster=a.monster,wet_x=wet.x,wet_y=wet.y,dry_x=dry.x,dry_y=dry.y,
            cell_water=wet.cellWater,will_drown=wet.willDrown,move_flags=wet.moveFlags,readonly_query_verified=1,
            native_query_scope=wet.scope,
            source_scope='Native willDrown tests anchor/far footprint corners and effective flags; no interior-cell claim. Damage hook records HP deltas, not exclusive damage cause.'}
        local old=M.copy(s);local accepted,message=r:add(s,13,1,object.x,object.y)
        assert(not accepted,'Native obstacle accepted a ground actor');healthy(r,s);assert(equal(s,old))
        local diagnostic=assert(r.diag:export({fixture='intentional coast obstacle rejection',terrain=preset},r:snapshot(s)))
        result.rejection_diagnostic={name=diagnostic}
        result.obstacle={monster=object.monster,name=api.get('monsterName',object.monster),x=object.x,y=object.y,rejection=tostring(message)}
        x,y=free(r,id);local copied,new,copy=r:add(s,13,2,x,y,a);assert(copied,new);s=new
        a=actor(s,a.id);caster=actor(s,caster.id)
        assert(copy.nativeName=='Coast Guard');assert(r:setNativeName(copy,'Other Guard'))
        assert(equal(caster,expected));healthy(r,s)
        local session=tostring(result.environment.session or'unknown'):gsub('[^%w%-]',''):sub(1,24)
        local file='water-coast-'..preset..'-'..minimum..'-'..session
        assert(api.writeIni(file,M.encode(s,c.mods)))
        local loaded,reason=M.decode(api.readIni(file),c,c.mods);assert(loaded,reason)
        assert(r:build(loaded,false));s=loaded;healthy(r,s);local frozen=M.copy(s)
        local ui=U.new(api);ui.catalog=c;ui.runtime=r;ui.scenario=s;ui.diag=r.diag
        for cycle=1,2 do
            local native=r.live[a.id];local current=actor(s,a.id)
            local water,why=api.testFieldWaterState(native,current.x,current.y);assert(water,why)
            assert(water.willDrown and water.cellWater,'Saved wet fixture no longer has the native water hazard')
            waterWatch={[native]={x=current.x,y=current.y}};damageBefore={}
            fighting=true;assert(ui:fight());fighting=false
            assert(api.get('battleRound')>0)
            result['battle'..cycle]={round=api.get('battleRound'),winner=api.get('battleWinner'),movement_events=movements}
            assert(ui:reset(cycle==1));s=ui.scenario;healthy(r,s)
            assert(equal(M.encode(s,c.mods),M.encode(frozen,c.mods)),'Reset/Rematch changed saved actor configuration')
        end
        waterWatch={};damageBefore={}
        result.hazard.damage_events_while_on_classified_wet_anchor=waterDamageEvents
        result.hazard.one_hp_events=waterOneHpEvents
        result.hazard.damage_observation=waterOneHpEvents>0 and'Observed one-HP loss on the preclassified wet anchor; source not exclusive.'or'No one-HP loss observed before this moving actor left its wet anchor.'
        local unchanged=M.copy(s.units)
        local large=assert(api.findMonster('Apocalyptic Rider'));assert(api.get('monsterName',large)=='Apocalyptic Rider')
        local fp=assert(api.testFieldFootprint(large));local px,py
        for tx=1,r.width-fp.width-1 do
            for ty=1,19-fp.height do
                local clear=true
                for dx=0,fp.width-1 do for dy=0,fp.height-1 do
                    if api.battleUnitAt(tx+dx,ty+dy)>=0 or api.battleObjectAt(tx+dx,ty+dy)>=0 then clear=false end
                end end
                if clear then px,py=tx,ty;break end
            end
            if px then break end
        end
        assert(px,'No large footprint available')
        local placed,new,u=r:add(s,large,1,px,py);assert(placed,new);s=new;healthy(r,s)
        local native=r.live[u.id]
        for dx=0,fp.width-1 do for dy=0,fp.height-1 do assert(api.battleUnitAt(px+dx,py+dy)==native)end end
        local removed,new=r:remove(s,u);assert(removed,new);s=new;healthy(r,s)
        assert(not r.live[u.id]and equal(s.units,unchanged))
        for dx=0,fp.width-1 do for dy=0,fp.height-1 do assert(api.battleUnitAt(px+dx,py+dy)~=native)end end
        local reused,new,u=r:add(s,13,2,px,py);assert(reused,new);s=new;healthy(r,s)
        local removed,new=r:remove(s,u);assert(removed,new);s=new;healthy(r,s);assert(equal(s.units,unchanged))
        result.large={width=fp.width,height=fp.height,all_hit_cells_verified=1,deleted_reused=1}
        while #s.units>0 do local removed,new=r:remove(s,s.units[1]);assert(removed,new);s=new end
        assert(#healthy(r,s).units==0)
        local emptyFile=file..'-empty';assert(api.writeIni(emptyFile,M.encode(s,c.mods)))
        local loaded,reason=M.decode(api.readIni(emptyFile),c,c.mods);assert(loaded,reason)
        assert(r:build(loaded,false));s=loaded;healthy(r,s)
        ui.scenario=s;local kept=M.encode(s,c.mods)
        assert(not ui:fight()and equal(M.encode(s,c.mods),kept)and #api.testFieldState().units==0)
        ui.noticeText=nil
        local ex,ey
        for _,g in ipairs(api.testFieldState().grid)do
            if g.x>0 and g.y>0 and g.unit<0 and g.object<0 then ex,ey=g.x,g.y;break end
        end
        assert(ex,'No empty cell after Clear')
        local added,new,u=r:add(s,13,2,ex,ey);assert(added,new);s=new;healthy(r,s)
        assert(M.count(s,1)==0 and M.count(s,2)==1)
        local removed,new=r:remove(s,u);assert(removed,new);s=new;healthy(r,s)
        result.empty={saved=emptyFile,both_teams_empty=1,battle_refused_unchanged=1,new_teamB_actor_after_clear=1}
        assert(movements>0,'No native combat movement observed')
        result.matrix={objects=objects,movement_events=movements,saved=file,names_spells_items_preserved=1}
        assert(r:close());active=nil
        assert(equal(world(),before),'Borrowed square/neighbor/plane context changed')
        local life=assert(api.testFieldLifecycle());assert(life.complete and #life.issues==0 and not life.open)
        result.cleanup={verified=1,world_readback_unchanged=1,issues=#life.issues}
    end,tostring)
    fighting=false
    if not ok and active then
        local exported,name=pcall(function()
            return active.diag:export({fixture='water/coast context acceptance failure',error=tostring(why)},active:snapshot(active.current or{}))
        end)
        result.failure_diagnostic={name=exported and name or'unavailable'}
    end
    if active then
        local called,closed,detail=pcall(function()return active:close()end)
        if not called or not closed then ok=false;why=tostring(why)..'; cleanup: '..tostring(detail or closed)end
    end
    finish(ok and'PASS'or'FAIL',ok and'Actual native coast context; placement/obstacle/movement, two natural battles, SaveLoad Reset Rematch, Clear and cleanup.'or tostring(why))
    api.set('traceLevel',0)
    return value
end,-100)
