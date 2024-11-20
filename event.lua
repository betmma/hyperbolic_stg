
local Event = Object:extend()
Event.modes={
    oneFrameOnce=0,
    oneFrameMultiple=1
}
Event.Event=Event -- for convenience as without it LoopEvent and EaseEvent need "Event." but base Event don't

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
    self.executeFunc=args.executeFunc or function(self,dt)return true end
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
            self:executeFunc(dt)
            self.executedTimes=self.executedTimes+1
        end
        if self.executedTimes>self.times or self.obj.removed then
            -- print(self.frame,self.obj.frame)
            self:remove()
            return
        end
    end
    -- self.time=self.time+dt
end

-- Event that checks condition for every [period] frames. Initially the time is set to [time]. (so if time==period it triggers upon creation)
-- conditionFunc, executeFunc, times, mode:Event.modes, time, period
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
local DelayEvent=LoopEvent:extend()
function DelayEvent:new(args)
    args.times=1
    args.period=args.period or args.delayFrame or 60
    DelayEvent.super.new(self,args)
end

Event.DelayEvent=DelayEvent

-- Event that changes [aimTable].[key] to [aimValue] in [easeFrame] frames.
-- [progressFunc] can be used to make smooth start or stop. e.g. sin(x*pi/2)
-- maybe make more default progressFuncs. I remember such functions in Unity.
-- when EaseEvent ends, call [endFunc].
local EaseEvent = Event:extend()
function EaseEvent:new(args)
    LoopEvent.super.new(self, args)
    self.time=0
    self.frame=0
    self.period=args.easeFrame or 60
    self.aimTable=args.aimTable or {}
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
        self.aimTable[self.key]=self.aimTable[self.key]+(newProgress-self.lastProgress)*(self.aimValue-self.startValue)
        if self.frame==self.period then
            self.times=0
            self:endFunc()
            self:remove()
        end
        self.lastProgress=newProgress
    end
    self.endFunc=args.endFunc or function(self)end
end
function EaseEvent:update(dt)
    -- self.time=self.time+dt
    EaseEvent.super.update(self,dt)
end

Event.EaseEvent=EaseEvent

return Event