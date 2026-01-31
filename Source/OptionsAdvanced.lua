local addonName, addonTable = ...

function addonTable:CreateAdvancedOptionsPanel()
    local panel = CreateFrame("Frame", addonName .. "AdvancedPanel")
    panel.name = "Advanced"
    local logo = self:CreatePanelHeader(panel)

    local header = self:CreateSectionHeader(panel, "Font instances", logo)

    local searchBox = CreateFrame("EditBox", nil, panel, "SearchBoxTemplate")
    searchBox:SetSize(400, 22)
    searchBox:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 5, -15)
    searchBox:SetAutoFocus(false)
    searchBox.Instructions:SetText("Search for a specific font instance")

    local UpdateList
    self:CreateReloadButton(panel, searchBox, 10, 0, function() UpdateList() end)

    self:InitialiseInspector()
    local inspectorButton = CreateFrame("Button", nil, panel)
    inspectorButton:SetSize(18, 18)
    inspectorButton:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", -5, -17)
    inspectorButton:SetNormalAtlas("common-icon-visual")
    inspectorButton:SetHighlightAtlas("common-icon-visual")
    inspectorButton:GetHighlightTexture():SetAlpha(0.5)
    inspectorButton:SetScript("OnClick", function()
        addonTable:ToggleInspection()
    end)
    inspectorButton:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Toggle Inspector")
        GameTooltip:Show()
    end)
    inspectorButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 0)
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 100)
    scrollFrame:SetScrollChild(content)

    local buttonPool = CreateFramePool("Button", content, "BackdropTemplate", function(pool, button)
        button:Hide()
        button:ClearAllPoints()
        button:SetScript("OnEnter", nil)
        button:SetScript("OnLeave", nil)
        button:SetScript("OnClick", nil)
    end)

    local function InitializeButton(button)
        if button.isInitialized then return end
        button:SetHeight(20)

        button.bg = button:CreateTexture(nil, "BACKGROUND")
        button.bg:SetAllPoints()

        local hl = button:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 0.8, 0, 0.1)
        button:SetHighlightTexture(hl)

        button.text = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        button.text:SetPoint("LEFT", 5, 0)
        button.text:SetJustifyH("LEFT")
        button.text:SetTextColor(1, 0.82, 0) -- Gold Text

        -- Specific Icon (Green Gear)
        button.specificIcon = button:CreateTexture(nil, "ARTWORK")
        button.specificIcon:SetSize(14, 14)
        button.specificIcon:SetPoint("RIGHT", -5, 0)
        button.specificIcon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
        button.specificIcon:SetDesaturated(true)    -- Enable coloring
        button.specificIcon:SetVertexColor(0, 1, 0) -- Green

        -- Disabled Icon (White Gear)
        button.disabledIcon = button:CreateTexture(nil, "ARTWORK")
        button.disabledIcon:SetSize(14, 14)
        button.disabledIcon:SetPoint("RIGHT", button.specificIcon, "LEFT", -2, 0)
        button.disabledIcon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
        button.disabledIcon:SetDesaturated(true)    -- Enable coloring
        button.disabledIcon:SetVertexColor(1, 1, 1) -- White

        button.isInitialized = true
    end

    local function UpdateButtonIcons(button, fontName)
        if not button or not fontName then return end

        local specific = addonTable.db.specific[fontName]
        local hasSpecific = false
        local hasDisabled = false

        if specific then
            -- Check for any specific value (ignoring 'disabled' table)
            for k, v in pairs(specific) do
                if k ~= "disabled" then
                    hasSpecific = true
                    break
                end
            end
            -- Check for any disabled value
            if specific.disabled then
                for k, v in pairs(specific.disabled) do
                    if v then
                        hasDisabled = true
                        break
                    end
                end
            end
        end

        button.specificIcon:SetShown(hasSpecific)
        button.disabledIcon:SetShown(hasDisabled)

        if not hasSpecific then
            button.disabledIcon:SetPoint("RIGHT", -5, 0)
        else
            button.disabledIcon:SetPoint("RIGHT", button.specificIcon, "LEFT", -2, 0)
        end
    end

    UpdateList = function()
        local width = scrollFrame:GetWidth()
        if width > 0 then content:SetWidth(width) end
        buttonPool:ReleaseAll()

        local search = searchBox:GetText():lower()
        local keys = {}
        for k in pairs(self.originalValues) do
            -- Filter out dynamic instances without names because there's no point storing overrides for them
            if (search == "" or k:lower():find(search)) and not k:lower():find("^table:") then
                table.insert(keys, k)
            end
        end
        table.sort(keys)

        local totalHeight = 0
        for i, fontName in ipairs(keys) do
            local button = buttonPool:Acquire()
            InitializeButton(button)

            button:SetWidth(width > 0 and width or 550)
            button.text:SetText(fontName)
            button:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -totalHeight)

            if i % 2 == 0 then
                button.bg:SetColorTexture(1, 1, 1, 0.03)
            else
                button.bg:SetColorTexture(0, 0, 0, 0.1)
            end

            UpdateButtonIcons(button, fontName)

            button:SetScript("OnEnter", function(self)
                -- Check if the tooltip is currently displaying this font and is not closing
                local isShowingThis = addonTable.comparisonTooltip
                    and addonTable.comparisonTooltip:IsShown()
                    and addonTable.comparisonTooltip.content.title:GetText() == fontName
                    and addonTable.comparisonTooltip.animState ~= "CLOSING"

                -- Show if it's not the inspected font OR if the tooltip needs to be restored
                if addonTable.inspectedFont ~= fontName or not isShowingThis then
                    addonTable:ShowComparison(self, fontName)
                end
            end)
            button:SetScript("OnLeave", function(self)
                if addonTable.inspectedFont ~= fontName then
                    addonTable:HideComparison()
                end
            end)
            button:SetScript("OnClick", function(self)
                if addonTable.inspectedFont == fontName then
                    addonTable.inspectedFont = nil
                    -- Refresh the tooltip to show non-edit mode instead of closing it
                    addonTable:ShowComparison(self, fontName)
                else
                    addonTable.inspectedFont = fontName
                    addonTable:ShowComparison(self, fontName)
                end
            end)
            button:Show()
            totalHeight = totalHeight + 20
        end
        content:SetHeight(math.max(totalHeight, 100))
    end

    -- Export Update function for Tooltip.lua to use
    addonTable.UpdateAdvancedListIcons = UpdateList

    searchBox:HookScript("OnTextChanged", UpdateList)
    panel:SetScript("OnShow", UpdateList)

    Settings.RegisterCanvasLayoutSubcategory(self.settingsCategory, panel, "Advanced")
end
