local Shape = require "shape"
local Circle=require'circle'
local Event=require"event"

local Enemy=Shape:extend()
Enemy.hpSegmentsFuncShockwave=function(self,hpLevel,canRemove)
    SFX:play('enemyCharge',true)
    Effect.Shockwave{x=self.x,y=self.y,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove=canRemove or {bullet=true,invincible=true}}
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
    self.showCircleHPBar=self.mainEnemy
    self.showHexagram=self.mainEnemy
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
    if not self.sprite then -- try find boss sprite based on levelData.user
        local level=G.UIDEF.CHOOSE_LEVELS.chosenLevel
        local scene=G.UIDEF.CHOOSE_LEVELS.chosenScene
        if level and scene and LevelData[level] and LevelData[level][scene] and LevelData[level][scene].user then
            local user=LevelData[level][scene].user
            if Asset.boss[user] then
                self.sprite=Asset.boss[user]
            else
                self.sprite=Asset.boss.placeholder
            end
        else
            self.sprite=Asset.boss.placeholder
        end
    end
    self.bindedEnemy=nil
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
    self:checkHitByPlayer(self.bindedEnemy)
    if self.bindedEnemy then
        self.hp=self.bindedEnemy.hp
        self.damageResistance=self.bindedEnemy.damageResistance
    end
    local hpLevel=self:getHPLevel()
    if self._hpLevel~=hpLevel then
        self.hpSegmentsFunc(self,self._hpLevel)
        self._hpLevel=hpLevel
    end
    self:calculateMovingTransitionSprite()
    self.orientation=Enemy.upwardDeltaOrientation(self.x,self.y)
end

--- make this enemy share hp and transfer damage with otherEnemy
function Enemy:bind(otherEnemy)
    self.bindedEnemy=otherEnemy
    self.maxhp=otherEnemy.maxhp
    self.hp=otherEnemy.hp
    self.hpSegments=otherEnemy.hpSegments
    self.showCircleHPBar=otherEnemy.showCircleHPBar
    self.showHexagram=otherEnemy.showHexagram
    if self.mainEnemy then
        error('Enemy:bind: mainEnemy cannot bind with other enemy')
    end
end

function Enemy:calculateMovingTransitionSprite()
    if not self.sprite then
        return
    end
    if self.sprite.key=='fairy' or self.sprite.key=='boss'then -- calculate whether enemy is moving left or right relative to player is kinda complex, so just use normal sprites
        local sprites=self.sprite.normal
        local t=self.time
        local index=math.floor(t/0.2)%#sprites+1
        self.currentSprite=sprites[index]
    end
end

-- to calculate to make the sprite upward, how much to rotate the sprite. calculation is similar to modelsTrans.glsl. basic idea is delta = - screen geodesic angle (different models) + world geodesic angle (Shape.to(x,y,viewObject.x,viewObject.y))
function Enemy.upwardDeltaOrientation(x,y)
    if G.viewMode.mode==G.CONSTANTS.VIEW_MODES.NORMAL then
        return 0
    end
    local obj=G.viewMode.object
    local xo,yo=obj.x,obj.y
    if xo==x and yo==y then
        return 0
    end
    local rotateAngle=obj.naturalDirection or 0
    local x1,y1=Shape.rotateAround(x,y,-rotateAngle,xo,yo)
    if G.viewMode.hyperbolicModel==G.CONSTANTS.HYPERBOLIC_MODELS.UHP then
        local deltaOrientation=-Shape.to(x1,y1,xo,yo)+Shape.to(x,y,xo,yo)
        return deltaOrientation
    end
    local screenx,screeny=Shape.screenPosition(x,y)
    local r=math.min(WINDOW_WIDTH,WINDOW_HEIGHT)/2*(G.DISK_RADIUS_BASE[G.viewMode.hyperbolicModel] or 1)
    local screenObjx,screenObjy=Shape.screenPosition(xo,yo)
    if G.viewMode.hyperbolicModel==G.CONSTANTS.HYPERBOLIC_MODELS.K_DISK then --geodesic is straight line
        return -math.atan2(screenObjy-screeny,screenObjx-screenx)+Shape.to(x,y,xo,yo)
    end
    -- poincare disk
    local wx,wy=(screenx-WINDOW_WIDTH/2)/r,(screeny-WINDOW_HEIGHT/2)/r
    local wox,woy=(screenObjx-WINDOW_WIDTH/2)/r,(screenObjy-WINDOW_HEIGHT/2)/r
    -- calculate direction from wx,wy to wox,woy along geodesic
    
    local start_mag_sq = wx * wx + wy * wy
    local epsilon = 1e-10

    -- CASE 1: The geodesic is a diameter of the disk.
    -- This occurs when the start point, end point, and the origin (0,0) are collinear.
    -- We check this using the 2D cross-product. If it's zero, they are collinear.
    local cross_product = wx * woy - wy * wox
    if math.abs(cross_product) < epsilon then
        -- The direction is simply the Euclidean vector from start to end.
        local dx = wox - wx
        local dy = woy - wy
        return -math.atan2(dy, dx) + Shape.to(x, y, xo, yo)
    end

    -- CASE 2: The geodesic is a circular arc orthogonal to the unit circle.
    -- We need to find the center of this circle. The circle passes through
    -- the start point P(wx, wy), the end point Q(wox, woy), and the inversion
    -- of the start point P* with respect to the unit circle.

    -- 1. Calculate the inversion of the start point P.
    local inv_wx = wx / start_mag_sq
    local inv_wy = wy / start_mag_sq

    -- 2. Find the center (cx, cy) of the circle passing through P, Q, and P*.
    -- This is the circumcenter of the triangle PQP*.
    local p = { x = wx, y = wy }
    local q = { x = wox, y = woy }
    local p_inv = { x = inv_wx, y = inv_wy }

    local p_sq = p.x^2 + p.y^2   -- This is just start_mag_sq
    local q_sq = q.x^2 + q.y^2   -- This is just end_mag_sq
    local p_inv_sq = p_inv.x^2 + p_inv.y^2

    local D = 2 * (p.x * (q.y - p_inv.y) + q.x * (p_inv.y - p.y) + p_inv.x * (p.y - q.y))

    local cx = (p_sq * (q.y - p_inv.y) + q_sq * (p_inv.y - p.y) + p_inv_sq * (p.y - q.y)) / D
    local cy = (p_sq * (p_inv.x - q.x) + q_sq * (p.x - p_inv.x) + p_inv_sq * (q.x - p.x)) / D

    -- 3. The tangent direction is perpendicular to the radius from the center (cx, cy)
    -- to the start point P(wx, wy).
    local radius_x = wx - cx
    local radius_y = wy - cy

    -- The two possible perpendicular tangent vectors are (-radius_y, radius_x) and (radius_y, -radius_x).
    local tangent_x = -radius_y
    local tangent_y = radius_x

    -- 4. Choose the correct tangent direction. The correct one will have a positive
    -- dot product with the vector from the start point to the end point (PQ).
    local pq_x = wox - wx
    local pq_y = woy - wy

    local dot_product = tangent_x * pq_x + tangent_y * pq_y
    if dot_product < 0 then
        -- We chose the wrong perpendicular vector, so we flip it.
        tangent_x = -tangent_x
        tangent_y = -tangent_y
    end

    return -math.atan2(tangent_y, tangent_x) + Shape.to(x, y, xo, yo)
end

function Enemy:drawSprite()
    local sprite=self.sprite
    if not sprite then
        return
    end
    if sprite.key=='fairy' then
        local x0,y0=self.x,self.y
        local orientation=0
        if G.UseHypRotShader then -- fairies should always face upwards (of screen). but inside different hyperbolic models, "upwards" is different. need a function to calculate the delta orientation
            orientation=self.orientation
        end
        local x,y,r=Shape.getCircle(x0,y0,self.drawRadius or 0.3)
        Asset.fairyBatch:add(self.currentSprite or sprite.normal[1],x,y,orientation,r,r,Asset.fairy.width/2,Asset.fairy.height/2)
    elseif sprite.key=='boss' then
        local x0,y0=self.x,self.y
        local orientation=0
        if G.UseHypRotShader then
            orientation=self.orientation
        end
        local offDistance=math.sin(self.time)*1 -- slightly floating
        x0,y0=Shape.rThetaPos(x0,y0,offDistance,orientation+math.pi/2)
        local mesh=Shape.fanMesh(x0,y0,(self.drawRadius or 0.6)*Asset.boss.width/2,orientation,self.currentSprite or sprite.normal[1],Asset.bossImage,16,{1,1,1,1},true) -- 16 is number of triangles
        Asset.bossMeshes:add(mesh)
        -- local x,y,r=Shape.getCircle(x0,y0,self.drawRadius or 0.6)
        -- Asset.bossMeshes:add(self.currentSprite or sprite.normal[1],x,y,orientation,r,r,Asset.boss.width/2,Asset.boss.height/2)
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
            -- hit visual effect. at bullet position
            Effect.Larger{x=circ.x,y=circ.y,speed=10+5*math.sin(self.x*51323.35131+self.y*46513.1333+self.frame*653.13),direction=9999*math.sin(self.x*513.35131+self.y*413.1333+self.frame*6553.13),sprite=Asset.shards.dot,radius=3,growSpeed=1,animationFrame=20,spriteTransparency=0.3}
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
    self.orientation=self.orientation or Enemy.upwardDeltaOrientation(self.x,self.y)
    if self.showHexagram then
        self:drawHexagram()
    end
    love.graphics.setColor(0,1,1)
    if not self.sprite then
        Shape.drawCircle(self.x,self.y,self.radius)
    end
    self:drawSprite()
    if not G.levelIsTimeoutSpellcard and self.showCircleHPBar then
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
    local vertices={}
    local angle0=self.orientation+math.pi*(1.5-2*ratio)
    local num=50
    local X,Y,W,H=love.graphics.getQuadXYWHOnImage(BulletSprites.laser.white.quad,Asset.bulletImage)
    for i=0,num do
        local angle=angle0+i/num*math.pi*2*ratio
        local x1,y1=Shape.rThetaPos(self.x,self.y,30.5,angle)
        local x2,y2=Shape.rThetaPos(self.x,self.y,32.5,angle)
        table.insert(vertices,{x1,y1,X,Y,1,1,1/yellowRatio,self.hpBarTransparency})
        table.insert(vertices,{x2,y2,X+W,Y,1,1,1/yellowRatio,self.hpBarTransparency})
    end
    if not self.circleHPBarMesh then
        self.circleHPBarMesh=love.graphics.newMesh(vertices,'strip')
        self.circleHPBarMesh:setTexture(Asset.bulletImage)
    else
        self.circleHPBarMesh:setVertices(vertices)
    end
    Asset.laserMeshes:add(self.circleHPBarMesh)
    -- love.graphics.setColor(1,0.3,0.3,self.hpBarTransparency)
    for i,ratio in pairs(self.hpSegments) do
        local rin,rout=29.5,33.5
        local x1,y1=Shape.rThetaPos(self.x,self.y,rin,self.orientation+math.pi*(1.5-2*ratio))
        local x2,y2=Shape.rThetaPos(self.x,self.y,rout,self.orientation+math.pi*(1.5-2*ratio))
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
        Shape.drawSegment(x1,y1,x2,y2,1)
        Shape.drawSegment(x3,y3,x2,y2,1)
    end
    love.graphics.setLineWidth(width)
    love.graphics.setColor(color[1],color[2],color[3])
end

return Enemy