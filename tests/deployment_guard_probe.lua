-- Opt-in real-game rollback checks for the separate exact deployment API.
local api=coe5;local M=require('sandbox.model');local U=require('sandbox.ui');local started=false;local ui
local out={environment=(api.readIni('launcher-context')or{}).environment}
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function flat(t)local o={};for k,v in pairs(t)do if type(v)=='boolean'then o[k]=v and 1 or 0 elseif type(v)=='number'or type(v)=='string'then o[k]=v end end;return o end
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local v=next(...);if started then return v end;started=true
 local ok,why=xpcall(function()
  ui=U.new(api);ui:ensureCatalog();ui.notice=function(self,text)self.message=text end
  local s=M.new();s.terrain=2;s.minimumWidth=50;s.size='Minimum width';M.add(s,13,api.get('monsterName',13),1,8,9);M.add(s,953,api.get('monsterName',953),2,28,9);ui.scenario=s;assert(ui.runtime:build(s,true))
  local native=assert(api.testFieldState());local request={};local unit=ui.runtime.live[s.units[1].id]
  local by={};for _,row in ipairs(native.units)do by[row.unit]=row end
  for _,u in ipairs(s.units)do local id=ui.runtime.live[u.id];request[#request+1]={unit=id,generation=by[id].generation,x=u.x,y=u.y}end
  local target
  for x=0,native.width-1 do for y=0,19 do local object=api.battleObjectAt(x,y)
   if object>=0 and api.battleUnitAt(x,y)<0 and not api.battleCanStand(unit,x,y,4)then target={x=x,y=y,object=object};break end
  end;if target then break end end
  assert(target,'No verified native blocked object cell found in the Forest fixture')
  request[1].x=target.x;request[1].y=target.y
  local accepted,reason,detail=api.setTestFieldDeployment(request)
  out.rejected=flat(detail or{});out.rejected.reason=tostring(reason);assert(not accepted and detail.rollbackVerified and detail.wroteAnchors and detail.anchorsRestored,tostring(reason))
  assert(same(native,api.testFieldState()),'Rejected native terrain changed the field');assert(ui.runtime:ready(s));out.rejected.complete_source_unchanged=1
  request[1].x=native.width;local accepted,reason,detail=api.setTestFieldDeployment(request);assert(not accepted and not detail.wroteAnchors and detail.rollbackVerified,reason)
  assert(same(native,api.testFieldState()));out.edge={refused_before_write=1,full_field_unchanged=1}
  assert(ui.runtime:close());local life=assert(api.testFieldLifecycle());assert(life.complete and not life.open and #life.issues==0)
 end,tostring)
 if ui and ui.runtime.open then ui.runtime:close()end
 out.complete={status=ok and'PASS'or'FAIL',detail=tostring(why or'Actual native impassable terrain rollback and full-footprint edge refusal verified')};assert(api.writeIni('results',out));return v
end,-100)
