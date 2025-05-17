---@class Event:Object
---@field time number time (seconds) since the event was created
---@field frame number frame since the event was created
---@field times number max times the event will be executed
---@field mode number Event.modes.oneFrameOnce or Event.modes.oneFrameMultiple. I think I never used Event.modes.oneFrameMultiple?
---@field executedTimes number times the event has been executed
---@field obj Object the object that the event is attached to. If not provided, it defaults to self. If obj is removed, the event will be removed too.
---@field conditionFunc fun(self: Object, ...):boolean Each frame, if it returns true, the event will be executed.
---@field executeFunc fun(self: Object, executedTimes: number, totalTimes:number):nil What the event does. Note that executedTimes is 0-based, and at last execution it's times-1.
local Event = GameObject:extend()
Event.modes={
    oneFrameOnce=0,
    oneFrameMultiple=1
}
Event.Event=Event -- for convenience as without it LoopEvent and EaseEvent need "Event." but base Event doesn't

-- conditionFunc, executeFunc, times, mode: Event.modes, obj
-- when update checks if [conditionFunc(self,dt)] returns true, then execute [executeFunc(self,dt,obj)]. after executed [times] times or executeFunc returns false or obj.removed is true it's removed. [mode] can be Event.modes.oneFrameOnce or Event.modes.oneFrameMultiple
-- if [activated] is false the event won't update.
-- you can set [time] and check it in [conditionFunc] to do same thing as LoopEvent
function Event:new(args)
    Event.super.new(args)
    self.time=args.time or 0
    self.frame=args.frame or 0
    self.times=args.times or 999999999999
    self.mode=args.mode or Event.modes.oneFrameOnce
    self.executedTimes=0
    self.obj=args.obj or self
    local conditionFunc=args.conditionFunc or function(self,dt)return true end
    self.conditionFunc=function(self,dt)return self.obj.removed~=true and conditionFunc(self,dt)end
    self.executeFunc=args.executeFunc or function(self,_,_)return true end
    self.activated=args.activated or true
end

function Event:update(dt)
    if self.activated==false or self.removed then return end
    self.time=self.time+dt
    self.frame=self.frame+1
    local first=true
    while first==true or self.mode==Event.modes.oneFrameMultiple do
        first=false
        local ret
        if self:conditionFunc(dt) and self.executedTimes<self.times then
            self:executeFunc(self.executedTimes,self.times)
            self.executedTimes=self.executedTimes+1
        end
        if self.executedTimes>=self.times or self.obj.removed then
            -- print(self.frame,self.obj.frame)
            self:remove()
            return
        end
    end
    -- self.time=self.time+dt
end

-- Event that checks condition for every [period] frames. 
---@class LoopEvent:Event
---@field period number period of the event in frames
local LoopEvent = Event:extend()
function LoopEvent:new(args)
    LoopEvent.super.new(self, args)
    self.conditionFuncRef=self.conditionFunc
    self.period=args.period or 60
    self.conditionFunc=function(self,dt)
        if self.frame>self.period then
            self.frame=self.frame-self.period
            return self.conditionFuncRef(self,dt)
        end
        return false
    end
end

-- function LoopEvent:update(dt)
--     LoopEvent.super.update(self,dt)
-- end
Event.LoopEvent=LoopEvent

-- Event that calls [executeFunc] after [delayFrame] (you can also use [period]) frames.
---@class DelayEvent:LoopEvent
---@field delayFrame number delay in frames
local DelayEvent=LoopEvent:extend()
function DelayEvent:new(args)
    args.times=1
    args.period=args.period or args.delayFrame or 60
    DelayEvent.super.new(self,args)
end

Event.DelayEvent=DelayEvent

Event.sineIOProgressFunc=function(x)return math.sin((x-0.5)*math.pi)*0.5+0.5 end
Event.sineOProgressFunc=function(x)return math.sin(x*math.pi/2) end
-- Event that changes [aimTable].[key] to [aimValue] in [easeFrame] frames. It can't modify plain variables. If [aimTable] is not provided, it defaults to [obj].
-- [progressFunc] can be used to make smooth start or stop. e.g. sin(x*pi/2)
-- [easeMode]='soft'|'hard'. 'soft' means [aimTable].[key] is added by d(progressFunc()) each frame and can be simultaneously changed by other sources, while 'hard' means the value is fixed by progressFunc.
-- when EaseEvent ends, call [afterFunc].
---@class EaseEvent:Event
local EaseEvent = Event:extend()
function EaseEvent:new(args)
    LoopEvent.super.new(self, args)
    self.time=0
    self.frame=0
    self.period=args.easeFrame or 60
    self.easeMode=args.easeMode=='hard' and 'hard' or'soft'
    self.aimTable=args.aimTable or args.obj or {}
    self.key=args.aimKey
    self.aimValue=args.aimValue or 0
    self.startValue=self.aimTable[self.key]
    -- can be used to make smooth start or stop. e.g. sin(x*pi/2)
    self.progressFunc=args.progressFunc or function(x)return x end
    self.lastProgress=self.progressFunc(0)
    self.conditionFunc=function(self,dt)
        return true
    end
    self.executeFunc=function(self,dt)
        -- print(self.frame,self.aimTable.frame,self.aimTable.x)
        if self.frame>self.period then
            self.frame=self.period
        end
        if not self.aimTable or self.aimTable.removed then
            return false
        end
        local newProgress=self.progressFunc(self.frame/self.period)
        local aimValue=type(self.aimValue)=="function" and self.aimValue() or self.aimValue
        if self.easeMode=='soft' then
            self.aimTable[self.key]=self.aimTable[self.key]+(newProgress-self.lastProgress)*(aimValue-self.startValue)
        else
            self.aimTable[self.key]=self.startValue+(newProgress)*(aimValue-self.startValue)
        end
        if self.frame==self.period then
            self.times=0
            self:afterFunc()
            self:remove()
        end
        self.lastProgress=newProgress
    end
    self.afterFunc=args.afterFunc or function(self)end
end
function EaseEvent:update(dt)
    -- self.time=self.time+dt
    EaseEvent.super.update(self,dt)
end

Event.EaseEvent=EaseEvent

return Event