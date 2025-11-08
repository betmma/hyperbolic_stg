return {
    ID=89,
    user='nareko',
    spellName='Path Sign "Escher\'s Walkway"',
    make=function()
        G.levelRemainingFrame=3600
        G.levelIsTimeoutSpellcard=true
        G.backgroundPattern:remove()
        G.backgroundPattern=BackgroundPattern.Empty()
        Shape.removeDistance=100000
        local en,a
        en=Enemy{x=400,y=30000,mainEnemy=true,maxhp=72000000}
        local player=Player{x=400,y=800,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local w,h=500,600
        local cx,axisY=400,Shape.axisY
        local poses={{cx-w,h+axisY},{cx,h+axisY},{cx+w,h+axisY},{cx+w,2*h+axisY},{cx-w,2*h+axisY}}
        local r02=(w*w+4*h*h)
        local border=PolyLine(poses,false)
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        -- G.viewMode.viewOffset.y=-200
        -- record LR sequences below current position, to know which side will you get if you leave from bottom. For example, if you go upper right, then upper left, it should track so that when you go bottom twice, you will appear from left, then right.
        local branch=0
        local UPPERLEFT,UPPERRIGHT,RIGHT,BOTTOM,LEFT=1,2,3,4,5
        local function drawWrapper(obj,isBullet)
            local drawRef=obj.draw
            obj.draw=function(self)
                local x,y=self.x,self.y
                -- local r2=(x-cx)*(x-cx)+(y-axisY)*(y-axisY)
                -- local a=math.clamp(10-r2/r02*10,0,1)
                -- -- attempt to add fade in/out to make "crossing up/down boundary discrepancy" but doesn't satisfying enough. need to track bullet's branch, and if fade in/out still hits player, then sudden kill remains; if during fade set safe=true, then on border is safe spot. so comment it out. for two subpentagons above current area, when going up, (after teleported to bottom) the other side needs fade in. when going down, the branch%2 0: right, 1: left side needs fade out. num%2==0 is left side, 1 is right side
                -- local goingUp=self.direction%(math.pi*2)>math.pi
                -- local upperRight=self.lastTeleport==UPPERRIGHT and 1 or 0
                for layer=-3,2 do
                    local negExp,exp=2^(-layer),2^(layer)
                    local ny=(y-axisY)*negExp+axisY
                    local xbase=(x-(cx-w))*negExp+cx-w
                    if layer<0 then
                        exp=0
                    end
                    local unit=w*negExp
                    for num=-exp-2,exp+1 do
                        local nx=xbase+unit*(num*2)
                        if layer<0 then
                            nx=nx+((negExp-branch)%negExp*w*2)
                        end
                        self.x,self.y=nx,ny
                        -- local comp=goingUp and 1-upperRight or 1-branch%2
                        -- if isBullet and num%2==comp then
                        --     love.graphics.setColor(1,1,1,a)
                        --     drawRef(self)
                        --     love.graphics.setColor(1,1,1,1)
                        -- else
                            drawRef(self)
                        -- end
                    end
                end
                self.x,self.y=x,y
            end
        end
        local function teleportUpdate(obj)
            local px,py=obj.x,obj.y
            local ret
            if not border:insideOne(px,py,1) then -- upper left
                local ax,ay=cx-w,axisY
                obj.x,obj.y=2*px-ax,2*py-ay
                ret=UPPERLEFT
            elseif not border:insideOne(px,py,2) then -- upper right
                local ax,ay=cx+w,axisY
                obj.x,obj.y=2*px-ax,2*py-ay
                ret=UPPERRIGHT
            elseif not border:insideOne(px,py,3) then -- right
                obj.x=obj.x-w*2
                ret=RIGHT
            elseif not border:insideOne(px,py,4) then -- bottom
                local ax,ay=cx+w,axisY
                if branch%2==0 then
                    ax=cx-w
                end
                obj.x,obj.y=(px+ax)/2,(py+ay)/2
                ret=BOTTOM
            elseif not border:insideOne(px,py,5) then -- left
                obj.x=obj.x+w*2
                ret=LEFT
            end
            obj.lastTeleport=ret or obj.lastTeleport
            return ret
        end
        local function bulletBase(cir)
            drawWrapper(cir,1)
            cir.extraUpdate[1]=teleportUpdate
        end
        local function fadeIn(cir)
            Event.EaseEvent{
                obj=cir,
                easeFrame=60,
                aimTable=cir,
                aimKey='spriteTransparency',
                aimValue=1,
                afterFunc=function()
                    cir.safe=false
                end
            }
        end
        
        -- local function generate()
            local direction=math.eval(0,999)
            a=BulletSpawner{x=400,y=500,period=1,frame=0,lifeFrame=14,bulletNumber=6,bulletSpeed=0,bulletLifeFrame=30000,angle=direction,range=math.pi*2,bulletSprite=BulletSprites.blackrice.yellow,bulletEvents={
                function(cir,args,self)
                    if args.index==1 then
                        a.bulletSpeed=a.bulletSpeed+8
                    end
                    cir.invincible=true
                    Event.EaseEvent{
                        obj=cir,
                        easeFrame=60,
                        aimTable=cir,
                        aimKey='speed',
                        aimValue=0
                    }
                    bulletBase(cir)
                end
            }}
        -- end
        -- generate()
        Event.DelayEvent{
            obj=en,
            delayFrame=60,
            executeFunc=function()
                SFX:play('enemyPowerfulShot',true,0.5)
            end
        }
        Event.DelayEvent{
            obj=en,
            delayFrame=600,
            executeFunc=function()
                for i=1,20 do
                    local x,y=Shape.rThetaPos(900,500,i*3+7,math.pi/2)
                    local cir={x=x,y=y,sprite=BulletSprites.blackrice.blue,lifeFrame=20000,fogTime=60,direction=0,speed=(i<11 and -1 or 1)*5,batch=Asset.bulletHighlightBatch,spriteTransparency=0.2,safe=true}
                    cir.extraUpdate={
                        function(cir)
                            fadeIn(cir)
                            cir.updateMove=function (self)
                                self.x=self.x+self.speed
                            end
                            cir.invincible=true
                            bulletBase(cir)
                        end
                    }
                    BulletSpawner.wrapFogEffect(cir,Circle,true)
                end
                SFX:play('enemyPowerfulShot',true,0.5)
            end
        }
        Event.DelayEvent{
            obj=en,
            delayFrame=1800,
            executeFunc=function()
                for i=1,20 do
                    local x,y=400+(i-10.5)*50,800
                    local cir={x=x,y=y,sprite=BulletSprites.blackrice.red,lifeFrame=20000,fogTime=60,direction=(i<11 and -math.pi/2 or math.pi/2),speed=36,batch=Asset.bulletHighlightBatch,spriteTransparency=0.2,safe=true}
                    cir.extraUpdate={
                        function(cir)
                            fadeIn(cir)
                            cir.invincible=true
                            bulletBase(cir)
                        end,
                        function (cir)
                            cir.speed=math.cos(cir.frame/50)*36
                        end
                    }
                    BulletSpawner.wrapFogEffect(cir,Circle,true)
                end
                SFX:play('enemyPowerfulShot',true,0.5)
            end
        }
        Event.LoopEvent{
            obj=en,
            period=30,
            frame=-60,
            executeFunc=function()
                local circle={x=player.x,y=player.y,sprite=BulletSprites.giant.blue,lifeFrame=330,fogTime=30,direction=math.eval(0,999),speed=0,batch=Asset.bulletHighlightBatch,spriteTransparency=0.2,extraUpdate={
                    function(cir)
                        fadeIn(cir)
                        Event.DelayEvent{
                            obj=en,
                            delayFrame=300,
                            executeFunc=function()
                                Event.EaseEvent{
                                    obj=cir,
                                    easeFrame=30,
                                    aimTable=cir,
                                    aimKey='spriteTransparency',
                                    aimValue=0.2
                                }
                            end
                        }
                        bulletBase(cir) -- will replace extraUpdate[1] so that it won't be called again
                    end
                }}
                BulletSpawner.wrapFogEffect(circle,Circle,true)
            end
        }
        Event.LoopEvent{
            obj=player,
            period=1,
            executeFunc=function()
                -- Shape.moveTowards(a,player,0.5,true)
                -- teleportUpdate(a)
                local ret=teleportUpdate(player)
                if ret==LEFT then
                    branch=branch-1
                elseif ret==RIGHT then
                    branch=branch+1
                elseif ret==UPPERLEFT then
                    branch=branch*2
                elseif ret==UPPERRIGHT then
                    branch=branch*2+1
                elseif ret==BOTTOM then
                    branch=bit.arshift(branch,1)
                end
            end
        }
    end
}