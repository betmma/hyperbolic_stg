return {
    ID=14,
    quote='Moving through this "square" grid is so difficult.',
    user='nemuno',
    spellName='Blade Exhaustion Sign "Killing Grid"',
    make=function()
        local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=4800,speed=2}
        Event.LoopEvent{
            obj=en,
            period=300,
            frame=270,
            executeFunc=function()
                Effect.Charge{obj=en,x=en.x,y=en.y,animationFrame=90}
            end
        }
        local a=BulletSpawner{x=400,y=300,period=300,frame=180,lifeFrame=10000,bulletNumber=0,bulletSpeed=10,angle='0+9999',bulletSprite=BulletSprites.knife.red,fogEffect=true,fogTime=60,bulletEvents={
            function(cir,args)
                local spd=cir.speed
                cir.speed=0
                Event.EaseEvent{
                    obj=cir,
                    aimTable=cir,
                    aimKey='speed',
                    aimValue=spd,
                    easeFrame=60
                }
            end
        },
        spawnBatchFunc=function(self)
            SFX:play('enemyShot',true,1)
            local num=math.eval(self.bulletNumber)
            local range=math.eval(self.range)
            local angle=math.eval(self.angle)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            local angle2=Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y)
            -- local nx,ny
            local inum=6
            local player=Player.objects[1]
            -- Shape.timeSpeed=0
            local dashDirection=angle2+math.pi/2*(self.spawnEvent.executedTimes%2==1 and 1 or -1)
            local dashAmount=4
            en.x,en.y=Shape.rThetaPos(en.x,en.y,-2*dashAmount,dashDirection)
            for ii=1,inum,1 do
                for i = 1, num, 1 do
                    local direction=range*(i-0.5-num/2)/num+angle
                    local radi=i/num*100+(-1)^ii*ii*0.2
                    local angle3=angle2
                    -- nx,ny=self.x+radi*math.cos(angle2),self.y+radi*math.sin(angle2)
                    Event.DelayEvent{
                        obj=self,
                        delayFrame=i+ii*3,
                        executeFunc=function(self)
                            if i==num and ii==inum then
                                -- Shape.timeSpeed=1
                            end
                            local angle3=angle2+math.pi/60*(ii-inum/2)
                            local x,y=Shape.rThetaPos(self.obj.x,self.obj.y,radi,angle3)
                            self.obj:spawnBulletFunc{x=x,y=y,direction=direction+ii*0.1,speed=speed,radius=size,index=i}
                            if i==1 then
                                en.x,en.y=Shape.rThetaPos(en.x,en.y,dashAmount,dashDirection)
                            end
                        end
                    }
                end
            end
        end
        }
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                en.direction=Shape.to(en.x,en.y,Player.objects[1].x,Player.objects[1].y)
                a.x=en.x;a.y=en.y
                a.bulletNumber=10+math.floor(10*(1-en.hp/en.maxhp))
                if Shape.distance(a.x,a.y,Player.objects[1].x,Player.objects[1].y)<10 and a.frame%30==0 then
                    local num
                    local range=math.eval(a.range)
                    local angle=math.eval(a.angle)
                    local speed=math.eval(a.bulletSpeed)
                    local size=math.eval(a.bulletSize)
                    local angle2=Shape.to(a.x,a.y,Player.objects[1].x,Player.objects[1].y)
                    num=30
                    for ii = 1, num, 1 do
                        local direction=range*(ii)/num+angle-math.pi/2
                        local radi=50
                        local angle3=angle2+ii/num*math.pi*2
                        -- nx,ny=self.x+radi*math.cos(angle2),self.y+radi*math.sin(angle2)
                        Event.DelayEvent{
                            obj=a,
                            delayFrame=ii/10,
                            executeFunc=function(self)
                                self.obj:spawnBulletFunc{x=self.obj.x+radi*math.cos(angle3),y=self.obj.y+radi*math.sin(angle3),direction=direction+ii*0.1,speed=2*speed,radius=size,index=ii}
                            end
                        }
                    end
                end
            end
        }
        local player=Player{x=400,y=600}
        local b=BulletSpawner{x=400,y=300,period=6000,frame=5940,lifeFrame=6001,bulletNumber=10,bulletSpeed=10,angle='0+9999',bulletLifeFrame=990000 ,bulletSprite=BulletSprites.bigRound.red,fogEffect=true,bulletEvents={
            function(cir,args)
                local spd=cir.speed
                cir.speed=0
                Event.EaseEvent{
                    obj=cir,
                    aimTable=cir,
                    aimKey='speed',
                    aimValue=spd,
                    easeFrame=60
                }
            end
        },
        spawnBatchFunc=function(self)
            local num=math.eval(self.bulletNumber)
            local range=math.eval(self.range)
            local angle=math.eval(self.angle)
            local angle2=self.angle2 or math.pi/-6
            self.angle2=(self.angle2 or 0)+math.pi/6
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            local sideNum=3
            -- local nx,ny
            for x0=150,650,50 do
                for y0=50,600,50 do
                    self:spawnBulletFunc{x=x0,y=y0,direction=0,speed=0,radius=size/(y0-Shape.axisY)*500,invincible=true,highlight=true}
                end
            end
        end
        }
    end
}