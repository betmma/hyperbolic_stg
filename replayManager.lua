---@class replayData
---@field keyRecord table<number,number> The key record of the replay.
---@field seed number The seed used for RNG.
---@field ID number The ID of the scene
---@field level number The level of the replay. It's looked up from LevelData.ID2LevelScene, so the value in replay file is ignored.
---@field scene number The scene of the replay. Same as above
---@field upgrades table The upgrades bought
---@field name string The name user typed in save replay menu
---@field time string The time when the run started.
---@field version string game version of the run.

local lume=require"lume"
local bit=require"bit"
local levelData = require "levelData"
local player    = require "player"

local replayManager={}
replayManager.REPLAY_NUM_PER_PAGE=25
replayManager.PAGES=4
replayManager.MAX_NAME_LENGTH=20
local dir='replay'
love.filesystem.createDirectory(dir)
local function savePath(slot)
    return dir..'/'..string.format('%03d',slot)..'.rpy'
end

local function getLevelScene(replayData)
    local levelAndScene=LevelData.ID2LevelScene[replayData.ID]
    if not levelAndScene then
        levelAndScene={level='?',scene='?'}
    end
    replayData.level=levelAndScene.level
    replayData.scene=levelAndScene.scene
end

function Hash64(input)
    local hash_table = {}
    local seed = 0xABCDEF  -- Seed value to initialize the hashing process
    -- Initialize the hash table with 64 default values
    for i = 1, 64 do
        hash_table[i] = (seed * i) % 256
    end
    -- Iterate through each character in the input string
    for i = 1, #input do
        local byte = string.byte(input, i)
        local index = (i % 64) + 1 
        -- Use bitwise operations to modify the hash table
        local temp = hash_table[index]
        temp = bit.bxor(temp, byte)
        temp = bit.rol(temp, 3)  -- Rotate left 3 bits
        temp = (temp + seed) % 256
        hash_table[index] = temp
        -- Update the seed based on the character value
        seed = bit.bxor(seed, byte)
        seed = bit.ror(seed, 5)  -- Rotate right 5 bits
    end
    -- Further diffusion across the hash table
    for i = 1, 64 do
        local index = (i % 64) + 1
        hash_table[i] = bit.bxor(hash_table[i], hash_table[index])
        hash_table[i] = (hash_table[i] + seed) % 256
    end
    return hash_table
end

--- get the replay data to be saved
--- @param slot number The slot number of the replay.
--- @param name string The user name inputted in the save replay menu.
--- @return replayData replayData The replay data to be saved.
replayManager.getReplayData=function(slot,name)
    local keyRecord=copy_table(Player.objects[1].keyRecord)
    local seed=G.randomseed
    local level=G.UIDEF.CHOOSE_LEVELS.chosenLevel
    local scene=G.UIDEF.CHOOSE_LEVELS.chosenScene
    local ID=LevelData[level][scene].ID
    local upgrades=G.save.upgrades
    local time=Player.objects[1].realCreatedTime
    local hash=Hash64(time..name..seed..ID)
    for i = 1, #hash do
        table.insert(keyRecord,hash[i])
    end
    local data={
        keyRecord=keyRecord,
        seed=seed,
        ID=ID,
        upgrades=upgrades,
        name=name,
        time=time,
        version=VERSION
    }
    return data
end

replayManager.saveReplay=function(slot,name)
    local data=replayManager.getReplayData(slot,name)
	local serialized = lume.serialize(data)
  	love.filesystem.write(savePath(slot), serialized)
    replayManager.replays[slot]=replayManager.loadReplay(slot)
end

--- replace old replay (use level and scene to determine spellcard) with new replay data (use ID to determine spellcard)
--- @param slot number The slot number of the replay.
replayManager.replaceOldReplay=function(slot)
    local path=savePath(slot)
    local file=love.filesystem.read(path)
    local data = lume.deserialize(file)
    data.ID=LevelData[data.level][data.scene].ID
    data.hash=Hash64(data.time..data.name..data.seed..data.ID)
    local len=#data.keyRecord
    for i=0,#data.hash-1 do
        data.keyRecord[len-i]=data.hash[#data.hash-i]
    end
    local serialized = lume.serialize(data)
    love.filesystem.write(savePath(slot), serialized)
    return data
end

--- @package
--- @return replayData|nil replayData The replay data loaded from the file, or nil if no replay on this slot or is invalid.
replayManager.loadReplay=function(slot)
    local path=savePath(slot)
    local file=love.filesystem.read(path)
    if not file then
        return
    end
    local data = lume.deserialize(file)
    if not data.ID then
        data=replayManager.replaceOldReplay(slot)
    end

    -- check if the replay is valid
    local hash=Hash64(data.time..data.name..data.seed..data.ID)
    local len=#data.keyRecord
    for i=0,#hash-1 do
        if data.keyRecord[len-i]~=hash[#hash-i]then
            return
        end
        table.remove(data.keyRecord,len-i)
    end

    -- get level and scene from ID, for convenience
    getLevelScene(data)

    return data
end

replayManager.runReplay=function(slot)
    local replay=replayManager.loadReplay(slot)
    if not replay then
        SFX:play('cancel',true)
        return
    end
    G.replay=replay
    G.upgradesRef=G.save.upgrades
    G.save.upgrades=replay.upgrades
    G:enterLevel(replay.level,replay.scene)
    -- seed restoring is in levelData
end

-- set the player to replay mode, and do compat things
replayManager.replayTweak=function(replay)
    local player=Player.objects[1]
    player:setReplaying()
    player.keyRecord=replay.keyRecord

    -- below is compat with old replay. Newer modification should be applied earlier, otherwise old modification will be overwritten by the new one.
    if replay.time<'2024-12-10 21:20:00' then
        player.shootInterval=1
        player.shootRows.back.straight.damage=1
        player.shootRows.side.straight.damage=1
        player.shootRows.front.straight.damage=1
        player.shootRows.front.homing.damage=1
        player.shootRows.back.straight.num=player.shootRows.back.straight.num*2
    end
    local version=replay.version or '0.0.0'
    player.version=version -- version<0.2.0.1 old graze effect is in player.lua
    if isVersionSmaller(version,'0.3.2') then
        player.diagonalSpeedAddition=true
    end
    if isVersionSmaller(version,'0.1.3') then
        Circle.sizeFactor=4.5
        Circle.spriteSizeFactor=1.0
    end
    if isVersionSmaller(version,'0.2.1') then
        player.grazeRadiusFactor=3.0
    end
    if isVersionSmaller(version,'0.1.2') then
        player.grazeRadiusFactor=1.5
    end
end

-- 2 uses, 1 is in save replay menu where player is entering their name, the other is in load replay menu. note that [replay] param is used for first situation, where data isn't saved in replayManager.replays yet, so needs to be passed in.
replayManager.getDescriptionString=function(slot,replay)
    local slotWidth = 6  -- "No.012" (includes "No." prefix)
    local nameWidth = 20 -- Reserve space for the name
    local dateWidth = 19 -- "2023-10-11 18:30:20" (fixed format)
    local levelSceneWidth = 6 -- e.g., "10-20"

    local overallWidth=slotWidth+nameWidth+dateWidth+levelSceneWidth -- =51
    if not replay then
        replay=replayManager.replays[slot]
    end
    if not replay then
        return string.format("No.%03d", slot)..' '..string.rep('-',overallWidth-slotWidth-1) -- empty
    end

    getLevelScene(replay)

    -- Format each component
    local slotStr = string.format("No.%03d", slot)
    local nameStr = string.format("%-" .. nameWidth .. "s", replay.name):sub(1, nameWidth) -- Pad or truncate name
    local levelSceneStr = string.format("%d-%d", replay.level, replay.scene)
    local dateStr = replay.time

    -- Combine into a fixed-length string
    local description = string.format("%-" .. slotWidth .. "s %-20s %s %-" .. levelSceneWidth .. "s",
        slotStr, nameStr, dateStr, levelSceneStr)

    return description
end

replayManager.monospacePrint=function(str,width,x,y)
    for i=1,#str do
        love.graphics.printf(str:sub(i,i),x+width*(i-1),y,width,'center')
    end
end

replayManager.replays={}

replayManager.loadAll=function()
    for i=1,replayManager.REPLAY_NUM_PER_PAGE*replayManager.PAGES do
        replayManager.replays[i]=replayManager.loadReplay(i)
    end
end

replayManager.loadAll()

return replayManager