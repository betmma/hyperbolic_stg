local Asset=...
local bulletImage = Asset.bulletImage
local function quad(x,y,width,height)
    local ret= love.graphics.newQuad(x,y,width,height,bulletImage:getWidth(),bulletImage:getHeight())
    return ret
end
local function getHitRadius(name,size)
    local hitRadius=Asset.hitRadius[name]
    if not hitRadius then
        hitRadius=size/16*2.4
    end
    return hitRadius
end

---@class BulletSpriteSingle:Object
---@field name string
---@field sizeX number
---@field sizeY number
---@field baseX number
---@field baseY number
---@field getSprite fun(self):Sprite return a Sprite object based on self's data that will be added to Asset.bulletSprites. 
---@field addToAsset fun(self):nil add the sprite to Asset.bulletSprites
local BulletSpriteSingle=Object:extend()
function BulletSpriteSingle:new(args)
    self.name=args.name
    self.sizeX=args.sizeX
    self.sizeY=args.sizeY
    self.baseX=args.baseX
    self.baseY=args.baseY
end
function BulletSpriteSingle:getSprite()
    local name=self.name
    local spriteData={sizeX=self.sizeX,sizeY=self.sizeY,hitRadius=getHitRadius(name,self.sizeX),key=name,isLaser=name=='laser'or name=='laserDark'}
    return Asset.Sprite(quad(self.baseX,self.baseY,self.sizeX,self.sizeY),spriteData)
    -- Asset.SpriteData[Asset.bulletSprites[name]]=spriteData
end
function BulletSpriteSingle:addToAsset()
    local name=self.name
    Asset.bulletSprites[name]=self:getSprite()
end

---@class BulletSpriteGIFSingle:BulletSpriteSingle
---@field frameCount number
---@field frameTime number
---@field frameOffsetFunc fun(index:number):{x:number,y:number} x and y offset of each frame
local BulletSpriteGIFSingle = BulletSpriteSingle:extend()
function BulletSpriteGIFSingle:new(args)
    BulletSpriteSingle.new(self,args)
    self.frameCount=args.frameCount
    self.frameTime=args.frameTime
    self.frameOffsetFunc=args.frameOffsetFunc
end
function BulletSpriteGIFSingle:getSprite()
    local name=self.name
    local spriteData={sizeX=self.sizeX,sizeY=self.sizeY,hitRadius=getHitRadius(name,self.sizeX),key=name,isLaser=name=='laser',isGIF=true,frameCount=self.frameCount,frameTime=self.frameTime}
    local quads={}
    for i=1,self.frameCount do
        local offset=self.frameOffsetFunc(i)
        local x=offset.x or 0
        local y=offset.y or 0
        quads[i]=quad(self.baseX+x,self.baseY+y,self.sizeX,self.sizeY)
    end
    return Asset.GIFSprite(quads,spriteData)
end
function BulletSpriteGIFSingle:addToAsset()
    local name=self.name
    Asset.bulletSprites[name]=self:getSprite()
end

---@class BulletSpriteSpectrum information of a spectrum (different colors of same shape) of bullets
---@field unit BulletSpriteSingle unit:getSprite() will be called. baseXY are overridden.
---@field colors string[]
---@field offsetFunc fun(index:number):{x:number,y:number} x and y offset of each color bullet in the group
---@field baseX number
---@field baseY number
---@field getSprite fun(self):table<string,Sprite> return color:Sprite table of the group
---@field addToAsset fun(self):nil create a spectrum of assets and add it to Asset.bulletSprites.
local BulletSpriteSpectrum=Object:extend()
function BulletSpriteSpectrum:new(args)
    self.unit=args.unit
    self.colors=args.colors
    self.offsetFunc=args.offsetFunc
    self.baseX=args.baseX
    self.baseY=args.baseY
end
function BulletSpriteSpectrum:getSprite()
    local unit=self.unit
    local name=unit.name
    local colors=self.colors
    local offsetFunc=self.offsetFunc
    local sprites={}
    --Asset.bulletSprites[name]=Asset.bulletSprites[name] or {}
    for i,color in ipairs(colors) do
        local x,y=offsetFunc(i).x,offsetFunc(i).y
        unit.baseX=self.baseX+x
        unit.baseY=self.baseY+y
        local sprite=unit:getSprite()
        sprite.data.color=color
        sprite.data.possibleColors=colors
        --Asset.bulletSprites[name][color]=sprite
        sprites[color]=sprite
    end
    return sprites
end
function BulletSpriteSpectrum:addToAsset()
    local unit=self.unit
    local name=unit.name
    local colors=self.colors
    local sprites=self:getSprite()
    Asset.bulletSprites[name]=sprites
end

---@class BulletSpriteMatrix many spectrums (many types of many colors of bullets)
---@field unit BulletSpriteSingle
---@field colors string[] array of colors of the spectrums
---@field names string[] array of names of the spectrums
---@field nameOffsetFunc fun(index:number):{x:number,y:number} x and y offset of each spectrum
---@field colorOffsetFunc fun(index:number):{x:number,y:number} x and y offset of each color in the spectrum
---@field baseX number
---@field baseY number
---@field addToAsset fun(self):nil 
local BulletSpriteMatrix=Object:extend()
function BulletSpriteMatrix:new(args)
    self.unit=args.unit
    self.names=args.names
    self.colors=args.colors
    self.nameOffsetFunc=args.nameOffsetFunc
    self.colorOffsetFunc=args.colorOffsetFunc
    self.baseX=args.baseX
    self.baseY=args.baseY
end
function BulletSpriteMatrix:addToAsset()
    local unit=self.unit
    local names=self.names
    local colors=self.colors
    local nameOffsetFunc=self.nameOffsetFunc
    local colorOffsetFunc=self.colorOffsetFunc
    local baseX=self.baseX
    local baseY=self.baseY
    for i,name in ipairs(names) do
        local nameOffset=nameOffsetFunc(i)
        local x,y=nameOffset.x,nameOffset.y
        Asset.bulletSprites[name]=Asset.bulletSprites[name] or {}
        for j,color in ipairs(colors) do
            local colorOffset=colorOffsetFunc(j)
            local x2,y2=colorOffset.x,colorOffset.y
            unit.baseX=baseX+x+x2
            unit.baseY=baseY+y+y2
            unit.name=name
            local sprite=unit:getSprite()
            sprite.data.color=color
            sprite.data.possibleColors=colors
            Asset.bulletSprites[name][color]=sprite
        end
    end
end

local function simpleOffsetFunc(dx,dy)
    return function(index)
        local x=dx*(index-1)
        local y=dy*(index-1)
        return {x=x,y=y}
    end
end

-- center position not at geometry center is rare, so write a function to set it
--- @param name string name of the sprite
--- @param centerX number x of the center position
--- @param centerY number y of the center position
--- @return nil
local function setCenterPosition(name,centerX,centerY)
    local sprite=Asset.bulletSprites[name]
    if not sprite then 
        error('setCenterPosition: no sprite found for name '..name)
    end
    if type(sprite)=='table' then
        for _,s in pairs(sprite) do
            s.data.centerX=centerX
            s.data.centerY=centerY
        end
    else
        sprite.data.centerX=centerX
        sprite.data.centerY=centerY
    end
end

Asset.bulletSpriteLoaders={
    single=BulletSpriteSingle,
    gifSingle=BulletSpriteGIFSingle,
    spectrum=BulletSpriteSpectrum,
    matrix=BulletSpriteMatrix,
    simpleOffsetFunc=simpleOffsetFunc,
    setCenterPosition=setCenterPosition,
}

love.filesystem.load('assets/bulletSpritesDefinition.lua')(Asset)