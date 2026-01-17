return {
    ID=151,
    quote='?',
    user='nitori',
    spellName='Water Sign "Water Fighting"', 
    make=function()
        G.levelRemainingFrame=9000
        Shape.removeDistance=2000000
        local a,b
        local en
        local gravityBase,isAboveWater,gravityDirection
        local enterPhase4Frame=0
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.85,0.5,0.25},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            -- a.spawnEvent.frame=a.spawnEvent.period-60
            en:addHPProtection(600,10)
            if hpLevel==1 then
                a.bulletSprite=BulletSprites.lightRound.blue
                a.bulletSpeed=100
                a.bulletExtraUpdate={
                    gravityBase(0.99,0.99,-0.3),
                }
                a.bulletEvents={
                    function(cir,args,self)
                        local sign=math.mod2Sign(a.spawnEvent.executedTimes)
                        if a.upwardFlag then
                            Event.LoopEvent{
                                obj=cir,period=1,executeFunc=function()
                                    if not isAboveWater(cir.x,cir.y) then
                                        cir.direction=cir.direction+0.01*sign
                                    end
                                end
                            }
                        end
                    end
                }
            elseif hpLevel==2 then
                a.bulletSprite=BulletSprites.round.purple
                a.bulletBatch=Asset.bulletHighlightBatch
                a.spawnEvent.period=20
                a.angle='player'
                a.range=0.9
                a.bulletNumber=30
                a.bulletEvents={
                    function(cir,args,self)
                        local sign=math.mod2Sign(a.spawnEvent.executedTimes)
                        cir.speed=(args.index*10*sign)%100+30
                    end
                }
            elseif hpLevel==3 then
                enterPhase4Frame=en.frame
                local function around(obj,radius,color)
                    BulletSpawner{x=obj.x,y=obj.y,period=2,frame=1,lifeFrame=3,bulletNumber=30,bulletSpeed=0,bulletLifeFrame=10000,angle='1.57',range=math.pi*2,bulletSprite=BulletSprites.giant[color or 'blue'],highlight=true,bulletEvents={
                        function(cir,args,self)
                            cir.invincible=true
                            cir.angle=args.index*math.pi*2/30
                        end
                    },
                    bulletExtraUpdate={
                        function(cir)
                            local ax,ay=Shape.rThetaPos(obj.x,obj.y,math.min(radius,cir.frame/3),cir.angle+cir.frame/20)
                            cir.x,cir.y=ax,ay
                            if obj.removed then
                                cir:remove()
                            end
                        end
                    }}
                end
                Event.DelayEvent{
                    obj=en,delayFrame=60,executeFunc=function()
                        SFX:play('enemyPowerfulShot')
                        around(en,30)
                    end
                }
                a:remove()
                a=BulletSpawner{x=en.x,y=en.y,period=400,frame=250,lifeFrame=10000,bulletNumber=2,bulletSpeed=0,bulletLifeFrame=1500,angle=gravityDirection(en.x,en.y),range=math.pi*2,bulletSprite=BulletSprites.giant.blue,highlight=true,spawnSFXVolume=1,bulletEvents={
                    function(cir,args,self)
                        cir.invincible=true
                        local sign=math.mod2Sign(a.spawnEvent.executedTimes)
                        local yoffset,color
                        if sign==1 then
                            yoffset={-1.4,1,2,3}
                            color='blue'
                        else
                            yoffset={-1,1,2.4,3.4}
                            color='red'
                        end
                        around(cir,50,color)
                        cir:changeSpriteColor(color)
                        cir.extraUpdate={
                            function(cir)
                                cir.direction=gravityDirection(cir.x,cir.y)+math.mod2Sign(args.index)*math.pi/2
                                cir.speed=math.min(30,cir.frame/10)
                                if cir.frame%20==0 and cir.frame>100 then
                                    local finalcir=Circle{x=cir.x,y=cir.y,sprite=BulletSprites.rain[color],highlight=true,lifeFrame=2000,speed=0}
                                    finalcir.extraUpdate={
                                        gravityBase(0.95,0.98,-0.4)
                                    }
                                end
                        end
                        }
                        for i=1,4 do
                            local yoffseti=yoffset[i]
                            local subcir=Circle{x=cir.x,y=cir.y,invincible=true,sprite=BulletSprites.giant[color],highlight=true,lifeFrame=2000}
                            around(subcir,50,color)
                            Event.LoopEvent{
                                obj=subcir,period=1,executeFunc=function()
                                    local gdir=gravityDirection(cir.x,cir.y)
                                    subcir.x,subcir.y=Shape.rThetaPos(cir.x,cir.y,(yoffseti)*math.min(80,subcir.frame),gdir)
                                end
                            }
                        end
                    end
                }}
            end
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,300,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local waterHeight=-150
        local surfaceAx,surfaceAy,sdir,surfaceBx,surfaceBy=400,2000,math.pi/2,410,2000
        isAboveWater=function (x,y)
            return Shape.leftToLine(x,y,surfaceAx,surfaceAy,surfaceBx,surfaceBy)
        end
        gravityDirection=function(x,y)
            local txy=Shape.nearestToLine(x,y,surfaceAx,surfaceAy,surfaceBx,surfaceBy)
            local toDir=Shape.to(x,y,txy[1],txy[2])
            return toDir+(isAboveWater(x,y) and 0 or math.pi)
        end
        -- G.backgroundPattern:remove()
        -- G.backgroundPattern=BackgroundPattern.FollowingTesselation()
        local drawRef=G.backgroundPattern.draw
        if G.backgroundPattern.drawInjected then -- ensure drawRef is the original one, and only inject once on pressing R
            drawRef=G.backgroundPattern.drawRef
        else
            G.backgroundPattern.drawRef=drawRef 
        end
        local function getDiskRadius()
            return G.DISK_RADIUS_BASE[G.viewMode.hyperbolicModel]
        end
        G.backgroundPattern.draw=function(self)
            local colorRef={love.graphics.getColor()}
            love.graphics.setColor(0,0,0,1)
            love.graphics.rectangle('fill',0,0,800,600)
            love.graphics.setColor(0.2,0.2,1,0.5)
            local dis=Shape.distanceToLine(player.x,player.y,surfaceAx,surfaceAy,surfaceBx,surfaceBy)*(isAboveWater(player.x,player.y) and 1 or -1)
            local centerX,radius
            centerX=WINDOW_WIDTH/2
            if G.viewMode.hyperbolicModel==G.CONSTANTS.HYPERBOLIC_MODELS.UHP then
                if G.UseHypRotShader then
                    local x1,y1=Shape.rThetaPos(centerX,WINDOW_HEIGHT/2,dis,math.pi/2)
                    radius=y1-Shape.axisY
                else
                    local surfaceAx2,surfaceAy2=Shape.rotateAround(surfaceAx,surfaceAy,-player.naturalDirection,player.x,player.y)
                    local surfaceBx2,surfaceBy2=Shape.rotateAround(surfaceBx,surfaceBy,-player.naturalDirection,player.x,player.y)
                    centerX,radius=Shape.lineCenter(surfaceAx2,surfaceAy2,surfaceBx2,surfaceBy2)
                end
                love.graphics.circle('fill',centerX,Shape.axisY,99999)
                love.graphics.setColor(0,0,0,1)
                love.graphics.circle('fill',centerX,Shape.axisY,radius)
            elseif G.viewMode.hyperbolicModel==G.CONSTANTS.HYPERBOLIC_MODELS.P_DISK then
                dis=dis/Shape.curvature
                local r=math.tanh(dis/2)
                local centerY=(1+r*r)/(2*r)
                local ratio=WINDOW_HEIGHT/2*getDiskRadius()
                if dis>0 then
                    -- love.graphics.stencil(function()
                    --     love.graphics.circle("fill", centerX,WINDOW_HEIGHT/2,ratio)
                    -- end, "replace", 1)
                    -- love.graphics.setStencilTest("equal", 1)
                    love.graphics.circle('fill',centerX,WINDOW_HEIGHT/2+ratio*centerY,ratio*(centerY-r))
                    -- love.graphics.setStencilTest()
                    -- love.graphics.clear(false, true, 0)
                else
                    love.graphics.circle('fill',centerX,WINDOW_HEIGHT/2,ratio)
                    love.graphics.setColor(0,0,0,1)
                    love.graphics.circle('fill',centerX,WINDOW_HEIGHT/2+ratio*centerY,ratio*(-centerY+r))
                end
            elseif G.viewMode.hyperbolicModel==G.CONSTANTS.HYPERBOLIC_MODELS.K_DISK then
                dis=dis/Shape.curvature
                local r=math.tanh(dis/2)
                r=(2*r)/(1+r*r)
                local ratio=WINDOW_HEIGHT/2*getDiskRadius()
                love.graphics.circle('fill',centerX,WINDOW_HEIGHT/2,ratio)
                love.graphics.setColor(0,0,0,1)
                love.graphics.rectangle('fill',centerX-ratio,WINDOW_HEIGHT/2-ratio,ratio*2,ratio*(1+r))
            end
            love.graphics.setColor(colorRef)
            love.graphics.setBlendMode('add')
            drawRef(self)
            love.graphics.setBlendMode('alpha')
        end
        G.backgroundPattern.drawInjected=true
        local vyAccum=0 -- simulate gravity / buoyancy
        local gravity,buoyancy=2,1
        player.moveUpdate=function(self,dt)
            self.naturalDirection=0
            local speed,direction=self:getKeyboardMoveSpeed()
            local vx,vy=math.rTheta2xy(speed,direction)
            local aboveWater=isAboveWater(self.x,self.y)
            if aboveWater then
                vyAccum=vyAccum+gravity
            else
                vyAccum=vyAccum+vy/30
                vyAccum=vyAccum-buoyancy
                -- vertical friction
                vyAccum=vyAccum*0.98
            end
            speed,direction=math.xy2rTheta(vx,vyAccum)
            
            self.naturalDirection=gravityDirection(self.x,self.y)-math.pi/2

            direction=direction+self.naturalDirection
            self.speed,self.direction=speed,direction
            self.super.update(self,dt)

            local count=0
            while self.border and count<10 and not self.border:inside(self.x,self.y) do
                count=count+1
                local line={self.border:inside(self.x,self.y)}
                local p=Shape.nearestToLine(self.x,self.y,line[2],line[3],line[4],line[5])
                local verticalDir=Shape.to(self.x,self.y,p[1],p[2])
                vyAccum=vyAccum*math.abs(math.cos(verticalDir-self.naturalDirection))
                self.x=p[1]--xref+dot*dirx
                self.y=p[2]--yref+dot*diry
            end
        end
        gravityBase=function(frictionY,frictionX,buoy,inborder)
            frictionY,frictionX=frictionY or 0.995,frictionX or 1
            buoy=buoy or buoyancy
            return function(cir)
                local gravityOffset=gravityDirection(cir.x,cir.y)-math.pi/2
                local vx,vy=math.rTheta2xy(cir.speed,cir.direction-gravityOffset)
                local aboveWater=isAboveWater(cir.x,cir.y)
                if aboveWater then
                    vy=vy+gravity
                else
                    vy=vy-buoy
                    -- vertical friction
                    vy,vx=vy*frictionY,vx*frictionX
                end
                if inborder then
                    local count=0
                    while player.border and count<10 and not player.border:inside(cir.x,cir.y) do
                        count=count+1
                        local line={player.border:inside(cir.x,cir.y)}
                        local p=Shape.nearestToLine(cir.x,cir.y,line[2],line[3],line[4],line[5])
                        local verticalDir=Shape.to(cir.x,cir.y,p[1],p[2])
                        vy=vy*math.abs(math.cos(verticalDir-gravityOffset))
                        cir.x=p[1]
                        cir.y=p[2]
                    end
                end
                cir.speed,cir.direction=math.xy2rTheta(vx,vy)
                cir.direction=cir.direction+gravityOffset
            end
        end
        a=BulletSpawner{x=en.x,y=en.y,period=10,frame=-100,lifeFrame=10000,bulletNumber=3,bulletSpeed=140,bulletLifeFrame=1000,angle='1.57',range=math.pi/2,bulletSprite=BulletSprites.giant.blue,highlight=true,bulletEvents={
        },
        bulletExtraUpdate={
            gravityBase(0.995,nil,0.5)
        }}
        Event.LoopEvent{
            obj=en,period=1,executeFunc=function()
                surfaceAx,surfaceAy,sdir=Shape.rThetaPosT(center.x,center.y,waterHeight,-math.pi/2)
                surfaceBx,surfaceBy=Shape.rThetaPos(surfaceAx,surfaceAy,10,sdir+math.pi/2)
                local t=en.frame
                local hpLevel=en:getHPLevel()
                if t==60 then
                    SFX:play('enemyCharge')
                    Event.LoopEvent{
                        obj=en,period=1,times=100,executeFunc=function()
                            waterHeight=waterHeight+1
                        end
                    }
                end
                if hpLevel<4 then
                    gravityBase(0.98,0.98,nil,true)(en)
                else
                    gravityBase(0.95,0.98,3,true)(en)
                end
                a.x,a.y=en.x,en.y
                if hpLevel==1 then
                    a.range=math.pi*(0.5+0.1*math.sin(t/100))
                    a.angle=math.eval(gravityDirection(en.x,en.y),0.03)+0.3*math.sin(t/71)
                elseif hpLevel==2 then
                    a.range=math.pi*(0.2+0.1*math.sin(t/100))
                    a.bulletNumber=5
                    a.angle=math.eval(gravityDirection(en.x,en.y),0.03)+0.1*math.sin(t/71)+math.pi
                    a.upwardFlag=true
                    if t%300>150 then
                        a.upwardFlag=false
                        a.angle=Shape.to(en.x,en.y,player.x,player.y)+0.1*math.sin(t/17)
                    end
                    if t%40==0 then
                        a.spawnEvent.frame=0
                        a.spawnEvent.period=4
                    elseif t%40==20 then
                        a.spawnEvent.frame=0
                        a.spawnEvent.period=1000
                    end
                elseif hpLevel==4 then
                    -- waterHeight=-50+50*math.sin((t-enterPhase4Frame)/100)
                end
                if t%300==240 and hpLevel<4 then
                    SFX:play('enemyCharge')
                    Event.LoopEvent{
                        obj=en,period=1,times=60,executeFunc=function()
                            if hpLevel==1 then
                                en.speed=en.speed+3
                            else
                                local vx,vy=math.rTheta2xy(en.speed,en.direction)
                                local toPlayerDir=Shape.to(en.x,en.y,player.x,player.y)
                                local dvx,dvy=math.rTheta2xy(4,toPlayerDir)
                                en.speed, en.direction=math.xy2rTheta(vx+dvx,vy+dvy)
                            end
                            -- if hpLevel==3 then
                            --     Shape.moveTowards(en,player,1,true)
                            -- end
                        end
                    }
                end
            end
        }
    end
}