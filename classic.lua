--
-- classic
--
-- Copyright (c) 2014, rxi
--
-- This module is free software; you can redistribute it and/or modify it under
-- the terms of the MIT license. See LICENSE for details.
--


local Object = {}
Object.__index = Object

Object.objects = {}
Object.subclasses = {}


function Object:new()
end


function Object:extend()
  local cls = {}
  for k, v in pairs(self) do
    if k:find("__") == 1 then
      cls[k] = v
    end
  end
  cls.__index = cls
  cls.super = self
  cls.objects = {} -- Add a table to store objects of this class
  cls.subclasses = {}
  setmetatable(cls, self)
  table.insert(self.subclasses,cls)
  return cls
end


function Object:implement(...)
  for _, cls in pairs({...}) do
    for k, v in pairs(cls) do
      if self[k] == nil and type(v) == "function" then
        self[k] = v
      end
    end
  end
end


function Object:is(T)
  local mt = getmetatable(self)
  while mt do
    if mt == T then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
end


function Object:__tostring()
  return "Object"
end


function Object:__call(...)
  local obj = setmetatable({}, self)
  obj:new(...)
  table.insert(self.objects, obj)
  return obj
end

-- Method to remove an object
function Object:remove()
  self.removed=true
  -- for i, obj in ipairs(self.objects) do
  --   if obj == self then
  --     table.remove(self.objects, i)
  --     return
  --   end
  -- end
end

function Object:removeAll()
  for i =#self.objects,1,-1 do
    table.remove(self.objects, i)
  end
  for key, cls in pairs(self.subclasses) do
      cls:removeAll()
  end
end

function Object:update(dt)
end

function Object:updateAll(dt) 
  -- why Object:updateAll can't update all things
  -- it's because I overrode Shape:updateAll so cls call didn't get to Circle, Player, etc. fixed
  for key, obj in pairs(self.objects) do
    if not obj.removed then
      obj:update(dt)
    end
  end
  for key, cls in pairs(self.subclasses) do
      cls:updateAll(dt)
  end
  self.nextObjects={}
  for i, obj in ipairs(self.objects) do
    if not obj.removed then
      table.insert(self.nextObjects,obj)
    end
  end
  self.objects=self.nextObjects
end

function Object:draw()
end

function Object:drawAll()
  for key, obj in pairs(self.objects) do
    if not obj.removed and not obj.notRespondToDrawAll then
      obj:draw()
    end
  end
  for key, cls in pairs(self.subclasses) do
      cls:drawAll()
  end
end


function Object:drawText()
end

function Object:drawTextAll()
  for key, obj in pairs(self.objects) do
    if not obj.removed then
      obj:drawText()
    end
  end
  for key, cls in pairs(self.subclasses) do
      cls:drawTextAll()
  end
end

function Object:drawShader()
end

function Object:drawShaderAll()
  for key, obj in pairs(self.objects) do
    if not obj.removed then
      obj:drawShader()
    end
  end
  for key, cls in pairs(self.subclasses) do
      cls:drawShaderAll()
  end
end

return Object