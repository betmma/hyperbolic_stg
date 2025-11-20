return {
    ID=58,
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
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
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
                            local color=cir.sprite.data.color
                            local direction
                            if color=='red' then
                                direction=cir.direction
                            elseif color=='blue' then
                                direction=Shape.to(cir.x,cir.y,player.x,player.y)
                            end
                            local laser=Laser{x=cir.x,y=cir.y,radius=2,direction=direction,speed=30,sprite=BulletSprites.laser[color],lifeFrame=25,frequency=3,smoothFrame=3,bulletEvents={
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
                            local laser2=Laser{x=cir.x,y=cir.y,radius=4,direction=direction,speed=300,sprite=BulletSprites.laserDark[color],lifeFrame=5,warningFrame=5,bulletEvents={
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
                    a.spawnEvent.period=120
                    a.bulletSprite=BulletSprites.rice.blue
                    a.range=math.pi*2
                    a.angle='0+999'
                    a.bulletNumber=math.ceil(5*(3-2*curPercent))
                else
                    a.spawnEvent.period=50
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
}