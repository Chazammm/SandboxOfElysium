-- Native-style template view only; no unit/card constructor or game is simulated.
local cache={};function require(name)if not cache[name]then cache[name]=assert(loadfile('mod/SandboxOfElysium/'..name:gsub('%.','/')..'.lua'))()end;return cache[name]end
local V=require('sandbox.unit_view');local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function fixture(id)
    id=id or 13
    local state={calls={},screens={},text={},rows={},choices={999},mutations=0,units=0}
    local stats={hp=12,armor=1,str=5,mor=5,mr=4,rank=1}
    local api={get=function(key,index,word)
        state.calls[#state.calls+1]={key,index,word}
        if key=='monsterLastIndex'then return 5999 elseif key=='monsterName'then return index==id and'Spearman'or''
        elseif key=='monsterSprite'then return 77 elseif key=='screenW'then return 800
        elseif key=='monsterMod'then return''elseif key=='monster'then return stats[word]or(word=='human'and true or false)
        elseif key=='monsterFlags'then return 8 elseif key=='monsterMoveFlags'then return 0
        elseif key=='monsterAbility'then return word==57 and 1 or 0
        elseif key=='effectName'then return index==57 and'unique'or nil
        elseif key=='monsterAttackType'then return word==0 and 1 or nil
        elseif key=='monsterAttackWeapon'then return 4 elseif key=='monsterAttackValue'then return 3
        elseif key=='weaponName'then return'Spear'
        elseif key=='weapon'then return({dmg=4,range=1,dmgtype=3})[word]end
        error('Unapproved data query: '..key)
    end,set=function()error('View must not write')end,spawnUnit=function()error('View must not construct')end,
    addTestFieldUnits=function()error('View must not add actors')end,testBattle=function()error('View must not open a fight')end}
    api.ui={screenBegin=function(title)state.screens[#state.screens+1]=title end,screenWidth=function(width)assert(width<=770)end,
        sectionBegin=function()end,sectionEnd=function()end,buttonRow=function()end,bindEscape=function(id)assert(id==999)end,
        text=function(id,text)state.text[#state.text+1]={id=id,text=text}end,
        monsterRow=function(action,monster,name,scope)state.rows[#state.rows+1]={action=action,monster=monster,name=name,scope=scope}end,
        wait=function()return table.remove(state.choices,1)end}
    return api,state
end
test('ordinary template stats and attacks are read from the exact requested loaded type',function()
    local api,state=fixture();local data=assert(V.read(api,13));assert(data.monster==13 and data.name=='Spearman'and data.stats[1].value==12)
    assert(data.flags[1]=='human'and data.attacks[1].name=='Spear'and data.attacks[1].value==3)
    assert(data.abilities[1].id==57 and data.abilities[1].word=='unique')
    for _,call in ipairs(state.calls)do assert(not call[1]:find('unit',1,true))end
end)
test('mod definitions use the real loaded ID/name and reported defining mod',function()
    local api,state=fixture(5501);local get=api.get
    api.get=function(key,id,word)if key=='monsterName'then return id==5501 and'Crab Knight'or''elseif key=='monsterMod'then return'CrabCult'end;return get(key,id,word)end
    local data=assert(V.read(api,5501));assert(data.name=='Crab Knight'and data.definitionMod=='CrabCult')
    assert(V.open(api,5501));assert(state.rows[1].monster==5501 and state.rows[1].name=='Crab Knight')
end)
test('caster rows show actual path/level defaults without inventing starting spell selections',function()
    local api=fixture();local get=api.get
    api.get=function(key,id,row)if key=='monsterAttackType'then return row==0 and 3 or nil elseif key=='monsterAttackWeapon'then return 81 elseif key=='monsterAttackValue'then return 2 end;return get(key,id,row)end
    local data=assert(V.read(api,13));local lines=table.concat(V.lines(data,80),'\n')
    assert(lines:find('School #81 (name unknown), default level 2',1,true)and not lines:find('Melee: Spear',1,true))
    assert(data.known==nil and data.memorized==nil and data.items==nil and data.unknown>0)
end)
test('unique metadata is viewed without any constructor, setter, reservation or team mutation',function()
    local api,state=fixture();assert(V.open(api,13));assert(state.units==0 and state.mutations==0)
    assert(state.rows[1].monster==13 and state.rows[1].action==0)
    local text='';for _,row in ipairs(state.text)do text=text..'\n'..row.text end
    assert(text:find('No unit is created',1,true)and text:find('unknown before placement',1,true))
end)
test('long Unicode names remain intact in paginated detail lines and codepoints are not split',function()
    local api=fixture();local get=api.get;local name=('Äther 蟹 '):rep(12)
    api.get=function(key,id,row)if key=='monsterName'then return name end;return get(key,id,row)end
    local data=assert(V.read(api,13));local lines=V.lines(data,28)
    local full='';for _,line in ipairs(lines)do assert(utf8.len(line));full=full..line end
    assert(full:find(name,1,true))
end)
test('pagination uses bounded detail rows and preserves the requested unit across pages',function()
    local api,state=fixture();state.choices={2,2,1,999};assert(V.open(api,13));assert(#state.screens==4 and #state.rows==4)
    for _,row in ipairs(state.rows)do assert(row.monster==13)end
    for _,row in ipairs(state.text)do assert(row.text~='Select')end
end)
test('invalid, missing and changing identities refuse instead of showing another type',function()
    local api=fixture();for _,id in ipairs({-1,0.5,6000,'13'})do assert(not V.read(api,id))end
    assert(not V.read(api,12))
    local get=api.get;local reads=0
    api.get=function(key,id,row)if key=='monsterName'then reads=reads+1;return reads==1 and'Spearman'or'Changed'end;return get(key,id,row)end
    local data,why=V.read(api,13);assert(not data and why:find('changed',1,true))
end)
test('unknown template fields and unlabelled abilities stay explicit and partial',function()
    local api=fixture();local get=api.get
    api.get=function(key,id,row)if key=='monster'and row=='mr'then return nil elseif key=='effectName'then return nil end;return get(key,id,row)end
    local data=assert(V.read(api,13));local lines=table.concat(V.lines(data,80),'\n')
    assert(data.unknown>0 and lines:find('Magic resistance: unknown',1,true)and lines:find('Ability [57]: 1',1,true))
end)
test('missing ability lookup stops at one refusal and does not invent empty complete data',function()
    local api=fixture();local get=api.get;local attempts=0
    api.get=function(key,id,row)if key=='monsterAbility'then attempts=attempts+1;error('Unavailable')end;return get(key,id,row)end
    local data=assert(V.read(api,13));assert(attempts==1 and not data.abilitiesAvailable and data.unknown>0)
end)
test('closing the native-style view returns template scope and never selects a unit',function()
    local api,state=fixture();local selected=77;local ok,detail=V.open(api,13)
    assert(ok and detail.monster==13 and detail.scope=='template/default'and detail.instanceCreated==false and selected==77)
    state.choices={0};assert(V.open(api,13))
end)
test('spell schools use only matching consistent names from the actual loaded catalog',function()
    local api,state=fixture();local get=api.get
    api.get=function(key,id,row)if key=='monsterAttackType'then return row==0 and 3 or nil elseif key=='monsterAttackWeapon'then return 81 elseif key=='monsterAttackValue'then return 2 end;return get(key,id,row)end
    local catalog={spells={{path=39,pathName='Druidism'},{path=81,pathName='Modded Tide Magic'},{path=81,pathName='Modded Tide Magic'}}}
    local data=assert(V.read(api,13,catalog));assert(data.attacks[1].schoolName=='Modded Tide Magic')
    local text=table.concat(V.lines(data,100),'\n');assert(text:find('Modded Tide Magic (school #81), default level 2',1,true)and not text:find('Druidism',1,true))
    assert(V.open(api,13,catalog));local modal='';for _,row in ipairs(state.text)do modal=modal..row.text end;assert(modal:find('Modded Tide Magic',1,true))
    catalog.spells[#catalog.spells+1]={path=81,pathName='Conflicting name'}
    data=assert(V.read(api,13,catalog));assert(data.attacks[1].schoolName==nil)
    assert(table.concat(V.lines(data,100),'\n'):find('School #81 (name unknown)',1,true))
end)
test('weapon defaults show actual base metadata without adding strength or estimating final damage',function()
    local api=fixture();local data=assert(V.read(api,13));local row=data.attacks[1]
    assert(row.baseDamage==4 and row.range==1 and row.damageType==3 and row.damageTypeName=='pierce')
    local text=table.concat(V.lines(data,100),'\n')
    assert(text:find('Weapon defaults: damage 4 | range 1 | pierce',1,true)and text:find('attack value 3',1,true))
    assert(not text:find('damage 9',1,true)and not text:find('final damage',1,true))
end)
test('unknown weapon metadata and damage types are explicit rather than guessed',function()
    local api=fixture();local get=api.get
    api.get=function(key,id,row)if key=='weapon'then if row=='dmgtype'then return 99 end;return nil end;return get(key,id,row)end
    local data=assert(V.read(api,13));local text=table.concat(V.lines(data,100),'\n')
    assert(data.unknown>=2 and text:find('damage unknown | range unknown | type #99',1,true))
end)
test('raw flags remain available to callers but do not consume player-facing page lines',function()
    local api=fixture();local data=assert(V.read(api,13));assert(data.rawFlags==8 and data.rawMovement==0)
    local lines=V.lines(data,71);local text=table.concat(lines,'\n')
    assert(not text:find('Raw',1,true)and not text:find('0x',1,true))
    assert(text:find('Attacks: Melee: Spear',1,true)and text:find('Abilities: unique',1,true))
    for _,line in ipairs(lines)do assert(line~='Attacks'and not line:match('^Attacks.*:$'))end
end)
test('the guarded native card receives the exact type without a substitute screen or template scan',function()
    local api,state=fixture(5501);local expected={monster=5501,verified=true,cleanupVerified=true,scope='native_preview_instance'}
    api.inspectTestFieldMonster=function(id)assert(id==5501);return true,expected end
    local ok,detail=V.open(api,5501);assert(ok and detail==expected and #state.calls==0 and #state.screens==0)
end)
test('native refusal and its cleanup evidence propagate without opening the fallback',function()
    local api,state=fixture();local expected={verified=false,cleanupVerified=false}
    api.inspectTestFieldMonster=function(id)assert(id==13);return false,'cleanup_unverified',expected end
    local ok,why,detail=V.open(api,13);assert(not ok and why=='cleanup_unverified'and detail==expected and #state.screens==0)
end)
test('an explicitly unsupported native build retains the functional metadata View',function()
    local api,state=fixture();api.testFieldEditorCapabilities=function()return{nativeMonsterInspectVersion=0}end
    api.inspectTestFieldMonster=function()error('Unsupported native card must not be invoked')end
    local ok,detail=V.open(api,13);assert(ok and detail.scope=='template/default'and #state.screens==1)
end)
print(count..' offline unit-view routing/default contracts passed; no native card, constructor or game simulated')
