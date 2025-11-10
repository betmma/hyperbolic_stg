return {
    ID=16,
    quote='not come up yet',
    user='yuugi',
    spellName='Manacles Sign "Manacles a Criminal Can\'t Take Off"',
    make=function()
        Shape.removeDistance=2500
        local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600,noBorder=true}
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        player.moveMode=Player.moveModes.Natural
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local a=BulletSpawner{x=400,y=150,period=300,frame=240,lifeFrame=10000,bulletNumber=10,bulletSpeed='90',bulletLifeFrame=100,range=math.pi*2,angle='1.17+3.14',bulletSprite=BulletSprites.laser.blue,bulletEvents={
            function(cir)
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function()
                        local t=cir.frame%120
                        if t<30 then
                            cir.direction=cir.direction+0.12
                        elseif t>=60 and t<90 then
                            cir.direction=cir.direction-0.12
                        end
                        if Shape.distanceObj(cir,center)>120 then
                            cir:remove()
                        end
                    end
                }
            end
        }}
        local b
        b=BulletSpawner{x=400,y=150,period=300,frame=240,lifeFrame=10000,bulletNumber=25,bulletSpeed='80',bulletLifeFrame=200,warningFrame=60,fadingFrame=20,angle='1.57+0.54',range=math.pi*2,bulletSprite=BulletSprites.laser.red,frequency=4,highlight=true,bulletEvents={
            function(cir)
                Event.EaseEvent{
                    obj=cir,aimKey='speed',aimValue=480,easeFrame=10
                }
                cir.lifeFrame=30
            end},laserEvents={
            function(laser)
                local enDirRef=en.direction
                Event.LoopEvent{
                    obj=laser,
                    period=1,
                    executeFunc=function(self)
                        laser.args.direction=laser.args.direction+en.direction-enDirRef+(a.spawnEvent.executedTimes%2==1 and 1 or -1)*0.0005*(2-en.hp/en.maxhp)
                        enDirRef=en.direction
                        laser.x,laser.y=en.x,en.y
                    end
                }
            end
        }}
        Event.LoopEvent{
            obj=en,period=300,frame=200,executeFunc=function(self,dt)
                local dir=Shape.to(en.x,en.y,player.x,player.y)+math.eval(0,0.4)
                local distance=Shape.distance(en.x,en.y,player.x,player.y)
                Event.LoopEvent{
                    obj=en,period=1,times=200,executeFunc=function(self,times,maxTimes)
                        Shape.moveTowards(en,dir,distance/maxTimes*math.sin(times/maxTimes*math.pi))
                        a.x,a.y=en.x,en.y
                        b.x,b.y=en.x,en.y
                        if times==maxTimes-1 then
                            local newAngle=Shape.to(en.x,en.y,player.x,player.y)
                            a.angle=newAngle+math.eval(0,0.4)
                            b.angle=newAngle+math.eval(0,0.54)
                        end
                    end
                }
            end
        }
    end
}