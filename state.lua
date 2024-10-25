local levelData=require"levelData"
local G={
    STATES={
        MAIN_MENU='MAIN_MENU',
        CHOOSE_LEVELS='CHOOSE_LEVELS',
        IN_LEVEL='IN_LEVEL',
        PAUSE='PAUSE'
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
                    self.STATE=self.STATES.IN_LEVEL
                    levelData[self.currentUI.chosenLevel][self.currentUI.chosenScene].make()
                elseif isPressed('x') then
                    self.STATE=self.STATES.MAIN_MENU
                end
            end,
            draw=function(self)
                SetFont(36)
                love.graphics.print("Level "..self.currentUI.chosenLevel,100,100,0,1,1)
                SetFont(36)
                for index, value in ipairs(levelData[self.currentUI.chosenLevel]) do
                    love.graphics.print("Scene "..index,100,200+index*100,0,1,1)
                end
                love.graphics.rectangle("line",100,200+self.currentUI.chosenScene*100,200,50)
            end
        },
        IN_LEVEL={
            update=function(self,dt)
            end,
            draw=function(self)
            end
        }
    }
}

G.STATE=G.STATES.MAIN_MENU
G.update=function(self,dt)
    self.currentUI=self.UIDEF[self.STATE]
    self.currentUI.update(self,dt)
end
G.draw=function(self)
    self.currentUI=self.UIDEF[self.STATE]
    self.currentUI.draw(self)
end
return G