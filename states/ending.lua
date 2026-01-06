local G=...
return {
    enter=function(self)
        self.backgroundPattern:remove()
        -- 12-9 final stage background
        self.backgroundPattern=BackgroundPattern.Stage{
            holeSize=4, -- same as 12-9 size (scene count 9 - 5)
            holeIsHorizon=true,
        }
        self.backgroundPattern.autoDark=false
        self.backgroundPattern.camMoveRange={1,1} -- larger movement range
        BGM:play('ending')
    end,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        if isPressed('x') or isPressed('escape') or isPressed('z')then
            SFX:play('select')
            self:switchState(self.STATES.MAIN_MENU)
        end
    end,
    draw=function(self)
    end,
    drawText=function(self)
        local color={love.graphics.getColor()}
        local xstart=350
        local width=450
        local ystart=30
        love.graphics.setColor(1,0.45,0.65,1) -- pink
        SetFont(48)
        love.graphics.printf(Localize{'ui','ending','congratulations'},xstart,ystart,width,'center')
        love.graphics.setColor(1,1,1,1)
        SetFont(24)
        love.graphics.printf(Localize{'ui','ending','epilogue'},xstart,ystart+70,width,'center')
        SetFont(36)
        love.graphics.printf(Localize{'ui','ending','thanksForPlaying'},xstart,ystart+400,width,'center')
        SetFont(24)
        love.graphics.printf(Localize{'ui','ending','yearAndAuthor'},xstart,ystart+470,width,'center')
        love.graphics.setColor(color[1],color[2],color[3],color[4])
    end
}