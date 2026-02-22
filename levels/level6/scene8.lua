return {
    ID=168,
    user='aya',
    spellName='', 
    unlock=function()
        return Nickname.hasSecretNicknameForAct(6)
    end,
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=2000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=3000,}
        en:addHPProtection(900,50)
        local player=Player{x=400,y=600}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local a
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,100,12))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local function calcVertices(cir,offset,radius)
            local vertices={}
            for i = 1, 4, 1 do
                local nx,ny=Shape.rThetaPos(cir.x,cir.y,radius,cir.direction+math.pi/2*(i-0.5)+offset*math.mod2Sign(i)) -- a rectangle
                table.insert(vertices,{nx,ny})
            end
            return vertices
        end
        local readyFrame=60
        local fadeFrame=20
        local function camDraw(cam)
            local originalMeshPoses=cam:getMeshPoses()
            PolyLine.drawMesh(cam,originalMeshPoses) -- original function to draw rectangle
            -- draw a cross at center
            local cir=cam.cir
            local vertices={}
            for i=1,4,1 do
                local distance=cam.size/100*30*math.min(cam.frame/readyFrame+0.2,1)*(i%2==0 and math.sin or math.cos)(cam.offset+math.pi/4)
                local farPointX,farPointY=Shape.rThetaPos(cir.x,cir.y,distance,cir.direction+math.pi/2*(i))
                table.insert(vertices,{x=farPointX,y=farPointY})
                table.insert(vertices,{x=cir.x,y=cir.y})
            end
            PolyLine.drawMesh(cam,PolyLine.getMeshPoses{points=vertices})
            -- fill whole area. first get outer points from original mesh (odd index), then add center point to form a fan mesh
            local areaColorRatio=0.05
            if cam.frame>=cam.shotFrame then
                areaColorRatio=math.clamp(1-(cam.frame-cam.shotFrame)/fadeFrame,0,1)
            end
            local r,g,b=1,1,1
            r,g,b=r*areaColorRatio,g*areaColorRatio,b*areaColorRatio
            local x,y,w,h=love.graphics.getQuadXYWHOnImage(BulletSprites.laser.white.quad,Asset.bulletImage)
            local areaVertices={{cir.x,cir.y,x+w/2,y+h/2,r,g,b,1}} -- center point
            for i=2,#originalMeshPoses,2 do
                table.insert(areaVertices,{originalMeshPoses[i][1],originalMeshPoses[i][2],x+w/2,y+h/2,r,g,b,1})
            end
            table.insert(areaVertices,{originalMeshPoses[2][1],originalMeshPoses[2][2],x+w/2,y+h/2,r,g,b,1}) -- connect last point to first point to form a closed area
            local mesh=love.graphics.newMesh(areaVertices,'fan')
            mesh:setTexture(Asset.bulletImage)
            Asset.laserMeshes:add(mesh)
        end
        local function camera(cir,offset,size,shotFrame,spawnFunc)
            local cam=PolyLine(calcVertices(cir,offset,2))
            cam.color={1,0.6,0.6}
            cam.sprite=BulletSprites.laser.red
            cam.cir,cam.size,cam.offset,cam.shotFrame=cir,size,offset,shotFrame
            cam.draw=camDraw
            cam.frame=0
            Event.LoopEvent{
                obj=cam,period=1,executeFunc=function()
                    if cir.removed then
                        cam:remove()
                        return
                    end
                    cam.frame=cam.frame+1
                    cam.spriteTransparency=math.clamp(1-(cam.frame-cam.shotFrame)/fadeFrame,0,1)
                    cam:replacePoints(calcVertices(cir,offset,size*math.min(cam.frame/readyFrame,1)))
                    if cam.frame==cam.shotFrame then
                        SFX:play('enemyShot',true)
                        -- if player inside camera area, do damage
                        if cam:inside(player.x,player.y) then
                            EventManager.post(EventManager.EVENTS.PLAYER_HIT,player,1)
                        end
                        cir.speed=0
                        if spawnFunc then
                            spawnFunc(cir)
                        end
                    end
                    if cam.frame>cam.shotFrame+fadeFrame then
                        cir:remove()
                        cam:remove()
                    end
                end
            }
        end
        -- cameras from enemy, each delaying a bit and rotating 4 cycles
        local function attack1()
            BulletSpawner{x=en.x,y=en.y,period=1,frame=0,lifeFrame=1,bulletNumber=24,bulletSpeed=100,bulletLifeFrame=500,angle='0+999',range=math.pi*8,bulletSprite=BulletSprites.round.red,invincible=true,bulletEvents={
                function(cir,args,self)
                    local index=args.index-1
                    local speedRef=cir.speed
                    cir.speed=0
                    cir.index=index
                    cir.safe=true
                    cir.spriteTransparency=0
                    if index>=12 then
                        cir.direction=cir.direction+math.pi/12
                    end
                    Event.DelayEvent{
                        obj=cir,delayFrame=index*2+math.floor(index/6)*15,executeFunc=function()
                            SFX:play('enemyShot',true)
                            cir.ready=true
                            cir.frame=0
                            cir.speed=speedRef
                            camera(cir,0.3,100,120)
                            Event.EaseEvent{
                                obj=cir,aimKey='speed',aimValue=cir.index%12>=6 and 65 or 10,easeFrame=30
                            }
                        end
                    }
                end},bulletExtraUpdate=function(cir)
                    if cir.ready and cir.frame==60 and cir.index%12>=6 then
                        Event.EaseEvent{
                            obj=cir,aimKey='direction',aimValue=cir.direction+math.pi/2*(cir.index>12 and -1 or 1),easeFrame=30
                        }
                    end
                end
            }
        end
        -- attack1()
        -- on line from enemy to player, spawn many cameras with increasing angle, and spawn bullets
        local function attack2()
            local points=Shape.segmentPoints(en.x,en.y,player.x,player.y,1,15)
            local dir0=Shape.toObj(en,player)
            local rotateDir=math.randomSign()
            for i,point in pairs(points) do
                local dir=dir0
                if i>1 then
                    dir=Shape.toObj(point,en)+math.pi
                end
                dir=dir+math.pi/(#points-1)*(i-1)*rotateDir
                local cir=Circle{x=point.x,y=point.y,direction=dir,speed=5,radius=1,safe=true,invincible=true,sprite=BulletSprites.round.red,spriteTransparency=0,lifeFrame=999}
                Event.DelayEvent{
                    obj=cir,delayFrame=i*5,executeFunc=function()
                        SFX:play('enemyShot',true)
                        camera(cir,-0.3,100,120,function(cir)
                            BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=12,bulletSpeed=100,bulletLifeFrame=500,angle=cir.direction,range=math.pi*6+rotateDir*0.3,bulletSprite=BulletSprites.scale.purple,highlight=true,bulletEvents={
                                function(cir,args,self)
                                    cir.speed=args.index*6+12
                                end
                            }}
                        end)
                    end
                }
            end
        end
        -- cameras towards player
        local function attack3()
            local angle0=math.eval(0,999)
            for i=1,24 do
                local x1,y1=Shape.rThetaPos(en.x,en.y,70+20*(i%3),angle0+math.pi/12*i)
                local dir=Shape.to(x1,y1,player.x,player.y)
                local cir=Circle{x=x1,y=y1,direction=dir,speed=0,radius=1,safe=true,invincible=true,sprite=BulletSprites.round.red,spriteTransparency=0,lifeFrame=999,extraUpdate=function(cir)
                    cir.direction=Shape.toObj(cir,player)
                end}
                Event.DelayEvent{
                    obj=cir,delayFrame=i*7%24*5,executeFunc=function()
                        SFX:play('enemyShot',true)
                        camera(cir,0.3,30,120,function(cir)
                            BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=12,bulletSpeed=100,bulletLifeFrame=500,angle=cir.direction,range=math.pi*0,bulletSprite=BulletSprites.scale.purple,highlight=true,bulletEvents={
                                function(cir,args,self)
                                    cir.speed=args.index*6+40
                                end
                            }}
                        end)
                    end
                }
            end
        end
        local attacks={attack1,attack2,attack3}
        Event.LoopEvent{
            obj=en,period=300,frame=240,executeFunc=function(self,times)
                attacks[times%3+1]()
            end
        }
    end
}