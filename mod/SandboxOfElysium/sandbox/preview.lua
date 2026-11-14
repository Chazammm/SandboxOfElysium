-- Read-only geometry. Native measurements are supplied by the caller; sprite
-- dimensions and temporary unit creation are deliberately not used here.
local P={}
local function dimensions(width,height)
    return type(width)=='number' and type(height)=='number' and width%1==0 and height%1==0 and width>0 and height>0
end
function P.shape(kind,n)
    n=math.max(1,math.min(15,math.floor(n or 1)))
    if kind=='Horizontal Row' then return n,1 elseif kind=='Vertical Row' then return 1,n
    elseif kind=='Square' then n=math.max(2,math.min(4,n));return n,n end
    return 1,1
end
function P.anchors(kind,n,x,y,width,height)
    if not dimensions(width,height) then return nil,'Native footprint unavailable' end
    local columns,rows=P.shape(kind,n);local out={}
    for row=0,rows-1 do for column=0,columns-1 do
        out[#out+1]={x=x+column*width,y=y+row*height}
    end end
    return out
end
function P.span(kind,n,width,height)
    if not dimensions(width,height) then return end
    local columns,rows=P.shape(kind,n);return columns*width,rows*height
end
function P.snap(x,y,origin,stepX,stepY)
    if not origin or not dimensions(stepX,stepY) then return x,y end
    return origin.x+math.floor((x-origin.x)/stepX)*stepX,origin.y+math.floor((y-origin.y)/stepY)*stepY
end
function P.cells(anchors,width,height)
    if not dimensions(width,height) then return {} end
    local out={}
    for index,anchor in ipairs(anchors) do
        for dy=0,height-1 do for dx=0,width-1 do
            out[#out+1]={x=anchor.x+dx,y=anchor.y+dy,anchor=index}
        end end
    end
    return out
end
return P
