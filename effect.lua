
local Shape = require "shape"
local Circle=require"circle"
local PolyLine=require"polyline"
local Effect = Shape:extend()

function Effect:new(args)
    Effect.super.new(self, args)
end

-- something keep growing and reducing opacity
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
    self.canRemove=args.canRemove or {bullet=true}
end

function Shockwave:update(dt)
    Shockwave.super.update(self,dt)

end

-- generating black smoke, boding a huge attack
local Charge=Effect:extend()
Effect.Charge=Charge
function Charge:new(args)
    Charge.super.new(self, args)
    self.obj=args.obj or self
    self.sprite=args.sprite or Asset.shards.round
    self.radius = args.radius or 1
    self.particleSpeed=args.particleSpeed or 5
    self.particleFrame=args.particleFrame or 40
    self.particleSize=args.particleSize or 5
    self.particles={}
    self.animationFrame=args.animationFrame or 120
    self.color=args.color or {0.3,0.3,0.3}
end

function Charge:update(dt)
    self.frame=self.frame+1
    local size=Asset.SpriteData[self.sprite].size
    table.insert(self.particles,{frame=0,x=self.obj.x,y=self.obj.y,direction=math.eval('0+999'),speed=self.particleSpeed})
    for k,particle in pairs(self.particles) do
        particle.frame=particle.frame+1
        if particle.frame>=self.particleFrame then
            goto continue
        end
        particle.x=particle.x+particle.speed*math.cos(particle.direction)
        particle.y=particle.y+particle.speed*math.sin(particle.direction)
        local scale=self.particleSize*0.95^particle.frame
        local x,y=particle.x,particle.y
        Asset.effectBatch:setColor(self.color[1],self.color[2],self.color[3],1-particle.frame/self.particleFrame)
        Asset.effectBatch:add(self.sprite,x,y,0,scale,scale,size/2,size/2)
        ::continue::
    end
    if self.frame==self.animationFrame then
        self:remove()
    end
end


return Effect