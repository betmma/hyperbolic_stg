return {
    quote='?',
    user='reisen',
    spellName='Illusion Light "Void Moon"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1500
        local a,b,t
        local en
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            a.spawnEvent.frame=290
            b.spawnEvent.frame=50
            t=0
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
        local function shadeBullet(cir,args,self)
            local hpLevel=en:getHPLevel()
            local time=hpLevel<=2 and 50 or 80
            Event.LoopEvent{
                obj=cir,
                period=1,
                conditionFunc=function()
                    return t%300==0
                end,
                times=3,
                executeFunc=function()
                    cir.safe=true
                    cir.spriteTransparency=cir.aim_transparency or 0.15
                    Event.LoopEvent{
                        obj=cir,
                        period=1,
                        times=time,
                        executeFunc=function(self,times)
                            if times>=time-10 then
                                cir.spriteTransparency=(times-time+10)/10+0.1
                            end
                            if times==time-1 then
                                cir.safe=false
                                cir.spriteTransparency=1
                                cir:changeSpriteColor('blue')
                                if not cir.aim_transparency then
                                    cir.speed=60
                                end
                            end
                        end
                    }
                end
            }
        end
        t=0
        local bullets={}
        a=BulletSpawner{x=400,y=300,period=300,frame=290,lifeFrame=10000,bulletNumber=2,bulletSpeed=80,bulletLifeFrame=1200,angle='0',range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bigRound.red,highlight=true,bulletSize=4,invincible=true,bulletEvents={
            function (cir,args,self)
                bullets[args.index]=cir
                cir.direction=math.eval('0+999')
                if args.index==2 then
                    cir.direction=bullets[1].direction+math.eval('1.57+1')
                    local bullet1=bullets[1]
                    local ratio=math.eval('0.5+0.3')
                    bullet1.ratio=ratio
                    bullet1.radius=bullet1.radius*ratio
                    cir.ratio=1-ratio
                    cir.radius=cir.radius*(1-ratio)
                end
                cir.speed=math.eval('60+30')
                local t=args.index<=2 and 160 or 80
                Event.EaseEvent{
                    obj=cir,
                    aimTable=cir,
                    aimKey='speed',
                    aimValue=0,
                    easeFrame=t
                }
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=t+80,
                    executeFunc=function()
                        if args.index==1 then
                            local bullet2=bullets[2]
                            local distance=Shape.distance(cir.x,cir.y,bullet2.x,bullet2.y)
                            local ratio=cir.ratio
                            local baseSpeed=distance/70*60 -- 300-120=180 frames from shade effect. 
                            BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=300,bulletSpeed=baseSpeed*ratio,bulletLifeFrame=18000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bigRound.red,highlight=true,bulletEvents={shadeBullet}}
                            BulletSpawner{x=bullet2.x,y=bullet2.y,period=1,frame=0,lifeFrame=2,bulletNumber=300,bulletSpeed=baseSpeed*(1-ratio),bulletLifeFrame=18000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bigRound.red,highlight=true,bulletEvents={shadeBullet}}
                        end
                        if args.index>2 then -- if more than 2 bullets, don't calculate the distance and just use a slow speed (though not used cuz it's so chaotic)
                            BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=300,bulletSpeed=20,bulletLifeFrame=18000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bigRound.red,highlight=true,bulletEvents={shadeBullet}}
                        end
                        cir:remove()
                    end
                }
                local hpLevel=en:getHPLevel()
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function()
                        -- create a white fog effect
                        Circle{x=cir.x,y=cir.y,direction=math.pseudoRandom(cir)*math.pi*2,speed=math.pseudoRandom(cir,2)*60,sprite=BulletSprites.fog.gray,lifeFrame=30,spriteTransparency=0.23-.03*hpLevel,radius=cir.radius*hpLevel,highlight=true,safe=true}
                    end
                }
            end
        }}
        b=BulletSpawner{x=400,y=300,period=150,frame=50,lifeFrame=10000,bulletNumber=30,bulletSpeed=20,bulletLifeFrame=1200,angle='0+999',range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bullet.red,bulletEvents={
            shadeBullet,
            function(cir,args,self)
                cir.aim_transparency=0.5 -- these bullets don't overlap much, if use 0.15 it's hard to discern
                local hpLevel=en:getHPLevel()
                if hpLevel==1 then
                    cir.speed=cir.speed-args.index%2*10
                elseif hpLevel>=2 then
                    cir.speed=cir.speed-args.index%3*7
                end
            end
        }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                t=t+1
                local t2=t%300
                if t2==250 then
                    SFX:play('enemyCharge',true)
                elseif t2==0 then
                    SFX:play('enemyPowerfulShot',true)
                elseif t2==100 then
                    -- SFX:play('enemyPowerfulShot',true)
                end
                local hpLevel=en:getHPLevel()
                if hpLevel==1 then
                    b.bulletNumber=40
                elseif hpLevel==2 then
                    b.bulletNumber=60
                    -- a.bulletNumber=3
                else
                    if t%300==150 then
                        BulletSpawner{x=400,y=300,period=1,frame=0,lifeFrame=1,bulletNumber=150,bulletSpeed=10,bulletLifeFrame=1200,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bullet.red,highlight=true,bulletEvents={shadeBullet,
                        function(cir,args,self)
                            cir.aim_transparency=0.3
                        end}}
                    end
                end
            end
        }
        
    end
}