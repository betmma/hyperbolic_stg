return {
    quote='?',
    user='patchouli',
    spellName='Moon Wood Sign "Celestial Thread"',
    make=function()
        Shape.removeDistance=2500
        local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=6000}
        local player=Player{x=400,y=600}
        local centers={}
        local a
        a=BulletSpawner{x=400,y=100,period=300,frame=260,lifeFrame=10000,bulletNumber=4,bulletSpeed='30',bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.round.red,invincible=true,bulletEvents={
            function(cir,args,self)
                local hpp=en.hp/en.maxhp
                local t0=en.frame
                centers[t0]=centers[t0] or {}
                cir.index=#centers[t0]+1
                centers[t0][#centers[t0]+1]=cir
                cir.speed=math.eval('150+60')
                local theta=math.eval('0+999')
                cir.theta=theta
                cir.r=5
                local aim=Shape.to(cir.x,cir.y,player.x,player.y)
                cir.direction=math.modClamp(cir.direction,aim,math.pi)
                Event.EaseEvent{
                    obj=cir,
                    aimTable=cir,
                    aimKey='speed',
                    aimValue=20,
                    easeFrame=150,
                    progressFunc=Event.sineOProgressFunc,
                    afterFunc=function()
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='direction',
                            aimValue=aim,
                            easeFrame=80,
                            progressFunc=Event.sineOProgressFunc
                        }
                    end
                }
                cir.sign=math.eval('0+1')>0 and 1 or -1
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function()
                        cir.theta=cir.theta+0.3*cir.sign/cir.r
                        local num=#centers[t0]
                        for i = cir.index, num, 1 do
                            local center=centers[t0][i]
                            if center.removed or center==cir then
                                goto continue
                            end
                            local count=0
                            local d=Shape.distance(cir.x,cir.y,center.x,center.y)
                            d=d-(d%6)*2
                            for r=d,0,-6 do
                                count=count+1
                                local angle=Shape.to(cir.x,cir.y,center.x,center.y)
                                local x,y=Shape.rThetaPos(cir.x,cir.y,r,angle)
                                local sprite=BulletSprites.dot.red
                                if (hpp<0.7 and count%2==0) or (hpp<0.5) then
                                    sprite=BulletSprites.round.gray
                                end
                                Circle{x=x,y=y,direction=angle,speed=0,sprite=sprite,lifeFrame=0}
                            end
                            ::continue::
                        end
                    end
                }
            end
        }}
    end
}