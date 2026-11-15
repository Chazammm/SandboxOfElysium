-- UI/input and persistence contracts with declared readbacks, not an engine simulation.
local cache={}
function require(name)
    if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end
    return cache[name]
end
local M=require('sandbox.model');local C=require('sandbox.catalog');local U=require('sandbox.ui')
local W=require('sandbox.config_window');local L=require('sandbox.loadout');local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function same(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function fixture()
    local state={x=200,y=200,w=800,h=600,events={},focused=false,nativeButtons=0,cellX=5,cellY=4,panels={},setCalls=0}
    local api={observe=function()return 1 end,wrap=function(site,fn)if site=='BATTLE_WAIT'then state.wait=fn end;return 1 end}
    api.get=function(key,id)
        if key=='screenW'then return state.w elseif key=='screenH'then return state.h
        elseif key=='uiPointerX'then return state.x elseif key=='uiPointerY'then return state.y
        elseif key=='mouseButtons'then return state.nativeButtons elseif key=='unitHp'then return 10
        elseif key=='ticksMs'then return 100 elseif key=='modLastIndex'then return -1 end;return 0
    end
    api.set=function()end;api.readIni=function()return nil end
    api.battleView=function()return {cellSize=24,screenW=state.w,screenH=state.h}end
    api.battleScreenToCell=function()return state.cellX,state.cellY end
    api.battleCellToScreen=function(x,y)return 20+x*24,80+y*24 end
    api.battleUnitAt=function(x,y)return x==5 and y==4 and 51 or x==20 and y==4 and 52 or -1 end
    api.testFieldPointerButtons=function()return state.nativeButtons end
    api.setTestFieldTextFocus=function(on)state.focused=on;return true end
    api.takeTestFieldTextEvents=function()local e=state.events;state.events={};return {events=e,focused=state.focused}end
    api.ui={drawRect=function()end,drawText=function(...)state.panels[#state.panels+1]={...}end,drawMonsterIconFit=function()return true end,drawItemIconFit=function()return true end}
    local s=M.new();local a=M.add(s,13,'Caster',1,4,3);local b=M.add(s,13,'Caster',2,20,3)
    local native={unit=51,generation=7,complete=true,valid=true,items={},known={1},memorized={1},
        schools={{path=39,name='Druidism',base=2,templateBase=1,bonus=1,level=3,allowance=4},{path=70,name='Mod school',base=1,templateBase=1,bonus=0,level=1,allowance=2}}}
    for p=0,19 do native.items[p+1]={position=p,slotType=p==0 and 1 or p==6 or p==7 and 7 or 0,id=-1}end
    native.items[7].slotType=7;native.items[8].slotType=7;native.items[7].id=153;native.items[7].name='Amulet'
    api.testFieldLoadoutState=function(id)local copy=M.copy(native);copy.unit=id;return copy end
    api.setTestFieldConfiguration=function()state.setCalls=state.setCalls+1;return true end
    api.testFieldEditorCapabilities=function()return {configuration=1,schoolLevelReduction=1}end
    local c={byId={[13]={id=13,name='Caster'}},monsters={{id=13,name='Caster',categories={}}},mods={},terrainById={[0]={name='Plain'}},
        items={{id=153,name='Amulet',slot=7,origin={kind='baseline',modded=false}},{id=142,name='Amulet cold',slot=7,origin={kind='created_by_mod',modded=true,definedBy='TestMod'}},
            {id=0,name='Frost Brand',slot=1,origin={kind='modified_by_mod',modded=true,lastModifiedBy='TestMod'}}},byItemId={},itemSlots={1,7},spellKeys={['1:Original']=1},
        spells={{id=1,name='Original',level=1,path=39},{id=3,name='Same',level=2,path=39},{id=5,name='Same',level=2,path=39},{id=4,name='Higher',level=3,path=39}},rangedUnknown=0}
    for _,item in ipairs(c.items)do c.byItemId[item.id]=item end
    local r={api=api,catalog=c,open=true,current=s,live={[a.id]=51,[b.id]=52},objects={},width=32}
    function r:ready()return true,{verified='declared fixture'}end
    function r:setLabel(u,label)local good,why=M.validLabel(label);if not good then return false,why end;u.label=label~='' and label or nil;return true end
    function r:check()return true,{verified='declared fixture'}end
    function r:accept()end
    function r:quarantine(_,why)self.blocked=true;return false,why end
    local u=U.new(api);u.scenario=s;u.runtime=r;u.catalog=c;u.filtered=c.monsters;u.selected=13;u.phase='prepare';u.native=true
    return {u=u,state=state,api=api,c=c,r=r,s=s,a=a,b=b,native=native}
end
test('selected item targets the actual native interior hit once per press and Cancel restores context',function()
    local f=fixture();local u=f.u;u.selectedItem=f.c.items[2];u.catalogTab='items'
    assert(u:input(2) and u.pending.equip and u.pending.model_id==f.a.id and not u.context)
    u.pending=nil;assert(u:input(2) and not u.pending);u:input(0)
    u:dispatch('itemcancel');u:input(0);u:input(2)
    assert(u.context and u.context.unit==f.a and not u.pending and not u.selectedItem)
end)
test('Items mode never places a unit into empty cells while Units keeps intentional placement',function()
    local f=fixture();f.state.cellX=10;f.u.catalogTab='items';f.u:input(2);assert(not f.u.pending)
    f.u:input(0);f.u:dispatch('catalogunits');f.u:input(0);f.u:input(2);assert(f.u.pending.place)
end)
test('drag and resize clamp the unit window and consume every held/released tail',function()
    local f=fixture();assert(W.open(f.u,f.a));f.u:input(0);local w=f.u.editWindow
    f.state.x=w.x+20;f.state.y=w.y+w.h-12;f.u:input(1);assert(w.drag)
    f.state.x=3000;f.state.y=-2000;f.u:input(1);assert(w.x>=10 and w.x+w.w<=790 and w.y>=42 and w.y+w.h<=558)
    f.u:input(0);f.u:input(0);assert(not f.u.pending and #f.s.units==2)
    f.state.x=w.x+w.w-10;f.state.y=w.y+10;f.u:input(1);assert(w.drag and w.drag.resize)
    f.state.x=4000;f.state.y=-2000;f.u:input(1);f.u:input(0);f.u:input(0)
    assert(w.x+w.w<=790 and w.y+w.h<=558 and not f.u.pending)
end)
test('window and modal clicks cannot activate overlapping panel or map controls',function()
    local f=fixture();W.open(f.u,f.a);f.u:input(0);local w=f.u.editWindow;w.x=350;w.y=80
    f.u.buttons={{key='fight',x=500,y=200,w=100,h=30}}
    f.state.x=510;f.state.y=210;f.u:input(1);assert(not f.u.pending)
    f.u:input(0);f.u.equipDialog={unitId=f.a.id};f.state.x=200;f.state.y=200;f.u:input(2)
    assert(not f.u.pending and not f.u.context)
end)
test('inline item search is independent and consumes native shortcuts including submit',function()
    local f=fixture();f.u.catalogTab='items';f.u.search='unit query';f.u.itemPage=5
    assert(f.u:setSearchFocus(true));f.state.events={{type='text',text='Amu'},{type='submit'}}
    assert(f.state.wait(function()return 4 end,0,0)==0)
    assert(f.u.itemSearch=='Amu' and f.u.search=='unit query' and #f.u.filteredItems==2 and f.u.itemPage==1)
end)
test('occupied slot requires a separate confirmation, Cancel calls no mutation and expected ID stays bound',function()
    local f=fixture();f.u.selectedItem=f.c.items[2];W.give(f.u,f.a);assert(f.u.equipDialog and f.u.equipDialog.position==nil)
    W.dispatch(f.u,'config:slot:6');assert(f.u.equipDialog.position==6 and f.u.equipDialog.expected==153 and f.state.setCalls==0)
    W.dispatch(f.u,'config:cancel');assert(not f.u.equipDialog and f.state.setCalls==0)
    W.give(f.u,f.a);W.dispatch(f.u,'config:slot:6');f.native.items[7].id=142
    local real=L.equip;local called=0
    L.equip=function(_,unit,position,item,expected)called=called+1;assert(unit==f.a and position==6 and expected==153 and item.id==142);return false,'Slot changed; review it again.'end
    W.dispatch(f.u,'config:confirm');L.equip=real
    assert(called==1 and f.state.setCalls==0 and f.u.noticeText and not f.u.equipDialog)
end)
test('a changed native generation cancels pending equipment without touching another instance',function()
    local f=fixture();f.u.selectedItem=f.c.items[2];W.give(f.u,f.a);W.dispatch(f.u,'config:slot:6');f.native.generation=8
    local real=L.equip;local calls=0;L.equip=function()calls=calls+1 end
    W.commit(f.u);L.equip=real;assert(calls==0 and not f.u.equipDialog and not f.b.label)
end)
test('live label editing preserves the type identity and the other identical unit',function()
    local f=fixture();W.open(f.u,f.a);f.u.editWindow.tab=3;f.u:setSearchFocus(true,'label')
    f.state.events={{type='text',text='Bär'},{type='text',text='enwache'}};f.u:searchEvents()
    assert(f.a.label=='Bärenwache' and f.a.name=='Caster' and not f.b.label and f.state.setCalls==0)
    f.state.events={{type='clear'}};f.u:searchEvents();assert(not f.a.label and M.displayName(f.a)=='Caster')
end)
test('labels roundtrip by instance and reject excessive, invalid or control input',function()
    local f=fixture();f.a.label='Bärenwache';local saved=M.encode(f.s,{});local loaded=assert(M.decode(saved,f.c,{}))
    assert(loaded.units[1].label==f.a.label and not loaded.units[2].label and loaded.units[1].name=='Caster')
    assert(M.validLabel('') and not M.validLabel(string.rep('ä',49)) and not M.validLabel('\255') and not M.validLabel('bad\nname'))
    saved.unit1.label_scope='native_commander';assert(not M.decode(saved,f.c,{}))
end)
test('unlock chooses IDs through selected base level, includes duplicates and never changes memorization',function()
    local f=fixture();f.a.baseline={known={'1:Original'}};f.a.spells={'1:Original'};local old=M.copy(f.a)
    local real=L.change;local chosen
    L.change=function(_,u,edit)local candidate=M.copy(u);local accepted,why=edit(candidate,f.native);assert(accepted,why);chosen=candidate;return true end
    assert(L.unlock(f.r,f.a,39));L.change=real
    assert(same(old,f.a) and same(chosen.spells,old.spells) and #chosen.baseline.known==3)
    assert(chosen.baseline.known[2]=='3:Same' and chosen.baseline.known[3]=='5:Same','bonus level3 must not unlock a base3 spell at selected base2')
end)
test('modded filters use provenance even for low IDs and do not guess from high IDs',function()
    local f=fixture();f.c.items[#f.c.items+1]={id=9000,name='High baseline',slot=7,origin={kind='baseline',modded=false}}
    f.c.items[#f.c.items+1]={id=2,name='Unknown source',slot=7,origin={kind='unknown',modded=false}}
    f.u.itemOrigin='modded';local items=W.items(f.u);assert(#items==2 and items[2].id==0)
    f.u.itemOrigin='unknown';items=W.items(f.u);assert(#items==1 and items[1].id==2)
    assert(C.origin({},'item',0).kind=='unknown')
    f.api.loadedContentOrigin=function(kind,id)return {id=id,kind=id==70 and 'created_by_mod' or 'baseline',modded=id==70,definedBy=id==70 and 'TestMod' or nil}end
    f.c.modSpellSchools={[39]={TestMod=true}}
    local w={spellSearch='',schoolOrigin='modded',schoolPages={},expanded={}}
    local rows=W.magicRows(f.u,f.native,w);assert(#rows==2 and rows[1].school.path==39 and rows[2].school.path==70)
end)
test('all window tabs and controls stay inside bounds at normal and larger sizes',function()
    local f=fixture();W.open(f.u,f.a)
    for _,size in ipairs({{800,600},{1420,720}})do
        f.state.w,f.state.h=size[1],size[2];local w=f.u.editWindow
        for tab=1,3 do
            w.tab=tab;f.u.buttons={};w.expanded={[39]=true,[70]=true};W.draw(f.u)
            for _,b in ipairs(f.u.buttons)do if b.configOwner=='window'then assert(b.x>=w.x and b.y>=w.y and b.x+b.w<=w.x+w.w+0.01 and b.y+b.h<=w.y+w.h+0.01)end end
        end
    end
end)
test('item Inspect returning changed native data locks editing rather than claiming success',function()
    local f=fixture();f.api.inspectTestFieldItem=function()return true,{source='native_item_card',readOnly=true}end
    f.r.check=function()return false,'unverified change',{}end;W.inspectItem(f.u,153)
    assert(f.r.blocked and f.u.noticeText:find('locked',1,true) and #f.s.units==2)
end)
print(count..' offline battlefield-window/input/identity contracts passed; native provenance, compatibility and rendering require real-game tests')
