--! file: circle.lua
local Shape = require "shape"
---@class Point:Shape
local Point = Shape:extend()

function Point:new(x, y,draw)
    self.doDraw=draw==nil and true or draw
    Point.super.new(self, {x=x, y=y})
end

function Point:draw()
    if not self.doDraw or PolyLine.useMesh==true then
        return
    end
    love.graphics.circle("line", self.x, self.y, 1) -- 1 px
end

-- Warning: points must form a convex polygon
---@class PolyLine:GameObject
---@field points Point[]
---@field color number[]|nil
---@field width number|nil
---@field sprite Sprite
---@field spriteTransparency number
---@field doDraw boolean
---@field faceColorRatio number|nil
---@field drawFace boolean|nil
local PolyLine=GameObject:extend()
PolyLine.Point=Point
PolyLine.useMesh=true -- use mesh to draw polyline
function PolyLine:new(points,draw)
    self.doDraw=draw==nil and true or draw
    self.points={}
    for key, value in pairs(points) do
        self.points[#self.points+1] = Point(value[1],value[2],self.doDraw)
    end
    self.sprite=BulletSprites.laser.white
    self.spriteTransparency=1
end

function PolyLine:replacePoints(points)
    local lenOriginal=#self.points
    local lenNew=#points
    for key, value in pairs(points) do
        if self.points[key]==nil then
            self.points[key]=Point(value[1],value[2],self.doDraw)
        else
            self.points[key].x=value[1]
            self.points[key].y=value[2]
        end
    end
    for i=lenNew+1,lenOriginal do
        self.points[i]:remove()
        self.points[i]=nil
    end
end

-- assume that points are given by increasing polar angle (so each point should be right to previous line)
function PolyLine:inside(xc,yc)
    local itenum=#self.points
    if itenum==2 then
        itenum=1
    end
    for i=1,itenum do
        if not self:insideOne(xc,yc,i) then
            return false,self.points[i].x,self.points[i].y,self.points[i%#self.points+1].x,self.points[i%#self.points+1].y
        end
    end
    return true
end

function PolyLine:insideOne(xc,yc,index)
    return not Shape.leftToLine(xc,yc,self.points[index].x,self.points[index].y,self.points[index%#self.points+1].x,self.points[index%#self.points+1].y)
end

-- obj should include x, y and direction. This function modifies obj.
-- usage example: adding a LoopEvent with condition = not polyline:inside(obj) and execute func = polyline:reflection(obj)
function PolyLine:reflection(obj)
    local inside,x1,y1,x2,y2=self:inside(obj.x,obj.y)
    if inside then
        return
    end
    if math.abs(x1-x2)<Shape.EPS then -- vertical
        obj.x=2*x1-obj.x
        obj.direction=-obj.direction
    end
    local centerX,radius=Shape.lineCenter(x1,y1,x2,y2)
    local direction=math.atan2(obj.y-Shape.axisY,obj.x-centerX)
    local r2=radius*2-math.distance(obj.x,obj.y,centerX,Shape.axisY)
    obj.x,obj.y=centerX+r2*math.cos(direction),Shape.axisY+r2*math.sin(direction)
    obj.direction=2*direction-obj.direction+math.pi
end

function PolyLine:draw()
    if not self.doDraw then
        return
    end
    if self.useMesh==true then
        local poses=self:getMeshPoses()
        self:drawMesh(poses)
        if self.drawFace then
            if G.viewMode.hyperbolicModel==G.CONSTANTS.HYPERBOLIC_MODELS.UHP then
                self:drawFaceMeshUHP()
            else
                self:drawFaceMesh(poses)
            end
        end
    else
        self:drawRaw()
    end
end

function PolyLine:drawRaw()
    local itenum=#self.points
    if itenum==2 then
        itenum=1
    end
    for i=1,itenum do
        self.drawOne(self.points[i],self.points[i%#self.points+1])
    end
end

-- draw line segment from (p1.x,p1.y) to (p2.x,p2.y)
function PolyLine.drawOne(p1,p2)
    local x1=p1.x
    local y1=p1.y
    local x2=p2.x
    local y2=p2.y
    Shape.drawSegment(x1,y1,x2,y2)
end

function PolyLine:getMeshPoses(points)
    points=points or self.points
    local width=self.width or 1
    local poses={}
    local itenum=#points
    if itenum==2 then
        itenum=1
    end
    for i=1,itenum do
        local x1,y1,x2,y2=points[i].x,points[i].y,points[i%#points+1].x,points[i%#points+1].y
        local distance=Shape.distance(x1,y1,x2,y2)
        local direction=Shape.to(x1,y1,x2,y2)
        local maxDist=5
        local maxMiddlePoints=40
        local middlePoints=math.min(math.ceil(distance/maxDist),maxMiddlePoints)
        local middleDistance=distance/middlePoints
        for j=0,middlePoints do
            local distanceToMiddle=j*middleDistance
            local mx,my,mdir=Shape.rThetaPosT(x1,y1,distanceToMiddle,direction)
            -- calculate edge position (approximately. note below is using math.rThetaPos not Shape.rThetaPos)
            local mwidth=width*my/Shape.curvature
            local mx1,my1=math.rThetaPos(mx,my,mwidth,mdir+math.pi/2)
            local mx2,my2=math.rThetaPos(mx,my,mwidth,mdir-math.pi/2)
            poses[#poses+1]={mx1,my1}
            poses[#poses+1]={mx2,my2}
        end
    end
    return poses
end

function PolyLine:drawMesh(poses)
    poses=poses or self:getMeshPoses()
    local vertices={}
    local x,y,w,h=love.graphics.getQuadXYWHOnImage(self.sprite.quad,Asset.bulletImage)
    local r,g,b=1,1,1
    if self.color then
        r,g,b=self.color[1],self.color[2],self.color[3]
    end
    for i=1,#poses,2 do
        table.insert(vertices,{poses[i][1],poses[i][2], x, y, r, g, b, self.spriteTransparency or 1})
        table.insert(vertices,{poses[i+1][1],poses[i+1][2], x+w, y+h, r, g, b, self.spriteTransparency or 1})
    end
    if #vertices<4 then return end
    local mesh=love.graphics.newMesh(vertices,'strip')
    mesh:setTexture(Asset.bulletImage)
    Asset.laserMeshes:add(mesh)
end

-- find the center of points in klein disk. not actually the center, but a point inside the polygon.
function PolyLine:centerOfPoints(points)
    points=points or self.points
    local centerX,centerY=0,0
    for key, value in pairs(points) do
        local x,y=value.x,value.y
        x,y=Shape.screenPosition(x,y,G.CONSTANTS.HYPERBOLIC_MODELS.K_DISK)
        centerX=centerX+x
        centerY=centerY+y
    end
    centerX=centerX/#points
    centerY=centerY/#points
    centerX,centerY=Shape.inverseScreenPosition(centerX,centerY,G.CONSTANTS.HYPERBOLIC_MODELS.K_DISK)
    return centerX,centerY
end

-- fill whole area. first get outer points from original mesh (even index), then add center point to form a fan mesh. note that there could be visual artifacts in UHP model when area is large, due to possible concave shape. this function is rarely used, as boundary normally doesnt need to be filled. currently only used in 11-10 to draw laser area.
function PolyLine:drawFaceMesh(poses,center)
    poses=poses or self:getMeshPoses()
    -- first find a point inside the area to form a fan mesh
    local centerX,centerY=0,0
    if center then
        centerX,centerY=center.x,center.y
    else
        centerX,centerY=self:centerOfPoints()
    end
    local r,g,b=1,1,1
    if self.color then
        r,g,b=self.color[1],self.color[2],self.color[3]
    end
    if self.faceColorRatio then
        r,g,b=r*self.faceColorRatio,g*self.faceColorRatio,b*self.faceColorRatio
    end
    local x,y,w,h=love.graphics.getQuadXYWHOnImage(self.sprite.quad,Asset.bulletImage)
    local areaVertices={{centerX,centerY,x+w/2,y+h,r,g,b,1}}
    for i=2,#poses,2 do
        local parity=i%4==2 and 1 or 0
        table.insert(areaVertices,{poses[i][1],poses[i][2],x+w*parity,y,r,g,b,1})
    end
    table.insert(areaVertices,{poses[2][1],poses[2][2],x+w,y,r,g,b,1})
    local mesh=love.graphics.newMesh(areaVertices,'fan')
    mesh:setTexture(Asset.bulletImage)
    Asset.laserMeshes:add(mesh)
end

-- polygon in UHP is very likely to be concave due to small and curly angle. the solution is to find and cut small angles, then draw them separately. this function is expensive.
function PolyLine:drawFaceMeshUHP()
    local points=self.points
    local cutTriangles={}
    local remainingPoints={}
    local cutRatio=0.4
    for key, value in pairs(points) do
        local x2,y2=value.x,value.y
        local x3,y3=points[key%#points+1].x,points[key%#points+1].y
        local x1,y1=points[(key-2)%#points+1].x,points[(key-2)%#points+1].y
        local angle=Shape.to(x2,y2,x1,y1)-Shape.to(x2,y2,x3,y3)
        if angle<math.pi/4 then
            -- cut at cutRatio of side length
            local cutX12,cutY12=Shape.rThetaPos(x2,y2,Shape.distance(x1,y1,x2,y2)*cutRatio,Shape.to(x2,y2,x1,y1))
            local cutX23,cutY23=Shape.rThetaPos(x2,y2,Shape.distance(x3,y3,x2,y2)*cutRatio,Shape.to(x2,y2,x3,y3))
            cutTriangles[#cutTriangles+1]={{x=x2,y=y2},{x=cutX12,y=cutY12},{x=cutX23,y=cutY23}}
            remainingPoints[#remainingPoints+1]={x=cutX12,y=cutY12}
            remainingPoints[#remainingPoints+1]={x=cutX23,y=cutY23}
        else
            remainingPoints[#remainingPoints+1]={x=x2,y=y2}
        end
    end
    for key, value in pairs(cutTriangles) do
        local centerX,centerY=self:centerOfPoints(value)
        self:drawFaceMesh(self:getMeshPoses(value),{x=centerX,y=centerY})
    end
    self:drawFaceMesh(self:getMeshPoses(remainingPoints))
end

function PolyLine:remove()
    PolyLine.super.remove(self)
    for key, value in pairs(self.points) do
        value:remove()
    end
end
function PolyLine:drawAll()
    for key, obj in pairs(self.objects) do
        obj:draw()
    end
end
return PolyLine