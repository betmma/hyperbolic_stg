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

-- Warning: points must form a convex polygon
local PolyLine=GameObject:extend()
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

-- obj should include x, y and direction. This function modifies obj.
-- usage example: adding a LoopEvent with condition = not polyline:inside(obj) and execute func = polyline:reflection(obj)
function PolyLine:reflection(obj)
    local inside,x1,y1,x2,y2=self:inside(obj.x,obj.y)
    if inside then
        return
    end
    if math.abs(x1-x2)<Shape.EPS then -- vertical
        obj.x=2*x1-obj.x
        obj.direction=-obj.direction
    end
    local centerX,radius=Shape.lineCenter(x1,y1,x2,y2)
    local direction=math.atan2(obj.y-Shape.axisY,obj.x-centerX)
    local r2=radius*2-math.distance(obj.x,obj.y,centerX,Shape.axisY)
    obj.x,obj.y=centerX+r2*math.cos(direction),Shape.axisY+r2*math.sin(direction)
    obj.direction=2*direction-obj.direction+math.pi
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
    Shape.drawSegment(x1,y1,x2,y2)
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