return {
    ID=46,
    quote='?',
    user='hina',
    spellName='Misfortune Sign "Scar of Calamity"',
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=2000
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
        a=BulletSpawner{x=400,y=300,period=1,frame=0,lifeFrame=10000,bulletNumber=1,bulletSpeed=30,bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.crystal.red,bulletEvents={
            function(cir,args,self)
                local t=a.frame%60
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=240-t,
                    executeFunc=function()
                        local hpp=en.hp/en.maxhp
                        local ax,ay=Shape.rThetaPos(player.x,player.y,10*(2-hpp),t/60*math.pi*2)
                        -- cir.x,cir.y=ax,ay
                        cir.speed=Shape.distance(cir.x,cir.y,ax,ay)/2
                        cir.direction=Shape.to(cir.x,cir.y,ax,ay)
                        cir.sprite=BulletSprites.crystal.blue
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=121,
                            executeFunc=function()
                                cir.speed=0
                                cir.sprite=BulletSprites.crystal.purple
                                cir.invincible=true
                            end
                        }
                    end
                }
            end
        }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local fr=en.frame%120
                if fr==0 then
                    a.spawnEvent.period=2
                    a.spawnEvent.frame=0
                end
                if fr==60 then
                    a.spawnEvent.period=1999
                end
            end
        }
    end
}