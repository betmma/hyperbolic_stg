--! file: shape.lua
local Shape = Object:extend()
Shape.curvature=100
Shape.removeDistance=100
Shape.timeSpeed=1
Shape.axisY=-100
local EPS=1e-8
Shape.EPS=EPS
function Shape.restore()
    Shape.curvature=100
    Shape.axisY=-100
    Shape.removeDistance=100
end

function Shape:new(args)
    self.args=args
    self.x = args.x
    self.y = args.y
    self.metric=self:getMetric()
    self.speed = args.speed or 0
    self.direction = args.direction or math.pi*2/9
    self.lifeFrame=args.lifeFrame or 1000
    self.time=0
    self.frame=0
    self.removeDistance=args.removeDistance or Shape.removeDistance
end

function Shape:getMetric()
    return (self.y-Shape.axisY)/Shape.curvature
end

function Shape:getMoveRadius()
    return (self.y-Shape.axisY)/math.cos(self.direction)
end

function Shape:update(dt)
    self.time=self.time+dt
    self.frame=self.frame+1
    if self.frame>self.lifeFrame then
        self:remove()
    end
    if self.x<-self.removeDistance+150 or self.x>self.removeDistance+love.graphics.getWidth()-150 or math.abs(self.y-Shape.axisY)<50/math.log(self.removeDistance,10) or self.y<-self.removeDistance or self.y>self.removeDistance+love.graphics.getHeight() then
        self:remove()
    end
    self:updateMove(dt)
end

function Shape:updateMove(dt)
    self.metric=self:getMetric()
    self.moveRadius=self:getMoveRadius()
    local moveDistance=self.speed* dt * Shape.timeSpeed * self.metric
    self.x = self.x +  moveDistance * math.cos(self.direction) 
    self.y=self.y+moveDistance * math.sin(self.direction) 
    self.direction=self.direction-moveDistance/self.moveRadius
end

function Shape:drawAll()
    love.graphics.line(0,Shape.axisY,love.graphics.getWidth(),Shape.axisY) -- draw the axis
    for key, obj in pairs(self.objects) do
      if not obj.removed then
        obj:draw()
      end
    end
    for key, cls in pairs(self.subclasses) do
        cls:drawAll()
    end
end
-- function Shape:updateAll(dt)
--     -- Shape.axisY=Shape.axisY+dt*10
--     for key, obj in pairs(self.objects) do
--         obj:update(dt)
--     end
-- end

---@class Shape:Object
---@field x number
---@field y number
---@field speed number
---@field direction number
---@field lifeFrame number after which the object will be removed
---@field time number deprecated
---@field frame number number of frames since the object was created. It's just an incrementer, so you can modify it freely.
---@field removeDistance number distance from the screen after which the object will be removed (roughly)
return Shape