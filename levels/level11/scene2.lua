return {
    ID=74,
    quote='?',
    user='yukari',
    spellName='Barrier ""', 
    make=function()
        -- after 60 seconds you can only get information from reflections. In this phase the key is to move in a circle, rotating with →↓←↑, instead of finding the direction, so that you don't get confused by the reflections.
        G.levelRemainingFrame=7200
        G.levelIsTimeoutSpellcard=true
        -- G.UseHypRotShader=false
        Shape.removeDistance=100000
        PolyLine.useMesh=false -- reflection written for drawOne, so it doesn't work with mesh. border is rotated in player.testRotate but circle isn't, so circle reflection will be incorrect if use hyprotshader. so i changed circle reflection and in border calculation to use border poses before rotate, to make it work with hyprotshader.
        local a,b
        local en
        en=Enemy{x=5000,y=300,mainEnemy=true,maxhp=96000000}
        en:addHPProtection(600,10)
        local player=Player{x=400,y=600}
        player.cancelVortex=true
        player.calculateShoot=function() end -- shooting isn't mirrored, so disable it
        player.moveMode=Player.moveModes.Natural
        local _,r=BackgroundPattern.calculateSideLength(4,5)
        local borderAngle=0
        local borderPoses={}
        local function borderCreate()
            player.border:remove()
            borderPoses={}
            for i = 1, 4, 1 do
                local nx,ny=Shape.rThetaPos(400,300,r,math.pi*(1/2*(i-.5)-0/6*math.mod2Sign(i))+borderAngle)
                table.insert(borderPoses,{nx,ny})
            end
            player.border=PolyLine(borderPoses)
        end
        borderCreate()
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player

        --- input object and (x1,y1), (x2,y2) that determines the mirror, return a fake object (a table with x, y and orientation)
        ---@param obj table
        ---@param x1 number
        ---@param y1 number
        ---@param x2 number
        ---@param y2 number
        ---@return table
        local function objReflection(obj,x1,y1,x2,y2)
            local xs,ys=obj.x,obj.y
            local xReflection,yReflection,deltaOrientation=Shape.reflectByLine(xs,ys,x1,y1,x2,y2)
            local fakeObj={x=xReflection,y=yReflection,orientation=deltaOrientation-(obj.orientation or 0),sprite=obj.sprite,naturalDirection=-(obj.naturalDirection or 0)} 
            return fakeObj
        end

        -- wrap obj.functionName to achieve calling the original function on every reflection object.
        -- functionName should be "atomic" function that doesn't call other obj methods (so only love draw)
        -- using copy_table on reflected object above is clearly a heavy load and causes fps drop, so you need to copy needed attributes from self to reflectedSelf
        local function reflectFunctionalize(obj,functionName,exitLayer,drawConditionFunc,modificationToReflectionFunc,extraNote)
            local originalFunc=obj[functionName]
            obj[functionName]=function(self,...) -- add layer, lastIndex and inReflection parameter
                local paramLength=select('#',...)
                local inReflection=paramLength>0 and select(-1,...)=='inReflection'
                local layer=0
                local lastIndex
                local args={...}
                if inReflection then
                    layer=select(-3,...)
                    lastIndex=select(-2,...)
                else
                    table.insert(args,0)
                    table.insert(args,0)
                    table.insert(args,'inReflection')
                end
                if not drawConditionFunc or drawConditionFunc(self,layer) then
                    local div=math.ceil(en.frame/30)%5+1
                    local decrease=0
                    if extraNote=='bullet' then
                        local frame=en.frame
                        if frame<3600 and layer==0 then
                            decrease=en.frame/7200
                        elseif frame>3600 and lastIndex==div then
                            decrease=(frame-3600)/7200
                        end
                    end
                    local base=0.6+0.4*math.cos(((lastIndex==div or layer==0) and 1 or 0)*(en.frame%30/30)^0.3*6.28)
                    love.graphics.setColor(1,1,1,base-decrease)
                    originalFunc(self,...)
                    love.graphics.setColor(1,1,1,1)
                end
                args[#args-2]=layer+1 -- layer+=1
                if layer==exitLayer then return end
                local border=player.border
                for i=1,#border.points do
                    if i==lastIndex then
                        goto continue
                    end
                    local pi=border.points[i]
                    local pi2=border.points[i%#border.points+1]
                    local x1,y1,x2,y2
                    if pi.testRotateRef and G.UseHypRotShader then
                        x1,y1=pi.testRotateRef[1],pi.testRotateRef[2]
                        x2,y2=pi2.testRotateRef[1],pi2.testRotateRef[2]
                    else
                        x1,y1=pi.x,pi.y
                        x2,y2=pi2.x,pi2.y
                    end
                    local reflectedSelf=objReflection(self,x1,y1,x2,y2)
                    if modificationToReflectionFunc then
                        modificationToReflectionFunc(reflectedSelf,self,x1,y1,x2,y2)
                    end
                    args[#args-1]=i -- lastIndex
                    obj[functionName](reflectedSelf,unpack(args))
                    ::continue::
                end
            end
        end

        reflectFunctionalize(player,'draw',2,function(self,layer)
            return layer>0 or en.frame<60
        end,function(fakePlayer,self)
            fakePlayer.drawRadius=self.drawRadius
            fakePlayer.focusPointTransparency=self.focusPointTransparency
            fakePlayer.time=-self.time
            fakePlayer.horizontalFlip=not self.horizontalFlip
        end)

        local function reflectBorder()
            local borderdrawOneRef=player.border.drawOne
            player.border.drawOne=function(p1,p2,layer,lastIndex)
                layer=layer or 0
                borderdrawOneRef(p1,p2)
                if layer==2 then return end
                local border=player.border
                for i=1,#border.points do
                    if i==lastIndex then
                        goto continue
                    end
                    local x1,y1=border.points[i].x,border.points[i].y
                    local x2,y2=border.points[i%#border.points+1].x,border.points[i%#border.points+1].y
                    local xs1=p1.x
                    local ys1=p1.y
                    local xs2=p2.x
                    local ys2=p2.y
                    if xs1==x1 and ys1==y1 and xs2==x2 and ys2==y2 then
                        goto continue
                    end
                    -- ugh 2 reflections here make it not able to use reflectFunctionalize :(
                    local xr1,yr1=Shape.reflectByLine(xs1,ys1,x1,y1,x2,y2)
                    local xr2,yr2=Shape.reflectByLine(xs2,ys2,x1,y1,x2,y2)
                    player.border.drawOne({x=xr1,y=yr1},{x=xr2,y=yr2},layer+1,i)
                    ::continue::
                end
            end
        end
        reflectBorder()

        local function bulletBase(cir)
            reflectFunctionalize(cir,'drawSprite',2,function(self,layer)
                return layer>0 or en.frame<3640
            end,function(reflectedSelf,self,x1,y1,x2,y2)
                reflectedSelf.radius=self.radius
                reflectedSelf.batch=self.batch
                reflectedSelf.direction=math.pi-self.direction+reflectedSelf.orientation
                reflectedSelf.orientation=0
            end,'bullet')
            local ref=cir.drawSprite
            cir.drawSprite=function(self,...)
                if G.UseHypRotShader then
                    for i=1,#borderPoses do -- same as border:inside, but use borderPoses to bypass testrotate since circle is not rotated
                        local x1,y1=borderPoses[i][1],borderPoses[i][2]
                        local x2,y2=borderPoses[i%#borderPoses+1][1],borderPoses[i%#borderPoses+1][2]
                        if Shape.leftToLine(cir.x,cir.y,x1,y1,x2,y2) then
                            return -- not inside
                        end
                    end
                else
                    if not player.border:inside(cir.x,cir.y) then
                        return -- not inside
                    end
                end
                ref(self,...)
            end
        end

        local basePos={x=400,y=300}

        a=BulletSpawner{x=400,y=300,period=150,frame=80,lifeFrame=10000,bulletNumber=40,bulletSpeed=20,bulletLifeFrame=3500,angle='0+360',range=math.pi*2,bulletSprite=BulletSprites.bigStar.yellow,visible=false,bulletEvents={
            function(cir,args,self)
                bulletBase(cir)
                if args.index%2==1 then
                    cir.speed=cir.speed+math.min(40,en.frame/60)
                    cir:changeSpriteColor('red')
                    Event.DelayEvent{
                        obj=cir,
                        delayFrame=30,
                        executeFunc=function()
                            Event.EaseEvent{
                                obj=cir,
                                aimTable=cir,
                                aimKey='speed',
                                aimValue=0,
                                easeFrame=20,
                                afterFunc=function()
                                    cir.direction=Shape.to(cir.x,cir.y,player.x,player.y)+math.eval(0,0.5)
                                    Event.EaseEvent{
                                        obj=cir,
                                        aimTable=cir,
                                        aimKey='speed',
                                        aimValue=30,
                                        easeFrame=20
                                    }
                                end
                            }
                        end
                    }
                else
                    Event.EaseEvent{
                        obj=cir,
                        aimTable=cir,
                        aimKey='speed',
                        aimValue=20+math.min(30,en.frame/120),
                        easeFrame=20
                    }
                end
            end
        }}

        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                G.viewMode.viewOffset.x=(player.x-400)*0.1
                G.viewMode.viewOffset.y=(player.y-300)*0.1
                local frame=en.frame
                local testing=0
                if frame==20 then
                    SFX:play('enemyCharge',true)
                    Effect.Charge{obj=player,particleSize=10,particleSpeed=0.5,color={0.3,0.3,0.3}}
                end
                if frame==60 then
                    SFX:play('enemyPowerfulShot',true)
                end
                if frame==math.max(1200-testing,2) then
                    SFX:play('enemyCharge',true)
                    b=BulletSpawner{x=400,y=300,period=300,frame=240,lifeFrame=10000,bulletNumber=15,bulletSpeed=15,bulletLifeFrame=3500,angle='player',range=math.pi/3,bulletSprite=BulletSprites.bigStar.blue,visible=false,bulletEvents={
                        function(cir,args,self)
                            if args.index==1 then
                                SFX:play('enemyShot',true,0.5)
                            end
                            bulletBase(cir)
                            --- a potential blue star bullets remake that looks like circle around corners instead of current 2-part line. But it's harder to dodge
                            -- local pointidx=self.spawnEvent.executedTimes%#player.border.points+1
                            -- local point=player.border.points[pointidx]
                            -- local point2=player.border.points[pointidx%#player.border.points+1]
                            -- local angleBase=Shape.to(point.x,point.y,point2.x,point2.y)
                            -- local angleAdd=math.pi*(args.index-0.5)/(self.bulletNumber)
                            -- cir.x,cir.y,cir.direction=Shape.rThetaPosT(point.x,point.y,1,angleBase+angleAdd)
                            -- cir.pointidx=pointidx
                            -- cir.angleAdd=angleAdd
                            cir.x,cir.y=Shape.rThetaPos(cir.x,cir.y,80-10*2*math.abs(args.index/b.bulletNumber-0.5),cir.direction)
                            cir.direction=Shape.to(cir.x,cir.y,b.x,b.y)
                        end
                    },bulletExtraUpdate={
                        -- function(self)
                        --     local pointidx=self.pointidx
                        --     local point=player.border.points[pointidx]
                        --     local point2=player.border.points[pointidx%#player.border.points+1]
                        --     local angleBase=Shape.to(point.x,point.y,point2.x,point2.y)
                        --     self.x,self.y,self.direction=Shape.rThetaPosT(point.x,point.y,1+self.frame/6,angleBase+self.angleAdd)
                        -- end
                    }}
                end
                -- if frame==2400 then
                --     SFX:play('enemyCharge',true)
                -- end
                if frame>=2400 then
                    Shape.moveTowards(basePos,player,0.1,true)
                    a.x,a.y=basePos.x,basePos.y
                    b.x,b.y=basePos.x,basePos.y
                end
                if frame==3600-testing then
                    SFX:play('enemyCharge',true)
                    Effect.Shockwave{x=a.x,y=a.y,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove={bullet=true,invincible=true}}
                    Effect.Charge{obj=a,particleSize=60,particleSpeed=2,color={0.3,0.3,0.3}}
                    a:remove()
                    b.spawnEvent.frame=180
                end
                if frame==4500-testing then
                    SFX:play('enemyCharge',true)
                    b.spawnEvent.frame=0
                    b.spawnEvent.period=150
                end
                if frame>=4500-testing then
                    borderAngle=borderAngle+math.pi/180*0.5
                    borderCreate()
                    reflectBorder()
                end
                if frame==6000-testing then
                    SFX:play('enemyCharge',true)
                    a=BulletSpawner{x=400,y=300,period=150,frame=80,lifeFrame=10000,bulletNumber=10,bulletSpeed=20,bulletLifeFrame=3500,angle='0+360',range=math.pi*2,bulletSprite=BulletSprites.bigStar.yellow,visible=false,bulletEvents={
                        function(cir,args,self)
                            bulletBase(cir)
                        end
                    }}
                end
            end
        }
    end,
    leave=function() -- restore PolyLine.useMesh
        PolyLine.useMesh=true
    end
}