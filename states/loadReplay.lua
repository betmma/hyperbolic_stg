return {
    chosen=1,
    page=1,
    chosenMax=25,
    pageMax=4,
    enter=function(self)
        self:removeAll()
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.NORMAL
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
        ReplayManager.loadAll()
        self.currentUI.chosenMax=ReplayManager.REPLAY_NUM_PER_PAGE
        self.currentUI.pageMax=ReplayManager.PAGES
    end,
    digitUpdate=function(self) -- use numpad to jump to replay number
        local digits='0123456789'
        for i=1,#digits do
            if isPressed(digits:sub(i,i)) or isPressed('kp'..digits:sub(i,i)) then
                local index=tonumber(digits:sub(i,i))
                local slot
                if not self.currentUI.firstDigit then
                    self.currentUI.firstDigit=index
                    slot=index
                elseif not self.currentUI.secondDigit then
                    self.currentUI.secondDigit=index
                    slot=self.currentUI.firstDigit*10+index
                else
                    slot=self.currentUI.firstDigit*100+self.currentUI.secondDigit*10+index
                    slot=math.clamp(slot,1,ReplayManager.REPLAY_NUM_PER_PAGE*ReplayManager.PAGES)
                    self.currentUI.firstDigit=nil
                    self.currentUI.secondDigit=nil
                end
                if slot==0 then slot=1 end
                self.currentUI.page=math.floor((slot+24)/25)
                self.currentUI.chosen=(slot-1)%25+1
            end
        end
    end,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        UIHelper.keyBindValueCalc(self,'down','up','chosen',self.currentUI.chosenMax)
        UIHelper.keyBindValueCalc(self,'right','left','page',self.currentUI.pageMax)
        self.currentUI.digitUpdate(self)
        if isPressed('z') then
            local index=self.currentUI.chosen+self.currentUI.page*25-25
            self.currentUI.slot=index
            local replay=ReplayManager.replays[index]
            if replay then
                self.UIDEF.CHOOSE_LEVELS.chosenLevel,self.UIDEF.CHOOSE_LEVELS.chosenScene=replay.level,replay.scene
            end
            ReplayManager.runReplay(index)
            SFX:play('select')
        elseif isPressed('x') or isPressed('escape')then
            SFX:play('select')
            self:switchState(self.STATES.MAIN_MENU)
        end
    end,
    draw=function(self)
    end,
    drawText=function(self)
        -- self.updateDynamicPatternData(self.patternData)
        local color={love.graphics.getColor()}
        love.graphics.setColor(1,1,1)

        local chosen,page=self.currentUI.chosen,self.currentUI.page
        SetFont(17,Fonts.en_us)
        for i=page*25+1-25,page*25 do
            local replayDesc=ReplayManager.getDescriptionString(i)
            ReplayManager.monospacePrint(replayDesc,10,145,50+(i-1)%25*20)
        end
        love.graphics.rectangle("line",140,30+self.currentUI.chosen*20,520,20)

        -- digits entered
        local baseX,baseY=650,580
        local digits=''..(self.currentUI.firstDigit or '')..(self.currentUI.secondDigit or '')
        if digits~='' then
            SetFont(17)
            local text=Localize{'ui','replayDigitsEntered',digits=digits}
            love.graphics.print(text,baseX,baseY,0,1,1)
        end

        love.graphics.setColor(color[1],color[2],color[3])
    end
}