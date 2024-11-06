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
                self.updateDynamicPatternData(self.patternData)
                SetFont(96)
                love.graphics.print("Hyperbolic\n   STG",200,100,0,1,1)
                SetFont(36)
                for index, value in ipairs(self.currentUI.options) do
                    local name=value.text
                    love.graphics.print(name,300,300+index*100,0,1,1)
                end
                love.graphics.rectangle("line",300,300+self.currentUI.chosen*100,200,50)
                love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
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
                    self.currentLevel={level,scene}
                    Shape.restore()
                    levelData[level][scene].make()
                elseif isPressed('x') or isPressed('escape')then
                    self.STATE=self.STATES.MAIN_MENU
                elseif isPressed('[') then
                    self.save.levelPassed[level][scene]=math.max(self.save.levelPassed[level][scene]-1,0)
                elseif isPressed(']') then
                    self.save.levelPassed[level][scene]=math.min(self.save.levelPassed[level][scene]+1,2)
                end
            end,
            draw=function(self)
                local level=self.currentUI.chosenLevel
                local scene=self.currentUI.chosenScene
                self.updateDynamicPatternData(self.patternData)
                SetFont(36)
                love.graphics.print("Level "..level,100,50,0,1,1)
                SetFont(36)
                for index, value in ipairs(levelData[level]) do
                    local color={love.graphics.getColor()}
                    love.graphics.setColor(.7,.6,.6)
                    if self.save.levelPassed[level][index]==1 then
                        love.graphics.setColor(.7,1,.7)
                    elseif self.save.levelPassed[level][index]==2 then
                        love.graphics.setColor(1,1,0.5)
                    end
                    love.graphics.print("Scene "..index,100,100+index*50,0,1,1)
                    love.graphics.setColor(color[1],color[2],color[3])
                end
                love.graphics.rectangle("line",100,100+scene*50,200,50)
                love.graphics.rectangle("line",320,500,400,80)
                local text=levelData.defaultQuote
                if self.save.levelPassed[level][scene]>=1 then
                    text=levelData[level][scene].quote or ''
                end
                SetFont(18)
                love.graphics.printf(text,330,510,380,"left",0,1,1)
            end
        },
        IN_LEVEL={
            update=function(self,dt)
                Asset:clearBatches()
                Asset.backgroundBatch:add(Asset.backgroundLeft,0,0,0,1,1,0,0)
                Asset.backgroundBatch:add(Asset.backgroundRight,600,0,0,1,1,0,0)
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
                Asset:drawBatches()
                Object:drawAll()
                
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
                Asset:drawBatches()
                Object:drawAll()
                
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
    for k,value in ipairs(levelData) do
        if not self.save.levelPassed[k] then
            self.save.levelPassed[k]={}
        end
        for i=1,#value do
            if not self.save.levelPassed[k][i] then
                self.save.levelPassed[k][i]=0
            end
        end
    end
end
G:loadData()
G.win=function(self)
    self.won_current_scene=true
    self.STATE=self.STATES.GAME_END
    local winLevel=1
    if Player.objects[1].hp==Player.objects[1].maxhp then
        winLevel=2
    end
    self.save.levelPassed[self.UIDEF.CHOOSE_LEVELS.chosenLevel][self.UIDEF.CHOOSE_LEVELS.chosenScene]=math.max(self.save.levelPassed[self.UIDEF.CHOOSE_LEVELS.chosenLevel][self.UIDEF.CHOOSE_LEVELS.chosenScene],winLevel)
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
        -- Shape.line(point.x,point.y,newpoint.x,newpoint.y)
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