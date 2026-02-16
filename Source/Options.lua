local addonName, addonTable = ...

function addonTable:CreateOptionsPanel(fadeTooltip)
    local panel = CreateFrame("Frame", addonName .. "OptionsPanel")
    local logo = self:CreatePanelHeader(panel, fadeTooltip)

    local generalHeader = self:CreateSectionHeader(panel, "General", logo)
    local warningIcon = panel:CreateTexture(nil, "ARTWORK")
    warningIcon:SetSize(15, 15)
    warningIcon:SetAtlas("icons_64x64_important")
    warningIcon:Hide()
    warningIcon:SetScript("OnEnter", function(self)
        fadeTooltip:ShowMessage(self,
            "|cffff9900A full exit/logout is needed for the new font to take effect on certain texts, such as floating combat text|r")
    end)
    warningIcon:SetScript("OnLeave", function()
        fadeTooltip:HideMessage()
    end)
    local fontDropDown = self:CreateFontDropdown(panel)
    fontDropDown:SetPoint("TOPRIGHT", generalHeader, "BOTTOM", -40, -20)
    fontDropDown:SetWidth(200)
    self:SetupFontMenu(fontDropDown,
        function() return addonTable.db.selectedFont end,
        function(val)
            addonTable.db.selectedFont = val
            addonTable:UpdateAllStoredInstances()

            -- Show the warning when we change the font
            if self.db.selectedFont ~= self.initiallySelectedFont then
                warningIcon:Show()
            else
                warningIcon:Hide()
            end
        end
    )
    warningIcon:SetPoint("LEFT", fontDropDown, "RIGHT", 10, 0)

    local hookCheckbox = self:CreateCheckbox("Keep applied", nil, panel, function(self)
        fadeTooltip:ShowMessage(self,
            "Without it, Fontmancer applies settings once on UI load and lets them be overridden")
    end, function()
        fadeTooltip:HideMessage()
    end)
    hookCheckbox:SetPoint("TOPLEFT", generalHeader, "BOTTOM", 40, -20)
    hookCheckbox:SetChecked(addonTable.db.enableHooks)
    hookCheckbox:SetScript("OnClick", function(self)
        addonTable.db.enableHooks = self:GetChecked()
    end)

    local RefreshExclusionList
    panel:SetScript("OnShow", function() RefreshExclusionList() end)
    local exclusionInput = CreateFrame("EditBox", nil, panel, "SearchBoxTemplate")
    exclusionInput:SetSize(200, 20)
    exclusionInput:SetAutoFocus(false)
    exclusionInput:SetPoint("TOPLEFT", fontDropDown, "BOTTOMLEFT", 0, -15)
    exclusionInput:SetPoint("RIGHT", hookCheckbox.text, "RIGHT", 0, 0)
    exclusionInput.Instructions:SetText("Enter a frame name to exclude (partial or full, case-insensitive)")
    local exclusionReload = self:CreateReloadButton(panel, exclusionInput, 10, 0, C_UI.Reload)
    exclusionReload:Hide()
    exclusionReload:HookScript("OnEnter", function(self)
        fadeTooltip:ShowMessage(self, "Reloading your UI is recommended when adding exclusions or changing their states")
    end)
    exclusionReload:HookScript("OnLeave", function() fadeTooltip:HideMessage() end)
    local function ShowExclusionReload()
        UIFrameFadeIn(exclusionReload, 0.2, exclusionReload:GetAlpha(), 1)
    end
    exclusionInput:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        if text and text ~= "" then
            addonTable.db.exclusionList[text] = "FULL"
            self:SetText("")
            self:ClearFocus()
            RefreshExclusionList()
            addonTable:UpdateAllStoredInstances()
            ShowExclusionReload()
        end
    end)

    local scrollBox = CreateFrame("Frame", nil, panel, "WowScrollBoxList")
    scrollBox:SetHeight(150)
    scrollBox:SetPoint("TOPLEFT", exclusionInput, "BOTTOMLEFT", 0, -10)
    scrollBox:SetPoint("RIGHT", exclusionInput, "RIGHT", -20, 0) -- Leave space for scrollbar
    local scrollBar = CreateFrame("EventFrame", nil, panel, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 5, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 5, 0)
    local listBg = scrollBox:CreateTexture(nil, "BACKGROUND")
    listBg:SetAllPoints()
    listBg:SetColorTexture(0, 0, 0, 0.2)

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(24)
    view:SetElementInitializer("BackdropTemplate", function(f, elementData)
        f.elementData = elementData -- Bind data for scripts to access
        f:Show()

        -- One-time creation of child frames and scripts
        if not f.initialized then
            f.initialized = true

            f.text = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            f.text:SetPoint("LEFT", f, "LEFT", 5, 0)
            f.text:SetPoint("RIGHT", f, "RIGHT", -100, 0)
            f.text:SetJustifyH("LEFT")
            f.text:SetWordWrap(false)

            -- Toggle Button
            f.toggleBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
            f.toggleBtn:SetSize(80, 20)
            f.toggleBtn:SetPoint("RIGHT", -30, 0)

            f.toggleBtn:SetScript("OnClick", function(self)
                local parent = self:GetParent()
                local key = parent.elementData.key
                local current = addonTable.db.exclusionList[key]

                addonTable.db.exclusionList[key] = (current == "FULL") and "PARTIAL" or "FULL"
                RefreshExclusionList()
                addonTable:UpdateAllStoredInstances()
                ShowExclusionReload()
            end)

            f.toggleBtn:SetScript("OnEnter", function(self)
                local data = self:GetParent().elementData
                local isFull = (addonTable.db.exclusionList[data.key] == "FULL")
                fadeTooltip:ShowMessage(self, isFull
                    and "Fully ignore this element (Requires Reload to revert)"
                    or "Apply Font file only; ignore color/size/shadows")
            end)
            f.toggleBtn:SetScript("OnLeave", function() fadeTooltip:HideMessage() end)

            f.deleteButton = CreateFrame("Button", nil, f)
            f.deleteButton:SetSize(16, 16)
            f.deleteButton:SetPoint("LEFT", f.toggleBtn, "RIGHT", 5, 0)
            f.deleteButton:SetNormalAtlas("transmog-icon-remove")
            f.deleteButton:SetHighlightAtlas("transmog-icon-remove")
            f.deleteButton:GetHighlightTexture():SetAlpha(0.5)

            f.deleteButton:SetScript("OnClick", function(self)
                local key = self:GetParent().elementData.key
                addonTable.db.exclusionList[key] = nil
                RefreshExclusionList()
                addonTable:UpdateAllStoredInstances()
                ShowExclusionReload()
            end)
        end

        f.text:SetText(elementData.key)

        if elementData.state == "FULL" then
            f.toggleBtn:SetText("Excluded")
            f.toggleBtn:GetFontString():SetTextColor(1, 0.5, 0.5) -- Red
        else
            f.toggleBtn:SetText("Font Only")
            f.toggleBtn:GetFontString():SetTextColor(0.5, 1, 0.5) -- Green
        end
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    -- The view is required before assigning the data provider
    local dataProvider = CreateDataProvider()
    scrollBox:SetDataProvider(dataProvider)

    -- Now that we have the data provider, we can define the function
    RefreshExclusionList = function()
        local sortedItems = {}
        for k, v in pairs(addonTable.db.exclusionList) do
            table.insert(sortedItems, { key = k, state = v })
        end
        table.sort(sortedItems, function(a, b) return a.key < b.key end)

        dataProvider:Flush()
        for _, item in ipairs(sortedItems) do
            dataProvider:Insert(item)
        end
    end

    local flagsHeader = self:CreateSectionHeader(panel, "Flags", scrollBox)
    local darkTextInfo = "Dark texts will be excluded from the flag's effects to maintain readability"
    local monoCheck = self:CreateTriStateCheckbox("Monochrome", "MONOCHROME", panel, fadeTooltip,
        "Renders the font without antialiasing")
    monoCheck:SetPoint("TOPRIGHT", flagsHeader, "BOTTOM", -180, -20)
    local outlineCheck = self:CreateTriStateCheckbox("Outline", "OUTLINE", panel, fadeTooltip,
        "Renders the font with a black outline" .. '\n' .. darkTextInfo)
    outlineCheck:SetPoint("TOP", flagsHeader, "BOTTOM", 0, -20)
    local thickCheck = self:CreateTriStateCheckbox("Thick", "THICKOUTLINE", panel, fadeTooltip,
        "Renders the font with a thick black outline" .. '\n' .. darkTextInfo)
    thickCheck:SetPoint("TOPLEFT", flagsHeader, "BOTTOM", 130, -20)

    local offsetHeader = self:CreateSectionHeader(panel, "Offsets", outlineCheck)
    local sizeSlider = self:CreateSlider("Size", "Size", panel, -10, 10, 0.5, addonTable.db.offsets, "height", "TOPRIGHT",
        offsetHeader, "BOTTOM", -20, -20)
    local spaceSlider = self:CreateSlider("Spacing", "Spacing", panel, -10, 10, 0.5, addonTable.db.offsets, "spacing",
        "TOP", sizeSlider, "BOTTOM", 0, -7)
    local shadowXSlider = self:CreateSlider("ShadowX", "Shadow X", panel, -10, 10, 0.5, addonTable.db.offsets.shadow, "x",
        "TOPLEFT", offsetHeader, "BOTTOM", 110, -20)
    self:CreateSlider("ShadowY", "Shadow Y", panel, -10, 10, 0.5, addonTable.db.offsets.shadow, "y", "TOP", shadowXSlider,
        "BOTTOM", 0, -7)

    local colourHeader = self:CreateSectionHeader(panel, "Colours", spaceSlider)
    local textColourPicker = self:CreateColourPicker("text", panel, addonTable.db.colours.text,
        addonTable.ApplyTextColour)
    textColourPicker:SetPoint("TOPRIGHT", colourHeader, "BOTTOM", -40, -20)
    local shadowColourPicker = self:CreateColourPicker("shadow", panel, addonTable.db.colours.shadow,
        addonTable.ApplyShadowColour)
    shadowColourPicker:SetPoint("TOPLEFT", colourHeader, "BOTTOM", 40, -20)

    -- Register with Blizzard settings
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Fontmancer")
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category
end
