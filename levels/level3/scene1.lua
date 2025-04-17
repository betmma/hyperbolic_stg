return {
    quote='Such surreal scene of a broader hyperbolic area...',
    user='remilia',
    spellName='Scarlet Sign "Vampirish Plaza"',
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=10000
        local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600}
        player.moveMode=player.moveModes.Euclid
        player.border:remove()
        local poses={}
        for i = 1, 12, 1 do
            local nx,ny=Shape.rThetaPos(400,300,200,math.pi/6*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local a
        a=BulletSpawner{x=400,y=150,period=80,frame=40,lifeFrame=10000,bulletNumber=35,bulletSpeed='60',bulletLifeFrame=2000,angle='1.57+0.54',range=math.pi*2,bulletSprite=BulletSprites.giant.red,highlight=true,spawnSFXVolume=1,bulletEvents={
            function(cir)
                if cir.args.index>35 then
                    cir.direction=Shape.to(a.x,a.y,player.x,player.y)+0.4*(cir.args.index%2==0 and 1 or -1)
                    cir.speed=(cir.args.index-35)*3
                    cir.sprite=BulletSprites.bigRound.red
                elseif(cir.args.index%2==0)then
                    cir.direction=Shape.to(a.x,a.y,player.x,player.y)
                    cir.speed=cir.args.index*3
                end
                Event.EaseEvent{
                    obj=cir,
                    aimTable=cir,
                    aimKey='speed',
                    aimValue=0,
                    easeFrame=300
                }
                Event.DelayEvent{
                    delayFrame=1800,
                    executeFunc=function()
                        cir.safe=true
                        cir.spriteTransparency=0.6
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='spriteTransparency',
                            aimValue=0,
                            easeFrame=200,
                        }
                    end
                }
            end
        }
        }
        Event.LoopEvent{
            period=1,
            obj=en,
            executeFunc=function()
                a.x,a.y=en.x,en.y--
                local hpp=en.hp/en.maxhp
                if hpp<0.7 then
                    a.bulletNumber=70
                    a.range=math.pi*4
                end
                if hpp<0.3 then
                    a.period=40
                end
                if en.frame%300==0 then
                    local nx,ny=Shape.rThetaPos(player.x,player.y,50,math.eval('0+3.14'))
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='x',
                        aimValue=nx,
                        easeFrame=200,
                    }
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='y',
                        aimValue=ny,
                        easeFrame=200,
                    }
                end
            end
        }
    end
}