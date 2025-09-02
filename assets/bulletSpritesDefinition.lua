local Asset=...
-- below is for IDE hinting
---@class spectrum
---@field white Sprite
---@field gray Sprite
---@field red Sprite
---@field orange Sprite
---@field yellow Sprite
---@field green Sprite
---@field teal Sprite
---@field cyan Sprite
---@field blue Sprite
---@field purple Sprite
---@field magenta Sprite
---@field black Sprite

---@class spectrum2
---@field gray Sprite
---@field red Sprite
---@field yellow Sprite
---@field green Sprite
---@field blue Sprite
---@field magenta Sprite

---@alias AssetBulletSpritesCollection { \
---laser: spectrum, round: spectrum, rim: spectrum, rice: spectrum, bill: spectrum, kunai: spectrum, scale: spectrum, bullet: spectrum, bulletFog: spectrum, crystal: spectrum, star: spectrum, rain: spectrum, diamond: spectrum, coin: spectrum, cross: spectrum, crossDark: spectrum, crossLight: spectrum, \
---laserDark: spectrum, roundDark: spectrum, rimDark: spectrum, blackrice: spectrum, billDark: spectrum, kunaiDark: spectrum, scaleDark: spectrum, bulletDark: spectrum, bulletFogDark: spectrum, crystalDark: spectrum, starDark: spectrum, rainDark: spectrum, \
---ellipse: spectrum, knife: spectrum, arrow: spectrum, \
---dot: spectrum, darkdot: spectrum, \
---bigRound: spectrum, bigStar: spectrum, heart: spectrum, flower: spectrum, magatama: spectrum, haniwa: spectrum, orb: spectrum, \
---giant: spectrum, lightRound: spectrum, largeOrb: spectrum, largeMagatama: spectrum, \
---lotus: spectrum2, darkLotus: spectrum2, explosion: spectrum2, shockwave: spectrum2, \
---butterfly: spectrum, flame: spectrum, human: spectrum, dog: spectrum, dogMirrored: spectrum, bird: spectrum, frog: spectrum, note: spectrum, \
---snake: spectrum, \
---rest: spectrum, \
---stick: spectrum, stickBlack: spectrum, stone: spectrum, egg: spectrum, fog: spectrum, \
---moon: Sprite, anchor: Sprite, playerFocus: Sprite, \
---nuke: Sprite}

---@type AssetBulletSpritesCollection
Asset.bulletSprites={}

local loaders=Asset.bulletSpriteLoaders
local single,gifSingle,spectrum,matrix,simpleOffsetFunc,setCenterPosition=loaders.single,loaders.gifSingle,loaders.spectrum,loaders.matrix,loaders.simpleOffsetFunc,loaders.setCenterPosition
local names16x16={'laser','round','rim','rice','bill','kunai','scale','bullet','bulletFog','crystal','star','rain','coin','cross','crossDark','crossRim','crossDarkRim'}
local colors={'white','gray','red','orange','yellow','green','teal','cyan','blue','purple','magenta','black'}
Asset.colors=colors
matrix{
    unit=single{sizeX=16,sizeY=16},
    names=names16x16,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,16),
    colorOffsetFunc=simpleOffsetFunc(16,0),
    baseX=0,baseY=0,
}:addToAsset()
local names16x16_2={'laserDark','roundDark','rimDark','blackrice','billDark','kunaiDark','scaleDark','bulletDark','bulletFogDark','crystalDark','starDark','rainDark'}
matrix{
    unit=single{sizeX=16,sizeY=16},
    names=names16x16_2,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,16),
    colorOffsetFunc=simpleOffsetFunc(16,0),
    baseX=16*12,baseY=0,
}:addToAsset()
local names16x32={'ellipse','knife','arrow'}
matrix{
    unit=single{sizeX=16,sizeY=32},
    names=names16x32,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,32),
    colorOffsetFunc=simpleOffsetFunc(16,0),
    baseX=0,baseY=16*17,
}:addToAsset()
setCenterPosition('arrow',8,6)
local names8x8={'dot','darkdot'}
matrix{
    unit=single{sizeX=8,sizeY=8},
    names=names8x8,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,8),
    colorOffsetFunc=simpleOffsetFunc(8,0),
    baseX=0,baseY=16*17+3*32,
}:addToAsset()
local names32x32={'bigRound','bigStar','heart','flower','magatama','haniwa','orb'}
matrix{
    unit=single{sizeX=32,sizeY=32},
    names=names32x32,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,32),
    colorOffsetFunc=simpleOffsetFunc(32,0),
    baseX=16*24,baseY=0,
}:addToAsset()
local names64x64={'giant','lightRound','largeOrb','largeMagatama'}
matrix{
    unit=single{sizeX=64,sizeY=64},
    names=names64x64,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(64,0),
    colorOffsetFunc=simpleOffsetFunc(0,64),
    baseX=16*24+32*12,baseY=0,
}:addToAsset()
local names128x128={'lotus','darkLotus','explosion','shockwave'}
local colors128x128={'gray','red','yellow','green','blue','magenta'}
matrix{
    unit=single{sizeX=128,sizeY=128},
    names=names128x128,colors=colors128x128,
    nameOffsetFunc=simpleOffsetFunc(128,0),
    colorOffsetFunc=simpleOffsetFunc(0,128),
    baseX=1024,baseY=0,
}:addToAsset()
local namesGIF32x32={'butterfly','flame','human','dog','dogMirrored','bird','frog','note'}
matrix{
    unit=gifSingle{sizeX=32,sizeY=32,frameCount=3,frameTime=10,frameOffsetFunc=simpleOffsetFunc(0,32)},
    names=namesGIF32x32,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,32*3),
    colorOffsetFunc=simpleOffsetFunc(32,0),
    baseX=16*24,baseY=32*7,
}:addToAsset()
setCenterPosition('flame',16,12)
setCenterPosition('note',16,25)
spectrum{
    unit=gifSingle{sizeX=16,sizeY=112,frameCount=3,frameTime=10,frameOffsetFunc=simpleOffsetFunc(0,112),name='snake'},
    colors=colors,
    offsetFunc=simpleOffsetFunc(16,0),
    baseX=16*12,baseY=16*19
}:addToAsset()
spectrum{
    unit=single{sizeX=32,sizeY=32,name='rest'},
    colors=colors,
    offsetFunc=simpleOffsetFunc(32,0),
    baseX=16*24,baseY=32*31,
}:addToAsset()
matrix{
    unit=single{sizeX=32,sizeY=32},
    names={'stick','stickBlack','stone','egg','fog'},colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,32),
    colorOffsetFunc=simpleOffsetFunc(32,0),
    baseX=0,baseY=32*27,
}:addToAsset()
single{
    sizeX=128,sizeY=128,name='moon',
    baseX=16*24+32*12,baseY=64*12,
}:addToAsset()
single{
    sizeX=128,sizeY=128,name='anchor',
    baseX=16*24+32*12+128,baseY=64*12,
}:addToAsset()
single{
    sizeX=256,sizeY=256,name='nuke',
    baseX=1280,baseY=768,
}:addToAsset()
single{
    sizeX=64,sizeY=64,name='playerFocus',
    baseX=0,baseY=496,
}:addToAsset()

-- some old names mapping
Asset.shards={dot=Asset.bulletSprites.dot.white,round=Asset.bulletSprites.fog.white}
-- Asset.bulletSprites.nuke=Asset.bulletSprites.moon

-- still need: nuke, vortex. shockwave and misc.smallShockwave should be remapped to shockwave