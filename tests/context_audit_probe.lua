-- Opt-in isolated native context audit. Never loaded by an ordinary mod launch.
local api=coe5;local M=require('sandbox.model');local C=require('sandbox.catalog');local R=require('sandbox.runtime')
local out={environment=api.readIni('launcher-context').environment};local started,open=false,false
local originalFlags=api.get('terrainFlags',0);local originalMap=api.get('terrain',2,'batmap')
local function flat(t)local result={};for k,v in pairs(t)do if type(v)=='boolean'then result[k]=v and 1 or 0 elseif type(v)=='number'or type(v)=='string'then result[k]=v end end;return result end
local function listed(id)for _,v in ipairs(api.testFieldTerrains())do if v==id then return true end end;return false end
local function close()assert(api.closeTestField());open=false;local life=api.testFieldLifecycle();assert(life.complete and #life.issues==0)end
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local value=next(...);if started then return value end;started=true
 local r
 local ok,why=xpcall(function()
  api.set('terrainFlags',0,originalFlags|4);assert(not listed(0),'Altered Plain still advertised')
  local yes,reason=api.openTestField{emptyEditor=true,terrain=0,minimumWidth=50};open=yes
  assert(not yes and reason=='unsupported_terrain',tostring(reason));api.set('terrainFlags',0,originalFlags)
  api.set('terrain',2,'batmap',49);assert(not listed(2),'Altered Forest still advertised')
  yes,reason=api.openTestField{emptyEditor=true,terrain=2,minimumWidth=50};open=yes
  assert(not yes and reason=='unsupported_terrain',tostring(reason));api.set('terrain',2,'batmap',originalMap)
  out.modified_definitions={status='PASS',plain_water_refused=1,forest_farm_refused=1}
  local ids=api.testFieldTerrains();out.capabilities={count=#ids,ids=table.concat(ids,',')}
  for _,id in ipairs({0,2,12,107,117,115})do out.capabilities['flags'..id]=tostring(api.get('terrainFlags',id)) end
  assert(#ids==21,'Expected21 presets; got '..#ids..': '..table.concat(ids,','))
  for _,id in ipairs(ids)do
   yes,reason=api.openTestField{emptyEditor=true,terrain=id,minimumWidth=50,friends={{13,1}},enemies={{13,1}}};open=yes;assert(yes,tostring(id)..':'..tostring(reason))
   local env=assert(api.testFieldEnvironmentState());assert(env.terrain==id and env.setupReturned and env.nativeTemplateObserved and not env.customMapReplaced and env.plane==0 and env.temperature==25)
   out['terrain'..id]=flat(env);out['terrain'..id].status='PASS'
   if id==0 or id==1 or id==78 then
    api.set('battleAtSea',not env.atSea);local fought,refusal=api.fightTestField();assert(not fought and refusal==(id==78 and'water_context_mismatch'or'field_context_mismatch'),tostring(refusal))
    api.set('battleAtSea',env.atSea);assert(api.testFieldState().complete)
    out['terrain'..id].altered_context_fight_refused=1
   end
   close()
  end
  -- Real failed exact deployment, followed by rename through the original UI actor.
  local c=C.read(api);local s=M.new();local a=M.add(s,13,'Spearman',1,5,9);M.add(s,13,'Spearman',2,25,9)
  r=R.new(api,c);assert(r:build(s));assert(r:setNativeName(a,'Audit Before'))
  local candidate=M.copy(s);candidate.units[2].x=a.x;candidate.units[2].y=a.y
  local accepted,message=r:build(candidate);assert(not accepted and message:find('Previous army restored'),message)
  assert(r.current==s and s.units[1]==a and r:ready(s));assert(r:setNativeName(a,'Audit After'));assert(r:setLabel(a,'Legacy label remains editable'))
  out.rollback={status='PASS',native_placement_refused=1,restored_identity=1,native_rename_after_rollback=1,legacy_label_after_rollback=1}
  assert(r:close());r=nil
  -- Native maximum-width anchor and actual INI round-trip. This does not add a UI size preset.
  local units;yes,units=api.openTestField{emptyEditor=true,terrain=0,minimumWidth=1536,friends={{13,1}}};open=yes;assert(yes)
  local unit=units.friends[1];assert(api.moveTestFieldUnit(unit,1000,9));assert(api.battleUnitAt(1000,9)==unit)
  local wide=M.new();M.add(wide,13,'Spearman',1,1000,9);assert(api.writeIni('audit-wide-anchor',M.encode(wide,c.mods)))
  local decoded,detail=M.decode(api.readIni('audit-wide-anchor'),c,c.mods);assert(decoded,detail);assert(decoded.units[1].x==1000)
  out.wide_anchor={status='PASS',native_width=api.get('battleWidth'),x=1000,scope='Native move and saved-anchor decoding; no1536 UI preset or reload reconstruction claim'};close()
 end,tostring)
 if r then r:close()end;if open then api.closeTestField()end
 api.set('terrainFlags',0,originalFlags);api.set('terrain',2,'batmap',originalMap)
 out.complete={status=ok and'PASS'or'FAIL',detail=tostring(why or'Native context and rollback checks completed')};assert(api.writeIni('results',out));return value
end,-100)
