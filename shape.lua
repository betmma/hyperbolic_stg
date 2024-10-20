--! file: shape.lua
local Shape = Object:extend()
Shape.curvature=100
Shape.axisY=-100
function Shape.distance(x1,y1,x2,y2)
    local ay=Shape.axisY
    return 2*Shape.curvature*math.log((math.distance(x1,y1,x2,y2)+math.distance(x1,y1,x2,2*ay-y2))/(2*((y1-ay)*(y2-ay))^0.5))
end
-- get direction from x1,y1 to x2,y2
function Shape.to(x1,y1,x2,y2)
    local x0=(x1+x2)/2
    local y0=(y1+y2)/2
    if x1==x2 then -- vertical 
        return y1<y2 and math.pi/2 or -math.pi/2
    end
    local k=(y2-y1)/(x2-x1)
    local centerX=x0+(y0-Shape.axisY)*k
    local theta1=math.atan2(y1-Shape.axisY,x1-centerX)
    local theta2=math.atan2(y2-Shape.axisY,x2-centerX)
    if theta1<theta2 then
        return theta1+math.pi/2
    end
    return theta1-math.pi/2
end


function Shape:new(x, y, speed, direction)
    self.x = x
    self.y = y
    self.metric=self:getMetric()
    self.speed = speed or 100
    self.direction = direction or math.pi*2/9
    self.lifeTime=10
    self.time=0
    self.removeDistance=100
end

function Shape:getMetric()
    return (self.y-Shape.axisY)/Shape.curvature
end

function Shape:getMoveRadius()
    return (self.y-Shape.axisY)/math.cos(self.direction)
end

function Shape:update(dt)
    self.time=self.time+dt
    if self.time>self.lifeTime then
        self:remove()
    end
    if self.x<-self.removeDistance or self.x>self.removeDistance+love.graphics.getWidth() or math.abs(self.y-Shape.axisY)<5 or self.y<-self.removeDistance or self.y>self.removeDistance+love.graphics.getHeight() then
        self:remove()
    end
    self.metric=self:getMetric()
    self.moveRadius=self:getMoveRadius()
    local moveDistance=self.speed* dt * self.metric
    self.x = self.x +  moveDistance * math.cos(self.direction) 
    self.y=self.y+moveDistance * math.sin(self.direction) 
    self.direction=self.direction-moveDistance/self.moveRadius
end

function Shape:drawAll()
    love.graphics.line(0,Shape.axisY,love.graphics.getWidth(),Shape.axisY) -- draw the axis
    for key, obj in pairs(self.objects) do
        obj:draw()
    end
end
function Shape:updateAll(dt)
    -- Shape.axisY=Shape.axisY+dt*10
    for key, obj in pairs(self.objects) do
        obj:update(dt)
    end
end

return Shape