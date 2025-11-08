return {
    ID=84,
    user='ubame',
    spellName='Dust Sign "Myriad Motes Accumulation"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1000
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
        local moveRange=0
        local rangeAlpha=0
        a=BulletSpawner{x=400,y=300,period=600,frame=540,lifeFrame=10000,bulletNumber=200,bulletSpeed=30,bulletLifeFrame=10000,angle=math.eval(0,999),range=math.pi*2,bulletSprite=BulletSprites.dot.gray,bulletEvents={
            function(cir,args,self)
                cir.direction=cir.direction+math.eval(0,999)
                cir.speed=math.log(math.eval(56,54),110)*40
                cir.extraUpdate[1]=function(cir)
                    cir.speed=cir.speed*0.99
                    if cir.frame>120 and cir.speed<20 and moveRange>0 and Shape.distance(cir.x,cir.y,en.x,en.y)<moveRange then
                        if not cir.inFlag then
                            cir.speed=cir.speed+50
                            cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)+math.eval(0,1)
                            cir.inFlag=true
                        end
                    else
                        cir.inFlag=false
                    end
                end
            end
        }}


        local drawRef=a.draw
        a.draw=function(self)
            local colorref={love.graphics.getColor()}
            love.graphics.setColor(0.65,0.5,0.1,rangeAlpha)
            Shape.drawCircle(en.x,en.y,moveRange,'fill')
            love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4] or 1)
            drawRef(self)
        end
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local t=en.frame%120
                if t==60 then
                    SFX:play('enemyCharge')
                    local playerPos={x=player.x,y=player.y}
                    Event.LoopEvent{
                        obj=en,
                        period=1,
                        times=60,
                        executeFunc=function(self,times)
                            Shape.moveTowards(en,playerPos,math.sin(times/60*math.pi),true)
                            a.x,a.y=en.x,en.y
                            moveRange=math.min(times,20)
                            rangeAlpha=math.sin(times/60*math.pi)*0.4
                            if times==59 then
                                moveRange=0
                            end
                        end
                    }
                end
            end
        }
    end
}