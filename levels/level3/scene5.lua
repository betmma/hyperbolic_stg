return {
    quote='Keep my speed up, and catch the right time to cross tracks!',
    user='flandre',
    spellName='Taboo "Labyrinthine Trap"',
    make=function()
        -- this spellcard is to showcase hyperbolic circle has exponential growth of circumference. The outmost track provides much longer time than inner tracks before the barrier catches up. So the key is to spend most time in outer tracks, and when barrier is close, straightly cross into the center then go back to outer tracks on the other side, so that you earn half circumference of space. 
        G.levelRemainingFrame=5400
        Shape.removeDistance=1000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600}
        player.moveMode=player.moveModes.Natural
        player.border:remove()
        local poses={}
        for i = 1, 12, 1 do
            local nx,ny=Shape.rThetaPos(400,300,110,math.pi/6*(i-.5))
            table.insert(poses,{nx,ny})
        end
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local theta=0
        local angles={}
        local speeds={}
        local lastFrameSpeeds={}
        local rs={}
        local layer=5
        for i = 1, layer, 1 do
            table.insert(angles,math.eval(-1.57,1))
            local r=20*i+10
            table.insert(rs,r)
            table.insert(speeds,0.015/math.sinh((r+10)/100))
            table.insert(lastFrameSpeeds,0)
            -- local cir=Circle{x=400,y=300,direction=0,speed=0,sprite=BulletSprites.giant.red,invincible=true,lifeFrame=99999,radius=2,batch=Asset.bulletHighlightBatch}
            -- table.insert(circles,cir)
            local r2=r
        end
        local innerR=0
        Event.LoopEvent{
            period=1,
            obj=en,
            executeFunc=function()
                theta=Shape.to(400,300,player.x,player.y)
                local playerR=Shape.distance(400,300,player.x,player.y)
                local playerLayer=1
                for i = 1, layer-1, 1 do
                    if playerR>rs[i+1] then
                        angles[i]=angles[i]+lastFrameSpeeds[i]
                        playerLayer=playerLayer+1
                    else
                        local the2=math.modClamp(theta,angles[i],math.pi)
                        local angleRef=angles[i]
                        local speed=speeds[i]
                        -- if player.focusing then
                        --     speed=speed*player.focusFactor
                        -- end
                        angles[i]=math.clamp(the2,angles[i]-speed,angles[i]+speed)
                        lastFrameSpeeds[i]=angles[i]-angleRef
                    end
                    for r=rs[i],rs[i+1],2 do
                        local x,y=Shape.rThetaPos(400,300,r,angles[i])
                        local cir=Circle{x=x,y=y,direction=0,speed=0,sprite=BulletSprites.round[lastFrameSpeeds[i]>0 and 'red' or 'blue'],invincible=true,lifeFrame=5,radius=1,batch=Asset.bulletHighlightBatch,}
                        Event.EaseEvent{
                            obj=cir,aimTable=cir,aimKey='spriteTransparency',aimValue=0.2,easeFrame=5
                        }
                    end
                end
                for i = 1, layer, 1 do
                    local r2=rs[i]
                    local color='green'
                    if i==playerLayer or i==playerLayer+1 then
                        color=lastFrameSpeeds[playerLayer]>0 and 'red' or 'blue'
                    end 
                    BulletSpawner{x=400,y=300,period=1,frame=0,lifeFrame=2,bulletNumber=math.floor(50*math.sinh(r2/100)),bulletSpeed=0,bulletLifeFrame=1,angle=0,bulletSprite=BulletSprites.bigRound[color],
                    -- fogEffect=true,fogTime=120,
                    spawnCircleRadius=r2,invincible=true
                    }
                end
                local innerSpeed=0.4
                if playerR<rs[1] then
                    innerR=math.clamp(playerR,innerR-innerSpeed,math.min(rs[1],innerR+innerSpeed))
                else
                    innerR=math.clamp(innerR-innerSpeed/4,0,rs[1])
                end
                BulletSpawner{x=400,y=300,period=1,frame=0,lifeFrame=2,bulletNumber=math.floor(200*math.sinh(innerR/100)),bulletSpeed=0,bulletLifeFrame=1,angle=0,bulletSprite=BulletSprites.bigRound.green,
                -- fogEffect=true,fogTime=120,
                spawnCircleRadius=innerR,invincible=true
                }
            end
        }
    end
}