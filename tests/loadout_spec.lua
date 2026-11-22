-- Offline persistence/identity contracts only. Native compatibility and combat
-- are exercised in loadout_probe.lua inside the actual isolated game.
local cache={}
function require(name)
    if not cache[name] then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))() end
    return cache[name]
end
local M=require('sandbox.model');local L=require('sandbox.loadout');local count=0
local c={byId={[13]={id=13,name='Spearman'}},terrainById={[0]={name='Plain'}},itemNames={Twin=false},
    byItemId={[5]={id=5,name='Twin',slot=7},[9]={id=9,name='Twin',slot=7}},spellKeys={['1:Same']=1,['2:Same']=2}}
local function scene()
    local s=M.new();local u=M.add(s,13,'Spearman',1,4,5)
    u.baseline={known={'1:Same','2:Same'}};u.spells={'2:Same'};u.items={'Twin','Twin'}
    u.equipment={{position=6,id=5,name='Twin'},{position=19,id=9,name='Twin'}}
    u.schools={{path=4,name='School',base=2}};return s,u
end
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
test('schema4 retains duplicate item names by ID and sparse positions including 20',function()
    local s=scene();local encoded=M.encode(s,{});assert(encoded.scenario.schema==4)
    local copy,why=M.decode(encoded,c,{});assert(copy,why)
    assert(copy.units[1].equipment[1].id==5 and copy.units[1].equipment[2].id==9 and copy.units[1].equipment[2].position==19)
    assert(copy.units[1].schools[1].base==2 and copy.units[1].spells[1]=='2:Same')
end)
test('changed item identity rejected before native mutation',function()
    local encoded=M.encode(scene(),{});encoded.unit1.equipment1_name='Different';assert(not M.decode(encoded,c,{}))
end)
test('duplicate equipment positions rejected',function()
    local encoded=M.encode(scene(),{});encoded.unit1.equipment2_position=6;assert(not M.decode(encoded,c,{}))
end)
test('out of range positions rejected',function()
    local encoded=M.encode(scene(),{});encoded.unit1.equipment2_position=20;assert(not M.decode(encoded,c,{}))
end)
test('duplicate school identities rejected',function()
    local encoded=M.encode(scene(),{});encoded.unit1.school_count=2
    for _,key in ipairs({'path','name','base'})do encoded.unit1['school2_'..key]=encoded.unit1['school1_'..key]end
    assert(not M.decode(encoded,c,{}))
end)
test('known and memorized duplicate spell names remain distinct',function()
    local s=scene();local copy=assert(M.decode(M.encode(s,{}),c,{}))
    assert(copy.units[1].baseline.known[1]=='1:Same' and copy.units[1].baseline.known[2]=='2:Same' and copy.units[1].spells[1]=='2:Same')
end)
test('legacy empty and one-sided scenarios remain supported',function()
    local s=M.new();local legacy=M.encode(s,{});legacy.scenario.schema=1;assert(M.decode(legacy,c,{}).legacyState)
    M.add(s,13,'Spearman',2,7,8);assert(M.decode(M.encode(s,{}),c,{}))
end)
test('copying configuration does not alias equipment or schools',function()
    local s,u=scene();local v=M.add(s,13,'Spearman',2,10,5,u)
    v.equipment[1].id=9;v.schools[1].base=3
    assert(u.equipment[1].id==5 and u.schools[1].base==2)
end)
test('missing API and changed school identity are explicit',function()
    local r={api={}};assert(not L.read(r,1))
    local s,u=scene();r.catalog=c
    local native={items={},schools={{path=4,name='Changed school',base=1}}}
    for p=0,19 do native.items[#native.items+1]={position=p,id=-1,slotType=7}end
    local wanted,why=L.wanted(r,u,native);assert(not wanted and why:find('changed native school',1,true))
end)
test('partial school metadata never silently downgrades to a legacy configuration',function()
    local encoded=M.encode(scene(),{});encoded.unit1.equipment_count=nil
    local loaded,why=M.decode(encoded,c,{});assert(not loaded and why:find('Incomplete',1,true))
end)

test('legacy duplicate names remain ambiguous even when an occupied native slot matches',function()
    local _,u=scene();u.equipment=nil;u.schools=nil
    local wanted,why=L.wanted({catalog=c},u,{items={{position=6,id=5,name='Twin',slotType=7}},schools={}})
    assert(not wanted and why:find('ambiguous',1,true))
end)

local function nativeState()
    local v={unit=41,complete=true,valid=true,items={},schools={{path=4,name='School',base=2}},known={1,2},memorized={2}}
    for p=0,19 do v.items[p+1]={position=p,id=-1,slotType=7}end
    v.items[7].id=5;v.items[7].name='Twin';v.items[20].id=9;v.items[20].name='Twin'
    return v
end
test('implant mismatch during reconstruction names the unit and keeps the exact saved configuration',function()
    local s,u=scene();local saved=M.encode(s,{})
    local fresh=nativeState();fresh.items[7].id=-1;fresh.items[7].name=nil
    local calls=0
    local r={catalog=c,api={
        testFieldLoadoutState=function()return fresh end,
        setTestFieldConfiguration=function(unit,wanted)
            calls=calls+1
            assert(unit==41 and wanted.restoreKnown==true and wanted.items[7]==5)
            return false,'permanent_anatomy_item_unsupported',{rollbackVerified=true}
        end,
    }}
    function r:observeSpellSelection()end
    local ok,why,detail=L.configure(r,u,41,true)
    assert(not ok and calls==1 and detail.rollbackVerified)
    assert(why:find('Spearman',1,true) and why:find('different permanent implants',1,true))
    assert(r.lastConfig.configuration_result=='permanent_anatomy_item_unsupported')
    local after=M.encode(s,{})
    for section,row in pairs(saved)do for key,value in pairs(row)do assert(after[section][key]==value)end end
end)

local function implantFixture(savedItem,freshItem,mode)
    local Runtime=require('sandbox.runtime')
    local _,u=scene()
    local state=nativeState()
    state.generation=3
    local items={
        [5]={id=5,name='Twin',slot=7},
        [9]={id=9,name='Twin',slot=7},
        [182]={id=182,name='Spirit Eye',slot=7,injury=0x100000},
        [185]={id=185,name='Crystal Heart',slot=7,injury=0x400000},
    }
    local function put(index,id)
        local item=items[id]
        state.items[index]={id=id,name=item and item.name,position=index-1,slotType=7,permanentEffects=item and item.injury~=nil}
    end
    put(7,freshItem)
    local function condition(injury)
        return {hp=5,maxHp=6,xp=9,kills=1,injuryFlags=injury,monster=13,width=1,height=1,version=1}
    end
    local current=condition(freshItem~=-1 and items[freshItem].injury or 0)
    local savedInjury=(savedItem~=-1 and items[savedItem].injury or 0)|0x800000
    local savedCondition=condition(savedInjury)
    u.condition=savedCondition
    u.equipment={{position=19,id=9,name='Twin'}}
    if savedItem~=-1 then table.insert(u.equipment,1,{position=6,id=savedItem,name=items[savedItem].name}) end
    local writes=0
    local api={
        testFieldLoadoutState=function()return M.copy(state) end,
        loadedContentOrigin=function(_,id)return {id=id,kind=mode=='modified' and 'modified_by_mod' or 'baseline',observed=true}end,
        testFieldActorState=function()
            local row=M.copy(current);row.unit=41;row.generation=3;row.complete=true;row.fullState=false
            return row
        end,
        set=function(name,unit,slot,id)
            assert(name=='unitItem' and unit==41 and (slot==6 or mode=='retained'))
            if mode=='retained' then assert(id==182,'retained heart must not be unequipped or reapplied') end
            writes=writes+1
            if mode=='failed' then return end
            put(slot+1,id)
            if items[id] and items[id].injury then current.injuryFlags=current.injuryFlags|items[id].injury end
            if mode=='changed_other_slot' then put(20,-1) end
        end,
        setTestFieldConfiguration=function(unit,wanted)
            assert(unit==41 and wanted.restoreKnown)
            local balance={}
            for i,id in ipairs(wanted.items) do
                if (items[id] or {}).injury then balance[id]=(balance[id] or 0)+1 end
                local old=state.items[i].id
                if (items[old] or {}).injury then balance[old]=(balance[old] or 0)-1 end
            end
            for _,count in pairs(balance)do if count~=0 then return false,'permanent_anatomy_item_unsupported',{rollbackVerified=true} end end
            for i,id in ipairs(wanted.items)do put(i,id)end
            return true
        end,
        setTestFieldActorState=function(unit,saved)
            assert(unit==41 and saved.hp==5 and saved.xp==9 and saved.injuryFlags==savedCondition.injuryFlags)
            current=M.copy(saved)
            return true
        end,
    }
    local catalog=M.copy(c);catalog.byItemId=items
    local r=Runtime.new(api,catalog)
    function r:observeSpellSelection()end
    function r:spellList(_,name)return name=='unitKnownSpell' and {'1:Same','2:Same'} or {'2:Same'}end
    return r,u,function()return state,current,writes end
end

test('a recreated actor receives a missing eye, replacing heart or no implant with exact injury and equipment state',function()
    for _,pair in ipairs({{182,-1},{182,185},{185,182},{-1,185}})do
        local r,u,read=implantFixture(pair[1],pair[2])
        local intended=M.copy(u.condition)
        assert(r:configure(u,41,true))
        local state,condition,writes=read()
        local expectedWrites=pair[1]~=-1 and pair[2]~=-1 and 2 or 1
        assert(writes==expectedWrites and state.generation==3 and state.items[7].id==pair[1] and state.items[20].id==9)
        assert(condition.injuryFlags==intended.injuryFlags and condition.hp==intended.hp and condition.xp==intended.xp)
        assert(u.condition.injuryFlags==intended.injuryFlags and u.spells[1]=='2:Same')
    end
end)
test('a retained implant in the wrong slot is moved by the verified configuration without running its effect again',function()
    local r,u,read=implantFixture(182,185,'retained')
    u.equipment[#u.equipment+1]={position=7,id=185,name='Crystal Heart'}
    u.condition.injuryFlags=u.condition.injuryFlags|0x400000
    assert(r:configure(u,41,true))
    local state,_,writes=read()
    assert(writes==1 and state.items[7].id==182 and state.items[8].id==185)
end)
test('matching implants are retained and a live edit or changed item definition cannot trigger replay',function()
    local r,u,read=implantFixture(182,182)
    assert(r:configure(u,41,true));local _,_,writes=read();assert(writes==0)
    for _,mode in ipairs({'live','modified'})do
        r,u,read=implantFixture(182,185,mode)
        local accepted=r:configure(u,41,mode~='live')
        local state,_,count=read()
        assert(not accepted and count==0 and state.items[7].id==185)
    end
end)
test('failed implant write and unexpected slot changes refuse before completing the candidate',function()
    for _,mode in ipairs({'failed','changed_other_slot'})do
        local r,u,read=implantFixture(182,185,mode)
        local before=u.condition.injuryFlags
        local ok,why=r:configure(u,41,true)
        local _,condition,writes=read()
        assert(not ok and writes==1 and why:find('unexpected slot',1,true) and u.condition.injuryFlags==before)
        assert(condition.injuryFlags~=before and r.lastConfig.configuration_result=='implant_replay_unverified')
    end
end)
test('explicitly unsupported capability and incomplete readback are refused',function()
    local value=nativeState();local api={testFieldLoadoutState=function()return value end,setTestFieldConfiguration=function()end}
    local r={api=api};assert(L.read(r,41))
    api.testFieldEditorCapabilities=function()return {configuration=0}end;assert(not L.available(api))
    api.testFieldEditorCapabilities=nil;value.items[20]=nil;assert(not L.read(r,41))
    value=nativeState();value.items[20].position=18;assert(not L.read(r,41))
    value=nativeState();value.unit=42;assert(not L.read(r,41))
end)

-- Fault injection covers the Sandbox recovery contract, not native compatibility.
local function rejection(mode)
    local s,u=scene();local original=M.encode(s,{});local value=nativeState()
    local r={current=s,live={[u.id]=41},catalog=c,api={}}
    r.api.testFieldLoadoutState=function()return M.copy(value)end
    r.api.setTestFieldConfiguration=function()
        if mode=='changed' then value.items[7].id=-1;value.items[7].name=nil end
        if mode=='false_success' then return true,nil,{rollbackVerified=true}end
        return false,'incompatible_slot',{rollbackVerified=mode~='unverified'}
    end
    function r:ready()return true end
    function r:snapshot()return {preserved=original}end
    function r:observeSpellSelection()end
    function r:failure(_,_,_,_,result)self.failureResult=result end
    function r:quarantine(_,why,before)self.blocked=true;self.preserved=before.preserved;return false,why end
    local ok=L.raise(r,u,4);assert(not ok)
    assert(M.encode(s,{}).unit1.school1_base==original.unit1.school1_base and u.equipment[1].id==5)
    return r,original
end
test('verified native rejection keeps model and permits further editing',function()
    local r=rejection('verified');assert(not r.blocked and r.failureResult=='verified unchanged')
end)
test('unverified rollback locks editing and retains the original scenario',function()
    local r,old=rejection('unverified');assert(r.blocked and r.preserved==old)
end)
test('rollback claiming success with changed native data locks editing',function()
    local r=rejection('changed');assert(r.blocked and r.failureResult=='unverified')
end)
test('successful mutation without matching native readback locks editing',function()
    local r=rejection('false_success');assert(r.blocked)
end)
test('configuration success and rejection both quarantine an unrelated structure change',function()
    local read,configure,matches=L.read,L.configure,L.matches
    for _,accepted in ipairs({false,true})do
        local u={id=1,baseline={known={}},spells={},items={},equipment={},schools={}};local original=M.copy(u)
        local r={current={units={u}},live={[1]=41},api={},catalog=c}
        function r:ready()return true,{signatures={[41]='target',[42]='other'},structures={[71]='proven structure'}}end
        function r:snapshot()return{preserved=original}end
        function r:check(_,positions,previous)assert(positions and previous.structures[71]=='proven structure' and previous.signatures[41]==nil and previous.signatures[42]=='other');self.checked=true;return false,'native_structure_changed'end
        function r:failure()end
        function r:quarantine(_,why)self.blocked=true;return false,why end
        L.read=function()return{}end;L.configure=function()return accepted,'incompatible_slot',{rollbackVerified=true}end;L.matches=function()return true end
        local ok=L.change(r,u,function()return true end,'test_config');assert(not ok and r.checked and r.blocked)
    end
    L.read,L.configure,L.matches=read,configure,matches
end)
print(count..' offline loadout identity/persistence/recovery contracts passed; no native slot rules or combat simulated')
