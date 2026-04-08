--[[
    Button.lua — Reusable Button Component
    The-Blur Roblox SurfaceGUI  |  4K (3840×2160)

    Styles:
        "primary"   — white bg, black text, hover neutral-200
        "secondary" — bg-white/5, border-neutral-800, neutral-300 text
        "ghost"     — transparent, border-neutral-800/40, neutral-600 text
        "active"    — bg-neutral-800/50, border-neutral-700, text-white
        "danger"    — red variants

    Usage:
        local Button = require(script.Parent.Button)
        local btn = Button.new(parent, {
            text = "Enter the Panel",
            style = "primary",
            size = UDim2.new(0, 300, 0, 56),
            position = UDim2.new(0.5, 0, 0, 0),
            anchorPoint = Vector2.new(0.5, 0),
            callback = function() print("clicked") end,
            fontSize = 22,
        })
        -- Later: btn:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")

local Button = {}

local STYLES = {
    primary = {
        default = {
            BackgroundColor3 = Theme.Colors.White,
            BackgroundTransparency = 0,
            TextColor3 = Theme.TextColors.Black,
            border = nil,
        },
        hover = {
            BackgroundColor3 = Theme.Colors.Neutral200,
        },
    },
    secondary = {
        default = {
            BackgroundColor3 = Theme.BgColors.White5.Color,
            BackgroundTransparency = Theme.BgColors.White5.Transparency,
            TextColor3 = Theme.TextColors.Neutral300,
            border = Theme.BorderColors.Neutral800,
        },
        hover = {
            BackgroundColor3 = Theme.BgColors.White10.Color,
            BackgroundTransparency = Theme.BgColors.White10.Transparency,
            TextColor3 = Theme.TextColors.White,
            border = Theme.BorderColors.Neutral600,
        },
    },
    ghost = {
        default = {
            BackgroundColor3 = Theme.Colors.White,
            BackgroundTransparency = 1,
            TextColor3 = Theme.TextColors.Neutral600,
            border = Theme.BorderColors.Neutral800_40,
        },
        hover = {
            TextColor3 = Theme.TextColors.Neutral400,
            border = Theme.BorderColors.Neutral700,
        },
    },
    active = {
        default = {
            BackgroundColor3 = Theme.BgColors.Neutral800_50.Color,
            BackgroundTransparency = Theme.BgColors.Neutral800_50.Transparency,
            TextColor3 = Theme.TextColors.White,
            border = Theme.BorderColors.Neutral700,
        },
        hover = {},
    },
    danger = {
        default = {
            BackgroundColor3 = Theme.BgColors.Destructive.Color,
            BackgroundTransparency = Theme.BgColors.Destructive.Transparency,
            TextColor3 = Theme.TextColors.White,
            border = nil,
        },
        hover = {
            BackgroundColor3 = Theme.Colors.DestructiveDark,
        },
    },
}

function Button.new(parent, config)
    config = config or {}
    local styleName = config.style or "primary"
    local styleDef = STYLES[styleName] or STYLES.primary
    local defaultProps = styleDef.default
    local hoverProps = styleDef.hover
    local connections = {}

    -- Root TextButton
    local btn = Instance.new("TextButton")
    btn.Name = "Button_" .. (config.text or "unnamed")
    btn.Size = config.size or UDim2.new(0, 320, 0, Theme.Heights.ButtonMd)
    btn.Position = config.position or UDim2.new(0, 0, 0, 0)
    btn.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    btn.BackgroundColor3 = defaultProps.BackgroundColor3
    btn.BackgroundTransparency = defaultProps.BackgroundTransparency
    btn.TextColor3 = defaultProps.TextColor3
    btn.Text = config.text or "Button"
    btn.TextSize = config.fontSize or Theme.FontSizes.Size13
    btn.Font = Theme.Font
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0

    -- UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, config.cornerRadius or Theme.Radii.MD)
    corner.Parent = btn

    -- UIStroke (border)
    local stroke = nil
    if defaultProps.border then
        stroke = Instance.new("UIStroke")
        stroke.Color = defaultProps.border.Color
        stroke.Transparency = defaultProps.border.Transparency or 0
        stroke.Thickness = Theme.BorderWidths.Default
        stroke.Parent = btn
    end

    -- UIPadding
    local padding = Instance.new("UIPadding")
    local hPad = config.paddingH or Theme.Spacing.PX_3
    local vPad = config.paddingV or Theme.Spacing.PX_2
    padding.PaddingLeft = UDim.new(0, hPad)
    padding.PaddingRight = UDim.new(0, hPad)
    padding.PaddingTop = UDim.new(0, vPad)
    padding.PaddingBottom = UDim.new(0, vPad)
    padding.Parent = btn

    -- Store defaults for reset
    local defaultBgColor3 = btn.BackgroundColor3
    local defaultBgTransparency = btn.BackgroundTransparency
    local defaultTextColor3 = btn.TextColor3
    local defaultStrokeColor = stroke and stroke.Color
    local defaultStrokeTransparency = stroke and stroke.Transparency
    local defaultScale = 1

    -- Tween helpers
    local function tweenProperties(props, duration)
        TweenService:Create(btn, TweenInfo.new(duration or Theme.Animations.Fast, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end

    -- Hover effect
    table.insert(connections, btn.MouseEnter:Connect(function()
        local props = {}
        if hoverProps.BackgroundColor3 then
            props.BackgroundColor3 = hoverProps.BackgroundColor3
        end
        if hoverProps.BackgroundTransparency then
            props.BackgroundTransparency = hoverProps.BackgroundTransparency
        end
        if hoverProps.TextColor3 then
            props.TextColor3 = hoverProps.TextColor3
        end
        props.Size = UDim2.new(
            btn.Size.X.Scale,
            btn.Size.X.Offset,
            btn.Size.Y.Scale,
            btn.Size.Y.Offset * 1.01
        )
        tweenProperties(props, Theme.Animations.Fast)

        if stroke and hoverProps.border then
            TweenService:Create(stroke, TweenInfo.new(Theme.Animations.Fast), {
                Color = hoverProps.border.Color,
                Transparency = hoverProps.border.Transparency or 0,
            }):Play()
        end
    end))

    -- Leave effect
    table.insert(connections, btn.MouseLeave:Connect(function()
        tweenProperties({
            BackgroundColor3 = defaultBgColor3,
            BackgroundTransparency = defaultBgTransparency,
            TextColor3 = defaultTextColor3,
            Size = UDim2.new(
                btn.Size.X.Scale,
                btn.Size.X.Offset,
                btn.Size.Y.Scale,
                btn.Size.Y.Offset / 1.01
            ),
        }, Theme.Animations.Fast)

        if stroke then
            TweenService:Create(stroke, TweenInfo.new(Theme.Animations.Fast), {
                Color = defaultStrokeColor,
                Transparency = defaultStrokeTransparency,
            }):Play()
        end
    end))

    -- Press effect
    table.insert(connections, btn.MouseButton1Down:Connect(function()
        local baseSize = btn.Size
        TweenService:Create(btn, TweenInfo.new(Theme.Animations.Fast), {
            Size = UDim2.new(baseSize.X.Scale, baseSize.X.Offset, baseSize.Y.Scale, baseSize.Y.Offset * 0.98),
        }):Play()
    end))

    -- Release effect
    table.insert(connections, btn.MouseButton1Up:Connect(function()
        local baseSize = btn.Size
        TweenService:Create(btn, TweenInfo.new(Theme.Animations.Fast), {
            Size = UDim2.new(baseSize.X.Scale, baseSize.X.Offset, baseSize.Y.Scale, baseSize.Y.Offset / 0.98),
        }):Play()
    end))

    -- Click callback
    if config.callback then
        table.insert(connections, btn.Activated:Connect(function()
            config.callback(btn)
        end))
    end

    -- Parent
    btn.Parent = parent

    -- Methods
    function btn:setStyle(newStyle)
        local newDef = STYLES[newStyle]
        if not newDef then return end
        styleName = newStyle
        styleDef = newDef
        defaultProps = styleDef.default
        hoverProps = styleDef.hover

        defaultBgColor3 = defaultProps.BackgroundColor3
        defaultBgTransparency = defaultProps.BackgroundTransparency
        defaultTextColor3 = defaultProps.TextColor3

        btn.BackgroundColor3 = defaultBgColor3
        btn.BackgroundTransparency = defaultBgTransparency
        btn.TextColor3 = defaultTextColor3

        if stroke then
            if defaultProps.border then
                stroke.Color = defaultProps.border.Color
                stroke.Transparency = defaultProps.border.Transparency or 0
                stroke.Visible = true
                defaultStrokeColor = stroke.Color
                defaultStrokeTransparency = stroke.Transparency
            else
                stroke.Visible = false
            end
        elseif defaultProps.border then
            stroke = Instance.new("UIStroke")
            stroke.Color = defaultProps.border.Color
            stroke.Transparency = defaultProps.border.Transparency or 0
            stroke.Thickness = Theme.BorderWidths.Default
            stroke.Parent = btn
            defaultStrokeColor = stroke.Color
            defaultStrokeTransparency = stroke.Transparency
        end
    end

    function btn:setText(newText)
        self.Text = newText
    end

    function btn:setEnabled(enabled)
        self.AutoButtonColor = false
        if enabled then
            self.BackgroundTransparency = defaultBgTransparency
            self.TextTransparency = 0
        else
            self.BackgroundTransparency = 0.5
            self.TextTransparency = 0.5
        end
    end

    function btn:destroy()
        for _, conn in ipairs(connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        connections = {}
        btn:Destroy()
    end

    return btn
end

return Button
