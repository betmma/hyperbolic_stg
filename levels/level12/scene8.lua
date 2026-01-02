return {
    ID=109,
    user='kotoba',
    spellName='Hotline "Fuse Web"',
    dialogue='bossDialogue12_8',
    make=function()
        G.levelRemainingFrame=5400
        G.levelIsTimeoutSpellcard=true
        Shape.removeDistance=1e100
        local center={x=400,y=300000}
        local a,b,player
        local en
        local hplevel=1
        en=Enemy{x=center.x,y=center.y,mainEnemy=true,maxhp=96000000,}
        en:addHPProtection(600,10)
        player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local spreadFrame=20
        local function smoke(self)
            BulletSpawner{x=self.x,y=self.y,bulletSprite=BulletSprites.flame.red,period=1,lifeFrame=spreadFrame,bulletSpeed=30,angle='0+999',bulletLifeFrame=30,bulletNumber=1,highlight=true,bulletEvents={function(self)
                self.safe=true
            end},bulletExtraUpdate=function(self)
                self.spriteTransparency=self.spriteTransparency - 0.03
            end}
        end
        local playerRadius=20
        local fireballRadius=6
        local fireballs={}
        local function fuseUpdate(self)
            if self.burnt then -- do nothing
                self.ignited=false
                return
            end
            
            if self.frame<50 then
                self.spriteTransparency=self.frame/50
            elseif self.frame==50 then
                self.safe=false
            end
            -- ignite if connected fuse is ignited
            if not self.preIgnitedFrame then
                for _,connectedFuse in ipairs(self.connect) do
                    if connectedFuse.ignited then
                        self.preIgnitedFrame=self.frame
                        break
                    end
                end
            elseif self.frame>self.preIgnitedFrame+spreadFrame and not self.ignited then
                self.ignited=true
            end
            if Shape.distanceObj(self,player)<playerRadius then
                self.preIgnitedFrame=nil
                self.ignited=false
            end
            for _,fb in ipairs(fireballs) do
                if Shape.distanceObj(self,fb)<fireballRadius then
                    self.ignited=true
                    fb.used=true
                    break
                end
            end
            if self.ignited then
                -- some particle effect later
                smoke(self)
                if not self.bomb then
                    self.spriteTransparency=0.2
                    self.burnt=true
                    self.safe=true
                --     self:remove()
                end
            end
        end
        local function spawnBomb()
            local bomb=Circle{x=en.x,y=en.y,radius=0,sprite=BulletSprites.giant.black,speed=0,invincible=true,highlight=true,lifeFrame=99999,damage=999,extraUpdate={function(self)
                self.forceDrawLargeSprite=true
                if self.frame<60 then
                    self.radius=self.frame*0.15
                end
                if self.ignited and not self.exploded then
                    SFX:play('enemyPowerfulShot')
                    self.exploded=true
                    G.bombExploded=true -- for the secret achievement
                    local explodeTime=player.hitInvincibleFrame-5 -- explode ends just before player invincible ends
                    Event.EaseEvent{
                        obj=self,aimKey='spriteTransparency',aimValue=0,easeFrame=explodeTime
                    }
                    Event.EaseEvent{
                        obj=self,aimKey='radius',aimValue=1000,easeFrame=explodeTime,afterFunc=function()
                            self:remove()
                        end
                    }
                end
            end,fuseUpdate}}
            bomb.bomb=true
            bomb.connect={}
            -- Event.DelayEvent{
            --     delayFrame=500,executeFunc=function()
            --         bomb.ignited=true
            --     end
            -- }
            return bomb
        end
        local bomb=spawnBomb()
        G.bombExploded=false
        local function spawnFusePoint(x,y,dir)
            local fusePoint=Circle{x=x,y=y,direction=dir or 0,radius=2,sprite=BulletSprites.rice.red,speed=0,invincible=true,safe=true,extraUpdate={fuseUpdate},lifeFrame=99999,spriteTransparency=0}
            fusePoint.connect={}
            return fusePoint
        end
        local fuseWeb={}
        local function connectFuses(cir1,cir2,num)
            local points=Shape.segmentPoints(cir1.x,cir1.y,cir2.x,cir2.y,1,num)
            local lastFusePoint=cir1
            for i=2,#points-1 do
                local p=points[i]
                local fusePoint=spawnFusePoint(p.x,p.y,Shape.toObj(p,cir2))
                table.insert(lastFusePoint.connect,fusePoint)
                table.insert(fusePoint.connect,lastFusePoint)
                lastFusePoint= fusePoint
            end
            table.insert(lastFusePoint.connect,cir2)
            table.insert(cir2.connect,lastFusePoint)
        end
        -- some labyrinth like fuse web
        local function spawnFuseWeb()
            local angle0=math.eval(0,999)
            for layer=1,4 do
                fuseWeb[layer]={}
                local r=layer*60
                local pointNum=2^layer*20 -- double for easy connect between layers
                for i=1,pointNum do
                    local angle=angle0 + i/pointNum*2*math.pi
                    local x,y,dir=Shape.rThetaPosT(en.x,en.y,r,angle)
                    local fusePoint=spawnFusePoint(x,y,dir+math.pi/2)
                    table.insert(fuseWeb[layer],fusePoint)
                    if i>1 then 
                        table.insert(fusePoint.connect,fuseWeb[layer][#fuseWeb[layer]-1])
                        table.insert(fuseWeb[layer][#fuseWeb[layer]-1].connect,fusePoint)
                    end
                    if (i+7*layer*layer)%(10+layer*10)==0 then
                        local connectNum=6
                        if layer==1 then
                            -- connect to bomb
                            connectFuses(bomb,fusePoint,connectNum)
                        else
                            -- connect to previous layer
                            local index=math.floor((i-1)/2)+1
                            local prevFusePoint=fuseWeb[layer-1][index]
                            connectFuses(prevFusePoint,fusePoint,connectNum)
                        end
                    end
                end
                table.insert(fuseWeb[layer][1].connect,fuseWeb[layer][#fuseWeb[layer]])
                table.insert(fuseWeb[layer][#fuseWeb[layer]].connect,fuseWeb[layer][1])
            end
        end
        spawnFuseWeb()
        -- fuseWeb[4][1].preIgnitedFrame=0 -- start from here
        local function spawnFireball()
            SFX:play('enemyShot',true,2)
            local dir=Shape.toObj(en,center)+math.randomSign()*math.pi*math.eval(0.4-0.2*((en.frame)/5400),0.1)
            local fireball=Circle{x=en.x,y=en.y,radius=fireballRadius,sprite=BulletSprites.flame.red,speed=80,direction=dir,lifeFrame=9999,highlight=true,extraUpdate={function(self)
                self.forceDrawLargeSprite=true
                self.invincible=true
                if self.used then
                    SFX:play('enemyPowerfulShot',true)
                    -- some bullets here
                    BulletSpawner{x=self.x,y=self.y,bulletSprite=BulletSprites.lightRound.red,period=10,lifeFrame=30,bulletSpeed=70,angle='0+999',bulletLifeFrame=300,bulletNumber=10,highlight=true,bulletEvents={function(self)
                        self.speed=self.speed+math.eval(0,40)
                    end},bulletExtraUpdate=function(self)
                        self.speed=self.speed*0.97+30*0.03
                        if self.frame+33>self.lifeFrame then
                            self.safe=true
                            self.spriteTransparency=self.spriteTransparency - 0.03
                        end
                    end}
                    self:remove()
                end
                local aim=math.modClamp(Shape.toObj(self,center),self.direction)
                local changeRange=0.01+0.01*self.frame/1000
                self.direction=math.clamp(aim,self.direction-changeRange,self.direction+changeRange)
            end}}
            -- clean fireballs that are used
            for i=#fireballs,1,-1 do
                if fireballs[i].used then
                    table.remove(fireballs,i)
                end
            end
            table.insert(fireballs,fireball)
            return fireball
        end
        Event.LoopEvent{
            obj=en,period=1,executeFunc=function()
                local r=math.min(en.frame*1.5,270)
                local angle=en.frame*0.005
                en.x,en.y=Shape.rThetaPos(center.x,center.y,r,angle)
                if en.frame%400==200 then
                    spawnFireball()
                end
            end
        }
        Event.DelayEvent{
            obj=en,
            period=30,
            executeFunc=function()
                SFX:play('enemyPowerfulShot',true)
                local drawRef=en.draw
                en.draw=function(self)
                    local colorref={love.graphics.getColor()}
                    love.graphics.setColor(0,0,1,0.3)
                    Shape.drawCircle(player.x,player.y,playerRadius,'fill')
                    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4] or 1)
                    drawRef(self)
                end
            end
        }
    end,
}