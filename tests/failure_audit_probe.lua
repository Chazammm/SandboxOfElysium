-- Isolated fault-boundary audit with real field lifecycle and INI I/O.
-- Missing readback/busy errors are injected, not naturally occurring failures.
local api=coe5;local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local U=require('sandbox.ui');local D=require('sandbox.diagnostics')
local out={environment=api.readIni('launcher-context').environment};local started=false;local active
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function scene()local s=M.new();M.add(s,13,'Spearman',1,5,9);M.add(s,13,'Spearman',2,25,9);return s end
local open,condition=api.openTestField,api.testFieldActorState
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local value=next(...);if started then return value end;started=true
 local ok,why=xpcall(function()
  local c=C.read(api);local s=scene();local actor=s.units[1];local failId
  api.openTestField=function(spec)local yes,units=open(spec);if yes then failId=units.enemies[1]end;return yes,units end
  api.testFieldActorState=function(unit)if unit==failId then return nil,'Injected missing later-actor readback'end;return condition(unit)end
  active=R.new(api,c,D.new(api));local accepted,message=active:build(s)
  api.openTestField=open;api.testFieldActorState=condition
  assert(not accepted and message:find('scenario is kept'),message)
  assert(s.units[1]==actor and actor.baseline==nil and actor.condition==nil and #s.units==2)
  local life=api.testFieldLifecycle();assert(life.complete and not life.open and #life.issues==0)
  out.first_open={status='PASS',fault='Injected missing second-actor condition readback',partial_captures_discarded=1,native_cleanup_verified=1}
  -- An ordinary valid native save survives an invalid candidate Save.
  assert(active:build(s));assert(api.writeIni('audit-preserved-target',M.encode(s,c.mods)))
  local original=assert(M.decode(api.readIni('audit-preserved-target'),c,c.mods));local before=M.encode(original,c.mods)
  local invalid=M.copy(s);for i=3,2001 do local copy=M.copy(actor);copy.id=i;invalid.units[i]=copy end
  local ui=U.new(api);ui.catalog=c;ui.scenario=invalid;ui.runtime=active;ui.diag=active.diag
  ui.prompt=function()return'audit-preserved-target'end;ui.notice=function(self,text)self.message=text end
  ui:save();assert(ui.message:find('Save refused'),ui.message)
  local kept,detail=M.decode(api.readIni('audit-preserved-target'),c,c.mods);assert(kept,detail);assert(equal(before,M.encode(kept,c.mods)))
  out.save={status='PASS',native_ini_target_preserved=1,refused_count=2001}
  assert(active:close());active=nil
  -- A missing physical/capability reply never bypasses the active native field.
  active=R.new(api,c,D.new(api));assert(active:build(s))
  local terrains=api.testFieldTerrains;api.testFieldTerrains=function()return{}end
  accepted,message=active:build(M.copy(s));api.testFieldTerrains=terrains
  assert(not accepted and message:find('CoE5SE terrain API')and active:ready(s))
  out.capability={status='PASS',fault='Injected empty advertised native terrain list',plain_fallback_refused=1,current_field_kept=1}
  assert(active:close());active=nil
 end,tostring)
 api.openTestField=open;api.testFieldActorState=condition
 if active then active:close()end
 out.complete={status=ok and'PASS'or'FAIL',detail=tostring(why or'Controlled failure checks completed')};assert(api.writeIni('results',out));return value
end,-100)
