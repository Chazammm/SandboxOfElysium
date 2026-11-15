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
test('schema2 retains duplicate item names by ID and sparse positions including 20',function()
    local s=scene();local encoded=M.encode(s,{});assert(encoded.scenario.schema==2)
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
    local s=M.new();assert(M.encode(s,{}).scenario.schema==1);assert(M.decode(M.encode(s,{}),c,{}))
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
print(count..' offline loadout identity/persistence/recovery contracts passed; no native slot rules or combat simulated')
