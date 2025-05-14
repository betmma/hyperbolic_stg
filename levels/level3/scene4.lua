return {
    ID=34,
    quote='What is she doing? I don\'t think my orientation has changed, but the world is still spinning...',
    user='seija',
    spellName='Turnabout "Change Projection"',
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=2000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600}
        -- the angle of normal rotation. What this spellcard does is to replace hyperbolic rotation with normal rotation (that rotates y=-100 line), so that the direction to other things remains same, but it looks distorted.
        player.naturalDirectionSpecial=0
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
        local b=BulletSpawner{x=400,y=300,period=10,frame=0,lifeFrame=6001,bulletNumber=72,bulletSpeed=60,angle=0,bulletLifeFrame=990000,bulletSprite=BulletSprites.rice.red,bulletEvents={
            function(cir)
                local color=SpriteData[cir.sprite].color
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=30+10*(1-en.hp/en.maxhp),
                    executeFunc=function()
                        cir.sprite=BulletSprites.blackrice[color]
                        cir.speed=cir.speed-30
                        Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=0,sprite=BulletSprites.fog.red,lifeFrame=5,safe=true}
                    end
                }
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=100,
                    executeFunc=function()
                        cir.sprite=BulletSprites.rice[color]
                        cir.speed=cir.speed+30
                        Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=0,sprite=BulletSprites.fog.red,lifeFrame=5,safe=true}
                        cir.direction=cir.direction+1.7*(color=='red' and 1 or -1)
                    end
                }
            end
        }
        }
        local c=BulletSpawner{x=400,y=300,period=30,frame=0,lifeFrame=6001,bulletNumber=6,range=0.48,bulletSpeed=60,angle=0,bulletLifeFrame=990000,bulletSprite=BulletSprites.bigRound.blue,}

        Event.LoopEvent{
            obj=b,
            period=1,
            executeFunc=function()
                local t=b.frame%200
                local times=math.ceil(b.frame/200)
                local hpPercent=en.hp/en.maxhp
                if t==0 then
                    b.spawnEvent.frame=0
                    b.spawnEvent.period=10
                elseif t>=100*(1-0.6*hpPercent) then
                    b.spawnEvent.period=9999
                    b.angle=b.angle+math.eval(0,0.3)
                end
                if times%2==0 then
                    b.bulletSprite=BulletSprites.rice.red
                else
                    b.bulletSprite=BulletSprites.rice.blue
                end
                if hpPercent>0.9 then
                    c.spawnEvent.period=9999
                else
                    if not c.reset then
                        c.spawnEvent.frame=0
                        c.reset=true
                    end
                    c.spawnEvent.period=10*(1.5+0.5*hpPercent)
                    c.bulletSpeed=50*(0.95-0.4*hpPercent)
                end
                c.angle=Shape.to(c.x,c.y,player.x,player.y)+math.eval(0,0.04)
                player.orientation=-player.naturalDirectionSpecial
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
                        SFX:play("enemyPowerfulShot")
                        local delta=player.naturalDirection-player.naturalDirectionSpecial
                        delta=math.abs(delta)<math.pi/2 and math.pi/2*math.sign(delta)+delta or delta
                        Event.EaseEvent{
                            obj=player,aimTable=player,aimKey='naturalDirectionSpecial',aimValue=delta+player.naturalDirectionSpecial,easeFrame=100,progressFunc=Event.sineIOProgressFunc
                        }
                    end
                }
            end
        }

        local rotateRef=player.testRotate
        player.testRotate=function (player,angle,restore)
            if not restore then
                love.graphics.push()
                local scale=(love.graphics.getHeight()/2-Shape.axisY)/(G.viewMode.object.y-Shape.axisY)
                local theta=player.naturalDirectionSpecial
                love.graphics.translate(player.x,player.y)
                love.graphics.rotate(theta)
                love.graphics.translate(-player.x,-player.y)
            else
                love.graphics.pop()
            end
            rotateRef(player,angle-player.naturalDirectionSpecial,restore)
        end

    end,
}