---@class PosXY
---@field x number 
---@field y number 

---@alias Pos number[]

---@class Connect
---@field left boolean|nil is connected to the left cell
---@field right boolean|nil 
---@field up boolean|nil
---@field down boolean|nil

---@class Upgrade
---@field cost number exp needed to buy it
---@field executeFunc fun():nil function to execute when entering a level
---@field spritePos PosXY position of the sprite in upgrades.png
---@field name string|nil name of this upgrade (actual value is in localization file, so not needed)
---@field description string|nil description of this upgrade (same as above)

---@class UpgradeTreeCell
---@field upgrade string|nil key of the upgrade in upgrades table. if nil, then this cell is only a path connecting other cells, not assigned to any upgrade
---@field connect Connect|nil table of connections to other cells. if nil, this cell is pure empty
---@field need Pos[]|nil table of positions of the cells that are needed to make this cell visible

local upgrades={}

---@type table<string,Upgrade>
local upgradesData = {
    -- Warning: real texts are in localization.lua. Following texts are for coding reference only.
    increaseHP={
        name='Increase HP',
        description='Increase HP by 1',
        cost=30,
        executeFunc=function()
            local player=Player.objects[1]
            player.hp=player.hp+1
            player.maxhp=player.maxhp+1
        end,
        spritePos={x=0,y=0}
    },
    regenerate={
        name='Regenerate',
        description='Increase HP by 0.024 per second',
        cost=40,
        executeFunc=function()
            local player=Player.objects[1]
            player.hpRegen=player.hpRegen+0.024
        end,
        spritePos={x=1,y=0}
    },
    unyielding={
        name='Unyielding',
        description='Shockwave when you are hit is bigger',
        cost=30,
        executeFunc=function()
            local player=Player.objects[1]
            player.dieShockwaveRadius=player.dieShockwaveRadius+1
        end,
        spritePos={x=2,y=0}
    },
    acrobat={ -- add a scene that costs HP when grazing, and unlock this upgrade for it
        name='Acrobat',
        description='Each graze gives 0.005 HP',
        cost=40,
        executeFunc=function()
            local player=Player.objects[1]
            player.grazeHpRegen=player.grazeHpRegen+0.005
        end,
        spritePos={x=3,y=0}
    },
    flashbomb={
        name='Flash Bomb',
        description='Release a flash bomb for every 100 grazes',
        cost=50,
        executeFunc=function()
            local player=Player.objects[1]
            player.enableFlashbomb=true
            player.grazeCountForFlashbomb=100
            player.flashbombWidth=5
        end,
        spritePos={x=4,y=0}
    },
    amulet={
        name='Amulet',
        description='Player hitbox is 25% smaller',
        cost=50,
        executeFunc=function()
            local player=Player.objects[1]
            player.radius = player.radius*0.75
        end,
        spritePos={x=5,y=0}
    },
    homingShot={
        name='Homing Shot',
        description='2 rows of your shot become homing',
        cost=50,
        executeFunc=function()
            local player=Player.objects[1]
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
        executeFunc=function()
            local player=Player.objects[1]
            local sideStraight=player:findShootType('side','straight')
            sideStraight.num=sideStraight.num+4
        end,
        spritePos={x=7,y=0}
    },
    backShot={
        name='Back Shot',
        description='Add 4 rows of back shot that do double damage',
        cost=50,
        executeFunc=function()
            local player=Player.objects[1]
            local backStraight=player:findShootType('back','straight')
            backStraight.num=backStraight.num+4
        end,
        spritePos={x=0,y=1}
    },
    familiarShot={
        name='Familiar Shot',
        description='Your shots can hit enemy\'s familiars and do 1/4 damage',
        cost=40,
        executeFunc=function()
            local player=Player.objects[1]
            player.canHitFamiliar=true
            player.hitFamiliarDamageFactor=0.25
        end,
        spritePos={x=1,y=1}
    },
    vortex={
        name='Vortex',
        description='A vortex rounding you that can absorb bullets',
        cost=60,
        executeFunc=function()
            local player=Player.objects[1]
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
        executeFunc=function()
            local player=Player.objects[1]
            player.diagonalSpeedAddition=true
        end,
        spritePos={x=5,y=1}
    },
    homingShotII={
        name='Homing Shot II',
        description='2 more rows of your shot become homing, but homing effect is reduced',
        cost=50,
        executeFunc=function()
            local player=Player.objects[1]
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
        executeFunc=function()
            local player=Player.objects[1]
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
        executeFunc=function()
            local player=Player.objects[1]
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
        executeFunc=function()
            local player=Player.objects[1]
            player.canShootDuringInvincible=true
        end,
        spritePos={x=1,y=2}
    }
}
upgrades.upgradesData=upgradesData

---@type UpgradeTreeCell[][]
local upgradesTree={
    {
        {
            upgrade='increaseHP',
            connect={down=true,right=true},
            need={}
        },
        {
            upgrade='regenerate',
            connect={down=true,left=true,right=true},
            need={{1,1}}
        },
        {
            upgrade='acrobat',
            connect={left=true,right=true},
            need={{2,1}}
        },
        {
            upgrade='flashbomb',
            connect={left=true,right=true},
            need={{3,1}}
        },
        {
            upgrade='vortex',
            connect={left=true},
            need={{4,1}}
        },
        {},
        {}
    },
    {
        {
            connect={up=true,down=true},
            need={}
        },
        {
            upgrade='unyielding',
            connect={up=true,},
            need={{2,1}}
        },
        {},
        {},
        {},
        {},
        {}
    },
    {
        {
            upgrade='homingShot',
            connect={up=true,right=true,down=true},
            need={}
        },
        {
            connect={left=true,right=true,down=true},
            need={{1,3}}
        },
        {
            upgrade='sideShot',
            connect={left=true,right=true},
            need={{1,3}}
        },
        {
            upgrade='familiarShot',
            connect={left=true,down=true,right=true},
            need={{3,3},{3,4}}
        },
        {
            connect={down=true,left=true,right=true},
            need={{4,3}}
        },
        {
            upgrade='homingShotII',
            connect={left=true,right=true},
            need={{4,3}}
        },
        {
            upgrade='counterShot',
            connect={left=true,down=true},
            need={{6,3},{6,4},{6,5}}
        }
    },
    {
        {
            connect={up=true,down=true},
            need={}
        },
        {
            connect={up=true,right=true},
            need={{1,3}}
        },
        {
            upgrade='backShot',
            connect={left=true,right=true},
            need={{1,3}}
        },
        {
            connect={up=true,left=true},
            need={{3,4}}
        },
        {
            connect={up=true,down=true,right=true},
            need={{4,3}}
        },
        {
            upgrade='sideShotII',
            connect={left=true,right=true},
            need={{4,3}}
        },
        {
            connect={left=true,up=true,down=true},
            need={{6,3},{6,4},{6,5}}
        }
    },
    {
        {
            upgrade='amulet',
            connect={up=true,right=true},
            need={}
        },
        {
            upgrade='fixedHPDisplay',
            connect={left=true,right=true,down=true},
            need={{1,5}}
        },
        {
            upgrade='clairvoyance',
            connect={left=true},
            need={{2,5}}
        },
        {},
        {
            connect={up=true,right=true},
            need={{4,3}}
        },
        {
            upgrade='backShotII',
            connect={left=true,right=true},
            need={{4,3}}
        },
        {
            connect={left=true,up=true},
            need={{6,3},{6,4},{6,5}}
        }
    },
    {
        {},
        {
            upgrade='diagonalMover',
            connect={up=true},
            need={{2,5}}
        },
        {},
        {},
        {},
        {},
        {}
    }
}
upgrades.upgradesTree=upgradesTree

return upgrades