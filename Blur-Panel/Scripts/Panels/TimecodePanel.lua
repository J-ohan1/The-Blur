--[[
    TimecodePanel.lua — DAW-style Timeline Sequencer
    The-Blur Roblox SurfaceGUI  |  4K (3840x2160)

    Complex timeline editor with:
    - Top: Controls (play/stop, BPM, name) + Saved Projects list
    - Sidebar: Collapsible drag source items (Effects, Toggles, Positions, Special)
    - Bottom: Timeline grid with group rows, step columns, drop targets,
      cell types, resize handles, playhead, and playback

    Usage:
        local TimecodePanel = require(script.Parent.TimecodePanel)
        local panel = TimecodePanel.new(parentFrame, store)
        panel:show()
        -- Later:
        panel:hide()
        panel:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local EffectPresets = require(script.Parent.Parent.EffectPresets)

--------------------------------------------------------------------------------
-- Constants (scaled for 4K: web values * 2)
--------------------------------------------------------------------------------

local COL_WIDTH = 144       -- 72px * 2
local ROW_HEIGHT = 68       -- 34px * 2
local GROUP_LABEL_WIDTH = 192  -- 96px * 2
local DEFAULT_COLS = 24
local SIDEBAR_WIDTH = 440    -- 220px * 2

local TOGGLE_ITEMS = {
    { type = "toggle", action = "toggle-master", label = "On / Off" },
    { type = "toggle", action = "toggle-fade", label = "Fade On / Off" },
    { type = "toggle", action = "toggle-hold", label = "Hold On / Off" },
    { type = "toggle", action = "toggle-hold-fade", label = "Hold Fade" },
}

local WAIT_MULTIPLIERS = { 0.25, 0.5, 1, 2, 4 }

local CELL_COLORS = {
    effect   = { bg = Theme.Colors.CellEffect,   text = Theme.Colors.TextSecondary },
    toggle   = { bg = Theme.Colors.CellToggle,   text = Theme.Colors.TextBody },
    position = { bg = Theme.Colors.CellPosition, text = Theme.Colors.TextSecondary },
    wait     = { bg = Theme.Colors.CellEmpty,    text = Theme.Colors.TextSubtle },
}

local CELL_ACTIVE_COLORS = {
    effect   = { bg = Color3.fromRGB(50, 50, 50),  text = Theme.Colors.TextPrimary },
    toggle   = { bg = Color3.fromRGB(40, 40, 40),  text = Theme.Colors.TextPrimary },
    position = { bg = Color3.fromRGB(60, 60, 60),  text = Theme.Colors.TextPrimary },
    wait     = { bg = Color3.fromRGB(30, 30, 30),  text = Theme.Colors.TextMuted },
}

--------------------------------------------------------------------------------
-- Helper: deep copy
--------------------------------------------------------------------------------
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = deepCopy(v)
    end
    return out
end

--------------------------------------------------------------------------------
-- TimecodePanel
--------------------------------------------------------------------------------

local TimecodePanel = {}
TimecodePanel.__index = TimecodePanel

function TimecodePanel.new(parent, store)
    local self = setmetatable({}, TimecodePanel)
    self.store = store
    self.connections = {}
    self.playbackConnection = nil
    self.playheadTween = nil
    self.isDragging = false
    self.dragPayload = nil
    self.isResizing = false
    self.resizeData = nil
    self.showNewDialog = false
    self.newName = ""
    self.deleteConfirmId = nil
    self.deleteConfirmTimer = nil
    self.expandedSections = { effects = true, toggles = true, positions = true, special = true }
    self.cellFrames = {} -- Map of "groupId-stepNum" -> frame

    -- Theme shortcuts
    local T = Theme
    local C = T.Colors
    local F = T.Font
    local FS = T.FontSize
    local S = T.Spacing
    local R = T.CornerRadius
    local A = T.Animation
    local Z = T.ZIndex

    ----------------------------------------------------------------
    -- Root frame
    ----------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Name = "TimecodePanel"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = true
    frame.Visible = false
    frame.Parent = parent

    ----------------------------------------------------------------
    -- Outer layout
    ----------------------------------------------------------------
    local outer = Instance.new("Frame")
    outer.Size = UDim2.new(1, 0, 1, 0)
    outer.BackgroundTransparency = 1
    outer.Parent = frame

    local outerPad = Instance.new("UIPadding")
    outerPad.PaddingTop = UDim.new(0, S.PanelTopOffset)
    outerPad.PaddingBottom = UDim.new(0, S.PanelPadding)
    outerPad.PaddingLeft = UDim.new(0, S.PanelPadding)
    outerPad.PaddingRight = UDim.new(0, S.PanelPadding)
    outerPad.Parent = outer

    local outerLayout = Instance.new("UIListLayout")
    outerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    outerLayout.Padding = UDim.new(0, S.SM)
    outerLayout.Parent = outer

    ----------------------------------------------------------------
    -- Top section (~38% height)
    ----------------------------------------------------------------
    local topSection = Instance.new("Frame")
    topSection.Name = "TopSection"
    topSection.Size = UDim2.new(1, 0, 0.38, 0)
    topSection.BackgroundTransparency = 1
    topSection.LayoutOrder = 0
    topSection.Parent = outer

    local topLayout = Instance.new("UIListLayout")
    topLayout.SortOrder = Enum.SortOrder.LayoutOrder
    topLayout.FillDirection = Enum.FillDirection.Horizontal
    topLayout.Padding = UDim.new(0, S.SM)
    topLayout.Parent = topSection

    -- ── Controls Frame (left, flex) ──
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "ControlsFrame"
    controlsFrame.Size = UDim2.new(1, -SIDEBAR_WIDTH - S.SM, 1, 0)
    controlsFrame.BackgroundColor3 = C.PanelBackground
    controlsFrame.BackgroundTransparency = 0.5
    controlsFrame.BorderSizePixel = 0
    controlsFrame.ClipsDescendants = true
    controlsFrame.Parent = topSection

    local cfCorner = Instance.new("UICorner")
    cfCorner.CornerRadius = UDim.new(0, R.XL)
    cfCorner.Parent = controlsFrame

    local cfStroke = Instance.new("UIStroke")
    cfStroke.Color = C.BorderDefault
    cfStroke.Transparency = 0.3
    cfStroke.Thickness = 1
    cfStroke.Parent = controlsFrame

    local cfLayout = Instance.new("UIListLayout")
    cfLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cfLayout.Parent = controlsFrame

    -- Header bar
    local cfHeader = Instance.new("Frame")
    cfHeader.Size = UDim2.new(1, 0, 0, 56)
    cfHeader.BackgroundColor3 = Color3.new(1, 1, 1)
    cfHeader.BackgroundTransparency = 1
    cfHeader.BorderSizePixel = 0
    cfHeader.Parent = controlsFrame

    local cfHeaderPad = Instance.new("UIPadding")
    cfHeaderPad.PaddingLeft = UDim.new(0, S.LG)
    cfHeaderPad.PaddingRight = UDim.new(0, S.LG)
    cfHeaderPad.Parent = cfHeader

    -- Header bottom border
    local cfHeaderBorder = Instance.new("Frame")
    cfHeaderBorder.Size = UDim2.new(1, 0, 0, 1)
    cfHeaderBorder.Position = UDim2.new(0, 0, 1, -1)
    cfHeaderBorder.BackgroundColor3 = C.BorderDefault
    cfHeaderBorder.BackgroundTransparency = 0.5
    cfHeaderBorder.BorderSizePixel = 0
    cfHeaderBorder.Parent = cfHeader

    local cfHeaderTitle = Instance.new("TextLabel")
    cfHeaderTitle.Size = UDim2.new(0, 400, 1, 0)
    cfHeaderTitle.BackgroundTransparency = 1
    cfHeaderTitle.Text = "Timecodes"
    cfHeaderTitle.TextColor3 = C.TextSecondary
    cfHeaderTitle.TextSize = FS.Small
    cfHeaderTitle.Font = F.FamilySemibold
    cfHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    cfHeaderTitle.Parent = cfHeader

    local newBtn = Instance.new("TextButton")
    newBtn.Size = UDim2.new(0, 140, 0, 32)
    newBtn.Position = UDim2.new(1, -140, 0.5, -16)
    newBtn.BackgroundColor3 = C.Background
    newBtn.BackgroundTransparency = 1
    newBtn.Text = "+ New"
    newBtn.TextColor3 = C.TextSubtle
    newBtn.TextSize = FS.Tiny
    newBtn.Font = F.FamilyMedium
    newBtn.AutoButtonColor = false
    newBtn.BorderSizePixel = 0
    newBtn.Parent = cfHeader

    -- New timecode input (hidden initially)
    local newDialogFrame = Instance.new("Frame")
    newDialogFrame.Name = "NewDialog"
    newDialogFrame.Size = UDim2.new(1, 0, 0, 0)
    newDialogFrame.BackgroundTransparency = 1
    newDialogFrame.ClipsDescendants = true
    newDialogFrame.Visible = false
    newDialogFrame.Parent = controlsFrame

    -- Transport bar (play/stop/BPM/name) - shown when project active
    local transportBar = Instance.new("Frame")
    transportBar.Name = "TransportBar"
    transportBar.Size = UDim2.new(1, 0, 0, 68)
    transportBar.BackgroundTransparency = 1
    transportBar.Visible = false
    transportBar.Parent = controlsFrame

    local transportPad = Instance.new("UIPadding")
    transportPad.PaddingLeft = UDim.new(0, S.LG)
    transportPad.PaddingRight = UDim.new(0, S.LG)
    transportPad.Parent = transportBar

    -- Bottom border
    local transportBorder = Instance.new("Frame")
    transportBorder.Size = UDim2.new(1, 0, 0, 1)
    transportBorder.Position = UDim2.new(0, 0, 1, -1)
    transportBorder.BackgroundColor3 = C.BorderDefault
    transportBorder.BackgroundTransparency = 0.6
    transportBorder.BorderSizePixel = 0
    transportBorder.Parent = transportBar

    local transportList = Instance.new("UIListLayout")
    transportList.SortOrder = Enum.SortOrder.LayoutOrder
    transportList.FillDirection = Enum.FillDirection.Horizontal
    transportList.Padding = UDim.new(0, S.LG)
    transportList.VerticalAlignment = Enum.VerticalAlignment.Center
    transportList.Parent = transportBar

    -- Play button
    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0, 56, 0, 56)
    playBtn.BackgroundColor3 = C.ButtonActive
    playBtn.BackgroundTransparency = 0.5
    playBtn.Text = ">"
    playBtn.TextColor3 = C.TextBody
    playBtn.TextSize = 24
    playBtn.Font = F.FamilyBold
    playBtn.AutoButtonColor = false
    playBtn.BorderSizePixel = 0
    playBtn.Parent = transportBar

    local playBtnCorner = Instance.new("UICorner")
    playBtnCorner.CornerRadius = UDim.new(0, R.MD)
    playBtnCorner.Parent = playBtn

    local playBtnStroke = Instance.new("UIStroke")
    playBtnStroke.Color = C.BorderHover
    playBtnStroke.Transparency = 0
    playBtnStroke.Thickness = 1
    playBtnStroke.Parent = playBtn

    -- Stop button
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0, 56, 0, 56)
    stopBtn.BackgroundColor3 = C.Surface
    stopBtn.BackgroundTransparency = 0.7
    stopBtn.Text = ""
    stopBtn.AutoButtonColor = false
    stopBtn.BorderSizePixel = 0
    stopBtn.Parent = transportBar

    local stopBtnCorner = Instance.new("UICorner")
    stopBtnCorner.CornerRadius = UDim.new(0, R.MD)
    stopBtnCorner.Parent = stopBtn

    local stopBtnStroke = Instance.new("UIStroke")
    stopBtnStroke.Color = C.BorderDefault
    stopBtnStroke.Transparency = 0.5
    stopBtnStroke.Thickness = 1
    stopBtnStroke.Parent = stopBtn

    local stopIcon = Instance.new("TextLabel")
    stopIcon.Size = UDim2.new(0, 20, 0, 20)
    stopIcon.Position = UDim2.new(0.5, -10, 0.5, -10)
    stopIcon.BackgroundColor3 = C.TextMuted
    stopIcon.Text = ""
    stopIcon.BorderSizePixel = 0
    stopIcon.Parent = stopBtn

    -- BPM section
    local bpmSection = Instance.new("Frame")
    bpmSection.Size = UDim2.new(0, 260, 0, 56)
    bpmSection.BackgroundTransparency = 1
    bpmSection.Parent = transportBar

    local bpmLabel = Instance.new("TextLabel")
    bpmLabel.Size = UDim2.new(0, 60, 0, 24)
    bpmLabel.Position = UDim2.new(0, 0, 0, 0)
    bpmLabel.BackgroundTransparency = 1
    bpmLabel.Text = "BPM"
    bpmLabel.TextColor3 = C.TextSubtle
    bpmLabel.TextSize = FS.Tiny
    bpmLabel.Font = F.FamilyMedium
    bpmLabel.Parent = bpmSection

    local bpmInput = Instance.new("TextBox")
    bpmInput.Name = "BPMInput"
    bpmInput.Size = UDim2.new(0, 100, 0, 48)
    bpmInput.Position = UDim2.new(0, 64, 0, 4)
    bpmInput.BackgroundColor3 = C.InputBackground
    bpmInput.BackgroundTransparency = 0.4
    bpmInput.Text = "120"
    bpmInput.TextColor3 = C.TextPrimary
    bpmInput.TextSize = FS.Small
    bpmInput.Font = F.FamilyLight
    bpmInput.TextXAlignment = Enum.TextXAlignment.Center
    bpmInput.ClearTextOnFocus = false
    bpmInput.BorderSizePixel = 0
    bpmInput.Parent = bpmSection

    local bpmInputCorner = Instance.new("UICorner")
    bpmInputCorner.CornerRadius = UDim.new(0, R.MD)
    bpmInputCorner.Parent = bpmInput

    local bpmInputStroke = Instance.new("UIStroke")
    bpmInputStroke.Color = C.InputBorder
    bpmInputStroke.Transparency = 0
    bpmInputStroke.Thickness = 1
    bpmInputStroke.Parent = bpmInput

    -- Beat info
    local beatInfoLabel = Instance.new("TextLabel")
    beatInfoLabel.Name = "BeatInfo"
    beatInfoLabel.Size = UDim2.new(0, 200, 0, 20)
    beatInfoLabel.Position = UDim2.new(0, 0, 1, 0)
    beatInfoLabel.BackgroundTransparency = 1
    beatInfoLabel.Text = "500ms/beat"
    beatInfoLabel.TextColor3 = C.TextVerySubtle
    beatInfoLabel.TextSize = 16
    beatInfoLabel.Font = F.Mono
    beatInfoLabel.Parent = bpmSection

    -- Name input
    local nameInput = Instance.new("TextBox")
    nameInput.Name = "NameInput"
    nameInput.Size = UDim2.new(1, 0, 0, 48)
    nameInput.BackgroundColor3 = C.Surface
    nameInput.BackgroundTransparency = 0.6
    nameInput.Text = ""
    nameInput.PlaceholderText = "Project name"
    nameInput.PlaceholderColor3 = C.TextVerySubtle
    nameInput.TextColor3 = C.TextSecondary
    nameInput.TextSize = FS.Small
    nameInput.Font = F.FamilyLight
    nameInput.TextTruncate = Enum.TextTruncate.AtEnd
    nameInput.TextXAlignment = Enum.TextXAlignment.Left
    nameInput.ClearTextOnFocus = false
    nameInput.BorderSizePixel = 0
    nameInput.Parent = transportBar

    local nameInputCorner = Instance.new("UICorner")
    nameInputCorner.CornerRadius = UDim.new(0, R.MD)
    nameInputCorner.Parent = nameInput

    local nameInputPad = Instance.new("UIPadding")
    nameInputPad.PaddingLeft = UDim.new(0, S.SM)
    nameInputPad.PaddingRight = UDim.new(0, S.SM)
    nameInputPad.Parent = nameInput

    -- ── Saved Projects List (scrollable, below transport) ──
    local savedList = Instance.new("ScrollingFrame")
    savedList.Name = "SavedList"
    savedList.Size = UDim2.new(1, 0, 1, -130)
    savedList.BackgroundTransparency = 1
    savedList.ScrollBarThickness = 0
    savedList.ScrollBarImageTransparency = 1
    savedList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    savedList.CanvasSize = UDim2.new(0, 0, 0, 0)
    savedList.ElasticBehavior = Enum.ElasticBehavior.Never
    savedList.Parent = controlsFrame

    local savedListLayout = Instance.new("UIListLayout")
    savedListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    savedListLayout.Padding = UDim.new(0, S.SM)
    savedListLayout.Parent = savedList

    local savedListPad = Instance.new("UIPadding")
    savedListPad.PaddingTop = UDim.new(0, S.SM)
    savedListPad.PaddingBottom = UDim.new(0, S.SM)
    savedListPad.PaddingLeft = UDim.new(0, S.SM)
    savedListPad.PaddingRight = UDim.new(0, S.SM)
    savedListPad.Parent = savedList

    -- ── Sidebar (right, fixed width) ──
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0)
    sidebar.BackgroundColor3 = C.PanelBackground
    sidebar.BackgroundTransparency = 0.5
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    sidebar.Parent = topSection

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, R.XL)
    sbCorner.Parent = sidebar

    local sbStroke = Instance.new("UIStroke")
    sbStroke.Color = C.BorderDefault
    sbStroke.Transparency = 0.3
    sbStroke.Thickness = 1
    sbStroke.Parent = sidebar

    -- Sidebar header
    local sbHeader = Instance.new("Frame")
    sbHeader.Size = UDim2.new(1, 0, 0, 56)
    sbHeader.BackgroundColor3 = Color3.new(1, 1, 1)
    sbHeader.BackgroundTransparency = 1
    sbHeader.BorderSizePixel = 0
    sbHeader.Parent = sidebar

    local sbHeaderBorder = Instance.new("Frame")
    sbHeaderBorder.Size = UDim2.new(1, 0, 0, 1)
    sbHeaderBorder.Position = UDim2.new(0, 0, 1, -1)
    sbHeaderBorder.BackgroundColor3 = C.BorderDefault
    sbHeaderBorder.BackgroundTransparency = 0.5
    sbHeaderBorder.BorderSizePixel = 0
    sbHeaderBorder.Parent = sbHeader

    local sbHeaderPad = Instance.new("UIPadding")
    sbHeaderPad.PaddingLeft = UDim.new(0, S.LG)
    sbHeaderPad.Parent = sbHeader

    local sbHeaderTitle = Instance.new("TextLabel")
    sbHeaderTitle.Size = UDim2.new(1, 0, 1, 0)
    sbHeaderTitle.BackgroundTransparency = 1
    sbHeaderTitle.Text = "Items"
    sbHeaderTitle.TextColor3 = C.TextSecondary
    sbHeaderTitle.TextSize = FS.Small
    sbHeaderTitle.Font = F.FamilySemibold
    sbHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    sbHeaderTitle.Parent = sbHeader

    -- Sidebar scroll
    local sbScroll = Instance.new("ScrollingFrame")
    sbScroll.Size = UDim2.new(1, 0, 1, -56)
    sbScroll.BackgroundTransparency = 1
    sbScroll.ScrollBarThickness = 0
    sbScroll.ScrollBarImageTransparency = 1
    sbScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sbScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    sbScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    sbScroll.Parent = sidebar

    local sbScrollLayout = Instance.new("UIListLayout")
    sbScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sbScrollLayout.Padding = UDim.new(0, S.SM)
    sbScrollLayout.Parent = sbScroll

    local sbScrollPad = Instance.new("UIPadding")
    sbScrollPad.PaddingTop = UDim.new(0, S.SM)
    sbScrollPad.PaddingBottom = UDim.new(0, S.SM)
    sbScrollPad.PaddingLeft = UDim.new(0, S.SM)
    sbScrollPad.PaddingRight = UDim.new(0, S.SM)
    sbScrollPad.Parent = sbScroll

    -- Sidebar disabled text
    local sbDisabledText = Instance.new("TextLabel")
    sbDisabledText.Size = UDim2.new(1, 0, 0, 48)
    sbDisabledText.BackgroundTransparency = 1
    sbDisabledText.Text = "Select a timecode first"
    sbDisabledText.TextColor3 = C.TextVerySubtle
    sbDisabledText.TextSize = FS.Tiny
    sbDisabledText.Font = F.FamilyLight
    sbDisabledText.Parent = sbScroll

    ----------------------------------------------------------------
    -- Bottom Frame: Timeline Grid
    ----------------------------------------------------------------
    local timelineFrame = Instance.new("Frame")
    timelineFrame.Name = "TimelineFrame"
    timelineFrame.Size = UDim2.new(1, 0, 0.62, 0)
    timelineFrame.BackgroundColor3 = C.PanelBackground
    timelineFrame.BackgroundTransparency = 0.5
    timelineFrame.BorderSizePixel = 0
    timelineFrame.ClipsDescendants = true
    timelineFrame.LayoutOrder = 1
    timelineFrame.Parent = outer

    local tlCorner = Instance.new("UICorner")
    tlCorner.CornerRadius = UDim.new(0, R.XL)
    tlCorner.Parent = timelineFrame

    local tlStroke = Instance.new("UIStroke")
    tlStroke.Color = C.BorderDefault
    tlStroke.Transparency = 0.3
    tlStroke.Thickness = 1
    tlStroke.Parent = timelineFrame

    local tlLayout = Instance.new("UIListLayout")
    tlLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tlLayout.Parent = timelineFrame

    -- Timeline header
    local tlHeader = Instance.new("Frame")
    tlHeader.Size = UDim2.new(1, 0, 0, 56)
    tlHeader.BackgroundColor3 = Color3.new(1, 1, 1)
    tlHeader.BackgroundTransparency = 1
    tlHeader.BorderSizePixel = 0
    tlHeader.Parent = timelineFrame

    local tlHeaderPad = Instance.new("UIPadding")
    tlHeaderPad.PaddingLeft = UDim.new(0, S.LG)
    tlHeaderPad.PaddingRight = UDim.new(0, S.LG)
    tlHeaderPad.Parent = tlHeader

    local tlHeaderBorder = Instance.new("Frame")
    tlHeaderBorder.Size = UDim2.new(1, 0, 0, 1)
    tlHeaderBorder.Position = UDim2.new(0, 0, 1, -1)
    tlHeaderBorder.BackgroundColor3 = C.BorderDefault
    tlHeaderBorder.BackgroundTransparency = 0.5
    tlHeaderBorder.BorderSizePixel = 0
    tlHeaderBorder.Parent = tlHeader

    local tlHeaderTitle = Instance.new("TextLabel")
    tlHeaderTitle.Size = UDim2.new(0, 300, 1, 0)
    tlHeaderTitle.BackgroundTransparency = 1
    tlHeaderTitle.Text = "Timeline"
    tlHeaderTitle.TextColor3 = C.TextSecondary
    tlHeaderTitle.TextSize = FS.Small
    tlHeaderTitle.Font = F.FamilySemibold
    tlHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    tlHeaderTitle.Parent = tlHeader

    local tlHeaderInfo = Instance.new("TextLabel")
    tlHeaderInfo.Size = UDim2.new(0, 600, 1, 0)
    tlHeaderInfo.Position = UDim2.new(0, 320, 0, 0)
    tlHeaderInfo.BackgroundTransparency = 1
    tlHeaderInfo.Text = ""
    tlHeaderInfo.TextColor3 = C.TextSubtle
    tlHeaderInfo.TextSize = FS.Tiny
    tlHeaderInfo.Font = F.FamilyLight
    tlHeaderInfo.TextXAlignment = Enum.TextXAlignment.Left
    tlHeaderInfo.Name = "InfoLabel"
    tlHeaderInfo.Parent = tlHeader

    -- Playhead step indicator
    local playheadIndicator = Instance.new("Frame")
    playheadIndicator.Name = "PlayheadIndicator"
    playheadIndicator.Size = UDim2.new(0, 300, 0, 32)
    playheadIndicator.Position = UDim2.new(1, -320, 0, 12)
    playheadIndicator.BackgroundTransparency = 1
    playheadIndicator.Visible = false
    playheadIndicator.Parent = tlHeader

    local phDot = Instance.new("Frame")
    phDot.Size = UDim2.new(0, 12, 0, 12)
    phDot.Position = UDim2.new(0, 0, 0.5, -6)
    phDot.BackgroundColor3 = C.TextPrimary
    phDot.BorderSizePixel = 0
    phDot.Parent = playheadIndicator

    local phDotCorner = Instance.new("UICorner")
    phDotCorner.CornerRadius = UDim.new(0, R.Full)
    phDotCorner.Parent = phDot

    local phLabel = Instance.new("TextLabel")
    phLabel.Size = UDim2.new(1, -24, 1, 0)
    phLabel.Position = UDim2.new(0, 20, 0, 0)
    phLabel.BackgroundTransparency = 1
    phLabel.Text = "Step 1"
    phLabel.TextColor3 = C.TextSecondary
    phLabel.TextSize = FS.Tiny
    phLabel.Font = F.Mono
    phLabel.TextXAlignment = Enum.TextXAlignment.Left
    phLabel.Name = "StepLabel"
    phLabel.Parent = playheadIndicator

    -- Timeline scrollable area
    local tlScroll = Instance.new("ScrollingFrame")
    tlScroll.Name = "TimelineScroll"
    tlScroll.Size = UDim2.new(1, 0, 1, -56)
    tlScroll.BackgroundTransparency = 1
    tlScroll.ScrollBarThickness = 0
    tlScroll.ScrollBarImageTransparency = 1
    tlScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tlScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tlScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    tlScroll.Parent = timelineFrame

    -- No-selection placeholder
    local tlEmpty = Instance.new("Frame")
    tlEmpty.Size = UDim2.new(1, 0, 1, 0)
    tlEmpty.BackgroundTransparency = 1
    tlEmpty.Parent = tlScroll

    local tlEmptyIcon = Instance.new("Frame")
    tlEmptyIcon.Size = UDim2.new(0, 100, 0, 100)
    tlEmptyIcon.Position = UDim2.new(0.5, -50, 0.35, 0)
    tlEmptyIcon.BackgroundColor3 = C.Surface
    tlEmptyIcon.BackgroundTransparency = 0.5
    tlEmptyIcon.BorderSizePixel = 0
    tlEmptyIcon.Parent = tlEmpty

    local tlEmptyIconCorner = Instance.new("UICorner")
    tlEmptyIconCorner.CornerRadius = UDim.new(0, R.XXL)
    tlEmptyIconCorner.Parent = tlEmptyIcon

    local tlEmptyIconStroke = Instance.new("UIStroke")
    tlEmptyIconStroke.Color = C.BorderDefault
    tlEmptyIconStroke.Transparency = 0.5
    tlEmptyIconStroke.Thickness = 1
    tlEmptyIconStroke.Parent = tlEmptyIcon

    local tlEmptyIconLabel = Instance.new("TextLabel")
    tlEmptyIconLabel.Size = UDim2.new(1, 0, 1, 0)
    tlEmptyIconLabel.BackgroundTransparency = 1
    tlEmptyIconLabel.Text = "TC"
    tlEmptyIconLabel.TextColor3 = C.TextUltraSubtle
    tlEmptyIconLabel.TextSize = 36
    tlEmptyIconLabel.Font = F.FamilyBold
    tlEmptyIconLabel.Parent = tlEmptyIcon

    local tlEmptyTitle = Instance.new("TextLabel")
    tlEmptyTitle.Size = UDim2.new(1, 0, 0, 32)
    tlEmptyTitle.Position = UDim2.new(0.5, 0, 0.35, 120)
    tlEmptyTitle.AnchorPoint = Vector2.new(0.5, 0)
    tlEmptyTitle.BackgroundTransparency = 1
    tlEmptyTitle.Text = "No timecode selected"
    tlEmptyTitle.TextColor3 = C.TextMuted
    tlEmptyTitle.TextSize = FS.CardTitle
    tlEmptyTitle.Font = F.FamilyMedium
    tlEmptyTitle.Parent = tlEmpty

    local tlEmptySub = Instance.new("TextLabel")
    tlEmptySub.Size = UDim2.new(1, 0, 0, 24)
    tlEmptySub.Position = UDim2.new(0.5, 0, 0.35, 152)
    tlEmptySub.AnchorPoint = Vector2.new(0.5, 0)
    tlEmptySub.BackgroundTransparency = 1
    tlEmptySub.Text = "Create or select a timecode to start editing"
    tlEmptySub.TextColor3 = C.TextVerySubtle
    tlEmptySub.TextSize = FS.Label
    tlEmptySub.Font = F.FamilyLight
    tlEmptySub.Parent = tlEmpty

    ----------------------------------------------------------------
    -- Store references
    ----------------------------------------------------------------
    self.frame = frame
    self.controlsFrame = controlsFrame
    self.newBtn = newBtn
    self.newDialogFrame = newDialogFrame
    self.transportBar = transportBar
    self.playBtn = playBtn
    self.stopBtn = stopBtn
    self.bpmInput = bpmInput
    self.beatInfoLabel = beatInfoLabel
    self.nameInput = nameInput
    self.savedList = savedList
    self.sidebar = sidebar
    self.sbScroll = sbScroll
    self.sbDisabledText = sbDisabledText
    self.timelineFrame = timelineFrame
    self.tlScroll = tlScroll
    self.tlEmpty = tlEmpty
    self.playheadIndicator = playheadIndicator
    self.phDot = phDot
    self.phLabel = phLabel
    self.tlHeaderInfo = tlHeaderInfo
    self.cfHeaderTitle = cfHeaderTitle

    ----------------------------------------------------------------
    -- Methods
    ----------------------------------------------------------------

    --- Create a new timecode project
    function self:createProject(name)
        if #name < 2 then return end
        local project = self.store:createTimecodeProject(name, DEFAULT_COLS)
        self.store:setActiveTimecodeId(project.id)
        self:refreshAll()
    end

    --- Get the active project
    function self:getActiveProject()
        return self.store:getActiveTimecodeProject()
    end

    --- Refresh everything
    function self:refreshAll()
        self:refreshSavedList()
        self:refreshTransport()
        self:refreshSidebar()
        self:refreshTimeline()
    end

    --- Refresh saved projects list
    function self:refreshSavedList()
        for _, child in ipairs(savedList:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local projects = self.store.timecodeProjects or {}
        local activeId = self.store.activeTimecodeId

        if #projects == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, 0, 0, 100)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "No timecodes created"
            emptyLabel.TextColor3 = C.TextSubtle
            emptyLabel.TextSize = FS.Small
            emptyLabel.Font = F.FamilyLight
            emptyLabel.Parent = savedList

            local hint = Instance.new("TextLabel")
            hint.Size = UDim2.new(1, 0, 0, 24)
            hint.Position = UDim2.new(0, 0, 0, 50)
            hint.BackgroundTransparency = 1
            hint.Text = "Click + New to create one"
            hint.TextColor3 = C.TextVerySubtle
            hint.TextSize = FS.Tiny
            hint.Font = F.FamilyLight
            hint.Parent = savedList

            cfHeaderTitle.Text = "Timecodes"
            return
        end

        for i, p in ipairs(projects) do
            local isActive = p.id == activeId
            local isDeleting = self.deleteConfirmId == p.id

            -- Count entries
            local entryCount = 0
            if p.steps then
                for _, step in pairs(p.steps) do
                    if step.effect or step.position then
                        entryCount = entryCount + 1
                    end
                end
            end

            local row = Instance.new("TextButton")
            row.Name = "Project_" .. p.id
            row.Size = UDim2.new(1, 0, 0, 60)
            row.BackgroundColor3 = isActive and C.SurfaceActive or C.Background
            row.BackgroundTransparency = isActive and 0.6 or 1
            row.Text = ""
            row.AutoButtonColor = false
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Parent = savedList

            local rowStroke = Instance.new("UIStroke")
            rowStroke.Color = isDeleting and Theme.Colors.ButtonDanger or (isActive and C.BorderHover or C.BorderDefault)
            rowStroke.Transparency = isDeleting and 0 or (isActive and 0 or 0.5)
            rowStroke.Thickness = 1
            rowStroke.Parent = row

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, R.LG)
            rowCorner.Parent = row

            local rowPad = Instance.new("UIPadding")
            rowPad.PaddingLeft = UDim.new(0, S.LG)
            rowPad.PaddingRight = UDim.new(0, S.LG)
            rowPad.Parent = row

            -- Active dot
            if isActive then
                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 12, 0, 12)
                dot.Position = UDim2.new(0, 0, 0.5, -6)
                dot.BackgroundColor3 = C.TextPrimary
                dot.BorderSizePixel = 0
                dot.Parent = row

                local dotCorner = Instance.new("UICorner")
                dotCorner.CornerRadius = UDim.new(0, R.Full)
                dotCorner.Parent = dot
            end

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -400, 0, 26)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = p.name
            nameLabel.TextColor3 = isActive and C.TextPrimary or C.TextBody
            nameLabel.TextSize = FS.Small
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Font = F.FamilyMedium
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = row

            -- Meta info
            local metaLabel = Instance.new("TextLabel")
            metaLabel.Size = UDim2.new(1, -400, 0, 20)
            metaLabel.Position = UDim2.new(0, 0, 0, 28)
            metaLabel.BackgroundTransparency = 1
            metaLabel.Text = p.bpm .. " BPM  |  " .. entryCount .. " entries"
            metaLabel.TextColor3 = C.TextVerySubtle
            metaLabel.TextSize = FS.Tiny
            metaLabel.Font = F.FamilyLight
            metaLabel.TextXAlignment = Enum.TextXAlignment.Left
            metaLabel.Parent = row

            -- Delete button
            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0, 60, 0, 32)
            delBtn.Position = UDim2.new(1, -60, 0.5, -16)
            delBtn.BackgroundColor3 = C.Background
            delBtn.BackgroundTransparency = 1
            delBtn.Text = isDeleting and "?" or "x"
            delBtn.TextColor3 = isDeleting and Theme.Colors.ButtonDanger or C.TextVerySubtle
            delBtn.TextSize = FS.Tiny
            delBtn.Font = F.FamilyMedium
            delBtn.AutoButtonColor = false
            delBtn.BorderSizePixel = 0
            delBtn.ZIndex = Z.Button
            delBtn.Parent = row

            -- Select project
            table.insert(self.connections, row.Activated:Connect(function()
                self.store:setActiveTimecodeId(p.id)
                self:refreshAll()
            end))

            -- Hover
            table.insert(self.connections, row.MouseEnter:Connect(function()
                TweenService:Create(row, TweenInfo.new(A.Fast), {
                    BackgroundTransparency = 0.8,
                }):Play()
            end))
            table.insert(self.connections, row.MouseLeave:Connect(function()
                TweenService:Create(row, TweenInfo.new(A.Fast), {
                    BackgroundTransparency = isActive and 0.6 or 1,
                }):Play()
            end))

            -- Delete click
            table.insert(self.connections, delBtn.Activated:Connect(function()
                if isDeleting then
                    self.store:deleteTimecodeProject(p.id)
                    self.deleteConfirmId = nil
                    self:refreshAll()
                else
                    self.deleteConfirmId = p.id
                    self:refreshSavedList()
                    -- Auto-cancel after 3 seconds
                    spawn(function()
                        wait(3)
                        if self.deleteConfirmId == p.id then
                            self.deleteConfirmId = nil
                            if savedList.Parent then self:refreshSavedList() end
                        end
                    end)
                end
            end))
        end

        cfHeaderTitle.Text = (activeId and "Timecode") or "Timecodes"
    end

    --- Refresh transport bar
    function self:refreshTransport()
        local project = self:getActiveProject()
        if not project then
            transportBar.Visible = false
            return
        end

        transportBar.Visible = true
        local bpm = self.store.timecodeBPM or 120
        bpmInput.Text = tostring(bpm)
        beatInfoLabel.Text = math.floor(60000 / bpm) .. "ms/beat"
        nameInput.Text = project.name or ""

        -- Update play/stop button states
        local playing = self.store.timecodeIsPlaying
        if playing then
            playBtn.BackgroundColor3 = C.ButtonPrimary
            playBtn.BackgroundTransparency = 0
            playBtn.TextColor3 = C.ButtonPrimaryText
            playBtn.Text = "||"
        else
            playBtn.BackgroundColor3 = C.ButtonActive
            playBtn.BackgroundTransparency = 0.5
            playBtn.TextColor3 = C.TextBody
            playBtn.Text = ">"
        end

        self:updatePlayhead()
    end

    --- Refresh sidebar items
    function self:refreshSidebar()
        local project = self:getActiveProject()
        sbDisabledText.Visible = not project

        -- Clear existing sections
        for _, child in ipairs(sbScroll:GetChildren()) do
            if child:IsA("Frame") and child.Name ~= "DisabledText" then
                child:Destroy()
            end
        end

        if not project then return end

        local effects = EffectPresets.getAll()
        local positions = self.store:getPositions()

        self:createSidebarSection(sbScroll, "effects", "Effects", #effects, function()
            local items = {}
            for _, fx in ipairs(effects) do
                table.insert(items, {
                    type = "effect", action = "effect-" .. fx.id, label = fx.name,
                })
            end
            return items
        end)

        self:createSidebarSection(sbScroll, "toggles", "Toggles", #TOGGLE_ITEMS, function()
            local items = {}
            for _, t in ipairs(TOGGLE_ITEMS) do
                table.insert(items, { type = t.type, action = t.action, label = t.label })
            end
            return items
        end)

        self:createSidebarSection(sbScroll, "positions", "Positions", #positions, function()
            local items = {}
            for _, pos in ipairs(positions) do
                table.insert(items, {
                    type = "position", action = "position-" .. pos.id, label = pos.name,
                })
            end
            return items
        end)

        self:createSidebarSection(sbScroll, "special", "Special", 1, function()
            return {
                { type = "wait", action = "wait", label = "Wait (1 beat)" },
            }
        end)
    end

    --- Create a collapsible sidebar section
    function self:createSidebarSection(parent, sectionKey, title, count, getItems)
        local section = Instance.new("Frame")
        section.Name = "Section_" .. sectionKey
        section.Size = UDim2.new(1, 0, 0, 0)
        section.BackgroundTransparency = 1
        section.AutomaticSize = Enum.AutomaticSize.Y

        local sectionLayout = Instance.new("UIListLayout")
        sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        sectionLayout.Parent = section

        -- Section header button
        local headerBtn = Instance.new("TextButton")
        headerBtn.Size = UDim2.new(1, 0, 0, 44)
        headerBtn.BackgroundColor3 = C.Background
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = ""
        headerBtn.AutoButtonColor = false
        headerBtn.BorderSizePixel = 0
        headerBtn.Parent = section

        local expanded = self.expandedSections[sectionKey] ~= false
        local chevronLabel = Instance.new("TextLabel")
        chevronLabel.Size = UDim2.new(0, 32, 1, 0)
        chevronLabel.BackgroundTransparency = 1
        chevronLabel.Text = expanded and "v" or ">"
        chevronLabel.TextColor3 = C.TextSubtle
        chevronLabel.TextSize = 16
        chevronLabel.Font = F.FamilyBold
        chevronLabel.Parent = headerBtn

        local headerPad = Instance.new("UIPadding")
        headerPad.PaddingLeft = UDim.new(0, S.SM)
        headerPad.PaddingRight = UDim.new(0, S.SM)
        headerPad.Parent = headerBtn

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -120, 1, 0)
        titleLabel.Position = UDim2.new(0, 32, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title:upper()
        titleLabel.TextColor3 = C.TextMuted
        titleLabel.TextSize = 16
        titleLabel.Font = F.FamilySemibold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = headerBtn

        local countLabel = Instance.new("TextLabel")
        countLabel.Size = UDim2.new(0, 60, 1, 0)
        countLabel.Position = UDim2.new(1, -60, 0, 0)
        countLabel.BackgroundTransparency = 1
        countLabel.Text = tostring(count)
        countLabel.TextColor3 = C.TextVerySubtle
        countLabel.TextSize = FS.Tiny
        countLabel.Font = F.FamilyLight
        countLabel.Parent = headerBtn

        -- Items container
        local itemsFrame = Instance.new("Frame")
        itemsFrame.Name = "ItemsFrame"
        itemsFrame.Size = UDim2.new(1, 0, 0, 0)
        itemsFrame.BackgroundTransparency = 1
        itemsFrame.Visible = expanded
        itemsFrame.AutomaticSize = Enum.AutomaticSize.Y
        itemsFrame.ClipsDescendants = true

        local itemsLayout = Instance.new("UIListLayout")
        itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        itemsLayout.Padding = UDim.new(0, S.XS)
        itemsLayout.Parent = itemsFrame

        local itemsPad = Instance.new("UIPadding")
        itemsPad.PaddingLeft = UDim.new(0, S.LG)
        itemsPad.Parent = itemsFrame

        -- Create drag items
        local items = getItems()
        for _, item in ipairs(items) do
            local itemFrame = Instance.new("TextButton")
            itemFrame.Name = "DragItem_" .. item.action
            itemFrame.Size = UDim2.new(1, 0, 0, 36)
            itemFrame.BackgroundColor3 = C.Background
            itemFrame.BackgroundTransparency = 1
            itemFrame.Text = item.label
            itemFrame.TextColor3 = C.TextBody
            itemFrame.TextSize = FS.Tiny
            itemFrame.Font = F.FamilyMedium
            itemFrame.TextXAlignment = Enum.TextXAlignment.Left
            itemFrame.AutoButtonColor = false
            itemFrame.BorderSizePixel = 0
            itemFrame.Parent = itemsFrame

            -- Hover
            table.insert(self.connections, itemFrame.MouseEnter:Connect(function()
                TweenService:Create(itemFrame, TweenInfo.new(A.Fast), {
                    BackgroundTransparency = 0.7,
                }):Play()
                itemFrame.TextColor3 = C.TextSecondary
            end))
            table.insert(self.connections, itemFrame.MouseLeave:Connect(function()
                TweenService:Create(itemFrame, TweenInfo.new(A.Fast), {
                    BackgroundTransparency = 1,
                }):Play()
                itemFrame.TextColor3 = C.TextBody
            end))

            -- Drag start
            table.insert(self.connections, itemFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    self.isDragging = true
                    self.dragPayload = { type = item.type, action = item.action, label = item.label }
                end
            end))
        end

        -- Toggle section
        table.insert(self.connections, headerBtn.Activated:Connect(function()
            expanded = not expanded
            self.expandedSections[sectionKey] = expanded
            itemsFrame.Visible = expanded
            chevronLabel.Text = expanded and "v" or ">"
        end))

        -- Hover header
        table.insert(self.connections, headerBtn.MouseEnter:Connect(function()
            TweenService:Create(headerBtn, TweenInfo.new(A.Fast), {
                BackgroundTransparency = 0.8,
            }):Play()
        end))
        table.insert(self.connections, headerBtn.MouseLeave:Connect(function()
            TweenService:Create(headerBtn, TweenInfo.new(A.Fast), {
                BackgroundTransparency = 1,
            }):Play()
        end))

        section.Parent = parent
    end

    --- Refresh timeline grid
    function self:refreshTimeline()
        -- Clear existing timeline content (except empty state)
        for _, child in ipairs(tlScroll:GetChildren()) do
            if child ~= self.tlEmpty then
                child:Destroy()
            end
        end

        self.cellFrames = {}

        local project = self:getActiveProject()
        if not project then
            tlEmpty.Visible = true
            tlHeaderInfo.Text = ""
            playheadIndicator.Visible = false
            return
        end

        tlEmpty.Visible = false
        local groups = self.store.groups or {}

        if #groups == 0 then
            local noGroupsLabel = Instance.new("TextLabel")
            noGroupsLabel.Size = UDim2.new(1, 0, 0, 48)
            noGroupsLabel.BackgroundTransparency = 1
            noGroupsLabel.Text = "No groups for this timecode"
            noGroupsLabel.TextColor3 = C.TextSubtle
            noGroupsLabel.TextSize = FS.Small
            noGroupsLabel.Font = F.FamilyLight
            noGroupsLabel.Parent = tlScroll
            tlHeaderInfo.Text = ""
            return
        end

        local steps = project.steps or {}
        local numSteps = math.max(DEFAULT_COLS, #steps + 4)

        tlHeaderInfo.Text = #groups .. " tracks  |  " .. numSteps .. " steps"

        -- Calculate total grid size
        local gridWidth = GROUP_LABEL_WIDTH + numSteps * COL_WIDTH
        local gridHeight = #groups * ROW_HEIGHT

        local gridContainer = Instance.new("Frame")
        gridContainer.Name = "GridContainer"
        gridContainer.Size = UDim2.new(0, gridWidth, 0, gridHeight)
        gridContainer.BackgroundTransparency = 1
        gridContainer.Parent = tlScroll

        -- Column headers row
        local headerRow = Instance.new("Frame")
        headerRow.Size = UDim2.new(0, gridWidth, 0, ROW_HEIGHT)
        headerRow.BackgroundTransparency = 1
        headerRow.Parent = gridContainer

        -- Group label header
        local groupLabelHeader = Instance.new("Frame")
        groupLabelHeader.Size = UDim2.new(0, GROUP_LABEL_WIDTH, 1, 0)
        groupLabelHeader.BackgroundColor3 = C.PanelBackground
        groupLabelHeader.BackgroundTransparency = 0.1
        groupLabelHeader.BorderSizePixel = 0
        groupLabelHeader.Parent = headerRow

        local glhBorder = Instance.new("Frame")
        glhBorder.Size = UDim2.new(0, 1, 1, 0)
        glhBorder.Position = UDim2.new(1, -1, 0, 0)
        glhBorder.BackgroundColor3 = C.BorderDefault
        glhBorder.BackgroundTransparency = 0.6
        glhBorder.BorderSizePixel = 0
        glhBorder.Parent = groupLabelHeader

        local glhBottom = Instance.new("Frame")
        glhBottom.Size = UDim2.new(1, 0, 0, 1)
        glhBottom.Position = UDim2.new(0, 0, 1, -1)
        glhBottom.BackgroundColor3 = C.BorderDefault
        glhBottom.BackgroundTransparency = 0.6
        glhBottom.BorderSizePixel = 0
        glhBottom.Parent = groupLabelHeader

        local glhLabel = Instance.new("TextLabel")
        glhLabel.Size = UDim2.new(1, 0, 1, 0)
        glhLabel.BackgroundTransparency = 1
        glhLabel.Text = "GROUP"
        glhLabel.TextColor3 = C.TextSubtle
        glhLabel.TextSize = 14
        glhLabel.Font = F.FamilyBold
        glhLabel.Parent = groupLabelHeader

        -- Step number headers
        for s = 1, numSteps do
            local stepHeader = Instance.new("Frame")
            stepHeader.Size = UDim2.new(0, COL_WIDTH, 1, 0)
            stepHeader.Position = UDim2.new(0, GROUP_LABEL_WIDTH + (s - 1) * COL_WIDTH, 0, 0)
            stepHeader.BackgroundColor3 = C.CellPlayhead
            stepHeader.BackgroundTransparency = 0.6
            stepHeader.BorderSizePixel = 0
            stepHeader.Parent = headerRow
            stepHeader.Name = "StepHeader_" .. s

            local shBottom = Instance.new("Frame")
            shBottom.Size = UDim2.new(1, 0, 0, 1)
            shBottom.Position = UDim2.new(0, 0, 1, -1)
            shBottom.BackgroundColor3 = C.BorderDefault
            shBottom.BackgroundTransparency = 0.8
            shBottom.BorderSizePixel = 0
            shBottom.Parent = stepHeader

            local stepLabel = Instance.new("TextLabel")
            stepLabel.Size = UDim2.new(1, 0, 1, 0)
            stepLabel.BackgroundTransparency = 1
            stepLabel.Text = tostring(s)
            stepLabel.TextColor3 = C.TextSubtle
            stepLabel.TextSize = 16
            stepLabel.Font = F.Mono
            stepLabel.Name = "StepNum"
            stepLabel.Parent = stepHeader
        end

        -- Track rows
        for g, group in ipairs(groups) do
            local rowFrame = Instance.new("Frame")
            rowFrame.Size = UDim2.new(0, gridWidth, 0, ROW_HEIGHT)
            rowFrame.Position = UDim2.new(0, 0, 0, g * ROW_HEIGHT)
            rowFrame.BackgroundTransparency = 1
            rowFrame.Parent = gridContainer

            -- Group label
            local groupLabel = Instance.new("Frame")
            groupLabel.Size = UDim2.new(0, GROUP_LABEL_WIDTH, 1, 0)
            groupLabel.BackgroundColor3 = C.PanelBackground
            groupLabel.BackgroundTransparency = 0.2
            groupLabel.BorderSizePixel = 0
            groupLabel.Parent = rowFrame

            local glBorder = Instance.new("Frame")
            glBorder.Size = UDim2.new(0, 1, 1, 0)
            glBorder.Position = UDim2.new(1, -1, 0, 0)
            glBorder.BackgroundColor3 = C.BorderDefault
            glBorder.BackgroundTransparency = 0.6
            glBorder.BorderSizePixel = 0
            glBorder.Parent = groupLabel

            local glBottom = Instance.new("Frame")
            glBottom.Size = UDim2.new(1, 0, 0, 1)
            glBottom.Position = UDim2.new(0, 0, 1, -1)
            glBottom.BackgroundColor3 = C.BorderDefault
            glBottom.BackgroundTransparency = 0.8
            glBottom.BorderSizePixel = 0
            glBottom.Parent = groupLabel

            local glPad = Instance.new("UIPadding")
            glPad.PaddingLeft = UDim.new(0, S.SM)
            glPad.Parent = groupLabel

            local glLabel = Instance.new("TextLabel")
            glLabel.Size = UDim2.new(1, 0, 1, 0)
            glLabel.BackgroundTransparency = 1
            glLabel.Text = group.name or ("Group " .. g)
            glLabel.TextColor3 = C.TextBody
            glLabel.TextSize = FS.Tiny
            glLabel.TextTruncate = Enum.TextTruncate.AtEnd
            glLabel.Font = F.FamilyMedium
            glLabel.TextXAlignment = Enum.TextXAlignment.Left
            glLabel.Parent = groupLabel

            -- Cell slots for this group
            for s = 1, numSteps do
                local stepData = steps[s]
                local cellData = nil
                if stepData and stepData.effect then
                    cellData = { type = "effect", label = stepData.effectName or "Effect", action = "effect-" .. stepData.effect, span = stepData.span or 1 }
                elseif stepData and stepData.position then
                    cellData = { type = "position", label = stepData.positionName or "Position", action = "position-" .. stepData.position, span = stepData.span or 1 }
                elseif stepData and stepData.wait then
                    cellData = { type = "wait", multiplier = stepData.waitMultiplier or 1, action = "wait", label = "Wait " .. (stepData.waitMultiplier or 1) .. "x", span = stepData.span or 1 }
                end

                local cellFrame = Instance.new("Frame")
                cellFrame.Name = "Cell_" .. group.id .. "_" .. s
                cellFrame.Size = UDim2.new(0, COL_WIDTH, 1, 0)
                cellFrame.Position = UDim2.new(0, GROUP_LABEL_WIDTH + (s - 1) * COL_WIDTH, 0, 0)
                cellFrame.BackgroundColor3 = C.CellEmpty
                cellFrame.BackgroundTransparency = 0
                cellFrame.BorderSizePixel = 0
                cellFrame.Parent = rowFrame

                local cellKey = group.id .. "-" .. s
                self.cellFrames[cellKey] = cellFrame

                -- Cell borders
                local cellBottom = Instance.new("Frame")
                cellBottom.Size = UDim2.new(1, 0, 0, 1)
                cellBottom.Position = UDim2.new(0, 0, 1, -1)
                cellBottom.BackgroundColor3 = C.BorderDefault
                cellBottom.BackgroundTransparency = 0.85
                cellBottom.BorderSizePixel = 0
                cellBottom.Parent = cellFrame

                if s < numSteps then
                    local cellRight = Instance.new("Frame")
                    cellRight.Size = UDim2.new(0, 1, 1, 0)
                    cellRight.Position = UDim2.new(1, -1, 0, 0)
                    cellRight.BackgroundColor3 = C.BorderDefault
                    cellRight.BackgroundTransparency = 0.9
                    cellRight.BorderSizePixel = 0
                    cellRight.Parent = cellFrame
                end

                if cellData then
                    -- Fill cell with content
                    local colors = CELL_COLORS[cellData.type] or CELL_COLORS.effect
                    cellFrame.BackgroundColor3 = colors.bg
                    cellFrame.BackgroundTransparency = 0

                    local innerPad = Instance.new("UIPadding")
                    innerPad.PaddingLeft = UDim.new(0, 6)
                    innerPad.PaddingRight = UDim.new(0, 6)
                    innerPad.PaddingTop = UDim.new(0, 4)
                    innerPad.PaddingBottom = UDim.new(0, 4)
                    innerPad.Parent = cellFrame

                    local cellLabel = Instance.new("TextLabel")
                    cellLabel.Size = UDim2.new(1, -32, 1, 0)
                    cellLabel.BackgroundTransparency = 1
                    cellLabel.Text = cellData.label or ""
                    cellLabel.TextColor3 = colors.text
                    cellLabel.TextSize = FS.Tiny
                    cellLabel.Font = cellData.type == "wait" and F.Mono or F.FamilyMedium
                    cellLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    cellLabel.TextXAlignment = Enum.TextXAlignment.Left
                    cellLabel.Parent = cellFrame

                    -- Remove button (visible on hover)
                    local removeBtn = Instance.new("TextButton")
                    removeBtn.Size = UDim2.new(0, 24, 0, 24)
                    removeBtn.Position = UDim2.new(1, -28, 0, 4)
                    removeBtn.BackgroundColor3 = C.Background
                    removeBtn.BackgroundTransparency = 1
                    removeBtn.Text = "x"
                    removeBtn.TextColor3 = C.TextSubtle
                    removeBtn.TextSize = 16
                    removeBtn.Font = F.FamilyBold
                    removeBtn.AutoButtonColor = false
                    removeBtn.BorderSizePixel = 0
                    removeBtn.Visible = false
                    removeBtn.ZIndex = Z.Button
                    removeBtn.Parent = cellFrame

                    -- Hover: show remove
                    table.insert(self.connections, cellFrame.MouseEnter:Connect(function()
                        removeBtn.Visible = true
                    end))
                    table.insert(self.connections, cellFrame.MouseLeave:Connect(function()
                        removeBtn.Visible = false
                    end))

                    -- Click remove
                    table.insert(self.connections, removeBtn.Activated:Connect(function()
                        if stepData then
                            stepData.effect = nil
                            stepData.position = nil
                            stepData.wait = nil
                            stepData.span = nil
                            stepData.waitMultiplier = nil
                        end
                        self:refreshTimeline()
                    end))

                    -- Wait cells: click to cycle multiplier
                    if cellData.type == "wait" then
                        local waitCellFrame = cellFrame
                        table.insert(self.connections, cellFrame.Activated:Connect(function()
                            if not steps[s] then return end
                            local mult = steps[s].waitMultiplier or 1
                            local nextIdx = nil
                            for mi, m in ipairs(WAIT_MULTIPLIERS) do
                                if m == mult then
                                    nextIdx = mi + 1
                                    break
                                end
                            end
                            local nextMult = WAIT_MULTIPLIERS[nextIdx] or WAIT_MULTIPLIERS[1]
                            steps[s].waitMultiplier = nextMult
                            steps[s].wait = true
                            steps[s].effect = nil
                            steps[s].position = nil
                            self:refreshTimeline()
                        end))
                    end

                    -- Resize handle (right edge)
                    if cellData.type ~= "wait" and cellData.span and cellData.span > 1 then
                        local resizeHandle = Instance.new("Frame")
                        resizeHandle.Size = UDim2.new(0, 8, 1, 0)
                        resizeHandle.Position = UDim2.new(1, -8, 0, 0)
                        resizeHandle.BackgroundColor3 = C.Background
                        resizeHandle.BackgroundTransparency = 1
                        resizeHandle.BorderSizePixel = 0
                        resizeHandle.ZIndex = Z.Button
                        resizeHandle.Parent = cellFrame

                        table.insert(self.connections, resizeHandle.MouseEnter:Connect(function()
                            resizeHandle.BackgroundTransparency = 0.7
                        end))
                        table.insert(self.connections, resizeHandle.MouseLeave:Connect(function()
                            resizeHandle.BackgroundTransparency = 1
                        end))
                    end

                    -- Dashed border for wait
                    if cellData.type == "wait" then
                        local waitStroke = Instance.new("UIStroke")
                        waitStroke.Color = C.BorderHover
                        waitStroke.Transparency = 0.6
                        waitStroke.Thickness = 1
                        waitStroke.Parent = cellFrame
                    end
                end
            end
        end

        self:updatePlayhead()
    end

    --- Update playhead position
    function self:updatePlayhead()
        local project = self:getActiveProject()
        local playing = self.store.timecodeIsPlaying
        local step = self.store.timecodeCurrentStep or 1

        playheadIndicator.Visible = playing

        if playing then
            phLabel.Text = "Step " .. step
            -- Pulse the dot
            if self.playheadTween then self.playheadTween:Cancel() end
            self.playheadTween = TweenService:Create(phDot, TweenInfo.new(
                A.PlayheadPulse, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
            ), { BackgroundTransparency = 0.7 })
            self.playheadTween:Play()
        else
            if self.playheadTween then
                self.playheadTween:Cancel()
                self.playheadTween = nil
            end
            phDot.BackgroundTransparency = 0
        end

        -- Highlight active step column
        if self.tlScroll then
            for name, cellFrame in pairs(self.cellFrames) do
                -- Parse groupId and step
                local _, _, sStr = name:find("^([^-]+)-(%d+)$")
                if sStr then
                    local s = tonumber(sStr)
                    local isPlayheadCol = playing and s == step
                    -- We'd update visual state here but this is simplified
                end
            end
        end
    end

    --- Start playback
    function self:startPlayback()
        local project = self:getActiveProject()
        if not project then return end

        self.store.timecodeIsPlaying = true
        self.store.timecodeCurrentStep = 1
        self:refreshTransport()
        self:refreshTimeline()

        local bpm = self.store.timecodeBPM or 120
        local interval = 60 / bpm

        -- Stop existing
        if self.playbackConnection then
            self.playbackConnection:Disconnect()
            self.playbackConnection = nil
        end

        self.playbackConnection = spawn(function()
            while self.store.timecodeIsPlaying and self:getActiveProject() do
                local currentStep = self.store.timecodeCurrentStep
                self.store.timecodeCurrentStep = currentStep + 1

                local steps = self:getActiveProject().steps or {}
                local maxStep = #steps

                if self.store.timecodeCurrentStep > maxStep then
                    if self.store.timecodeLoop then
                        self.store.timecodeCurrentStep = 1
                    else
                        self.store.timecodeIsPlaying = false
                        self.store.timecodeCurrentStep = 1
                        break
                    end
                end

                -- Execute step
                local stepData = steps[self.store.timecodeCurrentStep]
                if stepData and stepData.effect then
                    self.store:setSelectedEffect(stepData.effect)
                end
                if stepData and stepData.position then
                    self.store:setActivePosition(stepData.position)
                end

                self:updatePlayhead()

                -- Update BPM in case it changed
                bpm = self.store.timecodeBPM or 120
                interval = 60 / bpm
                wait(interval)
            end

            self.store.timecodeIsPlaying = false
            self:refreshTransport()
            self:refreshTimeline()
        end)
    end

    --- Stop playback
    function self:stopPlayback()
        self.store.timecodeIsPlaying = false
        self.store.timecodeCurrentStep = 1
        if self.playbackConnection then
            self.playbackConnection = nil -- spawn can't be disconnected cleanly
        end
        self:refreshTransport()
        self:refreshTimeline()
    end

    --- Drop item into cell
    function self:dropItem(groupId, stepNum)
        if not self.dragPayload then return false end
        local project = self:getActiveProject()
        if not project then return false end

        local steps = project.steps
        if not steps or not steps[stepNum] then return false end

        -- Check if cell is occupied
        local stepData = steps[stepNum]
        if stepData.effect or stepData.position or stepData.wait then
            return false
        end

        -- Place item
        local payload = self.dragPayload
        if payload.type == "effect" then
            local effectId = payload.action:gsub("^effect-", "")
            stepData.effect = effectId
            stepData.effectName = payload.label
            stepData.position = nil
            stepData.wait = nil
        elseif payload.type == "position" then
            local posId = payload.action:gsub("^position-", "")
            stepData.position = posId
            stepData.positionName = payload.label
            stepData.effect = nil
            stepData.wait = nil
        elseif payload.type == "wait" then
            stepData.wait = true
            stepData.waitMultiplier = 1
            stepData.effect = nil
            stepData.position = nil
        elseif payload.type == "toggle" then
            -- Toggle placement
            stepData.toggle = payload.action
            stepData.toggleLabel = payload.label
            stepData.effect = nil
            stepData.position = nil
            stepData.wait = nil
        end

        self.isDragging = false
        self.dragPayload = nil
        self:refreshTimeline()
        return true
    end

    ----------------------------------------------------------------
    -- Event connections
    ----------------------------------------------------------------

    -- New button
    table.insert(self.connections, newBtn.Activated:Connect(function()
        self.showNewDialog = not self.showNewDialog
        if self.showNewDialog then
            self:showNewDialogUI()
        else
            self:hideNewDialogUI()
        end
    end))

    -- Play button
    table.insert(self.connections, playBtn.Activated:Connect(function()
        if self.store.timecodeIsPlaying then
            self:startPlayback()
        else
            if self:getActiveProject() then
                self:startPlayback()
            end
        end
    end))

    -- Stop button
    table.insert(self.connections, stopBtn.Activated:Connect(function()
        self:stopPlayback()
    end))

    -- BPM input
    table.insert(self.connections, bpmInput.FocusLost:Connect(function()
        local val = tonumber(bpmInput.Text)
        if val then
            self.store:setTimecodeBPM(math.clamp(val, 20, 999))
        end
        self:refreshTransport()
    end))

    -- Name input
    table.insert(self.connections, nameInput.FocusLost:Connect(function()
        local project = self:getActiveProject()
        if project then
            project.name = nameInput.Text
            self:refreshSavedList()
        end
    end))

    -- Drag end (mouse up)
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if self.isDragging then
                -- Try to drop on the cell under cursor
                -- Simplified: we'd need hit testing here
                self.isDragging = false
                self.dragPayload = nil
            end
        end
    end))

    -- Store listeners
    table.insert(self.connections, self.store:on("timecodeProjectsChanged", function()
        self:refreshAll()
    end))

    table.insert(self.connections, self.store:on("activeTimecodeChanged", function()
        self:refreshAll()
    end))

    table.insert(self.connections, self.store:on("timecodeBPMChanged", function()
        self:refreshTransport()
    end))

    ----------------------------------------------------------------
    -- New dialog helpers
    ----------------------------------------------------------------

    function self:showNewDialogUI()
        newDialogFrame.Visible = true
        newDialogFrame.Size = UDim2.new(1, 0, 0, 72)

        newDialogFrame:ClearAllChildren()

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0, S.SM)
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.Parent = newDialogFrame

        local dlgPad = Instance.new("UIPadding")
        dlgPad.PaddingLeft = UDim.new(0, S.LG)
        dlgPad.PaddingRight = UDim.new(0, S.LG)
        dlgPad.Parent = newDialogFrame

        local dlgBorder = Instance.new("Frame")
        dlgBorder.Size = UDim2.new(1, 0, 0, 1)
        dlgBorder.Position = UDim2.new(0, 0, 1, -1)
        dlgBorder.BackgroundColor3 = C.BorderDefault
        dlgBorder.BackgroundTransparency = 0.6
        dlgBorder.BorderSizePixel = 0
        dlgBorder.Parent = newDialogFrame

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(1, -260, 0, 56)
        input.BackgroundColor3 = C.InputBackground
        input.BackgroundTransparency = 0.4
        input.Text = ""
        input.PlaceholderText = "Timecode name..."
        input.PlaceholderColor3 = C.TextVerySubtle
        input.TextColor3 = C.TextPrimary
        input.TextSize = FS.Small
        input.Font = F.FamilyLight
        input.ClearTextOnFocus = false
        input.BorderSizePixel = 0
        input.Parent = newDialogFrame

        local inputCorner = Instance.new("UICorner")
        inputCorner.CornerRadius = UDim.new(0, R.MD)
        inputCorner.Parent = input

        local inputStroke = Instance.new("UIStroke")
        inputStroke.Color = C.InputBorder
        inputStroke.Transparency = 0
        inputStroke.Thickness = 1
        inputStroke.Parent = input

        local inputPad = Instance.new("UIPadding")
        inputPad.PaddingLeft = UDim.new(0, S.SM)
        inputPad.PaddingRight = UDim.new(0, S.SM)
        inputPad.Parent = input

        -- Save button
        local saveBtn = Instance.new("TextButton")
        saveBtn.Size = UDim2.new(0, 140, 0, 44)
        saveBtn.BackgroundColor3 = C.ButtonPrimary
        saveBtn.BackgroundTransparency = 0
        saveBtn.Text = "Save"
        saveBtn.TextColor3 = C.ButtonPrimaryText
        saveBtn.TextSize = FS.Tiny
        saveBtn.Font = F.FamilyMedium
        saveBtn.AutoButtonColor = false
        saveBtn.BorderSizePixel = 0
        saveBtn.Parent = newDialogFrame

        local saveCorner = Instance.new("UICorner")
        saveCorner.CornerRadius = UDim.new(0, R.MD)
        saveCorner.Parent = saveBtn

        -- Cancel button
        local cancelBtn = Instance.new("TextButton")
        cancelBtn.Size = UDim2.new(0, 60, 0, 44)
        cancelBtn.BackgroundColor3 = C.Background
        cancelBtn.BackgroundTransparency = 1
        cancelBtn.Text = "x"
        cancelBtn.TextColor3 = C.TextMuted
        cancelBtn.TextSize = FS.Small
        cancelBtn.Font = F.FamilyMedium
        cancelBtn.AutoButtonColor = false
        cancelBtn.BorderSizePixel = 0
        cancelBtn.Parent = newDialogFrame

        -- Focus input
        spawn(function()
            wait(0.1)
            input:CaptureFocus()
        end)

        -- Enter to save
        table.insert(self.connections, input.FocusLost:Connect(function()
            local name = input.Text
            if #name >= 2 then
                self:createProject(name)
                self.showNewDialog = false
                newDialogFrame.Visible = false
                newBtn.Text = "+ New"
            end
        end))

        -- Save click
        table.insert(self.connections, saveBtn.Activated:Connect(function()
            local name = input.Text
            if #name >= 2 then
                self:createProject(name)
                self.showNewDialog = false
                newDialogFrame.Visible = false
            end
        end))

        -- Cancel click
        table.insert(self.connections, cancelBtn.Activated:Connect(function()
            self.showNewDialog = false
            newDialogFrame.Visible = false
            newBtn.Text = "+ New"
        end))
    end

    function self:hideNewDialogUI()
        newDialogFrame.Visible = false
        newBtn.Text = "+ New"
    end

    ----------------------------------------------------------------
    -- Initialize
    ----------------------------------------------------------------
    self:refreshAll()

    return self
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function TimecodePanel:show()
    self.frame.Visible = true
    self:refreshAll()
end

function TimecodePanel:hide()
    self:stopPlayback()
    self.frame.Visible = false
end

function TimecodePanel:destroy()
    self:stopPlayback()
    for _, conn in ipairs(self.connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self.connections = {}
    self.frame:Destroy()
end

return TimecodePanel
