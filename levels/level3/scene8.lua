return {
    ID=138,
    user='seiran',
    spellName='Raid Sign "Carpet Bombing"',
    unlock=function()
        return Nickname.hasSecretNicknameForAct(3)
    end,
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=100000
        local a,b
        local en
        en=Enemy{x=400,y=200,mainEnemy=true,maxhp=6000}
        -- en:addHPProtection(600,10)
        local player=Player{x=400,y=600,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        local center={x=400,y=300}
        player.border=PolyLine(Shape.regularPolygonCoordinates(center.x,center.y,110,12))
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local triangleSizeUnit=3
        local subBulletUpdate=function(cir)
            local row,index,parent=cir.row,cir.index,cir.parent
            local disRow=row*triangleSizeUnit
            local disIndex=index*triangleSizeUnit
            local initDisRow,initDisIndex=cir.frame*0.5*math.abs(disRow/10)^0.5,cir.frame*0.5*math.abs(disIndex/10)^0.5
            local initComplete=initDisRow>=math.abs(disRow) and initDisIndex>=math.abs(disIndex)
            if not cir.firstInitComplete and initComplete then
                cir.firstInitComplete=true
                cir.grazed=false
            end
            disRow=math.min(math.abs(disRow),initDisRow)*math.sign(disRow)
            disIndex=math.min(math.abs(disIndex),initDisIndex)*math.sign(disIndex)
            local x1,y1,dir1=Shape.rThetaPosT(parent.x,parent.y,-disRow,parent.direction)
            local x2,y2,dir2=Shape.rThetaPosT(x1,y1,disIndex,dir1+math.pi/2)
            cir.x,cir.y,cir.direction=x2,y2,dir2-math.pi/2
            if parent.removed then
                cir.spriteTransparency=cir.spriteTransparency-0.05
                if cir.spriteTransparency<=0 then
                    cir:remove()
                end
            end
        end
        local triangleBase=function(cir,size)
            -- spawn bullets in triangle shape. cir is the center of the triangle. 
            for row=1,size,1 do
                for index=1,row,1 do
                    local isEdge=index==1 or index==row or row==size
                    local color=isEdge and 'blue' or 'cyan'
                    local bullet=Circle{x=cir.x,y=cir.y,sprite=BulletSprites.bullet[color],speed=0,lifeFrame=500,extraUpdate=subBulletUpdate}
                    bullet.row=row-size*2/3 -- this deduction makes cir the center of the triangle instead of the top.
                    bullet.index=index-row/2-0.5
                    bullet.parent=cir
                    bullet.grazed=true -- prevent grazing all overlapping bullets at spawn
                end
            end
        end
        local triangleNum=10
        a=BulletSpawner{x=en.x,y=en.y,period=390,frame=330,lifeFrame=10000,bulletNumber=1,bulletSpeed=0,bulletLifeFrame=500,angle='player',range=math.pi*2,bulletSprite=BulletSprites.bullet.cyan,fogEffect=true,spawnSFXVolume=1,bulletEvents={
            function(cir,args,self)
                cir.invincible=true
                cir.spriteTransparency=0
                cir.index=args.index
                triangleBase(cir,20)
                Shape.moveToInTime(cir,{x=args.aimx,y=args.aimy},60)
            end
        },bulletExtraUpdate=function(cir)
            if cir.frame>=triangleNum*15+30-cir.index*14 then
                cir.speed=cir.speed+0.5
            end
        end,spawnBatchFunc=function(self)
            triangleNum=math.ceil(15-5*en.hp/en.maxhp)
            SFX:play('enemyShot',true,self.spawnSFXVolume)
            local angle=self.angle=='player' and Shape.to(self.x,self.y,Player.objects[1].x,Player.objects[1].y) or math.eval(self.angle)
            local x1,y1,angle1=Shape.rThetaPosT(self.x,self.y,-20,angle)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            for i=1,triangleNum do
                local rx,ry=Shape.rThetaPosT(x1,y1,150*(1-math.random()^3)*math.randomSign(),angle1+math.eval(math.pi/2,0.8))
                Event.DelayEvent{
                    delayFrame=i*15,
                    executeFunc=function()
                        SFX:play('enemyShot',true)
                        local angle2=math.eval(Shape.to(rx,ry,player.x,player.y),0.5)
                        self:spawnBulletFunc{x=self.x,y=self.y,direction=angle2,speed=speed,radius=size,index=i,batch=self.bulletBatch,fogTime=15,sprite=self.bulletSprite,aimx=rx,aimy=ry}
                    end
                }
            end
        end}
        Event.LoopEvent{
            obj=en,
            period=1,
            executeFunc=function()
                if a.spawnEvent.frame==(triangleNum*15+30) then
                    SFX:play('enemyPowerfulShot')
                end
                if en.frame%200==199 then
                    -- SFX:play('enemyShot',true,0.5)
                    local x,y=Shape.rThetaPos(400,200,math.eval(30,30),math.eval(0,999))
                    Event.LoopEvent{
                        obj=en,period=1,
                        times=100,
                        executeFunc=function ()
                            Shape.moveTowards(en,{x=x,y=y},0.6,true)
                            a.x,a.y=en.x,en.y
                            -- b.x,b.y=en.x,en.y
                        end
                    }
                end
            end
        }
    end
}