return {
    ID=120,
    user='ariya',
    spellName='Stop Sign ""',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=20000
        local center={x=400,y=300}
        G.backgroundPattern:remove()
        G.backgroundPattern=BackgroundPattern.FixedTesselation{centerPoint=center,sideColor={0.6,0.3,0.15},faceColor={0.3,0.15,0.06},overallColorScale=0}
        Shape.timeSpeed=0.1
        -- if G.replay then
        --     Shape.timeSpeed=0.12
        -- end
        local a,b
        local en
        local player=Player{x=400,y=600}
        local function immuneUpdateMove(self,dt)
            self.metric=self:getMetric()
            self.moveRadius=self:getMoveRadius()
            local moveDistance=self.speed* dt * 1 * self.metric
            self.x = self.x +  moveDistance * math.cos(self.direction) 
            self.y=self.y+moveDistance * math.sin(self.direction) 
            self.direction=self.direction-moveDistance/self.moveRadius
        end
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9400,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            SFX:play('enemyCharge',true)
            en:addHPProtection(600,10)
            a.frame=a.period-60
            b=BulletSpawner{x=center.x,y=center.y,period=200,frame=0,lifeFrame=10000,bulletNumber=10,bulletSize=1,highlight=true,bulletLifeFrame=300,range=math.pi*0.1,angle='player',bulletSpeed=40,bulletSprite=BulletSprites.stone.red,bulletEvents={function(cir,args,self)
                cir.updateMove=immuneUpdateMove
            end}}
        end}
        en:addHPProtection(600,10)
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,100,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local playerMoving=false
        Event.LoopEvent{
            obj=player,
            period=1,
            executeFunc=function(self)
                local keys={'up','down','left','right'}
                playerMoving=false
                for i,key in ipairs(keys) do
                    if G.replay then
                        if player.keyIsDown(key,player.frame-1) then -- must -1 to prevent replay desync
                            playerMoving=true
                            break
                        end
                    else
                        if player.keyIsDown(key) then
                            playerMoving=true
                            break
                        end
                    end
                end
                if playerMoving then
                    Shape.timeSpeed=math.min(1,Shape.timeSpeed+0.02)
                else
                    Shape.timeSpeed=math.max(0,Shape.timeSpeed-0.02)
                end
                G.backgroundPattern.overallColorScale=Shape.timeSpeed
            end
        }
        local stopUpdate=function(cir)
            if playerMoving then
                cir.speed=cir.speed+1
            else
                cir.speed=math.max(0,cir.speed-1)
            end
        end
        local function shoot(x,y,dir,bulletNumber)
            local count=0
            local colors={'red','orange','yellow','green'}
            BulletSpawner{x=x,y=y,period=15,frame=0,lifeFrame=50,bulletNumber=bulletNumber or 9,bulletSize=2,highlight=true,bulletLifeFrame=1200,range=math.pi,angle=dir,bulletSpeed=30,bulletSprite=BulletSprites.scaleDark.orange,fogEffect=true,fogTime=20,bulletEvents={
                function(cir,args,self)
                    if args.index==1 then
                        count=count+1
                    end
                    cir.speed=cir.speed+10*count
                    cir:changeSpriteColor(colors[count%#colors+1])
                end
            }}
        end
        local function pattern()
            local dir0=Shape.toObj(player,en)
            local bias=math.eval(0,0.05)
            for i=-1,1,2 do
                local dir=dir0+math.pi/2*i
                local x1,y1,dir1=Shape.rThetaPosT(player.x,player.y,50,dir)
                shoot(x1,y1,dir1+math.pi)
                for j=-1,1,2 do
                    local dir2=dir1+math.pi/2*j
                    local xk,yk,dirk=x1,y1,dir2
                    for k=1,10 do
                        local step=30
                        xk,yk,dirk=Shape.rThetaPosT(xk,yk,step,dirk)
                        dirk=dirk+j*step/100
                        shoot(xk,yk,dirk+(math.pi/2+0.05*k)*j+bias)
                    end
                end
            end
        end
        local function pattern2()
            local dir0=Shape.toObj(en,player)
            local bias=math.eval(0,0.05)
            for i=1,40 do
                local angle=math.pi*2/40*i
                local dir=dir0+angle
                local x1,y1,dir1=Shape.rThetaPosT(en.x,en.y,100/math.cos((angle+math.pi/3)%(math.pi*2/3)-math.pi/3),dir)
                shoot(x1,y1,dir1+bias+math.pi+math.pi/17*(i%4))
            end
        end
        local function pattern3()
            local angle=math.eval(0,math.pi*2)
            for i=1,12 do
                local dir=angle+math.pi*2/12*i
                local x1,y1,dir1=Shape.rThetaPosT(en.x,en.y,-20,dir)
                local deltaAngle=0--math.pi/12*i
                for j=1,10 do
                    local x2,y2,dir2=Shape.rThetaPosT(x1,y1,5*j,dir1)
                    local x3,y3,dir3=Shape.rThetaPosT(x2,y2,120,dir2+math.pi/2+deltaAngle)
                    shoot(x3,y3,dir3+math.pi,1)
                end
            end
        end
        local function pattern4()
            local angle=Shape.toObj(en,player)
            local bias=math.eval(0,0.05)
            local x0,y0,dir0=Shape.rThetaPosT(en.x,en.y,Shape.distanceObj(en,player)/2,angle)
            for i=1,4 do
                local dir=dir0+math.pi/2*i+math.pi/4
                for j=1,10 do
                    local x1,y1,dir1=Shape.rThetaPosT(x0,y0,10*j,dir)
                    shoot(x1,y1,dir1+math.pi+bias,9)
                end
            end
        end
        local patterns={pattern,pattern2,pattern3,pattern4}
        a=Event.LoopEvent{
            obj=en,
            period=600,frame=540,
            executeFunc=function(self,times)
                SFX:play('enemyPowerfulShot',true)
                -- pattern4()
                patterns[(times)%#patterns+1]()
            end
        }
    end,
}