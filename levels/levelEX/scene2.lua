return {
    ID=43,
    quote='Hyperbolic geometry distorts her rings a lot.',
    user='suwako',
    spellName='Divine Tool "Moriya\'s Elastic Ring"',
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=2000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local poses={}
        for i = 1, 12, 1 do
            local nx,ny=Shape.rThetaPos(400,300,100,math.pi/6*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local a
        a=BulletSpawner{x=400,y=300,period=30,frame=0,lifeFrame=10000,bulletNumber=48,bulletSpeed=50,bulletLifeFrame=10000,angle='0+999',spawnCircleRadius=0,range=math.pi*2,bulletSprite=BulletSprites.rice.red,bulletEvents={
            function(cir,args,self)
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=30,
                    executeFunc=function()
                        local direction=a.angle--Shape.to(a.x,a.y,player.x,player.y)--args.index%8*math.pi/4
                        local nx,ny=Shape.rThetaPos(a.x,a.y,290,direction)
                        cir.direction=Shape.to(cir.x,cir.y,nx,ny)--+math.pi
                    end
                }
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    times=3,
                    conditionFunc=function()return not player.border:inside(cir.x,cir.y) end,
                    executeFunc=function()
                        player.border:reflection(cir)
                    end
                }
            end
        }}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local fr=a.frame%600
                if fr==302 then
                    a.spawnEvent.period=10000
                elseif fr==2 then
                    a.spawnEvent.period=15
                    a.spawnEvent.frame=0
                end
                if fr<200 then
                    a.angle=Shape.to(a.x,a.y,player.x,player.y)
                else
                    a.angle=a.angle+math.pi/89
                end
            end
        }

    end
}