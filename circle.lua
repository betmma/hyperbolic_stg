--! file: circle.lua
local Shape = require "shape"
local Circle = Shape:extend()
function Circle.restore()
    Circle.sizeFactor=5.0
    Circle.spriteSizeFactor=1.1
end
Circle.restore()

function Circle:new(args)
    Circle.super.new(self, args)
    --A circle doesn't have a width or height. It has a radius.
    self.radius = args.radius or 1
    self.sprite=args.sprite
    if self.sprite then
        local data=SpriteData[self.sprite]
        self.radius=self.radius/Circle.sizeFactor*data.hitRadius
    end
    self.extraUpdate={}
    -- safe means won't hit player 
    self.safe=args.safe or false
    -- fromPlayer means can hit enemy
    self.fromPlayer=args.fromPlayer or false
    -- invincible means won't be removed by normal shockwave (not win shockwave)
    self.invincible=args.invincible or false

    self.batch=args.batch or BulletBatch
    self.sprite_transparency=args.sprite_transparency or 1

    self.spriteExtraDirection=0
    self.spriteRotationSpeed=0

    if self.sprite==Asset.nuke then
        self.invincible=true
        self.batch=Asset.bulletHighlightBatch
        self.spriteRotationSpeed=0.01
    end
end

function Circle:draw()
    self:drawSprite()
    -- Formula: center (x,y) and radius r should be drawn as center (x,y*cosh(r)) and radius y*sinh(r)
    -- Shape.drawCircle(self.x,self.y,self.radius)
    -- love.graphics.circle("line", self.x, self.y, 1) -- center point
end


function Circle:update(dt)
    if self.removed then
        return
    end
    for k, func in pairs(self.extraUpdate or {}) do
        func(self,dt)
    end
    Circle.super.update(self,dt)
    self:checkShockwaveRemove()
    self:checkFlashBombRemove()
    self:checkHitPlayer()
    self.spriteExtraDirection=self.spriteExtraDirection+self.spriteRotationSpeed*Shape.timeSpeed
end

-- this happens in draw.
function Circle:drawSprite()
    local x,y,r=Shape.getCircle(self.x,self.y,self.radius)
    local data=SpriteData[self.sprite]
    local scale=r/data.hitRadius*Circle.spriteSizeFactor
    if self.sprite then
        if data.forcedColor then
            self.batch:setColor(data.forcedColor[1],data.forcedColor[2],data.forcedColor[3],self.sprite_transparency)
        else
            self.batch:setColor(1,1,1,self.sprite_transparency)
        end
        self.batch:add(self.sprite,x,y,self.direction+math.pi/2+self.spriteExtraDirection,scale,scale,data.size/2,data.size/2)
    end
end
function Circle:checkShockwaveRemove()
    if not self.fromPlayer then 
        for k,shockwave in pairs(Effect.Shockwave.objects) do
            if shockwave.canRemove.bullet==true and(self.invincible==false or shockwave.canRemove.invincible==true) and Shape.distance(shockwave.x,shockwave.y,self.x,self.y)<shockwave.radius+self.radius then
                self:remove()
                self:removeEffect()
            end
        end
    end
end
function Circle:checkFlashBombRemove()
    if not self.safe then 
        for k,flashBomb in pairs(Effect.FlashBomb.objects) do
            local nx,ny=math.rThetaPos(flashBomb.x,flashBomb.y,10,flashBomb.direction)-- get another point on the straight line
            if flashBomb.canRemove.bullet==true and(self.invincible==false or flashBomb.canRemove.invincible==true) and math.pointToLineDistance(self.x,self.y,flashBomb.x,flashBomb.y,nx,ny)<flashBomb.width+self.radius then
                self:remove()
                self:removeEffect()
            end
        end
    end
end
function Circle:checkHitPlayer()
    if not self.safe then 
        for key, player in pairs(Player.objects) do
            local dis=Shape.distance(player.x,player.y,self.x,self.y)
            local radi=player.radius+self.radius
            if dis<radi+player.radius*player.grazeRadiusFactor and not self.grazed then
                player:grazeEffect((self.lifeFrame<3 or self.frame<3) and 0.25 or 1)
                self.grazed=true
            end
            if player.invincibleTime<=0 and dis<radi then
                player:dieEffect(self.damage or 1)
            end
        end
    end
end

function Circle:removeEffect()
    Effect.Larger{x=self.x,y=self.y,sprite=Asset.shards.round,radius=5,growSpeed=1.1,animationFrame=20}
end

function Circle:changeSpriteColor(color)
    if not color then
        local colors=Asset.SpriteData[self.sprite].possibleColors
        local ind=math.floor(math.random(1,#colors+0.999999))
        color=colors[ind]
    end
    self.sprite=Asset.SpriteData[self.sprite].super[color] or self.sprite
end

function Circle:changeSprite(sprite)
    local data=SpriteData[self.sprite]
    self.radius=self.radius/data.hitRadius
    self.sprite=sprite
    data=SpriteData[self.sprite]
    self.radius=self.radius*data.hitRadius
end

return Circle