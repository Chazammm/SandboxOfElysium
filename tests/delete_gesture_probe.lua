-- Opt-in native engine test. The driver supplies input samples to the production editor.
local api=coe5
local U=require('sandbox.ui')
local M=require('sandbox.model')
local out={environment=api.readIni('launcher-context').environment}
local started,fighting=false,false
api.wrap('BATTLE_WAIT',function(next,...)
    local v=next(...)
    if fighting and v==0 and api.get('battleDelay')>2 then return 1 end
    return v
end)
api.wrap('MAIN_MENU_WAIT',function(next,...)
    local result=next(...)
    if started then return result end
    started=true
    local ui,r
    local ok,why=xpcall(function()
        ui=U.new(api);ui:ensureCatalog()
        r=ui.runtime;ui.scenario=M.new()
        ui.scenario.minimumWidth=32;ui.scenario.size='Minimum width'
        assert(r:build(ui.scenario))
        ui.phase,ui.native='prepare',true
        ui:prepareLog();api.drawTestField()
        ui.notice=function(self,message) self.message=message end
        ui.results=function()return 'controls' end
        local cursorX,cursorY
        ui.api=setmetatable({get=function(key,...)
            if key=='uiPointerX' then return cursorX end
            if key=='uiPointerY' then return cursorY end
            return api.get(key,...)
        end},{__index=api})
        local spear=assert(api.findMonster('Spearman'))
        local large
        for _,name in ipairs({'Hunter of Gods','Strange Seraph','God'}) do
            local id=api.findMonster(name)
            local f=id and id>=0 and api.testFieldFootprint(id)
            if f and f.width>1 then large=id;break end
        end
        assert(large,'No large fixture')
        local function add(type,team,x,y)
            local added,scene,unit=r:add(ui.scenario,type,team,x,y)
            assert(added,scene);ui.scenario=scene
            return unit,r.live[unit.id]
        end
        local retained=add(spear,1,5,10)
        assert(r:setNativeName(retained,'Kept for recovery'))
        add(spear,2,16,10)
        local scenery,object=add(1395,3,5,8)
        local shared,sharedNative=add(spear,1,5,8)
        local wide,wideNative=add(large,1,8,8)
        local target,targetNative=add(spear,2,13,8)
        assert(api.battleUnitAt(5,8)==sharedNative and api.battleObjectAt(5,8)==object)
        ui.native=false
        ui.grid={x=0,y=50,cell=25,width=r.width}
        local function sample(buttons,x,y)
            if x then
                cursorX,cursorY=25*x+12,50+25*y+12
                local cx,cy=ui:pointerCell()
                assert(cx==x and cy==y,('Viewport sample expected %d,%d got %s,%s'):format(x,y,tostring(cx),tostring(cy)))
            else
                cursorX,cursorY=api.get('screenW')-20,40
            end
            ui:input(buttons)
            local action=ui.pending;ui.pending=nil
            if action then assert(ui:dispatch(action)) end
        end
        -- Hold actual CoE5SE key state, with the pointer projected from real battlefield cells.
        api.set('keyHeld',224,true);assert(api.get('keyHeld',224))
        sample(2,5,8);assert(r.live[shared.id]==sharedNative and not ui.context)
        sample(0,5,8);ui:dispatch('ctrldelete');sample(0,5,8)
        sample(2);sample(2,5,8);sample(0,5,8);assert(r.live[shared.id]==sharedNative and not ui.context)
        sample(2,5,8);assert(r.live[shared.id]==nil and api.battleObjectAt(5,8)==object and api.battleUnitAt(5,8)<0)
        sample(0,5,8)
        api.set('keyHeld',224,false);api.set('keyHeld',228,true);assert(api.get('keyHeld',228))
        assert(api.battleUnitAt(9,8)==wideNative,'Secondary cell must resolve to its multi-cell actor')
        sample(2,9,8);sample(2,14,8);sample(2,9,8);sample(0,9,8)
        assert(r.live[wide.id]==nil and r.live[target.id]==nil and api.battleUnitAt(9,8)<0 and not ui.context)
        assert(r:retirementVerified(sharedNative) and r:retirementVerified(wideNative) and r:retirementVerified(targetNative))
        api.set('keyHeld',228,false)
        ui.selected=spear
        sample(2,5,10);assert(ui.context and ui.context.unit.id==retained.id)
        sample(0,5,10);ui.context=nil
        sample(2,9,8);sample(0,9,8)
        assert(api.battleUnitAt(9,8)>=0 and M.count(ui.scenario,1)==2 and r.live[scenery.id]==object)
        assert(r:ready(ui.scenario))
        ui.prompt=function()return 'feedback-drag-fixture'end
        ui:save();assert(ui.message=='Scenario saved: feedback-drag-fixture',ui.message)
        local saved=assert(api.readIni('feedback-drag-fixture'))
        assert(saved.scenario.count=='4')
        local menu=ui.menu;ui.menu=function()return 1 end
        ui:load();ui.menu=menu
        assert(r:ready(ui.scenario))
        fighting=true;assert(ui:fight(),ui.message);fighting=false
        assert(ui.phase=='after' and ui.report.result.summary.final_round>0)
        assert(ui:postBattle('restore') and r:ready(ui.scenario))
        assert(ui:reset(false) and r:ready(ui.scenario))
        fighting=true;assert(ui:postBattle('rematch') and ui.phase=='after');fighting=false
        assert(ui:postBattle('restore') and r:ready(ui.scenario))
        local names=M.encode(ui.scenario,ui.catalog.mods)
        assert(names.unit1.native_name_hex==saved.unit1.native_name_hex and tostring(names.scenario.count)==saved.scenario.count)
        assert(api.battleObjectAt(5,8)>=0 and api.battleUnitAt(5,8)<0)
        out.deletion={left_ctrl_api=1,right_ctrl_api=1,off_refused=1,ui_origin_refused=1,shared_preserved=1,
            single_retired=1,drag_retired=2,normal_context=1,normal_place=1,battle_restore=1,reset=1,rematch=1,save_load=1}
    end,tostring)
    api.set('keyHeld',224,false);api.set('keyHeld',228,false)
    if r and r.open then local clean,reason=r:close();if not clean then ok=false;why=reason end end
    out.complete={status=ok and 'PASS' or 'FAIL',detail=tostring(why or 'Native editor deletion and recovery')}
    assert(api.writeIni('results',out))
    return result
end)
