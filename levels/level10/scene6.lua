return {
    ID=118,
    user='toyohime',
    spellName='Pure Land "Crystal on the Divine Sea"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=20000
        local center={x=400,y=3000}
        local a,b
        local en
        local player=Player{x=400,y=6000}
        en=Enemy{x=400,y=3000,mainEnemy=true,maxhp=4000,hpSegments={},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel,{bullet=true,invincible=false})
            SFX:play('enemyCharge',true)
            en:addHPProtection(600,10)
        end}
        en:addHPProtection(1200,10)
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,150,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local obj=Circle{x=center.x,y=center.y,sprite=BulletSprites.lotus.blue,invincible=true,radius=5,speed=0,direction=0,lifeFrame=9999,spriteTransparency=0,safe=true}
        -- Event.EaseEvent{
        --     obj=obj,easeFrame=120,aimKey='spriteTransparency',aimValue=0.5
        -- }
        local objEffect=Circle{x=center.x,y=center.y,sprite=BulletSprites.lotus.blue,invincible=true,radius=2,speed=0,direction=0,lifeFrame=9999,highlight=true,spriteTransparency=0,safe=true}
        Event.LoopEvent{
            obj=obj,period=1,executeFunc=function()
                obj.spriteExtraDirection=obj.spriteExtraDirection+0.02
                objEffect.spriteExtraDirection=objEffect.spriteExtraDirection+0.015
                objEffect.x,objEffect.y=obj.x,obj.y
                en.x,en.y=obj.x,obj.y
            end
        }
        local tesseAngle=math.eval(0,999)
        local adjacentPoints,angles,sidesTable=BackgroundPattern.tesselation(center,tesseAngle,3,7,0,{x=400,y=3500},42,nil,true)
        G.backgroundPattern:remove()
        G.backgroundPattern=BackgroundPattern.FixedTesselation{centerPoint=center,sideColor={0.1,0.1,0.5},faceColor={0.06,0.06,0.3},sideNum=3,angleNum=7,toDrawNum=42}
        Event.DelayEvent{
            obj=en,delayFrame=60,executeFunc=function()
                SFX:play('enemyShot',true,2)
        for i,sideTable in ipairs(sidesTable) do
            local p1,p2=sideTable[1],sideTable[2]
            -- local segments=Shape.segmentPoints(p1.x,p1.y,p2.x,p2.y,1,10)
            local d=Shape.distanceObj(p1,p2)
            local mid=Shape.segmentPoints(p1.x,p1.y,p2.x,p2.y,1,2)[2]
            local segments=Shape.regularPolygonCoordinates(mid.x,mid.y,d/4,20,Shape.toObj(mid,p2),true)
            for j=1,#segments do
                local posRef=segments[j]
                local x,y=posRef.x,posRef.y
                local cirargs={x=x,y=y,lifeFrame=9999,direction=math.eval(0,999),speed=10,sprite=BulletSprites.bigRound.blue,invincible=true,highlight=true,fogTime=60,extraUpdate={
                    function(cir)
                        local distance=Shape.distanceObj(cir,objEffect)
                        local pullMagnitude=math.clamp(1-(distance-objEffect.radius*1.4)/20,0,1)
                        cir.speed=cir.speed*(1-0.2*pullMagnitude)
                        Shape.moveTowards(cir,posRef,0.1*pullMagnitude,true,true)
                        cir.speed=cir.speed+math.eval(0,1)
                        cir.direction=cir.direction+math.eval(0,0.1)
                        local distance2Ref=Shape.distanceObj(cir,posRef)
                        local moveMagnitude=math.clamp((distance2Ref-10)/40,0,2)
                        Shape.moveTowards(cir,posRef,moveMagnitude,true)
                        cir.radius=math.clamp(2.5-distance2Ref/5,0.5,2)*2
                    end
                }}
                BulletSpawner.wrapFogEffect(cirargs,Circle,true)
            end
        end
            end
        }
        local function packed(x,y,dir)
            local num=0
            local cir2={fogTime=30,x=x,y=y,sprite=BulletSprites.crystal.blue,radius=2,speed=60,direction=dir,lifeFrame=300,extraUpdate={
                function(cir)
                    if cir.frame%30==29 then
                        num=num+1
                        for i=-1,1,2 do
                            local numRef=num
                            local follower=Circle{x=cir.x,y=cir.y,sprite=BulletSprites.crystal.blue,radius=2,speed=cir.speed,direction=cir.direction,lifeFrame=300,spriteTransparency=0.5,extraUpdate={
                                function(cirF)
                                    if cir.removed then
                                        return
                                    end
                                    cirF.spriteTransparency=math.clamp(cirF.spriteTransparency+0.05,0,1)
                                    cirF.direction=cir.direction
                                    local smooth=math.clamp(cirF.frame/20,0,1)
                                    cirF.x,cirF.y=Shape.rThetaPos(cir.x,cir.y,3*i*(numRef+smooth-1),cir.direction+math.pi*(1/2+1/4*i))
                                end
                            }}
                        end
                    end
                end
            }}
            BulletSpawner.wrapFogEffect(cir2,Circle,true)
        end
        Event.LoopEvent{
            obj=en,period=600,frame=240,executeFunc=function()
                SFX:play('enemyPowerfulShot',true)
                Event.EaseEvent{
                    obj=objEffect,easeFrame=360,aimKey='radius',aimValue=100,progressFunc=Event.sineBackProgressFunc
                }
                Event.EaseEvent{
                    obj=objEffect,easeFrame=360,aimKey='spriteTransparency',aimValue=0.5,progressFunc=Event.sineBackProgressFunc
                }
                BulletSpawner{x=obj.x,y=obj.y,period=1,lifeFrame=1,bulletNumber=18,bulletSpeed='150',bulletLifeFrame=300,warningFrame=20,fadingFrame=20,angle='0+999',range=math.pi*6,bulletSprite=BulletSprites.laserDark.blue,bulletSize=6,frequency=2,highlight=true,bulletEvents={
                    function(cir,args,self)
                        cir.direction=cir.direction+obj.direction
                        local index0=cir.parent.args.index
                        local index=math.ceil(index0/6)-2
                        local ts=self.frame
                        local t=math.clamp(ts/6,4,30)
                        Event.EaseEvent{
                            obj=cir,easeFrame=t,aimKey='radiusRef',aimValue=0,afterFunc=function()
                                cir:remove()
                            end,
                        }
                        Event.DelayEvent{
                            obj=cir,delayFrame=(-ts)%30,executeFunc=function()
                                if ts>100 and ts<250 and cir.frame>t-3 then
                                    -- for i=-1,1 do
                                    local toPlayer=Shape.toObj(cir,player)
                                    local dir=toPlayer+math.eval(0,0.7)
                                    if math.abs(math.modClamp(cir.direction-toPlayer))<math.pi/3 then
                                        packed(cir.x,cir.y,dir)
                                    end
                                    -- end
                                end
                            end
                        }
                        -- Event.EaseEvent{
                        --     obj=cir,easeFrame=t,aimKey='speed',aimValue=0,progressFunc=Event.sineOProgressFunc
                        -- }
                        Event.DelayEvent{
                            obj=cir,delayFrame=15,executeFunc=function()
                                cir.direction=cir.direction+math.pi/3*index
                            end
                        }
                    end},laserEvents={
                    function(laser)
                        Event.LoopEvent{
                            obj=laser,
                            period=1,
                            executeFunc=function(self)
                                laser.args.direction=laser.args.direction+0.003--*math.sin(laser.frame/10)
                                laser.toPlayer=Shape.toObj(laser,player)
                                laser.x,laser.y=obj.x,obj.y
                            end
                        }
                    end
                }}
            end
        }
        Event.LoopEvent{
            obj=obj,period=240,frame=120,executeFunc=function()
                local dir=Shape.toObj(obj,player)+math.eval(0,0.1)
                Event.LoopEvent{
                    obj=obj,period=1,times=180,executeFunc=function(self,time,maxTimes)
                        Shape.moveTowards(obj,dir,math.cos(time/maxTimes*math.pi/2)*0.7)
                    end
                }
            end
        }
    end
}