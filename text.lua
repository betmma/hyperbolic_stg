local Shape=require"Shape"
local Text=Shape:extend()

-- Text doesn't apply to hyperbolic geometry xD
-- Also it's only used to display moving Spellcard name when entering level. Under other circumstances, normal print is quite enough.
-- [align] is the alignment of the text, can be 'left', 'center', 'right' and 'justify'. passed to love.graphics.printf.
-- [anchor] is the anchor of the textBox, can be 'nw', 'n', 'ne', 'w', 'c', 'e', 'sw', 's', 'se'. used to calculate the position of the textBox.
function Text:new(args)
    args.lifeFrame=args.lifeFrame or 999999999
    Enemy.super.new(self, args)
    self.text=args.text or ''
    self.width=args.width or 300
    self.height=args.height or 100
    self.bordered=args.bordered or false
    self.align=args.align or 'left'
    self.anchor=args.anchor or 'nw'
    self.fontSize=args.fontSize or 18
    self.color=args.color or {1,1,1,1}
end

function Text:drawText()
    local x,y=self.x,self.y
    if self.anchor=='nw' then
        x,y=self.x,self.y
    elseif self.anchor=='n' then
        x,y=self.x-self.width/2,self.y
    elseif self.anchor=='ne' then
        x,y=self.x-self.width,self.y
    elseif self.anchor=='w' then
        x,y=self.x,self.y-self.height/2
    elseif self.anchor=='c' then
        x,y=self.x-self.width/2,self.y-self.height/2
    elseif self.anchor=='e' then
        x,y=self.x-self.width,self.y-self.height/2
    elseif self.anchor=='sw' then
        x,y=self.x,self.y-self.height
    elseif self.anchor=='s' then
        x,y=self.x-self.width/2,self.y-self.height
    elseif self.anchor=='se' then
        x,y=self.x-self.width,self.y-self.height
    end
    
    if self.bordered then
        love.graphics.rectangle("line",x,y,self.width,self.height)
    end
    SetFont(self.fontSize)
    local colorref={love.graphics.getColor()}
    love.graphics.setColor(self.color[1],self.color[2],self.color[3],self.color[4]or 1)
    love.graphics.printf(self.text,x+5,y+5,self.width-10,self.align,0,1,1)
    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4] or 1)
end

return Text