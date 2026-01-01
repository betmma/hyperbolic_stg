-- simple half transparent notice box covering whole screen
---@class Notice
---@field textArgs string[] localization args. will localize with {'notice', textArgs[1], ...}
---@field displayFrame integer frame when this notice starts to display
---@field dismissFrame integer? frame when this notice is dismissed (player pressed z to dismiss)
---@field sfxPlayed boolean whether the sound effect has been played
---@field draw fun(self:Notice):boolean draw the notice box, return false if fully transparent

---@class NoticeManager:Object
---@field notices Notice[]
---@field add fun(self:NoticeManager,textArgs:localizationArgs)
---@field addWhenEnterState fun(self:NoticeManager,textArgs:localizationArgs,state:string)
---@field update fun(self:NoticeManager)
---@field drawText fun(self:NoticeManager)
---@field hasNotice fun(self:NoticeManager):boolean return true if there is any notice being displayed

local FADE_FRAME=20

local Notice=Object:extend()
local NoticeManager=Object:extend()

function Notice:new(textArgs)
    self.textArgs=textArgs
    self.displayFrame=G.frame -- if multiple notices appear in same frame, the displayFrame of later ones will be renewed in NoticeManager:update
    self.dismissFrame=nil
    self.sfxPlayed=false
end

function Notice:concreteness()
    local framePassed=G.frame - self.displayFrame
    local fadeIn=math.min(framePassed/FADE_FRAME,1)
    local fadeOut=1
    if self.dismissFrame then
        local framePassedDismiss=G.frame - self.dismissFrame
        fadeOut=math.max(1 - framePassedDismiss/FADE_FRAME,0)
    end
    return fadeIn*fadeOut
end

-- it's not GameObject so draw is not auto called but called by manager
function Notice:draw()
    local alpha=self:concreteness()
    if alpha<=0 then
        return false
    end
    local colorRef={love.graphics.getColor()}
    love.graphics.setColor(0,0,0,0.5*alpha)
    love.graphics.rectangle('fill',0,0,WINDOW_WIDTH,WINDOW_HEIGHT)
    love.graphics.setColor(1,1,1,alpha)
    local boxWidth,boxHeight=600,200
    local fullParams={'notice'}
    for _,v in ipairs(self.textArgs) do
        table.insert(fullParams,v)
    end
    local text=Localize(fullParams)
    SetFont(36)
    love.graphics.printf(text,WINDOW_WIDTH/2-boxWidth/2,WINDOW_HEIGHT/2-boxHeight/2,boxWidth,'center')
    love.graphics.setColor(colorRef)
    return true
end

function NoticeManager:new()
    ---@type Notice[]
    self.notices={}
end

---@param textArgs localizationArgs "localization args. will localize with {'ui', 'notice', textArgs[1], ...}. non integer indexes are ignored"
function NoticeManager:add(textArgs)
    self.notices[#self.notices+1]=Notice(textArgs)
end

-- add a notice that will be shown when entering certain (defaults to choose levels) state, common notices can use this. directly call NoticeManager:add in level:leave could happen when retrying level or at you win/lose screen
function NoticeManager:addWhenEnterState(textArgs, state)
    EventManager.listenTo(EventManager.EVENTS.SWITCH_STATE, function(from,to)
        if to~=state then
            return
        end
        self:add(textArgs)
        return EventManager.DELETE_LISTENER
    end)
end

-- called in G.update
function NoticeManager:update()
    if #self.notices==0 then
        return
    end
    local currentNotice=self.notices[1]
    if not currentNotice.sfxPlayed then
        SFX:play('notice')
        currentNotice.sfxPlayed=true
    end
    if isPressed('z') and not currentNotice.dismissFrame then
        currentNotice.dismissFrame=G.frame
        SFX:play('select')
    end
    if currentNotice.dismissFrame then
        local framePassedDismiss=G.frame - currentNotice.dismissFrame
        if framePassedDismiss>=FADE_FRAME then
            table.remove(self.notices,1)
            if #self.notices>0 then -- multiple notices queued, set displayFrame of next notice to current frame
                self.notices[1].displayFrame=G.frame
            end
        end
    end
    Input.consume() -- block (other) inputs while notice is showing
end

function NoticeManager:drawText()
    if #self.notices==0 then
        return
    end
    local currentNotice=self.notices[1]
    currentNotice:draw()
end

function NoticeManager:hasNotice() -- currently not used
    return #self.notices>0
end

local noticeManager=NoticeManager()
return noticeManager