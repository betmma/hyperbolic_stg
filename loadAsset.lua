local Asset={}
local tilesetImage = love.graphics.newImage( "assets/bullets.png" )
tilesetImage:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles
local tileSize = 8
local function quad(x,y,width,height)
    local ret= love.graphics.newQuad(x*tileSize+5,y*tileSize+6,width*tileSize,height*tileSize,tilesetImage:getWidth(),tilesetImage:getHeight())
    return ret
end
local template={
    gray=...,red=...,purple=...,blue=...,cyan=...,green=...,yellow=...,orange=...,
}
Asset.playerFocus=quad(34,2,8,8)
Asset.shockwave={
    red=quad(50,2,8,8),
    blue=quad(58,2,8,8),
    yellow=quad(50,10,8,8),
    green=quad(58,10,8,8),
}
Asset.shards={
    leaf =quad(63.625,49.625,1,1),
    drop =quad(64.625,49.625,1,1),
    round=quad(65.625,49.625,1,1),
    dot  =quad(66.625,49.625,1,1),
}
Asset.bulletSprites={
    scale=template,
    rim=template,
    round=template,
    rice=template,
    kunai=template,
    crystal=template,
    bill=template,
    bullet=template,
    blackheart=template,
    star=template,
    darkdot=template,
    dot=template
}
Asset.SpriteData={
}
for k,wave in pairs(Asset.shockwave) do
    Asset.SpriteData[wave]={size=64}
end
for k,wave in pairs(Asset.shards) do
    Asset.SpriteData[wave]={size=8}
end
local hitRadius={scale=2.4,rim=2.4,round=4,rice=2.4,kunai=2.4,crystal=2.4,bill=2.8,bullet=2.4,blackheart=2.4,star=4,darkdot=2.4,dot=2.4}
local colors={'gray','red','purple','blue','cyan','green','yellow','orange'}
local types={'scale','rim','round','rice','kunai','crystal','bill','bullet','blackheart','star'}
for i, value in ipairs(types) do
    Asset.bulletSprites[value]={}
    for j,color in ipairs(colors) do
        Asset.bulletSprites[value][color]=quad(4*j-4,2*i,2,2)
        Asset.SpriteData[Asset.bulletSprites[value][color]]={size=16,hitRadius=hitRadius[value]}
    end
end
types={'darkdot','dot'}
for i, value in ipairs(types) do
    Asset.bulletSprites[value]={}
    for j,color in ipairs(colors) do
        Asset.bulletSprites[value][color]=quad(2*((j-1)%4),18+6*i+(j>4 and 1 or 0),1,1)
        Asset.SpriteData[Asset.bulletSprites[value][color]]={size=8,hitRadius=hitRadius[value]}
    end
end
--[[
Batches are used to seperate different draw layers. Generally, order should be:

Background (not implemented yet (niy))
Enemy with HP bar (boss)
Player bullets (currently in Enemy bullets batch)
Player
Enemy without HP bar (probably won't appear)
Items (niy)
Enemy bullets
Effects (now only shockwave)
Player spell (niy)
Player focus (currently in Enemy bullets batch)
UI (niy)
Dialogue (niy)
Dialogue Characters (niy)
]]
Asset.bulletBatch = love.graphics.newSpriteBatch(tilesetImage, 2000,'stream')
Asset.effectBatch=love.graphics.newSpriteBatch(tilesetImage, 2000,'stream')
Asset.Batches={Asset.bulletBatch,Asset.effectBatch}
Asset.clearBatches=function(self)
    for key, batch in pairs(self.Batches) do
        batch:clear()
    end
end
Asset.flushBatches=function(self)
    for key, batch in pairs(self.Batches) do
        batch:flush()
    end
end
Asset.drawBatches=function(self)
    for key, batch in pairs(self.Batches) do
        love.graphics.draw(batch)
    end
end
return Asset