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
    if self.mainEnemy then
        G.mainEnemy=self
    end
    self.hpBarTransparency=1
    self.hpSegments=args.hpSegments or {}
end

function Enemy:update(dt)
    Enemy.super.update(self,dt)
    local player=Player.objects[1]
    if player and Shape.distance(player.x,player.y,self.x,self.y)<50 then
        self.hpBarTransparency=0.85*(self.hpBarTransparency-0.5)+0.5
    else
        self.hpBarTransparency=0.85*(self.hpBarTransparency-1)+1
    end
    Circle.checkHitPlayer(self)
    self:checkHitByPlayer()
end

-- objToReduceHp is to allow familiars to take damage for the enemy
function Enemy:checkHitByPlayer(objToReduceHp,damageFactor)
    objToReduceHp=objToReduceHp or self
    damageFactor=damageFactor or 1
    for key, circ in pairs(Circle.objects) do
        if circ.fromPlayer and Shape.distance(circ.x,circ.y,self.x,self.y)<circ.radius+self.radius then
            objToReduceHp.hp=objToReduceHp.hp-(circ.damage or 1)*damageFactor
            circ:remove()
            SFX:play('damage')
            -- if self.hp<self.maxhp*0.01 and self.mainEnemy and not self.presaved then
            --     self.presaved=true
            -- end
            if objToReduceHp.hp<0 and not objToReduceHp.removed then
                objToReduceHp:dieEffect()
            end
        end
    end
end

function Enemy:dieEffect()
    SFX:play('kill')
    self:remove()
    if self.mainEnemy then
        local level=G.UIDEF.CHOOSE_LEVELS.chosenLevel
        local scene=G.UIDEF.CHOOSE_LEVELS.chosenScene
        if not G.replay then
            ScreenshotManager.preSave(level,scene)
        end
        Effect.Shockwave{x=self.x,y=self.y,canRemove={bullet=true,bulletSpawner=true,invincible=true}}
        Event.LoopEvent{
            times=1,
            period=60,
            executeFunc=function(x)
                local level=G.UIDEF.CHOOSE_LEVELS.chosenLevel
                local scene=G.UIDEF.CHOOSE_LEVELS.chosenScene
                if not G.replay then
                    ScreenshotManager.save(level,scene)
                end
                G:win()
            end
        }
    end
end

function Enemy:draw()
    local color={love.graphics.getColor()}
    if self.mainEnemy then
        self:drawHexagram()
    end
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
        Shape.drawArc(self.x,self.y,i,math.pi*(1.5-2*ratio),math.pi*(1.5),100)
    end
    -- love.graphics.setColor(1,0.3,0.3,self.hpBarTransparency)
    for i,ratio in pairs(self.hpSegments) do
        local rin,rout=29.5,33.5
        local x1,y1=Shape.rThetaPos(self.x,self.y,rin,math.pi*(1.5-2*ratio))
        local x2,y2=Shape.rThetaPos(self.x,self.y,rout,math.pi*(1.5-2*ratio))
        Shape.drawSegment(x1,y1,x2,y2)
    end
    -- SetFont(12)
    -- love.graphics.print(""..ratio..', ', 10, 100)
    love.graphics.setColor(color[1],color[2],color[3])
end

-- due to hyperbolic geometry, it's not feasible to prepare an image for rotating hexagram
function Enemy:drawHexagram()
    local color={love.graphics.getColor()}
    love.graphics.setColor(0.5,0.1,0.1)
    local points={}
    local theta=self.frame/100
    local rIN=40
    local rOUT=45
    for i=1,6 do
        local alpha=theta+math.pi*2/6*(i-1)
        local nx,ny=Shape.rThetaPos(self.x,self.y,rIN,alpha)
        local newpoint={nx,ny}
        points[#points+1]=newpoint
    end
    for i=1,#points do
        Shape.drawSegment(points[i][1],points[i][2],points[(i+1)%#points+1][1],points[(i+1)%#points+1][2])
    end
    Shape.drawCircle(self.x,self.y,rIN)
    Shape.drawCircle(self.x,self.y,rOUT)

    -- draw miniatures between the two circles
    local rM=(rIN+rOUT)/2
    local dM=(rM-rIN)/2
    local dtheta=0.03
    for i=1,12 do
        local alpha=theta+math.pi*2/12*(i-0.5)
        local x1,y1=Shape.rThetaPos(self.x,self.y,rM+dM*math.sin(theta*2.167+i*3.16),alpha+dtheta*math.sin(theta*1.943+5632+i*63.3))
        local x2,y2=Shape.rThetaPos(self.x,self.y,rM+dM*math.sin(theta*1.469+i*9.4),alpha+dtheta*(math.sin(theta*2.136+562+i*7.74))+0.03)
        local x3,y3=Shape.rThetaPos(self.x,self.y,rM+dM*math.sin(theta*2.463+i*13.3),alpha+dtheta*(math.sin(theta*1.796+1592+i*29.1))+0.06)
        Shape.drawSegment(x1,y1,x2,y2)
        Shape.drawSegment(x3,y3,x2,y2)
    end

    love.graphics.setColor(color[1],color[2],color[3])
end

return Enemy