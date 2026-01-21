local addonName = ...
local AceAddon = LibStub("AceAddon-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

---@class Fontmancer: AceAddon
local Fontmancer = AceAddon:GetAddon(addonName)

Fontmancer.tableValues = {}
Fontmancer.searchText = ""

function Fontmancer:UpdateList()
    local order = 1

    local searchPattern = self.searchText
    if searchPattern ~= "" then
        searchPattern = C_StringUtil.EscapeLuaPatterns(searchPattern)
    end

    local sortedFonts = {}
    for fontName in pairs(self.originalFonts) do
        table.insert(sortedFonts, fontName)
    end
    table.sort(sortedFonts)

    for _, fontName in ipairs(sortedFonts) do
        -- Check if item matches search
        if self.searchText == "" or fontName:lower():find(searchPattern) then
            self.tableValues["item" .. order] = {
                type = "description",
                name = fontName,
                width = 'full',
                fontSize = "medium",
                order = order,
            }
            order = order + 1
        end
    end

    -- Update the UI with the new list entries
    AceConfigRegistry:NotifyChange(addonName)
end

function Fontmancer:CreateAdvancedOptionsPanel()
    self:InitialiseInspector()
    self:UpdateList()

    local options = {
        name = self.metadata.TITLE,
        handler = Fontmancer,
        type = "group",
        args = {
            inspectorHeader = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "header",
                name = "Inspector",
            },
            inspectorHeaderSpacing = self:CreateSpacing(),
            inspectorDescription = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "description",
                name = "Looking for a specific frame's text, but not sure which one? Use the inspector!",
            },
            inspectorToggle = {
                order = self:IncrementAndFetchOptionOrder(),
                type = "execute",
                name = "Toggle Inspector",
                func = function()
                    HideUIPanel(SettingsPanel)
                    HideUIPanel(GameMenuFrame)
                    self:ToggleInspection()
                end,
            },
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
