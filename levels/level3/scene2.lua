return {
    ID=133,
    user='seiran',
    spellName='Bullet Sign "Eagle\'s Big Shot"',
    make=function()
        -- more interesting than expected. thought similar to junko's shivering star, actually 2 ways to solve: first stand aside to first bullet, cuz center column of bullets form straight line and all other columns are moving away. second is stay at 2 (or 10) o'clock, when last few rows come, move through tilted passage.
        G.levelRemainingFrame=7200
        Shape.removeDistance=10000
        local a,b
        local en
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=6000}
        -- en:addHPProtection(600,10)
        local player=Player{x=400,y=600,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        a=BulletSpawner{x=400,y=300,period=600,frame=440,lifeFrame=10000,bulletNumber=1,bulletSpeed=30,bulletLifeFrame=1000,angle='player',range=math.pi*2,bulletSprite=BulletSprites.bullet.cyan,fogEffect=true,spawnSFXVolume=1,bulletEvents={
            function(cir,args,self)
            end
        },spawnBatchFunc=function(self)
            SFX:play('enemyShot',true,self.spawnSFXVolume)
            local num=math.eval(self.bulletNumber)
            local range=math.eval(self.range)
            local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            local x0,y0=self.x,self.y
            for index=1,num do
                local direction=range*(index-0.5-num/2)/num+angle
                for i=1,20,1 do
                    for j = 1, i, 1 do
                        local x,y,dir=Shape.rThetaPosT(x0,y0,4*(j-i/2-0.499),direction+math.pi/2)
                        dir=dir-math.pi/2
                        local x0ref,y0ref=x0,y0
                        Event.DelayEvent{
                            delayFrame=i*3,
                            executeFunc=function()
                                self:spawnBulletFunc{x=x,y=y,direction=dir,speed=speed,radius=size,index=i,batch=self.bulletBatch,fogTime=15,sprite=self.bulletSprite}
                                a.x,a.y=x0ref,y0ref
                                en.x,en.y=x0ref,y0ref
                            end
                        }
                    end
                    x0,y0,direction=Shape.rThetaPosT(x0,y0,-4,direction)
                end
            end
        end}
        local bo=0
        b=BulletSpawner{x=400,y=300,period=10000,frame=-50,lifeFrame=10000,bulletNumber=20,bulletSpeed=120,bulletLifeFrame=600,angle=math.eval(0,999),range=math.pi*2,bulletSprite=BulletSprites.bigRound.white,highlight=true,bulletEvents={
            function(cir,args,self)
                cir.invincible=true
                local offset=(bo)/200
                if args.index==1 then
                    bo=bo+1
                end
                Event.EaseEvent{
                    obj=cir,
                    easeFrame=50,
                    aimKey='speed',
                    aimValue=0,
                }
                Event.DelayEvent{
                    obj=cir,delayFrame=50+bo*10,executeFunc=function()
                        cir:changeSprite(BulletSprites.scale.purple)
                        cir.direction=cir.direction+math.pi*(0.2+offset)*math.mod2Sign(args.index)
                        cir.speed=80
                        Circle{x=cir.x,y=cir.y,lifeFrame=100,sprite=cir.sprite,speed=cir.speed,direction=cir.direction+0.2}
                        Circle{x=cir.x,y=cir.y,lifeFrame=100,sprite=cir.sprite,speed=cir.speed,direction=cir.direction-0.2}
                    end
                }
            end
        }}

        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local t=(en.frame+520)%600
                if t==540 then
                    SFX:play('enemyCharge')
                end
                if t==480 then
                    local x,y=Shape.rThetaPos(center.x,center.y,math.eval(30,30),math.eval(0,999))
                    Event.LoopEvent{
                        obj=en,period=1,
                        times=120,
                        executeFunc=function ()
                            Shape.moveTowards(en,{x=x,y=y},Shape.distance(en.x,en.y,x,y)/60,true)
                            a.x,a.y=en.x,en.y
                            b.x,b.y=en.x,en.y
                        end
                    }
                end
                if t==0 then
                    b.angle=math.eval(0,999)
                    bo=0
                    b.spawnEvent.frame,b.spawnEvent.period=0,1
                end
                if t==40 then
                    b.spawnEvent.period=10000
                    Event.LoopEvent{
                        obj=en,period=1,
                        times=40,
                        executeFunc=function ()
                            Shape.moveTowards(en,player,-2,true)
                            a.x,a.y=en.x,en.y
                            b.x,b.y=en.x,en.y
                        end
                    }
                end
            end
        }
    end
}