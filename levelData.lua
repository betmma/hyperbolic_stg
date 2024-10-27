BulletSpawner=require"bulletSpawner"

local levelData={
    {
        {
            make=function ()
                local en=Enemy{x=400,y=200}
                player=Player(400,600)
                local a=BulletSpawner{x=200,y=0,period=0.2,time=0,lifeTime=100,bulletNumber=10,bulletSpeed='40',angle='0+112',bulletSize=0.75,bulletSprite=BulletSprites.round.blue,bulletEvents={
                }}
                local a=BulletSpawner{x=600,y=0,period=0.2,time=0,lifeTime=100,bulletNumber=10,bulletSpeed='40',angle='0+112',bulletSize=0.75,bulletSprite=BulletSprites.round.blue,bulletEvents={
                }}
                local b=BulletSpawner{x=400,y=600,period=2,time=1,lifeTime=100,bulletNumber=60,bulletSpeed=1.5,bulletSize=0.75,bulletSprite=BulletSprites.star.red,bulletEvents={
                    function(cir,args)
                        local key=args.index
                        Event.LoopEvent{
                            obj=cir,
                            times=1,
                            period=0.5,
                            conditionFunc=function()return true end,
                            executeFunc=function(self)
                                Event.EaseEvent{
                                    obj=cir,
                                    easeTime=1,
                                    aimTable=cir,
                                    aimKey='speed',
                                    aimValue=0
                                }
                                Event.LoopEvent{
                                    obj=cir,
                                    times=1,
                                    period=1,
                                    conditionFunc=function()return true end,
                                    executeFunc=function(self)
                                        cir.direction=-math.pi/2
                                        cir.speed=20
                                end}
                        end}
                    end
                },
                spawnBatchFunc=function(self)
                    self.x=math.eval('400+10')
                    local num=math.eval(self.bulletNumber)
                    local angle=math.eval(self.angle)
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    for i = 1, num, 1 do
                        self:spawnBulletFunc{direction=i<=num/2 and 0 or math.pi,speed=math.abs(speed*(i-num/2)),radius=size,index=i}
                    end
                end}
            end
        },
        {
            make=function ()
                player=Player(400,600)
                local a=BulletSpawner{x=400,y=300,period=0.2,time=0,lifeTime=100,bulletNumber=10,bulletSpeed='20',bulletSize=0.75,bulletSprite=BulletSprites.crystal.blue,bulletEvents={
                }}
                Event{
                    obj=a,
                    executeFunc=function(self)
                        a.angle=(a.angle+a.time/50)%(2*math.pi)
                    end
                }
                local b=BulletSpawner{x=400,y=100,period=5,time=2,lifeTime=100,bulletNumber=30,bulletSpeed=6,bulletSize=0.75,bulletSprite=BulletSprites.kunai.gray,bulletEvents={
                    function(cir,args)
                        local key=args.index
                        Event.LoopEvent{
                            obj=cir,
                            times=1,
                            period=1,
                            conditionFunc=function()return true end,
                            executeFunc=function(self)
                                cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)
                                cir.speed=cir.speed+10
                        end}
                    end
                },
                spawnBatchFunc=function(self)
                    local num=math.eval(self.bulletNumber)
                    local angle=math.eval(self.angle)
                    local speed=math.eval(self.bulletSpeed)
                    local size=math.eval(self.bulletSize)
                    for i = 1, num, 1 do
                        self:spawnBulletFunc{direction=i<=num/2 and 0 or math.pi,speed=math.abs(speed*(i-num/2)),radius=size,index=i}
                    end
                end}
            end
        },
    }
}

return levelData