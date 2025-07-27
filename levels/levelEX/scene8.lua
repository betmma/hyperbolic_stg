return {
    ID=102,
    quote='Koto Sign ""',
    user='yatsuhashi',
    spellName='', 
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local en,a
        local phases={}
        en=Enemy{x=400,y=300000,mainEnemy=true,maxhp=8400,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
            en.frame=0
            phases[hpLevel+1]()
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300000}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        
        local dpitch={4,2,1,4,1}
        local pitches={0.5}
        for i=1,12 do
            pitches[i+1]=pitches[i]*2^(dpitch[(i-1)%#dpitch+1]/12)
        end
        
        local lines={}
        local function lineBind(line,obj,createBulletFunc)
            local laser,pitchIndex,audio=line.laser,line.pitchIndex,line.audio
            local x1,y1,x2,y2=laser.x,laser.y,laser.next.x,laser.next.y
            local side=Shape.leftToLine(obj.x,obj.y,x1,y1,x2,y2)
            Event.LoopEvent{
                obj=laser,period=1,executeFunc=function()
                    if laser.spriteTransparency<0.9 then -- fading in
                        return
                    end
                    local xp,yp=obj.x,obj.y
                    local x1,y1,x2,y2=laser.x,laser.y,laser.next.x,laser.next.y
                    local dis=Shape.distanceToSegment(xp,yp,x1,y1,x2,y2)
                    local newSide=Shape.leftToLine(xp,yp,x1,y1,x2,y2)
                    if laser.flip then
                        newSide=not newSide
                    end
                    if newSide~=side and dis<5 then
                        love.audio.stop(audio)
                        audio:play()
                        local near=Shape.nearestToLine(xp,yp,x1,y1,x2,y2)
                        createBulletFunc(near[1],near[2],pitchIndex)
                    end
                    side=newSide
                end
            }
        end
        local function lineBindAll(obj,createBulletFunc)
            for i=1,#lines do
                lineBind(lines[i],obj,createBulletFunc)
            end
        end
        local function lineRemoveAll()
            for i=1,#lines do
                lines[i].laser.next:remove()
                lines[i].laser:remove()
            end
            lines={}
        end

        local function line(x1,y1,x2,y2,radius,pitchIndex)
            pitchIndex=pitchIndex or 7
            local dir12=Shape.to(x1,y1,x2,y2)
            local laser1=Laser.LaserUnit{x=x1,y=y1,direction=dir12,radius=radius,speed=0,safe=true,lifeFrame=8800,sprite=BulletSprites.laser.red}
            local dir21=Shape.to(x2,y2,x1,y1)
            local laser2=Laser.LaserUnit{x=x2,y=y2,direction=dir21+math.pi,radius=radius,speed=0,safe=true,lifeFrame=8800,sprite=BulletSprites.laser.red}
            laser1.meshLimit,laser2.meshLimit=30,30
            laser1.last=false
            laser1.next=laser2
            laser2.previous=laser1
            laser1.spriteTransparency=0.1
            Event.EaseEvent{
                obj=laser1,easeFrame=40,aimKey='spriteTransparency',aimValue=1,
            }
            local pitch=pitches[pitchIndex]
            SFX.data.koto:setPitch(pitch)
            lines[#lines+1]={laser=laser1,pitchIndex=pitchIndex,audio=SFX.data.koto:clone()}
            lineBind(lines[#lines],player,function(x,y,pitchIndex)
                local pitch=pitches[pitchIndex]
                BulletSpawner{x=x,y=y,period=1,lifeFrame=1,bulletNumber=math.floor(30/pitch),bulletSpeed=0,spawnSFXVolume=0,bulletSprite=BulletSprites.note.red,bulletEvents={
                    function(cir)
                        cir.spriteExtraDirection=math.pi
                        cir.safe=true
                        cir.spriteTransparency=0.2
                        Event.EaseEvent{
                            obj=cir,
                            easeFrame=20,
                            aimKey='spriteTransparency',
                            aimValue=1,
                            afterFunc=function()
                                cir.safe=false
                                cir.speed=20*pitch
                            end,
                        }
                    end
                }}
            end)
        end
        local function bridge(x,y)
            local cir=Circle{x=x,y=y,radius=1,lifeFrame=8800,sprite=BulletSprites.bigRound.red,speed=0,direction=0,invincible=true,safe=true,spriteTransparency=0.1}
            Event.EaseEvent{
                obj=cir,
                easeFrame=40,
                aimKey='spriteTransparency',
                aimValue=1,
                afterFunc=function()
                    cir.safe=false
                end,
            }
            return cir
        end

        local function koto1(xc,yc,dir)
            local points={}
            -- 13 strings, border extends 1
            for i=-7,7 do
                local xa,ya,dira=Shape.rThetaPosT(xc,yc,15*i,dir)
                local x1,y1=Shape.rThetaPos(xa,ya,100,dira-math.pi/2)
                local x2,y2=Shape.rThetaPos(xa,ya,100,dira+math.pi/2)
                points[i+8]={x1,y1}
                points[-(i+8)+31]={x2,y2}
                if math.abs(i)~=7 then
                    -- bridge
                    local x3,y3=Shape.rThetaPos(xa,ya,10*i,dira+math.pi/2)
                    bridge(x3,y3)
                    line(x1,y1,x3,y3,0.5,-i+7)
                    line(x3,y3,x2,y2,0.5,i+7)
                end
            end
            local oldBorder=player.border
            Event.EaseEvent{
                obj=oldBorder,easeFrame=40,aimKey='spriteTransparency',aimValue=0,
                afterFunc=function()
                    oldBorder:remove()
                end
            }
            player.border=PolyLine(points)
            player.border.spriteTransparency=0.1
            Event.EaseEvent{
                obj=player.border,easeFrame=40,aimKey='spriteTransparency',aimValue=1,
            }
        end
        local xa,ya,xb,yb,dira,dirb
        local halfDis=260
        local function koto2(xc,yc,dir)
            local points={}
            -- 2 straight lines
            xa,ya,dira=Shape.rThetaPosT(xc,yc,-105,dir)
            local x1,y1=Shape.rThetaPos(xa,ya,halfDis,dira-math.pi/2)
            local x2,y2=Shape.rThetaPos(xa,ya,halfDis,dira+math.pi/2)
            points[1]={x1,y1}
            points[4]={x2,y2}
            xb,yb,dirb=Shape.rThetaPosT(xc,yc,105,dir)
            x1,y1=Shape.rThetaPos(xb,yb,halfDis,dirb-math.pi/2)
            x2,y2=Shape.rThetaPos(xb,yb,halfDis,dirb+math.pi/2)
            points[2]={x1,y1}
            points[3]={x2,y2}
            -- 13 strings
            for i=-6,6 do
                local x1,y1=Shape.rThetaPos(xa,ya,i*40,dira+math.pi/2)
                local x2,y2=Shape.rThetaPos(xb,yb,i*40,dirb+math.pi/2)
                -- bridge
                local dis=Shape.distance(x1,y1,x2,y2)
                local x3,y3=Shape.rThetaPos(x1,y1,dis*(0.5+0.05*i),Shape.to(x1,y1,x2,y2))
                bridge(x3,y3)
                line(x1,y1,x3,y3,0.5,-i+7)
                line(x3,y3,x2,y2,0.5,i+7)
            end
            local oldBorder=player.border
            Event.EaseEvent{
                obj=oldBorder,easeFrame=40,aimKey='spriteTransparency',aimValue=0,
                afterFunc=function()
                    oldBorder:remove()
                end
            }
            player.border=PolyLine(points)
            player.border.spriteTransparency=0.1
            Event.EaseEvent{
                obj=player.border,easeFrame=40,aimKey='spriteTransparency',aimValue=1,
            }
        end
        
        local hpp,hpLevel=1,1
        phases={function()
            lineRemoveAll()
            koto1(20000,500000,0)
        end,
        function()
            lineRemoveAll()
            local pos=Shape.nearestToLine(player.x,player.y,20000,500000,20000,400000)
            koto2(pos[1],pos[2],0)
            Event.LoopEvent{
                obj=en,period=1,times=60,executeFunc=function()
                    Shape.moveTowards(en,{x=pos[1],y=pos[2]},Shape.distance(en.x,en.y,pos[1],pos[2])/20,true)
                    a.x,a.y=en.x,en.y
                end
            }
            a.angle=a.angle+math.pi/2
            a.spawnEvent.period=180
            a.spawnEvent.frame=120
        end,
        function()
            lineRemoveAll()
            
            a.spawnEvent.period=180000
            for i=-6,6 do
                local x1,y1=Shape.rThetaPos(xa,ya,i*40,dira+math.pi/2)
                local x2,y2=Shape.rThetaPos(xb,yb,i*40,dirb+math.pi/2)
                line(x1,y1,x2,y2,0.5,-i+7)
                local laser1,laser2=lines[#lines].laser,lines[#lines].laser.next
                -- bridge
                local dis=Shape.distance(x1,y1,x2,y2)
                local x3,y3=Shape.rThetaPos(x1,y1,dis*(0.5+0.05*i),Shape.to(x1,y1,x2,y2))
                local cir=bridge(x3,y3)
                Event.LoopEvent{
                    obj=cir,period=1,executeFunc=function()
                        local x1,y1,x2,y2=laser1.x,laser1.y,laser2.x,laser2.y
                        local dis=Shape.distance(x1,y1,x2,y2)
                        local x3,y3=Shape.rThetaPos(x1,y1,dis*(0.5+0.05*i),Shape.to(x1,y1,x2,y2))
                        cir.x,cir.y=x3,y3
                    end
                }
                -- line(x1,y1,x3,y3,0.5,-i+7)
                -- line(x3,y3,x2,y2,0.5,i+7)
            end
            for i=1,#lines do
                local laser1,laser2=lines[i].laser,lines[i].laser.next
                local p1=player.border.points[1]
                local p2=player.border.points[2]
                local ps={p1,p2}
                for i,laser in pairs({laser1,laser2}) do
                    local p=ps[i]
                    -- local x0,y0=laser.x,laser.y
                    -- local base=Shape.nearestToLine(x0,y0,p1.x,p1.y,p2.x,p2.y)
                    -- base={x=base[1],y=base[2]}
                    Event.LoopEvent{
                        obj=laser,period=1,executeFunc=function()
                            Shape.moveTowards(laser,p,-math.min(1,en.frame/240))
                            local dis=Shape.distanceObj(laser,p)
                            if dis>halfDis*2+1 then
                                Shape.moveTowards(laser,p,halfDis*2+1)
                                laser.flip=not laser.flip
                            end
                        end
                    }
                end
            end
        end
        }
        phases[1]()

        a=BulletSpawner{x=en.x,y=en.y,period=360,frame=300,lifeFrame=9999,bulletNumber=1,bulletLifeFrame=500,range=math.pi*2,angle=math.pi/2,bulletSpeed=30,spawnSFXVolume=0.3,bulletSprite=BulletSprites.bigRound.blue,bulletEvents={
            function(cir,args)
                cir.invincible=true
                cir.direction=cir.direction+math.mod2Sign(a.spawnEvent.executedTimes)*math.pi/2
                lineBindAll(cir,function(x,y,pitchIndex)
                    local pitch=pitches[pitchIndex]
                    BulletSpawner{x=x,y=y,period=1,lifeFrame=1,bulletNumber=20,spawnCircleRadius=20*pitch,bulletSpeed=0,spawnSFXVolume=0,bulletSprite=BulletSprites.note.blue,bulletEvents={
                        function(cir)
                            cir.spriteExtraDirection=math.pi
                            cir.safe=true
                            cir.spriteTransparency=0.2
                            Event.EaseEvent{
                                obj=cir,
                                easeFrame=20,
                                aimKey='spriteTransparency',
                                aimValue=1,
                                afterFunc=function()
                                    cir.safe=false
                                    cir.direction=Shape.toObj(cir,player)+math.eval(0,0.12)
                                    cir.speed=40/pitch
                                end,
                            }
                        end
                    }}
                end)
            end
        },bulletExtraUpdate={
            -- function(cir)
            --     cir.direction=cir.direction+math.eval(0,0.03)
            --     cir.speed=cir.speed*0.98+20*0.02
            -- end
        }}
        Event.LoopEvent{
            obj=en,period=1,executeFunc=function()
                hpp=en.hp/en.maxhp
                hpLevel=en:getHPLevel()
            end
        }
    end
}