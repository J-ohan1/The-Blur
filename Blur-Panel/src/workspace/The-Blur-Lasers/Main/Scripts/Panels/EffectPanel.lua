--[[
    EffectPanel.lua — Effect Panel & Editor (The Most Complex Panel)
    The-Blur Roblox SurfaceGUI  |  4K (3840x2160)

    Two views: "list" (effect cards grid) and "editor" (beam canvas + timeline + properties)
    Includes: Save Dialog, Preset Browser, Keyboard Shortcuts, Easter Eggs, Undo/Redo

    Usage:
        local EffectPanel = require(script.Parent.EffectPanel)
        local panel = EffectPanel.new(parent, store)
        panel:show()
        panel:hide()
        panel:destroy()
]]

--------------------------------------------------------------------------------
-- Dependencies
--------------------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)
local TweenHelper = require(script.Parent.Parent.TweenHelper)
local EffectPresets = require(script.Parent.Parent.EffectPresets)

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
local TYPE_BADGE = {
    movement = "Movement",
    pattern = "Pattern",
    chase = "Chase",
    wave = "Wave",
    color = "Color",
    custom = "Custom",
}

local EFFECT_TYPES = {
    { value = "movement", label = "Movement" },
    { value = "pattern",  label = "Pattern" },
    { value = "chase",    label = "Chase" },
    { value = "wave",     label = "Wave" },
    { value = "color",    label = "Color" },
    { value = "custom",   label = "Custom" },
}

local BROWSE_CATEGORIES = {
    { value = "all",      label = "All" },
    { value = "waves",    label = "Waves" },
    { value = "chase",    label = "Chase" },
    { value = "pattern",  label = "Pattern" },
    { value = "color",    label = "Color" },
    { value = "advanced", label = "Advanced" },
}

local MAX_UNDO = 50

--------------------------------------------------------------------------------
-- Helper: deep copy a table
--------------------------------------------------------------------------------
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

--------------------------------------------------------------------------------
-- Helper: create UI primitives matching the design system
--------------------------------------------------------------------------------
local function createFrame(props)
    local f = Instance.new("Frame")
    f.Name = props.name or "Frame"
    f.Size = props.size or UDim2.new(1, 0, 1, 0)
    f.Position = props.position or UDim2.new(0, 0, 0, 0)
    f.AnchorPoint = props.anchorPoint or Vector2.new(0, 0)
    f.BackgroundColor3 = props.color or Color3.new(1, 1, 1)
    f.BackgroundTransparency = props.transparency or 1
    f.BorderSizePixel = 0
    f.ZIndex = props.zIndex or 1
    f.ClipsDescendants = props.clips or false
    if props.parent then f.Parent = props.parent end
    return f
end

local function createCorner(props)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, props.radius or Theme.CornerRadius.LG)
    if props.parent then c.Parent = props.parent end
    return c
end

local function createStroke(props)
    local s = Instance.new("UIStroke")
    s.Color = props.color or Theme.Colors.BorderDefault
    s.Transparency = props.transparency or 0
    s.Thickness = props.thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    if props.parent then s.Parent = props.parent end
    return s
end

local function createLabel(props)
    local l = Instance.new("TextLabel")
    l.Name = props.name or "Label"
    l.Size = props.size or UDim2.new(1, 0, 0, 24)
    l.Position = props.position or UDim2.new(0, 0, 0, 0)
    l.AnchorPoint = props.anchorPoint or Vector2.new(0, 0)
    l.BackgroundTransparency = 1
    l.Text = props.text or ""
    l.TextColor3 = props.textColor or Theme.Colors.TextPrimary
    l.TextSize = props.textSize or Theme.FontSize.Body
    l.Font = props.font or Theme.Font.FamilyMedium
    l.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
    l.TextYAlignment = props.yAlign or Enum.TextYAlignment.Center
    l.TextTransparency = props.textTransparency or 0
    l.ZIndex = props.zIndex or 2
    l.ClipsDescendants = props.clips or false
    if props.parent then l.Parent = props.parent end
    return l
end

local function createButton(props)
    local b = Instance.new("TextButton")
    b.Name = props.name or "Button"
    b.Size = props.size or UDim2.new(0, 100, 0, 40)
    b.Position = props.position or UDim2.new(0, 0, 0, 0)
    b.AnchorPoint = props.anchorPoint or Vector2.new(0, 0)
    b.BackgroundColor3 = props.color or Color3.new(1, 1, 1)
    b.BackgroundTransparency = props.transparency or 1
    b.BorderSizePixel = 0
    b.Text = props.text or ""
    b.TextColor3 = props.textColor or Theme.Colors.TextPrimary
    b.TextSize = props.textSize or Theme.FontSize.Button
    b.Font = props.font or Theme.Font.FamilyMedium
    b.AutoButtonColor = false
    b.ZIndex = props.zIndex or 5
    if props.corner then createCorner({ radius = props.corner, parent = b }) end
    if props.stroke then createStroke(props.stroke) end
    if props.padding then
        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0, props.padding[1] or 16)
        p.PaddingRight = UDim.new(0, props.padding[2] or 16)
        p.PaddingTop = UDim.new(0, props.padding[3] or 8)
        p.PaddingBottom = UDim.new(0, props.padding[4] or 8)
        p.Parent = b
    end
    if props.parent then b.Parent = props.parent end
    return b
end

local function createInput(props)
    local i = Instance.new("TextBox")
    i.Name = props.name or "Input"
    i.Size = props.size or UDim2.new(1, 0, 0, 40)
    i.Position = props.position or UDim2.new(0, 0, 0, 0)
    i.BackgroundColor3 = props.bgColor or Color3.fromRGB(0, 0, 0)
    i.BackgroundTransparency = 0
    i.BorderSizePixel = 0
    i.PlaceholderText = props.placeholder or ""
    i.PlaceholderColor3 = Theme.Colors.TextPlaceholder
    i.Text = props.text or ""
    i.TextColor3 = Theme.Colors.InputText
    i.TextSize = props.textSize or Theme.FontSize.Input
    i.Font = Theme.Font.FamilyLight
    i.TextXAlignment = Enum.TextXAlignment.Left
    i.ClearTextOnFocus = false
    i.ZIndex = props.zIndex or 20
    createCorner({ radius = Theme.CornerRadius.LG, parent = i })
    createStroke({ color = Theme.Colors.InputBorder, parent = i })
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, Theme.Spacing.InputPaddingX)
    pad.PaddingRight = UDim.new(0, Theme.Spacing.InputPaddingX)
    pad.PaddingTop = UDim.new(0, Theme.Spacing.InputPaddingY)
    pad.PaddingBottom = UDim.new(0, Theme.Spacing.InputPaddingY)
    pad.Parent = i
    if props.parent then i.Parent = props.parent end
    return i
end

local function createDivider(props)
    local d = Instance.new("Frame")
    d.Name = props.name or "Divider"
    d.Size = props.size or UDim2.new(1, 0, 0, 1)
    d.Position = props.position or UDim2.new(0, 0, 1, 0)
    d.AnchorPoint = props.anchorPoint or Vector2.new(0, 1)
    d.BackgroundColor3 = Theme.Colors.BorderDivider
    d.BackgroundTransparency = 0
    d.BorderSizePixel = 0
    d.ZIndex = props.zIndex or 2
    if props.parent then d.Parent = props.parent end
    return d
end

--------------------------------------------------------------------------------
-- EffectPanel
--------------------------------------------------------------------------------
local EffectPanel = {}
EffectPanel.__index = EffectPanel

function EffectPanel.new(parent, store)
    local self = setmetatable({}, EffectPanel)
    self.store = store
    self.connections = {}
    self.tweens = {}
    self.timers = {}
    self.currentView = "list" -- "list" | "editor"
    self.beamButtons = {} -- beam index -> button
    self.onionBeams = {} -- onion skin ghost buttons
    self.frameButtons = {} -- frame index -> button
    self.isDraggingBeam = false
    self.dragBeamIndex = 0
    self.dragStartX = 0
    self.dragStartY = 0
    self.dragStartBeamX = 0
    self.dragStartBeamY = 0
    self.playbackConnection = nil
    self.playheadPulseTween = nil

    -- Easter egg state
    self.prevAligned = false
    self.speedEasterTriggered = false
    self.frame42ToastTriggered = false
    self.lastSyncColor = ""
    self.save42Triggered = false
    self.chaseClicks = { count = 0, last = 0 }
    self.name42Triggered = false
    self.blurGlowTween = nil
    self.saveGlowActive = false

    -- Save dialog state
    self.saveTagInput = ""

    -- Preset browser state
    self.presetSearch = ""
    self.presetCategory = "all"

    -- Confirm delete
    self.confirmDeleteId = nil
    self.confirmDeleteTimer = nil

    -- Context menu
    self.activeContextMenu = nil

    -- Shift state for multi-select
    self.shiftHeld = false

    -- Create main frame
    self.frame = createFrame({
        name = "EffectPanel",
        size = UDim2.new(1, 0, 1, 0),
        color = Color3.new(0, 0, 0),
        transparency = 1,
        zIndex = Theme.ZIndex.Content,
        parent = parent,
    })

    -- Create list view container
    self.listView = createFrame({
        name = "ListView",
        size = UDim2.new(1, 0, 1, 0),
        parent = self.frame,
    })

    -- Create editor view container
    self.editorView = createFrame({
        name = "EditorView",
        size = UDim2.new(1, 0, 1, 0),
        parent = self.frame,
    })
    self.editorView.Visible = false

    -- Build UI
    self:_buildListView()
    self:_buildEditorView()
    self:_buildSaveDialog()
    self:_buildPresetBrowser()

    -- Store event listeners
    table.insert(self.connections, store:on("effectPanelViewChanged", function(view)
        self:setView(view)
    end))
    table.insert(self.connections, store:on("editorFramesChanged", function()
        if self.currentView == "editor" then
            self:_refreshCanvas()
            self:_refreshTimeline()
            self:_refreshProperties()
            self:_checkEasterEggs()
        end
    end))
    table.insert(self.connections, store:on("editorFrameIndexChanged", function()
        if self.currentView == "editor" then
            self:_refreshCanvas()
            self:_refreshTimeline()
            self:_refreshPlayhead()
            self:_refreshProperties()
        end
    end))
    table.insert(self.connections, store:on("editorSelectionChanged", function()
        if self.currentView == "editor" then
            self:_refreshCanvasSelections()
            self:_refreshBeamStrip()
            self:_refreshProperties()
        end
    end))
    table.insert(self.connections, store:on("editorPlayStateChanged", function()
        if self.currentView == "editor" then
            self:_updatePlayback()
        end
    end))
    table.insert(self.connections, store:on("editorLoopChanged", function()
        if self.currentView == "editor" then
            self:_refreshPlaybackControls()
        end
    end))
    table.insert(self.connections, store:on("editorSpeedChanged", function()
        if self.currentView == "editor" then
            self:_refreshPlaybackControls()
            self:_checkEasterEggs()
        end
    end))
    table.insert(self.connections, store:on("editorOnionSkinChanged", function()
        if self.currentView == "editor" then
            self:_refreshOnionSkin()
            self:_refreshPlaybackControls()
        end
    end))
    table.insert(self.connections, store:on("editorApplyToAllChanged", function()
        if self.currentView == "editor" then
            self:_refreshProperties()
        end
    end))
    table.insert(self.connections, store:on("editorSaveDialogChanged", function(open)
        if open then
            self:_openSaveDialog()
        else
            self:_closeSaveDialog()
        end
    end))
    table.insert(self.connections, store:on("editorPresetBrowserChanged", function(open)
        if open then
            self:_openPresetBrowser()
        else
            self:_closePresetBrowser()
        end
    end))
    table.insert(self.connections, store:on("effectSaved", function(effect)
        self:_refreshEffectGrid()
    end))

    -- Keyboard shortcuts
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if self.currentView ~= "editor" then return end
        self:_handleKeyInput(input)
    end))
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            self.shiftHeld = false
        end
    end))

    -- Global mouse tracking for beam dragging
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if self.isDraggingBeam then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                self:_handleBeamDrag(input)
            end
        end
    end))
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if self.isDraggingBeam then
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                self:_endBeamDrag()
            end
        end
    end))

    return self
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function EffectPanel:show()
    self.frame.Visible = true
    self:_refreshEffectGrid()
end

function EffectPanel:hide()
    self.frame.Visible = false
end

function EffectPanel:setView(view)
    self.currentView = view
    self.listView.Visible = (view == "list")
    self.editorView.Visible = (view == "editor")
    if view == "list" then
        self:_refreshEffectGrid()
        self:_stopPlayback()
    else
        self:_refreshCanvas()
        self:_refreshTimeline()
        self:_refreshBeamStrip()
        self:_refreshPlaybackControls()
        self:_refreshProperties()
    end
end

function EffectPanel:destroy()
    self:_stopPlayback()
    for _, conn in ipairs(self.connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    for _, tw in ipairs(self.tweens) do
        if tw and typeof(tw) == "userdata" then
            tw:Cancel()
        end
    end
    for name, conn in pairs(self.timers) do
        if conn then conn:Disconnect() end
    end
    if self.blurGlowTween then self.blurGlowTween:Cancel() end
    self.frame:Destroy()
end

--------------------------------------------------------------------------------
-- LIST VIEW
--------------------------------------------------------------------------------

function EffectPanel:_buildListView()
    local list = self.listView
    local store = self.store

    -- Header
    local header = createFrame({
        name = "Header",
        size = UDim2.new(1, 0, 0, 80),
        parent = list,
    })

    -- Header left: Title
    local title = createLabel({
        name = "Title",
        size = UDim2.new(0, 400, 0, 36),
        position = UDim2.new(0, Theme.Spacing.PanelPadding, 0, Theme.Spacing.PanelPadding),
        text = "Custom Effects",
        textColor = Theme.Colors.TextPrimary,
        textSize = Theme.FontSize.CardTitle,
        font = Theme.Font.FamilySemibold,
        zIndex = 3,
        parent = header,
    })

    self.listSubtitle = createLabel({
        name = "Subtitle",
        size = UDim2.new(0, 300, 0, 24),
        position = UDim2.new(0, Theme.Spacing.PanelPadding, 0, Theme.Spacing.PanelPadding + 40),
        text = "0 effects saved",
        textColor = Theme.Colors.TextSubtle,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.FamilyLight,
        zIndex = 3,
        parent = header,
    })

    -- Header right: buttons
    local presetsBtn = createButton({
        name = "PresetsBtn",
        size = UDim2.new(0, 160, 0, 48),
        position = UDim2.new(1, -(Theme.Spacing.PanelPadding + 320), 0, Theme.Spacing.PanelPadding),
        text = "Presets",
        textColor = Theme.Colors.ButtonGhostText,
        textSize = Theme.FontSize.Small,
        corner = Theme.CornerRadius.LG,
        padding = { 24, 24, 12, 12 },
        zIndex = 6,
        parent = header,
    })
    createStroke({ color = Theme.Colors.BorderDefault, transparency = 0, parent = presetsBtn })

    local newBtn = createButton({
        name = "NewEffectBtn",
        size = UDim2.new(0, 160, 0, 48),
        position = UDim2.new(1, -(Theme.Spacing.PanelPadding), 0, Theme.Spacing.PanelPadding),
        text = "Create Effect",
        textColor = Theme.Colors.ButtonPrimaryText,
        textSize = Theme.FontSize.Small,
        font = Theme.Font.FamilySemibold,
        color = Theme.Colors.ButtonPrimary,
        transparency = 0,
        corner = Theme.CornerRadius.LG,
        padding = { 24, 24, 12, 12 },
        zIndex = 6,
        parent = header,
    })

    -- Button hover effects
    self:_addHoverEffect(presetsBtn, Theme.Colors.SurfaceHover, Theme.Colors.ButtonSecondaryText)
    self:_addHoverEffect(newBtn, Theme.Colors.ButtonPrimaryHover, Theme.Colors.ButtonPrimaryText)

    -- Button click handlers
    table.insert(self.connections, newBtn.Activated:Connect(function()
        store:initEditorFrames(15, 24)
        store:setEffectPanelView("editor")
    end))
    table.insert(self.connections, presetsBtn.Activated:Connect(function()
        store:setEditorPresetBrowserOpen(true)
    end))

    -- Effects grid (scrollable)
    self.effectGrid = createFrame({
        name = "EffectGrid",
        size = UDim2.new(1, 0, 1, -100),
        position = UDim2.new(0, 0, 0, 100),
        clips = true,
        parent = list,
    })

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.5, -Theme.Spacing.GridGap, 0, 120)
    gridLayout.CellPadding = UDim2.new(0, Theme.Spacing.GridGap, 0, Theme.Spacing.GridGap)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = self.effectGrid

    local gridPadding = Instance.new("UIPadding")
    gridPadding.PaddingLeft = UDim.new(0, Theme.Spacing.PanelPadding)
    gridPadding.PaddingRight = UDim.new(0, Theme.Spacing.PanelPadding)
    gridPadding.PaddingTop = UDim.new(0, 4)
    gridPadding.PaddingBottom = UDim.new(0, Theme.Spacing.PanelPadding)
    gridPadding.Parent = self.effectGrid

    -- Scrollbar for grid
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "EffectScroll"
    scroll.Size = UDim2.new(1, -Theme.Scrollbar.Width, 1, 0)
    scroll.Position = UDim2.new(0, 0, 0, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 0
    scroll.ScrollBarImageTransparency = 1
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ElasticBehavior = Enum.ElasticBehavior.Never
    scroll.ScrollBarBehavior = Enum.ScrollBarBehavior.Never
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ZIndex = 2
    scroll.Parent = self.effectGrid

    self.effectScrollContent = createFrame({
        name = "ScrollContent",
        size = UDim2.new(1, 0, 1, 0),
        parent = scroll,
    })
    local scrollLayout = Instance.new("UIGridLayout")
    scrollLayout.CellSize = UDim2.new(0.5, -Theme.Spacing.GridGap, 0, 120)
    scrollLayout.CellPadding = UDim2.new(0, Theme.Spacing.GridGap, 0, Theme.Spacing.GridGap)
    scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scrollLayout.Parent = self.effectScrollContent

    local scrollPad = Instance.new("UIPadding")
    scrollPad.PaddingLeft = UDim.new(0, Theme.Spacing.PanelPadding)
    scrollPad.PaddingRight = UDim.new(0, Theme.Spacing.PanelPadding + Theme.Scrollbar.Width)
    scrollPad.PaddingTop = UDim.new(0, 4)
    scrollPad.PaddingBottom = UDim.new(0, Theme.Spacing.PanelPadding)
    scrollPad.Parent = self.effectScrollContent

    self.gridLayoutRef = scrollLayout

    -- Empty state
    self.emptyState = createFrame({
        name = "EmptyState",
        size = UDim2.new(1, 0, 1, -100),
        position = UDim2.new(0, 0, 0, 100),
        parent = list,
    })
    self.emptyState.Visible = false

    -- FX icon placeholder (pulsing)
    local fxIconBg = createFrame({
        name = "FxIconBg",
        size = UDim2.new(0, 200, 0, 200),
        position = UDim2.new(0.5, -100, 0.4, -100),
        anchorPoint = Vector2.new(0, 0),
        color = Color3.fromRGB(15, 15, 15),
        transparency = 0.5,
        corner = Theme.CornerRadius.XXL,
        zIndex = 2,
        parent = self.emptyState,
    })
    createStroke({ color = Theme.Colors.BorderDefault, transparency = 0.5, parent = fxIconBg })

    local fxLabel = createLabel({
        name = "FxLabel",
        size = UDim2.new(1, 0, 1, 0),
        text = "FX",
        textColor = Color3.fromRGB(64, 64, 64),
        textSize = 96,
        font = Theme.Font.FamilyBlack,
        xAlign = Enum.TextXAlignment.Center,
        zIndex = 3,
        parent = fxIconBg,
    })

    -- Pulsing animation on FX icon
    spawn(function()
        while self.emptyState and self.emptyState.Parent do
            TweenHelper.pulse(fxLabel, "TextTransparency", 0.7, 0, 2)
            wait(2)
        end
    end)

    createLabel({
        name = "EmptyTitle",
        size = UDim2.new(0, 400, 0, 30),
        position = UDim2.new(0.5, -200, 0.4, 120),
        text = "No custom effects yet",
        textColor = Theme.Colors.TextMuted,
        textSize = Theme.FontSize.Body,
        font = Theme.Font.FamilyMedium,
        xAlign = Enum.TextXAlignment.Center,
        zIndex = 3,
        parent = self.emptyState,
    })

    createLabel({
        name = "EmptySubtitle",
        size = UDim2.new(0, 400, 0, 26),
        position = UDim2.new(0.5, -200, 0.4, 154),
        text = "Create your first laser effect or browse presets",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.FamilyLight,
        xAlign = Enum.TextXAlignment.Center,
        zIndex = 3,
        parent = self.emptyState,
    })

    -- Scrollbar styling for effect grid
    self:_addCustomScrollbar(scroll, self.effectGrid)
end

function EffectPanel:_refreshEffectGrid()
    local effects = self.store.savedEffects
    local count = #effects

    -- Update subtitle
    if self.listSubtitle then
        self.listSubtitle.Text = count .. " effect" .. (count ~= 1 and "s" or "") .. " saved"
    end

    -- Toggle empty state vs grid
    if self.emptyState then
        self.emptyState.Visible = (count == 0)
    end

    -- Clear existing cards
    for _, child in ipairs(self.effectScrollContent:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Build cards
    for idx, effect in ipairs(effects) do
        self:_createEffectCard(effect, idx)
    end
end

function EffectPanel:_createEffectCard(effect, idx)
    local store = self.store
    local isDeleting = (self.confirmDeleteId == effect.id)

    local card = Instance.new("TextButton")
    card.Name = "EffectCard_" .. effect.id
    card.Size = UDim2.new(0.5, -Theme.Spacing.GridGap, 0, 120)
    card.BackgroundColor3 = isDeleting and Color3.fromRGB(40, 10, 10) or Color3.fromRGB(10, 10, 10)
    card.BackgroundTransparency = 0.5
    card.BorderSizePixel = 0
    card.AutoButtonColor = false
    card.LayoutOrder = idx
    card.ZIndex = 5
    card.Text = ""

    createCorner({ radius = Theme.CornerRadius.XL, parent = card })
    createStroke({
        color = isDeleting and Color3.fromRGB(127, 29, 29) or Theme.Colors.BorderDefault,
        transparency = isDeleting and 0.4 or 0.4,
        parent = card,
    })

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, Theme.Spacing.CardPadding)
    pad.PaddingRight = UDim.new(0, Theme.Spacing.CardPadding)
    pad.PaddingTop = UDim.new(0, Theme.Spacing.CardPadding)
    pad.PaddingBottom = UDim.new(0, Theme.Spacing.CardPadding)
    pad.Parent = card

    -- Card content container
    local content = createFrame({
        name = "CardContent",
        size = UDim2.new(1, 0, 1, 0),
        parent = card,
    })

    -- Name
    createLabel({
        name = "EffectName",
        size = UDim2.new(1, -80, 0, 26),
        text = effect.name,
        textColor = Theme.Colors.TextSecondary,
        textSize = Theme.FontSize.CardTitle,
        font = Theme.Font.FamilySemibold,
        zIndex = 3,
        parent = content,
    })

    -- Type badge
    local badge = createFrame({
        name = "TypeBadge",
        size = UDim2.new(0, 120, 0, 22),
        position = UDim2.new(0, 0, 0, 32),
        color = Theme.Colors.SurfaceActive,
        transparency = 0.4,
        corner = Theme.CornerRadius.MD,
        zIndex = 3,
        parent = content,
    })
    createLabel({
        name = "BadgeText",
        size = UDim2.new(1, 0, 1, 0),
        text = TYPE_BADGE[effect.type] or effect.type,
        textColor = Theme.Colors.TextBody,
        textSize = Theme.FontSize.Tiny,
        font = Theme.Font.FamilyMedium,
        xAlign = Enum.TextXAlignment.Center,
        zIndex = 4,
        parent = badge,
    })

    -- Frame count
    createLabel({
        name = "FrameCount",
        size = UDim2.new(0, 60, 0, 22),
        position = UDim2.new(0, 130, 0, 32),
        text = (#effect.frames or 0) .. "F",
        textColor = Theme.Colors.TextSubtle,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.FamilyMedium,
        zIndex = 3,
        parent = content,
    })

    -- Source tag
    createLabel({
        name = "SourceTag",
        size = UDim2.new(0, 80, 0, 22),
        position = UDim2.new(0, 200, 0, 32),
        text = "Custom",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.FamilyLight,
        zIndex = 3,
        parent = content,
    })

    -- Hover actions (top-right)
    local actionsFrame = createFrame({
        name = "HoverActions",
        size = UDim2.new(0, 120, 0, 28),
        position = UDim2.new(1, -120, 0, 0),
        zIndex = 10,
        parent = content,
    })

    local editBtn = createButton({
        name = "EditBtn",
        size = UDim2.new(0, 50, 0, 28),
        position = UDim2.new(0, 0, 0, 0),
        text = "Edit",
        textColor = Theme.Colors.TextBody,
        textSize = Theme.FontSize.Tiny,
        zIndex = 11,
        parent = actionsFrame,
    })

    local deleteBtn = createButton({
        name = "DeleteBtn",
        size = UDim2.new(0, 60, 0, 28),
        position = UDim2.new(0, 58, 0, 0),
        text = isDeleting and "Confirm?" or "Delete",
        textColor = isDeleting and Color3.fromRGB(248, 113, 113) or Theme.Colors.TextSubtle,
        textSize = Theme.FontSize.Tiny,
        zIndex = 11,
        parent = actionsFrame,
    })

    -- Initially hide actions
    actionsFrame.BackgroundTransparency = 1

    -- Hover effects
    table.insert(self.connections, card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(Theme.Animation.HoverEnter), {
            BackgroundTransparency = 0.35,
        }):Play()
        TweenService:Create(actionsFrame, TweenInfo.new(Theme.Animation.HoverEnter), {
            BackgroundTransparency = 0,
        }):Play()
        TweenService:Create(editBtn, TweenInfo.new(Theme.Animation.HoverEnter), {
            TextTransparency = 0,
        }):Play()
        TweenService:Create(deleteBtn, TweenInfo.new(Theme.Animation.HoverEnter), {
            TextTransparency = 0,
        }):Play()
        -- Change stroke
        local stroke = card:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = Theme.Colors.BorderHover
            stroke.Transparency = 0.2
        end
    end))

    table.insert(self.connections, card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(Theme.Animation.HoverExit), {
            BackgroundTransparency = 0.5,
        }):Play()
        TweenService:Create(actionsFrame, TweenInfo.new(Theme.Animation.HoverExit), {
            BackgroundTransparency = 1,
        }):Play()
        local stroke = card:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = isDeleting and Color3.fromRGB(127, 29, 29) or Theme.Colors.BorderDefault
            stroke.Transparency = 0.4
        end
    end))

    -- Card click -> open editor
    table.insert(self.connections, card.Activated:Connect(function()
        if effect.frames and #effect.frames > 0 then
            store:loadEditorFrames(effect.frames)
        else
            store:initEditorFrames(15, 24)
        end
        store:setEffectPanelView("editor")
    end))

    -- Edit button
    table.insert(self.connections, editBtn.Activated:Connect(function()
        if effect.frames and #effect.frames > 0 then
            store:loadEditorFrames(effect.frames)
        else
            store:initEditorFrames(15, 24)
        end
        store:setEffectPanelView("editor")
    end))

    -- Delete button
    table.insert(self.connections, deleteBtn.Activated:Connect(function()
        self:_handleDeleteEffect(effect)
    end))

    card.Parent = self.effectScrollContent
end

function EffectPanel:_handleDeleteEffect(effect)
    if self.confirmDeleteId == effect.id then
        -- Confirm delete
        self.confirmDeleteId = nil
        for i, e in ipairs(self.store.savedEffects) do
            if e.id == effect.id then
                table.remove(self.store.savedEffects, i)
                break
            end
        end
        self.store:emit("effectSaved", {})
        self.store:addToast('Effect "' .. effect.name .. '" deleted', "success")
        self:_refreshEffectGrid()
    else
        -- Start confirm timer
        self.confirmDeleteId = effect.id
        self:_refreshEffectGrid()
        if self.confirmDeleteTimer then
            self.confirmDeleteTimer:Disconnect()
        end
        self.confirmDeleteTimer = spawn(function()
            wait(3)
            if self.confirmDeleteId == effect.id then
                self.confirmDeleteId = nil
                if self.currentView == "list" then
                    self:_refreshEffectGrid()
                end
            end
        end)
    end
end

--------------------------------------------------------------------------------
-- EDITOR VIEW
--------------------------------------------------------------------------------

function EffectPanel:_buildEditorView()
    local editor = self.editorView

    -- Toolbar (top bar)
    self.toolbar = createFrame({
        name = "Toolbar",
        size = UDim2.new(1, 0, 0, 56),
        parent = editor,
    })
    self:_buildToolbar()

    -- Main area (canvas + properties side by side)
    self.mainArea = createFrame({
        name = "MainArea",
        size = UDim2.new(1, 0, 1, -260),
        position = UDim2.new(0, 0, 0, 56),
        parent = editor,
    })

    -- Canvas (left, flexible)
    self.canvasContainer = createFrame({
        name = "CanvasContainer",
        size = UDim2.new(1, -440, 1, 0),
        parent = self.mainArea,
    })
    self:_buildCanvas()

    -- Properties panel (right)
    self.propertiesPanel = createFrame({
        name = "PropertiesPanel",
        size = UDim2.new(0, 416, 1, 0),
        position = UDim2.new(1, -416, 0, 0),
        parent = self.mainArea,
    })
    self:_buildPropertiesPanel()

    -- Timeline (bottom)
    self.timelineArea = createFrame({
        name = "TimelineArea",
        size = UDim2.new(1, 0, 0, 200),
        position = UDim2.new(0, 0, 1, -200),
        parent = editor,
    })
    self:_buildTimeline()
end

function EffectPanel:_buildToolbar()
    local tb = self.toolbar
    local store = self.store
    local btnH = 40
    local gap = 8
    local xOff = Theme.Spacing.MD

    local function tbBtn(text, xPos, callback)
        local b = createButton({
            name = text,
            size = UDim2.new(0, 80, 0, btnH),
            position = UDim2.new(0, xPos, 0.5, -btnH / 2),
            text = text,
            textColor = Theme.Colors.TextBody,
            textSize = Theme.FontSize.Small,
            corner = Theme.CornerRadius.LG,
            padding = { 16, 16, 8, 8 },
            zIndex = 6,
            parent = tb,
        })
        createStroke({ color = Theme.Colors.BorderDefault, transparency = 0.6, parent = b })
        self:_addHoverEffect(b, Theme.Colors.SurfaceHover, Theme.Colors.ButtonSecondaryText)
        if callback then
            table.insert(self.connections, b.Activated:Connect(callback))
        end
        return b
    end

    -- Back button
    tbBtn("Back", xOff, function()
        store:setEffectPanelView("list")
    end)
    xOff = xOff + 88 + gap

    -- Divider
    local div = createFrame({
        size = UDim2.new(0, 1, 0, 20),
        position = UDim2.new(0, xOff, 0.5, -10),
        color = Theme.Colors.BorderDivider,
        parent = tb,
    })
    xOff = xOff + 8 + gap

    -- New button
    tbBtn("New", xOff, function()
        store:initEditorFrames(15, 24)
    end)
    xOff = xOff + 68 + gap

    -- Save button (primary)
    local saveBtn = createButton({
        name = "Save",
        size = UDim2.new(0, 80, 0, btnH),
        position = UDim2.new(0, xOff, 0.5, -btnH / 2),
        text = "Save",
        textColor = Theme.Colors.ButtonPrimaryText,
        textSize = Theme.FontSize.Small,
        font = Theme.Font.FamilySemibold,
        color = Theme.Colors.ButtonPrimary,
        transparency = 0,
        corner = Theme.CornerRadius.LG,
        padding = { 16, 16, 8, 8 },
        zIndex = 6,
        parent = tb,
    })
    self:_addHoverEffect(saveBtn, Theme.Colors.ButtonPrimaryHover, Theme.Colors.ButtonPrimaryText)
    table.insert(self.connections, saveBtn.Activated:Connect(function()
        store:setEditorSaveDialogOpen(true)
    end))
    xOff = xOff + 88 + gap

    -- Presets button
    tbBtn("Presets", xOff, function()
        store:setEditorPresetBrowserOpen(true)
    end)
    xOff = xOff + 88 + gap

    -- Divider
    createFrame({
        size = UDim2.new(0, 1, 0, 20),
        position = UDim2.new(0, xOff, 0.5, -10),
        color = Theme.Colors.BorderDivider,
        parent = tb,
    })
    xOff = xOff + 8 + gap

    -- Undo button
    tbBtn("Undo", xOff, function()
        store:editorUndo()
    end)
    xOff = xOff + 72 + gap

    -- Redo button
    tbBtn("Redo", xOff, function()
        store:editorRedo()
    end)
    xOff = xOff + 72 + gap

    -- Right side: frame count + selection count
    self.toolbarInfo = createLabel({
        name = "ToolbarInfo",
        size = UDim2.new(0, 200, 0, 24),
        position = UDim2.new(1, -(Theme.Spacing.MD), 0.5, -12),
        text = "0F  |  0 sel",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.Mono,
        xAlign = Enum.TextXAlignment.Right,
        zIndex = 3,
        parent = tb,
    })

    -- Toolbar bottom divider
    createDivider({
        size = UDim2.new(1, 0, 0, 1),
        position = UDim2.new(0, 0, 1, 0),
        anchorPoint = Vector2.new(0, 1),
        parent = tb,
    })
end

function EffectPanel:_buildCanvas()
    local container = self.canvasContainer
    local pad = Theme.Spacing.SM

    -- Canvas frame with dot grid bg
    self.canvas = createFrame({
        name = "Canvas",
        size = UDim2.new(1, -pad * 2, 1, -pad * 2),
        position = UDim2.new(0, pad, 0, pad),
        color = Color3.fromRGB(10, 10, 10),
        transparency = 0.5,
        corner = Theme.CornerRadius.XL,
        clips = true,
        zIndex = 3,
        parent = container,
    })
    createStroke({ color = Theme.Colors.BorderDefault, transparency = 0.3, parent = self.canvas })

    -- Dot grid pattern (approximate with small frames)
    local dotGrid = Instance.new("Frame")
    dotGrid.Name = "DotGrid"
    dotGrid.Size = UDim2.new(1, 0, 1, 0)
    dotGrid.BackgroundTransparency = 1
    dotGrid.ClipsDescendants = false
    dotGrid.ZIndex = 1
    dotGrid.Parent = self.canvas

    -- We'll use a UIGridLayout approach: small dots at regular intervals
    -- For performance, we create a few guide dots only
    for row = 0, 8 do
        for col = 0, 16 do
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 2, 0, 2)
            dot.Position = UDim2.new(col / 16, 0, row / 8, 0)
            dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            dot.BackgroundTransparency = 0.92
            dot.BorderSizePixel = 0
            dot.ZIndex = 1
            dot.Parent = dotGrid
        end
    end

    -- Center crosshair guides
    local crosshairContainer = createFrame({
        name = "Crosshair",
        size = UDim2.new(1, 0, 1, 0),
        zIndex = 2,
        parent = self.canvas,
    })

    -- Vertical center line
    local vLine = createFrame({
        size = UDim2.new(0, 1, 1, 0),
        position = UDim2.new(0.5, 0, 0, 0),
        color = Theme.Colors.EditorGridLine,
        transparency = 0,
        zIndex = 2,
        parent = crosshairContainer,
    })

    -- Horizontal center line
    local hLine = createFrame({
        size = UDim2.new(1, 0, 0, 1),
        position = UDim2.new(0, 0, 0.5, 0),
        color = Theme.Colors.EditorGridLine,
        transparency = 0,
        zIndex = 2,
        parent = crosshairContainer,
    })

    -- Direction labels
    createLabel({
        size = UDim2.new(0, 30, 0, 14),
        position = UDim2.new(1, -36, 0, 6),
        text = "UP",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Ultra,
        font = Theme.Font.FamilyBold,
        xAlign = Enum.TextXAlignment.Right,
        zIndex = 2,
        parent = crosshairContainer,
    })
    createLabel({
        size = UDim2.new(0, 50, 0, 14),
        position = UDim2.new(1, -56, 1, -20),
        text = "DOWN",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Ultra,
        font = Theme.Font.FamilyBold,
        xAlign = Enum.TextXAlignment.Right,
        zIndex = 2,
        parent = crosshairContainer,
    })
    createLabel({
        size = UDim2.new(0, 16, 0, 14),
        position = UDim2.new(0, 6, 0.5, -7),
        text = "L",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Ultra,
        font = Theme.Font.FamilyBold,
        zIndex = 2,
        parent = crosshairContainer,
    })
    createLabel({
        size = UDim2.new(0, 16, 0, 14),
        position = UDim2.new(1, -22, 0.5, -7),
        text = "R",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Ultra,
        font = Theme.Font.FamilyBold,
        zIndex = 2,
        parent = crosshairContainer,
    })

    -- Onion skin layer (above crosshair, below beams)
    self.onionSkinLayer = createFrame({
        name = "OnionSkinLayer",
        size = UDim2.new(1, 0, 1, 0),
        zIndex = 3,
        parent = self.canvas,
    })

    -- Beam layer
    self.beamLayer = createFrame({
        name = "BeamLayer",
        size = UDim2.new(1, 0, 1, 0),
        zIndex = 5,
        parent = self.canvas,
    })

    -- Canvas click to deselect
    table.insert(self.connections, self.canvas.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not self.store.editorIsPlaying then
                self.store:deselectAllEditorBeams()
            end
        end
    end))
end

function EffectPanel:_buildPropertiesPanel()
    local pp = self.propertiesPanel

    -- Properties header
    local header = createFrame({
        name = "PropsHeader",
        size = UDim2.new(1, 0, 0, 56),
        color = Color3.new(1, 1, 1),
        parent = pp,
    })
    createLabel({
        name = "PropsTitle",
        size = UDim2.new(1, -24, 1, 0),
        position = UDim2.new(0, Theme.Spacing.LG, 0, 0),
        text = "Properties",
        textColor = Theme.Colors.TextSecondary,
        textSize = Theme.FontSize.Small,
        font = Theme.Font.FamilySemibold,
        zIndex = 3,
        parent = header,
    })
    self.propsSelectionLabel = createLabel({
        name = "PropsSelectionCount",
        size = UDim2.new(0, 60, 1, 0),
        position = UDim2.new(1, -80, 0, 0),
        text = "",
        textColor = Theme.Colors.TextSubtle,
        textSize = Theme.FontSize.Tiny,
        font = Theme.Font.FamilyMedium,
        xAlign = Enum.TextXAlignment.Right,
        zIndex = 3,
        parent = header,
    })
    createDivider({
        size = UDim2.new(1, 0, 0, 1),
        position = UDim2.new(0, 0, 1, 0),
        anchorPoint = Vector2.new(0, 1),
        parent = header,
    })

    -- Properties content (scrollable)
    local propsScroll = Instance.new("ScrollingFrame")
    propsScroll.Name = "PropsScroll"
    propsScroll.Size = UDim2.new(1, 0, 1, -56)
    propsScroll.BackgroundTransparency = 1
    propsScroll.BorderSizePixel = 0
    propsScroll.ScrollBarThickness = 0
    propsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    propsScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    propsScroll.ScrollBarBehavior = Enum.ScrollBarBehavior.Never
    propsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    propsScroll.ZIndex = 2
    propsScroll.Parent = pp

    local propsContent = createFrame({
        name = "PropsContent",
        size = UDim2.new(1, -Theme.Scrollbar.Width - 4, 1, 0),
        parent = propsScroll,
    })
    local propsLayout = Instance.new("UIListLayout")
    propsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    propsLayout.Padding = UDim.new(0, Theme.Spacing.LG)
    propsLayout.Parent = propsContent

    local propsPad = Instance.new("UIPadding")
    propsPad.PaddingLeft = UDim.new(0, Theme.Spacing.LG)
    propsPad.PaddingRight = UDim.new(0, Theme.Spacing.LG)
    propsPad.PaddingTop = UDim.new(0, Theme.Spacing.LG)
    propsPad.PaddingBottom = UDim.new(0, Theme.Spacing.LG)
    propsPad.Parent = propsContent

    self.propsContent = propsContent

    -- "No selection" placeholder
    self.propsEmptyLabel = createLabel({
        name = "PropsEmpty",
        size = UDim2.new(1, 0, 0, 100),
        text = "Select a beam to\nedit its properties",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.FamilyLight,
        xAlign = Enum.TextXAlignment.Center,
        zIndex = 3,
        parent = propsContent,
    })

    -- Active properties container (hidden until selection)
    self.propsActive = createFrame({
        name = "PropsActive",
        size = UDim2.new(1, 0, 0, 800),
        parent = propsContent,
    })
    self.propsActive.Visible = false

    self:_buildActiveProperties()
end

function EffectPanel:_buildActiveProperties()
    local ap = self.propsActive
    local store = self.store
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, Theme.Spacing.LG)
    layout.Parent = ap

    -- Apply to all frames checkbox
    local applyAllFrame = createFrame({
        name = "ApplyAllFrame",
        size = UDim2.new(1, 0, 0, 32),
        zIndex = 3,
        parent = ap,
    })
    self.applyAllCheckBg = createFrame({
        name = "CheckBox",
        size = UDim2.new(0, 28, 0, 28),
        position = UDim2.new(0, 0, 0, 0),
        color = Theme.Colors.ToggleOffBorder,
        transparency = 0,
        corner = Theme.CornerRadius.SM,
        zIndex = 4,
        parent = applyAllFrame,
    })
    self.applyAllCheckMark = createLabel({
        name = "CheckMark",
        size = UDim2.new(1, 0, 1, 0),
        text = "v",
        textColor = Color3.new(0, 0, 0),
        textSize = 18,
        font = Theme.Font.FamilyBold,
        xAlign = Enum.TextXAlignment.Center,
        textTransparency = 1,
        zIndex = 5,
        parent = self.applyAllCheckBg,
    })
    createLabel({
        name = "ApplyAllLabel",
        size = UDim2.new(1, -40, 1, 0),
        position = UDim2.new(0, 36, 0, 0),
        text = "Apply to all frames",
        textColor = Theme.Colors.TextBody,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.FamilyMedium,
        zIndex = 3,
        parent = applyAllFrame,
    })
    table.insert(self.connections, applyAllFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            store:toggleEditorApplyToAll()
        end
    end))

    -- Divider
    createDivider({ name = "Div1", size = UDim2.new(1, 0, 0, 1), parent = ap })

    -- Color section header
    createLabel({
        name = "ColorLabel",
        size = UDim2.new(1, 0, 0, 20),
        text = "COLOR",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Tiny,
        font = Theme.Font.FamilySemibold,
        zIndex = 3,
        parent = ap,
    })

    -- Color wheel
    self.colorWheelContainer = createFrame({
        name = "ColorWheelContainer",
        size = UDim2.new(1, 0, 0, 200),
        zIndex = 3,
        parent = ap,
    })

    -- Divider
    createDivider({ name = "Div2", size = UDim2.new(1, 0, 0, 1), parent = ap })

    -- Iris slider
    self.irisSliderFrame = createFrame({
        name = "IrisSlider",
        size = UDim2.new(1, 0, 0, 60),
        zIndex = 3,
        parent = ap,
    })
    createLabel({
        name = "IrisLabel",
        size = UDim2.new(0.5, 0, 0, 20),
        text = "Iris",
        textColor = Theme.Colors.TextBody,
        textSize = Theme.FontSize.Label,
        zIndex = 4,
        parent = self.irisSliderFrame,
    })
    self.irisValue = createLabel({
        name = "IrisValue",
        size = UDim2.new(0.5, 0, 0, 20),
        position = UDim2.new(0.5, 0, 0, 0),
        text = "0",
        textColor = Theme.Colors.TextSecondary,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.Mono,
        xAlign = Enum.TextXAlignment.Right,
        zIndex = 4,
        parent = self.irisSliderFrame,
    })
    self.irisSliderTrack = createFrame({
        name = "IrisTrack",
        size = UDim2.new(1, 0, 0, 8),
        position = UDim2.new(0, 0, 1, -16),
        anchorPoint = Vector2.new(0, 1),
        color = Color3.fromRGB(38, 38, 38),
        transparency = 0,
        corner = UDim.new(1, 0),
        zIndex = 4,
        parent = self.irisSliderFrame,
    })
    self.irisSliderFill = createFrame({
        name = "IrisFill",
        size = UDim2.new(1, 0, 1, 0),
        color = Color3.new(1, 1, 1),
        transparency = 0,
        corner = UDim.new(1, 0),
        zIndex = 5,
        parent = self.irisSliderTrack,
    })
    self.irisSliderThumb = createFrame({
        name = "IrisThumb",
        size = UDim2.new(0, 24, 0, 24),
        position = UDim2.new(1, -12, 0, -8),
        anchorPoint = Vector2.new(1, 0.5),
        color = Color3.new(1, 1, 1),
        transparency = 0,
        corner = UDim.new(1, 0),
        zIndex = 6,
        parent = self.irisSliderFrame,
    })
    self:_setupSliderDrag(self.irisSliderFrame, function(val)
        store:updateEditorBeam(self._sliderBeamIndex or 1, { iris = val * 255 })
    end)

    -- Dimmer slider
    self.dimmerSliderFrame = createFrame({
        name = "DimmerSlider",
        size = UDim2.new(1, 0, 0, 60),
        zIndex = 3,
        parent = ap,
    })
    createLabel({
        name = "DimmerLabel",
        size = UDim2.new(0.5, 0, 0, 20),
        text = "Dimmer",
        textColor = Theme.Colors.TextBody,
        textSize = Theme.FontSize.Label,
        zIndex = 4,
        parent = self.dimmerSliderFrame,
    })
    self.dimmerValue = createLabel({
        name = "DimmerValue",
        size = UDim2.new(0.5, 0, 0, 20),
        position = UDim2.new(0.5, 0, 0, 0),
        text = "0",
        textColor = Theme.Colors.TextSecondary,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.Mono,
        xAlign = Enum.TextXAlignment.Right,
        zIndex = 4,
        parent = self.dimmerSliderFrame,
    })
    self.dimmerSliderTrack = createFrame({
        name = "DimmerTrack",
        size = UDim2.new(1, 0, 0, 8),
        position = UDim2.new(0, 0, 1, -16),
        anchorPoint = Vector2.new(0, 1),
        color = Color3.fromRGB(38, 38, 38),
        transparency = 0,
        corner = UDim.new(1, 0),
        zIndex = 4,
        parent = self.dimmerSliderFrame,
    })
    self.dimmerSliderFill = createFrame({
        name = "DimmerFill",
        size = UDim2.new(1, 0, 1, 0),
        color = Color3.new(1, 1, 1),
        transparency = 0,
        corner = UDim.new(1, 0),
        zIndex = 5,
        parent = self.dimmerSliderTrack,
    })
    self.dimmerSliderThumb = createFrame({
        name = "DimmerThumb",
        size = UDim2.new(0, 24, 0, 24),
        position = UDim2.new(1, -12, 0, -8),
        anchorPoint = Vector2.new(1, 0.5),
        color = Color3.new(1, 1, 1),
        transparency = 0,
        corner = UDim.new(1, 0),
        zIndex = 6,
        parent = self.dimmerSliderFrame,
    })
    self:_setupSliderDrag(self.dimmerSliderFrame, function(val)
        store:updateEditorBeam(self._sliderBeamIndex or 1, { dimmer = val * 255 })
    end)

    -- Divider
    createDivider({ name = "Div3", size = UDim2.new(1, 0, 0, 1), parent = ap })

    -- Position read-only
    createLabel({
        name = "PositionLabel",
        size = UDim2.new(1, 0, 0, 20),
        text = "POSITION (CANVAS)",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Tiny,
        font = Theme.Font.FamilySemibold,
        zIndex = 3,
        parent = ap,
    })

    local posFrame = createFrame({
        name = "PositionDisplay",
        size = UDim2.new(1, 0, 0, 48),
        zIndex = 3,
        parent = ap,
    })
    createLabel({
        name = "XLabel",
        size = UDim2.new(0, 20, 0, 16),
        text = "X",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Tiny,
        zIndex = 4,
        parent = posFrame,
    })
    self.posXValue = createLabel({
        name = "XValue",
        size = UDim2.new(0, 120, 0, 24),
        position = UDim2.new(0, 24, 0, 0),
        text = "50.0%",
        textColor = Theme.Colors.TextSecondary,
        textSize = Theme.FontSize.Small,
        font = Theme.Font.Mono,
        zIndex = 4,
        parent = posFrame,
    })
    createLabel({
        name = "YLabel",
        size = UDim2.new(0, 20, 0, 16),
        position = UDim2.new(0, 160, 0, 0),
        text = "Y",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Tiny,
        zIndex = 4,
        parent = posFrame,
    })
    self.posYValue = createLabel({
        name = "YValue",
        size = UDim2.new(0, 120, 0, 24),
        position = UDim2.new(0, 184, 0, 0),
        text = "50.0%",
        textColor = Theme.Colors.TextSecondary,
        textSize = Theme.FontSize.Small,
        font = Theme.Font.Mono,
        zIndex = 4,
        parent = posFrame,
    })

    -- Divider
    createDivider({ name = "Div4", size = UDim2.new(1, 0, 0, 1), parent = ap })

    -- Visible toggle
    local visFrame = createFrame({
        name = "VisibleFrame",
        size = UDim2.new(1, 0, 0, 40),
        zIndex = 3,
        parent = ap,
    })
    createLabel({
        name = "VisibleLabel",
        size = UDim2.new(0.6, 0, 1, 0),
        text = "Visible",
        textColor = Theme.Colors.TextBody,
        textSize = Theme.FontSize.Label,
        zIndex = 4,
        parent = visFrame,
    })
    self.visibleToggle = createButton({
        name = "VisibleToggle",
        size = UDim2.new(0, 80, 0, 34),
        position = UDim2.new(1, -80, 0, 3),
        text = "ON",
        textColor = Theme.Colors.TextPrimary,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.FamilyBold,
        color = Theme.Colors.ButtonActive,
        transparency = 0.5,
        corner = Theme.CornerRadius.MD,
        zIndex = 6,
        parent = visFrame,
    })
    createStroke({ color = Theme.Colors.BorderHover, parent = self.visibleToggle })
    table.insert(self.connections, self.visibleToggle.Activated:Connect(function()
        local first = self:_getFirstSelectedBeam()
        if first then
            store:updateEditorBeam(first.id, { visible = not first.visible })
        end
    end))
end

function EffectPanel:_getFirstSelectedBeam()
    local store = self.store
    if #store.editorSelectedBeams == 0 then return nil end
    local frame = store:getEditorCurrentFrame()
    if not frame then return nil end
    return frame[store.editorSelectedBeams[1]]
end

function EffectPanel:_setupSliderDrag(trackFrame, onChange)
    local isDragging = false
    local sliderValue = 0

    local function getValueFromInput(input)
        local absX = input.Position.X
        local trackAbsX = trackFrame.AbsolutePosition.X
        local trackWidth = trackFrame.AbsoluteSize.X
        if trackWidth <= 0 then return sliderValue end
        local localX = absX - trackAbsX
        local pct = math.clamp(localX / trackWidth, 0, 1)
        sliderValue = pct
        if onChange then onChange(pct) end
    end

    table.insert(self.connections, trackFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            getValueFromInput(input)
        end
    end))
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            isDragging = false
        end
    end))
end

function EffectPanel:_buildTimeline()
    local tl = self.timelineArea

    -- Playback controls
    local playbackFrame = createFrame({
        name = "PlaybackControls",
        size = UDim2.new(1, 0, 0, 48),
        parent = tl,
    })

    local btnS = 32
    local gap = 6
    local x = Theme.Spacing.MD

    local function playBtn(icon, label, xPos, active, callback)
        local b = createButton({
            name = label,
            size = UDim2.new(0, btnS, 0, btnS),
            position = UDim2.new(0, xPos, 0.5, -btnS / 2),
            text = icon,
            textColor = Theme.Colors.TextBody,
            textSize = Theme.FontSize.Label,
            font = Theme.Font.FamilyBold,
            corner = Theme.CornerRadius.LG,
            zIndex = 6,
            parent = playbackFrame,
        })
        createStroke({ color = Theme.Colors.BorderDefault, transparency = 0.7, parent = b })
        if callback then
            table.insert(self.connections, b.Activated:Connect(callback))
        end
        return b
    end

    self.playPauseBtn = playBtn(">", "PlayPause", x, false, function()
        if self.store.editorIsPlaying then
            self.store:setEditorPlaying(false)
        else
            self.store:setEditorPlaying(true)
        end
    end)
    x = x + btnS + gap

    playBtn("[]", "Stop", x, false, function()
        self.store:setEditorPlaying(false)
        self.store:setEditorCurrentFrameIndex(1)
    end)
    x = x + btnS + gap

    -- Divider
    createFrame({
        size = UDim2.new(0, 1, 0, 20),
        position = UDim2.new(0, x, 0.5, -10),
        color = Theme.Colors.BorderDivider,
        parent = playbackFrame,
    })
    x = x + 8

    -- Speed controls
    playBtn("<", "SpeedDown", x, false, function()
        self.store:setEditorSpeed(self.store.editorSpeed - 0.25)
    end)
    x = x + btnS + gap

    self.speedLabel = createLabel({
        name = "SpeedDisplay",
        size = UDim2.new(0, 80, 0, 24),
        position = UDim2.new(0, x, 0.5, -12),
        text = "1.00x",
        textColor = Theme.Colors.TextBody,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.Mono,
        xAlign = Enum.TextXAlignment.Center,
        zIndex = 3,
        parent = playbackFrame,
    })
    x = x + 80 + gap

    playBtn(">", "SpeedUp", x, false, function()
        self.store:setEditorSpeed(self.store.editorSpeed + 0.25)
    end)
    x = x + btnS + gap

    -- Divider
    createFrame({
        size = UDim2.new(0, 1, 0, 20),
        position = UDim2.new(0, x, 0.5, -10),
        color = Theme.Colors.BorderDivider,
        parent = playbackFrame,
    })
    x = x + 8

    -- Loop toggle
    self.loopBtn = playBtn("Loop", "Loop", x, false, function()
        self.store:toggleEditorLoop()
    end)
    x = x + 56 + gap

    -- Onion toggle
    self.onionBtn = playBtn("Onion", "Onion", x, false, function()
        self.store:toggleEditorOnionSkin()
    end)
    x = x + 60 + gap

    -- Frame counter
    self.frameCounter = createLabel({
        name = "FrameCounter",
        size = UDim2.new(0, 120, 0, 24),
        position = UDim2.new(1, -(Theme.Spacing.MD), 0.5, -12),
        text = "F1/24",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.Mono,
        xAlign = Enum.TextXAlignment.Right,
        zIndex = 3,
        parent = playbackFrame,
    })

    -- Beam strip
    self.beamStrip = createFrame({
        name = "BeamStrip",
        size = UDim2.new(1, 0, 0, 56),
        position = UDim2.new(0, 0, 0, 52),
        parent = tl,
    })

    local stripLabel = createLabel({
        name = "BeamLabel",
        size = UDim2.new(0, 60, 0, 48),
        position = UDim2.new(0, Theme.Spacing.MD, 0, 4),
        text = "BEAM",
        textColor = Theme.Colors.TextVerySubtle,
        textSize = Theme.FontSize.Micro,
        font = Theme.Font.FamilyBold,
        zIndex = 3,
        parent = self.beamStrip,
    })

    -- Frame strip (scrollable)
    self.frameStripScroll = Instance.new("ScrollingFrame")
    self.frameStripScroll.Name = "FrameStripScroll"
    self.frameStripScroll.Size = UDim2.new(1, 0, 0, 88)
    self.frameStripScroll.Position = UDim2.new(0, 0, 1, -92)
    self.frameStripScroll.BackgroundTransparency = 1
    self.frameStripScroll.BorderSizePixel = 0
    self.frameStripScroll.ScrollBarThickness = 0
    self.frameStripScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    self.frameStripScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    self.frameStripScroll.ScrollBarBehavior = Enum.ScrollBarBehavior.Never
    self.frameStripScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.frameStripScroll.ZIndex = 3
    self.frameStripScroll.Parent = tl

    self.frameStrip = createFrame({
        name = "FrameStrip",
        size = UDim2.new(1, 0, 1, 0),
        parent = self.frameStripScroll,
    })

    local stripLayout = Instance.new("UIListLayout")
    stripLayout.SortOrder = Enum.SortOrder.LayoutOrder
    stripLayout.FillDirection = Enum.FillDirection.Horizontal
    stripLayout.Padding = UDim.new(0, Theme.Spacing.SM)
    stripLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    stripLayout.Parent = self.frameStrip

    local stripPad = Instance.new("UIPadding")
    stripPad.PaddingLeft = UDim.new(0, Theme.Spacing.MD)
    stripPad.PaddingRight = UDim.new(0, Theme.Spacing.MD)
    stripPad.PaddingTop = UDim.new(0, 4)
    stripPad.PaddingBottom = UDim.new(0, 4)
    stripPad.Parent = self.frameStrip
end

--------------------------------------------------------------------------------
-- SAVE DIALOG
--------------------------------------------------------------------------------

function EffectPanel:_buildSaveDialog()
    local modalWidth = 760
    local modalHeight = 560

    -- Backdrop
    self.saveBackdrop = createFrame({
        name = "SaveBackdrop",
        size = UDim2.new(1, 0, 1, 0),
        color = Color3.new(0, 0, 0),
        transparency = 0.4,
        zIndex = Theme.ZIndex.ModalOverlay,
        parent = self.frame,
    })
    self.saveBackdrop.Visible = false

    local backdropBtn = Instance.new("TextButton")
    backdropBtn.Name = "BackdropBtn"
    backdropBtn.Size = UDim2.new(1, 0, 1, 0)
    backdropBtn.BackgroundTransparency = 1
    backdropBtn.Text = ""
    backdropBtn.AutoButtonColor = false
    backdropBtn.ZIndex = Theme.ZIndex.ModalOverlay + 1
    backdropBtn.Parent = self.saveBackdrop
    table.insert(self.connections, backdropBtn.Activated:Connect(function()
        self.store:setEditorSaveDialogOpen(false)
    end))

    -- Modal container
    self.saveModal = createFrame({
        name = "SaveModal",
        size = UDim2.new(0, modalWidth, 0, modalHeight),
        position = UDim2.new(0.5, 0, 0.5, 0),
        anchorPoint = Vector2.new(0.5, 0.5),
        color = Color3.fromRGB(10, 10, 10),
        transparency = 0.05,
        corner = Theme.CornerRadius.XL,
        zIndex = Theme.ZIndex.Modal,
        parent = self.frame,
    })
    self.saveModal.Visible = false
    createStroke({ color = Theme.Colors.BorderDefault, transparency = 0.4, parent = self.saveModal })

    -- Header
    local header = createFrame({
        name = "SaveHeader",
        size = UDim2.new(1, 0, 0, 64),
        zIndex = 3,
        parent = self.saveModal,
    })
    createLabel({
        name = "SaveTitle",
        size = UDim2.new(1, -60, 1, 0),
        position = UDim2.new(0, Theme.Spacing.XL, 0, 0),
        text = "Save Effect",
        textColor = Theme.Colors.TextPrimary,
        textSize = Theme.FontSize.CardTitle,
        font = Theme.Font.FamilySemibold,
        zIndex = 4,
        parent = header,
    })
    local closeBtn = createButton({
        name = "CloseBtn",
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -48, 0.5, -20),
        text = "x",
        textColor = Theme.Colors.TextMuted,
        textSize = Theme.FontSize.Large,
        zIndex = 6,
        parent = header,
    })
    table.insert(self.connections, closeBtn.Activated:Connect(function()
        self.store:setEditorSaveDialogOpen(false)
    end))
    createDivider({ parent = header })

    -- Content
    local content = createFrame({
        name = "SaveContent",
        size = UDim2.new(1, 0, 1, -64),
        position = UDim2.new(0, 0, 0, 64),
        parent = self.saveModal,
    })
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, Theme.Spacing.LG)
    contentLayout.Parent = content
    local contentPad = Instance.new("UIPadding")
    contentPad.PaddingLeft = UDim.new(0, Theme.Spacing.XL)
    contentPad.PaddingRight = UDim.new(0, Theme.Spacing.XL)
    contentPad.PaddingTop = UDim.new(0, Theme.Spacing.LG)
    contentPad.PaddingBottom = UDim.new(0, Theme.Spacing.LG)
    contentPad.Parent = content

    -- Name input
    createLabel({
        name = "NameLabel",
        size = UDim2.new(1, 0, 0, 20),
        text = "NAME",
        textColor = Theme.Colors.TextSubtle,
        textSize = Theme.FontSize.Tiny,
        font = Theme.Font.FamilySemibold,
        zIndex = 3,
        parent = content,
    })
    self.saveNameInput = createInput({
        name = "SaveNameInput",
        size = UDim2.new(1, 0, 0, 48),
        placeholder = "Effect name...",
        zIndex = 20,
        parent = content,
    })
    -- Easter egg: "42" and "blur"
    table.insert(self.connections, self.saveNameInput:GetPropertyChangedSignal("Text"):Connect(function()
        local val = self.saveNameInput.Text
        self.store:setEditorSaveName(val)
        -- Easter egg: 42
        if val:match("^42$") and not self.name42Triggered then
            self.name42Triggered = true
            self.store:addToast("The answer to everything, apparently", "success")
        end
        if not val:match("^42$") then
            self.name42Triggered = false
        end
        -- Easter egg: blur -> glow
        if val:lower():find("blur") then
            if not self.saveGlowActive then
                self.saveGlowActive = true
                self:_triggerSaveGlow()
            end
        else
            self.saveGlowActive = false
        end
    end))

    -- Type selector
    createLabel({
        name = "TypeLabel",
        size = UDim2.new(1, 0, 0, 20),
        text = "TYPE",
        textColor = Theme.Colors.TextSubtle,
        textSize = Theme.FontSize.Tiny,
        font = Theme.Font.FamilySemibold,
        zIndex = 3,
        parent = content,
    })

    local typeRow = createFrame({
        name = "TypeRow",
        size = UDim2.new(1, 0, 0, 44),
        zIndex = 3,
        parent = content,
    })
    local typeLayout = Instance.new("UIListLayout")
    typeLayout.SortOrder = Enum.SortOrder.LayoutOrder
    typeLayout.FillDirection = Enum.FillDirection.Horizontal
    typeLayout.Padding = UDim.new(0, 8)
    typeLayout.Parent = typeRow

    self.typeButtons = {}
    for i, t in ipairs(EFFECT_TYPES) do
        local tb = createButton({
            name = "Type_" .. t.value,
            size = UDim2.new(0, 100, 0, 36),
            text = t.label,
            textColor = Theme.Colors.TextSubtle,
            textSize = Theme.FontSize.Label,
            font = Theme.Font.FamilyMedium,
            corner = Theme.CornerRadius.MD,
            padding = { 12, 12, 6, 6 },
            zIndex = 6,
            parent = typeRow,
        })
        createStroke({ color = Theme.Colors.BorderDefault, transparency = 0.6, parent = tb })
        table.insert(self.connections, tb.Activated:Connect(function()
            self.store:setEditorSaveType(t.value)
            self:_refreshSaveDialogTypes()
        end))
        self.typeButtons[t.value] = tb
    end

    -- Tags input
    createLabel({
        name = "TagsLabel",
        size = UDim2.new(1, 0, 0, 20),
        text = "TAGS",
        textColor = Theme.Colors.TextSubtle,
        textSize = Theme.FontSize.Tiny,
        font = Theme.Font.FamilySemibold,
        zIndex = 3,
        parent = content,
    })
    self.tagInput = createInput({
        name = "TagInput",
        size = UDim2.new(1, 0, 0, 48),
        placeholder = "Type and press Enter...",
        zIndex = 20,
        parent = content,
    })
    table.insert(self.connections, self.tagInput.FocusLost:Connect(function()
        self:_handleTagSubmit()
    end))
    -- Handle Enter key for tag input
    table.insert(self.connections, self.tagInput:GetPropertyChangedSignal("Text"):Connect(function()
        -- Detect enter via checking if we have input focus
    end))

    -- Tags display area
    self.tagsDisplay = createFrame({
        name = "TagsDisplay",
        size = UDim2.new(1, 0, 0, 36),
        zIndex = 3,
        parent = content,
    })

    -- Save buttons
    local btnRow = createFrame({
        name = "SaveBtnRow",
        size = UDim2.new(1, 0, 0, 56),
        zIndex = 3,
        parent = content,
    })
    local btnLayout = Instance.new("UIListLayout")
    btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.Padding = UDim.new(0, Theme.Spacing.SM)
    btnLayout.Parent = btnRow

    self.saveLocalBtn = createButton({
        name = "SaveLocalBtn",
        size = UDim2.new(0.5, -6, 0, 56),
        text = "Save Local",
        textColor = Theme.Colors.ButtonPrimaryText,
        textSize = Theme.FontSize.Small,
        font = Theme.Font.FamilySemibold,
        color = Theme.Colors.ButtonPrimary,
        transparency = 0,
        corner = Theme.CornerRadius.LG,
        padding = { 24, 24, 12, 12 },
        zIndex = 6,
        parent = btnRow,
    })
    self:_addHoverEffect(self.saveLocalBtn, Theme.Colors.ButtonPrimaryHover, Theme.Colors.ButtonPrimaryText)
    table.insert(self.connections, self.saveLocalBtn.Activated:Connect(function()
        local name = self.store.editorSaveName
        if #name < 2 or #name > 30 then
            self.store:addToast("Effect name must be 2-30 characters", "warning")
            return
        end
        self.store:saveEditorEffect()
        self.store:addToast("Effect saved locally", "success")
    end))

    local saveHubBtn = createButton({
        name = "SaveHubBtn",
        size = UDim2.new(0.5, -6, 0, 56),
        text = "Save to Hub",
        textColor = Theme.Colors.ButtonSecondaryText,
        textSize = Theme.FontSize.Small,
        font = Theme.Font.FamilyMedium,
        color = Theme.Colors.SurfaceActive,
        transparency = 0.5,
        corner = Theme.CornerRadius.LG,
        padding = { 24, 24, 12, 12 },
        zIndex = 6,
        parent = btnRow,
    })
    createStroke({ color = Theme.Colors.BorderHover, parent = saveHubBtn })
    self:_addHoverEffect(saveHubBtn, Theme.Colors.SurfaceHover, Theme.Colors.ButtonSecondaryText)
    table.insert(self.connections, saveHubBtn.Activated:Connect(function()
        self.store:setEditorSaveDialogOpen(false)
        self.store:addToast("Hub feature coming soon", "warning")
    end))
end

function EffectPanel:_handleTagSubmit()
    local tag = self.tagInput.Text
    if tag and #tag > 0 then
        local tags = deepCopy(self.store.editorSaveTags)
        table.insert(tags, tag)
        self.store:setEditorSaveTags(tags)
        self.tagInput.Text = ""
        self:_refreshSaveTags()
    end
end

function EffectPanel:_refreshSaveTags()
    -- Clear existing
    for _, child in ipairs(self.tagsDisplay:GetChildren()) do
        child:Destroy()
    end

    local tags = self.store.editorSaveTags
    local xOff = 0
    for _, tag in ipairs(tags) do
        local tagBg = createFrame({
            name = "Tag_" .. tag,
            size = UDim2.new(0, 80, 0, 28),
            position = UDim2.new(0, xOff, 0, 0),
            color = Theme.Colors.SurfaceActive,
            transparency = 0.4,
            corner = Theme.CornerRadius.MD,
            zIndex = 3,
            parent = self.tagsDisplay,
        })
        createLabel({
            size = UDim2.new(1, -28, 1, 0),
            position = UDim2.new(0, 8, 0, 0),
            text = tag,
            textColor = Theme.Colors.TextBody,
            textSize = Theme.FontSize.Tiny,
            zIndex = 4,
            parent = tagBg,
        })
        local removeBtn = createButton({
            name = "RemoveTag",
            size = UDim2.new(0, 24, 0, 24),
            position = UDim2.new(1, -24, 0, 2),
            text = "x",
            textColor = Theme.Colors.TextSubtle,
            textSize = Theme.FontSize.Micro,
            zIndex = 6,
            parent = tagBg,
        })
        local capturedTag = tag
        table.insert(self.connections, removeBtn.Activated:Connect(function()
            local newTags = deepCopy(self.store.editorSaveTags)
            for i, t in ipairs(newTags) do
                if t == capturedTag then
                    table.remove(newTags, i)
                    break
                end
            end
            self.store:setEditorSaveTags(newTags)
            self:_refreshSaveTags()
        end))
        xOff = xOff + 88
    end
end

function EffectPanel:_refreshSaveDialogTypes()
    local currentType = self.store.editorSaveType
    for tValue, btn in pairs(self.typeButtons) do
        if tValue == currentType then
            btn.BackgroundColor3 = Theme.Colors.SurfaceActive
            btn.BackgroundTransparency = 0.5
            btn.TextColor3 = Theme.Colors.TextPrimary
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = Theme.Colors.BorderHover
                stroke.Transparency = 0.3
            end
        else
            btn.BackgroundColor3 = Color3.new(1, 1, 1)
            btn.BackgroundTransparency = 1
            btn.TextColor3 = Theme.Colors.TextSubtle
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = Theme.Colors.BorderDefault
                stroke.Transparency = 0.6
            end
        end
    end
end

function EffectPanel:_triggerSaveGlow()
    if self.blurGlowTween then self.blurGlowTween:Cancel() end
    self.blurGlowTween = TweenService:Create(self.saveLocalBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = Color3.new(1, 1, 1),
    })
    self.blurGlowTween:Play()
    self.blurGlowTween.Completed:Connect(function()
        -- Create glow effect using size pulse
        local glow = TweenService:Create(self.saveLocalBtn, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0), {
            BackgroundTransparency = 0,
        })
        glow:Play()
        wait(0.8)
        if self.saveGlowActive then
            self:_triggerSaveGlow()
        end
    end)
end

function EffectPanel:_openSaveDialog()
    self.saveBackdrop.Visible = true
    self.saveModal.Visible = true
    self.saveNameInput.Text = self.store.editorSaveName or ""
    self:_refreshSaveDialogTypes()
    self:_refreshSaveTags()
    self.saveGlowActive = false
    self.name42Triggered = false

    -- Fade in
    self.saveBackdrop.BackgroundTransparency = 1
    TweenService:Create(self.saveBackdrop, TweenInfo.new(Theme.Animation.ModalFadeIn), {
        BackgroundTransparency = 0.6,
    }):Play()

    self.saveModal.BackgroundTransparency = 0.3
    self.saveModal.Size = UDim2.new(0, 760 * 0.9, 0, 560 * 0.9)
    TweenService:Create(self.saveModal, TweenInfo.new(Theme.Animation.ModalScaleIn, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.05,
        Size = UDim2.new(0, 760, 0, 560),
    }):Play()
end

function EffectPanel:_closeSaveDialog()
    self.saveGlowActive = false
    if self.blurGlowTween then self.blurGlowTween:Cancel() end

    TweenService:Create(self.saveBackdrop, TweenInfo.new(Theme.Animation.ModalFadeOut), {
        BackgroundTransparency = 1,
    }):Play()
    TweenService:Create(self.saveModal, TweenInfo.new(Theme.Animation.ModalScaleOut, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 0.3,
        Size = UDim2.new(0, 760 * 0.9, 0, 560 * 0.9),
    }):Play()

    spawn(function()
        wait(Theme.Animation.ModalFadeOut)
        self.saveBackdrop.Visible = false
        self.saveModal.Visible = false
    end)
end

--------------------------------------------------------------------------------
-- PRESET BROWSER
--------------------------------------------------------------------------------

function EffectPanel:_buildPresetBrowser()
    local modalWidth = 1160
    local modalHeight = 800

    -- Backdrop
    self.presetBackdrop = createFrame({
        name = "PresetBackdrop",
        size = UDim2.new(1, 0, 1, 0),
        color = Color3.new(0, 0, 0),
        transparency = 0.4,
        zIndex = Theme.ZIndex.ModalOverlay,
        parent = self.frame,
    })
    self.presetBackdrop.Visible = false

    local pbBackdropBtn = Instance.new("TextButton")
    pbBackdropBtn.Size = UDim2.new(1, 0, 1, 0)
    pbBackdropBtn.BackgroundTransparency = 1
    pbBackdropBtn.Text = ""
    pbBackdropBtn.AutoButtonColor = false
    pbBackdropBtn.ZIndex = Theme.ZIndex.ModalOverlay + 1
    pbBackdropBtn.Parent = self.presetBackdrop
    table.insert(self.connections, pbBackdropBtn.Activated:Connect(function()
        self.store:setEditorPresetBrowserOpen(false)
    end))

    -- Modal
    self.presetModal = createFrame({
        name = "PresetModal",
        size = UDim2.new(0, modalWidth, 0, modalHeight),
        position = UDim2.new(0.5, 0, 0.5, 0),
        anchorPoint = Vector2.new(0.5, 0.5),
        color = Color3.fromRGB(10, 10, 10),
        transparency = 0.05,
        corner = Theme.CornerRadius.XL,
        zIndex = Theme.ZIndex.Modal,
        parent = self.frame,
    })
    self.presetModal.Visible = false
    createStroke({ color = Theme.Colors.BorderDefault, transparency = 0.4, parent = self.presetModal })

    -- Header
    local header = createFrame({
        name = "PresetHeader",
        size = UDim2.new(1, 0, 0, 64),
        zIndex = 3,
        parent = self.presetModal,
    })
    createLabel({
        size = UDim2.new(1, -60, 1, 0),
        position = UDim2.new(0, Theme.Spacing.XL, 0, 0),
        text = "Browse Presets",
        textColor = Theme.Colors.TextPrimary,
        textSize = Theme.FontSize.CardTitle,
        font = Theme.Font.FamilySemibold,
        zIndex = 4,
        parent = header,
    })
    local pCloseBtn = createButton({
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -48, 0.5, -20),
        text = "x",
        textColor = Theme.Colors.TextMuted,
        textSize = Theme.FontSize.Large,
        zIndex = 6,
        parent = header,
    })
    table.insert(self.connections, pCloseBtn.Activated:Connect(function()
        self.store:setEditorPresetBrowserOpen(false)
    end))
    createDivider({ parent = header })

    -- Search + filter area
    local filterArea = createFrame({
        name = "FilterArea",
        size = UDim2.new(1, 0, 0, 88),
        position = UDim2.new(0, 0, 0, 64),
        zIndex = 3,
        parent = self.presetModal,
    })
    local filterLayout = Instance.new("UIListLayout")
    filterLayout.SortOrder = Enum.SortOrder.LayoutOrder
    filterLayout.Padding = UDim.new(0, Theme.Spacing.MD)
    filterLayout.Parent = filterArea
    local filterPad = Instance.new("UIPadding")
    filterPad.PaddingLeft = UDim.new(0, Theme.Spacing.XL)
    filterPad.PaddingRight = UDim.new(0, Theme.Spacing.XL)
    filterPad.PaddingTop = UDim.new(0, Theme.Spacing.MD)
    filterPad.Parent = filterArea

    self.presetSearchInput = createInput({
        name = "PresetSearch",
        size = UDim2.new(1, 0, 0, 44),
        placeholder = "Search presets...",
        zIndex = 20,
        parent = filterArea,
    })
    table.insert(self.connections, self.presetSearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        self.presetSearch = self.presetSearchInput.Text
        self:_refreshPresetGrid()
    end))

    -- Category filter buttons
    local catRow = createFrame({
        name = "CategoryRow",
        size = UDim2.new(1, 0, 0, 36),
        zIndex = 3,
        parent = filterArea,
    })
    local catLayout = Instance.new("UIListLayout")
    catLayout.SortOrder = Enum.SortOrder.LayoutOrder
    catLayout.FillDirection = Enum.FillDirection.Horizontal
    catLayout.Padding = UDim.new(0, 6)
    catLayout.Parent = catRow

    self.categoryButtons = {}
    for i, cat in ipairs(BROWSE_CATEGORIES) do
        local cb = createButton({
            name = "Cat_" .. cat.value,
            size = UDim2.new(0, 90, 0, 32),
            text = cat.label,
            textColor = Theme.Colors.TextSubtle,
            textSize = Theme.FontSize.Label,
            font = Theme.Font.FamilyMedium,
            corner = Theme.CornerRadius.MD,
            padding = { 12, 12, 4, 4 },
            zIndex = 6,
            parent = catRow,
        })
        createStroke({ color = Theme.Colors.BorderDefault, transparency = 0.6, parent = cb })
        table.insert(self.connections, cb.Activated:Connect(function()
            self.presetCategory = cat.value
            self:_refreshPresetCategories()
            self:_refreshPresetGrid()
            -- Easter egg: chase clicks
            if cat.value == "chase" then
                local now = tick()
                if now - self.chaseClicks.last < 2 then
                    self.chaseClicks.count = self.chaseClicks.count + 1
                else
                    self.chaseClicks.count = 1
                end
                self.chaseClicks.last = now
                if self.chaseClicks.count >= 3 then
                    self.store:addToast("You really like chasing, don't you?", "success")
                    self.chaseClicks.count = 0
                end
            end
        end))
        self.categoryButtons[cat.value] = cb
    end

    createDivider({ parent = filterArea })

    -- Preset grid (scrollable)
    self.presetGridScroll = Instance.new("ScrollingFrame")
    self.presetGridScroll.Name = "PresetGridScroll"
    self.presetGridScroll.Size = UDim2.new(1, 0, 1, -120)
    self.presetGridScroll.Position = UDim2.new(0, 0, 0, 160)
    self.presetGridScroll.BackgroundTransparency = 1
    self.presetGridScroll.BorderSizePixel = 0
    self.presetGridScroll.ScrollBarThickness = 0
    self.presetGridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.presetGridScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    self.presetGridScroll.ScrollBarBehavior = Enum.ScrollBarBehavior.Never
    self.presetGridScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.presetGridScroll.ZIndex = 3
    self.presetGridScroll.Parent = self.presetModal

    self.presetGridContent = createFrame({
        name = "PresetGridContent",
        size = UDim2.new(1, 0, 1, 0),
        parent = self.presetGridScroll,
    })

    -- Footer
    self.presetFooter = createFrame({
        name = "PresetFooter",
        size = UDim2.new(1, 0, 0, 52),
        position = UDim2.new(0, 0, 1, -52),
        zIndex = 3,
        parent = self.presetModal,
    })
    createDivider({
        size = UDim2.new(1, 0, 0, 1),
        position = UDim2.new(0, 0, 0, 0),
        parent = self.presetFooter,
    })
    self.presetCountLabel = createLabel({
        name = "PresetCount",
        size = UDim2.new(0.5, 0, 1, 0),
        position = UDim2.new(0, Theme.Spacing.XL, 0, 0),
        text = EffectPresets.getCount() .. " presets available",
        textColor = Theme.Colors.TextSubtle,
        textSize = Theme.FontSize.Label,
        zIndex = 3,
        parent = self.presetFooter,
    })
end

function EffectPanel:_refreshPresetCategories()
    local currentCat = self.presetCategory
    for catValue, btn in pairs(self.categoryButtons) do
        if catValue == currentCat then
            btn.BackgroundColor3 = Theme.Colors.SurfaceActive
            btn.BackgroundTransparency = 0.5
            btn.TextColor3 = Theme.Colors.TextPrimary
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = Theme.Colors.BorderHover
                stroke.Transparency = 0.3
            end
        else
            btn.BackgroundColor3 = Color3.new(1, 1, 1)
            btn.BackgroundTransparency = 1
            btn.TextColor3 = Theme.Colors.TextSubtle
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = Theme.Colors.BorderDefault
                stroke.Transparency = 0.6
            end
        end
    end
end

function EffectPanel:_refreshPresetGrid()
    -- Clear
    for _, child in ipairs(self.presetGridContent:GetChildren()) do
        child:Destroy()
    end

    local allPresets = EffectPresets.getAll()
    local filtered = {}

    -- Filter by category
    for _, preset in ipairs(allPresets) do
        local matchesCat = (self.presetCategory == "all") or (preset.category == self.presetCategory)
        local matchesSearch = (self.presetSearch == "") or preset.name:lower():find(self.presetSearch:lower(), 1, true)
        if matchesCat and matchesSearch then
            table.insert(filtered, preset)
        end
    end

    if self.presetCategory == "all" then
        -- Grouped by category
        local categories = EffectPresets.getCategories()
        for _, cat in ipairs(categories) do
            local catPresets = {}
            for _, preset in ipairs(filtered) do
                if preset.category == cat.id then
                    table.insert(catPresets, preset)
                end
            end
            if #catPresets > 0 then
                -- Category header
                createLabel({
                    name = "CatHeader_" .. cat.id,
                    size = UDim2.new(1, 0, 0, 28),
                    text = cat.name:upper(),
                    textColor = Theme.Colors.TextSubtle,
                    textSize = Theme.FontSize.Label,
                    font = Theme.Font.FamilySemibold,
                    zIndex = 3,
                    parent = self.presetGridContent,
                })
                -- Preset cards in 3-column grid
                local catGrid = createFrame({
                    name = "CatGrid_" .. cat.id,
                    size = UDim2.new(1, 0, 0, 100),
                    zIndex = 3,
                    parent = self.presetGridContent,
                })
                local catGridLayout = Instance.new("UIGridLayout")
                catGridLayout.CellSize = UDim2.new(1/3, -Theme.Spacing.SM, 0, 80)
                catGridLayout.CellPadding = UDim.new(0, Theme.Spacing.SM, 0, Theme.Spacing.SM)
                catGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
                catGridLayout.Parent = catGrid

                for _, preset in ipairs(catPresets) do
                    self:_createPresetCard(preset, catGrid)
                end
            end
        end
    else
        -- Single category view
        local catGrid = createFrame({
            name = "FilteredGrid",
            size = UDim2.new(1, 0, 0, 100),
            zIndex = 3,
            parent = self.presetGridContent,
        })
        local catGridLayout = Instance.new("UIGridLayout")
        catGridLayout.CellSize = UDim2.new(1/3, -Theme.Spacing.SM, 0, 80)
        catGridLayout.CellPadding = UDim.new(0, Theme.Spacing.SM, 0, Theme.Spacing.SM)
        catGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        catGridLayout.Parent = catGrid

        for _, preset in ipairs(filtered) do
            self:_createPresetCard(preset, catGrid)
        end
    end
end

function EffectPanel:_createPresetCard(preset, parent)
    local card = Instance.new("TextButton")
    card.Name = "PresetCard_" .. preset.id
    card.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    card.BackgroundTransparency = 0.5
    card.BorderSizePixel = 0
    card.AutoButtonColor = false
    card.Text = ""
    createCorner({ radius = Theme.CornerRadius.LG, parent = card })
    createStroke({ color = Theme.Colors.BorderDefault, transparency = 0.6, parent = card })
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, Theme.Spacing.Base)
    pad.PaddingRight = UDim.new(0, Theme.Spacing.Base)
    pad.PaddingTop = UDim.new(0, Theme.Spacing.Base)
    pad.PaddingBottom = UDim.new(0, Theme.Spacing.Base)
    pad.Parent = card

    createLabel({
        name = "PresetName",
        size = UDim2.new(1, 0, 0, 26),
        text = preset.name,
        textColor = Theme.Colors.TextSecondary,
        textSize = Theme.FontSize.Label,
        font = Theme.Font.FamilySemibold,
        clips = true,
        zIndex = 3,
        parent = card,
    })

    local catBadge = createFrame({
        name = "CatBadge",
        size = UDim2.new(0, 80, 0, 20),
        position = UDim2.new(0, 0, 0, 30),
        color = Theme.Colors.SurfaceActive,
        transparency = 0.4,
        corner = Theme.CornerRadius.SM,
        zIndex = 3,
        parent = card,
    })
    local catName = preset.category or "custom"
    createLabel({
        size = UDim2.new(1, 0, 1, 0),
        text = catName:sub(1, 1):upper() .. catName:sub(2),
        textColor = Theme.Colors.TextBody,
        textSize = Theme.FontSize.BadgeSmall,
        zIndex = 4,
        parent = catBadge,
    })

    table.insert(self.connections, card.Activated:Connect(function()
        local frame = preset.generate and preset.generate(15)
        if frame then
            self.store:loadEditorFrames({ frame })
        else
            self.store:initEditorFrames(15, 1)
        end
        self.store:setEditorPresetBrowserOpen(false)
        self.store:setEffectPanelView("editor")
    end))

    -- Hover
    table.insert(self.connections, card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(Theme.Animation.HoverEnter), {
            BackgroundTransparency = 0.3,
        }):Play()
    end))
    table.insert(self.connections, card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(Theme.Animation.HoverExit), {
            BackgroundTransparency = 0.5,
        }):Play()
    end))

    card.Parent = parent
end

function EffectPanel:_openPresetBrowser()
    self.presetBackdrop.Visible = true
    self.presetModal.Visible = true
    self.presetSearchInput.Text = ""
    self.presetSearch = ""
    self.presetCategory = "all"
    self:_refreshPresetCategories()
    self:_refreshPresetGrid()

    self.presetBackdrop.BackgroundTransparency = 1
    TweenService:Create(self.presetBackdrop, TweenInfo.new(Theme.Animation.ModalFadeIn), {
        BackgroundTransparency = 0.6,
    }):Play()
    self.presetModal.BackgroundTransparency = 0.3
    TweenService:Create(self.presetModal, TweenInfo.new(Theme.Animation.ModalScaleIn, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.05,
    }):Play()
end

function EffectPanel:_closePresetBrowser()
    TweenService:Create(self.presetBackdrop, TweenInfo.new(Theme.Animation.ModalFadeOut), {
        BackgroundTransparency = 1,
    }):Play()
    TweenService:Create(self.presetModal, TweenInfo.new(Theme.Animation.ModalScaleOut, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 0.3,
    }):Play()
    spawn(function()
        wait(Theme.Animation.ModalFadeOut)
        self.presetBackdrop.Visible = false
        self.presetModal.Visible = false
    end)
end

--------------------------------------------------------------------------------
-- CANVAS REFRESH
--------------------------------------------------------------------------------

function EffectPanel:_refreshCanvas()
    local frames = self.store.editorFrames
    local frameIndex = self.store.editorCurrentFrameIndex
    local frame = frames[frameIndex]
    if not frame then return end

    -- Clear beams
    for _, btn in ipairs(self.beamLayer:GetChildren()) do
        btn:Destroy()
    end
    self.beamButtons = {}

    for _, beam in ipairs(frame) do
        if not beam.visible then continue end
        local sz = 28 + (beam.iris / 255) * 36
        local sel = self.store:isEditorBeamSelected(beam.id)

        local beamBtn = Instance.new("Frame")
        beamBtn.Name = "Beam_" .. beam.id
        beamBtn.Size = UDim2.new(0, sz, 0, sz)
        beamBtn.Position = UDim2.new(beam.x / 100, -sz / 2, beam.y / 100, -sz / 2)
        beamBtn.AnchorPoint = Vector2.new(0, 0)
        beamBtn.BackgroundColor3 = self:_beamColor(beam)
        beamBtn.BackgroundTransparency = (beam.dimmer or 255) / 255 * (1 - (beam.brightness or 1))
        beamBtn.BorderSizePixel = 0
        beamBtn.ZIndex = sel and 10 or 5
        beamBtn.Parent = self.beamLayer

        createCorner({ radius = Theme.CornerRadius.Full, parent = beamBtn })

        if sel then
            -- White border ring + glow
            local selStroke = createStroke({
                color = Color3.new(1, 1, 1),
                thickness = 3,
                parent = beamBtn,
            })
            -- Glow (approximate with a slightly larger background frame)
            local glow = Instance.new("ImageLabel")
            glow.Size = UDim2.new(1, 12, 1, 12)
            glow.Position = UDim2.new(0, -6, 0, -6)
            glow.BackgroundTransparency = 1
            glow.ImageTransparency = 0.85
            glow.ImageColor3 = Color3.new(1, 1, 1)
            glow.ScaleType = Enum.ScaleType.Slice
            glow.SliceCenter = Rect.new(49, 49, 450, 450)
            glow.ZIndex = -1
            glow.Parent = beamBtn
        end

        -- Beam number label
        local label = createLabel({
            name = "BeamNum",
            size = UDim2.new(1, 0, 1, 0),
            text = tostring(beam.id),
            textColor = (beam.dimmer or 255) > 128 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1),
            textSize = Theme.FontSize.Ultra,
            font = Theme.Font.FamilyBold,
            xAlign = Enum.TextXAlignment.Center,
            zIndex = 6,
            parent = beamBtn,
        })

        -- Drag handling
        table.insert(self.connections, beamBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if self.store.editorIsPlaying then return end
                input.Position -- consume

                -- Toggle selection
                if self.shiftHeld then
                    self.store:toggleEditorBeamSelection(beam.id)
                else
                    -- Check if already selected
                    if not self.store:isEditorBeamSelected(beam.id) then
                        self.store:deselectAllEditorBeams()
                    end
                    self.store:toggleEditorBeamSelection(beam.id)
                end

                -- Start drag
                self.store:editorPushUndo()
                self.isDraggingBeam = true
                self.dragBeamIndex = beam.id
                self.dragStartX = input.Position.X
                self.dragStartY = input.Position.Y
                self.dragStartBeamX = beam.x
                self.dragStartBeamY = beam.y
            end
        end))

        self.beamButtons[beam.id] = beamBtn
    end

    self:_refreshOnionSkin()
end

function EffectPanel:_beamColor(beam)
    if beam.saturation and beam.saturation > 0 then
        -- HSB to RGB approximation
        local h = beam.hue or 0
        local s = beam.saturation
        local b = beam.brightness or 1
        return self:_hsbToColor3(h, s, b)
    end
    return Color3.new(1, 1, 1)
end

function EffectPanel:_hsbToColor3(h, s, b)
    h = h % 360
    s = math.clamp(s, 0, 1)
    b = math.clamp(b, 0, 1)
    local c = b * s
    local x = c * (1 - math.abs(((h / 60) % 2) - 1))
    local m = b - c
    local r, g, bl
    if h < 60 then r, g, bl = c, x, 0
    elseif h < 120 then r, g, bl = x, c, 0
    elseif h < 180 then r, g, bl = 0, c, x
    elseif h < 240 then r, g, bl = 0, x, c
    elseif h < 300 then r, g, bl = x, 0, c
    else r, g, bl = c, 0, x
    end
    return Color3.fromRGB(math.round((r + m) * 255), math.round((g + m) * 255), math.round((bl + m) * 255))
end

function EffectPanel:_handleBeamDrag(input)
    if not self.canvas then return end
    local canvasAbsSize = self.canvas.AbsoluteSize
    if canvasAbsSize.X <= 0 or canvasAbsSize.Y <= 0 then return end

    local dx = ((input.Position.X - self.dragStartX) / canvasAbsSize.X) * 100
    local dy = ((input.Position.Y - self.dragStartY) / canvasAbsSize.Y) * 100

    local newX = math.clamp(self.dragStartBeamX + dx, 0, 100)
    local newY = math.clamp(self.dragStartBeamY + dy, 0, 100)

    -- Update beam position visually (directly, no undo push)
    local frame = self.store:getEditorCurrentFrame()
    if frame and frame[self.dragBeamIndex] then
        frame[self.dragBeamIndex].x = newX
        frame[self.dragBeamIndex].y = newY

        local btn = self.beamButtons[self.dragBeamIndex]
        if btn then
            local sz = btn.AbsoluteSize.X
            btn.Position = UDim2.new(newX / 100, -sz / 2, newY / 100, -sz / 2)
        end

        -- Update position display
        self:_updatePositionDisplay(newX, newY)
    end
end

function EffectPanel:_endBeamDrag()
    if not self.isDraggingBeam then return end
    self.isDraggingBeam = false
    -- Emit change event (data already updated in place)
    self.store:emit("editorFramesChanged", self.store.editorFrames)
end

function EffectPanel:_refreshCanvasSelections()
    local frame = self.store:getEditorCurrentFrame()
    if not frame then return end

    for _, beam in ipairs(frame) do
        local btn = self.beamButtons[beam.id]
        if not btn then continue end
        local sel = self.store:isEditorBeamSelected(beam.id)
        btn.ZIndex = sel and 10 or 5

        -- Update selection visual
        local existingStroke = btn:FindFirstChildOfClass("UIStroke")
        if sel and not existingStroke then
            createStroke({ color = Color3.new(1, 1, 1), thickness = 3, parent = btn })
        elseif not sel and existingStroke then
            existingStroke:Destroy()
        end
    end
end

function EffectPanel:_refreshOnionSkin()
    -- Clear onion skin
    for _, btn in ipairs(self.onionSkinLayer:GetChildren()) do
        btn:Destroy()
    end
    self.onionBeams = {}

    if not self.store.editorOnionSkin then return end
    local prevIdx = self.store.editorCurrentFrameIndex - 1
    if prevIdx < 1 then return end

    local prevFrame = self.store.editorFrames[prevIdx]
    if not prevFrame then return end

    for _, beam in ipairs(prevFrame) do
        if not beam.visible then continue end
        local sz = 28 + (beam.iris / 255) * 36

        local ghost = Instance.new("Frame")
        ghost.Name = "Onion_" .. beam.id
        ghost.Size = UDim2.new(0, sz, 0, sz)
        ghost.Position = UDim2.new(beam.x / 100, -sz / 2, beam.y / 100, -sz / 2)
        ghost.BackgroundColor3 = self:_beamColor(beam)
        ghost.BackgroundTransparency = 0.88 -- 12% opacity
        ghost.BorderSizePixel = 0
        ghost.ZIndex = 3
        ghost.Parent = self.onionSkinLayer
        createCorner({ radius = Theme.CornerRadius.Full, parent = ghost })

        -- Dashed border approximation (solid thin)
        local onionStroke = createStroke({
            color = Color3.new(1, 1, 1),
            transparency = 0.85,
            thickness = 1,
            parent = ghost,
        })

        self.onionBeams[beam.id] = ghost
    end
end

function EffectPanel:_updatePositionDisplay(x, y)
    if self.posXValue then
        self.posXValue.Text = string.format("%.1f%%", x)
    end
    if self.posYValue then
        self.posYValue.Text = string.format("%.1f%%", y)
    end
end

--------------------------------------------------------------------------------
-- TIMELINE REFRESH
--------------------------------------------------------------------------------

function EffectPanel:_refreshTimeline()
    local frames = self.store.editorFrames
    local frameIndex = self.store.editorCurrentFrameIndex

    -- Clear frame buttons
    for _, child in ipairs(self.frameStrip:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    self.frameButtons = {}

    for idx = 1, #frames do
        local isCurrent = (idx == frameIndex)
        local isEaster = (#frames == 31 and idx == 31)

        local frameBtn = Instance.new("TextButton")
        frameBtn.Name = "Frame_" .. idx
        frameBtn.Size = UDim2.new(0, 80, 0, 80)
        frameBtn.BackgroundColor3 = isCurrent and Theme.Colors.EditorFrameActive or Theme.Colors.EditorFrameInactive
        frameBtn.BackgroundTransparency = isCurrent and 0.5 or 0.8
        frameBtn.BorderSizePixel = 0
        frameBtn.AutoButtonColor = false
        frameBtn.Text = isEaster and "Extra" or tostring(idx)
        frameBtn.TextColor3 = isCurrent and Theme.Colors.TextPrimary or Theme.Colors.TextSecondary
        frameBtn.TextSize = isEaster and Theme.FontSize.Micro : Theme.FontSize.Small
        frameBtn.Font = isEaster and Theme.Font.FamilyBold : Theme.Font.FamilyBold
        frameBtn.ZIndex = 5
        frameBtn.LayoutOrder = idx

        createCorner({ radius = Theme.CornerRadius.LG, parent = frameBtn })
        createStroke({
            color = isCurrent and Color3.new(1, 1, 1) or Theme.Colors.BorderDefault,
            transparency = isCurrent and 0 : 0.6,
            parent = frameBtn,
        })

        -- Easter egg glow for frame 31
        if isEaster then
            local glowLabel = createLabel({
                size = UDim2.new(1, 0, 0, 14),
                position = UDim2.new(0, 0, 1, -14),
                text = "Mile",
                textColor = Theme.Colors.TextSubtle,
                textSize = Theme.FontSize.BadgeSmall,
                font = Theme.Font.FamilyLight,
                xAlign = Enum.TextXAlignment.Center,
                zIndex = 6,
                parent = frameBtn,
            })
            -- Pulsing glow animation
            spawn(function()
                while frameBtn and frameBtn.Parent do
                    TweenHelper.pulse(frameBtn, "BackgroundTransparency", 0.3, 0.6, 2)
                    wait(2)
                end
            end)
        end

        -- Playhead indicator
        if isCurrent and self.store.editorIsPlaying then
            local playhead = createFrame({
                name = "Playhead",
                size = UDim2.new(1, -4, 0, 4),
                position = UDim2.new(0, 2, 0, 0),
                color = Color3.new(1, 1, 1),
                transparency = 0,
                corner = UDim.new(0, 2),
                zIndex = 10,
                parent = frameBtn,
            })
        end

        -- Click to navigate
        table.insert(self.connections, frameBtn.Activated:Connect(function()
            self.store:setEditorCurrentFrameIndex(idx)
        end))

        -- Right-click for context menu
        table.insert(self.connections, frameBtn.MouseButton2Down:Connect(function(input)
            self:_showContextMenu(input.Position, idx)
        end))

        frameBtn.Parent = self.frameStrip
        self.frameButtons[idx] = frameBtn
    end

    -- Add frame button
    local addBtn = Instance.new("TextButton")
    addBtn.Name = "AddFrame"
    addBtn.Size = UDim2.new(0, 80, 0, 80)
    addBtn.BackgroundColor3 = Color3.new(1, 1, 1)
    addBtn.BackgroundTransparency = 1
    addBtn.BorderSizePixel = 0
    addBtn.AutoButtonColor = false
    addBtn.Text = "+"
    addBtn.TextColor3 = Theme.Colors.TextSubtle
    addBtn.TextSize = Theme.FontSize.Large
    addBtn.Font = Theme.Font.FamilyBold
    addBtn.ZIndex = 5
    addBtn.LayoutOrder = #frames + 1
    createCorner({ radius = Theme.CornerRadius.LG, parent = addBtn })
    createStroke({ color = Theme.Colors.BorderDefault, transparency = 0.3, parent = addBtn })
    table.insert(self.connections, addBtn.Activated:Connect(function()
        self.store:addEditorFrame()
    end))
    addBtn.Parent = self.frameStrip

    -- Update frame counter
    if self.frameCounter then
        self.frameCounter.Text = string.format("F%d/%d", frameIndex, #frames)
    end

    -- Update toolbar info
    if self.toolbarInfo then
        self.toolbarInfo.Text = string.format("%dF  |  %d sel", #frames, #self.store.editorSelectedBeams)
    end
end

function EffectPanel:_refreshBeamStrip()
    local frame = self.store:getEditorCurrentFrame()
    if not frame then return end

    -- Clear existing beam buttons in strip
    for _, child in ipairs(self.beamStrip:GetChildren()) do
        if child.Name:match("^BeamStrip_") then
            child:Destroy()
        end
    end

    local xOff = 70 -- after "BEAM" label
    for _, beam in ipairs(frame) do
        local sel = self.store:isEditorBeamSelected(beam.id)

        local btn = Instance.new("TextButton")
        btn.Name = "BeamStrip_" .. beam.id
        btn.Size = UDim2.new(0, 56, 0, 48)
        btn.Position = UDim2.new(0, xOff, 0, 4)
        btn.BackgroundColor3 = sel and Theme.Colors.SurfaceActive or Color3.new(1, 1, 1)
        btn.BackgroundTransparency = sel and 0.5 or 1
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = tostring(beam.id)
        btn.TextColor3 = sel and Theme.Colors.TextPrimary or Theme.Colors.TextBody
        btn.TextSize = Theme.FontSize.Micro
        btn.Font = Theme.Font.FamilyBold
        btn.ZIndex = 5

        createCorner({ radius = Theme.CornerRadius.SM, parent = btn })
        createStroke({
            color = sel and Color3.new(1, 1, 1) or Theme.Colors.BorderDefault,
            transparency = sel and 0 : 0.6,
            parent = btn,
        })

        if sel then
            btn.BackgroundColor3 = self:_beamColor(beam)
            btn.TextColor3 = (beam.dimmer or 255) > 128 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
        end

        table.insert(self.connections, btn.Activated:Connect(function()
            if not self.store.editorIsPlaying then
                self.store:toggleEditorBeamSelection(beam.id)
            end
        end))

        btn.Parent = self.beamStrip
        xOff = xOff + 60
    end
end

function EffectPanel:_refreshPlayhead()
    -- Auto-scroll to active frame
    local frameBtn = self.frameButtons[self.store.editorCurrentFrameIndex]
    if frameBtn and self.frameStripScroll then
        -- Approximate scroll to make frame visible
        local targetX = frameBtn.AbsolutePosition.X - self.frameStripScroll.AbsolutePosition.X
        self.frameStripScroll.CanvasPosition = Vector2.new(
            math.clamp(targetX - 200, 0, math.max(0, self.frameStripScroll.AbsoluteCanvasSize.X - self.frameStripScroll.AbsoluteSize.X)),
            0
        )
    end
end

function EffectPanel:_refreshPlaybackControls()
    local store = self.store

    -- Play/Pause button
    if self.playPauseBtn then
        self.playPauseBtn.Text = store.editorIsPlaying and "||" or ">"
    end

    -- Speed display
    if self.speedLabel then
        self.speedLabel.Text = string.format("%.2fx", store.editorSpeed)
    end

    -- Loop button
    if self.loopBtn then
        if store.editorLoop then
            self.loopBtn.BackgroundColor3 = Theme.Colors.SurfaceActive
            self.loopBtn.BackgroundTransparency = 0.5
            self.loopBtn.TextColor3 = Theme.Colors.TextPrimary
        else
            self.loopBtn.BackgroundColor3 = Color3.new(1, 1, 1)
            self.loopBtn.BackgroundTransparency = 1
            self.loopBtn.TextColor3 = Theme.Colors.TextBody
        end
    end

    -- Onion button
    if self.onionBtn then
        if store.editorOnionSkin then
            self.onionBtn.BackgroundColor3 = Theme.Colors.SurfaceActive
            self.onionBtn.BackgroundTransparency = 0.5
            self.onionBtn.TextColor3 = Theme.Colors.TextPrimary
        else
            self.onionBtn.BackgroundColor3 = Color3.new(1, 1, 1)
            self.onionBtn.BackgroundTransparency = 1
            self.onionBtn.TextColor3 = Theme.Colors.TextBody
        end
    end

    -- Frame counter
    if self.frameCounter then
        self.frameCounter.Text = string.format("F%d/%d", store.editorCurrentFrameIndex, #store.editorFrames)
    end

    -- Toolbar info
    if self.toolbarInfo then
        self.toolbarInfo.Text = string.format("%dF  |  %d sel", #store.editorFrames, #store.editorSelectedBeams)
    end
end

--------------------------------------------------------------------------------
-- PROPERTIES REFRESH
--------------------------------------------------------------------------------

function EffectPanel:_refreshProperties()
    local store = self.store
    local selected = store.editorSelectedBeams

    if #selected == 0 then
        self.propsEmptyLabel.Visible = true
        self.propsActive.Visible = false
        return
    end

    self.propsEmptyLabel.Visible = false
    self.propsActive.Visible = true

    local first = self:_getFirstSelectedBeam()
    if not first then return end

    -- Selection count
    if self.propsSelectionLabel then
        self.propsSelectionLabel.Text = #selected > 1 and "(" .. #selected .. ")" or ""
    end

    -- Apply to all
    if self.applyAllCheckMark then
        if store.editorApplyToAllFrames then
            self.applyAllCheckBg.BackgroundColor3 = Color3.new(1, 1, 1)
            self.applyAllCheckBg.BackgroundTransparency = 0
            self.applyAllCheckMark.TextTransparency = 0
        else
            self.applyAllCheckBg.BackgroundColor3 = Theme.Colors.ToggleOffBorder
            self.applyAllCheckBg.BackgroundTransparency = 0
            self.applyAllCheckMark.TextTransparency = 1
        end
    end

    -- Iris slider
    self._sliderBeamIndex = first.id
    local irisVal = (first.iris or 255) / 255
    if self.irisValue then self.irisValue.Text = tostring(first.iris or 255) end
    if self.irisSliderFill then self.irisSliderFill.Size = UDim2.new(irisVal, 0, 1, 0) end
    if self.irisSliderThumb then
        self.irisSliderThumb.Position = UDim2.new(irisVal, -12, 0, -8)
    end

    -- Dimmer slider
    local dimmerVal = (first.dimmer or 255) / 255
    if self.dimmerValue then self.dimmerValue.Text = tostring(first.dimmer or 255) end
    if self.dimmerSliderFill then self.dimmerSliderFill.Size = UDim2.new(dimmerVal, 0, 1, 0) end
    if self.dimmerSliderThumb then
        self.dimmerSliderThumb.Position = UDim2.new(dimmerVal, -12, 0, -8)
    end

    -- Position
    self:_updatePositionDisplay(first.x or 50, first.y or 50)

    -- Visible toggle
    if self.visibleToggle then
        if first.visible then
            self.visibleToggle.Text = "ON"
            self.visibleToggle.TextColor3 = Theme.Colors.TextPrimary
            self.visibleToggle.BackgroundColor3 = Theme.Colors.SurfaceActive
            self.visibleToggle.BackgroundTransparency = 0.5
        else
            self.visibleToggle.Text = "OFF"
            self.visibleToggle.TextColor3 = Theme.Colors.TextSubtle
            self.visibleToggle.BackgroundColor3 = Color3.new(1, 1, 1)
            self.visibleToggle.BackgroundTransparency = 1
        end
    end
end

--------------------------------------------------------------------------------
-- PLAYBACK
--------------------------------------------------------------------------------

function EffectPanel:_updatePlayback()
    if self.store.editorIsPlaying then
        self:_startPlayback()
    else
        self:_stopPlayback()
    end
end

function EffectPanel:_startPlayback()
    self:_stopPlayback()
    self.playbackConnection = spawn(function()
        while self.store.editorIsPlaying and self.currentView == "editor" do
            wait(0.5 / self.store.editorSpeed)

            -- Check loop
            local nextFrame = self.store.editorCurrentFrameIndex + 1
            if nextFrame > #self.store.editorFrames then
                if self.store.editorLoop then
                    nextFrame = 1
                else
                    self.store:setEditorPlaying(false)
                    break
                end
            end
            self.store:setEditorCurrentFrameIndex(nextFrame)
        end
    end)
end

function EffectPanel:_stopPlayback()
    if self.playbackConnection then
        self.playbackConnection = nil
    end
end

--------------------------------------------------------------------------------
-- CONTEXT MENU
--------------------------------------------------------------------------------

function EffectPanel:_showContextMenu(position, frameIndex)
    -- Destroy existing
    self:_closeContextMenu()

    local menuWidth = 240
    local menuHeight = 140
    local gui = self.frame
    local viewportSize = gui.AbsoluteSize

    local x = position.X
    local y = position.Y
    if x + menuWidth > viewportSize.X then x = viewportSize.X - menuWidth - 16 end
    if y + menuHeight > viewportSize.Y then y = viewportSize.Y - menuHeight - 16 end
    x = math.max(8, x)
    y = math.max(8, y)

    local backdrop = Instance.new("TextButton")
    backdrop.Name = "CtxBackdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.Text = ""
    backdrop.AutoButtonColor = false
    backdrop.ZIndex = 100
    backdrop.Parent = gui
    table.insert(self.connections, backdrop.Activated:Connect(function()
        self:_closeContextMenu()
    end))

    local menu = Instance.new("Frame")
    menu.Name = "ContextMenu"
    menu.Size = UDim2.new(0, menuWidth, 0, menuHeight)
    menu.Position = UDim2.new(0, x, 0, y)
    menu.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    menu.BackgroundTransparency = 0.05
    menu.BorderSizePixel = 0
    menu.ZIndex = 101
    menu.ClipsDescendants = true
    menu.Parent = gui
    createCorner({ radius = Theme.CornerRadius.LG, parent = menu })
    createStroke({ color = Theme.Colors.BorderDefault, parent = menu })

    local menuLayout = Instance.new("UIListLayout")
    menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
    menuLayout.Parent = menu

    local function menuBtn(text, callback)
        local b = createButton({
            size = UDim2.new(1, 0, 0, 44),
            text = text,
            textColor = Theme.Colors.TextSecondary,
            textSize = Theme.FontSize.Small,
            padding = { 20, 20, 10, 10 },
            zIndex = 106,
            parent = menu,
        })
        table.insert(self.connections, b.Activated:Connect(function()
            self:_closeContextMenu()
            if callback then callback() end
        end))
        table.insert(self.connections, b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.12), {
                BackgroundTransparency = 0.7,
            }):Play()
        end))
        table.insert(self.connections, b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.12), {
                BackgroundTransparency = 1,
            }):Play()
        end))
    end

    menuBtn("Duplicate", function()
        self.store:duplicateEditorFrame()
    end)
    menuBtn("Insert After", function()
        self.store:addEditorFrame()
    end)
    menuBtn("Remove", function()
        self.store:deleteEditorFrame()
    end)

    self.activeContextMenu = { backdrop = backdrop, menu = menu }
end

function EffectPanel:_closeContextMenu()
    if self.activeContextMenu then
        if self.activeContextMenu.backdrop then self.activeContextMenu.backdrop:Destroy() end
        if self.activeContextMenu.menu then self.activeContextMenu.menu:Destroy() end
        self.activeContextMenu = nil
    end
end

--------------------------------------------------------------------------------
-- KEYBOARD SHORTCUTS
--------------------------------------------------------------------------------

function EffectPanel:_handleKeyInput(input)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        self.shiftHeld = true
        return
    end

    local store = self.store

    if input.KeyCode == Enum.KeyCode.Space then
        if store.editorIsPlaying then
            store:setEditorPlaying(false)
        else
            store:setEditorPlaying(true)
        end
    elseif input.KeyCode == Enum.KeyCode.S and not (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
        store:setEditorPlaying(false)
        store:setEditorCurrentFrameIndex(1)
    elseif input.KeyCode == Enum.KeyCode.Z and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
            store:editorRedo()
        else
            store:editorUndo()
        end
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        -- Ctrl alone doesn't do anything, but Ctrl+S handled below
    elseif input.KeyCode == Enum.KeyCode.S and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
        store:setEditorSaveDialogOpen(true)
    elseif input.KeyCode == Enum.KeyCode.D and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
        store:duplicateEditorFrame()
    elseif input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.Backspace then
        store:deleteEditorFrame()
    elseif input.KeyCode == Enum.KeyCode.Left then
        local newIdx = math.max(1, store.editorCurrentFrameIndex - 1)
        store:setEditorCurrentFrameIndex(newIdx)
    elseif input.KeyCode == Enum.KeyCode.Right then
        local newIdx = math.min(#store.editorFrames, store.editorCurrentFrameIndex + 1)
        store:setEditorCurrentFrameIndex(newIdx)
    elseif input.KeyCode == Enum.KeyCode.A and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
        store:selectAllEditorBeams()
    elseif input.KeyCode == Enum.KeyCode.Escape then
        store:deselectAllEditorBeams()
        self:_closeContextMenu()
    end
end

--------------------------------------------------------------------------------
-- EASTER EGGS
--------------------------------------------------------------------------------

function EffectPanel:_checkEasterEggs()
    local store = self.store
    local frame = store:getEditorCurrentFrame()
    if not frame then return end

    -- All beams aligned (within 2%)
    local beams = frame
    if #beams >= 2 then
        local avgX, avgY = 0, 0
        for _, b in ipairs(beams) do
            avgX = avgX + (b.x or 50)
            avgY = avgY + (b.y or 50)
        end
        avgX = avgX / #beams
        avgY = avgY / #beams
        local aligned = true
        for _, b in ipairs(beams) do
            if math.abs((b.x or 50) - avgX) > 2 or math.abs((b.y or 50) - avgY) > 2 then
                aligned = false
                break
            end
        end
        if aligned and not self.prevAligned then
            store:addToast("All beams aligned — maximum power", "success")
        end
        self.prevAligned = aligned
    end

    -- Speed >= 4 AND >= 30 frames
    if store.editorSpeed >= 4 and #store.editorFrames >= 30 and not store.editorIsPlaying then
        if not self.speedEasterTriggered then
            store:addToast("Maximum velocity engaged", "success")
            self.speedEasterTriggered = true
        end
    else
        self.speedEasterTriggered = false
    end

    -- Exactly 42 frames
    if #store.editorFrames == 42 then
        if not self.frame42ToastTriggered then
            store:addToast("The meaning of life, 42 frames at a time", "success")
            self.frame42ToastTriggered = true
        end
    else
        self.frame42ToastTriggered = false
    end

    -- 15+ selected beams all with iris=0
    if #store.editorSelectedBeams >= 15 and not store.editorIsPlaying then
        local allIris0 = true
        for _, idx in ipairs(store.editorSelectedBeams) do
            local b = frame[idx]
            if not b or (b.iris or 255) ~= 0 then
                allIris0 = false
                break
            end
        end
        if allIris0 then
            store:addToast("Invisible mode activated", "success")
        end
    end

    -- All beams same color (not white/black)
    if #beams >= 3 then
        local firstColor = self:_beamColor(beams[1])
        local allSame = true
        local isNotWhiteOrBlack = (firstColor ~= Color3.new(1, 1, 1)) and (firstColor ~= Color3.new(0, 0, 0))
        if isNotWhiteOrBlack then
            for i = 2, #beams do
                local bc = self:_beamColor(beams[i])
                if bc ~= firstColor then
                    allSame = false
                    break
                end
            end
            local colorStr = string.format("%.0f,%.0f,%.0f", firstColor.R * 255, firstColor.G * 255, firstColor.B * 255)
            if allSame and colorStr ~= self.lastSyncColor then
                self.lastSyncColor = colorStr
                store:addToast("Beam synchronization achieved", "success")
            elseif not allSame then
                self.lastSyncColor = ""
            end
        end
    end
end

--------------------------------------------------------------------------------
-- UTILITY HELPERS
--------------------------------------------------------------------------------

function EffectPanel:_addHoverEffect(btn, hoverBg, hoverText)
    table.insert(self.connections, btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(Theme.Animation.HoverEnter), {
            BackgroundColor3 = hoverBg,
            TextColor3 = hoverText,
        }):Play()
    end))
    table.insert(self.connections, btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(Theme.Animation.HoverExit), {
            BackgroundColor3 = btn.BackgroundColor3,
            TextColor3 = btn.TextColor3,
        }):Play()
    end))
end

function EffectPanel:_addCustomScrollbar(scroll, parentFrame)
    local scrollbar = Instance.new("Frame")
    scrollbar.Name = "CustomScrollbar"
    scrollbar.Size = UDim2.new(0, Theme.Scrollbar.Width, 1, -8)
    scrollbar.Position = UDim2.new(1, -(Theme.Scrollbar.Width + 4), 0, 4)
    scrollbar.BackgroundTransparency = 1
    scrollbar.BorderSizePixel = 0
    scrollbar.ZIndex = 10
    scrollbar.Parent = parentFrame

    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(1, 0, 0.2, 0)
    thumb.Position = UDim2.new(0, 0, 0, 0)
    thumb.BackgroundColor3 = Theme.Colors.ScrollbarThumb
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 11
    thumb.Parent = scrollbar
    createCorner({ radius = Theme.Scrollbar.CornerRadius, parent = thumb })

    table.insert(self.connections, thumb.MouseEnter:Connect(function()
        TweenService:Create(thumb, TweenInfo.new(Theme.Animation.Fast), {
            BackgroundColor3 = Theme.Colors.ScrollbarThumbHover,
        }):Play()
    end))
    table.insert(self.connections, thumb.MouseLeave:Connect(function()
        TweenService:Create(thumb, TweenInfo.new(Theme.Animation.Fast), {
            BackgroundColor3 = Theme.Colors.ScrollbarThumb,
        }):Play()
    end))

    local function updateThumb()
        local canvasY = scroll.AbsoluteCanvasSize.Y
        local viewY = scroll.AbsoluteSize.Y
        if canvasY <= viewY then
            thumb.Visible = false
            return
        end
        thumb.Visible = true
        local ratio = scroll.CanvasPosition.Y / math.max(1, canvasY - viewY)
        local thumbRatio = viewY / canvasY
        local maxThumbY = 1 - thumbRatio
        thumb.Size = UDim2.new(1, 0, math.max(0.02, thumbRatio), 0)
        thumb.Position = UDim2.new(0, 0, ratio * maxThumbY, 0)
    end

    table.insert(self.connections, scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(updateThumb))
    table.insert(self.connections, scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateThumb))
    table.insert(self.connections, scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateThumb))

    task.defer(updateThumb)
end

return EffectPanel
