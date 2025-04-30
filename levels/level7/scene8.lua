return {
    ID=78,
    user='mystia',
    spellName='?',
    make=function()
        G.levelRemainingFrame=7200
        G.backgroundPattern:remove()
        G.backgroundPattern=BackgroundPattern.Empty()
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
        local lightSources={}
        a=BulletSpawner{x=400,y=600000,period=170,frame=90,lifeFrame=10000,bulletNumber=1,bulletSpeed=30,spawnSFXVolume=0.7,bulletLifeFrame=1000,angle=math.eval(0,999),range=math.pi*2,bulletSprite=BulletSprites.butterfly.yellow,bulletEvents={
            function(cir,args,self)
                a.angle=a.angle+math.eval(0,1)
                lightSources[#lightSources+1]=cir
            end
        }}

        b=BulletSpawner{x=400,y=600000,period=300,frame=200,lifeFrame=10000,bulletNumber=6,bulletSpeed=30,bulletLifeFrame=350,angle=0,range=math.pi*2,bulletSprite=BulletSprites.bigRound.yellow,bulletEvents={
            function(cir,args,self)
                Event.LoopEvent{
                    obj=cir,period=1,times=100,executeFunc=function()
                        cir.direction=cir.direction+math.mod2Sign(args.index)*0.02
                    end
                }
                Event.LoopEvent{
                    obj=cir,period=math.max(10,20-b.spawnEvent.executedTimes),executeFunc=function()
                        BulletSpawner{x=cir.x,y=cir.y,period=1,frame=0,lifeFrame=2,bulletNumber=2,bulletSpeed=0,bulletLifeFrame=300,angle=cir.direction,range=math.pi*2,bulletSprite=BulletSprites.scale.yellow,bulletEvents={
                            function(cir,args,self)
                                Event.EaseEvent{
                                    obj=cir,easeFrame=100,aimTable=cir,aimKey='speed',aimValue=50
                                }
                            end
                        }}
                    end
                }
                -- cir.speed=cir.speed+math.eval(0,20)
            end
        }}

        local offset=0
        local angleD=0.1
        c=BulletSpawner{x=400,y=600000,period=300,frame=50,lifeFrame=10000,bulletNumber=92,bulletSpeed=20,bulletLifeFrame=650,angle='player',range=0,bulletSprite=BulletSprites.round.green,bulletEvents={
            function(cir,args,self)
                if args.index==1 then
                    offset=math.eval(0,0.05)
                    local distance=Shape.distance(en.x,en.y,player.x,player.y)
                    angleD=0.2/math.max(0.5,math.sinh(distance/Shape.curvature)*3)
                    Event.LoopEvent{
                        obj=cir,period=5,times=5,executeFunc=function()
                            SFX:play('enemyShot',true,0.7)
                        end
                    }
                end
                cir.direction=cir.direction+offset+(math.ceil(args.index/4)-12)*angleD
                Event.EaseEvent{
                    obj=cir,easeFrame=(args.index%4)*15+math.ceil(args.index/4)*5,aimTable=cir,aimKey='speed',aimValue=80
                }
            end
        }}

        local shader = love.graphics.newShader("shaders/light.glsl")
        local bg=Shape{x=300,y=0,lifeFrame=99999}
        table.insert(G.sceneTempObjs,bg)
        bg.update=function(self)
        end
        local image=Asset.backgroundImage
        local MAX_LIGHT=16
        bg.draw=function(self)
            local translateX,translateY,scale=G:followModeTransform(true)
            local function translate(x,y)
                return x*scale+translateX,y*scale+translateY
            end
            local function antiTranslate(x,y)
                return (x-translateX)/scale,(y-translateY)/scale
            end
            local filteredLightSources={}
            local lightPositions={}
            local lightColors={}
            local lightIntensities={}
            local enx,eny=translate(en.x,en.y)
            table.insert(lightPositions,{enx,eny})
            table.insert(lightColors,{1,1,1})
            table.insert(lightIntensities,-1)
            for i=1,#lightSources do
                local cir=lightSources[i]
                if not cir.removed then
                    filteredLightSources[#filteredLightSources+1]=cir
                    if #lightPositions>=MAX_LIGHT then
                        break
                    end
                    local x,y=translate(cir.x,cir.y)
                    table.insert(lightPositions,{x,y})
                    table.insert(lightColors,{1,1,1})
                    local lifetimeLeftRatio=(cir.lifeFrame-cir.frame)/cir.lifeFrame
                    local initialLightup=(cir.frame/cir.lifeFrame)*10
                    local lightIntensity=math.min(lifetimeLeftRatio,initialLightup)
                    table.insert(lightIntensities,lightIntensity)
                end
            end
            -- fill the lightPositions, lightColors and lightIntensities to MAX_LIGHT
            -- for i=#lightPositions+1,MAX_LIGHT do
            --     lightPositions[i]={0,0}
            --     lightColors[i]={0,0,0}
            --     lightIntensities[i]=0
            -- end
            shader:send("numLights", #lightPositions)
            if #lightPositions>0 then
                shader:send("lightPositions",unpack(lightPositions))
                shader:send("lightColors",unpack(lightColors))
                shader:send("lightIntensities",unpack(lightIntensities))
            end
            shader:send("backgroundLightIntensity", math.min(1,1.5-en.frame/120))

            love.graphics.setShader(shader)
        end

        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                -- a.x,a.y=en.x,en.y
                if en.frame==60 then
                    SFX:play('enemyCharge')
                end
            end
        }
    end
}