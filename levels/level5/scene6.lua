return {
    ID=32,
    quote='Yuugi\'s classic three steps become unpredictable here. She is truly drunken.',
    user='yuugi',
    spellName='Big Four Arcanum "Knock Out In Three Sides"',
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=2500
        local en=Enemy{x=400,y=150,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600,noBorder=true}
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        player.moveMode=Player.moveModes.Natural
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local center,radius,thetas,vertices,outvertices,polyline,outpolyline
        Event.LoopEvent{
            period=1,
            obj=en,
            executeFunc=function()
                -- a.x,a.y=en.x,en.y--
                local hpp=en.hp/en.maxhp
                local t=(en.frame-100)%480
                if t==0 then
                    center={x=math.eval(400,50),y=math.eval(300,50)}
                    
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='x',
                        aimValue=center.x,
                        easeFrame=60,
                        progressFunc=Event.sineIOProgressFunc
                    }
                    Event.EaseEvent{
                        obj=en,
                        aimTable=en,
                        aimKey='y',
                        aimValue=center.y,
                        easeFrame=60,
                        progressFunc=Event.sineIOProgressFunc
                    }
                    radius=math.eval(60,20)
                    thetas={math.eval(0,3)}
                    table.insert(thetas,thetas[1]+math.pi*2/3+math.eval(0,0.5))
                    table.insert(thetas,thetas[2]+math.pi*2/3+math.eval(0,0.5))
                    vertices={}
                    outvertices={}
                    for i = 1, 3 do
                        local x,y=Shape.rThetaPos(center.x,center.y,radius-7,thetas[i])
                        local xo,yo=Shape.rThetaPos(center.x,center.y,radius+7,thetas[i])
                        table.insert(vertices,{x,y})
                        table.insert(outvertices,{xo,yo})
                        local fog=Circle({x=x, y=y, radius=1, lifeFrame=60, sprite=Asset.bulletSprites.fog.gray,safe=true})
                        Event.EaseEvent{
                            obj=fog,
                            easeFrame=60,
                            aimTable=fog,
                            aimKey='spriteTransparency',
                            aimValue=0,
                            -- period=60,
                            afterFunc=function()
                                SFX:play('enemyShot',true,1)
                                local cir=Circle{x=x,y=y,direction=0,speed=0,sprite=BulletSprites.round.red,lifeFrame=400,invincible=true}
                                for j=1,30 do
                                    Circle{x=x,y=y,direction=j*math.pi/15+thetas[i],speed=15,sprite=BulletSprites.rim.red,lifeFrame=800}
                                end
                            end
                        }
                    end
                    if polyline then
                        polyline:remove()
                    end
                    polyline=PolyLine(vertices,false)
                    if outpolyline then
                        outpolyline:remove()
                    end
                    outpolyline=PolyLine(outvertices,false)
                elseif t==130 then
                    local xoff=math.eval(0,0.1)
                    local count=0
                    local sfxplayed,sfxplayed2=false,false
                    for r0 = 0, 100, 5 do
                        local num=math.min(math.ceil(math.sinh(r0/Shape.curvature)*120),100)
                        local thetaOffset=math.eval(0,0.1)
                        for idx = 1, num do
                            count=count+1
                            local nx,ny=Shape.rThetaPos(en.x,en.y,r0,idx*math.pi*2/num+thetaOffset)
                            local inarea=polyline:inside(nx,ny)
                            local outarea=not outpolyline:inside(nx,ny)
                            if not inarea and not outarea then
                                goto continue
                            end
                            local delay0=Shape.distance(center.x,center.y,nx,ny)*(inarea and 1.1 or 0.1)
                            Event.DelayEvent{
                                delayFrame=delay0+(inarea and 0 or 80),
                                executeFunc=function()
                                    if not sfxplayed then
                                        SFX:play('enemyShot',true,1)
                                        sfxplayed=true
                                    end
                                    local cir=Circle{x=nx,y=ny,direction=Shape.to(center.x,center.y,nx,ny)+(inarea and math.pi or 0),speed=0,sprite=inarea and BulletSprites.bigRound.red or BulletSprites.giant.red,lifeFrame=800,batch=Asset.bulletHighlightBatch,radius=(inarea and 1 or 1+r0/100)}
                                    Event.DelayEvent{
                                        delayFrame=-delay0+80+(inarea and 0 or 30),
                                        executeFunc=function()
                                            
                                    if not sfxplayed2 then
                                        SFX:play('enemyShot',true,1)
                                        sfxplayed2=true
                                    end
                                            if inarea then
                                                cir.speed=15
                                            end
                                            Event.EaseEvent{
                                                obj=cir,easeFrame=100,aimTable=cir,aimKey='speed',aimValue=inarea and 30 or 60,
                                            }
                                        end
                                    }
                                    
                                end
                            }
                            ::continue::
                        end
                    end
                end
            end
        }
    end
}