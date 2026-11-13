-- Copied into the private lab only. These calls run against the real CoE5SE API.
local M=require('sandbox.model')
local Runtime=require('sandbox.runtime')
local Probe={}
function Probe.run(ui,only)
    ui:ensureCatalog()
    local api=ui.api;local runtime=ui.runtime;local results={environment={dev='57abc69a2ddb272a5b9049b4a561367066d9d99e'}}
    local file=only and ('native-probe-'..only:gsub('_','-')) or 'native-probe'
    local function test(name,fn)
        if only and name~=only then return end
        local ok,err=pcall(fn);results[name]={status=ok and 'PASS' or 'FAIL',detail=ok and 'real game API' or tostring(err)}
        runtime:close();api.writeIni(file,results)
    end
    local function scenario()
        local s=M.new();M.add(s,api.findMonster('Spearman'),'Spearman',1,8,9);M.add(s,api.findMonster('Goblin'),'Goblin',2,18,9);return s
    end
    test('native_field',function()
        local s=scenario();assert(runtime:build(s));results.environment.width=runtime.width
        assert(api.get('unitOwner',runtime.live[1])==0 and api.get('unitOwner',runtime.live[2])==24)
        assert(api.get('slotTeam',0)~=api.get('slotTeam',24))
        assert(api.get('unitBattleX',runtime.live[1])==8)
        assert(api.get('unitBattleX',runtime.live[2])==18)
    end)
    test('move_and_cancel',function()
        local s=scenario();assert(runtime:build(s));local unit=runtime.live[1]
        local inventory=table.concat(runtime:inventory(unit),'|')
        assert(runtime:move(s.units[1],7,8));assert(api.get('unitBattleX',unit)==7 and api.get('unitBattleY',unit)==8)
        assert(table.concat(runtime:inventory(unit),'|')==inventory)
        -- A cancelled UI move performs no mutation: original live record remains.
        local x=api.get('unitBattleX',unit);assert(x==s.units[1].x)
        assert(not runtime:move(s.units[1],-1,8));assert(api.get('unitBattleX',unit)==7)
        assert(not runtime:move(s.units[1],18,9));assert(api.get('unitBattleX',unit)==7)
    end)
    test('copy_delete_and_items',function()
        local s=scenario();assert(runtime:build(s))
        api.giveItem(runtime.live[1],'A Chest Full of Fire');s.units[1].items=runtime:inventory(runtime.live[1]);assert(#s.units[1].items>0)
        assert(runtime:move(s.units[1],6,8));assert(#runtime:inventory(runtime.live[1])==#s.units[1].items)
        local ok,candidate,u=runtime:add(s,s.units[1].monster,1,7,8,s.units[1]);assert(ok,candidate)
        assert(#candidate.units==3 and u.baseline);assert(runtime.live[u.id]~=runtime.live[1])
        assert(table.concat(runtime:inventory(runtime.live[u.id]),'|')==table.concat(s.units[1].items,'|'))
        M.remove(candidate,u.id);assert(runtime:build(candidate));assert(#candidate.units==2)
    end)
    test('automatic_field_expansion',function()
        local ok=api.openTestField{commander=api.findMonster('Spearman'),spell=-1,friends={{api.findMonster('Spearman'),499}},enemies={{api.findMonster('Goblin'),500}}}
        assert(ok);runtime.open=true
        results.environment.thousand_unit_width=api.get('battleWidth')
        assert(results.environment.thousand_unit_width>=results.environment.width)
    end)
    test('activated_mod_faction_unit',function()
        local monster=api.findMonster('Shorebound Initiate');assert(monster and monster>=0,'CrabCult not activated')
        local s=scenario();s.units[1].monster=monster;s.units[1].name='Shorebound Initiate'
        local ok,why=runtime:build(s);assert(ok,why)
        assert(api.get('unitMonster',runtime.live[1])==monster);assert(ui.catalog.byId[monster])
        results.mod_content={name='CrabCult',unit='Shorebound Initiate',id=monster,scope='Activated faction unit in native field; faction-wide start effects not simulated'}
        local old=ui.scenario;ui.scenario=s;ui:fight();assert(ui.report:export('probe-mod-battle'));ui.scenario=old;ui.phase='menu'
    end)
    test('known_spell_edit',function()
        local s=scenario();s.units[1].monster=api.findMonster('Old Wizard');s.units[1].name='Old Wizard'
        local ok,why=runtime:build(s);assert(ok,why)
        local u=s.units[1];assert(#u.baseline.known>0,'No starting spells initialized')
        local name=u.spells[1] or u.baseline.known[1]
        local removed=runtime:memorize(u,name,false)
        results.magic_observation={known=#u.baseline.known,memorized=#u.spells,spell=name,removed=removed and 1 or 0}
        assert(removed,'Native spell removal failed: '..name)
        local added=runtime:memorize(u,name,true);results.magic_observation.added=added and 1 or 0
        assert(added,'Native memorization failed: '..name)
        results.magic_observation={known=#u.baseline.known,memorized=#u.spells,spell=name}
        assert(api.writeIni('probe-mage-scenario',M.encode(s,ui.catalog.mods)))
        local decoded,reason=M.decode(api.readIni('probe-mage-scenario'),ui.catalog,ui.catalog.mods);assert(decoded,reason)
        local restored,restoreReason=runtime:build(decoded)
        results.magic_observation.restoration=restored and 'PASS: regenerated baseline matched' or 'REFUSED: '..tostring(restoreReason)
    end)
    for _,kind in ipairs({'Single','Horizontal Row','Vertical Row','Square'}) do
        local sizes=kind=='Square' and {2,3,4} or kind=='Single' and {1} or {1,15}
        for _,n in ipairs(sizes) do test(kind..'_'..n,function()
            local s=scenario()
            for _,c in ipairs(M.cells(kind,n,1,1)) do if not M.at(s,c[1],c[2]) then M.add(s,s.units[1].monster,'Spearman',1,c[1],c[2]) end end
            local ok,why=runtime:build(s);assert(ok,why)
            for _,u in ipairs(s.units) do assert(api.get('unitBattleX',runtime.live[u.id])==u.x and api.get('unitBattleY',runtime.live[u.id])==u.y) end
        end) end
    end
    test('native_item_assignment_probe',function()
        local s=scenario();assert(runtime:build(s));local unit=runtime.live[1]
        local item=ui.catalog.items[1];assert(item)
        local before=runtime:inventory(unit);api.giveItem(unit,item.name)
        local after=runtime:inventory(unit)
        results.item_observation={name=item.name,slot_type=item.slot,before=#before,after=#after,
            compatibility='No public anatomical-slot preflight; this call alone does not prove slot validity'}
    end)
    test('save_load',function()
        local s=scenario();assert(runtime:build(s));assert(api.writeIni('probe-scenario',M.encode(s,ui.catalog.mods)))
        local decoded,why=M.decode(api.readIni('probe-scenario'),ui.catalog,ui.catalog.mods);assert(decoded,why)
        assert(runtime:build(decoded));assert(api.get('unitBattleX',runtime.live[1])==8)
    end)
    test('same_colors_opposing_teams',function()
        local s=scenario();s.colors={3,3};assert(runtime:build(s));assert(api.get('slotTeam',0)~=api.get('slotTeam',24))
        assert(math.abs(api.get('slotColorGreen',0)-api.get('slotColorGreen',24))<0.001)
    end)
    test('small_battle_report_reset_rematch',function()
        local old=ui.scenario;ui.scenario=scenario();assert(runtime:build(ui.scenario))
        ui:fight();local r=ui.report.result
        assert(r.teamA.start==1 and r.teamB.start==1);assert(r.teamA.survivors+r.teamA.losses==1)
        assert(r.summary.winner==0 or r.summary.winner==24)
        assert(ui.report:export('probe-small-battle'))
        local snap=M.copy(ui.snapshot);assert(runtime:build(snap));ui.scenario=snap
        ui:fight();assert(ui.report:export('probe-rematch'));ui.scenario=old;ui.phase='menu'
    end)
    test('large_battle',function()
        local old=ui.scenario;local s=M.new()
        for y=0,19 do for x=3,7 do M.add(s,api.findMonster('Spearman'),'Spearman',1,x,y) end end
        for y=0,19 do for x=22,26 do M.add(s,api.findMonster('Goblin'),'Goblin',2,x,y) end end
        local ok,why=runtime:build(s);assert(ok,why);results.environment.large_width=runtime.width
        ui.scenario=s;ui:fight();assert(ui.report:export('probe-large-battle'));assert(ui.report.result.teamA.start==100);ui.scenario=old;ui.phase='menu'
    end)
    runtime:close();ui.phase='menu';ui:notice('Native probe complete. See '..file..'.ini; failures are retained.')
end
return Probe
