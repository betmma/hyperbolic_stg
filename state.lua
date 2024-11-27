local levelData=require"levelData"
local function keyBindValueCalc(self,addKey,subKey,valueName,valueMax)
    if isPressed(addKey)then
        self.currentUI[valueName]=self.currentUI[valueName]%valueMax+1
        SFX:play('select')
    elseif isPressed(subKey)then
        self.currentUI[valueName]=(self.currentUI[valueName]-2)%valueMax+1
        SFX:play('select')
    end
end
local function optionsCalc(self,execFuncs)
    local size=#self.currentUI.options
    keyBindValueCalc(self,'down','up','chosen',size)
    if isPressed('z') then
        local value=self.currentUI.options[self.currentUI.chosen].value
        SFX:play('select')
        if execFuncs[value]then
            execFuncs[value](self)
        end
    end
end
local G={
    switchState=function(self,state)
        self.STATE=state
        self.currentUI=self.UIDEF[self.STATE]
        if self.UIDEF[state].enter then
            self.UIDEF[state].enter(self)
        end
    end,
    CONSTANTS={
    },
    STATES={
        MAIN_MENU='MAIN_MENU',
        OPTIONS='OPTIONS',
        UPGRADES='UPGRADES',
        CHOOSE_LEVELS='CHOOSE_LEVELS',
        IN_LEVEL='IN_LEVEL',
        PAUSE='PAUSE',
        GAME_END='GAME_END',--either win or lose
        SAVE_REPLAY='SAVE_REPLAY',
        SAVE_REPLAY_ENTER_NAME='SAVE_REPLAY_ENTER_NAME',
        LOAD_REPLAY='LOAD_REPLAY'
    },
    STATE=...,
    UIDEF={
        MAIN_MENU={
            options={
                {text='Start',value='START'},
                {text='Replay',value='REPLAY'},
                {text='Options',value='OPTIONS'},
                {text='Exit',value='EXIT'},
            },
            chosen=1,
            update=function(self,dt)
                optionsCalc(self,{EXIT=love.event.quit,START=function(self)self.STATE=self.STATES.CHOOSE_LEVELS end,
                REPLAY=function(self)self:switchState(self.STATES.LOAD_REPLAY)end,
                OPTIONS=function(self)self.STATE=self.STATES.OPTIONS end})
            end,
            draw=function(self)
            end,
            drawText=function(self)
                self.updateDynamicPatternData(self.patternData)
                SetFont(96)
                love.graphics.print("Hyperbolic\n   STG",200,100,0,1,1)
                SetFont(36)
                for index, value in ipairs(self.currentUI.options) do
                    local name=value.text
                    love.graphics.print(name,300,300+index*50,0,1,1)
                end
                love.graphics.rectangle("line",300,300+self.currentUI.chosen*50,200,50)
                love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
            end
        },
        OPTIONS={
            options={
                {text='Master Volume',value='master_volume'},
                {text='Music Volume',value='music_volume'},
                {text='SFX Volume',value='sfx_volume'},
                {text='Exit',value='EXIT'},
            },
            chosen=1,
            update=function(self,dt)
                optionsCalc(self,{EXIT=function(self)self.STATE=self.STATES.MAIN_MENU;self:saveData() end})
                local optionKey=self.currentUI.options[self.currentUI.chosen].value
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
                elseif isPressed('x') or isPressed('escape')then
                    SFX:play('select')
                    self.STATE=self.STATES.MAIN_MENU
                end
            end,
            draw=function(self)
            end,
            drawText=function(self)
                self.updateDynamicPatternData(self.patternData)
                SetFont(48)
                love.graphics.print("Options", 100, 60)
                SetFont(36)
                for index, value in ipairs(self.currentUI.options) do
                    local name=value.text
                    love.graphics.print(name,100,index<#self.currentUI.options and 100+index*50 or 500,0,1,1)
                    if value.value~='EXIT' then
                        love.graphics.printf(self.save.options[value.value],600,100+index*50,100,'right')
                    end
                end
                love.graphics.rectangle("line",100,self.currentUI.chosen<#self.currentUI.options and 100+self.currentUI.chosen*50 or 500,600,50)
                love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
            end
        },
        UPGRADES={
            upgrades={
                increaseHP={
                    name='Increase HP',
                    description='Increase HP by 1',
                    cost=50,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.hp=player.hp+1
                        player.maxhp=player.maxhp+1
                    end
                },
                regenerate={
                    name='Regenerate',
                    description='Increase HP by 0.024 per second',
                    cost=40,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.hpRegen=player.hpRegen+0.024
                    end
                },
                unyielding={
                    name='Unyielding',
                    description='Shockwave when you are hit is bigger',
                    cost=30,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.dieShockwaveRadius=player.dieShockwaveRadius+1
                    end
                },
                acrobat={
                    name='Acrobat',
                    description='Each graze gives 0.005 HP',
                    cost=40,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.grazeHpRegen=player.grazeHpRegen+0.005
                    end
                },
                homingShot={
                    name='Homing Shot',
                    description='2 rows of your shot become homing',
                    cost=50,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.shootRows.front.straight.num=player.shootRows.front.straight.num-2
                        player.shootRows.front.homing.num=player.shootRows.front.homing.num+2
                    end
                },
                sideShot={
                    name='Side Shot',
                    description='Add 4 rows of side shot (on each side)',
                    cost=30,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.shootRows.side.straight.num=player.shootRows.side.straight.num+4
                    end
                },
                backShot={
                    name='Back Shot',
                    description='Add 8 rows of back shot',
                    cost=50,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.shootRows.back.straight.num=player.shootRows.back.straight.num+8
                    end
                },
            },
            -- note that: options below are line first, but chosen are coordinates where x is first. So to get an option use self.currentUI.options[chosen[2]][chosen[1]]. However in save it's stored in order of (x, y), so to get if an upgrade is bought use self.save.upgrades[chosen[1]][chosen[2]]. (this seems silly but when drawing upgrades x and y are aligned to real x and y (x go up means moving right))
            -- need is also (x, y)
            options={
                {
                    {
                        upgrade='increaseHP',
                        connect={down=true,right=true},
                        need={}
                    },
                    {
                        upgrade='regenerate',
                        connect={down=true,left=true,right=true},
                        need={{1,1}}
                    },
                    {
                        upgrade='acrobat',
                        connect={left=true},
                        need={{2,1}}
                    },
                    {
                    }
                },
                {
                    {
                        connect={up=true,down=true},
                        need={}
                    },
                    {
                        upgrade='unyielding',
                        connect={up=true,},
                        need={{2,1}}
                    },
                    {},
                    {}
                },
                {
                    {
                        upgrade='homingShot',
                        connect={up=true,right=true},
                        need={}
                    },
                    {
                        connect={left=true,right=true,down=true},
                        need={{1,3}}
                    },
                    {
                        upgrade='sideShot',
                        connect={left=true},
                        need={{1,3}}
                    },
                    {}
                },
                {
                    {},
                    {
                        connect={up=true,right=true},
                        need={{1,3}}
                    },
                    {
                        upgrade='backShot',
                        connect={left=true},
                        need={{1,3}}
                    },
                    {}
                },
            },
            chosen={1,1},
            needSatisfied=function(self,option)
                if not option.need then
                    return true
                end
                for key, value in pairs(option.need) do
                    if self.save.upgrades[value[1]][value[2]].bought==false then
                        return false
                    end
                end
                return true
            end,
            calculateRestXP=function(self)
                local xp=0
                for k,value in ipairs(self.save.levelData) do
                    for i=1,#value do
                        local pass=self.save.levelData[k][i].passed
                        if pass==1 then
                            xp=xp+10
                        elseif pass==2 then
                            xp=xp+12
                        end
                    end
                end
                local options=self.currentUI.options
                for k,value in ipairs(options) do
                    for i=1,#value do
                        local option=value[i]
                        if option.upgrade and self.save.upgrades[i][k].bought then
                            xp=xp-self.currentUI.upgrades[option.upgrade].cost
                        end
                    end
                end
                return xp
            end,
            update=function(self,dt)
                local options=self.currentUI.options
                local chosen=self.currentUI.chosen
                local option=options[chosen[2]][chosen[1]]
                local dirValues={down={0,1},up={0,-1},left={-1,0},right={1,0}}
                for key, dir in pairs(dirValues) do
                    if isPressed(key) then
                        local dx,dy=dir[1],dir[2]
                        local newx,newy=chosen[1]+dx,chosen[2]+dy
                        if option.connect[key] and(self.currentUI.needSatisfied(self,options[newy][newx])~=false) then
                            self.currentUI.chosen={newx,newy} 
                        end
                        break
                    end
                end
                if isPressed('x') or isPressed('escape')then
                    SFX:play('select')
                    self.STATE=self.STATES.CHOOSE_LEVELS
                    self:saveData()
                elseif isPressed('d') then
                    SFX:play('cancel',true)
                    for k,value in ipairs(options) do
                        for i=1,#value do
                            self.save.upgrades[i][k].bought=false
                        end
                    end
                    self.currentUI.chosen={1,1}
                elseif isPressed('z') then
                    local restXP=self.currentUI.calculateRestXP(self)
                    if option.upgrade then
                        local upgrade=self.currentUI.upgrades[option.upgrade]
                        local bought=self.save.upgrades[chosen[1]][chosen[2]].bought
                        if bought then
                            self.save.upgrades[chosen[1]][chosen[2]].bought=false
                            SFX:play('select')
                            -- need to cancel all upgrades related to this upgrade
                            local function recursiveCancel(x,y)
                                for k,value in ipairs(options) do
                                    for i=1,#value do
                                        local option=value[i]
                                        local need=option.need
                                        if not need then
                                            goto continue
                                        end
                                        for key, value in pairs(need) do
                                            if x==value[1] and y==value[2] and self.save.upgrades[i][k].bought==true then
                                                self.save.upgrades[i][k].bought=false
                                                recursiveCancel(i,k)
                                                break
                                            end
                                        end
                                        
                                        ::continue::
                                    end
                                end
                            end
                            recursiveCancel(chosen[1],chosen[2])
                        elseif restXP<upgrade.cost then
                            SFX:play('cancel',true)
                        else
                            self.save.upgrades[chosen[1]][chosen[2]].bought=true
                            SFX:play('select')
                        end
                    end
                end
            end,
            draw=function(self)
            end,
            drawText=function(self)
                local color={love.graphics.getColor()}
                self.updateDynamicPatternData(self.patternData)

                --draw upgrades
                local options=self.currentUI.options
                local xbegin,ybegin=50,100
                local dx,size=50,30
                local gap=(dx-size)/2
                local sizeX,sizeY=#self.currentUI.options[1],#self.currentUI.options
                local dirValues={down={0,1},up={0,-1},left={-1,0},right={1,0}}
                for x=1,sizeX do
                    for y=1,sizeY do
                        local option=options[y][x]
                        if self.currentUI.needSatisfied(self,option) then
                            if option.connect then
                                for key, value in pairs(option.connect) do
                                    local dirValue=dirValues[key]
                                    local nx,ny=x+dirValue[1]/2,y+dirValue[2]/2
                                    love.graphics.setColor(1,1,1)
                                    love.graphics.line(dx/2+xbegin+dx*x,dx/2+ybegin+dx*y,dx/2+xbegin+dx*nx,dx/2+ybegin+dx*ny)
                                end
                            end
                            if not option.upgrade then
                                goto continue
                            end
                            local bought=self.save.upgrades[x][y].bought
                            if bought then
                                love.graphics.setColor(1,1,1)
                            else
                                love.graphics.setColor(.8,.8,.8)
                            end
                            love.graphics.rectangle(bought and "fill" or "line",gap+xbegin+dx*x,gap+ybegin+dx*y,size,size)
                        end
                        ::continue::
                    end
                end
                -- draw chosen
                local chosen=self.currentUI.chosen
                local chosenOption=options[chosen[2]][chosen[1]]
                local x,y=chosen[1],chosen[2]
                love.graphics.setColor(1,1,1)
                love.graphics.rectangle("line",xbegin+dx*x,ybegin+dx*y,dx,dx)
                -- print text
                if chosenOption.upgrade then
                    local upgrade=self.currentUI.upgrades[chosenOption.upgrade]
                    SetFont(24)
                    love.graphics.printf(upgrade.name,100,450,380,"left",0,1,1)
                    SetFont(18)
                    love.graphics.printf(upgrade.description,110,485,380,"left",0,1,1)
                    love.graphics.printf('Cost: '..upgrade.cost..' XP',110,540,380,"left",0,1,1)
                    love.graphics.rectangle("line",100,480,600,85)
                end


                SetFont(48)
                love.graphics.print("Upgrades", 100, 60)
                SetFont(36)
                love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
                
                -- show "X: return"
                SetFont(18)
                love.graphics.printf("X: Return  Z: Buy / Refund  D: Refund All",100,570,380,"left",0,1,1)
                love.graphics.printf("Current XP: "..self.currentUI.calculateRestXP(self),500,570,380,"left",0,1,1)

                love.graphics.setColor(color[1],color[2],color[3],color[4] or 1)
            end
        },
        CHOOSE_LEVELS={
            chosenLevel=1,
            chosenScene=1,
            update=function(self,dt)
                local level=self.currentUI.chosenLevel
                local scene=self.currentUI.chosenScene
                local levelNum=#levelData
                local sceneNum=#levelData[level]
                local passedSceneCount=self:countPassedSceneNum()
                for i=1,levelNum do
                    if passedSceneCount<levelData.needPass[i] then
                        levelNum=i
                        break
                    end
                end
                if isPressed('down') then
                    self.currentUI.chosenScene=self.currentUI.chosenScene%sceneNum+1
                    SFX:play('select')
                elseif isPressed('up') then
                    self.currentUI.chosenScene=(self.currentUI.chosenScene-2)%sceneNum+1
                    SFX:play('select')
                elseif isPressed('right') then
                    self.currentUI.chosenLevel=self.currentUI.chosenLevel%levelNum+1
                    self.currentUI.chosenScene=math.min(self.currentUI.chosenScene,#levelData[self.currentUI.chosenLevel])
                    SFX:play('select')
                elseif isPressed('left') then
                    self.currentUI.chosenLevel=(self.currentUI.chosenLevel-2)%levelNum+1
                    self.currentUI.chosenScene=math.min(self.currentUI.chosenScene,#levelData[self.currentUI.chosenLevel])
                    SFX:play('select')
                elseif isPressed('z') then
                    SFX:play('select')
                    self:enterLevel(level,scene)
                elseif isPressed('c') then
                    SFX:play('select')
                    self.STATE=self.STATES.UPGRADES
                elseif isPressed('x') or isPressed('escape')then
                    SFX:play('select')
                    self.STATE=self.STATES.MAIN_MENU
                elseif isPressed('[') then
                    SFX:play('select')
                    self.save.levelData[level][scene].passed=math.max(self.save.levelData[level][scene].passed-1,0)
                elseif isPressed(']') then
                    SFX:play('select')
                    self.save.levelData[level][scene].passed=math.min(self.save.levelData[level][scene].passed+1,2)
                end
            end,
            draw=function(self)
            end,
            drawText=function(self)
                self.updateDynamicPatternData(self.patternData)
                local level=self.currentUI.chosenLevel
                local scene=self.currentUI.chosenScene

                -- print Level x and Scene x
                SetFont(36)
                love.graphics.print("Level "..level,100,50,0,1,1)
                SetFont(36)
                for index, value in ipairs(levelData[level]) do
                    local color={love.graphics.getColor()}
                    love.graphics.setColor(.7,.6,.6)
                    if self.save.levelData[level][index].passed==1 then
                        love.graphics.setColor(.7,1,.7)
                    elseif self.save.levelData[level][index].passed==2 then
                        love.graphics.setColor(1,1,0.5)
                    end
                    love.graphics.print("Scene "..index,100,100+index*50,0,1,1)
                    love.graphics.setColor(color[1],color[2],color[3])
                end
                -- draw rectangle to mark current selected scene 
                love.graphics.rectangle("line",100,100+scene*50,200,50)


                -- show screenshot
                if ScreenshotManager.data[level][scene].batch then
                    local x0,y0=325,25
                    local ratio=0.75
                    local width,height=500,600
                    local data=ScreenshotManager.data[level][scene]
                    data.batch:clear()
                    data.batch:add(data.quad,x0,y0,0,ratio,ratio,0,0)
                    data.batch:flush()
                    love.graphics.draw(data.batch)
                    love.graphics.rectangle("line",x0,y0,width*ratio,height*ratio)
                end

                -- show quote
                love.graphics.rectangle("line",325,500,400,80)
                local text=levelData.defaultQuote
                local save=self.save.levelData[level][scene]
                if save.passed>=1 then
                    text=levelData[level][scene].quote or ''
                end
                SetFont(18)
                love.graphics.printf(text,330,510,380,"left",0,1,1)

                -- show try count / first pass / first perfect data
                SetFont(14)
                love.graphics.printf(save.tryCount..' tries',710,325,90,'left')
                love.graphics.printf('First pass:\n'..save.firstPass..' tries',710,350,90,'left')
                love.graphics.printf('First perfect:\n'..save.firstPerfect..' tries',710,390,90,'left')

                -- show number of passed levels needed for next level
                local passedSceneCount,allSceneCount=self:countPassedSceneNum()
                local needSceneCount=levelData.needPass[level]
                SetFont(14)
                love.graphics.printf('Passed Scenes: '..passedSceneCount..'/'..allSceneCount,710,5,90,'left')
                love.graphics.printf(''..needSceneCount..' scenes to unlock next level',710,50,90,'left')

                -- show "C: upgrades menu"
                SetFont(18)
                love.graphics.printf("C: Upgrades Menu",100,570,380,"left",0,1,1)
            end
        },
        IN_LEVEL={
            update=function(self,dt)
                Asset:clearBatches()
                Asset.backgroundBatch:add(Asset.backgroundLeft,0,0,0,1,1,0,0)
                Asset.backgroundBatch:add(Asset.backgroundRight,650,0,0,1,1,0,0)
                Object:updateAll(dt)
                Asset:flushBatches()
                if isPressed('escape') then
                    SFX:play('select')
                    -- self:removeAll()
                    self.STATE=self.STATES.PAUSE
                elseif isPressed('r')then
                    if self.replay then -- if in "replay" replay "replay" (why so strange)
                        self:leaveLevel()
                        ReplayManager.runReplay(self.UIDEF.LOAD_REPLAY.slot)
                    else
                        self:leaveLevel()
                        self:enterLevel(self.UIDEF.CHOOSE_LEVELS.chosenLevel,self.UIDEF.CHOOSE_LEVELS.chosenScene)
                    end
                end
                -- rest time calculation
                self.levelRemainingFrame=self.levelRemainingFrame-1
                if self.levelRemainingFrame<=600 and self.levelRemainingFrame%60==0 then
                    SFX:play('timeout')
                end
                if self.levelRemainingFrame==0 then
                    self:lose()
                end
            end,
            draw=function(self)
                Asset:drawBatches()
                Object:drawAll()
            end,
            drawText=function(self)
                SetFont(18)
                love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
                love.graphics.print("Circle: "..#Circle.objects, 10, 50)
                love.graphics.print("Laser: "..#Laser.LaserUnit.objects, 10, 80)
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
                    love.graphics.print("REPLAYING... "..speedText, 150, 580)
                end
                SetFont(48)
                love.graphics.print(string.format('%03d',math.floor(self.levelRemainingFrame/60))..'.', 180, 10)
                SetFont(18)
                love.graphics.print(string.format('%02d',math.floor(self.levelRemainingFrame%60*100/60)), 252, 36)
                
            end
        },
        PAUSE={
            options={
                {text='Resume',value='RESUME'},
                {text='Exit',value='EXIT'},
            },
            chosen=1,
            update=function(self,dt)
                optionsCalc(self,{
                    EXIT=function(self)
                        self:removeAll()
                        self.STATE=self.replay and self.STATES.LOAD_REPLAY or self.STATES.CHOOSE_LEVELS
                        self:leaveLevel()
                    end,
                    RESUME=function(self)self.STATE=self.STATES.IN_LEVEL end
                })
                if isPressed('escape') then
                    SFX:play('select')
                    self.STATE=self.STATES.IN_LEVEL
                end
            end,
            draw=function(self)
                Asset:drawBatches()
                Object:drawAll()
            end,
            drawText=function(self)
                local color={love.graphics.getColor()}
                love.graphics.setColor(1,1,1,0.5)
                love.graphics.rectangle("fill",0,0,9999,9999) -- half transparent effect
                love.graphics.setColor(0,0,0,0.5)
                love.graphics.rectangle("fill",0,0,9999,9999)
                love.graphics.setColor(color[1],color[2],color[3])
                SetFont(48)
                love.graphics.print("Paused",100,50,0,1,1)
                SetFont(36)
                for index, value in ipairs(self.currentUI.options) do
                    local name=value.text
                    love.graphics.print(name,100,200+index*100,0,1,1)
                end
                love.graphics.rectangle("line",100,200+self.currentUI.chosen*100,200,50)
            end
        },
        GAME_END={
            options={
                {text='Restart',value='RESTART'},
                {text='Save Replay',value='SAVE_REPLAY'},
                {text='Exit',value='EXIT'},
            },
            chosen=1,
            update=function(self,dt)
                optionsCalc(self,{
                    EXIT=function(self)
                        self:removeAll()
                        self.STATE=self.STATES.CHOOSE_LEVELS
                    end,
                    SAVE_REPLAY=function(self)
                        self:switchState(self.STATES.SAVE_REPLAY)
                    end,
                    RESTART=function(self)
                        self:enterLevel(self.UIDEF.CHOOSE_LEVELS.chosenLevel,self.UIDEF.CHOOSE_LEVELS.chosenScene)
                    end
                })
            end,
            draw=function(self)
                Asset:drawBatches()
                Object:drawAll()
            end,
            drawText=function(self)
                local color={love.graphics.getColor()}
                love.graphics.setColor(1,1,1,0.5)
                love.graphics.rectangle("fill",0,0,9999,9999) -- half transparent effect
                love.graphics.setColor(0,0,0,0.5)
                love.graphics.rectangle("fill",0,0,9999,9999)
                love.graphics.setColor(color[1],color[2],color[3])
                SetFont(48)
                love.graphics.print(self.won_current_scene and "WIN" or "LOSE",100,50,0,1,1)
                SetFont(36)
                for index, value in ipairs(self.currentUI.options) do
                    local name=value.text
                    love.graphics.print(name,100,200+index*50,0,1,1)
                end
                love.graphics.rectangle("line",100,200+self.currentUI.chosen*50,200,50)
            end
        },
        SAVE_REPLAY={
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
                keyBindValueCalc(self,'down','up','chosen',self.currentUI.chosenMax)
                keyBindValueCalc(self,'right','left','page',self.currentUI.pageMax)
                if isPressed('z') then
                    local slot=self.currentUI.chosen+self.currentUI.page*25-25
                    self.currentUI.slot=slot
                    -- ReplayManager.saveReplay(slot,'test')
                    self:switchState(self.STATES.SAVE_REPLAY_ENTER_NAME)
                    SFX:play('select')
                elseif isPressed('x') or isPressed('escape')then
                    SFX:play('select')
                    self.STATE=self.STATES.GAME_END
                end
            end,
            draw=function(self)
                Asset:drawBatches()
                Object:drawAll()
            end,
            drawText=function(self)
                local color={love.graphics.getColor()}
                love.graphics.setColor(1,1,1,0.5)
                love.graphics.rectangle("fill",0,0,9999,9999) -- half transparent effect
                love.graphics.setColor(0,0,0,0.5)
                love.graphics.rectangle("fill",0,0,9999,9999)
                love.graphics.setColor(color[1],color[2],color[3])

                local chosen,page=self.currentUI.chosen,self.currentUI.page
                SetFont(16)
                for i=page*25+1-25,page*25 do
                    local replayDesc=ReplayManager.getDescriptionString(i)
                    ReplayManager.monospacePrint(replayDesc,10,145,50+(i-1)%25*20)
                end
                love.graphics.rectangle("line",140,30+self.currentUI.chosen*20,520,20)
            end
        },
        SAVE_REPLAY_ENTER_NAME={
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
                keyBindValueCalc(self,'down','up','row',#self.currentUI.keyboard)
                keyBindValueCalc(self,'right','left','column',#self.currentUI.keyboard[1])
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
            draw=function(self)
                Asset:drawBatches()
                Object:drawAll()
            end,
            drawText=function(self)
                local color={love.graphics.getColor()}
                love.graphics.setColor(1,1,1,0.5)
                love.graphics.rectangle("fill",0,0,9999,9999) -- half transparent effect
                love.graphics.setColor(0,0,0,0.5)
                love.graphics.rectangle("fill",0,0,9999,9999)
                love.graphics.setColor(color[1],color[2],color[3])

                SetFont(16)
                local replayDesc=ReplayManager.getDescriptionString(self.currentUI.slot,ReplayManager.getReplayData(self.currentUI.slot,self.currentUI.name))
                ReplayManager.monospacePrint(replayDesc,10,145,50)

                SetFont(24)
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
        },
        LOAD_REPLAY={
            chosen=1,
            page=1,
            chosenMax=25,
            pageMax=4,
            enter=function(self)
                ReplayManager.loadAll()
                self.currentUI.chosenMax=ReplayManager.REPLAY_NUM_PER_PAGE
                self.currentUI.pageMax=ReplayManager.PAGES
            end,
            update=function(self,dt)
                keyBindValueCalc(self,'down','up','chosen',self.currentUI.chosenMax)
                keyBindValueCalc(self,'right','left','page',self.currentUI.pageMax)
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
                    self.STATE=self.STATES.MAIN_MENU
                end
            end,
            draw=function(self)
            end,
            drawText=function(self)
                self.updateDynamicPatternData(self.patternData)
                local color={love.graphics.getColor()}
                love.graphics.setColor(1,1,1)

                local chosen,page=self.currentUI.chosen,self.currentUI.page
                SetFont(17)
                for i=page*25+1-25,page*25 do
                    local replayDesc=ReplayManager.getDescriptionString(i)
                    ReplayManager.monospacePrint(replayDesc,10,145,50+(i-1)%25*20)
                end
                love.graphics.rectangle("line",140,30+self.currentUI.chosen*20,520,20)

                love.graphics.setColor(color[1],color[2],color[3])
            end
        },
    }
}

G.STATE=G.STATES.MAIN_MENU
G.frame=0
G.sceneTempObjs={}
G.VIEW_MODES={NORMAL='NORMAL',FOLLOW='FOLLOW'}
G.viewMode={
    mode=G.VIEW_MODES.NORMAL,
    object=...,
}

local lume = require "lume"
G.saveData=function(self)
    local data = {}
    data=self.save or {}
	local serialized = lume.serialize(data)
  	love.filesystem.write("savedata.txt", serialized)
end
-- an example of its structure
G.save={
    levelData={{{passed=0,tryCount=0,firstPass=0,firstPerfect=0}}},
    options={},
    upgrades={{{bought=true}}},
    defaultName='',
}
G.loadData=function(self)
	local file = love.filesystem.read("savedata.txt")
    self.save={}
    if file then
        local data = lume.deserialize(file)
        self.save=data or {}
    end
    if not self.save.levelData then
        self.save.levelData={}
    end
    -- add data for each level (passed, tryCount, firstPass, firstPerfect)
    for k,value in ipairs(levelData) do
        if not self.save.levelData[k] then
            self.save.levelData[k]={}
        end
        for i=1,#value do
            if not self.save.levelData[k][i] then
                self.save.levelData[k][i]={passed=0,tryCount=0,firstPass=0,firstPerfect=0}
            elseif type(self.save.levelData[k][i])=='number'then --compatible with old save
                self.save.levelData[k][i]={passed=self.save.levelData[k][i],tryCount=0,firstPass=0,firstPerfect=0}
            end
        end
    end
    -- add options data
    if not self.save.options then
        self.save.options={
            master_volume=100,
            music_volume=100,
            sfx_volume=100
        }
    end
    SFX:setVolume(self.save.options.master_volume*self.save.options.sfx_volume/10000)
    BGM:setVolume(self.save.options.master_volume*self.save.options.music_volume/10000)

    -- add upgrades data
    if not self.save.upgrades then
        self.save.upgrades={}
    end
    local options=self.UIDEF.UPGRADES.options
    local sizeX,sizeY=#options[1],#options
    for x=1,sizeX do
        if not self.save.upgrades[x] then
            self.save.upgrades[x]={}
        end
        for y=1,sizeY do
            if not self.save.upgrades[x][y] then
                self.save.upgrades[x][y]={bought=false}
            end
        end
    end

    -- add default name for saving replay
    if not self.save.defaultName then
        self.save.defaultName=''
    end

    self:saveData()
end
G:loadData()

---@param self table
---@return integer "number of passed scenes"
---@return integer "number of all scenes"
G.countPassedSceneNum=function(self)
    local allSceneCount,passedSceneCount=0,0
    for i,value in ipairs(levelData)do
        for j,level in ipairs(value)do
            allSceneCount=allSceneCount+1
            if self.save.levelData[i][j].passed>0 then
                passedSceneCount=passedSceneCount+1
            end
        end
    end
    return passedSceneCount,allSceneCount
end
G.win=function(self)
    self.STATE=self.STATES.GAME_END
    self:leaveLevel()
    self.won_current_scene=true
    local winLevel=1
    if Player.objects[1].hurt==false then
        winLevel=2
    end
    local level=self.UIDEF.CHOOSE_LEVELS.chosenLevel
    local scene=self.UIDEF.CHOOSE_LEVELS.chosenScene
    self.save.levelData[level][scene].passed=math.max(self.save.levelData[level][scene].passed,winLevel)
    if self.save.levelData[level][scene].firstPass==0 then
        self.save.levelData[level][scene].firstPass=self.save.levelData[level][scene].tryCount
    end
    if self.save.levelData[level][scene].firstPerfect==0 and winLevel==2 then
        self.save.levelData[level][scene].firstPerfect=self.save.levelData[level][scene].tryCount
    end
    self:saveData()
end
G.lose=function(self)
    self.STATE=self.STATES.GAME_END
    self:leaveLevel()
    self.won_current_scene=false
end
G.enterLevel=function(self,level,scene)
    self:removeAll()
    self.STATE=self.STATES.IN_LEVEL
    self.currentLevel={level,scene}
    Shape.restore()
    self.levelRemainingFrame=nil
    self.levelRemainingFrameMax=nil
    levelData[level][scene].make()
    self.levelRemainingFrame=self.levelRemainingFrame or 3600
    self.levelRemainingFrameMax=self.levelRemainingFrame
end
G.leaveLevel=function(self)
    if self.replay then
        self.replay=nil
        self.STATE=self.STATES.LOAD_REPLAY
        self.save.upgrades=self.upgradesRef
        return
    end
    self:_incrementTryCount()
    local level=self.UIDEF.CHOOSE_LEVELS.chosenLevel
    local scene=self.UIDEF.CHOOSE_LEVELS.chosenScene
    if levelData[level][scene].leave then
        levelData[level][scene].leave()
    end
end
G._incrementTryCount=function(self)
    local level=self.UIDEF.CHOOSE_LEVELS.chosenLevel
    local scene=self.UIDEF.CHOOSE_LEVELS.chosenScene
    self.save.levelData[level][scene].tryCount=self.save.levelData[level][scene].tryCount+1
    self:saveData()
end
G.update=function(self,dt)
    self.frame=self.frame+1
    self.currentUI=self.UIDEF[self.STATE]
    if G.replay then
        if love.keyboard.isDown('lalt') then
            self.currentUI.update(self,dt)
            self.currentUI.update(self,dt)
        end
        if love.keyboard.isDown('lctrl') then
            self.currentUI.update(self,dt)
        end
        if not love.keyboard.isDown('lshift') or self.frame%2==0 then
            self.currentUI.update(self,dt)
        end
    else
        self.currentUI.update(self,dt)
    end
end
-- sideNum=5 angleNum=4 -> r=107
-- sideNum=4 angleNum=5 -> r=126.2
-- sideNum=3 angleNum=7 -> r=110
-- point: where pattern begins. angle: direction of first line. sideNum: useless now as I dunno how to calculate side length. angleNum: how many sides are connected to each point. iteCount: used for recursion. plz input 0. r: side length. drawedPoints: plz input {}. color: {r,g,b}
local function bgpattern(point,angle,sideNum,angleNum,iteCount,r,drawedPoints,color)
    color=color or {0.7,0.2,0.5}
    local iteCount=(iteCount or 0)+1
    local points={}
    local r=r or 107--math.acosh(math.cos(math.pi/sideNum)/math.sin(math.pi/angleNum))*Shape.curvature
    drawedPoints=drawedPoints or {}
    local cic={Shape.getCircle(point.x,point.y,r)}
    -- love.graphics.print(''..cic[1]..', '..cic[2]..' '..cic[3],10,10)
    local begin=iteCount>1 and 2 or 1
    for i=begin,angleNum do
        local alpha=angle+math.pi*2/angleNum*(i-1)
        local ret={Shape.rThetaPos(point.x,point.y,r,alpha)}
        local newpoint={x=ret[1],y=ret[2]}
        points[#points+1]=newpoint
        -- SetFont(18)
        local flag=true
        local ratio=4.5
        for k,v in pairs(drawedPoints) do
            if ((point.x-v[1].x)^2+(point.y-v[1].y)^2+(newpoint.x-v[2].x)^2+(newpoint.y-v[2].y)^2)<ratio*point.y or ((point.x-v[2].x)^2+(point.y-v[2].y)^2+(newpoint.x-v[1].x)^2+(newpoint.y-v[1].y)^2)<ratio*point.y then
                flag=false
                break
            end
        end
        if flag then
            table.insert(drawedPoints,{point,newpoint})
            local colorref={love.graphics.getColor()}
            love.graphics.setColor(color[1],color[2],color[3])
            PolyLine.drawOne(point,newpoint)
            love.graphics.setColor(colorref[1],colorref[2],colorref[3])
        end
        -- Shape.drawLine(point.x,point.y,newpoint.x,newpoint.y)
        -- love.graphics.print(''..newpoint.x..', '..newpoint.y..' '..alpha..' '..ret[3],10,10+50*i)
    end
    if iteCount==4 then return {},{} end
    local angles={}
    for i=1,#points do
        local newpoint=points[i]
        local newangle=Shape.to(newpoint.x,newpoint.y,point.x,point.y)
        table.insert(angles,newangle)
        bgpattern(newpoint,newangle,sideNum,angleNum,iteCount,r,drawedPoints,color)
    end
    return points,angles
end
G.patternData={point={x=400,y=150},limit={xmin=300,xmax=500,ymin=150,ymax=600},angle=math.pi/3,speed=0.0045}
G.updateDynamicPatternData=function(data)
    local ay=Shape.axisY
    Shape.axisY=-30
    bgpattern({x=data.point.x+1,y=data.point.y+1},data.angle,5,5,0,126.2,{},{0.35,0.15,0.8})
    local newpoint,newAngle=bgpattern(data.point,data.angle,5,5,0,126.2,{},{0.7,0.2,0.5})
    if not math.inRange(data.point.x,data.point.y,data.limit.xmin,data.limit.xmax,data.limit.ymin,data.limit.ymax)  then
        for i=1,#newpoint do
            if math.inRange(newpoint[i].x,newpoint[i].y,data.limit.xmin,data.limit.xmax,data.limit.ymin,data.limit.ymax) then
                data.point=newpoint[i]
                data.angle=newAngle[i]
            end
        end
    end
    data.point={x=data.point.x-(data.point.x-400)*data.speed,y=data.point.y-(data.point.y-Shape.axisY)*data.speed}
    data.angle=data.angle+0.004
    -- love.graphics.print(''..data.point.x..', '..data.point.y,10,10+50)
    Shape.axisY=ay
end
G.patternPoint={x=400,y=100}
G.patternAngle=math.pi/3
G.draw=function(self)
    self.currentUI=self.UIDEF[self.STATE]
    if G.viewMode.mode==G.VIEW_MODES.NORMAL then
        self.currentUI.draw(self)
        self.currentUI.drawText(self)
    elseif G.viewMode.mode==G.VIEW_MODES.FOLLOW and G.viewMode.object then
        love.graphics.push()
        local scale=(love.graphics.getHeight()/2-Shape.axisY)/(G.viewMode.object.y-Shape.axisY)
        local screenWidth, screenHeight = love.graphics.getDimensions()
        love.graphics.translate((screenWidth / 2-G.viewMode.object.x*scale),(screenHeight / 2-G.viewMode.object.y*scale))
        love.graphics.scale(scale)
        -- love.graphics.translate(-G.viewMode.object.x,100)
        -- love.graphics.translate(screenWidth / 2, screenHeight / 2)
        -- love.graphics.translate(G.viewMode.object.x,G.viewMode.object.y)
        self.currentUI.draw(self)
        love.graphics.pop()
        self.currentUI.drawText(self)
    end
end
G.removeAll=function(self)
    Asset:clearBatches()
    Object:removeAll()
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