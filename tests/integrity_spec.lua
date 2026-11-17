-- Validation and injected contract failures, not a simulation of native creation.
local cache={}
function require(name)
    if not cache[name] then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))() end
    return cache[name]
end
local M=require('sandbox.model');local R=require('sandbox.runtime');local I=require('sandbox.integrity')
local n=0
local function test(name,fn)fn();n=n+1;print('PASS '..name)end
local function row(id,monster,owner,x,y,w,h)
    local cells={};for a=x,x+w-1 do for b=y,y+h-1 do cells[#cells+1]={x=a,y=b} end end
    return {unit=id,monster=monster,owner=owner,hp=20,alive=true,width=w,height=h,anchorCount=1,anchors={{x=x,y=y}},occupied=cells}
end
local function fixture()
    local s=M.new();M.add(s,13,'Spearman',1,4,4);M.add(s,202,'Rider',2,16,12)
    local state={complete=true,width=32,height=20,issues={},units={row(11,13,0,4,4,1,1),row(12,202,24,16,12,3,3)},grid={}}
    local calls={add=0,remove=0,move=0,preserve=0,errors={}}
    local api={testFieldState=function()return state end,
        get=function(key,id)
            if key=='monsterAbility' then return id==202 and 1 or 0 end
            if key=='battleWidth' then return 32 end
            for _,u in ipairs(state.units) do if u.unit==id then
                if key=='unitMonster' then return u.monster elseif key=='unitOwner' then return u.owner elseif key=='unitHp' then return u.hp end
            end end
            return -1
        end,spellInfo=function()end,
        addTestFieldUnits=function()calls.add=calls.add+1;return nil,'refused' end,
        removeTestFieldUnit=function()calls.remove=calls.remove+1;return false,'refused' end,
        moveTestFieldUnit=function()calls.move=calls.move+1;return false end}
    local diag={snapshot=function()return {summary={},units={}} end,
        failure=function(self,action,why,details,before,after,restored)self.lastError={action=action,message=why,details=details,restored=restored};calls.errors[#calls.errors+1]=why end,
        preserve=function()calls.preserve=calls.preserve+1;return 'recovery-test-1','test/recovery-test-1.ini' end,
        record=function()end}
    local r=R.new(api,{byId={[13]={id=13,name='Spearman'},[202]={id=202,name='Rider'}},mods={}},diag)
    r.open=true;r.width=32;r.live={[1]=11,[2]=12};r.current=s;r.lastKnownGood=M.copy(s)
    return r,s,state,calls
end
test('complete 1x1 and 3x3 bijection verified',function()
    local r,s=fixture();assert(I.inspect(r,s,true))
end)
local function structureFixture()
 local r,s,state,calls=fixture();state.classificationVersion=1;state.session=4
 local gate=row(20,1436,24,20,8,1,2);gate.kind='structure';gate.creationSource='native_gate_replacement';gate.provenanceVerified=true;gate.generation=91;gate.anchorLayer='unit'
 state.units[#state.units+1]=gate;return r,s,state,calls,gate
end
test('constructor-proven native structures stay outside model and team actors',function()
 local r,s,state=structureFixture();local ok,observed=I.inspect(r,s,true);assert(ok and observed.structures[20] and not observed.used[20] and #s.units==2)
end)
test('a gate monster placed as an ordinary actor is still an orphan without a model',function()
 local r,s,state,calls,gate=structureFixture();gate.kind='actor';local ok,why=I.inspect(r,s,true);assert(not ok and why=='orphaned_native_unit')
end)
test('unproven or wrong-generation structures and partial footprints are refused',function()
 for _,field in ipairs({'provenanceVerified','creationSource','generation','anchorLayer','occupied'})do
  local r,s,state,calls,gate=structureFixture();gate[field]=field=='occupied' and {} or field=='generation' and 0 or false
  local ok,why=I.inspect(r,s,true);assert(not ok and why=='native_structure_unverified',field)
 end
end)
test('unexpected structure damage or removal fails rollback verification',function()
 local r,s,state,calls,gate=structureFixture();local ok,before=I.inspect(r,s,true);assert(ok);gate.hp=gate.hp-1
 local ok,why=I.inspect(r,s,true,before);assert(not ok and why=='native_structure_changed');state.units[3]=nil
 local ok,why=I.inspect(r,s,true,before);assert(not ok and why=='native_structure_missing')
end)

test('aliased live handle refused before any mutation',function()
    local r,s,_,calls=fixture();r.live[2]=11
    local ok=r:add(s,13,1,8,8);assert(not ok and r.blocked and calls.add==0 and calls.remove==0)
    assert(r.diag.firstIntegrity.message=='aliased_native_handle' and calls.preserve==1)
end)
test('dead actor, missing anchor and partial native view are not healthy',function()
    for _,kind in ipairs({'dead','anchor','partial'}) do
        local r,s,state=fixture()
        if kind=='dead' then state.units[2].hp=0;state.units[2].alive=false
        elseif kind=='anchor' then state.units[2].anchorCount=0;state.units[2].anchors={}
        else state.complete=false end
        assert(not I.inspect(r,s,true))
    end
end)
test('all cells of a large footprint must match',function()
    local r,s,state=fixture();table.remove(state.units[2].occupied)
    local ok,why=I.inspect(r,s,true);assert(not ok and why=='native_footprint_mismatch')
end)
test('orphan and changed team rejected',function()
    local r,s,state=fixture();state.units[#state.units+1]=row(15,13,0,8,8,1,1)
    assert(not I.inspect(r,s,true));table.remove(state.units);state.units[2].owner=0
    assert(not I.inspect(r,s,true))
end)
test('duplicate unique creature refused before native creation',function()
    local r,s,_,calls=fixture();local ok=r:add(s,202,1,22,4)
    assert(not ok and calls.add==0 and calls.remove==0 and not r.blocked)
end)
test('unverified cleanup locks all following mutations and preserves first cause',function()
    local r,s,state,calls=fixture()
    r.api.addTestFieldUnits=function()calls.add=calls.add+1;state.units[#state.units+1]=row(15,13,0,22,9,1,1);return {15} end
    local ok=r:add(s,13,1,8,8);assert(not ok and r.blocked and calls.add==1 and calls.remove==1 and calls.preserve==1)
    local first=r.diag.firstIntegrity.message
    local mutations=calls.add+calls.remove+calls.move
    assert(not r:add(s,13,1,9,8));assert(not r:remove(s,s.units[2]));assert(not r:move(s.units[1],6,6));assert(not r:memorize(s.units[2],'missing',true))
    assert(mutations==calls.add+calls.remove+calls.move and first==r.diag.firstIntegrity.message and calls.preserve==1)
    assert(#r.recovery.units==2 and r.recovery.units[2].monster==202)
end)
test('false native move with changed state locks the editor',function()
    local r,s,state=fixture()
    r.api.moveTestFieldUnit=function()state.units[1].anchors[1].x=5;return false end
    assert(not r:move(s.units[1],6,6) and r.blocked)
end)
test('successful move return cannot substitute for a global final-position check',function()
    local r,s,state=fixture()
    state.units[1].anchors[1].x=5;state.units[1].occupied[1].x=5
    r.api.moveTestFieldUnit=function()return true end -- lying injected contract
    local ok,why=r:place(s);assert(not ok and why=='native_position_mismatch')
end)
test('already permanently retired new allocation can have a verified unchanged rollback',function()
    local r,s,state=fixture()
    r.api.addTestFieldUnits=function()state.units[#state.units+1]=row(15,13,0,22,9,1,1);return {15} end
    r.api.removeTestFieldUnit=function()table.remove(state.units);return false,'dead_unit' end
    r.api.testFieldUnitState=function()return {alive=false,hp=-9999,worldX=-1,worldY=-1,anchors={},occupied={}}end
    local ok=r:add(s,13,1,8,8)
    assert(not ok and not r.blocked and r.diag.lastError.restored=='existing army kept')
    assert(r.diag.lastError.details.remove_result==0 and r.diag.lastError.details.rollback_verified==1)
end)
test('large placement chain parks the actual cycle and avoids every destination footprint',function()
    local r=fixture();local s=M.new();s.allowMultipleUnique=true
    local targets={{21,6,3,3},{21,12,3,3},{21,17,3,3},{19,15,2,2}}
    local starts={{20,1},{20,7},{20,13},{20,16}};local state={complete=true,issues={},units={}}
    r.live={};r.api.testFieldState=function()return state end
    for i,t in ipairs(targets)do M.add(s,13,'Test actor',1,t[1],t[2]);r.live[i]=100+i;state.units[i]=row(100+i,13,0,starts[i][1],starts[i][2],t[3],t[4])end
    r.api.get=function(key,id)
        for _,u in ipairs(state.units)do if u.unit==id then
            if key=='unitMonster'then return u.monster elseif key=='unitOwner'then return u.owner elseif key=='unitHp'then return u.hp
            elseif key=='unitBattleX'then return u.anchors[1].x elseif key=='unitBattleY'then return u.anchors[1].y end
        end end;return -1
    end
    local parks={}
    r.api.moveTestFieldUnit=function(id,x,y)
        local index=id-100;local u=state.units[index];local w,h=u.width,u.height
        for _,other in ipairs(state.units)do if other.unit~=id then local a=other.anchors[1]
            if x<a.x+other.width and x+w>a.x and y<a.y+other.height and y+h>a.y then return false end
        end end
        if x<0 or y<0 or x+w>32 or y+h>20 then return false end
        if x~=targets[index][1] or y~=targets[index][2]then
            assert(not parks[id],'same actor was parked twice');parks[id]=true
            for _,t in ipairs(targets)do assert(not(x<t[1]+t[3] and x+w>t[1] and y<t[2]+t[4] and y+h>t[2]),'parking covers a desired footprint')end
        end
        state.units[index]=row(id,13,0,x,y,w,h);return true
    end
    local ok,why=r:place(s);assert(ok,why);assert(parks[103] and parks[104] and I.inspect(r,s,true))
end)
test('overlapping desired footprints are refused before any native move',function()
    local r,s,_,calls=fixture();s.units[1].x=17;s.units[1].y=13
    local ok,why=r:place(s);assert(not ok and why:find('footprints overlap') and calls.move==0)
end)
test('unverified whole-field cleanup preserves setup and requires fresh isolated process',function()
    local r,s,_,calls=fixture();local opened=0
    r.api.closeTestField=function()return false,'owned_actor_still_alive' end
    r.api.openTestField=function()opened=opened+1;return true,{} end
    local ok,why=r:close()
    assert(not ok and why=='owned_actor_still_alive' and r.blocked and r.cleanupFailed)
    assert(r.recovery and #r.recovery.units==2 and calls.preserve==1)
    assert(not r:build(s) and not r:recover() and opened==0)
    local other=fixture()
    other.api.closeTestField=function()return true end
    other.api.testFieldLifecycle=function()return {open=false,complete=false,issues={{code='cleanup_unverified'}}} end
    assert(not other:close() and other.blocked and other.recovery,'success without verified lifecycle accepted')
end)
test('HP-zero removal success cannot authorize rollback or a later battle',function()
    local r,s,state,calls=fixture()
    r.api.addTestFieldUnits=function()state.units[#state.units+1]=row(15,13,0,22,9,1,1);return {15}end
    r.api.removeTestFieldUnit=function()table.remove(state.units);return true end
    r.api.testFieldUnitState=function()return{alive=false,hp=0,worldX=1,worldY=1,anchors={},occupied={}}end
    assert(not r:add(s,13,1,8,8)and r.blocked and r.cleanupFailed and #s.units==2 and calls.preserve==1)
    assert(not r:ready(s)and not r:recover())
end)
test('HP-zero deletion does not silently remove the saved actor',function()
    local r,s,state,calls=fixture()
    r.api.removeTestFieldUnit=function()table.remove(state.units,2);return true end
    r.api.testFieldUnitState=function()return{alive=false,hp=0,worldX=1,worldY=1,anchors={},occupied={}}end
    assert(not r:remove(s,s.units[2])and r.blocked and r.cleanupFailed and #s.units==2 and calls.preserve==1)
end)
print(n..' integrity/contract checks passed outside game')
