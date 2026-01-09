---@class Nickname:Object
---@field ID integer
---@field name string used to find name and description in localization file. should be unique and short
---@field eventName string the event this nickname is associated with
---@field eventFunc fun(...):nil called when eventName event is posted. generally it should update statistics
---@field isSecret boolean if true, this nickname is not shown in nicknames menu when locked
---@field extraLocalizeInputFunc fun():table additional key-value pairs to be added to Localize input when getting description text
local Nickname=Object:extend()

-- localization format: name, condition, description
---@class NicknameLocalization
---@field name localizationItem the string appearing out of box
---@field condition localizationItem the string describing the condition to unlock this nickname, always shown
---@field description localizationItem usually some comments, shown only when unlocked

---@type table<integer,Nickname>
Nickname.nicknames={}

Nickname.nicknameCount=0

function Nickname:new(args)
    Nickname.super.new(self, args)
    self.name=args.name
    self.eventName=args.eventName
    self.eventFunc=args.eventFunc or function(...)end
    self.isSecret=args.isSecret or false
    self.extraLocalizeInputFunc=args.extraLocalizeInputFunc or function()return {} end
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

---@return string name the display name of this nickname (from Localize)
function Nickname:getName()
    local ret=Localize{'nickname',self.name,'name'}
    return ret
end

---@param unlocked boolean whether this nickname is unlocked
---@return string text the description text of this nickname (from Localize)
function Nickname:getText(unlocked)
    local condition=Localize(self:_getConditionLocalizeInput())
    if unlocked then
        local description=Localize(self:_getDescriptionLocalizeInput())
        return string.format('%s\n%s',condition,description)
    else
        return condition
    end
end

---@return table localization input for condition string
function Nickname:_getConditionLocalizeInput()
    return {'nickname',self.name,'condition'}
end

---@return table localization input for description string
function Nickname:_getDescriptionLocalizeInput()
    local base={'nickname',self.name,'description'}
    local toAdd=self:extraLocalizeInputFunc()
    for k,v in pairs(toAdd) do
        base[k]=v
    end
    return base
end

---@class ProgressedNickname:Nickname display a progress bar in nickname menu when unlocked.
---@field progressFunc fun():number read from statistics and calculate filled ratio of progress bar.
local ProgressedNickname=Nickname:extend()
function ProgressedNickname:new(args)
    self.progressFunc=args.progressFunc or function(self)return 0 end
    args.eventFunc=args.eventFunc or function(self)return self:progressFunc()>=1 end
    ProgressedNickname.super.new(self, args)
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

-- this is to draw notice box when a nickname is unlocked. considering moving to notice.lua
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

Nickname.BeatTheGame=Nickname{
    name='BeatTheGame',
    eventName=EventManager.EVENTS.WIN_LEVEL,
    eventFunc=function(self,levelData,player,perfect)
        if levelData.id==100 then -- 12-9, final level
            if G.save.nicknameUnlock[self.name]~=true then -- first time unlock, go to ending screen
                G:switchState(G.STATES.ENDING)
            end
            return true
        end
    end,
}
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
EventManager.listenTo(EventManager.EVENTS.LEAVE_LEVEL, function(level,scene,inReplay,win)
    if not inReplay and not win then
        G.save.statistics.loseCount=G.save.statistics.loseCount+1
    end
end)
ProgressedNickname{
    name='Lose100Times',
    progressFunc=function()
        return G.save.statistics.loseCount/100
    end,
    eventName=EventManager.EVENTS.LEAVE_LEVEL
}
ProgressedNickname{
    name='Lose300Times',
    progressFunc=function()
        return G.save.statistics.loseCount/300
    end,
    eventName=EventManager.EVENTS.LEAVE_LEVEL
}
ProgressedNickname{
    name='Lose1000Times',
    progressFunc=function()
        return G.save.statistics.loseCount/1000
    end,
    eventName=EventManager.EVENTS.LEAVE_LEVEL,
    extraLocalizeInputFunc=function(self)
        return {count=G.save.statistics.loseCount}
    end,
}
ProgressedNickname{
    name='Play30Minutes',
    progressFunc=function()
        return G.save.playTimeTable.playTimeOverall/(30*60)
    end,
    eventName=EventManager.EVENTS.LEAVE_LEVEL,
}
ProgressedNickname{
    name='Play1Hour',
    progressFunc=function()
        return G.save.playTimeTable.playTimeOverall/(60*60)
    end,
    eventName=EventManager.EVENTS.LEAVE_LEVEL,
}
ProgressedNickname{
    name='Play3Hours',
    progressFunc=function()
        return G.save.playTimeTable.playTimeOverall/(3*60*60)
    end,
    eventName=EventManager.EVENTS.LEAVE_LEVEL,
}
ProgressedNickname{
    name='Play10Hours',
    progressFunc=function()
        return G.save.playTimeTable.playTimeOverall/(10*60*60)
    end,
    eventName=EventManager.EVENTS.LEAVE_LEVEL,
}
Nickname{
    name='Take10DamageIn1Scene',
    extraLocalizeInputFunc=function(self)
        local maxDamageTaken=G.save.statistics.maxDamageTaken or {levelData={level=0,scene=0},amount=0}
        return {level=maxDamageTaken.levelData.level,scene=maxDamageTaken.levelData.scene,amount=maxDamageTaken.amount}
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
Nickname{
    name='PerfectWinIn15Seconds',
    extraLocalizeInputFunc=function(self)
        local fastestWin=G.save.statistics.fastestWin or {levelData={level=0,scene=0},time=999}
        return{level=fastestWin.levelData.level,scene=fastestWin.levelData.scene,time=string.format("%.2f",fastestWin.time)}
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
    name='Stonemason',
    isSecret=true,
    eventName=EventManager.EVENTS.WIN_LEVEL,
    eventFunc=function(self,levelData,player,perfect)
        if levelData.id==137 and player.stoneMissed<=3 then -- 3-7 Eika stack stone spellcard
            return true
        end
    end
}
Nickname{
    name='TrianglePower',
    isSecret=true,
    eventName=EventManager.EVENTS.WIN_LEVEL,
    eventFunc=function(self,levelData,player,perfect)
        if levelData.id==111 and player.insideLargeTriangleFrame>=600 then -- 9-8 Keiki triangle creature spellcard
            return true
        end
    end
}
Nickname{
    name='GapYoukai',
    isSecret=true,
    eventName=EventManager.EVENTS.WIN_LEVEL,
    eventFunc=function(self,levelData,player,perfect)
        if levelData.id==117 and player.outsideMainMountain and perfect then -- 10-5 Watatsuki mountain and sea spellcard
            return true
        end
    end
}
Nickname{
    name='MaginotLine',
    eventName=EventManager.EVENTS.WIN_LEVEL,
    eventFunc=function(self,levelData,player,perfect)
        if levelData.id==75 and not G.phase4EnteredInner then -- 11-3 yukari Fortress spellcard
            return true
        end
        return false
    end,
    isSecret=true,
}
Nickname{
    name='BombSurvivor',
    eventName=EventManager.EVENTS.WIN_LEVEL,
    eventFunc=function(self,levelData,player,perfect)
        if levelData.id==109 and G.bombExploded==true then -- 12-8 kotoba fuse web spellcard
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
        if not player.keyEverPressed['lshift'] and perfect then
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
        if not player.keyEverPressed['left'] and not player.keyEverPressed['right'] and perfect then
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
        if not player.keyEverPressed['up'] and not player.keyEverPressed['down'] and perfect then
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
return Nickname