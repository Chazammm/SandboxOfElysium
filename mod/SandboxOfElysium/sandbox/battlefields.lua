local B={}
-- These are editor minimums demonstrated in native fields, not a vanilla preset enum.
B.sizes={
    {name='Native automatic'},
    {name='Small',columns=32},
    {name='Medium',columns=50},
    {name='Large',columns=70},
    {name='Extra Large',columns=160},
}
function B.sizeLabel(s)
    if not s.minimumWidth then return 'Native automatic'end
    for _,row in ipairs(B.sizes)do if row.columns==s.minimumWidth then return row.name..' (minimum '..row.columns..' x 20)'end end
    return 'Minimum '..s.minimumWidth..' x 20'
end
function B.sizeAvailable(c,row)
    if not row.columns then return true end
    local e=c.environment
    return type(e)=='table' and e.minimumWidthVersion==1 and e.rows==20 and
        type(e.minimumColumns)=='number'and type(e.maximumColumns)=='number'and
        row.columns>=e.minimumColumns and row.columns<=e.maximumColumns
end
function B.selectSize(c,s,row)
    if not B.sizeAvailable(c,row)then return false,'This minimum size needs the separate release-next size API. Current setup kept.'end
    s.minimumWidth=row.columns;s.size=row.columns and 'Minimum width'or'Native automatic'
    return true
end
return B
