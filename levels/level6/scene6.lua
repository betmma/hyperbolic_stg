return {
    ID=90,
    user='minamitsu',
    spellName='Heavy Sign "Weight of a Thousand Fathoms"',
    make=function()
        G.levelRemainingFrame=7200
        G.backgroundPattern:remove()
        -- G.backgroundPattern=BackgroundPattern.H3Terrain()
        Shape.removeDistance=1e100
        local en,a
        en=Enemy{x=400,y=600000,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=800000,noBorder=true}
        local center={x=400,y=600000}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,400,4))
        local largerBorder=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,720,4),false)
        player.moveMode=Player.moveModes.Natural
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        a=BulletSpawner{x=en.x,y=en.y,period=300,frame=250,lifeFrame=10000,bulletNumber=20,bulletSpeed=0,bulletLifeFrame=1000,angle=math.eval(0,999),range=math.pi*2,highlight=true,bulletSprite=BulletSprites.anchor,bulletEvents={
            function(cir,args,self)
                local index=args.index
                Event.EaseEvent{
                    obj=cir,aimKey='speed',aimValue=160,easeFrame=120
                }
                Event.LoopEvent{
                    obj=cir,period=1,times=1,conditionFunc=function()
                        return not player.border:inside(cir.x,cir.y)
                    end,
                    executeFunc=function()
                        SFX:play('enemyShot',true,0.7)
                        cir.speed=0
                        cir.direction=Shape.to(cir.x, cir.y, player.x, player.y)
                        Event.EaseEvent{
                            obj=cir,aimKey='speed',aimValue=80,easeFrame=300,progressFunc=Event.sineIOProgressFunc,
                        }
                        Event.LoopEvent{
                            obj=cir,period=10,times=30,executeFunc=function(self,times)
                                Circle{x=cir.x,y=cir.y,direction=cir.direction+0.1*math.mod2Sign(times),speed=cir.speed,lifeFrame=600,sprite=BulletSprites.rain.blue}
                            end
                        }
                    end
                }
            end
        },
        spawnBatchFunc=function(self)
            local times=self.spawnEvent.executedTimes
            if times%3==2 then
                SFX:play('enemyCharge',true,self.spawnSFXVolume)
                Effect.Charge{obj=a}
                Event.DelayEvent{
                    obj=self,delayFrame=60,executeFunc=function()
                        SFX:play('enemyPowerfulShot',true,0.7)
                        local large=Circle{x=self.x,y=self.y,direction=Shape.to(self.x,self.y,player.x,player.y),speed=0,radius=2,lifeFrame=1000,sprite=BulletSprites.anchor}
                        large.invincible=true
                        Event.EaseEvent{
                            obj=large,aimTable=large,aimKey='speed',aimValue=160,easeFrame=120
                        }
                        Event.LoopEvent{
                            obj=large,period=1,times=1,conditionFunc=function()
                                return not player.border:inside(large.x,large.y)
                            end,
                            executeFunc=function()
                                SFX:play('kill',true,1)
                                BulletSpawner{x=large.x,y=large.y,period=1,frame=0,lifeFrame=1,bulletNumber=500,bulletSpeed=25,bulletLifeFrame=10000,angle=0,spawnCircleRadius=10,spawnCircleAngle='0+999',bulletSprite=BulletSprites.lightRound.blue,highlight=true,bulletSize=1.5,bulletEvents={
                                    function(cir,args,self)
                                        if args.index%2==1 then
                                            cir.invincible=true
                                            cir:changeSpriteColor('purple')
                                        end
                                        Event.LoopEvent{
                                            obj=cir,period=1,times=1,conditionFunc=function()
                                                local isInside,x1,y1,x2,y2=largerBorder:inside(cir.x,cir.y)
                                                if not isInside then
                                                    local distance=Shape.distanceToLine(cir.x,cir.y,x1,y1,x2,y2)
                                                    if distance>20 then
                                                        return true
                                                    end
                                                end
                                            end,
                                            executeFunc=function()
                                                Event.EaseEvent{
                                                    obj=cir,aimTable=cir,aimKey='spriteTransparency',aimValue=0,easeFrame=90
                                                }
                                                Event.DelayEvent{
                                                    obj=cir,delayFrame=90,executeFunc=function()
                                                        cir:remove()
                                                    end
                                                }
                                            end
                                        }
                                    end
                                }}
                                large:remove()
                            end
                        }
                    end
                }
                return
            end
            local num=math.eval(self.bulletNumber)
            local range=math.eval(self.range)
            local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            for i = 1, num, 1 do
                Event.DelayEvent{
                    obj=self,delayFrame=i*2,executeFunc=function()
                        local direction=range*(i-0.5-num/2)/num+angle
                        local x,y=self.x,self.y
                        SFX:play('enemyShot',true,self.spawnSFXVolume)
                        self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed,radius=size,index=i,batch=self.bulletBatch,fogTime=self.fogTime,sprite=self.bulletSprite}
                    end
                }
            end
        end
        }
    end
}