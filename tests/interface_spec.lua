-- Focus, layout, navigation and file ownership checks only; no native game is simulated.
local cache={}
function require(name)
    if not cache[name] then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))() end
    return cache[name]
end
local M=require('sandbox.model');local C=require('sandbox.catalog');local U=require('sandbox.ui');local Report=require('sandbox.report')
assert(loadfile('tests/interface_probe.lua'))
local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
test('native ranged positives, negatives and unavailable results remain distinct',function()
    local api={get=function(key,id)
        if key=='monsterLastIndex'then return 2 elseif key=='monsterName'then return ({[0]='Archer',[1]='Spearman',[2]='Caster'})[id]
        elseif key=='monsterSprite'then return id elseif key=='monster'then return false else return -1 end
    end,spellInfo=function()end,monsterHasRanged=function(id)if id==0 then return true elseif id==1 then return false end end}
    local c=C.read(api);local ranged=C.filter(c,'','ranged')
    assert(#ranged==1 and ranged[1].id==0 and c.rangedUnknown==1 and not c.byId[1].categories.ranged and not c.byId[2].categories.ranged)
    api.monsterHasRanged=function(id)return id~=1 end;c=C.read(api);ranged=C.filter(c,'','ranged')
    assert(c.rangedUnknown==0 and #ranged==2 and #C.filter(c,'arch','ranged')==1)
end)
local function fixture()
    local state={x=200,y=200,w=800,h=600,buttons=0,focused=false,events={},prompts=0,masks={},icons={}}
    local api={get=function(key)
        if key=='screenW' then return state.w elseif key=='screenH' then return state.h
        elseif key=='uiPointerX' then return state.x elseif key=='uiPointerY' then return state.y
        elseif key=='mouseButtons' then return state.buttons elseif key=='modLastIndex' then return -1 end
        return 0
    end,readIni=function()end,observe=function()end,writeIni=function()return true end,listIni=function()return {} end,
        set=function(_,v)state.masks[#state.masks+1]=v end,
        wrap=function(site,fn)if site=='BATTLE_WAIT' then state.wait=fn end;return true end,
        testFieldPointerButtons=function()return state.buttons end,
        setTestFieldTextFocus=function(on)state.focused=on;return true end,
        takeTestFieldTextEvents=function()local e=state.events;state.events={};return {focused=state.focused,events=e}end,
        testFieldEditorCapabilities=function()return {multipleUnique=1}end,
        battleScreenToCell=function()return 6,6 end,battleUnitAt=function()return -1 end,
        ui={nameBox=function()state.prompts=state.prompts+1;return 'popup' end,
            drawRect=function()end,drawText=function()end,
            drawMonsterSprite=function(x,y,w,h,id)state.icons[#state.icons+1]={x=x,y=y,w=w,h=h,id=id};return true end}}
    local u=U.new(api);u.phase='prepare';u.scenario=M.new();u.runtime={open=true,width=30,live={},objects={}}
    u.catalog={monsters={{id=1,name='Äther',categories={}},{id=2,name='Apocalyptic Rider',categories={}},{id=3,name='Zebra',categories={}}},byId={}}
    for _,m in ipairs(u.catalog.monsters)do u.catalog.byId[m.id]=m end
    u.selected=1;u:refresh()
    return u,state,api
end
test('battlefield setup groups actions without losing navigation or recovery',function()
    local u=fixture();M.add(u.scenario,13,'Spearman',1,4,4);u.snapshot=M.copy(u.scenario)
    local rows=u:setupRows();local group,seen=nil,{}
    for _,row in ipairs(rows)do if row.section then group=row.section elseif row[1] and row[1]~=0 then assert(not seen[row[1]]);seen[row[1]]=group end end
    assert(seen[11]=='Current setup' and seen[1]=='Current setup' and seen[2]=='Current setup' and seen[15]=='Current setup')
    assert(seen[3]=='Battlefield' and seen[12]=='Battlefield' and seen[4]=='Scenarios' and seen[10]=='Scenarios' and seen[9]=='Scenarios')
    assert(seen[13]=='Tools' and seen[5]=='Tools' and seen[6]=='Tools' and seen[7]=='Tools' and seen[999])
    u.runtime.blocked=true;rows=u:setupRows();seen={};for _,row in ipairs(rows)do if row[1]then seen[row[1]]=true end end
    assert(seen[14] and seen[13] and seen[999] and not seen[3] and not seen[12] and not seen[11] and not seen[1] and not seen[2] and not seen[15])
end)
test('native menu balances sections and keeps navigation in the final button row',function()
    local u,_,api=fixture();local depth,tail,headings,back=0,false,0,false
    api.ui.screenBegin=function()end;api.ui.screenWidth=function()end
    api.ui.sectionBegin=function()assert(not tail and depth==0);depth=1;headings=headings+1 end
    api.ui.sectionEnd=function()assert(depth==1);depth=0 end
    api.ui.buttonRow=function()assert(depth==0);tail=true end
    api.ui.text=function(id)if id==999 then assert(tail and depth==0);back=true else assert(depth==1)end end
    api.ui.bindEscape=function(id)assert(id==999)end;api.ui.wait=function()return 999 end
    assert(u:menu('Sandbox - battlefield',u:setupRows())==999 and depth==0 and headings==4 and back)
end)
test('missing active mod is named in Load refusal and leaves the current scenario/native field unchanged',function()
    local u,_,api=fixture();local original=u.scenario;u.catalog.mods={'CoE5SE'};u.catalog.terrainById={[0]={name='Plain'}}
    local saved=M.encode(M.new(),{'CoE5SE','CrabCult'})
    api.listIni=function()return {'mod-scenario'}end;api.readIni=function()return saved end
    u.menu=function()return 1 end;u.runtime.snapshot=function()return {}end
    u.runtime.build=function()error('missing-mod load must not rebuild')end
    local notice;u.notice=function(_,text)notice=text end;u:load()
    assert(u.scenario==original and notice:find('CrabCult') and notice:find('Current setup kept') and u.diag.lastError.message:find('CrabCult'))
end)
test('main search uses captured UTF8 inline events and never a popup',function()
    local u,s=fixture();u:dispatch('search');assert(u.searchFocused and s.focused and s.prompts==0)
    s.events={{type='text',text='ÄT'}};assert(u:searchEvents());assert(u.search=='ÄT' and #u.filtered==1 and u.filtered[1].id==1)
    s.events={{type='backspace'}};u:searchEvents();assert(u.search=='Ä')
    s.events={{type='backspace'}};u:searchEvents();assert(u.search=='' and #u.filtered==3)
    s.events={{type='text',text='not found'}};u:searchEvents();assert(#u.filtered==0 and u.page==1)
    u:dispatch('searchclear');assert(u.search=='' and u.searchFocused and #u.filtered==3)
    s.events={{type='text',text='a\n\1'}};u:searchEvents();assert(u.search=='a')
    s.events={{type='cancel'}};u:searchEvents();assert(not u.searchFocused and not s.focused and s.prompts==0)
end)
test('UTF8 case folding/backspace/truncation retain complete German codepoints',function()
    assert(C.fold('ÄÖÜẞ')==C.fold('äöüß'))
    assert(C.backspace('Fü')=='F' and C.backspace('😀')=='')
    assert(C.textLimit('ÄÖÜ',2,'...')=='ÄÖ...')
    assert(C.textLimit('ÄÖ',2,'...')=='ÄÖ')
    local u=fixture();u.search='a';u.category=1;u:refresh()
    assert(u.filtered[1].id==2 and u.filtered[2].id==3,'filter changed source alphabetic order')
end)
test('search focus owns held pointer and blur click cannot place',function()
    local u,s=fixture();u.native=true;u:dispatch('search')
    u.lastMouse=2;assert(u:input(2) and not u.pending,'typing allowed held-button placement')
    u.lastMouse=0;s.x=200;s.y=200;assert(u:input(2));assert(not u.searchFocused and not u.pending and u.dragBlocked)
    u:input(2);assert(not u.pending,'blur held tail placed')
    u:input(0);u:input(2);assert(u.pending and u.pending.place,'a new intentional gesture was lost')
end)
test('submit consumes its native wait result and releases focus for next frame',function()
    local u,s=fixture();u:dispatch('search');s.events={{type='submit'}}
    assert(s.wait(function()return 70 end)==0 and not u.searchFocused)
    assert(s.wait(function()return 70 end)==70)
    u:dispatch('search');u.api.takeTestFieldTextEvents=function()return {focused=true,overflow=true,events={}}end
    u:searchEvents();assert(not u.searchFocused and u.message:find('overflow'))
end)
test('missing input service explains limitation and never opens search popup',function()
    local u,s=fixture();u.api.setTestFieldTextFocus=nil;u.api.takeTestFieldTextEvents=nil
    u:dispatch('search');assert(not u.searchFocused and s.prompts==0 and u.message:find('requires'))
end)
test('five fitted icon rectangles and controls fit both observed UI sizes',function()
    for _,width in ipairs({800,1136})do
        local u,s=fixture();s.w=width
        for i=4,5 do local m={id=i,name='Apocalyptic Rider variant '..i,categories={}};u.catalog.monsters[#u.catalog.monsters+1]=m;u.catalog.byId[i]=m end
        u:refresh();u:draw();assert(#s.icons==5)
        for i,icon in ipairs(s.icons)do
            assert(icon.w==32 and icon.h==28 and icon.x>=width-300 and icon.x+icon.w<width)
            if i>1 then assert(icon.y+icon.h<s.icons[i-1].y,'icon regions overlap rows')end
        end
        for _,b in ipairs(u.buttons)do assert(b.x>=0 and b.y>=0 and b.x+b.w<=width and b.y+b.h<=600,'button outside UI')end
    end
end)
test('multiple unique toggle commits a candidate only after verified rebuild',function()
    local u=fixture();local before=u.scenario;before.allowMultipleUnique=false
    u.runtime.build=function(_,candidate)assert(candidate~=before and candidate.allowMultipleUnique);return false,'rebuild refused'end
    u:toggleMultipleUnique();assert(u.scenario==before and not before.allowMultipleUnique)
    u.noticeText=nil;u.runtime.build=function(_,candidate)assert(candidate~=before);return true end
    assert(u:toggleMultipleUnique() and u.scenario~=before and u.scenario.allowMultipleUnique and not before.allowMultipleUnique)
end)
test('closed-field duplicate unique setup refuses Off before mutating the flag',function()
    local u=fixture();u.runtime.open=false;u.scenario.allowMultipleUnique=true
    u.scenario.units={{id=1,monster=207},{id=2,monster=207}}
    local before=u.scenario;local get=u.api.get
    u.api.get=function(key,...)if key=='monsterAbility'then return 1 end;return get(key,...)end
    u.notice=function(_,text)assert(text:find('Remove the extra copies'))end
    assert(not u:toggleMultipleUnique() and u.scenario==before and before.allowMultipleUnique)
end)
test('multiple unique scenario option roundtrips and legacy files default Off',function()
    local s=M.new();assert(s.allowMultipleUnique==false);s.allowMultipleUnique=true
    local unit=M.add(s,207,'God',1,5,3);unit.baseline={known={'1:Spell'}};unit.spells={'1:Spell'};unit.items={'Item'}
    local catalog={byId={[207]={name='God'}},terrainById={[0]={name='Plain'}},itemNames={Item=1},spellKeys={['1:Spell']=1}}
    local encoded=M.encode(s,{});local loaded,why=M.decode(encoded,catalog,{});assert(loaded,why)
    assert(loaded.allowMultipleUnique and loaded.units[1].baseline.known[1]=='1:Spell' and loaded.units[1].items[1]=='Item')
    encoded.scenario.allow_multiple_unique=nil;loaded,why=M.decode(encoded,catalog,{});assert(loaded,why);assert(not loaded.allowMultipleUnique)
    encoded.scenario.allow_multiple_unique=2;assert(not M.decode(encoded,catalog,{}),'invalid mode accepted')
end)
test('report returns explicit navigation actions and clears native-menu ownership',function()
    local u=fixture();u.report.result={summary={winner=0,final_round=1,elapsed_wall_ms=0},teamA={start=1,losses=0,survivors=1},teamB={start=1,losses=1,survivors=0},types={}}
    for id,action in pairs({[999]='restore',[4]='rematch',[5]='controls',[6]='main'})do
        u.menu=function(_,_,rows)
            local found=false;for _,r in ipairs(rows)do if r[1]==999 and r[2]:find('Back to Sandbox')then found=true end end
            assert(found);return id
        end
        assert(u:results()==action and not u.inNativeMenu)
    end
end)
test('many rematches are iterative and restoration failure never starts a fight',function()
    local u=fixture();local reports,fights,resets=0,0,0
    u.results=function()reports=reports+1;return reports<=120 and 'rematch' or 'controls'end
    u.reset=function(_,rematch)assert(rematch);resets=resets+1;return true end
    u.fight=function()fights=fights+1;return true end
    assert(u:postBattle() and reports==121 and fights==120 and resets==120)
    u.reset=function()return false end;u:postBattle('rematch');assert(fights==120)
    assert(u:postBattle('main')==false and u.exitToMain)
end)
test('Main menu propagates through setup and exact snapshot restoration keeps report',function()
    local u=fixture();local original=u.scenario;u.snapshot=M.copy(original);u.snapshot.units={{id=1,baseline={known={'1:Spell'}},spells={'1:Spell'},items={'Item'}}}
    local report={kept=true};u.report.result=report
    u.runtime.build=function(_,candidate)assert(candidate~=u.snapshot and candidate.units[1].spells[1]=='1:Spell');return true end
    assert(u:reset(false) and u.report.result==report and u.snapshot.units[1].items[1]=='Item')
    u.ensureCatalog=function()end;u.catalog.testFieldTerrains={};u.catalog.terrainById={}
    local calls=0;u.menu=function()calls=calls+1;assert(calls==1);return 3 end
    u.prepare=function()u.exitToMain=true end;u:setup();assert(calls==1 and not u.exitToMain)
end)
test('unverified close cancels silent Main menu exit and explains recovery',function()
    local u=fixture();local original=u.scenario;local notice
    u.runtime.build=function()return true end
    u.runtime.close=function()u.runtime.open=false;return false,'injected_cleanup_unverified'end
    u.api.drawTestField=function()u.pending='main'end
    u.notice=function(_,text)notice=text end
    u:prepare()
    assert(not u.exitToMain and u.scenario==original and u.phase=='menu')
    assert(notice and notice:find('restart the isolated game') and notice:find('injected_cleanup_unverified'))
end)
test('automatic report archives preserve legacy and every prior battle file',function()
    local files={['last-battle']={summary={old=1}},['battle-session-1']={previous=1}}
    local api={observe=function()end,readIni=function(name)if name=='launcher-context'then return {environment={session='session'}}end;return files[name]end,
        listIni=function()local out={};for name in pairs(files)do out[#out+1]=name end;return out end,
        writeIni=function(name,data)if name~='last-battle'then assert(not files[name],'archive overwritten')end;files[name]=data;return true end}
    local r=Report.new(api);r.result={summary={battle=1},types={}}
    local first,warning=r:archive();assert(first=='battle-session-2' and not warning and files['battle-previous-session-1'].summary.old==1)
    r.result={summary={battle=2},types={}};local second=r:archive()
    assert(second=='battle-session-3' and files[first].summary.battle==1 and files[second].summary.battle==2 and files['battle-session-1'].previous==1)
    local old=files['last-battle'];api.writeIni=function()return false end
    assert(not r:archive() and files['last-battle']==old,'archive failure overwrote last report')
end)
print(count..' offline interface checks passed; no native input, sprite rendering or combat was simulated')
