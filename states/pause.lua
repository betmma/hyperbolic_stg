local G=...
return {
    options={
        {text='Resume',value='RESUME'},
        {text='Exit',value='EXIT'},
    },
    chosen=1,
    update=function(self,dt)
        UIHelper.optionsCalc(self,{
            EXIT=function(self)
                self:removeAll()
                self:switchState(self.replay and self.STATES.LOAD_REPLAY or self.STATES.CHOOSE_LEVELS)
                self:leaveLevel()
            end,
            RESUME=function(self)self:switchState(self.STATES.IN_LEVEL) end
        })
        if isPressed('escape') then
            SFX:play('select')
            self:switchState(self.STATES.IN_LEVEL)
        end
    end,
    draw=G.CONSTANTS.DRAW,
    drawText=function(self)
        GameObject:drawTextAll()
        local color={love.graphics.getColor()}
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.rectangle("fill",0,0,9999,9999) -- half transparent effect
        love.graphics.setColor(0,0,0,0.5)
        love.graphics.rectangle("fill",0,0,9999,9999)
        love.graphics.setColor(color[1],color[2],color[3])
        SetFont(48)
        love.graphics.print(Localize{'ui','paused'},100,50,0,1,1)
        SetFont(36)
        for index, value in ipairs(self.currentUI.options) do
            local name=Localize{'ui',value.value}
            love.graphics.print(name,100,200+index*100,0,1,1)
        end
        love.graphics.rectangle("line",100,200+self.currentUI.chosen*100,200,50)
    end
}