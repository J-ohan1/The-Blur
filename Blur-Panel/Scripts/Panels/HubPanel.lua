--[[
    HubPanel.lua — Community Hub Panel
    The-Blur Roblox SurfaceGUI  |  4K (3840x2160)

    Browse and share laser effects via the community hub.
    Features: search with easter egg, filter dropdown, 2-col grid,
    hover code preview, "Add" to custom, Top Creators footer,
    My Uploads tab, Viewing User banner.

    Usage:
        local HubPanel = require(script.Parent.HubPanel)
        local panel = HubPanel.new(parentFrame, store)
        panel:show()
        -- Later:
        panel:hide()
        panel:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--------------------------------------------------------------------------------
-- Type label map (matching the web component)
--------------------------------------------------------------------------------

local TYPE_LABELS = {
    all = "All",
    movement = "Movement",
    pattern = "Pattern",
    chase = "Chase",
    strobe = "Strobe",
    wave = "Wave",
    custom = "Custom",
}

local FILTER_OPTIONS = {
    { value = "all", label = "All" },
    { value = "movement", label = "Movement" },
    { value = "pattern", label = "Pattern" },
    { value = "chase", label = "Chase" },
    { value = "strobe", label = "Strobe" },
    { value = "wave", label = "Wave" },
    { value = "custom", label = "Custom" },
}

--------------------------------------------------------------------------------
-- Helper: shallow copy
--------------------------------------------------------------------------------

local function shallowCopy(t)
    local out = {}
    for k, v in pairs(t) do out[k] = v end
    return out
end

--------------------------------------------------------------------------------
-- Helper: format time ago
--------------------------------------------------------------------------------

local function timeAgo(tickVal)
    local seconds = os.time() - tickVal
    if seconds < 60 then return "just now" end
    if seconds < 3600 then
        local m = math.floor(seconds / 60)
        return m .. "m ago"
    end
    if seconds < 86400 then
        local h = math.floor(seconds / 3600)
        return h .. "h ago"
    end
    local d = math.floor(seconds / 86400)
    return d .. "d ago"
end

--------------------------------------------------------------------------------
-- HubPanel
--------------------------------------------------------------------------------

local HubPanel = {}
HubPanel.__index = HubPanel

function HubPanel.new(parent, store)
    local self = setmetatable({}, HubPanel)
    self.store = store
    self.connections = {}
    self.addedIds = {} -- Set of added effect IDs
    self.activeTab = "browse"
    self.filterOpen = false
    self.blurSearchShown = false
    self.deleteConfirmId = nil
    self.deleteConfirmTimer = nil

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
    -- Root frame (full panel area)
    ----------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Name = "HubPanel"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = true
    frame.Visible = false
    frame.Parent = parent

    ----------------------------------------------------------------
    -- Outer padding frame
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
    headerTitle.Name = "Title"
    headerTitle.Size = UDim2.new(1, 0, 0, 36)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Hub"
    headerTitle.TextColor3 = C.TextPrimary
    headerTitle.TextSize = FS.H3
    headerTitle.Font = F.FamilySemibold
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header

    local headerSubtitle = Instance.new("TextLabel")
    headerSubtitle.Name = "Subtitle"
    headerSubtitle.Size = UDim2.new(1, 0, 0, 28)
    headerSubtitle.Position = UDim2.new(0, 0, 0, 36)
    headerSubtitle.BackgroundTransparency = 1
    headerSubtitle.Text = "Community effects shared via Firebase"
    headerSubtitle.TextColor3 = C.TextSubtle
    headerSubtitle.TextSize = FS.Label
    headerSubtitle.Font = F.FamilyLight
    headerSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    headerSubtitle.Parent = header

    ----------------------------------------------------------------
    -- Tabs row
    ----------------------------------------------------------------
    local tabsRow = Instance.new("Frame")
    tabsRow.Name = "TabsRow"
    tabsRow.Size = UDim2.new(1, 0, 0, 52)
    tabsRow.BackgroundTransparency = 1
    tabsRow.LayoutOrder = 1
    tabsRow.Parent = outer

    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabsLayout.FillDirection = Enum.FillDirection.Horizontal
    tabsLayout.Padding = UDim.new(0, S.XS)
    tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabsLayout.Parent = tabsRow

    local function createTabButton(text, tabKey)
        local btn = Instance.new("TextButton")
        btn.Name = "Tab_" .. tabKey
        btn.Size = UDim2.new(0, 200, 0, 40)
        btn.BackgroundColor3 = C.Background
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        btn.LayoutOrder = tabKey == "browse" and 1 or 2
        btn.Parent = tabsRow

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, R.LG)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = C.BorderDefault
        btnStroke.Transparency = 1
        btnStroke.Thickness = 1
        btnStroke.Parent = btn

        local btnLabel = Instance.new("TextLabel")
        btnLabel.Size = UDim2.new(1, 0, 1, 0)
        btnLabel.BackgroundTransparency = 1
        btnLabel.Text = text
        btnLabel.TextColor3 = C.TextSubtle
        btnLabel.TextSize = FS.Small
        btnLabel.Font = F.FamilyMedium
        btnLabel.Parent = btn

        local btnPad = Instance.new("UIPadding")
        btnPad.PaddingLeft = UDim.new(0, S.XL)
        btnPad.PaddingRight = UDim.new(0, S.XL)
        btnPad.Parent = btn

        return btn, btnLabel, btnStroke
    end

    local browseTabBtn, browseTabLabel, browseTabStroke = createTabButton("Browse", "browse")
    local uploadsTabBtn, uploadsTabLabel, uploadsTabStroke = createTabButton("My Uploads", "my_uploads")

    ----------------------------------------------------------------
    -- Content container (tabs swap here)
    ----------------------------------------------------------------
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 1, -132)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ClipsDescendants = true
    contentContainer.LayoutOrder = 2
    contentContainer.Parent = outer

    -- ═══════════════════════════════════════════════════════════
    -- BROWSE TAB
    -- ═══════════════════════════════════════════════════════════

    local browseFrame = Instance.new("Frame")
    browseFrame.Name = "BrowseFrame"
    browseFrame.Size = UDim2.new(1, 0, 1, 0)
    browseFrame.BackgroundTransparency = 1
    browseFrame.ClipsDescendants = true
    browseFrame.Parent = contentContainer

    local browseLayout = Instance.new("UIListLayout")
    browseLayout.SortOrder = Enum.SortOrder.LayoutOrder
    browseLayout.Padding = UDim.new(0, S.SM)
    browseLayout.Parent = browseFrame

    --- Viewing user banner
    local viewingBanner = Instance.new("Frame")
    viewingBanner.Name = "ViewingBanner"
    viewingBanner.Size = UDim2.new(1, 0, 0, 0) -- starts collapsed
    viewingBanner.BackgroundTransparency = 1
    viewingBanner.ClipsDescendants = true
    viewingBanner.Visible = false
    viewingBanner.LayoutOrder = 0
    viewingBanner.Parent = browseFrame

    local vbInner = Instance.new("Frame")
    vbInner.Name = "Inner"
    vbInner.Size = UDim2.new(1, 0, 0, 72)
    vbInner.BackgroundColor3 = C.Surface
    vbInner.BackgroundTransparency = 0.6
    vbInner.BorderSizePixel = 0
    vbInner.Parent = viewingBanner

    local vbCorner = Instance.new("UICorner")
    vbCorner.CornerRadius = UDim.new(0, R.LG)
    vbCorner.Parent = vbInner

    local vbStroke = Instance.new("UIStroke")
    vbStroke.Color = C.BorderDefault
    vbStroke.Transparency = 0.5
    vbStroke.Thickness = 1
    vbStroke.Parent = vbInner

    local vbPad = Instance.new("UIPadding")
    vbPad.PaddingLeft = UDim.new(0, S.LG)
    vbPad.PaddingRight = UDim.new(0, S.LG)
    vbPad.PaddingTop = UDim.new(0, S.SM)
    vbPad.PaddingBottom = UDim.new(0, S.SM)
    vbPad.Parent = vbInner

    -- Avatar circle
    local vbAvatar = Instance.new("Frame")
    vbAvatar.Size = UDim2.new(0, 48, 0, 48)
    vbAvatar.BackgroundColor3 = C.ButtonActive
    vbAvatar.BorderSizePixel = 0
    vbAvatar.Parent = vbInner

    local vbAvatarCorner = Instance.new("UICorner")
    vbAvatarCorner.CornerRadius = UDim.new(0, R.Full)
    vbAvatarCorner.Parent = vbAvatar

    local vbAvatarStroke = Instance.new("UIStroke")
    vbAvatarStroke.Color = C.BorderHover
    vbAvatarStroke.Transparency = 0
    vbAvatarStroke.Thickness = 1
    vbAvatarStroke.Parent = vbAvatar

    local vbAvatarLabel = Instance.new("TextLabel")
    vbAvatarLabel.Size = UDim2.new(1, 0, 1, 0)
    vbAvatarLabel.BackgroundTransparency = 1
    vbAvatarLabel.Text = "?"
    vbAvatarLabel.TextColor3 = C.TextMuted
    vbAvatarLabel.TextSize = FS.Tiny
    vbAvatarLabel.Font = F.FamilyBold
    vbAvatarLabel.Parent = vbAvatar

    -- Name + count
    local vbNameLabel = Instance.new("TextLabel")
    vbNameLabel.Size = UDim2.new(1, -200, 0, 24)
    vbNameLabel.Position = UDim2.new(0, 64, 0, 4)
    vbNameLabel.BackgroundTransparency = 1
    vbNameLabel.Text = ""
    vbNameLabel.TextColor3 = C.TextPrimary
    vbNameLabel.TextSize = FS.Small
    vbNameLabel.Font = F.FamilySemibold
    vbNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    vbNameLabel.Parent = vbInner

    local vbCountLabel = Instance.new("TextLabel")
    vbCountLabel.Size = UDim2.new(1, -200, 0, 20)
    vbCountLabel.Position = UDim2.new(0, 64, 0, 28)
    vbCountLabel.BackgroundTransparency = 1
    vbCountLabel.Text = ""
    vbCountLabel.TextColor3 = C.TextSubtle
    vbCountLabel.TextSize = FS.Tiny
    vbCountLabel.Font = F.FamilyLight
    vbCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    vbCountLabel.Parent = vbInner

    -- Back button
    local vbBackBtn = Instance.new("TextButton")
    vbBackBtn.Size = UDim2.new(0, 120, 0, 36)
    vbBackBtn.Position = UDim2.new(1, -120, 0, 18)
    vbBackBtn.AnchorPoint = Vector2.new(0, 0)
    vbBackBtn.BackgroundColor3 = C.Background
    vbBackBtn.BackgroundTransparency = 1
    vbBackBtn.Text = "Back"
    vbBackBtn.TextColor3 = C.TextMuted
    vbBackBtn.TextSize = FS.Tiny
    vbBackBtn.Font = F.FamilyMedium
    vbBackBtn.AutoButtonColor = false
    vbBackBtn.BorderSizePixel = 0
    vbBackBtn.Parent = vbInner

    local vbBackStroke = Instance.new("UIStroke")
    vbBackStroke.Color = C.BorderLight
    vbBackStroke.Transparency = 0.6
    vbBackStroke.Thickness = 1
    vbBackStroke.Parent = vbBackBtn

    local vbBackCorner = Instance.new("UICorner")
    vbBackCorner.CornerRadius = UDim.new(0, R.MD)
    vbBackCorner.Parent = vbBackBtn

    --- Search + Filter row
    local searchRow = Instance.new("Frame")
    searchRow.Name = "SearchRow"
    searchRow.Size = UDim2.new(1, 0, 0, 80)
    searchRow.BackgroundTransparency = 1
    searchRow.LayoutOrder = 1
    searchRow.Parent = browseFrame

    local searchRowLayout = Instance.new("UIListLayout")
    searchRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    searchRowLayout.FillDirection = Enum.FillDirection.Horizontal
    searchRowLayout.Padding = UDim.new(0, S.LG)
    searchRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    searchRowLayout.Parent = searchRow

    -- Search input
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(0, 600, 0, 64)
    searchFrame.BackgroundColor3 = C.InputBackground
    searchFrame.BackgroundTransparency = 0.4
    searchFrame.BorderSizePixel = 0
    searchFrame.LayoutOrder = 1
    searchFrame.Parent = searchRow

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, R.LG)
    searchCorner.Parent = searchFrame

    local searchStroke = Instance.new("UIStroke")
    searchStroke.Color = C.InputBorder
    searchStroke.Transparency = 0
    searchStroke.Thickness = 1
    searchStroke.Parent = searchFrame

    local searchPad = Instance.new("UIPadding")
    searchPad.PaddingLeft = UDim.new(0, S.LG)
    searchPad.PaddingRight = UDim.new(0, S.LG)
    searchPad.Parent = searchFrame

    local searchInput = Instance.new("TextBox")
    searchInput.Name = "SearchInput"
    searchInput.Size = UDim2.new(1, 0, 1, 0)
    searchInput.BackgroundTransparency = 1
    searchInput.Text = ""
    searchInput.PlaceholderText = "Search effects or creators..."
    searchInput.PlaceholderColor3 = C.TextVerySubtle
    searchInput.TextColor3 = C.InputText
    searchInput.TextSize = FS.Small
    searchInput.Font = F.FamilyLight
    searchInput.TextXAlignment = Enum.TextXAlignment.Left
    searchInput.ClearTextOnFocus = false
    searchInput.Parent = searchFrame

    -- Filter button
    local filterBtn = Instance.new("TextButton")
    filterBtn.Name = "FilterBtn"
    filterBtn.Size = UDim2.new(0, 200, 0, 64)
    filterBtn.BackgroundColor3 = C.Background
    filterBtn.BackgroundTransparency = 0.8
    filterBtn.Text = "Filter"
    filterBtn.TextColor3 = C.TextMuted
    filterBtn.TextSize = FS.Label
    filterBtn.Font = F.FamilyMedium
    filterBtn.AutoButtonColor = false
    filterBtn.BorderSizePixel = 0
    filterBtn.LayoutOrder = 2
    filterBtn.Parent = searchRow

    local filterCorner = Instance.new("UICorner")
    filterCorner.CornerRadius = UDim.new(0, R.LG)
    filterCorner.Parent = filterBtn

    local filterStroke = Instance.new("UIStroke")
    filterStroke.Color = C.BorderDefault
    filterStroke.Transparency = 0.6
    filterStroke.Thickness = 1
    filterStroke.Parent = filterBtn

    local filterPad = Instance.new("UIPadding")
    filterPad.PaddingLeft = UDim.new(0, S.LG)
    filterPad.PaddingRight = UDim.new(0, S.LG)
    filterPad.Parent = filterBtn

    -- Filter dropdown menu
    local filterMenu = Instance.new("Frame")
    filterMenu.Name = "FilterMenu"
    filterMenu.Size = UDim2.new(0, 280, 0, 56 * #FILTER_OPTIONS + 8)
    filterMenu.Position = UDim2.new(0, 0, 1, 4)
    filterMenu.BackgroundColor3 = C.DropdownBg
    filterMenu.BackgroundTransparency = 0.05
    filterMenu.BorderSizePixel = 0
    filterMenu.ClipsDescendants = true
    filterMenu.Visible = false
    filterMenu.ZIndex = Z.Dropdown

    local filterMenuCorner = Instance.new("UICorner")
    filterMenuCorner.CornerRadius = UDim.new(0, R.LG)
    filterMenuCorner.Parent = filterMenu

    local filterMenuStroke = Instance.new("UIStroke")
    filterMenuStroke.Color = C.BorderDefault
    filterMenuStroke.Transparency = 0
    filterMenuStroke.Thickness = 1
    filterMenuStroke.Parent = filterMenu

    local filterMenuLayout = Instance.new("UIListLayout")
    filterMenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
    filterMenuLayout.Parent = filterMenu

    local filterMenuPad = Instance.new("UIPadding")
    filterMenuPad.PaddingTop = UDim.new(0, 4)
    filterMenuPad.PaddingBottom = UDim.new(0, 4)
    filterMenuPad.Parent = filterMenu

    local filterItems = {}
    for i, opt in ipairs(FILTER_OPTIONS) do
        local itemBtn = Instance.new("TextButton")
        itemBtn.Name = "FilterItem_" .. opt.value
        itemBtn.Size = UDim2.new(1, 0, 0, 48)
        itemBtn.BackgroundColor3 = C.Background
        itemBtn.BackgroundTransparency = 1
        itemBtn.Text = "  " .. opt.label
        itemBtn.TextColor3 = C.TextMuted
        itemBtn.TextSize = FS.Label
        itemBtn.Font = F.FamilyLight
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.AutoButtonColor = false
        itemBtn.BorderSizePixel = 0
        itemBtn.LayoutOrder = i
        itemBtn.ZIndex = Z.Dropdown + 1
        itemBtn.Parent = filterMenu

        local itemPad = Instance.new("UIPadding")
        itemPad.PaddingLeft = UDim.new(0, S.SM)
        itemPad.PaddingRight = UDim.new(0, S.SM)
        itemPad.Parent = itemBtn

        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, R.MD)
        itemCorner.Parent = itemBtn

        filterItems[opt.value] = itemBtn
    end

    -- Parent filterMenu to surfacegui-level container
    local function findSurfaceGui(obj)
        local current = obj
        while current and current.Parent do
            if current:IsA("SurfaceGui") then return current end
            current = current.Parent
        end
        return parent
    end
    filterMenu.Parent = findSurfaceGui(parent)

    --- Effect count label
    local effectCountLabel = Instance.new("TextLabel")
    effectCountLabel.Name = "EffectCount"
    effectCountLabel.Size = UDim2.new(1, 0, 0, 24)
    effectCountLabel.BackgroundTransparency = 1
    effectCountLabel.Text = ""
    effectCountLabel.TextColor3 = C.TextVerySubtle
    effectCountLabel.TextSize = FS.Tiny
    effectCountLabel.Font = F.FamilySemibold
    effectCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    effectCountLabel.LayoutOrder = 2
    effectCountLabel.Parent = browseFrame

    --- Effects grid (2 columns via UIGridLayout)
    local gridScroll = Instance.new("ScrollingFrame")
    gridScroll.Name = "GridScroll"
    gridScroll.Size = UDim2.new(1, 0, 1, -340)
    gridScroll.BackgroundTransparency = 1
    gridScroll.ScrollBarThickness = 0
    gridScroll.ScrollBarImageTransparency = 1
    gridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    gridScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    gridScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    gridScroll.LayoutOrder = 3
    gridScroll.Parent = browseFrame

    local gridContent = Instance.new("Frame")
    gridContent.Name = "GridContent"
    gridContent.Size = UDim2.new(1, 0, 0, 0)
    gridContent.BackgroundTransparency = 1
    gridContent.AutomaticSize = Enum.AutomaticSize.Y
    gridContent.Parent = gridScroll

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.CellSize = UDim2.new(0.48, 0, 0, 200)
    gridLayout.CellPadding = UDim2.new(0, S.GridGap, 0, S.GridGap)
    gridLayout.Parent = gridContent

    local gridPad = Instance.new("UIPadding")
    gridPad.PaddingTop = UDim.new(0, 4)
    gridPad.PaddingBottom = UDim.new(0, 4)
    gridPad.Parent = gridContent

    --- Empty state for no results
    local emptyState = Instance.new("Frame")
    emptyState.Name = "EmptyState"
    emptyState.Size = UDim2.new(1, 0, 0, 200)
    emptyState.BackgroundTransparency = 1
    emptyState.Visible = false
    emptyState.LayoutOrder = 4
    emptyState.Parent = browseFrame

    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Size = UDim2.new(1, 0, 1, 0)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "No effects found"
    emptyLabel.TextColor3 = C.TextVerySubtle
    emptyLabel.TextSize = FS.Small
    emptyLabel.Font = F.FamilyLight
    emptyLabel.Parent = emptyState

    --- Top Creators footer
    local topCreatorsFrame = Instance.new("Frame")
    topCreatorsFrame.Name = "TopCreators"
    topCreatorsFrame.Size = UDim2.new(1, 0, 0, 0)
    topCreatorsFrame.BackgroundTransparency = 1
    topCreatorsFrame.Visible = false
    topCreatorsFrame.LayoutOrder = 5
    topCreatorsFrame.ClipsDescendants = true
    topCreatorsFrame.Parent = browseFrame

    local topCreatorsInner = Instance.new("Frame")
    topCreatorsInner.Size = UDim2.new(1, 0, 0, 120)
    topCreatorsInner.BackgroundTransparency = 1
    topCreatorsInner.Parent = topCreatorsFrame

    -- Top border
    local tcBorder = Instance.new("Frame")
    tcBorder.Size = UDim2.new(1, 0, 0, 1)
    tcBorder.BackgroundColor3 = C.BorderDivider
    tcBorder.BackgroundTransparency = 0.4
    tcBorder.BorderSizePixel = 0
    tcBorder.Parent = topCreatorsInner

    local tcTitleLabel = Instance.new("TextLabel")
    tcTitleLabel.Size = UDim2.new(1, 0, 0, 28)
    tcTitleLabel.Position = UDim2.new(0, 0, 0, 8)
    tcTitleLabel.BackgroundTransparency = 1
    tcTitleLabel.Text = "TOP CREATORS"
    tcTitleLabel.TextColor3 = C.TextVerySubtle
    tcTitleLabel.TextSize = 14
    tcTitleLabel.Font = F.FamilyBold
    tcTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    tcTitleLabel.Parent = topCreatorsInner

    local tcRowLayout = Instance.new("UIListLayout")
    tcRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tcRowLayout.FillDirection = Enum.FillDirection.Horizontal
    tcRowLayout.Padding = UDim.new(0, S.SM)
    tcRowLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    tcRowLayout.Parent = topCreatorsInner

    -- ═══════════════════════════════════════════════════════════
    -- MY UPLOADS TAB
    -- ═══════════════════════════════════════════════════════════

    local uploadsFrame = Instance.new("Frame")
    uploadsFrame.Name = "UploadsFrame"
    uploadsFrame.Size = UDim2.new(1, 0, 1, 0)
    uploadsFrame.BackgroundTransparency = 1
    uploadsFrame.ClipsDescendants = true
    uploadsFrame.Visible = false
    uploadsFrame.Parent = contentContainer

    -- Empty state for uploads
    local uploadsEmpty = Instance.new("Frame")
    uploadsEmpty.Size = UDim2.new(1, 0, 1, 0)
    uploadsEmpty.BackgroundTransparency = 1
    uploadsEmpty.Parent = uploadsFrame

    local uploadsIcon = Instance.new("Frame")
    uploadsIcon.Size = UDim2.new(0, 100, 0, 100)
    uploadsIcon.Position = UDim2.new(0.5, -50, 0.35, 0)
    uploadsIcon.BackgroundColor3 = C.Surface
    uploadsIcon.BackgroundTransparency = 0.5
    uploadsIcon.BorderSizePixel = 0
    uploadsIcon.Parent = uploadsEmpty

    local uploadsIconCorner = Instance.new("UICorner")
    uploadsIconCorner.CornerRadius = UDim.new(0, R.XXL)
    uploadsIconCorner.Parent = uploadsIcon

    local uploadsIconStroke = Instance.new("UIStroke")
    uploadsIconStroke.Color = C.BorderDefault
    uploadsIconStroke.Transparency = 0.5
    uploadsIconStroke.Thickness = 1
    uploadsIconStroke.Parent = uploadsIcon

    local uploadsIconLabel = Instance.new("TextLabel")
    uploadsIconLabel.Size = UDim2.new(1, 0, 1, 0)
    uploadsIconLabel.BackgroundTransparency = 1
    uploadsIconLabel.Text = "H"
    uploadsIconLabel.TextColor3 = C.TextUltraSubtle
    uploadsIconLabel.TextSize = 44
    uploadsIconLabel.Font = F.FamilyBold
    uploadsIconLabel.Parent = uploadsIcon

    local uploadsEmptyTitle = Instance.new("TextLabel")
    uploadsEmptyTitle.Size = UDim2.new(1, 0, 0, 32)
    uploadsEmptyTitle.Position = UDim2.new(0.5, 0, 0.35, 120)
    uploadsEmptyTitle.AnchorPoint = Vector2.new(0.5, 0)
    uploadsEmptyTitle.BackgroundTransparency = 1
    uploadsEmptyTitle.Text = "No uploads yet"
    uploadsEmptyTitle.TextColor3 = C.TextMuted
    uploadsEmptyTitle.TextSize = FS.CardTitle
    uploadsEmptyTitle.Font = F.FamilyMedium
    uploadsEmptyTitle.Parent = uploadsEmpty

    local uploadsEmptySub = Instance.new("TextLabel")
    uploadsEmptySub.Size = UDim2.new(1, 0, 0, 24)
    uploadsEmptySub.Position = UDim2.new(0.5, 0, 0.35, 152)
    uploadsEmptySub.AnchorPoint = Vector2.new(0.5, 0)
    uploadsEmptySub.BackgroundTransparency = 1
    uploadsEmptySub.Text = "Publish your custom effects to the Hub"
    uploadsEmptySub.TextColor3 = C.TextVerySubtle
    uploadsEmptySub.TextSize = FS.Label
    uploadsEmptySub.Font = F.FamilyLight
    uploadsEmptySub.Parent = uploadsEmpty

    -- Uploads list (scrollable)
    local uploadsScroll = Instance.new("ScrollingFrame")
    uploadsScroll.Name = "UploadsScroll"
    uploadsScroll.Size = UDim2.new(1, 0, 1, 0)
    uploadsScroll.BackgroundTransparency = 1
    uploadsScroll.ScrollBarThickness = 0
    uploadsScroll.ScrollBarImageTransparency = 1
    uploadsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    uploadsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    uploadsScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    uploadsScroll.Visible = false
    uploadsScroll.Parent = uploadsFrame

    local uploadsList = Instance.new("UIListLayout")
    uploadsList.SortOrder = Enum.SortOrder.LayoutOrder
    uploadsList.Padding = UDim.new(0, S.SM)
    uploadsList.Parent = uploadsScroll

    local uploadsPad = Instance.new("UIPadding")
    uploadsPad.PaddingTop = UDim.new(0, S.SM)
    uploadsPad.PaddingBottom = UDim.new(0, S.SM)
    uploadsPad.Parent = uploadsScroll

    ----------------------------------------------------------------
    -- Internal state references
    ----------------------------------------------------------------
    self.frame = frame
    self.browseFrame = browseFrame
    self.uploadsFrame = uploadsFrame
    self.gridContent = gridContent
    self.browseTabBtn = browseTabBtn
    self.uploadsTabBtn = uploadsTabBtn
    self.browseTabLabel = browseTabLabel
    self.uploadsTabLabel = uploadsTabLabel
    self.browseTabStroke = browseTabStroke
    self.uploadsTabStroke = uploadsTabStroke
    self.searchInput = searchInput
    self.filterBtn = filterBtn
    self.filterMenu = filterMenu
    self.filterItems = filterItems
    self.effectCountLabel = effectCountLabel
    self.emptyState = emptyState
    self.topCreatorsFrame = topCreatorsFrame
    self.topCreatorsInner = topCreatorsInner
    self.viewingBanner = viewingBanner
    self.vbAvatarLabel = vbAvatarLabel
    self.vbNameLabel = vbNameLabel
    self.vbCountLabel = vbCountLabel
    self.uploadsScroll = uploadsScroll
    self.uploadsEmpty = uploadsEmpty

    ----------------------------------------------------------------
    -- Methods
    ----------------------------------------------------------------

    --- Refresh the entire browse tab
    function self:refreshBrowse()
        local effects = self.store.hubEffects or {}
        local viewingUser = self.store.hubViewingUser
        local filter = self.store.hubFilter or "all"
        local search = (self.store.hubSearch or ""):lower()

        -- Filter effects
        local filtered = {}
        for _, fx in ipairs(effects) do
            if viewingUser and fx.authorId ~= viewingUser then continue end
            if filter ~= "all" and fx.type ~= filter then continue end
            if #search > 0 then
                local nameMatch = fx.name:lower():find(search, 1, true)
                local authorMatch = fx.authorName:lower():find(search, 1, true)
                if not nameMatch and not authorMatch then continue end
            end
            table.insert(filtered, fx)
        end

        -- Update count
        local countText = #filtered .. " effect" .. (#filtered ~= 1 and "s" or "") .. " found"
        if filter ~= "all" then
            countText = countText .. "  --  " .. (TYPE_LABELS[filter] or filter)
        end
        effectCountLabel.Text = countText

        -- Show/hide empty state
        emptyState.Visible = #filtered == 0

        -- Clear existing cards
        for _, child in ipairs(gridContent:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then
                child:Destroy()
            end
        end

        -- Create effect cards
        for i, fx in ipairs(filtered) do
            self:_createEffectCard(gridContent, fx, i)
        end

        -- Viewing banner
        if viewingUser then
            viewingBanner.Visible = true
            local viewingData = nil
            for _, e in ipairs(effects) do
                if e.authorId == viewingUser then
                    viewingData = e
                    break
                end
            end
            if viewingData then
                vbAvatarLabel.Text = viewingData.authorName:sub(1, 1):upper()
                vbNameLabel.Text = viewingData.authorName
                local userCount = 0
                for _, e in ipairs(effects) do
                    if e.authorId == viewingUser then userCount = userCount + 1 end
                end
                vbCountLabel.Text = userCount .. " effect" .. (userCount ~= 1 and "s" or "") .. " shared"
            end
            topCreatorsFrame.Visible = false
        else
            viewingBanner.Visible = false
            self:refreshTopCreators()
        end
    end

    --- Create an effect card
    function self:_createEffectCard(parent, fx, index)
        local card = Instance.new("Frame")
        card.Name = "Card_" .. fx.id
        card.BackgroundColor3 = C.HubCardBg
        card.BackgroundTransparency = 0.5
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.LayoutOrder = index

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, R.XL)
        cardCorner.Parent = card

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = C.BorderDefault
        cardStroke.Transparency = 0.3
        cardStroke.Thickness = 1
        cardStroke.Parent = card

        -- Top section: name + author
        local topSection = Instance.new("Frame")
        topSection.Size = UDim2.new(1, 0, 0, 100)
        topSection.BackgroundTransparency = 1
        topSection.Parent = card

        local topPad = Instance.new("UIPadding")
        topPad.PaddingLeft = UDim.new(0, S.XL)
        topPad.PaddingRight = UDim.new(0, S.XL)
        topPad.PaddingTop = UDim.new(0, S.XL)
        topPad.Parent = topSection

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0, 26)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = fx.name
        nameLabel.TextColor3 = C.TextSecondary
        nameLabel.TextSize = FS.CardTitle
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Font = F.FamilySemibold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = topSection

        local authorLabel = Instance.new("TextLabel")
        authorLabel.Size = UDim2.new(1, 0, 0, 22)
        authorLabel.Position = UDim2.new(0, 0, 0, 30)
        authorLabel.BackgroundTransparency = 1
        authorLabel.Text = "by " .. fx.authorName
        authorLabel.TextColor3 = C.TextSubtle
        authorLabel.TextSize = FS.Tiny
        authorLabel.Font = F.FamilyLight
        authorLabel.TextXAlignment = Enum.TextXAlignment.Left
        authorLabel.Parent = topSection

        -- Author click detection (whole card)
        local authorClickBtn = Instance.new("TextButton")
        authorClickBtn.Size = UDim2.new(1, 0, 0, 48)
        authorClickBtn.BackgroundTransparency = 1
        authorClickBtn.Text = ""
        authorClickBtn.AutoButtonColor = false
        authorClickBtn.Parent = topSection

        -- Bottom row: badge + downloads + add
        local bottomSection = Instance.new("Frame")
        bottomSection.Size = UDim2.new(1, 0, 0, 48)
        bottomSection.Position = UDim2.new(0, 0, 1, -48)
        bottomSection.BackgroundTransparency = 1
        bottomSection.Parent = card

        local bottomPad = Instance.new("UIPadding")
        bottomPad.PaddingLeft = UDim.new(0, S.XL)
        bottomPad.PaddingRight = UDim.new(0, S.XL)
        bottomPad.Parent = bottomSection

        -- Type badge
        local badge = Instance.new("TextLabel")
        badge.Size = UDim2.new(0, 100, 0, 28)
        badge.BackgroundColor3 = C.ButtonActive
        badge.BackgroundTransparency = 0.4
        badge.Text = TYPE_LABELS[fx.type] or fx.type
        badge.TextColor3 = C.TextMuted
        badge.TextSize = 14
        badge.Font = F.FamilyMedium
        badge.BorderSizePixel = 0
        badge.Parent = bottomSection

        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, R.MD)
        badgeCorner.Parent = badge

        -- Downloads
        local dlLabel = Instance.new("TextLabel")
        dlLabel.Size = UDim2.new(0, 120, 0, 28)
        dlLabel.Position = UDim2.new(0, 108, 0, 0)
        dlLabel.BackgroundTransparency = 1
        dlLabel.Text = fx.downloads .. " dl"
        dlLabel.TextColor3 = C.TextVerySubtle
        dlLabel.TextSize = 14
        dlLabel.Font = F.FamilyLight
        dlLabel.TextXAlignment = Enum.TextXAlignment.Left
        dlLabel.Parent = bottomSection

        -- Add button
        local isAdded = self.addedIds[fx.id] == true
        local addBtn = Instance.new("TextButton")
        addBtn.Size = UDim2.new(0, 120, 0, 36)
        addBtn.Position = UDim2.new(1, -120, 0, 6)
        addBtn.BackgroundColor3 = isAdded and C.ButtonActive or C.ButtonPrimary
        addBtn.BackgroundTransparency = isAdded and 0.6 or 0
        addBtn.Text = isAdded and "Added" or "Add"
        addBtn.TextColor3 = isAdded and C.TextSubtle or C.ButtonPrimaryText
        addBtn.TextSize = FS.Tiny
        addBtn.Font = F.FamilyMedium
        addBtn.AutoButtonColor = false
        addBtn.BorderSizePixel = 0
        addBtn.ZIndex = Z.Button
        addBtn.Parent = bottomSection

        local addCorner = Instance.new("UICorner")
        addCorner.CornerRadius = UDim.new(0, R.MD)
        addCorner.Parent = addBtn

        if not isAdded then
            local addStroke = Instance.new("UIStroke")
            addStroke.Color = C.BorderDefault
            addStroke.Transparency = 1
            addStroke.Thickness = 1
            addStroke.Parent = addBtn
        end

        -- Hover effects
        table.insert(self.connections, card.MouseEnter:Connect(function()
            if isAdded then return end
            TweenService:Create(addBtn, TweenInfo.new(A.HoverEnter), {
                BackgroundColor3 = C.ButtonPrimaryHover,
            }):Play()
        end))

        table.insert(self.connections, card.MouseLeave:Connect(function()
            if isAdded then return end
            TweenService:Create(addBtn, TweenInfo.new(A.HoverExit), {
                BackgroundColor3 = C.ButtonPrimary,
            }):Play()
        end))

        -- Add button click
        if not isAdded then
            table.insert(self.connections, addBtn.Activated:Connect(function()
                self.addedIds[fx.id] = true
                addBtn.Text = "Added"
                addBtn.BackgroundColor3 = C.ButtonActive
                addBtn.BackgroundTransparency = 0.6
                addBtn.TextColor3 = C.TextSubtle
                -- Add to store saved effects
                if self.store.addHubEffectToCustom then
                    self.store:addHubEffectToCustom(fx)
                end
                self.store:emit("toast", "Effect added to custom", "success")
            end))
        end

        -- Author click
        table.insert(self.connections, authorClickBtn.Activated:Connect(function()
            self.store.hubViewingUser = fx.authorId
            self.store:emit("hubViewingUserChanged", fx.authorId)
            self:refreshBrowse()
        end))

        -- Code preview overlay
        local codePreview = Instance.new("Frame")
        codePreview.Name = "CodePreview"
        codePreview.Size = UDim2.new(1, 0, 0, 80)
        codePreview.Position = UDim2.new(0, 0, 1, -80)
        codePreview.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
        codePreview.BackgroundTransparency = 0.05
        codePreview.BorderSizePixel = 0
        codePreview.Visible = false
        codePreview.ZIndex = Z.Button
        codePreview.ClipsDescendants = true
        codePreview.Parent = card

        local cpTopBorder = Instance.new("Frame")
        cpTopBorder.Size = UDim2.new(1, 0, 0, 1)
        cpTopBorder.BackgroundColor3 = C.BorderDefault
        cpTopBorder.BackgroundTransparency = 0.5
        cpTopBorder.BorderSizePixel = 0
        cpTopBorder.Parent = codePreview

        local cpPad = Instance.new("UIPadding")
        cpPad.PaddingLeft = UDim.new(0, S.XL)
        cpPad.PaddingRight = UDim.new(0, S.XL)
        cpPad.PaddingTop = UDim.new(0, S.SM)
        cpPad.Parent = codePreview

        local cpTitle = Instance.new("TextLabel")
        cpTitle.Size = UDim2.new(1, 0, 0, 18)
        cpTitle.BackgroundTransparency = 1
        cpTitle.Text = "Code Preview"
        cpTitle.TextColor3 = C.TextSubtle
        cpTitle.TextSize = 14
        cpTitle.Font = F.FamilyMedium
        cpTitle.TextXAlignment = Enum.TextXAlignment.Left
        cpTitle.Parent = codePreview

        local cpCode = Instance.new("TextLabel")
        cpCode.Size = UDim2.new(1, 0, 0, 40)
        cpCode.Position = UDim2.new(0, 0, 0, 20)
        cpCode.BackgroundTransparency = 1
        cpCode.Text = fx.codeLines and table.concat(fx.codeLines, "\n"):sub(1, 120) or ""
        cpCode.TextColor3 = C.TextBody
        cpCode.TextSize = 14
        cpCode.Font = F.Mono
        cpCode.TextXAlignment = Enum.TextXAlignment.Left
        cpCode.TextYAlignment = Enum.TextYAlignment.Top
        cpCode.TextTruncate = Enum.TextTruncate.AtEnd
        cpCode.Parent = codePreview

        -- Hover to show code preview
        table.insert(self.connections, card.MouseEnter:Connect(function()
            TweenService:Create(codePreview, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.05,
            }):Play()
            codePreview.Visible = true
        end))

        table.insert(self.connections, card.MouseLeave:Connect(function()
            TweenService:Create(codePreview, TweenInfo.new(0.15), {
                BackgroundTransparency = 1,
            }):Play()
            spawn(function()
                wait(0.15)
                codePreview.Visible = false
            end)
        end))

        card.Parent = parent -- Will be reparented by UIGridLayout automatically
        -- Actually UIGridLayout works on children of gridContent
        card.Parent = gridContent
    end

    --- Refresh top creators footer
    function self:refreshTopCreators()
        local effects = self.store.hubEffects or {}
        local authorMap = {}
        for _, e in ipairs(effects) do
            if not authorMap[e.authorId] then
                authorMap[e.authorId] = { name = e.authorName, count = 0, totalDownloads = 0 }
            end
            authorMap[e.authorId].count = authorMap[e.authorId].count + 1
            authorMap[e.authorId].totalDownloads = authorMap[e.authorId].totalDownloads + e.downloads
        end

        -- Sort by total downloads
        local sorted = {}
        for id, data in pairs(authorMap) do
            table.insert(sorted, { id = id, name = data.name, count = data.count, totalDownloads = data.totalDownloads })
        end
        table.sort(sorted, function(a, b) return a.totalDownloads > b.totalDownloads end)

        -- Clear existing creator buttons
        for _, child in ipairs(self.topCreatorsInner:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        topCreatorsFrame.Visible = #sorted > 0 and not self.store.hubViewingUser

        if #sorted == 0 then return end

        local top = sorted
        if #top > 6 then top = { unpack(top, 1, 6) } end

        for i, author in ipairs(top) do
            local btn = Instance.new("TextButton")
            btn.Name = "Creator_" .. author.id
            btn.Size = UDim2.new(0, 0, 0, 36)
            btn.AutomaticSize = Enum.AutomaticSize.X
            btn.BackgroundColor3 = C.Background
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.BorderSizePixel = 0
            btn.LayoutOrder = i
            btn.Parent = self.topCreatorsInner

            local btnStroke = Instance.new("UIStroke")
            btnStroke.Color = C.BorderLight
            btnStroke.Transparency = 0.6
            btnStroke.Thickness = 1
            btnStroke.Parent = btn

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, R.MD)
            btnCorner.Parent = btn

            local btnPad = Instance.new("UIPadding")
            btnPad.PaddingLeft = UDim.new(0, S.SM)
            btnPad.PaddingRight = UDim.new(0, S.SM)
            btnPad.Parent = btn

            -- Avatar circle
            local avatar = Instance.new("Frame")
            avatar.Size = UDim2.new(0, 28, 0, 28)
            avatar.BackgroundColor3 = C.ButtonActive
            avatar.BackgroundTransparency = 0
            avatar.BorderSizePixel = 0
            avatar.Parent = btn

            local avatarCorner = Instance.new("UICorner")
            avatarCorner.CornerRadius = UDim.new(0, R.Full)
            avatarCorner.Parent = avatar

            local avatarStroke2 = Instance.new("UIStroke")
            avatarStroke2.Color = C.BorderHover
            avatarStroke2.Transparency = 0
            avatarStroke2.Thickness = 1
            avatarStroke2.Parent = avatar

            local avatarLbl = Instance.new("TextLabel")
            avatarLbl.Size = UDim2.new(1, 0, 1, 0)
            avatarLbl.BackgroundTransparency = 1
            avatarLbl.Text = author.name:sub(1, 1):upper()
            avatarLbl.TextColor3 = C.TextMuted
            avatarLbl.TextSize = 12
            avatarLbl.Font = F.FamilyBold
            avatarLbl.Parent = avatar

            -- Name + count
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -56, 1, 0)
            nameLabel.Position = UDim2.new(0, 36, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = author.name
            nameLabel.TextColor3 = C.TextMuted
            nameLabel.TextSize = FS.Tiny
            nameLabel.Font = F.FamilyLight
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = btn

            table.insert(self.connections, btn.Activated:Connect(function()
                self.store.hubViewingUser = author.id
                self.store:emit("hubViewingUserChanged", author.id)
                self:refreshBrowse()
            end))
        end
    end

    --- Refresh uploads tab
    function self:refreshUploads()
        local effects = self.store.hubEffects or {}
        local currentUser = self.store.currentUser
        local myEffects = {}
        for _, e in ipairs(effects) do
            if e.authorId == currentUser.id then
                table.insert(myEffects, e)
            end
        end

        uploadsEmpty.Visible = #myEffects == 0
        uploadsScroll.Visible = #myEffects > 0

        -- Clear existing
        for _, child in ipairs(uploadsScroll:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for i, fx in ipairs(myEffects) do
            local row = Instance.new("Frame")
            row.Name = "Upload_" .. fx.id
            row.Size = UDim2.new(1, 0, 0, 72)
            row.BackgroundColor3 = C.Surface
            row.BackgroundTransparency = 0.7
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Parent = uploadsScroll

            local rowStroke = Instance.new("UIStroke")
            rowStroke.Color = C.BorderDefault
            rowStroke.Transparency = 0.4
            rowStroke.Thickness = 1
            rowStroke.Parent = row

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, R.LG)
            rowCorner.Parent = row

            local rowPad = Instance.new("UIPadding")
            rowPad.PaddingLeft = UDim.new(0, S.XL)
            rowPad.PaddingRight = UDim.new(0, S.XL)
            rowPad.PaddingTop = UDim.new(0, S.SM)
            rowPad.PaddingBottom = UDim.new(0, S.SM)
            rowPad.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -100, 0, 26)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = fx.name
            nameLabel.TextColor3 = C.TextSecondary
            nameLabel.TextSize = FS.Small
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Font = F.FamilyMedium
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = row

            local metaLabel = Instance.new("TextLabel")
            metaLabel.Size = UDim2.new(1, -100, 0, 20)
            metaLabel.Position = UDim2.new(0, 0, 0, 28)
            metaLabel.BackgroundTransparency = 1
            metaLabel.Text = (TYPE_LABELS[fx.type] or fx.type) .. "  |  " .. fx.downloads .. " downloads"
            metaLabel.TextColor3 = C.TextVerySubtle
            metaLabel.TextSize = FS.Tiny
            metaLabel.Font = F.FamilyLight
            metaLabel.TextXAlignment = Enum.TextXAlignment.Left
            metaLabel.Parent = row

            local agoLabel = Instance.new("TextLabel")
            agoLabel.Size = UDim2.new(0, 120, 0, 20)
            agoLabel.Position = UDim2.new(1, -120, 0, 26)
            agoLabel.BackgroundTransparency = 1
            agoLabel.Text = timeAgo(fx.createdAt)
            agoLabel.TextColor3 = C.TextVerySubtle
            agoLabel.TextSize = FS.Tiny
            agoLabel.Font = F.FamilyLight
            agoLabel.Parent = row
        end
    end

    --- Switch tabs
    function self:setTab(tab)
        self.activeTab = tab
        local isBrowse = tab == "browse"

        browseFrame.Visible = isBrowse
        uploadsFrame.Visible = not isBrowse

        -- Update tab button styles
        if isBrowse then
            browseTabBtn.BackgroundTransparency = 0
            browseTabStroke.Transparency = 0.3
            browseTabLabel.TextColor3 = C.TextPrimary
            uploadsTabBtn.BackgroundTransparency = 1
            uploadsTabStroke.Transparency = 1
            uploadsTabLabel.TextColor3 = C.TextSubtle
        else
            uploadsTabBtn.BackgroundTransparency = 0
            uploadsTabStroke.Transparency = 0.3
            uploadsTabLabel.TextColor3 = C.TextPrimary
            browseTabBtn.BackgroundTransparency = 1
            browseTabStroke.Transparency = 1
            browseTabLabel.TextColor3 = C.TextSubtle
        end

        if isBrowse then
            self:refreshBrowse()
        else
            self:refreshUploads()
        end
    end

    ----------------------------------------------------------------
    -- Event connections
    ----------------------------------------------------------------

    -- Tab clicks
    table.insert(self.connections, browseTabBtn.Activated:Connect(function()
        self:setTab("browse")
    end))

    table.insert(self.connections, uploadsTabBtn.Activated:Connect(function()
        self:setTab("my_uploads")
    end))

    -- Search input
    table.insert(self.connections, searchInput.FocusLost:Connect(function()
        local text = searchInput.Text
        self.store.hubSearch = text

        -- Easter egg: "blur" search
        if text:lower():trim() == "blur" and not self.blurSearchShown then
            self.blurSearchShown = true
            self.store:emit("toast", "Searching for greatness, are we?", "success")
        end
        if text:lower():trim() ~= "blur" then
            self.blurSearchShown = false
        end

        self:refreshBrowse()
    end))

    table.insert(self.connections, searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        self.store.hubSearch = searchInput.Text
        self:refreshBrowse()
    end))

    -- Search input enter key
    table.insert(self.connections, searchInput.FocusLost:Connect(function()
        -- Already handled above
    end))

    -- Filter button
    table.insert(self.connections, filterBtn.Activated:Connect(function()
        self.filterOpen = not self.filterOpen
        if self.filterOpen then
            filterMenu.Visible = true
            filterMenu.BackgroundTransparency = 1
            -- Position below filter button
            filterMenu.Position = UDim2.new(
                0, filterBtn.AbsolutePosition.X - (parent and parent.AbsolutePosition.X or 0),
                0, filterBtn.AbsolutePosition.Y + filterBtn.AbsoluteSize.Y + 4
            )
            TweenService:Create(filterMenu, TweenInfo.new(A.DropdownOpen), {
                BackgroundTransparency = 0.05,
            }):Play()
        else
            self:closeFilterMenu()
        end
    end))

    -- Filter hover
    table.insert(self.connections, filterBtn.MouseEnter:Connect(function()
        TweenService:Create(filterStroke, TweenInfo.new(A.HoverEnter), {
            Transparency = 0.3,
        }):Play()
        TweenService:Create(filterBtn, TweenInfo.new(A.HoverEnter), {
            TextColor3 = C.TextBody,
        }):Play()
    end))

    table.insert(self.connections, filterBtn.MouseLeave:Connect(function()
        TweenService:Create(filterStroke, TweenInfo.new(A.HoverExit), {
            Transparency = 0.6,
        }):Play()
        TweenService:Create(filterBtn, TweenInfo.new(A.HoverExit), {
            TextColor3 = C.TextMuted,
        }):Play()
    end))

    -- Filter item clicks
    for val, itemBtn in pairs(self.filterItems) do
        table.insert(self.connections, itemBtn.Activated:Connect(function()
            self.store.hubFilter = val
            self.filterOpen = false
            self:closeFilterMenu()
            self:updateFilterBtnStyle()
            self:refreshBrowse()
        end))

        -- Hover
        table.insert(self.connections, itemBtn.MouseEnter:Connect(function()
            TweenService:Create(itemBtn, TweenInfo.new(A.Fast), {
                BackgroundTransparency = 0.3,
            }):Play()
            itemBtn.TextColor3 = C.TextPrimary
        end))

        table.insert(self.connections, itemBtn.MouseLeave:Connect(function()
            TweenService:Create(itemBtn, TweenInfo.new(A.Fast), {
                BackgroundTransparency = 1,
            }):Play()
            itemBtn.TextColor3 = (val == self.store.hubFilter) and C.TextPrimary or C.TextMuted
        end))
    end

    -- Back button (viewing user)
    table.insert(self.connections, vbBackBtn.Activated:Connect(function()
        self.store.hubViewingUser = nil
        self.store:emit("hubViewingUserChanged", nil)
        self:refreshBrowse()
    end))

    -- Back button hover
    table.insert(self.connections, vbBackBtn.MouseEnter:Connect(function()
        TweenService:Create(vbBackBtn, TweenInfo.new(A.Fast), {
            BackgroundTransparency = 0.7,
        }):Play()
        vbBackBtn.TextColor3 = C.TextPrimary
    end))

    table.insert(self.connections, vbBackBtn.MouseLeave:Connect(function()
        TweenService:Create(vbBackBtn, TweenInfo.new(A.Fast), {
            BackgroundTransparency = 1,
        }):Play()
        vbBackBtn.TextColor3 = C.TextMuted
    end))

    -- Close dropdown on outside click
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if self.filterOpen then
                self.filterOpen = false
                self:closeFilterMenu()
            end
        end
    end))

    -- Store listeners
    table.insert(self.connections, self.store:on("hubEffectsChanged", function()
        if self.activeTab == "browse" then self:refreshBrowse() end
        if self.activeTab == "my_uploads" then self:refreshUploads() end
    end))

    -- Initialize
    self:setTab("browse")
    self:updateFilterBtnStyle()

    return self
end

--------------------------------------------------------------------------------
-- Filter menu helpers
--------------------------------------------------------------------------------

function HubPanel:closeFilterMenu()
    local menu = self.filterMenu
    if menu.Visible then
        local closeTween = TweenService:Create(menu, TweenInfo.new(Theme.Animation.DropdownClose), {
            BackgroundTransparency = 1,
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            menu.Visible = false
        end)
    end
end

function HubPanel:updateFilterBtnStyle()
    local filter = self.store.hubFilter or "all"
    local btn = self.filterBtn
    local stroke = btn:FindFirstChildOfClass("UIStroke")

    if filter ~= "all" then
        btn.BackgroundColor3 = Theme.Colors.ButtonActive
        btn.BackgroundTransparency = 0.5
        btn.TextColor3 = Theme.Colors.TextPrimary
        if stroke then stroke.Color = Theme.Colors.BorderHover; stroke.Transparency = 0 end
    else
        btn.BackgroundColor3 = Theme.Colors.Background
        btn.BackgroundTransparency = 0.8
        btn.TextColor3 = Theme.Colors.TextMuted
        if stroke then stroke.Color = Theme.Colors.BorderDefault; stroke.Transparency = 0.6 end
    end

    -- Update filter item highlights
    for val, itemBtn in pairs(self.filterItems) do
        if val == filter then
            itemBtn.TextColor3 = Theme.Colors.TextPrimary
        else
            itemBtn.TextColor3 = Theme.Colors.TextMuted
        end
    end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function HubPanel:show()
    self.frame.Visible = true
    TweenService:Create(self.frame, TweenInfo.new(Theme.Animation.PanelFadeIn), {
        BackgroundTransparency = 1,
    }):Play()
    self:refreshBrowse()
end

function HubPanel:hide()
    local fadeOut = TweenService:Create(self.frame, TweenInfo.new(Theme.Animation.PanelFadeOut), {
        BackgroundTransparency = 1,
    })
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        self.frame.Visible = false
    end)
end

function HubPanel:destroy()
    self:closeFilterMenu()
    for _, conn in ipairs(self.connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self.connections = {}
    self.frame:Destroy()
end

return HubPanel
