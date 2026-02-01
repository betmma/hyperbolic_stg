return {
    ID=28,
    user='cirno',
    spellName='',
    unlock=function()
        return Nickname.hasSecretNicknameForAct(2)
    end,
    make=function()
        G.levelRemainingFrame=5400
        local en=Enemy{x=400,y=200,mainEnemy=true,maxhp=7500}
        local player=Player{x=400,y=600}
        local tripwires={}
        local function connect(cir1,cir2)
            local laserUnit1=Laser.LaserUnit{x=cir1.x,y=cir1.y,sprite=BulletSprites.laserDark.blue,radius=0.5,speed=0,safe=true,spriteTransparency=0.5,invincible=true,lifeFrame=5400,extraUpdate=function(self)
                self.x,self.y=cir1.x,cir1.y
            end}
            local laserUnit2=Laser.LaserUnit{x=cir2.x,y=cir2.y,sprite=BulletSprites.laserDark.blue,radius=0.5,speed=0,safe=true,spriteTransparency=0.5,invincible=true,lifeFrame=5400,extraUpdate=function(self)
                self.x,self.y=cir2.x,cir2.y
            end}
            laserUnit1:connect(laserUnit2)
            tripwires[#tripwires+1]={cir1,cir2,laserUnit1,laserUnit2}
        end
        local function triggerBase(cir)
            cir.wireSides=cir.wireSides or {}
            for _,pair in ipairs(tripwires) do
                local cir1,cir2=pair[1],pair[2]
                local side=Shape.leftToLine(cir.x,cir.y,cir1.x,cir1.y,cir2.x,cir2.y)
                if cir.wireSides[pair]==nil then
                    cir.wireSides[pair]=side
                elseif side~=cir.wireSides[pair] then
                    local distance=Shape.distanceToSegment(cir.x,cir.y,cir1.x,cir1.y,cir2.x,cir2.y)
                    if distance<10 and not pair.resting then -- exclude outside of segment
                        SFX:play('enemyShot',true)
                        pair.resting=true
                        Event.EaseEvent{
                            obj=pair[3],aimKey='spriteTransparency',aimValue=1,easeFrame=20,progressFunc=Event.sineBackProgressFunc,afterFunc=function()
                                pair.resting=false
                            end
                        }
                        Event.EaseEvent{
                            obj=pair[3],aimKey='radius',aimValue=pair[3].radius*2,easeFrame=20,progressFunc=Event.sineBackProgressFunc
                        }
                        local points=Shape.segmentPoints(cir1.x,cir1.y,cir2.x,cir2.y,12,30)
                        for i=1,#points-1 do
                            local p=points[i]
                            local dir0=Shape.toObj(p,cir2)
                            local cir=Circle{x=p.x,y=p.y,direction=dir0+math.pi/2+math.pi/3*i,speed=0,lifeFrame=900,sprite=BulletSprites.crystalDark.blue,extraUpdate=function(cir)
                                cir.speed=cir.speed+0.5
                            end}
                        end
                    end
                    cir.wireSides[pair]=side
                end
            end
        end
        Event.DelayEvent{
            obj=en,delayFrame=60,executeFunc=function()
                SFX:play('enemyCharge')
                local points={}
                for i=1,6 do
                    local angle=math.pi/3*(i-1)
                    local cir=Circle{x=en.x,y=en.y,direction=angle,speed=60,sprite=BulletSprites.bigRound.blue,radius=1,lifeFrame=5400,spriteTransparency=0.5,safe=true,invincible=true}
                    Event.EaseEvent{
                        obj=cir,aimKey='speed',aimValue=0,easeFrame=160,
                    }
                    table.insert(points,cir)
                end
                for i=1,6 do
                    for j=i+1,6 do
                        connect(points[i],points[j])
                    end
                end
                Event.EaseEvent{
                    obj=en,aimKey='y',aimValue=150,easeFrame=120,afterFunc=function()
                        BulletSpawner{x=en.x,y=en.y,period=180,frame=180,lifeFrame=5400,bulletNumber=1,bulletSpeed=60,bulletLifeFrame=600,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.ellipse.blue,bulletExtraUpdate={triggerBase},bulletEvents={
                            function(cir,args,self)
                                if args.index==1 and self.spawnEvent.executedTimes%4==3 then
                                    SFX:play('enemyCharge',true)
                                    Effect.Charge{obj=en}
                                    self.bulletNumber=6
                                else
                                    self.bulletNumber=1
                                end
                                Event.EaseEvent{
                                    obj=cir,aimKey='speed',aimValue=0,easeFrame=240,progressFunc=Event.sineBackProgressFunc
                                }
                                Event.DelayEvent{
                                    obj=cir,
                                    delayFrame=120,
                                    executeFunc=function()
                                        cir.direction=Shape.toObj(cir,player)
                                    end
                                }
                            end
                        }}
                    end
                }
            end
        }
    end
}