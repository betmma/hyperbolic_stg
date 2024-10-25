local Asset={}
local tilesetImage = love.graphics.newImage( "assets/bullets.png" )
tilesetImage:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles
local tileSize = 8
local function quad(x,y,width,height)
    local ret= love.graphics.newQuad(x*tileSize+5,y*tileSize+6,width*tileSize,height*tileSize,tilesetImage:getWidth(),tilesetImage:getHeight())
    return ret
end
local template={
    size=16,
    gray=...,red=...,purple=...,blue=...,cyan=...,green=...,yellow=...,orange=...,
}
Asset.playerFocus=quad(34,2,8,8)
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
    star=template
}
Asset.SpriteData={
}
local types={'scale','rim','round','rice','kunai','crystal','bill','bullet','blackheart','star'}
local hitRadius={scale=2.4,rim=2.4,round=4,rice=2.4,kunai=2.4,crystal=2.4,bill=2.8,bullet=2.4,blackheart=2.4,star=4}
local colors={'gray','red','purple','blue','cyan','green','yellow','orange'}
for i, value in ipairs(types) do
    Asset.bulletSprites[value]={}
    for j,color in ipairs(colors) do
        Asset.bulletSprites[value][color]=quad(4*j-4,2*i,2,2)
        Asset.SpriteData[Asset.bulletSprites[value][color]]={size=16,hitRadius=hitRadius[value]}
    end
end
-- Asset.bulletSprites.scale.gray()
-- Asset.bulletSprites.
Asset.bulletBatch = love.graphics.newSpriteBatch(tilesetImage, 2000,'stream')
return Asset