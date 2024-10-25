
if arg[2] == "debug" then
    require("lldebugger").start()
end
require'misc'
function love.load()
    Object = require "classic"
    Shape = require "shape"
    Rectangle = require "rectangle"
    Circle = require "circle"
    PolyLine = require "polyline"
    Player = require "player"
    Event= require "event"
    BulletSpawner=require"bulletSpawner"
    Asset=require"loadAsset"
    BulletSprites,BulletBatch,SpriteData=Asset.bulletSprites,Asset.bulletBatch,Asset.SpriteData
    G=require"state"

    function s1()
        a=BulletSpawner{x=400,y=200,period=0.03333,time=0,lifeTime=100,bulletNumber=10,bulletSpeed='60',bulletSize=0.75,bulletSprite=BulletSprites.crystal.blue,bulletEvents={
            -- function(cir,args)
            --     local key=args.index
            --     Event.EaseEvent{
            --         obj=cir,
            --         easeTime=10,
            --         aimTable=cir,
            --         aimKey='direction',
            --         aimValue=cir.direction+(key%2==0 and math.pi or -math.pi)*2,
            --         -- progressFunc=function(x)return math.sin(math.pi*20*x) end
            --     }
            --     Event.EaseEvent{
            --         obj=cir,
            --         easeTime=5,
            --         aimTable=cir,
            --         aimKey='speed',
            --         aimValue=20
            --     }
            -- end

        }}
        Event{
            obj=a,
            executeFunc=function(self)
                a.angle=(a.angle+a.time/50)%(2*math.pi)
            end
        }
        -- e1=Event.LoopEvent{
        --     obj=a,
        --     time=5,
        --     period=5,
        --     conditionFunc=function()return true end,
        --     executeFunc=function(self)
        --         a.angle=math.eval('3.14+3.14')
        --         a.spawnEvent.time=0
        --         a.spawnEvent.period=0.2
        --         e3=Event.EaseEvent{
        --             obj=a,
        --             easeTime=2,
        --             aimTable=a,
        --             aimKey='bulletSpeed',
        --             aimValue=50,
        --         }
        --     end
        -- }
        -- e2=Event.LoopEvent{
        --     obj=a,
        --     time=3,
        --     period=5,
        --     conditionFunc=function()return true end,
        --     executeFunc=function(self)
        --         a.spawnEvent.period=5
        --         a.bulletSpeed=40
        --     end
        -- }
        local b=BulletSpawner{x=400,y=100,period=4000,time=2,lifeTime=100,bulletNumber=30,bulletSpeed=6,bulletSize=0.75,bulletSprite=BulletSprites.kunai.gray,bulletEvents={
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
        player=Player(400,300)
    end
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
    
end
KeyboardPressed={up=false,down=false,left=false,right=false,z=false,x=false}
function love.keyreleased(key)
    KeyboardPressed[key]=false
end
-- return true if current frame is the first frame that key be pressed down
function isPressed(key)
    return love.keyboard.isDown(key)and (KeyboardPressed[key]==false)-- or KeyboardPressed[key]==nil)
end
function love.update(dt)
    -- dt=1/60
    -- Rectangle:updateAll(dt)
    BulletBatch:clear()
    BulletSpawner:updateAll(dt)
    Circle:updateAll(dt)
    Player:updateAll(dt)
    Event:updateAll(dt)
    BulletBatch:flush()
    G:update(dt)
    for key, value in pairs(KeyboardPressed) do
        if love.keyboard.isDown(key) then
            KeyboardPressed[key]=true
        end
    end
end

function love.draw()
    G:draw()
    love.graphics.draw(BulletBatch)
    --     love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
    Rectangle:drawAll()
    Circle:drawAll()
    PolyLine:drawAll()
    PolyLine.drawAll(BulletSpawner) -- a fancy way to call BulletSpawner:drawAll()
    Player:drawAll()
end