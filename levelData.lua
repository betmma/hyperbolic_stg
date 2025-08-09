---@class LevelData
---@field ID number unique ID of this level. It's to make a map between ID and level-scene, which is used to look up replay level-scene and localizations. Will raise an error if not assigned or not unique.
-- (further elaboration: the relationship between level-scene and ID is calculated after loading all levels in the definition of levelData below)
---@field user string the character of this scene. Is used to look up name in localization file.
---@field make fun():nil core of level
---@field leave fun():nil | nil do things when leaving the level, like recover modified global things, or secret unlocks
---@field quote string | nil After implementation of localization, this field is not used in game. It's only for coding reference.
---@field spellName string | nil Same as above
---@field bgm string | nil the name of the background music of this level. If not assigned, will use default BGM based on level.


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

---@return LevelData[]
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
--[[
current level arrangement (outdated):
level 1: doremy 1-1 to 1-4, 1-5 to 1-6 is mike goutokuji
level 2: nemuno sakata 2-1 to 2-2, takane yamashiro 2-3 to 2-4, cirno 2-5 to 2-6
these two levels are most of small map levels (except for yuugi's)
add a scene in level 3 to introduce the follow view and broader move area by seiga (霍 青娥).
level 3: stage 1 characters. 3-1 3-2 mystia lorelei, 3-3 3-4 3-5 chirizuka ubame, 3-6 3-7 eika ebisu
level 4: stage 2 characters. 4-1 4-2 houjuu chimi, 4-3 4-4 4-5 urumi ushizaki
level 5: stage 3 characters, 5-1 5-2 kawashiro nitori, 5-3 5-4 michigami sureko, 5-5 5-6 yuugi hoshiguma
level 6: stage 4 characters, 6-1 6-2 shameimaru aya, 6-3 to 6-5 patchouli knowledge, 6-6 6-7 minamitsu murasa
level 7: stage 5 characters, 7-1 7-2 kijin seija, 7-3 7-4 toramaru shou, 7-5 7-6 udongein reisen 7-7 7-8 clownpiece
level 8: protagonists. 8-1 to 8-3 youmu konpaku, 8-4 8-5 sakuya izayoi
level 9: stage 6 characters, 9-1 9-2 reiuji utsuho, 9-3 9-4 haniyasushin keiki, 9-5 to 9-7 motara okina
level 10: stage EX characters, 10-1 to 10-3 yakumo yukari, 10-4 10-5 flandre scarlet, 10-6 10-7 usami renko
level EX: not categorized spell cards (temporary). EX-1 remilia (original 3-1), EX-2 suwako ring reference, EX-3 eirin remember direction, EX-4 hina ring, EX-5 alice many bullets, EX-6 junko
]]
-- some other idea: pun on the game name "soukyokuiki", where "soukyo" could be "壮挙", "soukyoku" could be "箏曲""双極", "kyokuiki" could be "局域". "箏曲域" can cue the mastermind is related to koto (yatsuhashi tsukumo), and "双極" relates to tsukumo sisters. nice idea. "奏曲""葬曲" are also good.
-- th20's new characters are interesting, and it's such a coincidence that th20 is related to a place called "seiiki", so the plot could be related to it. 
local levelData={
    loadLevels(1,{'1','2','3','4','5','6'}),
    loadLevels(2,{'1','2','3','4','5','6'}),
    loadLevels(3,{'1','2','3','4','5','6','7'}),
    loadLevels(4,{'1','2','3','4','5','6','7','8'}),
    loadLevels(5,{'1','2','3','4','5','6','7','8'}),
    loadLevels(6,{'1','2','3','4','5','6','7'}),
    loadLevels(7,{'1','2','3','4','5','6','7','8'}),
    loadLevels(8,{'1','2','3','4','5','6','7','8'}),
    loadLevels(9,{'1','2','3','4','5','6','7','8'}),
    loadLevels(10,{'1','2','3','4','5','6','7','8'}),
    loadLevels('EX',{'1','2','5','6','7','8','9',}),
}

---@type {id:{level:number,scene:number}}
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

levelData.needPass={3,6,9,12,16,22,30,40,50,60,70,80}
levelData.defaultQuote='What will happen here?'

---@return string
levelData.getBGMName=function(level,scene)
    local levelData=levelData[level][scene]
    if levelData and levelData.bgm then
        return levelData.bgm
    end
    if level<6 then
        return 'level1'
    end
    return 'level2'
end
return levelData