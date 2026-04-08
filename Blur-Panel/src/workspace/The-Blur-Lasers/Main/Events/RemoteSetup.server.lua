--[[
    RemoteSetup.lua (Script - Server)
    Initializes remote events on server side

    Place this as a Script inside: Main/Events/RemoteSetup
]]

local remoteEventsModule = script.Parent:FindFirstChild("RemoteEvents")

if remoteEventsModule and remoteEventsModule:IsA("ModuleScript") then
    local RemoteEvents = require(remoteEventsModule)
    RemoteEvents.setup()
else
    warn("[The-Blur Server] RemoteEvents module not found!")
end
