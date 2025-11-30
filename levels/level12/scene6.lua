return {
    ID=107,
    user='kotoba',
    spellName='Honeymoon "Sticky Satellites',
    make=function()
        G.levelRemainingFrame=10800
        Shape.removeDistance=1e100
        local center={x=400,y=300000}
        local a,b,player
        local en
        local hplevel=1
        local moonZoomUpdate
        en=Enemy{x=center.x,y=center.y,mainEnemy=true,maxhp=9600,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            -- Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
            hplevel=hplevel+1
        end}
        -- en.showHexagram=false
        en:addHPProtection(600,10)
        player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local stickyR,stickySprite=0.718,'explosion'
        local function stickyCheckHitPlayer(self)
            if self.stickHit then
                return
            end
            local dis=Shape.distance(player.x,player.y,self.x,self.y)
            local radi=player.radius+self.radius
            if dis<radi then
                SFX:play('sticky',true,3)
                player.stickyLayer=(player.stickyLayer or 0)+1
                self.stickHit=true
            end
        end
        local function stickyUpdate(self)
            if self.stickHit or self.frame+60>self.lifeFrame then
                self.spriteTransparency=math.max(0,self.spriteTransparency-0.03)
                if self.spriteTransparency==0 then
                    self:remove()
                end
            end
        end
        local function summonStickies(cir)
            local r=cir.radius
            local dir=cir.direction
            local circumference=2*math.pi*math.sinh(r/Shape.curvature)*Shape.curvature
            local n=math.ceil(circumference/9)
            -- cir.count=cir.count or 0
            for i=1,1 do
                -- cir.count=cir.count+math.mod2Sign(cir.index)
                -- if i==1 then
                --     i=cir.count%n
                -- else
                --     i=n-cir.count%n
                -- end
                -- if cir.count%11~=0 then
                --     goto continue
                -- end
                local ratio=0--(i-0.5-n/2)/n*2 -- -1 to 1
                local angle=math.asin(ratio)+dir-math.pi/2*cir.rotateSign -- uniform distribution along direction perpendicular to cir direction
                local x,y=Shape.rThetaPos(cir.x,cir.y,r,angle)
                local sticky={x=x,y=y,direction=0,speed=0,radius=stickyR,sprite=BulletSprites[stickySprite].yellow,highlight=true,lifeFrame=300,extraUpdate={stickyUpdate,stickyCheckHitPlayer},spriteTransparency=0.4,safe=true,fogTime=5,spriteColor={1,1,0.6}}
                BulletSpawner.wrapFogEffect(sticky)
                ::continue::
            end
        end
        moonZoomUpdate = function (self)
            if self.frame<self.t1 then
                self.radius=self.radius+self.dr
                self.speed=self.speed+self.dv
                -- self.speed=self.speed+0.5
            end
            if self.frame%30==0 and self.summon~=false then
                summonStickies(self)
            end
            if self.frame+60>=self.lifeFrame then
                self.radius=self.radius-1
            end
        end
        a=BulletSpawner{x=en.x,y=en.y,period=360,frame=0,lifeFrame=399,angle='player',bulletSprite=BulletSprites.moon,bulletSpeed=0.1,bulletLifeFrame=19900,bulletNumber=1,bulletRadius=0.01,bulletExtraUpdate={moonZoomUpdate},bulletEvents={
            function(cir,args)
                cir.t1,cir.dr=240,0.25
                cir.dv=0.375
                cir.spriteColor={1,0.6,0.42}
                cir.summon=false
                cir.invincible=true
                cir.index=args.index+1
                cir.spriteRotationSpeed=-0.01*(cir.index-2)
                Event.LoopEvent{period=240,frame=60*cir.index-60,executeFunc=function()
                    SFX:play('enemyPowerfulShot')
                    Event.EaseEvent{
                        obj=cir,aimKey='speed',aimValue=0,easeFrame=60,progressFunc=Event.sineBackProgressFunc
                    }
                    Event.DelayEvent{period=30,frame=0,executeFunc=function()
                        local newDir=Shape.toObj(cir,player)+0.03*(cir.index-2)
                        cir.spriteExtraDirection=cir.spriteExtraDirection-newDir+cir.direction -- keep sprite direction unchanged
                        cir.direction=newDir
                        -- cir.summon=false
                    end}
                end}
            end,
        }}
        local tesseAngle=math.eval(0,999)
        local sideNum,angleNum=7,3
        local adjacentPoints,angles,sidesTable=BackgroundPattern.tesselation(center,tesseAngle,sideNum,angleNum,0,{x=en.x,y=en.y},210,nil,true)
        local function ring(x0,y0,i)
            local r=110
            local circumference=2*math.pi*math.sinh(r/Shape.curvature)*Shape.curvature
            local n=3--math.ceil(circumference/300)
            local angleStep=2*math.pi/n
            local angle0=math.eval(0,999)
            for j=1,n do
                local angle=angle0+j*angleStep
                local x,y=Shape.rThetaPos(x0,y0,r,angle)
                Circle{x=x,y=y,lifeFrame=19999,sprite=BulletSprites.moon,speed=0,radius=0.01,extraUpdate={moonZoomUpdate,
                    function (self)
                        self.x,self.y,self.direction=Shape.rThetaPosT(x0,y0,r-0*math.sin(self.frame/200),self.angle)
                        local speed=1
                        if hplevel==2 then
                            self.summon=true
                            speed=2-en:getHPPercentOfCurrentLevel()
                        end
                        self.angle=self.angle+speed/circumference*3*self.rotateSign
                        if self.frame>60 then
                            self.safe=false
                        end
                    end
                },events={
                    function(cir,args)
                        cir.rotateSign=math.mod2Sign(i)
                        cir.t1=240
                        cir.dr=0.25
                        cir.dv=0
                        cir.spriteColor={1,1,0.7}
                        cir.summon=false
                        cir.invincible=true
                        cir.index=args.index
                        cir.angle=angle
                        cir.safe=true
                    end,
                }}
            end
            Circle{x=x0,y=y0,lifeFrame=19999,sprite=BulletSprites.moon,speed=0,radius=0.01,extraUpdate={moonZoomUpdate,},events={
                function(cir,args)
                    cir.t1=240
                    cir.dr=0.25
                    cir.dv=0
                    cir.spriteColor={1,1,0.7}
                    cir.summon=false
                    cir.invincible=true
                    cir.index=args.index
                end,
            }}
        end
        local function number(x,y,i)
            local ten=math.floor(i/10)
            local one=i%10
            local dir=0
            for j=1,one do
                local xj,yj=Shape.rThetaPos(x,y,5*j,dir)
                Circle{x=xj,y=yj,lifeFrame=30000,sprite=BulletSprites.round.white,speed=0,radius=1}
            end
            x,y,dir=Shape.rThetaPosT(x,y,15,dir+math.pi/2)
            dir=dir-math.pi/2
            for j=1,ten do
                local xj,yj=Shape.rThetaPos(x,y,5*j,dir)
                Circle{x=xj,y=yj,lifeFrame=30000,sprite=BulletSprites.bigRound.white,speed=0,radius=1}
            end
        end
        local nums={[1]=true,[17]=true,[31]=true,[39]=true,[41]=true,[43]=true,[45]=true,[54]=true,[56]=true,[58]=true,[96]=true,[62]=true,[80]=true}
        local centers={}
        local centerHashes={}
        Event.DelayEvent{
            obj=en,delayFrame=10,executeFunc=function()
                SFX:play('enemyShot',true,2)
                for i,sideTable in ipairs(sidesTable) do
                    local p1,p2=sideTable[1],sideTable[2]
                    local x,y=BackgroundPattern.getCenterOfPolygonWithSide(p1.x,p1.y,p2.x,p2.y,sideNum,angleNum)
                    local distanceToCenter=Shape.distanceObj(center,{x=x,y=y})
                    local angleToCenter=Shape.toObj(center,{x=x,y=y})
                    local centerKey=math.ceil(distanceToCenter)*1000+math.floor(angleToCenter*1000)
                    if not centerHashes[centerKey] then
                        centerHashes[centerKey]=true
                        centers[#centers+1]={x=x,y=y}
                    end
                    if i>#sidesTable*0.7 then
                        goto continue
                    end
                    -- local segments=Shape.segmentPoints(p1.x,p1.y,p2.x,p2.y,1,10)
                    local d=Shape.distanceObj(p1,p2)
                    local segments=Shape.segmentPoints(p1.x,p1.y,p2.x,p2.y,1,5)
                    for j=1,#segments-1 do
                        local posRef=segments[j]
                        local x,y=posRef.x,posRef.y
                        local sticky={x=x,y=y,direction=0,speed=0,radius=stickyR,sprite=BulletSprites[stickySprite].yellow,highlight=true,lifeFrame=12000,extraUpdate={stickyUpdate,stickyCheckHitPlayer},spriteTransparency=0.4,safe=true,fogTime=sideTable.index,spriteColor={1,1,0.6}}
                        BulletSpawner.wrapFogEffect(sticky)
                    end
                    ::continue::
                end
                for i,cen in ipairs(centers) do
                    if nums[i] then
                        ring(cen.x,cen.y,i)
                    end
                    -- number(cen.x,cen.y,i)
                end
            end
        }
        local moveSpeedRef=player.moveSpeed
        Event.LoopEvent{period=1,frame=0,executeFunc=function()
            player.stickyLayer=(player.stickyLayer or 0)
            local ratio=0.9^player.stickyLayer
            player.moveSpeed=moveSpeedRef*ratio
            player.stickyLayer=math.max(0,player.stickyLayer-0.01)
            love.graphics.setColor(1,1,ratio)
            ratio=ratio^2
            G.backgroundPattern.lightColor[3]=ratio -- reduce blue component to give yellowish tint
            G.backgroundPattern.darkColor[3]=0.5*ratio
        end}
        -- Event.LoopEvent{
        --     obj=en,period=180,frame=0,executeFunc=function(self,times)
        --         local playerPosRef={x=player.x,y=player.y}
        --         Event.LoopEvent{
        --             obj=en,period=1,times=120,executeFunc=function(self,times,maxTimes)
        --                 Shape.moveTowards(en,playerPosRef,0.01,false,true)
        --                 a.x,a.y=en.x,en.y
        --             end
        --         }
        --     end
        -- }
    end,
    leave=function()
        love.graphics.setColor(1,1,1)
    end
}