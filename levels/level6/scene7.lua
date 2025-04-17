return {
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
        G.backgroundPattern=BackgroundPattern.FollowingTesselation{sideColor={1,0.2,0.1},sideNum=sideNum,angleNum=angleNum,toDrawNum=50}
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
                local center1,center2={BackgroundPattern.getCenterOfPolygonWithSide(x1,y1,x2,y2,backgroundPatt.sideNum,backgroundPatt.angleNum)},{BackgroundPattern.getCenterOfPolygonWithSide(x2,y2,x1,y1,backgroundPatt.sideNum,backgroundPatt.angleNum)}
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
}