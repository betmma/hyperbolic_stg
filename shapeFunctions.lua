-- helper functions for hyperbolic geometry
---@alias angle number
---@alias coordinate number

local math=math

-- hyperbolic distance
function Shape.distance(x1,y1,x2,y2)
    local ay=Shape.axisY
    return 2*Shape.curvature*math.log((math.distance(x1,y1,x2,y2)+math.distance(x1,y1,x2,2*ay-y2))/(2*((y1-ay)*(y2-ay))^0.5))
end

--  get distance between two objects with x,y coordinates
---@param obj1 table "{x,y}"
---@param obj2 table "{x,y}"
---@return number distance (hyperbolic) distance between obj1 and obj2
function Shape.distanceObj(obj1,obj2)
    return Shape.distance(obj1.x,obj1.y,obj2.x,obj2.y)
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

-- get direction from obj1 to obj2 (at obj1)
---@param obj1 table "{x,y}"
---@param obj2 table "{x,y}"
---@return angle 'direction in [-pi/2,3pi/2]'
function Shape.toObj(obj1,obj2)
    return Shape.to(obj1.x,obj1.y,obj2.x,obj2.y)
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

-- used to calculate segment (not line) hitbox (note it's approx.)
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
        local r2=(yc-Shape.axisY)^2+(xc-x1)^2
        return {x1,Shape.axisY+math.sqrt(r2)}
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

--- calculate the distance from point xc,yc to line [x1,y1 to x2,y2]. Uses nearestToLine.
function Shape.distanceToLine(xc,yc,x1,y1,x2,y2)
    local nearest=Shape.nearestToLine(xc,yc,x1,y1,x2,y2)
    return Shape.distance(xc,yc,nearest[1],nearest[2])
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
    -- local x3toself=Shape.to(x3,y3,xs,ys)
    -- local selftox3=Shape.to(xs,ys,x3,y3)
    local distance=Shape.distance(xs,ys,x3,y3)
    if distance<Shape.EPS then
        local tangentAngle=Shape.to(xs,ys,x1,y1)
        return xs,ys,tangentAngle*2+math.pi
    end
    local centerX,radius=Shape.lineCenter(x1,y1,x2,y2)
    local xsd,ysd=xs-centerX,ys-Shape.axisY
    local disSSquared=xsd*xsd+ysd*ysd
    local ratio=radius*radius/disSSquared
    local xReflection,yReflection=centerX+xsd*ratio,Shape.axisY+ysd*ratio -- this is the reflection point
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
    local width=love.graphics.getLineWidth()
    love.graphics.setLineWidth(y/300*width)
    love.graphics.circle(mode or "line", x,y,r)
    love.graphics.setLineWidth(width)
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
---@param xyindex boolean|nil "if true, return {x=...,y=...} instead of {x,y}"
---@return table[] points table of coordinates of the vertices. {{x1,y1},{x2,y2},...}
function Shape.regularPolygonCoordinates(x,y,r,n,theta,xyindex)
    theta=theta or 0
    local points={}
    for i=1,n do
        local angle=math.pi*2/n*(i-0.5)+theta
        local x2,y2=Shape.rThetaPos(x,y,r,angle)
        points[i]=xyindex and {x=x2,y=y2} or {x2,y2}
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

-- same as rThetaPos, but return the new direction facing after moving. Note that when r is negative, the direction is facing the beginning point (naturally, because you are moving backward), so flip r's sign and add pi to theta will result in same newX and newY, but pi added to newTheta.
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
    local rLT0=r<0
    if rLT0 then
        r=-r
        theta=theta+math.pi
    end
    local x2,y2,r2=Shape.getCircle(x,y,r)
    local xp,yp=x2,y2+r2 -- theta=pi/2
    local retX,retY=Shape.rotateAround(xp,yp,theta-math.pi/2,x,y)
    return retX,retY,Shape.to(retX,retY,x,y)+(rLT0 and 0 or math.pi) -- if r>0 add pi
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
    local finaltheta=math.atan2(retY-y2,retX-x2)%(math.pi*2)
    if finaltheta>math.pi*3/2 and theta<math.pi/2 then 
        div=div-1
    end
    return finaltheta+div*math.pi*2
end


--- Calculates the coordinates of the vertices of a Schwarz triangle (p,q,r)
--- in the Upper Half-Plane model. vertices are ordered in counter-clockwise direction.
---@param p integer Reciprocal of the angle at vertex v0 (angle = pi/p).
---@param q integer Reciprocal of the angle at vertex v1 (angle = pi/q).
---@param r integer Reciprocal of the angle at vertex v2 (angle = pi/r).
---@param v0_coord table Coordinates of the first vertex, e.g., {x=0, y=1} or {0,1}.
---                     It's assumed y-coordinate is > Shape.axisY.
---@param dir_v0v1_angle number Hyperbolic angle (in radians) of the side v0-v1 at v0,
---                             as expected by Shape.rThetaPos.
---@return table v0_out {x, y} coordinates of the first vertex.
---@return table v1_out {x, y} coordinates of the second vertex.
---@return table v2_out {x, y} coordinates of the third vertex.
function Shape.schwarzTriangleVertices(p, q, r, v0_coord, dir_v0v1_angle)
    -- 1. Extract v0 coordinates
    local v0x = v0_coord.x or v0_coord[1]
    local v0y = v0_coord.y or v0_coord[2]
  
    if v0x == nil or v0y == nil then
      error("v0_coord must contain recognizable x and y parts (e.g., {x=val, y=val} or {val1,val2}).")
    end
    if v0y <= Shape.axisY then
      error(string.format("The y-coordinate of v0_coord (%.2f) must be greater than Shape.axisY (%.2f) in the Upper Half-Plane model.", v0y, Shape.axisY))
    end
    
    local v0_out = {v0x, v0y}
  
    -- 2. Calculate internal angles of the triangle (A at v0, B at v1, C at v2)
    local angle_A = math.pi / p
    local angle_B = math.pi / q
    local angle_C = math.pi / r
  
    -- 3. Calculate model-scaled hyperbolic side lengths
    --    The hyperbolic law of cosines gives d_intrinsic = acosh(...).
    --    The distance used by Shape.rThetaPos should be d_model = Shape.curvature * d_intrinsic.
    local cos_A = math.cos(angle_A)
    local cos_B = math.cos(angle_B)
    local cos_C = math.cos(angle_C)
    local sin_A = math.sin(angle_A)
    local sin_B = math.sin(angle_B)
    local sin_C = math.sin(angle_C) -- Used for side b
  
    -- Check for valid denominators to prevent division by zero or issues with acosh input
    local den_c = sin_A * sin_B
    if math.abs(den_c) < 1e-9 then 
      error("Degenerate triangle geometry for side c (p or q too large, or invalid). sin(A) or sin(B) is near zero.")
    end
    local cosh_c_val = (cos_A * cos_B + cos_C) / den_c
    local dist_v0v1_intrinsic = math.acosh(cosh_c_val) -- math.acosh is assumed to be defined
    local dist_v0v1_model = Shape.curvature * dist_v0v1_intrinsic
  
    local den_b = sin_A * sin_C
    if math.abs(den_b) < 1e-9 then
      error("Degenerate triangle geometry for side b (p or r too large, or invalid). sin(A) or sin(C) is near zero.")
    end
    local cosh_b_val = (cos_A * cos_C + cos_B) / den_b
    local dist_v0v2_intrinsic = math.acosh(cosh_b_val)
    local dist_v0v2_model = Shape.curvature * dist_v0v2_intrinsic
  
    -- 4. Calculate v1 using Shape.rThetaPos
    local v1x, v1y = Shape.rThetaPos(v0x, v0y, dist_v0v1_model, dir_v0v1_angle)
    local v1_out = {v1x, v1y}
  
    -- 5. Calculate v2 using Shape.rThetaPos
    --    Angle at v0 is angle_A. For CCW order (v0,v1,v2), turn from v0v1 to v0v2 is -angle_A.
    local dir_v0v2_angle = dir_v0v1_angle - angle_A 
    local v2x, v2y = Shape.rThetaPos(v0x, v0y, dist_v0v2_model, dir_v0v2_angle)
    local v2_out = {v2x, v2y}
  
    return v0_out, v1_out, v2_out
end

--- return the area of a triangle with vertices (x1,y1), (x2,y2), (x3,y3). not using Shape.curvature
---@return number "area of the triangle"
function Shape.triangleArea(x1,y1,x2,y2,x3,y3)
    local angleA=math.abs(math.modClamp(Shape.to(x1,y1,x2,y2)-Shape.to(x1,y1,x3,y3)))
    local angleB=math.abs(math.modClamp(Shape.to(x2,y2,x1,y1)-Shape.to(x2,y2,x3,y3)))
    local angleC=math.abs(math.modClamp(Shape.to(x3,y3,x1,y1)-Shape.to(x3,y3,x2,y2)))
    return math.pi-angleA-angleB-angleC
end

--- return the barycenter coordinates of a point (x,y) in triangle with vertices (x1,y1), (x2,y2), (x3,y3).
---@return number "barycenter coordinate A"
---@return number "barycenter coordinate B"
---@return number "barycenter coordinate C"
function Shape.barycenterCoordinates(x,y,x1,y1,x2,y2,x3,y3)
    local area=Shape.triangleArea(x1,y1,x2,y2,x3,y3)
    local areaA=Shape.triangleArea(x,y,x2,y2,x3,y3)
    local areaB=Shape.triangleArea(x1,y1,x,y,x3,y3)
    local areaC=Shape.triangleArea(x1,y1,x2,y2,x,y)
    return areaA/area, areaB/area, areaC/area
end

--- flip a point (x,y) into a triangle with vertices (x1,y1), (x2,y2), (x3,y3). If the point is outside the triangle, it will be reflected by the edges until it is inside or flipLimit is reached.
---@return coordinate "x of the flipped point"
---@return coordinate "y of the flipped point"
---@return angle "delta orientation after flipping"
---@return number "number of flips" 
---@return boolean "after flipLimit loops, true if the point is inside the triangle, false if it is still outside"
function Shape.flipIntoTriangle(x,y,x1,y1,x2,y2,x3,y3,flipLimit)
    --[[
    usage example (due to reflectByLine flip axis thing is kinda spaghetti):
    v1,v2,v3=Shape.schwarzTriangleVertices(p,q,r,{center.x,center.y},0) -- coords of the triangle vertices
    outerx,outery=... before flipping
    innerx,innery,deltaOrientation,flipCount,inside=Shape.flipIntoTriangle(outerx,outery,v1[1],v1[2],v2[1],v2[2],v3[1],v3[2],20)
    if you want after flip, the direction towards center:
    innerToCenterDir=Shape.to(innerx,innery,center.x,center.y)
    then before flip, the direction is calculated by:
    outerDir=innerToCenterDir-deltaOrientation (this deltaOrientation means afterFlip-beforeFlip, so minus here)
    and, if flipCount is odd, needs an extra flip:
    if flipCount%2==1 then
        outerDir=math.pi-outerDir
    end
    ]]
    flipLimit=flipLimit or 20
    local loopCount=0
    local flipCount=0
    local deltaOrientationSum=0
    local dO=0
    while loopCount<flipLimit do
        local inside=true
        if not Shape.leftToLine(x,y,x1,y1,x2,y2) then
            x,y,dO=Shape.reflectByLine(x,y,x1,y1,x2,y2)
            inside=false
            deltaOrientationSum=-deltaOrientationSum+dO
            flipCount=flipCount+1
        end
        if not Shape.leftToLine(x,y,x2,y2,x3,y3) then
            x,y,dO=Shape.reflectByLine(x,y,x2,y2,x3,y3)
            inside=false
            deltaOrientationSum=-deltaOrientationSum+dO
            flipCount=flipCount+1
        end
        if not Shape.leftToLine(x,y,x3,y3,x1,y1) then
            x,y,dO=Shape.reflectByLine(x,y,x3,y3,x1,y1)
            inside=false
            deltaOrientationSum=-deltaOrientationSum+dO
            flipCount=flipCount+1
        end
        if inside==true then
            return x,y, deltaOrientationSum, flipCount, true
        end
        loopCount=loopCount+1
    end
    return x,y, deltaOrientationSum, flipCount, false
end

--- given a segment with endpoints (x1,y1) and (x2,y2), return equally spaced points on the segment, with distance <= step but number of points <= maxPoints.
---@param x1 coordinate
---@param y1 coordinate
---@param x2 coordinate
---@param y2 coordinate
---@param step number
---@param maxPoints number
---@return table[] points "table of points, each point is a table with x and y attributes"
function Shape.segmentPoints(x1,y1,x2,y2,step,maxPoints)
    local points={}
    local distance=Shape.distance(x1,y1,x2,y2)
    if distance<Shape.EPS then
        return {{x=x1,y=y1},{x=x2,y=y2}} -- if distance is 0, return two points
    end
    local numPoints=math.ceil(distance/step)
    if numPoints>maxPoints then
        numPoints=maxPoints
    end
    local stepSize=distance/numPoints
    local dir=Shape.to(x1,y1,x2,y2)
    for i=0,numPoints do
        local x,y=Shape.rThetaPos(x1,y1,stepSize*i,dir)
        points[i+1]={x=x,y=y}
    end
    return points
end