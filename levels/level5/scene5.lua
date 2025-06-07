return {
    ID=16,
    quote='not come up yet',
    user='yuugi',
    spellName='Manacles Sign "Manacles a Criminal Can\'t Take Off"',
    make=function()
        local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=4800}
        local player=Player{x=400,y=600}
        local a=BulletSpawner{x=400,y=150,period=300,frame=240,lifeFrame=10000,bulletNumber=15,bulletSpeed='60',bulletLifeFrame=100,angle='1.17+3.14',bulletSprite=BulletSprites.laser.blue,bulletEvents={
            function(cir)
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function()
                        local t=cir.frame%120
                        if t<30 then
                            cir.direction=cir.direction+0.12
                        elseif t>=60 and t<90 then
                            cir.direction=cir.direction-0.12
                        end
                    end
                }
            end
        }}
        local a
        a=BulletSpawner{x=400,y=150,period=300,frame=240,lifeFrame=10000,bulletNumber=35,bulletSpeed='480',bulletLifeFrame=200,warningFrame=60,fadingFrame=20,angle='1.57+0.54',range=math.pi,bulletSprite=BulletSprites.laser.red,highlight=true,laserEvents={
            function(laser)
                Event.LoopEvent{
                    obj=laser,
                    period=1,
                    executeFunc=function(self)
                        self.obj.args.direction=self.obj.args.direction+(a.spawnEvent.executedTimes%2==1 and 1 or -1)*0.0005*(2-en.hp/en.maxhp)
                    end
                }
            end
        }}
    end
}