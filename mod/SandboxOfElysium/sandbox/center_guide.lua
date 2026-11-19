-- Projection-only midpoint overlay geometry. No input or native state writes.
local G={}
local function finite(n)return type(n)=='number'and n==n and n>-math.huge and n<math.huge end
local function positive(n)return finite(n)and n>0 end
function G.line(view,clip)
    if type(view)~='table'or type(clip)~='table'or
        not finite(view.originX)or not finite(view.originY)or not positive(view.cellSize)or
        not positive(view.width)or view.width%1~=0 or view.width>1536 or
        not positive(view.height)or view.height%1~=0 or view.height>20 or
        not finite(clip.x)or not finite(clip.y)or not positive(clip.width)or not positive(clip.height)then return nil end
    -- Column indices denote cell centers at i+0.5. A continuous width/2 is
    -- between the middle columns for even widths, inside the middle cell for odd.
    local x=view.originX+view.width*view.cellSize/2
    local top=view.originY+view.height*view.cellSize
    local right,clipTop=clip.x+clip.width,clip.y+clip.height
    if not finite(x)or not finite(top)or not finite(right)or not finite(clipTop)then return nil end
    local y1,y2=math.max(view.originY,clip.y),math.min(top,clipTop)
    if x<clip.x or x>=right or y2<=y1 then return nil end
    return{x=x,y1=y1,y2=y2,midColumn=view.width/2,fieldWidth=view.width,fieldHeight=view.height}
end
return G
