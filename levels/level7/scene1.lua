return {
    ID=61,
    quote='?',
    user='reisen',
    spellName='Scatter Sign "Phantom Mirage"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=150000
        local a,t
        local en
        en=Enemy{x=1000,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            a.spawnEvent.frame=0
            t=0
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
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local direction=0
        t=0
        a=BulletSpawner{x=poses[1][1],y=poses[1][2],period=6000,frame=0,lifeFrame=10000,bulletNumber=50,bulletSpeed=40,bulletLifeFrame=1200,angle='0',range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.rice.red,bulletEvents={
            function(cir,args,self)
                -- if args.index%2==0 then
                --     cir.sprite=BulletSprites.rice.blue
                -- end
                -- Event.LoopEvent{
                --     obj=cir,
                --     period=60,
                --     executeFunc=function()
                --         cir.direction=cir.direction+math.pi/2
                --     end
                -- }
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    conditionFunc=function()
                        return t%300==0
                    end,
                    times=10,
                    executeFunc=function()
                        -- local newCir=Circle{x=cir.x,y=cir.y,direction=cir.direction,speed=cir.speed,sprite=BulletSprites.rice.red,lifeFrame=1000,safe=true,spriteTransparency=0.5}
                        cir.safe=true
                        cir.spriteTransparency=0.5
                        local r,the=Shape.distance(cir.x,cir.y,player.x,player.y),Shape.to(player.x,player.y,cir.x,cir.y)
                        local theI=Shape.to(cir.x,cir.y,player.x,player.y)
                        local deltaDir=cir.direction-theI
                        local rAim=r*0.8
                        local playerx,playery=player.x,player.y
                        Event.LoopEvent{
                            obj=cir,
                            period=1,
                            times=100,
                            executeFunc=function(self,times)
                                local ratio=1-(1-times/100)^2
                                local r2=rAim*ratio+(1-ratio)*r
                                local the2
                                if en:getHPLevel()<=2 then
                                    the2=the+ratio*math.pi*2*(args.index/a.bulletNumber*4%1*2-1)
                                else
                                    the2=the+ratio*math.pi*(args.index/a.bulletNumber*2-1)
                                end
                                local x,y=Shape.rThetaPos(playerx,playery,r2,the2)
                                cir.x,cir.y=x,y
                                cir.direction=-(Shape.to(cir.x,cir.y,playerx,playery)+deltaDir)+math.pi
                                x,y=Shape.rThetaPos(playerx,playery,r2,2*the-the2)
                                -- newCir.x,newCir.y=x,y
                                if times==99 then
                                    cir.safe=false
                                    cir.spriteTransparency=1
                                    cir:changeSpriteColor('blue')
                                    cir.speed=40
                                    -- newCir.safe=false
                                    -- newCir.spriteTransparency=1
                                    -- newCir:changeSpriteColor('blue')
                                    -- newCir.direction=-(Shape.to(newCir.x,newCir.y,playerx,playery)+deltaDir)+math.pi
                                end
                            end
                        }
                    end
                }
            end
        }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                t=t+1
                en.x,en.y=Shape.rThetaPos(400,300,100*en.hp/en.maxhp,math.pi/600*en.frame)
                a.x,a.y=en.x,en.y
                local t2=t%300
                if t2==250 then
                    SFX:play('enemyCharge',true)
                elseif t2==0 then
                    SFX:play('enemyPowerfulShot',true)
                end
                local hpLevel=en:getHPLevel()
                if hpLevel==1 then
                    if t2==10 then
                        for i=1,10 do
                            a.bulletSpeed=20+1*i
                            a:spawnBatchFunc()
                        end
                    elseif t2==70 then
                        -- a.spawnEvent.frame=0
                        -- a.spawnEvent.period=10000
                        a.angle=math.eval(0,999)
                    end
                elseif hpLevel==2 then
                    a.bulletNumber=10
                    a.spawnEvent.period=10
                    a.bulletSpeed=60
                    if t2==298 then
                        a.angle=math.eval(0,999)
                    end
                else
                    a.bulletNumber=50
                    a.spawnEvent.period=50
                    a.bulletSpeed=40
                    a.range=math.pi*100
                    a.angle=Shape.to(a.x,a.y,player.x,player.y)+math.pi
                end
            end
        }
        
    end
}