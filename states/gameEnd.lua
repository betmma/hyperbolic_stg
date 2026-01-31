local G=...
return {
    enter=function(self)
        self.currentUI.transparency=0
        local showNextSceneOption=false
        if self.won_current_scene then
            local level=self.UIDEF.CHOOSE_LEVELS.chosenLevel
            local scene=self.UIDEF.CHOOSE_LEVELS.chosenScene
            local nextLevel,nextScene,valid=LevelData.getNextLevelScene(level,scene)
            if valid then
                showNextSceneOption=true
            end
        end
        if showNextSceneOption then
            self.currentUI.options[4]={text='Next Scene',value='NEXT_SCENE'}
        else
            self.currentUI.options[4]=nil
            if self.currentUI.chosen>3 then
                self.currentUI.chosen=3
            end
        end
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
            end,
            NEXT_SCENE=function(self)
                local level=self.UIDEF.CHOOSE_LEVELS.chosenLevel
                local scene=self.UIDEF.CHOOSE_LEVELS.chosenScene
                local nextLevel,nextScene,valid=LevelData.getNextLevelScene(level,scene)
                if not valid then
                    return
                end
                self.UIDEF.CHOOSE_LEVELS.chosenLevel=nextLevel
                self.UIDEF.CHOOSE_LEVELS.chosenScene=nextScene
                self:enterLevel(nextLevel,nextScene)
            end,
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