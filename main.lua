
if arg[2] == "debug" then
    require("lldebugger").start()
end
io.stdout:setvbuf("no")
require'misc'
function love.load()
    Object = require "classic"
    Shape = require "shape"
    Circle = require "circle"
    Laser=require"laser"
    PolyLine = require "polyline"
    Player = require "player"
    Event= require "event"
    BulletSpawner=require"bulletSpawner"
    Enemy=require"enemy"
    Asset=require"loadAsset"
    Audio=require"audio"
    SFX=Audio.sfx;BGM=Audio.bgm
    Effect=require"effect"
    BulletSprites,BulletBatch,SpriteData=Asset.bulletSprites,Asset.bulletBatch,Asset.SpriteData
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
function love.keyreleased(key)
    KeyboardPressed[key]=false
end
-- return true if current frame is the first frame that key be pressed down
function isPressed(key)
    return love.keyboard.isDown(key)and (KeyboardPressed[key]==false)-- or KeyboardPressed[key]==nil)
end
local sleepTime=1/60
function love.update(dt)
    love.timer.sleep(sleepTime-dt)
    local fps=love.timer.getFPS()
    local newTime=sleepTime*fps/60
    sleepTime=0.995*(sleepTime-newTime)+newTime
    dt=1/60
    -- Rectangle:updateAll(dt)
    G:update(dt)
    for key, value in pairs(KeyboardPressed) do
        if love.keyboard.isDown(key) then
            KeyboardPressed[key]=true
        end
    end
end

function love.draw()
    G:draw()
end