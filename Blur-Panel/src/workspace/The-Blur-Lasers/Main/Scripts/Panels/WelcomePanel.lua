--[[
    WelcomePanel.lua — Welcome Screen (Full Screen, Auto-Transitions)
    The-Blur Roblox SurfaceGUI  |  4K (3840x2160)

    Full-screen black background with centered pill containing avatar
    and "Welcome, {username}" text. Auto-transitions to main phase
    after 2.5 seconds.

    Export: WelcomePanel.new(parent, store) -> { frame, show(), destroy() }
]]

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Parent.Theme)
local TweenHelper = require(script.Parent.Parent.TweenHelper)

local WelcomePanel = {}

function WelcomePanel.new(parent, store)
    assert(store, "WelcomePanel requires a Store instance")

    local self = {}
    self._connections = {}
    self._store = store
    self._autoTransitionDelay = nil

    ---------------------------------------------------------------------------
    -- Root frame (full screen, black)
    ---------------------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Name = "WelcomePanel"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = Theme.Colors.Background -- pure black
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = Theme.ZIndex.ModalOverlay
    frame.Parent = parent

    ---------------------------------------------------------------------------
    -- Content container (centered pill)
    ---------------------------------------------------------------------------
    local pill = Instance.new("Frame")
    pill.Name = "Pill"
    pill.Size = UDim2.new(0, 0, 0, 0)
    pill.AutomaticSize = Enum.AutomaticSize.XY
    pill.Position = UDim2.new(0.5, 0, 0.5, 0)
    pill.AnchorPoint = Vector2.new(0.5, 0.5)
    pill.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- bg-black/80
    pill.BackgroundTransparency = 0.2
    pill.BorderSizePixel = 0
    pill.ZIndex = Theme.ZIndex.ModalOverlay + 1
    pill.Parent = frame

    -- UICorner - rounded-xl (24px)
    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.XL)
    pillCorner.Parent = pill

    -- UIStroke - border-neutral-700
    local pillStroke = Instance.new("UIStroke")
    pillStroke.Color = Theme.Colors.BorderHover -- neutral-700
    pillStroke.Thickness = 1
    pillStroke.Transparency = 0
    pillStroke.Parent = pill

    -- UIPadding - px-8(64px), py-5(40px)
    local pillPadding = Instance.new("UIPadding")
    pillPadding.PaddingLeft = UDim.new(0, 64)
    pillPadding.PaddingRight = UDim.new(0, 64)
    pillPadding.PaddingTop = UDim.new(0, 40)
    pillPadding.PaddingBottom = UDim.new(0, 40)
    pillPadding.Parent = pill

    -- Inner horizontal layout
    local pillLayout = Instance.new("UIListLayout")
    pillLayout.FillDirection = Enum.FillDirection.Horizontal
    pillLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    pillLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pillLayout.Padding = UDim.new(0, Theme.Spacing.XXL) -- 32px gap (gap-4)
    pillLayout.Parent = pill

    ---------------------------------------------------------------------------
    -- Circular avatar (w-12/96px)
    ---------------------------------------------------------------------------
    local avatarFrame = Instance.new("Frame")
    avatarFrame.Name = "Avatar"
    avatarFrame.Size = UDim2.new(0, Theme.Avatar.Welcome, 0, Theme.Avatar.Welcome) -- 96px
    avatarFrame.BackgroundColor3 = Theme.Colors.SurfaceActive -- neutral-800
    avatarFrame.BackgroundTransparency = 0
    avatarFrame.BorderSizePixel = 0
    avatarFrame.LayoutOrder = 1
    avatarFrame.ZIndex = Theme.ZIndex.ModalOverlay + 2
    avatarFrame.Parent = pill

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0) -- rounded-full
    avatarCorner.Parent = avatarFrame

    local avatarBorder = Instance.new("UIStroke")
    avatarBorder.Color = Theme.Colors.BorderActive -- neutral-600
    avatarBorder.Thickness = 1
    avatarBorder.Parent = avatarFrame

    local avatarInitial = Instance.new("TextLabel")
    avatarInitial.Name = "Initial"
    avatarInitial.Size = UDim2.new(1, 0, 1, 0)
    avatarInitial.BackgroundTransparency = 1
    local userName = store:getCurrentUser().name
    avatarInitial.Text = userName:sub(1, 1):upper()
    avatarInitial.TextColor3 = Theme.Colors.TextBody -- neutral-400
    avatarInitial.TextSize = Theme.FontSize.H3 -- 44px (text-sm)
    avatarInitial.Font = Theme.Font.FamilyBold
    avatarInitial.ZIndex = Theme.ZIndex.ModalOverlay + 3
    avatarInitial.Parent = avatarFrame

    ---------------------------------------------------------------------------
    -- "Welcome, {username}" text
    -- text-xl(36px), white, font-medium
    ---------------------------------------------------------------------------
    local welcomeLabel = Instance.new("TextLabel")
    welcomeLabel.Name = "WelcomeText"
    welcomeLabel.Size = UDim2.new(0, 0, 0, 0)
    welcomeLabel.AutomaticSize = Enum.AutomaticSize.XY
    welcomeLabel.BackgroundTransparency = 1
    welcomeLabel.Text = "Welcome, " .. userName
    welcomeLabel.TextColor3 = Theme.Colors.TextPrimary -- white
    welcomeLabel.TextSize = 36 -- text-xl/36px
    welcomeLabel.Font = Theme.Font.FamilyMedium -- font-medium
    welcomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    welcomeLabel.LayoutOrder = 2
    welcomeLabel.ZIndex = Theme.ZIndex.ModalOverlay + 2
    welcomeLabel.Parent = pill

    ---------------------------------------------------------------------------
    -- Show with animations
    ---------------------------------------------------------------------------
    function self.show()
        frame.Visible = true

        -- Initial state: everything transparent/offset
        frame.BackgroundTransparency = 1
        pill.BackgroundTransparency = 1
        pillStroke.Transparency = 1
        avatarFrame.BackgroundTransparency = 1
        avatarBorder.Transparency = 1
        avatarInitial.TextTransparency = 1
        welcomeLabel.TextTransparency = 1

        -- Container: opacity 0 -> 1, scale 0.9 -> 1 (0.5s, delay 0.2s)
        pill.Size = UDim2.new(0, 500 * 0.9, 0, 176 * 0.9) -- initial scale
        local pillTargetSize = UDim2.new(0, 0, 0, 0)
        -- We need to compute the actual size first
        pill.AutomaticSize = Enum.AutomaticSize.None
        pill.Size = UDim2.new(0, 500, 0, 176)

        -- Fade in background
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
        }):Play()

        -- Pill: scale 0.9 -> 1, opacity 0 -> 1 (0.5s, delay 0.2s)
        local pillStartSize = UDim2.new(0, 500 * 0.9, 0, 176 * 0.9)
        local pillEndSize = UDim2.new(0, 500, 0, 176)
        pill.Size = pillStartSize

        -- Re-enable auto-size after animation
        local pillInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2)
        TweenService:Create(pill, pillInfo, {
            Size = pillEndSize,
            BackgroundTransparency = 0.2,
        }):Play()

        TweenService:Create(pillStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {
            Transparency = 0,
        }):Play()

        -- Avatar: fade in (0.5s, delay 0.2s)
        TweenService:Create(avatarFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {
            BackgroundTransparency = 0,
        }):Play()
        TweenService:Create(avatarBorder, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {
            Transparency = 0,
        }):Play()
        TweenService:Create(avatarInitial, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {
            TextTransparency = 0,
        }):Play()

        -- Text: opacity 0 -> 1, x: -20 -> 0 (0.4s, delay 0.5s)
        welcomeLabel.Position = UDim2.new(0, -20, 0, 0)

        local textInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.5)
        TweenService:Create(welcomeLabel, textInfo, {
            Position = UDim2.new(0, 0, 0, 0),
            TextTransparency = 0,
        }):Play()

        -- Auto-transition to main phase after 2.5 seconds
        self._autoTransitionDelay = spawn(function()
            wait(Theme.Animation.WelcomeAutoTransition) -- 2.5s
            store:setPhase("main")
        end)
    end

    ---------------------------------------------------------------------------
    -- Destroy
    ---------------------------------------------------------------------------
    function self.destroy()
        -- Cancel auto-transition if any
        self._autoTransitionDelay = nil

        for _, conn in ipairs(self._connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        self._connections = {}

        if frame and frame.Parent then
            frame:Destroy()
        end
    end

    self.frame = frame

    return self
end

return WelcomePanel
