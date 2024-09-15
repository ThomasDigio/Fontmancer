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
            offsets = { height = 0 },
            enableColour = false,
            enableAlpha = false,
            colour = { r = 1, g = 247 / 255, b = 140 / 255, a = 1 },
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
        self:ApplyFont()
    end)
end

function Fontmancer:ApplyFont()
    local selectedFont = self.db.global.selectedFont
    if not selectedFont then
        return
    end

    local fetchedFont = LSM:Fetch(LSM.MediaType.FONT, selectedFont)

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
                local newHeight = max(self.originalFonts[frameName].HEIGHT + self.db.global.offsets.height, 0.5)
                frame:SetFont(fetchedFont, newHeight, self:BuildFlags(frameName))
                self:ApplyTextColour(frameName, frame)
                self:ApplyIndent(frameName, frame)
            end
        end
    end
end

function Fontmancer:StoreOriginals(fontName, font)
    if not self.originalFonts[fontName] then
        -- Height and flags
        local _, height, flags = font:GetFont()
        self.originalFonts[fontName] = { HEIGHT = height, FLAGS = flags }

        -- Colour
        local r, g, b, a = font:GetTextColor()
        self.originalFonts[fontName].COLOUR = { r = r, g = g, b = b, a = a }

        -- Indent
        local indent = font:GetIndentedWordWrap()
        self.originalFonts[fontName].INDENT = indent
    end
end
function Fontmancer:BuildFlags(fontName)
    local newFlagsSplit = {}

    for flagName, flagState in pairs(self.db.global.flags) do
        -- Apply the flag if the box is checked, or unchecked but in the original values
        -- If greyed out, don't add it
        if flagState or (flagState == false and string.find(self.originalFonts[fontName].FLAGS, flagName)) then
            table.insert(newFlagsSplit, flagName)
        end
    end

    return table.concat(newFlagsSplit, ", ")
end

function Fontmancer:ApplyTextColour(fontName, font)
    local colour = self.db.global.colour
    if self.db.global.enableColour then
        if self.db.global.enableAlpha then
            font:SetTextColor(colour.r, colour.g, colour.b, colour.a)
        else
            font:SetTextColor(colour.r, colour.g, colour.b)
        end
    else
        local originalColour = self.originalFonts[fontName].COLOUR
        if originalColour then
            if self.db.global.enableAlpha then
                font:SetTextColor(originalColour.r, originalColour.g, originalColour.b, colour.a)
            else
                font:SetTextColor(originalColour.r, originalColour.g, originalColour.b, originalColour.a)
            end
        end
    end
end

function Fontmancer:ApplyIndent(fontName, font)
    local indent = self.db.global.forceIndent
    font:SetIndentedWordWrap(indent or (indent == false and self.originalFonts[fontName].INDENT))
end
