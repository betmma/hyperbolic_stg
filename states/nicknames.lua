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
            self.currentUI.chosen=self.currentUI.chosen-10
            if self.currentUI.chosen<1 then
                self.currentUI.chosen=nicknameCount-9+(self.currentUI.chosen-nicknameCount-1)%10
            end
            SFX:play('select')
        elseif isPressed('down') then
            self.currentUI.chosen=self.currentUI.chosen+10
            if self.currentUI.chosen>nicknameCount then
                self.currentUI.chosen=1+(self.currentUI.chosen-1)%10
            end
            SFX:play('select')
        elseif isPressed('[') or isPressed(']') then
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
        local numberPerRow=10
        local index=0
        local boxX,boxY=100,480
        local gap=10
        for k,v in pairs(nicknames) do
            index=index+1
            local x=xbegin+(index-1)%numberPerRow*gridSize
            local y=ybegin+math.floor((index-1)/numberPerRow)*gridSize
            local name=Localize{'nickname',v.name,'name'}
            local condition=Localize{'nickname',v.name,'condition'}
            local description=Localize{'nickname',v.name,'description'}
            local unlocked=G.save.nicknameUnlock[v.name]
            if not v.isSecret or unlocked then
                if unlocked then
                    love.graphics.setColor(1,1,0.5) -- yellow for unlocked nicknames
                else
                    love.graphics.setColor(1,1,1,1) -- white for normal nicknames
                end
                SetFont(48)
                love.graphics.print(string.format('%02d',index),x+5,y)
            end
            love.graphics.setColor(1,1,1,1)
            if index==self.currentUI.chosen then
                love.graphics.rectangle("line",x,y,gridSize,gridSize)
                if v.isSecret and not unlocked then
                    goto continue
                end
                SetFont(24)
                love.graphics.print(name,boxX,boxY-30)
                SetFont(18)
                local text=condition
                if v:is(Nickname.DetailedNickname) then
                    ---@cast v DetailedNickname
                    local detail=v:detailFunc()
                    if detail and detail~='' then
                        text=text..'\n'..detail
                    end
                end
                if unlocked then
                    text=text..'\n'..description
                else
                    if v:is(Nickname.ProgressedNickname) then
                        ---@cast v ProgressedNickname
                        local progress=math.clamp(v.progressFunc(),0,1)
                        local x0,y0,width=boxX+gap,boxY+50,600-gap*2
                        love.graphics.setColor(1,1,1)
                        love.graphics.rectangle("line",x0,y0,width,10)
                        love.graphics.setColor(1,1,0.5)
                        love.graphics.rectangle("fill",x0,y0,width*progress,10)
                        love.graphics.setColor(1,1,1,1)
                    end
                end
                love.graphics.printf(text,boxX+gap,boxY+gap,600-gap*2,'left')
                love.graphics.rectangle("line",boxX,boxY,600,100)
            end
            ::continue::
        end

        love.graphics.setColor(color[1],color[2],color[3],color[4] or 1)
    end
    
}