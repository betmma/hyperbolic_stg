---@class Nickname:Object
---@field name string used to find name and description in localization file. should be unique and short
---@field progressFunc fun():number read from statistics and calculate filled ratio of progress bar in nickname menu, and if returns 1 this nickname is unlocked.
---@field eventName string the event this nickname is associated with
---@field eventFunc fun(...):nil update statistics
---@field isSecret boolean if true, this nickname is not shown in nicknames menu when locked
local Nickname=Object:extend()

-- localization format: name, condition, description

Nickname.nicknames={}
Nickname.nicknameCount=0

function Nickname:new(args)
    Nickname.super.new(self, args)
    self.name=args.name
    self.progressFunc=args.progressFunc or function()return 0 end
    self.eventName=args.eventName
    self.eventFunc=args.eventFunc or function(...)end
    self.isSecret=args.isSecret or false
    EventManager.listenTo(self.eventName, function(...)
        self.eventFunc(...)
        if self.progressFunc()>=1 and G.save.nicknames[self.name]~=true then
            G.save.nicknames[self.name]=true
            EventManager.post('NicknameUnlocked',self.name)
        end
    end)
    Nickname.nicknameCount=Nickname.nicknameCount+1
    Nickname.nicknames[Nickname.nicknameCount]=self
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
    name='PerfectAllScenes',
    progressFunc=function()
        local passed,all,perfect=G:countPassedSceneNum()
        return perfect/all
    end,
    eventName='winLevel',
    isSecret=true,
}
return Nickname