--[[
    LandingPanel.lua — Landing Page (Full Screen)
    The-Blur Roblox SurfaceGUI  |  4K (3840x2160)

    Full-screen black background with centered "Blur" title and
    "Enter the Panel" button. Click transitions to welcome phase.

    Export: LandingPanel.new(parent, store, onEnter) -> { frame, show(), hide(), destroy() }
]]

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Parent.Theme)
local TweenHelper = require(script.Parent.Parent.TweenHelper)

local LandingPanel = {}

function LandingPanel.new(parent, store, onEnter)
    assert(store, "LandingPanel requires a Store instance")

    local self = {}
    self._connections = {}
    self._store = store

    ---------------------------------------------------------------------------
    -- Root frame (full screen, black)
    ---------------------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Name = "LandingPanel"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = Theme.Colors.Background -- pure black
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.ZIndex = Theme.ZIndex.ModalOverlay -- high z-index
    frame.Parent = parent

    ---------------------------------------------------------------------------
    -- Content container (centered)
    ---------------------------------------------------------------------------
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(0, 0, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.XY
    content.Position = UDim2.new(0.5, 0, 0.5, 0)
    content.AnchorPoint = Vector2.new(0.5, 0.5)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ZIndex = Theme.ZIndex.ModalOverlay + 1
    content.Parent = frame

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, Theme.Spacing.XXXL) -- 64px (mt-8/64px)
    contentLayout.Parent = content

    ---------------------------------------------------------------------------
    -- "Blur" title (text-[120px]/240px, font-bold/black, tracking-tight, white)
    ---------------------------------------------------------------------------
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0, 0, 0, 0)
    titleLabel.AutomaticSize = Enum.AutomaticSize.XY
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Blur"
    titleLabel.TextColor3 = Theme.Colors.LandingText -- white
    titleLabel.TextSize = Theme.FontSize.LandingTitle -- 240px
    titleLabel.Font = Theme.Font.FamilyBlack -- font-bold/black
    titleLabel.LayoutOrder = 1
    titleLabel.ZIndex = Theme.ZIndex.ModalOverlay + 2
    titleLabel.Parent = content

    ---------------------------------------------------------------------------
    -- "Enter the Panel" button (primary: white bg, black text)
    -- px-8(64px) py-3(24px), text-sm/28px, font-medium, tracking-wide, rounded-lg(16px)
    ---------------------------------------------------------------------------
    local enterButton = Instance.new("TextButton")
    enterButton.Name = "EnterButton"
    enterButton.Size = UDim2.new(0, 0, 0, 0)
    enterButton.AutomaticSize = Enum.AutomaticSize.XY
    enterButton.BackgroundColor3 = Theme.Colors.ButtonPrimary -- white
    enterButton.BackgroundTransparency = 0
    enterButton.BorderSizePixel = 0
    enterButton.Text = "Enter the Panel"
    enterButton.TextColor3 = Theme.Colors.ButtonPrimaryText -- black
    enterButton.TextSize = Theme.FontSize.ButtonLarge -- 28px (text-sm)
    enterButton.Font = Theme.Font.FamilyMedium -- font-medium
    enterButton.AutoButtonColor = false
    enterButton.LayoutOrder = 2
    enterButton.ZIndex = Theme.ZIndex.ModalOverlay + 2
    enterButton.Parent = content

    -- UICorner - rounded-lg (16px)
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.LG)
    btnCorner.Parent = enterButton

    -- UIPadding - px-8(64px), py-3(24px)
    local btnPadding = Instance.new("UIPadding")
    btnPadding.PaddingLeft = UDim.new(0, 64)
    btnPadding.PaddingRight = UDim.new(0, 64)
    btnPadding.PaddingTop = UDim.new(0, 24)
    btnPadding.PaddingBottom = UDim.new(0, 24)
    btnPadding.Parent = enterButton

    -- UIStroke - border-neutral-600 (ghost style per web: border border-neutral-600)
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Theme.Colors.BorderActive -- neutral-600
    btnStroke.Thickness = 1
    btnStroke.Parent = enterButton

    -- Track original states for reset
    local originalBgColor = enterButton.BackgroundColor3
    local originalTextColor = enterButton.TextColor3
    local originalStrokeColor = btnStroke.Color

    ---------------------------------------------------------------------------
    -- Button hover effect: bg-neutral-200, text-white, border-white
    ---------------------------------------------------------------------------
    table.insert(self._connections, enterButton.MouseEnter:Connect(function()
        TweenService:Create(enterButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Theme.Colors.ButtonPrimaryHover, -- neutral-200
            TextColor3 = Theme.Colors.TextPrimary, -- white
        }):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.2), {
            Color = Theme.Colors.TextPrimary, -- white
        }):Play()
    end))

    table.insert(self._connections, enterButton.MouseLeave:Connect(function()
        TweenService:Create(enterButton, TweenInfo.new(0.2), {
            BackgroundColor3 = originalBgColor,
            TextColor3 = originalTextColor,
        }):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.2), {
            Color = originalStrokeColor,
        }):Play()
    end))

    -- Press effect: scale 0.98
    table.insert(self._connections, enterButton.MouseButton1Down:Connect(function()
        TweenService:Create(enterButton, TweenInfo.new(0.1), {
            Size = UDim2.new(
                enterButton.Size.X.Scale,
                enterButton.Size.X.Offset * 0.98,
                enterButton.Size.Y.Scale,
                enterButton.Size.Y.Offset * 0.98
            ),
        }):Play()
    end))

    table.insert(self._connections, enterButton.MouseButton1Up:Connect(function()
        TweenService:Create(enterButton, TweenInfo.new(0.1), {
            Size = UDim2.new(
                enterButton.Size.X.Scale,
                enterButton.Size.X.Offset / 0.98,
                enterButton.Size.Y.Scale,
                enterButton.Size.Y.Offset / 0.98
            ),
        }):Play()
    end))

    -- Click handler: call store:setPhase("welcome")
    table.insert(self._connections, enterButton.Activated:Connect(function()
        if onEnter then
            onEnter()
        else
            store:setPhase("welcome")
        end
    end))

    ---------------------------------------------------------------------------
    -- Show with animations
    ---------------------------------------------------------------------------
    function self.show()
        frame.Visible = true

        -- Title: opacity 0 -> 1, scale 0.9 -> 1 (0.8s easeOut)
        titleLabel.TextTransparency = 1
        titleLabel.Size = UDim2.new(0, 0, 0, 0)
        titleLabel.Size = UDim2.new(0, 1000, 0, 240) -- set initial size for scale animation

        local titleScaleStart = UDim2.new(0, 1000 * 0.9, 0, 240 * 0.9)
        local titleScaleEnd = UDim2.new(0, 1000, 0, 240)

        -- We simulate scale by animating size from center
        titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        titleLabel.Size = titleScaleStart
        titleLabel.Position = UDim2.new(0.5, 0, 0, 0)

        local titleInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(titleLabel, titleInfo, {
            Size = titleScaleEnd,
            TextTransparency = 0,
        }):Play()

        -- Button: opacity 0 -> 1, y: 20 -> 0 (0.6s, delay 0.4s)
        enterButton.TextTransparency = 1
        btnStroke.Transparency = 1
        enterButton.AnchorPoint = Vector2.new(0.5, 0)
        enterButton.Position = UDim2.new(0.5, 0, 0, 20)

        local btnInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.4)
        TweenService:Create(enterButton, btnInfo, {
            Position = UDim2.new(0.5, 0, 0, 0),
        }):Play()

        TweenService:Create(enterButton, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.4), {
            TextTransparency = 0,
        }):Play()

        TweenService:Create(btnStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.4), {
            Transparency = 0,
        }):Play()
    end

    ---------------------------------------------------------------------------
    -- Hide with fade-out
    ---------------------------------------------------------------------------
    function self.hide()
        local exitInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(frame, exitInfo, {
            BackgroundTransparency = 1,
        }):Play()

        TweenService:Create(titleLabel, exitInfo, {
            TextTransparency = 1,
        }):Play()

        TweenService:Create(enterButton, exitInfo, {
            TextTransparency = 1,
        }):Play()

        spawn(function()
            wait(0.5)
            frame.Visible = false
            frame.BackgroundTransparency = 0
        end)
    end

    ---------------------------------------------------------------------------
    -- Destroy
    ---------------------------------------------------------------------------
    function self.destroy()
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

return LandingPanel
