---@class Nickname:Object
---@field ID integer
---@field name string used to find name and description in localization file. should be unique and short
---@field progressFunc fun():number read from statistics and calculate filled ratio of progress bar in nickname menu, and if returns 1 this nickname is unlocked.
---@field eventName string the event this nickname is associated with
---@field eventFunc fun(...):nil update statistics
---@field isSecret boolean if true, this nickname is not shown in nicknames menu when locked
local Nickname=Object:extend()

-- localization format: name, condition, description

---@type table<integer,Nickname>
Nickname.nicknames={}

Nickname.nicknameCount=0

function Nickname:new(args)
    Nickname.super.new(self, args)
    self.name=args.name
    self.progressFunc=args.progressFunc or function()return 0 end
    self.eventName=args.eventName
    self.eventFunc=args.eventFunc or function(...)end
    self.isSecret=args.isSecret or false
    Nickname.nicknameCount=Nickname.nicknameCount+1
    self.ID=Nickname.nicknameCount
    EventManager.listenTo(self.eventName, function(...)
        self.eventFunc(...)
        if self.progressFunc()>=1 and G.save.nicknameUnlock[self.name]~=true then
            G.save.nicknameUnlock[self.name]=true
            EventManager.post('NicknameGet',self.ID)
        end
    end)
    Nickname.nicknames[Nickname.nicknameCount]=self
end

local nicknamePending={}
local displayFrame=120
local function nicknameGet(id)
    nicknamePending[id]=G.frame
    Event.DelayEvent{
        obj=G,delayFrame=displayFrame,executeFunc=function()
            nicknamePending[id]=nil
        end
    }
end
EventManager.listenTo('NicknameGet',nicknameGet)

-- this is to draw notice box when a nickname is unlocked
function Nickname:drawText()
    local count=0
    local x,y=650,0
    local width,height=150,50
    local gap=5
    for id,frame in pairs(nicknamePending) do
        local ratio=(G.frame-frame)/displayFrame
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
    end
end

Nickname{
    name='PassAllScenes',
    progressFunc=function()
        local passed,all=G:countPassedSceneNum()
        return passed/all
    end,
    eventName='winLevel'
}
Nickname{
    name='Pass1Scene',
    progressFunc=function()
        return G:countPassedSceneNum()
    end,
    eventName='winLevel'
}
Nickname{
    name='Lose100Times',
    progressFunc=function()
        G.save.statistics.loseCount=G.save.statistics.loseCount or 0
        return G.save.statistics.loseCount/100
    end,
    eventName='loseLevel',
    eventFunc=function()
        G.save.statistics.loseCount=(G.save.statistics.loseCount or 0)+1
    end,
}
Nickname{
    name='PerfectAllScenes',
    progressFunc=function()
        local passed,all,perfect=G:countPassedSceneNum()
        return perfect/all
    end,
    eventName='winLevel',
    isSecret=true,
}
return Nickname