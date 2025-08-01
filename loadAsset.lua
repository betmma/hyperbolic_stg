local Asset={}
---@alias color string
---@class spriteData
---@field size number|nil if size is defined, sizeX and sizeY will be set to this value
---@field sizeX number sprite size in pixels
---@field sizeY number
---@field centerX number (hitbox) center x of the sprite. defaulted to sizeX/2
---@field centerY number center y of the sprite
---@field hitRadius number?
---@field color color?
---@field key string key in Asset.bulletSprites like "round"
---@field isLaser boolean? if the sprite is laser (needs different drawing method) 
---@field isGIF boolean? if the sprite is gif (circle.lua will copy table, randomize initial frame and call update for it)
---@field possibleColors color[]?

---@class love.Quad

---@class Sprite:Object
---@field quad love.Quad when drawing, use like love.graphics.draw(sprite.quad, ...)
---@field data spriteData
local Sprite=Object:extend()
Asset.Sprite=Sprite

---@param quad love.Quad
---@param data spriteData
function Sprite:new(quad,data)
    data.sizeX=data.size or data.sizeX
    data.sizeY=data.size or data.sizeY
    data.centerX=data.centerX or data.sizeX/2
    data.centerY=data.centerY or data.sizeY/2
    self.quad=quad
    self.data=data
end

---@class GIFSprite:Sprite
---@field private quads love.Quad[]
---@field private currentFrame number
---@field private frameTime number 
---@field private switchCountin number 
local GIFSprite=Sprite:extend()
Asset.GIFSprite=GIFSprite

--- @param quads love.Quad[] array of quads, each quad is a frame of the gif
--- @param data spriteData
function GIFSprite:new(quads,data)
    data.isGIF=true
    self.currentFrame=data.currentFrame or 1
    GIFSprite.super.new(self,quads[self.currentFrame],data)
    self.quads=quads
    self.frameTime=data.frameTime or 1
    self.switchCounting=0
end

--- Important reason of why don't naming it update: Such object inheriting Object is removed in G.removeAll which calls Object:removeAll when entering or exiting level (remove an object only removes it from Class.objects. :remove is not a garbage collector lol so the object is still usable), so Object.updateAll won't find this object and won't call it automatically. To avoid confusion, we name it countDown instead of update. It's called in circle.lua.
function GIFSprite:countDown()
    self.switchCounting=self.switchCounting+1
    if self.switchCounting>=self.frameTime then
        self.switchCounting=0
        self.currentFrame=self.currentFrame%#self.quads+1
        self.quad=self.quads[self.currentFrame]
    end
end

local randomSeed=0
function GIFSprite:randomizeCurrentFrame()
    self.currentFrame=math.ceil(math.pseudoRandom(randomSeed)*#self.quads)
    randomSeed=(randomSeed+1)%99999
    self.quad=self.quads[self.currentFrame]
end


local bulletImage = love.graphics.newImage( "assets/bullets.png" )
Asset.bulletImage=bulletImage
bulletImage:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles

local hitRadius={laser=4,scale=2.4,rim=2.4,round=4,rice=2.4,kunai=2.4,crystal=2.4,bill=2.8,bullet=2.4,blackrice=2.4,star=4,darkdot=2.4,dot=2.4,bigStar=7,bigRound=8.5,butterfly=7,knife=6,ellipse=7,fog=8.5,heart=10,giant=14,lightRound=14,hollow=2.4,flame=6,orb=6,moon=60,nuke=96,explosion=38}
Asset.hitRadius=hitRadius
love.filesystem.load('loadBulletSprites.lua')(Asset)
Asset.spectrum1MapSpectrum2={white='gray',gray='gray',red='red',orange='red',yellow='yellow',green='green',teal='green',cyan='blue',blue='blue',purple='purple',magenta='purple',black='gray'}

local bgImage = love.graphics.newImage( "assets/bg.png" )
Asset.backgroundImage=bgImage
Asset.backgroundLeft=love.graphics.newQuad(0,0,150,bgImage:getHeight(),bgImage:getWidth(),bgImage:getHeight())
Asset.backgroundRight=love.graphics.newQuad(650,0,150,bgImage:getHeight(),bgImage:getWidth(),bgImage:getHeight())
local titleImage = love.graphics.newImage( "assets/title.png" )
Asset.title=love.graphics.newQuad(0,0,1280,720,titleImage:getWidth(),titleImage:getHeight())

-- load player sprite
local playerImage = love.graphics.newImage( "assets/player.png" )
Asset.player={
    normal={},
    moveTransition={left={},right={}},
    moving={left={},right={}},
} -- each sprite is 32x48
local playerWidth,playerHeight=32,48
Asset.player.width=playerWidth
Asset.player.height=playerHeight
for i=1,8 do
    Asset.player.normal[i]=love.graphics.newQuad((i-1)*playerWidth,0,playerWidth,playerHeight,playerImage:getWidth(),playerImage:getHeight())
end
for i=1,4 do
    Asset.player.moveTransition.left[i]=love.graphics.newQuad((i-1)*playerWidth,playerHeight,playerWidth,playerHeight,playerImage:getWidth(),playerImage:getHeight())
    Asset.player.moveTransition.right[i]=love.graphics.newQuad((i-1)*playerWidth,playerHeight*2,playerWidth,playerHeight,playerImage:getWidth(),playerImage:getHeight())
end
for i=1,4 do
    Asset.player.moving.left[i]=love.graphics.newQuad((i-1+4)*playerWidth,playerHeight,playerWidth,playerHeight,playerImage:getWidth(),playerImage:getHeight())
    Asset.player.moving.right[i]=love.graphics.newQuad((i-1+4)*playerWidth,playerHeight*2,playerWidth,playerHeight,playerImage:getWidth(),playerImage:getHeight())
end

local fairyImage = love.graphics.newImage( "assets/fairy.png" )
Asset.fairyImage=fairyImage
Asset.fairyColors={'red','blue','green','orange','purple','white','black'}
Asset.fairy={}
local fairyWidth,fairyHeight=32,32
Asset.fairy.width=fairyWidth
Asset.fairy.height=fairyHeight
for i,color in pairs(Asset.fairyColors) do
    Asset.fairy[color]={key='fairy',normal={},moveTransition={},moving={}}
    for j=1,9 do
        local type='normal'
        if j==5 then
            type='moveTransition'
        elseif j>5 then
            type='moving'
        end
        Asset.fairy[color][type][#Asset.fairy[color][type]+1]=love.graphics.newQuad((j-1)*fairyWidth,(i-1)*fairyHeight,fairyWidth,fairyHeight,fairyImage:getWidth(),fairyImage:getHeight())
    end
end
--[[
Batches are used to seperate different draw layers. Generally, order should be:

Background (backgroundPattern class)
Enemy with HP bar (boss)
Player bullets
Player
Enemy without HP bar
Items (niy)
Enemy bullets highlighted (add blend mode)
Enemy bullets
Effects
Player spell (niy)
Player focus 
UI (left half and right half foreground)
Dialogue (niy)
Dialogue Characters (niy)
]]
Asset.titleBatch=love.graphics.newSpriteBatch(titleImage,1,'stream') -- title screen

Asset.fairyBatch=love.graphics.newSpriteBatch(fairyImage,100,'stream')
Asset.playerBatch=love.graphics.newSpriteBatch(playerImage, 5,'stream')
Asset.playerBulletBatch=love.graphics.newSpriteBatch(bulletImage, 2000,'stream')
Asset.bigBulletMeshes={}
Asset.bulletHighlightBatch = love.graphics.newSpriteBatch(bulletImage, 2000,'stream')
Asset.laserMeshes={}
Asset.bulletBatch = love.graphics.newSpriteBatch(bulletImage, 2000,'stream')
Asset.effectBatch=love.graphics.newSpriteBatch(bulletImage, 2000,'stream')
Asset.playerFocusBatch=love.graphics.newSpriteBatch(bulletImage, 5,'stream')
Asset.foregroundBatch=love.graphics.newSpriteBatch(bgImage,5,'stream')
Asset.Batches={
    Asset.fairyBatch,
    Asset.playerBatch,
    Asset.playerBulletBatch,
    Asset.bigBulletMeshes,
    Asset.bulletHighlightBatch,
    Asset.laserMeshes,
    Asset.bulletBatch,
    Asset.effectBatch,
    Asset.playerFocusBatch,
    -- G.afterExtraDraw here, not an element of batches
    Asset.foregroundBatch,
}
local isHighlightBatch={}
isHighlightBatch[Asset.bigBulletMeshes]=true
isHighlightBatch[Asset.bulletHighlightBatch]=true
isHighlightBatch[Asset.laserMeshes]=true
Asset.clearBatches=function(self)
    for key, batch in pairs(self.Batches) do
        if type(batch)=='table' then -- laser batch that is actually a table of laser meshes
            for key in pairs(batch) do
                batch[key] = nil
            end
        else
            batch:clear()
        end
    end
end
Asset.flushBatches=function(self)
    for key, batch in pairs(self.Batches) do
        if batch.flush then
            batch:flush()
        end
    end
end
Asset.setHyperbolicRotateShader=function()
    if not (G.viewMode.mode==G.VIEW_MODES.FOLLOW and G.UseHypRotShader) then
        return
    end
    local object=G.viewMode.object
    local shader=G.hyperbolicRotateShader
    love.graphics.setShader(shader)
    shader:send("player_pos", {object.x, object.y})
    shader:send("aim_pos", {WINDOW_WIDTH/2+G.viewOffset.x, WINDOW_HEIGHT/2+G.viewOffset.y})
    shader:send("rotation_angle",0)
    shader:send("shape_axis_y", Shape.axisY)
    shader:send("hyperbolic_model", G.viewMode.hyperbolicModel)
    shader:send("r_factor", G.DISK_RADIUS_BASE[G.viewMode.hyperbolicModel] or 1)
end
Asset.drawBatches=function(self)
    for key, batch in pairs(self.Batches) do
        -- use hyperbolicRotateShader from fairyBatch to playerFocusBatch. Note that some levels have their own shader, levels need to set G.UseHypRotShader to false to prevent being overridden
        if G.viewMode.mode==G.VIEW_MODES.FOLLOW and G.UseHypRotShader then
            local object=G.viewMode.object
            local shader=G.hyperbolicRotateShader
            if batch==Asset.fairyBatch then 
                Asset.setHyperbolicRotateShader()
            end
            if batch==Asset.playerFocusBatch or batch==Asset.playerBatch then -- player and focus are not rotated
                shader:send("rotation_angle",0)
            else
                shader:send("rotation_angle",-object.naturalDirection)
            end
        end
        if G.viewMode.mode==G.VIEW_MODES.FOLLOW and batch==Asset.foregroundBatch then
            love.graphics.push()
            love.graphics.origin()
        end
        if isHighlightBatch[batch] then
            love.graphics.setBlendMode("add")
        end
        if type(batch)=='table' then -- laser batch that is actually a table of laser meshes
            for i, mesh in pairs(batch) do
                love.graphics.draw(mesh)
            end
        else
            love.graphics.draw(batch)
        end
        love.graphics.setBlendMode('alpha') -- default mode
        if G.viewMode.mode==G.VIEW_MODES.FOLLOW and batch==Asset.playerFocusBatch and G.UseHypRotShader then
            love.graphics.setShader()
        end
        if G.viewMode.mode==G.VIEW_MODES.FOLLOW and batch==Asset.foregroundBatch then
            love.graphics.pop()
        end
        if batch==Asset.playerFocusBatch then
            if G.extraAfterDraw then
                G.extraAfterDraw()
            end
        end
    end
end


local upgradeIconsImage = love.graphics.newImage( "assets/upgrades.png" )
local upgradeSize,upgradeGap=30,32
Asset.upgradeIcons={}
Asset.upgradeIconsImage=upgradeIconsImage
for x=0,7 do
    Asset.upgradeIcons[x]={}
    for y=0,3 do
        Asset.upgradeIcons[x][y]=love.graphics.newQuad(x*upgradeGap,y*upgradeGap,upgradeSize,upgradeSize,upgradeIconsImage:getWidth(),upgradeIconsImage:getHeight())
    end
end
Asset.upgradeSize=30
return Asset