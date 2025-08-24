return {
    ID=116,
    user='toyohime',
    spellName='Fan Sign ""',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=2000
        local center={x=400,y=300}
        local a,b
        local en
        local player=Player{x=400,y=600}
        local la,lb=-13,5
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=8400,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            SFX:play('enemyCharge',true)
            en:addHPProtection(600,10)
            la,lb=-10,0
            a.spawnEvent.period=100
            a.spawnEvent.frame=40
            a.bulletNumber=10
            a.bulletSpeed=80
            b.period=150
            b.frame=75
        end}
        en:addHPProtection(600,10)
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,100,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local fanPolyline=nil
        local function fanEffect(x,y,direction,r,theta,rnum,thetaNum)
            local t1,t2=30,60
            local points={{x,y}}
            for i=-1,rnum do
                local ri=r*i/rnum
                for j=1,thetaNum do
                    local angle=theta*((j-0.5)/thetaNum-0.5)
                    local xi,yi=Shape.rThetaPos(x,y,ri,direction+angle)
                    if i==rnum then
                        table.insert(points,{xi,yi})
                    end
                    local circle=Circle{x=x,y=y,lifeFrame=400,sprite=BulletSprites.round.purple,speed=0,direction=direction,safe=true,spriteTransparency=0.4,invincible=true,extraUpdate=function (self)
                        local rt=ri*math.clamp(self.frame/t1,0,1)
                        local anglet=angle*Event.sineOProgressFunc(math.clamp((self.frame-t1)/t2,0,1))
                        self.x,self.y=Shape.rThetaPos(x,y,rt,anglet+direction)
                        if self.frame>=t1+t2 then
                            self.spriteTransparency=math.max(0,self.spriteTransparency-0.04)
                        end
                        if self.frame>=t1+t2+20 then
                            self:remove()
                        end
                    end}
                end
            end
            Event.DelayEvent{
                obj=en,
                delayFrame=t1+t2+10,
                executeFunc=function()
                    fanPolyline=PolyLine(points,false)
                    Event.DelayEvent{
                        obj=en,delayFrame=1,executeFunc=function()
                            fanPolyline:remove()
                            fanPolyline=nil
                        end
                    }
                end
            }
        end
        a=BulletSpawner{x=en.x,y=en.y,period=300,frame=250,lifeFrame=10000,bulletNumber=20,bulletSpeed=40,bulletLifeFrame=1000,spawnCircleRadius=50,spawnCircleRange=math.pi,spawnCircleAngle='0+999',angle=math.pi/2,range=math.pi*2,highlight=true,bulletSprite=BulletSprites.giant.blue,fogEffect=true,fogTime=30,bulletEvents={
            function(cir,args,self)
                local speedRef=cir.speed
                cir.speed=0
                Event.EaseEvent{
                    obj=cir,easeFrame=120,aimKey='speed',aimValue=speedRef,progressFunc=Event.sineOProgressFunc}
            end
        },bulletExtraUpdate={
            function(self)
                if fanPolyline and fanPolyline:inside(self.x,self.y) then
                    self:removeEffect()
                    self:remove()
                    local hplevel=en.getHPLevel()
                    BulletSpawner{x=self.x,y=self.y,period=1,lifeFrame=2,bulletSprite=BulletSprites.round[self.sprite.data.color],bulletSpeed=0,bulletLifeFrame=600,bulletNumber=hplevel==1 and 5 or 3,angle='0+999',range=math.pi*2,fogEffect=true,fogTime=30,bulletEvents={
                        function(cir,args,self)
                            local speedRef=math.eval(20,10)
                            Event.EaseEvent{
                                obj=cir,easeFrame=120,aimKey='speed',aimValue=speedRef,progressFunc=Event.sineOProgressFunc}
                        end
                    }}
                end
            end
        },
        spawnBatchFunc=function(self)
            SFX:play('enemyShot',true,self.spawnSFXVolume)
            local num=math.eval(self.bulletNumber)
            local range=math.eval(self.range)
            local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
            local spawnCircleAngle=Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y)-angle*.4
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
        b=Event.LoopEvent{
            obj=en,period=300,frame=0,executeFunc=function(self,times,maxTimes)
                local r,theta,rnum,thetaNum=30,math.pi*2/3,10,10
                local mod=times%4
                local hplevel=en:getHPLevel()
                if hplevel==1 then
                    if mod==0 then
                        return
                    elseif mod==2 then
                        r,rnum,thetaNum=50,15,15
                    elseif mod==3 then
                        r,rnum,thetaNum=70,25,20
                    end
                end
                local x,y,dir=player.x,player.y,Shape.to(player.x,player.y,en.x,en.y)
                if hplevel==2 then
                    if mod<2 then
                        dir=dir+math.mod2Sign(times)*math.pi/6
                        for i=1,3 do
                            Event.DelayEvent{
                                obj=en,delayFrame=(i-1)*10,executeFunc=function()
                                    x,y,dir=Shape.rThetaPosT(x,y,20,dir)
                                    fanEffect(x,y,dir+math.mod2Sign(times)*math.pi/2,r,theta,rnum,thetaNum)
                                end
                            }
                        end
                    else
                        x,y,dir=Shape.rThetaPosT(x,y,40,dir)
                        for i=1,3 do
                            Event.DelayEvent{
                                obj=en,delayFrame=(i-1)*10,executeFunc=function()
                                    dir=dir+math.mod2Sign(times)*math.pi*2/3
                                    fanEffect(x,y,dir,r,theta,rnum,thetaNum)
                                end
                            }
                        end
                    end
                else
                    fanEffect(x,y,dir,r,theta,rnum,thetaNum)
                end
            end
        }
        Event.LoopEvent{
            obj=en,period=300,frame=0,executeFunc=function(self,times,maxTimes)
                local x1,y1=Shape.rThetaPos(center.x,center.y,math.eval(15,15),math.eval(0,999))
                Event.LoopEvent{
                    obj=en,period=1,times=60,executeFunc=function()
                        Shape.moveTowards(en,{x=x1,y=y1},0.5,true)
                    end
                }
            end
        }
    end
}