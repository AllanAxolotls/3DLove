--[[

local Render = require("Renderer")
local mlib = require("mlib")

function love.load()
    Map = Render.LoadObject("RobloxWorld2")[1]
    Render.FullScreen = true
    Render.Resizable = false

    Paused = false
    --Allos.UpdateProjectionMatrix()
    --Render.Spawn = mlib.Vector3(100, 5, 200)

    --[[
    Sun = Render.DirectionalLight()
    Sun.WorldDirection.y = -1
    Sun.WorldDirection.x = 1
    Sun.SpecularIntensity = 1
    Sun.AmbientIntensity = 0.1
    Sun.DiffuseIntensity = 0.5
    Sun.Color = {0.6, 0.6, 1}
    --]]

    --Cube1 = Render.LoadObject("Cube2")[1]

    --// Create Point Lights
    --[[
    Point1 = Render.PointLight()
    Point1.WorldPosition = mlib.Vector3(-90, 80, 190)
    Point1.AmbientIntensity = 0.1
    Point1.Color = {1, 1, 0}
    Point1.Attenuation.Exp = 0
    Point1.Attenuation.Linear = 0.1
    ]]

    --[[
    FlashLight = Render.SpotLight()
    FlashLight.Color = {1, 1, 0}
    FlashLight.AmbientIntensity = 1
    FlashLight.DiffuseIntensity = 2
    FlashLight.Attenuation.Linear = 0.05
    FlashLight.Attenuation.Exp = 0
    FlashLight.Cutoff = 20

    FlashLight.WorldDirection:Set(mlib.Vector3(0,0,1))
    --]]

    --[[
    StartPosition = mlib.Vector3(-400, 100, -50)

    Render.Init(1920, 1080)
    Render.SetProjectionMatrix()

    love.graphics.setBackgroundColor(0.5, 0.5, 0.9)

    Map.Position.z = 0
    Render.MainCamera.speed = 30

    TimePassed = 0
end

function love.keypressed(key)
    if key == "p" then Paused = not Paused end
end

function love.update(dt)
    Render.UpdateMousePan(dt)
    Render.UpdateControls(dt)

    TimePassed = TimePassed + 1 * dt

    -- [[
    if not Paused then
        FlashLight.WorldPosition:Set(Render.MainCamera.pos)
        FlashLight.WorldDirection:Set(Render.MainCamera.target)
    end
    --]]

    --FlashLight.WorldPosition:Set(StartPosition + mlib.Vector3(TimePassed * 40, 0, 0))
--[[end

function love.mousepressed(X, Y, Button) Render.MousePressed(X, Y, Button) end
function love.mousereleased(X, Y, Button) Render.MouseReleased(X, Y, Button) end

function love.draw()
    Render.RenderScene()
    Render.OutputRender()

    love.graphics.setColor(1, 0, 0)
    love.graphics.print("\t" .. tostring(love.timer.getFPS()))
    love.graphics.setColor(1, 1, 1)
end]]