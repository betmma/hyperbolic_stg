--! file: circle.lua
local Shape = require "shape"
local Point = Shape:extend()

function Point:new(x, y,draw)
    self.doDraw=draw==nil and true or draw
    Point.super.new(self, {x=x, y=y})
end

function Point:draw()
    if not self.doDraw then
        return
    end
    love.graphics.circle("line", self.x, self.y, 1) -- 1 px
end

local PolyLine=Object:extend()
function PolyLine:new(points,draw)
    self.doDraw=draw==nil and true or draw
    self.points={}
    for key, value in pairs(points) do
        self.points[#self.points+1] = Point(value[1],value[2],self.doDraw)
    end
end

-- assume that points are given by increasing polar angle (so points should be right to each line)
function PolyLine:inside(xc,yc)
    local itenum=#self.points
    if itenum==2 then
        itenum=1
    end
    for i=1,itenum do
        if not self:insideOne(xc,yc,i) then
            return false,self.points[i].x,self.points[i].y,self.points[i%#self.points+1].x,self.points[i%#self.points+1].y
        end
    end
    return true
end

function PolyLine:insideOne(xc,yc,index)
    return not Shape.leftToLine(xc,yc,self.points[index].x,self.points[index].y,self.points[index%#self.points+1].x,self.points[index%#self.points+1].y)
end

function PolyLine:draw()
    if not self.doDraw then
        return
    end
    local itenum=#self.points
    if itenum==2 then
        itenum=1
    end
    for i=1,itenum do
        self.drawOne(self.points[i],self.points[i%#self.points+1])
    end
end

-- draw line segment from (p1.x,p1.y) to (p2.x,p2.y)
function PolyLine.drawOne(p1,p2)
    local x1=p1.x
    local y1=p1.y
    local x2=p2.x
    local y2=p2.y
    if  math.abs(x1-x2)<Shape.EPS then -- vertical -> line
        love.graphics.line(x1,y1,x2,y2)
        return
    end
    local centerX,r=Shape.lineCenter(x1,y1,x2,y2)
    local theta1=math.atan2(y1-Shape.axisY,x1-centerX)
    local theta2=math.atan2(y2-Shape.axisY,x2-centerX)
    Shape.drawNormalArc(centerX,Shape.axisY,r,theta1,theta2,50)

    -- we know that in Poincare half plane a straight line is a semicircle and satisfies no 2 points on it have same x, so a line segment can be got by clipping x coordinate
    -- if math.abs(x1-x2)>20 or math.abs(y1-y2)<20 then
    --     love.graphics.setScissor(math.min(x1,x2),math.min(y1,y2),math.abs(x1-x2),9999)
    -- else
    --     local height=math.abs(y1-y2)
    --     if math.min(x1,x2)<centerX and math.max(x1,x2)>centerX then
    --         height=r+Shape.axisY-math.min(y1,y2)
    --     end
    --     love.graphics.setScissor(math.min(x1,x2)-5,math.min(y1,y2),math.abs(x1-x2)+10,height)
    -- end
    -- love.graphics.circle("line", centerX,Shape.axisY,((centerX-x1)^2+(y1-Shape.axisY)^2)^0.5)
    -- love.graphics.setScissor( )
    -- love.graphics.arc("line",centerX,0,((centerX-x1)^2+y1^2)^0.5,math.min(theta1,theta2),math.max(theta1,theta2)) -- this draws 2 radii and can't be cancelled :(
end
function PolyLine:remove()
    PolyLine.super.remove(self)
    for key, value in pairs(self.points) do
        value:remove()
    end
end
function PolyLine:drawAll()
    for key, obj in pairs(self.objects) do
        obj:draw()
    end
end
return PolyLine