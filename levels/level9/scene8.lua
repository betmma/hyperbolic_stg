return {
    ID=111,
    user='keiki',
    spellName='Triangular Shape "Triangle Creature"', 
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=3000
        local center={x=400,y=300}
        local a,b
        local en
        local flippingTriangle
        local player=Player{x=400,y=600}
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=10800,hpSegments={0.8,0.6,0.4,0.2},hpSegmentsFunc=function(self,hpLevel)
            SFX:play('enemyCharge',true)
            Effect.Shockwave{x=self.x,y=self.y,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove={bullet=true,invincible=hpLevel~=2}}
            a.spawnEvent.frame=a.spawnEvent.period-60
            en:addHPProtection(600,10)
            if hpLevel==1 then
                local points=Shape.regularPolygonCoordinates(center.x,center.y,30,3)
                Event.DelayEvent{
                    obj=en,delayFrame=60,executeFunc=function()
                        flippingTriangle(points[1],points[2],points[3],{center.x,center.y},BulletSprites.bigRound.blue,7,BulletSprites.round.blue,60,player)
                    end
                }
            elseif hpLevel==2 then
                b.spawnEvent.frame=b.spawnEvent.period-60
            elseif hpLevel==3 then
                local points=Shape.regularPolygonCoordinates(center.x,center.y,50,8)
                Event.DelayEvent{
                    obj=en,delayFrame=60,executeFunc=function()
                        flippingTriangle(points[1],points[2],points[5],{center.x,center.y},BulletSprites.bigRound.green,7,BulletSprites.round.green,30,player)
                    end
                }
            elseif hpLevel==4 then
                a.spawnEvent.period=9999
                b.spawnEvent.period=150
                b.spawnEvent.frame=b.spawnEvent.period-60
                b.bulletNumber=17
            end
        end}
        en:addHPProtection(600,10)
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,100,12))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        flippingTriangle=function (v1,v2,v3,startPoint,sprite,gap,smallSprite,movePeriod,aim)
            local vs={v1,v2,v3}
            local cirs={}
            for i=1,3 do
                local moveAim={x=vs[i][1],y=vs[i][2]}
                cirs[i]=Circle{x=startPoint[1],y=startPoint[2],lifeFrame=9999,speed=0,direction=0,sprite=sprite,invincible=true}
                local moveDistance=Shape.distance(cirs[i].x,cirs[i].y,moveAim.x,moveAim.y)
                Event.LoopEvent{
                    obj=cirs[i],period=1,times=10,executeFunc=function(self,times,maxTimes)
                        Shape.moveTowards(cirs[i],moveAim,moveDistance/maxTimes,true)
                        if times==maxTimes-1 then
                            cirs[i].x,cirs[i].y=moveAim.x,moveAim.y
                            cirs[i].initialized=true
                        end
                    end
                }
            end
            for i=1,3 do
                local va,vb=vs[i],vs[i%3+1]
                local distance=Shape.distance(va[1],va[2],vb[1],vb[2])
                local num=math.ceil(distance/gap)
                for j=1,num-1 do
                    local ratio=j/num
                    local nx,ny=Shape.lerp(cirs[i].x,cirs[i].y,cirs[i%3+1].x,cirs[i%3+1].y,ratio)
                    local cir=Circle{x=nx,y=ny,lifeFrame=9999,speed=0,direction=0,sprite=smallSprite,invincible=true,extraUpdate={
                        function(self)
                            if cirs[i].removed or cirs[i%3+1].removed then
                                self:remove()
                                return
                            end
                            self.x,self.y=Shape.lerp(cirs[i].x,cirs[i].y,cirs[i%3+1].x,cirs[i%3+1].y,ratio)
                        end
                    }}
                    
                end
            end
            local period=movePeriod or 30
            local isobj=type(aim)=='table'
            local isnumber=type(aim)=='number'
            local isrotate=type(aim)=='string'
            local flipiref=isrotate and 1 or nil
            Event.LoopEvent{
                obj=en,period=period,conditionFunc=function(self)
                    for i=1,3 do
                        if cirs[i].removed then
                            self:remove()
                            for j=1,3 do
                                if not cirs[j].removed then
                                    cirs[j]:remove()
                                end
                            end
                            return false
                        end
                        if not cirs[i].initialized then
                            return false
                        end
                    end
                    return true
                end,executeFunc=function()
                    local flipi=nil
                    local maxCos
                    for i=1,3 do
                        local cira,cirb,circ=cirs[i],cirs[i%3+1],cirs[(i+1)%3+1]
                        local flipx,flipy=Shape.reflectByLine(cira.x,cira.y,cirb.x,cirb.y,circ.x,circ.y)
                        if isnumber then
                            local dir=Shape.to(cira.x,cira.y,flipx,flipy)
                            local v12flip=Shape.to(v1[1],v1[2],flipx,flipy)
                            local flip2v1=Shape.to(flipx,flipy,v1[1],v1[2])
                            local cos=math.cos(dir-aim-(flip2v1-v12flip+math.pi))+math.eval(0,0.1)
                            if not maxCos or cos>maxCos then
                                maxCos=cos
                                flipi=i
                            end
                        elseif isobj then
                            local distance=Shape.distance(cira.x,cira.y,aim.x,aim.y)
                            local distance2=Shape.distance(flipx,flipy,aim.x,aim.y)
                            if distance2<distance then
                                flipi=i
                                break
                            end
                        end
                    end
                    if flipi or isrotate then
                        if isnumber and flipi==flipiref then
                            flipi=flipi%3+1
                        end
                        if isrotate then
                            flipi=flipiref%3+1
                        end
                        local cira,cirb,circ=cirs[flipi],cirs[flipi%3+1],cirs[(flipi+1)%3+1]
                        flipiref=flipi
                        local flipx,flipy=Shape.reflectByLine(cira.x,cira.y,cirb.x,cirb.y,circ.x,circ.y)
                        local moveAim={x=flipx,y=flipy}
                        local moveDistance=Shape.distance(cira.x,cira.y,moveAim.x,moveAim.y)
                        if period>20 then
                            SFX:play('enemyShot',true)
                        end
                        Event.LoopEvent{
                            obj=cira,period=1,times=period-1,executeFunc=function(self,times,maxTimes) -- without -1 new flip may start before the old one ends
                                Shape.moveTowards(cira,moveAim,moveDistance/maxTimes,true)
                                if times==maxTimes-1 then
                                    cira.x,cira.y=moveAim.x,moveAim.y
                                end
                            end
                        }
                    end
                end
            }
        end
        a=BulletSpawner{x=en.x,y=en.y,period=300,frame=250,lifeFrame=10000,bulletNumber=15,bulletSpeed=-120,bulletLifeFrame=10000,angle='player',range=math.pi,highlight=true,bulletSprite=BulletSprites.rim.red,fogEffect=true,fogTime=3,bulletEvents={
            function(cir,args,self)
                cir.invincible=true
                cir.speed=cir.speed+args.index*3+math.eval(0,40)
                Event.EaseEvent{
                    obj=cir,aimTable=cir,aimKey='speed',aimValue=0,easeFrame=50,progressFunc=function(x)return x^4 end,afterFunc=function()
                        local dir=math.eval(0,999)
                        local x2,y2=Shape.rThetaPos(cir.x,cir.y,15,dir)
                        local x3,y3=Shape.rThetaPos(cir.x,cir.y,15,dir+math.pi/3)
                        flippingTriangle({cir.x,cir.y},{x2,y2},{x3,y3}, {cir.x,cir.y},BulletSprites.round.red,6,BulletSprites.round.red,15,Shape.to(cir.x,cir.y,player.x,player.y)+math.eval(0,0.3))
                        cir:remove()
                    end
                }
            end
        }}
        local rand=false
        b=BulletSpawner{x=en.x,y=en.y,period=300,frame=-9999,lifeFrame=10000,bulletNumber=10,bulletSpeed=0,bulletLifeFrame=10000,angle='player',range=math.pi*0,highlight=true,bulletSprite=BulletSprites.rim.yellow,fogEffect=true,fogTime=3,bulletEvents={
            function(cir,args,self)
                cir.invincible=true
                cir.direction=cir.direction+math.pi/2
                local index=args.index
                cir.speed=cir.speed+(index-b.bulletNumber/2-0.5)*18*17/b.bulletNumber
                rand=math.eval(0,1)<0
                Event.EaseEvent{
                    obj=cir,aimTable=cir,aimKey='speed',aimValue=0,easeFrame=50,progressFunc=function(x)return x^4 end,afterFunc=function()
                        local dir=cir.direction
                        local triangleAngle=dir+math.eval(0,math.pi/3)
                        local hpLevel=en:getHPLevel()
                        local hp5rotatepi=false
                        if hpLevel==5 then
                            triangleAngle=dir
                            if rand then
                                hp5rotatepi=true
                                triangleAngle=triangleAngle+math.pi
                            end
                        end
                        local poses=Shape.regularPolygonCoordinates(cir.x,cir.y,10,3,triangleAngle)
                        local to=Shape.to(cir.x,cir.y,player.x,player.y)
                        local flip=math.cos(dir-math.pi/2-to)<0
                        local points={poses[3],poses[1],poses[2]}
                        if (flip and 1 or 0)+(hp5rotatepi and 1 or 0)==1 then
                            points={poses[1],poses[3],poses[2]}
                        end
                        local mode=hpLevel==5 and 'incr' or (dir-math.pi/2+(flip and math.pi or 0))
                        flippingTriangle(points[1],points[2],points[3], {cir.x,cir.y},BulletSprites.round.yellow,6,BulletSprites.round.yellow,30,mode)
                        cir:remove()
                    end
                }
            end
        }}

    end
}