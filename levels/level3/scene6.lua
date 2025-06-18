return {
    ID=46,
    quote='?',
    user='eika',
    spellName='Stack Sign "Crop Circle"',
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=2000
        local en=Enemy{x=400,y=-80,mainEnemy=true,maxhp=4800}
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
        local mode2=false
        local rand,rand2=math.pseudoRandom(0),math.pseudoRandom(1)
        a=BulletSpawner{x=400,y=300,period=2,frame=0,lifeFrame=10000,bulletNumber=1,bulletSpeed=30,bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.rimDark.red,bulletEvents={
            function(cir,args,self)
                local t=a.frame%60
                local et=en.frame
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=240-t,
                    executeFunc=function()
                        local hpp=en.hp/en.maxhp
                        local ax,ay
                        if mode2 then
                            ax,ay=Shape.rThetaPos(player.x,player.y,10*(1.5-hpp+rand),t/60*math.pi*2)
                        else
                            local angle=t/60*math.pi*4
                            ax,ay=Shape.rThetaPos(player.x,player.y,10*(1.5-hpp+rand)*(0.6+0.3*math.sin(angle/2+rand2)),angle)
                        end
                        -- cir.x,cir.y=ax,ay
                        cir.speed=Shape.distance(cir.x,cir.y,ax,ay)/3
                        cir.direction=Shape.to(cir.x,cir.y,ax,ay)
                        cir:changeSpriteColor('purple')
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=181,
                            executeFunc=function()
                                cir.speed=0
                                cir:changeSpriteColor('blue')
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
                if en.frame>300 then
                    Shape.moveTowards(en,{x=400,y=300},0.1,true)
                end
                if en.frame%240==0 then
                    mode2=not mode2
                    rand,rand2=math.pseudoRandom(en.frame),math.pseudoRandom(en.frame+1)
                end
            end
        }
    end
}