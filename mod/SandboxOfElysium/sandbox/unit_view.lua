-- Prefer the guarded genuine native preview card when available. The legacy
-- metadata view remains usable with older Extenders; it never creates actors.
local C=require('sandbox.catalog')
local V={}
local fields={{'hp','Hit points'},{'armor','Armor'},{'str','Strength'},{'mor','Morale'},{'mr','Magic resistance'},{'rank','Rank'}}
-- These are supported single-bit monster/movement words, not inferred traits.
-- Anatomical slot selectors are omitted: their shared mask is not a bool trait.
local flagWords={
    'acutesenses','aggressive','ancforest1','animal','badsight','banishsurv','battlefast','battleslow','battleslow2',
    'berserker','bluntres','charmres','citadel2','clumsy','coastal','coldblood','curseditem','deadforest1','deadforest2',
    'demonic','desert','desert1','desert2','desert3','desertstealth','diseaseres','ethereal','fast','fastheal','female',
    'float','flying','followstupid','forest1','forest2','foreststealth','frontpos','gates1','holy','horror','huge',
    'human','immobile','immortal','inanimate','invisible','invul','jungle1','jungle2','largeshield','loner','lucky',
    'magicshield','mines1','money1','money2','mountain','mountain1','mountain2','nocombat','noheal','noland','noleader',
    'nonmaginvul','nonruin1','north1','nozoc','passwall','pierceres','rearpos','regeneration','savanna2','semistupid',
    'shield','shipmove','size1x1','size2x2','slashres','sleepres','slow','snow','snowstealth','south1','south2',
    'spiritsight','stationary','stealth','stray','stupid','swallowres','swamp','swamp1','swamp2','teleport',
    'temple1','temple2','tiny','treelook','tunnel','unaging','undead','unimportant','void2','wall','water','winteridle'}
local attackNames={[1]='Melee',[2]='Ranged',[3]='Spell',[4]='Melee bonus',[5]='Ranged bonus',[6]='Spell bonus',
    [7]='Ranged25',[8]='Special melee',[10]='Pre-battle',[11]='Ranged50',[12]='Assassin',[13]='Siege',
    [14]='Spell50',[15]='Single spell',[17]='Melee50s',[18]='Ranged50s',[19]='Spell50s',[21]='Ranged50x'}
local spellAttack={[3]=true,[6]=true,[14]=true,[15]=true,[19]=true}
local damageNames={[1]='slash',[2]='blunt',[3]='pierce',[4]='fire',[5]='cold',[6]='shock',[7]='magic',[8]='fear',
    [9]='poison',[10]='acid',[11]='phantasm',[12]='special damage',[13]='special benefit',[14]='charm',
    [15]='polymorph',[16]='sleep',[17]='paralyze',[18]='summon',[19]='enslave',[20]='swallow',
    [21]='mirror image',[22]='corrupt',[23]='banish',[24]='petrify',[25]='animate',[26]='heal'}
local function integer(value,low,high)
    return type(value)=='number'and value%1==0 and value>=low and value<=high
end
local function read(api,...)
    local ok,value=pcall(api.get,...)
    if ok then return value end
end
local function number(value)return type(value)=='number'and value%1==0 and value or nil end
local function schoolName(catalog,path)
    if type(catalog)~='table'or type(catalog.spells)~='table'then return nil end
    local name
    for _,spell in ipairs(catalog.spells)do
        if type(spell)=='table'and spell.path==path and type(spell.pathName)=='string'and spell.pathName~=''then
            if name and name~=spell.pathName then return nil end
            name=spell.pathName
        end
    end
    return name
end
function V.read(api,id,catalog)
    if type(api)~='table'or type(api.get)~='function'or not integer(id,0,65535)then return nil,'Unit type is unavailable.'end
    local last=read(api,'monsterLastIndex')
    if not integer(last,0,65535)or id>last then return nil,'Unit type is unavailable.'end
    local name=read(api,'monsterName',id)
    if type(name)~='string'or name==''then return nil,'Unit type is missing or no longer loaded.'end
    local result={monster=id,name=name,stats={},flags={},abilities={},attacks={},scope='template/default',unknown=0}
    result.sprite=number(read(api,'monsterSprite',id))
    local source=read(api,'monsterMod',id)
    if type(source)=='string'and source~=''then result.definitionMod=source end
    for _,field in ipairs(fields)do
        local value=number(read(api,'monster',id,field[1]))
        result.stats[#result.stats+1]={label=field[2],value=value}
        if value==nil then result.unknown=result.unknown+1 end
    end
    for _,word in ipairs(flagWords)do
        local value=read(api,'monster',id,word)
        if value==true then result.flags[#result.flags+1]=word
        elseif value~=false then result.unknown=result.unknown+1 end
    end
    local flags=read(api,'monsterFlags',id);local movement=read(api,'monsterMoveFlags',id)
    if integer(flags,math.mininteger,math.maxinteger)then result.rawFlags=flags end
    if integer(movement,math.mininteger,math.maxinteger)then result.rawMovement=movement end
    -- Read on demand, once per View. Existing public lookup returns the first
    -- native definition value; these are not summed instance abilities.
    result.abilitiesAvailable=true
    for ability=0,1501 do
        local value=number(read(api,'monsterAbility',id,ability))
        if value==nil then result.abilitiesAvailable=false;result.unknown=result.unknown+1;break end
        if value~=0 then
            local word=read(api,'effectName',ability)
            result.abilities[#result.abilities+1]={id=ability,value=value,word=type(word)=='string'and word~=''and word or nil}
        end
    end
    result.attacksAvailable=true
    for index=0,15 do
        local kind=read(api,'monsterAttackType',id,index)
        if kind==nil then break end
        local weapon=read(api,'monsterAttackWeapon',id,index);local value=read(api,'monsterAttackValue',id,index)
        if not integer(kind,1,2147483647)or not integer(weapon,0,2147483647)or number(value)==nil then
            result.attacksAvailable=false;result.unknown=result.unknown+1;break
        end
        local row={kind=kind,kindLabel=attackNames[kind]or('Attack kind #'..kind),weapon=weapon,value=value,spell=spellAttack[kind]==true}
        if row.spell then
            row.schoolName=schoolName(catalog,weapon)
            if not row.schoolName then result.unknown=result.unknown+1 end
        else
            local label=read(api,'weaponName',weapon);if type(label)=='string'and label~=''then row.name=label end
            row.baseDamage=number(read(api,'weapon',weapon,'dmg'))
            row.range=number(read(api,'weapon',weapon,'range'))
            row.damageType=number(read(api,'weapon',weapon,'dmgtype'))
            row.damageTypeName=damageNames[row.damageType]
            for _,key in ipairs({'baseDamage','range','damageType'})do if row[key]==nil then result.unknown=result.unknown+1 end end
        end
        result.attacks[#result.attacks+1]=row
    end
    if read(api,'monsterName',id)~=name then return nil,'The loaded unit type changed while its information was read.'end
    return result
end
local function wrap(text,width)
    local out={};text=tostring(text)
    while text~=''do
        local part=C.textLimit(text,width)
        out[#out+1]=part;text=text:sub(#part+1)
    end
    return out
end
function V.lines(data,width)
    local lines={}
    local function add(text)for _,line in ipairs(wrap(text,width or 70))do lines[#lines+1]=line end end
    add('Unit type: '..data.name..' (#'..data.monster..')')
    if data.definitionMod then add('Definition mod: '..data.definitionMod)end
    local stats={};for _,row in ipairs(data.stats)do stats[#stats+1]=row.label..': '..(row.value==nil and'unknown'or row.value)end
    add(table.concat(stats,' | '))
    add('Movement and traits: '..(#data.flags>0 and table.concat(data.flags,', ')or'none observed'))
    for index,row in ipairs(data.attacks)do
        local prefix=index==1 and'Attacks: 'or''
        if row.spell then add(prefix..row.kindLabel..': '..(row.schoolName and(row.schoolName..' (school #'..row.weapon..')')or('School #'..row.weapon..' (name unknown)'))..', default level '..row.value)
        else
            add(prefix..row.kindLabel..': '..(row.name or('Weapon #'..row.weapon))..', attack value '..row.value)
            local damage=row.baseDamage==nil and'unknown'or row.baseDamage
            local range=row.range==nil and'unknown'or row.range
            local kind=row.damageTypeName or(row.damageType and('type #'..row.damageType)or'unknown')
            add('Weapon defaults: damage '..damage..' | range '..range..' | '..kind)
        end
    end
    if #data.attacks==0 then add(data.attacksAvailable and'Attacks: none observed.'or'Attack information unavailable.')end
    for index,row in ipairs(data.abilities)do add((index==1 and'Abilities: 'or'')..(row.word or'Ability')..' ['..row.id..']: '..row.value)end
    if #data.abilities==0 then add(data.abilitiesAvailable and'Abilities: none observed.'or'Ability information unavailable.')end
    if data.unknown>0 then add('Some template fields are unavailable ('..data.unknown..'); this view is partial.')end
    return lines
end
function V.nativeAvailable(api)
    if type(api.inspectTestFieldMonster)~='function'then return false end
    if type(api.testFieldEditorCapabilities)=='function'then
        local ok,caps=pcall(api.testFieldEditorCapabilities)
        if ok and type(caps)=='table'and caps.nativeMonsterInspectVersion==0 then return false end
    end
    return true
end
function V.open(api,id,catalog)
    if V.nativeAvailable(api)then
        -- A refused native transaction must not be concealed by opening a
        -- substitute card. The caller verifies cleanup and the existing field.
        return api.inspectTestFieldMonster(id)
    end
    local data,why=V.read(api,id,catalog);if not data then return false,why end
    local ui=api.ui
    if type(ui)~='table'or type(ui.screenBegin)~='function'or type(ui.wait)~='function'then return false,'Native-style unit information view is unavailable.'end
    local width=math.min(680,(read(api,'screenW')or 800)-30)
    local columns=math.max(28,math.floor((width-35)/9))
    local lines=V.lines(data,columns);local perPage=8;local page=1;local pages=math.max(1,math.ceil(#lines/perPage))
    while true do
        ui.screenBegin('Unit information — template/default');ui.screenWidth(width)
        ui.sectionBegin('Selected unit type')
        if type(ui.monsterRow)=='function'then ui.monsterRow(0,id,C.textLimit(data.name,math.max(16,columns-8),'...'),'#'..id..' | Template/default; not a placed unit')
        else ui.text(0,C.textLimit(data.name,columns,'...')..' (#'..id..')')end
        ui.text(0,'Template values, not final battle stats. No unit is created.')
        ui.text(0,'Items and random known/memorized spells are unknown before placement.')
        ui.sectionEnd();ui.sectionBegin('Definition information — '..page..' / '..pages)
        for index=(page-1)*perPage+1,math.min(page*perPage,#lines)do ui.text(0,lines[index])end
        ui.sectionEnd();ui.buttonRow();ui.text(1,'Previous');ui.text(2,'Next');ui.text(999,'Back');ui.bindEscape(999)
        local chosen=ui.wait()
        if chosen==999 or chosen==0 or chosen==nil then return true,{monster=id,name=data.name,scope='template/default',instanceCreated=false,partial=data.unknown>0}end
        if chosen==1 then page=math.max(1,page-1)elseif chosen==2 then page=math.min(pages,page+1)end
    end
end
return V
