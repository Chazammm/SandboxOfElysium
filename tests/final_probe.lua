-- Explicit isolated native regression. This does not simulate battle outcomes.
-- Request: mode=final; optional commander/enemy/terrain/multiple_unique;
-- require_created_in_fight=1 requires a surviving newly-created combat actor.
local api=coe5
local request=api.readIni('request')
if not request or not request.run or request.run.mode~='final' then return end
local q=request.run
local out={environment={scope='actual isolated CoE5 process',view='post_aftermath_before_upkeep unit/cell snapshot; not full effects'}}
local function save()assert(api.writeIni('final-results',out))end
local active=false
local speedRequests=0
api.wrap('BATTLE_WAIT',function(next,b,m)
    local id=next(b,m)
    if active and id==0 and (api.get('battleDelay') or 0)>2 then speedRequests=speedRequests+1;return 1 end
    return id
end)
local function same(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local function run(name,fn)
    local ok,why=xpcall(fn,function(e)return tostring(e)end)
    out[name]={status=ok and 'PASS' or 'FAIL',detail=ok and 'actual native calls' or why}
    local closed,reason=api.closeTestField();assert(closed,tostring(reason));save()
    assert(ok,why)
end
assert(type(api.testFieldFinalState)=='function' and type(api.inspectTestFieldFinalUnit)=='function','final API unavailable')
run('capture_and_final_readonly_cleanup',function()
    local spec={commander=tonumber(q.commander) or 13,enemies={{tonumber(q.enemy) or 953,1}}}
    if q.terrain then spec.terrain=assert(tonumber(q.terrain))end
    if tonumber(q.multiple_unique)==1 then spec.allowMultipleUnique=true end
    if q.friend then spec.friends={{assert(tonumber(q.friend)),1}}end
    local opened,ids=api.openTestField(spec);assert(opened,tostring(ids))
    local before=api.testFieldState();assert(before and before.complete and #before.issues==0)
    local initial={};for _,u in ipairs(before.units)do initial[u.unit]=u.generation end
    active=true;local accepted,why=api.fightTestField();active=false
    assert(accepted~=false,tostring(why))
    local final,reason=api.testFieldFinalState();assert(final,tostring(reason))
    assert(final.captured and final.complete and not final.sceneComplete and #final.issues==0,'incomplete final unit/cell capture')
    assert(final.source=='post_aftermath_before_upkeep' and final.round>0 and final.winner>=0)
    assert(#final.grid==final.width*final.height,'grid coverage truncated')
    local nativeIds,visible,dead,offfield,created,removed,terrain={},0,0,0,0,0,0
    for _,u in ipairs(final.units)do
        assert(not nativeIds[u.unit] and u.generation>0);nativeIds[u.unit]=u.generation
        assert(type(u.hp)=='number' and type(u.currentHP)=='number' and u.kind)
        if u.kind=='terrain' then terrain=terrain+1 end
        if u.alive and u.anchorCount==1 then
            visible=visible+1;assert(#u.anchors==1 and u.width>=1 and u.height>=1)
            if u.kind=='actor' then
                assert(#u.occupied==u.width*u.height,'native hit footprint missing')
                local cells={};for _,p in ipairs(u.occupied)do cells[p.x..','..p.y]=true end
                for x=u.anchors[1].x,u.anchors[1].x+u.width-1 do for y=u.anchors[1].y,u.anchors[1].y+u.height-1 do assert(cells[x..','..y])end end
            end
        elseif not u.alive then dead=dead+1 else offfield=offfield+1;assert(#u.anchors==0,'off-field position guessed')end
        if u.kind=='actor' and u.createdDuringFight and u.alive then created=created+1 end
        if u.alive and not u.currentAlive then removed=removed+1;assert(not u.inspectable and u.inspectReason)end
        if u.identityMatches then assert(api.get('unitHp',u.unit)==u.currentHP,'current HP differs from readback')end
        out['unit'..u.unit]={unit=u.unit,generation=u.generation,kind=u.kind,monster=u.monster,owner=u.owner,team=u.team,
            hp=u.hp,current_hp=u.currentHP,alive=u.alive and 1 or 0,current_alive=u.currentAlive and 1 or 0,
            created_during_fight=u.createdDuringFight and 1 or 0,created_monster=u.createdMonster,created_owner=u.createdOwner,
            status=u.status,anchor_count=u.anchorCount,width=u.width,height=u.height,inspectable=u.inspectable and 1 or 0,
            inspect_reason=u.inspectReason or 'available',x=u.anchors[1] and u.anchors[1].x or 'none',y=u.anchors[1] and u.anchors[1].y or 'none'}
    end
    assert(visible>0,'fixture has no visible final survivor')
    if tonumber(q.require_created_in_fight)==1 then assert(created>0,'required surviving combat summon was not observed')end
    if tonumber(q.require_terrain)==1 then assert(terrain>0,'required terrain object was not observed')end
    local target
    for _,u in ipairs(final.units)do if u.kind=='actor' and u.alive and u.anchorCount==1 then target=u;break end end
    assert(target,'no actor for final read-only refusal checks')
    local moved,mwhy=api.moveTestFieldUnit(target.unit,1,1);assert(not moved and mwhy=='final_read_only')
    local deleted,dwhy=api.removeTestFieldUnit(target.unit);assert(not deleted and dwhy=='final_read_only')
    local added,awhy=api.addTestFieldUnits('friends',{{13,1}});assert(not added and awhy=='final_read_only')
    local fought,fwhy=api.fightTestField();assert(not fought and fwhy=='final_read_only')
    assert(same(final,api.testFieldFinalState()),'a refused edit changed the final snapshot or current actor')
    out.capture={source=final.source,complete=1,scene_complete=0,width=final.width,height=final.height,round=final.round,winner=final.winner,
        actors_and_objects=#final.units,visible=visible,dead=dead,off_field=offfield,created_alive=created,removed_after_capture=removed,
        terrain=terrain,speed_requests=speedRequests,readonly_refusals=4,native_inspect_ui='separate visible test required'}
    local closed,cwhy=api.closeTestField();assert(closed,tostring(cwhy))
    local lifecycle=api.testFieldLifecycle();assert(lifecycle.complete and #lifecycle.issues==0 and not lifecycle.open)
    for id in pairs(nativeIds)do assert(api.get('unitHp',id)<=0,'owned final actor/object leaked after close')end
    assert(not api.testFieldFinalState(),'closed field retained a final handle')
    local reopened,second=api.openTestField(spec);assert(reopened,tostring(second))
    local state=api.testFieldState();assert(state.complete and #state.issues==0 and #state.units>0)
    assert(not api.testFieldFinalState(),'old final capture leaked into new field')
    out.cleanup={complete=1,reopened=1,old_snapshot_unavailable=1}
end)
save()
