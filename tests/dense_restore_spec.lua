-- Complete-roster transaction routing and verification. Native admissibility,
-- object passability and rollback writes require separate real-game evidence.
local cache={}
function require(name)
    if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end
    return cache[name]
end
local M=require('sandbox.model');local Runtime=require('sandbox.runtime')
local passed=0
local function test(name,fn)fn();passed=passed+1;print('PASS '..name)end
local function same(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function fixture(width,count)
    local s=M.new();local state={complete=true,width=width,height=20,issues={},units={}}
    local calls={moves=0,batches=0,preserved=0};local rowsById={}
    local function row(id,x,y,w,h,team)
        local occupied={};for dx=0,w-1 do for dy=0,h-1 do occupied[#occupied+1]={x=x+dx,y=y+dy}end end
        return {unit=id,monster=13,owner=team==2 and 24 or 0,hp=20,alive=true,width=w,height=h,
            generation=900+id,anchorCount=1,anchors={{x=x,y=y}},occupied=occupied}
    end
    local function replace(id,x,y)
        local current=rowsById[id];local nextRow=row(id,x,y,current.width,current.height,current.owner==24 and 2 or 1)
        rowsById[id]=nextRow;for i,u in ipairs(state.units)do if u.unit==id then state.units[i]=nextRow;break end end
    end
    local api={testFieldState=function()return state end,spellInfo=function()return nil end,
        testFieldEditorCapabilities=function()return{exactDeploymentVersion=1}end}
    api.get=function(key,id)
        local native=rowsById[id]
        if native then
            if key=='unitMonster'then return native.monster elseif key=='unitOwner'then return native.owner elseif key=='unitHp'then return native.hp
            elseif key=='unitBattleX'then return native.anchors[1].x elseif key=='unitBattleY'then return native.anchors[1].y end
        end
        return -1
    end
    api.moveTestFieldUnit=function(id,x,y)
        calls.moves=calls.moves+1
        for _,other in ipairs(state.units)do if other.unit~=id and other.anchors[1].x==x and other.anchors[1].y==y then return false,'blocked'end end
        replace(id,x,y);return true
    end
    api.setTestFieldDeployment=function(rows)
        calls.batches=calls.batches+1;calls.last=M.copy(rows)
        for _,entry in ipairs(rows)do replace(entry.unit,entry.x,entry.y)end
        return true,nil,{version=1,phase='committed',rollbackVerified=true,wroteAnchors=true,units=#rows}
    end
    local diag={record=function()end,snapshot=function()return{}end,
        failure=function(self,action,why,details,before,after,restored)self.lastError={action=action,message=why,details=details,restored=restored}end,
        preserve=function()calls.preserved=calls.preserved+1;return 'dense-recovery','dense-recovery.ini'end}
    local r=Runtime.new(api,{byId={[13]={id=13,name='Spearman'}},mods={}},diag);r.open=true;r.width=width;r.live={}
    for id=1,count do
        local current=id-1;local wanted=id%count;local team=id%2+1
        M.add(s,13,'Spearman',team,math.floor(wanted/20),wanted%20)
        local native=row(100+id,math.floor(current/20),current%20,1,1,team)
        state.units[id]=native;rowsById[native.unit]=native;r.live[id]=native.unit
    end
    r.current=s;r.lastKnownGood=M.copy(s)
    return r,s,state,calls,replace
end

test('a full cyclic field restores exact cells in one native roster transaction without parking',function()
    local r,s,state,calls=fixture(2,40);local saved=M.copy(s)
    assert(r:place(s));assert(calls.batches==1 and calls.moves==0 and same(saved,s)and not r.blocked)
    for i,entry in ipairs(calls.last)do assert(entry.unit==r.live[s.units[i].id]and entry.generation==state.units[i].generation)end
    assert(r:check(s,true,nil,false))
end)
test('batch routing preserves team identity and includes every current actor exactly once',function()
    local r,s,state,calls=fixture(4,9);local before={};for _,u in ipairs(state.units)do before[u.unit]={u.monster,u.owner,u.hp,u.generation}end
    assert(r:place(s));local ids={}
    for _,entry in ipairs(calls.last)do assert(not ids[entry.unit]);ids[entry.unit]=true end
    for _,u in ipairs(state.units)do assert(ids[u.unit]and same(before[u.unit],{u.monster,u.owner,u.hp,u.generation}))end
end)
test('a verified terrain refusal reports the real cell and keeps the native source positions',function()
    local r,s,state,calls=fixture(4,3);local original=M.copy(state)
    r.api.setTestFieldDeployment=function()calls.batches=calls.batches+1;return false,'blocked',{version=1,phase='preflight',rollbackVerified=true,wroteAnchors=false,unit=102,x=1,y=7,object=700,objectSource='native_terrain_placement',blockerKind='terrain'}end
    local ok,why=r:place(s)
    assert(not ok and why:find('(1, 7)',1,true)and why:find('native terrain',1,true))
    assert(same(original,state)and not r.blocked and calls.moves==0 and calls.batches==1)
    assert(r.lastConfig.deployment_object==700 and r.lastConfig.deployment_unit==102 and r.lastConfig.deployment_rollbackVerified==1)
end)
test('a refused atomic operation never falls back to individual native movement',function()
    local r,s,state,calls=fixture(4,3)
    r.api.setTestFieldDeployment=function()calls.batches=calls.batches+1;return false,'off_field',{version=1,phase='preflight',rollbackVerified=true,unit=101,x=8,y=2,blockerKind='out_of_bounds'}end
    local ok,why=r:place(s);assert(not ok and why:find('outside',1,true)and calls.moves==0 and not r.blocked)
end)
test('a rollback claim with changed positions quarantines the scenario instead of accepting the claim',function()
    local r,s,state,calls,replace=fixture(4,3);local frozen=M.copy(s)
    r.api.setTestFieldDeployment=function()replace(101,2,3);return false,'blocked',{version=1,phase='rollback',rollbackVerified=true,unit=101}end
    assert(not r:place(s)and r.blocked and calls.preserved==1 and calls.moves==0)
    assert(same(frozen,s)and same(frozen,r.recovery))
end)
test('a successful native return still requires complete exact readback and unchanged signatures',function()
    local r,s,state,calls=fixture(4,3)
    r.api.setTestFieldDeployment=function(rows)return true,nil,{version=1,phase='committed',rollbackVerified=true,units=#rows}end
    assert(not r:place(s)and r.blocked and calls.preserved==1 and calls.moves==0)
end)
test('native configuration changes during deployment are caught even when anchors match',function()
    local r,s,state,calls=fixture(4,3);local native=r.api.setTestFieldDeployment
    r.api.setTestFieldDeployment=function(rows)local ok,why,detail=native(rows);state.units[1].hp=19;return ok,why,detail end
    assert(not r:place(s)and r.blocked and calls.preserved==1 and calls.moves==0)
end)
test('missing rollback verification and exceptions lock editing and retain recovery',function()
    for _,kind in ipairs({'missing','exception'})do
        local r,s,state,calls=fixture(4,3)
        r.api.setTestFieldDeployment=function()if kind=='exception'then error('injected native boundary failure')end;return false,'blocked',{}end
        assert(not r:place(s)and r.blocked and calls.preserved==1 and calls.moves==0)
    end
end)
test('partial or incompatible success metadata cannot become a verified deployment',function()
    for _,kind in ipairs({'version','phase','count'})do
        local r,s,state,calls=fixture(4,3);local native=r.api.setTestFieldDeployment
        r.api.setTestFieldDeployment=function(rows)local ok,why,detail=native(rows);if kind=='version'then detail.version=2 elseif kind=='phase'then detail.phase='queued'else detail.units=#rows-1 end;return ok,why,detail end
        assert(not r:place(s)and r.blocked and calls.moves==0)
    end
end)
test('a declared API mismatch refuses before either placement path is called',function()
    for _,value in ipairs({'1',2,true})do
        local r,s,state,calls=fixture(4,3);r.api.testFieldEditorCapabilities=function()return{exactDeploymentVersion=value}end
        assert(not r:place(s)and calls.batches==0 and calls.moves==0 and not r.blocked)
    end
    local r,s,state,calls=fixture(4,3);r.api.setTestFieldDeployment=nil
    assert(not r:place(s)and calls.moves==0 and not r.blocked)
end)
test('older Extenders retain the existing sequential path only when the atomic API is absent',function()
    local r,s,state,calls=fixture(4,3);r.api.setTestFieldDeployment=nil;r.api.testFieldEditorCapabilities=function()return{}end
    assert(r:place(s)and calls.batches==0 and calls.moves>0 and not r.blocked)
end)
test('overlapping and out-of-field full footprints refuse before the native transaction',function()
    for _,kind in ipairs({'overlap','outside'})do
        local r,s,state,calls=fixture(4,3)
        if kind=='overlap'then s.units[1].x=s.units[2].x;s.units[1].y=s.units[2].y else s.units[1].x=4 end
        assert(not r:place(s)and calls.batches==0 and calls.moves==0 and not r.blocked)
    end
end)
test('the genuinely empty actor roster uses a verified empty transaction',function()
    local r,s,state,calls=fixture(4,0);assert(r:place(s)and calls.batches==1 and #calls.last==0 and calls.moves==0)
end)
print(passed..' offline dense-deployment routing/readback contracts passed; native passability and atomic writes require real-game checks')
