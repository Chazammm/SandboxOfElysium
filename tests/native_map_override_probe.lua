-- Explicit isolated QA: requires a private owned farm.coem copy, not distributed.
local api=coe5;assert(api.addBattleMap{file='./maps/qa-farm-copy.coem',terrains={5}},'Private Farm override fixture unavailable')
local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime');local D=require('sandbox.diagnostics');local started=false
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local v=next(...);if started then return v end;started=true;local out={environment=api.readIni('launcher-context').environment};local r,s
 local ok,why=xpcall(function()
  local c=C.read(api);s=M.new();local guard=M.add(s,13,'Spearman',1,8,9);local caster=M.add(s,594,"Druid's Apprentice",1,6,5);M.add(s,953,'Goblin',2,18,9)
  r=R.new(api,c,D.new(api));assert(r:build(s,true));assert(r:setNativeName(guard,'Kept Guard'));assert(r:setNativeName(caster,'Kept Sage'));local frozen=M.copy(s)
  local candidate=M.copy(s);candidate.terrain=5;local accepted,message=r:build(candidate,true);assert(not accepted and not r.blocked,'Custom replacement bypassed verified stock context or rollback failed');local restored=r.current;local good,reason=r:ready(restored);assert(good,reason);assert(equal(M.encode(restored,c.mods),M.encode(frozen,c.mods)));assert(api.testFieldUnitName(r.live[guard.id]).name=='Kept Guard');assert(api.testFieldUnitName(r.live[caster.id]).name=='Kept Sage')
  local name=assert(r.diag:export({fixture='intentional custom replacement of stock Farm; exact original setup restored'},r:snapshot(restored)));out.refusal={message=tostring(message),native_reason=r.diag.lastError and r.diag.lastError.message or'unknown',diagnostic=name,model_names_spells_items_preserved=1};assert(out.refusal.native_reason:find('field_context_mismatch',1,true));assert(r:close());r=nil
 end,tostring)
 if r then local closed,reason=r:close();if not closed then ok=false;why=tostring(why)..'; cleanup:'..tostring(reason)end end
 out.custom_replacement_refused_and_previous_scenario_restored={status=ok and'PASS'or'FAIL',detail=ok and'Actual load-time native map replacement, scoped refusal and exact supported setup recovery'or tostring(why)};out.complete={status=ok and'PASS'or'FAIL'};assert(api.writeIni('results',out));return v
end,-100)
