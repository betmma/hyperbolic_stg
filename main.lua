
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
function love.load()
    Object = require "classic"
    Shape = require "shape"
    Rectangle = require "rectangle"
    Circle = require "circle"
    PolyLine = require "polyline"
    Player = require "player"
    Event= require "event"

    -- r1 = Rectangle(100, 100, 200, 50)
    function CircleCast(num,x,y,speed,size,extraUpdate)
        local ret={}
        for i = 1, num, 1 do
            local cir=Circle(x, y, size)
            table.insert(ret,cir)
            cir.direction=math.pi*i*2/num
            cir.speed=speed
            cir.extraUpdate=extraUpdate
        end
        return ret
    end
    
    player=Player(400,300)
    -- x = 100 
    -- y=50
    -- ratio=1
    Event.LoopEvent{
        period=2,
        time=2,
        executeFunc=function(self)
            local ret=CircleCast(math.random(30,50),math.random(300,500),math.random(100,300),math.random(30,50),math.random(1,3))
            for key, cir in pairs(ret) do
                Event.EaseEvent{
                    easeTime=1,
                    aimTable=cir,
                    aimKey='direction',
                    aimValue=cir.direction+(key%2==0 and math.pi or -math.pi)
                }
                Event.EaseEvent{
                    easeTime=5,
                    aimTable=cir,
                    aimKey='speed',
                    aimValue=20
                }
            end
        end
    }
end
function love.update(dt)
    -- dt=1/60
    if math.random()<dt/4 then
        local xy={math.random(300,500),math.random(100,300)}
        for i = 1, 30, 1 do
            local cir=Circle(xy[1],xy[2], 1)
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