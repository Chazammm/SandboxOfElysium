-- Offline observation/call-count contracts. These do not measure game time or
-- simulate native placement, configuration transactions or combat.
local cache={}
function require(name)
    if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end
    return cache[name]
end
local M=require('sandbox.model');local I=require('sandbox.integrity');local L=require('sandbox.loadout')
local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function same(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function fixture(n)
    local s=M.new();local native={};local calls={loadout=0,field=0,inventory=0,spellList=0,itemGet=0}
    local catalog={byItemId={[5]={id=5,name='Twin'},[9]={id=9,name='Twin'}},itemNames={Twin=false},spellKeys={['1:Same']=1,['2:Same']=2}}
    for i=1,n or 1 do
        local id=40+i;local u=M.add(s,13,'Spearman',i==1 and 1 or 2,4*i,5)
        u.baseline={known={'1:Same','2:Same'}};u.spells={'2:Same'};u.items={'Twin','Twin'}
        u.equipment={{position=6,id=5,name='Twin'},{position=19,id=9,name='Twin'}};u.schools={{path=4,name='School',base=2}}
        local loadout={unit=id,generation=100+i,complete=true,valid=true,items={},schools={{path=4,name='School',base=2}},known={1,2},memorized={2}}
        for p=0,19 do loadout.items[p+1]={position=p,id=-1,slotType=7}end
        loadout.items[7].id=5;loadout.items[7].name='Twin';loadout.items[20].id=9;loadout.items[20].name='Twin'
        native[id]={monster=13,owner=i==1 and 0 or 24,hp=20,loadout=loadout,
            row={unit=id,generation=100+i,kind='actor',monster=13,owner=i==1 and 0 or 24,hp=20,alive=true,
                width=1,height=1,anchorCount=1,anchors={{x=u.x,y=u.y}},occupied={{x=u.x,y=u.y}}}}
    end
    local api={setTestFieldConfiguration=function()error('Read-only check must not configure')end,
        testFieldEditorCapabilities=function()return{configuration=1}end,
        testFieldState=function()
            calls.field=calls.field+1;local rows={};for i=1,#s.units do rows[#rows+1]=M.copy(native[40+i].row)end
            return{complete=true,session=7,width=32,height=20,issues={},units=rows,grid={}}
        end,
        testFieldLoadoutState=function(id)
            calls.loadout=calls.loadout+1
            if calls.onRead then calls.onRead(id)end
            return M.copy(native[id].loadout)
        end,
        spellInfo=function(id)return(id==1 or id==2)and{id=id,name='Same'}or nil end,
        get=function(key,id,slot)
            local v=native[id]
            if key=='unitMonster'then return v.monster elseif key=='unitOwner'then return v.owner elseif key=='unitHp'then return v.hp
            elseif key=='unitItem'then calls.itemGet=calls.itemGet+1;return v.loadout.items[slot+1]and v.loadout.items[slot+1].id or -1
            elseif key=='unitKnownSpell'then return v.loadout.known[slot+1]or -1
            elseif key=='unitMemorizedSpell'then return v.loadout.memorized[slot+1]or -1
            elseif key=='itemName'then return catalog.byItemId[id]and catalog.byItemId[id].name end
        end}
    local r={api=api,catalog=catalog,live={}}
    for i,u in ipairs(s.units)do r.live[u.id]=40+i end
    function r:inventory(id)
        calls.inventory=calls.inventory+1;local out={}
        for p=0,L.available(api)and 19 or 7 do local item=api.get('unitItem',id,p);if item and item>=0 then out[#out+1]=api.get('itemName',item)end end
        return out
    end
    function r:spellList(id,key,max)
        calls.spellList=calls.spellList+1;local out={}
        for p=0,max do local spell=api.get(key,id,p);if not spell or spell<0 then break end
            local info=api.spellInfo(spell);if info then out[#out+1]=spell..':'..info.name end
        end;return out
    end
    return r,s,native,calls
end
local function rejected(change,expected)
    local r,s,native,calls=fixture();change(native[41].loadout,s.units[1],r,native[41])
    local ok,why=I.inspect(r,s,true);assert(not ok and(not expected or why==expected),tostring(why))
    return calls
end
test('each actor uses exactly one fresh loadout read per complete verification',function()
    local r,s,_,calls=fixture(2);assert(I.inspect(r,s,true));assert(calls.loadout==2 and calls.field==1)
    assert(calls.inventory==0 and calls.spellList==0 and calls.itemGet==0)
end)
test('public two-argument signature keeps its original exact serialized format',function()
    local r,_,native,calls=fixture();local signature=I.signature(r,41)
    local ids={};for _,row in ipairs(native[41].loadout.items)do ids[#ids+1]=tostring(row.id)end;ids[#ids+1]='school:4:2'
    assert(signature=='13;0;20;1:Same|2:Same;2:Same;'..table.concat(ids,','))
    assert(calls.loadout==1 and calls.itemGet==20 and calls.spellList==2)
end)
test('fresh snapshot and original public signature are byte-for-byte equivalent',function()
    local r,s,native=fixture();local old=I.signature(r,41)
    local snapshot=M.copy(native[41].loadout);assert(I.signature(r,41,snapshot)==old)
    local ok,observed=I.inspect(r,s,true)
    assert(ok and observed.signatures[41]==old)
end)
test('public loadout matches still performs a fresh native read on every call',function()
    local r,s,native,calls=fixture();assert(L.matches(r,s.units[1],41));native[41].loadout.memorized={1}
    assert(not L.matches(r,s.units[1],41)and calls.loadout==2)
end)
test('positions and IDs of same-name items are still compared exactly',function()
    rejected(function(v)v.items[7].id,v.items[20].id=v.items[20].id,v.items[7].id end,'saved_loadout_mismatch')
    rejected(function(v)v.items[7].id=-1;v.items[7].name=nil;v.items[8].id=5;v.items[8].name='Twin'end,'saved_loadout_mismatch')
end)
test('changed native item names remain detectable by the saved inventory check',function()
    rejected(function(v)v.items[7].name='Changed Twin'end,'saved_configuration_mismatch')
end)
test('known and memorized identities and order retain separate checks',function()
    rejected(function(v)v.known={2,1}end,'saved_loadout_mismatch')
    rejected(function(v)v.memorized={1}end,'saved_loadout_mismatch')
    rejected(function(v)v.known={1}end,'saved_loadout_mismatch')
end)
test('changed school identity base and removal are all refused',function()
    for _,change in ipairs({function(v)v.schools[1].base=3 end,function(v)v.schools[1].name='Changed school'end,
        function(v)v.schools[1].path=5 end,function(v)v.schools={}end})do rejected(change,'saved_loadout_mismatch')end
end)
test('native spell-rule validity is not removed by snapshot reuse',function()
    rejected(function(v)v.valid=false end,'saved_loadout_mismatch')
end)
test('malformed or incomplete snapshots fail closed rather than authorizing a check',function()
    local changes={function(v)v.complete=false end,function(v)v.unit=42 end,function(v)v.items[10]=nil end,
        function(v)v.items.extra=true end,function(v)v.items[7].position=2 end,function(v)v.items[7].id='5'end,
        function(v)v.items[7].slotType=8 end,function(v)v.items[7].name=nil end,function(v)v.schools[1].base=nil end,
        function(v)v.schools[1].path='4'end,function(v)v.schools[2]=M.copy(v.schools[1])end,
        function(v)v.known={1,1}end,function(v)v.memorized={'2'}end,function(v)v.known={[-1]=1}end,
        function(v)v.generation=0 end}
    for _,change in ipairs(changes)do rejected(change,'native_loadout_snapshot_incomplete')end
end)
test('a throwing native read becomes an explicit failed observation',function()
    local r,s,_,calls=fixture();calls.onRead=function()error('read failure')end
    local ok,why,detail=I.inspect(r,s,true);assert(not ok and why=='native_loadout_snapshot_incomplete'and detail.reason:find('read failure',1,true))
end)
test('loadout generation must match the preceding guarded field observation',function()
    rejected(function(v)v.generation=v.generation+1 end,'native_identity_mismatch')
    rejected(function(v)v.generation=nil end,'native_identity_mismatch')
end)
test('identity and life getters are rechecked after reading the loadout',function()
    for _,key in ipairs({'monster','owner','hp'})do
        local r,s,native,calls=fixture();calls.onRead=function()native[41][key]=native[41][key]+1 end
        local ok,why=I.inspect(r,s,true);assert(not ok and why=='native_identity_mismatch')
    end
end)
test('changed data on the next verification cannot use a stale read',function()
    local r,s,native,calls=fixture();assert(I.inspect(r,s,true));native[41].loadout.memorized={1}
    local ok,why=I.inspect(r,s,true);assert(not ok and why=='saved_loadout_mismatch'and calls.loadout==2 and calls.field==2)
end)
test('previous signatures still protect disabled saved-configuration checks',function()
    local r,s,native,calls=fixture();local ok,previous=I.inspect(r,s,true);assert(ok)
    native[41].loadout.items[7].id=9
    local ok,why=I.inspect(r,s,true,previous,false);assert(not ok and why=='existing_configuration_changed'and calls.loadout==2)
end)
test('legacy configuration without exact positions still checks saved spells and item names',function()
    local r,s,native,calls=fixture();s.units[1].equipment=nil;s.units[1].schools=nil
    assert(I.inspect(r,s,true));native[41].loadout.memorized={1}
    local ok,why=I.inspect(r,s,true);assert(not ok and why=='saved_configuration_mismatch'and calls.loadout==2)
end)
test('API-absent fallback retains the original eight-slot getter signature',function()
    local r,s,_,calls=fixture();r.api.testFieldLoadoutState=nil;r.api.setTestFieldConfiguration=nil
    s.units[1].baseline=nil;s.units[1].equipment=nil;s.units[1].schools=nil
    assert(I.inspect(r,s,true));assert(calls.loadout==0 and calls.itemGet==8 and calls.spellList==2)
end)
test('getter-only older API keeps its legacy signature and does not require a setter',function()
    local r,s,_,calls=fixture();r.api.setTestFieldConfiguration=nil
    s.units[1].baseline=nil;s.units[1].equipment=nil;s.units[1].schools=nil
    assert(I.inspect(r,s,true));assert(calls.loadout==1 and calls.itemGet==20 and calls.spellList==2)
end)
test('public matches without a supplied observation always reads freshly',function()
    local r,s,native,calls=fixture();assert(L.matches(r,s.units[1],41));native[41].loadout.schools[1].base=3
    assert(not L.matches(r,s.units[1],41));assert(calls.loadout==2)
end)
test('inspection leaves the supplied native observation and saved model untouched',function()
    local r,s,native=fixture();local before=M.copy(native);local model=M.copy(s)
    assert(I.inspect(r,s,true));assert(same(native,before)and same(s,model))
end)
print(count..' offline integrity/loadout read-reuse contracts passed; no native performance or combat simulated')
