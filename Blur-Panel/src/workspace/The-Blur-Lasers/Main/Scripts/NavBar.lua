--[[
    NavBar.lua — Navigation Bar Component
    The-Blur Roblox SurfaceGUI  |  4K (3840x2160)

    Pixel-perfect replica of the web NavBar component.
    Fixed top bar with brand, 10 nav tabs, avatar.

    Export: NavBar.new(parent, store) -> { frame, destroy(), setActivePanel(name),
             updateKeybindCount(count), updateGroupDot(hasGroups), show(), hide() }
]]

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Theme)
local TweenHelper = require(script.Parent.TweenHelper)

local NavBar = {}

local NAV_BUTTONS = {
    { label = "Home",          key = "home" },
    { label = "Control",       key = "control" },
    { label = "Customization", key = "customisation" },
    { label = "Group",         key = "group" },
    { label = "Player",        key = "player" },
    { label = "Effect",        key = "effect" },
    { label = "Hub",           key = "hub" },
    { label = "Keybind",       key = "keybind" },
    { label = "Timecode",      key = "timecode" },
    { label = "Info",          key = "info" },
}

function NavBar.new(parent, store)
    assert(store, "NavBar requires a Store instance")

    local self = {}
    self._connections = {}
    self._store = store
    self._activePanel = store:getActivePanel()

    ---------------------------------------------------------------------------
    -- Root container (full width, fixed top)
    ---------------------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Name = "NavBar"
    frame.Size = UDim2.new(1, 0, 0, Theme.Spacing.NavBarHeight) -- 96px
    frame.Position = UDim2.new(0, 0, 0, -Theme.Spacing.NavBarHeight) -- off-screen
    frame.BackgroundColor3 = Theme.Colors.Background
    frame.BackgroundTransparency = Theme.Transparency.NavBar -- 0.1 = 90% opacity
    frame.BorderSizePixel = 0
    frame.ZIndex = Theme.ZIndex.Top
    frame.Parent = parent

    -- UICorner (optional slight rounding — nav is full-width so no rounding needed,
    -- but we apply it for consistency with backdrop-blur aesthetic)
    -- No corner radius on navbar per web design

    -- Bottom border (border-b border-neutral-800/60)
    local bottomBorder = Instance.new("Frame")
    bottomBorder.Name = "BottomBorder"
    bottomBorder.Size = UDim2.new(1, 0, 0, 1)
    bottomBorder.Position = UDim2.new(0, 0, 1, -1)
    bottomBorder.BackgroundColor3 = Theme.Colors.BorderDefault -- neutral-800
    bottomBorder.BackgroundTransparency = 0.4 -- /60 equivalent
    bottomBorder.BorderSizePixel = 0
    bottomBorder.ZIndex = Theme.ZIndex.Top + 1
    bottomBorder.Parent = frame

    ---------------------------------------------------------------------------
    -- Layout: UIListLayout won't work for 3-section flex layout.
    -- We use 3 separate frames: left, center, right.
    ---------------------------------------------------------------------------

    -- === LEFT SECTION: Brand ===
    local leftSection = Instance.new("Frame")
    leftSection.Name = "Left"
    leftSection.Size = UDim2.new(0, 600, 1, 0) -- fixed width for left
    leftSection.Position = UDim2.new(0, 0, 0, 0)
    leftSection.BackgroundTransparency = 1
    leftSection.BorderSizePixel = 0
    leftSection.ZIndex = Theme.ZIndex.Top + 2
    leftSection.Parent = frame

    local leftPadding = Instance.new("UIPadding")
    leftPadding.PaddingLeft = UDim.new(0, Theme.Spacing.NavBarPaddingX) -- 48px
    leftPadding.PaddingRight = UDim.new(0, 0)
    leftPadding.PaddingTop = UDim.new(0, 0)
    leftPadding.PaddingBottom = UDim.new(0, 0)
    leftPadding.Parent = leftSection

    local leftLayout = Instance.new("UIListLayout")
    leftLayout.FillDirection = Enum.FillDirection.Horizontal
    leftLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Padding = UDim.new(0, Theme.Spacing.XXL) -- 32px gap
    leftLayout.Parent = leftSection

    -- "Blur" brand text
    local brandLabel = Instance.new("TextLabel")
    brandLabel.Name = "Brand"
    brandLabel.Size = UDim2.new(0, 0, 0, Theme.FontSize.NavTab) -- 24px, auto-width
    brandLabel.AutomaticSize = Enum.AutomaticSize.X
    brandLabel.BackgroundTransparency = 1
    brandLabel.Text = "Blur"
    brandLabel.TextColor3 = Theme.Colors.TextPrimary -- white
    brandLabel.TextSize = Theme.FontSize.Label -- 22px (text-sm/28px equivalent)
    brandLabel.Font = Theme.Font.FamilySemibold -- semibold
    brandLabel.TextXAlignment = Enum.TextXAlignment.Left
    brandLabel.LayoutOrder = 1
    brandLabel.ZIndex = Theme.ZIndex.Top + 2
    brandLabel.Parent = leftSection

    -- "Laser-version 1.0.0" — easter egg trigger (3 clicks in 2s)
    local versionButton = Instance.new("TextButton")
    versionButton.Name = "VersionButton"
    versionButton.Size = UDim2.new(0, 0, 0, 0)
    versionButton.AutomaticSize = Enum.AutomaticSize.XY
    versionButton.BackgroundTransparency = 1
    versionButton.Text = "Laser-version 1.0.0"
    versionButton.TextColor3 = Theme.Colors.TextSubtle -- neutral-600
    versionButton.TextSize = Theme.FontSize.Label -- 22px (text-[11px]/22px)
    versionButton.Font = Theme.Font.FamilyLight
    versionButton.TextXAlignment = Enum.TextXAlignment.Left
    versionButton.AutoButtonColor = false
    versionButton.LayoutOrder = 2
    versionButton.ZIndex = Theme.ZIndex.Top + 2
    versionButton.Parent = leftSection

    -- === CENTER SECTION: Nav tabs ===
    local centerSection = Instance.new("Frame")
    centerSection.Name = "Center"
    centerSection.Size = UDim2.new(0, 0, 1, 0) -- auto-sized
    centerSection.AutomaticSize = Enum.AutomaticSize.X
    centerSection.Position = UDim2.new(0.5, 0, 0, 0)
    centerSection.AnchorPoint = Vector2.new(0.5, 0)
    centerSection.BackgroundTransparency = 1
    centerSection.BorderSizePixel = 0
    centerSection.ZIndex = Theme.ZIndex.Top + 2
    centerSection.Parent = frame

    local centerLayout = Instance.new("UIListLayout")
    centerLayout.FillDirection = Enum.FillDirection.Horizontal
    centerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    centerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    centerLayout.Padding = UDim.new(0, Theme.Spacing.XS) -- 4px gap
    centerLayout.Parent = centerSection

    -- Active underline bar (shared, animated between buttons)
    local underlineBar = Instance.new("Frame")
    underlineBar.Name = "UnderlineBar"
    underlineBar.Size = UDim2.new(0, 100, 0, 4) -- 4px = 2px web * 2
    underlineBar.BackgroundColor3 = Theme.Colors.TextPrimary -- white
    underlineBar.BackgroundTransparency = 0
    underlineBar.BorderSizePixel = 0
    underlineBar.AnchorPoint = Vector2.new(0.5, 1)
    underlineBar.ZIndex = Theme.ZIndex.Top + 5
    underlineBar.Parent = frame

    local underlineCorner = Instance.new("UICorner")
    underlineCorner.CornerRadius = UDim.new(1, 0) -- rounded-full
    underlineCorner.Parent = underlineBar

    -- Create tab buttons
    local tabButtons = {} -- key -> button instance
    local tabLabels = {} -- key -> label inside button

    for i, item in ipairs(NAV_BUTTONS) do
        local btn = Instance.new("TextButton")
        btn.Name = "Tab_" .. item.key
        btn.Size = UDim2.new(0, 0, 0, 0)
        btn.AutomaticSize = Enum.AutomaticSize.XY
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.LayoutOrder = i
        btn.ZIndex = Theme.ZIndex.Top + 3
        btn.Parent = centerSection

        -- Button padding (px-4/32px, py-2/16px)
        local btnPadding = Instance.new("UIPadding")
        btnPadding.PaddingLeft = UDim.new(0, 32) -- px-4 * 2
        btnPadding.PaddingRight = UDim.new(0, 32)
        btnPadding.PaddingTop = UDim.new(0, 16) -- py-2 * 2
        btnPadding.PaddingBottom = UDim.new(0, 16)
        btnPadding.Parent = btn

        -- Text label inside button
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0, 0, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.XY
        label.BackgroundTransparency = 1
        label.Text = item.label
        label.TextColor3 = Theme.Colors.TextMuted -- neutral-500
        label.TextSize = 26 -- text-[13px]/26px
        label.Font = Theme.Font.FamilyMedium -- font-medium
        label.ZIndex = Theme.ZIndex.Top + 3
        label.Parent = btn

        -- Keybind count badge (only for "keybind" tab)
        local keybindBadge = nil
        if item.key == "keybind" then
            keybindBadge = Instance.new("Frame")
            keybindBadge.Name = "KeybindBadge"
            keybindBadge.Size = UDim2.new(0, 28, 0, 28) -- min-w-[14px]/28px, h-[14px]/28px
            keybindBadge.Position = UDim2.new(1, -4, 0, -4) -- top-right
            keybindBadge.AnchorPoint = Vector2.new(1, 0)
            keybindBadge.BackgroundColor3 = Theme.Colors.ButtonPrimary -- white
            keybindBadge.BackgroundTransparency = 0
            keybindBadge.BorderSizePixel = 0
            keybindBadge.Visible = false -- hidden until keybinds exist
            keybindBadge.ZIndex = Theme.ZIndex.Top + 6
            keybindBadge.Parent = btn

            local badgeCorner = Instance.new("UICorner")
            badgeCorner.CornerRadius = UDim.new(1, 0) -- rounded-full
            badgeCorner.Parent = keybindBadge

            local badgeLabel = Instance.new("TextLabel")
            badgeLabel.Name = "Count"
            badgeLabel.Size = UDim2.new(1, 0, 1, 0)
            badgeLabel.BackgroundTransparency = 1
            badgeLabel.Text = "0"
            badgeLabel.TextColor3 = Theme.Colors.ButtonPrimaryText -- black
            badgeLabel.TextSize = Theme.FontSize.Micro -- 18px (text-[9px]/18px)
            badgeLabel.Font = Theme.Font.FamilyBold
            badgeLabel.ZIndex = Theme.ZIndex.Top + 7
            badgeLabel.Parent = keybindBadge
        end

        -- Group blink dot (only for "group" tab when groups.length === 0)
        local groupDot = nil
        if item.key == "group" then
            groupDot = Instance.new("Frame")
            groupDot.Name = "GroupDot"
            groupDot.Size = UDim2.new(0, 3, 0, 3) -- w-1.5/3px, h-1.5/3px
            groupDot.Position = UDim2.new(1, -8, 0, 8) -- top-1, right-1
            groupDot.AnchorPoint = Vector2.new(1, 0)
            groupDot.BackgroundColor3 = Theme.Colors.TextPrimary -- white
            groupDot.BackgroundTransparency = 0
            groupDot.BorderSizePixel = 0
            groupDot.Visible = #store.groups == 0 -- visible when no groups
            groupDot.ZIndex = Theme.ZIndex.Top + 6
            groupDot.Parent = btn

            local dotCorner = Instance.new("UICorner")
            dotCorner.CornerRadius = UDim.new(1, 0) -- rounded-full
            dotCorner.Parent = groupDot

            -- Blink animation: opacity cycling 1 -> 0 -> 1 over 1.5s
            TweenHelper.pulse(groupDot, "BackgroundTransparency", 0, 1, 1.5)
        end

        tabButtons[item.key] = btn
        tabLabels[item.key] = label

        -- Store references for badge/dot updates
        self["_keybindBadge"] = keybindBadge
        self["_groupDot_" .. item.key] = groupDot

        -- Hover effect (text neutral-500 -> white, 200ms transition)
        table.insert(self._connections, btn.MouseEnter:Connect(function()
            if self._activePanel ~= item.key then
                TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextColor3 = Theme.Colors.TextPrimary -- white
                }):Play()
            end
        end))

        table.insert(self._connections, btn.MouseLeave:Connect(function()
            if self._activePanel ~= item.key then
                TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextColor3 = Theme.Colors.TextMuted -- neutral-500
                }):Play()
            end
        end))

        -- Click handler: set active panel
        table.insert(self._connections, btn.Activated:Connect(function()
            store:setActivePanel(item.key)
        end))
    end

    -- === RIGHT SECTION: Avatar ===
    local rightSection = Instance.new("Frame")
    rightSection.Name = "Right"
    rightSection.Size = UDim2.new(0, 200, 1, 0)
    rightSection.Position = UDim2.new(1, 0, 0, 0)
    rightSection.AnchorPoint = Vector2.new(1, 0)
    rightSection.BackgroundTransparency = 1
    rightSection.BorderSizePixel = 0
    rightSection.ZIndex = Theme.ZIndex.Top + 2
    rightSection.Parent = frame

    local rightPadding = Instance.new("UIPadding")
    rightPadding.PaddingRight = UDim.new(0, Theme.Spacing.NavBarPaddingX) -- 48px
    rightPadding.Parent = rightSection

    -- Avatar button (w-7/56px, h-7/56px)
    local avatarContainer = Instance.new("Frame")
    avatarContainer.Name = "AvatarContainer"
    avatarContainer.Size = UDim2.new(0, 72, 0, 96) -- extra space for dropdown positioning
    avatarContainer.Position = UDim2.new(1, 0, 0, 0)
    avatarContainer.AnchorPoint = Vector2.new(1, 0)
    avatarContainer.BackgroundTransparency = 1
    avatarContainer.BorderSizePixel = 0
    avatarContainer.ClipsDescendants = false
    avatarContainer.ZIndex = Theme.ZIndex.Top + 2
    avatarContainer.Parent = rightSection

    local avatarButton = Instance.new("TextButton")
    avatarButton.Name = "AvatarButton"
    avatarButton.Size = UDim2.new(0, Theme.Avatar.Nav, 0, Theme.Avatar.Nav) -- 56x56
    avatarButton.Position = UDim2.new(1, 0, 0.5, 0)
    avatarButton.AnchorPoint = Vector2.new(1, 0.5)
    avatarButton.BackgroundColor3 = Theme.Colors.SurfaceActive -- neutral-800/bg-neutral-700 equivalent
    avatarButton.BackgroundTransparency = 0
    avatarButton.BorderSizePixel = 0
    avatarButton.Text = ""
    avatarButton.AutoButtonColor = false
    avatarButton.ZIndex = Theme.ZIndex.Top + 3
    avatarButton.Parent = avatarContainer

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0) -- rounded-full
    avatarCorner.Parent = avatarButton

    -- Avatar border stroke
    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = Theme.Colors.BorderHover -- neutral-700
    avatarStroke.Thickness = 1
    avatarStroke.Transparency = 0
    avatarStroke.Parent = avatarButton

    -- Avatar initial letter
    local avatarInitial = Instance.new("TextLabel")
    avatarInitial.Name = "Initial"
    avatarInitial.Size = UDim2.new(1, 0, 1, 0)
    avatarInitial.BackgroundTransparency = 1
    local userName = store:getCurrentUser().name
    avatarInitial.Text = userName:sub(1, 1):upper()
    avatarInitial.TextColor3 = Theme.Colors.TextBody -- neutral-400
    avatarInitial.TextSize = 20 -- text-[10px]/20px
    avatarInitial.Font = Theme.Font.FamilyBold
    avatarInitial.ZIndex = Theme.ZIndex.Top + 4
    avatarInitial.Parent = avatarButton

    -- Avatar hover/tap effects
    table.insert(self._connections, avatarButton.MouseEnter:Connect(function()
        TweenHelper.hoverScale(avatarButton, 1.05, 0.15)
        TweenService:Create(avatarStroke, TweenInfo.new(0.2), {
            Color = Theme.Colors.TextMuted -- neutral-500 on hover
        }):Play()
    end))

    table.insert(self._connections, avatarButton.MouseLeave:Connect(function()
        TweenHelper.unhoverScale(avatarButton, UDim2.new(0, Theme.Avatar.Nav, 0, Theme.Avatar.Nav), 0.1)
        TweenService:Create(avatarStroke, TweenInfo.new(0.2), {
            Color = Theme.Colors.BorderHover -- neutral-700
        }):Play()
    end))

    table.insert(self._connections, avatarButton.Activated:Connect(function()
        store:toggleProfileDropdown()
    end))

    ---------------------------------------------------------------------------
    -- Easter egg: 3 clicks within 2 seconds on version text
    ---------------------------------------------------------------------------
    local easterEggClickCount = 0
    local easterEggFirstClickTime = 0

    table.insert(self._connections, versionButton.Activated:Connect(function()
        local now = tick()
        if now - easterEggFirstClickTime > 2 then
            easterEggClickCount = 1
            easterEggFirstClickTime = now
        else
            easterEggClickCount = easterEggClickCount + 1
        end

        if easterEggClickCount >= 3 then
            easterEggClickCount = 0
            store:incrementEasterEggClick()
        end
    end))

    -- Version hover effect
    table.insert(self._connections, versionButton.MouseEnter:Connect(function()
        TweenService:Create(versionButton, TweenInfo.new(0.15), {
            TextColor3 = Theme.Colors.TextBody -- neutral-400
        }):Play()
    end))

    table.insert(self._connections, versionButton.MouseLeave:Connect(function()
        TweenService:Create(versionButton, TweenInfo.new(0.15), {
            TextColor3 = Theme.Colors.TextSubtle -- neutral-600
        }):Play()
    end))

    ---------------------------------------------------------------------------
    -- Underline positioning helper
    ---------------------------------------------------------------------------
    local function updateUnderlinePosition(targetKey)
        local btn = tabButtons[targetKey]
        if not btn then return end

        -- Get absolute position of the button relative to the nav frame
        local btnAbsPos = btn.AbsolutePosition
        local frameAbsPos = frame.AbsolutePosition
        local btnWidth = btn.AbsoluteSize.X

        -- Calculate underline position (left-2/right-2 inset -> 32px each side for 4K)
        local inset = 32 -- matches px-2 = 16px * 2
        local underLeft = btnAbsPos.X - frameAbsPos.X + inset
        local underWidth = btnWidth - inset * 2

        underlineBar.Size = UDim2.new(0, underWidth, 0, 4)
        underlineBar.Position = UDim2.new(0, underLeft + underWidth / 2, 1, -1)
    end

    local function updateActiveState(panelKey)
        self._activePanel = panelKey

        -- Update all tab text colors
        for _, item in ipairs(NAV_BUTTONS) do
            local label = tabLabels[item.key]
            if label then
                if item.key == panelKey then
                    -- Active: white text
                    label.TextColor3 = Theme.Colors.TextPrimary
                else
                    -- Inactive: neutral-500
                    label.TextColor3 = Theme.Colors.TextMuted
                end
            end

            -- Hide group dot when group tab is active
            if item.key == "group" then
                local dot = self["_groupDot_" .. item.key]
                if dot then
                    dot.Visible = (#store.groups == 0) and (panelKey ~= "group")
                end
            end
        end

        -- Animate underline to new position
        -- Use spring-like animation (Back easing)
        task.defer(function()
            updateUnderlinePosition(panelKey)
            -- Spring animation for the underline bar
            -- We approximate the spring with Back easing
            local tweenInfo = TweenInfo.new(
                0.4, -- duration
                Enum.EasingStyle.Back,
                Enum.EasingDirection.Out,
                0, false,
                0.2 -- overshoot
            )
            TweenService:Create(underlineBar, tweenInfo, {
                -- Position/size already set, just re-trigger for animation effect
            }):Play()
        end)
    end

    ---------------------------------------------------------------------------
    -- Store event listeners
    ---------------------------------------------------------------------------
    table.insert(self._connections, store:on("panelChanged", function(panelKey)
        updateActiveState(panelKey)
    end))

    table.insert(self._connections, store:on("keybindsChanged", function()
        local count = store:getKeybindCount()
        self:updateKeybindCount(count)
    end))

    table.insert(self._connections, store:on("groupsChanged", function()
        local hasGroups = #store.groups > 0
        self:updateGroupDot(not hasGroups)
    end))

    ---------------------------------------------------------------------------
    -- Slide-in animation from top
    ---------------------------------------------------------------------------
    local function slideIn()
        local targetPos = UDim2.new(0, 0, 0, 0)
        frame.Position = UDim2.new(0, 0, 0, -Theme.Spacing.NavBarHeight)

        local tweenInfo = TweenInfo.new(
            0.6, -- duration
            Enum.EasingStyle.Cubic,
            Enum.EasingDirection.Out,
            0, false,
            0.1 -- delay
        )
        local tween = TweenService:Create(frame, tweenInfo, { Position = targetPos })
        tween:Play()

        -- After slide in completes, position the underline
        tween.Completed:Connect(function()
            updateUnderlinePosition(self._activePanel)
        end)
    end

    ---------------------------------------------------------------------------
    -- Public methods
    ---------------------------------------------------------------------------

    function self.setActivePanel(name)
        store:setActivePanel(name)
    end

    function self.updateKeybindCount(count)
        local badge = self["_keybindBadge"]
        if badge then
            if count > 0 then
                badge.Visible = true
                local countLabel = badge:FindFirstChild("Count")
                if countLabel then
                    countLabel.Text = tostring(count)
                    -- Adjust badge width based on digit count
                    if count >= 10 then
                        badge.Size = UDim2.new(0, 40, 0, 28)
                    else
                        badge.Size = UDim2.new(0, 28, 0, 28)
                    end
                end
            else
                badge.Visible = false
            end
        end
    end

    function self.updateGroupDot(showDot)
        for _, item in ipairs(NAV_BUTTONS) do
            if item.key == "group" then
                local dot = self["_groupDot_" .. item.key]
                if dot then
                    dot.Visible = showDot and (self._activePanel ~= "group")
                end
            end
        end
    end

    function self.show()
        frame.Visible = true
        slideIn()
    end

    function self.hide()
        local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
        TweenService:Create(frame, tweenInfo, {
            Position = UDim2.new(0, 0, 0, -Theme.Spacing.NavBarHeight)
        }):Play()
    end

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

    -- Initial state setup
    updateActiveState(self._activePanel)
    self:updateKeybindCount(store:getKeybindCount())
    self:updateGroupDot(#store.groups == 0)

    -- Frame reference (read-only)
    self.frame = frame

    return self
end

return NavBar
