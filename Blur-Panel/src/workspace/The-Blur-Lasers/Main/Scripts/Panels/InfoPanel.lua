--[[
    InfoPanel.lua — Information Panel
    The-Blur Roblox SurfaceGUI  |  4K (3840x2160)

    Centered content with Credits, Version, and Bug Fixes cards.

    Export: InfoPanel.new(parent) -> { frame, show(), hide(), destroy() }
]]

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Parent.Theme)
local TweenHelper = require(script.Parent.Parent.TweenHelper)

local InfoPanel = {}

function InfoPanel.new(parent)
    local self = {}
    self._connections = {}

    ---------------------------------------------------------------------------
    -- Root frame (full panel area, below navbar)
    ---------------------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Name = "InfoPanel"
    frame.Size = UDim2.new(1, 0, 1, -Theme.Spacing.NavBarHeight) -- full minus nav
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
    -- Centered content wrapper (max-width ~680px/1360px)
    ---------------------------------------------------------------------------
    local centerWrapper = Instance.new("Frame")
    centerWrapper.Name = "CenterWrapper"
    centerWrapper.Size = UDim2.new(0, 1360, 1, 0) -- max-w-md(1360px)
    centerWrapper.Position = UDim2.new(0.5, 0, 0, 0)
    centerWrapper.AnchorPoint = Vector2.new(0.5, 0)
    centerWrapper.BackgroundTransparency = 1
    centerWrapper.BorderSizePixel = 0
    centerWrapper.ZIndex = Theme.ZIndex.Content + 1
    centerWrapper.Parent = frame

    -- Inner padding (p-4/32px, pt-14/112px)
    local wrapperPadding = Instance.new("UIPadding")
    wrapperPadding.PaddingLeft = UDim.new(0, Theme.Spacing.XXL)   -- 32px
    wrapperPadding.PaddingRight = UDim.new(0, Theme.Spacing.XXL)
    wrapperPadding.PaddingTop = UDim.new(0, Theme.Spacing.PanelTopOffset) -- 112px (pt-14)
    wrapperPadding.PaddingBottom = UDim.new(0, Theme.Spacing.XXL)
    wrapperPadding.Parent = centerWrapper

    -- Vertical layout
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.FillDirection = Enum.FillDirection.Vertical
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Padding = UDim.new(0, Theme.Spacing.XL) -- 24px gap (mb-6)
    mainLayout.Parent = centerWrapper

    ---------------------------------------------------------------------------
    -- Header section
    ---------------------------------------------------------------------------
    local headerSection = Instance.new("Frame")
    headerSection.Name = "Header"
    headerSection.Size = UDim2.new(1, 0, 0, 0)
    headerSection.AutomaticSize = Enum.AutomaticSize.Y
    headerSection.BackgroundTransparency = 1
    headerSection.BorderSizePixel = 0
    headerSection.LayoutOrder = 1
    headerSection.ZIndex = Theme.ZIndex.Content + 2
    headerSection.Parent = centerWrapper

    local headerLayout = Instance.new("UIListLayout")
    headerLayout.FillDirection = Enum.FillDirection.Vertical
    headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    headerLayout.Padding = UDim.new(0, Theme.Spacing.XS) -- 4px gap (mt-0.5)
    headerLayout.Parent = headerSection

    -- Title: "Blur Lasers" (text-lg/36px, white, semibold)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0, 0, 0, 0)
    titleLabel.AutomaticSize = Enum.AutomaticSize.XY
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Blur Lasers"
    titleLabel.TextColor3 = Theme.Colors.TextPrimary -- white
    titleLabel.TextSize = Theme.FontSize.H2 -- 56px (text-lg)
    titleLabel.Font = Theme.Font.FamilySemibold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.LayoutOrder = 1
    titleLabel.ZIndex = Theme.ZIndex.Content + 2
    titleLabel.Parent = headerSection

    -- Subtitle: "Panel Information" (text-[11px]/22px, neutral-600)
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(0, 0, 0, 0)
    subtitleLabel.AutomaticSize = Enum.AutomaticSize.XY
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Panel Information"
    subtitleLabel.TextColor3 = Theme.Colors.TextSubtle -- neutral-600
    subtitleLabel.TextSize = Theme.FontSize.Label -- 22px (text-[11px])
    subtitleLabel.Font = Theme.Font.FamilyLight
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.LayoutOrder = 2
    subtitleLabel.ZIndex = Theme.ZIndex.Content + 2
    subtitleLabel.Parent = headerSection

    ---------------------------------------------------------------------------
    -- Helper: Create an info card
    ---------------------------------------------------------------------------
    local function createInfoCard(name, headerTitle, layoutOrder)
        local card = Instance.new("Frame")
        card.Name = name
        card.Size = UDim2.new(1, 0, 0, 0)
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.BackgroundColor3 = Theme.Colors.PanelBackground -- neutral-950/50
        card.BackgroundTransparency = 0.5
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.LayoutOrder = layoutOrder
        card.ZIndex = Theme.ZIndex.Content + 2
        card.Parent = centerWrapper

        -- UICorner - rounded-xl (24px)
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.XL)
        cardCorner.Parent = card

        -- UIStroke - border-neutral-800/70
        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = Theme.Colors.BorderDefault
        cardStroke.Thickness = 1
        cardStroke.Transparency = 0.3
        cardStroke.Parent = card

        local cardLayout = Instance.new("UIListLayout")
        cardLayout.FillDirection = Enum.FillDirection.Vertical
        cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
        cardLayout.Padding = UDim.new(0, 0)
        cardLayout.Parent = card

        -- Card header row (h-8/64px, border-b, px-4)
        local cardHeader = Instance.new("Frame")
        cardHeader.Name = "CardHeader"
        cardHeader.Size = UDim2.new(1, 0, 0, 64) -- h-8(64px)
        cardHeader.BackgroundTransparency = 1
        cardHeader.BorderSizePixel = 0
        cardHeader.LayoutOrder = 1
        cardHeader.ZIndex = Theme.ZIndex.Content + 3
        cardHeader.Parent = card

        local headerPadding = Instance.new("UIPadding")
        headerPadding.PaddingLeft = UDim.new(0, 32) -- px-4(32px)
        headerPadding.PaddingRight = UDim.new(0, 32)
        headerPadding.Parent = cardHeader

        -- Header title
        local headerLabel = Instance.new("TextLabel")
        headerLabel.Size = UDim2.new(1, 0, 1, 0)
        headerLabel.BackgroundTransparency = 1
        headerLabel.Text = headerTitle
        headerLabel.TextColor3 = Theme.Colors.TextSecondary -- neutral-300
        headerLabel.TextSize = Theme.FontSize.Small -- 24px (text-[12px])
        headerLabel.Font = Theme.Font.FamilySemibold
        headerLabel.TextXAlignment = Enum.TextXAlignment.Left
        headerLabel.ZIndex = Theme.ZIndex.Content + 3
        headerLabel.Parent = cardHeader

        -- Header bottom border
        local headerBorder = Instance.new("Frame")
        headerBorder.Size = UDim2.new(1, 0, 0, 1)
        headerBorder.Position = UDim2.new(0, 0, 1, -1)
        headerBorder.BackgroundColor3 = Theme.Colors.BorderDefault -- neutral-800
        headerBorder.BackgroundTransparency = 0.5 -- /50
        headerBorder.BorderSizePixel = 0
        headerBorder.ZIndex = Theme.ZIndex.Content + 4
        headerBorder.Parent = cardHeader

        -- Card content area
        local cardContent = Instance.new("Frame")
        cardContent.Name = "CardContent"
        cardContent.Size = UDim2.new(1, 0, 0, 0)
        cardContent.AutomaticSize = Enum.AutomaticSize.Y
        cardContent.BackgroundTransparency = 1
        cardContent.BorderSizePixel = 0
        cardContent.LayoutOrder = 2
        cardContent.ClipsDescendants = true
        cardContent.ZIndex = Theme.ZIndex.Content + 3
        cardContent.Parent = card

        return card, cardContent
    end

    ---------------------------------------------------------------------------
    -- Helper: Create a credit row (label + value, space-between)
    ---------------------------------------------------------------------------
    local function createCreditRow(parentInstance, labelText, valueText, layoutOrder)
        local row = Instance.new("Frame")
        row.Name = "CreditRow_" .. labelText
        row.Size = UDim2.new(1, 0, 0, 0)
        row.AutomaticSize = Enum.AutomaticSize.Y
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.LayoutOrder = layoutOrder
        row.ZIndex = Theme.ZIndex.Content + 4
        row.Parent = parentInstance

        local rowPadding = Instance.new("UIPadding")
        rowPadding.PaddingLeft = UDim.new(0, 32) -- px-4(32px)
        rowPadding.PaddingRight = UDim.new(0, 32)
        rowPadding.PaddingTop = UDim.new(0, 16)
        rowPadding.PaddingBottom = UDim.new(0, 16)
        rowPadding.Parent = row

        local rowLabel = Instance.new("TextLabel")
        rowLabel.Name = "Label"
        rowLabel.Size = UDim2.new(0, 0, 0, 0)
        rowLabel.AutomaticSize = Enum.AutomaticSize.XY
        rowLabel.BackgroundTransparency = 1
        rowLabel.Text = labelText
        rowLabel.TextColor3 = Theme.Colors.TextSubtle -- neutral-600
        rowLabel.TextSize = Theme.FontSize.Label -- 22px (text-[11px])
        rowLabel.Font = Theme.Font.FamilyLight
        rowLabel.TextXAlignment = Enum.TextXAlignment.Left
        rowLabel.ZIndex = Theme.ZIndex.Content + 4
        rowLabel.Parent = row

        local rowValue = Instance.new("TextLabel")
        rowValue.Name = "Value"
        rowValue.Size = UDim2.new(0, 0, 0, 0)
        rowValue.AutomaticSize = Enum.AutomaticSize.XY
        rowValue.Position = UDim2.new(1, 0, 0, 0)
        rowValue.AnchorPoint = Vector2.new(1, 0)
        rowValue.BackgroundTransparency = 1
        rowValue.Text = valueText
        rowValue.TextColor3 = Theme.Colors.TextSecondary -- neutral-300
        rowValue.TextSize = Theme.FontSize.Small -- 24px (text-[12px])
        rowValue.Font = Theme.Font.FamilyMedium
        rowValue.TextXAlignment = Enum.TextXAlignment.Right
        rowValue.ZIndex = Theme.ZIndex.Content + 4
        rowValue.Parent = row
    end

    ---------------------------------------------------------------------------
    -- Card 1: Credits
    ---------------------------------------------------------------------------
    local creditsCard, creditsContent = createInfoCard("CreditsCard", "Credits", 2)

    local creditsLayout = Instance.new("UIListLayout")
    creditsLayout.FillDirection = Enum.FillDirection.Vertical
    creditsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    creditsLayout.Padding = UDim.new(0, 0)
    creditsLayout.Parent = creditsContent

    createCreditRow(creditsContent, "Code written by", "Johan", 1)
    createCreditRow(creditsContent, "UI made by", "Johan", 2)
    createCreditRow(creditsContent, "Models made by", "Johan", 3)

    ---------------------------------------------------------------------------
    -- Card 2: Version
    ---------------------------------------------------------------------------
    local versionCard, versionContent = createInfoCard("VersionCard", "Version", 3)

    local versionInner = Instance.new("Frame")
    versionInner.Name = "VersionInner"
    versionInner.Size = UDim2.new(1, 0, 0, 0)
    versionInner.AutomaticSize = Enum.AutomaticSize.Y
    versionInner.BackgroundTransparency = 1
    versionInner.BorderSizePixel = 0
    versionInner.ZIndex = Theme.ZIndex.Content + 4
    versionInner.Parent = versionContent

    local versionPadding = Instance.new("UIPadding")
    versionPadding.PaddingLeft = UDim.new(0, 32) -- px-4(32px)
    versionPadding.PaddingRight = UDim.new(0, 32)
    versionPadding.PaddingTop = UDim.new(0, 16)
    versionPadding.PaddingBottom = UDim.new(0, 16)
    versionPadding.Parent = versionInner

    -- "v1.0.0" text
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Name = "VersionText"
    versionLabel.Size = UDim2.new(0, 0, 0, 0)
    versionLabel.AutomaticSize = Enum.AutomaticSize.XY
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "v1.0.0"
    versionLabel.TextColor3 = Theme.Colors.TextSecondary -- neutral-300
    versionLabel.TextSize = Theme.FontSize.Small -- 24px (text-[12px])
    versionLabel.Font = Theme.Font.FamilyMedium
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    versionLabel.ZIndex = Theme.ZIndex.Content + 5
    versionLabel.Parent = versionInner

    -- "Current" badge
    local currentBadge = Instance.new("Frame")
    currentBadge.Name = "CurrentBadge"
    currentBadge.Size = UDim2.new(0, 0, 0, 0)
    currentBadge.AutomaticSize = Enum.AutomaticSize.XY
    currentBadge.Position = UDim2.new(0, 0, 0.5, 0)
    currentBadge.AnchorPoint = Vector2.new(0, 0.5)
    currentBadge.BackgroundColor3 = Theme.Colors.SurfaceActive -- bg-neutral-800/60
    currentBadge.BackgroundTransparency = 0.4
    currentBadge.BorderSizePixel = 0
    currentBadge.ZIndex = Theme.ZIndex.Content + 5
    currentBadge.Parent = versionInner

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.MD) -- rounded-md
    badgeCorner.Parent = currentBadge

    local badgePad = Instance.new("UIPadding")
    badgePad.PaddingLeft = UDim.new(0, 24) -- px-3(24px)
    badgePad.PaddingRight = UDim.new(0, 24)
    badgePad.PaddingTop = UDim.new(0, 4) -- py-0.5(8px)
    badgePad.PaddingBottom = UDim.new(0, 4)
    badgePad.Parent = currentBadge

    local badgeText = Instance.new("TextLabel")
    badgeText.Size = UDim2.new(0, 0, 0, 0)
    badgeText.AutomaticSize = Enum.AutomaticSize.XY
    badgeText.BackgroundTransparency = 1
    badgeText.Text = "Current"
    badgeText.TextColor3 = Theme.Colors.TextMuted -- neutral-500
    badgeText.TextSize = Theme.FontSize.Tiny -- 20px (text-[10px])
    badgeText.Font = Theme.Font.FamilyMedium
    badgeText.ZIndex = Theme.ZIndex.Content + 6
    badgeText.Parent = currentBadge

    ---------------------------------------------------------------------------
    -- Card 3: Bug Fixes
    ---------------------------------------------------------------------------
    local bugCard, bugContent = createInfoCard("BugFixesCard", "Bug Fixes", 4)

    local bugCenter = Instance.new("Frame")
    bugCenter.Name = "BugCenter"
    bugCenter.Size = UDim2.new(1, 0, 0, 48)
    bugCenter.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bugCenter.BackgroundTransparency = 1
    bugCenter.BorderSizePixel = 0
    bugCenter.ZIndex = Theme.ZIndex.Content + 4
    bugCenter.Parent = bugContent

    local bugPadding = Instance.new("UIPadding")
    bugPadding.PaddingTop = UDim.new(0, 48) -- p-6(48px)
    bugPadding.PaddingBottom = UDim.new(0, 48)
    bugPadding.Parent = bugContent

    local bugLabel = Instance.new("TextLabel")
    bugLabel.Name = "NoBugs"
    bugLabel.Size = UDim2.new(1, 0, 1, 0)
    bugLabel.BackgroundTransparency = 1
    bugLabel.Text = "No bugs found yet"
    bugLabel.TextColor3 = Theme.Colors.TextSubtle -- neutral-600
    bugLabel.TextSize = Theme.FontSize.Small -- 24px (text-[12px])
    bugLabel.Font = Theme.Font.FamilyLight
    bugLabel.ZIndex = Theme.ZIndex.Content + 5
    bugLabel.Parent = bugCenter

    ---------------------------------------------------------------------------
    -- Show / Hide
    ---------------------------------------------------------------------------
    function self.show()
        frame.Visible = true

        -- Fade in
        frame.BackgroundTransparency = 1
        self:_setAllTransparency(frame, 1)

        local fadeInInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15)
        TweenService:Create(frame, fadeInInfo, {
            BackgroundTransparency = 0,
        }):Play()

        self:_fadeInAll(frame, 0.4, 0.15)
    end

    function self.hide()
        local fadeOutInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(frame, fadeOutInfo, {
            BackgroundTransparency = 1,
        }):Play()

        self:_fadeOutAll(frame, 0.3)

        spawn(function()
            wait(0.35)
            frame.Visible = false
            frame.BackgroundTransparency = 0
        end)
    end

    ---------------------------------------------------------------------------
    -- Helpers
    ---------------------------------------------------------------------------
    function self:_setAllTransparency(instance, transparency)
        for _, child in ipairs(instance:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                child.TextTransparency = transparency
            elseif child:IsA("Frame") then
                if child.BackgroundTransparency < 1 then
                    child:SetAttribute("_origTransparency", child.BackgroundTransparency)
                end
                self:_setAllTransparency(child, transparency)
            end
        end
    end

    function self:_fadeInAll(instance, duration, delay)
        local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, delay)
        for _, child in ipairs(instance:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                TweenService:Create(child, info, { TextTransparency = 0 }):Play()
            elseif child:IsA("Frame") then
                self:_fadeInAll(child, duration, delay)
            end
        end
    end

    function self:_fadeOutAll(instance, duration)
        local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        for _, child in ipairs(instance:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                TweenService:Create(child, info, { TextTransparency = 1 }):Play()
            elseif child:IsA("Frame") then
                self:_fadeOutAll(child, duration)
            end
        end
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

return InfoPanel
