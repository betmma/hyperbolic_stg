--! file: shape.lua
local Shape = Object:extend()
Shape.curvature=100
Shape.axisY=-100
function Shape.distance(x1,y1,x2,y2)
    local ay=Shape.axisY
    return 2*Shape.curvature*math.log((math.distance(x1,y1,x2,y2)+math.distance(x1,y1,x2,2*ay-y2))/(2*((y1-ay)*(y2-ay))^0.5))
end

-- get X coordinate and radius of center point of line x1,y1 to x2,y2
function Shape.lineCenter(x1,y1,x2,y2)
    local x0=(x1+x2)/2
    local y0=(y1+y2)/2
    if x1==x2 then -- vertical 
        return 0,tonumber('inf')
    end
    local k=(y2-y1)/(x2-x1)
    local centerX=x0+(y0-Shape.axisY)*k
    return centerX,math.distance(centerX,Shape.axisY,x1,y1)
end

-- get direction from x1,y1 to x2,y2
function Shape.to(x1,y1,x2,y2)
    if x1==x2 then -- vertical 
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

-- calculate if a point xc,yc is left to line x1,y1 to x2,y2 (in/out the semicircle if angle p1 to p2 is negative/positive // left to a vertical line)
function Shape.leftToLine(xc,yc,x1,y1,x2,y2)
    if x1==x2 then -- vertical
        if y2<y1 then
            return xc<x1
        end
        return xc>x1
    end
    local centerX,radius=Shape.lineCenter(x1,y1,x2,y2)
    local theta1=math.atan2(y1-Shape.axisY,x1-centerX)
    local theta2=math.atan2(y2-Shape.axisY,x2-centerX)
    if theta1>theta2 then
        return math.distance(centerX,Shape.axisY,xc,yc)<radius
    end 
    return math.distance(centerX,Shape.axisY,xc,yc)>radius
end

-- find the nearest point to xc,yc on line [x1,y1 to x2,y2] 
function Shape.nearestToLine(xc,yc,x1,y1,x2,y2)
    if x1==x2 then -- vertical
        return {x1,yc}
    end
    local centerX,radius=Shape.lineCenter(x1,y1,x2,y2)
    local direction=math.atan2(yc-Shape.axisY,xc-centerX)
    return {centerX+radius*math.cos(direction),Shape.axisY+radius*math.sin(direction)}
end

function Shape.drawCircle(x,y,r)
    x,y,r=Shape.getCircle(x,y,r)
    love.graphics.circle("line", x,y,r)
    return x,y,r
end

function Shape.getCircle(x,y,r)
    return x, (y-Shape.axisY)*math.cosh(r/Shape.curvature)+Shape.axisY, (y-Shape.axisY)*math.sinh(r/Shape.curvature)
end

-- find the point that is (r,theta) to x,y in polar coordinates
function Shape.rThetaPos(x,y,r,theta)
    local div=math.floor(theta/(math.pi*2))
    theta=theta%(math.pi*2)
    local x2,y2,r2=Shape.getCircle(x,y,r)
    if theta%math.pi==math.pi/2 then --vertical
        if theta>math.pi then
            return x2,y2-r,theta+div*math.pi*2
        end
        return x2,y2+r,theta+div*math.pi*2
    end
    local xc=Shape.lineCenter(x,y,x+math.cos(theta),y+math.sin(theta))
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
    return x2+r*math.cos(finaltheta),y2+r*math.sin(finaltheta),finaltheta+div*math.pi*2
end


function Shape:new(args)
    self.x = args.x
    self.y = args.y
    self.metric=self:getMetric()
    self.speed = args.speed or 0
    self.direction = args.direction or math.pi*2/9
    self.lifeTime=args.lifeTime or 10
    self.time=0
    self.removeDistance=100
end

function Shape:getMetric()
    return (self.y-Shape.axisY)/Shape.curvature
end

function Shape:getMoveRadius()
    return (self.y-Shape.axisY)/math.cos(self.direction)
end

function Shape:update(dt)
    self.time=self.time+dt
    if self.time>self.lifeTime then
        self:remove()
    end
    if self.x<-self.removeDistance or self.x>self.removeDistance+love.graphics.getWidth() or math.abs(self.y-Shape.axisY)<5 or self.y<-self.removeDistance or self.y>self.removeDistance+love.graphics.getHeight() then
        self:remove()
    end
    self.metric=self:getMetric()
    self.moveRadius=self:getMoveRadius()
    local moveDistance=self.speed* dt * self.metric
    self.x = self.x +  moveDistance * math.cos(self.direction) 
    self.y=self.y+moveDistance * math.sin(self.direction) 
    self.direction=self.direction-moveDistance/self.moveRadius
end

function Shape:drawAll()
    love.graphics.line(0,Shape.axisY,love.graphics.getWidth(),Shape.axisY) -- draw the axis
    for key, obj in pairs(self.objects) do
        obj:draw()
    end
end
function Shape:updateAll(dt)
    -- Shape.axisY=Shape.axisY+dt*10
    for key, obj in pairs(self.objects) do
        obj:update(dt)
    end
end

return Shape