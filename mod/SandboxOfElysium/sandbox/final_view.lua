-- Timed native unit/cell snapshot. Never creates actors or guesses positions.
local F={}
local function truth(v)return v==true or v==1 end
local function integer(v)return type(v)=='number' and v%1==0 end
-- Dense terrain must not consume the bounded diagnostic budget before actors.
-- Return references in a new list; never reorder or modify the frozen capture.
function F.exportUnits(snapshot,limit)
    local out={}
    for _,actor in ipairs({true,false})do for _,row in ipairs(snapshot and snapshot.units or {})do
        if (row.kind=='actor')==actor and #out<limit then out[#out+1]=row end
    end end
    return out
end
function F.prepare(snapshot)
    local plan={rows={},actors={},byUnit={},teamA=0,teamB=0,offField=0,dead=0,invalid=0,complete=false,source='unavailable'}
    if type(snapshot)~='table' or snapshot.source~='post_aftermath_before_upkeep' or not integer(snapshot.width) or not integer(snapshot.height) then return plan end
    plan.source=snapshot.source;plan.snapshot=snapshot
    plan.complete=truth(snapshot.complete) and #(snapshot.issues or {})==0
    for _,row in ipairs(snapshot.units or {}) do
        if not truth(row.alive) or not row.hp or row.hp<=0 then if row.kind=='actor'then plan.dead=plan.dead+1 end
        elseif row.anchorCount==0 then if row.kind=='actor'then plan.offField=plan.offField+1 end
        else
            local anchor=row.anchors and row.anchors[1]
            local valid=integer(row.unit) and row.unit>=0 and integer(row.monster) and row.monster>=0 and (row.kind=='actor' or row.kind=='terrain' or (row.kind=='structure' and snapshot.classificationVersion==1 and truth(row.provenanceVerified) and row.creationSource=='native_gate_replacement')) and
                row.anchorCount==1 and row.anchors and #row.anchors==1 and anchor and integer(anchor.x) and integer(anchor.y) and
                integer(row.width) and integer(row.height) and row.width>=1 and row.width<=3 and row.height>=1 and row.height<=3 and
                (row.kind=='terrain' or #(row.occupied or {})==row.width*row.height)
            local cells={}
            if valid and row.kind~='terrain' then for _,cell in ipairs(row.occupied) do
                if not integer(cell.x) or not integer(cell.y) then valid=false;break end
                local key=cell.x..':'..cell.y
                if cells[key] or cell.x<anchor.x or cell.x>=anchor.x+row.width or cell.y<anchor.y or cell.y>=anchor.y+row.height or
                    cell.x<0 or cell.y<0 or cell.x>=snapshot.width or cell.y>=snapshot.height then valid=false;break end
                cells[key]=true
            end end
            if valid and not plan.byUnit[row.unit] then
                local entry={native=row.unit,row=row,x=anchor.x,y=anchor.y,width=row.width,height=row.height,cells=cells,
                    monster=row.monster,hp=row.hp,team=row.owner==0 and 1 or row.owner==24 and 2 or 0,kind=row.kind}
                plan.rows[#plan.rows+1]=entry;plan.byUnit[row.unit]=entry
                if row.kind=='actor' then
                    plan.actors[#plan.actors+1]=entry
                    if entry.team==1 then plan.teamA=plan.teamA+1 elseif entry.team==2 then plan.teamB=plan.teamB+1 end
                end
            else plan.invalid=plan.invalid+1;plan.complete=false end
        end
    end
    table.sort(plan.rows,function(a,b)
        if a.kind~=b.kind then local order={terrain=1,structure=2,actor=3};return order[a.kind]<order[b.kind] end
        return a.y==b.y and a.x<b.x or a.y>b.y
    end)
    return plan
end
function F.at(plan,x,y)
    if not plan then return end
    local key=x..':'..y
    for _,entry in ipairs(plan.actors) do if entry.cells[key] then return entry end end
end
return F
