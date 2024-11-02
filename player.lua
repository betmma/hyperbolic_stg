
local Shape = require "shape"
local Circle=require"circle"
local PolyLine=require"polyline"
local Player = Shape:extend()

function Player:new(x, y, movespeed)
    Player.super.new(self, {x=x, y=y})
    self.lifeFrame=9999999
    self.speed=0
    self.movespeed=movespeed or 60
    self.focusFactor=0.4444
    --when pressed left or right player moves in an arc with center (centerX,0)
    self.centerX=400
    --drawn as a circle
    self.radius = 0.5
    -- self.border={minx=0,maxx=love.graphics.getWidth(),miny=0,maxy=love.graphics.getHeight()}
    local minx=200
    local maxx=600
    local miny=0
    local maxy=560
    
    self.border=PolyLine({{minx,miny},{maxx,miny},{maxx,maxy},{minx,maxy}})

    self.maxhp=3
    self.hp=self.maxhp
    self.invincibleTime=0

    self.shootRows=4
end
local function isDownInt(keyname)
    return love.keyboard.isDown(keyname)and 1 or 0
end

function Player:update(dt)
    local xref=self.x
    local yref=self.y
    self.direction=math.atan2(self.y-Shape.axisY,self.x-self.centerX)-math.pi/2
    local right=isDownInt("right")-isDownInt("left")
    if right==-1 then
        self.direction=math.pi+self.direction
    end
    local down=isDownInt("down")-isDownInt("up")
    if self.y<Shape.axisY then
        down=down*-1
    end
    if right==0 and down==0 then
        self.speed=0
    elseif right*down==0 then
        self.speed=self.movespeed
        if right==0 then
            self.direction=math.pi/2*down
        end
    else
        local downdir=math.pi/2*down
        self.speed=self.movespeed*2*math.cos((self.direction-downdir)/2)
        self.direction=(self.direction+downdir)/2
    end
    if love.keyboard.isDown('lshift') then
        self.speed=self.speed*self.focusFactor
    end

    self.super.update(self,dt) -- actually move

    -- limit player in border
    local count=0
    while count<10 and not self.border:inside(self.x,self.y) do
        count=count+1
        local line={self.border:inside(self.x,self.y)}
        local p=Shape.nearestToLine(self.x,self.y,line[2],line[3],line[4],line[5])
        self.x=p[1]--xref+dot*dirx
        self.y=p[2]--yref+dot*diry
    end

    -- handle invincible time from hit
    self.invincibleTime=self.invincibleTime-dt
    if self.invincibleTime<=0 then
        self.invincibleTime=0
        -- it's not ideal to handle hit in player:update, cuz different bullets may have non-circle hitbox (like laser) so this part will grow long
        for key, circ in pairs(Circle.objects) do
            if not circ.safe and Shape.distance(circ.x,circ.y,self.x,self.y)<circ.radius+self.radius then
                self.hp=self.hp-1
                self.invincibleTime=self.invincibleTime+1
                if self.hp<=0 then
                    G:lose()
                end
                Effect.Shockwave{x=self.x,y=self.y,radius=3,growSpeed=1.1,animationFrame=30}
                break
            end
        end
    end
    local x,y,r=Shape.getCircle(self.x,self.y,self.radius)
    Asset.playerFocusBatch:add(Asset.playerFocus,x,y,self.time/5,r*0.5,r*0.5,31,33)-- the image is 64*64 but the focus center seems slightly off

    -- shooting bullet
    if love.keyboard.isDown('z') then
        self:shoot()
    end
end

function Player:shoot()
    local x,y,r=Shape.getCircle(self.x,self.y,self.radius)
    local rows=self.shootRows
    for i=1,rows do 
        local cir=Circle({x=self.x+2*r*(i-0.5-rows/2), y=self.y, radius=0.3, lifeFrame=60, sprite=self.bulletSprite or BulletSprites.darkdot.cyan, batch=Asset.playerBulletBatch, sprite_transparency=0.5})
        -- table.insert(ret,cir)
        cir.fromPlayer=true
        cir.safe=true
        cir.direction=-math.pi/2
        cir.speed=200
        cir.damage=1
    end
end

function Player:draw()
    -- Formula: center (x,y) and radius r should be drawn as center (x,y*cosh(r)) and radius y*sinh(r)
    local color={love.graphics.getColor()}
    love.graphics.setColor(1,1,0)
    if self.invincibleTime>0 then
        love.graphics.setColor(1,0,0)
    end
    Shape.drawCircle(self.x,self.y,self.radius)
    love.graphics.setColor(color[1],color[2],color[3])
    -- love.graphics.circle("line", self.x, self.y, 1) -- center point
    -- love.graphics.print(tostring(self.hp),self.x-5,self.y-8)
    SetFont(24)
    love.graphics.print('HP: '..tostring(self.hp),100,100)
end
return Player