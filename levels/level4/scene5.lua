return {
    ID=145,
    user='urumi',
    spellName='Stone Sign "Boulder in Sanzu River"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=2500
        local en,a,b
        en=Enemy{x=400,y=100,mainEnemy=true,maxhp=7200}
        -- en:addHPProtection(300,10)
        local player=Player{x=400,y=600,noBorder=true}
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        player.moveMode=Player.moveModes.Natural
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local stones={}
        local flag=nil
        local shoot=function(self)
            local x0,y0=400,300
            local offset=math.eval(0,5)
            for r=-110,110,10 do
                r=r+offset
                local x1,y1,dir=Shape.rThetaPosT(x0,y0,r,0)
                dir=dir-math.pi/2
                local x2,y2,dir2=Shape.rThetaPosT(x1,y1,100,dir)
                local cir=Circle{x=x2,y=y2,lifeFrame=1000,sprite=Asset.bulletSprites.rice.blue,speed=30,direction=dir2+math.pi,spriteTransparency=0,highlight=true,extraUpdate={
                    function(cir)
                        if not cir.inside and player.border:inside(cir.x,cir.y) then
                            cir.inside=true
                            Event.EaseEvent{
                                obj=cir,aimKey='spriteTransparency',aimValue=1,easeFrame=30
                            }
                        end
                        if not cir.inside and not cir.exited and cir.frame>300 then -- missed the chance to enter, edge bullets
                            cir:remove()
                        end
                        if cir.inside and not cir.exited and not player.border:inside(cir.x,cir.y) then
                            cir.exited=true
                            Event.EaseEvent{
                                obj=cir,aimKey='spriteTransparency',aimValue=0,easeFrame=30,afterFunc=function()
                                    cir:remove()
                                end
                            }
                        end
                        if flag==0 then
                            Event.EaseEvent{
                                obj=cir,aimKey='speed',aimValue=0,easeFrame=20
                            }
                        end
                        cir.collideFrame=cir.collideFrame or 0
                        local mM=0.03
                        for i=1,#stones do
                            local stone=stones[i]
                            local rs=stone.radius
                            local dis=Shape.distance(cir.x,cir.y,stone.x,stone.y)
                            if cir.frame>20+cir.collideFrame and dis<rs+cir.radius then
                                cir.collideFrame=cir.frame
                                local dir=Shape.to(cir.x,cir.y,stone.x,stone.y)
                                local vct=cir.speed*math.cos(cir.direction-dir)
                                local vcn=cir.speed*math.sin(cir.direction-dir)
                                local vst=stone.speed*math.cos(stone.direction-dir)
                                local vsn=stone.speed*math.sin(stone.direction-dir)
                                vct,vst=(2-2*mM)*vst-(1-2*mM)*vct,(1-2*mM)*vst+(2*mM)*vct
                                cir.direction=dir+math.atan2(vcn,vct)
                                cir.speed=math.sqrt(vct^2+vcn^2)
                                if not flag then
                                    stone.direction=dir+math.atan2(vsn,vst)
                                    stone.speed=math.sqrt(vst^2+vsn^2)
                                end                                    
                            elseif flag and cir.frame>20+cir.collideFrame then
                                local dir=Shape.to(cir.x,cir.y,stone.x,stone.y)
                                local vct=cir.speed*math.cos(cir.direction-dir)
                                local vcn=cir.speed*math.sin(cir.direction-dir)
                                vct=vct+flag^3*dis/100
                                cir.direction=dir+math.atan2(vcn,vct)
                                cir.speed=math.sqrt(vct^2+vcn^2)
                            end
                        end
                    end
                }}
                
            end
        end
        Event.LoopEvent{
            obj=en,period=20,executeFunc=shoot
        }
        a=BulletSpawner{x=en.x,y=en.y,period=850,frame=800,lifeFrame=100000,bulletSpeed=0,bulletNumber=1,bulletLifeFrame=100000,angle='1.57+1',range=math.pi*2,highlight=true,bulletSprite=BulletSprites.lightRound.purple,bulletEvents={
            function(cir,args,self)
                cir.invincible=true
                cir.forceDrawLargeSprite=true
                local round=Circle{x=cir.x,y=cir.y,sprite=BulletSprites.bigRound['yellow'],lifeFrame=cir.lifeFrame}
                round.forceDrawLargeSprite=true
                local roundRadius=round.radius
                local radiusRef=cir.radius
                round.invincible=true
                Event.LoopEvent{
                    obj=round,period=1,conditionFunc=function(self)
                        if cir.removed then
                            round:remove()
                            return false
                        end
                        return true
                    end,
                    executeFunc=function(self)
                        round.x=cir.x
                        round.y=cir.y
                        round.radius=cir.radius/radiusRef*roundRadius
                        round.spriteTransparency=cir.spriteTransparency
                    end
                }
                Event.EaseEventBatch{
                    obj=cir,aimKeys={'radius','speed'},aimValues={roundRadius*15,80},easeFrames={200,200}
                }
                Event.DelayEvent{
                    obj=cir,delayFrame=600,executeFunc=function()
                        Event.EaseEventBatch{
                            obj=cir,aimKeys={'radius','speed'},aimValues={roundRadius*0.1,150},easeFrames={600,600}
                        }
                        Event.DelayEvent{
                            obj=cir,delayFrame=600,executeFunc=function()
                                cir:remove()
                                round:remove()
                            end
                        }
                    end
                }
                stones[#stones+1]=cir
            end
        },bulletExtraUpdate={
            function(cir)
                if not player.border:inside(cir.x,cir.y) then
                    player.border:reflection(cir)
                end
            end
        }}
        Event.LoopEvent{
            obj=en,period=1,executeFunc=function(self)
                local t=en.frame%850
                if #stones>0 then
                    for i=#stones,1,-1 do
                        local cir=stones[i]
                        if cir.removed then
                            table.remove(stones,i)
                        end
                        if t==450 then
                            Event.EaseEvent{
                                obj=cir,aimKey='speed',aimValue=0,easeFrame=200,progressFunc=function(x)return 1-(1-math.sin(x*math.pi))^3 end
                            }
                        end
                    end
                end
                if t==400 then
                    SFX:play('enemyCharge',true)
                elseif t==500 then
                    SFX:play('enemyPowerfulShot',true)
                elseif t==520 then
                    flag=0.01
                elseif t==590 then
                    flag=nil
                end
                if t>=400 and t<=500 then
                    flag=(t-400)/100
                end
                if t%5==2 and player.y<150 then
                    shoot()
                end
            end
        }
    end
}