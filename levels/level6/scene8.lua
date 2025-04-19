return {
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
        G.backgroundPattern=BackgroundPattern.FollowingTesselation{sideColor={0.9,0.7,0.18},sideNum=sideNum,angleNum=angleNum,toDrawNum=100}
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
                    backgroundPatt.angle=math.eval(0,999)
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
            local deltaAngle=math.eval(0,99999)
            for key,side in pairs(sides) do
                local x1,y1,x2,y2=side[1].x,side[1].y,side[2].x,side[2].y
                local angle1=Shape.to(x1,y1,x2,y2)+deltaAngle
                local center1,center2={BackgroundPattern.getCenterOfPolygonWithSide(x1,y1,x2,y2,backgroundPatt.sideNum,backgroundPatt.angleNum)},{BackgroundPattern.getCenterOfPolygonWithSide(x2,y2,x1,y1,backgroundPatt.sideNum,backgroundPatt.angleNum)}
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
}