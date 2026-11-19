-- Pure projection geometry; no native camera/rendering behavior is simulated.
local G=assert(loadfile('mod/SandboxOfElysium/sandbox/center_guide.lua'))()
local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function view()return{originX=-200,originY=15,cellSize=10,width=50,height=20}end
local function rect()return{x=0,y=38,width=490,height=524}end
test('even native widths split the two middle columns exactly',function()
    local v=view();local line=assert(G.line(v,rect()));assert(line.x==50 and line.midColumn==25)
    local left=v.originX+(24+0.5)*v.cellSize;local right=v.originX+(25+0.5)*v.cellSize
    assert(line.x==(left+right)/2)
end)
test('odd native widths cross the middle cell center without rounding',function()
    local v=view();v.width=51;local line=assert(G.line(v,rect()))
    assert(line.x==55 and line.midColumn==25.5 and line.x==v.originX+(25+0.5)*v.cellSize)
end)
test('single native column has its center halfway through that cell',function()
    local v=view();v.width=1;v.originX=20;local line=assert(G.line(v,rect()));assert(line.x==25 and line.midColumn==0.5)
end)
test('auto expansion uses actual width rather than an unrelated requested minimum',function()
    local v=view();v.width=160;v.minimumWidth=70;v.originX=-600
    local line=assert(G.line(v,rect()));assert(line.x==200 and line.fieldWidth==160)
end)
test('panning moves the guide by the actual native origin delta',function()
    local v=view();local a=assert(G.line(v,rect()));v.originX=v.originX+73;v.originY=v.originY+100
    local b=assert(G.line(v,rect()));assert(b.x-a.x==73 and b.y1==115 and b.y2==315)
end)
test('zoom follows projection scale and clips against the usable map',function()
    local v=view();v.cellSize=20;v.originX=-200;v.originY=-100
    local line=assert(G.line(v,rect()));assert(line.x==300 and line.y1==38 and line.y2==300)
    v.cellSize=30;v.originX=-700;v.originY=-100
    line=assert(G.line(v,rect()));assert(line.x==50 and line.y1==38 and line.y2==500)
end)
test('vertical extent stops at the actual field and clip boundaries',function()
    local v=view();v.originY=100;local line=assert(G.line(v,rect()));assert(line.y1==100 and line.y2==300)
    local clip=rect();clip.y=125;clip.height=40;line=assert(G.line(v,clip));assert(line.y1==125 and line.y2==165)
end)
test('offscreen center or field produces no overlay instead of edge snapping',function()
    local v=view();v.originX=-251;assert(not G.line(v,rect()))
    v.originX=240;assert(not G.line(v,rect())) -- exact right boundary is outside
    v=view();v.originY=-200;assert(not G.line(v,rect()))
    v.originY=562;assert(not G.line(v,rect()))
end)
test('invalid and nonfinite views or rectangles refuse without projection',function()
    for _,bad in ipairs({0,-1,'10',false,math.huge,0/0})do
        local v=view();v.cellSize=bad;assert(not G.line(v,rect()))
    end
    for _,bad in ipairs({0,50.5,1537,math.huge})do local v=view();v.width=bad;assert(not G.line(v,rect()))end
    for _,bad in ipairs({0,21,2.5})do local v=view();v.height=bad;assert(not G.line(v,rect()))end
    for _,key in ipairs({'originX','originY'})do local v=view();v[key]=math.huge;assert(not G.line(v,rect()))end
    for _,key in ipairs({'x','y','width','height'})do local r=rect();r[key]=0/0;assert(not G.line(view(),r))end
    assert(not G.line(nil,rect())and not G.line(view(),nil))
end)
test('overflowed derived projection refuses rather than drawing outside the field',function()
    local v=view();v.cellSize=1e308;assert(not G.line(v,rect()))
    local r=rect();r.x=1e308;r.width=1e308;assert(not G.line(view(),r))
end)
test('projection leaves view and clip unchanged and creates no input surface',function()
    local v,r=view(),rect();local line=assert(G.line(v,r));line.x=999
    assert(v.originX==-200 and v.width==50 and r.x==0 and r.width==490)
    assert(G.line(v,r).x==50 and G.input==nil and G.buttons==nil)
end)
print(count..' offline midpoint geometry contracts passed; native camera/alignment require real-game checks')
