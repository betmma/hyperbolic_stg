return {
    ID=121,
    user='ariya',
    spellName='Rejection Sign "Inactive Iwakura Amids the Flow of Seasons"',
    make=function()
        G.levelIsTimeoutSpellcard=true
        G.levelRemainingFrame=3600
        Shape.removeDistance=10000
        local center={x=400,y=1000}
        G.backgroundPattern:remove()
        G.backgroundPattern=BackgroundPattern.FixedTesselation{centerPoint=center,sideColor={0.3,0.3,0.3},faceColor={0.15,0.15,0.15}}
        for i=1,#G.backgroundPattern.sidesTable do
            local color=G.backgroundPattern.sidesTable[i].color
            for j=1,3 do
                color[j]=color[j]*0.4+0.6
            end
        end
        local a,b
        local en
        local player=Player{x=400,y=2000}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,150,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local safeR,safeTheta=math.eval(60,40),math.eval(0,math.pi)
        local safex,safey=Shape.rThetaPos(center.x,center.y,safeR,safeTheta)
        -- Circle{x=safex,y=safey,speed=0,sprite=BulletSprites.giant.red,highlight=true,safe=true,spriteTransparency=0.3,lifeFrame=6000}
        local function isLineSafe(x,y,dir,margin)
            local toSafe=Shape.to(x,y,safex,safey)
            if math.angleDiff(dir,toSafe)>math.pi/2 then -- moving away
                return true
            end
            local x2,y2=Shape.rThetaPos(x,y,30,dir)
            return Shape.distanceToLine(safex,safey,x,y,x2,y2)>(margin or 10)
        end
        local ROTATE_SPEED=0.03
        local function flowerWrap(cir)
            local angle0=cir.direction
            for i=1,5 do
                local angle=angle0+math.pi*2/5*i
                local petal=Circle{x=cir.x,y=cir.y,direction=angle,speed=0,sprite=BulletSprites.heart.red,highlight=true,lifeFrame=600,extraUpdate=function(self)
                    self.safe=cir.safe
                    self.spriteTransparency=cir.spriteTransparency
                    local t=self.frame
                    local r=math.clamp(t*0.5,0,8)
                    self.angle=(self.angle or angle)+ROTATE_SPEED
                    if not cir.removed then
                        self.x,self.y,self.direction=Shape.rThetaPosT(cir.x,cir.y,r,self.angle)
                    else
                        self.speed=math.clamp(self.speed+0.5,40,80)
                    end
                end}
            end
        end
        local function limitedTry(func,condition,maxTry)
            local count=0
            local flag=false
            local ret
            while not flag and count<maxTry do
                ret={func()}
                flag=condition(unpack(ret))
                count=count+1
            end
            if not flag then
                return nil
            end
            return unpack(ret)
        end
        local speed=1
        local function getSeasons()
            -- spring: each flower in it: spawn at [x0, y0] after [delay] frames, move to [x1, y1] in [moveFrame] frames, then explode into petals
            local springInitData={}
            for i=1,5 do
                local x,y,dir=Shape.rThetaPosT(center.x,center.y,150,math.eval(0,math.pi))
                dir=dir+math.pi
                local angle
                local count=0
                while not angle and count<10 do
                    angle=math.eval(dir,math.pi/3)
                    if not isLineSafe(x,y,angle,20) then
                        angle=nil
                    end
                    count=count+1
                end
                if not angle then
                    goto continue
                end
                for j=0,30 do
                    local xj,yj,dirj=Shape.rThetaPosT(x,y,j*10,angle)
                    if Shape.distance(xj,yj,center.x,center.y)>150 then -- leave bounds
                        break
                    end
                    local flag=false
                    local dirj2
                    count=0
                    while not flag and count<10 do
                        dirj2=math.eval(0,math.pi)
                        if isLineSafe(xj,yj,dirj2,15) then
                            flag=true
                        end
                        count=count+1
                    end
                    if not flag then
                        goto continue
                    end
                    flag=false
                    local xjaim,yjaim=Shape.rThetaPos(xj,yj,math.eval(80,10),dirj2)
                    local toSafe=Shape.to(xjaim,yjaim,safex,safey)
                    local delay=20+j*5
                    local angle2=dirj2
                    local moveFrameBase,angle3
                    count=0
                    while not flag and count<10 do
                        moveFrameBase=math.eval(200,20)
                        angle3=angle2+ROTATE_SPEED*moveFrameBase
                        if isLineSafe(xjaim,yjaim,math.modClamp(angle3,toSafe,math.pi/5),10) then
                            flag=true
                        end
                        count=count+1
                    end
                    if not flag then
                        goto continue
                    end
                    table.insert(springInitData,{x0=xj,y0=yj,delay=delay,moveFrame=moveFrameBase,x1=xjaim,y1=yjaim,angle3=angle3})
                    ::continue::
                end
                ::continue::
            end
            local function spring()
                for _,data in ipairs(springInitData) do
                    local x0,y0,delay,moveFrame,x1,y1,angle3=data.x0,data.y0,data.delay,data.moveFrame,data.x1,data.y1,data.angle3
                    Event.DelayEvent{
                        obj=en,delayFrame=delay,executeFunc=function()
                            local flower=Circle{x=x0,y=y0,speed=Shape.distance(x0,y0,x1,y1)/moveFrame*60,direction=Shape.to(x0,y0,x1,y1),sprite=BulletSprites.bigRound.red,highlight=true,lifeFrame=moveFrame,invincible=true,radius=2,safe=true,spriteTransparency=0.2,extraUpdate=function(self)
                                self.spriteTransparency=math.clamp(self.spriteTransparency+0.01,0.2,1)
                                if self.spriteTransparency>=1 then
                                    self.safe=false
                                end
                                if self.frame>=self.lifeFrame-1 then
                                    self.x,self.y=x1,y1
                                end
                            end}
                            flowerWrap(flower)
                        end
                    }
                end
            end
            -- summer: sun with laser and flame
            local sunx,suny=Shape.rThetaPos(safex,safey,90,math.eval(0,math.pi))
            local angle=Shape.to(sunx,suny,safex,safey)+math.pi
            local function summer()
                local sun=Circle{x=sunx,y=suny,speed=0,direction=angle,sprite=BulletSprites.nuke,highlight=true,lifeFrame=200,invincible=true,radius=0,safe=true,spriteTransparency=0.3,extraUpdate=function(self)
                    local t=self.frame
                    self.r0=16
                    self.radius=self.r0*math.clamp(math.min(t/20,(self.lifeFrame-t)/20),0,3)
                    self.spriteTransparency=math.clamp(self.spriteTransparency+0.01,0.3,1)
                    if self.spriteTransparency>=1 then
                        self.safe=false
                    end
                end}
                BulletSpawner{x=sunx,y=suny,period=1,lifeFrame=1,bulletNumber=17,bulletSpeed=80,bulletLifeFrame=200,bulletSize=3,warningFrame=60,fadingFrame=20,angle=angle,range=math.pi*2,bulletSprite=BulletSprites.laser.red,frequency=2,highlight=true,bulletEvents={
                    function(cir)
                        cir.invincible=true
                        cir.lifeFrame=40
                        Event.EaseEvent{
                            obj=cir,aimKey='speed',aimValue=480,easeFrame=10
                        }
                        Event.EaseEvent{
                            obj=cir,aimKey='radiusRef',aimValue=20,easeFrame=120
                        }
                        if cir.index%5==0 and cir.index>30 and cir.index<80 then
                            Event.LoopEvent{
                                obj=cir,period=5,times=5,frame=-5,executeFunc=function(self,times)
                                    local flame=Circle{x=cir.x,y=cir.y,speed=30*speed,direction=cir.direction+(1.3+times*0.1)*math.mod2Sign(times),sprite=BulletSprites.flame.red,highlight=true,lifeFrame=150,radius=2,extraUpdate={
                                        function(self)
                                            self.speed=self.speed+1*speed
                                        end}}
                                end
                            }
                        end
                    end},laserEvents={
                    function(laser)
                        Event.LoopEvent{
                            obj=laser,
                            period=1,
                            executeFunc=function(self)
                                laser.args.direction=laser.args.direction+0.002*math.cos(laser.frame/160*math.pi)
                            end
                        }
                    end
                }}
            end
            -- autumn: fruit with rotating bullets
            local num=9
            local autumnInitData={}
            for i=1,10 do
                local x,y=limitedTry(function()
                    return Shape.rThetaPos(center.x,center.y,math.eval(75,75),math.eval(0,math.pi))
                end,function(x,y)
                    return Shape.distance(x,y,safex,safey)>40
                end,10)
                if not x then
                    goto continue
                end
                local toSafe=Shape.to(x,y,safex,safey)
                local dir=toSafe+math.eval(0.15,0.05)*math.mod2Sign(i)
                table.insert(autumnInitData,{x=x,y=y,direction=dir,i=i})
                ::continue::
            end
            local function autumn()
                for _,data in ipairs(autumnInitData) do
                    local x,y,direction,i=data.x,data.y,data.direction,data.i
                    local fruit=Circle{x=x,y=y,speed=0,direction=direction,sprite=BulletSprites.giant[i%2==0 and 'orange' or 'yellow'],highlight=true,lifeFrame=600,invincible=true,radius=3,safe=true,spriteTransparency=0.0,extraUpdate=function(self)
                        if self.frame==0 then
                            self.spriteTransparency=math.eval(0.15,0.15)
                        end
                        self.spriteTransparency=math.clamp(self.spriteTransparency+0.01,0.0,1)
                        if self.spriteTransparency>=1 then
                            local spawner=BulletSpawner{x=self.x,y=self.y,period=3,lifeFrame=30,bulletNumber=num,bulletSpeed=60*speed,bulletLifeFrame=300,bulletSize=2,angle=0,range=math.pi*2,bulletSprite=BulletSprites.ellipse.orange,highlight=true,fogEffect=true,fogTime=60,spawnCircleRadius=0,spawnCircleAngle=direction,bulletExtraUpdate={
                                function(cir)
                                    cir.direction=cir.direction+0.003*math.mod2Sign(i)*speed
                                end
                            }}
                            Event.EaseEvent{
                                obj=spawner,aimKey='spawnCircleRadius',aimValue=100,easeFrame=30
                            }
                            Event.EaseEvent{
                                obj=spawner,aimKey='bulletSpeed',aimValue=100,easeFrame=30
                            }
                            self:remove()
                        end
                    end}
                end
            end
            -- winter: snowball rolling and growing
            local winterInitData={}
            local growRatio=0.1
            for i=1,40 do
                local x,y=limitedTry(function()
                    return Shape.rThetaPos(center.x,center.y,math.eval(75,75),math.eval(0,math.pi))
                end,function(x,y)
                    return Shape.distance(x,y,safex,safey)>10
                end,10)
                if not x then
                    goto continue
                end
                local distance=Shape.distance(x,y,safex,safey)
                local dir=limitedTry(function()
                    return math.eval(0,math.pi)
                end,function(dir)
                    return isLineSafe(x,y,dir,distance*(growRatio+0.05))
                end,10)
                if not dir then
                    goto continue
                end
                table.insert(winterInitData,{x=x,y=y,direction=dir})
                ::continue::
            end
            local function winter()
                for _,data in ipairs(winterInitData) do
                    local x,y,direction=data.x,data.y,data.direction
                    local snow={fogTime=math.eval(20,20),x=x,y=y,speed=40*speed,direction=direction,sprite=BulletSprites.bigRound.white,highlight=true,lifeFrame=600,invincible=true,radius=0,safe=true,spriteTransparency=0.3,extraUpdate=function(self)
                        self.spriteTransparency=math.clamp(self.spriteTransparency+0.01,0.0,1)
                        if self.spriteTransparency>=1 then
                            self.safe=false
                        end
                        local dis=Shape.distance(self.x,self.y,x,y)
                        self.radius=dis*growRatio
                        if Shape.distance(self.x,self.y,center.x,center.y)>170 then
                            self.spriteTransparency=math.clamp(self.spriteTransparency-0.03,0,1)
                            if self.spriteTransparency<=0 then
                                self:remove()
                            end
                        end
                    end}
                    BulletSpawner.wrapFogEffect(snow)
                end
            end
            return {spring,summer,autumn,winter}
        end
        local seasons=getSeasons()
        local backgroundColors={{0.25,0.6,0.3},{0.8,0.25,0.18},{0.8,0.8,0.18},{0.2,0.2,0.2}}
        a=Event.LoopEvent{
            obj=en,period=360,frame=300,executeFunc=function(self,times)
                SFX:play('enemyPowerfulShot',true)
                seasons[(times)%4+1]()
                a.period=math.clamp(a.period*0.9,60,600)
                speed=(300/a.period)^0.5
                local c=backgroundColors[(times)%4+1]
                Event.LoopEvent{
                    obj=en,period=1,times=60,executeFunc=function(self)
                        for i=1,3 do
                            G.backgroundPattern.faceColor[i]=G.backgroundPattern.faceColor[i]*0.9+c[i]*0.1*0.5
                            G.backgroundPattern.sideColor[i]=G.backgroundPattern.sideColor[i]*0.9+c[i]*0.1
                        end
                    end
                }
            end,
        }
    end,
}