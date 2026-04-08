--[[
    PlayerPanel.lua — Player Management Panel
    The-Blur Roblox SurfaceGUI  |  4K (3840×2160)

    Player list with search, role filtering, 2-column card grid,
    role-colored dots, and action buttons (Whitelist, Remove, Kick)
    with a full permission system.

    Usage:
        local PlayerPanel = require(script.Parent.PlayerPanel)
        local panel = PlayerPanel.new(parentFrame, store)
        panel:show()
        -- Later: panel:hide() or panel:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")

--------------------------------------------------------------------------------
-- Role helpers
--------------------------------------------------------------------------------

local ROLE_PRIORITY = {
    staff = 5,
    whitelisted = 4,
    temp_whitelisted = 3,
    normal = 2,
    blacklisted = 1,
}

local ROLE_LABELS = {
    staff = "Staff",
    whitelisted = "Whitelisted",
    temp_whitelisted = "Temp Whitelisted",
    normal = "Normal",
    blacklisted = "Blacklisted",
}

local ROLE_COLORS = {
    staff = Theme.Colors.RoleStaff,
    whitelisted = Theme.Colors.RoleWhitelisted,
    temp_whitelisted = Theme.Colors.RoleTempWhitelisted,
    normal = Theme.Colors.RoleNormal,
    blacklisted = Theme.Colors.RoleBlacklisted,
}

local ROLE_FILTERS = {
    { label = "All",           value = "all" },
    { label = "Staff",         value = "staff" },
    { label = "Whitelisted",   value = "whitelisted" },
    { label = "Temp WL",       value = "temp_whitelisted" },
    { label = "Normal",        value = "normal" },
    { label = "Blacklisted",   value = "blacklisted" },
}

local ROLE_DOT_COLORS = {
    staff = { dot = Theme.Colors.RoleStaff,         glow = true },
    whitelisted = { dot = Theme.Colors.RoleWhitelisted, glow = true },
    temp_whitelisted = { dot = Theme.Colors.RoleTempWhitelisted, glow = true },
    normal = { dot = Theme.Colors.RoleNormal,        glow = false },
    blacklisted = { dot = Theme.Colors.RoleBlacklisted, glow = true },
}

--- Which buttons are logically available for a given target role
local function getActiveButtons(targetRole)
    if targetRole == "staff" then
        return { whitelist = false, remove = false, kick = true }
    elseif targetRole == "whitelisted" then
        return { whitelist = true, remove = true, kick = true }
    elseif targetRole == "temp_whitelisted" then
        return { whitelist = false, remove = true, kick = true }
    elseif targetRole == "blacklisted" then
        return { whitelist = true, remove = false, kick = false }
    else -- normal
        return { whitelist = true, remove = true, kick = true }
    end
end

--- Check if a viewer role can perform an action on a target role
local function canPerform(viewerRole, targetRole, action)
    local viewerPrio = ROLE_PRIORITY[viewerRole] or 0
    local targetPrio = ROLE_PRIORITY[targetRole] or 0

    -- Blacklisted and Normal viewers can't do anything
    if viewerPrio <= 2 and viewerRole ~= "staff" then
        -- Normal (prio 2) and blacklisted (prio 1) viewers: no authority
        if viewerRole == "blacklisted" then return false end
        if viewerRole == "normal" then return false end
    end

    -- Temp WL viewers: limited
    if viewerRole == "temp_whitelisted" then
        if targetRole == "normal" or targetRole == "blacklisted" then
            return true
        end
        return false
    end

    -- HWL viewers: can act on temp_wl, normal, blacklisted
    if viewerRole == "whitelisted" then
        if targetRole == "staff" or targetRole == "whitelisted" then
            return false
        end
        return true
    end

    -- Staff viewers: can do everything except remove HWL or kick HWL/staff
    if viewerRole == "staff" then
        if action == "remove" and targetRole == "whitelisted" then
            return false
        end
        if action == "kick" and (targetRole == "whitelisted" or targetRole == "staff") then
            if targetRole == "staff" then
                -- Staff can kick other staff (special case from spec)
                return true
            end
            return false
        end
        if action == "whitelist" and (targetRole == "staff" or targetRole == "whitelisted") then
            return false
        end
        return true
    end

    return false
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function inTable(t, val)
    for _, v in ipairs(t) do
        if v == val then return true end
    end
    return false
end

--------------------------------------------------------------------------------
-- UI Helper: create a small button (mirrors GroupPanel helper)
--------------------------------------------------------------------------------

local function createSmallButton(parent, text, style, callback)
    style = style or "secondary"
    local btn = Instance.new("TextButton")
    btn.Name = "Btn_" .. text
    btn.Text = text
    btn.TextSize = Theme.FontSize.Label
    btn.Font = Theme.Font.FamilyMedium
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Theme.CornerRadius.MD)
    corner.Parent = btn

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 20)
    pad.PaddingRight = UDim.new(0, 20)
    pad.PaddingTop = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.Parent = btn

    if style == "primary" then
        btn.BackgroundColor3 = Theme.Colors.ButtonPrimary
        btn.TextColor3 = Theme.Colors.ButtonPrimaryText
    elseif style == "ghost" then
        btn.BackgroundTransparency = 1
        btn.TextColor3 = Theme.Colors.TextMuted
    elseif style == "active" then
        btn.BackgroundColor3 = Theme.Colors.ButtonActive
        btn.TextColor3 = Theme.Colors.TextPrimary
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Colors.BorderHover
        stroke.Thickness = 2
        stroke.Parent = btn
    elseif style == "danger" then
        btn.BackgroundColor3 = Color3.fromRGB(127, 29, 29)
        btn.BackgroundTransparency = 0.2
        btn.TextColor3 = Color3.fromRGB(252, 165, 165)
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(153, 27, 27)
        stroke.Thickness = 2
        stroke.Parent = btn
    elseif style == "warn" then
        btn.BackgroundColor3 = Color3.fromRGB(113, 63, 18)  -- yellow-900/30
        btn.BackgroundTransparency = 0.3
        btn.TextColor3 = Color3.fromRGB(253, 224, 71)     -- yellow-300
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(161, 98, 7)         -- yellow-700/60
        stroke.Thickness = 2
        stroke.Parent = btn
    else -- secondary
        btn.BackgroundColor3 = Theme.Colors.Surface
        btn.BackgroundTransparency = 0.5
        btn.TextColor3 = Theme.Colors.TextSecondary
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Colors.BorderDefault
        stroke.Thickness = 2
        stroke.Parent = btn
    end

    -- Store originals
    local origBg = btn.BackgroundColor3
    local origTrans = btn.BackgroundTransparency
    local origText = btn.TextColor3
    local defStroke = btn:FindFirstChildOfClass("UIStroke")

    btn.MouseEnter:Connect(function()
        if style == "primary" then
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundColor3 = Theme.Colors.ButtonPrimaryHover,
            }):Play()
        elseif style == "ghost" then
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundColor3 = Theme.Colors.SurfaceHover,
                BackgroundTransparency = 0.6,
                TextColor3 = Theme.Colors.TextPrimary,
            }):Play()
        elseif style == "danger" then
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundTransparency = 0.1,
            }):Play()
        elseif style == "warn" then
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundTransparency = 0.2,
            }):Play()
        else
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundColor3 = Theme.Colors.SurfaceHover,
                BackgroundTransparency = 0.3,
                TextColor3 = Theme.Colors.TextPrimary,
            }):Play()
            if defStroke then
                TweenService:Create(defStroke, TweenInfo.new(Theme.Animation.Fast), {
                    Color = Theme.Colors.BorderActive,
                }):Play()
            end
        end
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
            BackgroundColor3 = origBg,
            BackgroundTransparency = origTrans,
            TextColor3 = origText,
        }):Play()
        if defStroke then
            local resetColor = style == "danger" and Color3.fromRGB(153, 27, 27)
                or style == "warn" and Color3.fromRGB(161, 98, 7)
                or style == "active" and Theme.Colors.BorderHover
                or Theme.Colors.BorderDefault
            TweenService:Create(defStroke, TweenInfo.new(Theme.Animation.Fast), {
                Color = resetColor,
            }):Play()
        end
    end)

    if callback then
        btn.Activated:Connect(callback)
    end

    btn.Parent = parent
    return btn
end

--- Create an action button (flex-1 pill with variants)
local function createActionButton(parent, label, active, variant, callback)
    variant = variant or "default"
    local btn = Instance.new("TextButton")
    btn.Name = "Action_" .. label
    btn.Size = UDim2.new(1, 0, 0, 48)
    btn.Text = label
    btn.TextSize = Theme.FontSize.Label  -- 22 (11px web)
    btn.Font = Theme.Font.FamilyMedium
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Theme.CornerRadius.LG)
    corner.Parent = btn

    if not active then
        -- Disabled state
        btn.BackgroundColor3 = Theme.Colors.Surface
        btn.BackgroundTransparency = 0.8
        btn.TextColor3 = Theme.Colors.TextVerySubtle
        btn.BackgroundTransparency = 0.7

        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Colors.BorderDefault
        stroke.Thickness = 2
        stroke.Transparency = 0.6
        stroke.Parent = btn

        btn.Parent = parent
        return btn
    end

    if variant == "danger" then
        -- Active danger
        btn.BackgroundColor3 = Color3.fromRGB(127, 29, 29)  -- red-900/20
        btn.BackgroundTransparency = 0.2
        btn.TextColor3 = Color3.fromRGB(252, 165, 165)     -- red-300
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(153, 27, 27)         -- red-800/50
        stroke.Thickness = 2
        stroke.Parent = btn
    elseif variant == "warn" then
        -- Active warn (Temp WL)
        btn.BackgroundColor3 = Color3.fromRGB(113, 63, 18)  -- yellow-900/30
        btn.BackgroundTransparency = 0.3
        btn.TextColor3 = Color3.fromRGB(253, 224, 71)       -- yellow-300
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(161, 98, 7)           -- yellow-700/60
        stroke.Thickness = 2
        stroke.Parent = btn
    else
        -- Active default
        btn.BackgroundColor3 = Theme.Colors.Surface
        btn.BackgroundTransparency = 0.6
        btn.TextColor3 = Theme.Colors.TextSecondary
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Colors.BorderHover
        stroke.Thickness = 2
        stroke.Parent = btn
    end

    local origBg = btn.BackgroundColor3
    local origTrans = btn.BackgroundTransparency
    local origText = btn.TextColor3
    local stroke = btn:FindFirstChildOfClass("UIStroke")
    local origStrokeColor = stroke and stroke.Color

    btn.MouseEnter:Connect(function()
        if variant == "danger" then
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundTransparency = 0.1,
            }):Play()
        elseif variant == "warn" then
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundTransparency = 0.2,
            }):Play()
        else
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundColor3 = Theme.Colors.SurfaceActive,
                BackgroundTransparency = 0.5,
                TextColor3 = Theme.Colors.TextPrimary,
            }):Play()
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(Theme.Animation.Fast), {
                    Color = Theme.Colors.BorderActive,
                }):Play()
            end
        end
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
            BackgroundColor3 = origBg,
            BackgroundTransparency = origTrans,
            TextColor3 = origText,
        }):Play()
        if stroke then
            TweenService:Create(stroke, TweenInfo.new(Theme.Animation.Fast), {
                Color = origStrokeColor,
            }):Play()
        end
    end)

    if callback then
        btn.Activated:Connect(callback)
    end

    btn.Parent = parent
    return btn
end

--------------------------------------------------------------------------------
-- PlayerPanel Module
--------------------------------------------------------------------------------

local PlayerPanel = {}

function PlayerPanel.new(parent, store)
    local self = setmetatable({}, { __index = PlayerPanel })
    self.store = store
    self.connections = {}

    -- Filter state
    self.searchText = ""
    self.roleFilter = "all"

    ---------------------------------------------------------------------------
    -- Root Frame
    ---------------------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Name = "PlayerPanel"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Visible = false
    frame.Parent = parent
    self.frame = frame

    ---------------------------------------------------------------------------
    -- Main vertical layout
    ---------------------------------------------------------------------------
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Padding = UDim.new(0, Theme.Spacing.XL)
    mainLayout.Parent = frame

    local mainPad = Instance.new("UIPadding")
    mainPad.PaddingTop = UDim.new(0, Theme.Spacing.PanelTopOffset)
    mainPad.PaddingBottom = UDim.new(0, Theme.Spacing.XL)
    mainPad.PaddingLeft = UDim.new(0, Theme.Spacing.XL)
    mainPad.PaddingRight = UDim.new(0, Theme.Spacing.XL)
    mainPad.Parent = frame

    ---------------------------------------------------------------------------
    -- Search + Filter Bar
    ---------------------------------------------------------------------------
    local filterBar = Instance.new("Frame")
    filterBar.Name = "FilterBar"
    filterBar.Size = UDim2.new(1, 0, 0, 52)
    filterBar.BackgroundTransparency = 1
    filterBar.BorderSizePixel = 0
    filterBar.LayoutOrder = 0
    filterBar.Parent = frame

    local filterLayout = Instance.new("UIListLayout")
    filterLayout.SortOrder = Enum.SortOrder.LayoutOrder
    filterLayout.FillDirection = Enum.FillDirection.Horizontal
    filterLayout.Padding = UDim.new(0, 12)
    filterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    filterLayout.Parent = filterBar

    -- Search input
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchContainer"
    searchContainer.Size = UDim2.new(0, 800, 0, 52)
    searchContainer.BackgroundTransparency = 1
    searchContainer.Parent = filterBar

    local searchInput = Instance.new("TextBox")
    searchInput.Name = "SearchInput"
    searchInput.Size = UDim2.new(1, 0, 1, 0)
    searchInput.BackgroundColor3 = Theme.Colors.Surface
    searchInput.BackgroundTransparency = 0.4
    searchInput.BorderSizePixel = 0
    searchInput.Text = ""
    searchInput.PlaceholderText = "Search players..."
    searchInput.PlaceholderColor3 = Theme.Colors.TextSubtle
    searchInput.TextColor3 = Theme.Colors.InputText
    searchInput.TextSize = Theme.FontSize.Small  -- 24 (12px web)
    searchInput.Font = Theme.Font.FamilyMedium
    searchInput.TextXAlignment = Enum.TextXAlignment.Left
    searchInput.ClearTextOnFocus = false
    searchInput.Parent = searchContainer

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.LG)
    searchCorner.Parent = searchInput

    local searchStroke = Instance.new("UIStroke")
    searchStroke.Color = Theme.Colors.InputBorder
    searchStroke.Thickness = 2
    searchStroke.Parent = searchInput

    local searchPad = Instance.new("UIPadding")
    searchPad.PaddingLeft = UDim.new(0, 80)
    searchPad.PaddingRight = UDim.new(0, 32)
    searchPad.Parent = searchInput

    -- Search icon (magnifying glass using text)
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Name = "SearchIcon"
    searchIcon.Size = UDim2.new(0, 52, 1, 0)
    searchIcon.Position = UDim2.new(0, 20, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "⌕"
    searchIcon.TextColor3 = Theme.Colors.TextSubtle
    searchIcon.TextSize = 28
    searchIcon.Font = Theme.Font.FamilyBold
    searchIcon.TextXAlignment = Enum.TextXAlignment.Center
    searchIcon.ZIndex = 2
    searchIcon.Parent = searchContainer

    searchInput.FocusLost:Connect(function()
        searchStroke.Color = Theme.Colors.InputBorder
    end)
    searchInput.Focused:Connect(function()
        searchStroke.Color = Theme.Colors.InputBorderFocus
    end)

    table.insert(self.connections, searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        self.searchText = searchInput.Text
        self:renderPlayerGrid()
    end))
    self.searchInputRef = searchInput

    -- Role filter buttons
    local filterBtnsFrame = Instance.new("Frame")
    filterBtnsFrame.Name = "FilterButtons"
    filterBtnsFrame.Size = UDim2.new(1, -820, 0, 52)
    filterBtnsFrame.BackgroundTransparency = 1
    filterBtnsFrame.Parent = filterBar

    local filterBtnsLayout = Instance.new("UIListLayout")
    filterBtnsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    filterBtnsLayout.FillDirection = Enum.FillDirection.Horizontal
    filterBtnsLayout.Padding = UDim.new(0, 6)
    filterBtnsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    filterBtnsLayout.Parent = filterBtnsFrame

    self.filterButtons = {}

    for _, filter in ipairs(ROLE_FILTERS) do
        local isFilterActive = (self.roleFilter == filter.value)
        local fBtn = Instance.new("TextButton")
        fBtn.Name = "Filter_" .. filter.value
        fBtn.Size = UDim2.new(0, 0, 0, 44)
        fBtn.AutomaticSize = Enum.AutomaticSize.X
        fBtn.BackgroundColor3 = isFilterActive and Theme.Colors.ButtonActive or Color3.fromRGB(0, 0, 0)
        fBtn.BackgroundTransparency = isFilterActive and 0.5 or 1
        fBtn.Text = filter.label
        fBtn.TextColor3 = isFilterActive and Theme.Colors.TextPrimary or Theme.Colors.TextSubtle
        fBtn.TextSize = Theme.FontSize.Label
        fBtn.Font = Theme.Font.FamilyMedium
        fBtn.AutoButtonColor = false
        fBtn.BorderSizePixel = 0
        fBtn.Parent = filterBtnsFrame

        local fCorner = Instance.new("UICorner")
        fCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.MD)
        fCorner.Parent = fBtn

        local fPad = Instance.new("UIPadding")
        fPad.PaddingLeft = UDim.new(0, 20)
        fPad.PaddingRight = UDim.new(0, 20)
        fPad.Parent = fBtn

        if isFilterActive then
            local fStroke = Instance.new("UIStroke")
            fStroke.Color = Theme.Colors.BorderHover
            fStroke.Thickness = 2
            fStroke.Parent = fBtn
        end

        -- Role dot for non-"All" filters
        if filter.value ~= "all" then
            local dot = Instance.new("Frame")
            dot.Name = "RoleDot"
            dot.Size = UDim2.new(0, 16, 0, 16)
            dot.Position = UDim2.new(0, -4, 0.5, 0)
            dot.AnchorPoint = Vector2.new(0, 0.5)
            dot.BackgroundColor3 = ROLE_COLORS[filter.value] or Theme.Colors.TextSubtle
            dot.BorderSizePixel = 0
            dot.ZIndex = 2
            dot.Parent = fBtn

            local dotCorner = Instance.new("UICorner")
            dotCorner.CornerRadius = UDim.new(0, 9999)
            dotCorner.Parent = dot
        end

        local capturedFilter = filter.value
        table.insert(self.connections, fBtn.Activated:Connect(function()
            self.roleFilter = capturedFilter
            self:updateFilterButtons()
            self:renderPlayerGrid()
        end))

        self.filterButtons[filter.value] = fBtn
    end

    ---------------------------------------------------------------------------
    -- Player count label
    ---------------------------------------------------------------------------
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "PlayerCount"
    countLabel.Size = UDim2.new(1, 0, 0, 22)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = ""
    countLabel.TextColor3 = Theme.Colors.TextVerySubtle
    countLabel.TextSize = Theme.FontSize.Label
    countLabel.Font = Theme.Font.FamilyBold
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.LayoutOrder = 1
    countLabel.Parent = frame
    self.countLabel = countLabel

    ---------------------------------------------------------------------------
    -- Player Grid Container (scrollable)
    ---------------------------------------------------------------------------
    self.gridContainer = Instance.new("Frame")
    self.gridContainer.Name = "GridContainer"
    self.gridContainer.Size = UDim2.new(1, 0, 1, -190)
    self.gridContainer.BackgroundTransparency = 1
    self.gridContainer.BorderSizePixel = 0
    self.gridContainer.ClipsDescendants = true
    self.gridContainer.LayoutOrder = 2
    self.gridContainer.Parent = frame

    ---------------------------------------------------------------------------
    -- Store listeners
    ---------------------------------------------------------------------------
    table.insert(self.connections, store:on("playersChanged", function()
        self:renderPlayerGrid()
    end))

    ---------------------------------------------------------------------------
    -- Public API
    ---------------------------------------------------------------------------
    function self:show()
        frame.Visible = true
        self:renderPlayerGrid()
        self:updateFilterButtons()
    end

    function self:hide()
        frame.Visible = false
    end

    function self:destroy()
        for _, conn in ipairs(self.connections) do
            if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
        end
        self.connections = {}
        frame:Destroy()
    end

    return self
end

--------------------------------------------------------------------------------
-- Update filter button styles
--------------------------------------------------------------------------------
function PlayerPanel:updateFilterButtons()
    for _, filter in ipairs(ROLE_FILTERS) do
        local fBtn = self.filterButtons[filter.value]
        if not fBtn then continue end

        local isActive = (self.roleFilter == filter.value)

        fBtn.BackgroundColor3 = isActive and Theme.Colors.ButtonActive or Color3.fromRGB(0, 0, 0)
        fBtn.BackgroundTransparency = isActive and 0.5 or 1
        fBtn.TextColor3 = isActive and Theme.Colors.TextPrimary or Theme.Colors.TextSubtle

        -- Update stroke
        local existingStroke = fBtn:FindFirstChildOfClass("UIStroke")
        if isActive then
            if not existingStroke then
                local fStroke = Instance.new("UIStroke")
                fStroke.Color = Theme.Colors.BorderHover
                fStroke.Thickness = 2
                fStroke.Parent = fBtn
            end
        else
            if existingStroke then
                existingStroke:Destroy()
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Filter players
--------------------------------------------------------------------------------
function PlayerPanel:getFilteredPlayers()
    local currentUser = self.store:getCurrentUser()
    local allPlayers = self.store:getPlayers() or {}
    local result = {}

    -- Exclude current user
    for _, player in ipairs(allPlayers) do
        if player.id ~= currentUser.id then
            table.insert(result, player)
        end
    end

    -- Role filter
    if self.roleFilter ~= "all" then
        local filtered = {}
        for _, player in ipairs(result) do
            if player.role == self.roleFilter then
                table.insert(filtered, player)
            end
        end
        result = filtered
    end

    -- Search filter
    if self.searchText and #self.searchText > 0 then
        local q = self.searchText:lower()
        local filtered = {}
        for _, player in ipairs(result) do
            if player.name:lower():find(q, 1, true) then
                table.insert(filtered, player)
            end
        end
        result = filtered
    end

    return result
end

--------------------------------------------------------------------------------
-- Render: Player Grid
--------------------------------------------------------------------------------
function PlayerPanel:renderPlayerGrid()
    if not self.frame or not self.frame.Parent then return end

    -- Clear existing content
    for _, child in ipairs(self.gridContainer:GetChildren()) do
        if child:IsA("Frame") or child:IsA("ScrollingFrame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local filteredPlayers = self:getFilteredPlayers()

    -- Update count label
    local countText = #filteredPlayers .. " Player" .. (#filteredPlayers ~= 1 and "s" or "") .. " found"
    if self.countLabel then
        self.countLabel.Text = countText:upper()
    end

    if #filteredPlayers == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Name = "EmptyState"
        emptyLabel.Size = UDim2.new(1, 0, 1, 0)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = "No players found"
        emptyLabel.TextColor3 = Theme.Colors.TextMuted
        emptyLabel.TextSize = Theme.FontSize.Small
        emptyLabel.Font = Theme.Font.FamilyMedium
        emptyLabel.Parent = self.gridContainer
        return
    end

    -- Scrollable frame for the grid
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "PlayerGrid"
    scroll.Size = UDim2.new(1, -12, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 0
    scroll.ScrollBarImageTransparency = 1
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ElasticBehavior = Enum.ElasticBehavior.Never
    scroll.ScrollBarBehavior = Enum.ScrollBarBehavior.Never
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = self.gridContainer

    -- Grid content (2-column grid using UIGridLayout)
    local gridContent = Instance.new("Frame")
    gridContent.Name = "GridContent"
    gridContent.Size = UDim2.new(1, -20, 0, 0)
    gridContent.AutomaticSize = Enum.AutomaticSize.Y
    gridContent.BackgroundTransparency = 1
    gridContent.Parent = scroll

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.CellSize = UDim2.new(0.5, -12, 0, 0) -- 2 columns
    gridLayout.CellPadding = UDim2.new(0, 12, 0, 12)
    gridLayout.Parent = gridContent

    local currentUser = self.store:getCurrentUser()

    for i, player in ipairs(filteredPlayers) do
        self:createPlayerCard(gridContent, player, currentUser.role, i)
    end
end

--------------------------------------------------------------------------------
-- Create: Player Card
--------------------------------------------------------------------------------
function PlayerPanel:createPlayerCard(parent, player, viewerRole, index)
    local card = Instance.new("Frame")
    card.Name = "PlayerCard_" .. (player.name or "")
    card.BackgroundColor3 = Theme.Colors.Background
    card.BackgroundTransparency = 0.5
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.ClipsDescendants = true
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.XL)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Theme.Colors.BorderDefault
    cardStroke.Thickness = 2
    cardStroke.Transparency = 0.4
    cardStroke.Parent = card

    -- Card layout
    local cardLayout = Instance.new("UIListLayout")
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardLayout.Padding = UDim.new(0, 0)
    cardLayout.Parent = card

    -- Top row: Avatar + Name + Role dot
    local topRow = Instance.new("Frame")
    topRow.Name = "TopRow"
    topRow.Size = UDim2.new(1, 0, 0, 112) -- Auto-sized by content
    topRow.BackgroundTransparency = 1
    topRow.LayoutOrder = 0
    topRow.Parent = card

    local topPad = Instance.new("UIPadding")
    topPad.PaddingTop = UDim.new(0, ROW_PADDING or 24)
    topPad.PaddingBottom = UDim.new(0, 12)
    topPad.PaddingLeft = UDim.new(0, ROW_PADDING or 24)
    topPad.PaddingRight = UDim.new(0, ROW_PADDING or 24)
    topPad.Parent = topRow

    local topLayout = Instance.new("UIListLayout")
    topLayout.SortOrder = Enum.SortOrder.LayoutOrder
    topLayout.FillDirection = Enum.FillDirection.Horizontal
    topLayout.Padding = UDim.new(0, 24)
    topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    topLayout.Parent = topRow

    -- Avatar circle
    local avatar = Instance.new("Frame")
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, 80, 0, 80) -- 40px web * 2
    avatar.BackgroundColor3 = Theme.Colors.SurfaceActive
    avatar.BackgroundTransparency = 0.3
    avatar.BorderSizePixel = 0
    avatar.Parent = topRow

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 9999)
    avatarCorner.Parent = avatar

    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = Theme.Colors.BorderDefault
    avatarStroke.Thickness = 2
    avatarStroke.Transparency = 0.5
    avatarStroke.Parent = avatar

    local initial = player.name and player.name:sub(1, 1):upper() or "?"
    local avatarText = Instance.new("TextLabel")
    avatarText.Size = UDim2.new(1, 0, 1, 0)
    avatarText.BackgroundTransparency = 1
    avatarText.Text = initial
    avatarText.TextColor3 = Theme.Colors.TextBody
    avatarText.TextSize = 32
    avatarText.Font = Theme.Font.FamilyBold
    avatarText.Parent = avatar

    -- Name + Role info column
    local infoCol = Instance.new("Frame")
    infoCol.Name = "Info"
    infoCol.Size = UDim2.new(1, -104, 1, 0)
    infoCol.BackgroundTransparency = 1
    infoCol.Parent = topRow

    local infoLayout = Instance.new("UIListLayout")
    infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
    infoLayout.Padding = UDim.new(0, 4)
    infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    infoLayout.Parent = infoCol

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 26)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.name or "Unknown"
    nameLabel.TextColor3 = Theme.Colors.TextPrimary
    nameLabel.TextSize = Theme.FontSize.CardTitle
    nameLabel.Font = Theme.Font.FamilyMedium
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.LayoutOrder = 0
    nameLabel.Parent = infoCol

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Size = UDim2.new(1, 0, 0, 22)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = ROLE_LABELS[player.role] or "Unknown"
    roleLabel.TextColor3 = Theme.Colors.TextSubtle
    roleLabel.TextSize = Theme.FontSize.Label
    roleLabel.Font = Theme.Font.FamilyMedium
    roleLabel.TextXAlignment = Enum.TextXAlignment.Left
    roleLabel.LayoutOrder = 1
    roleLabel.Parent = infoCol

    -- Role dot (top-right of avatar)
    local roleDotInfo = ROLE_DOT_COLORS[player.role] or { dot = Theme.Colors.TextSubtle, glow = false }
    local roleDot = Instance.new("Frame")
    roleDot.Name = "RoleDot"
    roleDot.Size = UDim2.new(0, 16, 0, 16) -- 8px web * 2 (spec says 16px)
    roleDot.Position = UDim2.new(0, 64, 0, 8) -- top-right of avatar area
    roleDot.AnchorPoint = Vector2.new(1, 0)
    roleDot.BackgroundColor3 = roleDotInfo.dot
    roleDot.BorderSizePixel = 0
    roleDot.ZIndex = 10
    roleDot.Parent = card

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(0, 9999)
    dotCorner.Parent = roleDot

    -- Glow effect for certain roles
    if roleDotInfo.glow then
        local glow = Instance.new("ImageLabel")
        glow.Name = "Glow"
        glow.Size = UDim2.new(1, 24, 1, 24)
        glow.Position = UDim2.new(0, -12, 0, -12)
        glow.BackgroundTransparency = 1
        glow.ImageTransparency = 0.6
        glow.ImageColor3 = roleDotInfo.dot
        glow.ScaleType = Enum.ScaleType.Slice
        glow.SliceCenter = Rect.new(49, 49, 450, 450)
        glow.ZIndex = 9
        glow.Parent = roleDot
    end

    -- Action Buttons row
    local actionsRow = Instance.new("Frame")
    actionsRow.Name = "Actions"
    actionsRow.Size = UDim2.new(1, 0, 0, 48)
    actionsRow.BackgroundTransparency = 1
    actionsRow.LayoutOrder = 1
    actionsRow.Parent = card

    local actionsPad = Instance.new("UIPadding")
    actionsPad.PaddingLeft = UDim.new(0, ROW_PADDING or 24)
    actionsPad.PaddingRight = UDim.new(0, ROW_PADDING or 24)
    actionsPad.PaddingBottom = UDim.new(0, ROW_PADDING or 24)
    actionsPad.Parent = actionsRow

    local actionsLayout = Instance.new("UIListLayout")
    actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    actionsLayout.FillDirection = Enum.FillDirection.Horizontal
    actionsLayout.Padding = UDim.new(0, 12)
    actionsLayout.Parent = actionsRow

    -- Determine button visibility and state
    local activeButtons = getActiveButtons(player.role)

    local wlAllowed = activeButtons.whitelist and canPerform(viewerRole, player.role, "whitelist")
    local rmAllowed = activeButtons.remove and canPerform(viewerRole, player.role, "remove")
    local kickAllowed = activeButtons.kick and canPerform(viewerRole, player.role, "kick")

    -- Whitelist / Temp WL button
    if activeButtons.whitelist then
        local wlLabel = player.role == "blacklisted" and "Temp WL" or "Whitelist"
        local wlVariant = player.role == "blacklisted" and "warn" or "default"
        local wlBtn = createActionButton(actionsRow, wlLabel, wlAllowed, wlVariant, function()
            self:whitelistPlayer(player)
        end)
    end

    -- Remove button
    if activeButtons.remove then
        local rmBtn = createActionButton(actionsRow, "Remove", rmAllowed, "default", function()
            self:removePlayer(player)
        end)
    end

    -- Kick button
    if activeButtons.kick then
        local kickBtn = createActionButton(actionsRow, "Kick", kickAllowed, "danger", function()
            self:kickPlayer(player)
        end)
    end

    -- Hover effect on card
    table.insert(self.connections, card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(Theme.Animation.HoverEnter), {
            BackgroundTransparency = 0.4,
        }):Play()
        TweenService:Create(cardStroke, TweenInfo.new(Theme.Animation.HoverEnter), {
            Transparency = 0.1,
        }):Play()
    end))

    table.insert(self.connections, card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(Theme.Animation.HoverExit), {
            BackgroundTransparency = 0.5,
        }):Play()
        TweenService:Create(cardStroke, TweenInfo.new(Theme.Animation.HoverExit), {
            Transparency = 0.4,
        }):Play()
    end))

    -- Re-parent role dot to be properly positioned relative to the card
    roleDot.Parent = card
    -- Position: top-right area of card
    roleDot.Position = UDim2.new(1, -40, 0, 28)
    roleDot.AnchorPoint = Vector2.new(0, 0)
end

--------------------------------------------------------------------------------
-- Actions
--------------------------------------------------------------------------------

function PlayerPanel:whitelistPlayer(player)
    local newRole = "whitelisted"
    if player.role == "blacklisted" then
        newRole = "temp_whitelisted"
    end

    for _, p in ipairs(self.store.players or {}) do
        if p.id == player.id then
            p.role = newRole
            break
        end
    end
    self.store:emit("playersChanged", self.store.players)
end

function PlayerPanel:removePlayer(player)
    for _, p in ipairs(self.store.players or {}) do
        if p.id == player.id then
            p.role = "normal"
            break
        end
    end
    self.store:emit("playersChanged", self.store.players)
end

function PlayerPanel:kickPlayer(player)
    -- In a real implementation, this would kick the player from the game
    -- For the UI, we simulate by removing them from the player list temporarily
    -- or just show a toast notification
    for i, p in ipairs(self.store.players or {}) do
        if p.id == player.id then
            table.remove(self.store.players, i)
            break
        end
    end
    self.store:emit("playersChanged", self.store.players)
end

return PlayerPanel
