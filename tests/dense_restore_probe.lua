-- Opt-in isolated native acceptance; never loaded by an ordinary mod launch.
local api=coe5;local U=require('sandbox.ui');local M=require('sandbox.model');local L=require('sandbox.loadout')
local out={environment=(api.readIni('launcher-context')or{}).environment};local stage=0;local ui,s,frozen;local fighting=false
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function flat(t)if type(t)=='boolean'then return t and 1 or 0 end;if type(t)~='table'then return t end;local o={};for k,v in pairs(t)do o[k]=flat(v)end;return o end
local function write()assert(api.writeIni('results',flat(out)))end
local function healthy()local ok,why=ui.runtime:ready(ui.scenario);assert(ok,why);local state=assert(api.testFieldState());assert(state.complete and #state.issues==0);return state end
local function rows(state,scenario)local by={};for _,row in ipairs(state.units)do by[row.unit]=row end;local list={};for _,u in ipairs(scenario.units)do local id=ui.runtime.live[u.id];list[#list+1]={unit=id,generation=by[id].generation,x=u.x,y=u.y}end;return list end
local function finish(ok,why)
 fighting=false;if ui and ui.runtime.open then local yes,detail=ui.runtime:close();if not yes then ok=false;why=tostring(why)..'; cleanup '..tostring(detail)end end
 if ok then local life=assert(api.testFieldLifecycle());assert(life.complete and not life.open and #life.issues==0)end
 out.complete={status=ok and'PASS'or'FAIL',detail=tostring(why or'Actual dense native restoration, cyclic anchors, configuration and natural battles verified')};stage=99;write()
end
api.wrap('BATTLE_WAIT',function(next,...)local v=next(...);if fighting and v==0 and(api.get('battleDelay')or 0)>2 then return 1 end;return v end)
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local value=next(...);if stage==99 then return value end
 local ok,why=xpcall(function()
  if stage==0 then
   assert(type(api.setTestFieldDeployment)=='function');assert(api.testFieldEditorCapabilities().exactDeploymentVersion==1)
   ui=U.new(api);ui:ensureCatalog();ui.notice=function(self,text)self.message=text end
   s=M.new();s.minimumWidth=32;s.size='Minimum width'
   for i=1,200 do M.add(s,634,api.get('monsterName',634),1,8,i%20)end
   for i=1,3 do M.add(s,13,api.get('monsterName',13),2,28,i*3)end
   ui.scenario=s;assert(ui.runtime:build(s,true));ui.phase='prepare';ui.native=true;ui:prepareLog()
   assert(ui.runtime:setNativeName(s.units[1],'Dense leader'));assert(ui.runtime:setNativeName(s.units[201],'Rear guard'))
   assert(api.giveItem(ui.runtime.live[s.units[1].id],'Amulet of Anti Magic'));assert(L.capture(ui.runtime,s.units[1],assert(L.read(ui.runtime,ui.runtime.live[s.units[1].id]))))
   healthy();frozen=M.encode(s,ui.catalog.mods);assert(api.writeIni('dense-original',frozen));out.initial={actors=#s.units,width=ui.runtime.width};stage=1
  elseif stage==1 then
   local old=healthy();local request=rows(old,s);local bad=M.copy(request);bad[1].generation=bad[1].generation+1
   local yes,reason,detail=api.setTestFieldDeployment(bad);assert(not yes and detail.rollbackVerified and same(old,api.testFieldState()),tostring(reason))
   bad=M.copy(request);table.remove(bad);yes,reason,detail=api.setTestFieldDeployment(bad);assert(not yes and detail.rollbackVerified and same(old,api.testFieldState()),tostring(reason))
   bad=M.copy(request);bad[1].x=bad[2].x;bad[1].y=bad[2].y;yes,reason,detail=api.setTestFieldDeployment(bad);assert(not yes and detail.rollbackVerified and same(old,api.testFieldState()),tostring(reason))
   out.invalid={generation_refused=1,missing_actor_refused=1,overlap_refused=1,native_unchanged=1}
   local cycle=M.copy(s);for i=1,200 do local other=s.units[i%200+1];cycle.units[i].x=other.x;cycle.units[i].y=other.y end
   assert(ui.runtime:place(cycle));s=cycle;ui.scenario=s;healthy();out.cycle={actors=200,all_exact=1};stage=2
  elseif stage==2 then
   local loaded=assert(M.decode(api.readIni('dense-original'),ui.catalog,ui.catalog.mods));assert(ui.runtime:build(loaded,false));ui.scenario=loaded;s=loaded
   assert(same(frozen,M.encode(s,ui.catalog.mods)));healthy();out.load={exact=1,names_items_ordered_spells_condition=1,width=ui.runtime.width};stage=3
  elseif stage==3 then
   fighting=true;assert(ui:fight());fighting=false;out.battle1={round=api.get('battleRound'),winner=api.get('battleWinner')};assert(ui:postBattle('restore'));s=ui.scenario
   assert(same(frozen,M.encode(s,ui.catalog.mods)));healthy();out.back={exact=1};stage=4
  elseif stage==4 then
   fighting=true;local results=ui.results;ui.results=function()return'controls'end;assert(ui:postBattle('rematch'));ui.results=results;fighting=false
   out.battle2={round=api.get('battleRound'),winner=api.get('battleWinner')};assert(ui:reset(false));s=ui.scenario
   assert(same(frozen,M.encode(s,ui.catalog.mods)));healthy();out.reset_rematch={exact=1};stage=5
  elseif stage==5 then
   local original=M.copy(ui.scenario);local one=original.units[1];local yes,new=ui.runtime:remove(original,one);assert(yes,new);ui.scenario=new;healthy()
   -- Clear uses the same production transaction as the editor control.
   local beforeClear=M.encode(ui.scenario,ui.catalog.mods)
   ui:dispatch('clear');assert(ui.clearResult and ui.clearResult.ok,ui.message);assert(#ui.scenario.units==0,ui.message);healthy()
   local kept=assert(M.decode(api.readIni(assert(ui.clearResult.originalRecovery)),ui.catalog,ui.catalog.mods));assert(same(beforeClear,M.encode(kept,ui.catalog.mods)))
   out.clear={empty=1,removed=ui.clearResult.removed,total=ui.clearResult.total,original_backup_verified=1}
   assert(ui:reset(false));assert(same(frozen,M.encode(ui.scenario,ui.catalog.mods)));healthy();out.clear.reset_original_exact=1
   finish(true)
  end
 end,tostring)
 if not ok then finish(false,why)else write()end;return value
end,-100)
