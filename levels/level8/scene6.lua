return {
    ID=181,
    user='sakuya',
    spellName='Illusion Existence "Doppleganger"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local a,b
        local en
        local spawners,sequence
        local swapSign=false
        en=Enemy{x=400,y=600000,mainEnemy=true,maxhp=6400,hpSegments={0.75,0.5,0.25},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            a:remove()
            b:remove()
            en.frame=0
            Shape.timeSpeed=1
            swapSign=false
            local spawner=spawners[sequence[hpLevel+1]]
            a=BulletSpawner(spawner)
            a.swap=false
            spawner.bulletSprite=BulletSprites.knife.blue
            b=BulletSpawner(spawner)
            b.swap=true
            a.x,a.y=en.x,en.y
            b.x,b.y=en.x,en.y
            en:addHPProtection(600,10)
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=1200000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=600000}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local signal
        local rotateFrame,moveFrame=30,60
        local swapBase=function(cir)
            if signal then
                local partner=cir.partner
                if not partner or partner.removed then
                    return
                end
                local cirSpeedRef=cir.speed
                local partnerSpeedRef=partner.speed
                local cirDirectionRef=cir.direction
                local partnerDirectionRef=partner.direction
                local cirPosRef={x=cir.x,y=cir.y}
                local partnerPosRef={x=partner.x,y=partner.y}
                local distance=Shape.distanceObj(cir,partner)
                local cir2partner=math.modClamp(Shape.to(cir.x,cir.y,partner.x,partner.y),cir.direction,math.pi)
                local partner2cir=math.modClamp(Shape.to(partner.x,partner.y,cir.x,cir.y),partner.direction,math.pi)
                if cir.x==partner.x and cir.y==partner.y then
                    cir2partner=cir.direction
                    partner2cir=partner.direction
                end
                cir.speed=0
                partner.speed=0
                Event.EaseEvent{
                    obj=cir,easeFrame=rotateFrame,aimKey='direction',aimValue=cir2partner,
                    progressFunc=Event.sineOProgressFunc
                }
                Event.EaseEvent{
                    obj=partner,easeFrame=rotateFrame,aimKey='direction',aimValue=partner2cir,
                    progressFunc=Event.sineOProgressFunc
                }
                Event.DelayEvent{
                    obj=cir,delayFrame=rotateFrame,
                    executeFunc=function()
                        Event.LoopEvent{
                            obj=cir,
                            period=1,times=moveFrame,
                            executeFunc=function()
                                Shape.moveTowards(cir,partnerPosRef,distance/moveFrame,true)
                                Shape.moveTowards(partner,cirPosRef,distance/moveFrame,true)
                            end
                        }
                    end
                }
                Event.DelayEvent{
                    obj=cir,delayFrame=rotateFrame+moveFrame,
                    executeFunc=function()
                        Event.EaseEvent{
                            obj=cir,easeFrame=rotateFrame,aimKey='direction',aimValue=partnerDirectionRef,
                            progressFunc=Event.sineOProgressFunc,
                            afterFunc=function()
                                cir.speed=partnerSpeedRef
                                partner.speed=cirSpeedRef
                            end
                        }
                        Event.EaseEvent{
                            obj=partner,easeFrame=rotateFrame,aimKey='direction',aimValue=cirDirectionRef,
                            progressFunc=Event.sineOProgressFunc
                        }
                    end
                }

            end
        end
        local function createPartner(cir)
            local partner=Circle{x=cir.x,y=cir.y,lifeFrame=cir.lifeFrame,direction=cir.direction,speed=cir.speed,safe=true,sprite=cir.sprite,spriteTransparency=0.1}
            cir.partner=partner
            partner.extraUpdate={
                function()
                    if cir.removed then
                        partner:remove()
                    end
                end
            }
            cir.extraUpdate[1]=swapBase
            return partner
        end
        local spawner1={x=400,y=600000,period=5,frame=-40,lifeFrame=10000,bulletNumber=5,bulletSpeed=80,bulletLifeFrame=500,angle=math.eval(0,999),range=math.pi*2,highlight=true,bulletSprite=BulletSprites.knife.red,bulletEvents={
            function(cir,args,self)
                local index=self.spawnEvent.executedTimes
                local partner=createPartner(cir)
                if swapSign==self.swap then
                    cir,partner=partner,cir
                end
                cir.speed=cir.speed+((index%4)*8)
                cir.direction=cir.direction-(index%4)*math.pi/50*(self.swap==true and -1 or 1)
            end
        }}
        local spawner2={x=400,y=600000,period=5,frame=-40,lifeFrame=10000,bulletNumber=4,bulletSpeed=40,bulletLifeFrame=500,angle=math.eval(0,999),range=math.pi*2,highlight=true,bulletSprite=BulletSprites.knife.red,bulletEvents={
            function(cir,args,self)
                local partner=createPartner(cir)
                Event.EaseEvent{
                    obj=cir,easeFrame=60,aimKey='speed',aimValue=80,
                }
                Event.EaseEvent{
                    obj=partner,easeFrame=60,aimKey='speed',aimValue=80,
                }
                if swapSign==self.swap then
                    cir,partner=partner,cir
                end
                cir.direction=cir.direction+math.pi/4
            end
        }}
        local spawner3={x=400,y=600000,period=180,frame=120,lifeFrame=10000,bulletNumber=40,bulletSpeed=40,bulletLifeFrame=360,angle='player',range=math.pi*0,highlight=true,bulletSprite=BulletSprites.knife.red,bulletEvents={
            function(cir,args,self)
                cir.invincible=true
                local index=args.index-1
                local speed=index*6
                cir.speed=speed
                cir.direction=cir.direction-math.pi/2
                local partner=createPartner(cir)
                local function fadeout(cir)
                    Event.DelayEvent{
                    obj=cir,delayFrame=280,
                    executeFunc=function()
                        cir.safe=true
                        cir.partner.safe=true
                        Event.EaseEvent{
                            obj=cir,easeFrame=60,aimKey='spriteTransparency',aimValue=0,
                        }
                        Event.EaseEvent{
                            obj=cir.partner,easeFrame=60,aimKey='spriteTransparency',aimValue=0,
                        }
                        end
                    }
                end
                fadeout(cir)
                if swapSign==self.swap then
                    cir,partner=partner,cir
                end
                partner.direction=partner.direction+math.pi
                local vertical=self.spawnEvent.executedTimes%2==1
                if vertical==true then
                    cir.speed=cir.speed-self.bulletNumber*3
                    partner.speed=math.modClamp(partner.speed+self.bulletNumber*3,0,self.bulletNumber*6)
                end
                cir.extraUpdate[#cir.extraUpdate+1]=function(cir)
                    cir.direction=cir.direction+cir.speed/4750
                end
                partner.extraUpdate[#partner.extraUpdate+1]=function(partner)
                    partner.direction=partner.direction-partner.speed/4750
                end
                -- clock hands
                if index==1 then
                    local clockCenterx,clockCentery=Shape.rThetaPos(en.x,en.y,107.5,Shape.toObj(en,player))
                    local dir=math.eval(0,3.14)
                    local length=self.swap==true and 50 or 30
                    local player2en=Shape.toObj(player,en)
                    for r=0,length,5 do
                        local cir=Circle{x=clockCenterx,y=clockCentery,lifeFrame=360,direction=dir,sprite=self.bulletSprite,speed=r}
                        local partner=createPartner(cir)
                        partner.direction=(2*player2en-dir+(vertical==true and math.pi or 0))%(math.pi*2)
                        fadeout(cir)
                    end
                end
            end
        }}
        local spawner4={x=400,y=600000,period=90,frame=40,lifeFrame=10000,bulletNumber=100,bulletSpeed=40,bulletLifeFrame=800,angle='player',range=math.pi,highlight=true,bulletSprite=BulletSprites.knife.red,bulletEvents={
            function(cir,args,self)
                local index=args.index
                local partner=createPartner(cir)
                if swapSign==self.swap then
                    cir,partner=partner,cir
                end
                cir.speed=cir.speed+((index%5)*3)
                local mod=index%5
                cir.direction=cir.direction+(mod%2==0 and 5-mod or -mod)*math.pi/100
            end
        }}
        spawners={spawner1,spawner2,spawner3,spawner4}
        sequence={3,2,1,4}
        local spawner=spawners[sequence[1]]
        a=BulletSpawner(spawner)
        a.swap=false
        spawner.bulletSprite=BulletSprites.knife.blue
        b=BulletSpawner(spawner)
        b.swap=true
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local hpLevel=sequence[en:getHPLevel()]
                local t=en.frame%(hpLevel~=3 and 300 or 330)
                local startFrame=160
                local endFrame
                if hpLevel~=3 then
                    rotateFrame,moveFrame=30,60
                else
                    rotateFrame,moveFrame=30,90
                end
                endFrame=startFrame+rotateFrame*2+moveFrame
                if t==startFrame-30 then
                    SFX:play('start')
                end
                if t==startFrame then
                    signal=true
                    Shape.timeSpeed=0
                    swapSign=not swapSign
                    local aimX,aimY=Shape.rThetaPos(player.x,player.y,math.eval(hpLevel==4 and 50 or 30,10),math.eval(Shape.toObj(player,en),2))
                    local aim={x=aimX,y=aimY}
                    Event.LoopEvent{
                        obj=en,period=1,times=120,
                        executeFunc=function(self,times,maxTimes)
                            Shape.moveTowards(en,aim,Shape.distanceObj(en,aim)/40,true)
                            a.x,a.y=en.x,en.y
                            if hpLevel~=4 then
                                b.x,b.y=en.x,en.y
                            end
                        end
                    }
                elseif t==startFrame+1 then
                    signal=false
                elseif t==endFrame-20 then
                    SFX:play('stop')
                elseif t==endFrame then
                    Shape.timeSpeed=1
                end
                if hpLevel==4 then
                    b.x,b.y=Shape.rThetaPos(player.x,player.y,70,Shape.toObj(player,en)+math.pi)
                end
                if Shape.timeSpeed==0 then
                    a.spawnEvent.frame=a.spawnEvent.frame-1
                    b.spawnEvent.frame=b.spawnEvent.frame-1
                else
                    if hpLevel==1 then
                        a.angle=a.angle+0.01
                        b.angle=b.angle-0.01
                    end
                end
                if hpLevel==2 then
                    if t==280 then
                        a.angle=math.eval(0,999)
                        b.angle=a.angle+math.pi
                    end
                end
            end
        }
    end
}