--[[
    Slider.lua — Custom Draggable Slider Component
    The-Blur Roblox SurfaceGUI  |  4K (3840×2160)

    Features:
        - Track: thin horizontal bar, bg-neutral-800/60
        - Thumb: white circle (24px diameter), hover scale 1.1
        - Value text label (mono font)
        - Min/max values (default 0–255)
        - Callback on value change

    Usage:
        local Slider = require(script.Parent.Slider)
        local slider = Slider.new(parent, {
            min = 0,
            max = 255,
            value = 128,
            label = "Dimmer",
            position = UDim2.new(0, 0, 0, 0),
            size = UDim2.new(1, 0, 0, 60),
            callback = function(val) print(val) end,
            showValue = true,
        })
        slider:setValue(200)
        slider:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Slider = {}

function Slider.new(parent, config)
    config = config or {}
    local connections = {}

    local minVal = config.min or 0
    local maxVal = config.max or 255
    local currentValue = config.value or 0
    local showValue = config.showValue ~= false
    local callback = config.callback

    -- === Root Frame ===
    local root = Instance.new("Frame")
    root.Name = "Slider_" .. (config.label or "unnamed")
    root.Size = config.size or UDim2.new(1, 0, 0, 80)
    root.Position = config.position or UDim2.new(0, 0, 0, 0)
    root.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    root.BackgroundTransparency = 1
    root.Parent = parent

    -- === Label + Value Row ===
    local labelRow = Instance.new("Frame")
    labelRow.Name = "LabelRow"
    labelRow.Size = UDim2.new(1, 0, 0, Theme.FontSizes.Size10 + Theme.Spacing.PX_1)
    labelRow.BackgroundTransparency = 1
    labelRow.Parent = root

    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = config.label or "Slider"
    label.TextColor3 = Theme.TextColors.Neutral600
    label.TextSize = Theme.FontSizes.Size10
    label.Font = Theme.FontSemiBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = labelRow

    -- Value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0.5, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(currentValue)
    valueLabel.TextColor3 = Theme.TextColors.Neutral400
    valueLabel.TextSize = Theme.FontSizes.Size10
    valueLabel.Font = Theme.FontMono
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = labelRow
    valueLabel.Visible = showValue

    -- === Slider Track Area ===
    local trackArea = Instance.new("Frame")
    trackArea.Name = "TrackArea"
    trackArea.Size = UDim2.new(1, 0, 0, Theme.Slider.TrackHeight + Theme.Slider.ThumbSize)
    trackArea.Position = UDim2.new(0, 0, 1, -(Theme.Slider.TrackHeight + Theme.Slider.ThumbSize))
    trackArea.BackgroundTransparency = 1
    trackArea.Parent = root

    -- Track background
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 0, Theme.Slider.TrackHeight)
    track.Position = UDim2.new(0, 0, 0.5, 0)
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.BackgroundColor3 = Theme.Slider.TrackColor.Color
    track.BackgroundTransparency = Theme.Slider.TrackColor.Transparency
    track.BorderSizePixel = 0
    track.Parent = trackArea

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0) -- Full radius for pill shape
    trackCorner.Parent = track

    -- Fill portion
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Slider.FillColor
    fill.BackgroundTransparency = 0
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    -- Thumb
    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(0, Theme.Slider.ThumbSize, 0, Theme.Slider.ThumbSize)
    thumb.Position = UDim2.new(0, 0, 0.5, 0)
    thumb.AnchorPoint = Vector2.new(0, 0.5)
    thumb.BackgroundColor3 = Theme.Slider.ThumbColor
    thumb.BackgroundTransparency = 0
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 5
    thumb.Parent = trackArea

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0) -- Circle
    thumbCorner.Parent = thumb

    -- === Internal update ===
    local function updateVisuals()
        local range = maxVal - minVal
        local percentage = range > 0 and (currentValue - minVal) / range or 0
        percentage = math.clamp(percentage, 0, 1)

        local trackWidth = track.AbsoluteSize.X
        local thumbOffset = percentage * trackWidth - (Theme.Slider.ThumbSize / 2)

        thumb.Position = UDim2.new(0, thumbOffset, 0.5, 0)
        fill.Size = UDim2.new(percentage, 0, 1, 0)

        if showValue then
            valueLabel.Text = tostring(math.round(currentValue))
        end
    end

    local function setValueFromPosition(x)
        local trackWidth = track.AbsoluteSize.X
        if trackWidth <= 0 then return end

        local localX = x - track.AbsolutePosition.X
        local percentage = math.clamp(localX / trackWidth, 0, 1)
        local range = maxVal - minVal
        currentValue = minVal + percentage * range
        currentValue = math.clamp(math.round(currentValue), minVal, maxVal)

        updateVisuals()

        if callback then
            callback(currentValue)
        end
    end

    -- === Drag logic ===
    local isDragging = false

    local function startDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            setValueFromPosition(input.Position.X)
        end
    end

    local function endDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end

    local function moveDrag(input)
        if isDragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                setValueFromPosition(input.Position.X)
            end
        end
    end

    -- Track area interactions
    table.insert(connections, trackArea.InputBegan:Connect(startDrag))
    table.insert(connections, thumb.InputBegan:Connect(startDrag))
    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if isDragging then
            endDrag(input)
        end
    end))
    table.insert(connections, UserInputService.InputChanged:Connect(moveDrag))

    -- === Thumb hover effect ===
    table.insert(connections, thumb.MouseEnter:Connect(function()
        if not isDragging then
            TweenService:Create(thumb, TweenInfo.new(Theme.Animations.Fast), {
                Size = UDim2.new(0, Theme.Slider.ThumbSize * Theme.Slider.ThumbHoverScale, 0, Theme.Slider.ThumbSize * Theme.Slider.ThumbHoverScale),
            }):Play()
        end
    end))

    table.insert(connections, thumb.MouseLeave:Connect(function()
        if not isDragging then
            TweenService:Create(thumb, TweenInfo.new(Theme.Animations.Fast), {
                Size = UDim2.new(0, Theme.Slider.ThumbSize, 0, Theme.Slider.ThumbSize),
            }):Play()
        end
    end))

    -- === Initial render ===
    task.defer(function()
        updateVisuals()
    end)

    -- Track size changes
    table.insert(connections, track:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        updateVisuals()
    end))

    -- === Public methods ===
    function root:setValue(val)
        currentValue = math.clamp(math.round(val), minVal, maxVal)
        updateVisuals()
    end

    function root:getValue()
        return currentValue
    end

    function root:setRange(newMin, newMax)
        minVal = newMin
        maxVal = newMax
        currentValue = math.clamp(currentValue, minVal, maxVal)
        updateVisuals()
    end

    function root:setLabel(text)
        label.Text = text
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

    root.sliderTrack = track
    root.sliderThumb = thumb
    root.sliderFill = fill
    root.valueLabel = valueLabel

    return root
end

return Slider
