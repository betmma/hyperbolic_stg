return {
    ID=88,
    user='nareko',
    spellName='Riddle Sign "Pseudo Hexagonal Labyrinth"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1000
        local en
        en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200,}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local spawnCount=0
        local function spawn()
            spawnCount=(spawnCount+1)%2
            local delayCount=0
            local count=0
            local theta=math.eval(0,999)
            local sideNum=6
            for r=1,3 do
                local num=r*6
                r=r*40
                for i=1,num do
                    local angle=theta+i*math.pi*2/num
                    local rRatio=math.cos(math.pi/sideNum)/math.cos((angle-theta)%(math.pi/(sideNum/2))-math.pi/sideNum)
                    local x,y,to=Shape.rThetaPosT(center.x,center.y,r*rRatio,angle)
                    Event.DelayEvent{
                        obj=en,delayFrame=count*2,executeFunc=function()
                            local b=BulletSpawner{x=x,y=y,period=10,lifeFrame=50,bulletNumber=6,bulletSpeed=50-(spawnCount)*10,bulletLifeFrame=400,angle=to+math.pi/2,range=math.pi*2,bulletSprite=BulletSprites.blackrice.yellow,fogEffect=true,fogTime=20}
                            b.delayCount=delayCount
                            delayCount=delayCount+1
                            Event.LoopEvent{
                                obj=b,
                                period=10,
                                executeFunc=function()
                                    b.angle=b.angle+0.05*math.mod2Sign(b.delayCount)*(spawnCount+1)
                                end
                            }
                        end
                    }
                    count=count+1
                end
            end
        end
        Event.LoopEvent{
            obj=en,
            period=200,
            frame=140,
            executeFunc=function()
                spawn()
            end
        }
    end
}