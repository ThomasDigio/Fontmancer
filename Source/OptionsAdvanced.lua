local addonName, addonTable = ...

function addonTable:CreateAdvancedOptionsPanel()
    local panel = CreateFrame("Frame", addonName .. "AdvancedPanel")
    panel.name = "Advanced"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 15, -15)
    title:SetText(self.metadata.TITLE)

    local inspectorGroup = CreateFrame("Frame", nil, panel)
    inspectorGroup:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    inspectorGroup:SetSize(400, 60)
    local inspectorLabel = inspectorGroup:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    inspectorLabel:SetPoint("TOPLEFT", 0, 0)
    inspectorLabel:SetText("The Inspector tool allows you to hover over frames to identify their fonts.")
    local inspectorBtn = CreateFrame("Button", nil, inspectorGroup, "GameMenuButtonTemplate")
    inspectorBtn:SetPoint("TOPLEFT", inspectorLabel, "BOTTOMLEFT", 0, -10)
    inspectorBtn:SetSize(140, 30)
    inspectorBtn:SetText("Open Inspector")
    inspectorBtn:SetScript("OnClick", function()
        if addonTable.ToggleInspection then
            addonTable:ToggleInspection()
            if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        end
    end)

    local listGroup = CreateFrame("Frame", nil, panel)
    listGroup:SetPoint("TOPLEFT", inspectorGroup, "BOTTOMLEFT", 0, -30)
    listGroup:SetPoint("BOTTOMRIGHT", -20, 20)
    local listTitle = listGroup:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    listTitle:SetPoint("TOPLEFT", 0, 0)
    listTitle:SetText("Font Instances")
    local desc = listGroup:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", listTitle, "BOTTOMLEFT", 0, -5)
    desc:SetText("Below is a list of all font instances found by Fontmancer.")
    local searchBox = CreateFrame("EditBox", nil, listGroup, "InputBoxTemplate")
    searchBox:SetSize(200, 30)
    searchBox:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 5, -15)
    searchBox:SetAutoFocus(false)
    searchBox:SetText("")
    local searchLabel = searchBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    searchLabel:SetPoint("BOTTOMLEFT", searchBox, "TOPLEFT", 0, 0)
    searchLabel:SetText("Search:")
    local refreshBtn = CreateFrame("Button", nil, listGroup, "GameMenuButtonTemplate")
    refreshBtn:SetSize(100, 25)
    refreshBtn:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)
    refreshBtn:SetText("Refresh")
    local scrollFrame = CreateFrame("ScrollFrame", nil, listGroup, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", listGroup, "BOTTOMRIGHT", -30, 0)
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 100)
    scrollFrame:SetScrollChild(content)
    local listText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    listText:SetPoint("TOPLEFT", 0, 0)
    listText:SetJustifyH("LEFT")
    listText:SetJustifyV("TOP")
    listText:SetWidth(content:GetWidth())
    local function UpdateList()
        local search = searchBox:GetText():lower()
        local keys = {}
        for k in pairs(addonTable.originalFonts) do
            if search == "" or k:lower():find(search, 1, true) then
                table.insert(keys, k)
            end
        end
        table.sort(keys)
        local fullText = table.concat(keys, "\n")
        listText:SetText(fullText)
        local height = listText:GetStringHeight()
        content:SetHeight(math.max(height, 100))
    end
    searchBox:SetScript("OnTextChanged", UpdateList)
    refreshBtn:SetScript("OnClick", UpdateList)
    panel:SetScript("OnShow", UpdateList)

    -- Register with Blizzard settings
    Settings.RegisterCanvasLayoutSubcategory(self.settingsCategory, panel, "Advanced")
end
