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
        local function antiGetCircle(x,y,r)
            -- y=y0*cosh(r0), r=y0*sinh(r0)
            y=y-Shape.axisY
            local tanhR0=r/y
            local r0=math.atanh(tanhR0)
            local y0=y/math.cosh(r0)
            return x,y0+Shape.axisY,r0*Shape.curvature
        end
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
                    if r==100 then
                        local x0,y0,r0=antiGetCircle(b.x,b.y-r,r)
                        Circle{x=x0,y=y0,sprite=BulletSprites.giant.blue,lifeFrame=120,safe=true,highlight=true,spriteTransparency=0.5,radius=2,extraUpdate={
                            function(self)
                                self.spriteTransparency=self.spriteTransparency-0.5/120
                                self.radius=self.radius*0.98
                            end
                        }}
                    end
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