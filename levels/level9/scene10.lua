return {
    ID=190,
    user='utsuho',
    spellName='Star Birthing "Agarized Accretion"',
    make=function()
        G.levelRemainingFrame=9000
        Shape.removeDistance=1e100
        local player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300000}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local en
        local nukes={}
        en=Enemy{x=center.x,y=center.y,mainEnemy=true,maxhp=8400}
        en:addHPProtection(1e10,1e10)
        en.safe=true
        local playerNuke
        Event.DelayEvent{
            obj=en,delayFrame=30,executeFunc=function ()
                SFX:play('enemyPowerfulShot')
                playerNuke=Circle{x=player.x,y=player.y,radius=0,speed=0,direction=0,sprite=BulletSprites.nuke,lifeFrame=100000,invincible=true,safe=true,highlight=true,events={function(cir)
                    Event.EaseEvent{
                        obj=cir,aimKey='radius',aimValue=20,easeFrame=60
                    }
                    cir.spriteColor={1,0.3,1}
                end},extraUpdate=function (cir)
                    cir.x,cir.y=player.x,player.y
                end}
                Event.LoopEvent{
                    obj=en,period=1,executeFunc=function()
                        en.hp=en.maxhp*math.clamp(1-(playerNuke.radius-20)/100,0,1)
                        if en.hp<=0 then
                            en:dieEffect()
                        end
                    end
                }
            end
        }
        local hitPlayerFunc=function(self)
            if not self.safe then 
                for key, player in pairs(Player.objects) do
                    local dis=Shape.distance(player.x,player.y,self.x,self.y)
                    local radi=playerNuke.radius+self.radius
                    -- if dis<radi+playerNuke.radius*player.grazeRadiusFactor and not self.grazed then
                    --     EventManager.post(EventManager.EVENTS.PLAYER_GRAZE,player,self:grazeValue())
                    --     self.grazed=true
                    -- end
                    if player.invincibleTime<=0 and dis<radi then
                        if self.radius>playerNuke.radius then
                            EventManager.post(EventManager.EVENTS.PLAYER_HIT,player,self.damage or 1)
                            Event.EaseEvent{
                                obj=playerNuke,aimKey='radius',aimValue=playerNuke.radius*0.9,easeFrame=30
                            }
                        else
                            SFX:play('notice',true)
                            Event.EaseEvent{
                                obj=self,aimKey='radius',aimValue=0,easeFrame=30
                            }
                            Event.EaseEvent{
                                obj=playerNuke,aimKey='radius',aimValue=playerNuke.radius+(2+math.max(0,playerNuke.radius*0.1-2)),easeFrame=30,afterFunc=function ()
                                    self:remove()
                                end
                            }
                            self.safe=true
                            self.speed=0
                            Shape.moveToInTime(self,player,30)
                        end
                    end
                end
            end
        end
        Event.LoopEvent{
            obj=en,period=150,frame=60,executeFunc=function ()
                local spawnRadius=200+playerNuke.radius*2
                BulletSpawner{x=player.x,y=player.y,period=1,lifeFrame=1,bulletNumber=10,bulletSpeed=20,bulletLifeFrame=600,spawnCircleRadius=spawnRadius,angle=3.14,range=math.pi*2,spawnSFXVolume=0,bulletSprite=BulletSprites.nuke,bulletSize=0,bulletBatch=Asset.bulletHighlightBatch,bulletEvents={
                    function (cir,args)
                        cir.x,cir.y=Shape.rThetaPos(cir.x,cir.y,50,math.eval(0,999))
                        cir.direction=math.eval(cir.direction,1.5)
                        cir.speed=cir.speed+math.eval(0,10)
                        local radius=playerNuke.radius
                        if math.random()<0.7 then
                            radius=radius+math.eval(30,15)
                        else
                            radius=radius-math.eval(6+math.max(0,playerNuke.radius*0.25-5),2)
                            cir.lifeFrame=cir.lifeFrame+400 -- edible bullets last longer
                            cir.speed=cir.speed+5
                        end
                        cir.safe=true
                        cir.checkHitPlayer=hitPlayerFunc
                        local index=args.index
                        Event.DelayEvent{
                            obj=cir,delayFrame=index*15,executeFunc=function ()
                                if Shape.distanceObj(cir,player)<radius+playerNuke.radius+60 then
                                    cir:remove()
                                    return
                                end
                                SFX:play('enemyShot',true,0.4)
                                Shape.moveToInTime(en,cir,10) -- looks like enemy moving around and planting bullets
                                Event.EaseEvent{
                                    obj=cir,aimKey='radius',aimValue=radius,easeFrame=60,progressFunc=function(x)return math.clamp(x*1.2-0.2,0,1)end,afterFunc=function ()
                                        cir.safe=false
                                    end
                                }
                            end}
                    end
                },bulletExtraUpdate={function (cir)
                    if Shape.distanceObj(cir,player)>spawnRadius+200 then
                        cir:remove()
                    end
                end,Circle.FadeOut}}
            end
        }
    end
}