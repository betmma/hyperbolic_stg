
local Event = Object:extend()
Event.modes={
    oneFrameOnce=0,
    oneFrameMultiple=1
}
--conditionFunc,executeFunc,times,mode:Event.modes
function Event:new(args)
    -- self.time=0
    self.times=args.times or 999999999999
    self.mode=args.mode or Event.modes.oneFrameOnce
    self.executedTimes=0
    self.conditionFunc=args.conditionFunc or function(self,dt)return true end
    self.executeFunc=args.executeFunc or function(self,dt)end
end

function Event:update(dt)
    local first=true
    while first==true or self.mode==Event.modes.oneFrameMultiple do
        first=false
        if self:conditionFunc(dt) and self.executedTimes<self.times then
            self:executeFunc(dt)
            self.executedTimes=self.executedTimes+1
        end
        if self.executedTimes>self.times then
            self:remove()
            return
        end
    end
    -- self.time=self.time+dt
end

--conditionFunc, executeFunc, times, mode:Event.modes
local LoopEvent = Event:extend()
function LoopEvent:new(args)
    LoopEvent.super.new(self, args)
    self.conditionFuncRef=self.conditionFunc
    self.time=args.time or 0
    self.period=args.period or 1
    self.conditionFunc=function(self,dt)
        if self.time>self.period then
            self.time=self.time-self.period
            return self.conditionFuncRef(self,dt)
        end
    end
end

function LoopEvent:update(dt)
    self.time=self.time+dt
    LoopEvent.super.update(self,dt)
end
Event.LoopEvent=LoopEvent

-- easeTime, aimTable, aimKey, aimValue, progressFunc
local EaseEvent = Event:extend()
function EaseEvent:new(args)
    LoopEvent.super.new(self, args)
    self.time=0
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
        self.aimTable[self.key]=self.progressFunc(self.time/self.period)*(self.aimValue-self.startValue)+self.startValue
        if self.time==self.period then
            self.times=0
        end
    end
end
function EaseEvent:update(dt)
    self.time=self.time+dt
    EaseEvent.super.update(self,dt)
end

Event.EaseEvent=EaseEvent

return Event