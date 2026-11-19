-- Opt-in isolated native-card verification. Cards are closed through the real
-- game UI. No automated substitute for the native modal is installed.
if coe5==nil then print('PARSE ONLY: native CoE5 API absent');return end
local api=coe5
local M=require('sandbox.model');local U=require('sandbox.ui');local L=require('sandbox.loadout')
local request=api.readIni('request');if not request or not request.run then return end
local started,ui,fighting=false,nil,false
local prepareView
local out={environment=(api.readIni('launcher-context')or{}).environment}
local function equal(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not equal(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function flat(t)local row={};for k,v in pairs(t or{})do if type(v)=='boolean'then row[k]=v and 1 or 0 elseif type(v)=='string'or type(v)=='number'then row[k]=v end end;return row end
local function write()assert(api.writeIni('results',out))end
local function healthy()
    local ok,why=ui.runtime:ready(ui.scenario);assert(ok,why)
    local state=assert(api.testFieldState());assert(state.complete and #state.issues==0);return state
end
api.wrap('BATTLE_WAIT',function(next,...)
    local value=next(...)
    if prepareView then
        local apply=prepareView;prepareView=nil;apply()
    end
    if fighting and value==0 and(api.get('battleDelay')or 0)>2 then return 1 end
    return value
end)
api.wrap('MAIN_MENU_WAIT',function(next,...)
    local value=next(...);if started then return value end;started=true
    local ok,why=xpcall(function()
        assert(type(api.inspectTestFieldMonster)=='function','Native monster Inspect API missing')
        ui=U.new(api);ui:ensureCatalog();ui.notice=function(self,text)self.message=text end
        local caster=assert(api.findMonster('Pyromancer'));local unique=assert(api.findMonster('Arch Devil'))
        local s=M.new();local a=M.add(s,13,ui.catalog.byId[13].name,1,8,9)
        local b=M.add(s,caster,ui.catalog.byId[caster].name,2,24,9)
        local devil=M.add(s,unique,ui.catalog.byId[unique].name,1,12,5)
        ui.scenario=s;assert(ui.runtime:build(s,true));ui.phase='prepare';ui.native=true
        assert(ui.runtime:setNativeName(a,'Existing Guard'));assert(ui.runtime:setNativeName(devil,'Existing Unique'))
        assert(api.giveItem(ui.runtime.live[a.id],'Amulet of Anti Magic'))
        assert(L.capture(ui.runtime,a,assert(L.read(ui.runtime,ui.runtime.live[a.id]))))
        assert(#b.spells>0,'Caster has no initial memorized spell to customize')
        local removedSpell=b.spells[1];assert(ui.runtime:memorize(b,removedSpell,false))
        local accepted,observed=ui.runtime:check(s);assert(accepted,observed);ui.runtime:accept(s,observed)
        out.existing_configuration={name_a=a.nativeName,name_unique=devil.nativeName,held_item='Amulet of Anti Magic',explicitly_deselected_spell=removedSpell}
        healthy();api.drawTestField()
        local width,height=api.get('screenW'),api.get('screenH')
        prepareView=function()
            assert(api.setTestFieldViewport{x=10,y=40,width=width-320,height=height-80})
            assert(api.fitTestFieldViewport())
            assert(api.setTestFieldZoom(1.25))
            assert(api.panTestFieldViewport(-100,-30))
        end
        api.drawTestField();assert(not prepareView)
        api.drawTestField()
        local viewport=assert(api.testFieldViewport())
        assert(viewport.zoom>1 and #healthy().units==3)
        for _,case in ipairs({{'bad_monster',-1,nil},{'unexpected_options',13,{}}})do
            local before=healthy();local life=api.testFieldLifecycle();local last=api.get('unitLastIndex')
            local shown,reason,detail=api.inspectTestFieldMonster(case[2],case[3])
            assert(not shown and reason==case[1]and detail.verified and detail.cleanupVerified and not detail.instanceCreated)
            assert(equal(before,healthy())and equal(life,api.testFieldLifecycle())and last==api.get('unitLastIndex'))
            out['refused_'..case[1]]={status='PASS',reason=reason,no_instance_created=1,field_unchanged=1}
        end
        local mod
        for _,m in ipairs(ui.catalog.monsters)do if m.definitionMod=='CrabCult'then mod=m;break end end
        assert(mod,'This opt-in run requires the separately installed CrabCult; no content is bundled')
        local selected=ui.selected
        local cases={{'normal',13},{'caster',caster},{'large',207},{'unique1',unique},{'unique2',unique},{'unique3',unique},{'modded',mod.id}}
        if request.run.only=='postview'then cases={{'normal',13}}end
        local uniqueViews=0
        for _,case in ipairs(cases)do
            local name,id=case[1],case[2]
            local before=healthy();local encoded=M.encode(s,ui.catalog.mods);local life=api.testFieldLifecycle();local last=api.get('unitLastIndex')
            out.progress={stage='native_card_'..name,monster=id,name=ui.catalog.byId[id].name,action='Close the genuine native card normally to continue'};write()
            local original=api.inspectTestFieldMonster;local detail
            local proxy=setmetatable({inspectTestFieldMonster=function(monster)local shown,result,extra=original(monster);detail=type(result)=='table'and result or extra;return shown,result,extra end},{__index=api})
            ui.api=proxy
            local accepted=ui:viewType(id);ui.api=api
            assert(accepted,ui.message)
            assert(type(detail)=='table'and detail.verified and detail.cleanupVerified and detail.monster==id and detail.source=='native_unit_card')
            assert(detail.instanceCreated and detail.temporaryInstance and not detail.startingItemsIncluded and not detail.futureInstanceSpellsVerified)
            assert(equal(encoded,M.encode(s,ui.catalog.mods))and equal(before,healthy()),'Native preview changed the scenario or field')
            assert(equal(life,api.testFieldLifecycle())and last==api.get('unitLastIndex'),'Native preview consumed lifecycle/allocator state')
            assert(equal(viewport,api.testFieldViewport()),'Native card changed the fitted and panned editor view')
            assert(ui.selected==selected and not ui.runtime.blocked and #s.units==3)
            out[name]=flat(detail);out[name].status='PASS';out[name].name=ui.catalog.byId[id].name
            if name=='modded'then out[name].definition_mod=mod.definitionMod end
            if name:match('^unique%d')then uniqueViews=uniqueViews+1 end
            write();api.drawTestField()
        end
        local removed,new=ui.runtime:remove(s,devil);assert(removed,new);s=new;ui.scenario=s;healthy()
        local x,y=devil.x,devil.y;local added,replaced,unit=ui.runtime:add(s,unique,1,x,y);assert(added,replaced);s=replaced;ui.scenario=s;healthy()
        assert(unit.monster==unique and #s.units==3,'Unique availability was consumed by viewing')
        out.unique_availability={status='PASS',repeated_views=uniqueViews,existing_unique_unchanged=1,delete_then_readd=1}
        if request.run.only=='postview'or request.run.only=='all_postview'then
            local frozen=M.encode(s,ui.catalog.mods);assert(api.writeIni('native-view-kept-setup',frozen))
            local loaded,reason=M.decode(api.readIni('native-view-kept-setup'),ui.catalog,ui.catalog.mods);assert(loaded,reason)
            assert(ui.runtime:build(loaded,false));ui.scenario=loaded;s=loaded;healthy()
            assert(equal(frozen,M.encode(s,ui.catalog.mods)))
            for cycle=1,2 do
                fighting=true;assert(ui:fight(),ui.message);fighting=false
                out['battle_after_view'..cycle]={round=api.get('battleRound'),winner=api.get('battleWinner'),scope='Natural battle after preview hook installation'}
                assert((api.get('battleRound')or 0)>0 and(api.get('battleWinner')==0 or api.get('battleWinner')==24))
                assert(ui:reset(cycle>1),ui.message);s=ui.scenario;healthy()
                assert(equal(frozen,M.encode(s,ui.catalog.mods)),'Save/Load or post-view battle Reset/Rematch changed supported setup')
            end
            out.postview_transitions={status='PASS',save_load=1,reset=1,rematch=1,supported_configuration_preserved=1}
        end
        assert(ui.runtime:close());local life=assert(api.testFieldLifecycle());assert(life.complete and not life.open and #life.issues==0)
        out.cleanup={status='PASS',complete=1,open=0,issues=0}
    end,tostring)
    if not ok and ui and ui.runtime.open then pcall(function()ui.runtime:close()end)end
    out.progress={stage='complete'};out.complete={status=ok and'PASS'or'FAIL',detail=tostring(why or'Genuine native cards closed through the game; ordinary field and scratch cleanup verified')};write()
    return value
end,-100)
