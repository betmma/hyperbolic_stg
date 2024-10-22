
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

    BulletSpawner{x=400,y=100,period=2,time=2,bulletNumber='40+10',bulletSpeed='40+10',bulletSize='2+1',bulletEvents={
        function(cir,args)
            local key=args.index
            Event.EaseEvent{
                easeTime=10,
                aimTable=cir,
                aimKey='direction',
                aimValue=cir.direction+(key%2==0 and math.pi or -math.pi)/2
            }
            Event.EaseEvent{
                easeTime=5,
                aimTable=cir,
                aimKey='speed',
                aimValue=20
            }
        end

    }}
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
    if math.random()<dt/4 then
        local xy={math.random(300,500),math.random(100,300)}
        for i = 1, 30, 1 do
            local cir=Circle({x=xy[1],y=xy[2], radius=1})
            cir.lifeTime=10
            cir.direction=i<=15 and 0 or math.pi
            cir.speed=math.abs(6*(i-15))
            Event.LoopEvent{
                times=1,
                period=1,
                conditionFunc=function()return true end,
                executeFunc=function(self)
                    cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)
                    cir.speed=cir.speed+10
                end}
        end
    end
    Rectangle:updateAll(dt)
    Circle:updateAll(dt)
    Event:updateAll(dt)
    player:update(dt)
end

function love.draw()
    -- if Circle.objects[1] then
        
    --     love.graphics.print(tostring(Circle.objects[1].time),100,100)
    -- end
    Rectangle:drawAll()
    Circle:drawAll()
    PolyLine:drawAll()
    player:draw()
end