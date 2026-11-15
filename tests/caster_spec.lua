-- Offline contracts for the real modules. Readbacks and build outcomes below
-- are declared fixtures; this does not simulate CoE allocation or spell rules.
local cache={}
function require(name)
    if not cache[name] then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))() end
    return cache[name]
end
local M=require('sandbox.model');local R=require('sandbox.runtime');local D=require('sandbox.diagnostics')
local I=require('sandbox.integrity');local count=0
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function fixture()
    local s=M.new();local god=M.add(s,141,'God Emperor',1,4,4)
    M.add(s,13,'Spearman',2,22,12)
    local infos,keys={},{}
    for _,id in ipairs({101,102,103,104,105,106,261,262,263,264,266,268}) do
        infos[id]={name=id==266 and 'Sunlight' or id==268 and 'Aura of the Sun' or 'Spell '..id,path=id<200 and 5 or 19,level=1}
        keys[id..':'..infos[id].name]=id
    end
    god.baseline={known={}};for _,id in ipairs({101,102,103,104,105,106,261,262,263,264,266,268}) do god.baseline.known[#god.baseline.known+1]=id..':'..infos[id].name end
    god.spells={};for _,id in ipairs({101,102,103,104,261,262,263,264}) do god.spells[#god.spells+1]=id..':'..infos[id].name end
    god.items={'Saved sigil'}
    local catalog={byId={[141]={id=141,name='God Emperor'},[13]={id=13,name='Spearman'}},mods={},spellKeys=keys,itemNames={['Saved sigil']=17},terrainById={[0]={name='Plain'}}}
    local observed,records,files,writes={},{},{},{}
    local calls={safe=0,unsafe=0,inspect=0,build=0}
    local api={spellInfo=function(id)return infos[id]end,memorizeAllowance=function()return 4 end}
    api.readIni=function(name)if name=='launcher-context' then return {environment={session='castertest',data_folder='isolated'}} end;return M.copy(files[name])end
    api.listIni=function()local out={};for name in pairs(files)do out[#out+1]=name end;return out end
    api.writeIni=function(name,data)writes[#writes+1]=name;files[name]=M.copy(data);return true end
    api.get=function(key,id,slot)
        if key=='ticksMs' then return 123 end
        if key=='battleWidth' then return 32 end
        if key=='monsterAbility' then return 0 end
        if key=='itemName' then return id==17 and 'Saved sigil' or nil end
        local rec=records[id];if not rec then return -1 end
        if key=='unitMonster' then return rec.monster elseif key=='unitOwner' then return rec.owner elseif key=='unitHp' then return 212
        elseif key=='unitItem' then return rec.monster==141 and slot==0 and 17 or -1
        elseif key=='unitKnownSpell' then return rec.known[slot+1] or -1
        elseif key=='unitMemorizedSpell' then return rec.mem[slot+1] or -1 end
        return -1
    end
    api.testFieldState=function()return M.copy(observed)end
    api.testFieldSpellState=function(id)
        local rec=records[id];local known,mem={},{}
        for _,spell in ipairs(rec.known)do local p=infos[spell].path;known[p]=(known[p] or 0)+1 end
        for _,spell in ipairs(rec.mem)do local p=infos[spell].path;mem[p]=(mem[p] or 0)+1 end
        return {unit=id,generation=1,complete=true,valid=true,known=M.copy(rec.known),memorized=M.copy(rec.mem),issues={},schools={
            {path=5,name='Air',level=3,bonus=0,allowance=4,knownCount=known[5] or 0,memorizedCount=mem[5] or 0},
            {path=19,name='Solar',level=3,bonus=0,allowance=4,knownCount=known[19] or 0,memorizedCount=mem[19] or 0}}}
    end
    api.memorizeSpell=function()calls.unsafe=calls.unsafe+1;error('unchecked primitive called')end
    api.unmemorizeSpell=api.memorizeSpell
    api.setTestFieldSpells=function()return false,'memorize_limit',{stage='validate',path=19,actual=6,allowed=4,allowance=4}end
    local d=D.new(api);local r=R.new(api,catalog,d)
    local function loadReadback(scene)
        observed={complete=true,width=32,height=20,issues={},units={},grid={}};records={};r.live={}
        for index,u in ipairs(scene.units)do
            local id=index+10;r.live[u.id]=id;local w=u.monster==141 and 3 or 1;local cells={}
            for x=u.x,u.x+w-1 do for y=u.y,u.y+w-1 do cells[#cells+1]={x=x,y=y}end end
            observed.units[#observed.units+1]={unit=id,monster=u.monster,owner=u.team==1 and 0 or 24,hp=212,alive=true,worldX=1,worldY=1,
                width=w,height=w,anchorCount=1,anchors={{x=u.x,y=u.y}},occupied=cells}
            local rec={monster=u.monster,owner=u.team==1 and 0 or 24,known={},mem={}};records[id]=rec
            for _,key in ipairs(u.baseline and u.baseline.known or {})do rec.known[#rec.known+1]=assert(keys[key])end
            for _,key in ipairs(u.spells)do rec.mem[#rec.mem+1]=assert(keys[key])end
        end
        r.open=true;r.width=32;r.current=scene
    end
    loadReadback(s);r.lastKnownGood=M.copy(s)
    return {r=r,s=s,god=god,d=d,api=api,catalog=catalog,calls=calls,files=files,writes=writes,load=loadReadback,
        extra='268:'..infos[268].name,extra2='266:'..infos[266].name}
end
local function invalidOriginal(f)
    local original=M.copy(f.s);original.units[1].spells[#original.units[1].spells+1]=f.extra
    original.units[1].spells[#original.units[1].spells+1]=f.extra2
    return original
end
local function diagnose(f,scene)
    f.r:observeSpellSelection(scene.units[1],11,'memorize_limit',{stage='validate',path=19,actual=6,allowed=4,allowance=4})
end
local function storedOriginal(f,original)
    local name='recovery-original';f.files[name]=M.encode(original,{})
    f.r.recovery=M.copy(original);f.r.recoveryFile=name;f.r.spellRepairSource=name
    f.r.originalSpellRecovery=M.copy(original);f.r.spellRepairScenario=M.copy(original);diagnose(f,original)
    return name,M.copy(f.files[name])
end

test('guarded memorize refusal changes neither selection nor instance and never calls unchecked primitives',function()
    local f=fixture();local before=M.encode(f.s,{});local native=f.api.testFieldState();local known=f.r:spellList(11,'unitKnownSpell',59)
    f.api.memorizeTestFieldSpell=function(id,spell,on)
        f.calls.safe=f.calls.safe+1;assert(id==11 and spell==268 and on==true)
        return false,'memorize_limit',{path=19,actual=5,allowance=4,stage='validate'}
    end
    local ok,why=f.r:memorize(f.god,f.extra,true)
    assert(not ok and why:find('memorize_limit',1,true) and f.calls.safe==1 and f.calls.unsafe==0)
    assert(equal(before,M.encode(f.s,{})) and equal(native,f.api.testFieldState()) and equal(known,f.r:spellList(11,'unitKnownSpell',59)))
    assert(not f.r.blocked and f.d.events[#f.d.events].action=='memorize_refused')
end)
test('legacy quota preflight refuses a fifth Solar selection before the unsafe primitive',function()
    local f=fixture();local before=M.copy(f.s)
    local ok=f.r:memorize(f.god,f.extra,true)
    assert(not ok and f.calls.unsafe==0 and equal(before,f.s) and not f.r.blocked)
end)
test('bulk restore refusal keeps the requested ten exact spells and records native per-school evidence',function()
    local f=fixture();local invalid=invalidOriginal(f);local before=M.copy(invalid);local native=f.r:spellList(11,'unitMemorizedSpell',29)
    local ok,why=f.r:configure(invalid.units[1],11)
    assert(not ok and why:find('memorize_limit',1,true) and equal(before,invalid) and equal(native,f.r:spellList(11,'unitMemorizedSpell',29)))
    local p=f.r.spellRepairProblems[invalid.units[1].id];local solar
    for _,school in ipairs(p.schools)do if school.path==19 then solar=school end end
    assert(solar.selected_count==6 and solar.actual_memorized==4 and solar.allowance==4 and #p.saved_memorized==10)
end)
test('native Inspect unverified detail locks editing even when the independent partial view stays healthy',function()
    for _,success in ipairs({false,true})do
        local f=fixture();local saved=M.copy(f.s)
        f.api.inspectTestFieldUnit=function(id,options)
            assert(id==11 and options.readOnly==true)
            if success then return true,{readOnly=true,verified=false} end
            return false,'native_readback_failed',{readOnly=true,verified=false}
        end
        assert(I.inspect(f.r,f.s,true))
        assert(not f.r:inspect(f.s,f.god) and f.r.blocked and equal(saved,f.r.recovery))
        assert(I.inspect(f.r,f.s,true),'fixture unexpectedly exposes the unverified native change')
    end
end)
test('verified read-only Inspect targets the selected instance and preserves the saved scenario exactly',function()
    local f=fixture();local before=M.encode(f.s,{});local native=f.api.testFieldState()
    f.api.inspectTestFieldUnit=function(id,options)f.calls.inspect=f.calls.inspect+1;assert(id==11 and options.readOnly);return true,{readOnly=true,verified=true,changed=false}end
    local ok,scene,detail=f.r:inspect(f.s,f.god)
    assert(ok and scene==f.s and detail.mode=='read_only' and f.calls.inspect==1 and not f.r.blocked)
    assert(equal(before,M.encode(scene,{})) and equal(native,f.api.testFieldState()) and next(f.files)==nil)
end)
test('explicit repaired copy keeps every selected ID and saves a new unique INI without overwriting its original',function()
    local f=fixture();local original=invalidOriginal(f);local originalFile,originalData=storedOriginal(f,original)
    f.files['repaired-castertest-1']={already='occupied'}
    local chosen=M.copy(original);table.remove(chosen.units[1].spells,9);table.remove(chosen.units[1].spells,9)
    local chosenData=M.encode(chosen,{})
    f.r._build=function(_,candidate)f.calls.build=f.calls.build+1;assert(equal(candidate,chosen));f.load(candidate);return true end
    local ok,verified,detail=f.r:repairSpellSelection(chosen)
    assert(ok and equal(verified,chosen) and f.calls.build==1 and detail.name=='repaired-castertest-2')
    assert(equal(originalData,f.files[originalFile]) and f.files['repaired-castertest-1'].already=='occupied')
    assert(equal(original,f.r.originalSpellRecovery) and #original.units[1].spells==10 and #chosen.units[1].spells==8)
    assert(f.files[detail.name].repair.original_recovery==originalFile and f.files[detail.name].repair.exact_restoration_of_original==0)
    local decoded=assert(M.decode(f.files[detail.name],f.catalog,{}));assert(equal(M.encode(decoded,{}),chosenData))
end)
test('rejected repair retains the original artifact and exact unaccepted selection',function()
    local f=fixture();local original=invalidOriginal(f);local name,before=storedOriginal(f,original);local chosen=M.copy(original)
    f.r._build=function(_,candidate)
        f.calls.build=f.calls.build+1
        if f.calls.build==1 then assert(equal(candidate,chosen));diagnose(f,candidate);return false,'memorize_limit' end
        f.load(candidate);return true
    end
    local ok,why=f.r:repairSpellSelection(chosen)
    assert(not ok and why:find('Original recovery kept',1,true) and equal(before,f.files[name]))
    assert(equal(original,f.r.originalSpellRecovery) and equal(original,chosen) and #chosen.units[1].spells==10)
    for _,written in ipairs(f.writes)do assert(not written:find('repaired-',1,true),'rejected repair was exported as accepted')end
end)
test('bad pending candidate remains repairable after the healthy previous field is restored',function()
    local f=fixture();local healthy=M.copy(f.s);local pending=invalidOriginal(f);f.r.sourceScenarioFile='saved-bad-candidate'
    f.r._build=function(_,candidate)
        f.calls.build=f.calls.build+1
        if f.calls.build==1 then assert(equal(candidate,pending));diagnose(f,candidate);return false,'memorize_limit' end
        assert(equal(candidate,healthy));f.load(candidate);return true
    end
    assert(not f.r:build(pending) and f.calls.build==2 and not f.r.blocked)
    assert(equal(f.r.current,healthy) and I.inspect(f.r,f.r.current,true))
    assert(equal(f.r.spellRepairScenario,pending) and f.r.spellRepairSource=='saved-bad-candidate')
    local problems=f.r:spellRepairCandidates(f.r.spellRepairScenario)
    assert(#problems==1 and #problems[1].spells==10 and equal(f.r.originalSpellRecovery,pending))
end)
test('failed legacy upgrade preserves exact original recovery provenance',function()
    local f=fixture();local pending=invalidOriginal(f);local requested=M.copy(pending);local healthy=M.copy(f.s)
    f.r._build=function(_,candidate)
        f.calls.build=f.calls.build+1
        if f.calls.build==1 then
            candidate.units[1].equipment={{position=0,id=17,name='Saved sigil'}}
            candidate.units[1].schools={{path=19,name='Solar',base=3}}
            diagnose(f,candidate);return false,'memorize_limit'
        end
        f.load(candidate);return true
    end
    assert(not f.r:build(pending) and not f.r.blocked and equal(f.r.current,healthy))
    assert(equal(f.r.originalSpellRecovery,requested) and equal(f.r.spellRepairScenario,requested))
    assert(f.r.originalSpellRecovery.units[1].equipment==nil and #f.r.originalSpellRecovery.units[1].spells==10)
end)
print(count..' offline caster contracts passed; native behavior requires the separate real-game probe')
