return {
    ID=23,
    quote='I can barely escape from these red bigRounds.',-- I have a feeling that something will happen if I linger till...',
    user='doremy',
    spellName='Dream Sign "Lingering Memory"',
    make=function()
        Shape.removeDistance=30
        local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=4800}
        local player=Player{x=400,y=600}
        local function around(bullet,r,theta,radius)
            local sub=Circle{x=bullet.x,y=bullet.y,speed=0,lifeFrame=3000,sprite=BulletSprites.bigRound.red,spriteTransparency=0,safe=true,highlight=true,radius=radius,extraUpdate=function(self)
                if bullet.removed then
                    self.speed=40
                    return
                end
                self.r=math.clamp((self.r or 0)+0.5,0,r)
                self.spriteTransparency=math.clamp((self.spriteTransparency or 0)+0.02,0,1)
                if self.spriteTransparency>=1 then
                    self.safe=false
                end
                self.x,self.y,self.direction=Shape.rThetaPosT(bullet.x,bullet.y,self.r,theta+bullet.direction)
            end}
            sub.forceDrawNormalSprite=true
        end
        Event.LoopEvent{
            period=300,
            frame=270,
            obj=en,
            executeFunc=function(self,times)
                local level=math.ceil((7200-en.hp)/1800)
                Event.LoopEvent{
                    period=1,frame=-120,times=150,
                    executeFunc=function()
                        if player.y>300 then
                            en.x=en.x*0.99+player.x*0.01
                        end
                    end
                }
                local x,y
                if times%2==0 then
                    x,y=en.x,en.y
                else
                    x,y=player.x,player.y
                    -- local dir=Shape.toObj(player,en)
                    -- x,y=Shape.rThetaPos(x,y,30,dir)
                end
                Effect.Charge{obj={x=x,y=y},animationFrame=60}
                Event.DelayEvent{
                    obj=en,delayFrame=60,executeFunc=function()
                        local core=Circle{x=x,y=y,speed=0,lifeFrame=3000,sprite=BulletSprites.bigRound.red,spriteTransparency=0,highlight=true,radius=level+1,safe=true,extraUpdate=function(self)
                            self.spriteTransparency=math.clamp((self.spriteTransparency or 0)+0.02,0,1)
                            if self.spriteTransparency>=1 then
                                self.safe=false
                            end
                            local aimRatio=math.clamp(1-(self.frame-240)/60,0,1)
                            if aimRatio>0 then
                                self.speed=self.speed+0.25*aimRatio
                                local div=self.speed*10/aimRatio
                                self.direction=math.clamp(Shape.toObj(self,player),self.direction-math.pi/div,self.direction+math.pi/div)
                            end
                        end}
                        local offset=math.eval(0,math.pi)
                        for i=1,level,1 do
                            local r=i*8
                            for j=1,6+level do
                                around(core,r,j/ (6+level) *math.pi*2+offset*i,level+1-i)
                            end
                        end
                    end
                }
            end
        }
    end,
    leave=function()
        if G.levelRemainingFrame<=0 then
            G.save.extraUnlock[2]=true
        end
    end
}