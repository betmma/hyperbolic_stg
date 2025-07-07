
local Shape = require "shape"
local Circle=require"circle"
local PolyLine=require"polyline"
---@class Effect:Shape
local Effect = Shape:extend()

function Effect:new(args)
    Effect.super.new(self, args)
end

-- something keep growing and reducing opacity
---@class Larger:Effect
local Larger=Effect:extend()
Effect.Larger=Larger
function Larger:new(args)
    Larger.super.new(self, args)
    ---@type Sprite
    self.sprite=args.sprite
    if not self.sprite then
        error('Larger.new: self.sprite is nil. args='..pprint(args))
    end
    if not self.sprite.data then
        error('Larger.new: self.sprite.data is nil. sprite='..pprint(self.sprite))
    end
    self.radius = args.radius or 1
    self.growSpeed=args.growSpeed or 1.2
    self.drawScale=args.drawScale or 1
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
    local data=self.sprite.data
    local size=self.sprite.data.sizeX
    local scale=r/size*2*(self.drawScale or 1)
    local direction=self.direction or 0
    Asset.effectBatch:setColor(1,1,1,1-self.frame/self.animationFrame)
    Asset.effectBatch:add(self.sprite.quad,x,y,direction,scale,scale,data.centerX,data.centerY)
end

-- A growing shockwave, that removes touched bullets and activate their :removeEffect
local Shockwave=Larger:extend()
Effect.Shockwave=Shockwave
function Shockwave:new(args)
    self.color=args.color or 'red'
    args.sprite=Asset.bulletSprites.explosion[self.color] or Asset.bulletSprites.explosion.red
    Shockwave.super.new(self, args)
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
    local data=self.sprite.data
    local size=self.sprite.data.sizeX
    local _,_,r=Shape.getCircle(self.obj.x,self.obj.y,self.radius)
    for k,particle in pairs(self.particles) do
        if particle.frame>=self.particleFrame then
            goto continue
        end
        local scale=self.particleSize*0.95^(self.particleFrame-particle.frame)*(r/3)
        particle.x,particle.y=Shape.rThetaPos(self.obj.x,self.obj.y,particle.speed*(-particle.frame+self.particleFrame),particle.direction)
        local x,y=particle.x,particle.y
        Asset.effectBatch:setColor(self.color[1],self.color[2],self.color[3],1-0.3*particle.frame/self.particleFrame)
        Asset.effectBatch:add(self.sprite.quad,x,y,0,scale,scale,data.centerX,data.centerY)
        ::continue::
    end
end

-- remove bullets in a rectangle area (like a laser)
local FlashBomb=Effect:extend()
Effect.FlashBomb=FlashBomb
function FlashBomb:new(args)
    args.lifeFrame=args.lifeFrame or 60
    FlashBomb.super.new(self, args)
    self.radiusFunction=args.radiusFunction or function(ratio) return 200*math.min(ratio*10,10/9*(1-ratio)) end
    self.radius=args.radius or 0.1
    self.sideNum=args.sideNum or 3
    self.color=args.color or 'black'
    self.sprite=BulletSprites.laserDark[self.color]
    self.canRemove=args.canRemove or {bullet=true,invincible=false}
    self.points=Shape.regularPolygonCoordinates(self.x,self.y,self.radius,self.sideNum,self.direction,true)
end

function FlashBomb:update(dt)
    FlashBomb.super.update(self,dt)
    local ratio=self.frame/self.lifeFrame
    self.radius=math.max(self.radiusFunction(ratio),0.1) -- negative radius will cause points order reversed and remove all bullets
    self.points=Shape.regularPolygonCoordinates(self.x,self.y,self.radius,self.sideNum,self.direction,true)
end

FlashBomb.insideOne=PolyLine.insideOne
FlashBomb.inside=PolyLine.inside

function FlashBomb:draw()
    local points=self.points
    local x,y,w,h=self.sprite.quad:getViewport() -- like 100, 100, 50, 50 so needs to divide width and height
    local W,H=Asset.bulletImage:getWidth(),Asset.bulletImage:getHeight()
    x,y,w,h=x/W,y/H,w/W,h/H
    local meshVertices={{self.x,self.y,x+w,y, 1, 1, 1, 1}} -- center point
    for i=1,#points do
        local x1,y1,x2,y2=points[i].x,points[i].y,points[i%#points+1].x,points[i%#points+1].y
        local verts=Shape.segmentPoints(x1,y1,x2,y2,10,30)
        for j=1,#verts do
            local xj,yj=verts[j].x,verts[j].y
            table.insert(meshVertices, {xj, yj, x, y+(j%2==1 and 0 or h), 1, 1, 1, 1})
        end
    end
    if #meshVertices<4 then return end
    local mesh=love.graphics.newMesh(meshVertices,'fan')
    mesh:setTexture(Asset.bulletImage)
    table.insert(Asset.laserBatch,mesh)
end

return Effect