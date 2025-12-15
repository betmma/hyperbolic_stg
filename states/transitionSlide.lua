return {
    TRANSITION=true,
    enter=function(self,transitionArgs)
        transitionArgs.startFrame=self.frame
        self.currentUI.transitionArgs=transitionArgs
        self.currentUI.transitionFrame=0
        self.currentUI.complete=false
            transitionArgs.aimDxy={DirectionName2Dxy(transitionArgs.slideDirection)}
            transitionArgs.aimDxy={transitionArgs.aimDxy[1]*WINDOW_WIDTH,transitionArgs.aimDxy[2]*WINDOW_HEIGHT}
            -- transitionArgs.length={WINDOW_WIDTH,WINDOW_HEIGHT}
            transitionArgs.currentDxy={0,0}
        local currentUI=self.currentUI
        self.currentUI=self.UIDEF[transitionArgs.nextState]
        self.currentUI.enter(self,transitionArgs.lastState)
        self.currentUI=currentUI
    end,
    update=function(self,dt)
        local args=self.currentUI.transitionArgs
        self.currentUI.transitionFrame=self.currentUI.transitionFrame+1
        if self.currentUI.transitionFrame>=args.transitionFrame or self.currentUI.complete==true then
            -- doesn't call switchState directly, because switchState will call nextState:enter, which has been called in TRANSITION:enter.
            self.STATE=args.nextState
            self.currentUI=self.UIDEF[self.STATE]
            self.currentUI.complete=true
            return
        end
        local ratio=args.slideRatio
        for i=1,2 do
            args.currentDxy[i]=args.currentDxy[i]*(1-ratio)+args.aimDxy[i]*ratio
        end
        local currentUI=self.currentUI
        self.STATE=args.nextState
        self.currentUI=self.UIDEF[args.nextState]
        self.currentUI.update(self,dt)
        if self.STATE~=args.nextState then
            --[[explain the condition: if the state is changed in the update function, there are 2 possibilities.
            1. it's changed without a new transition (means it's abrupt), then stop current transition by setting complete to true.
            2. it's changed with a new transition, then no need to stop current transition, because the new transition has overwritten the current one. If do so, the new transition will be stopped immediately and stuck.]]
            return
        end
        self.currentUI=currentUI
        self.STATE=self.STATES.TRANSITION_SLIDE
    end,
    draw=function(self)
        local args=self.currentUI.transitionArgs
            local currentUI=self.currentUI
            local currentDxy=args.currentDxy
            love.graphics.translate(currentDxy[1],currentDxy[2])
            self.currentUI=self.UIDEF[args.lastState]
            self.currentUI.draw(self)
            love.graphics.translate(-args.aimDxy[1],-args.aimDxy[2])
            self.currentUI=self.UIDEF[args.nextState]
            self.currentUI.draw(self)
            love.graphics.translate(args.aimDxy[1]-currentDxy[1],args.aimDxy[2]-currentDxy[2])
            self.currentUI=currentUI
    end,
    drawText=function(self)
        local args=self.currentUI.transitionArgs
            local currentUI=self.currentUI
            local currentDxy=args.currentDxy
            love.graphics.translate(currentDxy[1],currentDxy[2])
            self.currentUI=self.UIDEF[args.lastState]
            self.currentUI.drawText(self)
            love.graphics.translate(-args.aimDxy[1],-args.aimDxy[2])
            self.currentUI=self.UIDEF[args.nextState]
            self.currentUI.drawText(self)
            love.graphics.translate(args.aimDxy[1]-currentDxy[1],args.aimDxy[2]-currentDxy[2])
            self.currentUI=currentUI
    end
}