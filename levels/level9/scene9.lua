return {
    ID=112,
    user='utsuho',
    spellName='Giant Star "?"', 
    make=function()
        G.levelRemainingFrame=9000
        Shape.removeDistance=1e100
        local player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300000}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local en
        local nukes={}
        local hpLevel1
        en=Enemy{x=center.x,y=center.y,mainEnemy=true,maxhp=8400,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            SFX:play('enemyPowerfulShot')
            -- Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
            en.enterNewLevelFrame=en.frame
            if hpLevel==1 then
                -- hpLevel1()
            end
        end}
        en:addHPProtection(600,10)
        local p,q=4,5
        local length=BackgroundPattern.calculateSideLength(p,q)
        local function connect(cir)
            cir.connections={}
            for i=1,#nukes do
                local nuke=nukes[i]
                if nuke==cir then
                    goto continue
                end
                if Shape.distance(cir.x,cir.y,nuke.x,nuke.y)<length*1.1 then
                    table.insert(cir.connections,nuke)
                    nuke.connections=nuke.connections or {}
                    table.insert(nuke.connections,cir)
                    -- local cx,cy=Shape.rThetaPos(cir.x,cir.y,length/2,Shape.to(cir.x,cir.y,nuke.x,nuke.y))
                    -- local cir2=Circle{
                    --     x=cx,y=cy,radius=1,
                    --     direction=Shape.to(cir.x,cir.y,nuke.x,nuke.y),
                    --     speed=0,lifeFrame=1000,sprite=BulletSprites.giant.red
                    -- }
                end
                ::continue::
            end
        end
        local fissionComplete=false
        local function growBase(cir)
            nukes[#nukes+1]=cir
            Event.LoopEvent{
                obj=cir,period=1,executeFunc=function()
                    if not fissionComplete then return end
                    local radiusRatio=0.5
                    local level=en:getHPLevel()
                    if level==1 then
                        if cir.small then
                            radiusRatio=0.2
                        else
                            radiusRatio=0.7
                        end
                    elseif level==2 then
                        local t=(en.frame-en.enterNewLevelFrame)
                        local sin=math.sin(t/120)
                        radiusRatio=math.min(0.5,0.2+t/120)*(0.9+0.4*sin*math.mod2Sign(cir.layer))
                        local playerAdditionalRadius=cir.playerAdditionalRadius or 0
                        local distance=Shape.distance(cir.x,cir.y,player.x,player.y)
                        if distance<length then
                            playerAdditionalRadius=math.interpolate(playerAdditionalRadius,0.1,0.005)
                        else
                            playerAdditionalRadius=math.interpolate(playerAdditionalRadius,0,0.01)
                        end
                        cir.playerAdditionalRadius=playerAdditionalRadius
                        radiusRatio=radiusRatio+playerAdditionalRadius*math.abs(sin)
                    end
                    cir.radius=math.interpolate(cir.radius,length*radiusRatio,0.03)
                end
            }
        end
        local origin
        local function start()
            SFX:play('enemyPowerfulShot')
            for i=1,#nukes do
                local nuke=nukes[i]
                connect(nuke)
            end
            local previousSmall=nil
            local small=origin
            origin.small=true
            Event.LoopEvent{
                obj=en,period=150,conditionFunc=function(self)
                    if en:getHPLevel()~=1 then
                        self:remove()
                        return false
                    end
                    return true
                end,
                executeFunc=function()
                    SFX:play('enemyShot',true,2)
                    Event.DelayEvent{
                        obj=en,delayFrame=100,executeFunc=function()
                            previousSmall.small=false
                        end
                    }
                    local connections=small.connections
                    local nextSmall
                    local candidates={}
                    for i=1,#connections do
                        local c=connections[i]
                        if #c.connections>2 and c~=previousSmall then
                            table.insert(candidates,c)
                        end
                    end
                    if #candidates>0 then
                        nextSmall=candidates[math.random(1,#candidates)]
                    else
                        nextSmall=previousSmall
                    end
                    nextSmall.small=true
                    previousSmall=small
                    small=nextSmall
                end
            }
        end
        hpLevel1=function ()
            local count=0
            Event.LoopEvent{
                obj=en,period=300,frame=240,conditionFunc=function(self)
                    if en:getHPLevel()~=2 then
                        self:remove()
                        return false
                    end
                    return true
                end,
                executeFunc=function()
                    for i=1,#nukes do
                        local nuke=nukes[i]
                        nuke.connections={}
                    end
                    for i=1,#nukes do
                        local nuke=nukes[i]
                        connect(nuke)
                    end
                    for i=1,#nukes do
                        local nuke=nukes[i]
                        if nuke.trigger==count then -- in swap process in this loop 
                            goto continue
                        end
                        local connections=nuke.connections
                        local candidates={}
                        for i=1,#connections do
                            local c=connections[i]
                            if c.trigger~=count then
                                table.insert(candidates,c)
                            end
                        end
                        if #candidates>0 then
                            local other=candidates[math.random(1,#candidates)]
                            local otherPosRef={x=other.x,y=other.y}
                            local nukePosRef={x=nuke.x,y=nuke.y}
                            Shape.moveToInTime(nuke,otherPosRef,240)
                            Shape.moveToInTime(other,nukePosRef,240)
                            nuke.trigger=count
                            other.trigger=count
                        end
                        ::continue::
                    end
                    count=count+1
                end
            }
        end
        local function fissionBase(cir,times)
            growBase(cir)
            times=times or 0
            cir.layer=times+1
            local num=q
            Event.DelayEvent{
                obj=cir,delayFrame=length/cir.speed*60,executeFunc=function()
                    SFX:play('enemyShot',true,2)
                    local speedRef=cir.speed
                    cir.speed=0
                    if times>=2 then
                        if not fissionComplete then
                            fissionComplete=true
                            start()
                        end
                        return
                    end
                    for i=1,num-2 do
                        local direction=cir.direction+math.pi+math.pi*2/num*i
                        local nx,ny=Shape.rThetaPos(cir.x,cir.y,length,direction)
                        if Shape.distance(center.x,center.y,nx,ny)<Shape.distance(center.x,center.y,cir.x,cir.y) then
                            goto continue
                        end
                        local subcir=Circle{
                            x=cir.x,y=cir.y,radius=0.07,
                            direction=direction,speed=speedRef,
                            lifeFrame=cir.lifeFrame-cir.frame,
                            sprite=cir.sprite
                        }
                        subcir.radius=cir.radius
                        -- Event.EaseEvent{
                        --     obj=subcir,aimKey='radius',aimValue=cir.radius*0.8,easeFrame=100
                        -- }
                        fissionBase(subcir,times+1)
                        ::continue::
                    end
                    -- cir:remove()
                end
            }
        end
        local a
        a=BulletSpawner{x=en.x,y=en.y,period=1600,frame=1540,lifeFrame=1700,bulletNumber=q,bulletSize=0.07,bulletSpeed=80,bulletLifeFrame=15000,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.nuke,spawnSFXVolume=2,bulletEvents={
            function(cir,args,self)
                if args.index==1 then
                    origin=Circle{
                        x=cir.x,y=cir.y,radius=0.07,
                        direction=cir.direction,speed=0,
                        lifeFrame=cir.lifeFrame-cir.frame,
                        sprite=cir.sprite
                    }
                    origin.layer=0
                    Event.EaseEvent{
                        obj=origin,easeFrame=10,aimKey='radius',aimValue=length*0.15
                    }
                    growBase(origin)
                end
                cir.bulletNumberRef=a.bulletNumber
                -- cir.safe=true
                Event.EaseEvent{
                    obj=cir,easeFrame=10,aimKey='radius',aimValue=length*0.15
                }
                fissionBase(cir)
            end
        }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
            end
        }
        
    end
}