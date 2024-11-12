-- Laser is composed of many small units. For each 2 adjacent unit, use Mesh to draw Laser sprite quad between them. When a laser is generated, it has x, y, radius, lifeFrame, sprite, direction and speed parameters (same as circle). During lifeFrame time, it needs to generate units at a frequency of [freq] (could be determined based on speed). Each unit is a circle with speed=speed and direction=direction. Its lifeFrame should be enough to leave the screen.
local Laser=Object:extend()
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
    if self.parent.enableWarningAndFading then
        if self.parent.frame<self.parent.warningFrame or self.parent.frame>self.parent.lifeFrame-self.parent.fadingFrame then
            self.safe=true
        else
            self.safe=false
        end
        self.radius=math.max(self.radiusRef*sigmoid(self.parent.frame-self.parent.warningFrame),0.1)*sigmoid(-self.parent.frame+self.parent.lifeFrame-self.parent.fadingFrame)
    end
end

function LaserUnit:drawSprite()
    -- LaserUnit.super.drawSprite(self)
    if not self.previous or self.previous.removed then
        self:drawMesh()
    end
end

function LaserUnit:draw()
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


function Laser:new(args)
    Laser.super.new(self)
    self.lifeFrame=args.lifeFrame or 100
    self.warningFrame=args.warningFrame or 0
    self.fadingFrame=args.fadingFrame or 0
    self.enableWarningAndFading=(args.warningFrame~=nil and args.warningFrame~=0 or args.fadingFrame~=nil and args.fadingFrame~=0)
    args.lifeFrame=9999
    args.batch=args.batch or Asset.bulletHighlightBatch
    self.frame=0
    self.bulletEvents=args.bulletEvents or {}
    self.units={}
    self.frequency=math.ceil(200/args.speed)
    Event.LoopEvent{
        obj=self,
        period=self.frequency,
        executeFunc=function()
            args.direction=math.eval(args.direction)
            args.speed=math.eval(args.speed)
            local cir=LaserUnit(args)
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
end

function Laser:update(dt)
    self.frame=self.frame+1
    if self.frame>self.lifeFrame then
        self:remove()
    end
end

return Laser