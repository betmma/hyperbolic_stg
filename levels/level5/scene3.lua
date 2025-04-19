return {
    quote='?',
    user='aya',
    spellName='Crossroad Sign "Wind-Chasing Track"', 
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=2000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=8400,}
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
        local a
        -- a=BulletSpawner{x=400,y=300,period=300,frame=240,lifeFrame=10000,bulletNumber=30,bulletSpeed=30,bulletLifeFrame=10000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bill.blue,bulletEvents={
        -- }}
        en.theta=0
        en.gap=0.5
        en.R=20
        local releaseT=0
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                -- a.x,a.y=en.x,en.y
                local fr=en.frame%600
                local hpp=en.hp/en.maxhp
                if fr==30 then
                    releaseT=math.ceil(550+30*hpp)
                    SFX:play('enemyCharge',true)
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='theta',
                        aimValue=math.eval(0,3.14),
                        easeFrame=60,
                        progressFunc=Event.sineOProgressFunc
                    }
                end
                if fr==300 then
                    SFX:play('enemyCharge',true)
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='R',
                        aimValue=105,
                        easeFrame=120,
                        progressFunc=Event.sineOProgressFunc
                    }
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='gap',
                        aimValue=0.05*(1+hpp),
                        easeFrame=120,
                        progressFunc=Event.sineOProgressFunc
                    }
                    local playerTheta=Shape.to(400,300,player.x,player.y)
                    local toMoveTheta=en.theta
                    if math.abs(math.modClamp(playerTheta-en.theta,0,math.pi))>math.pi/2 then
                        toMoveTheta=en.theta+math.pi
                    end
                    Event.LoopEvent{
                        obj=en,
                        period=1,
                        times=360,
                        executeFunc=function(self,times)
                            local t
                            if times<120 then
                                t=math.sin(times/120*math.pi/2)
                            else
                                t=math.sin((times/80-0.5)*math.pi/2)
                            end
                            local x,y=Shape.rThetaPos(400,300,110*t,toMoveTheta)
                            en.x,en.y=x,y
                        end
                    }
                end
                if fr==500 then
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='R',
                        aimValue=20,
                        easeFrame=120,
                        progressFunc=Event.sineOProgressFunc
                    }
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='gap',
                        aimValue=0.5,
                        easeFrame=120,
                        progressFunc=Event.sineOProgressFunc
                    }
                    
                end
                
                local x1,y1=Shape.rThetaPos(400,300,en.R,en.theta+en.gap)
                local x2,y2=Shape.rThetaPos(400,300,en.R,en.theta-en.gap)
                local x3,y3=Shape.rThetaPos(400,300,en.R,en.theta+math.pi+en.gap)
                local x4,y4=Shape.rThetaPos(400,300,en.R,en.theta+math.pi-en.gap)
                local dis=Shape.distance(x1,y1,x4,y4)
                local num=math.ceil(dis/2)
                local xys={}
                for i=0,num do
                    local disi=dis*i/num
                    local x,y=Shape.rThetaPos(x1,y1,disi,Shape.to(x1,y1,x4,y4))
                    table.insert(xys,{x,y,Shape.to(x,y,x4,y4)})
                    
                    local x,y=Shape.rThetaPos(x2,y2,disi,Shape.to(x2,y2,x3,y3))
                    table.insert(xys,{x,y,Shape.to(x,y,x3,y3)})
                end
                local num2=math.ceil(math.sinh(en.R/100)*40*(math.pi-en.gap*2))
                for i=0,num2 do
                    local anglei=en.gap+(math.pi-en.gap*2)*i/num2+en.theta
                    local x,y=Shape.rThetaPos(400,300,en.R,anglei)
                    table.insert(xys,{x,y,Shape.to(x,y,400,300)})
                    x,y=Shape.rThetaPos(400,300,en.R,anglei+math.pi)
                    table.insert(xys,{x,y,Shape.to(x,y,400,300)})
                end

                for key, value in pairs(xys) do
                    if fr==releaseT then
                        Circle{x=value[1],y=value[2],direction=math.eval(0,999),speed=20,sprite=BulletSprites.scale.red,lifeFrame=1000}
                    else
                        Circle{x=value[1],y=value[2],direction=value[3],speed=0,sprite=BulletSprites.scale.blue,invincible=true,lifeFrame=0}
                    end
                end
                -- en.theta=en.theta+0.01
            end
        }
        
    end
}