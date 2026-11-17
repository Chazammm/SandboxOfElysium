-- Explicit native API acceptance. Does not run on an ordinary Sandbox launch.
local api=coe5;local started,fighting=false,false;local out={environment=api.readIni('launcher-context').environment}
local expected={[5]='farm',[18]='village',[70]='hoburgh',[98]='oasis',[109]='tentvillage'}
-- Metadata covers the current positive list; this probe's battle loop remains
-- the five original neutral templates. Full siege acceptance is separate.
local verified={};for id,name in pairs(expected)do verified[id]=name end
for id,name in pairs({[1]='palisaden',[20]='stonetower',[72]='woodentower',[22]='greatwall',[23]='citadel',[17]='town',[9]='city'})do verified[id]=name end
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function save()assert(api.writeIni('results',out))end
local function test(name,fn)local ok,why=xpcall(fn,tostring);local life=api.testFieldLifecycle();local clean=true;if life and life.open then clean=api.closeTestField()end;out[name]={status=ok and clean~=false and'PASS'or'FAIL',detail=ok and'Actual native API, unmodified native fight and cleanup'or tostring(why)};save()end
api.wrap('BATTLE_WAIT',function(next,...)local v=next(...);if fighting and v==0 and(api.get('battleDelay')or 0)>2 then return 1 end;return v end)
api.wrap('MAIN_MENU_WAIT',function(next,...)
 local v=next(...);if started then return v end;started=true
 test('metadata_verified_contexts_and_unsupported_guards',function()
  local value,why=api.testFieldEnvironmentState();assert(not value and why=='not_open');local info=assert(api.testFieldEnvironmentInfo());assert(info.environmentStateVersion==1 and info.templateContextVersion==1 and #info.templates==59)
  local ids={};for _,id in ipairs(api.testFieldTerrains())do ids[id]=true end;for id in pairs(verified)do assert(ids[id])end;for _,id in ipairs({3,197,327,158,27,47,103})do assert(not ids[id]);local ok,why=api.openTestField{emptyEditor=true,terrain=id};assert(not ok and why=='unsupported_terrain')end
  local rows={};for _,t in ipairs(info.terrains)do rows[t.id]=t end;for id in pairs(verified)do assert(rows[id].verifiedTemplateField and not rows[id].verifiedNeutralField and not rows[id].candidateAvailable)end;for _,id in ipairs({0,2,12,107,115,117})do assert(rows[id].verifiedNeutralField and not rows[id].verifiedTemplateField)end
  local templates={};for _,t in ipairs(info.templates)do templates[t.name]=t end;for id,name in pairs(verified)do local row=templates[name];assert(row.installed and row.verifiedContext);local found=false;for _,i in ipairs(row.verifiedTerrainIds)do if i==id then found=true end end;assert(found)end;assert(templates.palisaden.verifiedContext and not templates.cavetunnel.verifiedContext)
 end)
 for _,id in ipairs({5,18,70,98,109})do for _,minimum in ipairs({0,160})do
  test('terrain'..id..'_minimum'..minimum,function()
   local spec={emptyEditor=true,terrain=id,friends={{13,2}},enemies={{953,3}}};if minimum>0 then spec.minimumWidth=minimum end
   local ok,units=api.openTestField(spec);assert(ok,units);local before=assert(api.testFieldState());local env=assert(api.testFieldEnvironmentState());local after=assert(api.testFieldState());assert(equal(before,after),'Read-only environment query changed field state');assert(env.nativeTemplate==expected[id]and env.setupReturned and env.nativeTemplateObserved and not env.customMapReplaced and not env.siege and not env.atSea and not env.underground and env.width>=math.max(32,minimum))
   fighting=true;local fought,why=api.fightTestField();fighting=false;assert(fought~=false,why);assert(api.get('battleRound')>0 and(api.get('battleWinner')==0 or api.get('battleWinner')==24));out['result'..id..'_'..minimum]={width=env.width,minimum=minimum,round=api.get('battleRound'),winner=api.get('battleWinner'),template=env.nativeTemplate};assert(api.closeTestField());local life=api.testFieldLifecycle();assert(life.complete and #life.issues==0 and not life.open)
  end)
 end end
 local passed=true;for _,r in pairs(out)do if type(r)=='table'and r.status=='FAIL'then passed=false end end;out.complete={status=passed and'PASS'or'FAIL'};save();return v
end,-100)
