return {
    ID=182,
    user='marisa',
    spellName='Love Sign "Expanding Spark"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local a,b
        local en
        en=Enemy{x=400,y=600000,mainEnemy=true,maxhp=7200,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=1200000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=600000}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local function rotateBase(cir,sign)
            cir.forceDrawNormalSprite=true
            cir.spriteExtraDirection=math.eval(0,999)
            cir.sign=math.mod2Sign(sign) or 1
            cir.extraUpdate[#cir.extraUpdate+1]=function (self)
                self.spriteExtraDirection=self.spriteExtraDirection+math.pi/30*self.sign
            end
        end
        local playerRef
        a=BulletSpawner{x=center.x,y=center.y,period=1000,frame=-30,lifeFrame=10000,angle=0,bulletNumber=5,bulletLifeFrame=650,range=math.pi*2,bulletSprite=BulletSprites.explosion.yellow,bulletSize=1,highlight=true,bulletSpeed=60,bulletEvents={
            function(cir,args,self)
                local times=self.spawnEvent.executedTimes
                rotateBase(cir,times)
                cir.speed=cir.speed+math.eval(0,20)
                local hpLevel=en:getHPLevel()
                cir.direction=cir.direction+math.eval(0,hpLevel==1 and 0.014 or 0.005)
                cir.invincible=true
                Event.EaseEvent{
                    obj=cir,
                    easeFrame=100,
                    aimKey='speed',
                    aimValue=200
                }
                if hpLevel==2 then
                    local dir=Shape.toObj(cir,playerRef)
                    local x2,y2,dir2=Shape.rThetaPosT(cir.x,cir.y,Shape.distanceObj(cir,playerRef)*2,dir)
                    local cir2=Circle{x=x2,y=y2,sprite=cir.sprite,lifeFrame=cir.lifeFrame,highlight=true,direction=dir2-dir+cir.direction+math.pi,speed=cir.speed}
                    rotateBase(cir2,times)
                    Event.EaseEvent{
                        obj=cir2,
                        easeFrame=100,
                        aimKey='speed',
                        aimValue=200
                    } 
                end
            end
        }}
        Event.LoopEvent{
            obj=en,period=1,executeFunc=function ()
                local hpp=en.hp/en.maxhp
                local t=(en.frame+500)%300
                if t==240 then
                    SFX:play('enemyCharge')
                    Effect.Charge{x=en.x,y=en.y}
                end
                if t==0 then
                    SFX:play('enemyPowerfulShot')
                    a.spawnEvent.frame=0
                    a.spawnEvent.period=1
                    a.angle=Shape.toObj(a,player)
                    a.range=math.pi*0
                    -- Event.EaseEvent{
                    --     obj=a,aimKey='range',aimValue=math.pi*0.15,easeFrame=400
                    -- }
                    b=BulletSpawner{x=en.x,y=en.y,period=4,frame=0,lifeFrame=100,bulletNumber=math.ceil(10*(1-hpp)),bulletSpeed=120,bulletSprite=BulletSprites.bigStar.blue,highlight=true,angle='player',range=math.pi*2,bulletLifeFrame=1000,bulletEvents={
                        function(cir,args,self)
                            local times=self.spawnEvent.executedTimes
                            rotateBase(cir,times)
                            cir.speed=cir.speed+math.eval(0,60)
                            Event.DelayEvent{
                                obj=cir,delayFrame=10*times,executeFunc=function()
                                    if Shape.distanceObj(cir,player)>150 then
                                        cir.direction=Shape.toObj(cir,player)+math.eval(0,0.03)
                                    end
                                end
                            }
                            Event.EaseEvent{
                                obj=cir,
                                easeFrame=100,
                                aimKey='speed',
                                aimValue=40
                            }
                        end
                    }}
                    playerRef={x=player.x,y=player.y}
                    Event.LoopEvent{
                        obj=en,period=1,times=100,executeFunc=function()
                            Shape.moveTowards(en,playerRef,-5)
                            a.x,a.y=en.x,en.y
                            b.x,b.y=en.x,en.y
                            a.angle=Shape.toObj(a,playerRef)
                        end
                    }
                end
                if t==100 then
                    a.spawnEvent.period=1000
                    Event.LoopEvent{
                        obj=en,period=1,times=100,executeFunc=function(self)
                            local dis=Shape.distanceObj(en,player)
                            if dis>50 then
                                Shape.moveTowards(en,player,dis/20)
                                a.x,a.y=en.x,en.y
                            else
                                self:remove()
                            end
                        end
                    }
                end
            end
        }
    end
}