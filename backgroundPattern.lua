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

-- sideNum=5 angleNum=4 -> r=107
-- sideNum=4 angleNum=5 -> r=126.2
-- sideNum=3 angleNum=7 -> r=110
-- point: where pattern begins. angle: direction of first line. sideNum: useless now as I dunno how to calculate side length. angleNum: how many sides are connected to each point. iteCount: used for recursion. plz input 0. r: side length. drawedPoints: plz input {}. color: {r,g,b}
local function tesselation(point,angle,sideNum,angleNum,iteCount,r,drawedPoints,color)
    color=color or {0.7,0.2,0.5}
    local iteCount=(iteCount or 0)+1
    local points={}
    local r=r or 107--math.acosh(math.cos(math.pi/sideNum)/math.sin(math.pi/angleNum))*Shape.curvature
    drawedPoints=drawedPoints or {}
    local cic={Shape.getCircle(point.x,point.y,r)}
    -- love.graphics.print(''..cic[1]..', '..cic[2]..' '..cic[3],10,10)
    local begin=iteCount>1 and 2 or 1
    for i=begin,angleNum do
        local alpha=angle+math.pi*2/angleNum*(i-1)
        local ret={Shape.rThetaPos(point.x,point.y,r,alpha)}
        local newpoint={x=ret[1],y=ret[2]}
        points[#points+1]=newpoint
        -- SetFont(18)
        local flag=true
        local ratio=4.5
        for k,v in pairs(drawedPoints) do
            if ((point.x-v[1].x)^2+(point.y-v[1].y)^2+(newpoint.x-v[2].x)^2+(newpoint.y-v[2].y)^2)<ratio*point.y or ((point.x-v[2].x)^2+(point.y-v[2].y)^2+(newpoint.x-v[1].x)^2+(newpoint.y-v[1].y)^2)<ratio*point.y then
                flag=false
                break
            end
        end
        if flag then
            table.insert(drawedPoints,{point,newpoint})
            local colorref={love.graphics.getColor()}
            love.graphics.setColor(color[1],color[2],color[3])
            PolyLine.drawOne(point,newpoint)
            love.graphics.setColor(0.35,0.15,0.8)
            PolyLine.drawOne({x=point.x+1,y=point.y+1},{x=newpoint.x+1,y=newpoint.y+1})
            love.graphics.setColor(colorref[1],colorref[2],colorref[3])
        end
        -- Shape.drawLine(point.x,point.y,newpoint.x,newpoint.y)
        -- love.graphics.print(''..newpoint.x..', '..newpoint.y..' '..alpha..' '..ret[3],10,10+50*i)
    end
    if iteCount==4 then return {},{} end
    local angles={}
    for i=1,#points do
        local newpoint=points[i]
        local newangle=Shape.to(newpoint.x,newpoint.y,point.x,point.y)
        table.insert(angles,newangle)
        tesselation(newpoint,newangle,sideNum,angleNum,iteCount,r,drawedPoints,color)
    end
    return points,angles
end


local Tesselation=BackgroundPattern:extend()
function Tesselation:new(args)
    Tesselation.super.new(self,args)
    -- self.name='Tesselation'
    args=args or {}
    self.point=args.point or {x=400,y=150}
    self.limit=args.limit or {xmin=300,xmax=500,ymin=150,ymax=600}
    self.angle=args.angle or math.pi/3
    self.speed=args.speed or 0.0045
end

function Tesselation:update(dt)
    local ay=Shape.axisY
    Shape.axisY=-30
    local newpoint,newAngle=self.newPoints or {self.point},self.newAngles or {self.angle}
    -- if the current point is out of limit, find a new point from the drawn points (so that it seems like an infinite pattern)
    if not math.inRange(self.point.x,self.point.y,self.limit.xmin,self.limit.xmax,self.limit.ymin,self.limit.ymax)  then
        for i=1,#newpoint do
            if math.inRange(newpoint[i].x,newpoint[i].y,self.limit.xmin,self.limit.xmax,self.limit.ymin,self.limit.ymax) then
                self.point=newpoint[i]
                self.angle=newAngle[i]
            end
        end
    end
    self.point={x=self.point.x-(self.point.x-400)*self.speed,y=self.point.y-(self.point.y-Shape.axisY)*self.speed}
    self.angle=self.angle+0.004
    Shape.axisY=ay
end

function Tesselation:draw()
    local ay=Shape.axisY
    Shape.axisY=-30
    -- tesselation({x=self.point.x+1,y=self.point.y+1},self.angle,5,5,0,126.2,{},{0.35,0.15,0.8})
    self.newPoints,self.newAngles=tesselation(self.point,self.angle,5,5,0,126.2,{},{0.7,0.2,0.5})
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
    self:drawOne(self.radius,self.angle)
    self:drawOne((self.radius+35)%self.radiusMax,self.angle)
    love.graphics.setColor(colorref[1],colorref[2],colorref[3])
end

BackgroundPattern.Square=Square

return BackgroundPattern