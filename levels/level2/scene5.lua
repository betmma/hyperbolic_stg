return {
    ID=25,
    quote='This kind of ice looks quite sharp. I\'d never want to touch it.',
    user='cirno',
    spellName='Crystalization "Supernatural Lattice"',
    make=function()
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600}
        local bullets={}
        local a
        a=BulletSpawner{x=400,y=300,period=600,frame=540,lifeFrame=23000,bulletNumber=600,bulletSpeed=40,bulletLifeFrame=9900,angle='-1.57+0.9',range=math.pi*200,bulletSprite=BulletSprites.crystal.blue,fogEffect=true,fogTime=20,bulletEvents={
            function(cir,args,self)
                local x0,y0=cir.x,cir.y
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function()
                        if not cir.flag then
                            local dis=Shape.distance(cir.x,cir.y,x0,y0)
                            if dis>60 then
                                cir.flag=true
                                cir.direction=math.eval(0,3.14)
                                cir.speed=math.eval(20,5)
                            end
                            if cir.frame%20==0 then
                                local rand= math.eval(0.0,1.0)
                                local angle=math.pi/3
                                local prob=0.2
                                if rand<prob and cir.turn~=1 then
                                    cir.direction=cir.direction+angle
                                    cir.turn=1
                                elseif rand>1-prob and cir.turn~=-1 then
                                    cir.direction=cir.direction-angle
                                    cir.turn=-1
                                end
                            end
                            local flag=true
                            for key, value in pairs(bullets) do
                                local dis=Shape.distance(value.x,value.y,cir.x,cir.y)
                                if dis<5 then
                                    flag=false
                                    break
                                end
                            end
                            if flag then
                                cir.flag=true
                                cir.speed=0
                                cir.dis=dis
                                table.insert(bullets,cir)
                            end
                            
                        end
                    end
                }
            end
            }
        }
        Event.LoopEvent{
            obj=en,
            period=10,
            executeFunc=function()
                local newB={}
                for key,value in pairs(bullets)do
                    if not value.removed then
                        table.insert(newB,value)
                    end
                end
                bullets=newB
            end
        }
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                local f=a.frame
                -- if f%600==100 then
                --     Effect.Charge{
                --         animationFrame=100,
                --         obj=a,
                --         x=a.x,y=a.y
                --     }
                -- end
                if f%600==200 then
                    local dir=Shape.to(a.x,a.y,player.x,player.y)
                    for key,value in pairs(bullets)do
                        Event.DelayEvent{
                            obj=value,
                            delayFrame=value.dis,
                            executeFunc=function()
                                value.direction=dir--+math.eval(0,0.01)
                                Event.EaseEvent{
                                    obj=value,
                                    easeFrame=200,
                                    aimTable=value,
                                    aimKey='speed',
                                    aimValue=30
                                }
                            end
                        }
                    end
                    bullets={}
                end
            end
        }
    end
}