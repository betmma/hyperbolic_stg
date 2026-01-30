return {
    ID=108,
    user='kotoba',
    spellName='Bluetooth "Tele-bite"',
    dialogue='bossDialogue12_7',
    make=function()
        G.levelRemainingFrame=10800
        Shape.removeDistance=1e100
        local center={x=400,y=300000}
        local a,b,player
        local en
        local hplevel=1
        local randChord
        local color='blue'
        en=Enemy{x=center.x,y=center.y,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.3},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
            hplevel=hplevel+1
            if hplevel==2 then
                a.frame=a.frame-20
                a.period=160
            elseif hplevel==3 then
                a.frame=a.frame-20
                a.period=120
            end
        end}
        en:addHPProtection(600,10)
        player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local function toothUpdate(self)
            if self.frame<=50 then
                self.spriteTransparency=self.frame/50
            else
                self.safe=false
            end
            self.ghostAccum=(self.ghostAccum or 0)+1
            local period=math.max(100/self.bind.speed,2)
            if self.ghostAccum>=period then -- ghost effect
                self.ghostAccum=0
                local ghost=Circle{x=self.x,y=self.y,speed=0,direction=self.direction,radius=self.radius,sprite=self.sprite,spriteTransparency=1,safe=true,invincible=true,highlight=true,lifeFrame=period*3}
                Event.EaseEvent{
                    obj=ghost,aimKey='spriteTransparency',aimValue=0,easeFrame=period*3
                }
            end
            if self.bind then
                local bind=self.bind
                local r=self.r*self.i
                local x0,y0,dir0=Shape.rThetaPosT(bind.x,bind.y,r,bind.direction+math.pi/2)
                dir0=dir0-math.pi/2
                self.x=x0
                self.y=y0
                self.direction=dir0
            end
        end
        local function toothBase(cir,num,laserTime,stopTime,distance)
            num=num or 5
            cir.teeth={}
            local r=10
            for i=1,num do
                local imid=i-num/2-0.5
                local x0,y0,dir0=Shape.rThetaPosT(cir.x,cir.y,r*i,cir.direction+math.pi/2)
                dir0=dir0-math.pi/2
                local tooth=Circle{x=x0,y=y0,speed=0,direction=dir0,radius=6,sprite=BulletSprites.scale[color],spriteTransparency=0,safe=true,invincible=true,highlight=true,extraUpdate=toothUpdate}
                tooth.bind=cir
                tooth.i=imid
                tooth.r=r
                tooth.laserTime=laserTime+math.abs(imid)*3
                cir.teeth[#cir.teeth+1]=tooth
            end
            Event.EaseEvent{
                obj=cir,aimKey='speed',aimValue=-60*math.pi*distance/stopTime,easeFrame=stopTime,progressFunc=Event.sineBackProgressFunc
            }
        end
        local linkCount=0
        local function link(cir1,cir2)
            linkCount=linkCount+1
            local spawnLine=linkCount%2==0 -- if hplevel>=2, whether spawn line between center tooth
            local n=#cir1.teeth
            local mid=math.ceil(n/2)
            for i=1,n do
                local tooth1=cir1.teeth[i]
                local tooth2=cir2.teeth[n+1-i]
                Event.DelayEvent{
                    obj=tooth1,delayFrame=tooth1.laserTime,executeFunc=function ()
                        SFX:play('enemyPowerfulShot',true)
                        local laserR=2.8
                        local lasert=30
                        local distance=Shape.distanceObj(tooth1,tooth2)
                        local laserSpeed=0--distance/lasert/2*60
                        -- tooth1.speed=laserSpeed
                        -- tooth2.speed=laserSpeed
                        local laser1=Laser.LaserUnit{x=tooth1.x,y=tooth1.y,direction=tooth1.direction,radius=0.01,sprite=BulletSprites.laser[color],speed=laserSpeed,lifeFrame=lasert}
                        Event.EaseEvent{
                            obj=laser1,aimKey='radius',aimValue=laserR,easeFrame=lasert,progressFunc=Event.sineBackProgressFunc
                        }
                        local laser2=Laser.LaserUnit{x=tooth2.x,y=tooth2.y,direction=tooth2.direction+math.pi,radius=0.01,sprite=BulletSprites.laser[color],speed=-laserSpeed,lifeFrame=lasert}
                        Event.EaseEvent{
                            obj=laser2,aimKey='radius',aimValue=laserR,easeFrame=lasert,progressFunc=Event.sineBackProgressFunc
                        }
                        laser1.next=laser2
                        laser2.previous=laser1
                        Event.DelayEvent{
                            obj=tooth1,delayFrame=lasert,executeFunc=function ()
                                tooth1:remove()
                                tooth2:remove()
                            end
                        }
                        if i==mid and (hplevel==2 and spawnLine or hplevel==3) then
                            local gap=5
                            local points=Shape.segmentPoints(tooth1.x,tooth1.y,tooth2.x,tooth2.y,gap,30+(spawnLine and 1 or 0)) -- add 1 to slightly change pattern
                            local np=#points
                            local t=a.period-20
                            for ind,p in ipairs(points) do
                                local toObj=laser1
                                if ind*2<np then
                                    toObj=laser2
                                end
                                local speed=0
                                if hplevel==3 then
                                    speed=distance*60/140*math.abs(ind-np/2)/(np/2)
                                end
                                local b=Circle{
                                    x=p.x,y=p.y,
                                    speed=0,direction=Shape.toObj(p,toObj),
                                    radius=2,highlight=true,
                                    sprite=BulletSprites.bigRound[color],lifeFrame=t,
                                    extraUpdate=function(self)
                                        self.speed=self.frame/(t-20)*speed
                                        if self.frame>(t-20) then
                                            self.spriteTransparency=self.spriteTransparency-0.05
                                        end
                                    end
                                }
                            end
                        end
                    end
                }
            end
        end
        local function spawnTeleBite(num,laserTime,stopTime,x1,y1,x2,y2)
            if not x1 then
                x1,y1=Shape.rThetaPos(en.x,en.y,math.eval(50,50),math.eval(0,999))
            end
            if not x2 then
                x2,y2=Shape.rThetaPos(x1,y1,math.eval(150,50),math.eval(0,999))
            end
            local distance=Shape.distance(x1,y1,x2,y2)/2
            local middle=Shape.segmentPoints(x1,y1,x2,y2,1,2)[2]
            local dir1=Shape.to(middle.x,middle.y,x1,y1)
            local cir1=Circle{x=middle.x,y=middle.y,lifeFrame=laserTime+200,sprite=BulletSprites.round.red,speed=0,direction=dir1,radius=1,spriteTransparency=0,safe=true,invincible=true}
            local cir2=Circle{x=middle.x,y=middle.y,lifeFrame=laserTime+200,sprite=BulletSprites.round.red,speed=0,direction=dir1+math.pi,radius=1,spriteTransparency=0,safe=true,invincible=true}
            toothBase(cir1,num,laserTime,stopTime,distance)
            toothBase(cir2,num,laserTime,stopTime,distance)
            link(cir1,cir2)
            SFX:play('enemyCharge',true)
        end
        local function circling()
            local num,laserTime,stopTime=5,120,90
            local r=100
            local angle=math.eval(0,999)
            local earlyFrames={[0]=true,[20]= true,[40]= true,[55]= true,[67]= true,[77]= true,}
            Event.LoopEvent{
                obj=en,period=1,times=600,executeFunc=function (self,times)
                    angle=angle+math.pi/180*(1+times/400)
                    if times<80 then
                        if not earlyFrames[times] then
                            return
                        end
                    elseif times%8~=5 then
                        return
                    end
                    local x1,y1=Shape.rThetaPos(player.x,player.y,r,angle)
                    local x2,y2=Shape.rThetaPos(player.x,player.y,r,angle+math.pi)
                    spawnTeleBite(num,laserTime,stopTime,x1,y1,x2,y2)
                end
            }
        end
        local function chord(x,y,r,angle1,angle2)
            local num,laserTime,stopTime=3,120,90
            local x1,y1=Shape.rThetaPos(x,y,r,angle1)
            local x2,y2=Shape.rThetaPos(x,y,r,angle2)
            local phi1=Shape.to(x,y,x1,y1)
            local phi2=Shape.to(x,y,x2,y2)
            local d=0.15
            local a1,a2=phi1,phi2
            while math.angleDiff(a1,a2)>d*3 do
                a1=a1+d
                a2=a2-d
                local cx1,cy1=Shape.rThetaPos(x,y,r,a1)
                local cx2,cy2=Shape.rThetaPos(x,y,r,a2)
                spawnTeleBite(num,laserTime,stopTime,cx1,cy1,cx2,cy2)
            end
            a1,a2=phi1,phi2
            while math.angleDiff(a2,a1)>d*3 do
                a1=a1-d
                a2=a2+d
                local cx1,cy1=Shape.rThetaPos(x,y,r,a1)
                local cx2,cy2=Shape.rThetaPos(x,y,r,a2)
                spawnTeleBite(num,laserTime,stopTime,cx1,cy1,cx2,cy2)
            end
        end
        local angle0=math.eval(0,999)
        randChord=function()
            angle0=math.eval(angle0+math.pi/2,1)
            local angleDiff=math.pi/2+math.randomSign()*math.eval(0.3,0.2)
            chord(player.x,player.y,100,angle0-angleDiff,angle0+angleDiff)
        end
        -- circling()
        a=Event.LoopEvent{
            obj=en,period=200,frame=140,executeFunc=function(self)
                if color=='blue' then
                    color='cyan'
                else
                    color='blue'
                end
                randChord()
                if Shape.distanceObj(player,en)>130 then
                    Event.LoopEvent{
                        obj=en,period=1,times=60,executeFunc=function (self,times)
                            Shape.moveTowards(en,player,1-times/60)
                        end
                    }
                end
            end
        }
    end,
}