return {
    ID=64,
    quote='?',
    user='junko',
    spellName='"Sterile Flowers of Murderous Intent"', 
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1000
        local colors={'','blue','purple'}
        local a
        local en
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            if hpLevel==2 then
                a.spawnEvent.period=200
                a.bulletNumber=576
                a.bulletLifeFrame=350
                Shape.removeDistance=1000
                a.bulletSprite=BulletSprites.scale[colors[3]]
            end
            if hpLevel==1 then
                a.spawnEvent.period=150
                a.bulletNumber=720
                a.bulletLifeFrame=250
                Shape.removeDistance=800
                a.bulletSprite=BulletSprites.scale[colors[2]]
            end
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
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        a=BulletSpawner{x=400,y=300,period=150,frame=80,lifeFrame=10000,bulletNumber=448,bulletSpeed=50,bulletLifeFrame=350,angle=math.eval(0,360),range=math.pi*2,bulletSprite=BulletSprites.scale.yellow,bulletEvents={
            function(cir,args,self)
                local ns,nd=32,14
                local hpLevel=en:getHPLevel()
                if hpLevel==3 then
                    ns,nd=7,32
                elseif hpLevel==2 then
                    ns,nd=16,18
                end
                local index=args.index
                local mods,modd=index%ns,index%nd
                local dspeed=math.sin(mods*math.pi/ns)*50
                Event.EaseEvent{
                    obj=cir,
                    aimTable=cir,
                    aimKey='speed',
                    aimValue=cir.speed-dspeed,
                    easeFrame=120,
                    progressFunc=function(x)return math.sin(x*math.pi) end
                }
                if hpLevel==2 then
                    Event.DelayEvent{
                        obj=cir,
                        delayFrame=60,
                        executeFunc=function()
                            Event.EaseEvent{
                                obj=cir,
                                aimTable=cir,
                                aimKey='speed',
                                aimValue=cir.speed+100,
                                easeFrame=150,
                                progressFunc=Event.sineIOProgressFunc
                            }
                        end
                    }
                end
                local t=150
                if hpLevel==2 then
                    t=60
                end
                Event.EaseEvent{
                    obj=cir,
                    aimTable=cir,
                    aimKey='direction',
                    aimValue=cir.direction+(modd-(nd-1)/2)*math.pi/22,
                    easeFrame=t,
                    progressFunc=function(x)return math.sin(x*math.pi) end
                }
            end
        }}
        

        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local hpLevel=en:getHPLevel()
                if a.spawnEvent.frame==a.spawnEvent.period-60 and hpLevel>=2 then
                    local sign=math.mod2Sign(a.spawnEvent.executedTimes)
                    local color=colors[hpLevel]
                    a.angle=math.eval(0,360)
                    for i=1,10 do
                        Laser{x=a.x,y=a.y,direction=math.pi*2/5*i+a.angle,speed=800,sprite=BulletSprites.laser[color],lifeFrame=140,warningFrame=60,radius=hpLevel,canRemovedByBulletRemover=true,
                        bulletEvents={
                            function(laser,args)
                                Event.LoopEvent{
                                    obj=laser,
                                    period=1,
                                    executeFunc=function()
                                        laser.direction=laser.direction+0.1*(i>5 and 1 or -1)
                                        laser.radius=laser.radius+0.05
                                    end
                                }
                            end
                        },
                        laserEvents={
                            function(laser,args)
                                Event.LoopEvent{
                                    obj=laser,
                                    period=1,
                                    executeFunc=function()
                                        laser.args.direction=laser.args.direction+0.005*sign
                                    end
                                }
                            end
                            }
                        }
                    end
                elseif a.spawnEvent.frame==a.spawnEvent.period-60 then
                    a.angle=math.eval(0,360)
                end
            end
        }
        
    end
}