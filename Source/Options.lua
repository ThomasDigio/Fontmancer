local addonName = ...
local AceAddon = LibStub("AceAddon-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

---@class Fontmancer: AceAddon
local Fontmancer = AceAddon:GetAddon(addonName)

Fontmancer.optionOrder = 0
Fontmancer.colour = "fff78c"

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

function Fontmancer:CreateGroupTitle(text)
    return {
        order = self:IncrementAndFetchOptionOrder(),
        type = "description",
        name = self:ColourText(text),
        fontSize = "medium"
    }
end
function Fontmancer:ColourText(text)
    return "|cff" .. self.colour .. text .. "|r"
end

function Fontmancer:CreateOptionsPanel()
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
                width = 3,
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
                    self:ApplyReplacements()
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
                    self:ApplyReplacements()
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
                    textOffsetDescription = self:CreateGroupTitle("Text"),
                    heightSelector = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "range",
                        name = "Size",
                        min = -10,
                        max = 10,
                        step = 0.5,
                        get = function(_)
                            return self.db.global.offsets.height
                        end,
                        set = function(_, value)
                            self.db.global.offsets.height = value
                            self:ApplyReplacements()
                        end,
                    },
                    spacingSelector = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "range",
                        name = "Spacing",
                        min = -10,
                        max = 10,
                        step = 0.5,
                        get = function(_)
                            return self.db.global.offsets.spacing
                        end,
                        set = function(_, value)
                            self.db.global.offsets.spacing = value
                            self:ApplyReplacements()
                        end,
                    },
                    offsetSpacing = self:CreateSpacing(),
                    shadowOffsetDescription = self:CreateGroupTitle("Shadow"),
                    xShadowSelector = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "range",
                        name = "Horizontal",
                        min = -10,
                        max = 10,
                        step = 0.5,
                        get = function(_)
                            return self.db.global.offsets.shadow.x
                        end,
                        set = function(_, value)
                            self.db.global.offsets.shadow.x = value
                            self:ApplyReplacements()
                        end,
                    },
                    yShadowSelector = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "range",
                        name = "Vertical",
                        min = -10,
                        max = 10,
                        step = 0.5,
                        get = function(_)
                            return self.db.global.offsets.shadow.y
                        end,
                        set = function(_, value)
                            self.db.global.offsets.shadow.y = value
                            self:ApplyReplacements()
                        end,
                    },
                },
            },
            colourGroup = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "group",
                name = "Colours",
                inline = true,
                args = {
                    textColourDescription = self:CreateGroupTitle("Text"),
                    textColourPicker = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "color",
                        name = "",
                        width = 0.2,
                        hasAlpha = true,
                        get = function(_)
                            local colour = self.db.global.colours.text
                            return colour.r, colour.g, colour.b, colour.a
                        end,
                        set = function(_, r, g, b, a)
                            self.db.global.colours.text = { r = r, g = g, b = b, a = a }
                            if self.db.global.enableTextColour or self.db.global.enableTextAlpha then
                                self:ApplyReplacements()
                            end
                        end,
                    },
                    textColourToggle = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "toggle",
                        name = "Replace colour",
                        width = 0.75,
                        get = function(_)
                            return self.db.global.enableTextColour
                        end,
                        set = function(_, value)
                            self.db.global.enableTextColour = value
                            self:ApplyReplacements()
                        end,
                    },
                    textAlphaToggle = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "toggle",
                        name = "Replace alpha",
                        width = 0.75,
                        get = function(_)
                            return self.db.global.enableTextAlpha
                        end,
                        set = function(_, value)
                            self.db.global.enableTextAlpha = value
                            self:ApplyReplacements()
                        end,
                    },
                    colourSpacing = self:CreateSpacing(),
                    shadowColourDescription = self:CreateGroupTitle("Shadow"),
                    shadowColourPicker = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "color",
                        name = "",
                        width = 0.2,
                        hasAlpha = true,
                        get = function(_)
                            local colour = self.db.global.colours.shadow
                            return colour.r, colour.g, colour.b, colour.a
                        end,
                        set = function(_, r, g, b, a)
                            self.db.global.colours.shadow = { r = r, g = g, b = b, a = a }
                            if self.db.global.enableShadowColour or self.db.global.enableShadowAlpha then
                                self:ApplyReplacements()
                            end
                        end,
                    },
                    shadowColourToggle = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "toggle",
                        name = "Replace colour",
                        width = 0.75,
                        get = function(_)
                            return self.db.global.enableShadowColour
                        end,
                        set = function(_, value)
                            self.db.global.enableShadowColour = value
                            self:ApplyReplacements()
                        end,
                    },
                    shadowAlphaToggle = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "toggle",
                        name = "Replace alpha",
                        width = 0.75,
                        get = function(_)
                            return self.db.global.enableShadowAlpha
                        end,
                        set = function(_, value)
                            self.db.global.enableShadowAlpha = value
                            self:ApplyReplacements()
                        end,
                    },
                },
            },
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
                        width = 1.75,
                    },
                    flagNameDescription = {
                        order = self:IncrementAndFetchOptionOrder(),
                        type = "description",
                        name =
                            "• " .. self:ColourText("Monochrome") .. ": Font is rendered without antialiasing\n" ..
                            "• " .. self:ColourText("Outline") .. ": Font is displayed with a black outline\n" ..
                            "• " .. self:ColourText("Thick") .. ": Font is displayed with a thick black outline\n",
                        width = 1.75,
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
                            self:ApplyReplacements()
                        end,
                    },
                    -- indentToggle = {
                    --     order = self:IncrementAndFetchOptionOrder(),
                    --     type = "toggle",
                    --     name = "Indent on word wrap",
                    --     tristate = true,
                    --     -- width = 1.5,
                    --     get = function(_)
                    --         return self.db.global.forceIndent
                    --     end,
                    --     set = function(_, value)
                    --         self.db.global.forceIndent = value
                    --         self:ApplyReplacements()
                    --     end,
                    -- },
                },
            },
        },
    }

    AceConfigRegistry:RegisterOptionsTable(self.name, options)
    AceConfigDialog:AddToBlizOptions(self.name)
end
