return {
    ID=103,
    user='byakuren',
    spellName='Flying Bowl "Legendary Flying Saucer"',
    make=function()
        G.levelRemainingFrame=10800
        Shape.removeDistance=1e100
        local center={x=400,y=300000}
        local a,b
        local en
        local hplevel=1
        en=Enemy{x=center.x,y=center.y,mainEnemy=true,maxhp=14400,hpSegments={0.75,0.5,0.25},hpSegmentsFunc=function(self,hpLevel)
            -- Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
            hplevel=hplevel+1
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local function hyperThetaPosT(x,y,r,direction,delta)
            local x1,y1,dir1=Shape.rThetaPosT(x,y,delta,direction+math.pi/2)
            dir1=dir1-math.pi/2
            local x2,y2,dir2=Shape.rThetaPosT(x1,y1,r,dir1)
            dir2=dir2+math.pi/2
            local x3,y3,dir3=Shape.rThetaPosT(x2,y2,-delta,dir2)
            return x3,y3,dir3-math.pi/2
        end
        -- several rotating lasers close to one point and transform into bullets will be good
        local function rotate(x,y,direction,rotateSpeed,attackMode,T,color)
            rotateSpeed=rotateSpeed or 0.02
            attackMode=attackMode or 0
            T=T or 300
            local cls=Laser.LaserUnit
            local sprite=BulletSprites.laserDark.black
            if attackMode==2 then
                cls=Circle
                sprite=BulletSprites.bill[color or 'red']
            end
            local x0,y0,dir0=Shape.rThetaPosT(x,y,520,direction)
            local core=Laser.LaserUnit{x=x0,y=y0,sprite=BulletSprites.note.red,lifeFrame=T*2,speed=30,radius=0,direction=dir0,invincible=true,extraUpdate={
                function(self)
                    local t=self.frame
                    local process=(t-T)/T
                    self.x,self.y,self.direction=Shape.rThetaPosT(x,y,(process)^2*500+20,direction)
                    self.direction=self.direction+math.pi/2
                    direction=direction+rotateSpeed*(1-math.abs(process))^4
                    -- self.x,self.y,self.direction=hyperThetaPosT(x,y,((t-300)/300)*150,direction,250)
                end
            }
            }
            local last=nil
            for i=-15,15 do
                local r=i*10
                local dangle=i*0
                local x0,y0,dir0=hyperThetaPosT(x0,y0,r,dir0+dangle,-130)
                local sub=cls{x=x0,y=y0,sprite=sprite,lifeFrame=10000,speed=30,radius=3,direction=dir0,invincible=true,extraUpdate={
                    function(self)
                        if core.removed then
                            self:remove()
                            return
                        end
                        self.x,self.y,self.direction=hyperThetaPosT(core.x,core.y,r,core.direction+dangle,-130)
                        self.spriteTransparency=core.spriteTransparency
                        local t=self.frame
                        if attackMode==1 then -- not used. already too hard (^^;
                            if math.abs(i)<5 and t>T*0.8 and t<T*1.2 and t%10==0 then
                                local circle={x=self.x,y=self.y,lifeFrame=500,speed=20,direction=self.direction+math.pi*(0.5+0.125*i),sprite=BulletSprites.note.red,fogEffect=true,fogTime=20+T*1.2-t
                                ,extraUpdate={
                                    function(circle)
                                        circle.speed=circle.speed+0.1
                                    end
                                }
                                }
                                BulletSpawner.wrapFogEffect(circle)
                            end
                        elseif attackMode==2 then
                        end
                    end
                }
                }
                if last then
                    last.next=sub
                    sub.previous=last
                end
                last=sub
            end
        end
        -- radius controls each rotate closer/farther to center (negative is closer)
        local function multiRotate(x,y,number,rotateSpeed,baseDirection,attackMode,T,radius)
            baseDirection=baseDirection or 0
            radius=radius or 0
            local colors={'red','blue','green','yellow','purple'}
            local color=math.randomSample(colors,1)[1]
            for i=0,number-1 do
                local angle=baseDirection+i*math.pi*2/number
                local x1,y1,angle1=Shape.rThetaPosT(x,y,radius,angle)
                rotate(x1,y1,angle1,rotateSpeed,attackMode,T,color)
            end
        end
        Event.LoopEvent{
            obj=en,period=120,frame=60,
            executeFunc=function(self,times)
                local r=math.eval(30,10)
                local theta=Shape.toObj(en,center)+math.eval(0,math.pi/3)
                local aimx,aimy=Shape.rThetaPos(en.x,en.y,r,theta)
                Event.LoopEvent{
                    obj=en,period=1,times=90,executeFunc=function(self)
                        Shape.moveTowards(en,{x=aimx,y=aimy},0.03,true,true)
                    end
                }
                local tx,ty,tt=Shape.rThetaPosT(player.x,player.y,r,theta)
                multiRotate(tx,ty,1,0.015,tt+math.pi,0)
                if hplevel>=2 and times%2==0 then
                    Event.DelayEvent{
                        obj=en,delayFrame=60,executeFunc=function()
                            local r=math.eval(30,10)
                            local theta=Shape.toObj(en,center)+math.eval(0,math.pi/3)
                            local tx,ty,tt=Shape.rThetaPosT(player.x,player.y,r,theta)
                            multiRotate(tx,ty,hplevel,-0.01,tt+math.pi/2,2,400,-30)
                        end
                    }
                end
                if hplevel==4 and times%3==0 then
                    local r=math.eval(30,10)
                    local theta=Shape.toObj(en,center)+math.eval(0,math.pi/3)
                    local tx,ty,tt=Shape.rThetaPosT(player.x,player.y,r,theta)
                    multiRotate(tx,ty,1,-0.01,tt+math.pi/2,2,600,-150)
                end
            end
        }
    end
}