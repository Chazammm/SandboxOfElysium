local M=require('sandbox.model')
local Catalog=require('sandbox.catalog')
local Runtime=require('sandbox.runtime')
local Report=require('sandbox.report')
local Diagnostics=require('sandbox.diagnostics')
local Preview=require('sandbox.preview')
local FinalView=require('sandbox.final_view')
local Loadout=require('sandbox.loadout')
local LoadoutUI=require('sandbox.loadout_ui')
local ConfigWindow=require('sandbox.config_window')
local Battlefields=require('sandbox.battlefields')
local ClearItems=require('sandbox.clear_items')
local U={};U.__index=U
local kinds={'Single','Horizontal Row','Vertical Row','Square'}
local categories={'All','human','animal','undead','demonic','flying','ranged','modded','unknown_origin'}
local categoryLabels={modded='Modded Units',unknown_origin='No mod definition'}
local function contains(t,v) for _,x in ipairs(t) do if x==v then return true end end;return false end
function U.new(api)
    local self=setmetatable({api=api,scenario=M.new(),team=1,formation=1,n=1,search='',category=1,page=1,
        phase='menu',message='',buttons={},lastMouse=0,pending=nil,native=false,context=nil},U)
    self.report=Report.new(api)
    self.diag=Diagnostics.new(api)
    self.drawHook=api.wrap('BATTLE_DRAW',function(next)
        local result=next()
        if not self.inNativeMenu and (self.phase=='prepare' or self.phase=='after') then
            self:draw()
            self.zoomAwaitingDraw=nil
        end
        return result
    end)
    self.waitHook=api.wrap('BATTLE_WAIT',function(next,b,m)
        local id=next(b,m)
        if not self.inNativeMenu and (self.phase=='prepare' or self.phase=='after') then
            self:wheelZoom()
            -- Native drawing is read only even before the original DRAW hook.
            -- Mutate in WAIT, then discard input until a fresh map is drawn.
            self:applyRequestedZoom()
            local engineButtons=api.get('mouseButtons') or 0
            if self.zoomAwaitingDraw then api.set('mouseButtons',engineButtons&4);return 0 end
            local buttons=engineButtons
            if type(api.testFieldPointerButtons)=='function' then buttons=api.testFieldPointerButtons() end
            if buttons==nil then
                self:setSearchFocus(false)
                api.set('mouseButtons',engineButtons&4)
                if self.runtime and self.runtime.quarantine then self.runtime:quarantine(self.scenario,'physical_pointer_unavailable',nil,{}) end
                return 0
            end
            if self.lastPhysicalButtons~=buttons then
                self.diag:record('input',{physical_buttons=buttons,engine_buttons=engineButtons,last_buttons=self.lastMouse,last_cell=self.lastCell or 'none',source=type(api.testFieldPointerButtons)=='function' and 'SDL' or 'legacy'})
                self.lastPhysicalButtons=buttons
            end
            local typing=self:searchEvents()
            local consumed=self:input(buttons)
            consumed=consumed or typing or self.searchFocused
            if consumed then api.set('mouseButtons',engineButtons&4);return 0 end
            return id
        end
        return id
    end)
    return self
end
function U:ensureCatalog()
    if self.catalog then return end
    self.catalog=Catalog.read(self.api);self.runtime=Runtime.new(self.api,self.catalog,self.diag)
    self.filtered=Catalog.filter(self.catalog,'','All');self.selected=self.api.findMonster('Spearman')
    local a=self.catalog.byId[self.selected];local b=self.catalog.byId[self.api.findMonster('Goblin')]
    if a and b then M.add(self.scenario,a.id,a.name,1,8,9);M.add(self.scenario,b.id,b.name,2,18,9) end
end
function U:prompt(title,prompt)
    self:setSearchFocus(false)
    local m=self.catalog.byId[self.selected] or self.catalog.monsters[1]
    return self.api.ui.nameBox(title,prompt,m.sprite,42)
end
function U:menu(title,rows)
    self:setSearchFocus(false)
    local ui=self.api.ui
    ui.screenBegin(title);ui.screenWidth(math.min(680,self.api.get('screenW')-30))
    local sectionOpen,buttonRow=false,false
    for _,row in ipairs(rows) do
        if row.section then
            if sectionOpen then ui.sectionEnd()end
            ui.sectionBegin(row.section);sectionOpen=true
        elseif row.buttonRow then
            if sectionOpen then ui.sectionEnd();sectionOpen=false end
            ui.buttonRow();buttonRow=true
        else
            if not sectionOpen and not buttonRow then ui.sectionBegin('');sectionOpen=true end
            ui.text(row[1],row[2])
        end
    end
    if sectionOpen then ui.sectionEnd()end
    ui.bindEscape(999);return ui.wait()
end
function U:notice(text,canExport)
    self:setSearchFocus(false)
    -- Keep map notices in its overlay; nested native editors need a synchronous
    -- dialog so their next menu iteration does not hide the message.
    if not self.inNativeMenu and self.runtime and self.runtime.open and (self.phase=='prepare' or self.phase=='after') then
        self.noticeText=text;self.noticeCanExport=canExport~=false;self.context=nil
        return
    end
    while true do
        local rows={{0,text},{1,'OK'}}
        if canExport~=false then rows[#rows+1]={2,'Export Diagnostics'} end
        local id=self:menu('SandboxOfElysium',rows)
        if id==1 or id==999 then return elseif id==2 then self:exportDiagnostics() end
    end
end
function U:exportDiagnostics()
    local selected=self.catalog and self.catalog.byId[self.selected]
    local generation=self.runtime and self.runtime.generation
    local preview,snapshot
    if generation~=nil and self.previewInfo and self.previewInfo.fieldGeneration==generation and self.phase=='prepare' and not self.inNativeMenu and not self.noticeText and
        not self:ownsPointer(self.api.get('uiPointerX'),self.api.get('uiPointerY')) then
        preview=self.previewInfo;snapshot='current'
    elseif generation~=nil and self.lastPreviewInfo and self.lastPreviewInfo.fieldGeneration==generation then
        preview=self.lastPreviewInfo;snapshot='last map hover'
    end
    self.diag:record('export_diagnostics',{phase=self.phase,team=self.team})
    local name,path=self.diag:export({terrain=self.scenario.terrain,team=self.team,phase=self.phase,
        selected=selected and selected.name or 'none',map_mode=self.native and 'native' or 'planning grid',
        preview_snapshot=snapshot or 'unknown',preview_field_generation=preview and preview.fieldGeneration or 'unknown',
        preview_anchor_x=preview and preview.anchorX or 'unknown',preview_anchor_y=preview and preview.anchorY or 'unknown',
        preview_monster=preview and preview.monster or 'unknown',
        preview_width=preview and preview.width or 'unknown',preview_height=preview and preview.height or 'unknown',
        preview_source=preview and preview.source or 'unavailable',preview_partial=1,
        preview_validity_source=preview and preview.validitySource or 'unavailable',
        preview_clear=preview and preview.clear or 'unknown',preview_blocked=preview and preview.blocked or 'unknown',
        preview_outside=preview and preview.outside or 'unknown'},self.runtime and self.runtime:snapshot(self.scenario))
    self:notice(name and 'Diagnostics saved: '..path..' | Upload this .ini or give Codex its path.' or path,false)
end
function U:setupRows()
    local s=self.scenario
    local locked=self.runtime.blocked
    local function count(team)local n=M.count(s,team);return n..(n==1 and ' unit' or ' units')end
    local change=locked and '' or ' (change)'
    local rows={{section=locked and 'Preserved setup' or 'Current setup'},
        {locked and 0 or 11,'Battlefield: '..(M.terrainNames[s.terrain] or 'Unknown')..change},
        {locked and 0 or 1,'Team A: '..count(1)..' | color: '..M.colors[s.colors[1]][1]..change},
        {locked and 0 or 2,'Team B: '..count(2)..' | color: '..M.colors[s.colors[2]][1]..change},
        {locked and 0 or 15,'Multiple unique units: '..(s.allowMultipleUnique and 'On' or 'Off')..(self:multipleUniqueAvailable() and '' or ' (API unavailable)')},
        {locked and 0 or 17,'Field size: '..Battlefields.sizeLabel(s)..change},
        {locked and 0 or 18,'New units: '..(s.startingItems==false and 'omit starting equipment' or 'normal starting equipment')..change}}
    if self.message and self.message~='' then rows[#rows+1]={0,self.message}end
    if self.runtime.blocked then
        rows[#rows+1]={0,'Editing locked. Saved setup preserved; export diagnostics before recovery.'}
        rows[#rows+1]={section='Recovery'};rows[#rows+1]={14,'Reopen preserved setup'}
    else
        rows[#rows+1]={section='Battlefield'}
        rows[#rows+1]={3,'Open battlefield / edit (keep positions)'}
        rows[#rows+1]={12,'Open with native deployment (reposition units)'}
        rows[#rows+1]={section='Scenarios'}
        rows[#rows+1]={4,'Load scenario'};rows[#rows+1]={10,'Save setup'}
        if self.snapshot then rows[#rows+1]={9,'Reset last pre-battle setup'}end
    end
    rows[#rows+1]={section='Tools'};rows[#rows+1]={13,'Export Diagnostics'}
    if self:hasSpellRepair() then rows[#rows+1]={16,'Repair saved spell selection (copy)'}end
    if not self.runtime.blocked then
        rows[#rows+1]={5,'Browse terrain data (read only)'};rows[#rows+1]={7,'Run small native battle check'}
        rows[#rows+1]={6,'API limitations'}
    end
    rows[#rows+1]={buttonRow=true};rows[#rows+1]={999,'Main menu'}
    return rows
end
function U:setup()
    self:ensureCatalog()
    while true do
        local s=self.scenario
        local available={};for id in pairs(self.catalog.testFieldTerrains) do available[#available+1]=id end;table.sort(available)
        local rows=self:setupRows()
        local id=self:menu('Sandbox - battlefield',rows)
        if id==999 then return end
        if id==11 then self:terrainPicker()
        elseif id==17 then self:sizePicker()
        elseif id==18 then self:toggleStartingItems()
        elseif id==1 or id==2 then s.colors[id]=s.colors[id]%7+1
        elseif id==15 then self:toggleMultipleUnique()
        elseif id==3 then
            self:prepare()
        elseif id==12 then
            self:prepare(true)
        elseif id==4 then self:load()
        elseif id==5 then self:terrainBrowser()
        elseif id==6 then self:notice('Verified neutral land fields only; other template contexts remain unverified. Size choices require the release-next API and are minimums. '..(Loadout.available(self.api) and 'Equipment and existing base schools up to level 3 are editable. New schools and eye/heart implants are unavailable. ' or 'Equipment and base-school editing need the newer experimental Extender. ')..'Modded Units means a mod-defined unit; modified vanilla units are not identified by that getter. Health/XP/injury-bit restoration needs the release-next API and remains a subset: effects, poison/bleeding and opaque native state are not saved. Complete battle telemetry is unavailable.')
        elseif id==7 then self:smallCheck()
        elseif id==9 and self.snapshot then self.scenario=M.copy(self.snapshot);self.message='Pre-battle setup selected; native restoration checked on Prepare'
        elseif id==10 then self:save()
        elseif id==13 then self:exportDiagnostics()
        elseif id==14 then
            local ok,candidate=self.runtime:recover()
            if ok then self.scenario=candidate;self:prepare(false,true) else self:notice(candidate) end
        elseif id==16 then if self:repairSpells() then self:prepare(false,true) end
        end
        if self.exitToMain then self.exitToMain=nil;return end
    end
end
function U:smallCheck()
    local s=M.new();M.add(s,self.api.findMonster('Spearman'),'Spearman',1,8,9);M.add(s,self.api.findMonster('Goblin'),'Goblin',2,18,9)
    M.add(s,self.api.findMonster('Goblin'),'Goblin',2,18,10)
    local old,oldSnapshot=self.scenario,self.snapshot;self.scenario=s
    local ok,why=self.runtime:build(s)
    local closed,closeWhy=true
    if ok then if self:fight() then self:postBattle() end;self:setSearchFocus(false);closed,closeWhy=self.runtime:close() else self:notice(why) end
    self.scenario=old;self.snapshot=oldSnapshot;self.phase='menu'
    if closed==false then self.exitToMain=nil;self:notice('Native cleanup was not verified: '..tostring(closeWhy)..'. Original setup and report kept. Export Diagnostics, then restart the isolated game.') end
end
function U:terrainPicker()
    while true do
        local rows={{0,'Only verified native contexts are playable. Template files and world terrains are separate.'},{section='Verified battlefields'}}
        local available={}
        for id in pairs(self.catalog.testFieldTerrains)do available[#available+1]=id end
        table.sort(available,function(a,b)return M.terrainNames[a]<M.terrainNames[b]end)
        if #available==0 then rows[#rows+1]={0,'No verified terrain API is available; the current selection is kept.'}end
        for i,id in ipairs(available)do rows[#rows+1]={100+i,(self.scenario.terrain==id and '[selected] 'or'')..M.terrainNames[id]}end
        rows[#rows+1]={section='Native catalogue'}
        rows[#rows+1]={1,'Installed battlefield templates (availability and limits)'}
        rows[#rows+1]={2,'Loaded world-terrain data (read only)'}
        rows[#rows+1]={999,'Back'}
        local id=self:menu('Battlefield presets',rows)
        if id==999 then return
        elseif id==1 then self:templateCatalogue()
        elseif id==2 then self:terrainBrowser()
        elseif available[id-100]then
            self.scenario.terrain=available[id-100]
            self.message='Terrain changed. Keep positions verifies exact cells; native deployment explicitly repositions units.'
            self.diag:record('terrain',{terrain=self.scenario.terrain,scope='verified native terrain/template context'});return
        end
    end
end
function U:templateCatalogue()
    local templates=self.catalog.environment and self.catalog.environment.templates
    if type(templates)~='table'then self:notice('The installed-template catalogue needs the separate release-next environment API. No additional preset is advertised.');return end
    local page=1
    while true do
        local rows={{0,#templates..' stock template names examined; a file is not proof of a playable native context.'},
            {0,'Sieges, water, other planes and unlisted variants remain unavailable.'},
            {section='Templates: page '..page..' / '..math.max(1,math.ceil(#templates/6))}}
        for i=(page-1)*6+1,math.min(page*6,#templates)do local row=templates[i]
            rows[#rows+1]={0,row.name..' | '..(row.installed and ('stored canvas '..tostring(row.storedWidth)..' x '..tostring(row.storedHeight))or'not installed')}
            rows[#rows+1]={0,row.verifiedContext and 'Playable via verified presets only; other variants remain unverified.'or'Unavailable: native context or exact restoration is not verified.'}
        end
        rows[#rows+1]={1,'Previous'};rows[#rows+1]={2,'Next'};rows[#rows+1]={999,'Back'}
        local id=self:menu('Native template catalogue (read only)',rows)
        if id==999 then return elseif id==1 then page=math.max(1,page-1)elseif id==2 then page=math.min(math.max(1,math.ceil(#templates/6)),page+1)end
    end
end
function U:sizePicker()
    while true do
        local rows={{0,'Sandbox minimums, not native preset names. All fields have 20 rows.'},
            {0,'Native army/map requirements can enlarge a minimum; existing saved cells are never silently moved.'},
            {section='Field size'}}
        for i,row in ipairs(Battlefields.sizes)do
            local label=row.name..(row.columns and (' | minimum '..row.columns..' x 20')or'')
            rows[#rows+1]={i,label..(Battlefields.sizeAvailable(self.catalog,row)and''or' (API unavailable)')}
        end
        rows[#rows+1]={999,'Back'}
        local id=self:menu('Battlefield size',rows)
        if id==999 then return end
        local row=Battlefields.sizes[id]
        if row then
            local ok,why=Battlefields.selectSize(self.catalog,self.scenario,row)
            if not ok then self:notice(why)else
                self.message='Size selected. Open checks exact positions; native deployment explicitly repositions units.'
                self.diag:record('field_size',{minimum_width=row.columns or 0,policy='native automatic expansion retained'});return
            end
        end
    end
end
function U:terrainBrowser()
    local page=1
    while true do
        local rows={{0,'Verified maps are selectable in Battlefield. This terrain catalog is read only.'}}
        for i=(page-1)*8+1,math.min(page*8,#self.catalog.terrains) do local t=self.catalog.terrains[i]
            rows[#rows+1]={0,('#%d %s | batmap %s'):format(t.id,t.name,tostring(t.batmap))}
        end
        rows[#rows+1]={1,'Previous'};rows[#rows+1]={2,'Next'};rows[#rows+1]={999,'Back'}
        local id=self:menu('Terrain data',rows)
        if id==999 then return elseif id==1 then page=math.max(1,page-1) elseif id==2 then page=math.min(math.ceil(#self.catalog.terrains/8),page+1) end
    end
end
function U:refresh()
    self.filtered=Catalog.filter(self.catalog,self.search,categories[self.category])
    self.page=math.max(1,math.min(self.page,math.max(1,math.ceil(#self.filtered/5))))
end
function U:setSearchFocus(on,target)
    if not on then
        if type(self.api.setTestFieldTextFocus)=='function' then self.api.setTestFieldTextFocus(false) end
        if self.searchFocused then self.dragBlocked=true end
        self.searchFocused=false;self.textTarget=nil;return true
    end
    if self.phase~='prepare' or self.runtime.blocked or self.noticeText then return false end
    if type(self.api.setTestFieldTextFocus)~='function' or type(self.api.takeTestFieldTextEvents)~='function' then
        self.message='Inline search requires the experimental text-input API. No popup is opened.';return false
    end
    local ok,why=self.api.setTestFieldTextFocus(true)
    self.searchFocused=ok and true or false
    self.textTarget=self.searchFocused and (target or (self.catalogTab=='items' and 'items' or 'units')) or nil
    if not ok then self.message='Inline search unavailable: '..tostring(why or 'unknown reason')
    else self.context=nil;self.moving=nil;self.copyTemplate=nil;self.message=self.textTarget=='label' and 'Sandbox label: type to update; native name stays unchanged.' or 'Type to filter; Backspace deletes, Clear resets, Enter/Escape leaves search.' end
    return self.searchFocused
end
function U:searchEvents()
    if not self.searchFocused or type(self.api.takeTestFieldTextEvents)~='function' then return false end
    local packet=self.api.takeTestFieldTextEvents()
    if type(packet)~='table' then self:setSearchFocus(false);self.message='Inline input state unavailable; search focus released.';return true end
    local changed=false;local focusTarget=self.textTarget
    for _,event in ipairs(packet.events or {}) do
        if (self.textTarget=='label' or self.textTarget=='spells' or self.textTarget=='native_name') and (event.type=='text' or event.type=='backspace' or event.type=='clear') then
            ConfigWindow.text(self,event)
        elseif event.type=='text' and type(event.text)=='string' then
            local text=event.text:gsub('[%z\1-\31\127]','')
            local valid=true
            if utf8 then local ok,length=pcall(utf8.len,text);valid=ok and length~=nil end
            if valid then if self.textTarget=='items' then self.itemSearch=Catalog.textLimit((self.itemSearch or '')..text,96)else self.search=Catalog.textLimit(self.search..text,96)end;changed=true end
        elseif event.type=='backspace' then if self.textTarget=='items'then self.itemSearch=Catalog.backspace(self.itemSearch or '')else self.search=Catalog.backspace(self.search)end;changed=true
        elseif event.type=='clear' then if self.textTarget=='items'then self.itemSearch=''else self.search=''end;changed=true
        elseif event.type=='submit' or event.type=='cancel' or event.type=='blur' then self:setSearchFocus(false) end
    end
    if changed then
        if focusTarget=='items'then self.itemPage=1;ConfigWindow.items(self)else self.page=1;self:refresh()end
        self.diag:record('search',{query_length=focusTarget=='items' and #(self.itemSearch or '')or #self.search,matches=focusTarget=='items' and #self.filteredItems or #self.filtered,source='inline_utf8',catalog=focusTarget or 'units'})
    end
    if packet.focused==false then self:setSearchFocus(false) end
    if packet.overflow then self:setSearchFocus(false);self.message='Input queue overflow: search focus released. Click search to continue.' end
    return true
end
function U:multipleUniqueAvailable()
    if type(self.api.testFieldEditorCapabilities)~='function' then return false end
    local ok,caps=pcall(self.api.testFieldEditorCapabilities)
    return ok and type(caps)=='table' and (caps.multipleUnique==1 or caps.multipleUnique==true) and
        (caps.multipleUniquePolicy==1 or caps.multipleUniquePolicy==true) and type(self.runtime.setMultipleUnique)=='function'
end
function U:zoomAvailable()
    if type(self.api.testFieldZoom)~='function' or type(self.api.setTestFieldZoom)~='function' or type(self.api.testFieldEditorCapabilities)~='function' then return false end
    local ok,caps=pcall(self.api.testFieldEditorCapabilities)
    return ok and type(caps)=='table' and (caps.battleZoom==1 or caps.battleZoom==true)
end
function U:zoomState()
    if not self:zoomAvailable() then return nil,'Native battlefield zoom needs the updated experimental API.' end
    local ok,state,why=pcall(self.api.testFieldZoom)
    if not ok or type(state)~='table' then return nil,tostring(why or (not ok and state) or 'Native zoom readback is unavailable.') end
    for _,key in ipairs({'zoom','minZoom','maxZoom','cellSize'}) do
        local value=state[key]
        if type(value)~='number' or value~=value or value==math.huge or value==-math.huge then return nil,'Native zoom readback is incomplete.' end
    end
    if state.minZoom<=0 or state.maxZoom<state.minZoom or state.zoom<state.minZoom or state.zoom>state.maxZoom or state.cellSize<=0 then return nil,'Native zoom readback is invalid.' end
    return state
end
function U:requestZoom(direction,x,y)
    if self.phase~='prepare' or not self.native or not self.runtime.open or self.runtime.blocked then return false end
    local state,why=self:zoomState();if not state then self:notice(why);return false end
    local target=math.max(state.minZoom,math.min(state.maxZoom,(self.requestedZoom or state.zoom)+direction*0.1))
    self.requestedZoom=target
    self.requestedZoomAnchor=x and y and {x=x,y=y} or nil
    self.releaseBarrier=true;self.dragBlocked=true;self.lastCell=nil;self.dragOrigin=nil
    return true
end
function U:wheelZoom()
    if type(self.api.testFieldPointerWheel)~='function' or not self.runtime or not self.runtime.open or self.phase~='prepare' then self.lastWheel=nil;return end
    local ok,current=pcall(self.api.testFieldPointerWheel)
    if not ok or type(current)~='number' or current%1~=0 then self.lastWheel=nil;return end
    local previous=self.lastWheel;self.lastWheel=current
    if previous==nil then return end
    local delta=(current-previous+0x80000000)%0x100000000-0x80000000
    if delta==0 then return end
    -- Every sample advances the baseline, including blocked/UI scrolls. They
    -- must never be replayed later when the pointer returns to the map.
    local x,y=self.api.get('uiPointerX'),self.api.get('uiPointerY')
    if self.inNativeMenu or self.noticeText or self.searchFocused or self.editWindow or self.equipDialog or self.context or self.finalContext or
        self.runtime.blocked or self.releaseBarrier or self:ownsPointer(x,y) then return end
    local buttons=self.api.testFieldPointerButtons and self.api.testFieldPointerButtons() or self.api.get('mouseButtons') or 0
    if buttons==nil or buttons&7~=0 then return end
    self:requestZoom(math.max(-5,math.min(5,delta)),x,y)
end
function U:applyRequestedZoom()
    if self.phase~='prepare' or self.inNativeMenu or not self.native or not self.runtime or not self.runtime.open or self.runtime.blocked or not self:zoomAvailable() then return end
    if self.zoomAwaitingDraw then return end
    local generation=self.runtime.generation
    if generation~=nil and self.zoomGeneration~=generation then
        self.zoomGeneration=generation
        if self.requestedZoom==nil then self.requestedZoom=self.zoom or 1 end
    end
    if self.requestedZoom==nil then return end
    local requested=self.requestedZoom;local anchor=self.requestedZoomAnchor;self.requestedZoom=nil;self.requestedZoomAnchor=nil
    self.releaseBarrier=true;self.dragBlocked=true;self.lastCell=nil;self.dragOrigin=nil;self.zoomAwaitingDraw=true
    local state,why=self:zoomState()
    if not state then self.message=why;self:notice(why);return end
    requested=math.max(state.minZoom,math.min(state.maxZoom,requested))
    local called,accepted,reason=pcall(self.api.setTestFieldZoom,requested,anchor and anchor.x or (self.api.get('screenW')-310)/2,anchor and anchor.y or self.api.get('screenH')/2)
    if not called or accepted~=true then
        why=tostring(reason or (not called and accepted) or 'Native zoom was refused.')
        self.message='Zoom unchanged: '..why;self:notice(self.message)
        self.diag:record('battle_zoom',{result='refused',requested=requested,reason=why})
        return
    end
    local observed;observed,why=self:zoomState()
    if not observed then self.message='Native zoom readback could not be verified: '..why;self:notice(self.message);return end
    self.zoom=observed.zoom;self.zoomGeneration=generation
    self.message=('Native zoom: %d%%'):format(math.floor(observed.zoom*100+0.5))
    self.diag:record('battle_zoom',{result='native readback verified',requested=requested,zoom=observed.zoom,cell_size=observed.cellSize,field_generation=generation or 'unknown'})
end
function U:toggleStartingItems()
    if self.runtime.blocked then return false end
    self.scenario.startingItems=self.scenario.startingItems==false
    self.message='Starting equipment policy affects new placements only. Existing units, copies and restored configurations stay unchanged.'
    self.diag:record('starting_items',{enabled=self.scenario.startingItems and 1 or 0,scope='new units only'})
    return true
end
function U:clearAllHeldItems()
    self:setSearchFocus(false);self.context=nil;self.moving=nil;self.copyTemplate=nil;self.pending=nil
    self.releaseBarrier=true;self.dragBlocked=true;self.lastCell=nil;self.dragOrigin=nil
    local plan,why=ClearItems.plan(self.runtime,self.scenario)
    if not plan then self:notice(why);return false end
    if plan.items==0 then self.message='Both teams already have no held items.';return true end
    local previous=self.inNativeMenu;self.inNativeMenu=true
    local id=self:menu('Clear All Held Items',{
        {0,('Both teams: %d actors holding %d items (A: %d actors; B: %d actors).'):format(#plan.actors,plan.items,plan.teamA,plan.teamB)},
        {0,('Includes all held equipment, %d cursed items and %d implanted items.'):format(plan.cursed,plan.implanted)},
        {0,'Existing injuries and permanent anatomical damage are NOT healed.'},
        {0,'Spells, names, positions and teams must stay unchanged.'},
        {0,'Each actor is verified separately. A failure stops the operation; completed actors stay cleared.'},
        {1,'Confirm - clear all held items on both teams'},
        {999,'Cancel - keep all held items'}})
    self.inNativeMenu=previous;self.releaseBarrier=true;self.dragBlocked=true;self.lastCell=nil;self.dragOrigin=nil
    if id~=1 then self.message='Clear All Held Items cancelled; equipment kept.';return false end
    local result=ClearItems.run(self.runtime,self.scenario,plan)
    self.message=ClearItems.describe(result)
    self.diag:record('clear_all_held_items',{result=result.ok and 'verified' or 'stopped',actors_total=result.total,
        actors_completed=result.completed,items_removed=result.removed,actors_remaining=result.remaining,
        failed_model_id=result.failed and result.failed.model_id or 'none',failed_native_id=result.failed and result.failed.native_id or 'none',
        failed_actor_rollback=result.ok and 'not needed' or result.rollbackVerified and 'verified unchanged' or 'unverified',reason=result.reason or 'none'})
    self:notice(self.message)
    return result.ok
end
function U:toggleMultipleUnique()
    if not self:multipleUniqueAvailable() then self:notice('Changing the unique-unit policy needs the updated experimental API. Current setup kept.');return false end
    local ok,why=self.runtime:setMultipleUnique(self.scenario,not self.scenario.allowMultipleUnique)
    if not ok then self.message=why;self:notice(why);return false end
    self.message='Allow multiple unique units: '..(self.scenario.allowMultipleUnique and 'On' or 'Off')..'. Battlefield kept.'
    self.diag:record('multiple_unique',{enabled=self.scenario.allowMultipleUnique and 1 or 0,scope='policy only; no rebuild'})
    return true
end
function U:browse()
    self:setSearchFocus(true)
end
function U:hasSpellRepair()
    return self.runtime and type(self.runtime.spellRepairProblems)=='table' and next(self.runtime.spellRepairProblems)~=nil and
        type(self.runtime.spellRepairCandidates)=='function' and type(self.runtime.repairSpellSelection)=='function'
end
function U:repairSpellUnit(candidate,problem)
    local unit
    for _,u in ipairs(candidate.units) do if u.id==problem.model_id then unit=u;break end end
    if not unit then self:notice('The preserved unit is missing from this copy. Original recovery kept.');return end
    local page=1;local known=problem.known
    while true do
        local rows={{0,'Edit memorized spells in the copy. Known spells and original recovery stay unchanged.'}}
        for _,school in ipairs(problem.schools) do
            local count=0
            for _,key in ipairs(unit.spells) do
                local id=tonumber(key:match('^(%d+):'));local info=id and self.api.spellInfo(id)
                if info and info.path==school.path then count=count+1 end
            end
            rows[#rows+1]={0,tostring(school.name)..': '..count..' selected / native allowance '..school.allowance}
        end
        for i=(page-1)*8+1,math.min(page*8,#known) do local key=known[i]
            rows[#rows+1]={100+i,(contains(unit.spells,key) and '[x] ' or '[ ] ')..key}
        end
        rows[#rows+1]={1,'Previous page'};rows[#rows+1]={2,'Next page'};rows[#rows+1]={999,'Back to repaired copy'}
        local id=self:menu('Repair '..problem.name..' #'..problem.model_id,rows)
        if id==999 then return
        elseif id==1 then page=math.max(1,page-1)
        elseif id==2 then page=math.min(math.max(1,math.ceil(#known/8)),page+1)
        elseif known[id-100] then
            local key=known[id-100]
            if contains(unit.spells,key) then for i=#unit.spells,1,-1 do if unit.spells[i]==key then table.remove(unit.spells,i) end end
            else unit.spells[#unit.spells+1]=key end
        end
    end
end
function U:repairSpells()
    self:setSearchFocus(false);self.context=nil;self.moving=nil;self.pending=nil
    if not self:hasSpellRepair() then self:notice('No verified spell-repair diagnosis is available. Original setup kept.');return false end
    local candidate=M.copy(self.runtime.spellRepairScenario or self.runtime.recovery or self.scenario)
    local problems,why=self.runtime:spellRepairCandidates(candidate)
    if type(problems)~='table' or #problems==0 then self:notice(why or 'No invalid memorization was identified. Original setup kept.');return false end
    self.inNativeMenu=true
    local function finish(ok)
        self.inNativeMenu=false;self.releaseBarrier=true;self.dragBlocked=true;self.lastCell=nil;self.dragOrigin=nil
        return ok
    end
    while true do
        local rows={{0,'Original recovery remains unchanged. Edit a copy only.'},
            {0,'No spells are removed automatically. Cancel keeps the original.'},
            {0,'Verification uses native school limits; an invalid copy is rejected.'}}
        for i,problem in ipairs(problems) do
            local count=0;for _,u in ipairs(candidate.units) do if u.id==problem.model_id then count=#u.spells end end
            rows[#rows+1]={100+i,problem.name..' #'..problem.model_id..' | '..count..' selected spells (click to edit)'}
            for _,school in ipairs(problem.schools) do
                rows[#rows+1]={0,'Original '..tostring(school.name)..': '..school.selected_count..' selected / native allowance '..school.allowance}
            end
        end
        rows[#rows+1]={1,'Verify repaired copy and save separately'};rows[#rows+1]={999,'Cancel - keep original recovery'}
        local id=self:menu('Repair saved spell selection',rows)
        if id==999 then return finish(false)
        elseif problems[id-100] then self:repairSpellUnit(candidate,problems[id-100])
        elseif id==1 then
            local ok,verified,details=self.runtime:repairSpellSelection(candidate)
            if ok then
                self.scenario=verified;self.snapshot=M.copy(verified);self.phase='prepare';self.native=type(self.api.battleView)=='function'
                self.noticeText=nil;self.copyTemplate=nil
                self.message='User-selected repaired copy verified; original recovery and report kept. Saved: '..tostring(details and (details.path or details.name) or 'unknown')
                self.diag:record('spell_repair',{result='verified user-selected copy',original_preserved=1,units=#verified.units})
                return finish(true)
            end
            self:notice(tostring(verified)..' Original recovery kept; this copy is still available for editing.')
            -- Validation may identify another independently configured caster.
            -- Keep the user's copy edits while exposing the newly diagnosed row.
            local updated=self.runtime:spellRepairCandidates(candidate)
            if type(updated)=='table' and #updated>0 then problems=updated end
        end
    end
end
function U:button(key,label,x,y,w,h,color,font)
    local ui=self.api.ui;color=color or {0.15,0.19,0.23}
    font=font or 13
    ui.drawRect(x,y,w,h,color[1],color[2],color[3],0.97)
    ui.drawText(x+5,y+(h-font)/2,font,label,0.96,0.96,0.90,1)
    self.buttons[#self.buttons+1]={key=key,x=x,y=y,w=w,h=h}
end
function U:unitAt(x,y)
    if type(self.api.battleUnitAt)=='function' and self.runtime.open then
        local unit=self.api.battleUnitAt(x,y)
        local found
        if unit and unit>=0 and (self.api.get('unitHp',unit) or 0)>0 then
            for _,u in ipairs(self.scenario.units) do if self.runtime.live[u.id]==unit then if found then return end;found=u end end
        end
        return found
    end
    if self.native then return end
    return M.at(self.scenario,x,y)
end
function U:placementFootprint()
    local source=self.moving or self.copyTemplate
    local monster=source and source.monster or self.selected
    local unit=source and self.runtime.live[source.id] or nil
    if type(self.api.testFieldFootprint)~='function' then return nil,'Footprint API unavailable' end
    local ok,footprint,why=pcall(self.api.testFieldFootprint,monster,unit)
    if not ok then return nil,'Footprint query failed' end
    if type(footprint)~='table' or footprint.anchor~='positive_xy' or not Preview.anchors('Single',1,0,0,footprint.width,footprint.height) then
        return nil,tostring(why or 'Native footprint unavailable')
    end
    if source and not self.moving and footprint.monster~=source.monster then return nil,'Copy source transformed; its saved model must be verified first' end
    footprint.requestedMonster=monster;footprint.unit=unit
    return footprint
end
function U:placementAnchors(x,y,footprint)
    footprint=footprint or self:placementFootprint()
    if not footprint then
        if self.formation==1 then return {{x=x,y=y}} end
        return nil,'Large-unit formation spacing requires the read-only native footprint API.'
    end
    return Preview.anchors(self.moving and 'Single' or kinds[self.formation],self.n,x,y,footprint.width,footprint.height)
end
function U:placementPreview(x,y)
    local footprint,why=self:placementFootprint()
    if not footprint then return {cells={},label='Footprint unknown: '..tostring(why)..'; native placement decides.',partial=true,anchorX=x,anchorY=y,fieldGeneration=self.runtime.generation} end
    if self.dragOrigin and self.lastMouse&2~=0 and not self.moving then x,y=Preview.snap(x,y,self.dragOrigin,self.dragOrigin.stepX,self.dragOrigin.stepY) end
    local anchors=self:placementAnchors(x,y,footprint)
    local plan={cells={},monster=footprint.monster,width=footprint.width,height=footprint.height,source=footprint.source,
        partial=true,clear=0,blocked=0,outside=0,unknown=0,anchors=anchors,preflightAccepted=0,anchorX=x,anchorY=y,fieldGeneration=self.runtime.generation}
    for _,anchor in ipairs(anchors) do
        local row
        if type(self.api.testFieldPlacementPreflight)=='function' then
            local ok,value=pcall(self.api.testFieldPlacementPreflight,footprint.monster,anchor.x,anchor.y,footprint.unit,self.moving~=nil)
            if ok and type(value)=='table' and value.width==footprint.width and value.height==footprint.height then row=value end
        end
        local native={}
        if row then
            plan.preflightAccepted=plan.preflightAccepted+1
            for _,cell in ipairs(row.cells or {}) do native[cell.x..':'..cell.y]=cell end
        end
        for _,cell in ipairs(Preview.cells({anchor},footprint.width,footprint.height)) do
            local observed=native[cell.x..':'..cell.y]
            if observed then cell.status=observed.status;cell.screenX=observed.screenX;cell.screenY=observed.screenY end
            if not cell.status then
                cell.status=(cell.x<0 or cell.y<0 or cell.x>=self.runtime.width or cell.y>=20) and 'out_of_bounds' or 'unknown'
            end
            if cell.status=='clear' then plan.clear=plan.clear+1
            elseif cell.status=='out_of_bounds' then plan.outside=plan.outside+1
            elseif cell.status=='occupied' or cell.status=='terrain' then plan.blocked=plan.blocked+1
            else cell.status='unknown';plan.unknown=plan.unknown+1 end
            plan.cells[#plan.cells+1]=cell
        end
    end
    plan.validitySource=plan.preflightAccepted==#anchors and 'native_geometry_and_occupancy_only' or plan.preflightAccepted>0 and 'native_preflight_plus_unknown_cells' or 'bounds_only_unknown_occupancy'
    plan.label=('%dx%d %s | partial: clear %d / blocked %d / outside %d / unknown %d'):format(plan.width,plan.height,tostring(plan.source),plan.clear,plan.blocked,plan.outside,plan.unknown)
    return plan
end
function U:ownsPointer(x,y)
    local W,H=self.api.get('screenW'),self.api.get('screenH')
    if self.phase=='after' then return y>=H-38 or y<106 end
    if ConfigWindow.owns(self,x,y)then return true end
    return y>=H-38 or y<38 or x>=W-310
end
function U:draw()
    local api,ui=self.api,self.api.ui;local W,H=api.get('screenW'),api.get('screenH');local p=W-300
    self.buttons={};self.grid=nil;self.previewInfo=nil
    self.view=self.native and type(api.battleView)=='function' and api.battleView() or nil
    if self.native and not self.view then self.native=false;self.message='Native projection unavailable; compatibility planning grid shown.' end
    if self.phase=='after' and self.view and self.finalPlan then
        for _,entry in ipairs(self.finalPlan.rows) do
            local x,y=api.battleCellToScreen(entry.x,entry.y)
            if x and y then
                local size=self.view.cellSize;local w,h=entry.width*size,entry.height*size
                if entry.team~=0 then
                    local color=M.colors[self.scenario.colors[entry.team]]
                    ui.drawRect(x-size/2,y-size/2,w-1,h-1,color[2],color[3],color[4],0.72)
                end
                if type(ui.drawMonsterIconFit)=='function' then ui.drawMonsterIconFit(x-size/2+1,y-size/2+1,w-2,h-2,entry.monster) end
            end
        end
    end
    if self.noticeText then
        local width=math.min(700,W-40);local columns=math.max(20,math.floor((width-30)/7))
        local lines={};local text=self.noticeText
        while #text>0 do lines[#lines+1]=text:sub(1,columns);text=text:sub(columns+1) end
        local height=#lines*18+90;local x,y=(W-width)/2,(H-height)/2
        ui.drawRect(0,0,W,H,0,0,0,0.65);ui.drawRect(x,y,width,height,0.055,0.075,0.09,1)
        ui.drawText(x+15,y+height-25,14,'SandboxOfElysium',1,0.9,0.65,1)
        for i,line in ipairs(lines) do ui.drawText(x+15,y+height-40-i*18,12,line,1,1,0.92,1) end
        self:button('noticeclose','OK',x+15,y+12,75,26)
        if self.noticeCanExport then self:button('diagnostics','Export Diagnostics',x+105,y+12,170,26) end
        return
    end
    if self.runtime.blocked then
        ui.drawRect(0,0,W,H,0.045,0.035,0.035,0.98)
        ui.drawText(35,H-65,18,'Editing locked: native state could not be verified',1,0.6,0.4,1)
        ui.drawText(35,H-100,12,'The saved setup is preserved. Native counts and sprites are not a verified editor state.',1,0.9,0.8,1)
        ui.drawText(35,H-126,12,'Export Diagnostics. Reopen explicitly to rebuild the preserved setup with its saved spells/items.',1,0.9,0.8,1)
        ui.drawText(35,H-152,11,'Recovery copy: '..tostring(self.runtime.recoveryFile or 'file unavailable; in-memory setup kept'),1,0.9,0.7,1)
        self:button('diagnostics','Export Diagnostics',35,H-210,180,30)
        self:button('recover','Reopen preserved setup',230,H-210,220,30)
        self:button('back','Back',465,H-210,90,30)
        if self:hasSpellRepair() then self:button('spellrepair','Repair saved spell selection',35,H-252,300,30) end
        return
    end
    if self.phase=='prepare' and not self.native then
        local width=self.runtime.width;local cell=math.min((p-24)/width,(H-130)/20)
        self.grid={x=12,y=52,cell=cell,width=width}
        ui.drawRect(0,38,p,H-76,0.06,0.08,0.065,1)
        for y=0,19 do for x=0,width-1 do
            local object=self.runtime.objects[x..':'..y]
            ui.drawRect(12+x*cell,52+y*cell,cell-0.6,cell-0.6,object and 0.32 or 0.16,object and 0.25 or 0.20,object and 0.12 or 0.16,1)
        end end
        for _,u in ipairs(self.scenario.units) do local color=M.colors[self.scenario.colors[u.team]]
            ui.drawRect(12+u.x*cell,52+u.y*cell,cell-0.6,cell-0.6,color[2],color[3],color[4],0.9)
            ui.drawText(13+u.x*cell,53+u.y*cell,math.min(10,cell/2),(u.team==1 and 'A' or 'B')..u.id,1,1,1,1)
        end
    end
    local gx,gy=self:pointerCell()
    if self.phase=='prepare' and gx and (self.selected~=nil or self.moving) and not self.context and not self.selectedItem and self.catalogTab~='items' then
        local plan=self:placementPreview(gx,gy);self.previewInfo=plan
        if plan.width and plan.height then self.lastPreviewInfo=plan end
        for _,c in ipairs(plan.cells) do
            local cx,cy,size
            if self.native then
                cx,cy=c.screenX,c.screenY
                if not cx and type(api.battleCellToScreen)=='function' then cx,cy=api.battleCellToScreen(c.x,c.y) end
                size=self.view.cellSize
            elseif self.grid then
                size=self.grid.cell;cx=self.grid.x+(c.x+0.5)*size;cy=self.grid.y+(c.y+0.5)*size
            end
            if cx and cy then
                local color=c.status=='clear' and {0.15,0.75,0.40} or c.status=='out_of_bounds' and {0.95,0.15,0.72} or c.status=='unknown' and {0.92,0.65,0.15} or {0.95,0.18,0.12}
                ui.drawRect(cx-size/2+1,cy-size/2+1,size-2,size-2,color[1],color[2],color[3],0.38)
            end
        end
    end
    ui.drawRect(0,H-38,W,38,0.035,0.045,0.055,0.97)
    local rosterLabel=self.phase=='after' and 'Snapshot ' or 'Team '
    local finalCounts=self.finalPlan and self.finalPlan.source~='unavailable'
    self:button('team1',rosterLabel..'A: '..(self.phase=='after' and (finalCounts and self.finalPlan.teamA or '?') or M.count(self.scenario,1)),10,H-32,110,26,self.team==1 and {0.16,0.32,0.52} or nil)
    self:button('team2',rosterLabel..'B: '..(self.phase=='after' and (finalCounts and self.finalPlan.teamB or '?') or M.count(self.scenario,2)),128,H-32,110,26,self.team==2 and {0.16,0.32,0.52} or nil)
    if self.phase=='prepare' then self:button('native',self.native and 'Planning grid' or 'Battle map',248,H-32,122,26) end
    self:button('diagnostics','Export Diagnostics',380,H-32,148,26)
    if self.phase=='prepare' and self.native then
        local zoom=self:zoomState()
        if zoom then
            self:button('zoomout','Zoom -',536,H-32,57,26,nil,11)
            ui.drawText(597,H-24,10,('%d%%'):format(math.floor(zoom.zoom*100+0.5)),0.90,0.92,0.85,1)
            self:button('zoomin','Zoom +',641,H-32,57,26,nil,11)
        else ui.drawText(539,H-24,10,'Native zoom unavailable',0.65,0.70,0.70,1) end
    end
    self:button('back',self.moving and 'Cancel move' or 'Back',W-94,H-32,84,26)
    ui.drawRect(0,0,W,38,0.035,0.045,0.055,0.98)
    ui.drawText(10,22,10,self.phase=='after' and 'Final snapshot is read only. Right-click a captured survivor for native Inspect where available.' or self.selectedItem and ('ITEM: '..Catalog.textLimit(self.selectedItem.name,42)..' - right-click a unit. Select again or Cancel item to clear.') or self.moving and 'MOVE: right-click destination; Cancel move keeps the original.' or (self.selected==nil or self.catalogTab=='items') and 'Right-click a unit: Inspect / Edit / Move / Copy / Delete.' or 'Right-click places. Existing unit: Inspect / Edit / Move / Copy / Delete.',1,1,0.9,1)
    ui.drawText(10,5,10,self.message:sub(1,112),0.95,0.76,0.45,1)
    if self.phase=='after' then
        ui.drawRect(0,38,W,68,0.035,0.045,0.055,0.95)
        self:button('results','Battle report',12,68,132,26);self:button('reset','Back to Sandbox',154,68,150,26);self:button('rematch','Rematch',314,68,110,26)
        self:button('main','Main menu',434,68,120,26)
        local status=self.finalPlan and self.finalPlan.source~='unavailable' and (self.finalPlan.complete and 'Complete unit/cell snapshot' or 'PARTIAL unit/cell snapshot') or 'Final snapshot unavailable'
        ui.drawText(12,44,10,status..' after aftermath, before cleanup; effects not captured. Right-click survivor: Inspect.',1,0.9,0.7,1)
        if self.finalContext then
            local x,y=math.max(5,math.min(W-180,self.finalContext.px)),math.max(145,math.min(H-45,self.finalContext.py))
            local entry=self.finalContext.entry;local name
            if type(api.testFieldUnitName)=='function'then
                local ok,state=pcall(api.testFieldUnitName,entry.native)
                if ok and type(state)=='table'and state.generation==entry.row.generation then name=state.shown end
            end
            local width=math.min(W-20,math.max(250,name and #name*8+16 or 250));x=math.max(5,math.min(W-width-5,x))
            ui.drawRect(x-5,y-36,width+5,59,0.02,0.025,0.03,1)
            ui.drawText(x+4,y+5,11,name or 'Native name unavailable after cleanup',1,0.94,0.73,1)
            self:button('finalinspect','Inspect current native unit',x,y-30,width,26)
        end
        return
    end
    ui.drawText(12,H-57,11,(self.native and 'Native battle-map' or 'Compatibility planning grid')..' | '..(M.terrainNames[self.scenario.terrain] or 'Unknown'),1,0.9,0.7,1)
    if self.previewInfo then
        ui.drawText(12,H-73,9,self.previewInfo.label,1,0.9,0.7,1)
        ui.drawText(12,H-87,9,'Partial only; native placement decides. Green clear / red blocked / pink outside / amber unknown.',1,0.9,0.7,1)
    end
    local selected=self.catalog.byId[self.selected]
    ui.drawRect(p,38,300,304,0.035,0.045,0.055,0.94)
    ui.drawRect(p,H-240,300,202,0.035,0.045,0.055,0.94)
    ui.drawText(p+8,H-61,12,self.selectedItem and ('Item: '..Catalog.textLimit(self.selectedItem.name,30,'...')) or self.catalogTab=='items' and 'Choose an item below' or selected and Catalog.textLimit(selected.name,37,'...') or 'Select a unit below',1,0.87,0.6,1)
    if self.selectedItem then
        self:button('itemcancel','Cancel item selection',p+8,H-88,284,25,{0.30,0.20,0.13})
    elseif self.catalogTab=='items'then ui.drawText(p+8,H-79,11,'Select an item, then right-click a placed unit.',0.9,0.9,0.85,1)
    else
        if self.formation==1 then self.n=1 end
        self:button('formation',kinds[self.formation]..(self.formation==1 and '' or ' ('..self.n..')'),p+8,H-88,self.formation==1 and 284 or 176,25)
        if self.formation~=1 then
            self:button('numberdown','-',p+192,H-88,46,25)
            self:button('number','+',p+246,H-88,46,25)
        end
    end
    self:button('fight','Start battle',p+8,H-121,284,29,{0.32,0.21,0.08})
    self:button('save','Save',p+8,H-150,138,25);self:button('load','Load',p+154,H-150,138,25)
    self:button('clear','Clear battlefield',p+8,H-179,178,25)
    if self.snapshot then self:button('reset','Reset',p+194,H-179,98,25) end
    self:button('clearitems','Clear All Held Items',p+8,H-208,284,25)
    self:button('unique','Multiple unique: '..(self.scenario.allowMultipleUnique and 'On' or 'Off'),p+8,H-237,138,25,nil,10)
    self:button('startingitems','Starting items: '..(self.scenario.startingItems==false and 'Off' or 'On'),p+154,H-237,138,25,nil,10)
    self:button('catalogunits','Units',p+8,316,138,24,self.catalogTab~='items' and {0.16,0.32,0.46} or nil)
    self:button('catalogitems','Items',p+154,316,138,24,self.catalogTab=='items' and {0.16,0.32,0.46} or nil)
    if self.catalogTab=='items'then ConfigWindow.drawCatalog(self,p)else
    local unitSearchFocused=self.searchFocused and (self.textTarget==nil or self.textTarget=='units')
    local searchLabel=self.search=='' and (unitSearchFocused and 'Type to search...' or 'Search units...') or Catalog.textLimit(self.search,28,'...')
    self.searchRect={x=p+8,y=285,w=234,h=27}
    self:button('search',searchLabel..(unitSearchFocused and ' |' or ''),p+8,285,234,27,unitSearchFocused and {0.16,0.31,0.43} or nil)
    self:button('searchclear','Clear',p+246,285,46,27)
    local filterText='Filter: '..(categoryLabels[categories[self.category]]or categories[self.category])..' | '..#self.filtered..' results'
    if categories[self.category]=='ranged' and (self.catalog.rangedUnknown or 0)>0 then filterText='Ranged unavailable/partial: update Extender' end
    self:button('filter',filterText,p+8,255,284,24)
    for row=1,5 do local index=(self.page-1)*5+row;local item=self.filtered[index];local y=251-row*36
        if item then
            ui.drawRect(p+8,y,284,34,0.13,0.17,0.20,0.98)
            ui.drawRect(p+10,y+2,34,30,0.065,0.085,0.10,1)
            local drawn=type(ui.drawMonsterIconFit)=='function' and ui.drawMonsterIconFit(p+11,y+3,32,28,item.id)
            if not drawn then ui.drawText(p+20,y+10,12,'?',0.65,0.7,0.75,1) end
            ui.drawText(p+50,y+20,10,Catalog.textLimit(item.name,29,'...'),1,0.95,0.85,1)
            ui.drawText(p+50,y+6,9,'#'..item.id..' | A '..M.count(self.scenario,1,item.id)..' / B '..M.count(self.scenario,2,item.id),0.7,0.75,0.8,1)
            self:button('unit:'..index,'Select',p+240,y+5,50,24,item.id==self.selected and {0.18,0.34,0.5} or nil)
        end
    end
    if #self.filtered==0 then ui.drawText(p+18,208,12,'No matching units. Clear search or filter.',0.95,0.85,0.65,1) end
    self:button('prev','<',p+8,42,40,25);self:button('next','>',p+252,42,40,25)
    ui.drawText(p+65,50,11,self.page..' / '..math.max(1,math.ceil(#self.filtered/5))..(type(ui.drawMonsterIconFit)=='function' and '' or ' | icon API missing'),0.8,0.8,0.8,1)
    end
    local hover=gx and self:unitAt(gx,gy)
    if hover and not self.context and not self.editWindow then
        local name=M.displayName(hover);local width=math.min(p-20,math.max(190,math.min(48,utf8 and utf8.len(name)or #name)*12+18))
        local x=math.max(5,math.min(p-width-5,self.api.get('uiPointerX')+14));local y=math.max(42,math.min(H-110,self.api.get('uiPointerY')+14))
        ui.drawRect(x,y,width,48,0.025,0.04,0.05,0.97);ui.drawText(x+8,y+29,12,name,1,0.94,0.73,1)
        ui.drawText(x+8,y+10,10,hover.name..' | '..(hover.team==1 and'A'or'B')..' #'..hover.id,0.82,0.87,0.9,1)
    end
    if self.context then
        local name=M.displayName(self.context.unit);local width=math.min(p-14,math.max(180,math.min(48,utf8 and utf8.len(name)or #name)*12+18))
        local x,y=math.max(5,math.min(p-width-5,self.context.px)),math.max(194,math.min(H-45,self.context.py))
        ui.drawRect(x-3,y-153,width+6,186,0.02,0.025,0.03,1);ui.drawText(x+6,y+12,12,name,1,0.94,0.73,1)
        for i,label in ipairs({'Inspect','Edit','Move','Copy','Delete'})do self:button('context:'..label,label,x,y-i*28,width,25)end
    end
    ConfigWindow.draw(self)
end
function U:pointerCell()
    local px,py=self.api.get('uiPointerX'),self.api.get('uiPointerY')
    if self:ownsPointer(px,py) then return end
    if self.native and type(self.api.battleScreenToCell)=='function' then return self.api.battleScreenToCell(px,py) end
    if not self.grid then return end
    local g=self.grid;local x=math.floor((px-g.x)/g.cell);local y=math.floor((py-g.y)/g.cell)
    if x>=0 and x<g.width and y>=0 and y<20 then return x,y end
end
function U:input(mouse)
    if self.native and type(self.api.battleView)=='function' then self.view=self.api.battleView() or self.view end
    local freshLeft=mouse&1~=0 and self.lastMouse&1==0
    local freshRight=mouse&2~=0 and self.lastMouse&2==0
    local x,y=self.api.get('uiPointerX'),self.api.get('uiPointerY');local consumed=false
    if self.releaseBarrier then
        self.lastMouse=mouse;self.lastCell=nil;self.dragOrigin=nil;self.dragBlocked=true
        if mouse&3==0 then self.releaseBarrier=nil;self.dragBlocked=false end
        return true
    end
    if not self.noticeText and not self.runtime.blocked and ConfigWindow.input(self,mouse,freshLeft,x,y)then return true end
    if self.searchFocused and (freshLeft or freshRight) then
        local r=ConfigWindow.focusRect(self)
        local inSearch=r and x>=r.x and x<r.x+r.w and y>=r.y and y<r.y+r.h
        local clear=false
        for _,b in ipairs(self.buttons) do if b.key=='searchclear' and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then clear=true end end
        if not inSearch and not clear then self:setSearchFocus(false);self.dragBlocked=true;consumed=true end
    end
    if self.noticeText then
        if freshLeft then for _,b in ipairs(self.buttons) do
            if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then self.pending=b.key;break end
        end end
        self.lastMouse=mouse
        return true
    end
    if freshLeft then
        for i=#self.buttons,1,-1 do local b=self.buttons[i]
            if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then self.pending=b.key;consumed=true;break end
        end
        if not consumed and (self.context or self.finalContext) then self.context=nil;self.finalContext=nil;consumed=true end
    end
    if self.runtime.blocked then self.lastMouse=mouse;self.lastCell=nil;return true end
    if self.searchFocused then self.lastMouse=mouse;return true end
    local gx,gy=self:pointerCell()
    if self.phase=='after' and mouse&3~=0 then
        consumed=true
        if freshRight and gx then
            local entry=FinalView.at(self.finalPlan,gx,gy)
            self.finalContext=entry and {entry=entry,px=x,py=y} or nil
        end
    end
    if self.phase=='prepare' and not self.runtime.blocked and mouse&2~=0 and gx then
        consumed=true;local u=self:unitAt(gx,gy)
        if freshRight and u and not self.moving then
            if self.selectedItem then self.pending={equip=true,model_id=u.id}
            elseif self.editWindow then self.pending={openConfig=u.id}
            else self.context={unit=u,px=x,py=y};self.diag:record('context',{name=u.name,id=u.id})end
            self.dragBlocked=true
        elseif self.moving then
            if freshRight then self.pending={move=true,x=gx,y=gy} end
        elseif self.selected~=nil and not self.context and not self.dragBlocked and self.catalogTab~='items' and not self.selectedItem then
            if freshRight then
                local footprint=self:placementFootprint()
                local stepX,stepY
                if footprint then stepX,stepY=Preview.span(kinds[self.formation],self.n,footprint.width,footprint.height) end
                self.dragOrigin={x=gx,y=gy,stepX=stepX,stepY=stepY};self.dragVisited={}
            end
            if self.dragOrigin then gx,gy=Preview.snap(gx,gy,self.dragOrigin,self.dragOrigin.stepX,self.dragOrigin.stepY) end
            local key=gx..':'..gy
            if (freshRight or self.lastCell~=key) and not (self.dragVisited and self.dragVisited[key]) then
                self.pending={place=true,x=gx,y=gy};self.lastCell=key
                if self.dragVisited then self.dragVisited[key]=true end
            end
        end
    end
    -- Consume the complete left press, including frames after a modal/button
    -- changes layout. Native battle controls must not receive its held tail.
    if mouse&1~=0 then consumed=true end
    if self:ownsPointer(x,y) and mouse&3~=0 then consumed=true end
    if mouse&2==0 then self.lastCell=nil;self.dragBlocked=false;self.dragOrigin=nil;self.dragVisited=nil end
    self.lastMouse=mouse
    if self.view and (freshRight or consumed and freshLeft) then
        self.diag:record('pointer',{ui_x=x,ui_y=y,cell_x=gx,cell_y=gy,cell_size=self.view.cellSize,
            camera_x=self.view.cameraX,camera_y=self.view.cameraY,screen_w=self.view.screenW,screen_h=self.view.screenH,team=self.team})
    end
    return consumed
end
function U:inspect(u)
    self:setSearchFocus(false);self.context=nil;self.moving=nil;self.pending=nil
    if type(self.runtime.inspect)~='function' then self:notice('Native instance Inspect requires the updated experimental API. No template card was substituted.');return false end
    self.inNativeMenu=true
    self.api.set('mouseButtons',(self.api.get('mouseButtons') or 0)&4)
    local called,ok,candidate,details=pcall(self.runtime.inspect,self.runtime,self.scenario,u)
    self.inNativeMenu=false;self.releaseBarrier=true;self.dragBlocked=true;self.lastCell=nil;self.dragOrigin=nil
    self.api.set('mouseButtons',(self.api.get('mouseButtons') or 0)&4)
    if not called then error(ok) end
    if ok then
        if type(candidate)~='table' then error('Verified native Inspect did not return its preserved scenario') end
        self.scenario=candidate;self.message=details and details.mode=='read_only' and 'Native Inspect is read only; instance state verified' or 'Native instance Inspect closed; state verified'
        self.diag:record('inspect',{model_id=u.id,native_id=self.runtime.live[u.id],accepted=1,
            mode=details and details.mode or 'verified',changed=details and (details.changed==true or details.changed==1) and 1 or 0})
        return true
    end
    self.message=tostring(candidate);self:notice(self.message)
    return false
end
function U:inspectFinal()
    local entry=self.finalContext and self.finalContext.entry
    self.finalContext=nil;self.pending=nil;self:setSearchFocus(false)
    if not entry then return false end
    if not entry.row.inspectable or entry.row.inspectable==0 or type(self.api.inspectTestFieldFinalUnit)~='function' then
        self:notice('This actor is visible in the final snapshot, but native cleanup removed or changed its live instance. Native Inspect is unavailable: '..tostring(entry.row.inspectReason or 'unverified instance'))
        return false
    end
    self.inNativeMenu=true;self.api.set('mouseButtons',(self.api.get('mouseButtons') or 0)&4)
    local called,ok,detail,nativeDetail=pcall(self.api.inspectTestFieldFinalUnit,entry.native,{readOnly=true})
    self.inNativeMenu=false;self.releaseBarrier=true;self.dragBlocked=true;self.lastCell=nil
    self.api.set('mouseButtons',(self.api.get('mouseButtons') or 0)&4)
    if not called then error(ok) end
    local verified=ok and type(detail)=='table' and detail.readOnly==true and detail.verified==true
    self.diag:record('final_inspect',{native_id=entry.native,accepted=verified and 1 or 0,source='current native instance; final drawing is a timed snapshot',reason=verified and 'read only verified' or tostring(detail)})
    if verified then self.message='Current native unit inspected read only; final snapshot remains unchanged.';return true end
    if type(nativeDetail)=='table' and nativeDetail.verified==false then self.runtime:quarantine(self.snapshot or self.scenario,'final_inspect_unverified',nil,{native_id=entry.native,reason=detail}) end
    self:notice('Native final-unit Inspect refused: '..tostring(detail));return false
end
function U:save()
    local migrate=self.scenario.legacyState or self.scenario.migrationRequired
    local name=self:prompt(migrate and 'Save migrated copy'or'Save scenario',migrate and 'Unused name for schema 4 copy; original is preserved:'or'File name (without .ini):')
    if name then
        if name:lower()=='launcher-context' or name:lower():find('^diagnostics%-') then self:notice('This name is reserved for diagnostics. Choose another scenario name.');return end
        if migrate then
            for _,existing in ipairs(self.api.listIni())do
                if existing:gsub('%.ini$',''):lower()==name:gsub('%.ini$',''):lower()then self:notice('Migration writes a new copy. Choose an unused name; existing scenarios are preserved.');return end
            end
        end
        local ok=self.api.writeIni(name,M.encode(self.scenario,self.catalog.mods))
        if ok then
            local verified,why=M.decode(self.api.readIni(name),self.catalog,self.catalog.mods)
            if not verified then ok=false;self.diag:record('save_readback',{accepted=0,reason=tostring(why)})
            else self.scenario.legacyState=false;self.scenario.sourceSchema=4;self.scenario.migrationRequired=false end
        end
        self.message=ok and 'Scenario saved: '..name or 'Save refused: invalid file name, value or quota'
        self.diag:record('save',{accepted=ok and 1 or 0,units=#self.scenario.units,terrain=self.scenario.terrain})
        if not ok then local snapshot=self.runtime:snapshot(self.scenario);self.diag:failure('save',self.message,{},snapshot,snapshot,'unchanged') end
    end
end
function U:load()
    local files={};local rows={{0,'Choose a saved scenario'}}
    for _,name in ipairs(self.api.listIni()) do
        local data=self.api.readIni(name)
        if data and data.scenario then files[#files+1]=name end
    end
    for i,name in ipairs(files) do rows[#rows+1]={i,name} end;rows[#rows+1]={999,'Cancel'}
    local id=self:menu('Load scenario',rows)
    if not files[id] then return end
    local candidate,why=M.decode(self.api.readIni(files[id]),self.catalog,self.catalog.mods)
    if not candidate then
        local snapshot=self.runtime:snapshot(self.scenario);self.diag:failure('load',why,{},snapshot,snapshot,'unchanged')
        self.message='Could not load scenario: '..Catalog.textLimit(tostring(why),140,'...')..'. Current setup kept.';self:notice(self.message);return
    end
    if candidate.terrain~=0 and not self.catalog.testFieldTerrains[candidate.terrain] then self:notice('This scenario needs the matching terrain API for '..(M.terrainNames[candidate.terrain] or 'this map')..'. Current setup kept.');return end
    self.runtime.sourceScenarioFile=files[id]
    if self.runtime.open then
        local ok;ok,why=self.runtime:build(candidate)
        if not ok then
            self.message=why
            if self:hasSpellRepair() then self.message=self.message..' Current army kept. Return to battlefield setup, then choose Repair saved spell selection (copy).' end
            self:notice(self.message);return
        end
    end
    ConfigWindow.close(self);self.selectedItem=nil
    self.scenario=candidate;self.context=nil;self.moving=nil;self.copyTemplate=nil;self.message='Scenario content validated; native positions checked on Prepare'
    if candidate.migrationRequired and not candidate.legacyState then self.message='Older setup loaded; existing labels remain Sandbox-only. Native personal names were not recorded. Save as a new schema 4 copy.';self:notice(self.message)end
    if candidate.legacyState or candidate.partialActorState then
        self.message='Recorded configuration loaded. Health/injury state was not recorded for every actor; native defaults remain for those fields. Save migration to a new name.'
        self:notice(self.message)
    end
    self.diag:record('load',{units=#candidate.units,terrain=candidate.terrain})
end
function U:edit(u)
    return ConfigWindow.open(self,u)
end
function U:spellEditor(u,path)
    local page=1
    while true do
        local known={};for _,key in ipairs(u.baseline.known) do local info=self.api.spellInfo(self.catalog.spellKeys[key]);if path==nil or (info and info.path==path) then known[#known+1]=key end end
        page=math.max(1,math.min(page,math.max(1,math.ceil(#known/8))))
        local rows={{0,'Choose existing known spells by ID. Native per-school limits apply.'}}
        for i=(page-1)*8+1,math.min(page*8,#known) do rows[#rows+1]={100+i,(contains(u.spells,known[i]) and '[x] ' or '[ ] ')..known[i]} end
        rows[#rows+1]={1,'Previous'};rows[#rows+1]={2,'Next'};rows[#rows+1]={999,'Done'}
        local id=self:menu('Battle spells',rows)
        if id==999 then return elseif id==1 then page=math.max(1,page-1) elseif id==2 then page=math.min(math.max(1,math.ceil(#known/8)),page+1)
        elseif known[id-100] then
            local name=known[id-100];local ok,why=self.runtime:memorize(u,name,not contains(u.spells,name));if not ok then self:notice(why or 'The game rejected this memorization change. Previous selection kept.') end
        end
    end
end
function U:itemBrowser(u)
    local search,slot,page,slotIndex='',nil,1,0
    while true do
        local rows={{0,'Inventory: '..(#u.items==0 and '(none)' or table.concat(u.items,', '))},
            {0,'Equipment editing needs the newer experimental Extender; current inventory is read only.'},
            {1,'Search: '..search},{2,'Slot type: '..(slot==nil and 'All' or tostring(slot))}}
        local filtered={};for _,item in ipairs(self.catalog.items) do if item.name:lower():find(search:lower(),1,true) and (slot==nil or slot==item.slot) then filtered[#filtered+1]=item end end
        page=math.max(1,math.min(page,math.max(1,math.ceil(#filtered/5))))
        for i=(page-1)*5+1,math.min(page*5,#filtered) do local item=filtered[i];rows[#rows+1]={0,item.name..' | native slot type '..tostring(item.slot)} end
        rows[#rows+1]={3,'Previous'};rows[#rows+1]={4,'Next'};rows[#rows+1]={999,'Done'}
        local id=self:menu('Item catalog (read only)',rows)
        if id==999 then return elseif id==1 then local q=self:prompt('Search items','Name contains:');if q then search=q;page=1 end
        elseif id==2 then slotIndex=(slotIndex+1)%(#self.catalog.itemSlots+1);slot=self.catalog.itemSlots[slotIndex];page=1
        elseif id==3 then page=page-1 elseif id==4 then page=page+1 end
    end
end
function U:fight()
    self:setSearchFocus(false)
    if M.count(self.scenario,1)==0 or M.count(self.scenario,2)==0 then self:notice('Place at least one unit for each team before fighting.');return false end
    local ready,why=self.runtime:ready(self.scenario);if not ready then self:notice(why);return false end
    self.diag:record('battle_start',{units=#self.scenario.units,terrain=self.scenario.terrain})
    ConfigWindow.close(self);self.selectedItem=nil
    self.snapshot=M.copy(self.scenario);self.phase='fight';self.context=nil;self.moving=nil
    self.report:start(self.scenario,self.runtime);self.api.fightTestField();self.report:finish(self.scenario,self.runtime)
    self.phase='after';self.runtime.phase='after';self.native=true;self.finalContext=nil
    self.finalPlan=FinalView.prepare(self.runtime.finalState)
    local reportName,archiveWarning=self.report:archive()
    self.message=reportName and 'Report archived: '..reportName..'.ini' or tostring(archiveWarning)
    if reportName and archiveWarning then self.message=self.message..' | '..archiveWarning end
    self.diag:record('battle_end',{winner=self.api.get('battleWinner'),round=self.api.get('battleRound')})
    return true
end
function U:results()
    local r=self.report.result;if not r then return 'controls' end
    self:setSearchFocus(false)
    self.inNativeMenu=true
    local winner=r.summary.winner==0 and 'Team A' or r.summary.winner==24 and 'Team B' or 'None / unavailable'
    local page=1;local types={};for _,row in pairs(r.types) do types[#types+1]=row end
    for _,u in ipairs(self.report.scenario and self.report.scenario.units or{})do if u.nativeName and u.nativeName~=''then
        local actor=r['unit'..u.id];if actor then types[#types+1]={team=u.team,name=u.nativeName,modelId=u.id,individual=true,survivors=actor.alive,losses=actor.alive==1 and 0 or 1}end
    end end
    table.sort(types,function(a,b) return a.team==b.team and a.name<b.name or a.team<b.team end)
    while true do
        local rows={{0,'Winner: '..winner..' | final round '..r.summary.final_round..' | elapsed wall '..math.floor(r.summary.elapsed_wall_ms/1000)..' s'},
            {0,('A: %d start / %d lost / %d survive; B: %d / %d / %d'):format(r.teamA.start,r.teamA.losses,r.teamA.survivors,r.teamB.start,r.teamB.losses,r.teamB.survivors)}}
        for i=(page-1)*5+1,math.min(page*5,#types) do local t=types[i];rows[#rows+1]={0,t.individual and ('Individual %s #%d: %s | %s'):format(t.team==1 and'A'or'B',t.modelId,t.name,t.survivors==1 and'survived'or'lost')or('Team %d %s: %d lost / %d survive'):format(t.team,t.name,t.losses,t.survivors)} end
        rows[#rows+1]={0,'Damage attribution partial; complete cast log unavailable. Export includes native kills.'}
        rows[#rows+1]={0,r.summary.final_snapshot_source and ('Final view: '..r.summary.final_snapshot_source..'; units/cells complete: '..tostring(r.summary.final_snapshot_complete)..'; effects excluded.') or 'Final capture unavailable; aftermath observations alone are partial.'}
        rows[#rows+1]={0,'The battle result is read only. Returning restores saved positions, spells and items.'}
        rows[#rows+1]={1,'Previous report page'};rows[#rows+1]={2,'Next report page'};rows[#rows+1]={3,'Export report'}
        rows[#rows+1]={999,'Back to Sandbox (restore pre-battle setup)'}
        rows[#rows+1]={4,'Rematch (restore setup and fight again)'}
        rows[#rows+1]={5,'View post-battle field (read only)'};rows[#rows+1]={6,'Main menu (keep setup and report)'}
        local id=self:menu('Battle report',rows)
        if id==999 or id==4 or id==5 or id==6 then
            self.inNativeMenu=false
            return id==999 and 'restore' or id==4 and 'rematch' or id==5 and 'controls' or 'main'
        elseif id==1 then page=math.max(1,page-1) elseif id==2 then page=math.min(math.max(1,math.ceil(#types/5)),page+1)
        elseif id==3 then local name=self:prompt('Export report','File name:');if name then self:notice(self.report:export(name) and 'Report exported as '..name..'.ini' or 'Export refused') end end
    end
end
function U:reset(rematch)
    self:setSearchFocus(false)
    if not self.snapshot then self:notice('No pre-battle setup is available. Current scenario was kept.');return false end
    local candidate=M.copy(self.snapshot);local ok,why=self.runtime:build(candidate)
    if ok then
        ConfigWindow.close(self);self.selectedItem=nil
        self.scenario=candidate;self.phase='prepare';self.native=type(self.api.battleView)=='function';self.context=nil;self.moving=nil;self.copyTemplate=nil;self.finalPlan=nil;self.finalContext=nil
        self.message='Original pre-battle setup restored; previous report kept'
        self.diag:record(rematch and 'rematch' or 'reset',{units=#candidate.units});return true
    end
    self.message=why;self:notice(why);return false
end
function U:postBattle(action)
    -- Each report returns an action. Rematches repeat this loop rather than
    -- recursively opening another results/reset/fight call chain.
    while true do
        action=action or self:results()
        if action=='main' then self:setSearchFocus(false);self.exitToMain=true;return false
        elseif action=='controls' then return true
        elseif action=='restore' then self:reset(false);return self.runtime.open
        elseif action=='rematch' then
            if not self:reset(true) or not self:fight() then return self.runtime.open end
            action=nil
        else return self.runtime.open end
    end
end
function U:dispatch(action)
    if action~='search' and action~='searchclear' then self:setSearchFocus(false) end
    if self.runtime.blocked and action~='diagnostics' and action~='recover' and action~='back' and action~='noticeclose' and action~='spellrepair' then
        self.message='Editing locked; export diagnostics and reopen the preserved setup.';self.pending=nil;return true
    end
    if type(action)=='table' then
        if action.equip then local u=ConfigWindow.find(self,action.model_id);if u then ConfigWindow.give(self,u)end
        elseif action.openConfig then local u=ConfigWindow.find(self,action.openConfig);if u then ConfigWindow.open(self,u)end
        elseif action.move then local ok,why=self.runtime:move(self.moving,action.x,action.y);self.message=ok and 'Moved; configuration preserved' or why;if ok then self.moving=nil;self.dragBlocked=true end
        elseif action.place then
            if self.selected==nil then self.message='Select a unit before placing.';return true end
            local skipped,placed,lastReason=0,0,nil
            local footprint=self:placementFootprint();local anchors,why=self:placementAnchors(action.x,action.y,footprint)
            if not anchors then self.message=why;return true end
            for _,c in ipairs(anchors) do
                local ok,candidate=self.runtime:add(self.scenario,self.selected,self.team,c.x,c.y,self.copyTemplate)
                if ok then self.scenario=candidate;placed=placed+1 else skipped=skipped+1;lastReason=candidate end
                if self.runtime.blocked then self.context=nil;self.moving=nil;self.copyTemplate=nil;break end
                if not self.runtime.open then self:notice(candidate);return false end
            end
            self.message='Placed '..placed..'; skipped '..skipped..(lastReason and '. '..lastReason or '')
            self.diag:record('formation',{kind=kinds[self.formation],count=self.n,placed=placed,skipped=skipped,team=self.team,
                footprint_width=footprint and footprint.width or 'unknown',footprint_height=footprint and footprint.height or 'unknown',
                footprint_source=footprint and footprint.source or 'unavailable',spacing='footprint-positive-xy'})
        end;return true
    end
    if ConfigWindow.dispatch(self,action)then return true end
    local prefix,value=action:match('^(%w+):(.+)$')
    if prefix=='item'then
        local item=self.catalog.byItemId and self.catalog.byItemId[tonumber(value)]
        if item then
            local deselect=self.selectedItem and self.selectedItem.id==item.id
            self.selectedItem=not deselect and item or nil;self.equipDialog=nil;self.moving=nil;self.copyTemplate=nil;self.context=nil
            self.releaseBarrier=true;self.dragBlocked=true
            self.message=deselect and 'Item selection cleared. Right-click a unit for its context menu.' or 'Item selected: '..item.name..'. Right-click a unit to equip; click Select again to clear.'
        end
    elseif prefix=='iteminfo'then ConfigWindow.inspectItem(self,tonumber(value))
    elseif prefix=='unit' then
        local m=self.filtered[tonumber(value)]
        if m then
            local deselect=self.selected==m.id
            self.selected=not deselect and m.id or nil;self.selectedItem=nil;self.equipDialog=nil;self.copyTemplate=nil;self.moving=nil;self.context=nil
            self.releaseBarrier=true;self.dragBlocked=true
            self.message=deselect and 'Unit selection cleared. Right-click a unit for its context menu.' or 'Selected '..m.name..'; click Select again to clear.'
            self.diag:record(deselect and 'deselect' or 'select',{monster=m.id,name=m.name})
        end
    elseif prefix=='context' then
        local u=self.context.unit;self.context=nil
        if value=='Inspect' then self:inspect(u) elseif value=='Edit' then self:edit(u) elseif value=='Move' then self.moving=u;self.message='Right-click target; Back cancels move'
        elseif value=='Copy' then self.selected=u.monster;self.copyTemplate=M.copy(u);self.team=u.team;self.message='Copy selected; right-click a free cell to preserve this configuration';self.diag:record('copy_selected',{id=u.id,name=u.name})
        elseif value=='Delete' then
            local ok,candidate=self.runtime:remove(self.scenario,u)
            if ok then self.scenario=candidate;self.message='Unit removed; other units kept' else self.message=candidate;self:notice(candidate) end
        end
    elseif action=='back' then if self.moving then self.moving=nil;self.message='Move cancelled; original cell retained' elseif self.context then self.context=nil else return false end
    elseif action=='main' then self.exitToMain=true;return false
    elseif action=='team1' then self.team=1;self.diag:record('team',{team=1}) elseif action=='team2' then self.team=2;self.diag:record('team',{team=2})
    elseif action=='native' then
        if type(self.api.battleView)=='function' then self.native=not self.native else self:notice('Direct battle-map interaction requires the experimental editor API. The labelled planning grid remains available.') end
    elseif action=='noticeclose' then self.noticeText=nil;self.dragBlocked=true
    elseif action=='diagnostics' then self:exportDiagnostics()
    elseif action=='spellrepair' then self:repairSpells()
    elseif action=='recover' then
        local ok,candidate=self.runtime:recover()
        if ok then self.scenario=candidate;self.context=nil;self.moving=nil;self.copyTemplate=nil;self.noticeText=nil;self.message='Preserved setup reopened and verified.'
        else self:notice(candidate) end
    elseif action=='browse' then self:browse()
    elseif action=='formation' then self.formation=self.formation%4+1;self.n=self.formation==4 and 2 or 1
    elseif action=='number' then self.n=self.formation==1 and 1 or self.formation==4 and (self.n==4 and 2 or self.n+1) or (self.n%15+1)
    elseif action=='numberdown' then self.n=self.formation==1 and 1 or math.max(self.formation==4 and 2 or 1,self.n-1)
    elseif action=='search' then self:setSearchFocus(true)
    elseif action=='searchclear' then
        if self.catalogTab=='items'then self.itemSearch='';self.itemPage=1;ConfigWindow.items(self)else self.search='';self.page=1;self:refresh()end
        self.diag:record('search',{query_length=0,source='clear',catalog=self.catalogTab or 'units'})
    elseif action=='catalogunits'then self.catalogTab='units';self.selectedItem=nil;self.equipDialog=nil;self.context=nil;self.releaseBarrier=true
    elseif action=='catalogitems'then self.catalogTab='items';self.context=nil;self.moving=nil;self.copyTemplate=nil;ConfigWindow.items(self);self.releaseBarrier=true
    elseif action=='itemcancel'then self.selectedItem=nil;self.equipDialog=nil;self.context=nil;self.releaseBarrier=true;self.message='Item selection cancelled. Right-click a unit for its context menu.'
    elseif action=='itemorigin'then local nextSource={all='modded',modded='unknown',unknown='all'};self.itemOrigin=nextSource[self.itemOrigin or 'all'];self.itemPage=1;ConfigWindow.items(self)
    elseif action=='unique' then self:toggleMultipleUnique()
    elseif action=='zoomout' then self:requestZoom(-1)
    elseif action=='zoomin' then self:requestZoom(1)
    elseif action=='startingitems' then self:toggleStartingItems()
    elseif action=='clearitems' then self:clearAllHeldItems()
    elseif action=='filter' then
        if self.catalogTab=='items'then self.itemSlotIndex=((self.itemSlotIndex or 0)+1)%(#self.catalog.itemSlots+1);self.itemSlot=self.catalog.itemSlots[self.itemSlotIndex];self.itemPage=1;ConfigWindow.items(self)
        else self.category=self.category%#categories+1;self.page=1;self:refresh()end
    elseif action=='prev' or action=='next' then
        if self.catalogTab=='items'then self.itemPage=(self.itemPage or 1)+(action=='next'and 1 or -1);ConfigWindow.items(self)
        else self.page=self.page+(action=='next'and 1 or -1);self:refresh()end
    elseif action=='fight' then if self:fight() then return self:postBattle() end
    elseif action=='results' then return self:postBattle()
    elseif action=='finalinspect' then self:inspectFinal()
    elseif action=='save' then self:save() elseif action=='load' then self:load()
    elseif action=='reset' then self:reset(false) elseif action=='rematch' then return self:postBattle('rematch')
    elseif action=='clear' then
        if not self.runtime:emptyEditorAvailable() then self:notice('A completely empty battlefield requires the updated experimental empty-editor API. Current setup kept.');return self.runtime.open end
        local units=M.copy(self.scenario.units)
        for _,u in ipairs(units) do
            local ok,candidate=self.runtime:remove(self.scenario,u)
            if not ok then self:notice(candidate);return self.runtime.open end
            self.scenario=candidate
        end
        self.context=nil;self.moving=nil;self.copyTemplate=nil;self.dragBlocked=true
        self.message='Battlefield is empty. Place units on either team; a battle needs at least one unit per team.'
        self.diag:record('clear',{units=#self.scenario.units,team_a=M.count(self.scenario,1),team_b=M.count(self.scenario,2)})
    end
    return self.runtime.open
end
function U:prepare(nativeDeployment,reuseVerified)
    self.previewInfo=nil;self.lastPreviewInfo=nil;self.finalPlan=nil;self.finalContext=nil
    if not self.drawHook or not self.waitHook then self:notice('Required native battle overlay/input hooks are unavailable on this extender/platform.');return end
    local candidate=nativeDeployment and M.copy(self.scenario) or self.scenario
    local ok,why
    if reuseVerified then ok,why=self.runtime:ready(candidate) else ok,why=self.runtime:build(candidate,nativeDeployment) end
    if not ok then self:notice(why);return end
    self.scenario=candidate
    self.phase='prepare';self.native=type(self.api.battleView)=='function';self.pending=nil;self.lastMouse=0;self.escapeHeld=false
    self.lastWheel=nil
    self.diag:record('open_field',{terrain=self.scenario.terrain,native=self.native and 1 or 0,units=#self.scenario.units})
    local success,err=xpcall(function()
        while self.runtime.open do
            self.api.drawTestField()
            if self.pending then local action=self.pending;self.pending=nil;if not self:dispatch(action) then break end end
        end
    end,function(e)return tostring(e) end)
    if not success then self.diag:failure('editor',err,{},self.runtime:snapshot(self.scenario),nil,'scenario kept; native field closed') end
    self:setSearchFocus(false);local closed,closeWhy=self.runtime:close();self.phase='menu';self.context=nil;self.moving=nil
    if closed==false then
        self.exitToMain=nil;self.message='Native cleanup was not verified; preserved setup and report kept.'
        self.diag:record('field_close',{verified=0,reason=tostring(closeWhy)})
        self:notice(self.message..' Export Diagnostics, then restart the isolated game. '..tostring(closeWhy))
    elseif not success then self:notice('The editor stopped. Your scenario is kept; Export Diagnostics for details.') end
end
return U
