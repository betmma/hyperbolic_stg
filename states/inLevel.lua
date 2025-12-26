local G=...
return {
    enter=function(self,previousState)
        local level,scene=self.currentLevel[1],self.currentLevel[2]
        -- transition animation caused this function to be called frames LATER than G.enterLevel (precisely, TRANSITION_IMAGE calls enter at half point of the transition). so I move G.enterLevel code and call replayManager's tweak code here.
        if previousState==self.STATES.CHOOSE_LEVELS or previousState==self.STATES.LOAD_REPLAY then
            self:replaceBackgroundPatternIfIs(BackgroundPattern.MainMenuTesselation,LevelData.getDefaultBackground(level,scene))
            local bgmName=LevelData.getBGMName(level,scene)
            BGM:play(bgmName)
        end
        -- if previousState==self.STATES.GAME_END then
        --     self.backgroundPattern:remove()
        --     self.backgroundPattern=backgroundPattern.FollowingTesselation()
        --     BGM:play('level2')
        -- end
        if previousState==self.STATES.PAUSE then
            return
        end
        AccumulatedTime=0 -- prevent lagging in menu causing accelerated frames in level
        self:removeAll()
        Shape.restore()
        Circle.restore()
        self.levelRemainingFrame=nil
        self.levelRemainingFrameMax=nil
        self.levelIsTimeoutSpellcard=false
        self.preWin=false -- when main enemy dies, it will be set to true. to track if player loses before the win animation ends
        self.UseHypRotShader=true
        self.foregroundTransparency=1
        LevelData[level][scene].make()
    end,
    update=function(self,dt)
        if DEV_MODE and isPressed('v') then
            G.UseHypRotShader=not G.UseHypRotShader
        end
        self.backgroundPattern:update(dt)
        GameObject:updateAll(dt)
        local player=Player.objects[1]
        if isPressed('escape') then
            SFX:play('select')
            -- self:removeAll()
            self:switchState(self.STATES.PAUSE)
        elseif (isPressed('r')or isPressed('w')) and (not player or player.frame>10)then
            self:retryLevel()
        elseif DEV_MODE and isPressed('q')then
            if self.viewMode.mode==self.CONSTANTS.VIEW_MODES.NORMAL and player then
                self.viewMode.mode=self.CONSTANTS.VIEW_MODES.FOLLOW
                self.viewMode.object=player
            elseif self.viewMode.mode==self.CONSTANTS.VIEW_MODES.FOLLOW then
                self.viewMode.mode=self.CONSTANTS.VIEW_MODES.NORMAL
            end
        elseif (player and player.keyIsPressed('x') or isPressed('x')) and (player and player.unlockDiskModels==true or G.replay) then -- note that this A and B or C clause is not equal to B if A else C, since B can be false. in replay mode pressing x still works
            G.viewMode.hyperbolicModel=(G.viewMode.hyperbolicModel+1)%G.CONSTANTS.HYPERBOLIC_MODELS_COUNT
            SFX:play('select')
        end

        if not G.UseHypRotShader or not (player and player.unlockDiskModels==true or G.replay) then
            G.viewMode.hyperbolicModel=G.CONSTANTS.HYPERBOLIC_MODELS.UHP -- without shader only UHP is supported
        end
        
        if self.levelRemainingFrame then
            -- rest time calculation
            self.levelRemainingFrame=self.levelRemainingFrame-1
            if self.levelRemainingFrame<=600 and self.levelRemainingFrame%60==0 then
                SFX:play('timeout',true,2)
            end
            local levelID=G.UIDEF.CHOOSE_LEVELS.levelID
            if self.levelIsTimeoutSpellcard and not G.replay and self.levelRemainingFrame==60 then -- for normal levels it's done by enemy:dieEffect
                ScreenshotManager.preSave(levelID)
            end
            if self.levelRemainingFrame==0 and not G.preWin then -- if time's up and main enemy is already dead, should not trigger win/lose again
                if self.levelIsTimeoutSpellcard then
                    if not G.replay then 
                        ScreenshotManager.save(levelID)
                    end
                    self:win()
                else
                    self:lose()
                end
            end
            self.levelRemainingFrame=math.max(self.levelRemainingFrame,0) -- prevent negative frame count due to main enemy death happening at 0~1 seconds left
        end
    end,
    draw=G.CONSTANTS.DRAW,
    drawText=function(self)
        GameObject:drawTextAll()
        SetFont(18)
        love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
        love.graphics.print("Circle: "..#Circle.objects, 10, 50)
        love.graphics.print("Laser: "..#Laser.LaserUnit.objects, 10, 80)
        love.graphics.print("Loop Event: "..#Event.LoopEvent.objects, 10, 310)
        love.graphics.print("Ease Event: "..#Event.EaseEvent.objects, 10, 340)
        love.graphics.print("Delay Event: "..#Event.DelayEvent.objects, 10, 370)
        if self.replay then
            local speed=1
            if love.keyboard.isDown('lalt') then
                speed=speed+2
            end
            if love.keyboard.isDown('lctrl') then
                speed=speed+1
            end
            if love.keyboard.isDown('lshift') then
                speed=speed-0.5
            end
            local speedText=speed==1 and '' or '['..speed..'x]'
            local num=3-math.ceil(self.levelRemainingFrame/30)%4
            local ellipsis=string.rep('.',num)..string.rep(' ',3-num)
            love.graphics.print(Localize{'ui','replaying'}..ellipsis..speedText, 150, 580)
        end
        local player=Player.objects[1]
        SetFont(48,Fonts.en_us)
        local xt,yt=160,5
        local dx,dy=72,26
        if not player or Shape.distance(170,10,player.x,player.y)>50 or G.viewMode.mode~=G.CONSTANTS.VIEW_MODES.NORMAL then
            xt,yt=160,5
        else
            xt,yt=560,5
        end
        if self.levelRemainingFrame then
            love.graphics.print(string.format('%03d',math.floor(self.levelRemainingFrame/60))..'.', xt, yt)
            SetFont(18,Fonts.en_us)
            love.graphics.print(string.format('%02d',math.floor(self.levelRemainingFrame%60*100/60)), xt+dx, yt+dy)
        end
    end
}