--
-- classic
--
-- Copyright (c) 2014, rxi
--
-- This module is free software; you can redistribute it and/or modify it under
-- the terms of the MIT license. See LICENSE for details.
--

--[[
  This module provides a simple classical inheritance system.

  - 'Object' is the root base class. It provides the fundamental mechanisms for
    class creation (:extend), instantiation (Class()), type checking (:is),
    and interface implementation (:implement). It is a general-purpose class
    and does not inherently know about game loops, updating, or drawing.
    Think of it as the blueprint for making blueprints.

  - 'GameObject' extends 'Object'. It is specifically designed for entities
    that need to be updated each frame (move, animate),
    and drawn on screen. It introduces methods like :update, :draw, :remove
    and their collective counterparts (:updateAll, :drawAll).
--]]

---@class Object
---@description The fundamental base class for creating other classes.
---@field public objects table<number, Object> List of instances created directly from this class.
---@field public subclasses table<number, Object> List of direct subclasses created using `:extend()`.
---@field public super table | nil The parent class this class was extended from.
local Object = {}
Object.__index = Object

Object.objects = {}
Object.subclasses = {}


--- Constructor (called via ClassName(...))
---@param ... any Arguments passed to the instance constructor
function Object:new(...)
end


--- Creates a new class that inherits from this class (`self`).
---@generic Class:Object
---@param self Class
---@return table Class An new class table that inherits from `self`. Use `---@class NewClassName : Object` in your code when using this.
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


--- Checks if an object instance (`self`) is derived from a given class (`T`).
---@param T table The class table to check against.
---@return boolean True if `self` is an instance of `T` or one of its subclasses.
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


--- Metamethod called when a class table is called like a function `ClassName(...)`.
--- Creates, initializes, and stores a new instance.
--- Constructor (called via ClassName(...))
---@generic Class:Object
---@param self Class
---@param ... any Arguments to be passed to the instance's `:new()` method.
---@return Class
function Object:__call(...)
  local obj = setmetatable({}, self)
  obj:new(...)
  table.insert(self.objects, obj)
  return obj
end

---@class GameObject : Object things need to be updated and drawn like Shape, Bullet, Player, Enemy. Static things like Sprite, AudioSystem are not GameObject.
---@field objects GameObject[] 
---@field subclasses GameObject[] 
---@field removed boolean|nil Internal flag set when `remove()` is called on an instance.
---@field notRespondToDrawAll boolean|nil If true on an instance, it will be skipped by `drawAll`.
local GameObject=Object:extend()

--- Marks an instance for removal during the next update cycle.
function GameObject:remove()
  self.removed=true
end

--- Removes all instances of this specific GameObject class and recursively
--- calls removeAll on its subclasses. Usually used to clear all objects
--- when entering/leaving a level.
function GameObject:removeAll()
  for i =#self.objects,1,-1 do
    table.remove(self.objects, i)
  end
  for key, cls in pairs(self.subclasses) do
      cls:removeAll()
  end
end

function GameObject:update(dt)
end

function GameObject:updateAll(dt) 
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
  local nextObjects={}
  for i, obj in ipairs(self.objects) do
    if not obj.removed then
      table.insert(nextObjects,obj)
    end
  end
  self.objects=nextObjects
end

function GameObject:draw()
end

function GameObject:drawAll()
  for key, obj in pairs(self.objects) do
    if not obj.removed and not obj.notRespondToDrawAll then
      obj:draw()
    end
  end
  for key, cls in pairs(self.subclasses) do
      cls:drawAll()
  end
end


function GameObject:drawText()
end

function GameObject:drawTextAll()
  for key, obj in pairs(self.objects) do
    if not obj.removed then
      obj:drawText()
    end
  end
  for key, cls in pairs(self.subclasses) do
      cls:drawTextAll()
  end
end

function GameObject:drawShader()
end

function GameObject:drawShaderAll()
  for key, obj in pairs(self.objects) do
    if not obj.removed then
      obj:drawShader()
    end
  end
  for key, cls in pairs(self.subclasses) do
      cls:drawShaderAll()
  end
end

return {Object,GameObject}