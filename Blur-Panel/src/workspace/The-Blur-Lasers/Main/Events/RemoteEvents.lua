--[[
    RemoteEvents.lua (ModuleScript)
    Creates and manages all RemoteEvents for The-Blur system

    Place this inside: Main/Events/RemoteEvents (ModuleScript)
    Also add RemoteSetup Script in Main/Events/
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

-- Create shared folder
local blurRemotes = Instance.new("Folder")
blurRemotes.Name = "BlurRemotes"
blurRemotes.Parent = ReplicatedStorage

-- ==========================================
-- CLIENT → SERVER REMOTES
-- ==========================================

-- Group management
local CreateGroup = Instance.new("RemoteEvent"); CreateGroup.Name = "CreateGroup"; CreateGroup.Parent = blurRemotes
local DeleteGroup = Instance.new("RemoteEvent"); DeleteGroup.Name = "DeleteGroup"; DeleteGroup.Parent = blurRemotes
local UpdateGroup = Instance.new("RemoteEvent"); UpdateGroup.Name = "UpdateGroup"; UpdateGroup.Parent = blurRemotes

-- Player management
local WhitelistPlayer = Instance.new("RemoteEvent"); WhitelistPlayer.Name = "WhitelistPlayer"; WhitelistPlayer.Parent = blurRemotes
local RemovePlayer = Instance.new("RemoteEvent"); RemovePlayer.Name = "RemovePlayer"; RemovePlayer.Parent = blurRemotes
local KickPlayer = Instance.new("RemoteEvent"); KickPlayer.Name = "KickPlayer"; KickPlayer.Parent = blurRemotes
local FetchPlayers = Instance.new("RemoteEvent"); FetchPlayers.Name = "FetchPlayers"; FetchPlayers.Parent = blurRemotes

-- Laser control
local TriggerEffect = Instance.new("RemoteEvent"); TriggerEffect.Name = "TriggerEffect"; TriggerEffect.Parent = blurRemotes
local SetToggle = Instance.new("RemoteEvent"); SetToggle.Name = "SetToggle"; SetToggle.Parent = blurRemotes
local ApplyCustomisation = Instance.new("RemoteEvent"); ApplyCustomisation.Name = "ApplyCustomisation"; ApplyCustomisation.Parent = blurRemotes
local SetPosition = Instance.new("RemoteEvent"); SetPosition.Name = "SetPosition"; SetPosition.Parent = blurRemotes

-- Timecode
local StartTimecode = Instance.new("RemoteEvent"); StartTimecode.Name = "StartTimecode"; StartTimecode.Parent = blurRemotes
local StopTimecode = Instance.new("RemoteEvent"); StopTimecode.Name = "StopTimecode"; StopTimecode.Parent = blurRemotes

-- Hub
local SaveToHub = Instance.new("RemoteEvent"); SaveToHub.Name = "SaveToHub"; SaveToHub.Parent = blurRemotes
local FetchHubEffects = Instance.new("RemoteFunction"); FetchHubEffects.Name = "FetchHubEffects"; FetchHubEffects.Parent = blurRemotes

-- ==========================================
-- SERVER → CLIENT REMOTES
-- ==========================================

local NotifyClient = Instance.new("RemoteEvent"); NotifyClient.Name = "NotifyClient"; NotifyClient.Parent = blurRemotes
local SyncGroups = Instance.new("RemoteEvent"); SyncGroups.Name = "SyncGroups"; SyncGroups.Parent = blurRemotes
local SyncPlayers = Instance.new("RemoteEvent"); SyncPlayers.Name = "SyncPlayers"; SyncPlayers.Parent = blurRemotes
local SyncHubEffects = Instance.new("RemoteEvent"); SyncHubEffects.Name = "SyncHubEffects"; SyncHubEffects.Parent = blurRemotes

-- ==========================================
-- SERVER SETUP
-- ==========================================

function RemoteEvents.setup()
    -- Whitelist player
    WhitelistPlayer.OnServerEvent:Connect(function(player, targetPlayerId)
        print("[The-Blur Server] " .. player.Name .. " whitelisted " .. tostring(targetPlayerId))
    end)

    -- Remove player access
    RemovePlayer.OnServerEvent:Connect(function(player, targetPlayerId)
        print("[The-Blur Server] " .. player.Name .. " removed " .. tostring(targetPlayerId))
    end)

    -- Kick player
    KickPlayer.OnServerEvent:Connect(function(player, targetPlayerId)
        print("[The-Blur Server] " .. player.Name .. " kicked " .. tostring(targetPlayerId))
    end)

    -- Trigger laser effect
    TriggerEffect.OnServerEvent:Connect(function(player, effectData)
        print("[The-Blur Server] " .. player.Name .. " triggered effect: " .. tostring(effectData and effectData.name or "unknown"))
    end)

    -- Set toggle state
    SetToggle.OnServerEvent:Connect(function(player, toggleName, value)
        print("[The-Blur Server] " .. player.Name .. " set " .. toggleName .. " = " .. tostring(value))
    end)

    -- Apply customisation
    ApplyCustomisation.OnServerEvent:Connect(function(player, customData)
        print("[The-Blur Server] " .. player.Name .. " applied customisation")
    end)

    -- Set position
    SetPosition.OnServerEvent:Connect(function(player, positionData)
        print("[The-Blur Server] " .. player.Name .. " set position")
    end)

    -- Start timecode playback
    StartTimecode.OnServerEvent:Connect(function(player, timecodeData)
        print("[The-Blur Server] " .. player.Name .. " started timecode: " .. tostring(timecodeData and timecodeData.name or ""))
    end)

    -- Stop timecode
    StopTimecode.OnServerEvent:Connect(function(player)
        print("[The-Blur Server] " .. player.Name .. " stopped timecode")
    end)

    -- Save to hub
    SaveToHub.OnServerEvent:Connect(function(player, effectData)
        print("[The-Blur Server] " .. player.Name .. " saved effect to hub")
    end)

    -- Fetch hub effects (RemoteFunction)
    FetchHubEffects.OnServerInvoke = function(player)
        print("[The-Blur Server] " .. player.Name .. " fetched hub effects")
        return {} -- Return hub effects data
    end

    print("[The-Blur] RemoteEvents setup complete")
end

function RemoteEvents.getClientRemotes()
    return {
        CreateGroup = CreateGroup,
        DeleteGroup = DeleteGroup,
        UpdateGroup = UpdateGroup,
        WhitelistPlayer = WhitelistPlayer,
        RemovePlayer = RemovePlayer,
        KickPlayer = KickPlayer,
        FetchPlayers = FetchPlayers,
        TriggerEffect = TriggerEffect,
        SetToggle = SetToggle,
        ApplyCustomisation = ApplyCustomisation,
        SetPosition = SetPosition,
        StartTimecode = StartTimecode,
        StopTimecode = StopTimecode,
        SaveToHub = SaveToHub,
        FetchHubEffects = FetchHubEffects,
        NotifyClient = NotifyClient,
        SyncGroups = SyncGroups,
        SyncPlayers = SyncPlayers,
        SyncHubEffects = SyncHubEffects,
    }
end

return RemoteEvents
