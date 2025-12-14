return {
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
    end,
    options={
        {text='Master Volume',value='master_volume'},
        {text='Music Volume',value='music_volume'},
        {text='SFX Volume',value='sfx_volume'},
        {options={
            {text='English',value='en_us'},
            {text='简体中文',value='zh_cn'},
        },value='language'},
        {
        ---@type {text:string,value:{width:integer,height:integer}}[]
        options={
            {text="800x600",value={width=800,height=600}},
            {text="1024x768",value={width=1024,height=768}},
            {text="1280x720",value={width=1280,height=720}},
            {text="1600x1200",value={width=1600,height=1200}},
            {text="1920x1080",value={width=1920,height=1080}},
        },value='resolution'},
        {text='Exit',value='EXIT'},
    },
    chosen=1,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        UIHelper.optionsCalc(self,{EXIT=function(self)self:switchState(self.STATES.MAIN_MENU);self:saveData() end})
        if self.STATE~=G.STATES.OPTIONS then
            return -- means exited through exit button
        end
        local optionKey=self.currentUI.options[self.currentUI.chosen].value
        if optionKey=='language' then
            local index=0
            local currentLanguage=self.save.options.language
            for i=1,#self.currentUI.options[self.currentUI.chosen].options do
                if self.currentUI.options[self.currentUI.chosen].options[i].value==currentLanguage then
                    index=i
                    break
                end
            end
            if isPressed('right') then
                self.save.options[optionKey]=self.currentUI.options[self.currentUI.chosen].options[index%#self.currentUI.options[self.currentUI.chosen].options+1].value
                self.language=self.save.options.language
                SFX:play('select')
            elseif isPressed('left') then
                self.save.options[optionKey]=self.currentUI.options[self.currentUI.chosen].options[(index-2)%#self.currentUI.options[self.currentUI.chosen].options+1].value
                self.language=self.save.options.language
                SFX:play('select')
            end
        elseif optionKey=='resolution' then
            local index=0
            local currentResolution=self.save.options.resolution
            for i=1,#self.currentUI.options[self.currentUI.chosen].options do
                if TableEqual(self.currentUI.options[self.currentUI.chosen].options[i].value,currentResolution) then
                    index=i
                    break
                end
            end
            if isPressed('right') then
                self.save.options[optionKey]=self.currentUI.options[self.currentUI.chosen].options[index%#self.currentUI.options[self.currentUI.chosen].options+1].value
                shove.setWindowMode(self.save.options.resolution.width,self.save.options.resolution.height, {resizable = true})
                SFX:play('select')
            elseif isPressed('left') then
                self.save.options[optionKey]=self.currentUI.options[self.currentUI.chosen].options[(index-2)%#self.currentUI.options[self.currentUI.chosen].options+1].value
                shove.setWindowMode(self.save.options.resolution.width,self.save.options.resolution.height, {resizable = true})
                SFX:play('select')
            end
        elseif optionKey~='EXIT' then
            if love.keyboard.isDown('right') then
                self.save.options[optionKey]=math.clamp(self.save.options[optionKey]+1,0,100)
                    SFX:setVolume(self.save.options.master_volume*self.save.options.sfx_volume/10000)
                    BGM:setVolume(self.save.options.master_volume*self.save.options.music_volume/10000)
                SFX:play('select')
            elseif love.keyboard.isDown('left') then
                self.save.options[optionKey]=math.clamp(self.save.options[optionKey]-1,0,100)
                SFX:setVolume(self.save.options.master_volume*self.save.options.sfx_volume/10000)
                BGM:setVolume(self.save.options.master_volume*self.save.options.music_volume/10000)
                SFX:play('select')
            end
        end
        if isPressed('x') or isPressed('escape')then
            SFX:play('select')
            self:switchState(self.STATES.MAIN_MENU)
        end
    end,
    draw=function(self)
    end,
    drawText=function(self)
        -- -- self.updateDynamicPatternData(self.patternData)
        SetFont(48)
        love.graphics.print(Localize{'ui',"OPTIONS"}, 100, 60)
        SetFont(36)
        for index, value in ipairs(self.currentUI.options) do
            local name=Localize{'ui',value.value}
            love.graphics.print(name,100,index<#self.currentUI.options and 100+index*50 or 500,0,1,1)
            local key=value.value
            if key~='EXIT' then
                local toPrint=self.save.options[key]
                if key=='language' or key=='resolution' then
                    local languageIndex=1
                    local currentLanguage=self.save.options[key]
                    for i=1,#self.currentUI.options[index].options do
                        if TableEqual(self.currentUI.options[index].options[i].value,currentLanguage) then
                            languageIndex=i
                            break
                        end
                    end
                    toPrint=self.currentUI.options[index].options[languageIndex].text
                end
                love.graphics.printf(toPrint,500,100+index*50,200,'right')
            end
        end
        love.graphics.rectangle("line",100,self.currentUI.chosen<#self.currentUI.options and 100+self.currentUI.chosen*50 or 500,600,50)
        love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
    end
}