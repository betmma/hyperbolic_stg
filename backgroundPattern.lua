local BackgroundPattern=GameObject:extend()

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
BackgroundPattern.calculateSideLength=calculateSideLength

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

local function getSideFacePolygonVertices(x1,y1,x2,y2,sideNum,angleNum)
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
        local num=math.clamp(Shape.distance(x1,y1,x2,y2)/10,3,15)
        addVerticesOnSide(x1,y1,x2,y2,num)
        x1,y1=x2,y2
        x2,y2=Shape.rThetaPos(x2,y2,sideLength,alpha1)
    end
    return vertices
end

-- draw a face of a polygon. x1,y1,x2,y2: two points of the side. color: {r,g,b}. sideNum: how many sides do each polygon have. angleNum: how many sides are connected to each point.
-- bad: since a polygon is drawn once for each side, bigger sideNum causes a polygon to be drawn redundant sideNum/2 times. should be fixed with redundant removal in FixedTesselation (but not in MainMenuTesselation yet)
local function drawSideFace(vertices,color)
    local colorref={love.graphics.getColor()}
    love.graphics.setColor(color[1],color[2],color[3])
    -- without triangulate love.graphics.polygon("fill",vertices) is buggy at some concave part
    local ok, triangles = pcall(love.math.triangulate,vertices)
    if not ok then
        local stringVertices = ""
        for i = 1, #vertices, 2 do
            stringVertices = stringVertices .. "(" .. string.format("%.2f", vertices[i]) .. ", " .. string.format("%.2f", vertices[i + 1]) .. ") "
        end
        error("Error triangulating vertices: "..stringVertices..'\n'..triangles)
        return
    end
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
        local len=#sidesTable
        sidesTable[len+1]={point,newpoint,index=len+1}
        if len+1>=toDrawNum then
            break
        end
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
    if #sidesTable<toDrawNum and pointsQueue[drawedPointsNum]then 
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
-- local shader=love.graphics.newShader('shaders/triangleTextureDrawerVertex.glsl','shaders/triangleTextureDrawer.glsl')
local shader=ShaderScan:load_shader('shaders/flipTessellation.glsl')

-- a tesselation that moves and rotates. It's used in main menu.
local MainMenuTesselation=BackgroundPattern:extend()
function MainMenuTesselation:new(args)
    MainMenuTesselation.super.new(self,args)
    -- self.name='Tesselation'
    args=args or {}
    self.p=args.p or 2
    self.q=args.q or 5
    self.r=args.r or 5
    self.shader=shader
    self.uvPoses={{265/800,376/600},{534/800,376/600},{399/800,140/600}}
    -- self.uvPoses={{0.5-3^0.5/4,1},{0.5+3^0.5/4,1},{0.5,0}}
    self.frame=0
end

function MainMenuTesselation:update(dt)
    self.frame=self.frame+1
end

function MainMenuTesselation:randomize()
    local rand=math.random(1,3)
    self.uvPoses[rand],self.uvPoses[rand%3+1]=self.uvPoses[rand%3+1],self.uvPoses[rand] -- swap 2 random uvPoses
    local tried=0
    while tried<20 do
        local p=math.random(3,14)/2
        local q=math.random(3,14)/2
        local r=math.random(3,14)/2
        if 1/p+1/q+1/r<1 then
            self.p=p
            self.q=q
            self.r=r
            return
        end
        tried=tried+1
    end
end

-- local testImage = love.graphics.newImage( "assets/test.png" )
-- testImage:setWrap("repeat", "repeat") -- set texture to repeat so that it can be used in shader
function MainMenuTesselation:draw()
    local ay=Shape.axisY
    Shape.axisY=-2
    local width=love.graphics.getLineWidth()
    love.graphics.setLineWidth(10)
    love.graphics.setShader(self.shader)
    local uvPoses=self.uvPoses
    local t=self.frame/151
    local x,y=400+50*math.sin(t),300+220*math.cos(t)
    local V0,V1,V2=Shape.schwarzTriangleVertices(self.p,self.q,self.r,{x,y},self.frame/131)
    -- local V0 = {400, 300}
    -- local V1 = {500, 300}
    -- local V2 = {400, 400}
    shader:send("V0", V0)
    shader:send("V1", V1)
    shader:send("V2", V2)
    shader:send("tex_uv_V0", uvPoses[1])
    shader:send("tex_uv_V1", uvPoses[2])
    shader:send("tex_uv_V2", uvPoses[3])
    shader:send("shape_axis_y", Shape.axisY)
    -- love.graphics.draw(testImage, 0,0)
    love.graphics.draw(Asset.backgroundImage, 0,0)
    love.graphics.setShader()
    -- love.graphics.circle("fill",V0[1],V0[2],25)
    -- love.graphics.circle("fill",V1[1],V1[2],25)
    -- love.graphics.circle("fill",V2[1],V2[2],25)
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
    self.hashSet={}
    self.redundantCount=0
    for i=1,#self.sidesTable do
        local centerPos={getCenterOfPolygonWithSide(self.sidesTable[i][1].x,self.sidesTable[i][1].y,self.sidesTable[i][2].x,self.sidesTable[i][2].y,self.sideNum,self.angleNum)}
        local hashValue=Hash64(''..(math.floor(centerPos[1])*8)..(math.floor(centerPos[2])*8).."loool")
        local color={hashValue[3]/256,hashValue[1]/256,hashValue[2]/256}
        local hashValueInt=hashValue[1]+hashValue[2]*256+hashValue[3]*256*256+hashValue[4]*256*256*256
        -- print(i,centerPos[1],centerPos[2],hashValueInt)
        if self.hashSet[hashValueInt] then
            self.sidesTable[i].redundantFace=true
            self.redundantCount=self.redundantCount+1
        end
        self.hashSet[hashValueInt]=true
        self.sidesTable[i].color=color
        self.sidesTable[i][1]=copy_table(self.sidesTable[i][1]) -- without copying player's hyperbolic rotate can't retrieve the original position (i forgor why tho) and will crash after few frames
        self.sidesTable[i][2]=copy_table(self.sidesTable[i][2])
    end
    -- print(self.redundantCount..' sides: '..#self.sidesTable)
    self.sideLength=calculateSideLength(self.sideNum,self.angleNum)
end

function FixedTesselation:update(dt)
    -- fixed tesselation doesn't need to update
end

function FixedTesselation:draw()
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle('fill',0,0,800,600)
    love.graphics.setColor(1,1,1,1)
    local shader=love.graphics.getShader()
    Asset.setHyperbolicRotateShader() -- contains G.UseHypRotShader check
    local ay=Shape.axisY
    -- Shape.axisY=-10
    local width=love.graphics.getLineWidth()
    love.graphics.setLineWidth(10)
    local overallColorScale=self.overallColorScale
    local faceColorCoeff=self.faceColor
    if not self.dontDrawFaces then
        for i=1,#self.sidesTable do
            if self.sidesTable[i].redundantFace then
                goto continue
            end
            local color=self.sidesTable[i].color
            color={color[1]*faceColorCoeff[1],color[2]*faceColorCoeff[2],color[3]*faceColorCoeff[3]}
            color={color[1]*overallColorScale,color[2]*overallColorScale,color[3]*overallColorScale}
            local vertices=getSideFacePolygonVertices(self.sidesTable[i][1].x,self.sidesTable[i][1].y,self.sidesTable[i][2].x,self.sidesTable[i][2].y,self.sideNum,self.angleNum)
            drawSideFace(vertices,color)
            ::continue::
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
    love.graphics.setShader(shader)
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
        -- look i really dont understand why after pressing r to restart or restart in game end screen, there is only one object in Player.objects, but the target is still the old one, and target.removed is nil. so i have to check if target is Player.objects[1]
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
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle('fill',0,0,800,600) -- black background, without it part of border won't display due to background has alpha=0, and "add" blend mode doesn't change alpha

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

-- love2d draws a white rectangle then shader draws pattern.
local Shader=BackgroundPattern:extend()
---@class ShaderBackground
---@class love.Shader
---@class ShaderBackgroundArgs
---@field shader love.Shader the shader to use for drawing the background
---@field paramSendFunction fun(self:ShaderBackground,shader:love.Shader):nil a function to send parameters to the shader, called in Shader:draw()

---@param args ShaderBackgroundArgs
function Shader:new(args)
    Shader.super.new(self,args)
    args=args or {}
    self.shader=args.shader
    self.frame=0
    self.paramSendFunction=args.paramSendFunction or function(self,shader) end
end
function Shader:update(dt)
    self.frame=self.frame+1
end
function Shader:draw()
    local colorref={love.graphics.getColor()}
    love.graphics.setColor(1,1,1)
    -- love.graphics.rectangle('fill',0,0,800,600)
    love.graphics.setShader(self.shader)
    self:paramSendFunction(self.shader) -- send parameters to shader
    local translateX,translateY,scale=G:followModeTransform(true)
    love.graphics.rectangle('fill',-translateX/scale,-translateY/scale,800/scale,600/scale)
    love.graphics.setShader()
    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4])
end

BackgroundPattern.Shader=Shader

local plasmaGlobe=Shader:extend()
function plasmaGlobe:new(args)
    plasmaGlobe.super.new(self,args)
    args=args or {}
    self.shader=love.graphics.newShader('shaders/backgrounds/plasmaGlobe.glsl')
    -- Create iChannel0 (noise texture)
    local noiseSize = 256
    local imageData = love.image.newImageData(noiseSize, noiseSize)

    -- The shader samples .x and .yx from iChannel0, so we need at least two noise channels (R and G)
    imageData:mapPixel(function(x, y, r, g, b, a)
        local val1 = math.random() -- For .x component
        local val2 = math.random() -- For .y component (used in .yx)
        return val1, val2, 0, 1 -- Store in R and G channels
    end)
    local iChannel0 = love.graphics.newImage(imageData)
    iChannel0:setFilter("linear", "linear") -- ShaderToy textures usually have linear filtering
    iChannel0:setWrap("repeat", "repeat")   -- Important for noise sampling
    self.cameraAngleX = math.pi/4 -- Corresponds to yaw (left/right)
    self.cameraAngleY = 0.0 -- Corresponds to pitch (up/down)
    self.rotationSpeed = math.pi / 1.5 -- Radians per second, adjust for sensitivity
    self.paramSendFunction=function(self,shader)
        shader:send("iTime", love.timer.getTime())
        shader:send("iResolution", {love.graphics.getWidth(), love.graphics.getHeight()})
        
        shader:send("u_camAngleX", self.cameraAngleX)
        shader:send("u_camAngleY", self.cameraAngleY)

        shader:send("iChannel0", iChannel0)
    end
end
plasmaGlobe.update=function(self,dt)
    -- dt=0.005
    self.frame=self.frame+1
    -- if isDown("left") then
    --     self.cameraAngleX = self.cameraAngleX - self.rotationSpeed * dt
    -- end
    -- if isDown("right") then
    --     self.cameraAngleX = self.cameraAngleX + self.rotationSpeed * dt
    -- end
    -- if isDown("up") then
    --     self.cameraAngleY = self.cameraAngleY + self.rotationSpeed * dt
    -- end
    -- if isDown("down") then
    --     self.cameraAngleY = self.cameraAngleY - self.rotationSpeed * dt
    -- end
end
-- testShader.draw=function(self)
--     Shader.draw(self)
--     love.graphics.print(''..self.cameraAngleX..', '..self.cameraAngleY, 310, 100)
-- end
BackgroundPattern.PlasmaGlobe=plasmaGlobe

local fractalShader=love.graphics.newShader('shaders/backgrounds/fractal.glsl')
local Fractal=Shader:extend()
function Fractal:new(args)
    Fractal.super.new(self,args)
    args=args or {}
    self.shader=fractalShader
    local randomOffset=math.random(0,1000)
    self.paramSendFunction=function(self,shader)
        shader:send("iTime", love.timer.getTime()/3+randomOffset)
        shader:send("iResolution", {love.graphics.getWidth(), love.graphics.getHeight()})
    end
end
BackgroundPattern.Fractal=Fractal

-- tessellation on H^2 is calculated similar to main menu tessellation: calculate schwarz triangle vertices and send this fundamental triangle to shader. after flip, flip count and barycenter coordinates are used to calculate color and height.
-- due to high computation cost, this could only fit ending / credits
local H3TerrainShader=ShaderScan:load_shader('shaders/backgrounds/h3Terrain2.glsl')
local H3Terrain=Shader:extend()
function H3Terrain:new()
    H3Terrain.super.new(self)
    self.shader=H3TerrainShader
    self.cam_translation={0,0,1}
    self.cam_pitch=-0.5
    self.cam_yaw=0
    self.cam_roll=0
    self.p,self.q,self.r=3,6,6
    local V0,V1,V2=Shape.schwarzTriangleVertices(self.p,self.q,self.r,{0,-1},0)
    local length=Shape.distance(V0[1],V0[2],V1[1],V1[2])
    self.length=length
    self.moveLength=0.01
    local autoMove=false
    self.paramSendFunction=function(self,shader)
        local l=length-self.moveLength
        local x,y,dir=Shape.rThetaPosT(0,-99,l,0)
        -- dir=dir+(l>0 and math.pi or 0)
        local V0,V1,V2=Shape.schwarzTriangleVertices(self.p,self.q,self.r,{x,y},dir)
        local axisY=Shape.axisY
        V0[2]=V0[2]-axisY
        V1[2]=V1[2]-axisY
        V2[2]=V2[2]-axisY
        shader:send("V0", V0)
        shader:send("V1", V1)
        shader:send("V2", V2)
        shader:send("time", self.frame/60*1.8)
        local trans=self.cam_translation or {0,0,0}
        if autoMove then
            trans[3]=math.cos(self.frame/200)*-0.5+1.5
        end
        shader:send("cam_translation", trans)
        local pitch=self.cam_pitch or 0
        if autoMove then
            pitch=math.cos(self.frame/200)*-0.3-0.3
        end
        shader:send("cam_pitch", pitch)
        shader:send("cam_yaw", self.cam_yaw or 0)
        local roll=self.cam_roll or 0
        shader:send("cam_roll", roll)
        shader:send("flat_", true)
    end
end
H3Terrain.update=function(self,dt)
    local xyRange=1.5
    local xyStep=0.9*dt
    self.moveLength=(self.moveLength+0.3/(1+self.cam_translation[1]^2))%(self.length*2)
    self.frame=self.frame+1
    local keyIsDown=love.keyboard.isDown
    if keyIsDown("n") then
        self.cam_pitch = self.cam_pitch - dt
    end
    if keyIsDown("m") then
        self.cam_pitch = self.cam_pitch + dt
    end
    if keyIsDown("h") then
        self.cam_yaw = self.cam_yaw - dt
    end
    if keyIsDown("j") then
        self.cam_yaw = self.cam_yaw + dt
    end
    if keyIsDown("y") then
        self.cam_roll = self.cam_roll - dt
    end
    if keyIsDown("u") then
        self.cam_roll = self.cam_roll + dt
    end
    if keyIsDown("i") then
        self.cam_translation[3] = self.cam_translation[3] + dt
    end
    if keyIsDown("k") then
        self.cam_translation[3] = self.cam_translation[3] - dt
    end
    if Player.objects[1] then
        keyIsDown=Player.objects[1].keyIsDown -- nmhjyu aren't recorded in player, so these keys use love.keyboard.isDown. arrow keys use player to restore in replay
    end
    if keyIsDown("right") then
        self.cam_translation[1] = math.clamp(self.cam_translation[1] + xyStep,-xyRange,xyRange)
    end
    if keyIsDown("left") then
        self.cam_translation[1] = math.clamp(self.cam_translation[1] - xyStep,-xyRange,xyRange)
    end
    if keyIsDown("up") then
        self.cam_translation[2] = math.clamp(self.cam_translation[2] - xyStep,-xyRange,xyRange)
    end
    if keyIsDown("down") then
        self.cam_translation[2] = math.clamp(self.cam_translation[2] + xyStep,-xyRange,xyRange)
    end
end
BackgroundPattern.H3Terrain=H3Terrain

return BackgroundPattern