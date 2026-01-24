local addonName, addonTable = ...
local LSM = LibStub("LibSharedMedia-3.0")

addonTable.metadata = {
    TITLE = "Title",
    LOGO_PATH = "IconTexture",
    DESCRIPTION = "Notes"
}
addonTable.originalFonts = {}
addonTable.isUpdating = false -- Allows us to update fonts without triggering callbacks
addonTable.initiallySelectedFont = nil
-- Does not contain flags (need special handling because of possible nil values)
addonTable.databaseDefaults = {
    selectedFont = nil,
    excludeNameplates = false,
    offsets = { height = 0, spacing = 0, shadow = { x = 0, y = 0 } },
    colours = {
        text = { isEnabled = false, r = 215 / 255, g = 151 / 255, b = 67 / 255, a = 1 },
        shadow = { isEnabled = false, r = 0, g = 0, b = 0, a = 1 }
    },
    forceIndent = false,
}

local areConstantsApplied = false
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    -- Change the following constants ASAP, otherwise it will not apply
    if not areConstantsApplied and FontmancerDB and FontmancerDB.global and FontmancerDB.global.selectedFont then
        local fetchedFont = LSM:Fetch(LSM.MediaType.FONT, FontmancerDB.global.selectedFont)
        DAMAGE_TEXT_FONT = fetchedFont
        UNIT_NAME_FONT = fetchedFont
        STANDARD_TEXT_FONT = fetchedFont
        NAMEPLATE_FONT = fetchedFont
        areConstantsApplied = true
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
        addonTable.initialExcludeNameplates = addonTable.db.excludeNameplates
    elseif event == "PLAYER_LOGIN" then
        addonTable:ReplaceAllFonts()
        addonTable:HookCallbacks()

        addonTable:CreateOptionsPanel()
        addonTable:CreateAdvancedOptionsPanel()
        addonTable:InitialiseInspector()
    end
end)

function addonTable:ReplaceAllFonts(revertingFunction)
    local fonts = GetFonts()

    if not revertingFunction then
        for _, fontName in ipairs(fonts) do
            local font = _G[fontName]
            if font then
                self:StoreOriginals(fontName, font)
            end
        end
    end

    for _, fontName in ipairs(fonts) do
        self:ReplaceFont(fontName, revertingFunction)
    end
end

function addonTable:ReplaceFont(fontName, revertingFunction)
    local font = _G[fontName]
    local isExcluded = self.db.excludeNameplates and string.find(fontName:lower(), "nameplate")
    if not font or isExcluded then return end

    if revertingFunction then
        revertingFunction(self, fontName, font, true)
    else
        self:StoreOriginals(fontName, font)
        self:ApplyFont(fontName, font)
        self:ApplySpacing(fontName, font)
        self:ApplyTextColour(fontName, font)
        self:ApplyShadowColour(fontName, font)
        self:ApplyShadowOffset(fontName, font)
    end
end

function addonTable:StoreOriginals(fontName, font)
    if self.originalFonts[fontName] then return end

    local _, height, flags = font:GetFont()
    local textRed, textGreen, textBlue, textAlpha = font:GetTextColor()
    local shadowRed, shadowGreen, shadowBlue, shadowAlpha = font:GetShadowColor()
    local shadowX, shadowY = font:GetShadowOffset()

    self.originalFonts[fontName] = {
        colours = {
            text = { r = textRed, g = textGreen, b = textBlue, a = textAlpha },
            shadow = { r = shadowRed, g = shadowGreen, b = shadowBlue, a = shadowAlpha }
        },
        flags = flags,
        height = height,
        offsets = {
            shadow = { x = shadowX, y = shadowY },
            spacing = font:GetSpacing()
        }
    }
end

function addonTable:ApplyFont(fontName, font)
    local selectedFont = self.db.selectedFont
    if not selectedFont then return end

    local fetchedFont = LSM:Fetch(LSM.MediaType.FONT, selectedFont)
    local newHeight = math.max(self.originalFonts[fontName].height + self.db.offsets.height, 0.5)

    local newFlagsSplit = {}
    for flagName, flagState in pairs(self.db.flags) do
        -- Apply the flag if the box is checked, or unchecked but in the original values
        -- If greyed out, don't add it
        if flagState or (flagState == false and string.find(self.originalFonts[fontName].flags, flagName)) then
            table.insert(newFlagsSplit, flagName)
        end
    end
    local newFlags = table.concat(newFlagsSplit, ", ")

    self.isUpdating = true
    font:SetFont(fetchedFont, newHeight, newFlags)
    self.isUpdating = false
end

function addonTable:ApplySpacing(fontName, font)
    self.isUpdating = true
    font:SetSpacing(self.originalFonts[fontName].offsets.spacing + self.db.offsets.spacing)
    self.isUpdating = false
end

function addonTable:ApplyTextColour(fontName, font, shouldRevert)
    local colourSettings = self.db.colours.text

    self.isUpdating = true
    if shouldRevert then
        local originalColour = self.originalFonts[fontName].colours.text
        font:SetTextColor(originalColour.r, originalColour.g, originalColour.b, originalColour.a)
    elseif colourSettings.isEnabled then
        -- Use alpha as a cap instead of a direct override to prevent hidden text from becoming visible
        local originalAlpha = self.originalFonts[fontName].colours.text.a or 1
        local finalAlpha = math.min(colourSettings.a, originalAlpha)
        font:SetTextColor(colourSettings.r, colourSettings.g, colourSettings.b, finalAlpha)
    end
    self.isUpdating = false
end

function addonTable:ApplyShadowColour(fontName, font, shouldRevert)
    local colourSettings = self.db.colours.shadow

    self.isUpdating = true
    if shouldRevert then
        local originalColour = self.originalFonts[fontName].colours.shadow
        font:SetShadowColor(originalColour.r, originalColour.g, originalColour.b, originalColour.a)
    elseif colourSettings.isEnabled then
        -- Use alpha as a cap instead of a direct override to prevent hidden text from becoming visible
        local originalAlpha = self.originalFonts[fontName].colours.shadow.a or 1
        local finalAlpha = math.min(colourSettings.a, originalAlpha)
        font:SetShadowColor(colourSettings.r, colourSettings.g, colourSettings.b, finalAlpha)
    end
    self.isUpdating = false
end

function addonTable:ApplyShadowOffset(fontName, font)
    local original = self.originalFonts[fontName]
    local newX = original.offsets.shadow.x + self.db.offsets.shadow.x
    local newY = original.offsets.shadow.y + self.db.offsets.shadow.y
    self.isUpdating = true
    font:SetShadowOffset(newX, newY)
    self.isUpdating = false
end
