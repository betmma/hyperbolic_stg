return {
    ID=79,
    user='mystia',
    spellName='Night Sparrow "Staccato Melody"',
    make=function()
        -- G.UseHypRotShader=false
        G.levelRemainingFrame=7200
        G.backgroundPattern:remove()
        -- G.backgroundPattern=BackgroundPattern.Empty()
        Shape.removeDistance=1e100
        local a,b,c
        local en
        en=Enemy{x=400,y=600000,mainEnemy=true,maxhp=7200}
        -- en:addHPProtection(600,10)
        local player=Player{x=400,y=1200000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=600000}
        local poses={}
        local borderVertices=30
        for i = 1, borderVertices, 1 do
            local nx,ny=Shape.rThetaPos(center.x,center.y,700,math.pi/borderVertices*2*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local offset=0
        local angleD=0.1

        b=BulletSpawner{x=400,y=600000,period=300,frame=200,lifeFrame=10000,bulletNumber=6,bulletSpeed=60,bulletLifeFrame=340,angle='player',range=0,bulletSprite=BulletSprites.bigRound.cyan,bulletEvents={
            function(cir,args,self)
                cir.safe=true
                cir.invincible=true
                cir.direction=cir.direction+math.eval(0,angleD*10)
                local sub=BulletSpawner{x=cir.x,y=cir.y,period=20,frame=math.random(0,19),lifeFrame=300,bulletNumber=1,bulletSpeed=0,bulletLifeFrame=500,angle='0+999',range=math.pi*2,bulletSprite=BulletSprites.bigRound.cyan,fogEffect=true,fogTime=60,bulletEvents={
                    function(cir,args,self)
                        Event.DelayEvent{
                            obj=cir,delayFrame=20,executeFunc=function()
                                cir:changeSpriteColor('blue')
                                Event.EaseEvent{
                                    obj=cir,easeFrame=100,aimTable=cir,aimKey='speed',aimValue=50
                                }
                            end
                        }
                    end
                }}
                Event.LoopEvent{
                    obj=sub,period=1,executeFunc=function()
                        sub.x,sub.y=cir.x,cir.y
                    end
                }
            end
        }}

        c=BulletSpawner{x=400,y=600000,period=300,frame=50,lifeFrame=10000,bulletNumber=4,bulletSpeed=120,bulletLifeFrame=650,angle='player',range=0,bulletSprite=BulletSprites.round.green,bulletEvents={
            function(cir,args,self)
                cir.speed=cir.speed-args.index*16
                Event.EaseEvent{
                    obj=cir,easeFrame=50,aimTable=cir,aimKey='speed',aimValue=0
                }
                Event.DelayEvent{
                    obj=cir,delayFrame=80,executeFunc=function()
                        Event.EaseEvent{
                            obj=cir,easeFrame=40,aimTable=cir,aimKey='speed',aimValue=60
                        }
                    end
                }
            end
        }}
        local spawnBatchFuncRef=c.spawnBatchFunc
        c.spawnBatchFunc=function (self)
            local angle=Shape.to(c.x,c.y,player.x,player.y)
            offset=math.eval(0,1)
            local distance=Shape.distance(en.x,en.y,player.x,player.y)
            angleD=0.05/math.max(0.5,math.sinh(distance/Shape.curvature)*3)
            Event.LoopEvent{
                obj=c,period=5,times=5,executeFunc=function()
                    SFX:play('enemyShot',true,0.7)
                end
            }
            local moveDirection=angle+math.eval(math.pi/2,0.4)*math.randomSign()
            local num=35
            for i=-num,num,1 do
                Event.DelayEvent{
                    obj=c,delayFrame=(i+num),executeFunc=function()
                        en.x,en.y=Shape.rThetaPos(en.x,en.y,0.5,moveDirection)
                        angle=Shape.to(c.x,c.y,player.x,player.y)
                        c.angle=angle+angleD*(i+math.ceil(i/3)*2+offset)
                        spawnBatchFuncRef(c)
                    end
                }
            end
        end

        local shader = ShaderScan:load_shader("shaders/light.glsl")
        local playerLightIntensity=1
        local afterDraw=function(self)
            local translateX,translateY,scale=G:followModeTransform(true)
            local function translate(x,y)
                return x*scale+translateX,y*scale+translateY
            end
            local lightPositions={}
            local lightColors={}
            local lightIntensities={}
            local enx,eny=translate(en.x,en.y)
            table.insert(lightPositions,{enx,eny})
            table.insert(lightColors,{1,1,1})
            table.insert(lightIntensities,-1)
            local playerX,playerY=translate(player.x,player.y)
            table.insert(lightPositions,{playerX,playerY})
            table.insert(lightColors,{1,1,1})
            table.insert(lightIntensities,playerLightIntensity)
            shader:send("numLights", #lightPositions)
            if #lightPositions>0 then
                shader:send("lightPositions",unpack(lightPositions))
                shader:send("lightColors",unpack(lightColors))
                shader:send("lightIntensities",unpack(lightIntensities))
            end
            shader:send("backgroundLightIntensity", math.min(1,1.5-en.frame/120))

            shader:send("player_pos", {player.x, player.y})
            shader:send("aim_pos", {WINDOW_WIDTH/2+G.viewMode.viewOffset.x, WINDOW_HEIGHT/2+G.viewMode.viewOffset.y})
            shader:send("rotation_angle",-player.naturalDirection)
            shader:send("hyperbolic_model", G.viewMode.hyperbolicModel)
            shader:send("r_factor", G.DISK_RADIUS_BASE[G.viewMode.hyperbolicModel] or 1)
            love.graphics.setShader(shader)
            local recX,recY=0,0
            love.graphics.setBlendMode("multiply","premultiplied")
            love.graphics.rectangle("fill", recX,recY, WINDOW_WIDTH, WINDOW_HEIGHT)
            love.graphics.setBlendMode("alpha")
            love.graphics.setShader()
        end
        Asset.batchExtraActions[Asset.playerFocusBatch].after=afterDraw
        local playerx,playery=player.x,player.y
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                -- a.x,a.y=en.x,en.y
                if en.frame==60 then
                    SFX:play('enemyCharge')
                end
                if player.x~=playerx or player.y~=playery then
                    playerx,playery=player.x,player.y
                    playerLightIntensity=playerLightIntensity*0.95
                else
                    playerLightIntensity=playerLightIntensity*0.95+1*0.05
                end
                b.x,b.y=en.x,en.y
                c.x,c.y=en.x,en.y
            end
        }
    end,
    leave=function()
        Asset.batchExtraActions[Asset.playerFocusBatch].after=nil
    end
}