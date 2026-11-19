local cache={};function require(name)if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end;return cache[name]end
local R=require('sandbox.runtime');local M=require('sandbox.model');local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function fixture()
 local native={known={},memorized={},schools={{path=1,name='Fixture school',level=1,bonus=0,allowance=1}}}
 local r=R.new({testFieldSpellState=function()return native end},{spellKeys={}},{});return r,native
end
test('spell diagnostic snapshots own their nested values independently',function()
 local r,native=fixture();local u={id=1,monster=13,name='First',baseline={known={}},spells={}}
 r:observeSpellSelection(u,7);local row=r.diag.spellValidation[1]
 native.schools[1].name='Changed';u.name='Changed';r.spellValidation[1].schools[1].name='Changed'
 assert(row.name=='First'and row.schools[1].name=='Fixture school'and row.native.schools[1].name=='Fixture school')
 r:observeSpellSelection({id=2,monster=13,name='Second',baseline={known={}},spells={}},8)
 assert(r.diag.spellValidation[1]==row and r.diag.spellValidation[2].native_id==8)
end)
test('new spell diagnostics replace the actor entry while retaining other actors',function()
 local r=fixture();local a={id=1,monster=13,name='First',baseline={known={}},spells={}};local b=M.copy(a);b.id=2
 r:observeSpellSelection(a,7);r:observeSpellSelection(b,8);local retained=M.copy(r.diag.spellValidation[2]);a.name='Renamed';r:observeSpellSelection(a,9)
 assert(r.diag.spellValidation[1].name=='Renamed'and r.diag.spellValidation[1].native_id==9)
 assert(r.diag.spellValidation[2].native_id==retained.native_id and r.diag.spellValidation[2].name==retained.name)
end)
test('diagnostic capture work scales with new observations instead of prior roster size',function()
 local original=M.copy
 local function work(n)
  local calls=0;M.copy=function(value)calls=calls+1;return original(value)end
  local r=fixture();for id=1,n do r:observeSpellSelection({id=id,monster=13,name='Unit',baseline={known={}},spells={}},id)end
  M.copy=original;return calls
 end
 local small,large=work(10),work(20);assert(small>0 and large<=small*2.1,'Capture cost grows with accumulated roster')
end)
print(count..' offline diagnostic performance contracts passed; no native timing or battle simulated')
