
local Shape = require "shape"
local Circle=require"circle"
local PolyLine=require"polyline"
local BackgroundPattern = require "backgroundPattern"
local invertShader = love.graphics.newShader("shaders/circleInvert.glsl")
local Player = Shape:extend()
Player.moveModes={
    -- North Pole (player.x, Shape.axisY). Move directions are same as Polar Coordinate System in Euclid space, that is Up / Down -> close to / away from pole. Left / Right -> along the arc centered at North Pole.
    -- Up & Down: not in hyperbolic line.
    -- Left & Right: in hyperbolic line.
    -- Orthogonality: True.
    Monopolar='Monopolar',
    -- North Pole (player.x, Shape.axisY), East Pole (+∞, player.y). Up / Down -> only change y coordinate. Left / Right -> same as Monopolar, along the arc.
    -- Up & Down: in hyperbolic line.
    -- Left & Right: in hyperbolic line.
    -- Orthogonality: False.
    Bipolar='Bipolar',

    Euclid='Euclid',

    Natural='Natural'
}
Player.shootRows={
    front={
        straight={
            num=4,
            damage=3,
            sprite=BulletSprites.darkdot.cyan
        },
        homing={
            num=0,
            damage=3,
            sprite=BulletSprites.darkdot.red
        }
    },
    side={
        straight={
            num=0,
            damage=3,
            sprite=BulletSprites.darkdot.blue
        }
    },
    back={
        straight={
            num=0,
            damage=6,
            sprite=BulletSprites.darkdot.purple
        }
    }
}
function Player:new(args)
    Player.super.new(self, {x=args.x, y=args.y})
    self.direction=0
    self.naturalDirection=0
    self.lifeFrame=9999999
    self.speed=0
    self.movespeed=args.movespeed or 60
    self.focusFactor=0.4444
    self.centerX=400
    self.radius = 0.5
    self.drawRadius=0.5
    local minx=150
    local maxx=650
    local miny=0
    local maxy=540
    
    if args.noBorder then
        self.border=nil
    else
        self.border=PolyLine({{minx,miny},{maxx,miny},{maxx,maxy},{minx,maxy}})
    end

    self.maxhp=3
    self.hp=self.maxhp
    self.hpRegen=0
    self.grazeHpRegen=0
    self.grazeCount=0
    self.hurt=false --to check perfect completion
    self.invincibleTime=0
    self.grazeRadiusFactor=5

    self.shootRows=copy_table(Player.shootRows)
    self.shootRadius=0.5
    self.shootTransparency=0.5
    self.shootInterval=3

    self.moveMode=Player.moveModes.Bipolar
    self.dieShockwaveRadius=2

    self.keyRecord={}
    self.replaying=args.replaying or false
    if self.replaying then
        self:setReplaying()
    end
    self.key2Value={up=1,right=2,down=4,left=8,lshift=16,z=32}
    self.keyIsDown=love.keyboard.isDown
    self.realCreatedTime=os.date('%Y-%m-%d %H:%M:%S')
end
function Player:setReplaying()
    self.replaying=true
    self.keyIsDown=function(key)
        local record=self.keyRecord[self.frame+1] --this is because when recording keys first frame is stored at index 1 (by table.insert), while when playing at first frame key value is loaded from keyRecord before update, so self.frame=0
        local val=self.key2Value[key]
        if record and val then
            return record%(val*2)>=val
        end
        return false
    end
end

function Player:isDownInt(keyname)
    return self.keyIsDown(keyname)and 1 or 0
end

function Player:update(dt)
    if not self.replaying then
        local keyVal=0
        for key, value in pairs(self.key2Value) do
            if self.keyIsDown(key)then
                keyVal=keyVal+value
            end
        end
        table.insert(self.keyRecord,keyVal)
    end
    -- shooting bullet
    if self.keyIsDown('z') and self.frame%self.shootInterval==0 then
        self:shoot()
    end
    local xref=self.x
    local yref=self.y
    local rightDir,downDir
    local the=math.atan2(self.y-Shape.axisY,self.x-self.centerX)-math.pi/2
    if self.moveMode==Player.moveModes.Monopolar then
        rightDir=the
        downDir=rightDir
    elseif self.moveMode==Player.moveModes.Bipolar then
        rightDir,downDir=the,0
    elseif self.moveMode==Player.moveModes.Euclid then
        rightDir,downDir=0,0
    elseif self.moveMode==Player.moveModes.Natural then
        rightDir=self.naturalDirection
        downDir=self.naturalDirection
    end
    self.direction=rightDir
    local right=self:isDownInt("right")-self:isDownInt("left")
    if right==-1 then
        self.direction=math.pi+self.direction
    end
    local down=self:isDownInt("down")-self:isDownInt("up")
    if self.y<Shape.axisY then
        down=down*-1
    end
    if right==0 and down==0 then
        self.speed=0
    elseif right*down==0 then
        self.speed=self.movespeed
        if right==0 then
            self.direction=math.pi/2*down+downDir
        end
    else
        local upOrDownDir=math.pi/2*down+downDir
        self.speed=self.movespeed*2*math.cos((self.direction-upOrDownDir)/2)
        self.direction=(self.direction+upOrDownDir)/2
    end
    if self.keyIsDown('lshift') then
        self.speed=self.speed*self.focusFactor
        self.focusing=true
    else
        self.focusing=false
    end

    self.super.update(self,dt) -- actually move

    -- limit player in border
    local count=0
    while self.border and count<10 and not self.border:inside(self.x,self.y) do
        count=count+1
        local line={self.border:inside(self.x,self.y)}
        local p=Shape.nearestToLine(self.x,self.y,line[2],line[3],line[4],line[5])
        self.x=p[1]--xref+dot*dirx
        self.y=p[2]--yref+dot*diry
    end

    -- handle invincible time from hit
    self.invincibleTime=self.invincibleTime-dt
    if self.invincibleTime<=0 then
        self.invincibleTime=0
    end

    -- hp regen
    self.hp=math.clamp(self.hp+self.hpRegen*dt,0,self.maxhp)


    if self.moveMode==Player.moveModes.Natural then
        -- problems & thoughts: 1. when player is blocked by border, the moveDistance is still the assumed distance before calculating border. (solved by calculating math.distance of current pos and ref pos)
        -- 2. while not calling self:testRotate, the rightward direction is changing correctly. So, the ideal operation is posing a hyperbolic rotate transform before drawing all things (and restore after it), but obviously love2d doesn't support that. Hyperbolic rotate transform is simple as the testRotate, and the difference between normal rotate is that, the y=-100 line doesn't change (rotating player's view shouldn't change the line). Applying testRotate to all objects, changing their real position and cancelling out naturalDirection's update is not ideal and actually wrong.
        -- 3. A paradox? We know that this hyperbolic space H² is isotropic, but in this implementation the naturalDirection only changes when player's x coordinate changes, so that x and y aren't equal. The reason is probably that the projection used to map H² to E² (half-plane model) is not isotropic, and the coordinates to store objects are actually in E², not H².
        local moveDistance=math.distance(self.x,self.y,xref,yref)
        self.direction=Shape.to(xref,yref,self.x,self.y)
        local dtheta=-moveDistance/self:getMoveRadius()
        -- rightDir=rightDir-moveDistance/self.moveRadius
        self.naturalDirection=self.naturalDirection+dtheta
        -- self:testRotate(self.naturalDirection)
        
    end

    self:calculateMovingTransitionSprite()
    self:calculateFocusPointTransparency()
    self:calculateFlashbomb()
    self.grazeCountThisFrame=0
end

-- calculate which player sprite to use (normal, moveTransition and moving). Specifically, when not moving, loop through 8 normal sprites for each 8 frames. when moving, loop through 4 moveTransition sprites for each 2 frames, and after it loop through 8 moving sprites for each 8 frames. Use [tilt] to record.
function Player:calculateMovingTransitionSprite()
    local lingerFrame={normal=8,moveTransition=2,moving=8}
    local tiltMax=#Asset.player.moveTransition.left*lingerFrame.moveTransition
    local right=self:isDownInt("right")-self:isDownInt("left")
    local tilt=self.tilt or 0
    local keptFrame=self.keptFrame or 0 -- how long player has been keeping unmove or moving at the same direction (after transition of tiltMax frames)
    if tilt==0 then
        if right==0 then
            keptFrame=keptFrame+1 -- at current frame keeping unmove
        else
            keptFrame=0 -- start moving
            tilt=tilt+right
        end
    elseif math.abs(tilt)==tiltMax then
        if math.sign(right)==math.sign(tilt) then -- keep moving at the same direction
            keptFrame=keptFrame+1
        else
            keptFrame=0
            tilt=tilt-math.sign(tilt) -- reduce tilt as not moving at the same direction
        end
    else
        keptFrame=0
        tilt=tilt+(right==0 and -math.sign(tilt) or right) -- if do move, change tilt to the moving direction. if not moving, reduce tilt towards 0.
    end
    self.tilt=tilt
    self.keptFrame=keptFrame
    local direction=tilt>0 and 'right' or 'left'
    local sprite
    if tilt==0 then
        sprite=Asset.player.normal[math.ceil(keptFrame/lingerFrame.normal)%#Asset.player.normal+1]
    elseif math.abs(tilt)==tiltMax then
        sprite=Asset.player.moving[direction][math.ceil(keptFrame/lingerFrame.moving)%#Asset.player.moving[direction]+1]
    else
        sprite=Asset.player.moveTransition[direction][math.ceil(math.abs(tilt)/lingerFrame.moveTransition)]
    end
    self.sprite=sprite
end

function Player:calculateFocusPointTransparency()
    local focus=self.keyIsDown('lshift')
    self.focusPointTransparency=self.focusPointTransparency or 0
    local add=0.2
    if focus then
        self.focusPointTransparency=math.min(1,self.focusPointTransparency+add)
    else
        self.focusPointTransparency=math.max(0,self.focusPointTransparency-add)
    end
end

function Player:testRotate(angle,restore)
    -- hyperbolic rotate all points by angle around player (actually change coordinates, not a visual effect, so it must be reverted later)
    -- restoring value is quicker and more accurate than calling (-angle)
    local function rotate(v)
        local r,theta,thetaRev=Shape.distance(self.x,self.y,v.x,v.y),Shape.to(self.x,self.y,v.x,v.y),Shape.to(v.x,v.y,self.x,self.y)
        v.testRotateRef={v.x,v.y,v.direction}
        v.x,v.y=Shape.rThetaPos(self.x,self.y,r,theta+angle)
        local thetaRev2=Shape.to(v.x,v.y,self.x,self.y)
        if v.direction then
            v.direction=v.direction+thetaRev2-thetaRev -- not using +angle is because the uninterchangeability of direction at both point of a straight line (in hyperbolic plane).
        end
    end
    if restore then
        rotate=function(v)
            v.x,v.y,v.direction=v.testRotateRef[1],v.testRotateRef[2],v.testRotateRef[3]
        end
    end
    local list={Circle,BulletSpawner,Enemy,Laser,Laser.LaserUnit,Effect.Larger,Effect.Shockwave} -- due to different implementation, PolyLine has to be handled separately. not ideal
    for k,cls in pairs(list)do
        for k2,obj in pairs(cls.objects)do
            rotate(obj)
        end
    end
    for k2,obj in pairs(PolyLine.objects)do
        for k,point in pairs(obj.points) do
            rotate(point)
        end
    end
    if G.backgroundPattern:is(BackgroundPattern.FixedTesselation) or G.backgroundPattern:is(BackgroundPattern.FollowingTesselation) then
        local pattern=G.backgroundPattern
        for i=1,#pattern.sidesTable do
            rotate(pattern.sidesTable[i][1])
            rotate(pattern.sidesTable[i][2])
        end
    end
end

function Player:shoot()
    local x,y,r=Shape.getCircle(self.x,self.y,self.radius)
    local front=self.shootRows.front
    local frontRows=0
    for j=1,front.straight.num do
        frontRows=frontRows+1
        self:shootFrontStraight(math.ceil(frontRows/2)*(-1)^frontRows,front.straight.damage,front.straight.sprite)
    end
    for j=1,front.homing.num do
        frontRows=frontRows+1
        self:shootFrontHoming(math.ceil(frontRows/2)*(-1)^frontRows,front.homing.damage,front.homing.sprite)
    end
    local side=self.shootRows.side
    local sideRows=0
    for j=1,side.straight.num do
        sideRows=sideRows+1
        self:shootSideStraight(math.ceil(sideRows/2)*(-1)^sideRows,side.straight.damage,side.straight.sprite)
    end
    local back=self.shootRows.back
    local backRows=0
    for j=1,back.straight.num do
        backRows=backRows+1
        self:shootBackStraight(math.ceil(backRows/2)*(-1)^backRows,back.straight.damage,back.straight.sprite)
    end
end

-- pos is like: -3, -2, -1, 1, 2, 3
function Player:shootDirStraight(pos,damage,sprite,theta)
    local x,y,r=Shape.getCircle(self.x,self.y,self.radius)
    local dx,dy=r*2,r*(math.abs(pos)*2-1)*(pos<0 and -1 or 1)
    local cir=Circle({x=self.x+dx*math.cos(theta)-dy*math.sin(theta), y=self.y+dx*math.sin(theta)+dy*math.cos(theta), radius=self.shootRadius, lifeFrame=60, sprite=sprite or BulletSprites.darkdot.cyan, batch=Asset.playerBulletBatch, sprite_transparency=self.shootTransparency})
    cir.fromPlayer=true
    cir.safe=true
    cir.direction=theta
    cir.speed=200
    cir.damage=damage
    return cir
end

function Player:shootFrontStraight(pos,damage,sprite)
    return self:shootDirStraight(pos,damage,sprite,-math.pi/2+self.naturalDirection)
end
function Player:shootBackStraight(pos,damage,sprite)
    return self:shootDirStraight(pos,damage,sprite,math.pi/2+self.naturalDirection)
end

-- note that this shoots 2 bullets, 1 on each side
function Player:shootSideStraight(pos,damage,sprite)
    for side=0,1 do
        self:shootDirStraight(pos,damage,sprite,math.pi*side+self.naturalDirection)
    end
end

-- let [cir] trace the closest enemy.
-- [mode] determines how direction changes.
-- 'abrupt': directly set to the aim direction.
-- 'portion': 0.9*cir.direction+0.1*aimDirection.
-- 'clamp': math.clamp(aimDirection,cir.direction-0.01,cir.direction+0.01)
local function addHoming(cir,mode)
    mode=mode or 'abrupt'
    cir.homing=true
    Event.LoopEvent{
        obj=cir,
        period=1,
        executeFunc=function()
            if not cir.homing then -- some level effect removing homing
                return
            end
            local closestEnemy
            local closestDistance=9e9
            for key, value in pairs(Enemy.objects) do
                local dis=Shape.distance(cir.x,cir.y,value.x,value.y)
                if dis<closestDistance then
                    closestDistance=dis
                    closestEnemy=value
                end
            end
            if closestEnemy then
                local aim=Shape.to(cir.x,cir.y,closestEnemy.x,closestEnemy.y)
                if aim>cir.direction+math.pi then
                    aim=aim-math.pi*2
                end
                if aim<cir.direction-math.pi then
                    aim=aim+math.pi*2
                end
                if mode=='abrupt'then
                    cir.direction=aim
                elseif mode=='portion'then
                    cir.direction=.9*cir.direction+.1*aim
                elseif mode=='clamp'then
                    local da=0.1
                    cir.direction=math.clamp(aim,cir.direction-da,cir.direction+da)
                end
            end
        end
    }
end

function Player:shootFrontHoming(pos,damage,sprite)
    local cir=self:shootFrontStraight(pos,damage,sprite)
    addHoming(cir)
end

function Player:draw()
    -- Formula: center (x,y) and radius r should be drawn as center (x,y*cosh(r)) and radius y*sinh(r)
    local color={love.graphics.getColor()}
    love.graphics.setColor(1,1,0)
    if self.invincibleTime>0 then
        love.graphics.setColor(1,0,0)
    end
    -- Shape.drawCircle(self.x,self.y,self.drawRadius)
    love.graphics.setColor(color[1],color[2],color[3])
    -- love.graphics.circle("line", self.x, self.y, 1) -- center point
    -- love.graphics.print(tostring(self.hp),self.x-5,self.y-8)
    --draw hit point
    local x,y,r=Shape.getCircle(self.x,self.y,self.drawRadius)
    Asset.playerFocusBatch:setColor(1,1,1,self.focusPointTransparency)
    Asset.playerFocusBatch:add(Asset.playerFocus,x,y,self.time/5,r*0.4,r*0.4,31,33)-- the image is 64*64 but the focus center seems slightly off
    if self.sprite then
        Asset.playerBatch:add(self.sprite,x,y,0,r*0.53,r*0.53,Asset.player.width/2,Asset.player.height/2)
    end
end

-- this function draws which keys are pressed. The keys are arranged as:
--[[
            U
Shift Z   L D R 
]]
function Player:displayKeysPressed()
    local x0,y0=15,500
    local gridSize=20
    local keysPoses={up={4,0},down={4,1},left={3,1},right={5,1},lshift={0,1},z={1,1}}
    local color={love.graphics.getColor()}
    for key, value in pairs(keysPoses) do
        local x,y=x0+value[1]*gridSize,y0+value[2]*gridSize
        if self.keyIsDown(key) then
            love.graphics.setColor(1,1,1)
            love.graphics.rectangle("fill",x,y,gridSize,gridSize)
        end
        love.graphics.setColor(0,0,0)
        love.graphics.rectangle("line",x,y,gridSize,gridSize)
    end
    love.graphics.setColor(color[1],color[2],color[3])
end

function Player:drawText()
    self:displayKeysPressed()
    SetFont(24)
    love.graphics.print(Localize{'ui','playerHP',HP=string.format("%.2f", self.hp)},40,110)
    love.graphics.print('X='..string.format("%.2f", self.x)..'\nY='..string.format("%.2f", self.y),30,140)
    -- love.graphics.print(''..self.naturalDirection,100,120)
    if self.enableFlashbomb then -- draw fill rate for flashbomb
        local color={love.graphics.getColor()}
        local x0,y0=30,570
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle("line",x0,y0,100,10)
        love.graphics.setColor(1,0.2,0.5)
        love.graphics.rectangle("fill",x0,y0,100*(self.grazeCount%self.grazeCountForFlashbomb)/self.grazeCountForFlashbomb,10)
        love.graphics.setColor(color[1],color[2],color[3])
    end
end

-- spawn a white dot to show the graze effect. Actually this random speed and direction particle has broken old replays sooooo many times each time I tweak bullet size or graze range :(
function Player:grazeEffect(amount)
    amount=amount or 1
    SFX:play('graze')
    if self.version and isVersionSmaller(self.version,'0.2.0.1') then
        Effect.Larger{x=self.x,y=self.y,speed=math.eval('50+30'),direction=math.eval('1+9999'),sprite=Asset.shards.dot,radius=7,growSpeed=1,animationFrame=20}
    else -- non-random graze effect
        Effect.Larger{x=self.x,y=self.y,speed=50+30*math.sin(self.x*51323.35131+self.y*46513.1333+self.frame*653.13),direction=9999*math.sin(self.x*513.35131+self.y*413.1333+self.frame*6553.13),sprite=Asset.shards.dot,radius=7,growSpeed=1,animationFrame=20}
    end
    self.grazeCountThisFrame=(self.grazeCountThisFrame or 0)+amount
    if self.grazeCountThisFrame>20 then
        return -- avoid too many grazes in a short time
    end
    -- grazeHpRegen
    self.hp=math.clamp(self.hp+self.grazeHpRegen*amount,0,self.maxhp)
    self.grazeCount=self.grazeCount+amount
end

-- it's hit effect, not hp = 0 effect
function Player:hitEffect(damage)
    if self.invincibleTime>0 then
        return
    end
    damage=damage or 1
    self.hp=self.hp-damage
    self.hurt=true
    self.dieFrame=self.frame
    self.invincibleTime=self.invincibleTime+1
    if self.hp<=0 then
        G:lose()
    end
    Effect.Shockwave{x=self.x,y=self.y,radius=self.dieShockwaveRadius,growSpeed=1.1,animationFrame=30}
    SFX:play('dead',true)
end

-- effect is strange, not used
function Player:drawShader()
    -- if self.dieFrame and self.frame-self.dieFrame<90 then
    --     local t=self.frame-self.dieFrame
    --     love.graphics.setShader(invertShader)
    --     local x,y,r=self.x,self.y,t*2
    --     x,y,r=Shape.getCircle(x,y,r)
    --     invertShader:send("centerInner",{x,y})
    --     invertShader:send("radiusInner",r)
    --     x,y,r=self.x,self.y,t*2+10
    --     x,y,r=Shape.getCircle(x,y,r)
    --     invertShader:send("centerOuter",{x,y})
    --     invertShader:send("radiusOuter",r)
    -- end
end

function Player:calculateFlashbomb()
    if not self.enableFlashbomb then
        return
    end
    local count=self.flashbombCount or 1
    if self.grazeCount>=count*self.grazeCountForFlashbomb then
        self.flashbombCount=count+1
        SFX:play('enemyPowerfulShot',true,0.8)
        Effect.FlashBomb{x=self.x,y=self.y,width=self.flashbombWidth*self:getMetric(),lifeFrame=30,direction=math.pi/2}
    end
end

return Player