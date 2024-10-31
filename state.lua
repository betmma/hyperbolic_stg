local levelData=require"levelData"
local G={
    STATES={
        MAIN_MENU='MAIN_MENU',
        CHOOSE_LEVELS='CHOOSE_LEVELS',
        IN_LEVEL='IN_LEVEL',
        PAUSE='PAUSE',
        GAME_END='GAME_END' --either win or lose
    },
    STATE=...,
    UIDEF={
        MAIN_MENU={
            options={
                {text='START',value='START'},
                {text='EXIT',value='EXIT'},
            },
            chosen=1,
            update=function(self,dt)
                local size=#self.currentUI.options
                if isPressed('down') then
                    self.currentUI.chosen=self.currentUI.chosen%size+1
                elseif isPressed('up') then
                    self.currentUI.chosen=(self.currentUI.chosen-2)%size+1
                elseif isPressed('z') then
                    local value=self.currentUI.options[self.currentUI.chosen].value
                    if value=='EXIT' then
                        love.event.quit()
                    elseif value=='START' then
                        self.STATE=self.STATES.CHOOSE_LEVELS
                    end
                end
            end,
            draw=function(self)
                SetFont(96)
                love.graphics.print("Hyperbolic\n   STG",200,100,0,1,1)
                SetFont(36)
                for index, value in ipairs(self.currentUI.options) do
                    local name=value.text
                    love.graphics.print(name,300,300+index*100,0,1,1)
                end
                love.graphics.rectangle("line",300,300+self.currentUI.chosen*100,200,50)
            end
        },
        CHOOSE_LEVELS={
            chosenLevel=1,
            chosenScene=1,
            update=function(self,dt)
                local levelNum=#levelData
                local sceneNum=#levelData[self.currentUI.chosenLevel]
                if isPressed('down') then
                    self.currentUI.chosenScene=self.currentUI.chosenScene%sceneNum+1
                elseif isPressed('up') then
                    self.currentUI.chosenScene=(self.currentUI.chosenScene-2)%sceneNum+1
                elseif isPressed('right') then
                    self.currentUI.chosenLevel=self.currentUI.chosenLevel%levelNum+1
                elseif isPressed('left') then
                    self.currentUI.chosenLevel=(self.currentUI.chosenLevel-2)%levelNum+1
                elseif isPressed('z') then
                    self:removeAll()
                    self.STATE=self.STATES.IN_LEVEL
                    self.currentLevel={self.currentUI.chosenLevel,self.currentUI.chosenScene}
                    levelData[self.currentUI.chosenLevel][self.currentUI.chosenScene].make()
                elseif isPressed('x') or isPressed('escape')then
                    self.STATE=self.STATES.MAIN_MENU
                end
            end,
            draw=function(self)
                SetFont(36)
                love.graphics.print("Level "..self.currentUI.chosenLevel,100,50,0,1,1)
                SetFont(36)
                for index, value in ipairs(levelData[self.currentUI.chosenLevel]) do
                    local color={love.graphics.getColor()}
                    love.graphics.setColor(1,1,1)
                    if self.save.levelPassed[self.currentUI.chosenLevel][index]==true then
                        love.graphics.setColor(1,1,0.5)
                    end
                    love.graphics.print("Scene "..index,100,100+index*50,0,1,1)
                    love.graphics.setColor(color[1],color[2],color[3])
                end
                love.graphics.rectangle("line",100,100+self.currentUI.chosenScene*50,200,50)
            end
        },
        IN_LEVEL={
            update=function(self,dt)
                Asset:clearBatches()
                -- BulletSpawner:updateAll(dt)
                -- Circle:updateAll(dt)
                -- Player:updateAll(dt)
                -- Event:updateAll(dt)
                -- Enemy:updateAll(dt)
                Object:updateAll(dt)
                Asset:flushBatches()
                if isPressed('escape') then
                    -- self:removeAll()
                    self.STATE=self.STATES.PAUSE
                end
            end,
            draw=function(self)
                Asset:drawBatches()
                SetFont(18)
                love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
                -- Rectangle:drawAll()
                -- Circle:drawAll()
                -- PolyLine:drawAll()
                -- PolyLine.drawAll(BulletSpawner) -- a fancy way to call BulletSpawner:drawAll()
                -- Player:drawAll()
                -- Enemy:drawAll()
                Object:drawAll()
            end
        },
        PAUSE={
            options={
                {text='RESUME',value='RESUME'},
                {text='EXIT',value='EXIT'},
            },
            chosen=1,
            update=function(self,dt)
                local size=#self.currentUI.options
                if isPressed('down') then
                    self.currentUI.chosen=self.currentUI.chosen%size+1
                elseif isPressed('up') then
                    self.currentUI.chosen=(self.currentUI.chosen-2)%size+1
                elseif isPressed('z') then
                    local value=self.currentUI.options[self.currentUI.chosen].value
                    if value=='EXIT' then
                        self:removeAll()
                        self.STATE=self.STATES.CHOOSE_LEVELS
                    elseif value=='RESUME' then
                        self.STATE=self.STATES.IN_LEVEL
                    end
                end
                if isPressed('escape') then
                    self.STATE=self.STATES.IN_LEVEL
                end
            end,
            draw=function(self)
                love.graphics.draw(BulletBatch)
                Rectangle:drawAll()
                Circle:drawAll()
                PolyLine:drawAll()
                PolyLine.drawAll(BulletSpawner) -- a fancy way to call BulletSpawner:drawAll()
                Player:drawAll()
                
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
                {text='RESTART',value='RESTART'},
                {text='EXIT',value='EXIT'},
            },
            chosen=1,
            update=function(self,dt)
                local size=#self.currentUI.options
                if isPressed('down') then
                    self.currentUI.chosen=self.currentUI.chosen%size+1
                elseif isPressed('up') then
                    self.currentUI.chosen=(self.currentUI.chosen-2)%size+1
                elseif isPressed('z') then
                    local value=self.currentUI.options[self.currentUI.chosen].value
                    if value=='EXIT' then
                        self:removeAll()
                        self.STATE=self.STATES.CHOOSE_LEVELS
                    elseif value=='RESTART' then
                        self:removeAll()
                        levelData[self.UIDEF.CHOOSE_LEVELS.chosenLevel][self.UIDEF.CHOOSE_LEVELS.chosenScene].make()
                        self.STATE=self.STATES.IN_LEVEL
                    end
                end
            end,
            draw=function(self)
                love.graphics.draw(BulletBatch)
                Rectangle:drawAll()
                Circle:drawAll()
                PolyLine:drawAll()
                PolyLine.drawAll(BulletSpawner) -- a fancy way to call BulletSpawner:drawAll()
                Player:drawAll()
                
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
                    love.graphics.print(name,100,200+index*100,0,1,1)
                end
                love.graphics.rectangle("line",100,200+self.currentUI.chosen*100,200,50)
            end
        }
    }
}

G.STATE=G.STATES.MAIN_MENU
G.frame=0

local lume = require "lume"
G.saveData=function(self)
    local data = {}
    data=self.save or {}
	local serialized = lume.serialize(data)
  	love.filesystem.write("savedata.txt", serialized)
end
G.loadData=function(self)
	local file = love.filesystem.read("savedata.txt")
    self.save={}
    if file then
        local data = lume.deserialize(file)
        self.save=data or {}
    end
    if not self.save.levelPassed then
        self.save.levelPassed={}
    end
    for k,value in pairs(levelData) do
        if not self.save.levelPassed[k] then
            self.save.levelPassed[k]={}
        end
        for i=1,#value do
            if not self.save.levelPassed[k][i] then
                self.save.levelPassed[k][i]=false
            end
        end
    end
end
G:loadData()
G.win=function(self)
    self.won_current_scene=true
    self.STATE=self.STATES.GAME_END
    self.save.levelPassed[self.UIDEF.CHOOSE_LEVELS.chosenLevel][self.UIDEF.CHOOSE_LEVELS.chosenScene]=true
    self:saveData()
end
G.lose=function(self)
    self.won_current_scene=false
    self.STATE=self.STATES.GAME_END
end
G.update=function(self,dt)
    self.frame=self.frame+1
    self.currentUI=self.UIDEF[self.STATE]
    self.currentUI.update(self,dt)
end
G.draw=function(self)
    self.currentUI=self.UIDEF[self.STATE]
    self.currentUI.draw(self)
end
G.removeAll=function(self)
    Asset:clearBatches()
    -- BulletSpawner:removeAll()
    -- Circle:removeAll()
    -- Player:removeAll()
    -- Event:removeAll()
    -- Enemy:removeAll()
    Object:removeAll()
end
return G