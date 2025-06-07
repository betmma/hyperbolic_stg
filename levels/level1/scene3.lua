return {
    ID=23,
    quote='I can barely escape from these red hearts.',-- I have a feeling that something will happen if I linger till...',
    user='doremy',
    spellName='Dream Sign "Lingering Memory"',
    make=function()
        Shape.removeDistance=300
        local en=Enemy{x=400,y=100,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600}
        local moveFunc=function(cir,args,self)
            local color2ratio={green=0.3,blue=0.5,purple=0.8,red=1}
            local color=cir.sprite.data.color
            local moveRatio=color2ratio[color]
            local ratio=(cir.args.index/self.bulletNumber)
            if color=='purple'or color=='red'then
                cir.speed=cir.speed*ratio
                cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)
            end
            Event.EaseEvent{
                obj=cir,
                easeFrame=9500,--*ratio,
                aimTable=cir,
                aimKey='x',
                aimValue=cir.x+moveRatio,
                progressFunc=function(x)
                    return player.x--math.sin(x*math.pi*2)
                end
            }
            Event.EaseEvent{
                obj=cir,
                easeFrame=9500,--*ratio,
                aimTable=cir,
                aimKey='y',
                aimValue=cir.y+moveRatio,
                progressFunc=function(x)
                    return player.y--math.sin(x*math.pi*2)
                end
            }
        end
        local a,b,c,d
        a=BulletSpawner{x=400,y=300,period=120,lifeFrame=10000,bulletNumber=10,bulletSpeed='20',bulletLifeFrame=10000,angle='0+3.14',range=math.pi*2,bulletSprite=BulletSprites.butterfly.green,bulletEvents={
            moveFunc
        }}
        a.removeDistance=500
        Event.LoopEvent{
            period=1,
            obj=a,
            executeFunc=function()
                local frame=a.frame
                local theta=frame/120
                local x,y=Shape.rThetaPos(player.x,player.y,30,theta)
                a.x,a.y=x,y
                local per=math.min(en.hp/en.maxhp,G.levelRemainingFrame/G.levelRemainingFrameMax)
                if per<0.8 and not b then
                    b=BulletSpawner{x=400,y=300,period=120,lifeFrame=10000,bulletNumber=10,bulletSpeed='15',bulletLifeFrame=10000,angle='0+3.14',range=math.pi*2,bulletSprite=BulletSprites.butterfly.blue,bulletEvents={
                        moveFunc,
                        function(cir,args,self)
                            Event.DelayEvent{
                                delayFrame=20,
                                executeFunc=function()
                                    cir.direction=Shape.to(b.x,b.y,player.x,player.y)
                                end
                            }
                        end
                    }}
                    b.removeDistance=500
                end
                if b then
                    local x,y=Shape.rThetaPos(player.x,player.y,math.min(40,30+b.frame/2),theta+b.frame/360)
                    b.x,b.y=x,y
                end
                if per<0.6 and not c then
                    c=BulletSpawner{x=400,y=300,period=180,lifeFrame=10000,bulletNumber=4,bulletSpeed='10',bulletLifeFrame=10000,angle='0+3.14',range=math.pi*2,bulletSprite=BulletSprites.butterfly.purple,bulletEvents={
                        moveFunc,
                    }}
                    c.removeDistance=500
                end
                if c then
                    local x,y=Shape.rThetaPos(player.x,player.y,math.min(50,40+c.frame/2),theta+b.frame/360+c.frame/240)
                    c.x,c.y=x,y
                end
                if per<0.4 and not d then
                    --1/(1/180+1/120+1/240+1/360)=48
                    local the=theta+b.frame/360+c.frame/240
                    local need=math.pi-the%math.pi
                    d=BulletSpawner{x=400,y=300,period=452,frame=452-need*48,lifeFrame=10000,bulletNumber=1,bulletSpeed='8',bulletLifeFrame=10000,angle='0+3.14',range=math.pi*2,bulletSprite=BulletSprites.butterfly.red,bulletEvents={
                        moveFunc,
                    }}
                    d.removeDistance=10000
                end
                if d then
                    local x,y=Shape.rThetaPos(player.x,player.y,math.min(60,50+c.frame/2),theta+b.frame/360+c.frame/240+(d.realFrame)/180)
                    d.x,d.y=x,y
                end
            end
        }
    end,
    leave=function()
        if G.levelRemainingFrame<=0 then
            G.save.extraUnlock[2]=true
        end
    end
}