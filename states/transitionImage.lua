return {
    TRANSITION=true,
    enter=function(self,transitionArgs)
        transitionArgs.startFrame=self.frame
        transitionArgs.image=transitionArgs.image or Asset.backgroundImage
        transitionArgs.shader=transitionArgs.shader or love.graphics.newShader("shaders/transitionImage.glsl")
        transitionArgs.thershold=transitionArgs.thershold or 0.3
        self.currentUI.transitionArgs=transitionArgs
        self.currentUI.transitionFrame=0
        self.currentUI.complete=false
    end,
    update=function(self,dt)
        -- in this transition no need to consider interrupt because no state's update is called, so no new transition is possible.
        local args=self.currentUI.transitionArgs
        self.currentUI.transitionFrame=self.currentUI.transitionFrame+1
        if self.currentUI.transitionFrame*2>=args.transitionFrame and self.currentUI.transitionFrame*2-2<args.transitionFrame then -- half point, execute nextState:enter()
            local currentUI=self.currentUI
            self.currentUI=self.UIDEF[args.nextState]
            self.currentUI.enter(self,args.lastState)
            self.currentUI=currentUI
        end
        if self.currentUI.transitionFrame>=args.transitionFrame or self.currentUI.complete==true then 
            self.STATE=args.nextState
            self.currentUI=self.UIDEF[self.STATE]
            self.currentUI.complete=true
        end
    end,
    draw=function(self)
        local args=self.currentUI.transitionArgs
        local ratio=self.currentUI.transitionFrame/args.transitionFrame

        local currentUI=self.currentUI
        if ratio<0.5 then
            self.currentUI=self.UIDEF[args.lastState]
            self.currentUI.draw(self)
        else
            self.currentUI=self.UIDEF[args.nextState]
            self.currentUI.draw(self)
        end
        self.currentUI=currentUI
    end,
    drawText=function(self)
        local args=self.currentUI.transitionArgs
        local progress=0.0001+self.currentUI.transitionFrame/args.transitionFrame

        local currentUI=self.currentUI
        if progress<0.5 then
            self.currentUI=self.UIDEF[args.lastState]
            self.currentUI.drawText(self)
        else
            self.currentUI=self.UIDEF[args.nextState]
            self.currentUI.drawText(self)
        end
        self.currentUI=currentUI

        --[[ ratio -> new ratio and meaning:
        0 -> 0 beginning of transition, image shouldn't be visible
        thershold -> 1 the point when image is fully visible
        0.5 -> 1 half way, execute nextState:enter()
        1 - thershold -> 1 image is still fully visible
        1 -> 0 end of transition, image shouldn't be visible

        so that, for shader ratio = 0 to 1 directly means invisible to visible
        ]]
        progress=-math.abs(progress-0.5)*2+1
        progress=math.min(progress*0.5/(args.thershold),1)

        local image=args.image
        local shader=args.shader
        shader:send("progress",progress)
        love.graphics.setShader(shader)
        love.graphics.draw(image,0,0,0,1,1)
        love.graphics.setShader()
    end
}