-- Laser is composed of many small units. For each 2 adjacent unit, use Mesh to draw Laser sprite quad between them. When a laser is generated, it has x, y, radius, lifeFrame, sprite, direction and speed parameters (same as circle). During lifeFrame time, it needs to generate units at a frequency of [freq] (be determined based on speed). Each unit is a circle with speed=speed and direction=direction. 
local Laser=Shape:extend()
local LaserUnit=Circle:extend()
Laser.LaserUnit=LaserUnit

function LaserUnit:new(args)
    LaserUnit.super.new(self, args)
    self.radiusRef=self.radius
    self.previous=nil
    self.next=nil
    self.interpolateLimit=args.interpolateLimit
    self.meshVerticesInitSize=100
end
local function sigmoid(x)
    return 1/(1+2.718^-x)
end

function LaserUnit:update(dt)
    LaserUnit.super.update(self,dt)
    self:updateWarningAndFading(self.parent or {})
end

function LaserUnit:updateWarningAndFading(parent)
    if parent.enableWarningAndFading then
        if parent.frame<parent.warningFrame or parent.frame>parent.lifeFrame-parent.fadingFrame then
            self.safe=true
        else
            self.safe=false
        end
        self.radius=math.max(self.radiusRef*sigmoid(parent.frame-parent.warningFrame),0.1)*sigmoid(-parent.frame+parent.lifeFrame-parent.fadingFrame)
    end
end

function LaserUnit:drawSprite()
    -- LaserUnit.super.drawSprite(self)
end

function LaserUnit:draw()
    if not self.previous or self.previous.removed then
        self:drawMesh()
    end
end

-- extract coordinates of all LaserUnits linked. Each unit yields 2 points that are perpendicular to its direction.
-- for example: 
-- v v v
---o-o-o---->
-- ^ ^ ^
function LaserUnit:extractCoordinates()
    local poses = {}
    local unit = self
    while unit and not unit.removed do
        local nextUnit=unit.next
        local the
        if nextUnit then
            the=Shape.toObj(unit,nextUnit)-math.pi/2
        elseif unit.previous then
            the=Shape.toObj(unit,unit.previous)+math.pi/2
        else
            the=unit.direction+math.pi/2+(unit.deltaOrientation or 0)
        end
        local x1, y1, r1 = Shape.getCircle(unit.x, unit.y, unit.radius)
        r1 = self.sprite.data.sizeX / 2 * r1 / self.sprite.data.hitRadius
        table.insert(poses, {x1+r1*math.cos(the),y1+r1*math.sin(the)})
        table.insert(poses, {x1-r1*math.cos(the),y1-r1*math.sin(the)})
        unit = unit.next
    end
    -- if poses only has 2 points, then it's a point laser, so add 2 more points to make it a line segment
    if #poses==2 then
        poses={}
        unit=self
        local x1, y1, r1 = Shape.getCircle(unit.x, unit.y, unit.radius)
        r1 = self.sprite.data.sizeX / 2 * r1 / self.sprite.data.hitRadius
        r1 = r1 * 2^0.5
        local the=unit.direction+math.pi/4
        for i=1,4 do
            table.insert(poses, {x1+r1*math.cos(the),y1+r1*math.sin(the)})
            the=the+math.pi/2
        end
        poses[3],poses[4]=poses[4],poses[3] -- due to mesh drawing, the order of points should be 1,2,4,3
    end

    -- if gap between units is too large, add more points to make it smooth (hyperbolic line is arc, while mesh is line segment)
    local newPoses={}
    for i=1,#poses,2 do
        table.insert(newPoses,poses[i])
        table.insert(newPoses,poses[i+1])
        if i+2<=#poses then
            local x1,y1,x2,y2=poses[i][1],poses[i][2],poses[i+2][1],poses[i+2][2]
            local x3,y3,x4,y4=poses[i+1][1],poses[i+1][2],poses[i+3][1],poses[i+3][2]
            --[[ like this:
            x1,y1            x2,y2
              o-xc1,yc1--------o-xc2,yc2
            x3,y3            x4,y4

            should use xc1,yc1 and xc2,yc2 to calculate middle points, not x1,y1 and x2,y2 (or x3,y3 and x4,y4) because when distance is large (same magnitude as curvature), the edge of laser can't be considered a straight line. If do so the laser at middle part will be much thinner than edge part.
            ]]
            local xc1,yc1,xc2,yc2=0.5*(x1+x3),0.5*(y1+y3),0.5*(x2+x4),0.5*(y2+y4)
            local dis=Shape.distance(xc1,yc1,xc2,yc2)
            local splitLength=10
            local segMax=self.interpolateLimit or 10 -- at most self.interpolateLimit or 10 points
            -- if G.viewMode.mode==G.VIEW_MODES.FOLLOW then
            --     local viewer=G.viewMode.object
            --     local toViewerDistance=Shape.distance(xc1,yc1,viewer.x,viewer.y)
            --     local toViewerDistance2=Shape.distance(xc2,yc2,viewer.x,viewer.y)
            --     local minDistance=math.min(toViewerDistance,toViewerDistance2)
            --     if minDistance>splitLength*segMax then
            --         splitLength=splitLength*segMax -- reduce not important points cuz it's away from player
            --     end
            -- end
            if dis>splitLength then
                local the=Shape.to(xc1,yc1,xc2,yc2)
                local r1=Shape.distance(x1,y1,xc1,yc1)
                local dtheta1=math.modClamp(Shape.to(xc1,yc1,x1,y1)-the)
                local r2=Shape.distance(x2,y2,xc2,yc2) 
                local dtheta2=math.modClamp(Shape.to(xc2,yc2,x2,y2)-Shape.to(xc2,yc2,xc1,yc1)+math.pi,math.pi/2,math.pi)
                local num=math.min(math.ceil(dis/splitLength),segMax)
                for j=1,num-1 do
                    local nx,ny=Shape.rThetaPos(xc1,yc1,dis/num*j,the)
                    local the2=Shape.to(nx,ny,xc2,yc2)
                    local rj=r1+(r2-r1)/dis*j
                    local dthetaj=dtheta1+math.modClamp(dtheta2-dtheta1,0,math.pi)/num*j
                    local nx2,ny2=Shape.rThetaPos(nx,ny,rj,the2+dthetaj)
                    table.insert(newPoses,{nx2,ny2})
                    nx2,ny2=Shape.rThetaPos(nx,ny,rj,the2+dthetaj+math.pi)
                    table.insert(newPoses,{nx2,ny2})
                end
            end

        end
    end
    return newPoses
end

function LaserUnit:drawMesh(poses)
    poses=poses or self:extractCoordinates()
    local vertices={}
    local x,y,w,h=love.graphics.getQuadXYWHOnImage(self.sprite.quad,Asset.bulletImage)
    for i=1,#poses,2 do
        table.insert(vertices,{poses[i][1],poses[i][2], x, y, 1, 1, 1, self.spriteTransparency or 1})
        table.insert(vertices,{poses[i+1][1],poses[i+1][2], x+w, y+h, 1, 1, 1, self.spriteTransparency or 1})
    end
    if #vertices<4 then return end
    if not self.mesh then
        self.mesh=ExpandingMesh(self.meshVerticesInitSize,'strip')
        self.mesh:setTexture(Asset.bulletImage)
    end
    self.mesh:setVertices(vertices)
    Asset.laserMeshes:add(self.mesh.mesh)
    -- love.graphics.draw(mesh)
end

-- use the line segment between self and self.previous to check if player is hit by laser. Circle check can cause safe spot inside laser.
function LaserUnit:checkHitPlayer()
    if not self.safe and self.previous and not self.previous.removed then
        local x1,y1,x2,y2=self.x,self.y,self.previous.x,self.previous.y
        local grazeFunction,hitFunction
        if math.abs(x1-x2)<Shape.EPS then --vertical
            grazeFunction=function(player)
                local x,y=player.x,player.y
                return math.abs(x-x1)<self.radius+player.radius*player.grazeRadiusFactor and (y1<=y and y<=y2 or y2<=y and y<=y1)
            end
            hitFunction=function(player)
                local x,y=player.x,player.y
                return math.abs(x-x1)<self.radius+player.radius and (y1<=y and y<=y2 or y2<=y and y<=y1)
            end
        else
            grazeFunction=function(player)
                local x,y=player.x,player.y
                return Shape.distanceToSegment(x,y,x1,y1,x2,y2)<self.radius+player.radius*player.grazeRadiusFactor
            end
            hitFunction=function(player)
                local x,y=player.x,player.y
                return Shape.distanceToSegment(x,y,x1,y1,x2,y2)<self.radius+player.radius
            end
        end
        for key, player in pairs(Player.objects) do
            if grazeFunction(player) and not self.grazed then
                EventManager.post(EventManager.EVENTS.PLAYER_GRAZE,player)
                self.grazed=true
            end
            if player.invincibleTime<=0 and hitFunction(player) then
                EventManager.post(EventManager.EVENTS.PLAYER_HIT,player,self.damage or 1)
            end
        end
    end
end

-- Note that warningFrame and fadingFrame is binded to Laser object's existence and lifeFrame, so for fast lasers these two parameters could be used, while for slow (usually curly and not long enough to go through screen) lasers shouldn't be set to nonzero, otherwise before actual laser reaches player it's warningFrame ends, and soon the Laser object is removed and actual laser will fade out.
-- Laser is actually a special bulletSpawner but it doesn't inherit bulletSpawner class yet (maybe I'll change). When creating its args are like normal bullets so args.direction and speed are actually for LaserUnits, so directly inheriting bulletSpawner (or shape) will cause it to move. [LaserEvents] are Laser object's events, while [bulletEvents] are LaserUnit's events.
-- To prevent unintended safe spot inside the laser, when enableWarningAndFading is true the speed of LaserUnits is added 1% of randomness. (this is before I added line segment check for player hit, so now it's not needed, for old replays I still keep it)
function Laser:new(args)
    Laser.super.new(self,args)
    self.radius=args.radius or 1
    self.args=copy_table(args)
    self.lifeFrame=args.lifeFrame or 100
    self.warningFrame=args.warningFrame or 0
    self.fadingFrame=args.fadingFrame or 0
    self.enableWarningAndFading=(args.warningFrame~=nil and args.warningFrame~=0 or args.fadingFrame~=nil and args.fadingFrame~=0)
    self.smoothFrame=args.smoothFrame or 0
    self.smooth=not self.enableWarningAndFading and self.smoothFrame>0
    args.lifeFrame=9999
    args.batch=args.batch or Asset.bulletHighlightBatch
    self.frame=0
    self.laserEvents=args.laserEvents or {}
    self.bulletEvents=args.bulletEvents or {}
    self.units={}
    self.frequency=args.frequency or math.ceil(200/args.speed)
    self.spawnEvent=Event.LoopEvent{
        obj=self,
        period=self.frequency,
        executeFunc=function()
            args.direction=math.eval(self.args.direction)
            args.speed=math.eval(self.args.speed)
            args.x=self.x
            args.y=self.y
            if self.enableWarningAndFading and G.replay and isVersionSmaller(G.replay.version,'0.2.8.7') then
                args.speed=args.speed*math.eval(1,0.01)
            end
            if self.smooth then
                args.radius=self.radius*sigmoid(self.frame/self.smoothFrame-1)*sigmoid((self.lifeFrame-self.frame)/self.smoothFrame-1)
            end
            local cir=LaserUnit(args)
            cir.index=self.spawnEvent.executedTimes
            cir:updateWarningAndFading(self)
            cir.last=true
            cir.parent=self
            if #self.units>0 then
                cir.previous=self.units[#self.units]
                self.units[#self.units].next=cir
                cir.previous.last=false
            end
            table.insert(self.units,cir)
            -- table.insert(ret,cir)
            for key, func in pairs(self.bulletEvents) do
                func(cir,args,self)
            end
        end
    }
    for key, func in pairs(self.laserEvents) do
        func(self,args)
    end
end

function Laser:update(dt)
    self.frame=self.frame+1
    if self.frame>self.lifeFrame then
        self:remove()
    end
    for k,shockwave in pairs(Effect.Shockwave.objects) do
        if shockwave.canRemove.bulletSpawner or (self.args.canRemovedByBulletRemover and shockwave.canRemove.bullet) and Shape.distance(shockwave.x,shockwave.y,self.x,self.y)<shockwave.radius+self.radius then
            self:remove()
        end
    end
end

return Laser