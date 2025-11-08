return {
    ID=81,
    user='okina',
    spellName='Secret Ceremony "Dark Butoh of the Back Door"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local a,b
        local en
        en=Enemy{x=400,y=1600000,mainEnemy=true,maxhp=14400,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            a.bulletSprite=BulletSprites.bigRound.blue
            en:addHPProtection(600,10)
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=800000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local poses={}
        for i = 1, 30, 1 do
            local nx,ny=Shape.rThetaPos(400,600000,700,math.pi/15*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local rDown=10
        local adding=true
        local enemyToAimDistance=30
        a=BulletSpawner{x=400,y=1600000,period=10,frame=-50,lifeFrame=10000,bulletNumber=1,bulletSpeed=300,bulletLifeFrame=100,angle=math.eval(0,999),range=math.pi*2,highlight=true,bulletSprite=BulletSprites.bigRound.red,fogEffect=true,fogTime=3,bulletEvents={
            function(cir,args,self)
                cir.safe=true
                local mod=(a.spawnEvent.executedTimes)%2
                local sign=math.mod2Sign(mod)
                if rDown>130 then
                    adding=false
                elseif rDown<30 then
                    adding=true
                    rDown=math.random()*10+20
                end
                rDown=rDown+10*(adding and 1 or -1)
                cir.speed=cir.speed-rDown*1.5
                local newDir
                cir.x,cir.y,newDir=Shape.rThetaPosT(player.x,player.y,rDown,player.naturalDirection+math.pi/2)
                newDir=newDir+math.pi/2*sign
                cir.direction=newDir
                local spreadRatio=enemyToAimDistance/10+1
                local hpLevel=en:getHPLevel()
                cir.extraUpdate[1]=function(cir)
                    cir.direction=cir.direction-cir.speed/Shape.curvature/60*sign -- move in horocycle (appears as a horizontal line if player doesn't move)
                    if cir.frame>30 and cir.frame%8==2 then
                        local frame=cir.frame
                        local args={x=cir.x,y=cir.y,sprite=BulletSprites.flame[hpLevel==1 and 'red' or 'blue'],lifeFrame=300,direction=0,speed=cir.frame*2+30,fogTime=100-cir.frame,batch=Asset.bulletHighlightBatch,extraUpdate={
                            function(cir2,args,self)
                                if cir2.speed>80 and hpLevel==1 then
                                    cir2.speed=cir2.speed*0.995
                                end
                                if cir2.frame>1 then
                                    return
                                end
                                cir2.direction=Shape.to(cir2.x,cir2.y,player.x,player.y)+(rDown-50)*0.001*sign*(spreadRatio)
                            end
                        }}
                        BulletSpawner.wrapFogEffect(args,Circle,true)
                    end
                end
            end
        }}
        Event.DelayEvent{
            obj=en,delayFrame=60,executeFunc=function() -- give a broader view of backside
                SFX:play('enemyPowerfulShot')
                Event.EaseEvent{
                    obj=en,aimTable=G.viewMode.viewOffset,aimKey='y',aimValue=-200,easeFrame=180,progressFunc=Event.sineIOProgressFunc
                }
                Event.EaseEvent{
                    obj=en,aimTable=Shape,aimKey='axisY',aimValue=-50,easeFrame=180,progressFunc=Event.sineIOProgressFunc
                }
            end
        }
        Event.LoopEvent{
            obj=en,
            period=1,
            frame=-50,
            executeFunc=function() -- moving behind player
                local nx,ny=Shape.rThetaPos(player.x,player.y,rDown,player.naturalDirection+math.pi/2)
                enemyToAimDistance=Shape.distance(nx,ny,en.x,en.y)
                Shape.moveTowards(en,{x=nx,y=ny},math.min(1.2,enemyToAimDistance/4),true)
                a.x,a.y=en.x,en.y
            end
        }
    end
}