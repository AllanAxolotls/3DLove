--[[

local Allos = require("Allos3D")

--[[
-- Triangle
local X, Y = 960, 540
local Buffer = {
    {-X, Y, 0, 1, 0, 0}, --// Bottom left
    {0, -Y, 0, 0, 1, 0}, --// Top
    {X,  Y, 0, 0, 0, 1}, --// Bottom Right
}

local IndexBuffer = {
    1, 2, 3,
}
 
-- Square
local X, Y = 100, 100
local Buffer = {
    {-X,  Y, 0},
    {-X, -Y, 0},
    { X, -Y, 0},
    { X,  Y, 0}
}--]]

--[[
local Triangle = Allos.Mesh("Interpolation")
local X, Y = 500, 500

Triangle.Triangles = {
    {
        {-X, Y, 0, 1, 0, 0}, --// Bottom left
        {0, -Y, 0, 0, 1, 0}, --// Top
        {X,  Y, 0, 0, 0, 1}, --// Bottom Right
    };
}
]]

--[[

function love.load()
    Cube = Allos.MeshLoadObjectFile("ArtisansRoblox")[1]
    Allos.SpawnPosition = {0, 0, 0}

    Allos.VisualWidth = 1920
    Allos.VisualHeight = 1080
    Allos.ComputeWidth, Allos.ComputeHeight = 1920, 1080
    Allos.FullScreen = true
    Allos.Resizable = false
    Allos.UpdateProjectionMatrix()
    Allos.Load()

    love.graphics.setBackgroundColor(0.5, 0.5, 0.9)

    Cube.Position[3] = 0
    Allos.PlayerCamera[4] = 30
end

function love.mousepressed(X, Y, Button) Allos.MousePressed(X, Y, Button) end
function love.mousereleased(X, Y, Button) Allos.MouseReleased(X, Y, Button) end

function love.update(dt)
    Allos.UpdateMousePan(dt)
    Allos.UpdateControls(dt)
    Allos.Update(dt)
    --Allos.MeshRotate(Cube, 1, 1)
end

function love.draw()
    Allos.DrawWorkspace()
    Allos.Draw()

    love.graphics.setColor(1, 0, 0)
    love.graphics.print("\t" .. tostring(love.timer.getFPS()))
    love.graphics.setColor(1, 1, 1)

    --love.graphics.print("\n" .. Allos.ArrayToString(Cube.Triangles[1][8]))

    --love.graphics.print("\n\t" ..
        --Allos.ArrayToString(Cube.Triangles[1]) .. " " .. Allos.ArrayToString(Cube.Triangles[2]) .. " " .. Allos.ArrayToString(Cube.Triangles[3])
        --Allos.ArrayToString(Cube)
    --)
end

]]