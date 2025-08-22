return {
    ID=113,
    user='asama',
    spellName='Serpent Sign "Ouroborous\'s Feast"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=3000
        local center={x=400,y=300}
        local a,b
        local en
        local player=Player{x=400,y=600}
        local circle
        en=Enemy{x=400,y=300,sprite=Asset.boss.asama,mainEnemy=true,maxhp=8400,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            SFX:play('enemyCharge',true)
            en:addHPProtection(600,10)
            a.spawnEvent.frame=-99999
            Event.DelayEvent{obj=en,delayFrame=60,executeFunc=function()
                circle(400,300,120,Shape.toObj(en,player),60,120,nil,true)
            end}
        end}
        en:addHPProtection(600,10)
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,100,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        circle=function(x,y,speed,direction,straightTime,turnTime,curveSign,regenerate)
            curveSign=curveSign or math.mod2Sign(a.spawnEvent.executedTimes)
            local startingLevel=en:getHPLevel()
            local t0=en.frame
            local firstAngle
            local sprite=regenerate and BulletSprites.heart.orange or BulletSprites.cross.purple
            local sprite2=regenerate and BulletSprites.bigRound.orange or BulletSprites.rim.purple
            local function one(count,offDis,offDir,isFirst)
                local passed=en.frame-t0
                local basePos={x=x,y=y,direction=direction}
                local cir=Circle{x=x,y=y,speed=0,direction=direction,lifeFrame=straightTime+turnTime*2-passed,sprite=sprite,highlight=true,safe=true,invincible=true,spriteTransparency=1,extraUpdate=function(self)
                    if en:getHPLevel()~=startingLevel then
                        self:remove()
                        return
                    end
                    -- self.spriteTransparency=math.clamp(self.frame/10,0,1)
                    if self.frame>10 then
                        self.safe=false
                    end
                    local moveDistance=speed* 1/60 * Shape.timeSpeed * ((basePos.y-Shape.axisY)/Shape.curvature)
                    basePos.x = basePos.x +  moveDistance * math.cos(basePos.direction) 
                    basePos.y = basePos.y + moveDistance * math.sin(basePos.direction) 
                    basePos.direction = basePos.direction - moveDistance/((basePos.y-Shape.axisY)/math.cos(basePos.direction))
                    if self.frame==straightTime then
                        local r0=speed*turnTime/60/math.pi/2
                        local x,y=Shape.rThetaPos(basePos.x,basePos.y,r0,basePos.direction+math.pi/2*curveSign)
                        self.center={x=x,y=y}
                        self.centerDirection=Shape.to(x,y,basePos.x,basePos.y)
                        self.r0=r0
                    end
                    local t1=0
                    local rRatio=1
                    if self.frame>=straightTime then
                        t1=self.frame-straightTime
                        local dTheta=math.pi*2/turnTime*curveSign
                        if t1+passed>=turnTime then
                            rRatio=1-(t1+passed-turnTime)/turnTime
                            dTheta=dTheta*math.interpolate((turnTime-passed)/turnTime,1,math.max(0.1,1-t1*0.05))
                        end
                        basePos.direction=basePos.direction+dTheta
                        self.centerDirection=self.centerDirection+dTheta
                        if isFirst then
                            firstAngle=self.centerDirection
                        else
                            if firstAngle and curveSign*self.centerDirection<curveSign*(firstAngle)-math.pi*2 then
                                self:remove() -- eaten by head
                                
                                if count%5==0 then     
                                    Circle{x=self.x,y=self.y,speed=0,direction=Shape.toObj(self,player),lifeFrame=300,sprite=sprite2,highlight=true,extraUpdate=function(self)
                                        if self.frame<40 then
                                            self.speed=self.speed+1
                                        end
                                    end}
                                end
                            end
                        end
                        basePos.x,basePos.y=Shape.rThetaPos(self.center.x,self.center.y,self.r0*rRatio,self.centerDirection)
                    end
                    -- local mouthRatio=t1>=turnTime and (self.lifeFrame-self.frame)/(self.lifeFrame-straightTime-turnTime) or 1
                    local dis=(offDis or 0)+ math.sin(self.frame/5)*3*math.min(1,count/10)
                    dis=dis*rRatio*math.min(1,self.frame/10) -- shrinking & prevent generation point varying
                    self.x,self.y=Shape.rThetaPos(basePos.x,basePos.y,dis,basePos.direction+(offDir or math.pi/2))
                    self.direction=basePos.direction
                    if isFirst and self.frame==self.lifeFrame then
                        SFX:play('enemyShot',true)
                        BulletSpawner{x=self.x,y=self.y,period=1,frame=0,lifeFrame=2,bulletNumber=30,bulletSpeed=20,bulletLifeFrame=10000,range=math.pi*10.1,angle='0+999',bulletSprite=BulletSprites.round.red,highlight=true
                        }
                    end
                    if isFirst and self.frame==self.lifeFrame-30 then
                        if regenerate then
                            local r0=speed*turnTime/60/math.pi/2
                            local toplayer=Shape.toObj(self.center,player)
                            local tocenter=Shape.toObj(self.center,{x=400,y=300})
                            tocenter=math.modClamp(tocenter,toplayer,math.pi/2)
                            curveSign=math.sign(tocenter-toplayer)
                            local aimx,aimy=Shape.rThetaPos(player.x,player.y,r0,Shape.toObj(player,self.center)+math.pi/2*curveSign)
                            local to2=Shape.toObj(self.center,{x=aimx,y=aimy})
                            circle(self.center.x,self.center.y,speed,to2,math.ceil(Shape.distanceObj(self.center,player)*60/speed),turnTime,curveSign,true)
                            for i=1,5 do
                                circle(self.center.x,self.center.y,40,toplayer+math.pi/7*(i-2.5),100+i*10,240)
                            end
                        end
                    end
                end}
            end
            Event.LoopEvent{
                obj=en,period=5,times=math.ceil(turnTime/5),
                executeFunc=function(self,executedTimes,times)
                    if executedTimes==0 then
                        for i=1,3 do
                            one(0,i*3,math.pi/3)
                            -- one(0,i*3,0)
                            one(0,i*3,-math.pi/3)
                        end
                        -- for i=1,12 do
                        --     one(0,5,-i*math.pi/6)
                        -- end
                    end
                    one(executedTimes,nil,nil,executedTimes==0)
                end
            }
        end
        a=BulletSpawner{x=en.x,y=en.y,period=400,frame=350,lifeFrame=10000,bulletNumber=5,bulletSpeed=40,bulletLifeFrame=10000,angle='player',range=math.pi*2,highlight=true,bulletSprite=BulletSprites.rim.red,fogEffect=true,fogTime=3,bulletEvents={
            function(cir,args,self)
                local index=args.index
                if a.spawnEvent.executedTimes%2==1 then
                    index=a.bulletNumber+1-index
                end
                Event.DelayEvent{obj=en,delayFrame=index*15,executeFunc=function()
                    circle(cir.x,cir.y,40,cir.direction+math.pi/5,60,240)
                    circle(cir.x,cir.y,40,cir.direction,120,240)
                end}
                cir:remove()
            end
        }}

    end
}