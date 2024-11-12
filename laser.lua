-- Laser is composed of many small units. For each 2 adjacent unit, use Mesh to draw Laser sprite quad between them. When a laser is generated, it has x, y, radius, lifeFrame, sprite, direction and speed parameters (same as circle). During lifeFrame time, it needs to generate units at a frequency of [freq] (could be determined based on speed). Each unit is a circle with speed=speed and direction=direction. Its lifeFrame should be enough to leave the screen.
local Laser=Object:extend()
local LaserUnit=Circle:extend()
Laser.LaserUnit=LaserUnit

function LaserUnit:new(args)
    LaserUnit.super.new(self, args)
    self.previous=nil
    self.next=nil
end

function LaserUnit:drawSprite()
    -- LaserUnit.super.drawSprite(self)
    if self.previous and not self.previous.removed then
        local x1,y1,r1=Shape.getCircle(self.x,self.y,self.radius)
        local x2,y2,r2=Shape.getCircle(self.previous.x,self.previous.y,self.previous.radius)
        local tangents=Laser.calculate_tangents_and_intersections(x1,y1,r1,x2,y2,r2)
    end
    if not self.previous or self.previous.removed then
        self:drawMesh()
    end
end

function LaserUnit:draw()
end

function LaserUnit:drawMesh()
    local laser=self.parent
    local vertices={}
    local x,y,w,h=self.sprite:getViewport() -- like 100, 100, 50, 50 so needs to divide width and height
    local W,H=Asset.bulletImage:getWidth(),Asset.bulletImage:getHeight()
    x,y,w,h=x/W,y/H,w/W,h/H
    local unit=self
    while unit and not unit.removed do
        local x1,y1,r1=Shape.getCircle(unit.x,unit.y,unit.radius)
        r1=SpriteData[self.sprite].size/2*r1/SpriteData[self.sprite].hitRadius
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

-- Function to calculate the tangent points and intersections
function Laser.calculate_tangents_and_intersections(x1, y1, r1, x2, y2, r2)
    local sqrt = math.sqrt
    local atan2 = math.atan2
    local cos = math.cos
    local sin = math.sin
    local asin = math.asin
    local d = math.distance(x1, y1, x2, y2)
    
    -- Check if circles are too close or intersecting
    if d <= math.abs(r1 - r2) then
        error("Circles are too close or intersecting; no outer tangents possible.")
    end

    -- Calculate distance between centers
    local dx = x2 - x1
    local dy = y2 - y1

    -- Calculate the angle offset for outer tangents
    local alpha = asin((r2 - r1) / d)+math.pi/2
    local theta = atan2(dy, dx)

    -- Calculate tangent points on Circle 1
    local x1_t1 = x1 + r1 * cos(theta + alpha)
    local y1_t1 = y1 + r1 * sin(theta + alpha)
    local x1_t2 = x1 + r1 * cos(theta - alpha)
    local y1_t2 = y1 + r1 * sin(theta - alpha)

    -- Calculate tangent points on Circle 2
    local x2_t1 = x2 + r2 * cos(theta + alpha)
    local y2_t1 = y2 + r2 * sin(theta + alpha)
    local x2_t2 = x2 + r2 * cos(theta - alpha)
    local y2_t2 = y2 + r2 * sin(theta - alpha)

    return {
        {x1_t1, y1_t1}, -- Tangent point 1 on Circle 1
        {x1_t2, y1_t2}, -- Tangent point 2 on Circle 1
        {x2_t1, y2_t1}, -- Tangent point 1 on Circle 2
        {x2_t2, y2_t2}  -- Tangent point 2 on Circle 2
    }
end

-- -- Example usage
-- local x1, y1, r1 = 0, 0, 5        -- Circle 1: center (0, 0) and radius 5
-- local x2, y2, r2 = 10, 0, 3       -- Circle 2: center (10, 0) and radius 3

-- local tangent_points = calculate_tangents_and_intersections(x1, y1, r1, x2, y2, r2)
-- for i, points in ipairs(tangent_points) do
--     print(string.format("Tangent %d: C1 (%f, %f), C2 (%f, %f)", i, points[1], points[2], points[3], points[4]))
-- end

return Laser