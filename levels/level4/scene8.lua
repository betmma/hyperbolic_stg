return {
    ID=87,
    user='chimi',
    spellName='Mountain Spirit Sign "Qi of a Drainage Divide"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1500
        local a,b
        local en
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
        -- en:addHPProtection(600,10)
        local player=Player{x=400,y=600,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local x01,y01=Shape.rThetaPos(400,300,120,-1.45+math.pi)
        local x02,y02=Shape.rThetaPos(400,300,120,-1.45)
        a=BulletSpawner{x=400,y=300,period=3,frame=-40,lifeFrame=10000,spawnCircleRadius='120+20',spawnCircleAngle='1.6+0.53',bulletNumber=2,bulletSpeed='50+20',bulletLifeFrame=450,angle='2.65+0.2',range=math.pi*2,bulletSprite=BulletSprites.rain.cyan,fogEffect=true,fogTime=10,bulletEvents={
            function(cir,args,self)
                local offset=math.eval(0,0.25)
                if args.index%2==1 then
                    cir.direction=Shape.to(cir.x,cir.y,x01,y01)+offset
                else
                    cir.direction=Shape.to(cir.x,cir.y,x02,y02)+offset
                end
            end
        }}
        a.spawnEvent.mode=Event.modes.oneFrameMultiple
        local x1,y1=Shape.rThetaPos(400,300,120,-0.75)
        local x2,y2=Shape.rThetaPos(400,300,120,-0.75+math.pi)
        b=BulletSpawner{x=400,y=300,period=5,frame=0,lifeFrame=10000,bulletNumber=6,spawnCircleRadius='30+10',spawnCircleAngle='0+999',bulletSpeed=30,bulletLifeFrame=300,fogEffect=true,fogTime=10,angle=1,range=math.pi*2,bulletSprite=BulletSprites.bigRound.black,highlight=true,bulletEvents={
            function(cir,args,self)
                local offset=math.eval(0,0.3)
                if args.index%2==1 then
                    cir.direction=Shape.to(cir.x,cir.y,x1,y1)+offset
                else
                    cir.direction=Shape.to(cir.x,cir.y,x2,y2)+offset
                end
            end
        }}
        Event.LoopEvent{
            period=600,frame=300,
            executeFunc=function()
                SFX:play('enemyCharge')
                Event.EaseEvent{
                    obj=a,
                    easeFrame=60,
                    aimTable=a.spawnEvent,
                    aimKey='period',
                    aimValue=0.5
                }
                a.bulletSprite=BulletSprites.rain.blue
                a.bulletSpeed={50,30}
                b.spawnEvent.period=40
                b.bulletSprite=BulletSprites.bigRound.gray
            end
        }
        Event.LoopEvent{
            period=600,frame=0,
            executeFunc=function()
                SFX:play('enemyCharge')
                Event.EaseEvent{
                    obj=a,
                    easeFrame=60,
                    aimTable=a.spawnEvent,
                    aimKey='period',
                    aimValue=3
                }
                a.bulletSprite=BulletSprites.rain.cyan
                a.bulletSpeed={50,20}
                b.spawnEvent.period=5
                b.bulletSprite=BulletSprites.bigRound.black
            end
        }
        Event.LoopEvent{
            period=40,frame=0,
            executeFunc=function()
                local x,y=Shape.rThetaPos(400,300,math.eval(10,10),math.eval(0,999))
                local pos={x=x,y=y}
                Event.LoopEvent{
                    period=1,times=20,
                    executeFunc=function(self,times)
                        Shape.moveTowards(en,pos,0.4,true)
                        b.x,b.y=en.x,en.y
                    end
                }
            end
        }
    end
}