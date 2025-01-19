--! file: shape.lua
local Shape = Object:extend()
Shape.curvature=100
Shape.removeDistance=100
Shape.timeSpeed=1
Shape.axisY=-100
local EPS=1e-8
Shape.EPS=EPS
function Shape.restore()
    Shape.curvature=100
    Shape.axisY=-100
    Shape.removeDistance=100
end

-- hyperbolic distance
function Shape.distance(x1,y1,x2,y2)
    local ay=Shape.axisY
    return 2*Shape.curvature*math.log((math.distance(x1,y1,x2,y2)+math.distance(x1,y1,x2,2*ay-y2))/(2*((y1-ay)*(y2-ay))^0.5))
end

-- get X coordinate and radius of center point of line x1,y1 to x2,y2
---@return number 'X coordinate of center point'
---@return number '(Euclidean) radius of line'
function Shape.lineCenter(x1,y1,x2,y2)
    local x0=(x1+x2)/2
    local y0=(y1+y2)/2
    if x1==x2 then -- vertical 
        return 0,1e308
    end
    local k=(y2-y1)/(x2-x1)
    local centerX=x0+(y0-Shape.axisY)*k
    return centerX,math.distance(centerX,Shape.axisY,x1,y1)
end

-- get Y coordinate of intersection point of line x=xc and line x1,y1 to x2,y2
-- that is, treat line as a function and get f(xc)
function Shape.lineX2Y(x1,y1,x2,y2,xc)
    local centerX,dis=Shape.lineCenter(x1,y1,x2,y2)
    if math.abs(xc-centerX)>dis then
        return 0 -- intersection point doesn't exist
    end
    return Shape.axisY+dis*math.cos(math.asin((xc-centerX)/dis))
end

-- actually this function is never used (^^;
function Shape.drawLine(x1,y1,x2,y2)
    if math.abs(x1-x2)<EPS then -- vertical -> line
        love.graphics.line(x1,y1,x2,y2)
        return
    end
    local centerX=Shape.lineCenter(x1,y1,x2,y2)
    love.graphics.circle("line", centerX,Shape.axisY,((centerX-x1)^2+(y1-Shape.axisY)^2)^0.5)
end

-- get direction from x1,y1 to x2,y2 (at x1,y1)
---@return number 'direction in [-pi/2,3pi/2]'
function Shape.to(x1,y1,x2,y2)
    if math.abs(x1-x2)<EPS then -- vertical 
        return y1<y2 and math.pi/2 or -math.pi/2
    end
    local centerX=Shape.lineCenter(x1,y1,x2,y2)
    local theta1=math.atan2(y1-Shape.axisY,x1-centerX)
    local theta2=math.atan2(y2-Shape.axisY,x2-centerX)
    if theta1<theta2 then
        return theta1+math.pi/2
    end
    return theta1-math.pi/2
end

-- calculate the SIGNED ON-SCREEN distance a point xc,yc to line [x1,y1 to x2,y2] (positive when in/out the semicircle if angle p1 to p2 is negative/positive // left to a vertical line)
function Shape.onscreenDistanceToLineSigned(xc,yc,x1,y1,x2,y2)
    if math.abs(x1-x2)<EPS then -- vertical
        if y2<y1 then -- the line goes upward
            return x1-xc
        end
        return xc-x1
    end
    local centerX,radius=Shape.lineCenter(x1,y1,x2,y2)
    local theta1=math.atan2(y1-Shape.axisY,x1-centerX)
    local theta2=math.atan2(y2-Shape.axisY,x2-centerX)
    if theta1>theta2 then
        return radius-math.distance(centerX,Shape.axisY,xc,yc)
    end 
    return math.distance(centerX,Shape.axisY,xc,yc)-radius
end

-- calculate if a point xc,yc is left to line [x1,y1 to x2,y2]. Uses distanceToLineSigned.
function Shape.leftToLine(xc,yc,x1,y1,x2,y2)
    return Shape.onscreenDistanceToLineSigned(xc,yc,x1,y1,x2,y2)>0
end

function Shape.onscreenDistanceToLine(xc,yc,x1,y1,x2,y2)
    return math.abs(Shape.onscreenDistanceToLineSigned(xc,yc,x1,y1,x2,y2))
end

-- used to calculate segment hitbox
function Shape.distanceToSegment(xc,yc,x1,y1,x2,y2)
    if math.abs(x1-x2)<EPS then -- vertical
        -- make a perpendicular (hyperbolic) line from (xc,yc) to x=xc, intersects at (xc,yd)
        local yd=math.distance(xc,yc,x1,Shape.axisY)
        if y2<yd and y1<yd or y2>yd and y1>yd then 
            return math.min(Shape.distance(x1,y1,xc,yc),Shape.distance(x2,y2,xc,yc))
        end
        return Shape.distance(x1,yd,xc,yc) -- the perpendicular line intersects the segment
    end
    local centerX,radius=Shape.lineCenter(x1,y1,x2,y2)
    local theta1=math.atan2(y1-Shape.axisY,x1-centerX)
    local theta2=math.atan2(y2-Shape.axisY,x2-centerX)
    local thetac=math.atan2(yc-Shape.axisY,xc-centerX)
    if theta1>thetac and theta2>thetac or theta1<thetac and theta2<thetac then
        return math.min(Shape.distance(x1,y1,xc,yc),Shape.distance(x2,y2,xc,yc))
    end 
    return Shape.distance(centerX+radius*math.cos(thetac),Shape.axisY+radius*math.sin(thetac),xc,yc) -- this is INCORRECT, just an approximation when distance is small (used in lazer segment hitbox check)
end

-- find the nearest point to xc,yc on line [x1,y1 to x2,y2] 
---@return table "{x,y}"
function Shape.nearestToLine(xc,yc,x1,y1,x2,y2)
    if math.abs(x1-x2)<EPS then -- vertical
        return {x1,yc}
    end
    local centerX,radius=Shape.lineCenter(x1,y1,x2,y2)
    local direction=math.atan2(yc-Shape.axisY,xc-centerX)
    return {centerX+radius*math.cos(direction),Shape.axisY+radius*math.sin(direction)}
end

function Shape.drawSegment(x1,y1,x2,y2,segNum)
    if math.abs(x1-x2)<EPS then -- vertical -> line
        love.graphics.line(x1,y1,x2,y2)
        return
    end
    local centerX,r=Shape.lineCenter(x1,y1,x2,y2)
    local theta1=math.atan2(y1-Shape.axisY,x1-centerX)
    local theta2=math.atan2(y2-Shape.axisY,x2-centerX)
    math.drawArc(centerX,Shape.axisY,r,theta1,theta2,segNum or 50)
end

-- draw hyperbolic arc.
---@param x number 'x of arc center'
---@param y number 'y of arc center'
---@param r any 'arc radius'
---@param s_ang any 'arc start angle'
---@param e_ang any 'arc end angle'
---@param numLines any 'how many lines are used'
function Shape.drawArc(x, y, r, s_ang, e_ang, numLines)
    local x2,y2,r2=Shape.getCircle(x,y,r)
    _,_,s_ang=Shape.rThetaPos(x,y,r,s_ang)
    _,_,e_ang=Shape.rThetaPos(x,y,r,e_ang)
	math.drawArc(x2,y2,r2,s_ang,e_ang,numLines)
end

-- draw hyperbolic circle with center (x,y) and radius r. using Shape.getCircle
function Shape.drawCircle(x,y,r,mode)
    x,y,r=Shape.getCircle(x,y,r)
    love.graphics.circle(mode or "line", x,y,r)
    return x,y,r
end

-- find the Euclidean x', y' and r' of hyperbolic circle with center (x,y) and radius r.
function Shape.getCircle(x,y,r)
    return x, (y-Shape.axisY)*math.cosh(r/Shape.curvature)+Shape.axisY, (y-Shape.axisY)*math.sinh(r/Shape.curvature)
end


-- find the point that is (r,theta) to x,y in polar coordinates
-- also means "from (x,y), aim at theta direction and go r unit forward, which point will you arrive"
---@param x number
---@param y number
---@param r number
---@param theta number
---@return number "x of new point"
---@return number "y of new point"
---@return number "Euclidean polar angle"
function Shape.rThetaPos(x,y,r,theta)
    if r==0 then
        return x,y,theta
    end
    local div=math.floor(theta/(math.pi*2))
    theta=theta%(math.pi*2)
    local x2,y2,r2=Shape.getCircle(x,y,r)
    if theta%math.pi==math.pi/2 then --vertical
        if theta>math.pi then
            return x2,y2-r2,theta+div*math.pi*2
        end
        return x2,y2+r2,theta+div*math.pi*2
    end
    local xc=x+math.tan(theta)*(y-Shape.axisY)
    local rr=math.distance(xc,Shape.axisY,x2,y2)
    local ra=math.distance(xc,Shape.axisY,x,y)
    -- 3 sides of the triangle are rr, ra and r2
    local cosalpha=(rr*rr+r2*r2-ra*ra)/(2*rr*r2)
    local alpha=math.acos(cosalpha)
    local thetaCenter=math.atan2(Shape.axisY-y2,xc-x2)

    local t1=thetaCenter+alpha
    t1=t1%(math.pi*2)
    local t2=thetaCenter-alpha
    t2=t2%(math.pi*2)
    -- two circles have two intersect points. we know that hyperbolic point and euclid point of (r,theta) in such case must be at the same left/right side, so find the point within same side.
    if math.pi/2<t1 and t1<math.pi/2*3 then 
        t1,t2=t2,t1
    end
    local finaltheta=t1
    if math.pi/2<theta and theta<math.pi/2*3 then
        finaltheta=t2
    end
    -- div is to restore the 2pi information lost when calculating trigonometric functions. however there is a case where new theta (final theta) and original theta not in same 2pi div. this is when original theta is barely over 0 and new theta is smaller than 0 (also, smaller than 2pi). so deduct 1 div in such case
    if finaltheta>math.pi*3/2 and theta<math.pi/2 then 
        div=div-1
    end
    return x2+r2*math.cos(finaltheta),y2+r2*math.sin(finaltheta),finaltheta+div*math.pi*2
end


function Shape:new(args)
    self.args=args
    self.x = args.x
    self.y = args.y
    self.metric=self:getMetric()
    self.speed = args.speed or 0
    self.direction = args.direction or math.pi*2/9
    self.lifeFrame=args.lifeFrame or 1000
    self.time=0
    self.frame=0
    self.removeDistance=args.removeDistance or Shape.removeDistance
end

function Shape:getMetric()
    return (self.y-Shape.axisY)/Shape.curvature
end

function Shape:getMoveRadius()
    return (self.y-Shape.axisY)/math.cos(self.direction)
end

function Shape:update(dt)
    self.time=self.time+dt
    self.frame=self.frame+1
    if self.frame>self.lifeFrame then
        self:remove()
    end
    if self.x<-self.removeDistance+150 or self.x>self.removeDistance+love.graphics.getWidth()-150 or math.abs(self.y-Shape.axisY)<50/math.log(self.removeDistance,10) or self.y<-self.removeDistance or self.y>self.removeDistance+love.graphics.getHeight() then
        self:remove()
    end
    self:updateMove(dt)
end

function Shape:updateMove(dt)
    self.metric=self:getMetric()
    self.moveRadius=self:getMoveRadius()
    local moveDistance=self.speed* dt * Shape.timeSpeed * self.metric
    self.x = self.x +  moveDistance * math.cos(self.direction) 
    self.y=self.y+moveDistance * math.sin(self.direction) 
    self.direction=self.direction-moveDistance/self.moveRadius
end

function Shape:drawAll()
    love.graphics.line(0,Shape.axisY,love.graphics.getWidth(),Shape.axisY) -- draw the axis
    for key, obj in pairs(self.objects) do
      if not obj.removed then
        obj:draw()
      end
    end
    for key, cls in pairs(self.subclasses) do
        cls:drawAll()
    end
end
-- function Shape:updateAll(dt)
--     -- Shape.axisY=Shape.axisY+dt*10
--     for key, obj in pairs(self.objects) do
--         obj:update(dt)
--     end
-- end

return Shape