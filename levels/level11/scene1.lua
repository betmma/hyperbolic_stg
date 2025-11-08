return {
    ID=27,
    quote='??',
    user='yukari',
    spellName='Barrier "Boundary of Monad and Dyad"', 
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local en=Enemy{x=400,y=300000,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300000}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local a
        local rs={r1=30,r2=50}
        local function teleportBase(cir)
            Event.LoopEvent{
                obj=cir,
                period=1,
                times=1,
                conditionFunc=function()
                    return Shape.distance(cir.x,cir.y,en.x,en.y)>rs.r1
                end,
                executeFunc=function()
                    local angle=Shape.to(en.x,en.y,cir.x,cir.y)
                    local d1=angle-Shape.to(cir.x,cir.y,en.x,en.y)-math.pi
                    local dTrans=Shape.to(player.x,player.y,en.x,en.y)-Shape.to(en.x,en.y,player.x,player.y)+math.pi
                    cir.x,cir.y=Shape.rThetaPos(player.x,player.y,rs.r2,angle+dTrans)
                    local d2=Shape.to(cir.x,cir.y,player.x,player.y)-(angle+dTrans)
                    cir.direction=cir.direction+d1+d2+dTrans
                    -- cir:changeSpriteColor('blue')
                    cir.teleported=true
                end
            }
        end
        local function pattern1()
            Event.EaseEvent{
                obj=en,
                aimTable=rs,
                aimKey='r1',
                aimValue=60,
                easeFrame=60,
                afterFunc=function()
                    Event.DelayEvent{
                        obj=en,
                        period=80,
                        executeFunc=function()
                            SFX:play('enemyPowerfulShot',true)
                        Event.EaseEvent{
                            obj=en,
                            aimTable=rs,
                            aimKey='r1',
                            aimValue=15,
                            easeFrame=40
                        }
                    end}
                end
            }
            Event.EaseEvent{
                obj=en,
                aimTable=rs,
                aimKey='r2',
                aimValue=50,
                easeFrame=60
            }
            Event.LoopEvent{
                obj=en,
                period=30,
                times=6,
                executeFunc=function(self,times)
                    BulletSpawner{x=en.x,y=en.y,period=1,frame=0,lifeFrame=1,bulletNumber=60,bulletSpeed=70-times*10,bulletLifeFrame=1000,angle=times*math.pi/3,range=math.pi*30+1,bulletSprite=BulletSprites.billDark.red,spawnSFXVolume=1,highlight=true,bulletEvents={
                        function(cir,args,self)
                            Event.EaseEvent{
                                obj=cir,
                                aimTable=cir,
                                aimKey='speed',
                                aimValue=0,
                                easeFrame=120,
                            }
                            Event.DelayEvent{
                                obj=cir,
                                delayFrame=240-times*30,
                                executeFunc=function()
                                Event.EaseEvent{
                                    obj=cir,
                                    aimTable=cir,
                                    aimKey='speed',
                                    aimValue=80,
                                    easeFrame=120,
                                }
                            end}
                            teleportBase(cir)
                        end
                    }}
                end
            }
        end
        local function pattern2(sign)
            sign=sign or 1
            Event.EaseEventBatch{
                obj=en,
                aimTable=rs,
                aimKeys={'r1','r2'},
                aimValues={50,50},
                easeFrames={30,30}
            }
            Event.EaseEvent{
                obj=en,
                aimTable=en,
                aimKey='speed',
                aimValue=80,
                easeFrame=280,
                progressFunc=Event.sineBackProgressFunc,
            }
            local x0,y0=en.x,en.y
            local dir=Shape.to(x0,y0,player.x,player.y)-math.pi/2*sign
            en.direction=dir
            Event.LoopEvent{
                obj=en,
                period=1,
                times=280,
                executeFunc=function(self,times)
                    en.direction=en.direction+math.pi/100*sign
                    if times>40 and times<240 then
                        BulletSpawner{x=en.x,y=en.y,period=1,frame=0,lifeFrame=1,bulletNumber=4,bulletSpeed=60,bulletLifeFrame=1000,angle=times*math.pi/3*sign,range=math.pi*30+1,bulletSprite=BulletSprites.billDark.blue,highlight=true,bulletEvents={
                            function(cir,args,self)
                                Event.EaseEvent{
                                    obj=cir,
                                    aimTable=cir,
                                    aimKey='speed',
                                    aimValue=0,
                                    easeFrame=120,
                                }
                                Event.DelayEvent{
                                    obj=cir,
                                    delayFrame=120,
                                    executeFunc=function()
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='speed',
                                        aimValue=40,
                                        easeFrame=120,
                                    }
                                end}
                                teleportBase(cir)
                            end
                        }}
                    end
                end
            }
        end
        local function pattern3(sign)
            sign=sign or 1
            local x0,y0=en.x,en.y
            local dir=Shape.to(x0,y0,player.x,player.y)
            SFX:play('enemyPowerfulShot',true)
            a=BulletSpawner{x=en.x,y=en.y,period=2,frame=-30,lifeFrame=170,bulletNumber=2,bulletSpeed=160,bulletLifeFrame=1000,angle=Shape.to(en.x,en.y,player.x,player.y),range=math.pi*6.1,bulletSprite=BulletSprites.billDark.magenta,bulletEvents={
                function(cir,args,self)
                    Event.EaseEvent{
                        obj=cir,
                        aimTable=cir,
                        aimKey='speed',
                        aimValue=0,
                        easeFrame=30,
                    }
                    teleportBase(cir)
                    Event.LoopEvent{
                        obj=cir,
                        period=1,
                        times=1,
                        conditionFunc=function()
                            return cir.teleported
                        end,
                        executeFunc=function(self,times)
                            cir.speed=30
                        end
                    }
                end
            }}
            Event.LoopEvent{
                obj=en,
                period=1,
                times=400,
                executeFunc=function(self,times)
                    local distance=Shape.distance(en.x,en.y,player.x,player.y)
                    rs.r1=math.clamp(distance,rs.r1-1,rs.r1+1)
                    rs.r2=math.clamp(distance,rs.r2-1,rs.r2+1)
                    if times<200 then
                        a.angle=a.angle+math.pi/17*sign
                        a.bulletSpeed=math.sin(times/51*math.pi)*60+160
                        en.x,en.y=Shape.rThetaPos(x0,y0,-math.cos(times/50*math.pi)*10+10,dir+times/17*math.pi*sign)
                        a.x,a.y=en.x,en.y
                    end
                end
            }
            Event.DelayEvent{
                obj=en,
                period=400,
                executeFunc=function()
                    SFX:play('enemyPowerfulShot',true)
                    Event.EaseEventBatch{
                        obj=en,
                        aimTable=rs,
                        aimKeys={'r1','r2'},
                        aimValues={15,20},
                        easeFrames={40,40}
                    }
            end}
        end
        local function pattern4()
            SFX:play('enemyPowerfulShot',true)
            Event.EaseEventBatch{
                obj=en,
                aimTable=rs,
                aimKeys={'r1','r2'},
                aimValues={130,60},
                easeFrames={30,30}
            }
            Event.DelayEvent{
                obj=en,
                period=30,
                executeFunc=function()
                    Event.EaseEvent{
                        obj=en,
                        aimTable=rs,
                        aimKey='r2',
                        aimValue=130,
                        easeFrame=240,
                        progressFunc=Event.sineBackProgressFunc,
                    }
                end
            }
            local a
            a=BulletSpawner{x=en.x,y=en.y,period=2,frame=-30,lifeFrame=240,bulletNumber=6,bulletSpeed=80,bulletLifeFrame=1000,angle=Shape.to(en.x,en.y,player.x,player.y),range=math.pi*6.1,bulletSprite=BulletSprites.billDark.orange,bulletEvents={
                function(cir,args,self)
                    if args.index==1 then
                        a.angle=a.angle+math.pi*4/17
                    end
                    Event.EaseEventBatch{
                        obj=cir,
                        aimTable=cir,
                        aimKeys={'speed','direction'},
                        aimValues={0,cir.direction+math.sin(a.frame/20)},
                        easeFrames={200+math.sin(a.frame/30)*80,200},
                    }
                    teleportBase(cir)
                    Event.DelayEvent{
                        obj=cir,
                        delayFrame=300-a.frame,
                        executeFunc=function()
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=40,
                            easeFrame=120,
                        }
                    end}
                end
            }}
        end
        local function pattern5()
            SFX:play('enemyPowerfulShot',true)
            Event.EaseEventBatch{
                obj=en,
                aimTable=rs,
                aimKeys={'r1','r2'},
                aimValues={100,60},
                easeFrames={30,30}
            }
            local a
            a=BulletSpawner{x=en.x,y=en.y,period=80,frame=-30,lifeFrame=240,bulletNumber=60,bulletSpeed=40,bulletLifeFrame=1000,angle='0+999',range=math.pi*1.9,bulletSprite=BulletSprites.billDark.teal,bulletEvents={
                function(cir,args,self)
                    teleportBase(cir)
                end
            }}
        end
        local patterns={pattern1,pattern2,pattern3,pattern4,pattern5}
        local current=0
        Event.LoopEvent{
            obj=en,
            period=600,
            frame=540,
            executeFunc=function()
                local index=math.random(1,#patterns)
                if index==current then
                    index=index%#patterns+1
                end
                current=index
                patterns[index](math.randomSign())
            end
        }
        Event.DelayEvent{
            obj=en,
            period=30,
            executeFunc=function()
                SFX:play('enemyPowerfulShot',true)
                local drawRef=en.draw
                en.draw=function(self)
                    local colorref={love.graphics.getColor()}
                    love.graphics.setColor(1,0,0,0.3)
                    Shape.drawCircle(en.x,en.y,rs.r1,'fill')
                    love.graphics.setColor(0,0,1,0.3)
                    Shape.drawCircle(player.x,player.y,rs.r2,'fill')
                    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4] or 1)
                    drawRef(self)
                end
            end
        }
    end
}