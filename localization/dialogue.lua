---@alias expression "normal"|"happy"|"sad"|"angry"|"surprised"|"cunning"|"frustrated"
---@alias position "left"|"right"|nil -- nil means use default position for the speaker. 

---@class DialogueLine
---@field speaker string used to pick image and display speaker name. 'system' is darken screen and display text in center
---@field expression expression used to pick image
---@field textKey string text is in localization.lua
---@field position position where to position image (and flip)

--- of course i want to omit "key=" in each line definition
---@param speaker string
---@param expression expression
---@param textKey string
---@param position position
---@return DialogueLine
local function line(speaker,expression,textKey,position)
    return {
        speaker=speaker,
        expression=expression,
        textKey=textKey,
        position=position,
    }
end

---@class Dialogue
---@field name string identifier, and is the key in localization.dialogues
---@field defaultSpeakerPosition table<string,position> default position for each speaker
---@field lines DialogueLine[]

local Dialogue={}

local DialogueController=GameObject:extend()
local portraitBatch=Asset.portraitBatch
local portraitQuads=Asset.portraitQuads
local portraitWidth,portraitHeight=Asset.portraitWidth,Asset.portraitHeight
function DialogueController:new(args)
    DialogueController.super.new(self,args)
    self.currentLineIndex=1
    self.autoAdvanceTime=args.autoAdvanceTime or 5 -- seconds to auto advance
    self.timeSinceLastAdvance=0
    self.timeSinceLastAutoAdvance=999
    self.dialogueKey=args.key
    self.data=Dialogue.data[args.key]
    if not self.data then
        error("Dialogue key "..tostring(args.key).." not found in Dialogue.data")
    end
    self.afterFunc=args.afterFunc -- function to call after dialogue ends
    ---@class activeCharacter
    ---@field speaker string
    ---@field expression expression
    ---@field position position
    ---@field alpha number
    
    ---@type table<string,activeCharacter>
    self.activeCharacters={} -- list of characters that have appeared in this dialogue. once appeared, their portrait will stay on screen (changing transparency based on who is speaking)
end

function DialogueController:update(dt)
    self.timeSinceLastAdvance=self.timeSinceLastAdvance+dt
    self.timeSinceLastAutoAdvance=self.timeSinceLastAutoAdvance+dt
    if self.timeSinceLastAdvance>=self.autoAdvanceTime or (isPressed('z') and self.timeSinceLastAutoAdvance>0.5) or love.keyboard.isDown('lctrl') then -- press z or hold left ctrl to advance. > 0.5 check to avoid unintended advance after an auto advance
        self:advanceDialogue()
    end
    if self.removed then
        return
    end
    -- update character portraits
    local line=self.data.lines[self.currentLineIndex]
    local speaker=line and line.speaker
    if speaker=='system' then
        self.activeCharacters={} -- clear all characters when system message
    end
    if speaker~='system' and self.activeCharacters[speaker]==nil then
        self.activeCharacters[speaker]={
            speaker=speaker,
            expression=line.expression,
            position=line.position or self.data.defaultSpeakerPosition[speaker] or 'left',
            alpha=0,
        }
    end
    for s,character in pairs(self.activeCharacters) do
        if s==speaker then
            character.alpha=math.min(character.alpha+dt*4,1)
            character.expression=line.expression
        else
            character.alpha=math.max(character.alpha-dt*4,0.3)
        end
    end
end

function DialogueController:advanceDialogue()
    SFX:play('select')
    if self.timeSinceLastAdvance>=self.autoAdvanceTime then
        self.timeSinceLastAutoAdvance=0
    end
    self.timeSinceLastAdvance=0
    self.currentLineIndex=self.currentLineIndex+1
    if self.currentLineIndex>#self.data.lines then
        if self.afterFunc then
            self.afterFunc()
        end
        self:remove()
    end
end

function DialogueController:draw()
    for s,character in pairs(self.activeCharacters) do
        portraitBatch:setColor(1,1,1,character.alpha)
        local speaker,expression=character.speaker,character.expression
        local expressions=portraitQuads[speaker]
        if not expressions then
            goto continue
        end
        local quad=expressions[expression] or expressions.normal
        if not quad then
            goto continue
        end
        local x=character.position=='left' and 10 or WINDOW_WIDTH-10-portraitWidth
        local y=WINDOW_HEIGHT-portraitHeight
        portraitBatch:add(quad,x,y)
        ::continue::
    end
    Asset.dialogueBatch:add(function()
        self:drawDialogueBox()
    end)
end

-- draw the dialogue box, current line and speaker name
function DialogueController:drawDialogueBox()
    if self.currentLineIndex>#self.data.lines then
        return
    end
    local line=self.data.lines[self.currentLineIndex]
    local speaker=line.speaker
    local textKey=line.textKey
    local position=line.position or self.data.defaultSpeakerPosition[speaker] or 'left'
    local text=Localize{'dialogues',self.dialogueKey,textKey}
    local color={love.graphics.getColor()}
    SetFont(24)
    if speaker=='system' then
        love.graphics.setColor(0,0,0,0.5)
        love.graphics.rectangle('fill',0,0,WINDOW_WIDTH,WINDOW_HEIGHT)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(text,150,WINDOW_HEIGHT/2-50,WINDOW_WIDTH-300,'center')
    else
        love.graphics.setColor(0,0,0,0.5)
        local x,y,width,height=150,450,500,130
        love.graphics.rectangle('fill',x,y,width,height)
        local gap=15
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(text,x+gap,y+gap,width-gap*2,'left')
        -- speaker name. it's possible for white part in portrait to cover the name, so draw shadow texts first
        love.graphics.setColor(0,0,0,0.5)
        local name=Localize{'levelData','names',speaker}
        local basex,basey,baseWidth=x+gap,y-gap-20,width-gap*2
        love.graphics.printf(name,basex-1,basey,baseWidth,position)
        love.graphics.printf(name,basex+1,basey,baseWidth,position)
        love.graphics.printf(name,basex,basey-1,baseWidth,position)
        love.graphics.printf(name,basex,basey+1,baseWidth,position)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(name,basex,basey,baseWidth,position)
    end
    love.graphics.setColor(color)
end


local doremyDialogue1_1={
    name='doremyDialogue1_1',
    defaultSpeakerPosition={
        reimu='left',
        doremy='right',
    },
    lines={
        line('reimu','surprised','whereAmI'),
        line('doremy','cunning','thisIsDreamWorld'),
        line('reimu','frustrated','itLooksStrange'),
        line('doremy','normal','thereIsReason'),
        line('doremy','normal','gensokyoIsInDanger'),
        line('reimu','surprised','whatDanger'),
        line('doremy','normal','theWorldIsVeryStrangeNow'),
        line('reimu','normal','dulyNotedCanILeaveNow'),
        line('doremy','normal','notSoFast'),
        line('doremy','cunning','youWillGetLostIfLeaveNow'),
        line('reimu','frustrated','okSoWhat'),
        line('doremy','normal','danmakuIsBetterExplanation'),
        line('system','normal','welcomeToThisGame'),
        line('system','normal','spaceIsStrange'),
        line('system','normal','upperThingsAppearSmaller'),
        line('system','normal','forThisSpellcard'),
        line('system','normal','finalHint'),
        line('system','normal','controlsIntroduction'),
        line('system','normal','haveFun'),
    }
}

local monologue2_1={
    name='monologue2_1',
    defaultSpeakerPosition={
        reimu='left',
    },
    lines={
        line('reimu','normal','gettingUsedToThis'),
        line('reimu','happy','mySkillsAreImproving'),
        line('system','normal','youAreDoingWell'),
        line('system','normal','shopUnlocked'),
        line('system','normal','getXPwhenCompletingScenes'),
        line('system','normal','perfectCompletionMoreXP'),
        line('system','normal','itsInSelectMenu'),
        line('system','normal','tryThatCoolHomingShotUpgrade'),
    }
}

local monologue3_1={
    name='monologue3_1',
    defaultSpeakerPosition={
        reimu='left',
    },
    lines={
        line('reimu','normal','wakeUp'),
        line('reimu','surprised','omgShesRight'),
        line('reimu','surprised','pathLooksInfiniteLong'),
        line('reimu','frustrated','whateverIShouldLeave'),
        line('reimu','frustrated','tryToNotTripOver'),
        line('reimu','normal','iSeeSomeone'),
        line('system','normal','congratulationsOnEscapingDreamWorld'),
        line('system','normal','dreamWorldIsSmaller'),
        line('system','normal','furtherScenesLargerAreas'),
        line('system','normal','reimuIsAlwaysDisplayedAtCenter'),
        line('system','normal','youWillAdaptSoon'),
        line('system','normal','goodLuck'),
    }
}

local nitoriDialogue5_1={
    name='nitoriDialogue5_1',
    defaultSpeakerPosition={
        reimu='left',
        nitori='right',
    },
    lines={
        line('nitori','surprised','reimuYouCame'),
        line('nitori','normal','everyoneKnowsSpaceIsStrange'),
        line('nitori','cunning','butIHaveMoreInformation'),
        line('nitori','normal','howDidYouFindMe'),
        line('reimu','frustrated','iHaveNoIdea'),
        line('reimu','normal','mountOfYoukaiShouldBeFar'),
        line('reimu','normal','butIOnlyFlewForShortWhile'),
        line('nitori','happy','yeahThisIsHowItWorks'),
        line('reimu','surprised','youKnowThis'),
        line('nitori','happy','ofCourseImEngineer'),
        line('reimu','happy','doExplain'),
        line('nitori','normal','itsCalledHyperbolicSpace'),
        line('nitori','normal','areaExpandsExponentially'),
        line('nitori','normal','soSameDistanceCoversMoreArea'),
        line('nitori','normal','gensokyosAreaDoesntChange'),
        line('nitori','happy','transportationIsFaster'),
        line('reimu','normal','butMuchHarderToNavigate'),
        line('reimu','normal','anywayAnyInfoOnCulprit'),
        line('nitori','frustrated','notYetBut'),
        line('nitori','normal','iHaveMadeADeviceCalledHyperCompass'),
        line('nitori','normal','thatPointsToMostDistortedArea'),
        line('reimu','happy','ohCulpritMustBeThere'),
        line('reimu','normal','giveItToMeThen'),
        line('nitori','cunning','ofCourseAfterSomeDanmakuPlaying'),
    }
}

local protagonistsDialogue8_1 = {
    name='protagonistsDialogue8_1',
    defaultSpeakerPosition={
        reimu='left',
        youmu='right',
        marisa='right',
        sakuya='right'
    },
    lines={
        line('reimu','sad','whyFollowingTheCompassIsThisHard'),
        line('reimu','sad','flyForAFewSecondsTheDirectionAlmostFlipped'),
        line('reimu','normal','finallyReachedHere'),
        line('reimu','frustrated','whatAreAllTheseBalls'),
        line('reimu','frustrated','iCantFindTheEntranceIJustEntered'),
        line('reimu','normal','haveToProceed'),
        line('reimu','surprised','iHearSomeVoiceApproaching'),
        line('youmu','surprised','ReimuYoureHereToo'),
        line('reimu','surprised','yeahTooYouMean'),
        line('marisa','cunning','HeheLooksLikeWeAllGotLost'),
        line('reimu','surprised','lostIActivelyFollowedThe'),
        line('sakuya','normal','hiReimuWeAreTooLost'),
        line('sakuya','normal','beforeMetthemIWanderedForDays'),
        line('reimu','sad','ohThatsBadWhatDidYouDo'),
        line('sakuya','normal','buyingFoodForScarletThisMorning'),
        line('sakuya','normal','walkingForAWhileNotRecognizingSurroundings'),
        line('sakuya','normal','thenFoundThisPlace'),
        line('reimu','normal','soThisIsNotCulpritsSmallMansion'),
        line('sakuya','normal','butAHugeMaze'),
        line('reimu','happy','butIHaveHyperCompass'),
        line('marisa','surprised','fromWhere'),
        line('reimu','happy','nitoriGaveItToMe'),
        line('reimu','happy','successfullyLocatedHere'),
        line('marisa','frustrated','ughYouDontNeedACompassToBeLost'),
        line('youmu','normal','butItShouldLeadUsToCulprit'),
        line('youmu','normal','weShouldGoTogether'),
        line('marisa','cunning','butFirstDanmakuTime'),
        line('sakuya','happy','yeahGettingHeatedUp'),
        line('youmu','happy','fineLetsDoIt'),
    }
}

local monologue9_1 = {
    name='monologue9_1',
    defaultSpeakerPosition={
        reimu='left',
    },
    lines={
        line('reimu','normal','theDirectionChangedAgain'),
        line('reimu','normal','shouldBeThisWayFollowMe'),
        line('reimu','surprised','whatTheyDisappeared'),
        line('reimu','surprised','marisaYoumuSakuya'),
        line('reimu','sad','dangitTheSpaceIsSoCursed'),
        line('reimu','sad','shouldntMoveThatFast'),
        line('reimu','normal','letMeWaitForSomeTime'),
        line('reimu','normal','canSomeoneHearMe'),
        line('reimu','surprised','ohSomeoneIsComing'),
        line('reimu','surprised','utsuhoUnderworldAlsoConnectsThere'),
        line('reimu','frustrated','guessIllMeetManyPeopleBeforeDestination'),
    }
}

local monologue10_1 = {
    name='monologue10_1',
    defaultSpeakerPosition={
        reimu='left',
    },
    lines={
        line('reimu','surprised','aBuildingFinally'),
        line('reimu','surprised','culpritShouldBeClose'),
        line('reimu','cunning','sneakInside'),
        line('reimu','normal','itLooksLikeACave'),
        line('reimu','normal','ballsShapeAreDugOut'),
        line('reimu','normal','andWallsAreSmoothlyTiled'),
        line('reimu','normal','whyFlashingColorsOnTheTiles'),
        line('reimu','frustrated','andThisPlaceIsStillSoBig'),
        line('reimu','frustrated','andWhoIsInFrontOfMe'),
        line('reimu','sad','ohNoItsAnotherLostPerson'),
        line('reimu','sad','shouldExpectedThis'),
    }
}

local bossDialogue12_1 = {
    name='bossDialogue12_1',
    defaultSpeakerPosition={
        reimu='left',
        benben='right',
        yatsuhashi='right'
    },
    lines={
        line('reimu','surprised','aPerformanceStage'),
        line('reimu','surprised','theSpotLightsAreOn'),
        line('reimu','normal','ohTheShinyColorsMeantDiscos'),
        line('reimu','surprised','whoAreUnderTheLights'),
        line('benben','happy','anotherAudienceMember'),
        line('yatsuhashi','happy','welcomeToOurPerformance'),
        line('reimu','angry','youAreBehindThis'),
        line('benben','cunning','noWeAreOnTheStageNotBehindIt'),
        line('reimu','angry','iWillStopYou'),
        line('benben','happy','enjoyTheShow'),
        line('yatsuhashi','happy','firstActIsAboutToBegin'),
    }
}

local bossDialogue12_6 = {
    name='bossDialogue12_6',
    defaultSpeakerPosition={
        reimu='left',
        benben='right',
        yatsuhashi='right',
        kotoba='right'
    },
    lines={
        line('reimu','angry','performanceEnded'),
        line('reimu','angry','nowStopDistortion'),
        line('benben','frustrated','weArentRelatedToIt'),
        line('yatsuhashi','frustrated','weAlsoGetLost'),
        line('reimu','surprised','really'),
        line('benben','normal','wePerformToLiftUpPeopleTrappedHere'),
        line('yatsuhashi','normal','yeahAndTheIdeaIsFrom'),
        line('reimu','surprised','ohWhoIsThat'),
        line('kotoba','normal','iAmKotobaWhoYouSeek'),
        line('kotoba','normal','withAbilityToDistort'),
        line('reimu','angry','soItsYouFight'),
    }
}

local bossDialogue12_7 = {
    name='bossDialogue12_7',
    defaultSpeakerPosition={
        reimu='left',
        kotoba='right'
    },
    lines={
        line('kotoba','surprised','iHaventFinishedLastSentence'),
        line('kotoba','normal','myAbilityIsToDistortLanguage'),
        line('reimu','surprised','huh'),
        line('kotoba','normal','preciselyMaterializeAPun'),
        line('reimu','normal','thatMatchesYourSpellcard'),
        line('reimu','normal','butWhatAboutTheSpace'),
        line('kotoba','normal','thisComesFromThePun'),
        line('kotoba','cunning','tellYouAfterNextSpellcard')
    }
}

local bossDialogue12_8 = {
    name='bossDialogue12_8',
    defaultSpeakerPosition={
        reimu='left',
        kotoba='right'
    },
    lines={
        line('kotoba','normal','okTellYouNow'),
        line('kotoba','happy','hyperbolicAria'),
        line('reimu','frustrated','itCouldBeFunnyIfNotTrappingEveryone'),
        line('kotoba','sad','sorryForThat'),
        line('kotoba','normal','daysEarlierIWanderInYoukaiMountain'),
        line('kotoba','normal','iFoundACavewithLargeSpace'),
        line('kotoba','normal','thoughtAndMaterializedThatPun'),
        line('kotoba','normal','aStageInHyperbolicSpaceAppears'),
        line('kotoba','happy','terrificForPerformance'),
        line('kotoba','sad','howeverThenComesTrouble'),
        line('reimu','surprised','whatTrouble'),
        line('kotoba','cunning','letsHaveAnotherDanmakuShow'),
    }
}

local bossDialogue12_9 = {
    name='bossDialogue12_9',
    defaultSpeakerPosition={
        reimu='left',
        kotoba='right'
    },
    lines={
        line('kotoba','normal','languageHasPower'),
        line('kotoba','normal','aPunWillStriveForFulfillment'),
        line('kotoba','normal','whenIWasFindingPerformer'),
        line('kotoba','surprised','theSpaceExpandedTooMuch'),
        line('kotoba','surprised','evenTwistingWholeGensokyo'),
        line('reimu','normal','ohISee'),
        line('kotoba','normal','asYouExperiencedPeopleGetThereWhenLost'),
        line('kotoba','normal','thereComesAudienceAndPerformers'),
        line('kotoba','normal','theWayToFixIsToFinishPerformance'),
        line('kotoba','normal','dunnoIfYouNoticedSpaceIsRecovering'),
        line('reimu','surprised','yeahOutsideSpaceIsZoomingAndDizzying'),
        line('kotoba','cunning','wellSupposeDontLookAtThat'),
        line('kotoba','normal','ourFightIsToAttractAttention'),
        line('reimu','happy','soOthersWontLeaveBeforeSpaceFullyStable'),
        line('kotoba','happy','exactlyFinalSpellcardHere'),
    }
}

---@type table<string,Dialogue>
Dialogue.data={
    doremyDialogue1_1=doremyDialogue1_1,
    monologue2_1=monologue2_1,
    monologue3_1=monologue3_1,
    nitoriDialogue5_1=nitoriDialogue5_1,
    protagonistsDialogue8_1=protagonistsDialogue8_1,
    monologue9_1=monologue9_1,
    monologue10_1=monologue10_1,
    bossDialogue12_1=bossDialogue12_1,
    bossDialogue12_6=bossDialogue12_6,
    bossDialogue12_7=bossDialogue12_7,
    bossDialogue12_8=bossDialogue12_8,
    bossDialogue12_9=bossDialogue12_9,
}


return DialogueController