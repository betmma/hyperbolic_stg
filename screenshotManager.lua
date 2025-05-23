local levelData=require'levelData'
local screenshotManager={}
---@class love.Image
---@class love.SpriteBatch

---@class ScreenShot
---@field image love.Image
---@field quad love.Quad
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
        end
    end
    data.quad=love.graphics.newQuad(150,0,500,data.image:getHeight(),data.image:getWidth(),data.image:getHeight())
    data.batch=love.graphics.newSpriteBatch(data.image,5,'stream')
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
    data.quad=love.graphics.newQuad(150,0,500,data.image:getHeight(),data.image:getWidth(),data.image:getHeight())
    data.batch=love.graphics.newSpriteBatch(data.image,5,'stream')
end
return screenshotManager