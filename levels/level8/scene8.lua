return {
    ID=183,
    user='marisa',
    spellName='Star Sign "Bending Link"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local a,b
        local en
        en=Enemy{x=400,y=600000,mainEnemy=true,maxhp=7200,hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
            en.frame=0
            a.spawnEvent.period=9999
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=1200000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=600000}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local function rotateBase(cir,sign)
            cir.spriteExtraDirection=math.eval(0,999)
            cir.sign=math.mod2Sign(sign) or 1
            cir.extraUpdate[#cir.extraUpdate+1]=function (self)
                self.spriteExtraDirection=self.spriteExtraDirection+math.pi/30*self.sign
            end
        end
        local function connect(cir,partner,obj,num,c1,c2)
            c1=c1 or 'orange'
            c2=c2 or 'red'
            for i=1,num do
                -- local cir2=Circle{x=cir.x,y=cir.y,sprite=BulletSprites.star.purple,lifeFrame=cir.lifeFrame,highlight=true,speed=0,direction=cir.direction}
                -- -- rotateBase(cir2,i)
                -- cir2.extraUpdate[#cir2.extraUpdate+1]=function (self)
                --     if cir.removed or partner.removed then
                --         self:remove()
                --         return
                --     end
                --     local distance=Shape.distanceObj(cir,partner)
                --     local toDir=Shape.toObj(cir,partner)
                --     self.x,self.y=Shape.rThetaPos(cir.x,cir.y,distance/(num+1)*i,toDir)
                -- end
                local cir3=Circle{x=cir.x,y=cir.y,sprite=BulletSprites.star[c1],lifeFrame=cir.lifeFrame,highlight=true,speed=0,direction=cir.direction}
                -- rotateBase(cir3,i)
                if i%2==0 then
                    cir3.invincible=true
                    cir3:changeSpriteColor(c2)
                end
                cir3.extraUpdate[#cir3.extraUpdate+1]=function (self)
                    self.spriteTransparency=cir.spriteTransparency
                    if cir.removed or partner.removed then
                        self:remove()
                        return
                    end
                    local distance=Shape.distanceObj(cir,obj)
                    local distance2=Shape.distanceObj(obj,partner)
                    local to1=Shape.toObj(obj,cir)
                    local to2=math.modClamp(Shape.toObj(obj,partner),to1)
                    self.x,self.y=Shape.rThetaPos(obj.x,obj.y,distance+(distance2-distance)*i/(num+1),to1+(to2-to1)*(i)/(num+1))
                end
            end
        end
        local function shape(angle,n,shrink,link1,link2)
            local inner,outer={},{}
            local speedInner,speedOuter=30,50
            if shrink then
                speedInner,speedOuter=5,10
            end
            local connectMode=1
            local c1,c2
            if not shrink then
                connectMode=math.random(1,3)
            end
            if connectMode==1 then
                c1,c2='orange','red'
                if shrink then
                    c1,c2='green','teal'
                end
            elseif connectMode==2 then
                c1,c2='blue','cyan'
            else
                c1,c2='purple','magenta'
            end
            for j=1,2 do
                for i=1,n do
                    local x1,y1,dir=en.x,en.y,angle+math.pi/n*2*(i-n/2-0.5)
                    if shrink then
                        x1,y1=Shape.rThetaPos(player.x,player.y,70,dir)
                        dir=Shape.to(x1,y1,player.x,player.y)
                    end
                    local cir=Circle{x=x1,y=y1,sprite=BulletSprites.bigStar[c1],lifeFrame=800,highlight=true,speed=speedInner,direction=dir,spriteTransparency=0.0}
                    Event.EaseEvent{
                        obj=cir,
                        easeFrame=30,
                        aimKey='spriteTransparency',
                        aimValue=1,
                    }
                    cir.invincible=true
                    if j==1 then
                        rotateBase(cir,1)
                        table.insert(inner,cir)
                    else
                        rotateBase(cir,-1)
                        cir.speed=speedOuter
                        table.insert(outer,cir)
                    end
                end
            end
            local sign=math.randomSign()
            for i=1,n do
                if connectMode==1 then
                    connect(inner[i],inner[(i%n)+1],en,link1,c1,c2)
                    connect(outer[i],outer[(i%n)+1],en,link1,c1,c2)
                    connect(inner[i],outer[i],en,link2,c1,c2)
                elseif connectMode==2 then
                    connect(inner[i],outer[(i%n)+1],en,link1,c1,c2)
                    connect(outer[i],inner[(i%n)+1],en,link1,c1,c2)
                    connect(inner[i],outer[i],en,link2,c1,c2)
                elseif connectMode==3 then
                    connect(inner[i],inner[(i%n)+1],en,link1,c1,c2)
                    connect(outer[i],outer[(i%n)+1],en,link1,c1,c2)
                    connect(inner[i],outer[(i+sign-1)%n+1],en,link2,c1,c2)
                end
            end
        end
        local aim
        Event.LoopEvent{
            obj=en,period=1,executeFunc=function ()
                local t=(en.frame+220)%250
                local t2=math.floor((en.frame+220)/250)
                local mode2=t2%4==0
                local startFrame=60
                if t==0 then
                    SFX:play('enemyCharge')
                    local aimX,aimY
                    if not mode2 then
                        aimX,aimY=Shape.rThetaPos(player.x,player.y,math.eval(70,20),Shape.toObj(player,en)+math.randomSign()*math.eval(1.57,1))
                    else
                        aimX,aimY=Shape.rThetaPos(player.x,player.y,math.eval(70,20),Shape.toObj(player,en)+math.eval(math.pi,0.1))
                    end
                    aim={x=aimX,y=aimY}
                    local points=Shape.segmentPoints(en.x,en.y,aimX,aimY,5,20)
                    for i=1,#points do
                        local cir=Circle{x=points[i].x,y=points[i].y,sprite=BulletSprites.bigStar[mode2 and 'green' or 'red'],lifeFrame=60,highlight=true,speed=0,direction=Shape.to(points[i].x,points[i].y,en.x,en.y),spriteTransparency=0}
                        cir.invincible=true
                        cir.safe=true
                        Event.EaseEvent{
                            obj=cir,
                            easeFrame=60,
                            aimTable=cir,
                            aimKey='spriteTransparency',
                            aimValue=0.5,
                            progressFunc=function(x)return 1-(x-0.5)^2*4 end
                        }
                    end
                end
                if t==startFrame then
                    SFX:play('enemyPowerfulShot')
                    if not mode2 then
                        -- SFX:play('enemyShot')
                        local angle=Shape.toObj(en,player)
                        shape(angle,16,false,10,20)
                        Event.LoopEvent{
                            obj=en,period=1,times=120,
                            executeFunc=function(self,times,maxTimes)
                                if en:getHPLevel()~=1 then
                                    self:remove()
                                    return
                                end
                                Shape.moveTowards(en,aim,Shape.distanceObj(en,aim)/40,true)
                            end
                        }
                    else
                        local angle=Shape.toObj(player,en)
                        shape(angle,4,true,30,10)
                        local dis=Shape.distanceObj(en,aim)
                        Event.LoopEvent{
                            obj=en,period=1,times=180,
                            executeFunc=function(self,times,maxTimes)
                                Shape.moveTowards(en,aim,dis/180,true)
                            end
                        }
                    end
                end
            end
        }
    end
}