return {
    ID=24,
    quote='not come up yet',
    user='cirno',
    spellName='Freeze Sign "Rime Ice"',
    make=function()
        local en=Enemy{x=400,y=50,mainEnemy=true,maxhp=4800}
        local player=Player{x=400,y=600}
        local circPeriod=5
        local circRad=60
        local a
        a=BulletSpawner{x=400,y=50,period=20,frame=0,lifeFrame=23000,bulletNumber=20,bulletSpeed=30,bulletLifeFrame=10000,angle='1.57+0.3',range=math.pi/2,bulletSprite=BulletSprites.rim.blue,fogEffect=true,fogTime=20,bulletEvents={
            function(cir,args,self)
                local speed=cir.speed
                -- cir.speed=0
                local limit=args.limit
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function()
                        if not cir.flag and cir.y<300 and math.abs(cir.direction-math.pi/2)>limit then
                            cir.direction=math.pi-(cir.direction+0.5*(math.pi/2-cir.direction))
                        end
                    end
                }
            end
            },
        spawnBatchFunc= function(self)
            local num=math.eval(self.bulletNumber)
            local range=math.eval(self.range)
            local angle=math.eval(-1.57,2)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            local limit=math.eval(0.4,0.2)
            for i = 1, num, 1 do
                local direction=range*(i-0.5-num/2)/num+angle
                local nx,ny=Shape.rThetaPos(self.x,self.y,circRad*i/num,angle)
                Event.DelayEvent{
                    obj=self,
                    delayFrame=circPeriod/num*i*range,
                    executeFunc=function()
                        if player.y<100 then
                            direction=Shape.to(nx,ny,player.x,player.y)
                        end
                        local cir=self:spawnBulletFunc{x=nx,y=ny,direction=direction,speed=speed,radius=size,index=i,batch=self.bulletBatch,limit=limit,sprite=self.bulletSprite}
                        if player.y<100 and cir then
                            cir.flag=true
                        end
                    end
                }
            end
        end
        }
        Event.LoopEvent{
            obj=a,
            period=1,
            executeFunc=function()
                a.x=a.x+math.min(a.frame/100,3)*math.eval(1,0.1)
                if a.x>650 then
                    a.x=a.x-500
                end
                en.x,en.y=a.x,a.y
                a.spawnEvent.period=(en.hp/en.maxhp)*10+10
            end
        }
    end
}