local levelData=require'levelData'
local screenshotManager={}
---@class love.Image
---@class love.SpriteBatch

---@class ScreenShot
---@field image love.Image
---@field quad love.Quad
---@field zoom number -- zoom ratio of screenshot relative to 500x600. should be divided when drawing
---@field batch love.SpriteBatch
---@type ScreenShot[]
screenshotManager.data={}
local screenshotDir='screenshots'
love.filesystem.createDirectory(screenshotDir)
local function oldPath(level,scene)
    return screenshotDir..'/scr_'..level..'_'..scene..'.png'
end
local function path(id)
    return screenshotDir..'/scr_'..id..'.png'
end
local function prePath(id)
    return screenshotDir..'/scr_pre_'..id..'.png'
end
--- func description: get the quad for drawing the real area of a screenshot image
---@param image love.Image
---@return love.Quad,number zoom
local function getQuad(image)
    local width,height=image:getWidth(),image:getHeight()
    -- window size can vary, so screenshot size can vary too. the real area is 500x600 at center of viewport size 800x600
    local realWidth,realHeight=500,600
    local viewportWidth,viewportHeight=800,600
    local zoom=math.min(width/viewportWidth,height/viewportHeight)
    local xOffset=(width-viewportWidth*zoom)/2
    local yOffset=(height-viewportHeight*zoom)/2 -- the offset to viewport
    xOffset=xOffset+(viewportWidth-realWidth)/2*zoom -- the offset to real area
    yOffset=yOffset+(viewportHeight-realHeight)/2*zoom
    return love.graphics.newQuad(xOffset,yOffset,realWidth*zoom,realHeight*zoom,width,height),zoom
end
for id,value in pairs(levelData.ID2LevelScene) do
    local data={}
    screenshotManager.data[id]=data
    local path=path(id)
    local level,scene=value.level,value.scene
    if love.filesystem.read(path)then
        data.image=love.graphics.newImage(path)
    else
        local oldPath=oldPath(level,scene)
        if love.filesystem.read(oldPath)then
            data.image=love.graphics.newImage(oldPath)
            love.filesystem.write(path, love.filesystem.read(oldPath))
            love.filesystem.remove(oldPath)
        else
            goto continue
        end
    end
    data.quad,data.zoom=getQuad(data.image)
    data.batch=love.graphics.newSpriteBatch(data.image,5,'stream')
    ::continue::
end
function screenshotManager.preSave(levelID)
    -- when player is about to win, make a screenshot
    local path=prePath(levelID)
    -- Capture a screenshot of the current screen
    love.graphics.captureScreenshot(path)

    -- love.graphics.captureScreenshot(path)
end
function screenshotManager.save(levelID)
    -- when player actually wins, save the screenshot to the final path and prepare for display in level choosing menu
    local pre_path=prePath(levelID)
    local path=path(levelID)
    love.filesystem.write(path, love.filesystem.read(pre_path))
    love.filesystem.remove(pre_path)
    local data=screenshotManager.data[levelID]
    data.image=love.graphics.newImage(path)
    data.quad,data.zoom=getQuad(data.image)
    data.batch=love.graphics.newSpriteBatch(data.image,5,'stream')
end
return screenshotManager