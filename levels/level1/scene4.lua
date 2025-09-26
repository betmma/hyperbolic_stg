return {
    ID=26,
    quote='??',
    user='doremy',
    spellName='"Eye of Horus"',
    make=function()
        local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600}
        local phi0=math.eval(0,999)
        local a
        local tmpBullets={}
        a=BulletSpawner{x=400,y=100,period=240,frame=200,lifeFrame=23000,bulletNumber=30,bulletSpeed=50,bulletLifeFrame=300,angle='1.57+0.5',range=math.pi*2,bulletSprite=BulletSprites.round.yellow,fogEffect=true,fogTime=20,bulletEvents={
            function(cir,args,self)
                if cir.args.index==1 then
                    tmpBullets={}
                end
                table.insert(tmpBullets,cir)
                local sx,sy=cir.speed*math.cos(cir.direction),cir.speed*math.sin(cir.direction)
                sy=sy/2+75
                cir.speed=(sx^2+sy^2)^0.5
                cir.direction=math.atan2(sy,sx)
                cir.sprite=cir.args.index%3==0 and BulletSprites.round.blue or BulletSprites.round.purple
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=60,
                    executeFunc=function()
                        local dirRef=cir.args.index%2==0 and Shape.to(cir.x,cir.y,tmpBullets[cir.args.index%a.bulletNumber+1].x,tmpBullets[cir.args.index%a.bulletNumber+1].y) or Shape.to(cir.x,cir.y,tmpBullets[(cir.args.index-2)%a.bulletNumber+1].x,tmpBullets[(cir.args.index-2)%a.bulletNumber+1].y)
                        --(cir.direction+3.14*0.6*(cir.args.index%2==0 and -1 or 1))%(math.pi*2)
                        local laser=Laser{x=cir.x,y=cir.y,direction=dirRef,speed=300,radius=0.7,index=1,lifeFrame=240,warningFrame=80,fadingFrame=20,sprite=cir.args.index%3==0 and BulletSprites.laser.blue or BulletSprites.laser.purple,
                        bulletEvents={
                            function(cir)
                                Event.LoopEvent{
                                    obj=cir,
                                    times=1,
                                    period=1,
                                    conditionFunc=function()
                                        if not(cir.x>120 and cir.x<680 and cir.y>0 and cir.y<650) then
                                            cir:remove()
                                        end 
                                        if not(cir.x>150 and cir.x<650 and cir.y>0 and cir.y<600) then
                                            return cir.sprite==BulletSprites.laser.blue and cir.index%10==0 
                                        end
                                    end,
                                    executeFunc=function(self)
                                        if not cir.safe then
                                            Circle{x=cir.x,y=cir.y,direction=cir.direction+math.pi+math.eval(0,0.3),speed=20,sprite=BulletSprites.rice.red}
                                        end
                                end}
                            end
                        }}
                        cir.speed=0
                        local rotate=math.sin(a.spawnEvent.executedTimes+phi0)*0.5*(cir.args.index%2==0 and -1 or 1)--math.eval(0,0.5)
                        Event.EaseEvent{
                            obj=laser,
                            aimTable=laser.args,
                            aimKey='direction',
                            aimValue=laser.args.direction+rotate,
                            easeFrame=60,
                            progressFunc=function(x)
                                return -math.sin(math.pi/2*(1-x))+1
                            end,
                        }
                    end
                }
                -- Event.LoopEvent{
                --     obj=cir,period=1,
                --     executeFunc=function ()
                --         -- cir.direction=cir.direction+(cir.y-300)/10000
                --         for key, player in pairs(Player.objects) do
                --             local dis=Shape.distance(player.x,player.y,cir.x,cir.y)
                --             local radi=player.radius+cir.radius
                --             if dis<radi+player.radius*1.5 and not cir.damaged then
                --                 player.hurt=true
                --                 player.hp=player.hp-0.02
                --                 cir.damaged=true
                --             end
                --         end
                --     end
                -- }
            end
            }
        }
    end
}