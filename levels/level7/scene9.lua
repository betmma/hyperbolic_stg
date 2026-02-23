return {
    ID=179,
    user='reisen&seija',
    spellName='"Binocular Rivalry"',
    unlock=function()
        return Nickname.hasSecretNicknameForAct(7)
    end,
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1500
        local a,b,c
        local en,en2
        local phases={}
        en=Enemy{x=100,y=300,mainEnemy=true,maxhp=6400,hpSegments={0.75,0.5,0.25},sprite=Asset.boss.reisen,hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,20)
            if a then
                a:remove()
            end
            if b then
                b:remove()
            end
            if c then
                c:remove()
            end
            phases[hpLevel+1]()
        end}
        en:addHPProtection(600,20)
        en2=Enemy{x=700,y=300,maxhp=6400,hpSegments=en.hpSegments,sprite=Asset.boss.seija,hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
        end}
        en2:bind(en)
        local player=Player{x=400,y=600}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,100,12))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local w,h=WINDOW_WIDTH,WINDOW_HEIGHT
        local bulletCanvasA=love.graphics.newCanvas(w,h)
        local bulletCanvasB=love.graphics.newCanvas(w,h)
        local bulletComposite=love.graphics.newCanvas(w,h)
        local overlapShader=love.graphics.newShader([[
            extern Image canvasB;

            vec4 effect(vec4 color, Image canvasA, vec2 texCoords, vec2 screenCoords)
            {
                vec4 a = Texel(canvasA, texCoords);
                vec4 b = Texel(canvasB, texCoords);
                float overlap = step(0.001, a.a) * step(0.001, b.a);
                float fade = mix(1.0, 0, overlap);
                vec4 combined = vec4(a.rgb + b.rgb, max(a.a, b.a));
                combined.rgb = clamp(combined.rgb, 0.0, 1.0);
                combined.a *= fade;
                return combined;
            }
        ]])
        local bulletBatchA=love.graphics.newSpriteBatch(Asset.bulletImage, 2000, 'stream')
        local bulletBatchB=love.graphics.newSpriteBatch(Asset.bulletImage, 2000, 'stream')
        local overlapBatch={}
        function overlapBatch:clear()
            bulletBatchA:clear()
            bulletBatchB:clear()
        end
        function overlapBatch:flush()
        end
        function overlapBatch:draw()
            local activeShader=love.graphics.getShader()
            local activeColor={love.graphics.getColor()}
            local activeBlendMode,activeAlphaMode=love.graphics.getBlendMode()
            local activeCanvas=love.graphics.getCanvas()
            love.graphics.setColor(1,1,1,1)
            love.graphics.setBlendMode('alpha')
            love.graphics.setCanvas(bulletCanvasA)
            love.graphics.clear(0,0,0,0)
            love.graphics.draw(bulletBatchA)
            love.graphics.setCanvas(bulletCanvasB)
            love.graphics.clear(0,0,0,0)
            love.graphics.draw(bulletBatchB)
            love.graphics.setCanvas(bulletComposite)
            love.graphics.clear(0,0,0,0)
            overlapShader:send("canvasB", bulletCanvasB)
            love.graphics.setShader(overlapShader)
            love.graphics.draw(bulletCanvasA,0,0)
            love.graphics.setShader()
            love.graphics.setCanvas(activeCanvas)
            love.graphics.draw(bulletComposite,0,0)
            love.graphics.setShader(activeShader)
            love.graphics.setBlendMode(activeBlendMode,activeAlphaMode)
            love.graphics.setColor(activeColor[1],activeColor[2],activeColor[3],activeColor[4])
        end
        local overlapBatchIndex
        for i,batch in ipairs(Asset.Batches) do
            if batch==Asset.bulletBatch then
                overlapBatchIndex=i
                break
            end
        end
        table.insert(Asset.Batches,overlapBatchIndex,overlapBatch)
        Asset.batchExtraActions[overlapBatch]={}
        EventManager.listenTo(EventManager.EVENTS.LEAVE_LEVEL,function()
            for i,batch in ipairs(Asset.Batches) do
                if batch==overlapBatch then
                    table.remove(Asset.Batches,i)
                    break
                end
            end
            Asset.batchExtraActions[overlapBatch]=nil
        end,EventManager.EVENTS.LEAVE_LEVEL)
        player.typeNearest={999,999}
        local nextTypeNearest={999,999}
        Event.LoopEvent{
            obj=player,period=1,executeFunc=function(self)
                player.typeNearest=nextTypeNearest
                nextTypeNearest={999,999} -- reset nearest distance every frame 
            end
        }
        local nearThreshold=6
        -- bullet should fade when two types of bullets cross and near player. for coding, the condition is: cir is near the player, and both values in player.typeNearest are less then nearThreshold. use double buffer to ensure every bullet see same player.typeNearest.
        local function checkHitPlayer(cir)
            if not cir.safe then 
                local dis=Shape.distance(player.x,player.y,cir.x,cir.y)
                local type=cir.type
                if nextTypeNearest[type]>dis then
                    nextTypeNearest[type]=dis
                end
                local doFade=player.typeNearest[1]<nearThreshold and player.typeNearest[2]<nearThreshold and dis<nearThreshold
                if doFade then
                    return
                end
                local radi=player.radius+cir.radius
                if dis<radi+player.radius*player.grazeRadiusFactor and not cir.grazed then
                    EventManager.post(EventManager.EVENTS.PLAYER_GRAZE,player,cir:grazeValue())
                    cir.grazed=true
                end
                if player.invincibleTime<=0 and dis<radi then
                    EventManager.post(EventManager.EVENTS.PLAYER_HIT,player,cir.damage or 1)
                end
            end
        end
        local overlapFadeBase=function(cir,type)
            cir.baseGrazeValue=0.5
            cir.type=type
            cir.checkHitPlayer=checkHitPlayer
        end
        local bulletSize=1.5
        phases[1]=function()
            a=BulletSpawner{x=100,y=300,period=1,frame=-30,lifeFrame=10000,bulletNumber=4,bulletSpeed=35,bulletLifeFrame=250,angle=math.eval(0,999),range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bullet.white,bulletSize=bulletSize,bulletBatch=bulletBatchA,bulletEvents={
                function (cir)
                    cir.spriteColor={1,0.7,0.7}
                    overlapFadeBase(cir,1)
                end
            }}
            b=BulletSpawner{x=700,y=300,period=1,frame=-30,lifeFrame=10000,bulletNumber=4,bulletSpeed=35,bulletLifeFrame=250,angle=math.eval(0,999),range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bullet.white,bulletSize=bulletSize,bulletBatch=bulletBatchB,bulletEvents={
                function (cir)
                    cir.spriteColor={0.7,1,1}
                    overlapFadeBase(cir,2)
                end
            }}
            local hpLevel=en:getHPLevel()
            Event.LoopEvent{
                obj=en,period=1,executeFunc=function(self)
                    if en:getHPLevel()~=hpLevel then
                        self:remove()
                    end
                    a.angle=a.angle+0.03*math.sin(en.frame/120)
                    b.angle=b.angle-0.032*math.sin(en.frame/177)
                end
            }
        end
        phases[2]=function()
            a=BulletSpawner{x=en.x,y=en.y,period=2,frame=-30,lifeFrame=10000,bulletNumber=4,bulletSpeed=50,bulletLifeFrame=300,angle=Shape.toObj(en,player),range=math.pi*0.4,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bullet.white,bulletSize=bulletSize,bulletBatch=bulletBatchA,bulletEvents={
                function (cir)
                    cir.spriteColor={1,1,0.7}
                    overlapFadeBase(cir,1)
                end
            }}
            b=BulletSpawner{x=en.x,y=en.y,period=100,frame=-20,lifeFrame=10000,bulletNumber=400,bulletSpeed=40,bulletLifeFrame=300,angle=math.eval(0,999),range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bullet.white,bulletSize=bulletSize,bulletBatch=bulletBatchB,bulletEvents={
                function (cir,args)
                    cir.speed=cir.speed+args.index%2*1
                    cir.spriteColor={0.7,0.7,1}
                    overlapFadeBase(cir,2)
                end
            }}
            c=BulletSpawner{x=en.x,y=en.y,period=100,frame=10,lifeFrame=10000,bulletNumber=60,bulletSpeed=20,bulletLifeFrame=600,angle='0+999',range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bullet.white,bulletSize=bulletSize,bulletBatch=bulletBatchB,bulletEvents={
                function (cir,args)
                    cir.speed=cir.speed+args.index%3*10
                    cir.spriteColor={0.7,0.7,1}
                    overlapFadeBase(cir,2)
                end
            }}
            local hpLevel=en:getHPLevel()
            Event.LoopEvent{
                obj=en,period=1,executeFunc=function(self,times)
                    if en:getHPLevel()~=hpLevel then
                        self:remove()
                    end
                    Shape.moveTowards(en,center,0.01,true,true)
                    b.x,b.y=en.x,en.y
                    c.x,c.y=en.x,en.y
                    local r=math.min(30,times/5)+20*math.sin(times/97)
                    local angle=times/100
                    local aimx,aimy=Shape.rThetaPos(400,300,r,angle)
                    Shape.moveTowards(en2,{x=aimx,y=aimy},0.02,true,true)
                    a.x,a.y=en2.x,en2.y
                    if times%10==0 then
                        a.angle=Shape.toObj(a,player)
                    end
                end
            }
        end
        local function update(cir)
            cir.x,cir.y,cir.direction=Shape.rThetaPosT(player.x,player.y,50*(1-cir.frame/cir.lifeFrame)^0.5,cir.angle+player.naturalDirection)
            cir.direction=cir.direction+math.pi
        end
        phases[3]=function()
            a=BulletSpawner{x=en.x,y=en.y,period=50,frame=0,lifeFrame=10000,bulletNumber=60,bulletSpeed=20,bulletLifeFrame=600,angle='0+999',range=math.pi*6,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bullet.white,bulletSize=bulletSize,bulletBatch=bulletBatchA,bulletEvents={
                function (cir,args)
                    cir.speed=cir.speed+args.index%3*10
                    cir.spriteColor={1,0.7,1}
                    overlapFadeBase(cir,1)
                end
            }}
            b=BulletSpawner{x=en.x,y=en.y,period=100,frame=10,lifeFrame=10000,bulletNumber=40,bulletSpeed=10,bulletLifeFrame=200,angle=math.pi,spawnCircleRadius=50,spawnCircleAngle='0+999',range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bullet.white,bulletSize=bulletSize,bulletBatch=bulletBatchB,bulletEvents={
                function (cir,args,self)
                    if self.spawnEvent.executedTimes%5~=4 then
                        self.spawnEvent.period=10
                        self.spawnEvent.frame=0
                    else
                        self.spawnEvent.period=100
                    end
                    cir.spriteColor={0.7,1,0.7}
                    local angle=Shape.toObj(player,cir)
                    cir.angle=angle
                    overlapFadeBase(cir,2)
                    cir.baseGrazeValue=0.1
                end
            },bulletExtraUpdate={
                update
            }}
            local hpLevel=en:getHPLevel()
            Event.LoopEvent{
                obj=en,period=1,executeFunc=function(self,times)
                    if en:getHPLevel()~=hpLevel then
                        self:remove()
                    end
                    b.x,b.y=player.x,player.y
                end
            }
        end
        phases[4]=function()
            local hpLevel=en:getHPLevel()
            local function f1(cir,args)
                cir.spriteColor={1,0.7,1}
                overlapFadeBase(cir,1)
            end
            local function f2(cir,args)
                cir.spriteColor={0.7,1,0.7}
                overlapFadeBase(cir,2)
            end
            local function getBulletEvent(index)
                local function event(cir,args)
                    cir.spriteTransparency=0
                    cir.invincible=true
                    cir.safe=true
                    local spawner=BulletSpawner{x=cir.x,y=cir.y,period=2,frame=0,lifeFrame=cir.lifeFrame,bulletNumber=1,bulletSpeed=30,bulletLifeFrame=300,angle=0,range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bullet.white,bulletSize=bulletSize,bulletBatch=index==1 and bulletBatchA or bulletBatchB,bulletEvents={index==1 and f1 or f2}}
                    Event.LoopEvent{
                        obj=cir,period=1,executeFunc=function(self,times)
                            spawner.x,spawner.y=cir.x,cir.y
                            spawner.angle=cir.direction-math.pi/2*math.mod2Sign(args.index)
                        end
                    }
                end
                return event
            end
            local args={x=en.x,y=en.y,period=60,frame=0,lifeFrame=10000,bulletNumber=2,bulletSpeed=80,bulletLifeFrame=100,angle=0,range=math.pi*2,spawnSFXVolume=0.5,bulletSprite=BulletSprites.bullet.white,bulletSize=bulletSize,bulletEvents={getBulletEvent(1)}}
            a=BulletSpawner(args)
            args.frame=30
            args.bulletEvents={getBulletEvent(2)}
            b=BulletSpawner(args)
            local angle=0
            Event.LoopEvent{
                obj=en,period=1,executeFunc=function(self,times)
                    if en:getHPLevel()~=hpLevel then
                        self:remove()
                    end
                    local r=70+math.min(50,times/5)+20*math.sin(times/97)
                    angle=angle+0.03*math.sin(times/120)
                    local aimx,aimy=Shape.rThetaPos(400,300,r,angle)
                    Shape.moveTowards(en,{x=aimx,y=aimy},0.02,true,true)
                    aimx,aimy=Shape.rThetaPos(400,300,r,angle+math.pi)
                    Shape.moveTowards(en2,{x=aimx,y=aimy},0.02,true,true)
                    a.x,a.y=en.x,en.y
                    b.x,b.y=en2.x,en2.y
                    a.angle=Shape.toObj(a,player)
                    b.angle=Shape.toObj(b,player)
                end
            }
        end
        phases[1]()
    end
}