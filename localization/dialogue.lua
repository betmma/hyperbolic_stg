---@alias expression "normal"|"happy"|"sad"|"angry"|"surprised"|"cunning"
---@alias position "left"|"right"|nil -- nil means use default position for the speaker. 

---@class DialogueLine
---@field speaker string used to pick image and display speaker name. 'system' is darken screen and display text in center
---@field expression expression used to pick image
---@field textKey string text is in localization.lua
---@field position position where to position image (and flip)

--- of course i want to omit "key=" in each line definition
---@param speaker string
---@param expression expression
---@param textKey string
---@param position position
---@return DialogueLine
local function line(speaker,expression,textKey,position)
    return {
        speaker=speaker,
        expression=expression,
        textKey=textKey,
        position=position,
    }
end

---@class Dialogue
---@field name string identifier, and is the key in localization.dialogues
---@field defaultSpeakerPosition table<string,position> default position for each speaker
---@field lines DialogueLine[]


local doremyDialogue1_1={
    name='doremyDialogue1_1',
    defaultSpeakerPosition={
        reimu='left',
        doremy='right',
    },
    lines={
        line('reimu','surprised','whereAmI'),
        line('doremy','cunning','thisIsDreamWorld'),
        line('reimu','surprised','itLooksStrange'),
        line('doremy','normal','thereIsReason'),
        line('doremy','normal','gensokyoIsInDanger'),
        line('reimu','surprised','whatDanger'),
        line('doremy','normal','theWorldIsVeryStrangeNow'),
        line('reimu','normal','dulyNotedCanILeaveNow'),
        line('doremy','normal','notSoFast'),
        line('doremy','cunning','youWillGetLostIfLeaveNow'),
        line('reimu','surprised','okSoWhat'),
        line('doremy','normal','danmakuIsBetterExplanation'),
        line('system','normal','welcomeToThisGame'),
        line('system','normal','spaceIsStrange'),
        line('system','normal','upperThingsAppearSmaller'),
        line('system','normal','forThisSpellcard'),
        line('system','normal','finalHint'),
        line('system','normal','controlsIntroduction'),
        line('system','normal','haveFun'),
    }
}

local Dialogue={}

---@type table<string,Dialogue>
Dialogue.data={
    doremyDialogue1_1=doremyDialogue1_1,
}

local DialogueController=GameObject:extend()

function DialogueController:new(args)
    DialogueController.super.new(self,args)
    self.currentLineIndex=1
    self.autoAdvanceTime=args.autoAdvanceTime or 5 -- seconds to auto advance
    self.timeSinceLastAdvance=0
    self.timeSinceLastAutoAdvance=999
    self.dialogueKey=args.key
    self.data=Dialogue.data[args.key]
    if not self.data then
        error("Dialogue key "..tostring(args.key).." not found in Dialogue.data")
    end
    self.afterFunc=args.afterFunc -- function to call after dialogue ends
end

function DialogueController:update(dt)
    self.timeSinceLastAdvance=self.timeSinceLastAdvance+dt
    self.timeSinceLastAutoAdvance=self.timeSinceLastAutoAdvance+dt
    if self.timeSinceLastAdvance>=self.autoAdvanceTime or (isPressed('z') and self.timeSinceLastAutoAdvance>0.5) or love.keyboard.isDown('lctrl') then -- press z or hold left ctrl to advance. > 0.5 check to avoid unintended advance after an auto advance
        self:advanceDialogue()
    end
end

function DialogueController:advanceDialogue()
    SFX:play('select')
    if self.timeSinceLastAdvance>=self.autoAdvanceTime then
        self.timeSinceLastAutoAdvance=0
    end
    self.timeSinceLastAdvance=0
    self.currentLineIndex=self.currentLineIndex+1
    if self.currentLineIndex>#self.data.lines then
        if self.afterFunc then
            self.afterFunc()
        end
        self:remove()
    end
end

function DialogueController:draw()
    if self.currentLineIndex>#self.data.lines then
        return
    end
    local line=self.data.lines[self.currentLineIndex]
    local speaker=line.speaker
    local expression=line.expression
    local textKey=line.textKey
    local position=line.position or self.data.defaultSpeakerPosition[speaker] or 'left'
    local text=Localize{'dialogues',self.dialogueKey,textKey}
    -- image not implemented yet (cuz i don't have art :c)
    local color={love.graphics.getColor()}
    SetFont(24)
    if speaker=='system' then
        love.graphics.setColor(0,0,0,0.5)
        love.graphics.rectangle('fill',0,0,WINDOW_WIDTH,WINDOW_HEIGHT)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(text,150,WINDOW_HEIGHT/2-50,WINDOW_WIDTH-300,'center')
    else
        love.graphics.setColor(0,0,0,0.5)
        local x,y,width,height=150,450,500,130
        love.graphics.rectangle('fill',x,y,width,height)
        local gap=15
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(text,x+gap,y+gap,width-gap*2,'left')
        -- speaker name
        love.graphics.printf(Localize{'levelData','names',speaker},x+gap,y-gap-20,width-gap*2,position)
        -- image placeholder
    end
    love.graphics.setColor(color)
end

return DialogueController