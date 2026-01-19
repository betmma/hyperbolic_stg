local lume = require "import.lume"

-- high level mechanic to add default values to save data (a table).
-- some keys have direct default values while some need a function to generate default value.
-- the final function would be default save data:apply(save data)

---@alias key string|integer

---@class DefaultItem
---@field public apply fun(self:DefaultItem,otherTable:table,key:key):nil apply default value to otherTable[key] if it is nil
---@field private defaultValue fun(self:DefaultItem,otherTable:table,key:key):any return the default value for this item
---@field private applyCondition fun(self:DefaultItem,otherTable:table,key:key):boolean optional condition function to check whether to apply default value

local DefaultItem=Object:extend()

function DefaultItem:apply(otherTable,key)
    if self:applyCondition(otherTable,key) then
        otherTable[key]=self:defaultValue(otherTable,key)
    end
end

function DefaultItem:defaultValue(otherTable,key)
    error('Not implemented')
end

function DefaultItem:applyCondition(otherTable,key)
    return otherTable[key]==nil
end

---@class DefaultValue:DefaultItem
---@field private value any the default value

local DefaultValue=DefaultItem:extend()

function DefaultValue:new(value)
    self.value=value
end
function DefaultValue:defaultValue()
    return self.value
end

---@class DefaultFunction:DefaultItem
---@field private func fun(otherTable:table,key:key):any function to generate default value

local DefaultFunction=DefaultItem:extend()

---@param func fun(otherTable:table,key:key):any function to generate default value
function DefaultFunction:new(func)
    self.defaultValue=function(self,otherTable,key)
        local ret=func(otherTable,key)
        if ret==nil then
            ret=otherTable[key] -- if func returns nil, keep original value (or otherTable[key] is a table and func has changed it)
        end
        return ret
    end
end

---@class AlwaysFunction:DefaultFunction
-- always call the function to get value, even if the key already exists. for example, to add new fields to existing tables.
local AlwaysFunction=DefaultFunction:extend()
function AlwaysFunction:applyCondition(otherTable,key)
    return true
end

---@class DefaultTable:DefaultItem
---@field private template table<key,DefaultItem> template table to apply recursively

local DefaultTable=DefaultItem:extend()

---@param template table<key,DefaultItem|any> template table to apply recursively, will auto wrap non-DefaultItem values with DefaultValue, DefaultTable or error on function
function DefaultTable:new(template)
    for k,v in pairs(template) do
        if not Object.is(v,DefaultItem) then
            if type(v)=='function' then
                error('Key '..tostring(k)..' has function value, please wrap it with DefaultFunction or AlwaysFunction')
            elseif type(v)=='table' then
                template[k]=DefaultTable(v)
            else
                template[k]=DefaultValue(v)
            end
        end
    end
    self.template=template
end

function DefaultTable:apply(otherTable, key)
    -- 1. If the table doesn't exist, create it
    if otherTable[key] == nil then
        otherTable[key] = {}
    end

    -- 2. Ensure what exists is actually a table (safety check)
    if type(otherTable[key]) ~= "table" then
        print("Warning: Type mismatch for key " .. tostring(key) .. ". Resetting to table.")
        otherTable[key] = {}
    end

    local subTable = otherTable[key]

    -- 3. Recurse through the template
    for subKey, subDefaultItem in pairs(self.template) do
        subDefaultItem:apply(subTable, subKey)
    end
end

---@class DefaultRoot:DefaultTable the root default table to apply to whole save data

local DefaultRoot=DefaultTable:extend()

function DefaultRoot:new(template)
    DefaultRoot.super.new(self, template)
end

function DefaultRoot:apply(otherTable)
    for key, defaultItem in pairs(self.template) do
        defaultItem:apply(otherTable, key)
    end
end


local SaveManager={}


-- define the default save data structure here
SaveManager.defaultSaveData=DefaultRoot{
    levelData=AlwaysFunction(function(otherTable,key) -- new level can be added anytime, so always check and add missing levels
        otherTable[key]=otherTable[key] or {}
        local saveLevelData=otherTable[key]
        for id,value in pairs(LevelData.ID2LevelScene) do
            local level,scene=value.level,value.scene
            if not saveLevelData[id] then
                if saveLevelData[level] and saveLevelData[level][scene] then -- has old save data of that level, transfer it
                    saveLevelData[id]=saveLevelData[level][scene]
                else -- new level, create default data
                    saveLevelData[id]={passed=0,tryCount=0,firstPass=0,firstPerfect=0}
                end
            end
            if saveLevelData[level] and saveLevelData[level][scene] then
                saveLevelData[level][scene]=nil -- remove old save data
            end
        end
    end),
    levelUnlock=1, -- highest unlocked level
    options={
        master_volume=100,
        music_volume=100,
        sfx_volume=100,
        language='en_us',
        resolution={width=WINDOW_WIDTH,height=WINDOW_HEIGHT},
    },
    upgrades=AlwaysFunction(function(otherTable,key) -- always check and add missing upgrades
        otherTable[key]=otherTable[key] or {}
        local saveUpgrades=otherTable[key]
        local upgradesData=Upgrades.data
        if saveUpgrades[1] and type(saveUpgrades[1])=='table' then -- old format (xy in matrix), convert to new format
            local newUpgrades={}
            for x=1,#saveUpgrades do
                for y=1,#saveUpgrades[x] do
                    local bought=saveUpgrades[x][y].bought
                    local upgrade=Upgrades.upgradesTree[x] and Upgrades.upgradesTree[x][y] and Upgrades.upgradesTree[x][y].upgrade
                    if upgrade then
                        newUpgrades[upgrade]={bought=bought}
                    end
                end
            end
            saveUpgrades=newUpgrades
        end
        for key,value in pairs(upgradesData) do
            if not saveUpgrades[key] then
                saveUpgrades[key]={bought=false}
            end
        end
    end),
    defaultName='', -- the default name when saving replay
    playTimeTable={ -- unit is seconds
        playTimeOverall=0,
        playTimeInLevel=0,
    },
    extraUnlock={
        firstStart=true, -- first time starting the game. enter 1-1 instead of level choose menu
        lshiftReplayDialogueHintShown=false, -- pass 1-1
        shopUnlocked=false -- pass 2-1
    },
    musicUnlock={
    },
    nicknameUnlock={}, -- this and below are managed by nickname.lua
    statistics={
        loseCount=0,
        totalGraze=0,
        totalYinYangOrbRemoved=0,
        totalPlayerGetHit=0
    },
}

function SaveManager:applyDefaultSaveData(saveData)
    SaveManager.defaultSaveData:apply(saveData)
end

function SaveManager:saveData(G)
    local data = G.save or {}
	local serialized = lume.serialize(data)
  	love.filesystem.write("savedata.txt", serialized)
end

function SaveManager:loadData(G)
    local file = love.filesystem.read("savedata.txt")
    local data = {}
    if file then
        data = lume.deserialize(file)
    end
    G.save = data
    self:applyDefaultSaveData(G.save)
end

return SaveManager