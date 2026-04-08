--[[
    ScrollFrame.lua — Custom Scrollable Frame Component
    The-Blur Roblox SurfaceGUI  |  4K (3840×2160)

    Custom scrollbar matching website style:
        - 10px wide (5px web * 2)
        - Thumb: #262626, hover #404040, rounded corners
        - Track: transparent

    Usage:
        local ScrollFrame = require(script.Parent.ScrollFrame)
        local scroll = ScrollFrame.new(parent, {
            size = UDim2.new(1, 0, 1, 0),
            position = UDim2.new(0, 0, 0, 0),
            canvasSize = UDim2.new(0, 0, 0, 2000),
            padding = Theme.Spacing.PX_4,
        })
        scroll:add(childFrame)
        scroll:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")

local ScrollFrame = {}

function ScrollFrame.new(parent, config)
    config = config or {}
    local connections = {}

    -- === Root ScrollingFrame ===
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "ScrollFrame"
    scroll.Size = config.size or UDim2.new(1, 0, 1, 0)
    scroll.Position = config.position or UDim2.new(0, 0, 0, 0)
    scroll.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    scroll.CanvasSize = config.canvasSize or UDim2.new(0, 0, 0, 0)
    scroll.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 0 -- Hide default scrollbar
    scroll.ScrollBarImageTransparency = 1
    scroll.AutomaticCanvasSize = config.automaticCanvasSize or Enum.AutomaticSize.Y
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
    scroll.ElasticBehavior = Enum.ElasticBehavior.Never
    scroll.ScrollBarBehavior = Enum.ScrollBarBehavior.Never
    scroll.Parent = parent

    -- === Content Frame (inside scroll) ===
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -Theme.Scrollbar.Width - 8, 1, 0) -- Account for scrollbar width
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.AutomaticSize = Enum.AutomaticSize.Y

    local contentList = Instance.new("UIListLayout")
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    contentList.Padding = UDim.new(0, 0)
    content.Parent = content

    local contentPadding = Instance.new("UIPadding")
    local pad = config.padding or Theme.Spacing.PX_2
    contentPadding.PaddingTop = UDim.new(0, pad)
    contentPadding.PaddingBottom = UDim.new(0, pad)
    contentPadding.PaddingLeft = UDim.new(0, pad)
    contentPadding.PaddingRight = UDim.new(0, pad)
    contentPadding.Parent = content

    content.Parent = scroll

    -- === Custom Scrollbar ===
    local scrollbar = Instance.new("Frame")
    scrollbar.Name = "CustomScrollbar"
    scrollbar.Size = UDim2.new(0, Theme.Scrollbar.Width, 1, -8)
    scrollbar.Position = UDim2.new(1, -(Theme.Scrollbar.Width + 4), 0, 4)
    scrollbar.BackgroundTransparency = 1 -- Track is transparent
    scrollbar.BorderSizePixel = 0
    scrollbar.ZIndex = 10
    scrollbar.Parent = scroll

    -- Scrollbar thumb
    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(1, 0, 0.2, 0) -- Default: 20% of track
    thumb.Position = UDim2.new(0, 0, 0, 0)
    thumb.BackgroundColor3 = Theme.Scrollbar.ThumbColor
    thumb.BackgroundTransparency = 0
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 11
    thumb.Parent = scrollbar

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(0, Theme.Scrollbar.ThumbRadius)
    thumbCorner.Parent = thumb

    -- === Thumb hover effect ===
    table.insert(connections, thumb.MouseEnter:Connect(function()
        TweenService:Create(thumb, TweenInfo.new(Theme.Animations.Fast), {
            BackgroundColor3 = Theme.Scrollbar.ThumbHoverColor,
        }):Play()
    end))

    table.insert(connections, thumb.MouseLeave:Connect(function()
        TweenService:Create(thumb, TweenInfo.new(Theme.Animations.Fast), {
            BackgroundColor3 = Theme.Scrollbar.ThumbColor,
        }):Play()
    end))

    -- === Scroll position tracking ===
    local function updateThumbPosition()
        local canvasY = scroll.AbsoluteCanvasSize.Y
        local viewY = scroll.AbsoluteSize.Y

        if canvasY <= viewY then
            thumb.Visible = false
            return
        end

        thumb.Visible = true

        local ratio = scroll.CanvasPosition.Y / math.max(1, canvasY - viewY)
        local thumbRatio = viewY / canvasY
        local maxThumbY = 1 - thumbRatio

        thumb.Size = UDim2.new(1, 0, math.max(0.02, thumbRatio), 0)
        thumb.Position = UDim2.new(0, 0, ratio * maxThumbY, 0)
    end

    table.insert(connections, scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(updateThumbPosition))
    table.insert(connections, scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateThumbPosition))
    table.insert(connections, scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateThumbPosition))

    -- === Thumb drag support ===
    local isDraggingThumb = false
    local dragStartY = 0
    local dragStartCanvasY = 0

    table.insert(connections, thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingThumb = true
            dragStartY = input.Position.Y
            dragStartCanvasY = scroll.CanvasPosition.Y
        end
    end))

    table.insert(connections, thumb.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingThumb = false
        end
    end))

    -- We need to track drag via UserInputService
    local UserInputService = game:GetService("UserInputService")
    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if isDraggingThumb and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local deltaY = input.Position.Y - dragStartY
            local canvasY = scroll.AbsoluteCanvasSize.Y
            local viewY = scroll.AbsoluteSize.Y
            local trackHeight = scrollbar.AbsoluteSize.Y
            local thumbHeight = thumb.AbsoluteSize.Y
            local maxDrag = trackHeight - thumbHeight

            if maxDrag > 0 then
                local scrollRange = canvasY - viewY
                local ratio = deltaY / maxDrag
                local newY = math.clamp(dragStartCanvasY + ratio * scrollRange, 0, scrollRange)
                scroll.CanvasPosition = Vector2.new(0, newY)
            end
        end
    end))

    -- === Public methods ===
    function scroll:add(child)
        child.Parent = content
        return child
    end

    function scroll:setCanvasSize(udim2)
        scroll.CanvasSize = udim2
    end

    function scroll:setPadding(padding)
        if type(padding) == "table" then
            contentPadding.PaddingTop = UDim.new(0, padding.Top or padding[1] or 0)
            contentPadding.PaddingBottom = UDim.new(0, padding.Bottom or padding[2] or padding[1] or 0)
            contentPadding.PaddingLeft = UDim.new(0, padding.Left or padding[3] or padding[1] or 0)
            contentPadding.PaddingRight = UDim.new(0, padding.Right or padding[4] or padding[3] or padding[1] or 0)
        else
            contentPadding.PaddingTop = UDim.new(0, padding)
            contentPadding.PaddingBottom = UDim.new(0, padding)
            contentPadding.PaddingLeft = UDim.new(0, padding)
            contentPadding.PaddingRight = UDim.new(0, padding)
        end
    end

    function scroll:setItemSpacing(spacing)
        contentList.Padding = UDim.new(0, spacing)
    end

    function scroll:scrollToTop()
        scroll.CanvasPosition = Vector2.new(0, 0)
    end

    function scroll:destroy()
        for _, conn in ipairs(connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        connections = {}
        scroll:Destroy()
    end

    scroll.contentFrame = content

    -- Initial thumb update
    task.defer(updateThumbPosition)

    return scroll
end

return ScrollFrame
