--[[
    EasterEggPopup.lua — Easter Egg Popup
    The-Blur Roblox SurfaceGUI  |  4K (3840x2160)

    Full-screen overlay with centered popup showing red glow dot and
    "Made with ❤ by Johan" text. Spring enter animation.

    Export: EasterEggPopup.new(parent) -> { frame, show(), hide(), destroy() }
]]

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Theme)
local TweenHelper = require(script.Parent.TweenHelper)

local EasterEggPopup = {}

function EasterEggPopup.new(parent)
    local self = {}
    self._connections = {}
    self._isOpen = false

    ---------------------------------------------------------------------------
    -- Backdrop overlay (full screen, semi-transparent)
    ---------------------------------------------------------------------------
    local backdrop = Instance.new("Frame")
    backdrop.Name = "EasterEggBackdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Theme.Colors.Overlay -- black
    backdrop.BackgroundTransparency = 0.4 -- bg-black/60
    backdrop.BorderSizePixel = 0
    backdrop.Visible = false
    backdrop.ZIndex = Theme.ZIndex.EasterEgg
    backdrop.Parent = parent

    ---------------------------------------------------------------------------
    -- Popup container (centered)
    ---------------------------------------------------------------------------
    local popup = Instance.new("Frame")
    popup.Name = "EasterEggPopup"
    popup.Size = UDim2.new(0, 640, 0, 0) -- w-80(640px), auto height
    popup.AutomaticSize = Enum.AutomaticSize.Y
    popup.Position = UDim2.new(0.5, 0, 0.5, 0)
    popup.AnchorPoint = Vector2.new(0.5, 0.5)
    popup.BackgroundColor3 = Color3.fromRGB(3, 3, 3) -- bg-neutral-950
    popup.BackgroundTransparency = 0.05
    popup.BorderSizePixel = 0
    popup.ClipsDescendants = true
    popup.ZIndex = Theme.ZIndex.EasterEgg + 1
    popup.Parent = parent

    -- UICorner - rounded-xl (24px)
    local popupCorner = Instance.new("UICorner")
    popupCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.XL)
    popupCorner.Parent = popup

    -- UIStroke - border-neutral-700
    local popupStroke = Instance.new("UIStroke")
    popupStroke.Color = Theme.Colors.BorderHover -- neutral-700
    popupStroke.Thickness = 1
    popupStroke.Transparency = 0
    popupStroke.Parent = popup

    -- Shadow simulation (slightly larger dark frame behind)
    local shadowFrame = Instance.new("Frame")
    shadowFrame.Name = "Shadow"
    shadowFrame.Size = UDim2.new(1, 20, 1, 20)
    shadowFrame.Position = UDim2.new(0.5, 0, 0.5, 10)
    shadowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    shadowFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadowFrame.BackgroundTransparency = 0.7
    shadowFrame.BorderSizePixel = 0
    shadowFrame.ZIndex = Theme.ZIndex.EasterEgg
    shadowFrame.Parent = parent

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.XL + 4)
    shadowCorner.Parent = shadowFrame

    ---------------------------------------------------------------------------
    -- Container padding
    ---------------------------------------------------------------------------
    local popupPadding = Instance.new("UIPadding")
    popupPadding.PaddingLeft = UDim.new(0, Theme.Spacing.XXXL)  -- 48px
    popupPadding.PaddingRight = UDim.new(0, Theme.Spacing.XXXL)
    popupPadding.PaddingTop = UDim.new(0, Theme.Spacing.XXXL)
    popupPadding.PaddingBottom = UDim.new(0, Theme.Spacing.XXXL)
    popupPadding.Parent = popup

    ---------------------------------------------------------------------------
    -- Content layout
    ---------------------------------------------------------------------------
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, Theme.Spacing.XL) -- 24px gap
    contentLayout.Parent = popup

    ---------------------------------------------------------------------------
    -- Outer glow circle (gradient red glow)
    -- bg-gradient-to-br from-red-500/40 to-red-900/20
    -- ~200px(400px) diameter
    ---------------------------------------------------------------------------
    local glowOuter = Instance.new("Frame")
    glowOuter.Name = "GlowOuter"
    glowOuter.Size = UDim2.new(0, 160, 0, 160) -- w-10(80px) * 2 for outer ring
    glowOuter.BackgroundColor3 = Theme.Colors.EasterEggGradient -- red-900
    glowOuter.BackgroundTransparency = 0.8 -- /20 opacity
    glowOuter.BorderSizePixel = 0
    glowOuter.LayoutOrder = 1
    glowOuter.ZIndex = Theme.ZIndex.EasterEgg + 2
    glowOuter.Parent = popup

    local glowOuterCorner = Instance.new("UICorner")
    glowOuterCorner.CornerRadius = UDim.new(1, 0) -- rounded-full
    glowOuterCorner.Parent = glowOuter

    -- Inner glow ring
    local glowInner = Instance.new("Frame")
    glowInner.Name = "GlowInner"
    glowInner.Size = UDim2.new(0, 120, 0, 120) -- slightly smaller
    glowInner.Position = UDim2.new(0.5, 0, 0.5, 0)
    glowInner.AnchorPoint = Vector2.new(0.5, 0.5)
    glowInner.BackgroundColor3 = Theme.Colors.EasterEggRed -- red-500
    glowInner.BackgroundTransparency = 0.6 -- /40 opacity
    glowInner.BorderSizePixel = 0
    glowInner.ZIndex = Theme.ZIndex.EasterEgg + 3
    glowInner.Parent = glowOuter

    local glowInnerCorner = Instance.new("UICorner")
    glowInnerCorner.CornerRadius = UDim.new(1, 0) -- rounded-full
    glowInnerCorner.Parent = glowInner

    ---------------------------------------------------------------------------
    -- Inner dot (bg-red-500, ~40px(80px))
    ---------------------------------------------------------------------------
    local dotFrame = Instance.new("Frame")
    dotFrame.Name = "Dot"
    dotFrame.Size = UDim2.new(0, 60, 0, 60) -- w-3(24px) * ~2.5 = 60px
    dotFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    dotFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    dotFrame.BackgroundColor3 = Theme.Colors.EasterEggRed -- red-500
    dotFrame.BackgroundTransparency = 0
    dotFrame.BorderSizePixel = 0
    dotFrame.ZIndex = Theme.ZIndex.EasterEgg + 4
    dotFrame.Parent = glowOuter

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0) -- rounded-full
    dotCorner.Parent = dotFrame

    -- Glow effect behind dot (shadow-[0_0_12px_rgba(239,68,68,0.6)])
    local dotGlow = Instance.new("ImageLabel")
    dotGlow.Name = "DotGlow"
    dotGlow.Size = UDim2.new(0, 120, 0, 120)
    dotGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    dotGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    dotGlow.BackgroundTransparency = 1
    dotGlow.Image = "rbxassetid://7669168585" -- glow asset
    dotGlow.ImageColor3 = Theme.Colors.EasterEggRed -- red-500
    dotGlow.ImageTransparency = 0.4
    dotGlow.ScaleType = Enum.ScaleType.Slice
    dotGlow.SliceCenter = Rect.new(24, 24, 476, 476)
    dotGlow.ZIndex = Theme.ZIndex.EasterEgg + 3
    dotGlow.Parent = glowOuter

    ---------------------------------------------------------------------------
    -- "Easter Egg Found!" title
    ---------------------------------------------------------------------------
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 0)
    titleLabel.AutomaticSize = Enum.AutomaticSize.XY
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Easter Egg Found!"
    titleLabel.TextColor3 = Theme.Colors.TextPrimary -- white
    titleLabel.TextSize = Theme.FontSize.CardTitle -- 26px (text-sm)
    titleLabel.Font = Theme.Font.FamilySemibold
    titleLabel.ZIndex = Theme.ZIndex.EasterEgg + 2
    titleLabel.LayoutOrder = 2
    titleLabel.Parent = popup

    ---------------------------------------------------------------------------
    -- "You found one of many easter eggs"
    ---------------------------------------------------------------------------
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(1, 0, 0, 0)
    subtitleLabel.AutomaticSize = Enum.AutomaticSize.XY
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "You found one of many easter eggs"
    subtitleLabel.TextColor3 = Theme.Colors.TextBody -- neutral-400
    subtitleLabel.TextSize = Theme.FontSize.Small -- 24px (text-xs)
    subtitleLabel.Font = Theme.Font.FamilyLight
    subtitleLabel.TextWrapped = true
    subtitleLabel.ZIndex = Theme.ZIndex.EasterEgg + 2
    subtitleLabel.LayoutOrder = 3
    subtitleLabel.Parent = popup

    ---------------------------------------------------------------------------
    -- "Made with ❤ by Johan"
    ---------------------------------------------------------------------------
    local creditLabel = Instance.new("TextLabel")
    creditLabel.Name = "Credit"
    creditLabel.Size = UDim2.new(1, 0, 0, 0)
    creditLabel.AutomaticSize = Enum.AutomaticSize.XY
    creditLabel.BackgroundTransparency = 1
    creditLabel.Text = "Made with \u{2764} by Johan" -- ❤ Unicode
    creditLabel.TextColor3 = Theme.Colors.TextBody -- neutral-400
    creditLabel.TextSize = Theme.FontSize.Small -- 24px (text-xs)
    creditLabel.Font = Theme.Font.FamilyLight
    creditLabel.TextWrapped = true
    creditLabel.ZIndex = Theme.ZIndex.EasterEgg + 2
    creditLabel.LayoutOrder = 4
    creditLabel.Parent = popup

    ---------------------------------------------------------------------------
    -- Close button
    ---------------------------------------------------------------------------
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 0, 0, 0)
    closeButton.AutomaticSize = Enum.AutomaticSize.XY
    closeButton.BackgroundTransparency = 1
    closeButton.BorderSizePixel = 0
    closeButton.Text = ""
    closeButton.AutoButtonColor = false
    closeButton.LayoutOrder = 5
    closeButton.ZIndex = Theme.ZIndex.EasterEgg + 5
    closeButton.Parent = popup

    -- Close button inner frame (styled button)
    local closeBtnInner = Instance.new("Frame")
    closeBtnInner.Size = UDim2.new(0, 0, 0, 0)
    closeBtnInner.AutomaticSize = Enum.AutomaticSize.XY
    closeBtnInner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    closeBtnInner.BackgroundTransparency = 1
    closeBtnInner.BorderSizePixel = 0
    closeBtnInner.ZIndex = Theme.ZIndex.EasterEgg + 5
    closeBtnInner.Parent = closeButton

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.LG)
    closeBtnCorner.Parent = closeBtnInner

    local closeBtnStroke = Instance.new("UIStroke")
    closeBtnStroke.Color = Theme.Colors.BorderHover -- neutral-700
    closeBtnStroke.Thickness = 1
    closeBtnStroke.Parent = closeBtnInner

    local closeBtnPadding = Instance.new("UIPadding")
    closeBtnPadding.PaddingLeft = UDim.new(0, 48) -- px-6(48px)
    closeBtnPadding.PaddingRight = UDim.new(0, 48)
    closeBtnPadding.PaddingTop = UDim.new(0, 16) -- py-2(32px)
    closeBtnPadding.PaddingBottom = UDim.new(0, 16)
    closeBtnPadding.Parent = closeBtnInner

    local closeBtnLabel = Instance.new("TextLabel")
    closeBtnLabel.Size = UDim2.new(0, 0, 0, 0)
    closeBtnLabel.AutomaticSize = Enum.AutomaticSize.XY
    closeBtnLabel.BackgroundTransparency = 1
    closeBtnLabel.Text = "Close"
    closeBtnLabel.TextColor3 = Theme.Colors.TextMuted -- neutral-500
    closeBtnLabel.TextSize = Theme.FontSize.Small -- 24px (text-xs)
    closeBtnLabel.Font = Theme.Font.FamilyMedium
    closeBtnLabel.ZIndex = Theme.ZIndex.EasterEgg + 6
    closeBtnLabel.Parent = closeBtnInner

    -- Close button hover
    table.insert(self._connections, closeButton.MouseEnter:Connect(function()
        TweenService:Create(closeBtnLabel, TweenInfo.new(0.2), {
            TextColor3 = Theme.Colors.TextPrimary -- white
        }):Play()
        TweenService:Create(closeBtnStroke, TweenInfo.new(0.2), {
            Color = Theme.Colors.TextMuted -- neutral-500
        }):Play()
    end))

    table.insert(self._connections, closeButton.MouseLeave:Connect(function()
        TweenService:Create(closeBtnLabel, TweenInfo.new(0.2), {
            TextColor3 = Theme.Colors.TextMuted -- neutral-500
        }):Play()
        TweenService:Create(closeBtnStroke, TweenInfo.new(0.2), {
            Color = Theme.Colors.BorderHover -- neutral-700
        }):Play()
    end))

    -- Click handlers
    table.insert(self._connections, closeButton.Activated:Connect(function()
        self.hide()
    end))

    table.insert(self._connections, backdrop.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            self.hide()
        end
    end))

    ---------------------------------------------------------------------------
    -- Show / Hide
    ---------------------------------------------------------------------------
    function self.show()
        if self._isOpen then return end
        self._isOpen = true

        backdrop.Visible = true
        popup.Visible = true
        shadowFrame.Visible = true

        -- Initial state
        backdrop.BackgroundTransparency = 1
        popup.BackgroundTransparency = 1
        popup.Size = UDim2.new(0, 640 * 0.85, 0, 0)
        popupStroke.Transparency = 1
        shadowFrame.BackgroundTransparency = 1
        self:_setAllTransparency(popup, 1)

        -- Enter animations
        -- Backdrop: opacity 0 -> 1
        TweenService:Create(backdrop, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.4
        }):Play()

        -- Popup: opacity 0 -> 1, scale 0.85 -> 1 (spring: stiffness 300, damping 25)
        local springDuration = 0.4
        local springOvershoot = 0.25
        local springInfo = TweenInfo.new(
            springDuration,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out,
            0, false,
            springOvershoot
        )

        TweenService:Create(popup, springInfo, {
            BackgroundTransparency = 0.05,
            Size = UDim2.new(0, 640, 0, 0),
        }):Play()

        TweenService:Create(popupStroke, springInfo, {
            Transparency = 0,
        }):Play()

        TweenService:Create(shadowFrame, TweenInfo.new(0.3), {
            BackgroundTransparency = 0.7,
        }):Play()

        -- Fade in text content
        self:_fadeInContent(popup, 0.3)
    end

    function self.hide()
        if not self._isOpen then return end
        self._isOpen = false

        -- Exit animations
        local exitInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

        TweenService:Create(backdrop, exitInfo, {
            BackgroundTransparency = 1
        }):Play()

        TweenService:Create(popup, exitInfo, {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 640 * 0.85, 0, 0),
        }):Play()

        TweenService:Create(popupStroke, exitInfo, {
            Transparency = 1,
        }):Play()

        TweenService:Create(shadowFrame, exitInfo, {
            BackgroundTransparency = 1,
        }):Play()

        self:_fadeOutContent(popup, 0.2)

        spawn(function()
            wait(0.3)
            backdrop.Visible = false
            popup.Visible = false
            shadowFrame.Visible = false
        end)
    end

    ---------------------------------------------------------------------------
    -- Helpers
    ---------------------------------------------------------------------------
    function self:_setAllTransparency(instance, transparency)
        for _, child in ipairs(instance:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                child.TextTransparency = transparency
            elseif child:IsA("ImageLabel") then
                child.ImageTransparency = transparency
            elseif child:IsA("Frame") and child ~= popup then
                -- Don't set BackgroundTransparency on glow frames
                if child.Name ~= "GlowOuter" and child.Name ~= "GlowInner" and child.Name ~= "Dot" then
                    child.BackgroundTransparency = transparency
                end
                self:_setAllTransparency(child, transparency)
            end
        end
    end

    function self:_fadeInContent(instance, duration)
        local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        for _, child in ipairs(instance:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                TweenService:Create(child, info, { TextTransparency = 0 }):Play()
            elseif child:IsA("ImageLabel") then
                TweenService:Create(child, info, { ImageTransparency = child.ImageTransparency }):Play()
            elseif child:IsA("Frame") and child ~= popup then
                if child.Name ~= "GlowOuter" and child.Name ~= "GlowInner" and child.Name ~= "Dot" then
                    -- Tween UIStroke if present
                    local s = child:FindFirstChildOfClass("UIStroke")
                    if s then
                        TweenService:Create(s, info, { Transparency = 0 }):Play()
                    end
                end
                self:_fadeInContent(child, duration)
            end
        end
    end

    function self:_fadeOutContent(instance, duration)
        local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        for _, child in ipairs(instance:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                TweenService:Create(child, info, { TextTransparency = 1 }):Play()
            elseif child:IsA("ImageLabel") then
                TweenService:Create(child, info, { ImageTransparency = 1 }):Play()
            elseif child:IsA("Frame") and child ~= popup then
                if child.Name ~= "GlowOuter" and child.Name ~= "GlowInner" and child.Name ~= "Dot" then
                    local s = child:FindFirstChildOfClass("UIStroke")
                    if s then
                        TweenService:Create(s, info, { Transparency = 1 }):Play()
                    end
                end
                self:_fadeOutContent(child, duration)
            end
        end
    end

    function self.destroy()
        for _, conn in ipairs(self._connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        self._connections = {}

        if backdrop and backdrop.Parent then backdrop:Destroy() end
        if popup and popup.Parent then popup:Destroy() end
        if shadowFrame and shadowFrame.Parent then shadowFrame:Destroy() end
    end

    -- Combine frames into a group reference
    self.frame = backdrop

    return self
end

return EasterEggPopup
