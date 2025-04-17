return {
    quote='?',
    user='utsuho',
    spellName='Atomic Fire "Nuclear Experiment Expansion"', 
    make=function()
        G.levelRemainingFrame=9000
        Shape.removeDistance=2000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=12600,hpSegments={0.7,0.4}}
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
        local a,hpp
        local randSpeed='30+50'
        local nukes={}
        local flag1=false
        local flag2=false
        a=BulletSpawner{x=400,y=300,period=300,frame=240,lifeFrame=10000,bulletNumber=30,bulletSize=0.07,bulletSpeed=30,bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.nuke,bulletEvents={
            function(cir,args,self)
                local t0=a.frame
                cir.speed=math.eval(randSpeed)
                cir.x=cir.x+math.eval('0+20')
                cir.y=cir.y+math.eval('0+20')
                Event.EaseEvent{
                    obj=cir,
                    aimTable=cir,
                    aimKey='speed',
                    aimValue=60,
                    easeFrame=120
                }
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    conditionFunc=function()return not player.border:inside(cir.x,cir.y) and not flag2 end,
                    executeFunc=function()
                        player.border:reflection(cir)
                    end
                }
                if args.index==1 then
                    nukes[t0]={cir}
                else
                    table.insert(nukes[t0],cir)
                end
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=120,
                    executeFunc=function()
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=0,
                            easeFrame=30
                        }
                    end
                }
                local ratio=1.1-hpp*0.2
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=180,
                    executeFunc=function()
                        SFX:play('enemyPowerfulShot',true)
                        local e
                        e=Event.LoopEvent{
                            obj=cir,
                            period=1,
                            times=30,
                            conditionFunc=function()
                                if cir.radius<8 then return true end
                                local flag=true
                                for i,v in ipairs(nukes[t0]) do
                                    if cir~=v and Shape.distance(cir.x,cir.y,v.x,v.y)*ratio<cir.radius+v.radius then
                                        flag=false
                                        e:remove()
                                        break
                                    end
                                end
                                return flag
                            end,
                            executeFunc=function()
                                cir.radius=cir.radius+2
                            end
                        }
                    end
                }
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=240,
                    executeFunc=function()
                        if cir.radius>10 then 
                            BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=math.ceil(math.sinh((cir.radius+10)/100)*50*(2-hpp)),bulletSpeed=20,bulletLifeFrame=1000,angle='0+999',bulletSprite=BulletSprites.round.blue,highlight=true}
                        end
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='radius',
                            aimValue=0,
                            easeFrame=80,
                        afterFunc=function()
                            if args.index==1 then
                                nukes[t0]=nil
                            end
                            cir:remove()
                            
                        end
                        }
                    end
                }
            end
        }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                hpp=en.hp/en.maxhp
                a.spawnEvent.period=100*(2+1*hpp)
                if hpp>0.7 then
                    a.bulletNumber=math.ceil(10*(1+2*hpp))
                else
                    if not flag1 then
                        flag1=true
                        SFX:play('enemyCharge',true)
                        Effect.Shockwave{x=400,y=300,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove={bullet=true,invincible=true}}
                        a.bulletSize=0.2
                        randSpeed='50+20'
                        a.spawnEvent.frame=a.spawnEvent.period-60
                    end
                    a.bulletNumber=5
                end
                if hpp<0.4 then
                    if not flag2 then
                        flag2=true
                        SFX:play('enemyCharge',true)
                        Effect.Shockwave{x=400,y=300,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove={bullet=true,invincible=true}}
                        a.bulletSize=0.1
                        randSpeed='20+10'
                        a.spawnEvent.frame=a.spawnEvent.period-60
                        Event.EaseEvent{
                            obj=en,
                            aimTable=en,
                            aimKey='y',
                            aimValue=50,
                            easeFrame=120,
                            progressFunc=Event.sineOProgressFunc
                        }
                    end
                    a.spawnEvent.period=100*(0.4+5*hpp)
                end
                
            end
        }
    end
}