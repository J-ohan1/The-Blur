--[[
    ProfileDropdown.lua — Profile Dropdown Menu
    The-Blur Roblox SurfaceGUI  |  4K (3840x2160)

    Dropdown below avatar showing user info, session timer, keybind count.
    Closes on outside click or Escape key.

    Export: ProfileDropdown.new(parent, store) -> { frame, toggle(), open(), close(), destroy() }
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Theme = require(script.Parent.Theme)
local TweenHelper = require(script.Parent.TweenHelper)

local ProfileDropdown = {}

function ProfileDropdown.new(parent, store)
    assert(store, "ProfileDropdown requires a Store instance")

    local self = {}
    self._connections = {}
    self._store = store
    self._isOpen = false
    self._timerConnection = nil

    ---------------------------------------------------------------------------
    -- Root frame (positioned below nav bar)
    ---------------------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Name = "ProfileDropdown"
    frame.Size = UDim2.new(0, 520, 0, 0) -- w-64(520px), auto height
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Position = UDim2.new(1, -152, 0, 108) -- below avatar (top-[56px] * 2 + padding)
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(3, 3, 3) -- bg-neutral-950/95
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ClipsDescendants = true
    frame.ZIndex = Theme.ZIndex.Dropdown
    frame.Parent = parent

    -- UICorner - rounded-xl (24px)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Theme.CornerRadius.XL)
    corner.Parent = frame

    -- UIStroke - border-neutral-800
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.BorderDefault
    stroke.Thickness = 1
    stroke.Transparency = 0
    stroke.Parent = frame

    -- Arrow/pointer at top
    local arrow = Instance.new("Frame")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.new(0, 20, 0, 10)
    arrow.Position = UDim2.new(1, -40, 0, -9)
    arrow.AnchorPoint = Vector2.new(0.5, 0)
    arrow.BackgroundColor3 = Color3.fromRGB(3, 3, 3)
    arrow.BackgroundTransparency = 0.05
    arrow.BorderSizePixel = 0
    arrow.ZIndex = Theme.ZIndex.Dropdown + 1
    arrow.Parent = frame

    -- Arrow border (right side visible)
    local arrowStroke = Instance.new("UIStroke")
    arrowStroke.Color = Theme.Colors.BorderDefault
    arrowStroke.Thickness = 1
    arrowStroke.Transparency = 0
    arrowStroke.Parent = arrow

    -- Hide bottom border of arrow, hide left border by rotation trick
    -- Actually we just overlay a small frame to create the arrow appearance
    local arrowHide = Instance.new("Frame")
    arrowHide.Size = UDim2.new(1, 2, 0.5, 0)
    arrowHide.Position = UDim2.new(0, -1, 0, 0)
    arrowHide.BackgroundColor3 = Color3.fromRGB(3, 3, 3)
    arrowHide.BackgroundTransparency = 0.05
    arrowHide.BorderSizePixel = 0
    arrowHide.ZIndex = Theme.ZIndex.Dropdown + 2
    arrowHide.Parent = arrow

    ---------------------------------------------------------------------------
    -- Container padding
    ---------------------------------------------------------------------------
    local containerPadding = Instance.new("UIPadding")
    containerPadding.PaddingLeft = UDim.new(0, Theme.Spacing.XXL)   -- 32px
    containerPadding.PaddingRight = UDim.new(0, Theme.Spacing.XXL)
    containerPadding.PaddingTop = UDim.new(0, Theme.Spacing.XXL)
    containerPadding.PaddingBottom = UDim.new(0, Theme.Spacing.XXL)
    containerPadding.Parent = frame

    ---------------------------------------------------------------------------
    -- Vertical layout
    ---------------------------------------------------------------------------
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.FillDirection = Enum.FillDirection.Vertical
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Padding = UDim.new(0, 0)
    mainLayout.Parent = frame

    ---------------------------------------------------------------------------
    -- Section 1: User info (avatar + name + role)
    ---------------------------------------------------------------------------
    local userSection = Instance.new("Frame")
    userSection.Name = "UserSection"
    userSection.Size = UDim2.new(1, 0, 0, 0)
    userSection.AutomaticSize = Enum.AutomaticSize.Y
    userSection.BackgroundTransparency = 1
    userSection.BorderSizePixel = 0
    userSection.LayoutOrder = 1
    userSection.ZIndex = Theme.ZIndex.Dropdown + 3
    userSection.Parent = frame

    local userLayout = Instance.new("UIListLayout")
    userLayout.FillDirection = Enum.FillDirection.Horizontal
    userLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    userLayout.SortOrder = Enum.SortOrder.LayoutOrder
    userLayout.Padding = UDim.new(0, Theme.Spacing.XL) -- 24px gap
    userLayout.Parent = userSection

    -- Avatar with role dot
    local avatarWrap = Instance.new("Frame")
    avatarWrap.Name = "AvatarWrap"
    avatarWrap.Size = UDim2.new(0, Theme.Avatar.Dropdown, 0, Theme.Avatar.Dropdown) -- 72px
    avatarWrap.AutomaticSize = Enum.AutomaticSize.None
    avatarWrap.BackgroundTransparency = 1
    avatarWrap.BorderSizePixel = 0
    avatarWrap.LayoutOrder = 1
    avatarWrap.ZIndex = Theme.ZIndex.Dropdown + 3
    avatarWrap.Parent = userSection

    local avatarFrame = Instance.new("Frame")
    avatarFrame.Name = "Avatar"
    avatarFrame.Size = UDim2.new(1, 0, 1, 0)
    avatarFrame.BackgroundColor3 = Theme.Colors.SurfaceActive -- neutral-800
    avatarFrame.BackgroundTransparency = 0
    avatarFrame.BorderSizePixel = 0
    avatarFrame.ZIndex = Theme.ZIndex.Dropdown + 4
    avatarFrame.Parent = avatarWrap

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0) -- rounded-full
    avatarCorner.Parent = avatarFrame

    local avatarBorder = Instance.new("UIStroke")
    avatarBorder.Color = Theme.Colors.BorderHover -- neutral-700
    avatarBorder.Thickness = 1
    avatarBorder.Parent = avatarFrame

    local avatarInitial = Instance.new("TextLabel")
    avatarInitial.Name = "Initial"
    avatarInitial.Size = UDim2.new(1, 0, 1, 0)
    avatarInitial.BackgroundTransparency = 1
    local userName = store:getCurrentUser().name
    avatarInitial.Text = userName:sub(1, 1):upper()
    avatarInitial.TextColor3 = Theme.Colors.TextSecondary -- neutral-300
    avatarInitial.TextSize = Theme.FontSize.Body -- 28px
    avatarInitial.Font = Theme.Font.FamilyBold
    avatarInitial.ZIndex = Theme.ZIndex.Dropdown + 5
    avatarInitial.Parent = avatarFrame

    -- Role dot on avatar (bottom-right)
    local roleDot = Instance.new("Frame")
    roleDot.Name = "RoleDot"
    roleDot.Size = UDim2.new(0, 24, 0, 24) -- w-3(24px), h-3(24px)
    roleDot.Position = UDim2.new(1, -4, 1, -4)
    roleDot.AnchorPoint = Vector2.new(1, 1)
    local userRole = store:getCurrentUser().role
    roleDot.BackgroundColor3 = Theme.RoleColors[userRole] or Theme.Colors.TextBody
    roleDot.BackgroundTransparency = 0
    roleDot.BorderSizePixel = 0
    roleDot.ZIndex = Theme.ZIndex.Dropdown + 6
    roleDot.Parent = avatarWrap

    local roleDotCorner = Instance.new("UICorner")
    roleDotCorner.CornerRadius = UDim.new(1, 0) -- rounded-full
    roleDotCorner.Parent = roleDot

    -- Role dot border (border-2 border-neutral-950)
    local roleDotBorder = Instance.new("UIStroke")
    roleDotBorder.Color = Color3.fromRGB(3, 3, 3) -- neutral-950
    roleDotBorder.Thickness = 4
    roleDotBorder.Parent = roleDot

    -- Name + Role text container
    local nameContainer = Instance.new("Frame")
    nameContainer.Name = "NameContainer"
    nameContainer.Size = UDim2.new(0, 0, 0, 0)
    nameContainer.AutomaticSize = Enum.AutomaticSize.Y
    nameContainer.BackgroundTransparency = 1
    nameContainer.BorderSizePixel = 0
    nameContainer.LayoutOrder = 2
    nameContainer.ZIndex = Theme.ZIndex.Dropdown + 3
    nameContainer.Parent = userSection

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "UserName"
    nameLabel.Size = UDim2.new(0, 0, 0, 0)
    nameLabel.AutomaticSize = Enum.AutomaticSize.XY
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = userName
    nameLabel.TextColor3 = Theme.Colors.TextPrimary -- white
    nameLabel.TextSize = Theme.FontSize.H4 -- 36px (text-sm)
    nameLabel.Font = Theme.Font.FamilyMedium
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = Theme.ZIndex.Dropdown + 3
    nameLabel.Parent = nameContainer

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Name = "RoleLabel"
    roleLabel.Size = UDim2.new(0, 0, 0, 0)
    roleLabel.AutomaticSize = Enum.AutomaticSize.XY
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = Theme.RoleDisplayNames[userRole] or "Normal"
    roleLabel.TextColor3 = Theme.Colors.TextMuted -- neutral-500
    roleLabel.TextSize = Theme.FontSize.Tiny -- 20px (text-[10px])
    roleLabel.Font = Theme.Font.FamilyMedium
    roleLabel.TextXAlignment = Enum.TextXAlignment.Left
    roleLabel.ZIndex = Theme.ZIndex.Dropdown + 3
    roleLabel.Parent = nameContainer

    ---------------------------------------------------------------------------
    -- Separator (border-b border-neutral-800)
    ---------------------------------------------------------------------------
    local separator1 = Instance.new("Frame")
    separator1.Name = "Separator1"
    separator1.Size = UDim2.new(1, 0, 0, 1)
    separator1.BackgroundColor3 = Theme.Colors.BorderDefault
    separator1.BackgroundTransparency = 0
    separator1.BorderSizePixel = 0
    separator1.LayoutOrder = 2
    separator1.ZIndex = Theme.ZIndex.Dropdown + 3
    separator1.Parent = frame

    ---------------------------------------------------------------------------
    -- Section 2: Session timer
    ---------------------------------------------------------------------------
    local sessionSection = Instance.new("Frame")
    sessionSection.Name = "SessionSection"
    sessionSection.Size = UDim2.new(1, 0, 0, 36)
    sessionSection.BackgroundTransparency = 1
    sessionSection.BorderSizePixel = 0
    sessionSection.LayoutOrder = 3
    sessionSection.ZIndex = Theme.ZIndex.Dropdown + 3
    sessionSection.Parent = frame

    local sessionLabel = Instance.new("TextLabel")
    sessionLabel.Name = "SessionLabel"
    sessionLabel.Size = UDim2.new(0, 0, 1, 0)
    sessionLabel.AutomaticSize = Enum.AutomaticSize.X
    sessionLabel.BackgroundTransparency = 1
    sessionLabel.Text = "Session"
    sessionLabel.TextColor3 = Theme.Colors.TextMuted -- neutral-500
    sessionLabel.TextSize = Theme.FontSize.Small -- 24px (text-xs)
    sessionLabel.Font = Theme.Font.FamilyLight
    sessionLabel.TextXAlignment = Enum.TextXAlignment.Left
    sessionLabel.ZIndex = Theme.ZIndex.Dropdown + 3
    sessionLabel.Parent = sessionSection

    local sessionTimeLabel = Instance.new("TextLabel")
    sessionTimeLabel.Name = "SessionTime"
    sessionTimeLabel.Size = UDim2.new(0, 0, 1, 0)
    sessionTimeLabel.AutomaticSize = Enum.AutomaticSize.X
    sessionTimeLabel.Position = UDim2.new(1, 0, 0, 0)
    sessionTimeLabel.AnchorPoint = Vector2.new(1, 0)
    sessionTimeLabel.BackgroundTransparency = 1
    sessionTimeLabel.Text = "00:00:00"
    sessionTimeLabel.TextColor3 = Theme.Colors.TextSecondary -- neutral-300
    sessionTimeLabel.TextSize = Theme.FontSize.Small -- 24px (text-xs)
    sessionTimeLabel.Font = Theme.Font.Mono -- font-mono
    sessionTimeLabel.TextXAlignment = Enum.TextXAlignment.Right
    sessionTimeLabel.ZIndex = Theme.ZIndex.Dropdown + 3
    sessionTimeLabel.Parent = sessionSection

    ---------------------------------------------------------------------------
    -- Separator 2
    ---------------------------------------------------------------------------
    local separator2 = Instance.new("Frame")
    separator2.Name = "Separator2"
    separator2.Size = UDim2.new(1, 0, 0, 1)
    separator2.BackgroundColor3 = Theme.Colors.BorderDefault
    separator2.BackgroundTransparency = 0
    separator2.BorderSizePixel = 0
    separator2.LayoutOrder = 4
    separator2.ZIndex = Theme.ZIndex.Dropdown + 3
    separator2.Parent = frame

    ---------------------------------------------------------------------------
    -- Section 3: User Defined (keybind count + link)
    ---------------------------------------------------------------------------
    local userDefinedSection = Instance.new("Frame")
    userDefinedSection.Name = "UserDefined"
    userDefinedSection.Size = UDim2.new(1, 0, 0, 0)
    userDefinedSection.AutomaticSize = Enum.AutomaticSize.Y
    userDefinedSection.BackgroundTransparency = 1
    userDefinedSection.BorderSizePixel = 0
    userDefinedSection.LayoutOrder = 5
    userDefinedSection.ZIndex = Theme.ZIndex.Dropdown + 3
    userDefinedSection.Parent = frame

    local userDefLayout = Instance.new("UIListLayout")
    userDefLayout.FillDirection = Enum.FillDirection.Vertical
    userDefLayout.SortOrder = Enum.SortOrder.LayoutOrder
    userDefLayout.Padding = UDim.new(0, Theme.Spacing.Base) -- 16px gap
    userDefLayout.Parent = userDefinedSection

    -- "USER DEFINED" heading
    local userDefHeading = Instance.new("TextLabel")
    userDefHeading.Name = "Heading"
    userDefHeading.Size = UDim2.new(1, 0, 0, 0)
    userDefHeading.AutomaticSize = Enum.AutomaticSize.XY
    userDefHeading.BackgroundTransparency = 1
    userDefHeading.Text = "USER DEFINED"
    userDefHeading.TextColor3 = Theme.Colors.TextSubtle -- neutral-600
    userDefHeading.TextSize = Theme.FontSize.Label -- 22px (text-[11px])
    userDefHeading.Font = Theme.Font.FamilyMedium
    userDefHeading.TextXAlignment = Enum.TextXAlignment.Left
    userDefHeading.LayoutOrder = 1
    userDefHeading.ZIndex = Theme.ZIndex.Dropdown + 3
    userDefHeading.Parent = userDefinedSection

    -- Keybind count row
    local keybindRow = Instance.new("Frame")
    keybindRow.Name = "KeybindRow"
    keybindRow.Size = UDim2.new(1, 0, 0, 0)
    keybindRow.AutomaticSize = Enum.AutomaticSize.Y
    keybindRow.BackgroundTransparency = 1
    keybindRow.BorderSizePixel = 0
    keybindRow.LayoutOrder = 2
    keybindRow.ZIndex = Theme.ZIndex.Dropdown + 3
    keybindRow.Parent = userDefinedSection

    local keybindLabel = Instance.new("TextLabel")
    keybindLabel.Name = "KeybindLabel"
    keybindLabel.Size = UDim2.new(0, 0, 0, 0)
    keybindLabel.AutomaticSize = Enum.AutomaticSize.XY
    keybindLabel.BackgroundTransparency = 1
    keybindLabel.Text = "Keybinds"
    keybindLabel.TextColor3 = Theme.Colors.TextMuted -- neutral-500
    keybindLabel.TextSize = Theme.FontSize.Small -- 24px (text-xs)
    keybindLabel.Font = Theme.Font.FamilyLight
    keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
    keybindLabel.ZIndex = Theme.ZIndex.Dropdown + 3
    keybindLabel.Parent = keybindRow

    local keybindCountBadge = Instance.new("Frame")
    keybindCountBadge.Name = "CountBadge"
    keybindCountBadge.Size = UDim2.new(0, 0, 0, 0)
    keybindCountBadge.AutomaticSize = Enum.AutomaticSize.XY
    keybindCountBadge.Position = UDim2.new(1, 0, 0, 0)
    keybindCountBadge.AnchorPoint = Vector2.new(1, 0)
    keybindCountBadge.BackgroundColor3 = Theme.Colors.SurfaceActive -- bg-neutral-800
    keybindCountBadge.BackgroundTransparency = 0
    keybindCountBadge.BorderSizePixel = 0
    keybindCountBadge.ZIndex = Theme.ZIndex.Dropdown + 4
    keybindCountBadge.Parent = keybindRow

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.MD) -- rounded-md
    badgeCorner.Parent = keybindCountBadge

    local badgePadding = Instance.new("UIPadding")
    badgePadding.PaddingLeft = UDim.new(0, 16) -- px-2(16px)
    badgePadding.PaddingRight = UDim.new(0, 16)
    badgePadding.PaddingTop = UDim.new(0, 4) -- py-0.5(8px)
    badgePadding.PaddingBottom = UDim.new(0, 4)
    badgePadding.Parent = keybindCountBadge

    local badgeText = Instance.new("TextLabel")
    badgeText.Name = "Count"
    badgeText.Size = UDim2.new(0, 0, 0, 0)
    badgeText.AutomaticSize = Enum.AutomaticSize.XY
    badgeText.BackgroundTransparency = 1
    badgeText.Text = tostring(store:getKeybindCount())
    badgeText.TextColor3 = Theme.Colors.TextPrimary -- white
    badgeText.TextSize = Theme.FontSize.Small -- 24px (text-xs)
    badgeText.Font = Theme.Font.FamilyMedium
    badgeText.ZIndex = Theme.ZIndex.Dropdown + 5
    badgeText.Parent = keybindCountBadge

    -- "See all the Keybinds ->" link button
    local keybindLink = Instance.new("TextButton")
    keybindLink.Name = "KeybindLink"
    keybindLink.Size = UDim2.new(1, 0, 0, 0)
    keybindLink.AutomaticSize = Enum.AutomaticSize.XY
    keybindLink.BackgroundTransparency = 1
    keybindLink.Text = "See all the Keybinds ->"
    keybindLink.TextColor3 = Theme.Colors.TextSubtle -- neutral-600
    keybindLink.TextSize = Theme.FontSize.Small -- 24px (text-xs)
    keybindLink.Font = Theme.Font.FamilyLight
    keybindLink.TextXAlignment = Enum.TextXAlignment.Left
    keybindLink.AutoButtonColor = false
    keybindLink.LayoutOrder = 3
    keybindLink.ZIndex = Theme.ZIndex.Dropdown + 4
    keybindLink.Parent = userDefinedSection

    -- Link hover effect
    table.insert(self._connections, keybindLink.MouseEnter:Connect(function()
        TweenService:Create(keybindLink, TweenInfo.new(0.15), {
            TextColor3 = Theme.Colors.TextSecondary -- neutral-300
        }):Play()
    end))

    table.insert(self._connections, keybindLink.MouseLeave:Connect(function()
        TweenService:Create(keybindLink, TweenInfo.new(0.15), {
            TextColor3 = Theme.Colors.TextSubtle -- neutral-600
        }):Play()
    end))

    -- Link click: navigate to keybinds panel and close dropdown
    table.insert(self._connections, keybindLink.Activated:Connect(function()
        store:setActivePanel("keybind")
        self.close()
    end))

    ---------------------------------------------------------------------------
    -- Session timer update
    ---------------------------------------------------------------------------
    local function updateSessionTime()
        local formatted = store:getSessionDurationFormatted()
        sessionTimeLabel.Text = formatted
    end

    local function startSessionTimer()
        updateSessionTime()
        self._timerConnection = spawn(function()
            while self._isOpen do
                wait(1)
                if self._isOpen then
                    updateSessionTime()
                end
            end
        end)
    end

    local function stopSessionTimer()
        self._timerConnection = nil
    end

    ---------------------------------------------------------------------------
    -- Update keybind count when store changes
    ---------------------------------------------------------------------------
    table.insert(self._connections, store:on("keybindsChanged", function()
        badgeText.Text = tostring(store:getKeybindCount())
    end))

    ---------------------------------------------------------------------------
    -- Close on outside click (click on parent that isn't the dropdown)
    ---------------------------------------------------------------------------
    table.insert(self._connections, parent.InputBegan:Connect(function(input)
        if not self._isOpen then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            -- Check if click is inside the dropdown
            local clickPos = input.Position
            local dropdownAbsPos = frame.AbsolutePosition
            local dropdownAbsSize = frame.AbsoluteSize

            if clickPos.X < dropdownAbsPos.X or clickPos.X > dropdownAbsPos.X + dropdownAbsSize.X
                or clickPos.Y < dropdownAbsPos.Y or clickPos.Y > dropdownAbsPos.Y + dropdownAbsSize.Y then
                self.close()
            end
        end
    end))

    -- Close on Escape key
    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Escape and self._isOpen then
            self.close()
        end
    end))

    -- Close when store says so
    table.insert(self._connections, store:on("profileDropdownClosed", function()
        if self._isOpen then
            self.close()
        end
    end))

    ---------------------------------------------------------------------------
    -- Open / Close animations
    ---------------------------------------------------------------------------
    function self.open()
        if self._isOpen then return end
        self._isOpen = true
        store.profileDropdownOpen = true
        frame.Visible = true

        -- Initial state
        frame.BackgroundTransparency = 1
        frame.Position = UDim2.new(1, -152, 0, 108 - 16) -- y - 16 (-8 * 2)
        arrow.BackgroundTransparency = 1

        -- Fade in children
        self:_setChildrenTransparency(frame, 1)

        -- Animate to final state: opacity 0 -> 1, y: -16 -> 0, scale 0.96 -> 1
        local enterInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(frame, enterInfo, {
            BackgroundTransparency = 0.05,
            Position = UDim2.new(1, -152, 0, 108),
        }):Play()

        TweenService:Create(arrow, enterInfo, {
            BackgroundTransparency = 0.05,
        }):Play()

        self:_fadeChildrenIn(frame, 0.2)

        -- Start session timer
        startSessionTimer()

        -- Update keybind count
        badgeText.Text = tostring(store:getKeybindCount())
    end

    function self.close()
        if not self._isOpen then return end
        self._isOpen = false
        store.profileDropdownOpen = false

        -- Stop session timer
        stopSessionTimer()

        -- Exit animation: reverse of enter
        local exitInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(frame, exitInfo, {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -152, 0, 108 - 16),
        }):Play()

        TweenService:Create(arrow, exitInfo, {
            BackgroundTransparency = 1,
        }):Play()

        self:_fadeChildrenOut(frame, 0.2)

        spawn(function()
            wait(0.2)
            if frame and frame.Parent then
                frame.Visible = false
            end
        end)
    end

    function self.toggle()
        if self._isOpen then
            self.close()
        else
            self.open()
        end
    end

    ---------------------------------------------------------------------------
    -- Helper: fade all TextLabel children
    ---------------------------------------------------------------------------
    function self:_setChildrenTransparency(parentInstance, transparency)
        for _, child in ipairs(parentInstance:GetChildren()) do
            if child:IsA("TextLabel") then
                child.TextTransparency = transparency
            elseif child:IsA("TextButton") then
                child.TextTransparency = transparency
            elseif child:IsA("Frame") and child ~= frame then
                self:_setChildrenTransparency(child, transparency)
            end
        end
    end

    function self:_fadeChildrenIn(parentInstance, duration)
        local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        for _, child in ipairs(parentInstance:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                TweenService:Create(child, info, { TextTransparency = 0 }):Play()
            elseif child:IsA("Frame") and child ~= frame then
                self:_fadeChildrenIn(child, duration)
            end
        end
    end

    function self:_fadeChildrenOut(parentInstance, duration)
        local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        for _, child in ipairs(parentInstance:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                TweenService:Create(child, info, { TextTransparency = 1 }):Play()
            elseif child:IsA("Frame") and child ~= frame then
                self:_fadeChildrenOut(child, duration)
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Destroy
    ---------------------------------------------------------------------------
    function self.destroy()
        stopSessionTimer()

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

return ProfileDropdown
