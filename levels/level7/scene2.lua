return {
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
}