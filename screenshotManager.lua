local levelData=require'levelData'
local screenshotManager={}
screenshotManager.data={}
local screenshotDir='screenshots'
love.filesystem.createDirectory(screenshotDir)
local function path(level,scene)
    return screenshotDir..'/scr_'..level..'_'..scene..'.png'
end
local function prePath(level,scene)
    return screenshotDir..'/scr_pre_'..level..'_'..scene..'.png'
end
for k,value in ipairs(levelData) do
    screenshotManager.data[k]={}
    for i=1,#value do
        local data={}
        screenshotManager.data[k][i]=data
        local path=path(k,i)
        if love.filesystem.read(path)then
            -- local d=love.filesystem.read(path)
            data.image=love.graphics.newImage(path)
            data.quad=love.graphics.newQuad(150,0,500,data.image:getHeight(),data.image:getWidth(),data.image:getHeight())
            data.batch=love.graphics.newSpriteBatch(data.image,5,'stream')
        end
    end
end
function screenshotManager.preSave(level,scene)
    local path=prePath(level,scene)
    -- Capture a screenshot of the current screen
    love.graphics.captureScreenshot(path)

    -- love.graphics.captureScreenshot(path)
end
function screenshotManager.save(level,scene)
    local pre_path=prePath(level,scene)
    local path=path(level,scene)
    love.filesystem.write(path, love.filesystem.read(pre_path))
    love.filesystem.remove(pre_path)
    local data=screenshotManager.data[level][scene]
    data.image=love.graphics.newImage(path)
    data.quad=love.graphics.newQuad(150,0,500,data.image:getHeight(),data.image:getWidth(),data.image:getHeight())
    data.batch=love.graphics.newSpriteBatch(data.image,5,'stream')
end
return screenshotManager