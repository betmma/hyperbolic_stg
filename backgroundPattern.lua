local Object=require 'classic'
local BackgroundPattern=Object:extend()

-- BackgroundPattern is an abstract class that needs implementation of:
-- 1. new(args): initialize the background pattern.
-- 2. update(dt): update the background pattern, called in love.update(dt)
-- 3. draw(): draw the background pattern, called in love.draw()
-- It will be bound to G and called in G.update and G.draw.
function BackgroundPattern:new(args)
    self.notRespondToDrawAll=true -- Since background should be drawn before everything else, it should not be drawn by Object:drawAll but directly called in G.draw before Object:drawAll.
end

local Empty=BackgroundPattern:extend()
function Empty:new(args)
    Empty.super.new(self,args)
end
BackgroundPattern.Empty=Empty

local sideLengthCache={}
-- calculate {the side length} and {radius of circumcircle} of a polygon with [sideNum] sides and each angle 2pi/[angleNum] in hyperbolic geometry. The result is cached.
local calculateSideLength=function(sideNum,angleNum)
    if sideLengthCache[sideNum] and sideLengthCache[sideNum][angleNum] then
        return sideLengthCache[sideNum][angleNum][1],sideLengthCache[sideNum][angleNum][2]
    end
    local centerToVertex=(math.sqrt((math.tan(math.pi/2-math.pi/angleNum)-math.tan(math.pi/sideNum))/(math.tan(math.pi/2-math.pi/angleNum)+math.tan(math.pi/sideNum)))) -- reference: https://www.malinc.se/noneuclidean/en/poincaretiling.php. sideNum->p, angleNum->q. actually this radius is on a poincare disk
    local x1,y1=centerToVertex,0
    local x2,y2=centerToVertex*math.cos(math.pi*2/sideNum),centerToVertex*math.sin(math.pi*2/sideNum) -- two points on a side, on a poincare disk
    local d=2*math.distance(x1,y1,x2,y2)^2/(1-centerToVertex^2)^2
    local sideLength= math.acosh(1+d)*Shape.curvature -- distance formula of poincare disk. reference: https://en.wikipedia.org/wiki/Poincar%C3%A9_disk_model
    local circumcircleRadius=2*math.atanh(centerToVertex)*Shape.curvature -- distance formula when 1 point is at center. 
    sideLengthCache[sideNum]=sideLengthCache[sideNum] or {}
    sideLengthCache[sideNum][angleNum]={sideLength,circumcircleRadius}
    return sideLength,circumcircleRadius
end

local function getCenterOfPolygonWithSide(x1,y1,x2,y2,sideNum,angleNum)
    local direction=Shape.to(x2,y2,x1,y1)
    local toCenterDirection=direction+math.pi*2/angleNum/2
    local _,centerRadius=calculateSideLength(sideNum,angleNum)
    local x,y=Shape.rThetaPos(x2,y2,centerRadius,toCenterDirection)
    return x,y
end
BackgroundPattern.getCenterOfPolygonWithSide=getCenterOfPolygonWithSide

local function drawSideLine(x1,y1,x2,y2,color)
    local colorref={love.graphics.getColor()}
    love.graphics.setColor(color[1],color[2],color[3])
    local num=math.ceil(math.min(25,Shape.distance(x1,y1,x2,y2)/10))
    Shape.drawSegment(x1,y1,x2,y2,num)
    -- love.graphics.setColor(0.35,0.15,0.8)
    -- Shape.drawSegment(x1+1,y1+1,x2+1,y2+1,num)
    love.graphics.setColor(colorref[1],colorref[2],colorref[3])
end

-- draw a face of a polygon. x1,y1,x2,y2: two points of the side. color: {r,g,b}. sideNum: how many sides do each polygon have. angleNum: how many sides are connected to each point.
-- bad: since a polygon is drawn once for each side, bigger sideNum causes a polygon to be drawn redundant sideNum/2 times.
local function drawSideFace(x1,y1,x2,y2,color,sideNum,angleNum)
    local vertices={}
    -- since love.graphics.polygon draws straight sides, need to insert vertices on each hyperbolic side to smooth the curve
    local function addVerticesOnSide(x1,y1,x2,y2,num)
        local xCenter,radius=Shape.lineCenter(x1,y1,x2,y2)
        local theta1,theta2=math.atan2(y1-Shape.axisY,x1-xCenter),math.atan2(y2-Shape.axisY,x2-xCenter)
        for i=1,num do
            local alpha=theta1+(theta2-theta1)*(i-1)/(num)
            local x,y=xCenter+radius*math.cos(alpha),Shape.axisY+radius*math.sin(alpha)
            vertices[#vertices+1]=x
            vertices[#vertices+1]=y
        end
    end
    local sideLength=calculateSideLength(sideNum,angleNum)
    for sideIndex=1,sideNum do
        local alpha1=math.pi*2/angleNum+Shape.to(x2,y2,x1,y1)
        local num=math.clamp(Shape.distance(x1,y1,x2,y2)/5,3,15)
        addVerticesOnSide(x1,y1,x2,y2,num)
        x1,y1=x2,y2
        x2,y2=Shape.rThetaPos(x2,y2,sideLength,alpha1)
    end
    local colorref={love.graphics.getColor()}
    love.graphics.setColor(color[1],color[2],color[3])
    -- without triangulate love.graphics.polygon("fill",vertices) is buggy at some concave part
    local triangles = love.math.triangulate(vertices)
    for i, triangle in ipairs(triangles) do
        love.graphics.polygon("fill", triangle)
    end
    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4])
end

--[[
params: 
[point]: where pattern begins. [angle]: direction of first line. [sideNum]: how many sides do each polygon have. [angleNum]: how many sides are connected to each point. [iteCount]: currently only to check if it's first point. [centerPoint]: input nil. [toDrawNum]: how many lines to draw (an approximation). If only draw sides, a few hundred to merely above 1000 is a reasonable number. If draw faces <400 is recommended.
returns: 
adjacentPoints,angles,sidesTable. [adjacentPoints]: adjacent points to centerPoint (inputted point). [angles]: angles from each adjacent point to center point. I knew it's only used to update center point while keeping the pattern same, so angle should be to center point. [sidesTable]: all sides that are drawn. Each side is a table {point1,point2,index}. index is the index of the side in the sidesTable.
the way to find tesselation points is rather simple: from a point, extend angleNum lines, and only keep points that are farther away from the center point. This is because the closer points are already drawn by the previous lines. However when sideNum is odd (especially 3) some lines' two ends have same distance to the center point, so another check (distance0-distance>Shape.EPS*10 or alpha%(math.pi*2)>math.pi) is added to prevent the side drawn 0 or 2 times.
pointsQueue is a queue that stores points that are not drawn yet, drawedPointsNum being the pointer. If drawedPointsNum is more than toDrawNum/angleNum, clear the queue to stop the tesselation. So that you shouldn't try getting points information from pointsQueue since it's always cleared when function ends.]]
local drawedPointsNum=0
local pointsQueue={}
local function tesselation(point,angle,sideNum,angleNum,iteCount, centerPoint, toDrawNum, sidesTable, skipInRangeLimit)
    centerPoint=centerPoint or point
    if iteCount==0 then
        drawedPointsNum=0
        pointsQueue={}
    end
    local iteCount=(iteCount or 0)+1
    local adjacentPoints={}
    local r=calculateSideLength(sideNum,angleNum)
    local begin=1
    local en=angleNum--iteCount>1 and angleNum-2 or angleNum
    sidesTable=sidesTable or {}

    drawedPointsNum=drawedPointsNum+1
    local distance0=Shape.distance(point.x,point.y,centerPoint.x,centerPoint.y)
    for i=begin,en do
        if not skipInRangeLimit and not math.inRange(point.x,point.y,-400,1200,-5,4000) then
            break
        end
        local alpha=angle+math.pi*2/angleNum*(i)
        local ret={Shape.rThetaPos(point.x,point.y,r,alpha)}
        local newpoint={x=ret[1],y=ret[2]}
        local distance=Shape.distance(newpoint.x,newpoint.y,centerPoint.x,centerPoint.y)
        if distance<distance0 and (distance0-distance>Shape.EPS*10 or alpha%(math.pi*2)>math.pi) then
            goto continue
        end
        adjacentPoints[#adjacentPoints+1]=newpoint
        sidesTable[#sidesTable+1]={point,newpoint,index=drawedPointsNum*angleNum+i}
        ::continue::
    end
    -- if leftMost and iteCount>2 then
    --     table.remove(points,1)
    -- end
    -- if drawedPointsNum>20 then
    --     pointsQueue={}
    --     return {},{}
    -- end
    local angles={}
    for i=1,#adjacentPoints do
        local newpoint=adjacentPoints[i]
        local newangle=Shape.to(newpoint.x,newpoint.y,point.x,point.y)
        table.insert(angles,newangle)
        pointsQueue[#pointsQueue+1]={newpoint,newangle,iteCount}
        -- tesselation(newpoint,newangle,sideNum,angleNum,iteCount,color,i==1,centerPoint)
    end
    if drawedPointsNum<toDrawNum/angleNum and pointsQueue[drawedPointsNum]then 
        tesselation(pointsQueue[drawedPointsNum][1],pointsQueue[drawedPointsNum][2],sideNum,angleNum,pointsQueue[drawedPointsNum][3],centerPoint,toDrawNum,sidesTable, skipInRangeLimit)
    else
        pointsQueue={}
    end

    return adjacentPoints,angles,sidesTable
end

-- this function isn't used in main menu cuz sometimes random parameters gets laggy
local function randomSideNumAndAngleNum()
    math.randomseed(os.time())
    local sideNum=math.random(3,8)
    local angleNum=math.random(3,8)
    local factor=(sideNum-2)*(angleNum-2)
    if factor<=4 or factor>20 then -- factor must > 4 to become a hyperbolic tesselation. the 20 limit is to prevent too scattered tesselation
        return randomSideNumAndAngleNum()
    end
    return sideNum,angleNum
end

-- a tesselation that moves and rotates. It's used in main menu.
local MainMenuTesselation=BackgroundPattern:extend()
function MainMenuTesselation:new(args)
    MainMenuTesselation.super.new(self,args)
    -- self.name='Tesselation'
    args=args or {}
    self.point=args.point or {x=400,y=150}
    self.limit=args.limit or {xmin=300,xmax=500,ymin=100,ymax=600}
    self.angle=args.angle or math.pi/3
    self.dangle=args.dangle or (0.004*math.randomSign())
    self.speed=args.speed or (0.0045*math.randomSign())
    self.sideNum=args.sideNum
    self.angleNum=args.angleNum
    if not self.sideNum or not self.angleNum then
        self.sideNum,self.angleNum=4,5--randomSideNumAndAngleNum()
    end
end

function MainMenuTesselation:update(dt)
    local newpoint,newAngle=self.newPoints or {self.point},self.newAngles or {self.angle}
    -- if the current point is out of limit, find a new point from the drawn points (so that it seems like an infinite pattern)
    -- if not math.inRange(self.point.x,self.point.y,self.limit.xmin,self.limit.xmax,self.limit.ymin,self.limit.ymax)  then
    --     for i=1,#newpoint do
    --         if math.inRange(newpoint[i].x,newpoint[i].y,self.limit.xmin,self.limit.xmax,self.limit.ymin,self.limit.ymax) then
    --             self.point=newpoint[i]
    --             self.angle=newAngle[i]
    --         end
    --     end
    -- end
    local centerExpected={x=400,y=300}
    local currentMinimumDistance=Shape.distance(self.point.x,self.point.y,centerExpected.x,centerExpected.y)
    if currentMinimumDistance>math.min(calculateSideLength(self.sideNum,self.angleNum)/2,100) then
        for i=1,#newpoint do
            local distance=Shape.distance(newpoint[i].x,newpoint[i].y,centerExpected.x,centerExpected.y)
            if distance<currentMinimumDistance then
                self.point=newpoint[i]
                self.angle=newAngle[i]
                currentMinimumDistance=distance
            end
        end
    end

    self.point={x=self.point.x-(self.point.x-400)*self.speed,y=self.point.y-(self.point.y-Shape.axisY)*self.speed}
    self.angle=self.angle+self.dangle
end

function MainMenuTesselation:draw()
    local ay=Shape.axisY
    Shape.axisY=-10
    -- tesselation({x=self.point.x+1,y=self.point.y+1},self.angle,5,5,0,126.2,{},{0.35,0.15,0.8})
    local width=love.graphics.getLineWidth()
    love.graphics.setLineWidth(10)
    local sides
    self.newPoints,self.newAngles,sides=tesselation(self.point,self.angle,self.sideNum,self.angleNum,0,nil,380)
    -- table.sort(sides,function(a,b)
    --     return a[1].y+a[2].y>b[1].y+b[2].y
    -- end)
    for i=1,#sides do
        local centerX,centerY=(sides[i][2].x+sides[i][1].x)/2,(sides[i][2].y+sides[i][1].y)/2
        local index=sides[i].index
        -- local color={math.cos(index/100)*0.8+0.2,math.cos(index/70)*0.5+0.5,math.sin(centerX/centerY/10)*0.7+0.3}
        local color=index%2==0 and {0.4,0.3,0.1} or {0.1,0.4,0.3}
        drawSideFace(sides[i][1].x,sides[i][1].y,sides[i][2].x,sides[i][2].y,color,self.sideNum,self.angleNum)
    end
    for i=1,#sides do
        drawSideLine(sides[i][1].x,sides[i][1].y,sides[i][2].x,sides[i][2].y,{0.35,0.15,0.8})
    end
    love.graphics.setLineWidth(width)
    Shape.axisY=ay
end

BackgroundPattern.MainMenuTesselation=MainMenuTesselation

local Square=BackgroundPattern:extend()
function Square:new(args)
    Square.super.new(self,args)
    args=args or {}
    self.radius=args.radius or 10
    self.radiusMax=args.radiusMax or 70
    self.angle=args.angle or math.pi/3
    self.speed=args.speed or 0.3
end

function Square:update(dt)
    self.radius=(self.radius+self.speed)%self.radiusMax
    self.angle=self.angle+self.speed/20
end

function Square:drawOne(r,angle)
    local xc,yc=400,300
    local r2=math.cosh(r/10)
    local points={}
    for i=1,4 do
        local alpha=angle+math.pi*2/4*(i-1)
        local ret={xc+r2*math.cos(alpha),yc+r2*math.sin(alpha)}
        local newpoint={x=ret[1],y=ret[2]}
        points[#points+1]=newpoint
    end
    local ratio=r/self.radiusMax
    love.graphics.setColor(0.5,0.7,0.9,ratio*0.3)
    for i=1,#points do
        local newpoint=points[i]
        love.graphics.line(newpoint.x,newpoint.y,points[i%#points+1].x,points[i%#points+1].y)
    end
end

function Square:draw()
    local colorref={love.graphics.getColor()}
    love.graphics.setColor(0,0,0)
    -- love.graphics.rectangle('fill',0,0,800,600)
    local width=love.graphics.getLineWidth()
    love.graphics.setLineWidth(10)
    self:drawOne(self.radius,self.angle)
    self:drawOne((self.radius+35)%self.radiusMax,self.angle)
    love.graphics.setLineWidth(width)
    love.graphics.setColor(colorref[1],colorref[2],colorref[3])
end

BackgroundPattern.Square=Square


local FixedTesselation=BackgroundPattern:extend()
-- FixedTesselation is a tesselation that calculate all sides upon new() and doesn't update. Used in normal levels.
function FixedTesselation:new(args)
    FixedTesselation.super.new(self,args)
    args=args or {}
    self.sideNum=args.sideNum or 4
    self.angleNum=args.angleNum or 5
    self.centerPoint=args.centerPoint or {x=400,y=300}
    self.faceColor=args.faceColor or {0.1,0.1,0.1}
    self.sideColor=args.sideColor or {0.15,0.1,0.2}
    self.overallColorScale=args.overallColorScale or 1
    self.toDrawNum=args.toDrawNum or 40
    self.angle=args.angle or 0
    self.adjacentPoints,self.angles,self.sidesTable=tesselation(self.centerPoint,self.angle,self.sideNum,self.angleNum,0,nil,self.toDrawNum,nil,true) -- self.adjacentPoints and self.angles are not used in FixedTesselation but in FollowingTesselation so don't remove them
    for i=1,#self.sidesTable do
        local centerPos={getCenterOfPolygonWithSide(self.sidesTable[i][1].x,self.sidesTable[i][1].y,self.sidesTable[i][2].x,self.sidesTable[i][2].y,self.sideNum,self.angleNum)}
        local hashValue=Hash64(''..centerPos[1]..centerPos[2].."loool")
        local color={hashValue[3]/256,hashValue[1]/256,hashValue[2]/256}
        self.sidesTable[i].color=color
        self.sidesTable[i][1]=copy_table(self.sidesTable[i][1]) -- without copying player's hyperbolic rotate can't retrieve the original position (i forgor why tho) and will crash after few frames
        self.sidesTable[i][2]=copy_table(self.sidesTable[i][2])
    end
    self.sideLength=calculateSideLength(self.sideNum,self.angleNum)
end

function FixedTesselation:update(dt)
    -- fixed tesselation doesn't need to update
end

function FixedTesselation:draw()
    local ay=Shape.axisY
    -- Shape.axisY=-10
    local width=love.graphics.getLineWidth()
    love.graphics.setLineWidth(10)
    local overallColorScale=self.overallColorScale
    local faceColorCoeff=self.faceColor
    if not self.dontDrawFaces then
        for i=1,#self.sidesTable do
            local color=self.sidesTable[i].color
            color={color[1]*faceColorCoeff[1],color[2]*faceColorCoeff[2],color[3]*faceColorCoeff[3]}
            color={color[1]*overallColorScale,color[2]*overallColorScale,color[3]*overallColorScale}
            drawSideFace(self.sidesTable[i][1].x,self.sidesTable[i][1].y,self.sidesTable[i][2].x,self.sidesTable[i][2].y,color,self.sideNum,self.angleNum)
        end
    end
    local color=self.sideColor
    color={color[1]*overallColorScale,color[2]*overallColorScale,color[3]*overallColorScale}
    if not self.dontDrawSides then
        for i=1,#self.sidesTable do
            drawSideLine(self.sidesTable[i][1].x,self.sidesTable[i][1].y,self.sidesTable[i][2].x,self.sidesTable[i][2].y,color)
        end
    end
    love.graphics.setLineWidth(width)
    Shape.axisY=ay
end
BackgroundPattern.FixedTesselation=FixedTesselation

local FollowingTesselation=BackgroundPattern:extend()
-- FollowingTesselation is a seemingly fixed tesselation that changes its center point to follow a target object (usually player), so that not need to draw many sides, but still filling the screen in player's view.
-- use FixedTesselation to generate the initial tesselation, and whenever the center point leaves the range, calculate the new center point and use a new FixedTesselation to update the sides.
function FollowingTesselation:new(args)
    FollowingTesselation.super.new(self,args)
    args=args or {}
    args.sideNum=args.sideNum or 4
    args.angleNum=args.angleNum or 5
    args.faceColor=args.faceColor or {0.1,0.1,0.1}
    args.sideColor=args.sideColor or {0.15,0.1,0.2}
    args.overallColorScale=args.overallColorScale or 1
    args.toDrawNum=args.toDrawNum or 40
    args.centerPoint=args.centerPoint or {x=400,y=300}
    args.target=args.target or Player.objects[1]
    args.updateRange=args.updateRange or 50
    for key, value in pairs(args) do
        self[key]=value
    end
    self.sidesTable=nil
    self:updateSides()
end

function FollowingTesselation:updateSides()
    local initialTesselation=FixedTesselation(self)
    self.adjacentPoints,self.angles,self.sidesTable=initialTesselation.adjacentPoints,initialTesselation.angles,initialTesselation.sidesTable
    initialTesselation:remove()
end

-- update the tesselation when the target is out of range
function FollowingTesselation:update(dt)
    local target=self.target
    if not target or target.removed or target:is(Player) and target~=Player.objects[1] then
        -- look i really dont understand why after pressing r to restart or restart in game end screen, there is only one object in Player.objects, but the target is still the old one, and target.removed is nil. so i have to check if target is in Player.objects[1]
        if Player.objects[1] then
            self.target=Player.objects[1]
            target=Player.objects[1]
        else
            return
        end
    end
    -- print(self.target.x..', '..self.target.y..', '..(#Player.objects)..', '..(self.target==Player.objects[1]and 't' or 'f'),400,300)

    local centerPoint=self.centerPoint
    local updateRange=self.updateRange
    local currentDistance=Shape.distance(target.x,target.y,centerPoint.x,centerPoint.y)
    if currentDistance>updateRange then -- should update the tesselation
        local closestPointIndex=1
        local closestDistance=Shape.distance(target.x,target.y,self.adjacentPoints[1].x,self.adjacentPoints[1].y)
        for i=2,#self.adjacentPoints do -- first check all adjacentPoints and see if any is closer to the target
            local distance=Shape.distance(target.x,target.y,self.adjacentPoints[i].x,self.adjacentPoints[i].y)
            if distance<closestDistance then
                closestDistance=distance
                closestPointIndex=i
            end
        end
        if closestDistance>currentDistance then -- if the closest point is still farther than the center point, don't update
            return
        end
        local newCenterPoint=self.adjacentPoints[closestPointIndex]
        local newAngle=self.angles[closestPointIndex]
        self.centerPoint=newCenterPoint
        self.angle=newAngle
        self:updateSides()
        
    end
end

function FollowingTesselation:draw()
    FixedTesselation.draw(self)
end

BackgroundPattern.FollowingTesselation=FollowingTesselation

local Pendulum=BackgroundPattern:extend()
-- euclid pendulum clock (for scene 6-3)
function Pendulum:new(args)
    Pendulum.super.new(self,args)
    args=args or {}
    self.radius=args.radius or 500
    self.amplitude=args.amplitude or 0.1
    self.period=args.period or 240
    self.centerPoint=args.centerPoint or {x=400,y=-200}
    self.point={x=self.centerPoint.x,y=self.centerPoint.y}
    self.colorRatio=args.colorRatio or 0 -- gradually increase this parameter to make pendulum looks like gradually appear
    self.frame=0
    self.noZoom=true
end

function Pendulum:update(dt)
    self.angle=math.sin(self.frame/self.period*math.pi*2)*self.amplitude+math.pi/2
    local x,y=math.rThetaPos(self.centerPoint.x,self.centerPoint.y,self.radius,self.angle)
    self.point={x=x,y=y}
    self.frame=self.frame+1
end

local clockImage = love.graphics.newImage( "assets/pics/clock.png" )
local clockWidth, clockHeight = clockImage:getDimensions()
local clockQuad = love.graphics.newQuad(0, 0, clockWidth, clockHeight, clockWidth, clockHeight)

function Pendulum:draw() -- ugh direct drawing looks kinda cringe. maybe find an image for this later. (done but this is still kept)
    local colorref={love.graphics.getColor()}
    local width=love.graphics.getLineWidth()
    love.graphics.setLineWidth(10)
    local x1,y1=self.centerPoint.x,self.centerPoint.y
    local x2,y2=self.point.x,self.point.y
    local function colorMult(colorTable)
        return {colorTable[1]*self.colorRatio,colorTable[2]*self.colorRatio,colorTable[3]*self.colorRatio}
    end
    -- the background
    local outerBGColor=colorMult{0.25,0.10,0.04}
    love.graphics.setColor(outerBGColor)
    love.graphics.rectangle('fill',250,0,300,400) -- outer rectangle
    love.graphics.rectangle('fill',230,400,340,30) -- base of clock
    love.graphics.setColor(colorMult{0.15,0.07,0.02})
    love.graphics.rectangle('fill',300,100,200,250) -- inner rectangle
    love.graphics.setColor(colorMult{0.10,0.05,0.02})
    love.graphics.rectangle('line',300,100,200,250) -- darker sides of inner rectangle
    love.graphics.rectangle('fill',250,390,300,10) -- shadow of base
    love.graphics.rectangle('fill',230,430,340,10) -- shadow of base
    -- the pendulum
    love.graphics.setColor(colorMult{0.45,0.45,0.38})
    love.graphics.line(x1,y1,x2,y2)
    love.graphics.setColor(colorMult{0.25,0.25,0.08})
    love.graphics.circle("fill",x2,y2,40)
    -- the upper part of background should block the view of the pendulum
    love.graphics.setColor(outerBGColor)
    love.graphics.rectangle('fill',250,0,300,95)
    love.graphics.setColor(colorMult{0.5,.5,.5})
    love.graphics.draw(clockImage, clockQuad, 150,0,0,1,1)
    love.graphics.setLineWidth(width)
    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4])
end

BackgroundPattern.Pendulum=Pendulum

return BackgroundPattern