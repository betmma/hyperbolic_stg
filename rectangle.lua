--! file: rectangle.lua
-- deprecated
--We could name our variable anything we want here, but it's nice to keep a consistent name.
local Shape = require "shape"

--Let's also make rectangle local.
local Rectangle = Shape:extend()

function Rectangle:new(x, y, width, height)
    Rectangle.super.new(self, x, y)
    self.width = width
    self.height = height
end

function Rectangle:draw()
    love.graphics.rectangle("line", self.x, self.y, self.width*self.metric, self.height*self.metric)
end


-- And then return it.
return Rectangle