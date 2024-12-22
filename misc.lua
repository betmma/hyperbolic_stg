function math.acosh(x)
    return math.log(x+(x*x-1)^0.5)
end

function math.sign(x)
    return x>0 and 1 or x<0 and -1 or 0
end

function math.inRange(x,y,xmin,xmax,ymin,ymax)
    return x>xmin and x<xmax and y>ymin and y<ymax
end

-- Euclidean distance between two points
function math.distance(x1,y1,x2,y2)
    return ((x1-x2)^2+(y1-y2)^2)^0.5
end

function math.clamp(val, lower, upper)
    assert(val and lower and upper, "nil sent to math.Clamp")
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

-- return a value that is congruent with [val] modulo 2*[radius] in the range of [center-radius,center+radius]. Useful to wrap around a circle.
function math.modClamp(val,center,radius)
    return center+(val-center+radius)%(radius*2)-radius
end

---@return number
-- input: a number or 'a+b', return that number or random number in [a-b,a+b]. Warning: it returns a float number for 'a+b'.
function math.eval(str)
    -- Check if the string is in the format 'a+b' where a can be negative
    local a, b = string.match(str, "([%-]?%d+%.?%d*)%+(%d+%.?%d*)")
    
    if a and b then
        -- Convert a and b to numbers
        a = tonumber(a)
        b = tonumber(b)
        -- Return a random number in the range [a-b, a+b]
        return math.random()*b*2+a-b
    else
        -- Otherwise, assume the string is just a number
        return tonumber(str) or 0
    end
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
        love.graphics.setLineWidth((y + (math.sin(ang1) * r))/400)
		love.graphics.line(x + (math.cos(ang1) * r), y + (math.sin(ang1) * r),
			x + (math.cos(ang2) * r), y + (math.sin(ang2) * r))
		ang1 = ang2
	end
    love.graphics.setLineWidth(lineWidth)
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

function SetFont(size)
    local font = love.graphics.setNewFont('assets/m6x11plus.ttf', size)
    love.graphics.setFont(font)
end