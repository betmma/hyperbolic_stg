return {
    ID=57,
    quote='?',
    user='nitori',
    spellName='Water Sign "Kappa\'s Meandering Current"', 
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=2000
        local a,b
        local en
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.4},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            -- a.spawnEvent.frame=a.spawnEvent.period-60
            en:addHPProtection(600,10)
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local poses={}
        for i = 1, 12, 1 do
            local nx,ny=Shape.rThetaPos(400,300,100,math.pi/6*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local direction=0
        -- a=BulletSpawner{x=400,y=300,period=300,frame=200,lifeFrame=10000,bulletNumber=0,bulletSpeed=20,bulletLifeFrame=200,angle='1+999',range=math.pi*0,spawnCircleRadius=50,spawnCircleAngle='0+999',fogEffect=true,fogTime=30,bulletSprite=BulletSprites.bigStar.red,bulletEvents={
        --     function(cir,args,self)
        --     end
        -- }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local t=en.frame%200
                if Shape.distance(en.x,en.y,player.x,player.y)<30 then
                    local direction=Shape.to(en.x,en.y,player.x,player.y) 
                    local x,y=Shape.rThetaPos(en.x,en.y,0.3,direction+math.pi)
                    en.x,en.y=x,y
                elseif Shape.distance(en.x,en.y,player.x,player.y)>70 then
                    local direction=Shape.to(en.x,en.y,player.x,player.y) 
                    local x,y=Shape.rThetaPos(en.x,en.y,0.3,direction)
                    en.x,en.y=x,y
                end
                if t==60 then
                    local directionRef=direction
                    local x,y=Shape.rThetaPos(400,300,math.eval(30,20),math.eval(0,999))
                    while math.abs(math.modClamp(direction-directionRef,0,math.pi/2))<math.pi/4 do
                        direction=math.eval(0,999)
                    end
                    Event.LoopEvent{
                        obj=en,
                        period=1,
                        times=600,
                        executeFunc=function(self,times)
                            if times==0 then
                                self.x,self.y,self.direction=x,y,direction
                                self.hpLevel=en:getHPLevel()
                            end
                            local r=((times-300)/300)^2*180+4*self.hpLevel
                            for i=1,2 do
                                local x1,y1=Shape.rThetaPos(self.x,self.y,r,math.pi*(i-0.5)+self.direction)
                                local dir2=Shape.to(x1,y1,x,y)
                                local j=0
                                local fail=false
                                while true do
                                    local jt=j+(times%30)/10*(i==1 and 1 or -1) -- note that, this divisor in modulo needs to match the below "self.hpLevel==3 and (j+i)%2==0" extra bullet part 
                                    local x2,y2=Shape.rThetaPos(x1,y1,5*jt,dir2+math.pi/2)
                                    local dir3=Shape.to(x2,y2,x1,y1)+math.pi*(jt>0 and 1 or 0)
                                    if jt==0 then
                                        dir3=dir2+math.pi/2
                                    end
                                    local ph=(jt)/5
                                    if self.hpLevel>=2 then
                                        ph=ph+times*(i==1 and 1 or -1)/(self.hpLevel==2 and 50 or 100)
                                    end
                                    local tilde=math.sin(ph)*5*(self.hpLevel+1)
                                    local x3,y3=Shape.rThetaPos(x2,y2,tilde,dir3+math.pi/2)
                                    local inside=player.border:inside(x3,y3)
                                    if inside then
                                        Circle{x=x3,y=y3,direction=dir3,lifeFrame=0,sprite=BulletSprites.round.blue}
                                        if self.hpLevel==3 and (j)%3==0 then
                                            local jt2=j+(times%30)/5*(i==1 and 1 or -1)
                                            local x2,y2=Shape.rThetaPos(x1,y1,5*jt2,dir2+math.pi/2)
                                            local dir3=Shape.to(x2,y2,x1,y1)+math.pi*(jt2>0 and 1 or 0)
                                            if jt2==0 then
                                                dir3=dir2+math.pi/2
                                            end
                                            local ph=(jt2)/5+times*(i==1 and 1 or -1)/100
                                            local tilde=math.sin(ph)*5*(self.hpLevel+1)-6
                                            local x3,y3=Shape.rThetaPos(x2,y2,tilde,dir3+math.pi/2)
                                            Circle{x=x3,y=y3,direction=dir3,lifeFrame=0,sprite=BulletSprites.round.blue}
                                            -- local x4,y4
                                            -- x4,y4=Shape.rThetaPos(x2,y2,tilde-4,dir3+math.pi/2)
                                            -- Circle{x=x4,y=y4,direction=dir3,lifeFrame=0,sprite=BulletSprites.round.blue}
                                            -- x4,y4=Shape.rThetaPos(x2,y2,tilde-8,dir3+math.pi/2)
                                            -- Circle{x=x4,y=y4,direction=dir3,lifeFrame=0,sprite=BulletSprites.round.blue}
                                        end
                                        fail=false
                                    else
                                        if fail and math.abs(j)>8 then -- means both sides are outside
                                            break
                                        end
                                        fail=true
                                    end
                                    if j>=0 then
                                        j=-j-1
                                    else
                                        j=-j
                                    end
                                end
                            end
                        end
                    }
                end
            end
        }
        
    end
}