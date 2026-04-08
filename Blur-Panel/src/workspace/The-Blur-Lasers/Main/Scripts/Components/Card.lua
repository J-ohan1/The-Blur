--[[
    Card.lua — Card/Panel Container Component
    The-Blur Roblox SurfaceGUI  |  4K (3840×2160)

    Style: bg-neutral-950/50, border-neutral-800/60, rounded-xl (24px 4K)
    Optional header with h-8 (64px), border-bottom, section title

    Usage:
        local Card = require(script.Parent.Card)
        local card = Card.new(parent, {
            title = "Effects",
            size = UDim2.new(1, 0, 0, 500),
            position = UDim2.new(0, 0, 0, 0),
        })
        -- Access card.content for adding children
        -- card.header for modifying the header area
        -- card:destroy() to clean up
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")

local Card = {}

function Card.new(parent, config)
    config = config or {}
    local connections = {}

    -- Root Frame
    local card = Instance.new("Frame")
    card.Name = "Card_" .. (config.title or "unnamed")
    card.Size = config.size or UDim2.new(1, 0, 0, 500)
    card.Position = config.position or UDim2.new(0, 0, 0, 0)
    card.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    card.BackgroundColor3 = Theme.BgColors.Neutral950_50.Color
    card.BackgroundTransparency = Theme.BgColors.Neutral950_50.Transparency
    card.BorderSizePixel = 0
    card.ClipsDescendants = true

    -- UICorner — rounded-xl
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Theme.Radii.XL)
    corner.Parent = card

    -- UIStroke — border-neutral-800/60
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.BorderColors.Neutral800_60.Color
    stroke.Transparency = Theme.BorderColors.Neutral800_60.Transparency
    stroke.Thickness = Theme.BorderWidths.Default
    stroke.Parent = card

    -- UIListLayout (vertical stacking)
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = card

    -- Header (optional)
    local header = nil
    local headerHeight = config.headerHeight or Theme.Heights.PanelHead

    if config.title then
        header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, headerHeight)
        header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        header.BackgroundTransparency = 1
        header.BorderSizePixel = 0
        header.LayoutOrder = 0
        header.Parent = card

        -- Header bottom border
        local headerBorder = Instance.new("Frame")
        headerBorder.Name = "Border"
        headerBorder.Size = UDim2.new(1, 0, 0, Theme.BorderWidths.Default)
        headerBorder.Position = UDim2.new(0, 0, 1, -Theme.BorderWidths.Default)
        headerBorder.BackgroundColor3 = Theme.BorderColors.Neutral800_50.Color
        headerBorder.BackgroundTransparency = Theme.BorderColors.Neutral800_50.Transparency
        headerBorder.BorderSizePixel = 0
        headerBorder.Parent = header

        -- Title text
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(1, 0, 1, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = config.title
        titleLabel.TextColor3 = Theme.TextColors.Neutral300
        titleLabel.TextSize = Theme.FontSizes.Size12
        titleLabel.Font = Theme.FontSemiBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = header

        -- Header padding
        local headerPad = Instance.new("UIPadding")
        headerPad.PaddingLeft = UDim.new(0, Theme.Spacing.PX_4)
        headerPad.PaddingRight = UDim.new(0, Theme.Spacing.PX_4)
        headerPad.PaddingTop = UDim.new(0, 0)
        headerPad.PaddingBottom = UDim.new(0, 0)
        headerPad.Parent = header
    end

    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -(header and headerHeight or 0))
    content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.LayoutOrder = 1
    content.ClipsDescendants = true
    content.Parent = card

    -- Content padding
    local contentPad = Instance.new("UIPadding")
    local pad = config.padding or Theme.Spacing.PX_4
    contentPad.PaddingTop = UDim.new(0, pad)
    contentPad.PaddingBottom = UDim.new(0, pad)
    contentPad.PaddingLeft = UDim.new(0, pad)
    contentPad.PaddingRight = UDim.new(0, pad)
    contentPad.Parent = content

    -- Parent
    card.Parent = parent

    -- Methods
    function card:getContent()
        return content
    end

    function card:getHeader()
        return header
    end

    function card:setTitle(text)
        if header then
            local titleLabel = header:FindFirstChild("Title")
            if titleLabel then
                titleLabel.Text = text
            end
        end
    end

    function card:setPadding(padding)
        contentPad.PaddingTop = UDim.new(0, padding)
        contentPad.PaddingBottom = UDim.new(0, padding)
        contentPad.PaddingLeft = UDim.new(0, padding)
        contentPad.PaddingRight = UDim.new(0, padding)
    end

    function card:addChild(child)
        child.Parent = content
    end

    function card:destroy()
        for _, conn in ipairs(connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        connections = {}
        card:Destroy()
    end

    card.content = content
    card.header = header

    return card
end

return Card
