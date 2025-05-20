-- helper functions for hyperbolic geometry
---@alias angle number
---@alias coordinate number

local math=math

-- hyperbolic distance
function Shape.distance(x1,y1,x2,y2)
    local ay=Shape.axisY
    return 2*Shape.curvature*math.log((math.distance(x1,y1,x2,y2)+math.distance(x1,y1,x2,2*ay-y2))/(2*((y1-ay)*(y2-ay))^0.5))
end

-- get X coordinate and radius of center point of line x1,y1 to x2,y2
---@return coordinate centerX X coordinate of center point
---@return number radius (Euclidean) radius of line
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
---@return angle 'direction in [-pi/2,3pi/2]'
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
---@param xs coordinate
---@param ys coordinate
---@param x1 coordinate
---@param y1 coordinate
---@param x2 coordinate
---@param y2 coordinate
---@return coordinate "x of reflected point"
---@return coordinate "y of reflected point"
---@return angle "delta orientation from reflection"
function Shape.reflectByLine(xs,ys,x1,y1,x2,y2)
    local nearest=Shape.nearestToLine(xs,ys,x1,y1,x2,y2)
    local x3,y3=nearest[1],nearest[2]
    local x3toself=Shape.to(x3,y3,xs,ys)
    -- local selftox3=Shape.to(xs,ys,x3,y3)
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
--- @param movingObj {x: number, y:number} "object to be moved, has x and y attributes"
--- @param aimObj {x: number, y:number}|angle "object to be aimed at, or direction (under this case, [stopAtReach] is ignored)"
--- @param step number "step distance"
--- @param stopAtReach? boolean "if true, won't go past [aimObj] if [step] is larger than distance between them"
function Shape.moveTowards(movingObj,aimObj,step,stopAtReach)
    local angle,aimX,aimY
    if type(aimObj)=='number' then
        angle=aimObj
        stopAtReach=false
    elseif type(aimObj)=='table' then
        aimX=aimObj.x
        aimY=aimObj.y
        if not aimX or not aimY then
            error('aimObj.x or aimObj.y is nil. Got aimObj.x='..tostring(aimObj.x)..' aimObj.y='..tostring(aimObj.y))
        end
        angle=Shape.to(movingObj.x,movingObj.y,aimX,aimY)
    else
        error('aimObj must be a number or a table with x and y attributes. Got: '..type(aimObj))
    end
    if stopAtReach then
        local distance=Shape.distance(movingObj.x,movingObj.y,aimX,aimY)
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
---@param x coordinate 'x of arc center'
---@param y coordinate 'y of arc center'
---@param r number 'arc radius'
---@param s_ang angle 'arc start angle'
---@param e_ang angle 'arc end angle'
---@param numLines any 'how many lines are used'
function Shape.drawArc(x, y, r, s_ang, e_ang, numLines)
    local x2,y2,r2=Shape.getCircle(x,y,r)
    s_ang=Shape.rThetaPosPolarAngle(x,y,r,s_ang)
    e_ang=Shape.rThetaPosPolarAngle(x,y,r,e_ang)
	math.drawArc(x2,y2,r2,s_ang,e_ang,numLines)
end

-- draw hyperbolic circle with center (x,y) and radius r. using Shape.getCircle
function Shape.drawCircle(x,y,r,mode)
    x,y,r=Shape.getCircle(x,y,r)
    love.graphics.circle(mode or "line", x,y,r)
    return x,y,r
end

-- find the Euclidean x', y' and r' of hyperbolic circle with center (x,y) and radius r.
---@param x coordinate
---@param y coordinate
---@param r number
function Shape.getCircle(x,y,r)
    return x, (y-Shape.axisY)*math.cosh(r/Shape.curvature)+Shape.axisY, (y-Shape.axisY)*math.sinh(r/Shape.curvature)
end



-- calculate the coordinates of a regular polygon with center (x,y), radius r, number of vertices n and rotation angle theta
---@param x coordinate
---@param y coordinate
---@param r number
---@param n number
---@param theta angle|nil
---@return table[] points table of coordinates of the vertices. {{x1,y1},{x2,y2},...}
function Shape.regularPolygonCoordinates(x,y,r,n,theta)
    theta=theta or 0
    local points={}
    for i=1,n do
        local angle=math.pi*2/n*(i-0.5)+theta
        local x2,y2=Shape.rThetaPos(x,y,r,angle)
        points[i]={x2,y2}
    end
    return points
end
--- hyperbolic rotate a point (x1,y1) around (ox,oy) by angle. Uses inlined mobius transformation.
---@param x1 coordinate
---@param y1 coordinate
---@param angle angle
---@param ox coordinate
---@param oy coordinate
---@return coordinate "x2"
---@return coordinate "y2"
function Shape.rotateAround(x1, y1, angle, ox, oy)
    -- S_d_im: imaginary part of S_d. Real part of S_d is -ox.
    local S_d_im = oy - 2*Shape.axisY

    -- U_a = cos(angle) + i*sin(angle)
    local U_a_re, U_a_im = math.cos(angle), math.sin(angle)

    local T_tmp_a_re = -ox * U_a_re - S_d_im * U_a_im
    local T_tmp_a_im = -ox * U_a_im + S_d_im * U_a_re

    local T_final_a_re = T_tmp_a_re + ox
    local T_final_a_im = T_tmp_a_im + oy

    local T_final_b_re = -T_tmp_a_re * ox + T_tmp_a_im * oy - ox * ox - oy * S_d_im
    local T_final_b_im = -T_tmp_a_re * oy - T_tmp_a_im * ox + ox * S_d_im - oy * ox

    -- T_final_c = T_tmp_c + 1 (where T_tmp_c = -U_a)
    local T_final_c_re = -U_a_re + 1
    local T_final_c_im = -U_a_im

    local T_final_d_re = U_a_re * ox - U_a_im * oy - ox
    local T_final_d_im = U_a_re * oy + U_a_im * ox + S_d_im

    -- Numerator = T_final_a * z + T_final_b
    local num_re = T_final_a_re * x1 - T_final_a_im * y1 + T_final_b_re
    local num_im = T_final_a_re * y1 + T_final_a_im * x1 + T_final_b_im

    -- Denominator = T_final_c * z + T_final_d
    local den_re = T_final_c_re * x1 - T_final_c_im * y1 + T_final_d_re
    local den_im = T_final_c_re * y1 + T_final_c_im * x1 + T_final_d_im

    -- Division: num / den = num * conj(den) / |den|^2
    local den_mod_sq = den_re * den_re + den_im * den_im

    -- if den_mod_sq == 0 then error("Division by zero in Mobius apply") end

    local common_divisor = 1.0 / den_mod_sq
    local result_re = (num_re * den_re + num_im * den_im) * common_divisor
    local result_im = (num_im * den_re - num_re * den_im) * common_divisor

    return result_re, result_im
end

-- find the point that is (r,theta) to x,y in polar coordinates
-- also means "from (x,y), aim at theta direction and go r unit forward, which point will you arrive"
---@param x coordinate
---@param y coordinate
---@param r number
---@param theta angle
---@return coordinate newX "x of new point"
---@return coordinate newY "y of new point"
function Shape.rThetaPos(x,y,r,theta)
    if r==0 then
        return x,y
    end
    if r<0 then
        r=-r
        theta=theta+math.pi
    end
    local x2,y2,r2=Shape.getCircle(x,y,r)
    local xp,yp=x2,y2+r2 -- theta=pi/2
    local retX,retY=Shape.rotateAround(xp,yp,theta-math.pi/2,x,y)
    return retX,retY
end

-- same as rThetaPos, but return the new direction facing after moving.
---@param x coordinate
---@param y coordinate
---@param r number
---@param theta angle
---@return coordinate newX "x of new point"
---@return coordinate newY "y of new point"
---@return angle newTheta "after moving the direction you are facing"
function Shape.rThetaPosT(x,y,r,theta)
    if r==0 then
        return x,y,theta
    end
    if r<0 then
        r=-r
        theta=theta+math.pi
    end
    local x2,y2,r2=Shape.getCircle(x,y,r)
    local xp,yp=x2,y2+r2 -- theta=pi/2
    local retX,retY=Shape.rotateAround(xp,yp,theta-math.pi/2,x,y)
    return retX,retY,Shape.to(retX,retY,x,y)+math.pi
end

-- get Euclidean polar angle. It's used in Shape.drawArc and probably nowhere else.
---@return angle "euclidean polar angle from original point to new point"
function Shape.rThetaPosPolarAngle(x,y,r,theta)
    if r==0 then
        return theta
    end
    if r<0 then
        r=-r
        theta=theta+math.pi
    end
    local div=math.floor(theta/(math.pi*2))
    theta=theta%(math.pi*2)
    local x2,y2,r2=Shape.getCircle(x,y,r)
    local xp,yp=x2,y2+r2 -- theta=pi/2
    local retX,retY=Shape.rotateAround(xp,yp,theta-math.pi/2,x,y)
    local finaltheta=math.atan2(retY-y,retX-x)%(math.pi*2)
    if finaltheta>math.pi*3/2 and theta<math.pi/2 then 
        div=div-1
    end
    return finaltheta+div*math.pi*2
end