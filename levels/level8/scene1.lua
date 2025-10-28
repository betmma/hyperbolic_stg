return {
    ID=71,
    quote='?',
    user='youmu',
    dialogue='protagonistsDialogue8_1',
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
}