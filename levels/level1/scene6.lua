return {
    ID=22,
    quote='Bullets are waving left and right, similar to how Manekineko waves its paw.',
    user='mike',
    spellName='Invitation Sign "Welcoming Gesture"',
    make=function()
        local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=7500}
        local player=Player{x=400,y=600}
        -- player.moveMode=Player.moveModes.Monopolar
        -- G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        -- G.viewMode.object=player
        local a
        a={x=150,y=300,period=300,frame=240,lifeFrame=10000,bulletNumber=512,bulletSpeed='20',bulletLifeFrame=10000,angle=math.pi/2,range=math.pi*256*0,bulletSprite=BulletSprites.rim.orange,bulletEvents={
            function(cir,args,self)
                local colors={'gray','red','purple','blue','cyan','green','yellow','orange'}
                local ind=math.floor(math.eval(5,4))
                cir.sprite=BulletSprites.rim[colors[ind]]
                local ratio=(cir.args.index/self.bulletNumber)
                Event.EaseEvent{
                    obj=cir,
                    easeFrame=800*ratio,
                    aimTable=cir,
                    aimKey='direction',
                    aimValue=cir.direction+(((ratio*32%1)*2+0.8)*math.pi/2)*(self.fogTime==61 and 1 or -1),
                    progressFunc=function(x)
                        return math.sin(x*math.pi*2)
                    end,
                    afterFunc=function(self)
                        Event.EaseEvent{
                            obj=cir,aimKey='spriteTransparency',aimValue=0,easeFrame=math.eval(30,10),afterFunc=function()
                                cir:remove()
                            end
                        }
                    end
                }
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=300,
                    executeFunc=function()
                        cir.speed=cir.speed+math.eval(0,1)
                    end
                }
            end
        }}
        local s=BulletSpawner(a)
        a.x=650;a.frame=90;a.fogTime=61
        local c=BulletSpawner(a)
        
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local per=en.hp/en.maxhp
                if per<0.33 then
                    s.bulletNumber,c.bulletNumber=192,192
                elseif per<0.67 then
                    s.bulletNumber,c.bulletNumber=128,128
                else
                    s.bulletNumber,c.bulletNumber=96,96
                end
            end
        }
    end
}