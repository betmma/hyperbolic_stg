local levelData=require'levelData'
local screenshotManager={}
screenshotManager.data={}
local function path(level,scene)
    return 'scr_'..level..'_'..scene..'.png'
end
local function prePath(level,scene)
    return 'scr_pre_'..level..'_'..scene..'.png'
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
    local function calcFunc(screenshot)
        -- Define the area to crop (x, y, width, height)
        local cropX, cropY, cropWidth, cropHeight = 50, 50, 200, 150

        -- Get the image data from the screenshot
        local screenshotData = screenshot:getData()

        -- Crop the image (creating a sub-image with the specified dimensions)
        local croppedData = screenshotData:sub(cropX, cropY, cropX + cropWidth - 1, cropY + cropHeight - 1)

        -- Save the cropped image to a file
        croppedData:encode("png", path)

    end
    love.graphics.captureScreenshot(path)

    -- love.graphics.captureScreenshot(path)
end
function screenshotManager.save(level,scene)
    local pre_path=prePath(level,scene)
    local path=path(level,scene)
    love.filesystem.write(path, love.filesystem.read(pre_path))
    local data=screenshotManager.data[level][scene]
    data.image=love.graphics.newImage(path)
    data.quad=love.graphics.newQuad(150,0,500,data.image:getHeight(),data.image:getWidth(),data.image:getHeight())
    data.batch=love.graphics.newSpriteBatch(data.image,5,'stream')
end
return screenshotManager