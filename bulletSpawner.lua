
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
    self.bulletNumber=args.bulletNumber or 10
    self.angle=args.angle or 0
    self.range=args.range or math.pi*2
    self.bulletSpeed=args.bulletSpeed or 20
    self.bulletSize=args.bulletSize or 1
    self.bulletLifeFrame=args.bulletLifeFrame or 2000
    self.bulletEvents=args.bulletEvents or {}
    self.bulletSprite=args.bulletSprite
    -- when spawning bullets, spawn a fog that turns into bullet 1s later
    self.fogEffect=args.fogEffect or false
    self.fogTime=args.fogTime or 60
    self.spawnBulletFunc=args.spawnBulletFunc or function(self,args)
        local cir=Circle({x=args.x or self.x, y=args.y or self.y, radius=args.radius, lifeFrame=self.bulletLifeFrame, sprite=self.bulletSprite, invincible=args.invincible})
        -- table.insert(ret,cir)
        cir.direction=math.eval(args.direction)
        cir.speed=math.eval(args.speed)
        for key, func in pairs(self.bulletEvents) do
            func(cir,args)
        end
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
                aimKey='sprite_transparency',
                aimValue=0,
                period=self.fogTime,
                endFunc=function()
                    self.spawnBulletFuncRef(self,args)
                end
            }
        end
    end
    self.spawnBatchFunc=args.spawnBatchFunc or function(self)
        local num=math.eval(self.bulletNumber)
        local range=math.eval(self.range)
        local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
        local speed=math.eval(self.bulletSpeed)
        local size=math.eval(self.bulletSize)
        for i = 1, num, 1 do
            local direction=range*(i-0.5-num/2)/num+angle
            self:spawnBulletFunc{direction=direction,speed=speed,radius=size,index=i}
        end
    end
    self.spawnEvent=Event.LoopEvent{obj=self,period=self.period,frame=self.frame,executeFunc=function(event,dt)
        self:spawnBatchFunc()
    end}
end

function BulletSpawner:update(dt)
    BulletSpawner.super.update(self,dt)
    for k,shockwave in pairs(Effect.Shockwave.objects) do
        if shockwave.canRemove.bulletSpawner and Shape.distance(shockwave.x,shockwave.y,self.x,self.y)<shockwave.radius+self.radius then
            self:remove()
        end
    end
end

function BulletSpawner:draw()
    local color={love.graphics.getColor()}
    love.graphics.setColor(1,0,1)
    Shape.drawCircle(self.x,self.y,self.radius)
    love.graphics.setColor(color[1],color[2],color[3])
end

return BulletSpawner