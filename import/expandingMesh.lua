---@class ExpandingMesh : Object
---@field mesh love.Mesh The internal LÖVE mesh object.
---@field capacity number The maximum number of vertices the internal mesh can hold.
---@field drawMode love.DrawMode The drawing mode for the mesh (e.g., "quads", "triangles").
---@field usageHint love.MeshUsage The usage hint for the mesh (e.g., "stream", "dynamic").
---@field texture love.Texture | nil The texture applied to the mesh.
--- much much worse than creating new mesh every frame. will cause periodically lag that becomes very severe after like 2 minutes. yay anti-optimization
local ExpandingMesh = Object:extend()

--- Creates a new auto-expanding mesh.
---@param initialCapacity integer The initial number of vertices the mesh can hold.
---@param drawMode love.DrawMode The primitive type used to draw the mesh. Defaults to "triangles".
---@param usageHint love.MeshUsage A hint for how the mesh will be used. Defaults to "stream".
function ExpandingMesh:new(initialCapacity, drawMode, usageHint)
    self.drawMode = drawMode or "triangles"
    self.usageHint = usageHint or "stream"
    self.capacity = initialCapacity or 128 -- Start with a reasonable default capacity

    self.texture = nil

    -- Create the initial internal mesh object
    self:_createMesh(self.capacity)
end

--- (Internal) Creates a new love.graphics.Mesh object with the given capacity.
---@param capacity integer The number of vertices to allocate.
function ExpandingMesh:_createMesh(capacity)
    self.mesh = love.graphics.newMesh(capacity, self.drawMode, self.usageHint)
  -- Re-apply texture if one was already set
    if self.texture then
        self.mesh:setTexture(self.texture)
    end
end


--- Adds one or more vertices to the buffer for this frame.
--- It will automatically expand the mesh if the capacity is exceeded.
---@param vertices table Each argument is a vertex table, e.g., {x, y, u, v, r, g, b, a}.
function ExpandingMesh:setVertices(vertices)
    local numNewVertices = #vertices

    -- Check if we need to expand *before* adding the new vertices
    if numNewVertices > self.capacity then
        self.capacity = math.max(numNewVertices, self.capacity * 2)
        self:_createMesh(self.capacity)
    end
    self.mesh:setVertices(vertices, 1, numNewVertices)
    self.mesh:setDrawRange(1, numNewVertices)
end

--- Sets the texture for the mesh.
---@param texture love.Texture The texture to use for drawing.
function ExpandingMesh:setTexture(texture)
    self.texture = texture
    self.mesh:setTexture(self.texture)
end

return ExpandingMesh