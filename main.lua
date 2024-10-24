
if arg[2] == "debug" then
    require("lldebugger").start()
end
function math.distance(x1,y1,x2,y2)
    return ((x1-x2)^2+(y1-y2)^2)^0.5
end
function math.clamp(val, lower, upper)
    assert(val and lower and upper, "nil sent to math.Clamp")
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end
-- input: a number or 'a+b', return that number or random number in [a-b,a+b]
function math.eval(str)
    -- Check if the string is in the format 'a+b' where a can be negative
    local a, b = string.match(str, "([%-]?%d+)%+(%d+)")
    
    if a and b then
        -- Convert a and b to numbers
        a = tonumber(a)
        b = tonumber(b)
        -- Return a random number in the range [a-b, a+b]
        return math.random(a - b, a + b)
    else
        -- Otherwise, assume the string is just a number
        return tonumber(str)
    end
end

function copy_table(O)
    local O_type = type(O)
    local copy
    if O_type == 'table' then
        copy = {}
        for k, v in next, O, nil do
            copy[copy_table(k)] = copy_table(v)
        end
        setmetatable(copy, getmetatable(O))
    else
        copy = O
    end
    return copy
end

function love.load()
    Object = require "classic"
    Shape = require "shape"
    Rectangle = require "rectangle"
    Circle = require "circle"
    PolyLine = require "polyline"
    Player = require "player"
    Event= require "event"
    BulletSpawner=require"bulletSpawner"
    local Asset=require"loadAsset"
    BulletSprites,BulletBatch=Asset.bulletSprites,Asset.bulletBatch

    a=BulletSpawner{x=400,y=200,period=5,time=0,lifeTime=100,bulletNumber=40,bulletSpeed='40',bulletSize=2,bulletEvents={
        function(cir,args)
            local key=args.index
            Event.EaseEvent{
                obj=cir,
                easeTime=10,
                aimTable=cir,
                aimKey='direction',
                aimValue=cir.direction+(key%2==0 and math.pi or -math.pi)*2,
                -- progressFunc=function(x)return math.sin(math.pi*20*x) end
            }
            Event.EaseEvent{
                obj=cir,
                easeTime=5,
                aimTable=cir,
                aimKey='speed',
                aimValue=20
            }
        end

    }}
    e1=Event.LoopEvent{
        obj=a,
        time=5,
        period=5,
        conditionFunc=function()return true end,
        executeFunc=function(self)
            a.angle=math.eval('3.14+3.14')
            a.spawnEvent.time=0
            a.spawnEvent.period=0.2
            e3=Event.EaseEvent{
                obj=a,
                easeTime=2,
                aimTable=a,
                aimKey='bulletSpeed',
                aimValue=50,
            }
        end
    }
    e2=Event.LoopEvent{
        obj=a,
        time=3,
        period=5,
        conditionFunc=function()return true end,
        executeFunc=function(self)
            a.spawnEvent.period=5
            a.bulletSpeed=40
        end
    }
    local b=BulletSpawner{x=400,y=100,period=4,time=2,lifeTime=100,bulletNumber=30,bulletSpeed=6,bulletSize=1,bulletEvents={
        function(cir,args)
            local key=args.index
            Event.LoopEvent{
                obj=cir,
                times=1,
                period=1,
                conditionFunc=function()return true end,
                executeFunc=function(self)
                    cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)
                    cir.speed=cir.speed+10
            end}
        end
    },
    spawnBatchFunc=function(self)
        local num=math.eval(self.bulletNumber)
        local angle=math.eval(self.angle)
        local speed=math.eval(self.bulletSpeed)
        local size=math.eval(self.bulletSize)
        for i = 1, num, 1 do
            self:spawnBulletFunc{direction=i<=num/2 and 0 or math.pi,speed=math.abs(speed*(i-num/2)),radius=size,index=i}
        end
    end}
    -- a:remove()
    -- r1 = Rectangle(100, 100, 200, 50)
    function CircleCast(num,x,y,speed,size,extraUpdate)
        local ret={}
        for i = 1, num, 1 do
            local cir=Circle({x=x, y=y, radius=size})
            table.insert(ret,cir)
            cir.direction=math.pi*i*2/num
            cir.speed=speed
            cir.extraUpdate=extraUpdate
        end
        return ret
    end
    
    player=Player(400,300)
end
function love.update(dt)
    -- dt=1/60
    -- Rectangle:updateAll(dt)
    BulletSpawner:updateAll(dt)
    Circle:updateAll(dt)
    player:update(dt)
    Event:updateAll(dt)
    BulletBatch:clear()
    for key, cir in pairs(Circle.objects) do
        local scale=(cir.y-Shape.axisY)*math.sinh(cir.radius/Shape.curvature)/4
        BulletBatch:add(BulletSprites.scale.gray,cir.x,(cir.y-Shape.axisY)*math.cosh(cir.radius/Shape.curvature)+Shape.axisY,cir.direction+math.pi/2,scale,scale,8,8)
    end
    BulletBatch:flush()
end

function love.draw()
    love.graphics.draw(BulletBatch)
    -- if Circle.objects[1] then
        
        love.graphics.print(tostring(e1.time),600,200)
        love.graphics.print(tostring(e2.time),600,300)
        if e3 then
            
            love.graphics.print(tostring(e3.time),600,400)
        end
        love.graphics.print(''..#Event.LoopEvent.objects,600,500)
        love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
    -- end
    Rectangle:drawAll()
    Circle:drawAll()
    PolyLine:drawAll()
    PolyLine.drawAll(BulletSpawner)
    player:draw()
end