---@class LevelData
---@field ID number unique ID of this level. It's to make a map between ID and level-scene, which is used to look up replay level-scene and localizations. Will raise an error if not assigned or not unique.
-- (further elaboration: the relationship between level-scene and ID is calculated after loading all levels in the definition of levelData below)
---@field user string the character of this scene. Is used to look up name in localization file.
---@field make fun():nil
---@field leave fun():nil | nil do things when leaving the level.
---@field quote string | nil After implementation of localization, this field is not used in game. It's only for coding reference.
---@field spellName string | nil Same as above


local Text=require"text"

-- some wrapping work for each scene
---@param levelData LevelData
local function wrapLevelMake(levelData)
    local makeLevelRef=levelData.make
    levelData.make=function()
        local replay=G.replay or {}
        local seed = replay.seed or math.floor(os.time()+os.clock()*1337)
        math.randomseed(seed)
        G.randomseed=seed
        Shape.timeSpeed=1
        G.viewMode.mode=G.VIEW_MODES.NORMAL
        G.viewOffset={x=0,y=0}
        -- show spellcard name
        do
            if not levelData.spellName then
                levelData.spellName=''
            end
            local name=Localize{'levelData','spellcards',levelData.ID,'spellName'}
            local txt=Text{x=200,y=500,width=400,height=100,bordered=false,text=name,fontSize=18,color={1,1,1,0},align='center'}
            G.spellNameText=txt
            Event.EaseEvent{
                obj=txt,
                easeFrame=120,
                aimTable=txt,
                aimKey='y',
                aimValue=10,
                progressFunc=Event.sineOProgressFunc
            }
            Event.EaseEvent{
                obj=txt,
                easeFrame=120,
                aimTable=txt.color,
                aimKey=4,
                aimValue=1,
                progressFunc=Event.sineOProgressFunc
            }
        end
        -- show user name
        do
            local name=Localize{'levelData','names',levelData.user}
            local fontSize=72
            if string.len(name)>20 then -- ensure the name fits in the screen
                fontSize=math.floor(72*20/string.len(name))
            end
            local name=Text{x=300,y=200,width=500,height=100,bordered=false,text=name,fontSize=fontSize-8,color={1,1,1,0},align='center',anchor='c',lifeFrame=60}
            Event.EaseEvent{
                obj=name,
                easeFrame=60,
                aimTable=name,
                aimKey='x',
                aimValue=500,
                easeMode='hard',
                progressFunc=function(x)return (2*x-1)^3*0.5+0.5 end
            }
            Event.EaseEvent{
                obj=name,
                easeFrame=60,
                aimTable=name,
                aimKey='fontSize',
                aimValue=fontSize,
                progressFunc=function(x)return math.sin(x*math.pi) end
            }
            Event.EaseEvent{
                obj=name,
                easeFrame=60,
                aimTable=name.color,
                aimKey=4,
                aimValue=0.5,
                progressFunc=function(x)return math.sin(x*math.pi) end
            }
        end
        makeLevelRef()
        -- show timeout spellcard text
        do
            if G.levelIsTimeoutSpellcard then
                local txt=Text{x=300,y=400,width=600,height=100,bordered=false,text=Localize{'ui','timeout'},fontSize=72,color={1,1,1,0},align='center',anchor='c',lifeFrame=60}
                Event.EaseEvent{
                    obj=txt,
                    easeFrame=60,
                    aimTable=txt,
                    aimKey='x',
                    aimValue=500,
                    easeMode='hard',
                    progressFunc=function(x)return (2*x-1)^3*0.5+0.5 end
                }
                Event.EaseEvent{
                    obj=txt,
                    easeFrame=60,
                    aimTable=txt.color,
                    aimKey=4,
                    aimValue=0.3,
                    progressFunc=function(x)return math.sin(x*math.pi) end
                }
            end
        end

        -- apply upgrades
        local options=G.UIDEF.UPGRADES.options
        for k,value in ipairs(options) do
            for i,option in pairs(value) do
                if option.upgrade and G.save.upgrades[i] and G.save.upgrades[i][k] and G.save.upgrades[i][k].bought==true then
                    G.UIDEF.UPGRADES.upgrades[option.upgrade].executeFunc()
                end
            end
        end
    end
end

--- load level data at /levels/level[levelStr]/scene[sceneStr].lua
---@param levelStr string|number
---@param sceneStr string|number
---@return LevelData
local function loadLevel(levelStr,sceneStr)
    ---@type LevelData
    local levelData=require("levels.level"..levelStr..".scene"..sceneStr)
    if not levelData.make then
        error("make function is not defined in level "..levelStr..", scene "..sceneStr)
    end
    if not levelData.ID then
        error("ID is not defined in level "..levelStr..", scene "..sceneStr)
    end
    wrapLevelMake(levelData)
    return levelData
end


local function loadLevels(levelStr,sceneStrList)
    local levels={}
    for i,sceneStr in ipairs(sceneStrList) do
        local level=loadLevel(levelStr,sceneStr)
        if level then
            table.insert(levels,level)
        end
    end
    return levels
end
-- currently levels are randomly stored, and need to be reorganized after majority of levels are done. The draft of final arrangement is as follows:
-- main idea: similar to original game, characters are sorted by the stage they appear in the original game. Like fan-game "Shatter All Spell Card", it's a good idea to add secret levels and unlock secret upgrades.
-- level 1: doremy's regular attack first (introduction), then doremy's spell, then protagonists like reimu, marisa, sakuya, sanae to give useful information. (yuugi should be moved to later levels)
-- level 2-4: characters from stage 1-3. 
-- level 5: introduce the follow view and broader move area. Let doremy introduce is fine, or maybe seiga (霍 青娥).
-- level 6-9: characters from stage 4-EX.
-- level 10: introduce boardless levels? I really wonder if this leads to interesting gameplay.
-- (an idea for boardless level: player needs to go far away then return to initial place. Without compass it's very difficult in hyperbolic world.)
-- level EX: protagonists' spells again.
-- some other idea: pun on the game name "soukyokuiki", where "soukyo" could be "壮挙", "soukyoku" could be "箏曲""双極", "kyokuiki" could be "局域". "箏曲域" can cue the mastermind is related to koto (yatsuhashi tsukumo), and "双極" relates to tsukumo sisters. nice idea. "奏曲""葬曲" are also good.
local levelData={
    loadLevels(1,{'1','2','3','4','5','6'}),
    loadLevels(2,{'1','2','3','4','5','6','7'}),
    loadLevels(3,{'1','2','3','4','5','6','7'}),
    loadLevels(4,{'1','2','3','4','5','6','7','8'}),
    loadLevels(5,{'1','2','3','4','5','6','7','8'}),
    loadLevels(6,{'1','2','3','4','5','6','7','8'}),
    loadLevels(7,{'1','2','3','4','5','6','7','8','9'}),
    loadLevels(8,{'1'}),
}

local ID2LevelScene={}
for i,level in ipairs(levelData) do
    for j,scene in ipairs(level) do
        if scene.ID then
            if ID2LevelScene[scene.ID] then
                error("ID "..scene.ID.." is not unique! It is assigned in level "..ID2LevelScene[scene.ID].level..", scene "..ID2LevelScene[scene.ID].scene.." and level "..i..", scene "..j)
            end
            ID2LevelScene[scene.ID]={level=i,scene=j}
        else
            error("ID is not assigned in level "..i..", scene "..j) -- though, above code has already checked this
        end
    end
end
levelData.ID2LevelScene=ID2LevelScene

levelData.needPass={3,6,9,12,16,20,25,30}
levelData.defaultQuote='What will happen here?'
return levelData