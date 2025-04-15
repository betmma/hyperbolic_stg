BulletSpawner=require"bulletSpawner"
local backgroundPattern = require "backgroundPattern"

-- currently levels are randomly stored, and need to be reorganized after majority of levels are done. The draft of final arrangement is as follows:
-- main idea: similar to original game, characters are sorted by the stage they appear in the original game. Like fan-game "Shatter All Spell Card", it's a good idea to add secret levels and unlock secret upgrades.
-- level 1: doremy's regular attack first (introduction), then doremy's spell, then protagonists like reimu, marisa, sakuya, sanae to give useful information. (yuugi should be moved to later levels)
-- level 2-4: characters from stage 1-3. 
-- level 5: introduce the follow view and broader move area. Let doremy introduce is fine, or maybe seiga (霍 青娥).
-- level 6-9: characters from stage 4-EX.
-- level 10: introduce boardless levels? I really wonder if this leads to interesting gameplay.
-- (an idea for boardless level: player needs to go far away then return to initial place. Without compass it's very difficult in hyperbolic world.)
-- level EX: protagonists' spells again.
-- some other idea: pun on the game name "soukyokuiki", where "soukyo" could be "壮挙", "soukyoku" could be "箏曲""双極", "kyokuiki" could be "局域". "箏曲域" can cue the mastermind is related to koto (yatsuhashi tsukumo), and "双極" relates to tsukumo sisters. nice idea. "奏曲""葬曲" are also good.
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
                                    afterFunc=function(self)
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
                                --     afterFunc=function(self)
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
                                        afterFunc=function()
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
                                cir.spriteTransparency=0.6
                                Event.EaseEvent{
                                    obj=cir,
                                    aimTable=cir,
                                    aimKey='spriteTransparency',
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
                                progressFunc=Event.sineIOProgressFunc
                            }
                            Event.EaseEvent{
                                obj=en,
                                aimTable=en,
                                aimKey='y',
                                aimValue=center.y,
                                easeFrame=60,
                                progressFunc=Event.sineIOProgressFunc
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
                                    aimKey='spriteTransparency',
                                    aimValue=0,
                                    -- period=60,
                                    afterFunc=function()
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
                Shape.removeDistance=1000
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
                                    end,easeFrame=100,easeMode='hard',progressFunc=Event.sineIOProgressFunc
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
                                    obj=player,aimTable=player,aimKey='naturalDirectionSpecial',aimValue=delta+player.naturalDirectionSpecial,easeFrame=100,progressFunc=Event.sineIOProgressFunc
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
                                    obj=cir,aimTable=cir,aimKey='spriteTransparency',aimValue=0.2,easeFrame=5
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
                                                cir.spriteTransparency=0
                                                Event.EaseEvent{
                                                    obj=cir,aimTable=cir,aimKey='spriteTransparency',aimValue=0.5,easeFrame=90,
                                                    afterFunc=function ()
                                                        cir.spriteTransparency=1
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
                                    local ci=Circle{x=x,y=y,direction=0,speed=0,sprite=BulletSprites.fog.red,invincible=true,safe=true,lifeFrame=200,batch=Asset.bulletHighlightBatch,radius=1.5/(y-Shape.axisY)*500,spriteTransparency=0}
                                    Event.EaseEvent{
                                        obj=ci,
                                        aimTable=ci,
                                        aimKey='spriteTransparency',
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
                                afterFunc=function()
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
                            progressFunc=Event.sineOProgressFunc,
                            afterFunc=function()
                                Event.EaseEvent{
                                    obj=cir,
                                    aimTable=cir,
                                    aimKey='direction',
                                    aimValue=aim,
                                    easeFrame=80,
                                    progressFunc=Event.sineOProgressFunc
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
                local hitEffectRef=player.hitEffect
                player.hitEffect=function(player,damage)
                    hitEffectRef(player,damage)
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
                                    progressFunc=Event.sineOProgressFunc,
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
        {
            quote='?',
            user='alice',
            spellName='Magic Sign "Explosive Marionette"',
            make=function()
                G.levelRemainingFrame=5400
                Shape.removeDistance=1000
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
                a=BulletSpawner{x=400,y=300,period=900,frame=840,lifeFrame=300000,bulletNumber=18,bulletSpeed=45,bulletLifeFrame=300,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.giant.red,bulletEvents={
                    function(cir,args,self)
                        cir:changeSpriteColor()
                        local index=args.index
                        local m0=index%3
                        local t=(m0*50)+50
                        Event.EaseEvent{
                            obj=cir,aimTable=cir,aimKey='speed',aimValue=0,easeFrame=t,progressFunc=function(x)return math.max(0,2*x-1)end
                        }
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=t,
                            executeFunc=function()
                                cir:remove()
                                BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=10,bulletSpeed=40,bulletLifeFrame=150+index*2,angle=math.eval('0+999'),bulletSprite=BulletSprites.bigRound.yellow,highlight=true,bulletEvents={
                                    function(cir,args,self)
                                        cir:changeSpriteColor()
                                        local index2=args.index
                                        local t2=60+index2*5+index*2
                                        Event.EaseEvent{
                                            obj=cir,aimTable=cir,aimKey='speed',aimValue=0,easeFrame=index2%2==1 and 60 or 30
                                        }
                                        Event.DelayEvent{
                                            obj=cir,
                                            delayFrame=t2,
                                            executeFunc=function()
                                                cir:remove()
                                                local angle=m0~=0 and '0+999' or Shape.to(cir.x,cir.y,player.x,player.y)+math.pi/10*3+math.eval('0+0.1')--
                                                BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=10,bulletSpeed=index%4>=2 and 16 or 12,bulletLifeFrame=1800,angle=angle,bulletSprite=BulletSprites.scale.yellow,highlight=true,bulletEvents={
                                                    function(cir,args,self)
                                                        cir:changeSpriteColor()
                                                        if m0==0 then
                                                            cir.speed=cir.speed*4
                                                        end
                                                        if args.index%2==1 then
                                                            cir.speed=cir.speed/2
                                                        end
                                                    end
                                                }
                                                }
                                            end
                                        }
                                    end
                                }
                                }
                            end
                        }
                    end
                }}
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local hpp=en.hp/en.maxhp
                        a.spawnEvent.period=450*(1+hpp)
                    end
                }
            end
        },
        {
            quote='?',
            user='patchouli',
            spellName='Sun Metal Sign "Solar Alloy"',
            make=function()
                G.levelRemainingFrame=5400
                Shape.removeDistance=20000000
                local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
                local player=Player{x=400,y=1000}
                player.moveMode=Player.moveModes.Natural
                player.border:remove()
                local poses={}
                for i = 1, 12, 1 do
                    local nx,ny=Shape.rThetaPos(400,300,150,math.pi/6*(i-.5))
                    table.insert(poses,{nx,ny})
                end
                player.border=PolyLine(poses)
                G.viewMode.mode=G.VIEW_MODES.FOLLOW
                G.viewMode.object=player
                local innerPoints={}
                en.outerR=150
                local a,aa,b,c
                a={x=400,y=300,direction=0,lifeFrame=15,frequency=1,speed=0,sprite=Asset.bulletSprites.laser.yellow,invincible=true,laserEvents={
                    function(laser)
                        Event.LoopEvent{
                            obj=laser,
                            period=1,
                            executeFunc=function()
                                laser.args.direction=laser.args.direction+math.pi/(laser.lifeFrame-2)*2
                            end
                        }
                    end
                },
                bulletEvents={
                    function(cir,args,self)
                        local dir0=cir.direction
                        table.insert(innerPoints,cir)
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                local the=dir0+en.frame/800
                                cir.direction=the+math.pi/3
                                local r
                                if en.frame<20 then
                                    r=0
                                elseif en.frame<140 then
                                    r=120*(1-(1-(en.frame-20)/120)^4)
                                else
                                    r=math.sin((en.frame-140)/100*math.pi/2)*25+120
                                end
                                cir.r,cir.theta=r,the
                                cir.x,cir.y=Shape.rThetaPos(en.x,en.y,r,the)
                            end
                        }
                    end
                }
                }
                aa=copy_table(a)
                b=Laser(a)
                -- aa.enableWarningAndFading=true
                -- aa.warningFrame=1
                aa.bulletEvents[1]=function(cir,args,self)
                    local dir0=cir.direction
                    Event.LoopEvent{
                        obj=cir,
                        period=1,
                        executeFunc=function()
                            local the=dir0+en.frame/800
                            cir.direction=the+math.pi/3
                            local r
                            if en.frame<140 then
                                r=140+en.outerR-en.frame
                            else
                                r=math.sin((en.frame-140)/100*math.pi/2)*25+en.outerR
                            end
                            cir.x,cir.y=Shape.rThetaPos(en.x,en.y,r,the)
                        end
                    }
                end
                c=Laser(aa)
                local border
                local e
                e=BulletSpawner{x=400,y=300,period=30,frame=-100,lifeFrame=10000,bulletNumber=48,bulletSpeed=150,bulletLifeFrame=1000,angle='0+999',range=math.pi*2,highlight=true,bulletSprite=BulletSprites.giant.red,bulletEvents={
                    function(cir,args,self)
                        cir.spriteTransparency=0.1
                        cir.safe=true
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            times=1,
                            conditionFunc=function()
                                return not border:inside(cir.x,cir.y)
                                end,
                            executeFunc=function()
                                Event.EaseEvent{
                                    obj=cir,
                                    aimTable=cir,
                                    aimKey='spriteTransparency',
                                    aimValue=1,
                                    easeFrame=10
                                }
                                cir.safe=false
                                cir:changeSprite(BulletSprites.bill.red)
                                cir.speed=math.eval('7+2')
                                if en.hp<en.maxhp*0.7 then
                                    cir:changeSprite(BulletSprites.bill.orange)
                                    cir.direction=cir.direction+0.3*(math.eval('0+1')>0 and 1 or -1)
                                end
                            end
                        }
                    end
                }}
                local f=BulletSpawner{x=400,y=300,period=30000,frame=0,lifeFrame=10000,bulletNumber=80,bulletSpeed=15,bulletLifeFrame=1000,angle='player',range=math.pi/3,bulletSprite=BulletSprites.bill.yellow,bulletEvents={
                    function(cir,args,self)
                    end
                }}
                f.set=false
                local outerRdecreased=false
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        if en.frame<20 then return end
                        local poses={}
                        for i=1,#innerPoints-1,1 do
                            local cir=innerPoints[i]
                            local x,y=Shape.rThetaPos(400,300,cir.r-2,cir.theta)
                            table.insert(poses,{x,y})
                        end
                        if border then
                            border:remove()
                        end
                        border=PolyLine(poses,false)
                        if border:inside(player.x,player.y) and en.frame%1==0 then
                            Circle{x=en.x,y=en.y,direction=Shape.to(400,300,player.x,player.y)+math.eval('0+0.5'),speed=100,sprite=BulletSprites.giant.yellow,invincible=true,lifeFrame=2000}
                        end
                        local hpp=en.hp/en.maxhp
                        if hpp<0.5 and not f.set then
                            f.set=true
                            f.spawnEvent.period=300
                            f.spawnEvent.frame=290
                        end
                        if hpp<0.3 and not outerRdecreased then
                            SFX:play('enemyCharge',true)
                            Event.EaseEvent{
                                obj=en,
                                aimTable=en,
                                aimKey='outerR',
                                aimValue=140,
                                easeFrame=100
                            }
                            outerRdecreased=true
                        end
                    end
                }
            end
        },
    },
    {
        {
            quote='?',
            user='utsuho',
            spellName='Explosion Sign "Critical Mass"', -- a pun on nuclear critical mass and the "critical" bullet player needs to identify
            make=function()
                G.levelRemainingFrame=7200
                Shape.removeDistance=2000
                local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200,hpSegments={0.5}}
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
                local function q(cir)
                    cir.speed=math.eval('50+50')
                    cir.x=cir.x+math.eval('0+20')
                    cir.y=cir.y+math.eval('0+20')
                    Event.EaseEvent{
                        obj=cir,
                        aimTable=cir,
                        aimKey='speed',
                        aimValue=20,
                        easeFrame=120
                    }
                    Event.LoopEvent{
                        obj=cir,
                        period=1,
                        conditionFunc=function()return not player.border:inside(cir.x,cir.y) end,
                        executeFunc=function()
                            player.border:reflection(cir)
                        end
                    }
                end
                local a
                local t0=480
                a=BulletSpawner{x=400,y=300,period=600,frame=540,lifeFrame=10000,bulletNumber=40,bulletSpeed=30,bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bigRound.red,bulletEvents={
                    function(cir,args,self)
                        q(cir)
                        if args.index==1 then
                            BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=1,bulletNumber=20,bulletSpeed=20,bulletLifeFrame=10000,angle='0+999',bulletSprite=BulletSprites.dot.red,bulletEvents={
                                function(cir,args,self)
                                    q(cir)
                                end}}
                            cir.invincible=true
                            local count=0
                            Event.LoopEvent{
                                obj=cir,
                                period=1,
                                times=t0,
                                executeFunc=function()
                                    local t=cir.frame
                                    if t<t0-200 and t%40==0 or t0-200<=t and t<t0-80 and t%20==0 or t0-80<=t and t%10==0 then
                                        if count%2==0 then
                                            cir:changeSpriteColor('blue')
                                        else
                                            cir:changeSpriteColor('red')
                                        end
                                        count=count+1
                                    end
                                end
                            }
                            Event.DelayEvent{
                                obj=cir,
                                delayFrame=t0,
                                executeFunc=function()
                                    cir:remove()
                                    local p
                                    p=BulletSpawner{x=cir.x,y=cir.y,period=2,frame=0,lifeFrame=60,bulletNumber=50,bulletSpeed=80,bulletLifeFrame=150,angle=0,spawnCircleRadius=20,bulletSprite=BulletSprites.bigRound.yellow,highlight=true,bulletEvents={
                                        function(cir,args,self)
                                            if args.index==1 then
                                                p.spawnCircleRadius=p.spawnCircleRadius+0.35
                                            end
                                            cir.spriteTransparency=0.1
                                            Event.EaseEvent{
                                                obj=cir,
                                                aimTable=cir,
                                                aimKey='spriteTransparency',
                                                aimValue=1,
                                                easeFrame=30
                                            }
                                            Event.EaseEvent{
                                                obj=cir,
                                                aimTable=cir,
                                                aimKey='speed',
                                                aimValue=150,
                                                easeFrame=30
                                            }
                                            Event.LoopEvent{
                                                obj=cir,
                                                period=1,
                                                times=30,
                                                executeFunc=function()
                                                    cir.direction=cir.direction+(args.index%2*2-1)*0.04+math.eval('0+0.04')
                                                end
                                            }
                                        end
                                    }
                                    }
                                    Effect.Shockwave{x=cir.x,y=cir.y,lifeFrame=20,radius=15,growSpeed=1.02,color='yellow'}
                                    SFX:play('enemyPowerfulShot',true)
                                end
                            }
                        end
                    end
                }}
                local hpflag=false
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local fr=(a.spawnEvent.frame-540)%600
                        if fr==120 then
                            Event.EaseEvent{
                                obj=en,
                                aimTable=en,
                                aimKey='y',
                                aimValue=30,
                                easeFrame=120,
                                progressFunc=Event.sineOProgressFunc
                            }
                        end
                        if fr==560 then
                            Event.EaseEvent{
                                obj=en,
                                aimTable=en,
                                aimKey='y',
                                aimValue=300,
                                easeFrame=120,
                                progressFunc=Event.sineOProgressFunc
                            }
                        end
                        local hpp=en.hp/en.maxhp
                        if en.frame>500 then
                            a.bulletNumber=20
                        end
                        if hpp<0.5 and not hpflag then
                            hpflag=true
                            SFX:play('enemyCharge',true)
                            Effect.Shockwave{x=en.x,y=en.y,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove={bullet=true,invincible=true}}
                            a.spawnEvent.frame=540
                        end 
                        if hpp<0.5 and fr==81 then
                            a.bulletSprite=BulletSprites.giant.red
                            t0=260
                            a:spawnBatchFunc()
                            t0=480
                            a.bulletSprite=BulletSprites.bigRound.red
                        end
                    end
                }
            end
        },
        {
            quote='?',
            user='utsuho',
            spellName='Atomic Fire "Nuclear Experiment Expansion"', 
            make=function()
                G.levelRemainingFrame=9000
                Shape.removeDistance=2000
                local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=12600,hpSegments={0.7,0.4}}
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
                local a,hpp
                local randSpeed='30+50'
                local nukes={}
                local flag1=false
                local flag2=false
                a=BulletSpawner{x=400,y=300,period=300,frame=240,lifeFrame=10000,bulletNumber=30,bulletSize=0.07,bulletSpeed=30,bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.nuke,bulletEvents={
                    function(cir,args,self)
                        local t0=a.frame
                        cir.speed=math.eval(randSpeed)
                        cir.x=cir.x+math.eval('0+20')
                        cir.y=cir.y+math.eval('0+20')
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=60,
                            easeFrame=120
                        }
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            conditionFunc=function()return not player.border:inside(cir.x,cir.y) and not flag2 end,
                            executeFunc=function()
                                player.border:reflection(cir)
                            end
                        }
                        if args.index==1 then
                            nukes[t0]={cir}
                        else
                            table.insert(nukes[t0],cir)
                        end
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=120,
                            executeFunc=function()
                                Event.EaseEvent{
                                    obj=cir,
                                    aimTable=cir,
                                    aimKey='speed',
                                    aimValue=0,
                                    easeFrame=30
                                }
                            end
                        }
                        local ratio=1.1-hpp*0.2
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=180,
                            executeFunc=function()
                                SFX:play('enemyPowerfulShot',true)
                                local e
                                e=Event.LoopEvent{
                                    obj=cir,
                                    period=1,
                                    times=30,
                                    conditionFunc=function()
                                        if cir.radius<8 then return true end
                                        local flag=true
                                        for i,v in ipairs(nukes[t0]) do
                                            if cir~=v and Shape.distance(cir.x,cir.y,v.x,v.y)*ratio<cir.radius+v.radius then
                                                flag=false
                                                e:remove()
                                                break
                                            end
                                        end
                                        return flag
                                    end,
                                    executeFunc=function()
                                        cir.radius=cir.radius+2
                                    end
                                }
                            end
                        }
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=240,
                            executeFunc=function()
                                if cir.radius>10 then 
                                    BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=math.ceil(math.sinh((cir.radius+10)/100)*50*(2-hpp)),bulletSpeed=20,bulletLifeFrame=1000,angle='0+999',bulletSprite=BulletSprites.round.blue,highlight=true}
                                end
                                Event.EaseEvent{
                                    obj=cir,
                                    aimTable=cir,
                                    aimKey='radius',
                                    aimValue=0,
                                    easeFrame=80,
                                afterFunc=function()
                                    if args.index==1 then
                                        nukes[t0]=nil
                                    end
                                    cir:remove()
                                    
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
                        hpp=en.hp/en.maxhp
                        a.spawnEvent.period=100*(2+1*hpp)
                        if hpp>0.7 then
                            a.bulletNumber=math.ceil(10*(1+2*hpp))
                        else
                            if not flag1 then
                                flag1=true
                                SFX:play('enemyCharge',true)
                                Effect.Shockwave{x=400,y=300,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove={bullet=true,invincible=true}}
                                a.bulletSize=0.2
                                randSpeed='50+20'
                                a.spawnEvent.frame=a.spawnEvent.period-60
                            end
                            a.bulletNumber=5
                        end
                        if hpp<0.4 then
                            if not flag2 then
                                flag2=true
                                SFX:play('enemyCharge',true)
                                Effect.Shockwave{x=400,y=300,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove={bullet=true,invincible=true}}
                                a.bulletSize=0.1
                                randSpeed='20+10'
                                a.spawnEvent.frame=a.spawnEvent.period-60
                                Event.EaseEvent{
                                    obj=en,
                                    aimTable=en,
                                    aimKey='y',
                                    aimValue=50,
                                    easeFrame=120,
                                    progressFunc=Event.sineOProgressFunc
                                }
                            end
                            a.spawnEvent.period=100*(0.4+5*hpp)
                        end
                        
                    end
                }
            end
        },
        {
            quote='?',
            user='aya',
            spellName='Crossroad Sign "Wind-Chasing Track"', 
            make=function()
                G.levelRemainingFrame=5400
                Shape.removeDistance=2000
                local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=8400,}
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
                -- a=BulletSpawner{x=400,y=300,period=300,frame=240,lifeFrame=10000,bulletNumber=30,bulletSpeed=30,bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bill.blue,bulletEvents={
                -- }}
                en.theta=0
                en.gap=0.5
                en.R=20
                local releaseT=0
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        -- a.x,a.y=en.x,en.y
                        local fr=en.frame%600
                        local hpp=en.hp/en.maxhp
                        if fr==30 then
                            releaseT=math.ceil(550+30*hpp)
                            SFX:play('enemyCharge',true)
                            Event.EaseEvent{
                                obj=en,
                                aimTable=en,
                                aimKey='theta',
                                aimValue=math.eval('0+3.14'),
                                easeFrame=60,
                                progressFunc=Event.sineOProgressFunc
                            }
                        end
                        if fr==300 then
                            SFX:play('enemyCharge',true)
                            Event.EaseEvent{
                                obj=en,
                                aimTable=en,
                                aimKey='R',
                                aimValue=105,
                                easeFrame=120,
                                progressFunc=Event.sineOProgressFunc
                            }
                            Event.EaseEvent{
                                obj=en,
                                aimTable=en,
                                aimKey='gap',
                                aimValue=0.05*(1+hpp),
                                easeFrame=120,
                                progressFunc=Event.sineOProgressFunc
                            }
                            local playerTheta=Shape.to(400,300,player.x,player.y)
                            local toMoveTheta=en.theta
                            if math.abs(math.modClamp(playerTheta-en.theta,0,math.pi))>math.pi/2 then
                                toMoveTheta=en.theta+math.pi
                            end
                            Event.LoopEvent{
                                obj=en,
                                period=1,
                                times=360,
                                executeFunc=function(self,times)
                                    local t
                                    if times<120 then
                                        t=math.sin(times/120*math.pi/2)
                                    else
                                        t=math.sin((times/80-0.5)*math.pi/2)
                                    end
                                    local x,y=Shape.rThetaPos(400,300,110*t,toMoveTheta)
                                    en.x,en.y=x,y
                                end
                            }
                        end
                        if fr==500 then
                            Event.EaseEvent{
                                obj=en,
                                aimTable=en,
                                aimKey='R',
                                aimValue=20,
                                easeFrame=120,
                                progressFunc=Event.sineOProgressFunc
                            }
                            Event.EaseEvent{
                                obj=en,
                                aimTable=en,
                                aimKey='gap',
                                aimValue=0.5,
                                easeFrame=120,
                                progressFunc=Event.sineOProgressFunc
                            }
                            
                        end
                        
                        local x1,y1=Shape.rThetaPos(400,300,en.R,en.theta+en.gap)
                        local x2,y2=Shape.rThetaPos(400,300,en.R,en.theta-en.gap)
                        local x3,y3=Shape.rThetaPos(400,300,en.R,en.theta+math.pi+en.gap)
                        local x4,y4=Shape.rThetaPos(400,300,en.R,en.theta+math.pi-en.gap)
                        local dis=Shape.distance(x1,y1,x4,y4)
                        local num=math.ceil(dis/2)
                        local xys={}
                        for i=0,num do
                            local disi=dis*i/num
                            local x,y=Shape.rThetaPos(x1,y1,disi,Shape.to(x1,y1,x4,y4))
                            table.insert(xys,{x,y,Shape.to(x,y,x4,y4)})
                            
                            local x,y=Shape.rThetaPos(x2,y2,disi,Shape.to(x2,y2,x3,y3))
                            table.insert(xys,{x,y,Shape.to(x,y,x3,y3)})
                        end
                        local num2=math.ceil(math.sinh(en.R/100)*40*(math.pi-en.gap*2))
                        for i=0,num2 do
                            local anglei=en.gap+(math.pi-en.gap*2)*i/num2+en.theta
                            local x,y=Shape.rThetaPos(400,300,en.R,anglei)
                            table.insert(xys,{x,y,Shape.to(x,y,400,300)})
                            x,y=Shape.rThetaPos(400,300,en.R,anglei+math.pi)
                            table.insert(xys,{x,y,Shape.to(x,y,400,300)})
                        end

                        for key, value in pairs(xys) do
                            if fr==releaseT then
                                Circle{x=value[1],y=value[2],direction=math.eval('0+999'),speed=20,sprite=BulletSprites.scale.red,lifeFrame=1000}
                            else
                                Circle{x=value[1],y=value[2],direction=value[3],speed=0,sprite=BulletSprites.scale.blue,invincible=true,lifeFrame=0}
                            end
                        end
                        -- en.theta=en.theta+0.01
                    end
                }
                
            end
        },
        {
            quote='?',
            user='aya',
            spellName='Wind God "Frenzied Wind"', 
            make=function()
                G.backgroundPattern:remove()
                G.backgroundPattern=backgroundPattern.FixedTesselation{toDrawNum=5}
                G.levelRemainingFrame=7200
                Shape.removeDistance=10000000
                local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=10800,hpSegments={0.7,0.4}}
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
                local dummy=Shape{x=400,y=400,lifeFrame=99999999}
                G.viewMode.object=player
                local alpha=0
                local angle=0
                local a
                a=BulletSpawner{x=400,y=300,period=5,frame=-50,lifeFrame=10000,bulletNumber=10,bulletSpeed=60,bulletLifeFrame=400,angle=math.eval('0+999'),range=math.pi*2,bulletSprite=BulletSprites.scale.blue,bulletEvents={
                    function(cir,args,self)
                        local dir0=cir.direction
                        local speed=cir.speed
                        local frame=cir.frame
                        local flag=args.index%2==1
                        local inc=cir.sprite==BulletSprites.scale.red and 1 or 0
                        local delta=0
                        local x0,y0=cir.x,cir.y
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                -- Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=0,sprite=BulletSprites.scale.blue,safe=true,lifeFrame=3,spriteTransparency=0.4}
                                local r=speed*(cir.frame-frame)/60
                                cir.x,cir.y=Shape.rThetaPos(x0,y0,r,dir0+delta)
                                cir.direction=dir0+delta
                                delta=delta+inc*cir.frame/r/960*(flag and 1 or -1)
                            end
                        }
                    end

                }
                }

                local borderCenter=Shape{x=400,y=300,lifeFrame=99999999}
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        a.angle=a.angle+0.008*math.sign(math.sin((en.frame-50)/800*math.pi))
                        a.x,a.y=en.x,en.y
                        local hpp=en.hp/en.maxhp
                        if en.frame%90==0 and hpp<0.7 then
                            if hpp<0.4 then
                                a.bulletSprite=BulletSprites.scale.red
                                a.bulletNumber=60
                            else
                                a.bulletSprite=BulletSprites.scale.yellow
                                a.bulletNumber=30
                            end
                            a.bulletSpeed=40
                            a:spawnBatchFunc()
                            a.bulletNumber=10
                            a.bulletSpeed=60
                            a.bulletSprite=BulletSprites.scale.blue
                        -- elseif hpp>0.4 then
                        -- else
                        --     a.bulletSprite=BulletSprites.scale.yellow
                        end
                        local fr=en.frame%800
                        local times=math.floor(en.frame/800)
                        if fr==50 then
                            SFX:play('enemyCharge',true)
                        end
                        if fr==100 then 
                            SFX:play('enemyPowerfulShot',true)
                            angle=0.3*(times%2==0 and 1 or -1)+math.pi/2
                            local speed=50
                            en.direction=angle
                            borderCenter.direction=angle
                            local e2
                            local alpha1=alpha
                            e2=Event.LoopEvent{
                                obj=en,
                                period=1,
                                times=600,
                                executeFunc=function()-- change border as been crashed into
                                    local times=e2.executedTimes
                                    local ratio=times/(e2.times-1)
                                    borderCenter.speed=speed*math.sin(ratio*math.pi)
                                    en.speed=speed*math.sin(ratio*math.pi)
                                    for i = 1, 12, 1 do
                                        player.border.points[i].x,player.border.points[i].y=Shape.rThetaPos(borderCenter.x,borderCenter.y,100,math.pi/6*(i-.5)+en.direction-angle+alpha1)
                                    end
                                    if times==599 then
                                        alpha=alpha+en.direction-angle
                                    end
                                        
                                end
                            }
                        end

                        for i=1,5 do
                            local side=G.backgroundPattern.sidesTable[i]
                            side[1].x,side[1].y=en.x,en.y
                            side[2].x,side[2].y=Shape.rThetaPos(en.x,en.y,G.backgroundPattern.sideLength,math.pi/5*2*(i-1))
                        end
                    end
                }

            end
        },
        {
            quote='?',
            user='clownpiece',
            spellName='Hell Sign "Erroneous Orbit"', 
            make=function()
                G.levelRemainingFrame=7200
                Shape.removeDistance=2000
                local a
                local en
                en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    a.spawnEvent.frame=a.spawnEvent.period-60
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
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
                local modf=function(x,m) return x%(2*m)<m end
                a=BulletSpawner{x=400,y=300,period=300,frame=240,lifeFrame=10000,bulletNumber=3,bulletSpeed=20,bulletLifeFrame=300,angle='1.57+1',range=math.pi*0,spawnCircleRadius=50,spawnCircleAngle='0+999',fogEffect=true,fogTime=30,bulletSprite=BulletSprites.bigStar.red,bulletEvents={
                    function(cir,args,self)
                        local hpLevel=en:getHPLevel()
                        if args.index==1 then
                            SFX:play('enemyPowerfulShot',true)
                        end
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=299,
                            executeFunc=function()
                                BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=20,bulletSpeed=20,bulletLifeFrame=1000,angle='0+999',bulletSprite=BulletSprites.bigStar.blue,highlight=true}
                            end
                        }
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                local dir=Shape.to(cir.x,cir.y,a.x,a.y)
                                local vx,vy=cir.speed*math.cos(cir.direction),cir.speed*math.sin(cir.direction)
                                local dv
                                local dis=Shape.distance(cir.x,cir.y,a.x,a.y)
                                if hpLevel==2 then
                                    dv=1000*dis^-2
                                elseif hpLevel==1 then
                                    dv=dis/30
                                else
                                    dir=Shape.to(cir.x,cir.y,player.x,player.y)
                                    -- dis=Shape.distance(cir.x,cir.y,player.x,player.y)
                                    dv=2
                                end
                                vx=vx+dv*math.cos(dir)
                                vy=vy+dv*math.sin(dir)
                                cir.direction=math.atan2(vy,vx)
                                cir.speed=math.sqrt(vx^2+vy^2)
                                if cir.frame%1==0 then
                                    cir.count=(cir.count or 0)+1
                                    local c=Circle{x=cir.x,y=cir.y,direction=cir.direction+math.pi/2*math.mod2Sign(cir.count),speed=0,sprite=BulletSprites.star[modf(cir.count,1) and 'red' or 'blue'],lifeFrame=1000}
                                    Event.DelayEvent{
                                        obj=c,
                                        delayFrame=300-cir.frame+(modf(cir.count,2*hpLevel) and 60 or 0),
                                        executeFunc=function()
                                            Event.EaseEvent{
                                                obj=c,
                                                aimTable=c,
                                                aimKey='speed',
                                                aimValue=30,
                                                easeFrame=120
                                            }
                                        end
                                    }
                                end
                            end
                        }
                    end
                }}
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()

                    end
                }
                
            end
        },
        {
            quote='?',
            user='clownpiece',
            spellName='?', 
            make=function()
                G.levelRemainingFrame=7200
                Shape.removeDistance=2000
                local a,b
                local en
                en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    a.spawnEvent.frame=a.spawnEvent.period-60
                    b.spawnEvent.frame=b.spawnEvent.period-95
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
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
                local bullet=nil
                a=BulletSpawner{x=400,y=300,period=300,frame=200,lifeFrame=10000,bulletNumber=3,bulletSpeed=20,bulletLifeFrame=200,angle='1+999',range=math.pi*0,spawnCircleRadius=50,spawnCircleAngle='0+999',fogEffect=true,fogTime=30,bulletSprite=BulletSprites.bigStar.red,bulletEvents={
                    function(cir,args,self)
                        bullet=cir
                        cir.direction=math.eval('0+999')
                        local count=0
                        local hpLevel=en:getHPLevel()
                        local range=hpLevel==1 and 30 or hpLevel==2 and 15 or 5
                        if hpLevel==3 then
                            cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)
                        end
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function(self,times)
                                if times>60 and times%2==0 then
                                    local dir=Shape.to(cir.x,cir.y,player.x,player.y)
                                    local offset=math.pi/2*math.max(300-times*2,range)/240*math.mod2Sign(count)
                                    if hpLevel==3 then
                                        offset=math.pi/2*math.max(200-times,range)/240*math.mod2Sign(count)
                                    end
                                    local c=Circle{x=cir.x,y=cir.y,direction=dir+offset,speed=90,sprite=BulletSprites.bigRound.red,lifeFrame=1000}
                                    count=count+1
                                end
                            end
                        }
                    end
                }}
                local squareSize=24
                b=BulletSpawner{x=400,y=300,period=150,frame=40,lifeFrame=10000,bulletNumber=288,bulletSpeed=20,bulletLifeFrame=300,angle=0,range=math.pi*2,spawnCircleRadius=0,spawnCircleAngle='0+999',highlight=true,bulletSprite=BulletSprites.ellipse.red,bulletEvents={
                    function(cir,args,self)
                        local hpLevel=en:getHPLevel()
                        if hpLevel==2 then
                            -- local d={1,5,3,7,2,6,4,8}
                            -- cir.speed=cir.speed-d[args.index%8+1]*5
                            local ret=args.index%squareSize
                            cir.speed=cir.speed-3*math.abs(squareSize/2-ret)-(args.index%(squareSize*2)<squareSize and 3 or 0)
                            cir.direction=cir.direction-math.clamp((ret-squareSize/4),0,squareSize/2)*math.pi/b.bulletNumber*4
                        elseif hpLevel==1 then
                            local ret=args.index%squareSize
                            cir.speed=cir.speed-1.5*math.abs(squareSize/2-ret)
                            cir.direction=cir.direction-math.clamp((ret-squareSize/4),0,squareSize/2)*math.pi/b.bulletNumber*4
                        else
                            cir.speed=cir.speed*(1-math.eval('0.5+0.5')^2)
                        end
                        if hpLevel<=2 then
                            Event.LoopEvent{
                                obj=cir,
                                period=1,
                                executeFunc=function()
                                    cir.speed=cir.speed+1.6-0.5*hpLevel
                                end
                            }
                        else
                            Event.EaseEvent{
                                obj=cir,
                                aimTable=cir,
                                aimKey='speed',
                                aimValue=0,
                                easeFrame=120,
                                afterFunc=function()
                                    local dir=cir.direction
                                    for i=1,4,1 do
                                        local c=Circle{x=cir.x,y=cir.y,direction=dir+math.pi/2*(i-1),speed=30,sprite=BulletSprites.ellipse.red,lifeFrame=5000}
                                        Event.EaseEvent{
                                            obj=c,
                                            aimTable=c,
                                            aimKey='speed',
                                            aimValue=0,
                                            easeFrame=20,
                                            afterFunc=function()
                                                Event.EaseEvent{
                                                    obj=c,
                                                    aimTable=c,
                                                    aimKey='direction',
                                                    aimValue=cir.direction,
                                                    easeFrame=20,
                                                }
                                            end
                                        }
                                    end
                                    cir:remove()
                                end
                            }
                        end
                    end
                }}
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local hpLevel=en:getHPLevel()
                        if hpLevel==1 then
                            if b.spawnEvent.frame==20 then
                                local type=math.random(1,2)
                                if type==1 then
                                    b.angle=b.angle+math.pi/12
                                    b:spawnBatchFunc()
                                    Event.DelayEvent{
                                        obj=b,
                                        delayFrame=20,
                                        executeFunc=function()
                                            if en:getHPLevel()~=1 then return end
                                            b.angle=b.angle-math.pi/12
                                            b:spawnBatchFunc()
                                            b.angle=math.eval('0+999')
                                        end
                                    }
                                else
                                    local sign=math.randomSign()
                                    b.angle=b.angle-math.pi/24*0.75*sign
                                    squareSize=12
                                    b:spawnBatchFunc()
                                    Event.DelayEvent{
                                        obj=b,
                                        delayFrame=10,
                                        executeFunc=function()
                                            if en:getHPLevel()~=1 then return end
                                            squareSize=24
                                            b.angle=b.angle-math.pi/24*.75*sign
                                            b:spawnBatchFunc()
                                            b.angle=math.eval('0+999')
                                            squareSize=24
                                        end
                                    }
                                end
                            end
                        elseif hpLevel==2 then
                            squareSize=4
                            b.bulletNumber=216
                            b.angle='0+999'
                            if b.spawnEvent.frame==20 then
                                b:spawnBatchFunc()
                            end
                        else
                            a.bulletNumber=1
                            a.spawnCircleRadius=20
                            -- a.fogTime=100
                            b.bulletNumber=15
                            b.bulletSpeed=100
                            b.bulletLifeFrame=6000
                            b.bulletSprite=BulletSprites.bigRound.red
                            b.x,b.y=bullet and bullet.x or 400,bullet and bullet.y or 300
                        end
                    end
                }
                
            end
        },
        {
            quote='?',
            user='nitori',
            spellName='Water Sign "Kappa\'s Meandering Current"', 
            make=function()
                G.levelRemainingFrame=7200
                Shape.removeDistance=2000
                local a,b
                local en
                en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    -- a.spawnEvent.frame=a.spawnEvent.period-60
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
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
                local direction=0
                -- a=BulletSpawner{x=400,y=300,period=300,frame=200,lifeFrame=10000,bulletNumber=0,bulletSpeed=20,bulletLifeFrame=200,angle='1+999',range=math.pi*0,spawnCircleRadius=50,spawnCircleAngle='0+999',fogEffect=true,fogTime=30,bulletSprite=BulletSprites.bigStar.red,bulletEvents={
                --     function(cir,args,self)
                --     end
                -- }}
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local t=en.frame%200
                        if Shape.distance(en.x,en.y,player.x,player.y)<30 then
                            local direction=Shape.to(en.x,en.y,player.x,player.y) 
                            local x,y=Shape.rThetaPos(en.x,en.y,0.3,direction+math.pi)
                            en.x,en.y=x,y
                        elseif Shape.distance(en.x,en.y,player.x,player.y)>70 then
                            local direction=Shape.to(en.x,en.y,player.x,player.y) 
                            local x,y=Shape.rThetaPos(en.x,en.y,0.3,direction)
                            en.x,en.y=x,y
                        end
                        if t==60 then
                            local directionRef=direction
                            local x,y=Shape.rThetaPos(400,300,math.eval('30+20'),math.eval('0+999'))
                            while math.abs(math.modClamp(direction-directionRef,0,math.pi/2))<math.pi/4 do
                                direction=math.eval('0+999')
                            end
                            Event.LoopEvent{
                                obj=en,
                                period=1,
                                times=600,
                                executeFunc=function(self,times)
                                    if times==0 then
                                        self.x,self.y,self.direction=x,y,direction
                                        self.hpLevel=en:getHPLevel()
                                    end
                                    local r=((times-300)/300)^2*180+4*self.hpLevel
                                    for i=1,2 do
                                        local x1,y1=Shape.rThetaPos(self.x,self.y,r,math.pi*(i-0.5)+self.direction)
                                        local dir2=Shape.to(x1,y1,x,y)
                                        local j=0
                                        local fail=false
                                        while true do
                                            local jt=j+(times%30)/10*(i==1 and 1 or -1) -- note that, this divisor in modulo needs to match the below "self.hpLevel==3 and (j+i)%2==0" extra bullet part 
                                            local x2,y2=Shape.rThetaPos(x1,y1,5*jt,dir2+math.pi/2)
                                            local dir3=Shape.to(x2,y2,x1,y1)+math.pi*(jt>0 and 1 or 0)
                                            if jt==0 then
                                                dir3=dir2+math.pi/2
                                            end
                                            local ph=(jt)/5
                                            if self.hpLevel>=2 then
                                                ph=ph+times*(i==1 and 1 or -1)/(self.hpLevel==2 and 50 or 100)
                                            end
                                            local tilde=math.sin(ph)*5*(self.hpLevel+1)
                                            local x3,y3=Shape.rThetaPos(x2,y2,tilde,dir3+math.pi/2)
                                            local inside=player.border:inside(x3,y3)
                                            if inside then
                                                Circle{x=x3,y=y3,direction=dir3,lifeFrame=0,sprite=BulletSprites.round.blue}
                                                if self.hpLevel==3 and (j)%3==0 then
                                                    local jt2=j+(times%30)/5*(i==1 and 1 or -1)
                                                    local x2,y2=Shape.rThetaPos(x1,y1,5*jt2,dir2+math.pi/2)
                                                    local dir3=Shape.to(x2,y2,x1,y1)+math.pi*(jt2>0 and 1 or 0)
                                                    if jt2==0 then
                                                        dir3=dir2+math.pi/2
                                                    end
                                                    local ph=(jt2)/5+times*(i==1 and 1 or -1)/100
                                                    local tilde=math.sin(ph)*5*(self.hpLevel+1)-6
                                                    local x3,y3=Shape.rThetaPos(x2,y2,tilde,dir3+math.pi/2)
                                                    Circle{x=x3,y=y3,direction=dir3,lifeFrame=0,sprite=BulletSprites.round.blue}
                                                    -- local x4,y4
                                                    -- x4,y4=Shape.rThetaPos(x2,y2,tilde-4,dir3+math.pi/2)
                                                    -- Circle{x=x4,y=y4,direction=dir3,lifeFrame=0,sprite=BulletSprites.round.blue}
                                                    -- x4,y4=Shape.rThetaPos(x2,y2,tilde-8,dir3+math.pi/2)
                                                    -- Circle{x=x4,y=y4,direction=dir3,lifeFrame=0,sprite=BulletSprites.round.blue}
                                                end
                                                fail=false
                                            else
                                                if fail and math.abs(j)>8 then -- means both sides are outside
                                                    break
                                                end
                                                fail=true
                                            end
                                            if j>=0 then
                                                j=-j-1
                                            else
                                                j=-j
                                            end
                                        end
                                    end
                                end
                            }
                        end
                    end
                }
                
            end
        },
        {
            quote='?',
            user='shou',
            spellName='Light Sign "Light of Purification"', 
            make=function()
                G.levelRemainingFrame=7200
                Shape.removeDistance=1500
                local a,b
                local en
                en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    a.spawnEvent.frame=a.spawnEvent.period-60
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
                local player=Player{x=400,y=600}
                player.moveMode=Player.moveModes.Natural
                player.border:remove()
                local poses={}
                for i = 1, 12, 1 do
                    local nx,ny=Shape.rThetaPos(400,300,100,math.pi/6*(i-.5))
                    table.insert(poses,{nx,ny})
                end
                player.border=PolyLine(poses)
                 poses={}
                for i = 1, 12, 1 do
                    local nx,ny=Shape.rThetaPos(400,300,102,math.pi/6*(i-.5))
                    table.insert(poses,{nx,ny})
                end
                local border=PolyLine(poses,false)
                G.viewMode.mode=G.VIEW_MODES.FOLLOW
                G.viewMode.object=player
                local direction=0
                a=BulletSpawner{x=400,y=300,period=200,frame=100,lifeFrame=10000,bulletNumber=15,bulletSpeed=40,bulletLifeFrame=1200,angle='player',range=math.pi/5,spawnSFXVolume=1,bulletSprite=BulletSprites.rice.red,bulletEvents={
                    function(cir,args,self)
                        -- if args.index%2==0 then
                        --     cir.sprite=BulletSprites.rice.blue
                        -- end
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                cir.speed=cir.speed+1
                                if not border:inside(cir.x,cir.y) then
                                    border:reflection(cir)
                                    SFX:play('enemyShot',true,0.5)
                                    local color=Asset.SpriteData[cir.sprite].color
                                    local direction
                                    if color=='red' then
                                        direction=cir.direction
                                    elseif color=='blue' then
                                        direction=Shape.to(cir.x,cir.y,player.x,player.y)
                                    end
                                    local laser=Laser{x=cir.x,y=cir.y,direction=direction,speed=30,sprite=BulletSprites.laser[color],lifeFrame=25,frequency=3,smoothFrame=3,bulletEvents={
                                        function(laser,args,self)
                                            Event.EaseEvent{
                                                obj=laser,
                                                aimTable=laser,
                                                aimKey='speed',
                                                aimValue=100,
                                                easeFrame=50
                                            }
                                        end
                                    }}
                                    local laser2=Laser{x=cir.x,y=cir.y,direction=direction,speed=300,sprite=BulletSprites.laser[color],lifeFrame=5,warningFrame=5,bulletEvents={
                                        function(laser,args,self)
                                            if laser.speed<100 then
                                                Event.EaseEvent{
                                                    obj=laser,
                                                    aimTable=laser,
                                                    aimKey='speed',
                                                    aimValue=100,
                                                    easeFrame=50
                                                }
                                            end
                                        end
                                    }}
                                    Event.EaseEvent{
                                        obj=laser2,
                                        aimTable=laser2.args,
                                        aimKey='speed',
                                        aimValue=30,
                                        easeFrame=5
                                    }
                                    cir:remove()
                                end
                            end
                        }
                    end
                }}
                local the=0
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local t=en.frame
                        if t>60 then
                            local r=80*math.sin((t-60)/120)
                            a.x,a.y=Shape.rThetaPos(400,300,r,the)
                            the=the+0.01/math.cosh(r/100)
                            en.x,en.y=a.x,a.y
                        end
                        local hpLevel=en:getHPLevel()
                        local curPercent=en:getHPPercentOfCurrentLevel()
                        if hpLevel==1 then
                            a.bulletNumber=math.ceil(15*(3-2*curPercent))
                            a.range=math.pi/75*a.bulletNumber
                        elseif hpLevel==2 then
                            a.spawnEvent.period=100
                            a.bulletSprite=BulletSprites.rice.blue
                            a.range=math.pi*2
                            a.angle='0+999'
                            a.bulletNumber=math.ceil(5*(3-2*curPercent))
                        else
                            a.spawnEvent.period=20
                            local num=a.spawnEvent.executedTimes
                            if num%2==0 then
                                a.bulletNumber=math.ceil(2*(3-2*curPercent))
                                a.angle=Shape.to(a.x,a.y,400,300)
                                a.range=math.pi*2
                                a.bulletSprite=BulletSprites.rice.blue
                            else
                                a.bulletNumber=math.ceil(2*(3-2*curPercent))
                                a.angle='player'
                                a.range=math.pi/100*a.bulletNumber
                                a.bulletSprite=BulletSprites.rice.red
                            end
                        end
                    end
                }
                
            end
        },
    },
    {
        {
            quote='?',
            user='reisen',
            spellName='Scatter Sign "Phantom Mirage"',
            make=function()
                G.levelRemainingFrame=7200
                Shape.removeDistance=150000
                local a,t
                local en
                en=Enemy{x=1000,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    a.spawnEvent.frame=0
                    t=0
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
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
                local direction=0
                t=0
                a=BulletSpawner{x=poses[1][1],y=poses[1][2],period=6000,frame=0,lifeFrame=10000,bulletNumber=50,bulletSpeed=40,bulletLifeFrame=1200,angle='0',range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.rice.red,bulletEvents={
                    function(cir,args,self)
                        -- if args.index%2==0 then
                        --     cir.sprite=BulletSprites.rice.blue
                        -- end
                        -- Event.LoopEvent{
                        --     obj=cir,
                        --     period=60,
                        --     executeFunc=function()
                        --         cir.direction=cir.direction+math.pi/2
                        --     end
                        -- }
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            conditionFunc=function()
                                return t%300==0
                            end,
                            times=10,
                            executeFunc=function()
                                -- local newCir=Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=cir.speed,sprite=BulletSprites.rice.red,lifeFrame=1000,safe=true,spriteTransparency=0.5}
                                cir.safe=true
                                cir.spriteTransparency=0.5
                                local r,the=Shape.distance(cir.x,cir.y,player.x,player.y),Shape.to(player.x,player.y,cir.x,cir.y)
                                local theI=Shape.to(cir.x,cir.y,player.x,player.y)
                                local deltaDir=cir.direction-theI
                                local rAim=r*0.8
                                local playerx,playery=player.x,player.y
                                Event.LoopEvent{
                                    obj=cir,
                                    period=1,
                                    times=100,
                                    executeFunc=function(self,times)
                                        local ratio=1-(1-times/100)^2
                                        local r2=rAim*ratio+(1-ratio)*r
                                        local the2
                                        if en:getHPLevel()<=2 then
                                            the2=the+ratio*math.pi*2*(args.index/a.bulletNumber*4%1*2-1)
                                        else
                                            the2=the+ratio*math.pi*(args.index/a.bulletNumber*2-1)
                                        end
                                        local x,y=Shape.rThetaPos(playerx,playery,r2,the2)
                                        cir.x,cir.y=x,y
                                        cir.direction=-(Shape.to(cir.x,cir.y,playerx,playery)+deltaDir)+math.pi
                                        x,y=Shape.rThetaPos(playerx,playery,r2,2*the-the2)
                                        -- newCir.x,newCir.y=x,y
                                        if times==99 then
                                            cir.safe=false
                                            cir.spriteTransparency=1
                                            cir:changeSpriteColor('blue')
                                            cir.speed=40
                                            -- newCir.safe=false
                                            -- newCir.spriteTransparency=1
                                            -- newCir:changeSpriteColor('blue')
                                            -- newCir.direction=-(Shape.to(newCir.x,newCir.y,playerx,playery)+deltaDir)+math.pi
                                        end
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
                        t=t+1
                        en.x,en.y=Shape.rThetaPos(400,300,100*en.hp/en.maxhp,math.pi/600*en.frame)
                        a.x,a.y=en.x,en.y
                        local t2=t%300
                        if t2==250 then
                            SFX:play('enemyCharge',true)
                        elseif t2==0 then
                            SFX:play('enemyPowerfulShot',true)
                        end
                        local hpLevel=en:getHPLevel()
                        if hpLevel==1 then
                            if t2==10 then
                                for i=1,10 do
                                    a.bulletSpeed=20+1*i
                                    a:spawnBatchFunc()
                                end
                            elseif t2==70 then
                                -- a.spawnEvent.frame=0
                                -- a.spawnEvent.period=10000
                                a.angle=math.eval('0+999')
                            end
                        elseif hpLevel==2 then
                            a.bulletNumber=10
                            a.spawnEvent.period=10
                            a.bulletSpeed=60
                            if t2==298 then
                                a.angle=math.eval('0+999')
                            end
                        else
                            a.bulletNumber=50
                            a.spawnEvent.period=50
                            a.bulletSpeed=40
                            a.range=math.pi*100
                            a.angle=Shape.to(a.x,a.y,player.x,player.y)+math.pi
                        end
                    end
                }
                
            end
        },
        {
            quote='?',
            user='reisen',
            spellName='Illusion Light "Void Moon"',
            make=function()
                G.levelRemainingFrame=7200
                Shape.removeDistance=1500
                local a,b,t
                local en
                en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    a.spawnEvent.frame=290
                    b.spawnEvent.frame=50
                    t=0
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
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
                local function shadeBullet(cir,args,self)
                    local hpLevel=en:getHPLevel()
                    local time=hpLevel<=2 and 50 or 80
                    Event.LoopEvent{
                        obj=cir,
                        period=1,
                        conditionFunc=function()
                            return t%300==0
                        end,
                        times=3,
                        executeFunc=function()
                            cir.safe=true
                            cir.spriteTransparency=cir.aim_transparency or 0.15
                            Event.LoopEvent{
                                obj=cir,
                                period=1,
                                times=time,
                                executeFunc=function(self,times)
                                    if times>=time-10 then
                                        cir.spriteTransparency=(times-time+10)/10+0.1
                                    end
                                    if times==time-1 then
                                        cir.safe=false
                                        cir.spriteTransparency=1
                                        cir:changeSpriteColor('blue')
                                        if not cir.aim_transparency then
                                            cir.speed=60
                                        end
                                    end
                                end
                            }
                        end
                    }
                end
                t=0
                local bullets={}
                a=BulletSpawner{x=400,y=300,period=300,frame=290,lifeFrame=10000,bulletNumber=2,bulletSpeed=80,bulletLifeFrame=1200,angle='0',range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bigRound.red,highlight=true,bulletSize=4,invincible=true,bulletEvents={
                    function (cir,args,self)
                        bullets[args.index]=cir
                        cir.direction=math.eval('0+999')
                        if args.index==2 then
                            cir.direction=bullets[1].direction+math.eval('1.57+1')
                            local bullet1=bullets[1]
                            local ratio=math.eval('0.5+0.3')
                            bullet1.ratio=ratio
                            bullet1.radius=bullet1.radius*ratio
                            cir.ratio=1-ratio
                            cir.radius=cir.radius*(1-ratio)
                        end
                        cir.speed=math.eval('60+30')
                        local t=args.index<=2 and 160 or 80
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=0,
                            easeFrame=t
                        }
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=t+80,
                            executeFunc=function()
                                if args.index==1 then
                                    local bullet2=bullets[2]
                                    local distance=Shape.distance(cir.x,cir.y,bullet2.x,bullet2.y)
                                    local ratio=cir.ratio
                                    local baseSpeed=distance/70*60 -- 300-120=180 frames from shade effect. 
                                    BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=300,bulletSpeed=baseSpeed*ratio,bulletLifeFrame=18000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bigRound.red,highlight=true,bulletEvents={shadeBullet}}
                                    BulletSpawner{x=bullet2.x,y=bullet2.y,period=1,frame=0,lifeFrame=2,bulletNumber=300,bulletSpeed=baseSpeed*(1-ratio),bulletLifeFrame=18000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bigRound.red,highlight=true,bulletEvents={shadeBullet}}
                                end
                                if args.index>2 then -- if more than 2 bullets, don't calculate the distance and just use a slow speed (though not used cuz it's so chaotic)
                                    BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=300,bulletSpeed=20,bulletLifeFrame=18000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bigRound.red,highlight=true,bulletEvents={shadeBullet}}
                                end
                                cir:remove()
                            end
                        }
                        local hpLevel=en:getHPLevel()
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                -- create a white fog effect
                                Circle{x=cir.x,y=cir.y,direction=math.pseudoRandom(cir)*math.pi*2,speed=math.pseudoRandom(cir,2)*60,sprite=BulletSprites.fog.gray,lifeFrame=30,spriteTransparency=0.23-.03*hpLevel,radius=cir.radius*hpLevel,highlight=true,safe=true}
                            end
                        }
                    end
                }}
                b=BulletSpawner{x=400,y=300,period=150,frame=50,lifeFrame=10000,bulletNumber=30,bulletSpeed=20,bulletLifeFrame=1200,angle='0+999',range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bullet.red,bulletEvents={
                    shadeBullet,
                    function(cir,args,self)
                        cir.aim_transparency=0.5 -- these bullets don't overlap much, if use 0.15 it's hard to discern
                        local hpLevel=en:getHPLevel()
                        if hpLevel==1 then
                            cir.speed=cir.speed-args.index%2*10
                        elseif hpLevel>=2 then
                            cir.speed=cir.speed-args.index%3*7
                        end
                    end
                }}
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        t=t+1
                        local t2=t%300
                        if t2==250 then
                            SFX:play('enemyCharge',true)
                        elseif t2==0 then
                            SFX:play('enemyPowerfulShot',true)
                        elseif t2==100 then
                            -- SFX:play('enemyPowerfulShot',true)
                        end
                        local hpLevel=en:getHPLevel()
                        if hpLevel==1 then
                            b.bulletNumber=40
                        elseif hpLevel==2 then
                            b.bulletNumber=60
                            -- a.bulletNumber=3
                        else
                            if t%300==150 then
                                BulletSpawner{x=400,y=300,period=1,frame=0,lifeFrame=1,bulletNumber=150,bulletSpeed=10,bulletLifeFrame=1200,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bullet.red,highlight=true,bulletEvents={shadeBullet,
                                function(cir,args,self)
                                    cir.aim_transparency=0.3
                                end}}
                            end
                        end
                    end
                }
                
            end
        },
        {
            quote='?',
            user='sakuya',
            spellName='Conjuring "The Clock that Doesn\'t Tell Time"', -- lenen reference lol
            make=function()
                G.backgroundPattern:remove()
                G.backgroundPattern=backgroundPattern.Pendulum{amplitude=0}
                Event.EaseEvent{
                    obj=G.backgroundPattern,
                    aimTable=G.backgroundPattern,
                    aimKey='colorRatio',
                    aimValue=1,
                    easeFrame=240
                }
                Event.EaseEvent{
                    obj=G.backgroundPattern,
                    aimTable=G.backgroundPattern,
                    aimKey='amplitude',
                    aimValue=0.05,
                    easeFrame=240
                }
                G.levelRemainingFrame=7200
                Shape.removeDistance=1000
                local a,b,t
                local en
                en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    a.spawnEvent.frame=a.spawnEvent.period-60
                    if hpLevel==2 then
                        Event.DelayEvent{
                            obj=en,
                            delayFrame=60,
                            executeFunc=function()
                                SFX:play('enemyCharge',true)
                                Event.EaseEvent{
                                    obj=en,
                                    aimTable=G.backgroundPattern,
                                    aimKey='amplitude',
                                    aimValue=0.1,
                                    easeFrame=600
                                }
                            end
                        }
                    end
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
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
                local period=120 -- 2 seconds, same as the period of pendulum clock
                local r=500
                local amplitude=0.05
                local bulletSpeed=30
                local dx,dy,dx2,dy2
                a=BulletSpawner{x=400,y=300,period=120,frame=60,lifeFrame=10000,bulletNumber=8,bulletSpeed=bulletSpeed,bulletLifeFrame=12000,angle=0,range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.knife.red,bulletEvents={
                    function(cir,args,self)
                        cir.safe=true
                        cir.spriteTransparency=0
                        local visibleCir=Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=cir.speed,sprite=a.bulletSprite,lifeFrame=10000,spriteTransparency=1}
                        local hpLevel=en:getHPLevel()
                        Event.LoopEvent{
                            obj=visibleCir,
                            period=1,
                            executeFunc=function(self)
                                if cir.removed then
                                    visibleCir:remove()
                                end
                            end
                        }
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function(self,times)
                                if visibleCir.removed then
                                    cir:remove()
                                end
                                local ratio=0
                                if hpLevel>1 then
                                    ratio=-(cir.y-Shape.axisY)/(300-Shape.axisY)
                                end
                                visibleCir.x,visibleCir.y=cir.x+dx2*ratio,cir.y+dy2*ratio
                                visibleCir.direction=cir.direction
                                visibleCir.speed=cir.speed
                                local t=en.frame
                                if t%(period)==0 or t%(period)==period/2 then
                                    cir.speed=cir.speed+50
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='speed',
                                        aimValue=cir.speed-50,
                                        easeFrame=period/10
                                    }
                                end
                            end
                        }
                        if visibleCir.sprite==BulletSprites.knife.red then
                            Event.LoopEvent{
                                obj=cir,
                                period=1,
                                times=1,
                                conditionFunc=function()return not player.border:inside(cir.x,cir.y) end,
                                executeFunc=function()
                                    player.border:reflection(cir)
                                    visibleCir:changeSpriteColor('blue')
                                end
                            }
                        end

                    end
                }
                }
                

                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        amplitude=G.backgroundPattern.amplitude or 0
                        local t=en.frame
                        local theta=amplitude*math.sin(-t/period*math.pi*2)
                        dx,dy=r*math.sin(theta),r*(math.cos(theta)-1)
                        G.viewOffset.x, G.viewOffset.y=dx,dy
                        local naturalDirection=player.naturalDirection
                        dx2,dy2=dx*math.cos(naturalDirection)-dy*math.sin(naturalDirection),dx*math.sin(naturalDirection)+dy*math.cos(naturalDirection)
                        if t%(period)==0 or t%(period)==period/2 then
                            SFX:play('graze',true,amplitude/0.05) -- mimic clock ticking
                        end
                        local hpLevel=en:getHPLevel()
                        if hpLevel>=2 then
                            a.bulletSprite=BulletSprites.knife.green
                        end
                        if a.spawnEvent.frame==1 then
                            local angle=a.angle
                            if hpLevel==1 then
                                Event.LoopEvent{
                                    obj=a,
                                    period=1,
                                    times=16,
                                    executeFunc=function(self,times)
                                        a.angle=angle+0.02*(times%8)
                                        a.bulletSpeed=bulletSpeed-2*math.floor(times/8)
                                        a:spawnBatchFunc()
                                    end
                                }
                            elseif hpLevel==2 then
                                Event.LoopEvent{
                                    obj=a,
                                    period=1,
                                    times=24,
                                    executeFunc=function(self,times)
                                        a.angle=angle+0.02*(times+math.floor(times/4))*math.mod2Sign(times)
                                        a.bulletSpeed=bulletSpeed-2*math.floor(times/4)
                                        a:spawnBatchFunc()
                                    end
                                }
                            else
                                Event.LoopEvent{
                                    obj=a,
                                    period=1,
                                    times=24,
                                    executeFunc=function(self,times)
                                        a.angle=angle+0.02*(times+math.floor(times/4))*(times%4==0 and 1 or -1)
                                        a.bulletSpeed=bulletSpeed-2*math.floor(times/4)
                                        a.bulletSprite=times%8==0 and BulletSprites.knife.red or BulletSprites.knife.green
                                        a:spawnBatchFunc()
                                    end
                                }

                            end
                        elseif a.spawnEvent.frame==60 then
                            a.bulletSpeed=bulletSpeed
                            a.angle=math.eval('0+999')
                        end
                    end
                }
                
            end
        },
        {
            quote='?',
            user='junko',
            spellName='"Sterile Flowers of Murderous Intent"', 
            make=function()
                G.levelRemainingFrame=7200
                Shape.removeDistance=1000
                local colors={'','blue','purple'}
                local a
                local en
                en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    if hpLevel==2 then
                        a.spawnEvent.period=200
                        a.bulletNumber=576
                        a.bulletLifeFrame=350
                        Shape.removeDistance=1000
                        a.bulletSprite=BulletSprites.scale[colors[3]]
                    end
                    if hpLevel==1 then
                        a.spawnEvent.period=150
                        a.bulletNumber=720
                        a.bulletLifeFrame=250
                        Shape.removeDistance=800
                        a.bulletSprite=BulletSprites.scale[colors[2]]
                    end
                    a.spawnEvent.frame=a.spawnEvent.period-60
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
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
                a=BulletSpawner{x=400,y=300,period=150,frame=80,lifeFrame=10000,bulletNumber=448,bulletSpeed=50,bulletLifeFrame=350,angle=math.eval('0+360'),range=math.pi*2,bulletSprite=BulletSprites.scale.yellow,bulletEvents={
                    function(cir,args,self)
                        local ns,nd=32,14
                        local hpLevel=en:getHPLevel()
                        if hpLevel==3 then
                            ns,nd=7,32
                        elseif hpLevel==2 then
                            ns,nd=16,18
                        end
                        local index=args.index
                        local mods,modd=index%ns,index%nd
                        local dspeed=math.sin(mods*math.pi/ns)*50
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=cir.speed-dspeed,
                            easeFrame=120,
                            progressFunc=function(x)return math.sin(x*math.pi) end
                        }
                        if hpLevel==2 then
                            Event.DelayEvent{
                                obj=cir,
                                delayFrame=60,
                                executeFunc=function()
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='speed',
                                        aimValue=cir.speed+100,
                                        easeFrame=150,
                                        progressFunc=Event.sineIOProgressFunc
                                    }
                                end
                            }
                        end
                        local t=150
                        if hpLevel==2 then
                            t=60
                        end
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='direction',
                            aimValue=cir.direction+(modd-(nd-1)/2)*math.pi/22,
                            easeFrame=t,
                            progressFunc=function(x)return math.sin(x*math.pi) end
                        }
                    end
                }}
                

                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local hpLevel=en:getHPLevel()
                        if a.spawnEvent.frame==a.spawnEvent.period-60 and hpLevel>=2 then
                            local sign=math.mod2Sign(a.spawnEvent.executedTimes)
                            local color=colors[hpLevel]
                            a.angle=math.eval('0+360')
                            for i=1,10 do
                                Laser{x=a.x,y=a.y,direction=math.pi*2/5*i+a.angle,speed=800,sprite=BulletSprites.laser[color],lifeFrame=140,warningFrame=60,radius=hpLevel,canRemovedByBulletRemover=true,
                                bulletEvents={
                                    function(laser,args)
                                        Event.LoopEvent{
                                            obj=laser,
                                            period=1,
                                            executeFunc=function()
                                                laser.direction=laser.direction+0.1*(i>5 and 1 or -1)
                                                laser.radius=laser.radius+0.05
                                            end
                                        }
                                    end
                                },
                                laserEvents={
                                    function(laser,args)
                                        Event.LoopEvent{
                                            obj=laser,
                                            period=1,
                                            executeFunc=function()
                                                laser.args.direction=laser.args.direction+0.005*sign
                                            end
                                        }
                                    end
                                    }
                                }
                            end
                        elseif a.spawnEvent.frame==a.spawnEvent.period-60 then
                            a.angle=math.eval('0+360')
                        end
                    end
                }
                
            end
        },
        {
            quote='?',
            user='renko',
            spellName='Capture "Fabry–Pérot Cavity"',
            make=function()
                G.levelRemainingFrame=7200
                Shape.removeDistance=1000
                local player=Player{x=400,y=600}
                local a, en, cavity
                local cavityAngle=0
                local level3Frame=0
                SFX.damageVolumeRef=SFX.audioVolumes.damage
                en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200,hpSegments={0.6,0.2},hpSegmentsFunc=function(self,hpLevel)
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    if hpLevel==1 then
                        a.bulletNumber=4
                        a.bulletLifeFrame=20
                    end
                    if hpLevel==2 then
                        local shoot=player.shootDirStraight
                        local count=0
                        player.shootDirStraight=function(self,pos,damage,sprite,theta)
                            local cir=shoot(self,pos,damage,sprite,theta)
                            cir.index=count
                            count=(count+1)%3
                            cir.reflectionMax=30
                            a.bulletEvents[1](cir)
                            return cir
                        end
                        a.bulletNumber=0
                        a.bulletLifeFrame=20
                        a.spawnEvent.period=120
                        level3Frame=en.frame
                        cavityAngle=math.modClamp(cavityAngle) -- prevent excessive spinning
                        SFX:setAudioVolume('damage',2) -- hint player if they hits the enemy
                    end
                    a.spawnEvent.frame=a.spawnEvent.period-60
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
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
                local halfAngle=math.pi*0.05
                a=BulletSpawner{x=400,y=300,period=300,frame=240,lifeFrame=10000,bulletNumber=2,bulletSpeed='260',bulletLifeFrame=30,angle=0,range=math.pi*0.9,bulletSprite=BulletSprites.laser.blue,spawnSFXVolume=1,bulletEvents={
                    function(cir)
                        local inCavity=false
                        local reflectionMax=cir.reflectionMax or 50
                        local reflectionCount=0
                        local hpLevel=en:getHPLevel()
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            executeFunc=function()
                                local isInside=cavity:inside(cir.x,cir.y)
                                if isInside then
                                    inCavity=true
                                end
                                if not isInside and inCavity then
                                    if cir.homing then
                                        cir.homing=false
                                    end
                                    if cir.safe then
                                        cir.safe=false
                                        cir.spriteTransparency=1
                                        cir.sprite=BulletSprites.rice[SpriteData[cir.sprite].color]
                                        -- cir.speed=80
                                    end
                                    reflectionCount=reflectionCount+1
                                    if reflectionCount>=reflectionMax or cir.frame>=300 then
                                        cir:remove()
                                        return
                                    end
                                    if cir.index%3~=0 then -- don't generate too many refraction bullets
                                        cavity:reflection(cir)
                                        return
                                    end
                                    local n=1.5
                                    local speedExtraCoeff=0.6
                                    if hpLevel>1 then
                                        speedExtraCoeff=speedExtraCoeff-0.01*cir.index
                                    end
                                    local refraction=Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=cir.speed/n*speedExtraCoeff,sprite=BulletSprites.crystal.blue,lifeFrame=1000}
                                    local dir0=cir.direction
                                    cavity:reflection(cir)
                                    local dir1=cir.direction
                                    -- simulate refraction
                                    local delta=math.modClamp(dir1-dir0)
                                    local theta0=math.pi/2-math.abs(delta)/2
                                    local theta1=math.asin(math.sin(theta0)/n)
                                    refraction.direction=refraction.direction+(theta1-theta0)*math.sign(delta)
                                    if cir.fromPlayer then
                                        refraction.fromPlayer=true
                                        refraction.damage=cir.damage
                                    end
                                end
                            end
                        }
                    end
                }}
                
                local function createCavity()
                    if cavity then
                        cavity:remove()
                    end
                    local poses={}
                    for i=1,4,1 do
                        local x,y=Shape.rThetaPos(400,300,70,math.pi*math.floor(i/2)-halfAngle*math.mod2Sign(i)+cavityAngle)
                        table.insert(poses,{x,y})
                    end
                    cavity=PolyLine(poses)
                end
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        local hpLevel=en:getHPLevel()
                        if en.frame==30 or hpLevel==2 and a.spawnEvent.frame==a.spawnEvent.period-55 or hpLevel==3 then
                            if hpLevel==1 then
                                SFX:play('enemyCharge',true)
                                createCavity()
                            elseif hpLevel==2 then
                                local newAngle=cavityAngle+math.eval('0+1.57')
                                local newHalfAngle=math.pi*math.eval('0.03+0.01')
                                local delta=newAngle-cavityAngle
                                local delta2=newHalfAngle-halfAngle
                                Event.LoopEvent{
                                    obj=en,
                                    period=1,
                                    times=50,
                                    executeFunc=function(self,times)
                                        cavityAngle=cavityAngle+delta/50
                                        halfAngle=halfAngle+delta2/50
                                        createCavity()
                                    end
                                }
                            else
                                local playerAngle=Shape.to(400,300,player.x,player.y)+math.pi/2+math.pi*0.2*math.sin(en.frame/200)
                                if en.frame>level3Frame+60 then
                                    cavityAngle=playerAngle
                                else
                                    cavityAngle=playerAngle*0.1+cavityAngle*0.9
                                end
                                halfAngle=halfAngle*0.99+math.pi*0.05*0.01
                                createCavity()
                                local dis=Shape.distance(player.x,player.y,400,300)
                                local x1,y1=Shape.rThetaPos(400,300,math.max(dis,30),playerAngle+math.pi*(0.5+0.1*math.sin(en.frame/150)))
                                if en.frame>level3Frame+60 then
                                    en.x,en.y=x1,y1
                                else
                                    en.x,en.y=en.x*0.9+x1*0.1,en.y*0.9+y1*0.1
                                end
                            end
                        end
                        if a.spawnEvent.frame==a.spawnEvent.period-55 and hpLevel<=2 then
                            local times=a.spawnEvent.executedTimes
                            local angle=cavityAngle+(times%2)*math.pi -- switch sides
                            local r=70
                            if hpLevel>1 then
                                r=30
                            end
                            local x1,y1=Shape.rThetaPos(400,300,r,angle)
                            local angle2=Shape.to(en.x,en.y,x1,y1)
                            local distance=Shape.distance(x1,y1,en.x,en.y)
                            local x0,y0=en.x,en.y
                            Event.LoopEvent{
                                obj=a,
                                period=1,
                                times=50,
                                executeFunc=function(self,times)
                                    en.x,en.y=Shape.rThetaPos(x0,y0,distance*((times+1)/50),angle2)
                                    if times==49 then
                                        local x3,y3=Shape.rThetaPos(400,300,70,cavityAngle)
                                        local point=Shape.nearestToLine(en.x,en.y,400,300,x3,y3)
                                        local angle3
                                        if hpLevel==1 then
                                            angle3=Shape.to(en.x,en.y,400,300)
                                        else
                                            angle3=Shape.to(en.x,en.y,point[1],point[2])
                                        end
                                        if hpLevel==1 then
                                            a.angle=''..angle3..'+0.1'
                                        else
                                            a.range=math.pi/4
                                            a.angle=''..angle3..'+0.3'
                                        end
                                    end
                                end
                            }
                        end
                        if a.spawnEvent.frame==a.spawnEvent.period-1 then
                            for i=1,5 do
                                BulletSpawner{x=en.x,y=en.y,period=1,frame=0,lifeFrame=1,bulletNumber=30,bulletSpeed=15+5*i,bulletLifeFrame=900,angle=math.eval('0+999'),range=math.pi*2,bulletSprite=BulletSprites.bill.purple,}
                            end
                        end
                        a.x,a.y=en.x,en.y
                    end
                }
                
            end,
            leave=function() -- restore damage volume
                SFX:setAudioVolume('damage',SFX.damageVolumeRef)
                SFX.damageVolumeRef=nil
            end
        },
        {
            quote='?',
            user='renko',
            spellName='Interference "Wavefront Mandala"', 
            make=function()
                G.levelRemainingFrame=5400
                G.levelIsTimeoutSpellcard=true
                Shape.removeDistance=100000
                local a,b
                local en
                en=Enemy{x=4000,y=300,mainEnemy=true,maxhp=96000000}
                en:addHPProtection(600,10)
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
                local ax,ay=Shape.rThetaPos(400,300,240,0)
                a=BulletSpawner{x=ax,y=ay,period=150000,frame=80,lifeFrame=10000,bulletNumber=48,bulletSpeed=50,bulletLifeFrame=350,angle=math.eval('0+360'),range=math.pi*2,bulletSprite=BulletSprites.scale.yellow}
                local bx,by=Shape.rThetaPos(400,300,240,math.pi)
                b=BulletSpawner{x=bx,y=by,period=150000,frame=80,lifeFrame=10000,bulletNumber=48,bulletSpeed=50,bulletLifeFrame=350,angle=math.eval('0+360'),range=math.pi*2,bulletSprite=BulletSprites.scale.yellow}
                
                local freq1,amp1,freq2,amp2=0.5,1,0.5,1
                freq2=freq2+math.eval('0+0.04')
                local time=0
                local thereshold=1
                local colorMix={0.7,0,0}
                local shader = love.graphics.newShader("shaders/waveBG.glsl")
                local bg=Shape{x=300,y=0,lifeFrame=99999}
                table.insert(G.sceneTempObjs,bg)
                bg.update=function(self)
                end
                bg.draw=function(self)
                    -- note that, in this function followModeTransform and hyperbolic rotation are applied, so it's incorrect to calculate other positions except for those sending to the shader
                    local translateX,translateY,scale=G:followModeTransform(true)
                    local function translate(x,y)
                        return x*scale+translateX,y*scale+translateY
                    end
                    local function antiTranslate(x,y)
                        return (x-translateX)/scale,(y-translateY)/scale
                    end
                    local x1,y1=translate(a.x,a.y)
                    shader:send("time", time)
                    shader:send("thershold", thereshold)
                    shader:send("colorMix", colorMix)
                    shader:send("source1", {x1,y1})
                    shader:send("frequency1", freq1)
                    shader:send("amplitude1", amp1)
                    local x2,y2=translate(b.x,b.y)
                    shader:send("source2", {x2,y2})
                    shader:send("frequency2", freq2)
                    shader:send("amplitude2", amp2)

                    shader:send("curvature", Shape.curvature)
                    shader:send("axisY", Shape.axisY)
                    love.graphics.setShader(shader)
                    local recX,recY=antiTranslate(150,0)
                    love.graphics.rectangle("fill", recX,recY, 500/scale, 600/scale)
                    love.graphics.setShader()
                end
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        time=time+1/20
                        local t=en.frame
                        if t<60 then
                        elseif t<180 then
                            thereshold=1-(t-60)/120*0.3
                        elseif t<1800 then
                            thereshold=0.7-(t-180)/(1800-180)*0.1
                        elseif t<1920 then -- rest for 2 seconds
                            if t==1800 then
                                SFX:play('enemyCharge',true)
                                Event.LoopEvent{
                                    obj=en,
                                    period=1,
                                    times=100,
                                    executeFunc=function()
                                        colorMix[1]=colorMix[1]-0.007
                                        colorMix[3]=colorMix[3]+0.007
                                    end
                                }
                            end
                            thereshold=math.min(1,0.6+(t-1800)/40*0.4)
                        elseif t<3600 then
                            thereshold=1-math.min(0.52,(t-1920)/120*0.52)+math.sin((t-1920)/90)*0.1
                        elseif t<3720 then -- rest for 2 seconds
                            if t==3600 then
                                Event.LoopEvent{
                                    obj=en,
                                    period=1,
                                    times=100,
                                    executeFunc=function()
                                        colorMix[3]=colorMix[3]-0.007
                                        colorMix[2]=colorMix[2]+0.007
                                    end
                                }
                                SFX:play('enemyCharge',true)
                            end
                            thereshold=thereshold*0.9+0.1
                        else
                            thereshold=1-math.min(0.48,(t-3720)/120*0.48)+math.sin((t-3720)/90)*0.1
                        end
                        if t<1800 then
                            a.x,a.y=Shape.rThetaPos(400,300,210*(1-t/1800)+30,0)
                            b.x,b.y=Shape.rThetaPos(400,300,200*(1-t/1800)+40,math.pi)
                        elseif t>3600 then
                            local tm=t-3600
                            a.x,a.y=Shape.rThetaPos(400,300,30,tm/230)
                            b.x,b.y=Shape.rThetaPos(400,300,40,math.pi+tm/255)
                        end
                        freq1=0.5+0.1*math.sin(t/200)

                        -- should be strictly the same as the shader
                        local dis1=Shape.distance(player.x,player.y,a.x,a.y)
                        local dis2=Shape.distance(player.x,player.y,b.x,b.y)
                        local phase1=dis1 * freq1 - time
                        local phase2=dis2 * freq2 - time
                        local sum=amp1 * math.sin(phase1) + amp2 * math.sin(phase2)
                        sum = sum / (amp1 + amp2) * 0.5 + 0.5
                        if sum>thereshold+0.01 then
                            player:hitEffect()
                        end
                    end
                }
            end
        },
        {
            quote='?',
            user='keiki',
            spellName='Polygon Shape "Facets Sculpture"', 
            make=function()
                -- hint: phase 1 stay at the center of each pentagon, phase 2 stay at the gap on side, phase 3 first stay at center, then move towards center of a side a little, phase 4 stay at the center of a side
                G.levelRemainingFrame=7200
                Shape.removeDistance=1300
                local a,b
                local en
                local backgroundPatt
                local sideNum,angleNum=4,5
                en=Enemy{x=400,y=300,mainEnemy=true,maxhp=12800,hpSegments={0.8,0.5,0.2},hpSegmentsFunc=function(self,hpLevel)
                    if hpLevel==1 then
                        angleNum=3
                        sideNum=7
                    elseif hpLevel==2 then
                        angleNum=7
                        sideNum=3
                    else
                        angleNum=4
                        sideNum=5
                    end
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    -- a.spawnEvent.frame=a.spawnEvent.period-60
                    en:addHPProtection(750,10)
                end}
                en:addHPProtection(600,10)
                en.removeDistance=9999
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

                G.backgroundPattern:remove()
                G.backgroundPattern=backgroundPattern.FollowingTesselation{sideColor={1,0.2,0.1},sideNum=sideNum,angleNum=angleNum,toDrawNum=50}
                backgroundPatt=G.backgroundPattern
                a=BulletSpawner{x=400,y=300,period=240,frame=160,lifeFrame=10000,bulletNumber=0,bulletSpeed=0,bulletLifeFrame=350,angle=0,range=math.pi*2,bulletSprite=BulletSprites.scale.yellow,spawnBatchFunc=function(self)
                    SFX:play('enemyShot',true,self.spawnSFXVolume)
                    local sides=backgroundPatt.sidesTable
                    local hpP=en:getHPPercentOfCurrentLevel()
                    hpP=math.max(0,hpP*2-1)
                    local hplevel=en:getHPLevel()
                    Event.EaseEvent{
                        obj=backgroundPatt,
                        aimTable=backgroundPatt,
                        aimKey='overallColorScale',
                        aimValue=0,
                        easeFrame=20
                    }
                    Event.DelayEvent{
                        obj=backgroundPatt,
                        delayFrame=120,
                        executeFunc=function()
                            backgroundPatt.angle=math.eval('0+999')
                            backgroundPatt.sideNum,backgroundPatt.angleNum=sideNum,angleNum
                            backgroundPatt:updateSides()
                            local centerPoint=backgroundPatt.centerPoint
                            local distance=Shape.distance(en.x,en.y,centerPoint.x,centerPoint.y)
                            local angle=Shape.to(centerPoint.x,centerPoint.y,en.x,en.y)
                            Event.LoopEvent{
                                obj=en,
                                period=1,
                                times=120,
                                executeFunc=function(self,times,maxTimes)
                                    en.x,en.y=Shape.rThetaPos(centerPoint.x,centerPoint.y,distance*math.sin((1-(times+1)/maxTimes)*math.pi/2),angle)
                                    a.x,a.y=en.x,en.y
                                end
                            }
                            Event.EaseEvent{
                                obj=backgroundPatt,
                                aimTable=backgroundPatt,
                                aimKey='overallColorScale',
                                aimValue=1,
                                easeFrame=20
                            }
                        end
                    }
                    for key,side in pairs(sides) do
                        local x1,y1,x2,y2=side[1].x,side[1].y,side[2].x,side[2].y
                        local angle1=Shape.to(x1,y1,x2,y2)
                        local center1,center2={backgroundPattern.getCenterOfPolygonWithSide(x1,y1,x2,y2,backgroundPatt.sideNum,backgroundPatt.angleNum)},{backgroundPattern.getCenterOfPolygonWithSide(x2,y2,x1,y1,backgroundPatt.sideNum,backgroundPatt.angleNum)}
                        local tab={x=x1,y=y1,period=1,frame=0,lifeFrame=1,bulletNumber=1,bulletSpeed=60,bulletLifeFrame=hplevel==2 and 60 or 120,angle=angle1,range=math.pi*2,bulletSprite=BulletSprites.crystal.purple,bulletEvents={
                            function(cir,args,self)
                                local t0=en.frame
                                local centerRef=self.center
                                Event.LoopEvent{
                                    obj=cir,
                                    period=1,
                                    executeFunc=function()
                                        if cir.frame%10==0 then
                                            local cir2=Circle{x=cir.x,y=cir.y,direction=Shape.to(cir.x,cir.y,centerRef[1],centerRef[2])+(math.pi*(hplevel-(hplevel==4 and 0.5 or 0))),speed=0,sprite=BulletSprites.crystal.red,lifeFrame=480-cir.frame,}
                                            Event.DelayEvent{
                                                obj=cir2,
                                                delayFrame=t0+120-en.frame,
                                                executeFunc=function()
                                                    cir2.speed=30
                                                    Event.EaseEvent{
                                                        obj=cir2,
                                                        aimTable=cir2,
                                                        aimKey='speed',
                                                        aimValue=30+60*(1-hpP),
                                                        easeFrame=100
                                                    }
                                                end
                                            }
                                        end
                                    end
                                }
                            end
                        }}
                        local bs=BulletSpawner(tab)
                        bs.center=center1
                        local angle2=Shape.to(x2,y2,x1,y1)
                        tab.x,tab.y,tab.angle=x2,y2,angle2
                        bs=BulletSpawner(tab)
                        bs.center=center2
                    end
                end}

            end
        },
        {
            quote='?',
            user='keiki',
            spellName='Tessellation "N-Sided Nirvana"', 
            make=function()
                G.levelRemainingFrame=7200
                Shape.removeDistance=13000000
                local a,b
                local en
                local backgroundPatt
                local sideNum,angleNum=4,5
                en=Enemy{x=400,y=300,mainEnemy=true,maxhp=10800,hpSegments={0.8,0.5,0.2},hpSegmentsFunc=function(self,hpLevel)
                    if hpLevel==1 then
                        sideNum=5
                        angleNum=4
                    elseif hpLevel==2 then
                        sideNum=7
                        angleNum=3
                    else
                        sideNum=3
                        angleNum=7
                    end
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    -- a.spawnEvent.frame=a.spawnEvent.period-60
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
                en.removeDistance=9999
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

                G.backgroundPattern:remove()
                G.backgroundPattern=backgroundPattern.FollowingTesselation{sideColor={0.9,0.7,0.18},sideNum=sideNum,angleNum=angleNum,toDrawNum=100}
                G.backgroundPattern.dontDrawFaces=true
                backgroundPatt=G.backgroundPattern
                a=BulletSpawner{x=400,y=300,period=240,frame=160,lifeFrame=10000,bulletNumber=0,bulletSpeed=0,bulletLifeFrame=350,angle=0,range=math.pi*2,bulletSprite=BulletSprites.scale.yellow,spawnBatchFunc=function(self)
                    SFX:play('enemyShot',true,self.spawnSFXVolume)
                    local sides=backgroundPatt.sidesTable
                    local hpP=en:getHPPercentOfCurrentLevel()
                    hpP=math.max(0,hpP*2-1)
                    local hplevel=en:getHPLevel()
                    Event.EaseEvent{
                        obj=backgroundPatt,
                        aimTable=backgroundPatt,
                        aimKey='overallColorScale',
                        aimValue=0,
                        easeFrame=20
                    }
                    Event.DelayEvent{
                        obj=backgroundPatt,
                        delayFrame=120,
                        executeFunc=function()
                            backgroundPatt.angle=math.eval('0+999')
                            backgroundPatt.sideNum,backgroundPatt.angleNum=sideNum,angleNum
                            backgroundPatt:updateSides()
                            local centerPoint=backgroundPatt.centerPoint
                            local distance=Shape.distance(en.x,en.y,centerPoint.x,centerPoint.y)
                            local angle=Shape.to(centerPoint.x,centerPoint.y,en.x,en.y)
                            Event.LoopEvent{
                                obj=en,
                                period=1,
                                times=120,
                                executeFunc=function(self,times,maxTimes)
                                    en.x,en.y=Shape.rThetaPos(centerPoint.x,centerPoint.y,distance*math.sin((1-(times+1)/maxTimes)*math.pi/2),angle)
                                    a.x,a.y=en.x,en.y
                                end
                            }
                            Event.EaseEvent{
                                obj=backgroundPatt,
                                aimTable=backgroundPatt,
                                aimKey='overallColorScale',
                                aimValue=1,
                                easeFrame=20
                            }
                        end
                    }
                    local deltaAngle=math.eval('0+99999')
                    for key,side in pairs(sides) do
                        local x1,y1,x2,y2=side[1].x,side[1].y,side[2].x,side[2].y
                        local angle1=Shape.to(x1,y1,x2,y2)+deltaAngle
                        local center1,center2={backgroundPattern.getCenterOfPolygonWithSide(x1,y1,x2,y2,backgroundPatt.sideNum,backgroundPatt.angleNum)},{backgroundPattern.getCenterOfPolygonWithSide(x2,y2,x1,y1,backgroundPatt.sideNum,backgroundPatt.angleNum)}
                        local tab={x=x1,y=y1,direction=angle1,lifeFrame=2,frequency=1,speed=0,sprite=Asset.bulletSprites.laser.yellow,invincible=true,meshLimit=20,laserEvents={
                            function(laser)
                            end
                        },
                        bulletEvents={
                            function(cir,args,self)
                                local dir0=cir.direction
                                local x0,y0=cir.x,cir.y
                                local r1,A=350,15
                                local t1,t2,t3=20,200,60
                                Event.LoopEvent{
                                    obj=cir,
                                    period=1,
                                    executeFunc=function()
                                        local the=dir0
                                        local r
                                        if cir.frame<t1 then
                                            r=A/t1*cir.frame
                                        elseif cir.frame<t2 then
                                            r=A+r1*(1-(1-(cir.frame-t1)/(t2-t1))^2)
                                        elseif cir.frame<t2+t3 then
                                            r=(A+r1)*((1-(cir.frame-t2)/(t3))^2)
                                        else
                                            cir:remove()
                                            return
                                        end
                                        if cir.index==1 then return end
                                        cir.r,cir.theta=r,the
                                        cir.x,cir.y=Shape.rThetaPos(x0,y0,r,the)
                                        cir.direction=Shape.to(cir.x,cir.y,x0,y0)+math.pi
                                    end
                                }
                            end
                        }
                        }
                        local tab2=copy_table(tab)
                        local toPlayerAngle=Shape.to(x1,y1,player.x,player.y)
                        if math.abs(math.modClamp(toPlayerAngle-angle1))<math.pi/2 then
                            Laser(tab)
                        end
                        local angle2=Shape.to(x2,y2,x1,y1)+deltaAngle
                        tab2.x,tab2.y,tab2.direction=x2,y2,angle2
                        toPlayerAngle=Shape.to(x2,y2,player.x,player.y)
                        if math.abs(math.modClamp(toPlayerAngle-angle2))<math.pi/2 then
                            Laser(tab2)
                        end
                    end
                end}
                
                b=BulletSpawner{x=400,y=200,period=120,frame=0,lifeFrame=10000,bulletNumber=3,bulletSpeed=20,angle='player',range=0.3,bulletSprite=BulletSprites.giant.yellow,bulletLifeFrame=1800,bulletEvents={
                    -- function(cir)
                    --     Event.LoopEvent{
                    --         obj=cir,
                    --         period=1,
                    --         executeFunc=function()
                    --             cir.speed=cir.speed+0.2
                    --         end
                    --     }
                    -- end
                }}
                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        b.x,b.y=en.x,en.y
                    end
                }

            end
        },
    },
    {
        {
            quote='?',
            user='youmu',
            spellName='Soul-Body Sword "Slash of Echoing Ghost Blade"', 
            make=function()
                G.levelRemainingFrame=7200
                Shape.removeDistance=1e100
                local a
                local en
                en=Enemy{x=400,y=400000,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    a.spawnEvent.frame=a.spawnEvent.period-60
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
                local player=Player{x=400,y=600000,noBorder=true}
                player.moveMode=Player.moveModes.Natural
                local poses={}
                for i = 1, 30, 1 do
                    local nx,ny=Shape.rThetaPos(400,600000,700,math.pi/15*(i-.5))
                    table.insert(poses,{nx,ny})
                end
                player.border=PolyLine(poses)
                G.viewMode.mode=G.VIEW_MODES.FOLLOW
                G.viewMode.object=player

                local function createLaser(x,y,direction,deltaTheta,mode)
                    mode=mode or 'spread'
                    if mode~='spread' then
                        deltaTheta=0
                    end
                    local firstLaserunit
                    local laser=Laser{x=x,y=y,direction=direction+math.pi-deltaTheta,lifeFrame=2,frequency=1,speed=80,sprite=Asset.bulletSprites.laser.gray,radius=2,invincible=true,meshLimit=100,laserEvents={
                        function(laser)
                            Event.LoopEvent{
                                obj=laser,
                                period=1,
                                executeFunc=function()
                                    if mode=='spread' then
                                        laser.args.direction=laser.args.direction+deltaTheta*2
                                    else
                                        laser.args.speed=laser.args.speed-70
                                    end
                                end
                            }
                        end
                        },
                    bulletEvents={
                        function(cir)
                            if cir.index==1 then
                                if mode=='spread' then
                                    cir.deltaOrientation=math.pi
                                end
                                firstLaserunit=cir
                            end
                            Event.DelayEvent{
                                obj=cir,
                                delayFrame=180,
                                executeFunc=function()
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='direction',
                                        aimValue=cir.direction+math.mod2Sign(cir.index)*deltaTheta/5*2,
                                        easeFrame=40
                                    }
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='speed',
                                        aimValue=-cir.speed*2,
                                        easeFrame=40
                                    }
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='radius',
                                        aimValue=10,
                                        easeFrame=240
                                    }
                                end
                            }
                            Event.DelayEvent{
                                obj=cir,
                                delayFrame=420,
                                executeFunc=function()
                                    if cir.index~=1 then
                                        local x1,y1=cir.x,cir.y
                                        local x2,y2=firstLaserunit.x,firstLaserunit.y
                                        local distance=Shape.distance(x1,y1,x2,y2)
                                        local dir=Shape.to(x1,y1,x2,y2)
                                        local dr=math.max(1,distance/20)
                                        for r=0,distance,dr do
                                            local x3,y3=Shape.rThetaPos(x1,y1,r,dir)
                                            local new=Circle{x=x3,y=y3,direction=Shape.to(x3,y3,en.x,en.y),speed=30,sprite=BulletSprites.giant.red,lifeFrame=1000}
                                            Event.EaseEvent{
                                                obj=new,
                                                aimTable=new,
                                                aimKey='speed',
                                                aimValue=100,
                                                easeFrame=400
                                            }
                                        end
                                    end
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='radius',
                                        aimValue=0,
                                        easeFrame=20
                                    }
                                end
                            }
                            Event.DelayEvent{
                                obj=cir,
                                delayFrame=440,
                                executeFunc=function()
                                    cir:remove()
                                end
                            }
                        end
                    }}
                end
                local function enemyDash(step)
                    local toPlayerAngle=Shape.to(en.x,en.y,player.x,player.y)
                    local dis=Shape.distance(en.x,en.y,player.x,player.y)
                    en.x,en.y=Shape.rThetaPos(en.x,en.y,math.min(dis,step),toPlayerAngle)
                    a.x,a.y=en.x,en.y
                end

                a=BulletSpawner{x=400,y=300000,period=350,frame=270,lifeFrame=10000,bulletNumber=2,bulletSpeed=150,bulletLifeFrame=350,angle=0,range=math.pi*2,bulletSprite=BulletSprites.giant.yellow,bulletEvents={
                    function(cir,args,self)
                        createLaser(cir.x,cir.y,cir.direction,0.35)
                    end
                }}
                local spawnBatchFuncRef=a.spawnBatchFunc
                a.spawnBatchFunc=function (self)
                    local hpLevel=en:getHPLevel()
                    if hpLevel==1 then
                        SFX:play('enemyPowerfulShot',true,self.spawnSFXVolume)
                        for i=-3,3,1 do
                            a.x,a.y=en.x,en.y
                            local angle=Shape.to(a.x,a.y,player.x,player.y)
                            a.angle=angle+i*0.1
                            spawnBatchFuncRef(a)
                        end
                        local x1,y1=Shape.rThetaPos(player.x,player.y,10,Shape.to(player.x,player.y,en.x,en.y)+math.pi)
                        createLaser(x1,y1,Shape.to(x1,y1,en.x,en.y),0.35)
                    elseif hpLevel==2 then
                        SFX:play('enemyPowerfulShot',true,self.spawnSFXVolume)
                        local timesMod=math.mod2Sign(a.spawnEvent.executedTimes)
                        if timesMod==1 then
                            for i=-3,3,1 do
                                a.x,a.y=en.x,en.y
                                local angle=Shape.to(a.x,a.y,player.x,player.y)
                                a.angle=angle+i*0.4+math.pi
                                createLaser(a.x,a.y,a.angle,0.8)
                            end
                        else
                            for i=-3,3,1 do
                                local x1,y1=Shape.rThetaPos(player.x,player.y,10,Shape.to(player.x,player.y,en.x,en.y)+math.pi+i*0.4)
                                createLaser(x1,y1,Shape.to(x1,y1,player.x,player.y),0.35)
                            end
                        end
                    elseif hpLevel==3 then
                        SFX:play('enemyPowerfulShot',true,self.spawnSFXVolume)
                        local timesMod=a.spawnEvent.executedTimes%2
                        for i=-7,7,1 do
                            a.x,a.y=en.x,en.y
                            local angle=Shape.to(a.x,a.y,player.x,player.y)
                            local x1,y1=Shape.rThetaPos(a.x,a.y,80+40*math.cos(i),i*0.2+angle)
                            createLaser(x1,y1,Shape.to(x1,y1,en.x,en.y)+i*0.4+timesMod*math.pi,0.2,(i%2==0 and 'spread' or 'normal'))
                        end

                    end
                end

                

                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        enemyDash(0.1)
                        if a.spawnEvent.frame==a.spawnEvent.period-60 then
                            SFX:play('enemyCharge',true)
                            Effect.Charge{obj=en,x=en.x,y=en.y}
                        end
                    end
                }
                
            end
        },
        {
            quote='?',
            user='youmu',
            spellName='Instant Sword "Fleeting Crossing Slash"', 
            make=function()
                -- this level is really interesting and tough. 4 key skills: memorizing arrow directions and catching the time, detecting direction with less bullets, finding way through dense bullet lines quickly and avoiding being cornered. 
                G.levelRemainingFrame=7200
                Shape.removeDistance=1e100
                local a
                local en
                en=Enemy{x=400,y=400000,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    a.spawnEvent.period=a.spawnEvent.period+30
                    a.spawnEvent.frame=a.spawnEvent.period-60
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
                local player=Player{x=400,y=600000,noBorder=true}
                player.moveMode=Player.moveModes.Natural
                local poses={}
                for i = 1, 30, 1 do
                    local nx,ny=Shape.rThetaPos(400,600000,700,math.pi/15*(i-.5))
                    table.insert(poses,{nx,ny})
                end
                player.border=PolyLine(poses)
                G.viewMode.mode=G.VIEW_MODES.FOLLOW
                G.viewMode.object=player

                local function createLaser(x,y,direction,deltaTheta,mode)
                    mode=mode or 'spread'
                    if mode~='spread' then
                        deltaTheta=0
                    end
                    local firstLaserunit
                    local laser=Laser{x=x,y=y,direction=direction+math.pi-deltaTheta,lifeFrame=3,frequency=1,speed=80,sprite=Asset.bulletSprites.laser.gray,radius=2,invincible=true,meshLimit=100,laserEvents={
                        function(laser)
                            Event.LoopEvent{
                                obj=laser,
                                period=1,
                                executeFunc=function()
                                    if mode=='spread' then
                                        laser.args.direction=laser.args.direction+deltaTheta*2
                                    else
                                        laser.args.speed=laser.args.speed-70
                                    end
                                end
                            }
                        end
                        },
                    bulletEvents={
                        function(cir)
                            if cir.index>2 then
                                cir:remove()
                                return
                            end
                            if cir.index==1 then
                                if mode=='spread' then
                                    cir.deltaOrientation=math.pi
                                end
                                firstLaserunit=cir
                            end
                            local function generate(cir,speed,colorIndex)
                                if cir.index==1 then
                                    return
                                end
                                local x1,y1=cir.x,cir.y
                                local x2,y2=firstLaserunit.x,firstLaserunit.y
                                local distance=Shape.distance(x1,y1,x2,y2)
                                local dir=Shape.to(x1,y1,x2,y2)
                                local hpLevel=en:getHPLevel()
                                local dr=math.max(1,distance/(hpLevel<3 and 20 or 15))
                                for r=0,distance,dr do
                                    local x3,y3=Shape.rThetaPos(x1,y1,r,dir)
                                    local dir2=Shape.to(x3,y3,x2,y2)
                                    if math.abs(r-distance)<Shape.EPS then
                                        dir2=Shape.to(x3,y3,x1,y1)+math.pi
                                    end
                                    local new=Circle{x=x3,y=y3,direction=dir2+math.eval('1.57+0.2'),speed=math.eval('0+10')-speed,sprite=BulletSprites.scale[Asset.colors[colorIndex or 1]],lifeFrame=1000}
                                    Event.EaseEvent{
                                        obj=new,
                                        aimTable=new,
                                        aimKey='speed',
                                        aimValue=2*speed,
                                        easeFrame=60
                                    }
                                end
                            end
                            Event.DelayEvent{
                                obj=cir,
                                delayFrame=10,
                                executeFunc=function()
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='direction',
                                        aimValue=cir.direction+math.mod2Sign(cir.index)*deltaTheta/2,
                                        easeFrame=40,
                                        afterFunc=function()
                                            Event.LoopEvent{
                                                obj=cir,
                                                period=10,
                                                times=5,
                                                executeFunc=function(self,times)
                                                    generate(cir,20+times*5,times+1)
                                                end
                                            }
                                        end
                                    }
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='speed',
                                        aimValue=-cir.speed*2,
                                        easeFrame=20
                                    }
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='radius',
                                        aimValue=4,
                                        easeFrame=80
                                    }
                                end
                            }
                            Event.DelayEvent{
                                obj=cir,
                                delayFrame=90,
                                executeFunc=function()
                                    cir.speed=0
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='radius',
                                        aimValue=0,
                                        easeFrame=20
                                    }
                                end
                            }
                            Event.DelayEvent{
                                obj=cir,
                                delayFrame=120,
                                executeFunc=function()
                                    cir:remove()
                                end
                            }
                        end
                    }}
                end
                local function enemyDash(step,pos)
                    pos=pos or {x=player.x,y=player.y}
                    local toPlayerAngle=Shape.to(en.x,en.y,pos.x,pos.y)
                    local dis=Shape.distance(en.x,en.y,pos.x,pos.y)
                    en.x,en.y=Shape.rThetaPos(en.x,en.y,math.min(dis,step),toPlayerAngle)
                    a.x,a.y=en.x,en.y
                end

                en.arrowAngle=0
                local function drawArrow()
                    local x,y=player.x,player.y
                    local angle=en.arrowAngle
                    local nx,ny
                    local size=4
                    local f=30
                    local function circle(x,y)
                        local cir=Circle{x=x,y=y,speed=0,direction=angle,sprite=BulletSprites.round.blue,lifeFrame=f,invincible=true,safe=true}
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='spriteTransparency',
                            aimValue=0,
                            easeFrame=f
                        }
                    end
                    for i=-2,10 do
                        nx,ny=Shape.rThetaPos(x,y,size*i,angle)
                        circle(nx,ny)
                    end
                    local angle2=Shape.to(nx,ny,x,y)
                    for i=1,3 do
                        local nx2,ny2=Shape.rThetaPos(nx,ny,size*i,angle2+math.pi/6)
                        circle(nx2,ny2)
                        nx2,ny2=Shape.rThetaPos(nx,ny,size*i,angle2-math.pi/6)
                        circle(nx2,ny2)
                    end
                end
                a=BulletSpawner{x=400,y=300000,period=350,frame=270,lifeFrame=10000,bulletNumber=2,bulletSpeed=150,bulletLifeFrame=350,angle=0,range=math.pi*2,bulletSprite=BulletSprites.giant.yellow,bulletEvents={
                    function(cir,args,self)
                        createLaser(cir.x,cir.y,cir.direction,0.35)
                    end
                }}
                local function oneAttack()
                    SFX:play('enemyCharge',true)
                    local newAngle=en.arrowAngle
                    while math.abs(math.modClamp(newAngle-en.arrowAngle,0,math.pi/2))<math.pi/4 do
                        newAngle=math.eval('0+999')
                    end
                    en.arrowAngle=newAngle
                    drawArrow()
                    local distance0=Shape.distance(player.x,player.y,en.x,en.y)
                    local hpLevel0=en:getHPLevel()
                    Event.DelayEvent{
                        obj=en,
                        delayFrame=45,
                        executeFunc=function()
                            en.safe=true -- prevent enemy's body killing player when dashing
                            Event.LoopEvent{
                                obj=en,
                                period=1,
                                times=10,
                                executeFunc=function(self,times,maxTimes)
                                    local distance=Shape.distance(player.x,player.y,en.x,en.y)
                                    local aimx,aimy=Shape.rThetaPos(player.x,player.y,math.max(distance0,40),newAngle+math.pi/2)
                                    local rt=maxTimes-times
                                    enemyDash(distance/rt,{x=aimx,y=aimy})
                                end
                            }
                        end
                    }
                    Event.DelayEvent{
                        obj=en,
                        delayFrame=60,
                        executeFunc=function()
                            local hpLevel=en:getHPLevel()
                            if hpLevel0~=hpLevel then -- into next phase, cancel current attack
                                return
                            end
                            SFX:play('enemyPowerfulShot',true)
                            createLaser(player.x,player.y,newAngle,1.5)
                            local xp,yp=player.x,player.y
                            local xn,yn=en.x,en.y
                            local angle=Shape.to(xp,yp,xn,yn)
                            local distance=Shape.distance(xp,yp,xn,yn)
                            local dr=math.max(2,distance/100)
                            for r=-distance,distance,dr do
                                if math.abs(r)<8 then
                                   goto continue 
                                end
                                local x3,y3=Shape.rThetaPos(xp,yp,r,angle)
                                local dir2=Shape.to(x3,y3,xp,yp)
                                local new=Circle{x=x3,y=y3,direction=dir2+math.eval('0+0.4'),speed=math.eval('-120+30'),sprite=BulletSprites.scale.orange,lifeFrame=600}
                                Event.EaseEvent{
                                    obj=new,
                                    aimTable=new,
                                    aimKey='speed',
                                    aimValue=60,
                                    easeFrame=120
                                }
                                ::continue::
                            end
                            en.x,en.y=Shape.rThetaPos(xp,yp,math.clamp(distance,20+hpLevel*20,80+hpLevel*20),angle+math.pi)
                            en.safe=false
                        end
                    }
                end
                local spawnBatchFuncRef=a.spawnBatchFunc
                a.spawnBatchFunc=function (self)
                    local hpLevel=en:getHPLevel()
                    for i=1,hpLevel+1 do
                        Event.DelayEvent{
                            obj=en,
                            delayFrame=i*20-9,
                            executeFunc=function()
                                local hpLevel2=en:getHPLevel()
                                if hpLevel2~=hpLevel then -- into next phase, cancel current attack
                                    return
                                end
                                oneAttack()
                            end
                        }
                    end
                end

                

                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        enemyDash(0.1)
                    end
                }
                
            end
        },
        {
            quote='?',
            user='youmu',
            spellName='Karmic Binding Sword "Karmic Retribution Slash"', 
            make=function()
                G.levelRemainingFrame=7200
                Shape.removeDistance=1e100
                local a
                local en
                en=Enemy{x=400,y=400000,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
                    Enemy.hpSegmentsFuncShockwave(self,hpLevel)
                    a.spawnEvent.period=a.spawnEvent.period+30
                    a.spawnEvent.frame=a.spawnEvent.period-60
                    en:addHPProtection(600,10)
                end}
                en:addHPProtection(600,10)
                local player=Player{x=400,y=600000,noBorder=true}
                player.moveMode=Player.moveModes.Natural
                local poses={}
                for i = 1, 30, 1 do
                    local nx,ny=Shape.rThetaPos(400,600000,700,math.pi/15*(i-.5))
                    table.insert(poses,{nx,ny})
                end
                player.border=PolyLine(poses)
                G.viewMode.mode=G.VIEW_MODES.FOLLOW
                G.viewMode.object=player

                local function createLaser(x,y,direction,deltaTheta,mode)
                    mode=mode or 'spread'
                    if mode~='spread' then
                        deltaTheta=0
                    end
                    local firstLaserunit
                    local laser=Laser{x=x,y=y,direction=direction+math.pi-deltaTheta,lifeFrame=3,frequency=1,speed=80,sprite=Asset.bulletSprites.laser.gray,radius=1,invincible=true,meshLimit=100,laserEvents={
                        function(laser)
                            Event.LoopEvent{
                                obj=laser,
                                period=1,
                                executeFunc=function()
                                    if mode=='spread' then
                                        laser.args.direction=laser.args.direction+deltaTheta*2
                                    else
                                        laser.args.direction=laser.args.direction+math.pi
                                    end
                                end
                            }
                        end
                        },
                    bulletEvents={
                        function(cir)
                            if cir.index>2 then
                                cir:remove()
                                return
                            end
                            if cir.index==1 then
                                    cir.deltaOrientation=math.pi
                                firstLaserunit=cir
                            end
                            local function generate(cir,speed,colorIndex)
                                if cir.index==1 then
                                    return
                                end
                                local x1,y1=cir.x,cir.y
                                local x2,y2=firstLaserunit.x,firstLaserunit.y
                                local distance=Shape.distance(x1,y1,x2,y2)
                                local dir=Shape.to(x1,y1,x2,y2)
                                local hpLevel=en:getHPLevel()
                                local dr=math.max(1,distance/(16-hpLevel*2))
                                for r=0,distance,dr do
                                    local x3,y3=Shape.rThetaPos(x1,y1,r,dir)
                                    local dir2=Shape.to(x3,y3,x2,y2)
                                    if math.abs(r-distance)<Shape.EPS then
                                        dir2=Shape.to(x3,y3,x1,y1)+math.pi
                                    end
                                    local toPlayerAngle=Shape.to(x3,y3,player.x,player.y)
                                    local dir3=dir2+math.eval('1.57+0.2')
                                    dir3=math.modClamp(dir3,toPlayerAngle,math.pi/2)
                                    local new=Circle{x=x3,y=y3,direction=dir3,speed=math.eval('0+10')-speed,sprite=BulletSprites.scale[Asset.colors[colorIndex or 1]],lifeFrame=1000}
                                    Event.EaseEvent{
                                        obj=new,
                                        aimTable=new,
                                        aimKey='speed',
                                        aimValue=2*speed,
                                        easeFrame=60
                                    }
                                end
                            end
                            Event.DelayEvent{
                                obj=cir,
                                delayFrame=10,
                                executeFunc=function()
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='direction',
                                        aimValue=cir.direction+math.mod2Sign(cir.index)*deltaTheta/2,
                                        easeFrame=40,
                                        afterFunc=function()
                                            Event.LoopEvent{
                                                obj=cir,
                                                period=30,
                                                times=5,
                                                executeFunc=function(self,times)
                                                    generate(cir,10+times*2.5,times+1)
                                                end
                                            }
                                        end
                                    }
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='speed',
                                        aimValue=0,
                                        easeFrame=1000
                                    }
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='radius',
                                        aimValue=4,
                                        easeFrame=80
                                    }
                                end
                            }
                            Event.DelayEvent{
                                obj=cir,
                                delayFrame=1170,
                                executeFunc=function()
                                    cir.speed=0
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='radius',
                                        aimValue=0,
                                        easeFrame=20
                                    }
                                end
                            }
                            Event.DelayEvent{
                                obj=cir,
                                delayFrame=1200,
                                executeFunc=function()
                                    cir:remove()
                                end
                            }
                        end
                    }}
                end
                local function enemyDash(step,pos)
                    pos=pos or {x=player.x,y=player.y}
                    local toPlayerAngle=Shape.to(en.x,en.y,pos.x,pos.y)
                    local dis=Shape.distance(en.x,en.y,pos.x,pos.y)
                    en.x,en.y=Shape.rThetaPos(en.x,en.y,math.min(dis,step),toPlayerAngle)
                    a.x,a.y=en.x,en.y
                end

                en.arrowAngle=0
                local function drawArrow()
                    local x,y=player.x,player.y
                    local angle=en.arrowAngle
                    local nx,ny
                    local size=4
                    local f=30
                    local function circle(x,y)
                        local cir=Circle{x=x,y=y,speed=0,direction=angle,sprite=BulletSprites.round.blue,lifeFrame=f,invincible=true,safe=true}
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='spriteTransparency',
                            aimValue=0,
                            easeFrame=f
                        }
                    end
                    for i=0,10 do
                        nx,ny=Shape.rThetaPos(x,y,size*i,angle)
                        circle(nx,ny)
                    end
                    local angle2=Shape.to(nx,ny,x,y)
                    for i=1,3 do
                        local nx2,ny2=Shape.rThetaPos(nx,ny,size*i,angle2+math.pi/6)
                        circle(nx2,ny2)
                        nx2,ny2=Shape.rThetaPos(nx,ny,size*i,angle2-math.pi/6)
                        circle(nx2,ny2)
                    end
                    for i=-1,-10,-1 do
                        nx,ny=Shape.rThetaPos(x,y,size*i,angle)
                        circle(nx,ny)
                    end
                    angle2=Shape.to(nx,ny,x,y)
                    for i=1,3 do
                        local nx2,ny2=Shape.rThetaPos(nx,ny,size*i,angle2+math.pi/6)
                        circle(nx2,ny2)
                        nx2,ny2=Shape.rThetaPos(nx,ny,size*i,angle2-math.pi/6)
                        circle(nx2,ny2)
                    end
                end
                a=BulletSpawner{x=400,y=300000,period=150,frame=80,lifeFrame=10000,bulletNumber=2,bulletSpeed=150,bulletLifeFrame=350,angle=0,range=math.pi*2,bulletSprite=BulletSprites.giant.yellow,bulletEvents={
                    function(cir,args,self)
                        createLaser(cir.x,cir.y,cir.direction,0.35)
                    end
                }}
                local function oneAttack(deltaTheta)
                    deltaTheta=deltaTheta or 0
                    SFX:play('enemyCharge',true)
                    local newAngle=Shape.to(player.x,player.y,en.x,en.y)+math.pi+deltaTheta
                    en.arrowAngle=newAngle
                    drawArrow()
                    local distance0=Shape.distance(player.x,player.y,en.x,en.y)
                    local hpLevel0=en:getHPLevel()
                    Event.DelayEvent{
                        obj=en,
                        delayFrame=52,
                        executeFunc=function()
                            en.safe=true -- prevent enemy's body killing player when dashing
                            Event.LoopEvent{
                                obj=en,
                                period=1,
                                times=5,
                                executeFunc=function(self,times,maxTimes)
                                    local aimx,aimy=Shape.rThetaPos(player.x,player.y,math.max(distance0,40),newAngle+math.pi)
                                    local distance=Shape.distance(player.x,player.y,aimx,aimy)
                                    local rt=maxTimes-times
                                    enemyDash(distance/rt,{x=aimx,y=aimy})
                                end
                            }
                        end
                    }
                    Event.DelayEvent{
                        obj=en,
                        delayFrame=60,
                        executeFunc=function()
                            local hpLevel=en:getHPLevel()
                            if hpLevel0~=hpLevel then -- into next phase, cancel current attack
                                return
                            end
                            SFX:play('enemyPowerfulShot',true)
                            createLaser(player.x,player.y,newAngle,1.5,'normal')
                            local xp,yp=player.x,player.y
                            local xn,yn=en.x,en.y
                            local angle=Shape.to(xp,yp,xn,yn)
                            local distance=Shape.distance(xp,yp,xn,yn)
                            local dr=math.max(2,distance/(hpLevel<3 and 50 or 20))
                            for r=-distance,distance,dr do
                                if math.abs(r)<8 then
                                   goto continue 
                                end
                                local x3,y3=Shape.rThetaPos(xp,yp,r,angle)
                                local dir2=Shape.to(x3,y3,xp,yp)
                                local new=Circle{x=x3,y=y3,direction=dir2+math.eval('0+0.4'),speed=math.eval('-120+30'),sprite=BulletSprites.scale.orange,lifeFrame=600}
                                Event.EaseEvent{
                                    obj=new,
                                    aimTable=new,
                                    aimKey='speed',
                                    aimValue=60,
                                    easeFrame=120
                                }
                                ::continue::
                            end
                            en.x,en.y=Shape.rThetaPos(xp,yp,math.clamp(distance,20,80),angle+math.pi)
                            en.safe=false
                        end
                    }
                end
                local spawnBatchFuncRef=a.spawnBatchFunc
                a.spawnBatchFunc=function (self)
                    local hpLevel=en:getHPLevel()
                    for i=1,hpLevel do
                        local deltaTheta=math.pi/(hpLevel)*(i-1)
                        Event.DelayEvent{
                            obj=en,
                            delayFrame=i*5-4,
                            executeFunc=function()
                                local hpLevel2=en:getHPLevel()
                                if hpLevel2~=hpLevel then -- into next phase, cancel current attack
                                    return
                                end
                                oneAttack(deltaTheta)
                            end
                        }
                    end
                end

                

                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                        enemyDash(0.1)
                    end
                }
                
            end
        },
        {
            quote='?',
            user='?',
            spellName='?', 
            make=function()
                G.levelRemainingFrame=7200
                G.levelIsTimeoutSpellcard=true
                Shape.removeDistance=100000
                local a,b
                local en
                en=Enemy{x=500,y=300,mainEnemy=true,maxhp=96000000}
                en:addHPProtection(600,10)
                local player=Player{x=400,y=600}
                player.cancelVortex=true
                player.shoot=function() end
                player.moveMode=Player.moveModes.Natural
                player.border:remove()
                local _,r=backgroundPattern.calculateSideLength(4,5)
                local poses={}
                for i = 1, 4, 1 do
                    local nx,ny=Shape.rThetaPos(400,300,r,math.pi*(1/2*(i-.5)-0/6*math.mod2Sign(i)))
                    table.insert(poses,{nx,ny})
                end
                player.border=PolyLine(poses)
                G.viewMode.mode=G.VIEW_MODES.FOLLOW
                G.viewMode.object=player

                --- input object and (x1,y1), (x2,y2) that determines the mirror, return a fake object (a table with x, y and orientation)
                ---@param obj table
                ---@param x1 number
                ---@param y1 number
                ---@param x2 number
                ---@param y2 number
                ---@return table
                local function objReflection(obj,x1,y1,x2,y2)
                    local xs,ys=obj.x,obj.y
                    local xReflection,yReflection,deltaOrientation=Shape.reflectByLine(xs,ys,x1,y1,x2,y2)
                    local fakeObj={x=xReflection,y=yReflection,orientation=deltaOrientation-(obj.orientation or 0),sprite=obj.sprite} 
                    return fakeObj
                end

                -- wrap obj.functionName to achieve calling the original function on every reflection object.
                -- functionName should be "atomic" function that doesn't call other obj methods (so only love draw)
                -- using copy_table on reflected object above is clearly a heavy load and causes fps drop, so you need to copy needed attributes from self to reflectedSelf
                local function reflectFunctionalize(obj,functionName,exitLayer,drawConditionFunc,modificationToReflectionFunc)
                    local originalFunc=obj[functionName]
                    obj[functionName]=function(self,...) -- add layer, lastIndex and inReflection parameter
                        local paramLength=select('#',...)
                        local inReflection=paramLength>0 and select(-1,...)=='inReflection'
                        local layer=0
                        local lastIndex
                        local args={...}
                        if inReflection then
                            layer=select(-3,...)
                            lastIndex=select(-2,...)
                        else
                            table.insert(args,0)
                            table.insert(args,0)
                            table.insert(args,'inReflection')
                        end
                        if not drawConditionFunc or drawConditionFunc(self,layer) then
                            originalFunc(self,...)
                        end
                        args[#args-2]=layer+1 -- layer+=1
                        if layer==exitLayer then return end
                        local border=player.border
                        for i=1,#border.points do
                            if i==lastIndex then
                                goto continue
                            end
                            local x1,y1=border.points[i].x,border.points[i].y
                            local x2,y2=border.points[i%#border.points+1].x,border.points[i%#border.points+1].y
                            local reflectedSelf=objReflection(self,x1,y1,x2,y2)
                            if modificationToReflectionFunc then
                                modificationToReflectionFunc(reflectedSelf,self,x1,y1,x2,y2)
                            end
                            args[#args-1]=i -- lastIndex
                            obj[functionName](reflectedSelf,unpack(args))
                            ::continue::
                        end
                    end
                end

                reflectFunctionalize(player,'draw',2,function(self,layer)
                    return layer>0 
                end,function(fakePlayer,self)
                    fakePlayer.drawRadius=self.drawRadius
                    fakePlayer.focusPointTransparency=self.focusPointTransparency
                    fakePlayer.time=-self.time
                    fakePlayer.horizontalFlip=not self.horizontalFlip
                end)


                local borderdrawOneRef=player.border.drawOne
                player.border.drawOne=function(p1,p2,layer,lastIndex)
                    layer=layer or 0
                    borderdrawOneRef(p1,p2)
                    if layer==2 then return end
                    local border=player.border
                    for i=1,#border.points do
                        if i==lastIndex then
                            goto continue
                        end
                        local x1,y1=border.points[i].x,border.points[i].y
                        local x2,y2=border.points[i%#border.points+1].x,border.points[i%#border.points+1].y
                        local xs1=p1.x
                        local ys1=p1.y
                        local xs2=p2.x
                        local ys2=p2.y
                        if xs1==x1 and ys1==y1 and xs2==x2 and ys2==y2 then
                            goto continue
                        end
                        -- ugh 2 reflections here make it not able to use reflectFunctionalize :(
                        local xr1,yr1=Shape.reflectByLine(xs1,ys1,x1,y1,x2,y2)
                        local xr2,yr2=Shape.reflectByLine(xs2,ys2,x1,y1,x2,y2)
                        player.border.drawOne({x=xr1,y=yr1},{x=xr2,y=yr2},layer+1,i)
                        ::continue::
                    end
                end

                a=BulletSpawner{x=400,y=300,period=150,frame=80,lifeFrame=10000,bulletNumber=10,bulletSpeed=50,bulletLifeFrame=3500,angle='0+360',range=math.pi*2,bulletSprite=BulletSprites.scale.yellow,bulletEvents={
                    function(cir,args,self)
                        reflectFunctionalize(cir,'drawSprite',2,function(self,layer)
                            return true 
                        end,function(reflectedSelf,self,x1,y1,x2,y2)
                            reflectedSelf.radius=self.radius
                            reflectedSelf.batch=self.batch
                            reflectedSelf.direction=math.pi-self.direction+reflectedSelf.orientation
                            reflectedSelf.orientation=0
                        end)
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            conditionFunc=function()
                                return not player.border:inside(cir.x,cir.y)
                            end,
                            executeFunc=function()
                                cir:remove()
                            end
                        }
                    end
                }}

                Event.LoopEvent{
                    obj=en,
                    period=1,
                    executeFunc=function()
                    end
                }
                
            end
        },
    }
}
levelData.needPass={3,6,9,12,16,20,25,30}
local Text=require"text"
for index, value in ipairs(levelData) do
    for index2, value2 in ipairs(value) do
        if value2.make then
            local makeLevelRef=value2.make
            value2.make=function()
                local replay=G.replay or {}
                local seed = replay.seed or math.floor(os.time()+os.clock()*1337)
                math.randomseed(seed)
                G.randomseed=seed
                Shape.timeSpeed=1
                G.viewMode.mode=G.VIEW_MODES.NORMAL
                G.viewOffset={x=0,y=0}
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
                        progressFunc=Event.sineOProgressFunc
                    }
                    Event.EaseEvent{
                        obj=txt,
                        easeFrame=120,
                        aimTable=txt.color,
                        aimKey=4,
                        aimValue=1,
                        progressFunc=Event.sineOProgressFunc
                    }
                end
                -- show user name
                do
                    local name=Localize{'levelData','names',value2.user}
                    local fontSize=72
                    if string.len(name)>20 then -- ensure the name fits in the screen
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
                makeLevelRef()
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
                        if option.upgrade and G.save.upgrades[i] and G.save.upgrades[i][k] and G.save.upgrades[i][k].bought==true then
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