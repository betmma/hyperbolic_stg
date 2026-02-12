---@class PosXY
---@field x number 
---@field y number 

---@alias Pos number[]

---@class Upgrade
---@field id string unique key of this upgrade
---@field cost number exp needed to buy it
---@field executeFunc fun(player):nil function to execute when entering a level
---@field spritePos PosXY position of the sprite in upgrades.png
---@field description string|nil description of this upgrade (actual value is in localization file, so not needed)

---@class UpgradeNode stores data of an upgrade in the upgrade tree
---@field pos PosXY position of this upgrade in the upgrade tree
---@field requires string[] list of upgrade names that are prerequisite for this upgrade
---@field connect table<string,boolean> table of upgrade names that are connected to this cell (one requires the other). automatically generated.

---@class UpgradeTreeCell
---@field upgrade string key of the upgrade in upgrades table.

local upgrades={}

---@type table<string,Upgrade>
local dataList = {
    {
        id='increaseHP',
        description='Increase HP by 1',
        cost=30,
        executeFunc=function(player)
            player.hp=player.hp+1
            player.maxhp=player.maxhp+1
        end,
        spritePos={x=0,y=0}
    },
    {
        id='increaseHPAgain',
        description='Increase HP by 1 again',
        cost=50,
        executeFunc=function(player)
            player.hp=player.hp+1
            player.maxhp=player.maxhp+1
        end,
        spritePos={x=0,y=0}
    },
    {
        id='regenerate',
        description='Increase HP by 0.024 per second',
        cost=40,
        executeFunc=function(player)
            player.hpRegen=player.hpRegen+0.024
        end,
        spritePos={x=1,y=0}
    },
    {
        id='unyielding',
        description='Shockwave when you are hit is bigger',
        cost=30,
        executeFunc=function(player)
            player.dieShockwaveRadius=player.dieShockwaveRadius+1
        end,
        spritePos={x=2,y=0}
    },
    {
        id='acrobat', -- add a scene that costs HP when grazing, and unlock this upgrade for it
        name='Acrobat',
        description='Each graze gives 0.005 HP',
        cost=40,
        executeFunc=function(player)
            player.grazeHpRegen=player.grazeHpRegen+0.005
        end,
        spritePos={x=3,y=0}
    },
    {
        id='flashbomb',
        description='Release a flash bomb for every 100 grazes',
        cost=50,
        executeFunc=function(player)
            player.enableFlashbomb=true
            player.grazeReqForFlashbomb=100
            player.flashbombWidth=5
        end,
        spritePos={x=4,y=0}
    },
    {
        id='amulet',
        description='Player hitbox is 25% smaller',
        cost=50,
        executeFunc=function(player)
            player.radius = player.radius*0.75
        end,
        spritePos={x=5,y=0}
    },
    {
        id='homingShot',
        description='2 rows of your shot become homing',
        cost=30,
        executeFunc=function(player)
            local frontStraight=player:findShootType('front','straight')
            frontStraight.num=frontStraight.num-2
            local frontHoming=player:findShootType('front','homing')
            frontHoming.num=frontHoming.num+2
        end,
        spritePos={x=6,y=0}
    },
    {
        id='sideShot',
        description='Add 4 rows of side shot (on each side)',
        cost=30,
        executeFunc=function(player)
            local sideStraight=player:findShootType('side','straight')
            sideStraight.num=sideStraight.num+4
        end,
        spritePos={x=7,y=0}
    },
    {
        id='backShot',
        description='Add 4 rows of back shot that do double damage',
        cost=50,
        executeFunc=function(player)
            local backStraight=player:findShootType('back','straight')
            backStraight.num=backStraight.num+4
        end,
        spritePos={x=0,y=1}
    },
    {
        id='familiarShot',
        description='Your shots can hit enemy\'s familiars and do 1/2 damage',
        cost=20,
        executeFunc=function(player)
            player.canHitFamiliar=true
            player.hitFamiliarDamageFactor=0.5
        end,
        spritePos={x=1,y=1}
    },
    {
        id='vortex',
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
                    vortex.isYinYangOrb=true
                    player.vortex=vortex
                end
            }
            EventManager.listenTo(EventManager.EVENTS.SHOCKWAVE_REMOVE_BULLET, function(bullet,shockwave)
                if player.vortex==shockwave then
                    EventManager.post(EventManager.EVENTS.YINYANG_ORB_REMOVE_BULLET,bullet,shockwave)
                end
            end,EventManager.EVENTS.LEAVE_LEVEL)
        end,
        spritePos={x=2,y=1}
    },
    {
        id='fixedHPDisplay',
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
    {
        id='clairvoyance',
        description='Widen your vision, somewhat',
        cost=40,
        executeFunc=function()
            G.foregroundTransparency=0.8
        end,
        spritePos={x=4,y=1}
    },
    {
        id='diagonalMover',
        description='You move faster when moving diagonally',
        cost=30,
        executeFunc=function(player)
            player.diagonalSpeedAddition=true
        end,
        spritePos={x=5,y=1}
    },
    {
        id='homingShotII',
        description='2 more rows of your shot become homing, but homing effect is reduced',
        cost=50,
        executeFunc=function(player)
            local frontStraight=player:findShootType('front','straight')
            frontStraight.num=frontStraight.num-2
            local frontHoming=player:findShootType('front','homing')
            frontHoming.num=frontHoming.num+2
            player.homingMode='portion'
            player.homingArg=0.09
        end,
        spritePos={x=6,y=1}
    },
    {
        id='sideShotII',
        description='Increase side shot damage by 50%, but they spread more',
        cost=50,
        executeFunc=function(player)
            local sideStraight=player:findShootType('side','straight')
            sideStraight.damage=sideStraight.damage*1.5
            sideStraight.spread=sideStraight.spread+0.1
        end,
        spritePos={x=7,y=1}
    },
    {
        id='backShotII',
        description='Increase back shot damage by 50%, but they do less damage if you are close to enemy',
        cost=50,
        executeFunc=function(player)
            local backStraight=player:findShootType('back','straight')
            backStraight.damage=backStraight.damage*1.5
            backStraight.readyFrame=30
        end,
        spritePos={x=0,y=2}
    },
    {
        id='counterShot',
        description='You can shoot during invincible time after being hit',
        cost=20,
        executeFunc=function(player)
            player.canShootDuringInvincible=true
        end,
        spritePos={x=1,y=2}
    },
    {
        id='diskModels',
        description='Unlock Poincare Disk and Klein Disk models. Press E in level to switch models.',
        cost=50,
        executeFunc=function(player)
            player.unlockDiskModels=true
        end,
        spritePos={x=2,y=2}
    },
    {
        id='instantRetry',
        description='When hurt, instantly retry the scene without pressing any key. For the perfectionist lazy player!',
        cost=20,
        executeFunc=function(player)
            player.instantRetry=true
        end,
        spritePos={x=3,y=2}
    },
    {
        id='emergencyBomb',
        description='Press C to use flash bomb without filling the graze bar, but each graze missing costs 0.01 HP. It counts as being hit.',
        cost=60,
        executeFunc=function(player)
            player.emergencyBomb=true
            player.emergencyBombCostPerGraze=0.01
        end,
        spritePos={x=4,y=2}
    },
    {
        id='accumulativeBomb',
        description='You can store multiple flash bombs and use them manually by pressing C.',
        cost=50,
        executeFunc=function(player)
            player.accumulativeFlashbomb=true
        end,
        spritePos={x=5,y=2}
    },
    {
        id='spareBomb',
        description='Start each scene with 1 flash bomb.',
        cost=30,
        executeFunc=function(player)
            player.grazeCountForFlashbomb=player.grazeCountForFlashbomb+player.grazeReqForFlashbomb
        end,
        spritePos={x=6,y=2}
    },
    {
        id='sensitiveOrb',
        description='Bullets absorbed by Yin-Yang Orb count as grazes.',
        cost=40,
        executeFunc=function(player)
            EventManager.listenTo(EventManager.EVENTS.YINYANG_ORB_REMOVE_BULLET, function(bullet,shockwave)
                EventManager.post(EventManager.EVENTS.PLAYER_GRAZE,player,bullet:grazeValue())
            end,EventManager.EVENTS.LEAVE_LEVEL)
        end,
        spritePos={x=7,y=2}
    },
    {
        id='ring',
        description='Your shots become rings',
        cost=50,
        executeFunc=function(player)
            player.shootMode=Player.shootModes.Charge
            player.shootRows={
                {
                    mode='ring',
                    baseDamage=15,
                    growRate=2,
                    width=10,
                    radiusBase=10,
                    minimumChargeFrame=20,
                    maximumChargeFrame=120,
                    shootFunc=function(self,player,chargeFrame)
                        --[[ dps data:
                            previous maximum (4 backrows + 2 homing) is 4*6*1.5 (with II) + 2*3 = 42 damage per shoot interval (3 frames) = 840 dps
                            but, many spellcards force to only use homing, then minimum is only 120 dps
                            ring dps = baseDamage * lifeFrame * damageRatio / chargeFrame = 900 * (chargeFrame/60)^0.5 (before cap).
                            easy shoot (chargeFrame 30 frames) dps = 900 / sqrt(2) = ~636 dps
                            max dps (chargeFrame 120 frames) = 1272 dps
                            To hit enemy, the time offset range is +- (enemy radius + half ring width)/growRate = 15 frames
                            but many spellcards don't have large area, or enemy is moving, and charge every 2 seconds interrupts dodging so fair enough.
                        ]]
                        if chargeFrame<self.minimumChargeFrame then
                            return
                        end
                        chargeFrame=math.min(chargeFrame,self.maximumChargeFrame) -- cap charge time to 120 frames
                        local damageRatio=(chargeFrame/60)^1.5 -- should be greater than linear growth
                        Effect.Ring{
                            x=player.x,
                            y=player.y,
                            radius=self.radiusBase+chargeFrame*self.growRate,
                            width=self.width,
                            lifeFrame=60,
                            damage=self.baseDamage*damageRatio,
                            direction=0, -- not important
                            sprite=Asset.bulletSprites.snake.red
                        }
                    end
                }
            }
        end,
        spritePos={x=0,y=3}
    },
    {
        id='spiritTraining',
        description='invincible time after being hit increases by 0.5 seconds.',
        cost=40,
        executeFunc=function(player)
            player.hitInvincibleFrame=player.hitInvincibleFrame+30
        end,
        spritePos={x=1,y=3}
    },
    {
        id='esoterica',
        description='know secret nickname titles',
        cost=0, -- G.loadData will load from save. in upgrades menu it will be randomized
        executeFunc=function(player) -- do nothing in game
        end,
        spritePos={x=2,y=3}
    }
}
-- when need to apply upgrades in order, use this table
upgrades.dataList=dataList
---@type table<string,Upgrade> key is upgrade id
-- when need to find upgrade by id, use this table
upgrades.data={}
for _,upgrade in ipairs(dataList) do
    upgrades.data[upgrade.id]=upgrade
end


--- it seems that below data can be placed in upgrades.data. but if there is second character with different upgrade tree while reusing some upgrades, then split upgrades data and tree data is good.
---@type table<string, UpgradeNode>
local nodes = {
    increaseHP =  {connect = {}, pos = {x=1, y=1}, requires = {} },
    increaseHPAgain =  {connect = {}, pos = {x=1, y=2}, requires = {'increaseHP'} },
    regenerate =  {connect = {}, pos = {x=2, y=1}, requires = {'increaseHP'} },
    unyielding =  {connect = {}, pos = {x=2, y=2}, requires = {'regenerate'} },
    acrobat =     {connect = {}, pos = {x=3, y=1}, requires = {'regenerate'} },
    flashbomb =   {connect = {}, pos = {x=4, y=1}, requires = {'acrobat'} },
    emergencyBomb={connect = {}, pos = {x=4, y=2}, requires = {'flashbomb'} },
    accumulativeBomb={connect = {}, pos = {x=5, y=2}, requires = {'flashbomb'} },
    spareBomb =     {connect = {}, pos = {x=6, y=2}, requires = {'accumulativeBomb'} },
    vortex =      {connect = {}, pos = {x=5, y=1}, requires = {'flashbomb'} },
    sensitiveOrb= {connect = {}, pos = {x=6, y=1}, requires = {'vortex'} },
    spiritTraining={connect = {}, pos = {x=7, y=1}, requires = {'sensitiveOrb'} },
    homingShot =  {connect = {}, pos = {x=1, y=3}, requires = {} },
    sideShot =    {connect = {}, pos = {x=3, y=3}, requires = {'homingShot'} },
    backShot =    {connect = {}, pos = {x=3, y=4}, requires = {'homingShot'} },
    familiarShot = {connect = {}, pos = {x=4, y=3}, requires = {'sideShot', 'backShot'} },
    homingShotII = {connect = {}, pos = {x=6, y=3}, requires = {'familiarShot'} },
    sideShotII =   {connect = {}, pos = {x=6, y=4}, requires = {'familiarShot'} },
    backShotII =   {connect = {}, pos = {x=6, y=5}, requires = {'familiarShot'} },
    counterShot =  {connect = {}, pos = {x=7, y=4}, requires = {'homingShotII', 'sideShotII', 'backShotII'} },
    ring =         {connect = {}, pos = {x=8, y=4}, requires = {'counterShot'} },
    amulet =         {connect = {}, pos = {x=1, y=5}, requires = {} },
    fixedHPDisplay = {connect = {}, pos = {x=2, y=5}, requires = {'amulet'} },
    clairvoyance =   {connect = {}, pos = {x=3, y=5}, requires = {'fixedHPDisplay'} },
    diskModels =     {connect = {}, pos = {x=4, y=5}, requires = {'clairvoyance'} },
    esoterica =     {connect = {}, pos = {x=8, y=6}, requires = {'clairvoyance','spiritTraining'} },
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
    local earnedXP=xp
    for name,upgrade in pairs(Upgrades.data) do
        if G.save.upgrades[name].bought then
            xp=xp-upgrade.cost
        end
    end
    if earnedXP>=100 and xp==0 then -- used all xp, unlock secret nickname
        EventManager.post(EventManager.EVENTS.XP_USED_UP)
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