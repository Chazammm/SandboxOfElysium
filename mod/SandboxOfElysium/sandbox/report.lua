local M=require('sandbox.model')
local Report={};Report.__index=Report
function Report.new(api)
    local self=setmetatable({api=api,active=false,stack={}},Report)
    self.hooks={}
    self.hooks.attack=api.observe('DOATTACK',function(unit,slot,spell)
        if not self.active then return end
        self.stack[#self.stack+1]=unit
        if spell and spell>=0 then
            local key=unit..':'..spell; self.itemSpellAttacks[key]=(self.itemSpellAttacks[key] or 0)+1
        end
    end,function()
        if self.active then table.remove(self.stack) end
    end)
    self.hooks.damage=api.observe('DAMAGE_UNIT',function(unit,damage)
        if not self.active then return end
        self.damageStack[#self.damageStack+1]={unit=unit,hp=api.get('unitHp',unit),source=self.stack[#self.stack]}
    end,function()
        if not self.active then return end
        local e=table.remove(self.damageStack); if not e or not e.hp then return end
        local after=api.get('unitHp',e.unit)
        if after then
            local loss=math.max(0,math.max(0,e.hp)-math.max(0,after))
            if e.source then self.direct[e.source]=(self.direct[e.source] or 0)+loss
            else self.unattributed=self.unattributed+loss end
        end
    end)
    self.hooks.aftermath=api.observe('BATTLE_TURN_EFFECTS',nil,function(result,unit,aftermath)
        if self.active and aftermath~=0 then
            local x,y=api.get('unitBattleX',unit),api.get('unitBattleY',unit)
            if x and y then self.aftermath[unit]={x=x,y=y} end
        end
    end)
    return self
end
function Report:start(s,runtime)
    self.active=true;self.stack={};self.damageStack={};self.direct={};self.itemSpellAttacks={};self.unattributed=0
    self.started=self.api.get('ticksMs');self.initial={};self.aftermath={};self.scenario=M.copy(s)
    for _,u in ipairs(s.units) do local unit=runtime.live[u.id]
        self.initial[u.id]={native=unit,kills=self.api.get('unitKills',unit)}
    end
end
function Report:finish(s,runtime)
    self.active=false
    local final,finalReason
    if type(self.api.testFieldFinalState)=='function' then
        local ok,value,reason=pcall(self.api.testFieldFinalState)
        if ok and type(value)=='table' then final=value else finalReason=reason or tostring(value) end
    end
    runtime.finalState=final
    local captured={};for _,row in ipairs(final and final.units or {}) do captured[row.unit]=row end
    local out={summary={winner=self.api.get('battleWinner'),final_round=self.api.get('battleRound'),terrain=s.terrain,
        terrain_name=self.api.get('terrainName',s.terrain),size=s.size,allow_multiple_unique=s.allowMultipleUnique and 1 or 0,
        elapsed_wall_ms=(self.api.get('ticksMs')-self.started)%4294967296,unattributed_observed_hp_loss=self.unattributed,
        damage='Partial: synchronous DOATTACK -> DAMAGE_UNIT HP loss only; not total damage',
        spells='Complete cast log unavailable; item spell DOATTACK events exported separately',
        population='Original roster only; summons excluded; survivors counted by original team, even after conversion',
        final_position_count=0,aftermath_position_count=0,captured_original_position_count=0,
        positions='Return-time cells and any observed aftermath cells are separate; no reconstructed native final scene'},
        teamA={start=0,survivors=0,losses=0},teamB={start=0,survivors=0,losses=0},types={}}
    for _,u in ipairs(s.units) do
        local initial=self.initial[u.id];local unit=initial.native
        local hp=self.api.get('unitHp',unit);local alive=hp and hp>0
        local t=u.team==1 and out.teamA or out.teamB;t.start=t.start+1
        t[alive and 'survivors' or 'losses']=t[alive and 'survivors' or 'losses']+1
        local key=u.team..'_'..u.monster
        local kind=out.types[key] or {team=u.team,monster=u.monster,name=u.name,start=0,survivors=0,losses=0}
        out.types[key]=kind;kind.start=kind.start+1;kind[alive and 'survivors' or 'losses']=kind[alive and 'survivors' or 'losses']+1
        local kills=self.api.get('unitKills',unit)
        local x,y=self.api.get('unitBattleX',unit),self.api.get('unitBattleY',unit)
        local aftermath=self.aftermath[unit]
        local finalRow=captured[unit];local finalAnchor=finalRow and finalRow.anchorCount==1 and finalRow.anchors[1]
        if finalAnchor then out.summary.captured_original_position_count=out.summary.captured_original_position_count+1 end
        if x and y then out.summary.final_position_count=out.summary.final_position_count+1 end
        if aftermath then out.summary.aftermath_position_count=out.summary.aftermath_position_count+1 end
        out['unit'..u.id]={name=u.name,monster=u.monster,team=u.team,native=unit,hp=hp or 'unavailable',
            alive=alive and 1 or 0,final_owner=self.api.get('unitOwner',unit) or 'unavailable',
            x=x or 'unavailable',y=y or 'unavailable',
            aftermath_x=aftermath and aftermath.x or 'unavailable',aftermath_y=aftermath and aftermath.y or 'unavailable',
            captured_x=finalAnchor and finalAnchor.x or 'unavailable',captured_y=finalAnchor and finalAnchor.y or 'unavailable',
            kills_delta=kills and initial.kills and kills-initial.kills or 'unavailable',
            observed_direct_hp_loss=self.hooks.damage and self.hooks.attack and (self.direct[unit] or 0) or 'unavailable'}
    end
    if final then
        out.summary.final_snapshot_source=final.source;out.summary.final_snapshot_complete=final.complete and 1 or 0
        out.summary.final_scene_complete=0;out.summary.final_snapshot_units=#(final.units or {});out.summary.final_snapshot_cells=#(final.grid or {})
        out.summary.final_snapshot_exported_units=math.min(48,#(final.units or {}));out.summary.final_snapshot_issues=#(final.issues or {})
        out.summary.positions='Timed native unit/cell snapshot after aftermath, before upkeep/temporary-unit cleanup; return-time cells are separate; effects excluded'
        out.summary.final_snapshot_export_scope='At most 48 rows, actors before terrain; bounded export is not the complete capture'
        for i,row in ipairs(require('sandbox.final_view').exportUnits(final,48)) do
            local anchor=row.anchorCount==1 and row.anchors[1]
            out['final_unit'..i]={native=row.unit,generation=row.generation,kind=row.kind,monster=row.monster,owner=row.owner,hp=row.hp,
                x=anchor and anchor.x or 'off field or unavailable',y=anchor and anchor.y or 'off field or unavailable',
                width=row.width,height=row.height,status=row.status,created_during_fight=row.createdDuringFight and 1 or 0,
                owner_changed=row.ownerChanged and 1 or 0,monster_changed=row.monsterChanged and 1 or 0,
                current_hp=row.currentHP,current_monster=row.currentMonster,current_owner=row.currentOwner,inspectable=row.inspectable and 1 or 0,
                inspect_reason=row.inspectReason}
        end
    else out.summary.final_snapshot_reason=finalReason or 'API unavailable' end
    for key,count in pairs(self.itemSpellAttacks) do out['item_spell_attack_'..key]={count=count} end
    self.result=out;return out
end
function Report:export(name)
    if not self.result then return false end
    local out=M.copy(self.result);out.types=nil
    for key,row in pairs(self.result.types) do out['type_'..key]=M.copy(row) end
    return self.api.writeIni(name,out)
end
function Report:freeName(prefix)
    local used={}
    for _,name in ipairs(self.api.listIni()) do used[name:gsub('%.ini$',''):lower()]=true end
    for i=1,10000 do local name=prefix..'-'..i;if not used[name:lower()] then return name end end
end
function Report:archive()
    if not self.result then return nil,'No battle report is available.' end
    -- Preserve the legacy report left by an older Sandbox version before its
    -- compatibility filename is updated. Every new result also has its own file.
    local context=self.api.readIni('launcher-context')
    local session=context and context.environment and context.environment.session or 'local'
    session=tostring(session):gsub('[^%w%-]',''):sub(1,32)
    if session=='' then session='local' end
    if not self.legacyArchived then
        local previous=self.api.readIni('last-battle')
        if previous then
            local previousName=self:freeName('battle-previous-'..session)
            if not previousName or not self.api.writeIni(previousName,previous) then return nil,'Previous report could not be archived; last-battle was kept.' end
        end
        self.legacyArchived=true
    end
    local name=self:freeName('battle-'..session)
    if not name or not self:export(name) then return nil,'Report archive refused (file limit or quota); previous reports were kept.' end
    self.archiveName=name
    local legacy=self:export('last-battle')
    if legacy then return name end
    return name,'Archive saved; compatibility last-battle could not be updated.'
end
return Report
