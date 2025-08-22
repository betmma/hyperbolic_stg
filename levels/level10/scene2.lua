return {
    ID=114,
    user='asama',
    spellName='Crowd Sign "Bitstream"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=3000
        local center={x=400,y=300}
        local a,b
        local en
        local player=Player{x=400,y=600}
        local hpLevel=1
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=10800,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel0)
            SFX:play('enemyCharge',true)
            Effect.Shockwave{x=self.x,y=self.y,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove={bullet=true,invincible=true,safe=true}}
            en:addHPProtection(600,10)
            hpLevel=hpLevel+1
            a.frame=a.period-60
        end}
        en:addHPProtection(600,10)
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,100,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local function stream(cir,mod,rem,solidNum,time,speed,inverse)
            time=time or 0
            speed=speed or 0.7
            local distance=140
            local num=50
            local color=cir.sprite.data.color
            for i=0,num-1 do
                local dist1=distance*2*(i/num-0.5)
                local x,y=Shape.rThetaPos(cir.x,cir.y,dist1,cir.direction+math.pi/2)
                local bullet=Circle{x=x,y=y,speed=0,lifeFrame=1000,sprite=BulletSprites.ellipse[color],spriteTransparency=0,extraUpdate={
                    function(self)
                        self.dist=(self.dist or dist1)-speed
                        self.x,self.y,self.direction=Shape.rThetaPosT(cir.x,cir.y,self.dist*(inverse and -1 or 1),cir.direction+math.pi/2)
                        if self.dist<=-distance then
                            self.dist=self.dist+distance*2
                            i=i+num
                        end
                        local disCenter=Shape.distanceObj(self,center)
                        local isSolid=(i-rem)%mod<solidNum
                        self.spriteTransparency=(isSolid and 1 or 0.4)*math.clamp((120-disCenter)*0.1,0,1)*math.clamp((self.frame-time)/60,0,1)
                        -- self.radius=(isSolid and 1 or 1)
                        self.safe=not (isSolid and self.frame>(60+time)) 
                        self.hpLevel=self.hpLevel or hpLevel
                        if self.hpLevel<hpLevel then
                            self:remove()
                        end
                    end
                }}
            end
        end
        local colors={}
        for i,j in pairs(BulletSprites.ellipse) do
            table.insert(colors,i)
        end
        local colorIndex=1
        local function mergeStream(cir,N,pack)
            pack=pack or 1
            local color=colors[colorIndex]
            colorIndex=(colorIndex+4)%#colors+1
            local inverse=math.random()<0.5
            local alignTime=400
            BulletSpawner{x=cir.x,y=cir.y,period=1,lifeFrame=1,bulletNumber=math.ceil(N/pack),bulletSpeed=0,bulletLifeFrame=1000,bulletSprite=BulletSprites.arrow[color],safe=true,invincible=true,spawnCircleRadius=40,spawnCircleAngle='0+999',angle=math.pi,bulletEvents={
            function(subcir,args,self)
                subcir.spriteTransparency=0
                subcir.deltaDir=math.eval(0,1.2+(hpLevel-1)*0.5)
                subcir.direction=cir.direction+subcir.deltaDir
                subcir.dist=Shape.distanceObj(cir,subcir)
                subcir.angle=Shape.toObj(cir,subcir)
                stream(subcir,N,(args.index-1)*pack,pack,math.eval(30,30),nil,inverse)
            end},bulletExtraUpdate={
                function(subcir)
                    if cir.frame<=alignTime then
                        subcir.direction=cir.direction+subcir.deltaDir*(1-cir.frame/alignTime)
                        subcir.x,subcir.y=Shape.rThetaPos(cir.x,cir.y,subcir.dist*(1-cir.frame/alignTime),subcir.angle)
                    else
                        if cir.frame==alignTime+1 then
                            SFX:play('enemyShot',true,2)
                        end
                        subcir.x,subcir.y,subcir.direction=cir.x,cir.y,cir.direction
                    end
                end
            }}
        end
        local data={{3,4,2},{3,3,1},{3,4,1}}
        a=Event.LoopEvent{
            obj=en,period=200,frame=170,executeFunc=function(self,times,maxTimes)
                SFX:play('enemyShot',true,2)
                local hpLevel=en:getHPLevel()
                local count,N,pack=unpack(data[hpLevel])
                -- if times<2 then
                --     count=count-1
                -- end
                count=1
                for i=1,count do
                    local dir=math.eval(0,999)
                    local x,y,t=Shape.rThetaPosT(en.x,en.y,math.eval(20,20),dir)
                    local main=Circle{x=x,y=y,speed=3,direction=t+math.pi,lifeFrame=1000,sprite=BulletSprites.heart.purple,invincible=true,safe=true,spriteTransparency=0}
                    mergeStream(main,N,pack)
                    Event.EaseEvent{
                        obj=main,aimKey='speed',aimValue=10,easeFrame=300
                    }
                end
            end
        }
    end
}