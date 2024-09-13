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
Fontmancer.optionOrder = 0
Fontmancer.colour = "fff78c"
Fontmancer.originalFonts = {}
Fontmancer.frame = CreateFrame("FRAME")

function Fontmancer:OnInitialize()
    -- Fetch metadata
    for keyName, keyValue in pairs(self.metadata) do
        self.metadata[keyName] = C_AddOns.GetAddOnMetadata(addonName, keyValue)
    end

    -- Initialise the database
    local databaseDefaults = {
        global = {
            offsets = { height = 0 },
            excludeNameplates = false,
            flags = { MONOCHROME = false, OUTLINE = false, THICKOUTLINE = false },
            selectedFont = nil
        }
    }
    self.db = AceDB:New(addonName .. "DB", databaseDefaults)
    Fontmancer.previousExcludeNameplates = self.db.global.excludeNameplates
    Fontmancer.initiallySelectedFont = self.db.global.selectedFont

    -- Create the options
    Fontmancer:CreateOptions()

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
                local _, height, flags = frame:GetFont()

                -- Store the original font values so users can reapply offsets / flags without needing to reload the UI
                if not self.originalFonts[frameName] then
                    self.originalFonts[frameName] = { HEIGHT = height, FLAGS = flags }
                end

                local newHeight = max(self.originalFonts[frameName].HEIGHT + self.db.global.offsets.height, 0.5)
                frame:SetFont(fetchedFont, newHeight, self:BuildFlags(frameName))
            end
        end
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

