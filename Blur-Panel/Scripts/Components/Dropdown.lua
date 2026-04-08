--[[
    Dropdown.lua — Dropdown Menu Component
    The-Blur Roblox SurfaceGUI  |  4K (3840×2160)

    Features:
        - Trigger button + expandable menu list
        - Items with hover highlighting
        - Selected item indicator
        - Animation: scale 0.96→1, opacity 0→1 on open

    Usage:
        local Dropdown = require(script.Parent.Dropdown)
        local dropdown = Dropdown.new(parent, {
            items = { "Option A", "Option B", "Option C" },
            selected = 1,
            position = UDim2.new(0, 0, 0, 0),
            onSelect = function(index, text) print(text) end,
            width = 400,
        })
        dropdown:setSelected(2)
        dropdown:destroy()
]]

local Theme = require(script.Parent.Parent.Theme)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Dropdown = {}

function Dropdown.new(parent, config)
    config = config or {}
    local connections = {}

    local items = config.items or {}
    local selectedIndex = config.selected or 1
    local onSelect = config.onSelect
    local dropdownWidth = config.width or Theme.Dropdown.MinWidth
    local isOpen = false

    -- === Trigger Button ===
    local trigger = Instance.new("TextButton")
    trigger.Name = "DropdownTrigger"
    trigger.Size = UDim2.new(0, dropdownWidth, 0, Theme.Heights.ButtonMd)
    trigger.Position = config.position or UDim2.new(0, 0, 0, 0)
    trigger.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    trigger.BackgroundColor3 = Theme.BgColors.Neutral900_60.Color
    trigger.BackgroundTransparency = Theme.BgColors.Neutral900_60.Transparency
    trigger.Text = ""
    trigger.AutoButtonColor = false
    trigger.BorderSizePixel = 0
    trigger.ZIndex = 10
    trigger.Parent = parent

    local triggerCorner = Instance.new("UICorner")
    triggerCorner.CornerRadius = UDim.new(0, Theme.Radii.MD)
    triggerCorner.Parent = trigger

    local triggerStroke = Instance.new("UIStroke")
    triggerStroke.Color = Theme.BorderColors.Neutral800.Color
    triggerStroke.Transparency = 0
    triggerStroke.Thickness = Theme.BorderWidths.Default
    triggerStroke.Parent = trigger

    -- Selected text label
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Name = "SelectedText"
    selectedLabel.Size = UDim2.new(1, -40, 1, 0)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = items[selectedIndex] or "Select..."
    selectedLabel.TextColor3 = Theme.TextColors.Neutral300
    selectedLabel.TextSize = Theme.FontSizes.Size13
    selectedLabel.Font = Theme.Font
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.Parent = trigger

    -- Trigger padding
    local triggerPad = Instance.new("UIPadding")
    triggerPad.PaddingLeft = UDim.new(0, Theme.Spacing.PX_3)
    triggerPad.PaddingRight = UDim.new(0, Theme.Spacing.PX_3)
    triggerPad.Parent = trigger

    -- Chevron indicator
    local chevron = Instance.new("TextLabel")
    chevron.Name = "Chevron"
    chevron.Size = UDim2.new(0, 24, 0, 24)
    chevron.Position = UDim2.new(1, -Theme.Spacing.PX_3 - 12, 0.5, -12)
    chevron.AnchorPoint = Vector2.new(0, 0.5)
    chevron.BackgroundTransparency = 1
    chevron.Text = "▾"
    chevron.TextColor3 = Theme.TextColors.Neutral500
    chevron.TextSize = Theme.FontSizes.Size12
    chevron.Font = Theme.Font
    chevron.ZIndex = 11
    chevron.Parent = trigger

    -- === Menu Frame (dropdown list) ===
    local menu = Instance.new("Frame")
    menu.Name = "DropdownMenu"
    menu.Size = UDim2.new(0, dropdownWidth, 0, Theme.Dropdown.ItemHeight * math.min(#items, 8))
    menu.Position = UDim2.new(0, 0, 1, 4)
    menu.BackgroundColor3 = Theme.Colors.Neutral950
    menu.BackgroundTransparency = 0.05
    menu.BorderSizePixel = 0
    menu.ClipsDescendants = true
    menu.Visible = false
    menu.ZIndex = 20

    -- Start invisible and scaled down
    menu.BackgroundTransparency = 1

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, Theme.Radii.LG)
    menuCorner.Parent = menu

    local menuStroke = Instance.new("UIStroke")
    menuStroke.Color = Theme.BorderColors.Neutral800_60.Color
    menuStroke.Transparency = Theme.BorderColors.Neutral800_60.Transparency
    menuStroke.Thickness = Theme.BorderWidths.Default
    menuStroke.Parent = menu

    local menuLayout = Instance.new("UIListLayout")
    menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
    menuLayout.Parent = menu

    -- === Item buttons ===
    local itemButtons = {}

    local function buildItems()
        -- Clear existing
        for _, btn in ipairs(itemButtons) do
            if btn and btn.Parent then
                btn:Destroy()
            end
        end
        itemButtons = {}

        for i, text in ipairs(items) do
            local itemBtn = Instance.new("TextButton")
            itemBtn.Name = "Item_" .. i
            itemBtn.Size = UDim2.new(1, 0, 0, Theme.Dropdown.ItemHeight)
            itemBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            itemBtn.BackgroundTransparency = 1
            itemBtn.Text = ""
            itemBtn.AutoButtonColor = false
            itemBtn.BorderSizePixel = 0
            itemBtn.LayoutOrder = i
            itemBtn.ZIndex = 21
            itemBtn.Parent = menu

            -- Item padding
            local itemPad = Instance.new("UIPadding")
            itemPad.PaddingLeft = UDim.new(0, Theme.Dropdown.Padding)
            itemPad.PaddingRight = UDim.new(0, Theme.Dropdown.Padding)
            itemPad.Parent = itemBtn

            -- Item text
            local itemText = Instance.new("TextLabel")
            itemText.Name = "Text"
            itemText.Size = UDim2.new(1, 0, 1, 0)
            itemText.BackgroundTransparency = 1
            itemText.Text = tostring(text)
            itemText.TextColor3 = (i == selectedIndex) and Theme.TextColors.White or Theme.TextColors.Neutral400
            itemText.TextSize = Theme.FontSizes.Size12
            itemText.Font = Theme.Font
            itemText.TextXAlignment = Enum.TextXAlignment.Left
            itemText.ZIndex = 22
            itemText.Parent = itemBtn

            -- Selected indicator
            if i == selectedIndex then
                local indicator = Instance.new("Frame")
                indicator.Name = "SelectedIndicator"
                indicator.Size = UDim2.new(1, 0, 1, 0)
                indicator.BackgroundColor3 = Theme.BgColors.Neutral800_40.Color
                indicator.BackgroundTransparency = Theme.BgColors.Neutral800_40.Transparency
                indicator.BorderSizePixel = 0
                indicator.ZIndex = 20
                indicator.Parent = itemBtn
            end

            -- Hover effect
            table.insert(connections, itemBtn.MouseEnter:Connect(function()
                TweenService:Create(itemBtn, TweenInfo.new(Theme.Animations.Fast), {
                    BackgroundTransparency = 0.7,
                }):Play()
                local textChild = itemBtn:FindFirstChild("Text")
                if textChild then
                    TweenService:Create(textChild, TweenInfo.new(Theme.Animations.Fast), {
                        TextColor3 = Theme.TextColors.White,
                    }):Play()
                end
            end))

            table.insert(connections, itemBtn.MouseLeave:Connect(function()
                TweenService:Create(itemBtn, TweenInfo.new(Theme.Animations.Fast), {
                    BackgroundTransparency = 1,
                }):Play()
                local textChild = itemBtn:FindFirstChild("Text")
                if textChild then
                    local isSelected = (i == selectedIndex)
                    TweenService:Create(textChild, TweenInfo.new(Theme.Animations.Fast), {
                        TextColor3 = isSelected and Theme.TextColors.White or Theme.TextColors.Neutral400,
                    }):Play()
                end
            end))

            -- Click
            table.insert(connections, itemBtn.Activated:Connect(function()
                selectedIndex = i
                selectedLabel.Text = tostring(text)
                menu:close()
                if onSelect then
                    onSelect(i, text)
                end
            end))

            table.insert(itemButtons, itemBtn)
        end

        -- Update menu size
        local totalHeight = Theme.Dropdown.ItemHeight * math.min(#items, 8)
        menu.Size = UDim2.new(0, dropdownWidth, 0, totalHeight)
    end

    buildItems()

    -- === Toggle open/close ===
    function menu:open()
        if isOpen then return end
        isOpen = true

        menu.Visible = true
        menu.BackgroundTransparency = 1

        -- Update menu position below trigger
        menu.Position = UDim2.new(0, trigger.AbsolutePosition.X - (parent and parent.AbsolutePosition.X or 0), 0, trigger.AbsoluteSize.Y + 4)

        TweenService:Create(chevron, TweenInfo.new(Theme.Animations.Fast), {
            Rotation = 180,
        }):Play()

        TweenService:Create(menu, TweenInfo.new(Theme.Animations.Medium, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.05,
        }):Play()
    end

    function menu:close()
        if not isOpen then return end
        isOpen = false

        TweenService:Create(chevron, TweenInfo.new(Theme.Animations.Fast), {
            Rotation = 0,
        }):Play()

        local closeTween = TweenService:Create(menu, TweenInfo.new(Theme.Animations.Fast, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            if not isOpen then
                menu.Visible = false
            end
        end)
    end

    -- Toggle on trigger click
    table.insert(connections, trigger.Activated:Connect(function()
        if isOpen then
            menu:close()
        else
            menu:open()
        end
    end))

    -- === Trigger hover effect ===
    table.insert(connections, trigger.MouseEnter:Connect(function()
        TweenService:Create(triggerStroke, TweenInfo.new(Theme.Animations.Fast), {
            Transparency = 0.3,
        }):Play()
    end))

    table.insert(connections, trigger.MouseLeave:Connect(function()
        TweenService:Create(triggerStroke, TweenInfo.new(Theme.Animations.Fast), {
            Transparency = 0,
        }):Play()
    end))

    -- === Close when clicking outside ===
    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isOpen then
                local pos = input.Position
                local triggerAbs = trigger.AbsolutePosition
                local triggerSize = trigger.AbsoluteSize
                local menuAbs = menu.AbsolutePosition
                local menuSize = menu.AbsoluteSize

                local inTrigger = pos.X >= triggerAbs.X and pos.X <= triggerAbs.X + triggerSize.X
                    and pos.Y >= triggerAbs.Y and pos.Y <= triggerAbs.Y + triggerSize.Y
                local inMenu = pos.X >= menuAbs.X and pos.X <= menuAbs.X + menuSize.X
                    and pos.Y >= menuAbs.Y and pos.Y <= menuAbs.Y + menuSize.Y

                if not inTrigger and not inMenu then
                    menu:close()
                end
            end
        end
    end))

    -- Menu needs to be in a higher-level container for proper z-ordering
    -- Try to parent it to the highest level possible
    local function findSurfaceGui(obj)
        local current = obj
        while current and current.Parent do
            if current:IsA("SurfaceGui") then
                return current
            end
            current = current.Parent
        end
        return parent
    end

    local surfaceGui = findSurfaceGui(parent)
    menu.Parent = surfaceGui

    -- === Public methods ===
    function trigger:setSelected(index)
        selectedIndex = math.clamp(index, 1, #items)
        selectedLabel.Text = items[selectedIndex] or "Select..."
        buildItems()
    end

    function trigger:getSelected()
        return selectedIndex
    end

    function trigger:getSelectedText()
        return items[selectedIndex] or ""
    end

    function trigger:setItems(newItems)
        items = newItems or {}
        if selectedIndex > #items then
            selectedIndex = 1
        end
        selectedLabel.Text = items[selectedIndex] or "Select..."
        buildItems()
    end

    function trigger:destroy()
        for _, conn in ipairs(connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        connections = {}
        menu:Destroy()
        trigger:Destroy()
    end

    trigger.menuFrame = menu
    trigger.itemButtons = itemButtons

    return trigger
end

return Dropdown
