local addonName = ...
local AceAddon = LibStub("AceAddon-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

---@class Fontmancer: AceAddon
local Fontmancer = AceAddon:GetAddon(addonName)

-- Sample data table - replace with your own data
Fontmancer.listData = {
    {
        name = "First Item",
        type = "Weapon",
        value = "1000g"
    },
    {
        name = "Second Item",
        type = "Armor",
        value = "500g"
    },
    {
        name = "Third Item",
        type = "Consumable",
        value = "50g"
    }
}
Fontmancer.tableValues = {}
Fontmancer.searchText = ""

-- Function to update the list based on search
function Fontmancer:UpdateList()
    self.tableValues = {}
    local order = 1

    for _, item in pairs(self.listData) do
        -- Check if item matches search
        if self.searchText == "" or item.name:lower():find(self.searchText) then
            self.tableValues[item.name] = {
                type = "group",
                name = "", -- Empty name for better spacing
                inline = true,
                order = order,
                args = {
                    name = {
                        type = "description",
                        name = item.name,
                        width = 1.3,
                        fontSize = "medium",
                        order = 1,
                    },
                    type = {
                        type = "description",
                        name = item.type,
                        width = 1.3,
                        fontSize = "medium",
                        order = 2,
                    },
                    value = {
                        type = "description",
                        name = item.value,
                        width = 1.3,
                        fontSize = "medium",
                        order = 3,
                    },
                }
            }
            order = order + 1
        end
    end

    -- Notify configuration system of the changes
    AceConfigRegistry:NotifyChange(addonName)
end

function Fontmancer:CreateAdvancedOptionsPanel()
    local options = {
        name = self.metadata.TITLE,
        handler = Fontmancer,
        type = "group",
        args = {
            -- inspectorHeader = {
            --     order = self:IncrementAndFetchOptionOrder(),
            --     type = "header",
            --     name = "Inspector",
            -- },
            -- inspectorHeaderSpacing = self:CreateSpacing(),
            -- inspectorDescription = {
            --     order = self:IncrementAndFetchOptionOrder(),
            --     type = "description",
            --     name = "Looking for a specific frame's text, but not sure which one? Use the inspector!",
            -- },
            -- inspectorToggle = {
            --     order = self:IncrementAndFetchOptionOrder(),
            --     type = "execute",
            --     name = "Toggle Inspector",
            --     func = function()
            --         HideUIPanel(SettingsPanel)
            --         HideUIPanel(GameMenuFrame)
            --         self:ToggleInspection()
            --     end,
            -- },
            listingHeader = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "header",
                name = "Text List",
            },
            listingHeaderSpacing = self:CreateSpacing(),
            listingDescription = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "description",
                name = "Find the full list of all font instances found by Fontmancer here",
            },
            fontListSearch = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "input",
                name = "Search",
                desc = "Search by name",
                get = function() return self.searchText end,
                set = function(_, value)
                    self.searchText = value:lower()
                end,
                -- width = 1,
            },
            fontListRefresh = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "execute",
                name = "Refresh",
                func = function()
                    self:UpdateList()
                end,
                width = 0.3,
            },
            fontListTable = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "group",
                name = "Font instances",
                inline = true,
                args = self.tableValues,
            },
        },
    }

    local advancedName = self.name .. "Advanced"
    AceConfigRegistry:RegisterOptionsTable(advancedName, options)
    AceConfigDialog:AddToBlizOptions(advancedName, "Advanced", self.name)
end
