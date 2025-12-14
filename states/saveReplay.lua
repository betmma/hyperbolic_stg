local G=...
return {
    chosen=1,
    page=1,
    chosenMax=25,
    pageMax=4,
    slot=0,
    enter=function(self)
        self.currentUI.chosenMax=ReplayManager.REPLAY_NUM_PER_PAGE
        self.currentUI.pageMax=ReplayManager.PAGES
    end,
    update=function(self,dt)
        UIHelper.keyBindValueCalc(self,'down','up','chosen',self.currentUI.chosenMax)
        UIHelper.keyBindValueCalc(self,'right','left','page',self.currentUI.pageMax)
        self.UIDEF.LOAD_REPLAY.digitUpdate(self)
        if isPressed('z') then
            local slot=self.currentUI.chosen+self.currentUI.page*25-25
            self.currentUI.slot=slot
            -- ReplayManager.saveReplay(slot,'test')
            self:switchState(self.STATES.SAVE_REPLAY_ENTER_NAME)
            SFX:play('select')
        elseif isPressed('x') or isPressed('escape')then
            SFX:play('select')
            self:switchState(self.STATES.GAME_END)
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

        local chosen,page=self.currentUI.chosen,self.currentUI.page
        SetFont(16,Fonts.en_us)
        for i=page*25+1-25,page*25 do
            local replayDesc=ReplayManager.getDescriptionString(i)
            ReplayManager.monospacePrint(replayDesc,10,145,50+(i-1)%25*20)
        end
        love.graphics.rectangle("line",140,30+self.currentUI.chosen*20,520,20)
    end
}