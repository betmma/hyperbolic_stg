return {
    ID=146,
    user='chimi',
    spellName='Mountain Spirit Sign "Qi of Silent Land"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1500
        local a,b
        local en
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=9000}
        -- en:addHPProtection(600,10)
        local player=Player{x=400,y=600,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        a=BulletSpawner{x=400,y=300,period=30,frame=-20,lifeFrame=10000,bulletNumber=30,bulletSpeed='0',bulletLifeFrame=1500,angle='player',range=math.pi*2,bulletSprite=BulletSprites.cross.orange,fogEffect=true,fogTime=10,bulletEvents={
            function(cir,args,self)
                Event.EaseEvent{
                    obj=cir,
                    easeFrame=900,
                    aimKey='speed',
                    aimValue=20,
                    progressFunc=function(x)
                        return math.sin(x*4.5*math.pi)
                    end
                }
            end
        },spawnBatchFunc=function(self)
            SFX:play('enemyShot',true,self.spawnSFXVolume)
            local num=math.eval(self.bulletNumber)
            local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
            local spawnCircleRadius=20
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            local x0,y0=Shape.rThetaPos(self.x,self.y,math.eval(60,45),math.modClamp(math.eval(0,999),angle,math.pi/2))
            Event.LoopEvent{
                obj=en,period=1,times=10,executeFunc=function(event,dt)
                    Shape.moveTowards(en,{x=x0,y=y0},1,true)
                end
            }
            angle=angle+math.eval(0,0.5)
            for i = 1, num, 1 do
                local r=spawnCircleRadius*(1-math.eval(0.5,0.5)^2)--*(math.abs(math.cos(rdir-direction))*0.3+0.7)
                -- r=r-r%2
                local rdir=math.eval(0,999)--math.random(1,6)*math.pi/3+math.eval(0,0.1)+angle*9
                local x,y=Shape.rThetaPos(x0,y0,r,rdir)
                direction=Shape.to(x,y,x0,y0)-Shape.to(x0,y0,x,y)+math.pi+angle
                Event.DelayEvent{
                    delayFrame=r,
                    executeFunc=function()
                        self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed,radius=size,index=i,batch=self.bulletBatch,fogTime=35-r,sprite=self.bulletSprite}
                    end
                }
            end
        end}
    end
}