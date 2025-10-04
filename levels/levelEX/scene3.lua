return {
    ID=47,
    quote='?',
    user='alice',
    spellName='Magic Sign "Explosive Marionette"',
    make=function()
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
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local a
        a=BulletSpawner{x=400,y=300,period=900,frame=840,lifeFrame=300000,bulletNumber=18,bulletSpeed=45,bulletLifeFrame=300,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.giant.red,bulletEvents={
            function(cir,args,self)
                cir:changeSpriteColor()
                local index=args.index
                local m0=index%3
                local t=(m0*50)+50
                Event.EaseEvent{
                    obj=cir,aimTable=cir,aimKey='speed',aimValue=0,easeFrame=t,progressFunc=function(x)return math.max(0,2*x-1)end
                }
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=t,
                    executeFunc=function()
                        cir:remove()
                        BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=10,bulletSpeed=40,bulletLifeFrame=150+index*2,angle=math.eval(0,999),bulletSprite=BulletSprites.bigRound.yellow,highlight=true,bulletEvents={
                            function(cir,args,self)
                                cir:changeSpriteColor()
                                local index2=args.index
                                local t2=60+index2*5+index*2
                                Event.EaseEvent{
                                    obj=cir,aimTable=cir,aimKey='speed',aimValue=0,easeFrame=index2%2==1 and 60 or 30
                                }
                                Event.DelayEvent{
                                    obj=cir,
                                    delayFrame=t2,
                                    executeFunc=function()
                                        cir:remove()
                                        local angle=m0~=0 and '0+999' or Shape.to(cir.x,cir.y,player.x,player.y)+math.pi/10*3+math.eval(0,0.1)--
                                        BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=10,bulletSpeed=index%4>=2 and 16 or 12,bulletLifeFrame=1800,angle=angle,bulletSprite=BulletSprites.scale.yellow,highlight=true,bulletEvents={
                                            function(cir,args,self)
                                                cir:changeSpriteColor()
                                                if m0==0 then
                                                    cir.speed=cir.speed*4
                                                end
                                                if args.index%2==1 then
                                                    cir.speed=cir.speed/2
                                                end
                                            end
                                        }
                                        }
                                    end
                                }
                            end
                        }
                        }
                    end
                }
            end
        }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local hpp=en.hp/en.maxhp
                a.spawnEvent.period=450*(1+hpp)
            end
        }
    end
}