--------------------------------------------------------------------------------
-- Complex Number Utilities
--------------------------------------------------------------------------------
local Complex = {}

---@alias ComplexNumber {re: number, im: number}

--- Creates a complex number.
---@param re number | ComplexNumber Real part or a complex number table
---@param im number? Imaginary part (optional if re is a ComplexNumber table)
---@return ComplexNumber
function Complex.new(re, im)
    if type(re) == "table" and re.re ~= nil then
        return { re = re.re, im = re.im or 0 }
    end
    return { re = re or 0, im = im or 0 }
end

setmetatable(Complex, {
    --- Creates a complex number when `Complex(...)` is called.
    ---@param re number | ComplexNumber Real part or a complex number table
    ---@param im number? Imaginary part (optional if re is a ComplexNumber table)
    ---@return ComplexNumber
    __call = function(self, ...) -- 'self' here will be the Complex table itself
        return Complex.new(...)
    end
})

--- Adds two complex numbers.
---@param z1 ComplexNumber
---@param z2 ComplexNumber
---@return ComplexNumber
function Complex.add(z1, z2)
    return { re = z1.re + z2.re, im = z1.im + z2.im }
end

--- Subtracts z2 from z1.
---@param z1 ComplexNumber
---@param z2 ComplexNumber
---@return ComplexNumber
function Complex.sub(z1, z2)
    return { re = z1.re - z2.re, im = z1.im - z2.im }
end

--- Multiplies two complex numbers.
---@param z1 ComplexNumber
---@param z2 ComplexNumber
---@return ComplexNumber
function Complex.mul(z1, z2)
    return {
        re = z1.re * z2.re - z1.im * z2.im,
        im = z1.re * z2.im + z1.im * z2.re
    }
end

--- Returns the complex conjugate of z.
---@param z ComplexNumber
---@return ComplexNumber
function Complex.conj(z)
    return { re = z.re, im = -z.im }
end

--- Divides z1 by z2.
---@param z1 ComplexNumber
---@param z2 ComplexNumber
---@return ComplexNumber
function Complex.div(z1, z2)
    local denominator = z2.re^2 + z2.im^2
    if denominator == 0 then
        -- This would represent infinity. How to handle depends on context.
        -- For Mobius, this means the input maps to the point at infinity.
        -- We could return a special value or error. For now, let's error for general division.
        -- In apply, we might handle it differently if a specific output for infinity is needed.
        error("Complex division by zero: ("..z2.re..","..z2.im..")")
    end
    local num = Complex.mul(z1, Complex.conj(z2))
    return { re = num.re / denominator, im = num.im / denominator }
end

--- Checks if a complex number is zero (within a tolerance).
---@param z ComplexNumber
---@param tol number? Tolerance, defaults to 1e-9
---@return boolean
function Complex.is_zero(z, tol)
    tol = tol or 1e-9
    return math.abs(z.re) < tol and math.abs(z.im) < tol
end

--- Converts a complex number to a string.
---@param z ComplexNumber
---@return string
function Complex.tostring(z)
    if z.im == 0 then
        return tostring(z.re)
    elseif z.re == 0 then
        return tostring(z.im) .. "i"
    elseif z.im < 0 then
        return tostring(z.re) .. " - " .. tostring(math.abs(z.im)) .. "i"
    else
        return tostring(z.re) .. " + " .. tostring(z.im) .. "i"
    end
end

-- Helper to ensure input is a complex number
local function ensure_complex(val)
    if type(val) == "number" then
        return Complex.new(val, 0)
    elseif type(val) == "table" and val.re ~= nil then
        return Complex.new(val.re, val.im or 0)
    else
        error("Invalid argument: expected number or complex table {re, im}, got: " .. pprint(val))
    end
end

--------------------------------------------------------------------------------
-- MobiusTransformation Class
--------------------------------------------------------------------------------

---@class MobiusTransformation : Object
---@description Represents a Mobius transformation f(z) = (az + b) / (cz + d).
---@field public a ComplexNumber Coefficient a
---@field public b ComplexNumber Coefficient b
---@field public c ComplexNumber Coefficient c
---@field public d ComplexNumber Coefficient d
local MobiusTransformation = Object:extend()

--- Constructor for MobiusTransformation.
--- Coefficients a, b, c, d can be numbers (real) or complex tables {re, im}.
---@param a number | ComplexNumber
---@param b number | ComplexNumber
---@param c number | ComplexNumber
---@param d number | ComplexNumber
function MobiusTransformation:new(a, b, c, d)
    self.a = ensure_complex(a)
    self.b = ensure_complex(b)
    self.c = ensure_complex(c)
    self.d = ensure_complex(d)

    -- Check determinant: ad - bc != 0
    local ad = Complex.mul(self.a, self.d)
    local bc = Complex.mul(self.b, self.c)
    local determinant = Complex.sub(ad, bc)

    if Complex.is_zero(determinant) then
        error("Mobius transformation is degenerate: ad - bc = 0")
    end
end

--- Applies the Mobius transformation to a complex number z.
--- z can be a number (real) or a complex table {re, im}.
---@param z number | ComplexNumber
---@return ComplexNumber | "infinity" The transformed complex number, or "infinity" if denominator is zero.
function MobiusTransformation:apply(z)
    local z_complex = ensure_complex(z)

    local numerator = Complex.add(Complex.mul(self.a, z_complex), self.b)
    local denominator = Complex.add(Complex.mul(self.c, z_complex), self.d)

    if Complex.is_zero(denominator) then
        -- Conventionally, this maps to the point at infinity.
        -- For simplicity, we can return a string or a special table.
        -- A string is easier for quick checks.
        return "infinity"
    end

    return Complex.div(numerator, denominator)
end

--- Returns the inverse of this Mobius transformation.
--- The inverse of f(z) = (az+b)/(cz+d) is g(z) = (dz-b)/(-cz+a).
---@return MobiusTransformation
function MobiusTransformation:inverse()
    -- new_a = d
    -- new_b = -b
    -- new_c = -c
    -- new_d = a
    local neg_b = Complex.mul(Complex.new(-1, 0), self.b)
    local neg_c = Complex.mul(Complex.new(-1, 0), self.c)
    return MobiusTransformation(self.d, neg_b, neg_c, self.a)
end

--- Composes this transformation with another Mobius transformation.
--- If this is T1 and `other` is T2, computes T1(T2(z)).
--- T1(z) = (a1*z + b1)/(c1*z + d1)
--- T2(z) = (a2*z + b2)/(c2*z + d2)
--- T1(T2(z)) has coefficients:
--- new_a = a1*a2 + b1*c2
--- new_b = a1*b2 + b1*d2
--- new_c = c1*a2 + d1*c2
--- new_d = c1*b2 + d1*d2
---@param other MobiusTransformation The other transformation (T2)
---@return MobiusTransformation The composed transformation (T1 o T2)
function MobiusTransformation:compose(other)
    if not other:is(MobiusTransformation) then
        error("Argument to compose must be a MobiusTransformation")
    end

    local a1, b1, c1, d1 = self.a, self.b, self.c, self.d
    local a2, b2, c2, d2 = other.a, other.b, other.c, other.d

    local new_a = Complex.add(Complex.mul(a1, a2), Complex.mul(b1, c2))
    local new_b = Complex.add(Complex.mul(a1, b2), Complex.mul(b1, d2))
    local new_c = Complex.add(Complex.mul(c1, a2), Complex.mul(d1, c2))
    local new_d = Complex.add(Complex.mul(c1, b2), Complex.mul(d1, d2))

    return MobiusTransformation(new_a, new_b, new_c, new_d)
end

--- Provides a string representation of the Mobius transformation.
---@return string
function MobiusTransformation:__tostring()
    return string.format("MobiusTransformation: f(z) = (%s * z + %s) / (%s * z + %s)",
        Complex.tostring(self.a), Complex.tostring(self.b),
        Complex.tostring(self.c), Complex.tostring(self.d))
end

return {Complex,MobiusTransformation}