return {
    ID=56,
    quote='?',
    user='clownpiece',
    spellName='?', 
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=2000
        local a,b
        local en
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            a.spawnEvent.frame=a.spawnEvent.period-60
            b.spawnEvent.frame=b.spawnEvent.period-95
            en:addHPProtection(600,10)
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local poses={}
        for i = 1, 12, 1 do
            local nx,ny=Shape.rThetaPos(400,300,100,math.pi/6*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local bullet=nil
        a=BulletSpawner{x=400,y=300,period=300,frame=200,lifeFrame=10000,bulletNumber=3,bulletSpeed=20,bulletLifeFrame=200,angle='1+999',range=math.pi*0,spawnCircleRadius=50,spawnCircleAngle='0+999',fogEffect=true,fogTime=30,bulletSprite=BulletSprites.bigStar.red,bulletEvents={
            function(cir,args,self)
                bullet=cir
                cir.direction=math.eval(0,999)
                local count=0
                local hpLevel=en:getHPLevel()
                local range=hpLevel==1 and 30 or hpLevel==2 and 15 or 5
                if hpLevel==3 then
                    cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)
                end
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function(self,times)
                        if times>60 and times%2==0 then
                            local dir=Shape.to(cir.x,cir.y,player.x,player.y)
                            local offset=math.pi/2*math.max(300-times*2,range)/240*math.mod2Sign(count)
                            if hpLevel==3 then
                                offset=math.pi/2*math.max(200-times,range)/240*math.mod2Sign(count)
                            end
                            local c=Circle{x=cir.x,y=cir.y,direction=dir+offset,speed=90,sprite=BulletSprites.bigRound.red,lifeFrame=1000}
                            count=count+1
                        end
                    end
                }
            end
        }}
        local squareSize=24
        b=BulletSpawner{x=400,y=300,period=150,frame=40,lifeFrame=10000,bulletNumber=288,bulletSpeed=20,bulletLifeFrame=300,angle=0,range=math.pi*2,spawnCircleRadius=0,spawnCircleAngle='0+999',highlight=true,bulletSprite=BulletSprites.ellipse.red,bulletEvents={
            function(cir,args,self)
                local hpLevel=en:getHPLevel()
                if hpLevel==2 then
                    -- local d={1,5,3,7,2,6,4,8}
                    -- cir.speed=cir.speed-d[args.index%8+1]*5
                    local ret=args.index%squareSize
                    cir.speed=cir.speed-3*math.abs(squareSize/2-ret)-(args.index%(squareSize*2)<squareSize and 3 or 0)
                    cir.direction=cir.direction-math.clamp((ret-squareSize/4),0,squareSize/2)*math.pi/b.bulletNumber*4
                elseif hpLevel==1 then
                    local ret=args.index%squareSize
                    cir.speed=cir.speed-1.5*math.abs(squareSize/2-ret)
                    cir.direction=cir.direction-math.clamp((ret-squareSize/4),0,squareSize/2)*math.pi/b.bulletNumber*4
                else
                    cir.speed=cir.speed*(1-math.eval(0.5,0.5)^2)
                end
                if hpLevel<=2 then
                    Event.LoopEvent{
                        obj=cir,
                        period=1,
                        executeFunc=function()
                            cir.speed=cir.speed+1.6-0.5*hpLevel
                        end
                    }
                else
                    Event.EaseEvent{
                        obj=cir,
                        aimTable=cir,
                        aimKey='speed',
                        aimValue=0,
                        easeFrame=120,
                        afterFunc=function()
                            local dir=cir.direction
                            for i=1,4,1 do
                                local c=Circle{x=cir.x,y=cir.y,direction=dir+math.pi/2*(i-1),speed=30,sprite=BulletSprites.ellipse.red,lifeFrame=5000}
                                Event.EaseEvent{
                                    obj=c,
                                    aimTable=c,
                                    aimKey='speed',
                                    aimValue=0,
                                    easeFrame=20,
                                    afterFunc=function()
                                        Event.EaseEvent{
                                            obj=c,
                                            aimTable=c,
                                            aimKey='direction',
                                            aimValue=cir.direction,
                                            easeFrame=20,
                                        }
                                    end
                                }
                            end
                            cir:remove()
                        end
                    }
                end
            end
        }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local hpLevel=en:getHPLevel()
                if hpLevel==1 then
                    if b.spawnEvent.frame==20 then
                        local type=math.random(1,2)
                        if type==1 then
                            b.angle=b.angle+math.pi/12
                            b:spawnBatchFunc()
                            Event.DelayEvent{
                                obj=b,
                                delayFrame=20,
                                executeFunc=function()
                                    if en:getHPLevel()~=1 then return end
                                    b.angle=b.angle-math.pi/12
                                    b:spawnBatchFunc()
                                    b.angle=math.eval(0,999)
                                end
                            }
                        else
                            local sign=math.randomSign()
                            b.angle=b.angle-math.pi/24*0.75*sign
                            squareSize=12
                            b:spawnBatchFunc()
                            Event.DelayEvent{
                                obj=b,
                                delayFrame=10,
                                executeFunc=function()
                                    if en:getHPLevel()~=1 then return end
                                    squareSize=24
                                    b.angle=b.angle-math.pi/24*.75*sign
                                    b:spawnBatchFunc()
                                    b.angle=math.eval(0,999)
                                    squareSize=24
                                end
                            }
                        end
                    end
                elseif hpLevel==2 then
                    squareSize=4
                    b.bulletNumber=216
                    b.angle='0+999'
                    if b.spawnEvent.frame==20 then
                        b:spawnBatchFunc()
                    end
                else
                    a.bulletNumber=1
                    a.spawnCircleRadius=20
                    -- a.fogTime=100
                    b.bulletNumber=15
                    b.bulletSpeed=100
                    b.bulletLifeFrame=6000
                    b.bulletSprite=BulletSprites.bigRound.red
                    b.x,b.y=bullet and bullet.x or 400,bullet and bullet.y or 300
                end
            end
        }
        
    end
}