-- Battlefield overlays. No nested editor screens and no native template writes.
local M=require('sandbox.model')
local C=require('sandbox.catalog')
local L=require('sandbox.loadout')
local Names=require('sandbox.names')
local W={}
local tabs={'Items','Magic Schools & Spells','Name'}
local function inside(r,x,y)return r and x>=r.x and y>=r.y and x<r.x+r.w and y<r.y+r.h end
local function trim(s,n)return C.textLimit(tostring(s or ''),n,'...')end
local function button(self,owner,key,label,x,y,w,h,color)
    self:button('config:'..key,label,x,y,w,h,color)
    self.buttons[#self.buttons].configOwner=owner
end
local function text(self,x,y,size,s,color)
    color=color or {0.94,0.94,0.87};self.api.ui.drawText(x,y,size,s,color[1],color[2],color[3],1)
end
function W.find(self,id)
    for _,u in ipairs(self.scenario.units)do if u.id==id then return u end end
end
function W.bounds(self,w)
    local sw,sh=self.api.get('screenW'),self.api.get('screenH')
    w.w=math.max(math.min(360,sw-20),math.min(w.w or 390,sw-20))
    w.h=math.max(math.min(w.tab==3 and 360 or 300,sh-84),math.min(w.h or 390,sh-84))
    w.x=math.max(10,math.min(w.x or 20,sw-w.w-10));w.y=math.max(42,math.min(w.y or 56,sh-w.h-42))
    return w
end
function W.close(self)
    if self.editWindow then local w=self.editWindow;self.lastConfigBounds={x=w.x,y=w.y,w=w.w,h=w.h,manualSize=w.manualSize}end
    if self.editWindow or self.equipDialog then self:setSearchFocus(false);self.releaseBarrier=true;self.dragBlocked=true end
    self.editWindow=nil;self.equipDialog=nil
end
function W.open(self,u)
    local ready,why=self.runtime:ready(self.scenario);if not ready then self:notice(why);return false end
    local state;state,why=L.read(self.runtime,self.runtime.live[u.id])
    if not state then self:notice(why);return false end
    self:setSearchFocus(false);local old=self.editWindow or self.lastConfigBounds or {}
    local slots=0;for _,row in ipairs(state.items)do if row.slotType>0 or row.id>=0 then slots=slots+1 end end
    local height=old.manualSize and old.h or math.min(430,194+math.min(slots,6)*42)
    self.editWindow=W.bounds(self,{x=old.x,y=old.y and old.y+old.h-height or nil,w=old.w,h=height,manualSize=old.manualSize,unitId=u.id,native=state.unit,generation=state.generation,
        tab=1,expanded={},schoolPages={},slotPage=1,magicOffset=1,spellSearch=''})
    local caps=type(self.api.testFieldEditorCapabilities)=='function' and self.api.testFieldEditorCapabilities() or {}
    self.editWindow.reduction=caps.schoolLevelReduction==1
    self.context=nil;self.moving=nil;self.copyTemplate=nil;self.releaseBarrier=true;self.dragBlocked=true
    self.message='Editing '..M.displayName(u)..' | Native Inspect stays read only.'
    return true
end
function W.target(self)
    local w=self.editWindow;if not w then return end
    local u=W.find(self,w.unitId)
    if not u or self.runtime.live[u.id]~=w.native then W.close(self);self.message='Unit changed; reopen its configuration window.';return end
    local state,why=L.read(self.runtime,w.native)
    if not state or state.generation~=w.generation then W.close(self);self:notice(why or 'Unit generation changed; reopen its configuration window.');return end
    return u,state
end
function W.owns(self,x,y)
    return self.equipDialog~=nil or inside(self.editWindow,x,y)
end
function W.focusRect(self)
    local w=self.editWindow
    return w and (self.textTarget=='native_name' and w.nativeNameRect or self.textTarget=='label' and w.labelRect or self.textTarget=='spells' and w.spellRect) or self.searchRect
end
function W.input(self,mouse,freshLeft,x,y)
    local w=self.editWindow
    if w then W.bounds(self,w)end
    if w and w.drag then
        if mouse&1~=0 then
            local d=w.drag
            if d.resize then w.w=d.w+x-d.x;w.h=d.h-y+d.y;w.y=d.top-w.h
            else w.x=x-d.dx;w.y=y-d.dy end
            W.bounds(self,w)
        else w.drag=nil;self.releaseBarrier=true end
        self.lastMouse=mouse;self.dragBlocked=true;return true
    end
    local owner=self.equipDialog and 'dialog' or inside(w,x,y) and 'window'
    if not owner then return false end
    if freshLeft then
        local field=W.focusRect(self)
        if self.searchFocused and not inside(field,x,y)then self:setSearchFocus(false)end
        local hit=false
        for i=#self.buttons,1,-1 do local b=self.buttons[i]
            if b.configOwner==owner and inside(b,x,y)then self.pending=b.key;hit=true;break end
        end
        if owner=='window' and not hit then
            if y>=w.y+w.h-29 then w.drag={dx=x-w.x,dy=y-w.y}
            elseif x>w.x+w.w-22 and y<w.y+22 then w.drag={resize=true,x=x,y=y,w=w.w,h=w.h,top=w.y+w.h};w.manualSize=true end
        end
    end
    self.dragBlocked=true;self.lastCell=nil;self.dragOrigin=nil;self.lastMouse=mouse
    return true
end
function W.items(self)
    local values={};local query=C.fold(self.itemSearch or '');local kind=self.itemSlot
    for _,item in ipairs(self.catalog.items or {})do
        local origin=item.origin or {kind='unknown',modded=false}
        local source=self.itemOrigin or 'all'
        if (source=='all' or source=='modded' and origin.modded or source=='unknown' and origin.kind=='unknown') and
            (kind==nil or item.slot==kind) and C.fold(item.name):find(query,1,true)then values[#values+1]=item end
    end
    self.filteredItems=values;self.itemPage=math.max(1,math.min(self.itemPage or 1,math.max(1,math.ceil(#values/5))))
    return values
end
function W.drawCatalog(self,p)
    local ui=self.api.ui;local values=W.items(self);local focused=self.searchFocused and self.textTarget=='items'
    local label=(self.itemSearch or '')=='' and (focused and 'Type to search items...' or 'Search items...') or trim(self.itemSearch,28)
    self.searchRect={x=p+8,y=285,w=234,h=27}
    self:button('search',label..(focused and ' |' or ''),p+8,285,234,27,focused and {0.16,0.31,0.43} or nil)
    self:button('searchclear','Clear',p+246,285,46,27)
    self:button('filter','Slot: '..(L.slotNames[self.itemSlot] or 'All'),p+8,255,138,24)
    local sources={all='All Items',modded='Modded Items',unknown='Unknown origin'}
    self:button('itemorigin',sources[self.itemOrigin or 'all'],p+154,255,138,24)
    for row=1,5 do local index=((self.itemPage or 1)-1)*5+row;local item=values[index];local y=251-row*36
        if item then
            ui.drawRect(p+8,y,284,34,0.13,0.17,0.20,0.98)
            local drawn=type(ui.drawItemIconFit)=='function' and ui.drawItemIconFit(p+11,y+3,32,28,item.id)
            if not drawn then text(self,p+20,y+10,12,'?')end
            text(self,p+50,y+21,10,trim(item.name,34))
            text(self,p+50,y+6,9,'#'..item.id..' '..(L.slotNames[item.slot] or '?')..(item.origin and item.origin.modded and ' [Mod]' or ''))
            self:button('iteminfo:'..item.id,'Inspect',p+179,y+2,54,17)
            self:button('item:'..item.id,'Select',p+236,y+2,54,17,self.selectedItem and self.selectedItem.id==item.id and {0.18,0.34,0.5} or nil)
        end
    end
    if #values==0 then text(self,p+18,208,12,'No matching items. Clear search or filter.')end
    self:button('prev','<',p+8,42,40,25);self:button('next','>',p+252,42,40,25)
    text(self,p+65,50,11,(self.itemPage or 1)..' / '..math.max(1,math.ceil(#values/5)))
end
function W.result(self,ok,why)
    if ok then self.message='Updated; exact native configuration verified.';return end
    if self.runtime.blocked then self:notice(why);return end
    local reason=tostring(why)
    if reason:find('memorize_limit',1,true) or reason:find('spell_level',1,true)then
        reason='Native school level/capacity refused this change. Unmemorize higher-level or excess spells first; known spells are kept. Previous configuration unchanged.'
    elseif reason:find('incompatible_slot',1,true) or reason:find('native_item_restriction',1,true)then
        reason='This unit cannot equip the item in that position. Previous configuration unchanged.'
    elseif reason:find('cursed_item',1,true)then reason='Use Remove and confirm the cursed item first; direct replacement stays protected. Previous configuration unchanged.'
    elseif reason:find('permanent_anatomy_item_unsupported',1,true)then reason='Eye/heart implants have permanent effects. Safe replacement/removal is unavailable; previous configuration unchanged.'end
    self:notice(reason)
end
function W.inspectItem(self,id)
    local ready,before=self.runtime:ready(self.scenario);if not ready then self:notice(before);return end
    if type(self.api.inspectTestFieldItem)~='function' then self:notice('Native item Inspect needs the updated experimental Extender. No substitute card is shown.');return end
    self:setSearchFocus(false);self.inNativeMenu=true
    local ok,detail=self.api.inspectTestFieldItem(id)
    self.inNativeMenu=false;self.releaseBarrier=true;self.dragBlocked=true
    local good,observed,extra=self.runtime:check(self.scenario,true,before)
    if not good then self.runtime:quarantine(self.scenario,observed,nil,extra);self:notice('Item Inspect returned with unverified state. Editing locked; export diagnostics.');return end
    self.runtime:accept(self.scenario,observed)
    if not ok then self:notice('Native item Inspect refused: '..tostring(detail));return end
    self.message='Native item card closed; existing units verified unchanged.'
    self.diag:record('item_inspect',{item_id=id,source=type(detail)=='table' and detail.source or 'unknown',result='field readback verified'})
end
local function dialogFor(self,u,state,item,position)
    self:setSearchFocus(false);self.context=nil;self.releaseBarrier=true;self.dragBlocked=true
    self.equipDialog={unitId=u.id,native=state.unit,generation=state.generation,item=item and M.copy(item) or nil,position=position,page=1}
end
function W.give(self,u)
    local item=self.selectedItem;if not item then return end
    local ready,why=self.runtime:ready(self.scenario);if not ready then self:notice(why);return end
    local state;state,why=L.read(self.runtime,self.runtime.live[u.id]);if not state then self:notice(why);return end
    local slots={};for _,row in ipairs(state.items)do if row.slotType==item.slot then slots[#slots+1]=row end end
    if #slots==0 then self:notice('Incompatible item: '..u.name..' has no '..(L.slotNames[item.slot] or 'matching')..' anatomical slot. Existing configuration unchanged.');return end
    dialogFor(self,u,state,item);local d=self.equipDialog;d.slots=slots
    if #slots==1 then d.position=slots[1].position;d.expected=slots[1].id
        if d.expected<0 then W.commit(self)end
    end
end
function W.commit(self)
    local d=self.equipDialog;if not d then return end
    local ready,why=self.runtime:ready(self.scenario)
    if not ready then self.equipDialog=nil;self:notice(why);return end
    local u=W.find(self,d.unitId);local state=u and L.read(self.runtime,self.runtime.live[u.id])
    if not state or state.unit~=d.native or state.generation~=d.generation then self.equipDialog=nil;self:notice('The selected instance changed. Choose the unit and slot again.');return end
    self.equipDialog=nil;self.releaseBarrier=true;self.dragBlocked=true
    local ok,why=L.equip(self.runtime,u,d.position,d.item,d.expected)
    W.result(self,ok,why)
end
function W.drawDialog(self)
    local d=self.equipDialog;if not d then return end
    local u=W.find(self,d.unitId);if not u then self.equipDialog=nil;return end
    local sw,sh=self.api.get('screenW'),self.api.get('screenH');local width=math.min(450,sw-30)
    local h=d.position~=nil and 190 or 325;local x,y=(sw-width)/2,(sh-h)/2;d.rect={x=x,y=y,w=width,h=h}
    self.api.ui.drawRect(x-3,y-3,width+6,h+6,0.015,0.025,0.035,1)
    self.api.ui.drawRect(x,y,width,h,0.08,0.12,0.16,1)
    text(self,x+12,y+h-24,14,(d.position~=nil and 'Confirm equipment' or 'Choose anatomical position')..' - #'..u.id)
    text(self,x+12,y+h-46,12,trim(M.displayName(u),45))
    if d.position~=nil then
        local state=L.read(self.runtime,self.runtime.live[u.id]);local slot=state and state.items[d.position+1]
        text(self,x+12,y+h-70,11,'Position '..(d.position+1)..' | Current: '..trim(slot and slot.name or '(empty)',38))
        text(self,x+12,y+h-91,11,'Requested: '..trim(d.item and (d.item.name..' #'..d.item.id) or '(empty)',45))
        local cursedRemoval=not d.item and slot and slot.cursed
        if cursedRemoval then text(self,x+12,y+h-113,10,slot.permanentEffects and 'Removes the item; permanent injuries are not healed.' or 'Sandbox override: remove only this cursed item.')end
        button(self,'dialog','confirm',d.item and (d.expected>=0 and 'Replace this item' or 'Equip item') or cursedRemoval and 'Remove cursed item' or 'Remove this item',x+12,y+45,width-24,28)
    else
        text(self,x+12,y+h-66,10,trim(d.item.name..' | native restrictions checked on equip',62))
        for i=1,6 do local row=d.slots[(d.page-1)*6+i];if row then
            button(self,'dialog','slot:'..row.position,'#'..(row.position+1)..' '..trim(row.name or '(empty)',40)..(row.cursed and ' [cursed]' or ''),x+12,y+h-93-i*28,width-24,25)
        end end
        if #d.slots>6 then
            button(self,'dialog','slotprev','<',x+12,y+41,40,22);button(self,'dialog','slotnext','>',x+width-52,y+41,40,22)
        end
    end
    button(self,'dialog','cancel','Cancel',x+12,y+10,width-24,26)
end
function W.draw(self)
    local w=self.editWindow
    if w then
        W.bounds(self,w);local u,state=W.target(self)
        if u then
            local ui=self.api.ui;local x,y,width,top=w.x,w.y,w.w,w.y+w.h
            ui.drawRect(x-2,y-2,width+4,w.h+4,0.015,0.025,0.035,1)
            ui.drawRect(x,y,width,w.h,0.065,0.095,0.125,0.99);ui.drawRect(x,top-29,width,29,0.13,0.23,0.31,1)
            text(self,x+10,top-20,13,trim(M.displayName(u),34)..' | '..(u.team==1 and 'A' or 'B')..' #'..u.id)
            button(self,'window','close','X',x+width-29,top-26,25,23)
            local tabX={x+10,x+110,x+width-72};local tabW={94,width-190,62}
            for i,label in ipairs(tabs)do button(self,'window','tab:'..i,label,tabX[i],top-61,tabW[i],25,w.tab==i and {0.18,0.34,0.46} or nil)end
            if w.tab==1 then W.drawSlots(self,u,state,w)
            elseif w.tab==2 then W.drawMagic(self,u,state,w)
            else W.drawName(self,u,w)end
            button(self,'window','inspect','Native Inspect (read only)',x+10,y+10,190,26)
            text(self,x+width-25,y+7,10,'///',{0.55,0.7,0.78})
        end
    end
    W.drawDialog(self)
end
function W.drawSlots(self,u,state,w)
    local x,top=w.x,w.y+w.h;local slots={}
    for _,row in ipairs(state.items)do if row.slotType>0 or row.id>=0 then slots[#slots+1]=row end end
    text(self,x+12,top-82,10,'Pick an item on the right, then right-click a unit to give it.')
    local perPage=math.max(1,math.min(6,math.ceil((w.h-194)/42)))
    w.slotPage=math.max(1,math.min(w.slotPage,math.max(1,math.ceil(#slots/perPage))))
    for i=1,perPage do local slot=slots[(w.slotPage-1)*perPage+i];local y=top-132-(i-1)*42
        if slot and y>w.y+62 then
            local item=slot.id>=0 and self.catalog.byItemId[slot.id]
            if item and type(self.api.ui.drawItemIconFit)=='function' then self.api.ui.drawItemIconFit(x+12,y+4,28,28,item.id)end
            text(self,x+45,y+24,10,'#'..(slot.position+1)..' '..(L.slotNames[slot.slotType] or 'Unavailable'))
            text(self,x+45,y+9,10,trim(slot.name or '(empty)',math.floor((w.w-165)/6))..(slot.cursed and ' [cursed]' or ''))
            if item then
                button(self,'window','iteminfo:'..slot.id,'Inspect',x+w.w-116,y+17,52,19)
                button(self,'window','remove:'..slot.position,'Remove',x+w.w-61,y+17,52,19)
            end
        end
    end
    button(self,'window','slotsprev','<',x+12,w.y+42,34,22);button(self,'window','slotsnext','>',x+52,w.y+42,34,22)
    text(self,x+99,w.y+49,10,'Slots '..w.slotPage..' / '..math.max(1,math.ceil(#slots/perPage)))
end
function W.magicRows(self,state,w)
    local rows={};local known,memorized={},{}
    for _,id in ipairs(state.known)do known[id]=true end;for _,id in ipairs(state.memorized)do memorized[id]=true end
    local query=C.fold(w.spellSearch)
    for _,school in ipairs(state.schools)do
        local origin=C.schoolOrigin(self.catalog,self.api,school.path);local source=w.schoolOrigin or 'all'
        if source=='all' or source=='modded' and origin.modded or source=='unknown' and origin.kind=='unknown' and not origin.modded then
        school=M.copy(school);school.origin=origin
        rows[#rows+1]={kind='school',school=school,h=31}
        if w.expanded[school.path]then
            rows[#rows+1]={kind='detail',school=school,h=18}
            rows[#rows+1]={kind='origin',school=school,h=18}
            rows[#rows+1]={kind='unlock',school=school,h=27}
            local spells={};for _,spell in ipairs(self.catalog.spells)do
                if spell.path==school.path and spell.level>=1 and C.fold(spell.name..' #'..spell.id):find(query,1,true)then spells[#spells+1]=spell end
            end
            local page=math.max(1,math.min(w.schoolPages[school.path]or 1,math.max(1,math.ceil(#spells/3))));w.schoolPages[school.path]=page
            for i=(page-1)*3+1,math.min(page*3,#spells)do
                rows[#rows+1]={kind='spell',spell=spells[i],school=school,known=known[spells[i].id],memorized=memorized[spells[i].id],h=33}
            end
            rows[#rows+1]={kind='pages',school=school,page=page,pages=math.max(1,math.ceil(#spells/3)),h=24}
        end
        end
    end
    return rows
end
function W.drawMagic(self,u,state,w)
    local x,top=w.x,w.y+w.h
    text(self,x+12,top-80,10,'Native Inspect is read only; choose memorized spells here.')
    w.spellRect={x=x+12,y=top-114,w=w.w-158,h=25}
    local focused=self.searchFocused and self.textTarget=='spells'
    button(self,'window','spellsearch',(w.spellSearch=='' and 'Search spells...' or trim(w.spellSearch,30))..(focused and ' |' or ''),x+12,top-114,w.w-158,25,focused and {0.16,0.31,0.43} or nil)
    local sources={all='All schools',modded='Modded schools',unknown='Unknown origin'}
    button(self,'window','schoolorigin',sources[w.schoolOrigin or 'all'],x+w.w-140,top-114,128,25)
    local rows=W.magicRows(self,state,w);w.magicOffset=math.max(1,math.min(w.magicOffset,#rows));local cursor=top-122
    for i=w.magicOffset,#rows do local row=rows[i];local y=cursor-row.h
        if y<w.y+68 then break end
        local path=row.school.path
        if row.kind=='school'then
            button(self,'window','expand:'..path,(w.expanded[path]and '- 'or '+ ')..trim(row.school.name,23)..(row.school.origin.modded and ' [Mod]' or '')..' | base '..row.school.base,x+12,y+3,w.w-112,25)
            if row.school.base>(w.reduction and 1 or row.school.templateBase)then button(self,'window','level:'..path..':'..(row.school.base-1),'-',x+w.w-92,y+3,34,25)
            else text(self,x+w.w-80,y+10,13,'-',{0.35,0.40,0.43})end
            if row.school.base<3 then button(self,'window','level:'..path..':'..(row.school.base+1),'+',x+w.w-52,y+3,34,25)
            else text(self,x+w.w-41,y+10,13,'+',{0.35,0.40,0.43})end
        elseif row.kind=='detail'then
            text(self,x+18,y+5,10,'Bonus '..row.school.bonus..' | effective '..row.school.level..' | native capacity '..row.school.allowance)
        elseif row.kind=='origin'then
            local o=row.school.origin;local source=o.definedBy or o.lastModifiedBy
            if not source and o.spellMods then local mods={};for name in pairs(o.spellMods)do mods[#mods+1]=name end;table.sort(mods);source='Mod spells: '..table.concat(mods,', ')end
            text(self,x+18,y+5,9,trim('Origin: '..(source or (o.kind=='unknown' and 'unknown' or 'unchanged baseline record')),65))
        elseif row.kind=='unlock'then
            button(self,'window','unlock:'..path,'Unlock all spells up to base '..row.school.base..' (known only)',x+18,y+2,w.w-36,23)
        elseif row.kind=='spell'then
            local spell=row.spell;local eligible=spell.level<=math.min(row.school.base,row.school.level)
            text(self,x+20,y+19,10,trim(spell.name,math.floor((w.w-120)/6))..' #'..spell.id)
            text(self,x+20,y+5,9,'Level '..spell.level..(row.known and ' | Known' or eligible and ' | Eligible' or ' | Locked'))
            if row.known then button(self,'window','memorize:'..spell.id,row.memorized and '[x] Mem' or '[ ] Mem',x+w.w-88,y+5,70,23,row.memorized and {0.16,0.34,0.40} or nil)
            elseif eligible then button(self,'window','learn:'..spell.id,'Learn',x+w.w-88,y+5,70,23)end
        else
            button(self,'window','spellprev:'..path,'<',x+20,y+1,32,21);button(self,'window','spellnext:'..path,'>',x+58,y+1,32,21)
            text(self,x+104,y+6,10,'Spells '..row.page..' / '..row.pages)
        end
        cursor=y
    end
    if #rows==0 then text(self,x+15,top-143,11,'No matching existing schools. Try All schools.')end
    button(self,'window','magicup','Scroll up',x+12,w.y+42,86,22);button(self,'window','magicdown','Scroll down',x+106,w.y+42,96,22)
end
local function wrappedName(self,value,x,y,columns,size,color)
    local line,at='',0
    if utf8 then
        for _,cp in utf8.codes(value)do
            if at==columns then text(self,x,y,size,line,color);y=y-15;line='';at=0 end
            line=line..utf8.char(cp);at=at+1
        end
    else
        for i=1,#value do if at==columns then text(self,x,y,size,line,color);y=y-15;line='';at=0 end;line=line..value:sub(i,i);at=at+1 end
    end
    if line~=''then text(self,x,y,size,line,color)end
end
function W.drawName(self,u,w)
    local x,top=w.x,w.y+w.h;local value=u.nativeName or '';local supported=Names.available(self.api)
    text(self,x+14,top-87,12,'Native individual name')
    text(self,x+14,top-108,10,supported and 'Used by native Inspect and combat messages.'or'Native naming API unavailable; existing labels are preserved.')
    w.nativeNameRect={x=x+14,y=top-151,w=w.w-28,h=29};w.labelRect=w.nativeNameRect
    local focus=self.searchFocused and self.textTarget=='native_name'
    button(self,'window','namesearch','',x+14,top-151,w.w-28,29,focus and{0.16,0.31,0.43}or nil)
    local shown=(value~=''and value or 'Click to name this unit...')..(focus and' |'or'')
    -- textWidth is preview-world-only upstream. A conservative one-em bound
    -- fits the complete bounded name without issuing refused queries per frame.
    local size=math.min(13,(w.w-40)/math.max(1,utf8 and utf8.len(shown)or #shown))
    text(self,x+19,top-144,size,shown)
    local count=utf8 and utf8.len(value)or #value
    text(self,x+14,top-174,11,('Characters: %d / %d | UTF-8 bytes: %d / %d'):format(count,M.nativeNameCharacters,#value,M.nativeNameBytes))
    if w.nameError then wrappedName(self,w.nameError,x+14,top-194,math.max(20,math.floor((w.w-28)/6)),10,{1,0.48,0.36})
    else text(self,x+14,top-194,10,'Native log lines have a fixed limit; long entries can be cut off.')end
    text(self,x+14,top-237,10,'Type: '..trim(u.name,36)..' | model #'..u.id..' | native #'..w.native)
    if u.label then
        text(self,x+14,top-257,10,'Previous Sandbox-only label (not applied automatically):')
        wrappedName(self,u.label,x+14,top-275,math.max(18,math.floor((w.w-28)/7)),11)
        button(self,'window','namelegacy','Use previous label',x+14,w.y+43,158,25)
    end
    button(self,'window','nameclear','Clear native name',x+w.w-173,w.y+43,159,25)
end
function W.text(self,event)
    local target=self.textTarget;if target~='spells' and target~='label' and target~='native_name'then return false end
    local u=W.target(self);if not u then return true end
    local w=self.editWindow;local old=target=='native_name' and (u.nativeName or '')or target=='label' and (u.label or '') or w.spellSearch;local nextText=old
    if event.type=='text'then
        if type(event.text)~='string'then return true end
        if utf8 then local ok,n=pcall(utf8.len,event.text);if not ok or not n then self.message='Invalid UTF-8 input rejected.';return true end end
        nextText=old..event.text
    elseif event.type=='backspace'then nextText=C.backspace(old)
    elseif event.type=='clear'then nextText=''
    else return false end
    if target=='native_name'then
        local ok,why=self.runtime:setNativeName(u,nextText)
        w.nameError=not ok and why or nil;self.message=ok and ('Native name updated: '..M.displayName(u))or why
    elseif target=='label'then
        local ok,why=self.runtime:setLabel(u,nextText)
        if not ok then self.message=why else self.message='Sandbox display label updated; native type/name unchanged.' end
    else
        w.spellSearch=C.textLimit(nextText,96);w.schoolPages={};w.magicOffset=1
    end
    return true
end
function W.dispatch(self,action)
    local value=type(action)=='string' and action:match('^config:(.*)$');if not value then return false end
    local cmd,a,b=value:match('^([^:]+):?([^:]*):?(.*)$');a=tonumber(a);b=tonumber(b)
    if cmd=='cancel'then self.equipDialog=nil;self.releaseBarrier=true;return true
    elseif cmd=='confirm'then W.commit(self);return true
    elseif cmd=='slotprev' or cmd=='slotnext'then
        local d=self.equipDialog;if d then d.page=math.max(1,math.min(d.page+(cmd=='slotnext' and 1 or -1),math.ceil(#d.slots/6)))end;return true
    elseif cmd=='slot'then
        local d=self.equipDialog;local u=d and W.find(self,d.unitId);local state=u and L.read(self.runtime,self.runtime.live[u.id])
        if state and state.unit==d.native and state.generation==d.generation then
            local slot=state.items[a+1];d.position=a;d.expected=slot.id
            if slot.id<0 then W.commit(self)else self.releaseBarrier=true end
        else self.equipDialog=nil;self:notice('Selected instance changed; choose its slot again.')end
        return true
    elseif cmd=='iteminfo'then W.inspectItem(self,a);return true
    elseif cmd=='close'then W.close(self);return true end
    local u,state=W.target(self);if not u then return true end;local w=self.editWindow
    if cmd=='tab'then
        self:setSearchFocus(false);w.tab=a
        if not w.manualSize then
            local slots=0;for _,row in ipairs(state.items)do if row.slotType>0 or row.id>=0 then slots=slots+1 end end
            local height=a==2 and 430 or a==3 and 360 or math.min(430,194+math.min(slots,6)*42)
            w.y=w.y+w.h-height;w.h=height;W.bounds(self,w)
        end
    elseif cmd=='schoolorigin'then local nextSource={all='modded',modded='unknown',unknown='all'};w.schoolOrigin=nextSource[w.schoolOrigin or 'all'];w.magicOffset=1
    elseif cmd=='inspect'then self:inspect(u)
    elseif cmd=='slotsprev' or cmd=='slotsnext'then w.slotPage=w.slotPage+(cmd=='slotsnext'and 1 or -1)
    elseif cmd=='remove'then
        local slot=state.items[a+1];if slot and slot.id>=0 then dialogFor(self,u,state,nil,a);self.equipDialog.expected=slot.id end
    elseif cmd=='expand'then w.expanded[a]=not w.expanded[a]
    elseif cmd=='magicup' or cmd=='magicdown'then w.magicOffset=w.magicOffset+(cmd=='magicdown'and 3 or -3)
    elseif cmd=='spellprev' or cmd=='spellnext'then w.schoolPages[a]=(w.schoolPages[a]or 1)+(cmd=='spellnext'and 1 or -1)
    elseif cmd=='level'then local ok,why=L.setLevel(self.runtime,u,a,b);W.result(self,ok,why)
    elseif cmd=='unlock'then local ok,why=L.unlock(self.runtime,u,a);W.result(self,ok,why)
    elseif cmd=='learn'then
        for _,spell in ipairs(self.catalog.spells)do if spell.id==a then local ok,why=L.learn(self.runtime,u,spell);W.result(self,ok,why);break end end
    elseif cmd=='memorize'then
        local found=false;for _,id in ipairs(state.memorized)do if id==a then found=true end end
        local info=self.api.spellInfo(a);if info then local ok,why=self.runtime:memorize(u,a..':'..info.name,not found);W.result(self,ok,why)end
    elseif cmd=='spellsearch'then self:setSearchFocus(true,'spells')
    elseif cmd=='namesearch'then self:setSearchFocus(true,'native_name');self.message='Type a native name; maximum 32 characters and 47 UTF-8 bytes.'
    elseif cmd=='nameclear'or cmd=='namelegacy'then
        local ok,why=self.runtime:setNativeName(u,cmd=='nameclear'and''or u.label or'')
        w.nameError=not ok and why or nil;self.message=ok and ('Native name updated: '..M.displayName(u))or why
    elseif cmd=='labelsearch'then self:setSearchFocus(true,'label')
    elseif cmd=='labelclear'then local ok,why=self.runtime:setLabel(u,'');W.result(self,ok,why)
    end
    return true
end
return W
