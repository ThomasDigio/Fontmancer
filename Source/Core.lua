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
Fontmancer.originalFonts = {}
Fontmancer.frame = CreateFrame("FRAME")

function Fontmancer:OnInitialize()
    -- Fetch metadata
    for keyName, keyValue in pairs(self.metadata) do
        self.metadata[keyName] = C_AddOns.GetAddOnMetadata("Fontmancer", keyValue)
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
    self.db = AceDB:New("FontmancerDB", databaseDefaults)
    Fontmancer.previousExcludeNameplates = self.db.global.excludeNameplates

    -- Create the options
    local options = {
        name = self.metadata.TITLE,
        handler = Fontmancer,
        type = "group",
        args = {
            -- ABOUT
            aboutHeader = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "header",
                name = "About",
            },
            aboutHeaderSpacing = self:CreateSpacing(),
            logoImage = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "description",
                name = " ",
                width = 0.6,
                image = self.metadata.LOGO_PATH,
                imageWidth = 64,
                imageHeight = 64,
            },
            description = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "description",
                name = self.metadata.DESCRIPTION,
                fontSize = "medium",
                width = 3.1,
            },
            -- CONFIG
            configHeader = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "header",
                name = "Config",
            },
            configHeaderSpacing = self:CreateSpacing(),
            fontSelector = {
                order = self:IncrementAndFetchOptionOrder(),
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
            },
            fontSpacing = self:CreateSpacing(),
            excludeNameplates = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "toggle",
                name = "Exclude Nameplates",
                desc =
                "Some people may find that nameplate text grows abnormally large using a different font and therefore want to disable it",
                get = function(_)
                    return self.db.global.excludeNameplates
                end,
                set = function(_, value)
                    self.previousExcludeNameplates = self.db.global.excludeNameplates
                    self.db.global.excludeNameplates = value
                    self:ApplyFont()
                end,
                width = 0.9,
            },
            excludeNameplatesReload = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "execute",
                name = "",
                desc = "Just like a " .. self:ColourText("/reload") .. " or " .. self:ColourText("/reloadui"),
                image = "Interface\\AddOns\\Fontmancer\\Assets\\Reload.png",
                imageWidth = 16,
                imageHeight = 16,
                func = function()
                    C_UI.Reload()
                end,
                disabled = function()
                    return not self:ShouldReload()
                end,
                width = 0.2,
            },
            excludeNameplatesWarning = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "description",
                name = "|cffff9900You will need to reload your UI for that option to take effect!|r",
                hidden = function()
                    return not self:ShouldReload()
                end,
                width = 2,
            },
            excludeNameplatesSpacing = self:CreateSpacing(),
            offsetGroup = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "group",
                name = "Offsets",
                inline = true,
                args = {
                    heightSelector = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "range",
                        name = "Height",
                        min = -10,
                        max = 10,
                        step = 0.5,
                        get = function(_)
                            return self.db.global.offsets.height
                        end,
                        set = function(_, value)
                            self.db.global.offsets.height = value
                            self:ApplyFont()
                        end,
                    },
                },
            },
            offsetGroupSpacing = self:CreateSpacing(),
            flagGroup = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "group",
                name = "Flags",
                inline = true,
                args = {
                    flagStateDescription = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "description",
                        name =
                            "• Unchecked means it will leave it as it is\n" ..
                            "• Checked means it will apply it everywhere\n" ..
                            "• Greyed out means it will remove it everywhere\n",
                        width = 1.8,
                    },
                    flagNameDescription = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "description",
                        name =
                            "• " .. self:ColourText("Monochrome") .. ": Font is rendered without antialiasing\n" ..
                            "• " .. self:ColourText("Outline") .. ": Font is displayed with a black outline\n" ..
                            "• " .. self:ColourText("Thick") .. ": Font is displayed with a thick black outline\n",
                        width = 1.8,
                    },
                    flagsSelector = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "multiselect",
                        name = "",
                        values = { MONOCHROME = "Monochrome", OUTLINE = "Outline", THICKOUTLINE = "Thick" },
                        tristate = true,
                        get = function(_, name)
                            return self.db.global.flags[name]
                        end,
                        set = function(_, name, value)
                            self.db.global.flags[name] = value
                            self:ApplyFont()
                        end,
                    },
                },
            },
        },
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

function Fontmancer:ShouldReload()
    -- Show the warning when we toggle "Exclude Nameplates" on
    return self.db.global.excludeNameplates and not self.previousExcludeNameplates
end

function Fontmancer:IncrementAndFetchOptionOrder()
    self.optionOrder = self.optionOrder + 1
    return self.optionOrder
end

function Fontmancer:CreateSpacing()
    return {
        order = self:IncrementAndFetchOptionOrder(),
        type = "description",
        name = " ",
        width = "full",
    }
end

function Fontmancer:ColourText(text)
    return "|cff" .. self.colour .. text .. "|r"
end
