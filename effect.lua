
local Shape = require "shape"
local Circle=require"circle"
local PolyLine=require"polyline"
local Effect = Shape:extend()

function Effect:new(args)
    Effect.super.new(self, args)
end
local Larger=Effect:extend()
Effect.Larger=Larger
function Larger:new(args)
    Larger.super.new(self, args)
    self.sprite=args.sprite
    self.radius = args.radius or 1
    self.growSpeed=args.growSpeed or 1.2
    self.animationFrame=args.animationFrame or 30
end

function Larger:update(dt)
    self.frame=self.frame+1
    self.radius=self.radius*self.growSpeed
    local x,y,r=Shape.getCircle(self.x,self.y,self.radius)
    local scale=r/30.3333
    local size=Asset.SpriteData[self.sprite].size
    Asset.effectBatch:setColor(1,1,1,1-self.frame/self.animationFrame)
    Asset.effectBatch:add(self.sprite,x,y,0,scale,scale,size/2,size/2)
    if self.frame==self.animationFrame then
        self:remove()
    end
end
-- A growing shockwave, that removes touched bullets and activate their :removeEffect
local Shockwave=Larger:extend()
Effect.Shockwave=Shockwave
function Shockwave:new(args)
    Shockwave.super.new(self, args)
    self.color=args.color or 'red'
    self.sprite=Asset.shockwave[self.color]
end

function Shockwave:update(dt)
    Shockwave.super.update(self,dt)

end

return Effect