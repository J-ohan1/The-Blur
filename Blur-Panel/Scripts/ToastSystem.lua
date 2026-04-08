--[[
    ToastSystem.lua — Toast Notification System
    The-Blur Roblox SurfaceGUI  |  4K (3840x2160)

    Stack of toast notifications appearing from the top-right.
    Auto-dismiss after 3s, click to dismiss, max 5 visible.

    Export: ToastSystem.new(parent, store) -> { frame, show(message, type), destroy() }
]]

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Theme)
local TweenHelper = require(script.Parent.TweenHelper)

local ToastSystem = {}

local MAX_VISIBLE_TOASTS = 5
local AUTO_DISMISS_TIME = 3
local ENTER_DURATION = 0.25
local EXIT_DURATION = 0.25

local TOAST_DOT_COLORS = {
    success = Theme.Colors.ToastSuccess,  -- white
    warning = Theme.Colors.ToastWarning,  -- neutral-400
    error   = Theme.Colors.ToastError,    -- neutral-500
}

function ToastSystem.new(parent, store)
    assert(store, "ToastSystem requires a Store instance")

    local self = {}
    self._connections = {}
    self._store = store
    self._activeToasts = {} -- Array of { id, frame, dismissDelay }

    ---------------------------------------------------------------------------
    -- Container: fixed position, top-16(128px), right-4(32px)
    ---------------------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Name = "ToastContainer"
    frame.Size = UDim2.new(0, 600, 0, 0) -- fixed width, auto height
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Position = UDim2.new(1, -32, 0, 128) -- right-4(32px), top-16(128px)
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ZIndex = Theme.ZIndex.Toast
    frame.Parent = parent

    -- UIListLayout for vertical stacking, gap-2(16px)
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, Theme.Spacing.XXL) -- 16px gap
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.Parent = frame

    ---------------------------------------------------------------------------
    -- Create a single toast element
    ---------------------------------------------------------------------------
    local function createToastElement(toastId, message, toastType)
        toastType = toastType or "success"

        local toast = Instance.new("Frame")
        toast.Name = "Toast_" .. toastId
        toast.Size = UDim2.new(0, 520, 0, 0) -- min-width 260px * 2 = 520px
        toast.AutomaticSize = Enum.AutomaticSize.Y
        toast.BackgroundColor3 = Color3.fromRGB(10, 10, 10) -- bg-neutral-950/90
        toast.BackgroundTransparency = 0.1
        toast.BorderSizePixel = 0
        toast.LayoutOrder = 1000 -- pushed to bottom initially
        toast.ZIndex = Theme.ZIndex.Toast + 1
        toast.Parent = frame

        -- UICorner - rounded-lg (16px)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, Theme.CornerRadius.LG)
        corner.Parent = toast

        -- UIStroke - border-neutral-800
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Colors.BorderDefault
        stroke.Thickness = 1
        stroke.Transparency = 0
        stroke.Parent = toast

        -- UIPadding - padding 16px(32px)
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, Theme.Spacing.XXL)   -- 32px
        padding.PaddingRight = UDim.new(0, Theme.Spacing.XXL)
        padding.PaddingTop = UDim.new(0, Theme.Spacing.XXL)
        padding.PaddingBottom = UDim.new(0, Theme.Spacing.XXL)
        padding.Parent = toast

        -- Inner horizontal layout
        local innerLayout = Instance.new("UIListLayout")
        innerLayout.FillDirection = Enum.FillDirection.Horizontal
        innerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
        innerLayout.Padding = UDim.new(0, Theme.Spacing.LG) -- 20px gap (2.5 * 2)
        innerLayout.Parent = toast

        -- Colored dot indicator (w-1.5/3px, h-1.5/3px -> scaled to 24px diameter)
        local dot = Instance.new("Frame")
        dot.Name = "IndicatorDot"
        dot.Size = UDim2.new(0, 24, 0, 24) -- 12px web * 2
        dot.BackgroundColor3 = TOAST_DOT_COLORS[toastType] or TOAST_DOT_COLORS.success
        dot.BackgroundTransparency = 0
        dot.BorderSizePixel = 0
        dot.LayoutOrder = 1
        dot.ZIndex = Theme.ZIndex.Toast + 2
        dot.Parent = toast

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0) -- rounded-full
        dotCorner.Parent = dot

        -- Message text (text-[12px]/24px, text-neutral-300)
        local msgLabel = Instance.new("TextLabel")
        msgLabel.Name = "Message"
        msgLabel.Size = UDim2.new(0, 0, 0, 0)
        msgLabel.AutomaticSize = Enum.AutomaticSize.XY
        msgLabel.BackgroundTransparency = 1
        msgLabel.Text = message
        msgLabel.TextColor3 = Theme.Colors.TextSecondary -- neutral-300
        msgLabel.TextSize = Theme.FontSize.Small -- 24px (text-[12px]/24px)
        msgLabel.Font = Theme.Font.FamilyMedium
        msgLabel.TextXAlignment = Enum.TextXAlignment.Left
        msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
        msgLabel.LayoutOrder = 2
        msgLabel.ZIndex = Theme.ZIndex.Toast + 2
        msgLabel.Parent = toast

        return toast
    end

    ---------------------------------------------------------------------------
    -- Dismiss a toast with exit animation
    ---------------------------------------------------------------------------
    local function dismissToast(toastEntry)
        if toastEntry.dismissed then return end
        toastEntry.dismissed = true

        local toastFrame = toastEntry.frame
        if not toastFrame or not toastFrame.Parent then return end

        -- Cancel auto-dismiss
        if toastEntry.dismissDelay then
            toastEntry.dismissDelay = nil
        end

        -- Exit animation: opacity 0, x: 40px, scale 0.95
        local tweenInfo = TweenInfo.new(EXIT_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(toastFrame, tweenInfo, {
            BackgroundTransparency = 1,
            Position = UDim2.new(
                toastFrame.Position.X.Scale,
                toastFrame.Position.X.Offset + 40,
                toastFrame.Position.Y.Scale,
                toastFrame.Position.Y.Offset
            ),
        }):Play()

        -- Fade text
        local msgLabel = toastFrame:FindFirstChild("Message")
        if msgLabel then
            TweenService:Create(msgLabel, tweenInfo, {
                TextTransparency = 1
            }):Play()
        end

        -- Fade dot
        local dot = toastFrame:FindFirstChild("IndicatorDot")
        if dot then
            TweenService:Create(dot, tweenInfo, {
                BackgroundTransparency = 1
            }):Play()
        end

        -- Fade stroke
        local stroke = toastFrame:FindFirstChildOfClass("UIStroke")
        if stroke then
            TweenService:Create(stroke, tweenInfo, {
                Transparency = 1
            }):Play()
        end

        spawn(function()
            wait(EXIT_DURATION)
            if toastFrame and toastFrame.Parent then
                toastFrame:Destroy()
            end
        end)
    end

    ---------------------------------------------------------------------------
    -- Remove oldest toast if exceeding max
    ---------------------------------------------------------------------------
    local function enforceMaxToasts()
        while #self._activeToasts > MAX_VISIBLE_TOASTS do
            local oldest = table.remove(self._activeToasts, 1)
            dismissToast(oldest)
        end
    end

    ---------------------------------------------------------------------------
    -- Show a new toast
    ---------------------------------------------------------------------------
    function self.show(message, toastType)
        toastType = toastType or "success"

        local toastId = tostring(tick()) .. "_" .. math.random(10000, 99999)

        local toastFrame = createToastElement(toastId, message, toastType)

        -- Initial state for enter animation
        toastFrame.BackgroundTransparency = 1
        toastFrame.Position = UDim2.new(
            toastFrame.Position.X.Scale,
            toastFrame.Position.X.Offset + 40,
            toastFrame.Position.Y.Scale,
            toastFrame.Position.Y.Offset
        )

        -- Set text initially transparent
        local msgLabel = toastFrame:FindFirstChild("Message")
        if msgLabel then msgLabel.TextTransparency = 1 end
        local dot = toastFrame:FindFirstChild("IndicatorDot")
        if dot then dot.BackgroundTransparency = 1 end
        local stroke = toastFrame:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Transparency = 1 end

        -- Enter animation: opacity 0 -> 1, x: 40px -> 0, scale 0.95 -> 1
        local enterTweenInfo = TweenInfo.new(ENTER_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(toastFrame, enterTweenInfo, {
            BackgroundTransparency = 0.1,
            Position = UDim2.new(
                toastFrame.Position.X.Scale,
                toastFrame.Position.X.Offset - 40,
                toastFrame.Position.Y.Scale,
                toastFrame.Position.Y.Offset
            ),
        }):Play()

        if msgLabel then
            TweenService:Create(msgLabel, enterTweenInfo, { TextTransparency = 0 }):Play()
        end
        if dot then
            TweenService:Create(dot, enterTweenInfo, { BackgroundTransparency = 0 }):Play()
        end
        if stroke then
            TweenService:Create(stroke, enterTweenInfo, { Transparency = 0 }):Play()
        end

        local toastEntry = {
            id = toastId,
            frame = toastFrame,
            dismissed = false,
        }

        -- Click to dismiss
        table.insert(self._connections, toastFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dismissToast(toastEntry)
            end
        end))

        table.insert(self._activeToasts, toastEntry)

        -- Auto-dismiss after 3 seconds
        spawn(function()
            wait(AUTO_DISMISS_TIME)
            if not toastEntry.dismissed then
                dismissToast(toastEntry)
            end
        end)

        -- Enforce max toasts
        enforceMaxToasts()
    end

    ---------------------------------------------------------------------------
    -- Listen to store toast events
    ---------------------------------------------------------------------------
    table.insert(self._connections, store:on("toastAdded", function(message, toastType)
        self.show(message, toastType)
    end))

    ---------------------------------------------------------------------------
    -- Destroy
    ---------------------------------------------------------------------------
    function self.destroy()
        -- Dismiss all active toasts
        for _, toastEntry in ipairs(self._activeToasts) do
            if not toastEntry.dismissed then
                toastEntry.dismissed = true
                if toastEntry.frame and toastEntry.frame.Parent then
                    toastEntry.frame:Destroy()
                end
            end
        end
        self._activeToasts = {}

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

    self.frame = frame

    return self
end

return ToastSystem
