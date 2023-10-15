--[[

local Render = {}

--// Requires
local mlib = require("mlib")

--// Read-Only Settings
local MeshAttributes = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoord", "float", 2},
    {"VertexNormal", "float", 3},
    {"VertexColor", "float", 4},
}
local ShadowMeshAttributes = {
    {"VertexPosition", "float", 3},
    {"VertexNormal", "float", 3},
}

--// Get Shader Files
local VertexShader = love.filesystem.read("VertexShader.vert")
local FragmentShader = love.filesystem.read("FragmentShader.frag")

local ShadowVertexShader = love.filesystem.read("ShadowVertexShader.vert")
local ShadowFragmentShader = love.filesystem.read("ShadowFragmentShader")

--// Löve
local LG = love.graphics
local LI = love.image
local LK = love.keyboard
local LW = love.window

--// Other optimisations
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
local random = math.random
local num = tonumber

local Y1Vector3 = mlib.Vector3(0, 1, 0)

--// Shaders
local MainShader = LG.newShader(VertexShader, FragmentShader)
local ShadowShader = LG.newShader(ShadowVertexShader, ShadowFragmentShader)

--// Globals
local CHARACTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local NUMBERS = "1234567890"
local SYMBOLS = "!@#$%^&*()'=-+_/.,<>"
local KEYS = CHARACTERS .. NUMBERS .. SYMBOLS

--// Variables
local Canvas = nil
local DepthCanvas = nil

local LightWorkspace = {}

--// Engine Variables
Render.Workspace = {}
Render.MainCamera = nil
Render.ProjectionMatrix = nil

--// Config Settings
Render.ScreenWidth = 1920
Render.ScreenHeight = 1080
Render.FullScreen = true
Render.Resizable = false
Render.DepthType = "depth32f"

Render.zNear = 1
Render.zFar = 1000
Render.FOV = 30

Render.Spawn = mlib.Vector3(0, 0, 0)

Render.EscapeKey = "escape"
Render.RestartKey = "r"

Render.ObjectPath = "Objects"
Render.TexturePath = "Textures"

Render.AlwaysPanning = false
Render.MousePanButton = 2
Render.MouseSensivity = 0.7
Render.CameraPitch = 0
Render.CameraYaw = 0
Render.CameraRoll = 0
Render.TurnSpeed = -0.5
Render.CameraAccelerate = 1
Render.CameraSlowdown = 1

Render.CalcNormals = false

--// Utility
function Render.SplitString(x, Seperator)
	--if Seperator == nil then Seperator = "%s" end
	local t = {}
	local i = 1
	for str in string.gmatch(x, "([^".. Seperator .."]+)") do t[i] = str; i = i + 1 end
	return t
end; local SplitString = Render.SplitString

function Render.ArrayToString(Array)
    local Result = ""

    local i = 0
    for k, v in pairs(Array) do
        i = i + 1
        if type(v) == "table" then v = Render.ArrayToString(v) end
        if type(v) ~= "userdata" then Result = Result .. "\n[" .. k .. "]: " .. v end
        if i ~= #Array then Result = Result .. ", " end
    end

    if Result == "" and i == 0 then Result = "nil" end
    return Result
end; local ArrayToString = Render.ArrayToString

function Render.RandomColor()
    local R = random(0, 100) / 100
    local G = random(0, 100) / 100
    local B = random(0, 100) / 100
    return R, G, B, 1
end; local RandomColor = Render.RandomColor

function Render.Lock(x, MinValue, MaxValue)
    return max(min(x, MaxValue), MinValue)
end; local lock = Render.Lock

--// Engine Classes
local BaseLight = {Type = "BaseLight"}
BaseLight.__index = BaseLight

function Render.BaseLight()
    local self = setmetatable({
        Color = {1, 1, 1};
        AmbientIntensity = 1;
        DiffuseIntensity = 1;
    }, BaseLight)
    return self
end

local LightAttenuation = {Type = "LightAttenuation"}

function Render.LightAttenuation()
    local self = setmetatable({
        Constant = 1;
        Linear = 0;
        Exp = 0;
    }, LightAttenuation)
    return self
end

local DirectionalLight = setmetatable({Type = "DirectionalLight"}, BaseLight)
DirectionalLight.__index = DirectionalLight

function Render.DirectionalLight()
    local self = setmetatable({
        Color = {1, 1, 1};
        AmbientIntensity = 1;
        DiffuseIntensity = 1;
        WorldDirection = mlib.Vector3(0, 0, 0);
        LocalDirection = mlib.Vector3(0, 0, 0);

    }, DirectionalLight)
    LightWorkspace[#LightWorkspace+1] = self
    return self
end

function DirectionalLight:Calc(WM)
     --// Get rid of translation in matrix, because not required
    local World3 = mlib.Convert(WM, "Matrix3")
    self.LocalDirection = (World3 * self.WorldDirection):Normalise()
end

local PointLight = setmetatable({Type = "PointLight"}, BaseLight)
PointLight.__index = PointLight

function Render.PointLight()
    local self = setmetatable({
        Attenuation = Render.LightAttenuation();
        WorldPosition = mlib.Vector3(0, 0, 0);
        LocalPosition = mlib.Vector3(0, 0, 0);
        AmbientIntensity = 1;
        DiffuseIntensity = 1;
        Color = {1, 1, 1};
    }, PointLight)
    LightWorkspace[#LightWorkspace+1] = self
    return self
end

function PointLight:Calc(WM)
    --// Get rid of translation in matrix, because not required
    self.LocalPosition = mlib.WorldToLocal(WM, self.WorldPosition)
end

local SpotLight = setmetatable({Type = "SpotLight"}, PointLight)
SpotLight.__index = SpotLight

function Render.SpotLight()
    local self = setmetatable({
        Attenuation = Render.LightAttenuation();
        WorldPosition = mlib.Vector3(0, 0, 0);
        LocalPosition = mlib.Vector3(0, 0, 0);
        AmbientIntensity = 1;
        DiffuseIntensity = 1;
        Color = {1, 1, 1};

        WorldDirection = mlib.Vector3(0, 0, 0);
        LocalDirection = mlib.Vector3(0, 0, 0);
        Cutoff = 0;
    }, SpotLight)
    LightWorkspace[#LightWorkspace+1] = self
    return self
end

function SpotLight:CalcLocalDirectionAndPosition(WM)
    self.LocalPosition = mlib.WorldToLocal(WM, self.WorldPosition)

    local World3 = mlib.Convert(WM, "Matrix3")
    self.LocalDirection = (World3 * self.WorldDirection):Normalise()
    --self.LocalDirection = mlib.WorldDirToLocalDir(self.WorldDirection)
end

function SpotLight:RotationTransform()
    local Pos, Target, Up = self.LocalPosition, self.LocalDirection, Y1Vector3
    local CameraTranslation = mlib.TranslationMatrix4(-Pos.x, -Pos.y, -Pos.z)
    local CameraRotateTrans = mlib.CameraTransform(Target, Up)
    return CameraRotateTrans * CameraTranslation
end

local Mesh = {}
Mesh.__index = Mesh

local function GetObjectByID(ID)
    for Alias, Object in pairs(Render.Workspace) do if Object.ID == ID then return Object end end
end

function Mesh:SetAlias(Alias)
    if Render.Workspace[Alias] ~= nil then
        local NewID = Alias
        local Found = false

        while true do
            for i = 1, #KEYS, 1 do --// Go through every character and check if it works
                local Attempt = NewID .. KEYS:sub(i, i)

                if not GetObjectByID(Attempt) then
                    NewID = Attempt
                    Found = true
                    break
                end
            end

            if Found == true then break end
            NewID = NewID .. "_" --// We can add any symbol technically
        end

        self.ID = NewID
    else
        self.ID = Alias
    end
end

function Mesh:InsertWorkspace(Alias)
    self:SetAlias(Alias)
    Render.Workspace[self.ID] = self
end

function Mesh:SetPosition(X, Y, Z) self.Position.x = X; self.Position.y = Y; self.Position.z = Z end
function Mesh:SetRotation(X, Y, Z) self.Rotation.x = X; self.Rotation.y = Y; self.Rotation.z = Z end
function Mesh:SetSize(X, Y, Z) self.Size.x = X; self.Size.y = Y; self.Size.z = Z end

function Mesh:Rotate(AngleX, AngleY, AngleZ)
    self.Rotation.x = self.Rotation.x + (AngleX or 0)
    self.Rotation.y = self.Rotation.y + (AngleY or 0)
    self.Rotation.z = self.Rotation.z + (AngleZ or 0)
end

local Material = {}
Material.__index = Material

function Render.Material()
    local self = setmetatable({
        AmbientColor = {1, 1, 1};
        DiffuseColor = {1, 1, 1};
        SpecularColor = {0, 0, 0};
        SpecularExponent = 0;
        Opaque = 1;
        Texture = nil;
    }, Material)
    return self
end

Render.ObjectMaterials = {
    ["Material"] = Render.Material()
}

function Render.FormatImageName(Name, Directory)
    local Result = Directory .. "/" .. Name
    local x = string.gsub(Result, "_diff", "") --// Append the TexturePath
    --\\ Roblox appends _diff to all of their textures when exporting for some reason, so we get rid of it
    --// There is no easy way to get a file without extension in love2d, so defualt is png
    Result = Result .. ".png"
    return Result
end

function Render.GetImage(Path)
    local Result = Path:gsub("_diff", "") --Path .. "_diff"
    Result = Result:gsub(".png", "")
    Result = Result .. ".png"

    local Image = nil
    local Success, ErrorMessage = pcall(function()
        Image = LG.newImage(Result)
    end)
    if Success then return Image end
    return nil, ErrorMessage
end

function Render.ReadMaterial(Directory, FileName)
    --// This function will go through all the data in the .mtl file
    --// it will create new materials and insert all of them inside an ObjectMaterials array
    --// from there the MeshLoadObjectFile can use these materials with "usemtl"
    local FileContent = love.filesystem.read(Directory .. FileName)
    if not FileContent then return 0, "File not found or cant't read file!" end

    local NewMaterial = nil
    local MaterialName = ""

    local Lines = SplitString(FileContent, "\n")
    for _, Line in ipairs(Lines) do
        local Tokens = SplitString(Line, " ")
        local Prefix = Tokens[1]

        if Prefix == "newmtl" then
            --// Put Material inside ObjectMaterials array
            MaterialName = Tokens[2]
            --if NewMaterial ~= nil then assert(Render.ObjectMaterials[MaterialName] ~= nil, "Material with name already exists!") end
            NewMaterial = Render.Material()
            Render.ObjectMaterials[MaterialName] = NewMaterial
        elseif Prefix == "Ns" then --// Specular Exponent
            NewMaterial.SpecularExponent = Tokens[2]
        elseif Prefix == "Ka" then --// AmbientColor
            NewMaterial.AmbientColor[1] = Tokens[2]
            NewMaterial.AmbientColor[2] = Tokens[3]
            NewMaterial.AmbientColor[3] = Tokens[4]
        elseif Prefix == "Kd" then --// Diffuse
            NewMaterial.DiffuseColor[1] = Tokens[2]
            NewMaterial.DiffuseColor[2] = Tokens[3]
            NewMaterial.DiffuseColor[3] = Tokens[4]
        elseif Prefix == "Ks" then --// Specular
            NewMaterial.SpecularColor[1] = Tokens[2]
            NewMaterial.SpecularColor[2] = Tokens[3]
            NewMaterial.SpecularColor[3] = Tokens[4]
        elseif Prefix == "Ke" then
        elseif Prefix == "Ni" then --// Optical Density
        elseif Prefix == "d" then --// Opaque
            NewMaterial.Opaque = Tokens[2]
        elseif Prefix == "illum" then
        elseif Prefix == "map_Bump" then
        elseif Prefix == "map_Ka" then --// Main Texture
            NewMaterial.Texture = Render.GetImage(Directory .. "/Textures/" .. Tokens[2])
        elseif Prefix == "map_Kd" then --// Diffuse Texture
        elseif Prefix == "map_Ks" then --// Specular Texture
        elseif Prefix == "map_Ns" then
        elseif Prefix == "refl" then
        elseif Prefix == "Material" then --// Material Color
        end
    end
end

function Render.LoadObject(ObjectName)
     --// We get the folder that the .obj is located in, inside the Objects folder
    --// Then we get the .obj file inside of that folder, Quite complicated lol
    local Directory = Render.ObjectPath .. "/" .. ObjectName .. "/"
    local ObjectFile = Directory .. ObjectName .. ".obj"
    local FileContent = love.filesystem.read(ObjectFile)
    if FileContent == nil then return end
    --assert(FileContent == nil, "File not found or can't read file!")

    --// Create caches
    local Vertices = {}
    local Normals = {}
    local Textures = {}

    local ObjectMesh = Render.Mesh(ObjectName)
    local Meshes = {}

    --// If FixedTexture isn't included, this will result in being nil
    local MaterialName = ""

    local Lines = SplitString(FileContent, "\n")
    for _, Line in ipairs(Lines) do
        local NewMesh = nil

        local Tokens = SplitString(Line, " ")
        local Prefix = Tokens[1]

        if Prefix == "v" then --// Create Vertex
            Vertices[#Vertices+1] = mlib.Vector3(num(Tokens[2]), num(Tokens[3]), num(Tokens[4]))
        elseif Prefix == "f" then --// Create face of vertices
            local Segments1 = SplitString(Tokens[2], "/")
            local Segments2 = SplitString(Tokens[3], "/")
            local Segments3 = SplitString(Tokens[4], "/")

            ObjectMesh.Triangles[#ObjectMesh.Triangles+1] = {
                --// Vertex Data
                Vertices[num(Segments1[1])];
                Vertices[num(Segments2[1])];
                Vertices[num(Segments3[1])];
                --// Texture Data
                Textures[num(Segments1[2])] or mlib.Vector2();
                Textures[num(Segments2[2])] or mlib.Vector2();
                Textures[num(Segments3[2])] or mlib.Vector2();
                --TextureData;
                --// Normal Data
                Normals[num(Segments1[3])] or mlib.Vector3();
                Normals[num(Segments2[3])] or mlib.Vector3();
                Normals[num(Segments3[3])] or mlib.Vector3();
                mlib.Vector3(); mlib.Vector3(); mlib.Vector3()
            }

        elseif Prefix == "vn" then --// Create Normal
            Normals[#Normals+1] = mlib.Vector3(num(Tokens[2]), num(Tokens[3]), num(Tokens[4]))
        elseif Prefix == "vt" then --// Create UV coordinates
            Textures[#Textures+1] = mlib.Vector2(num(Tokens[2]), num(Tokens[3]))
        elseif Prefix == "g" then --// Creates new object group for upcoming faces
            --// If object is empty, don't create a new one just yet
            if #Vertices ~= 0 then NewMesh = Tokens[2] end
            ObjectMesh:SetAlias(Tokens[2]) --// Name the object accordingly
            --\\ We handle objects like groups in this case
        elseif Prefix == "mtllib" then --// Open mtl file and load materials
            Render.ReadMaterial(Directory, Tokens[2])
        elseif Prefix == "usemtl" then --// Set Material of upcoming triangles
            --// Set the material of the object
            MaterialName = Tokens[2]
            ObjectMesh.ObjectMaterial = Render.ObjectMaterials[MaterialName]
        elseif Prefix == "o" then --// New Object
        elseif Prefix == "s" then --// Smoothshading
        end

        if NewMesh ~= nil then
            --// If NewMesh isn't nil then create a new mesh
            --// Note: Caches don't have to be reset, index just goes up even though new object is formed
            Meshes[#Meshes+1] = ObjectMesh
            ObjectMesh = Render.Mesh(NewMesh)
            ObjectMesh.ObjectMaterial = Render.ObjectMaterials[MaterialName] --// !: may break
            Triangles = ObjectMesh.Triangles
        end
    end

    --// Add Final Mesh
    Meshes[#Meshes+1] = ObjectMesh

    return Meshes
end

function Render.Mesh(Alias, PX, PY, PZ, RX, RY, RZ, SX, SY, SZ)
    local self = setmetatable({
        ID = 0; --// Reference of object in Workspace
        Triangles = {};

        Position = mlib.Vector4(PX, PY, PZ);
        Rotation = mlib.Vector4(RX, RY, RZ);
        Size     = mlib.Vector4(SX or 1, SY or 1, SZ or 1);

        MeshFormats = {};
        ShadowFormats = {};
        ObjectMaterial = Render.Material();
    }, Mesh)
    self:InsertWorkspace(Alias)
    return self
end

--// Camera
local Camera = {}
Camera.__index = Camera

function Render.Camera(X, Y, Z)
    local self = setmetatable({
        pos = mlib.Vector3(X, Y, Z),
        target = mlib.Vector3(0, 0, 1),
        up = mlib.Vector3(0, 1, 0),
        speed = 5
    }, Camera)
    return self
end

function Camera:SetPosition(X, Y, Z)
    self.pos.x = X
    self.pos.y = Y
    self.pos.z = Z
    return self
end

function Camera:RotationTransform()
    local Pos, Target, Up = self.pos, self.target, self.up
    local CameraTranslation = mlib.TranslationMatrix4(-Pos.x, -Pos.y, -Pos.z)
    local CameraRotateTrans = mlib.CameraTransform(Target, Up)
    return CameraRotateTrans * CameraTranslation
end

--// More Advanced Functions

--// Setters and Init
function Render.SetProjectionMatrix()
    Render.ProjectionMatrix = mlib.ProjectionMatrix(Render.zNear, Render.zFar, Render.FOV)
    Render.ShadowProjectionMatrix = mlib.ProjectionMatrix(Render.zNear, Render.zFar, Render.FOV)
end

function Render.Init(ScreenWidth, ScreenHeight)
    Render.ScreenWidth = ScreenWidth or 1920
    Render.ScreenHeight = ScreenHeight or 1080

    LW.setMode(ScreenWidth, ScreenHeight, {fullscreen=Render.FullScreen,resizable=Render.FullScreen})
    Canvas = LG.newCanvas()
    DepthCanvas = LG.newCanvas(ScreenWidth, ScreenHeight, {type="2d",format="depth32f",readable=true})
    ShadowMap = LG.newCanvas(ScreenWidth, ScreenHeight, {type="2d",format="depth32f",readable=true})
    LG.setMeshCullMode("back")

    Render.MainCamera = Render.Camera(Render.Spawn.x, Render.Spawn.y, Render.Spawn.z)

    --// Create Sun and Skybox
end

function Render.SetResolution(ScreenWidth, ScreenHeight)
    Render.ScreenWidth = ScreenWidth or 1920
    Render.ScreenHeight = ScreenHeight or 1080
end

--// Controls
local Panning = false

function Render.MousePressed(X, Y, Button) --// If mouse is down (not released yet)
    if Button ~= Render.MousePanButton then return end
    Panning = true
    MouseX, MouseY = X, Y
    StartPanX, StartPanY = X, Y
    love.mouse.setGrabbed(true)
end

function Render.MouseReleased(X, Y, Button)
    if Button ~= Render.MousePanButton then return end
    Panning = false
    love.mouse.setGrabbed(false)
end

function Render.UpdateMousePan(dt)
    if Render.AlwaysPanning or Panning then
        --love.mouse.setVisible(false)
        NewMouseX, NewMouseY = love.mouse.getX(), love.mouse.getY()
        local DifferenceX, DifferenceY
        DifferenceX = NewMouseX - MouseX
        DifferenceY = NewMouseY - MouseY

        Render.CameraYaw = Render.CameraYaw - DifferenceX * dt * Render.MouseSensivity
        Render.CameraPitch = lock(Render.CameraPitch - DifferenceY * dt * Render.MouseSensivity, -1.5, 1.5)

        --// Reset Mouse Position
        --local OriginX, OriginY = Allos.VisualWidth / 2, Allos.VisualHeight / 2
        love.mouse.setPosition(Render.ScreenWidth / 2, Render.ScreenHeight / 2)
    end
    MouseX, MouseY = Render.ScreenWidth / 2, Render.ScreenHeight / 2
end

function Render.UpdateControls(dt)
    local PlayerCamera = Render.MainCamera
    local Target, Up, Speed = PlayerCamera.target, PlayerCamera.up, PlayerCamera.speed * dt
    if LK.isDown('w') then PlayerCamera.pos = PlayerCamera.pos + (Target * Speed) end
    if LK.isDown('s') then PlayerCamera.pos = PlayerCamera.pos - (Target * Speed) end
    if LK.isDown("space") then PlayerCamera.pos = PlayerCamera.pos + Up * Speed end
    if LK.isDown("lshift") or LK.isDown("rshift") then PlayerCamera.pos = PlayerCamera.pos - Up * Speed end
    if LK.isDown('a') then
        local Left = Up:Cross(Target) --// Flipped (Target, Up)
        Left:Normalise()
        PlayerCamera.pos = PlayerCamera.pos + Left * Speed
    end
    if LK.isDown('d') then
        local Right = Target:Cross(Up) --// Flipped (Up, Target)
        Right:Normalise()
        PlayerCamera.pos = PlayerCamera.pos + Right * Speed
    end

    if LK.isDown("q") then PlayerCamera.speed = PlayerCamera.speed + Render.CameraAccelerate end
    if LK.isDown("e") then PlayerCamera.speed = PlayerCamera.speed - Render.CameraSlowdown end

    if LK.isDown("up") then Render.CameraPitch = lock(Render.CameraPitch - Render.TurnSpeed * dt, -1.5, 1.5) end
    if LK.isDown("down") then Render.CameraPitch = lock(Render.CameraPitch + Render.TurnSpeed * dt, -1.5, 1.5) end
    if LK.isDown("right") then Render.CameraYaw = Render.CameraYaw + Render.TurnSpeed * dt end
    if LK.isDown("left") then Render.CameraYaw = Render.CameraYaw - Render.TurnSpeed * dt end

    if LK.isDown(Render.EscapeKey) then love.event.quit(1) end
    if LK.isDown(Render.RestartKey) then love.event.quit('restart') end

    local CameraRotationX = mlib.XRotationMatrix4(Render.CameraPitch)
    local CameraRotationY = mlib.YRotationMatrix4(Render.CameraYaw)
    local CameraRotationZ = mlib.ZRotationMatrix4(Render.CameraRoll)

    --// We transform our target direction normal by a rotation matrix so it's pointing in the correct direction
    --// We can later add on to this with another rotation matrix to rotate up and down
    local LookDirection = CameraRotationZ * (CameraRotationY * (CameraRotationX * mlib.Vector4(0, 0, 1, 1)))
    --\\ We want yaw to go after pitch

    PlayerCamera.target.x = LookDirection.x
    PlayerCamera.target.y = LookDirection.y
    PlayerCamera.target.z = LookDirection.z
end

--// Draw
function Render.SendDefaultLightData()
    local dir, point, spot = 0, 0, 0
    for _, Light in ipairs(LightWorkspace) do
        if Light.Type == "DirectionalLight" then
            local T = "DirLights[" .. dir .. "]."
            local B = T .. "Base."
            MainShader:send(B .. "AmbientIntensity", Light.AmbientIntensity)
            MainShader:send(B .. "DiffuseIntensity", Light.DiffuseIntensity)
            MainShader:send(B .. "Color", Light.Color)
            dir = dir + 1
        elseif Light.Type == "PointLight" then
            local T = "PointLights[" .. point .. "]."
            local B = T .. "Base."
            MainShader:send(B .. "AmbientIntensity", Light.AmbientIntensity)
            MainShader:send(B .. "DiffuseIntensity", Light.DiffuseIntensity)
            MainShader:send(B .. "Color", Light.Color)

            local A = T .. "Atten."
            MainShader:send(A .. "Constant", Light.Attenuation.Constant)
            MainShader:send(A .. "Linear", Light.Attenuation.Linear)
            MainShader:send(A .. "Exp", Light.Attenuation.Exp)

            point = point + 1
        elseif Light.Type == "SpotLight" then
            local T = "SpotLights[" .. spot .. "]."

            MainShader:send(T .. "Cutoff", cos(Light.Cutoff))

            local B2 = T .. "Base.Base."
            MainShader:send(B2 .. "AmbientIntensity", Light.AmbientIntensity)
            MainShader:send(B2 .. "DiffuseIntensity", Light.DiffuseIntensity)
            MainShader:send(B2 .. "Color", Light.Color)

            local A = T .. "Base." .. "Atten."
            MainShader:send(A .. "Constant", Light.Attenuation.Constant)
            MainShader:send(A .. "Linear", Light.Attenuation.Linear)
            MainShader:send(A .. "Exp", Light.Attenuation.Exp)
            spot = spot + 1
        end
    end
end

function Render.SendLightTransformedData(WM)
    --// Go through all lights and send data
    local dir = 0
    local point = 0
    local spot = 0

    for _, Light in ipairs(LightWorkspace) do
        if Light.Type == "DirectionalLight" then
            Light:Calc(WM)
            local T = "DirLights[" .. dir .. "]."
            MainShader:send(T .. "Direction", Light.LocalDirection:ToArray())
            dir = dir + 1
        elseif Light.Type == "PointLight" then
            Light:Calc(WM)
            local T = "PointLights[" .. point .. "]."
            MainShader:send(T .. "LocalPos", Light.LocalPosition:ToArray())
            point = point + 1
        elseif Light.Type == "SpotLight" then
            Light:CalcLocalDirectionAndPosition(WM)
            local T = "SpotLights[" .. spot .. "]."
            MainShader:send(T .. "Direction", Light.LocalDirection:ToArray())
            MainShader:send(T .. "Base." .. "LocalPos", Light.LocalPosition:ToArray())
            spot = spot + 1
        end
    end

    MainShader:send("TotalPointLights", point)
    MainShader:send("TotalSpotLights", spot)
end

function Render.CalculateNormals(Triangles)
    local Normals = {}
    for _, Triangle in ipairs(Triangles) do
        --// Get the vertices of the triangle
        local v1, v2, v3 = Triangle[1], Triangle[2], Triangle[3]

        --// Calculate the normal of the triangle
        local normal = (v2 - v1):Cross(v3 - v1)
        normal = normal:Normalise()

        --// Add the normal to the vertex normals table for each vertex
        if Normals[v1] then Normals[v1] = Normals[v1] + normal else Normals[v1] = normal end
        if Normals[v2] then Normals[v2] = Normals[v2] + normal else Normals[v2] = normal end
        if Normals[v3] then Normals[v3] = Normals[v3] + normal else Normals[v3] = normal end
    end

    --// Normalize the vertex normals
    for _, normal in pairs(Normals) do normal:Normalise() end
    return Normals
end

function Render.RenderCanvas(DepthStencil, Light, IsShadowMap)
    LG.setCanvas({Canvas, depthstencil=(DepthStencil or DepthCanvas), depth=true})
    LG.clear()
    LG.setDepthMode("lequal", true)
    LG.setShader(IsShadowMap and ShadowShader or MainShader)

    local MainCamera = Render.MainCamera

    --[[
    local RotationTransform = nil
    local ProjectionMatrix = nil

    if not ShadowMap then RotationTransform = MainCamera:RotationTransform()
    else RotationTransform = Light:RotationTransform() end
    if not ShadowMap then ProjectionMatrix = Render.ProjectionMatrix
    else ProjectionMatrix = Render.ShadowProjectionMatrix end
    ]]

    --[[

    local View = MainCamera:RotationTransform()
    local LightView = Light:RotationTransform()
    local ProjectionMatrix = Render.ProjectionMatrix
    local ShadowProjectionMatrix = Render.ShadowProjectionMatrix

    local HalfWidth, HalfHeight = Render.ScreenWidth / 2, Render.ScreenHeight / 2

    if not IsShadowMap then Render.SendDefaultLightData() end

    for ID, Object in pairs(Render.Workspace) do
        local WM = mlib.WorldMatrix(Object)

        local WVP = ProjectionMatrix * (View * WM)
        local LightWVP = ShadowProjectionMatrix * (LightView * WM)

        if not IsShadowMap then
            MainShader:send("WVP", WVP)
            MainShader:send("LightWVP", LightWVP)
            MainShader:send("ShadowMap", ShadowMap)

            Render.SendLightTransformedData(WM)

            --// Camera local pos
            MainShader:send("CameraPos", mlib.WorldToLocal(WM, MainCamera.pos):ToArray(1))

            --// Material Data
            local ObjectMaterial = Object.ObjectMaterial
            if ObjectMaterial == nil then ObjectMaterial = Render.Material() end
            MainShader:send("MaterialDiffuseColor",  mlib.Color3ToArray4(ObjectMaterial.DiffuseColor))
            MainShader:send("MaterialAmbientColor", mlib.Color3ToArray4(ObjectMaterial.AmbientColor))
            MainShader:send("MaterialSpecularColor", mlib.Color3ToArray4(ObjectMaterial.SpecularColor))
            MainShader:send("MaterialSpecularExponent", ObjectMaterial.SpecularExponent)
            MainShader:send("MaterialOpaque", ObjectMaterial.Opaque)
        else
            ShadowShader:send("WVP", LightWVP)
        end

        --// Convert triangle data into mesh data for all triangles if not done yet.
        if #Object.MeshFormats == 0 and #Object.Triangles > 0 then
            local Normals = nil
            if Render.CalcNormals then Normals = Render.CalculateNormals(Object.Triangles) end

            for i, Triangle in ipairs(Object.Triangles) do
                local Normal1, Normal2, Normal3 = nil, nil, nil
                if Render.CalcNormals then
                    Normal1, Normal2, Normal3 = Normals[Triangle[1]]--, Normals[Triangle[2]], Normals[Triangle[3]]
                    --[[
                else
                    Normal1, Normal2, Normal3 = Triangle[7], Triangle[8], Triangle[9]
                end

                --// Shadow
                local ShadowMeshTriangle = LG.newMesh(ShadowMeshAttributes, {
                    {Triangle[1].x, Triangle[1].y, Triangle[1].z, Normal1:Unpack()},
                    {Triangle[2].x, Triangle[2].y, Triangle[2].z, Normal2:Unpack()},
                    {Triangle[3].x, Triangle[3].y, Triangle[3].z, Normal3:Unpack()}
                }, "triangles", "static")
                Object.ShadowFormats[i] = ShadowMeshTriangle

                --// Normal Version
                local MeshTriangle = LG.newMesh(MeshAttributes, {
                    {
                        Triangle[1].x, Triangle[1].y, Triangle[1].z,
                        Triangle[4].x, 1-Triangle[4].y,
                        Normal1:Unpack(),
                        1, 1, 1, 1
                    },
                    {
                        Triangle[2].x, Triangle[2].y, Triangle[2].z,
                        Triangle[5].x, 1-Triangle[5].y,
                        Normal2:Unpack(),
                        1, 1, 1, 1
                    },
                    {
                        Triangle[3].x, Triangle[3].y, Triangle[3].z,
                        Triangle[6].x, 1-Triangle[6].y,
                        Normal3:Unpack(),
                        1, 1, 1, 1
                    },
                }, "triangles", "static")
                MeshTriangle:setTexture(Object.ObjectMaterial.Texture)
                Object.MeshFormats[i] = MeshTriangle
            end
        end

        if IsShadowMap then
            for _, Triangle in ipairs(Object.ShadowFormats) do
                LG.draw(Triangle, HalfWidth, HalfHeight, 0, 100, 100)
            end
        else
            for _, Triangle in ipairs(Object.MeshFormats) do
                LG.draw(Triangle, HalfWidth, HalfHeight, 0, 100, 100)
            end
        end
    end

    LG.setShader()
    LG.setCanvas()
end

function Render.RenderScene()
    --// Shadow Render
    Render.RenderCanvas(ShadowMap, LightWorkspace[1], true)
    --// Main Render
    Render.RenderCanvas(nil, LightWorkspace[1], false)
end

function Render.OutputRender()
    LG.setColor(1,1,1)
    LG.setDepthMode()
    LG.draw(Canvas, 0,0,0, 1,1)
    LG.print(ArrayToString(Render.MainCamera.pos))

    LG.setColor(1,1,1)
    LG.draw(ShadowMap, 0,0,0, 0.2,0.2)
end

return Render]]