local Objects={}

-- Older experimental builds advertised capability without the native role.
local legacyBuildings={
    [1394]={name='Stone Parapet (Medium Cover)',group='Parapets'},
    [1395]={name='Stone Parapet (Heavy Cover)',group='Parapets'},
    [1404]={name='Stone Wall',group='Walls'},
    [1446]={name='Palisade Parapet',group='Parapets'},
    [1448]={name='Palisade Wall',group='Walls'},
    [1462]={name='Wooden Stairs',group='Stairs'},
    [1511]={name='Stone Stairs',group='Stairs'},
}
local neutralGroups={wall='Walls',parapet='Parapets',stairs='Stairs'}

function Objects.neutralGroup(entry)
    if type(entry)~='table' or entry.scenery~=true or entry.definitionMod~=nil then return end
    local group
    if entry.sceneryRole then
        group=neutralGroups[entry.sceneryRole]
    else
        local legacy=legacyBuildings[entry.id]
        if legacy and legacy.name==entry.name then group=legacy.group end
    end
    if group and (group=='Walls' or entry.sceneryStandable==true) then return group end
end

function Objects.neutralBuilding(entry)
    return Objects.neutralGroup(entry)~=nil
end

function Objects.neutralStanding(entry)
    local group=Objects.neutralGroup(entry)
    return group~=nil and group~='Walls'
end

function Objects.savedNeutralProblem(entry)
    if not Objects.neutralBuilding(entry) then
        return entry.name..' is unavailable in Neutral. The original scenario file is kept'
    end
end

function Objects.role(row)
    if type(row)~='table' or row.provenanceVerified~=true then return end
    if row.kind=='structure' and row.creationSource=='native_gate_replacement' then return 'structure' end
    if row.kind=='actor' and row.owner==31 and row.anchorLayer=='unit' and row.creationSource=='owned_neutral_actor' then return 'neutral' end
    if row.kind=='terrain' and row.owner==31 and
        (row.creationSource=='native_map_loader' or row.creationSource=='native_terrain_placement' or
         (row.creationSource=='owned_scenery_placement' and row.anchorLayer=='object')) then
        return 'scenery'
    end
end

function Objects.label(role,owner)
    if role=='scenery' then return 'Neutral battlefield scenery' end
    if role=='unverified' then return 'Unverified battlefield object' end
    if role=='neutral' then return 'Neutral actor | fights both sides' end
    if role=='structure' then
        if owner==0 then return 'Native structure | attacker side' end
        if owner==24 then return 'Native structure | defender side' end
        return 'Native battlefield structure'
    end
end

return Objects
