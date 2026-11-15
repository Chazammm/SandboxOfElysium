-- Offline UI event scheduling/privacy invariants, not a simulated native game.
local cache={}
function require(name)
    if not cache[name] then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))() end
    return cache[name]
end
local M=require('sandbox.model');local D=require('sandbox.diagnostics');local U=require('sandbox.ui');local n=0
local function test(name,fn) fn();n=n+1;print('PASS '..name) end
test('diagnostics remain bounded, chronological and unique',function()
    local files={['diagnostics-session-1']={old=true}}
    local api={get=function(key)if key=='modLastIndex' then return -1 end;return 100 end,
        readIni=function()return {environment={session='session'}} end,
        listIni=function()local names={};for name in pairs(files) do names[#names+1]=name end;return names end,
        writeIni=function(name,data)assert(not files[name],'overwritten diagnostic');files[name]=data;return true end}
    local d=D.new(api);for i=1,80 do d:record('place',{id=i}) end
    assert(#d.events==64 and d.events[1].sequence==17 and d.events[64].sequence==80)
    local a=d:export({},nil);local b=d:export({},nil)
    assert(a=='diagnostics-session-2' and b=='diagnostics-session-3' and files['diagnostics-session-1'].old)
end)
test('diagnostic values redact synthetic paths and credentials',function()
    local written
    local api={get=function(key)if key=='modLastIndex' then return -1 end;return 100 end,readIni=function()return nil end,
        listIni=function()return {} end,writeIni=function(_,data)written=data;return true end}
    local d=D.new(api)
    d:failure('place','PASSWORD=SYNTHETIC_A token=SYNTHETIC_B C:\\Users\\Example\\private.txt',{access_token='SYNTHETIC_C'},nil,nil,'unchanged')
    assert(d:export({},nil))
    local function visit(value)
        if type(value)=='table' then for _,v in pairs(value) do visit(v) end
        elseif type(value)=='string' then assert(not value:find('SYNTHETIC') and not value:find('C:\\Users',1,true)) end
    end
    visit(written);assert(written.error.restored=='unchanged')
end)
local function inputFixture()
    local px,py,cx,cy=200,200,6,6;local live=11;local transforms=0
    local api={get=function(key)if key=='screenW' then return 800 elseif key=='screenH' then return 600 elseif key=='uiPointerX' then return px elseif key=='uiPointerY' then return py elseif key=='unitHp' then return 6 end end,
        battleUnitAt=function()return live end,battleScreenToCell=function()transforms=transforms+1;return cx,cy end}
    local s=M.new();local unit=M.add(s,13,'Spearman',1,6,6)
    local u=setmetatable({api=api,scenario=s,runtime={open=true,live={[unit.id]=11}},selected=13,phase='prepare',native=true,lastMouse=0,buttons={},diag={record=function()end}},U)
    return u,function(x,y,a,b,id)px=x;py=y;cx=a;cy=b;live=id end,function()return transforms end
end
test('existing native unit gets context before placement',function()
    local u=inputFixture();assert(u:input(2));assert(u.context and u.context.unit.id==1 and not u.pending and u.dragBlocked)
end)
test('held right placement schedules once per new cell',function()
    local u,set=inputFixture();set(200,200,7,6,-1);u:input(2);assert(u.pending.place and u.pending.x==7);u.pending=nil
    u:input(2);assert(not u.pending);set(220,200,8,6,-1);u:input(2);assert(u.pending.place and u.pending.x==8)
    u.pending=nil;u:input(0);u:input(2);assert(u.pending.place)
end)
test('unit panel occludes native placement and transform',function()
    local u,set,transforms=inputFixture();set(700,100,6,6,-1);assert(u:input(2));assert(not u.pending and not u.context and transforms()==0)
end)
test('Select button schedules selection without placement',function()
    local u,set=inputFixture();set(700,100,6,6,-1);u.buttons={{key='unit:1',x=690,y=90,w=60,h=25}}
    assert(u:input(1));assert(u.pending=='unit:1' and not u.context)
    u.pending=nil;u.buttons={};set(200,200,7,6,-1)
    assert(u:input(1) and not u.pending,'held closing click leaked into native battle controls')
end)
test('moving while right remains held cannot fall through to placement',function()
    local u,set=inputFixture();set(200,200,7,6,-1);u.moving=u.scenario.units[1];u.lastMouse=2;u:input(2);assert(not u.pending)
end)
test('modal result cannot activate a native battle control; later native IDs survive',function()
    local wait,masked
    local api={readIni=function()end,get=function()return 0 end,set=function(_,value)masked=value end,observe=function()end,
        wrap=function(site,fn)if site=='BATTLE_WAIT' then wait=fn end end}
    local u=U.new(api);u.phase='prepare';u.noticeText='Diagnostics saved'
    assert(wait(function()return 1 end)==0 and masked==0)
    u.noticeText=nil
    u.input=function()return false end
    assert(wait(function()return 70 end)==70)
    local synchronous=false
    u.runtime={open=true};u.inNativeMenu=true
    u.menu=function()synchronous=true;return 1 end
    u:notice('Nested editor error')
    assert(synchronous and not u.noticeText,'nested native editor hid its error message')
end)
test('physical hold survives consumed frame masks and places only on new drag cells',function()
    local wait,engine,physical,cell,scheduled= nil,0,2,6,0
    local api={readIni=function()end,observe=function()end,
        get=function(key)if key=='mouseButtons' then return engine elseif key=='screenW' then return 800 elseif key=='screenH' then return 600 elseif key=='uiPointerX' or key=='uiPointerY' then return 200 end;return 0 end,
        set=function(key,value)if key=='mouseButtons' then engine=value end end,
        testFieldPointerButtons=function()return physical end,
        battleScreenToCell=function()return cell,6 end,battleUnitAt=function()return -1 end,
        wrap=function(site,fn)if site=='BATTLE_WAIT' then wait=fn end end}
    local u=U.new(api);u.phase='prepare';u.native=true;u.runtime={open=true,live={}};u.scenario=M.new();u.selected=13
    for frame=1,8 do
        engine=frame%2==1 and 2 or 0 -- simulate the consumable native frame mask
        if frame==5 then cell=7 end
        assert(wait(function()return 70 end)==0)
        if u.pending then assert(u.pending.place);scheduled=scheduled+1;u.pending=nil end
    end
    assert(scheduled==2,'held press retried on the same cell')
    physical=0;engine=0;assert(wait(function()return 70 end)==70)
    physical=2;engine=2;wait(function()return 0 end);assert(u.pending.place)
end)
test('locked editor consumes native controls without scheduling placement',function()
    local u,set=inputFixture();u.runtime.blocked=true;set(200,200,7,6,-1)
    assert(u:input(2) and not u.pending and not u.context)
    assert(u:input(0))
    local candidate=M.new();local opened=false;local step=0
    u.catalog={testFieldTerrains={[0]=true}};u.ensureCatalog=function()end;u.scenario=M.new()
    u.runtime.recover=function()u.runtime.blocked=false;return true,candidate end
    u.menu=function(_,_,rows)
        step=step+1
        if step==1 then
            local actions={};for _,row in ipairs(rows)do if row[1]then actions[row[1]]=true end end
            assert(actions[14] and actions[13] and actions[999] and not actions[11] and not actions[15]);return 14
        end
        return 999
    end
    u.prepare=function(_,native,reuse)assert(not native and reuse);opened=true end
    u:setup();assert(opened and u.scenario==candidate,'closed-field recovery was unreachable')
end)
print(n..' offline editor/privacy checks passed; no native camera or battles simulated')
