return {
    ID=119,
    user='ariya',
    spellName='Permanence Sign "Unmoving Fossil"',
    make=function()
        G.backgroundPattern:remove()
        G.viewMode.hyperbolicModel=G.CONSTANTS.HYPERBOLIC_MODELS.UHP
        Shape.axisY=-20
        G.levelRemainingFrame=7200
        Shape.removeDistance=20000
        local center={x=400,y=3000}
        G.backgroundPattern=BackgroundPattern.FixedTesselation{centerPoint=center,sideColor={0.3,0.15,0.05},faceColor={0.15,0.06,0.03},sideNum=4,angleNum=5,toDrawNum=42}
        local a,b
        local en
        local player=Player{x=400,y=5000}
        local phase2,phase3
        en=Enemy{x=400,y=2000,mainEnemy=true,maxhp=9000,hpSegments={0.6,0.2},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel,{bullet=true,invincible=false})
            SFX:play('enemyCharge',true)
            en:addHPProtection(600,10)
            if hpLevel==1 then
                a.spawnEvent.frame=0
                a.spawnEvent.period=100
                Shape.moveToInTime(en,{x=400,y=4300},240)
                Shape.moveToInTime(a,{x=400,y=4300},240)
                phase2()
            elseif hpLevel==2 then
                a.spawnEvent.frame=0
                a.spawnEvent.period=300
                a.bulletNumber=8
                a.range=math.pi*2
                a.angle={0,999}
                Shape.moveToInTime(en,{x=400,y=6000},240)
                Shape.moveToInTime(a,{x=400,y=6000},240)
                phase3()
            end
        end}
        en:addHPProtection(1200,10)
        player.moveMode=Player.moveModes.Euclid
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,150,12))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object={x=400,y=6000}
        G.viewMode.viewOffset={x=0,y=0}
        local function fixedMove(self)
            if not self.fixed then
                local x,y=self.x,self.y
                self.fixed={Shape.screenPosition(x,y)}
            end
            local x,y=self.fixed[1],self.fixed[2]
            local speed,dir=self.speed,self.direction
            x,y=x+math.cos(dir)*speed,y+math.sin(dir)*speed
            self.fixed={x,y}
            self.x,self.y=x,y
        end
        local function drawSprite(self)
            if not self.fixed then
                local x,y=self.x,self.y
                self.fixed={Shape.screenPosition(x,y)}
            end
            self.x,self.y=self.fixed[1],self.fixed[2]
            local color={love.graphics.getColor()}
            local x,y,radius=self.x,self.y,self.radius
            local data=self.sprite.data
            local scale=radius/data.hitRadius*Circle.spriteSizeFactor
            local r,g,b
            if self.spriteColor then
                r,g,b=self.spriteColor[1],self.spriteColor[2],self.spriteColor[3]
            end
            self.batch:setColor(r or 1,g or 1,b or 1,(self.spriteTransparency or 1)*color[4])
            self.batch:add(self.sprite.quad,x,y,self.direction+math.pi/2+(self.spriteExtraDirection or 0),scale,scale,data.centerX,data.centerY)
        end
        local function checkHitPlayer(self)
            if not self.safe then 
                for key, player in pairs(Player.objects) do
                    local playerScreenX,playerScreenY=Shape.screenPosition(player.x,player.y)
                    local dis=math.distance(playerScreenX,playerScreenY,self.x,self.y)
                    local radi=player.radius+self.radius
                    if dis<radi+player.radius*player.grazeRadiusFactor and not self.grazed then
                        EventManager.post(EventManager.EVENTS.PLAYER_GRAZE,player,(self.lifeFrame<3 or self.frame<3) and 0.05 or 1)
                        self.grazed=true
                    end
                    if player.invincibleTime<=0 and dis<radi then
                        EventManager.post(EventManager.EVENTS.PLAYER_HIT,player,self.damage or 1)
                    end
                end
            end
        end
        local fixedUpdate=function(cir)
            if not cir.init then
                cir.init=true
                cir.forceDrawNormalSprite=true
                cir.updateMove=fixedMove
                cir.drawSprite=drawSprite
                cir.checkHitPlayer=checkHitPlayer
            end
            cir.spriteTransparency=math.clamp(cir.spriteTransparency+0.01,0,1)
            if cir.frame==100 then
                cir.safe=false
            end
        end
        local function fixedBullet(x,y)
            local x0,y0=Shape.inverseScreenPosition(x,y)
            local cir={fogTime=60,x=x0,y=y0,speed=0,direction=0,lifeFrame=6000,sprite=BulletSprites.stone.yellow,radius=5,spriteTransparency=0,safe=true,invincible=true,extraUpdate={
                fixedUpdate
            }}
            local ciro=Circle(cir)
            ciro.removeDistance=1e308
        end
        phase2=function()
            for x=-1,3 do
                x=150+500/3*x
                for y=0,600,10 do
                    fixedBullet(x,y)
                end
            end
            for y=0,3 do
                y=50+550/3*y
                for x=0,800,10 do
                    fixedBullet(x,y)
                end
            end
            local indicator=Circle{x=player.x,y=player.y,sprite=BulletSprites.largeOrb.red,radius=2,spriteTransparency=0,speed=0,direction=0,lifeFrame=9000,safe=true,extraUpdate={ -- where player will be at after switching model
                function(cir)
                    if not cir.init then
                        cir.init=true
                        cir.forceDrawNormalSprite=true
                        cir.updateMove=fixedMove
                        cir.drawSprite=drawSprite
                        cir.checkHitPlayer=checkHitPlayer
                    end
                    cir.spriteTransparency=math.clamp(cir.spriteTransparency+0.02,0,0.3)
                    G.viewMode.hyperbolicModel=(G.viewMode.hyperbolicModel+1)%G.CONSTANTS.HYPERBOLIC_MODELS_COUNT
                    cir.fixed={Shape.screenPosition(player.x,player.y)}
                    G.viewMode.hyperbolicModel=(G.viewMode.hyperbolicModel-1)%G.CONSTANTS.HYPERBOLIC_MODELS_COUNT
                end
            }}

        end
        phase3=function()
            Event.LoopEvent{
                obj=en,period=60,frame=-60,executeFunc=function(self)
                    local x,y=Shape.screenPosition(player.x,player.y)
                    for dx=-10,10,10 do
                        for dy=-10,10,10 do
                            if dx==0 and dy==0 then
                                goto continue
                            end
                            fixedBullet(x+dx,y+dy)
                            ::continue::
                        end
                    end
                    fixedBullet(x,y) -- make center appear above others
                end
            }
        end
        local function packed(cir)
            local hpLevel=en:getHPLevel()
            cir.forceDrawNormalSprite=true
            local num=0
            cir.extraUpdate[#cir.extraUpdate+1]=function(cir)
                if cir.frame%5==4 and cir.frame<(hpLevel==2 and 40 or 20) then
                    num=num+1
                    for i=1,3 do
                        local numRef=num
                        local follower=Circle{x=cir.x,y=cir.y,sprite=cir.sprite,radius=2,speed=cir.speed,highlight=true,safe=cir.safe,direction=cir.direction,lifeFrame=600,spriteTransparency=0.5,extraUpdate={
                            function(cirF)
                                if cir.removed then
                                    cirF:remove()
                                    return
                                end
                                cirF.spriteTransparency=math.clamp(cirF.spriteTransparency+0.05,0,1)
                                cirF.direction=cir.direction
                                local smooth=math.clamp(cirF.frame/5,0,1)
                                cirF.x,cirF.y=Shape.rThetaPos(cir.x,cir.y,10*(numRef+smooth-1),cir.direction+math.pi*2/3*i)
                            end
                        }}
                        follower.forceDrawNormalSprite=true
                    end
                end
            end
        end
        local function bone(x,y,direction)
            -- warning area
            -- local cir=Circle{x=x,y=y,sprite=BulletSprites.bigRound.red,radius=2,speed=50,direction=direction,lifeFrame=600,highlight=true,safe=true}
            -- packed(cir)
            local t=en.frame
            local hpLevel=en:getHPLevel()
            Event.LoopEvent{
                obj=en,period=40,times=4,frame=38,executeFunc=function(self,times)
                    if en:getHPLevel()~=hpLevel then
                        return
                    end
                    local cir=Circle{x=x,y=y,sprite=BulletSprites.lightRound.orange,radius=2,speed=0,direction=direction,lifeFrame=600,highlight=true,extraUpdate={
                        function(cir)
                            cir.speed=math.clamp(cir.speed+0.5,30,60)
                            if times==0 then
                                if hpLevel==1 and cir.frame%20==0 then
                                    SFX:play('enemyShot')
                                    for i=-9,9 do
                                        if i==0 then
                                        goto continue 
                                        end
                                        Circle{x=cir.x,y=cir.y,sprite=BulletSprites.roundDark.orange,radius=2,speed=i*10,direction=cir.direction+math.pi/2,lifeFrame=1200,highlight=true}
                                        ::continue::
                                    end
                                -- elseif hpLevel==1 and cir.frame%5==0 then
                                --     fixedBullet(cir.x,cir.y)
                                end
                            end
                        end
                    }}
                    packed(cir)
                end
            }
        end
        a=BulletSpawner{x=en.x,y=en.y,period=180,frame=100,lifeFrame=10000,bulletNumber=1,bulletSize=2,highlight=true,bulletLifeFrame=600,range=math.pi/2,angle=math.pi/2,bulletSpeed=150,bulletSprite=BulletSprites.lightRound.orange,bulletEvents={
            function(cir)
                local hpLevel=en:getHPLevel()
                if hpLevel==1 then
                    cir.speed=cir.speed+math.eval(0,20)
                    cir.direction=cir.direction+math.eval(0,math.pi/8)+math.pi/2*math.mod2Sign(a.spawnEvent.executedTimes)
                elseif hpLevel==2 then
                    cir.speed=Shape.distanceObj(cir,player)
                    cir.direction=Shape.toObj(cir,player)
                else
                    bone(cir.x,cir.y,cir.direction)
                    cir:remove()
                    return
                end
                cir.invincible=true
                Event.EaseEvent{
                    obj=cir,easeFrame=100,aimTable=cir,aimKey='speed',aimValue=0,progressFunc=function(x)
                        return x*x
                    end,
                }
                Event.DelayEvent{
                    obj=cir,delayFrame=90,executeFunc=function()
                        SFX:play('enemyShoot')
                        bone(cir.x,cir.y,Shape.toObj(cir,player))
                        cir:remove()
                    end
                }
                Event.EaseEvent{
                    obj=cir,easeFrame=120,aimTable=cir,aimKey='radius',aimValue=cir.radius*3
                }
            end
        }
        }
        Asset.batchExtraActions[Asset.bulletBatch].before=function()
            love.graphics.setShader() -- dont use hyprotshader since bullets are drawn in screen coordinates
        end
        Asset.batchExtraActions[Asset.bulletBatch].after=function()
            Asset.setHyperbolicRotateShader()
        end
    end,
    leave=function()
        Asset.batchExtraActions[Asset.bulletBatch].before=nil
        Asset.batchExtraActions[Asset.bulletBatch].after=nil
    end
}