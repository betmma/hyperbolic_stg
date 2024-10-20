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
  for i, obj in ipairs(self.objects) do
    if obj == self then
      table.remove(self.objects, i)
      return
    end
  end
end

function Object:update(dt)
end

function Object:updateAll(dt) -- why Object:updateAll can't update all things
  for key, obj in pairs(self.objects) do
      obj:update(dt)
  end
  for key, cls in pairs(self.subclasses) do
      cls:updateAll(dt)
  end
end

return Object