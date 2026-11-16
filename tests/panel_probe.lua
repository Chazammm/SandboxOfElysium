-- Explicit native process acceptance; normal BAT startup never runs this file.
local P={}
function P.run(api,options)
    options=options or {};local M=require('sandbox.model');local C=require('sandbox.catalog')
    local R=require('sandbox.runtime');local D=require('sandbox.diagnostics');local L=require('sandbox.loadout')
    local U=require('sandbox.ui');local W=require('sandbox.config_window');local c=C.read(api)
    local context=api.readIni('launcher-context');local out={environment=M.copy(context and context.environment or {})}
    out.environment.scope='Actual isolated CoE5 native API and production Sandbox modules; not a UI click simulation'
    out.environment.sandbox_version=require('sandbox.version')
    local active,fatal
    local function save()assert(api.writeIni('panel-results',out))end
    local function flat(row)local copy={};for k,v in pairs(row)do if type(v)=='boolean'then copy[k]=v and 1 or 0 elseif type(v)~='table'then copy[k]=v end end;return copy end
    local function same(a,b)
        if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
        for k,v in pairs(a)do if not same(v,b[k])then return false end end
        for k in pairs(b)do if a[k]==nil then return false end end;return true
    end
    local function record(name,fn)
        if fatal then out[name]={status='NOT_RUN',detail='Earlier cleanup was not verified; restart required'};save();return end
        out.progress={case=name,status='RUNNING'};save()
        local ok,why=xpcall(fn,function(e)return tostring(e)end)
        if active then local closed,reason=active:close();active=nil;if not closed then fatal=true;ok=false;why='cleanup: '..tostring(reason)end end
        out[name]={status=ok and 'PASS' or 'FAIL',detail=ok and 'Native readback verified' or why};out.progress.status=ok and 'PASS' or 'FAIL';save()
    end
    local function open(scene)
        local r=R.new(api,c,D.new(api));active=r;local ok,why=r:build(scene);assert(ok,why);assert(r:ready(scene));return r
    end
    local function read(r,u)return assert(L.read(r,r.live[u.id]))end
    local function school(state,path)for _,row in ipairs(state.schools)do if row.path==path then return row end end end
    local function unique(label,data)
        local session=out.environment.session or 'unknown';local stem='panel-qa-'..session:sub(1,16)..'-'..label
        local used={};for _,name in ipairs(api.listIni())do used[name:gsub('%.ini$','')]=true end
        for i=1,1000 do if not used[stem..'-'..i]then local name=stem..'-'..i;assert(api.writeIni(name,data));return name end end
        error('No unused QA filename')
    end
    record('modded_item_and_spellschool_filters_use_observed_sources',function()
        assert(type(api.loadedContentOrigin)=='function','loaded provenance API missing')
        local crab;for _,item in ipairs(c.items)do if item.name=='Abyss Fragment'then crab=item end end;assert(crab)
        local origin=api.loadedContentOrigin('item',crab.id);out.crabcult_origin=flat(origin);save()
        assert(origin.observed and origin.modded and (origin.definedBy=='CrabCult' or origin.lastModifiedBy=='CrabCult'),'CrabCult item not attributed to its actual parser writer')
        local view={catalog=c,itemOrigin='modded',itemSearch='Abyss Fragment'};local items=W.items(view);assert(#items==1 and items[1].id==crab.id)
        local pathOrigin=api.loadedContentOrigin('spellschool',70);out.custom_school_origin=flat(pathOrigin);save()
        assert(pathOrigin.observed and pathOrigin.modded and pathOrigin.definedBy=='ZZZSandboxLoadoutFixture20261115','private custom school source missing')
        local combined=C.schoolOrigin(c,api,70);assert(combined.modded and combined.hasModSpells,'custom spells not associated by actual origin')
        local found=0;for _,spell in ipairs(c.spells)do if spell.path==70 and spell.name=='Sandbox Echo'then assert(spell.origin.modded and spell.origin.definedBy=='ZZZSandboxLoadoutFixture20261115');found=found+1 end end
        assert(found==2)
        local rows=W.magicRows({catalog=c,api=api},{known={},memorized={},schools={{path=39,name='Druidism',base=1},{path=70,name='Sandbox QA',base=1}}},
            {spellSearch='',schoolOrigin='modded',expanded={},schoolPages={}})
        local custom=false;for _,row in ipairs(rows)do if row.school.path==70 then custom=true end end;assert(custom)
        out.mod_filters={items=1,custom_school=70,duplicate_spells=found,source='Actual C5M writes and spell-path registration, never numeric ranges'}
    end)
    record('lower_levels_preserve_known_and_refuse_invalid_memorization',function()
        local s=M.new();local u=M.add(s,594,"Druid's Apprentice",1,8,9);M.add(s,953,'Goblin',2,20,9)
        local r=open(s);local initial=read(r,u);assert(school(initial,39).base==1)
        assert(L.setLevel(r,u,39,2));local before=read(r,u);assert(L.unlock(r,u,39));local unlocked=read(r,u)
        assert(same(before.memorized,unlocked.memorized),'Unlock all changed memorization')
        local known={};for _,id in ipairs(unlocked.known)do known[id]=true end
        local eligible,locked=0,0;local high
        for _,spell in ipairs(c.spells)do if spell.path==39 and spell.level>=1 then
            if spell.level<=2 then assert(known[spell.id],'eligible spell not unlocked');eligible=eligible+1
            elseif spell.level==3 then assert(not known[spell.id],'level3 spell was unlocked at base2');locked=locked+1;high=high or spell end
        end end
        assert(eligible>0 and locked>0 and high)
        assert(L.setLevel(r,u,39,3));assert(L.learn(r,u,high));assert(r:memorize(u,high.id..':'..high.name,true))
        before=read(r,u);local model=M.encode(s,c.mods);local ok,why=L.setLevel(r,u,39,2)
        assert(not ok and not r.blocked and same(before,read(r,u)) and same(model,M.encode(s,c.mods)),'unsafe downgrade changed configuration')
        assert(r:memorize(u,high.id..':'..high.name,false));assert(L.setLevel(r,u,39,2))
        local lower=read(r,u);known={};for _,id in ipairs(lower.known)do known[id]=true end
        assert(known[high.id] and school(lower,39).base==2,'downgrade erased higher known spell')
        for _,id in ipairs(initial.known)do assert(known[id],'original random spell erased')end
        out.unlock={path=39,eligible_level1_2=eligible,level3_still_locked=locked,memorized_unchanged=1,higher_known_retained=high.id,invalid_downgrade_reason=why}
    end)
    record('independent_multischool_levels_and_sandbox_labels',function()
        local s=M.new();s.allowMultipleUnique=true
        local a=M.add(s,141,'God Emperor',1,4,3);local b=M.add(s,141,'God Emperor',2,22,3)
        local druid=M.add(s,594,"Druid's Apprentice",1,8,12);M.add(s,953,'Goblin',2,20,12)
        local r=open(s);local original=read(r,a);local other=read(r,b);assert(#original.schools>=2 and original.maxBase>1)
        -- Explicit QA choices, never an automatic repair or random finalizer.
        for _,key in ipairs(M.copy(a.spells))do assert(r:memorize(a,key,false))end
        for _,row in ipairs(read(r,a).schools)do assert(L.setLevel(r,a,row.path,1))end
        local lower=read(r,a);assert(lower.maxBase==1 and lower.maxEffective==1,'aggregate reader retained a higher template level')
        assert(same(original.known,lower.known) and same(other,read(r,b)))
        for _,row in ipairs(lower.schools)do assert(row.base==1 and row.level==1 and row.templateBase==school(original,row.path).base)end
        assert(r:setLabel(a,'Bärensäule'));assert(not b.label and M.displayName(a)=='Bärensäule')
        assert(same(lower,read(r,a)) and same(other,read(r,b)),'Sandbox label changed native actors')
        local ui=U.new(api);ui.scenario=s;ui.runtime=r;ui.catalog=c;ui.phase='prepare';ui.selected=13;ui.filtered=C.filter(c,'','All')
        assert(W.open(ui,a));local w=ui.editWindow;local paths={}
        for _,row in ipairs(lower.schools)do w.expanded[row.path]=true;paths[#paths+1]=row.path end
        local rows=W.magicRows(ui,lower,w);local expanded=0;for _,row in ipairs(rows)do if row.kind=='unlock'then expanded=expanded+1 end end
        assert(expanded>=2);W.close(ui);ui.phase='menu'
        local item;for _,row in ipairs(c.items)do if row.id==153 then item=row end end;assert(item)
        local ds=read(r,druid);local pos;for _,row in ipairs(ds.items)do if row.slotType==7 and row.id<0 then pos=row.position;break end end
        assert(L.equip(r,druid,pos,item,-1));assert(L.setLevel(r,druid,39,2));assert(L.unlock(r,druid,39));assert(r:setLabel(druid,'Testdruide'))
        local file=unique('window',M.encode(s,c.mods));out.window_fixture={file=file,unit_id=a.id,label=a.label,other_unchanged=1,schools=#paths,base=1,druid_id=druid.id}
        local saved=M.encode(s,c.mods);assert(r:close());local decoded=assert(M.decode(api.readIni(file),c,c.mods));assert(r:build(decoded));assert(r:ready(decoded))
        assert(same(saved,M.encode(decoded,c.mods)));out.label_roundtrip={schema=saved.scenario.schema,label=decoded.units[1].label,other_unlabelled=decoded.units[2].label==nil and 1 or 0}
    end)
    record('configured_label_copy_move_save_load_fight_reset_rematch',function()
        local s=M.new();local u=M.add(s,594,"Druid's Apprentice",1,8,9);M.add(s,953,'Goblin',2,20,9)
        local r=open(s);assert(r:setLabel(u,'Bärenwächter'));assert(L.setLevel(r,u,39,2));assert(L.unlock(r,u,39))
        local item=c.byItemId[153];local state=read(r,u);local pos;for _,row in ipairs(state.items)do if row.slotType==7 and row.id<0 then pos=row.position;break end end
        assert(L.equip(r,u,pos,item,-1))
        local ok,nextScene,copy=r:add(s,u.monster,1,6,12,u);assert(ok,nextScene);s=nextScene;u=s.units[1]
        assert(copy.label==u.label and copy.id~=u.id and L.matches(r,copy,r.live[copy.id]));assert(r:move(u,8,8))
        local file=unique('battle',M.encode(s,c.mods));local loaded=assert(M.decode(api.readIni(file),c,c.mods));assert(r:close());assert(r:build(loaded));s=loaded
        local expected=M.encode(s,c.mods);local ui=U.new(api);ui.scenario=s;ui.runtime=r;ui.catalog=c;ui.phase='prepare';ui.selected=594;ui.filtered=C.filter(c,'','All')
        for cycle=1,2 do
            if options.onFight then options.onFight(true)end;assert(ui:fight());if options.onFight then options.onFight(false)end
            assert(api.get('battleRound')>0 and (api.get('battleWinner')==0 or api.get('battleWinner')==24),'fight did not finish naturally')
            assert(ui.report.result.unit1.sandbox_label=='Bärenwächter','Sandbox report lost label')
            out['label_fight'..cycle]={round=api.get('battleRound'),winner=api.get('battleWinner'),label=ui.report.result.unit1.sandbox_label,scope='Actual U.fight and U.reset; report navigation not clicked'}
            assert(ui:reset(cycle==2));assert(same(expected,M.encode(ui.scenario,c.mods)),'Reset/Rematch lost exact named configuration')
        end
        ui.phase='menu'
        out.persistence={file=file,copy=1,move=1,save_load=1,reset=1,rematch=1,label_scope='Sandbox display label; native card and native messages keep game name'}
    end)
    record('mod_school_selected_by_native_combat_and_restored',function()
        local s=M.new();local u=M.add(s,594,"Druid's Apprentice",1,8,9);M.add(s,953,'Goblin',2,14,9)
        local r=open(s);assert(L.setLevel(r,u,70,2));assert(L.unlock(r,u,70))
        -- Explicit QA selection: isolate the new path without replacing any random known spells.
        for _,key in ipairs(M.copy(u.spells))do assert(r:memorize(u,key,false))end
        local chosen={};for _,spell in ipairs(c.spells)do if spell.path==70 and spell.level<=2 then
            assert(r:memorize(u,spell.id..':'..spell.name,true));chosen[spell.id]=true
        end end
        local expected=M.encode(s,c.mods);local native=r.live[u.id];local picks,selected=0,0;local watching=false
        api.wrap('BATTLE_SPELL_PICK',function(next,unit,path,...)
            local spell=next(unit,path,...)
            if watching and unit==native and path==70 then picks=picks+1;if chosen[spell]then selected=selected+1 end end
            return spell
        end)
        local ui=U.new(api);ui.scenario=s;ui.runtime=r;ui.catalog=c;ui.phase='prepare';ui.selected=594;ui.filtered=C.filter(c,'','All')
        watching=true;if options.onFight then options.onFight(true)end;assert(ui:fight());if options.onFight then options.onFight(false)end;watching=false
        assert(api.get('battleRound')>0 and (api.get('battleWinner')==0 or api.get('battleWinner')==24),'mod-school battle did not finish naturally')
        out.mod_combat={round=api.get('battleRound'),winner=api.get('battleWinner'),path=70,native_path_picks=picks,selected_fixture_spell=selected,
            scope='Native spell selection returned actual mod spell IDs; not a complete per-effect damage trace'};save()
        assert(picks>0 and selected>0,'native combat did not select a configured mod-school spell')
        assert(ui:reset(false));assert(same(expected,M.encode(ui.scenario,c.mods)),'mod-school configuration changed after battle reset');ui.phase='menu'
    end)
    record('native_item_icons_fit_their_rectangles',function()
        local s=M.new();local u=M.add(s,594,"Druid's Apprentice",1,8,9);M.add(s,953,'Goblin',2,20,9);local r=open(s)
        local painting,done=false,false
        api.wrap('BATTLE_DRAW',function(next,...)
            local result=next(...);if painting then
                for i,id in ipairs({0,153})do local ok,rect=api.ui.drawItemSprite(40+i*40,100,32,28,id)
                    assert(ok and rect.width>0 and rect.height>0 and rect.x>=40+i*40 and rect.y>=100 and rect.x+rect.width<=72+i*40+0.001 and rect.y+rect.height<=128.001)
                    out['icon'..id]={source_width=rect.sourceWidth,source_height=rect.sourceHeight,width=rect.width,height=rect.height,sprite=rect.sprite}
                end
                done=true
            end;return result
        end)
        painting=true;api.drawTestField();painting=false;assert(done,'native drawing frame was not observed');assert(r:ready(s))
    end)
    out.complete={status='FINISHED',scope='Inspect each group; FINISHED alone does not mean all-pass'};save()
end
return P
