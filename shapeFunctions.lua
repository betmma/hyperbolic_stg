-- helper functions for hyperbolic geometry

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
    if math.abs(x1-x2)<Shape.EPS then -- vertical -> line
        love.graphics.line(x1,y1,x2,y2)
        return
    end
    local centerX=Shape.lineCenter(x1,y1,x2,y2)
    love.graphics.circle("line", centerX,Shape.axisY,((centerX-x1)^2+(y1-Shape.axisY)^2)^0.5)
end

-- get direction from x1,y1 to x2,y2 (at x1,y1)
---@return number 'direction in [-pi/2,3pi/2]'
function Shape.to(x1,y1,x2,y2)
    if math.abs(x1-x2)<Shape.EPS then -- vertical 
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
    if math.abs(x1-x2)<Shape.EPS then -- vertical
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

-- used to calculate segment hitbox (note it's approx.)
function Shape.distanceToSegment(xc,yc,x1,y1,x2,y2)
    if math.abs(x1-x2)<Shape.EPS then -- vertical
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
    if math.abs(x1-x2)<Shape.EPS then -- vertical
        return {x1,yc}
    end
    local centerX,radius=Shape.lineCenter(x1,y1,x2,y2)
    --[[ let the semicircle from xc,yc to the foot of the perpendicular line intersecting the semicircle of (centerX,radius) be (centerX2, radius2), then radius2 is radius*tan(direction) (this can be negative, but we only use squared value below so doesn't matter), centerX2 is centerX+radius/cos(direction), xc,yc is on it, so (xc-centerX2)^2+(yc-Shape.axisY)^2=radius2^2, which is:
    (xc-centerX-radius/cos(direction))^2+(yc-Shape.axisY)^2=radius^2*tan(direction)^2
    let xc-centerX=a, (yc-Shape.axisY)^2=b, radius=R, then we have:
    (a-R/cos(direction))^2+b=R^2*tan(direction)^2
    expand, we get:
    a^2-2aR/cos(direction)+R^2/cos(direction)^2+b=R^2*tan(direction)^2
    a^2-2aR/cos(direction)+R^2/cos(direction)^2+b=R^2*(1/cos(direction)^2-1)
    multiplying cos(direction)^2 and let cos(direction)=x, we get:
    (a^2+b)x^2-2aRx+R^2=R^2-R^2x^2
    (a^2+b+R^2)x^2-2aRx=0
    x=(2aR)/(a^2+b+R^2) (discard x=0 solution)
    ]]
    local a=xc-centerX
    local b=(yc-Shape.axisY)^2
    local R=radius
    local x=(2*a*R)/(a^2+b+R^2)
    -- direction is limited in (0,pi) so sin(direction) is positive

    return {centerX+radius*x,Shape.axisY+radius*math.sqrt(1-x^2)}
end

--- reflect a point xc,yc by line [x1,y1 to x2,y2]. when drawing flipped object, besides using this function to calculate the new position, also need to horizontally flip the object.
---@param xs number
---@param ys number
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number "x of reflected point"
---@return number "y of reflected point"
---@return number "delta orientation from reflection"
function Shape.reflectByLine(xs,ys,x1,y1,x2,y2)
    local nearest=Shape.nearestToLine(xs,ys,x1,y1,x2,y2)
    local x3,y3=nearest[1],nearest[2]
    local x3toself=Shape.to(x3,y3,xs,ys)
    local selftox3=Shape.to(xs,ys,x3,y3)
    local distance=Shape.distance(xs,ys,x3,y3)
    if distance<Shape.EPS then
        local tangentAngle=Shape.to(xs,ys,x1,y1)
        return xs,ys,tangentAngle*2+math.pi
    end
    local xReflection,yReflection=Shape.rThetaPos(x3,y3,distance,x3toself+math.pi)
    --[[this is complex, lemme explain:
       (xs,ys)\______(x3,y3)______/(xRe,yRe)     (Re is Reflection)
        ↘selftox3  ←x3toself     ↙xRetox3
    let the orientation of player be 0.
    first calculate the orientation, when moving player from (xs,ys) to (x3,y3) along the straight line. The difference of orientation is x3toself-selftox3+pi. so the result, calling it ori1, is x3toself-selftox3+pi.
    then calculate the reflection. after reflection, the orientation is 2*tangent direction at (x3,y3)-ori1+pi (a little tricky for this pi. it's from how we implement flip. horizontal flip adds 2*flip axis angle that is pi. if use vertical flip there won't be pi). we know that x3toself is perpendicular to tangent, so the result after reflection, calling it ori2, is 2*(x3toself+pi/2)-ori1+pi=x3toself+selftox3+pi.
    finally move the reflection to (xRe,yRe). difference is xRetox3-x3toself. so the result, calling it ori3, is xRetox3-x3toself+ori2=xRetox3+selftox3+pi.
    for the initial orientation, it's easy to know the reflection rotates in the opposite direction, so minus initial orientation.
    ]]
    local deltaOrientation=Shape.to(xReflection,yReflection,xs,ys)+Shape.to(xs,ys,x3,y3)+math.pi
    return xReflection,yReflection,deltaOrientation
end

-- move [movingObj] towards [aimObj] with [step] distance. if [stopAtReach] is true, won't go past [aimObj] if [step] is larger than distance between them. This function directly modifies [movingObj]'s x and y.
--- @param movingObj table "object to be moved, has x and y attributes"
--- @param aimObj table "object to be aimed at"
--- @param step number "step distance"
--- @param stopAtReach boolean "if true, won't go past [aimObj] if [step] is larger than distance between them"
function Shape.moveTowards(movingObj,aimObj,step,stopAtReach)
    local angle=Shape.to(movingObj.x,movingObj.y,aimObj.x,aimObj.y)
    if stopAtReach then
        local distance=Shape.distance(movingObj.x,movingObj.y,aimObj.x,aimObj.y)
        step=math.min(step,distance)
    end
    local x,y=Shape.rThetaPos(movingObj.x,movingObj.y,step,angle)
    movingObj.x=x
    movingObj.y=y
end

function Shape.drawSegment(x1,y1,x2,y2,segNum)
    if math.abs(x1-x2)<Shape.EPS then -- vertical -> line
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
---@param x number
---@param y number
---@param r number
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