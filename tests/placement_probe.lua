-- Explicit opt-in probe in the isolated game. No campaign, no simulated engine.
local api=coe5
local M=require('sandbox.model')
local C=require('sandbox.catalog')
local D=require('sandbox.diagnostics')
local request=api.readIni('request')
if not request or not request.run then return end
local mode=request.run.mode
local R=require(mode=='baseline' and 'baseline.runtime' or 'sandbox.runtime')
local c=C.read(api)
local results={environment={scope='real CoE5 process; explicit isolated placement probe',mode=mode}}
local serial=0
local function save() assert(api.writeIni('placement-results',results)) end
local function spells(unit,key,max)
    local out={}
    for i=0,max do local id=api.get(key,unit,i);if not id or id<0 then break end
        local info=api.spellInfo(id);out[#out+1]=id..':'..(info and info.name or '?')
    end
    return table.concat(out,'|')
end
local function native(unit)
    local cells={}
    for x=0,api.get('battleWidth')-1 do for y=0,19 do
        if api.battleUnitAt(x,y)==unit then cells[#cells+1]=x..','..y end
    end end
    return {unit=unit,hp=api.get('unitHp',unit),monster=api.get('unitMonster',unit),owner=api.get('unitOwner',unit),
        x=api.get('unitBattleX',unit),y=api.get('unitBattleY',unit),cells=table.concat(cells,';'),
        known=spells(unit,'unitKnownSpell',59),memorized=spells(unit,'unitMemorizedSpell',29)}
end
local function checkpoint(label,s,r,extra)
    serial=serial+1;local prefix=('%03d_%s'):format(serial,label)
    local row=extra or {};row.model_units=s and #s.units or 0;row.width=api.get('battleWidth');row.open=r and r.open and 1 or 0
    results[prefix]=row
    if s then for i,u in ipairs(s.units) do local id=r.live[u.id];local n=id and native(id) or {}
        n.model_id=u.id;n.saved_monster=u.monster;n.saved_x=u.x;n.saved_y=u.y;n.team=u.team
        results[prefix..'_unit'..i]=n
    end end
    save()
end
local function fresh(terrain)
    local d=D.new(api);local r=R.new(api,c,d);local s=M.new();s.terrain=terrain or 0
    M.add(s,13,c.byId[13].name,1,8,9);M.add(s,953,c.byId[953].name,2,18,9)
    local ok,why=r:build(s,terrain==2);if not ok then d:export({fixture='fresh failed'},r:snapshot(s)) end;assert(ok,why);return r,s,d
end
local function test(name,fn)
    local ok,why=xpcall(fn,function(e)return tostring(e) end)
    results[name]={status=ok and 'PASS' or 'FAIL',detail=ok and 'real native calls' or why}
    api.closeTestField();save()
end
if mode=='baseline' then
    test('raw_large_allocation',function()
        local r,s=fresh()
        for i,monster in ipairs({206,206,202,202,203}) do
            local ids=api.addTestFieldUnits('enemies',{{monster,1}});assert(ids and #ids==1)
            local id=ids[1];results['raw'..i..'_after_add']=native(id)
            local ok=api.moveTestFieldUnit(id,22,(i-1)*4)
            results['raw'..i..'_after_move']=native(id);results['raw'..i..'_after_move'].accepted=ok and 1 or 0
            save()
        end
        r:close()
    end)
    test('old_runtime_large_sequence',function()
        local r,s,d=fresh()
        for i,pos in ipairs({{206,1,10,6},{206,1,10,8},{206,1,10,10},{206,1,10,12},{206,1,10,14},
            {202,2,16,14},{202,2,16,11},{202,2,16,13},{203,2,16,3},{202,2,19,10}}) do
            local ok,candidate,u=r:add(s,table.unpack(pos));if ok then s=candidate end
            checkpoint('add'..i,s,r,{accepted=ok and 1 or 0,detail=ok and 'ok' or tostring(candidate)})
        end
        local name=d:export({fixture='large baseline'},r:snapshot(s));results.baseline_diagnostic={name=name or 'failed'}
        for _,u in ipairs(s.units) do if u.monster==202 then local ok,why=r:remove(s,u);checkpoint('delete',s,r,{accepted=ok and 1 or 0,detail=tostring(why)});break end end
        r:close()
    end)
else
    local function checked(r,s,previous)
        assert(r.emptyEditor and r.primaryId==nil,'placement regression did not use the commander-free editor')
        local ok,value=r:check(s,true,previous);assert(ok,tostring(value));return value
    end
    local function add(r,s,monster,team,x,y,template)
        local before=checked(r,s);local ok,nextScenario,u=r:add(s,monster,team,x,y,template)
        assert(ok,tostring(nextScenario));checked(r,nextScenario,before);return nextScenario,u
    end
    local function absent(r,id)
        local row=api.testFieldUnitState(id);assert(row and row.hp==-9999 and row.worldX==-1 and row.worldY==-1 and row.anchorCount==0 and #row.occupied==0,'removed slot not permanently retired/detached')
        local state=api.testFieldState();assert(state.complete and #state.issues==0)
        for _,cell in ipairs(state.grid) do assert(cell.unit~=id,'retired anchor remains') end
        for _,unit in ipairs(state.units) do assert(unit.unit~=id or not unit.alive,'retired unit still alive') end
    end
    test('unique_guards_prevent_alias_before_mutation',function()
        local r,s=fresh();s=add(r,s,202,2,16,14)
        local before=checked(r,s);local last=api.get('unitLastIndex')
        local made,why=api.addTestFieldUnits('friends',{{202,1}})
        assert(not made and why=='unique_exists',tostring(why));checked(r,s,before);assert(api.get('unitLastIndex')==last)
        made,why=api.addTestFieldUnits('enemies',{{204,1},{204,1}})
        assert(not made and why=='unique_count',tostring(why));checked(r,s,before);assert(api.get('unitLastIndex')==last)
        local ok=r:add(s,202,1,22,2);assert(not ok and not r.blocked);checked(r,s,before)
        checkpoint('unique_refused',s,r,{native_exists=1,native_count=1,lua_duplicate=1,old_state_unchanged=1})
        r:close()
        ok=api.openTestField{commander=202,enemies={{202,1}}};assert(not ok,'cross-side duplicate unique accepted')
    end)
    test('large_placement_delete_reuse_spells_items',function()
        local r,s,d=fresh()
        for _,y in ipairs({6,8,10,12,14}) do s=add(r,s,206,1,10,y) end
        local riderA,riderB,priest
        s,riderA=add(r,s,202,2,16,14);s,riderB=add(r,s,203,2,16,11)
        s,priest=add(r,s,208,1,5,4)
        api.giveItem(r.live[priest.id],'A Chest Full of Fire');priest.items=r:inventory(r.live[priest.id])
        if priest.equipment then local L=require('sandbox.loadout');L.capture(r,priest,assert(L.read(r,r.live[priest.id])))end
        assert(#priest.items>0);assert(r:memorize(priest,priest.spells[1],false))
        local original=checked(r,s)
        for i=1,6 do
            local ok=r:add(s,204,2,17,15);assert(not ok and not r.blocked,'overlapping 3x3 was not safely rejected')
            checked(r,s,original)
            local error=d.lastError;assert(error and error.details.native_id)
            absent(r,assert(tonumber(error.details.native_id)))
        end
        local name,path=d:export({fixture='repeated genuine large-footprint rejection'},r:snapshot(s));assert(name,path)
        results.rejected_export={name=name,real_native_target_rejections=6,rollback_verified=1}
        local id=r.live[riderA.id];local ok,nextScenario=r:remove(s,riderA);assert(ok,tostring(nextScenario));s=nextScenario
        absent(r,id);checked(r,s,original)
        s,riderA=add(r,s,202,1,16,14)
        local seraph=s.units[3];assert(seraph.monster==206)
        id=r.live[seraph.id];ok,nextScenario=r:remove(s,seraph);assert(ok,tostring(nextScenario));s=nextScenario;absent(r,id)
        local spear;s,spear=add(r,s,13,2,11,7)
        ok=r:add(s,206,1,10,6);assert(not ok and not r.blocked,'interior occupied footprint accepted')
        local spearNative=r.live[spear.id];ok,nextScenario=r:remove(s,spear);assert(ok,tostring(nextScenario));s=nextScenario;absent(r,spearNative)
        s=add(r,s,206,1,10,6)
        local current=checked(r,s)
        assert(current.signatures[r.live[priest.id]]==original.signatures[r.live[priest.id]],'custom caster changed')
        checkpoint('large_final',s,r,{teams=2,seraph_footprint='2x2',rider_footprint='3x3',custom_priest_preserved=1,delete_reuse=1})
        r:close()
    end)
    test('forest_obstacle_rejection_and_afterwards_placement',function()
        local r,s,d=fresh(2);local before=checked(r,s);local rejected=false
        local state=api.testFieldState()
        for _,g in ipairs(state.grid) do if g.object>=0 and g.x<r.width-3 and g.y<17 then
            local ok=r:add(s,206,2,g.x,g.y)
            if not ok and not r.blocked then rejected=true;checked(r,s,before);break end
        end end
        assert(rejected,'no tested obstacle rejection')
        local placed=false
        for y=1,16 do for x=1,r.width-4 do
            local free=true
            for dx=0,1 do for dy=0,1 do if api.battleUnitAt(x+dx,y+dy)>=0 or api.battleObjectAt(x+dx,y+dy)>=0 then free=false end end end
            if free then local ok,candidate=r:add(s,206,2,x,y);if ok then s=candidate;placed=true;break end end
        end;if placed then break end end
        assert(placed and not r.blocked);checked(r,s,before)
        checkpoint('forest',s,r,{obstacle_refused=1,later_placement=1});r:close()
    end)
    test('injected_cleanup_failure_locks_and_requires_restart',function()
        local r,s,d=fresh();local priest;s,priest=add(r,s,208,1,5,4)
        assert(r:memorize(priest,priest.spells[1],false))
        local known=table.concat(priest.baseline.known,'|');local memorized=table.concat(priest.spells,'|')
        local realApi=r.api;local proxy=setmetatable({removeTestFieldUnit=function()return false,'injected_cleanup_refusal' end},{__index=realApi});r.api=proxy
        local ok=r:add(s,206,1,7,9);assert(not ok and r.blocked,'failed cleanup not locked')
        local last=api.get('unitLastIndex');local first=d.firstIntegrity.message
        assert(not r:add(s,13,2,21,3));assert(not r:remove(s,s.units[2]));assert(not r:memorize(priest,priest.baseline.known[1],true))
        assert(api.get('unitLastIndex')==last and d.firstIntegrity.message==first)
        assert(r.recoveryFile and api.readIni(r.recoveryFile).scenario,'preserved setup not written')
        local name=d:export({fixture='explicit injected cleanup refusal'},r:snapshot(s));results.recovery={diagnostics=name,scenario=r.recoveryFile,injected=1,locked=1}
        local preserved=M.encode(s,c.mods)
        r.api=realApi;local recovered,message=r:recover();assert(not recovered and r.blocked and message:find('restart'),'unverified retirement recovered silently')
        local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
        assert(same(preserved,M.encode(s,c.mods)) and table.concat(priest.baseline.known,'|')==known and table.concat(priest.spells,'|')==memorized)
        assert(api.writeIni('controls-recovery-reference',{recovery={scenario=r.recoveryFile,known=known,memorized=memorized}}))
        results.recovery.restart_required=1;results.recovery.preserved_exact_spells=1;r:close()
    end)
end
save()
