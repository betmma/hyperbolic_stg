return {
    ID=122,
    user='nina',
    spellName='Truth "Moon Landing Studio"',
    make=function()
        G.levelRemainingFrame=10800
        Shape.removeDistance=7000
        local center={x=400,y=1000}
        local a,b
        local en,hpLevel
        local player=Player{x=400,y=2000}
        en=Enemy{x=400,y=1000,mainEnemy=true,maxhp=9400,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            SFX:play('enemyCharge',true)
            en:addHPProtection(600,10)
        end}
        en:addHPProtection(600,10)
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,150,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local relativeUpdate=function(self)
            if self.core.removed then
                for speed=0,hpLevel==1 and 60 or 10,10 do
                    Circle{x=self.x,y=self.y,direction=Shape.toObj(self.core,self),speed=speed,sprite=self.sprite,lifeFrame=300,highlight=false,extraUpdate={function(self)
                        self.direction=self.direction+math.eval(0,0.005)
                        self.speed=self.speed*0.95+80*0.05
                    end}}
                end
                self:remove()
            end
            self.x,self.y,self.direction=Shape.rThetaPosT(self.core.x,self.core.y,self.r*math.min(self.core.ratio,self.frame/120),self.theta+self.core.direction)
            self.direction=self.direction+self.dirDiff
        end
        local function relativeCircle(args)
            local core=args.core
            local x,y,cx,cy=args.x,args.y,core.x,core.y
            local r,theta=Shape.distance(cx,cy,x,y),Shape.to(cx,cy,x,y)-core.direction
            local dirDiff=args.direction-core.direction
            args.x,args.y=cx,cy
            local cir=Circle(args)
            cir.core=core
            cir.r,cir.theta,cir.dirDiff=r,theta,dirDiff
            cir.extraUpdate[#cir.extraUpdate+1]=relativeUpdate
            return cir
        end
        local function line(x1,y1,x2,y2,gap,initGap,core,delta)
            local distance=Shape.distance(x1,y1,x2,y2)
            local dir=Shape.to(x1,y1,x2,y2)
            for dis=initGap,distance,gap do
                local x,y,dir2=Shape.rThetaPosT(x1,y1,dis,dir)
                local cir=relativeCircle{core=core,x=x,y=y,direction=dir2+delta,speed=0,sprite=BulletSprites.round.red,lifeFrame=1000,invincible=true,}
            end
        end
        local function spotlight(x,y,core)
            local n=10
            local distance=Shape.distance(x,y,core.x,core.y)
            local dir=Shape.to(x,y,core.x,core.y)
            for i=1,n-1 do
                local ratio=i/n
                local x0,y0=Shape.rThetaPos(x,y,distance*ratio,dir)
                local light=Circle{x=x0,y=y0,speed=0,sprite=BulletSprites.explosion.gray,highlight=true,spriteTransparency=0,lifeFrame=1000,invincible=true,safe=true,radius=2+2*ratio,extraUpdate={function(self)
                    if self.frame<=30 then
                        self.spriteTransparency=self.spriteTransparency+1/60
                    elseif self.frame>900 then
                        self.spriteTransparency=math.max(0,self.spriteTransparency-1/100)
                    end
                    if core.removed then
                        if not self.flag then
                            self.flag=true
                            local dir=Shape.to(self.x,self.y,core.x,core.y)
                            for index=-1,1 do
                                local xi,yi,diri=Shape.rThetaPosT(self.x,self.y,5*index,dir)
                                for sign=-1,1,2 do
                                    local args={x=xi,y=yi,direction=diri+sign*math.pi/2,speed=40,sprite=BulletSprites.bigStar.gray,radius=2,lifeFrame=1000,fogTime=i*3+10,highlight=true}
                                    BulletSpawner.wrapFogEffect(args)
                                end
                            end
                        end
                        self.spriteTransparency=math.max(0,self.spriteTransparency-1/100)
                    end
                    if self.spriteTransparency<=0 then
                        self:remove()
                    end
                    self.x,self.y=Shape.rThetaPos(x,y,Shape.distance(x,y,core.x,core.y)*ratio,Shape.to(x,y,core.x,core.y))
                end}}
            end
        end
        local function rocket(x,y,angle,ratio)
            SFX:play('enemyPowerfulShot')
            local core=Circle{x=x,y=y,direction=angle,sprite=BulletSprites.round.red,speed=0,lifeFrame=1000,invincible=true}
            hpLevel=en:getHPLevel()
            local range=hpLevel==1 and 2 or 1
            for i=-range,range do
                local angle2=angle+math.pi/3*i
                local x1,y1=Shape.rThetaPos(center.x,center.y,180,angle2)
                spotlight(x1,y1,core)
            end
            Event.DelayEvent{
                obj=core,delayFrame=60,executeFunc=function()
                    Event.EaseEvent{
                        obj=core,aimKey='speed',aimValue=-50,easeFrame=240,progressFunc=Event.sineBackProgressFunc,
                        afterFunc=function()
                            core:remove()
                        end,
                    }
                    Event.LoopEvent{
                        obj=core,period=2,times=120,executeFunc=function()
                            SFX:play('enemyShot',true)
                            local r=math.eval(0,10)
                            local x,y,dir=Shape.rThetaPosT(core.x,core.y,r,core.direction-math.pi/2)
                            local args={x=x,y=y,direction=dir-math.pi/2,speed=math.eval(70,20),sprite=BulletSprites.flame.red,lifeFrame=200,fogTime=10,radius=2}
                            BulletSpawner.wrapFogEffect(args)
                        end
                    }
                end
            }
            core.ratio=ratio or 1
            local size=10
            for sign=-1,1,2 do
                local angle2=angle+sign*math.pi/2
                -- bottom line
                local x1,y1,dir1
                for i=1,3 do
                    x1,y1,dir1=Shape.rThetaPosT(x,y,i*size,angle2)
                    local cir=relativeCircle{core=core,x=x1,y=y1,direction=dir1-sign*math.pi/2,speed=0,sprite=BulletSprites.round.red,lifeFrame=1000,invincible=true,}
                end
                -- ( shape
                local xlim,ylim=Shape.rThetaPos(x,y,10,angle) -- x,y,xlim,ylim axis of symmetry
                dir1=dir1-math.pi/3*sign
                local side=Shape.leftToLine(x1,y1,x,y,xlim,ylim)
                local xm,ym
                local count=0
                while Shape.leftToLine(x1,y1,x,y,xlim,ylim)==side and count<30 do
                    count=count+1
                    if count==12 then
                        xm,ym=x1,y1
                    end
                    if count==2 then -- wing
                        local dirw=dir1+math.pi/2*sign
                        local xw,yw=Shape.rThetaPos(x1,y1,size*4,dirw)
                        line(x1,y1,xw,yw,size,size,core,sign*math.pi/2)
                        local xw2,yw2=Shape.rThetaPos(x1,y1,size*2,dir1)
                        line(xw2,yw2,xw,yw,size,size,core,-sign*math.pi/2)
                    end
                    x1,y1,dir1=Shape.rThetaPosT(x1,y1,size,dir1)
                    dir1=dir1-sign*math.pi/30
                    local cir=relativeCircle{core=core,x=x1,y=y1,direction=dir1,speed=0,sprite=BulletSprites.round.red,lifeFrame=1000,invincible=true,}
                end
                -- horizontal line
                local xm2,ym2=unpack(Shape.nearestToLine(xm,ym,x,y,xlim,ylim))
                line(xm2,ym2,xm,ym,size,size/2,core,-sign*math.pi/2)
                -- circle
                if sign==-1 then
                    local x2,y2=unpack(Shape.nearestToLine(x1,y1,x,y,xlim,ylim))
                    local dirc=Shape.to(x2,y2,x,y)
                    local x3,y3,dir3=Shape.rThetaPosT(x2,y2,size*6,dirc)
                    local centerCirc=relativeCircle{core=core,x=x3,y=y3,direction=dir3,speed=0,sprite=BulletSprites.round.red,lifeFrame=1000,invincible=true,spriteTransparency=0}
                    if hpLevel==1 then 
                        centerCirc.extraUpdate[#centerCirc.extraUpdate+1]=function(self)
                            en.x,en.y=self.x,self.y
                        end
                    end
                    local r,N=size*2,10
                    for i=0,N-1 do
                        local angle3=dirc+math.pi/2+math.pi*2/N*i
                        local x4,y4=Shape.rThetaPos(x3,y3,r,angle3)
                        local cir=relativeCircle{core=core,x=x4,y=y4,direction=angle3+math.pi/2,speed=0,sprite=BulletSprites.round.red,lifeFrame=1000,invincible=true,}
                    end
                end
            end
        end
        Event.LoopEvent{
            obj=en,period=300,frame=200,executeFunc=function()
                local hpLevel=en:getHPLevel()
                if hpLevel==1 then
                    rocket(en.x,en.y,Shape.toObj(en,player)+math.pi,0.5)
                else
                    rocket(en.x,en.y,Shape.toObj(en,player)+math.pi,0.5)
                    Event.DelayEvent{
                        obj=en,delayFrame=150,executeFunc=function()
                            rocket(en.x,en.y,Shape.toObj(en,player),0.5)
                        end,
                    }
                end
            end,
        }
    end,
}