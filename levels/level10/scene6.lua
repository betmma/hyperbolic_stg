return {
    ID=65,
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
                                cir.sprite=BulletSprites.rice[cir.sprite.data.color]
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
                        local newAngle=cavityAngle+math.eval(0,1.57)
                        local newHalfAngle=math.pi*math.eval(0.03,0.01)
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
                        BulletSpawner{x=en.x,y=en.y,period=1,frame=0,lifeFrame=1,bulletNumber=30,bulletSpeed=15+5*i,bulletLifeFrame=900,angle=math.eval(0,999),range=math.pi*2,bulletSprite=BulletSprites.bill.purple,}
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
}