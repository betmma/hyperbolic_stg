return {
    ID=105,
    user='benben',
    spellName='Sonata ""',
    make=function()
        G.levelRemainingFrame=10800
        Shape.removeDistance=1e100
        local center={x=400,y=300000}
        local a,b
        local en
        local hplevel=1
        en=Enemy{x=center.x,y=center.y,mainEnemy=true,maxhp=14400,hpSegments={0.75,0.5,0.25},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
            hplevel=hplevel+1
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local moveUpdateRef=player.moveUpdate
        player.moveUpdate=function(self,dt)
            if self.stop then
                -- Shape.update is in moveUpdate and is also skipped. But increment time and frame should still happen.
                self.time=self.time+dt*Shape.timeSpeed
                self.frame=self.frame+1
                return
            end
            moveUpdateRef(self,dt)
        end
        local tick=0
        local function switchBase(self)
            self.refSpeed=self.refSpeed or self.speed
            if not player.stop and self.stopFlag~=true then
                self.stopFlag=true
                self:changeSprite(BulletSprites.rest[self.sprite.data.color])
                self.speed=0
            elseif player.stop and self.stopFlag~=false then
                self.stopFlag=false
                self:changeSprite(BulletSprites.note[self.sprite.data.color])
                self.speed=self.refSpeed
            end
            if self.tick~=tick then
                self.tick=tick
                self.speed=self.refSpeed
            end
            self.speed=self.speed*0.9
        end
        local function type1(x,y)
            BulletSpawner{x=x,y=y,period=1,frame=0,lifeFrame=2,bulletNumber=15,bulletLifeFrame=500,range=math.pi*2,angle=0,spawnCircleRadius=20,spawnCircleAngle='0+999',bulletSpeed=100,bulletSprite=BulletSprites.note.red,bulletExtraUpdate={switchBase},bulletSize=1.5
            }
        end
        local function type2(x,y)
            BulletSpawner{x=x,y=y,period=1,frame=0,lifeFrame=2,bulletNumber=45,bulletLifeFrame=800,range=math.pi*2,angle='player',spawnCircleRadius=2,spawnCircleAngle='0+999',bulletSpeed=60,bulletSprite=BulletSprites.note.blue,bulletExtraUpdate={switchBase},bulletSize=1.5,
            spawnBatchFunc=function(self)
                SFX:play('enemyShot',true,self.spawnSFXVolume)
                local num=math.eval(self.bulletNumber)
                local range=math.eval(self.range)
                local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
                local spawnCircleRange=math.eval(self.spawnCircleRange)
                local spawnCircleRadius=math.eval(self.spawnCircleRadius)
                local speed=math.eval(self.bulletSpeed)
                local size=math.eval(self.bulletSize)
                for i = 1, num, 1 do
                    if i%5<3 then
                        goto continue
                    end
                    local x,y,direction=Shape.rThetaPosT(self.x,self.y,spawnCircleRadius*(i-0.5-num/2),angle+math.pi/2)
                    direction=direction-math.pi/2
                    self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed,radius=size,index=i,batch=self.bulletBatch,fogTime=self.fogTime,sprite=self.bulletSprite}
                    ::continue::
                end
            end
            }
        end
        local function type3(x,y)
            BulletSpawner{x=x,y=y,period=1,frame=0,lifeFrame=2,bulletNumber=35,bulletLifeFrame=800,range=0,angle='player',spawnCircleRadius=0,spawnCircleAngle='0+999',bulletSpeed=150,bulletSprite=BulletSprites.note.purple,bulletExtraUpdate={switchBase},bulletSize=1.5,bulletEvents={
                function(circle,args)
                    local index=args.index
                    if index<=15 then
                        circle.speed=index*10+30
                    else
                        circle.direction=circle.direction+math.pi/40*(index-12)*math.mod2Sign(index)
                        circle.speed=180-(index-15)*7.5
                    end
                end
            }}
        end
        local function types()
            local hpLevel=hplevel
            if hpLevel==4 then
                hpLevel=math.random(1,3)
            end
            local x,y=Shape.rThetaPos(player.x,player.y,math.eval(100,50),math.eval(0,999))
            if hpLevel==1 then
                type1(x,y)
            elseif hpLevel==2 then
                type2(x,y)
            elseif hpLevel==3 then
                type3(x,y)
            end
        end
        local rhythms={{1,1,1,1},{0.5,0.5,1,1,1},{0.75,0.75,0.5,1,1},{1,1,0.5,0.5,1},{0.75,0.25,0.75,0.25,1,1},{1,1,0.75,0.75,0.5},{1,0.5,0.5,1,0.5,0.5}}
        local function randRhythm(spawn)
            local frame=0
            local rhythm=rhythms[math.random(1,#rhythms-4+hplevel)]
            for key, value in pairs(rhythm) do
                Event.DelayEvent{
                    obj=en,delayFrame=frame,executeFunc=function()
                        SFX:play('hit')
                        if spawn then -- player can move, bullet stopped, spawn new bullets
                            types()
                        else -- player stopped, bullet moving, tick is to let bullets move jerkily
                            tick=tick+1
                        end
                    end
                }
                frame=frame+value*30
            end
        end
        Event.LoopEvent{
            obj=en,period=240,frame=180,executeFunc=function(self)
                SFX:play('hit')
                randRhythm(true)
                Event.DelayEvent{
                    obj=en,delayFrame=120,executeFunc=function()
                        player.stop=true
                        SFX:play('hit2')
                        Effect.Shockwave{x=player.x,y=player.y,canRemove={},sprite=BulletSprites.shockwave.blue,growSpeed=0.9,radius=40}
                        randRhythm()
                    end
                }
                Event.DelayEvent{
                    obj=en,delayFrame=240,executeFunc=function()
                        player.stop=false
                        SFX:play('hit2')
                        Effect.Shockwave{x=player.x,y=player.y,canRemove={},sprite=BulletSprites.shockwave.red,growSpeed=0.9,radius=40}
                    end
                }
            end
        }
    end
}