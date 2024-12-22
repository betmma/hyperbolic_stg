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
                SFX:play('kill')
                objToReduceHp:remove()
                if objToReduceHp.mainEnemy then
                    local level=G.UIDEF.CHOOSE_LEVELS.chosenLevel
                    local scene=G.UIDEF.CHOOSE_LEVELS.chosenScene
                    if not G.replay then
                        ScreenshotManager.preSave(level,scene)
                    end
                    Effect.Shockwave{x=objToReduceHp.x,y=objToReduceHp.y,canRemove={bullet=true,bulletSpawner=true,invincible=true}}
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
        end
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
    love.graphics.setColor(color[1],color[2],color[3])
end

return Enemy