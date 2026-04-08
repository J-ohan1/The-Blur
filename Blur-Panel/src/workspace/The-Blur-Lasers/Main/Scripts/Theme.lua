-- Theme.lua - Complete visual theme for The-Blur SurfaceGUI
-- This ModuleScript returns the entire theme configuration
-- Pixel-perfect replica of the Next.js website at 4K (3840x2160)

local Theme = {}

--------------------------------------------------------------------------------
-- Resolution & Scaling
--------------------------------------------------------------------------------
Theme.Resolution = Vector2.new(3840, 2160)
Theme.ScaleFactor = 1 -- 4K native, no downscaling needed

--------------------------------------------------------------------------------
-- Colors (exact Color3 values from website Tailwind analysis)
--------------------------------------------------------------------------------
Theme.Colors = {
    ---------------------------------------------------------------------------
    -- Backgrounds
    ---------------------------------------------------------------------------
    Background       = Color3.fromRGB(0, 0, 0),
    NavBar           = Color3.fromRGB(0, 0, 0),           -- with 90% opacity
    PanelBackground  = Color3.fromRGB(10, 10, 10),        -- neutral-950/50
    CardBackground   = Color3.fromRGB(15, 15, 15),
    FrameHeader      = Color3.fromRGB(10, 10, 10),
    Surface          = Color3.fromRGB(12, 12, 12),        -- white/5
    SurfaceHover     = Color3.fromRGB(25, 25, 25),        -- white/10
    SurfaceActive    = Color3.fromRGB(38, 38, 38),        -- white/15

    ---------------------------------------------------------------------------
    -- Text colors (neutral scale from Tailwind)
    ---------------------------------------------------------------------------
    TextPrimary      = Color3.fromRGB(255, 255, 255),     -- white
    TextSecondary    = Color3.fromRGB(212, 212, 212),     -- neutral-300
    TextBody         = Color3.fromRGB(163, 163, 163),     -- neutral-400
    TextMuted        = Color3.fromRGB(115, 115, 115),     -- neutral-500
    TextSubtle       = Color3.fromRGB(82, 82, 82),        -- neutral-600
    TextVerySubtle   = Color3.fromRGB(64, 64, 64),        -- neutral-700
    TextUltraSubtle  = Color3.fromRGB(38, 38, 38),        -- neutral-800
    TextPlaceholder  = Color3.fromRGB(64, 64, 64),        -- neutral-500 (inputs)

    ---------------------------------------------------------------------------
    -- Border colors
    ---------------------------------------------------------------------------
    BorderDefault    = Color3.fromRGB(38, 38, 38),        -- neutral-800
    BorderLight      = Color3.fromRGB(38, 38, 38),        -- neutral-800/60
    BorderSubtle     = Color3.fromRGB(64, 64, 64),        -- neutral-800/40
    BorderHover      = Color3.fromRGB(64, 64, 64),        -- neutral-700
    BorderActive     = Color3.fromRGB(82, 82, 82),        -- neutral-600
    BorderFocus      = Color3.fromRGB(255, 255, 255),     -- white (focus rings)
    BorderDivider    = Color3.fromRGB(25, 25, 25),        -- neutral-800/30

    ---------------------------------------------------------------------------
    -- Button colors
    ---------------------------------------------------------------------------
    ButtonPrimary        = Color3.fromRGB(255, 255, 255), -- white bg
    ButtonPrimaryHover   = Color3.fromRGB(212, 212, 212), -- neutral-200
    ButtonPrimaryActive  = Color3.fromRGB(163, 163, 163), -- neutral-300
    ButtonPrimaryText    = Color3.fromRGB(0, 0, 0),       -- black text
    ButtonSecondary      = Color3.fromRGB(12, 12, 12),    -- white/5
    ButtonSecondaryHover = Color3.fromRGB(25, 25, 25),    -- white/10
    ButtonSecondaryText  = Color3.fromRGB(212, 212, 212), -- neutral-300
    ButtonGhost          = Color3.fromRGB(0, 0, 0),       -- transparent
    ButtonGhostHover     = Color3.fromRGB(25, 25, 25),    -- white/10
    ButtonGhostText      = Color3.fromRGB(163, 163, 163), -- neutral-400
    ButtonActive         = Color3.fromRGB(38, 38, 38),    -- neutral-800/50
    ButtonDanger         = Color3.fromRGB(239, 68, 68),   -- red-500
    ButtonDangerHover    = Color3.fromRGB(220, 38, 38),   -- red-600
    ButtonDangerText     = Color3.fromRGB(255, 255, 255), -- white
    ButtonDisabled       = Color3.fromRGB(25, 25, 25),    -- white/10
    ButtonDisabledText   = Color3.fromRGB(64, 64, 64),    -- neutral-700

    ---------------------------------------------------------------------------
    -- Toggle / Switch colors
    ---------------------------------------------------------------------------
    ToggleOff         = Color3.fromRGB(38, 38, 38),       -- neutral-800
    ToggleOffBorder   = Color3.fromRGB(64, 64, 64),       -- neutral-700
    ToggleOn          = Color3.fromRGB(255, 255, 255),    -- white
    ToggleOnBorder    = Color3.fromRGB(255, 255, 255),    -- white
    ToggleKnob        = Color3.fromRGB(0, 0, 0),          -- black knob
    ToggleKnobOn      = Color3.fromRGB(0, 0, 0),          -- black knob

    ---------------------------------------------------------------------------
    -- Role colors
    ---------------------------------------------------------------------------
    RoleStaff            = Color3.fromRGB(96, 165, 250),   -- blue-400
    RoleWhitelisted      = Color3.fromRGB(52, 211, 153),   -- emerald-400
    RoleTempWhitelisted  = Color3.fromRGB(250, 204, 21),   -- yellow-400
    RoleNormal           = Color3.fromRGB(163, 163, 163),  -- neutral-400
    RoleBlacklisted      = Color3.fromRGB(239, 68, 68),    -- red-500

    -- Role badge backgrounds (very subtle tinted versions)
    RoleStaffBg            = Color3.fromRGB(96, 165, 250),  -- blue-400/10
    RoleWhitelistedBg      = Color3.fromRGB(52, 211, 153),  -- emerald-400/10
    RoleTempWhitelistedBg  = Color3.fromRGB(250, 204, 21),  -- yellow-400/10

    ---------------------------------------------------------------------------
    -- Quick colors (14 preset laser colors)
    ---------------------------------------------------------------------------
    QuickColor_White     = Color3.fromRGB(255, 255, 255),
    QuickColor_Red       = Color3.fromRGB(255, 0, 0),
    QuickColor_Orange    = Color3.fromRGB(255, 102, 0),
    QuickColor_Yellow    = Color3.fromRGB(255, 204, 0),
    QuickColor_Green     = Color3.fromRGB(51, 204, 51),
    QuickColor_Blue      = Color3.fromRGB(0, 153, 255),
    QuickColor_Purple    = Color3.fromRGB(102, 51, 255),
    QuickColor_Pink      = Color3.fromRGB(255, 51, 204),
    QuickColor_HotPink   = Color3.fromRGB(255, 102, 153),
    QuickColor_Mint      = Color3.fromRGB(153, 255, 204),
    QuickColor_LightGray = Color3.fromRGB(204, 204, 204),
    QuickColor_DarkGray  = Color3.fromRGB(102, 102, 102),
    QuickColor_Charcoal  = Color3.fromRGB(51, 51, 51),
    QuickColor_Black     = Color3.fromRGB(0, 0, 0),

    ---------------------------------------------------------------------------
    -- Toast indicator colors
    ---------------------------------------------------------------------------
    ToastSuccess     = Color3.fromRGB(255, 255, 255),     -- white dot
    ToastWarning     = Color3.fromRGB(163, 163, 163),     -- neutral-400 dot
    ToastError       = Color3.fromRGB(115, 115, 115),     -- neutral-500 dot
    ToastInfo        = Color3.fromRGB(96, 165, 250),      -- blue-400 dot

    ---------------------------------------------------------------------------
    -- Easter egg colors
    ---------------------------------------------------------------------------
    EasterEggRed       = Color3.fromRGB(239, 68, 68),     -- red-500
    EasterEggGradient  = Color3.fromRGB(153, 27, 27),     -- red-900
    EasterEggBg        = Color3.fromRGB(127, 29, 29),     -- red-900/80

    ---------------------------------------------------------------------------
    -- Glow effects (used with ImageLabel transparencies)
    ---------------------------------------------------------------------------
    GlowWhite        = Color3.fromRGB(255, 255, 255),
    GlowStaff        = Color3.fromRGB(96, 165, 250),
    GlowWhitelisted  = Color3.fromRGB(52, 211, 153),
    GlowYellow       = Color3.fromRGB(250, 204, 21),
    GlowRed          = Color3.fromRGB(239, 68, 68),
    GlowBlue         = Color3.fromRGB(0, 153, 255),

    ---------------------------------------------------------------------------
    -- Timecode cell types
    ---------------------------------------------------------------------------
    CellEffect       = Color3.fromRGB(25, 25, 25),        -- neutral-800/50
    CellToggle       = Color3.fromRGB(20, 20, 20),        -- neutral-800/40
    CellPosition     = Color3.fromRGB(30, 30, 30),        -- neutral-800/60
    CellPlayhead     = Color3.fromRGB(38, 38, 38),        -- neutral-800/40
    CellActive       = Color3.fromRGB(255, 255, 255),     -- white (active step)
    CellEmpty        = Color3.fromRGB(12, 12, 12),        -- empty cell

    ---------------------------------------------------------------------------
    -- Save dialog glow
    ---------------------------------------------------------------------------
    SaveGlow        = Color3.fromRGB(255, 255, 255),

    ---------------------------------------------------------------------------
    -- Landing page colors
    ---------------------------------------------------------------------------
    LandingOverlay  = Color3.fromRGB(0, 0, 0),            -- black overlay
    LandingText     = Color3.fromRGB(255, 255, 255),      -- white text

    ---------------------------------------------------------------------------
    -- Carousel colors
    ---------------------------------------------------------------------------
    CarouselDotActive   = Color3.fromRGB(255, 255, 255),  -- white
    CarouselDotInactive = Color3.fromRGB(64, 64, 64),     -- neutral-700
    CarouselArrow       = Color3.fromRGB(163, 163, 163),  -- neutral-400

    ---------------------------------------------------------------------------
    -- Navbar specific
    ---------------------------------------------------------------------------
    NavLogo           = Color3.fromRGB(255, 255, 255),    -- white
    NavSeparator      = Color3.fromRGB(38, 38, 38),       -- neutral-800
    NavTabActive      = Color3.fromRGB(255, 255, 255),    -- white text
    NavTabInactive    = Color3.fromRGB(163, 163, 163),    -- neutral-400
    NavTabHover       = Color3.fromRGB(212, 212, 212),    -- neutral-300

    ---------------------------------------------------------------------------
    -- Input / Form colors
    ---------------------------------------------------------------------------
    InputBackground    = Color3.fromRGB(12, 12, 12),      -- white/5
    InputBorder        = Color3.fromRGB(38, 38, 38),      -- neutral-800
    InputBorderFocus   = Color3.fromRGB(64, 64, 64),      -- neutral-700
    InputPlaceholder   = Color3.fromRGB(64, 64, 64),      -- neutral-500
    InputText          = Color3.fromRGB(212, 212, 212),   -- neutral-300

    ---------------------------------------------------------------------------
    -- Scrollbar
    ---------------------------------------------------------------------------
    ScrollbarTrack   = Color3.fromRGB(0, 0, 0),
    ScrollbarThumb   = Color3.fromRGB(38, 38, 38),        -- neutral-800
    ScrollbarThumbHover = Color3.fromRGB(64, 64, 64),     -- neutral-700

    ---------------------------------------------------------------------------
    -- Effect editor
    ---------------------------------------------------------------------------
    EditorGridLine       = Color3.fromRGB(25, 25, 25),    -- grid lines
    EditorBeamDefault    = Color3.fromRGB(255, 255, 255), -- white beam
    EditorBeamSelected   = Color3.fromRGB(96, 165, 250),  -- blue-400 selected
    EditorOnionSkin      = Color3.fromRGB(255, 255, 255), -- with low transparency
    EditorPlayhead       = Color3.fromRGB(255, 255, 255), -- white playhead line
    EditorTimeline       = Color3.fromRGB(12, 12, 12),    -- timeline bg
    EditorFrameActive    = Color3.fromRGB(38, 38, 38),    -- active frame
    EditorFrameInactive  = Color3.fromRGB(18, 18, 18),    -- inactive frame

    ---------------------------------------------------------------------------
    -- Dropdown / Popover
    ---------------------------------------------------------------------------
    DropdownBg        = Color3.fromRGB(12, 12, 12),       -- neutral-950
    DropdownBorder    = Color3.fromRGB(38, 38, 38),       -- neutral-800
    DropdownHover     = Color3.fromRGB(25, 25, 25),       -- white/10
    DropdownSeparator = Color3.fromRGB(25, 25, 25),       -- neutral-800/30

    ---------------------------------------------------------------------------
    -- Hub panel
    ---------------------------------------------------------------------------
    HubCardBg         = Color3.fromRGB(15, 15, 15),       -- card bg
    HubCardHover      = Color3.fromRGB(25, 25, 25),       -- hover state
    HubBadgeBg        = Color3.fromRGB(25, 25, 25),       -- badge bg
    HubTabActive      = Color3.fromRGB(255, 255, 255),    -- white text
    HubTabInactive    = Color3.fromRGB(115, 115, 115),    -- neutral-500

    ---------------------------------------------------------------------------
    -- Keybind display
    ---------------------------------------------------------------------------
    KeybindKey        = Color3.fromRGB(25, 25, 25),       -- key bg
    KeybindKeyBorder  = Color3.fromRGB(64, 64, 64),       -- key border
    KeybindKeyText    = Color3.fromRGB(212, 212, 212),    -- key text
    KeybindRecording  = Color3.fromRGB(239, 68, 68),      -- red (recording)

    ---------------------------------------------------------------------------
    -- Customisation / Fader colors
    ---------------------------------------------------------------------------
    FaderTrack       = Color3.fromRGB(25, 25, 25),        -- track bg
    FaderFill        = Color3.fromRGB(255, 255, 255),     -- fill color
    FaderKnob        = Color3.fromRGB(255, 255, 255),     -- white knob
    FaderLabel       = Color3.fromRGB(163, 163, 163),     -- neutral-400
    FaderValue       = Color3.fromRGB(212, 212, 212),     -- neutral-300

    ---------------------------------------------------------------------------
    -- Color picker
    ---------------------------------------------------------------------------
    ColorPickerHueTrack    = Color3.fromRGB(25, 25, 25),
    ColorPickerThumb       = Color3.fromRGB(255, 255, 255),

    ---------------------------------------------------------------------------
    -- Player card
    ---------------------------------------------------------------------------
    PlayerCardHover       = Color3.fromRGB(25, 25, 25),   -- hover bg
    PlayerCardSelected    = Color3.fromRGB(38, 38, 38),   -- selected bg
    PlayerCardCheckboxOn  = Color3.fromRGB(255, 255, 255), -- white check
    PlayerCardCheckboxOff = Color3.fromRGB(38, 38, 38),   -- neutral-800

    ---------------------------------------------------------------------------
    -- Misc / Utility
    ---------------------------------------------------------------------------
    Skeleton          = Color3.fromRGB(25, 25, 25),       -- loading skeleton
    Selection         = Color3.fromRGB(255, 255, 255),    -- text selection bg
    Link              = Color3.fromRGB(212, 212, 212),    -- neutral-300
    LinkHover         = Color3.fromRGB(255, 255, 255),    -- white on hover
    Badge             = Color3.fromRGB(25, 25, 25),       -- badge bg
    BadgeText         = Color3.fromRGB(163, 163, 163),    -- badge text
    Separator         = Color3.fromRGB(25, 25, 25),       -- divider line
    Overlay           = Color3.fromRGB(0, 0, 0),          -- modal overlay
}

--------------------------------------------------------------------------------
-- Quick colors as an ordered array (for the 14-color picker grid)
--------------------------------------------------------------------------------
Theme.QuickColors = {
    { name = "White",     color = Theme.Colors.QuickColor_White },
    { name = "Red",       color = Theme.Colors.QuickColor_Red },
    { name = "Orange",    color = Theme.Colors.QuickColor_Orange },
    { name = "Yellow",    color = Theme.Colors.QuickColor_Yellow },
    { name = "Green",     color = Theme.Colors.QuickColor_Green },
    { name = "Blue",      color = Theme.Colors.QuickColor_Blue },
    { name = "Purple",    color = Theme.Colors.QuickColor_Purple },
    { name = "Pink",      color = Theme.Colors.QuickColor_Pink },
    { name = "Hot Pink",  color = Theme.Colors.QuickColor_HotPink },
    { name = "Mint",      color = Theme.Colors.QuickColor_Mint },
    { name = "Light Gray",color = Theme.Colors.QuickColor_LightGray },
    { name = "Dark Gray", color = Theme.Colors.QuickColor_DarkGray },
    { name = "Charcoal",  color = Theme.Colors.QuickColor_Charcoal },
    { name = "Black",     color = Theme.Colors.QuickColor_Black },
}

--------------------------------------------------------------------------------
-- Role color mapping
--------------------------------------------------------------------------------
Theme.RoleColors = {
    staff            = Theme.Colors.RoleStaff,
    whitelisted      = Theme.Colors.RoleWhitelisted,
    temp_whitelisted = Theme.Colors.RoleTempWhitelisted,
    normal           = Theme.Colors.RoleNormal,
    blacklisted      = Theme.Colors.RoleBlacklisted,
}

Theme.RoleBadgeColors = {
    staff            = Theme.Colors.RoleStaffBg,
    whitelisted      = Theme.Colors.RoleWhitelistedBg,
    temp_whitelisted = Theme.Colors.RoleTempWhitelistedBg,
    normal           = Theme.Colors.Surface,
    blacklisted      = Color3.fromRGB(239, 68, 68),
}

-- Role display names (properly capitalized)
Theme.RoleDisplayNames = {
    staff            = "Staff",
    whitelisted      = "Whitelisted",
    temp_whitelisted = "Temp Whitelisted",
    normal           = "Normal",
    blacklisted      = "Blacklisted",
}

-- Role priority (higher number = higher permission)
Theme.RolePriority = {
    staff            = 5,
    whitelisted      = 4,
    temp_whitelisted = 3,
    normal           = 2,
    blacklisted      = 1,
}

--------------------------------------------------------------------------------
-- Fonts (Inter family mapped to closest Roblox equivalents)
--------------------------------------------------------------------------------
Theme.Font = {
    Family         = Enum.Font.GothamBold,      -- Closest to Inter Bold
    FamilyMedium   = Enum.Font.GothamMedium,    -- Inter Medium
    FamilySemibold = Enum.Font.GothamSemibold,  -- Inter Semibold
    FamilyBold     = Enum.Font.GothamBold,      -- Inter Bold
    FamilyBlack    = Enum.Font.GothamBlack,     -- Inter Black (extra bold)
    FamilyLight    = Enum.Font.Gotham,          -- Inter Light/Regular
    Mono           = Enum.Font.Code,            -- JetBrains Mono equivalent
    Icon           = Enum.Font.GothamBold,      -- Icon font fallback
}

--------------------------------------------------------------------------------
-- Font sizes (scaled for 4K - multiply web sizes by 2)
--------------------------------------------------------------------------------
Theme.FontSize = {
    -- Landing page
    LandingTitle     = 240,   -- 120px web * 2
    LandingSubtitle  = 60,    -- 30px web * 2

    -- Carousel
    CarouselText     = 120,   -- 60px web * 2

    -- Welcome screen
    WelcomeTitle     = 80,    -- 40px web * 2
    WelcomeSubtitle  = 36,    -- 18px web * 2

    -- Headings
    H1               = 72,    -- 36px web * 2
    H2               = 56,    -- 28px web * 2
    H3               = 44,    -- 22px web * 2
    H4               = 36,    -- 18px web * 2

    -- Body text
    Large            = 36,    -- 18px web * 2
    Body             = 28,    -- 14px web * 2
    CardTitle        = 26,    -- 13px web * 2

    -- Small text
    Small            = 24,    -- 12px web * 2
    Label            = 22,    -- 11px web * 2
    Tiny             = 20,    -- 10px web * 2

    -- Extra small
    Micro            = 18,    -- 9px web * 2
    Nano             = 16,    -- 8px web * 2
    Ultra            = 14,    -- 7px web * 2

    -- Badges
    Badge            = 14,    -- 9px web (badge text)
    BadgeSmall       = 12,    -- 6px web (small badge)

    -- Specific UI elements
    NavBarBrand      = 48,    -- 24px web * 2
    NavTab           = 24,    -- 12px web * 2
    Button           = 24,    -- 12px web * 2
    ButtonLarge      = 28,    -- 14px web * 2
    Input            = 24,    -- 12px web * 2
    Toast            = 22,    -- 11px web * 2
    Keybind          = 20,    -- 10px web * 2
    FaderLabel       = 20,    -- 10px web * 2
    FaderValue       = 22,    -- 11px web * 2
    TimecodeStep     = 18,    -- 9px web * 2
    EffectName       = 22,    -- 11px web * 2
    CategoryName     = 24,    -- 12px web * 2
    PlayerName       = 24,    -- 12px web * 2
    RoleBadge        = 14,    -- 9px web * 2
    FrameHeader      = 22,    -- 11px web * 2
    TabText          = 22,    -- 11px web * 2
    TooltipText      = 20,    -- 10px web * 2
    EasterEggText    = 28,    -- 14px web * 2
    TimerText        = 22,    -- 11px web * 2
}

--------------------------------------------------------------------------------
-- Spacing (scaled for 4K - multiply web sizes by 2)
--------------------------------------------------------------------------------
Theme.Spacing = {
    -- Base scale (4px increments)
    XXS  = 2,           -- 1px web * 2
    XS   = 4,           -- 2px web * 2
    SM   = 8,           -- 4px web * 2
    MD   = 12,          -- 6px web * 2
    Base = 16,          -- 8px web * 2
    LG   = 20,          -- 10px web * 2
    XL   = 24,          -- 12px web * 2
    XXL  = 32,          -- 16px web * 2
    XXXL = 48,          -- 24px web * 2

    -- Component-specific
    NavBarHeight      = 96,    -- 48px * 2
    NavBarPaddingX    = 48,    -- 24px * 2
    PanelPadding      = 32,    -- 16px * 2
    PanelTopOffset    = 112,   -- pt-14 (56px * 2)
    PanelGap          = 24,    -- 12px * 2
    FrameHeaderHeight = 64,    -- 32px * 2
    FramePadding      = 24,    -- 12px * 2
    CardPadding       = 24,    -- 12px * 2
    CardGap           = 16,    -- 8px * 2
    ButtonPaddingX    = 32,    -- 16px * 2
    ButtonPaddingY    = 16,    -- 8px * 2
    ButtonGap         = 12,    -- 6px * 2
    InputPaddingX     = 24,    -- 12px * 2
    InputPaddingY     = 14,    -- 7px * 2
    InputGap          = 8,     -- 4px * 2
    ToastPaddingX     = 24,    -- 12px * 2
    ToastPaddingY     = 16,    -- 8px * 2
    DropdownPadding   = 8,     -- 4px * 2
    DropdownItemH     = 44,    -- 22px * 2
    AvatarGap         = 12,    -- 6px * 2
    GridGap           = 16,    -- 8px * 2
    SectionGap        = 32,    -- 16px * 2
    DividerMargin     = 16,    -- 8px * 2
}

--------------------------------------------------------------------------------
-- Border radius (scaled for 4K)
--------------------------------------------------------------------------------
Theme.CornerRadius = {
    None  = 0,
    SM    = 4,          -- rounded-sm (2px approx)
    MD    = 8,          -- rounded-md (6px approx)
    LG    = 16,         -- rounded-lg (8px)
    XL    = 24,         -- rounded-xl (12px)
    XXL   = 32,         -- rounded-2xl (16px)
    Full  = 9999,       -- rounded-full (circular)
}

--------------------------------------------------------------------------------
-- Avatar sizes (scaled for 4K)
--------------------------------------------------------------------------------
Theme.Avatar = {
    Nav         = 56,     -- 28px * 2 (w-7 h-7)
    Dropdown    = 72,     -- 36px * 2 (w-9 h-9)
    PlayerCard  = 80,     -- 40px * 2 (w-10 h-10)
    Welcome     = 96,     -- 48px * 2 (w-12 h-12)
    HubCard     = 64,     -- 32px * 2 (w-8 h-8)
    Large       = 128,    -- 64px * 2 (w-16 h-16)
}

--------------------------------------------------------------------------------
-- Icon sizes (scaled for 4K)
--------------------------------------------------------------------------------
Theme.Icon = {
    XS    = 24,     -- 12px * 2
    SM    = 28,     -- 14px * 2
    MD    = 32,     -- 16px * 2
    LG    = 36,     -- 18px * 2
    XL    = 40,     -- 20px * 2
    XXL   = 48,     -- 24px * 2
}

--------------------------------------------------------------------------------
-- Animation durations (in seconds)
--------------------------------------------------------------------------------
Theme.Animation = {
    -- UI transitions
    Fast               = 0.12,
    Quick              = 0.2,
    Normal             = 0.25,
    Medium             = 0.3,
    Standard           = 0.4,
    Slow               = 0.5,
    Slower             = 0.6,

    -- Landing page
    LandingTitle       = 0.8,
    LandingFadeIn      = 0.6,
    LandingFadeOut     = 0.4,
    WelcomeAutoTransition = 2.5,

    -- Toast system
    ToastEnter         = 0.3,
    ToastExit          = 0.2,
    ToastAutoDismiss   = 3,

    -- Blink effects (for recording indicators)
    BlinkSlow          = 1.5,
    BlinkMedium        = 1.0,
    BlinkFast          = 0.8,

    -- Pulse effects
    PulseSlow          = 2.0,
    PulseMedium        = 1.5,
    PulseFast          = 1.0,
    PlayheadPulse      = 0.8,

    -- Spring physics (for Framer Motion spring approximation)
    SpringStiffness    = 400,
    SpringDamping      = 30,

    -- Hover / Press
    HoverEnter         = 0.15,
    HoverExit          = 0.1,
    PressIn            = 0.1,
    PressOut           = 0.15,

    -- Dropdown
    DropdownOpen       = 0.2,
    DropdownClose      = 0.15,

    -- Modal
    Enter              = 0.25,    -- alias for ModalScaleIn
    Exit               = 0.15,    -- alias for ModalScaleOut
    ModalFadeIn        = 0.2,
    ModalFadeOut       = 0.15,
    ModalScaleIn       = 0.25,
    ModalScaleOut      = 0.15,

    -- Panel transitions
    PanelFadeIn        = 0.2,
    PanelSlideIn       = 0.3,
    PanelSlideOut      = 0.2,

    -- Carousel
    CarouselSlide      = 0.5,

    -- Editor
    FrameTransition    = 0.15,
    EditorPlaySpeed    = 0.5,     -- base frame interval at speed=1
}

--------------------------------------------------------------------------------
-- Easing styles
--------------------------------------------------------------------------------
Theme.Easing = {
    Spring         = Enum.EasingStyle.Back,
    Smooth         = Enum.EasingStyle.Quad,
    Standard       = Enum.EasingStyle.Cubic,
    Bounce         = Enum.EasingStyle.Bounce,
    Elastic        = Enum.EasingStyle.Elastic,
    Expo           = Enum.EasingStyle.Quart,   -- Roblox has no Expo; Quart is closest
    Sine           = Enum.EasingStyle.Sine,
    Direction      = Enum.EasingDirection.Out,
    DirectionIn    = Enum.EasingDirection.In,
    DirectionInOut = Enum.EasingDirection.InOut,
}

--------------------------------------------------------------------------------
-- Scrollbar dimensions
--------------------------------------------------------------------------------
Theme.Scrollbar = {
    Width         = 10,
    MinHeight     = 40,
    ThumbColor    = Color3.fromRGB(38, 38, 38),
    ThumbHoverColor = Color3.fromRGB(64, 64, 64),
    TrackColor    = Color3.fromRGB(0, 0, 0),
    CornerRadius  = 10,
    Padding       = 2,
}

--------------------------------------------------------------------------------
-- Shadow values (simulated with ImageLabel + UICorner in Roblox)
--------------------------------------------------------------------------------
Theme.Shadow = {
    None   = 0,
    Small  = 4,
    Medium = 8,
    Large  = 16,
    XL     = 24,
    XXL    = 32,
}

--------------------------------------------------------------------------------
-- Transparency values (for overlay effects)
--------------------------------------------------------------------------------
Theme.Transparency = {
    Full       = 1,
    High       = 0.9,
    NavBar     = 0.1,       -- 90% opacity
    Panel      = 0.5,       -- 50% opacity
    Card       = 0.4,       -- 60% opacity
    Subtle     = 0.7,       -- 30% opacity
    HoverGlow  = 0.85,      -- 15% opacity
    Low        = 0.05,      -- 95% opacity
    None       = 0,
}

--------------------------------------------------------------------------------
-- Z-Index layers (for proper layering in SurfaceGUI)
--------------------------------------------------------------------------------
Theme.ZIndex = {
    Background    = 1,
    Content       = 5,
    Panel         = 10,
    Card          = 15,
    Input         = 20,
    Button        = 25,
    Dropdown      = 30,
    Tooltip       = 35,
    Toast         = 40,
    ModalOverlay  = 45,
    Modal         = 50,
    EasterEgg     = 55,
    Top           = 100,
}

--------------------------------------------------------------------------------
-- Layout constants
--------------------------------------------------------------------------------
Theme.Layout = {
    -- Main grid
    MainColumns      = 3,
    MainColumnGap    = 24,

    -- Navbar
    NavBarLeftWidth  = 0.15,   -- 15% for logo
    NavBarCenterWidth = 0.55,   -- 55% for tabs
    NavBarRightWidth = 0.30,    -- 30% for user

    -- Panel widths (fraction of available space)
    PanelWide        = 2,       -- spans 2 columns
    PanelNarrow      = 1,       -- spans 1 column

    -- Effect grid
    EffectColumns    = 3,
    EffectGridGap    = 16,

    -- Player list
    PlayerColumns    = 1,
    PlayerItemHeight = 56,      -- 28px * 2

    -- Timecode grid
    TimecodeColumns  = 16,      -- 16 steps
    TimecodeRowHeight = 44,     -- 22px * 2
}

--------------------------------------------------------------------------------
-- Text truncation
--------------------------------------------------------------------------------
Theme.Text = {
    Truncate = Enum.TextTruncate.AtEnd,
    Ellipsis = "...",
}

--------------------------------------------------------------------------------
-- Beam editor constants
--------------------------------------------------------------------------------
Theme.BeamEditor = {
    DefaultBeamCount  = 15,
    MaxBeams          = 30,
    MinBeams          = 1,
    BeamDotSize       = 12,     -- 6px * 2
    BeamSelectedSize  = 18,     -- 9px * 2
    GridPadding       = 40,     -- 20px * 2
    GridLines         = 10,
    PlayheadWidth     = 4,      -- 2px * 2
    OnionSkinOpacity  = 0.15,
    MinFrameCount     = 1,
    MaxFrameCount     = 120,
    DefaultFrameCount = 24,
    DefaultFPS        = 24,
    SpeedMin          = 0.25,
    SpeedMax          = 4.0,
    SpeedStep         = 0.25,
}

--------------------------------------------------------------------------------
-- Timecode constants
--------------------------------------------------------------------------------
Theme.Timecode = {
    DefaultBPM          = 120,
    MinBPM              = 60,
    MaxBPM              = 200,
    BPMStep            = 1,
    DefaultSteps        = 16,
    MinSteps            = 4,
    MaxSteps            = 64,
    StepIncrement       = 4,
    PlayheadFlashSpeed  = 0.8,
}

--------------------------------------------------------------------------------
-- Customisation fader config
--------------------------------------------------------------------------------
Theme.Faders = {
    { id = "phase",      name = "Phase",      min = 0, max = 255, default = 128 },
    { id = "speed",      name = "Speed",      min = 0, max = 255, default = 128 },
    { id = "iris",       name = "Iris",       min = 0, max = 255, default = 255 },
    { id = "dimmer",     name = "Dimmer",     min = 0, max = 255, default = 255 },
    { id = "wing",       name = "Wing",       min = 0, max = 255, default = 128 },
    { id = "tilt",       name = "Tilt",       min = 0, max = 255, default = 128 },
    { id = "pan",        name = "Pan",        min = 0, max = 255, default = 128 },
    { id = "brightness", name = "Brightness", min = 0, max = 255, default = 255 },
    { id = "zoom",       name = "Zoom",       min = 0, max = 255, default = 128 },
}

--------------------------------------------------------------------------------
-- Effect save tags
--------------------------------------------------------------------------------
Theme.SaveTags = {
    "movement", "pattern", "chase", "wave", "custom",
    "color", "strobe", "fan", "symmetric", "random",
}

--------------------------------------------------------------------------------
-- Max lengths
--------------------------------------------------------------------------------
Theme.MaxLength = {
    EffectName      = 30,
    GroupName       = 20,
    PositionName    = 20,
    SaveName        = 30,
    KeybindLabel    = 20,
    PlayerName      = 20,
    TimecodeProject = 30,
    SearchQuery     = 50,
}

-- Alias for backward compatibility (some files use plural)
Theme.Animations = Theme.Animation

return Theme
