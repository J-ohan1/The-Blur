--[[
    Toggle.lua — Toggle Switch Component
    The-Blur Roblox SurfaceGUI  |  4K (3840×2160)

    States:
        Off: bg-neutral-80%, circle on left (neutral-400)
        On:  bg-white, circle on right (black) with slide animation

    Size: 64×36 (32×18 web * 2)

    Usage:
        local Toggle = require(script.Parent.Toggle)
        local toggle = Toggle.new(parent, {
            value = false,
            position = UDim2.new(0, 0, 0, 0),
            callback = function(val) print(val) end,
            label = "Dark Mode",
        })
        toggle:setValue(true)
        local val = toggle:getValue()
        toggle:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")

local Toggle = {}

function Toggle.new(parent, config)
    config = config or {}
    local connections = {}
    local isOn = config.value or false
    local callback = config.callback

    local toggleWidth = config.width or Theme.Toggle.Width
    local toggleHeight = config.height or Theme.Toggle.Height

    -- === Root Frame ===
    local root = Instance.new("Frame")
    root.Name = "Toggle_" .. (config.label or "unnamed")
    root.Size = UDim2.new(0, toggleWidth, 0, toggleHeight)
    root.Position = config.position or UDim2.new(0, 0, 0, 0)
    root.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    root.BackgroundTransparency = 1
    root.Parent = parent

    -- === Optional Label ===
    local label = nil
    if config.label then
        local containerWidth = toggleWidth + Theme.Spacing.PX_2 + 300 -- Extra for label text
        root.Size = UDim2.new(0, containerWidth, 0, toggleHeight)

        label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, -(toggleWidth + Theme.Spacing.PX_2), 1, 0)
        label.BackgroundTransparency = 1
        label.Text = config.label
        label.TextColor3 = Theme.TextColors.Neutral400
        label.TextSize = Theme.FontSizes.Size12
        label.Font = Theme.Font
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = root
    end

    -- === Track (background) ===
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(0, toggleWidth, 0, toggleHeight)
    track.Position = UDim2.new(1, -toggleWidth, 0, 0)
    track.BackgroundColor3 = Theme.Toggle.OffBg.Color
    track.BackgroundTransparency = Theme.Toggle.OffBg.Transparency
    track.BorderSizePixel = 0
    track.Parent = root

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0) -- pill shape
    trackCorner.Parent = track

    -- === Thumb (circle) ===
    local thumbSize = Theme.Toggle.ThumbSize
    local thumbMargin = (toggleHeight - thumbSize) / 2
    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(0, thumbSize, 0, thumbSize)
    thumb.Position = UDim2.new(0, thumbMargin, 0.5, 0)
    thumb.AnchorPoint = Vector2.new(0, 0.5)
    thumb.BackgroundColor3 = Theme.Toggle.OffThumb
    thumb.BackgroundTransparency = 0
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 2
    thumb.Parent = track

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0) -- circle
    thumbCorner.Parent = thumb

    -- === Click detector (invisible button over track) ===
    local clickBtn = Instance.new("TextButton")
    clickBtn.Name = "ClickDetector"
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.AutoButtonColor = false
    clickBtn.BorderSizePixel = 0
    clickBtn.ZIndex = 5
    clickBtn.Parent = track

    -- === Internal update ===
    local function updateVisuals(animate)
        local duration = animate and Theme.Animations.Normal or 0

        if isOn then
            -- On state: white bg, black thumb, thumb on right
            TweenService:Create(track, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Theme.Toggle.OnBg,
                BackgroundTransparency = 0,
            }):Play()

            TweenService:Create(thumb, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, toggleWidth - thumbSize - thumbMargin, 0.5, 0),
                BackgroundColor3 = Theme.Toggle.OnThumb,
            }):Play()
        else
            -- Off state: neutral bg, neutral thumb, thumb on left
            TweenService:Create(track, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Theme.Toggle.OffBg.Color,
                BackgroundTransparency = Theme.Toggle.OffBg.Transparency,
            }):Play()

            TweenService:Create(thumb, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, thumbMargin, 0.5, 0),
                BackgroundColor3 = Theme.Toggle.OffThumb,
            }):Play()
        end
    end

    -- Set initial state without animation
    updateVisuals(false)

    -- === Click handler ===
    table.insert(connections, clickBtn.Activated:Connect(function()
        isOn = not isOn
        updateVisuals(true)
        if callback then
            callback(isOn)
        end
    end))

    -- === Hover effect on track ===
    table.insert(connections, track.MouseEnter:Connect(function()
        if isOn then
            TweenService:Create(track, TweenInfo.new(Theme.Animations.Fast), {
                BackgroundTransparency = 0.05,
            }):Play()
        else
            TweenService:Create(track, TweenInfo.new(Theme.Animations.Fast), {
                BackgroundTransparency = 0.1,
            }):Play()
        end
    end))

    table.insert(connections, track.MouseLeave:Connect(function()
        if isOn then
            TweenService:Create(track, TweenInfo.new(Theme.Animations.Fast), {
                BackgroundTransparency = 0,
            }):Play()
        else
            TweenService:Create(track, TweenInfo.new(Theme.Animations.Fast), {
                BackgroundTransparency = Theme.Toggle.OffBg.Transparency,
            }):Play()
        end
    end))

    -- === Public methods ===
    function root:setValue(value, animate)
        isOn = value == true
        updateVisuals(animate ~= false)
    end

    function root:getValue()
        return isOn
    end

    function root:setCallback(newCallback)
        callback = newCallback
    end

    function root:setLabel(text)
        if label then
            label.Text = text or ""
        end
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

    root.track = track
    root.thumb = thumb

    return root
end

return Toggle
