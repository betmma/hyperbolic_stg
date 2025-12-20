return {
    ID=100,
    user='kotoba',
    spellName='Fangame',
    dialogue='bossDialogue12_9',
    make=function()
        G.levelRemainingFrame=10800
        Shape.removeDistance=1e100
        local center={x=400,y=300000}
        local a,b,player
        local en
        local hplevel=1
        en=Enemy{x=center.x,y=center.y,mainEnemy=true,maxhp=9600}
        en:addHPProtection(600,10)
        player=Player{x=400,y=900000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local function fanComponentUpdate(self)
            local core=self.core
            self.x,self.y,self.direction=Shape.rThetaPosT(core.x,core.y,core.r*self.rRatio,core.span*self.angleRatio+core.direction)
            if core.removed then
                self:remove()
            end
        end
        local MODES={IDLE=0,AROUND_ENEMY=1,AROUND_PLAYER=2,POINT=3}
        local function fanCoreUpdate(self)
            local mode=self.mode or MODES.IDLE
            local modeFrame=self.frame - self.enterFrame
            self.rotateDir=self.rotateDir + self.rotateSpeed
            if mode==MODES.IDLE then
                -- do nothing
            elseif mode==MODES.AROUND_ENEMY then
                local moveRatio=math.min(1,modeFrame/60+0.1)
                local aimx,aimy,dir=Shape.rThetaPosT(en.x,en.y,self.enemyRadius,self.rotateDir)
                Shape.moveTowards(self,{x=aimx,y=aimy},moveRatio,true,true)
                self.direction=dir
            elseif mode==MODES.AROUND_PLAYER then
                local moveRatio=math.min(1,modeFrame/60+0.1)
                local aimx,aimy,dir=Shape.rThetaPosT(player.x,player.y,self.playerRadius,self.rotateDir)
                Shape.moveTowards(self,{x=aimx,y=aimy},moveRatio,true,true)
                self.direction=dir
            elseif mode==MODES.POINT then
                local point={x=self.px,y=self.py}
                local dir=math.modClamp(self.pdir,self.direction)
                local moveRatio=self.pointMoveRatio or 0.1
                Shape.moveTowards(self,point,moveRatio,true,true)
                self.direction=math.interpolate(self.direction,dir,moveRatio)
            end
        end
        local function switchMode(core,to)
            core.mode=to
            core.enterFrame=core.frame
        end
        local function fan(args)
            local color=args.color or 'red'
            local core=Circle{x=args.x,y=args.y,sprite=BulletSprites.round[color],safe=true,spriteTransparency=0,direction=args.direction,speed=0,lifeFrame=args.lifeFrame or 99999,invincible=true}
            core.r=args.r or 100
            core.span=args.span or math.pi/4
            core.mode=MODES.AROUND_ENEMY
            core.enterFrame=0
            core.rotateDir=0
            core.rotateSpeed=0.01
            core.enemyRadius=10
            core.playerRadius=10
            core.switchMode=switchMode
            core.extraUpdate={fanCoreUpdate}
            local lengthGap=args.gap or 5
            local rnum=math.ceil(core.r/lengthGap)
            local rRatioGap=1/rnum
            local arcLength=math.sinh(core.r/Shape.curvature)*Shape.curvature*core.span
            local angleNum=math.ceil(arcLength/lengthGap)
            local angleRatioGap=1/angleNum
            for angleRatio=-0.5,0.5,angleRatioGap do
                local previous
                for rRatio=rRatioGap,1,rRatioGap do
                    local part=Laser.LaserUnit{x=core.x,y=core.y,direction=core.direction,sprite=BulletSprites.laser[color],safe=true,invincible=true,radius=math.max(rRatio,0.1)*lengthGap*0.4,extraUpdate=fanComponentUpdate,lifeFrame=core.lifeFrame}
                    part.core=core
                    part.rRatio=rRatio
                    part.angleRatio=0
                    Event.EaseEvent{
                        obj=part,aimKey='angleRatio',aimValue=angleRatio,easeFrame=30,progressFunc=Event.sineOProgressFunc
                    }
                    if previous then
                        previous.next=part
                        part.previous=previous
                    end
                    previous=part
                end
            end
            return core
        end
        local function bulletEvent(self,args,spawner)
            local index=spawner.spawnEvent.executedTimes%5
            Event.DelayEvent{
                delayFrame=30+index*5,executeFunc=function()
                    Event.EaseEvent{
                        obj=self,aimKey='speed',aimValue=60,easeFrame=120,
                    }
                end
            }
        end
        local function laserPrep(c)
            local r,theta=math.eval(150,80),math.eval(0,999)
            local aimx,aimy=Shape.rThetaPos(player.x,player.y,r,theta)
            c.px=aimx
            c.py=aimy
            c.pdir=Shape.to(aimx,aimy,player.x,player.y)+math.eval(0,0.03)
        end
        local prepFrame=100
        local activeFrame=40
        local function laserUpdate(self)
            local t=self.frame
            if t<=prepFrame then
                local ratio=t/prepFrame
                self.spriteTransparency=0.5
                self.spriteColor=self.colorValue
                self.radius=1+2*(1-(1-ratio)^2)
            elseif t<=prepFrame+activeFrame then
                local ratio=(t-prepFrame)/activeFrame
                self.safe=false
                self.spriteTransparency=1
                self.spriteColor={0.8,0.8,0.8}
                self.radius=3*(1-(1-ratio)^2)
                if t==prepFrame+math.floor(activeFrame/2) and self.next then
                    local midPoints=Shape.segmentPoints(self.x,self.y,self.next.x,self.next.y,5,10)
                    for _,pt in ipairs(midPoints) do
                        local r=Shape.distanceObj(pt,self)
                        local orb=Circle{x=pt.x,y=pt.y,sprite=BulletSprites.lightRound[self.sprite.data.color],radius=2,speed=0,direction=0,lifeFrame=activeFrame/2+prepFrame,highlight=true,spriteTransparency=0,safe=true,extraUpdate={fanComponentUpdate,function(self)
                            self.spriteTransparency=math.min(1,self.frame/(prepFrame/2))
                            if self.spriteTransparency==1 then
                                self.safe=false
                            end
                            if self.frame>math.floor(activeFrame/2) then
                                self.radius=self.radiusRef*(1-(self.frame - math.floor(activeFrame/2))/ (activeFrame/2+prepFrame))
                            end
                        end}}
                        orb.radiusRef=orb.radius
                        orb.core,orb.rRatio,orb.angleRatio=self.core, r/self.core.r,self.angleRatio
                    end
                end
            elseif t<=prepFrame*2+activeFrame then
                local ratio=(t-prepFrame-activeFrame)/prepFrame
                self.spriteTransparency=math.interpolate(self.spriteTransparency,0.5,0.1)
                self.safe=true
                self.spriteColor=math.interpolateTable(self.spriteColor,{0.5,0.5,0.5},ratio)
                self.radius=3*(1-ratio^2)
            end
        end
        local colors={'red','blue','green','yellow'}
        local colorValues={
            red={1,0,0},
            blue={0,0,1},
            green={0,1,0},
            yellow={1,1,0},
        }
        --[[
            pattern:
            8 around enemy (spawning)
            8 around player (blocking view)
            8 around enemy
            4 around player (A), 4 still around enemy (B)
            half of A and B move away and fire lasers (C). enemy moves and shoots
            C around player, rest move away and shoot lasers
            all around player
            one by one move away and shoot lasers
            one by one return to around enemy
            loop
        ]]
        local angle0=math.eval(0,999)
        for i=1,8 do
            local color=colors[(i-1)%#colors+1]
            local colorValue=colorValues[color]
            local core=fan{x=en.x,y=en.y,direction=math.pi/4*i+angle0,r=50,span=math.pi/3,gap=15,color=color,lifeFrame=99999}
            core.rotateDir=core.direction
            core.color=color
            core.extraUpdate[2]=function(c)
                c.rotateSpeed=0.04*math.sin(c.frame/120+i%2*math.pi)*(1.5-0.5*math.cos(c.frame/1800))
                c.enemyRadius=20+30*math.sin(c.frame/60+i*math.pi)
                c.playerRadius=-5+5*math.sin(c.frame/30+i*math.pi)
                local period=240
                local t=c.frame%(period*8)
                if t==period then
                    c:switchMode(MODES.AROUND_PLAYER)
                elseif t==period*2 then
                    c:switchMode(MODES.AROUND_ENEMY)
                elseif t==period*3 and i%2==0 then
                    c:switchMode(MODES.AROUND_PLAYER)
                elseif t==period*3 and i%2==1 then
                    c:switchMode(MODES.AROUND_ENEMY) -- reset enterFrame
                elseif t==period*4 and i%4<2 then
                    laserPrep(c)
                    c:switchMode(MODES.POINT)
                elseif t==period*4 and i%4>=2 and i%2==1 then
                    c:switchMode(MODES.AROUND_ENEMY) -- reset enterFrame
                elseif t==period*5 and i%4<2 then
                    c:switchMode(MODES.AROUND_PLAYER)
                elseif t==period*5 and i%4>=2 then
                    laserPrep(c)
                    c:switchMode(MODES.POINT)
                elseif t==period*6 then
                    c:switchMode(MODES.AROUND_PLAYER)
                elseif t==period*6+(period/8)*(i-1)+1 then
                    laserPrep(c)
                    c:switchMode(MODES.POINT)
                elseif t==period*7+(period/8)*(i-1)+1 then
                    c:switchMode(MODES.AROUND_ENEMY)
                end
                local modeFrame=c.frame-c.enterFrame
                if c.mode==MODES.AROUND_ENEMY and modeFrame==20 then
                    local spawner=BulletSpawner{x=c.x,y=c.y,period=2,frame=0,lifeFrame=200,bulletNumber=1,bulletSize=2,bulletSpeed=0,angle=0,range=math.pi*0,bulletSprite=BulletSprites.ellipse[color],highlight=true,fogEffect=true,fogTime=10,bulletLifeFrame=400,bulletEvents={bulletEvent
                    }}
                    spawner.core=c
                    spawner.rRatio=1
                    spawner.angleRatio=0
                    Event.LoopEvent{
                        obj=spawner,period=1,executeFunc=function(self)
                            fanComponentUpdate(spawner)
                            spawner.angle=spawner.direction+c.rotateSpeed*30
                        end,
                    }
                end
                if c.mode==MODES.POINT then
                    local startFrame=5
                    local orbFrame=startFrame+prepFrame+activeFrame+20
                    if modeFrame==startFrame then
                        SFX:play('enemyCharge',true)
                        c.pointMoveRatio=0.1
                        for angleRatio=-0.5,0.5,0.25 do
                            local cSideLaserUnit=Laser.LaserUnit{x=c.x,y=c.y,direction=c.direction,sprite=BulletSprites.laserDark[color],safe=true,radius=1,speed=0,lifeFrame=240,extraUpdate={fanComponentUpdate, laserUpdate}}
                            cSideLaserUnit.core=c
                            cSideLaserUnit.rRatio=1
                            cSideLaserUnit.angleRatio=angleRatio
                            cSideLaserUnit.colorValue=colorValue
                            local farSideLaserUnit=Laser.LaserUnit{x=c.x,y=c.y,direction=c.direction,sprite=BulletSprites.laserDark[color],safe=true,radius=1,speed=0,lifeFrame=240,extraUpdate={fanComponentUpdate, laserUpdate}}
                            farSideLaserUnit.core=c
                            farSideLaserUnit.rRatio=10
                            farSideLaserUnit.angleRatio=angleRatio
                            farSideLaserUnit.colorValue=colorValue
                            cSideLaserUnit.next=farSideLaserUnit
                            farSideLaserUnit.previous=cSideLaserUnit
                        end
                    elseif modeFrame==startFrame+prepFrame then
                        SFX:play('enemyPowerfulShot',true)
                    elseif modeFrame==orbFrame then
                        c.pointMoveRatio=0.001
                        c.px,c.py=Shape.rThetaPos(c.px,c.py,math.eval(60,20),math.eval(0,999))
                        c.pdir=c.direction+math.eval(0.4,0.2)*math.randomSign()
                    elseif modeFrame>orbFrame and modeFrame<orbFrame+60 then
                        c.pointMoveRatio=0.01*math.min(1,(modeFrame-orbFrame)/60)
                    end
                end
            end
        end
        Event.LoopEvent{
            obj=en,period=60,executeFunc=function(self)
                if Shape.distanceObj(player,en)>200 then
                    Event.LoopEvent{
                        obj=en,period=1,times=60,executeFunc=function(self)
                            Shape.moveTowards(en,player,1,true)
                        end,
                    }
                end
                if Shape.distanceObj(player,en)<50 then
                    SFX:play('enemyPowerfulShot',true)
                    local spawner=BulletSpawner{x=en.x,y=en.y,period=10,frame=0,lifeFrame=60,bulletNumber=10,bulletSize=1,bulletSpeed=40,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.giant.red,highlight=true,fogEffect=true,fogTime=10,bulletLifeFrame=100}
                end
            end
        }
    end,
}