--! file: circle.lua
local Shape = require "shape"
local Circle = Shape:extend()

function Circle:new(args)
    Circle.super.new(self, args)
    --A circle doesn't have a width or height. It has a radius.
    self.radius = args.radius or 1
    self.extraUpdate={}
end

function Circle:draw()
    -- Formula: center (x,y) and radius r should be drawn as center (x,y*cosh(r)) and radius y*sinh(r)
    love.graphics.circle("line", self.x, (self.y-Shape.axisY)*math.cosh(self.radius/Shape.curvature)+Shape.axisY, (self.y-Shape.axisY)*math.sinh(self.radius/Shape.curvature))
    -- love.graphics.circle("line", self.x, self.y, 1) -- center point
end

function Circle:update(dt)
    for k, func in pairs(self.extraUpdate or {}) do
        func(self,dt)
    end
    self.super.update(self,dt)
end
return Circle