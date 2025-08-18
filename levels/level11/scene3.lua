return {
    ID=75,
    user="yukari",
    spellName="Instant Pierce Barrier - Impregnable Fortress",
    make=function()
        G.levelRemainingFrame=10800
        Shape.removeDistance=1e100
        local en,player,phases
        local function evict(radius)
            local playerDirection=Shape.to(en.x,en.y,player.x,player.y)
            local distance=Shape.distance(en.x,en.y,player.x,player.y)
            local aimDistance=radius
            player.evicting=true
            player.invincibleTime=player.invincibleTime+0.5 -- when normally clearing a phase, player is evicted to far away and it's possible to run into bullets. so add invincibleTime
            Event.LoopEvent{
                obj=en,
                period=1,times=20,
                executeFunc=function(self,executedTimes,totalTimes)
                    player.x,player.y=Shape.rThetaPos(en.x,en.y,distance+executedTimes*(aimDistance-distance)/totalTimes,playerDirection)
                    if executedTimes==totalTimes-1 then
                        player.evicting=false
                        player.invincibleTime=player.invincibleTime-0.5
                    end
                end,
            }
        end
        local function getRadius(hpLevel)
            hpLevel=hpLevel or en:getHPLevel()
            local radiusTable={100,120,160,270}
            return radiusTable[hpLevel]
        end
        en=Enemy{x=400,y=400000,mainEnemy=true,maxhp=960,hpSegments={0.75,0.5,0.25},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            -- en:addHPProtection(600,10)
            if hpLevel==1 then
                Event.EaseEvent{
                    obj=en,
                    easeFrame=60,
                    aimTable=en,
                    aimKey='r2',
                    aimValue=en.r2+10
                }
            end
            evict(getRadius(hpLevel+1))
            if phases[hpLevel+1] then
               phases[hpLevel+1]() 
            end
        end}
        -- en:addHPProtection(600,10)
        player=Player{x=400,y=1200000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local poses={}
        for i = 1, 30, 1 do
            local nx,ny=Shape.rThetaPos(400,400000,700,math.pi/15*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local shoot=player.shootDirStraight
        player.shootDirStraight=function(self,pos,damage,sprite,theta)
            -- self.canHitFamiliar=false
            local cir=shoot(self,pos,damage,sprite,theta)
            Event.LoopEvent{
                obj=cir,
                period=1,times=1,
                conditionFunc=function(self)return Shape.distance(cir.x,cir.y,player.x,player.y)>en.r2 end,
                executeFunc=function(self)
                    cir.speed=0
                end
            }
            return cir
        end
        -- local hitEffectRef=player.hitEffect
        -- player.hitEffect=function(player,damage)
        --     hitEffectRef(player,damage)
        --     evict(getRadius())
        -- end
        local autoEvict=function()
            evict(getRadius())
        end
        EventManager.listenTo(EventManager.EVENTS.PLAYER_HIT,autoEvict,'leaveLevel')

        local function circleEffect(cir)
            Event.LoopEvent{
                obj=cir,
                period=1,
                conditionFunc=function(self)return not player.evicting and Shape.distance(cir.x,cir.y,player.x,player.y)<en.r2 end,
                executeFunc=function(self)
                    local times=0
                    local speedRef=cir.speed
                    cir.speed=math.max(cir.speed,40)
                    while Shape.distance(cir.x,cir.y,player.x,player.y)<en.r2 and times<50 do
                        times=times+1
                        cir:updateMove(1/60)
                        local nx,ny=cir.x,cir.y
                        -- local nx,ny,newDir=Shape.rThetaPosT(cir.x,cir.y,1,cir.direction)
                        -- cir.x=nx
                        -- cir.y=ny
                        -- cir.direction=newDir
                        Circle{x=nx,y=ny,direction=cir.direction,speed=0,sprite=cir.sprite,invincible=true,lifeFrame=0,batch=Asset.bulletHighlightBatch,}
                        cir:checkHitPlayer()
                    end
                    cir.speed=speedRef
                end
            }
        end

        -- create a circle of bullets rotating around their center
        local function rotatingCircle(cir,radius,speed,number,reversed,size,life)
            number=number or 10
            -- local circumference=math.pi*2*math.sinh(radius/Shape.curvature)*Shape.curvature
            local angularSpeed=speed/60/radius
            BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=number,bulletSpeed=speed,bulletLifeFrame=life or 6000,angle=math.pi/2*(reversed and -1 or 1),bulletSprite=BulletSprites.scale.green,bulletSize=size or 1,
            -- fogEffect=true,fogTime=120,
            spawnCircleRadius=radius,bulletEvents={
                function(cir2,args)
                    cir2.invincible=true
                    circleEffect(cir2)
                    Event.LoopEvent{
                        obj=cir2,
                        period=1,
                        executeFunc=function()
                            cir2.direction=cir2.direction+angularSpeed*(reversed and -1 or 1)
                        end
                    }
                end
            }
            }
        end
        local phase4EnteredInner=false
        local function bulletLine(from,to,gap,trigger,life)
            local distance=Shape.distance(from.x,from.y,to.x,to.y)
            local dir=Shape.to(from.x,from.y,to.x,to.y)
            for i=0,distance,gap do
                local nx,ny,newTheta=Shape.rThetaPosT(from.x,from.y,i,dir)
                local cir=Circle{x=nx,y=ny,direction=newTheta+math.pi/2,speed=0,sprite=Asset.bulletSprites.bigRound.red,lifeFrame=life or 19000,radius=2.47,invincible=true}
                if trigger then
                    Event.LoopEvent{
                        obj=cir,
                        period=1,times=1,conditionFunc=function(self)return phase4EnteredInner end,
                        executeFunc=function(self)
                            cir.direction=cir.direction+math.eval(math.pi,0.2)
                            cir.speed=math.eval(85,80)
                            cir:changeSpriteColor('gray')
                            Event.EaseEvent{
                                obj=cir,
                                easeFrame=60,
                                aimTable=cir,
                                aimKey='speed',
                                aimValue=0
                            }
                        end
                    }
                end
            end
        end
        local function injectBulletSpawnDistance(bulletSpawner)
            Event.LoopEvent{
                obj=bulletSpawner,
                period=1,times=1,conditionFunc=function(self)return phase4EnteredInner end,
                executeFunc=function(self)
                    if type(bulletSpawner.angle)=="number" then 
                        bulletSpawner.angle=bulletSpawner.angle+math.pi
                    end
                end
            }
            local spawnBatchFuncRef=bulletSpawner.spawnBatchFunc
            bulletSpawner.spawnBatchFunc=function (self)
                if Shape.distance(self.x,self.y,player.x,player.y)>100 or self.frame<50 then
                    return
                end
                spawnBatchFuncRef(self)
            end
        end
        phases={ -- first 3 phases are just tutorial, phase 4 is the real deal
            function()
                BulletSpawner{x=en.x,y=en.y,period=40,frame=0,lifeFrame=50,bulletNumber=24,bulletSpeed=70,bulletLifeFrame=125,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.giant.yellow,bulletEvents={
                    function(cir,args,self)
                        local index=args.index
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=20,
                            executeFunc=function()
                                Event.LoopEvent{
                                    obj=cir,period=3,executeFunc=function ()
                                        cir.direction=cir.direction+math.mod2Sign(index)*0.1
                                        local cir2=Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=0,sprite=Asset.bulletSprites.scale.yellow,lifeFrame=12000}
                                        circleEffect(cir2)
                                        cir2.invincible=true
                                    end
                                }
                            end
                        }
                    end
                }}
            end,
            function()
                BulletSpawner{x=en.x,y=en.y,period=40,frame=0,lifeFrame=50,bulletNumber=24,bulletSpeed=30,bulletLifeFrame=70,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.giant.yellow,bulletEvents={
                    function(cir,args,self)
                        local index=args.index
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=20,
                            executeFunc=function()
                                Event.LoopEvent{
                                    obj=cir,period=5,executeFunc=function ()
                                        cir.direction=cir.direction+math.mod2Sign(index)*0.1
                                        local cir2=Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=0,sprite=Asset.bulletSprites.scale.yellow,lifeFrame=12000}
                                        circleEffect(cir2)
                                        cir2.invincible=true
                                    end
                                }
                            end
                        }
                    end
                }}
                BulletSpawner{x=en.x,y=en.y,period=40,frame=20,lifeFrame=50,bulletNumber=72,bulletSpeed=80,bulletLifeFrame=60,spawnCircleRadius=30,angle=0,range=math.pi*2,bulletSprite=BulletSprites.giant.blue,bulletEvents={
                    function(cir,args,self)
                        local index=args.index
                        cir.speed=cir.speed-(index%12)*4
                        cir.direction=cir.direction+math.mod2Sign(index)*math.pi/2
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=30,
                            executeFunc=function()
                                Event.LoopEvent{
                                    obj=cir,period=3,executeFunc=function (self,executedTimes)
                                        local cir2=Circle{x=cir.x,y=cir.y,direction=cir.direction+math.pi/3,speed=index%12*3,sprite=Asset.bulletSprites.scale.blue,lifeFrame=12000}
                                        Event.EaseEvent{
                                            obj=cir2,
                                            easeFrame=60,
                                            aimTable=cir2,
                                            aimKey='speed',
                                            aimValue=0
                                        }
                                        circleEffect(cir2)
                                        cir2.invincible=true
                                    end
                                }
                            end
                        }
                    end
                }}
                local staticCircle=function(cir,radius,number,angle,size,life)
                    BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=number,bulletSpeed=0,bulletLifeFrame=life or 6000,angle=angle,bulletSprite=BulletSprites.scale.green,bulletSize=size or 1,
                    -- fogEffect=true,fogTime=120,
                    spawnCircleRadius=radius,bulletEvents={
                        function(cir2,args)
                            cir2.invincible=true
                            circleEffect(cir2)
                        end}}
                end
                Event.DelayEvent{
                    obj=en,delayFrame=30,
                    executeFunc=function()
                        SFX:play('enemyPowerfulShot',true)
                        staticCircle(en,90,50,math.pi/2-0.3)
                        staticCircle(en,80,50,-math.pi/2+0.3)
                    end
                }
            end,
            function()
                BulletSpawner{x=en.x,y=en.y,period=150,frame=0,lifeFrame=5000,bulletNumber=3,bulletSpeed=30,bulletLifeFrame=700,angle='player',range=math.pi/6,bulletSprite=BulletSprites.ellipse.yellow,bulletEvents={
                    function(cir,args,self)
                        circleEffect(cir)
                    end
                }}
                local function generate(number,radius,range)
                    BulletSpawner{x=en.x,y=en.y,period=40,frame=20,lifeFrame=50,bulletNumber=number,bulletSpeed=0,bulletLifeFrame=9990,spawnCircleRadius=radius,spawnCircleAngle='0+999',angle=0,range=math.pi*2,bulletSprite=BulletSprites.giant.green,bulletEvents={
                        function(cir,args,self)
                            rotatingCircle(cir,5,60)
                            cir.invincible=true
                            BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=1,bulletNumber=20,bulletSpeed=30,bulletLifeFrame=13000,angle=Shape.to(cir.x,cir.y,en.x,en.y),range=range,bulletSprite=BulletSprites.knife.green,
                            -- fogEffect=true,fogTime=120,
                            spawnCircleRadius=0,bulletEvents={
                                function(cir2,args)
                                    if args.index%2==1 then
                                        cir2.speed=cir2.speed+30
                                    end
                                    cir2.invincible=true
                                    circleEffect(cir2)
                                    Event.EaseEvent{
                                        obj=cir2,
                                        easeFrame=60,
                                        aimTable=cir2,
                                        aimKey='speed',
                                        aimValue=0
                                    }
                                end
                            }}
                        end
                    }}
                end
                Event.DelayEvent{
                    obj=en,delayFrame=10,
                    executeFunc=function()
                        generate(5,44,math.pi*2)
                    end
                }
                Event.DelayEvent{
                    obj=en,delayFrame=20,
                    executeFunc=function()
                        generate(10,95,math.pi)
                    end
                }
            end,
            function()
                local function generate(number,radius,angle,shoot)
                    local last
                    local first
                    BulletSpawner{x=en.x,y=en.y,period=40,frame=20,lifeFrame=50,bulletNumber=number,bulletSpeed=0,bulletLifeFrame=19990,spawnCircleRadius=radius,bulletSize=2,spawnCircleAngle=angle or '0+999',angle=1.57,range=math.pi*2,bulletSprite=BulletSprites.giant.red,bulletEvents={
                        function(cir,args,self)
                            cir.invincible=true
                            local reachOut={Shape.rThetaPosT(cir.x,cir.y,49,Shape.to(cir.x,cir.y,en.x,en.y)+math.pi)}
                            reachOut={x=reachOut[1],y=reachOut[2],theta=reachOut[3]}
                            if shoot then
                                local type=math.random(1,4) -- 4 types of sentries
                                local color
                                if type==1 then
                                    local bs=BulletSpawner{x=reachOut.x,y=reachOut.y,period=30,frame=0,lifeFrame=15000,bulletNumber=4,bulletSpeed=90,bulletLifeFrame=300,angle='player',range=math.pi/2,bulletSprite=BulletSprites.ellipse.yellow,bulletEvents={
                                        function(cir,args,self)
                                            local index=args.index
                                            local delta=math.eval(0,0.2)
                                            
                                            cir.direction=cir.direction+delta
                                            circleEffect(cir)
                                        end
                                    }}
                                    injectBulletSpawnDistance(bs)
                                    color='yellow'
                                elseif type==2 then
                                    local bs=BulletSpawner{x=reachOut.x,y=reachOut.y,period=5,frame=0,lifeFrame=15000,bulletNumber=2,bulletSpeed=90,bulletLifeFrame=60,angle='player',range=math.pi/2,bulletSprite=BulletSprites.ellipse.blue,bulletEvents={
                                        function(cir2,args,self)
                                            local index=args.index
                                            local delta=math.mod2Sign(index)*(cir.frame%60)*0.01
                                            
                                            cir2.direction=cir2.direction+delta
                                            circleEffect(cir2)
                                        end
                                    }}
                                    injectBulletSpawnDistance(bs)
                                    color='blue'
                                elseif type==3 then
                                    local bs=BulletSpawner{x=reachOut.x,y=reachOut.y,period=120,frame=0,lifeFrame=15000,bulletNumber=3,bulletSpeed=360,bulletLifeFrame=600,angle=reachOut.theta,range=math.pi/2,bulletSprite=BulletSprites.giant.green,bulletEvents={
                                        function(cir2,args,self)
                                            local delay=math.eval('5+5')
                                            Event.DelayEvent{
                                                obj=cir2,delayFrame=delay,
                                                executeFunc=function()
                                                    rotatingCircle(cir2,5,60,nil,nil,2,120)
                                                    Event.EaseEvent{
                                                        obj=cir2,
                                                        easeFrame=30,
                                                        aimTable=cir2,
                                                        aimKey='speed',
                                                        aimValue=0,
                                                        afterFunc=function()
                                                            rotatingCircle(cir2,5,60,nil,nil,2,120)
                                                            cir2:remove()
                                                        end
                                                    }
                                                end
                                            }
                                        end
                                    }}
                                    injectBulletSpawnDistance(bs)
                                    color='green'
                                else
                                    local bs=BulletSpawner{x=reachOut.x,y=reachOut.y,period=120,frame=0,lifeFrame=15000,bulletNumber=3,bulletSpeed=180,bulletLifeFrame=600,angle=reachOut.theta,range=math.pi/2,bulletSprite=BulletSprites.giant.red,bulletEvents={
                                        function(cir2,args,self)
                                            local delay=math.eval('3+3')
                                            Event.DelayEvent{
                                                obj=cir2,delayFrame=delay,
                                                executeFunc=function()
                                                    local toPlayerAngle=Shape.to(cir2.x,cir2.y,player.x,player.y)
                                                    Event.LoopEvent{
                                                        obj=cir2,period=3,times=10,executeFunc=function ()
                                                            local cir3=Circle{x=cir2.x,y=cir2.y,direction=math.modClamp(cir2.direction+math.pi/2,toPlayerAngle,math.pi/2),speed=0,sprite=Asset.bulletSprites.knife.red,lifeFrame=120}
                                                            circleEffect(cir3)
                                                        end
                                                    }
                                                end
                                            }
                                        end
                                    }}
                                    injectBulletSpawnDistance(bs)
                                    color='red'
                                end
                                Circle{x=reachOut.x,y=reachOut.y,direction=0,speed=0,sprite=Asset.bulletSprites.giant[color],lifeFrame=16000,radius=2,invincible=true}
                                bulletLine(cir,reachOut,10,true)
                            end
                            if not last then
                                first=cir
                                last=cir
                                return
                            end
                            bulletLine(cir,last,10,true) -- connect bullets like a curtain wall
                            if args.index==number then -- leaves larger gap for player to enter
                                bulletLine(first,cir,20,true)
                            end
                            last=cir
                        end
                    }}
                end
                local function generateInner1frame(number,radius,angle)
                    local last
                    local first
                    BulletSpawner{x=en.x,y=en.y,period=1,frame=0,lifeFrame=1,bulletNumber=number,bulletSpeed=0,bulletLifeFrame=1,spawnCircleRadius=radius,bulletSize=2,spawnCircleAngle=angle or '0+999',angle=1.57,range=math.pi*2,bulletSprite=BulletSprites.giant.red,bulletEvents={
                        function(cir,args,self)
                            cir.invincible=true
                            if not last then
                                first=cir
                                last=cir
                                return
                            end
                            bulletLine(cir,last,10,nil,1) -- connect bullets like a curtain wall
                            if args.index==number then -- leaves larger gap for player to enter
                                bulletLine(first,cir,20,nil,1)
                            end
                            last=cir
                        end
                    }}
                end
                local toPlayerAngle=Shape.to(en.x,en.y,player.x,player.y)
                Event.DelayEvent{
                    obj=en,delayFrame=30,
                    executeFunc=function()
                        local angle1=toPlayerAngle+math.eval(0,1)--*math.randomSign()
                        generate(23,190,angle1,1)
                        local angleInner=angle1+math.eval(3.14,1.57)
                        generate(8,95,angleInner)
                        Event.LoopEvent{
                            obj=player,period=1,times=1,
                            conditionFunc=function(self)return Shape.distance(player.x,player.y,en.x,en.y)<185 end,
                            executeFunc=function(self)
                                SFX:play('enemyPowerfulShot',true)
                                phase4EnteredInner=true
                                local en2player=Shape.to(en.x,en.y,player.x,player.y)
                                local cx,cy=Shape.rThetaPos(en.x,en.y,215,en2player)
                                local circle=Circle{x=cx,y=cy,direction=Shape.to(cx,cy,player.x,player.y),speed=20,sprite=Asset.bulletSprites.heart.red,lifeFrame=6000,radius=2,invincible=true}
                                Event.LoopEvent{
                                    obj=circle,
                                    period=1,
                                    executeFunc=function(self,executedTimes)
                                        circle.direction=Shape.to(circle.x,circle.y,player.x,player.y)
                                        if executedTimes%20==0 and executedTimes>50 then
                                            local cir=Circle{x=circle.x,y=circle.y,direction=circle.direction,speed=40,sprite=Asset.bulletSprites.heart.red,lifeFrame=600,radius=1}
                                            circleEffect(cir)
                                            Event.EaseEvent{
                                                obj=cir,
                                                easeFrame=60,
                                                aimTable=cir,
                                                aimKey='speed',
                                                aimValue=120,
                                            }
                                        end
                                    end
                                }
                                local rotateCoeff=0.5
                                Event.LoopEvent{
                                    obj=en,period=1,
                                    executeFunc=function(self)
                                        local en2playerNew=Shape.to(en.x,en.y,player.x,player.y)
                                        angleInner=angleInner+math.modClamp(en2playerNew-en2player,0,math.pi/2)*rotateCoeff
                                        en2player=en2playerNew
                                        generateInner1frame(8,95,angleInner)
                                    end
                                }
                            end
                        }
                    end
                }
                
            end,
        }
        local beginLevel=1
        en.r2=10*math.min(beginLevel,2)
        phases[beginLevel]()
        evict(getRadius(beginLevel))
        
        Event.DelayEvent{
            obj=en,
            period=30,
            executeFunc=function()
                SFX:play('enemyPowerfulShot',true)
                local drawRef=en.draw
                en.draw=function(self)
                    local colorref={love.graphics.getColor()}
                    love.graphics.setColor(0,1,0,0.5)
                    Shape.drawCircle(player.x,player.y,en.r2,'fill')
                    love.graphics.setColor(1,0,0,0.5)
                    -- Shape.drawCircle(en.x,en.y,en.r1,'fill') --  "player's bullet disappears when entering area around enemy from outside" is simplified to "player's bullet don't move when exiting player's area"
                    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4] or 1)
                    drawRef(self)
                end
            end
        }
    end
}