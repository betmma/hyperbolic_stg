VERSION="0.4.1.2"
WINDOW_WIDTH,WINDOW_HEIGHT=love.graphics.getDimensions()
if arg[2] == "debug" then
    require("lldebugger").start()
end
io.stdout:setvbuf("no")
love.window.setTitle('Hyperbolic STG')
require'misc'

local input = require "input"
function love.load()
    Object = require "classic"
    Shape = require "shape"
    require "shapeFunctions"
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
    LevelData = require "levelData"
    G=require"state"
    BGM:play('title')
    ScreenshotManager=require"screenshotManager"
    ReplayManager=require"replayManager"
end
function love.keypressed(key, scancode, isrepeat)
    input.keypressed(key, scancode, isrepeat)
end
-- return true if current frame is the first frame that key be pressed down
isPressed=input.isKeyJustPressed

local profiExists=pcall(require,"profi") -- lib that log functions call and time spent to optimize code
local profi
if profiExists then
    profi=require"profi"
end
local profiActivate=false

local controlFPSmode=0
local sleepTime=1/60
local frameTime=1/60
AccumulatedTime=0
function love.update(dt)
    input.update()
    if profi then
        profiActivate=isPressed('f3')
        if profiActivate then
            profi:start('once')
        end
    end
    if controlFPSmode==0 then
        AccumulatedTime=AccumulatedTime+dt
        AccumulatedTime=math.min(AccumulatedTime,frameTime*5)
        if AccumulatedTime>=frameTime then
            AccumulatedTime=AccumulatedTime-frameTime
            dt=1/60
            G:update(dt)
        end
    elseif controlFPSmode==1 then
        love.timer.sleep(sleepTime-dt)
        local fps=love.timer.getFPS()
        local newTime=sleepTime*fps/60
        sleepTime=0.995*(sleepTime-newTime)+newTime
        dt=1/60
        G:update(dt)
    end
    -- love.timer.sleep(sleepTime-dt)
    -- local fps=love.timer.getFPS()
    -- local newTime=sleepTime*fps/60
    -- sleepTime=0.995*(sleepTime-newTime)+newTime
    if profi and love.keyboard.isDown('f4') then
        profi:stop()
        profi:writeReport( 'MyProfilingReport.txt' )
    end
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