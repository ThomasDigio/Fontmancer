local addonName = ...
local AceAddon = LibStub("AceAddon-3.0")
local AceDB = LibStub("AceDB-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

---@class Fontmancer: AceAddon
local Fontmancer = AceAddon:NewAddon(addonName)

Fontmancer.metadata = {
    TITLE = "Title",
    LOGO_PATH = "IconTexture",
    DESCRIPTION = "Notes"
}
Fontmancer.originalFonts = {}

function Fontmancer:OnInitialize()
    -- Fetch metadata
    for keyName, keyValue in pairs(self.metadata) do
        self.metadata[keyName] = C_AddOns.GetAddOnMetadata(addonName, keyValue)
    end

    -- Setup the options database + panel
    self.databaseDefaults = {
        global = {
            selectedFont = nil,
            excludeNameplates = false,
            offsets = { height = 0, spacing = 0, shadow = { x = 0, y = 0 } },
            colours = {
                text = { isEnabled = false, r = 215 / 255, g = 151 / 255, b = 67 / 255, a = 1 },
                shadow = { isEnabled = false, r = 0, g = 0, b = 0, a = 1 }
            },
            flags = { MONOCHROME = false, OUTLINE = false, THICKOUTLINE = false },
            forceIndent = false,
        }
    }
    self.db = AceDB:New(addonName .. "DB", self.databaseDefaults)
    self.previousExcludeNameplates = self.db.global.excludeNameplates
    self.initiallySelectedFont = self.db.global.selectedFont
    self:CreateOptionsPanel()
    -- self:CreateAdvancedOptionsPanel()

    -- Change the following constants on addon load, otherwise it will not apply
    local eventFrame = CreateFrame("FRAME")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:SetScript("OnEvent", function()
        local selectedFont = self.db.global.selectedFont
        if selectedFont then
            local fetchedFont = LSM:Fetch(LSM.MediaType.FONT, selectedFont)
            DAMAGE_TEXT_FONT = fetchedFont
            UNIT_NAME_FONT = fetchedFont
            STANDARD_TEXT_FONT = fetchedFont
            NAMEPLATE_FONT = fetchedFont
        end
    end)
end

function Fontmancer:OnEnable()
    -- Give it some time to avoid loading at the same time as the rest of the UI
    C_Timer.After(0.5, function()
        self:ReplaceAllFonts()
        self:HookCallbacks()
    end)
end

function Fontmancer:ReplaceAllFonts(revertingFunction)
    local fonts = GetFonts()
    for _, font in ipairs(fonts) do
        self:ReplaceFont(font, revertingFunction)
    end
end

function Fontmancer:ReplaceFont(fontName, revertingFunction)
    local isExcluded = self.db.global.excludeNameplates and string.find(fontName, "nameplate")
    if not isExcluded then
        local font = _G[fontName]
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
end

function Fontmancer:StoreOriginals(fontName, font)
    if not self.originalFonts[fontName] then
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
            indent = font:GetIndentedWordWrap(),
            offsets = {
                shadow = { x = shadowX, y = shadowY },
                spacing = font:GetSpacing()
            }
        }
    end
end

function Fontmancer:ApplyFont(fontName, font)
    local selectedFont = self.db.global.selectedFont
    if selectedFont then
        local fetchedFont = LSM:Fetch(LSM.MediaType.FONT, selectedFont)
        local newHeight = math.max(self.originalFonts[fontName].height + self.db.global.offsets.height, 0.5)

        local newFlagsSplit = {}
        for flagName, flagState in pairs(self.db.global.flags) do
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
end

function Fontmancer:ApplySpacing(fontName, font)
    self.isUpdating = true
    font:SetSpacing(self.originalFonts[fontName].offsets.spacing + self.db.global.offsets.spacing)
    self.isUpdating = false
end

function Fontmancer:ApplyTextColour(fontName, font, shouldRevert)
    local colourSettings = self.db.global.colours.text
    self.isUpdating = true
    if shouldRevert then
        local originalColour = self.originalFonts[fontName].colours.text
        font:SetTextColor(originalColour.r, originalColour.g, originalColour.b, originalColour.a)
    elseif colourSettings.isEnabled then
        font:SetTextColor(colourSettings.r, colourSettings.g, colourSettings.b, colourSettings.a)
    end
    self.isUpdating = false
end

function Fontmancer:ApplyShadowColour(fontName, font, shouldRevert)
    local colourSettings = self.db.global.colours.shadow
    self.isUpdating = true
    if shouldRevert then
        local originalColour = self.originalFonts[fontName].colours.shadow
        font:SetShadowColor(originalColour.r, originalColour.g, originalColour.b, originalColour.a)
    elseif colourSettings.isEnabled then
        font:SetShadowColor(colourSettings.r, colourSettings.g, colourSettings.b, colourSettings.a)
    end
    self.isUpdating = false
end

function Fontmancer:ApplyShadowOffset(fontName, font)
    local newX = self.originalFonts[fontName].offsets.shadow.x + self.db.global.offsets.shadow.x
    local newY = self.originalFonts[fontName].offsets.shadow.y + self.db.global.offsets.shadow.y
    self.isUpdating = true
    font:SetShadowOffset(newX, newY)
    self.isUpdating = false
end

function Fontmancer:ApplyIndent(fontName, font)
    local indent = self.db.global.forceIndent
    self.isUpdating = true
    font:SetIndentedWordWrap(indent or (indent == false and self.originalFonts[fontName].indent))
    self.isUpdating = false
end
