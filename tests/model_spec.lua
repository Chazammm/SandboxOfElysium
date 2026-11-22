local cache={}
function require(name)
    if cache[name] then return cache[name] end
    local f=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))
    cache[name]=f();return cache[name]
end
local M=require('sandbox.model')
local count=0
local function test(name,fn) fn();count=count+1;print('PASS '..name) end
test('all formations and clamp',function()
    assert(#M.cells('Single',15,0,0)==1)
    for n=1,15 do assert(#M.cells('Horizontal Row',n,0,0)==n);assert(#M.cells('Vertical Row',n,0,0)==n) end
    for n=2,4 do assert(#M.cells('Square',n,0,0)==n*n) end
    assert(#M.cells('Horizontal Row',99,0,0)==15)
    local c=M.cells('Square',2,3,4);assert(c[1][1]==3 and c[4][1]==4 and c[4][2]==5)
end)
local cat={byId={[13]={name='Spearman'},[42]={name='Wizard'}},itemNames={Ring=1},spellKeys={['2:Spark']=2,['3:Spark']=3},terrainById={[0]={name='Plain'},[2]={name='Forest'}}}
local s=M.new();local a=M.add(s,13,'Spearman',1,2,3);local b=M.add(s,42,'Wizard',2,9,3)
b.items={'Ring'};b.spells={'2:Spark'};b.baseline={known={'2:Spark'}}
test('copies preserve configuration without aliasing',function()
    local c=M.copy(b);c.items[1]='Different';assert(b.items[1]=='Ring')
    local u=M.add(s,b.monster,b.name,2,10,3,b);assert(u.id~=b.id);assert(u.spells[1]=='2:Spark')
    M.remove(s,u.id);assert(#s.units==2)
end)
test('roundtrip with equipment, spells, colors and mods',function()
    s.colors={3,3};local decoded,why=M.decode(M.encode(s,{'ExampleMod'}),cat,{'ExampleMod'})
    assert(decoded,why);assert(decoded.colors[1]==3 and decoded.colors[2]==3)
    assert(decoded.units[2].items[1]=='Ring' and decoded.units[2].baseline.known[1]=='2:Spark')
end)
test('missing required mod is rejected',function() local v,e=M.decode(M.encode(s,{'Gone'}),cat,{});assert(not v and e:find('Gone')) end)
test('changed unit identity is rejected',function() local t=M.encode(s,{});t.unit1.name='Different';assert(not M.decode(t,cat,{})) end)
test('missing unit is rejected',function() local t=M.encode(s,{});t.unit1.monster=999;assert(not M.decode(t,cat,{})) end)
test('missing item is rejected',function() local t=M.encode(s,{});t.unit2.item1='Gone';assert(not M.decode(t,cat,{})) end)
test('missing spell is rejected',function() local t=M.encode(s,{});t.unit2.spell1='Gone';assert(not M.decode(t,cat,{})) end)
test('missing known spell is rejected',function() local t=M.encode(s,{});t.unit2.known1='Gone';assert(not M.decode(t,cat,{})) end)
test('same-name spells retain distinct IDs',function()
    local t=M.encode(s,{});t.unit2.spell1='3:Spark';local v=assert(M.decode(t,cat,{}));assert(v.units[2].spells[1]=='3:Spark')
    t.unit2.spell1='4:Spark';assert(not M.decode(t,cat,{}))
end)
test('configured unit without baseline rejected',function() local t=M.encode(s,{});t.unit2.known_count=nil;assert(not M.decode(t,cat,{})) end)
test('invalid count and coordinates are rejected',function()
    for _,value in ipairs({'x',-1,2001,1.5}) do local t=M.encode(s,{});t.scenario.count=value;assert(not M.decode(t,cat,{})) end
    for _,value in ipairs({'x',-1,20,3.5}) do local t=M.encode(s,{});t.unit1.y=value;assert(not M.decode(t,cat,{})) end
end)
test('overlapping cells rejected',function() local t=M.encode(s,{});t.unit2.x=t.unit1.x;t.unit2.y=t.unit1.y;assert(not M.decode(t,cat,{})) end)
test('unsupported terrain, schema and size rejected',function()
    for _,key in ipairs({'terrain','schema','size'}) do local t=M.encode(s,{});t.scenario[key]='unsupported';assert(not M.decode(t,cat,{})) end
end)
test('empty scenario remains empty',function() local t=assert(M.decode(M.encode(M.new(),{}),cat,{}));assert(#t.units==0) end)
test('Forest survives scenario roundtrip',function() local source=M.copy(s);source.terrain=2;local t=assert(M.decode(M.encode(source,{}),cat,{}));assert(t.terrain==2) end)
test('missing or changed Forest is rejected',function() local source=M.copy(s);source.terrain=2;local c=M.copy(cat);c.terrainById[2].name='Different';assert(not M.decode(M.encode(source,{}),c,{})) end)
test('legacy extender refuses Forest before touching an open field',function()
    local R=require('sandbox.runtime');local r=R.new({},cat);r.open=true
    local ok,why=r:build({terrain=2});assert(not ok and why:find('CoE5SE terrain API',1,true));assert(r.open)
end)
test('incompatible terrain capability reply is refused without engine calls',function()
    local R=require('sandbox.runtime');local r=R.new({testFieldTerrains=function()return 'incompatible' end},cat)
    local ok,why=r:build({terrain=2});assert(not ok and why:find('capabilities are unavailable'))
end)
test('counts remain separate even with identical colors',function() assert(M.count(s,1,13)==1 and M.count(s,2,13)==0);assert(M.count(s)==2) end)
print(count..' model/guard tests passed (outside game; no native battles simulated)')
