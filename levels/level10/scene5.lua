return {
    ID=117,
    user='toyohime',
    spellName='Boundary Sign ""',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=2000
        local center={x=400,y=300}
        local a,b
        local en
        local player=Player{x=400,y=600}
        local la,lb=0,6
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=8400,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            SFX:play('enemyCharge',true)
            Effect.Shockwave{x=self.x,y=self.y,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove={bullet=true}}
            en:addHPProtection(600,10)
            a.angle=math.pi*2/3
            a.spawnCircleRange=math.pi*0.8
            b.bulletNumber=40
            b.bulletSpeed=40
        end}
        en:addHPProtection(600,10)
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,100,12))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local num=61
        local function stream(cir,time,speed,inverse)
            time=time or 0
            speed=speed or 0.2
            local distance=100
            local color='blue'
            local bullets={}
            for i=0,num-1 do
                local dist1=distance*2*(i/num-0.5)
                local x,y=Shape.rThetaPos(cir.x,cir.y,dist1,cir.direction+math.pi/2)
                local bullet=Circle{x=x,y=y,speed=0,radius=2,lifeFrame=10000,sprite=BulletSprites.rim[color],highlight=true,invincible=true,spriteTransparency=0,extraUpdate={
                    function(self)
                        self.dist=(self.dist or dist1)-speed
                        self.x,self.y,self.direction=Shape.rThetaPosT(cir.x,cir.y,self.dist*(inverse and -1 or 1),cir.direction+math.pi/2)
                        self.x,self.y,self.direction=Shape.rThetaPosT(self.x,self.y,10*math.sin(i/10+self.frame/120),self.direction+math.pi/2)
                        self.direction=self.direction-math.pi/2
                        if self.dist<=-distance then
                            self.dist=self.dist+distance*2
                            i=i+num
                        end
                        local disCenter=Shape.distanceObj(self,center)
                        self.spriteTransparency=1*math.clamp((120-disCenter)*0.1,0,1)*math.clamp((self.frame-time-disCenter/2)/60,0,1)
                        -- self.safe=true
                    end
                }}
                bullets[#bullets+1]=bullet
            end
            return bullets
        end
        local bullets={stream({x=400,y=900,direction=math.pi/2},-20),stream({x=400,y=500,direction=math.pi/2},-20)}
        local lines={}
        local top={x=400,y=50}
        local gap=3
        local function mountain(top,num,add,transparencyMax)
            for i=0,num-1 do
                for sign=-1,1,2 do
                    local dir=math.pi/2+sign*math.pi/6
                    local x,y,direction=Shape.rThetaPosT(top.x,top.y,i*gap,dir)
                    Circle{x=x,y=y,speed=0,radius=2,direction=direction,lifeFrame=10000,sprite=BulletSprites.crystalDark.red,highlight=true,invincible=true,spriteTransparency=0,extraUpdate={
                        function(self)
                            self.spriteTransparency=math.clamp((self.frame-10)/60,0,transparencyMax)
                        end
                    }}
                    if i==num-1 and add then
                        if sign==-1 then
                            lines[1]={top.x,top.y,x,y}
                        else
                            lines[2]={x,y,top.x,top.y}
                        end
                    end
                end
            end
        end
        mountain(top,num,true,1) -- main mountain that teleports
        mountain({x=000,y=70},math.floor(num*0.5),false,0.5) -- decoration
        mountain({x=800,y=70},math.floor(num*0.5),false,0.5)
        for i=1,2 do
            local x1,y1,x2,y2=unpack(lines[i])
            local centerX,radius=Shape.lineCenter(x1,y1,x2,y2)
            lines[i][5],lines[i][6]=centerX,radius
        end
        local function teleportBase(self)
            if self.teleported then return end
            for i=1,2 do
                local line=lines[i]
                if math.distance(self.x,self.y,line[5],Shape.axisY)<line[6] then -- precalculated Shape.leftToLine
                    local distance=Shape.distance(self.x,self.y,top.x,top.y)
                    if distance>gap*num then
                        goto continue
                    end
                    local index=math.ceil(distance/gap)
                    local x1,y1=unpack(Shape.nearestToLine(self.x,self.y,line[1],line[2],line[3],line[4]))
                    local angle=Shape.to(x1,y1,self.x,self.y)
                    local distanceToMove=Shape.distance(self.x,self.y,x1,y1)
                    local corrcir=bullets[i][index]
                    self.teleported=true
                    self.x,self.y,self.direction=Shape.rThetaPosT(corrcir.x,corrcir.y,distanceToMove,corrcir.direction+(Shape.to(x1,y1,top.x,top.y)-angle)+math.pi)
                    Circle{x=self.x,y=self.y,speed=0,lifeFrame=10,radius=2,safe=true,highlight=true,sprite=BulletSprites.fog.white,extraUpdate=function(fog)
                        fog.spriteTransparency=1-0.1*fog.frame
                    end}
                    self.speed=self.speed*0.5
                    break
                end
                ::continue::
            end
        end
        a=BulletSpawner{x=en.x,y=en.y,period=120,frame=0,lifeFrame=10000,bulletNumber=10,bulletSpeed=40,bulletLifeFrame=1000,spawnCircleRadius=50,spawnCircleRange=math.pi*0.6,spawnCircleAngle='0+999',angle=math.pi/9,range=math.pi*2,highlight=true,bulletSprite=BulletSprites.giant.blue,fogEffect=true,fogTime=30,bulletEvents={
            function(cir,args,self)
                local speedRef=cir.speed
                cir.speed=0
                Event.EaseEvent{
                    obj=cir,easeFrame=120,aimKey='speed',aimValue=speedRef,progressFunc=Event.sineOProgressFunc}
                
            end
        },bulletExtraUpdate={
        },
        spawnBatchFunc=function(self)
            SFX:play('enemyShot',true,self.spawnSFXVolume)
            local num=math.eval(self.bulletNumber)
            local range=math.eval(self.range)
            local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
            local spawnCircleAngle=Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y)-angle*1
            local spawnCircleRange=math.eval(self.spawnCircleRange)
            local spawnCircleRadius=math.eval(self.spawnCircleRadius)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            local x1,y1,dir1=Shape.rThetaPosT(self.x,self.y,-spawnCircleRadius*0.6,spawnCircleAngle)
            for i = 1, num, 1 do
                local direction=range*(i-0.5-num/2)/num+dir1
                local spawnCircleDir=spawnCircleRange*(i-0.5-num/2)/num+spawnCircleAngle
                local x,y=Shape.rThetaPos(x1,y1,spawnCircleRadius,spawnCircleDir)
                if spawnCircleRadius~=0 then
                    direction=Shape.to(x,y,x1,y1)+math.pi+angle
                end
                Event.DelayEvent{
                    obj=self,
                    delayFrame=i,
                    executeFunc=function()
                        for j=la,lb do
                            self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed+j*5,radius=size,index=i,batch=self.bulletBatch,fogTime=self.fogTime,sprite=self.bulletSprite}
                            local dAngle=angle*-1
                            x,y,direction=Shape.rThetaPosT(x,y,-3,direction+dAngle)
                            direction=direction-dAngle
                        end
                    end
                }
            end
            self.sign=not self.sign
            self.angle=-self.angle
            self.spawnCircleRange=-self.spawnCircleRange
            if self.sign then
                self.bulletSprite=BulletSprites.giant.red
            else
                self.bulletSprite=BulletSprites.giant.blue
            end
        end}
        b=BulletSpawner{x=en.x,y=en.y,period=120,frame=60,lifeFrame=10000,bulletNumber=10,bulletSpeed=40,bulletLifeFrame=1000,spawnCircleRadius=30,spawnCircleRange=math.pi*0.5,spawnCircleAngle=-0.5,angle=0,range=math.pi*2,highlight=true,bulletSprite=BulletSprites.bigRound.purple,fogEffect=true,fogTime=30,bulletEvents={
            function(cir,args,self)
                local speedRef=cir.speed
                cir.speed=0
                Event.EaseEvent{
                    obj=cir,easeFrame=120,aimKey='speed',aimValue=speedRef,progressFunc=Event.sineOProgressFunc}
                local hpLevel=en:getHPLevel()
                if hpLevel==2 and args.index%10<5 then
                    Event.EaseEvent{
                        obj=cir,easeFrame=60,aimKey='spriteTransparency',aimValue=0}
                    cir.lifeFrame=60
                end
            end
        },bulletExtraUpdate={
            teleportBase
        },spawnBatchFunc=function(self)
            local hpLevel=en:getHPLevel()
            SFX:play('enemyShot',true,self.spawnSFXVolume)
            local num=math.eval(self.bulletNumber)
            local range=math.eval(self.range)
            local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
            local spawnCircleAngle=self.spawnCircleAngle
            local spawnCircleRange=math.eval(self.spawnCircleRange)
            local spawnCircleRadius=math.eval(self.spawnCircleRadius)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            local x1,y1,dir1=Shape.rThetaPosT(self.x,self.y,-spawnCircleRadius*0.6,spawnCircleAngle)
            for i = 1, num, 1 do
                Event.DelayEvent{
                    obj=self,
                    delayFrame=i,
                    executeFunc=function()
                        for j=la,lb do
                            local direction=range*(i-0.5-num/2)/num+dir1
                            local spawnCircleDir=spawnCircleRange*(i-0.5-num/2)/num+spawnCircleAngle
                            local x,y=Shape.rThetaPos(x1,y1,spawnCircleRadius+j*3,spawnCircleDir)
                            if spawnCircleRadius~=0 then
                                direction=Shape.to(x,y,x1,y1)+math.pi+angle
                            end
                            self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed+j*5*(hpLevel==2 and -0.5 or 1),radius=size,index=i,batch=self.bulletBatch,fogTime=self.fogTime,sprite=self.bulletSprite}
                        end
                    end
                }
            end
            self.sign=not self.sign
            self.spawnCircleAngle=-math.pi-self.spawnCircleAngle
            self.spawnCircleRange=-self.spawnCircleRange
        end}
        Event.LoopEvent{
            obj=en,period=300,frame=0,executeFunc=function(self,times,maxTimes)
            end
        }
    end
}