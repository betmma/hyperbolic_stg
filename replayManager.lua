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

local function hash64(input)
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

replayManager.getReplayData=function(slot,name)
    local keyRecord=copy_table(Player.objects[1].keyRecord)
    local seed=G.randomseed
    local level=G.UIDEF.CHOOSE_LEVELS.chosenLevel
    local scene=G.UIDEF.CHOOSE_LEVELS.chosenScene
    local upgrades=G.save.upgrades
    local time=Player.objects[1].realCreatedTime
    local hash=hash64(time..name..seed..level..scene)
    for i = 1, #hash do
        table.insert(keyRecord,hash[i])
    end
    local data={
        keyRecord=keyRecord,
        seed=seed,
        level=level,
        scene=scene,
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

replayManager.loadReplay=function(slot)
    local path=savePath(slot)
    local file=love.filesystem.read(path)
    if not file then
        return false
    end
    local data = lume.deserialize(file)
    local hash=hash64(data.time..data.name..data.seed..data.level..data.scene)
    local len=#data.keyRecord
    for i=0,#hash-1 do
        if data.keyRecord[len-i]~=hash[#hash-i]then
            return false
        end
        table.remove(data.keyRecord,len-i)
    end
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
    local player=Player.objects[1]
    player:setReplaying()
    player.keyRecord=replay.keyRecord

    -- below is compat with old replay
    if replay.time<'2024-12-10 21:20:00' then
        player.shootInterval=1
        player.shootRows.back.straight.damage=1
        player.shootRows.side.straight.damage=1
        player.shootRows.front.straight.damage=1
        player.shootRows.front.homing.damage=1
        player.shootRows.back.straight.num=player.shootRows.back.straight.num*2
    end
end

-- note that replay param is used for pending (not saved yet) replay like when entering name. Other situations no need to input replay.
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
        return string.format("No.%03d", slot)..' '..string.rep('-',overallWidth-slotWidth-1)
    end

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