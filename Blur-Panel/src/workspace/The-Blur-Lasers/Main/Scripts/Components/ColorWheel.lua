--[[
    ColorWheel.lua — Color Wheel Picker Component
    The-Blur Roblox SurfaceGUI  |  4K (3840×2160)

    Approximates a color wheel using UI elements:
        - Hue ring: colored frames arranged in a circle
        - Inner saturation/brightness: simplified gradient square
        - Selected color indicator
        - Brightness slider bar

    Usage:
        local ColorWheel = require(script.Parent.ColorWheel)
        local wheel = ColorWheel.new(parent, {
            size = 360,
            position = UDim2.new(0, 0, 0, 0),
            onColorChange = function(hue, saturation, brightness) print(hue, s, b) end,
        })
        local h, s, b = wheel:getColor()
        wheel:setColor(180, 100, 255)
        wheel:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ColorWheel = {}
local HSBtoRGB, RGBtoHSB

-- HSB to RGB conversion
function HSBtoRGB(h, s, b)
    h = h % 360
    s = math.clamp(s, 0, 100) / 100
    b = math.clamp(b, 0, 100) / 100

    local c = b * s
    local x = c * (1 - math.abs(((h / 60) % 2) - 1))
    local m = b - c

    local r, g, bl

    if h < 60 then
        r, g, bl = c, x, 0
    elseif h < 120 then
        r, g, bl = x, c, 0
    elseif h < 180 then
        r, g, bl = 0, c, x
    elseif h < 240 then
        r, g, bl = 0, x, c
    elseif h < 300 then
        r, g, bl = x, 0, c
    else
        r, g, bl = c, 0, x
    end

    return Color3.fromRGB(
        math.round((r + m) * 255),
        math.round((g + m) * 255),
        math.round((bl + m) * 255)
    )
end

function ColorWheel.new(parent, config)
    config = config or {}
    local connections = {}

    local wheelSize = config.size or Theme.ColorWheel.Size
    local currentHue = config.hue or 0
    local currentSaturation = config.saturation or 100
    local currentBrightness = config.brightness or 100
    local onColorChange = config.onColorChange

    -- === Root Frame ===
    local root = Instance.new("Frame")
    root.Name = "ColorWheel"
    root.Size = UDim2.new(0, wheelSize + 80, 0, wheelSize) -- Extra space for brightness slider
    root.Position = config.position or UDim2.new(0, 0, 0, 0)
    root.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    root.BackgroundTransparency = 1
    root.Parent = parent

    -- === Hue Ring ===
    local ringContainer = Instance.new("Frame")
    ringContainer.Name = "RingContainer"
    ringContainer.Size = UDim2.new(0, wheelSize, 0, wheelSize)
    ringContainer.BackgroundTransparency = 1
    ringContainer.ClipsDescendants = false
    ringContainer.Parent = root

    local center = wheelSize / 2
    local outerRadius = Theme.ColorWheel.OuterRadius
    local innerRadius = Theme.ColorWheel.InnerRadius
    local ringWidth = outerRadius - innerRadius
    local segments = Theme.ColorWheel.Segments
    local segmentAngle = 360 / segments

    -- Create ring segments
    for i = 0, segments - 1 do
        local angle = i * segmentAngle
        local angleRad = math.rad(angle)
        local nextAngleRad = math.rad(angle + segmentAngle)

        local segment = Instance.new("Frame")
        segment.Name = "Segment_" .. i
        segment.Size = UDim2.new(0, ringWidth + 4, 0, ringWidth + 4)
        segment.BackgroundColor3 = HSBtoRGB(angle, 100, 100)
        segment.BackgroundTransparency = 0
        segment.BorderSizePixel = 0
        segment.Rotation = angle + segmentAngle / 2
        segment.ZIndex = 1

        -- Position at midpoint of ring
        local midRadius = (outerRadius + innerRadius) / 2
        local midAngle = angleRad + (nextAngleRad - angleRad) / 2
        local midX = center + midRadius * math.cos(midAngle) - (ringWidth + 4) / 2
        local midY = center + midRadius * math.sin(midAngle) - (ringWidth + 4) / 2
        segment.Position = UDim2.new(0, midX, 0, midY)

        local segCorner = Instance.new("UICorner")
        segCorner.CornerRadius = UDim.new(1, 0)
        segCorner.Parent = segment

        segment.Parent = ringContainer
    end

    -- Inner circle (saturation/brightness area)
    local innerCircle = Instance.new("Frame")
    innerCircle.Name = "InnerCircle"
    innerCircle.Size = UDim2.new(0, innerRadius * 2 - 8, 0, innerRadius * 2 - 8)
    innerCircle.Position = UDim2.new(0.5, -(innerRadius - 4), 0.5, -(innerRadius - 4))
    innerCircle.AnchorPoint = Vector2.new(0, 0)
    innerCircle.BackgroundColor3 = HSBtoRGB(currentHue, currentSaturation, currentBrightness)
    innerCircle.BackgroundTransparency = 0
    innerCircle.BorderSizePixel = 0
    innerCircle.ZIndex = 2

    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(1, 0)
    innerCorner.Parent = innerCircle
    innerCircle.Parent = ringContainer

    -- Gradient overlay on inner circle (saturation gradient left to right)
    local satGradient = Instance.new("Frame")
    satGradient.Name = "SatGradient"
    satGradient.Size = UDim2.new(1, 0, 1, 0)
    satGradient.BackgroundTransparency = 0
    satGradient.BorderSizePixel = 0
    satGradient.ZIndex = 3

    -- Create a simple 2-column gradient for saturation
    local satLeft = Instance.new("Frame")
    satLeft.Size = UDim2.new(0.5, 0, 1, 0)
    satLeft.Position = UDim2.new(0, 0, 0, 0)
    satLeft.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    satLeft.BackgroundTransparency = 0
    satLeft.BorderSizePixel = 0
    satLeft.ZIndex = 3
    satLeft.Parent = satGradient

    local satRight = Instance.new("Frame")
    satRight.Size = UDim2.new(0.5, 0, 1, 0)
    satRight.Position = UDim2.new(0.5, 0, 0, 0)
    satRight.BackgroundColor3 = HSBtoRGB(currentHue, 100, 100)
    satRight.BackgroundTransparency = 0
    satRight.BorderSizePixel = 0
    satRight.ZIndex = 3
    satRight.Parent = satGradient

    local satCorner = Instance.new("UICorner")
    satCorner.CornerRadius = UDim.new(1, 0)
    satCorner.Parent = satGradient

    -- Brightness overlay (top=white, bottom=black)
    local brightGradient = Instance.new("Frame")
    brightGradient.Name = "BrightGradient"
    brightGradient.Size = UDim2.new(1, 0, 1, 0)
    brightGradient.BackgroundTransparency = 0
    brightGradient.BorderSizePixel = 0
    brightGradient.ZIndex = 4

    local brightTop = Instance.new("Frame")
    brightTop.Size = UDim2.new(1, 0, 0.5, 0)
    brightTop.Position = UDim2.new(0, 0, 0, 0)
    brightTop.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    brightTop.BackgroundTransparency = 0.7 -- subtle white
    brightTop.BorderSizePixel = 0
    brightTop.ZIndex = 4
    brightTop.Parent = brightGradient

    local brightBottom = Instance.new("Frame")
    brightBottom.Size = UDim2.new(1, 0, 0.5, 0)
    brightBottom.Position = UDim2.new(0, 0, 0.5, 0)
    brightBottom.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    brightBottom.BackgroundTransparency = 0.3 -- more visible dark
    brightBottom.BorderSizePixel = 0
    brightBottom.ZIndex = 4
    brightBottom.Parent = brightGradient

    local brightCorner = Instance.new("UICorner")
    brightCorner.CornerRadius = UDim.new(1, 0)
    brightCorner.Parent = brightGradient

    satGradient.Parent = innerCircle
    brightGradient.Parent = innerCircle

    -- === Hue Indicator on ring ===
    local hueIndicator = Instance.new("Frame")
    hueIndicator.Name = "HueIndicator"
    local indicatorSize = Theme.ColorWheel.IndicatorSize + 4
    hueIndicator.Size = UDim2.new(0, indicatorSize, 0, indicatorSize)
    hueIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hueIndicator.BackgroundTransparency = 0
    hueIndicator.BorderSizePixel = 0
    hueIndicator.ZIndex = 10

    local hueInner = Instance.new("Frame")
    hueInner.Size = UDim2.new(1, -4, 1, -4)
    hueInner.Position = UDim2.new(0, 2, 0, 2)
    hueInner.BackgroundColor3 = HSBtoRGB(currentHue, 100, 100)
    hueInner.BorderSizePixel = 0
    hueInner.ZIndex = 11
    hueInner.Parent = hueIndicator

    local hueICorner = Instance.new("UICorner")
    hueICorner.CornerRadius = UDim.new(1, 0)
    hueICorner.Parent = hueIndicator

    local hueICorner2 = Instance.new("UICorner")
    hueICorner2.CornerRadius = UDim.new(1, 0)
    hueICorner2.Parent = hueInner

    hueIndicator.Parent = ringContainer

    -- === Brightness Slider (right side) ===
    local brightSliderArea = Instance.new("Frame")
    brightSliderArea.Name = "BrightnessSlider"
    brightSliderArea.Size = UDim2.new(0, 40, 0, wheelSize)
    brightSliderArea.Position = UDim2.new(1, -40, 0, 0)
    brightSliderArea.BackgroundTransparency = 1
    brightSliderArea.Parent = root

    -- Brightness track
    local brightTrack = Instance.new("Frame")
    brightTrack.Size = UDim2.new(0, 24, 0, wheelSize - 20)
    brightTrack.Position = UDim2.new(0.5, -12, 0, 10)
    brightTrack.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    brightTrack.BackgroundTransparency = 0
    brightTrack.BorderSizePixel = 0
    brightTrack.ZIndex = 2
    brightTrack.Parent = brightSliderArea

    local btCorner = Instance.new("UICorner")
    btCorner.CornerRadius = UDim.new(0, 12)
    btCorner.Parent = brightTrack

    -- Brightness gradient fill (white top, black bottom)
    local brightFill = Instance.new("Frame")
    brightFill.Size = UDim2.new(1, -2, 1, -2)
    brightFill.Position = UDim2.new(0, 1, 0, 1)
    brightFill.BackgroundTransparency = 0
    brightFill.BorderSizePixel = 0
    brightFill.ClipsDescendants = true
    brightFill.ZIndex = 3
    brightFill.Parent = brightTrack

    local bfTop = Instance.new("Frame")
    bfTop.Size = UDim2.new(1, 0, 0.5, 0)
    bfTop.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bfTop.BorderSizePixel = 0
    bfTop.ZIndex = 3
    bfTop.Parent = brightFill

    local bfBottom = Instance.new("Frame")
    bfBottom.Size = UDim2.new(1, 0, 0.5, 0)
    bfBottom.Position = UDim2.new(0, 0, 0.5, 0)
    bfBottom.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bfBottom.BorderSizePixel = 0
    bfBottom.ZIndex = 3
    bfBottom.Parent = brightFill

    local bfCorner = Instance.new("UICorner")
    bfCorner.CornerRadius = UDim.new(0, 10)
    bfCorner.Parent = brightFill

    -- Brightness indicator
    local brightIndicator = Instance.new("Frame")
    brightIndicator.Size = UDim2.new(0, 28, 0, 12)
    brightIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    brightIndicator.BorderSizePixel = 0
    brightIndicator.ZIndex = 10
    brightIndicator.Parent = brightTrack

    local biCorner = Instance.new("UICorner")
    biCorner.CornerRadius = UDim.new(0, 6)
    biCorner.Parent = brightIndicator

    -- === Color preview ===
    local preview = Instance.new("Frame")
    preview.Name = "Preview"
    preview.Size = UDim2.new(0, 40, 0, 40)
    preview.Position = UDim2.new(1, -40, 1, -40)
    preview.BackgroundColor3 = HSBtoRGB(currentHue, currentSaturation, currentBrightness)
    preview.BorderSizePixel = 0
    preview.ZIndex = 5

    local previewStroke = Instance.new("UIStroke")
    previewStroke.Color = Theme.BorderColors.Neutral700.Color
    previewStroke.Transparency = 0
    previewStroke.Thickness = 2
    previewStroke.Parent = preview

    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, Theme.Radii.SM)
    previewCorner.Parent = preview

    preview.Parent = root

    -- === Internal update ===
    local function updateHueIndicator()
        local angleRad = math.rad(currentHue - 90)
        local midRadius = (outerRadius + innerRadius) / 2
        local ix = center + midRadius * math.cos(angleRad) - indicatorSize / 2
        local iy = center + midRadius * math.sin(angleRad) - indicatorSize / 2
        hueIndicator.Position = UDim2.new(0, ix, 0, iy)

        hueInner.BackgroundColor3 = HSBtoRGB(currentHue, 100, 100)
    end

    local function updateInnerCircle()
        innerCircle.BackgroundColor3 = HSBtoRGB(currentHue, currentSaturation, currentBrightness)
        satRight.BackgroundColor3 = HSBtoRGB(currentHue, 100, 100)
    end

    local function updateBrightIndicator()
        local trackHeight = brightTrack.AbsoluteSize.Y
        local ratio = currentBrightness / 255
        local yPos = trackHeight * (1 - ratio) - 6
        brightIndicator.Position = UDim2.new(0, -2, 0, yPos)
    end

    local function updatePreview()
        preview.BackgroundColor3 = HSBtoRGB(currentHue, currentSaturation, currentBrightness)
    end

    local function updateAll()
        updateHueIndicator()
        updateInnerCircle()
        updateBrightIndicator()
        updatePreview()
    end

    -- === Ring interaction (hue selection) ===
    local isDraggingRing = false

    local function getHueFromPosition(position)
        local relX = position.X - ringContainer.AbsolutePosition.X - center
        local relY = position.Y - ringContainer.AbsolutePosition.Y - center
        local dist = math.sqrt(relX * relX + relY * relY)

        if dist >= innerRadius - 20 and dist <= outerRadius + 20 then
            local angle = math.atan2(relY, relX) * (180 / math.pi) + 90
            if angle < 0 then angle = angle + 360 end
            currentHue = angle % 360
            updateHueIndicator()
            updateInnerCircle()
            updatePreview()
            if onColorChange then
                onColorChange(currentHue, currentSaturation, currentBrightness)
            end
        end
    end

    table.insert(connections, ringContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingRing = true
            getHueFromPosition(input.Position)
        end
    end))

    -- === Inner circle interaction (saturation/brightness) ===
    local isDraggingInner = false

    local function getSatBrightFromPosition(position)
        local relX = position.X - innerCircle.AbsolutePosition.X
        local relY = position.Y - innerCircle.AbsolutePosition.Y
        local w = innerCircle.AbsoluteSize.X
        local h = innerCircle.AbsoluteSize.Y

        if w > 0 and h > 0 then
            currentSaturation = math.clamp(math.round((relX / w) * 100), 0, 100)
            currentBrightness = math.clamp(math.round((1 - relY / h) * 255), 0, 255)
            updateInnerCircle()
            updateBrightIndicator()
            updatePreview()
            if onColorChange then
                onColorChange(currentHue, currentSaturation, currentBrightness)
            end
        end
    end

    table.insert(connections, innerCircle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingInner = true
            getSatBrightFromPosition(input.Position)
        end
    end))

    -- === Brightness slider interaction ===
    local isDraggingBright = false

    local function getBrightnessFromPosition(position)
        local relY = position.Y - brightTrack.AbsolutePosition.Y
        local trackHeight = brightTrack.AbsoluteSize.Y
        if trackHeight > 0 then
            local ratio = 1 - (relY / trackHeight)
            currentBrightness = math.clamp(math.round(ratio * 255), 0, 255)
            updateInnerCircle()
            updateBrightIndicator()
            updatePreview()
            if onColorChange then
                onColorChange(currentHue, currentSaturation, currentBrightness)
            end
        end
    end

    table.insert(connections, brightTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingBright = true
            getBrightnessFromPosition(input.Position)
        end
    end))

    -- === Global input tracking ===
    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingRing = false
            isDraggingInner = false
            isDraggingBright = false
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if isDraggingRing then
                getHueFromPosition(input.Position)
            elseif isDraggingInner then
                getSatBrightFromPosition(input.Position)
            elseif isDraggingBright then
                getBrightnessFromPosition(input.Position)
            end
        end
    end))

    -- === Initial render ===
    task.defer(updateAll)

    -- === Public methods ===
    function root:getColor()
        return currentHue, currentSaturation, currentBrightness
    end

    function root:getColor3()
        return HSBtoRGB(currentHue, currentSaturation, currentBrightness)
    end

    function root:setColor(hue, saturation, brightness)
        currentHue = hue or currentHue
        currentSaturation = saturation or currentSaturation
        currentBrightness = brightness or currentBrightness
        updateAll()
    end

    function root:setHue(hue)
        currentHue = hue % 360
        updateHueIndicator()
        updateInnerCircle()
        updatePreview()
    end

    function root:setSaturation(sat)
        currentSaturation = math.clamp(sat, 0, 100)
        updateInnerCircle()
        updatePreview()
    end

    function root:setBrightness(bright)
        currentBrightness = math.clamp(bright, 0, 255)
        updateInnerCircle()
        updateBrightIndicator()
        updatePreview()
    end

    function root:destroy()
        for _, conn in ipairs(connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        connections = {}
        root:Destroy()
    end

    root.hueRing = ringContainer
    root.innerCircle = innerCircle
    root.preview = preview

    return root
end

return ColorWheel
