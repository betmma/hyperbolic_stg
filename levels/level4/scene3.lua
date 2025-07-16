return {
    ID=92,
    user='urumi',
    spellName='Stone Sign "Rotating Stone"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=2500
        local en,a
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
        -- en:addHPProtection(300,10)
        local player=Player{x=400,y=600,noBorder=true}
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        player.moveMode=Player.moveModes.Natural
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        a=BulletSpawner{x=en.x,y=en.y,period=150,frame=100,lifeFrame=10000,bulletSpeed=10,bulletNumber=10,bulletLifeFrame=1000,angle='0+999',range=math.pi*2,highlight=true,bulletSprite=BulletSprites.lightRound.purple,bulletEvents={
            function(cir,args,self)
                cir.invincible=true -- prevent vortex removing all bullets. set to false at 120 frames
                cir.forceDrawLargeSprite=true
                local times=a.spawnEvent.executedTimes
                local sign=math.mod2Sign(times)
                local round=Circle{x=cir.x,y=cir.y,sprite=BulletSprites.bigRound.yellow,lifeFrame=cir.lifeFrame}
                round.forceDrawLargeSprite=true
                local roundRadius=round.radius
                local radiusRef=cir.radius
                round.invincible=true
                Event.LoopEvent{
                    obj=round,period=1,conditionFunc=function(self)
                        if cir.removed then
                            round:remove()
                            return false
                        end
                        return true
                    end,
                    executeFunc=function(self)
                        round.x=cir.x
                        round.y=cir.y
                        round.radius=cir.radius/radiusRef*roundRadius
                    end
                }
                local afterHypRotX0,afterHypRotY0=Shape.rotateAround(cir.x,cir.y,-player.naturalDirection,player.x,player.y)
                local metricRef=(afterHypRotY0-Shape.axisY)/Shape.curvature
                local angle=cir.direction
                local r=math.pseudoRandom(times)*20+80
                Event.LoopEvent{
                    obj=cir,period=1,times=360,executeFunc=function(self,times,maxTimes)
                        if times==120 then
                            cir.invincible=false
                        end
                        local ratio=math.sin(times/maxTimes*math.pi-math.pi/2)/2+0.5
                        cir.x,cir.y=Shape.rThetaPos(en.x,en.y,(1-(1-ratio)^3)*r,angle+math.pi*ratio*sign)
                        round.x=cir.x
                        round.y=cir.y
                        if times<180 then
                            local afterHypRotX,afterHypRotY=Shape.rotateAround(cir.x,cir.y,-player.naturalDirection,player.x,player.y)
                            cir.radius=radiusRef*metricRef/(afterHypRotY-Shape.axisY)*Shape.curvature
                        end
                        if times==maxTimes-1 then
                            cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)
                            Event.EaseEvent{
                                obj=cir,aimKey='speed',aimValue=40,easeFrame=60
                            }
                        end
                    end
                }
            end
        },
        }
    end
}