local Objects={}

function Objects.role(row)
    if type(row)~='table' or row.provenanceVerified~=true then return end
    if row.kind=='structure' and row.creationSource=='native_gate_replacement' then return 'structure' end
    if row.kind=='terrain' and row.owner==31 and
        (row.creationSource=='native_map_loader' or row.creationSource=='native_terrain_placement') then
        return 'scenery'
    end
end

function Objects.label(role,owner)
    if role=='scenery' then return 'Neutral battlefield scenery' end
    if role=='structure' then
        if owner==0 then return 'Native structure | attacker side' end
        if owner==24 then return 'Native structure | defender side' end
        return 'Native battlefield structure'
    end
end

return Objects
