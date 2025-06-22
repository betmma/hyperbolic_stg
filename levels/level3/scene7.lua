return {
    ID=137,
    quote='?',
    user='eika',
    spellName='Stack Sign "Stone Bloxx"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=4800}
        en:addHPProtection(1e10,1e10)
        local player=Player{x=400,y=600}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local poses={}
        for i = 1, 12, 1 do
            local nx,ny=Shape.rThetaPos(400,300,100,math.pi/6*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local middleLineAngle=math.pi/2+math.eval(0.2,0.1)*math.randomSign()
        local mlx,mly=Shape.rThetaPos(400,300,100,middleLineAngle)
        local function pointOnMiddleLine(x,y)
            return unpack(Shape.nearestToLine(x,y,400,300,mlx,mly))
        end
        local goalx,goaly,dir=Shape.rThetaPosT(400,300,20,middleLineAngle+math.pi)
        local goalx2,goaly2
        for r=-100,100,5 do
            goalx2,goaly2=Shape.rThetaPos(goalx,goaly,r,dir+math.pi/2)
            if player.border:inside(goalx2,goaly2) then
                Circle{x=goalx2,y=goaly2,radius=1,speed=0,sprite=BulletSprites.round.blue,lifeFrame=100000,invincible=true,safe=true,highlight=true,spriteTransparency=0.5}
            end
        end
        
        local function drawArrow(x,y,angle,lastFrame,transparency)
            local nx,ny
            local size=4
            local f=lastFrame+1
            local function circle(x,y)
                local cir=Circle{x=x,y=y,speed=0,direction=angle,sprite=BulletSprites.round.blue,lifeFrame=f,invincible=true,safe=true,highlight=true,spriteTransparency=transparency or 1}
                Event.EaseEvent{
                    obj=cir,
                    aimTable=cir,
                    aimKey='spriteTransparency',
                    aimValue=0,
                    easeFrame=f
                }
            end
            for i=1,10 do
                nx,ny=Shape.rThetaPos(x,y,size*i,angle)
                circle(nx,ny)
            end
            local angle2=Shape.to(nx,ny,x,y)
            for i=1,3 do
                local nx2,ny2=Shape.rThetaPos(nx,ny,size*i,angle2+math.pi/6)
                circle(nx2,ny2)
                nx2,ny2=Shape.rThetaPos(nx,ny,size*i,angle2-math.pi/6)
                circle(nx2,ny2)
            end
        end
        local a
        local fixedStones={}
        local firstStone=false
        local firstStoneFixed=false
        local firstStonePos=nil
        local highestPos={400,300}
        local currentPos={400,300}
        local function dropped(cir)
            cir.speed=0
            cir.fixed=true
            fixedStones[#fixedStones+1]=cir
            local x,y=pointOnMiddleLine(cir.x,cir.y)
            local upward=math.modClamp(Shape.to(x,y,400,300),-math.pi/2,math.pi/2)
            local ux,uy=Shape.rThetaPos(x,y,100,upward)
            if uy<highestPos[2] then
                highestPos={ux,uy}
                if firstStonePos then
                    local distanceToGoal=Shape.distanceToLine(x,y,goalx,goaly,goalx2,goaly2)
                    local distanceInitial=Shape.distanceToLine(firstStonePos[1],firstStonePos[2],goalx,goaly,goalx2,goaly2)
                    en.hp=en.maxhp*(distanceToGoal/distanceInitial)
                end
                if y<goaly then
                    en:dieEffect()
                end
            end
        end
        local function drawHangingStone(cir)
            local swingAngle=math.sin(en.frame/17)*0.4
            local xm,ym=pointOnMiddleLine(en.x,en.y)
            local to=cir.x==xm and 0 or Shape.to(cir.x,cir.y,xm,ym)
            to=to+math.pi/2*(math.modClamp(to,math.pi/2,math.pi)<math.pi/2 and 1 or -1)
            local rMax=math.cos(en.frame/23)*10+20
            for r=0,rMax,rMax/6 do
                local x,y=Shape.rThetaPos(cir.x,cir.y,r,to+swingAngle)
                Circle{x=x,y=y,radius=1,sprite=BulletSprites.round.red,highlight=true,lifeFrame=1,speed=0,invincible=true}
            end
            local x,y,dir=Shape.rThetaPosT(cir.x,cir.y,rMax,to+swingAngle)
            cir.x,cir.y=x,y
            cir.direction=dir-swingAngle*0.5
            drawArrow(x,y,dir-swingAngle*0.5,1,math.max(0,1-a.spawnEvent.executedTimes/6))
        end
        a=BulletSpawner{x=400,y=300,period=7200,frame=7180,lifeFrame=100000,bulletNumber=1,bulletSpeed=30,bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bigRound.red,bulletSize=3,highlight=true,spawnSFXVolume=1,bulletEvents={
            function(cir,args,self)
                -- fixedStones[#fixedStones+1]=cir
                cir.released=false
                cir.invincible=true
                cir.inside=player.border:inside(cir.x,cir.y)
            end
        },bulletExtraUpdate={
            function(cir)
                if cir.released==false then
                    cir.x,cir.y=en.x,en.y
                        drawHangingStone(cir)
                    if player.keyIsDown('z') or firstStone==true then
                        firstStone=false
                        SFX:play('select')
                        cir.released=true
                        a.spawnEvent.frame=a.spawnEvent.period-40
                        -- local xm,ym=pointOnMiddleLine(cir.x,cir.y)
                        -- local to=cir.x==xm and 0 or Shape.to(cir.x,cir.y,xm,ym)
                        -- cir.direction=to+math.pi/2*(math.modClamp(to,math.pi/2,math.pi)<math.pi/2 and 1 or -1)
                    end
                elseif not cir.fixed then
                    cir.speed=cir.speed+1
                    for i=1,#fixedStones do
                        local cir2=fixedStones[i]
                        local distance=Shape.distance(cir.x,cir.y,cir2.x,cir2.y)
                        if distance<cir.radius+cir2.radius then
                            dropped(cir)
                            break
                        end
                    end
                    local inside=player.border:inside(cir.x,cir.y)
                    if not inside and cir.inside==true then -- tower is high, initial pos could be outside
                        if firstStoneFixed==false then
                            firstStoneFixed=true
                            dropped(cir)
                            firstStonePos={cir.x,cir.y}
                            return
                        end
                        local spawner
                        spawner=BulletSpawner{x=cir.x,y=cir.y,period=5,frame=4,lifeFrame=5+math.floor(#fixedStones/2),bulletNumber=10+2*#fixedStones,bulletSpeed=10,bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.round.purple,bulletSize=1,highlight=true,spawnSFXVolume=1,bulletEvents={
                            function(cir,args,self)
                                Event.EaseEvent{
                                    obj=cir,aimKey='speed',aimValue=math.eval(60,10),easeTime=120+120*spawner.spawnEvent.executedTimes
                                }
                            end
                        }}
                        cir:remove()
                    end
                    cir.inside=inside
                end
            end
        }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local t=en.frame
                if #fixedStones>0 then
                    for i=#fixedStones,1,-1 do
                        local cir=fixedStones[i]
                        if i%3==0 and (t-i*11)%60==0 then
                            local cir=Circle{x=cir.x,y=cir.y,radius=1,speed=30,sprite=BulletSprites.round.red,highlight=true,lifeFrame=1000,direction=Shape.to(cir.x,cir.y,player.x,player.y)+math.eval(0,0.05)}
                            Event.EaseEvent{
                                obj=cir,
                                aimTable=cir,
                                aimKey='speed',
                                aimValue=60,
                                easeTime=240
                            }
                        end
                        if cir.removed then
                            table.remove(fixedStones,i)
                        end
                    end
                end
                a.bulletSize=math.max(2,3-#fixedStones/12)
                currentPos={highestPos[1]*0.1+currentPos[1]*0.9,highestPos[2]*0.1+currentPos[2]*0.9}
                en.x,en.y=Shape.rThetaPos(currentPos[1],currentPos[2],10*math.sin(t/30),middleLineAngle+math.pi/2)
                a.x,a.y=en.x,en.y
            end
        }
    end
}