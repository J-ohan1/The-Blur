--[[
    CustomisationPanel.lua — Customisation Panel for The-Blur SurfaceGUI
    4K (3840x2160) pixel-perfect replica of the Next.js website

    Layout:
        Left Frame (560px):  Color wheel + brightness slider + preview
                               Selection buttons (All, Odd, Even, Left, Right, Reset)
                               Quick Colors (14 presets in 7-column grid)
                               Color Patterns (Rainbow, Warm, Cool, Neon, Pastel, Mono)
        Right Frame (flex):   9 Faders (Phase, Speed, Iris, Dimmer, Wing, Tilt, Pan, Brightness, Zoom)
                               in 3-column grid layout

    Export: CustomisationPanel.new(parent, store) => { frame, show(), hide(), destroy() }
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenHelper = require(script.Parent.Parent.TweenHelper)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local CustomisationPanel = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HSB to RGB conversion
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
-- Helper: hex to Color3
-- ═══════════════════════════════════════════════════════════════════════════════
local function hexToColor3(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) or 0
    local g = tonumber(hex:sub(3, 4), 16) or 0
    local b = tonumber(hex:sub(5, 6), 16) or 0
    return Color3.fromRGB(r, g, b)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Helpers: create UI elements
-- ═══════════════════════════════════════════════════════════════════════════════
local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or Theme.CornerRadius.MD)
    corner.Parent = instance
    return corner
end

local function addStroke(instance, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Colors.BorderDefault
    stroke.Transparency = transparency or 0
    stroke.Thickness = thickness or 1
    stroke.Parent = instance
    return stroke
end

local function createPanelCard(parent, title, size, position)
    local card = Instance.new("Frame")
    card.Name = "Card_" .. (title or "unnamed")
    card.Size = size or UDim2.new(1, 0, 1, 0)
    card.Position = position or UDim2.new(0, 0, 0, 0)
    card.BackgroundColor3 = Theme.Colors.PanelBackground
    card.BackgroundTransparency = Theme.Transparency.Panel
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    addCorner(card, Theme.CornerRadius.XL)
    addStroke(card, Theme.Colors.BorderDefault, 0.3)

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, Theme.Spacing.XXL)
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
-- Quick Colors (14 presets matching the website)
-- ═══════════════════════════════════════════════════════════════════════════════
local QUICK_COLORS = {
    { name = "White",     hex = "#ffffff" },
    { name = "Red",       hex = "#ff0000" },
    { name = "Orange",    hex = "#ff6600" },
    { name = "Yellow",    hex = "#ffcc00" },
    { name = "Green",     hex = "#33cc33" },
    { name = "Blue",      hex = "#0099ff" },
    { name = "Purple",    hex = "#6633ff" },
    { name = "Pink",      hex = "#ff33cc" },
    { name = "Hot Pink",  hex = "#ff6699" },
    { name = "Mint",      hex = "#99ffcc" },
    { name = "Light Gray",hex = "#cccccc" },
    { name = "Dark Gray", hex = "#666666" },
    { name = "Charcoal",  hex = "#333333" },
    { name = "Black",     hex = "#000000" },
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- Color Patterns
-- ═══════════════════════════════════════════════════════════════════════════════
local COLOR_PATTERNS = {
    { id = "rainbow",    name = "Rainbow" },
    { id = "warm",       name = "Warm" },
    { id = "cool",       name = "Cool" },
    { id = "neon",       name = "Neon" },
    { id = "pastel",     name = "Pastel" },
    { id = "monochrome", name = "Mono" },
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- Main Panel Constructor
-- ═══════════════════════════════════════════════════════════════════════════════

function CustomisationPanel.new(parent, store)
    local self = {}
    local connections = {}

    -- ─────────────────────────────────────────────────────────────────────────
    -- Root Frame
    -- ─────────────────────────────────────────────────────────────────────────
    local frame = Instance.new("Frame")
    frame.Name = "CustomisationPanel"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Visible = false
    frame.Parent = parent

    -- Main layout
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
    -- HEADER
    -- ═══════════════════════════════════════════════════════════════════════════
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "HeaderFrame"
    headerFrame.Size = UDim2.new(1, 0, 0, 80)
    headerFrame.BackgroundTransparency = 1
    headerFrame.BorderSizePixel = 0
    headerFrame.LayoutOrder = 1
    headerFrame.Parent = frame

    local headerTitle = Instance.new("TextLabel")
    headerTitle.Size = UDim2.new(0, 400, 0, Theme.FontSize.Large)
    headerTitle.Position = UDim2.new(0, 0, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Customisation"
    headerTitle.TextColor3 = Theme.Colors.TextPrimary
    headerTitle.TextSize = Theme.FontSize.Large
    headerTitle.Font = Theme.Font.FamilySemibold
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = headerFrame

    local headerSubtext = Instance.new("TextLabel")
    headerSubtext.Name = "Subtext"
    headerSubtext.Size = UDim2.new(0, 600, 0, Theme.FontSize.Label)
    headerSubtext.Position = UDim2.new(0, 0, 0, Theme.FontSize.Large + 8)
    headerSubtext.BackgroundTransparency = 1
    headerSubtext.Text = "No group selected"
    headerSubtext.TextColor3 = Theme.Colors.TextSubtle
    headerSubtext.TextSize = Theme.FontSize.Label
    headerSubtext.Font = Theme.Font.FamilyMedium
    headerSubtext.TextXAlignment = Enum.TextXAlignment.Left
    headerSubtext.Parent = headerFrame

    -- ═══════════════════════════════════════════════════════════════════════════
    -- MAIN CONTENT: Left + Right frames
    -- ═══════════════════════════════════════════════════════════════════════════
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -110)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.LayoutOrder = 2
    contentFrame.Parent = frame

    local contentList = Instance.new("UIListLayout")
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    contentList.FillDirection = Enum.FillDirection.Horizontal
    contentList.Padding = UDim.new(0, Theme.Spacing.PanelGap)
    contentList.Parent = contentFrame

    -- ═══════════════════════════════════════════════════════════════════════════
    -- LEFT FRAME: Color (width 560px = 280px * 2)
    -- ═══════════════════════════════════════════════════════════════════════════
    local colorCard = createPanelCard(contentFrame, "Color", UDim2.new(0, 560, 1, 0))
    colorCard.LayoutOrder = 1
    local colorContent = colorCard._content

    -- Scrollable content inside color panel
    local colorScroll = Instance.new("ScrollingFrame")
    colorScroll.Name = "ColorScroll"
    colorScroll.Size = UDim2.new(1, 0, 1, 0)
    colorScroll.BackgroundTransparency = 1
    colorScroll.BorderSizePixel = 0
    colorScroll.ScrollBarThickness = 0
    colorScroll.ScrollBarImageTransparency = 1
    colorScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    colorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    colorScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    colorScroll.Parent = colorContent

    local colorScrollPad = Instance.new("UIPadding")
    colorScrollPad.PaddingTop = UDim.new(0, Theme.Spacing.FramePadding)
    colorScrollPad.PaddingBottom = UDim.new(0, Theme.Spacing.FramePadding)
    colorScrollPad.PaddingLeft = UDim.new(0, Theme.Spacing.FramePadding)
    colorScrollPad.PaddingRight = UDim.new(0, Theme.Spacing.FramePadding)
    colorScrollPad.Parent = colorScroll

    local colorContentList = Instance.new("UIListLayout")
    colorContentList.SortOrder = Enum.SortOrder.LayoutOrder
    colorContentList.Padding = UDim.new(0, Theme.Spacing.XXL)
    colorContentList.Parent = colorScroll

    -- ─────────────────────────────────────────────────────────────────────────
    -- COLOR WHEEL + BRIGHTNESS SLIDER + PREVIEW
    -- ─────────────────────────────────────────────────────────────────────────
    local colorWheelSection = Instance.new("Frame")
    colorWheelSection.Name = "ColorWheelSection"
    colorWheelSection.Size = UDim2.new(1, 0, 0, 400)
    colorWheelSection.BackgroundTransparency = 1
    colorWheelSection.LayoutOrder = 1
    colorWheelSection.Parent = colorScroll

    -- Color wheel container (left) + brightness slider (right)
    local wheelLayout = Instance.new("Frame")
    wheelLayout.Name = "WheelLayout"
    wheelLayout.Size = UDim2.new(1, 0, 1, 0)
    wheelLayout.BackgroundTransparency = 1
    wheelLayout.Parent = colorWheelSection

    local wheelRow = Instance.new("UIListLayout")
    wheelRow.SortOrder = Enum.SortOrder.LayoutOrder
    wheelRow.FillDirection = Enum.FillDirection.Horizontal
    wheelRow.Padding = UDim.new(0, Theme.Spacing.Base)
    wheelRow.VerticalAlignment = Enum.VerticalAlignment.Top
    wheelRow.Parent = wheelLayout

    -- Color Wheel (360px diameter at 4K)
    local wheelSize = 360
    local wheelContainer = Instance.new("Frame")
    wheelContainer.Name = "ColorWheel"
    wheelContainer.Size = UDim2.new(0, wheelSize, 0, wheelSize)
    wheelContainer.BackgroundTransparency = 1
    wheelContainer.ClipsDescendants = false
    wheelContainer.LayoutOrder = 1
    wheelContainer.Parent = wheelLayout

    -- State
    local currentHue = store.customisation.colorHue or 0
    local currentSaturation = (store.customisation.colorSaturation or 0) * 100  -- 0-100
    local currentBrightness = (store.customisation.colorBrightness or 1) * 255  -- 0-255

    local outerRadius = wheelSize / 2 - 8
    local innerRadius = outerRadius - 48
    local ringWidth = outerRadius - innerRadius
    local center = wheelSize / 2
    local segments = 72
    local segmentAngle = 360 / segments

    -- Create hue ring segments
    for i = 0, segments - 1 do
        local angle = i * segmentAngle
        local angleRad = math.rad(angle)
        local nextAngleRad = math.rad(angle + segmentAngle)

        local segment = Instance.new("Frame")
        segment.Name = "RingSeg_" .. i
        segment.Size = UDim2.new(0, ringWidth + 6, 0, ringWidth + 6)
        segment.BackgroundColor3 = hsbToRgb(angle, 100, 100)
        segment.BackgroundTransparency = 0
        segment.BorderSizePixel = 0
        segment.Rotation = angle + segmentAngle / 2
        segment.ZIndex = 1

        local midRadius = (outerRadius + innerRadius) / 2
        local midAngle = angleRad + (nextAngleRad - angleRad) / 2
        local midX = center + midRadius * math.cos(midAngle) - (ringWidth + 6) / 2
        local midY = center + midRadius * math.sin(midAngle) - (ringWidth + 6) / 2
        segment.Position = UDim2.new(0, midX, 0, midY)
        addCorner(segment, 9999)
        segment.Parent = wheelContainer
    end

    -- Inner circle (saturation/brightness area)
    local innerSize = innerRadius * 2 - 12
    local innerCircle = Instance.new("Frame")
    innerCircle.Name = "InnerCircle"
    innerCircle.Size = UDim2.new(0, innerSize, 0, innerSize)
    innerCircle.Position = UDim2.new(0.5, -(innerSize / 2), 0.5, -(innerSize / 2))
    innerCircle.BackgroundColor3 = hsbToRgb(currentHue, currentSaturation, currentBrightness / 255 * 100)
    innerCircle.BackgroundTransparency = 0
    innerCircle.BorderSizePixel = 0
    innerCircle.ZIndex = 2
    addCorner(innerCircle, 9999)
    innerCircle.Parent = wheelContainer

    -- Hue indicator on ring
    local indicatorSize = 18
    local hueIndicator = Instance.new("Frame")
    hueIndicator.Name = "HueIndicator"
    hueIndicator.Size = UDim2.new(0, indicatorSize, 0, indicatorSize)
    hueIndicator.BackgroundColor3 = Theme.Colors.TextPrimary
    hueIndicator.BackgroundTransparency = 0
    hueIndicator.BorderSizePixel = 0
    hueIndicator.ZIndex = 10
    addCorner(hueIndicator, 9999)
    hueIndicator.Parent = wheelContainer

    local hueIndicatorInner = Instance.new("Frame")
    hueIndicatorInner.Size = UDim2.new(1, -4, 1, -4)
    hueIndicatorInner.Position = UDim2.new(0, 2, 0, 2)
    hueIndicatorInner.BackgroundColor3 = hsbToRgb(currentHue, 100, 100)
    hueIndicatorInner.BorderSizePixel = 0
    hueIndicatorInner.ZIndex = 11
    addCorner(hueIndicatorInner, 9999)
    hueIndicatorInner.Parent = hueIndicator

    -- ─── Brightness slider (right side) ───
    local brightColumn = Instance.new("Frame")
    brightColumn.Name = "BrightColumn"
    brightColumn.Size = UDim2.new(0, 60, 1, 0)
    brightColumn.BackgroundTransparency = 1
    brightColumn.LayoutOrder = 2
    brightColumn.Parent = wheelLayout

    local brightTrack = Instance.new("Frame")
    brightTrack.Name = "Track"
    brightTrack.Size = UDim2.new(0, 40, 0, 360)
    brightTrack.Position = UDim2.new(0.5, -20, 0, 20)
    brightTrack.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    brightTrack.BackgroundTransparency = 0
    brightTrack.BorderSizePixel = 0
    brightTrack.ZIndex = 2
    addCorner(brightTrack, 20)
    brightTrack.Parent = brightColumn

    -- Brightness gradient fill (white top, black bottom)
    local brightFill = Instance.new("Frame")
    brightFill.Size = UDim2.new(1, -4, 1, -4)
    brightFill.Position = UDim2.new(0, 2, 0, 2)
    brightFill.ClipsDescendants = true
    brightFill.BorderSizePixel = 0
    brightFill.ZIndex = 3
    brightFill.Parent = brightTrack
    addCorner(brightFill, 18)

    local brightTop = Instance.new("Frame")
    brightTop.Size = UDim2.new(1, 0, 0.5, 0)
    brightTop.BackgroundColor3 = Theme.Colors.TextPrimary
    brightTop.BackgroundTransparency = 0
    brightTop.BorderSizePixel = 0
    brightTop.ZIndex = 3
    brightTop.Parent = brightFill

    local brightBottom = Instance.new("Frame")
    brightBottom.Size = UDim2.new(1, 0, 0.5, 0)
    brightBottom.Position = UDim2.new(0, 0, 0.5, 0)
    brightBottom.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    brightBottom.BackgroundTransparency = 0
    brightBottom.BorderSizePixel = 0
    brightBottom.ZIndex = 3
    brightBottom.Parent = brightFill
    addCorner(brightBottom, 18)

    -- Brightness indicator (thumb)
    local brightThumb = Instance.new("Frame")
    brightThumb.Name = "Thumb"
    brightThumb.Size = UDim2.new(0, 48, 0, 12)
    brightThumb.BackgroundColor3 = Theme.Colors.TextPrimary
    brightThumb.BackgroundTransparency = 0
    brightThumb.BorderSizePixel = 0
    brightThumb.ZIndex = 10
    addCorner(brightThumb, 6)
    brightThumb.Parent = brightTrack

    -- Color preview (below brightness slider)
    local colorPreview = Instance.new("Frame")
    colorPreview.Name = "Preview"
    colorPreview.Size = UDim2.new(0, 40, 0, 40)
    colorPreview.Position = UDim2.new(0.5, -20, 1, -60)
    colorPreview.BackgroundColor3 = hsbToRgb(currentHue, currentSaturation, currentBrightness / 255 * 100)
    colorPreview.BorderSizePixel = 0
    colorPreview.ZIndex = 5
    addCorner(colorPreview, Theme.CornerRadius.SM)
    addStroke(colorPreview, Theme.Colors.BorderHover, 0, 2)
    colorPreview.Parent = brightColumn

    -- ═══════════════════════════════════════════════════════════════════════════
    -- Color Wheel / Brightness interaction
    -- ═══════════════════════════════════════════════════════════════════════════
    local isDraggingRing = false
    local isDraggingBright = false

    local function updateHueIndicator()
        local angleRad = math.rad(currentHue - 90)
        local midRadius = (outerRadius + innerRadius) / 2
        local ix = center + midRadius * math.cos(angleRad) - indicatorSize / 2
        local iy = center + midRadius * math.sin(angleRad) - indicatorSize / 2
        hueIndicator.Position = UDim2.new(0, ix, 0, iy)
        hueIndicatorInner.BackgroundColor3 = hsbToRgb(currentHue, 100, 100)
    end

    local function updateInnerCircle()
        innerCircle.BackgroundColor3 = hsbToRgb(currentHue, currentSaturation, currentBrightness / 255 * 100)
    end

    local function updateBrightThumb()
        local trackHeight = brightTrack.AbsoluteSize.Y
        if trackHeight <= 0 then return end
        local ratio = currentBrightness / 255
        local yPos = trackHeight * (1 - ratio) - 6
        brightThumb.Position = UDim2.new(0, -4, 0, math.clamp(yPos, 0, trackHeight - 12))
    end

    local function updatePreview()
        colorPreview.BackgroundColor3 = hsbToRgb(currentHue, currentSaturation, currentBrightness / 255 * 100)
    end

    local function updateAllColorUI()
        updateHueIndicator()
        updateInnerCircle()
        updateBrightThumb()
        updatePreview()
    end

    local function applyColorToStore()
        store:setColorHue(currentHue)
        store:setColorSaturation(currentSaturation / 100)
        store:setColorBrightness(currentBrightness / 255)
    end

    -- Ring drag
    local function getHueFromPosition(position)
        local relX = position.X - wheelContainer.AbsolutePosition.X - center
        local relY = position.Y - wheelContainer.AbsolutePosition.Y - center
        local dist = math.sqrt(relX * relX + relY * relY)
        if dist >= innerRadius - 30 and dist <= outerRadius + 30 then
            local angle = math.atan2(relY, relX) * (180 / math.pi) + 90
            if angle < 0 then angle = angle + 360 end
            currentHue = angle % 360
            updateHueIndicator()
            updateInnerCircle()
            updatePreview()
            applyColorToStore()
        end
    end

    table.insert(connections, wheelContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingRing = true
            getHueFromPosition(input.Position)
        end
    end))

    -- Brightness slider drag
    local function getBrightnessFromPosition(position)
        local relY = position.Y - brightTrack.AbsolutePosition.Y
        local trackHeight = brightTrack.AbsoluteSize.Y
        if trackHeight > 0 then
            local ratio = 1 - (relY / trackHeight)
            currentBrightness = math.clamp(math.round(ratio * 255), 0, 255)
            updateInnerCircle()
            updateBrightThumb()
            updatePreview()
            applyColorToStore()
        end
    end

    table.insert(connections, brightTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingBright = true
            getBrightnessFromPosition(input.Position)
        end
    end))

    -- Global input tracking
    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingRing = false
            isDraggingBright = false
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if isDraggingRing then
                getHueFromPosition(input.Position)
            elseif isDraggingBright then
                getBrightnessFromPosition(input.Position)
            end
        end
    end))

    -- ═══════════════════════════════════════════════════════════════════════════
    -- SELECTION BUTTONS (3-column grid: All, Odd, Even, Left, Right, Reset)
    -- ═══════════════════════════════════════════════════════════════════════════
    local selectionSection = Instance.new("Frame")
    selectionSection.Name = "SelectionSection"
    selectionSection.Size = UDim2.new(1, 0, 0, 0)
    selectionSection.AutomaticSize = Enum.AutomaticSize.Y
    selectionSection.BackgroundTransparency = 1
    selectionSection.LayoutOrder = 2
    selectionSection.Parent = colorScroll

    local selectionList = Instance.new("UIListLayout")
    selectionList.SortOrder = Enum.SortOrder.LayoutOrder
    selectionList.Padding = UDim.new(0, Theme.Spacing.Base)
    selectionList.Parent = selectionSection

    -- Section label
    local selectionLabel = Instance.new("TextLabel")
    selectionLabel.Size = UDim2.new(1, 0, 0, Theme.FontSize.Tiny + 24)
    selectionLabel.BackgroundTransparency = 1
    selectionLabel.Text = "SELECTION"
    selectionLabel.TextColor3 = Theme.Colors.TextSubtle
    selectionLabel.TextSize = Theme.FontSize.Tiny
    selectionLabel.Font = Theme.Font.FamilySemibold
    selectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectionLabel.LayoutOrder = 1
    selectionLabel.Parent = selectionSection

    -- Selection buttons grid
    local selectionGrid = Instance.new("Frame")
    selectionGrid.Size = UDim2.new(1, 0, 0, 0)
    selectionGrid.AutomaticSize = Enum.AutomaticSize.Y
    selectionGrid.BackgroundTransparency = 1
    selectionGrid.LayoutOrder = 2
    selectionGrid.Parent = selectionSection

    local selGridLayout = Instance.new("UIGridLayout")
    selGridLayout.CellSize = UDim2.new(0, 160, 0, 36)
    selGridLayout.CellPadding = UDim2.new(0, Theme.Spacing.SM, 0, Theme.Spacing.SM)
    selGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    selGridLayout.Parent = selectionGrid

    local selectionButtons = {
        { label = "All",   action = function() end },
        { label = "Odd",   action = function() end },
        { label = "Even",  action = function() end },
        { label = "Left",  action = function() end },
        { label = "Right", action = function() end },
        { label = "Reset", action = function() end },
    }

    local activeSelectionBtn = nil

    for i, selDef in ipairs(selectionButtons) do
        local btn = Instance.new("TextButton")
        btn.Name = "Sel_" .. selDef.label
        btn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        btn.BackgroundTransparency = 0.8
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = selDef.label
        btn.TextColor3 = Theme.Colors.TextMuted
        btn.TextSize = Theme.FontSize.Label
        btn.Font = Theme.Font.FamilyMedium
        btn.Parent = selectionGrid
        addCorner(btn, Theme.CornerRadius.MD)
        addStroke(btn, Theme.Colors.BorderDefault, 0.4)

        table.insert(connections, btn.Activated:Connect(function()
            if not store:hasSelectedGroups() then
                store:emit("toast", { message = "Select a group first", type = "warning" })
                return
            end
            selDef.action()
            -- Visual feedback: flash active
            if activeSelectionBtn and activeSelectionBtn ~= btn then
                TweenService:Create(activeSelectionBtn, TweenInfo.new(Theme.Animation.Fast), {
                    BackgroundTransparency = 0.8,
                    BackgroundColor3 = Color3.fromRGB(10, 10, 10),
                    TextColor3 = Theme.Colors.TextMuted,
                }):Play()
                local s = activeSelectionBtn:FindFirstChildOfClass("UIStroke")
                if s then s.Color = Theme.Colors.BorderDefault s.Transparency = 0.4 end
            end
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundTransparency = 0.5,
                BackgroundColor3 = Color3.fromRGB(38, 38, 38),
                TextColor3 = Theme.Colors.TextPrimary,
            }):Play()
            local st = btn:FindFirstChildOfClass("UIStroke")
            if st then st.Color = Theme.Colors.BorderHover st.Transparency = 0 end
            activeSelectionBtn = btn
        end))

        -- Hover
        table.insert(connections, btn.MouseEnter:Connect(function()
            if btn ~= activeSelectionBtn then
                TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                    BackgroundTransparency = 0.95,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    TextColor3 = Theme.Colors.TextSecondary,
                }):Play()
                local st = btn:FindFirstChildOfClass("UIStroke")
                if st then st.Color = Theme.Colors.BorderHover end
            end
        end))
        table.insert(connections, btn.MouseLeave:Connect(function()
            if btn ~= activeSelectionBtn then
                TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                    BackgroundTransparency = 0.8,
                    BackgroundColor3 = Color3.fromRGB(10, 10, 10),
                    TextColor3 = Theme.Colors.TextMuted,
                }):Play()
                local st = btn:FindFirstChildOfClass("UIStroke")
                if st then st.Color = Theme.Colors.BorderDefault st.Transparency = 0.4 end
            end
        end))
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- QUICK COLORS (14 presets in 7-column grid)
    -- ═══════════════════════════════════════════════════════════════════════════
    local quickColorsSection = Instance.new("Frame")
    quickColorsSection.Name = "QuickColorsSection"
    quickColorsSection.Size = UDim2.new(1, 0, 0, 0)
    quickColorsSection.AutomaticSize = Enum.AutomaticSize.Y
    quickColorsSection.BackgroundTransparency = 1
    quickColorsSection.LayoutOrder = 3
    quickColorsSection.Parent = colorScroll

    local qcList = Instance.new("UIListLayout")
    qcList.SortOrder = Enum.SortOrder.LayoutOrder
    qcList.Padding = UDim.new(0, Theme.Spacing.Base)
    qcList.Parent = quickColorsSection

    local qcLabel = Instance.new("TextLabel")
    qcLabel.Size = UDim2.new(1, 0, 0, Theme.FontSize.Tiny + 24)
    qcLabel.BackgroundTransparency = 1
    qcLabel.Text = "QUICK COLORS"
    qcLabel.TextColor3 = Theme.Colors.TextSubtle
    qcLabel.TextSize = Theme.FontSize.Tiny
    qcLabel.Font = Theme.Font.FamilySemibold
    qcLabel.TextXAlignment = Enum.TextXAlignment.Left
    qcLabel.LayoutOrder = 1
    qcLabel.Parent = quickColorsSection

    local qcGrid = Instance.new("Frame")
    qcGrid.Size = UDim2.new(1, 0, 0, 0)
    qcGrid.AutomaticSize = Enum.AutomaticSize.Y
    qcGrid.BackgroundTransparency = 1
    qcGrid.LayoutOrder = 2
    qcGrid.Parent = quickColorsSection

    local qcGridLayout = Instance.new("UIGridLayout")
    qcGridLayout.CellSize = UDim2.new(0, 48, 0, 48)
    qcGridLayout.CellPadding = UDim.new(0, Theme.Spacing.SM, 0, Theme.Spacing.SM)
    qcGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    qcGridLayout.Parent = qcGrid

    local activeQuickColor = nil

    for i, qc in ipairs(QUICK_COLORS) do
        local swatch = Instance.new("TextButton")
        swatch.Name = "QuickColor_" .. qc.name:gsub(" ", "_")
        swatch.BackgroundColor3 = hexToColor3(qc.hex)
        swatch.BackgroundTransparency = 0
        swatch.BorderSizePixel = 0
        swatch.AutoButtonColor = false
        swatch.Text = ""
        swatch.Parent = qcGrid
        addCorner(swatch, 16) -- rounded-lg at 4K = 16px

        -- Selected state border
        local swatchStroke = addStroke(swatch, Theme.Colors.TextPrimary, 1, 0)

        table.insert(connections, swatch.Activated:Connect(function()
            if not store:hasSelectedGroups() then
                store:emit("toast", { message = "Select a group first", type = "warning" })
                return
            end
            -- Update selection visual
            if activeQuickColor and activeQuickColor ~= swatch then
                TweenService:Create(activeQuickColor, TweenInfo.new(Theme.Animation.Fast), {
                    Size = UDim2.new(0, 48, 0, 48),
                }):Play()
                local prevStroke = activeQuickColor:FindFirstChildOfClass("UIStroke")
                if prevStroke then prevStroke.Transparency = 1 end
            end
            TweenService:Create(swatch, TweenInfo.new(Theme.Animation.Medium), {
                Size = UDim2.new(0, 50, 0, 50),
            }):Play()
            swatchStroke.Transparency = 0
            activeQuickColor = swatch

            -- Apply color
            local color = hexToColor3(qc.hex)
            local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
            -- Convert to HSB approximately
            local maxC = math.max(r, g, b) / 255
            local minC = math.min(r, g, b) / 255
            local delta = maxC - minC
            currentBrightness = math.round(maxC * 255)
            if delta == 0 then
                currentHue = 0
                currentSaturation = 0
            else
                if maxC == r / 255 then
                    currentHue = 60 * (((g / 255 - b / 255) / delta) % 6)
                elseif maxC == g / 255 then
                    currentHue = 60 * (((b / 255 - r / 255) / delta) + 2)
                else
                    currentHue = 60 * (((r / 255 - g / 255) / delta) + 4)
                end
                if currentHue < 0 then currentHue = currentHue + 360 end
                currentSaturation = maxC > 0 and math.round((delta / maxC) * 100) or 0
            end
            updateAllColorUI()
            applyColorToStore()
        end))

        -- Hover scale
        table.insert(connections, swatch.MouseEnter:Connect(function()
            if swatch ~= activeQuickColor then
                TweenService:Create(swatch, TweenInfo.new(Theme.Animation.Fast), {
                    Size = UDim2.new(0, 52, 0, 52),
                }):Play()
            end
        end))
        table.insert(connections, swatch.MouseLeave:Connect(function()
            if swatch ~= activeQuickColor then
                TweenService:Create(swatch, TweenInfo.new(Theme.Animation.Fast), {
                    Size = UDim2.new(0, 48, 0, 48),
                }):Play()
            end
        end))
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- COLOR PATTERNS (3-column grid: Rainbow, Warm, Cool, Neon, Pastel, Mono)
    -- ═══════════════════════════════════════════════════════════════════════════
    local patternsSection = Instance.new("Frame")
    patternsSection.Name = "PatternsSection"
    patternsSection.Size = UDim2.new(1, 0, 0, 0)
    patternsSection.AutomaticSize = Enum.AutomaticSize.Y
    patternsSection.BackgroundTransparency = 1
    patternsSection.LayoutOrder = 4
    patternsSection.Parent = colorScroll

    local patList = Instance.new("UIListLayout")
    patList.SortOrder = Enum.SortOrder.LayoutOrder
    patList.Padding = UDim.new(0, Theme.Spacing.BASE)
    patList.Parent = patternsSection

    local patLabel = Instance.new("TextLabel")
    patLabel.Size = UDim2.new(1, 0, 0, Theme.FontSize.Tiny + 24)
    patLabel.BackgroundTransparency = 1
    patLabel.Text = "COLOR PATTERNS"
    patLabel.TextColor3 = Theme.Colors.TextSubtle
    patLabel.TextSize = Theme.FontSize.Tiny
    patLabel.Font = Theme.Font.FamilySemibold
    patLabel.TextXAlignment = Enum.TextXAlignment.Left
    patLabel.LayoutOrder = 1
    patLabel.Parent = patternsSection

    local patGrid = Instance.new("Frame")
    patGrid.Size = UDim2.new(1, 0, 0, 0)
    patGrid.AutomaticSize = Enum.AutomaticSize.Y
    patGrid.BackgroundTransparency = 1
    patGrid.LayoutOrder = 2
    patGrid.Parent = patternsSection

    local patGridLayout = Instance.new("UIGridLayout")
    patGridLayout.CellSize = UDim2.new(0, 160, 0, 36)
    patGridLayout.CellPadding = UDim.new(0, Theme.Spacing.SM, 0, Theme.Spacing.SM)
    patGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    patGridLayout.Parent = patGrid

    for i, pattern in ipairs(COLOR_PATTERNS) do
        local btn = Instance.new("TextButton")
        btn.Name = "Pattern_" .. pattern.id
        btn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        btn.BackgroundTransparency = 0.8
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = pattern.name
        btn.TextColor3 = Theme.Colors.TextMuted
        btn.TextSize = Theme.FontSize.Label
        btn.Font = Theme.Font.FamilyMedium
        btn.Parent = patGrid
        addCorner(btn, Theme.CornerRadius.MD)
        addStroke(btn, Theme.Colors.BorderDefault, 0.4)

        table.insert(connections, btn.Activated:Connect(function()
            if not store:hasSelectedGroups() then
                store:emit("toast", { message = "Select a group first", type = "warning" })
                return
            end
            -- Apply pattern - for now, apply preset hue based on pattern
            if pattern.id == "rainbow" then
                currentHue = 0; currentSaturation = 100; currentBrightness = 255
            elseif pattern.id == "warm" then
                currentHue = 30; currentSaturation = 100; currentBrightness = 255
            elseif pattern.id == "cool" then
                currentHue = 210; currentSaturation = 100; currentBrightness = 255
            elseif pattern.id == "neon" then
                currentHue = 300; currentSaturation = 100; currentBrightness = 255
            elseif pattern.id == "pastel" then
                currentHue = 180; currentSaturation = 40; currentBrightness = 255
            elseif pattern.id == "monochrome" then
                currentHue = 0; currentSaturation = 0; currentBrightness = 255
            end
            updateAllColorUI()
            applyColorToStore()
        end))

        -- Hover
        table.insert(connections, btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundTransparency = 0.95,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                TextColor3 = Theme.Colors.TextSecondary,
            }):Play()
            local st = btn:FindFirstChildOfClass("UIStroke")
            if st then st.Color = Theme.Colors.BorderHover end
        end))
        table.insert(connections, btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundTransparency = 0.8,
                BackgroundColor3 = Color3.fromRGB(10, 10, 10),
                TextColor3 = Theme.Colors.TextMuted,
            }):Play()
            local st = btn:FindFirstChildOfClass("UIStroke")
            if st then st.Color = Theme.Colors.BorderDefault st.Transparency = 0.4 end
        end))
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- RIGHT FRAME: Faders (flex width)
    -- ═══════════════════════════════════════════════════════════════════════════
    local fadersCard = createPanelCard(contentFrame, "Faders", UDim2.new(1, -560 - Theme.Spacing.PanelGap, 1, 0))
    fadersCard.LayoutOrder = 2
    local fadersContent = fadersCard._content

    -- Faders scroll area
    local fadersScroll = Instance.new("ScrollingFrame")
    fadersScroll.Name = "FadersScroll"
    fadersScroll.Size = UDim2.new(1, 0, 1, 0)
    fadersScroll.BackgroundTransparency = 1
    fadersScroll.BorderSizePixel = 0
    fadersScroll.ScrollBarThickness = 0
    fadersScroll.ScrollBarImageTransparency = 1
    fadersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    fadersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    fadersScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    fadersScroll.Parent = fadersContent

    local fadersScrollPad = Instance.new("UIPadding")
    fadersScrollPad.PaddingTop = UDim.new(0, Theme.Spacing.FramePadding)
    fadersScrollPad.PaddingBottom = UDim.new(0, Theme.Spacing.FramePadding)
    fadersScrollPad.PaddingLeft = UDim.new(0, Theme.Spacing.FramePadding)
    fadersScrollPad.PaddingRight = UDim.new(0, Theme.Spacing.FramePadding)
    fadersScrollPad.Parent = fadersScroll

    -- Faders grid (3-column)
    local fadersGrid = Instance.new("Frame")
    fadersGrid.Name = "FadersGrid"
    fadersGrid.Size = UDim2.new(1, 0, 0, 0)
    fadersGrid.AutomaticSize = Enum.AutomaticSize.Y
    fadersGrid.BackgroundTransparency = 1
    fadersGrid.Parent = fadersScroll

    local fadersGridLayout = Instance.new("UIGridLayout")
    fadersGridLayout.CellSize = UDim2.new(0.333, -24, 0, 80)
    fadersGridLayout.CellPadding = UDim.new(0, 0, 0, Theme.Spacing.XXL)
    fadersGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    fadersGridLayout.Parent = fadersGrid

    -- Create 9 faders
    local faderDefs = Theme.Faders
    local faderInstances = {} -- faderId -> { sliderTrack, thumb, fill, valueLabel }

    for i, faderDef in ipairs(faderDefs) do
        local faderFrame = Instance.new("Frame")
        faderFrame.Name = "Fader_" .. faderDef.id
        faderFrame.BackgroundTransparency = 1
        faderFrame.ClipsDescendants = true
        faderFrame.Parent = fadersGrid

        -- Label + Value row
        local labelRow = Instance.new("Frame")
        labelRow.Name = "LabelRow"
        labelRow.Size = UDim2.new(1, 0, 0, Theme.FontSize.Tiny + 12)
        labelRow.BackgroundTransparency = 1
        labelRow.Parent = faderFrame

        local faderLabel = Instance.new("TextLabel")
        faderLabel.Name = "Label"
        faderLabel.Size = UDim2.new(0.5, 0, 1, 0)
        faderLabel.BackgroundTransparency = 1
        faderLabel.Text = faderDef.name
        faderLabel.TextColor3 = Theme.Colors.TextMuted
        faderLabel.TextSize = Theme.FontSize.Tiny
        faderLabel.Font = Theme.Font.FamilySemibold
        faderLabel.TextXAlignment = Enum.TextXAlignment.Left
        faderLabel.Parent = labelRow

        local faderValueLabel = Instance.new("TextLabel")
        faderValueLabel.Name = "Value"
        faderValueLabel.Size = UDim2.new(0.5, 0, 1, 0)
        faderValueLabel.Position = UDim2.new(0.5, 0, 0, 0)
        faderValueLabel.BackgroundTransparency = 1
        faderValueLabel.Text = tostring(faderDef.default)
        faderValueLabel.TextColor3 = Theme.Colors.TextBody
        faderValueLabel.TextSize = Theme.FontSize.Tiny
        faderValueLabel.Font = Theme.Font.Mono
        faderValueLabel.TextXAlignment = Enum.TextXAlignment.Right
        faderValueLabel.Parent = labelRow

        -- Slider track area
        local trackArea = Instance.new("Frame")
        trackArea.Name = "TrackArea"
        trackArea.Size = UDim2.new(1, 0, 0, 24)
        trackArea.Position = UDim2.new(0, 0, 1, -24)
        trackArea.BackgroundTransparency = 1
        trackArea.Parent = faderFrame

        -- Track
        local sliderTrack = Instance.new("Frame")
        sliderTrack.Name = "Track"
        sliderTrack.Size = UDim2.new(1, 0, 0, 12)
        sliderTrack.Position = UDim2.new(0, 0, 0.5, 0)
        sliderTrack.AnchorPoint = Vector2.new(0, 0.5)
        sliderTrack.BackgroundColor3 = Theme.Colors.FaderTrack
        sliderTrack.BackgroundTransparency = 0
        sliderTrack.BorderSizePixel = 0
        sliderTrack.Parent = trackArea
        addCorner(sliderTrack, 9999)

        -- Fill
        local sliderFill = Instance.new("Frame")
        sliderFill.Name = "Fill"
        sliderFill.Size = UDim2.new(0, 0, 1, 0)
        sliderFill.BackgroundColor3 = Theme.Colors.FaderFill
        sliderFill.BackgroundTransparency = 0
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderTrack
        addCorner(sliderFill, 9999)

        -- Thumb
        local sliderThumb = Instance.new("Frame")
        sliderThumb.Name = "Thumb"
        sliderThumb.Size = UDim2.new(0, 24, 0, 24)
        sliderThumb.Position = UDim2.new(0, 0, 0.5, 0)
        sliderThumb.AnchorPoint = Vector2.new(0, 0.5)
        sliderThumb.BackgroundColor3 = Theme.Colors.FaderKnob
        sliderThumb.BackgroundTransparency = 0
        sliderThumb.BorderSizePixel = 0
        sliderThumb.ZIndex = 5
        sliderThumb.Parent = trackArea
        addCorner(sliderThumb, 9999)

        -- Store reference
        faderInstances[faderDef.id] = {
            track = sliderTrack,
            fill = sliderFill,
            thumb = sliderThumb,
            valueLabel = faderValueLabel,
            faderId = faderDef.id,
            min = faderDef.min,
            max = faderDef.max,
        }

        -- Drag logic
        local isDragging = false
        local currentValue = store:getFaderValue(faderDef.id) or faderDef.default

        local function updateFaderVisuals()
            local range = faderDef.max - faderDef.min
            local pct = range > 0 and (currentValue - faderDef.min) / range or 0
            pct = math.clamp(pct, 0, 1)
            local trackWidth = sliderTrack.AbsoluteSize.X
            if trackWidth > 0 then
                local thumbOffset = pct * trackWidth - 12
                sliderThumb.Position = UDim2.new(0, thumbOffset, 0.5, 0)
            end
            sliderFill.Size = UDim2.new(pct, 0, 1, 0)
            faderValueLabel.Text = tostring(math.round(currentValue))
        end

        local function setValueFromX(x)
            local trackWidth = sliderTrack.AbsoluteSize.X
            if trackWidth <= 0 then return end
            local localX = x - sliderTrack.AbsolutePosition.X
            local pct = math.clamp(localX / trackWidth, 0, 1)
            local range = faderDef.max - faderDef.min
            currentValue = math.round(faderDef.min + pct * range)
            currentValue = math.clamp(currentValue, faderDef.min, faderDef.max)
            updateFaderVisuals()
            store:setFaderValue(faderDef.id, currentValue)
        end

        -- Drag handlers
        table.insert(connections, trackArea.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                setValueFromX(input.Position.X)
            end
        end))
        table.insert(connections, sliderThumb.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                setValueFromX(input.Position.X)
            end
        end))

        table.insert(connections, UserInputService.InputEnded:Connect(function(input)
            if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                isDragging = false
            end
        end))

        table.insert(connections, UserInputService.InputChanged:Connect(function(input)
            if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                setValueFromX(input.Position.X)
            end
        end))

        -- Thumb hover
        table.insert(connections, sliderThumb.MouseEnter:Connect(function()
            if not isDragging then
                TweenService:Create(sliderThumb, TweenInfo.new(Theme.Animation.Fast), {
                    Size = UDim2.new(0, 28, 0, 28),
                }):Play()
            end
        end))
        table.insert(connections, sliderThumb.MouseLeave:Connect(function()
            if not isDragging then
                TweenService:Create(sliderThumb, TweenInfo.new(Theme.Animation.Fast), {
                    Size = UDim2.new(0, 24, 0, 24),
                }):Play()
            end
        end))

        -- Initial render
        task.defer(function()
            updateFaderVisuals()
        end)
        table.insert(connections, sliderTrack:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            updateFaderVisuals()
        end))
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- STORE EVENT LISTENERS
    -- ═══════════════════════════════════════════════════════════════════════════

    -- Customisation changed (color/faders from external)
    table.insert(connections, store:on("customisationChanged", function(cust)
        currentHue = cust.colorHue or 0
        currentSaturation = (cust.colorSaturation or 0) * 100
        currentBrightness = (cust.colorBrightness or 1) * 255
        updateAllColorUI()

        -- Update fader visuals
        for faderId, faderData in pairs(faderInstances) do
            local val = cust.faders[faderId]
            if val ~= nil then
                local range = faderData.max - faderData.min
                local pct = range > 0 and (val - faderData.min) / range or 0
                pct = math.clamp(pct, 0, 1)
                local trackWidth = faderData.track.AbsoluteSize.X
                if trackWidth > 0 then
                    faderData.thumb.Position = UDim2.new(0, pct * trackWidth - 12, 0.5, 0)
                end
                faderData.fill.Size = UDim2.new(pct, 0, 1, 0)
                faderData.valueLabel.Text = tostring(math.round(val))
            end
        end
    end))

    -- Group selection changed (update header subtext)
    table.insert(connections, store:on("groupSelectionChanged", function(selectedIds)
        if #selectedIds > 0 then
            local names = {}
            for _, id in ipairs(selectedIds) do
                for _, g in ipairs(store.groups) do
                    if g.id == id then
                        table.insert(names, g.name)
                        break
                    end
                end
            end
            headerSubtext.Text = table.concat(names, ", ")
            headerSubtext.TextColor3 = Theme.Colors.TextSubtle
        else
            headerSubtext.Text = #store.groups > 0 and "No group selected" or "No groups -- create one first"
            headerSubtext.TextColor3 = Theme.Colors.TextSubtle
        end
    end))

    table.insert(connections, store:on("groupsChanged", function()
        if not store:hasSelectedGroups() then
            headerSubtext.Text = #store.groups > 0 and "No group selected" or "No groups -- create one first"
            headerSubtext.TextColor3 = Theme.Colors.TextSubtle
        end
    end))

    -- ═══════════════════════════════════════════════════════════════════════════
    -- Initial render
    -- ═══════════════════════════════════════════════════════════════════════════
    task.defer(function()
        updateAllColorUI()
        -- Update header subtext
        if store:hasSelectedGroups() then
            local names = {}
            for _, id in ipairs(store.selectedGroupIds) do
                for _, g in ipairs(store.groups) do
                    if g.id == id then
                        table.insert(names, g.name)
                        break
                    end
                end
            end
            headerSubtext.Text = table.concat(names, ", ")
        end
    end)

    -- ═══════════════════════════════════════════════════════════════════════════
    -- Public API
    -- ═══════════════════════════════════════════════════════════════════════════
    function self:show()
        frame.Visible = true
        frame.BackgroundTransparency = 1
        TweenHelper.fadeIn(frame, Theme.Animation.PanelFadeIn)
        -- Re-sync UI with store
        currentHue = store.customisation.colorHue or 0
        currentSaturation = (store.customisation.colorSaturation or 0) * 100
        currentBrightness = (store.customisation.colorBrightness or 1) * 255
        updateAllColorUI()
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

return CustomisationPanel
