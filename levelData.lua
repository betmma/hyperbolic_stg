---@class LevelData
---@field ID number unique ID of this level. It's to make a map between ID and level-scene, which is used to look up replay level-scene and localizations. Will raise an error if not assigned or not unique.
-- (further elaboration: the relationship between level-scene and ID is calculated after loading all levels in the definition of levelData below)
---@field user string the character of this scene. Is used to look up name in localization file.
---@field dialogue string|nil key in localization.dialogues, if exists, dialogue will be shown before the level starts
---@field unlock fun():boolean | nil function that returns whether this level is unlocked. If not assigned, considered always unlocked.
---@field make fun():nil core of level (danmaku)
---@field leave fun():nil | nil do things when leaving the level, like recover modified global things, or secret unlocks
---@field quote string | nil After implementation of localization, this field is not used in game. It's only for coding reference.
---@field spellName string | nil Same as above
---@field bgm string | nil the name of the background music of this level. If not assigned, will use default BGM based on level.


local Text=require"text"

-- some wrapping work for each scene
---@param levelData LevelData
local function wrapLevelMake(levelData)
    local makeLevelRef=levelData.make
    local makeLevelWrapped=function()
        local replay=G.replay or {}
        local seed = replay.seed or math.floor(os.time()+os.clock()*1337)
        math.randomseed(seed)
        G.randomseed=seed
        Shape.timeSpeed=1
        G.viewMode.mode=G.CONSTANTS.VIEW_MODES.NORMAL
        G.viewMode.viewOffset={x=0,y=0}
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
            Event.LoopEvent{
                obj=txt,period=1,frame=-120,executeFunc=function(self) -- after above ease events
                    if G.viewMode.mode==G.CONSTANTS.VIEW_MODES.NORMAL and Player.objects[1] then
                        txt.color[4]=math.clamp(math.abs(txt.y-Player.objects[1].y)/75,0.2,1)
                    end
                end
            }
        end
        -- show user (boss) name
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
        -- show boss sprite if exists
        do
            local user=levelData.user
            local sprite=Asset.boss[user]
            if sprite then
                local distance=300
                local frame,moveFrame=120,30
                local angle=-math.pi/9
                local x0,y0=WINDOW_WIDTH/2+distance*math.cos(angle),WINDOW_HEIGHT/2+distance*math.sin(angle)
                local dummyShape=Shape{x=x0,y=y0,speed=distance/moveFrame,direction=0,lifeFrame=frame}
                dummyShape.updateMove=function(self)
                    if self.frame>=moveFrame and self.frame<frame-moveFrame then
                        return
                    end
                    self.x = self.x - self.speed*math.cos(angle)
                    self.y = self.y - self.speed*math.sin(angle)
                end
                dummyShape.drawText=function(self)
                    local x,y=self.x,self.y
                    local r,g,b,a=love.graphics.getColor()
                    love.graphics.setColor(1,1,1,math.sin(self.frame/frame*math.pi)*0.7)
                    love.graphics.draw(Asset.bossImage,sprite.normal[1],x,y,0,8,8,Asset.boss.width/2,Asset.boss.height/2)
                    love.graphics.setColor(r,g,b,a)
                end
            end
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

        local player=Player.objects[1]
        -- apply upgrades
        local upgrades=Upgrades.dataList
        for _,v in ipairs(upgrades) do
            if G.save.upgrades[v.id] and G.save.upgrades[v.id].bought then
                v.executeFunc(player)
                player.hasUpgrade=true
            end
        end

        G.levelRemainingFrame=G.levelRemainingFrame or 3600
        G.levelRemainingFrameMax=G.levelRemainingFrame
        if G.replay then
            ReplayManager.replayTweak(G.replay)
        end
    end
    levelData.make=function()
        if levelData.dialogue and not G.replay and (G.save.levelData[levelData.ID].tryCount==0 or G.replayDialogue) then -- first time playing this level or holding lshift to watch dialogue again
            local dialogueController=DialogueController{key=levelData.dialogue}
            dialogueController.afterFunc=makeLevelWrapped
        else
            makeLevelWrapped()
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
    levels.levelStr=levelStr
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
    loadLevels(1,{'1','2','3','4','5','6','7'}),
    loadLevels(2,{'1','2','3','4','5','6','7'}),
    loadLevels(3,{'1','2','3','4','5','6','7','8'}),
    loadLevels(4,{'1','2','3','4','5','6','7','8'}),
    loadLevels(5,{'1','2','3','4','5','6','7','8'}),
    loadLevels(6,{'1','2','3','4','5','6','7','8'}),
    loadLevels(7,{'1','2','3','4','5','6','7','8','9'}),
    loadLevels(8,{'1','2','3','4','5','6','7','8'}),
    loadLevels(9,{'1','2','3','4','5','6','7','8','9'}),
    loadLevels(10,{'1','2','3','4','5','6','7','8','9','10'}),
    loadLevels(11,{'1','2','3','4','5','6','7','8'}),
    loadLevels(12,{'1','2','3','4','5','6','7','8','9'}),
    loadLevels('EX',{'1','2','3','4','5','7'}),
}

---@param level integer
---@return string 
--- get the level string of a level, like EX is stored as level 11 but displayed as "EX"
levelData.getLevelStr=function(level)
    ---@type {levelStr:string}
    local levelData=levelData[level]
    return levelData and levelData.levelStr or ''..level
end

---@param level integer
---@return integer
--- get the number of visible scenes of a level. levels may have hidden scenes. level > levelUnlock is considered having 0 scenes.
levelData.getSceneNum=function(level)
    if level>G.save.levelUnlock then
        return 0
    end
    local leveldata=levelData[level]
    if leveldata then
        for i,scene in ipairs(leveldata) do
            local unlockFunc=scene.unlock
            if unlockFunc and not unlockFunc() then
                return i-1
            end
        end
        return #leveldata
    end
    return 0
end

---@param level integer
---@param scene integer
---@return number nextLevel
---@return number nextScene
---@return boolean isNextExist
levelData.getNextLevelScene=function(level,scene)
    local sceneNum=levelData.getSceneNum(level)
    if scene<sceneNum then
        return level,scene+1,true
    else
        return level+1,1,levelData.getSceneNum(level+1)>0
    end
end

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

levelData.needPass={3,6,9,12,16,22,30,40,50,60,70,80,85}
levelData.defaultQuote='What will happen here?'

---@return string
levelData.getBGMName=function(level,scene)
    local levelData=levelData[level][scene]
    if levelData and levelData.bgm then
        return levelData.bgm
    end
    if level<=2 then
        return 'level1'
    end
    if level>=3 and level<=4 then
        return 'level2'
    end
    if level>=5 and level<=7 then
        return 'level3'
    end
    if level>=8 and level<=9 then
        return 'level4'
    end
    if level>=10 and level<=11 or level==13 then
        return 'level5'
    end
    if level==12 then
        return 'level6'
    end
    return 'level1'
end

--- get the default background class of a level-scene
levelData.getDefaultBackground=function(level,scene)
    if level<=2 then
        return BackgroundPattern.DreamWorld
    end
    if level>=3 and level<=4 then
        return BackgroundPattern.H3Terrain
    end
    if level>=5 and level<=7 then
        return BackgroundPattern.YoukaiMountain
    end
    if level>=8 and level<=9 then
        return function() return BackgroundPattern.Honeycomb{inverse=true} end
    end
    if level>=10 and level<=11 or level==13 then
        return BackgroundPattern.Honeycomb
    end
    if level==12 then
        if scene<=5 then
            return BackgroundPattern.Stage
        end
        return function() return BackgroundPattern.Stage{holeSize=scene-5} end
    end
    return BackgroundPattern.FollowingTesselation
end

-- some common functions used for initializing levels
levelData.initFuncs={

}
return levelData