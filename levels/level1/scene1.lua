return {
    ID=11,
    quote="In this world things appear smaller when closer to top.",
    user='doremy',
    dialogue='doremyDialogue1_1',
    spellName='Magic Sign "Otherworld Star Dust"',
    make=function ()
        local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=4800}
        local player=Player{x=400,y=600}
        local a=BulletSpawner{x=150,y=0,period=12,frame=-1800,lifeFrame=10000,bulletNumber=10,bulletSpeed='40',angle='0+112',bulletSprite=BulletSprites.round.blue,bulletEvents={
        }}
        local a=BulletSpawner{x=650,y=0,period=12,frame=-1800,lifeFrame=10000,bulletNumber=10,bulletSpeed='40',angle='0+112',bulletSprite=BulletSprites.round.blue,bulletEvents={
        }}
        local b=BulletSpawner{x=400,y=630,period=120,frame=60,lifeFrame=10000,bulletNumber=36,bulletSpeed=2.5,bulletSprite=BulletSprites.star.red,bulletEvents={
            function(cir,args)
                local key=args.index
                Event.LoopEvent{
                    obj=cir,
                    times=1,
                    period=30,
                    conditionFunc=function()return true end,
                    executeFunc=function(self)
                        Event.EaseEvent{
                            obj=cir,
                            easeFrame=60,
                            aimTable=cir,
                            aimKey='speed',
                            aimValue=0,
                            afterFunc=function(self)
                                cir.direction=-math.pi/2
                                cir.speed=20
                            end
                        }
                end}
            end
        },
        spawnBatchFunc=function(self)
            self.x=math.eval(400,10)
            local num=math.eval(self.bulletNumber)
            local angle=math.eval(self.angle)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            for i = 1, num, 1 do
                self:spawnBulletFunc{direction=i<=num/2 and 0 or math.pi,speed=math.abs(speed*(i-num/2)),radius=size,index=i}
            end
        end}
    end
}