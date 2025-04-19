return {
    quote='?',
    user='patchouli',
    spellName='Sun Metal Sign "Solar Alloy"',
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=20000000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=1000}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local poses={}
        for i = 1, 12, 1 do
            local nx,ny=Shape.rThetaPos(400,300,150,math.pi/6*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local innerPoints={}
        en.outerR=150
        local a,aa,b,c
        a={x=400,y=300,direction=0,lifeFrame=15,frequency=1,speed=0,sprite=Asset.bulletSprites.laser.yellow,invincible=true,laserEvents={
            function(laser)
                Event.LoopEvent{
                    obj=laser,
                    period=1,
                    executeFunc=function()
                        laser.args.direction=laser.args.direction+math.pi/(laser.lifeFrame-2)*2
                    end
                }
            end
        },
        bulletEvents={
            function(cir,args,self)
                local dir0=cir.direction
                table.insert(innerPoints,cir)
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function()
                        local the=dir0+en.frame/800
                        cir.direction=the+math.pi/3
                        local r
                        if en.frame<20 then
                            r=0
                        elseif en.frame<140 then
                            r=120*(1-(1-(en.frame-20)/120)^4)
                        else
                            r=math.sin((en.frame-140)/100*math.pi/2)*25+120
                        end
                        cir.r,cir.theta=r,the
                        cir.x,cir.y=Shape.rThetaPos(en.x,en.y,r,the)
                    end
                }
            end
        }
        }
        aa=copy_table(a)
        b=Laser(a)
        -- aa.enableWarningAndFading=true
        -- aa.warningFrame=1
        aa.bulletEvents[1]=function(cir,args,self)
            local dir0=cir.direction
            Event.LoopEvent{
                obj=cir,
                period=1,
                executeFunc=function()
                    local the=dir0+en.frame/800
                    cir.direction=the+math.pi/3
                    local r
                    if en.frame<140 then
                        r=140+en.outerR-en.frame
                    else
                        r=math.sin((en.frame-140)/100*math.pi/2)*25+en.outerR
                    end
                    cir.x,cir.y=Shape.rThetaPos(en.x,en.y,r,the)
                end
            }
        end
        c=Laser(aa)
        local border
        local e
        e=BulletSpawner{x=400,y=300,period=30,frame=-100,lifeFrame=10000,bulletNumber=48,bulletSpeed=150,bulletLifeFrame=1000,angle='0+999',range=math.pi*2,highlight=true,bulletSprite=BulletSprites.giant.red,bulletEvents={
            function(cir,args,self)
                cir.spriteTransparency=0.1
                cir.safe=true
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    times=1,
                    conditionFunc=function()
                        return not border:inside(cir.x,cir.y)
                        end,
                    executeFunc=function()
                        Event.EaseEvent{
                            obj=cir,
                            aimTable=cir,
                            aimKey='spriteTransparency',
                            aimValue=1,
                            easeFrame=10
                        }
                        cir.safe=false
                        cir:changeSprite(BulletSprites.bill.red)
                        cir.speed=math.eval(7,2)
                        if en.hp<en.maxhp*0.7 then
                            cir:changeSprite(BulletSprites.bill.orange)
                            cir.direction=cir.direction+0.3*(math.eval(0,1)>0 and 1 or -1)
                        end
                    end
                }
            end
        }}
        local f=BulletSpawner{x=400,y=300,period=30000,frame=0,lifeFrame=10000,bulletNumber=80,bulletSpeed=15,bulletLifeFrame=1000,angle='player',range=math.pi/3,bulletSprite=BulletSprites.bill.yellow,bulletEvents={
            function(cir,args,self)
            end
        }}
        f.set=false
        local outerRdecreased=false
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                if en.frame<20 then return end
                local poses={}
                for i=1,#innerPoints-1,1 do
                    local cir=innerPoints[i]
                    local x,y=Shape.rThetaPos(400,300,cir.r-2,cir.theta)
                    table.insert(poses,{x,y})
                end
                if border then
                    border:remove()
                end
                border=PolyLine(poses,false)
                if border:inside(player.x,player.y) and en.frame%1==0 then
                    Circle{x=en.x,y=en.y,direction=Shape.to(400,300,player.x,player.y)+math.eval(0,0.5),speed=100,sprite=BulletSprites.giant.yellow,invincible=true,lifeFrame=2000}
                end
                local hpp=en.hp/en.maxhp
                if hpp<0.5 and not f.set then
                    f.set=true
                    f.spawnEvent.period=300
                    f.spawnEvent.frame=290
                end
                if hpp<0.3 and not outerRdecreased then
                    SFX:play('enemyCharge',true)
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='outerR',
                        aimValue=140,
                        easeFrame=100
                    }
                    outerRdecreased=true
                end
            end
        }
    end
}