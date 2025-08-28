---@alias lang string

---@alias localizationItem table<lang,string>

return {
    levelData = {
        defaultQuote = {
            en_us = 'What will happen here?',
            zh_cn = '这里会发生什么呢？',
        },
        names = {
            __default__ = {
                en_us = 'Unknown',
                zh_cn = '未知',
            },
            reimu = {
                en_us = 'Reimu Hakurei',
                zh_cn = '博丽灵梦',
            },
            marisa = {
                en_us = 'Marisa Kirisame',
                zh_cn = '雾雨魔理沙',
            },
            sakuya = {
                en_us = 'Sakuya Izayoi',
                zh_cn = '十六夜咲夜',
            },
            sanae = {
                en_us = 'Sanae Kochiya',
                zh_cn = '东风谷早苗',
            },
            doremy = {
                en_us = 'Doremy Sweet',
                zh_cn = '哆来咪·苏伊特',
            },
            yuugi = {
                en_us = 'Yuugi Hoshiguma',
                zh_cn = '星熊勇仪',
            },
            koishi = {
                en_us = 'Koishi Komeiji',
                zh_cn = '古明地恋',
            },
            cirno = {
                en_us = 'Cirno',
                zh_cn = '琪露诺',
            },
            satori = {
                en_us = 'Satori Komeiji',
                zh_cn = '古明地觉',
            },
            remilia = {
                en_us = 'Remilia Scarlet',
                zh_cn = '蕾米莉亚·斯卡雷特',
            },
            flandre = {
                en_us = 'Flandre Scarlet',
                zh_cn = '芙兰朵露·斯卡雷特',
            },
            nitori = {
                en_us = 'Nitori Kawashiro',
                zh_cn = '河城荷取',
            },
            seija = {
                en_us = 'Seija Kijin',
                zh_cn = '鬼人正邪',
            },
            meiling = {
                en_us = 'Hong Meiling',
                zh_cn = '红美铃',
            },
            patchouli = {
                en_us = 'Patchouli Knowledge',
                zh_cn = '帕秋莉·诺蕾姬',
            },
            suwako = {
                en_us = 'Suwako Moriya',
                zh_cn = '洩矢诹访子',
            },
            eirin = {
                en_us = 'Eirin Yagokoro',
                zh_cn = '八意永琳',
            },
            yukari = {
                en_us = 'Yukari Yakumo',
                zh_cn = '八云紫',
            },
            shou = {
                en_us = 'Shou Toramaru',
                zh_cn = '寅丸星',
            },
            hina = {
                en_us = 'Hina Kagiyama',
                zh_cn = '键山雏',
            },
            alice = {
                en_us = 'Alice Margatroid',
                zh_cn = '爱丽丝·玛格特洛依德',
            },
            utsuho = {
                en_us = 'Utsuho Reiuji',
                zh_cn = '灵乌路空',
            },
            aya = {
                en_us = 'Aya Shameimaru',
                zh_cn = '射命丸文',
            },
            clownpiece = {
                en_us = 'Clownpiece',
                zh_cn = '克劳恩皮丝',
            },
            reisen = {
                en_us = 'Reisen Udongein Inaba',
                zh_cn = '铃仙·优昙华院·因幡',
            },
            junko = {
                en_us = 'Junko',
                zh_cn = '纯狐',
            },
            renko = {
                en_us = 'Renko Usami',
                zh_cn = '宇佐见莲子',
            },
            keiki = {
                en_us = 'Keiki Haniyasushin',
                zh_cn = '埴安神袿姬',
            },
            youmu = {
                en_us = 'Youmu Konpaku',
                zh_cn = '魂魄妖梦',
            },
            mystia = {
                en_us = 'Mystia Lorelei',
                zh_cn = '米斯蒂娅·萝蕾拉',
            },
            okina = {
                en_us = 'Okina Matara',
                zh_cn = '摩多罗隐岐奈',
            },
            ubame = {
                en_us = 'Ubame Chirizuka',
                zh_cn = '尘塚姥芽',
            },
            chimi = {
                en_us = 'Chimi Houjuu',
                zh_cn = '封兽魑魅',
            },
            nareko = {
                en_us = 'Nareko Michigami',
                zh_cn = '道神驯子',
            },
            minamitsu = {
                en_us = 'Minamitsu Murasa',
                zh_cn = '村纱水蜜',
            },
            urumi = {
                en_us = 'Urumi Ushizaki',
                zh_cn = '牛崎润美',
            },
            mike = {
                en_us = 'Mike Goutokuji',
                zh_cn = '豪德寺三花',
            },
            nemuno = {
                en_us = 'Nemuno Sakata',
                zh_cn = '坂田合欢',
            },
            takane = {
                en_us = 'Takane Yamashiro',
                zh_cn = '山城高岭',
            },
            eika = {
                en_us = 'Eika Ebisu',
                zh_cn = '戎璎花',
            },
            seiran = {
                en_us = 'Seiran',
                zh_cn = '清兰',
            },
            benben = {
                en_us = 'Benben Tsukumo',
                zh_cn = '九十九弁弁',
            },
            yatsuhashi = {
                en_us = 'Yatsuhashi Tsukumo',
                zh_cn = '九十九八桥',
            },
            asama = {
                en_us = 'Yuiman Asama',
                zh_cn = '维缦·浅间',
            },
            toyohime = {
                en_us = 'Watatsuki no Toyohime',
                zh_cn = '绵月丰姬',
            }
        },
        spellcards = {
            -- level 1
            [11] = {
                quote = {
                    en_us = 'In this world things appear smaller when closer to top.',
                    zh_cn = '在这个世界里，靠近顶部的东西看起来会更小。',
                },
                spellName = {
                    en_us = 'Dream Sign "Permeable Wall"',
                    zh_cn = '梦符「可渗透的墙」',
                },
            },
            [12] = {
                quote = {
                    en_us = 'Hyperbolic center of circle is above the Euclidean center.',
                    zh_cn = '双曲几何的圆心在欧氏圆心的上方。',
                },
                spellName = {
                    en_us = 'Moon Sign "Cerulean Lunatic Dream"',
                    zh_cn = '月符「蔚蓝色的狂梦」',
                },
            },
            [13] = {
                quote = {
                    en_us = 'I wonder where is the best place to induce these bullets.',
                    zh_cn = '哪里是诱导这些子弹的最佳位置？',
                },
                spellName = {
                    en_us = 'Beckon Sign "Koban Attraction"',
                    zh_cn = '招符「小判吸引」',
                },
            },
            [14] = {
                quote = {
                    en_us = 'Moving through this "square" grid is so difficult.',
                    zh_cn = '穿过这个"方"阵真是太困难了。',
                },
                spellName = {
                    en_us = 'Blade Exhaustion Sign "Killing Grid"',
                    zh_cn = '尽符「杀戮方阵」',
                },
            },
            [15] = {
                quote = {
                    en_us = 'The shape reminds me of the Moriya maiden. Maybe Takane learned this from her.',
                    zh_cn = '这个形状让我想起了守矢的巫女。也许高岭是从她那里学来的。',
                },
                spellName = {
                    en_us = 'Leaf Skill "Green Heptagram"',
                    zh_cn = '叶技「绿色七角星」',
                },
            },
            [16] = {
                quote = {
                    en_us = 'These manacles are not even a closed loop, how could that can\'t be taken off?',
                    zh_cn = '这些铐子甚至不是一个封闭的环，怎么会不能脱掉？',
                },
                spellName = {
                    en_us = 'Manacles Sign "Manacles a Criminal Can\'t Take Off"',
                    zh_cn = '铐符「罪人不释之铐」',
                },
            },
            -- level 2
            [21] = {
                quote = {
                    en_us = 'Leaves are teleporting across the screen, or maybe they are just moving fast due to forest qi.',
                    zh_cn = '树叶好像在瞬移，也有可能它们因为森林的气而移动得很快。',
                },
                spellName = {
                    en_us = 'Forest Sign "Folded Forest Region"',
                    zh_cn = '森符「折叠的森域」',
                },
            },
            [22] = {
                quote = {
                    en_us = 'Bullets are waving left and right, similar to how Manekineko waves its paw.',
                    zh_cn = '子弹左右摇摆，和招财猫挥动爪子的方式类似。'
                },
                spellName = {
                    en_us = 'Invitation Sign "Welcoming Gesture"',
                    zh_cn = '邀符「欢迎姿态」',
                },
            },
            [23] = {
                quote = {
                    en_us = 'Moving around can help shake off these bullets.',
                    zh_cn = '到处跑可以帮助摆脱这些子弹。'
                }, -- I have a feeling that something will happen if I linger till...'
                spellName = {
                    en_us = 'Dream Sign "Lingering Memory"',
                    zh_cn = '梦符「萦绕的记忆」',
                },
            },
            [24] = {
                quote = {
                    en_us = 'Running around and casting freezing magic, she is playfully teasing me.',
                    zh_cn = '到处跑着施放冰冻魔法，和做游戏一样。',
                },
                spellName = {
                    en_us = 'Freeze Sign "Rime Ice"',
                    zh_cn = '冻符「雾凇冰晶」',
                },
            },
            [25] = {
                quote = {
                    en_us = 'This kind of ice looks quite sharp. I\'d never want to touch it.',
                    zh_cn = '这种冰看起来很锋利。我绝对不想碰它。',
                },
                spellName = {
                    en_us = 'Crystalization "Supernatural Lattice"',
                    zh_cn = '结晶「超自然晶格」',
                },
            },
            [26] = {
                quote = {
                    en_us = 'Straight lines curve upwards and appear as arcs. Should be careful when dodging.',
                    zh_cn = '直线向上弯曲并呈弧形。躲避时要小心。',
                },
                spellName = {
                    en_us = '"Eye of Nightmare"',
                    zh_cn = '「噩梦之眼」',
                },
            },
            [27] = {
                quote = {
                    en_us = 'not come up yet :P',
                    zh_cn = '还没想好 :P',
                },
                spellName = {
                    en_us = 'Barrier "Boundary of Monad and Dyad"',
                    zh_cn = '结界「己与彼的境界」',
                },
            },
            -- level 3
            [31] = {
                quote = {
                    en_us = 'Such surreal scene of a broader hyperbolic area...',
                    zh_cn = '如此超现实的广阔双曲区域...',
                },
                spellName = {
                    en_us = 'Scarlet Sign "Vampirish Plaza"',
                    zh_cn = '红符「吸血鬼广场」',
                },
            },
            [32] = {
                quote = {
                    en_us = 'Yuugi\'s classic three steps become unpredictable here. She is truly drunken.',
                    zh_cn = '勇仪的经典三步在这变得不可预测了。看来她真的喝醉了。',
                },
                spellName = {
                    en_us = 'Big Four Arcanum "Knock Out In Three Sides"',
                    zh_cn = '四天王奥义「三角必杀」',
                },
            },
            [33] = {
                quote = {
                    en_us = 'Oh no, I can\'t find the direction home! Can compass work in this world?',
                    zh_cn = '不好，我找不到回家的方向了！指南针在这个世界里能用吗？',
                },
                spellName = {
                    en_us = 'Turnabout "Change Orientation"',
                    zh_cn = '逆转「方向变换」',
                },
            },
            [34] = {
                quote = {
                    en_us =
                    'What is she doing? I don\'t think my orientation has changed, but the world is still spinning...',
                    zh_cn = '她在干什么？我觉得我的朝向没变，但世界还在旋转...',
                },
                spellName = {
                    en_us = 'Turnabout "Change Projection"',
                    zh_cn = '逆转「投影变换」',
                },
            },
            [35] = {
                quote = {
                    en_us = 'Keep my speed up, and catch the right time to cross tracks!',
                    zh_cn = '保持速度，抓住合适的时机穿越轨道！',
                },
                spellName = {
                    en_us = 'Taboo "Labyrinthine Trap"',
                    zh_cn = '禁忌「环形陷阱」',
                },
            },
            [36] = {
                quote = {
                    en_us = 'Even she sits in that machine automatically chasing me! Lazy, but effective.',
                    zh_cn = '连她自己都坐在机器里自动追逐我！懒惰，但有效。',
                },
                spellName = {
                    en_us = 'Battle Machine "Autonomous Sentries"',
                    zh_cn = '战斗兵器「自动哨兵」',
                },
            },
            [37] = {
                quote = {
                    en_us = 'A creative use of her absolute power to destroy everything...',
                    zh_cn = '她绝对破坏力的创造性运用...',
                },
                spellName = {
                    en_us = 'Forbidden Barrage "Border break"',
                    zh_cn = '禁弹「边界破碎」',
                },
            },
            [131] = {
                spellName = {
                    en_us = 'Collapse "Sanctuary of Schwarz"',
                    zh_cn = '崩溃「施瓦茨圣域」',
                },
                quote = {
                    en_us = 'She tried but failed to destroy this Hyperbolic Domain. Who to visit next?',
                    zh_cn = '她试图摧毁双曲域，但失败了。接下来要去拜访谁呢？',
                },
            },
            [137] = {
                spellName = {
                    en_us = 'Stack Sign "Tower Stoxx"',
                    zh_cn = '堆符「石头叠叠乐」',
                },
                quote = {
                    en_us = 'It\'s stone version of that stack building game! Should hyperbolic tower be more unstable?',
                    zh_cn = '这是石头版的叠建筑物游戏！双曲塔会更不稳定吗？',
                },
            },
            [132] = {
                spellName = {
                    en_us = 'Bullet Sign "Eagle\'s Volley Fire"',
                    zh_cn = '弹符「鹰之齐射」',
                },
                quote = {
                    en_us = 'The pattern is quite similar to when she was in normal world. Or her bullets originally belong to this dimension?',
                    zh_cn = '这种弹幕和她在正常世界时的很相似。也许她的子弹本来就属于这个维度？',
                },
            },
            [133] = {
                spellName = {
                    en_us = 'Bullet Sign "Eagle\'s Big Shot"',
                    zh_cn = '弹符「鹰之大射」',
                },
                quote = {
                    en_us = 'Woah, a giant triangle! Its recoil pushes her too far away, so she can\'t shoot it continuously.',
                    zh_cn = '哇，一个巨大的三角形！后坐力把她推得太远了，所以她不能连续射击。',
                },
            },
            -- level 4
            [41] = {
                quote = {
                    en_us = 'This knife sharpening way looks funny. Sometimes she almost leaves the screen.',
                    zh_cn = '这种磨刀方式看起来很有趣。有时她几乎要离开屏幕了。',
                },
                spellName = {
                    en_us = 'Blade Sign "Swirling Knife Sharpening"',
                    zh_cn = '刃符「旋转式磨刀」',
                },
            },
            [42] = {
                quote = {
                    en_us = 'The thread is stretched far away but still connected. So called "Celestial Thread".',
                    zh_cn = '线拉得很远但仍然连接着。这就是所谓「通天线」吧。',
                },
                spellName = {
                    en_us = 'Moon Wood Sign "Celestial Thread"',
                    zh_cn = '月木符「通天线」',
                },
            },
            [43] = {
                quote = {
                    en_us = 'Hyperbolic geometry distorts her rings a lot. She has to change the material.',
                    zh_cn = '双曲几何让她的环大大变形。她不得不换材料了。',
                },
                spellName = {
                    en_us = 'Divine Tool "Moriya\'s Elastic Ring"',
                    zh_cn = '神具「洩矢的弹性环」',
                },
            },
            [44] = {
                spellName = {
                    en_us = 'Obstructing Sign "Wall of Misdirection"',
                    zh_cn = '塞符「误向之墙」',
                },
                quote = {
                    en_us = 'Examine the environment carefully to tell direction. I\'m learning a useful skill!',
                    zh_cn = '仔细观察环境来判断方向。我正在学习一项有用的技能！',
                },
            },
            [45] = {
                quote = {
                    en_us = 'Her pounce even moves the border. Moving too far in this world seems dangerous.',
                    zh_cn = '她的扑击甚至移动了边界。在这个世界里走得太远似乎很危险。',
                },
                spellName = {
                    en_us = 'Tiger Sign "Famished Tiger"',
                    zh_cn = '寅符「饿虎扑食」',
                },
            },
            [46] = {
                spellName = {
                    en_us = 'Stack Sign "Crop Circle"',
                    zh_cn = '堆符「麦田怪圈」',
                },
                quote = {
                    en_us = 'Stones are stacked in a way that looks like a crop circle. Then, shouldn\'t it be called "Stone Circle"?',
                    zh_cn = '石头堆成的形状看起来像麦田怪圈。那么，难道不应该叫“石头怪圈”吗？',
                },
            },
            [47] = {
                quote = {
                    en_us = 'not come up yet :P',
                    zh_cn = '还没想好 :P',
                },
                spellName = {
                    en_us = 'Magic Sign "Explosive Marionette"',
                    zh_cn = '魔符「爆裂玩偶」',
                },
            },
            [48] = {
                quote = {
                    en_us = 'With solar energy stored inside, the alloy is hot and untouchable.',
                    zh_cn = '蕴含太阳能的合金炽热无比，不可触碰。',
                },
                spellName = {
                    en_us = 'Sun Metal Sign "Solar Alloy"',
                    zh_cn = '日金符「太阳合金」',
                },
            },
            [144] = {
                quote = {
                    en_us = 'The souls stop drifting and shoot bullets before disappearing. I wonder what they are thinking.',
                    zh_cn = '漂流的灵魂在消失前会停下来射出子弹。它们在想什么呢。',
                },
                spellName = {
                    en_us = 'Drowning Sign "Drifting Souls"',
                    zh_cn = '溺符「漂流的灵魂」',
                },
            },
            [145] = {
                quote = {
                    en_us = 'Boulder\'s mass is so large that its gravity attracts all water drops in the river. Is this really possible?',
                    zh_cn = '巨石的质量如此之大，以至于它的引力吸引了河中所有的水滴。这真的可能吗？',
                },
                spellName = {
                    en_us = 'Stone Sign "Boulder in Sanzu River"',
                    zh_cn = '石符「三途川的巨石」',
                },
            },
            [146] = {
                quote = {
                    en_us = 'Though called silent land, the ground is always moving. More like a living land.',
                    zh_cn = '虽然叫做寂静大地，但地面总是在移动。更像是有生命的土地。',
                },
                spellName = {
                    en_us = 'Mountain Spirit Sign "Qi of Silent Land"',
                    zh_cn = '魑符「寂静大地之气」',
                },
            },
            -- level 5
            [51] = {
                quote = {
                    en_us = 'Find the critical bullet that will explode! Sharp eyes are needed.',
                    zh_cn = '找到即将爆炸的关键子弹！要火眼金睛才行。',
                },
                spellName = {
                    en_us = 'Explosion Sign "Critical Mass"',
                    zh_cn = '爆符「临界质量」',
                },
            },
            [52] = {
                quote = {
                    en_us = 'Through the experiment, she found the way to make bigger nukes in this world.',
                    zh_cn = '通过实验，她找到了在这个世界制造更大核弹的方法。',
                },
                spellName = {
                    en_us = 'Atomic Fire "Nuclear Experiment Expansion"',
                    zh_cn = '核热「核反应扩大试验」',
                },
            },
            [53] = {
                spellName = {
                    en_us = 'Crossroad Sign "Wind-Chasing Track"',
                    zh_cn = '岐符「逐风小径」',
                },
                quote = {
                    en_us = 'Escaping along the track and feeling the rustling wind, a unique experience.',
                    zh_cn = '沿着小路全速逃跑，感受风声呼啸，也算独特的体验。',
                },
            },
            [54] = {
                spellName = {
                    en_us = 'Wind God "Tengu\'s Gale"',
                    zh_cn = '风神「天狗疾风」',
                },
                quote = {
                    en_us = 'Looks like wind is pushing me and her bullets, but actually it\'s she moving with the border.',
                    zh_cn = '看起来是风在推动我和她的子弹，但实际上是她在和边界一起移动。',
                },
            },
            [55] = {
                spellName = {
                    en_us = 'Hell Sign "Erroneous Orbit"',
                    zh_cn = '狱符「谬误轨道」',
                },
                quote = {
                    en_us = 'The orbit is ellipse, or more like rotating ellipse, or what?',
                    zh_cn = '这轨道是椭圆，还是更像旋转的椭圆，或者说是什么？',
                },
            },
            [56] = {
                spellName = {
                    en_us = 'Hell Sign "Exotic Meteor"',
                    zh_cn = '狱符「异域流星」',
                },
                quote = {
                    en_us = 'Earth would be destroyed if these meteors are real.',
                    zh_cn = '如果这些流星是真的，地球就会被毁灭的。',
                },
            },
            [57] = {
                spellName = {
                    en_us = 'Water Sign "Kappa\'s Meandering Current"',
                    zh_cn = '水符「河童的蜿蜒河流」',
                },
                quote = {
                    en_us =
                    'I noticed the banks are diverging at far away place. It seems a complicated question whether river can exist in this world.',
                    zh_cn = '河岸在远处逐渐分开。在这个世界里河能不能存在好像是个很复杂的问题。',
                },
            },
            [58] = {
                spellName = {
                    en_us = 'Light Sign "Light of Purification"',
                    zh_cn = '光符「净化之光」',
                },
                quote = {
                    en_us = 'not come up yet :P',
                    zh_cn = '还没想好 :P',
                },
            },
            [151] = {
                spellName = {
                    en_us = 'Water Sign "the Grand Water War"',
                    zh_cn = '水符「大水仗」',
                },
                quote = {
                    en_us = 'Playful water fight! If this is Kappa\'s daily life I would like to be a Kappa too.',
                    zh_cn = '顽皮的水仗！如果这是河童的日常生活，我也想当个河童。',
                },
            },
            -- level 6
            [61] = {
                quote = {
                    en_us = 'Suddenly bullets fade and scatter all around me, but next moment they return solid.',
                    zh_cn = '子弹突然虚化，四处飘散，但下一刻又变为实体。',
                },
                spellName = {
                    en_us = 'Scatter Sign "Phantom Mirage"',
                    zh_cn = '散符「幻影蜃景」',
                },
            },
            [62] = {
                quote = {
                    en_us = 'Two misty figures cast deadly radiance. Mystic and dangerous illusion.',
                    zh_cn = '两处朦胧投射出致命的光辉。神秘而危险的幻象。',
                },
                spellName = {
                    en_us = 'Illusion Light "Moon of Void"',
                    zh_cn = '幻光「虚无之月」',
                },
            },
            [63] = {
                quote = {
                    en_us = 'Ehh, how did I become the bob of this clock? Dizzying.',
                    zh_cn = '诶，我怎么成了这个钟的摆锤？头好晕。',
                },
                spellName = {
                    en_us = 'Conjuring "The Clock that Doesn\'t Tell Time"',
                    zh_cn = '奇术「不报时的钟表」',
                },
            },
            [64] = {
                quote = {
                    en_us = 'Junko must have improved her gardening skills. No longer only lilies.',
                    zh_cn = '纯狐一定是提高了她的园艺技能。不再只有百合了。',
                },
                spellName = {
                    en_us = '"Sterile Flowers of Murderous Intent"',
                    zh_cn = '「杀意的徒花」',
                },
            },
            [65] = {
                quote = {
                    en_us = 'A real physicist here. What a clever trick to capture my shots.',
                    zh_cn = '货真价实的物理学家。捕捉我的子弹，真是个聪明的把戏。',
                },
                spellName = {
                    en_us = 'Capture "Fabry-Pérot Cavity"',
                    zh_cn = '捕获「法布里-佩罗腔」'
                },
            },
            [66] = {
                quote = {
                    en_us = 'Monochrome light makes the mandala kind of bland. A limitation of interference pattern?',
                    zh_cn = '单色光让曼荼罗有点单调。这是干涉图案的局限性吗？',
                },
                spellName = {
                    en_us = 'Interference "Wavefront Mandala"',
                    zh_cn = '干涉「波前曼荼罗」'
                },
            },
            [67] = {
                quote = {
                    en_us = 'Seems like Keiki\'s power can be adapted to jewelry. Will she consider this?',
                    zh_cn = '看来袿姬的能力可以用来制作首饰，她会考虑一下吗？',
                },
                spellName = {
                    en_us = 'Polygon Shape "Facet Sculpting Art"',
                    zh_cn = '多边形「刻面造形术」'
                },
            },
            [68] = {
                quote = {
                    en_us = 'Lines from extremely far away converge to me.',
                    zh_cn = '来自远方的直线到达我这里。',
                },
                spellName = {
                    en_us = 'Tessellation "N-Sided Nirvana"',
                    zh_cn = '密铺「N边的涅槃」'
                },
            },
            -- level 7
            [71] = {
                quote = {
                    en_us = 'The world is full of her "sword spirit". I can feel the power of her sword.',
                    zh_cn = '这个世界充满了她的“剑气”。我能感受到她的力量。',
                },
                spellName = {
                    en_us = 'Soul-Body Sword "Slash of Echoing Ghost Blade"',
                    zh_cn = '魂魄剑「回响灵刃斩」',
                },
            },
            [72] = {
                quote = {
                    en_us = 'Follow the rhythm... do\'nt tell me the idea is from dance pad.',
                    zh_cn = '跟紧节奏……难道这个创意是来自跳舞毯？',
                },
                spellName = {
                    en_us = 'Instant Sword "Fleeting Crossing Slash"',
                    zh_cn = '刹那剑「无常横断斩」',
                },
            },
            [73] = {
                quote = {
                    en_us = 'The border corners are like horns, much deeper than I thought and provide space to escape.',
                    zh_cn = '边界的角落是号角形的，比我想象的要深得多，提供了逃跑的空间。',
                },
                spellName = {
                    en_us = 'Karmic Binding Sword "Karmic Retribution Slash"',
                    zh_cn = '业缚剑「宿业断罪斩」',
                },
            },
            [74] = {
                spellName = {
                    en_us = 'Barrier "Flickering of the Real and Reflected"',
                    zh_cn = '结界「物与像的明灭」',
                },
                quote = {
                    en_us = 'Under barrier\'s interference, it\'s like trying to watch a corrupted feed.',
                    zh_cn = '在结界的干扰下，就像试图观看损坏的信号。',
                },
            },
            [75] = {
                spellName = {
                    en_us = '"Instant Pierce Barrier - Impregnable Fortress"',
                    zh_cn = '「隧穿结界　-金城铁壁-」'
                },
                quote = {
                    en_us =
                    'Stationary bullets can warp through the space around me, and that\'s the way to penetrate inside. The final fortress is too large, though.',
                    zh_cn = '静止的子弹可以穿越我周围的空间，这就是穿透到内部的方式。不过最终的堡垒太大了。',
                },
            },
            [76] = {
                spellName = {
                    en_us = 'Conjuring "Pendulum of Illusory Speed"',
                    zh_cn = '奇术「幻速的振子」',
                },
                quote = {
                    en_us = 'To get close, to circle around, or to get away?',
                    zh_cn = '要靠近，要绕圈，还是要远离？',
                }
            },
            [77] = {
                spellName = {
                    en_us = 'Fire Sign "Hephaestus Pyrotechnics"',
                    zh_cn = '火符「赫淮斯托斯的烟火」',
                },
                quote = {
                    en_us =
                    'Pyrotechnics, huh? It\'s like a fireworks show where every single spark suddenly decides it really hates me.',
                    zh_cn = '烟火吗？好似烟花表演，但每一颗火星都真的讨厌我。',
                },
            },
            [78] = {
                spellName = {
                    en_us = 'Night-Blindness "Bioluminescent Night"',
                    zh_cn = '夜盲「生物荧光之夜」',
                },
                quote = {
                    en_us = 'Fireflies are providing dim light. Be careful not to kill them accidentally.',
                    zh_cn = '萤火虫提供微弱的光线。小心不要意外地杀死它们。',
                },
            },
            [79] = {
                spellName = {
                    en_us = 'Night Sparrow "Staccato Melody"',
                    zh_cn = '夜雀「断奏的旋律」',
                },
                quote = {
                    en_us = 'A music kind of night blindness. Take fitful steps, or sometimes sprint into deep darkness.',
                    zh_cn = '一种音乐般的夜盲症。走走停停，或者有时冲进深邃的黑暗。',
                },
            },
            -- level 8
            [81] = {
                spellName = {
                    en_us = 'Secret Ceremony "Dark Butoh of the Back Door"',
                    zh_cn = '秘仪「后户的暗黑舞踏」',
                },
                quote = {
                    en_us = 'She is moving so frantically, and the danmaku is chaotic too. Should\'t Butoh be more elegant?',
                    zh_cn = '她的动作如此疯狂，弹幕也很混乱。舞踏不应该更优雅吗？',
                },
            },
            [82] = {
                spellName = {
                    en_us = 'Secret Ceremony "The Ninefold Heaven Gates"',
                    zh_cn = '秘仪「阊阖九重天门」',
                },
                quote = {
                    en_us = 'Nine heaven gates look solemn and majestic, but hesitate too much before them will leave no time to do damage.',
                    zh_cn = '九扇天门看起来庄严而宏伟，但在它们面前犹豫太久，就没有时间打伤害了。',
                },
            },
            [83] = {
                spellName = {
                    en_us = 'Secret Ceremony "One Eyed Bat"',
                    zh_cn = '秘仪「独眼蝙蝠」',
                },
                quote = {
                    en_us = 'Huge bats are flying around, their wings shrouding me. But the big eyes detached from the body seems more irritating.',
                    zh_cn = '巨大的蝙蝠在我周围飞翔，它们的翅膀笼罩着我。但从身体上脱离的大眼睛似乎更让人不安。',
                },
            },
            [84] = {
                spellName = {
                    en_us = 'Dust Sign "Myriad Motes Accumulation"',
                    zh_cn = '尘符「万尘集积」',
                },
                quote = {
                    en_us = 'She is sweeping the dust away, but it only creates more dust. What a bad janitor.',
                    zh_cn = '她在扫除灰尘，却让更多的灰尘出现。真是个糟糕的清洁工。',
                }
            },
            [85] = {
                spellName = {
                    en_us = 'Chest Sign "Karabitsu\'s Opened Hoard"',
                    zh_cn = '柜符「唐柜的宝藏」',
                },
                quote = {
                    en_us = 'Searching here and there, found nothing but random items. What is she looking for?',
                    zh_cn = '到处寻找，找到的全是杂物。她在找什么呢？',
                }
            },
            [86] = {
                spellName = {
                    en_us = 'Bewitching Sign "Qi of an Impenetrable Thicket"',
                    zh_cn = '魅符「致密灌木之气」',
                },
                quote = {
                    en_us = 'This thicket is almost a primary forest. Seems a environment protection yokai.',
                    zh_cn = '这个灌木丛几乎像是原始森林了。看起来是个环境保护妖怪。',
                }
            },
            [87] = {
                spellName = {
                    en_us = 'Mountain Spirit Sign "Qi of a Drainage Divide"',
                    zh_cn = '魑符「分水山岭之气」',
                },
                quote = {
                    en_us = 'How the water flows in opposite directions on both sides of the watershed?',
                    zh_cn = '分水岭两侧的水流为什么是相反方向的？',
                }
            },
            [88] = {
                spellName = {
                    en_us = 'Riddle Sign "Pseudo Hexagonal Labyrinth"',
                    zh_cn = '谜符「伪六角迷宫」',
                },
                quote = {
                    en_us = 'Due to the geometry, 6 way shots don\'t form regular cells and it gets more complicated.',
                    zh_cn = '由于几何关系，6路弹幕并没有形成规则的单元格，而是更加复杂。',
                }
            },
            [89] = {
                spellName = {
                    en_us = 'Path Sign "Escher\'s Walkway"',
                    zh_cn = '道符「埃舍尔的走道」',
                },
                quote = {
                    en_us = 'Seemingly infinite space filled with bullets quickly. All paths are dangerous now.',
                    zh_cn = '看似无限的空间迅速被子弹填满。所有的道路现在都很危险。',
                }
            },
            [181] = {
                spellName = {
                    en_us = 'Illusion Existence "Doppelganger"',
                    zh_cn = '幻在「双生」',
                },
                quote = {
                    en_us = 'Thought it\'s her doppelganger, but actually knives\' doppelgangers. Do my bullets have doppelgangers too?',
                    zh_cn = '以为是她的分身，实际上是刀的分身。我的子弹也有分身吗？',
                }
            },
            [182] = {
                spellName = {
                    en_us = 'Love Sign "Expanding Spark"',
                    zh_cn = '恋符「扩散火花」',
                },
                quote = {
                    en_us = 'The range expands suddenly, and the sparks are everywhere. Individual spark looks like ... popcorn?',
                    zh_cn = '范围突然扩大，火花无处不在。单个火花看起来像……爆米花？',
                }
            },
            [183] = {
                spellName = {
                    en_us = 'Star Sign "Star Chain"',
                    zh_cn = '星符「星之链」',
                },
                quote = {
                    en_us = 'Chains are bent away from her. Is that showing her power?',
                    zh_cn = '链条向外弯曲。这是在展示她的力量吗？',
                }
            },
            [90] = {
                spellName = {
                    en_us = 'Heavy Sign "Weight of a Thousand Fathoms"',
                    zh_cn = '重符「千寻之重」',
                },
                quote = {
                    en_us = 'The huge anchor explodes into countless pieces. Must guide it to the deep corners of the area.',
                    zh_cn = '巨大的锚爆炸成无数碎片。必须引导它到区域的深处。',
                }
            },
            [91] = {
                spellName = {
                    en_us = 'Drowning Sign "Double Vortex"',
                    zh_cn = '溺符「双重漩涡」',
                },
                quote = {
                    en_us = 'The water is swirling around, and I can\'t find the way out. It\'s like being trapped in a whirlpool.',
                    zh_cn = '水在旋转，我找不到出路。就像被困在漩涡中一样。',
                }
            },
            [92] = {
                spellName = {
                    en_us = 'Stone Sign "Rotating Stone"',
                    zh_cn = '石符「旋转的石头」',
                },
                quote = {
                    en_us = 'Stones mysteriously become larger after rotating around.',
                    zh_cn = '石头在旋转后神秘地变大了。',
                }
            },
            [110] = {
                spellName = {
                    en_us = 'Wave Sign "Eigenstate in the Quantum Well"',
                    zh_cn = '波符「量子阱的本征态」',
                },
                quote = {
                    en_us = 'Sine waves are oscillating around me! What a messy quantum well.',
                    zh_cn = '正弦波在我周围振荡！真是混乱的量子阱。',
                }
            },
            [111] = {
                spellName = {
                    en_us = 'Triangular Shape "Triangle Creature"',
                    zh_cn = '三角形「三角生物」',
                },
                quote = {
                    en_us = 'Triangle creatures walk by flipping their sides. Would they be confused which vertex walks to the front?',
                    zh_cn = '三角生物通过翻转它们的边走动。它们会搞混哪个顶点走在前面吗？',
                }
            },
            [112] = {
                spellName = {
                    en_us = 'Giant Star "Dense Stellaris"',
                    zh_cn = '巨星「致密星云」',
                },
                quote = {
                    en_us = 'Hugest bullets I have ever seen! The whole area is filled with them.',
                    zh_cn = '我见过的最大子弹！整个区域都被它们填满了。',
                }
            },
            -- level 10
            [113] = {
                spellName = {
                    en_us = 'Serpent Sign "Ouroborous\'s Feast"',
                    zh_cn = '蛇符「衔尾蛇的盛宴」',
                },
                quote = {
                    en_us = 'Snake reborns itself by eating its own tail. Too similar to ecdysis?',
                    zh_cn = '蛇通过吃掉自己的尾巴来重生。和蜕皮太像了吧？',
                }
            },
            [114] = {
                spellName = {
                    en_us = 'Crowd Sign "Bitstream"',
                    zh_cn = '群符「比特流」',
                },
                quote = {
                    en_us = 'Merging streams of data into a single piece, it would be cool as a download animation, much better than flying papers.',
                    zh_cn = '将数据流合并为一个整体，作为下载动画会很酷，比纸张飞来飞去好得多。',
                }
            },
            [115] = {
                spellName = {
                    en_us = 'Void Sign "Purge Algorithm"',
                    zh_cn = '虚符「清除算法」',
                },
                quote = {
                    en_us = 'A way to remove impurities in her memory. But there is always a bit not touched.',
                    zh_cn = '一种清除她记忆中杂质的方法。但总有一部分没有被触及。',
                }
            },
            [116] = {
                spellName = {
                    en_us = 'Fan Sign "Destructive Breeze"',
                    zh_cn = '扇符「破坏之风」',
                },
                quote = {
                    en_us = 'A breeze that purifies bullets in its path. Snapping open the fan is cool.',
                    zh_cn = '一阵净化子弹的微风。猛地打开扇子真是太酷了。',
                }
            },
            [117] = {
                spellName = {
                    en_us = 'Boundary Sign "Landscape of Mountain and Sea"',
                    zh_cn = '境符「山海之景」',
                },
                quote = {
                    en_us = 'A beautiful landscape painting depicting the harmony between mountains and seas... if the danmaku is not this dense.',
                    zh_cn = '一幅美丽的风景画，描绘了山与海之间的和谐……如果弹幕没有这么密的话。',
                }
            },
            -- boss spellcards
            [101] = {
                spellName = {
                    en_us = 'Music Sign "Sly Musical Score"',
                    zh_cn = '乐符「狡诈的五线谱」',
                },
                quote = {
                    en_us = 'Varied types of scores are flying around. I can\'t read music, but I can dodge.',
                    zh_cn = '各种类型的乐谱在空中飞舞。我不会读乐谱，但我可以躲避。',
                }
            },
            [102] = {
                spellName = {
                    en_us = 'Koto Sign "Cage of the Thirteen Strings"',
                    zh_cn = '琴符「十三弦之囚笼」',
                },
                quote = {
                    en_us = 'Is this the feeling of being trapped in koto as a tsukumogami?',
                    zh_cn = '作为付丧神被困在筝里的感觉……？',
                }
            },
            [104] = {
                spellName = {
                    en_us = 'Dirge "Lost Path of Return"',
                    zh_cn = '葬曲「不知归路」',
                },
                quote = {
                    en_us = 'After funeral procession leaves, the soul wanders around, trying to find the way home.',
                    zh_cn = '送葬队伍离开后，灵魂徘徊在四周，试图找到回家的路。',
                }
            }
        },
    },
    ui = {
        START = {
            en_us = 'Start',
            zh_cn = '开始游戏',
        },
        REPLAY = {
            en_us = 'Replay',
            zh_cn = '录像回放',
        },
        OPTIONS = {
            en_us = 'Options',
            zh_cn = '设置',
        },
        MUSIC_ROOM = {
            en_us = 'Music Room',
            zh_cn = '音乐室',
        },
        NICKNAMES = {
            en_us = 'Nicknames',
            zh_cn = '称号',
        },
        EXIT = {
            en_us = 'Exit',
            zh_cn = '退出',
        },
        RESTART = {
            en_us = 'Restart',
            zh_cn = '重新开始',
        },
        SAVE_REPLAY = {
            en_us = 'Save Replay',
            zh_cn = '保存录像',
        },
        RESUME = {
            en_us = 'Resume',
            zh_cn = '继续',
        },
        master_volume = {
            en_us = 'Master Volume',
            zh_cn = '主音量',
        },
        music_volume = {
            en_us = 'Music Volume',
            zh_cn = '音乐音量',
        },
        sfx_volume = {
            en_us = 'SFX Volume',
            zh_cn = '音效音量',
        },
        language = {
            en_us = 'Language',
            zh_cn = '语言',
        },
        upgrades = {
            en_us = 'Upgrades',
            zh_cn = '升级',
        },
        upgradesUIHint = {
            en_us = 'X/C: Return  Z: Buy / Refund  D: Refund All',
            zh_cn = 'X/C: 返回  Z: 购买 / 取消升级  D: 取消全部',
        },
        upgradesCurrentXP = {
            en_us = 'Current XP: {xp}',
            zh_cn = '当前经验值: {xp}',
        },
        upgradesCostXP = {
            en_us = 'Cost: {xp} XP',
            zh_cn = '花费: {xp} 经验值',
        },
        level = {
            en_us = 'Day {level}',
            zh_cn = '第{level}日',
        },
        tryCount = {
            en_us = '{tries} tries',
            zh_cn = '挑战次数: {tries}',
        },
        firstPass = {
            en_us = 'First pass:\n{tries} tries',
            zh_cn = '首次通过\n挑战次数: {tries}',
        },
        firstPerfect = {
            en_us = 'First perfect:\n{tries} tries',
            zh_cn = '首次完美通过\n挑战次数: {tries}',
        },
        passedScenes = {
            en_us = 'Passed scenes: {passed}/{all}',
            zh_cn = '已通过场景: {passed}/{all}',
        },
        needSceneToUnlockNextLevel = {
            en_us = '{need} scenes to unlock next day',
            zh_cn = '通过{need}个场景\n解锁下一天',
        },
        playTimeOverall = {
            en_us = 'Playtime Overall:\n{playtime}',
            zh_cn = '总游戏时间: {playtime}',
        },
        playTimeInLevel = {
            en_us = 'Playtime in levels:\n{playtime}',
            zh_cn = '关卡内游戏时间: {playtime}',
        },
        levelUIHint = {
            en_us = 'C: Upgrades Menu',
            zh_cn = 'C: 升级菜单',
        },
        playerHP = {
            en_us = 'HP: {HP}',
            zh_cn = '生命值: {HP}',
        },
        paused = {
            en_us = 'Paused',
            zh_cn = '已暂停',
        },
        win = {
            en_us = 'You win!',
            zh_cn = '挑战成功',
        },
        lose = {
            en_us = 'You lose!',
            zh_cn = '满身疮痍',
        },
        timeout = { -- the spell card type is timeout
            en_us = 'T I M E O U T',
            zh_cn = '耐 久',
        },
        replaying = {
            en_us = 'Replaying',
            zh_cn = '回放中',
        },
        nicknameGet = {
            en_us = 'Get nickname:',
            zh_cn = '获得称号:',
        },
        replayDigitsEntered = {
            en_us = 'Digits entered: {digits}',
            zh_cn = '已输入数字: {digits}',
        }
    },
    musicData = {
        title = {
            name = {
                en_us = 'Hyperbolic Domain ~ Exponential Existence',
                zh_cn = '双曲域 ~ Exponential Existence',
            },
            description = {
                en_us = 'This is the title screen theme.\nHyperbolic geometry means exponential growth, so I used Fibonacci sequence time signature.\nSounds a little bit 8-bit retro?\nI can look at the zooming background for a long time.',
                zh_cn = '标题画面的主题曲。\n双曲几何意味着指数增长，所以我用了斐波那契数列的拍号。\n听起来有点8位复古？\n我可以看着不停缩放的背景很久呢。',
            },
        },
        level1 = {
            name = {
                en_us = 'The Dream of a Mathematician',
                zh_cn = '数学家之梦',
            },
            description = {
                en_us = 'By Shinanij\nThis is (currently) first half level\'s theme.\nThis time I tried to make the climax part the most cheerful and uplifting.\nAlthough the difficulty of no-damage clear is hellish, after all, gaming should be a joyful thing. So should mathematics.\nBy the way, which one would be more interested in visiting this space, a mathematician or a physicist?',
                zh_cn = 'By Shinanij\n这是（目前）前半关卡的主题曲。\n这次尝试把高潮部分写得最为欢乐，催人奋进。\n虽然无伤通关的难度是地狱，但是游戏总归是一件快乐的事。数学也应该是如此吧。\n话说数学家和物理学家，哪个会对来访这片空间更感兴趣呢？',
            },
        },
        level2 = {
            name = {
                en_us = 'Broader Sky',
                zh_cn = '更广阔的天空',
            },
            description = {
                en_us = 'This is (currently) second half level\'s theme.\nIt feels energetic and uplifting.\nThe intro gives me a feeling of celebrating Spring Festival (^^;\nHyperbolic sky, would be nearly pure black if considered again.',
                zh_cn = '这是（目前）后半关卡的主题曲。\n听起来充满活力和积极。\n前奏有一种强烈的庆祝春节的感觉(^^;\n双曲的天空，再想想的话，几乎是纯黑的吧。',
            },
        }
    },
    upgrades = {
        increaseHP = {
            name = {
                en_us = 'Increase HP',
                zh_cn = '增加生命值',
            },
            description = {
                en_us = 'Increase HP by 1',
                zh_cn = '增加1点生命值',
            },
        },
        regenerate = {
            name = {
                en_us = 'Regenerate',
                zh_cn = '生命回复',
            },
            description = {
                en_us = 'Increase HP by 0.024 per second',
                zh_cn = '每秒回复0.024点生命值',
            },
        },
        unyielding = {
            name = {
                en_us = 'Unyielding',
                zh_cn = '不屈',
            },
            description = {
                en_us = 'Shockwave when you are hit is bigger',
                zh_cn = '被弹后消弹范围更大',
            },
        },
        acrobat = {
            name = {
                en_us = 'Acrobat',
                zh_cn = '杂技演员',
            },
            description = {
                en_us = 'Each graze gives 0.005 HP',
                zh_cn = '每次擦弹回复0.005点生命值',
            },
        },
        flashbomb = {
            name = {
                en_us = 'Flash Bomb',
                zh_cn = '瞬雷',
            },
            description = {
                en_us = 'Release a flash bomb for every 100 grazes',
                zh_cn = '每擦弹100次释放一次瞬雷',
            },
        },
        amulet = {
            name = {
                en_us = 'Amulet',
                zh_cn = '护符',
            },
            description = {
                en_us = 'Player hitbox is 25% smaller',
                zh_cn = '判定点减小25%',
            },
        },
        homingShot = {
            name = {
                en_us = 'Homing Shot',
                zh_cn = '追尾射击',
            },
            description = {
                en_us = '2 rows of your shot become homing',
                zh_cn = '自机的2排子弹具有追踪效果',
            },
        },
        sideShot = {
            name = {
                en_us = 'Side Shot',
                zh_cn = '侧翼射击',
            },
            description = {
                en_us = 'Add 4 rows of side shot on each side',
                zh_cn = '自机两侧各发射4排子弹',
            },
        },
        backShot = {
            name = {
                en_us = 'Back Shot',
                zh_cn = '后方射击',
            },
            description = {
                en_us = 'Add 4 rows of back shot that do double damage',
                zh_cn = '自机向后方发射4排子弹，伤害加倍',
            },
        },
        familiarShot = {
            name = {
                en_us = 'Familiar Shot',
                zh_cn = '使魔射击',
            },
            description = {
                en_us = 'Your shots can hit enemy\'s familiars and do 1/4 damage',
                zh_cn = '自机子弹可以击中敌人的使魔，造成1/4伤害',
            },
        },
        vortex = {
            name = {
                en_us = 'Vortex',
                zh_cn = '漩涡',
            },
            description = {
                en_us = 'Create a vortex rounding you that can absorb bullets',
                zh_cn = '产生一个环绕自己的漩涡，可以吸收子弹',
            },
        },
        fixedHPDisplay = {
            name = {
                en_us = 'Fixed HP Display',
                zh_cn = '固定生命值显示',
            },
            description = {
                en_us = 'Show enemy HP at the top of the screen. (Wow, this is an upgrade?)',
                zh_cn = '在屏幕顶部显示敌人生命值。（哇，这也算升级？）',
            },
        },
        clairvoyance = {
            name = {
                en_us = 'Clairvoyance',
                zh_cn = '透视',
            },
            description = {
                en_us = 'The background on both sides is slightly transparent',
                zh_cn = '两侧背景略微透明',
            },
        },
        diagonalMover = {
            name = {
                en_us = 'Diagonal Mover',
                zh_cn = '角行者',
            },
            description = {
                en_us = 'You move faster when moving diagonally',
                zh_cn = '斜向移动时速度更快',
            },
        },
        homingShotII = {
            name = {
                en_us = 'Homing Shot II',
                zh_cn = '追尾射击II',
            },
            description = {
                en_us = '2 more rows of your shot become homing, but homing effect is reduced',
                zh_cn = '自机再多2排子弹具有追踪效果，但是追踪效果减弱',
            },
        },
        sideShotII = {
            name = {
                en_us = 'Side Shot II',
                zh_cn = '侧翼射击II',
            },
            description = {
                en_us = 'Increase side shot damage by 50%, but they spread more',
                zh_cn = '侧边子弹伤害增加50%，但是角度扩散',
            },
        },
        backShotII = {
            name = {
                en_us = 'Back Shot II',
                zh_cn = '后方射击II',
            },
            description = {
                en_us = 'Increase back shot damage by 50%, but they do less damage if you are close to enemy',
                zh_cn = '后方子弹伤害增加50%，但离敌人较近时伤害降低',
            },
        },
        counterShot = {
            name = {
                en_us = 'Counter Shot',
                zh_cn = '反击',
            },
            description = {
                en_us = 'You can shoot during invincible time after being hit',
                zh_cn = '被弹后的无敌时间可以射击',
            },
        },
        diskModels = {
            name = {
                en_us = 'Disk Models',
                zh_cn = '圆盘模型',
            },
            description = {
                en_us = 'Unlock Poincare Disk and Klein Disk models. Press E in level to switch model.',
                zh_cn = '解锁庞加莱圆盘和克莱因圆盘模型。在关卡中按E键切换模型。',
            },
        }
    },
    ---@type table<string, NicknameLocalization>
    nickname = {
        PassAllScenes = {
            name = {
                en_us = 'Hyperbolic Master',
                zh_cn = '双曲大师',
            },
            condition = {
                en_us = 'All scenes cleared',
                zh_cn = '通过所有场景',
            },
            description = {
                en_us = 'Congratulations! You have mastered the hyperbolic domain and all its challenges!',-- Hit Z to see the ending screen.',
                zh_cn = '恭喜你！你已经掌握了双曲域及其所有挑战！',--按Z键查看结局画面。',
            },
        },
        Pass1Scene = {
            name = {
                en_us = 'Hyperbolic Beginner',
                zh_cn = '双曲新手',
            },
            condition = {
                en_us = '1 scene cleared',
                zh_cn = '通过1个场景',
            },
            description = {
                en_us = 'The adventure begins here. Be prepared for mindblowing challenges ahead!',
                zh_cn = '冒险从这里开始。准备好迎接令人震撼的挑战吧！',
            },
        },
        Lose100Times = {
            name = {
                en_us = 'Necessary Pain',
                zh_cn = '必要的痛苦',
            },
            condition = {
                en_us = 'Lose 100 times',
                zh_cn = '满身疮痍100次',
            },
            description = {
                en_us = '100 times is just beginning. Come on and try again!',
                zh_cn = '100次只是开始。再来一次吧！',
            },
        },
        Take10DamageIn1Scene = {
            name = {
                en_us = 'Stoneskin',
                zh_cn = '石肤',
            },
            condition = {
                en_us = 'Take 10 damage in 1 scene',
                zh_cn = '在1个场景中受到10点伤害',
            },
            description = {
                en_us = 'Actually it\'s you regenerated much HP (^^;',
                zh_cn = '实际上是回复了很多生命值（^^;',
            },
            detail = {
                en_us = 'Most damage: {level}-{scene}, {amount} damage',
                zh_cn = '最高伤害: {level}-{scene}，{amount} 伤害',
            }
        },
        PerfectWinIn15Seconds = {
            name = {
                en_us = 'Speedrunner',
                zh_cn = '速通',
            },
            condition = {
                en_us = 'Clear a scene without taking damage in 15 seconds',
                zh_cn = '在15秒内无伤通过一个场景',
            },
            description = {
                en_us = 'Early spellcard is too easy when you have all the upgrades.',
                zh_cn = '当你拥有所有升级时，早期的符卡实在是太简单了。',
            },
            detail = {
                en_us = 'Fastest perfect win: {level}-{scene}, {time} seconds',
                zh_cn = '最快无伤通过: {level}-{scene}，{time} 秒',
            }
        },
        ThisIsTouhou = {
            name = {
                en_us = 'This is Touhou',
                zh_cn = '这就是东方',
            },
            condition = {
                en_us = 'Lose after main enemy has been defeated',
                zh_cn = '击破撞',
            },
            description = {
                en_us = 'The HP design is to reduce such situation...! So unlucky of you.',
                zh_cn = 'HP设计就是为了减少这种情况……！真是不幸。',
            },
        },
        HurrySickness = {
            name = {
                en_us = 'Hurry Sickness',
                zh_cn = '急躁症',
            },
            condition = {
                en_us = 'Clear a scene without taking damage and without focusing (pressing LShift)',
                zh_cn = '低速封印（不按LShift）无伤通过一个场景',
            },
            description = {
                en_us = 'To show the eccentricity of hyperbolic geometry, macrododging is more preferred in spellcard designs. So I suppose this nickname is not that hard to get.',
                zh_cn = '为了展示双曲几何的特性，大范围移动在符卡设计中更受欢迎。所以我想这个称号并不难获得。',
            },
        },
        VerticalThinking = {
            name = {
                en_us = 'Vertical Thinking',
                zh_cn = '纵向思维',
            },
            condition = {
                en_us = 'Clear a scene without taking damage and without pressing left or right',
                zh_cn = '左右封印（不按←/→）无伤通过一个场景',
            },
            description = {
                en_us = 'Did you try to find a scene designed for this nickname...',
                zh_cn = '你试着找为这个称号设计的场景……',
            },
        },
        LateralThinking = {
            name = {
                en_us = 'Lateral Thinking',
                zh_cn = '横向思维',
            },
            condition = {
                en_us = 'Clear a scene without taking damage and without pressing up or down',
                zh_cn = '上下封印（不按↑/↓）无伤通过一个场景',
            },
            description = {
                en_us = 'Or just try easiest scene?',
                zh_cn = '还是试试最简单的场景？',
            },
        },
        PerfectAllScenes = {
            name = {
                en_us = 'Hyperbolic Indigenous',
                zh_cn = '双曲原住民',
            },
            condition = {
                en_us = 'All scenes cleared without taking damage',
                zh_cn = '无伤通过所有场景',
            },
            description = {
                en_us = 'No way! You have achieved perfection in the hyperbolic domain! Please, feel free to tell me "I\'m indigeneous to hyperbolic domain" on social media.',
                zh_cn = '不可能！你在双曲域中达到了完美！请在社交媒体上告诉我“我是双曲域的原住民”。',
            },
        },
    }
}
