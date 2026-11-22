local cache={}
function require(name)
    if not cache[name] then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))() end
    return cache[name]
end

local M=require('sandbox.model')
local C=require('sandbox.catalog')
local U=require('sandbox.ui')
local states={
    {mods={'CoE5SE','CrabCult'},base=13,mod=6876},
    {mods={'CoE5SE'},base=13},
    {mods={'CoE5SE','CrabCult'},base=13,mod=6912},
    {mods={'CoE5SE','CrabCult'},base=37,mod=7112},
}
local index,reads=1,0
C.read=function()
    reads=reads+1
    local state=states[index]
    local a={id=13,name='Spearman',sprite=state.base,categories={}}
    local b={id=953,name='Goblin',sprite=953,categories={}}
    local c={mods=state.mods,byId={[13]=a,[953]=b},monsters={a,b},testFieldTerrains={},terrainById={[0]={name='Plain'}}}
    if state.mod then
        local row={id=2009,name='Shell Priest',sprite=state.mod,definitionMod='CrabCult',categories={modded=true}}
        c.byId[row.id]=row;c.monsters[#c.monsters+1]=row
    end
    return c
end
local api={observe=function()end,wrap=function()return true end,readIni=function()end,
    get=function(k)if k=='modLastIndex'then return -1 end end,
    findMonster=function(n)return n=='Spearman' and 13 or 953 end}
local ui=U.new(api)
ui:ensureCatalog(true)
local original,originalRuntime=ui.scenario,ui.runtime
M.add(original,2009,'Shell Priest',1,10,9)
local persisted=M.encode(original,ui.catalog.mods)
ui.search='shell';ui.category=9;ui.selected=2009;ui.selectedItem={id=123}
ui.snapshot=M.copy(original)
index=2;ui:ensureCatalog(true)
assert(#ui.filtered==0 and ui.catalog.byId[2009]==nil and ui.selected==nil and ui.selectedItem==nil)
assert(ui.scenario~=original and #ui.scenario.units==2 and ui.snapshot==nil)
local loaded,why=M.decode(persisted,ui.catalog,ui.catalog.mods)
assert(not loaded and why:find('CrabCult',1,true))
assert(persisted.unit3.name=='Shell Priest')
print('PASS disabled mod rows and selection disappear while other setups and saves remain intact')

local vanilla=ui.scenario
index=3;ui:ensureCatalog(true)
assert(ui.scenario==original and ui.runtime==originalRuntime and #ui.snapshot.units==3)
assert(ui.runtime.catalog==ui.catalog and #ui.filtered==1 and ui.filtered[1].sprite==6912)
assert(M.decode(persisted,ui.catalog,ui.catalog.mods))
print('PASS re-enabling a mod restores the kept setup and updates its sprite handles')

ui.selected=2009;index=4;ui:ensureCatalog(true)
assert(ui.scenario==original and ui.selected==2009 and ui.catalog.byId[13].sprite==37 and #ui.filtered==1 and ui.filtered[1].sprite==7112)
ui.runtime.open=true;ui:ensureCatalog(true);assert(reads==4)
ui.runtime.open=false;index=2;ui:ensureCatalog(true)
assert(ui.scenario==vanilla and reads==5)
print('PASS a same-list reopen refreshes both sprite sets and a live field retains its catalog')
