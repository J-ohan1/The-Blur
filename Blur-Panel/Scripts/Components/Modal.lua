--[[
    Modal.lua — Modal/Dialog Overlay Component
    The-Blur Roblox SurfaceGUI  |  4K (3840×2160)

    Features:
        - Full-screen semi-transparent backdrop
        - Centered content frame, rounded-xl, max-width 1520px (760×2)
        - Title, close button (X), content area
        - Enter animation: opacity 0→1, scale 0.85→1 (spring easing)
        - Exit animation: reverse
        - Click backdrop to close

    Usage:
        local Modal = require(script.Parent.Modal)
        local modal = Modal.new(screenGui, {
            title = "Settings",
            width = 1200,
            height = 800,
            content = contentFrame, -- optional pre-built frame
            onClose = function() print("closed") end,
            onOpen = function() print("opened") end,
        })
        modal:open()
        modal:close()
        modal:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")

local Modal = {}

local function createTween(object, properties, duration, style, direction)
    return TweenService:Create(
        object,
        TweenInfo.new(
            duration or Theme.Animations.Medium,
            style or Enum.EasingStyle.Back,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )
end

function Modal.new(parent, config)
    config = config or {}
    local connections = {}
    local isOpen = false

    -- === Backdrop (full-screen) ===
    local backdrop = Instance.new("TextButton")
    backdrop.Name = "ModalBackdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.Position = UDim2.new(0, 0, 0, 0)
    backdrop.BackgroundColor3 = Theme.Modal.Backdrop.Color
    backdrop.BackgroundTransparency = 1 -- start invisible
    backdrop.Text = ""
    backdrop.AutoButtonColor = false
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 100
    backdrop.Parent = parent

    -- === Container (centered) ===
    local container = Instance.new("Frame")
    container.Name = "ModalContainer"
    container.AutomaticSize = Enum.AutomaticSize.None
    local modalWidth = math.min(config.width or Theme.Modal.MaxWidth, Theme.Modal.MaxWidth)
    local modalHeight = config.height or 800
    container.Size = UDim2.new(0, modalWidth, 0, modalHeight)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundColor3 = Theme.Modal.Content.Color
    container.BackgroundTransparency = Theme.Modal.Content.Transparency
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.ZIndex = 101
    container.Visible = false
    container.Parent = parent

    -- UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Theme.Radii.XL)
    corner.Parent = container

    -- UIStroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.BorderColors.Neutral800_60.Color
    stroke.Transparency = Theme.BorderColors.Neutral800_60.Transparency
    stroke.Thickness = Theme.BorderWidths.Default
    stroke.Parent = container

    -- UIListLayout (vertical)
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = container

    -- === Header ===
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, Theme.Modal.HeaderHeight)
    header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.LayoutOrder = 0
    header.ZIndex = 102
    header.Parent = container

    -- Header border bottom
    local headerBorder = Instance.new("Frame")
    headerBorder.Size = UDim2.new(1, 0, 0, Theme.BorderWidths.Default)
    headerBorder.Position = UDim2.new(0, 0, 1, -Theme.BorderWidths.Default)
    headerBorder.BackgroundColor3 = Theme.BorderColors.Neutral800_50.Color
    headerBorder.BackgroundTransparency = Theme.BorderColors.Neutral800_50.Transparency
    headerBorder.BorderSizePixel = 0
    headerBorder.ZIndex = 103
    headerBorder.Parent = header

    -- Header padding
    local headerPad = Instance.new("UIPadding")
    headerPad.PaddingLeft = UDim.new(0, Theme.Modal.Padding)
    headerPad.PaddingRight = UDim.new(0, Theme.Modal.Padding)
    headerPad.Parent = header

    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -Theme.Modal.CloseBtnSize, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = config.title or "Modal"
    titleLabel.TextColor3 = Theme.TextColors.White
    titleLabel.TextSize = Theme.FontSizes.Size16
    titleLabel.Font = Theme.FontSemiBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 104
    titleLabel.Parent = header

    -- Close button (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, Theme.Modal.CloseBtnSize, 0, Theme.Modal.CloseBtnSize)
    closeBtn.Position = UDim2.new(1, -Theme.Modal.CloseBtnSize, 0.5, -Theme.Modal.CloseBtnSize / 2)
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.TextColors.Neutral500
    closeBtn.TextSize = Theme.FontSizes.Size18
    closeBtn.Font = Theme.Font
    closeBtn.AutoButtonColor = false
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 105
    closeBtn.Parent = header

    -- Close button hover
    table.insert(connections, closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(Theme.Animations.Fast), {
            TextColor3 = Theme.TextColors.White,
            BackgroundTransparency = 0.7,
        }):Play()
    end))
    table.insert(connections, closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(Theme.Animations.Fast), {
            TextColor3 = Theme.TextColors.Neutral500,
            BackgroundTransparency = 1,
        }):Play()
    end))
    table.insert(connections, closeBtn.Activated:Connect(function()
        if isOpen then
            container:close()
        end
    end))

    -- === Content Area ===
    local content = config.content
    if content then
        content.Name = "Content"
        content.Size = UDim2.new(1, 0, 1, -(Theme.Modal.HeaderHeight))
        content.LayoutOrder = 1
        content.ClipsDescendants = true
        content.ZIndex = 102
        content.Parent = container
    else
        content = Instance.new("Frame")
        content.Name = "Content"
        content.Size = UDim2.new(1, 0, 1, -(Theme.Modal.HeaderHeight))
        content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.LayoutOrder = 1
        content.ClipsDescendants = true
        content.ZIndex = 102
        content.Parent = container

        local contentPad = Instance.new("UIPadding")
        contentPad.PaddingTop = UDim.new(0, Theme.Modal.Padding)
        contentPad.PaddingBottom = UDim.new(0, Theme.Modal.Padding)
        contentPad.PaddingLeft = UDim.new(0, Theme.Modal.Padding)
        contentPad.PaddingRight = UDim.new(0, Theme.Modal.Padding)
        contentPad.Parent = content
    end

    -- === Backdrop click to close ===
    table.insert(connections, backdrop.Activated:Connect(function()
        if isOpen then
            container:close()
        end
    end))

    -- === Animation state ===
    local enterTweens = {}
    local exitTweens = {}

    -- === Methods ===
    function container:open()
        if isOpen then return end
        isOpen = true

        -- Show container
        container.Visible = true
        backdrop.Visible = true

        -- Reset to initial state
        backdrop.BackgroundTransparency = 1
        container.BackgroundTransparency = 1
        container.Size = UDim2.new(0, modalWidth * 0.85, 0, modalHeight * 0.85)

        -- Play enter animations
        local backdropTween = TweenService:Create(backdrop, TweenInfo.new(Theme.Animations.Medium, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = Theme.Modal.Backdrop.Transparency,
        })
        backdropTween:Play()

        local containerTween = TweenService:Create(container, TweenInfo.new(
            Theme.Animations.Enter,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out
        ), {
            BackgroundTransparency = Theme.Modal.Content.Transparency,
            Size = UDim2.new(0, modalWidth, 0, modalHeight),
        })
        containerTween:Play()

        enterTweens = { backdropTween, containerTween }

        if config.onOpen then
            config.onOpen()
        end
    end

    function container:close()
        if not isOpen then return end
        isOpen = false

        -- Cancel any running enter tweens
        for _, tw in ipairs(enterTweens) do
            tw:Cancel()
        end
        enterTweens = {}

        -- Play exit animations
        local backdropTween = TweenService:Create(backdrop, TweenInfo.new(Theme.Animations.Exit, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        })
        backdropTween:Play()

        local containerTween = TweenService:Create(container, TweenInfo.new(
            Theme.Animations.Exit,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
        ), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, modalWidth * 0.85, 0, modalHeight * 0.85),
        })
        containerTween:Play()

        exitTweens = { backdropTween, containerTween }

        -- Hide after animation
        containerTween.Completed:Connect(function()
            if not isOpen then
                container.Visible = false
                backdrop.Visible = false
            end
        end)

        if config.onClose then
            config.onClose()
        end
    end

    function container:setTitle(text)
        titleLabel.Text = text
    end

    function container:setContent(newContent)
        if content and content.Parent then
            content.Parent = nil
        end
        content = newContent
        content.Size = UDim2.new(1, 0, 1, -(Theme.Modal.HeaderHeight))
        content.LayoutOrder = 1
        content.ClipsDescendants = true
        content.ZIndex = 102
        content.Parent = container
    end

    function container:destroy()
        for _, conn in ipairs(connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        connections = {}
        for _, tw in ipairs(enterTweens) do tw:Cancel() end
        for _, tw in ipairs(exitTweens) do tw:Cancel() end
        container:Destroy()
        backdrop:Destroy()
    end

    container.backdrop = backdrop
    container.content = content
    container.headerFrame = header

    return container
end

return Modal
