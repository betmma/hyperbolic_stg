return {
    ID=144,
    user='urumi',
    spellName='Drowning Sign "Drifting Souls"',
    make=function()
        G.UseHypRotShader=false
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
        a=BulletSpawner{x=en.x,y=en.y,period=150,frame=100,lifeFrame=10000,bulletSpeed=60,bulletNumber=10,bulletLifeFrame=1000,angle='0+999',range=math.pi*2,highlight=true,bulletSprite=BulletSprites.lightRound.purple,bulletEvents={
            function(cir,args,self)
                cir.invincible=true
                local index=args.index
                local stop=math.random()<0.3
                local round=Circle{x=cir.x,y=cir.y,sprite=BulletSprites.bigRound[stop and 'red' or 'yellow'],lifeFrame=cir.lifeFrame}
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
                Event.EaseEventBatch{
                    obj=cir,aimKeys={'radius','speed'},aimValues={roundRadius*8,stop and 0 or 10},easeFrames={stop and index*10+100 or 200,stop and index*10+100 or 100}
                }
                if stop then
                    Event.DelayEvent{
                        obj=cir,delayFrame=index*10+100,executeFunc=function()
                            Event.EaseEvent{
                                obj=cir,aimKey='radius',aimValue=0,easeFrame=100,afterFunc=function()
                                    cir:remove()
                                    round:remove()
                                end
                            }
                            local s=BulletSpawner{x=cir.x,y=cir.y,period=10,lifeFrame=100,bulletSpeed=60,bulletNumber=8,angle=math.eval(0,999),bulletSprite=BulletSprites.rice.purple}
                        end
                    }
                end
            end
        },
        }
    end
}