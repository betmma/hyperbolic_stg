return {
    quote='?',
    user='utsuho',
    spellName='Explosion Sign "Critical Mass"', -- a pun on nuclear critical mass and the "critical" bullet player needs to identify
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=2000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200,hpSegments={0.5}}
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
        local function q(cir)
            cir.speed=math.eval('50+50')
            cir.x=cir.x+math.eval('0+20')
            cir.y=cir.y+math.eval('0+20')
            Event.EaseEvent{
                obj=cir,
                aimTable=cir,
                aimKey='speed',
                aimValue=20,
                easeFrame=120
            }
            Event.LoopEvent{
                obj=cir,
                period=1,
                conditionFunc=function()return not player.border:inside(cir.x,cir.y) end,
                executeFunc=function()
                    player.border:reflection(cir)
                end
            }
        end
        local a
        local t0=480
        a=BulletSpawner{x=400,y=300,period=600,frame=540,lifeFrame=10000,bulletNumber=40,bulletSpeed=30,bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bigRound.red,bulletEvents={
            function(cir,args,self)
                q(cir)
                if args.index==1 then
                    BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=1,bulletNumber=20,bulletSpeed=20,bulletLifeFrame=10000,angle='0+999',bulletSprite=BulletSprites.dot.red,bulletEvents={
                        function(cir,args,self)
                            q(cir)
                        end}}
                    cir.invincible=true
                    local count=0
                    Event.LoopEvent{
                        obj=cir,
                        period=1,
                        times=t0,
                        executeFunc=function()
                            local t=cir.frame
                            if t<t0-200 and t%40==0 or t0-200<=t and t<t0-80 and t%20==0 or t0-80<=t and t%10==0 then
                                if count%2==0 then
                                    cir:changeSpriteColor('blue')
                                else
                                    cir:changeSpriteColor('red')
                                end
                                local distance=Shape.distance(cir.x,cir.y,player.x,player.y)
                                local volume=math.max(0.5,1-distance/50)
                                SFX:play('graze',true,volume)
                                count=count+1
                            end
                        end
                    }
                    Event.DelayEvent{
                        obj=cir,
                        delayFrame=t0,
                        executeFunc=function()
                            cir:remove()
                            local p
                            p=BulletSpawner{x=cir.x,y=cir.y,period=2,frame=0,lifeFrame=60,bulletNumber=50,bulletSpeed=80,bulletLifeFrame=150,angle=0,spawnCircleRadius=20,bulletSprite=BulletSprites.bigRound.yellow,highlight=true,bulletEvents={
                                function(cir,args,self)
                                    if args.index==1 then
                                        p.spawnCircleRadius=p.spawnCircleRadius+0.35
                                    end
                                    cir.spriteTransparency=0.1
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='spriteTransparency',
                                        aimValue=1,
                                        easeFrame=30
                                    }
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='speed',
                                        aimValue=150,
                                        easeFrame=30
                                    }
                                    Event.LoopEvent{
                                        obj=cir,
                                        period=1,
                                        times=30,
                                        executeFunc=function()
                                            cir.direction=cir.direction+(args.index%2*2-1)*0.04+math.eval('0+0.04')
                                        end
                                    }
                                end
                            }
                            }
                            Effect.Shockwave{x=cir.x,y=cir.y,lifeFrame=20,radius=15,growSpeed=1.02,color='yellow'}
                            SFX:play('enemyPowerfulShot',true)
                        end
                    }
                end
            end
        }}
        local hpflag=false
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local fr=(a.spawnEvent.frame-540)%600
                if fr==120 then
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='y',
                        aimValue=30,
                        easeFrame=120,
                        progressFunc=Event.sineOProgressFunc
                    }
                end
                if fr==560 then
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='y',
                        aimValue=300,
                        easeFrame=120,
                        progressFunc=Event.sineOProgressFunc
                    }
                end
                local hpp=en.hp/en.maxhp
                if en.frame>500 then
                    a.bulletNumber=20
                end
                if hpp<0.5 and not hpflag then
                    hpflag=true
                    SFX:play('enemyCharge',true)
                    Effect.Shockwave{x=en.x,y=en.y,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove={bullet=true,invincible=true}}
                    a.spawnEvent.frame=540
                end 
                if hpp<0.5 and fr==81 then
                    a.bulletSprite=BulletSprites.giant.red
                    t0=260
                    a:spawnBatchFunc()
                    t0=480
                    a.bulletSprite=BulletSprites.bigRound.red
                end
            end
        }
    end
}