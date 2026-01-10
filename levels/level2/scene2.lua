return {
    ID=41,
    quote='Random jump kicks, and a powerful strike. Sometimes she almost leaves the screen.',
    user='nemuno',
    spellName='Blade Sign "Swirling Knife Sharpening"',
    make=function()
        Shape.removeDistance=10000
        local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=6000}
        local player=Player{x=400,y=600}
        local a
        a=BulletSpawner{x=400,y=100,period=2,frame=0,lifeFrame=10000,bulletNumber=1,bulletSpeed=30,bulletLifeFrame=10000,angle='0',range=math.pi*2,bulletSprite=BulletSprites.rice.yellow,highlight=true,bulletEvents={
            function(cir,args,self)
                local speedRef=cir.speed
                if not a.flag then
                    cir:changeSpriteColor('yellow')
                    cir.direction=cir.direction+math.eval(0,2)
                    cir.speed=math.eval(0.2,0.2)
                    speedRef=speedRef*math.eval(1,0.5)
                end
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function()
                        if a.flag then
                            cir.speed=speedRef
                        end
                    end
                }
            end
        }}
        a.flag=true
        Event.LoopEvent{
            obj=player,period=1,executeFunc=function(self)
                if en.removed and not G.preWin then -- enemy has moved too far and get removed. unlock secret nickname
                    EventManager.post(EventManager.EVENTS.NICKNAME_DANGEROUS_AREA)
                    self:remove()
                end
            end
        }
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local hpp=en.hp/en.maxhp
                if a.flag then
                    a.angle=a.angle+math.pi/10
                    a.bulletSpeed=a.bulletSpeed+0.5
                end
                a.spawnEvent.frame=a.spawnEvent.frame+Shape.distance(a.x,a.y,en.x,en.y)*4
                a.x,a.y=en.x,en.y
                local frame=en.frame
                if (frame+298)%300==0 then
                    local nx,ny=Shape.rThetaPos(player.x,player.y,50,math.eval(0,3.14))
                    nx=math.clamp(nx,200,600)
                    nx=math.clamp(nx,en.x-100,en.x+100)
                    ny=math.clamp(ny,100,500)
                    local yNegLimit=200
                    if en.frame>2400 then
                        yNegLimit=300
                    end
                    ny=math.clamp(ny,en.y-yNegLimit,en.y+100)
                    local co={math.eval(0,3),math.eval(0,3),math.eval(0,3),math.eval(0,3)}
                    a.flag=false
                    a.bulletSpeed=30
                    a.bulletNumber=2
                    a.spawnEvent.period=10
                    SFX:play('enemyCharge')
                    local k=1+(hpp<0.7 and 1 or 0)--+(hpp<0.4 and 1 or 0)
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='x',
                        aimValue=nx,
                        easeFrame=200,
                        progressFunc=function(x)return math.sin(x*math.pi/2)+(x*x*co[1]-x*co[2])*math.sin(x*math.pi*k) end
                    }
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='y',
                        aimValue=ny,
                        easeFrame=200,
                        progressFunc=function(x)
                            local r=math.sin(x*math.pi/2)+(x*x*co[3]-x*co[4])*math.sin(x*math.pi*k)
                            a.angle=r*(co[1]^2+co[2]^2+co[3]^2+co[4]^2)/3
                            return r end,
                        afterFunc=function()
                            SFX:play('enemyPowerfulShot',true)
                            a.flag=true
                            a.bulletSprite=BulletSprites.rice.red
                            a.spawnEvent.period=1
                            a.bulletNumber=5
                        end
                    }
                end
            end
        }
    end
}