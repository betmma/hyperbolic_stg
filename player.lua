
local Shape = require "shape"
local Circle=require"circle"
local PolyLine=require"polyline"
local Player = Shape:extend()

function Player:new(x, y, movespeed)
    Player.super.new(self, {x=x, y=y})
    self.lifeTime=9999999
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

    self.hp=3
    self.invincibleTime=0
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

    -- self.x=math.clamp(self.x,self.border.minx,self.border.maxx)
    -- self.y=math.clamp(self.y,self.border.miny,self.border.maxy)
    local count=0
    while count<10 and not self.border:inside(self.x,self.y) do
        count=count+1
        local line={self.border:inside(self.x,self.y)}
        -- local centerX=Shape.lineCenter(line[2],line[3],line[4],line[5])
        local p=Shape.nearestToLine(self.x,self.y,line[2],line[3],line[4],line[5])
        -- local direction=Shape.to(self.x,self.y,line[4],line[5])
        -- local dirx=math.cos(direction)
        -- local diry=math.sin(direction)
        -- local dot=(self.x-xref)*dirx+(self.y-yref)*diry
        self.x=p[1]--xref+dot*dirx
        self.y=p[2]--yref+dot*diry
    end

    self.invincibleTime=self.invincibleTime-dt
    if self.invincibleTime<=0 then
        self.invincibleTime=0
        for key, circ in pairs(Circle.objects) do
            if Shape.distance(circ.x,circ.y,self.x,self.y)<circ.radius+self.radius then
                self.hp=self.hp-1
                self.invincibleTime=self.invincibleTime+1
                break
            end
        end
    end
    local x,y,r=math.getCircle(self.x,self.y,self.radius)
    BulletBatch:add(Asset.playerFocus,x,y,self.time/10,r*0.5,r*0.5,31,33)
end

function Player:draw()
    -- Formula: center (x,y) and radius r should be drawn as center (x,y*cosh(r)) and radius y*sinh(r)
    local color={love.graphics.getColor()}
    love.graphics.setColor(1,1,0)
    if self.invincibleTime>0 then
        love.graphics.setColor(1,0,0)
    end
    math.drawCircle(self.x,self.y,self.radius)
    love.graphics.setColor(color[1],color[2],color[3])
    -- love.graphics.circle("line", self.x, self.y, 1) -- center point
    -- love.graphics.print(tostring(self.hp),self.x-5,self.y-8)
    love.graphics.print('HP: '..tostring(self.hp),100,100)
end
return Player