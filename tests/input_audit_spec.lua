-- Production input routing with declared native geometry only; no game or native mutation is simulated.
local cache={}
function require(name)
    if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end
    return cache[name]
end
local M=require('sandbox.model');local U=require('sandbox.ui')
local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function fixture(width)
    local st={w=width,h=600,x=100,y=200,cellX=6,cellY=6,hit=-1,wrappers={}}
    local api={get=function(key)
        if key=='screenW'then return st.w elseif key=='screenH'then return st.h
        elseif key=='uiPointerX'then return st.x elseif key=='uiPointerY'then return st.y
        elseif key=='modLastIndex'then return -1 end;return 0
    end,set=function()end,readIni=function()end,observe=function()end,wrap=function(site,fn)st.wrappers[site]=fn;return true end,
        battleScreenToCell=function()return st.cellX,st.cellY end,battleUnitAt=function()return st.hit end,
        testFieldFootprint=function(monster)return {monster=monster,width=3,height=3,source='native_monster_rules',exact=true,anchor='positive_xy'}end}
    local u=U.new(api);u.phase='prepare';u.native=true;u.selected=206;u.scenario=M.new()
    u.runtime={open=true,width=30,live={},objects={}}
    u.catalog={byId={[206]={name='Seraph',id=206}},mods={},testFieldTerrains={}}
    return u,st
end

test('right presses originating in every setup margin cannot begin placement on their held tail',function()
    for _,width in ipairs({800,1136})do
        for _,point in ipairs({{width-100,300},{100,10},{100,590}})do
            local u,st=fixture(width);st.x,st.y=point[1],point[2]
            assert(u:input(2)and not u.pending,'the setup UI must own the initial press')
            st.x,st.y=100,200;u:input(2)
            assert(not u.pending,'a held UI press must not place a unit after entering the battlefield')
            u:input(0);u:input(2)
            assert(u.pending and u.pending.place and u.pending.x==6 and u.pending.y==6,'release must permit a new intentional placement')
        end
    end
end)

test('invalid physical helpers lock setup once without throwing or retaining a queued action',function()
    local samples={false,function()return nil end,function()error('Injected missing pointer')end,function()return'0'end,function()return 0.5 end,function()return 8 end}
    for _,sample in ipairs(samples)do
        local u,st=fixture(800);u.api.testFieldPointerButtons=sample;u.pending={place=true,x=6,y=6}
        local locks=0;u.runtime.quarantine=function(self,scenario,reason)locks=locks+1;self.blocked=true;assert(scenario==u.scenario and reason=='physical_pointer_unavailable')end
        for _=1,2 do local ok,id=pcall(st.wrappers.BATTLE_WAIT,function()return 77 end);assert(ok and id==0)end
        assert(locks==1 and u.runtime.blocked and not u.pending and u.releaseBarrier)
    end
end)

test('intentional map-origin drag survives crossing the setup UI without repeating visited cells',function()
    for _,width in ipairs({800,1136})do
        local u,st=fixture(width);u:input(2)
        assert(u.pending and u.pending.place);u.pending=nil
        st.x,st.y=width-100,300;u:input(2);assert(not u.pending)
        st.x,st.y,st.cellX,st.cellY=100,200,9,6;u:input(2)
        assert(u.pending and u.pending.place and u.pending.x==9 and u.pending.y==6)
        u.pending=nil;st.cellX=6;u:input(2);assert(not u.pending,'a visited drag anchor must not be attempted again')
        st.cellX=9;u:input(2);assert(not u.pending,'the second visited anchor must remain visited')
        u:input(0);u:input(2);assert(u.pending and u.pending.x==9,'a fresh drag may retry an anchor')
    end
end)

test('formation drags retain their complete footprint spacing',function()
    local u,st=fixture(1136);u.formation=2;u.n=2;u:input(2)
    assert(u.pending and u.pending.x==6);u.pending=nil
    st.cellX=9;u:input(2);assert(not u.pending,'the adjacent 3-cell unit remains inside the 6-cell formation span')
    st.cellX=12;u:input(2);assert(u.pending and u.pending.x==12)
end)

print(count..' input audit tests passed')
