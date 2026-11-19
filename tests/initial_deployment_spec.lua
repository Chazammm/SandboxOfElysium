-- Native boundaries are declared fixtures. These checks do not simulate CoE5
-- packing, passability or rollback writes; separate native evidence is required.
local cache={}
function require(name)
    if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end
    return cache[name]
end
local M=require('sandbox.model');local R=require('sandbox.runtime');local I=require('sandbox.integrity');local D=require('sandbox.diagnostics')
local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function same(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function fixture()
    local s=M.new();M.add(s,13,'Large',1,1,1);M.add(s,14,'Small',2,8,12)
    local state,receipt;local calls={batch=0,receipts=0,moves=0,opens=0,closes=0};local writes={};local nativeOpen=true;local clock=100
    local catalog={byId={[13]={id=13,name='Large'},[14]={id=14,name='Small'}},mods={},spellKeys={}}
    local function initialize(session)
        local a={unit=101,generation=1000+session,monster=13,owner=0,hp=20,alive=true,kind='actor',creationSource='owned_actor_creation',provenanceVerified=true,
            width=2,height=2,anchorCount=1,anchorLayer='unit',anchors={{x=3,y=6}},occupied={{x=3,y=6},{x=4,y=6},{x=4,y=7}},known={7,8},memorized={8,7},worldX=1,worldY=1}
        local b={unit=102,generation=2000+session,monster=14,owner=24,hp=10,alive=true,kind='actor',creationSource='owned_actor_creation',provenanceVerified=true,
            width=1,height=1,anchorCount=1,anchorLayer='unit',anchors={{x=3,y=7}},occupied={{x=3,y=7}},known={},memorized={},worldX=1,worldY=1}
        state={complete=true,classificationVersion=1,session=session,width=12,height=20,allowMultipleUnique=false,units={a,b},grid={},issues={{code='overlapping_footprint',unit=101,x=3,y=7}}}
        for x=0,11 do for y=0,19 do state.grid[#state.grid+1]={x=x,y=y,unit=x==3 and(y==6 and 101 or y==7 and 102 or-1)or-1,object=-1}end end
        receipt={version=1,session=session,token=700+session,fresh=true,eligible=true,sourceHealthy=false,actorOverlapOnly=true,completeRoster=true,actors={},
            overlaps={{unit=101,otherUnit=102,x=3,y=7}}}
        for _,row in ipairs(state.units)do receipt.actors[#receipt.actors+1]={unit=row.unit,generation=row.generation,monster=row.monster,owner=row.owner,
            x=row.anchors[1].x,y=row.anchors[1].y,width=row.width,height=row.height,kind=row.kind,creationSource=row.creationSource,provenanceVerified=true}end
    end
    initialize(17)
    local function relocate(rows)
        for _,entry in ipairs(rows)do for _,row in ipairs(state.units)do if row.unit==entry.unit then
            row.anchors={{x=entry.x,y=entry.y}};row.occupied={}
            for x=entry.x,entry.x+row.width-1 do for y=entry.y,entry.y+row.height-1 do row.occupied[#row.occupied+1]={x=x,y=y}end end
        end end end
        for _,cell in ipairs(state.grid)do cell.unit=-1 end
        for _,row in ipairs(state.units)do local p=row.anchors[1];state.grid[p.x*20+p.y+1].unit=row.unit end
        state.issues={}
    end
    local api={testFieldState=function()return M.copy(state)end,
        testFieldEditorCapabilities=function()return{emptyEditor=1,exactDeploymentVersion=1,initialDeploymentVersion=1}end,
        testFieldInitialDeployment=function()calls.receipts=calls.receipts+1;return M.copy(receipt)end,
        readIni=function(name)if name=='launcher-context'then return{environment={session='offline-intake'}}end;return writes[name]end,
        listIni=function()local names={};for name in pairs(writes)do names[#names+1]=name end;return names end,
        writeIni=function(name,data)writes[name]=M.copy(data);return true end,set=function()end,
        spellInfo=function(id)return{name=id==7 and'First'or'Second'}end,
        testFieldLifecycle=function()return{session=state.session,complete=true,open=nativeOpen,issues={}}end}
    api.get=function(key,id,index)
        if key=='ticksMs'then clock=clock+1;return clock elseif key=='modLastIndex'then return-1 elseif key=='battleWidth'then return state.width
        elseif key=='squareTerrain'then return 0 elseif key:find('slotColor',1,true)then return 0.2 elseif key=='monsterAbility'then return 0 end
        local row;for _,candidate in ipairs(state.units)do if candidate.unit==id then row=candidate;break end end
        if row then
            if key=='unitMonster'then return row.monster elseif key=='unitOwner'then return row.owner elseif key=='unitHp'then return row.hp
            elseif key=='unitBattleX'then return row.anchors[1].x elseif key=='unitBattleY'then return row.anchors[1].y
            elseif key=='unitX'or key=='unitY'then return 1
            elseif key=='unitKnownSpell'then return row.known[index+1]or-1 elseif key=='unitMemorizedSpell'then return row.memorized[index+1]or-1 end
        end
        return-1
    end
    api.moveTestFieldUnit=function()calls.moves=calls.moves+1;error('Sequential movement cannot repair this initial fixture')end
    api.setTestFieldDeployment=function(rows,options)
        calls.batch=calls.batch+1;calls.rows=M.copy(rows);calls.options=M.copy(options)
        if calls.refuse then return false,'native_stand_rejected',{version=1,phase='preflight',rollbackVerified=false,byteRollbackVerified=true,
            rollbackResult='invalid_source_restored',sourceHealthy=false,finalHealthy=false,initialReceiptUsed=true,initialSession=state.session,units=#rows}end
        relocate(rows)
        return true,nil,{version=1,phase='committed',rollbackVerified=true,byteRollbackVerified=true,rollbackResult='not_needed',sourceHealthy=false,
            finalHealthy=true,initialReceiptUsed=options~=nil,initialSession=state.session,units=#rows,wroteAnchors=true}
    end
    api.openTestField=function()
        calls.opens=calls.opens+1;initialize(17+calls.opens);nativeOpen=true
        return true,{commander=-1,friends={101},enemies={102}}
    end
    api.closeTestField=function()calls.closes=calls.closes+1;nativeOpen=false;return true end
    local diag=D.new(api);local r=R.new(api,catalog,diag);r.open=true;r.width=12;r.generation=3;r.live={[1]=101,[2]=102}
    return r,s,api,calls,function()return state,receipt end,relocate,writes,initialize
end

test('ordinary integrity and ordinary placement still reject overlapping initial actors',function()
    local r,s,api,calls=fixture();assert(not I.inspect(r,s,false,nil,false));assert(not r:place(s))
    assert(calls.receipts==0 and calls.batch==0 and calls.moves==0 and not r.current and not r.verified)
end)
test('authenticated initial repair uses every generation once and requires strict final readback',function()
    local r,s,api,calls,current=fixture();local frozen=M.copy(s);local initial=M.copy(current())
    assert(r:place(s,true));assert(calls.receipts==1 and calls.batch==1 and calls.moves==0 and calls.options.initialReceipt==717)
    assert(#calls.rows==2 and calls.rows[1].generation==initial.units[1].generation and calls.rows[2].generation==initial.units[2].generation)
    assert(r:check(s,true,nil,false));assert(same(s,frozen)and not r.current and not r.verified,'Provisional intake became an accepted editor checkpoint')
end)
test('stale or incompatible receipts refuse without a native mutation',function()
    for _,change in ipairs({function(v)v.fresh=false end,function(v)v.eligible=false end,function(v)v.version=2 end,function(v)v.token='717'end,function(v)v.session=18 end,
        function(v)v.sourceHealthy=true end,function(v)v.actorOverlapOnly=false end,function(v)v.completeRoster=false end})do
        local r,s,api,calls,current=fixture();local _,receipt=current();change(receipt)
        assert(not r:place(s,true)and calls.batch==0 and calls.moves==0 and not r.current)
    end
end)
test('missing API capability never authorizes the exceptional intake path',function()
    local r,s,api,calls=fixture();api.testFieldEditorCapabilities=function()return{exactDeploymentVersion=1}end
    assert(not r:place(s,true)and calls.receipts==0 and calls.batch==0)
end)
test('changed identity or incomplete receipt roster refuses before batch dispatch',function()
    for _,change in ipairs({function(v)table.remove(v.actors)end,function(v)v.actors[1].generation=1 end,function(v)v.actors[1].owner=24 end,
        function(v)v.actors[1].x=4 end,function(v)v.actors[1].provenanceVerified=false end})do
        local r,s,api,calls,current=fixture();local _,receipt=current();change(receipt)
        assert(not r:place(s,true)and calls.batch==0 and calls.moves==0)
    end
end)
test('unexplained issues and structural collisions cannot borrow actor-overlap permission',function()
    for _,change in ipairs({function(state)state.issues[1].code='missing_anchor'end,function(state)state.issues[1].x=4 end,
        function(state)state.units[2].kind='structure';state.units[2].creationSource='native_gate_replacement'end,
        function(state)state.units[1].anchorCount=0 end,function(state)state.units[1].occupied[1]=nil end})do
        local r,s,api,calls,current=fixture();local state=current();change(state)
        assert(not r:place(s,true)and calls.batch==0 and calls.moves==0)
    end
end)
test('the receipt must explain every actual lost footprint hit and no invented pair',function()
    for _,change in ipairs({function(v)v.overlaps={}end,function(v)v.overlaps[1].otherUnit=999 end,function(v)v.overlaps[1].y=8 end,
        function(v)v.overlaps[2]=M.copy(v.overlaps[1])end})do
        local r,s,api,calls,current=fixture();local _,receipt=current();change(receipt)
        assert(not r:place(s,true)and calls.batch==0)
    end
end)
test('exact byte rollback of an invalid source is quarantined and never reported healthy',function()
    local r,s,api,calls,current=fixture();calls.refuse=true;local before=M.copy(current());local frozen=M.copy(s)
    assert(not r:place(s,true)and r.blocked and calls.batch==1 and calls.moves==0)
    assert(same(before,current())and same(frozen,s)and same(frozen,r.recovery))
    assert(r.lastDeployment.byteRollbackVerified==1 and r.lastDeployment.rollbackVerified==0 and r.lastDeployment.sourceHealthy==0)
    assert(r.diag.lastError.restored=='unverified; editing locked'and not r.current and not r.verified)
end)
test('a claimed repair needs its initial receipt/session and final-health contract',function()
    for _,change in ipairs({function(v)v.initialReceiptUsed=false end,function(v)v.initialSession=18 end,function(v)v.finalHealthy=false end})do
        local r,s,api,calls=fixture();local original=api.setTestFieldDeployment
        api.setTestFieldDeployment=function(...)local ok,why,detail=original(...);change(detail);return ok,why,detail end
        assert(not r:place(s,true)and r.blocked and not r.current)
    end
end)
test('matching final positions do not hide a generation replacement or reordered spells',function()
    for _,change in ipairs({function(state)state.units[1].generation=9000 end,function(state)state.units[1].memorized={7,8}end,function(state)state.units[1].hp=19 end})do
        local r,s,api,calls,current=fixture();local original=api.setTestFieldDeployment
        api.setTestFieldDeployment=function(...)local ok,why,detail=original(...);change(current());return ok,why,detail end
        assert(not r:place(s,true)and r.blocked and not r.current)
    end
end)
test('a healthy ordinary source takes the unchanged strict route without a receipt',function()
    local r,s,api,calls,current,relocate=fixture();relocate({{unit=101,x=2,y=2},{unit=102,x=9,y=10}})
    assert(r:place(s)and calls.receipts==0 and calls.batch==1 and calls.options==nil and calls.moves==0)
end)
test('a refused first exact build keeps its requested recovery and original disk source',function()
    local r,s,api,calls,current,relocate,writes=fixture();assert(r:close());calls.refuse=true
    r.sourceScenarioFile='original-user-recovery';local expected=M.encode(s,{})
    assert(api.writeIni(r.sourceScenarioFile,expected));local disk=M.copy(writes[r.sourceScenarioFile]);local original=M.copy(s)
    local ok,why=r:build(s,false)
    assert(not ok and r.blocked and not r.open and calls.opens==1)
    assert(same(original,s)and r.recovery and same(original,r.recovery),'First refused build erased its requested in-memory recovery')
    assert(r.sourceScenarioFile=='original-user-recovery'and same(disk,writes[r.sourceScenarioFile]),'Original disk recovery was replaced')
    local preserved=r.recoveryFile and M.copy(writes[r.recoveryFile]);assert(preserved and preserved.recovery)
    preserved.recovery=nil;assert(same(expected,preserved),'Preserved recovery file is not the original requested setup')
    assert(not why:find('Previous army restored',1,true)and why:find('native_stand_rejected',1,true),'First-open failure hid its native reason or claimed a rollback')
end)
test('quarantined native target refusals retain the actor cell and concrete reason',function()
    for _,case in ipairs({{'off_field','out_of_bounds','outside the native field'},
        {'blocked','target_overlap','Saved unit footprints overlap'},{'blocked','structure','blocked by a native structure'}})do
        local r,s,api=fixture()
        api.setTestFieldDeployment=function(rows)return false,case[1],{version=1,phase='preflight',units=#rows,unit=101,x=8,y=9,
            blockerKind=case[2],rollbackVerified=false,byteRollbackVerified=true,sourceHealthy=false,finalHealthy=false}end
        local ok,why=r:place(s,true)
        assert(not ok and r.blocked and why:find(case[3],1,true)and why:find('(8, 9)',1,true)and why:find('Large',1,true),why)
        assert(why:find('Editing locked',1,true)and not why:find('Previous army restored',1,true),why)
    end
end)
test('a verified previous-army restoration still reports the refused requested target',function()
    local r,s,api=fixture();r.current=s;r.lastKnownGood=M.copy(s)
    local builds=0;r._build=function()builds=builds+1;return builds~=1,'Saved footprint at (14, 3) is outside the native field'end
    r.check=function()return true,{}end
    local ok,why=r:build(M.copy(s),false)
    assert(not ok and builds==2 and not r.blocked and why:find('Previous army restored',1,true)and why:find('outside the native field',1,true),why)
end)
test('failed requested and rollback fields stay separately readable after close',function()
    local r,s,api,calls,current,relocate,writes=fixture();relocate({{unit=101,x=1,y=1},{unit=102,x=8,y=12}})
    r.current=s;r.lastKnownGood=M.copy(s);calls.refuse=true
    local requested=M.copy(s);requested.units[1].x=2
    local ok,why=r:build(requested);assert(not ok and not why:find('Previous army restored',1,true)and r.blocked and not r.open)
    assert(calls.opens==2 and r.diag.buildFailures.requested and r.diag.buildFailures.rollback)
    local first=r.diag.buildFailures.requested;local rollback=r.diag.buildFailures.rollback
    assert(first.summary.session=='18'and rollback.summary.session=='19'and first.nativeUnits[1].anchors=='3,6')
    assert(first.issues[1].code=='overlapping_footprint'and first.nativeUnits[1].generation~=rollback.nativeUnits[1].generation)
    local file=assert(r.diag:export({},nil));local data=writes[file]
    assert(data.build_failure_requested.session=='18'and data.build_failure_rollback.session=='19')
    assert(data.build_failure_requested_native1.anchors=='3,6'and data.build_failure_requested_snapshot.open=='1')
    assert(#requested.units==2 and requested.units[1].x==2 and #r.recovery.units==2)
end)
test('failure observations are frozen bounded and sanitized independently of later retries',function()
    local r,s,api,calls,current,relocate,writes=fixture();local state=current();local group={}
    for i=3,110 do local row=M.copy(state.units[2]);row.unit=100+i;row.generation=3000+i;state.units[i]=row end
    for i=2,40 do state.issues[i]={code='overlapping_footprint',unit=101,x=i,y=7}end
    for _,cell in ipairs(state.grid)do cell.object=555 end
    local snapshot={summary={open=1,field_generation=3},units={},nativeUnits={},cells={}}
    r.diag:captureBuildFailure(group,'requested','intake','failure C:\\private\\file',{summary=snapshot.summary},state,s,r.live,{api_token='do not export',reason='secret=hidden'})
    state.units[1].hp=-9999;state.units[1].anchors[1].x=11
    r.diag:captureBuildFailure(group,'requested','later','must not replace',snapshot,state,s,r.live,{})
    r.diag:captureBuildFailure(group,'rollback','intake','different failure',snapshot,state,s,r.live,{})
    local file=assert(r.diag:export({},nil));local data=writes[file]
    assert(data.build_failure_requested.native_rows_total=='110'and data.build_failure_requested.native_rows_exported=='96')
    assert(data.build_failure_requested.issues_total=='40'and data.build_failure_requested.issues_exported=='32')
    assert(data.build_failure_requested_native1.hp=='20'and data.build_failure_requested_native1.anchors=='3,6')
    assert(data.build_failure_requested.stage=='intake'and data.build_failure_requested_context.api_token=='[redacted]')
    assert(not data.build_failure_requested.message:find('private',1,true)and not data.build_failure_requested_context.reason:find('hidden',1,true))
    assert(data.build_failure_rollback_native1.hp=='-9999'and data.build_failure_requested.ticks_ms~='unknown')
end)
print(count..' offline initial-intake/readback/failure-capture contracts passed; native receipt freshness and repair require real-game evidence')
