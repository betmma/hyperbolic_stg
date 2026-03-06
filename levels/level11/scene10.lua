return {
    ID=125,
    user='renko',
    spellName='High-Energy "Rotational Collimator"',
    unlock=function()
        return Nickname.hasSecretNicknameForAct(11)
    end,
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1000
        local player=Player{x=400,y=600}
        local en
        local makeCore
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            Event.DelayEvent{
                obj=en,delayFrame=60,executeFunc=function()
                    SFX:play('enemyPowerfulShot',true)
                    makeCore(2,0.8)
                end
             }
            en:addHPProtection(600,10)
        end}
        en:addHPProtection(600,10)
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,100,12))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local twopi=math.pi*2
        -- should not make it inherit Object since huge number of AngleIntervals is needed and need manual cleanup.
        ---@alias AngleIntervals {start:number,ending:number}[]
        local AngleIntervals={}
        function AngleIntervals.new(start,ending)
            local twopis=math.floor(start/twopi)
            start=start-twopis*twopi
            ending=ending-twopis*twopi
            if ending<=twopi then
                return {{start=start,ending=ending}}
            elseif ending>start+twopi then
                return {{start=0,ending=twopi}}
            else
                return {{start=0,ending=ending-twopi},{start=start,ending=twopi},}
            end
        end
        function AngleIntervals:intersect(other)
            AngleIntervals.unwrap(self)
            AngleIntervals.unwrap(other)
            local newIntervals={}
            local index1,index2=1,1
            while index1<=#self and index2<=#other do
                local int1=self[index1]
                local int2=other[index2]
                local newStart=math.max(int1.start,int2.start)
                local newEnding=math.min(int1.ending,int2.ending)
                if newStart<newEnding then
                    table.insert(newIntervals,{start=newStart,ending=newEnding})
                end
                if int1.ending<int2.ending then
                    index1=index1+1
                else
                    index2=index2+1
                end
            end
            return newIntervals
        end
        -- merge first and last interval if they are connected. 
        function AngleIntervals:wrap()
            if #self>=2 and self[1].start==0 and self[#self].ending==twopi then
                self[1].start=self[#self].start-twopi
                table.remove(self)
            end
        end

        function AngleIntervals:unwrap()
            if #self>=1 and self[1].start<0 then
                self[#self+1]={start=self[1].start+twopi,ending=twopi}
                self[1].start=0
            end
        end
        function AngleIntervals:inside(angle)
            angle=angle%twopi
            for _,interval in ipairs(self) do
                if interval.start<=angle and angle<=interval.ending then
                    return true
                end
            end
            return false
        end

        local layerTypes={AIMING=1,ROTATING=2}
        ---@class Layer:Object
        ---@field core Core
        ---@field type integer
        ---@field angle number
        ---@field gap number
        ---@field rotateSpeed number
        ---@field radius number
        ---@field revealIntervals AngleIntervals
        local Layer=Object:extend()
        function Layer:new(core,type,angle,gap,speed,radius)
            self.core=core
            self.type=type
            self.angle=angle
            self.gap=gap
            self.rotateSpeed=speed
            self.radius=radius
            self.bullets={}
            local fillAngle=math.pi*2-gap
            local bulletNum=math.ceil(fillAngle/(math.pi/18))
            for i=1,bulletNum do
                local bulletAngle=self.angle+(i-0.5)*fillAngle/bulletNum+self.gap/2
                local bullet=Circle{x=self.core.cir.x,y=self.core.cir.y,direction=bulletAngle,speed=0,lifeFrame=9999,invincible=true,sprite=BulletSprites.billDark.red,radius=self.radius/10,highlight=true,extraUpdate={Circle.FadeIn,Circle.ZoomIn,function(bullet)
                    if self.core.removed then
                        bullet:remove()
                    end
                    local fillAngle=math.pi*2-self.gap
                    bullet.x,bullet.y,bullet.direction=Shape.rThetaPosT(self.core.cir.x,self.core.cir.y,self.radius,self.angle+(i-0.5)*fillAngle/bulletNum+self.gap/2)
                end}}
                table.insert(self.bullets,bullet)
            end
        end
        function Layer:update()
            self.angle=self.angle+self.core.cirDeltaDirection
            if self.type==layerTypes.ROTATING then
                self.angle=self.angle+self.rotateSpeed
            elseif self.type==layerTypes.AIMING then
                local targetAngle=Shape.to(self.core.cir.x,self.core.cir.y,player.x,player.y)
                local angleDiff=math.angleDiffSigned(targetAngle,self.angle)
                local maxTurn=math.abs(self.rotateSpeed)
                if math.abs(angleDiff)>maxTurn then
                    self.angle=self.angle+maxTurn*math.sign(angleDiff)
                else
                    self.angle=targetAngle
                end
            end
            self.revealIntervals=AngleIntervals.new(self.angle-self.gap/2,self.angle+self.gap/2)
        end

        ---@class Core:GameObject
        ---@field cir Shape
        ---@field layers Layer[]
        ---@field revealIntervals AngleIntervals
        ---@field polyLines PolyLine[] dynamically allocate to draw multi parts of laser areas
        ---@field cirLastDirection number
        ---@field cirDeltaDirection number
        local Core=GameObject:extend()
        function Core:new(cir)
            self.cir=cir
            self.layers={}
            self.revealIntervals=AngleIntervals.new(0,0)
            self.polyLines={}
            self.cirLastDirection=cir.direction
            self.cirDeltaDirection=0
        end
        function Core:addLayer(type,angle,gap,speed,radius)
            local layer=Layer(self,type,angle,gap,speed,radius)
            table.insert(self.layers,layer)
        end
        function Core:update(dt)
            if self.cir.removed then
                for i,polyline in pairs(self.polyLines) do
                    polyline:remove()
                end
                self:remove()
                return
            end
            self.cirDeltaDirection=self.cir.direction-self.cirLastDirection
            self.cirLastDirection=self.cir.direction
            for _,layer in ipairs(self.layers) do
                layer:update()
            end
            local revealIntervals=AngleIntervals.new(0,twopi)
            for _,layer in ipairs(self.layers) do
                revealIntervals=AngleIntervals.intersect(revealIntervals,layer.revealIntervals)
            end
            self.revealIntervals=revealIntervals
            AngleIntervals.wrap(self.revealIntervals)
            local intervals=self.revealIntervals
            if #self.polyLines<#intervals then
                for i=#self.polyLines+1,#intervals do
                    local blankPolyLine=PolyLine({},false)
                    blankPolyLine.color={0.7,0.2,0.2}
                    blankPolyLine.faceColorRatio=0.6
                    blankPolyLine.drawFace=true
                    blankPolyLine.sprite=BulletSprites.snake.white
                    table.insert(self.polyLines,blankPolyLine)
                end
            end
            local intervalNum=#intervals
            local polyLineNum=#self.polyLines
            for i=1,intervalNum do
                local startAngle=intervals[i].start
                local endAngle=intervals[i].ending
                local vertices={{self.cir.x,self.cir.y}}
                local pointNum=math.max(math.ceil((endAngle-startAngle)/math.pi*18),3)
                for j=0,pointNum do
                    local angle=startAngle+j/pointNum*(endAngle-startAngle)
                    local x,y=Shape.rThetaPos(self.cir.x,self.cir.y,200,angle)
                    table.insert(vertices,{x,y})
                end
                self.polyLines[i]:replacePoints(vertices)
                self.polyLines[i].doDraw=true
            end
            for i=intervalNum+1,polyLineNum do
                self.polyLines[i].doDraw=false
            end

            self:checkHitPlayer()
            if self.cir.frame%5==0 then
                self:checkGrazePlayer()
            end
        end
        function Core:checkHitPlayer()
            if AngleIntervals.inside(self.revealIntervals, Shape.to(self.cir.x,self.cir.y,player.x,player.y)) then
                EventManager.post(EventManager.EVENTS.PLAYER_HIT,player,1)
            end
        end
        function Core:checkGrazePlayer()
            local angleToPlayer=Shape.to(self.cir.x,self.cir.y,player.x,player.y)
            if AngleIntervals.inside(self.revealIntervals,angleToPlayer+0.04) then
                EventManager.post(EventManager.EVENTS.PLAYER_GRAZE,player,1)
            end
            if AngleIntervals.inside(self.revealIntervals,angleToPlayer-0.04) then
                EventManager.post(EventManager.EVENTS.PLAYER_GRAZE,player,1)
            end
        end
        -- for debug
        -- function Core:drawText()
        --     local intervalText='points: '..#PolyLine.Point.objects..'\npolylines: '..#PolyLine.objects..'\nintervals: '..#AngleIntervals.objects
        --     love.graphics.print(intervalText,100,100)
        -- end

        makeCore=function (num,speedRatio)
            num=num or 1
            speedRatio=speedRatio or 1
            local function stickUpdate(cir)
                local cir2=cir.core.cir
                local dir=cir.dir0+cir2.direction+cir.frame*(cir.index%2==0 and math.pi/960 or -math.pi/480)*speedRatio
                cir.r=cir.r+cir.speed/60
                cir.x,cir.y=Shape.rThetaPos(cir2.x,cir2.y,cir.r,dir)
                -- if cir.frame%10==0 and AngleIntervals.inside(cir.core.revealIntervals,dir) then
                --     cir.speed=cir.speed+5
                -- end
            end
            for i=1,num do
                local dir=math.pi*2/num*(i-1)
                local cir=Circle{x=center.x,y=center.y,direction=dir,speed=160,lifeFrame=9999,invincible=true,sprite=BulletSprites.giant.white,spriteColor={1,0.5,0.5},highlight=true,extraUpdate={function(cir)
                    if cir.frame<120 then
                        cir.speed=cir.speed*0.95
                    elseif cir.frame==120 then
                        cir.r=Shape.distanceObj(center,cir)
                        cir.angle=Shape.toObj(center,cir)
                    else
                        local rotateSpeed=math.min(1,(cir.frame-120)/300)*0.003
                        cir.angle=cir.angle+rotateSpeed
                        cir.x,cir.y,cir.direction=Shape.rThetaPosT(center.x,center.y,cir.r,cir.angle)
                    end
                end}}
                local core=Core(cir)
                for j=1,6 do
                    core:addLayer(layerTypes.ROTATING,dir+math.pi/3*j,math.pi*4.5/3,math.pi/180*0,8)
                    Event.EaseEvent{
                        obj=core.layers[j],aimKey='gap',aimValue=math.pi*22/12,easeFrame=120
                    }
                end
                for j=7,12 do
                    core:addLayer(layerTypes.ROTATING,dir+math.pi/3*j,math.pi*4.5/3,math.pi/180*0,10)
                    Event.EaseEvent{
                        obj=core.layers[j],aimKey='gap',aimValue=math.pi*23/12,easeFrame=120
                    }
                end
                Event.DelayEvent{
                    obj=en,delayFrame=120,executeFunc=function()
                        for j=1,6 do
                            core.layers[j].rotateSpeed=math.pi/960*speedRatio
                        end
                        for j=7,12 do
                            core.layers[j].rotateSpeed=-math.pi/480*speedRatio
                        end
                        local s=BulletSpawner{x=core.cir.x,y=core.cir.y,period=120*num,frame=120*(i-1),lifeFrame=9999,bulletNumber=36,bulletSpeed=40,bulletLifeFrame=300,angle=0,bulletSprite=BulletSprites.crossRim.red,highlight=false,
                        bulletEvents={
                            function(cir,args,self)
                                if args.index==1 then
                                    if self.spawnEvent.executedTimes%5~=4 then
                                        self.spawnEvent.period=5
                                    else
                                        self.spawnEvent.period=120*num
                                        self.angle=math.eval(0,999)
                                    end
                                end
                                cir.dir0=cir.direction-core.cir.direction
                                cir.index=args.index
                                cir.r=0
                                cir.core=core
                            end
                        },bulletExtraUpdate=stickUpdate}
                        Event.LoopEvent{
                            obj=s,period=1,executeFunc=function(self)
                                if core.removed then
                                    s:remove()
                                    return
                                end
                                s.x=core.cir.x
                                s.y=core.cir.y
                            end
                        }
                    end
                }
            end
        end

        Event.DelayEvent{
            obj=en,delayFrame=60,executeFunc=function()
                SFX:play('enemyPowerfulShot',true)
                makeCore()
            end
        }
    end
}