
local Shape = require "shape"
local Circle=require"circle"
local PolyLine=require"polyline"
local Player = Shape:extend()
Player.moveModes={
    -- North Pole (400, Shape.axisY). Move directions are same as Polar Coordinate System in Euclid space, that is Up / Down -> close to / away from pole. Left / Right -> along the arc centered at North Pole.
    -- Up & Down: not in hyperbolic line.
    -- Left & Right: in hyperbolic line.
    -- Orthogonality: True.
    Monopolar='Monopolar',
    -- North Pole (400, Shape.axisY), East Pole (+∞, 400). Up / Down -> only change y coordinate. Left / Right -> same as Monopolar, along the arc.
    -- Up & Down: in hyperbolic line.
    -- Left & Right: in hyperbolic line.
    -- Orthogonality: False.
    Bipolar='Bipolar'
}
function Player:new(args)
    Player.super.new(self, {x=args.x, y=args.y})
    self.lifeFrame=9999999
    self.speed=0
    self.movespeed=args.movespeed or 60
    self.focusFactor=0.4444
    --when pressed left or right player moves in an arc with center (centerX,0)
    self.centerX=400
    --drawn as a circle
    self.radius = 0.5
    -- self.border={minx=0,maxx=love.graphics.getWidth(),miny=0,maxy=love.graphics.getHeight()}
    local minx=150
    local maxx=650
    local miny=0
    local maxy=540
    
    self.border=PolyLine({{minx,miny},{maxx,miny},{maxx,maxy},{minx,maxy}})

    self.maxhp=3
    self.hp=self.maxhp
    self.hpRegen=0
    self.hurt=false --to check perfect completion
    self.invincibleTime=0

    self.shootRows={
        front={
            straight={
                num=4,
                dmg=1,
                sprite=BulletSprites.darkdot.cyan
            },
            homing={
                num=0,
                dmg=1,
                sprite=BulletSprites.darkdot.red
            }
        },
        side={
            straight={
                num=0,
                dmg=1,
                sprite=BulletSprites.darkdot.blue
            }
        },
        back={
            straight={
                num=0,
                dmg=1,
                sprite=BulletSprites.darkdot.purple
            }
        }
    }
    self.shootRadius=0.5
    self.shootTransparency=0.5

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
    if self.keyIsDown('z') then
        self:shoot()
    end
    local xref=self.x
    local yref=self.y
    local rightDir=math.atan2(self.y-Shape.axisY,self.x-self.centerX)-math.pi/2
    local downDir=self.moveMode==Player.moveModes.Bipolar and 0 or rightDir
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
    end

    self.super.update(self,dt) -- actually move

    -- limit player in border
    local count=0
    while count<10 and not self.border:inside(self.x,self.y) do
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
        -- it's not ideal to handle hit in player:update, cuz different bullets may have non-circle hitbox (like laser) so this part will grow long
    end

    -- hp regen
    self.hp=math.clamp(self.hp+self.hpRegen*dt,0,self.maxhp)

    --draw hit point
    local x,y,r=Shape.getCircle(self.x,self.y,self.radius)
    Asset.playerFocusBatch:add(Asset.playerFocus,x,y,self.time/5,r*0.4,r*0.4,31,33)-- the image is 64*64 but the focus center seems slightly off

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
    return self:shootDirStraight(pos,damage,sprite,-math.pi/2)
end
function Player:shootBackStraight(pos,damage,sprite)
    return self:shootDirStraight(pos,damage,sprite,math.pi/2)
end

-- note that this shoots 2 bullets on each side
function Player:shootSideStraight(pos,damage,sprite)
    for side=0,1 do
        self:shootDirStraight(pos,damage,sprite,math.pi*side)
    end
end

local function addHoming(cir)
    Event.LoopEvent{
        obj=cir,
        period=1,
        executeFunc=function()
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
                cir.direction=Shape.to(cir.x,cir.y,closestEnemy.x,closestEnemy.y)
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
    Shape.drawCircle(self.x,self.y,self.radius)
    love.graphics.setColor(color[1],color[2],color[3])
    -- love.graphics.circle("line", self.x, self.y, 1) -- center point
    -- love.graphics.print(tostring(self.hp),self.x-5,self.y-8)
    SetFont(24)
    love.graphics.print('HP: '..string.format("%.2f", self.hp),40,110)
end


function Player:grazeEffect()
    SFX:play('graze')
    Effect.Larger{x=self.x,y=self.y,speed=math.eval('50+30'),direction=math.eval('1+9999'),sprite=Asset.shards.dot,radius=7,growSpeed=1,animationFrame=20}
end

function Player:dieEffect()
    self.hp=self.hp-1
    self.hurt=true
    self.invincibleTime=self.invincibleTime+1
    if self.hp<=0 then
        G:lose()
    end
    Effect.Shockwave{x=self.x,y=self.y,radius=self.dieShockwaveRadius,growSpeed=1.1,animationFrame=30}
    SFX:play('dead',true)
end

return Player