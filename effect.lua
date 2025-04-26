
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
    ---@type Sprite
    self.sprite=args.sprite
    self.radius = args.radius or 1
    self.growSpeed=args.growSpeed or 1.2
    self.animationFrame=args.animationFrame or 30
end

function Larger:update(dt)
    Larger.super.update(self,dt)
    self.radius=self.radius*self.growSpeed
    if self.frame==self.animationFrame then
        self:remove()
    end
end

function Larger:draw()
    local x,y,r=Shape.getCircle(self.x,self.y,self.radius)
    local size=self.sprite.data.size
    local scale=r/size*2*(self.drawScale or 1)
    local direction=self.direction or 0
    Asset.effectBatch:setColor(1,1,1,1-self.frame/self.animationFrame)
    Asset.effectBatch:add(self.sprite.quad,x,y,direction,scale,scale,size/2,size/2)
end

-- A growing shockwave, that removes touched bullets and activate their :removeEffect
local Shockwave=Larger:extend()
Effect.Shockwave=Shockwave
function Shockwave:new(args)
    Shockwave.super.new(self, args)
    self.color=args.color or 'red'
    self.sprite=Asset.shockwave[self.color]
    self.canRemove=args.canRemove or {bullet=true,invincible=false,safe=true}
end

function Shockwave:update(dt)
    Shockwave.super.update(self,dt)

end

-- generating black smoke, boding a huge attack
local Charge=Effect:extend()
Effect.Charge=Charge
function Charge:new(args)
    if not args.x then
        args.x=args.obj.x
    end
    if not args.y then
        args.y=args.obj.y
    end
    Charge.super.new(self, args)
    self.obj=args.obj or self
    self.sprite=args.sprite or Asset.shards.round
    self.radius = args.radius or 1
    self.particleSpeed=args.particleSpeed or 1
    self.particleFrame=args.particleFrame or 40
    self.particleSize=args.particleSize or 5
    self.particles={}
    self.animationFrame=args.animationFrame or 120
    self.color=args.color or {1,1,1}
    SFX:play("enemyCharge",true)
end

function Charge:update(dt)
    self.frame=self.frame+1
    local direction=math.eval(0,999)
    if self.frame+self.particleFrame<self.animationFrame then
        table.insert(self.particles,{frame=0,x=self.obj.x,y=self.obj.y,direction=direction,speed=self.particleSpeed})
    end
    for k,particle in pairs(self.particles) do
        particle.frame=particle.frame+1
        if particle.frame>=self.particleFrame then
            goto continue
        end
        ::continue::
    end
    if self.frame==self.animationFrame then
        self:remove()
    end
end

function Charge:draw(dt)
    local size=self.sprite.data.size
    for k,particle in pairs(self.particles) do
        if particle.frame>=self.particleFrame then
            goto continue
        end
        local scale=self.particleSize*0.95^(self.particleFrame-particle.frame)
        particle.x,particle.y=Shape.rThetaPos(self.obj.x,self.obj.y,particle.speed*(-particle.frame+self.particleFrame),particle.direction)
        local x,y=particle.x,particle.y
        Asset.effectBatch:setColor(self.color[1],self.color[2],self.color[3],1-0.3*particle.frame/self.particleFrame)
        Asset.effectBatch:add(self.sprite.quad,x,y,0,scale,scale,size/2,size/2)
        ::continue::
    end
end

-- remove bullets in a rectangle area (like a laser)
local FlashBomb=Effect:extend()
Effect.FlashBomb=FlashBomb
function FlashBomb:new(args)
    FlashBomb.super.new(self, args)
    self.width=args.width or 10
    self.color=args.color or 'gray'
    self.sprite=BulletSprites.laser[self.color]
    self.canRemove=args.canRemove or {bullet=true,invincible=false}
end

function FlashBomb:draw()
    local ratio=self.frame/self.lifeFrame
    local tWidth=self.width*math.cos(ratio*math.pi/2)
    local xa,ya=math.rThetaPos(self.x,self.y,tWidth,self.direction+math.pi/2)
    local xb,yb=math.rThetaPos(self.x,self.y,tWidth,self.direction-math.pi/2)
    local x1,y1=math.rThetaPos(xa,ya,1500,self.direction)
    local x2,y2=math.rThetaPos(xb,yb,1500,self.direction)
    local x3,y3=math.rThetaPos(xb,yb,1500,self.direction+math.pi)
    local x4,y4=math.rThetaPos(xa,ya,1500,self.direction+math.pi)
    Laser.LaserUnit.drawMesh(self,{{x1,y1},{x4,y4},{x3,y3},{x2,y2}})
end

return Effect