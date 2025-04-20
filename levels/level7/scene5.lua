return {
    user="?",
    spellName="?",
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local a
        local en
        en=Enemy{x=400,y=400000,mainEnemy=true,maxhp=9600000,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            a.spawnEvent.frame=a.spawnEvent.period-60
            en:addHPProtection(600,10)
            Event.EaseEvent{
                obj=en,
                easeFrame=60,
                aimTable=en,
                aimKey='r2',
                aimValue=en.r2+10
            }
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local poses={}
        for i = 1, 30, 1 do
            local nx,ny=Shape.rThetaPos(400,600000,700,math.pi/15*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        en.r2=30

        local function circleEffect(cir)
            Event.LoopEvent{
                obj=cir,
                period=1,
                conditionFunc=function(self)return Shape.distance(cir.x,cir.y,player.x,player.y)<en.r2 end,
                executeFunc=function(self)
                    local times=0
                    while Shape.distance(cir.x,cir.y,player.x,player.y)<en.r2 and times<50 do
                        times=times+1
                        cir:updateMove(1/60)
                        local nx,ny=cir.x,cir.y
                        -- local nx,ny,newDir=Shape.rThetaPos(cir.x,cir.y,1,cir.direction)
                        -- cir.x=nx
                        -- cir.y=ny
                        -- cir.direction=newDir
                        Circle{x=nx,y=ny,direction=0,speed=0,sprite=cir.sprite,invincible=true,lifeFrame=0,batch=Asset.bulletHighlightBatch,}
                        cir:checkHitPlayer()
                    end
                end
            }
        end

        a=BulletSpawner{x=400,y=400000,period=160,frame=100,lifeFrame=10000,bulletNumber=4,bulletSpeed=80,bulletLifeFrame=125,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.giant.yellow,bulletEvents={
            function(cir,args,self)
                local index=args.index
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=60,
                    executeFunc=function()
                        cir.speed=0
                        local distanceAim=(50+en.r2)
                        local angleAim=index/a.bulletNumber*math.pi*2
                        local angle=math.modClamp(Shape.to(player.x,player.y,cir.x,cir.y),angleAim)
                        local ratio=0.94
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                local distance=Shape.distance(cir.x,cir.y,player.x,player.y)
                                distance=distance*ratio+distanceAim*(1-ratio)
                                angle=angle*ratio+angleAim*(1-ratio)
                                angleAim=angleAim+0.03
                                cir.x,cir.y=Shape.rThetaPos(player.x,player.y,distance,angle)
                            end
                        }
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=50,
                            executeFunc=function()
                                Event.EaseEvent{
                                    obj=cir,
                                    easeFrame=14,
                                    aimTable=cir,
                                    aimKey='radius',
                                    aimValue=cir.radius*2,
                                    afterFunc=function()
                                        BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=20,bulletSpeed=60,bulletLifeFrame=1000,angle=math.pi/2,bulletSprite=BulletSprites.scale.green,
                                        -- fogEffect=true,fogTime=120,
                                        spawnCircleRadius=20,bulletEvents={
                                            function(cir2,args)
                                                circleEffect(cir2)
                                                Event.LoopEvent{
                                                    obj=cir2,
                                                    period=1,
                                                    executeFunc=function()
                                                        cir2.direction=cir2.direction+0.056
                                                    end
                                                }
                                            end
                                        }
                                        }
                                        cir:remove()
                                    end
                                }
                            end
                        }
                    end
                }
            end
        }}

        Event.LoopEvent{
            obj=en,
            period=240,
            frame=120,
            executeFunc=function()
                local aimX,aimY=Shape.rThetaPos(player.x,player.y,math.eval(30,30),math.eval(0,999))
                SFX:play('enemyShot')
                Event.LoopEvent{
                    obj=en,period=1,times=120,
                    executeFunc=function()
                        Shape.moveTowards(en,{x=aimX,y=aimY},Shape.distance(en.x,en.y,aimX,aimY)/60)
                        a.x,a.y=en.x,en.y
                    end
                }
            end
        }
        
        Event.DelayEvent{
            obj=en,
            period=30,
            executeFunc=function()
                SFX:play('enemyPowerfulShot',true)
                local drawRef=a.draw
                a.draw=function(self)
                    local colorref={love.graphics.getColor()}
                    love.graphics.setColor(1,0,0,0.5)
                    Shape.drawCircle(player.x,player.y,en.r2,'fill')
                    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4] or 1)
                    drawRef(self)
                end
            end
        }
    end
}