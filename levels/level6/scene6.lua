return {
    quote='?',
    user='renko',
    spellName='Interference "Wavefront Mandala"', 
    make=function()
        G.levelRemainingFrame=5400
        G.levelIsTimeoutSpellcard=true
        Shape.removeDistance=100000
        local a,b
        local en
        en=Enemy{x=4000,y=300,mainEnemy=true,maxhp=96000000}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local poses={}
        for i = 1, 12, 1 do
            local nx,ny=Shape.rThetaPos(400,300,100,math.pi/6*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local ax,ay=Shape.rThetaPos(400,300,240,0)
        a=BulletSpawner{x=ax,y=ay,period=150000,frame=80,lifeFrame=10000,bulletNumber=48,bulletSpeed=50,bulletLifeFrame=350,angle=math.eval('0+360'),range=math.pi*2,bulletSprite=BulletSprites.scale.yellow}
        local bx,by=Shape.rThetaPos(400,300,240,math.pi)
        b=BulletSpawner{x=bx,y=by,period=150000,frame=80,lifeFrame=10000,bulletNumber=48,bulletSpeed=50,bulletLifeFrame=350,angle=math.eval('0+360'),range=math.pi*2,bulletSprite=BulletSprites.scale.yellow}
        
        local freq1,amp1,freq2,amp2=0.5,1,0.5,1
        freq2=freq2+math.eval('0+0.04')
        local time=0
        local thereshold=1
        local colorMix={0.7,0,0}
        local shader = love.graphics.newShader("shaders/waveBG.glsl")
        local bg=Shape{x=300,y=0,lifeFrame=99999}
        table.insert(G.sceneTempObjs,bg)
        bg.update=function(self)
        end
        bg.draw=function(self)
            -- note that, in this function followModeTransform and hyperbolic rotation are applied, so it's incorrect to calculate other positions except for those sending to the shader
            local translateX,translateY,scale=G:followModeTransform(true)
            local function translate(x,y)
                return x*scale+translateX,y*scale+translateY
            end
            local function antiTranslate(x,y)
                return (x-translateX)/scale,(y-translateY)/scale
            end
            local x1,y1=translate(a.x,a.y)
            shader:send("time", time)
            shader:send("thershold", thereshold)
            shader:send("colorMix", colorMix)
            shader:send("source1", {x1,y1})
            shader:send("frequency1", freq1)
            shader:send("amplitude1", amp1)
            local x2,y2=translate(b.x,b.y)
            shader:send("source2", {x2,y2})
            shader:send("frequency2", freq2)
            shader:send("amplitude2", amp2)

            shader:send("curvature", Shape.curvature)
            shader:send("axisY", Shape.axisY)
            love.graphics.setShader(shader)
            local recX,recY=antiTranslate(150,0)
            love.graphics.rectangle("fill", recX,recY, 500/scale, 600/scale)
            love.graphics.setShader()
        end
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                time=time+1/20
                local t=en.frame
                if t<60 then
                elseif t<180 then
                    thereshold=1-(t-60)/120*0.3
                elseif t<1800 then
                    thereshold=0.7-(t-180)/(1800-180)*0.1
                elseif t<1920 then -- rest for 2 seconds
                    if t==1800 then
                        SFX:play('enemyCharge',true)
                        Event.LoopEvent{
                            obj=en,
                            period=1,
                            times=100,
                            executeFunc=function()
                                colorMix[1]=colorMix[1]-0.007
                                colorMix[3]=colorMix[3]+0.007
                            end
                        }
                    end
                    thereshold=math.min(1,0.6+(t-1800)/40*0.4)
                elseif t<3600 then
                    thereshold=1-math.min(0.52,(t-1920)/120*0.52)+math.sin((t-1920)/90)*0.1
                elseif t<3720 then -- rest for 2 seconds
                    if t==3600 then
                        Event.LoopEvent{
                            obj=en,
                            period=1,
                            times=100,
                            executeFunc=function()
                                colorMix[3]=colorMix[3]-0.007
                                colorMix[2]=colorMix[2]+0.007
                            end
                        }
                        SFX:play('enemyCharge',true)
                    end
                    thereshold=thereshold*0.9+0.1
                else
                    thereshold=1-math.min(0.48,(t-3720)/120*0.48)+math.sin((t-3720)/90)*0.1
                end
                if t<1800 then
                    a.x,a.y=Shape.rThetaPos(400,300,210*(1-t/1800)+30,0)
                    b.x,b.y=Shape.rThetaPos(400,300,200*(1-t/1800)+40,math.pi)
                elseif t>3600 then
                    local tm=t-3600
                    a.x,a.y=Shape.rThetaPos(400,300,30,tm/230)
                    b.x,b.y=Shape.rThetaPos(400,300,40,math.pi+tm/255)
                end
                freq1=0.5+0.1*math.sin(t/200)

                -- should be strictly the same as the shader
                local dis1=Shape.distance(player.x,player.y,a.x,a.y)
                local dis2=Shape.distance(player.x,player.y,b.x,b.y)
                local phase1=dis1 * freq1 - time
                local phase2=dis2 * freq2 - time
                local sum=amp1 * math.sin(phase1) + amp2 * math.sin(phase2)
                sum = sum / (amp1 + amp2) * 0.5 + 0.5
                if sum>thereshold+0.01 then
                    player:hitEffect()
                end
            end
        }
    end
}