BulletSpawner=require"bulletSpawner"

local levelData={
    {
        {
            quote="In this world things appear smaller when closer to top.",
            make=function ()
                local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=4800}
                local player=Player(400,600)
                local a=BulletSpawner{x=200,y=0,period=12,frame=0,lifeFrame=10000,bulletNumber=10,bulletSpeed='40',angle='0+112',bulletSprite=BulletSprites.round.blue,bulletEvents={
                }}
                local a=BulletSpawner{x=600,y=0,period=12,frame=0,lifeFrame=10000,bulletNumber=10,bulletSpeed='40',angle='0+112',bulletSprite=BulletSprites.round.blue,bulletEvents={
                }}
                local b=BulletSpawner{x=400,y=600,period=120,frame=60,lifeFrame=10000,bulletNumber=60,bulletSpeed=1.5,bulletSprite=BulletSprites.star.red,bulletEvents={
                    function(cir,args)
                        local key=args.index
                        Event.LoopEvent{
                            obj=cir,
                            times=1,
                            period=30,
                            conditionFunc=function()return true end,
                            executeFunc=function(self)
                                Event.EaseEvent{
                                    obj=cir,
                                    easeFrame=60,
                                    aimTable=cir,
                                    aimKey='speed',
                                    aimValue=0,
                                    endFunc=function(self)
                                        cir.direction=-math.pi/2
                                        cir.speed=20
                                    end
                                }
                        end}
                    end
                },
                spawnBatchFunc=function(self)
                    self.x=math.eval('400+10')
                    local num=math.eval(self.bulletNumber)
                    local angle=math.eval(self.angle)
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    for i = 1, num, 1 do
                        self:spawnBulletFunc{direction=i<=num/2 and 0 or math.pi,speed=math.abs(speed*(i-num/2)),radius=size,index=i}
                    end
                end}
            end
        },
        {
            quote="Hyperbolic center of circle is above the Euclidean center.",
            make=function ()
                local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=4800}
                local player=Player(400,600)
                a=BulletSpawner{x=400,y=600,period=300,frame=180,lifeFrame=10000,bulletNumber=1,bulletSpeed=0,bulletSprite=BulletSprites.blackheart.blue,bulletEvents={
                    function(cir,args)
                        local key=args.index
                        Event{
                            obj=cir,
                            times=1,
                            conditionFunc=function(self)return b.flag end,
                            executeFunc=function(self)
                                cir.direction=cir.direction+math.eval('0+999')
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
        },
        {
            quote='The two upper corners seem narrow, but actually good places to induce these bullets.',
            make=function()
                local en=Enemy{x=400,y=200,mainEnemy=true,maxhp=4800}
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        en.x=en.x-(en.x-Player.objects[1].x)*0.01
                    end
                }
                local player=Player(400,600)
                local b=BulletSpawner{x=400,y=200,period=600,frame=540,lifeFrame=10000,bulletNumber=120,bulletSpeed=30,angle='0+9999',bulletSprite=BulletSprites.bill.red,bulletEvents={
                    function(cir,args)
                        local key=args.index
                        Event.LoopEvent{
                            obj=cir,
                            times=5,
                            period=1,
                            conditionFunc=function()return
                                not Player.objects[1].border:inside(cir.x,cir.y)
                            end,
                            executeFunc=function(self)
                                cir.speed=20
                                cir.sprite=BulletSprites.bill.blue
                                cir.direction=Shape.to(cir.x,cir.y,Player.objects[1].x,Player.objects[1].y)
                                -- Event.EaseEvent{
                                --     obj=cir,
                                --     easeFrame=60,
                                --     aimTable=cir,
                                --     aimKey='direction',
                                --     aimValue=cir.direction+1,
                                --     endFunc=function(self)
                                --         cir.direction=math.pi+cir.direction
                                --         cir.speed=20
                                --     end
                                -- }
                        end}
                    end
                },
                spawnBatchFunc=function(self)
                    local num=math.eval(self.bulletNumber)
                    local range=math.eval(self.range)
                    local angle=math.eval(self.angle)
                    self.angle2=(self.angle2 or math.eval(self.angle))+math.pi/12
                    local angle2=self.angle2 or 0
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    local sideNum=3
                    for i = 1, num, 1 do
                        local direction=range*(i-0.5-num/2)/num+angle
                        local sped=speed/math.cos((direction-angle2)%(math.pi/(sideNum/2))-math.pi/sideNum)^(1)
                        self:spawnBulletFunc{direction=direction,speed=sped,radius=size,index=i}
                    end
                    -- angle2=angle2+math.pi
                    -- for i = 1, num, 1 do
                    --     local direction=range*(i-0.5-num/2)/num+angle
                    --     local sped=speed/math.cos((direction-angle2)%(math.pi/(sideNum/2))-math.pi/sideNum)^(1)
                    --     self:spawnBulletFunc{direction=direction,speed=sped,radius=size,index=i}
                    -- end
                end
                }
                Event.LoopEvent{
                    obj=b,
                    period=600,
                    frame=60,
                    executeFunc=function()
                        Effect.Charge{obj=b,x=b.x,y=b.y}
                    end
                }
                Event.LoopEvent{
                    obj=b,
                    period=1,
                    executeFunc=function()
                        b.x=en.x
                        b.y=en.y
                    end
                }
            end
        },
        {
            quote='Moving through this "square" grid is so difficult.',
            make=function()
                local en=Enemy{x=400,y=200,mainEnemy=true,maxhp=4800,speed=10}
                local a=BulletSpawner{x=400,y=300,period=300,frame=240,lifeFrame=10000,bulletNumber=100,bulletSpeed=10,angle='0+9999',bulletSprite=BulletSprites.crystal.red,fogEffect=true,bulletEvents={
                    function(cir,args)
                        local spd=cir.speed
                        cir.speed=0
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=spd,
                            easeFrame=60
                        }
                    end
                },
                spawnBatchFunc=function(self)
                    local num=math.eval(self.bulletNumber)
                    local range=math.eval(self.range)
                    local angle=math.eval(self.angle)
                    local angle2=Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y)
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    local sideNum=3
                    -- local nx,ny
                    for i = 1, num, 1 do
                        local direction=range*(i-0.5-num/2)/num+angle
                        local radi=i/num*100
                        local angle3=angle2
                        -- nx,ny=self.x+radi*math.cos(angle2),self.y+radi*math.sin(angle2)
                        Event.DelayEvent{
                            obj=self,
                            delayFrame=i/3,
                            executeFunc=function(self)
                                local x,y=Shape.rThetaPos(self.obj.x,self.obj.y,radi,angle3)
                                self.obj:spawnBulletFunc{x=x,y=y,direction=direction*2,speed=speed,radius=size,index=i}
                            end
                        }
                    end
                    for i = 1, 30, 1 do
                        local direction=range*(i-0.5-num/2)/num+angle
                        local radi=30
                        local angle3=angle2+i/30*math.pi*2
                        -- nx,ny=self.x+radi*math.cos(angle2),self.y+radi*math.sin(angle2)
                        Event.DelayEvent{
                            obj=self,
                            delayFrame=i/3,
                            executeFunc=function(self)
                                self.obj:spawnBulletFuncRef{x=self.obj.x+radi*math.cos(angle3),y=self.obj.y+radi*math.sin(angle3),direction=direction*2,speed=speed,radius=size,index=i}
                            end
                        }
                    end
                end
                }
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        en.direction=Shape.to(en.x,en.y,Player.objects[1].x,Player.objects[1].y)
                        a.x=en.x;a.y=en.y
                        a.bulletNumber=50+math.floor(50-50*en.hp/en.maxhp)
                    end
                }
                local player=Player(400,600)
                local b=BulletSpawner{x=400,y=300,period=6000,frame=5940,lifeFrame=990000,bulletNumber=10,bulletSpeed=10,angle='0+9999',bulletLifeFrame=990000 ,bulletSprite=BulletSprites.rim.yellow,fogEffect=true,bulletEvents={
                    function(cir,args)
                        local spd=cir.speed
                        cir.speed=0
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=spd,
                            easeFrame=60
                        }
                    end
                },
                spawnBatchFunc=function(self)
                    local num=math.eval(self.bulletNumber)
                    local range=math.eval(self.range)
                    local angle=math.eval(self.angle)
                    local angle2=self.angle2 or math.pi/-6
                    self.angle2=(self.angle2 or 0)+math.pi/6
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    local sideNum=3
                    -- local nx,ny
                    for x0=200,600,40 do
                        for y0=40,600,40 do
                            self:spawnBulletFunc{x=x0,y=y0,direction=0,speed=0,radius=size/(y0-Shape.axisY)*500,invincible=true}
                        end
                    end
                end
                }
            end
        },
        {
            quote='this pattern is cool.',
            make=function()
                -- local en=Enemy{x=400,y=200,mainEnemy=true,maxhp=4800}
                -- Event.LoopEvent{
                --     obj=en,
                --     period=1,
                --     executeFunc=function()
                --         en.x=en.x-(en.x-Player.objects[1].x)*0.01
                --     end
                -- }
                local player=Player(400,600)
                local b=BulletSpawner{x=400,y=300,period=600,frame=540,lifeFrame=10000,bulletNumber=960,bulletSpeed=10,angle='0+9999',bulletSprite=BulletSprites.darkdot.yellow,fogEffect=true,bulletEvents={
                    function(cir,args)
                        local spd=cir.speed
                        cir.speed=0
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=spd,
                            easeFrame=60
                        }
                    end
                },
                spawnBatchFunc=function(self)
                    local num=math.eval(self.bulletNumber)
                    local range=math.eval(self.range)
                    local angle=math.eval(self.angle)
                    local angle2=self.angle2 or math.pi/-6
                    self.angle2=(self.angle2 or 0)+math.pi/6
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    local sideNum=3
                    -- local nx,ny
                    for i = 1, num, 1 do
                        local direction=range*(i-0.5-num/2)/num+angle
                        local radi=math.sin(i/num*math.pi)*100
                        local angle3=angle2+i*math.pi/119*41
                        -- nx,ny=self.x+radi*math.cos(angle2),self.y+radi*math.sin(angle2)
                        Event.DelayEvent{
                            obj=self,
                            delayFrame=i/3,
                            executeFunc=function(self)
                                self.obj:spawnBulletFunc{x=self.obj.x+radi*math.cos(angle3),y=self.obj.y+radi*math.sin(angle3),direction=direction*2+angle3,speed=speed,radius=size,index=i}
                            end
                        }
                    end
                end
                }
            end
        },
    }
}
levelData.defaultQuote='What will happen here?'
return levelData