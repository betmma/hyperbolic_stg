return {
    ID=82,
    user='okina',
    spellName='Secret Ceremony "the Ninefold Heaven Gates"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local a,b
        local en
        en=Enemy{x=400,y=1000000,mainEnemy=true,maxhp=12600,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            a.bulletSprite=BulletSprites.bigRound.blue
            en:addHPProtection(600,10)
        end}
        local player=Player{x=400,y=100000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local backShoot=player:findShootType('back','straight')
        backShoot.lifeFrame=45
        local homingShoot=player:findShootType('front','homing')
        homingShoot.lifeFrame=45
        local poses={}
        for i = 1, 30, 1 do
            local nx,ny=Shape.rThetaPos(400,600000,700,math.pi/15*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local enemyToAimDistance=30
        local aim={player.x,player.y}
        local direction=player.naturalDirection+math.pi/2
        local base=1.075
        local doubleLevel=2
        local shootUpdate=function(hpLevel,speed,sign)
            local freq=hpLevel==doubleLevel and 10 or 15
            local lifeFrame=hpLevel==doubleLevel and 400 or 600
            return function(cir)
                if cir.frame%freq==2 then
                    local args={x=cir.x,y=cir.y,sprite=BulletSprites.flame[hpLevel==1 and 'red' or 'blue'],lifeFrame=lifeFrame,direction=cir.direction+math.pi,speed=speed,fogTime=10,batch=Asset.bulletHighlightBatch,extraUpdate={
                        function(cir2)
                            cir2.direction=cir2.direction+cir2.speed/Shape.curvature/60*sign -- move in horocycle (appears as a horizontal line if player doesn't move)
                        end
                    }}
                    BulletSpawner.wrapFogEffect(args,Circle,true)
                end
            end
        end
        a=BulletSpawner{x=400,y=1000000,period=650,frame=580,lifeFrame=10000,bulletNumber=18,bulletSpeed=0,bulletLifeFrame=600,angle=math.eval(0,999),range=math.pi*2,highlight=true,bulletSprite=BulletSprites.bigRound.red,fogEffect=true,fogTime=10,spawnSFXVolume=1,bulletEvents={
            function(cir,args,self)
                local index=args.index
                if index==1 then
                    aim={player.x,player.y}
                    direction=player.naturalDirection+math.pi/2
                end
                cir.invincible=true
                local sign=math.mod2Sign(index)
                local div2=math.ceil(index/2)
                local rDown=15+15*div2
                local newDir
                cir.x,cir.y,newDir=Shape.rThetaPos(player.x,player.y,rDown,player.naturalDirection+math.pi/2)
                newDir=newDir+(math.pi/2)*sign*math.sign(rDown)
                cir.direction=newDir
                local hpLevel=en:getHPLevel()
                local speed=50*base^(8-index)
                cir.extraUpdate[1]=shootUpdate(hpLevel,speed,sign)
                if hpLevel==doubleLevel then
                    cir.speed=speed
                    cir.extraUpdate[2]=function(cir2)
                        cir2.direction=cir2.direction-cir2.speed/Shape.curvature/60*sign
                    end
                end
            end
        }}
        Event.DelayEvent{
            obj=en,delayFrame=60,executeFunc=function() -- give a broader view of backside
                SFX:play('enemyPowerfulShot')
                Event.EaseEvent{
                    obj=en,aimTable=G.viewOffset,aimKey='y',aimValue=-200,easeFrame=180,progressFunc=Event.sineIOProgressFunc
                }
                Event.EaseEvent{
                    obj=en,aimTable=Shape,aimKey='axisY',aimValue=-50,easeFrame=180,progressFunc=Event.sineIOProgressFunc
                }
            end
        }
        local hp=en.hp
        Event.LoopEvent{
            obj=en,
            period=1,
            frame=-100,
            executeFunc=function() 
                local aimr=240
                local newhp=en.hp
                local t=a.spawnEvent.frame
                if newhp<hp and t>300 and t<a.spawnEvent.period-10 then
                    a.spawnEvent.frame=a.spawnEvent.frame+1
                end
                if t>=300 then
                    return
                end
                local nx,ny=Shape.rThetaPos(aim[1],aim[2],aimr,direction)
                enemyToAimDistance=Shape.distance(nx,ny,en.x,en.y)
                Shape.moveTowards(en,{x=nx,y=ny},math.min(3,enemyToAimDistance/4),true)
                a.x,a.y=en.x,en.y
            end
        }
    end
}