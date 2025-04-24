return {
    user='sakuya',
    spellName='Conjuring "Pendulum of Illusory Speed"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local a
        local en
        en=Enemy{x=400,y=600000,mainEnemy=true,maxhp=7200}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=1200000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local poses={}
        for i = 1, 30, 1 do
            local nx,ny=Shape.rThetaPos(400,600000,700,math.pi/15*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player

        local distance,angle
        a=BulletSpawner{x=400,y=600000,period=10,frame=-30,lifeFrame=10000,bulletNumber=7,bulletSpeed=9,bulletLifeFrame=650,angle='player',range=math.pi*0,highlight=true,bulletSprite=BulletSprites.flame.red,bulletEvents={
            function(cir,args,self)
                math.random() -- I used to use random() to determine initial frame of flame sprite gif, so after removing that random() it's needed to add 1 here to make random number same as before and don't break replay. 
                cir.direction=cir.direction+math.eval(0,angle)
                local coeff=math.eval(1,0.4)
                cir.speed=(20+(math.sin(en.frame/200+3.14)/2+0.5)*100)*coeff
                local acceleration=(-math.sin(en.frame/200+3.14)/2+0.5)*1.0*coeff
                cir.extraUpdate[1]=function()
                    cir.speed=cir.speed+acceleration*math.max(cir.frame-50,0)/40
                end
            end
        }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                distance=Shape.distance(en.x,en.y,player.x,player.y)
                angle=1/math.sinh(distance/Shape.curvature)
            end
        }
    end
}