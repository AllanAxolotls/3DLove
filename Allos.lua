-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
--// Allos3D by Allan //--
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

local Allos = {}

--// Libraries
local mlib = require("mlib")

--// Main Settings
local SCREEN_WIDTH = 1920
local SCREEN_HEIGHT = 1080
local HALF_WIDTH = SCREEN_WIDTH / 2
local HALF_HEIGHT = SCREEN_HEIGHT / 2

local FOV = 30
local NEAR = 0.1
local FAR = 1000

local WhiteColor = {1,1,1}
local RedColor = {1,0,0}
local GreenColor = {0,1,0}
local BlueColor = {0,0,1}

local VertexAttributes = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoord", "float", 2},
    {"VertexNormal", "float", 3},
    {"VertexColor", "float", 4}
}

--// Allos Settings
Allos.DefaultTexture = nil
Allos.ObjectDirectory = "Objects/"
Allos.TextureDirectory = "Textures/"
Allos.MouseSensivity = 0.7
Allos.QuitMap = false

Allos.Errors = {
    MaterialMissing = false
}

--// Main Variables
local ProjectionMatrix = mlib.IdentityMatrix4()
local ProjectionShader = love.graphics.newShader(love.filesystem.read("VS.vert") or "", love.filesystem.read("FS.frag") or "")
local MainCanvas = nil
local ShadowCanvas = nil
local DepthCanvas = nil
local ShadowMap = nil

Allos.Workspace = {}
Allos.BaseLights = {}
Allos.DirLights = {}
Allos.PointLights = {}
Allos.SpotLights = {}

Allos.Timer = 0
Allos.ObjectCount = 0
Allos.TriangleCount = 0

--// Love
local LG = love.graphics
local LK = love.keyboard
local LI = love.image
local LW = love.window

--// optimisations
local sin, cos, tan = math.sin, math.cos, math.tan
local rad, deg = math.rad, math.deg
local min, max = math.min, math.max
local floor, ceil, abs = math.floor, math.ceil, math.abs
local pi, huge = math.pi, math.huge
local num = tonumber
local sqrt, exp = math.sqrt, math.exp
local random = math.random

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
--// Init //--
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

function Allos.Settings(Width, Height, Fov, Near, Far)
    SCREEN_WIDTH = Width or 1920
    SCREEN_HEIGHT = Height or 1080

    HALF_WIDTH = SCREEN_WIDTH / 2
    HALF_HEIGHT = SCREEN_HEIGHT / 2

    FOV = Fov or 30
    NEAR = Near or 0.1
    FAR = Far or 1000
end

function Allos.Init(Width, Height, Fov, Near, Far)
    Allos.Settings(Width, Height, Fov, Near, Far)
    ProjectionMatrix = mlib.ProjectionMatrix(NEAR, FAR, FOV)
    MainCanvas = LG.newCanvas(Width, Height)
    ShadowCanvas = LG.newCanvas(Width, Height)
    DepthCanvas = LG.newCanvas(Width, Height, {type="2d",format="depth32f",readable=true})
    ShadowMap = LG.newCanvas(Width, Height, {type="2d",format="depth32f",readable=true})

    LW.setMode(Width, Height, {fullscreen=false,resizable=true})
    LG.setMeshCullMode("back")
    LG.setBackgroundColor(0.5,0.5,0.9,1)

    Allos.MainCamera = Allos.Camera()
    Allos.MainLight = Allos.SpotLight()
    Allos.Sun = Allos.DirectionalLight()

    Allos.Skybox = Allos.LoadObjectFile("Skybox", false)[1]
    Allos.Skybox:SetSize(0.001, 0.001, 0.001)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
--// Simple Render //--
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

function Allos.WriteCanvas(Iter)
    --Allos.Render(Iter, ShadowCanvas, ShadowMap, nil)
    Allos.Render(Iter, MainCanvas, DepthCanvas, ShadowMap)
end

function Allos.DrawCanvas()
    LG.setColor(1,1,1)
    LG.setDepthMode()
    LG.draw(MainCanvas, 0,0,0, 1,1)
    --LG.draw(ShadowMap, 0,0,0, 0.4,0.4)
    --LG.print("\t" .. love.timer.getFPS())

    --LG.print("\n\n\n\n\n\n\n\t" .. mlib.Cos(0.3) .. ", " .. cos(0.3))
end

function Allos.Update(dt)
    Allos.Timer = Allos.Timer + 1
    Allos.Skybox.position:Set(Allos.MainCamera.pos)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
--// Utility //--
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

function Allos.SplitString(x, Seperator)
	local t, i = {}, 1
	for str in string.gmatch(x, "([^".. Seperator .."]+)") do t[i] = str; i = i + 1 end
	return t
end; local SplitString = Allos.SplitString

function Allos.ArrayToString(Array)
    local Result, i = "", 0
    for k, v in pairs(Array) do
        i = i + 1
        if type(v) == "table" then v = Allos.ArrayToString(v) end
        if type(v) ~= "userdata" then Result = Result .. "\n[" .. k .. "]: " .. v end
        if i ~= #Array then Result = Result .. ", " end
    end
    if Result == "" and i == 0 then return "nil" end
    return Result
end; local ArrayToString = Allos.ArrayToString

function Allos.RandomColor()
    return random(0, 100) / 100, random(0, 100) / 100, random(0, 100) / 100, 1
end; local RandomColor = Allos.RandomColor

function Allos.Lock(x, MinValue, MaxValue)
    return max(min(x, MaxValue), MinValue)
end; local lock = Allos.Lock

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
--// Classes //--
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

--// Materials
local MaterialClass = {Type="Material"}
MaterialClass.__index = MaterialClass

function MaterialClass.new()
    local self = setmetatable({
        Ka = {1,1,1}; Kd = {1,1,1}; Ks = {0,0,0}; Ke = 0;
        Ns = 0; Ni = 0;
        illum = 0;
        d = 1;
        map_Ka = nil; map_Kd = nil; map_Ks = nil; map_Bump = nil;
    }, MaterialClass)
    return self
end

--// Meshes
local MeshClass = {Type="Mesh"}
MeshClass.__index = MeshClass

function Allos.Mesh(px, py, pz, rx, ry, rz, sx, sy, sz, name, shaded)
    local self = setmetatable({
        position = mlib.Vector3(px, py, pz);
        rotation = mlib.Vector3(rx, ry, rz);
        size = mlib.Vector3(sx or 1, sy or 1, sz or 1);

        triangles = {};
        material = MaterialClass.new();
        name = name or "Mesh";
        shaded = shaded == nil and true or shaded;
    }, MeshClass)
    local temp = self.name
    local i = 1
    while Allos.Workspace[self.name] ~= nil do
        self.name = temp .. i
        i = i + 1
    end
    Allos.Workspace[self.name] = self
    return self
end

function Allos.MeshTriangle(
        Position1, TexCoord1, Normal1, Color1,
        Position2, TexCoord2, Normal2, Color2,
        Position3, TexCoord3, Normal3, Color3,
        Texture
    )
    local Mesh = LG.newMesh(VertexAttributes, {
        {Position1.x, Position1.y, Position1.z, TexCoord1.x, TexCoord1.y, Normal1.x, Normal1.y, Normal1.z, Color1[1], Color1[2], Color1[3], Color1[4]},
        {Position2.x, Position2.y, Position2.z, TexCoord2.x, TexCoord2.y, Normal2.x, Normal2.y, Normal2.z, Color2[1], Color2[2], Color2[3], Color2[4]},
        {Position3.x, Position3.y, Position3.z, TexCoord3.x, TexCoord3.y, Normal3.x, Normal3.y, Normal3.z, Color3[1], Color3[2], Color3[3], Color3[4]}
    }, "triangles", "static")
    Mesh:setTexture(Texture)
    return Mesh
end

function Allos.CloneTriangle(Triangle, opx, opy, opz)
    local Vertices = {}

    for i = 1, 3, 1 do
        local x, y, z, u, v, nx, ny, nz, r, g, b, a = Triangle:getVertex(i)
        Vertices[i] = {x + opx, y + opy, z + opz, u, v, nx, ny, nz, r, g, b, a}
    end

    local Mesh = LG.newMesh(VertexAttributes, Vertices, "triangles", "static")
    Mesh:setTexture(Triangle:getTexture())
    return Mesh
end

function MeshClass:SetTriangles(List)
    for _, Triangle in ipairs(List) do self.triangles[#self.triangles+1] = Allos.MeshTriangle(unpack(Triangle), self.material.map_Ka) end
end

function Allos.Cube(name, px, py, pz, rx, ry, rz, sx, sy, sz, shaded, TextureName)
    local Mesh = Allos.LoadObjectFile("Cube2", shaded or true, TextureName)[1] --// We get first index, because table of meshes
    Mesh.position:SetXYZ(px, py, pz)
    Mesh.rotation:SetXYZ(rx, ry, rz)
    Mesh.size:SetXYZ(sx, sy, sz)
    --Mesh.name = name or ("Cube" .. (Allos.ObjectCount + 1))
    return Mesh
end

function Allos.BoundBoxCorner(Cube)
    local sx, sy, sz = Cube.size.x, Cube.size.y, Cube.size.z
    local px, py, pz = Cube.position.x, Cube.position.y, Cube.position.z
    local hsx, hsy, hsz = sx / 2, sy / 2, sz / 2
    return mlib.Vector3(px - hsx, py - hsy, pz - hsz)
end

function Allos.FormatPath(Path)
    local Result = Path:gsub("_diff", "")
    Result = Result:gsub("%s", "")
    return Result
end

function Allos.LoadMaterialFile(Directory, FileName, fmap_Ka)
    local FileMtl = FileName .. ".mtl"
    local File = love.filesystem.read(Directory .. FileMtl)
    local TexDir = Directory .. "Textures/"
    if Allos.Errors.MaterialMissing then assert(File ~= nil, "File not found: " .. FileMtl) elseif File == nil then return end

    local Material, Result = nil, {}
    if fmap_Ka then fmap_Ka = LG.newImage(Allos.FormatPath(TexDir .. fmap_Ka)) end

    local Lines = SplitString(File, "\n")
    for LineIndex, Line in ipairs(Lines) do
        local Tokens = SplitString(Line, "%s")
        local Prefix, x, y, z = Tokens[1], Tokens[2], Tokens[3], Tokens[4]

        if Prefix == "Material" then --// Type of material
        elseif Prefix == "Ka" then Material.Ka = {x, y, z, 1} --// Ambient Color
        elseif Prefix == "Kd" then Material.Kd = {x, y, z, 1} --// Diffuse Color
        elseif Prefix == "Ks" then Material.Ks = {x, y, z, 1} --// Specular Color
        elseif Prefix == "Ke" then
        elseif Prefix == "Ns" then Material.Ns = x --// Specular Exponent
        elseif Prefix == "Ni" then Material.Ni = x --// Optical Density
        elseif Prefix == "d" then Material.d = x --// opaque
        elseif Prefix == "refl" then
        elseif Prefix == "illum" then Material.illum = x
        elseif Prefix == "map_Ka" then Material.map_Ka = fmap_Ka or LG.newImage(Allos.FormatPath(TexDir .. x))
        elseif Prefix == "map_Kd" then Material.map_Kd = LG.newImage(Allos.FormatPath(TexDir .. x))
        elseif Prefix == "map_Ks" then Material.map_Ks = LG.newImage(Allos.FormatPath(TexDir .. x))
        elseif Prefix == "map_Bump" then Material.map_Bump = LG.newImage(Allos.FormatPath(TexDir .. x))
        elseif Prefix == "newmtl" then
            Material = MaterialClass.new()
            Result[x] = Material
        end
    end

    if fmap_Ka then Material.map_Ka = fmap_Ka end

    return Result
end

function Allos.LoadObjectFile(FileName, shaded, fmap_Ka)
    local Directory = Allos.ObjectDirectory .. FileName .. "/"
    local FileObj = FileName .. ".obj"
    local File = love.filesystem.read(Directory .. FileObj)
    assert(File ~= nil, "File not found: " .. FileObj)

    local Vertices, TexCoords, Normals, Materials = {}, {}, {}, nil
    local Object, Result = nil, {}

    local Lines = SplitString(File, "\n")
    for LineIndex, Line in ipairs(Lines) do
        local Tokens = SplitString(Line, " ")
        local Prefix, x, y, z = Tokens[1], Tokens[2], Tokens[3], Tokens[4]

        if Prefix == "v" then Vertices[#Vertices+1] = mlib.Vector3(num(x), num(y), num(z))
        elseif Prefix == "vt" then TexCoords[#TexCoords+1] = mlib.Vector2(num(x), 1-num(y))
        elseif Prefix == "vn" then Normals[#Normals+1] = mlib.Vector3(num(x), num(y), num(z))
        elseif Prefix == "s" then --// Smoooth shading
        elseif Prefix == "f" then
            --// Triangle
            local Segments1, Segments2, Segments3 = SplitString(x, "/"), SplitString(y, "/"), SplitString(z, "/")
            Object.triangles[#Object.triangles+1] = Allos.MeshTriangle(
                Vertices[num(Segments1[1])], TexCoords[num(Segments1[2])], Normals[num(Segments1[3])], WhiteColor,
                Vertices[num(Segments2[1])], TexCoords[num(Segments2[2])], Normals[num(Segments2[3])], WhiteColor,
                Vertices[num(Segments3[1])], TexCoords[num(Segments3[2])], Normals[num(Segments3[3])], WhiteColor,
                Object.material.map_Ka
            )

            --// Quad
            if Tokens[5] then
                local Segments4 = SplitString(Tokens[5], "/")
                Object.triangles[#Object.triangles+1] = Allos.MeshTriangle(
                    Vertices[num(Segments1[1])], TexCoords[num(Segments1[2])], Normals[num(Segments1[3])], WhiteColor,
                    Vertices[num(Segments3[1])], TexCoords[num(Segments3[2])], Normals[num(Segments3[3])], WhiteColor,
                    Vertices[num(Segments4[1])], TexCoords[num(Segments4[2])], Normals[num(Segments4[3])], WhiteColor,
                    Object.material.map_Ka
                )
            end
        elseif Prefix == "g" then --// Add: Prefix == "o"
            Object = Allos.Mesh(nil,nil,nil, nil,nil,nil, nil,nil,nil, x,shaded)
            Result[#Result+1] = Object
        elseif Prefix == "usemtl" then
            if Allos.Errors.MaterialMissing then assert(Materials ~= nil, "'usemtl' on line: '" .. LineIndex .. "', but no materials were loaded. 'mtllib' missing in file: " .. FileObj) end
            if Materials then Object.material = Materials[x] end
        elseif Prefix == "mtllib" then
            Materials = Allos.LoadMaterialFile(Directory, FileName, fmap_Ka)
        end
    end

    return Result
end

function MeshClass:SetPosition(x, y, z)
    if mlib.Class(x) == "Vector" then self.position:Set(x)
    else self.position.x = x; self.position.y = y; self.position.z = z end
end

function MeshClass:SetRotation(x, y, z)
    if mlib.Class(x) == "Vector" then self.rotation:Set(x)
    else self.rotation.x = x; self.rotation.y = y; self.rotation.z = z end
end

function MeshClass:SetSize(x, y, z)
    if mlib.Class(x) == "Vector" then self.size:Set(x)
    else self.size.x = x; self.size.y = y; self.size.z = z end
end

--// Camera
local CameraClass = {}
CameraClass.__index = CameraClass

function Allos.Camera()
    local self = setmetatable({
        pos = mlib.Vector3();
        rot = mlib.Vector3(); --// Pitch, Yaw, Roll
        target = mlib.Vector3(0, 0, 1);
        up = mlib.Vector3(0, 1, 0);

        speed = 30;
        turnspeed = 0.7;
        accelerate = 1;
        decelerate = 1;
    }, CameraClass)
    return self
end

function CameraClass:View()
    local Pos, Target, Up = self.pos, self.target, self.up
    local CameraTranslation = mlib.TranslationMatrix4(-Pos.x, -Pos.y, -Pos.z)
    local CameraRotateTrans = mlib.CameraTransform(Target, Up)
    return CameraRotateTrans * CameraTranslation
end

function CameraClass:Move(dx, dy, dz)
    if mlib.Class(dx) == "Vector" then dy = dx.y; dz = dx.z; dx = dx.x end
    self.pos.x = self.pos.x + dx
    self.pos.y = self.pos.y + dy
    self.pos.z = self.pos.z + dz
end

function CameraClass:RotateTo(Pitch, Yaw, Roll)
    local RX, RY, RZ = mlib.XRotationMatrix4(Pitch), mlib.YRotationMatrix4(Yaw), mlib.ZRotationMatrix4(Roll)
    self.target:Set(RZ * (RY * (RX * mlib.Vector4(0, 0, 1, 1)))) --// target is vec3, so 'w' data gets lost
end


--// Lights
local BaseLightClass = {}
BaseLightClass.__index = BaseLightClass

function Allos.BaseLight()
    local self = setmetatable({
        Color = {1, 1, 1};
        AmbientIntensity = 1;
        DiffuseIntensity = 1;
    }, BaseLightClass)
    Allos.BaseLights[#Allos.BaseLights+1] = self
    return self
end

local DirectionalLightClass = {}
DirectionalLightClass.__index = DirectionalLightClass

function Allos.DirectionalLight()
    local self = setmetatable({
        Color = {1, 1, 1};
        AmbientIntensity = 1;
        DiffuseIntensity = 1;

        WorldDirection = mlib.Vector3();

        LocalDirection = mlib.Vector3();
    }, DirectionalLightClass)
    Allos.DirLights[#Allos.DirLights+1] = self
    return self
end

function DirectionalLightClass:CalcLocalDirection(World)
   self.LocalDirection = mlib.WorldToLocal(World, self.WorldDirection):Normalise()
end

local PointLightClass = {}
PointLightClass.__index = PointLightClass

function Allos.PointLight()
    local self = setmetatable({
        Color = {1, 1, 1};
        AmbientIntensity = 1;
        DiffuseIntensity = 1;

        WorldPosition = mlib.Vector3();
        Constant = 1;
        Linear = 0;
        Quadratic = 0;

        LocalPosition = mlib.Vector3();
    }, PointLightClass)
    Allos.PointLights[#Allos.PointLights+1] = self
    return self
end

function PointLightClass:CalcLocalPosition(World)
    self.LocalPosition = mlib.WorldToLocal(World, self.WorldPosition)
end

local SpotLightClass = {}
SpotLightClass.__index = SpotLightClass

function Allos.SpotLight()
    local self = setmetatable({
        Color = {1, 1, 1};
        AmbientIntensity = 1;
        DiffuseIntensity = 1;

        WorldPosition = mlib.Vector3();
        WorldDirection = mlib.Vector3();
        Constant = 1;
        Linear = 0;
        Quadratic = 0.00005;
        Cutoff = 20;

        LocalPosition = mlib.Vector3();
        LocalDirection = mlib.Vector3();
    }, SpotLightClass)
    Allos.SpotLights[#Allos.SpotLights+1] = self
    return self
end

function SpotLightClass:CalcLocalPositionAndDirection(World)
    self.LocalDirection = mlib.WorldToLocal(World, self.WorldDirection):Normalise()
    self.LocalPosition = mlib.WorldToLocal(World, self.WorldPosition)
end

function SpotLightClass:View()
    local Pos, Target, Up = self.LocalPosition, self.LocalDirection, mlib.VectorY1
    local CameraTranslation = mlib.TranslationMatrix4(-Pos.x, -Pos.y, -Pos.z)
    local CameraRotateTrans = mlib.CameraTransform(Target, Up)
    return CameraRotateTrans * CameraTranslation
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
--// Controls //--
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

local Panning = false

function Allos.MousePressed(X, Y, Button) --// If mouse is down (not released yet)
    if Button ~= 2 then return end
    Panning = true
    MouseX, MouseY = X, Y
    StartPanX, StartPanY = X, Y
    love.mouse.setGrabbed(true)
end

function Allos.MouseReleased(X, Y, Button)
    if Button ~= 2 then return end
    Panning = false
    love.mouse.setGrabbed(false)
    love.mouse.setVisible(true)
end

function Allos.UpdateMousePan(dt)
    if Panning then
        love.mouse.setVisible(false)
        NewMouseX, NewMouseY = love.mouse.getX(), love.mouse.getY()
        local DifferenceX, DifferenceY
        DifferenceX = NewMouseX - MouseX
        DifferenceY = NewMouseY - MouseY

        Allos.MainCamera.rot.y = Allos.MainCamera.rot.y - DifferenceX * dt * Allos.MouseSensivity
        Allos.MainCamera.rot.x = lock(Allos.MainCamera.rot.x - DifferenceY * dt * Allos.MouseSensivity, -1.5, 1.5)

        --// Reset Mouse Position
        love.mouse.setPosition(HALF_WIDTH, HALF_HEIGHT)
    end
    MouseX, MouseY = HALF_WIDTH, HALF_HEIGHT
end

function Allos.Controls(dt)
    if LK.isDown("escape") then
        Allos.QuitMap = true
        love.event.quit(1)
    end
    if LK.isDown("r") then love.event.quit("restart") end

    local Camera = Allos.MainCamera
    local Target, Up, Speed = Camera.target, Camera.up, Camera.speed * dt

    local TargetYLock = Target:Copy()
    TargetYLock.y = 0
    TargetYLock:Normalise()

    if LK.isDown('w') then Camera:Move(TargetYLock * Speed) end
    if LK.isDown('s') then Camera:Move(TargetYLock * -Speed) end
    if LK.isDown("space") then Camera:Move(Up * Speed) end
    if LK.isDown("lshift") or LK.isDown("rshift") then Camera:Move(Up * -Speed) end
    if LK.isDown('a') then
        local Left = Up:Cross(Target) --// Flipped (Target, Up)
        Left:Normalise()
        Camera:Move(Left * Speed)
    end
    if LK.isDown('d') then
        local Right = Target:Cross(Up) --// Flipped (Up, Target)
        Right:Normalise()
        Camera:Move(Right * Speed)
    end

    if LK.isDown("q") then Camera.speed = Camera.speed + Camera.accelerate end
    if LK.isDown("e") then Camera.speed = Camera.speed - Camera.decelerate end

    if LK.isDown("up") then Camera.rot.x = lock(Camera.rot.x + Camera.turnspeed * dt, -1.5, 1.5) end
    if LK.isDown("down") then Camera.rot.x = lock(Camera.rot.x - Camera.turnspeed * dt, -1.5, 1.5) end
    if LK.isDown("right") then Camera.rot.y = Camera.rot.y - Camera.turnspeed * dt end
    if LK.isDown("left") then Camera.rot.y = Camera.rot.y + Camera.turnspeed * dt end

    Camera:RotateTo(Camera.rot.x, Camera.rot.y, Camera.rot.z)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
--// Render Calculations //--
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

function Allos.SendMaterial(Material)
    ProjectionShader:send("Ka", Material.Ka)
    ProjectionShader:send("Kd", Material.Kd)
    ProjectionShader:send("Ks", Material.Ks)
    ProjectionShader:send("Ns", Material.Ns)
    ProjectionShader:send("d", Material.d)
end

function Allos.UpdateLights(WorldMatrix)
    for _, DirLight in ipairs(Allos.DirLights) do DirLight:CalcLocalDirection(WorldMatrix) end
    for _, PointLight in ipairs(Allos.PointLights) do PointLight:CalcLocalPosition(WorldMatrix) end
    for _, SpotLight in ipairs(Allos.SpotLights) do SpotLight:CalcLocalPositionAndDirection(WorldMatrix) end
end

function Allos.SendLights()
    local BaseLightCount = 0
    local DirLightCount = 0
    local PointLightCount = 0
    local SpotLightCount = 0

    for i, BaseLight in ipairs(Allos.BaseLights) do
        local Struct = "BaseLights[" .. (i - 1) .. "]."
        ProjectionShader:send(Struct .. "Color", BaseLight.Color)
        ProjectionShader:send(Struct .. "AmbientIntensity", BaseLight.AmbientIntensity)
        ProjectionShader:send(Struct .. "DiffuseIntensity", BaseLight.DiffuseIntensity)
        BaseLightCount = BaseLightCount + 1
    end
    for i, DirLight in ipairs(Allos.DirLights) do
        local Struct = "DirLights[" .. (i - 1) .. "]."
        local Base = Struct .. "Base."
        ProjectionShader:send(Base .. "Color", DirLight.Color)
        ProjectionShader:send(Base .. "AmbientIntensity", DirLight.AmbientIntensity)
        ProjectionShader:send(Base .. "DiffuseIntensity", DirLight.DiffuseIntensity)

        ProjectionShader:send(Struct .. "Direction", DirLight.LocalDirection:ToArray())

        DirLightCount = DirLightCount + 1
    end
    for i, PointLight in ipairs(Allos.PointLights) do
        local Struct = "PointLights[" .. (i - 1) .. "]."
        local Base = Struct .. "Base."
        local Atten = Struct .. "Atten."
        ProjectionShader:send(Base .. "Color", PointLight.Color)
        ProjectionShader:send(Base .. "AmbientIntensity", PointLight.AmbientIntensity)
        ProjectionShader:send(Base .. "DiffuseIntensity", PointLight.DiffuseIntensity)

        ProjectionShader:send(Struct .. "Position", PointLight.LocalPosition:ToArray())

        ProjectionShader:send(Atten .. "Constant", PointLight.Constant)
        ProjectionShader:send(Atten .. "Linear", PointLight.Linear)
        ProjectionShader:send(Atten .. "Quadratic", PointLight.Quadratic)

        PointLightCount = PointLightCount + 1
    end
    for i, SpotLight in ipairs(Allos.SpotLights) do
        local Struct = "SpotLights[" .. (i - 1) .. "]."
        local PBase = Struct .. "PointBase."
        local Base = PBase .. "Base."
        local Atten = PBase .. "Atten."

        ProjectionShader:send(Base .. "Color", SpotLight.Color)
        ProjectionShader:send(Base .. "AmbientIntensity", SpotLight.AmbientIntensity)
        ProjectionShader:send(Base .. "DiffuseIntensity", SpotLight.DiffuseIntensity)

        ProjectionShader:send(Struct .. "Direction", SpotLight.LocalDirection:ToArray())
        ProjectionShader:send(PBase .. "Position", SpotLight.LocalPosition:ToArray())
        ProjectionShader:send(Struct .. "Cutoff", cos(SpotLight.Cutoff))

        ProjectionShader:send(Atten .. "Constant", SpotLight.Constant)
        ProjectionShader:send(Atten .. "Linear", SpotLight.Linear)
        ProjectionShader:send(Atten .. "Quadratic", SpotLight.Quadratic)

        SpotLightCount = SpotLightCount + 1
    end

    ProjectionShader:send("TotalBaseLights", BaseLightCount)
    ProjectionShader:send("TotalDirLights", DirLightCount)
    ProjectionShader:send("TotalPointLights", PointLightCount)
    ProjectionShader:send("TotalSpotLights", SpotLightCount)
end

function Allos.CalculateScene(Iter, Camera, UseDepth)
    local ViewMatrix = Camera:View() --// Also works with spotlights
    local ObjCount, TriCount = 0, 0
    local ScaleX = UseDepth and 100 or 100
    local ScaleY = UseDepth and 100 or 100

    for _, Object in pairs(Iter or Allos.Workspace) do
        local WorldMatrix = mlib.WorldMatrix(Object)

        ProjectionShader:send("CameraLocalPos", mlib.WorldToLocal(WorldMatrix, Camera.pos or Camera.LocalPosition):ToArray())
        local WVP = ProjectionMatrix * (ViewMatrix * WorldMatrix)
        if UseDepth == false then Allos.LightWVP = WVP end
        ProjectionShader:send("WVP", WVP)

        Allos.UpdateLights(WorldMatrix)

        if UseDepth then
            ProjectionShader:send("shaded", Object.shaded)
            --ProjectionShader:send("LightWVP", Allos.LightWVP)
            Allos.SendMaterial(Object.material)
            Allos.SendLights()
        end

        for _, Triangle in ipairs(Object.triangles) do
            LG.draw(Triangle, HALF_WIDTH, HALF_HEIGHT, 0, ScaleX, ScaleY)
            TriCount = TriCount + 1
        end

        ObjCount = ObjCount + 1
    end

    Allos.ObjectCount, Allos.TriangleCount = ObjCount, TriCount
end

function Allos.Render(Iter, Canvas, Stencil, Depth)
    LG.setCanvas({Canvas, depthstencil=(Stencil or DepthCanvas), depth=true})
    LG.clear()
    LG.setDepthMode("lequal", true)
    LG.setShader(ProjectionShader)

    local UseDepth = (Depth ~= nil)
    ProjectionShader:send("UseDepthMap", UseDepth)
    ProjectionShader:send("RimLightEnabled", false)
    ProjectionShader:send("RimLightPower", 3)

    if UseDepth then ProjectionShader:send("DepthMap", Depth)  end
    Allos.CalculateScene(Iter, UseDepth and Allos.MainCamera or Allos.MainLight, UseDepth)

    LG.setCanvas()
    LG.setShader()
end

return Allos