return {
    ID=12,
    quote="Hyperbolic center of circle is above the Euclidean center.",
    user='doremy',
    spellName='Moon Sign "Cerulean Lunatic Dream"',
    make=function ()
        local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=4800}
        local player=Player{x=400,y=600}
        local b
        local a=BulletSpawner{x=400,y=600,period=300,frame=180,lifeFrame=10000,bulletNumber=1,bulletSpeed=0,bulletSprite=BulletSprites.blackrice.blue,bulletEvents={
            function(cir,args)
                local t0=en.frame
                Event{
                    obj=cir,
                    times=1,
                    conditionFunc=function(self)return b.flag end,
                    executeFunc=function(self)
                        if t0%3~=0 then
                            Event.EaseEvent{
                                obj=cir,aimKey='spriteTransparency',aimValue=0,easeFrame=math.eval(30,10),afterFunc=function()
                                    cir:remove()
                                end
                            }
                        end
                        cir.direction=cir.direction+math.eval(0,999)
                        Event.EaseEvent{
                            obj=cir,
                            easeFrame=60,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=5
                        }
                end}
            end
        },
        }
        local tb={x=400,y=600,period=300,frame=180,lifeFrame=10000,bulletNumber=1,bulletSpeed=0,bulletSprite=BulletSprites.rice.red,bulletEvents={
            function(cir,args)
                local key=args.index
                Event{
                    obj=cir,
                    times=1,
                    conditionFunc=function(self)return b.flag end,
                    executeFunc=function(self)
                        cir.direction=cir.direction+math.pi/24
                        Event.EaseEvent{
                            obj=cir,
                            easeFrame=60,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=30
                        }
                end}
            end
        },}
        b=BulletSpawner(tb)
        -- c=BulletSpawner(tb)
        local function spin(b,r,angle)
            Event.LoopEvent{
                obj=b,
                frame=240,
                period=300,
                conditionFunc=function()return true end,
                executeFunc=function(self)
                    local r=r
                    b.flag=false
                    b.spawnEvent.period=0.005
                    b.spawnEvent.frame=0
                    b.angle=angle-math.pi/2
                    b.x=Player.objects[1].x
                    b.y=math.clamp(Player.objects[1].y,100,560)+r
                    Event.EaseEvent{
                        obj=b,
                        easeFrame=60,
                        aimTable=b,
                        aimKey='x',
                        aimValue=b.x+r,
                        progressFunc=function(x)
                            return math.sin(x*math.pi*2)
                        end
                    }
                    Event.EaseEvent{
                        obj=b,
                        easeFrame=60,
                        aimTable=b,
                        aimKey='y',
                        aimValue=b.y+r,
                        progressFunc=function(x)
                            return math.cos(x*math.pi*2)
                        end
                    }
                    Event.EaseEvent{
                        obj=b,
                        easeFrame=60,
                        aimTable=b,
                        aimKey='angle',
                        aimValue=b.angle-math.pi*2,
                    }
                    Event.LoopEvent{
                        obj=b,
                        times=1,
                        period=60,
                        executeFunc=function(x)
                            b.spawnEvent.period=990.05
                            b.flag=true
                        end
                    }
                end
            }
        end
        spin(a,50,math.pi)
        spin(b,100,0)
        -- spin(c,150,0)
    end
}