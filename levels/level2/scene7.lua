return {
    quote='??',
    user='yukari',
    spellName='Barrier "Boundary of Monad and Dyad"', -- this spell card should be remade later to add more interesting patterns. like laser
    make=function()
        Shape.removeDistance=2000
        local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600}
        local a
        local r1=30
        local r2=50
        a=BulletSpawner{x=400,y=100,period=300,frame=20,lifeFrame=10000,bulletNumber=1,bulletSpeed='30',bulletLifeFrame=10000,angle='0+0.01',range=math.pi*2,bulletSprite=BulletSprites.knife.red,bulletEvents={
            function(cir,args,self)
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    times=1,
                    conditionFunc=function()
                        return Shape.distance(cir.x,cir.y,en.x,en.y)>r1
                    end,
                    executeFunc=function()
                        local angle=Shape.to(en.x,en.y,cir.x,cir.y)
                        cir.x,cir.y=Shape.rThetaPos(player.x,player.y,r2,angle)
                        cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)+cir.direction-angle
                        cir.sprite=BulletSprites.knife.blue
                    end
                }
            end
        }}
        local mode=0
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                a.x,a.y=en.x,en.y
                local frame=en.frame
                r1=40+25*math.sin(frame/120)
                r2=40-20*math.sin(frame/120)
                if (frame+240)%300==0 then
                    local nx,ny=Shape.rThetaPos(player.x,player.y,50,math.eval('0+3.14'))
                    nx=math.clamp(nx,200,600)
                    nx=math.clamp(nx,en.x-100,en.x+100)
                    ny=math.clamp(ny,0,550)
                    ny=math.clamp(ny,en.y-100,en.y+100)
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
                if frame%150==0 then
                    mode=math.random(1,3)
                    if mode==1 then
                        a.bulletSpeed=20
                        a.bulletNumber=3
                        a.spawnEvent.period=3
                        a.spawnEvent.frame=0
                        a.angle=math.eval('0+999.01')
                    elseif mode==2 then
                        a.bulletSpeed=30
                        a.bulletNumber=15
                        a.spawnEvent.period=100
                        a.spawnEvent.frame=75
                        a.angle=math.eval('0+999')
                    elseif mode==3 then
                        a.bulletSpeed=40
                        a.bulletNumber=1
                        a.spawnEvent.period=1
                        a.spawnEvent.frame=0
                        a.angle=math.eval('0+999')
                        a.angleRef=a.angle
                    end
                end
                if mode==1 then
                    a.angle=a.angle+0.01
                    if frame%150==70 then
                        a.spawnEvent.period=999
                    end
                elseif mode==2 then
                    a.angle=math.eval('0+999')
                elseif mode==3 then
                    a.angle=math.eval('0+0.5')+a.angleRef
                end
            end
        }
        Event.DelayEvent{
            obj=en,
            period=30,
            executeFunc=function()
                SFX:play('enemyPowerfulShot',true)
                local drawRef=a.draw
                a.draw=function(self)
                    local colorref={love.graphics.getColor()}
                    love.graphics.setColor(1,0,0,0.5)
                    Shape.drawCircle(en.x,en.y,r1,'fill')
                    love.graphics.setColor(0,0,1,0.5)
                    Shape.drawCircle(player.x,player.y,r2,'fill')
                    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4] or 1)
                    drawRef(self)
                end
            end
        }
    end
}