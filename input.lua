local Input={}

local keyboardPressedLastFrame={}
local keyboardPressedThisFrame={}

function Input.update()
    keyboardPressedLastFrame=keyboardPressedThisFrame
    keyboardPressedThisFrame={}
end

function Input.keypressed(key, scancode, isrepeat)
    if not isrepeat then
        keyboardPressedThisFrame[key] = true
    end
end

function Input.isKeyJustPressed(key)
    -- Input.update() is called at the beginning of love.update, so must use keyboardPressedLastFrame instead of keyboardPressedThisFrame.
    -- but why don't move Input.update to the end of love.update, then keyboardPressedThisFrame table isn't emptied when calling G.update, and we can discard lastFrame table?
    -- if so, it's possible that during G.update love.keyboard.keypressed is called, then in same frame, isKeyJustPressed call can yield different result.
    return keyboardPressedLastFrame[key]
end

return Input