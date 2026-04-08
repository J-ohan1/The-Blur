-- ProfanityFilter.lua - Content filtering for text inputs
-- Provides comprehensive profanity detection with leet-speak bypass prevention
-- Used for effect names, group names, save names, and any user-generated text

local ProfanityFilter = {}

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

--- Maximum text length for filtering (prevents extremely long strings)
ProfanityFilter.MAX_LENGTH = 200

--------------------------------------------------------------------------------
-- Blocked words list (comprehensive)
--------------------------------------------------------------------------------
local blockedWords = {
    -- Sexual content
    "sex", "porn", "nsfw", "nude", "naked", "erotic", "xxx",
    "hentai", "orgy", "penis", "vagina", "genitals",

    -- Profanity
    "fuck", "shit", "damn", "ass", "bitch", "bastard", "crap",
    "dick", "cock", "pussy", "cunt", "twat", "wanker",
    "bollocks", "arse", "bugger", "feck",

    -- Slurs and hate speech
    "nigger", "nigga", "niggr", "fag", "faggot", "faggit",
    "retard", "retarded", "tranny", "shemale",

    -- Self-harm references
    "kill myself", "suicide", "kms", "end my life",
    "selfharm", "self harm", "cut myself",

    -- Drugs
    "weed", "cocaine", "heroin", "meth", "drugs",
    "lsd", "ecstasy", "mdma", "crack",

    -- Hate speech markers
    "hitler", "nazi", "swastika", "genocide", "holocaust",

    -- Cheating/exploiting (game-specific)
    "exploit", "hack", "cheat", "script",
    -- Note: "script" may need to be removed if used in legitimate UI contexts

    -- Spam / advertising markers
    "free robux", "freerobux", "get robux",
    "robux generator", "roblox hack",
}

--------------------------------------------------------------------------------
-- Leet speak replacement table
--------------------------------------------------------------------------------
local leetPatterns = {
    ["0"] = "o", ["1"] = "i", ["3"] = "e", ["4"] = "a",
    ["5"] = "s", ["7"] = "t", ["8"] = "b", ["@"] = "a",
    ["$"] = "s", ["!"] = "i", ["|"] = "l", ["_"] = " ",
    ["-"] = " ", ["+"] = "t", ["9"] = "g", ["6"] = "g",
}

--------------------------------------------------------------------------------
-- Internal helpers
--------------------------------------------------------------------------------

--- Remove common leet speak substitutions from text
-- @param text string
-- @return string
local function deLeet(text)
    text = text:lower()
    for leet, normal in pairs(leetPatterns) do
        text = text:gsub(leet, normal)
    end
    return text
end

--- Remove all non-alphabetic characters (for fuzzy matching)
-- @param text string
-- @return string
local function alphaOnly(text)
    return text:lower():gsub("[^%a]", "")
end

--- Normalize whitespace
-- @param text string
-- @return string
local function normalizeSpaces(text)
    return text:lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Check if text contains any blocked content
-- @param text string - Text to check
-- @return boolean - true if clean (no blocked content found)
function ProfanityFilter.isClean(text)
    if not text or type(text) ~= "string" then
        return false
    end

    -- Truncate to prevent regex DoS on extremely long strings
    if #text > ProfanityFilter.MAX_LENGTH then
        text = text:sub(1, ProfanityFilter.MAX_LENGTH)
    end

    local normalized = normalizeSpaces(text)

    -- Check 1: Direct substring match (normalized)
    for _, word in ipairs(blockedWords) do
        if normalized:find(word, 1, true) then
            return false
        end
    end

    -- Check 2: Leet speak deobfuscation
    local cleaned = deLeet(normalized)
    for _, word in ipairs(blockedWords) do
        if cleaned:find(word, 1, true) then
            return false
        end
    end

    -- Check 3: Alpha-only fuzzy match (catches "f.u.c.k" etc.)
    local alpha = alphaOnly(text)
    for _, word in ipairs(blockedWords) do
        local wordAlpha = alphaOnly(word)
        if #wordAlpha >= 4 and alpha:find(wordAlpha, 1, true) then
            return false
        end
    end

    -- Check 4: Reversed text (catches "kcuf" etc.)
    local reversed = string.reverse(alphaOnly(text))
    for _, word in ipairs(blockedWords) do
        local wordAlpha = alphaOnly(word)
        if #wordAlpha >= 4 and reversed:find(wordAlpha, 1, true) then
            return false
        end
    end

    return true
end

--- Get the first offending word found (for user feedback)
-- @param text string
-- @return string|nil - The offending word, or nil if clean
function ProfanityFilter.findOffense(text)
    if not text or type(text) ~= "string" then
        return "invalid"
    end

    if #text > ProfanityFilter.MAX_LENGTH then
        text = text:sub(1, ProfanityFilter.MAX_LENGTH)
    end

    local normalized = normalizeSpaces(text)

    for _, word in ipairs(blockedWords) do
        if normalized:find(word, 1, true) then
            return word
        end
    end

    local cleaned = deLeet(normalized)
    for _, word in ipairs(blockedWords) do
        if cleaned:find(word, 1, true) then
            return word
        end
    end

    return nil
end

--- Validate a name (e.g., effect name, group name, save name)
-- @param text string
-- @param minLength number (default 2)
-- @param maxLength number (default 30)
-- @return boolean - true if valid
-- @return string|nil - Error message if invalid
function ProfanityFilter.validateName(text, minLength, maxLength)
    minLength = minLength or 2
    maxLength = maxLength or 30

    -- Check type
    if not text or type(text) ~= "string" then
        return false, "Name must be a valid text string"
    end

    -- Trim whitespace
    text = text:match("^%s*(.-)%s*$")

    -- Check length
    if #text < minLength then
        return false, "Name must be at least " .. minLength .. " characters"
    end

    if #text > maxLength then
        return false, "Name must be " .. maxLength .. " characters or fewer"
    end

    -- Check for only whitespace
    if #text:gsub("%s", "") == 0 then
        return false, "Name cannot be empty or whitespace only"
    end

    -- Only allow alphanumeric, spaces, hyphens, underscores, and periods
    if not text:match("^[%w%s%.%-%_]+$") then
        return false, "Name can only contain letters, numbers, spaces, hyphens, underscores, and periods"
    end

    -- Must start with a letter or number
    if not text:match("^[%w]") then
        return false, "Name must start with a letter or number"
    end

    -- Profanity check
    if not ProfanityFilter.isClean(text) then
        return false, "Name contains inappropriate content"
    end

    return true, nil
end

--- Validate generic text input (less strict than name validation)
-- @param text string
-- @param maxLength number (default 100)
-- @return boolean
-- @return string|nil
function ProfanityFilter.validateText(text, maxLength)
    maxLength = maxLength or 100

    if not text or type(text) ~= "string" then
        return false, "Invalid text input"
    end

    text = text:match("^%s*(.-)%s*$")

    if #text == 0 then
        return false, "Text cannot be empty"
    end

    if #text > maxLength then
        return false, "Text must be " .. maxLength .. " characters or fewer"
    end

    if not ProfanityFilter.isClean(text) then
        return false, "Text contains inappropriate content"
    end

    return true, nil
end

--- Sanitize text by replacing offensive words with asterisks
-- @param text string
-- @return string
function ProfanityFilter.sanitize(text)
    if not text or type(text) ~= "string" then
        return ""
    end

    local result = text
    for _, word in ipairs(blockedWords) do
        -- Use pattern-safe escaping
        local escaped = word:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
        result = result:gsub("(" .. escaped .. ")", string.rep("*", #word))
    end

    return result
end

return ProfanityFilter
