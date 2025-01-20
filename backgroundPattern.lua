local Object=require 'classic'
local BackgroundPattern=Object:extend()

-- BackgroundPattern is an abstract class that needs implementation of:
-- 1. new(args): initialize the background pattern.
-- 2. update(dt): update the background pattern, called in love.update(dt)
-- 3. draw(): draw the background pattern, called in love.draw()
-- It will be bound to G and called in G.update and G.draw.
function BackgroundPattern:new(args)

end

local Empty=BackgroundPattern:extend()
function Empty:new(args)
    Empty.super.new(self,args)
end
BackgroundPattern.Empty=Empty

local sideLengthCache={}
local calculateSideLength=function(sideNum,angleNum)
    if sideLengthCache[sideNum] and sideLengthCache[sideNum][angleNum] then
        return sideLengthCache[sideNum][angleNum]
    end
    local centerToVertex=(math.sqrt((math.tan(math.pi/2-math.pi/angleNum)-math.tan(math.pi/sideNum))/(math.tan(math.pi/2-math.pi/angleNum)+math.tan(math.pi/sideNum)))) -- reference: https://www.malinc.se/noneuclidean/en/poincaretiling.php. sideNum->p, angleNum->q. actually this radius is on a poincare disk
    local x1,y1=centerToVertex,0
    local x2,y2=centerToVertex*math.cos(math.pi*2/sideNum),centerToVertex*math.sin(math.pi*2/sideNum)
    local d=2*math.distance(x1,y1,x2,y2)^2/(1-centerToVertex^2)^2
    local ret= math.acosh(1+d)*Shape.curvature
    sideLengthCache[sideNum]=sideLengthCache[sideNum] or {}
    sideLengthCache[sideNum][angleNum]=ret
    return ret
end

local fourFiveLength=calculateSideLength(4,5)

-- point: where pattern begins. angle: direction of first line. sideNum: useless now as I dunno how to calculate side length. angleNum: how many sides are connected to each point. iteCount: used for recursion. plz input 0. r: side length. color: {r,g,b}. leftMost: input nil.
-- currently it's only used to draw {4,5} tesselation. Upon inspecting the tesselation, I found a non-overlapping way to draw it: at depth 0, extend 5 branches, at depth 1, extend 3 branches (excluding the rightmost one and the one it comes from), at depth >=2, if the point is marked as the leftmost branch of last depth, don't extend the first branch (but this line should be drawn). Such specific implementation makes it not able to draw other tesselations :(.
local drawedPointsNum=0
local pointsQueue={}
local function tesselation(point,angle,sideNum,angleNum,iteCount,color,leftMost, centerPoint, toDrawNum)
    color=color or {0.7,0.2,0.5}
    centerPoint=centerPoint or point
    if iteCount==0 then
        drawedPointsNum=0
        pointsQueue={}
    end
    local iteCount=(iteCount or 0)+1
    local points={}
    local r=calculateSideLength(sideNum,angleNum)
    local cic={Shape.getCircle(point.x,point.y,r)}
    -- love.graphics.print(''..cic[1]..', '..cic[2]..' '..cic[3],10,10)
    local begin=1
    local en=angleNum--iteCount>1 and angleNum-2 or angleNum

    drawedPointsNum=drawedPointsNum+1
    local distance0=Shape.distance(point.x,point.y,centerPoint.x,centerPoint.y)
    for i=begin,en do
        if not math.inRange(point.x,point.y,-400,1200,-5,4000) then
            break
        end
        local alpha=angle+math.pi*2/angleNum*(i)
        local ret={Shape.rThetaPos(point.x,point.y,r,alpha)}
        local newpoint={x=ret[1],y=ret[2]}
        local distance=Shape.distance(newpoint.x,newpoint.y,centerPoint.x,centerPoint.y)
        if distance<distance0 and (distance0-distance>Shape.EPS*10 or alpha%(math.pi*2)>math.pi) then
            goto continue
        end
        points[#points+1]=newpoint
        -- SetFont(18)
            -- table.insert(drawedPoints,{point,newpoint})
            local colorref={love.graphics.getColor()}
            love.graphics.setColor(color[1],color[2],color[3])
            local num=math.ceil(math.min(25,Shape.distance(point.x,point.y,newpoint.x,newpoint.y)/10))
            Shape.drawSegment(point.x,point.y,newpoint.x,newpoint.y,num)
            love.graphics.setColor(0.35+iteCount*.04,0.15,0.8)
            Shape.drawSegment(point.x+1,point.y+1,newpoint.x+1,newpoint.y+1,num)
            love.graphics.setColor(colorref[1],colorref[2],colorref[3])
        -- Shape.drawLine(point.x,point.y,newpoint.x,newpoint.y)
        -- love.graphics.print(''..newpoint.x..', '..newpoint.y..' '..alpha..' '..ret[3],10,10+50*i)
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
    for i=1,#points do
        local newpoint=points[i]
        local newangle=Shape.to(newpoint.x,newpoint.y,point.x,point.y)
        table.insert(angles,newangle)
        pointsQueue[#pointsQueue+1]={newpoint,newangle,iteCount}
        -- tesselation(newpoint,newangle,sideNum,angleNum,iteCount,color,i==1,centerPoint)
    end
    if drawedPointsNum<toDrawNum/angleNum and pointsQueue[drawedPointsNum]then 
        tesselation(pointsQueue[drawedPointsNum][1],pointsQueue[drawedPointsNum][2],sideNum,angleNum,pointsQueue[drawedPointsNum][3],color,true,centerPoint,toDrawNum)
    else
        pointsQueue={}
    end

    return points,angles
end

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

local Tesselation=BackgroundPattern:extend()
function Tesselation:new(args)
    Tesselation.super.new(self,args)
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

function Tesselation:update(dt)
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

function Tesselation:draw()
    local ay=Shape.axisY
    Shape.axisY=-10
    -- tesselation({x=self.point.x+1,y=self.point.y+1},self.angle,5,5,0,126.2,{},{0.35,0.15,0.8})
    local width=love.graphics.getLineWidth()
    love.graphics.setLineWidth(10)
    self.newPoints,self.newAngles=tesselation(self.point,self.angle,self.sideNum,self.angleNum,0,{0.7,0.2,0.5},nil,nil,800)
    love.graphics.setLineWidth(width)
    Shape.axisY=ay
end

BackgroundPattern.Tesselation=Tesselation

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

return BackgroundPattern