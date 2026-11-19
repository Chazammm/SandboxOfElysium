-- Production browser routing/layout with declared metadata and modal replies.
-- These checks do not simulate native rendering, input injection or a unit card.
local cache={};function require(name)if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end;return cache[name]end
local U=require('sandbox.ui');local M=require('sandbox.model');local V=require('sandbox.unit_view')
local count=0;local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function same(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function fixture(width)
    local t={w=width or 800,h=600,x=740,y=360,buttons=0,icons={},texts={},modalIds={},modalCount=0,
        focused=false,checked=0,accepted=0,quarantined=0,setters={},allocated=0}
    local catalog={monsters={},byId={},mods={},rangedUnknown=0}
    for index=1,12 do
        local row={id=99+index,name=('Unit %02d'):format(index),categories={human=true},sprite=index}
        catalog.monsters[#catalog.monsters+1]=row;catalog.byId[row.id]=row
    end
    local stats={hp=12,armor=1,str=5,mor=5,mr=4,rank=1}
    local api={observe=function()end,wrap=function()return 1 end,readIni=function()end,writeIni=function()return true end}
    api.get=function(key,id,field)
        if key=='screenW'then return t.w elseif key=='screenH'then return t.h
        elseif key=='uiPointerX'then return t.x elseif key=='uiPointerY'then return t.y
        elseif key=='mouseButtons'then return t.buttons elseif key=='ticksMs'then return 100
        elseif key=='monsterLastIndex'then return 5999 elseif key=='monsterName'then return catalog.byId[id]and catalog.byId[id].name or''
        elseif key=='monsterSprite'then return catalog.byId[id]and catalog.byId[id].sprite or 0
        elseif key=='monsterMod'then return id==111 and'Loaded Test Mod'or''
        elseif key=='monster'then return stats[field]or false
        elseif key=='monsterFlags'or key=='monsterMoveFlags'or key=='monsterAbility'then return 0
        elseif key=='monsterAttackType'or key=='effectName'then return nil end
        return 0
    end
    api.set=function(key,value)assert(key=='mouseButtons','View attempted a non-input write');t.setters[#t.setters+1]=value;t.buttons=value end
    api.testFieldPointerButtons=function()return t.buttons end
    api.testFieldEditorCapabilities=function()return{battleZoom=1,battleViewport=1}end
    api.testFieldZoom=function()return{zoom=1,minZoom=0.1,maxZoom=2,cellSize=30}end
    api.setTestFieldZoom=function()error('Unexpected zoom mutation')end
    api.testFieldViewport=function()return{version=1,x=0,y=38,width=t.w-310,height=524,cellSize=30,originX=0,originY=38}end
    api.setTestFieldViewport=function()error('Unexpected viewport mutation')end
    api.fitTestFieldViewport=function()error('Unexpected viewport mutation')end
    api.battleView=function()return{originX=0,originY=38,baseX=0,baseY=0,width=50,height=20,cellSize=30,screenW=t.w,screenH=t.h,cameraX=0,cameraY=0}end
    api.battleScreenToCell=function()return nil end
    api.battleCellToScreen=function(x,y)return(x+0.5)*30,38+(y+0.5)*30 end
    api.battleUnitAt=function()return -1 end
    api.setTestFieldTextFocus=function(focus)t.focused=focus;return true end
    api.takeTestFieldTextEvents=function()return{events={},focused=t.focused}end
    for _,key in ipairs({'addTestFieldUnits','spawnUnit','openTestField','removeTestFieldUnit','setTestFieldConfiguration'})do api[key]=function()t.allocated=t.allocated+1;error('View must not mutate actors')end end
    api.ui={drawRect=function()end,drawText=function(x,y,size,text)t.texts[#t.texts+1]={x=x,y=y,size=size,text=text}end,
        drawMonsterIconFit=function(x,y,w,h,id)t.icons[#t.icons+1]={x=x,y=y,w=w,h=h,id=id};return true end,
        screenBegin=function()t.modalCount=t.modalCount+1 end,screenWidth=function()end,sectionBegin=function()end,
        sectionEnd=function()end,buttonRow=function()end,text=function()end,bindEscape=function()end,
        monsterRow=function(_,id)t.modalIds[#t.modalIds+1]=id end,wait=function()if t.throwModal then error('Controlled modal failure')end;return 999 end}
    local scenario=M.new();M.add(scenario,100,'Unit 01',1,8,9);M.add(scenario,101,'Unit 02',2,20,9)
    local runtime={open=true,width=50,generation=1,live={[1]=21,[2]=22},objects={}}
    runtime.ready=function(_,s)assert(s==scenario);return true,{fixture='previous native observation'}end
    runtime.check=function(_,s,positions,previous)
        assert(s==scenario and positions==true and previous.fixture=='previous native observation');t.checked=t.checked+1
        if t.refuseReadback then return false,'controlled state mismatch',{fixture='fault'}end
        return true,{fixture='unchanged native observation'}
    end
    runtime.accept=function(_,s)assert(s==scenario);t.accepted=t.accepted+1 end
    runtime.quarantine=function(_,s)assert(s==scenario);t.quarantined=t.quarantined+1;runtime.blocked=true end
    local u=U.new(api);u.scenario=scenario;u.runtime=runtime;u.catalog=catalog;u.selected=100;u.phase='prepare';u.native=true;u:refresh()
    return u,t,api,catalog
end
local function button(u,key)for _,b in ipairs(u.buttons)do if b.key==key then return b end end;error('Missing button '..key)end
local function overlap(a,b)return a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h end
local function press(u,t,b)
    t.x=b.x+b.w/2;t.y=b.y+b.h/2;u:input(0);t.buttons=1;assert(u:input(1));local action=u.pending;u.pending=nil;return action
end
test('View and Select have disjoint visible click targets and preserved sprite alignment at both widths',function()
    for _,width in ipairs({800,1136})do
        local u,t=fixture(width);t.x=width-100;u:draw();assert(#t.icons==5)
        for index=1,5 do
            local row=u.filtered[index];local view=button(u,'view:'..row.id);local select=button(u,'unit:'..index)
            assert(not overlap(view,select)and view.y==select.y and view.x+view.w<=select.x)
            local icon=t.icons[index];assert(icon.id==row.id and icon.x+icon.w<view.x)
            assert(view.x>=width-300 and select.x+select.w<=width)
            for _,label in ipairs(t.texts)do if label.text=='View'or label.text=='Select'then assert(label.x>=width-300)end end
        end
    end
end)
test('the actual filtered and paginated unit ID reaches View without changing selection or teams',function()
    for _,width in ipairs({800,1136})do
        local u,t=fixture(width);t.x=width-100;u.search='Unit';u:refresh();u.page=3;u:draw()
        local selected=u.selected;local before=M.copy(u.scenario);local identities={u.scenario.units[1],u.scenario.units[2]}
        local key=press(u,t,button(u,'view:111'));assert(key=='view:111');u:dispatch(key)
        assert(t.modalIds[1]==111 and u.selected==selected and same(u.scenario,before))
        assert(u.scenario.units[1]==identities[1]and u.scenario.units[2]==identities[2]and t.allocated==0)
        assert(M.count(u.scenario,1)==1 and M.count(u.scenario,2)==1 and t.checked==1 and t.accepted==1)
    end
end)
test('search narrows View to its displayed type and Select keeps its toggle behavior',function()
    local u,t=fixture();u.search='Unit 08';u:refresh();u:draw();assert(#u.filtered==1 and u.filtered[1].id==107)
    local key=press(u,t,button(u,'view:107'));u:dispatch(key);assert(t.modalIds[1]==107 and u.selected==100)
    u:input(0);u:draw();key=press(u,t,button(u,'unit:1'));u:dispatch(key);assert(u.selected==107)
    u:input(0);u:draw();key=press(u,t,button(u,'unit:1'));u:dispatch(key);assert(u.selected==nil)
    assert(#u.scenario.units==2 and t.allocated==0)
end)
test('successful View releases search focus and consumes held mouse tails before map input',function()
    local u,t=fixture();u.searchFocused=true;t.focused=true;u.dragOrigin={x=2,y=3};u.lastCell='2:3';t.buttons=1
    assert(u:viewType(104));assert(not u.inNativeMenu and not u.searchFocused and not t.focused)
    assert(u.releaseBarrier and u.dragBlocked and not u.lastCell and not u.dragOrigin)
    assert(u:input(1)and not u.pending);assert(u:input(0)and not u.pending and not u.releaseBarrier)
    assert(t.allocated==0 and #u.scenario.units==2)
end)
test('modal errors restore UI ownership and release barriers without changing the setup',function()
    local u,t=fixture();local before=M.copy(u.scenario);local selected=u.selected;t.throwModal=true
    local ok=u:viewType(104);assert(not ok and not u.inNativeMenu and u.releaseBarrier and u.dragBlocked)
    assert(same(before,u.scenario)and u.selected==selected and t.allocated==0 and t.checked==1 and t.accepted==0)
    assert(u.noticeText:find('View unavailable',1,true)and t.quarantined==0)
    assert(u:input(1)and not u.pending)
end)
test('unverified readback quarantines the existing scenario instead of accepting modal success',function()
    local u,t=fixture();local before=M.copy(u.scenario);t.refuseReadback=true
    assert(not u:viewType(104));assert(t.quarantined==1 and t.accepted==0 and same(before,u.scenario))
    assert(not u.inNativeMenu and u.releaseBarrier and u.runtime.blocked and t.allocated==0)
end)
test('the midpoint guide header cannot steal Back or neighboring header targets at normal and wide sizes',function()
    for _,width in ipairs({800,1136})do
        local u,t=fixture(width);t.x=width-100;u:draw();local guide=button(u,'centerguide');local back=button(u,'back')
        assert(not overlap(guide,back)and guide.x>=0 and guide.x+guide.w<=width)
        for _,b in ipairs(u.buttons)do if b~=guide and b.y==guide.y then assert(not overlap(guide,b),'Guide overlaps '..b.key)end end
        local before=M.copy(u.scenario);u:dispatch('centerguide');assert(u.centerGuideVisible and same(before,u.scenario))
        u:draw();u:dispatch('centerguide');assert(not u.centerGuideVisible and same(before,u.scenario)and t.allocated==0)
    end
end)
test('verified native preview preserves the setup, selection and ordinary card barriers',function()
    local u,t,api=fixture();local before=M.copy(u.scenario);local selected=u.selected
    api.inspectTestFieldMonster=function(id)assert(id==107);return true,{monster=id,verified=true,cleanupVerified=true,scope='native_preview_instance'}end
    assert(u:viewType(107)and same(before,u.scenario)and u.selected==selected)
    assert(t.modalCount==0 and t.checked==1 and t.accepted==1 and t.quarantined==0)
    assert(u.releaseBarrier and u.dragBlocked and not u.inNativeMenu)
    assert(u.message:find('no starting items; random spells may differ',1,true))
    u:draw();local hints={}
    for _,row in ipairs(t.texts)do if row.text:find('View: native preview',1,true)or row.text:find('Random spells may differ',1,true)then
        assert(row.x>=t.w-300 and row.y>=340 and row.y+row.size<=t.h-237);hints[#hints+1]=row
    end end
    assert(#hints==2,'Native preview scope is not visibly explained in the browser')
end)
test('native preview cleanup failure locks editing even when ordinary roster readback could pass',function()
    local u,t,api=fixture();local before=M.copy(u.scenario)
    api.inspectTestFieldMonster=function()return false,'scratch_not_retired',{verified=false,cleanupVerified=false}end
    assert(not u:viewType(107)and same(before,u.scenario)and t.quarantined==1 and t.checked==0 and t.accepted==0)
    assert(t.modalCount==0 and u.runtime.blocked and u.releaseBarrier and not u.inNativeMenu)
end)
test('a wrong-type native preview result is not accepted as the requested card',function()
    local u,t,api=fixture()
    api.inspectTestFieldMonster=function()return true,{monster=108,verified=true,cleanupVerified=true}end
    assert(not u:viewType(107)and t.quarantined==1 and t.accepted==0 and t.modalCount==0)
end)
test('safe native refusal keeps editing available and does not imitate a card',function()
    local u,t,api=fixture();local before=M.copy(u.scenario)
    api.inspectTestFieldMonster=function()return false,'preview_unavailable',{verified=true,cleanupVerified=true,instanceCreated=false}end
    assert(not u:viewType(107)and same(before,u.scenario)and t.quarantined==0 and t.checked==1 and t.modalCount==0)
end)
test('unexpected native preview errors do not silently fall back or assume cleanup',function()
    local u,t,api=fixture();api.inspectTestFieldMonster=function()error('Controlled native API error')end
    assert(not u:viewType(107)and t.quarantined==1 and t.accepted==0 and t.modalCount==0)
end)
print(count..' offline browser View routing/layout/barrier contracts passed; no native rendering or game simulated')
