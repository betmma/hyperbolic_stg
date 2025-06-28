return {
    ID=44,
    quote='Her ancient memory about leaving somewhere to find mysterious ingredient.',
    user='nareko',
    spellName='Obstructing Sign "Distant Memory"',
    make=function()
        G.levelRemainingFrame=4800
        G.levelIsTimeoutSpellcard=true
        Shape.removeDistance=2000
        local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=72000000}
        Event.EaseEvent{
            obj=en,
            aimTable=en,
            aimKey='y',
            aimValue=-50,
            easeFrame=100
        }
        local player=Player{x=400,y=300}
        local hitEffectRef=player.hitEffect
        player.hitEffect=function(player,damage)
            hitEffectRef(player,damage)
            Event.EaseEvent{
                obj=player,
                aimTable=player,
                aimKey='x',
                aimValue=400,
                easeFrame=10
            }
            Event.EaseEvent{
                obj=player,
                aimTable=player,
                aimKey='y',
                aimValue=300,
                easeFrame=10
            }
        end
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
        local safeAngle=0
        local safeWidth=math.pi/6
        local a
        a=BulletSpawner{x=400,y=300,period=1200,frame=1199,lifeFrame=10000,bulletNumber=500,bulletSpeed=0,bulletLifeFrame=1200,angle='0+999',spawnCircleRadius=0,range=math.pi*2,invincible=true,bulletSprite=BulletSprites.ellipse.blue,fogEffect=true,fogTime=20,
        spawnBatchFunc=function(self)
            local ind=a.spawnEvent.executedTimes
            SFX:play('enemyShot',true,self.spawnSFXVolume)
            local num=math.eval(self.bulletNumber)
            local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            for i = 1, num, 1 do
                local ii=i^0.5*num^0.5
                local direction=angle+ii*0.04*(ind%2*2-1)
                local x,y=Shape.rThetaPos(self.x,self.y,ii/num*70+10,direction)
                self.fogTime=math.ceil(ii/num*120)
                self:spawnBulletFunc{x=x,y=y,direction=direction+1.5,speed=speed,radius=size,index=i,batch=self.bulletBatch,fogTime=self.fogTime}
                if(ind>0 and i%(12-2*ind)==0) then
                    self:spawnBulletFunc{x=x,y=y,direction=direction+math.pi+ind*0.1,speed=5,radius=size,index=i,sprite=self.bulletSprite,fogTime=self.fogTime}
                end
                
            end
        end,
        bulletEvents={
            function(cir,args,self)
                local speedRef=cir.speed
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=1000-cir.args.fogTime,
                    executeFunc=function()
                        cir.grazed=true
                        cir.damage=2
                        cir.sprite=BulletSprites.ellipse.purple
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=Shape.distance(cir.x,cir.y,400,300),
                            easeFrame=100,
                            progressFunc=Event.sineOProgressFunc,
                        }
                        cir.direction=Shape.to(cir.x,cir.y,400,300)
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=100,
                            executeFunc=function()
                                -- cir.sprite=BulletSprites.ellipse.red
                                -- cir.damage=1
                                cir.speed=90
                                cir.direction=cir.args.index/a.bulletNumber*(math.pi*2-safeWidth/2)+safeAngle+safeWidth/2
                            end
                        }
                    end
                }
            end
        }
        }
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local fr=en.frame%1200
                if fr==2 then
                    safeAngle=math.eval(0,3.14)
                    Circle{x=400,y=300,direction=safeAngle,speed=30,sprite=BulletSprites.fog.blue,invincible=true,safe=true,lifeFrame=2000,}
                end
                if fr==1190 then
                    Event.EaseEvent{
                        obj=en,
                        aimTable=player,
                        aimKey='x',
                        aimValue=400,
                        easeFrame=10
                    }
                    Event.EaseEvent{
                        obj=en,
                        aimTable=player,
                        aimKey='y',
                        aimValue=300,
                        easeFrame=10
                    }
                end
            end
        }

    end
}