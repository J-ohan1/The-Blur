-- Store.lua - Central state management (inspired by Zustand)
-- Manages ALL application state for The-Blur SurfaceGUI
local Store = {}
Store.__index = Store

function Store.new()
    local self = setmetatable({}, Store)

    ---------------------------------------------------------------------------
    -- Phase management
    ---------------------------------------------------------------------------
    self.phase = "landing" -- "landing" | "welcome" | "main"
    self.activePanel = "home"

    ---------------------------------------------------------------------------
    -- User
    ---------------------------------------------------------------------------
    self.currentUser = {
        id = "local_player",
        name = "Johan",
        role = "staff", -- staff, whitelisted, temp_whitelisted, normal, blacklisted
    }
    self.sessionStartTime = tick()

    ---------------------------------------------------------------------------
    -- Players (12 mock players matching the website)
    ---------------------------------------------------------------------------
    self.players = {
        { id = "p1",  name = "xLaserKing",  role = "staff",            headshot = "" },
        { id = "p2",  name = "NeonPulse",   role = "whitelisted",      headshot = "" },
        { id = "p3",  name = "DarkPhoton",  role = "whitelisted",      headshot = "" },
        { id = "p4",  name = "BeamRider42", role = "temp_whitelisted", headshot = "" },
        { id = "p5",  name = "SpectrumX",   role = "temp_whitelisted", headshot = "" },
        { id = "p6",  name = "CrystalWave", role = "normal",           headshot = "" },
        { id = "p7",  name = "LaserFox",    role = "normal",           headshot = "" },
        { id = "p8",  name = "PhotonDust",  role = "normal",           headshot = "" },
        { id = "p9",  name = "PrismShift",  role = "normal",           headshot = "" },
        { id = "p10", name = "VoltEdge",    role = "normal",           headshot = "" },
        { id = "p11", name = "ShadowBeam",  role = "normal",           headshot = "" },
        { id = "p12", name = "Starburst99", role = "normal",           headshot = "" },
    }

    ---------------------------------------------------------------------------
    -- Groups
    ---------------------------------------------------------------------------
    self.groups = {} -- Array of { id, name, playerIds = {} }
    self.selectedGroupIds = {} -- Currently selected group IDs

    ---------------------------------------------------------------------------
    -- Control toggles
    ---------------------------------------------------------------------------
    self.masterOnOff = false
    self.fadeOnOff = false
    self.holdOnOff = false
    self.holdFadeOnOff = false
    self.selectedEffect = nil -- Currently active effect preset ID

    ---------------------------------------------------------------------------
    -- Positions (5 default positions matching the website)
    ---------------------------------------------------------------------------
    self.positions = {
        { id = "pos_1", name = "Fan Out" },
        { id = "pos_2", name = "Center" },
        { id = "pos_3", name = "Split" },
        { id = "pos_4", name = "Wave Line" },
        { id = "pos_5", name = "Symmetric" },
    }
    self.activePositionId = nil

    ---------------------------------------------------------------------------
    -- Effect Editor state
    ---------------------------------------------------------------------------
    self.effectPanelView = "list" -- "list" | "editor"
    self.editorFrames = {} -- Array of frames: each frame = array of 15 beams
    self.editorCurrentFrameIndex = 1
    self.editorIsPlaying = false
    self.editorLoop = false
    self.editorSpeed = 1
    self.editorSelectedBeams = {} -- Set of beam IDs (indices) currently selected
    self.editorOnionSkin = false
    self.editorApplyToAllFrames = false
    self.editorUndoStack = {} -- Stack of frame snapshots
    self.editorRedoStack = {} -- Stack of frame snapshots
    self.editorSaveDialogOpen = false
    self.editorSaveName = ""
    self.editorSaveType = "movement"
    self.editorSaveTags = {}
    self.editorPresetBrowserOpen = false
    self.savedEffects = {} -- User-saved custom effects

    ---------------------------------------------------------------------------
    -- Customisation state
    ---------------------------------------------------------------------------
    self.customisation = {
        colorHue = 0,
        colorSaturation = 0,
        colorBrightness = 1,
        faders = {
            phase = 128,
            speed = 128,
            iris = 255,
            dimmer = 255,
            wing = 128,
            tilt = 128,
            pan = 128,
            brightness = 255,
            zoom = 128,
        },
    }

    ---------------------------------------------------------------------------
    -- Keybinds
    ---------------------------------------------------------------------------
    self.keybinds = {
        effects = {},   -- { effectId = keyString }
        toggles = {},   -- { toggleName = keyString }
        positions = {}, -- { positionId = keyString }
    }
    self.recordingKeybind = nil -- nil or { category = string, itemId = string }

    ---------------------------------------------------------------------------
    -- Timecode
    ---------------------------------------------------------------------------
    self.timecodeProjects = {} -- Array of { id, name, steps = {} }
    self.activeTimecodeId = nil
    self.timecodeIsPlaying = false
    self.timecodeBPM = 120
    self.timecodeCurrentStep = 1
    self.timecodeLoop = false

    ---------------------------------------------------------------------------
    -- Hub
    ---------------------------------------------------------------------------
    self.hubEffects = {} -- Mock data for the Hub panel
    self.hubTab = "browse" -- "browse" | "my_uploads"
    self.hubFilter = "all" -- "all" | category filter
    self.hubSearch = ""
    self.hubViewingUser = nil -- nil or player table

    ---------------------------------------------------------------------------
    -- Toast system
    ---------------------------------------------------------------------------
    self.toasts = {} -- Array of { id, message, type, timestamp }

    ---------------------------------------------------------------------------
    -- Easter egg state
    ---------------------------------------------------------------------------
    self.easterEggClicks = 0
    self.lastEasterEggClick = 0
    self.easterEggVisible = false

    ---------------------------------------------------------------------------
    -- Profile dropdown
    ---------------------------------------------------------------------------
    self.profileDropdownOpen = false

    ---------------------------------------------------------------------------
    -- Save dialog glow animation
    ---------------------------------------------------------------------------
    self.saveGlow = false

    ---------------------------------------------------------------------------
    -- Keybind panel search
    ---------------------------------------------------------------------------
    self.keybindSearch = ""

    ---------------------------------------------------------------------------
    -- Internal: event listeners
    ---------------------------------------------------------------------------
    self._listeners = {} -- { eventName = { callback1, callback2, ... } }
    self._nextToastId = 1

    -- Initialize mock data
    self:_initHubEffects()
    self:_initBuiltInEffects()
    self:_initDefaultGroups()

    return self
end

--------------------------------------------------------------------------------
-- Listener system for reactive updates (pub/sub pattern)
--------------------------------------------------------------------------------

--- Subscribe to an event
-- @param event string - Event name
-- @param callback function - Callback function
function Store:on(event, callback)
    if not self._listeners[event] then
        self._listeners[event] = {}
    end
    table.insert(self._listeners[event], callback)
end

--- Unsubscribe from an event
-- @param event string - Event name
-- @param callback function - The exact callback reference to remove
function Store:off(event, callback)
    if self._listeners[event] then
        for i, cb in ipairs(self._listeners[event]) do
            if cb == callback then
                table.remove(self._listeners[event], i)
                break
            end
        end
    end
end

--- Emit an event to all listeners
-- @param event string - Event name
-- @param ... any - Arguments to pass to listeners
function Store:emit(event, ...)
    if self._listeners[event] then
        for _, callback in ipairs(self._listeners[event]) do
            local ok, err = pcall(callback, ...)
            if not ok then
                warn("[Store] Error in listener for '" .. event .. "': " .. tostring(err))
            end
        end
    end
end

--- Remove all listeners (useful for cleanup)
function Store:removeAllListeners()
    self._listeners = {}
end

--------------------------------------------------------------------------------
-- Phase management
--------------------------------------------------------------------------------

--- Set the application phase (landing -> welcome -> main)
-- @param phase string - "landing", "welcome", or "main"
function Store:setPhase(phase)
    assert(phase == "landing" or phase == "welcome" or phase == "main",
        "Invalid phase: " .. tostring(phase))
    self.phase = phase
    self:emit("phaseChanged", phase)
end

--- Get the current phase
-- @return string
function Store:getPhase()
    return self.phase
end

--------------------------------------------------------------------------------
-- Panel navigation
--------------------------------------------------------------------------------

--- Set the active panel
-- @param panel string - Panel identifier ("home", "effects", "customisation",
--                      "players", "groups", "timecode", "hub", "keybinds", "info")
function Store:setActivePanel(panel)
    local validPanels = {
        "home", "effects", "customisation", "players",
        "groups", "timecode", "hub", "keybinds", "info"
    }
    assert(validPanels[panel], "Invalid panel: " .. tostring(panel))
    self.activePanel = panel
    self:emit("panelChanged", panel)
end

--- Get the active panel
-- @return string
function Store:getActivePanel()
    return self.activePanel
end

--------------------------------------------------------------------------------
-- User management
--------------------------------------------------------------------------------

--- Get the current user
-- @return table
function Store:getCurrentUser()
    return self.currentUser
end

--- Check if current user has at least the given role level
-- @param requiredRole string
-- @return boolean
function Store:hasRole(requiredRole)
    local rolePriority = {
        staff = 5,
        whitelisted = 4,
        temp_whitelisted = 3,
        normal = 2,
        blacklisted = 1,
    }
    return (rolePriority[self.currentUser.role] or 0) >= (rolePriority[requiredRole] or 0)
end

--- Check if current user is staff
-- @return boolean
function Store:isStaff()
    return self.currentUser.role == "staff"
end

--------------------------------------------------------------------------------
-- Player management
--------------------------------------------------------------------------------

--- Get all players
-- @return table
function Store:getPlayers()
    return self.players
end

--- Get a player by ID
-- @param playerId string
-- @return table|nil
function Store:getPlayerById(playerId)
    for _, player in ipairs(self.players) do
        if player.id == playerId then
            return player
        end
    end
    return nil
end

--- Get player count
-- @return number
function Store:getPlayerCount()
    return #self.players
end

--------------------------------------------------------------------------------
-- Group management
--------------------------------------------------------------------------------

--- Add a new group
-- @param name string
-- @param playerIds table - Array of player IDs
-- @return table - The created group
function Store:addGroup(name, playerIds)
    local group = {
        id = "grp_" .. self:generateId(),
        name = name,
        playerIds = playerIds or {},
    }
    table.insert(self.groups, group)
    self:emit("groupsChanged", self.groups)
    return group
end

--- Remove a group by ID
-- @param groupId string
function Store:removeGroup(groupId)
    for i, g in ipairs(self.groups) do
        if g.id == groupId then
            table.remove(self.groups, i)
            break
        end
    end
    -- Also remove from selected
    for i, id in ipairs(self.selectedGroupIds) do
        if id == groupId then
            table.remove(self.selectedGroupIds, i)
            break
        end
    end
    self:emit("groupsChanged", self.groups)
    self:emit("groupSelectionChanged", self.selectedGroupIds)
end

--- Rename a group
-- @param groupId string
-- @param newName string
function Store:renameGroup(groupId, newName)
    for _, g in ipairs(self.groups) do
        if g.id == groupId then
            g.name = newName
            break
        end
    end
    self:emit("groupsChanged", self.groups)
end

--- Add a player to a group
-- @param groupId string
-- @param playerId string
function Store:addPlayerToGroup(groupId, playerId)
    for _, g in ipairs(self.groups) do
        if g.id == groupId then
            -- Check if already in group
            for _, pid in ipairs(g.playerIds) do
                if pid == playerId then return end
            end
            table.insert(g.playerIds, playerId)
            break
        end
    end
    self:emit("groupsChanged", self.groups)
end

--- Remove a player from a group
-- @param groupId string
-- @param playerId string
function Store:removePlayerFromGroup(groupId, playerId)
    for _, g in ipairs(self.groups) do
        if g.id == groupId then
            for i, pid in ipairs(g.playerIds) do
                if pid == playerId then
                    table.remove(g.playerIds, i)
                    break
                end
            end
            break
        end
    end
    self:emit("groupsChanged", self.groups)
end

--- Toggle group selection
-- @param groupId string
function Store:toggleGroupSelection(groupId)
    local found = false
    for i, id in ipairs(self.selectedGroupIds) do
        if id == groupId then
            table.remove(self.selectedGroupIds, i)
            found = true
            break
        end
    end
    if not found then
        table.insert(self.selectedGroupIds, groupId)
    end
    self:emit("groupSelectionChanged", self.selectedGroupIds)
end

--- Get selected groups
-- @return table - Array of group tables
function Store:getSelectedGroups()
    local selected = {}
    for _, id in ipairs(self.selectedGroupIds) do
        for _, g in ipairs(self.groups) do
            if g.id == id then
                table.insert(selected, g)
                break
            end
        end
    end
    return selected
end

--- Check if any groups are selected
-- @return boolean
function Store:hasSelectedGroups()
    return #self.selectedGroupIds > 0
end

--- Get all players in selected groups (deduplicated)
-- @return table - Array of player tables
function Store:getPlayersInSelectedGroups()
    local seen = {}
    local result = {}
    for _, groupId in ipairs(self.selectedGroupIds) do
        for _, g in ipairs(self.groups) do
            if g.id == groupId then
                for _, playerId in ipairs(g.playerIds) do
                    if not seen[playerId] then
                        seen[playerId] = true
                        local player = self:getPlayerById(playerId)
                        if player then
                            table.insert(result, player)
                        end
                    end
                end
                break
            end
        end
    end
    return result
end

--------------------------------------------------------------------------------
-- Toggle management
--------------------------------------------------------------------------------

function Store:setMasterOnOff(value)
    self.masterOnOff = value
    self:emit("togglesChanged")
end

function Store:toggleMasterOnOff()
    self.masterOnOff = not self.masterOnOff
    self:emit("togglesChanged")
    return self.masterOnOff
end

function Store:setFadeOnOff(value)
    self.fadeOnOff = value
    self:emit("togglesChanged")
end

function Store:toggleFadeOnOff()
    self.fadeOnOff = not self.fadeOnOff
    self:emit("togglesChanged")
    return self.fadeOnOff
end

function Store:setHoldOnOff(value)
    self.holdOnOff = value
    self:emit("togglesChanged")
end

function Store:toggleHoldOnOff()
    self.holdOnOff = not self.holdOnOff
    self:emit("togglesChanged")
    return self.holdOnOff
end

function Store:setHoldFadeOnOff(value)
    self.holdFadeOnOff = value
    self:emit("togglesChanged")
end

function Store:toggleHoldFadeOnOff()
    self.holdFadeOnOff = not self.holdFadeOnOff
    self:emit("togglesChanged")
    return self.holdFadeOnOff
end

function Store:setSelectedEffect(effectId)
    self.selectedEffect = effectId
    self:emit("selectedEffectChanged", effectId)
end

function Store:getToggles()
    return {
        masterOnOff = self.masterOnOff,
        fadeOnOff = self.fadeOnOff,
        holdOnOff = self.holdOnOff,
        holdFadeOnOff = self.holdFadeOnOff,
    }
end

--------------------------------------------------------------------------------
-- Position management
--------------------------------------------------------------------------------

--- Add a new position
-- @param name string
-- @return table
function Store:addPosition(name)
    local pos = {
        id = "pos_" .. self:generateId(),
        name = name,
    }
    table.insert(self.positions, pos)
    self:emit("positionsChanged", self.positions)
    return pos
end

--- Remove a position by ID
-- @param posId string
function Store:removePosition(posId)
    for i, p in ipairs(self.positions) do
        if p.id == posId then
            table.remove(self.positions, i)
            break
        end
    end
    if self.activePositionId == posId then
        self.activePositionId = nil
    end
    self:emit("positionsChanged", self.positions)
end

--- Rename a position
-- @param posId string
-- @param newName string
function Store:renamePosition(posId, newName)
    for _, p in ipairs(self.positions) do
        if p.id == posId then
            p.name = newName
            break
        end
    end
    self:emit("positionsChanged", self.positions)
end

--- Set the active position
-- @param posId string|nil
function Store:setActivePosition(posId)
    self.activePositionId = posId
    self:emit("activePositionChanged", posId)
end

--- Get the active position
-- @return table|nil
function Store:getActivePosition()
    if not self.activePositionId then return nil end
    for _, p in ipairs(self.positions) do
        if p.id == self.activePositionId then
            return p
        end
    end
    return nil
end

--- Get all positions
-- @return table
function Store:getPositions()
    return self.positions
end

--------------------------------------------------------------------------------
-- Effect Editor
--------------------------------------------------------------------------------

--- Set the effect panel view
-- @param view string - "list" or "editor"
function Store:setEffectPanelView(view)
    self.effectPanelView = view
    self:emit("effectPanelViewChanged", view)
end

--- Initialize editor with a preset or blank frames
-- @param beamCount number - Number of beams per frame
-- @param frameCount number - Number of frames
function Store:initEditorFrames(beamCount, frameCount)
    beamCount = beamCount or 15
    frameCount = frameCount or 24
    self.editorFrames = {}
    for f = 1, frameCount do
        local frame = {}
        for b = 1, beamCount do
            frame[b] = {
                id = b,
                x = 50,
                y = 50,
                iris = 255,
                dimmer = 255,
                hue = 0,
                saturation = 0,
                brightness = 1,
                visible = true,
            }
        end
        self.editorFrames[f] = frame
    end
    self.editorCurrentFrameIndex = 1
    self.editorSelectedBeams = {}
    self.editorUndoStack = {}
    self.editorRedoStack = {}
    self:emit("editorFramesChanged", self.editorFrames)
end

--- Load frames from a preset generator
-- @param frames table - Array of frame tables
function Store:loadEditorFrames(frames)
    self.editorFrames = {}
    for f, frame in ipairs(frames) do
        self.editorFrames[f] = {}
        for b, beam in ipairs(frame) do
            self.editorFrames[f][b] = {
                id = beam.id or b,
                x = beam.x or 50,
                y = beam.y or 50,
                iris = beam.iris or 255,
                dimmer = beam.dimmer or 255,
                hue = beam.hue or 0,
                saturation = beam.saturation or 0,
                brightness = beam.brightness or 1,
                visible = beam.visible ~= false,
            }
        end
    end
    self.editorCurrentFrameIndex = 1
    self.editorSelectedBeams = {}
    self.editorUndoStack = {}
    self.editorRedoStack = {}
    self:emit("editorFramesChanged", self.editorFrames)
end

--- Get the current frame
-- @return table|nil
function Store:getEditorCurrentFrame()
    return self.editorFrames[self.editorCurrentFrameIndex]
end

--- Set the current frame index
-- @param index number
function Store:setEditorCurrentFrameIndex(index)
    if index >= 1 and index <= #self.editorFrames then
        self.editorCurrentFrameIndex = index
        self:emit("editorFrameIndexChanged", index)
    end
end

--- Get frame count
-- @return number
function Store:getEditorFrameCount()
    return #self.editorFrames
end

--- Add a new frame (copy of current)
function Store:addEditorFrame()
    local currentFrame = self:getEditorCurrentFrame()
    if currentFrame then
        local copy = {}
        for _, beam in ipairs(currentFrame) do
            local b = {}
            for k, v in pairs(beam) do
                b[k] = v
            end
            table.insert(copy, b)
        end
        table.insert(self.editorFrames, self.editorCurrentFrameIndex + 1, copy)
        self.editorCurrentFrameIndex = self.editorCurrentFrameIndex + 1
        self:emit("editorFramesChanged", self.editorFrames)
    end
end

--- Duplicate current frame
function Store:duplicateEditorFrame()
    self:addEditorFrame()
end

--- Delete current frame
function Store:deleteEditorFrame()
    if #self.editorFrames > 1 then
        table.remove(self.editorFrames, self.editorCurrentFrameIndex)
        if self.editorCurrentFrameIndex > #self.editorFrames then
            self.editorCurrentFrameIndex = #self.editorFrames
        end
        self:emit("editorFramesChanged", self.editorFrames)
    end
end

--- Push current frame to undo stack
function Store:editorPushUndo()
    local frame = self:getEditorCurrentFrame()
    if frame then
        local snapshot = {}
        for _, beam in ipairs(frame) do
            local b = {}
            for k, v in pairs(beam) do
                b[k] = v
            end
            table.insert(snapshot, b)
        end
        table.insert(self.editorUndoStack, {
            frameIndex = self.editorCurrentFrameIndex,
            data = snapshot,
        })
        -- Clear redo stack on new action
        self.editorRedoStack = {}
    end
end

--- Pop from undo stack
-- @return boolean - Whether undo was successful
function Store:editorUndo()
    if #self.editorUndoStack == 0 then return false end

    -- Save current state to redo stack
    local currentFrame = self:getEditorCurrentFrame()
    if currentFrame then
        local snapshot = {}
        for _, beam in ipairs(currentFrame) do
            local b = {}
            for k, v in pairs(beam) do
                b[k] = v
            end
            table.insert(snapshot, b)
        end
        table.insert(self.editorRedoStack, {
            frameIndex = self.editorCurrentFrameIndex,
            data = snapshot,
        })
    end

    -- Restore from undo
    local entry = table.remove(self.editorUndoStack)
    self.editorFrames[entry.frameIndex] = entry.data
    self.editorCurrentFrameIndex = entry.frameIndex
    self:emit("editorFramesChanged", self.editorFrames)
    return true
end

--- Pop from redo stack
-- @return boolean
function Store:editorRedo()
    if #self.editorRedoStack == 0 then return false end

    -- Save current state to undo stack
    local currentFrame = self:getEditorCurrentFrame()
    if currentFrame then
        local snapshot = {}
        for _, beam in ipairs(currentFrame) do
            local b = {}
            for k, v in pairs(beam) do
                b[k] = v
            end
            table.insert(snapshot, b)
        end
        table.insert(self.editorUndoStack, {
            frameIndex = self.editorCurrentFrameIndex,
            data = snapshot,
        })
    end

    -- Restore from redo
    local entry = table.remove(self.editorRedoStack)
    self.editorFrames[entry.frameIndex] = entry.data
    self.editorCurrentFrameIndex = entry.frameIndex
    self:emit("editorFramesChanged", self.editorFrames)
    return true
end

--- Update a beam in the current frame
-- @param beamIndex number
-- @param properties table
function Store:updateEditorBeam(beamIndex, properties)
    local frame = self:getEditorCurrentFrame()
    if frame and frame[beamIndex] then
        self:editorPushUndo()
        for k, v in pairs(properties) do
            frame[beamIndex][k] = v
        end
        -- If "apply to all frames" is enabled, propagate
        if self.editorApplyToAllFrames then
            for f = 1, #self.editorFrames do
                if f ~= self.editorCurrentFrameIndex and self.editorFrames[f][beamIndex] then
                    for k, v in pairs(properties) do
                        self.editorFrames[f][beamIndex][k] = v
                    end
                end
            end
        end
        self:emit("editorFramesChanged", self.editorFrames)
    end
end

--- Toggle beam selection in the editor
-- @param beamIndex number
function Store:toggleEditorBeamSelection(beamIndex)
    local found = false
    for i, id in ipairs(self.editorSelectedBeams) do
        if id == beamIndex then
            table.remove(self.editorSelectedBeams, i)
            found = true
            break
        end
    end
    if not found then
        table.insert(self.editorSelectedBeams, beamIndex)
    end
    self:emit("editorSelectionChanged", self.editorSelectedBeams)
end

--- Select all beams in current frame
function Store:selectAllEditorBeams()
    local frame = self:getEditorCurrentFrame()
    if frame then
        self.editorSelectedBeams = {}
        for _, beam in ipairs(frame) do
            table.insert(self.editorSelectedBeams, beam.id)
        end
        self:emit("editorSelectionChanged", self.editorSelectedBeams)
    end
end

--- Deselect all beams
function Store:deselectAllEditorBeams()
    self.editorSelectedBeams = {}
    self:emit("editorSelectionChanged", self.editorSelectedBeams)
end

--- Check if a beam is selected
-- @param beamIndex number
-- @return boolean
function Store:isEditorBeamSelected(beamIndex)
    for _, id in ipairs(self.editorSelectedBeams) do
        if id == beamIndex then
            return true
        end
    end
    return false
end

--- Set editor playing state
-- @param playing boolean
function Store:setEditorPlaying(playing)
    self.editorIsPlaying = playing
    self:emit("editorPlayStateChanged", playing)
end

--- Toggle editor loop
function Store:toggleEditorLoop()
    self.editorLoop = not self.editorLoop
    self:emit("editorLoopChanged", self.editorLoop)
end

--- Set editor playback speed
-- @param speed number
function Store:setEditorSpeed(speed)
    self.editorSpeed = math.max(0.25, math.min(4, speed))
    self:emit("editorSpeedChanged", self.editorSpeed)
end

--- Toggle onion skin mode
function Store:toggleEditorOnionSkin()
    self.editorOnionSkin = not self.editorOnionSkin
    self:emit("editorOnionSkinChanged", self.editorOnionSkin)
end

--- Toggle apply to all frames
function Store:toggleEditorApplyToAll()
    self.editorApplyToAllFrames = not self.editorApplyToAllFrames
    self:emit("editorApplyToAllChanged", self.editorApplyToAllFrames)
end

--- Open/close save dialog
-- @param open boolean
function Store:setEditorSaveDialogOpen(open)
    self.editorSaveDialogOpen = open
    self:emit("editorSaveDialogChanged", open)
end

--- Set save dialog name
-- @param name string
function Store:setEditorSaveName(name)
    self.editorSaveName = name
end

--- Set save dialog type
-- @param saveType string
function Store:setEditorSaveType(saveType)
    self.editorSaveType = saveType
end

--- Set save dialog tags
-- @param tags table
function Store:setEditorSaveTags(tags)
    self.editorSaveTags = tags
end

--- Save current effect
-- @return table|nil - The saved effect, or nil on failure
function Store:saveEditorEffect()
    if not self.editorSaveName or #self.editorSaveName == 0 then
        return nil
    end

    local effect = {
        id = "saved_" .. self:generateId(),
        name = self.editorSaveName,
        type = self.editorSaveType,
        tags = {},
        frames = {},
        createdAt = tick(),
        author = self.currentUser.name,
    }

    -- Copy tags
    for _, tag in ipairs(self.editorSaveTags) do
        table.insert(effect.tags, tag)
    end

    -- Deep copy frames
    for _, frame in ipairs(self.editorFrames) do
        local fCopy = {}
        for _, beam in ipairs(frame) do
            local b = {}
            for k, v in pairs(beam) do
                b[k] = v
            end
            table.insert(fCopy, b)
        end
        table.insert(effect.frames, fCopy)
    end

    table.insert(self.savedEffects, effect)
    self:setEditorSaveDialogOpen(false)
    self.editorSaveName = ""
    self.editorSaveType = "movement"
    self.editorSaveTags = {}
    self:emit("effectSaved", effect)
    return effect
end

--- Open/close preset browser
-- @param open boolean
function Store:setEditorPresetBrowserOpen(open)
    self.editorPresetBrowserOpen = open
    self:emit("editorPresetBrowserChanged", open)
end

--------------------------------------------------------------------------------
-- Customisation
--------------------------------------------------------------------------------

--- Set color hue
-- @param hue number (0-360)
function Store:setColorHue(hue)
    self.customisation.colorHue = hue % 360
    self:emit("customisationChanged", self.customisation)
end

--- Set color saturation
-- @param saturation number (0-1)
function Store:setColorSaturation(saturation)
    self.customisation.colorSaturation = math.max(0, math.min(1, saturation))
    self:emit("customisationChanged", self.customisation)
end

--- Set color brightness
-- @param brightness number (0-1)
function Store:setColorBrightness(brightness)
    self.customisation.colorBrightness = math.max(0, math.min(1, brightness))
    self:emit("customisationChanged", self.customisation)
end

--- Set a fader value
-- @param faderId string
-- @param value number (0-255)
function Store:setFaderValue(faderId, value)
    value = math.max(0, math.min(255, math.floor(value)))
    if self.customisation.faders[faderId] ~= nil then
        self.customisation.faders[faderId] = value
        self:emit("customisationChanged", self.customisation)
    end
end

--- Get a fader value
-- @param faderId string
-- @return number
function Store:getFaderValue(faderId)
    return self.customisation.faders[faderId] or 0
end

--- Get all customisation state
-- @return table
function Store:getCustomisation()
    return self.customisation
end

--- Reset all faders to defaults
function Store:resetFaders()
    local defaults = {
        phase = 128, speed = 128, iris = 255, dimmer = 255,
        wing = 128, tilt = 128, pan = 128, brightness = 255, zoom = 128,
    }
    for k, v in pairs(defaults) do
        self.customisation.faders[k] = v
    end
    self.customisation.colorHue = 0
    self.customisation.colorSaturation = 0
    self.customisation.colorBrightness = 1
    self:emit("customisationChanged", self.customisation)
end

--------------------------------------------------------------------------------
-- Keybind management
--------------------------------------------------------------------------------

--- Set a keybind
-- @param category string - "effects", "toggles", "positions"
-- @param itemId string
-- @param key string - Key code string (e.g., "E", "F1", "One")
function Store:setKeybind(category, itemId, key)
    -- Remove any existing keybind with this key (one key = one action)
    for catName, catBinds in pairs(self.keybinds) do
        for bId, bKey in pairs(catBinds) do
            if bKey == key and (catName ~= category or bId ~= itemId) then
                self.keybinds[catName][bId] = nil
            end
        end
    end
    self.keybinds[category][itemId] = key
    self:emit("keybindsChanged", self.keybinds)
end

--- Remove a keybind
-- @param category string
-- @param itemId string
function Store:removeKeybind(category, itemId)
    self.keybinds[category][itemId] = nil
    self:emit("keybindsChanged", self.keybinds)
end

--- Get a keybind
-- @param category string
-- @param itemId string
-- @return string|nil
function Store:getKeybind(category, itemId)
    return self.keybinds[category] and self.keybinds[category][itemId] or nil
end

--- Get total keybind count
-- @return number
function Store:getKeybindCount()
    local count = 0
    for _, catBinds in pairs(self.keybinds) do
        for _ in pairs(catBinds) do
            count = count + 1
        end
    end
    return count
end

--- Get keybind count by category
-- @param category string
-- @return number
function Store:getKeybindCountByCategory(category)
    local count = 0
    if self.keybinds[category] then
        for _ in pairs(self.keybinds[category]) do
            count = count + 1
        end
    end
    return count
end

--- Start recording a keybind
-- @param category string
-- @param itemId string
function Store:startRecordingKeybind(category, itemId)
    self.recordingKeybind = { category = category, itemId = itemId }
    self:emit("keybindRecordingChanged", self.recordingKeybind)
end

--- Cancel keybind recording
function Store:cancelRecordingKeybind()
    self.recordingKeybind = nil
    self:emit("keybindRecordingChanged", nil)
end

--- Finish recording a keybind with the pressed key
-- @param key string
function Store:finishRecordingKeybind(key)
    if self.recordingKeybind then
        self:setKeybind(self.recordingKeybind.category, self.recordingKeybind.itemId, key)
        self.recordingKeybind = nil
        self:emit("keybindRecordingChanged", nil)
    end
end

--- Check if currently recording a keybind
-- @return boolean
function Store:isRecordingKeybind()
    return self.recordingKeybind ~= nil
end

--------------------------------------------------------------------------------
-- Timecode management
--------------------------------------------------------------------------------

--- Create a new timecode project
-- @param name string
-- @param stepCount number
-- @return table
function Store:createTimecodeProject(name, stepCount)
    stepCount = stepCount or 16
    local project = {
        id = "tc_" .. self:generateId(),
        name = name,
        steps = {},
        createdAt = tick(),
    }
    for i = 1, stepCount do
        project.steps[i] = {
            effect = nil,    -- effect preset ID
            position = nil,  -- position ID
            toggles = { master = true, fade = false, hold = false, holdFade = false },
        }
    end
    table.insert(self.timecodeProjects, project)
    self:emit("timecodeProjectsChanged", self.timecodeProjects)
    return project
end

--- Delete a timecode project
-- @param projectId string
function Store:deleteTimecodeProject(projectId)
    for i, p in ipairs(self.timecodeProjects) do
        if p.id == projectId then
            table.remove(self.timecodeProjects, i)
            break
        end
    end
    if self.activeTimecodeId == projectId then
        self.activeTimecodeId = nil
        self.timecodeIsPlaying = false
    end
    self:emit("timecodeProjectsChanged", self.timecodeProjects)
end

--- Set active timecode project
-- @param projectId string|nil
function Store:setActiveTimecodeId(projectId)
    self.activeTimecodeId = projectId
    self.timecodeIsPlaying = false
    self.timecodeCurrentStep = 1
    self:emit("activeTimecodeChanged", projectId)
end

--- Get active timecode project
-- @return table|nil
function Store:getActiveTimecodeProject()
    if not self.activeTimecodeId then return nil end
    for _, p in ipairs(self.timecodeProjects) do
        if p.id == self.activeTimecodeId then
            return p
        end
    end
    return nil
end

--- Update a timecode step
-- @param stepIndex number
-- @param data table - Partial step data to merge
function Store:updateTimecodeStep(stepIndex, data)
    local project = self:getActiveTimecodeProject()
    if project and project.steps[stepIndex] then
        for k, v in pairs(data) do
            project.steps[stepIndex][k] = v
        end
        self:emit("timecodeStepChanged", stepIndex, data)
    end
end

--- Set timecode playing state
-- @param playing boolean
function Store:setTimecodePlaying(playing)
    self.timecodeIsPlaying = playing
    self:emit("timecodePlayStateChanged", playing)
end

--- Set timecode BPM
-- @param bpm number
function Store:setTimecodeBPM(bpm)
    self.timecodeBPM = math.max(60, math.min(200, bpm))
    self:emit("timecodeBPMChanged", self.timecodeBPM)
end

--- Set current timecode step
-- @param step number
function Store:setTimecodeCurrentStep(step)
    self.timecodeCurrentStep = step
    self:emit("timecodeStepChanged", step)
end

--- Toggle timecode loop
function Store:toggleTimecodeLoop()
    self.timecodeLoop = not self.timecodeLoop
    self:emit("timecodeLoopChanged", self.timecodeLoop)
end

--------------------------------------------------------------------------------
-- Hub management
--------------------------------------------------------------------------------

--- Set hub tab
-- @param tab string - "browse" or "my_uploads"
function Store:setHubTab(tab)
    self.hubTab = tab
    self:emit("hubTabChanged", tab)
end

--- Set hub filter
-- @param filter string
function Store:setHubFilter(filter)
    self.hubFilter = filter
    self:emit("hubFilterChanged", filter)
end

--- Set hub search query
-- @param query string
function Store:setHubSearch(query)
    self.hubSearch = query
    self:emit("hubSearchChanged", query)
end

--- Set hub viewing user
-- @param player table|nil
function Store:setHubViewingUser(player)
    self.hubViewingUser = player
    self:emit("hubViewingUserChanged", player)
end

--- Get filtered hub effects
-- @return table
function Store:getFilteredHubEffects()
    local results = {}
    for _, effect in ipairs(self.hubEffects) do
        -- Filter by category
        if self.hubFilter ~= "all" and effect.type ~= self.hubFilter then
            goto continue
        end
        -- Filter by search
        if #self.hubSearch > 0 then
            local searchLower = self.hubSearch:lower()
            if not effect.name:lower():find(searchLower, 1, true)
                and not effect.author:lower():find(searchLower, 1, true) then
                goto continue
            end
        end
        table.insert(results, effect)
        ::continue::
    end
    return results
end

--------------------------------------------------------------------------------
-- Toast system
--------------------------------------------------------------------------------

--- Add a toast notification
-- @param message string
-- @param toastType string - "success", "warning", "error", "info"
-- @return table - The created toast
function Store:addToast(message, toastType)
    toastType = toastType or "success"
    local toast = {
        id = "toast_" .. self._nextToastId,
        message = message,
        type = toastType,
        timestamp = tick(),
    }
    self._nextToastId = self._nextToastId + 1
    table.insert(self.toasts, toast)
    self:emit("toastAdded", toast)

    -- Auto dismiss after 3 seconds
    spawn(function()
        wait(3)
        self:removeToast(toast.id)
    end)

    return toast
end

--- Remove a toast by ID
-- @param toastId string
function Store:removeToast(toastId)
    for i, t in ipairs(self.toasts) do
        if t.id == toastId then
            table.remove(self.toasts, i)
            break
        end
    end
    self:emit("toastRemoved", toastId)
end

--- Get all current toasts
-- @return table
function Store:getToasts()
    return self.toasts
end

--- Clear all toasts
function Store:clearToasts()
    self.toasts = {}
    self:emit("toastsCleared")
end

--------------------------------------------------------------------------------
-- Easter egg
--------------------------------------------------------------------------------

--- Increment easter egg click counter
function Store:incrementEasterEggClick()
    local now = tick()
    if now - self.lastEasterEggClick > 2 then
        -- Reset if clicks are too far apart
        self.easterEggClicks = 1
    else
        self.easterEggClicks = self.easterEggClicks + 1
    end
    self.lastEasterEggClick = now

    if self.easterEggClicks >= 3 then
        self.easterEggVisible = true
        self.easterEggClicks = 0
        self:emit("easterEggTriggered")
    end
end

--- Dismiss the easter egg
function Store:dismissEasterEgg()
    self.easterEggVisible = false
    self:emit("easterEggDismissed")
end

--- Check if easter egg is visible
-- @return boolean
function Store:isEasterEggVisible()
    return self.easterEggVisible
end

--------------------------------------------------------------------------------
-- Profile dropdown
--------------------------------------------------------------------------------

--- Toggle profile dropdown
function Store:toggleProfileDropdown()
    self.profileDropdownOpen = not self.profileDropdownOpen
    self:emit("profileDropdownChanged", self.profileDropdownOpen)
end

--- Close profile dropdown
function Store:closeProfileDropdown()
    self.profileDropdownOpen = false
    self:emit("profileDropdownChanged", false)
end

--- Check if profile dropdown is open
-- @return boolean
function Store:isProfileDropdownOpen()
    return self.profileDropdownOpen
end

--------------------------------------------------------------------------------
-- Save glow animation state
--------------------------------------------------------------------------------

--- Set save glow state
-- @param glow boolean
function Store:setSaveGlow(glow)
    self.saveGlow = glow
    self:emit("saveGlowChanged", glow)
end

--------------------------------------------------------------------------------
-- Utility functions
--------------------------------------------------------------------------------

--- Get session duration in seconds
-- @return number
function Store:getSessionDuration()
    return tick() - self.sessionStartTime
end

--- Format session duration as HH:MM:SS
-- @return string
function Store:getSessionDurationFormatted()
    local totalSeconds = math.floor(self:getSessionDuration())
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

--- Generate a unique ID
-- @return string
function Store:generateId()
    return string.format("%06d", math.random(100000, 999999))
end

--- Deep copy a table
-- @param orig table
-- @return table
function Store:deepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            copy[k] = self:deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

--------------------------------------------------------------------------------
-- Initialization helpers (private)
--------------------------------------------------------------------------------

--- Initialize mock Hub effects
function Store:_initHubEffects()
    local authors = { "Johan", "xLaserKing", "NeonPulse", "BeamRider42", "SpectrumX", "CrystalWave" }
    local types = { "movement", "pattern", "chase", "wave", "custom" }
    local names = {
        "Spiral Dance", "Rainbow Wave", "Strobe Rush", "Fan Sweep", "Pulse Beat",
        "Cross Pattern", "Diamond Chase", "Circle Loop", "V-Spread", "Random Flicker",
        "Bounce Up", "Heart Shape", "Star Burst", "Infinity Loop", "Cascade",
        "Helix Spin",
    }

    self.hubEffects = {}
    -- Use deterministic seed-like behavior with index
    for i, name in ipairs(names) do
        table.insert(self.hubEffects, {
            id = "hub_" .. i,
            name = name,
            author = authors[((i - 1) % #authors) + 1],
            type = types[((i - 1) % #types) + 1],
            downloads = 10 + ((i * 37) % 491),
            codeLines = 5 + ((i * 13) % 21),
            createdAt = 1000 + ((i * 7) % 9000),
        })
    end
end

--- Initialize built-in effects placeholder
function Store:_initBuiltInEffects()
    -- Built-in effects are managed by the EffectPresets module
    -- This is a placeholder for any store-side effect metadata
    self.builtInEffects = {}
end

--- Initialize default groups for demo purposes
function Store:_initDefaultGroups()
    -- No default groups - user creates them
end

return Store
