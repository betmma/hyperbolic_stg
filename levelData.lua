BulletSpawner=require"bulletSpawner"

local levelData={
    {
        {
            quote="In this world things appear smaller when closer to top.",
            user='marisa',
            spellName='Magic Sign "Otherworld Star Dust"',
            make=function ()
                local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=4800}
                local player=Player(400,600)
                local a=BulletSpawner{x=150,y=0,period=12,frame=0,lifeFrame=10000,bulletNumber=10,bulletSpeed='40',angle='0+112',bulletSprite=BulletSprites.round.blue,bulletEvents={
                }}
                local a=BulletSpawner{x=650,y=0,period=12,frame=0,lifeFrame=10000,bulletNumber=10,bulletSpeed='40',angle='0+112',bulletSprite=BulletSprites.round.blue,bulletEvents={
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
            user='doremy',
            spellName='Moon Sign "Cerulean Lunatic Dream"',
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
            quote='I wonder where is the best place to induce these bullets.',
            user='reimu',
            spellName='Spirit Sign "Fantasy Seal -Focus-"',
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
            user='sakuya',
            spellName='Illusion Trap "Killing Grid"',
            make=function()
                local en=Enemy{x=400,y=200,mainEnemy=true,maxhp=4800,speed=5}
                local a=BulletSpawner{x=400,y=300,period=300,frame=180,lifeFrame=10000,bulletNumber=0,bulletSpeed=10,angle='0+9999',bulletSprite=BulletSprites.knife.blue,fogEffect=true,fogTime=60,bulletEvents={
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
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    local angle2=Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y)
                    -- local nx,ny
                    local inum=6
                    local player=Player.objects[1]
                    Shape.timeSpeed=0
                    local dashDirection=angle2+math.pi/2*(self.spawnEvent.executedTimes%2==1 and 1 or -1)
                    local dashAmount=4
                    en.x,en.y=Shape.rThetaPos(en.x,en.y,-2*dashAmount,dashDirection)
                    for ii=1,inum,1 do
                        for i = 1, num, 1 do
                            local direction=range*(i-0.5-num/2)/num+angle
                            local radi=i/num*100+(-1)^ii*ii*0.2
                            local angle3=angle2
                            -- nx,ny=self.x+radi*math.cos(angle2),self.y+radi*math.sin(angle2)
                            Event.DelayEvent{
                                obj=self,
                                delayFrame=i+ii*3,
                                executeFunc=function(self)
                                    if i==num and ii==inum then
                                        Shape.timeSpeed=1
                                    end
                                    local angle3=angle2+math.pi/60*(ii-inum/2)
                                    local x,y=Shape.rThetaPos(self.obj.x,self.obj.y,radi,angle3)
                                    self.obj:spawnBulletFunc{x=x,y=y,direction=direction+ii*0.1,speed=speed,radius=size,index=i}
                                    if i==1 then
                                        en.x,en.y=Shape.rThetaPos(en.x,en.y,dashAmount,dashDirection)
                                    end
                                end
                            }
                        end
                    end
                end
                }
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        en.direction=Shape.to(en.x,en.y,Player.objects[1].x,Player.objects[1].y)
                        a.x=en.x;a.y=en.y
                        a.bulletNumber=20+math.floor(20*(1-en.hp/en.maxhp))
                        if Shape.distance(a.x,a.y,Player.objects[1].x,Player.objects[1].y)<10 and a.frame%30==0 then
                            local num
                            local range=math.eval(a.range)
                            local angle=math.eval(a.angle)
                            local speed=math.eval(a.bulletSpeed)
                            local size=math.eval(a.bulletSize)
                            local angle2=Shape.to(a.x,a.y,Player.objects[1].x,Player.objects[1].y)
                            num=30
                            for ii = 1, num, 1 do
                                local direction=range*(ii)/num+angle-math.pi/2
                                local radi=50
                                local angle3=angle2+ii/num*math.pi*2
                                -- nx,ny=self.x+radi*math.cos(angle2),self.y+radi*math.sin(angle2)
                                Event.DelayEvent{
                                    obj=a,
                                    delayFrame=ii/10,
                                    executeFunc=function(self)
                                        self.obj:spawnBulletFunc{x=self.obj.x+radi*math.cos(angle3),y=self.obj.y+radi*math.sin(angle3),direction=direction+ii*0.1,speed=2*speed,radius=size,index=ii}
                                    end
                                }
                            end
                        end
                    end
                }
                local player=Player(400,600)
                local b=BulletSpawner{x=400,y=300,period=6000,frame=5940,lifeFrame=6001,bulletNumber=10,bulletSpeed=10,angle='0+9999',bulletLifeFrame=990000 ,bulletSprite=BulletSprites.bigRound.red,fogEffect=true,bulletEvents={
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
                    for x0=150,650,50 do
                        for y0=50,600,50 do
                            self:spawnBulletFunc{x=x0,y=y0,direction=0,speed=0,radius=size/(y0-Shape.axisY)*500,invincible=true}
                        end
                    end
                end
                }
            end
        },
        {
            quote='Heptagrams are more mysterious than pentagrams.',
            user='sanae',
            spellName='Preparation "Suwa Daimyōjin Invocation"',
            make=function()
                local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=4800}
                local player=Player(400,600)
                local b
                b=BulletSpawner{x=400,y=150,period=600,frame=540,lifeFrame=10000,bulletNumber=8,bulletSpeed=210,angle='0+9999',bulletSprite=BulletSprites.rice.blue,fogEffect=false,
                spawnBulletFunc=function(self,args)
                    local en
                    local d0=args.direction
                    local nx,ny=args.x-63,args.y--Shape.rThetaPos(args.x,args.y,50,args.direction)
                    en=BulletSpawner{x=nx,y=ny,period=199,lifeFrame=160,bulletNumber=1,bulletSpeed=25,angle=0,bulletSprite=self.bulletSprite,speed=math.eval(args.speed),direction=0,bulletEvents={
                        function(cir,args)
                            local spd=cir.speed
                            local dir=d0+(math.pi/2)*(b.spawnEvent.executedTimes%2)+(en.frame%20)/20*math.pi+cir.direction
                            cir.speed=0
                            Event.Event{
                                times=1,
                                conditionFunc=function()
                                    return en.flag
                                end,
                                executeFunc=function()
                                    cir.direction=d0+math.pi*3/5
                                    cir.speed=70+25*(math.sin(cir.direction))
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='speed',
                                        aimValue=0,
                                        easeFrame=120,
                                        endFunc=function()
                                            cir.direction=dir
                                            Event.EaseEvent{
                                                obj=cir,
                                                aimTable=cir,
                                                aimKey='speed',
                                                aimValue=spd,
                                                easeFrame=260
                                            }
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
                            en.angle=en.direction
                        end
                    }
                    Event.LoopEvent{
                        obj=en,
                        times=7,
                        period=20,
                        executeFunc=function(self)
                            en.spawnEvent.period=1
                            local delta=self.executedTimes==0 and math.pi*4/5 or math.pi*3/5
                            en.direction=en.direction+delta
                            en.angle=en.direction
                        end
                    }
                    Event.DelayEvent{
                        period=180,
                        executeFunc=function()
                            en.flag=1
                        end
                    }
                    -- local cir=Circle({x=args.x or self.x, y=args.y or self.y, radius=args.radius, lifeFrame=self.bulletLifeFrame, sprite=self.bulletSprite, invincible=args.invincible})
                    -- -- table.insert(ret,cir)
                    -- cir.direction=math.eval(args.direction)
                    -- cir.speed=math.eval(args.speed)
                    -- for key, func in pairs(self.bulletEvents) do
                    --     func(cir,args)
                    -- end
                end
                }
            end
        },
        {
            quote='laser test',
            user='addaddda',
            spellName='test',
            make=function()
                local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=4800}
                local player=Player(400,600)
                local a=BulletSpawner{x=400,y=150,period=12,frame=0,lifeFrame=10000,bulletNumber=1,bulletSpeed='60',bulletLifeFrame=100,angle='1.17+0.3',bulletSprite=BulletSprites.laser.blue,bulletEvents={
                    function(cir)
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                cir.direction=cir.direction+0.01
                            end
                        }
                    end
                }}
            end
        },
    }
}
local Text=require"text"
for index, value in ipairs(levelData) do
    for index2, value2 in ipairs(value) do
        if value2.make then
            local ref=value2.make
            value2.make=function()
                Shape.timeSpeed=1
                if not value2.spellName then
                    value2.spellName=''
                end
                local txt=Text{x=200,y=500,width=400,height=100,bordered=false,text=value2.spellName,fontSize=18,color={1,1,1,0},align='center'}
                G.spellNameText=txt
                Event.EaseEvent{
                    obj=txt,
                    easeFrame=120,
                    aimTable=txt,
                    aimKey='y',
                    aimValue=10,
                    progressFunc=function(x)return math.sin(x*math.pi/2) end
                }
                Event.EaseEvent{
                    obj=txt,
                    easeFrame=120,
                    aimTable=txt.color,
                    aimKey=4,
                    aimValue=1,
                    progressFunc=function(x)return math.sin(x*math.pi/2) end
                }
                ref()
            end
        end
    end
end
levelData.defaultQuote='What will happen here?'
return levelData