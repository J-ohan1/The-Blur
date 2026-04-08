--[[
    ContextMenu.lua — Right-Click Context Menu Component
    The-Blur Roblox SurfaceGUI  |  4K (3840×2160)

    Features:
        - Appears at click position (viewport-aware positioning)
        - Items with hover highlight, optional icons
        - Separator lines between groups
        - Close on click outside
        - Disabled items support

    Usage:
        local ContextMenu = require(script.Parent.ContextMenu)
        local ctx = ContextMenu.new(screenGui, {
            items = {
                { text = "Copy", icon = "📋", callback = function() print("copied") end },
                { text = "Paste", icon = "📄", callback = function() print("pasted") end },
                { separator = true },
                { text = "Delete", icon = "🗑️", callback = function() print("deleted") end, disabled = false },
                { text = "Disabled Option", disabled = true },
            },
            position = Vector2.new(500, 300),
            onClose = function() print("closed") end,
        })
        ctx:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ContextMenu = {}

function ContextMenu.new(parent, config)
    config = config or {}
    local connections = {}
    local items = config.items or {}
    local onClose = config.onClose
    local clickPosition = config.position or Vector2.new(0, 0)

    -- === Backdrop (close on outside click) ===
    local backdrop = Instance.new("TextButton")
    backdrop.Name = "ContextMenuBackdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.Text = ""
    backdrop.AutoButtonColor = false
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 200
    backdrop.Parent = parent

    -- === Menu Container ===
    local menu = Instance.new("Frame")
    menu.Name = "ContextMenu"
    menu.BackgroundColor3 = Theme.Colors.Neutral950
    menu.BackgroundTransparency = 0.05
    menu.BorderSizePixel = 0
    menu.ClipsDescendants = true
    menu.ZIndex = 201

    -- Start hidden
    menu.Visible = false
    menu.BackgroundTransparency = 1

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, Theme.Radii.LG)
    menuCorner.Parent = menu

    local menuStroke = Instance.new("UIStroke")
    menuStroke.Color = Theme.BorderColors.Neutral800_60.Color
    menuStroke.Transparency = Theme.BorderColors.Neutral800_60.Transparency
    menuStroke.Thickness = Theme.BorderWidths.Default
    menuStroke.Parent = menu

    -- Shadow (subtle dark glow)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.ImageTransparency = 0.4
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.ZIndex = 200
    shadow.Parent = menu

    -- Menu layout
    local menuLayout = Instance.new("UIListLayout")
    menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
    menuLayout.Parent = menu

    local menuPadding = Instance.new("UIPadding")
    menuPadding.PaddingTop = UDim.new(0, Theme.ContextMenu.Padding)
    menuPadding.PaddingBottom = UDim.new(0, Theme.ContextMenu.Padding)
    menuPadding.Parent = menu

    -- === Build items ===
    local itemHeight = Theme.ContextMenu.ItemHeight
    local separatorHeight = 2

    local function buildMenu()
        -- Clear existing children (except layout, padding, corner, stroke, shadow)
        for _, child in ipairs(menu:GetChildren()) do
            if child.Name ~= "UIListLayout"
                and child.Name ~= "UIPadding"
                and child.ClassName ~= "UICorner"
                and child.ClassName ~= "UIStroke"
                and child.Name ~= "Shadow" then
                child:Destroy()
            end
        end

        local totalHeight = Theme.ContextMenu.Padding -- top
        local maxWidth = 0

        for i, item in ipairs(items) do
            if item.separator then
                -- Separator line
                local sep = Instance.new("Frame")
                sep.Name = "Separator"
                sep.Size = UDim2.new(1, -Theme.ContextMenu.Padding * 2, 0, separatorHeight)
                sep.BackgroundColor3 = Theme.ContextMenu.SeparatorColor.Color
                sep.BackgroundTransparency = Theme.ContextMenu.SeparatorColor.Transparency
                sep.BorderSizePixel = 0
                sep.LayoutOrder = i
                sep.ZIndex = 202
                sep.Parent = menu

                totalHeight = totalHeight + separatorHeight + 4 -- 4px spacing
            else
                -- Item button
                local itemBtn = Instance.new("TextButton")
                itemBtn.Name = "Item_" .. (item.text or "unnamed")
                itemBtn.Size = UDim2.new(1, 0, 0, itemHeight)
                itemBtn.BackgroundTransparency = 1
                itemBtn.Text = ""
                itemBtn.AutoButtonColor = false
                itemBtn.BorderSizePixel = 0
                itemBtn.LayoutOrder = i
                itemBtn.ZIndex = 202
                itemBtn.Parent = menu

                local isDisabled = item.disabled == true

                -- Item padding
                local itemPad = Instance.new("UIPadding")
                itemPad.PaddingLeft = UDim.new(0, Theme.ContextMenu.Padding)
                itemPad.PaddingRight = UDim.new(0, Theme.ContextMenu.Padding)
                itemPad.Parent = itemBtn

                -- Icon (optional)
                if item.icon then
                    local icon = Instance.new("TextLabel")
                    icon.Name = "Icon"
                    icon.Size = UDim2.new(0, 32, 1, 0)
                    icon.BackgroundTransparency = 1
                    icon.Text = item.icon
                    icon.TextSize = Theme.FontSizes.Size14
                    icon.Font = Theme.Font
                    icon.TextXAlignment = Enum.TextXAlignment.Center
                    icon.TextTransparency = isDisabled and 0.5 or 0
                    icon.ZIndex = 203
                    icon.Parent = itemBtn
                end

                -- Text label
                local textOffset = item.icon and 40 or 0
                local itemText = Instance.new("TextLabel")
                itemText.Name = "Text"
                itemText.Size = UDim2.new(1, -textOffset, 1, 0)
                itemText.Position = UDim2.new(0, textOffset, 0, 0)
                itemText.BackgroundTransparency = 1
                itemText.Text = item.text or ""
                itemText.TextColor3 = isDisabled and Theme.TextColors.Neutral700 or Theme.TextColors.Neutral300
                itemText.TextSize = Theme.FontSizes.Size12
                itemText.Font = Theme.Font
                itemText.TextXAlignment = Enum.TextXAlignment.Left
                itemText.TextTransparency = isDisabled and 0.5 or 0
                itemText.ZIndex = 203
                itemText.Parent = itemBtn

                -- Estimate width
                local estimatedWidth = Theme.FontSizes.Size12 * (#tostring(item.text or "") * 0.6 + 1) + textOffset + Theme.ContextMenu.Padding * 2
                if estimatedWidth > maxWidth then
                    maxWidth = estimatedWidth
                end

                -- Hover effect (only if not disabled)
                if not isDisabled then
                    table.insert(connections, itemBtn.MouseEnter:Connect(function()
                        TweenService:Create(itemBtn, TweenInfo.new(Theme.Animations.Fast), {
                            BackgroundTransparency = 0.7,
                        }):Play()
                        TweenService:Create(itemText, TweenInfo.new(Theme.Animations.Fast), {
                            TextColor3 = Theme.TextColors.White,
                        }):Play()
                    end))

                    table.insert(connections, itemBtn.MouseLeave:Connect(function()
                        TweenService:Create(itemBtn, TweenInfo.new(Theme.Animations.Fast), {
                            BackgroundTransparency = 1,
                        }):Play()
                        TweenService:Create(itemText, TweenInfo.new(Theme.Animations.Fast), {
                            TextColor3 = Theme.TextColors.Neutral300,
                        }):Play()
                    end))

                    -- Click handler
                    table.insert(connections, itemBtn.Activated:Connect(function()
                        if item.callback then
                            item.callback()
                        end
                        menu:close()
                    end))
                end

                totalHeight = totalHeight + itemHeight
            end
        end

        totalHeight = totalHeight + Theme.ContextMenu.Padding -- bottom

        -- Set final size
        local finalWidth = math.max(maxWidth, config.width or Theme.ContextMenu.MinWidth)
        finalWidth = math.min(finalWidth, Theme.ContextMenu.MaxWidth)
        menu.Size = UDim2.new(0, finalWidth, 0, totalHeight)

        return finalWidth, totalHeight
    end

    local menuWidth, menuHeight = buildMenu()

    -- === Viewport-aware positioning ===
    local function positionMenu()
        local gui = parent
        local viewportSize = gui.AbsoluteSize

        local x = clickPosition.X
        local y = clickPosition.Y

        -- Ensure menu stays within viewport
        if x + menuWidth > viewportSize.X then
            x = viewportSize.X - menuWidth - 16
        end
        if y + menuHeight > viewportSize.Y then
            y = viewportSize.Y - menuHeight - 16
        end

        -- Clamp minimum
        x = math.max(8, x)
        y = math.max(8, y)

        menu.Position = UDim2.new(0, x, 0, y)
    end

    positionMenu()

    -- === Open animation ===
    function menu:open(position)
        if position then
            clickPosition = position
        end

        menuWidth, menuHeight = buildMenu()
        positionMenu()

        menu.Visible = true
        menu.BackgroundTransparency = 1

        -- Fade in + scale animation
        TweenService:Create(menu, TweenInfo.new(Theme.Animations.Medium, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.05,
        }):Play()
    end

    function menu:close()
        -- Fade out animation
        local closeTween = TweenService:Create(menu, TweenInfo.new(Theme.Animations.Fast, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            menu.Visible = false
        end)

        if onClose then
            onClose()
        end
    end

    -- === Backdrop click to close ===
    table.insert(connections, backdrop.Activated:Connect(function()
        menu:close()
    end))

    -- === Close on outside input ===
    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if menu.Visible then
                local pos = input.Position
                local menuAbs = menu.AbsolutePosition
                local menuSize = menu.AbsoluteSize

                local inMenu = pos.X >= menuAbs.X and pos.X <= menuAbs.X + menuSize.X
                    and pos.Y >= menuAbs.Y and pos.Y <= menuAbs.Y + menuSize.Y

                if not inMenu then
                    menu:close()
                end
            end
        end
    end))

    -- === Escape key to close ===
    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            if menu.Visible then
                menu:close()
            end
        end
    end))

    -- === Parent menu to proper container ===
    menu.Parent = parent

    -- Open immediately
    menu:open()

    -- === Public methods ===
    function menu:setItems(newItems)
        items = newItems or {}
        menuWidth, menuHeight = buildMenu()
        positionMenu()
    end

    function menu:reposition(position)
        clickPosition = position
        menuWidth, menuHeight = buildMenu()
        positionMenu()
    end

    function menu:isVisible()
        return menu.Visible
    end

    function menu:destroy()
        for _, conn in ipairs(connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        connections = {}
        menu:Destroy()
        backdrop:Destroy()
    end

    return menu
end

return ContextMenu
