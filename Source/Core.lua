local addonName, addonTable = ...
local LSM = LibStub("LibSharedMedia-3.0")

addonTable.metadata = {
    TITLE = "Title",
    LOGO_PATH = "IconTexture",
    DESCRIPTION = "Notes"
}
addonTable.databaseDefaults = {
    selectedFont = nil,
    enableHooks = true,
    exclusionList = {},
    -- Flags would be here, but purposefully missing (need special handling because of possible nil values)
    offsets = { height = 0, spacing = 0, shadow = { x = 0, y = 0 } },
    colours = {
        text = { isEnabled = false, r = 215 / 255, g = 151 / 255, b = 67 / 255, a = 1 },
        shadow = { isEnabled = false, r = 0, g = 0, b = 0, a = 1 }
    },
    forceIndent = false,
    specific = {}             -- Stores per-font overrides
}
addonTable.isUpdating = false -- Allows us to update fonts without triggering callbacks
addonTable.originalValues = {}

-- Helper to check exclusion state
-- Returns: "FULL", "PARTIAL", or nil
function addonTable:GetExclusionState(name)
    if not name then return nil end
    for keyword, state in pairs(self.db.exclusionList) do
        if keyword ~= "" and string.find(name, keyword) then
            return state
        end
    end
    return nil
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    -- Change the following constants ASAP, otherwise it will not apply
    -- TODO Applying once on first load event does not work, figure out how to optimise
    if FontmancerDB and FontmancerDB.global and FontmancerDB.global.selectedFont then
        local fetchedFont = LSM:Fetch(LSM.MediaType.FONT, FontmancerDB.global.selectedFont)
        DAMAGE_TEXT_FONT = fetchedFont
        UNIT_NAME_FONT = fetchedFont
        STANDARD_TEXT_FONT = fetchedFont
        NAMEPLATE_FONT = fetchedFont
    end

    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialise from defaults if missing
        FontmancerDB = FontmancerDB or {}
        FontmancerDB.global = FontmancerDB.global or {}
        addonTable.db = FontmancerDB.global
        local function CopyDefaults(defaultValues, savedValues)
            if type(defaultValues) ~= "table" or type(savedValues) ~= "table" then return end

            for k, v in pairs(defaultValues) do
                if type(v) == "table" then
                    -- If the key doesn't exist in dest, copy the whole table
                    if savedValues[k] == nil then
                        savedValues[k] = CopyTable(v)
                    else
                        -- If it exists, recurse (or replace if it's not a table somehow)
                        if type(savedValues[k]) == "table" then
                            CopyDefaults(v, savedValues[k])
                        else
                            savedValues[k] = CopyTable(v)
                        end
                    end
                else
                    -- If value is not a table, just copy if missing
                    if savedValues[k] == nil then
                        savedValues[k] = v
                    end
                end
            end
        end
        CopyDefaults(addonTable.databaseDefaults, addonTable.db)
        if addonTable.db.flags == nil then
            -- false = Default, true = Force On, nil = Force Off
            addonTable.db.flags = { MONOCHROME = false, OUTLINE = false, THICKOUTLINE = false }
        end

        -- Populate addon properties needed for options
        for key, value in pairs(addonTable.metadata) do
            addonTable.metadata[key] = C_AddOns.GetAddOnMetadata(addonName, value)
        end
        addonTable.initiallySelectedFont = addonTable.db.selectedFont
    elseif event == "PLAYER_LOGIN" then
        local fadeTooltip = addonTable:CreateFadeTooltip()
        addonTable:CreateOptionsPanel(fadeTooltip)
        -- addonTable:CreateAdvancedOptionsPanel(fadeTooltip)

        -- Apply settings to all fonts
        -- Must be done in 2 separate loops to ensure all original values are stored before any updates are applied
        -- Otherwise we might end up with some fonts using already modified values as "originals"
        local fonts = GetFonts()
        for _, fontName in ipairs(fonts) do
            local font = _G[fontName]
            if font then
                addonTable:StoreOriginals(fontName, font)
            end
        end
        for _, fontName in ipairs(fonts) do
            local font = _G[fontName]
            if font then
                addonTable:UpdateInstance(fontName)
            end
        end

        addonTable:HookCallbacks()
    end
end)

function addonTable:UpdateAllStoredInstances(revertingFunction)
    for name, _ in pairs(self.originalValues) do
        self:UpdateInstance(name, revertingFunction)
    end
end

function addonTable:UpdateInstance(name, revertingFunction)
    local fontInstance = self.originalValues[name].instance

    local state = self:GetExclusionState(name)
    if not fontInstance or state == "FULL" then return end

    if revertingFunction then
        revertingFunction(self, name, fontInstance, true)
    else
        self:StoreOriginals(name, fontInstance)
        self:ApplyFont(name, fontInstance)
        self:ApplySpacing(name, fontInstance)
        self:ApplyTextColour(name, fontInstance)
        self:ApplyShadowColour(name, fontInstance)
        self:ApplyShadowOffset(name, fontInstance)
    end
end

function addonTable:StoreOriginals(name, fontInstance)
    if self.originalValues[name] then return false end

    local fontFile, height, flags = fontInstance:GetFont()
    local textRed, textGreen, textBlue, textAlpha = fontInstance:GetTextColor()
    local shadowRed, shadowGreen, shadowBlue, shadowAlpha = fontInstance:GetShadowColor()
    local shadowX, shadowY = fontInstance:GetShadowOffset()

    self.originalValues[name] = {
        instance = fontInstance,
        file = fontFile,
        colours = {
            text = { r = textRed, g = textGreen, b = textBlue, a = textAlpha },
            shadow = { r = shadowRed, g = shadowGreen, b = shadowBlue, a = shadowAlpha }
        },
        flags = flags,
        height = height,
        offsets = {
            shadow = { x = shadowX, y = shadowY },
            spacing = fontInstance:GetSpacing()
        }
    }

    return true
end

function addonTable:ApplyFont(name, fontInstance)
    local state = self:GetExclusionState(name)
    if state == "FULL" then return end

    local selectedFont = self.db.selectedFont
    if not selectedFont then return end

    local specific = self.db.specific[name]
    local disabled = specific and specific.disabled or {}

    -- Font
    local fontToUse
    if disabled.font then
        fontToUse = self.originalValues[name].file
    elseif specific and specific.font then
        fontToUse = LSM:Fetch(LSM.MediaType.FONT, specific.font)
    else
        fontToUse = LSM:Fetch(LSM.MediaType.FONT, selectedFont)
    end

    -- Height
    local newHeight
    if state == "PARTIAL" or disabled.height then
        -- In PARTIAL mode, we preserve the original height (or whatever was set by the game)
        newHeight = self.originalValues[name].height
    elseif specific and specific.height then
        newHeight = specific.height
    else
        local originalHeight = self.originalValues[name].height
        if originalHeight == 0 then
            -- Fallback to a sensible default (happens with Clique's dropdowns for example)
            originalHeight = 12
        end
        newHeight = math.max(originalHeight + self.db.offsets.height, 0.5)
    end

    -- Flags
    local newFlags
    if state == "PARTIAL" or disabled.flags then
        -- In PARTIAL mode, we preserve the original flags
        newFlags = self.originalValues[name].flags
    elseif specific and specific.flags then
        newFlags = specific.flags
    else
        local activeFlags = {}
        local originalFlags = self.originalValues[name].flags or ""

        -- Parse original flags into a set
        for flag in string.gmatch(originalFlags, "[^,]+") do
            flag = flag:match("^%s*(.-)%s*$") -- Trim whitespace
            if flag and flag ~= "" then
                activeFlags[flag:upper()] = true
            end
        end

        -- Apply overrides using a KNOWN list of flags
        for _, flagName in ipairs({ "MONOCHROME", "OUTLINE", "THICKOUTLINE" }) do
            local flagState = self.db.flags[flagName]

            if flagState == true then
                activeFlags[flagName] = true
            elseif flagState == nil then
                activeFlags[flagName] = nil
            end
        end

        -- Outlines exclusions
        local r, g, b = fontInstance:GetTextColor()
        if canaccessvalue(r) and canaccessvalue(g) and canaccessvalue(b) then
            local luminance = (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
            if luminance < 0.2 then
                activeFlags["OUTLINE"] = nil
                activeFlags["THICKOUTLINE"] = nil
            end
        end

        -- Rebuild the comma-separated string
        local newFlagsSplit = {}
        for flag in pairs(activeFlags) do
            table.insert(newFlagsSplit, flag)
        end
        table.sort(newFlagsSplit)
        newFlags = table.concat(newFlagsSplit, ", ")
    end

    -- TODO: figure out why that works in letting objective text scale immediately
    local currentFile, currentHeight, currentFlags = fontInstance:GetFont()
    -- Handle floating point precision for height
    local heightMatch = (math.abs(currentHeight - newHeight) < 0.05)
    -- Handle flag normalization (Game might return nil for empty string)
    local flagsMatch = (currentFlags or "") == (newFlags or "")
    -- Handle file normalization (Case insensitive and backslash/slash agnostic usually best, but simple check first)
    local fileMatch = (currentFile == fontToUse)
    if fileMatch and heightMatch and flagsMatch then
        return -- The font is already correct. Don't touch it.
    end

    self.isUpdating = true
    fontInstance:SetFont(fontToUse, newHeight, newFlags)
    self.isUpdating = false
end

function addonTable:ApplySpacing(name, fontInstance)
    local state = self:GetExclusionState(name)
    if state == "FULL" or state == "PARTIAL" then return end

    local specific = self.db.specific[name]
    local disabled = specific and specific.disabled or {}
    local spacing

    if disabled.spacing then
        spacing = self.originalValues[name].offsets.spacing
    elseif specific and specific.spacing then
        spacing = specific.spacing
    else
        spacing = self.originalValues[name].offsets.spacing + self.db.offsets.spacing
    end

    self.isUpdating = true
    fontInstance:SetSpacing(spacing)
    self.isUpdating = false
end

function addonTable:ApplyTextColour(name, fontInstance, shouldRevert)
    local state = self:GetExclusionState(name)
    if state == "FULL" or state == "PARTIAL" then return end

    local colourSettings = self.db.colours.text
    local specific = self.db.specific[name]
    local disabled = specific and specific.disabled or {}

    self.isUpdating = true
    if shouldRevert or disabled.text then
        local originalColour = self.originalValues[name].colours.text
        fontInstance:SetTextColor(originalColour.r, originalColour.g, originalColour.b, originalColour.a)
    elseif specific and specific.text then
        local s = specific.text
        fontInstance:SetTextColor(s.r, s.g, s.b, s.a)
    elseif colourSettings.isEnabled then
        if canaccessvalue(self.originalValues[name].colours.text.a) then
            local originalAlpha = self.originalValues[name].colours.text.a or 1
            local finalAlpha = math.min(colourSettings.a, originalAlpha)
            fontInstance:SetTextColor(colourSettings.r, colourSettings.g, colourSettings.b, finalAlpha)
        else
            fontInstance:SetTextColor(colourSettings.r, colourSettings.g, colourSettings.b, colourSettings.a)
        end
    end
    self.isUpdating = false

    -- This ensures that if a FontString becomes dark, the outline is removed
    self:ApplyFont(name, fontInstance)
end

function addonTable:ApplyShadowColour(name, fontInstance, shouldRevert)
    local state = self:GetExclusionState(name)
    if state == "FULL" or state == "PARTIAL" then return end

    local colourSettings = self.db.colours.shadow
    local specific = self.db.specific[name]
    local disabled = specific and specific.disabled or {}

    self.isUpdating = true
    if shouldRevert or disabled.shadow then
        local originalColour = self.originalValues[name].colours.shadow
        fontInstance:SetShadowColor(originalColour.r, originalColour.g, originalColour.b, originalColour.a)
    elseif specific and specific.shadow then
        local s = specific.shadow
        fontInstance:SetShadowColor(s.r, s.g, s.b, s.a)
    elseif colourSettings.isEnabled then
        if canaccessvalue(self.originalValues[name].colours.shadow.a) then
            local originalAlpha = self.originalValues[name].colours.shadow.a or 1
            local finalAlpha = math.min(colourSettings.a, originalAlpha)
            fontInstance:SetShadowColor(colourSettings.r, colourSettings.g, colourSettings.b, finalAlpha)
        else
            fontInstance:SetShadowColor(colourSettings.r, colourSettings.g, colourSettings.b, colourSettings.a)
        end
    end
    self.isUpdating = false
end

function addonTable:ApplyShadowOffset(name, fontInstance)
    local state = self:GetExclusionState(name)
    if state == "FULL" or state == "PARTIAL" then return end

    local original = self.originalValues[name]
    local specific = self.db.specific[name]
    local disabled = specific and specific.disabled or {}

    local newX, newY
    if disabled.shadowX then
        newX = original.offsets.shadow.x
    elseif specific and specific.shadowX then
        newX = specific.shadowX
    else
        newX = original.offsets.shadow.x + self.db.offsets.shadow.x
    end

    if disabled.shadowY then
        newY = original.offsets.shadow.y
    elseif specific and specific.shadowY then
        newY = specific.shadowY
    else
        newY = original.offsets.shadow.y + self.db.offsets.shadow.y
    end

    self.isUpdating = true
    fontInstance:SetShadowOffset(newX, newY)
    self.isUpdating = false
end
