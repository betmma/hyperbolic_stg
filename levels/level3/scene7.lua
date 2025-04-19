return {
    quote='A creative use of her absolute power to destroy everything...',
    user='flandre',
    spellName='Forbidden Barrage "Border break"',
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=1000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600}
        player.moveMode=player.moveModes.Natural
        player.border:remove()
        local poses={}
        local indexes={}
        for i = 1, 12, 1 do
            local nx,ny=Shape.rThetaPos(400,300,110,math.pi/6*(i-.5))
            table.insert(poses,{nx,ny})
            table.insert(indexes,i)
        end
        local posesCopy=copy_table(poses)
        local indexesCopy=copy_table(indexes)
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local theta=math.eval(0,999)
        Event.LoopEvent{
            period=500,
            frame=470,
            obj=en,
            executeFunc=function()
                local hpp=en.hp/en.maxhp
                local removePointsNum=6+math.ceil(3*(1-hpp))
                -- local toRemove=math.randomSample(poses,removePointsNum)
                indexes=copy_table(indexesCopy)
                local afterRemoveIndexes={}
                for i=1,12 do
                    local removeIndex=math.random(1,#indexes)
                    local point=poses[indexes[removeIndex]]
                    table.remove(indexes,removeIndex)
                    if i==removePointsNum then
                        afterRemoveIndexes=copy_table(indexes)
                    end
                    Event.DelayEvent{
                        delayFrame=20*(i<=removePointsNum and i or 12),
                        executeFunc=function()
                            BulletSpawner{x=en.x,y=en.y,period=1,frame=0,lifeFrame=2,bulletNumber=30,bulletSpeed=15,bulletLifeFrame=10000,angle=math.eval(0,999),bulletSprite=BulletSprites.kunai.red,
                            spawnBatchFunc=function(self)
                                SFX:play('enemyShot',true,self.spawnSFXVolume)
                                local num=math.eval(self.bulletNumber)
                                local range=math.eval(self.range)
                                local angle=Shape.to(self.x,self.y,point[1],point[2])
                                local speed=math.eval(self.bulletSpeed)
                                local size=math.eval(self.bulletSize)
                                for j = 1, num, 1 do
                                    local direction=angle
                                    local x,y=self.x,self.y
                                    self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed+j*3,radius=size,index=j,batch=self.bulletBatch}
                                end
                                angle=theta+i*13203.216
                                for j = 1, num, 1 do
                                    local direction=range*(j-0.5-num/2)/num+angle
                                    local x,y=self.x,self.y
                                    self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed+i*3,radius=size,index=j,batch=self.bulletBatch}
                                end
                            end
                            }
                            Event.DelayEvent{
                                delayFrame=60,
                                executeFunc=function()
                                    local angle=math.eval(0,999)
                                    local bulletEvent=function(cir)
                                        cir.safe=true
                                        cir.spriteTransparency=0
                                        Event.EaseEvent{
                                            obj=cir,aimTable=cir,aimKey='spriteTransparency',aimValue=0.5,easeFrame=90,
                                            afterFunc=function ()
                                                cir.spriteTransparency=1
                                                cir.safe=false
                                            end
                                        }
                                    end
                                    BulletSpawner{x=point[1],y=point[2],period=1,frame=0,lifeFrame=2,bulletNumber=20,bulletSpeed=25,bulletLifeFrame=10000,angle=angle,bulletSprite=BulletSprites.giant.red,highlight=true,bulletEvents={bulletEvent}
                                    }
                                    if hpp<0.75 then
                                        BulletSpawner{x=point[1],y=point[2],period=1,frame=0,lifeFrame=2,bulletNumber=60,bulletSpeed=18,bulletLifeFrame=10000,angle=angle,bulletSprite=BulletSprites.round.red,highlight=true,bulletEvents={bulletEvent}
                                        }
                                    end
                                    if hpp<0.45 then
                                        BulletSpawner{x=point[1],y=point[2],period=1,frame=0,lifeFrame=2,bulletNumber=60,bulletSpeed=20,bulletLifeFrame=10000,angle=angle,bulletSprite=BulletSprites.round.red,highlight=true,bulletEvents={bulletEvent}
                                        }
                                    end
                                    table.remove(poses,removeIndex)
                                    if i<=removePointsNum then
                                        player.border:remove()
                                        player.border=PolyLine(poses)
                                    end
                                    if i==12 then
                                        local ev
                                        ev=Event.LoopEvent{
                                            period=1,
                                            obj=en,
                                            times=150,
                                            executeFunc=function()
                                                player.border:remove()
                                                -- poses=copy_table(posesCopy)
                                                poses={}
                                                for i = 1, 12, 1 do
                                                    local nx,ny=Shape.rThetaPos(400,300,110+150*(1-math.sin(ev.executedTimes/150*math.pi/2)),math.pi/6*(i-.5)+theta+ev.executedTimes/150)
                                                    table.insert(poses,{nx,ny})
                                                end
                                                posesCopy=poses
                                                player.border=PolyLine(poses)
                                            end
                                        }
                                    end
                                end
                            }
                        end
                    }
                end
                
                local newPoses={}
                for k,v in pairs(afterRemoveIndexes) do
                    table.insert(newPoses,posesCopy[v])
                end
                local newPolyline=PolyLine(newPoses,false)
                for x = -100, 900, 25 do
                    for y = 0, 1000, 25 do
                        if newPolyline:inside(x,y) then
                            local ci=Circle{x=x,y=y,direction=0,speed=0,sprite=BulletSprites.fog.red,invincible=true,safe=true,lifeFrame=200,batch=Asset.bulletHighlightBatch,radius=1.5/(y-Shape.axisY)*500,spriteTransparency=0}
                            Event.EaseEvent{
                                obj=ci,
                                aimTable=ci,
                                aimKey='spriteTransparency',
                                aimValue=0.1,
                                easeFrame=200,
                                progressFunc=function(x)return math.sin(x*math.pi) end
                            }
                        end
                    end
                end
                newPolyline:remove()
                Effect.Charge{obj=en,x=en.x,y=en.y}

            end
        }
    end
}