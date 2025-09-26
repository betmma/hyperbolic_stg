return {
    ID=21,
    quote='My common sense really gets in the way.',
    user='takane',
    spellName='Forest Sign "Folded Forest Region"',
    make=function()
        local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600}
        local b=BulletSpawner{x=400,y=300,period=60,lifeFrame=10000,bulletNumber=30,bulletSpeed='10+3',bulletLifeFrame=10000,angle='0+3.14',bulletSprite=BulletSprites.bill.green,spawnBatchFunc=function(self)
            SFX:play('enemyShot',true)
            local num=math.eval(self.bulletNumber)
            local range=math.eval(self.range)
            local angle=math.eval(self.angle)
            local size=math.eval(self.bulletSize)
            for i = 1, num, 1 do
                local direction=range*(i-0.5-num/2)/num+angle
                self:spawnBulletFunc{x=self.x,y=self.y,direction=direction,speed=math.eval(self.bulletSpeed),radius=size,index=i,batch=self.bulletBatch}
            end
        end}
        local greenLines=Shape{x=300,y=0,lifeFrame=99999}
        table.insert(G.sceneTempObjs,greenLines)
        greenLines.items={}
        greenLines.draw=function(self)
            local colorref={love.graphics.getColor()}
            love.graphics.setColor(0,1,0,0.5)
            local new={}
            for i,value in pairs(self.items) do
                local x1,y1,x2,y2,rest=value[1],value[2],value[3],value[4],value[5]
                if rest>0 then
                    table.insert(new,{x1,y1,x2,y2,rest-1})
                end
                love.graphics.line(x1,y1,x2,y2)
            end
            self.items=new
            love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4] or 1)
        end
        local a
        a=BulletSpawner{x=400,y=300,period=3,frame=0,lifeFrame=10000,bulletNumber=16,bulletSpeed='30',bulletLifeFrame=10000,angle=-0.5,range=math.pi*2,bulletSprite=BulletSprites.dot.cyan,bulletEvents={
            function(cir)
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=60,
                    executeFunc=function()
                        cir.sprite=BulletSprites.rain.cyan
                        cir.direction=cir.direction+(cir.args.index%2==1 and 1 or -1)*0.4
                    end
                }
                -- Event.DelayEvent{
                --     obj=cir,
                --     delayFrame=120,
                --     executeFunc=function()
                --         cir.sprite=BulletSprites.bill.blue
                --         cir.direction=cir.direction+(cir.args.index%2==1 and 1 or -1)*-1
                --     end
                -- }
                Event.LoopEvent{
                    obj=cir,
                    period=1,
                    executeFunc=function()
                        if not cir.mark then
                            local polyline=Player.objects[1].border
                            local flag=true
                            if cir.x<150 then
                                cir.x=650
                                table.insert(greenLines.items,{150,cir.y,650,cir.y,5})
                            elseif cir.x>650 then
                                cir.x=150
                                table.insert(greenLines.items,{150,cir.y,650,cir.y,5})
                            elseif cir.y<0 then
                                cir.y=600
                                table.insert(greenLines.items,{cir.x,0,cir.x,600,5})
                            elseif cir.y>600 then
                                cir.y=0
                                table.insert(greenLines.items,{cir.x,0,cir.x,600,5})
                            -- below is for original polyline border
                            -- elseif not polyline:insideOne(cir.x,cir.y,1) then
                            --     local ny=Shape.lineX2Y(polyline.points[3].x,polyline.points[3].y,polyline.points[4].x,polyline.points[4].y,cir.x)
                            --     -- print(polyline.points[3].x,polyline.points[3].y,polyline.points[4].x,polyline.points[4].y,cir.x,ny)
                            --     table.insert(greenLines.items,{cir.x,cir.y,cir.x,ny,5})
                            --     cir.y=ny
                            -- elseif not polyline:insideOne(cir.x,cir.y,3) then
                            --     local ny=Shape.lineX2Y(polyline.points[1].x,polyline.points[1].y,polyline.points[2].x,polyline.points[2].y,cir.x)
                            --     table.insert(greenLines.items,{cir.x,cir.y,cir.x,ny,5})
                            --     cir.y=ny
                            else
                                flag=false
                            end
                            if flag then
                                cir.mark=true
                                cir.sprite=BulletSprites.rain.green
                            end
                        end
                        -- local vx=cir.speed*math.cos(cir.direction)
                        -- local vy=cir.speed*math.sin(cir.direction)
                        -- vx=vx+math.cos(a.angle)*0.05
                        -- vy=vy+math.sin(a.angle)*0.05
                        -- cir.speed=(vx*vx+vy*vy)^0.5
                        -- cir.direction=math.atan2(vy,vx)
                    end
                }
            end
        }}
        Event.LoopEvent{
            obj=a,
            period=1,
            executeFunc=function(self)
                local pe=1800
                local t=a.frame%(pe*2)
                if t==2 then
                    a.bulletNumber=12
                    a.bulletSpeed=20
                    a.range=math.pi*2
                end
                if t==180 then
                    a.bulletSpeed=30
                    a.bulletNumber=8
                    a.range=math.pi/2
                end
                if t<180 then
                    a.angle=a.angle+0.0033*(a.angle<1.57 and 1 or -1)
                elseif t>=180 and t<pe then
                    a.angle=a.angle+0.0007*(a.angle<1.57 and 1 or -1)
                elseif t>=pe and t<2*pe-180 then
                    a.angle=a.angle-0.0007*(a.angle<1.57 and 1 or -1)
                elseif t>=2*pe-180 then
                    a.angle=a.angle-0.0033*(a.angle<1.57 and 1 or -1)
                end
                if t%60==45 and t>150 then
                    a.spawnEvent.period=999
                elseif t%60==0 then
                    a.spawnEvent.period=3
                    a.spawnEvent.frame=0
                    a.angle=math.pi-a.angle
                end

            end
        }
    end
}