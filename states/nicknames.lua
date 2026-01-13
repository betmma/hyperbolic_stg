local NUMBER_PER_ROW=12
return {
    enter=function(self)
        self.currentUI.chosen=1
    end,
    update=function(self,dt)
        local nicknameCount=Nickname.nicknameCount
        self.backgroundPattern:update(dt)
        if isPressed('x') or isPressed('escape')then
            SFX:play('select')
            self:switchState(self.STATES.MAIN_MENU)
            self:saveData()
        elseif isPressed('left') then
            self.currentUI.chosen=self.currentUI.chosen-1
            if self.currentUI.chosen<1 then
                self.currentUI.chosen=nicknameCount
            end
            SFX:play('select')
        elseif isPressed('right') then
            self.currentUI.chosen=self.currentUI.chosen+1
            if self.currentUI.chosen>nicknameCount then
                self.currentUI.chosen=1
            end
            SFX:play('select')
        elseif isPressed('up') then
            self.currentUI.chosen=self.currentUI.chosen-NUMBER_PER_ROW
            if self.currentUI.chosen<1 then
                self.currentUI.chosen=nicknameCount-NUMBER_PER_ROW+1+(self.currentUI.chosen-nicknameCount-1)%NUMBER_PER_ROW
            end
            SFX:play('select')
        elseif isPressed('down') then
            self.currentUI.chosen=self.currentUI.chosen+NUMBER_PER_ROW
            if self.currentUI.chosen>nicknameCount then
                self.currentUI.chosen=1+(self.currentUI.chosen-1)%NUMBER_PER_ROW
            end
            SFX:play('select')
        elseif DEV_MODE and (isPressed('[') or isPressed(']')) then
            SFX:play('select')
            local nicknames=Nickname.nicknames
            local currentNickname=nicknames[self.currentUI.chosen]
            local bool
            if isPressed('[') then
                bool=false
            else
                bool=true
            end
            self.save.nicknameUnlock[currentNickname.name]=bool
        elseif isPressed('z') then
            local nicknames=Nickname.nicknames
            local currentNickname=nicknames[self.currentUI.chosen]
            if currentNickname==Nickname.BeatTheGame and self.save.nicknameUnlock[currentNickname.name]==true then
                SFX:play('select')
                G:switchState(G.STATES.ENDING)
            end
        end
    end,
    draw=function(self)
    end,
    drawText=function(self)
        local color={love.graphics.getColor()}
        SetFont(48)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(Localize{'ui',"NICKNAMES"}, 100, 30)
        local nicknames=Nickname.nicknames
        local xbegin,ybegin=100,100
        local gridSize=50
        local numberPerRow=12
        local index=0
        local boxX,boxY=100,480
        local gap=10
        for k,v in pairs(nicknames) do -- draw the matrix of nicknames (some unlocked, some locked, some hidden)
            index=index+1
            local x=xbegin+(index-1)%numberPerRow*gridSize
            local y=ybegin+math.floor((index-1)/numberPerRow)*gridSize
            local unlocked=G.save.nicknameUnlock[v.name]
            if not v.isSecret or unlocked then
                if unlocked then
                    love.graphics.setColor(1,1,0.5) -- yellow for unlocked nicknames
                else
                    love.graphics.setColor(1,1,1,1) -- white for normal nicknames
                end
                SetFont(48)
                love.graphics.print(string.format('%02d',index),x+5,y) -- the index number
            end
            love.graphics.setColor(1,1,1,1)
        end
        local chosen=self.currentUI.chosen
        local chosenNickname=nicknames[chosen]
        local chosenUnlocked=G.save.nicknameUnlock[chosenNickname.name]
        -- draw cursor box
        local x=xbegin+(chosen-1)%numberPerRow*gridSize
        local y=ybegin+math.floor((chosen-1)/numberPerRow)*gridSize
        love.graphics.rectangle("line",x,y,gridSize,gridSize)
        if not (chosenNickname.isSecret and not chosenUnlocked) then
            local name=chosenNickname:getName()
            -- draw large box
            love.graphics.rectangle("line",boxX,boxY,600,100)
            -- name above box
            SetFont(24)
            love.graphics.print(name,boxX,boxY-30)

            local text=chosenNickname:getText(chosenUnlocked) -- let nickname generate its own description text
            -- description text inside box
            SetFont(18)
            love.graphics.printf(text,boxX+gap,boxY+gap,600-gap*2,'left')
            -- possible progress bar for locked and progressed nickname
            if not chosenUnlocked and chosenNickname:is(Nickname.ProgressedNickname) then
                ---@cast chosenNickname ProgressedNickname
                local progress=math.clamp(chosenNickname.progressFunc(),0,1)
                local x0,y0,width=boxX+gap,boxY+50,600-gap*2
                love.graphics.setColor(1,1,1)
                love.graphics.rectangle("line",x0,y0,width,10)
                love.graphics.setColor(1,1,0.5)
                love.graphics.rectangle("fill",x0,y0,width*progress,10)
                love.graphics.setColor(1,1,1,1)
            end
        end

        love.graphics.setColor(color[1],color[2],color[3],color[4] or 1)
    end
}