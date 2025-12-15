local G=...
return {
    column=1,
    row=1,
    keyboard={
        {'A',"B","C","D","E","F","G","H","I","J","K","L","M"},
        {"N","O","P","Q","R","S","T","U",'V',"W","X","Y","Z"},
        {'a',"b","c","d","e","f","g","h","i","j","k","l","m"},
        {"n","o","p","q","r","s","t","u",'v',"w","x","y","z"},
        {"0","1","2","3","4","5","6","7",'8',"9","+","-","="},
        {".",",","!","?","@",":",";","[",']',"(",")","_","/"},
        {"{","}","|","~","^","#","$","%",'&',"*"," ","BS","END"},
    },
    name='',
    slot=0,
    enter=function(self)
        self.currentUI.slot=self.UIDEF.SAVE_REPLAY.slot
        self.currentUI.name=self.save.defaultName
    end,
    update=function(self,dt)
        UIHelper.keyBindValueCalc(self,'down','up','row',#self.currentUI.keyboard)
        UIHelper.keyBindValueCalc(self,'right','left','column',#self.currentUI.keyboard[1])
        if isPressed('z') then
            local char=self.currentUI.keyboard[self.currentUI.row][self.currentUI.column]
            if char=='BS'then
                if #self.currentUI.name>0 then 
                    self.currentUI.name=self.currentUI.name:sub(1,#self.currentUI.name-1)
                    SFX:play('select',true)
                else
                    SFX:play('cancel',true)
                end
            elseif char=='END'then
                if #self.currentUI.name>0 then
                    self.save.defaultName=self.currentUI.name
                    self:saveData()
                    ReplayManager.saveReplay(self.currentUI.slot,self.currentUI.name)
                    SFX:play('select',true)
                    self:switchState(self.STATES.SAVE_REPLAY)
                else
                    SFX:play('cancel',true)
                end
            else --normal char
                if #self.currentUI.name>=ReplayManager.MAX_NAME_LENGTH then
                    SFX:play('cancel',true)
                else
                    self.currentUI.name=self.currentUI.name..char
                    SFX:play('select',true)
                end
            end
        elseif isPressed('x') or isPressed('escape')then
            SFX:play('select',true)
            self:switchState(self.STATES.SAVE_REPLAY)
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

        SetFont(16,Fonts.en_us)
        local replayDesc=ReplayManager.getDescriptionString(self.currentUI.slot,ReplayManager.getReplayData(self.currentUI.slot,self.currentUI.name))
        ReplayManager.monospacePrint(replayDesc,10,145,50)

        SetFont(24,Fonts.en_us)
        for row, value in pairs(self.currentUI.keyboard) do
            for column, char in pairs(value) do
                if char~=' 'then
                    love.graphics.printf(char,100+column*40,100+row*40,40,'center')
                else
                    love.graphics.rectangle('line',100+column*40+10,100+row*40,20,30)
                end
            end
        end

        love.graphics.rectangle("line",100+self.currentUI.column*40,95+self.currentUI.row*40,40,40)
    end
}