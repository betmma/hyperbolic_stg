return {
    ID=36,
    quote='?',
    user='nitori',
    dialogue='nitoriDialogue5_1',
    spellName='Battle Machine "Autonomous Sentries"',
    make=function()
        G.levelRemainingFrame=5400
        Shape.removeDistance=2000
        local en=Enemy{x=400,y=300,mainEnemy=true,maxhp=7200}
        local player=Player{x=400,y=600}
        player.moveMode=Player.moveModes.Natural
        player.border:remove()
        local poses={}
        for i = 1, 12, 1 do
            local nx,ny=Shape.rThetaPos(400,300,100,math.pi/6*(i-.5))
            table.insert(poses,{nx,ny})
        end
        local dis0=Shape.distance(poses[1][1],poses[1][2],poses[2][1],poses[2][2])
        player.border=PolyLine(poses)
        G.viewMode.mode=G.VIEW_MODES.FOLLOW
        G.viewMode.object=player
        local b={x=-500,y=300,period=24,frame=0,lifeFrame=6001,bulletSpeed=20,angle=0,bulletLifeFrame=990000,bulletSprite=BulletSprites.bullet.red,
        spawnBatchFunc=function(self)
            SFX:play('enemyShot',true,self.spawnSFXVolume)
            -- local num=math.ceil((1-en.hp/en.maxhp)*12)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            local distance=self.dist or 0
            self.dist=distance+3
            local index=math.floor(self.dist/dis0)
                local x0,y0=Shape.rThetaPos(400,300,100,math.pi/6*(index-.5))
                local x1,y1=Shape.rThetaPos(400,300,100,math.pi/6*(index+.5))
                local direction0=Shape.to(x0,y0,x1,y1)
                local x,y=Shape.rThetaPos(x0,y0,self.dist%dis0,direction0)
                local direction=Shape.to(x,y,player.x,player.y)
                self.x,self.y=x,y
                self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed,radius=size,index=1,batch=self.bulletBatch}
        end
        }
        local c={x=-500,y=300,period=24,frame=0,lifeFrame=6001,bulletSpeed=60,angle=0,bulletLifeFrame=990000,bulletSprite=BulletSprites.bullet.yellow,
        spawnBatchFunc=function(self)
            SFX:play('enemyShot',true,self.spawnSFXVolume)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            local distance=self.dist or 0
            self.dist=distance+10
            local index=math.floor(self.dist/dis0)
                local x0,y0=Shape.rThetaPos(400,300,100,math.pi/6*(index-.5))
                local x1,y1=Shape.rThetaPos(400,300,100,math.pi/6*(index+.5))
                local direction0=Shape.to(x0,y0,x1,y1)
                local x,y=Shape.rThetaPos(x0,y0,self.dist%dis0,direction0)
                local direction=Shape.to(x,y,400,300)
                self.x,self.y=x,y
                self:spawnBulletFunc{x=x,y=y,direction=direction,speed=speed,radius=size,index=1,batch=self.bulletBatch}
        end
        }
        local d={x=-500,y=300,period=72,frame=0,lifeFrame=6001,bulletSpeed=50,angle=0,bulletLifeFrame=990000,bulletSprite=BulletSprites.bullet.blue,
        spawnBatchFunc=function(self)
            SFX:play('enemyShot',true,self.spawnSFXVolume)
            local speed=math.eval(self.bulletSpeed)
            local size=math.eval(self.bulletSize)
            local distance=self.dist or 0
            self.dist=distance+30
            local index=math.floor(self.dist/dis0)
            local x0,y0=Shape.rThetaPos(400,300,100,math.pi/6*(index-.5))
            local x1,y1=Shape.rThetaPos(400,300,100,math.pi/6*(index+.5))
            local direction0=Shape.to(x0,y0,x1,y1)
            local x,y=Shape.rThetaPos(x0,y0,self.dist%dis0,direction0)
            local direction=Shape.to(x,y,player.x,player.y)+math.eval(0,0.2)
            self.x,self.y=x,y
            local num=10
            for i = 1, num, 1 do
                local nx,ny=Shape.rThetaPos(x,y,(i-num/2-0.5)*2,direction+math.pi/2)
                self:spawnBulletFunc{x=nx,y=ny,direction=direction,speed=speed,radius=size,index=i,batch=self.bulletBatch}
            end
        end
        }
        local list={b,c,d}
        local hppRef=1
        local sentryNum=0
        local sentries={}
        Event.LoopEvent{
            obj=b,
            period=1,
            executeFunc=function()
                local hpp=en.hp/en.maxhp
                en.x,en.y=Shape.rThetaPos(en.x,en.y,math.min((hppRef-hpp)*1000,Shape.distance(en.x,en.y,player.x,player.y)),Shape.to(en.x,en.y,player.x,player.y))
                for key, value in pairs(sentries) do
                    value.spawnEvent.frame=value.spawnEvent.frame+(hppRef-hpp)*5000
                end
                hppRef=hpp
                -- b.spawnEvent.period=6*(hpp+0.5)
                local num=math.ceil((1-hpp)*12)
                if sentryNum<num then
                    sentryNum=sentryNum+1
                    local choose={1,1,2,1,2,3,1,2,3,1,2,3,1,2,3}
                    table.insert(sentries,BulletSpawner(list[choose[sentryNum]]))
                    sentries[sentryNum].dist=-dis0*sentryNum
                end
            end
        }
    end
}