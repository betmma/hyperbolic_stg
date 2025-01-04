BulletSpawner=require"bulletSpawner"

-- currently levels are randomly stored, and need to be reorganized after majority of levels are done. The draft of final arrangement is as follows:
-- main idea: similar to original game, characters are sorted by the stage they appear in the original game. Like fan-game "Shatter All Spell Card", it's a good idea to add secret levels and unlock secret upgrades.
-- level 1: doremy's regular attack first (introduction), then doremy's spell, then protagonists like reimu, marisa, sakuya, sanae to give useful information. (yuugi should be moved to later levels)
-- level 2-4: characters from stage 1-3. 
-- level 5: introduce the follow view and broader move area. Let doremy introduce is fine, or maybe seiga (霍 青娥).
-- level 6-9: characters from stage 4-EX.
-- level 10: introduce boardless levels? I really wonder if this leads to interesting gameplay.
-- (an idea for boardless level: player needs to go far away then return to initial place. Without compass it's very difficult in hyperbolic world.)
-- level EX: protagonists' spells again.
local levelData={
    {
        -- Warning: as text data need localization, all [quotes] and [spellNames] here aren't used in game and are only for coding reference. Data used are in localization.lua. But [user] parameter is used as a key to get localization.
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
                local b
                local a=BulletSpawner{x=400,y=600,period=300,frame=180,lifeFrame=10000,bulletNumber=1,bulletSpeed=0,bulletSprite=BulletSprites.blackrice.blue,bulletEvents={
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
                    SFX:play('enemyShot',true,1)
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
                    SFX:play('enemyShot',true,1)
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
                a=BulletSpawner{x=400,y=150,period=300,frame=240,lifeFrame=10000,bulletNumber=35,bulletSpeed='480',bulletLifeFrame=200,warningFrame=60,fadingFrame=20,angle='1.57+0.54',range=math.pi,bulletSprite=BulletSprites.laser.red,highlight=true,laserEvents={
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
                    SFX:play('enemyShot',true)
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
                local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=7500}
                local player=Player{x=400,y=600}
                -- player.moveMode=Player.moveModes.Monopolar
                -- G.viewMode.mode=G.VIEW_MODES.FOLLOW
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
            end,
            leave=function()
                if G.levelRemainingFrame<=0 then
                    G.save.levelData[2].extraUnlock=true
                end
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
            quote='This kind of ice looks quite sharp. I\'d never want to touch it.',
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
        {
            quote='??',
            user='satori',
            spellName='"Eye of Horus"',
            make=function()
                local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=600}
                local phi0=math.eval('0+999')
                local a
                local tmpBullets={}
                a=BulletSpawner{x=400,y=100,period=240,frame=200,lifeFrame=23000,bulletNumber=30,bulletSpeed=50,bulletLifeFrame=300,angle='1.57+0.5',range=math.pi*2,bulletSprite=BulletSprites.round.yellow,fogEffect=true,fogTime=20,bulletEvents={
                    function(cir,args,self)
                        if cir.args.index==1 then
                            tmpBullets={}
                        end
                        table.insert(tmpBullets,cir)
                        local sx,sy=cir.speed*math.cos(cir.direction),cir.speed*math.sin(cir.direction)
                        sy=sy/2+75
                        cir.speed=(sx^2+sy^2)^0.5
                        cir.direction=math.atan2(sy,sx)
                        cir.sprite=cir.args.index%3==0 and BulletSprites.round.yellow or BulletSprites.round.purple
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=60,
                            executeFunc=function()
                                local dirRef=cir.args.index%2==0 and Shape.to(cir.x,cir.y,tmpBullets[cir.args.index%a.bulletNumber+1].x,tmpBullets[cir.args.index%a.bulletNumber+1].y) or Shape.to(cir.x,cir.y,tmpBullets[(cir.args.index-2)%a.bulletNumber+1].x,tmpBullets[(cir.args.index-2)%a.bulletNumber+1].y)
                                --(cir.direction+3.14*0.6*(cir.args.index%2==0 and -1 or 1))%(math.pi*2)
                                local laser=Laser{x=cir.x,y=cir.y,direction=dirRef,speed=300,radius=0.7,index=1,lifeFrame=240,warningFrame=80,fadingFrame=20,sprite=cir.args.index%3==0 and BulletSprites.laser.yellow or BulletSprites.laser.purple,
                                bulletEvents={
                                    function(cir)
                                        Event.LoopEvent{
                                            obj=cir,
                                            times=1,
                                            period=1,
                                            conditionFunc=function()
                                                if not(cir.x>120 and cir.x<680 and cir.y>0 and cir.y<650) then
                                                    cir:remove()
                                                end 
                                                if not(cir.x>150 and cir.x<650 and cir.y>0 and cir.y<600) then
                                                    return cir.sprite==BulletSprites.laser.yellow and cir.index%10==0 
                                                end
                                            end,
                                            executeFunc=function(self)
                                                if not cir.safe then
                                                    Circle{x=cir.x,y=cir.y,direction=cir.direction+math.pi+math.eval('0+0.3'),speed=20,sprite=BulletSprites.dot.red}
                                                end
                                        end}
                                    end
                                }}
                                cir.speed=0
                                local rotate=math.sin(a.spawnEvent.executedTimes+phi0)*0.5*(cir.args.index%2==0 and -1 or 1)--math.eval('0+0.5')
                                Event.EaseEvent{
                                    obj=laser,
                                    aimTable=laser.args,
                                    aimKey='direction',
                                    aimValue=laser.args.direction+rotate,
                                    easeFrame=60,
                                    progressFunc=function(x)
                                        return -math.sin(math.pi/2*(1-x))+1
                                    end,
                                }
                            end
                        }
                        -- Event.LoopEvent{
                        --     obj=cir,period=1,
                        --     executeFunc=function ()
                        --         -- cir.direction=cir.direction+(cir.y-300)/10000
                        --         for key, player in pairs(Player.objects) do
                        --             local dis=Shape.distance(player.x,player.y,cir.x,cir.y)
                        --             local radi=player.radius+cir.radius
                        --             if dis<radi+player.radius*1.5 and not cir.damaged then
                        --                 player.hurt=true
                        --                 player.hp=player.hp-0.02
                        --                 cir.damaged=true
                        --             end
                        --         end
                        --     end
                        -- }
                    end
                    }
                }
            end
        },
        {
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
        },
    },
    {
        {
            quote='Such surreal scene of a broader hyperbolic area...',
            user='remilia',
            spellName='Scarlet Sign "Vampirish Plaza"',
            make=function()
                G.levelRemainingFrame=5400
                Shape.removeDistance=10000
                local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=600}
                player.moveMode=player.moveModes.Euclid
                player.border:remove()
                local poses={}
                for i = 1, 12, 1 do
                    local nx,ny=Shape.rThetaPos(400,300,200,math.pi/6*(i-.5))
                    table.insert(poses,{nx,ny})
                end
                player.border=PolyLine(poses)
                G.viewMode.mode=G.VIEW_MODES.FOLLOW
                G.viewMode.object=player
                local a
                a=BulletSpawner{x=400,y=150,period=80,frame=40,lifeFrame=10000,bulletNumber=35,bulletSpeed='60',bulletLifeFrame=2000,angle='1.57+0.54',range=math.pi*2,bulletSprite=BulletSprites.giant.red,highlight=true,spawnSFXVolume=1,bulletEvents={
                    function(cir)
                        if cir.args.index>35 then
                            cir.direction=Shape.to(a.x,a.y,player.x,player.y)+0.4*(cir.args.index%2==0 and 1 or -1)
                            cir.speed=(cir.args.index-35)*3
                            cir.sprite=BulletSprites.bigRound.red
                        elseif(cir.args.index%2==0)then
                            cir.direction=Shape.to(a.x,a.y,player.x,player.y)
                            cir.speed=cir.args.index*3
                        end
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=0,
                            easeFrame=300
                        }
                        Event.DelayEvent{
                            delayFrame=1800,
                            executeFunc=function()
                                cir.safe=true
                                cir.sprite_transparency=0.6
                                Event.EaseEvent{
                                    obj=cir,
                                    aimTable=cir,
                                    aimKey='sprite_transparency',
                                    aimValue=0,
                                    easeFrame=200,
                                }
                            end
                        }
                    end
                }
                }
                Event.LoopEvent{
                    period=1,
                    obj=en,
                    executeFunc=function()
                        a.x,a.y=en.x,en.y--
                        local hpp=en.hp/en.maxhp
                        if hpp<0.7 then
                            a.bulletNumber=70
                            a.range=math.pi*4
                        end
                        if hpp<0.3 then
                            a.period=40
                        end
                        if en.frame%300==0 then
                            local nx,ny=Shape.rThetaPos(player.x,player.y,50,math.eval('0+3.14'))
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
                    end
                }
            end
        },
        {
            quote='Yuugi\'s classic three steps become unpredictable here. She is truly drunken.',
            user='yuugi',
            spellName='Big Four Arcanum "Knock Out In Three Sides"',
            make=function()
                G.levelRemainingFrame=5400
                local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=600}
                local center,radius,thetas,vertices,outvertices,polyline,outpolyline
                Event.LoopEvent{
                    period=1,
                    obj=en,
                    executeFunc=function()
                        -- a.x,a.y=en.x,en.y--
                        local hpp=en.hp/en.maxhp
                        local t=(en.frame-100)%480
                        if t==0 then
                            center={x=math.eval('400+50'),y=math.eval('300+50')}
                            
                            Event.EaseEvent{
                                obj=en,
                                aimTable=en,
                                aimKey='x',
                                aimValue=center.x,
                                easeFrame=60,
                                progressFunc=Event.sineProgressFunc
                            }
                            Event.EaseEvent{
                                obj=en,
                                aimTable=en,
                                aimKey='y',
                                aimValue=center.y,
                                easeFrame=60,
                                progressFunc=Event.sineProgressFunc
                            }
                            radius=math.eval('50+10')
                            thetas={math.eval('0+3')}
                            table.insert(thetas,thetas[1]+math.pi*2/3+math.eval('0+0.5'))
                            table.insert(thetas,thetas[2]+math.pi*2/3+math.eval('0+0.5'))
                            vertices={}
                            outvertices={}
                            for i = 1, 3 do
                                local x,y=Shape.rThetaPos(center.x,center.y,radius-7,thetas[i])
                                local xo,yo=Shape.rThetaPos(center.x,center.y,radius+7,thetas[i])
                                table.insert(vertices,{x,y})
                                table.insert(outvertices,{xo,yo})
                                local fog=Circle({x=x, y=y, radius=1, lifeFrame=60, sprite=Asset.bulletSprites.fog.gray,safe=true})
                                Event.EaseEvent{
                                    obj=fog,
                                    easeFrame=60,
                                    aimTable=fog,
                                    aimKey='sprite_transparency',
                                    aimValue=0,
                                    -- period=60,
                                    endFunc=function()
                                        SFX:play('enemyShot',true,1)
                                        local cir=Circle{x=x,y=y,direction=0,speed=0,sprite=BulletSprites.round.red,lifeFrame=400,invincible=true}
                                        for j=1,30 do
                                            Circle{x=x,y=y,direction=j*math.pi/15+thetas[i],speed=15,sprite=BulletSprites.dot.red,lifeFrame=800}
                                        end
                                    end
                                }
                            end
                            if polyline then
                                polyline:remove()
                            end
                            polyline=PolyLine(vertices,false)
                            if outpolyline then
                                outpolyline:remove()
                            end
                            outpolyline=PolyLine(outvertices,false)
                        elseif t==130 then
                            local xoff=math.eval('0+0.1')
                            local count=0
                            local sfxplayed,sfxplayed2=false,false
                            for y0 = 0, 100, 2 do
                                local y=y0*y0/13
                                for x = 100, 700, (y+100)/20 do
                                    count=count+1
                                    local nx,ny=x+xoff*y,y
                                    local inarea=polyline:inside(nx,ny)
                                    local outarea=not outpolyline:inside(nx,ny)
                                    if not inarea and not outarea then
                                        goto continue
                                    end
                                    local delay0=Shape.distance(center.x,center.y,nx,ny)*(inarea and 1.5 or 0.1)
                                    Event.DelayEvent{
                                        delayFrame=delay0+(inarea and 0 or 80),
                                        executeFunc=function()
                                            if not sfxplayed then
                                                SFX:play('enemyShot',true,1)
                                                sfxplayed=true
                                            end
                                            local cir=Circle{x=nx,y=ny,direction=Shape.to(center.x,center.y,nx,ny)+(inarea and math.pi or 0),speed=0,sprite=inarea and BulletSprites.bigRound.red or BulletSprites.giant.red,lifeFrame=800,batch=Asset.bulletHighlightBatch}
                                            Event.DelayEvent{
                                                delayFrame=-delay0+80+(inarea and 0 or 50),
                                                executeFunc=function()
                                                    
                                            if not sfxplayed2 then
                                                SFX:play('enemyShot',true,1)
                                                sfxplayed2=true
                                            end
                                                    if inarea then
                                                        cir.speed=15
                                                    end
                                                    Event.EaseEvent{
                                                        obj=cir,easeFrame=100,aimTable=cir,aimKey='speed',aimValue=inarea and 30 or 60,
                                                    }
                                                end
                                            }
                                            
                                        end
                                    }
                                    ::continue::
                                end
                            end
                        end
                    end
                }
            end
        },
        {
            quote='Oh no, I can\'t find the direction home! Can compass work in this world?',
            user='seija',
            spellName='Turnabout "Change Orientation"',
            make=function()
                -- What this spellcard does is forcing player to look at the enemy by changing player's natural direction.
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
                local b=BulletSpawner{x=400,y=300,period=5,frame=0,lifeFrame=6001,bulletNumber=24,bulletSpeed=30,angle=0,bulletLifeFrame=990000,bulletSprite=BulletSprites.blackrice.red,bulletEvents={
                    function(cir)
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=40,
                            executeFunc=function()
                                cir.sprite=BulletSprites.rice.red
                                cir.speed=cir.speed+20
                                Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=0,sprite=BulletSprites.fog.red,lifeFrame=5,safe=true}
                            end
                        }
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=80,
                            executeFunc=function()
                                cir.sprite=BulletSprites.blackrice.red
                                cir.speed=cir.speed-20
                                Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=0,sprite=BulletSprites.fog.red,lifeFrame=5,safe=true}
                            end
                        }
                    end
                }
                }
                local c=BulletSpawner{x=400,y=300,period=30,frame=0,lifeFrame=6001,bulletNumber=5,range=2,bulletSpeed=60,angle='player',bulletLifeFrame=990000,bulletSprite=BulletSprites.bigRound.blue,}
                Event.LoopEvent{
                    obj=b,
                    period=1,
                    executeFunc=function()
                        local t=b.frame%500
                        local times=math.ceil(b.frame/2000)
                        local hpPercent=en.hp/en.maxhp
                        if t==0 then
                            b.spawnEvent.frame=0
                            b.spawnEvent.period=5
                        elseif t==400 then
                            b.spawnEvent.period=9999
                        end
                        if times%2==0 then
                            b.angle=b.angle+0.004*(2-hpPercent)
                        else
                            b.angle=b.angle-0.004*(2-hpPercent)
                        end
                        if hpPercent>0.8 then
                            c.spawnEvent.period=9999
                        else
                            if not c.reset then
                                c.spawnEvent.frame=0
                                c.reset=true
                            end
                            c.spawnEvent.period=30*(1.5-hpPercent)
                        end
                    end
                }
                Event.LoopEvent{
                    obj=en,
                    period=300,
                    executeFunc=function()
                        Effect.Charge{obj=b,x=b.x,y=b.y}
                        Event.DelayEvent{
                            obj=b,
                            delayFrame=100,
                            executeFunc=function()
                                SFX:play("enemyPowerfulShot")
                                Event.EaseEvent{
                                    obj=player,aimTable=player,aimKey='naturalDirection',aimValue=function()
                                        return math.modClamp(Shape.to(player.x,player.y,en.x,en.y)+math.pi/2,player.naturalDirection,math.pi)
                                    end,easeFrame=100,easeMode='hard',progressFunc=Event.sineProgressFunc
                                }
                            end
                        }
                    end
                }
            end
        },
        {
            quote='What is she doing? I don\'t think my orientation has changed, but the world is still spinning...',
            user='seija',
            spellName='Turnabout "Change Projection"',
            make=function()
                G.levelRemainingFrame=5400
                Shape.removeDistance=2000
                local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=600}
                -- the angle of normal rotation. What this spellcard does is to replace hyperbolic rotation with normal rotation (that rotates y=-100 line), so that the direction to other things remains same, but it looks distorted.
                player.naturalDirectionSpecial=0
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
                local b=BulletSpawner{x=400,y=300,period=10,frame=0,lifeFrame=6001,bulletNumber=72,bulletSpeed=60,angle=0,bulletLifeFrame=990000,bulletSprite=BulletSprites.rice.red,bulletEvents={
                    function(cir)
                        local color=SpriteData[cir.sprite].color
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=30+10*(1-en.hp/en.maxhp),
                            executeFunc=function()
                                cir.sprite=BulletSprites.blackrice[color]
                                cir.speed=cir.speed-30
                                Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=0,sprite=BulletSprites.fog.red,lifeFrame=5,safe=true}
                            end
                        }
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=100,
                            executeFunc=function()
                                cir.sprite=BulletSprites.rice[color]
                                cir.speed=cir.speed+30
                                Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=0,sprite=BulletSprites.fog.red,lifeFrame=5,safe=true}
                                cir.direction=cir.direction+1.7*(color=='red' and 1 or -1)
                            end
                        }
                    end
                }
                }
                local c=BulletSpawner{x=400,y=300,period=30,frame=0,lifeFrame=6001,bulletNumber=6,range=0.48,bulletSpeed=60,angle=0,bulletLifeFrame=990000,bulletSprite=BulletSprites.bigRound.blue,}

                Event.LoopEvent{
                    obj=b,
                    period=1,
                    executeFunc=function()
                        local t=b.frame%200
                        local times=math.ceil(b.frame/200)
                        local hpPercent=en.hp/en.maxhp
                        if t==0 then
                            b.spawnEvent.frame=0
                            b.spawnEvent.period=10
                        elseif t>=100*(1-0.6*hpPercent) then
                            b.spawnEvent.period=9999
                            b.angle=b.angle+math.eval('0+0.3')
                        end
                        if times%2==0 then
                            b.bulletSprite=BulletSprites.rice.red
                        else
                            b.bulletSprite=BulletSprites.rice.blue
                        end
                        if hpPercent>0.9 then
                            c.spawnEvent.period=9999
                        else
                            if not c.reset then
                                c.spawnEvent.frame=0
                                c.reset=true
                            end
                            c.spawnEvent.period=10*(1.5+0.5*hpPercent)
                            c.bulletSpeed=50*(0.95-0.4*hpPercent)
                        end
                        c.angle=Shape.to(c.x,c.y,player.x,player.y)+math.eval('0+0.04')
                    end
                }
                Event.LoopEvent{
                    obj=en,
                    period=300,
                    executeFunc=function()
                        Effect.Charge{obj=b,x=b.x,y=b.y}
                        Event.DelayEvent{
                            obj=b,
                            delayFrame=100,
                            executeFunc=function()
                                SFX:play("enemyPowerfulShot")
                                local delta=player.naturalDirection-player.naturalDirectionSpecial
                                delta=math.abs(delta)<math.pi/2 and math.pi/2*math.sign(delta)+delta or delta
                                Event.EaseEvent{
                                    obj=player,aimTable=player,aimKey='naturalDirectionSpecial',aimValue=delta+player.naturalDirectionSpecial,easeFrame=100,progressFunc=Event.sineProgressFunc
                                }
                            end
                        }
                    end
                }

                local rotateRef=player.testRotate
                player.testRotate=function (player,angle,restore)
                    if not restore then
                        love.graphics.push()
                        local scale=(love.graphics.getHeight()/2-Shape.axisY)/(G.viewMode.object.y-Shape.axisY)
                        local theta=player.naturalDirectionSpecial
                        love.graphics.translate(player.x,player.y)
                        love.graphics.rotate(theta)
                        love.graphics.translate(-player.x,-player.y)
                    else
                        love.graphics.pop()
                    end
                    rotateRef(player,angle-player.naturalDirectionSpecial,restore)
                end

            end,
        },
        {
            quote='Keep my speed up, and catch the right time to cross tracks!',
            user='flandre',
            spellName='Taboo "Labyrinthine Trap"',
            make=function()
                -- this spellcard is to showcase hyperbolic circle has exponential growth of circumference. The outmost track provides much longer time than inner tracks before the barrier catches up. So the key is to spend most time in outer tracks, and when barrier is close, straightly cross into the center then go back to outer tracks on the other side, so that you earn half circumference of space. 
                G.levelRemainingFrame=5400
                Shape.removeDistance=1000
                local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=600}
                player.moveMode=player.moveModes.Natural
                player.border:remove()
                local poses={}
                for i = 1, 12, 1 do
                    local nx,ny=Shape.rThetaPos(400,300,110,math.pi/6*(i-.5))
                    table.insert(poses,{nx,ny})
                end
                player.border=PolyLine(poses)
                G.viewMode.mode=G.VIEW_MODES.FOLLOW
                G.viewMode.object=player
                local theta=0
                local angles={}
                local speeds={}
                local lastFrameSpeeds={}
                local rs={}
                local layer=5
                for i = 1, layer, 1 do
                    table.insert(angles,math.eval('-1.57+1'))
                    local r=20*i+10
                    table.insert(rs,r)
                    table.insert(speeds,0.015/math.sinh((r+10)/100))
                    table.insert(lastFrameSpeeds,0)
                    -- local cir=Circle{x=400,y=300,direction=0,speed=0,sprite=BulletSprites.giant.red,invincible=true,lifeFrame=99999,radius=2,batch=Asset.bulletHighlightBatch}
                    -- table.insert(circles,cir)
                    local r2=r
                end
                local innerR=0
                Event.LoopEvent{
                    period=1,
                    obj=en,
                    executeFunc=function()
                        theta=Shape.to(400,300,player.x,player.y)
                        local playerR=Shape.distance(400,300,player.x,player.y)
                        local playerLayer=1
                        for i = 1, layer-1, 1 do
                            if playerR>rs[i+1] then
                                angles[i]=angles[i]+lastFrameSpeeds[i]
                                playerLayer=playerLayer+1
                            else
                                local the2=math.modClamp(theta,angles[i],math.pi)
                                local angleRef=angles[i]
                                local speed=speeds[i]
                                -- if player.focusing then
                                --     speed=speed*player.focusFactor
                                -- end
                                angles[i]=math.clamp(the2,angles[i]-speed,angles[i]+speed)
                                lastFrameSpeeds[i]=angles[i]-angleRef
                            end
                            for r=rs[i],rs[i+1],2 do
                                local x,y=Shape.rThetaPos(400,300,r,angles[i])
                                local cir=Circle{x=x,y=y,direction=0,speed=0,sprite=BulletSprites.round[lastFrameSpeeds[i]>0 and 'red' or 'blue'],invincible=true,lifeFrame=5,radius=1,batch=Asset.bulletHighlightBatch,}
                                Event.EaseEvent{
                                    obj=cir,aimTable=cir,aimKey='sprite_transparency',aimValue=0.2,easeFrame=5
                                }
                            end
                        end
                        for i = 1, layer, 1 do
                            local r2=rs[i]
                            local color='green'
                            if i==playerLayer or i==playerLayer+1 then
                                color=lastFrameSpeeds[playerLayer]>0 and 'red' or 'blue'
                            end 
                            BulletSpawner{x=400,y=300,period=1,frame=0,lifeFrame=2,bulletNumber=math.floor(50*math.sinh(r2/100)),bulletSpeed=0,bulletLifeFrame=1,angle=0,bulletSprite=BulletSprites.bigRound[color],
                            -- fogEffect=true,fogTime=120,
                            spawnCircleRadius=r2,invincible=true
                            }
                        end
                        local innerSpeed=0.4
                        if playerR<rs[1] then
                            innerR=math.clamp(playerR,innerR-innerSpeed,math.min(rs[1],innerR+innerSpeed))
                        else
                            innerR=math.clamp(innerR-innerSpeed/4,0,rs[1])
                        end
                        BulletSpawner{x=400,y=300,period=1,frame=0,lifeFrame=2,bulletNumber=math.floor(200*math.sinh(innerR/100)),bulletSpeed=0,bulletLifeFrame=1,angle=0,bulletSprite=BulletSprites.bigRound.green,
                        -- fogEffect=true,fogTime=120,
                        spawnCircleRadius=innerR,invincible=true
                        }
                    end
                }
            end
        },
        {
            quote='?',
            user='nitori',
            spellName='Battle Machine "Autonomous Sentries"',
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
                local dis0=Shape.distance(poses[1][1],poses[1][2],poses[2][1],poses[2][2])
                player.border=PolyLine(poses)
                G.viewMode.mode=G.VIEW_MODES.FOLLOW
                G.viewMode.object=player
                local b={x=-500,y=300,period=24,frame=0,lifeFrame=6001,bulletSpeed=20,angle=0,bulletLifeFrame=990000,bulletSprite=BulletSprites.bullet.red,
                spawnBatchFunc=function(self)
                    SFX:play('enemyShot',true,self.spawnSFXVolume)
                    -- local num=math.ceil((1-en.hp/en.maxhp)*12)
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    local distance=self.dist or 0
                    self.dist=distance+3
                    local index=math.floor(self.dist/dis0)
                        local x0,y0=Shape.rThetaPos(400,300,100,math.pi/6*(index-.5))
                        local x1,y1=Shape.rThetaPos(400,300,100,math.pi/6*(index+.5))
                        local direction0=Shape.to(x0,y0,x1,y1)
                        local x,y=Shape.rThetaPos(x0,y0,self.dist%dis0,direction0)
                        local direction=Shape.to(x,y,player.x,player.y)
                        self.x,self.y=x,y
                        self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed,radius=size,index=1,batch=self.bulletBatch}
                end
                }
                local c={x=-500,y=300,period=24,frame=0,lifeFrame=6001,bulletSpeed=60,angle=0,bulletLifeFrame=990000,bulletSprite=BulletSprites.bullet.yellow,
                spawnBatchFunc=function(self)
                    SFX:play('enemyShot',true,self.spawnSFXVolume)
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    local distance=self.dist or 0
                    self.dist=distance+10
                    local index=math.floor(self.dist/dis0)
                        local x0,y0=Shape.rThetaPos(400,300,100,math.pi/6*(index-.5))
                        local x1,y1=Shape.rThetaPos(400,300,100,math.pi/6*(index+.5))
                        local direction0=Shape.to(x0,y0,x1,y1)
                        local x,y=Shape.rThetaPos(x0,y0,self.dist%dis0,direction0)
                        local direction=Shape.to(x,y,400,300)
                        self.x,self.y=x,y
                        self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed,radius=size,index=1,batch=self.bulletBatch}
                end
                }
                local d={x=-500,y=300,period=72,frame=0,lifeFrame=6001,bulletSpeed=50,angle=0,bulletLifeFrame=990000,bulletSprite=BulletSprites.bullet.blue,
                spawnBatchFunc=function(self)
                    SFX:play('enemyShot',true,self.spawnSFXVolume)
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    local distance=self.dist or 0
                    self.dist=distance+30
                    local index=math.floor(self.dist/dis0)
                    local x0,y0=Shape.rThetaPos(400,300,100,math.pi/6*(index-.5))
                    local x1,y1=Shape.rThetaPos(400,300,100,math.pi/6*(index+.5))
                    local direction0=Shape.to(x0,y0,x1,y1)
                    local x,y=Shape.rThetaPos(x0,y0,self.dist%dis0,direction0)
                    local direction=Shape.to(x,y,player.x,player.y)+math.eval('0+0.2')
                    self.x,self.y=x,y
                    local num=10
                    for i = 1, num, 1 do
                        local nx,ny=Shape.rThetaPos(x,y,(i-num/2-0.5)*2,direction+math.pi/2)
                        self:spawnBulletFunc{x=nx,y=ny,direction=direction,speed=speed,radius=size,index=i,batch=self.bulletBatch}
                    end
                end
                }
                local list={b,c,d}
                local hppRef=1
                local sentryNum=0
                local sentries={}
                Event.LoopEvent{
                    obj=b,
                    period=1,
                    executeFunc=function()
                        local hpp=en.hp/en.maxhp
                        en.x,en.y=Shape.rThetaPos(en.x,en.y,math.min((hppRef-hpp)*1000,Shape.distance(en.x,en.y,player.x,player.y)),Shape.to(en.x,en.y,player.x,player.y))
                        for key, value in pairs(sentries) do
                            value.spawnEvent.frame=value.spawnEvent.frame+(hppRef-hpp)*5000
                        end
                        hppRef=hpp
                        -- b.spawnEvent.period=6*(hpp+0.5)
                        local num=math.ceil((1-hpp)*12)
                        if sentryNum<num then
                            sentryNum=sentryNum+1
                            local choose={1,1,2,1,2,3,1,2,3,1,2,3,1,2,3}
                            table.insert(sentries,BulletSpawner(list[choose[sentryNum]]))
                            sentries[sentryNum].dist=-dis0*sentryNum
                        end
                    end
                }
            end
        },
        {
            quote='A creative use of her absolute power to destroy everything...',
            user='flandre',
            spellName='Forbidden Barrage "Border break"',
            make=function()
                G.levelRemainingFrame=5400
                Shape.removeDistance=1000
                local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=600}
                player.moveMode=player.moveModes.Natural
                player.border:remove()
                local poses={}
                local indexes={}
                for i = 1, 12, 1 do
                    local nx,ny=Shape.rThetaPos(400,300,110,math.pi/6*(i-.5))
                    table.insert(poses,{nx,ny})
                    table.insert(indexes,i)
                end
                local posesCopy=copy_table(poses)
                local indexesCopy=copy_table(indexes)
                player.border=PolyLine(poses)
                G.viewMode.mode=G.VIEW_MODES.FOLLOW
                G.viewMode.object=player
                local theta=math.eval('0+999')
                Event.LoopEvent{
                    period=500,
                    frame=470,
                    obj=en,
                    executeFunc=function()
                        local hpp=en.hp/en.maxhp
                        local removePointsNum=6+math.ceil(3*(1-hpp))
                        -- local toRemove=math.randomSample(poses,removePointsNum)
                        indexes=copy_table(indexesCopy)
                        local afterRemoveIndexes={}
                        for i=1,12 do
                            local removeIndex=math.random(1,#indexes)
                            local point=poses[indexes[removeIndex]]
                            table.remove(indexes,removeIndex)
                            if i==removePointsNum then
                                afterRemoveIndexes=copy_table(indexes)
                            end
                            Event.DelayEvent{
                                delayFrame=20*(i<=removePointsNum and i or 12),
                                executeFunc=function()
                                    BulletSpawner{x=en.x,y=en.y,period=1,frame=0,lifeFrame=2,bulletNumber=30,bulletSpeed=15,bulletLifeFrame=10000,angle=math.eval('0+999'),bulletSprite=BulletSprites.kunai.red,
                                    spawnBatchFunc=function(self)
                                        SFX:play('enemyShot',true,self.spawnSFXVolume)
                                        local num=math.eval(self.bulletNumber)
                                        local range=math.eval(self.range)
                                        local angle=Shape.to(self.x,self.y,point[1],point[2])
                                        local speed=math.eval(self.bulletSpeed)
                                        local size=math.eval(self.bulletSize)
                                        for j = 1, num, 1 do
                                            local direction=angle
                                            local x,y=self.x,self.y
                                            self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed+j*3,radius=size,index=j,batch=self.bulletBatch}
                                        end
                                        angle=theta+i*13203.216
                                        for j = 1, num, 1 do
                                            local direction=range*(j-0.5-num/2)/num+angle
                                            local x,y=self.x,self.y
                                            self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed+i*3,radius=size,index=j,batch=self.bulletBatch}
                                        end
                                    end
                                    }
                                    Event.DelayEvent{
                                        delayFrame=60,
                                        executeFunc=function()
                                            local angle=math.eval('0+999')
                                            local bulletEvent=function(cir)
                                                cir.safe=true
                                                cir.sprite_transparency=0
                                                Event.EaseEvent{
                                                    obj=cir,aimTable=cir,aimKey='sprite_transparency',aimValue=0.5,easeFrame=90,
                                                    endFunc=function ()
                                                        cir.sprite_transparency=1
                                                        cir.safe=false
                                                    end
                                                }
                                            end
                                            BulletSpawner{x=point[1],y=point[2],period=1,frame=0,lifeFrame=2,bulletNumber=20,bulletSpeed=25,bulletLifeFrame=10000,angle=angle,bulletSprite=BulletSprites.giant.red,highlight=true,bulletEvents={bulletEvent}
                                            }
                                            if hpp<0.75 then
                                                BulletSpawner{x=point[1],y=point[2],period=1,frame=0,lifeFrame=2,bulletNumber=60,bulletSpeed=18,bulletLifeFrame=10000,angle=angle,bulletSprite=BulletSprites.round.red,highlight=true,bulletEvents={bulletEvent}
                                                }
                                            end
                                            if hpp<0.45 then
                                                BulletSpawner{x=point[1],y=point[2],period=1,frame=0,lifeFrame=2,bulletNumber=60,bulletSpeed=20,bulletLifeFrame=10000,angle=angle,bulletSprite=BulletSprites.round.red,highlight=true,bulletEvents={bulletEvent}
                                                }
                                            end
                                            table.remove(poses,removeIndex)
                                            if i<=removePointsNum then
                                                player.border:remove()
                                                player.border=PolyLine(poses)
                                            end
                                            if i==12 then
                                                local ev
                                                ev=Event.LoopEvent{
                                                    period=1,
                                                    obj=en,
                                                    times=150,
                                                    executeFunc=function()
                                                        player.border:remove()
                                                        -- poses=copy_table(posesCopy)
                                                        poses={}
                                                        for i = 1, 12, 1 do
                                                            local nx,ny=Shape.rThetaPos(400,300,110+150*(1-math.sin(ev.executedTimes/150*math.pi/2)),math.pi/6*(i-.5)+theta+ev.executedTimes/150)
                                                            table.insert(poses,{nx,ny})
                                                        end
                                                        posesCopy=poses
                                                        player.border=PolyLine(poses)
                                                    end
                                                }
                                            end
                                        end
                                    }
                                end
                            }
                        end
                        
                        local newPoses={}
                        for k,v in pairs(afterRemoveIndexes) do
                            table.insert(newPoses,posesCopy[v])
                        end
                        local newPolyline=PolyLine(newPoses,false)
                        for x = -100, 900, 25 do
                            for y = 0, 1000, 25 do
                                if newPolyline:inside(x,y) then
                                    local ci=Circle{x=x,y=y,direction=0,speed=0,sprite=BulletSprites.fog.red,invincible=true,safe=true,lifeFrame=200,batch=Asset.bulletHighlightBatch,radius=1.5/(y-Shape.axisY)*500,sprite_transparency=0}
                                    Event.EaseEvent{
                                        obj=ci,
                                        aimTable=ci,
                                        aimKey='sprite_transparency',
                                        aimValue=0.1,
                                        easeFrame=200,
                                        progressFunc=function(x)return math.sin(x*math.pi) end
                                    }
                                end
                            end
                        end
                        newPolyline:remove()
                        Effect.Charge{obj=en,x=en.x,y=en.y}

                    end
                }
            end
        },
    },
    {
        {
            quote='Random jump kicks, and a powerful strike. Sometimes she almost leaves the screen.',
            user='meiling',
            spellName='Strike Sign "Drunken Fist"',
            make=function()
                Shape.removeDistance=2000
                local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=6000}
                local player=Player{x=400,y=600}
                local a
                a=BulletSpawner{x=400,y=100,period=2,frame=0,lifeFrame=10000,bulletNumber=3,bulletSpeed=30,bulletLifeFrame=10000,angle='0',range=math.pi*2,bulletSprite=BulletSprites.rice.red,bulletEvents={
                    function(cir,args,self)
                        local speedRef=cir.speed
                        if not a.flag then
                            local colors={'gray','red','purple','blue','cyan','green','yellow','orange'}
                            local ind=math.floor(math.eval('5+4'))
                            cir.sprite=BulletSprites.rice[colors[ind]]
                            cir.speed=math.random(5,5)
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
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local hpp=en.hp/en.maxhp
                        if a.flag then
                            a.angle=a.angle+math.pi/30
                            a.bulletSpeed=a.bulletSpeed+0.5
                        end
                        a.spawnEvent.frame=a.spawnEvent.frame+Shape.distance(a.x,a.y,en.x,en.y)*4
                        a.x,a.y=en.x,en.y
                        local frame=en.frame
                        if (frame+298)%300==0 then
                            local nx,ny=Shape.rThetaPos(player.x,player.y,50,math.eval('0+3.14'))
                            nx=math.clamp(nx,200,600)
                            nx=math.clamp(nx,en.x-100,en.x+100)
                            ny=math.clamp(ny,0,550)
                            ny=math.clamp(ny,en.y-100,en.y+100)
                            local co={math.eval('0+3'),math.eval('0+3'),math.eval('0+3'),math.eval('0+3')}
                            a.flag=false
                            a.bulletSpeed=30
                            a.bulletNumber=9+math.ceil((1-hpp)*6)
                            a.spawnEvent.period=20
                            SFX:play('enemyCharge')
                            local k=(hpp<0.7 and 1 or 0)+(hpp<0.4 and 1 or 0)+1
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
                                endFunc=function()
                                    SFX:play('enemyPowerfulShot',true)
                                    a.flag=true
                                    a.bulletSprite=BulletSprites.rice.blue
                                    a.spawnEvent.period=1
                                    a.bulletNumber=5
                                end
                            }
                        end
                    end
                }
            end
        },
        {
            quote='?',
            user='patchouli',
            spellName='Moon Wood Sign "Celestial Thread"',
            make=function()
                Shape.removeDistance=2500
                local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=6000}
                local player=Player{x=400,y=600}
                local centers={}
                local a
                a=BulletSpawner{x=400,y=100,period=300,frame=260,lifeFrame=10000,bulletNumber=4,bulletSpeed='30',bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.round.red,invincible=true,bulletEvents={
                    function(cir,args,self)
                        local hpp=en.hp/en.maxhp
                        local t0=en.frame
                        centers[t0]=centers[t0] or {}
                        cir.index=#centers[t0]+1
                        centers[t0][#centers[t0]+1]=cir
                        cir.speed=math.eval('150+60')
                        local theta=math.eval('0+999')
                        cir.theta=theta
                        cir.r=5
                        local aim=Shape.to(cir.x,cir.y,player.x,player.y)
                        cir.direction=math.modClamp(cir.direction,aim,math.pi)
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=20,
                            easeFrame=150,
                            progressFunc=function(x)return math.sin(x*math.pi/2) end,
                            endFunc=function()
                                Event.EaseEvent{
                                    obj=cir,
                                    aimTable=cir,
                                    aimKey='direction',
                                    aimValue=aim,
                                    easeFrame=80,
                                    progressFunc=function(x)return math.sin(x*math.pi/2) end
                                }
                            end
                        }
                        cir.sign=math.eval('0+1')>0 and 1 or -1
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                cir.theta=cir.theta+0.3*cir.sign/cir.r
                                local num=#centers[t0]
                                for i = cir.index, num, 1 do
                                    local center=centers[t0][i]
                                    if center.removed or center==cir then
                                        goto continue
                                    end
                                    local count=0
                                    local d=Shape.distance(cir.x,cir.y,center.x,center.y)
                                    d=d-(d%6)*2
                                    for r=d,0,-6 do
                                        count=count+1
                                        local angle=Shape.to(cir.x,cir.y,center.x,center.y)
                                        local x,y=Shape.rThetaPos(cir.x,cir.y,r,angle)
                                        local sprite=BulletSprites.dot.red
                                        if (hpp<0.7 and count%2==0) or (hpp<0.5) then
                                            sprite=BulletSprites.round.gray
                                        end
                                        Circle{x=x,y=y,direction=angle,speed=0,sprite=sprite,lifeFrame=0}
                                    end
                                    ::continue::
                                end
                            end
                        }
                    end
                }}
            end
        },
        {
            quote='Hyperbolic geometry distorts her rings a lot.',
            user='suwako',
            spellName='Divine Tool "Moriya\'s Elastic Ring"',
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
                a=BulletSpawner{x=400,y=300,period=30,frame=0,lifeFrame=10000,bulletNumber=48,bulletSpeed=50,bulletLifeFrame=10000,angle='0+999',spawnCircleRadius=0,range=math.pi*2,bulletSprite=BulletSprites.rice.red,bulletEvents={
                    function(cir,args,self)
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=30,
                            executeFunc=function()
                                local direction=a.angle--Shape.to(a.x,a.y,player.x,player.y)--args.index%8*math.pi/4
                                local nx,ny=Shape.rThetaPos(a.x,a.y,290,direction)
                                cir.direction=Shape.to(cir.x,cir.y,nx,ny)--+math.pi
                            end
                        }
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            times=3,
                            conditionFunc=function()return not player.border:inside(cir.x,cir.y) end,
                            executeFunc=function()
                                player.border:reflection(cir)
                            end
                        }
                    end
                }}
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local fr=a.frame%600
                        if fr==302 then
                            a.spawnEvent.period=10000
                        elseif fr==2 then
                            a.spawnEvent.period=15
                            a.spawnEvent.frame=0
                        end
                        if fr<200 then
                            a.angle=Shape.to(a.x,a.y,player.x,player.y)
                        else
                            a.angle=a.angle+math.pi/89
                        end
                    end
                }

            end
        },
        {
            quote='Her ancient memory about leaving somewhere to find mysterious ingredient.',
            user='eirin',
            spellName='Mind of God "Distant Memory"',
            make=function()
                G.levelRemainingFrame=4800
                G.levelIsTimeoutSpellcard=true
                Shape.removeDistance=2000
                local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=72000000}
                Event.EaseEvent{
                    obj=en,
                    aimTable=en,
                    aimKey='y',
                    aimValue=-50,
                    easeFrame=100
                }
                local player=Player{x=400,y=300}
                local dieEffectRef=player.dieEffect
                player.dieEffect=function(player,damage)
                    dieEffectRef(player,damage)
                    Event.EaseEvent{
                        obj=player,
                        aimTable=player,
                        aimKey='x',
                        aimValue=400,
                        easeFrame=10
                    }
                    Event.EaseEvent{
                        obj=player,
                        aimTable=player,
                        aimKey='y',
                        aimValue=300,
                        easeFrame=10
                    }
                end
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
                local safeAngle=0
                local safeWidth=math.pi/6
                local a
                a=BulletSpawner{x=400,y=300,period=1200,frame=1199,lifeFrame=10000,bulletNumber=500,bulletSpeed=0,bulletLifeFrame=1200,angle='0+999',spawnCircleRadius=0,range=math.pi*2,invincible=true,bulletSprite=BulletSprites.ellipse.blue,fogEffect=true,fogTime=20,
                spawnBatchFunc=function(self)
                    local ind=a.spawnEvent.executedTimes
                    SFX:play('enemyShot',true,self.spawnSFXVolume)
                    local num=math.eval(self.bulletNumber)
                    local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    for i = 1, num, 1 do
                        local ii=i^0.5*num^0.5
                        local direction=angle+ii*0.04*(ind%2*2-1)
                        local x,y=Shape.rThetaPos(self.x,self.y,ii/num*70+10,direction)
                        self.fogTime=math.ceil(ii/num*120)
                        self:spawnBulletFunc{x=x,y=y,direction=direction+1.5,speed=speed,radius=size,index=i,batch=self.bulletBatch,fogTime=self.fogTime}
                        if(ind>0 and i%(12-2*ind)==0) then
                            self:spawnBulletFunc{x=x,y=y,direction=direction+math.pi+ind*0.1,speed=5,radius=size,index=i,sprite=self.bulletSprite,fogTime=self.fogTime}
                        end
                        
                    end
                end,
                bulletEvents={
                    function(cir,args,self)
                        local speedRef=cir.speed
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=1000-cir.args.fogTime,
                            executeFunc=function()
                                cir.grazed=true
                                cir.damage=2
                                cir.sprite=BulletSprites.ellipse.purple
                                Event.EaseEvent{
                                    obj=cir,
                                    aimTable=cir,
                                    aimKey='speed',
                                    aimValue=Shape.distance(cir.x,cir.y,400,300),
                                    easeFrame=100,
                                    progressFunc=function(x)return math.sin(x*math.pi/2) end,
                                }
                                cir.direction=Shape.to(cir.x,cir.y,400,300)
                                Event.DelayEvent{
                                    obj=cir,
                                    delayFrame=100,
                                    executeFunc=function()
                                        -- cir.sprite=BulletSprites.ellipse.red
                                        -- cir.damage=1
                                        cir.speed=90
                                        cir.direction=cir.args.index/a.bulletNumber*(math.pi*2-safeWidth/2)+safeAngle+safeWidth/2
                                    end
                                }
                            end
                        }
                    end
                }
                }
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local fr=en.frame%1200
                        if fr==2 then
                            safeAngle=math.eval('0+3.14')
                            Circle{x=400,y=300,direction=safeAngle,speed=30,sprite=BulletSprites.fog.blue,invincible=true,safe=true,lifeFrame=2000,}
                        end
                        if fr==1190 then
                            Event.EaseEvent{
                                obj=en,
                                aimTable=player,
                                aimKey='x',
                                aimValue=400,
                                easeFrame=10
                            }
                            Event.EaseEvent{
                                obj=en,
                                aimTable=player,
                                aimKey='y',
                                aimValue=300,
                                easeFrame=10
                            }
                        end
                    end
                }

            end
        },
        {
            quote='?',
            user='shou',
            spellName='Tiger Sign "Famished Tiger"',
            make=function()
                G.levelRemainingFrame=5400
                Shape.removeDistance=10000000
                local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=500}
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
                local borderCenter=Shape{x=400,y=300,lifeFrame=99999999}
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local fr=en.frame%200
                        if fr==50 then
                            SFX:play('enemyCharge',true)
                            if not player.border:inside(en.x,en.y) then
                                local dir=Shape.to(borderCenter.x,borderCenter.y,en.x,en.y)
                                local nx,ny=Shape.rThetaPos(borderCenter.x,borderCenter.y,90,dir)
                                Event.EaseEvent{
                                    obj=en,
                                    aimTable=en,
                                    aimKey='x',
                                    aimValue=nx,
                                    easeFrame=50
                                }
                                Event.EaseEvent{
                                    obj=en,
                                    aimTable=en,
                                    aimKey='y',
                                    aimValue=ny,
                                    easeFrame=50
                                }
                            end
                        end
                        if fr==100 then --dash towards player
                            local angle=Shape.to(en.x,en.y,player.x,player.y)
                            en.direction=angle
                            local e1
                            e1=Event.LoopEvent{
                                obj=en,
                                period=1,
                                times=300,
                                conditionFunc=function()
                                    local inRange=player.border:inside(en.x,en.y)
                                    if not inRange then
                                        local speedRef=en.speed*1.1
                                        local direction=Shape.to(borderCenter.x,borderCenter.y,en.x,en.y)
                                        e1:remove()
                                        en.speed=0
                                        local e2
                                        e2=Event.LoopEvent{
                                            obj=en,
                                            period=1,
                                            times=100,
                                            executeFunc=function()-- change border as been crashed into
                                                local times=e2.executedTimes
                                                borderCenter.direction=direction
                                                borderCenter.speed=speedRef*(1-times/99)
                                                for i = 1, 12, 1 do
                                                    player.border.points[i].x,player.border.points[i].y=Shape.rThetaPos(borderCenter.x,borderCenter.y,100,math.pi/6*(i-.5))
                                                end
                                            end
                                        }
                                        SFX:play('enemyPowerfulShot',true)
                                        local hpp=en.hp/en.maxhp
                                        local num=hpp<0.4 and 150 or 90
                                        BulletSpawner{x=en.x,y=en.y,period=1,frame=0,lifeFrame=2,bulletNumber=num,bulletSpeed=70,bulletLifeFrame=500,angle=angle,bulletSprite=BulletSprites.scale.yellow,highlight=true,bulletEvents={
                                            function(cir,args,self)
                                                cir.x=cir.x*math.eval('1+0.04')
                                                cir.y=cir.y*math.eval('1+0.04')
                                                local rand=math.eval('0+1')
                                                local dang=rand^3*math.pi*(hpp<0.4 and 4 or 2)
                                                cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)+dang
                                                cir.speed=40+math.cos(rand*3)*30+math.eval('0+8')
                                                if math.abs(dang)>math.pi*2 then
                                                    cir.sprite=BulletSprites.scale.blue
                                                    cir.speed=cir.speed+70
                                                end
                                            end
                                        }
                                        }
                                        if hpp<0.7 then
                                            BulletSpawner{x=en.x,y=en.y,period=1,frame=0,lifeFrame=1,bulletNumber=90,bulletSpeed=70,bulletLifeFrame=500,angle=angle,bulletSprite=BulletSprites.scale.red,highlight=true,bulletEvents={
                                                function(cir,args,self)
                                                    local index=args.index
                                                    cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)+(0.3*index/90+0.1*math.sin(index/3))*(index%2*2-1)
                                                    cir.speed=20+index
                                                end
                                            }
                                            }
                                        end
                                    end
                                    return inRange
                                end,
                                executeFunc=function()
                                    local dr=e1.executedTimes
                                    en.speed=150*(1-dr/299)*math.min(1,dr*0.1)
                                end
                            }
                            en.e1=e1
                        end
                    end
                }

            end
        },
        {
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
                G.viewMode.mode=G.VIEW_MODES.NORMAL
                -- show spellcard name
                do
                    if not value2.spellName then
                        value2.spellName=''
                    end
                    local name=Localize{'levelData',index,index2,'spellName'}
                    local txt=Text{x=200,y=500,width=400,height=100,bordered=false,text=name,fontSize=18,color={1,1,1,0},align='center'}
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
                -- show user name
                do
                    local name=Localize{'levelData','names',value2.user}
                    local fontSize=72
                    if string.len(name)>20 then
                        fontSize=math.floor(72*20/string.len(name))
                    end
                    local name=Text{x=300,y=200,width=500,height=100,bordered=false,text=name,fontSize=fontSize-8,color={1,1,1,0},align='center',anchor='c',lifeFrame=60}
                    Event.EaseEvent{
                        obj=name,
                        easeFrame=60,
                        aimTable=name,
                        aimKey='x',
                        aimValue=500,
                        easeMode='hard',
                        progressFunc=function(x)return (2*x-1)^3*0.5+0.5 end
                    }
                    Event.EaseEvent{
                        obj=name,
                        easeFrame=60,
                        aimTable=name,
                        aimKey='fontSize',
                        aimValue=fontSize,
                        progressFunc=function(x)return math.sin(x*math.pi) end
                    }
                    Event.EaseEvent{
                        obj=name,
                        easeFrame=60,
                        aimTable=name.color,
                        aimKey=4,
                        aimValue=0.5,
                        progressFunc=function(x)return math.sin(x*math.pi) end
                    }
                end
                ref()
                -- show timeout spellcard text
                do
                    if G.levelIsTimeoutSpellcard then
                        local txt=Text{x=300,y=400,width=600,height=100,bordered=false,text=Localize{'ui','timeout'},fontSize=72,color={1,1,1,0},align='center',anchor='c',lifeFrame=60}
                        Event.EaseEvent{
                            obj=txt,
                            easeFrame=60,
                            aimTable=txt,
                            aimKey='x',
                            aimValue=500,
                            easeMode='hard',
                            progressFunc=function(x)return (2*x-1)^3*0.5+0.5 end
                        }
                        Event.EaseEvent{
                            obj=txt,
                            easeFrame=60,
                            aimTable=txt.color,
                            aimKey=4,
                            aimValue=0.3,
                            progressFunc=function(x)return math.sin(x*math.pi) end
                        }
                    end
                end

                -- apply upgrades
                local options=G.UIDEF.UPGRADES.options
                for k,value in ipairs(options) do
                    for i,option in pairs(value) do
                        if option.upgrade and G.save.upgrades[i][k] and G.save.upgrades[i][k].bought==true then
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