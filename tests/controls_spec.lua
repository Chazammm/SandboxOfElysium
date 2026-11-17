-- Declared UI and batch contracts only; these do not simulate native mutations.
local cache={}
function require(name)
    if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end
    return cache[name]
end
local M=require('sandbox.model');local U=require('sandbox.ui');local B=require('sandbox.clear_items')
local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function same(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function fixture()
    local st={w=800,h=600,x=100,y=200,buttons=0,text={},calls={},focused=false,caps={configuration=1,clearHeldItems=1,multipleUnique=1,multipleUniquePolicy=1}}
    local api={get=function(key)if key=='screenW'then return st.w elseif key=='screenH'then return st.h elseif key=='uiPointerX'then return st.x elseif key=='uiPointerY'then return st.y elseif key=='modLastIndex'then return -1 end;return 0 end,
        observe=function()end,wrap=function(site,fn)if site=='BATTLE_DRAW'then st.drawHook=fn elseif site=='BATTLE_WAIT'then st.waitHook=fn end;return true end,readIni=function()end,set=function()end,
        setTestFieldTextFocus=function(on)st.focused=on;return true end,testFieldEditorCapabilities=function()return st.caps end,
        setTestFieldConfiguration=function()error('UI must use the runtime transaction')end,
        ui={drawRect=function()end,drawText=function(_,_,_,text)st.text[#st.text+1]=text end,drawMonsterIconFit=function()return true end}}
    local s=M.new();local a=M.add(s,13,'Spearman',1,5,4);local b=M.add(s,953,'Goblin',2,20,4)
    local native={}
    for i,u in ipairs(s.units)do
        local state={unit=50+i,generation=7+i,complete=true,valid=true,items={},known={31,20},memorized={20},organInjuryFlags=5,schools={{path=2,base=2,name='Fire'}}}
        for p=0,19 do state.items[p+1]={position=p,id=-1,slotType=7}end
        state.items[1]={position=0,id=100+i,name='Item '..i,slotType=7,cursed=i==1,permanentEffects=i==1}
        native[50+i]=state;u.equipment={{position=0,id=100+i,name='Item '..i}}
    end
    api.testFieldLoadoutState=function(id)return native[id]and M.copy(native[id])end
    local r={api=api,open=true,current=s,live={[a.id]=51,[b.id]=52},width=32,objects={}}
    function r:ready()return not self.blocked,self.blocked and 'locked' or {}end
    function r:clearHeldItems(scene,u,expected)
        st.calls[#st.calls+1]={id=u.id,expected=expected};assert(scene==s)
        if st.fail==u.id then return false,'declared rejection',{rollbackVerified=st.verified~=false}end
        local state=native[self.live[u.id]];assert(expected.generation==state.generation)
        for p,slot in ipairs(state.items)do assert(expected.items[p]==slot.id);slot.id=-1;slot.name=nil end
        u.equipment={};u.items={};return true,nil,{rollbackVerified=true}
    end
    function r:build()error('these controls must never rebuild')end
    function r:setMultipleUnique(scene,on)assert(scene==s);if st.policyFail then return false,'declared duplicate rejection' end;scene.allowMultipleUnique=on;return true end
    local ui=U.new(api);ui.phase='prepare';ui.scenario=s;ui.runtime=r;ui.catalog={byId={},monsters={},mods={}};ui.filtered={};ui.selected=nil
    ui.notice=function(self,text)self.noticeText=text end
    return {u=ui,s=s,a=a,b=b,r=r,st=st,native=native}
end
test('starting-item controls share one scenario flag and preserve all current configurations',function()
    local f=fixture();local old=M.copy(f.s.units)
    assert(f.u:toggleStartingItems()and f.s.startingItems==false)
    local rows=f.u:setupRows();local label;for _,row in ipairs(rows)do if row[1]==18 then label=row[2]end end
    assert(label:find('omit starting equipment')and same(old,f.s.units))
    f.u:dispatch('startingitems');assert(f.s.startingItems==true and same(old,f.s.units))
    f.r.blocked=true;assert(not f.u:toggleStartingItems()and f.s.startingItems==true)
end)
test('starting-item Off affects only fresh actors and keeps copied equipment policy',function()
    local f=fixture();local original=M.copy(f.a);assert(f.u:toggleStartingItems())
    local fresh=M.add(f.s,13,'Spearman',1,7,4)
    local copy=M.add(f.s,13,'Spearman',2,22,4,f.a)
    assert(fresh.omitStartingItems and not copy.omitStartingItems and same(copy.equipment,original.equipment)and same(f.a,original))
    assert(f.u:toggleStartingItems());local normal=M.add(f.s,13,'Spearman',1,8,4);assert(not normal.omitStartingItems and fresh.omitStartingItems)
end)
test('Single removes the count and plus hitbox and ignores a stale number action',function()
    local f=fixture();f.u.n=12;f.u:draw();assert(f.u.n==1)
    for _,b in ipairs(f.u.buttons)do assert(b.key~='number')end
    local saw=false;for _,label in ipairs(f.st.text)do if label=='Single'then saw=true end;assert(label~='Single (1)')end;assert(saw)
    f.u:dispatch('number');assert(f.u.n==1)
end)
test('row counts remain adjustable and Square cycles exactly2/3/4',function()
    local f=fixture();f.u:dispatch('formation');assert(f.u.formation==2 and f.u.n==1)
    f.u:dispatch('number');assert(f.u.n==2);f.u:dispatch('formation');assert(f.u.formation==3 and f.u.n==1)
    f.u:dispatch('number');assert(f.u.n==2);f.u:dispatch('formation');assert(f.u.formation==4 and f.u.n==2)
    for _,n in ipairs({3,4,2})do f.u:dispatch('number');assert(f.u.n==n)end
    f.u:dispatch('formation');assert(f.u.formation==1 and f.u.n==1)
end)
test('new controls fit600px at both widths and stay inside pointer-owned side panels',function()
    for _,w in ipairs({800,1136})do
        local f=fixture();f.st.w=w;f.u:draw();local found={}
        for _,b in ipairs(f.u.buttons)do
            assert(b.x>=0 and b.y>=0 and b.x+b.w<=w and b.y+b.h<=600)
            if b.key=='clearitems'or b.key=='startingitems'or b.key=='unique'then
                assert(f.u:ownsPointer(b.x+1,b.y+1));found[b.key]=true
            end
        end
        assert(found.clearitems and found.startingitems and found.unique)
    end
end)
test('clear plan binds both teams exact native identity and all20 positions',function()
    local f=fixture();local plan=assert(B.plan(f.r,f.s));assert(#plan.actors==2 and plan.teamA==1 and plan.teamB==1 and plan.items==2 and plan.cursed==1 and plan.implanted==1)
    local expected=plan.actors[1].expected;assert(expected.unit==51 and expected.generation==8 and #expected.items==20 and expected.items[1]==101)
    assert(same(expected.known,{31,20})and same(expected.memorized,{20})and expected.organInjuryFlags==5 and same(expected.schools,{{path=2,base=2}}))
    f.native[51].items[1].id=999;assert(expected.items[1]==101 and #f.st.calls==0)
end)
test('missing bulk API and incomplete snapshots refuse before any actor is mutated',function()
    local f=fixture();f.st.caps.clearHeldItems=nil;assert(not B.plan(f.r,f.s)and #f.st.calls==0)
    f.st.caps.clearHeldItems=1;f.native[52].generation=nil;assert(not B.plan(f.r,f.s)and #f.st.calls==0)
end)
test('Cancel explicitly confirms cursed and implanted scope without mutations and consumes held tails',function()
    local f=fixture();local old=M.copy(f.native);f.u.searchFocused=true
    f.u.menu=function(self,title,rows)
        assert(self.inNativeMenu and not self.searchFocused and title=='Clear All Held Items')
        local all='';for _,row in ipairs(rows)do all=all..row[2]end
        assert(all:find('Both teams')and all:find('cursed items')and all:find('implanted items')and all:find('NOT healed'))
        return 999
    end
    assert(not f.u:clearAllHeldItems()and #f.st.calls==0 and same(old,f.native)and not f.u.inNativeMenu)
    assert(f.u.releaseBarrier and f.u:input(2)and not f.u.pending);f.u:input(0);assert(not f.u.pending)
end)
test('confirmed clear performs one transaction per actor and preserves spells and injury readbacks',function()
    local f=fixture();local old=M.copy(f.native);f.u.menu=function()return 1 end
    assert(f.u:clearAllHeldItems()and #f.st.calls==2)
    for id,state in pairs(f.native)do
        for _,slot in ipairs(state.items)do assert(slot.id==-1)end
        assert(same(state.known,old[id].known)and same(state.memorized,old[id].memorized)and state.organInjuryFlags==old[id].organInjuryFlags)
    end
    assert(f.u.message:find('2/2 actors')and f.u.releaseBarrier)
end)
test('multiple cursed and implanted positions still require exactly one atomic transaction per actor',function()
    local f=fixture();f.native[51].items[2]={position=1,id=103,name='Second cursed item',slotType=7,cursed=true,permanentEffects=true}
    f.native[51].items[3]={position=2,id=104,name='Ordinary item',slotType=7}
    local plan=assert(B.plan(f.r,f.s));assert(plan.items==4 and plan.cursed==2 and plan.implanted==2)
    local result=B.run(f.r,f.s,plan);assert(result.ok and result.removed==4 and #f.st.calls==2)
end)
test('partial failure reports completed actors and verified unchanged failed actor honestly',function()
    local f=fixture();f.st.fail=f.b.id;local original=M.copy(f.native[52]);local plan=assert(B.plan(f.r,f.s));local result=B.run(f.r,f.s,plan)
    assert(not result.ok and result.completed==1 and result.removed==1 and result.remaining==1 and result.rollbackVerified)
    assert(f.native[51].items[1].id==-1 and same(original,f.native[52])and B.describe(result):find('Failed actor verified unchanged'))
end)
test('unverified failure is never reported as unchanged or as a complete success',function()
    local f=fixture();f.st.fail=f.a.id;f.st.verified=false;local result=B.run(f.r,f.s,assert(B.plan(f.r,f.s)))
    assert(not result.ok and result.completed==0 and #f.st.calls==1 and not result.rollbackVerified)
    local text=B.describe(result);assert(text:find('unverified')and text:find('locked')and not text:find('verified unchanged'))
end)
test('identity change after confirmation stops before invoking an unrelated actor',function()
    local f=fixture();local plan=assert(B.plan(f.r,f.s));f.r.live[f.a.id]=99
    local result=B.run(f.r,f.s,plan);assert(not result.ok and result.completed==0 and #f.st.calls==0 and result.rollbackVerified)
end)
test('an empty or already-cleared army never opens confirmation or sends native writes',function()
    local f=fixture();for _,state in pairs(f.native)do for _,slot in ipairs(state.items)do slot.id=-1 end end
    f.u.menu=function()error('nothing to confirm')end;assert(f.u:clearAllHeldItems()and #f.st.calls==0)
    f.s.units={};assert(f.u:clearAllHeldItems()and #f.st.calls==0)
end)
test('unique policy changes keep the same scenario and never rebuild; unavailable API refuses',function()
    local f=fixture();local old=M.copy(f.s.units);local scene=f.s
    assert(f.u:toggleMultipleUnique()and f.s==scene and f.s.allowMultipleUnique and same(old,f.s.units))
    f.st.policyFail=true;assert(not f.u:toggleMultipleUnique()and f.s.allowMultipleUnique and same(old,f.s.units))
    f.st.caps.multipleUniquePolicy=nil;assert(not f.u:toggleMultipleUnique()and f.s.allowMultipleUnique)
end)
local function zoomFixture()
    local f=fixture();local st=f.st;st.caps.battleZoom=1;st.zoomCalls={};st.nativeZoom=1;f.r.generation=4;f.u.native=true
    f.r.clearHeldItems=function()error('zoom must not configure an actor')end
    f.u.api.testFieldZoom=function()
        if st.invalidZoom then return {zoom=1}end
        return {zoom=st.nativeZoom,minZoom=0.5,maxZoom=2,cellSize=24*st.nativeZoom}
    end
    f.u.api.setTestFieldZoom=function(value,x,y)
        assert(st.nativeWaitReturned,'Zoom mutation must follow the native WAIT return.')
        st.zoomCalls[#st.zoomCalls+1]={zoom=value,x=x,y=y}
        if st.zoomRefused then return false,'declared camera refusal'end
        st.nativeZoom=st.acceptedZoom or value;return true
    end
    f.u.api.battleView=function()return {cellSize=24*st.nativeZoom,screenW=st.w,screenH=st.h}end
    f.u.api.battleScreenToCell=function()return nil end
    return f
end
test('closed setup policy remains editable without opening or rebuilding a native field',function()
    local f=fixture();local R=require('sandbox.runtime');local api=f.u.api
    api.setTestFieldMultipleUnique=function()error('closed setup must not invoke a native policy write')end
    local get=api.get;api.get=function(key,id,...)if key=='monsterAbility'then return id==207 and 1 or 0 end;return get(key,id,...)end
    local r=R.new(api,f.u.catalog);local before=M.copy(f.s.units)
    assert(r:setMultipleUnique(f.s,true)and f.s.allowMultipleUnique and same(before,f.s.units))
    M.add(f.s,207,'Arch Devil',1,5,8);M.add(f.s,207,'Arch Devil',2,18,8)
    local all=M.copy(f.s);assert(not r:setMultipleUnique(f.s,false)and same(all,f.s))
    M.remove(f.s,f.s.units[#f.s.units].id);assert(r:setMultipleUnique(f.s,false)and not f.s.allowMultipleUnique)
    r.blocked=true;assert(not r:setMultipleUnique(f.s,true)and not f.s.allowMultipleUnique)
end)
local function zoomWait(f)
    f.st.nativeWaitReturned=false
    return f.st.waitHook(function()f.st.nativeWaitReturned=true;return 73 end,0,0)
end
local function zoomDraw(f)
    return f.st.drawHook(function()return 31 end)
end
test('DRAW never mutates zoom; WAIT applies after native return and blocks input until a fresh DRAW',function()
    local f=zoomFixture();local original=M.copy(f.s);f.u:dispatch('zoomin')
    assert(#f.st.zoomCalls==0 and f.u.requestedZoom>1 and f.u.releaseBarrier)
    assert(zoomDraw(f)==31 and #f.st.zoomCalls==0 and f.st.nativeZoom==1)
    local inputs=0;local input=f.u.input
    f.u.input=function(self,buttons)inputs=inputs+1;return input(self,buttons)end
    assert(zoomWait(f)==0)
    assert(inputs==0 and f.u.zoomAwaitingDraw and f.u.releaseBarrier and f.u.dragBlocked)
    assert(zoomWait(f)==0 and inputs==0 and #f.st.zoomCalls==1)
    local nativeCell
    assert(f.st.drawHook(function()nativeCell=f.u.api.battleView().cellSize;return 31 end)==31)
    assert(#f.st.zoomCalls==1 and f.st.zoomCalls[1].x==245 and f.st.zoomCalls[1].y==300)
    assert(not f.u.zoomAwaitingDraw and math.abs(f.u.zoom-1.1)<0.001 and f.u.view.cellSize==nativeCell and same(original,f.s)and f.u.requestedZoom==nil)
    zoomWait(f);assert(inputs==1 and not f.u.pending)
end)
test('queued zoom clamps both limits and retains the authoritative accepted readback',function()
    local f=zoomFixture();f.st.nativeZoom=1.99;assert(f.u:requestZoom(1)and f.u.requestedZoom==2)
    f.st.acceptedZoom=1.95;zoomWait(f);assert(f.u.zoom==1.95);zoomDraw(f)
    f.st.nativeZoom=0.51;f.st.acceptedZoom=nil;assert(f.u:requestZoom(-1)and f.u.requestedZoom==0.5)
    zoomWait(f);assert(f.u.zoom==0.5)
end)
test('ordinary actions preserve camera and a new field generation reapplies accepted zoom once',function()
    local f=zoomFixture();f.u:requestZoom(-1);zoomWait(f);zoomDraw(f);assert(#f.st.zoomCalls==1)
    f.u:dispatch('startingitems');f.u:dispatch('team2');zoomWait(f);assert(#f.st.zoomCalls==1)
    f.r.generation=5;f.st.nativeZoom=1;zoomWait(f);assert(#f.st.zoomCalls==2 and math.abs(f.st.nativeZoom-0.9)<0.001)
    zoomDraw(f);zoomWait(f);assert(#f.st.zoomCalls==2)
end)
test('zoom refusal is visible and a failed generation restore never retries every frame',function()
    local f=zoomFixture();f.u:requestZoom(-1);zoomWait(f);zoomDraw(f);local last=f.u.zoom
    f.u.releaseBarrier=nil;f.u.dragBlocked=nil;f.r.generation=5;f.st.zoomRefused=true;zoomWait(f)
    assert(f.u.zoom==last and #f.st.zoomCalls==2 and f.u.noticeText:find('declared camera refusal'))
    assert(f.u.zoomAwaitingDraw and f.u.releaseBarrier and f.u.dragBlocked)
    for _=1,4 do zoomWait(f)end;assert(#f.st.zoomCalls==2)
    zoomDraw(f);zoomWait(f);assert(#f.st.zoomCalls==2)
end)
test('missing or incomplete native zoom never imitates a scale or sends writes',function()
    local f=zoomFixture();f.st.caps.battleZoom=nil;assert(not f.u:requestZoom(-1)and #f.st.zoomCalls==0)
    f.st.caps.battleZoom=1;f.st.invalidZoom=true;assert(not f.u:requestZoom(1)and #f.st.zoomCalls==0)
    f.st.invalidZoom=nil;f.u.native=false;assert(not f.u:requestZoom(1));f.u.native=true;f.u.phase='after';assert(not f.u:requestZoom(1))
end)
test('zoom controls fit the top bar without overlapping Back or the fixed side panel at both sizes',function()
    for _,width in ipairs({800,1136})do
        local f=zoomFixture();f.st.w=width;f.u:draw();local zoom,back,side={},nil,nil
        for _,b in ipairs(f.u.buttons)do
            if b.key=='zoomin'or b.key=='zoomout'then zoom[#zoom+1]=b;assert(f.u:ownsPointer(b.x+1,b.y+1))end
            if b.key=='back'then back=b elseif b.key=='clearitems'then side=b end
        end
        assert(#zoom==2 and side.x==width-292 and side.w==284)
        for _,b in ipairs(zoom)do assert(b.x+b.w<back.x and b.y==back.y)end
    end
end)
test('the full right column owns its left margin and inter-panel gap at every declared native zoom',function()
    for _,width in ipairs({800,1136})do for _,zoom in ipairs({0.5,1,2})do
        local f=zoomFixture();f.st.w=width;f.st.nativeZoom=zoom
        for _,point in ipairs({{width-310,200},{width-305,350},{width-301,350},{width-300,350},{width-1,350},{width-305,500}})do
            assert(f.u:ownsPointer(point[1],point[2]),'Panel margin or gap leaked to map.')
        end
        assert(not f.u:ownsPointer(width-311,350)and f.u:ownsPointer(10,599)and f.u:ownsPointer(10,1))
        assert(#f.st.zoomCalls==0)
    end end
end)
local function wheelFixture()
    local f=zoomFixture();f.st.wheel=100;f.st.physical=0
    f.u.api.testFieldPointerWheel=function()return f.st.wheel end
    f.u.api.testFieldPointerButtons=function()return f.st.physical end
    return f
end
test('map wheel queues bounded native zoom around the pointer without changing actors',function()
    local f=wheelFixture();local before=M.copy(f.s);f.u:wheelZoom();assert(not f.u.requestedZoom)
    f.st.wheel=102;f.u:wheelZoom();assert(math.abs(f.u.requestedZoom-1.2)<0.001)
    zoomWait(f);assert(#f.st.zoomCalls==1 and f.st.zoomCalls[1].x==f.st.x and f.st.zoomCalls[1].y==f.st.y and same(before,f.s))
end)
test('scrolling controls and focused editors never changes map zoom or replays discarded wheel steps',function()
    for _,key in ipairs({'noticeText','searchFocused','editWindow','equipDialog','context','releaseBarrier'})do
        local f=wheelFixture();f.u:wheelZoom();f.u[key]=key=='editWindow'and{}or true;f.st.wheel=101;f.u:wheelZoom();assert(not f.u.requestedZoom,key)
        f.u[key]=nil;f.u:wheelZoom();assert(not f.u.requestedZoom,'Discarded scroll replayed')
        f.st.wheel=102;f.u:wheelZoom();assert(math.abs(f.u.requestedZoom-1.1)<0.001)
    end
    for _,point in ipairs({{499,200},{799,350},{10,590},{10,10}})do
        local f=wheelFixture();f.u:wheelZoom();f.st.x,f.st.y=point[1],point[2];f.st.wheel=101;f.u:wheelZoom();assert(not f.u.requestedZoom)
    end
end)
test('held placement buttons keep their drag and consume wheel baseline without zoom',function()
    local f=wheelFixture();f.u:wheelZoom();f.st.physical=2;f.st.wheel=101;f.u:wheelZoom();assert(not f.u.requestedZoom)
    f.st.physical=0;f.u:wheelZoom();assert(not f.u.requestedZoom);f.st.wheel=100;f.u:wheelZoom();assert(math.abs(f.u.requestedZoom-0.9)<0.001)
end)
test('wheel counter wraps correctly and unavailable input never synthesizes scroll',function()
    local f=wheelFixture();f.st.wheel=0xffffffff;f.u:wheelZoom();f.st.wheel=0;f.u:wheelZoom();assert(math.abs(f.u.requestedZoom-1.1)<0.001)
    f=wheelFixture();f.u:wheelZoom();f.st.wheel=nil;f.u:wheelZoom();assert(not f.u.requestedZoom and f.u.lastWheel==nil)
    f.st.wheel=500;f.u:wheelZoom();assert(not f.u.requestedZoom)
end)
test('first WAIT activates native projection control before later wheel handling',function()
    local f=wheelFixture();zoomWait(f);assert(#f.st.zoomCalls==1 and f.st.zoomCalls[1].zoom==1)
    zoomDraw(f);zoomWait(f);assert(#f.st.zoomCalls==1)
end)
print(count..' offline control/confirmation/batch contracts passed; native atomicity and rendering require real-game verification')
