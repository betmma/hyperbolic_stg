return {
    ID=101,
    quote='Music Sign "Sly Musical Score"',
    user='benben',
    dialogue='bossDialogue12_1',
    spellName='', 
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local en
        en=Enemy{x=400,y=300000,mainEnemy=true,maxhp=14400,hpSegments={0.8,0.6,0.4,0.2},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
            en.frame=0
        end}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300000}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,700,30))
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local hpp,hpLevel=1,1
        local function runningNote(noteType,centerUnit,moveMode)
            moveMode=moveMode or 'sawtooth'
            local note=Circle{x=centerUnit.x,y=centerUnit.y,lifeFrame=centerUnit.lifeFrame,speed=0,sprite=Asset.bulletSprites[noteType][centerUnit.sprite.data.color],radius=1.5,highlight=true}
            note.extraUpdate[1]=function(self)
                local t=self.fixedTime or self.frame
                if noteType=='rest' and centerUnit.triggered then
                    self.fixedTime=t
                end
                local period=600
                local val
                if moveMode=='sawtooth' then
                    val=(t%period)/period
                elseif moveMode=='triangle' then
                    val=math.abs(t%period-period/2)/period*2
                end
                local x,y,dir=Shape.rThetaPosT(centerUnit.x,centerUnit.y,val*280-140,centerUnit.direction-math.pi/2)
                self.x,self.y,self.direction=x,y,dir-math.pi/2
            end
            local x,y,dir=Shape.rThetaPosT(centerUnit.x,centerUnit.y,-140,centerUnit.direction-math.pi/2)
            note.x,note.y,note.direction=x,y,dir-math.pi/2
        end
        local angle=0
        local function noteGroup(times,noteType,centerUnit,play)
            for i=1,#times do
                local t=times[i]
                Event.DelayEvent{
                    obj=en,
                    delayFrame=t*60,
                    executeFunc=function()
                        if play then 
                            SFX:play('hit2',true,3)
                            if hpp<0.5 then
                                angle=angle+math.pi/15
                                local x1,y1,dir=Shape.rThetaPosT(player.x,player.y,50,angle)
                                local note=Circle{x=x1,y=y1,lifeFrame=240,speed=20,sprite=Asset.bulletSprites.note.purple,radius=1.5,highlight=true,direction=dir+math.pi,extraUpdate={
                                    function(self)
                                        self.direction=self.direction+math.eval(0,0.14)
                                        local t=self.frame
                                        if t==180 then
                                            self.safe=true
                                            Event.EaseEventBatch{
                                                obj=self,easeFrames={60,60},aimKeys={'spriteTransparency','speed'},aimValues={0,0}
                                            }
                                        end
                                    end
                                }}

                            end
                        end
                        runningNote(noteType,centerUnit,'triangle')
                    end
                }
            end
        end
        local sets={
            {0.5},{0.25,0.5},{0.25,0.5,0.75},{0.25,0.5,0.625,0.75},{0.25,0.375,0.5,0.75},{0.25,0.375,0.5,0.625,0.75}
        }
        local function getset()
            local range=math.clamp(math.ceil(#sets*(1-hpp)),1,#sets)
            return sets[math.random(1,range)]
        end

        local function changeSafe(cir,frame)
            local safe=cir.safe
            Event.EaseEvent{
                obj=cir,
                easeFrame=frame,
                aimTable=cir,
                aimKey='radius',
                aimValue=safe and 1 or 0.2,
                afterFunc=function()
                    cir.safe=not cir.safe
                end,
            }
        end
        
        local function line(x,y,direction,type,speed)
            speed=speed or 30
            local colorMap={
                before='red',
                after='green',
                period='blue'
            }
            local color=colorMap[type] or 'white'
            local centerUnit
            local laser=Laser{x=x,y=y,direction=direction-math.pi/2,lifeFrame=15,frequency=1,speed=0,sprite=Asset.bulletSprites.laser[color],invincible=true,laserEvents={
            function(laser)
                -- Event.LoopEvent{
                --     obj=laser,
                --     period=1,
                --     executeFunc=function()
                --         laser.args.speed=laser.args.speed+speed
                --     end
                -- }
            end
            },
            bulletEvents={
                function(cir,args,self)
                    cir.lifeFrame=1000
                    cir.safe=true
                    cir.radius=0.2
                    local index=cir.index
                    if index==7 then
                        centerUnit=cir
                        Event.DelayEvent{
                            obj=cir,
                            delayFrame=10,
                            executeFunc=function()
                                cir.hpLevel=hpLevel
                                cir.speed=speed
                                cir.direction=cir.direction+math.pi/2
                                cir.deltaOrientation=-math.pi/2
                                SFX:play('hit',true,3)
                                noteGroup(getset(),'note',centerUnit,true) 
                Event.DelayEvent{
                    obj=cir,
                    delayFrame=60,
                    executeFunc=function()
                        noteGroup(getset(),'rest',centerUnit,true)
                    end
                }
                                cir.extraUpdate[1]=function (self)
                                    if hpLevel~=self.hpLevel then
                                        self:remove()
                                        return
                                    end
                                    local x1,y1=Shape.rThetaPos(self.x,self.y,10,self.direction-math.pi/2)
                                    local side=Shape.leftToLine(player.x,player.y,self.x,self.y,x1,y1)
                                    local nearest=Shape.nearestToLine(player.x,player.y,self.x,self.y,x1,y1)
                                    local distance=Shape.distance(nearest[1],nearest[2],player.x,player.y)
                                    local distance2=Shape.distance(self.x,self.y,nearest[1],nearest[2])
                                    local ratio=math.cosh(distance2/Shape.curvature)
                                    if self.playerSide==nil then
                                        self.playerSide=side
                                    end
                                    local signedDistance=distance*(self.playerSide==side and 1 or -1)
                                    if self.triggered then return end
                                    if type=='before' and signedDistance<20 or type=='after' and signedDistance<3 then
                                        self.triggered=true
                                        changeSafe(self,5)
                                        Event.DelayEvent{
                                            obj=self,
                                            delayFrame=35/ratio*30/speed,
                                            executeFunc=function()
                                                changeSafe(self,5)
                                            end
                                        }
                                    end
                                    if type=='period' and en.frame%60==15 then
                                        changeSafe(self,5)
                                    end
                                end
                            end
                        }
                        return
                    end
                    Event.DelayEvent{
                        obj=cir,
                        delayFrame=20-index,
                        executeFunc=function()
                            cir.extraUpdate[1]=function (self)
                                if not centerUnit then return end
                                if centerUnit.removed then
                                    self:remove()
                                    return
                                end
                                local x,y,dir=Shape.rThetaPosT(centerUnit.x,centerUnit.y,(index-7)*math.min(20,cir.frame+index-20),centerUnit.direction-math.pi/2)
                                self.x,self.y,self.direction=x,y,dir
                                self.safe=centerUnit.safe
                                self.radius=centerUnit.radius
                            end
                        end
                    }
                end
            }
            }
        end

        Event.LoopEvent{
            obj=en,period=1,executeFunc=function()
                hpp=en.hp/en.maxhp
                hpLevel=en:getHPLevel()
                local lineType
                if hpp>0.8 then
                    lineType='after'
                elseif hpp>0.6 then
                    lineType='period'
                elseif hpp>0.4 then
                    lineType='before'
                else
                    lineType=math.randomSample({'before','after','period'},1)[1]
                end
                local t=en.frame
                local num=math.floor(t/120)
                if t%120==60 then
                    local dir=player.naturalDirection
                    if num%2==0 or hpp<0.2 then
                        if hpp>0.2 then
                            dir=dir+math.pi/2*math.random(0,3)
                            for i=1,5 do
                                local x,y,dir2
                                x,y=Shape.rThetaPos(player.x,player.y,150+i*10,dir)
                                dir2=Shape.toObj({x=x,y=y},player)
                                line(x,y,dir2,lineType)
                            end
                        else
                            local rand=math.random(1,4)
                            for i=1,4 do
                                dir=dir+math.pi/2
                                local x,y,dir2
                                x,y=Shape.rThetaPos(player.x,player.y,150,dir)
                                dir2=Shape.toObj({x=x,y=y},player)
                                line(x,y,dir2,i==rand and 'before' or 'after',60)
                            end
                        end
                    else
                        local x,y=en.x,en.y
                        local dir=Shape.toObj({x=x,y=y},player)
                        line(x,y,dir,lineType)
                    end
                    if Shape.distanceObj(en,player)>60 then
                        Event.LoopEvent{
                            obj=en,period=1,times=60,executeFunc=function(self,times)
                                Shape.moveTowards(en,player,0.98^times,true)
                            end
                        }
                    end
                end
            end
        }
    end
}