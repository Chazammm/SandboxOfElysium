-- Private real-process runner; never enabled by a normal BAT launch.
local api=coe5
local request=api.readIni('request');if not request or not request.run then return end
local function execute()
local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local D=require('sandbox.diagnostics');local Report=require('sandbox.report')
local c=C.read(api);local out={environment={scope='actual isolated CoE5 process',mode=request.run.mode}}
local selected={};for key in tostring(request.run.only or ''):gmatch('[^,]+')do selected[key]=true end
local function enabled(key)return not next(selected) or selected[key]end
local function save()assert(api.writeIni('battlefield-results',out))end
local active,fighting,lastRound
api.wrap('BATTLE_WAIT',function(next,b,m)
    local id=next(b,m)
    if fighting then
        local round=api.get('battleRound')
        if round~=lastRound then lastRound=round;out.progress=out.progress or {};out.progress.round=round;out.progress.delay=api.get('battleDelay') or 'unknown';save()end
    end
    if fighting and id==0 and (api.get('battleDelay') or 0)>2 then return 1 end
    return id
end)
local function flat(row)local t={};for k,v in pairs(row or {})do if type(v)=='boolean'then t[k]=v and 1 or 0 elseif type(v)~='table'then t[k]=v end end;return t end
local function same(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function run(name,fn)
    out.progress={case=name,status='RUNNING'};lastRound=nil;save()
    local ok,why=xpcall(fn,function(e)return tostring(e)end)
    if active then local closed,reason=active:close();active=nil;if not closed then ok=false;why='cleanup: '..tostring(reason)end end
    out[name]={status=ok and 'PASS' or 'FAIL',detail=ok and 'actual native calls; not an offline simulation' or why};out.progress.status=ok and 'PASS' or 'FAIL';save()
end
local function open(scene,nativeDeployment)
    local r=R.new(api,c,D.new(api));active=r
    local place=r.place
    r.place=function(self,s)
        local ok,why=place(self,s)
        if not ok then
            local key=(out.progress and out.progress.case or 'unknown')..'_placement_failure'
            local diagnostic=self.diag:export({fixture=key,reason=why},self:snapshot(s))
            out[key]={reason=why,diagnostic=diagnostic or 'unavailable'}
            local valid,detail,extra=self:check(s,true,nil,false)
            out[key].final_check=tostring(detail)
            if not valid and type(extra)=='table'then for k,v in pairs(extra)do if type(v)~='table'then out[key][k]=v end end end
            save()
        end
        return ok,why
    end
    local ok,why=r:build(scene,nativeDeployment);assert(ok,why);assert(r:ready(scene));return r
end
local function small()
    local s=M.new();M.add(s,13,assert(c.byId[13]).name,1,8,9);M.add(s,953,assert(c.byId[953]).name,2,18,9);return s
end
if request.run.mode=='baseline' then
    run('old_final_cells_cleared_while_survivor_alive',function()
        local s=small();local r=open(s);fighting=true;api.fightTestField();fighting=false
        local native=api.testFieldState();local cells,survivors=0,0
        for _,g in ipairs(native.grid or {})do if g.unit>=0 or g.object>=0 then cells=cells+1 end end
        for _,u in ipairs(s.units)do if api.get('unitHp',r.live[u.id])>0 then survivors=survivors+1 end end
        out.baseline={survivors=survivors,raw_nonempty_cells=cells,round=api.get('battleRound'),winner=api.get('battleWinner'),native_issues=#(native.issues or {})}
        assert(survivors>0 and cells==0 and api.get('battleRound')>0,'old empty post-battle state was not reproduced')
    end)
    return
end
if enabled('empty')then require('empty_probe').run(api,{cycles=2,onFight=function(value)fighting=value end})end
if enabled('terrain')then require('terrain_expansion_probe').run(api,{cycles=2,candidateBuild=request.run.terrain_candidates=='1',includeBaseline=true,onFight=function(value)fighting=value end})end
if enabled('filters')then
    run('unit_filters_main_menu_and_native_field',function()
        assert(c.rangedUnknown==0,'main-menu ranged query unavailable')
        local count={};for _,category in ipairs({'All','human','animal','undead','demonic','flying','ranged'})do count[category]=#C.filter(c,'',category);assert(count[category]>0,'empty filter: '..category)end
        assert(not c.byId[13].categories.ranged,'Spearman unexpectedly classified ranged')
        local archers=C.filter(c,'Archer','ranged');assert(#archers>0,'no native ranged Archer')
        local r=open(M.new())
        for _,m in ipairs(c.monsters)do local current=api.monsterHasRanged(m.id);assert(type(current)=='boolean' and current==(m.categories.ranged==true),'classifier differs by context for '..m.id)end
        out.filter_counts=count;out.filter_counts.unavailable=c.rangedUnknown
        for i,m in ipairs(archers)do if i<=8 then out['ranged_archer'..i]={id=m.id,name=m.name}end end
        local closed,why=r:close();assert(closed,why)
    end)
end
local function finalBattle(name,scene,requireSummons,nativeDeployment)
    run(name,function()
        local original=M.copy(scene);local r=open(scene,nativeDeployment);local before=M.copy(scene);local report=Report.new(api)
        local initial={};for _,u in ipairs(scene.units)do initial[r.live[u.id]]=u.id end
        report:start(scene,r);fighting=true;api.fightTestField();fighting=false;report:finish(scene,r);r.phase='after'
        assert(api.get('battleRound')>0 and (api.get('battleWinner')==0 or api.get('battleWinner')==24),'battle did not complete naturally')
        local final=assert(api.testFieldFinalState());assert(final.source=='post_aftermath_before_upkeep' and final.complete==true,'complete timed final capture unavailable')
        assert(#final.grid==final.width*final.height and final.sceneComplete==false)
        local alive,onField,summons,removed,terrain,changed=0,0,0,0,0,0
        for _,row in ipairs(final.units)do
            if row.kind=='terrain'then terrain=terrain+1
            elseif row.alive then
                alive=alive+1;if row.anchorCount==1 then onField=onField+1;assert(#row.occupied==row.width*row.height)end
                if row.createdDuringFight then summons=summons+1 end
                if not row.currentAlive then removed=removed+1 end
                if row.ownerChanged or row.monsterChanged then changed=changed+1 end
            end
        end
        assert(onField>0,'no survivor position captured')
        if requireSummons then assert(summons>0,'natural summon case not established')end
        out[name..'_capture']={source=final.source,complete=1,scene_complete=0,actors_alive_at_boundary=alive,on_field=onField,
            living_new_combat_actors=summons,later_removed=removed,terrain_rows=terrain,changed_owners_or_monsters=changed,round=api.get('battleRound'),winner=api.get('battleWinner')}
        out[name..'_capture'].export_scope='At most 64 rows, actors before terrain; full capture coverage is separate'
        for i,row in ipairs(require('sandbox.final_view').exportUnits(final,64))do out[name..'_unit'..i]=flat(row);local anchor=row.anchors[1];if anchor then out[name..'_unit'..i].x=anchor.x;out[name..'_unit'..i].y=anchor.y end end
        local kept=api.testFieldFinalState();assert(same(final,kept),'read-only snapshot query mutated its capture')
        local id=scene.units[1] and r.live[scene.units[1].id]
        if id then assert(not api.moveTestFieldUnit(id,4,4));assert(not api.removeTestFieldUnit(id))end
        assert(same(final,api.testFieldFinalState()),'refused final edit changed snapshot')
        assert(report:archive());local diagnostic=r.diag:export({phase='after',fixture=name},r:snapshot(scene));assert(diagnostic)
        out[name..'_diagnostic']={name=diagnostic}
        local closed,why=r:close();assert(closed,why)
        scene=M.copy(before);assert(r:build(scene));assert(r:ready(scene));assert(same(M.encode(scene,c.mods),M.encode(before,c.mods)),'reset changed configured setup')
        -- Source recovery is only read. Native initialization may populate an
        -- absent baseline in an unconfigured fixture, never alter saved lists.
        for i,u in ipairs(original.units)do if u.baseline then assert(same(u.baseline,scene.units[i].baseline) and same(u.spells,scene.units[i].spells) and same(u.items,scene.units[i].items))end end
        if name=='actual_user_ten_unit_setup_final_view'then
            local rematch=Report.new(api);rematch:start(scene,r);fighting=true;api.fightTestField();fighting=false;rematch:finish(scene,r);r.phase='after'
            local second=assert(api.testFieldFinalState());assert(second.complete and #(second.issues or {})==0 and #second.grid==second.width*second.height)
            assert(api.get('battleRound')>0 and (api.get('battleWinner')==0 or api.get('battleWinner')==24),'user rematch did not finish naturally')
            out.actual_user_ten_unit_rematch={round=api.get('battleRound'),winner=api.get('battleWinner'),complete=1,source=second.source,report=assert(rematch:archive())}
            local closed,why=r:close();assert(closed,why);scene=M.copy(before);assert(r:build(scene));assert(r:ready(scene))
            assert(same(M.encode(scene,c.mods),M.encode(before,c.mods)),'user rematch changed exact saved setup')
        end
    end)
end
if enabled('mods')then
    local scene=M.new()
    for i,name in ipairs({'Shorebound Initiate','Abyssal Shellback'})do
        local id=api.findMonster(name);assert(c.byId[id] and c.byId[id].name==name,'loaded mod fixture missing: '..name)
        local matches=C.filter(c,name,'All');assert(#matches==1 and matches[1].id==id,'mod search failed')
        M.add(scene,id,name,1,8,3+i*4)
        out['crabcult_unit'..i]={name=name,monster=id,sprite=c.byId[id].sprite,hp=api.get('monsterHp',id),
            provenance='Exact newmonster names verified in the installed CrabCult.c5m; no ID-range attribution'}
    end
    for i=1,3 do M.add(scene,953,c.byId[953].name,2,18,3+i*4)end
    local saved=M.encode(scene,c.mods);local available={};local found=false
    for _,mod in ipairs(c.mods)do if mod=='CrabCult'then found=true else available[#available+1]=mod end end
    assert(found,'CrabCult not active')
    local rejected,why=M.decode(saved,c,available);assert(not rejected and why:find('CrabCult'),'missing active mod was not refused')
    out.crabcult_missing_mod={refused=1,reason=why,scope='Production decoder with actual loaded catalog; only CrabCult omitted from active mods'}
    finalBattle('active_crabcult_units_search_placement_and_combat',scene,false,true)
end
if enabled('six')then local s,why=M.decode(api.readIni('replay'),c,c.mods);assert(s,why);finalBattle('six_original_gods_final_snapshot',s,false)end
if enabled('user')then local s,why=M.decode(api.readIni('user-replay'),c,c.mods);assert(s,why);finalBattle('actual_user_ten_unit_setup_final_view',s,false)end
if enabled('summon')then
    local saved,why=M.decode(api.readIni('replay'),c,c.mods);assert(saved,why)
    local s=M.new();for i=1,5 do M.add(s,13,c.byId[13].name,1,8,i*3)end
    local source=M.copy(saved.units[2]);source.spells={}
    for _,key in ipairs(source.baseline.known)do if key:match('^57:') or key:match('^58:')then source.spells[#source.spells+1]=key end end
    assert(#source.spells==2,'recorded known summon spells absent')
    M.add(s,source.monster,source.name,2,22,9,source)
    finalBattle('explicit_known_summons_survive_to_final_boundary',s,true,true)
end
out.complete={status='FINISHED',scope='Consult each selected group and separate final/empty/terrain result files; FINISHED is not an all-pass claim'};save()
end
if request.run.defer=='1' then
    local started=false
    api.addMainMenuButton('Battlefield regression (private)',function()if not started then started=true;execute()end end)
else execute()end
