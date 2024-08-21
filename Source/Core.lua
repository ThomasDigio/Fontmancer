local AceAddon = LibStub("AceAddon-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDB = LibStub("AceDB-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

local Fontmancer = AceAddon:NewAddon("Fontmancer")
Fontmancer.metadata = {
    TITLE = "Title",
    LOGO_PATH = "IconTexture",
    DESCRIPTION = "Notes"
}
Fontmancer.optionOrder = 0
Fontmancer.colour = "fff78c"
Fontmancer.originalFontHeights = {}
Fontmancer.frame = CreateFrame("FRAME")

function Fontmancer:OnInitialize()
    -- Fetch metadata
    for keyName, keyValue in pairs(self.metadata) do
        self.metadata[keyName] = C_AddOns.GetAddOnMetadata("Fontmancer", keyValue)
    end

    -- Initialise the database
    local databaseDefaults = {
        global = {
            delta = 0,
            selectedFont = nil
        }
    }
    self.db = AceDB:New("FontmancerDB", databaseDefaults)

    -- Create the options
    local options = {
        name = self.metadata.TITLE,
        handler = Fontmancer,
        type = "group",
        args = {
            -- ABOUT
            aboutHeader = {
                type = "header",
                name = "About",
                order = self:IncrementAndFetchOptionOrder()
            },
            spacing1 = self:CreateSpacing("full"),
            logoImage = {
                type = "description",
                name = " ",
                width = 0.5,
                image = self.metadata.LOGO_PATH,
                imageWidth = 64,
                imageHeight = 64,
                order = self:IncrementAndFetchOptionOrder()
            },
            spacing2 = self:CreateSpacing(0.1),
            description = {
                type = "description",
                name = self.metadata.DESCRIPTION,
                fontSize = "medium",
                width = 3.1,
                order = self:IncrementAndFetchOptionOrder()
            },
            -- CONFIG
            header = {
                type = "header",
                name = "Config",
                order = self:IncrementAndFetchOptionOrder()
            },
            spacing3 = self:CreateSpacing("full"),
            fontSelector = {
                type = "select",
                name = "Font",
                desc = "Choose the font to apply to all UI elements (add new fonts with SharedMedia)",
                dialogControl = "LSM30_Font",
                values = LSM:HashTable(LSM.MediaType.FONT),
                get = function(_)
                    return self.db.global.selectedFont
                end,
                set = function(_, value)
                    self.db.global.selectedFont = value
                    self:ApplyFont()
                end,
                order = self:IncrementAndFetchOptionOrder(),
            },
            spacing4 = self:CreateSpacing(0.5),
            deltaSelector = {
                type = "range",
                name = "Delta",
                desc = "Optional delta value used to adjust your font size",
                min = -10,
                max = 10,
                step = 0.5,
                get = function(_)
                    return self.db.global.delta
                end,
                set = function(_, value)
                    self.db.global.delta = value
                    self:ApplyFont()
                end,
                order = self:IncrementAndFetchOptionOrder(),
            },
            -- spacing5 = self:CreateSpacing(0.1),
            -- deltaReload = {
            --     type = "execute",
            --     name = "",
            --     desc = "Just like a " .. self:ColourText("/reload") .. " or " .. self:ColourText("/reloadui"),
            --     image = "Interface\\AddOns\\Fontmancer\\Assets\\Reload.png",
            --     imageWidth = 16,
            --     imageHeight = 16,
            --     func = function()
            --         C_UI.Reload()
            --     end,
            --     disabled = function()
            --         return self.db.global.delta == initialDelta
            --     end,
            --     width = 0.2,
            --     order = self:IncrementAndFetchOptionOrder(),
            -- },
            -- deltaWarning = {
            --     type = "description",
            --     name = "|cffff9900You will need to reload your UI for that option to take effect!|r",
            --     width = 2,
            --     order = self:IncrementAndFetchOptionOrder()
            -- }
        }
    }
    AceConfigRegistry:RegisterOptionsTable(self.name, options)
    AceConfigDialog:AddToBlizOptions(self.name)
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
        if frame and type(frame) == "table" and (not frame.IsForbidden or not pcall(frame.IsForbidden, frame) or not frame:IsForbidden()) and (frame.GetFont and pcall(frame.GetFont, frame) and frame:GetFont()) then
            local _, height, flags = frame:GetFont()

            -- Store the original height so users can reapply the delta without needing to reload the UI
            if not Fontmancer.originalFontHeights[frameName] then
                Fontmancer.originalFontHeights[frameName] = height
            end

            local newHeight = max(Fontmancer.originalFontHeights[frameName] + self.db.global.delta, 0.5)
            frame:SetFont(fetchedFont, newHeight, flags)
        end
    end
end

function Fontmancer:IncrementAndFetchOptionOrder()
    self.optionOrder = self.optionOrder + 1
    return self.optionOrder
end

function Fontmancer:CreateSpacing(width)
    return {
        type = "description",
        name = " ",
        width = width,
        order = self:IncrementAndFetchOptionOrder()
    }
end

function Fontmancer:ColourText(text)
    return "|cff" .. self.colour .. text .. "|r"
end
