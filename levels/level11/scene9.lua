return {
    ID=124,
    user='flandre',
    spellName='Taboo "Devil\'s Nutcracker"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local en,createGiants
        en=Enemy{x=400,y=300000,mainEnemy=true,maxhp=9600,hpSegments={0.7,0.3},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel,{bullet=true})
            en:addHPProtection(600,10)
            if hpLevel==1 then
                createGiants(18,300,48,'blue',480,-0.04,60)
            elseif hpLevel==2 then
                createGiants(6,80,8,'green',720,0.01)
            end
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300000}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local smashNumTable={{2,3,4},{2,2,2},{6,6,6}} -- [i][j] means how many giants of ith ring in jth spellcard phase will smash. values where j<i are useless but needed to fill the table
        createGiants=function(number,radius,giantRadius,color,period,rotateSpeedBase,prepFrame)
            number=number or 12
            radius=radius or 150
            giantRadius=giantRadius or 24
            color=color or 'red'
            period=period or 330
            local prepFrame,moveFrame=prepFrame or 30,150
            local giants={}
            local args={rotateSpeedBase=rotateSpeedBase or 0.04} -- able to call EaseEvent on rotateSpeedBase
            local function giantUpdate(cir)
                if cir.frame<60 then
                    cir.radius=cir.radius+giantRadius/60
                else
                    cir.safe=false
                end
                cir.x,cir.y=Shape.rThetaPos(center.x,center.y,cir.r,cir.angle)
                local rotateSpeed=args.rotateSpeedBase*(math.sin(cir.frame/230)*0.3+0.7)
                cir.angle=cir.angle+rotateSpeed
                cir.direction=cir.direction+rotateSpeed*10
            end
            local angle0=math.eval(0,999)
            for i=1,number do
                local angle=angle0+i*2*math.pi/number
                local x0,y0=Shape.rThetaPos(center.x,center.y,radius,angle)
                local cir=Circle{x=x0,y=y0,radius=0,speed=0,direction=0,lifeFrame=100000,invincible=true,sprite=BulletSprites.giant[color],extraUpdate={giantUpdate}}
                cir.r=radius
                cir.angle=angle
                cir.safe=true
                cir.forceDrawLargeSprite=true
                cir.spriteColor={1,1,1}
                table.insert(giants,cir)
            end
            local initHPLevel=en:getHPLevel()
            local function smash()
                SFX:play('enemyCharge',true)
                local smashID=math.random(1,#giants)
                -- stop rotating
                local rotateSpeedRef=args.rotateSpeedBase
                Event.EaseEvent{
                    obj=args,aimKey='rotateSpeedBase',aimValue=0,easeFrame=prepFrame*2,
                }
                Event.DelayEvent{
                    obj=args,delayFrame=moveFrame,executeFunc=function()
                        Event.EaseEvent{
                            obj=args,aimKey='rotateSpeedBase',aimValue=rotateSpeedRef,easeFrame=prepFrame*2,
                        }
                    end
                }
                local smashNum=smashNumTable[initHPLevel][en:getHPLevel()]
                local step=math.floor(#giants/smashNum)
                for i=1,smashNum do
                    local cir=giants[(i*step+smashID)%#giants+1]
                    -- turn red to warn
                    Event.EaseEventBatch{
                        obj=cir.spriteColor,
                        aimKeys={2,3},
                        aimValues={0.5,0.5},
                        easeFrames={prepFrame,prepFrame}
                    }
                    Event.DelayEvent{
                        obj=cir,delayFrame=prepFrame,executeFunc=function()
                            -- a pair move towards center to smash and then move back to original position
                            Event.EaseEvent{
                                obj=cir,aimKey='r',aimValue=cir.radius,easeFrame=moveFrame,progressFunc=function(x)
                                    return (1-math.abs(2*x-1))^3
                                end,
                                afterFunc=function()
                                    Event.EaseEventBatch{
                                        obj=cir.spriteColor,
                                        aimKeys={2,3},
                                        aimValues={1,1},
                                        easeFrames={prepFrame,prepFrame}
                                    }
                                end
                            }
                        end
                    }
                end
                -- when smash happens
                Event.DelayEvent{
                    obj=en,delayFrame=prepFrame+moveFrame/2,executeFunc=function()
                        SFX:play('enemyPowerfulShot',true)
                        -- spawn bullets
                        BulletSpawner{x=center.x,y=center.y,period=1,lifeFrame=2,times=1,bulletNumber=120,bulletSpeed=15,bulletLifeFrame=1200,angle='0+999',range=math.pi*30.1,bulletSprite=BulletSprites.flame[color],bulletSize=4,highlight=true,bulletEvents={
                            function(cir,args)
                                cir.speed=cir.speed-math.abs(math.floor((args.index-1)/8-7))*1
                                cir.r0=cir.radius
                                cir.shrinkSpeed=cir.speed/2000
                            end
                        },bulletExtraUpdate=function(cir)
                            cir.radius=cir.r0/4*cir.shrinkSpeed+cir.radius*(1-cir.shrinkSpeed)
                        end}
                    end
                }
            end
            Event.LoopEvent{
                obj=en,period=period,executeFunc=smash,frame=period-30
            }
        end
        createGiants()
    end
}