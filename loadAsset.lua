local Asset={}
local tilesetImage = love.graphics.newImage( "assets/bullets.png" )
tilesetImage:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles
local tileSize = 8
local function quad(x,y,width,height)
    return love.graphics.newQuad(x*tileSize+5,y*tileSize+6,width*tileSize,height*tileSize,tilesetImage:getWidth(),tilesetImage:getHeight())
end
Asset.bulletSprites={
    scale={
        gray=quad(2,14,2,2)
    }
}
Asset.bulletBatch = love.graphics.newSpriteBatch(tilesetImage, 2000,'stream')
return Asset