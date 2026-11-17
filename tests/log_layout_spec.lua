-- Declared native overlay/input contracts only; no native rendering or combat is simulated.
local cache={}
function require(name)
    if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end
    return cache[name]
end
local M=require('sandbox.model');local U=require('sandbox.ui');local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function same(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function fixture()
    local t={w=800,h=600,x=400,y=200,physical=0,visible=true,rectValid=true,toggleAction=12,writes={},masks={},texts={},draws=0,caps={battleLogVisibility=1}}
    local api={wrap=function(site,fn)t[site]=fn;return true end,observe=function()end,readIni=function()end,
        get=function(key)if key=='screenW'then return t.w elseif key=='screenH'then return t.h elseif key=='uiPointerX'then return t.x elseif key=='uiPointerY'then return t.y elseif key=='mouseButtons'then return t.physical elseif key=='modLastIndex'then return -1 end;return 0 end,
        set=function(key,value)if key=='mouseButtons'then t.masks[#t.masks+1]=value end end,
        testFieldEditorCapabilities=function()return t.caps end,testFieldPointerButtons=function()return t.physical end,
        setTestFieldTextFocus=function()return true end,
        ui={drawRect=function()end,drawText=function(_,_,_,text)t.texts[#t.texts+1]=text end,drawMonsterIconFit=function()return true end}}
    api.testFieldLogState=function()
        if t.badState then return nil,'declared metadata refusal'end
        return {version=1,visible=t.visible,overlay=true,reservesMapSpace=false,toggleAction=t.toggleAction,rectValid=t.rectValid,
            rect=t.rectValid and{x=15,y=15,width=t.w==800 and 200 or 250,height=t.h-30}or nil}
    end
    api.setTestFieldLogVisible=function(value)
        assert(not t.inDraw and type(value)=='boolean','Visibility writes must not run in DRAW.')
        t.writes[#t.writes+1]=value
        if t.refuse then return false,'declared visibility refusal'end
        t.visible=value;return true
    end
    api.battleView=function()return {cellSize=24,screenW=t.w,screenH=t.h}end
    api.battleScreenToCell=function()return 6,6 end;api.battleUnitAt=function()return -1 end
    local u=U.new(api);u.scenario=M.new();M.add(u.scenario,13,'Spearman',1,5,5);M.add(u.scenario,953,'Goblin',2,20,5)
    local r={open=true,current=u.scenario,generation=1,width=32,objects={},live={}}
    function r:ready()return true,{}end;function r:build()self.open=true;return true end
    function r:close()self.open=false;return true end;function r:snapshot()return {}end
    u.runtime=r;u.catalog={byId={},monsters={},mods={}};u.filtered={};u.selected=nil;u.phase='prepare';u.native=true
    u.notice=function(self,text)self.noticeText=text end
    u.report={start=function()t.started=(t.started or 0)+1 end,finish=function()t.finished=(t.finished or 0)+1 end,archive=function()return 'declared-report'end}
    api.fightTestField=function()t.fights=(t.fights or 0)+1 end
    return u,t,api
end
local function draw(u,t)
    t.inDraw=true;local v=t.BATTLE_DRAW(function()t.draws=t.draws+1;return 37 end);t.inDraw=false;return v
end
local function wait(u,t,id)
    return t.BATTLE_WAIT(function()return id or 0 end,0,0)
end
local function button(u,key)
    for _,b in ipairs(u.buttons)do if b.key==key then return b end end
end
test('Prepare hides the real overlay before its first map frame and offers no Show control',function()
    local u,t,api=fixture();local original=M.copy(u.scenario)
    api.drawTestField=function()assert(t.visible==false and #t.writes==1);draw(u,t);u.runtime.open=false end
    u:prepare(false);assert(t.draws==1 and t.writes[1]==false and not button(u,'battlelog')and same(original,u.scenario))
end)
test('Prepare consumes the metadata native toggle action without synthesizing a key or a second write',function()
    local u,t=fixture();t.toggleAction=42;u:prepareLog();draw(u,t);wait(u,t,0)
    local before=#t.writes;assert(wait(u,t,42)==0 and t.visible==false and #t.writes==before)
    assert(wait(u,t,12)==12,'A different native action must not be mistaken for the getter action.')
    u.requestedLogVisible=true;wait(u,t,0);assert(not u.requestedLogVisible and not t.visible and #t.writes==before)
end)
test('each fight shows the native log once even if preparation or the previous fight hid it',function()
    local u,t,api=fixture();t.visible=false;local original=M.copy(u.scenario)
    api.fightTestField=function()assert(t.visible==true and u.phase=='fight');t.fights=(t.fights or 0)+1;t.visible=false end
    assert(u:fight()and #t.writes==1 and t.writes[1]==true and u.phase=='after'and not t.visible)
    u.phase='prepare';u.runtime.phase=nil;assert(u:fight()and #t.writes==2 and t.writes[2]==true and t.fights==2 and same(original,u.scenario))
end)
test('combat draw contains only a labelled presentation button outside actual native log and speed areas',function()
    for _,w in ipairs({800,1136})do
        local u,t=fixture();t.w=w;u.phase='fight';draw(u,t)
        assert(#u.buttons==1);local b=assert(button(u,'battlelog'));local log=assert(u:readLogState()).rect
        assert(b.x==w/2-85 and b.w==170 and b.x>log.x+log.width and b.x+b.w<w-140 and b.y+b.h<=t.h)
        assert(#t.writes==0 and not button(u,'fight')and not button(u,'clear')and not button(u,'unit:1'))
        local label=false;for _,s in ipairs(t.texts)do if s=='Battle log: Hide'then label=true end end;assert(label)
    end
end)
test('combat button owns its whole held gesture through release; native pause/speed resume afterward',function()
    local u,t=fixture();u.phase='fight';draw(u,t);local b=button(u,'battlelog');t.x,t.y=b.x+5,b.y+5;t.physical=1
    assert(wait(u,t,0)==0 and #t.writes==1 and not t.visible and u.logHeldTail)
    -- Moving a held overlay press over native controls must not activate them.
    -- A concurrent native key is deliberately consumed during this owned gesture.
    t.x=t.w-70;t.y=t.h-20
    assert(wait(u,t,3)==0 and wait(u,t,1)==0 and wait(u,t,t.toggleAction)==0 and #t.writes==1)
    t.physical=0;assert(wait(u,t,4)==0 and not u.logHeldTail and #t.masks>0)
    assert(wait(u,t,3)==3 and wait(u,t,1)==1 and wait(u,t,4)==4 and wait(u,t,t.toggleAction)==t.toggleAction)
end)
test('native L remains native during combat and the next DRAW label follows actual state without another toggle',function()
    local u,t=fixture();u.phase='fight';draw(u,t)
    local id=wait(u,t,t.toggleAction);assert(id==t.toggleAction and #t.writes==0)
    t.visible=false;draw(u,t);local show=false;for _,s in ipairs(t.texts)do if s=='Battle log: Show'then show=true end end
    assert(show and #t.writes==0)
end)
test('post-battle label and button use actual visibility and do not reserve an imaginary map band',function()
    for _,w in ipairs({800,1136})do
        local u,t=fixture();t.w=w;u.phase='after';t.visible=false;local bounds=u:usableViewport();draw(u,t)
        local b=assert(button(u,'battlelog'));assert(b.x==536 and b.w==162 and b.x+b.w<button(u,'back').x)
        assert(b.x>15+(w==800 and 200 or 250))
        u:dispatch('battlelog');assert(u.requestedLogVisible==true and #t.writes==0)
        assert(wait(u,t,5)==0 and #t.writes==1 and t.visible and u.zoomAwaitingDraw)
        draw(u,t);assert(same(bounds,u:usableViewport()))
        t.visible=false;draw(u,t);assert(same(bounds,u:usableViewport()))
    end
end)
test('visible valid native log blocks map placement, previews and context while forwarding native log clicks',function()
    local u,t=fixture();u.phase='after';t.x,t.y=40,200;draw(u,t);assert(u:logOccludes(t.x,t.y)and not u:pointerCell())
    t.physical=1;assert(wait(u,t,5)==5 and not u.pending and not u.finalContext and #t.masks==0)
    t.physical=0;wait(u,t,0);t.physical=2;assert(wait(u,t,6)==6 and not u.pending and not u.finalContext)
end)
test('hidden Prepare retains the existing global left-press consumption for the native left viewer path',function()
    local u,t=fixture();t.visible=false;t.x,t.y=40,200;t.physical=1;draw(u,t)
    assert(not u:logOccludes(t.x,t.y)and wait(u,t,5)==0 and #t.masks>0)
end)
test('overlay notices and their held tails retain priority over the native log viewer',function()
    local u,t=fixture();u.phase='after';t.x,t.y=40,200;u.releaseBarrier=true;t.physical=1;draw(u,t)
    assert(wait(u,t,5)==0 and not u.pending)
    t.physical=0;wait(u,t,0);u.noticeText='declared overlay notice';assert(wait(u,t,5)==0)
end)
test('visible state without valid native bounds is displayed without inventing occlusion geometry',function()
    local u,t=fixture();u.phase='fight';t.rectValid=false;draw(u,t)
    assert(u.logState.visible and not u.logState.rectValid and not u:logOccludes(40,200)and #t.writes==0)
    assert(button(u,'battlelog'))
end)
test('a failed combat visibility request reports the error once without changing actor state or native key routing',function()
    local u,t=fixture();u.phase='fight';t.refuse=true;local original=M.copy(u.scenario);draw(u,t);local b=button(u,'battlelog');t.x,t.y=b.x+1,b.y+1;t.physical=1
    wait(u,t,0);assert(#t.writes==1 and t.visible and u.logMessage:find('declared visibility refusal')and same(original,u.scenario))
    assert(wait(u,t,3)==0 and #t.writes==1);t.physical=0;wait(u,t,0);assert(wait(u,t,3)==3)
end)
test('failure to establish default-visible combat refuses before starting or replacing a snapshot',function()
    local u,t=fixture();t.visible=false;t.refuse=true;local original=M.copy(u.scenario)
    assert(not u:fight()and not t.fights and not t.started and not u.snapshot and u.phase=='prepare'and same(original,u.scenario))
    assert(u.noticeText:find('declared visibility refusal'))
end)
test('missing API remains explicit N/A and compatible rather than covering or reconstructing the native log',function()
    local u,t=fixture();t.caps.battleLogVisibility=nil;u.phase='fight';draw(u,t)
    local label=false;for _,s in ipairs(t.texts)do if s=='Battle log: N/A'then label=true end end;assert(label and #t.writes==0)
    assert(not u:requestLogToggle()and u.logMessage:find('unavailable'))
    u.phase='prepare';assert(u:fight()and t.fights==1 and #t.writes==0)
end)
test('Reset hides the overlay before the next editable frame and keeps the previous report/scenario',function()
    local u,t=fixture();u.phase='after';u.snapshot=M.copy(u.scenario);local previous=u.report;local original=M.copy(u.snapshot)
    assert(u:reset(false)and u.phase=='prepare'and not t.visible and u.report==previous and same(original,u.scenario))
    assert(#t.writes==1 and t.writes[1]==false)
end)
test('post-battle visibility changes dismiss stale context before the native overlay can overdraw it',function()
    local u,t=fixture();u.phase='after';t.visible=false;u.finalContext={entry={}};u.context={unit={}}
    assert(u:setLogVisibility(true,'declared test')and not u.finalContext and not u.context and u.zoomAwaitingDraw)
end)
test('Prepare metadata failure is reported once per generation without repeated visibility writes',function()
    local u,t=fixture();t.badState=true;u:prepareLog();assert(u.noticeText:find('declared metadata refusal')and #t.writes==0)
    u.noticeText=nil;u:prepareLog();assert(not u.noticeText and #t.writes==0)
end)
print(count..' offline native-log overlay/state/input contracts passed; native visibility, clipping and combat require real-game verification')
