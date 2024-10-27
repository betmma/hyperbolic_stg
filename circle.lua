--! file: circle.lua
local Shape = require "shape"
local Circle = Shape:extend()

function Circle:new(args)
    Circle.super.new(self, args)
    --A circle doesn't have a width or height. It has a radius.
    self.radius = args.radius or 1
    self.sprite=args.sprite
    if self.sprite then
        local data=SpriteData[self.sprite]
        self.radius=self.radius*2.4/data.hitRadius
    end
    self.extraUpdate={}
    -- safe means won't hit player and can hit enemy
    self.safe=false
end

function Circle:draw()
    -- Formula: center (x,y) and radius r should be drawn as center (x,y*cosh(r)) and radius y*sinh(r)
    -- Shape.drawCircle(self.x,self.y,self.radius)
    -- love.graphics.circle("line", self.x, self.y, 1) -- center point
end


function Circle:update(dt)
    if self.reomved then
        return
    end
    for k, func in pairs(self.extraUpdate or {}) do
        func(self,dt)
    end
    self.super.update(self,dt)
    local x,y,r=Shape.getCircle(self.x,self.y,self.radius)
    local data=SpriteData[self.sprite]
    local scale=r/3.3333
    if self.sprite then
        BulletBatch:add(self.sprite,x,y,self.direction+math.pi/2,scale,scale,data.size/2,data.size/2)
    end
end
return Circle