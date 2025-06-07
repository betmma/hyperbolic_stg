return {
    ID=15,
    quote='Heptagrams are more mysterious than pentagrams.',
    user='takane',
    spellName='Leaf Skill "Green Heptagram"',
    make=function()
        local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600}
        local b
        b=BulletSpawner{x=400,y=150,period=600,frame=540,lifeFrame=10000,bulletNumber=8,bulletSpeed=210,angle='0+9999',bulletSprite=BulletSprites.rain.green,fogEffect=false,
        spawnBulletFunc=function(self,args)
            local en
            local d0=args.direction
            local nx,ny=args.x-63,args.y--Shape.rThetaPos(args.x,args.y,50,args.direction)
            en=BulletSpawner{x=nx,y=ny,period=199,lifeFrame=160,bulletNumber=1,bulletSpeed=25,angle=0,bulletSprite=self.bulletSprite,speed=math.eval(args.speed),direction=0,bulletEvents={
                function(cir,args)
                    local spd=cir.speed
                    local dir=d0+(math.pi/2)*(b.spawnEvent.executedTimes%2)+(en.frame%20)/20*math.pi+cir.direction
                    cir.speed=0
                    Event.Event{
                        times=1,
                        conditionFunc=function()
                            return en.flag
                        end,
                        executeFunc=function()
                            cir.direction=d0+math.pi*3/5
                            cir.speed=70+25*(math.sin(cir.direction))
                            Event.EaseEvent{
                                obj=cir,
                                aimTable=cir,
                                aimKey='speed',
                                aimValue=0,
                                easeFrame=120,
                                afterFunc=function()
                                    cir.direction=dir
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='speed',
                                        aimValue=spd,
                                        easeFrame=260
                                    }
                            end
                            }
                        end
                    }
                end
            }}
            Event.LoopEvent{
                obj=en,
                period=1,
                executeFunc=function()
                    en.angle=en.direction
                end
            }
            Event.LoopEvent{
                obj=en,
                times=7,
                period=20,
                executeFunc=function(self)
                    en.spawnEvent.period=1
                    local delta=self.executedTimes==0 and math.pi*4/5 or math.pi*3/5
                    en.direction=en.direction+delta
                    en.angle=en.direction
                end
            }
            Event.DelayEvent{
                period=180,
                executeFunc=function()
                    en.flag=1
                end
            }
            -- local cir=Circle({x=args.x or self.x, y=args.y or self.y, radius=args.radius, lifeFrame=self.bulletLifeFrame, sprite=self.bulletSprite, invincible=args.invincible})
            -- -- table.insert(ret,cir)
            -- cir.direction=math.eval(args.direction)
            -- cir.speed=math.eval(args.speed)
            -- for key, func in pairs(self.bulletEvents) do
            --     func(cir,args)
            -- end
        end
        }
    end
}