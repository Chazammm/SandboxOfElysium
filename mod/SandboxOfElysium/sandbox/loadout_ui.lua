local L=require('sandbox.loadout')
local E={}
local reasons={incompatible_slot='This unit cannot use that equipment slot.',native_item_restriction='The native game rejected this item for this unit.',
    cursed_item='A cursed item cannot be removed or replaced.',permanent_anatomy_item_unsupported='Eye/heart implants have permanent effects; safe editing is not supported yet.',
    memorize_limit='The native school memorization limit is reached.',spell_level='This spell exceeds the current native school level.',
    new_spell_above_level='The spell is not available at this unit\'s school level.'}
local function explain(why)
    for key,value in pairs(reasons) do if tostring(why):find(key,1,true) then return value..' Previous configuration kept.' end end
    return tostring(why)
end
local function state(self,u)
    local value,why=L.read(self.runtime,self.runtime.live[u.id]);if not value then self:notice(why) end;return value
end
local function schoolByPath(value,path)
    for _,row in ipairs(value.schools) do if row.path==path then return row end end
end
function E.confirmItem(self,u,position,item)
    local current=state(self,u);if not current then return end
    local slot=current.items[position+1];if not slot then self:notice('Equipment slot unavailable.');return end
    local old=slot.id>=0 and (slot.name..' #'..slot.id) or '(empty)'
    local new=item and (item.name..' #'..item.id) or '(empty)'
    if item and slot.id==item.id then self:notice('This exact item is already in the selected slot.');return end
    local rows={{0,u.name..' | '..(L.slotNames[slot.slotType] or 'Slot')..' position '..(position+1)},
        {0,'Current: '..old},{0,'Requested: '..new},
        {1,slot.id>=0 and (item and 'Replace this item' or 'Remove this item') or 'Equip this item'}, {999,'Cancel'}}
    if self:menu('Confirm equipment change',rows)~=1 then return end
    local ok,why=L.equip(self.runtime,u,position,item,slot.id)
    if not ok then self:notice(explain(why)) else self.message='Equipment updated; native item position and identity verified.' end
end
function E.chooseSlot(self,u,item)
    local value=state(self,u);if not value then return end
    local choices={};local rows={{0,item.name..' #'..item.id..' | '..(L.slotNames[item.slot] or 'Unknown slot')}}
    for _,slot in ipairs(value.items) do if slot.slotType>0 and slot.slotType==item.slot then
        choices[#choices+1]=slot;rows[#rows+1]={100+#choices,'Position '..(slot.position+1)..': '..(slot.id>=0 and slot.name..' #'..slot.id or '(empty)')}
    end end
    if #choices==0 then self:notice('Incompatible: this unit has no '..(L.slotNames[item.slot] or 'matching')..' slot. Current equipment kept.');return end
    rows[#rows+1]={999,'Cancel'}
    local id=self:menu('Choose equipment position',rows);local slot=choices[id-100]
    if slot then E.confirmItem(self,u,slot.position,item) end
end
function E.catalog(self,u,initialSlot)
    local search,page,slot='',1,initialSlot
    local index=0;for i,v in ipairs(self.catalog.itemSlots) do if v==slot then index=i end end
    while not self.runtime.blocked do
        local filtered={}
        for _,item in ipairs(self.catalog.items) do if (not slot or slot==item.slot) and item.name:lower():find(search:lower(),1,true) then filtered[#filtered+1]=item end end
        page=math.max(1,math.min(page,math.max(1,math.ceil(#filtered/6))))
        local rows={{1,'Search: '..(search~='' and search or '(all names)')},{2,'Slot filter: '..(slot and L.slotNames[slot] or 'All')},
            {0,#filtered..' items | page '..page..'/'..math.max(1,math.ceil(#filtered/6))}}
        for i=(page-1)*6+1,math.min(page*6,#filtered) do local item=filtered[i];rows[#rows+1]={100+i,item.name..' #'..item.id..' | '..(L.slotNames[item.slot] or 'Unknown')} end
        rows[#rows+1]={3,'Previous'};rows[#rows+1]={4,'Next'};rows[#rows+1]={999,'Back'}
        local id=self:menu('Items - search and select',rows)
        if id==999 then return elseif id==1 then local q=self:prompt('Search items','Name contains:');if q then search=q;page=1 end
        elseif id==2 then index=(index+1)%(#self.catalog.itemSlots+1);slot=self.catalog.itemSlots[index];page=1
        elseif id==3 then page=page-1 elseif id==4 then page=page+1
        elseif filtered[id-100] then E.chooseSlot(self,u,filtered[id-100]) end
    end
end
function E.items(self,u)
    local page=1
    while not self.runtime.blocked do
        local value=state(self,u);if not value then return end
        local slots={};for _,slot in ipairs(value.items) do if slot.slotType>0 or slot.id>=0 then slots[#slots+1]=slot end end
        page=math.max(1,math.min(page,math.max(1,math.ceil(#slots/7))))
        local rows={{0,u.name..' | '..#slots..' anatomical positions'},{1,'Search / browse item catalog'}}
        for i=(page-1)*7+1,math.min(page*7,#slots) do local slot=slots[i]
            rows[#rows+1]={100+i,'#'..(slot.position+1)..' '..(L.slotNames[slot.slotType] or 'Unavailable')..': '..(slot.id>=0 and slot.name..' #'..slot.id..(slot.cursed and ' [cursed]' or '') or '(empty)')}
        end
        rows[#rows+1]={2,'Previous slots'};rows[#rows+1]={3,'Next slots'};rows[#rows+1]={999,'Done'}
        local id=self:menu('Items - '..u.name,rows)
        if id==999 then return elseif id==1 then E.catalog(self,u)
        elseif id==2 then page=page-1 elseif id==3 then page=page+1 elseif slots[id-100] then
            local slot=slots[id-100]
            if slot.id>=0 then
                local pick=self:menu('Equipment position '..(slot.position+1),{{0,slot.name..' #'..slot.id},{1,'Choose replacement item'},{2,'Remove item (confirm)'},{999,'Back'}})
                if pick==1 then E.catalog(self,u,slot.slotType) elseif pick==2 then E.confirmItem(self,u,slot.position,nil) end
            else E.catalog(self,u,slot.slotType) end
        end
    end
end
function E.learn(self,u,path)
    local search,page='',1
    while not self.runtime.blocked do
        local value=state(self,u);if not value then return end
        local school=schoolByPath(value,path);if not school then return end
        local known={};for _,id in ipairs(value.known) do known[id]=true end
        local choices={};for _,spell in ipairs(self.catalog.spells) do if spell.path==path and spell.level>=1 and spell.level<=school.level and not known[spell.id] and spell.name:lower():find(search:lower(),1,true) then choices[#choices+1]=spell end end
        page=math.max(1,math.min(page,math.max(1,math.ceil(#choices/7))))
        local rows={{0,school.name..' #'..path..' | effective level '..school.level},{0,'Learning adds a known spell; memorization is selected separately.'},
            {1,'Search: '..(search~='' and search or '(all available)')}}
        for i=(page-1)*7+1,math.min(page*7,#choices) do local spell=choices[i];rows[#rows+1]={100+i,spell.name..' #'..spell.id..' | level '..spell.level} end
        rows[#rows+1]={2,'Previous'};rows[#rows+1]={3,'Next'};rows[#rows+1]={999,'Back'}
        local id=self:menu('Learn spell - '..#choices..' available',rows)
        if id==999 then return elseif id==1 then local q=self:prompt('Search available spells','Name contains:');if q then search=q;page=1 end
        elseif id==2 then page=page-1 elseif id==3 then page=page+1 elseif choices[id-100] then
            local spell=choices[id-100]
            if self:menu('Learn '..spell.name..' #'..spell.id,{{0,'Existing known/random spells stay unchanged.'},{1,'Add to known spells only'},{999,'Cancel'}})==1 then
                local ok,why=L.learn(self.runtime,u,spell);if not ok then self:notice(explain(why)) end
            end
        end
    end
end
function E.school(self,u,path)
    while not self.runtime.blocked do
        local value=state(self,u);if not value then return end;local row=schoolByPath(value,path);if not row then return end
        local count=0;for _,id in ipairs(value.memorized) do if self.api.spellInfo(id).path==path then count=count+1 end end
        local rows={{0,row.name..' #'..path..' | base '..row.base..' | bonus '..row.bonus..' | effective '..row.level},
            {0,'Memorized: '..count..' / native capacity '..row.allowance},
            {row.base<3 and 1 or 0,row.base<3 and ('Increase base level '..row.base..' -> '..(row.base+1)) or 'Base level: supported maximum reached'},
            {2,'Known spells / memorization'},{3,'Learn an available spell'},{999,'Back'}}
        local id=self:menu('Magic school - '..u.name,rows)
        if id==999 then return elseif id==1 then
            if self:menu('Confirm base-school increase',{{0,row.name..': base '..row.base..' -> '..(row.base+1)},{0,'No random spells are selected or replaced.'},{1,'Increase this base school'},{999,'Cancel'}})==1 then
                local ok,why=L.raise(self.runtime,u,path);if not ok then self:notice(explain(why)) end
            end
        elseif id==2 then self:spellEditor(u,path) elseif id==3 then E.learn(self,u,path) end
    end
end
function E.magic(self,u)
    while not self.runtime.blocked do
        local value=state(self,u);if not value then return end
        local rows={{0,'Base schools are separate from equipment/temporary bonuses.'},{1,'All known spells / memorization'}}
        for i,row in ipairs(value.schools) do rows[#rows+1]={100+i,row.name..' #'..row.path..' | base '..row.base..' + bonus '..row.bonus..' = '..row.level} end
        if #value.schools==0 then rows[#rows+1]={0,'This unit has no existing base school to increase.'} end
        rows[#rows+1]={999,'Done'}
        local id=self:menu('Spells and magic schools - '..u.name,rows)
        if id==999 then return elseif id==1 then self:spellEditor(u) elseif value.schools[id-100] then E.school(self,u,value.schools[id-100].path) end
    end
end
return E
