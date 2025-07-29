return {
    ID=104,
    user='yatsuhashi',
    spellName='Dirge "Lost Path of Return"',
    make=function()
        G.levelRemainingFrame=7200
        G.backgroundPattern.overallColorScale=2
        Event.EaseEvent{
            obj=G.backgroundPattern,
            easeFrame=240,
            aimKey='overallColorScale',
            aimValue=0,
            afterFunc=function()
                G.backgroundPattern:remove()
                G.backgroundPattern=BackgroundPattern.Empty()
            end
        }
        Shape.removeDistance=1e100
        local center={x=400,y=300}
        local a,b
        local en
        en=Enemy{x=center.x,y=center.y,mainEnemy=true,maxhp=7200,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
            Effect.Charge{x=en.x,y=en.y}
            en.x,en.y=center.x,center.y
        end}
        en:addHPProtection(600000,1000)
        local player=Player{x=400,y=100,noBorder=true}
        player.homingDistance=200
        player.moveMode=Player.moveModes.Natural
        -- player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player

        local function wrapDistance(spawner)
            local spawnRef=spawner.spawnBatchFunc
            spawner.spawnBatchFunc=function(self)
                if Shape.distanceObj(self,player)>150 then
                    return
                end
                spawnRef(self)
            end
        end
        local latestFairy,latestKilledSignal
        local function summon(x,y)
            local fairy=Enemy{x=x,y=y,mainEnemy=false,maxhp=300,sprite=Asset.fairy.red}
            latestFairy=fairy
            local spawner
            local dangle
            spawner=BulletSpawner{x=x,y=y,period=60,frame=0,lifeFrame=9999,bulletNumber=15,bulletLifeFrame=500,range=0,angle='player',bulletSpeed=60,spawnSFXVolume=0.3,bulletSprite=BulletSprites.note.blue,bulletEvents={
                function(cir,args)
                    local index=args.index
                    if index==1 then
                        -- local distance=Shape.distanceObj(cir,player)
                        local angle=Shape.toObj(player,cir)
                        dangle=-player.speed*math.sin(player.direction-angle)/cir.speed
                    end
                    cir.direction=cir.direction+dangle+(index%3-1)*0.1+(index-8)*0.01*math.sign(dangle)
                    cir.speed=cir.speed-2*index
                end
            },}
            wrapDistance(spawner)
            Event.LoopEvent{
                obj=spawner,period=1,executeFunc=function()
                    if fairy.removed then
                        if fairy==latestFairy then
                            latestKilledSignal=true
                        end
                        spawner:remove()
                        return
                    end
                end
            }
        end

        local removeResist=function()
            Event.LoopEvent{
                obj=en,period=1,executeFunc=function()
                    en.damageResistance=1
                end
            }
        end

        summon(en.x,en.y)
        local dir=math.eval(math.pi/2,math.pi*0.1)
        Event.LoopEvent{
            obj=en,period=20,times=20,conditionFunc=function(self)
                if latestKilledSignal then
                    latestKilledSignal=false
                    return true
                end
                return Shape.distanceObj(en,player)<50
            end,
            executeFunc=function(self,times0,maxTimes0)
                local distance=math.eval(100,20)
                local x,y,dir2=Shape.rThetaPosT(en.x,en.y,distance,dir)
                if y>3e7 then
                    removeResist()
                    self:remove()
                    return
                end
                en.safe=true
                Event.LoopEvent{
                    obj=en,period=1,times=20,executeFunc=function(self,times)
                        Shape.moveTowards(en,{x=x,y=y},0.2,true,true)
                        if times==19 then
                            if times0~=maxTimes0-1 then
                                summon(en.x,en.y)
                            else
                                removeResist()
                            end
                            en.safe=false
                        end
                    end
                }
                dir=math.eval(math.pi/2,math.pi*0.3)
            end
        }
    end
}