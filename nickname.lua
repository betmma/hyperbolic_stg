---@class Nickname:Object
---@field ID integer
---@field name string used to find name and description in localization file. should be unique and short
---@field eventName string the event this nickname is associated with
---@field eventFunc fun(...):nil called when eventName event is posted. generally it should update statistics
---@field isSecret boolean if true, this nickname is not shown in nicknames menu when locked
local Nickname=Object:extend()

-- localization format: name, condition, description
---@class NicknameLocalization
---@field name localizationItem
---@field condition localizationItem
---@field description localizationItem

---@type table<integer,Nickname>
Nickname.nicknames={}

Nickname.nicknameCount=0

function Nickname:new(args)
    Nickname.super.new(self, args)
    self.name=args.name
    self.eventName=args.eventName
    self.eventFunc=args.eventFunc or function(...)end
    self.isSecret=args.isSecret or false
    Nickname.nicknameCount=Nickname.nicknameCount+1
    self.ID=Nickname.nicknameCount
    Nickname.nicknames[Nickname.nicknameCount]=self
    EventManager.listenTo(self.eventName, function(...)
        local ret=self:eventFunc(...)
        if ret and G.save.nicknameUnlock[self.name]~=true then
            G.save.nicknameUnlock[self.name]=true
            EventManager.post(EventManager.EVENTS.NICKNAME_GET,self.ID)
        end
    end)
end

---@class ProgressedNickname:Nickname display a progress bar in nickname menu when unlocked.
---@field progressFunc fun():number read from statistics and calculate filled ratio of progress bar.
local ProgressedNickname=Nickname:extend()
function ProgressedNickname:new(args)
    self.progressFunc=args.progressFunc or function(self)return 0 end
    args.eventFunc=args.eventFunc or function(self)return self:progressFunc()>=1 end
    ProgressedNickname.super.new(self, args)
end

---@class DetailedNickname:Nickname with extra detail string about progress.
---@field detailFunc fun():string read from statistics and use Localize to form and return a string to show in nickname menu.
local DetailedNickname=Nickname:extend()
function DetailedNickname:new(args)
    self.detailFunc=args.detailFunc or function(self)return '' end
    DetailedNickname.super.new(self, args)
end

local nicknamePending={}
local displayFrame=120
local function nicknameGet(id)
    nicknamePending[id]=G.frame
    -- Event.DelayEvent{ -- not removing??
    --     obj=G,delayFrame=displayFrame,executeFunc=function()
    --         nicknamePending[id]=nil
    --     end
    -- }
end
EventManager.listenTo(EventManager.EVENTS.NICKNAME_GET,nicknameGet)

-- this is to draw notice box when a nickname is unlocked
function Nickname:drawText()
    local color={love.graphics.getColor()}
    local count=0
    local x,y=650,0
    local width,height=150,50
    local gap=5
    for id,frame in pairs(nicknamePending) do
        local ratio=(G.frame-frame)/displayFrame
        if ratio>1 then
            goto continue
        end
        local transparency=math.min(ratio*10,1-ratio)
        local nickname=Nickname.nicknames[id]
        local get=Localize{'ui','nicknameGet'}
        local name=Localize{'nickname',nickname.name,'name'}
        love.graphics.setColor(0,0,0,transparency)
        love.graphics.rectangle('fill',x,y+height*count,width,height)
        love.graphics.setColor(1,1,1,transparency)
        love.graphics.rectangle('line',x,y+height*count,width,height)
        SetFont(16)
        love.graphics.printf(get,x+gap,y+height*count,width-gap*2,'center')
        love.graphics.setColor(1,1,0.5,transparency)
        SetFont(18)
        love.graphics.printf(name,x+gap,y+height*count+gap*3,width-gap*2,'center')
        count=count+1
        ::continue::
    end
    if count>0 then
        love.graphics.setColor(color)
    end
end

ProgressedNickname{
    name='PassAllScenes',
    progressFunc=function()
        local passed,all=G:countPassedSceneNum()
        return passed/all
    end,
    eventName=EventManager.EVENTS.WIN_LEVEL,
}
ProgressedNickname{
    name='Pass1Scene',
    progressFunc=function()
        return G:countPassedSceneNum()
    end,
    eventName=EventManager.EVENTS.WIN_LEVEL,
}
ProgressedNickname{
    name='Lose100Times',
    progressFunc=function()
        G.save.statistics.loseCount=G.save.statistics.loseCount or 0
        return G.save.statistics.loseCount/100
    end,
    eventName=EventManager.EVENTS.LOSE_LEVEL,
    eventFunc=function()
        G.save.statistics.loseCount=(G.save.statistics.loseCount or 0)+1
        return G.save.statistics.loseCount/100>=1
    end,
}
DetailedNickname{
    name='Take10DamageIn1Scene',
    detailFunc=function(self)
        local maxDamageTaken=G.save.statistics.maxDamageTaken or {levelData={level=0,scene=0},amount=0}
        return Localize{'nickname',self.name,'detail',level=maxDamageTaken.levelData.level,scene=maxDamageTaken.levelData.scene,amount=maxDamageTaken.amount}
    end,
    eventName=EventManager.EVENTS.PLAYER_HIT,
    eventFunc=function(self,player)
        local maxDamageTaken=G.save.statistics.maxDamageTaken or {levelData={level=0,scene=0},amount=0}
        local damage=player.damageTaken
        if damage>maxDamageTaken.amount then
            local level=G.UIDEF.CHOOSE_LEVELS.chosenLevel
            local scene=G.UIDEF.CHOOSE_LEVELS.chosenScene
            maxDamageTaken.amount=damage
            maxDamageTaken.levelData={level=level,scene=scene}
            G.save.statistics.maxDamageTaken=maxDamageTaken
        end
        return maxDamageTaken.amount>=10
    end,
}
DetailedNickname{
    name='PerfectWinIn15Seconds',
    detailFunc=function(self)
        local fastestWin=G.save.statistics.fastestWin or {levelData={level=0,scene=0},time=999}
        return Localize{'nickname',self.name,'detail',level=fastestWin.levelData.level,scene=fastestWin.levelData.scene,time=string.format("%.2f",fastestWin.time)}
    end,
    eventName=EventManager.EVENTS.WIN_LEVEL,
    eventFunc=function(self,levelData,player,perfect)
        local usedTime=(G.levelRemainingFrameMax-G.levelRemainingFrame)/60
        local fastestWin=G.save.statistics.fastestWin or {levelData={level=0,scene=0},time=math.huge}
        if usedTime<fastestWin.time and perfect then
            fastestWin.time=usedTime
            fastestWin.levelData=levelData
            G.save.statistics.fastestWin=fastestWin
        end
        return fastestWin.time<15
    end,
}
Nickname{
    name='ThisIsTouhou',
    eventName=EventManager.EVENTS.LOSE_LEVEL,
    eventFunc=function(self)
        if G.preWin then
            return true
        end
        return false
    end,
    isSecret=true,
}
Nickname{
    name='HurrySickness',
    eventName=EventManager.EVENTS.WIN_LEVEL,
    eventFunc=function(self,levelData,player,perfect)
        if not player.keyEverPressed['lshift'] then
            return true
        end
        return false
    end,
    isSecret=true,
}
Nickname{
    name='VerticalThinking',
    eventName=EventManager.EVENTS.WIN_LEVEL,
    eventFunc=function(self,levelData,player,perfect)
        if not player.keyEverPressed['left'] and not player.keyEverPressed['right'] then
            return true
        end
        return false
    end,
    isSecret=true,
}
Nickname{
    name='LateralThinking',
    eventName=EventManager.EVENTS.WIN_LEVEL,
    eventFunc=function(self,levelData,player,perfect)
        if not player.keyEverPressed['up'] and not player.keyEverPressed['down'] then
            return true
        end
        return false
    end,
    isSecret=true,
}
ProgressedNickname{
    name='PerfectAllScenes',
    progressFunc=function()
        local passed,all,perfect=G:countPassedSceneNum()
        return perfect/all
    end,
    eventName=EventManager.EVENTS.WIN_LEVEL,
    isSecret=true,
}

Nickname.ProgressedNickname=ProgressedNickname
Nickname.DetailedNickname=DetailedNickname
return Nickname