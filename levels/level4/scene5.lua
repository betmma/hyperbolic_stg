return {
    quote='?',
    user='shou',
    spellName='Tiger Sign "Famished Tiger"',
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=10000000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
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
        G.viewMode.object=player
        local borderCenter=Shape{x=400,y=300,lifeFrame=99999999}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local fr=en.frame%200
                if fr==50 then
                    SFX:play('enemyCharge',true)
                    if not player.border:inside(en.x,en.y) then
                        local dir=Shape.to(borderCenter.x,borderCenter.y,en.x,en.y)
                        local nx,ny=Shape.rThetaPos(borderCenter.x,borderCenter.y,90,dir)
                        Event.EaseEvent{
                            obj=en,
                            aimTable=en,
                            aimKey='x',
                            aimValue=nx,
                            easeFrame=50
                        }
                        Event.EaseEvent{
                            obj=en,
                            aimTable=en,
                            aimKey='y',
                            aimValue=ny,
                            easeFrame=50
                        }
                    end
                end
                if fr==100 then --dash towards player
                    local angle=Shape.to(en.x,en.y,player.x,player.y)
                    en.direction=angle
                    local e1
                    e1=Event.LoopEvent{
                        obj=en,
                        period=1,
                        times=300,
                        conditionFunc=function()
                            local inRange=player.border:inside(en.x,en.y)
                            if not inRange then
                                local speedRef=en.speed*1.1
                                local direction=Shape.to(borderCenter.x,borderCenter.y,en.x,en.y)
                                e1:remove()
                                en.speed=0
                                local e2
                                e2=Event.LoopEvent{
                                    obj=en,
                                    period=1,
                                    times=100,
                                    executeFunc=function()-- change border as been crashed into
                                        local times=e2.executedTimes
                                        borderCenter.direction=direction
                                        borderCenter.speed=speedRef*(1-times/99)
                                        for i = 1, 12, 1 do
                                            player.border.points[i].x,player.border.points[i].y=Shape.rThetaPos(borderCenter.x,borderCenter.y,100,math.pi/6*(i-.5))
                                        end
                                    end
                                }
                                SFX:play('enemyPowerfulShot',true)
                                local hpp=en.hp/en.maxhp
                                local num=hpp<0.4 and 150 or 90
                                BulletSpawner{x=en.x,y=en.y,period=1,frame=0,lifeFrame=2,bulletNumber=num,bulletSpeed=70,bulletLifeFrame=500,angle=angle,bulletSprite=BulletSprites.scale.yellow,highlight=true,bulletEvents={
                                    function(cir,args,self)
                                        cir.x=cir.x*math.eval(1,0.04)
                                        cir.y=cir.y*math.eval(1,0.04)
                                        local rand=math.eval(0,1)
                                        local dang=rand^3*math.pi*(hpp<0.4 and 4 or 2)
                                        cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)+dang
                                        cir.speed=40+math.cos(rand*3)*30+math.eval(0,8)
                                        if math.abs(dang)>math.pi*2 then
                                            cir.sprite=BulletSprites.scale.blue
                                            cir.speed=cir.speed+70
                                        end
                                    end
                                }
                                }
                                if hpp<0.7 then
                                    BulletSpawner{x=en.x,y=en.y,period=1,frame=0,lifeFrame=1,bulletNumber=90,bulletSpeed=70,bulletLifeFrame=500,angle=angle,bulletSprite=BulletSprites.scale.red,highlight=true,bulletEvents={
                                        function(cir,args,self)
                                            local index=args.index
                                            cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)+(0.3*index/90+0.1*math.sin(index/3))*(index%2*2-1)
                                            cir.speed=20+index
                                        end
                                    }
                                    }
                                end
                            end
                            return inRange
                        end,
                        executeFunc=function()
                            local dr=e1.executedTimes
                            en.speed=150*(1-dr/299)*math.min(1,dr*0.1)
                        end
                    }
                    en.e1=e1
                end
            end
        }

    end
}