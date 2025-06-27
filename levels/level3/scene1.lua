return {
    ID=132,
    user='seiran',
    spellName='Bullet Sign "Eagle\'s Volley Fire"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1000
        local a,b
        local en
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
        -- en:addHPProtection(600,10)
        local player=Player{x=400,y=600,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        a=BulletSpawner{x=400,y=300,period=350,frame=10,lifeFrame=10000,bulletNumber=10,bulletSpeed=70,bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bullet.cyan,fogEffect=true,spawnSFXVolume=1,bulletEvents={
            function(cir,args,self)
            end
        },spawnBatchFunc=function(self)
            SFX:play('enemyShot',true,self.spawnSFXVolume)
            local num=math.eval(self.bulletNumber)
            local range=math.eval(self.range)
            local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            for index=1,num do
                local direction=range*(index-0.5-num/2)/num+angle
                for i=1,10,1 do
                    for j = 1, i, 1 do
                        local x,y,dir=Shape.rThetaPosT(self.x,self.y,2*(j-i/2-0.499),direction+math.pi/2)
                        dir=dir+math.pi/2
                        Event.DelayEvent{
                            delayFrame=i*5+(index*3%10)*15,
                            executeFunc=function()
                                self:spawnBulletFunc{x=x,y=y,direction=dir,speed=speed,radius=size,index=i,batch=self.bulletBatch,fogTime=15,sprite=self.bulletSprite}
                            end
                        }
                    end
                end
            end
        end}
        b=BulletSpawner{x=400,y=300,period=10,frame=-50,lifeFrame=10000,bulletNumber=20,bulletSpeed=80,bulletLifeFrame=1500,angle=math.eval(0,999),range=math.pi*2,bulletSprite=BulletSprites.bigRound.white,highlight=true,bulletEvents={
            function(cir,args,self)
                if args.index==1 then
                    b.bulletSpeed=b.bulletSpeed+(1-en.hp/en.maxhp)*10
                    if b.spawnEvent.executedTimes%15==14 then 
                        b.spawnEvent.frame=-50
                        b.angle=math.eval(0,999)
                        b.bulletSpeed=80
                    end
                end
                Event.EaseEvent{
                    obj=cir,
                    easeFrame=50,
                    aimKey='speed',
                    aimValue=0,
                    afterFunc=function()
                        -- Circle{x=cir.x,y=cir.y,lifeFrame=1,sprite=BulletSprites.fog.white,speed=0}
                        cir:changeSprite(BulletSprites.scale.red)
                        cir.direction=cir.direction+math.pi*0.7*math.mod2Sign(args.index)
                        cir.speed=50
                    end,
                }
            end
        }}

        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                if a.spawnEvent.frame==a.spawnEvent.period-60 then
                    SFX:play('enemyCharge')
                end
                if en.frame%200==199 then
                    SFX:play('enemyShot',true,0.5)
                    local x,y=Shape.rThetaPos(center.x,center.y,math.eval(30,30),math.eval(0,999))
                    Event.LoopEvent{
                        obj=en,period=1,
                        times=100,
                        executeFunc=function ()
                            Shape.moveTowards(en,{x=x,y=y},0.6,true)
                            a.x,a.y=en.x,en.y
                            b.x,b.y=en.x,en.y
                        end
                    }
                end
            end
        }
    end
}