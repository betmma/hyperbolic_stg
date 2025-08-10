local Shape = require "shape"
local Circle=require'circle'
local Event=require"event"

local Enemy=Shape:extend()
Enemy.hpSegmentsFuncShockwave=function(self,hpLevel)
    SFX:play('enemyCharge',true)
    Effect.Shockwave{x=self.x,y=self.y,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove={bullet=true,invincible=true}}
end

-- parameters: [maxhp], [hp] (defaulted as maxhp), [mainEnemy] if true, killing it wins the scene. [hpSegments] a table of hp levels that triggers special effects. [hpSegmentsFunc] a function that triggers special effects when hp reaches a certain level. note that the hpLevel parameter passed to hpSegmentsFunc is 1-based. (hplevel 1->2 sends 1)
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
    -- safe means enemy's body (circle) won't hit player, similar to circle.safe
    self.safe=false
    self.hpBarTransparency=1
    self.hpSegments=args.hpSegments or {} -- draw a small bar marking special hp values. These are only visual effects. If you want a shockwave removing bullets when reaching special values, you need to do it manually.
    table.sort(self.hpSegments,function (a,b) return a>b end) -- we want it decreasing
    self.hpSegmentsFunc=args.hpSegmentsFunc or function(self,hpLevel)end 
    self.damageResistance=1
    self._hpLevel=self:getHPLevel()
    self.sprite=args.sprite
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
    local hpLevel=self:getHPLevel()
    if self._hpLevel~=hpLevel then
        self.hpSegmentsFunc(self,self._hpLevel)
        self._hpLevel=hpLevel
    end
    self:calculateMovingTransitionSprite()
end

function Enemy:calculateMovingTransitionSprite()
    if not self.sprite then
        return
    end
    if self.sprite.key=='fairy' then -- calculate whether enemy is moving left or right relative to player is kinda complex, so just use normal sprites
        local sprites=self.sprite.normal
        local t=self.time
        local index=math.floor(t/0.2)%#sprites+1
        self.currentSprite=sprites[index]
    end
end

function Enemy:drawSprite()
    local sprite=self.sprite
    if not sprite then
        return
    end
    if sprite.key=='fairy' then
        local x0,y0=self.x,self.y
        local orientation=0
        if G.UseHypRotShader then -- ideally fairies should always face upwards (of screen). but inside different hyperbolic models, "upwards" is different. for UHP it can be calculated using difference of direction after "rotate" in player.testRotate (which won't be called when using UseHypRotShader so extra work). omit for now
        
        end
        local x,y,r=Shape.getCircle(x0,y0,self.drawRadius or 0.3)
        Asset.fairyBatch:add(self.currentSprite or sprite.normal[1],x,y,orientation,r,r,Asset.fairy.width/2,Asset.fairy.height/2)
    end
end

-- get the hp level of the enemy. Useful with hpSegments set. e.g. if hpSegments={0.8,0.5,0.2}, getHPLevel() returns 1 if hp/maxhp is in [0.8,1], 2 if in [0.5,0.8), 3 if in [0.2,0.5), 4 if in [0,0.2).
function Enemy:getHPLevel()
    local hpp=self.hp/self.maxhp
    for i=1,#self.hpSegments do
        if hpp>=self.hpSegments[i] then
            return i
        end
    end
    return #self.hpSegments+1
end

-- get the ratio of hp in the current level. e.g. if hpSegments={0.8,0.5,0.2}, getHPPercentOfCurrentLevel() returns 0.5 if hp/maxhp is 0.9 (half of the way from 0.8 to 1), 0.65 (half of the way from 0.5 to 0.8), 0.35 (half of the way from 0.2 to 0.5), and 0.1 (half of the way from 0 to 0.2).
function Enemy:getHPPercentOfCurrentLevel()
    local hpp=self.hp/self.maxhp
    local hpLevel=self:getHPLevel()
    if hpLevel>#self.hpSegments then
        return hpp/self.hpSegments[hpLevel-1]
    elseif hpLevel==1 then
        return (hpp-self.hpSegments[hpLevel])/(1-self.hpSegments[hpLevel])
    else
        return (hpp-self.hpSegments[hpLevel])/(self.hpSegments[hpLevel-1]-self.hpSegments[hpLevel])
    end
end

-- increase enemy's damageResistance by [value] and fade out in [time] frames
-- to prevent player from killing the enemy too quickly
function Enemy:addHPProtection(time,value)
    self.damageResistance=(self.damageResistance or 1)+value
    Event.EaseEvent{
        obj=self,
        easeFrame=time,
        aimTable=self,
        aimKey='damageResistance',
        aimValue=self.damageResistance-value,
    }
end

-- objToReduceHp is to allow familiars to take damage for the enemy
function Enemy:checkHitByPlayer(objToReduceHp,damageFactor)
    objToReduceHp=objToReduceHp or self
    damageFactor=damageFactor or 1
    for key, circ in pairs(Circle.objects) do
        if circ.fromPlayer and Shape.distance(circ.x,circ.y,self.x,self.y)<circ.radius+self.radius then
            objToReduceHp.hp=objToReduceHp.hp-(circ.damage or 1)*damageFactor/(objToReduceHp.damageResistance or 1)
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
    SFX:play('kill',true)
    self:remove()
    if self.mainEnemy then
        local levelID=G.UIDEF.CHOOSE_LEVELS.levelID
        if not G.replay then
            ScreenshotManager.preSave(levelID)
        end
        Effect.Shockwave{x=self.x,y=self.y,canRemove={bullet=true,bulletSpawner=true,invincible=true}}
        G.preWin=true
        Event.LoopEvent{
            times=1,
            period=60,
            executeFunc=function(x)
                local levelID=G.UIDEF.CHOOSE_LEVELS.levelID
                if not G.replay then
                    ScreenshotManager.save(levelID)
                end
                G:win()
            end
        }
    end
end

function Enemy:draw()
    local shader=love.graphics.getShader()
    local color={love.graphics.getColor()}
    if self.mainEnemy then
        self:drawHexagram()
    end
    love.graphics.setColor(0,1,1)
    if not self.sprite then
        Shape.drawCircle(self.x,self.y,self.radius)
    end
    self:drawSprite()
    if not G.levelIsTimeoutSpellcard and self.mainEnemy then 
        self:drawCircleHPBar()
    end
    love.graphics.setColor(color[1],color[2],color[3])
    love.graphics.setShader(shader)
end

function Enemy:drawText()
    if self.showUpperHPBar and not G.levelIsTimeoutSpellcard then
        self:drawUpperHPBar()
    end
end

-- an HP bar around enemy (like DDC)
function Enemy:drawCircleHPBar()
    local color={love.graphics.getColor()}
    love.graphics.setColor(1,0.3,0.3,self.hpBarTransparency)
    Shape.drawCircle(self.x,self.y,30.5)--inner circle
    Shape.drawCircle(self.x,self.y,32.5)--outer circle
    local ratio=self.hp/self.maxhp
    local yellowRatio=(self.damageResistance or 1)^0.5
    love.graphics.setColor(1,1,1/yellowRatio,self.hpBarTransparency)
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

-- an HP bar at top of screen (like UFO)
function Enemy:drawUpperHPBar()
    local color={love.graphics.getColor()}
    local ratio=self.hp/self.maxhp
    local yellowRatio=(self.damageResistance or 1)^0.5
    local beginX=150+5
    local width=490
    local last=0
    local num=#self.hpSegments
    local hpLevel=self:getHPLevel()
    for i=num,hpLevel,-1 do -- increasing order of hpSegments. hpLevel is the last full part of the bar and drawn as grey
        local ratio=self.hpSegments[i]
        love.graphics.setColor(0.5,0.5,0.5,0.7)
        love.graphics.rectangle('fill',beginX+width*last,1,width*(ratio-last),3)
        last=ratio
        love.graphics.setColor(1,0.3,0.3,1)
        love.graphics.rectangle('fill',beginX+width*ratio,0,3,5) -- a red mark on segment point
    end
    love.graphics.setColor(1,1,1/yellowRatio,0.7)
    love.graphics.rectangle('fill',beginX+width*last,1,width*(ratio-last),3)
    love.graphics.setColor(color[1],color[2],color[3])
end

-- due to hyperbolic geometry, it's not feasible to prepare an image for rotating hexagram
function Enemy:drawHexagram()
    local color={love.graphics.getColor()}
    love.graphics.setColor(0.5,0.1,0.1)
    local width=love.graphics.getLineWidth()
    love.graphics.setLineWidth(2)
    local points={}
    local theta=self.time*3/5
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
    love.graphics.setLineWidth(width)
    love.graphics.setColor(color[1],color[2],color[3])
end

return Enemy