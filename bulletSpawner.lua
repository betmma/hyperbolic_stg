
local Shape = require "shape"
local Circle=require'circle'
local Event=require"event"

local BulletSpawner=Shape:extend()

-- a spawner spawns [bulletNumber] or bullets with size=[bulletSize], speed=[bulletSpeed] from angle=[angle] to [angle+range] every [period] frames.
-- all numbers except for [period] can be set to 'a+b' form to mean random.range(a-b,a+b). angle can be 'player' to mean player. (can't use on other params)
-- each function in [bulletEvents] should takes a bullet (circle) and adds event to it.
-- [spawnBatchFunc] and [spawnBulletFunc] can be modified to spawn non-circle pattern bullets (like a line of bullets of different speed or spawn spawners)
function BulletSpawner:new(args)
    BulletSpawner.super.new(self, args)
    self.radius=args.radius or 5
    self.visible=args.visible
    if self.visible==nil then
       self.visible=(self.lifeFrame>60 and true or false)
    end
    self.sprite=BulletSprites.lotus[args.bulletSprite and Asset.spectrum1MapSpectrum2[args.bulletSprite.data.color] or 'gray']
    self.period=args.period or 60
    self.frame=args.frame or 0
    self.realFrame=0
    self.bulletNumber=args.bulletNumber and math._extractABfromstr(args.bulletNumber) or 10
    self.angle=args.angle and (args.angle=='player' and args.angle or math._extractABfromstr(args.angle)) or 0
    self.range=args.range and math._extractABfromstr(args.range) or math.pi*2
    self.spawnCircleRadius=args.spawnCircleRadius and math._extractABfromstr(args.spawnCircleRadius) or 0
    self.spawnCircleAngle=args.spawnCircleAngle and math._extractABfromstr(args.spawnCircleAngle) or 0
    self.spawnCircleRange=args.spawnCircleRange and math._extractABfromstr(args.spawnCircleRange) or math.pi*2
    self.bulletSpeed=args.bulletSpeed and math._extractABfromstr(args.bulletSpeed) or 20
    self.bulletSize=args.bulletSize and math._extractABfromstr(args.bulletSize) or 1
    self.bulletLifeFrame=args.bulletLifeFrame or 2000
    self.bulletEvents=args.bulletEvents or {}
    self.bulletExtraUpdate=args.bulletExtraUpdate
    self.bulletSprite=args.bulletSprite
    self.bulletBatch=args.bulletBatch or (args.highlight and Asset.bulletHighlightBatch or BulletBatch)
    -- when spawning bullets, spawn a fog that turns into bullet sometime later
    self.fogEffect=args.fogEffect or false
    self.fogTime=args.fogTime or 60
    self.spawnSFXVolume=args.spawnSFXVolume -- nil means default volume set in audio.lua (50%)
    self.spawnBulletFunc=args.spawnBulletFunc or function(self,_args)
        if not _args.x then
            _args.x=self.x
        end
        if not _args.y then
            _args.y=self.y
        end
        if not _args.lifeFrame then
            _args.lifeFrame=self.bulletLifeFrame
        end
        if not _args.sprite then
            _args.sprite=self.bulletSprite
        end
        _args.direction=math.eval(_args.direction)
        _args.speed=math.eval(_args.speed)
        _args.invincible=_args.invincible or args.invincible or false
        if _args.sprite.data.isLaser then
            _args.laserEvents=args.laserEvents or {}
            _args.bulletEvents=self.bulletEvents
            _args.warningFrame=args.warningFrame or 0
            _args.fadingFrame=args.fadingFrame or 0
            _args.frequency=args.frequency
            local cir=Laser(_args)
            return
        end
        _args.extraUpdate=self.bulletExtraUpdate or {}
        local cir=Circle(_args)
        -- table.insert(ret,cir)
        for key, func in pairs(self.bulletEvents) do
            func(cir,_args,self)
        end
        return cir
    end
    if self.fogEffect then
        self.spawnBulletFuncRef=self.spawnBulletFunc
        self.spawnBulletFunc=function(self,args)
            self.wrapFogEffect(args,function()
                        self.spawnBulletFuncRef(self,args)
                    end)
        end
    end
    self.spawnBatchFunc=args.spawnBatchFunc or function(self)
        SFX:play('enemyShot',true,self.spawnSFXVolume)
        local num=math.eval(self.bulletNumber)
        local range=math.eval(self.range)
        local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
        local spawnCircleAngle=math.eval(self.spawnCircleAngle)
        local spawnCircleRange=math.eval(self.spawnCircleRange)
        local spawnCircleRadius=math.eval(self.spawnCircleRadius)
        local speed=math.eval(self.bulletSpeed)
        local size=math.eval(self.bulletSize)
        for i = 1, num, 1 do
            local direction=range*(i-0.5-num/2)/num+angle
            local x,y=Shape.rThetaPos(self.x,self.y,spawnCircleRadius,spawnCircleRange*(i-0.5-num/2)/num+spawnCircleAngle)
            if spawnCircleRadius~=0 then
                direction=Shape.to(x,y,self.x,self.y)+math.pi+angle
            end
            self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed,radius=size,index=i,batch=self.bulletBatch,fogTime=self.fogTime,sprite=self.bulletSprite}
        end
    end
    ---@type LoopEvent
    self.spawnEvent=Event.LoopEvent{obj=self,period=self.period,frame=self.frame,executeFunc=function(event,dt)
        self:spawnBatchFunc()
    end}
end

function BulletSpawner:update(dt)
    self.realFrame=self.realFrame+1
    BulletSpawner.super.update(self,dt)
    for k,shockwave in pairs(Effect.Shockwave.objects) do
        if shockwave.canRemove.bulletSpawner and Shape.distance(shockwave.x,shockwave.y,self.x,self.y)<shockwave.radius+self.radius then
            self:remove()
        end
    end
    local player=Player.objects[1]
    if player and player.canHitFamiliar and G.mainEnemy then
        Enemy.checkHitByPlayer(self,G.mainEnemy,player.hitFamiliarDamageFactor)
    end
end

function BulletSpawner:draw()
    -- local color={love.graphics.getColor()}
    -- love.graphics.setColor(1,0,1)
    -- Shape.drawCircle(self.x,self.y,self.radius)
    -- love.graphics.setColor(color[1],color[2],color[3])
    if self.visible then
        self:drawSprite()
    end
end

---@class fogArgs
---@field fogTime number frames before fog disappears and calls func
---@field sprite Sprite
---@field color string|nil defaults to args.sprite.data.color
---@field x number 
---@field y number 
---@field radius number|nil defaults to 1
---@field fogTransparency number|nil transparency of fog, defaults to 1

---@param args fogArgs
---@param func function|nil to be called after fog disappears. defaults to Circle
---@param wrapping boolean|nil if true, will call func(args), otherwise only func() (so you need to wrap it to send args)
function BulletSpawner.wrapFogEffect(args, func, wrapping)
    if not func then
        func,wrapping=Circle,true
    end
    local color=args.color or (args.sprite and args.sprite.data.color) or 'red'
    local fogTime=args.fogTime or 60
    local x=args.x
    local y=args.y
    local radius=args.radius or args.radius or 1
    local fog=Circle({x=x, y=y, radius=radius, lifeFrame=fogTime, sprite=Asset.bulletSprites.fog[color],safe=true,spriteTransparency=args.fogTransparency or 1})
    local easeFunc=func
    if wrapping then
        easeFunc=function()func(args)end
    end
    Event.EaseEvent{
        obj=fog,
        easeFrame=fogTime,
        aimTable=fog,
        aimKey='spriteTransparency',
        aimValue=0,
        -- period=self.fogTime,
        afterFunc=easeFunc
    }
end

function BulletSpawner:drawSprite()
    if not self.sprite then
        return
    end
    local color={love.graphics.getColor()}
    local x,y,radius=Shape.getCircle(self.x,self.y,self.radius)
    local data=self.sprite.data
    local scale=radius/data.hitRadius*0.3
    local r,g,b
    if self.spriteColor then
        r,g,b=self.spriteColor[1],self.spriteColor[2],self.spriteColor[3]
    end
    local batch=Asset.bulletBatch
    batch:setColor(r or 1,g or 1,b or 1,(self.spriteTransparency or 0.5)*color[4])
    batch:add(self.sprite.quad,x,y,self.time,scale,scale,data.centerX,data.centerY)
end

return BulletSpawner