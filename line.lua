--! file: circle.lua
local Shape = require "shape"
local Point = Shape:extend()

function Point:new(x, y)
    Point.super.new(self, x, y,0,0)
end

function Point:draw()
    love.graphics.circle("line", self.x, self.y, 1) -- 1 point
end

local Line=Object:extend()
function Line:new(points)
    self.points={}
    for key, value in pairs(points) do
        self.points[#self.points+1] = Point(value[1],value[2])
    end
end
function Line:draw()
    local itenum=#self.points
    if itenum==2 then
        itenum=1
    end
    for i=1,itenum do
        self:drawOne(self.points[i],self.points[i%#self.points+1])
    end
end
function Line:drawOne(p1,p2)
    local x1=p1.x
    local y1=p1.y
    local x2=p2.x
    local y2=p2.y
    local x0=(x1+x2)/2
    local y0=(y1+y2)/2
    if x1==x2 then -- vertical -> line
        love.graphics.line(x1,y1,x2,y2)
        return
    end
    local k=(y2-y1)/(x2-x1)
    local centerX=x0+(y0-Shape.axisY)*k
    -- local theta1=math.atan2(y1,x1-centerX)
    -- local theta2=math.atan2(y2,x2-centerX)
    love.graphics.setScissor(math.min(x1,x2),math.min(y1,y2),math.abs(x1-x2),9999)
    love.graphics.circle("line", centerX,Shape.axisY,((centerX-x1)^2+(y1-Shape.axisY)^2)^0.5)
    love.graphics.setScissor( )
    -- love.graphics.arc("line",centerX,0,((centerX-x1)^2+y1^2)^0.5,math.min(theta1,theta2),math.max(theta1,theta2)) -- this draws 2 radii and can't be cancelled :(
end
function Line:remove()
    Line.super.remove(self)
    for key, value in pairs(self.points) do
        value:remove()
    end
end
function Line:drawAll()
    for key, obj in pairs(self.objects) do
        obj:draw()
    end
end
return Line