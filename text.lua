local Shape=require"Shape"
local Text=Shape:extend()

-- Text doesn't apply to hyperbolic geometry xD
-- Also it's only used to display moving Spellcard name when entering level. Under other circumstances, normal print is quite enough.
function Text:new(args)
    args.lifeFrame=999999999
    Enemy.super.new(self, args)
    self.text=args.text or ''
    self.width=args.width or 300
    self.height=args.height or 100
    self.bordered=args.bordered or false
    self.align=args.align or 'left'
    self.fontSize=args.fontSize or 18
    self.color=args.color or {1,1,1,1}
end

function Text:drawText()
    if self.bordered then
        love.graphics.rectangle("line",self.x,self.y,self.width,self.height)
    end
    SetFont(self.fontSize)
    local colorref={love.graphics.getColor()}
    love.graphics.setColor(self.color[1],self.color[2],self.color[3],self.color[4]or 1)
    love.graphics.printf(self.text,self.x+5,self.y+5,self.width-10,self.align,0,1,1)
    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4] or 1)
end

return Text