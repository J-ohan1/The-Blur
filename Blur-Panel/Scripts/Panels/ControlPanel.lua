--[[
    ControlPanel.lua — Full Control Panel for The-Blur SurfaceGUI
    4K (3840x2160) pixel-perfect replica of the Next.js website

    Layout:
        Top Row:        Custom Group (left) | Custom Effects (right)
        Position:       Position buttons (10-column grid) with add/delete
        Main Effects:   Left sidebar (Toggles/Hold) | Right scrollable effects (5 categories x 7)

    Export: ControlPanel.new(parent, store) => { frame, show(), hide(), destroy() }
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenHelper = require(script.Parent.Parent.TweenHelper)
local EffectPresets = require(script.Parent.Parent.EffectPresets)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ControlPanel = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HSB to RGB conversion (for internal use)
-- ═══════════════════════════════════════════════════════════════════════════════
local function hsbToRgb(h, s, b)
    h = h % 360
    s = math.clamp(s, 0, 100) / 100
    b = math.clamp(b, 0, 100) / 100
    local c = b * s
    local x = c * (1 - math.abs(((h / 60) % 2) - 1))
    local m = b - c
    local r, g, bl
    if h < 60 then r, g, bl = c, x, 0
    elseif h < 120 then r, g, bl = x, c, 0
    elseif h < 180 then r, g, bl = 0, c, x
    elseif h < 240 then r, g, bl = 0, x, c
    elseif h < 300 then r, g, bl = x, 0, c
    else r, g, bl = c, 0, x end
    return Color3.fromRGB(
        math.round((r + m) * 255),
        math.round((g + m) * 255),
        math.round((bl + m) * 255)
    )
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Helper: create a panel card frame with header
-- ═══════════════════════════════════════════════════════════════════════════════
local function createPanelCard(parent, title, size, position)
    local card = Instance.new("Frame")
    card.Name = "Card_" .. (title or "unnamed")
    card.Size = size or UDim2.new(1, 0, 1, 0)
    card.Position = position or UDim2.new(0, 0, 0, 0)
    card.BackgroundColor3 = Theme.Colors.PanelBackground
    card.BackgroundTransparency = Theme.Transparency.Panel
    card.BorderSizePixel = 0
    card.ClipsDescendants = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Theme.CornerRadius.XL)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.BorderDefault
    stroke.Transparency = 0.3
    stroke.Thickness = 1
    stroke.Parent = card

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, Theme.Spacing.XXL)
    header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.ZIndex = 2
    header.Parent = card

    local headerBorder = Instance.new("Frame")
    headerBorder.Size = UDim2.new(1, 0, 0, 1)
    headerBorder.Position = UDim2.new(0, 0, 1, -1)
    headerBorder.BackgroundColor3 = Theme.Colors.BorderDefault
    headerBorder.BackgroundTransparency = 0.5
    headerBorder.BorderSizePixel = 0
    headerBorder.Parent = header

    local headerPad = Instance.new("UIPadding")
    headerPad.PaddingLeft = UDim.new(0, Theme.Spacing.FramePadding)
    headerPad.PaddingRight = UDim.new(0, Theme.Spacing.FramePadding)
    headerPad.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or ""
    titleLabel.TextColor3 = Theme.Colors.TextSecondary
    titleLabel.TextSize = Theme.FontSize.Small
    titleLabel.Font = Theme.Font.FamilySemibold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    -- Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -Theme.Spacing.XXL)
    content.Position = UDim2.new(0, 0, 0, Theme.Spacing.XXL)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.Parent = card

    card.Parent = parent
    card._content = content
    card._header = header
    return card
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Helper: create a section label
-- ═══════════════════════════════════════════════════════════════════════════════
local function createSectionLabel(parent, text)
    local label = Instance.new("TextLabel")
    label.Name = "SectionLabel_" .. text
    label.Size = UDim2.new(1, 0, 0, Theme.FontSize.Tiny + 24)
    label.BackgroundTransparency = 1
    label.Text = text:upper()
    label.TextColor3 = Theme.Colors.TextSubtle
    label.TextSize = Theme.FontSize.Tiny
    label.Font = Theme.Font.FamilySemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Helper: create UIStroke (border)
-- ═══════════════════════════════════════════════════════════════════════════════
local function addStroke(instance, color, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Colors.BorderDefault
    stroke.Transparency = transparency or 0
    stroke.Thickness = 1
    stroke.Parent = instance
    return stroke
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Helper: add UICorner
-- ═══════════════════════════════════════════════════════════════════════════════
local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or Theme.CornerRadius.MD)
    corner.Parent = instance
    return corner
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Main Panel Constructor
-- ═══════════════════════════════════════════════════════════════════════════════

function ControlPanel.new(parent, store)
    local self = {}
    local connections = {}
    local uiElements = {} -- Track all dynamic UI elements for cleanup

    -- ─────────────────────────────────────────────────────────────────────────
    -- Root Frame
    -- ─────────────────────────────────────────────────────────────────────────
    local frame = Instance.new("Frame")
    frame.Name = "ControlPanel"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Visible = false
    frame.Parent = parent

    -- Main layout (vertical list)
    local mainList = Instance.new("UIListLayout")
    mainList.SortOrder = Enum.SortOrder.LayoutOrder
    mainList.Padding = UDim.new(0, Theme.Spacing.PanelGap)
    mainList.Parent = frame

    local mainPadding = Instance.new("UIPadding")
    mainPadding.PaddingTop = UDim.new(0, Theme.Spacing.PanelTopOffset)
    mainPadding.PaddingBottom = UDim.new(0, Theme.Spacing.PanelPadding)
    mainPadding.PaddingLeft = UDim.new(0, Theme.Spacing.PanelPadding)
    mainPadding.PaddingRight = UDim.new(0, Theme.Spacing.PanelPadding)
    mainPadding.Parent = frame

    -- ═══════════════════════════════════════════════════════════════════════════
    -- TOP ROW: Custom Group (left) + Custom Effects (right)
    -- ═══════════════════════════════════════════════════════════════════════════
    local topRow = Instance.new("Frame")
    topRow.Name = "TopRow"
    topRow.Size = UDim2.new(1, 0, 0, 280)
    topRow.BackgroundTransparency = 1
    topRow.BorderSizePixel = 0
    topRow.LayoutOrder = 1
    topRow.Parent = frame

    local topRowList = Instance.new("UIListLayout")
    topRowList.SortOrder = Enum.SortOrder.LayoutOrder
    topRowList.FillDirection = Enum.FillDirection.Horizontal
    topRowList.Padding = UDim.new(0, Theme.Spacing.PanelGap)
    topRowList.Parent = topRow

    -- ── Left: Custom Group Panel ──
    local groupPanel = createPanelCard(topRow, "Custom Group", UDim2.new(0.5, -Theme.Spacing.PanelGap / 2, 1, 0))
    groupPanel.LayoutOrder = 1
    local groupContent = groupPanel._content

    -- Scrollable list for groups
    local groupScroll = Instance.new("ScrollingFrame")
    groupScroll.Name = "GroupScroll"
    groupScroll.Size = UDim2.new(1, 0, 1, 0)
    groupScroll.BackgroundTransparency = 1
    groupScroll.BorderSizePixel = 0
    groupScroll.ScrollBarThickness = 0
    groupScroll.ScrollBarImageTransparency = 1
    groupScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    groupScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    groupScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    groupScroll.Parent = groupContent

    local groupScrollPad = Instance.new("UIPadding")
    groupScrollPad.PaddingTop = UDim.new(0, Theme.Spacing.SM)
    groupScrollPad.PaddingBottom = UDim.new(0, Theme.Spacing.SM)
    groupScrollPad.PaddingLeft = UDim.new(0, Theme.Spacing.SM)
    groupScrollPad.PaddingRight = UDim.new(0, Theme.Spacing.SM)
    groupScrollPad.Parent = groupScroll

    local groupList = Instance.new("UIListLayout")
    groupList.SortOrder = Enum.SortOrder.LayoutOrder
    groupList.Padding = UDim.new(0, Theme.Spacing.XS)
    groupList.Parent = groupScroll

    -- ── Right: Custom Effects Panel ──
    local effectsPanel = createPanelCard(topRow, "Custom Effects", UDim2.new(0.5, -Theme.Spacing.PanelGap / 2, 1, 0))
    effectsPanel.LayoutOrder = 2
    local effectsContent = effectsPanel._content

    -- Empty state for custom effects
    local effectsEmptyState = Instance.new("Frame")
    effectsEmptyState.Name = "EmptyState"
    effectsEmptyState.Size = UDim2.new(1, 0, 1, 0)
    effectsEmptyState.BackgroundTransparency = 1
    effectsEmptyState.Parent = effectsContent

    local effectsEmptyText = Instance.new("TextLabel")
    effectsEmptyText.Size = UDim2.new(1, 0, 0, Theme.FontSize.Label)
    effectsEmptyText.Position = UDim2.new(0, 0, 0.4, 0)
    effectsEmptyText.BackgroundTransparency = 1
    effectsEmptyText.Text = "No custom effects yet"
    effectsEmptyText.TextColor3 = Theme.Colors.TextMuted
    effectsEmptyText.TextSize = Theme.FontSize.Label
    effectsEmptyText.Font = Theme.Font.FamilyMedium
    effectsEmptyText.Parent = effectsEmptyState

    local effectsEmptySubtext = Instance.new("TextLabel")
    effectsEmptySubtext.Size = UDim2.new(1, 0, 0, Theme.FontSize.Tiny)
    effectsEmptySubtext.Position = UDim2.new(0, 0, 0.4, Theme.FontSize.Label + 8)
    effectsEmptySubtext.BackgroundTransparency = 1
    effectsEmptySubtext.Text = "Create one in the Effect panel"
    effectsEmptySubtext.TextColor3 = Theme.Colors.TextSubtle
    effectsEmptySubtext.TextSize = Theme.FontSize.Tiny
    effectsEmptySubtext.Font = Theme.Font.FamilyLight
    effectsEmptySubtext.Parent = effectsEmptyState

    -- Custom effects scroll container
    local customEffectsScroll = Instance.new("ScrollingFrame")
    customEffectsScroll.Name = "CustomEffectsScroll"
    customEffectsScroll.Size = UDim2.new(1, 0, 1, 0)
    customEffectsScroll.BackgroundTransparency = 1
    customEffectsScroll.BorderSizePixel = 0
    customEffectsScroll.ScrollBarThickness = 0
    customEffectsScroll.ScrollBarImageTransparency = 1
    customEffectsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    customEffectsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    customEffectsScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    customEffectsScroll.Visible = false
    customEffectsScroll.Parent = effectsContent

    local customEffectsPad = Instance.new("UIPadding")
    customEffectsPad.PaddingTop = UDim.new(0, Theme.Spacing.SM)
    customEffectsPad.PaddingBottom = UDim.new(0, Theme.Spacing.SM)
    customEffectsPad.PaddingLeft = UDim.new(0, Theme.Spacing.SM)
    customEffectsPad.PaddingRight = UDim.new(0, Theme.Spacing.SM)
    customEffectsPad.Parent = customEffectsScroll

    local customEffectsList = Instance.new("UIListLayout")
    customEffectsList.SortOrder = Enum.SortOrder.LayoutOrder
    customEffectsList.Padding = UDim.new(0, Theme.Spacing.XS)
    customEffectsList.Parent = customEffectsScroll

    -- TYPE_LABEL mapping for custom effects
    local TYPE_LABEL = {
        movement = "Mvm", pattern = "Pat", chase = "Chase",
        strobe = "Str", wave = "Wav", custom = "Cus",
    }

    -- ═══════════════════════════════════════════════════════════════════════════
    -- POSITION SECTION
    -- ═══════════════════════════════════════════════════════════════════════════
    local positionSection = createPanelCard(frame, "Positions", UDim2.new(1, 0, 0, 200))
    positionSection.LayoutOrder = 2
    local positionContent = positionSection._content

    -- "+ Add" button in header
    local addPosBtn = Instance.new("TextButton")
    addPosBtn.Name = "AddPosBtn"
    addPosBtn.Size = UDim2.new(0, 120, 0, Theme.Spacing.XXL)
    addPosBtn.Position = UDim2.new(1, -120 - Theme.Spacing.FramePadding, 0.5, 0)
    addPosBtn.AnchorPoint = Vector2.new(0, 0.5)
    addPosBtn.BackgroundTransparency = 1
    addPosBtn.Text = "+ Add"
    addPosBtn.TextColor3 = Theme.Colors.TextSubtle
    addPosBtn.TextSize = Theme.FontSize.Badge
    addPosBtn.Font = Theme.Font.FamilyMedium
    addPosBtn.AutoButtonColor = false
    addPosBtn.BorderSizePixel = 0
    addPosBtn.ZIndex = 5
    addPosBtn.Parent = positionSection._header

    table.insert(connections, addPosBtn.MouseEnter:Connect(function()
        TweenHelper.play(addPosBtn, { TextColor3 = Theme.Colors.TextSecondary }, Theme.Animation.Fast)
    end))
    table.insert(connections, addPosBtn.MouseLeave:Connect(function()
        TweenHelper.play(addPosBtn, { TextColor3 = Theme.Colors.TextSubtle }, Theme.Animation.Fast)
    end))

    -- Position grid container
    local posGridContainer = Instance.new("Frame")
    posGridContainer.Name = "PosGridContainer"
    posGridContainer.Size = UDim2.new(1, 0, 1, 0)
    posGridContainer.BackgroundTransparency = 1
    posGridContainer.ClipsDescendants = true
    posGridContainer.Parent = positionContent

    local posGridList = Instance.new("UIListLayout")
    posGridList.SortOrder = Enum.SortOrder.LayoutOrder
    posGridList.Padding = UDim.new(0, Theme.Spacing.XS)
    posGridList.Parent = posGridContainer

    local posGridPad = Instance.new("UIPadding")
    posGridPad.PaddingTop = UDim.new(0, Theme.Spacing.SM)
    posGridPad.PaddingBottom = UDim.new(0, Theme.Spacing.SM)
    posGridPad.PaddingLeft = UDim.new(0, Theme.Spacing.SM)
    posGridPad.PaddingRight = UDim.new(0, Theme.Spacing.SM)
    posGridPad.Parent = posGridContainer

    -- Add position input (hidden by default)
    local addPosInputFrame = Instance.new("Frame")
    addPosInputFrame.Name = "AddPosInputFrame"
    addPosInputFrame.Size = UDim2.new(1, 0, 0, 52)
    addPosInputFrame.BackgroundTransparency = 1
    addPosInputFrame.Visible = false
    addPosInputFrame.LayoutOrder = 0
    addPosInputFrame.Parent = posGridContainer

    local addPosInput = Instance.new("TextBox")
    addPosInput.Name = "Input"
    addPosInput.Size = UDim2.new(1, -120, 0, 48)
    addPosInput.Position = UDim2.new(0, 0, 0, 0)
    addPosInput.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    addPosInput.BackgroundTransparency = 0.4
    addPosInput.BorderSizePixel = 0
    addPosInput.Text = ""
    addPosInput.PlaceholderText = "Position name..."
    addPosInput.PlaceholderColor3 = Theme.Colors.TextSubtle
    addPosInput.TextColor3 = Theme.Colors.TextPrimary
    addPosInput.TextSize = Theme.FontSize.Label
    addPosInput.Font = Theme.Font.FamilyMedium
    addPosInput.ClearTextOnFocus = false
    addPosInput.Parent = addPosInputFrame
    addCorner(addPosInput, Theme.CornerRadius.MD)
    addStroke(addPosInput, Theme.Colors.BorderDefault, 0)

    local addPosSaveBtn = Instance.new("TextButton")
    addPosSaveBtn.Name = "SaveBtn"
    addPosSaveBtn.Size = UDim2.new(0, 100, 0, 48)
    addPosSaveBtn.Position = UDim2.new(1, -100, 0, 0)
    addPosSaveBtn.BackgroundColor3 = Theme.Colors.ButtonPrimary
    addPosSaveBtn.BackgroundTransparency = 0
    addPosSaveBtn.BorderSizePixel = 0
    addPosSaveBtn.Text = "Save"
    addPosSaveBtn.TextColor3 = Theme.Colors.ButtonPrimaryText
    addPosSaveBtn.TextSize = Theme.FontSize.Tiny
    addPosSaveBtn.Font = Theme.Font.FamilySemibold
    addPosSaveBtn.AutoButtonColor = false
    addPosSaveBtn.Parent = addPosInputFrame
    addCorner(addPosSaveBtn, Theme.CornerRadius.MD)

    -- Position button grid (10 columns)
    local posBtnRowFrame = Instance.new("Frame")
    posBtnRowFrame.Name = "PositionButtons"
    posBtnRowFrame.Size = UDim2.new(1, 0, 0, 0)
    posBtnRowFrame.BackgroundTransparency = 1
    posBtnRowFrame.AutomaticSize = Enum.AutomaticSize.Y
    posBtnRowFrame.LayoutOrder = 1
    posBtnRowFrame.Parent = posGridContainer

    local posBtnGrid = Instance.new("UIGridLayout")
    posBtnGrid.CellSize = UDim2.new(0, 80, 0, 40)
    posBtnGrid.CellPadding = UDim2.new(0, Theme.Spacing.XS, 0, Theme.Spacing.XS)
    posBtnGrid.SortOrder = Enum.SortOrder.LayoutOrder
    posBtnGrid.Parent = posBtnRowFrame

    -- No positions state
    local noPosLabel = Instance.new("TextLabel")
    noPosLabel.Name = "NoPositions"
    noPosLabel.Size = UDim2.new(1, 0, 0, Theme.FontSize.Tiny + 8)
    noPosLabel.BackgroundTransparency = 1
    noPosLabel.Text = "No positions saved"
    noPosLabel.TextColor3 = Theme.Colors.TextSubtle
    noPosLabel.TextSize = Theme.FontSize.Tiny
    noPosLabel.Font = Theme.Font.FamilyLight
    noPosLabel.LayoutOrder = 2
    noPosLabel.Parent = posGridContainer

    -- ═══════════════════════════════════════════════════════════════════════════
    -- MAIN EFFECTS SECTION
    -- ═══════════════════════════════════════════════════════════════════════════
    local mainEffectsCard = createPanelCard(frame, "Effects", UDim2.new(1, 0, 1, -520))
    mainEffectsCard.LayoutOrder = 3
    local mainEffectsContent = mainEffectsCard._content

    -- Horizontal split: sidebar + scrollable effects
    local effectsSplit = Instance.new("Frame")
    effectsSplit.Name = "EffectsSplit"
    effectsSplit.Size = UDim2.new(1, 0, 1, 0)
    effectsSplit.BackgroundTransparency = 1
    effectsSplit.Parent = mainEffectsContent

    local effectsSplitList = Instance.new("UIListLayout")
    effectsSplitList.SortOrder = Enum.SortOrder.LayoutOrder
    effectsSplitList.FillDirection = Enum.FillDirection.Horizontal
    effectsSplitList.Parent = effectsSplit

    -- ── Left Sidebar: Toggles + Hold (width 400px = 200px * 2) ──
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 400, 1, 0)
    sidebar.BackgroundTransparency = 1
    sidebar.LayoutOrder = 1
    sidebar.Parent = effectsSplit

    -- Border right
    local sidebarBorder = Instance.new("Frame")
    sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    sidebarBorder.Position = UDim2.new(1, 0, 0, 0)
    sidebarBorder.BackgroundColor3 = Theme.Colors.BorderDefault
    sidebarBorder.BackgroundTransparency = 0.5
    sidebarBorder.BorderSizePixel = 0
    sidebarBorder.Parent = sidebar

    local sidebarPad = Instance.new("UIPadding")
    sidebarPad.PaddingTop = UDim.new(0, Theme.Spacing.FramePadding)
    sidebarPad.PaddingBottom = UDim.new(0, Theme.Spacing.FramePadding)
    sidebarPad.PaddingLeft = UDim.new(0, Theme.Spacing.FramePadding)
    sidebarPad.PaddingRight = UDim.new(0, Theme.Spacing.FramePadding)
    sidebarPad.Parent = sidebar

    local sidebarList = Instance.new("UIListLayout")
    sidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarList.Padding = UDim.new(0, Theme.Spacing.XS)
    sidebarList.Parent = sidebar

    -- TOGGLES section label
    local togglesLabel = createSectionLabel(sidebar, "Toggles")
    togglesLabel.LayoutOrder = 1

    -- Toggle buttons container
    local toggleBtnsContainer = Instance.new("Frame")
    toggleBtnsContainer.Name = "ToggleBtns"
    toggleBtnsContainer.Size = UDim2.new(1, 0, 0, 0)
    toggleBtnsContainer.BackgroundTransparency = 1
    toggleBtnsContainer.AutomaticSize = Enum.AutomaticSize.Y
    toggleBtnsContainer.LayoutOrder = 2
    toggleBtnsContainer.Parent = sidebar

    local toggleBtnsList = Instance.new("UIListLayout")
    toggleBtnsList.SortOrder = Enum.SortOrder.LayoutOrder
    toggleBtnsList.Padding = UDim.new(0, Theme.Spacing.XS)
    toggleBtnsList.Parent = toggleBtnsContainer

    -- Divider
    local divider1 = Instance.new("Frame")
    divider1.Size = UDim2.new(1, 0, 0, 1)
    divider1.BackgroundColor3 = Theme.Colors.BorderDefault
    divider1.BackgroundTransparency = 0.6
    divider1.BorderSizePixel = 0
    divider1.LayoutOrder = 3
    divider1.Parent = sidebar

    -- HOLD section label
    local holdLabel = createSectionLabel(sidebar, "Hold")
    holdLabel.LayoutOrder = 4

    -- Hold buttons container
    local holdBtnsContainer = Instance.new("Frame")
    holdBtnsContainer.Name = "HoldBtns"
    holdBtnsContainer.Size = UDim2.new(1, 0, 0, 0)
    holdBtnsContainer.BackgroundTransparency = 1
    holdBtnsContainer.AutomaticSize = Enum.AutomaticSize.Y
    holdBtnsContainer.LayoutOrder = 5
    holdBtnsContainer.Parent = sidebar

    local holdBtnsList = Instance.new("UIListLayout")
    holdBtnsList.SortOrder = Enum.SortOrder.LayoutOrder
    holdBtnsList.Padding = UDim.new(0, Theme.Spacing.XS)
    holdBtnsList.Parent = holdBtnsContainer

    -- ═══════════════════════════════════════════════════════════════════════════
    -- Helper: create a flat toggle button (On/Off style)
    -- ═══════════════════════════════════════════════════════════════════════════
    local function createFlatButton(parent, label, order)
        local btn = Instance.new("TextButton")
        btn.Name = "FlatButton_" .. label:gsub(" ", "_")
        btn.Size = UDim2.new(1, 0, 0, 56)
        btn.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.LayoutOrder = order
        btn.Parent = parent
        addCorner(btn, Theme.CornerRadius.MD)
        addStroke(btn, Theme.Colors.BorderDefault, 0.4)

        -- Label text
        local labelText = Instance.new("TextLabel")
        labelText.Name = "Label"
        labelText.Size = UDim2.new(0.6, 0, 1, 0)
        labelText.Position = UDim2.new(0, 0, 0, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.TextColor3 = Theme.Colors.TextMuted
        labelText.TextSize = Theme.FontSize.Label
        labelText.Font = Theme.Font.FamilyMedium
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = btn

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, Theme.Spacing.Base)
        pad.Parent = labelText

        -- Status text (ON/OFF)
        local statusText = Instance.new("TextLabel")
        statusText.Name = "Status"
        statusText.Size = UDim2.new(0.3, 0, 1, 0)
        statusText.Position = UDim2.new(0.7, 0, 0, 0)
        statusText.BackgroundTransparency = 1
        statusText.Text = "OFF"
        statusText.TextColor3 = Theme.Colors.TextMuted
        statusText.TextSize = Theme.FontSize.Tiny
        statusText.Font = Theme.Font.FamilyBold
        statusText.TextXAlignment = Enum.TextXAlignment.Right
        statusText.Parent = btn

        return btn, labelText, statusText
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- Helper: create a hold button
    -- ═══════════════════════════════════════════════════════════════════════════
    local function createHoldButton(parent, label, order)
        local btn = Instance.new("TextButton")
        btn.Name = "HoldButton_" .. label:gsub(" ", "_")
        btn.Size = UDim2.new(1, 0, 0, 60)
        btn.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.Selectable = false
        btn.LayoutOrder = order
        btn.Parent = parent
        addCorner(btn, Theme.CornerRadius.MD)
        addStroke(btn, Theme.Colors.BorderDefault, 0.4)

        local labelText = Instance.new("TextLabel")
        labelText.Name = "Label"
        labelText.Size = UDim2.new(0.6, 0, 1, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.TextColor3 = Theme.Colors.TextMuted
        labelText.TextSize = Theme.FontSize.Label
        labelText.Font = Theme.Font.FamilyMedium
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = btn

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, Theme.Spacing.BASE)
        pad.Parent = labelText

        local statusText = Instance.new("TextLabel")
        statusText.Name = "Status"
        statusText.Size = UDim2.new(0.3, 0, 1, 0)
        statusText.Position = UDim2.new(0.7, 0, 0, 0)
        statusText.BackgroundTransparency = 1
        statusText.Text = "OFF"
        statusText.TextColor3 = Theme.Colors.TextMuted
        statusText.TextSize = Theme.FontSize.Tiny
        statusText.Font = Theme.Font.FamilyBold
        statusText.TextXAlignment = Enum.TextXAlignment.Right
        statusText.Parent = btn

        return btn, labelText, statusText
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- Helper: set flat button active/inactive styling
    -- ═══════════════════════════════════════════════════════════════════════════
    local function setFlatButtonActive(btn, labelText, statusText, active)
        if active then
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundColor3 = Color3.fromRGB(38, 38, 38),
                BackgroundTransparency = 0.5,
            }):Play()
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(Theme.Animation.Fast), {
                    Color = Theme.Colors.BorderHover,
                    Transparency = 0,
                }):Play()
            end
            TweenService:Create(labelText, TweenInfo.new(Theme.Animation.Fast), {
                TextColor3 = Theme.Colors.TextPrimary,
            }):Play()
            TweenService:Create(statusText, TweenInfo.new(Theme.Animation.Fast), {
                Text = "ON",
                TextColor3 = Theme.Colors.TextPrimary,
            }):Play()
        else
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                BackgroundTransparency = 0,
            }):Play()
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(Theme.Animation.Fast), {
                    Color = Theme.Colors.BorderDefault,
                    Transparency = 0.4,
                }):Play()
            end
            TweenService:Create(labelText, TweenInfo.new(Theme.Animation.Fast), {
                TextColor3 = Theme.Colors.TextMuted,
            }):Play()
            TweenService:Create(statusText, TweenInfo.new(Theme.Animation.Fast), {
                Text = "OFF",
                TextColor3 = Theme.Colors.TextMuted,
            }):Play()
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- Create toggle buttons
    -- ═══════════════════════════════════════════════════════════════════════════
    local masterOnBtn, masterOnLabel, masterOnStatus = createFlatButton(toggleBtnsContainer, "On / Off", 1)
    local fadeOnBtn, fadeOnLabel, fadeOnStatus = createFlatButton(toggleBtnsContainer, "Fade On / Off", 2)

    -- Master On/Off toggle
    table.insert(connections, masterOnBtn.Activated:Connect(function()
        if not store:hasSelectedGroups() then
            store:emit("toast", { message = "Select a group first", type = "warning" })
            return
        end
        store:toggleMasterOnOff()
    end))

    -- Hover effects for toggle buttons
    local function addFlatBtnHover(btn, label)
        table.insert(connections, btn.MouseEnter:Connect(function()
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke and store.masterOnOff == false then
                TweenService:Create(stroke, TweenInfo.new(Theme.Animation.Fast), {
                    Color = Theme.Colors.BorderHover,
                    Transparency = 0,
                }):Play()
            end
            TweenService:Create(label, TweenInfo.new(Theme.Animation.Fast), {
                TextColor3 = Theme.Colors.TextBody,
            }):Play()
        end))
        table.insert(connections, btn.MouseLeave:Connect(function()
            -- Restore state will be handled by the togglesChanged event
        end))
    end
    addFlatBtnHover(masterOnBtn, masterOnLabel)
    addFlatBtnHover(fadeOnBtn, fadeOnLabel)

    -- Fade On/Off toggle
    table.insert(connections, fadeOnBtn.Activated:Connect(function()
        if not store:hasSelectedGroups() then
            store:emit("toast", { message = "Select a group first", type = "warning" })
            return
        end
        store:toggleFadeOnOff()
    end))

    -- ═══════════════════════════════════════════════════════════════════════════
    -- Create hold buttons
    -- ═══════════════════════════════════════════════════════════════════════════
    local holdOnBtn, holdOnLabel, holdOnStatus = createHoldButton(holdBtnsContainer, "Hold On / Off", 1)
    local holdFadeBtn, holdFadeLabel, holdFadeStatus = createHoldButton(holdBtnsContainer, "Hold Fade On / Off", 2)

    -- Hold On/Off: mouse-down = ON, mouse-up = OFF
    table.insert(connections, holdOnBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not store:hasSelectedGroups() then
                store:emit("toast", { message = "Select a group first", type = "warning" })
                return
            end
            store:setHoldOnOff(true)
        end
    end))
    table.insert(connections, holdOnBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            store:setHoldOnOff(false)
        end
    end))

    -- Hold Fade On/Off: mouse-down = ON, mouse-up = OFF
    table.insert(connections, holdFadeBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not store:hasSelectedGroups() then
                store:emit("toast", { message = "Select a group first", type = "warning" })
                return
            end
            store:setHoldFadeOnOff(true)
        end
    end))
    table.insert(connections, holdFadeBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            store:setHoldFadeOnOff(false)
        end
    end))

    -- ═══════════════════════════════════════════════════════════════════════════
    -- RIGHT: Scrollable Effects Grid (5 categories x 7 effects each)
    -- ═══════════════════════════════════════════════════════════════════════════
    local effectsScrollArea = Instance.new("ScrollingFrame")
    effectsScrollArea.Name = "EffectsScrollArea"
    effectsScrollArea.Size = UDim2.new(1, -400, 1, 0)
    effectsScrollArea.Position = UDim2.new(0, 400, 0, 0)
    effectsScrollArea.BackgroundTransparency = 1
    effectsScrollArea.BorderSizePixel = 0
    effectsScrollArea.ScrollBarThickness = 0
    effectsScrollArea.ScrollBarImageTransparency = 1
    effectsScrollArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
    effectsScrollArea.CanvasSize = UDim2.new(0, 0, 0, 0)
    effectsScrollArea.ElasticBehavior = Enum.ElasticBehavior.Never
    effectsScrollArea.LayoutOrder = 2
    effectsScrollArea.Parent = effectsSplit

    local effectsScrollPad = Instance.new("UIPadding")
    effectsScrollPad.PaddingTop = UDim.new(0, Theme.Spacing.FramePadding)
    effectsScrollPad.PaddingBottom = UDim.new(0, Theme.Spacing.FramePadding)
    effectsScrollPad.PaddingLeft = UDim.new(0, Theme.Spacing.FramePadding)
    effectsScrollPad.PaddingRight = UDim.new(0, Theme.Spacing.FramePadding)
    effectsScrollPad.Parent = effectsScrollArea

    local effectsContentList = Instance.new("UIListLayout")
    effectsContentList.SortOrder = Enum.SortOrder.LayoutOrder
    effectsContentList.Padding = UDim.new(0, Theme.Spacing.XXL)
    effectsContentList.Parent = effectsScrollArea

    -- Create effect category sections
    local categoryLabels = {
        waves = "WAVES",
        chase = "CHASE",
        pattern = "PATTERN",
        color = "COLOR",
        advanced = "ADVANCED",
    }

    local effectButtons = {} -- effectId -> button reference

    local categories = EffectPresets.getCategories()
    for _, cat in ipairs(categories) do
        local catFrame = Instance.new("Frame")
        catFrame.Name = "Category_" .. cat.id
        catFrame.Size = UDim2.new(1, 0, 0, 0)
        catFrame.BackgroundTransparency = 1
        catFrame.AutomaticSize = Enum.AutomaticSize.Y
        catFrame.LayoutOrder = _ == 1 and 1 or 10
        catFrame.Parent = effectsScrollArea
        table.insert(uiElements, catFrame)

        local catList = Instance.new("UIListLayout")
        catList.SortOrder = Enum.SortOrder.LayoutOrder
        catList.Padding = UDim.new(0, Theme.Spacing.Base)
        catList.Parent = catFrame

        -- Category header
        local catHeader = Instance.new("Frame")
        catHeader.Size = UDim2.new(1, 0, 0, Theme.FontSize.Tiny + 24)
        catHeader.BackgroundTransparency = 1
        catHeader.LayoutOrder = 1
        catHeader.Parent = catFrame

        local catHeaderText = Instance.new("TextLabel")
        catHeaderText.Size = UDim2.new(1, 0, 1, 0)
        catHeaderText.BackgroundTransparency = 1
        catHeaderText.Text = categoryLabels[cat.id] or cat.name:upper()
        catHeaderText.TextColor3 = Theme.Colors.TextSubtle
        catHeaderText.TextSize = Theme.FontSize.Tiny
        catHeaderText.Font = Theme.Font.FamilySemibold
        catHeaderText.TextXAlignment = Enum.TextXAlignment.Left
        catHeaderText.Parent = catHeader

        -- Effects grid (3 columns)
        local effectsGrid = Instance.new("Frame")
        effectsGrid.Name = "EffectsGrid"
        effectsGrid.Size = UDim2.new(1, 0, 0, 0)
        effectsGrid.BackgroundTransparency = 1
        effectsGrid.AutomaticSize = Enum.AutomaticSize.Y
        effectsGrid.LayoutOrder = 2
        effectsGrid.Parent = catFrame

        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.CellSize = UDim2.new(0, 160, 0, 44)
        gridLayout.CellPadding = UDim2.new(0, Theme.Spacing.SM, 0, Theme.Spacing.SM)
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.Parent = effectsGrid

        local presets = EffectPresets.getByCategory(cat.id)
        for _, preset in ipairs(presets) do
            local effectBtn = Instance.new("TextButton")
            effectBtn.Name = "Effect_" .. preset.id
            effectBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            effectBtn.BackgroundTransparency = 0.8
            effectBtn.BorderSizePixel = 0
            effectBtn.AutoButtonColor = false
            effectBtn.Text = preset.name
            effectBtn.TextColor3 = Theme.Colors.TextMuted
            effectBtn.TextSize = Theme.FontSize.Small
            effectBtn.Font = Theme.Font.FamilyMedium
            effectBtn.TextXAlignment = Enum.TextXAlignment.Left
            effectBtn.TextTruncate = Enum.TextTruncate.AtEnd
            effectBtn.Parent = effectsGrid
            addCorner(effectBtn, Theme.CornerRadius.MD)

            local effectPad = Instance.new("UIPadding")
            effectPad.PaddingLeft = UDim.new(0, Theme.Spacing.Base)
            effectPad.PaddingRight = UDim.new(0, Theme.Spacing.SM)
            effectPad.Parent = effectBtn

            effectButtons[preset.id] = effectBtn
            table.insert(uiElements, effectBtn)

            -- Click handler
            table.insert(connections, effectBtn.Activated:Connect(function()
                if not store:hasSelectedGroups() then
                    store:emit("toast", { message = "Select a group first", type = "warning" })
                    return
                end
                local current = store.selectedEffect
                store:setSelectedEffect(current == preset.id and nil or preset.id)
            end))

            -- Hover
            table.insert(connections, effectBtn.MouseEnter:Connect(function()
                local isSelected = store.selectedEffect == preset.id
                if not isSelected then
                    TweenService:Create(effectBtn, TweenInfo.new(Theme.Animation.HoverEnter), {
                        BackgroundTransparency = 0.95,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    }):Play()
                    TweenService:Create(effectBtn, TweenInfo.new(Theme.Animation.HoverEnter), {
                        TextColor3 = Theme.Colors.TextSecondary,
                    }):Play()
                    effectBtn.AnchorPoint = Vector2.new(0.5, 0.5)
                    local pos = effectBtn.Position
                    -- Subtle scale
                end
            end))

            table.insert(connections, effectBtn.MouseLeave:Connect(function()
                local isSelected = store.selectedEffect == preset.id
                if not isSelected then
                    TweenService:Create(effectBtn, TweenInfo.new(Theme.Animation.HoverExit), {
                        BackgroundTransparency = 0.8,
                        BackgroundColor3 = Color3.fromRGB(10, 10, 10),
                    }):Play()
                    TweenService:Create(effectBtn, TweenInfo.new(Theme.Animation.HoverExit), {
                        TextColor3 = Theme.Colors.TextMuted,
                    }):Play()
                end
            end))

            -- Press
            table.insert(connections, effectBtn.MouseButton1Down:Connect(function()
                effectBtn.AnchorPoint = Vector2.new(0.5, 0.5)
                local origPos = effectBtn.Position
                local origSize = effectBtn.Size
                effectBtn.Position = UDim2.new(
                    origPos.X.Scale + origSize.X.Scale * 0.01,
                    origPos.X.Offset + origSize.X.Offset * 0.01,
                    origPos.Y.Scale,
                    origPos.Y.Offset + origSize.Y.Offset * 0.01
                )
                effectBtn.Size = UDim2.new(origSize.X.Scale, origSize.X.Offset * 0.98, origSize.Y.Scale, origSize.Y.Offset * 0.98)
            end))

            table.insert(connections, effectBtn.MouseButton1Up:Connect(function()
                effectBtn.AnchorPoint = Vector2.new(0, 0)
                effectBtn.Size = UDim2.new(0, 160, 0, 44)
                effectBtn.Position = UDim2.new(0, 0, 0, 0)
            end))
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- CUSTOM GROUP PANEL: Render groups
    -- ═══════════════════════════════════════════════════════════════════════════
    local groupItems = {}

    local function renderGroups()
        -- Clear existing
        for _, item in ipairs(groupItems) do
            if item and item.Parent then item:Destroy() end
        end
        groupItems = {}

        local groups = store.groups
        local selectedIds = store.selectedGroupIds

        if #groups == 0 then
            -- Empty state
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, 0, 0, Theme.FontSize.Label)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "No groups -- please create one"
            emptyLabel.TextColor3 = Theme.Colors.TextMuted
            emptyLabel.TextSize = Theme.FontSize.Label
            emptyLabel.Font = Theme.Font.FamilyMedium
            emptyLabel.Parent = groupScroll
            table.insert(groupItems, emptyLabel)

            -- Pulsing opacity
            TweenHelper.pulse(emptyLabel, "TextTransparency", 0.3, 1, Theme.Animation.PulseSlow)
            return
        end

        for i, group in ipairs(groups) do
            local isSelected = false
            for _, id in ipairs(selectedIds) do
                if id == group.id then isSelected = true break end
            end

            local row = Instance.new("TextButton")
            row.Name = "Group_" .. group.id
            row.Size = UDim2.new(1, 0, 0, 44)
            row.BackgroundColor3 = isSelected and Color3.fromRGB(38, 38, 38) or Color3.fromRGB(255, 255, 255)
            row.BackgroundTransparency = isSelected and 0.6 or 1
            row.BorderSizePixel = 0
            row.AutoButtonColor = false
            row.Text = ""
            row.LayoutOrder = i
            row.Parent = groupScroll
            addCorner(row, Theme.CornerRadius.MD)
            if isSelected then addStroke(row, Theme.Colors.BorderHover, 0) end

            -- Checkbox (14x14 at 4K = 28px = ~20px)
            local checkbox = Instance.new("Frame")
            checkbox.Name = "Checkbox"
            checkbox.Size = UDim2.new(0, 28, 0, 28)
            checkbox.Position = UDim2.new(0, Theme.Spacing.Base, 0.5, -14)
            checkbox.AnchorPoint = Vector2.new(0, 0.5)
            checkbox.BackgroundColor3 = isSelected and Theme.Colors.TextPrimary or Color3.fromRGB(255, 255, 255)
            checkbox.BackgroundTransparency = isSelected and 0 or 1
            checkbox.BorderSizePixel = 0
            checkbox.Parent = row
            addCorner(checkbox, 4)
            if not isSelected then addStroke(checkbox, Theme.Colors.BorderDefault, 0) end

            -- Checkmark (simple "✓" text)
            if isSelected then
                local check = Instance.new("TextLabel")
                check.Size = UDim2.new(1, 0, 1, 0)
                check.BackgroundTransparency = 1
                check.Text = "✓"
                check.TextColor3 = Color3.fromRGB(0, 0, 0)
                check.TextSize = 18
                check.Font = Theme.Font.FamilyBold
                check.Parent = checkbox
            end

            -- Group name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.5, -60, 1, 0)
            nameLabel.Position = UDim2.new(0, 60, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = group.name
            nameLabel.TextColor3 = isSelected and Theme.Colors.TextPrimary or Theme.Colors.TextSecondary
            nameLabel.TextSize = Theme.FontSize.Label
            nameLabel.Font = Theme.Font.FamilyMedium
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = row

            -- Fixture count badge
            local countBadge = Instance.new("TextLabel")
            countBadge.Size = UDim2.new(0, 60, 0, 22)
            countBadge.Position = UDim2.new(1, -60 - Theme.Spacing.SM, 0.5, -11)
            countBadge.AnchorPoint = Vector2.new(0, 0.5)
            countBadge.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
            countBadge.BackgroundTransparency = 0.4
            countBadge.BorderSizePixel = 0
            countBadge.Text = #group.playerIds .. "F"
            countBadge.TextColor3 = Theme.Colors.TextMuted
            countBadge.TextSize = Theme.FontSize.Badge
            countBadge.Font = Theme.Font.FamilyMedium
            countBadge.Parent = row
            addCorner(countBadge, Theme.CornerRadius.SM)

            -- Click
            table.insert(connections, row.Activated:Connect(function()
                store:toggleGroupSelection(group.id)
            end))

            table.insert(groupItems, row)
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- CUSTOM EFFECTS PANEL: Render saved effects
    -- ═══════════════════════════════════════════════════════════════════════════
    local customEffectItems = {}

    local function renderCustomEffects()
        for _, item in ipairs(customEffectItems) do
            if item and item.Parent then item:Destroy() end
        end
        customEffectItems = {}

        local saved = store.savedEffects
        if #saved == 0 then
            effectsEmptyState.Visible = true
            customEffectsScroll.Visible = false
            return
        end

        effectsEmptyState.Visible = false
        customEffectsScroll.Visible = true

        for i, fx in ipairs(saved) do
            local row = Instance.new("Frame")
            row.Name = "CustomEffect_" .. fx.id
            row.Size = UDim2.new(1, 0, 0, 44)
            row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Parent = customEffectsScroll
            addCorner(row, Theme.CornerRadius.MD)
            addStroke(row, Theme.Colors.BorderDefault, 0.7)

            -- Effect name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
            nameLabel.Position = UDim2.new(0, Theme.Spacing.Base, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = fx.name
            nameLabel.TextColor3 = Theme.Colors.TextSecondary
            nameLabel.TextSize = Theme.FontSize.Label
            nameLabel.Font = Theme.Font.FamilyMedium
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = row

            -- Type badge
            local typeBadge = Instance.new("TextLabel")
            typeBadge.Size = UDim2.new(0, 60, 0, 22)
            typeBadge.Position = UDim2.new(1, -140, 0.5, -11)
            typeBadge.AnchorPoint = Vector2.new(0, 0.5)
            typeBadge.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
            typeBadge.BackgroundTransparency = 0.4
            typeBadge.BorderSizePixel = 0
            typeBadge.Text = TYPE_LABEL[fx.type] or (fx.type or "?")
            typeBadge.TextColor3 = Theme.Colors.TextMuted
            typeBadge.TextSize = Theme.FontSize.Badge
            typeBadge.Font = Theme.Font.FamilyMedium
            typeBadge.Parent = row
            addCorner(typeBadge, Theme.CornerRadius.SM)

            -- Frames badge
            local framesBadge = Instance.new("TextLabel")
            framesBadge.Size = UDim2.new(0, 60, 0, 22)
            framesBadge.Position = UDim2.new(1, -68, 0.5, -11)
            framesBadge.AnchorPoint = Vector2.new(0, 0.5)
            framesBadge.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
            framesBadge.BackgroundTransparency = 0.6
            framesBadge.BorderSizePixel = 0
            framesBadge.Text = #fx.frames .. "F"
            framesBadge.TextColor3 = Theme.Colors.TextSubtle
            framesBadge.TextSize = Theme.FontSize.Badge
            framesBadge.Font = Theme.Font.FamilyMedium
            framesBadge.Parent = row
            addCorner(framesBadge, Theme.CornerRadius.SM)

            table.insert(customEffectItems, row)
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- POSITION SECTION: Render position buttons
    -- ═══════════════════════════════════════════════════════════════════════════
    local positionButtons = {}

    local function renderPositions()
        for _, btn in ipairs(positionButtons) do
            if btn and btn.Parent then btn:Destroy() end
        end
        positionButtons = {}

        local positions = store.positions
        noPosLabel.Visible = #positions == 0

        if #positions > 0 then
            posBtnRowFrame.Visible = true
            for i, pos in ipairs(positions) do
                local isActive = store.activePositionId == pos.id

                local posBtn = Instance.new("TextButton")
                posBtn.Name = "Pos_" .. pos.id
                posBtn.BackgroundColor3 = isActive and Theme.Colors.TextPrimary or Color3.fromRGB(10, 10, 10)
                posBtn.BackgroundTransparency = isActive and 0 or 0.7
                posBtn.BorderSizePixel = 0
                posBtn.AutoButtonColor = false
                posBtn.Text = pos.name
                posBtn.TextColor3 = isActive and Theme.Colors.ButtonPrimaryText or Theme.Colors.TextMuted
                posBtn.TextSize = Theme.FontSize.Badge
                posBtn.Font = Theme.Font.FamilyMedium
                posBtn.TextTruncate = Enum.TextTruncate.AtEnd
                posBtn.LayoutOrder = i
                posBtn.Parent = posBtnRowFrame
                addCorner(posBtn, Theme.CornerRadius.MD)
                if not isActive then
                    addStroke(posBtn, Theme.Colors.BorderDefault, 0.5)
                end

                -- Active glow effect via UIStroke (white border when active)
                if isActive then
                    local glowStroke = Instance.new("UIStroke")
                    glowStroke.Color = Theme.Colors.TextPrimary
                    glowStroke.Transparency = 0.7
                    glowStroke.Thickness = 2
                    glowStroke.Parent = posBtn
                end

                -- Click: activate position
                table.insert(connections, posBtn.Activated:Connect(function()
                    if not store:hasSelectedGroups() then
                        store:emit("toast", { message = "Select a group first", type = "warning" })
                        return
                    end
                    if store.activePositionId == pos.id then
                        store:setActivePosition(nil)
                    else
                        store:setActivePosition(pos.id)
                    end
                    -- Click scale animation: 1 -> 1.05 -> 1
                    posBtn.AnchorPoint = Vector2.new(0.5, 0.5)
                    local origSize = posBtn.Size
                    posBtn.Size = UDim2.new(0, 80 * 1.05, 0, 40 * 1.05)
                    posBtn.Position = UDim2.new(
                        posBtn.Position.X.Scale,
                        posBtn.Position.X.Offset + (80 * 0.025),
                        posBtn.Position.Y.Scale,
                        posBtn.Position.Y.Offset + (40 * 0.025)
                    )
                    spawn(function()
                        wait(0.15)
                        posBtn.Size = origSize
                        posBtn.Position = UDim2.new(0, 0, 0, 0)
                        posBtn.AnchorPoint = Vector2.new(0, 0)
                    end)
                end))

                -- Right-click to delete
                table.insert(connections, posBtn.MouseButton2Click:Connect(function()
                    store:removePosition(pos.id)
                end))

                -- Hover
                table.insert(connections, posBtn.MouseEnter:Connect(function()
                    if not isActive then
                        TweenService:Create(posBtn, TweenInfo.new(Theme.Animation.Fast), {
                            BackgroundTransparency = 0.9,
                            TextColor3 = Theme.Colors.TextSecondary,
                        }):Play()
                    end
                end))
                table.insert(connections, posBtn.MouseLeave:Connect(function()
                    if not isActive then
                        TweenService:Create(posBtn, TweenInfo.new(Theme.Animation.Fast), {
                            BackgroundTransparency = 0.7,
                            TextColor3 = Theme.Colors.TextMuted,
                        }):Play()
                    end
                end))

                table.insert(positionButtons, posBtn)
            end
        else
            posBtnRowFrame.Visible = false
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- EFFECT BUTTONS: Update selected state
    -- ═══════════════════════════════════════════════════════════════════════════
    local function updateEffectButtons()
        for effectId, btn in pairs(effectButtons) do
            if btn and btn.Parent then
                local isSelected = store.selectedEffect == effectId
                if isSelected then
                    TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                        BackgroundColor3 = Color3.fromRGB(38, 38, 38),
                        BackgroundTransparency = 0.4,
                        TextColor3 = Theme.Colors.TextPrimary,
                    }):Play()
                    -- Add border
                    local existingStroke = btn:FindFirstChildOfClass("UIStroke")
                    if not existingStroke then
                        addStroke(btn, Theme.Colors.BorderHover, 0)
                    end
                else
                    TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                        BackgroundColor3 = Color3.fromRGB(10, 10, 10),
                        BackgroundTransparency = 0.8,
                        TextColor3 = Theme.Colors.TextMuted,
                    }):Play()
                    local existingStroke = btn:FindFirstChildOfClass("UIStroke")
                    if existingStroke then existingStroke:Destroy() end
                end
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- ADD POSITION input handling
    -- ═══════════════════════════════════════════════════════════════════════════
    table.insert(connections, addPosBtn.Activated:Connect(function()
        addPosInputFrame.Visible = true
        addPosInput:CaptureFocus()
    end))

    table.insert(connections, addPosInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local name = addPosInput.Text
            if name and #name > 0 then
                name = name:sub(1, Theme.MaxLength.PositionName)
                store:addPosition(name)
            end
        end
        addPosInput.Text = ""
        addPosInputFrame.Visible = false
    end))

    table.insert(connections, addPosSaveBtn.Activated:Connect(function()
        local name = addPosInput.Text
        if name and #name > 0 then
            name = name:sub(1, Theme.MaxLength.PositionName)
            store:addPosition(name)
        end
        addPosInput.Text = ""
        addPosInputFrame.Visible = false
    end))

    -- Input focus styling
    table.insert(connections, addPosInput.Focused:Connect(function()
        local stroke = addPosInput:FindFirstChildOfClass("UIStroke")
        if stroke then
            TweenService:Create(stroke, TweenInfo.new(Theme.Animation.Fast), {
                Color = Theme.Colors.BorderHover,
                Transparency = 0,
            }):Play()
        end
    end))
    table.insert(connections, addPosInput.FocusLost:Connect(function()
        local stroke = addPosInput:FindFirstChildOfClass("UIStroke")
        if stroke then
            TweenService:Create(stroke, TweenInfo.new(Theme.Animation.Fast), {
                Color = Theme.Colors.BorderDefault,
                Transparency = 0,
            }):Play()
        end
    end))

    -- ═══════════════════════════════════════════════════════════════════════════
    -- STORE EVENT LISTENERS
    -- ═══════════════════════════════════════════════════════════════════════════

    -- Groups changed
    table.insert(connections, store:on("groupsChanged", function()
        renderGroups()
    end))

    -- Group selection changed
    table.insert(connections, store:on("groupSelectionChanged", function()
        renderGroups()
    end))

    -- Toggles changed
    table.insert(connections, store:on("togglesChanged", function()
        setFlatButtonActive(masterOnBtn, masterOnLabel, masterOnStatus, store.masterOnOff)
        setFlatButtonActive(fadeOnBtn, fadeOnLabel, fadeOnStatus, store.fadeOnOff)
        setFlatButtonActive(holdOnBtn, holdOnLabel, holdOnStatus, store.holdOnOff)
        setFlatButtonActive(holdFadeBtn, holdFadeLabel, holdFadeStatus, store.holdFadeOnOff)
    end))

    -- Selected effect changed
    table.insert(connections, store:on("selectedEffectChanged", function()
        updateEffectButtons()
    end))

    -- Positions changed
    table.insert(connections, store:on("positionsChanged", function()
        renderPositions()
    end))

    -- Active position changed
    table.insert(connections, store:on("activePositionChanged", function()
        renderPositions()
    end))

    -- Effect saved
    table.insert(connections, store:on("effectSaved", function()
        renderCustomEffects()
    end))

    -- ═══════════════════════════════════════════════════════════════════════════
    -- Initial render
    -- ═══════════════════════════════════════════════════════════════════════════
    renderGroups()
    renderCustomEffects()
    renderPositions()
    updateEffectButtons()
    setFlatButtonActive(masterOnBtn, masterOnLabel, masterOnStatus, store.masterOnOff)
    setFlatButtonActive(fadeOnBtn, fadeOnLabel, fadeOnStatus, store.fadeOnOff)
    setFlatButtonActive(holdOnBtn, holdOnLabel, holdOnStatus, store.holdOnOff)
    setFlatButtonActive(holdFadeBtn, holdFadeLabel, holdFadeStatus, store.holdFadeOnOff)

    -- Pulsing empty state text
    TweenHelper.pulse(effectsEmptyText, "TextTransparency", 0.3, 1, Theme.Animation.PulseSlow)

    -- ═══════════════════════════════════════════════════════════════════════════
    -- Public API
    -- ═══════════════════════════════════════════════════════════════════════════
    function self:show()
        frame.Visible = true
        frame.BackgroundTransparency = 1
        TweenHelper.fadeIn(frame, Theme.Animation.PanelFadeIn)

        -- Re-render on show
        renderGroups()
        renderCustomEffects()
        renderPositions()
        updateEffectButtons()
    end

    function self:hide()
        TweenHelper.fadeOut(frame, Theme.Animation.PanelFadeOut)
        spawn(function()
            wait(Theme.Animation.PanelFadeOut)
            frame.Visible = false
        end)
    end

    function self:destroy()
        for _, conn in ipairs(connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        connections = {}
        frame:Destroy()
    end

    self.frame = frame
    return self
end

return ControlPanel
