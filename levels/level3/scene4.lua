return {
    ID=85,
    user='ubame',
    spellName='Chest Sign "Karabitsu\'s Opened Hoard"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1000
        local a,b
        local en
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=6000}
        -- en:addHPProtection(600,10)
        local player=Player{x=400,y=600,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300}
        local poses=Shape.regularPolygonCoordinates(center.x,center.y,110,12)
        player.border=PolyLine(poses)
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local moveRange=40
        local function drawBox(x,y,direction)
            local ratio=(y-Shape.axisY)/Shape.curvature
            local dx,dy,xnum,ynum=3*ratio,3*ratio,4,6
            for i=1,xnum do
                for j=1,ynum do
                    local x0=(i-xnum/2)*dx
                    local y0=(j-ynum/2)*dy
                    local x1=x+x0*math.cos(direction)-y0*math.sin(direction)
                    local y1=y+x0*math.sin(direction)+y0*math.cos(direction)
                    local cir=Circle{x=x1,y=y1,lifeFrame=9999,invincible=true,sprite=BulletSprites.bigRound.blue,batch=Asset.bulletHighlightBatch}
                    if i>1 and j>1 and j<ynum then
                        cir.extraUpdate[1]=function(cir)
                            local distance=Shape.distance(cir.x,cir.y,en.x,en.y)
                            cir.spriteTransparency=math.clamp(distance/moveRange-0.5,0,1)
                        end
                    end
                end
            end
        end
        for i=1,#poses do
            local x,y=poses[i][1],poses[i][2]
            local direction=Shape.to(x,y,center.x,center.y)
            drawBox(x,y,direction)
        end
        local rangeAlpha=0.2
        local spriteTypes={'scale','rim','round','rice','kunai','crystal','bill','bullet','blackrice','star'}
        local colors=Asset.colors
        local flag=false
        a=BulletSpawner{x=400,y=300,period=25,frame=-40,lifeFrame=10000,bulletNumber=12,bulletSpeed=0,bulletLifeFrame=10000,angle=0,spawnCircleRadius='110+4',spawnCircleAngle='0+0.03',range=math.pi*2,bulletSprite=BulletSprites.dot.gray,highlight=true,bulletEvents={
            function(cir,args,self)
                local index=args.index
                local randomSprite=BulletSprites[spriteTypes[math.random(1,#spriteTypes)]][colors[math.random(1,#colors)]]
                cir:changeSprite(randomSprite)
                cir.direction=cir.direction+math.eval(math.pi,0.5)
                cir.speed=0
                cir.extraUpdate[1]=function(cir)
                    if Shape.distance(cir.x,cir.y,en.x,en.y)<moveRange and not cir.released then
                        cir.speed=math.eval(50,20)
                        cir.released=true
                    end
                    if cir.released and index%2==1 and not flag then
                        local distance=Shape.distance(cir.x,cir.y,player.x,player.y)
                        if distance<50 then return end
                        local toPlayer=Shape.to(cir.x,cir.y,player.x,player.y)
                        toPlayer=math.modClamp(toPlayer,cir.direction)
                        cir.direction=math.clamp(toPlayer,cir.direction-0.005,cir.direction+0.005)
                    end
                end
            end
        }}
        local currentIndex=0
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
                local t=en.frame%180
                if t==60 then
                    local times=math.floor(en.frame/180)
                    local nextIndex,aim
                    if times%5==4 then
                        SFX:play('enemyPowerfulShot')
                        flag=true
                        nextIndex=math.random(1,12)
                        aim={center.x,center.y}
                    else
                        SFX:play('enemyCharge')
                        flag=false
                        nextIndex=(math.random(1,3)*math.randomSign()+currentIndex-1)%12+1
                        aim=poses[nextIndex]
                    end
                    currentIndex=nextIndex
                    Event.LoopEvent{
                        obj=en,
                        period=1,
                        times=180,
                        executeFunc=function(self,times)
                            local distance=Shape.distance(en.x,en.y,400,300)
                            local ratio=math.clamp(1-distance/130,0.1,0.5)*4
                            Shape.moveTowards(en,{x=aim[1],y=aim[2]},math.sin(times/180*math.pi)*ratio,true)
                            if flag then
                                moveRange=math.sin(times/180*math.pi)*75+40
                            end
                        end
                    }
                end
            end
        }
    end
}