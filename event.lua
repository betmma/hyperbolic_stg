
local Event = Object:extend()
Event.modes={
    oneFrameOnce=0,
    oneFrameMultiple=1
}
-- conditionFunc, executeFunc, times, mode: Event.modes, obj
-- when update checks if [conditionFunc(self,dt)] returns true, then execute [executeFunc(self,dt,obj)]. after executed [times] times or executeFunc returns false or obj.removed is true it's removed. [mode] can be Event.modes.oneFrameOnce or Event.modes.oneFrameMultiple
-- if [activated] is false the event won't update.
-- you can set [time] and check it in [conditionFunc] to do same thing as LoopEvent
function Event:new(args)
    self.time=args.time or 0
    self.times=args.times or 999999999999
    self.mode=args.mode or Event.modes.oneFrameOnce
    self.executedTimes=0
    self.obj=args.obj or self
    local conditionFunc=args.conditionFunc or function(self,dt)return true end
    self.conditionFunc=function(self,dt)return self.obj.removed~=true and conditionFunc(self,dt)end
    self.executeFunc=args.executeFunc or function(self,dt)return true end
    self.activated=args.activated or true
end

function Event:update(dt)
    if self.activated==false or self.removed then return end
    self.time=self.time+dt
    local first=true
    while first==true or self.mode==Event.modes.oneFrameMultiple do
        first=false
        local ret
        if self:conditionFunc(dt) and self.executedTimes<self.times then
            self:executeFunc(dt)
            self.executedTimes=self.executedTimes+1
        end
        if self.executedTimes>self.times or self.obj.removed then
            self:remove()
            return
        end
    end
    -- self.time=self.time+dt
end

-- Event that checks condition for every [period] secs. Initially the time is set to [time]. (so if time==period it triggers upon creation)
-- conditionFunc, executeFunc, times, mode:Event.modes, time, period
local LoopEvent = Event:extend()
function LoopEvent:new(args)
    LoopEvent.super.new(self, args)
    self.conditionFuncRef=self.conditionFunc
    self.period=args.period or 1
    self.conditionFunc=function(self,dt)
        if self.time>self.period then
            self.time=self.time-self.period
            return self.conditionFuncRef(self,dt)
        end
        return false
    end
end

-- function LoopEvent:update(dt)
--     LoopEvent.super.update(self,dt)
-- end
Event.LoopEvent=LoopEvent

-- Event that changes [aimTable].[key] to [aimValue] in [easeTime] secs.
-- [progressFunc] can be used to make smooth start or stop. e.g. sin(x*pi/2)
-- maybe make more default progressFuncs. I remember such functions in Unity.
local EaseEvent = Event:extend()
function EaseEvent:new(args)
    LoopEvent.super.new(self, args)
    self.time=0
    self.lastTime=0
    self.period=args.easeTime or 1
    self.aimTable=args.aimTable or {}
    self.key=args.aimKey
    self.aimValue=args.aimValue or 0
    self.startValue=self.aimTable[self.key]
    -- can be used to make smooth start or stop. e.g. sin(x*pi/2)
    self.progressFunc=args.progressFunc or function(x)return x end
    self.conditionFunc=function(self,dt)
        return true
    end
    self.executeFunc=function(self,dt)
        if self.time>self.period then
            self.time=self.period
        end
        if not self.aimTable or self.aimTable.removed then
            return false
        end
        self.aimTable[self.key]=self.aimTable[self.key]+(self.progressFunc(self.time/self.period)-self.progressFunc(self.lastTime/self.period))*(self.aimValue-self.startValue)
        if self.time==self.period then
            self.times=0
            self:remove()
        end
        self.lastTime=self.time
    end
end
function EaseEvent:update(dt)
    -- self.time=self.time+dt
    EaseEvent.super.update(self,dt)
end

Event.EaseEvent=EaseEvent

return Event