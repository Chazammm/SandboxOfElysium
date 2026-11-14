-- Runs only in an isolated profile. No memory access and no campaign mutations.
local api=coe5
local plain,forest
local catalog={environment={purpose='Terrain API experiment; actual native calls',last=api.get('terrainLastIndex')}}
for i=0,api.get('terrainLastIndex') do
    local name=api.get('terrainName',i)
    if name=='Plain' then plain=i elseif name=='Forest' then forest=i end
    if name and name~='' then catalog['terrain'..i]={id=i,name=name,batmap=api.get('terrain',i,'batmap')} end
end
api.writeIni('terrain-catalog',catalog)
local result={environment={plain=plain or 'missing',forest=forest or 'missing'}}
local shown=false
local fight=false
local movements=0
api.observe('BATTLE_ADVANCE_UNIT',function(unit)
    if fight then result.step={unit=unit,x=api.get('unitBattleX',unit),y=api.get('unitBattleY',unit)} end
end,function(_,unit)
    if fight and result.step and result.step.unit==unit then
        if result.step.x~=api.get('unitBattleX',unit) or result.step.y~=api.get('unitBattleY',unit) then movements=movements+1 end
        result.step=nil
    end
end)
local function state()
    local s={}
    for _,key in ipairs({'activePlayer','worldW','worldH','battleDelay'}) do s[key]=tostring(api.get(key)) end
    for _,key in ipairs({'squareTerrain','squareGround','squareTemperature','squareArmy','squareOwner','squareArmyOwner','squarePlane'}) do s[key]=tostring(api.get(key,1,1)) end
    s.teamA=tostring(api.get('slotTeam',0));s.teamB=tostring(api.get('slotTeam',24))
    for _,key in ipairs({'planeX','planeY','planeWidth','planeHeight'}) do s[key]=tostring(api.get(key,0)) end
    s.lastPlane=tostring(api.get('planeLastIndex'));return s
end
local function equal(a,b)
    for k,v in pairs(a) do if b[k]~=v then return false,k..' '..v..' -> '..tostring(b[k]) end end;return true
end
local function spec(terrain)
    return {commander=api.findMonster('Spearman'),spell=-1,enemies={{api.findMonster('Goblin'),2}},terrain=terrain}
end
local function save() api.writeIni('terrain-results',result) end
local function menu(title,rows)
    api.ui.screenBegin(title);api.ui.screenWidth(650);api.ui.sectionBegin('')
    for _,r in ipairs(rows) do api.ui.text(r[1],r[2]) end
    api.ui.sectionEnd();api.ui.bindEscape(999);return api.ui.wait()
end
local function notice(message)
    while true do local id=menu('Terrain experiment',{{0,message},{1,'OK'},{999,'Back'}});if id==1 or id==999 then return end end
end
local function snapshot(units)
    local s={terrain=api.get('squareTerrain',1,1),ground=api.get('squareGround',1,1),temperature=api.get('squareTemperature',1,1),
        plane=api.get('squarePlane',1,1),width=api.get('battleWidth'),objects=0,blocked=0,free=0}
    for x=0,s.width-1 do for y=0,19 do
        local object=api.battleObjectAt(x,y)
        if object and object>=0 then s.objects=s.objects+1 end
        if api.battleCanStand(units.commander,x,y,0) then s.free=s.free+1 else s.blocked=s.blocked+1 end
    end end
    return s
end
local function compatibility()
    local before=state()
    local ok=api.openTestField(spec(nil));result.omitted={opened=ok and 1 or 0}
    if ok then result.omitted.terrain=api.get('squareTerrain',1,1);api.closeTestField() end
    local restored,why=equal(before,state());result.omitted.restored=restored and 1 or 0;result.omitted.detail=why or 'public state matches'
    ok=api.openTestField(api.findMonster('Spearman'),-1,api.findMonster('Goblin'),2)
    result.positional={opened=ok and 1 or 0};if ok then result.positional.terrain=api.get('squareTerrain',1,1);api.closeTestField() end
    restored,why=equal(before,state());result.positional.restored=restored and 1 or 0;result.positional.detail=why or 'public state matches';save()
end
local function invalids()
    local values={{'negative',-1},{'above_last',api.get('terrainLastIndex')+1},{'huge',1e100},{'fraction',0.5},
        {'string','0'},{'boolean',false},{'true',true},{'table',{}},{'function',function()end},{'thread',coroutine.create(function()end)},
        {'infinity',math.huge},{'nan',0/0},{'maxinteger',math.maxinteger},{'unsupported_named',1}}
    for _,v in ipairs(values) do
        local before=state();local ok=api.openTestField(spec(v[2]));if ok then api.closeTestField() end
        local restored,why=equal(before,state());local reuse=api.openTestField(spec(nil));if reuse then api.closeTestField() end
        result['invalid_'..v[1]]={rejected=not ok and 1 or 0,restored=restored and 1 or 0,reopened=reuse and 1 or 0,detail=why or 'public state matches'}
    end;save()
end
local function cycles()
    for i=1,10 do
        local before=state();local terrain=i%2==0 and plain or forest;local ok,units=api.openTestField(spec(terrain))
        local row=ok and snapshot(units) or {};row.opened=ok and 1 or 0
        if ok then
            row.anchor_a=api.moveTestFieldUnit(units.commander,8,9) and 1 or 0
            row.anchor_b=api.moveTestFieldUnit(units.enemies[1],18,9) and 1 or 0
            api.closeTestField()
        end
        local restored,why=equal(before,state());row.restored=restored and 1 or 0;row.detail=why or 'public state matches';result['cycle'..i]=row
    end;save()
end
local function integration()
    local ok,why=xpcall(function()
        local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local Report=require('sandbox.report')
        local c=C.read(api);local r=R.new(api,c);local s=M.new();s.terrain=forest
        -- Explicitly adopt actual native cells, then require exact saved cells thereafter.
        M.add(s,api.findMonster('Spearman'),'Spearman',1,8,9)
        M.add(s,api.findMonster('Goblin'),'Goblin',2,18,9)
        local good,reason=r:build(s,true);assert(good,reason)
        for _,u in ipairs(s.units) do assert(api.get('unitBattleX',r.live[u.id])==u.x and api.get('unitBattleY',r.live[u.id])==u.y) end
        assert(api.get('squareTerrain',1,1)==forest)
        assert(api.writeIni('forest-scenario',M.encode(s,c.mods)))
        local loaded,loadReason=M.decode(api.readIni('forest-scenario'),c,c.mods);assert(loaded,loadReason);assert(loaded.terrain==forest)
        good,reason=r:build(loaded);assert(good,reason)
        local snapshot=M.copy(loaded);local report=Report.new(api)
        fight=true;report:start(loaded,r);api.fightTestField();fight=false;report:finish(loaded,r);assert(report:export('forest-integration-battle'))
        good,reason=r:build(M.copy(snapshot));assert(good,'Reset: '..tostring(reason));assert(api.get('squareTerrain',1,1)==forest)
        for _,u in ipairs(snapshot.units) do assert(api.get('unitBattleX',r.live[u.id])==u.x and api.get('unitBattleY',r.live[u.id])==u.y) end
        fight=true;report:start(snapshot,r);api.fightTestField();fight=false;report:finish(snapshot,r);assert(report:export('forest-integration-rematch'))
        r:close();result.integration={status='PASS',terrain=forest,native_deployment=1,save_load=1,reset=1,rematch=1}
    end,function(e)return tostring(e) end)
    if not ok then api.closeTestField();fight=false;result.integration={status='FAIL',detail=why} end
    save()
end
local function preview(terrain,label)
    if terrain==nil then notice('Loaded terrain not found: '..label);return end
    local before=state();local ok,units=api.openTestField(spec(terrain))
    if not ok then result[label]={opened=0};save();notice('Field refused: '..label..'. Read refusal log.');return end
    result[label]=snapshot(units)
    -- Move real units to native-approved free cells rather than assuming forest cells are empty.
    local moved=false
    for y=0,19 do for x=3,math.min(10,result[label].width-1) do
        if api.battleCanStand(units.commander,x,y,0) and api.moveTestFieldUnit(units.commander,x,y) then
            result[label].placed_x=x;result[label].placed_y=y;moved=true;break
        end
    end;if moved then break end end
    result[label].placed=moved and 1 or 0
    -- Actual object cells must reject placement when the native unit cannot stand there.
    for x=0,result[label].width-1 do for y=0,19 do
        local object=api.battleObjectAt(x,y)
        if object and object>=0 and not api.battleCanStand(units.commander,x,y,0) then
            result[label].obstacle_rejected=not api.moveTestFieldUnit(units.commander,x,y) and 1 or 0;break
        end
    end;if result[label].obstacle_rejected then break end end
    if result[label].terrain~=terrain then api.closeTestField();result[label].unsupported='API ignored terrain';save();notice('This extender ignored terrain; no terrain support proven.');return end
    shown=true
    while shown do
        api.drawTestField()
        local id=menu('Inspect '..label,{{0,'Terrain '..terrain..'; ground '..result[label].ground..'; objects '..result[label].objects},
            {1,'Show native battlefield'},{2,'Fight now'},{999,'Close'}})
        if id==1 then
            -- Repeated native frames with the game's own drawing. End by clicking the overlay.
            local leave=false
            while not leave do api.drawTestField();leave=shown=='close' end;shown=true
        elseif id==2 then
            fight=true;movements=0;api.fightTestField();fight=false
            result[label].winner=api.get('battleWinner');result[label].round=api.get('battleRound');result[label].movements=movements
            result[label].a_hp=api.get('unitHp',units.commander);result[label].b1_hp=api.get('unitHp',units.enemies[1]);result[label].b2_hp=api.get('unitHp',units.enemies[2]);shown=false
        elseif id==999 then shown=false end
    end
    api.closeTestField();local restored,why=equal(before,state());result[label].restored=restored and 1 or 0;result[label].restore_detail=why or 'public state matches';save()
end
api.wrap('BATTLE_DRAW',function(next)
    local r=next()
    if shown and not fight then api.ui.drawRect(0,0,360,35,0.03,0.03,0.04,0.95);api.ui.drawText(10,10,14,'Return to terrain test menu',1,1,1,1) end
    return r
end)
api.wrap('BATTLE_WAIT',function(next,b,m)
    local id=next(b,m)
    if shown and not fight then
        if (api.get('mouseButtons') or 0)&1~=0 and api.get('uiPointerY')<35 then shown='close';api.set('mouseButtons',0) end
        api.set('mouseButtons',0);return 0
    end;return id
end)
api.addMainMenuButton('Terrain experiment',function()
    while true do
        local id=menu('Terrain experiment',{{0,'Loaded Plain='..tostring(plain)..' Forest='..tostring(forest)},
            {1,'Compatibility checks'},{2,'Invalid argument checks'},{3,'Plain preview / fight'},{4,'Forest preview / fight'},
            {5,'testBattle table Forest'},{6,'Alternate Plain / Forest cleanup'},{999,'Back'}})
        if id==999 then return elseif id==1 then compatibility();notice('Compatibility checks written')
        elseif id==2 then invalids();notice('Invalid-argument checks written')
        elseif id==3 then preview(plain,'Plain') elseif id==4 then preview(forest,'Forest')
        elseif id==5 then
            local before=state();local ok=api.testBattle(spec(forest));local restored,why=equal(before,state())
            result.testBattle_forest={shown=ok and 1 or 0,restored=restored and 1 or 0,detail=why or 'public state matches',winner=api.get('battleWinner'),round=api.get('battleRound')};save()
        elseif id==6 then
            cycles();notice('Alternating cleanup checks written')
        end
    end
end)

-- Optional automated native checks, configured only in this private profile.
-- These are API tests, not claims of manual visual observation.
local auto=api.readIni('terrain-auto')
if auto and auto.run then
    result.environment.build=auto.run.build or 'unspecified'
    if auto.run.fault=='1' then
        local before=state();local opened=api.openTestField(spec(forest));if opened then api.closeTestField() end
        local restored,why=equal(before,state());local reopened=api.openTestField(spec(plain));if reopened then api.closeTestField() end
        local fault={failure={refused=not opened and 1 or 0,restored=restored and 1 or 0,reopened=reopened and 1 or 0,detail=why or 'public state matches',kind='explicit one-time post-init fault injection; not a natural terrain failure'}}
        api.writeIni('terrain-fault-results',fault)
    end
    if auto.run.quick=='1' then compatibility();invalids();cycles() end
    if auto.run.standardFight=='1' then
        local before=state();local opened=api.openTestField(spec(nil))
        if opened then fight=true;api.fightTestField();fight=false;api.closeTestField() end
        local restored,why=equal(before,state());result.standard_fight={opened=opened and 1 or 0,restored=restored and 1 or 0,winner=api.get('battleWinner'),round=api.get('battleRound'),detail=why or 'public state matches'};save()
    end
    if auto.run.tableFight=='1' then
        local before=state();fight=true;local shown=api.testBattle(spec(forest));fight=false
        local restored,why=equal(before,state());result.testBattle_forest={shown=shown and 1 or 0,restored=restored and 1 or 0,winner=api.get('battleWinner'),round=api.get('battleRound'),detail=why or 'public state matches'};save()
    end
    if auto.run.integration=='1' then integration() end
end
