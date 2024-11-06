local Shape = require "shape"
local Circle=require'circle'
local Event=require"event"

local Enemy=Shape:extend()

-- parameters: [maxhp], [hp] (defaulted as maxhp), [mainEnemy] if true, killing it wins the scene.
function Enemy:new(args)
    args.lifeFrame=99999999
    Enemy.super.new(self, args)
    self.maxhp=args.maxhp or args.hp or 1000
    self.hp=args.hp or self.maxhp
    self.radius=10
    -- if mainEnemy is defeated, win this scene
    self.mainEnemy=args.mainEnemy or false
    self.hpBarTransparency=1
end

function Enemy:update(dt)
    Enemy.super.update(self,dt)
    local player=Player.objects[1]
    if Shape.distance(player.x,player.y,self.x,self.y)<50 then
        self.hpBarTransparency=0.85*(self.hpBarTransparency-0.5)+0.5
    else
        self.hpBarTransparency=0.85*(self.hpBarTransparency-1)+1
    end
    for key, circ in pairs(Circle.objects) do
        if circ.fromPlayer and Shape.distance(circ.x,circ.y,self.x,self.y)<circ.radius+self.radius then
            self.hp=self.hp-(circ.damage or 1)
            circ:remove()
            SFX:play('damage')
            if self.hp<0 then
                SFX:play('kill')
                self:remove()
                if self.mainEnemy then
                    Effect.Shockwave{x=self.x,y=self.y,canRemove={bullet=true,bulletSpawner=true,invincible=true}}
                    Event.LoopEvent{
                        times=1,
                        period=60,
                        executeFunc=function(x)
                            G:win()
                        end
                    }
                end
            end
        end
    end
end

function Enemy:draw()
    local color={love.graphics.getColor()}
    love.graphics.setColor(0,1,1)
    Shape.drawCircle(self.x,self.y,self.radius)
    self:drawHPBar()
    love.graphics.setColor(color[1],color[2],color[3])
end

function Enemy:drawHPBar()
    local color={love.graphics.getColor()}
    love.graphics.setColor(1,0.3,0.3,self.hpBarTransparency)
    Shape.drawCircle(self.x,self.y,30.5)--inner circle
    Shape.drawCircle(self.x,self.y,32.5)--outer circle
    local ratio=self.hp/self.maxhp
    -- self.DrawArc(self.x,self.y,31,-math.pi/2,math.pi*(2*ratio-0.5),100)
    love.graphics.setColor(1,1,1,self.hpBarTransparency)
    for i=31,32,0.5 do
        self.DrawArc(self.x,self.y,i,math.pi*(1.5-2*ratio),math.pi*(1.5),100)
    end
    -- SetFont(12)
    -- love.graphics.print(""..ratio..', ', 10, 100)
    love.graphics.setColor(color[1],color[2],color[3])
end

-- love is really silly to not provide arc without lines toward center
-- but anyway to draw hyperbolic arc it's better to have my own func
-- (the one in polyline can only draw arc < pi. think about it, there is no way a 3/4 circle can be drawn with only 1 scissor)
function Enemy.DrawArc(x, y, r, s_ang, e_ang, numLines)
    -- SetFont(12)
    -- love.graphics.print(""..s_ang..', '..e_ang, 10, 150)
    local x2,y2,r2=Shape.getCircle(x,y,r)
    _,_,s_ang=Shape.rThetaPos(x,y,r,s_ang)
    _,_,e_ang=Shape.rThetaPos(x,y,r,e_ang)
    -- SetFont(12)
    -- love.graphics.print(""..s_ang..', '..e_ang, 10, 200)
	local step = ((e_ang-s_ang) / numLines)
	local ang1 = s_ang
	local ang2 = 0
	
	for i=1,numLines do
		ang2 = ang1 + step
		love.graphics.line(x2 + (math.cos(ang1) * r2), y2 + (math.sin(ang1) * r2),
			x2 + (math.cos(ang2) * r2), y2 + (math.sin(ang2) * r2))
		ang1 = ang2
	end

end

return Enemy