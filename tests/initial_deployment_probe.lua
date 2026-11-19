-- Opt-in native initial-intake transaction checks. Run only through the muted,
-- isolated QA launcher. This file never loads or overwrites a user scenario.
-- Native byte preservation is the API's exact internal snapshot contract;
-- independent Lua readback covers identities, grids and supported unit state.
if coe5==nil then print('PARSE ONLY: native CoE5 API absent; no game checks performed');return end
local api=coe5
local request=api.readIni('request')or{}
if type(request.run)~='table'then return end
local only=request.run.only or'all'
local out={environment=(api.readIni('launcher-context')or{}).environment}
local started,opened=false,false
local currentCase

local function equal(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~='table'then return a==b end
    for key,value in pairs(a)do if not equal(value,b[key])then return false end end
    for key in pairs(b)do if a[key]==nil then return false end end
    return true
end
local function copy(value)
    if type(value)~='table'then return value end
    local result={};for key,item in pairs(value)do result[key]=copy(item)end;return result
end
local function flat(value)
    local result={}
    for key,item in pairs(value or{})do
        if key~='token'then
            if type(item)=='boolean'then result[key]=item and 1 or 0
            elseif type(item)=='number'or type(item)=='string'then result[key]=item end
        end
    end
    return result
end
local function write()assert(api.writeIni('results',out))end
local function tick()return api.get('ticksMs')end
local function record(name,value)
    out[currentCase..'_'..name]=flat(value)
    write()
end
local function observed()
    local state,reason=api.testFieldState()
    assert(type(state)=='table',tostring(reason));return state
end
local function spatial(state)
    -- Quarantine intentionally disables native hit testing. Compare its raw
    -- grid, single anchors and identities without labelling that view healthy.
    local result={width=state.width,height=state.height,session=state.session,grid=copy(state.grid),units={}}
    for _,row in ipairs(state.units or{})do
        result.units[#result.units+1]={unit=row.unit,generation=row.generation,monster=row.monster,hp=row.hp,
            owner=row.owner,worldX=row.worldX,worldY=row.worldY,kind=row.kind,creationSource=row.creationSource,
            provenanceVerified=row.provenanceVerified,width=row.width,height=row.height,
            anchorCount=row.anchorCount,anchors=copy(row.anchors)}
    end
    return result
end
local function genericBody(unit)
    local result={known={},memorized={},tempIds={},tempValues={}}
    for _,key in ipairs({'unitHp','unitMonster','unitOwner','unitX','unitY','unitCommander'})do result[key]=api.get(key,unit)end
    for i=0,59 do result.known[i+1]=api.get('unitKnownSpell',unit,i)end
    for i=0,29 do result.memorized[i+1]=api.get('unitMemorizedSpell',unit,i)end
    for i=0,3 do
        result.tempIds[i+1]=api.get('unitTempAbilityId',unit,i)
        result.tempValues[i+1]=api.get('unitTempAbilityValue',unit,i)
    end
    return result
end
local function supportedBodies(receipt)
    local result={}
    for _,row in ipairs(receipt.actors)do
        local actor,reason=api.testFieldActorState(row.unit);assert(actor,reason)
        local name;name,reason=api.testFieldUnitName(row.unit);assert(name,reason)
        local loadout;loadout,reason=api.testFieldLoadoutState(row.unit);assert(loadout,reason)
        -- These counters describe observations, rather than actor state.
        name.formatterReads=nil;loadout.combatAttackReads=nil
        result[row.unit]={actor=actor,name=name,loadout=loadout,generic=genericBody(row.unit)}
    end
    return result
end
local function close()
    local accepted=api.closeTestField();opened=false
    assert(accepted,'Generation-verified native close was refused')
    local life=assert(api.testFieldLifecycle())
    assert(life.complete and not life.open and #(life.issues or{})==0,'Native cleanup is unverified')
    record('cleanup',{status='PASS',complete=true,open=false,issues=0,session=life.session})
end
local function open(both)
    local began=tick()
    local accepted,units=api.openTestField{emptyEditor=true,terrain=20,minimumWidth=70,allowMultipleUnique=true,
        friends=both and{{884,1},{1475,1}}or{{13,1}},enemies={{884,1},{1475,1}}}
    opened=accepted;assert(accepted,tostring(units))
    local openMs=tick()-began
    local state=observed();assert(state.complete,'Source observation is incomplete')
    assert(#(state.issues or{})>0,'Fixture did not reproduce an initial native overlap')
    for _,issue in ipairs(state.issues)do assert(issue.code=='overlapping_footprint','Unexpected initial fault: '..tostring(issue.code))end
    local receipt=api.testFieldInitialDeployment()
    assert(receipt.version==1 and receipt.fresh and receipt.eligible and receipt.completeRoster and receipt.actorOverlapOnly)
    assert(receipt.sourceHealthy==false and type(receipt.token)=='number'and receipt.token>0 and receipt.session==state.session)
    assert(#receipt.overlaps>0 and #receipt.actors==(both and 4 or 3),'Receipt roster or overlap evidence is incomplete')
    local byId,counts,large={}, {[0]=0,[24]=0},0
    for _,row in ipairs(receipt.actors)do
        assert(not byId[row.unit]and row.generation>0 and row.kind=='actor'and row.creationSource=='owned_actor_creation'and row.provenanceVerified)
        assert(counts[row.owner]~=nil,'Unexpected native owner');counts[row.owner]=counts[row.owner]+1
        if row.width*row.height>1 then large=large+1 end
        byId[row.unit]=row
    end
    assert(counts[0]==(both and 2 or 1)and counts[24]==2 and large==(both and 2 or 1))
    for _,pair in ipairs(receipt.overlaps)do
        local a,b=assert(byId[pair.unit]),assert(byId[pair.otherUnit])
        assert(a.unit~=b.unit)
        for _,row in ipairs({a,b})do
            assert(pair.x>=row.x and pair.x<row.x+row.width and pair.y>=row.y and pair.y<row.y+row.height,'Overlap evidence lies outside a footprint')
        end
        assert(api.battleUnitAt(pair.x,pair.y)==b.unit,'Receipt winner differs from native hit')
    end
    record('source',{status='PASS',terrain=20,width=state.width,height=state.height,actors=#receipt.actors,
        overlaps=#receipt.overlaps,session=receipt.session,team_a=counts[0],team_b=counts[24],large_units=large,open_ms=openMs})
    return state,receipt
end
local function plan(state,receipt)
    local blocked,reserved={},{}
    for _,row in ipairs(state.units)do
        if row.alive and row.anchorCount==1 then
            local anchor=assert(row.anchors[1])
            for x=anchor.x,anchor.x+row.width-1 do for y=anchor.y,anchor.y+row.height-1 do blocked[x..':'..y]=true end end
        end
    end
    local rows={}
    for _,actor in ipairs(receipt.actors)do
        local target
        for x=1,state.width-actor.width do
            for y=0,state.height-actor.height do
                local free=true
                for dx=0,actor.width-1 do for dy=0,actor.height-1 do
                    local key=(x+dx)..':'..(y+dy)
                    if blocked[key]or reserved[key]or api.battleObjectAt(x+dx,y+dy)>=0 then free=false end
                end end
                if free and api.battleCanStand(actor.unit,x,y,0)and api.battleCanStand(actor.unit,x,y,4)then target={x=x,y=y};break end
            end
            if target then break end
        end
        assert(target,'No independently native-accepted target found for fixture actor '..actor.unit)
        rows[#rows+1]={unit=actor.unit,generation=actor.generation,x=target.x,y=target.y}
        for x=target.x,target.x+actor.width-1 do for y=target.y,target.y+actor.height-1 do reserved[x..':'..y]=true end end
    end
    return rows
end
local function healthyTargets(rows,receipt)
    local state=observed();assert(state.complete and #state.issues==0,'Final native field is not strictly healthy')
    local byId={};for _,row in ipairs(state.units)do byId[row.unit]=row end
    for _,wanted in ipairs(rows)do
        local row=assert(byId[wanted.unit]);assert(row.kind=='actor'and row.generation==wanted.generation and row.anchorCount==1)
        local anchor=assert(row.anchors[1]);assert(anchor.x==wanted.x and anchor.y==wanted.y,'Final position was silently changed')
        assert(#row.occupied==row.width*row.height)
        for x=anchor.x,anchor.x+row.width-1 do for y=anchor.y,anchor.y+row.height-1 do assert(api.battleUnitAt(x,y)==row.unit)end end
    end
    assert(state.session==receipt.session)
    return state
end
local function rejectedInvalidSource(state,receipt,rows,expectedReason,expectedKind,wrote)
    local before={};for _,actor in ipairs(receipt.actors)do before[actor.unit]=genericBody(actor.unit)end
    local accepted,reason,detail=api.setTestFieldDeployment(rows,{initialReceipt=receipt.token})
    assert(not accepted and reason==expectedReason,tostring(reason))
    assert(detail.version==1 and detail.initialReceiptUsed and detail.initialSession==receipt.session)
    assert(detail.sourceHealthy==false and detail.finalHealthy==false and detail.rollbackVerified==false and detail.byteRollbackVerified==true)
    assert(detail.wroteAnchors==wrote and detail.rollbackResult==(wrote and'invalid_source_restored'or'invalid_source_unchanged'))
    if wrote then assert(detail.anchorsRestored,'Staged anchor rollback was not verified')end
    if expectedKind then assert(detail.blockerKind==expectedKind,tostring(detail.blockerKind))end
    local after=observed();assert(equal(spatial(state),spatial(after)),'Refusal changed original source anchors/grid/identities')
    for _,actor in ipairs(receipt.actors)do assert(equal(before[actor.unit],genericBody(actor.unit)),'Refusal changed supported raw unit fields')end
    assert(not after.complete,'An invalid restored source must remain quarantined')
    record('rejected',detail);out[currentCase..'_rejected'].status='PASS';out[currentCase..'_rejected'].reason=reason
    out[currentCase..'_rejected'].raw_grid_anchors_identities_unchanged=1
    out[currentCase..'_rejected'].healthy_rollback_claimed=0;write()
end

local cases={
    {'repair_both_teams_large',function()
        local state,receipt=open(true);local rows=plan(state,receipt)
        local accepted,reason,detail=api.setTestFieldDeployment(rows)
        assert(not accepted and reason=='current_actor_overlap'and not detail.wroteAnchors,'Ordinary deployment silently accepted invalid source')
        assert(equal(state,observed()),'Ordinary refusal changed source')
        assert(api.testFieldInitialDeployment().fresh,'Read-only ordinary refusal invalidated the fresh receipt')
        record('ordinary_refusal',{status='PASS',reason=reason,wrote_anchors=false,source_unchanged=true,
            scope='Existing no-option API refuses; its legacy rollback flag is not a source-health assertion'})
        for _,bad in ipairs({
            {name='wrong_token',options={initialReceipt=receipt.token+1},reason='initial_receipt_unavailable'},
            {name='missing_option_key',options={},reason='bad_initial_receipt'},
            {name='unknown_option',options={initialReceipt=receipt.token,unexpected=true},reason='bad_initial_receipt'},
        })do
            accepted,reason,detail=api.setTestFieldDeployment(rows,bad.options)
            assert(not accepted and reason==bad.reason and detail.initialReceiptUsed==false and not detail.wroteAnchors,tostring(reason))
            assert(equal(state,observed()),'Invalid receipt options changed the source')
            assert(equal(receipt,api.testFieldInitialDeployment()),'Invalid receipt options consumed or changed the genuine receipt')
            record(bad.name,{status='PASS',reason=reason,genuine_receipt_retained=true,source_unchanged=true})
        end
        local bodies=supportedBodies(receipt);local life=api.testFieldLifecycle();local began=tick()
        accepted,reason,detail=api.setTestFieldDeployment(rows,{initialReceipt=receipt.token})
        local elapsed=tick()-began
        assert(accepted and reason==nil and detail.version==1 and detail.phase=='committed',tostring(reason))
        assert(detail.initialReceiptUsed and detail.initialSession==receipt.session and detail.sourceHealthy==false and detail.finalHealthy)
        assert(detail.rollbackVerified and detail.byteRollbackVerified and detail.wroteAnchors and detail.units==#rows)
        local after=healthyTargets(rows,receipt)
        assert(equal(bodies,supportedBodies(receipt)),'Successful repair changed supported names/configuration/body fields')
        assert(equal(life,api.testFieldLifecycle()),'Successful repair changed lifecycle identities')
        record('committed',detail)
        out[currentCase..'_committed'].status='PASS';out[currentCase..'_committed'].commit_ms=elapsed
        out[currentCase..'_committed'].supported_actor_name_loadout_state_unchanged=1
        out[currentCase..'_committed'].exact_native_bytes_scope='Internal API exact full-snapshot contract; Lua independently checks supported state'
        local used=api.testFieldInitialDeployment();assert(not used.fresh and not used.eligible and used.reason=='initial_receipt_consumed')
        accepted,reason,detail=api.setTestFieldDeployment(rows,{initialReceipt=receipt.token})
        assert(not accepted and reason=='initial_receipt_unavailable'and not detail.initialReceiptUsed and not detail.wroteAnchors)
        assert(equal(after,observed()),'Token replay changed the repaired field')
        record('replay',{status='PASS',reason=reason,healthy_field_unchanged=true});close()
    end},
    {'occupied_target',function()
        local state,receipt=open(false);local rows=plan(state,receipt)
        rows[2].x=rows[1].x;rows[2].y=rows[1].y
        rejectedInvalidSource(state,receipt,rows,'blocked','target_overlap',false);close()
    end},
    {'outside_footprint',function()
        local state,receipt=open(false);local rows=plan(state,receipt)
        local index;for i,row in ipairs(receipt.actors)do if row.width>1 then index=i;break end end
        assert(index);rows[index].x=state.width-receipt.actors[index].width+1
        assert(rows[index].x<state.width,'This case must keep the anchor inside while the full footprint crosses the edge')
        rejectedInvalidSource(state,receipt,rows,'off_field','out_of_bounds',false);close()
    end},
    {'gate_target',function()
        local state,receipt=open(false);local rows=plan(state,receipt);local structure
        for _,row in ipairs(state.units)do
            if row.kind=='structure'and row.creationSource=='native_gate_replacement'and row.provenanceVerified then assert(not structure);structure=row end
        end
        assert(structure and structure.anchorCount==1,'No constructor-proven native gate in this fixture')
        rows[1].x=structure.anchors[1].x;rows[1].y=structure.anchors[1].y
        rejectedInvalidSource(state,receipt,rows,'blocked','structure',false);close()
    end},
    {'blocked_object_target',function()
        local state,receipt=open(false);local rows=plan(state,receipt);local target
        local reserved={}
        for i,row in ipairs(rows)do if i~=1 then local actor=receipt.actors[i]
            for x=row.x,row.x+actor.width-1 do for y=row.y,row.y+actor.height-1 do reserved[x..':'..y]=true end end
        end end
        for _,row in ipairs(state.units)do if row.kind=='structure'then local a=assert(row.anchors[1])
            for x=a.x,a.x+row.width-1 do for y=a.y,a.y+row.height-1 do reserved[x..':'..y]=true end end
        end end
        assert(receipt.actors[1].width==1 and receipt.actors[1].height==1)
        for x=0,state.width-1 do for y=0,state.height-1 do
            local object=api.battleObjectAt(x,y)
            if object>=0 and not reserved[x..':'..y]and not api.battleCanStand(rows[1].unit,x,y,4)then target={x=x,y=y,object=object};break end
        end;if target then break end end
        assert(target,'No genuinely native-rejected object cell found; this rollback case is not verified')
        rows[1].x=target.x;rows[1].y=target.y
        local before={};for _,actor in ipairs(receipt.actors)do before[actor.unit]=genericBody(actor.unit)end
        local accepted,reason,detail=api.setTestFieldDeployment(rows,{initialReceipt=receipt.token})
        assert(not accepted and(reason=='native_stand_rejected'or reason=='native_terrain_rejected'),tostring(reason))
        assert(detail.initialReceiptUsed and detail.initialSession==receipt.session and detail.wroteAnchors and detail.anchorsRestored)
        assert(detail.sourceHealthy==false and detail.finalHealthy==false and not detail.rollbackVerified and detail.byteRollbackVerified)
        assert(detail.rollbackResult=='invalid_source_restored')
        assert(equal(spatial(state),spatial(observed())),'Native rejection did not restore original source anchors')
        for _,actor in ipairs(receipt.actors)do assert(equal(before[actor.unit],genericBody(actor.unit)))end
        record('rejected',detail);out[currentCase..'_rejected'].status='PASS';out[currentCase..'_rejected'].reason=reason
        out[currentCase..'_rejected'].actual_native_object=target.object;write();close()
    end},
    {'omitted_actor',function()
        local state,receipt=open(false);local rows=plan(state,receipt);table.remove(rows)
        rejectedInvalidSource(state,receipt,rows,'incomplete_actor_roster',nil,false);close()
    end},
    {'stale_generation',function()
        local state,receipt=open(false);local rows=plan(state,receipt);rows[1].generation=rows[1].generation+1
        rejectedInvalidSource(state,receipt,rows,'generation_changed',nil,false);close()
    end},
    {'missing_generation',function()
        local state,receipt=open(false);local rows=plan(state,receipt);rows[1].generation=nil
        rejectedInvalidSource(state,receipt,rows,'generation_changed',nil,false);close()
    end},
    {'duplicate_actor',function()
        local state,receipt=open(false);local rows=plan(state,receipt);rows[2]=copy(rows[1])
        rejectedInvalidSource(state,receipt,rows,'duplicate_unit',nil,false);close()
    end},
    {'stale_body',function()
        local state,receipt=open(false);local rows=plan(state,receipt);local unit=receipt.actors[1].unit
        local hp=api.get('unitHp',unit);assert(hp>1)
        api.set('unitHp',unit,hp-1)
        local changed=api.testFieldInitialDeployment();assert(not changed.fresh and not changed.eligible and changed.reason=='initial_source_changed')
        api.set('unitHp',unit,hp)
        local restored=api.testFieldInitialDeployment();assert(not restored.fresh and not restored.eligible,'Byte restoration revived an invalidated receipt')
        local accepted,reason,detail=api.setTestFieldDeployment(rows,{initialReceipt=receipt.token})
        assert(not accepted and reason=='initial_receipt_unavailable'and not detail.initialReceiptUsed and not detail.wroteAnchors)
        assert(equal(state,observed()),'Stale receipt test did not retain the original source')
        record('refused',{status='PASS',reason=reason,permanent_invalidation=true,controlled_hp_restored=true});close()
    end},
    {'healthy_ordinary',function()
        local accepted,units=api.openTestField{emptyEditor=true,terrain=0,minimumWidth=70,friends={{13,1}},enemies={{13,1}}}
        opened=accepted;assert(accepted,tostring(units))
        local state=observed();assert(state.complete and #state.issues==0,'Ordinary fixture is not healthy')
        local receipt=api.testFieldInitialDeployment()
        assert(receipt.version==1 and receipt.fresh and not receipt.eligible and receipt.sourceHealthy and receipt.completeRoster)
        assert(not receipt.actorOverlapOnly and #receipt.overlaps==0 and #receipt.actors==2 and receipt.token>0)
        local rows=plan(state,receipt);local bodies=supportedBodies(receipt);local life=api.testFieldLifecycle()
        local reason,detail
        accepted,reason,detail=api.setTestFieldDeployment(rows,{initialReceipt=receipt.token})
        assert(not accepted and reason=='initial_receipt_unavailable'and detail.initialReceiptUsed==false and not detail.wroteAnchors)
        assert(equal(state,observed())and equal(receipt,api.testFieldInitialDeployment()),'Unneeded exceptional repair changed the healthy field/receipt')
        record('exception_refused',{status='PASS',reason=reason,healthy_field_unchanged=true,receipt_unconsumed=true})
        accepted,reason,detail=api.setTestFieldDeployment(rows)
        assert(accepted and reason==nil and detail.initialReceiptUsed==false and detail.finalHealthy and detail.rollbackVerified)
        healthyTargets(rows,receipt)
        assert(equal(bodies,supportedBodies(receipt))and equal(life,api.testFieldLifecycle()),'Ordinary deployment changed supported unit state or identities')
        local used=api.testFieldInitialDeployment();assert(not used.fresh and not used.eligible and used.reason=='initial_source_changed')
        record('ordinary_committed',{status='PASS',ordinary_deployment=true,supported_state_unchanged=true,old_initial_receipt_stale=true});close()
    end},
}

api.wrap('MAIN_MENU_WAIT',function(next,...)
    local value=next(...);if started then return value end;started=true
    local count=0
    local accepted,reason=xpcall(function()
        local caps=assert(api.testFieldEditorCapabilities())
        assert(caps.initialDeploymentVersion==1 and caps.exactDeploymentVersion==1,'Matching initial-deployment API missing')
        for id,name in pairs({[13]='Spearman',[884]='Hunter of Gods',[1475]='Bronze Wall'})do
            assert(api.get('monsterName',id)==name,'Fixture type differs from the examined vanilla definition: '..name)
        end
        for _,case in ipairs(cases)do
            if only=='all'or only=='none'or only==case[1]then
                currentCase=case[1];out.progress={stage=currentCase,status='RUNNING'};write()
                case[2]();count=count+1;out[currentCase]={status='PASS'};write()
            end
        end
        assert(count>0,'Unknown initial-deployment probe case: '..tostring(only))
    end,tostring)
    if not accepted and opened then
        local stateOk,state=pcall(api.testFieldState)
        if stateOk and type(state)=='table'then out.failure_source={complete=state.complete and 1 or 0,issues=#(state.issues or{}),units=#(state.units or{})}end
        local closeOk,closed=pcall(api.closeTestField);opened=false
        out.failure_cleanup={called=closeOk and 1 or 0,returned=closed==true and 1 or 0}
    end
    if not accepted then out[currentCase or'initialization']={status='FAIL',detail=tostring(reason)}end
    out.progress=nil
    out.complete={status=accepted and'PASS'or'FAIL',cases_completed=count,detail=tostring(reason or
        'Direct native receipt, full-roster repair, refusal, identity/state and generation-verified cleanup checks passed; no battle or visible UI test')}
    write();return value
end,-100)
