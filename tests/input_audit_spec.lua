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
    local api={get=function(key,index)
        if key=='screenW'then return st.w elseif key=='screenH'then return st.h
        elseif key=='uiPointerX'then return st.x elseif key=='uiPointerY'then return st.y
        elseif key=='keyHeld'then return index==st.ctrl
        elseif key=='modLastIndex'then return -1 elseif key=='unitHp'then return 8 end;return 0
    end,set=function()end,readIni=function()end,observe=function()end,wrap=function(site,fn)st.wrappers[site]=fn;return true end,
        battleScreenToCell=function()return st.cellX,st.cellY end,battleUnitAt=function(x,y)return st.cells and (st.cells[x..':'..y] or -1) or st.hit end,
        battleObjectAt=function(x,y)if x==6 and y==6 then return st.object end end,
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

local function deleteFixture()
    local u,st=fixture(1136)
    local first=M.add(u.scenario,206,'Seraph',1,5,6)
    local nextUnit=M.add(u.scenario,206,'Seraph',2,9,6)
    local last=M.add(u.scenario,206,'Seraph',2,11,6)
    local object=M.add(u.scenario,1404,'Wall',3,6,6);object.scenery=true
    u.runtime.live={[first.id]=21,[nextUnit.id]=23,[last.id]=25,[object.id]=80}
    st.cells={['5:6']=21,['6:6']=21,['7:6']=21,['9:6']=23,['11:6']=25}
    st.object=80;st.ctrl=224
    return u,st,first,nextUnit,last,object
end

test('Ctrl deletion starts off and ordinary right click still opens actions or places',function()
    local u,st,first=deleteFixture()
    assert(u:input(2) and not u.pending and not u.context)
    u:input(0);st.ctrl=nil
    assert(u:input(2) and u.context.unit==first and not u.pending)
    u:input(0);u.context=nil;st.cellX=8
    u:input(2);assert(u.pending and u.pending.place)
end)

test('Ctrl click selects the army layer and waits for a new press after releasing Ctrl',function()
    local u,st,first=deleteFixture()
    u:dispatch('ctrldelete');u:input(0)
    assert(u.ctrlDeleteEnabled and u:input(2))
    assert(u.pending and #u.pending.deleteUnits==1 and u.pending.deleteUnits[1]==first.id and not u.context)
    u.pending=nil;st.cellX=7;u:input(2);assert(not u.pending)
    st.ctrl=nil;st.cellX=9;u:input(2);assert(not u.pending and not u.context)
    st.ctrl=228;u:input(2);assert(not u.pending)
    u:input(0);u:input(2);assert(u.pending and u.pending.deleteUnits)
end)

test('Ctrl drag catches crossed cells, de-duplicates footprints and keeps scenery',function()
    local u,st,first,second,last=deleteFixture()
    u:dispatch('ctrldelete');u:input(0);st.cellX=4;u:input(2);assert(not u.pending)
    st.cellX=11;u:input(2)
    local ids=assert(u.pending.deleteUnits)
    assert(#ids==3 and ids[1]==first.id and ids[2]==second.id and ids[3]==last.id)
    u.pending=nil;st.cellX=5;u:input(2);assert(not u.pending)
end)

test('a Ctrl press originating over UI or a modal cannot resume over a unit',function()
    for _,mask in ipairs({'panel','noticeText','editWindow','equipDialog','searchFocused','context'})do
        local u,st=deleteFixture()
        u:dispatch('ctrldelete');u:input(0)
        if mask=='panel'then st.x=st.w-100 else u[mask]=true end
        u:input(2);assert(not u.pending)
        if mask=='panel'then st.x=100 else u[mask]=nil end
        u:input(2);assert(not u.pending)
        u:input(0);u:input(2);assert(u.pending and u.pending.deleteUnits)
    end
end)

test('drag segments stop at UI and an ordinary press cannot turn into a delete stroke',function()
    local u,st,_,_,last=deleteFixture()
    u:dispatch('ctrldelete');u:input(0);st.cellX=4;u:input(2)
    st.x=st.w-100;u:input(2)
    st.x=100;st.cellX=11;u:input(2)
    assert(#u.pending.deleteUnits==1 and u.pending.deleteUnits[1]==last.id)
    u.pending=nil;u:input(0);st.ctrl=nil;st.cellX=4;u:input(2);assert(u.pending.place)
    u.pending=nil;st.ctrl=224;st.cellX=6;u:input(2);assert(not u.pending and not u.context)
end)

test('delete dispatch uses verified removal and stops on the first refusal',function()
    local u,st,first,second,last,object=deleteFixture()
    local called={}
    u.runtime.remove=function(_,s,unit)
        called[#called+1]=unit.id
        if unit.id==second.id then return false,'Native refusal' end
        local candidate=M.copy(s);M.remove(candidate,unit.id);return true,candidate
    end
    u.notice=function(_,message)assert(message=='Native refusal')end
    u:dispatch({deleteUnits={object.id,first.id,second.id,last.id}})
    assert(#called==2 and called[1]==first.id and called[2]==second.id)
    assert(#u.scenario.units==3 and u.message=='Native refusal')
end)

print(count..' input audit tests passed')
