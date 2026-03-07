return {
    ID=99,
    user='kotoba',
    spellName='Headhunting "Bloody Collection"',
    unlock=function()
        return Nickname.hasPassAllScenesNicknameForAct(12)
    end,
    make=function()
        G.levelRemainingFrame=10800
        Shape.removeDistance=1e100
        local center={x=400,y=300000}
        local a,b,player
        local en
        local event
        en=Enemy{x=center.x,y=center.y,mainEnemy=true,maxhp=9600,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
            event.frame=event.period-120
        end}
        en:addHPProtection(600,10)
        player=Player{x=400,y=900000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        Event.LoopEvent{
            obj=en,period=60,executeFunc=function(self)
            end
        }
        -- attack 1: human bullets around player, after some time enemy shoots arrows with warning line (uhh not implemented) that kill humans (release red bullets), and spawn small rounds (heads). player needs to get out in time. attack 2: similar but human bullets form straight lines, player needs to get to the other side.
        -- heads will be collected by enemy and orbit around it, and shoot towards player after grazing to threaten player. possible strategy: keep enemy and human bullets perpendicular to player, so that human bullets' aiming explosions form a safe stripe area that is perpendicular to released heads. use up enemy's heads before new round of human bullets starts, to make it safer to escape. 

        local shootingHeads=false
        local headStates={PENDING=1,CIRCLING=2,RELEASED=3}
        local headsCircling={}
        local lastFrameGrazing=0
        local function updateGrazing()
            lastFrameGrazing=en.frame
        end
        EventManager.listenTo(EventManager.EVENTS.PLAYER_GRAZE,updateGrazing,EventManager.EVENTS.LEAVE_LEVEL)
        Event.LoopEvent{
            obj=en,period=1,executeFunc=function()
                local newHeadsCircling={}
                for k,head in pairs(headsCircling) do
                    if not head.removed and head.state==headStates.CIRCLING then
                        newHeadsCircling[#newHeadsCircling+1]=head
                        head.circleIndex=#newHeadsCircling
                    end
                end
                headsCircling=newHeadsCircling
                shootingHeads=en.frame-lastFrameGrazing<10 -- shoot when grazing. grazing means player is close to bullets and possibly in danger, so it's a good time to shoot the heads.
            end
        }
        local function headUpdate(head)
            if head.frame<30 then -- slowing down
                head.speed=head.speed*0.9
                head.state=headStates.PENDING
            elseif head.state==headStates.PENDING then -- move towards enemy to be collected
                local distance=Shape.distanceObj(head,en)
                if distance<10 then
                    head.speed=0
                    head.state=headStates.CIRCLING
                    headsCircling[#headsCircling+1]=head
                    head.circleIndex=#headsCircling
                    head.circleAngle=Shape.toObj(en,head)
                    head.circleRadius=distance
                    head.lifeFrame=9999
                    return
                end
                head.direction=Shape.toObj(head,en)
                head.speed=head.speed+2
            elseif head.state==headStates.CIRCLING then -- circling around enemy
                local r=30+math.sin(en.frame/10)*5
                local angleBase=en.frame/120*math.pi
                local angle=angleBase+head.circleIndex*math.pi*2/#headsCircling
                head.circleAngle=head.circleAngle*0.8+math.modClamp(angle,head.circleAngle)*0.2
                head.circleRadius=head.circleRadius*0.9+r*0.1
                head.x,head.y=Shape.rThetaPosT(en.x,en.y,head.circleRadius,head.circleAngle)
                if shootingHeads and en.frame%1==0 and head==headsCircling[#headsCircling] then
                    SFX:play('enemyShot',true,0.5)
                    head.state=headStates.RELEASED
                    head.speed=180
                    head.direction=Shape.toObj(head,player)+math.eval(0,0.03)
                end
            elseif head.state==headStates.RELEASED then
                head.lifeFrame=head.frame+300
                head.speed=head.speed*0.95+120*0.05
            end
        end
        local function humanUpdate(cir)
            local center=cir.center
            local r=cir.radiusFunc(cir.frame)
            if cir.frame<30 then
                r=r*(2-cir.frame/30)
            end
            cir.x,cir.y,cir.direction=Shape.rThetaPosT(center.x,center.y,r,cir.angle)
            cir.angle=cir.angle+cir.rotateSpeed
            if cir.frame==cir.lifeFrame-120 then -- spawn arrow that will kill cir
                local diex,diey=Shape.rThetaPosT(center.x,center.y,cir.radiusFunc(cir.lifeFrame),cir.angle+cir.rotateSpeed*120)
                local spawnx,spawny=en.x,en.y
                if en.movingStart then
                    local movingDir=Shape.toObj(en,en.aim)
                    spawnx,spawny=Shape.rThetaPos(en.x,en.y,-30+(en.frame-en.movingStart),movingDir)
                end
                local angle=Shape.to(spawnx,spawny,diex,diey)
                local distance=Shape.distance(spawnx,spawny,diex,diey)
                local arrow={x=spawnx,y=spawny,direction=angle,speed=distance*60/60,sprite=BulletSprites.arrow.yellow,lifeFrame=180,fogTime=60,events={
                    function(arrow)
                        SFX:play('enemyShot',true,0.5)
                        cir.arrow=arrow
                    end}}
                BulletSpawner.wrapFogEffect(arrow)
            elseif cir.frame==cir.lifeFrame and not cir.arrow.removed then -- the moment arrow hits
                BulletSpawner{x=cir.x,y=cir.y,period=1,lifeFrame=2,times=1,range=math.pi*math.eval(0.5,0.3),angle='player',bulletNumber=7,bulletSpeed=math.eval(120,40),bulletSprite=BulletSprites.rainDark.red,bulletLifeFrame=400,bulletExtraUpdate=function(cir)
                    cir.speed=cir.speed*0.98+30*0.02
                end}
                Circle{x=cir.x,y=cir.y,direction=cir.arrow.direction,speed=cir.arrow.speed,sprite=BulletSprites.round.red,lifeFrame=600,extraUpdate=headUpdate}
            end
        end
        local function humanBase(cir,center,radiusFunc,rotateSpeed,angle)
            cir.center=center
            cir.radiusFunc=radiusFunc
            cir.rotateSpeed=rotateSpeed
            cir.angle=angle
            cir.targetSize=cir.radius
            cir.fadeFrame=10
            cir.extraUpdate={Circle.FadeIn,Circle.ZoomIn,humanUpdate}
        end
        local attackCount=0
        local function circleHuman()
            local angle=math.eval(0,999)
            BulletSpawner{x=player.x,y=player.y,period=10,lifeFrame=40,frame=9,times=3,range=math.pi*2,angle='0+999',bulletNumber=24,bulletSpeed=0,bulletSprite=BulletSprites.human.red,bulletLifeFrame=360,bulletEvents={
                function(cir,args,self)
                    cir.lifeFrame=cir.lifeFrame+math.floor(math.eval(0,10)) -- let them die in different frames to make it look more natural
                    local ringID=self.spawnEvent.executedTimes
                    local ringRadius=ringID*20+30
                    humanBase(cir,{x=self.x,y=self.y},function(frame)
                        if attackCount>2 then
                            return ringRadius+math.sin(frame/20)*5
                        else
                            return ringRadius
                        end
                    end,math.pi/ringRadius/10*math.mod2Sign(ringID),angle*ringID+math.pi*2*args.index/self.bulletNumber)
                    if args.index==self.bulletNumber then
                        self.bulletNumber=self.bulletNumber+18
                    end
                    if args.index%2==0 then
                        cir:changeSpriteColor('blue')
                        cir.invincible=true
                    end
                end
            }}
        end
        local function lineHuman()
            local angle=math.eval(0,999)
            local distance=Shape.distanceObj(en,player)
            local angleToPlayer=Shape.toObj(en,player)
            local mx,my,mdir=Shape.rThetaPosT(en.x,en.y,distance-50,angleToPlayer)
            local angle0=Shape.to(mx,my,player.x,player.y)
            local nx,ny,ndir
            local offsets={30,0,-30}
            BulletSpawner{x=mx,y=my,period=5,lifeFrame=50,frame=4,times=6,range=math.pi*2,angle='0+999',bulletNumber=24,bulletSpeed=0,bulletSprite=BulletSprites.human.red,bulletLifeFrame=360,bulletEvents={
                function(cir,args,self)
                    local ringID=self.spawnEvent.executedTimes+1
                    local ringID2=math.min(ringID,7-ringID)
                    if args.index==1 then
                        nx,ny,ndir=Shape.rThetaPosT(mx,my,offsets[ringID2],angle0)
                    end
                    cir.lifeFrame=cir.lifeFrame+math.floor(math.eval(0,10)) -- let them die in different frames to make it look more natural
                    humanBase(cir,{x=nx,y=ny},function(frame)
                        return frame/8+(args.index-self.bulletNumber/2)*15
                    end,0,ndir+math.pi/12*(ringID-3.5)-math.pi/2*math.mod2Sign(ringID))
                    if args.index%2==0 then
                        cir:changeSpriteColor('blue')
                        cir.invincible=true
                    end
                end
            }}
        end
        event=Event.LoopEvent{
            obj=en,period=620,frame=560,executeFunc=function(self)
                attackCount=attackCount+1
                if en:getHPLevel()==1 then
                    circleHuman()
                else
                    lineHuman()
                end
                Event.DelayEvent{
                    obj=en,delayFrame=210,executeFunc=function() -- enemy moving. arrows spawning should be in this period
                        local ax,ay=Shape.rThetaPos(en.x,en.y,80,Shape.toObj(en,center)+math.eval(0,1))
                        en.movingStart=en.frame
                        en.aim={x=ax,y=ay}
                        Shape.moveToInTime(en,{x=ax,y=ay},60)
                    end
                }
            end
        }
    end,
}