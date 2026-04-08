-- TweenHelper.lua - Tween utilities for consistent animations
-- Provides a clean API for creating smooth, consistent tweens
-- across the The-Blur SurfaceGUI application

local TweenService = game:GetService("TweenService")

local TweenHelper = {}

--------------------------------------------------------------------------------
-- Core tween creation
--------------------------------------------------------------------------------

--- Create a TweenInfo object with defaults
-- @param duration number - Duration in seconds (default 0.25)
-- @param easingStyle Enum.EasingStyle (default Quad)
-- @param easingDirection Enum.EasingDirection (default Out)
-- @param repeatCount number (default 0)
-- @param reverses boolean (default false)
-- @param delay number (default 0)
-- @return TweenInfo
function TweenHelper.info(duration, easingStyle, easingDirection, repeatCount, reverses, delay)
    duration = duration or 0.25
    easingStyle = easingStyle or Enum.EasingStyle.Quad
    easingDirection = easingDirection or Enum.EasingDirection.Out
    repeatCount = repeatCount or 0
    reverses = reverses or false
    delay = delay or 0

    return TweenInfo.new(duration, easingStyle, easingDirection, repeatCount, reverses, delay)
end

--- Create a tween (does not auto-play)
-- @param instance GuiObject - The Roblox instance to tween
-- @param properties table - Property table to tween to
-- @param duration number (default 0.25)
-- @param easingStyle Enum.EasingStyle (default Quad)
-- @param easingDirection Enum.EasingDirection (default Out)
-- @return Tween
function TweenHelper.create(instance, properties, duration, easingStyle, easingDirection)
    duration = duration or 0.25
    easingStyle = easingStyle or Enum.EasingStyle.Quad
    easingDirection = easingDirection or Enum.EasingDirection.Out

    local tweenInfo = TweenInfo.new(
        duration,
        easingStyle,
        easingDirection
    )

    return TweenService:Create(instance, tweenInfo, properties)
end

--- Create and immediately play a tween
-- @param instance GuiObject
-- @param properties table
-- @param duration number (default 0.25)
-- @param easingStyle Enum.EasingStyle (default Quad)
-- @param easingDirection Enum.EasingDirection (default Out)
-- @return Tween
function TweenHelper.play(instance, properties, duration, easingStyle, easingDirection)
    local tween = TweenHelper.create(instance, properties, duration, easingStyle, easingDirection)
    tween:Play()
    return tween
end

--------------------------------------------------------------------------------
-- Spring-like animation (simulates Framer Motion spring)
--------------------------------------------------------------------------------

--- Play a spring-like animation (Back easing approximation)
-- @param instance GuiObject
-- @param properties table - Target properties
-- @param stiffness number (default 400)
-- @param damping number (default 30)
-- @return Tween
function TweenHelper.spring(instance, properties, stiffness, damping)
    stiffness = stiffness or 400
    damping = damping or 30

    -- Roblox doesn't have true spring physics; we approximate with Back easing
    -- Higher stiffness = faster, lower damping = more overshoot
    local overshoot = math.max(0.01, (stiffness / 400) * (1 - damping / 60))
    -- Clamp overshoot to a reasonable range
    overshoot = math.min(overshoot, 0.5)

    local duration = 0.3 + (1 - damping / 60) * 0.2 -- 0.3-0.5s based on damping

    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out,
        0,
        false,
        overshoot
    )

    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

--------------------------------------------------------------------------------
-- Fade animations
--------------------------------------------------------------------------------

--- Fade in (BackgroundTransparency 1 -> 0)
-- @param instance GuiObject
-- @param duration number (default 0.4)
-- @return Tween
function TweenHelper.fadeIn(instance, duration)
    duration = duration or 0.4
    instance.BackgroundTransparency = 1
    return TweenHelper.play(instance, { BackgroundTransparency = 0 }, duration,
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

--- Fade out (BackgroundTransparency 0 -> 1)
-- @param instance GuiObject
-- @param duration number (default 0.4)
-- @return Tween
function TweenHelper.fadeOut(instance, duration)
    duration = duration or 0.4
    return TweenHelper.play(instance, { BackgroundTransparency = 1 }, duration,
        Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

--- Fade text in (TextTransparency 1 -> 0)
-- @param instance TextLabel/TextBox
-- @param duration number (default 0.4)
-- @return Tween
function TweenHelper.fadeTextIn(instance, duration)
    duration = duration or 0.4
    instance.TextTransparency = 1
    return TweenHelper.play(instance, { TextTransparency = 0 }, duration,
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

--- Fade text out (TextTransparency 0 -> 1)
-- @param instance TextLabel/TextBox
-- @param duration number (default 0.4)
-- @return Tween
function TweenHelper.fadeTextOut(instance, duration)
    duration = duration or 0.4
    return TweenHelper.play(instance, { TextTransparency = 1 }, duration,
        Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

--- Fade ImageLabel in (ImageTransparency 1 -> 0)
-- @param instance ImageLabel
-- @param duration number (default 0.4)
-- @return Tween
function TweenHelper.fadeImageIn(instance, duration)
    duration = duration or 0.4
    instance.ImageTransparency = 1
    return TweenHelper.play(instance, { ImageTransparency = 0 }, duration,
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

--- Fade ImageLabel out
-- @param instance ImageLabel
-- @param duration number (default 0.4)
-- @return Tween
function TweenHelper.fadeImageOut(instance, duration)
    duration = duration or 0.4
    return TweenHelper.play(instance, { ImageTransparency = 1 }, duration,
        Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

--- Fade out then destroy the instance
-- @param instance GuiObject
-- @param duration number (default 0.3)
-- @param destroyDelay number (default 0)
-- @return Tween
function TweenHelper.fadeOutAndDestroy(instance, duration, destroyDelay)
    duration = duration or 0.3
    destroyDelay = destroyDelay or 0
    local tween = TweenHelper.fadeOut(instance, duration)
    tween.Completed:Connect(function()
        if destroyDelay > 0 then
            wait(destroyDelay)
        end
        if instance and instance.Parent then
            instance:Destroy()
        end
    end)
    return tween
end

--------------------------------------------------------------------------------
-- Slide animations
--------------------------------------------------------------------------------

--- Slide in from the top (pre-positioned off-screen, tweens to target)
-- @param instance GuiObject
-- @param targetPosition UDim2 - Final position
-- @param offset number - How far off-screen (default 200)
-- @param duration number (default 0.6)
-- @return Tween
function TweenHelper.slideInTop(instance, targetPosition, offset, duration)
    offset = offset or 200
    duration = duration or 0.6

    -- Position off-screen above
    instance.Position = UDim2.new(
        targetPosition.X.Scale,
        targetPosition.X.Offset,
        targetPosition.Y.Scale,
        targetPosition.Y.Offset - offset
    )

    return TweenHelper.play(instance, { Position = targetPosition }, duration,
        Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
end

--- Slide in from the bottom
-- @param instance GuiObject
-- @param targetPosition UDim2
-- @param offset number (default 200)
-- @param duration number (default 0.5)
-- @return Tween
function TweenHelper.slideInBottom(instance, targetPosition, offset, duration)
    offset = offset or 200
    duration = duration or 0.5

    instance.Position = UDim2.new(
        targetPosition.X.Scale,
        targetPosition.X.Offset,
        targetPosition.Y.Scale,
        targetPosition.Y.Offset + offset
    )

    return TweenHelper.play(instance, { Position = targetPosition }, duration,
        Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
end

--- Slide in from the left
-- @param instance GuiObject
-- @param targetPosition UDim2
-- @param offset number (default 200)
-- @param duration number (default 0.5)
-- @return Tween
function TweenHelper.slideInLeft(instance, targetPosition, offset, duration)
    offset = offset or 200
    duration = duration or 0.5

    instance.Position = UDim2.new(
        targetPosition.X.Scale,
        targetPosition.X.Offset - offset,
        targetPosition.Y.Scale,
        targetPosition.Y.Offset
    )

    return TweenHelper.play(instance, { Position = targetPosition }, duration,
        Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
end

--- Slide in from the right
-- @param instance GuiObject
-- @param targetPosition UDim2
-- @param offset number (default 200)
-- @param duration number (default 0.5)
-- @return Tween
function TweenHelper.slideInRight(instance, targetPosition, offset, duration)
    offset = offset or 200
    duration = duration or 0.5

    instance.Position = UDim2.new(
        targetPosition.X.Scale,
        targetPosition.X.Offset + offset,
        targetPosition.Y.Scale,
        targetPosition.Y.Offset
    )

    return TweenHelper.play(instance, { Position = targetPosition }, duration,
        Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
end

--- Slide out to the top
-- @param instance GuiObject
-- @param offset number (default 200)
-- @param duration number (default 0.4)
-- @return Tween
function TweenHelper.slideOutTop(instance, offset, duration)
    offset = offset or 200
    duration = duration or 0.4

    local targetPos = UDim2.new(
        instance.Position.X.Scale,
        instance.Position.X.Offset,
        instance.Position.Y.Scale,
        instance.Position.Y.Offset - offset
    )

    return TweenHelper.play(instance, { Position = targetPos }, duration,
        Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
end

--- Slide out to the bottom
-- @param instance GuiObject
-- @param offset number (default 200)
-- @param duration number (default 0.4)
-- @return Tween
function TweenHelper.slideOutBottom(instance, offset, duration)
    offset = offset or 200
    duration = duration or 0.4

    local targetPos = UDim2.new(
        instance.Position.X.Scale,
        instance.Position.X.Offset,
        instance.Position.Y.Scale,
        instance.Position.Y.Offset + offset
    )

    return TweenHelper.play(instance, { Position = targetPos }, duration,
        Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
end

--------------------------------------------------------------------------------
-- Scale animations
--------------------------------------------------------------------------------

--- Scale to a specific UDim2 size
-- @param instance GuiObject
-- @param targetSize UDim2
-- @param duration number (default 0.2)
-- @param easingStyle Enum.EasingStyle (default Back)
-- @return Tween
function TweenHelper.scaleTo(instance, targetSize, duration, easingStyle)
    duration = duration or 0.2
    easingStyle = easingStyle or Enum.EasingStyle.Back

    -- Ensure center anchoring for uniform scaling
    if instance.AnchorPoint ~= Vector2.new(0.5, 0.5) then
        instance.AnchorPoint = Vector2.new(0.5, 0.5)
    end

    return TweenHelper.play(instance, { Size = targetSize }, duration, easingStyle,
        Enum.EasingDirection.Out)
end

--- Scale from zero (pop-in effect)
-- @param instance GuiObject
-- @param targetSize UDim2
-- @param duration number (default 0.3)
-- @return Tween
function TweenHelper.scaleIn(instance, targetSize, duration)
    duration = duration or 0.3

    instance.AnchorPoint = Vector2.new(0.5, 0.5)
    instance.Size = UDim2.new(0, 0, 0, 0)

    return TweenHelper.play(instance, { Size = targetSize }, duration,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

--- Scale to zero (pop-out effect)
-- @param instance GuiObject
-- @param duration number (default 0.2)
-- @return Tween
function TweenHelper.scaleOut(instance, duration)
    duration = duration or 0.2

    return TweenHelper.play(instance, { Size = UDim2.new(0, 0, 0, 0) }, duration,
        Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

--- Scale to zero then destroy
-- @param instance GuiObject
-- @param duration number (default 0.2)
-- @return Tween
function TweenHelper.scaleOutAndDestroy(instance, duration)
    duration = duration or 0.2
    local tween = TweenHelper.scaleOut(instance, duration)
    tween.Completed:Connect(function()
        if instance and instance.Parent then
            instance:Destroy()
        end
    end)
    return tween
end

--------------------------------------------------------------------------------
-- Hover and press effects
--------------------------------------------------------------------------------

--- Hover scale effect (slightly enlarge)
-- @param instance GuiObject
-- @param targetScale number (default 1.05)
-- @param duration number (default 0.15)
-- @return Tween
function TweenHelper.hoverScale(instance, targetScale, duration)
    targetScale = targetScale or 1.05
    duration = duration or 0.15

    local currentSize = instance.Size
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    -- Ensure center anchoring for uniform scaling
    if instance.AnchorPoint ~= Vector2.new(0.5, 0.5) then
        instance.AnchorPoint = Vector2.new(0.5, 0.5)
    end

    local newWidth = currentSize.X.Offset * targetScale
    local newHeight = currentSize.Y.Offset * targetScale

    local tween = TweenService:Create(instance, tweenInfo, {
        Size = UDim2.new(currentSize.X.Scale, newWidth, currentSize.Y.Scale, newHeight)
    })
    tween:Play()
    return tween
end

--- Un-hover scale (return to original size)
-- @param instance GuiObject
-- @param originalSize UDim2
-- @param duration number (default 0.1)
-- @return Tween
function TweenHelper.unhoverScale(instance, originalSize, duration)
    duration = duration or 0.1

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local tween = TweenService:Create(instance, tweenInfo, {
        Size = originalSize
    })
    tween:Play()
    return tween
end

--- Press scale effect (shrink then return to original)
-- @param instance GuiObject
-- @param pressScale number (default 0.95)
-- @param duration number (default 0.1)
-- @return Tween
function TweenHelper.pressScale(instance, pressScale, duration)
    pressScale = pressScale or 0.95
    duration = duration or 0.1

    local currentSize = instance.Size
    if instance.AnchorPoint ~= Vector2.new(0.5, 0.5) then
        instance.AnchorPoint = Vector2.new(0.5, 0.5)
    end

    local smallWidth = currentSize.X.Offset * pressScale
    local smallHeight = currentSize.Y.Offset * pressScale

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, {
        Size = UDim2.new(currentSize.X.Scale, smallWidth, currentSize.Y.Scale, smallHeight)
    })
    tween:Play()
    tween.Completed:Connect(function()
        TweenService:Create(instance, tweenInfo, {
            Size = currentSize
        }):Play()
    end)
    return tween
end

--------------------------------------------------------------------------------
-- Looping animations
--------------------------------------------------------------------------------

--- Pulse animation (oscillates a property back and forth, loops infinitely)
-- @param instance GuiObject
-- @param property string - Property name (e.g., "BackgroundTransparency")
-- @param from any - Start value
-- @param to any - End value
-- @param duration number (default 1.5)
-- @return Tween
function TweenHelper.pulse(instance, property, from, to, duration)
    duration = duration or 1.5
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0)
    local tween = TweenService:Create(instance, tweenInfo, { [property] = to })

    -- Set initial value
    if from ~= nil then
        instance[property] = from
    end

    tween:Play()
    return tween
end

--- Blink animation (BackgroundTransparency pulsing)
-- @param instance GuiObject
-- @param duration number (default 1.5)
-- @return Tween
function TweenHelper.blink(instance, duration)
    duration = duration or 1.5
    return TweenHelper.pulse(instance, "BackgroundTransparency", 0, 1, duration)
end

--- Text blink animation (TextTransparency pulsing)
-- @param instance TextLabel/TextBox
-- @param duration number (default 1.5)
-- @return Tween
function TweenHelper.textBlink(instance, duration)
    duration = duration or 1.5
    return TweenHelper.pulse(instance, "TextTransparency", 0, 1, duration)
end

--- Color pulse animation (BackgroundColor3 oscillation)
-- @param instance GuiObject
-- @param color1 Color3
-- @param color2 Color3
-- @param duration number (default 1.5)
-- @return Tween
function TweenHelper.colorPulse(instance, color1, color2, duration)
    duration = duration or 1.5
    instance.BackgroundColor3 = color1
    return TweenHelper.pulse(instance, "BackgroundColor3", color1, color2, duration)
end

--- Size pulse animation (slight breathing effect)
-- @param instance GuiObject
-- @param scaleFrom number (default 1.0)
-- @param scaleTo number (default 1.05)
-- @param duration number (default 1.5)
-- @return Tween
function TweenHelper.sizePulse(instance, scaleFrom, scaleTo, duration)
    scaleFrom = scaleFrom or 1.0
    scaleTo = scaleTo or 1.05
    duration = duration or 1.5

    if instance.AnchorPoint ~= Vector2.new(0.5, 0.5) then
        instance.AnchorPoint = Vector2.new(0.5, 0.5)
    end

    local baseSize = instance.Size
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0)

    local tween = TweenService:Create(instance, tweenInfo, {
        Size = UDim2.new(
            baseSize.X.Scale,
            baseSize.X.Offset * scaleTo,
            baseSize.Y.Scale,
            baseSize.Y.Offset * scaleTo
        )
    })
    tween:Play()
    return tween
end

--------------------------------------------------------------------------------
-- Sequential and parallel tween control
--------------------------------------------------------------------------------

--- Chain multiple tweens to play sequentially
-- @param tweens table - Array of Tween objects (first one auto-plays)
-- @return table - The same array of tweens
function TweenHelper.chain(tweens)
    if #tweens == 0 then return tweens end

    for i = 1, #tweens - 1 do
        tweens[i].Completed:Connect(function()
            if tweens[i + 1] then
                tweens[i + 1]:Play()
            end
        end)
    end

    tweens[1]:Play()
    return tweens
end

--- Play multiple tweens in parallel
-- @param tweens table - Array of Tween objects (all auto-play)
-- @return table
function TweenHelper.parallel(tweens)
    for _, tween in ipairs(tweens) do
        tween:Play()
    end
    return tweens
end

--- Play a tween and call a callback when complete
-- @param instance GuiObject
-- @param properties table
-- @param callback function
-- @param duration number (default 0.25)
-- @return Tween
function TweenHelper.playAndCall(instance, properties, callback, duration)
    duration = duration or 0.25
    local tween = TweenHelper.play(instance, properties, duration)
    if callback then
        tween.Completed:Connect(callback)
    end
    return tween
end

--------------------------------------------------------------------------------
-- Delayed execution
--------------------------------------------------------------------------------

--- Execute a function after a delay (non-blocking)
-- @param delay number - Seconds to wait
-- @param callback function
function TweenHelper.delayed(delay, callback)
    spawn(function()
        wait(delay)
        callback()
    end)
end

--- Execute a function on the next frame
-- @param callback function
function TweenHelper.nextFrame(callback)
    spawn(function()
        wait(0) -- Yields to next frame via spawn
        callback()
    end)
end

--------------------------------------------------------------------------------
-- Utility: Cancel all tweens on an instance
--------------------------------------------------------------------------------

--- Cancel all active tweens on an instance
-- @param instance GuiObject
function TweenHelper.cancelAll(instance)
    TweenService:Create(instance, TweenInfo.new(0), {}):Cancel()
end

--- Check if an instance currently has active tweens
-- Note: Roblox doesn't provide a direct API for this, so this is a best-effort check
-- @param instance GuiObject
-- @return boolean - Always returns false (no native API; track manually if needed)
function TweenHelper.isPlaying(instance)
    -- Roblox doesn't expose a way to check this directly
    return false
end

return TweenHelper
