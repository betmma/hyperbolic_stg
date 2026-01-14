return {
    ID=33,
    quote='Oh no, I can\'t find the direction home! Can compass work in this world?',
    user='seija',
    spellName='Turnabout "Change Orientation"',
    make=function()
        -- What this spellcard does is forcing player to look at the enemy by changing player's natural direction.
        G.levelRemainingFrame=5400
        Shape.removeDistance=1000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
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
        local b=BulletSpawner{x=400,y=300,period=5,frame=0,lifeFrame=6001,bulletNumber=24,bulletSpeed=30,angle=0,bulletLifeFrame=990000,bulletSprite=BulletSprites.blackrice.red,bulletEvents={
            function(cir)
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=40,
                    executeFunc=function()
                        cir.sprite=BulletSprites.rice.red
                        cir.speed=cir.speed+20
                        Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=0,sprite=BulletSprites.fog.red,lifeFrame=5,safe=true}
                    end
                }
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=80,
                    executeFunc=function()
                        cir.sprite=BulletSprites.blackrice.red
                        cir.speed=cir.speed-20
                        Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=0,sprite=BulletSprites.fog.red,lifeFrame=5,safe=true}
                    end
                }
            end
        }
        }
        local c=BulletSpawner{x=400,y=300,period=30,frame=0,lifeFrame=6001,bulletNumber=5,range=2,bulletSpeed=60,angle='player',bulletLifeFrame=990000,bulletSprite=BulletSprites.bigRound.blue,}
        Event.LoopEvent{
            obj=b,
            period=1,
            executeFunc=function()
                local t=b.frame%500
                local times=math.ceil(b.frame/2000)
                local hpPercent=en.hp/en.maxhp
                if t==0 then
                    b.spawnEvent.frame=0
                    b.spawnEvent.period=5
                elseif t==400 then
                    b.spawnEvent.period=9999
                end
                if times%2==0 then
                    b.angle=b.angle+0.004*(2-hpPercent)
                else
                    b.angle=b.angle-0.004*(2-hpPercent)
                end
                if hpPercent>0.8 then
                    c.spawnEvent.period=9999
                else
                    if not c.reset then
                        c.spawnEvent.frame=0
                        c.reset=true
                    end
                    c.spawnEvent.period=30*(1.5-hpPercent)
                end
            end
        }
        Event.LoopEvent{
            obj=en,
            period=300,
            executeFunc=function()
                Effect.Charge{obj=b,x=b.x,y=b.y}
                Event.DelayEvent{
                    obj=b,
                    delayFrame=100,
                    executeFunc=function()
                        local playerNaturalDirectionAtStart=player.naturalDirection
                        Event.EaseEvent{
                            obj=player,aimTable=player,aimKey='naturalDirection',aimValue=function()
                                return math.modClamp(Shape.to(player.x,player.y,en.x,en.y)+math.pi/2,playerNaturalDirectionAtStart,math.pi)
                            end,easeFrame=100,easeMode='hard',progressFunc=Event.sineIOProgressFunc
                        }
                    end
                }
            end
        }
        local lastNaturalDirection=player.naturalDirection
        Event.LoopEvent{
            obj=player,period=1,executeFunc=function()
                if math.angleDiff(player.naturalDirection,lastNaturalDirection)>0.1 then
                    EventManager.post(EventManager.EVENTS.LEVEL_7_3_FAST_TURN)
                end
                lastNaturalDirection=player.naturalDirection
            end
        }
    end
}