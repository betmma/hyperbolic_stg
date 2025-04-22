BulletSpawner=require"bulletSpawner"
BackgroundPattern=require"backgroundPattern"
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
    CONSTANTS={
        DRAW=function(self)
            Object:drawShaderAll()
            Asset:clearBatches()
            local colorRef={love.graphics.getColor()}
            Asset.foregroundBatch:setColor(colorRef[1],colorRef[2],colorRef[3],self.foregroundTransparency)
            Asset.foregroundBatch:add(Asset.backgroundLeft,0,0,0,1,1,0,0)
            Asset.foregroundBatch:add(Asset.backgroundRight,650,0,0,1,1,0,0)
            Object:drawAll() -- including directly calling love.graphics functions like .circle and adding sprite into corresponding batch.
            Asset:flushBatches()
            Asset:drawBatches()
            love.graphics.setShader()
        end,
    },
}
G={
    backgroundPattern=BackgroundPattern.MainMenuTesselation(),
    switchState=function(self,state)
        if not self.UIDEF[state] then
            error("State "..state.." not defined")
        end
        if self.UIDEF[state].TRANSITION then
            error("Illegal to switch to a transition state directly")
        end

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
        UPGRADES='UPGRADES',
        CHOOSE_LEVELS='CHOOSE_LEVELS',
        IN_LEVEL='IN_LEVEL',
        PAUSE='PAUSE',
        GAME_END='GAME_END', -- either win or lose
        SAVE_REPLAY='SAVE_REPLAY',
        SAVE_REPLAY_ENTER_NAME='SAVE_REPLAY_ENTER_NAME',
        LOAD_REPLAY='LOAD_REPLAY',
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
            }
        },
        OPTIONS={
            MAIN_MENU={
                slideDirection='left'
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
    UIDEF={
        MAIN_MENU={
            options={
                {text='Start',value='START'},
                {text='Replay',value='REPLAY'},
                {text='Options',value='OPTIONS'},
                {text='Exit',value='EXIT'},
            },
            chosen=1,
            enter=function(self)
                self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
                BGM:play('title')
            end,
            update=function(self,dt)
                self.backgroundPattern:update(dt)
                optionsCalc(self,{EXIT=love.event.quit,START=function(self)self:switchState(self.STATES.CHOOSE_LEVELS) end,
                REPLAY=function(self)self:switchState(self.STATES.LOAD_REPLAY)end,
                OPTIONS=function(self)self:switchState(self.STATES.OPTIONS) end})
                Asset.titleBatch:clear()
                Asset.titleBatch:add(Asset.title,70,0,0,0.5,0.5,0,0)
            end,
            draw=function(self)
            end,
            drawText=function(self)
                Asset.titleBatch:flush()
                love.graphics.draw(Asset.titleBatch)
                -- -- self.updateDynamicPatternData(self.patternData)
                local color={love.graphics.getColor()}
                SetFont(36)
                love.graphics.setColor(1,1,1,0.6)
                love.graphics.printf("Hyperbolic STG",200,270,400,'center')
                SetFont(36)
                love.graphics.setColor(1,1,1,1)
                for index, value in ipairs(self.currentUI.options) do
                    local name=Localize{'ui',value.value}
                    love.graphics.print(name,300,300+index*50,0,1,1)
                end
                love.graphics.rectangle("line",300,300+self.currentUI.chosen*50,200,50)
                love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
                love.graphics.setColor(color[1],color[2],color[3],color[4] or 1)
            end
        },
        OPTIONS={
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
                {text='Exit',value='EXIT'},
            },
            chosen=1,
            update=function(self,dt)
                self.backgroundPattern:update(dt)
                optionsCalc(self,{EXIT=function(self)self:switchState(self.STATES.MAIN_MENU);self:saveData() end})
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
                    if value.value~='EXIT' then
                        local toPrint=self.save.options[value.value]
                        if value.value=='language' then
                            local languageIndex=0
                            local currentLanguage=self.save.options.language
                            for i=1,#self.currentUI.options[index].options do
                                if self.currentUI.options[index].options[i].value==currentLanguage then
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
        },
        UPGRADES={
            enter=function(self)
                self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
            end,
            upgrades={
                -- Warning: real texts are in localization.lua. Following texts are for coding reference only.
                increaseHP={
                    name='Increase HP',
                    description='Increase HP by 1',
                    cost=30,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.hp=player.hp+1
                        player.maxhp=player.maxhp+1
                    end,
                    spritePos={x=0,y=0}
                },
                regenerate={
                    name='Regenerate',
                    description='Increase HP by 0.024 per second',
                    cost=40,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.hpRegen=player.hpRegen+0.024
                    end,
                    spritePos={x=1,y=0}
                },
                unyielding={
                    name='Unyielding',
                    description='Shockwave when you are hit is bigger',
                    cost=30,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.dieShockwaveRadius=player.dieShockwaveRadius+1
                    end,
                    spritePos={x=2,y=0}
                },
                acrobat={ -- add a scene that costs HP when grazing, and unlock this upgrade for it
                    name='Acrobat',
                    description='Each graze gives 0.005 HP',
                    cost=40,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.grazeHpRegen=player.grazeHpRegen+0.005
                    end,
                    spritePos={x=3,y=0}
                },
                flashbomb={
                    name='Flash Bomb',
                    description='Release a flash bomb for every 100 grazes',
                    cost=50,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.enableFlashbomb=true
                        player.grazeCountForFlashbomb=100
                        player.flashbombWidth=5
                    end,
                    spritePos={x=4,y=0}
                },
                amulet={
                    name='Amulet',
                    description='Player hitbox is 25% smaller',
                    cost=50,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.radius = player.radius*0.75
                    end,
                    spritePos={x=5,y=0}
                },
                homingShot={
                    name='Homing Shot',
                    description='2 rows of your shot become homing',
                    cost=50,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.shootRows.front.straight.num=player.shootRows.front.straight.num-2
                        player.shootRows.front.homing.num=player.shootRows.front.homing.num+2
                    end,
                    spritePos={x=6,y=0}
                },
                sideShot={
                    name='Side Shot',
                    description='Add 4 rows of side shot (on each side)',
                    cost=30,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.shootRows.side.straight.num=player.shootRows.side.straight.num+4
                    end,
                    spritePos={x=7,y=0}
                },
                backShot={
                    name='Back Shot',
                    description='Add 4 rows of back shot that do double damage',
                    cost=50,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.shootRows.back.straight.num=player.shootRows.back.straight.num+4
                    end,
                    spritePos={x=0,y=1}
                },
                familiarShot={
                    name='Familiar Shot',
                    description='Your shots can hit enemy\'s familiars and do 1/4 damage',
                    cost=40,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.canHitFamiliar=true
                        player.hitFamiliarDamageFactor=0.25
                    end,
                    spritePos={x=1,y=1}
                },
                vortex={
                    name='Vortex',
                    description='A vortex rounding you that can absorb bullets',
                    cost=60,
                    executeFunc=function()
                        local player=Player.objects[1]
                        Event.LoopEvent{
                            obj=player,
                            period=1,
                            executeFunc=function(self,executedTimes)
                                if player.cancelVortex then
                                    return
                                end
                                local x,y=player.x,player.y
                                local theta=0.02*executedTimes
                                local r=20
                                local nx,ny=Shape.rThetaPos(x,y,r,theta)
                                local vortex=Effect.Shockwave{x=nx,y=ny,radius=2,canRemove={bullet=true,invincible=false,safe=false},animationFrame=1}
                                vortex.scale=2
                                vortex.direction=theta*5
                                vortex.sprite=Asset.misc.vortex
                            end
                        }
                    end,
                    spritePos={x=2,y=1}
                },
                fixedHPDisplay={
                    name='Fixed HP Display',
                    description='Show enemy HP at the top of the screen. (Wow, this is an upgrade?)', -- useful when enemy is off screen, specifically in 6-5 phase 3 where enemy is always at opposite direction of player, and player's projectiles go awry, with this upgrade it's easier to know if the shot is hitting the enemy. (Though I've raised the hitting sfx volume at that phase, adding a visual cue is still better)
                    cost=10,
                    executeFunc=function()
                        local enemy=G.mainEnemy
                        if enemy then
                            enemy.showUpperHPBar=true
                        end
                    end,
                    spritePos={x=3,y=1}
                },
                clairvoyance={
                    name='Clairvoyance',
                    description='Widen your vision, somewhat',
                    cost=40,
                    executeFunc=function()
                        G.foregroundTransparency=0.8
                    end,
                    spritePos={x=4,y=1}
                },
                diagonalMover={
                    name='Diagonal Mover',
                    description='You move faster when moving diagonally',
                    cost=30,
                    executeFunc=function()
                        local player=Player.objects[1]
                        player.diagonalSpeedAddition=true
                    end,
                    spritePos={x=5,y=1}
                }
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
                        connect={left=true,right=true},
                        need={{2,1}}
                    },
                    {
                        upgrade='flashbomb',
                        connect={left=true,right=true},
                        need={{3,1}}
                    },
                    {
                        upgrade='vortex',
                        connect={left=true},
                        need={{4,1}}
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
                    {},
                    {}
                },
                {
                    {
                        upgrade='homingShot',
                        connect={up=true,right=true,down=true},
                        need={}
                    },
                    {
                        connect={left=true,right=true,down=true},
                        need={{1,3}}
                    },
                    {
                        upgrade='sideShot',
                        connect={left=true,right=true},
                        need={{1,3}}
                    },
                    {
                        upgrade='familiarShot',
                        connect={left=true,down=true},
                        need={{3,3},{3,4}}
                    },
                    {}
                },
                {
                    {
                        connect={up=true,down=true},
                        need={}
                    },
                    {
                        connect={up=true,right=true},
                        need={{1,3}}
                    },
                    {
                        upgrade='backShot',
                        connect={left=true,right=true},
                        need={{1,3}}
                    },
                    {
                        connect={up=true,left=true},
                        need={{3,4}}
                    },
                    {}
                },
                {
                    {
                        upgrade='amulet',
                        connect={up=true,right=true},
                        need={}
                    },
                    {
                        upgrade='fixedHPDisplay',
                        connect={left=true,right=true,down=true},
                        need={{1,5}}
                    },
                    {
                        upgrade='clairvoyance',
                        connect={left=true},
                        need={{2,5}}
                    },
                    {},
                    {}
                },
                {
                    {},
                    {
                        upgrade='diagonalMover',
                        connect={up=true},
                        need={{2,5}}
                    },
                    {},
                    {},
                    {}
                }
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
                self.backgroundPattern:update(dt)
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
                if isPressed('x') or isPressed('escape') or isPressed('c')then
                    SFX:play('select')
                    self:switchState(self.STATES.CHOOSE_LEVELS)
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
                -- -- self.updateDynamicPatternData(self.patternData)

                --draw upgrades
                local options=self.currentUI.options
                local xbegin,ybegin=50,80
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
                            
                            local upgrade=option.upgrade
                            local spritePos=self.currentUI.upgrades[upgrade].spritePos
                            love.graphics.draw(Asset.upgradeIconsImage, Asset.upgradeIcons[spritePos.x][spritePos.y], gap+xbegin+dx*x,gap+ybegin+dx*y,0,1,1)
                        end
                        ::continue::
                    end
                end
                -- draw chosen (a bigger square around the chosen upgrade)
                local chosen=self.currentUI.chosen
                local chosenOption=options[chosen[2]][chosen[1]]
                local x,y=chosen[1],chosen[2]
                love.graphics.setColor(1,1,1)
                love.graphics.rectangle("line",xbegin+dx*x,ybegin+dx*y,dx,dx)
                -- print text
                if chosenOption.upgrade then
                    local upgrade=self.currentUI.upgrades[chosenOption.upgrade]
                    SetFont(24)
                    local name=Localize{'upgrades',chosenOption.upgrade,'name'}
                    love.graphics.printf(name,100,450,380,"left",0,1,1)
                    SetFont(18)
                    local description=Localize{'upgrades',chosenOption.upgrade,'description'}
                    love.graphics.printf(description,110,485,580,"left",0,1,1)
                    love.graphics.printf(Localize{'ui','upgradesCostXP',xp=upgrade.cost},110,540,380,"left",0,1,1)
                    love.graphics.rectangle("line",100,480,600,85)
                end


                SetFont(48)
                love.graphics.print(Localize{'ui','upgrades'}, 100, 60)
                -- SetFont(36)
                -- love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
                
                -- show "X: return"
                SetFont(18)
                love.graphics.printf(Localize{'ui','upgradesUIHint'},100,570,380,"left",0,1,1)
                love.graphics.printf(Localize{'ui','upgradesCurrentXP',xp=self.currentUI.calculateRestXP(self)},500,570,380,"left",0,1,1)

                love.graphics.setColor(color[1],color[2],color[3],color[4] or 1)
            end,
        },
        CHOOSE_LEVELS={
            enter=function(self,lastState)
                G.viewMode.mode=G.VIEW_MODES.NORMAL
                self.currentUI.enterFrame=self.frame
                self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
                BGM:play('title')
            end,
            chosenLevel=1,
            chosenScene=1,
            update=function(self,dt)
                self.backgroundPattern:update(dt)
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
                    G.UIDEF.CHOOSE_LEVELS.transparency=0
                elseif isPressed('up') then
                    self.currentUI.chosenScene=(self.currentUI.chosenScene-2)%sceneNum+1
                    SFX:play('select')
                    G.UIDEF.CHOOSE_LEVELS.transparency=0
                elseif isPressed('right') then
                    self.currentUI.chosenLevel=self.currentUI.chosenLevel%levelNum+1
                    self.currentUI.chosenScene=math.min(self.currentUI.chosenScene,#levelData[self.currentUI.chosenLevel])
                    SFX:play('select')
                    G.UIDEF.CHOOSE_LEVELS.transparency=0
                elseif isPressed('left') then
                    self.currentUI.chosenLevel=(self.currentUI.chosenLevel-2)%levelNum+1
                    self.currentUI.chosenScene=math.min(self.currentUI.chosenScene,#levelData[self.currentUI.chosenLevel])
                    SFX:play('select')
                    G.UIDEF.CHOOSE_LEVELS.transparency=0
                elseif isPressed('z') then
                    SFX:play('select')
                    self:enterLevel(level,scene)
                elseif isPressed('c') then
                    SFX:play('select')
                    self:switchState(self.STATES.UPGRADES)
                elseif isPressed('x') or isPressed('escape')then
                    SFX:play('select')
                    self:switchState(self.STATES.MAIN_MENU)
                elseif isPressed('[') then
                    SFX:play('select')
                    self.save.levelData[level][scene].passed=math.max(self.save.levelData[level][scene].passed-1,0)
                elseif isPressed(']') then
                    SFX:play('select')
                    self.save.levelData[level][scene].passed=math.min(self.save.levelData[level][scene].passed+1,2)
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

                local color={love.graphics.getColor()}

                local deltaFrame=self.frame-self.currentUI.enterFrame
                local leftOffset,rightOffset=300,300
                local ratio=0.8^deltaFrame
                leftOffset,rightOffset=leftOffset*ratio,rightOffset*ratio
                love.graphics.translate(-leftOffset,0) -- left part begins
                -- print Level x and Scene x (left part)
                SetFont(36)
                love.graphics.print(Localize{'ui','level',level=level},100,50,0,1,1)
                SetFont(30)
                for index, value in ipairs(levelData[level]) do
                    love.graphics.setColor(.7,.6,.6)
                    if self.save.levelData[level][index].passed==1 then
                        love.graphics.setColor(.7,1,.7)
                    elseif self.save.levelData[level][index].passed==2 then
                        love.graphics.setColor(1,1,0.5)
                    end
                    love.graphics.print(level.."-"..index,100,100+index*40,0,1,1)
                end
                -- draw rectangle to mark current selected scene (left part)
                love.graphics.setColor(1,1,1)
                love.graphics.rectangle("line",100,100+scene*40,200,40)

                love.graphics.translate(leftOffset+rightOffset,0) -- right part begins
                -- add smooth transition when switching scenes or levels (setting the transparency of screenshot and qupte)
                local transparency=G.UIDEF.CHOOSE_LEVELS.transparency or 1
                love.graphics.setColor(color[1],color[2],color[3],transparency)

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
                local text=Localize{'levelData','defaultQuote'}--levelData.defaultQuote
                local save=self.save.levelData[level][scene]
                if save.passed>=1 then
                    text=Localize{'levelData',level,scene,'quote'}--levelData[level][scene].quote or ''
                end
                SetFont(18)
                love.graphics.printf(text,330,510,380,"left",0,1,1)

                -- show try count / first pass / first perfect data
                SetFont(14)
                love.graphics.printf(Localize{'ui','tryCount',tries=save.tryCount},710,325,90,'left')
                love.graphics.printf(Localize{'ui','firstPass',tries=save.firstPass},710,350,90,'left')
                love.graphics.printf(Localize{'ui','firstPerfect',tries=save.firstPerfect},710,390,90,'left')

                love.graphics.setColor(color[1],color[2],color[3],color[4]) -- below doesn't apply transparency

                -- show number of passed levels needed for next level
                local passedSceneCount,allSceneCount=self:countPassedSceneNum()
                local needSceneCount=levelData.needPass[level]
                SetFont(14)
                love.graphics.printf(Localize{'ui','passedScenes',passed=passedSceneCount,all=allSceneCount},710,5,90,'left')
                love.graphics.printf(Localize{'ui','needSceneToUnlockNextLevel',need=needSceneCount},710,50,90,'left')

                -- show play time
                local playTimeTable=self.save.playTimeTable
                love.graphics.printf(Localize{'ui','playTimeOverall',playtime=math.formatTime(playTimeTable.playTimeOverall)},710,100,90,'left')
                love.graphics.printf(Localize{'ui','playTimeInLevel',playtime=math.formatTime(playTimeTable.playTimeInLevel)},710,130,90,'left')

                love.graphics.translate(-rightOffset,0) -- right part ends

                -- show "C: upgrades menu"
                SetFont(18)
                love.graphics.printf(Localize{'ui','levelUIHint'},100,570,380,"left",0,1,1)
            end,
        },
        IN_LEVEL={
            enter=function(self,previousState)
                -- transition animation caused this function to be called frames LATER than G.enterLevel (precisely, TRANSITION_IMAGE calls enter at half point of the transition). so I move G.enterLevel code and call replayManager's tweak code here.
                if previousState==self.STATES.CHOOSE_LEVELS or previousState==self.STATES.LOAD_REPLAY then
                    self:replaceBackgroundPatternIfIs(BackgroundPattern.MainMenuTesselation,BackgroundPattern.FollowingTesselation)
                    BGM:play('level2')
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
                local level,scene=self.currentLevel[1],self.currentLevel[2]
                Shape.restore()
                Circle.restore()
                self.levelRemainingFrame=nil
                self.levelRemainingFrameMax=nil
                self.levelIsTimeoutSpellcard=false
                self.foregroundTransparency=1
                levelData[level][scene].make()
                self.levelRemainingFrame=self.levelRemainingFrame or 3600
                self.levelRemainingFrameMax=self.levelRemainingFrame
                if self.replay then
                    ReplayManager.replayTweak(self.replay)
                end
            end,
            update=function(self,dt)
                self.backgroundPattern:update(dt)
                Object:updateAll(dt)
                if isPressed('escape') then
                    SFX:play('select')
                    -- self:removeAll()
                    self:switchState(self.STATES.PAUSE)
                elseif (isPressed('r')or isPressed('w')) and (not Player.objects[1] or Player.objects[1].frame>10)then
                    if self.replay then -- if in "replay" replay "replay" (why so strange)
                        self:leaveLevel()
                        ReplayManager.runReplay(self.UIDEF.LOAD_REPLAY.slot)
                    else
                        self:leaveLevel()
                        self:enterLevel(self.UIDEF.CHOOSE_LEVELS.chosenLevel,self.UIDEF.CHOOSE_LEVELS.chosenScene)
                    end
                elseif isPressed('q')then
                    if self.viewMode.mode==self.VIEW_MODES.NORMAL and Player.objects[1] then
                        self.viewMode.mode=self.VIEW_MODES.FOLLOW
                        self.viewMode.object=Player.objects[1]
                    elseif self.viewMode.mode==self.VIEW_MODES.FOLLOW then
                        self.viewMode.mode=self.VIEW_MODES.NORMAL
                    end
                elseif isPressed('w')then
                    -- Player.objects[1].hp=999
                    -- Player.objects[1].maxhp=999
                    -- Player.objects[1].moveMode=Player.moveModes.Natural
                end

                -- rest time calculation
                self.levelRemainingFrame=self.levelRemainingFrame-1
                if self.levelRemainingFrame<=600 and self.levelRemainingFrame%60==0 then
                    SFX:play('timeout',true,2)
                end
                local level=G.UIDEF.CHOOSE_LEVELS.chosenLevel
                local scene=G.UIDEF.CHOOSE_LEVELS.chosenScene
                if self.levelIsTimeoutSpellcard and not G.replay and self.levelRemainingFrame==60 then -- for normal levels it's done by enemy:dieEffect
                    ScreenshotManager.preSave(level,scene)
                end
                if self.levelRemainingFrame==0 then
                    if self.levelIsTimeoutSpellcard then
                        if not G.replay then 
                            ScreenshotManager.save(level,scene)
                        end
                        self:win()
                    else
                        self:lose()
                    end
                end
            end,
            draw=G.CONSTANTS.DRAW,
            drawText=function(self)
                Object:drawTextAll()
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
                if not player or Shape.distance(170,10,player.x,player.y)>50 or G.viewMode.mode~=G.VIEW_MODES.NORMAL then
                    xt,yt=160,5
                else
                    xt,yt=560,5
                end
                love.graphics.print(string.format('%03d',math.floor(self.levelRemainingFrame/60))..'.', xt, yt)
                SetFont(18,Fonts.en_us)
                love.graphics.print(string.format('%02d',math.floor(self.levelRemainingFrame%60*100/60)), xt+dx, yt+dy)
                
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
                        self:switchState(self.replay and self.STATES.LOAD_REPLAY or self.STATES.CHOOSE_LEVELS)
                        self:leaveLevel()
                    end,
                    RESUME=function(self)self:switchState(self.STATES.IN_LEVEL) end
                })
                if isPressed('escape') then
                    SFX:play('select')
                    self:switchState(self.STATES.IN_LEVEL)
                end
            end,
            draw=G.CONSTANTS.DRAW,
            drawText=function(self)
                Object:drawTextAll()
                local color={love.graphics.getColor()}
                love.graphics.setColor(1,1,1,0.5)
                love.graphics.rectangle("fill",0,0,9999,9999) -- half transparent effect
                love.graphics.setColor(0,0,0,0.5)
                love.graphics.rectangle("fill",0,0,9999,9999)
                love.graphics.setColor(color[1],color[2],color[3])
                SetFont(48)
                love.graphics.print(Localize{'ui','paused'},100,50,0,1,1)
                SetFont(36)
                for index, value in ipairs(self.currentUI.options) do
                    local name=Localize{'ui',value.value}
                    love.graphics.print(name,100,200+index*100,0,1,1)
                end
                love.graphics.rectangle("line",100,200+self.currentUI.chosen*100,200,50)
            end
        },
        GAME_END={
            enter=function(self)
                self.currentUI.transparency=0
            end,
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
                        self:switchState(self.STATES.CHOOSE_LEVELS)
                    end,
                    SAVE_REPLAY=function(self)
                        self:switchState(self.STATES.SAVE_REPLAY)
                    end,
                    RESTART=function(self)
                        self:enterLevel(self.UIDEF.CHOOSE_LEVELS.chosenLevel,self.UIDEF.CHOOSE_LEVELS.chosenScene)
                    end
                })
                local transparency=self.currentUI.transparency or 1
                transparency=transparency*0.92+0.08
                self.currentUI.transparency=transparency
            end,
            draw=G.CONSTANTS.DRAW,
            drawText=function(self)
                local transparency=self.currentUI.transparency or 1
                Object:drawTextAll()
                local color={love.graphics.getColor()}
                love.graphics.setColor(1,1,1,0.5*transparency)
                love.graphics.rectangle("fill",0,0,9999,9999) -- half transparent effect
                love.graphics.setColor(0,0,0,0.5*transparency)
                love.graphics.rectangle("fill",0,0,9999,9999)
                love.graphics.setColor(1,1,1,transparency)
                SetFont(48)
                love.graphics.print(self.won_current_scene and Localize{'ui','win'} or Localize{'ui','lose'},100,50,0,1,1)
                SetFont(36)
                for index, value in ipairs(self.currentUI.options) do
                    local name=Localize{'ui',value.value}
                    love.graphics.print(name,100,200+index*50,0,1,1)
                end
                love.graphics.rectangle("line",100,200+self.currentUI.chosen*50,200,50)
                love.graphics.setColor(color[1],color[2],color[3],color[4])
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
                Object:drawTextAll()
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
            draw=G.CONSTANTS.DRAW,
            drawText=function(self)
                Object:drawTextAll()
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
        },
        LOAD_REPLAY={
            chosen=1,
            page=1,
            chosenMax=25,
            pageMax=4,
            enter=function(self)
                G.viewMode.mode=G.VIEW_MODES.NORMAL
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
                        else
                            slot=self.currentUI.firstDigit*10+index
                            self.currentUI.firstDigit=nil
                        end
                        if slot==0 then slot=100 end
                        self.currentUI.page=math.floor((slot+24)/25)
                        self.currentUI.chosen=(slot-1)%25+1
                    end
                end
            end,
            update=function(self,dt)
                self.backgroundPattern:update(dt)
                keyBindValueCalc(self,'down','up','chosen',self.currentUI.chosenMax)
                keyBindValueCalc(self,'right','left','page',self.currentUI.pageMax)
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

                love.graphics.setColor(color[1],color[2],color[3])
            end
        },
        TRANSITION_SLIDE={
            TRANSITION=true,
            enter=function(self,transitionArgs)
                transitionArgs.startFrame=self.frame
                self.currentUI.transitionArgs=transitionArgs
                self.currentUI.transitionFrame=0
                self.currentUI.complete=false
                    transitionArgs.aimDxy={DirectionName2Dxy(transitionArgs.slideDirection)}
                    transitionArgs.aimDxy={transitionArgs.aimDxy[1]*WINDOW_WIDTH,transitionArgs.aimDxy[2]*WINDOW_HEIGHT}
                    -- transitionArgs.length={WINDOW_WIDTH,WINDOW_HEIGHT}
                    transitionArgs.currentDxy={0,0}
                local currentUI=self.currentUI
                self.currentUI=self.UIDEF[transitionArgs.nextState]
                self.currentUI.enter(self,transitionArgs.lastState)
                self.currentUI=currentUI
            end,
            update=function(self,dt)
                local args=self.currentUI.transitionArgs
                self.currentUI.transitionFrame=self.currentUI.transitionFrame+1
                if self.currentUI.transitionFrame>=args.transitionFrame or self.currentUI.complete==true then
                    -- doesn't call switchState directly, because switchState will call nextState:enter, which has been called in TRANSITION:enter.
                    self.STATE=args.nextState
                    self.currentUI=self.UIDEF[self.STATE]
                    self.currentUI.complete=true
                    return
                end
                local ratio=args.slideRatio
                for i=1,2 do
                    args.currentDxy[i]=args.currentDxy[i]*(1-ratio)+args.aimDxy[i]*ratio
                end
                local currentUI=self.currentUI
                self.STATE=args.nextState
                self.currentUI=self.UIDEF[args.nextState]
                self.currentUI.update(self,dt)
                if self.STATE~=args.nextState then
                    --[[explain the condition: if the state is changed in the update function, there are 2 possibilities.
                    1. it's changed without a new transition (means it's abrupt), then stop current transition by setting complete to true.
                    2. it's changed with a new transition, then no need to stop current transition, because the new transition has overwritten the current one. If do so, the new transition will be stopped immediately and stuck.]]
                    return
                end
                self.currentUI=currentUI
                self.STATE=self.STATES.TRANSITION_SLIDE
            end,
            draw=function(self)
                local args=self.currentUI.transitionArgs
                    local currentUI=self.currentUI
                    local currentDxy=args.currentDxy
                    love.graphics.translate(currentDxy[1],currentDxy[2])
                    self.currentUI=self.UIDEF[args.lastState]
                    self.currentUI.draw(self)
                    love.graphics.translate(-args.aimDxy[1],-args.aimDxy[2])
                    self.currentUI=self.UIDEF[args.nextState]
                    self.currentUI.draw(self)
                    love.graphics.translate(args.aimDxy[1]-currentDxy[1],args.aimDxy[2]-currentDxy[2])
                    self.currentUI=currentUI
            end,
            drawText=function(self)
                local args=self.currentUI.transitionArgs
                    local currentUI=self.currentUI
                    local currentDxy=args.currentDxy
                    love.graphics.translate(currentDxy[1],currentDxy[2])
                    self.currentUI=self.UIDEF[args.lastState]
                    self.currentUI.drawText(self)
                    love.graphics.translate(-args.aimDxy[1],-args.aimDxy[2])
                    self.currentUI=self.UIDEF[args.nextState]
                    self.currentUI.drawText(self)
                    love.graphics.translate(args.aimDxy[1]-currentDxy[1],args.aimDxy[2]-currentDxy[2])
                    self.currentUI=currentUI
            end
        },
        TRANSITION_IMAGE={
            TRANSITION=true,
            enter=function(self,transitionArgs)
                transitionArgs.startFrame=self.frame
                transitionArgs.image=transitionArgs.image or Asset.backgroundImage
                transitionArgs.shader=transitionArgs.shader or love.graphics.newShader("shaders/transitionImage.glsl")
                transitionArgs.thershold=transitionArgs.thershold or 0.3
                self.currentUI.transitionArgs=transitionArgs
                self.currentUI.transitionFrame=0
                self.currentUI.complete=false
            end,
            update=function(self,dt)
                -- in this transition no need to consider interrupt because no state's update is called, so no new transition is possible.
                local args=self.currentUI.transitionArgs
                self.currentUI.transitionFrame=self.currentUI.transitionFrame+1
                if self.currentUI.transitionFrame*2>=args.transitionFrame and self.currentUI.transitionFrame*2-2<args.transitionFrame then -- half point, execute nextState:enter()
                    local currentUI=self.currentUI
                    self.currentUI=self.UIDEF[args.nextState]
                    self.currentUI.enter(self,args.lastState)
                    self.currentUI=currentUI
                end
                if self.currentUI.transitionFrame>=args.transitionFrame or self.currentUI.complete==true then 
                    self.STATE=args.nextState
                    self.currentUI=self.UIDEF[self.STATE]
                    self.currentUI.complete=true
                end
            end,
            draw=function(self)
                local args=self.currentUI.transitionArgs
                local ratio=self.currentUI.transitionFrame/args.transitionFrame

                local currentUI=self.currentUI
                if ratio<0.5 then
                    self.currentUI=self.UIDEF[args.lastState]
                    self.currentUI.draw(self)
                else
                    self.currentUI=self.UIDEF[args.nextState]
                    self.currentUI.draw(self)
                end
                self.currentUI=currentUI
            end,
            drawText=function(self)
                local args=self.currentUI.transitionArgs
                local progress=0.0001+self.currentUI.transitionFrame/args.transitionFrame

                local currentUI=self.currentUI
                if progress<0.5 then
                    self.currentUI=self.UIDEF[args.lastState]
                    self.currentUI.drawText(self)
                else
                    self.currentUI=self.UIDEF[args.nextState]
                    self.currentUI.drawText(self)
                end
                self.currentUI=currentUI

                --[[ ratio -> new ratio and meaning:
                0 -> 0 beginning of transition, image shouldn't be visible
                thershold -> 1 the point when image is fully visible
                0.5 -> 1 half way, execute nextState:enter()
                1 - thershold -> 1 image is still fully visible
                1 -> 0 end of transition, image shouldn't be visible

                so that, for shader ratio = 0 to 1 directly means invisible to visible
                ]]
                progress=-math.abs(progress-0.5)*2+1
                progress=math.min(progress*0.5/(args.thershold),1)

                local image=args.image
                local shader=args.shader
                shader:send("progress",progress)
                love.graphics.setShader(shader)
                love.graphics.draw(image,0,0,0,1,1)
                love.graphics.setShader()
            end
        }
    }
}

G:switchState(G.STATES.MAIN_MENU)
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
    options={master_volume=100,},
    upgrades={{{bought=true}}},
    defaultName='',-- the default name when saving replay
    playTimeTable={
        playTimeOverall=0,
        playTimeInLevel=0,
    },
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
    local defaultOptions={
        master_volume=100,
        music_volume=100,
        sfx_volume=100,
        language='en_us',
    }
    if not self.save.options then
        self.save.options=defaultOptions
    end
    for key,value in pairs(defaultOptions) do
        if not self.save.options[key] then
            self.save.options[key]=value
        end
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

    -- add play time data
    if not self.save.playTimeTable then
        self.save.playTimeTable={}
    end
    local defaultPlayTimeTable={
        -- unit is seconds
        playTimeOverall=0,
        playTimeInLevel=0,
    }
    for k,value in pairs(defaultPlayTimeTable) do
        if not self.save.playTimeTable[k] then
            self.save.playTimeTable[k]=value
        end
    end

    self:saveData()
end
G:loadData()

G.language=G.save.options.language--'zh_cn'--'en_us'--

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
    self:switchState(self.STATES.GAME_END)
    self:leaveLevel()
    self.won_current_scene=true -- it's only used to determine the displayed text in end screen to be "win" or "lose"
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
    self:switchState(self.STATES.GAME_END)
    self:leaveLevel()
    self.won_current_scene=false -- it's only used to determine the displayed text in end screen to be "win" or "lose"
    self:saveData()
end
G.enterLevel=function(self,level,scene)
    self.currentLevel={level,scene}
    self:switchState(self.STATES.IN_LEVEL)
end
-- It's called when leaving the level, either by winning, losing (these 2 are called from enemy or player object), pressing "R" to restart or exiting from pause menu.
G.leaveLevel=function(self)
    if self.replay then
        self.replay=nil
        self:switchState(self.STATES.LOAD_REPLAY)
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
G.draw=function(self)
    self.currentUI=self.UIDEF[self.STATE]
    if G.viewMode.mode==G.VIEW_MODES.NORMAL then
        self:_drawBatches()
        self.currentUI.drawText(self)
    elseif G.viewMode.mode==G.VIEW_MODES.FOLLOW then
        if not G.viewMode.object then
            G.viewMode.object=Player.objects[1]
        end
        if self.backgroundPattern.noZoom then
            self.backgroundPattern:draw()
        end
        love.graphics.push()
        self:followModeTransform()
        if G.viewMode.object.moveMode==Player.moveModes.Natural then
            G.viewMode.object:testRotate(-G.viewMode.object.naturalDirection) -- rotate all objects to make player face up. Note that due to love2d limitation, it *changes* objects' coordinates to achieve hyperbolic rotation.
        end
        self:_drawBatches()
        if G.viewMode.object.moveMode==Player.moveModes.Natural then
            G.viewMode.object:testRotate(0,true) -- "true" means restore objects' coordinates
        end
        love.graphics.pop()
        self.currentUI.drawText(self)
    end
end
G._drawBatches=function(self)
    if not self.backgroundPattern.noZoom or G.viewMode.mode==G.VIEW_MODES.NORMAL then
        self.backgroundPattern:draw()
    end
    self.currentUI.draw(self)
end
-- transform the coordinate system to make the player in the center of the screen. If [getParams] is true, return the translation and scaling parameters instead of applying them. (for shader use)
G.followModeTransform=function(self, getParams)
    local scale=(love.graphics.getHeight()/2-Shape.axisY)/(G.viewMode.object.y-Shape.axisY)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local wantedX, wantedY=screenWidth/2,screenHeight/2 -- after translation and scaling, the position of the player (default is center of the screen)
    if G.viewOffset then
        wantedX=wantedX+G.viewOffset.x
        wantedY=wantedY+G.viewOffset.y
    end
    local translateX,translateY=wantedX-G.viewMode.object.x*scale,wantedY-G.viewMode.object.y*scale
    if getParams then
        return translateX,translateY,scale
    end
    love.graphics.translate(translateX,translateY)
    love.graphics.scale(scale)
end
G.antiFollowModeTransform=function(self)
    local scale=(love.graphics.getHeight()/2-Shape.axisY)/(G.viewMode.object.y-Shape.axisY)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local wantedX, wantedY=screenWidth/2,screenHeight/2 -- after translation and scaling, the position of the player (default is center of the screen)
    if G.viewOffset then
        wantedX=wantedX+G.viewOffset.x
        wantedY=wantedY+G.viewOffset.y
    end
    love.graphics.scale(1/scale)
    love.graphics.translate(-(wantedX-G.viewMode.object.x*scale),-(wantedY-G.viewMode.object.y*scale))
end

-- remove all objects in the scene
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