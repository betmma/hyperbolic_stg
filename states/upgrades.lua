return {
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
    end,
    upgrades=Upgrades.data,
    options=Upgrades.upgradesTree,
    chosen={1,1},
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        local options=Upgrades.upgradesTree
        local upgrades=Upgrades.data
        local chosen=self.currentUI.chosen
        local option=options[chosen[1]][chosen[2]]
        local dirValues={down={0,1},up={0,-1},left={-1,0},right={1,0}}
        for key, dir in pairs(dirValues) do
            if isPressed(key) then
                local newUpgrade=Upgrades.moveToNode(option.upgrade,key)
                local newx,newy=Upgrades.nodes[newUpgrade].pos.x,Upgrades.nodes[newUpgrade].pos.y
                self.currentUI.chosen={newx,newy}
                if newUpgrade~=option.upgrade then
                    SFX:play('select')
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
            for k,value in pairs(upgrades) do
                self.save.upgrades[k].bought=false
            end
            self.currentUI.chosen={1,1}
        elseif isPressed('z') then
            local restXP=Upgrades.calculateRestXP()
            if option.upgrade then
                local upgrade=upgrades[option.upgrade]
                local bought=self.save.upgrades[option.upgrade].bought
                if bought then -- cancel the upgrade
                    self.save.upgrades[option.upgrade].bought=false
                    SFX:play('select')
                    -- need to cancel all upgrades related to this upgrade
                    local function recursiveCancel(cancelledUpgrade)
                        for name,value in pairs(upgrades) do
                            local requires=Upgrades.nodes[name].requires
                            for key, neededUpgrade in pairs(requires) do
                                if cancelledUpgrade==neededUpgrade and self.save.upgrades[name].bought==true then
                                    self.save.upgrades[name].bought=false
                                    recursiveCancel(name)
                                    break
                                end
                            end
                        end
                    end
                    recursiveCancel(option.upgrade)
                elseif restXP<upgrade.cost then -- not enough XP
                    SFX:play('cancel',true)
                else -- successfully buy the upgrade
                    self.save.upgrades[option.upgrade].bought=true
                    EventManager.post(EventManager.EVENTS.BUY_UPGRADE,option.upgrade)
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
        for name,node in pairs(Upgrades.nodes) do
            local pos=node.pos
            local x,y=pos.x,pos.y
            local upgrade=self.currentUI.upgrades[name]
            -- lines
            local requires=node.requires
            local isNeedSatisfied=Upgrades.needSatisfied(name)
            if not isNeedSatisfied then
                goto continue
            end
            for i,req in ipairs(requires) do
                local reqPos=Upgrades.nodes[req].pos
                local reqX,reqY=reqPos.x,reqPos.y
                love.graphics.setColor(1,1,1)
                love.graphics.line(dx/2+xbegin+dx*x,dx/2+ybegin+dx*y,dx/2+xbegin+dx*reqX,dx/2+ybegin+dx*reqY)
            end
            local bought=self.save.upgrades[name].bought
            -- box
            if bought then
                love.graphics.setColor(1,1,1)
            else
                love.graphics.setColor(.8,.8,.8)
            end
            love.graphics.rectangle(bought and "fill" or "line",gap+xbegin+dx*x,gap+ybegin+dx*y,size,size)
            ::continue::
        end
        for name,node in pairs(Upgrades.nodes) do -- icons at top of all lines so need second loop
            local pos=node.pos
            local x,y=pos.x,pos.y
            local upgrade=self.currentUI.upgrades[name]
            local isNeedSatisfied=Upgrades.needSatisfied(name)
            if not isNeedSatisfied then
                goto continue
            end
            local bought=self.save.upgrades[name].bought
            if bought then
                love.graphics.setColor(1,1,1)
            else
                love.graphics.setColor(.8,.8,.8)
            end
            -- icon
            local spritePos=upgrade.spritePos
            love.graphics.draw(Asset.upgradeIconsImage, Asset.upgradeIcons[spritePos.x][spritePos.y], gap+xbegin+dx*x,gap+ybegin+dx*y,0,1,1)
            ::continue::
        end
        -- draw chosen (a bigger square around the chosen upgrade)
        local chosen=self.currentUI.chosen
        local chosenOption=options[chosen[1]][chosen[2]]
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
        love.graphics.printf(Localize{'ui','upgradesCurrentXP',xp=Upgrades.calculateRestXP()},500,570,380,"left",0,1,1)

        love.graphics.setColor(color[1],color[2],color[3],color[4] or 1)
    end,
}