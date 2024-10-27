local Shape = require "shape"
local Circle=require'circle'
local Event=require"event"

local Enemy=Shape:extend()

function Enemy:new(args)
    Enemy.super.new(self, args)
    self.hp=args.hp or 1000
    self.maxhp=args.maxhp or 1000 
    self.radius=10
end

function Enemy:update(dt)
    for key, circ in pairs(Circle.objects) do
        if circ.safe and Shape.distance(circ.x,circ.y,self.x,self.y)<circ.radius+self.radius then
            self.hp=self.hp-(circ.damage or 1)
            circ:remove()
            if self.hp<0 then
                self:remove()
            end
        end
    end
end

function Enemy:draw()
    local color={love.graphics.getColor()}
    love.graphics.setColor(0,1,1)
    Shape.drawCircle(self.x,self.y,self.radius)
    self:drawHPBar()
    love.graphics.setColor(color[1],color[2],color[3])
end

function Enemy:drawHPBar()
    local color={love.graphics.getColor()}
    love.graphics.setColor(1,0.3,0.3)
    Shape.drawCircle(self.x,self.y,30.5)--inner circle
    Shape.drawCircle(self.x,self.y,32.5)--outer circle
    local ratio=self.hp/self.maxhp
    -- self.DrawArc(self.x,self.y,31,-math.pi/2,math.pi*(2*ratio-0.5),100)
    love.graphics.setColor(1,1,1)
    for i=31,32,0.5 do
        self.DrawArc(self.x,self.y,i,math.pi*(1.5-2*ratio),math.pi*(1.5),100)
    end
    SetFont(12)
    love.graphics.print(""..ratio..', ', 10, 100)
    love.graphics.setColor(color[1],color[2],color[3])
end

-- love is really silly to not provide arc without lines toward center
-- but anyway to draw hyperbolic arc it's better to have my own func
function Enemy.DrawArc(x, y, r, s_ang, e_ang, numLines)
    -- SetFont(12)
    -- love.graphics.print(""..s_ang..', '..e_ang, 10, 150)
    local x2,y2,r2=Shape.getCircle(x,y,r)
    _,_,s_ang=Shape.rThetaPos(x,y,r,s_ang)
    _,_,e_ang=Shape.rThetaPos(x,y,r,e_ang)
    -- SetFont(12)
    -- love.graphics.print(""..s_ang..', '..e_ang, 10, 200)
	local step = ((math.pi * 2) / numLines)
	local ang1 = s_ang
	local ang2 = 0
	
	while (ang1 < e_ang) do
		ang2 = ang1 + step
		love.graphics.line(x2 + (math.cos(ang1) * r2), y2 + (math.sin(ang1) * r2),
			x2 + (math.cos(ang2) * r2), y2 + (math.sin(ang2) * r2))
		ang1 = ang2
	end

end

return Enemy