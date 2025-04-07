VERSION="0.3.2.2"
WINDOW_WIDTH,WINDOW_HEIGHT=love.graphics.getDimensions()
if arg[2] == "debug" then
    require("lldebugger").start()
end
io.stdout:setvbuf("no")
love.window.setTitle('Hyperbolic STG')
require'misc'
function love.load()
    Object = require "classic"
    Shape = require "shape"
    Circle = require "circle"
    Laser=require"laser"
    PolyLine = require "polyline"
    Event= require "event"
    BulletSpawner=require"bulletSpawner"
    Enemy=require"enemy"
    Asset=require"loadAsset"
    Audio=require"audio"
    SFX=Audio.sfx;BGM=Audio.bgm
    Effect=require"effect"
    BulletSprites,BulletBatch,SpriteData=Asset.bulletSprites,Asset.bulletBatch,Asset.SpriteData
    Player = require "player"
    G=require"state"
    BGM:play('title')
    ScreenshotManager=require"screenshotManager"
    ReplayManager=require"replayManager"
end
local keyConstants='1234567890-=qwertyuiop[]\\asdfghjkl;\'zxcvbnm,./`'
KeyboardPressed={up=false,down=false,left=false,right=false,escape=false,lctrl=false}
for i=1,#keyConstants do
    KeyboardPressed[keyConstants:sub(i,i)]=false
end
for i=0,9 do
    KeyboardPressed['kp'..i]=false
end
function love.keyreleased(key)
    KeyboardPressed[key]=false
end
-- return true if current frame is the first frame that key be pressed down
function isPressed(key)
    return love.keyboard.isDown(key)and (KeyboardPressed[key]==false)-- or KeyboardPressed[key]==nil)
end
local controlFPSmode=0
local sleepTime=1/60
local frameTime=1/60
AccumulatedTime=0
function love.update(dt)
    if controlFPSmode==0 then
        AccumulatedTime=AccumulatedTime+dt
        AccumulatedTime=math.min(AccumulatedTime,frameTime*5)
        if AccumulatedTime>=frameTime then
            AccumulatedTime=AccumulatedTime-frameTime
            dt=1/60
            G:update(dt)
            for key, value in pairs(KeyboardPressed) do
                if love.keyboard.isDown(key) then
                    KeyboardPressed[key]=true
                end
            end
        end
    elseif controlFPSmode==1 then
        love.timer.sleep(sleepTime-dt)
        local fps=love.timer.getFPS()
        local newTime=sleepTime*fps/60
        sleepTime=0.995*(sleepTime-newTime)+newTime
        dt=1/60
        G:update(dt)
        for key, value in pairs(KeyboardPressed) do
            if love.keyboard.isDown(key) then
                KeyboardPressed[key]=true
            end
        end
    
    end
    -- love.timer.sleep(sleepTime-dt)
    -- local fps=love.timer.getFPS()
    -- local newTime=sleepTime*fps/60
    -- sleepTime=0.995*(sleepTime-newTime)+newTime
end

function love.draw()
    G:draw()
    -- for i = 50, 600, 50 do
    -- if CIM then
    --     local x0,y0,x1,y1=Player.objects[1].x,Player.objects[1].y,CIM.x,CIM.y
    --     local ang=0.0
    --     local r,theta=Shape.distance(x0,y0,x1,y1),Shape.to(x0,y0,x1,y1)
    --     local nx,ny=Shape.rThetaPos(x0,y0,r,theta+ang)
    --     love.graphics.print(r..', '..theta,300,100)
    --     love.graphics.print(nx..', '..ny,300,130)
    -- end
end