local module = {}

local Chunks = {}
local Allos = require("Allos")
local mlib  = require("mlib")

local RenderList = nil

--// optimisations
local sin = math.sin
local cos = math.cos
local tan = math.tan
local rad = math.rad
local abs = math.abs
local min = math.min
local max = math.max

local pi = math.pi
local sqrt = math.sqrt
local floor = math.floor
local ceil = math.ceil
local huge = math.huge
local round = function(x) return floor(x + 0.5) end

local asin = math.asin
local acos = math.acos
local atan = math.atan

function module.MakeChunk(x, z) Chunks[x] = {}; Chunks[x][z] = {} end
function module.ChunckToWorld(cx, cz) return cx * 16, cz * 16 end
function module.WorldToChunk(wx, wz) return floor(wx / 16), floor(wz / 16) end
function module.WorldToChunkPos(wx, wz) return wx / 16, wz / 16 end

function module.GetChunk(x, z)
    if Chunks[x] == nil then return end
    return Chunks[x][z]
end

function module.CreateBlock(x, y, z)
    return Allos.Cube(nil, x, y, z, 0, 0, 0, 0.5, 0.5, 0.5, true, "EngineIcon.png")
end

function module.GenerateChunk(cx, cz)
    local Chunk = {}

    cx, cz = module.ChunckToWorld(cx, cz)
    for x = 0, 15, 1 do
        for y = 0, 0, 1 do
            for z = 0, 15, 1 do
                if Chunk[x] == nil then Chunk[x] = {} end
                if Chunk[x][y] == nil then Chunk[x][y] = {} end
                if Chunk[x][y][z] == nil then Chunk[x][y][z] = module.CreateBlock(x + cx + 0.5, y , z + cz + 0.5) end
            end
        end
    end

    return Chunk
end

function module.GetChunkAddMissing(x, z)
    local Chunk = module.GetChunk(x, z)
     if Chunk == nil then
        Chunk = module.GenerateChunk(x, z)
        if Chunks[x] == nil then Chunks[x] = {} end
        Chunks[x][z] = Chunk
        return Chunk
    end
    return Chunk
end

function module.GetBlocks(Chunk)
    local Blocks = {}

    for x, y_table in pairs(Chunk) do
        for y, z_table in pairs(y_table) do
            for z, block in pairs(z_table) do
                Blocks[#Blocks+1] = block
            end
        end
    end

    return Blocks
end

function module.GetBlock(x, y, z)
    x, z = x - 0.5, z - 0.5
    local ChunkX, ChunkZ = module.WorldToChunk(x, z)

    local Chunk = module.GetChunk(ChunkX, ChunkZ)
    if Chunk == nil then return end
    if Chunk[x] == nil then return end
    if Chunk[x][y] == nil then return end
    return Chunk[x][y][z] ~= nil
end

function module.ReadChunks(cam, render_distance)
    local cp = cam.pos
    local cx, cz = cp.x, cp.z
    cx, cz = module.WorldToChunk(cx, cz)

    --// Chunk Types:
    -- 0: Origin
    -- 1: SideL
    -- 2: SideR
    -- 3: Top
    -- 4: Bottom

    local Outter = {mlib.Vector3(cx, cz, 0)}
    local i = 0

    local List = {}

    while i < render_distance do
        local NewOutter = {}

        for _, ChunkPos in ipairs(Outter) do
            cx, cz = ChunkPos.x, ChunkPos.y
            local Chunk = module.GetChunkAddMissing(cx, cz)
            local Blocks = module.GetBlocks(Chunk)
            
            for j = 1, #Blocks, 1 do
                local Block = Blocks[j]
                local triangles = Block.triangles
                local pos = Block.position

                local T = module.GetBlock(pos.x, pos.y + 1, pos.z)
                local BT = module.GetBlock(pos.x, pos.y - 1, pos.z)
                local BK = module.GetBlock(pos.x, pos.y, pos.z + 1)
                local L = module.GetBlock(pos.x - 1, pos.y, pos.z)
                local R = module.GetBlock(pos.x + 1, pos.y, pos.z)
                local F = module.GetBlock(pos.x, pos.y, pos.z - 1)

                for k = 1, #triangles, 1 do

                    --NOTE: triangle occlution only works in center chunk, not in outter ones for some odd reason
                    
                    --if (T or BT or BK or L or R or F) and cx ~= 0 then assert(false, cx .. ", " .. cz) end
                    if k == 1 and T then goto continue end
                    if k == 2 and BK then goto continue end
                    if k == 3 and L then goto continue end
                    if k == 4 and BT then goto continue end
                    if k == 5 and R then goto continue end
                    if k == 6 and F then goto continue end
                    if k == 7 and T then goto continue end
                    if k == 8 and BK then goto continue end
                    if k == 9 and L then goto continue end
                    if k == 10 and BT then goto continue end
                    if k == 11 and R then goto continue end
                    if k == 12 and F then goto continue end

                    List[#List+1] = Allos.CloneTriangle(triangles[k], pos.x * 2, pos.y * 2, pos.z * 2)

                    :: continue ::
                end
            end

            local Type = ChunkPos.z
            if Type == 0 then
                NewOutter[#NewOutter+1] = mlib.Vector3(cx, cz + 1, 3) --// North
                NewOutter[#NewOutter+1] = mlib.Vector3(cx + 1, cz, 2) --// East
                NewOutter[#NewOutter+1] = mlib.Vector3(cx, cz - 1, 4) --// South
                NewOutter[#NewOutter+1] = mlib.Vector3(cx - 1, cz, 1) --// West
            elseif Type == 1 then
                NewOutter[#NewOutter+1] = mlib.Vector3(cx, cz + 1, 3) --// North
                NewOutter[#NewOutter+1] = mlib.Vector3(cx, cz - 1, 4) --// South
                NewOutter[#NewOutter+1] = mlib.Vector3(cx - 1, cz, 1) --// West
            elseif Type == 2 then
                NewOutter[#NewOutter+1] = mlib.Vector3(cx, cz + 1, 3) --// North
                NewOutter[#NewOutter+1] = mlib.Vector3(cx + 1, cz, 2) --// East
                NewOutter[#NewOutter+1] = mlib.Vector3(cx, cz - 1, 4) --// South
            elseif Type == 3 then
                NewOutter[#NewOutter+1] = mlib.Vector3(cx, cz + 1, 3) --// North
            elseif Type == 4 then
                NewOutter[#NewOutter+1] = mlib.Vector3(cx, cz - 1, 4) --// South
            end
        end

        i = i + 1

        for j = 1, #Outter, 1 do Outter[j] = nil end
        for j = 1, #NewOutter, 1 do Outter[j] = NewOutter[j] end
    end

    local RenderMesh = Allos.Mesh(0,0,0, 0,0,0, 1,1,1, "RenderMesh", true)
    RenderMesh.triangles = List

    return {RenderMesh}
end

function module.GetRenderList(cam, render_distance)
    return module.ReadChunks(cam, render_distance)
end

function module.StaticGetRenderList(cam, render_distance)
    if RenderList == nil then RenderList = module.ReadChunks(cam, render_distance) end
    return RenderList
end

return module