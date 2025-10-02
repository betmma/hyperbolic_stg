-- Lua 5.1/5.3 friendly hyperbolic funcs
local function cosh(x) return (math.exp(x) + math.exp(-x)) * 0.5 end
local function sinh(x) return (math.exp(x) - math.exp(-x)) * 0.5 end

-- Vec3 helpers
local function vlen(x, y, z) return math.sqrt(x*x + y*y + z*z) end
local function vnorm(x, y, z)
  local L = vlen(x, y, z)
  if L < 1e-8 then return 0, 0, 0, 0 end
  return x/L, y/L, z/L, L
end

-- Make a column-major 4x4 zero matrix
local function mzero()
  return {
    0,0,0,0,  -- col0
    0,0,0,0,  -- col1
    0,0,0,0,  -- col2
    0,0,0,0   -- col3
  }
end

-- Identity
local function mident()
  return {
    1,0,0,0,
    0,1,0,0,
    0,0,1,0,
    0,0,0,1
  }
end

-- Column-major set/get (c,r) with 0-based mind but Lua’s 1-based indexing
local function set(m, c, r, v) m[c*4 + r + 1] = v end
local function get(m, c, r) return m[c*4 + r + 1] end

-- Column-major mat4 multiply: out = A * B
local function mmul(A, B)
  local C = mzero()
  for c = 0, 3 do
    for r = 0, 3 do
      local s =
        get(A,0,r)*get(B,c,0) +
        get(A,1,r)*get(B,c,1) +
        get(A,2,r)*get(B,c,2) +
        get(A,3,r)*get(B,c,3)
      set(C, c, r, s)
    end
  end
  return C
end

-- GLSL-compatible Lorentz rotation about spatial axis (no time mixing)
-- axis: {x,y,z}, angle in radians
local function create_rotation_lorentz_matrix(axis, angle)
  local ax, ay, az = axis[1], axis[2], axis[3]
  if math.abs(angle) < 1e-5 or vlen(ax,ay,az) < 1e-4 then
    return mident()
  end

  ax, ay, az = vnorm(ax, ay, az)

  local s = math.sin(angle)
  local c = math.cos(angle)
  local t = 1 - c

  -- 3x3 spatial rotation in upper-left; time row/col is [0,0,0; 1]
  local M = mident()
  -- col 0
  set(M,0,0, t*ax*ax + c)
  set(M,0,1, t*ax*ay - s*az)
  set(M,0,2, t*ax*az + s*ay)
  -- col 1
  set(M,1,0, t*ax*ay + s*az)
  set(M,1,1, t*ay*ay + c)
  set(M,1,2, t*ay*az - s*ax)
  -- col 2
  set(M,2,0, t*ax*az - s*ay)
  set(M,2,1, t*ay*az + s*ax)
  set(M,2,2, t*az*az + c)
  -- time column stays (0,0,0,1)
  return M
end

-- GLSL-compatible Lorentz boost along spatial unit vector n by rapidity b
-- n: {x,y,z} direction, b: rapidity (distance on hyperboloid)
local function create_boost_lorentz_matrix(n, b)
  if math.abs(b) < 1e-5 then
    return mident()
  end
  local nx, ny, nz = n[1], n[2], n[3]
  if vlen(nx,ny,nz) < 1e-4 then
    return mident()
  end
  nx, ny, nz = vnorm(nx, ny, nz)

  local ch, sh = cosh(b), sinh(b)
  local k = ch - 1

  local L = mzero()
  -- spatial 3x3: I + (ch-1) n n^T
  set(L,0,0, 1 + k*nx*nx)
  set(L,0,1,     k*nx*ny)
  set(L,0,2,     k*nx*nz)
  set(L,1,0,     k*ny*nx)
  set(L,1,1, 1 + k*ny*ny)
  set(L,1,2,     k*ny*nz)
  set(L,2,0,     k*nz*nx)
  set(L,2,1,     k*nz*ny)
  set(L,2,2, 1 + k*nz*nz)
  -- time row in spatial columns
  set(L,0,3, sh*nx)  -- L_03
  set(L,1,3, sh*ny)  -- L_13
  set(L,2,3, sh*nz)  -- L_23
  -- spatial rows in time column
  set(L,3,0, sh*nx)  -- L_30
  set(L,3,1, sh*ny)  -- L_31
  set(L,3,2, sh*nz)  -- L_32
  -- time-time
  set(L,3,3, ch)

  return L
end

-- Build the full M_total = M_boost * M_rotation as in your GLSL
-- cam_rotation_axis1/2/3: {x,y,z}
-- cam_pitch/yaw/roll: radians
-- cam_translation: {bx, by, bz} interpreted as rapidities along x,y,z axes
local function build_lorentz_mat4(cam_pitch,cam_yaw,cam_roll,cam_translation)
  local axis1,axis2,axis3={1,0,0},{0,1,0},{0,0,1}
  -- Rotation component: R2(yaw) * R1(pitch) * R3(roll)
  local R2 = create_rotation_lorentz_matrix(axis2, cam_yaw)
  local R1 = create_rotation_lorentz_matrix(axis1, cam_pitch)
  local R3 = create_rotation_lorentz_matrix(axis3, cam_roll)
  local M_rotation = mmul(mmul(R2, R1), R3)

  -- Boost component: B(x, tx) * B(y, ty) * B(z, tz)
  local bx, by, bz = cam_translation[1], cam_translation[2], cam_translation[3]
  local Bx = create_boost_lorentz_matrix({1,0,0}, bx)
  local By = create_boost_lorentz_matrix({0,1,0}, by)
  local Bz = create_boost_lorentz_matrix({0,0,1}, bz)
  local M_boost = mmul(mmul(Bz, By), Bx)

  -- Total
  local M_total = mmul(M_rotation, M_boost)

  -- Return as a 16-number column-major table, ready for Shader:send("M_total", M_total)
  return M_total
end

-- Example usage with LÖVE:
-- local M = build_lorentz_mat4({1,0,0}, pitch, {0,1,0}, yaw, {0,0,1}, roll, {tx,ty,tz})
-- shader:send("M_total", M)
return {
  build_lorentz_mat4 = build_lorentz_mat4
}