local Asset={}
local bulletImage = love.graphics.newImage( "assets/bullets.png" )
Asset.bulletImage=bulletImage
bulletImage:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles

local tileSize = 8
local function quad(x,y,width,height)
    local ret= love.graphics.newQuad(x*tileSize+5,y*tileSize+6,width*tileSize,height*tileSize,bulletImage:getWidth(),bulletImage:getHeight())
    return ret
end
local template={
    gray=...,red=...,purple=...,blue=...,cyan=...,green=...,yellow=...,orange=...,
}
Asset.playerFocus=quad(34,2,8,8)
Asset.shockwave={
    red=quad(50,2,8,8),
    blue=quad(58,2,8,8),
    yellow=quad(34,10,8,8),
    green=quad(42,10,8,8),
}
Asset.misc={
    leaf=quad(34,28,4,4),
    leafRed=quad(38,28,4,4),
    smallShockwave=quad(42,28,4,4),
    vortex=quad(46,28,4,4),
    furBall=quad(50,28,4,4),
}
Asset.shards={
    leaf =quad(63.625,49.25,1,1),
    drop =quad(64.625,49.25,1,1),
    round=quad(65.625,49.25,1,1),
    dot  =quad(66.625,49.25,1,1),
}
Asset.nuke=love.graphics.newQuad(306,547,256,256,bulletImage:getWidth(),bulletImage:getHeight())
Asset.bulletSprites={
    nuke=Asset.nuke,
    laser=template,
    scale=template,
    rim=template,
    round=template,
    rice=template,
    kunai=template,
    crystal=template,
    bill=template,
    bullet=template,
    blackrice=template,
    star=template,
    darkdot=template,
    dot=template,
    bigStar=template,
    bigRound=template,
    butterfly=template,
    knife=template,
    ellipse=template,
    fog=template,
    heart=template,
    giant={
        red=...,blue=...,green=...,yellow=...,
    },
    hollow={
        grey=...,red=...,blue=...,green=...,yellow=...,
    }
}
Asset.SpriteData={
}
Asset.SpriteData[Asset.nuke]={size=256,hitRadius=96}
for k,wave in pairs(Asset.shockwave) do
    Asset.SpriteData[wave]={size=64}
end
for k,misc in pairs(Asset.misc) do
    Asset.SpriteData[misc]={size=32,hitRadius=6}
end
for k,shard in pairs(Asset.shards) do
    Asset.SpriteData[shard]={size=8}
end
local hitRadius={laser=4,scale=2.4,rim=2.4,round=4,rice=2.4,kunai=2.4,crystal=2.4,bill=2.8,bullet=2.4,blackrice=2.4,star=4,darkdot=2.4,dot=2.4,bigStar=7,bigRound=8.5,butterfly=7,knife=6,ellipse=7,fog=8.5,heart=10,giant=14,hollow=2.4}
local colors={'gray','red','purple','blue','cyan','green','yellow','orange'}
Asset.colors=colors
local types={'laser','scale','rim','round','rice','kunai','crystal','bill','bullet','blackrice','star'}
for i, value in ipairs(types) do
    Asset.bulletSprites[value]={}
    for j,color in ipairs(colors) do
        Asset.bulletSprites[value][color]=quad(4*j-4,2*i-2,2,2)
        Asset.SpriteData[Asset.bulletSprites[value][color]]={size=16,hitRadius=hitRadius[value],color=color,super=Asset.bulletSprites[value],laser=value=='laser',possibleColors=colors}
    end
end
types={'darkdot','dot'}
for i, value in ipairs(types) do
    Asset.bulletSprites[value]={}
    for j,color in ipairs(colors) do
        Asset.bulletSprites[value][color]=quad(2*((j-1)%4),18+6*i+(j>4 and 1 or 0),1,1)
        Asset.SpriteData[Asset.bulletSprites[value][color]]={size=8,hitRadius=hitRadius[value],color=color,super=Asset.bulletSprites[value],possibleColors=colors}
    end
end
types={'bigStar','bigRound','butterfly','knife','ellipse','fog',}
for i, value in ipairs(types) do
    Asset.bulletSprites[value]={}
    for j,color in ipairs(colors) do
        Asset.bulletSprites[value][color]=quad(4*j-4,29+4*i+0.5,4,4)
        Asset.SpriteData[Asset.bulletSprites[value][color]]={size=32,hitRadius=hitRadius[value],color=color,super=Asset.bulletSprites[value],possibleColors=colors}
    end
end
types={'heart'}
for i, value in ipairs(types) do
    Asset.bulletSprites[value]={}
    for j,color in ipairs(colors) do
        Asset.bulletSprites[value][color]=quad(30+4*j,29+4*i+0.5,4,4)
        Asset.SpriteData[Asset.bulletSprites[value][color]]={size=32,hitRadius=hitRadius[value],color=color,super=Asset.bulletSprites[value],possibleColors=colors}
    end
end
types={'giant'}
local colors2={'red','blue','green','yellow'}
for i, value in ipairs(types) do
    Asset.bulletSprites[value]={}
    for j,color in ipairs(colors2) do
        Asset.bulletSprites[value][color]=quad(8*j-8,49+8*i+0.5,8,8)
        Asset.SpriteData[Asset.bulletSprites[value][color]]={size=64,hitRadius=hitRadius[value],color=color,super=Asset.bulletSprites[value],possibleColors=colors2}
    end
end
types={'hollow'}
colors2={'grey','red','blue','green','yellow'}
for i, value in ipairs(types) do
    Asset.bulletSprites[value]={}
    for j,color in ipairs(colors2) do
        Asset.bulletSprites[value][color]=quad(2*j+16,28+2*i,2,2)
        Asset.SpriteData[Asset.bulletSprites[value][color]]={size=16,hitRadius=hitRadius[value],color=color,super=Asset.bulletSprites[value],possibleColors=colors2}
    end
end
local bgImage = love.graphics.newImage( "assets/bg.png" )
Asset.backgroundImage=bgImage
Asset.backgroundLeft=love.graphics.newQuad(0,0,150,bgImage:getHeight(),bgImage:getWidth(),bgImage:getHeight())
Asset.backgroundRight=love.graphics.newQuad(650,0,150,bgImage:getHeight(),bgImage:getWidth(),bgImage:getHeight())
local titleImage = love.graphics.newImage( "assets/title.png" )
Asset.title=love.graphics.newQuad(0,0,1280,720,titleImage:getWidth(),titleImage:getHeight())
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

--[[
Batches are used to seperate different draw layers. Generally, order should be:

Background (backgroundPattern class)
Enemy with HP bar (boss, currently it's drawn as a circle so actually niy)
Player bullets
Player (niy)
Enemy without HP bar (probably won't appear)
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

Asset.playerBatch=love.graphics.newSpriteBatch(playerImage, 5,'stream')
Asset.playerBulletBatch=love.graphics.newSpriteBatch(bulletImage, 2000,'stream')
Asset.bulletHighlightBatch = love.graphics.newSpriteBatch(bulletImage, 2000,'stream')
Asset.laserBatch={}
Asset.bulletBatch = love.graphics.newSpriteBatch(bulletImage, 2000,'stream')
Asset.effectBatch=love.graphics.newSpriteBatch(bulletImage, 2000,'stream')
Asset.playerFocusBatch=love.graphics.newSpriteBatch(bulletImage, 5,'stream')
Asset.foregroundBatch=love.graphics.newSpriteBatch(bgImage,5,'stream')
Asset.Batches={
    Asset.playerBatch,
    Asset.playerBulletBatch,
    Asset.bulletHighlightBatch,
    Asset.laserBatch,
    Asset.bulletBatch,
    Asset.effectBatch,
    Asset.playerFocusBatch,
    Asset.foregroundBatch,
}
local isHighlightBatch={}
isHighlightBatch[Asset.bulletHighlightBatch]=true
isHighlightBatch[Asset.laserBatch]=true
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
Asset.drawBatches=function(self)
    for key, batch in pairs(self.Batches) do
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
        if G.viewMode.mode==G.VIEW_MODES.FOLLOW and batch==Asset.foregroundBatch then
            love.graphics.pop()
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