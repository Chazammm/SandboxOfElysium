local function module(name)
    return assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()
end
local cache={}
function require(name)
    if cache[name]==nil then cache[name]=module(name)end
    return cache[name]
end
local M=require('sandbox.model')
local R=require('sandbox.runtime')
local U=require('sandbox.ui')
local catalog={byId={},mods={},testFieldTerrains={},terrainById={[0]={name='Plain'}}}
local ordinary=M.new()
local naval={fleet={mode='native_fleet_v1',schema=1,count=0}}

local decoded,reason=M.decode(naval,catalog,{})
assert(not decoded and reason:find('ship and passenger battles',1,true))
local hybrid=M.encode(ordinary,{})
hybrid.fleet=naval.fleet
assert(not M.decode(hybrid,catalog,{}))

local notices={}
local runtime={open=true,current=ordinary,build=function()error('naval load must not touch the battlefield')end,
    snapshot=function()return {}end}
local view={scenario=ordinary,catalog=catalog,runtime=runtime,diag={failure=function()end},
    api={listIni=function()return{'old-fleet.ini'}end,readIni=function()return naval end},
    menu=function(_,_,rows)assert(rows[2][2]:find('naval unavailable',1,true));return rows[2][1]end,
    notice=function(_,message)notices[#notices+1]=message end}
U.load(view)
assert(view.scenario==ordinary and runtime.current==ordinary and #notices==1 and notices[1]:find('ship and passenger battles',1,true))

local api={get=function(key,monster,ability)
    if key=='monsterMoveFlags'then return 0 end
    if key=='monsterAbility'then
        if monster==88 and ability==0x1d2 then return 1 end
        if monster==90 and ability==0x1d3 then return 3 end
        return 0
    end
end}
assert(M.waterMonsterProblem(api,0,88):find('unavailable',1,true))
assert(M.waterMonsterProblem(api,27,88):find('unavailable',1,true))
assert(not M.waterMonsterProblem(api,27,89))
assert(not M.waterMonsterProblem(api,20,90) and M.waterMonsterProblem(api,27,90))

local rt=R.new({},catalog)
rt.open=true;rt.current=ordinary
local ok,message=rt:build({mode='native_fleet_v1',units={}})
assert(not ok and message:find('unavailable',1,true) and rt.current==ordinary and rt.open)
ok,message=rt:_build(ordinary)
assert(not ok and message:find('lifecycle APIs',1,true) and rt.current==ordinary and rt.open)

local button,start,waits,seen
local function noop()end
coe5={addMainMenuButton=function(_,fn)button=fn end,
    testFieldEditorCapabilities=function()return {unitRetirement=1,initialDeploymentVersion='1',exactDeploymentVersion=1}end,
    ui={screenBegin=function(title)seen=title end,sectionBegin=noop,sectionEnd=noop,buttonRow=noop,
        text=noop,bindEscape=noop,wait=function()waits=true end}}
cache['sandbox.ui']={new=function()start=true;return{setup=noop}end}
assert(loadfile('mod/SandboxOfElysium/SandboxOfElysium.lua'))()
assert(type(button)=='function' and not start)
button()
assert(waits and seen:find('compatible CoE5SE',1,true) and not start)
print('6 release boundary checks passed')

local caps={unitRetirement=1,initialDeploymentVersion=1,exactDeploymentVersion=1,configuration=1}
coe5.testFieldEditorCapabilities=function()return caps end
coe5.setTestFieldDeployment=noop;coe5.testFieldInitialDeployment=noop
coe5.testFieldLoadoutState=noop
waits=false;button()
assert(waits and not start)
coe5.setTestFieldConfiguration=noop;caps.configuration=0
waits=false;button()
assert(waits and not start)
print('PASS the release entry refuses missing and unavailable native configuration')
caps.configuration=1
waits=false;button()
assert(start and not waits)
print('PASS the release entry accepts full configuration without the old setter')
