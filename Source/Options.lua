local addonName, addonTable = ...

function addonTable:CreateOptionsPanel()
    local panel = CreateFrame("Frame", addonName .. "OptionsPanel")
    local logo = self:CreatePanelHeader(panel)

    local fadeTooltip = self:CreateFadeTooltip(UIParent)

    local fontHeader = self:CreateSectionHeader(panel, "Font", logo)
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
    fontDropDown:SetPoint("TOPRIGHT", fontHeader, "BOTTOM", -40, -20)
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

    local nameplateCheckbox = self:CreateCheckbox("Exclude Nameplates", nil, panel)
    nameplateCheckbox:SetPoint("TOPLEFT", fontHeader, "BOTTOM", 40, -20)
    nameplateCheckbox:SetChecked(addonTable.db.excludeNameplates)
    local reloadButton = self:CreateReloadButton(panel, nameplateCheckbox.text, 10, 0, C_UI.Reload)
    reloadButton:Hide()
    reloadButton:HookScript("OnEnter", function(self)
        fadeTooltip:ShowMessage(self, "You will need to reload your UI for that option to take effect!")
    end)
    reloadButton:HookScript("OnLeave", function()
        fadeTooltip:HideMessage()
    end)
    local function UpdateNameplateReload()
        -- Show the warning when we toggle the checkbox on
        local shouldShow = addonTable.db.excludeNameplates and not addonTable.initialExcludeNameplates
        if shouldShow then
            UIFrameFadeIn(reloadButton, 0.2, reloadButton:GetAlpha(), 1)
        else
            UIFrameFadeOut(reloadButton, 0.2, reloadButton:GetAlpha(), 0)
        end
    end
    nameplateCheckbox:SetScript("OnClick", function(self)
        addonTable.db.excludeNameplates = self:GetChecked()
        addonTable:UpdateAllStoredInstances()
        UpdateNameplateReload()
    end)

    local flagsHeader = self:CreateSectionHeader(panel, "Flags", nameplateCheckbox)
    local flagsDescription = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    flagsDescription:SetSize(500, 40)
    -- Manually set the color on this specific string to block SetTextColor from updating the alpha, ensuring the text stays hidden
    -- Not fully sure I understand how that works but it works
    flagsDescription:SetTextColor(1, 1, 1, 1)
    flagsDescription:SetAlpha(0)
    local monoCheck = self:CreateTriStateCheckbox("Monochrome", "MONOCHROME", panel, flagsDescription,
        "Renders the font without antialiasing")
    monoCheck:SetPoint("TOPRIGHT", flagsHeader, "BOTTOM", -180, -60)
    local outlineCheck = self:CreateTriStateCheckbox("Outline", "OUTLINE", panel, flagsDescription,
        "Renders the font with a black outline")
    outlineCheck:SetPoint("TOP", flagsHeader, "BOTTOM", 0, -60)
    local thickCheck = self:CreateTriStateCheckbox("Thick", "THICKOUTLINE", panel, flagsDescription,
        "Renders the font with a thick black outline")
    thickCheck:SetPoint("TOPLEFT", flagsHeader, "BOTTOM", 130, -60)

    flagsDescription:SetPoint("TOP", outlineCheck, "BOTTOM", 0, -20)

    local outlineBorder = panel:CreateTexture(nil, "ARTWORK")
    outlineBorder:SetAtlas("Adventure-MissionEnd-Line")
    outlineBorder:SetHeight(10)
    outlineBorder:SetPoint("LEFT", outlineCheck, "TOPLEFT", -5, 10)
    outlineBorder:SetPoint("RIGHT", thickCheck.text, "TOPRIGHT", 5, 5)
    local excludeDarkTextCheckbox = self:CreateCheckbox("Exclude dark texts", nil, panel)
    excludeDarkTextCheckbox:SetPoint("BOTTOM", outlineBorder, "TOP", -50, 5)
    excludeDarkTextCheckbox:SetChecked(addonTable.db.excludeFlagsDarkText)
    excludeDarkTextCheckbox:SetScript("OnClick", function(self)
        addonTable.db.excludeFlagsDarkText = self:GetChecked()
        addonTable:UpdateAllStoredInstances()
    end)
    excludeDarkTextCheckbox:SetScript("OnEnter", function(self)
        fadeTooltip:ShowMessage(self,
            "Prevents text being almost unreadable due to the outline colour being so close to the text's")
    end)
    excludeDarkTextCheckbox:SetScript("OnLeave", function() fadeTooltip:HideMessage() end)

    local offsetHeader = self:CreateSectionHeader(panel, "Offsets", flagsDescription)
    local sizeSlider = self:CreateSlider("Size", "Size", panel, -10, 10, 0.5, addonTable.db.offsets, "height", "TOPRIGHT",
        offsetHeader, "BOTTOM", -20, -20)
    local spaceSlider = self:CreateSlider("Spacing", "Spacing", panel, -10, 10, 0.5, addonTable.db.offsets, "spacing",
        "TOP", sizeSlider, "BOTTOM", 0, -10)
    local shadowXSlider = self:CreateSlider("ShadowX", "Shadow X", panel, -10, 10, 0.5, addonTable.db.offsets.shadow, "x",
        "TOPLEFT", offsetHeader, "BOTTOM", 110, -20)
    self:CreateSlider("ShadowY", "Shadow Y", panel, -10, 10, 0.5, addonTable.db.offsets.shadow, "y", "TOP", shadowXSlider,
        "BOTTOM", 0, -10)

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
