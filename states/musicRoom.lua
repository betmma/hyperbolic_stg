return {
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
        self.UIDEF.MUSIC_ROOM.options={}
        for i,v in ipairs(BGM.fileNames) do
            table.insert(self.UIDEF.MUSIC_ROOM.options,{value=v})
        end
        -- for testing ui insert same option more times
        -- for i=1,10 do
        --     table.insert(self.UIDEF.MUSIC_ROOM.options,{value='test_music_'..i})
        -- end
    end,
    chosen=1,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        UIHelper.optionsCalc(self,{})
        if isPressed('x') or isPressed('escape')then
            SFX:play('select')
            self:switchState(self.STATES.MAIN_MENU)
        end
        if isPressed('z') then
            SFX:play('select')
            local chosen=self.currentUI.chosen
            local musicName=self.currentUI.options[chosen].value
            BGM:play(musicName)
        end
    end,
    options={},
    draw=function(self)
    end,
    drawText=function(self)
        SetFont(48)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(Localize{'ui',"MUSIC_ROOM"}, 100, 30)
        local edge=5
        local width=600
        local optionBaseX=100
        local optionBaseY=100
        local optionHeight=40
        SetFont(24)
        local chosen=self.currentUI.chosen
        local optionCount=#self.currentUI.options
        local displayedCount=7
        local slider=true
        if displayedCount>optionCount then
            displayedCount=optionCount
            slider=false
        end
        local displayHeight=displayedCount*optionHeight
        love.graphics.setColor(0,0,0,0.3)
        love.graphics.rectangle("fill",optionBaseX,optionBaseY,width,displayHeight) -- background
        local halfDisplayedCount=math.floor(displayedCount/2)
        local beginIndex=math.clamp(chosen-halfDisplayedCount,1,optionCount-displayedCount+1)
        local endIndex=math.min(optionCount,beginIndex+displayedCount-1)
        love.graphics.setColor(1,1,1,1)
        if slider==true then
            local sliderHeight=displayHeight-edge*2
            love.graphics.line(optionBaseX+width-edge,optionBaseY+edge+(beginIndex-1)/optionCount*sliderHeight,optionBaseX+width-edge,optionBaseY+edge+(endIndex)/optionCount*sliderHeight) -- vertical line (slider)
        end
        for index = beginIndex,endIndex do
            local value=self.currentUI.options[index]
            if not value then
                error("Option "..index.." not found in MUSIC_ROOM options")
            end
            local name=Localize{'musicData',value.value,'name'}
            local prefix=''..index..'. '
            local indexAppearing=index-beginIndex -- indexAppearing is the index of the option in the current view, starting from 0
            love.graphics.print(prefix..name,optionBaseX+edge,optionBaseY+edge+indexAppearing*optionHeight,0,1,1)
        end
        love.graphics.rectangle("line",optionBaseX,optionBaseY+edge+(chosen-beginIndex)*optionHeight,width,30)
        local option=self.currentUI.options[chosen]
        local description=Localize{'musicData',option.value,'description'}

        local bottomY=400
        love.graphics.setColor(0,0,0,0.3)
        love.graphics.rectangle("fill",optionBaseX,bottomY,width,180)
        love.graphics.setColor(1,1,1,1)
        SetFont(20)
        love.graphics.printf(description,optionBaseX+edge,bottomY+edge,width-edge*2,'left')
        love.graphics.rectangle("line",optionBaseX,bottomY,width,180)
        -- SetFont(36)
        -- love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
    end,
}