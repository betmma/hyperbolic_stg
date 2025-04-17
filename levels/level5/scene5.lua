return {
    quote='?',
    user='clownpiece',
    spellName='Hell Sign "Erroneous Orbit"', 
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=2000
        local a
        local en
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            a.spawnEvent.frame=a.spawnEvent.period-60
            en:addHPProtection(600,10)
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local poses={}
        for i = 1, 12, 1 do
            local nx,ny=Shape.rThetaPos(400,300,100,math.pi/6*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local modf=function(x,m) return x%(2*m)<m end
        a=BulletSpawner{x=400,y=300,period=300,frame=240,lifeFrame=10000,bulletNumber=3,bulletSpeed=20,bulletLifeFrame=300,angle='1.57+1',range=math.pi*0,spawnCircleRadius=50,spawnCircleAngle='0+999',fogEffect=true,fogTime=30,bulletSprite=BulletSprites.bigStar.red,bulletEvents={
            function(cir,args,self)
                local hpLevel=en:getHPLevel()
                if args.index==1 then
                    SFX:play('enemyPowerfulShot',true)
                end
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=299,
                    executeFunc=function()
                        BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=20,bulletSpeed=20,bulletLifeFrame=1000,angle='0+999',bulletSprite=BulletSprites.bigStar.blue,highlight=true}
                    end
                }
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function()
                        local dir=Shape.to(cir.x,cir.y,a.x,a.y)
                        local vx,vy=cir.speed*math.cos(cir.direction),cir.speed*math.sin(cir.direction)
                        local dv
                        local dis=Shape.distance(cir.x,cir.y,a.x,a.y)
                        if hpLevel==2 then
                            dv=1000*dis^-2
                        elseif hpLevel==1 then
                            dv=dis/30
                        else
                            dir=Shape.to(cir.x,cir.y,player.x,player.y)
                            -- dis=Shape.distance(cir.x,cir.y,player.x,player.y)
                            dv=2
                        end
                        vx=vx+dv*math.cos(dir)
                        vy=vy+dv*math.sin(dir)
                        cir.direction=math.atan2(vy,vx)
                        cir.speed=math.sqrt(vx^2+vy^2)
                        if cir.frame%1==0 then
                            cir.count=(cir.count or 0)+1
                            local c=Circle{x=cir.x,y=cir.y,direction=cir.direction+math.pi/2*math.mod2Sign(cir.count),speed=0,sprite=BulletSprites.star[modf(cir.count,1) and 'red' or 'blue'],lifeFrame=1000}
                            Event.DelayEvent{
                                obj=c,
                                delayFrame=300-cir.frame+(modf(cir.count,2*hpLevel) and 60 or 0),
                                executeFunc=function()
                                    Event.EaseEvent{
                                        obj=c,
                                        aimTable=c,
                                        aimKey='speed',
                                        aimValue=30,
                                        easeFrame=120
                                    }
                                end
                            }
                        end
                    end
                }
            end
        }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()

            end
        }
        
    end
}