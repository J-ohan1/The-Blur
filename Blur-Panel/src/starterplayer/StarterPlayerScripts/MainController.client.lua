--[[
    MainController.lua (LocalScript)
    Entry point for The-Blur SurfaceGUI Panel

    Place this as a LocalScript inside: Main/Scripts/MainController
    The SurfaceGui should be at: Panel/Panel/GUI
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Wait for Rojo to sync workspace objects
local function findSurfaceGui(maxRetries)
    maxRetries = maxRetries or 20
    for i = 1, maxRetries do
        local blurLasers = workspace:FindFirstChild("The-Blur-Lasers")
        if blurLasers then
            local panelFolder = blurLasers:FindFirstChild("Panel")
            if panelFolder then
                local panelPart = panelFolder:FindFirstChild("Panel")
                if panelPart then
                    local gui = panelPart:FindFirstChild("GUI")
                    if gui then
                        return gui
                    end
                end
            end
        end
        task.wait(0.5)
    end
    return nil
end

local surfaceGui = findSurfaceGui(20)
if not surfaceGui then
    warn("[The-Blur] Could not find SurfaceGui at Panel/Panel/GUI after retries!")
    warn("[The-Blur] Make sure your workspace hierarchy is correct:")
    warn("  The-Blur-Lasers/Panel/Panel/GUI (SurfaceGui)")
    return
end

assert(surfaceGui:IsA("SurfaceGui") or surfaceGui:IsA("ScreenGui"),
    "GUI must be a SurfaceGui or ScreenGui! Got: " .. surfaceGui.ClassName)

-- Configure SurfaceGui for 4K
surfaceGui.ResetOnSpawn = false
if surfaceGui:IsA("SurfaceGui") then
    surfaceGui.CanvasSize = Vector2.new(3840, 2160)
    surfaceGui.SpreadWhenEnabled = false
    surfaceGui.LightInfluence = 0
end

-- Clear existing GUI children
for _, child in ipairs(surfaceGui:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end

-- Require modules (with retry for Rojo sync)
local function findScriptsFolder(maxRetries)
    maxRetries = maxRetries or 10
    for i = 1, maxRetries do
        local blurLasers = workspace:FindFirstChild("The-Blur-Lasers")
        if blurLasers then
            local main = blurLasers:FindFirstChild("Main")
            if main then
                local scripts = main:FindFirstChild("Scripts")
                if scripts then
                    return scripts
                end
            end
        end
        task.wait(0.5)
    end
    return nil
end

local scriptsFolder = findScriptsFolder(10)
if not scriptsFolder then
    warn("[The-Blur] Could not find Scripts folder after retries!")
    return
end

local Theme = require(scriptsFolder:FindFirstChild("Theme"))
local Store = require(scriptsFolder:FindFirstChild("Store"))
local TweenHelper = require(scriptsFolder:FindFirstChild("TweenHelper"))

-- Create store
local store = Store.new()
local playerName = player.DisplayName or player.Name
store.currentUser.name = playerName

-- ==========================================
-- MAIN CONTAINER
-- ==========================================
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainContainer"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Theme.Colors.Background
mainFrame.BackgroundTransparency = 0
mainFrame.ZIndex = 1
mainFrame.Parent = surfaceGui

-- ==========================================
-- PHASE 1: LANDING PAGE
-- ==========================================
local LandingPanel = require(scriptsFolder.Panels:FindFirstChild("LandingPanel"))
local landingPanel = LandingPanel.new(mainFrame, store, function()
    store:setPhase("welcome")
end)
landingPanel:show()

-- ==========================================
-- PHASE 2: WELCOME SCREEN
-- ==========================================
local WelcomePanel = require(scriptsFolder.Panels:FindFirstChild("WelcomePanel"))
local welcomePanel = WelcomePanel.new(mainFrame, store)
welcomePanel.frame.Visible = false

-- ==========================================
-- PHASE 3: MAIN APPLICATION
-- ==========================================

-- NavBar
local NavBar = require(scriptsFolder:FindFirstChild("NavBar"))
local navBar = NavBar.new(mainFrame, store)
navBar:hide()

-- Toast System
local ToastSystem = require(scriptsFolder:FindFirstChild("ToastSystem"))
local toastSystem = ToastSystem.new(mainFrame, store)
toastSystem.frame.Visible = false

-- Profile Dropdown
local ProfileDropdown = require(scriptsFolder:FindFirstChild("ProfileDropdown"))
local profileDropdown = ProfileDropdown.new(mainFrame, store)
profileDropdown.frame.Visible = false

-- Easter Egg Popup
local EasterEggPopup = require(scriptsFolder:FindFirstChild("EasterEggPopup"))
local easterEggPopup = EasterEggPopup.new(mainFrame)
easterEggPopup.frame.Visible = false

-- Panel Container
local panelContainer = Instance.new("Frame")
panelContainer.Name = "PanelContainer"
panelContainer.Size = UDim2.new(1, 0, 1, -Theme.Spacing.NavBarHeight)
panelContainer.Position = UDim2.new(0, 0, 0, Theme.Spacing.NavBarHeight)
panelContainer.BackgroundTransparency = 1
panelContainer.ClipsDescendants = true
panelContainer.ZIndex = 2
panelContainer.Visible = false
panelContainer.Parent = mainFrame

-- ==========================================
-- CREATE ALL PANELS
-- ==========================================

local HomePanel = require(scriptsFolder.Panels:FindFirstChild("HomePanel"))
local homePanel = HomePanel.new(panelContainer)
homePanel:hide()

local ControlPanel = require(scriptsFolder.Panels:FindFirstChild("ControlPanel"))
local controlPanel = ControlPanel.new(panelContainer, store)
controlPanel:hide()

local CustomisationPanel = require(scriptsFolder.Panels:FindFirstChild("CustomisationPanel"))
local customisationPanel = CustomisationPanel.new(panelContainer, store)
customisationPanel:hide()

local GroupPanel = require(scriptsFolder.Panels:FindFirstChild("GroupPanel"))
local groupPanel = GroupPanel.new(panelContainer, store)
groupPanel:hide()

local PlayerPanel = require(scriptsFolder.Panels:FindFirstChild("PlayerPanel"))
local playerPanel = PlayerPanel.new(panelContainer, store)
playerPanel:hide()

local EffectPanel = require(scriptsFolder.Panels:FindFirstChild("EffectPanel"))
local effectPanel = EffectPanel.new(panelContainer, store)
effectPanel:hide()

local HubPanel = require(scriptsFolder.Panels:FindFirstChild("HubPanel"))
local hubPanel = HubPanel.new(panelContainer, store)
hubPanel:hide()

local KeybindPanel = require(scriptsFolder.Panels:FindFirstChild("KeybindPanel"))
local keybindPanel = KeybindPanel.new(panelContainer, store)
keybindPanel:hide()

local TimecodePanel = require(scriptsFolder.Panels:FindFirstChild("TimecodePanel"))
local timecodePanel = TimecodePanel.new(panelContainer, store)
timecodePanel:hide()

local InfoPanel = require(scriptsFolder.Panels:FindFirstChild("InfoPanel"))
local infoPanel = InfoPanel.new(panelContainer)
infoPanel:hide()

-- Panel mapping
local panels = {
    home = homePanel,
    control = controlPanel,
    customisation = customisationPanel,
    group = groupPanel,
    player = playerPanel,
    effect = effectPanel,
    hub = hubPanel,
    keybind = keybindPanel,
    timecode = timecodePanel,
    info = infoPanel,
}

local currentActivePanel = nil

local function showPanel(panelName)
    if currentActivePanel and panels[currentActivePanel] then
        panels[currentActivePanel]:hide()
    end
    if panels[panelName] then
        panels[panelName]:show()
        currentActivePanel = panelName
    end
    navBar:setActivePanel(panelName)
end

-- ==========================================
-- PHASE TRANSITIONS
-- ==========================================

store:on("phaseChanged", function(newPhase)
    if newPhase == "landing" then
        landingPanel:show()
        welcomePanel.frame.Visible = false
        panelContainer.Visible = false
        navBar:hide()
        toastSystem.frame.Visible = false
    elseif newPhase == "welcome" then
        landingPanel:hide()
        wait(0.3)
        welcomePanel.frame.Visible = true
        welcomePanel:show()
        spawn(function()
            wait(2.5)
            if store.phase == "welcome" then
                store:setPhase("main")
            end
        end)
    elseif newPhase == "main" then
        welcomePanel.frame.Visible = false
        landingPanel:hide()
        navBar:show()
        toastSystem.frame.Visible = true
        panelContainer.Visible = true
        showPanel("home")
    end
end)

-- ==========================================
-- NAVIGATION
-- ==========================================

store:on("panelChanged", function(panelName)
    if store.phase == "main" then
        showPanel(panelName)
    end
end)

-- ==========================================
-- EASTER EGG
-- ==========================================

store:on("easterEggTriggered", function()
    easterEggPopup:show()
end)

-- ==========================================
-- PROFILE DROPDOWN
-- ==========================================

store:on("profileDropdownChanged", function(isOpen)
    if isOpen then
        profileDropdown:open()
    else
        profileDropdown:close()
    end
end)

-- Navigate to keybinds from profile dropdown
store:on("navigateToKeybinds", function()
    profileDropdown:close()
    store:setActivePanel("keybind")
end)

-- ==========================================
-- CLEANUP
-- ==========================================

player.CharacterRemoving:Connect(function()
    for _, panel in pairs(panels) do
        if panel.destroy then panel:destroy() end
    end
    if landingPanel.destroy then landingPanel:destroy() end
    if welcomePanel.frame then welcomePanel.frame:Destroy() end
    if navBar.destroy then navBar:destroy() end
    if toastSystem.destroy then toastSystem:destroy() end
    if profileDropdown.destroy then profileDropdown:destroy() end
    if easterEggPopup.destroy then easterEggPopup:destroy() end
end)

print("[The-Blur] Panel loaded successfully! Welcome, " .. playerName)
