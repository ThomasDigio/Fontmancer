local addonName, addonTable = ...

function addonTable:CreateAdvancedOptionsPanel()
    local panel = CreateFrame("Frame", addonName .. "AdvancedPanel")
    panel.name = "Advanced"
    local logo = self:CreatePanelHeader(panel)

    local listingHeader = self:CreateSectionHeader(panel, "Listing", logo)
    local desc = listingHeader:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", listingHeader, "BOTTOMLEFT", 0, -5)
    desc:SetText("Search for a specific font instance or frame and tweak it!")
    local searchBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    searchBox:SetSize(200, 30)
    searchBox:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 5, -15)
    searchBox:SetAutoFocus(false)
    local UpdateList -- Declare function early so the search box can call it
    self:CreateReloadButton(panel, searchBox, 10, 0, UpdateList)
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 0)
    local content = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(content)
    local listText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    listText:SetPoint("TOPLEFT", 0, 0)
    listText:SetJustifyH("LEFT")
    listText:SetJustifyV("TOP")
    UpdateList = function()
        -- Update width dynamically because it is 0 during initialization
        local width = scrollFrame:GetWidth()
        content:SetWidth(width)
        listText:SetWidth(width)

        local search = searchBox:GetText():lower()
        local keys = {}
        for k in pairs(self.originalFonts) do
            if search == "" or k:lower():find(search) then
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
    panel:SetScript("OnShow", UpdateList)

    -- Register with Blizzard settings
    Settings.RegisterCanvasLayoutSubcategory(self.settingsCategory, panel, "Advanced")
end
