
local Shape = require "shape"
local Circle=require'circle'
local Event=require"event"

local BulletSpawner=Shape:extend()

-- a spawner spawns [bulletNumber] or bullets with size=[bulletSize], speed=[bulletSpeed] from angle=[angle] to [angle+range] every [period] secs.
-- all numbers except for [period] can be set to 'a+b' form to mean random.range(a-b,a+b)
-- each function in [bulletEvents] should takes a bullet (circle) and adds event to it.
-- [spawnBatchFunc] and [spawnBulletFunc] can be modified to spawn non-circle pattern bullets (like a line of bullets of different speed or spawn spawners)
function BulletSpawner:new(args)
    BulletSpawner.super.new(self, args)
    self.period=args.period or 1
    self.time=args.time or 0
    self.bulletNumber=args.bulletNumber or 10
    self.angle=args.angle or 0
    self.range=args.range or math.pi*2
    self.bulletSpeed=args.bulletSpeed or 20
    self.bulletSize=args.bulletSize or 1
    self.bulletEvents=args.bulletEvents or {}
    self.spawnBulletFunc=args.spawnBulletFunc or function(self,args)
        local cir=Circle({x=self.x, y=self.y, radius=args.radius})
        -- table.insert(ret,cir)
        cir.direction=math.eval(args.direction)
        cir.speed=math.eval(args.speed)
        for key, func in pairs(self.bulletEvents) do
            func(cir,args)
        end
    end
    self.spawnBatchFunc=args.spawnBatchFunc or function(self)
        local num=math.eval(self.bulletNumber)
        local range=math.eval(self.range)
        local angle=math.eval(self.angle)
        local speed=math.eval(self.bulletSpeed)
        local size=math.eval(self.bulletSize)
        for i = 1, num, 1 do
            local direction=range*(i-0.5-num/2)/num+angle
            self:spawnBulletFunc{direction=direction,speed=speed,radius=size,index=i}
        end
    end
    self.spawnEvent=Event.LoopEvent{obj=self,period=self.period,time=self.time,executeFunc=function(event,dt)
        self:spawnBatchFunc()
    end}
end

function BulletSpawner:draw()
    local color={love.graphics.getColor()}
    love.graphics.setColor(1,0,1)
    math.drawCircle(self.x,self.y,5)
    love.graphics.setColor(color[1],color[2],color[3])
end

return BulletSpawner