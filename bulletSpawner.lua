
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
    self.period=args.period or 60
    self.frame=args.frame or 0
    self.realFrame=0
    self.bulletNumber=args.bulletNumber and math._extractABfromstr(args.bulletNumber) or 10
    self.angle=args.angle and (args.angle=='player' and args.angle or math._extractABfromstr(args.angle)) or 0
    self.range=args.range and math._extractABfromstr(args.range) or math.pi*2
    self.spawnCircleRadius=args.spawnCircleRadius or 0
    self.spawnCircleAngle=args.spawnCircleAngle and math._extractABfromstr(args.spawnCircleAngle) or 0
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
    self.spawnBulletFunc=args.spawnBulletFunc or function(self,args)
        if not args.x then
            args.x=self.x
        end
        if not args.y then
            args.y=self.y
        end
        if not args.lifeFrame then
            args.lifeFrame=self.bulletLifeFrame
        end
        if not args.sprite then
            args.sprite=self.bulletSprite
        end
        args.direction=math.eval(args.direction)
        args.speed=math.eval(args.speed)
        args.invincible=self.args.invincible or args.invincible or false
        if args.sprite.data.isLaser then
            args.laserEvents=self.args.laserEvents or {}
            args.bulletEvents=self.bulletEvents
            args.warningFrame=self.args.warningFrame or 0
            args.fadingFrame=self.args.fadingFrame or 0
            local cir=Laser(args)
            return
        end
        args.extraUpdate=self.bulletExtraUpdate or {}
        local cir=Circle(args)
        -- table.insert(ret,cir)
        for key, func in pairs(self.bulletEvents) do
            func(cir,args,self)
        end
        return cir
    end
    if self.fogEffect then
        self.spawnBulletFuncRef=self.spawnBulletFunc
        self.spawnBulletFunc=function(self,args)
            local color=Asset.SpriteData[self.bulletSprite].color
            local fog=Circle({x=args.x or self.x, y=args.y or self.y, radius=args.radius, lifeFrame=self.fogTime, sprite=Asset.bulletSprites.fog[color],safe=true})
            Event.EaseEvent{
                obj=fog,
                easeFrame=self.fogTime,
                aimTable=fog,
                aimKey='spriteTransparency',
                aimValue=0,
                -- period=self.fogTime,
                afterFunc=function()
                    self.spawnBulletFuncRef(self,args)
                end
            }
        end
    end
    self.spawnBatchFunc=args.spawnBatchFunc or function(self)
        SFX:play('enemyShot',true,self.spawnSFXVolume)
        local num=math.eval(self.bulletNumber)
        local range=math.eval(self.range)
        local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
        local spawnCircleAngle=math.eval(self.spawnCircleAngle)
        local speed=math.eval(self.bulletSpeed)
        local size=math.eval(self.bulletSize)
        for i = 1, num, 1 do
            local direction=range*(i-0.5-num/2)/num+angle
            local x,y=Shape.rThetaPos(self.x,self.y,self.spawnCircleRadius,math.pi*2*(i-0.5-num/2)/num+spawnCircleAngle)
            if self.spawnCircleRadius~=0 then
                direction=Shape.to(x,y,self.x,self.y)+math.pi+angle
            end
            self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed,radius=size,index=i,batch=self.bulletBatch}
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
    if player.canHitFamiliar and G.mainEnemy then
        Enemy.checkHitByPlayer(self,G.mainEnemy,player.hitFamiliarDamageFactor)
    end
end

function BulletSpawner:draw()
    local color={love.graphics.getColor()}
    love.graphics.setColor(1,0,1)
    Shape.drawCircle(self.x,self.y,self.radius)
    love.graphics.setColor(color[1],color[2],color[3])
end

return BulletSpawner