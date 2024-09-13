local addonName = ...
local AceAddon = LibStub("AceAddon-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

---@class Fontmancer: AceAddon
local Fontmancer = AceAddon:GetAddon(addonName)

function Fontmancer:ShouldReloadForFonts()
    -- Show the warning when we change the font
    return self.db.global.selectedFont ~= self.initiallySelectedFont
end

function Fontmancer:ShouldReloadForNameplates()
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

function Fontmancer:CreateOptions()
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
            fontReloadImage = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "description",
                name = " ",
                image = "Interface\\AddOns\\Fontmancer\\Assets\\Warning.png",
                imageWidth = 14,
                imageHeight = 20,
                width = 0.2,
                hidden = function()
                    return not self:ShouldReloadForFonts()
                end,
            },
            fontReloadWarning = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "description",
                name =
                "|cffff9900You will need to fully logout / exit the game for that option to take effect on floating combat text!|r",
                hidden = function()
                    return not self:ShouldReloadForFonts()
                end,
                width = 2.3,
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
            excludeNameplatesReloadButton = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "execute",
                name = "",
                desc = "Just like a " .. self:ColourText("/reload") .. " or " .. self:ColourText("/reloadui"),
                image = "Interface\\AddOns\\Fontmancer\\Assets\\Reload.png",
                imageWidth = 14,
                imageHeight = 14,
                func = function()
                    C_UI.Reload()
                end,
                hidden = function()
                    return not self:ShouldReloadForNameplates()
                end,
                width = 0.2,
            },
            excludeNameplatesReloadWarning = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "description",
                name = "|cffff9900You will need to reload your UI for that option to take effect!|r",
                hidden = function()
                    return not self:ShouldReloadForNameplates()
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
