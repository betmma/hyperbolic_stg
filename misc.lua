function math.acosh(x)
    return math.log(x+(x*x-1)^0.5)
end

function math.atanh(x)
    return 0.5*math.log((1+x)/(1-x))
end

-- return 1 if x>0, -1 if x<0, 0 if x=0
function math.sign(x)
    return x>0 and 1 or x<0 and -1 or 0
end

-- sometimes (especially particle system) random numbers are needed each frame. The bad part of using math.random is it easily break every replay on slightest change of a particle. So use this function instead. seeds can be (obj, seed2) which expands to (obj.x, seed2, obj.y, obj.frame). seed2 is to generate different numbers for same obj at same frame.
-- and warning: the distribution is not even since it uses sin function.
function math.pseudoRandom(seed1,seed2,seed3,seed4)
    if type(seed1)=='table' then
        seed3=seed1.y
        seed4=seed1.frame
        seed1=seed1.x
    end
    seed1=seed1 or 0
    seed2=seed2 or 0
    seed3=seed3 or 0
    seed4=seed4 or 0

    local h
    h = seed1*4613213 + seed2*3424761393 + seed3*3543761393 + seed4*92014631
    h = h - seed1^2*135431 - seed2^2*976320 - seed3^2*463409 - seed4^2*123469
    
    return math.sin(h)*0.5+0.5
end

-- return 1 if x is even, -1 if x is odd
function math.mod2Sign(x)
    return x%2==0 and 1 or -1
end

-- return 1 or -1 randomly
function math.randomSign()
    return math.random(2)==1 and 1 or -1
end

function math.inRange(x,y,xmin,xmax,ymin,ymax)
    return x>xmin and x<xmax and y>ymin and y<ymax
end

-- Euclidean distance between two points
function math.distance(x1,y1,x2,y2)
    return ((x1-x2)^2+(y1-y2)^2)^0.5
end

function math.pointToLineDistance(x, y, x1, y1, x2, y2)
    local A = y2 - y1
    local B = x1 - x2
    local C = x2 * y1 - x1 * y2
    return math.abs(A * x + B * y + C) / ((A * A + B * B) ^ 0.5)
end

function math.rThetaPos(x,y,r,theta)
    return x+r*math.cos(theta),y+r*math.sin(theta)
end

function math.clamp(val, lower, upper)
    assert(val and lower and upper, "nil sent to math.Clamp")
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

-- return a value that is congruent with [val] modulo 2*[radius] in the range of [center-radius,center+radius]. Useful to wrap around 2pi radians. center and radius default to 0 and pi.
function math.modClamp(val,center,radius)
    center=center or 0
    radius=radius or math.pi
    return center+(val-center+radius)%(radius*2)-radius
end

---@param a number|string|table
---@param b? number
---@return number
-- this has some lore. I used a software called "Crazy Storm" to make spell cards years ago, and that software supports the "a+b" form, so I subconsciously use this form, but string could be inefficient. return random number in [a-b,a+b]. Warning: it always returns a float number.
function math.eval(a,b)
    if type(a)=='string' then -- old 'a+b' form
        a=math._evalStr(a)
    end
    if type(a)=='table' then -- old 'a+b' form replaced by table
        a,b=a[1],a[2]
    end
    if not b or b==0 then -- plain number or plain string number form
        return tonumber(a) or 0
    end
    local na = tonumber(a) -- new a, b form
    local nb = tonumber(b)
    return math.random()*nb*2+na-nb
end

-- input: 'a+b', return that number or random number in [a-b,a+b].
function math._evalStr(str)
    -- Check if the string is in the format 'a+b' where a can be negative
    local a, b = string.match(str, "([%-]?%d+%.?%d*)%+(%d+%.?%d*)")
    
    if a and b then
        return math.eval(a, b)
    else
        -- Otherwise, assume the string is just a number
        return tonumber(str) or 0
    end
end

---@return table|number
-- extract a and b from a+b string. used to replace string format with table format in bulletSpawner
function math._extractABfromstr(str)
    -- Check if the string is in the format 'a+b' where a can be negative
    local a, b = string.match(str, "([%-]?%d+%.?%d*)%+(%d+%.?%d*)")
    
    if a and b then
        return {tonumber(a), tonumber(b)}
    end

    return tonumber(str) or 0
end

-- randomly sample k elements from a table. If k is larger than the table size, k is considered as the table size.
function math.randomSample(table,k)
    local n=#table
    k=math.min(n,k)
    local result={}
    for i=1,k do
        local j=math.random(i,n)
        result[i]=table[j]
        table[j]=table[i]
    end
    return result
end

-- love is really silly to not provide arc without lines toward center
-- but anyway to draw hyperbolic arc it's better to have my own func
-- (the one in polyline can only draw arc < pi. think about it, there is no way a 3/4 circle can be drawn with only 1 scissor. also scissor doesn't apply transform)
function math.drawArc(x, y, r, s_ang, e_ang, numLines)
	local step = ((e_ang-s_ang) / numLines)
	local ang1 = s_ang
	local ang2 = 0
	local lineWidth=love.graphics.getLineWidth()
	for i=1,numLines do
		ang2 = ang1 + step
        love.graphics.setLineWidth((y + (math.sin(ang1) * r))/400*lineWidth)
		love.graphics.line(x + (math.cos(ang1) * r), y + (math.sin(ang1) * r),
			x + (math.cos(ang2) * r), y + (math.sin(ang2) * r))
		ang1 = ang2
	end
    love.graphics.setLineWidth(lineWidth)
end

-- format time in seconds to hh:mm:ss
-- example: 3661 -> 01:01:01
function math.formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local seconds = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end


function copy_table(O)
    local O_type = type(O)
    local copy
    if O_type == 'table' then
        copy = {}
        for k, v in next, O, nil do
            copy[copy_table(k)] = copy_table(v)
        end
        setmetatable(copy, getmetatable(O))
    else
        copy = O
    end
    return copy
end

local fontCache={}
local function getFont(path,size)
    if not fontCache[path] then
        fontCache[path]={}
    end
    if not fontCache[path][size] then
        fontCache[path][size]=love.graphics.newFont(path,size)
    end
    return fontCache[path][size]
end

Fonts={
    en_us='assets/m6x11plus.ttf',
    zh_cn='assets/Source Han Sans CN Heavy.otf'
}
-- set font size. The font changes with language. In menus like replay saving and loading, where character width is important and hardcoded for process, the forcedFont parameter should be set to Fonts.en_us.
function SetFont(size,forcedFont)
    if forcedFont then
        love.graphics.setFont(getFont(forcedFont,size))
        return
    end
    local font = getFont(Fonts.en_us, size)
    if G.language=='zh_cn' then
        size=size*0.8
        font=getFont(Fonts.zh_cn,size)
    end
    love.graphics.setFont(font)
end

local localization=require 'localization.localization'

-- get raw localize string containing {}. args is a table of keys, for example {'ui','start'}
local function getRawLocalizeString(args)
    local lang=G.language or 'en_us'
    local current=localization
    for key, value in ipairs(args) do
        if current[value] then
            current=current[value]
        elseif current['__default__'] then
            current=current['__default__']
        else
            return 'ERROR'
        end
    end
    if current[lang] then
        return current[lang]
    else
        return current['en_us']
    end
end

-- localize a string. args example: {'ui', 'upgradesCurrentXP', xp=100}
function Localize(args)
    local rawString=getRawLocalizeString(args)
    local result=rawString
    for key, value in pairs(args) do
        result=result:gsub('{'..key..'}',value)
    end
    result=result:gsub('{.-}','MISSING VALUE')
    return result
end

function isVersionSmaller(version1, version2)
    -- Split version strings into tables of numbers
    local function split_version(version)
        local result = {}
        for num in version:gmatch("%d+") do
            table.insert(result, tonumber(num))
        end
        return result
    end

    -- Split the versions into tables of numbers
    local v1 = split_version(version1)
    local v2 = split_version(version2)

    -- Compare each part of the version
    for i = 1, math.max(#v1, #v2) do
        local part1 = v1[i] or 0  -- If there's no part, consider it 0
        local part2 = v2[i] or 0  -- If there's no part, consider it 0

        if part1 < part2 then
            return true  -- version1 is less than version2
        elseif part1 > part2 then
            return false   -- version1 is greater than version2
        end
    end

    return false  -- versions are equal
end

function DirectionName2Dxy(direction)
    if direction==0 or direction=='up' or direction=='u' then
        return 0,-1
    elseif direction==1 or direction=='right' or direction=='r' then
        return 1,0
    elseif direction==2 or direction=='down' or direction=='d' then
        return 0,1
    elseif direction==3 or direction=='left' or direction=='l' then
        return -1,0
    end
    error('Invalid direction: '..tostring(direction))
end