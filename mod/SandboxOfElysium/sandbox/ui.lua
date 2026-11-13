local M=require('sandbox.model')
local Catalog=require('sandbox.catalog')
local Runtime=require('sandbox.runtime')
local Report=require('sandbox.report')
local U={};U.__index=U
local kinds={'Single','Horizontal Row','Vertical Row','Square'}
local categories={'All','human','animal','undead','demonic','flying','ranged'}
local function contains(t,v) for _,x in ipairs(t) do if x==v then return true end end;return false end
function U.new(api)
    local self=setmetatable({api=api,scenario=M.new(),team=1,formation=1,n=1,search='',category=1,page=1,
        phase='menu',message='',buttons={},lastMouse=0,pending=nil,native=false,context=nil},U)
    self.report=Report.new(api)
    self.drawHook=api.wrap('BATTLE_DRAW',function(next) local result=next();if self.phase=='prepare' or self.phase=='after' then self:draw() end;return result end)
    self.waitHook=api.wrap('BATTLE_WAIT',function(next,b,m)
        local id=next(b,m)
        if self.phase=='prepare' or self.phase=='after' then
            local buttons=api.get('mouseButtons') or 0
            self:input(buttons)
            api.set('mouseButtons',0)
            return 0
        end
        return id
    end)
    return self
end
function U:ensureCatalog()
    if self.catalog then return end
    self.catalog=Catalog.read(self.api);self.runtime=Runtime.new(self.api,self.catalog)
    self.filtered=Catalog.filter(self.catalog,'','All');self.selected=self.api.findMonster('Spearman')
    local a=self.catalog.byId[self.selected];local b=self.catalog.byId[self.api.findMonster('Goblin')]
    if a and b then M.add(self.scenario,a.id,a.name,1,8,9);M.add(self.scenario,b.id,b.name,2,18,9) end
end
function U:prompt(title,prompt)
    local m=self.catalog.byId[self.selected] or self.catalog.monsters[1]
    return self.api.ui.nameBox(title,prompt,m.sprite,42)
end
function U:menu(title,rows)
    local ui=self.api.ui
    ui.screenBegin(title);ui.screenWidth(math.min(680,self.api.get('screenW')-30));ui.sectionBegin('')
    for _,row in ipairs(rows) do ui.text(row[1],row[2]) end
    ui.sectionEnd();ui.bindEscape(999);return ui.wait()
end
function U:notice(text)
    while self:menu('SandboxOfElysium',{{0,text},{1,'OK'}})~=1 do end
end
function U:setup()
    self:ensureCatalog()
    while true do
        local s=self.scenario
        local rows={{0,'Native battlefield: Grass, no fort. Size: native automatic.'},
            {0,self.message},
            {0,'Small / Medium / Large / Extra Large: unavailable in test-field API.'},
            {1,'Team A color: '..M.colors[s.colors[1]][1]}, {2,'Team B color: '..M.colors[s.colors[2]][1]},
            {3,'Prepare battlefield'}, {4,'Load scenario'}, {5,'Browse available terrain data (read only)'},
            {6,'API limitations'}, {7,'Run small native battle check'}, {8,'Add unit to setup ('..#s.units..' placed)'}, {10,'Save setup'}, {999,'Back'}}
        if self.snapshot then table.insert(rows,#rows,{9,'Reset last pre-battle setup'}) end
        local id=self:menu('Sandbox - battlefield',rows)
        if id==999 then return end
        if id==1 or id==2 then s.colors[id]=s.colors[id]%7+1
        elseif id==3 then
            self:prepare()
        elseif id==4 then self:load()
        elseif id==5 then self:terrainBrowser()
        elseif id==6 then self:notice('Grass only; native width; no attack-sprite or mod-origin API. No school-level setter or unit slot preflight. See API-GAPS.md.')
        elseif id==7 then self:smallCheck()
        elseif id==9 and self.snapshot then self.scenario=M.copy(self.snapshot);self.message='Pre-battle setup selected; native restoration checked on Prepare'
        elseif id==10 then self:save()
        elseif id==8 then
            self:browse()
            local text=self:prompt('Add unit','Team,x,y (zero based), e.g. 1,8,9 or 2,18,9:')
            if text then
                local team,x,y=text:match('^(%d+),%s*(%d+),%s*(%d+)$');team=tonumber(team);x=tonumber(x);y=tonumber(y)
                if (team==1 or team==2) and x and x<1000 and y and y<20 and not M.at(s,x,y) then local m=self.catalog.byId[self.selected];M.add(s,m.id,m.name,team,x,y)
                else self:notice('Invalid coordinates, team or occupied cell. Use Team,x,y.') end
            end
        end
    end
end
function U:smallCheck()
    local s=M.new();M.add(s,self.api.findMonster('Spearman'),'Spearman',1,8,9);M.add(s,self.api.findMonster('Goblin'),'Goblin',2,18,9)
    M.add(s,self.api.findMonster('Goblin'),'Goblin',2,18,10)
    local old=self.scenario;self.scenario=s
    local ok,why=self.runtime:build(s)
    if ok then self:fight(); self:results();self.runtime:close() else self:notice(why) end
    self.scenario=old;self.phase='menu'
end
function U:terrainBrowser()
    local page=1
    while true do
        local rows={{0,'Data inventory only: test-field API cannot select these terrains.'}}
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
function U:browse()
    while true do
        local ui=self.api.ui;ui.screenBegin('Select unit');ui.screenWidth(570);ui.sectionBegin('Units - loaded database')
        ui.text(1,'Search: '..(self.search=='' and '(all)' or self.search));ui.text(2,'Filter: '..categories[self.category])
        for i=(self.page-1)*5+1,math.min(self.page*5,#self.filtered) do local m=self.filtered[i]
            ui.monsterRow(100+i,m.id,m.name,'Select | #'..m.id..' | A '..M.count(self.scenario,1,m.id)..' / B '..M.count(self.scenario,2,m.id))
        end
        ui.text(3,'Previous page');ui.text(4,'Next page');ui.text(0,'Idle picture only. Mod provenance and attack picture unavailable.')
        ui.text(999,'Back');ui.sectionEnd();ui.bindEscape(999)
        local id=ui.wait()
        if id==999 then return elseif id==1 then local q=self:prompt('Search units','Name contains (empty clears):');if q then self.search=q;self.page=1 end
        elseif id==2 then self.category=self.category%#categories+1;self.page=1
        elseif id==3 then self.page=self.page-1 elseif id==4 then self.page=self.page+1
        elseif id>100 and self.filtered[id-100] then self.selected=self.filtered[id-100].id;self.copyTemplate=nil;return end
        self:refresh()
    end
end
function U:button(key,label,x,y,w,h,color)
    local ui=self.api.ui;color=color or {0.15,0.19,0.23}
    ui.drawRect(x,y,w,h,color[1],color[2],color[3],0.97)
    ui.drawText(x+5,y+(h-13)/2,13,label,0.96,0.96,0.90,1)
    self.buttons[#self.buttons+1]={key=key,x=x,y=y,w=w,h=h}
end
function U:draw()
    local api,ui=self.api,self.api.ui;local W,H=api.get('screenW'),api.get('screenH')
    self.buttons={}
    local p=W-238
    ui.drawRect(0,H-38,W,38,0.035,0.045,0.055,0.99)
    local after=self.phase=='after' and self.report.result
    self:button('team1','Team A: '..(after and after.teamA.survivors..' alive' or M.count(self.scenario,1)),10,H-32,115,25,self.team==1 and {0.16,0.32,0.52} or nil)
    self:button('team2','Team B: '..(after and after.teamB.survivors..' alive' or M.count(self.scenario,2)),132,H-32,115,25,self.team==2 and {0.16,0.32,0.52} or nil)
    if self.phase=='prepare' then self:button('native',self.native and 'Planning grid' or 'Native view',255,H-32,120,25) end
    self:button('back',self.moving and 'Cancel move' or 'Back',W-105,H-32,95,25)
    if self.phase=='after' then
        ui.drawRect(0,H-122,W,76,0.035,0.045,0.055,0.94)
        ui.drawText(15,H-75,16,'Battle complete',1,0.85,0.55,1)
        ui.drawText(15,H-100,12,'Native unit positions are unavailable after combat. See report; Reset restores the setup.',0.95,0.95,0.9,1)
        ui.drawRect(0,0,W,42,0.035,0.045,0.055,0.95)
        self:button('results','Battle report',12,7,135,28)
        self:button('reset','Reset setup',158,7,130,28)
        self:button('rematch','Rematch',300,7,110,28)
        return
    end
    if self.native then
        ui.drawRect(0,0,W,42,0.035,0.045,0.055,0.95)
        ui.drawText(12,15,13,'Native battlefield. Use Planning grid to edit; native camera remains game controlled.',1,1,1,1)
        return
    end
    -- This is an explicit cell editor, not a replacement for native terrain/graphics.
    local width=self.runtime.width
    local cell=math.min((p-24)/width,(H-118)/20)
    self.grid={x=12,y=64,cell=cell,width=width}
    ui.drawRect(0,46,p,H-84,0.06,0.08,0.065,1)
    for y=0,19 do for x=0,width-1 do
        ui.drawRect(12+x*cell,64+(19-y)*cell,cell-0.6,cell-0.6,0.16,0.20,0.16,1)
    end end
    for _,u in ipairs(self.scenario.units) do local color=M.colors[self.scenario.colors[u.team]]
        ui.drawRect(12+u.x*cell,64+(19-u.y)*cell,cell-0.6,cell-0.6,color[2],color[3],color[4],0.9)
        ui.drawText(13+u.x*cell,64+(19-u.y)*cell,math.min(10,cell*0.5),(u.team==1 and 'A' or 'B')..u.id,1,1,1,1)
    end
    local gx,gy=self:pointerCell()
    ui.drawText(16,H-70,18,'Deployment editor',0.94,0.86,0.66,1)
    ui.drawText(16,H-93,12,'Grass | native automatic size | Team A left, Team B right by default',0.85,0.86,0.82,1)
    local hovered=gx and M.at(self.scenario,gx,gy)
    if hovered then
        ui.drawText(16,H-119,13,(hovered.team==1 and 'A' or 'B')..hovered.id..' '..hovered.name..' | cell '..gx..','..gy,1,1,1,1)
    else
        ui.drawText(16,H-119,12,'Select a unit on the right, then right-click a cell. Drag repeats the formation.',0.76,0.8,0.76,1)
    end
    if gx and self.selected and not self.context then
        for _,c in ipairs(M.cells(kinds[self.formation],self.n,gx,gy)) do
            local valid=c[1]>=0 and c[1]<width and c[2]>=0 and c[2]<20 and not M.at(self.scenario,c[1],c[2])
            if c[1]>=0 and c[1]<width and c[2]>=0 and c[2]<20 then
                ui.drawRect(12+c[1]*cell,64+(19-c[2])*cell,cell-0.6,cell-0.6,valid and 0.3 or 1,valid and 0.9 or 0.2,0.2,0.45)
            end
        end
    end
    ui.drawText(12,45,11,'Planning cells: '..width..' x 20. Native collision is checked on placement.',0.86,0.87,0.78,1)
    ui.drawRect(p,0,238,H-38,0.035,0.045,0.055,0.99)
    local m=self.catalog.byId[self.selected]
    ui.drawText(p+8,H-61,13,m and m.name:sub(1,29) or 'Select unit',1,0.86,0.55,1)
    self:button('browse','Browse sprites / search',p+8,H-96,220,26)
    self:button('formation',kinds[self.formation]..' ('..self.n..')',p+8,H-128,170,26)
    self:button('number','+',p+184,H-128,44,26)
    self:button('fight','Start battle',p+8,H-167,220,30,{0.32,0.21,0.08})
    self:button('save','Save',p+8,H-202,105,26);self:button('load','Load',p+120,H-202,108,26)
    self:button('clear','Clear',p+8,H-234,105,26)
    if self.snapshot then self:button('reset','Reset',p+120,H-234,108,26) end
    self:button('search','Search: '..self.search:sub(1,15),p+8,205,220,25)
    self:button('filter','Filter: '..categories[self.category],p+8,175,220,25)
    for row=1,5 do local index=(self.page-1)*5+row; local item=self.filtered[index]
        if item then self:button('unit:'..index,item.name:sub(1,27),p+8,175-row*27,220,24) end
    end
    self:button('prev','<',p+8,5,40,25);self:button('next','>',p+188,5,40,25)
    ui.drawText(p+58,12,11,self.page..' / '..math.max(1,math.ceil(#self.filtered/5)),0.8,0.8,0.8,1)
    ui.drawRect(0,0,p,38,0.035,0.045,0.055,1)
    ui.drawText(10,20,11,self.moving and 'MOVE: right-click destination; Cancel move keeps the original cell.' or 'Right-click places. Existing unit opens Edit / Move / Copy / Delete.',1,1,0.9,1)
    ui.drawText(10,4,10,self.message:sub(1,100),0.9,0.72,0.4,1)
    if self.context then
        local x,y=math.min(p-134,self.context.px),math.max(130,self.context.py)
        ui.drawRect(x-5,y-124,138,124,0.02,0.025,0.03,1)
        for i,label in ipairs({'Edit','Move','Copy','Delete'}) do self:button('context:'..label,label,x,y-i*28,128,25) end
    end
end
function U:pointerCell()
    if not self.grid then return end
    local g=self.grid;local px,py=self.api.get('uiPointerX'),self.api.get('uiPointerY')
    local x=math.floor((px-g.x)/g.cell);local y=19-math.floor((py-g.y)/g.cell)
    if x>=0 and x<g.width and y>=0 and y<20 then return x,y end
end
function U:input(mouse)
    local freshLeft=mouse&1~=0 and self.lastMouse&1==0
    local freshRight=mouse&2~=0 and self.lastMouse&2==0
    local x,y=self.api.get('uiPointerX'),self.api.get('uiPointerY')
    if freshLeft then
        for i=#self.buttons,1,-1 do local b=self.buttons[i]
            if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then self.pending=b.key;break end
        end
    end
    if not self.native and self.phase=='prepare' and mouse&2~=0 then
        local gx,gy=self:pointerCell()
        if gx then
            local u=M.at(self.scenario,gx,gy)
            if freshRight and u and not self.moving then self.context={unit=u,px=x,py=y};self.dragBlocked=true
            elseif self.moving then
                if freshRight then self.pending={move=true,x=gx,y=gy} end
            elseif not self.context and not self.dragBlocked and (freshRight or self.lastCell~=gx..':'..gy) then
                self.pending={place=true,x=gx,y=gy};self.lastCell=gx..':'..gy
            end
        end
    end
    if mouse&2==0 then self.lastCell=nil;self.dragBlocked=false end
    self.lastMouse=mouse
end
function U:save()
    local name=self:prompt('Save scenario','File name (without .ini):')
    if name then self.message=self.api.writeIni(name,M.encode(self.scenario,self.catalog.mods)) and 'Scenario saved: '..name or 'Save refused: invalid file name, value or quota' end
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
    if not candidate then self.message=why;self:notice(why);return end
    if self.runtime.open then
        local old=self.scenario;local ok;ok,why=self.runtime:build(candidate)
        if not ok then local restored,reason=self.runtime:build(old);self.message=why..(restored and '' or '; restore: '..tostring(reason));self:notice(self.message);return end
    end
    self.scenario=candidate;self.context=nil;self.moving=nil;self.copyTemplate=nil;self.message='Scenario content validated; native positions checked on Prepare'
end
function U:edit(u)
    while true do
        local unit=self.runtime.live[u.id]
        local ui=self.api.ui;ui.screenBegin('Edit '..u.name..' #'..u.id);ui.screenWidth(610);ui.sectionBegin('Native unit')
        ui.monsterRow(0,u.monster,u.name,'Team '..(u.team==1 and 'A' or 'B')..' | cell '..u.x..', '..u.y..' | HP '..tostring(self.api.get('unitHp',unit)))
        ui.text(1,'Spells: select from this unit\'s existing known spells')
        ui.text(2,'Items: inspect inventory and search item catalog')
        ui.text(0,'School level upgrades: unavailable (no supported base-level setter).')
        ui.text(999,'Done');ui.sectionEnd();ui.bindEscape(999);local id=ui.wait()
        if id==999 then return elseif id==1 then self:spellEditor(u) elseif id==2 then self:itemBrowser(u) end
    end
end
function U:spellEditor(u)
    local page=1
    while true do
        local known=u.baseline.known;local rows={{0,'Choose existing known spells. Game memorization limits apply.'}}
        for i=(page-1)*8+1,math.min(page*8,#known) do rows[#rows+1]={100+i,(contains(u.spells,known[i]) and '[x] ' or '[ ] ')..known[i]} end
        rows[#rows+1]={1,'Previous'};rows[#rows+1]={2,'Next'};rows[#rows+1]={999,'Done'}
        local id=self:menu('Battle spells',rows)
        if id==999 then return elseif id==1 then page=math.max(1,page-1) elseif id==2 then page=math.min(math.max(1,math.ceil(#known/8)),page+1)
        elseif known[id-100] then
            local name=known[id-100];if not self.runtime:memorize(u,name,not contains(u.spells,name)) then self:notice('The game rejected this memorization change.') end
        end
    end
end
function U:itemBrowser(u)
    local search,slot,page,slotIndex='',nil,1,0
    while true do
        local rows={{0,'Inventory: '..(#u.items==0 and '(none)' or table.concat(u.items,', '))},
            {0,'Assignment disabled: no documented unit-slot compatibility preflight.'},
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
    self.snapshot=M.copy(self.scenario);self.phase='fight';self.context=nil;self.moving=nil
    self.report:start(self.scenario,self.runtime);self.api.fightTestField();self.report:finish(self.scenario,self.runtime)
    self.phase='after';self.native=true;self.report:export('last-battle')
end
function U:results()
    local r=self.report.result;if not r then return end
    local winner=r.summary.winner==0 and 'Team A' or r.summary.winner==24 and 'Team B' or 'None / unavailable'
    local page=1;local types={};for _,row in pairs(r.types) do types[#types+1]=row end
    table.sort(types,function(a,b) return a.team==b.team and a.name<b.name or a.team<b.team end)
    while true do
        local rows={{0,'Winner: '..winner..' | final round '..r.summary.final_round..' | elapsed wall '..math.floor(r.summary.elapsed_wall_ms/1000)..' s'},
            {0,('A: %d start / %d lost / %d survive; B: %d / %d / %d'):format(r.teamA.start,r.teamA.losses,r.teamA.survivors,r.teamB.start,r.teamB.losses,r.teamB.survivors)}}
        for i=(page-1)*5+1,math.min(page*5,#types) do local t=types[i];rows[#rows+1]={0,('Team %d %s: %d lost / %d survive'):format(t.team,t.name,t.losses,t.survivors)} end
        rows[#rows+1]={0,'Damage attribution partial; complete cast log unavailable. Export includes native kills.'}
        rows[#rows+1]={0,'Native final deployment unavailable. Recorded aftermath cells: '..(r.summary.aftermath_position_count or 0)..' (export).'}
        rows[#rows+1]={1,'Previous'};rows[#rows+1]={2,'Next'};rows[#rows+1]={3,'Export report'};rows[#rows+1]={999,'Post-battle controls'}
        local id=self:menu('Battle report',rows)
        if id==999 then return elseif id==1 then page=math.max(1,page-1) elseif id==2 then page=math.min(math.max(1,math.ceil(#types/5)),page+1)
        elseif id==3 then local name=self:prompt('Export report','File name:');if name then self:notice(self.report:export(name) and 'Report exported as '..name..'.ini' or 'Export refused') end end
    end
end
function U:reset(rematch)
    if not self.snapshot then return end
    local candidate=M.copy(self.snapshot);local ok,why=self.runtime:build(candidate)
    if ok then self.scenario=candidate;self.phase='prepare';self.native=false;self.message='Original pre-battle setup restored';if rematch then self:fight();self:results() end
    else self.message=why;self:notice(why) end
end
function U:dispatch(action)
    if type(action)=='table' then
        if action.move then local ok,why=self.runtime:move(self.moving,action.x,action.y);self.message=ok and 'Moved; configuration preserved' or why;if ok then self.moving=nil;self.dragBlocked=true end
        elseif action.place then
            local skipped,placed=0,0
            for _,c in ipairs(M.cells(kinds[self.formation],self.n,action.x,action.y)) do
                local ok,candidate=self.runtime:add(self.scenario,self.selected,self.team,c[1],c[2],self.copyTemplate)
                if ok then self.scenario=candidate;placed=placed+1 else skipped=skipped+1;self.message=candidate end
                if not self.runtime.open then self:notice(candidate);return false end
            end
            self.message='Placed '..placed..'; skipped '..skipped..(skipped>0 and ' (occupied / native collision / restoration restriction)' or '')
        end;return true
    end
    local prefix,value=action:match('^(%w+):(.+)$')
    if prefix=='unit' then local m=self.filtered[tonumber(value)];if m then self.selected=m.id;self.copyTemplate=nil;self.message='Selected '..m.name end
    elseif prefix=='context' then
        local u=self.context.unit;self.context=nil
        if value=='Edit' then self:edit(u) elseif value=='Move' then self.moving=u;self.message='Right-click target; Back cancels move'
        elseif value=='Copy' then self.selected=u.monster;self.copyTemplate=M.copy(u);self.team=u.team;self.message='Copy selected; native starting spells must match'
        elseif value=='Delete' then
            if M.count(self.scenario,u.team)<=1 then M.remove(self.scenario,u.id);self.message='Unit deleted. Add a unit to each team before preparing again.';return false
            else local candidate=M.copy(self.scenario);M.remove(candidate,u.id);local ok,why=self.runtime:build(candidate)
                if ok then self.scenario=candidate else self.runtime:build(self.scenario);self.message=why end
            end
        end
    elseif action=='back' then if self.moving then self.moving=nil;self.message='Move cancelled; original cell retained' elseif self.context then self.context=nil else return false end
    elseif action=='team1' then self.team=1 elseif action=='team2' then self.team=2
    elseif action=='native' then self.native=not self.native
    elseif action=='browse' then self:browse()
    elseif action=='formation' then self.formation=self.formation%4+1;self.n=self.formation==4 and 2 or 1
    elseif action=='number' then self.n=self.formation==4 and (self.n==4 and 2 or self.n+1) or (self.n%15+1)
    elseif action=='search' then local q=self:prompt('Search units','Name contains:');if q then self.search=q;self.page=1;self:refresh() end
    elseif action=='filter' then self.category=self.category%#categories+1;self.page=1;self:refresh()
    elseif action=='prev' then self.page=self.page-1;self:refresh() elseif action=='next' then self.page=self.page+1;self:refresh()
    elseif action=='fight' then self:fight();self:results()
    elseif action=='results' then self:results()
    elseif action=='save' then self:save() elseif action=='load' then self:load()
    elseif action=='reset' then self:reset(false) elseif action=='rematch' then self:reset(true)
    elseif action=='clear' then self.scenario.units={};self.scenario.nextId=1;self.message='All units removed';return false end
    return self.runtime.open
end
function U:prepare()
    if not self.drawHook or not self.waitHook then self:notice('Required native battle overlay/input hooks are unavailable on this extender/platform.');return end
    local ok,why=self.runtime:build(self.scenario)
    if not ok then self:notice(why);return end
    self.phase='prepare';self.native=false;self.pending=nil;self.lastMouse=0;self.escapeHeld=false
    local success,err=xpcall(function()
        while self.runtime.open do
            self.api.drawTestField()
            if self.pending then local action=self.pending;self.pending=nil;if not self:dispatch(action) then break end end
        end
    end,function(e)return tostring(e) end)
    self.runtime:close();self.phase='menu';self.context=nil;self.moving=nil
    if not success then self:notice('Sandbox stopped safely: '..err) end
end
return U
