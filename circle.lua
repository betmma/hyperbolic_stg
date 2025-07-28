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
    self.radius = args.radius or 1
    ---@type Sprite
    self.sprite=args.sprite
    if self.sprite then
        local data=self.sprite.data
        if not data then
            error('Circle:new: self.sprite.data is nil')
        end
        if data.isGIF then
            self.sprite=copy_table(self.sprite)
            self.sprite:randomizeCurrentFrame()
        end
        self.radius=self.radius/Circle.sizeFactor*data.hitRadius
    end
    self.extraUpdate=args.extraUpdate or {}
    -- safe means won't hit player 
    self.safe=args.safe or false
    -- fromPlayer means can hit enemy
    self.fromPlayer=args.fromPlayer or false
    -- invincible means won't be removed by normal shockwave (win shockwave can)
    self.invincible=args.invincible or false

    self.grazed=args.grazed or false

    self.batch=args.batch or (args.highlight and Asset.bulletHighlightBatch or BulletBatch)
    self.spriteTransparency=args.spriteTransparency or 1

    self.spriteExtraDirection=0
    self.spriteRotationSpeed=0 -- used for nuke bullet

    if self.sprite.data.key=='note' then
        self.spriteExtraDirection=math.pi -- note sprites are rotated 180 degrees
    end
    if self.sprite==BulletSprites.nuke then
        self.invincible=true
        self.batch=Asset.bulletHighlightBatch
        self.spriteRotationSpeed=0.01
    end
end

function Circle:draw()
    -- if G.screenRect.xmin<self.x and self.x<G.screenRect.xmax and G.screenRect.ymin<self.y and self.y<G.screenRect.ymax then -- view port cull test, but doesn't improve performance (and large bullets are wrongly culled)
    --     if self.sprite then
    --         self:drawSprite()
    --     end
    -- end
    if not self.sprite then
        return
    end
    local radius=self.radius
    if radius<5 and not self.forceDrawLargeSprite then
        self:drawSprite()
    else
        self:drawLargeSprite()
    end
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
    Shape.update(self,dt)
    if #Effect.Shockwave.objects>0 then self:checkShockwaveRemove() end
    if #Effect.FlashBomb.objects>0 then self:checkFlashBombRemove() end
    self:checkHitPlayer()
    self.spriteExtraDirection=self.spriteExtraDirection+self.spriteRotationSpeed*Shape.timeSpeed
    if self.sprite then
        local data=self.sprite.data
        if data.isGIF then
            self.sprite:countDown()
        end
    end
end

-- this happens in draw.
function Circle:drawSprite()
    local color={love.graphics.getColor()}
    local x,y,radius=Shape.getCircle(self.x,self.y,self.radius)
    local data=self.sprite.data
    local scale=radius/data.hitRadius*Circle.spriteSizeFactor
    local r,g,b
    if self.spriteColor then
        r,g,b=self.spriteColor[1],self.spriteColor[2],self.spriteColor[3]
    end
    self.batch:setColor(r or 1,g or 1,b or 1,(self.spriteTransparency or 1)*color[4])
    self.batch:add(self.sprite.quad,x,y,self.direction+math.pi/2+(self.spriteExtraDirection or 0),scale,scale,data.centerX,data.centerY)
end

-- for large sprites, normal quad (2 triangles) will cause huge distortion, so we use mesh (fan triangles)
---@param num integer|nil number of vertices on the circle
function Circle:drawLargeSprite(num)
    num=num or math.ceil(math.clamp(self.radius,6,32))
    local x,y,w,h=self.sprite.quad:getViewport() -- like 100, 100, 50, 50 so needs to divide width and height
    local W,H=Asset.bulletImage:getWidth(),Asset.bulletImage:getHeight()
    x,y,w,h=x/W,y/H,w/W,h/H
    local meshVertices={{self.x,self.y,x+w/2,y+h/2, 1, 1, 1, 1}} -- center point
    local r=self.radius*Circle.spriteSizeFactor*1.41
    local direction=self.direction+math.pi/2+(self.spriteExtraDirection or 0)
    for i=0,num-1 do
        local angle=i/num*math.pi*2
        local nx,ny=Shape.rThetaPos(self.x,self.y,r,direction+angle)
        table.insert(meshVertices,{nx,ny,x+w/2*(1+math.cos(angle)),y+h/2*(1+math.sin(angle)), 1, 1, 1, 1})
    end
    table.insert(meshVertices,meshVertices[2]) -- close the fan
    local mesh=love.graphics.newMesh(meshVertices,'fan')
    mesh:setTexture(Asset.bulletImage)
    table.insert(Asset.bigBulletMeshes,mesh)
end

function Circle:checkShockwaveRemove()
    if not self.safe then 
        for k,shockwave in pairs(Effect.Shockwave.objects) do
            if shockwave.canRemove.bullet==true and(self.invincible==false or shockwave.canRemove.invincible==true)and(self.safe==false or shockwave.canRemove.safe==true) and Shape.distance(shockwave.x,shockwave.y,self.x,self.y)<shockwave.radius+self.radius then
                self:remove()
                self:removeEffect()
            end
        end
    end
end
function Circle:checkFlashBombRemove()
    if not self.safe then
        for k,flashBomb in pairs(Effect.FlashBomb.objects) do
            if flashBomb.canRemove.bullet==true and(self.invincible==false or flashBomb.canRemove.invincible==true) and flashBomb:inside(self.x,self.y) then
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
                EventManager.post('playerGraze',player,(self.lifeFrame<3 or self.frame<3) and 0.05 or 1)
                self.grazed=true
            end
            if player.invincibleTime<=0 and dis<radi then
                EventManager.post('playerHit',player,self.damage or 1)
            end
        end
    end
end

function Circle:removeEffect()
    Effect.Larger{x=self.x,y=self.y,sprite=Asset.shards.dot,radius=1,growSpeed=1.05,animationFrame=20}
end

function Circle:changeSpriteColor(color)
    if not color then
        local colors=self.sprite.data.possibleColors
        if not colors then
            return
        end
        local ind=math.floor(math.random(1,#colors+0.999999))
        color=colors[ind]
    end
    self.sprite=BulletSprites[self.sprite.data.key][color] or self.sprite
end

-- you shouldn't directly change self.sprite, cuz radius won't update (same as how Kanako's 神穀 spellcard has larger hitbox)
function Circle:changeSprite(sprite)
    local data=self.sprite.data
    self.radius=self.radius/data.hitRadius
    self.sprite=sprite
    data=self.sprite.data
    self.radius=self.radius*data.hitRadius
    if data.isGIF then
        self.sprite=copy_table(self.sprite)
        self.sprite:randomizeCurrentFrame()
    end
end

return Circle