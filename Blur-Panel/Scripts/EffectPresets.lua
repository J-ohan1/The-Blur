-- EffectPresets.lua - 35 built-in laser effects in 5 categories
-- Each effect has a frame generator that produces beam position data
-- Beam count default is 15 (matching the website's beam editor)
-- Used by the EffectPanel and EffectEditor components

local EffectPresets = {}

--------------------------------------------------------------------------------
-- Category definitions (5 categories, 7 effects each = 35 total)
--------------------------------------------------------------------------------
local categories = {
    { id = "waves",    name = "Waves",    icon = "〰", description = "Smooth oscillating beam patterns" },
    { id = "chase",    name = "Chase",    icon = "›", description = "Sequential beam chase effects" },
    { id = "pattern",  name = "Pattern",  icon = "◇", description = "Geometric shape formations" },
    { id = "color",    name = "Color",    icon = "●", description = "Color gradient and strobe effects" },
    { id = "advanced", name = "Advanced", icon = "★", description = "Complex parametric beam shapes" },
}

--------------------------------------------------------------------------------
-- Frame generation utilities
--------------------------------------------------------------------------------

--- Generate a frame with default beam values, then apply a generator function
-- @param generatorFn function|nil - Function(beams, beamCount) to customize beam positions
-- @param beamCount number (default 15)
-- @return table - Array of beam tables
local function generateFrame(generatorFn, beamCount)
    beamCount = beamCount or 15
    local beams = {}
    for i = 1, beamCount do
        beams[i] = {
            id = i,
            x = 50,           -- percentage (0-100)
            y = 50,           -- percentage (0-100)
            iris = 255,       -- 0-255
            dimmer = 255,     -- 0-255
            hue = 0,          -- 0-360
            saturation = 0,   -- 0-1
            brightness = 1,   -- 0-1
            visible = true,
        }
    end
    if generatorFn then
        generatorFn(beams, beamCount)
    end
    return beams
end

--- Generate multi-frame animation from a generator
-- @param frameCount number - Number of frames
-- @param generatorFn function(frameIndex, beams, beamCount, frameCount)
-- @param beamCount number (default 15)
-- @return table - Array of frame tables
local function generateMultiFrame(frameCount, generatorFn, beamCount)
    beamCount = beamCount or 15
    local frames = {}
    for f = 1, frameCount do
        local beams = {}
        for i = 1, beamCount do
            beams[i] = {
                id = i,
                x = 50, y = 50,
                iris = 255, dimmer = 255,
                hue = 0, saturation = 0, brightness = 1,
                visible = true,
            }
        end
        if generatorFn then
            generatorFn(f, beams, beamCount, frameCount)
        end
        frames[f] = beams
    end
    return frames
end

--------------------------------------------------------------------------------
-- Effect Presets (35 total: 7 per category)
--------------------------------------------------------------------------------
local presets = {

    ==========================================================================
    -- WAVES (7 effects)
    ==========================================================================

    {
        id = "wave_1",
        name = "Sine Wave",
        category = "waves",
        description = "Classic sinusoidal wave pattern",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = t * 100
                    beams[i].y = 50 + math.sin(t * math.pi * 2) * 30
                end
            end, beamCount)
        end,
    },

    {
        id = "wave_2",
        name = "Cosine Wave",
        category = "waves",
        description = "Phase-shifted cosine wave",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = t * 100
                    beams[i].y = 50 + math.cos(t * math.pi * 2) * 30
                end
            end, beamCount)
        end,
    },

    {
        id = "wave_3",
        name = "Sawtooth",
        category = "waves",
        description = "Sharp sawtooth ramp pattern",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = t * 100
                    beams[i].y = 20 + (t * 3 % 1) * 60
                end
            end, beamCount)
        end,
    },

    {
        id = "wave_4",
        name = "Triangle Wave",
        category = "waves",
        description = "Linear triangle oscillation",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    local tri = 1 - math.abs(2 * ((t * 2) % 1) - 1)
                    beams[i].x = t * 100
                    beams[i].y = 20 + tri * 60
                end
            end, beamCount)
        end,
    },

    {
        id = "wave_5",
        name = "Ripple",
        category = "waves",
        description = "Circular ripple emanating from center",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = 50 + math.cos(t * math.pi * 2) * 35
                    beams[i].y = 50 + math.sin(t * math.pi * 2) * 35
                end
            end, beamCount)
        end,
    },

    {
        id = "wave_6",
        name = "Helix",
        category = "waves",
        description = "3D helix projection with dimming",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = 20 + t * 60
                    beams[i].y = 50 + math.sin(t * math.pi * 4) * 20
                    beams[i].dimmer = math.floor(128 + math.cos(t * math.pi * 2) * 127)
                end
            end, beamCount)
        end,
    },

    {
        id = "wave_7",
        name = "Breathing",
        category = "waves",
        description = "All beams converge and pulse at center",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    beams[i].x = 50
                    beams[i].y = 50
                    beams[i].iris = math.floor(50 + math.sin(0) * 100)
                    beams[i].dimmer = 200
                end
            end, beamCount)
        end,
    },

    ==========================================================================
    -- CHASE (7 effects)
    ==========================================================================

    {
        id = "chase_1",
        name = "Linear Chase",
        category = "chase",
        description = "Beams chase left to right in a line",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = t * 100
                    beams[i].y = 50
                    beams[i].dimmer = (i == 1) and 255 or 50
                end
            end, beamCount)
        end,
    },

    {
        id = "chase_2",
        name = "Circle Chase",
        category = "chase",
        description = "Single bright beam chases around a circle",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    local angle = t * math.pi * 2
                    beams[i].x = 50 + math.cos(angle) * 35
                    beams[i].y = 50 + math.sin(angle) * 35
                    beams[i].dimmer = (i == 1) and 255 or 50
                end
            end, beamCount)
        end,
    },

    {
        id = "chase_3",
        name = "Random Chase",
        category = "chase",
        description = "Beams at random positions with one highlighted",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                math.randomseed(42) -- Deterministic for consistency
                for i = 1, n do
                    beams[i].x = math.random(10, 90)
                    beams[i].y = math.random(10, 90)
                    beams[i].dimmer = 80
                end
                beams[1].dimmer = 255
                math.randomseed(tick()) -- Reset seed
            end, beamCount)
        end,
    },

    {
        id = "chase_4",
        name = "Bounce",
        category = "chase",
        description = "Beams follow a parabolic bounce arc",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = t * 100
                    beams[i].y = math.abs(math.sin(t * math.pi)) * 80 + 10
                end
            end, beamCount)
        end,
    },

    {
        id = "chase_5",
        name = "Ping Pong",
        category = "chase",
        description = "Beams oscillate back and forth horizontally",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    local pingpong = t <= 0.5 and t * 2 or 2 - t * 2
                    beams[i].x = pingpong * 100
                    beams[i].y = 50
                end
            end, beamCount)
        end,
    },

    {
        id = "chase_6",
        name = "Zigzag",
        category = "chase",
        description = "Beams zigzag across rows",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    local row = math.floor(t * 4)
                    local col = (t * 4) % 1
                    beams[i].x = (row % 2 == 0) and (col * 100) or ((1 - col) * 100)
                    beams[i].y = row * 20 + 10
                end
            end, beamCount)
        end,
    },

    {
        id = "chase_7",
        name = "Cascade",
        category = "chase",
        description = "Beams cascade diagonally with fading dimmer",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = t * 100
                    beams[i].y = t * 80 + 10
                    beams[i].dimmer = math.floor(255 - t * 200)
                end
            end, beamCount)
        end,
    },

    ==========================================================================
    -- PATTERN (7 effects)
    ==========================================================================

    {
        id = "pat_1",
        name = "Cross",
        category = "pattern",
        description = "Beams form a cross/plus pattern",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                local mid = math.ceil(n / 2)
                for i = 1, n do
                    beams[i].x = 50
                    beams[i].y = 50
                    if i <= mid then
                        beams[i].x = 10 + (i / mid) * 80
                    else
                        beams[i].y = 10 + ((i - mid) / math.max(1, n - mid)) * 80
                    end
                end
            end, beamCount)
        end,
    },

    {
        id = "pat_2",
        name = "Diamond",
        category = "pattern",
        description = "Beams arranged in a diamond shape",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    local angle = t * math.pi * 2
                    -- Diamond: alternate between inner and outer radius
                    local r = (i <= n / 2) and 35 or 20
                    beams[i].x = 50 + math.cos(angle + math.pi / 4) * r
                    beams[i].y = 50 + math.sin(angle + math.pi / 4) * r
                end
            end, beamCount)
        end,
    },

    {
        id = "pat_3",
        name = "Grid",
        category = "pattern",
        description = "Beams arranged in a rectangular grid",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                local cols = 5
                local rows = math.ceil(n / cols)
                for i = 1, n do
                    local row = math.ceil(i / cols)
                    local col = ((i - 1) % cols) + 1
                    beams[i].x = (col / (cols + 1)) * 100
                    beams[i].y = (row / (rows + 1)) * 100
                end
            end, beamCount)
        end,
    },

    {
        id = "pat_4",
        name = "Circle",
        category = "pattern",
        description = "Beams evenly distributed around a circle",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local angle = ((i - 1) / n) * math.pi * 2 - math.pi / 2
                    beams[i].x = 50 + math.cos(angle) * 35
                    beams[i].y = 50 + math.sin(angle) * 35
                end
            end, beamCount)
        end,
    },

    {
        id = "pat_5",
        name = "Star",
        category = "pattern",
        description = "Beams alternate between inner and outer points to form a star",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local angle = ((i - 1) / n) * math.pi * 2 - math.pi / 2
                    local r = (i % 2 == 1) and 35 or 15
                    beams[i].x = 50 + math.cos(angle) * r
                    beams[i].y = 50 + math.sin(angle) * r
                end
            end, beamCount)
        end,
    },

    {
        id = "pat_6",
        name = "Spiral",
        category = "pattern",
        description = "Beams spiral outward from center",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    local angle = t * math.pi * 4
                    local r = 5 + t * 30
                    beams[i].x = 50 + math.cos(angle) * r
                    beams[i].y = 50 + math.sin(angle) * r
                end
            end, beamCount)
        end,
    },

    {
        id = "pat_7",
        name = "Fan",
        category = "pattern",
        description = "Beams spread out in a fan pattern",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    local angle = -math.pi / 3 + t * (2 * math.pi / 3)
                    beams[i].x = 50 + math.cos(angle - math.pi / 2) * 35
                    beams[i].y = 50 + math.sin(angle - math.pi / 2) * 35
                end
            end, beamCount)
        end,
    },

    ==========================================================================
    -- COLOR (7 effects)
    ==========================================================================

    {
        id = "col_1",
        name = "Rainbow",
        category = "color",
        description = "Full rainbow hue gradient across beams",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = t * 100
                    beams[i].y = 50
                    beams[i].hue = t * 360
                    beams[i].saturation = 1
                    beams[i].brightness = 1
                end
            end, beamCount)
        end,
    },

    {
        id = "col_2",
        name = "Warm Gradient",
        category = "color",
        description = "Red to yellow warm color gradient",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = t * 100
                    beams[i].y = 50
                    beams[i].hue = t * 60 -- 0 (red) to 60 (yellow)
                    beams[i].saturation = 1
                    beams[i].brightness = 1
                end
            end, beamCount)
        end,
    },

    {
        id = "col_3",
        name = "Cool Gradient",
        category = "color",
        description = "Cyan to blue cool color gradient",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = t * 100
                    beams[i].y = 50
                    beams[i].hue = 180 + t * 60 -- 180 (cyan) to 240 (blue)
                    beams[i].saturation = 1
                    beams[i].brightness = 1
                end
            end, beamCount)
        end,
    },

    {
        id = "col_4",
        name = "Neon",
        category = "color",
        description = "Alternating neon pink and green beams",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = t * 100
                    beams[i].y = 50
                    beams[i].hue = (i % 2 == 0) and 300 or 120 -- magenta / green
                    beams[i].saturation = 1
                    beams[i].brightness = 1
                end
            end, beamCount)
        end,
    },

    {
        id = "col_5",
        name = "Pastel",
        category = "color",
        description = "Soft pastel rainbow with reduced saturation",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = t * 100
                    beams[i].y = 50
                    beams[i].hue = t * 360
                    beams[i].saturation = 0.4
                    beams[i].brightness = 1
                end
            end, beamCount)
        end,
    },

    {
        id = "col_6",
        name = "Monochrome",
        category = "color",
        description = "White to dark gradient with no saturation",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    beams[i].x = t * 100
                    beams[i].y = 50
                    beams[i].brightness = 1 - t * 0.8
                    beams[i].saturation = 0
                end
            end, beamCount)
        end,
    },

    {
        id = "col_7",
        name = "Strobe Colors",
        category = "color",
        description = "Alternating colored and dark beams for strobe effect",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    beams[i].x = 50 + ((i - 1) / math.max(1, n - 1)) * 40 - 20
                    beams[i].y = 50
                    beams[i].hue = (i * 50) % 360
                    beams[i].saturation = 1
                    beams[i].brightness = (i % 2 == 0) and 1 or 0
                    beams[i].dimmer = (i % 2 == 0) and 255 or 20
                end
            end, beamCount)
        end,
    },

    ==========================================================================
    -- ADVANCED (7 effects)
    ==========================================================================

    {
        id = "adv_1",
        name = "V-Spread",
        category = "advanced",
        description = "Beams spread outward in a V formation",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    -- V shape: starts at top, spreads down and outward
                    local spread = math.abs(t - 0.5) * 2
                    beams[i].x = 10 + t * 80
                    beams[i].y = 15 + spread * 70
                end
            end, beamCount)
        end,
    },

    {
        id = "adv_2",
        name = "Random Scatter",
        category = "advanced",
        description = "Beams randomly scattered across the field",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                math.randomseed(42) -- Deterministic for consistency
                for i = 1, n do
                    beams[i].x = math.random(10, 90)
                    beams[i].y = math.random(10, 90)
                    beams[i].hue = math.random(0, 360)
                    beams[i].saturation = 0.8
                end
                math.randomseed(tick()) -- Reset seed
            end, beamCount)
        end,
    },

    {
        id = "adv_3",
        name = "Converge",
        category = "advanced",
        description = "Beams converge toward center point",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    local fromCenter = math.abs(t - 0.5) * 2
                    beams[i].x = 20 + t * 60
                    beams[i].y = 50 + (1 - fromCenter) * 20
                    beams[i].dimmer = math.floor(100 + (1 - fromCenter) * 155)
                end
            end, beamCount)
        end,
    },

    {
        id = "adv_4",
        name = "DNA Helix",
        category = "advanced",
        description = "Double helix pattern with alternating brightness",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    local angle = t * math.pi * 4
                    beams[i].x = 50 + math.cos(angle) * 25
                    beams[i].y = t * 100
                    beams[i].dimmer = math.floor(128 + math.sin(angle) * 127)
                    beams[i].hue = (i % 2 == 0) and 180 or 300
                    beams[i].saturation = 0.8
                end
            end, beamCount)
        end,
    },

    {
        id = "adv_5",
        name = "Infinity",
        category = "advanced",
        description = "Beams trace an infinity/lemniscate curve",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    local angle = t * math.pi * 2
                    -- Lemniscate of Bernoulli parametric equations
                    local denom = 1 + math.sin(angle) * math.sin(angle)
                    beams[i].x = 50 + math.cos(angle) * 30 / denom
                    beams[i].y = 50 + math.sin(angle) * math.cos(angle) * 30 / denom
                end
            end, beamCount)
        end,
    },

    {
        id = "adv_6",
        name = "Explosion",
        category = "advanced",
        description = "Beams radiate outward from center like an explosion",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                math.randomseed(42)
                for i = 1, n do
                    local angle = ((i - 1) / n) * math.pi * 2
                    local r = 15 + math.random(0, 20)
                    beams[i].x = 50 + math.cos(angle) * r
                    beams[i].y = 50 + math.sin(angle) * r
                    beams[i].dimmer = math.random(100, 255)
                    beams[i].hue = math.random(0, 60) -- Red-orange-yellow range
                    beams[i].saturation = 1
                end
                math.randomseed(tick())
            end, beamCount)
        end,
    },

    {
        id = "adv_7",
        name = "Heart",
        category = "advanced",
        description = "Beams trace a heart shape curve",
        generate = function(beamCount)
            return generateFrame(function(beams, n)
                for i = 1, n do
                    local t = (i - 1) / math.max(1, n - 1)
                    local angle = t * math.pi * 2
                    -- Heart curve parametric equations
                    local hx = 16 * math.sin(angle) ^ 3
                    local hy = 13 * math.cos(angle) - 5 * math.cos(2 * angle)
                        - 2 * math.cos(3 * angle) - math.cos(4 * angle)
                    beams[i].x = 50 + (hx / 17) * 30
                    beams[i].y = 50 - (hy / 17) * 30
                    beams[i].hue = 350 + t * 20 -- Red range
                    beams[i].saturation = 0.9
                end
            end, beamCount)
        end,
    },
}

--------------------------------------------------------------------------------
-- Multi-frame animation generators
-- These produce arrays of frames for animated effects
--------------------------------------------------------------------------------

--- Generate a sine wave animation (beam positions shift over time)
-- @param frameCount number (default 24)
-- @param beamCount number (default 15)
-- @return table - Array of frame tables
function EffectPresets.generateSineWaveAnimation(frameCount, beamCount)
    return generateMultiFrame(frameCount, function(frameIndex, beams, n, totalFrames)
        local phase = (frameIndex - 1) / totalFrames * math.pi * 2
        for i = 1, n do
            local t = (i - 1) / math.max(1, n - 1)
            beams[i].x = t * 100
            beams[i].y = 50 + math.sin(t * math.pi * 2 + phase) * 30
        end
    end, beamCount)
end

--- Generate a circle chase animation
-- @param frameCount number (default 15)
-- @param beamCount number (default 15)
-- @return table
function EffectPresets.generateCircleChaseAnimation(frameCount, beamCount)
    return generateMultiFrame(frameCount, function(frameIndex, beams, n, totalFrames)
        local highlightIndex = math.floor(((frameIndex - 1) / totalFrames) * n) + 1
        for i = 1, n do
            local angle = ((i - 1) / n) * math.pi * 2
            beams[i].x = 50 + math.cos(angle) * 35
            beams[i].y = 50 + math.sin(angle) * 35
            beams[i].dimmer = (i == highlightIndex) and 255 or 50
        end
    end, beamCount)
end

--- Generate a spiral animation (rotating spiral over time)
-- @param frameCount number (default 24)
-- @param beamCount number (default 15)
-- @return table
function EffectPresets.generateSpiralAnimation(frameCount, beamCount)
    return generateMultiFrame(frameCount, function(frameIndex, beams, n, totalFrames)
        local rotationOffset = (frameIndex - 1) / totalFrames * math.pi * 2
        for i = 1, n do
            local t = (i - 1) / math.max(1, n - 1)
            local angle = t * math.pi * 4 + rotationOffset
            local r = 5 + t * 30
            beams[i].x = 50 + math.cos(angle) * r
            beams[i].y = 50 + math.sin(angle) * r
        end
    end, beamCount)
end

--- Generate a rainbow sweep animation
-- @param frameCount number (default 24)
-- @param beamCount number (default 15)
-- @return table
function EffectPresets.generateRainbowSweepAnimation(frameCount, beamCount)
    return generateMultiFrame(frameCount, function(frameIndex, beams, n, totalFrames)
        local hueOffset = (frameIndex - 1) / totalFrames * 360
        for i = 1, n do
            local t = (i - 1) / math.max(1, n - 1)
            beams[i].x = t * 100
            beams[i].y = 50
            beams[i].hue = (t * 360 + hueOffset) % 360
            beams[i].saturation = 1
            beams[i].brightness = 1
        end
    end, beamCount)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Get all effect categories
-- @return table - Array of category tables
function EffectPresets.getCategories()
    return categories
end

--- Get a category by ID
-- @param categoryId string
-- @return table|nil
function EffectPresets.getCategoryById(categoryId)
    for _, cat in ipairs(categories) do
        if cat.id == categoryId then
            return cat
        end
    end
    return nil
end

--- Get all presets
-- @return table - Array of all preset tables
function EffectPresets.getAll()
    return presets
end

--- Get presets filtered by category
-- @param categoryId string
-- @return table - Array of matching preset tables
function EffectPresets.getByCategory(categoryId)
    local result = {}
    for _, preset in ipairs(presets) do
        if preset.category == categoryId then
            table.insert(result, preset)
        end
    end
    return result
end

--- Get a preset by its ID
-- @param presetId string
-- @return table|nil
function EffectPresets.getById(presetId)
    for _, preset in ipairs(presets) do
        if preset.id == presetId then
            return preset
        end
    end
    return nil
end

--- Search presets by name (case-insensitive)
-- @param query string
-- @return table - Array of matching presets
function EffectPresets.search(query)
    if not query or #query == 0 then
        return presets
    end
    local queryLower = query:lower()
    local result = {}
    for _, preset in ipairs(presets) do
        if preset.name:lower():find(queryLower, 1, true) then
            table.insert(result, preset)
        end
    end
    return result
end

--- Generate a single frame for a preset
-- @param presetId string
-- @param beamCount number (default 15)
-- @return table|nil - Array of beam tables, or nil if preset not found
function EffectPresets.generateFrame(presetId, beamCount)
    local preset = EffectPresets.getById(presetId)
    if preset and preset.generate then
        return preset.generate(beamCount or 15)
    end
    return nil
end

--- Get total preset count
-- @return number
function EffectPresets.getCount()
    return #presets
end

--- Get preset count per category
-- @return table - Map of categoryId -> count
function EffectPresets.getCountByCategory()
    local counts = {}
    for _, cat in ipairs(categories) do
        counts[cat.id] = 0
    end
    for _, preset in ipairs(presets) do
        if counts[preset.category] then
            counts[preset.category] = counts[preset.category] + 1
        end
    end
    return counts
end

return EffectPresets
