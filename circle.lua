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
        self.radius=self.radius/4.5*data.hitRadius
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
end

-- draw nothing as the actual thing drawn is its sprite
function Circle:draw()
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
    self.super.update(self,dt)
    local x,y,r=Shape.getCircle(self.x,self.y,self.radius)
    local data=SpriteData[self.sprite]
    local scale=r/data.hitRadius
    if self.sprite then
        self.batch:setColor(1,1,1,self.sprite_transparency)
        self.batch:add(self.sprite,x,y,self.direction+math.pi/2,scale,scale,data.size/2,data.size/2)
    end
    if not self.safe then 
        for k,shockwave in pairs(Effect.Shockwave.objects) do
            if shockwave.canRemove.bullet and(self.invincible==false or shockwave.canRemove.invincible) and Shape.distance(shockwave.x,shockwave.y,self.x,self.y)<shockwave.radius+self.radius then
                self:remove()
                self:removeEffect()
            end
        end
        for key, player in pairs(Player.objects) do
            local dis=Shape.distance(player.x,player.y,self.x,self.y)
            local radi=player.radius+self.radius
            if dis<radi+player.radius*1.5 and not self.grazed then
                player:grazeEffect()
                self.grazed=true
            end
            if player.invincibleTime<=0 and dis<radi then
                player.hp=player.hp-1
                player.invincibleTime=player.invincibleTime+1
                if player.hp<=0 then
                    G:lose()
                end
                Effect.Shockwave{x=player.x,y=player.y,radius=3,growSpeed=1.1,animationFrame=30}
            end
        end

    end
end

function Circle:removeEffect()
    Effect.Larger{x=self.x,y=self.y,sprite=Asset.shards.round,radius=5,growSpeed=1.1,animationFrame=20}
end
return Circle