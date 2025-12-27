return {
    ID=115,
    user='asama',
    spellName='Void Sign "Purge Algorithm"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=3000
        local center={x=400,y=300}
        local a,b
        local en
        local player=Player{x=400,y=600}
        local hpLevel=1
        local preSignalLineCoversNewArea=false
        local numOfNotCoveringNewAreas=0
        local preSignalLine=nil -- to check if a signalLine covers new area
        local signalLine=nil -- explosions will appear if signalLine exists and left to signalLine, and will disappear if signalLine is nil
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=10800,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel0)
            SFX:play('enemyCharge',true)
            Effect.Shockwave{x=self.x,y=self.y,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove={bullet=true}}
            en:addHPProtection(600,10)
            hpLevel=hpLevel+1
            a.frame=a.period-60
            preSignalLineCoversNewArea=false
            numOfNotCoveringNewAreas=0
            preSignalLine=nil
            signalLine=nil
        end}
        en:addHPProtection(600,10)
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,100,12))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local period=5
        for r=5,120,5 do
            local circum=math.sinh(r/Shape.curvature)*Shape.curvature*math.pi*2
            local num=math.floor(circum/10)
            for i=0,num-1 do
                local theta=i/num*math.pi*2
                local x,y=Shape.rThetaPos(center.x,center.y,r,theta)
                local bullet=Circle{x=x,y=y,speed=0,lifeFrame=10000,sprite=BulletSprites.explosion.gray,radius=0.9,safe=true,highlight=true,invincible=true,spriteTransparency=0,extraUpdate={
                    function(self)
                        if not self.preSignalled and preSignalLine and Shape.leftToLine(self.x,self.y,preSignalLine[1],preSignalLine[2],preSignalLine[3],preSignalLine[4]) then
                            self.preSignalled=true
                            preSignalLineCoversNewArea=true
                        end
                        if signalLine then
                            self.preSignalled=false
                        end
                        if signalLine and self.safe==true and Shape.leftToLine(self.x,self.y,signalLine[1],signalLine[2],signalLine[3],signalLine[4]) then
                            self.safe=false
                            local dist=math.clamp(1-Shape.distanceObj(self,player)/120,0,1)*0.7
                            local baseColor=self.spriteColorBase
                            self.spriteColor={dist*baseColor[1],dist*baseColor[2],dist*baseColor[3],1}
                        elseif not signalLine and not self.safe then
                            self.safe=true
                        end
                        self.hpLevel=self.hpLevel or hpLevel
                        if self.hpLevel<hpLevel then
                            self.hpLevel=hpLevel
                            self.preSignalled=false
                        end
                        self.spriteTransparency=self.safe and (self.preSignalled and 0 or 0) or 1
                    end
                }}
                bullet.forceDrawNormalSprite=true
                local seed=i*999+r*776
                bullet.spriteColorBase={math.pseudoRandom(seed),math.pseudoRandom(seed,13),math.pseudoRandom(seed,29),1}
                bullet.spriteColor={0,0,0,1}
            end
        end
        local function stream(cir,time,speed,inverse,burst,noNewArea)
            time=time or 0
            speed=speed or 0.2
            local distance=180
            local num=20
            local color=cir.sprite.data.color
            for i=0,num-1 do
                local dist1=distance*2*(i/num-0.5)
                local x,y=Shape.rThetaPos(cir.x,cir.y,dist1,cir.direction+math.pi/2)
                local bullet=Circle{x=x,y=y,speed=0,radius=2,lifeFrame=1000,sprite=BulletSprites.arrow[color],highlight=true,spriteTransparency=0,extraUpdate={
                    function(self)
                        self.dist=(self.dist or dist1)-speed
                        self.x,self.y,self.direction=Shape.rThetaPosT(cir.x,cir.y,self.dist*(inverse and -1 or 1),cir.direction+math.pi/2)
                        self.direction=self.direction-math.pi/2
                        if self.dist<=-distance then
                            self.dist=self.dist+distance*2
                            i=i+num
                        end
                        local disCenter=Shape.distanceObj(self,center)
                        self.spriteTransparency=1*math.clamp((120-disCenter)*0.1,0,1)*math.clamp((self.frame-time-disCenter/2)/60,0,1)
                        self.safe=true
                        self.hpLevel=self.hpLevel or hpLevel
                        if self.hpLevel<hpLevel then
                            self:remove()
                        end
                        if self.frame>=burst then
                            self:remove()
                        end
                    end
                }}
            end
            if noNewArea then
                return
            end
            local hpLevelRef=hpLevel
            Event.DelayEvent{
                obj=cir,
                delayFrame=burst,
                executeFunc=function(self)
                    if hpLevelRef<hpLevel then
                        return
                    end
                    SFX:play('enemyShot',true,2)
                    local x1,y1=Shape.rThetaPos(cir.x,cir.y,20,cir.direction-math.pi/2)
                    local x2,y2=Shape.rThetaPos(cir.x,cir.y,20,cir.direction+math.pi/2)
                    signalLine={x1,y1,x2,y2}
                end
            }
        end
        local colors={}
        for i,j in pairs(BulletSprites.ellipse) do
            table.insert(colors,i)
        end
        local colorIndex=1
        local function trace2(aimx,aimy,aimDirection,r,burst)
            local color=colors[colorIndex]
            colorIndex=(colorIndex+4)%#colors+1
            local inverse=math.random()<0.5
            local alignTime=150
            local spawnDirection=math.eval(0,999)
            local spawnx,spawny=Shape.rThetaPos(aimx,aimy,r,spawnDirection)
            local directionBias=math.eval(0,(hpLevel-1)*0.5)
            local cir=Circle{x=spawnx,y=spawny,direction=aimDirection+directionBias,speed=0,lifeFrame=10000,sprite=BulletSprites.arrow[color],spriteTransparency=0,safe=true,invincible=true,extraUpdate={
                function(self)
                    if self.frame<=alignTime then
                        self.direction=aimDirection+directionBias*(1-self.frame/alignTime)
                        self.x,self.y=Shape.rThetaPos(aimx,aimy,r*(1-self.frame/alignTime),spawnDirection)
                    else
                        self.x,self.y, self.direction=aimx,aimy,aimDirection
                    end
                end
            }}
            local x1,y1=Shape.rThetaPos(aimx,aimy,20,aimDirection-math.pi/2)
            preSignalLine={x1,y1,aimx,aimy}
            preSignalLineCoversNewArea=false
            local hpLevelRef=hpLevel
            Event.DelayEvent{
                obj=cir,
                delayFrame=1,
                executeFunc=function(self)
                    if hpLevelRef<hpLevel then
                        return
                    end
                    if not preSignalLineCoversNewArea then
                        numOfNotCoveringNewAreas=numOfNotCoveringNewAreas+1
                    end
                    stream(cir,0,nil,inverse,burst-period*numOfNotCoveringNewAreas,not preSignalLineCoversNewArea)
                end
            }
        end
        a=Event.LoopEvent{
            obj=en,period=400,frame=370,executeFunc=function(self,times,maxTimes)
                local hpLevelRef=hpLevel
                local count
                count=10+hpLevel*5
                local dir=math.eval(0,999)
                local x,y=Shape.rThetaPosT(en.x,en.y,math.eval(50,20),dir)
                local burst=300
                local r2=(hpLevel-1)*10
                numOfNotCoveringNewAreas=0
                period=90/count
                Event.LoopEvent{
                    obj=en,
                    period=period,
                    times=count,
                    executeFunc=function(self,time)
                        if hpLevel>hpLevelRef then
                            self:remove()
                            return
                        end
                        SFX:play('enemyShot',true)
                        local try=0
                        while try<5 do
                            try=try+1
                            local r0=Shape.curvature*math.acosh(1+math.random()*(math.cosh(60/Shape.curvature)-1))
                            local x1,y1,dir1=Shape.rThetaPosT(en.x,en.y,r0,math.eval(0,999))
                            local dir2=dir1
                            local x2,y2=Shape.rThetaPos(x1,y1,10,dir2+math.pi/2)
                            if Shape.distanceToLine(x,y,x1,y1,x2,y2)>5 then
                                if math.cos(Shape.to(x1,y1,x,y)-dir2)>0 then
                                    dir2=dir2+math.pi
                                end
                                trace2(x1,y1,dir2,r2,burst)
                                break
                            end
                        end
                        if time==count-1 then
                            local hpLevelRef2=hpLevel
                            Event.DelayEvent{
                                obj=en,
                                delayFrame=burst-period*numOfNotCoveringNewAreas+30,
                                executeFunc=function(self)
                                    if hpLevelRef2<hpLevel then
                                        return
                                    end
                                    signalLine=nil
                                    preSignalLine=nil
                                end
                            }
                        end
                    end
                }
            end
        }
    end
}