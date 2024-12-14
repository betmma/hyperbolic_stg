-- Laser is composed of many small units. For each 2 adjacent unit, use Mesh to draw Laser sprite quad between them. When a laser is generated, it has x, y, radius, lifeFrame, sprite, direction and speed parameters (same as circle). During lifeFrame time, it needs to generate units at a frequency of [freq] (be determined based on speed). Each unit is a circle with speed=speed and direction=direction. 
local Laser=Shape:extend()
local LaserUnit=Circle:extend()
Laser.LaserUnit=LaserUnit

function LaserUnit:new(args)
    LaserUnit.super.new(self, args)
    self.radiusRef=self.radius
    self.previous=nil
    self.next=nil
end
local function sigmoid(x)
    return 1/(1+2.718^-x)
end
function LaserUnit:update(dt)
    LaserUnit.super.update(self,dt)
    self:updateWarningAndFading(self.parent)
end

function LaserUnit:updateWarningAndFading(parent)
    if parent.enableWarningAndFading then
        if parent.frame<parent.warningFrame or parent.frame>parent.lifeFrame-parent.fadingFrame then
            self.safe=true
        else
            self.safe=false
        end
        self.radius=math.max(self.radiusRef*sigmoid(parent.frame-parent.warningFrame),0.1)*sigmoid(-parent.frame+parent.lifeFrame-parent.fadingFrame)
    end
end

function LaserUnit:drawSprite()
    -- LaserUnit.super.drawSprite(self)
end

function LaserUnit:draw()
    if not self.previous or self.previous.removed then
        self:drawMesh()
    end
end

function LaserUnit:drawMesh()
    local vertices={}
    local x,y,w,h=self.sprite:getViewport() -- like 100, 100, 50, 50 so needs to divide width and height
    local W,H=Asset.bulletImage:getWidth(),Asset.bulletImage:getHeight()
    x,y,w,h=x/W,y/H,w/W,h/H
    local unit=self
    while unit and not unit.removed do
        local x1,y1,r1=Shape.getCircle(unit.x,unit.y,unit.radius)
        r1=SpriteData[self.sprite].size/2*r1/SpriteData[self.sprite].hitRadius
        -- if unit==self then
        --     r1=r1/2
        -- end
        local the=unit.direction+math.pi/2
        table.insert(vertices,{x1+r1*math.cos(the),y1+r1*math.sin(the), x, y, 1, 1, 1, 1})
        table.insert(vertices,{x1-r1*math.cos(the),y1-r1*math.sin(the), x+w, y+h, 1, 1, 1, 1})
        unit=unit.next
    end
    if #vertices<4 then return end
    local mesh=love.graphics.newMesh(vertices,'strip')
    mesh:setTexture(Asset.bulletImage)
    table.insert(Asset.laserBatch,mesh)
    -- love.graphics.draw(mesh)
end

-- use the line segment between self and self.previous to check if player is hit by laser. Circle check can cause safe spot inside laser.
function LaserUnit:checkHitPlayer()
    if not self.safe and self.previous and not self.previous.removed then
        local x1,y1,x2,y2=self.x,self.y,self.previous.x,self.previous.y
        local grazeFunction,hitFunction
        if math.abs(x1-x2)<Shape.EPS then --vertical
            grazeFunction=function(player)
                local x,y=player.x,player.y
                return math.abs(x-x1)<self.radius+player.radius*player.grazeRadiusFactor and (y1<=y and y<=y2 or y2<=y and y<=y1)
            end
            hitFunction=function(player)
                local x,y=player.x,player.y
                return math.abs(x-x1)<self.radius+player.radius and (y1<=y and y<=y2 or y2<=y and y<=y1)
            end
        else
            grazeFunction=function(player)
                local x,y=player.x,player.y
                return Shape.distanceToSegment(x,y,x1,y1,x2,y2)<self.radius+player.radius*player.grazeRadiusFactor
            end
            hitFunction=function(player)
                local x,y=player.x,player.y
                return Shape.distanceToSegment(x,y,x1,y1,x2,y2)<self.radius+player.radius
            end
        end
        for key, player in pairs(Player.objects) do
            if grazeFunction(player) and not self.grazed then
                player:grazeEffect()
                self.grazed=true
            end
            if player.invincibleTime<=0 and hitFunction(player) then
                player:dieEffect()
            end
        end
    end
end

-- Note that warningFrame and fadingFrame is binded to Laser object's existence and lifeFrame, so for fast lasers these two parameters could be used, while for slow (usually curly and not long enough to go through screen) lasers shouldn't be set to nonzero, otherwise before actual laser reaches player it's warningFrame ends, and soon the Laser object is removed and actual laser will fade out.
-- Laser is actually a special bulletSpawner but it doesn't inherit bulletSpawner class yet (maybe I'll change). When creating its args are like normal bullets so args.direction and speed are actually for LaserUnits, so directly inheriting bulletSpawner (or shape) will cause it to move. [LaserEvents] are Laser object's events, while [bulletEvents] are LaserUnit's events.
-- To prevent unintended safe spot inside the laser, when enableWarningAndFading is true the speed of LaserUnits is added 1% of randomness. (this is before I added line segment check for player hit, so now it's not needed, but to not break replays I keep it)
function Laser:new(args)
    Laser.super.new(self,args)
    self.radius=args.radius or 5
    self.args=copy_table(args)
    self.lifeFrame=args.lifeFrame or 100
    self.warningFrame=args.warningFrame or 0
    self.fadingFrame=args.fadingFrame or 0
    self.enableWarningAndFading=(args.warningFrame~=nil and args.warningFrame~=0 or args.fadingFrame~=nil and args.fadingFrame~=0)
    args.lifeFrame=9999
    args.batch=args.batch or Asset.bulletHighlightBatch
    self.frame=0
    self.laserEvents=args.laserEvents or {}
    self.bulletEvents=args.bulletEvents or {}
    self.units={}
    self.frequency=args.frequency or math.ceil(200/args.speed)
    self.spawnEvent=Event.LoopEvent{
        obj=self,
        period=self.frequency,
        executeFunc=function()
            args.direction=math.eval(self.args.direction)
            args.speed=math.eval(self.args.speed)
            if self.enableWarningAndFading then
                args.speed=args.speed*math.eval('1+0.01')
            end
            local cir=LaserUnit(args)
            cir.index=self.spawnEvent.executedTimes
            cir:updateWarningAndFading(self)
            cir.last=true
            cir.parent=self
            if #self.units>0 then
                cir.previous=self.units[#self.units]
                self.units[#self.units].next=cir
                cir.previous.last=false
            end
            table.insert(self.units,cir)
            -- table.insert(ret,cir)
            for key, func in pairs(self.bulletEvents) do
                func(cir,args)
            end
        end
    }
    for key, func in pairs(self.laserEvents) do
        func(self,args)
    end
end

function Laser:update(dt)
    self.frame=self.frame+1
    if self.frame>self.lifeFrame then
        self:remove()
    end
    for k,shockwave in pairs(Effect.Shockwave.objects) do
        if shockwave.canRemove.bulletSpawner and Shape.distance(shockwave.x,shockwave.y,self.x,self.y)<shockwave.radius+self.radius then
            self:remove()
        end
    end
end

return Laser