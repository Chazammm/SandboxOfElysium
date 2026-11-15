-- Private explicit real-game probe; never installed by a default BAT launch.
local P={}
function P.run(api,options)
    options=options or {};local M=require('sandbox.model');local C=require('sandbox.catalog')
    local R=require('sandbox.runtime');local D=require('sandbox.diagnostics');local L=require('sandbox.loadout')
    local c=C.read(api);local out={environment={scope='actual isolated CoE5 native API; work in progress'}}
    local context=api.readIni('launcher-context')
    for k,v in pairs(context and context.environment or {})do out.environment[k]=v end
    out.environment.sandbox_version=require('sandbox.version')
    local function save()assert(api.writeIni('loadout-results',out))end
    local active
    local function record(name,fn)
        if options.only and options.only~=name then return end
        out.progress={case=name,status='RUNNING'};save()
        local ok,why=xpcall(fn,function(e)return tostring(e)end)
        if active then local closed,reason=active:close();active=nil;if not closed then ok=false;why='cleanup: '..tostring(reason)end end
        out[name]={status=ok and 'PASS' or 'FAIL',detail=ok and 'native API readbacks verified' or why};out.progress.status=ok and 'PASS' or 'FAIL';save()
    end
    record('vertical_item_school_native_readback',function()
        local s=M.new();local r=R.new(api,c,D.new(api));active=r;assert(r:build(s))
        local caster
        for _,m in ipairs(c.monsters)do if m.name:lower():find('apprentice',1,true)then
            local ok,scene,u=r:add(s,m.id,1,8,9);assert(ok,scene);s=scene
            local state=assert(L.read(r,r.live[u.id]))
            for _,school in ipairs(state.schools)do if school.base>=1 and school.base<3 then caster=u;break end end
            if caster then break end;local removed,nextScene=r:remove(s,u);assert(removed,nextScene);s=nextScene
        end end
        assert(caster,'No suitable loaded Apprentice caster found')
        local id=r.live[caster.id];local state=assert(L.read(r,id));local path
        for _,school in ipairs(state.schools)do if school.base<3 then path=school.path;out.caster={name=caster.name,monster=caster.monster,path=path,before_base=school.base};break end end
        assert(L.raise(r,caster,path));state=assert(L.read(r,id))
        for _,school in ipairs(state.schools)do if school.path==path then out.caster.after_base=school.base;out.caster.effective=school.level;out.caster.bonus=school.bonus;out.caster.allowance=school.allowance;assert(school.base==out.caster.before_base+1)end end
        local chosen
        for _,item in ipairs(c.items)do if item.name=='Amulet of Magic Resistance'then chosen=item;break end end
        if not chosen then for _,item in ipairs(c.items)do if item.slot==7 and not item.name:lower():find('eye',1,true) and not item.name:lower():find('heart',1,true)then chosen=item;break end end end
        assert(chosen,'No suitable loaded misc fixture')
        local position;for _,slot in ipairs(state.items)do if slot.slotType==chosen.slot and slot.id<0 then position=slot.position;break end end
        assert(position,'Caster has no empty compatible item slot')
        local ok,why=L.equip(r,caster,position,chosen,-1);assert(ok,why)
        state=assert(L.read(r,id));assert(state.items[position+1].id==chosen.id)
        out.item={id=chosen.id,name=chosen.name,position=position};assert(L.matches(r,caster,id));assert(r:ready(s))
        local data=M.encode(s,c.mods);local restored,reason=M.decode(data,c,c.mods);assert(restored,reason)
        local closed,reason=r:close();assert(closed,reason);assert(r:build(restored));assert(r:ready(restored))
        local restoredUnit=restored.units[1];assert(L.matches(r,restoredUnit,r.live[restoredUnit.id]))
        out.rebuild={schema=data.scenario.schema,base=restoredUnit.schools[1].base,equipped=#restoredUnit.equipment}
        local diag=r.diag:export({fixture='equipment_vertical'},r:snapshot(restored));out.diagnostic={name=diag or 'unavailable'}
    end)
    local function same(a,b)
        if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
        for k,v in pairs(a)do if not same(v,b[k])then return false end end
        for k in pairs(b)do if a[k]==nil then return false end end;return true
    end
    local function findItem(name)
        local found;for _,item in ipairs(c.items)do if item.name==name then assert(not found,'ambiguous fixture item');found=item end end
        return assert(found,'Loaded item fixture missing: '..name)
    end
    local function open(extra)
        local s=M.new();s.allowMultipleUnique=extra==true
        local u=M.add(s,594,"Druid's Apprentice",1,8,9);M.add(s,953,'Goblin',2,20,9)
        assert(c.byId[594].name==u.name and c.byId[953].name=='Goblin')
        local r=R.new(api,c,D.new(api));active=r;local ok,why=r:build(s);assert(ok,why);assert(r:ready(s));return r,s,u
    end
    local function native(r,u)return assert(L.read(r,assert(r.live[u.id])))end
    local function slots(state,kind)
        local out={};for _,slot in ipairs(state.items)do if slot.slotType==kind then out[#out+1]=slot.position end end;return out
    end
    local function saveUnique(label,data)
        local context=api.readIni('launcher-context');local session=context and context.environment and context.environment.session or 'local'
        session=tostring(session):gsub('[^%w%-]',''):sub(1,16)
        local used={};for _,name in ipairs(api.listIni())do used[name:gsub('%.ini$',''):lower()]=true end
        for i=1,1000 do local name='loadout-qa-'..session..'-'..label..'-'..i
            if not used[name:lower()]then assert(api.writeIni(name,data));return name end
        end;error('No unused QA filename available')
    end
    record('configuration_validation_and_lifecycle_guards',function()
        local r,s,u=open();local id=r.live[u.id];local before=native(r,u)
        local function reject(wanted,expected)
            local ok,why,detail=api.setTestFieldConfiguration(id,wanted)
            assert(not ok and why==expected and detail.rollbackVerified==true,tostring(why)..' instead of '..expected)
            assert(same(before,native(r,u)),'invalid request changed native configuration')
        end
        local wanted=assert(L.wanted(r,u,before));wanted.items[20]=nil;reject(wanted,'bad_item_positions')
        wanted=assert(L.wanted(r,u,before));wanted.schools={};reject(wanted,'missing_school_configuration')
        wanted=assert(L.wanted(r,u,before));wanted.schools[#wanted.schools+1]=M.copy(wanted.schools[1]);reject(wanted,'duplicate_school')
        wanted=assert(L.wanted(r,u,before));wanted.known[#wanted.known+1]=wanted.known[1];reject(wanted,'duplicate_spell')
        local ok,why=api.setTestFieldConfiguration(-1,{});assert(not ok and why=='bad_unit')
        local removed,nextScene=r:remove(s,u);assert(removed,nextScene);s=nextScene
        ok,why=api.setTestFieldConfiguration(id,{});assert(not ok and why~='bad_state','retired actor passed ownership/life guards')
        local value,reason=api.testFieldLoadoutState(id);assert(not value and reason)
        out.guard_results={invalid_requests_unchanged=1,retired_actor_reason=why,read_reason=reason}
        assert(r:ready(s))
    end)
    record('items_positions_replacement_incompatible_rollback',function()
        local r,s,u=open();local misc=slots(native(r,u),7);assert(#misc>=2)
        local first,second,replacement=findItem('Amulet of Anti Magic'),findItem('Amulet of Cold Resistance'),findItem('Amulet of Bear Control')
        assert(L.equip(r,u,misc[1],first,-1));assert(L.equip(r,u,misc[2],second,-1))
        local before=native(r,u);local originalKnown=M.copy(before.known);local originalMemorized=M.copy(before.memorized)
        local accepted,why=L.equip(r,u,misc[1],replacement,-1)
        assert(not accepted and same(before,native(r,u)),'stale expected slot identity was accepted')
        assert(L.equip(r,u,misc[1],replacement,first.id));local replaced=native(r,u)
        assert(replaced.items[misc[1]+1].id==replacement.id and replaced.items[misc[2]+1].id==second.id)
        local weapon=findItem('Frost Brand');assert(weapon.id==0,'ID-zero item fixture changed')
        local weapons=slots(replaced,1);assert(#weapons>=1)
        assert(L.equip(r,u,weapons[1],weapon,replaced.items[weapons[1]+1].id))
        before=native(r,u)
        accepted,why=L.equip(r,u,weapons[1],first,weapon.id)
        assert(not accepted and tostring(why):find('incompatible_slot',1,true) and same(before,native(r,u)),'incompatible item did not restore exact state')
        assert(not r.blocked and r:ready(s));assert(same(originalKnown,native(r,u).known) and same(originalMemorized,native(r,u).memorized))
        local implant
        if type(api.itemAbility)=='function'then for _,item in ipairs(c.items)do
            local ok,eye=pcall(api.itemAbility,item.id,0x1be);local ok2,heart=pcall(api.itemAbility,item.id,0x1bf)
            if (ok and type(eye)=='number' and eye>0) or (ok2 and type(heart)=='number' and heart>0)then implant=item;break end
        end end
        if implant then
            before=native(r,u);local available=slots(before,implant.slot)
            if #available>0 then
                accepted,why=L.equip(r,u,available[1],implant,before.items[available[1]+1].id)
                assert(not accepted and tostring(why):find('permanent_anatomy_item_unsupported',1,true) and same(before,native(r,u)))
                out.implant={id=implant.id,name=implant.name,result='explicit unsupported refusal; exact old state verified'}
            end
        end
        out.item_positions={first=misc[1],second=misc[2],replacement=replacement.id,weapon_id=weapon.id,weapon_position=weapons[1],exact_rejected_state=1}
        out.item_rejection_diagnostic={name=assert(r.diag:export({fixture='intentional_incompatible_equipment'},r:snapshot(s)))}
    end)
    record('school_limits_learning_random_spells_unchanged',function()
        local r,s,u=open();local before=native(r,u);local original=M.copy(before.known)
        local school;for _,row in ipairs(before.schools)do if row.path==39 then school=row end end;assert(school and school.base==1)
        assert(L.raise(r,u,39));assert(native(r,u).schools[1].base==2)
        assert(same(original,native(r,u).known),'raising a base school changed random starting spells')
        local briar;for _,spell in ipairs(c.spells)do if spell.id==350 and spell.path==39 and spell.name=='Briar Cage'then briar=spell end end;assert(briar)
        assert(L.learn(r,u,briar));assert(same(before.memorized,native(r,u).memorized),'learning auto-memorized a spell')
        assert(r:memorize(u,briar.id..':'..briar.name,true))
        local current=native(r,u);local memorized,known={},{}
        for _,id in ipairs(current.memorized)do memorized[id]=true end
        for _,id in ipairs(current.known)do known[id]=true end
        local tangle;for _,spell in ipairs(c.spells)do if spell.path==39 and spell.level>=1 and spell.level<=2 and not memorized[spell.id]then tangle=spell;break end end;assert(tangle)
        if not known[tangle.id]then assert(L.learn(r,u,tangle))end;before=native(r,u)
        local accepted,why=r:memorize(u,tangle.id..':'..tangle.name,true)
        assert(not accepted and same(before,native(r,u)),'fourth memorized school spell was not rejected unchanged')
        local high;for _,spell in ipairs(c.spells)do if spell.path==39 and spell.level==3 then high=spell;break end end;assert(high)
        accepted,why=L.learn(r,u,high);assert(not accepted and same(before,native(r,u)),'above-level spell changed configuration')
        assert(L.raise(r,u,39));assert(L.learn(r,u,high));assert(r:memorize(u,high.id..':'..high.name,true))
        before=native(r,u);accepted,why=L.raise(r,u,39);assert(not accepted and same(before,native(r,u)))
        local wanted=assert(L.wanted(r,u,before));for _,row in ipairs(wanted.schools)do if row.path==39 then row.level=4 end end
        accepted,why=api.setTestFieldConfiguration(r.live[u.id],wanted)
        assert(not accepted and why=='unsupported_school_level' and same(before,native(r,u)))
        assert(r:ready(s));out.magic={caster=u.name,path=39,base=3,original_known=#original,final_known=#before.known,final_memorized=#before.memorized,
            memorization_limit_rejected=1,above_level_rejected=1,level4_rejected=1,random_originals_preserved=1}
    end)
    record('multischool_unique_instances_independent',function()
        local s=M.new();s.allowMultipleUnique=true;local god=api.findMonster('God Emperor');assert(c.byId[god] and c.byId[god].name=='God Emperor')
        local u=M.add(s,god,'God Emperor',1,4,3);local other=M.add(s,god,'God Emperor',2,20,3)
        local r=R.new(api,c,D.new(api));active=r;assert(r:build(s));local before=native(r,u);local untouched=native(r,other)
        assert(#before.schools>=2 and r.live[u.id]~=r.live[other.id],'multi-school or independent unique fixture missing')
        local known={};for _,id in ipairs(before.known)do known[id]=true end
        local chosen
        for _,spell in ipairs(c.spells)do for _,school in ipairs(before.schools)do if spell.path==school.path and spell.level<=school.level and spell.level>=1 and not known[spell.id]then chosen=spell;break end end;if chosen then break end end
        assert(chosen);assert(L.learn(r,u,chosen));assert(same(untouched,native(r,other)),'learning changed another unique instance')
        assert(#native(r,u).known==#before.known+1 and same(before.memorized,native(r,u).memorized))
        out.multi_school={monster=god,name=u.name,schools=#before.schools,learned_id=chosen.id,learned_name=chosen.name,other_instance_unchanged=1}
        assert(r:ready(s))
    end)
    local activeFighter,spellPicks= nil,{}
    api.wrap('BATTLE_SPELL_PICK',function(next,unit,path)
        local spell=next(unit,path)
        if activeFighter and activeFighter[unit]then spellPicks[unit..':'..path..':'..tostring(spell)]=(spellPicks[unit..':'..path..':'..tostring(spell)]or 0)+1 end
        return spell
    end)
    record('copy_move_save_load_fight_reset_rematch_exact',function()
        local r,s,u=open();local misc=slots(native(r,u),7)
        assert(L.equip(r,u,misc[1],findItem('Amulet of Anti Magic'),-1));assert(L.equip(r,u,misc[2],findItem('Amulet of Cold Resistance'),-1))
        assert(L.raise(r,u,39));local briar;for _,spell in ipairs(c.spells)do if spell.id==350 then briar=spell end end
        assert(L.learn(r,u,assert(briar)));assert(r:memorize(u,'350:Briar Cage',true))
        local ok,nextScene,copy=r:add(s,u.monster,1,6,12,u);assert(ok,nextScene);s=nextScene
        u=s.units[1];assert(copy.id~=u.id and r.live[copy.id]~=r.live[u.id]);assert(L.matches(r,copy,r.live[copy.id]))
        assert(r:move(u,8,8));local saved=M.encode(s,c.mods);local filename=saveUnique('configured',saved)
        local decoded,why=M.decode(api.readIni(filename),c,c.mods);assert(decoded,why);assert(same(saved,M.encode(decoded,c.mods)))
        assert(r:close());assert(r:build(decoded));s=decoded;assert(r:ready(s))
        local expected=M.encode(s,c.mods);local readsBefore=native(r,s.units[1]).combatAttackReads
        for fight=1,2 do
            activeFighter={};for _,actor in ipairs(s.units)do if actor.monster==594 then activeFighter[r.live[actor.id]]=true end end
            local report=require('sandbox.report').new(api);report:start(s,r)
            if options.onFight then options.onFight(true)end;api.fightTestField();if options.onFight then options.onFight(false)end
            report:finish(s,r);r.phase='after';activeFighter=nil
            assert(api.get('battleRound')>0 and (api.get('battleWinner')==0 or api.get('battleWinner')==24),'battle did not finish naturally')
            local final=assert(api.testFieldFinalState());assert(final.complete and final.sceneComplete==false)
            out['configured_fight'..fight]={round=api.get('battleRound'),winner=api.get('battleWinner'),final_complete=1,report=assert(report:archive())}
            local refused,reason=api.setTestFieldConfiguration(r.live[s.units[1].id],{items={}});assert(not refused and reason=='final_read_only')
            local restore=M.copy(s);assert(r:close());assert(r:build(restore));s=restore;assert(r:ready(s))
            assert(same(expected,M.encode(s,c.mods)),'items, base levels or exact known/memorized lists changed on Reset/Rematch')
            for _,actor in ipairs(s.units)do assert(L.matches(r,actor,r.live[actor.id]))end
        end
        local readsAfter=native(r,s.units[1]).combatAttackReads;assert(readsAfter>readsBefore,'trained native combat attack reader was not exercised')
        local picks=0;for key,n in pairs(spellPicks)do picks=picks+n;out['cast_'..key:gsub(':','_')]={native_spell_picks=n}end
        assert(picks>0,'configured caster did not enter native battle spell selection')
        out.persistence={file=filename,exact_reset=1,exact_rematch=1,independent_copy=1,move=1,native_trained_attack_reads=readsAfter-readsBefore,native_spell_picks=picks}
    end)
    local crab
    for _,item in ipairs(c.items)do if item.name=='Abyss Fragment'then crab=item end end
    if crab then record('active_crabcult_item_cursed_guard_and_restore',function()
        local monster=api.findMonster('Shell Priest');assert(c.byId[monster] and c.byId[monster].name=='Shell Priest')
        local s=M.new();local u=M.add(s,monster,'Shell Priest',1,8,9);M.add(s,953,'Goblin',2,20,9)
        local r=R.new(api,c,D.new(api));active=r;assert(r:build(s));local original=native(r,u)
        local misc=slots(original,7);assert(L.equip(r,u,misc[1],crab,-1))
        local school
        for _,row in ipairs(native(r,u).schools)do if row.path==4 then school=row end end
        out.mod_bonus_observation={school_present=school and 1 or 0,base=school and school.base or 'none',bonus=school and school.bonus or 'none',effective=school and school.level or 'none'};save()
        assert(school and school.base==1 and school.bonus>0 and school.level==school.base+school.bonus,'mod item path bonus not represented separately')
        assert(L.raise(r,u,school.path));local trained
        for _,row in ipairs(native(r,u).schools)do if row.path==school.path then trained=row end end
        assert(trained.base==2 and trained.bonus==school.bonus and trained.level==2+school.bonus)
        assert(same(original.known,native(r,u).known) and same(original.memorized,native(r,u).memorized),'item or training replaced random spells')
        local before=native(r,u);assert(before.items[misc[1]+1].cursed==true)
        local wanted=assert(L.wanted(r,u,before));wanted.items[misc[1]+1]=-1
        local ok,why=api.setTestFieldConfiguration(r.live[u.id],wanted)
        assert(not ok and tostring(why):find('cursed_item',1,true) and same(before,native(r,u)),'default native cursed protection changed')
        local saved=M.encode(s,c.mods);assert(r:close());local restored=assert(M.decode(saved,c,c.mods));assert(r:build(restored));assert(r:ready(restored))
        local copy=restored.units[1];assert(L.matches(r,copy,r.live[copy.id]));out.mod_item={id=crab.id,name=crab.name,caster=u.name,monster=monster,path=trained.path,
            base=trained.base,bonus=trained.bonus,effective=trained.level,cursed_removal_rejected=1,exact_restore=1}
    end)else out.mod_item={status='NOT_RUN',reason='CrabCult item not active in this session'}end
    if options.fixture then record('custom_twenty_slots_mod_school_and_duplicate_names',function()
        local r,s,u=open();local value=native(r,u);local usable=0
        for _,slot in ipairs(value.items)do if slot.slotType>0 then usable=usable+1 end end;assert(usable==20,'private custom slot fixture did not load')
        assert(L.equip(r,u,19,findItem('Amulet of Anti Magic'),-1));assert(api.get('unitItem',r.live[u.id],19)==153)
        local school;for _,row in ipairs(native(r,u).schools)do if row.name=='Sandbox QA'then school=row end end;assert(school and school.base==1)
        local original=native(r,u);assert(L.raise(r,u,school.path))
        local echoes={};for _,spell in ipairs(c.spells)do if spell.name=='Sandbox Echo' and spell.path==school.path then echoes[#echoes+1]=spell end end
        assert(#echoes==2 and echoes[1].id~=echoes[2].id and c.spellNames['Sandbox Echo']==false,'duplicate mod spell identities missing')
        local known={};for _,id in ipairs(native(r,u).known)do known[id]=true end
        for _,spell in ipairs(echoes)do if not known[spell.id]then assert(L.learn(r,u,spell))end;assert(r:memorize(u,spell.id..':'..spell.name,true))end
        local wanted=M.encode(s,c.mods);local filename=saveUnique('custom',wanted);assert(r:close());local loaded=assert(M.decode(api.readIni(filename),c,c.mods));assert(r:build(loaded));assert(r:ready(loaded))
        local actor=loaded.units[1];assert(L.matches(r,actor,r.live[actor.id]));assert(api.get('unitItem',r.live[actor.id],19)==153)
        out.custom={positions=usable,last_item_position=19,last_item_id=153,school=school.name,path=school.path,base=2,
            duplicate_name='Sandbox Echo',first_id=echoes[1].id,second_id=echoes[2].id,other_school_original_level=original.schools[1].base,file=filename}
    end)end
    out.complete={status='FINISHED',scope='Each case is authoritative; FINISHED alone is not all-pass'};save()
end
return P
