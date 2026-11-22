-- Opt-in native scenario regression. Each batch places different exact IDs on
-- a real field. Run plain1 through plain8 or castle1 through castle8.
local api=coe5
local M=require('sandbox.model')
local U=require('sandbox.ui')
local Objects=require('sandbox.battlefield_objects')
local request=assert(api.readIni('request')).run.only
local map,batch=request:match('^([a-z]+)(%d+)$')
batch=tonumber(batch)
if not batch or (map~='plain' and map~='castle') then return end
local ran,fighting,editor=false,false,nil
local out={environment=api.readIni('launcher-context').environment}
local renderList,rendered

api.wrap('BATTLE_DRAW',function(next,...)
    local result=next(...)
    if renderList then
        rendered={}
        for i,monster in ipairs(renderList) do
            rendered[monster]=api.ui.drawMonsterSprite(5+(i-1)*16,5,16,16,monster)
        end
        renderList=nil
    end
    return result
end,-200)

api.wrap('BATTLE_WAIT',function(next,...)
    local result=next(...)
    if fighting and result==0 and api.get('battleDelay')>2 then return 1 end
    return result
end)

local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end

api.wrap('MAIN_MENU_WAIT',function(next,...)
    local result=next(...)
    if ran then return result end
    ran=true
    local ok,reason=xpcall(function()
        editor=U.new(api)
        editor:ensureCatalog()
        editor.notice=function(self,message)self.message=message end
        editor.results=function()return 'controls' end
        local runtime=editor.runtime
        local s=M.new()
        s.terrain=map=='castle' and 22 or 0
        s.minimumWidth,s.size=50,'Minimum width'
        assert(runtime:build(s,true))
        editor.phase,editor.native='prepare',true
        local list={}
        for _,row in ipairs(assert(api.testFieldSceneryTypes()).types) do
            local entry=editor.catalog.byId[row.monster]
            if Objects.neutralBuilding(entry) then list[#list+1]=entry end
        end
        assert(#list==142,'Incomplete verified building catalog')
        local used={}
        local function pick(x0,x1,y0,y1)
            for x=x0,x1 do for y=y0,y1 do
                local key=x..':'..y
                if not used[key] and api.battleUnitAt(x,y)<0 and api.battleObjectAt(x,y)<0 then
                    used[key]=true;return x,y
                end
            end end
            error('No free fixture cell')
        end
        local spear=assert(api.findMonster('Spearman'))
        local ax,ay=pick(10,14,9,10)
        local bx,by=pick(map=='castle' and 30 or 16,36,9,10)
        M.add(s,spear,'Spearman',1,ax,ay)
        M.add(s,spear,'Spearman',2,bx,by)
        local expected={}
        local shared,first=0,(batch-1)*18+1
        for i=first,math.min(first+17,#list) do
            local entry=list[i]
            local x,y=pick(6,18,2,7)
            local object=M.add(s,entry.id,entry.name,3,x,y)
            object.scenery=true
            expected[object.id]=entry.id
            if Objects.neutralStanding(entry) then
                M.add(s,spear,'Spearman',i%2+1,x,y)
                shared=shared+1
            end
        end
        assert(#s.units>2)
        assert(runtime:build(s))
        editor.scenario=s
        renderList={}
        for i=first,math.min(first+17,#list) do renderList[#renderList+1]=list[i].id end
        api.drawTestField()
        assert(rendered,'Native rendering did not run')
        for _,id in pairs(expected) do assert(rendered[id],'Renderer refused ID '..id) end
        local function verify()
            local good,state=runtime:ready(editor.scenario);assert(good,state)
            for _,u in ipairs(editor.scenario.units) do
                local id=runtime.live[u.id]
                if u.scenery then
                    local row=assert(state.rows[id])
                    assert(row.monster==expected[u.id] and row.owner==31 and row.anchorLayer=='object')
                    assert(api.battleObjectAt(u.x,u.y)==id)
                else assert(api.battleUnitAt(u.x,u.y)==id) end
            end
        end
        verify()
        local before=M.encode(s,editor.catalog.mods)
        local file='building-variants-'..request..'-'..api.get('ticksMs')
        editor.prompt=function()return file end
        editor:save()
        assert(api.readIni(file),editor.message)
        editor.menu=function(_,_,rows)for _,row in ipairs(rows) do if row[2]==file then return row[1] end end;return 999 end
        editor:load()
        verify()
        assert(equal(before,M.encode(editor.scenario,editor.catalog.mods)))
        api.drawTestField()
        local function finishBattle(rematch)
            fighting=true
            local complete=rematch and editor:postBattle('rematch') or editor:fight()
            fighting=false
            assert(complete and editor.phase=='after',editor.message)
            local report=editor.report.result
            assert(report.neutral.start==0 and report.summary.winner~=31)
            assert(editor:postBattle('restore'))
            verify()
            assert(equal(before,M.encode(editor.scenario,editor.catalog.mods)))
            return report.summary.winner
        end
        local winner=finishBattle(false)
        assert(editor:reset(false))
        local rematchWinner=finishBattle(true)
        out.workflow={status='PASS',terrain=s.terrain,first=first,last=math.min(first+17,#list),
            shared=shared,winner=winner,rematch_winner=rematchWinner}
        for model,id in pairs(expected) do out['variant'..id]={status='PASS',model=model,rendered=1} end
    end,tostring)
    if editor and editor.runtime.open then
        local closed,detail=editor.runtime:close()
        if not closed then ok=false;reason=reason or detail end
    end
    out.complete={status=ok and 'PASS' or 'FAIL',detail=tostring(reason or 'Exact scenario round trip and battles verified')}
    assert(api.writeIni('results',out))
    return result
end,-100)
