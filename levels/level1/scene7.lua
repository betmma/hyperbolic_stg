return {
    ID=17,
    user='doremy',
    spellName='Limitation ""',
    make=function()
        G.levelRemainingFrame=5400
        local en=Enemy{x=400,y=200,mainEnemy=true,maxhp=7500}
        local player=Player{x=400,y=600}
        local times=0
        local fade=function(cir)
            cir.safe=true
            Event.EaseEvent{
                obj=cir,
                aimKey='spriteTransparency',
                aimValue=0,
                easeFrame=cir.fadeFrame or 30,
                progressFunc=Event.sineOProgressFunc,
                afterFunc=function()
                    cir:remove()
                end
            }
        end
        local period=240
        Event.LoopEvent{
            obj=en,
            period=period,
            frame=period-60,
            executeFunc=function(self)
                SFX:play('enemyCharge',true)
                local aimx=400+150*math.mod2Sign(times)
                local startx=400-250*math.mod2Sign(times)
                local enaimx=400+200*math.mod2Sign(times)
                local hppercent=math.max(0,en.hp/en.maxhp*1.5-0.5)
                local enaimy=10+190*hppercent
                times=times+1
                for yi=0,120 do
                    local y=100*1.017^yi-100
                    local circ={x=startx,y=y,speed=0,direction=0,radius=1,sprite=BulletSprites.round.purple,highlight=true,events={function(cir)
                        Event.EaseEvent{
                            obj=cir,
                            aimKey='x',
                            aimValue=aimx,
                            easeFrame=period,
                            progressFunc=function(x) return x^3 end,
                            afterFunc=function() fade(cir) end
                        }
                    end},fogTime=60}
                    BulletSpawner.wrapFogEffect(circ)
                    local hintCirc={x=aimx,y=y,speed=0,direction=0,radius=1,sprite=BulletSprites.round.red,highlight=true,safe=true,spriteTransparency=0.3,events={function(cir)
                        cir.fadeFrame=period+30
                        fade(cir)
                        end},fogTime=60}
                    Circle(hintCirc)
                end
                local aimy=hppercent*500+50
                for x=150,650,10 do
                    local circ={x=x,y=600,speed=0,direction=-math.pi/2,radius=1,sprite=BulletSprites.round.purple,highlight=true,events={function(cir)
                        Event.EaseEvent{
                            obj=cir,
                            aimKey='y',
                            aimValue=aimy,
                            easeFrame=period,
                            progressFunc=function(x) return x^3 end,
                            afterFunc=function() fade(cir) end
                        }
                    end},fogTime=60}
                    BulletSpawner.wrapFogEffect(circ)
                    local hintCirc={x=x,y=aimy,speed=0,direction=0,radius=1,sprite=BulletSprites.round.red,highlight=true,safe=true,spriteTransparency=0.3,events={function(cir)
                        cir.fadeFrame=period+30
                        fade(cir)
                        end},fogTime=60}
                    Circle(hintCirc)
                end
                Event.DelayEvent{
                    obj=en,
                    delayFrame=60,
                    executeFunc=function()
                        Event.EaseEventBatch{
                            obj=en,
                            aimKeys={'x','y'},
                            aimValues={enaimx, enaimy},
                            easeFrames={period, period},
                            -- progressFunc=Event.sineIOProgressFunc,
                        }
                    end
                }
            end
        }
    end
}