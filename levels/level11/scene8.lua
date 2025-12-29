return {
    ID=110,
    user='renko',
    spellName='Wave Sign "Eigenstate in the Quantum Well"',
    make=function()
        G.levelRemainingFrame=7200
        Shape.removeDistance=1e100
        local center={x=400,y=300000}
        local a,b
        local en
        en=Enemy{x=center.x,y=center.y*0.6,mainEnemy=true,maxhp=7200,hpSegments={0.5},hpSegmentsFunc=function(self,hpLevel)
            Enemy.hpSegmentsFuncShockwave(self,hpLevel)
            en:addHPProtection(600,10)
            en.frame=0
        end}
        en:addHPProtection(600,10)
        local dir0=math.pi/2
        local x1,y1,dir1=Shape.rThetaPosT(center.x,center.y,10,dir0)
        dir1=dir1+math.pi/2
        local x2,y2,dir2=Shape.rThetaPosT(center.x,center.y,-10,dir0)
        dir2=dir2+math.pi/2
        local x11,y11=Shape.rThetaPos(x1,y1,300,dir1)
        local x12,y12=Shape.rThetaPos(x1,y1,-300,dir1)
        local x21,y21=Shape.rThetaPos(x2,y2,300,dir2)
        local x22,y22=Shape.rThetaPos(x2,y2,-300,dir2)
        local player=Player{x=400,y=300000,noBorder=true}
        player.moveMode=Player.moveModes.Natural
        player.border=PolyLine({
            {x12,y12},{x11,y11},
            {x21,y21},{x22,y22},
        })
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local x31,y31=Shape.rThetaPos(center.x,center.y,300,dir0+math.pi/2)
        local x32,y32=Shape.rThetaPos(center.x,center.y,-300,dir0+math.pi/2)
        local L,R=false,false
        local LLastFalseFrame,RLastFalseFrame=0,0
        local function runBase(cir,color)
            cir.spriteTransparency=0
            local d=Shape.distanceToLineSigned(cir.x,cir.y,x1,y1,x2,y2)
            -- if player.keyIsDown('lshift') then
            --     d=d*-1
            -- end
            cir.d=d
            cir.dsign=math.sign(d)
            cir.phase=-a.frame/20
            local times=a.spawnEvent.executedTimes
            if times%2==1 and en:getHPLevel()>1 then
                cir.phase=cir.phase+math.pi
                cir:changeSpriteColor(color)
            end
        end
        a=BulletSpawner{x=x31,y=y31,period=3,frame=0,lifeFrame=9000,bulletNumber=1,bulletSpeed=0,bulletLifeFrame=1000,angle='player',range=math.pi*0.3,bulletSprite=BulletSprites.giant.red,highlight=true,bulletEvents={
            function(cir,args,self)
                runBase(cir,'green')
                cir.frameSinceLastFalse=self.successCount or 0
                if not L then
                    self.successCount=0
                    cir:remove()
                end
                self.successCount=(self.successCount or 0)+1
            end
        },bulletExtraUpdate={
            function(cir)
                local maxTrans=0.2+cir.frameSinceLastFalse/30+(cir.frameSinceLastFalse>12 and 0.4 or 0)
                if maxTrans<1 then
                    cir.safe=true
                end
                cir.spriteTransparency=math.min(cir.frame/20,(cir.lifeFrame-cir.frame)/20,maxTrans,1)
                local xd,yd,dir=Shape.rThetaPosT(center.x,center.y,cir.d,dir0+math.pi/2)
                local xe,ye=Shape.rThetaPos(x1,y1,cir.d,dir1)
                local d2=Shape.distance(xd,yd,xe,ye)
                cir.phase=cir.phase-math.pi/40*25/d2
                cir.d=cir.d-cir.dsign*25/d2
                cir.x,cir.y=Shape.rThetaPos(xd,yd,d2*(math.cosh(cir.d/300))*math.sin(cir.phase),dir+math.pi/2)
            end
        }}
        b=BulletSpawner{x=x32,y=y32,period=3,frame=0,lifeFrame=9000,bulletNumber=1,bulletSpeed=0,bulletLifeFrame=1000,angle='player',range=math.pi*0.3,bulletSprite=BulletSprites.giant.blue,highlight=true,bulletEvents={
            function(cir,args,self)
                runBase(cir,'yellow')
                cir.frameSinceLastFalse=(self.successCount or 0)*2
                if not R then
                    self.successCount=0
                    cir:remove()
                end
                self.successCount=(self.successCount or 0)+1
            end
        },bulletExtraUpdate=a.bulletExtraUpdate}
        local period,started
        Event.LoopEvent{
            obj=en,period=1,
            executeFunc=function(self)
                local t=en.frame
                local hpp=en:getHPPercentOfCurrentLevel()
                if not started then
                    period=480-240*hpp
                    started=true
                    en.frame=0
                else
                    if t%period<period/2 then
                        L,R=true,false
                    else
                        L,R=false,true
                    end
                    if t>=period then
                        started=false
                    end
                end
            end
        }
    end
}