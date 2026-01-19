return {
    enter=function(self,lastState)
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.NORMAL
        self.currentUI.enterFrame=self.frame
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
        BGM:play('title')
        local newMaxUnlock=#LevelData
        local passedSceneCount=self:countPassedSceneNum()
        for i=1,newMaxUnlock do -- find new max unlock
            if passedSceneCount<LevelData.needPass[i] then
                newMaxUnlock=i
                break
            end
        end
        for newUnlockedLevel=self.save.levelUnlock+1,newMaxUnlock do
            NoticeManager:add({'unlockLevel',newUnlockedLevel})
        end
        self.save.levelUnlock=newMaxUnlock
    end,
    chosenLevel=1,
    chosenScene=1,
    levelID=LevelData[1][1].ID,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        local level=self.currentUI.chosenLevel
        local scene=self.currentUI.chosenScene
        local levelNum=self.save.levelUnlock
        local sceneNum=#LevelData[level]
        local levelID=LevelData[level][scene].ID
        self.currentUI.levelID=levelID
        if isPressed('down') then
            self.currentUI.chosenScene=self.currentUI.chosenScene%sceneNum+1
            SFX:play('select')
            G.UIDEF.CHOOSE_LEVELS.transparency=0
        elseif isPressed('up') then
            self.currentUI.chosenScene=(self.currentUI.chosenScene-2)%sceneNum+1
            SFX:play('select')
            G.UIDEF.CHOOSE_LEVELS.transparency=0
        elseif isPressed('right') then
            self.currentUI.chosenLevel=self.currentUI.chosenLevel%levelNum+1
            self.currentUI.chosenScene=math.min(self.currentUI.chosenScene,#LevelData[self.currentUI.chosenLevel])
            SFX:play('select')
            G.UIDEF.CHOOSE_LEVELS.transparency=0
        elseif isPressed('left') then
            self.currentUI.chosenLevel=(self.currentUI.chosenLevel-2)%levelNum+1
            self.currentUI.chosenScene=math.min(self.currentUI.chosenScene,#LevelData[self.currentUI.chosenLevel])
            SFX:play('select')
            G.UIDEF.CHOOSE_LEVELS.transparency=0
        elseif isPressed('z') then
            SFX:play('select')
            self:enterLevel(level,scene)
        elseif isPressed('c') and self.save.extraUnlock.shopUnlocked then
            SFX:play('select')
            self:switchState(self.STATES.UPGRADES)
        elseif isPressed('x') or isPressed('escape')then
            SFX:play('select')
            self:switchState(self.STATES.MAIN_MENU)
        elseif DEV_MODE and isPressed('[') then
            SFX:play('select')
            self.save.levelData[levelID].passed=math.max(self.save.levelData[levelID].passed-1,0)
        elseif DEV_MODE and isPressed(']') then
            SFX:play('select')
            self.save.levelData[levelID].passed=math.min(self.save.levelData[levelID].passed+1,2)
        end
        local digits={['1']=1,['2']=2,['3']=3,['4']=4,['5']=5,['6']=6,['7']=7,['8']=8,['9']=9,['0']=10,['-']=11,['=']=12}
        for key,value in pairs(digits) do
            if isPressed(key)then
                SFX:play('select')
                self.currentUI.chosenLevel=math.clamp(value,1,levelNum)
                self.currentUI.chosenScene=1
            end
            if isPressed('kp'..key) then
                SFX:play('select')
                self.currentUI.chosenScene=math.clamp(value,1,sceneNum)
            end
        end
        local transparency=G.UIDEF.CHOOSE_LEVELS.transparency or 1
        transparency=transparency*0.9+0.1
        G.UIDEF.CHOOSE_LEVELS.transparency=transparency
    end,
    draw=function(self)
    end,
    drawText=function(self)
        -- self.updateDynamicPatternData(self.patternData)
        local level=self.currentUI.chosenLevel
        local scene=self.currentUI.chosenScene
        local levelID=LevelData[level][scene].ID

        local color={love.graphics.getColor()}

        local deltaFrame=self.frame-self.currentUI.enterFrame
        local leftOffset,rightOffset=300,300
        local ratio=0.8^deltaFrame
        leftOffset,rightOffset=leftOffset*ratio,rightOffset*ratio
        love.graphics.translate(-leftOffset,0) -- left part begins
        -- print Level x and Scene x (left part)
        SetFont(36)
        local levelStr=LevelData.getLevelStr(level)
        local xBase=100
        local yBase=50
        love.graphics.print(Localize{'ui','level',level=levelStr},xBase,yBase,0,1,1)
        SetFont(30)
        yBase=yBase+50
        local yGap=40
        for index, value in ipairs(LevelData[level]) do
            local levelID=LevelData[level][index].ID
            love.graphics.setColor(.7,.6,.6)
            if self.save.levelData[levelID].passed==1 then
                love.graphics.setColor(.7,1,.7)
            elseif self.save.levelData[levelID].passed==2 then
                love.graphics.setColor(1,1,0.5)
            end
            -- print X-X text
            love.graphics.print(levelStr.."-"..index,xBase,yBase+index*yGap,0,1,1)
            -- draw a square indicating dialogue level
            love.graphics.setColor(1,1,1)
            if LevelData[level][index].dialogue then
                love.graphics.rectangle("fill",xBase-20,yBase+index*yGap+10,10,10)
            end
        end
        -- draw rectangle to mark current selected scene (left part)
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle("line",xBase,yBase+scene*yGap,200,40)

        love.graphics.translate(leftOffset+rightOffset,0) -- right part begins
        -- add smooth transition when switching scenes or levels (setting the transparency of screenshot and quote)
        local transparency=G.UIDEF.CHOOSE_LEVELS.transparency or 1
        love.graphics.setColor(color[1],color[2],color[3],transparency)

        -- show screenshot
        if ScreenshotManager.data[levelID].batch then
            local x0,y0=325,25
            local width,height=500,600
            local data=ScreenshotManager.data[levelID]
            local ratio=0.75
            data.batch:clear()
            data.batch:add(data.quad,x0,y0,0,ratio/data.zoom,ratio/data.zoom,0,0)
            data.batch:flush()
            love.graphics.draw(data.batch)
            love.graphics.rectangle("line",x0,y0,width*ratio,height*ratio)
        end

        -- show quote
        love.graphics.rectangle("line",325,500,400,80)
        local text=Localize{'levelData','defaultQuote'}
        local save=self.save.levelData[levelID]
        if save.passed>=1 then
            text=Localize{'levelData','spellcards',LevelData[level][scene].ID,'quote'}
        elseif save.tryCount>=10 then -- show hint text
            local hintText, success=Localize{'levelData','spellcards',LevelData[level][scene].ID,'hint'}
            if success then -- some levels may not have hint text
                love.graphics.setColor(0.5,1,0.5,transparency)
                text=hintText
            end
        end
        SetFont(18)
        love.graphics.printf(text,330,510,380,"left",0,1,1)

        -- show try count / first pass / first perfect data
        love.graphics.setColor(color[1],color[2],color[3],transparency)
        SetFont(14)
        love.graphics.printf(Localize{'ui','tryCount',tries=save.tryCount},710,325,90,'left')
        love.graphics.printf(Localize{'ui','firstPass',tries=save.firstPass},710,350,90,'left')
        love.graphics.printf(Localize{'ui','firstPerfect',tries=save.firstPerfect},710,390,90,'left')

        love.graphics.setColor(color[1],color[2],color[3],color[4]) -- below doesn't apply transparency

        -- show number of passed levels needed for next level
        local passedSceneCount,allSceneCount=self:countPassedSceneNum()
        local needSceneCount=LevelData.needPass[level]
        SetFont(14)
        love.graphics.printf(Localize{'ui','passedScenes',passed=passedSceneCount,all=allSceneCount},710,5,90,'left')
        love.graphics.printf(Localize{'ui','needSceneToUnlockNextLevel',need=needSceneCount},710,50,90,'left')

        -- show play time
        local playTimeTable=self.save.playTimeTable
        love.graphics.printf(Localize{'ui','playTimeOverall',playtime=math.formatTime(playTimeTable.playTimeOverall)},710,100,90,'left')
        love.graphics.printf(Localize{'ui','playTimeInLevel',playtime=math.formatTime(playTimeTable.playTimeInLevel)},710,130,90,'left')

        love.graphics.translate(-rightOffset,0) -- right part ends

        -- show "C: upgrades menu"
        if self.save.extraUnlock.shopUnlocked then
            SetFont(18)
            love.graphics.printf(Localize{'ui','levelUIHint'},100,570,380,"left",0,1,1)
        end
    end,
}