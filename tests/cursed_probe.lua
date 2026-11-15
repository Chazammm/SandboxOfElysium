-- Explicit private real-game acceptance; no production startup automation.
local P={}
function P.run(api,options)
    options=options or {};local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime')
    local D=require('sandbox.diagnostics');local L=require('sandbox.loadout');local U=require('sandbox.ui');local c=C.read(api)
    local context=api.readIni('launcher-context');local out={environment=M.copy(context.environment)};local active,fatal
    local function save()assert(api.writeIni('cursed-results',out))end
    local function same(a,b)
        if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
        for k,v in pairs(a)do if not same(v,b[k])then return false end end
        for k in pairs(b)do if a[k]==nil then return false end end;return true
    end
    local function test(name,fn)
        if fatal then out[name]={status='NOT_RUN',reason='Previous cleanup unverified'};save();return end
        out.progress={case=name,status='RUNNING'};save();local ok,why=xpcall(fn,tostring)
        if active then local closed,reason=active:close();active=nil;if not closed then fatal=true;ok=false;why='cleanup: '..tostring(reason)end end
        out[name]={status=ok and 'PASS' or 'FAIL',detail=ok and 'Actual native state and model verified' or why};out.progress.status=out[name].status;save()
    end
    local function open(s)
        local r=R.new(api,c,D.new(api));active=r;local ok,why=r:build(s)
        if not ok then
            out.open_failure={reason=why,detail=r.diag.lastError and r.diag.lastError.message or 'unknown',diagnostic=r.diag:export({fixture='cursed_replay_open'},r:snapshot(s))};save()
        end
        assert(ok,tostring(why)..' | '..tostring(r.diag.lastError and r.diag.lastError.message));assert(r:ready(s));return r
    end
    local function read(r,u)return assert(L.read(r,r.live[u.id]))end
    local function pos(state,kind)for _,row in ipairs(state.items)do if row.slotType==kind and row.id<0 then return row.position end end end
    local function split(s)local values={};for value in tostring(s or ''):gmatch('[^|]+')do values[#values+1]=value end;return values end
    local function saveUnique(label,s)
        local stem='cursed-qa-'..out.environment.session:sub(1,16)..'-'..label;local used={}
        for _,name in ipairs(api.listIni())do used[name:gsub('%.ini$','')]=true end
        for i=1,1000 do if not used[stem..'-'..i]then local name=stem..'-'..i;assert(api.writeIni(name,M.encode(s,c.mods)));return name end end
        error('No unused private scenario name')
    end
    local function userFixture()
        local diag=assert(api.readIni('user-cursed-replay'),'Private actual diagnostic fixture missing');local row=assert(diag.current_unit5)
        assert(row.name=='Arcane Frost Dragon' and tonumber(row.monster)==1830 and row.saved_item_positions=='6:185:Crystal Heart')
        local s=M.new();local u=M.add(s,tonumber(row.monster),row.name,1,tonumber(row.saved_x),tonumber(row.saved_y))
        local other=M.add(s,594,"Druid's Apprentice",1,3,12);M.add(s,953,'Goblin',2,22,9);local r=open(s)
        -- Seed the existing implant with the genuine native give API in this private
        -- fixture only; the production editor still refuses adding new implants.
        local hasHeart=false;for _,slot in ipairs(read(r,u).items)do if slot.id==185 then hasHeart=true end end
        if not hasHeart then assert(api.giveItem(r.live[u.id],'Crystal Heart'))end
        L.capture(r,u,read(r,u));r:observeSpellSelection(u,r.live[u.id])
        local position;for _,slot in ipairs(read(r,u).items)do if slot.id==185 then position=slot.position end end;assert(position~=nil)
        out.native_initial={position=position,items=table.concat(u.items,' | ')};save()
        u.baseline={known=split(row.saved_known)};u.spells=split(row.saved_memorized)
        u.equipment={{position=6,id=185,name='Crystal Heart'}};u.items={'Crystal Heart'}
        u.schools={};for value in row.saved_base_schools:gmatch('[^|]+')do local path,name,base=value:match('^(%d+):(.-):base=(%d+)$');assert(path);u.schools[#u.schools+1]={path=tonumber(path),name=name,base=tonumber(base)}end
        assert(L.configure(r,u,r.live[u.id],true));local good,state,details=r:check(s);assert(good,tostring(state));r:accept(s,state)
        position=6;assert(read(r,u).items[position+1].id==185)
        return r,s,u,other,row,position
    end
    test('actual_diagnostic_crystal_heart_large_unit_removal_and_persistence',function()
        local r,s,u,other,row,position=userFixture();local before=read(r,u);local untouched=read(r,other);local savedKnown=M.copy(u.baseline.known);local savedMem=M.copy(u.spells)
        assert(before.items[position+1].id==185 and before.items[position+1].cursed);assert(api.testFieldEditorCapabilities().cursedRemoval==1)
        local wanted=assert(L.wanted(r,u,before));wanted.items[position+1]=-1
        local ok,why,detail=api.setTestFieldConfiguration(r.live[u.id],wanted)
        assert(not ok and why=='cursed_item' and detail.rollbackVerified and same(before,read(r,u)),'ordinary API protection changed')
        wanted.removeCursed={position=position,item=184};ok,why=api.setTestFieldConfiguration(r.live[u.id],wanted)
        assert(not ok and why=='cursed_removal_changed' and same(before,read(r,u)),'stale removal accepted')
        wanted.removeCursed={position=position,item=185};wanted.items[position==0 and 2 or 1]=153;ok,why=api.setTestFieldConfiguration(r.live[u.id],wanted)
        assert(not ok and why=='cursed_removal_only' and same(before,read(r,u)),'compound removal accepted')
        assert(L.equip(r,u,position,nil,185));local after=read(r,u)
        assert(after.items[position+1].id==-1 and same(before.known,after.known) and same(before.memorized,after.memorized))
        assert(before.organInjuryFlags==after.organInjuryFlags,'permanent native injuries changed')
        assert(same(savedKnown,u.baseline.known) and same(savedMem,u.spells) and same(untouched,read(r,other)))
        local repeated,repeatWhy=L.equip(r,u,position,nil,185);assert(not repeated and repeatWhy:find('slot changed',1,true) and same(after,read(r,u)))
        local prohibited,implantWhy=L.equip(r,u,position,c.byItemId[185],-1)
        assert(not prohibited and implantWhy:find('permanent_anatomy_item_unsupported',1,true) and same(after,read(r,u)))
        assert(api.giveItem(r.live[u.id],'Crystal Heart'));assert(read(r,u).items[position+1].cursed,'item definition was globally uncursed')
        L.capture(r,u,read(r,u));r:observeSpellSelection(u,r.live[u.id]);local good,state=r:check(s);assert(good);r:accept(s,state)
        assert(L.equip(r,u,position,nil,185));assert(same(after,read(r,u)))
        assert(r:ready(s));local file=saveUnique('diagnostic-removed',s);local expected=M.encode(s,c.mods)
        assert(r:close());local restored=assert(M.decode(api.readIni(file),c,c.mods));assert(r:build(restored));assert(r:ready(restored))
        assert(same(expected,M.encode(restored,c.mods)) and read(r,restored.units[1]).items[position+1].id==-1)
        out.user_diagnostic={model_id_in_export=tonumber(row.model_id),native_id_in_export=tonumber(row.native_id),monster=u.monster,item=185,position=position,position_in_export=6,
            footprint=row.footprint_w..'x'..row.footprint_h,other_actor_unchanged=1,known_and_memorized_unchanged=1,file=file,
            live_organ_injuries_before=before.organInjuryFlags,live_organ_injuries_after=after.organInjuryFlags,
            new_actor_organ_injuries=read(r,restored.units[1]).organInjuryFlags,
            scope='Exact recorded target, position, equipment, base schools and ordered spells; own QA teammates, no inferred earlier clicks or unrecorded colors'}
    end)
    test('mod_bonus_removal_refuses_invalid_memorization_and_keeps_known',function()
        local monster=api.findMonster('Shell Priest');assert(c.byId[monster] and c.byId[monster].name=='Shell Priest','CrabCult fixture not active')
        local crab;for _,item in ipairs(c.items)do if item.name=='Abyss Fragment'then crab=item end end;assert(crab)
        local s=M.new();local u=M.add(s,monster,'Shell Priest',1,8,9);M.add(s,953,'Goblin',2,20,9);local r=open(s)
        local position=assert(pos(read(r,u),7));assert(L.equip(r,u,position,crab,-1))
        for _,key in ipairs(M.copy(u.spells))do assert(r:memorize(u,key,false))end
        local school;for _,row in ipairs(read(r,u).schools)do if row.path==4 then school=row end end;assert(school and school.base==1 and school.level==2)
        local high;for _,spell in ipairs(c.spells)do if spell.path==4 and spell.level==2 then high=spell;break end end;assert(high)
        local already=false;for _,key in ipairs(u.baseline.known)do if key==high.id..':'..high.name then already=true end end
        if not already then assert(L.learn(r,u,high))end;assert(r:memorize(u,high.id..':'..high.name,true))
        local before=read(r,u);local model=M.encode(s,c.mods);local ok,why=L.equip(r,u,position,nil,crab.id)
        assert(not ok and tostring(why):find('spell_level',1,true) and not r.blocked and same(before,read(r,u)) and same(model,M.encode(s,c.mods)))
        out.bonus_refusal={item=crab.id,spell=high.id,reason=why,rollback_verified=1}
        assert(r:memorize(u,high.id..':'..high.name,false));assert(L.equip(r,u,position,nil,crab.id))
        local after=read(r,u);assert(after.items[position+1].id==-1)
        local known=false;for _,id in ipairs(after.known)do if id==high.id then known=true end end;assert(known)
        for _,row in ipairs(after.schools)do if row.path==4 then assert(row.base==1 and row.level==1 and row.bonus==0)end end
        local file=saveUnique('mod-removed',s);assert(r:close());local restored=assert(M.decode(api.readIni(file),c,c.mods));assert(r:build(restored));assert(r:ready(restored))
        assert(L.matches(r,restored.units[1],r.live[restored.units[1].id]));out.mod_removed={file=file,item=crab.id,base=1,effective=1,higher_known_preserved=1}
    end)
    api.addMainMenuButton('Cursed diagnostic editor (private)',function()
        local r,s=userFixture();local ui=U.new(api);ui.catalog=c;ui.runtime=r;ui.scenario=s;ui.filtered=C.filter(c,'','All');ui.selected=nil
        ui:prepare(false,true);active=nil
    end)
    out.complete={status='FINISHED',scope='Each case above is authoritative; no automatic all-pass claim'};save()
end
return P
