local Allos = require("Allos")
local mlib = require("mlib")
--local map = require("map")

local FollowCamera = true

local LG = love.graphics
local LK = love.keyboard

--// opt
local floor = math.floor
local round = function(x) return floor(x + 0.5) end

function love.load()
    Allos.Init(1920, 1080, 30, 0.1, 1000)
    Objects = Allos.LoadObjectFile("RobloxWorld2", true)

    Allos.Sun.AmbientIntensity = 1
    Allos.Sun.DiffuseIntensity = 1
    Allos.Sun.WorldDirection:Set(mlib.Vector3(1, -1, 0))
end

function love.keypressed(key) end
function love.mousepressed(x, y, button) Allos.MousePressed(x, y, button) end
function love.mousereleased(x, y, button) Allos.MouseReleased(x, y, button) end

function love.update(dt)
    Allos.UpdateMousePan(dt)
    Allos.Controls(dt)
    Allos.Update(dt)
end

function love.draw()
    --local Render = map.StaticGetRenderList(Allos.MainCamera, 3)
    --Allos.WriteCanvas(Render)
    Allos.WriteCanvas(Objects)
    Allos.DrawCanvas()

    love.graphics.print("\n\t" .. Allos.MainCamera.pos:ToIntString() .. "\n\t" .. Allos.TriangleCount .. "\n\t" .. love.timer.getFPS())
end