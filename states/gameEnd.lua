local G=...
return {
    enter=function(self)
        self.currentUI.transparency=0
    end,
    options={
        {text='Restart',value='RESTART'},
        {text='Save Replay',value='SAVE_REPLAY'},
        {text='Exit',value='EXIT'},
    },
    chosen=1,
    update=function(self,dt)
        UIHelper.optionsCalc(self,{
            EXIT=function(self)
                self:removeAll()
                self:switchState(self.STATES.CHOOSE_LEVELS)
            end,
            SAVE_REPLAY=function(self)
                self:switchState(self.STATES.SAVE_REPLAY)
            end,
            RESTART=function(self)
                self:enterLevel(self.UIDEF.CHOOSE_LEVELS.chosenLevel,self.UIDEF.CHOOSE_LEVELS.chosenScene)
            end
        })
        local transparency=self.currentUI.transparency or 1
        transparency=transparency*0.92+0.08
        self.currentUI.transparency=transparency
    end,
    draw=G.CONSTANTS.DRAW,
    drawText=function(self)
        local transparency=self.currentUI.transparency or 1
        GameObject:drawTextAll()
        local color={love.graphics.getColor()}
        love.graphics.setColor(1,1,1,0.5*transparency)
        love.graphics.rectangle("fill",0,0,9999,9999) -- half transparent effect
        love.graphics.setColor(0,0,0,0.5*transparency)
        love.graphics.rectangle("fill",0,0,9999,9999)
        love.graphics.setColor(1,1,1,transparency)
        SetFont(48)
        love.graphics.print(self.won_current_scene and Localize{'ui','win'} or Localize{'ui','lose'},100,50,0,1,1)
        SetFont(36)
        for index, value in ipairs(self.currentUI.options) do
            local name=Localize{'ui',value.value}
            love.graphics.print(name,100,200+index*50,0,1,1)
        end
        love.graphics.rectangle("line",100,200+self.currentUI.chosen*50,200,50)
        love.graphics.setColor(color[1],color[2],color[3],color[4])
    end
}