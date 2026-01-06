return {
    ID=131,
    user='ubame',
    spellName='Collapse "Sanctuary of Schwarz"',
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=1500
        local en=Enemy{x=400,y=200,mainEnemy=true,maxhp=6000}
        local player=Player{x=400,y=600,noBorder=true}
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        player.moveMode=Player.moveModes.Natural
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local p,q,r,v1,v2,v3
        local count=0
        local pqrs={{7,2,3},{3.5,3,3},{4,2,4.5}}
        local permutation={{1,2,3},{1,3,2},{2,1,3},{2,3,1},{3,1,2},{3,2,1}}
        Event.LoopEvent{
            period=1,
            obj=en,
            executeFunc=function()
                -- a.x,a.y=en.x,en.y--
                local hpp=en.hp/en.maxhp
                local t=(en.frame)%550
                if t>=50 and t<=100 and t%1==0 then
                    if t==50 then
                        local pqrsIndex=math.random(1,#pqrs)
                        local pqrs=pqrs[pqrsIndex]
                        local permIndex=math.random(1,#permutation)
                        local perm=permutation[permIndex]
                        p=pqrs[perm[1]]
                        q=pqrs[perm[2]]
                        r=pqrs[perm[3]]
                        center.x=math.eval(400,300)
                        center.y=math.eval(300,200)
                        v1,v2,v3=Shape.schwarzTriangleVertices(p,q,r,{center.x,center.y},math.eval(0,999))
                        count=0
                    end
                    local sfxplayed,sfxplayed2=false,false
                    local t0=t-50
                    local r0=120-t0*2.4
                    local num=math.min(math.ceil(math.sinh(r0/Shape.curvature)*80),100)
                    local thetaOffset=math.eval(0,0.1)
                    for idx = 1, num do
                        local nx,ny=Shape.rThetaPos(400,300,r0,idx*math.pi*2/num+thetaOffset)
                        local flipx,flipy,dO,flipCount=Shape.flipIntoTriangle(nx,ny,v1[1],v1[2],v2[1],v2[2],v3[1],v3[2])
                        local bx,by,bz=Shape.barycenterCoordinates(flipx,flipy,v1[1],v1[2],v2[1],v2[2],v3[1],v3[2])
                        local xs,ys,zs=bx<0.05,by<0.1,bz<0.1
                        if not (xs or ys or zs) then
                            goto continue
                        end
                        local colorIndex=(xs and 1 or ys and 2 or zs and 3 or 0) -- wont be 0
                        if xs and ys or ys and zs or zs and xs then
                            colorIndex=4
                        end
                        local colors={'red','orange','yellow','green','blue','cyan','purple','magenta'}
                        local color=colors[colorIndex]
                        local delay0=colorIndex*20-t0+50-r0/5
                        local toFlipCenterDir=Shape.to(flipx,flipy,center.x,center.y)
                        local toFlipCenterDistance=Shape.distance(flipx,flipy,center.x,center.y)
                        local finalDir=toFlipCenterDir-dO
                        if flipCount%2==1 then
                            finalDir=math.pi-finalDir
                        end
                        Event.DelayEvent{
                            delayFrame=delay0,
                            executeFunc=function()
                                count=count+1
                                if not sfxplayed then
                                    SFX:play('enemyShot',true,0.5)
                                    sfxplayed=true
                                end
                                local sx,sy=en.x+math.eval(0,10),en.y+math.eval(0,10)--,dir=Shape.rThetaPosT(en.x,en.y,r0/2+30,colorIndex)--
                                local cir=Circle{x=sx,y=sy,direction=finalDir,speed=0,sprite=BulletSprites['blackrice'][color],lifeFrame=500,
                                -- batch=Asset.bulletHighlightBatch,
                                radius=(1),extraUpdate=Circle.FadeOut}
                                local distance=Shape.distance(sx,sy,nx,ny)
                                Event.DelayEvent{
                                    delayFrame=1,
                                    executeFunc=function()
                                        Event.LoopEvent{
                                            obj=cir,period=1,times=150,executeFunc=function(self,time,maxTime)
                                                Shape.moveTowards(cir,{x=nx,y=ny},distance/77.85*0.99^time,true)
                                            end
                                        }
                                    end
                                }
                                Event.DelayEvent{
                                    delayFrame=-delay0+250-t0,
                                    executeFunc=function()
                                        if not sfxplayed2 then
                                            SFX:play('enemyPowerfulShot',true,0.5)
                                            sfxplayed2=true
                                        end
                                        cir.speed=toFlipCenterDistance*0.7
                                        Event.EaseEvent{
                                            obj=cir,easeFrame=300+math.mod2Sign(flipCount)*75,aimTable=cir,aimKey='speed',aimValue=-toFlipCenterDistance*0.7-10,
                                        }
                                    end
                                }
                                
                            end
                        }
                        ::continue::
                    end
                end
            end
        }
    end
}