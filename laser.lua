-- Laser is composed of many small units. For each 2 adjacent unit, use Mesh to draw Laser sprite quad between them. When a laser is generated, it has x, y, radius, lifeFrame, sprite, direction and speed parameters (same as circle). During lifeFrame time, it needs to generate units at a frequency of [freq] (could be determined based on speed). Each unit is a circle with speed=speed and direction=direction. Its lifeFrame should be enough to leave the screen.
local Laser=Object:extend()
local LaserUnit=Circle:extend()
Laser.LaserUnit=LaserUnit

function LaserUnit:new(args)
    LaserUnit.super.new(self, args)
    self.previous=nil
end

function LaserUnit:drawSprite()
    LaserUnit.super.drawSprite(self)
    if self.previous and not self.previous.removed then
        local x1,y1,r1=Shape.getCircle(self.x,self.y,self.radius)
        local x2,y2,r2=Shape.getCircle(self.previous.x,self.previous.y,self.previous.radius)
        local tangents=Laser.calculate_tangents_and_intersections(x1,y1,r1,x2,y2,r2)
    end
end

function Laser:new(args)
    Laser.super.new(self)
    self.lifeFrame=args.lifeFrame or 100
    args.lifeFrame=9999
    self.frame=0
    self.bulletEvents=args.bulletEvents or {}
    self.units={}
    self.frequency=math.ceil(100/args.speed)
    Event.LoopEvent{
        obj=self,
        period=self.frequency,
        executeFunc=function()
            args.direction=math.eval(args.direction)
            args.speed=math.eval(args.speed)
            local cir=LaserUnit(args)
            if #self.units>0 then
                cir.previous=self.units[#self.units]
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