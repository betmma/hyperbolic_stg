return {
    ID=119,
    user='ariya',
    spellName='',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=20000
        local center={x=400,y=3000}
        local a,b
        local en
        local player=Player{x=400,y=6000}
        en=Enemy{x=400,y=3000,mainEnemy=true,maxhp=8000,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel,{bullet=true,invincible=false})
            SFX:play('enemyCharge',true)
            en:addHPProtection(600,10)
        end}
        en:addHPProtection(1200,10)
        player.moveMode=Player.moveModes.Euclid
        player.border:remove()
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,150,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=en
        G.viewMode.viewOffset={x=0,y=-150}
        local function fixedMove(cir)
            if not cir.fixed then
                local x,y=cir.x,cir.y
                cir.fixed={Shape.screenPosition(x,y)}
            end
            local x,y=cir.fixed[1],cir.fixed[2]
            local speed,dir=cir.speed,cir.direction
            x,y=x+math.cos(dir)*speed,y+math.sin(dir)*speed
            cir.fixed={x,y}
        end
        a=BulletSpawner{x=en.x,y=en.y,period=300,frame=200,lifeFrame=10000,bulletNumber=100,bulletLifeFrame=600,range=math.pi*2,angle='player',bulletSpeed=1,bulletSprite=BulletSprites.stone.yellow,bulletEvents={
            function(cir)
                cir.updateMove=fixedMove
                local drawref=cir.drawSprite
                cir.drawSprite=function(self)
                    if not cir.fixed then
                        local x,y=cir.x,cir.y
                        cir.fixed={Shape.screenPosition(x,y)}
                    end
                    self.x,self.y=Shape.inverseScreenPosition(self.fixed[1],self.fixed[2])
                    drawref(self)
                end
            end
        }
        }
    end
}