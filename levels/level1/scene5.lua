return {
    ID=13,
    quote='I wonder where is the best place to induce these bullets.',
    user='mike',
    spellName='Beckon Sign "Koban Attraction"',
    make=function()
        local en=Enemy{x=400,y=200,mainEnemy=true,maxhp=4800}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                en.x=en.x-(en.x-Player.objects[1].x)*0.01
            end
        }
        local player=Player{x=400,y=600}
        local b=BulletSpawner{x=400,y=200,period=600,frame=540,lifeFrame=10000,bulletNumber=120,bulletSpeed=30,angle='0+9999',bulletSprite=BulletSprites.round.yellow,bulletEvents={
            function(cir,args)
                local key=args.index
                Event.LoopEvent{
                    obj=cir,
                    times=5,
                    period=1,
                    conditionFunc=function()return
                        not Player.objects[1].border:inside(cir.x,cir.y)
                    end,
                    executeFunc=function(self)
                        cir.speed=20
                        cir:changeSpriteColor('red')
                        cir.direction=Shape.to(cir.x,cir.y,Player.objects[1].x,Player.objects[1].y)
                        -- Event.EaseEvent{
                        --     obj=cir,
                        --     easeFrame=60,
                        --     aimTable=cir,
                        --     aimKey='direction',
                        --     aimValue=cir.direction+1,
                        --     afterFunc=function(self)
                        --         cir.direction=math.pi+cir.direction
                        --         cir.speed=20
                        --     end
                        -- }
                end}
            end
        },
        spawnBatchFunc=function(self)
            SFX:play('enemyShot',true,1)
            local num=math.eval(self.bulletNumber)
            local range=math.eval(self.range)
            local angle=math.eval(self.angle)
            self.angle2=(self.angle2 or math.eval(self.angle))+math.pi/12
            local angle2=self.angle2 or 0
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            local sideNum=3
            for i = 1, num, 1 do
                local direction=range*(i-0.5-num/2)/num+angle
                local theta=direction-angle2
                local vt,vp=speed*math.cos(theta),speed*math.sin(theta)*0.7
                local sped=math.sqrt(vt^2+vp^2)
                self:spawnBulletFunc{direction=direction,speed=sped,radius=size,index=i}
            end
            -- angle2=angle2+math.pi
            -- for i = 1, num, 1 do
            --     local direction=range*(i-0.5-num/2)/num+angle
            --     local sped=speed/math.cos((direction-angle2)%(math.pi/(sideNum/2))-math.pi/sideNum)^(1)
            --     self:spawnBulletFunc{direction=direction,speed=sped,radius=size,index=i}
            -- end
        end
        }
        Event.LoopEvent{
            obj=b,
            period=600,
            frame=60,
            executeFunc=function()
                Effect.Charge{obj=b,x=b.x,y=b.y}
            end
        }
        Event.LoopEvent{
            obj=b,
            period=1,
            executeFunc=function()
                b.x=en.x
                b.y=en.y
            end
        }
    end
}