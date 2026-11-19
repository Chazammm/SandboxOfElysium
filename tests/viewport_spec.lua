-- UI rectangles, native-readback consumption and frame ownership only.
-- These declared API responses do not simulate native rendering, camera or combat.
local cache={}
function require(name)
    if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end
    return cache[name]
end
local M=require('sandbox.model');local U=require('sandbox.ui');local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function fixture()
    local t={w=800,h=600,x=100,y=200,wheel=0,physical=0,zoom=1,writes={},rects={},texts={},input=0,
        caps={battleZoom=1,battleViewport=1},viewport={version=1,x=0,y=38,width=490,height=524,cellSize=30,
            originX=2,originY=40,minOriginX=-4312,maxOriginX=2,minOriginY=-40,maxOriginY=40,fitsX=false,fitsY=false,fits=false}}
    local api={wrap=function(site,fn)t[site]=fn;return true end,observe=function()end,readIni=function()end,set=function()end,
        get=function(key)if key=='screenW'then return t.w elseif key=='screenH'then return t.h elseif key=='uiPointerX'then return t.x elseif key=='uiPointerY'then return t.y elseif key=='modLastIndex'then return -1 end;return 0 end,
        testFieldEditorCapabilities=function()return t.caps end,testFieldPointerButtons=function()return t.physical end,
        testFieldPointerWheel=function()return t.wheel end,setTestFieldTextFocus=function()return true end,
        testFieldViewport=function()if t.badReadback then return {version=1}end;return M.copy(t.viewport)end,
        testFieldZoom=function()return {zoom=t.zoom,minZoom=0.1,maxZoom=2,cellSize=t.viewport.cellSize}end,
        ui={drawRect=function(...)t.rects[#t.rects+1]={...}end,drawText=function(_,_,_,label)t.texts[#t.texts+1]=label end,drawMonsterIconFit=function()return true end}}
    local function write(kind,value)
        assert(t.inWait and t.nativeWaitReturned and not t.inDraw,'Native viewport writes belong after the native WAIT return.')
        t.writes[#t.writes+1]={kind=kind,value=M.copy(value)}
    end
    api.setTestFieldViewport=function(rect)
        write('viewport',rect);if t.refuseViewport then return false,'declared viewport refusal'end
        for _,key in ipairs({'x','y','width','height'})do t.viewport[key]=rect[key]end
        return true
    end
    api.fitTestFieldViewport=function()
        write('fit');if t.refuseFit then return false,'declared fit refusal'end
        t.zoom=t.fitZoom or 0.137;t.viewport.cellSize=t.fitCell or 4.11
        t.viewport.fits=t.fitFits==true;t.viewport.fitsX=t.fitFits==true;t.viewport.fitsY=t.fitFits==true
        return true
    end
    api.setTestFieldZoom=function(value,x,y)
        write('zoom',{zoom=value,x=x,y=y});t.zoom=value;t.viewport.cellSize=t.h/20*value;return true
    end
    api.battleView=function()return {cellSize=t.viewport.cellSize,baseX=t.viewport.originX,baseY=t.viewport.originY,cameraX=0,cameraY=0,screenW=t.w,screenH=t.h}end
    api.battleCellToScreen=function(x,y)return t.viewport.originX+(x+0.5)*t.viewport.cellSize,t.viewport.originY+(y+0.5)*t.viewport.cellSize end
    api.battleScreenToCell=function(px,py)
        local x,y=math.floor((px-t.viewport.originX)/t.viewport.cellSize),math.floor((py-t.viewport.originY)/t.viewport.cellSize)
        if x>=0 and x<160 and y>=0 and y<20 then return x,y end
    end
    api.battleUnitAt=function()return -1 end
    local u=U.new(api);u.phase='prepare';u.native=true;u.runtime={open=true,generation=1,width=160,live={},objects={}}
    u.catalog={byId={[13]={id=13,name='Spearman'}},monsters={},mods={}};u.filtered={};u.selected=nil
    local originalInput=u.input;u.input=function(self,buttons)t.input=t.input+1;return originalInput(self,buttons)end
    u.notice=function(self,text)self.noticeText=text end
    return u,t,api
end
local function wait(u,t)
    t.inWait=true;t.nativeWaitReturned=false
    local value=t.BATTLE_WAIT(function()t.nativeWaitReturned=true;return 71 end,0,0)
    t.inWait=false;return value
end
local function draw(u,t)
    t.inDraw=true;local value=t.BATTLE_DRAW(function()return 37 end);t.inDraw=false;return value
end
test('usable map rectangle preserves bars and the full panel column at800 and1136 widths',function()
    for _,w in ipairs({800,1136})do for _,h in ipairs({600,900})do
        local u,t=fixture();t.w=w;t.h=h;local r=u:usableViewport()
        assert(r.x==0 and r.y==38 and r.width==w-310 and r.height==h-76)
        assert(not u:ownsPointer(r.x,r.y)and not u:ownsPointer(r.width-0.01,r.y+r.height-0.01))
        assert(u:ownsPointer(r.width,350)and u:ownsPointer(r.width+5,350)and u:ownsPointer(10,37)and u:ownsPointer(10,h-38))
        assert(not u:pointerCell()or not u:ownsPointer(t.x,t.y))
    end end
end)
test('DRAW sends no writes; changed viewport applies before zoom/wheel in WAIT with a fresh-DRAW barrier',function()
    local u,t=fixture();u.requestedZoom=0.4;draw(u,t);assert(#t.writes==0)
    assert(wait(u,t)==0 and #t.writes==1 and t.writes[1].kind=='viewport'and u.viewportReady and u.zoomAwaitingDraw and t.input==0)
    assert(wait(u,t)==0 and #t.writes==1 and t.input==0)
    draw(u,t);wait(u,t);assert(#t.writes==2 and t.writes[2].kind=='zoom'and t.input==0)
    draw(u,t);wait(u,t);assert(t.input==1 and not u.pending)
end)
test('rectangle writes occur only on field generation or usable rectangle changes',function()
    local u,t=fixture();wait(u,t);draw(u,t);wait(u,t);assert(#t.writes==1)
    u:dispatch('team2');u:dispatch('startingitems');draw(u,t);wait(u,t);assert(#t.writes==1)
    t.w=1136;wait(u,t);assert(#t.writes==2 and t.writes[2].value.width==826)
    draw(u,t);wait(u,t);assert(#t.writes==2)
    u.runtime.generation=2;wait(u,t);assert(#t.writes==3 and t.writes[3].kind=='viewport')
end)
test('Fit queues outside the frame, waits for viewport setup, and trusts actual native readbacks',function()
    local u,t=fixture();u:dispatch('fit');assert(u.requestedFit and #t.writes==0)
    wait(u,t);assert(#t.writes==1 and t.writes[1].kind=='viewport'and u.requestedFit)
    draw(u,t);wait(u,t);assert(#t.writes==2 and t.writes[2].kind=='fit'and u.zoom==0.137 and u.zoomGeneration==1)
    assert(u.message:find('14%%')and u.message:find('exceeds')and u.zoomAwaitingDraw)
    draw(u,t);wait(u,t);assert(#t.writes==2,'An automatic100% reset must not overwrite the actualFit.')
end)
test('an unset native viewport is initialized before any required readback or Fit',function()
    local u,t,api=fixture();local getter,setter=api.testFieldViewport,api.setTestFieldViewport;local installed=false
    api.testFieldViewport=function()if not installed then return nil,'viewport_not_set'end;return getter()end
    api.setTestFieldViewport=function(rect)local ok,why=setter(rect);if ok then installed=true end;return ok,why end
    draw(u,t);assert(not installed and #t.writes==0)
    assert(u:requestFit());wait(u,t);assert(installed and u.viewportReady and t.writes[1].kind=='viewport')
    draw(u,t);wait(u,t);assert(t.writes[2].kind=='fit')
end)
test('native fits=true is required before claiming the whole field fits',function()
    local u,t=fixture();t.fitFits=true;t.fitZoom=0.324;t.fitCell=9.72
    wait(u,t);draw(u,t);u:requestFit();wait(u,t)
    assert(u.zoom==0.324 and u.message:find('Entire field fits')and not u.message:find('exceeds'))
end)
test('fifty-column Fit uses real pixel bounds and source metadata, never the historical50% assumption',function()
    local u,t=fixture();local rect=u:usableViewport();local cell=math.min((rect.width-4)/50,(rect.height-4)/20)
    assert(math.abs(cell-9.72)<0.0001 and 50*cell<=rect.width-4+1e-9 and 20*cell<=rect.height-4+1e-9)
    local zoom=cell/(t.h/20);assert(math.abs(zoom-0.324)<0.0001 and zoom<0.5)
    t.fitZoom=zoom;t.fitCell=cell;t.fitFits=true;wait(u,t);draw(u,t);u:requestFit();wait(u,t)
    assert(u.zoom==zoom and t.viewport.cellSize==cell)
end)
test('huge-field minimum zoom can remain larger than the viewport and reports panning rather than fakefit',function()
    local u,t=fixture();local rect=u:usableViewport();local fieldPixels=1536*(t.h/20*0.1)
    assert(fieldPixels>rect.width-4);t.fitZoom=0.1;t.fitCell=3;t.fitFits=false
    wait(u,t);draw(u,t);u:requestFit();wait(u,t)
    assert(u.zoom==0.1 and u.message:find('exceeds')and u.message:find('pan with arrow keys or middle%-drag'))
end)
test('failed viewport setup never retries every WAIT or calls Fit against a different rectangle',function()
    local u,t=fixture();t.refuseViewport=true;u:requestFit();wait(u,t)
    assert(not u.viewportReady and not u.requestedFit and #t.writes==1 and u.noticeText:find('declared viewport refusal'))
    draw(u,t);for _=1,3 do wait(u,t)end;assert(#t.writes==1)
end)
test('native Fit refusal keeps last accepted zoom and consumes held input through freshDRAW',function()
    local u,t=fixture();wait(u,t);draw(u,t);u.zoom=0.4;t.refuseFit=true;u:requestFit();wait(u,t)
    assert(u.zoom==0.4 and u.zoomAwaitingDraw and u.releaseBarrier and u.dragBlocked and u.noticeText:find('declared fit refusal'))
    local before=#t.writes;wait(u,t);assert(#t.writes==before and t.input==0)
    draw(u,t);wait(u,t);assert(#t.writes==before)
end)
test('missing API or incomplete readback is explicit and cannot create a client-side fitted scale',function()
    local u,t,api=fixture();t.caps.battleViewport=nil;assert(not u:requestFit()and not u.requestedFit and #t.writes==0)
    assert(u.noticeText:find('unavailable'));u.noticeText=nil;draw(u,t)
    local label=false;for _,s in ipairs(t.texts)do if s=='Fit N/A'then label=true end end;assert(label)
    t.caps.battleViewport=1;t.badReadback=true;wait(u,t);assert(not u.viewportReady and u.noticeText:find('incomplete')and #t.writes==1)
    api.testFieldViewport=nil;assert(not u:viewportAvailable())
end)
test('Fit and zoom controls stay disjoint from Back and the fixed panel at both widths',function()
    for _,w in ipairs({800,1136})do
        local u,t=fixture();t.w=w;draw(u,t);local buttons={}
        for _,b in ipairs(u.buttons)do buttons[b.key]=b end
        assert(buttons.fit.x+buttons.fit.w<buttons.centerguide.x and buttons.centerguide.x+buttons.centerguide.w<buttons.back.x)
        assert(buttons.zoomout.x+buttons.zoomout.w<buttons.zoomin.x and buttons.zoomin.x+buttons.zoomin.w<buttons.fit.x)
        assert(buttons.clearitems.x==w-292 and buttons.clearitems.w==284)
        local hint=false;for _,s in ipairs(t.texts)do if s:find('arrows / middle%-drag')and s:find('Fit: whole field')then hint=true end end;assert(hint)
    end
end)
test('viewport initialization and panel scrolling advance wheel baseline without replaying blocked scroll',function()
    local u,t=fixture();t.wheel=100;wait(u,t);draw(u,t);wait(u,t);assert(#t.writes==1)
    t.x=795;t.y=350;t.wheel=101;wait(u,t);assert(#t.writes==1 and not u.requestedZoom)
    t.x=100;wait(u,t);assert(#t.writes==1 and not u.requestedZoom)
    t.wheel=102;wait(u,t);assert(#t.writes==2 and t.writes[2].kind=='zoom'and math.abs(t.writes[2].value.zoom-1.1)<1e-9)
end)
test('native previews use current reported coordinates and clip only to the shared usable map rectangle',function()
    local u,t,api=fixture();t.viewport.cellSize=20;t.viewport.originX=0;t.viewport.originY=38;u.selected=13
    u.placementPreview=function()
        local cells={};for _,pos in ipairs({{24,0},{0,26},{24,26}})do local x,y=api.battleCellToScreen(pos[1],pos[2]);cells[#cells+1]={x=pos[1],y=pos[2],screenX=x,screenY=y,status='clear'}end
        return {width=1,height=1,label='declared native projection',cells=cells}
    end
    draw(u,t);local rect=u:usableViewport();local overlays=0
    for _,r in ipairs(t.rects)do if r[8]==0.38 then
        overlays=overlays+1;assert(r[1]>=rect.x and r[2]>=rect.y and r[1]+r[3]<=rect.x+rect.width and r[2]+r[4]<=rect.y+rect.height)
    end end
    assert(overlays==3 and #u.previewInfo.cells==3,'Clipping must retain the full recorded native preview.')
    t.x=rect.width;t.y=350;assert(not u:pointerCell())
end)
print(count..' offline viewport rectangle/math/frame contracts passed; native fit, pan, rendering and reachability require real-game tests')
