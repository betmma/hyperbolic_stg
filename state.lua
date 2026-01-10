BulletSpawner=require"bulletSpawner"
BackgroundPattern=require"backgroundPattern"
local G={
    CONSTANTS={
        DRAW=function(self)
            Asset:clearBatches()
            local colorRef={love.graphics.getColor()}
            Asset.foregroundBatch:setColor(colorRef[1],colorRef[2],colorRef[3],self.foregroundTransparency)
            Asset.foregroundBatch:add(Asset.backgroundLeft,0,0,0,1,1,0,0)
            Asset.foregroundBatch:add(Asset.backgroundRight,650,0,0,1,1,0,0)
            Asset.setHyperbolicRotateShader()
            GameObject:drawAll() -- including directly calling love.graphics functions like .circle and adding sprite into corresponding batch.
            Asset:flushBatches()
            Asset:drawBatches()
            love.graphics.setShader()
        end,
        ---@enum VIEW_MODE
        VIEW_MODES={NORMAL='NORMAL',FOLLOW='FOLLOW'},
        ---@enum HYPERBOLIC_MODEL
        HYPERBOLIC_MODELS={UHP=0,P_DISK=1,K_DISK=2}, -- use number is because it will be sent to shader
        HYPERBOLIC_MODELS_COUNT=3
    },
}
local function loadState(uppercaseName)
    local camelName=uppercaseName:lower():gsub("_(%w)", string.upper)
    local stateChunk=love.filesystem.load('states/'..camelName..'.lua')
    if not stateChunk then
        error('State '..uppercaseName..' ('..camelName..') not found')
    end
    return stateChunk(G)
end
G={
    backgroundPattern=BackgroundPattern.MainMenuTesselation(),
    switchState=function(self,state)
        if not self.UIDEF[state] then
            error("State "..state.." not defined")
        end
        if self.UIDEF[state].TRANSITION then
            error("Illegal to switch to a transition state directly")
        end
        EventManager.post(EventManager.EVENTS.SWITCH_STATE,self.STATE,state)

        local lastState=self.STATE

        -- check if there is transition data between current state and the state to switch to
        local transitionData=self.transitionData[lastState]
        if transitionData and transitionData[state] then
            local data=transitionData[state]
            local transitionState=data.transitionState or self.STATES.TRANSITION_SLIDE
            local args={nextState=state,lastState=lastState}
            if transitionState==self.STATES.TRANSITION_SLIDE then
                local slideDirection=data.slideDirection
                local slideRatio=data.slideRatio or 0.15
                local slideFrame=data.slideFrame or 300
                args.slideDirection=slideDirection
                args.slideRatio=slideRatio
                args.transitionFrame=slideFrame
            elseif transitionState==self.STATES.TRANSITION_IMAGE then
                local image=data.image
                local thershold=data.thershold or 0.5
                local frame=data.fadeFrame or 60
                args.image=image
                args.thershold=thershold
                args.transitionFrame=frame
            end
            self.STATE=transitionState
            self.currentUI=self.UIDEF[self.STATE]
            self.currentUI.enter(self,args)
            return
        end

        self.STATE=state
        self.currentUI=self.UIDEF[self.STATE]
        if self.UIDEF[state].enter then
            self.UIDEF[state].enter(self,lastState)
        end
    end,
    replaceBackgroundPatternIfNot=function(self,patternClass)
        if getmetatable(self.backgroundPattern)~=patternClass then
            self.backgroundPattern:remove()
            self.backgroundPattern=patternClass()
        end
    end,
    replaceBackgroundPatternIfIs=function(self,patternClass,patternClass2)
        if getmetatable(self.backgroundPattern)==patternClass then
            self.backgroundPattern:remove()
            self.backgroundPattern=patternClass2()
        end
    end,
    CONSTANTS=G.CONSTANTS,
    STATES={
        MAIN_MENU='MAIN_MENU',
        OPTIONS='OPTIONS',
        MUSIC_ROOM='MUSIC_ROOM',
        NICKNAMES='NICKNAMES',
        UPGRADES='UPGRADES',
        CHOOSE_LEVELS='CHOOSE_LEVELS',
        IN_LEVEL='IN_LEVEL',
        PAUSE='PAUSE',
        GAME_END='GAME_END', -- either win or lose a scene
        SAVE_REPLAY='SAVE_REPLAY',
        SAVE_REPLAY_ENTER_NAME='SAVE_REPLAY_ENTER_NAME',
        LOAD_REPLAY='LOAD_REPLAY',
        ENDING='ENDING', -- ending screen after beating the game
        TRANSITION_SLIDE='TRANSITION_SLIDE', -- a state that slides the screen. Draw both last state and next state, while update is only called for next state
        TRANSITION_IMAGE='TRANSITION_IMAGE', -- an image that covers the screen and fades
    },
    STATE=...,
    transitionData={ -- transitionData[STATE1][STATE2] is the transition data from STATE1 to STATE2. like, if transitionData[MAIN_MENU][CHOOSE_LEVELS].slideDirection='up', then when switching from MAIN_MENU to CHOOSE_LEVELS, the texts of both states will slide up.
        MAIN_MENU={
            CHOOSE_LEVELS={
                slideDirection='up'
            },
            LOAD_REPLAY={
                slideDirection='left'
            },
            OPTIONS={
                slideDirection='right'
            },
            MUSIC_ROOM={
                slideDirection='down'
            },
            NICKNAMES={
                slideDirection='up'
            },
        },
        OPTIONS={
            MAIN_MENU={
                slideDirection='left'
            }
        },
        MUSIC_ROOM={
            MAIN_MENU={
                slideDirection='up'
            }
        },
        NICKNAMES={
            MAIN_MENU={
                slideDirection='down'
            },
            ENDING={
                transitionState='TRANSITION_IMAGE'
            }
        },
        GAME_END={
            ENDING={
                transitionState='TRANSITION_IMAGE'
            }
        },
        ENDING={
            MAIN_MENU={
                transitionState='TRANSITION_IMAGE'
            }
        },
        UPGRADES={
            CHOOSE_LEVELS={
                slideDirection='down'
            }
        },
        CHOOSE_LEVELS={
            UPGRADES={
                slideDirection='up'
            },
            MAIN_MENU={
                slideDirection='down'
            },
            IN_LEVEL={
                transitionState='TRANSITION_IMAGE',
            }
        },
        LOAD_REPLAY={
            MAIN_MENU={
                slideDirection='right'
            },
            IN_LEVEL={
                transitionState='TRANSITION_IMAGE',
            }
        },
    },
    currentLevel={},
    --- Warning: besides setting max time, do not access it in any level logic (like for random seed). it is 1 frame less in replay (dunno why) so using it will break replays.
    ---@type integer|nil
    levelRemainingFrame=nil,
    ---@type integer|nil
    levelRemainingFrameMax=nil,
    ---@type boolean|nil
    levelIsTimeoutSpellcard=nil,
    ---@type {level: integer, scene: integer}
    lastLevel={},
    mainEnemy=nil,
    preWin=nil,
    frame=0,
    sceneTempObjs={},
    ---@type replayData|nil
    replay=nil,
    ---@type GameObject|nil
    spellNameText=nil,
    ---@type boolean
    UseHypRotShader=true,
    ---@type boolean
    -- to replay dialogue when entering level (spaghetti???)
    lshiftDownWhenEnteringLevel=false,

    DISK_RADIUS_BASE={
        [G.CONSTANTS.HYPERBOLIC_MODELS.P_DISK]=1, -- Poincare disk
        [G.CONSTANTS.HYPERBOLIC_MODELS.K_DISK]=1, -- Klein disk
    },
    ---@type {mode: VIEW_MODE, hyperbolicModel: HYPERBOLIC_MODEL, object: GameObject|nil, viewOffset: pos}
    viewMode={
        mode=G.CONSTANTS.VIEW_MODES.NORMAL,
        hyperbolicModel=G.CONSTANTS.HYPERBOLIC_MODELS.UHP,
        object=...,
        viewOffset={x=0,y=0}
    },
    UIDEF={
    }
}

for stateName,state in pairs(G.STATES) do
    G.UIDEF[state]=loadState(state)
end

G:switchState(G.STATES.MAIN_MENU)


local SaveManager=require"saveManager"
G.saveData=function(self)
    SaveManager:saveData(self)
end
-- an example of its structure
---@class Save
---@field levelData {[integer]: {passed: integer, tryCount: integer, firstPass: integer, firstPerfect: integer}}
---@field levelUnlock integer -- max level unlocked
---@field options {master_volume: integer, music_volume: integer, sfx_volume: integer, language: string, resolution: {width: integer, height: integer}}
---@field upgrades {[string]: {bought: boolean}}}
---@field defaultName string
---@field playTimeTable {playTimeOverall: number, playTimeInLevel: number}
---@field extraUnlock {[string]: boolean} -- secret level unlocks, format not decided
---@field nicknameUnlock {[string]: boolean}
---@field statistics {[string]: number}
---@type Save
G.save={
    levelData={[1]={passed=0,tryCount=0,firstPass=0,firstPerfect=0}},
    levelUnlock=1,
    options={master_volume=100,},
    upgrades={{{bought=true}}},
    defaultName='',-- the default name when saving replay
    playTimeTable={
        playTimeOverall=0,
        playTimeInLevel=0,
    },
    extraUnlock={
        shopUnlocked=false
    }, -- secret level unlocks, format not decided
    nicknameUnlock={},
    statistics={},
}
G.loadData=function(self)
	SaveManager:loadData(self)
    SFX:setVolume(self.save.options.master_volume*self.save.options.sfx_volume/10000)
    BGM:setVolume(self.save.options.master_volume*self.save.options.music_volume/10000)
    self:saveData()
end
G:loadData()

G.language=G.save.options.language--'zh_cn'--'en_us'--

---@param self table
---@return integer "number of passed scenes"
---@return integer "number of all scenes"
---@return integer "number of perfect scenes"
G.countPassedSceneNum=function(self)
    local allSceneCount,passedSceneCount,perfectSceneCount=0,0,0
    for id,value in pairs(LevelData.ID2LevelScene) do
        allSceneCount=allSceneCount+1
        if self.save.levelData[id].passed>0 then
            passedSceneCount=passedSceneCount+1
        end
        if self.save.levelData[id].passed==2 then
            perfectSceneCount=perfectSceneCount+1
        end
    end
    return passedSceneCount,allSceneCount, perfectSceneCount
end
G.win=function(self)
    self:switchState(self.STATES.GAME_END)
    local inReplay=self:leaveLevel(true)
    if inReplay then
        return -- don't change savedata and other things
    end
    self.won_current_scene=true -- it's only used to determine the displayed text in end screen to be "win" or "lose"
    local winLevel=1
    if Player.objects[1].hurt==false then
        winLevel=2
    end
    local level=self.UIDEF.CHOOSE_LEVELS.chosenLevel
    local scene=self.UIDEF.CHOOSE_LEVELS.chosenScene
    local levelID=LevelData[level][scene].ID
    local saveData=self.save.levelData[levelID]
    saveData.passed=math.max(saveData.passed,winLevel)
    if saveData.firstPass==0 then
        saveData.firstPass=saveData.tryCount
    end
    if saveData.firstPerfect==0 and winLevel==2 then
        saveData.firstPerfect=saveData.tryCount
    end
    EventManager.post(EventManager.EVENTS.WIN_LEVEL,{id=levelID,level=level,scene=scene},Player.objects[1],winLevel==2)
    self:saveData()
end
G.lose=function(self)
    self:switchState(self.STATES.GAME_END)
    local inReplay=self:leaveLevel()
    if inReplay then
        return -- don't change savedata and other things
    end
    self.won_current_scene=false -- it's only used to determine the displayed text in end screen to be "win" or "lose"
    local level=self.UIDEF.CHOOSE_LEVELS.chosenLevel
    local scene=self.UIDEF.CHOOSE_LEVELS.chosenScene
    local levelID=LevelData[level][scene].ID
    EventManager.post(EventManager.EVENTS.LOSE_LEVEL,{id=levelID,level=level,scene=scene}) -- retry wont call this function, so use this to count lose times is not accurate. need to listen to LEAVE_LEVEL event and exclude win=true cases instead.
    self:saveData()
end
G.enterLevel=function(self,level,scene)
    self.currentLevel={level,scene}
    self.lshiftDownWhenEnteringLevel=love.keyboard.isDown('lshift')
    self:switchState(self.STATES.IN_LEVEL)
end
-- It's called when leaving the level, either by winning, losing (these 2 are called from enemy or player object), G.retryLevel (pressing "R" or instant retry upgrade called from player) or exiting from pause menu. return true if in replay (for G.win or lose to skip changing savedata and other things)
---@param self table
---@param win boolean|nil whether the player just won the level
G.leaveLevel=function(self,win)
    local level=self.UIDEF.CHOOSE_LEVELS.chosenLevel
    local scene=self.UIDEF.CHOOSE_LEVELS.chosenScene
    EventManager.post(EventManager.EVENTS.LEAVE_LEVEL,level,scene,self.replay~=nil,win)
    if LevelData[level][scene].leave then
        LevelData[level][scene].leave()
    end
    if self.replay then
        self.replay=nil
        self:switchState(self.STATES.LOAD_REPLAY)
        self.save.upgrades=self.upgradesRef
        return true
    end
    self.lastLevel={level,scene}
    self:_incrementTryCount()
end
G.retryLevel=function(self)
    self:leaveLevel()
    if self.replay then -- if in "replay" replay "replay" (why so strange)
        ReplayManager.runReplay(self.UIDEF.LOAD_REPLAY.slot)
    else
        self:enterLevel(self.UIDEF.CHOOSE_LEVELS.chosenLevel,self.UIDEF.CHOOSE_LEVELS.chosenScene)
    end
end
G._incrementTryCount=function(self)
    local level=self.UIDEF.CHOOSE_LEVELS.chosenLevel
    local scene=self.UIDEF.CHOOSE_LEVELS.chosenScene
    local levelID=LevelData[level][scene].ID
    local saveData=self.save.levelData[levelID]
    saveData.tryCount=saveData.tryCount+1
    self:saveData()
end
G.update=function(self,dt)
    self.frame=self.frame+1
    self.currentUI=self.UIDEF[self.STATE]

    NoticeManager:update()
    -- replay speed control
    if G.replay then
        if love.keyboard.isDown('lalt') then -- +2x
            self.currentUI.update(self,dt)
            self.currentUI.update(self,dt)
        end
        if love.keyboard.isDown('lctrl') then -- +1x
            self.currentUI.update(self,dt)
        end
        if not love.keyboard.isDown('lshift') or self.frame%2==0 then -- -0.5x
            self.currentUI.update(self,dt)
        end
    else
        self.currentUI.update(self,dt)
    end

    -- playtime calculation
    if self.STATE==self.STATES.IN_LEVEL then
        self.save.playTimeTable.playTimeInLevel=self.save.playTimeTable.playTimeInLevel+dt
    end
    self.save.playTimeTable.playTimeOverall=self.save.playTimeTable.playTimeOverall+dt

end
G.hyperbolicRotateShader=ShaderScan:load_shader("shaders/hyperbolicRotateM.glsl")
local canvas=love.graphics.newCanvas(WINDOW_WIDTH,WINDOW_HEIGHT,{msaa=8})
G.draw=function(self)
    -- love.graphics.setCanvas(canvas)
    -- love.graphics.clear({0,0,0,1})
    shove.beginLayer('main')
    self.currentUI=self.UIDEF[self.STATE]
    if G.viewMode.mode==G.CONSTANTS.VIEW_MODES.NORMAL then
        self:_drawBatches()
    elseif G.viewMode.mode==G.CONSTANTS.VIEW_MODES.FOLLOW then
        if not G.viewMode.object then
            G.viewMode.object=Player.objects[1]
        end
        local object=G.viewMode.object
        if self.backgroundPattern.noZoom then
            self.backgroundPattern:draw()
        end
        love.graphics.push()
        self:followModeTransform()
        if object.moveMode==Player.moveModes.Natural then
            object:testRotate(-object.naturalDirection) -- rotate non-sprite objects to make player face up. Note that due to love2d limitation, it *changes* objects' coordinates to achieve hyperbolic rotation. sprite objects are rotated by hyperbolicRotateShader.
        end
        self:_drawBatches()
        love.graphics.setShader()
        if object.moveMode==Player.moveModes.Natural then
            object:testRotate(0,true) -- "true" means restore objects' coordinates
        end
        love.graphics.pop()
    end

    -- love.graphics.setCanvas()
    if Player.objects[1] and not Player.objects[1].removed then
        Player.objects[1]:invertShaderEffect()
    else
        Player:invertShaderEffect()
    end
    -- love.graphics.draw(canvas, 0, 0)
    love.graphics.setShader()
    shove.endLayer()
    shove.beginLayer('text')
    self:drawText()
    shove.endLayer()
end
G.drawText=function(self)
    self.currentUI.drawText(self)
    NoticeManager:drawText()
end
G._drawBatches=function(self)
    if not self.backgroundPattern.noZoom or G.viewMode.mode==G.CONSTANTS.VIEW_MODES.NORMAL then
        self.backgroundPattern:draw()
    end
    self.currentUI.draw(self)
end
-- transform the coordinate system to make the player in the center of the screen. If [getParams] is true, return the translation and scaling parameters instead of applying them. (for shader use)
G.followModeTransform=function(self, getParams)
    if G.UseHypRotShader then
        return 0,0,1
    end
    local screenWidth, screenHeight = WINDOW_WIDTH, WINDOW_HEIGHT
    local wantedX, wantedY=screenWidth/2,screenHeight/2 -- after translation and scaling, the position of the player (default is center of the screen)
    if G.viewMode.viewOffset then
        wantedX=wantedX+G.viewMode.viewOffset.x
        wantedY=wantedY+G.viewMode.viewOffset.y
    end
    local scale=(wantedY-Shape.axisY)/(G.viewMode.object.y-Shape.axisY)
    local translateX,translateY=wantedX-G.viewMode.object.x*scale,wantedY-G.viewMode.object.y*scale
    if getParams then
        return translateX,translateY,scale
    end
    love.graphics.translate(translateX,translateY)
    love.graphics.scale(scale)
    -- calculate screen rectangle position, to test view port culling (doesn't improve performance so commented out)
    -- local edgeLength=30
    -- local screenRect={xmin=(-translateX-edgeLength)/scale,ymin=(-translateY-edgeLength)/scale,xmax=(-translateX+screenWidth+edgeLength)/scale,ymax=(-translateY+screenHeight+edgeLength)/scale}
    -- G.screenRect=screenRect
end
G.antiFollowModeTransform=function(self)
    local scale=(WINDOW_HEIGHT/2-Shape.axisY)/(G.viewMode.object.y-Shape.axisY)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local wantedX, wantedY=screenWidth/2,screenHeight/2 -- after translation and scaling, the position of the player (default is center of the screen)
    if G.viewMode.viewOffset then
        wantedX=wantedX+G.viewMode.viewOffset.x
        wantedY=wantedY+G.viewMode.viewOffset.y
    end
    love.graphics.scale(1/scale)
    love.graphics.translate(-(wantedX-G.viewMode.object.x*scale),-(wantedY-G.viewMode.object.y*scale))
end

-- remove all objects in the scene
G.removeAll=function(self)
    Asset:clearBatches()
    GameObject:removeAll()
    if self.spellNameText and not self.spellNameText.removed then
        self.spellNameText:remove()
    end
    for i,obj in pairs(self.sceneTempObjs) do
        if not obj.removed then
            obj:remove()
        end
    end
    self.sceneTempObjs={}
end

return G