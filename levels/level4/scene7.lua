return {
    ID=86,
    user='chimi',
    spellName='Bewitching Sign "Qi of an Impenetrable Thicket"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1000
        local a,b
        local en
        en=Enemy{x=400,y=100,mainEnemy=true,maxhp=7200}
        -- en:addHPProtection(600,10)
        local player=Player{x=400,y=600,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local gen
        gen=function(cir)
            if cir.frame%5==0 then
                local f=cir.frame%10==0
                local timeM=(cir.times or 0)%2
                local c=Circle{x=cir.x,y=cir.y,lifeFrame=500,direction=cir.direction,sprite=BulletSprites.crystal[timeM==1 and 'green' or 'teal'],speed=0}
                if f then
                    c.direction=c.direction+math.eval(0,0.1)
                    Event.EaseEvent{
                        obj=c,
                        easeFrame=180,
                        aimTable=c,
                        aimKey='speed',
                        aimValue=30,
                        progressFunc=Event.sineOProgressFunc
                    }
                end
            end
            if cir.frame%20==10 and (not cir.times or cir.times<2) then
                SFX:play('enemyShot',true,0.7)
                cir.times=(cir.times or 0)+1
                local new=Circle{x=cir.x,y=cir.y,lifeFrame=cir.lifeFrame-cir.frame,direction=cir.direction+cir.d*(cir.times),sprite=BulletSprites.crystal.white,speed=cir.speed}
                new.times=cir.times
                new.d=cir.d
                cir.direction=cir.direction-cir.d*(cir.times)
                new.extraUpdate[1]=gen
            end
        end
        a=BulletSpawner{x=400,y=300,period=600,frame=540,lifeFrame=10000,spawnCircleRadius=110,bulletNumber=12,bulletSpeed=50,bulletLifeFrame=160,angle=math.pi,range=math.pi*2,spawnSFXVolume=1,bulletSprite=BulletSprites.crystal.white,bulletEvents={
            function(cir,args,self)
                cir.d=math.eval(0.3,0.1)
                cir.extraUpdate[1]=gen
            end
        }}
        b=BulletSpawner{x=400,y=100,period=600000,frame=0,lifeFrame=10000,bulletNumber=2,bulletSpeed=40,bulletLifeFrame=1000,angle='player',range=math.pi*0.1,bulletSprite=BulletSprites.giant.green,highlight=true,bulletEvents={
        }}
        Event.LoopEvent{
            period=600,frame=0,
            executeFunc=function()
                SFX:play('enemyCharge')
            end
        }
        Event.LoopEvent{
            period=600,frame=350,
            executeFunc=function()
                SFX:play('enemyCharge')
                local pos={x=player.x,y=player.y}
                Event.LoopEvent{
                    period=1,times=100,
                    executeFunc=function(self,times)
                        Shape.moveTowards(en,pos,1,true)
                        b.x,b.y=en.x,en.y
                        if times%2==0 then
                            b.range=math.pi*times/150
                            b:spawnBatchFunc()
                        end
                    end
                }
            end
        }
    end
}