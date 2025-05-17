return {
    ID=77,
    user='patchouli',
    spellName='Fire Sign "Hephaestus Pyrotechnics"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local a,b
        local en
        en=Enemy{x=400,y=600000,mainEnemy=true,maxhp=7200}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=1200000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local poses={}
        for i = 1, 30, 1 do
            local nx,ny=Shape.rThetaPos(400,600000,700,math.pi/15*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player

        local extraUpdate=function(cir)
            if cir.lighted and cir.frame%5==0 then
                Circle{x=cir.x,y=cir.y,sprite=cir.sprite,lifeFrame=12,direction=cir.direction+math.eval(0,999),speed=cir.speed*0.2,radius=cir.radius*0.8,safe=true,batch=cir.batch,
                    spriteTransparency=0.75}
            end
            if en.frame%300==0 then
                cir.lighted=true
                cir:changeSprite(BulletSprites.flame[cir.sprite.data.color])
                cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)--+math.eval(0,0.2)
                Event.EaseEvent{
                    obj=cir,
                    easeFrame=200,
                    aimTable=cir,
                    aimKey='speed',
                    aimValue=Shape.distance(cir.x,cir.y,player.x,player.y),
                    progressFunc=function(x)return math.sin(x*math.pi) end,
                    afterFunc=function()
                        cir.lighted=false
                        cir:changeSprite(BulletSprites.round[cir.sprite.data.color])
                    end
                }
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=100,
                    executeFunc=function()
                        cir.direction=cir.direction+math.eval(0,en.frame/1800)
                    end
                }
            end
        end

        a=BulletSpawner{x=400,y=600000,period=6,frame=-30,lifeFrame=10000,bulletNumber=1,bulletSpeed=0,bulletLifeFrame=3600,angle=math.eval(0,999),range=math.pi*2,highlight=true,bulletSprite=BulletSprites.round.red,fogEffect=true,fogTime=3,bulletEvents={
            function(cir,args,self)
                a.angle=a.angle+0.01
                cir.extraUpdate[1]=extraUpdate
            end
        }}
        b=BulletSpawner{x=400,y=600000,period=120,frame=-300,lifeFrame=10000,bulletNumber=10,bulletSpeed=30,bulletLifeFrame=3600,angle=math.eval(0,999),range=math.pi*2,highlight=true,bulletSprite=BulletSprites.round.blue,fogEffect=true,fogTime=3,bulletSize=2,bulletEvents={
            function(cir,args,self)
                cir.extraUpdate[1]=extraUpdate
            end
        }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local angle=en.frame/30
                local x,y=Shape.rThetaPos(player.x,player.y,30,angle)
                local aim={x=x,y=y}
                local distance=Shape.distance(a.x,a.y,x,y)
                Shape.moveTowards(a,aim,math.max(1,distance/10),true)
                b.x,b.y=en.x,en.y
                if en.frame%300==240 then
                    SFX:play('enemyCharge')
                end
                if en.frame%300==0 then
                    SFX:play('enemyPowerfulShot')
                    Effect.Larger{sprite=BulletSprites.shockwave.gray,x=en.x,y=en.y,animationFrame=60}
                    Event.LoopEvent{
                        obj=en,
                        period=1,times=120,
                        executeFunc=function()
                            local distance2=Shape.distance(en.x,en.y,x,y)
                            Shape.moveTowards(en,aim,math.max(0.25,distance2/40),true)
                        end
                    }
                end
            end
        }
    end
}