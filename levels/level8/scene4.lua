return {
    ID=63,
    quote='?',
    user='sakuya',
    spellName='Conjuring "The Clock that Doesn\'t Tell Time"', -- lenen reference lol
    make=function()
        G.backgroundPattern:remove()
        G.backgroundPattern=BackgroundPattern.Pendulum{amplitude=0}
        Event.EaseEvent{
            obj=G.backgroundPattern,
            aimTable=G.backgroundPattern,
            aimKey='colorRatio',
            aimValue=1,
            easeFrame=240
        }
        Event.EaseEvent{
            obj=G.backgroundPattern,
            aimTable=G.backgroundPattern,
            aimKey='amplitude',
            aimValue=0.05,
            easeFrame=240
        }
        G.levelRemainingFrame=7200
        Shape.removeDistance=1000
        local a,b,t
        local en
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            a.spawnEvent.frame=a.spawnEvent.period-60
            if hpLevel==2 then
                Event.DelayEvent{
                    obj=en,
                    delayFrame=60,
                    executeFunc=function()
                        SFX:play('enemyCharge',true)
                        Event.EaseEvent{
                            obj=en,
                            aimTable=G.backgroundPattern,
                            aimKey='amplitude',
                            aimValue=0.1,
                            easeFrame=600
                        }
                    end
                }
            end
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
        local period=120 -- 2 seconds, same as the period of pendulum clock
        local r=500
        local amplitude=0.05
        local bulletSpeed=30
        local dx,dy,dx2,dy2
        a=BulletSpawner{x=400,y=300,period=120,frame=60,lifeFrame=10000,bulletNumber=8,bulletSpeed=bulletSpeed,bulletLifeFrame=12000,angle=0,range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.knife.red,bulletEvents={
            function(cir,args,self)
                cir.safe=true
                cir.spriteTransparency=0
                local visibleCir=Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=cir.speed,sprite=a.bulletSprite,lifeFrame=10000,spriteTransparency=1}
                local hpLevel=en:getHPLevel()
                Event.LoopEvent{
                    obj=visibleCir,
                    period=1,
                    executeFunc=function(self)
                        if cir.removed then
                            visibleCir:remove()
                        end
                    end
                }
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function(self,times)
                        if visibleCir.removed then
                            cir:remove()
                        end
                        local ratio=0
                        if hpLevel>1 then
                            ratio=-(cir.y-Shape.axisY)/(300-Shape.axisY)
                        end
                        visibleCir.x,visibleCir.y=cir.x+dx2*ratio,cir.y+dy2*ratio
                        visibleCir.direction=cir.direction
                        visibleCir.speed=cir.speed
                        local t=en.frame
                        if t%(period)==0 or t%(period)==period/2 then
                            cir.speed=cir.speed+50
                            Event.EaseEvent{
                                obj=cir,
                                aimTable=cir,
                                aimKey='speed',
                                aimValue=cir.speed-50,
                                easeFrame=period/10
                            }
                        end
                    end
                }
                if visibleCir.sprite==BulletSprites.knife.red then
                    Event.LoopEvent{
                        obj=cir,
                        period=1,
                        times=1,
                        conditionFunc=function()return not player.border:inside(cir.x,cir.y) end,
                        executeFunc=function()
                            player.border:reflection(cir)
                            visibleCir:changeSpriteColor('blue')
                        end
                    }
                end

            end
        }
        }
        

        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                amplitude=G.backgroundPattern.amplitude or 0
                local t=en.frame
                local theta=amplitude*math.sin(-t/period*math.pi*2)
                dx,dy=r*math.sin(theta),r*(math.cos(theta)-1)
                G.viewMode.viewOffset.x, G.viewMode.viewOffset.y=dx,dy
                local naturalDirection=player.naturalDirection
                dx2,dy2=dx*math.cos(naturalDirection)-dy*math.sin(naturalDirection),dx*math.sin(naturalDirection)+dy*math.cos(naturalDirection)
                if t%(period)==0 or t%(period)==period/2 then
                    SFX:play('graze',true,amplitude/0.05) -- mimic clock ticking sound
                end
                local hpLevel=en:getHPLevel()
                if hpLevel>=2 then
                    a.bulletSprite=BulletSprites.knife.green
                end
                if a.spawnEvent.frame==1 then
                    local angle=a.angle
                    if hpLevel==1 then
                        Event.LoopEvent{
                            obj=a,
                            period=1,
                            times=16,
                            executeFunc=function(self,times)
                                a.angle=angle+0.02*(times%8)
                                a.bulletSpeed=bulletSpeed-2*math.floor(times/8)
                                a:spawnBatchFunc()
                            end
                        }
                    elseif hpLevel==2 then
                        Event.LoopEvent{
                            obj=a,
                            period=1,
                            times=24,
                            executeFunc=function(self,times)
                                a.angle=angle+0.02*(times+math.floor(times/4))*math.mod2Sign(times)
                                a.bulletSpeed=bulletSpeed-2*math.floor(times/4)
                                a:spawnBatchFunc()
                            end
                        }
                    else
                        Event.LoopEvent{
                            obj=a,
                            period=1,
                            times=24,
                            executeFunc=function(self,times)
                                a.angle=angle+0.02*(times+math.floor(times/4))*(times%4==0 and 1 or -1)
                                a.bulletSpeed=bulletSpeed-2*math.floor(times/4)
                                a.bulletSprite=times%8==0 and BulletSprites.knife.red or BulletSprites.knife.green
                                a:spawnBatchFunc()
                            end
                        }

                    end
                elseif a.spawnEvent.frame==60 then
                    a.bulletSpeed=bulletSpeed
                    a.angle=math.eval(0,999)
                end
            end
        }
        
    end
}