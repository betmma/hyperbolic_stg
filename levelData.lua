BulletSpawner=require"bulletSpawner"

local levelData={
    {
        {
            quote="In this world things appear smaller when closer to top.",
            user='marisa',
            spellName='Magic Sign "Otherworld Star Dust"',
            make=function ()
                local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=4800}
                local player=Player{x=400,y=600}
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
                local player=Player{x=400,y=600}
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
                local player=Player{x=400,y=600}
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
                local player=Player{x=400,y=600}
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
                local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=600}
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
            quote='not come up yet',
            user='yuugi',
            spellName='Manacles Sign "Manacles a Criminal Can\'t Take Off"',
            make=function()
                local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=4800}
                local player=Player{x=400,y=600}
                local a=BulletSpawner{x=400,y=150,period=300,frame=240,lifeFrame=10000,bulletNumber=15,bulletSpeed='60',bulletLifeFrame=100,angle='1.17+3.14',bulletSprite=BulletSprites.laser.blue,bulletEvents={
                    function(cir)
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                local t=cir.frame%120
                                if t<30 then
                                    cir.direction=cir.direction+0.12
                                elseif t>=60 and t<90 then
                                    cir.direction=cir.direction-0.12
                                end
                            end
                        }
                    end
                }}
                local a
                a=BulletSpawner{x=400,y=150,period=300,frame=240,lifeFrame=10000,bulletNumber=35,bulletSpeed='240+30',bulletLifeFrame=200,warningFrame=60,fadingFrame=20,angle='1.57+0.54',range=math.pi,bulletSprite=BulletSprites.laser.red,highlight=true,laserEvents={
                    function(laser)
                        Event.LoopEvent{
                            obj=laser,
                            period=1,
                            executeFunc=function(self)
                                self.obj.args.direction=self.obj.args.direction+(a.spawnEvent.executedTimes%2==1 and 1 or -1)*0.0005*(2-en.hp/en.maxhp)
                            end
                        }
                    end
                }}
            end
        },
    },
    {
        {
            quote='My common sense really gets in the way.',
            user='reimu',
            spellName='"Hakurei Transmit Barrier"',
            make=function()
                local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=600}
                local b=BulletSpawner{x=400,y=300,period=60,lifeFrame=10000,bulletNumber=30,bulletSpeed='10+3',bulletLifeFrame=10000,angle='0+3.14',bulletSprite=BulletSprites.scale.red,spawnBatchFunc=function(self)
                    local num=math.eval(self.bulletNumber)
                    local range=math.eval(self.range)
                    local angle=math.eval(self.angle)
                    local size=math.eval(self.bulletSize)
                    for i = 1, num, 1 do
                        local direction=range*(i-0.5-num/2)/num+angle
                        self:spawnBulletFunc{x=self.x,y=self.y,direction=direction,speed=math.eval(self.bulletSpeed),radius=size,index=i,batch=self.bulletBatch}
                    end
                end}
                local greenLines=Shape{x=300,y=0,lifeFrame=99999}
                table.insert(G.sceneTempObjs,greenLines)
                greenLines.items={}
                greenLines.draw=function(self)
                    local colorref={love.graphics.getColor()}
                    love.graphics.setColor(0,1,0,0.5)
                    local new={}
                    for i,value in pairs(self.items) do
                        local x1,y1,x2,y2,rest=value[1],value[2],value[3],value[4],value[5]
                        if rest>0 then
                            table.insert(new,{x1,y1,x2,y2,rest-1})
                        end
                        love.graphics.line(x1,y1,x2,y2)
                    end
                    self.items=new
                    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4] or 1)
                end
                local a
                a=BulletSpawner{x=400,y=300,period=3,frame=0,lifeFrame=10000,bulletNumber=16,bulletSpeed='30',bulletLifeFrame=10000,angle=-0.5,range=math.pi*2,bulletSprite=BulletSprites.dot.blue,bulletEvents={
                    function(cir)
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=60,
                            executeFunc=function()
                                cir.sprite=BulletSprites.bill.blue
                                cir.direction=cir.direction+(cir.args.index%2==1 and 1 or -1)*0.4
                            end
                        }
                        -- Event.DelayEvent{
                        --     obj=cir,
                        --     delayFrame=120,
                        --     executeFunc=function()
                        --         cir.sprite=BulletSprites.bill.blue
                        --         cir.direction=cir.direction+(cir.args.index%2==1 and 1 or -1)*-1
                        --     end
                        -- }
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                if not cir.mark then
                                    local polyline=Player.objects[1].border
                                    local flag=true
                                    if cir.x<150 then
                                        cir.x=650
                                        table.insert(greenLines.items,{150,cir.y,650,cir.y,5})
                                    elseif cir.x>650 then
                                        cir.x=150
                                        table.insert(greenLines.items,{150,cir.y,650,cir.y,5})
                                    elseif not polyline:insideOne(cir.x,cir.y,1) then
                                        local ny=Shape.lineX2Y(polyline.points[3].x,polyline.points[3].y,polyline.points[4].x,polyline.points[4].y,cir.x)
                                        -- print(polyline.points[3].x,polyline.points[3].y,polyline.points[4].x,polyline.points[4].y,cir.x,ny)
                                        table.insert(greenLines.items,{cir.x,cir.y,cir.x,ny,5})
                                        cir.y=ny
                                    elseif not polyline:insideOne(cir.x,cir.y,3) then
                                        local ny=Shape.lineX2Y(polyline.points[1].x,polyline.points[1].y,polyline.points[2].x,polyline.points[2].y,cir.x)
                                        table.insert(greenLines.items,{cir.x,cir.y,cir.x,ny,5})
                                        cir.y=ny
                                    else
                                        flag=false
                                    end
                                    if flag then
                                        cir.mark=true
                                        cir.sprite=BulletSprites.bill.green
                                    end
                                end
                                -- local vx=cir.speed*math.cos(cir.direction)
                                -- local vy=cir.speed*math.sin(cir.direction)
                                -- vx=vx+math.cos(a.angle)*0.05
                                -- vy=vy+math.sin(a.angle)*0.05
                                -- cir.speed=(vx*vx+vy*vy)^0.5
                                -- cir.direction=math.atan2(vy,vx)
                            end
                        }
                    end
                }}
                Event.LoopEvent{
                    obj=a,
                    period=1,
                    executeFunc=function(self)
                        local pe=1800
                        local t=a.frame%(pe*2)
                        if t==2 then
                            a.bulletNumber=12
                            a.bulletSpeed=20
                            a.range=math.pi*2
                        end
                        if t==180 then
                            a.bulletSpeed=30
                            a.bulletNumber=8
                            a.range=math.pi/2
                        end
                        if t<180 then
                            a.angle=a.angle+0.0033*(a.angle<1.57 and 1 or -1)
                        elseif t>=180 and t<pe then
                            a.angle=a.angle+0.0007*(a.angle<1.57 and 1 or -1)
                        elseif t>=pe and t<2*pe-180 then
                            a.angle=a.angle-0.0007*(a.angle<1.57 and 1 or -1)
                        elseif t>=2*pe-180 then
                            a.angle=a.angle-0.0033*(a.angle<1.57 and 1 or -1)
                        end
                        if t%60==45 and t>150 then
                            a.spawnEvent.period=999
                        elseif t%60==0 then
                            a.spawnEvent.period=3
                            a.spawnEvent.frame=0
                            a.angle=math.pi-a.angle
                        end

                    end
                }
            end
        },
        {
            quote='Are there hidden black holes twisting the path of stars?',
            user='marisa',
            spellName='Black Magic "Gamma-ray Burst"',
            make=function()
                -- G.viewMode.mode=G.VIEW_MODES.FOLLOW
                local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=600}
                -- player.moveMode=Player.moveModes.Monopolar
                -- G.viewMode.object=player
                local a
                a={x=150,y=300,period=300,frame=240,lifeFrame=10000,bulletNumber=512,bulletSpeed='20',bulletLifeFrame=10000,angle=math.pi/2,range=math.pi*256*0,bulletSprite=BulletSprites.star.orange,bulletEvents={
                    function(cir,args,self)
                        local colors={'gray','red','purple','blue','cyan','green','yellow','orange'}
                        local ind=math.floor(math.eval('5+4'))
                        cir.sprite=BulletSprites.star[colors[ind]]
                        local ratio=(cir.args.index/self.bulletNumber)
                        Event.EaseEvent{
                            obj=cir,
                            easeFrame=800*ratio,
                            aimTable=cir,
                            aimKey='direction',
                            aimValue=cir.direction+(((ratio*32%1)*2+0.8)*math.pi/2)*(self.fogTime==61 and 1 or -1),
                            progressFunc=function(x)
                                return math.sin(x*math.pi*2)
                            end
                        }
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=300,
                            executeFunc=function()
                                cir.speed=cir.speed+math.eval('0+1')
                            end
                        }
                    end
                }}
                local s=BulletSpawner(a)
                a.x=650;a.frame=90;a.fogTime=61
                local c=BulletSpawner(a)
                
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local per=en.hp/en.maxhp
                        if per<0.33 then
                            s.bulletNumber,c.bulletNumber=512,512
                        elseif per<0.67 then
                            s.bulletNumber,c.bulletNumber=384,384
                        else
                            s.bulletNumber,c.bulletNumber=256,256
                        end
                    end
                }
            end
        },
        {
            quote='I can barely escape from these red hearts.',-- I have a feeling that something will happen if I linger till...',
            user='koishi',
            spellName='Unconscious "Super-Ego\'s Trace"',
            make=function()
                Shape.removeDistance=300
                local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=600}
                local moveFunc=function(cir,args,self)
                    local color2ratio={green=0.3,blue=0.5,purple=0.8,red=1}
                    local color=SpriteData[cir.sprite].color
                    local moveRatio=color2ratio[color]
                    local ratio=(cir.args.index/self.bulletNumber)
                    if color=='purple'or color=='red'then
                        cir.speed=cir.speed*ratio
                        cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)
                    end
                    Event.EaseEvent{
                        obj=cir,
                        easeFrame=9500,--*ratio,
                        aimTable=cir,
                        aimKey='x',
                        aimValue=cir.x+moveRatio,
                        progressFunc=function(x)
                            return player.x--math.sin(x*math.pi*2)
                        end
                    }
                    Event.EaseEvent{
                        obj=cir,
                        easeFrame=9500,--*ratio,
                        aimTable=cir,
                        aimKey='y',
                        aimValue=cir.y+moveRatio,
                        progressFunc=function(x)
                            return player.y--math.sin(x*math.pi*2)
                        end
                    }
                end
                local a,b,c,d
                a=BulletSpawner{x=400,y=300,period=120,lifeFrame=10000,bulletNumber=10,bulletSpeed='20',bulletLifeFrame=10000,angle='0+3.14',range=math.pi*2,bulletSprite=BulletSprites.heart.green,bulletEvents={
                    moveFunc
                }}
                a.removeDistance=500
                Event.LoopEvent{
                    period=1,
                    obj=a,
                    executeFunc=function()
                        local frame=a.frame
                        local theta=frame/120
                        local x,y=Shape.rThetaPos(player.x,player.y,30,theta)
                        a.x,a.y=x,y
                        local per=math.min(en.hp/en.maxhp,G.levelRemainingFrame/G.levelRemainingFrameMax)
                        if per<0.8 and not b then
                            b=BulletSpawner{x=400,y=300,period=120,lifeFrame=10000,bulletNumber=10,bulletSpeed='15',bulletLifeFrame=10000,angle='0+3.14',range=math.pi*2,bulletSprite=BulletSprites.heart.blue,bulletEvents={
                                moveFunc,
                                function(cir,args,self)
                                    Event.DelayEvent{
                                        delayFrame=20,
                                        executeFunc=function()
                                            cir.direction=Shape.to(b.x,b.y,player.x,player.y)
                                        end
                                    }
                                end
                            }}
                            b.removeDistance=500
                        end
                        if b then
                            local x,y=Shape.rThetaPos(player.x,player.y,math.min(40,30+b.frame/2),theta+b.frame/360)
                            b.x,b.y=x,y
                        end
                        if per<0.6 and not c then
                            c=BulletSpawner{x=400,y=300,period=180,lifeFrame=10000,bulletNumber=4,bulletSpeed='10',bulletLifeFrame=10000,angle='0+3.14',range=math.pi*2,bulletSprite=BulletSprites.heart.purple,bulletEvents={
                                moveFunc,
                            }}
                            c.removeDistance=500
                        end
                        if c then
                            local x,y=Shape.rThetaPos(player.x,player.y,math.min(50,40+c.frame/2),theta+b.frame/360+c.frame/240)
                            c.x,c.y=x,y
                        end
                        if per<0.4 and not d then
                            --1/(1/180+1/120+1/240+1/360)=48
                            local the=theta+b.frame/360+c.frame/240
                            local need=math.pi-the%math.pi
                            d=BulletSpawner{x=400,y=300,period=452,frame=452-need*48,lifeFrame=10000,bulletNumber=1,bulletSpeed='8',bulletLifeFrame=10000,angle='0+3.14',range=math.pi*2,bulletSprite=BulletSprites.heart.red,bulletEvents={
                                moveFunc,
                            }}
                            d.removeDistance=10000
                        end
                        if d then
                            local x,y=Shape.rThetaPos(player.x,player.y,math.min(60,50+c.frame/2),theta+b.frame/360+c.frame/240+(d.realFrame)/180)
                            d.x,d.y=x,y
                        end
                    end
                }
            end
        },
        {
            quote='not come up yet',
            user='cirno',
            spellName='Freeze Sign "Rime Ice"',
            make=function()
                local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=4800}
                local player=Player{x=400,y=600}
                local circPeriod=5
                local circRad=60
                local a
                a=BulletSpawner{x=400,y=50,period=20,frame=0,lifeFrame=23000,bulletNumber=20,bulletSpeed=30,bulletLifeFrame=10000,angle='1.57+0.3',range=math.pi/2,bulletSprite=BulletSprites.rim.blue,fogEffect=true,fogTime=20,bulletEvents={
                    function(cir,args,self)
                        local speed=cir.speed
                        -- cir.speed=0
                        local limit=args.limit
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                if not cir.flag and cir.y<300 and math.abs(cir.direction-math.pi/2)>limit then
                                    cir.direction=math.pi-(cir.direction+0.5*(math.pi/2-cir.direction))
                                end
                            end
                        }
                    end
                    },
                spawnBatchFunc= function(self)
                    local num=math.eval(self.bulletNumber)
                    local range=math.eval(self.range)
                    local angle=math.eval('-1.57+2')
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    local limit=math.eval('0.4+0.2')
                    for i = 1, num, 1 do
                        local direction=range*(i-0.5-num/2)/num+angle
                        local nx,ny=Shape.rThetaPos(self.x,self.y,circRad*i/num,angle)
                        Event.DelayEvent{
                            obj=self,
                            delayFrame=circPeriod/num*i*range,
                            executeFunc=function()
                                if player.y<100 then
                                    direction=Shape.to(nx,ny,player.x,player.y)
                                end
                                local cir=self:spawnBulletFunc{x=nx,y=ny,direction=direction,speed=speed,radius=size,index=i,batch=self.bulletBatch,limit=limit}
                                if player.y<100 and cir then
                                    cir.flag=true
                                end
                            end
                        }
                    end
                end
                }
                Event.LoopEvent{
                    obj=a,
                    period=1,
                    executeFunc=function()
                        a.x=a.x+math.min(a.frame/100,3)*math.eval('1+0.1')
                        if a.x>650 then
                            a.x=a.x-500
                        end
                        en.x,en.y=a.x,a.y
                        a.spawnEvent.period=(en.hp/en.maxhp)*10+10
                    end
                }
            end
        },
        {
            quote='not come up yet',
            user='cirno',
            spellName='Crystalization "Supernatural Lattice"',
            make=function()
                local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=600}
                local bullets={}
                local a
                a=BulletSpawner{x=400,y=300,period=600,frame=540,lifeFrame=23000,bulletNumber=600,bulletSpeed=40,bulletLifeFrame=9900,angle='-1.57+0.9',range=math.pi*200,bulletSprite=BulletSprites.crystal.blue,fogEffect=true,fogTime=20,bulletEvents={
                    function(cir,args,self)
                        local x0,y0=cir.x,cir.y
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                if not cir.flag then
                                    local dis=Shape.distance(cir.x,cir.y,x0,y0)
                                    if dis>60 then
                                        cir.flag=true
                                        cir.direction=math.eval('0+3.14')
                                        cir.speed=math.eval('20+5')
                                    end
                                    if cir.frame%20==0 then
                                        local rand= math.eval('0.0+1.0')
                                        local angle=math.pi/3
                                        local prob=0.2
                                        if rand<prob and cir.turn~=1 then
                                            cir.direction=cir.direction+angle
                                            cir.turn=1
                                        elseif rand>1-prob and cir.turn~=-1 then
                                            cir.direction=cir.direction-angle
                                            cir.turn=-1
                                        end
                                    end
                                    local flag=true
                                    for key, value in pairs(bullets) do
                                        local dis=Shape.distance(value.x,value.y,cir.x,cir.y)
                                        if dis<5 then
                                            flag=false
                                            break
                                        end
                                    end
                                    if flag then
                                        cir.flag=true
                                        cir.speed=0
                                        cir.dis=dis
                                        table.insert(bullets,cir)
                                    end
                                    
                                end
                            end
                        }
                    end
                    }
                }
                Event.LoopEvent{
                    obj=en,
                    period=10,
                    executeFunc=function()
                        local newB={}
                        for key,value in pairs(bullets)do
                            if not value.removed then
                                table.insert(newB,value)
                            end
                        end
                        bullets=newB
                    end
                }
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local f=a.frame
                        -- if f%600==100 then
                        --     Effect.Charge{
                        --         animationFrame=100,
                        --         obj=a,
                        --         x=a.x,y=a.y
                        --     }
                        -- end
                        if f%600==200 then
                            local dir=Shape.to(a.x,a.y,player.x,player.y)
                            for key,value in pairs(bullets)do
                                Event.DelayEvent{
                                    obj=value,
                                    delayFrame=value.dis,
                                    executeFunc=function()
                                        value.direction=dir--+math.eval('0+0.01')
                                        Event.EaseEvent{
                                            obj=value,
                                            easeFrame=200,
                                            aimTable=value,
                                            aimKey='speed',
                                            aimValue=30
                                        }
                                    end
                                }
                            end
                            bullets={}
                        end
                    end
                }
            end
        },
    }
}
levelData.needPass={3,6,9,12,15,18}
local Text=require"text"
for index, value in ipairs(levelData) do
    for index2, value2 in ipairs(value) do
        if value2.make then
            local ref=value2.make
            value2.make=function()
                local replay=G.replay or {}
                local seed = replay.seed or math.floor(os.time()+os.clock()*1337)
                math.randomseed(seed)
                G.randomseed=seed
                Shape.timeSpeed=1
                -- show spellcard name
                do
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
                end
                ref()
                -- apply upgrades
                local options=G.UIDEF.UPGRADES.options
                for k,value in ipairs(options) do
                    for i,option in pairs(value) do
                        if option.upgrade and G.save.upgrades[i][k].bought==true then
                            G.UIDEF.UPGRADES.upgrades[option.upgrade].executeFunc()
                        end
                    end
                end
            end
        end
    end
end
levelData.defaultQuote='What will happen here?'
return levelData