local addonName, addonTable = ...

function addonTable:CreateOptionsPanel()
    local panel = CreateFrame("Frame", addonName .. "OptionsPanel")
    local logo = self:CreatePanelHeader(panel)

    local fontHeader = self:CreateSectionHeader(panel, "Font", logo)
    local UpdateReloadWarning -- Declare function early so the dropdown can call it
    local fontDropDown = self:CreateFontDropdown(panel)
    fontDropDown:SetPoint("TOPLEFT", fontHeader, "BOTTOMLEFT", 30, -20)
    fontDropDown:SetWidth(200)
    self:SetupFontMenu(fontDropDown,
        function() return addonTable.db.selectedFont end,
        function(val)
            addonTable.db.selectedFont = val
            addonTable:ReplaceAllFonts()
            if UpdateReloadWarning then UpdateReloadWarning() end
        end
    )

    local warningFrame = CreateFrame("Frame", nil, panel)
    local warningIcon = warningFrame:CreateTexture(nil, "ARTWORK")
    warningIcon:SetSize(15, 15)
    warningIcon:SetAtlas("icons_64x64_important")
    warningIcon:SetPoint("LEFT", fontDropDown, "RIGHT", 10, 0)
    warningIcon:Hide()
    local warningText = warningFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    warningText:SetPoint("LEFT", warningIcon, "RIGHT", 3, 0)
    warningText:SetPoint("RIGHT", fontHeader, "BOTTOMRIGHT", -10, -15)
    warningText:SetText(
        "|cffff9900A full exit/logout is needed for the new font to take effect on certain texts, such as floating combat text|r")
    warningText:Hide()
    UpdateReloadWarning = function()
        -- Show the warning when we change the font
        if self.db.selectedFont ~= self.initiallySelectedFont then
            warningIcon:Show()
            warningText:Show()
        else
            warningIcon:Hide()
            warningText:Hide()
        end
    end
    local nameplateCheckbox = self:CreateCheckbox("Exclude Nameplates", nil, panel)
    nameplateCheckbox:SetPoint("TOPLEFT", fontDropDown, "BOTTOMLEFT", 0, -10)
    nameplateCheckbox:SetChecked(addonTable.db.excludeNameplates)
    local reloadButton = self:CreateReloadButton(panel, nameplateCheckbox.text, 10, 0, C_UI.Reload)
    reloadButton:SetAlpha(0)
    local reloadWarning = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    reloadWarning:SetText("|cffff9900You will need to reload your UI for that option to take effect!|r")
    reloadWarning:SetPoint("LEFT", reloadButton, "RIGHT", 5, 0)
    -- Manually set the color on this specific string to block SetTextColor from updating the alpha, ensuring the text stays hidden
    -- Not fully sure I understand how that works but it works
    reloadWarning:SetTextColor(1, 1, 1, 1)
    reloadWarning:SetAlpha(0)
    local function UpdateNameplateReload()
        -- Show the warning when we toggle the checkbox on
        local shouldShow = addonTable.db.excludeNameplates and not addonTable.initialExcludeNameplates
        if shouldShow then
            UIFrameFadeIn(reloadButton, 0.2, reloadButton:GetAlpha(), 1)
            UIFrameFadeIn(reloadWarning, 0.2, reloadWarning:GetAlpha(), 1)
        else
            UIFrameFadeOut(reloadButton, 0.2, reloadButton:GetAlpha(), 0)
            UIFrameFadeOut(reloadWarning, 0.2, reloadWarning:GetAlpha(), 0)
        end
    end
    nameplateCheckbox:SetScript("OnClick", function(self)
        addonTable.db.excludeNameplates = self:GetChecked()
        addonTable:ReplaceAllFonts()
        UpdateNameplateReload()
    end)

    local flagsHeader = self:CreateSectionHeader(panel, "Flags", nameplateCheckbox)
    local flagRowAnchor = CreateFrame("Frame", nil, panel)
    flagRowAnchor:SetSize(1, 1)
    flagRowAnchor:SetPoint("TOP", flagsHeader, "BOTTOM", 0, -20)
    flagRowAnchor:SetPoint("LEFT", panel, "LEFT", 20, 0)
    flagRowAnchor:SetPoint("RIGHT", panel, "RIGHT", -20, 0)
    local flagsDescription = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    flagsDescription:SetPoint("TOP", flagRowAnchor, "BOTTOM", 0, -50)
    flagsDescription:SetSize(500, 40)
    -- Manually set the color on this specific string to block SetTextColor from updating the alpha, ensuring the text stays hidden
    -- Not fully sure I understand how that works but it works
    flagsDescription:SetTextColor(1, 1, 1, 1)
    flagsDescription:SetAlpha(0)
    local outlineCheck = self:CreateTriStateCheckbox("Outline", "OUTLINE", panel, flagsDescription,
        "Renders the font with a black outline")
    outlineCheck:SetPoint("TOP", flagRowAnchor, "TOP", -25, 0)
    local thickCheck = self:CreateTriStateCheckbox("Thick", "THICKOUTLINE", panel, flagsDescription,
        "Renders the font with a thick black outline")
    thickCheck:SetPoint("LEFT", outlineCheck.text, "RIGHT", 40, 0)
    local monoCheck = self:CreateTriStateCheckbox("Monochrome", "MONOCHROME", panel, flagsDescription,
        "Renders the font without antialiasing")
    monoCheck:SetPoint("RIGHT", outlineCheck, "LEFT", -135, 0)

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
    self:CreateColourPicker("text", panel, addonTable.db.colours.text, colourHeader, 100, -20,
        addonTable.ApplyTextColour)
    self:CreateColourPicker("shadow", panel, addonTable.db.colours.shadow, colourHeader, 330, -20,
        addonTable.ApplyShadowColour)

    -- Register with Blizzard settings
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Fontmancer")
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category
end
