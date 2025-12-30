---@class PosXY
---@field x number 
---@field y number 

---@alias Pos number[]

---@class Upgrade
---@field cost number exp needed to buy it
---@field executeFunc fun(player):nil function to execute when entering a level
---@field spritePos PosXY position of the sprite in upgrades.png
---@field name string|nil name of this upgrade (actual value is in localization file, so not needed)
---@field description string|nil description of this upgrade (same as above)

---@class UpgradeNode stores data of an upgrade in the upgrade tree
---@field pos PosXY position of this upgrade in the upgrade tree
---@field requires string[] list of upgrade names that are prerequisite for this upgrade
---@field connect table<string,boolean> table of upgrade names that are connected to this cell (one requires the other). automatically generated.

---@class UpgradeTreeCell
---@field upgrade string key of the upgrade in upgrades table.

local upgrades={}

---@type table<string,Upgrade>
local data = {
    -- Warning: real texts are in localization.lua. Following texts are for coding reference only.
    increaseHP={
        name='Increase HP',
        description='Increase HP by 1',
        cost=30,
        executeFunc=function(player)
            player.hp=player.hp+1
            player.maxhp=player.maxhp+1
        end,
        spritePos={x=0,y=0}
    },
    regenerate={
        name='Regenerate',
        description='Increase HP by 0.024 per second',
        cost=40,
        executeFunc=function(player)
            player.hpRegen=player.hpRegen+0.024
        end,
        spritePos={x=1,y=0}
    },
    unyielding={
        name='Unyielding',
        description='Shockwave when you are hit is bigger',
        cost=30,
        executeFunc=function(player)
            player.dieShockwaveRadius=player.dieShockwaveRadius+1
        end,
        spritePos={x=2,y=0}
    },
    acrobat={ -- add a scene that costs HP when grazing, and unlock this upgrade for it
        name='Acrobat',
        description='Each graze gives 0.005 HP',
        cost=40,
        executeFunc=function(player)
            player.grazeHpRegen=player.grazeHpRegen+0.005
        end,
        spritePos={x=3,y=0}
    },
    flashbomb={
        name='Flash Bomb',
        description='Release a flash bomb for every 100 grazes',
        cost=50,
        executeFunc=function(player)
            player.enableFlashbomb=true
            player.grazeReqForFlashbomb=100
            player.flashbombWidth=5
        end,
        spritePos={x=4,y=0}
    },
    amulet={
        name='Amulet',
        description='Player hitbox is 25% smaller',
        cost=50,
        executeFunc=function(player)
            player.radius = player.radius*0.75
        end,
        spritePos={x=5,y=0}
    },
    homingShot={
        name='Homing Shot',
        description='2 rows of your shot become homing',
        cost=50,
        executeFunc=function(player)
            local frontStraight=player:findShootType('front','straight')
            frontStraight.num=frontStraight.num-2
            local frontHoming=player:findShootType('front','homing')
            frontHoming.num=frontHoming.num+2
        end,
        spritePos={x=6,y=0}
    },
    sideShot={
        name='Side Shot',
        description='Add 4 rows of side shot (on each side)',
        cost=30,
        executeFunc=function(player)
            local sideStraight=player:findShootType('side','straight')
            sideStraight.num=sideStraight.num+4
        end,
        spritePos={x=7,y=0}
    },
    backShot={
        name='Back Shot',
        description='Add 4 rows of back shot that do double damage',
        cost=50,
        executeFunc=function(player)
            local backStraight=player:findShootType('back','straight')
            backStraight.num=backStraight.num+4
        end,
        spritePos={x=0,y=1}
    },
    familiarShot={
        name='Familiar Shot',
        description='Your shots can hit enemy\'s familiars and do 1/4 damage',
        cost=40,
        executeFunc=function(player)
            player.canHitFamiliar=true
            player.hitFamiliarDamageFactor=0.25
        end,
        spritePos={x=1,y=1}
    },
    vortex={
        name='Vortex',
        description='A vortex rounding you that can absorb bullets',
        cost=60,
        executeFunc=function(player)
            Event.LoopEvent{
                obj=player,
                period=1,
                executeFunc=function(self,executedTimes)
                    if player.cancelVortex then
                        return
                    end
                    local x,y=player.x,player.y
                    local theta=0.02*(player.time*60-1)
                    local r=20
                    local nx,ny=Shape.rThetaPos(x,y,r,theta)
                    local vortex=Effect.Shockwave{x=nx,y=ny,radius=2,canRemove={bullet=true,invincible=false,safe=false},animationFrame=1}
                    vortex.scale=2
                    vortex.direction=theta*5
                    vortex.sprite=Asset.bulletSprites.orb.red
                    player.vortex=vortex
                end
            }
        end,
        spritePos={x=2,y=1}
    },
    fixedHPDisplay={
        name='Fixed HP Display',
        description='Show enemy HP at the top of the screen. (Wow, this is an upgrade?)', -- useful when enemy is off screen, specifically in 6-5 phase 3 where enemy is always at opposite direction of player, and player's projectiles go awry, with this upgrade it's easier to know if the shot is hitting the enemy. (Though I've raised the hitting sfx volume at that phase, adding a visual cue is still better)
        cost=10,
        executeFunc=function()
            local enemy=G.mainEnemy
            if enemy then
                enemy.showUpperHPBar=true
            end
        end,
        spritePos={x=3,y=1}
    },
    clairvoyance={
        name='Clairvoyance',
        description='Widen your vision, somewhat',
        cost=40,
        executeFunc=function()
            G.foregroundTransparency=0.8
        end,
        spritePos={x=4,y=1}
    },
    diagonalMover={
        name='Diagonal Mover',
        description='You move faster when moving diagonally',
        cost=30,
        executeFunc=function(player)
            player.diagonalSpeedAddition=true
        end,
        spritePos={x=5,y=1}
    },
    homingShotII={
        name='Homing Shot II',
        description='2 more rows of your shot become homing, but homing effect is reduced',
        cost=50,
        executeFunc=function(player)
            local frontStraight=player:findShootType('front','straight')
            frontStraight.num=frontStraight.num-2
            local frontHoming=player:findShootType('front','homing')
            frontHoming.num=frontHoming.num+2
            player.homingMode='portion'
            player.homingArg=0.07
        end,
        spritePos={x=6,y=1}
    },
    sideShotII={
        name='Side Shot II',
        description='Increase side shot damage by 50%, but they spread more',
        cost=50,
        executeFunc=function(player)
            local sideStraight=player:findShootType('side','straight')
            sideStraight.damage=sideStraight.damage*1.5
            sideStraight.spread=sideStraight.spread+0.1
        end,
        spritePos={x=7,y=1}
    },
    backShotII={
        name='Back Shot II',
        description='Increase back shot damage by 50%, but they do less damage if you are close to enemy',
        cost=50,
        executeFunc=function(player)
            local backStraight=player:findShootType('back','straight')
            backStraight.damage=backStraight.damage*1.5
            backStraight.readyFrame=30
        end,
        spritePos={x=0,y=2}
    },
    counterShot={
        name='Counter Shot',
        description='You can shoot during invincible time after being hit',
        cost=70,
        executeFunc=function(player)
            player.canShootDuringInvincible=true
        end,
        spritePos={x=1,y=2}
    },
    diskModels={
        name='Disk Models',
        description='Unlock Poincare Disk and Klein Disk models. Press E in level to switch models.',
        cost=50,
        executeFunc=function(player)
            player.unlockDiskModels=true
        end,
        spritePos={x=2,y=2}
    },
    instantRetry={
        name='Instant Retry',
        description='When hurt, instantly retry the scene without pressing any key. For the perfectionist lazy player!',
        cost=20,
        executeFunc=function(player)
            player.instantRetry=true
        end,
        spritePos={x=3,y=2}
    },
    emergencyBomb={
        name='Emergency Bomb',
        description='Press C to use flash bomb without filling the graze bar, but each graze missing costs 0.01 HP. It counts as being hit.',
        cost=60,
        executeFunc=function(player)
            player.emergencyBomb=true
            player.emergencyBombCostPerGraze=0.01
        end,
        spritePos={x=4,y=2}
    },
    accumulativeBomb={
        name='Accumulative Bomb',
        description='You can store multiple flash bombs and use them manually by pressing C.',
        cost=50,
        executeFunc=function(player)
            player.accumulativeFlashbomb=true
        end,
        spritePos={x=5,y=2}
    },
    spareBomb={
        name='Spare Bomb',
        description='Start each scene with 1 flash bomb.',
        cost=30,
        executeFunc=function(player)
            player.grazeCountForFlashbomb=player.grazeCountForFlashbomb+player.grazeReqForFlashbomb
        end,
        spritePos={x=6,y=2}
    },
    sensitiveOrb={
        name='Sensitive Orb',
        description='Bullets absorbed by Yin-Yang Orb count as grazes.',
        cost=40,
        executeFunc=function(player)
            EventManager.listenTo(EventManager.EVENTS.SHOCKWAVE_REMOVE_BULLET, function(bullet,shockwave)
                if player.vortex==shockwave then
                    EventManager.post(EventManager.EVENTS.PLAYER_GRAZE,player,bullet:grazeValue())
                end
            end,EventManager.EVENTS.LEAVE_LEVEL)
        end,
        spritePos={x=7,y=2}
    },
}
upgrades.data=data


--- it seems that below data can be placed in upgrades.data. but if there is second character with different upgrade tree while reusing some upgrades, then split upgrades data and tree data is good.
---@type table<string, UpgradeNode>
local nodes = {
    increaseHP =  {connect = {}, pos = {x=1, y=1}, requires = {} },
    regenerate =  {connect = {}, pos = {x=2, y=1}, requires = {'increaseHP'} },
    unyielding =  {connect = {}, pos = {x=2, y=2}, requires = {'regenerate'} },
    acrobat =     {connect = {}, pos = {x=3, y=1}, requires = {'regenerate'} },
    flashbomb =   {connect = {}, pos = {x=4, y=1}, requires = {'acrobat'} },
    emergencyBomb={connect = {}, pos = {x=4, y=2}, requires = {'flashbomb'} },
    accumulativeBomb={connect = {}, pos = {x=5, y=2}, requires = {'flashbomb'} },
    spareBomb =     {connect = {}, pos = {x=6, y=2}, requires = {'accumulativeBomb'} },
    vortex =      {connect = {}, pos = {x=5, y=1}, requires = {'flashbomb'} },
    sensitiveOrb= {connect = {}, pos = {x=6, y=1}, requires = {'vortex'} },
    homingShot =  {connect = {}, pos = {x=1, y=3}, requires = {} },
    sideShot =    {connect = {}, pos = {x=3, y=3}, requires = {'homingShot'} },
    backShot =    {connect = {}, pos = {x=3, y=4}, requires = {'homingShot'} },
    familiarShot = {connect = {}, pos = {x=4, y=3}, requires = {'sideShot', 'backShot'} },
    homingShotII = {connect = {}, pos = {x=6, y=3}, requires = {'familiarShot'} },
    sideShotII =   {connect = {}, pos = {x=6, y=4}, requires = {'familiarShot'} },
    backShotII =   {connect = {}, pos = {x=6, y=5}, requires = {'familiarShot'} },
    counterShot =  {connect = {}, pos = {x=7, y=3}, requires = {'homingShotII', 'sideShotII', 'backShotII'} },
    amulet =         {connect = {}, pos = {x=1, y=5}, requires = {} },
    fixedHPDisplay = {connect = {}, pos = {x=2, y=5}, requires = {'amulet'} },
    clairvoyance =   {connect = {}, pos = {x=3, y=5}, requires = {'fixedHPDisplay'} },
    diskModels =     {connect = {}, pos = {x=4, y=5}, requires = {'clairvoyance'} },
    diagonalMover =  {connect = {}, pos = {x=2, y=6}, requires = {'fixedHPDisplay'} },
    instantRetry =   {connect = {}, pos = {x=3, y=6}, requires = {'clairvoyance'} },
}

upgrades.nodes = nodes

---@type UpgradeTreeCell[][] for convenience of finding upgrade by position
local upgradesTree={}
for name,node in pairs(nodes) do
    local x,y=node.pos.x,node.pos.y
    upgradesTree[x]=upgradesTree[x] or {}
    upgradesTree[x][y]=upgradesTree[x][y] or {}
    upgradesTree[x][y].upgrade=name
end
for name,node in pairs(nodes) do
    local requires=node.requires
    for i,req in ipairs(requires) do
        local reqNode=nodes[req]
        -- add connection in both cells
        node.connect[req]=true
        reqNode.connect[name]=true
    end
end

upgrades.upgradesTree=upgradesTree

-- helper functions

--- check if all prerequisite upgrades are bought
---@param upgrade string key of the upgrade in upgrades.data
---@return boolean true if all prerequisite upgrades are bought
upgrades.needSatisfied=function(upgrade)
    local node=Upgrades.nodes[upgrade]
    for key, value in pairs(node.requires) do
        if G.save.upgrades[value].bought==false then
            return false
        end
    end
    return true
end

--- calculate current available XP (total earned XP - total spent XP)
---@return number available XP
upgrades.calculateRestXP=function()
    local xp=0
    for id,value in pairs(LevelData.ID2LevelScene) do
        local pass=G.save.levelData[id].passed
        if pass==1 then
            xp=xp+10
        elseif pass==2 then
            xp=xp+12
        end
    end
    for name,upgrade in pairs(Upgrades.data) do
        if G.save.upgrades[name].bought then
            xp=xp-upgrade.cost
        end
    end
    return xp
end


---@param upgrade string key of the upgrade in upgrades.data
---@param dir 'up'|'down'|'left'|'right'
---@return string nextUpgrade the upgrade moved to
upgrades.moveToNode=function(upgrade,dir)
    local currentNode=upgrades.nodes[upgrade]
    local x,y=currentNode.pos.x,currentNode.pos.y
    local dirx,diry=DirectionName2Dxy(dir)
    local bestFitUpgrade,bestFitValue=upgrade,-500
    -- 
    for name,node in pairs(upgrades.nodes) do
        if name==upgrade then -- dont recalculate self
            goto continue
        end
        if not upgrades.needSatisfied(name) then -- can't go to an upgrade that is not available
            goto continue
        end
        local nx,ny=node.pos.x,node.pos.y
        local deltax, deltay = nx-x, ny-y
        local isConnected=node.connect[name]
        local score=0
        if isConnected then
            score=score+2.5 -- prefer connected nodes
        end
        local distance=math.sqrt(deltax*deltax+deltay*deltay)
        score=score-distance*2 -- prefer closer nodes
        local angle=math.angleDiff(math.atan2(deltay,deltax),math.atan2(diry,dirx))
        if angle>math.pi*0.49 then
            score=score-1000 -- don't go backwards (worse than staying still). pi*0.49 is to prevent /0 below
        else
            score=score-5/math.cos(angle)
        end
        if score>bestFitValue then
            bestFitValue=score
            bestFitUpgrade=name
        end
        ::continue::
    end
    return bestFitUpgrade
end

return upgrades