return {
    ID=189,
    user='marisa',
    spellName='Magic Sign "Sigil Automaton"',
    unlock=function()
        return Nickname.hasSecretNicknameForAct(8)
    end,
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local a,b
        local en
        en=Enemy{x=400,y=600000,mainEnemy=true,maxhp=9600,hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
        end}
        en:addHPProtection(1200,10)
        local player=Player{x=400,y=1200000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=600000}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        ---@type {points:{r:number,theta:number,dir:number}[],maxDistance:number,aveAngle:number}
        local sigil
        local freq,count=10,30
        local function startRecord()
            local center={x=player.x,y=player.y}
            sigil={points={},maxDistance=0,aveAngle=0}
            local natDir=player.naturalDirection
            local lastpos={x=player.x,y=player.y}
            Event.LoopEvent{
                obj=en,period=freq,times=count,executeFunc=function (self,times)
                    local pos={x=player.x,y=player.y}
                    local r=Shape.distanceObj(pos,center)
                    sigil.maxDistance=math.max(sigil.maxDistance,r)
                    local theta=Shape.toObj(center,pos)-natDir
                    local dir=Shape.toObj(pos,lastpos)
                    lastpos=pos
                    table.insert(sigil.points,{r=r,theta=theta,dir=dir})
                    sigil.aveAngle=sigil.aveAngle+theta/count
                    -- visual effect
                    local cir=Circle{x=pos.x,y=pos.y,speed=0,lifeFrame=freq*(count-times)+30,sprite=BulletSprites.star.white,highlight=true,spriteTransparency=0.3,safe=true,events={
                        function (cir)
                            Event.EaseEvent{
                                obj=cir,aimKey='spriteTransparency',aimValue=1,easeFrame=30,afterFunc=function()
                                    cir.safe=false
                                end
                            }
                        end,extraUpdate=Circle.FadeOut}}
                end
            }
        end
        local colors={'red','orange','yellow','green','blue','cyan','purple','magenta'}
        local colorIndex=1
        local function spawnSigil(x,y,direction,func,rzoom,delay,timeRatio)
            delay=delay or 30
            timeRatio=timeRatio or 0.2
            local color=colors[colorIndex]
            colorIndex=colorIndex%#colors+1
            local pen=Circle{x=en.x,y=en.y,direction=direction,speed=0,lifeFrame=freq*timeRatio*count+delay,sprite=BulletSprites.bigStar[color],highlight=true,safe=true,spriteTransparency=0.5}
            Shape.moveToInTime(pen,{x=x,y=y},delay)
            local points=sigil.points
            local rRatio=1
            if rzoom then
                rRatio=rzoom/sigil.maxDistance
            end
            for i=1,#points do
                Event.DelayEvent{
                    delayFrame=freq*(i-1)*timeRatio+delay,
                    executeFunc=function()
                        local args=points[i]
                        local x1,y1,dir1=Shape.rThetaPosT(x,y,args.r*rRatio,args.theta+direction)
                        Shape.moveToInTime(pen,{x=x1,y=y1},freq*timeRatio)
                        if Shape.distance(x1,y1,player.x,player.y)<15 then -- avoid spawn on player
                            return
                        end
                        local cir=Circle{x=x1,y=y1,direction=dir1,speed=0,lifeFrame=600,sprite=BulletSprites.star[color],highlight=true,spriteTransparency=0.3,events={
                            function (cir)
                                Event.EaseEvent{
                                    obj=cir,aimKey='spriteTransparency',aimValue=1,easeFrame=30,afterFunc=function()
                                        cir.safe=false
                                    end
                                }
                                if func then 
                                    Event.DelayEvent{
                                        delayFrame=freq*timeRatio*(#points-i+1)+delay+20,executeFunc=function()
                                            func(cir,i,args.dir+direction)
                                        end
                                    }
                                end
                            end,extraUpdate=Circle.FadeOut}}
                    end
                }
            end
        end
        local followUpdate=function(cir)
            if not cir.center or cir.center.removed then
                return
            end
            cir.x,cir.y,cir.direction=Shape.rThetaPosT(cir.center.x,cir.center.y,cir.distance,cir.angle+cir.center.direction+cir.center.frame*(cir.center.rotateSpeed or 0))
        end
        local spawns={
            -- easy homing, move in straight line
            function()
                for i=1,8 do
                    local x,y,dir=Shape.rThetaPosT(player.x,player.y,50,math.pi/4*(i-1))
                    spawnSigil(x,y,dir,function(cir)
                        cir.direction=Shape.toObj(cir,player)
                        cir.speed=40
                    end)
                end
            end,
            -- go in ə shape, all bullets will move away
            function()
                local angle=math.eval(0,999)
                for i=-1,1,2 do
                    local x1,y1,dir1=Shape.rThetaPosT(player.x,player.y,50,angle+math.pi/2*i)
                    for j=-8,8 do
                        local x2,y2,dir2=Shape.rThetaPosT(x1,y1,j*15,dir1+math.pi/2)
                        spawnSigil(x2,y2,dir2,function(cir,i)
                            cir.direction=cir.direction+math.pi/16*i
                            cir.speed=20
                        end)
                    end
                end
            end,
            -- move around in small circles, then move outwards fast
            function()
                local angle=math.eval(0,999)
                local n,m,k=5,3,1
                for i=1,40 do
                    local theta=math.pi/20*i
                    local r=math.cos((2*math.asin(k)+math.pi*m)/2/n)/math.cos((2*math.asin(k*math.cos(n*theta))+math.pi*m)/2/n)*100
                    local x,y,dir=Shape.rThetaPosT(player.x,player.y,r,theta+angle)
                    local center
                    spawnSigil(x,y,dir+math.pi*(0.5+0.1*math.sign(math.sin(n*theta)))-sigil.aveAngle,function(cir,i,dir)
                        cir.speed=30
                        if i==1 then
                            center=cir
                            cir.frame=0
                            cir.lifeFrame=200+i*10
                            cir.rotateSpeed=math.pi/60
                            cir.direction=Shape.toObj(cir,player)
                        elseif center then
                            cir.center=center
                            cir.distance=Shape.distanceObj(cir,center)
                            cir.angle=Shape.toObj(center,cir)-center.direction
                            cir.extraUpdate={followUpdate}
                        end
                    end,50,10,0.3)
                end
            end,
            function()
                local points=sigil.points
                local cx,cy=player.x,player.y
                for i=1,#points do
                    local args=points[i]
                    local x,y,dir=Shape.rThetaPosT(cx,cy,args.r,args.theta)
                    spawnSigil(x,y,args.dir+i*math.pi/30,function(cir,i)
                        cir.direction=cir.direction+math.pi
                        cir.speed=i*2
                    end)
                end
            end
        }
        Event.LoopEvent{
            obj=en,period=600,frame=590,executeFunc=function(self,times)
                Effect.Charge{obj=player,animationFrame=30,particleFrame=10,particleSize=2}
                Event.DelayEvent{
                    delayFrame=30,executeFunc=function()
                        startRecord()
                    end
                }
                Event.DelayEvent{
                    delayFrame=freq*count+30,executeFunc=function()
                        SFX:play("enemyPowerfulShot")
                    end
                }
                Event.DelayEvent{
                    delayFrame=freq*count+60,executeFunc=function()
                        spawns[times%#spawns+1]()
                    end
                }
            end
        }
    end
}