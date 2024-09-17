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
Fontmancer.frame = CreateFrame("FRAME")

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
            enableTextColour = false,
            enableTextAlpha = false,
            enableShadowColour = false,
            enableShadowAlpha = false,
            colours = { text = { r = 1, g = 247 / 255, b = 140 / 255, a = 1 }, shadow = { r = 0, g = 0, b = 0, a = 1 } },
            flags = { MONOCHROME = false, OUTLINE = false, THICKOUTLINE = false },
            forceIndent = false,
        }
    }
    self.db = AceDB:New(addonName .. "DB", self.databaseDefaults)
    Fontmancer.previousExcludeNameplates = self.db.global.excludeNameplates
    Fontmancer.initiallySelectedFont = self.db.global.selectedFont
    Fontmancer:CreateOptionsPanel()

    -- Change some of the fonts on addon load event otherwise it will not actually apply
    self.frame:RegisterEvent("ADDON_LOADED")
    self.frame:SetScript("OnEvent", function()
        local selectedFont = self.db.global.selectedFont
        if selectedFont then
            local fetchedFont = LSM:Fetch(LSM.MediaType.FONT, selectedFont)
            DAMAGE_TEXT_FONT = fetchedFont
            UNIT_NAME_FONT = fetchedFont
            -- STANDARD_TEXT_FONT? NAMEPLATE_FONT?
        end
    end)
end

function Fontmancer:OnEnable()
    -- Give it some time to load everything
    C_Timer.After(0.5, function()
        self:ApplyReplacements()
    end)
end

function Fontmancer:ApplyReplacements()
    for frameName in pairs(_G) do
        local frame = _G[frameName]
        if frame and type(frame) == "table" then
            local isExcluded = self.db.global.excludeNameplates and string.find(frameName:lower(), "nameplate")
            local isForbidden = frame.IsForbidden and pcall(frame.IsForbidden, frame) and frame:IsForbidden()
            local hasFont = frame.GetFont and pcall(frame.GetFont, frame) and frame:GetFont()
            if not isExcluded and not isForbidden and hasFont then
                -- Store the original font values so users can reapply height, flags, etc... without needing to reload the UI
                self:StoreOriginals(frameName, frame)

                -- Apply all the options
                self:ApplyFont(frameName, frame)
                self:ApplySpacing(frameName, frame)
                self:ApplyTextColour(frameName, frame)
                self:ApplyShadow(frameName, frame)
                -- Except indent, because that is completely broken for some reason
                -- self:ApplyIndent(frameName, frame)
            end
        end
    end
end

function Fontmancer:StoreOriginals(fontName, font)
    if not self.originalFonts[fontName] then
        local _, height, flags = font:GetFont()
        self.originalFonts[fontName] = {
            height = height,
            flags = flags,
            spacing = font:GetSpacing(),
            indent = font:GetIndentedWordWrap()
        }

        local textRed, textGreen, textBlue, textAlpha = font:GetTextColor()
        self.originalFonts[fontName].colour = { r = textRed, g = textGreen, b = textBlue, a = textAlpha }

        local shadowRed, shadowGreen, shadowBlue, shadowAlpha = font:GetShadowColor()
        local shadowX, shadowY = font:GetShadowOffset()
        self.originalFonts[fontName].shadow = { colour = { r = shadowRed, g = shadowGreen, b = shadowBlue, a = shadowAlpha }, offset = { x = shadowX, y = shadowY } }
    end
end

function Fontmancer:ApplyFont(fontName, font)
    local selectedFont = self.db.global.selectedFont
    if selectedFont then
        local fetchedFont = LSM:Fetch(LSM.MediaType.FONT, selectedFont)
        local newHeight = max(self.originalFonts[fontName].height + self.db.global.offsets.height, 0.5)
        font:SetFont(fetchedFont, newHeight, self:BuildFlags(fontName))
    end
end

function Fontmancer:BuildFlags(fontName)
    local newFlagsSplit = {}

    for flagName, flagState in pairs(self.db.global.flags) do
        -- Apply the flag if the box is checked, or unchecked but in the original values
        -- If greyed out, don't add it
        if flagState or (flagState == false and string.find(self.originalFonts[fontName].flags, flagName)) then
            table.insert(newFlagsSplit, flagName)
        end
    end

    return table.concat(newFlagsSplit, ", ")
end

function Fontmancer:ApplySpacing(fontName, font)
    font:SetSpacing(self.originalFonts[fontName].spacing + self.db.global.offsets.spacing)
end

function Fontmancer:ApplyTextColour(fontName, font)
    local colour = self.db.global.colours.text
    if self.db.global.enableTextColour then
        if self.db.global.enableTextAlpha then
            font:SetTextColor(colour.r, colour.g, colour.b, colour.a)
        else
            font:SetTextColor(colour.r, colour.g, colour.b)
        end
    else
        local originalColour = self.originalFonts[fontName].colour
            if self.db.global.enableTextAlpha then
                font:SetTextColor(originalColour.r, originalColour.g, originalColour.b, colour.a)
            else
            font:SetTextColor(originalColour.r, originalColour.g, originalColour.b, originalColour.a)
        end
    end
end

function Fontmancer:ApplyShadow(fontName, font)
    -- Colour
    local colour = self.db.global.colours.shadow
    if self.db.global.enableShadowColour then
        if self.db.global.enableShadowAlpha then
            font:SetShadowColor(colour.r, colour.g, colour.b, colour.a)
        else
            font:SetShadowColor(colour.r, colour.g, colour.b)
        end
    else
        local originalColour = self.originalFonts[fontName].shadow.colour
            if self.db.global.enableShadowAlpha then
                font:SetShadowColor(originalColour.r, originalColour.g, originalColour.b, colour.a)
            else
            font:SetShadowColor(originalColour.r, originalColour.g, originalColour.b, originalColour.a)
        end
    end

    -- Offset
    local newX = self.originalFonts[fontName].shadow.offset.x + self.db.global.offsets.shadow.x
    local newY = self.originalFonts[fontName].shadow.offset.y + self.db.global.offsets.shadow.y
    font:SetShadowOffset(newX, newY)
end

function Fontmancer:ApplyIndent(fontName, font)
    local indent = self.db.global.forceIndent
    font:SetIndentedWordWrap(indent or (indent == false and self.originalFonts[fontName].indent))
end
