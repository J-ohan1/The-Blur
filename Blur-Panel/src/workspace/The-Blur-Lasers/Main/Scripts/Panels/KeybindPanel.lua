--[[
    KeybindPanel.lua — Keybind Management Panel
    The-Blur Roblox SurfaceGUI  |  4K (3840x2160)

    Category-based keybind management with:
    - 3 category buttons (Effects, Toggles, Positions) with count badges
    - Items list per category with record/re-record/remove
    - Recording state with pulsing dot, listens to UserInputService
    - Duplicate key detection with warning toast
    - Empty category state

    Usage:
        local KeybindPanel = require(script.Parent.KeybindPanel)
        local panel = KeybindPanel.new(parentFrame, store)
        panel:show()
        -- Later:
        panel:hide()
        panel:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local EffectPresets = require(script.Parent.Parent.EffectPresets)

--------------------------------------------------------------------------------
-- Category definitions
--------------------------------------------------------------------------------

local CATEGORY_META = {
    { key = "effects", label = "Effects" },
    { key = "toggles", label = "Toggles" },
    { key = "positions", label = "Positions" },
}

local TOGGLE_ITEMS = {
    { action = "toggle-master", label = "On / Off", category = "toggles" },
    { action = "toggle-fade", label = "Fade On / Off", category = "toggles" },
    { action = "toggle-hold", label = "Hold On / Off", category = "toggles" },
    { action = "toggle-hold-fade", label = "Hold Fade On / Off", category = "toggles" },
}

--------------------------------------------------------------------------------
-- Key formatting
--------------------------------------------------------------------------------

local MODIFIER_KEYS = {
    [Enum.KeyCode.LeftControl] = true,
    [Enum.KeyCode.RightControl] = true,
    [Enum.KeyCode.LeftAlt] = true,
    [Enum.KeyCode.RightAlt] = true,
    [Enum.KeyCode.LeftShift] = true,
    [Enum.KeyCode.RightShift] = true,
}

local MODIFIER_DISPLAY = {
    LeftControl = "Ctrl", RightControl = "Ctrl",
    LeftAlt = "Alt", RightAlt = "Alt",
    LeftShift = "Shift", RightShift = "Shift",
}

local KEY_DISPLAY_NAMES = {
    [Enum.KeyCode.Space] = "Space",
    [Enum.KeyCode.Return] = "Enter",
    [Enum.KeyCode.Tab] = "Tab",
    [Enum.KeyCode.Escape] = "Escape",
    [Enum.KeyCode.Backquote] = "`",
    [Enum.KeyCode.Minus] = "-",
    [Enum.KeyCode.Equals] = "=",
    [Enum.KeyCode.LeftBracket] = "[",
    [Enum.KeyCode.RightBracket] = "]",
    [Enum.KeyCode.Semicolon] = ";",
    [Enum.KeyCode.Quote] = "'",
    [Enum.KeyCode.Comma] = ",",
    [Enum.KeyCode.Period] = ".",
    [Enum.KeyCode.Slash] = "/",
    [Enum.KeyCode.BackSlash] = "\\",
    [Enum.KeyCode.CapsLock] = "CapsLock",
    [Enum.KeyCode.Delete] = "Delete",
    [Enum.KeyCode.Insert] = "Insert",
    [Enum.KeyCode.Home] = "Home",
    [Enum.KeyCode.End] = "End",
    [Enum.KeyCode.PageUp] = "PageUp",
    [Enum.KeyCode.PageDown] = "PageDown",
    [Enum.KeyCode.Print] = "Print",
    [Enum.KeyCode.ScrollLock] = "Scroll",
    [Enum.KeyCode.Pause] = "Pause",
    [Enum.KeyCode.NumLock] = "NumLock",
    [Enum.KeyCode.F1] = "F1", [Enum.KeyCode.F2] = "F2", [Enum.KeyCode.F3] = "F3",
    [Enum.KeyCode.F4] = "F4", [Enum.KeyCode.F5] = "F5", [Enum.KeyCode.F6] = "F6",
    [Enum.KeyCode.F7] = "F7", [Enum.KeyCode.F8] = "F8", [Enum.KeyCode.F9] = "F9",
    [Enum.KeyCode.F10] = "F10", [Enum.KeyCode.F11] = "F11", [Enum.KeyCode.F12] = "F12",
    [Enum.KeyCode.One] = "1", [Enum.KeyCode.Two] = "2", [Enum.KeyCode.Three] = "3",
    [Enum.KeyCode.Four] = "4", [Enum.KeyCode.Five] = "5", [Enum.KeyCode.Six] = "6",
    [Enum.KeyCode.Seven] = "7", [Enum.KeyCode.Eight] = "8", [Enum.KeyCode.Nine] = "9",
    [Enum.KeyCode.Zero] = "0",
    [Enum.KeyCode.Numpad0] = "Num0", [Enum.KeyCode.Numpad1] = "Num1",
    [Enum.KeyCode.Numpad2] = "Num2", [Enum.KeyCode.Numpad3] = "Num3",
    [Enum.KeyCode.Numpad4] = "Num4", [Enum.KeyCode.Numpad5] = "Num5",
    [Enum.KeyCode.Numpad6] = "Num6", [Enum.KeyCode.Numpad7] = "Num7",
    [Enum.KeyCode.Numpad8] = "Num8", [Enum.KeyCode.Numpad9] = "Num9",
}

local function formatKeyCode(keyCode)
    if KEY_DISPLAY_NAMES[keyCode] then
        return KEY_DISPLAY_NAMES[keyCode]
    end
    local name = keyCode.Name
    -- Single letter keys
    if #name == 1 then
        return name:upper()
    end
    -- Multi-char like "LeftControl" -> strip prefix
    return name
end

local function formatKeyDisplay(keyString)
    if not keyString or #keyString == 0 then return "" end
    return keyString
end

--------------------------------------------------------------------------------
-- KeybindPanel
--------------------------------------------------------------------------------

local KeybindPanel = {}
KeybindPanel.__index = KeybindPanel

function KeybindPanel.new(parent, store)
    local self = setmetatable({}, KeybindPanel)
    self.store = store
    self.connections = {}
    self.selectedCategory = nil
    self.recordingItem = nil -- { category, action, label }
    self.recordingDotTween = nil

    -- Theme shortcuts
    local T = Theme
    local C = T.Colors
    local F = T.Font
    local FS = T.FontSize
    local S = T.Spacing
    local R = T.CornerRadius
    local A = T.Animation
    local Z = T.ZIndex

    ----------------------------------------------------------------
    -- Root frame
    ----------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Name = "KeybindPanel"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = true
    frame.Visible = false
    frame.Parent = parent

    ----------------------------------------------------------------
    -- Outer padding
    ----------------------------------------------------------------
    local outer = Instance.new("Frame")
    outer.Name = "Outer"
    outer.Size = UDim2.new(1, 0, 1, 0)
    outer.BackgroundTransparency = 1
    outer.Parent = frame

    local outerPad = Instance.new("UIPadding")
    outerPad.PaddingTop = UDim.new(0, S.PanelTopOffset)
    outerPad.PaddingBottom = UDim.new(0, S.PanelPadding)
    outerPad.PaddingLeft = UDim.new(0, S.PanelPadding)
    outerPad.PaddingRight = UDim.new(0, S.PanelPadding)
    outerPad.Parent = outer

    local outerLayout = Instance.new("UIListLayout")
    outerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    outerLayout.Padding = UDim.new(0, S.GridGap)
    outerLayout.Parent = outer

    ----------------------------------------------------------------
    -- Header
    ----------------------------------------------------------------
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 0
    header.Parent = outer

    local headerTitle = Instance.new("TextLabel")
    headerTitle.Size = UDim2.new(1, 0, 0, 36)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Keybinds"
    headerTitle.TextColor3 = C.TextPrimary
    headerTitle.TextSize = FS.H3
    headerTitle.Font = F.FamilySemibold
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header

    local headerSubtitle = Instance.new("TextLabel")
    headerSubtitle.Size = UDim2.new(1, 0, 0, 28)
    headerSubtitle.Position = UDim2.new(0, 0, 0, 36)
    headerSubtitle.BackgroundTransparency = 1
    headerSubtitle.Text = "0 keybinds assigned"
    headerSubtitle.TextColor3 = C.TextSubtle
    headerSubtitle.TextSize = FS.Label
    headerSubtitle.Font = F.FamilyLight
    headerSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    headerSubtitle.Name = "Subtitle"
    headerSubtitle.Parent = header

    ----------------------------------------------------------------
    -- Category selection view
    ----------------------------------------------------------------
    local categoryView = Instance.new("Frame")
    categoryView.Name = "CategoryView"
    categoryView.Size = UDim2.new(1, 0, 1, -90)
    categoryView.BackgroundTransparency = 1
    categoryView.LayoutOrder = 1
    categoryView.Parent = outer

    -- Center icon
    local centerIcon = Instance.new("Frame")
    centerIcon.Size = UDim2.new(0, 100, 0, 100)
    centerIcon.Position = UDim2.new(0.5, -50, 0.3, 0)
    centerIcon.BackgroundColor3 = C.Surface
    centerIcon.BackgroundTransparency = 0.5
    centerIcon.BorderSizePixel = 0
    centerIcon.Parent = categoryView

    local centerIconCorner = Instance.new("UICorner")
    centerIconCorner.CornerRadius = UDim.new(0, R.XXL)
    centerIconCorner.Parent = centerIcon

    local centerIconStroke = Instance.new("UIStroke")
    centerIconStroke.Color = C.BorderDefault
    centerIconStroke.Transparency = 0.5
    centerIconStroke.Thickness = 1
    centerIconStroke.Parent = centerIcon

    local centerIconLabel = Instance.new("TextLabel")
    centerIconLabel.Size = UDim2.new(1, 0, 1, 0)
    centerIconLabel.BackgroundTransparency = 1
    centerIconLabel.Text = "K"
    centerIconLabel.TextColor3 = C.TextUltraSubtle
    centerIconLabel.TextSize = 44
    centerIconLabel.Font = F.FamilyBold
    centerIconLabel.Parent = centerIcon

    -- Center text
    local centerText = Instance.new("TextLabel")
    centerText.Size = UDim2.new(1, 0, 0, 32)
    centerText.Position = UDim2.new(0.5, 0, 0.3, 120)
    centerText.AnchorPoint = Vector2.new(0.5, 0)
    centerText.BackgroundTransparency = 1
    centerText.Text = "Select a category to manage keybinds"
    centerText.TextColor3 = C.TextMuted
    centerText.TextSize = FS.CardTitle
    centerText.Font = F.FamilyMedium
    centerText.Parent = categoryView

    local centerSubtext = Instance.new("TextLabel")
    centerSubtext.Size = UDim2.new(1, 0, 0, 24)
    centerSubtext.Position = UDim2.new(0.5, 0, 0.3, 152)
    centerSubtext.AnchorPoint = Vector2.new(0.5, 0)
    centerSubtext.BackgroundTransparency = 1
    centerSubtext.Text = "Effects, Toggles, or Positions"
    centerSubtext.TextColor3 = C.TextVerySubtle
    centerSubtext.TextSize = FS.Label
    centerSubtext.Font = F.FamilyLight
    centerSubtext.Parent = categoryView

    -- Category buttons row
    local catBtnRow = Instance.new("Frame")
    catBtnRow.Size = UDim2.new(1, 0, 0, 80)
    catBtnRow.Position = UDim2.new(0, 0, 0.3, 200)
    catBtnRow.BackgroundTransparency = 1
    catBtnRow.Parent = categoryView

    local catBtnLayout = Instance.new("UIListLayout")
    catBtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
    catBtnLayout.FillDirection = Enum.FillDirection.Horizontal
    catBtnLayout.Padding = UDim.new(0, S.LG)
    catBtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    catBtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    catBtnLayout.Parent = catBtnRow

    local catButtons = {}
    for i, catMeta in ipairs(CATEGORY_META) do
        local btn = Instance.new("TextButton")
        btn.Name = "CatBtn_" .. catMeta.key
        btn.Size = UDim2.new(0, 280, 0, 72)
        btn.BackgroundColor3 = C.Background
        btn.BackgroundTransparency = 0.8
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        btn.LayoutOrder = i
        btn.Parent = catBtnRow

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, R.LG)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = C.BorderDefault
        btnStroke.Transparency = 0
        btnStroke.Thickness = 1
        btnStroke.Parent = btn

        local btnLabel = Instance.new("TextLabel")
        btnLabel.Size = UDim2.new(1, 0, 0, 30)
        btnLabel.Position = UDim2.new(0, 0, 0.15, 0)
        btnLabel.BackgroundTransparency = 1
        btnLabel.Text = catMeta.label
        btnLabel.TextColor3 = C.TextSecondary
        btnLabel.TextSize = FS.Small
        btnLabel.Font = F.FamilyMedium
        btnLabel.Parent = btn

        local countBadge = Instance.new("TextLabel")
        countBadge.Name = "CountBadge"
        countBadge.Size = UDim2.new(0, 56, 0, 56)
        countBadge.Position = UDim2.new(0.5, -28, 0.75, 0)
        countBadge.AnchorPoint = Vector2.new(0, 0)
        countBadge.BackgroundColor3 = C.ButtonPrimary
        countBadge.BackgroundTransparency = 0
        countBadge.Text = "0"
        countBadge.TextColor3 = C.ButtonPrimaryText
        countBadge.TextSize = 36
        countBadge.Font = F.FamilyBold
        countBadge.BorderSizePixel = 0
        countBadge.Visible = false
        countBadge.Parent = btn

        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, R.Full)
        badgeCorner.Parent = countBadge

        catButtons[catMeta.key] = { btn = btn, label = btnLabel, stroke = btnStroke, countBadge = countBadge }

        -- Hover
        table.insert(self.connections, btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(A.HoverEnter), {
                BackgroundTransparency = 0.7,
            }):Play()
            TweenService:Create(btnStroke, TweenInfo.new(A.HoverEnter), {
                Color = C.BorderHover, Transparency = 0,
            }):Play()
        end))

        table.insert(self.connections, btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(A.HoverExit), {
                BackgroundTransparency = 0.8,
            }):Play()
            TweenService:Create(btnStroke, TweenInfo.new(A.HoverExit), {
                Color = C.BorderDefault, Transparency = 0,
            }):Play()
        end))

        -- Click
        table.insert(self.connections, btn.Activated:Connect(function()
            self:selectCategory(catMeta.key)
        end))
    end

    ----------------------------------------------------------------
    -- Items list view
    ----------------------------------------------------------------
    local itemsView = Instance.new("Frame")
    itemsView.Name = "ItemsView"
    itemsView.Size = UDim2.new(1, 0, 1, -90)
    itemsView.BackgroundTransparency = 1
    itemsView.Visible = false
    itemsView.ClipsDescendants = true
    itemsView.LayoutOrder = 1
    itemsView.Parent = outer

    local itemsLayout = Instance.new("UIListLayout")
    itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    itemsLayout.Padding = UDim.new(0, S.SM)
    itemsLayout.Parent = itemsView

    -- Back + category header
    local itemsHeader = Instance.new("Frame")
    itemsHeader.Size = UDim2.new(1, 0, 0, 48)
    itemsHeader.BackgroundTransparency = 1
    itemsHeader.LayoutOrder = 0
    itemsHeader.Parent = itemsView

    local itemsHeaderLayout = Instance.new("UIListLayout")
    itemsHeaderLayout.SortOrder = Enum.SortOrder.LayoutOrder
    itemsHeaderLayout.FillDirection = Enum.FillDirection.Horizontal
    itemsHeaderLayout.Padding = UDim.new(0, S.LG)
    itemsHeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    itemsHeaderLayout.Parent = itemsHeader

    local backBtn = Instance.new("TextButton")
    backBtn.Size = UDim2.new(0, 140, 0, 36)
    backBtn.BackgroundColor3 = C.Background
    backBtn.BackgroundTransparency = 1
    backBtn.Text = "< Back"
    backBtn.TextColor3 = C.TextMuted
    backBtn.TextSize = FS.Small
    backBtn.Font = F.FamilyLight
    backBtn.AutoButtonColor = false
    backBtn.BorderSizePixel = 0
    backBtn.LayoutOrder = 1
    backBtn.Parent = itemsHeader

    local catTitleLabel = Instance.new("TextLabel")
    catTitleLabel.Size = UDim2.new(0, 300, 0, 36)
    catTitleLabel.BackgroundTransparency = 1
    catTitleLabel.Text = ""
    catTitleLabel.TextColor3 = C.TextPrimary
    catTitleLabel.TextSize = FS.CardTitle
    catTitleLabel.Font = F.FamilySemibold
    catTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    catTitleLabel.LayoutOrder = 2
    catTitleLabel.Parent = itemsHeader

    local catCountLabel = Instance.new("TextLabel")
    catCountLabel.Size = UDim2.new(0, 200, 0, 36)
    catCountLabel.BackgroundTransparency = 1
    catCountLabel.Text = ""
    catCountLabel.TextColor3 = C.TextSubtle
    catCountLabel.TextSize = FS.Tiny
    catCountLabel.Font = F.FamilyLight
    catCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    catCountLabel.LayoutOrder = 3
    catCountLabel.Parent = itemsHeader

    -- Back hover
    table.insert(self.connections, backBtn.MouseEnter:Connect(function()
        backBtn.TextColor3 = C.TextPrimary
    end))
    table.insert(self.connections, backBtn.MouseLeave:Connect(function()
        backBtn.TextColor3 = C.TextMuted
    end))
    table.insert(self.connections, backBtn.Activated:Connect(function()
        self:goBack()
    end))

    -- Recording banner
    local recordingBanner = Instance.new("Frame")
    recordingBanner.Name = "RecordingBanner"
    recordingBanner.Size = UDim2.new(1, 0, 0, 0)
    recordingBanner.BackgroundColor3 = C.Surface
    recordingBanner.BackgroundTransparency = 0.7
    recordingBanner.BorderSizePixel = 0
    recordingBanner.ClipsDescendants = true
    recordingBanner.Visible = false
    recordingBanner.LayoutOrder = 1
    recordingBanner.Parent = itemsView

    local recBannerCorner = Instance.new("UICorner")
    recBannerCorner.CornerRadius = UDim.new(0, R.LG)
    recBannerCorner.Parent = recordingBanner

    local recBannerStroke = Instance.new("UIStroke")
    recBannerStroke.Color = C.BorderHover
    recBannerStroke.Transparency = 0
    recBannerStroke.Thickness = 1
    recBannerStroke.Parent = recordingBanner

    local recBannerPad = Instance.new("UIPadding")
    recBannerPad.PaddingLeft = UDim.new(0, S.XL)
    recBannerPad.PaddingRight = UDim.new(0, S.XL)
    recBannerPad.PaddingTop = UDim.new(0, S.SM)
    recBannerPad.PaddingBottom = UDim.new(0, S.SM)
    recBannerPad.Parent = recordingBanner

    -- Pulsing dot
    local recDot = Instance.new("Frame")
    recDot.Size = UDim2.new(0, 16, 0, 16)
    recDot.Position = UDim2.new(0, 0, 0.5, -8)
    recDot.BackgroundColor3 = C.TextPrimary
    recDot.BorderSizePixel = 0
    recDot.Parent = recordingBanner

    local recDotCorner = Instance.new("UICorner")
    recDotCorner.CornerRadius = UDim.new(0, R.Full)
    recDotCorner.Parent = recDot

    local recText = Instance.new("TextLabel")
    recText.Name = "RecText"
    recText.Size = UDim2.new(1, -260, 0, 28)
    recText.Position = UDim2.new(0, 32, 0.5, -14)
    recText.BackgroundTransparency = 1
    recText.Text = "Press a key..."
    recText.TextColor3 = C.TextSecondary
    recText.TextSize = FS.Small
    recText.Font = F.FamilyLight
    recText.TextXAlignment = Enum.TextXAlignment.Left
    recText.Parent = recordingBanner

    local recCancelBtn = Instance.new("TextButton")
    recCancelBtn.Size = UDim2.new(0, 140, 0, 36)
    recCancelBtn.Position = UDim2.new(1, -140, 0.5, -18)
    recCancelBtn.BackgroundColor3 = C.Background
    recCancelBtn.BackgroundTransparency = 1
    recCancelBtn.Text = "Cancel"
    recCancelBtn.TextColor3 = C.TextMuted
    recCancelBtn.TextSize = FS.Tiny
    recCancelBtn.Font = F.FamilyMedium
    recCancelBtn.AutoButtonColor = false
    recCancelBtn.BorderSizePixel = 0
    recCancelBtn.Parent = recordingBanner

    table.insert(self.connections, recCancelBtn.MouseEnter:Connect(function()
        recCancelBtn.TextColor3 = C.TextPrimary
    end))
    table.insert(self.connections, recCancelBtn.MouseLeave:Connect(function()
        recCancelBtn.TextColor3 = C.TextMuted
    end))
    table.insert(self.connections, recCancelBtn.Activated:Connect(function()
        self:stopRecording(true)
    end))

    -- Items scroll
    local itemsScroll = Instance.new("ScrollingFrame")
    itemsScroll.Name = "ItemsScroll"
    itemsScroll.Size = UDim2.new(1, 0, 1, -140)
    itemsScroll.BackgroundTransparency = 1
    itemsScroll.ScrollBarThickness = 0
    itemsScroll.ScrollBarImageTransparency = 1
    itemsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    itemsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemsScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    itemsScroll.LayoutOrder = 2
    itemsScroll.Parent = itemsView

    local itemsListLayout = Instance.new("UIListLayout")
    itemsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    itemsListLayout.Padding = UDim.new(0, S.SM)
    itemsListLayout.Parent = itemsScroll

    local itemsScrollPad = Instance.new("UIPadding")
    itemsScrollPad.PaddingTop = UDim.new(0, S.SM)
    itemsScrollPad.PaddingBottom = UDim.new(0, S.SM)
    itemsScrollPad.Parent = itemsScroll

    ----------------------------------------------------------------
    -- Internal references
    ----------------------------------------------------------------
    self.frame = frame
    self.categoryView = categoryView
    self.itemsView = itemsView
    self.catButtons = catButtons
    self.catTitleLabel = catTitleLabel
    self.catCountLabel = catCountLabel
    self.recordingBanner = recordingBanner
    self.recDot = recDot
    self.recText = recText
    self.itemsScroll = itemsScroll
    self.headerSubtitle = headerSubtitle

    ----------------------------------------------------------------
    -- Methods
    ----------------------------------------------------------------

    --- Get items for a category
    function self:getItemsForCategory(cat)
        if cat == "toggles" then
            return TOGGLE_ITEMS
        elseif cat == "effects" then
            local presets = EffectPresets.getAll()
            local items = {}
            for _, p in ipairs(presets) do
                table.insert(items, {
                    action = "effect-" .. p.id,
                    label = p.name,
                    category = "effects",
                })
            end
            return items
        elseif cat == "positions" then
            local positions = self.store:getPositions()
            local items = {}
            for _, pos in ipairs(positions) do
                table.insert(items, {
                    action = "position-" .. pos.id,
                    label = pos.name,
                    category = "positions",
                })
            end
            return items
        end
        return {}
    end

    --- Get keybind for an action
    function self:getKeybindForAction(action)
        for catName, catBinds in pairs(self.store.keybinds) do
            if catBinds[action] then
                return { category = catName, action = action, key = catBinds[action] }
            end
        end
        return nil
    end

    --- Get keybind count by category
    function self:getCountByCategory(cat)
        local count = 0
        if cat == "effects" then
            for action, _ in pairs(self.store.keybinds.effects or {}) do
                if action:find("^effect-") then count = count + 1 end
            end
        elseif cat == "toggles" then
            for action, _ in pairs(self.store.keybinds.toggles or {}) do
                if action:find("^toggle-") then count = count + 1 end
            end
        elseif cat == "positions" then
            for action, _ in pairs(self.store.keybinds.positions or {}) do
                if action:find("^position-") then count = count + 1 end
            end
        end
        return count
    end

    --- Update count badges
    function self:updateCounts()
        local total = 0
        for _, catMeta in ipairs(CATEGORY_META) do
            local count = self:getCountByCategory(catMeta.key)
            total = total + count
            local data = self.catButtons[catMeta.key]
            data.countBadge.Visible = count > 0
            data.countBadge.Text = tostring(count)
        end
        self.headerSubtitle.Text = total .. " keybind" .. (total ~= 1 and "s" or "") .. " assigned"
    end

    --- Select a category
    function self:selectCategory(cat)
        self.selectedCategory = cat
        self.recordingItem = nil
        self:stopRecording(false)

        local catMeta = CATEGORY_META[1]
        for _, m in ipairs(CATEGORY_META) do
            if m.key == cat then catMeta = m break end
        end

        categoryView.Visible = false
        itemsView.Visible = true

        catTitleLabel.Text = catMeta.label

        local items = self:getItemsForCategory(cat)
        catCountLabel.Text = #items .. " item" .. (#items ~= 1 and "s" or "")

        self:refreshItems()
    end

    --- Go back to category selection
    function self:goBack()
        self.selectedCategory = nil
        self.recordingItem = nil
        self:stopRecording(false)

        categoryView.Visible = true
        itemsView.Visible = false

        self:updateCounts()
    end

    --- Refresh items list
    function self:refreshItems()
        -- Clear existing items
        for _, child in ipairs(itemsScroll:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local cat = self.selectedCategory
        if not cat then return end

        local items = self:getItemsForCategory(cat)

        if #items == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, 0, 0, 200)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "No items available"
            emptyLabel.TextColor3 = C.TextSubtle
            emptyLabel.TextSize = FS.Small
            emptyLabel.Font = F.FamilyLight
            emptyLabel.Parent = itemsScroll

            if cat == "positions" then
                local hint = Instance.new("TextLabel")
                hint.Size = UDim2.new(1, 0, 0, 24)
                hint.Position = UDim2.new(0, 0, 0, 100)
                hint.BackgroundTransparency = 1
                hint.Text = "Create positions in the Control panel first"
                hint.TextColor3 = C.TextVerySubtle
                hint.TextSize = FS.Tiny
                hint.Font = F.FamilyLight
                hint.Parent = itemsScroll
            end
            return
        end

        for idx, item in ipairs(items) do
            self:createItemRow(itemsScroll, item, idx)
        end
    end

    --- Create a keybind item row
    function self:createItemRow(parent, item, idx)
        local keybind = self:getKeybindForAction(item.action)
        local hasKey = keybind ~= nil
        local isRecording = self.recordingItem and self.recordingItem.action == item.action

        local row = Instance.new("Frame")
        row.Name = "Row_" .. item.action
        row.Size = UDim2.new(1, 0, 0, 72)
        row.BackgroundColor3 = C.Surface
        row.BorderSizePixel = 0
        row.LayoutOrder = idx

        if isRecording then
            row.BackgroundColor3 = C.SurfaceActive
            row.BackgroundTransparency = 0.7
        else
            row.BackgroundTransparency = 0.7
        end

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, R.LG)
        rowCorner.Parent = row

        local rowStroke = Instance.new("UIStroke")
        rowStroke.Color = isRecording and C.BorderHover or C.BorderDefault
        rowStroke.Transparency = isRecording and 0 or 0.5
        rowStroke.Thickness = 1
        rowStroke.Parent = row

        local rowPad = Instance.new("UIPadding")
        rowPad.PaddingLeft = UDim.new(0, S.XL)
        rowPad.PaddingRight = UDim.new(0, S.XL)
        rowPad.Parent = row

        -- Left: label + category badge
        local leftContainer = Instance.new("Frame")
        leftContainer.Size = UDim2.new(0, 600, 1, 0)
        leftContainer.BackgroundTransparency = 1
        leftContainer.Parent = row

        local leftLayout = Instance.new("UIListLayout")
        leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        leftLayout.FillDirection = Enum.FillDirection.Horizontal
        leftLayout.Padding = UDim.new(0, S.SM)
        leftLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        leftLayout.Parent = leftContainer

        local itemLabel = Instance.new("TextLabel")
        itemLabel.Size = UDim2.new(1, -80, 0, 26)
        itemLabel.BackgroundTransparency = 1
        itemLabel.Text = item.label
        itemLabel.TextColor3 = C.TextSecondary
        itemLabel.TextSize = FS.Small
        itemLabel.TextTruncate = Enum.TextTruncate.AtEnd
        itemLabel.Font = F.FamilyMedium
        itemLabel.TextXAlignment = Enum.TextXAlignment.Left
        itemLabel.Parent = leftContainer

        local catBadge = Instance.new("TextLabel")
        catBadge.Size = UDim2.new(0, 70, 0, 24)
        catBadge.BackgroundColor3 = C.ButtonActive
        catBadge.BackgroundTransparency = 0.5
        catBadge.Text = item.category:sub(1, 3)
        catBadge.TextColor3 = C.TextSubtle
        catBadge.TextSize = 14
        catBadge.Font = F.FamilyMedium
        catBadge.BorderSizePixel = 0
        catBadge.Parent = leftContainer

        local catBadgeCorner = Instance.new("UICorner")
        catBadgeCorner.CornerRadius = UDim.new(0, R.SM)
        catBadgeCorner.Parent = catBadge

        -- Right side: key display + buttons
        local rightContainer = Instance.new("Frame")
        rightContainer.Size = UDim2.new(1, -620, 1, 0)
        rightContainer.BackgroundTransparency = 1
        rightContainer.Parent = row

        local rightLayout = Instance.new("UIListLayout")
        rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rightLayout.FillDirection = Enum.FillDirection.Horizontal
        rightLayout.Padding = UDim.new(0, S.SM)
        rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        rightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        rightLayout.Parent = rightContainer

        if hasKey then
            -- Key display badge
            local keyBadge = Instance.new("TextLabel")
            keyBadge.Size = UDim2.new(0, 120, 0, 40)
            keyBadge.BackgroundColor3 = C.ButtonActive
            keyBadge.BackgroundTransparency = 0.4
            keyBadge.Text = formatKeyDisplay(keybind.key)
            keyBadge.TextColor3 = C.TextSecondary
            keyBadge.TextSize = FS.Label
            keyBadge.Font = F.Mono
            keyBadge.BorderSizePixel = 0
            keyBadge.Parent = rightContainer

            local keyBadgeCorner = Instance.new("UICorner")
            keyBadgeCorner.CornerRadius = UDim.new(0, R.MD)
            keyBadgeCorner.Parent = keyBadge

            local keyBadgeStroke = Instance.new("UIStroke")
            keyBadgeStroke.Color = C.BorderHover
            keyBadgeStroke.Transparency = 0
            keyBadgeStroke.Thickness = 1
            keyBadgeStroke.Parent = keyBadge

            -- Re-record button
            local reRecordBtn = Instance.new("TextButton")
            reRecordBtn.Size = UDim2.new(0, 140, 0, 36)
            reRecordBtn.BackgroundColor3 = C.Background
            reRecordBtn.BackgroundTransparency = 1
            reRecordBtn.Text = "Re-record"
            reRecordBtn.TextColor3 = C.TextMuted
            reRecordBtn.TextSize = FS.Tiny
            reRecordBtn.Font = F.FamilyMedium
            reRecordBtn.AutoButtonColor = false
            reRecordBtn.BorderSizePixel = 0
            reRecordBtn.Parent = rightContainer

            local rrStroke = Instance.new("UIStroke")
            rrStroke.Color = C.BorderDefault
            rrStroke.Transparency = 0.6
            rrStroke.Thickness = 1
            rrStroke.Parent = reRecordBtn

            local rrCorner = Instance.new("UICorner")
            rrCorner.CornerRadius = UDim.new(0, R.MD)
            rrCorner.Parent = reRecordBtn

            -- Remove button
            local removeBtn = Instance.new("TextButton")
            removeBtn.Size = UDim2.new(0, 120, 0, 36)
            removeBtn.BackgroundColor3 = C.Background
            removeBtn.BackgroundTransparency = 1
            removeBtn.Text = "Remove"
            removeBtn.TextColor3 = C.TextSubtle
            removeBtn.TextSize = FS.Tiny
            removeBtn.Font = F.FamilyMedium
            removeBtn.AutoButtonColor = false
            removeBtn.BorderSizePixel = 0
            removeBtn.Parent = rightContainer

            -- Hover: re-record
            table.insert(self.connections, reRecordBtn.MouseEnter:Connect(function()
                TweenService:Create(reRecordBtn, TweenInfo.new(A.Fast), {
                    BackgroundTransparency = 0.8,
                }):Play()
                reRecordBtn.TextColor3 = C.TextSecondary
                rrStroke.Transparency = 0
                rrStroke.Color = C.BorderHover
            end))
            table.insert(self.connections, reRecordBtn.MouseLeave:Connect(function()
                TweenService:Create(reRecordBtn, TweenInfo.new(A.Fast), {
                    BackgroundTransparency = 1,
                }):Play()
                reRecordBtn.TextColor3 = C.TextMuted
                rrStroke.Transparency = 0.6
                rrStroke.Color = C.BorderDefault
            end))

            -- Hover: remove (red)
            table.insert(self.connections, removeBtn.MouseEnter:Connect(function()
                removeBtn.TextColor3 = Theme.Colors.ButtonDanger
            end))
            table.insert(self.connections, removeBtn.MouseLeave:Connect(function()
                removeBtn.TextColor3 = C.TextSubtle
            end))

            -- Click: re-record
            table.insert(self.connections, reRecordBtn.Activated:Connect(function()
                self:startRecording(item)
            end))

            -- Click: remove
            table.insert(self.connections, removeBtn.Activated:Connect(function()
                self.store:removeKeybind(item.category, item.action)
                self:refreshItems()
                self:updateCounts()
            end))
        elseif isRecording then
            -- Listening indicator
            local listeningLabel = Instance.new("TextLabel")
            listeningLabel.Size = UDim2.new(0, 200, 0, 36)
            listeningLabel.BackgroundTransparency = 1
            listeningLabel.Text = "Listening..."
            listeningLabel.TextColor3 = C.TextBody
            listeningLabel.TextSize = FS.Tiny
            listeningLabel.Font = F.FamilyLight
            listeningLabel.Parent = rightContainer

            -- Pulsing transparency
            spawn(function()
                while self.recordingItem and self.recordingItem.action == item.action do
                    for alpha = 0.4, 1, 0.1 do
                        if not self.recordingItem or self.recordingItem.action ~= item.action then break end
                        listeningLabel.TextTransparency = alpha
                        wait(0.12)
                    end
                end
            end)
        else
            -- No keybind: "Not set" + "Record" button
            local notSetLabel = Instance.new("TextLabel")
            notSetLabel.Size = UDim2.new(0, 160, 0, 36)
            notSetLabel.BackgroundTransparency = 1
            notSetLabel.Text = "Not set"
            notSetLabel.TextColor3 = C.TextVerySubtle
            notSetLabel.TextSize = FS.Small
            notSetLabel.Font = F.FamilyLight
            notSetLabel.Parent = rightContainer

            local recordBtn = Instance.new("TextButton")
            recordBtn.Size = UDim2.new(0, 140, 0, 40)
            recordBtn.BackgroundColor3 = C.Background
            recordBtn.BackgroundTransparency = 0.8
            recordBtn.Text = "Record"
            recordBtn.TextColor3 = C.TextMuted
            recordBtn.TextSize = FS.Tiny
            recordBtn.Font = F.FamilyMedium
            recordBtn.AutoButtonColor = false
            recordBtn.BorderSizePixel = 0
            recordBtn.Parent = rightContainer

            local recStroke = Instance.new("UIStroke")
            recStroke.Color = C.BorderDefault
            recStroke.Transparency = 0.6
            recStroke.Thickness = 1
            recStroke.Parent = recordBtn

            local recCorner = Instance.new("UICorner")
            recCorner.CornerRadius = UDim.new(0, R.MD)
            recCorner.Parent = recordBtn

            -- Hover
            table.insert(self.connections, recordBtn.MouseEnter:Connect(function()
                TweenService:Create(recordBtn, TweenInfo.new(A.Fast), {
                    BackgroundTransparency = 0.8,
                }):Play()
                recordBtn.TextColor3 = C.TextPrimary
                recStroke.Color = C.BorderHover
                recStroke.Transparency = 0
            end))
            table.insert(self.connections, recordBtn.MouseLeave:Connect(function()
                TweenService:Create(recordBtn, TweenInfo.new(A.Fast), {
                    BackgroundTransparency = 1,
                }):Play()
                recordBtn.TextColor3 = C.TextMuted
                recStroke.Color = C.BorderDefault
                recStroke.Transparency = 0.6
            end))

            -- Click
            table.insert(self.connections, recordBtn.Activated:Connect(function()
                self:startRecording(item)
            end))
        end

        -- Row hover
        table.insert(self.connections, row.MouseEnter:Connect(function()
            if not isRecording then
                TweenService:Create(rowStroke, TweenInfo.new(A.Fast), {
                    Color = C.BorderHover, Transparency = 0.4,
                }):Play()
            end
        end))
        table.insert(self.connections, row.MouseLeave:Connect(function()
            if not isRecording then
                TweenService:Create(rowStroke, TweenInfo.new(A.Fast), {
                    Color = C.BorderDefault, Transparency = 0.5,
                }):Play()
            end
        end))

        row.Parent = itemsScroll
    end

    --- Start recording a keybind
    function self:startRecording(item)
        self.recordingItem = { category = item.category, action = item.action, label = item.label }
        self.store:startRecordingKeybind(item.category, item.action)

        -- Show recording banner
        recordingBanner.Visible = true
        recordingBanner.Size = UDim2.new(1, 0, 0, 68)
        recText.Text = 'Press a key for "' .. item.label .. '"...'

        -- Start pulsing dot
        if self.recordingDotTween then self.recordingDotTween:Cancel() end
        self.recordingDotTween = TweenService:Create(recDot, TweenInfo.new(
            A.BlinkMedium, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
        ), { BackgroundTransparency = 0.7 })
        self.recordingDotTween:Play()

        self:refreshItems()
    end

    --- Stop recording
    function self:stopRecording(cleanup)
        if self.recordingDotTween then
            self.recordingDotTween:Cancel()
            self.recordingDotTween = nil
        end

        recDot.BackgroundTransparency = 0
        recordingBanner.Visible = false

        if cleanup and self.recordingItem then
            -- If the keybind has no key set, remove it
            local key = self.store:getKeybind(self.recordingItem.category, self.recordingItem.action)
            if not key then
                self.store:removeKeybind(self.recordingItem.category, self.recordingItem.action)
            end
        end

        self.recordingItem = nil
        self.store:cancelRecordingKeybind()

        if self.selectedCategory then
            self:refreshItems()
        end
    end

    ----------------------------------------------------------------
    -- Keyboard input listener
    ----------------------------------------------------------------
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not self.recordingItem then return end

        local keyCode = input.KeyCode
        if keyCode == Enum.KeyCode.Unknown then return end

        -- Ignore modifier-only presses
        if MODIFIER_KEYS[keyCode] then return end

        -- Build key string with modifiers
        local parts = {}
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            table.insert(parts, "Ctrl")
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then
            table.insert(parts, "Alt")
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
            table.insert(parts, "Shift")
        end

        local keyDisplay = formatKeyCode(keyCode)
        table.insert(parts, keyDisplay)
        local fullKey = table.concat(parts, "+")

        -- Check for duplicate
        for catName, catBinds in pairs(self.store.keybinds) do
            for bId, bKey in pairs(catBinds) do
                if bKey == fullKey and (catName ~= self.recordingItem.category or bId ~= self.recordingItem.action) then
                    -- Duplicate found - remove old binding
                    self.store:removeKeybind(catName, bId)
                    self.store:emit("toast", '"' .. fullKey .. '" unbound from previous action', "warning")
                end
            end
        end

        -- Assign keybind
        self.store:setKeybind(self.recordingItem.category, self.recordingItem.action, fullKey)
        self.store:emit("toast", "Keybind set: " .. fullKey, "success")
        self:stopRecording(false)
        self:updateCounts()
    end))

    ----------------------------------------------------------------
    -- Store listeners
    ----------------------------------------------------------------
    table.insert(self.connections, self.store:on("keybindsChanged", function()
        self:updateCounts()
        if self.selectedCategory then
            self:refreshItems()
        end
    end))

    ----------------------------------------------------------------
    -- Initialize
    ----------------------------------------------------------------
    self:updateCounts()

    return self
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function KeybindPanel:show()
    self.frame.Visible = true
    self:updateCounts()
    if self.selectedCategory then
        self:refreshItems()
    end
end

function KeybindPanel:hide()
    self:stopRecording(true)
    self.frame.Visible = false
end

function KeybindPanel:destroy()
    self:stopRecording(true)
    for _, conn in ipairs(self.connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self.connections = {}
    self.frame:Destroy()
end

return KeybindPanel
