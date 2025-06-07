return {
    ID=91,
    user='minamitsu',
    spellName='Drowning Sign "Double Vortex"',
    make=function()
        -- solution: use side shot, toggle naturalDirection to near 0 and dodge by moving vertically
        G.levelRemainingFrame=7200
        Shape.removeDistance=2500
        local en,a
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200,hpSegments={0.75,0.5,0.25},hpSegmentsFunc=function(self,hpLevel)
            SFX:play('enemyCharge',true)
            -- Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            -- a.spawnEvent.frame=a.spawnEvent.period-60
            en:addHPProtection(300,10)
        end}
        en:addHPProtection(300,10)
        local player=Player{x=400,y=600,noBorder=true}
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        player.moveMode=Player.moveModes.Natural
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        a=BulletSpawner{x=en.x,y=en.y,period=300,frame=250,lifeFrame=10000,bulletSpeed=10,bulletLifeFrame=1000,angle=math.pi/2,range=math.pi*2,highlight=true,fogEffect=true,bulletSprite=BulletSprites.rain.cyan,bulletEvents={
            function(cir,args,self)
                local index=args.index
                Event.EaseEvent{
                    obj=cir,aimKey='speed',aimValue=60,easeFrame=300
                }
            end
        },
        spawnBatchFunc=function(self)
            SFX:play('enemyShot',true,1)
            local waveTimes=en:getHPLevel()
            local num=5+1*waveTimes
            local angle=self.angle
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            local spawnCircleAngle0=math.eval(0,0.1)+math.pi/2
            for ri=1,30,1 do
                local spawnCircleAngle=spawnCircleAngle0+math.eval(0,0.1)
                for i = 1, num, 1 do
                    local ratio=(i-num/2)/num*2
                    local angle1=math.pi*math.sign(ratio)*(math.abs(ratio))^0.5+spawnCircleAngle
                    local x,y=Shape.rThetaPos(player.x,player.y,ri^0.5*30,angle1)
                    local direction=Shape.to(x,y,player.x,player.y)-Shape.to(player.x,player.y,x,y)+math.pi+angle
                    self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed,radius=size,index=i,batch=self.bulletBatch,fogTime=ri*3,sprite=self.bulletSprite}
                    x,y=Shape.rThetaPos(player.x,player.y,ri^0.5*30,angle1+math.pi)
                    self:spawnBulletFunc{x=x,y=y,direction=direction+math.pi+player.naturalDirection,speed=speed/2,radius=size,index=i,batch=self.bulletBatch,fogTime=ri*3,sprite=BulletSprites.rain.blue}
                end
            end
            local colors={'green','yellow','orange','red'}
            local toPlayer0=Shape.to(en.x,en.y,player.x,player.y)
            local dis0=30
            if math.sin(toPlayer0)<0 then
                dis0=dis0+15
            end
            local x0,y0=Shape.rThetaPos(en.x,en.y,dis0,toPlayer0-math.pi*1/4)
            local num=20
            for waveIndex=1,waveTimes-1 do
                local xn,yn=Shape.rThetaPos(en.x,en.y,dis0+20*waveIndex,toPlayer0-math.pi*(math.mod2Sign(waveIndex)*1/4))
                local dir=Shape.to(x0,y0,xn,yn)
                local distance=Shape.distance(x0,y0,xn,yn)
                local color=colors[waveIndex]
                for i=1,num do
                    local di=distance*(i-0.5)/num
                    local x,y=Shape.rThetaPos(x0,y0,di,dir)
                    local toPlayerDir=Shape.to(x,y,player.x,player.y)
                    Event.DelayEvent{
                        obj=self,delayFrame=waveIndex*num+i,executeFunc=function()
                            if i==1 then
                                SFX:play('enemyShot',true,1)
                            end
                            BulletSpawner{x=x,y=y,period=1,lifeFrame=2,bulletNumber=3,range=math.eval(3,3),angle=toPlayerDir+(i-num/2)*0.05*math.mod2Sign(waveIndex+1)+0*math.eval(0,waveIndex*0.15),bulletSpeed={45-5*waveIndex,10},bulletLifeFrame=1000,bulletSprite=BulletSprites.rain[color]}
                        end
                    }
                end
                x0,y0=xn,yn
            end
        end
        }
    end
}