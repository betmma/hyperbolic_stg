return {
    quote='?',
    user='aya',
    spellName='Wind God "Frenzied Wind"', 
    make=function()
        G.backgroundPattern:remove()
        G.backgroundPattern=BackgroundPattern.FixedTesselation{toDrawNum=5}
        G.levelRemainingFrame=7200
        Shape.removeDistance=10000000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=10800,hpSegments={0.7,0.4}}
        local player=Player{x=400,y=500}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local poses={}
        for i = 1, 12, 1 do
            local nx,ny=Shape.rThetaPos(400,300,100,math.pi/6*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        local dummy=Shape{x=400,y=400,lifeFrame=99999999}
        G.viewMode.object=player
        local alpha=0
        local angle=0
        local a
        a=BulletSpawner{x=400,y=300,period=5,frame=-50,lifeFrame=10000,bulletNumber=10,bulletSpeed=60,bulletLifeFrame=400,angle=math.eval(0,999),range=math.pi*2,bulletSprite=BulletSprites.scale.blue,bulletEvents={
            function(cir,args,self)
                local dir0=cir.direction
                local speed=cir.speed
                local frame=cir.frame
                local flag=args.index%2==1
                local inc=cir.sprite==BulletSprites.scale.red and 1 or 0
                local delta=0
                local x0,y0=cir.x,cir.y
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function()
                        -- Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=0,sprite=BulletSprites.scale.blue,safe=true,lifeFrame=3,spriteTransparency=0.4}
                        local r=speed*(cir.frame-frame)/60
                        cir.x,cir.y=Shape.rThetaPos(x0,y0,r,dir0+delta)
                        cir.direction=dir0+delta
                        delta=delta+inc*cir.frame/r/960*(flag and 1 or -1)
                    end
                }
            end

        }
        }

        local borderCenter=Shape{x=400,y=300,lifeFrame=99999999}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                a.angle=a.angle+0.008*math.sign(math.sin((en.frame-50)/800*math.pi))
                a.x,a.y=en.x,en.y
                local hpp=en.hp/en.maxhp
                if en.frame%90==0 and hpp<0.7 then
                    if hpp<0.4 then
                        a.bulletSprite=BulletSprites.scale.red
                        a.bulletNumber=60
                    else
                        a.bulletSprite=BulletSprites.scale.yellow
                        a.bulletNumber=30
                    end
                    a.bulletSpeed=40
                    a:spawnBatchFunc()
                    a.bulletNumber=10
                    a.bulletSpeed=60
                    a.bulletSprite=BulletSprites.scale.blue
                -- elseif hpp>0.4 then
                -- else
                --     a.bulletSprite=BulletSprites.scale.yellow
                end
                local fr=en.frame%800
                local times=math.floor(en.frame/800)
                if fr==50 then
                    SFX:play('enemyCharge',true)
                end
                if fr==100 then 
                    SFX:play('enemyPowerfulShot',true)
                    angle=0.3*(times%2==0 and 1 or -1)+math.pi/2
                    local speed=50
                    en.direction=angle
                    borderCenter.direction=angle
                    local e2
                    local alpha1=alpha
                    e2=Event.LoopEvent{
                        obj=en,
                        period=1,
                        times=600,
                        executeFunc=function()-- change border as been crashed into
                            local times=e2.executedTimes
                            local ratio=times/(e2.times-1)
                            borderCenter.speed=speed*math.sin(ratio*math.pi)
                            en.speed=speed*math.sin(ratio*math.pi)
                            for i = 1, 12, 1 do
                                player.border.points[i].x,player.border.points[i].y=Shape.rThetaPos(borderCenter.x,borderCenter.y,100,math.pi/6*(i-.5)+en.direction-angle+alpha1)
                            end
                            if times==599 then
                                alpha=alpha+en.direction-angle
                            end
                                
                        end
                    }
                end

                for i=1,5 do
                    local side=G.backgroundPattern.sidesTable[i]
                    side[1].x,side[1].y=en.x,en.y
                    side[2].x,side[2].y=Shape.rThetaPos(en.x,en.y,G.backgroundPattern.sideLength,math.pi/5*2*(i-1))
                end
            end
        }

    end
}