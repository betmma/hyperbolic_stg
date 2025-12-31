return {
    ID=123,
    user='nina',
    spellName='Truth "Simulation Hypothesis"',
    make=function()
        G.levelRemainingFrame=4200
        -- G.backgroundPattern:remove()
        -- G.backgroundPattern=BackgroundPattern.Empty()
        Shape.axisY=0
        G.levelIsTimeoutSpellcard=true
        Shape.removeDistance=1e100
        local en
        local xratio=1
        local zoomRatio=1.8
        local function getBorder(index)
            local base=200
            local y0=Shape.axisY+base/(zoomRatio-1)
            for i=1,index do
                y0=y0+base
                base=base*zoomRatio
            end
            local basex=base*xratio
            return {{-basex,y0},{basex,y0},{basex*zoomRatio,y0+base},{-basex*zoomRatio,y0+base}},y0+base*0.9,base
        end
        local function arrowCircle(x,y,dir,radius,controller)
            local function changeColorFunc(self)
                if Shape.distance(x,y,controller.x,controller.y)<radius then
                    self.sprite=BulletSprites.round.green
                else
                    self.sprite=BulletSprites.round.red
                end
            end
            local n=16
            for i=1,n do
                local angle=(i-1)/n*math.pi*2+dir
                local x1,y1,dir1=Shape.rThetaPosT(x,y,radius,angle)
                Circle{x=x1,y=y1,speed=0,direction=dir1,lifeFrame=99999,sprite=BulletSprites.round.red,highlight=true,safe=true,spriteTransparency=0.5,extraUpdate=changeColorFunc}
            end
            local gap=radius/4
            local x1,y1,dir1
            for i=-2,2 do
                x1,y1,dir1=Shape.rThetaPosT(x,y,gap*i,dir)
                Circle{x=x1,y=y1,speed=0,direction=dir1,lifeFrame=99999,sprite=BulletSprites.round.red,highlight=true,safe=true,spriteTransparency=0.5,extraUpdate=changeColorFunc}
            end
            for sign=-1,1,2 do
                for i=1,2 do
                    local x2,y2,dir2=Shape.rThetaPosT(x1,y1,gap*i,dir+sign*math.pi*3/4)
                    Circle{x=x2,y=y2,speed=0,direction=dir2,lifeFrame=99999,sprite=BulletSprites.round.red,highlight=true,safe=true,spriteTransparency=0.5,extraUpdate=changeColorFunc}
                end
            end
        end
        local function addControl(i,controller,player)
            local border,y,base=getBorder(i)
            local angles={up=-math.pi/2,down=math.pi/2,left=math.pi,right=0}
            local poses={}
            local r=10
            for dir,angle in pairs(angles) do
                local x,y,dir1=Shape.rThetaPosT(0,y,r*2,angle)
                poses[dir]={x=x,y=y,dir=dir1}
                arrowCircle(x,y,dir1,r,controller)
            end
            local function isPressed(key)
                local data=poses[key]
                if not data then
                    return false
                end
                local ret=Shape.distance(controller.x,controller.y,data.x,data.y)<r
                return ret
            end
            player.keyIsDown=isPressed
        end
        local currentIndex=4
        local maxIndex=4
        local players={}
        local border,y0,base=getBorder(currentIndex)
        local player0=Player{x=0,y=y0,border=PolyLine(border),moveMode=Player.moveModes.Natural}
        -- player0.cancelVortex=true
        players[currentIndex]=player0
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player0
        local bullets={}
        en=Enemy{x=0,y=y0/2,mainEnemy=true,maxhp=94000000,}
        local function newLayer()
            local border,y,base=getBorder(currentIndex-1)
            local currentPlayer=players[currentIndex]
            local player=Player{x=currentPlayer.x/zoomRatio,y=currentPlayer.y/zoomRatio,border=PolyLine(border),moveMode=Player.moveModes.Natural}
            player.naturalDirection=currentPlayer.naturalDirection
            for i=currentIndex,maxIndex-1 do
                players[i].x,players[i].y=players[i+1].x/zoomRatio,players[i+1].y/zoomRatio
                players[i].naturalDirection=players[i+1].naturalDirection
            end
            players[maxIndex].x,players[maxIndex].y=0,y0
            players[maxIndex].naturalDirection=0

            players[currentIndex-1]=player
            addControl(currentIndex,players[currentIndex],player)
            -- G.viewMode.object=player
            player.drawText=function()end
            player.time=player0.time
            local upgrades=Upgrades.dataList
            for _,v in ipairs(upgrades) do
                if G.save.upgrades[v.id] and G.save.upgrades[v.id].bought then
                    v.executeFunc(player)
                end
            end
            currentIndex=currentIndex-1
            for i=#bullets,1,-1 do
                local b=bullets[i]
                b.x,b.y=b.x/zoomRatio,b.y/zoomRatio
            end
            player0.invincibleTime=0.5 -- prevent hit right after new layer
            en.y=y0/zoomRatio^(maxIndex-currentIndex)/2
            local x1,y1,x2,y2=players[maxIndex-1].x,players[maxIndex-1].y,players[maxIndex].x,players[maxIndex].y
            local dx,dy=x2-x1,y2-y1
            local ratio=(y1-Shape.axisY)/Shape.curvature
            G.viewMode.viewOffset={ x=dx/ratio*3, y=dy/ratio*3 }
        end
        Event.LoopEvent{
            obj=player0,period=180,frame=140,executeFunc=function()
                SFX:play('enemyShot')
                local y=y0/zoomRatio^(maxIndex-currentIndex)/2
                local currentPlayer=players[currentIndex]
                local args={x=0,y=y,direction=Shape.to(0,y,currentPlayer.x,currentPlayer.y),speed=30,lifeFrame=3000,sprite=BulletSprites.giant.red,fogTime=20,spriteTransparency=0.1,extraUpdate=function(self)
                    if not self.flag then
                        self.flag=true
                        table.insert(bullets,self)
                        self.checkHitPlayer=function()
                            if not self.safe then 
                                for key, player in pairs(Player.objects) do
                                    local dis=Shape.distance(player.x,player.y,self.x,self.y)
                                    local radi=player.radius+self.radius
                                    if dis<radi+player.radius*player.grazeRadiusFactor and not self.grazed then
                                        EventManager.post(EventManager.EVENTS.PLAYER_GRAZE,player0,(self.lifeFrame<3 or self.frame<3) and 0.05 or 1)
                                        self.grazed=true
                                    end
                                    if player.invincibleTime<=0 and dis<radi then
                                        EventManager.post(EventManager.EVENTS.PLAYER_HIT,player0,self.damage or 1)
                                    end
                                end
                            end
                        end
                    end
                    self.spriteTransparency=math.min(self.spriteTransparency+0.02,1)
                end}
                BulletSpawner.wrapFogEffect(args)
            end
        }
        local offsets={-211,-167,-100,0}
        local function delay(sec)
            Event.DelayEvent{
                obj=player0,delayFrame=sec*60-60,executeFunc=function()
                    SFX:play('enemyCharge',true)
                    Event.DelayEvent{
                        obj=player0,delayFrame=60,executeFunc=function()
                            SFX:play('enemyPowerfulShot',true)
                            newLayer()
                        end
                    }
                    Event.LoopEvent{
                        obj=player0,period=1,frame=60,executeFunc=function(self,times,maxTimes)
                            G.viewMode.viewOffset.x=G.viewMode.viewOffset.x*0.97
                            G.viewMode.viewOffset.y=G.viewMode.viewOffset.y*0.97
                            if times==maxTimes-1 then
                                G.viewMode.viewOffset.x=0
                                G.viewMode.viewOffset.y=0
                            end
                        end,
                    }
                end
            }
        end
        delay(5);delay(20);delay(40)
    end,
}