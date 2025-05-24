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

    -- self:InitialiseInspector()
end

function Fontmancer:OnEnable()
    -- Give it some time to load everything
    C_Timer.After(0.5, function()
        self:ApplyReplacements()
        self:HookCallbacks()
    end)
end

function Fontmancer:ApplyReplacements(revertingFunction)
    for frameName in pairs(_G) do
        local frame = _G[frameName]
        if frame and type(frame) == "table" then
            local isExcluded = self.db.global.excludeNameplates and string.find(frameName:lower(), "nameplate")
            local isForbidden = frame.IsForbidden and pcall(frame.IsForbidden, frame) and frame:IsForbidden()
            local hasFont = frame.GetFont and pcall(frame.GetFont, frame) and frame:GetFont()
            if not isExcluded and not isForbidden and hasFont then
                -- Store the original font values so users can reapply height, flags, etc... without needing to reload the UI
                self:StoreOriginals(frameName, frame)

                if revertingFunction then
                    revertingFunction(self, frameName, frame, true)
                else
                    -- Apply all the options
                    self:ApplyFont(frameName, frame)
                    self:ApplySpacing(frameName, frame)
                    self:ApplyTextColour(frameName, frame)
                    self:ApplyShadowColour(frameName, frame)
                    self:ApplyShadowOffset(frameName, frame)
                    -- Except indent, because that is completely broken for some reason
                    -- self:ApplyIndent(frameName, frame)
                end
            end
        end
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
    font:SetSpacing(self.originalFonts[fontName].offsets.spacing + self.db.global.offsets.spacing)
end

function Fontmancer:ApplyTextColour(fontName, font, shouldRevert)
    local colourSettings = self.db.global.colours.text
    if shouldRevert then
        local originalColour = self.originalFonts[fontName].colours.text
        font:SetTextColor(originalColour.r, originalColour.g, originalColour.b, originalColour.a, true)
    elseif colourSettings.isEnabled then
        font:SetTextColor(colourSettings.r, colourSettings.g, colourSettings.b, colourSettings.a, true)
    end
end

function Fontmancer:ApplyShadowColour(fontName, font, shouldRevert)
    local colourSettings = self.db.global.colours.shadow
    if shouldRevert then
        local originalColour = self.originalFonts[fontName].colours.shadow
        font:SetShadowColor(originalColour.r, originalColour.g, originalColour.b, originalColour.a, true)
    elseif colourSettings.isEnabled then
        font:SetShadowColor(colourSettings.r, colourSettings.g, colourSettings.b, colourSettings.a, true)
    end
end

function Fontmancer:ApplyShadowOffset(fontName, font)
    local newX = self.originalFonts[fontName].offsets.shadow.x + self.db.global.offsets.shadow.x
    local newY = self.originalFonts[fontName].offsets.shadow.y + self.db.global.offsets.shadow.y
    font:SetShadowOffset(newX, newY)
end

function Fontmancer:ApplyIndent(fontName, font)
    local indent = self.db.global.forceIndent
    font:SetIndentedWordWrap(indent or (indent == false and self.originalFonts[fontName].indent))
end
