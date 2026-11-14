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

-- Safe wrappers for Retail 12.0+ secret value checks (unavailable in Classic Era / MoP Classic)
function addonTable:CanAccessValue(val)
    if canaccessvalue then
        return canaccessvalue(val)
    end
    return true
end

function addonTable:CanAccessAllValues(...)
    if canaccessallvalues then
        return canaccessallvalues(...)
    elseif canaccessvalue then
        for i = 1, select("#", ...) do
            if not canaccessvalue(select(i, ...)) then
                return false
            end
        end
    end
    return true
end

-- Helper to check exclusion state
-- Returns: "FULL", "PARTIAL", or nil
function addonTable:GetExclusionState(name)
    if next(self.db.exclusionList) == nil then return nil end
    if not self:CanAccessValue(name) or not name then return nil end
    local lowerName = name:lower()
    for keyword, state in pairs(self.db.exclusionList) do
        if keyword ~= "" and string.find(lowerName, keyword:lower(), 1, true) then
            return state
        end
    end
    return nil
end

local function ApplyGlobalFonts()
    if addonTable.db and addonTable.db.selectedFont then
        local fetchedFont = LSM:Fetch(LSM.MediaType.FONT, addonTable.db.selectedFont, true)
        if fetchedFont then
            DAMAGE_TEXT_FONT = fetchedFont
            UNIT_NAME_FONT = fetchedFont
            STANDARD_TEXT_FONT = fetchedFont
            NAMEPLATE_FONT = fetchedFont
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        self:UnregisterEvent("ADDON_LOADED")

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

        -- Change the global font constants ASAP, and re-apply if a custom font is registered later (e.g. via SharedMedia_MyMedia)
        ApplyGlobalFonts()
        LSM.RegisterCallback(addonTable, "LibSharedMedia_Registered", function(_, mediaType, key)
            if mediaType == LSM.MediaType.FONT and key == addonTable.db.selectedFont then
                ApplyGlobalFonts()
                addonTable:UpdateAllStoredInstances()
            end
        end)

        -- Populate addon properties needed for options
        for key, value in pairs(addonTable.metadata) do
            addonTable.metadata[key] = C_AddOns.GetAddOnMetadata(addonName, value)
        end
        addonTable.initiallySelectedFont = addonTable.db.selectedFont
    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

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
        self:ApplyTextColour(name, fontInstance, false, true)
        self:ApplyFont(name, fontInstance)
        self:ApplySpacing(name, fontInstance)
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
    local spacing = fontInstance:GetSpacing()

    if not self:CanAccessValue(fontFile) then fontFile = nil end
    if not self:CanAccessValue(height) or not height then height = 0 end
    if not self:CanAccessValue(flags) or not flags then flags = "" end
    if not self:CanAccessValue(spacing) or not spacing then spacing = 0 end

    if not self:CanAccessAllValues(textRed, textGreen, textBlue, textAlpha) then
        textRed, textGreen, textBlue, textAlpha = 1, 1, 1, 1
    else
        textRed = textRed or 1
        textGreen = textGreen or 1
        textBlue = textBlue or 1
        textAlpha = textAlpha or 1
    end

    if not self:CanAccessAllValues(shadowRed, shadowGreen, shadowBlue, shadowAlpha) then
        shadowRed, shadowGreen, shadowBlue, shadowAlpha = 0, 0, 0, 1
    else
        shadowRed = shadowRed or 0
        shadowGreen = shadowGreen or 0
        shadowBlue = shadowBlue or 0
        shadowAlpha = shadowAlpha or 1
    end

    if not self:CanAccessAllValues(shadowX, shadowY) then
        shadowX, shadowY = 0, 0
    else
        shadowX = shadowX or 0
        shadowY = shadowY or 0
    end

    -- If this is a FontString inheriting from an already-modified FontObject,
    -- use the FontObject's unmodified originals to avoid applying offsets twice.
    if fontInstance.GetFontObject then
        local fontObject = fontInstance:GetFontObject()
        if self:CanAccessValue(fontObject) and fontObject and not (fontObject.IsForbidden and fontObject:IsForbidden()) then
            local fontObjectName = fontObject:GetName()
            if self:CanAccessValue(fontObjectName) and fontObjectName and self.originalValues[fontObjectName] then
                local parentOrig = self.originalValues[fontObjectName]
                local parentFile, parentHeight, parentFlags = fontObject:GetFont()
                if self:CanAccessAllValues(parentFile, parentHeight, parentFlags) then
                    if not fontFile or fontFile == parentFile then fontFile = parentOrig.file end
                    if height == 0 or (parentHeight and math.abs(height - parentHeight) < 0.05) then height = parentOrig.height end
                    if flags == (parentFlags or "") then flags = parentOrig.flags end
                end
                local parentSpacing = fontObject:GetSpacing()
                if self:CanAccessValue(parentSpacing) and parentSpacing and math.abs(spacing - parentSpacing) < 0.05 then
                    spacing = parentOrig.offsets.spacing
                end
                local parentShadowX, parentShadowY = fontObject:GetShadowOffset()
                if self:CanAccessAllValues(parentShadowX, parentShadowY) and parentShadowX and parentShadowY then
                    if math.abs(shadowX - parentShadowX) < 0.05 then shadowX = parentOrig.offsets.shadow.x end
                    if math.abs(shadowY - parentShadowY) < 0.05 then shadowY = parentOrig.offsets.shadow.y end
                end
            end
        end
    end

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
            spacing = spacing
        }
    }

    return true
end

local function ParseFlags(flagsStr)
    if not flagsStr or flagsStr == "" then
        return false, false, false
    end
    local upper = flagsStr:upper()
    local hasMono = string.find(upper, "MONOCHROME", 1, true) ~= nil
    local hasThick = string.find(upper, "THICKOUTLINE", 1, true) ~= nil
    local hasOutline = false
    if upper == "OUTLINE"
        or string.find(upper, "^OUTLINE%s*,") ~= nil
        or string.find(upper, ",%s*OUTLINE%s*,") ~= nil
        or string.find(upper, ",%s*OUTLINE$") ~= nil then
        hasOutline = true
    end
    return hasMono, hasOutline, hasThick
end

function addonTable:ApplyFont(name, fontInstance)
    local state = self:GetExclusionState(name)
    if state == "FULL" then return end

    local selectedFont = self.db.selectedFont
    local specific = self.db.specific[name]
    local disabled = specific and specific.disabled or {}

    -- Font
    local fontToUse
    if disabled.font then
        fontToUse = self.originalValues[name].file
    elseif specific and specific.font then
        fontToUse = LSM:Fetch(LSM.MediaType.FONT, specific.font)
    elseif selectedFont then
        fontToUse = LSM:Fetch(LSM.MediaType.FONT, selectedFont)
    else
        fontToUse = self.originalValues[name].file
    end
    if not fontToUse then return end

    -- Height
    local originalHeight = self.originalValues[name].height
    if not originalHeight or originalHeight <= 0 then
        -- Fallback to a sensible default (happens with Clique's dropdowns for example)
        originalHeight = 12
    end

    local newHeight
    if state == "PARTIAL" or disabled.height then
        -- In PARTIAL mode, we preserve the original height (or whatever was set by the game)
        newHeight = originalHeight
    elseif specific and specific.height then
        newHeight = specific.height
    else
        newHeight = math.max(originalHeight + self.db.offsets.height, 0.5)
    end
    if not newHeight or newHeight <= 0 then return end

    -- Flags
    local newFlags
    if state == "PARTIAL" or disabled.flags then
        -- In PARTIAL mode, we preserve the original flags
        newFlags = self.originalValues[name].flags
    elseif specific and specific.flags then
        newFlags = specific.flags
    else
        local hasMono, hasOutline, hasThick = ParseFlags(self.originalValues[name].flags)
        local dbFlags = self.db.flags

        if dbFlags.MONOCHROME ~= false then hasMono = dbFlags.MONOCHROME == true end
        if dbFlags.OUTLINE ~= false then hasOutline = dbFlags.OUTLINE == true end
        if dbFlags.THICKOUTLINE ~= false then hasThick = dbFlags.THICKOUTLINE == true end

        -- Outlines exclusions for dark text (only check GetTextColor when an outline is actually active)
        if hasOutline or hasThick then
            local r, g, b = fontInstance:GetTextColor()
            if self:CanAccessAllValues(r, g, b) and r and g and b then
                local luminance = (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
                if luminance < 0.2 then
                    hasOutline = false
                    hasThick = false
                end
            end
        end

        if hasMono then
            if hasOutline then
                newFlags = hasThick and "MONOCHROME, OUTLINE, THICKOUTLINE" or "MONOCHROME, OUTLINE"
            else
                newFlags = hasThick and "MONOCHROME, THICKOUTLINE" or "MONOCHROME"
            end
        elseif hasOutline then
            newFlags = hasThick and "OUTLINE, THICKOUTLINE" or "OUTLINE"
        else
            newFlags = hasThick and "THICKOUTLINE" or ""
        end
    end

    -- Skip calling SetFont if the instance already has the target font, height, and flags.
    -- Calling SetFont directly on a child FontString overrides its dynamic FontObject inheritance
    -- (for example, preventing Blizzard_ObjectiveTracker line text from scaling immediately when
    -- ObjectiveTrackerLineFont's height is updated).
    local currentFile, currentHeight, currentFlags = fontInstance:GetFont()
    if self:CanAccessAllValues(currentFile, currentFlags) then
        -- Handle flag normalization (Game might return nil for empty string)
        local flagsMatch = (currentFlags or "") == (newFlags or "")
        -- Handle file normalization (Case insensitive and backslash/slash agnostic usually best, but simple check first)
        local fileMatch = (currentFile == fontToUse)
        if not self:CanAccessValue(currentHeight) then
            -- If currentHeight is a secret value (e.g. Blizzard_CombatText scaling), don't clobber it if font and flags already match
            if fileMatch and flagsMatch then
                return
            end
        elseif currentHeight and (math.abs(currentHeight - newHeight) < 0.05) and fileMatch and flagsMatch then
            return -- The font is already correct. Don't touch it.
        end
    end

    self.isUpdating = true
    pcall(fontInstance.SetFont, fontInstance, fontToUse, newHeight, newFlags)
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
    pcall(fontInstance.SetSpacing, fontInstance, spacing)
    self.isUpdating = false
end

local function ApplyColour(self, name, fontInstance, colourKey, setterMethod, shouldRevert)
    local colourSettings = self.db.colours[colourKey]
    local specific = self.db.specific[name]
    local disabled = specific and specific.disabled
    local hasSpecific = specific and specific[colourKey]
    local isDisabled = disabled and disabled[colourKey]

    if not shouldRevert and not isDisabled and not hasSpecific and not colourSettings.isEnabled then
        return
    end

    local originalColour = self.originalValues[name].colours[colourKey]
    self.isUpdating = true
    if shouldRevert or isDisabled then
        pcall(setterMethod, fontInstance, originalColour.r, originalColour.g, originalColour.b, originalColour.a)
    elseif hasSpecific then
        pcall(setterMethod, fontInstance, hasSpecific.r, hasSpecific.g, hasSpecific.b, hasSpecific.a)
    elseif colourSettings.isEnabled then
        if self:CanAccessValue(originalColour.a) then
            local originalAlpha = originalColour.a or 1
            local finalAlpha = math.min(colourSettings.a, originalAlpha)
            pcall(setterMethod, fontInstance, colourSettings.r, colourSettings.g, colourSettings.b, finalAlpha)
        else
            pcall(setterMethod, fontInstance, colourSettings.r, colourSettings.g, colourSettings.b, colourSettings.a)
        end
    end
    self.isUpdating = false
end

function addonTable:ApplyTextColour(name, fontInstance, shouldRevert, skipFontUpdate)
    local state = self:GetExclusionState(name)
    if state == "FULL" or state == "PARTIAL" then return end

    ApplyColour(self, name, fontInstance, "text", fontInstance.SetTextColor, shouldRevert)

    -- Re-evaluate dark-text outline exclusion only when RGB changed and an outline could be active
    if not skipFontUpdate then
        local origFlags = self.originalValues[name].flags
        local specific = self.db.specific[name]
        local specFlags = specific and specific.flags
        if self.db.flags.OUTLINE or self.db.flags.THICKOUTLINE
            or (origFlags and origFlags ~= "" and string.find(origFlags, "OUTLINE", 1, true))
            or (specFlags and specFlags ~= "" and string.find(specFlags, "OUTLINE", 1, true)) then
            self:ApplyFont(name, fontInstance)
        end
    end
end

function addonTable:ApplyShadowColour(name, fontInstance, shouldRevert)
    local state = self:GetExclusionState(name)
    if state == "FULL" or state == "PARTIAL" then return end

    ApplyColour(self, name, fontInstance, "shadow", fontInstance.SetShadowColor, shouldRevert)
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
    pcall(fontInstance.SetShadowOffset, fontInstance, newX, newY)
    self.isUpdating = false
end
