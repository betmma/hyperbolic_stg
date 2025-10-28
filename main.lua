VERSION="0.8.9"
WINDOW_WIDTH,WINDOW_HEIGHT=love.graphics.getDimensions()
if arg[2] == "debug" then
    require("lldebugger").start()
end
io.stdout:setvbuf("no")
love.window.setTitle('Hyperbolic Domain'..' '..VERSION)
require'misc'
shove = require "import.shove"
local input = require "input"
function love.load()
    shove.setResolution(800, 600, {fitMethod = "aspect", renderMode = "layer"})
    Object,GameObject = unpack(require "classic")
    ExpandingMesh = require "import.expandingMesh"
    ---@type ShaderScan
    ShaderScan = (require 'import.shaderScan')()
    EventManager = require "eventManager"
    EM = EventManager
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
    ---@type AssetBulletSpritesCollection
    BulletSprites,BulletBatch,SpriteData=Asset.bulletSprites,Asset.bulletBatch,Asset.SpriteData
    Player = require "player"
    LevelData = require "levelData"
    DialogueController=require"localization.dialogue"
    Upgrades = require "upgrades"
    G=require"state"
    BGM:play('title')
    ScreenshotManager=require"screenshotManager"
    ReplayManager=require"replayManager"
    Nickname=require"nickname"
    Complex,Mobius=unpack(require"import.mobius")

    shove.setWindowMode(G.save.options.resolution.width,G.save.options.resolution.height, {resizable = true})
    shove.createLayer("main")
    shove.addEffect('main',Player.invertShader)
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
            input.update()
            G:update(dt)
        end
    elseif controlFPSmode==1 then
        love.timer.sleep(sleepTime-dt)
        local fps=love.timer.getFPS()
        local newTime=sleepTime*fps/60
        sleepTime=0.995*(sleepTime-newTime)+newTime
        dt=1/60
        input.update()
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
  shove.beginDraw()
    G:draw()
    shove.beginLayer('nickname')
    Nickname:drawText() -- nickname is an individual system 
    -- for i = 50, 600, 50 do
    -- if CIM then
    --     local x0,y0,x1,y1=Player.objects[1].x,Player.objects[1].y,CIM.x,CIM.y
    --     local ang=0.0
    --     local r,theta=Shape.distance(x0,y0,x1,y1),Shape.to(x0,y0,x1,y1)
    --     local nx,ny=Shape.rThetaPos(x0,y0,r,theta+ang)
    --     love.graphics.print(r..', '..theta,300,100)
    --     love.graphics.print(nx..', '..ny,300,130)
    -- end
    shove.endLayer()
  shove.endDraw()
end