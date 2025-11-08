return {
    ID=83,
    user='okina',
    spellName='Secret Ceremony "One Eyed Bat"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local a,b
        local en
        en=Enemy{x=400,y=1600000,mainEnemy=true,maxhp=12600,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            a.lifeFrame=91
            a.bulletSprite=BulletSprites.scale.orange
            en:addHPProtection(600,10)
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=800000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local poses={}
        for i = 1, 30, 1 do
            local nx,ny=Shape.rThetaPos(400,600000,700,math.pi/15*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player

        a={x=400,y=1600000,period=30,frame=0,speed=20,lifeFrame=61,bulletNumber=20,bulletSpeed=70,bulletLifeFrame=1000,angle=0,range=0,highlight=true,bulletSprite=BulletSprites.scale.purple,fogEffect=true,fogTime=3,bulletEvents={
            function(cir,args,self)
                local hpLevel=en._hpLevel
                local index=args.index
                local sign=math.mod2Sign(index)
                local div2=math.ceil(index/2)
                cir.direction=cir.direction+math.pi/2*sign
                cir.speed=cir.speed-div2*3
                cir.extraUpdate[1]=function(cir)
                    cir.direction=cir.direction-cir.speed/Shape.curvature/60*sign*(1+div2/10*(0.7+hpLevel*0.15))
                end
            end
        }}
        Event.DelayEvent{
            obj=en,delayFrame=60,executeFunc=function() -- give a broader view of backside
                SFX:play('enemyPowerfulShot')
                Event.EaseEvent{
                    obj=en,aimTable=G.viewMode.viewOffset,aimKey='y',aimValue=-200,easeFrame=180,progressFunc=Event.sineIOProgressFunc
                }
                Event.EaseEvent{
                    obj=en,aimTable=Shape,aimKey='axisY',aimValue=-50,easeFrame=180,progressFunc=Event.sineIOProgressFunc
                }
            end
        }
        Event.LoopEvent{
            obj=en,
            period=120,
            frame=110,
            executeFunc=function()
                local angle=math.pi/12*math.eval(0,1)
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    times=60,
                    executeFunc=function()
                        local nx,ny=Shape.rThetaPos(player.x,player.y,150,player.naturalDirection+math.pi/2+angle)
                        local enemyToAimDistance=Shape.distance(nx,ny,en.x,en.y)
                        Shape.moveTowards(en,{x=nx,y=ny},math.min(1.2,enemyToAimDistance/4),true)
                        -- a.x,a.y=en.x,en.y
                    end
                }
                local hpLevel=en:getHPLevel()
                Event.DelayEvent{
                    obj=en,delayFrame=60,executeFunc=function()
                        SFX:play('enemyShot',true,1)
                        a.x,a.y=en.x,en.y
                        local angle=Shape.to(a.x,a.y,player.x,player.y)
                        a.angle=angle
                        local spawner=BulletSpawner(a)
                        spawner.direction=angle
                        local round=BulletSpawner{x=en.x,y=en.y,period=1,frame=0,speed=30,direction=angle,lifeFrame=500,bulletNumber=20,bulletSpeed=0,bulletLifeFrame=1,angle=0,range=0,highlight=true,spawnCircleRadius=5+5*hpLevel,bulletSprite=BulletSprites.bigRound.red}
                    end
                }
            end
        }
    end
}