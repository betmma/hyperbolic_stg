return {
    ID=106,
    user='tsukumo',
    spellName='Soukyoku "Bent Strings"',
    make=function()
        G.levelRemainingFrame=10800
        Shape.removeDistance=1e100
        local center={x=400,y=300000}
        local a,b
        local en,en2
        local hplevel=1
        en=Enemy{x=center.x,y=center.y,mainEnemy=true,maxhp=14400,hpSegments={0.75,0.5,0.25},sprite=Asset.boss.yatsuhashi,hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
            hplevel=hplevel+1
            a.frame=0
            b.frame=0
            if hplevel==3 then
                a.period=200
            end
        end}
        -- en.showHexagram=false
        en:addHPProtection(600,10)
        en2=Enemy{x=center.x,y=center.y*0.5,maxhp=14400,hpSegments={0.75,0.5,0.25},sprite=Asset.boss.benben,hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
        end}
        en2:bind(en)
        local player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local counter=0
        local extraUpdate=function(cir)
            local t,i=cir.frame,cir.i
            local ja=math.abs(cir.j)
            local moveTime=15*i+15
            if moveTime-20<t and t<moveTime then
                cir.spriteTransparency=math.min(1,cir.spriteTransparency+0.05)
            end
            local x2,y2,dir2=unpack(cir.aim)
            if t<moveTime then
                Shape.moveTowards(cir,{x=x2,y=y2},6/moveTime,false,true)
            elseif t==moveTime then
                cir.x,cir.y,cir.direction=x2,y2,dir2
                cir.safe=false
                Event.EaseEvent{
                    obj=cir,aimKey='speed',aimValue=-40,easeFrame=300,progressFunc=Event.sineBackProgressFunc
                }
            end
            local jaCond
            local warningTime=60
            if hplevel>=4 then
                jaCond=(ja%4<2)==(cir.counter%2==0)--math.abs(cir.j-math.pseudoRandom(cir.counter)*10)>4
                -- warningTime=0
            else
                if cir.counter%2==0 then
                    jaCond=ja<4
                else
                    jaCond=ja>4
                end
            end
            local hasAdditional=hplevel>1 and jaCond and ja%2==0
            if t==moveTime+warningTime+ja*5 and hasAdditional then
                local warning=Circle{x=cir.x,y=cir.y,lifeFrame=120,speed=0,sprite=BulletSprites.giant.red,safe=true,highlight=true,spriteTransparency=0,radius=2,extraUpdate={function(cir2)
                    cir2.x,cir2.y=cir.x,cir.y
                    if cir2.frame<20 then
                        cir2.spriteTransparency=cir2.spriteTransparency+0.02
                    elseif cir2.frame>=100 then
                        cir2.spriteTransparency=cir2.spriteTransparency-0.02
                    end
                end}}
                warning.spriteColor={1,0,0}
            end
            if t==moveTime+180+ja*5 and hasAdditional then
                BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=8,bulletSpeed=60,angle=math.eval(0,999),bulletSprite=BulletSprites.note.red,bulletLifeFrame=60,bulletSize=4,bulletEvents={
                    function(cir,args)
                        cir.forceDrawNormalSprite=true
                    end}
                ,bulletExtraUpdate={function(cir)
                    if cir.frame>40 then
                        cir.spriteTransparency=cir.spriteTransparency-0.05
                    end
                    if cir.radius>0.4 then 
                        cir.radius=cir.radius*0.98
                        cir.speed=cir.speed*0.98
                    end
                end}}
            end
            local switchFrame=cir.switchFrame -- not used. row number is much less than number of units in a laser, so such switch will cause nonsmooth lasers
            if switchFrame then
                if t>switchFrame-20 and t<=switchFrame  then
                    cir.spriteTransparency=math.max(0,cir.spriteTransparency-0.05)
                elseif t>switchFrame and t<=switchFrame+20 then
                    cir.spriteTransparency=math.min(1,cir.spriteTransparency+0.05)
                end
                if t==switchFrame then
                    cir.previous=cir.previousRow
                    cir.next=cir.nextRow
                end
            end
            if t+20>cir.lifeFrame then
                cir.safe=true
                cir.spriteTransparency=math.max(0,cir.spriteTransparency-0.05)
            end
        end
        local function spawn(x,y)
            local dir=Shape.to(x,y,player.x,player.y)
            local dis=Shape.distance(x,y,player.x,player.y)
            local n=6
            local cirTable={}
            for i=1,n do
                Event.DelayEvent{
                    delayFrame=10*(n-i),executeFunc=function()
                        SFX:play('enemyShot',true)
                        local x1,y1,dir1=Shape.rThetaPosT(x,y,(i-n/2)*30+dis,dir)
                        local previous
                        for j=-12,12 do
                            local x0,y0,dir0=Shape.rThetaPosT(x,y,j*1,dir+math.pi/2) -- span less wide
                            local x2,y2,dir2=Shape.rThetaPosT(x1,y1,j*13,dir1+math.pi/2)
                            dir2=dir2-math.pi/2
                            local cir=Laser.LaserUnit{x=x0,y=y0,direction=dir0,speed=0,sprite=BulletSprites.laser.red,lifeFrame=400,--600-10*(n-i),
                            radius=1.5,spriteTransparency=0.5,safe=true,invincible=true,extraUpdate=extraUpdate}
                            cir.counter=counter
                            -- cir.switchFrame=400-10*(n-i)
                            cir.i,cir.j=i,j
                            cir.aim={x2,y2,dir2}
                            -- Shape.moveToInTime(cir,{x=x2,y=y2},15*i)
                            if previous then
                                cir.previous=previous
                                previous.next=cir
                            end
                            previous=cir
                            if cirTable[j] then
                                cir.previousRow=cirTable[j]
                                cirTable[j].nextRow=cir
                            end
                            cirTable[j]=cir
                        end
                    end
                }
            end
        end
        a=Event.LoopEvent{
            obj=en,period=300,frame=240,executeFunc=function(self,times)
                counter=counter+1
                spawn(en.x,en.y)
            end
        }
        b=Event.LoopEvent{
            obj=en2,period=180,frame=0,executeFunc=function(self,times)
                local playerPosRef={x=player.x,y=player.y}
                Event.LoopEvent{
                    obj=en2,period=1,times=120,executeFunc=function(self,times,maxTimes)
                        Shape.moveTowards(en2,playerPosRef,0.01,false,true)
                        if times==maxTimes-1 then
                            local spawner=BulletSpawner{x=en2.x,y=en2.y,period=5,frame=0,lifeFrame=100,bulletNumber=3,bulletSpeed=30,angle='player',range=math.pi*0.7,bulletSprite=BulletSprites.note.blue,bulletLifeFrame=360,radius=1,bulletExtraUpdate={function(cir)
                                cir.direction=math.eval(cir.direction,0.01)
                                if cir.frame+20>cir.lifeFrame then
                                    cir.safe=true
                                    cir.spriteTransparency=math.max(0,cir.spriteTransparency-0.05)
                                end
                            end}}
                            Event.LoopEvent{
                                obj=spawner,period=1,times=120,executeFunc=function()
                                    spawner.x,spawner.y=en2.x,en2.y
                                    spawner.bulletSpeed=spawner.bulletSpeed+0.6
                                end
                            }
                        end
                    end
                }
            end
        }
    end
}