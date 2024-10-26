
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
    
end
KeyboardPressed={up=false,down=false,left=false,right=false,z=false,x=false,escape=false}
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