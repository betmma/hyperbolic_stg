return {
    options={ -- actual text is in localization file
        {text='Start',value='START'},
        {text='Replay',value='REPLAY'},
        {text='Options',value='OPTIONS'},
        {text='Music Room',value='MUSIC_ROOM'},
        {text='Nicknames',value='NICKNAMES'},
        -- {text='Ending',value='ENDING'}, -- test only
        {text='Exit',value='EXIT'},
    },
    chosen=1,
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
        BGM:play('title')
    end,
    update=function(self,dt)
        if isPressed('f3') then
            SFX:play('cancel',true)
            self.backgroundPattern:randomize()
        end
        self.backgroundPattern:update(dt)
        UIHelper.optionsCalc(self,{EXIT=love.event.quit,START=function(self)self:switchState(self.STATES.CHOOSE_LEVELS) end,
        REPLAY=function(self)self:switchState(self.STATES.LOAD_REPLAY)end,
        MUSIC_ROOM=function(self)self:switchState(self.STATES.MUSIC_ROOM)end,
        NICKNAMES=function(self)self:switchState(self.STATES.NICKNAMES)end,
        OPTIONS=function(self)self:switchState(self.STATES.OPTIONS) end,
        ENDING=function(self)self:switchState(self.STATES.ENDING) end}
        )
        Asset.titleBatch:clear()
        Asset.titleBatch:add(Asset.title,70,-30,0,0.5,0.5,0,0)
    end,
    draw=function(self)
    end,
    drawText=function(self)
        if love.keyboard.isDown('f2') then
            return
        end
        Asset.titleBatch:flush()
        love.graphics.draw(Asset.titleBatch)
        -- -- self.updateDynamicPatternData(self.patternData)
        local color={love.graphics.getColor()}
        SetFont(36)
        love.graphics.setColor(1,1,1,0.6)
        love.graphics.printf("Hyperbolic Domain",200,250,400,'center')
        local optionBaseY=255
        SetFont(36)
        love.graphics.setColor(1,1,1,1)
        for index, value in ipairs(self.currentUI.options) do
            local name=Localize{'ui',value.value}
            love.graphics.print(name,300,optionBaseY+index*50,0,1,1)
        end
        love.graphics.rectangle("line",300,optionBaseY+self.currentUI.chosen*50,200,40)
        -- love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
        SetFont(24)
        love.graphics.print(VERSION, WINDOW_WIDTH-80, WINDOW_HEIGHT-30)
        love.graphics.setColor(color[1],color[2],color[3],color[4] or 1)
    end
}