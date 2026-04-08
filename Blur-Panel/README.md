# The-Blur Panel — Roblox SurfaceGUI

Pixel-perfect replica of The-Blur laser control panel for Roblox SurfaceGUI (4K).

## Resolution
- **4K (3840 × 2160)** canvas size

## Setup Instructions

### 1. Workspace Hierarchy

```
The-Blur-Lasers
├── Lasers
├── Main
│   ├── Events
│   │   ├── RemoteEvents        (ModuleScript)
│   │   └── RemoteSetup         (Script)
│   ├── Scripts
│   │   ├── Theme.lua            (ModuleScript)
│   │   ├── Store.lua            (ModuleScript)
│   │   ├── TweenHelper.lua      (ModuleScript)
│   │   ├── ProfanityFilter.lua  (ModuleScript)
│   │   ├── EffectPresets.lua    (ModuleScript)
│   │   ├── MainController.lua   (LocalScript)
│   │   ├── NavBar.lua           (ModuleScript)
│   │   ├── ToastSystem.lua      (ModuleScript)
│   │   ├── ProfileDropdown.lua  (ModuleScript)
│   │   ├── EasterEggPopup.lua   (ModuleScript)
│   │   ├── Components/
│   │   │   ├── Button.lua
│   │   │   ├── Card.lua
│   │   │   ├── Modal.lua
│   │   │   ├── ScrollFrame.lua
│   │   │   ├── Slider.lua
│   │   │   ├── ColorWheel.lua
│   │   │   ├── Dropdown.lua
│   │   │   ├── Toggle.lua
│   │   │   └── ContextMenu.lua
│   │   └── Panels/
│   │       ├── LandingPanel.lua
│   │       ├── WelcomePanel.lua
│   │       ├── HomePanel.lua
│   │       ├── ControlPanel.lua
│   │       ├── CustomisationPanel.lua
│   │       ├── GroupPanel.lua
│   │       ├── PlayerPanel.lua
│   │       ├── EffectPanel.lua
│   │       ├── HubPanel.lua
│   │       ├── KeybindPanel.lua
│   │       ├── TimecodePanel.lua
│   │       └── InfoPanel.lua
│   └── Template
└── Panel
    └── Panel
        └── GUI  (SurfaceGui)
```

### 2. SurfaceGui Configuration

At `Panel/Panel/GUI`:
- **Class**: SurfaceGui
- **Face**: Front
- **CanvasSize**: {3840, 0}, {2160, 0}
- **LightInfluence**: 0
- **ResetOnSpawn**: false
- **PixelsPerStud**: 10 (adjust based on Part size)

### 3. Panel Part Size

| PixelsPerStud | Part Size (studs) |
|---------------|-------------------|
| 10 | 384 × 216 |
| 15 | 256 × 144 |
| 20 | 192 × 108 |

### 4. Script Types

| File | Script Type |
|------|-------------|
| RemoteSetup | Script (Server) |
| MainController | LocalScript |
| All others | ModuleScript |

### 5. Adding Scripts in Roblox Studio

1. Create the folder structure as shown above
2. For each `.lua` file:
   - Create a **ModuleScript** (or **LocalScript**/**Script** as specified)
   - Name it exactly as shown (without `.lua` extension)
   - Paste the file contents
   - Parent it to the correct folder
3. Create an empty **SurfaceGui** at `Panel/Panel/GUI`
4. Set SurfaceGui properties (CanvasSize, PixelsPerStud, etc.)
5. Playtest!

## Features

- 3-phase flow: Landing → Welcome → Main
- 10 navigation panels with spring-animated underline
- 35 built-in laser effects (Waves, Chase, Pattern, Color, Advanced)
- Full effect editor with draggable canvas, timeline, undo/redo
- Group management (Fixture + Individual modes)
- Player management with role-based permissions
- Color wheel with brightness slider + 14 quick colors
- 9 fader sliders (Phase, Speed, Iris, Dimmer, Wing, Tilt, Pan, Brightness, Zoom)
- DAW-style timecode sequencer with BPM sync
- Keybind system with recording
- Community hub for sharing effects
- 13 easter eggs
- Toast notification system
- Profanity filter with leet-speak detection
- Custom scrollbar, spring animations, 3D carousel

## Troubleshooting

- **UI too small**: Increase `PixelsPerStud` on SurfaceGui
- **UI too large**: Decrease `PixelsPerStud` on SurfaceGui
- **Scripts not loading**: Verify Script vs LocalScript vs ModuleScript types
- **Module not found**: Check folder names and hierarchy exactly match
- **Missing events**: Ensure RemoteSetup Script runs on server

## Architecture

- **Theme.lua**: All colors, fonts, sizes, spacing, animation configs
- **Store.lua**: Zustand-like state management with pub/sub events
- **TweenHelper.lua**: Animation utilities (spring, fade, slide, pulse)
- **Components/**: Reusable UI building blocks
- **Panels/**: Self-contained screen modules
- **MainController.lua**: Bootstrapper that wires everything together
