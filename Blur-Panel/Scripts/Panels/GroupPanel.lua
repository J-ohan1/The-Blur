--[[
    GroupPanel.lua — Group Management Panel
    The-Blur Roblox SurfaceGUI  |  4K (3840×2160)

    Full group management: create/edit/delete laser fixture groups,
    fixture mode (24 fixtures, 8-col grid) and individual mode
    (24 expandable rows × 15 beams each).

    Usage:
        local GroupPanel = require(script.Parent.GroupPanel)
        local panel = GroupPanel.new(parentFrame, store)
        panel:show()
        -- Later: panel:hide() or panel:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
local FIXTURE_COUNT = 24
local BEAMS_PER_FIXTURE = 15
local FIXTURE_GRID_COLS = 8

-- 4K-scaled dimensions (web px × 2)
local FIXTURE_CELL_SIZE = UDim2.new(0, 160, 0, 80)   -- 80×40 web → 160×80 4K
local BEAM_CELL_SIZE = UDim2.new(0, 112, 0, 60)       -- 56×30 web → 112×60 4K
local CHECKBOX_SIZE = UDim2.new(0, 40, 0, 40)          -- 20×20 web → 40×40 4K
local ROW_PADDING = 32                                  -- 16px web × 2
local INPUT_WIDTH = UDim2.new(0, 800, 0, 96)           -- 400×48 web
local INPUT_PADDING = 32                                -- 16px web × 2

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function inTable(t, val)
    for _, v in ipairs(t) do
        if v == val then return true end
    end
    return false
end

local function removeFromTable(t, val)
    for i, v in ipairs(t) do
        if v == val then
            table.remove(t, i)
            return true
        end
    end
    return false
end

local function countTable(t)
    local n = 0
    for _ in ipairs(t) do n = n + 1 end
    return n
end

--- Create a simple TextButton styled as a pill / small button
local function createSmallButton(parent, text, style, callback)
    -- style: "secondary" | "ghost" | "active" | "danger" | "primary"
    style = style or "secondary"
    local btn = Instance.new("TextButton")
    btn.Name = "Btn_" .. text
    btn.Text = text
    btn.TextSize = Theme.FontSize.Label  -- 22 (11px web)
    btn.Font = Theme.Font.FamilyMedium
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Theme.CornerRadius.LG) -- 16 (8px web)
    corner.Parent = btn

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 24)
    pad.PaddingRight = UDim.new(0, 24)
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
        btn.BackgroundColor3 = Color3.fromRGB(127, 29, 29)  -- red-900/80
        btn.BackgroundTransparency = 0.2
        btn.TextColor3 = Color3.fromRGB(252, 165, 165)     -- red-300
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(153, 27, 27)         -- red-800/50
        stroke.Thickness = 2
        stroke.Parent = btn
    else -- secondary (default)
        btn.BackgroundColor3 = Theme.Colors.Surface
        btn.BackgroundTransparency = 0.5
        btn.TextColor3 = Theme.Colors.TextSecondary
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Colors.BorderDefault
        stroke.Thickness = 2
        stroke.Parent = btn
    end

    -- Hover / press tweens
    local origBg = btn.BackgroundColor3
    local origText = btn.TextColor3
    local defaultStroke = btn:FindFirstChildOfClass("UIStroke")

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
        else
            TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
                BackgroundColor3 = Theme.Colors.SurfaceHover,
                BackgroundTransparency = 0.3,
                TextColor3 = Theme.Colors.TextPrimary,
            }):Play()
            if defaultStroke then
                TweenService:Create(defaultStroke, TweenInfo.new(Theme.Animation.Fast), {
                    Color = Theme.Colors.BorderActive,
                }):Play()
            end
        end
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
            BackgroundColor3 = origBg,
            TextColor3 = origText,
        }):Play()
        if style == "ghost" then
            btn.BackgroundTransparency = 1
        elseif style == "danger" then
            btn.BackgroundTransparency = 0.2
        else
            btn.BackgroundTransparency = 0.5
        end
        if defaultStroke then
            TweenService:Create(defaultStroke, TweenInfo.new(Theme.Animation.Fast), {
                Color = style == "danger" and Color3.fromRGB(153, 27, 27)
                    or style == "active" and Theme.Colors.BorderHover
                    or Theme.Colors.BorderDefault,
            }):Play()
        end
    end)

    if callback then
        btn.Activated:Connect(callback)
    end

    btn.Parent = parent
    return btn
end

--- Create the context menu overlay
local function showContextMenu(parentFrame, position, items, onClose)
    -- position: Vector2 in GUI space
    local connections = {}

    -- Backdrop
    local backdrop = Instance.new("TextButton")
    backdrop.Name = "CtxBackdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.Text = ""
    backdrop.AutoButtonColor = false
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 200
    backdrop.Parent = parentFrame

    -- Menu container
    local menu = Instance.new("Frame")
    menu.Name = "ContextMenu"
    menu.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
    menu.BackgroundTransparency = 0.05
    menu.BorderSizePixel = 0
    menu.ClipsDescendants = true
    menu.ZIndex = 201

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.LG)
    menuCorner.Parent = menu

    local menuStroke = Instance.new("UIStroke")
    menuStroke.Color = Theme.Colors.BorderDefault
    menuStroke.Thickness = 2
    menuStroke.Parent = menu

    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.ImageTransparency = 0.5
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.ZIndex = 200
    shadow.Parent = menu

    -- Layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = menu

    local menuPad = Instance.new("UIPadding")
    menuPad.PaddingTop = UDim.new(0, 8)
    menuPad.PaddingBottom = UDim.new(0, 8)
    menuPad.Parent = menu

    local itemHeight = 52  -- 26px web * 2
    local totalHeight = 16

    for i, item in ipairs(items) do
        local itemBtn = Instance.new("TextButton")
        itemBtn.Name = "CtxItem_" .. (item.text or "")
        itemBtn.Size = UDim2.new(1, 0, 0, itemHeight)
        itemBtn.BackgroundTransparency = 1
        itemBtn.Text = ""
        itemBtn.AutoButtonColor = false
        itemBtn.BorderSizePixel = 0
        itemBtn.LayoutOrder = i
        itemBtn.ZIndex = 202
        itemBtn.Parent = menu

        local itemPad = Instance.new("UIPadding")
        itemPad.PaddingLeft = UDim.new(0, 24)
        itemPad.PaddingRight = UDim.new(0, 24)
        itemPad.Parent = itemBtn

        local itemText = Instance.new("TextLabel")
        itemText.Size = UDim2.new(1, 0, 1, 0)
        itemText.BackgroundTransparency = 1
        itemText.Text = item.text or ""
        itemText.TextColor3 = item.danger and Theme.Colors.TextBody or Theme.Colors.TextSecondary
        itemText.TextSize = Theme.FontSize.CardTitle  -- 26 (13px web)
        itemText.Font = Theme.Font.FamilyMedium
        itemText.TextXAlignment = Enum.TextXAlignment.Left
        itemText.ZIndex = 203
        itemText.Parent = itemBtn

        -- Width estimation
        local estWidth = Theme.FontSize.CardTitle * (#tostring(item.text or "") * 0.55 + 1) + 48 + 16
        totalHeight = totalHeight + itemHeight

        if not item.disabled then
            local itemCorner = Instance.new("UICorner")
            itemCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.MD)
            itemCorner.Parent = itemBtn

            table.insert(connections, itemBtn.MouseEnter:Connect(function()
                TweenService:Create(itemBtn, TweenInfo.new(Theme.Animation.Fast), {
                    BackgroundTransparency = 0.7,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                }):Play()
                TweenService:Create(itemText, TweenInfo.new(Theme.Animation.Fast), {
                    TextColor3 = Theme.Colors.TextPrimary,
                }):Play()
            end))

            table.insert(connections, itemBtn.MouseLeave:Connect(function()
                TweenService:Create(itemBtn, TweenInfo.new(Theme.Animation.Fast), {
                    BackgroundTransparency = 1,
                }):Play()
                TweenService:Create(itemText, TweenInfo.new(Theme.Animation.Fast), {
                    TextColor3 = item.danger and Theme.Colors.TextBody or Theme.Colors.TextSecondary,
                }):Play()
            end))

            table.insert(connections, itemBtn.Activated:Connect(function()
                closeMenu()
                if item.callback then item.callback() end
            end))
        else
            itemText.TextTransparency = 0.5
        end
    end

    totalHeight = totalHeight + 8
    local menuWidth = 320 -- 160px web * 2

    -- Viewport-aware positioning
    local gui = parentFrame
    local vpSize = gui.AbsoluteSize
    local x = position.X
    local y = position.Y
    if x + menuWidth > vpSize.X then x = vpSize.X - menuWidth - 16 end
    if y + totalHeight > vpSize.Y then y = vpSize.Y - totalHeight - 16 end
    x = math.max(8, x)
    y = math.max(8, y)

    menu.Size = UDim2.new(0, menuWidth, 0, totalHeight)
    menu.Position = UDim2.new(0, x, 0, y)

    function closeMenu()
        for _, conn in ipairs(connections) do
            if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
        end
        connections = {}
        local tween = TweenService:Create(menu, TweenInfo.new(Theme.Animation.Fast, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        })
        tween:Play()
        tween.Completed:Connect(function()
            menu:Destroy()
            backdrop:Destroy()
        end)
        if onClose then onClose() end
    end

    table.insert(connections, backdrop.Activated:Connect(closeMenu))
    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            if menu and menu.Parent then closeMenu() end
        end
    end))

    menu.Parent = parentFrame

    -- Enter animation
    menu.BackgroundTransparency = 1
    TweenService:Create(menu, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.05,
    }):Play()

    return closeMenu
end

--------------------------------------------------------------------------------
-- GroupPanel Module
--------------------------------------------------------------------------------
local GroupPanel = {}

function GroupPanel.new(parent, store)
    local self = setmetatable({}, { __index = GroupPanel })
    self.store = store
    self.connections = {}

    -- Creator state
    self.isCreatorOpen = false
    self.editingGroupId = nil
    self.groupMode = "fixture"
    self.groupNameInput = ""
    self.selectedFixtures = {}
    self.selectedBeams = {}
    self.expandedFixture = nil
    -- List state
    self.deleteConfirmId = nil
    self.activeCtxClose = nil

    ---------------------------------------------------------------------------
    -- Root Frame
    ---------------------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Name = "GroupPanel"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Visible = false
    frame.Parent = parent
    self.frame = frame

    ---------------------------------------------------------------------------
    -- Main layout (vertical)
    ---------------------------------------------------------------------------
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Padding = UDim.new(0, Theme.Spacing.XL) -- 24
    mainLayout.Parent = frame

    local mainPad = Instance.new("UIPadding")
    mainPad.PaddingTop = UDim.new(0, Theme.Spacing.PanelTopOffset) -- 112
    mainPad.PaddingBottom = UDim.new(0, Theme.Spacing.XL)
    mainPad.PaddingLeft = UDim.new(0, Theme.Spacing.XL)
    mainPad.PaddingRight = UDim.new(0, Theme.Spacing.XL)
    mainPad.Parent = frame

    ---------------------------------------------------------------------------
    -- Header
    ---------------------------------------------------------------------------
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.LayoutOrder = 0
    header.Parent = frame

    local headerLayout = Instance.new("UIListLayout")
    headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    headerLayout.FillDirection = Enum.FillDirection.Horizontal
    headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.SpaceBetween
    headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    headerLayout.Parent = header

    -- Left side: Title + subtitle
    local headerLeft = Instance.new("Frame")
    headerLeft.Size = UDim2.new(1, -400, 1, 0)
    headerLeft.BackgroundTransparency = 1
    headerLeft.Parent = header

    local leftLayout = Instance.new("UIListLayout")
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Padding = UDim.new(0, 4)
    leftLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    leftLayout.Parent = headerLeft

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "Groups"
    title.TextColor3 = Theme.Colors.TextPrimary
    title.TextSize = Theme.FontSize.Body  -- 28 (14px web)
    title.Font = Theme.Font.FamilyBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.LayoutOrder = 0
    title.Parent = headerLeft

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, 0, 0, 22)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = ""
    subtitle.TextColor3 = Theme.Colors.TextSubtle
    subtitle.TextSize = Theme.FontSize.Label  -- 22 (11px web)
    subtitle.Font = Theme.Font.FamilyMedium
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.LayoutOrder = 1
    subtitle.Parent = headerLeft
    self.subtitleLabel = subtitle

    -- Right side: Add Group button
    local addGroupBtn = createSmallButton(header, "Add Group", "secondary", function()
        self:openCreator()
    end)
    addGroupBtn.Size = UDim2.new(0, 280, 0, 56)
    addGroupBtn.TextSize = Theme.FontSize.Small  -- 24 (12px web)
    addGroupBtn.Parent = header

    ---------------------------------------------------------------------------
    -- Content Container (swaps between list and creator)
    ---------------------------------------------------------------------------
    self.contentView = Instance.new("Frame")
    self.contentView.Name = "ContentView"
    self.contentView.Size = UDim2.new(1, 0, 1, -104)
    self.contentView.BackgroundTransparency = 1
    self.contentView.BorderSizePixel = 0
    self.contentView.ClipsDescendants = true
    self.contentView.LayoutOrder = 1
    self.contentView.Parent = frame

    ---------------------------------------------------------------------------
    -- Store listeners
    ---------------------------------------------------------------------------
    self:onGroupsChanged()
    table.insert(self.connections, store:on("groupsChanged", function()
        self:onGroupsChanged()
    end))
    table.insert(self.connections, store:on("groupSelectionChanged", function()
        self:onGroupsChanged()
    end))

    ---------------------------------------------------------------------------
    -- Public API
    ---------------------------------------------------------------------------
    function self:show()
        frame.Visible = true
        frame.BackgroundTransparency = 1
        TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
        }):Play()
        self:onGroupsChanged()
    end

    function self:hide()
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        }):Play()
        spawn(function()
            wait(0.2)
            frame.Visible = false
        end)
    end

    function self:destroy()
        for _, conn in ipairs(self.connections) do
            if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
        end
        self.connections = {}
        if self.activeCtxClose then self.activeCtxClose() end
        frame:Destroy()
    end

    return self
end

--------------------------------------------------------------------------------
-- Render: Groups changed
--------------------------------------------------------------------------------
function GroupPanel:onGroupsChanged()
    if not self.frame or not self.frame.Parent then return end

    -- Update subtitle
    local groups = self.store.groups or {}
    local selectedGroupIds = self.store.selectedGroupIds or {}
    local countText = #groups .. " group" .. (#groups ~= 1 and "s" or "") .. " created"
    if #selectedGroupIds > 0 then
        countText = countText .. "  (" .. #selectedGroupIds .. " selected)"
    end
    if self.subtitleLabel then
        self.subtitleLabel.Text = countText
    end

    if self.isCreatorOpen then
        self:renderCreator()
    else
        self:renderGroupList()
    end
end

--------------------------------------------------------------------------------
-- Render: Group List
--------------------------------------------------------------------------------
function GroupPanel:renderGroupList()
    local content = self.contentView
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("Frame") or child:IsA("ScrollingFrame") then
            child:Destroy()
        end
    end

    local groups = self.store.groups or {}

    if #groups == 0 then
        self:renderEmptyState(content)
        return
    end

    -- Scrollable list
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "GroupList"
    scroll.Size = UDim2.new(1, -12, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 0
    scroll.ScrollBarImageTransparency = 1
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ElasticBehavior = Enum.ElasticBehavior.Never
    scroll.ScrollBarBehavior = Enum.ScrollBarBehavior.Never
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = content

    local scrollContent = Instance.new("Frame")
    scrollContent.Name = "ScrollContent"
    scrollContent.Size = UDim2.new(1, -20, 0, 0)
    scrollContent.BackgroundTransparency = 1
    scrollContent.AutomaticSize = Enum.AutomaticSize.Y
    scrollContent.Parent = scroll

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 12)
    listLayout.Parent = scrollContent

    local selectedGroupIds = self.store.selectedGroupIds or {}

    for i, group in ipairs(groups) do
        local isSelected = inTable(selectedGroupIds, group.id)
        local isDeleting = self.deleteConfirmId == group.id
        local mode = group.mode or "fixture"
        local selectedCount = mode == "fixture"
            and countTable(group.selectedFixtures or {})
            or countTable(group.selectedBeams or {})

        local row = self:createGroupRow(scrollContent, group, i, isSelected, isDeleting, mode, selectedCount)
    end
end

--------------------------------------------------------------------------------
-- Render: Empty State
--------------------------------------------------------------------------------
function GroupPanel:renderEmptyState(parent)
    local empty = Instance.new("Frame")
    empty.Name = "EmptyState"
    empty.Size = UDim2.new(1, 0, 1, 0)
    empty.BackgroundTransparency = 1
    empty.Parent = parent

    local emptyLayout = Instance.new("UIListLayout")
    emptyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    emptyLayout.Padding = UDim.new(0, 16)
    emptyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    emptyLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    emptyLayout.Parent = empty

    -- Icon box
    local iconBox = Instance.new("Frame")
    iconBox.Name = "Icon"
    iconBox.Size = UDim2.new(0, 128, 0, 128)
    iconBox.BackgroundColor3 = Theme.Colors.Surface
    iconBox.BackgroundTransparency = 0.5
    iconBox.BorderSizePixel = 0
    iconBox.LayoutOrder = 0
    iconBox.Parent = empty

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.XXL)
    iconCorner.Parent = iconBox

    local iconStroke = Instance.new("UIStroke")
    iconStroke.Color = Theme.Colors.BorderDefault
    iconStroke.Transparency = 0.5
    iconStroke.Thickness = 2
    iconStroke.Parent = iconBox

    local iconText = Instance.new("TextLabel")
    iconText.Size = UDim2.new(1, 0, 1, 0)
    iconText.BackgroundTransparency = 1
    iconText.Text = "G"
    iconText.TextColor3 = Theme.Colors.TextUltraSubtle
    iconText.TextSize = Theme.FontSize.H3  -- 44
    iconText.Font = Theme.Font.FamilyBold
    iconText.Parent = iconBox

    -- Text
    local emptyTitle = Instance.new("TextLabel")
    emptyTitle.Size = UDim2.new(0, 600, 0, 30)
    emptyTitle.BackgroundTransparency = 1
    emptyTitle.Text = "No groups yet. Create one to get started."
    emptyTitle.TextColor3 = Theme.Colors.TextMuted
    emptyTitle.TextSize = Theme.FontSize.CardTitle
    emptyTitle.Font = Theme.Font.FamilyMedium
    emptyTitle.TextWrapped = true
    emptyTitle.LayoutOrder = 1
    emptyTitle.Parent = empty
end

--------------------------------------------------------------------------------
-- Create: Group Row
--------------------------------------------------------------------------------
function GroupPanel:createGroupRow(parent, group, index, isSelected, isDeleting, mode, selectedCount)
    local row = Instance.new("Frame")
    row.Name = "GroupRow_" .. (group.name or "")
    row.Size = UDim2.new(1, 0, 0, 100)
    row.BackgroundColor3 = Theme.Colors.Background
    row.BackgroundTransparency = isSelected and 0.6 or 0.5
    row.BorderSizePixel = 0
    row.LayoutOrder = index
    row.ClipsDescendants = true
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.XL)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color = isSelected and Theme.Colors.BorderHover or Theme.Colors.BorderDefault
    rowStroke.Thickness = 2
    rowStroke.Transparency = isSelected and 0 or 0.3
    rowStroke.Parent = row

    -- Inner padding
    local innerPad = Instance.new("UIPadding")
    innerPad.PaddingTop = UDim.new(0, ROW_PADDING)
    innerPad.PaddingBottom = UDim.new(0, ROW_PADDING)
    innerPad.PaddingLeft = UDim.new(0, ROW_PADDING)
    innerPad.PaddingRight = UDim.new(0, ROW_PADDING)
    innerPad.Parent = row

    -- Main row content
    local mainRow = Instance.new("Frame")
    mainRow.Name = "MainRow"
    mainRow.Size = UDim2.new(1, 0, 0, isDeleting and 56 or 100)
    mainRow.BackgroundTransparency = 1
    mainRow.LayoutOrder = 0
    mainRow.Parent = row

    local mainRowLayout = Instance.new("UIListLayout")
    mainRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainRowLayout.FillDirection = Enum.FillDirection.Horizontal
    mainRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    mainRowLayout.Parent = mainRow

    -- Checkbox
    local checkbox = Instance.new("TextButton")
    checkbox.Name = "Checkbox"
    checkbox.Size = CHECKBOX_SIZE
    checkbox.BackgroundColor3 = isSelected and Theme.Colors.TextPrimary or Theme.Colors.Surface
    checkbox.BackgroundTransparency = isSelected and 0 or 0.7
    checkbox.Text = isSelected and "✓" or ""
    checkbox.TextColor3 = Theme.Colors.Background
    checkbox.TextSize = 24
    checkbox.Font = Theme.Font.FamilyBold
    checkbox.AutoButtonColor = false
    checkbox.BorderSizePixel = 0
    checkbox.LayoutOrder = 0
    checkbox.Parent = mainRow

    local cbCorner = Instance.new("UICorner")
    cbCorner.CornerRadius = UDim.new(0, 6)
    cbCorner.Parent = checkbox

    if not isSelected then
        local cbStroke = Instance.new("UIStroke")
        cbStroke.Color = Theme.Colors.BorderDefault
        cbStroke.Thickness = 2
        cbStroke.Parent = checkbox
    end

    -- Info column
    local infoCol = Instance.new("Frame")
    infoCol.Name = "Info"
    infoCol.Size = UDim2.new(1, -240, 1, 0)
    infoCol.BackgroundTransparency = 1
    infoCol.LayoutOrder = 1
    infoCol.Parent = mainRow

    local infoLayout = Instance.new("UIListLayout")
    infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
    infoLayout.Padding = UDim.new(0, 4)
    infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    infoLayout.Parent = infoCol

    -- Group name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 26)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = group.name or "Untitled"
    nameLabel.TextColor3 = isSelected and Theme.Colors.TextPrimary or Theme.Colors.TextSecondary
    nameLabel.TextSize = Theme.FontSize.CardTitle
    nameLabel.Font = Theme.Font.FamilyBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.LayoutOrder = 0
    nameLabel.Parent = infoCol

    -- Sub info row (mode badge + count)
    local subInfoRow = Instance.new("Frame")
    subInfoRow.Size = UDim2.new(1, 0, 0, 22)
    subInfoRow.BackgroundTransparency = 1
    subInfoRow.LayoutOrder = 1
    subInfoRow.Parent = infoCol

    local subLayout = Instance.new("UIListLayout")
    subLayout.SortOrder = Enum.SortOrder.LayoutOrder
    subLayout.FillDirection = Enum.FillDirection.Horizontal
    subLayout.Padding = UDim.new(0, 12)
    subLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    subLayout.Parent = subInfoRow

    -- Mode badge
    local modeBadge = Instance.new("Frame")
    modeBadge.Size = UDim2.new(0, 0, 0, 22)
    modeBadge.AutomaticSize = Enum.AutomaticSize.X
    modeBadge.BackgroundColor3 = Theme.Colors.Surface
    modeBadge.BackgroundTransparency = 0.6
    modeBadge.BorderSizePixel = 0
    modeBadge.Parent = subInfoRow

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.MD)
    badgeCorner.Parent = modeBadge

    local badgePad = Instance.new("UIPadding")
    badgePad.PaddingLeft = UDim.new(0, 16)
    badgePad.PaddingRight = UDim.new(0, 16)
    badgePad.Parent = modeBadge

    local badgeText = Instance.new("TextLabel")
    badgeText.Size = UDim2.new(1, 0, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.Text = mode == "fixture" and "Fixture" or "Individual"
    badgeText.TextColor3 = Theme.Colors.TextSubtle
    badgeText.TextSize = Theme.FontSize.Label
    badgeText.Font = Theme.Font.FamilyMedium
    badgeText.Parent = modeBadge

    -- Count text
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(0, 0, 0, 22)
    countLabel.AutomaticSize = Enum.AutomaticSize.X
    countLabel.BackgroundTransparency = 1
    local unitLabel = mode == "fixture" and "fixture" or "beam"
    countLabel.Text = selectedCount .. " " .. unitLabel .. (selectedCount ~= 1 and "s" or "")
    countLabel.TextColor3 = Theme.Colors.TextSubtle
    countLabel.TextSize = Theme.FontSize.Label
    countLabel.Font = Theme.Font.FamilyMedium
    countLabel.Parent = subInfoRow

    -- Preview pills (right side)
    local pillsFrame = Instance.new("Frame")
    pillsFrame.Name = "Pills"
    pillsFrame.Size = UDim2.new(0, 400, 1, 0)
    pillsFrame.BackgroundTransparency = 1
    pillsFrame.LayoutOrder = 2
    pillsFrame.Parent = mainRow

    local pillsLayout = Instance.new("UIListLayout")
    pillsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pillsLayout.FillDirection = Enum.FillDirection.Horizontal
    pillsLayout.Padding = UDim.new(0, 6)
    pillsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    pillsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    pillsLayout.Parent = pillsFrame

    local pillsWrap = Instance.new("UIListLayout")
    pillsWrap.SortOrder = Enum.SortOrder.LayoutOrder
    pillsWrap.FillDirection = Enum.FillDirection.Horizontal
    pillsWrap.Padding = UDim.new(0, 6)
    pillsWrap.WrapDirection = Enum.WrapDirection.Both
    pillsWrap.Parent = pillsFrame

    local items = mode == "fixture"
        and (group.selectedFixtures or {})
        or (function()
            local beams = group.selectedBeams or {}
            local sliced = {}
            for i = 1, math.min(8, #beams) do sliced[i] = beams[i] end
            return sliced
        end)()

    for j, item in ipairs(items) do
        local pill = Instance.new("TextLabel")
        pill.Size = UDim2.new(0, 0, 0, 24)
        pill.AutomaticSize = Enum.AutomaticSize.X
        pill.BackgroundColor3 = Theme.Colors.Surface
        pill.BackgroundTransparency = 0.4
        pill.BorderSizePixel = 0
        pill.Text = tostring(item)
        pill.TextColor3 = Theme.Colors.TextMuted
        pill.TextSize = Theme.FontSize.Tiny  -- 20
        pill.Font = Theme.Font.FamilyMedium
        pill.Parent = pillsFrame

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = UDim.new(0, 4)
        pillCorner.Parent = pill

        local pillPad = Instance.new("UIPadding")
        pillPad.PaddingLeft = UDim.new(0, 12)
        pillPad.PaddingRight = UDim.new(0, 12)
        pillPad.Parent = pill
    end

    if (mode == "fixture" and countTable(group.selectedFixtures or {}) > 8)
        or (mode == "individual" and countTable(group.selectedBeams or {}) > 8) then
        local moreLabel = Instance.new("TextLabel")
        moreLabel.Size = UDim2.new(0, 0, 0, 24)
        moreLabel.AutomaticSize = Enum.AutomaticSize.X
        moreLabel.BackgroundTransparency = 1
        moreLabel.Text = "+" .. tostring(selectedCount - 8)
        moreLabel.TextColor3 = Theme.Colors.TextVerySubtle
        moreLabel.TextSize = Theme.FontSize.Tiny
        moreLabel.Font = Theme.Font.FamilyMedium
        moreLabel.Parent = pillsFrame
    end

    ---------------------------------------------------------------------------
    -- Delete confirmation (inline expansion)
    ---------------------------------------------------------------------------
    local deleteConfirm = nil
    if isDeleting then
        deleteConfirm = Instance.new("Frame")
        deleteConfirm.Name = "DeleteConfirm"
        deleteConfirm.Size = UDim2.new(1, 0, 0, 56)
        deleteConfirm.BackgroundTransparency = 1
        deleteConfirm.LayoutOrder = 1
        deleteConfirm.Parent = row

        -- Top border
        local topBorder = Instance.new("Frame")
        topBorder.Size = UDim2.new(1, 0, 0, 2)
        topBorder.BackgroundColor3 = Theme.Colors.BorderDefault
        topBorder.BackgroundTransparency = 0.5
        topBorder.BorderSizePixel = 0
        topBorder.Parent = deleteConfirm

        local dcLayout = Instance.new("UIListLayout")
        dcLayout.SortOrder = Enum.SortOrder.LayoutOrder
        dcLayout.FillDirection = Enum.FillDirection.Horizontal
        dcLayout.HorizontalAlignment = Enum.HorizontalAlignment.SpaceBetween
        dcLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        dcLayout.Parent = deleteConfirm

        local dcPad = Instance.new("UIPadding")
        dcPad.PaddingTop = UDim.new(0, 16)
        dcPad.PaddingLeft = UDim.new(0, 16)
        dcPad.Parent = deleteConfirm

        local dcText = Instance.new("TextLabel")
        dcText.Size = UDim2.new(0, 0, 0, 26)
        dcText.AutomaticSize = Enum.AutomaticSize.X
        dcText.BackgroundTransparency = 1
        dcText.Text = "Delete '" .. (group.name or "") .. "'?"
        dcText.TextColor3 = Theme.Colors.TextBody
        dcText.TextSize = Theme.FontSize.Label
        dcText.Font = Theme.Font.FamilyMedium
        dcText.Parent = deleteConfirm

        local dcBtns = Instance.new("Frame")
        dcBtns.Size = UDim2.new(0, 0, 0, 44)
        dcBtns.AutomaticSize = Enum.AutomaticSize.X
        dcBtns.BackgroundTransparency = 1
        dcBtns.Parent = deleteConfirm

        local dcBtnsLayout = Instance.new("UIListLayout")
        dcBtnsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        dcBtnsLayout.FillDirection = Enum.FillDirection.Horizontal
        dcBtnsLayout.Padding = UDim.new(0, 12)
        dcBtnsLayout.Parent = dcBtns

        local cancelBtn = createSmallButton(dcBtns, "Cancel", "ghost", function()
            self.deleteConfirmId = nil
            self:onGroupsChanged()
        end)
        cancelBtn.Size = UDim2.new(0, 140, 0, 44)
        cancelBtn.TextSize = Theme.FontSize.Label

        local deleteBtn = createSmallButton(dcBtns, "Delete", "danger", function()
            self.store:removeGroup(group.id)
            self.deleteConfirmId = nil
        end)
        deleteBtn.Size = UDim2.new(0, 140, 0, 44)
        deleteBtn.TextSize = Theme.FontSize.Label

        -- Adjust row height
        row.Size = UDim2.new(1, 0, 0, 156)
        mainRow.Size = UDim2.new(1, 0, 0, 56)
    end

    ---------------------------------------------------------------------------
    -- Events
    ---------------------------------------------------------------------------
    -- Click → toggle selection
    local clickConn
    clickConn = checkbox.Activated:Connect(function()
        self.store:toggleGroupSelection(group.id)
    end)
    table.insert(self.connections, clickConn)

    -- Also click on row to select
    local rowClickConn
    rowClickConn = mainRow.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.store:toggleGroupSelection(group.id)
        end
    end)
    table.insert(self.connections, rowClickConn)

    -- Right-click → context menu
    local rightClickConn
    rightClickConn = row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            local pos = UserInputService:GetMouseLocation()
            if self.activeCtxClose then self.activeCtxClose() end

            self.activeCtxClose = showContextMenu(self.frame, pos, {
                { text = "Edit", callback = function()
                    self:openCreator(group.id)
                end },
                { text = "Delete", danger = true, callback = function()
                    self.deleteConfirmId = group.id
                    self:onGroupsChanged()
                end },
            }, function()
                self.activeCtxClose = nil
            end)
        end
    end)
    table.insert(self.connections, rightClickConn)

    -- Hover effect
    local hoverConn
    hoverConn = row.MouseEnter:Connect(function()
        if not isSelected then
            TweenService:Create(rowStroke, TweenInfo.new(Theme.Animation.HoverEnter), {
                Transparency = 0,
            }):Play()
            TweenService:Create(row, TweenInfo.new(Theme.Animation.HoverEnter), {
                BackgroundTransparency = 0.45,
            }):Play()
        end
    end)
    table.insert(self.connections, hoverConn)

    local leaveConn
    leaveConn = row.MouseLeave:Connect(function()
        if not isSelected then
            TweenService:Create(rowStroke, TweenInfo.new(Theme.Animation.HoverExit), {
                Transparency = 0.3,
            }):Play()
            TweenService:Create(row, TweenInfo.new(Theme.Animation.HoverExit), {
                BackgroundTransparency = 0.5,
            }):Play()
        end
    end)
    table.insert(self.connections, leaveConn)

    return row
end

--------------------------------------------------------------------------------
-- Open: Group Creator / Editor
--------------------------------------------------------------------------------
function GroupPanel:openCreator(editGroupId)
    self.isCreatorOpen = true
    self.editingGroupId = editGroupId or nil

    if editGroupId then
        -- Load existing group data
        local group = nil
        for _, g in ipairs(self.store.groups or {}) do
            if g.id == editGroupId then
                group = g
                break
            end
        end
        if group then
            self.groupNameInput = group.name or ""
            self.groupMode = group.mode or "fixture"
            self.selectedFixtures = group.selectedFixtures and { unpack(group.selectedFixtures) } or {}
            self.selectedBeams = group.selectedBeams and { unpack(group.selectedBeams) } or {}
        end
    else
        self.groupNameInput = ""
        self.groupMode = "fixture"
        self.selectedFixtures = {}
        self.selectedBeams = {}
    end

    self.expandedFixture = nil
    self.deleteConfirmId = nil
    self:renderCreator()
end

function GroupPanel:closeCreator()
    self.isCreatorOpen = false
    self.editingGroupId = nil
    self.expandedFixture = nil
    self:onGroupsChanged()
end

--------------------------------------------------------------------------------
-- Render: Group Creator
--------------------------------------------------------------------------------
function GroupPanel:renderCreator()
    local content = self.contentView
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("Frame") or child:IsA("ScrollingFrame") then
            child:Destroy()
        end
    end

    -- Creator container
    local creator = Instance.new("ScrollingFrame")
    creator.Name = "GroupCreator"
    creator.Size = UDim2.new(1, -12, 1, 0)
    creator.BackgroundTransparency = 1
    creator.BorderSizePixel = 0
    creator.ScrollBarThickness = 0
    creator.ScrollBarImageTransparency = 1
    creator.AutomaticCanvasSize = Enum.AutomaticSize.Y
    creator.ElasticBehavior = Enum.ElasticBehavior.Never
    creator.ScrollBarBehavior = Enum.ScrollBarBehavior.Never
    creator.CanvasSize = UDim2.new(0, 0, 0, 0)
    creator.Parent = content

    local creatorContent = Instance.new("Frame")
    creatorContent.Name = "CreatorContent"
    creatorContent.Size = UDim2.new(1, -20, 0, 0)
    creatorContent.BackgroundTransparency = 1
    creatorContent.AutomaticSize = Enum.AutomaticSize.Y
    creatorContent.Parent = creator

    local creatorLayout = Instance.new("UIListLayout")
    creatorLayout.SortOrder = Enum.SortOrder.LayoutOrder
    creatorLayout.Padding = UDim.new(0, 24)
    creatorLayout.Parent = creatorContent

    local orderIdx = 0

    -- Back button + title row
    orderIdx = orderIdx + 1
    local navRow = Instance.new("Frame")
    navRow.Size = UDim2.new(1, 0, 0, 40)
    navRow.BackgroundTransparency = 1
    navRow.LayoutOrder = orderIdx
    navRow.Parent = creatorContent

    local navLayout = Instance.new("UIListLayout")
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.FillDirection = Enum.FillDirection.Horizontal
    navLayout.Padding = UDim.new(0, 24)
    navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    navLayout.Parent = navRow

    local backBtn = createSmallButton(navRow, "← Back", "ghost", function()
        self:closeCreator()
    end)
    backBtn.Size = UDim2.new(0, 0, 0, 40)
    backBtn.AutomaticSize = Enum.AutomaticSize.X
    backBtn.TextSize = Theme.FontSize.Small

    local creatorTitle = Instance.new("TextLabel")
    creatorTitle.Size = UDim2.new(1, -200, 0, 40)
    creatorTitle.BackgroundTransparency = 1
    creatorTitle.Text = self.editingGroupId and "Edit Group" or "Create Group"
    creatorTitle.TextColor3 = Theme.Colors.TextPrimary
    creatorTitle.TextSize = Theme.FontSize.CardTitle
    creatorTitle.Font = Theme.Font.FamilyBold
    creatorTitle.TextXAlignment = Enum.TextXAlignment.Left
    creatorTitle.Parent = navRow

    -- Name Input Section
    orderIdx = orderIdx + 1
    local nameSection = Instance.new("Frame")
    nameSection.Size = UDim2.new(1, 0, 0, 160)
    nameSection.BackgroundTransparency = 1
    nameSection.LayoutOrder = orderIdx
    nameSection.Parent = creatorContent

    local nameLayout = Instance.new("UIListLayout")
    nameLayout.SortOrder = Enum.SortOrder.LayoutOrder
    nameLayout.Padding = UDim.new(0, 8)
    nameLayout.Parent = nameSection

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "GROUP NAME"
    nameLabel.TextColor3 = Theme.Colors.TextSubtle
    nameLabel.TextSize = Theme.FontSize.Label
    nameLabel.Font = Theme.Font.FamilySemibold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.LayoutOrder = 0
    nameLabel.Parent = nameSection

    local nameInput = Instance.new("TextBox")
    nameInput.Name = "NameInput"
    nameInput.Size = INPUT_WIDTH
    nameInput.BackgroundColor3 = Theme.Colors.Surface
    nameInput.BackgroundTransparency = 0.4
    nameInput.BorderSizePixel = 0
    nameInput.Text = self.groupNameInput
    nameInput.PlaceholderText = "Enter group name..."
    nameInput.PlaceholderColor3 = Theme.Colors.TextSubtle
    nameInput.TextColor3 = Theme.Colors.InputText
    nameInput.TextSize = Theme.FontSize.Small
    nameInput.Font = Theme.Font.FamilyMedium
    nameInput.TextXAlignment = Enum.TextXAlignment.Left
    nameInput.ClearTextOnFocus = false
    nameInput.LayoutOrder = 1
    nameInput.Parent = nameSection

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.LG)
    inputCorner.Parent = nameInput

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Theme.Colors.InputBorder
    inputStroke.Thickness = 2
    inputStroke.Parent = nameInput

    local inputPad = Instance.new("UIPadding")
    inputPad.PaddingLeft = UDim.new(0, INPUT_PADDING)
    inputPad.PaddingRight = UDim.new(0, INPUT_PADDING)
    inputPad.Parent = nameInput

    -- Focus/blur styling
    nameInput.FocusLost:Connect(function()
        inputStroke.Color = Theme.Colors.InputBorder
    end)
    nameInput.Focused:Connect(function()
        inputStroke.Color = Theme.Colors.InputBorderFocus
    end)

    table.insert(self.connections, nameInput:GetPropertyChangedSignal("Text"):Connect(function()
        self.groupNameInput = nameInput.Text
    end))

    local nameHint = Instance.new("TextLabel")
    nameHint.Size = UDim2.new(1, 0, 0, 20)
    nameHint.BackgroundTransparency = 1
    nameHint.Text = "Letters, numbers, spaces, hyphens, underscores only (2-30 chars)"
    nameHint.TextColor3 = Theme.Colors.TextVerySubtle
    nameHint.TextSize = Theme.FontSize.Label
    nameHint.Font = Theme.Font.FamilyMedium
    nameHint.TextXAlignment = Enum.TextXAlignment.Left
    nameHint.LayoutOrder = 2
    nameHint.Parent = nameSection

    -- Mode Selector
    orderIdx = orderIdx + 1
    local modeSection = Instance.new("Frame")
    modeSection.Size = UDim2.new(1, 0, 0, 52)
    modeSection.BackgroundTransparency = 1
    modeSection.LayoutOrder = orderIdx
    modeSection.Parent = creatorContent

    local modeLayout = Instance.new("UIListLayout")
    modeLayout.SortOrder = Enum.SortOrder.LayoutOrder
    modeLayout.FillDirection = Enum.FillDirection.Horizontal
    modeLayout.Padding = UDim.new(0, 16)
    modeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    modeLayout.Parent = modeSection

    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(0, 0, 0, 52)
    modeLabel.AutomaticSize = Enum.AutomaticSize.X
    modeLabel.BackgroundTransparency = 1
    modeLabel.Text = "MODE"
    modeLabel.TextColor3 = Theme.Colors.TextSubtle
    modeLabel.TextSize = Theme.FontSize.Label
    modeLabel.Font = Theme.Font.FamilySemibold
    modeLabel.Parent = modeSection

    local fixtureModeBtn = createSmallButton(modeSection, "Fixture",
        self.groupMode == "fixture" and "active" or "secondary",
        function()
            self.groupMode = "fixture"
            self.expandedFixture = nil
            self:renderCreator()
        end
    )
    fixtureModeBtn.Size = UDim2.new(0, 180, 0, 52)
    fixtureModeBtn.TextSize = Theme.FontSize.Label

    local individualModeBtn = createSmallButton(modeSection, "Individual",
        self.groupMode == "individual" and "active" or "secondary",
        function()
            self.groupMode = "individual"
            self.expandedFixture = nil
            self:renderCreator()
        end
    )
    individualModeBtn.Size = UDim2.new(0, 180, 0, 52)
    individualModeBtn.TextSize = Theme.FontSize.Label

    -- Laser Selector Section
    orderIdx = orderIdx + 1
    local selectorHeader = Instance.new("Frame")
    selectorHeader.Size = UDim2.new(1, 0, 0, 28)
    selectorHeader.BackgroundTransparency = 1
    selectorHeader.LayoutOrder = orderIdx
    selectorHeader.Parent = creatorContent

    local selHeaderLayout = Instance.new("UIListLayout")
    selHeaderLayout.SortOrder = Enum.SortOrder.LayoutOrder
    selHeaderLayout.FillDirection = Enum.FillDirection.Horizontal
    selHeaderLayout.HorizontalAlignment = Enum.HorizontalAlignment.SpaceBetween
    selHeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    selHeaderLayout.Parent = selectorHeader

    local selLabel = Instance.new("TextLabel")
    selLabel.Size = UDim2.new(0, 0, 0, 28)
    selLabel.AutomaticSize = Enum.AutomaticSize.X
    selLabel.BackgroundTransparency = 1
    selLabel.Text = "SELECT LASERS"
    selLabel.TextColor3 = Theme.Colors.TextSubtle
    selLabel.TextSize = Theme.FontSize.Label
    selLabel.Font = Theme.Font.FamilySemibold
    selLabel.Parent = selectorHeader

    local totalSelected = self.groupMode == "fixture"
        and countTable(self.selectedFixtures)
        or countTable(self.selectedBeams)

    local selCount = Instance.new("TextLabel")
    selCount.Size = UDim2.new(0, 0, 0, 28)
    selCount.AutomaticSize = Enum.AutomaticSize.X
    selCount.BackgroundTransparency = 1
    selCount.Text = totalSelected .. " selected"
    selCount.TextColor3 = Theme.Colors.TextMuted
    selCount.TextSize = Theme.FontSize.Label
    selCount.Font = Theme.Font.FamilyMedium
    selCount.Parent = selectorHeader

    -- Selector content
    orderIdx = orderIdx + 1
    if self.groupMode == "fixture" then
        self:renderFixtureGrid(creatorContent, orderIdx)
    else
        self:renderIndividualSelector(creatorContent, orderIdx)
    end

    -- Save button
    orderIdx = orderIdx + 1
    local saveBtn = createSmallButton(creatorContent,
        self.editingGroupId and "Save Changes" or "Create Group",
        "primary",
        function()
            self:saveGroup()
        end
    )
    saveBtn.Size = UDim2.new(1, 0, 0, 64)
    saveBtn.TextSize = Theme.FontSize.Small
    saveBtn.LayoutOrder = orderIdx
end

--------------------------------------------------------------------------------
-- Render: Fixture Grid (8 columns, 24 fixtures)
--------------------------------------------------------------------------------
function GroupPanel:renderFixtureGrid(parent, layoutOrder)
    local grid = Instance.new("Frame")
    grid.Name = "FixtureGrid"
    grid.Size = UDim2.new(1, 0, 0, 0)
    grid.AutomaticSize = Enum.AutomaticSize.Y
    grid.BackgroundTransparency = 1
    grid.LayoutOrder = layoutOrder
    grid.Parent = parent

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.CellSize = FIXTURE_CELL_SIZE
    gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    gridLayout.FillDirectionMaxCells = FIXTURE_GRID_COLS
    gridLayout.Parent = grid

    for i = 1, FIXTURE_COUNT do
        local isSelected = inTable(self.selectedFixtures, i)

        local cell = Instance.new("TextButton")
        cell.Name = "F" .. i
        cell.BackgroundColor3 = isSelected and Theme.Colors.SurfaceActive or Theme.Colors.Surface
        cell.BackgroundTransparency = isSelected and 0.5 or 0.8
        cell.Text = tostring(i)
        cell.TextColor3 = isSelected and Theme.Colors.TextPrimary or Theme.Colors.TextSubtle
        cell.TextSize = Theme.FontSize.Small
        cell.Font = Theme.Font.FamilyBold
        cell.AutoButtonColor = false
        cell.BorderSizePixel = 0
        cell.Parent = grid

        local cellCorner = Instance.new("UICorner")
        cellCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.LG)
        cellCorner.Parent = cell

        local cellStroke = Instance.new("UIStroke")
        cellStroke.Color = isSelected and Theme.Colors.BorderHover or Theme.Colors.BorderDefault
        cellStroke.Thickness = 2
        cellStroke.Transparency = isSelected and 0 or 0.6
        cellStroke.Parent = cell

        local capturedI = i
        table.insert(self.connections, cell.Activated:Connect(function()
            if inTable(self.selectedFixtures, capturedI) then
                removeFromTable(self.selectedFixtures, capturedI)
            else
                table.insert(self.selectedFixtures, capturedI)
            end
            self:renderCreator()
        end))
    end
end

--------------------------------------------------------------------------------
-- Render: Individual Selector (24 expandable fixture rows × 15 beams)
--------------------------------------------------------------------------------
function GroupPanel:renderIndividualSelector(parent, layoutOrder)
    local container = Instance.new("Frame")
    container.Name = "IndividualSelector"
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutOrder
    container.Parent = parent

    local containerLayout = Instance.new("UIListLayout")
    containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    containerLayout.Padding = UDim.new(0, 8)
    containerLayout.Parent = container

    for fNum = 1, FIXTURE_COUNT do
        local beamKeys = {}
        for b = 1, BEAMS_PER_FIXTURE do
            beamKeys[b] = fNum .. "-" .. b
        end

        local selectedCount = 0
        for _, key in ipairs(beamKeys) do
            if inTable(self.selectedBeams, key) then
                selectedCount = selectedCount + 1
            end
        end

        local allSelected = selectedCount == BEAMS_PER_FIXTURE
        local isExpanded = self.expandedFixture == fNum

        -- Fixture row container
        local fixtureRow = Instance.new("Frame")
        fixtureRow.Name = "FixtureRow_" .. fNum
        fixtureRow.Size = UDim2.new(1, 0, 0, 0)
        fixtureRow.AutomaticSize = Enum.AutomaticSize.Y
        fixtureRow.BackgroundColor3 = Theme.Colors.Surface
        fixtureRow.BackgroundTransparency = 0.9
        fixtureRow.BorderSizePixel = 0
        fixtureRow.ClipsDescendants = true
        fixtureRow.Parent = container

        local fRowCorner = Instance.new("UICorner")
        fRowCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.LG)
        fRowCorner.Parent = fixtureRow

        local fRowStroke = Instance.new("UIStroke")
        fRowStroke.Color = Theme.Colors.BorderDefault
        fRowStroke.Thickness = 2
        fRowStroke.Transparency = 0.5
        fRowStroke.Parent = fixtureRow

        local fRowLayout = Instance.new("UIListLayout")
        fRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        fRowLayout.Parent = fixtureRow

        -- Header row (clickable to expand)
        local headerRow = Instance.new("TextButton")
        headerRow.Name = "Header"
        headerRow.Size = UDim2.new(1, 0, 0, 56)
        headerRow.BackgroundTransparency = isExpanded and 0.3 or 0.5
        headerRow.BackgroundColor3 = isExpanded and Theme.Colors.SurfaceActive or Color3.fromRGB(0, 0, 0)
        headerRow.Text = ""
        headerRow.AutoButtonColor = false
        headerRow.BorderSizePixel = 0
        headerRow.LayoutOrder = 0
        headerRow.Parent = fixtureRow

        local hRowLayout = Instance.new("UIListLayout")
        hRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        hRowLayout.FillDirection = Enum.FillDirection.Horizontal
        hRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        hRowLayout.Parent = headerRow

        local hRowPad = Instance.new("UIPadding")
        hRowPad.PaddingLeft = UDim.new(0, 24)
        hRowPad.PaddingRight = UDim.new(0, 24)
        hRowPad.Parent = headerRow

        -- F{number} label
        local fLabel = Instance.new("TextLabel")
        fLabel.Size = UDim2.new(0, 80, 0, 56)
        fLabel.BackgroundTransparency = 1
        fLabel.Text = "F" .. fNum
        fLabel.TextColor3 = Theme.Colors.TextSecondary
        fLabel.TextSize = Theme.FontSize.Small
        fLabel.Font = Theme.Font.FamilyBold
        fLabel.TextXAlignment = Enum.TextXAlignment.Left
        fLabel.LayoutOrder = 0
        fLabel.Parent = headerRow

        -- Beam count
        local bCountLabel = Instance.new("TextLabel")
        bCountLabel.Size = UDim2.new(0, 0, 0, 56)
        bCountLabel.AutomaticSize = Enum.AutomaticSize.X
        bCountLabel.BackgroundTransparency = 1
        bCountLabel.Text = selectedCount > 0
            and (selectedCount .. "/" .. BEAMS_PER_FIXTURE .. " beams")
            or (BEAMS_PER_FIXTURE .. " beams")
        bCountLabel.TextColor3 = Theme.Colors.TextSubtle
        bCountLabel.TextSize = Theme.FontSize.Label
        bCountLabel.Font = Theme.Font.FamilyMedium
        bCountLabel.TextXAlignment = Enum.TextXAlignment.Left
        bCountLabel.LayoutOrder = 1
        bCountLabel.Parent = headerRow

        -- Select All / Deselect button
        local selectAllBtn = Instance.new("TextButton")
        selectAllBtn.Name = "SelectAll"
        selectAllBtn.Size = UDim2.new(0, 0, 0, 56)
        selectAllBtn.AutomaticSize = Enum.AutomaticSize.X
        selectAllBtn.BackgroundTransparency = 1
        selectAllBtn.Text = allSelected and "Deselect" or "Select All"
        selectAllBtn.TextColor3 = Theme.Colors.TextMuted
        selectAllBtn.TextSize = Theme.FontSize.Label
        selectAllBtn.Font = Theme.Font.FamilyMedium
        selectAllBtn.AutoButtonColor = false
        selectAllBtn.BorderSizePixel = 0
        selectAllBtn.LayoutOrder = 2
        selectAllBtn.Parent = headerRow

        local saBtnPad = Instance.new("UIPadding")
        saBtnPad.PaddingLeft = UDim.new(0, 16)
        saBtnPad.PaddingRight = UDim.new(0, 16)
        saBtnPad.Parent = selectAllBtn

        table.insert(self.connections, selectAllBtn.MouseEnter:Connect(function()
            TweenService:Create(selectAllBtn, TweenInfo.new(Theme.Animation.Fast), {
                TextColor3 = Theme.Colors.TextSecondary,
            }):Play()
        end))
        table.insert(self.connections, selectAllBtn.MouseLeave:Connect(function()
            TweenService:Create(selectAllBtn, TweenInfo.new(Theme.Animation.Fast), {
                TextColor3 = Theme.Colors.TextMuted,
            }):Play()
        end))

        -- Expand/collapse click
        local capturedFNum = fNum
        table.insert(self.connections, headerRow.Activated:Connect(function()
            if self.expandedFixture == capturedFNum then
                self.expandedFixture = nil
            else
                self.expandedFixture = capturedFNum
            end
            self:renderCreator()
        end))

        -- Select All / Deselect click (stop propagation by having separate button)
        local saConn
        saConn = selectAllBtn.Activated:Connect(function()
            for _, key in ipairs(beamKeys) do
                if allSelected then
                    removeFromTable(self.selectedBeams, key)
                else
                    if not inTable(self.selectedBeams, key) then
                        table.insert(self.selectedBeams, key)
                    end
                end
            end
            self:renderCreator()
        end)
        table.insert(self.connections, saConn)

        -- Expanded beams grid
        if isExpanded then
            local beamsSection = Instance.new("Frame")
            beamsSection.Name = "BeamsSection"
            beamsSection.Size = UDim2.new(1, 0, 0, 0)
            beamsSection.AutomaticSize = Enum.AutomaticSize.Y
            beamsSection.BackgroundTransparency = 1
            beamsSection.LayoutOrder = 1
            beamsSection.Parent = fixtureRow

            -- Top border
            local topBorder = Instance.new("Frame")
            topBorder.Size = UDim2.new(1, -24, 0, 2)
            topBorder.Position = UDim2.new(0, 24, 0, 0)
            topBorder.BackgroundColor3 = Theme.Colors.BorderDefault
            topBorder.BackgroundTransparency = 0.7
            topBorder.BorderSizePixel = 0
            topBorder.Parent = beamsSection

            local beamsPad = Instance.new("UIPadding")
            beamsPad.PaddingTop = UDim.new(0, 16)
            beamsPad.PaddingBottom = UDim.new(0, 16)
            beamsPad.PaddingLeft = UDim.new(0, 24)
            beamsPad.PaddingRight = UDim.new(0, 24)
            beamsPad.Parent = beamsSection

            local beamsGrid = Instance.new("Frame")
            beamsGrid.Name = "BeamsGrid"
            beamsGrid.Size = UDim2.new(1, 0, 0, 0)
            beamsGrid.AutomaticSize = Enum.AutomaticSize.Y
            beamsGrid.BackgroundTransparency = 1
            beamsGrid.Parent = beamsSection

            local bGridLayout = Instance.new("UIGridLayout")
            bGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
            bGridLayout.CellSize = BEAM_CELL_SIZE
            bGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
            bGridLayout.FillDirectionMaxCells = FIXTURE_GRID_COLS
            bGridLayout.Parent = beamsGrid

            for b = 1, BEAMS_PER_FIXTURE do
                local key = beamKeys[b]
                local isSelected = inTable(self.selectedBeams, key)

                local beamBtn = Instance.new("TextButton")
                beamBtn.Name = "B" .. b
                beamBtn.BackgroundColor3 = isSelected and Theme.Colors.SurfaceActive or Theme.Colors.Surface
                beamBtn.BackgroundTransparency = isSelected and 0.4 or 0.8
                beamBtn.Text = "B" .. b
                beamBtn.TextColor3 = isSelected and Theme.Colors.TextPrimary or Theme.Colors.TextSubtle
                beamBtn.TextSize = Theme.FontSize.Label
                beamBtn.Font = Theme.Font.FamilyMedium
                beamBtn.AutoButtonColor = false
                beamBtn.BorderSizePixel = 0
                beamBtn.Parent = beamsGrid

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.MD)
                bCorner.Parent = beamBtn

                local bStroke = Instance.new("UIStroke")
                bStroke.Color = isSelected and Theme.Colors.BorderHover or Theme.Colors.BorderDefault
                bStroke.Thickness = 2
                bStroke.Transparency = isSelected and 0 or 0.7
                bStroke.Parent = beamBtn

                local capturedKey = key
                table.insert(self.connections, beamBtn.Activated:Connect(function()
                    if inTable(self.selectedBeams, capturedKey) then
                        removeFromTable(self.selectedBeams, capturedKey)
                    else
                        table.insert(self.selectedBeams, capturedKey)
                    end
                    self:renderCreator()
                end))
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Save: Group
--------------------------------------------------------------------------------
function GroupPanel:saveGroup()
    -- Validate name
    local name = self.groupNameInput
    if not name or #name:gsub("^%s*(.-)%s*$", "") < 2 then
        return -- Too short
    end

    name = name:match("^%s*(.-)%s*$") -- trim

    if #name > 30 then
        return -- Too long
    end

    -- Alphanumeric + spaces/hyphens/underscores
    if not name:match("^[%w%s%-%_]+$") then
        return -- Invalid characters
    end

    -- Profanity check (basic)
    local ProfanityFilter = nil
    local ok, err = pcall(function()
        ProfanityFilter = require(script.Parent.Parent.ProfanityFilter)
    end)
    if ok and ProfanityFilter then
        local clean, errMsg = ProfanityFilter.validateName(name, 2, 30)
        if not clean then
            return
        end
    end

    -- Check selection
    local totalSelected = self.groupMode == "fixture"
        and countTable(self.selectedFixtures)
        or countTable(self.selectedBeams)

    if totalSelected == 0 then
        return -- Must select at least one
    end

    if self.editingGroupId then
        -- Update existing group
        for _, g in ipairs(self.store.groups or {}) do
            if g.id == self.editingGroupId then
                g.name = name
                g.mode = self.groupMode
                g.selectedFixtures = { unpack(self.selectedFixtures) }
                g.selectedBeams = { unpack(self.selectedBeams) }
                break
            end
        end
        self.store:emit("groupsChanged", self.store.groups)
    else
        -- Create new group
        local group = self.store:addGroup(name, {})
        group.mode = self.groupMode
        group.selectedFixtures = { unpack(self.selectedFixtures) }
        group.selectedBeams = { unpack(self.selectedBeams) }
    end

    self:closeCreator()
end

return GroupPanel
