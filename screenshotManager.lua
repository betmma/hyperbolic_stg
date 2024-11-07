local screenshotManager={}
function screenshotManager.preSave(level,scene)
    local path='scr_pre_'..level..'_'..scene..'.png'
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
    local pre_path='scr_pre_'..level..'_'..scene..'.png'
    local path='scr_'..level..'_'..scene..'.png'
    love.filesystem.write(path, love.filesystem.read(pre_path))
end
return screenshotManager