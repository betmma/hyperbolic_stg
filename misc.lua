function math.acosh(x)
    return math.log(x+(x*x-1)^0.5)
end

function math.inRange(x,y,xmin,xmax,ymin,ymax)
    return x>xmin and x<xmax and y>ymin and y<ymax
end

function math.distance(x1,y1,x2,y2)
    return ((x1-x2)^2+(y1-y2)^2)^0.5
end
function math.clamp(val, lower, upper)
    assert(val and lower and upper, "nil sent to math.Clamp")
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

---@return number?
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
        return tonumber(str)
    end
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