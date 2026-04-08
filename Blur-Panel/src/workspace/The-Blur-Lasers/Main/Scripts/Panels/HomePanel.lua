--[[
    HomePanel.lua — Home Panel with 3D Carousel
    The-Blur Roblox SurfaceGUI  |  4K (3840x2160)

    Full panel area with a 3D rotating carousel of "Blur" text items,
    perspective depth effects, and a footer with version info.

    Export: HomePanel.new(parent) -> { frame, show(), hide(), destroy() }
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Theme = require(script.Parent.Parent.Theme)
local TweenHelper = require(script.Parent.Parent.TweenHelper)

local HomePanel = {}

local CAROUSEL_ITEM_COUNT = 5
local CAROUSEL_RADIUS = 400 -- 200px * 2 for 4K
local CAROUSEL_SPEED = 12 -- degrees per second

function HomePanel.new(parent)
    local self = {}
    self._connections = {}
    self._heartbeatConnection = nil
    self._angle = 0 -- current rotation angle in degrees
    self._carouselItems = {} -- Array of { frame, glowFrame, label, glowLabel }

    ---------------------------------------------------------------------------
    -- Root frame (full panel area, below navbar)
    ---------------------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Name = "HomePanel"
    frame.Size = UDim2.new(1, 0, 1, -Theme.Spacing.NavBarHeight) -- full minus nav height
    frame.Position = UDim2.new(0, 0, 1, 0)
    frame.AnchorPoint = Vector2.new(0, 1)
    frame.BackgroundColor3 = Theme.Colors.Background -- black
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ClipsDescendants = true
    frame.ZIndex = Theme.ZIndex.Content
    frame.Parent = parent

    ---------------------------------------------------------------------------
    -- Content: centered column layout
    ---------------------------------------------------------------------------
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ZIndex = Theme.ZIndex.Content + 1
    content.Parent = frame

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, Theme.Spacing.XXL) -- 24px gap
    contentLayout.Parent = content

    ---------------------------------------------------------------------------
    -- Carousel container (h-[400px]/800px)
    ---------------------------------------------------------------------------
    local carouselContainer = Instance.new("Frame")
    carouselContainer.Name = "Carousel"
    carouselContainer.Size = UDim2.new(1, 0, 0, 800) -- h-[400px]/800px
    carouselContainer.BackgroundColor3 = Theme.Colors.Background
    carouselContainer.BackgroundTransparency = 0
    carouselContainer.BorderSizePixel = 0
    carouselContainer.ClipsDescendants = true
    carouselContainer.LayoutOrder = 1
    carouselContainer.ZIndex = Theme.ZIndex.Content + 2
    carouselContainer.Parent = content

    ---------------------------------------------------------------------------
    -- Create carousel items
    ---------------------------------------------------------------------------
    for i = 1, CAROUSEL_ITEM_COUNT do
        local itemFrame = Instance.new("Frame")
        itemFrame.Name = "CarouselItem_" .. i
        itemFrame.Size = UDim2.new(0, 0, 0, 0)
        itemFrame.AutomaticSize = Enum.AutomaticSize.XY
        itemFrame.BackgroundTransparency = 1
        itemFrame.BorderSizePixel = 0
        itemFrame.ZIndex = Theme.ZIndex.Content + 3
        itemFrame.Parent = carouselContainer

        itemFrame.AnchorPoint = Vector2.new(0.5, 0.5)

        -- Glow text (behind, blurred simulation)
        local glowLabel = Instance.new("TextLabel")
        glowLabel.Name = "GlowText"
        glowLabel.Size = UDim2.new(0, 0, 0, 0)
        glowLabel.AutomaticSize = Enum.AutomaticSize.XY
        glowLabel.BackgroundTransparency = 1
        glowLabel.Text = "Blur"
        glowLabel.TextColor3 = Theme.Colors.TextPrimary -- white
        glowLabel.TextSize = Theme.FontSize.CarouselText -- 120px
        glowLabel.Font = Theme.Font.FamilyBlack
        glowLabel.TextTransparency = 0.85 -- high transparency for glow effect
        glowLabel.ZIndex = Theme.ZIndex.Content + 3
        glowLabel.Parent = itemFrame

        -- Main text label
        local label = Instance.new("TextLabel")
        label.Name = "Text"
        label.Size = UDim2.new(0, 0, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.XY
        label.BackgroundTransparency = 1
        label.Text = "Blur"
        label.TextColor3 = Theme.Colors.TextPrimary -- white
        label.TextSize = Theme.FontSize.CarouselText -- 120px (text-6xl)
        label.Font = Theme.Font.FamilyBlack
        label.ZIndex = Theme.ZIndex.Content + 4
        label.Parent = itemFrame

        table.insert(self._carouselItems, {
            frame = itemFrame,
            label = label,
            glowLabel = glowLabel,
        })
    end

    ---------------------------------------------------------------------------
    -- Footer text: "Blur Lasers · Panel v1.0.0"
    -- text-[11px]/22px, neutral-700, tracking-widest, uppercase
    ---------------------------------------------------------------------------
    local footerLabel = Instance.new("TextLabel")
    footerLabel.Name = "Footer"
    footerLabel.Size = UDim2.new(0, 0, 0, 0)
    footerLabel.AutomaticSize = Enum.AutomaticSize.XY
    footerLabel.BackgroundTransparency = 1
    footerLabel.Text = "Blur Lasers \u{00B7} Panel v1.0.0" -- · middle dot
    footerLabel.TextColor3 = Theme.Colors.TextVerySubtle -- neutral-700
    footerLabel.TextSize = Theme.FontSize.Label -- 22px (text-[11px]/22px)
    footerLabel.Font = Theme.Font.FamilyLight
    footerLabel.LayoutOrder = 2
    footerLabel.ZIndex = Theme.ZIndex.Content + 2
    footerLabel.Parent = content

    ---------------------------------------------------------------------------
    -- Carousel update function (called every frame)
    ---------------------------------------------------------------------------
    local function updateCarousel(dt)
        self._angle = self._angle + CAROUSEL_SPEED * dt

        local centerX = carouselContainer.AbsoluteSize.X / 2
        local centerY = carouselContainer.AbsoluteSize.Y / 2

        for i, item in ipairs(self._carouselItems) do
            local angleOffset = (i - 1) * (360 / CAROUSEL_ITEM_COUNT)
            local totalAngle = self._angle + angleOffset
            local radians = math.rad(totalAngle)

            -- Calculate position on circle
            local x = math.sin(radians) * CAROUSEL_RADIUS
            local z = math.cos(radians) * CAROUSEL_RADIUS -- depth (positive = towards viewer)

            -- Normalize depth: -RADIUS to +RADIUS -> 0 to 1
            local depthNorm = (z + CAROUSEL_RADIUS) / (2 * CAROUSEL_RADIUS) -- 0 = far, 1 = near

            -- Position the item
            local itemX = centerX + x
            local itemY = centerY

            item.frame.Position = UDim2.new(0, itemX, 0, itemY)

            -- Scale based on depth (perspective)
            local minScale = 0.5
            local maxScale = 1.2
            local scale = minScale + (maxScale - minScale) * depthNorm

            -- Apply scale by adjusting text size
            local baseTextSize = Theme.FontSize.CarouselText
            local scaledTextSize = baseTextSize * scale

            item.label.TextSize = scaledTextSize
            item.glowLabel.TextSize = scaledTextSize * 1.1 -- slightly larger for glow

            -- Opacity based on depth
            local minOpacity = 0.15
            local maxOpacity = 1.0
            local opacity = minOpacity + (maxOpacity - minOpacity) * depthNorm

            item.label.TextTransparency = 1 - opacity
            item.glowLabel.TextTransparency = math.max(0.7, 1 - opacity * 0.5)

            -- Z-index ordering based on depth (closer = higher z-index)
            local zIdx = Theme.ZIndex.Content + 3 + math.floor(depthNorm * 10)
            item.frame.ZIndex = zIdx
            item.label.ZIndex = zIdx + 1
            item.glowLabel.ZIndex = zIdx

            -- Front-facing items (>0.6 facing): add glow effect
            if depthNorm > 0.6 then
                -- Glow gets more intense as item faces front
                local glowIntensity = (depthNorm - 0.6) / 0.4 -- 0 to 1
                item.glowLabel.TextTransparency = 0.85 - (glowIntensity * 0.5) -- 0.85 to 0.35
            else
                item.glowLabel.TextTransparency = 1 -- hide glow when not facing
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Show / Hide
    ---------------------------------------------------------------------------
    function self.show()
        frame.Visible = true

        -- Fade in
        frame.BackgroundTransparency = 1
        TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
        }):Play()

        -- Start carousel rotation
        if not self._heartbeatConnection then
            self._heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
                if frame.Visible then
                    updateCarousel(dt)
                end
            end)
        end

        -- Footer animation
        footerLabel.TextTransparency = 1
        footerLabel.Position = UDim2.new(0.5, 0, 0, 16)
        footerLabel.AnchorPoint = Vector2.new(0.5, 0)

        local footerInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.6)
        TweenService:Create(footerLabel, footerInfo, {
            Position = UDim2.new(0.5, 0, 0, 0),
            TextTransparency = 0,
        }):Play()
    end

    function self.hide()
        -- Stop carousel rotation
        if self._heartbeatConnection then
            self._heartbeatConnection:Disconnect()
            self._heartbeatConnection = nil
        end

        -- Fade out
        TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
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
        -- Stop heartbeat
        if self._heartbeatConnection then
            self._heartbeatConnection:Disconnect()
            self._heartbeatConnection = nil
        end

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

return HomePanel
