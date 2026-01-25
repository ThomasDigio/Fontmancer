local addonName, addonTable = ...
local LSM = LibStub("LibSharedMedia-3.0")


function addonTable:CreateOptionsPanel()
    local panel = CreateFrame("Frame", addonName .. "OptionsPanel")
    local logo = self:CreatePanelHeader(panel)

    local fontHeader = self:CreateSectionHeader(panel, "Font", logo)
    local fontDropDown = CreateFrame("DropdownButton", addonName .. "FontDropDown", panel,
        "WowStyle1DropdownTemplate")
    fontDropDown:SetPoint("TOPLEFT", fontHeader, "BOTTOMLEFT", 0, -20)
    fontDropDown:SetWidth(200)
    fontDropDown:SetText(addonTable.db.selectedFont or "Select Font")
    local UpdateReloadWarning -- Declare function early so the dropdown can call it
    fontDropDown:SetupMenu(function(dropdown, rootDescription)
        rootDescription:SetMinimumWidth(300)

        local fonts = LSM:HashTable(LSM.MediaType.FONT)
        local sorted = {}
        for k in pairs(fonts) do table.insert(sorted, k) end
        table.sort(sorted)
        if #sorted == 0 then
            rootDescription:CreateButton("No fonts found", function() end)
            return
        end

        for _, fontName in ipairs(sorted) do
            local radio = rootDescription:CreateRadio(fontName,
                function() return addonTable.db.selectedFont == fontName end,
                function()
                    addonTable.db.selectedFont = fontName
                    addonTable:ReplaceAllFonts()
                    UpdateReloadWarning()
                end)
            -- We create a custom dropdown where each font option is rendered in its own style
            radio:AddInitializer(function(button)
                -- For that, we have to create our own custom FontString because we're not allowed to modify the default one
                if not button.customFontLayer then
                    local overlay = CreateFrame("Frame", nil, button)
                    overlay:SetAllPoints(button)

                    local fs = overlay:CreateFontString(nil, "ARTWORK")
                    fs:SetPoint("LEFT", button, "LEFT", 25, 0)
                    overlay.fs = fs

                    button.customFontLayer = overlay

                    -- Hide our custom text so it doesn't overlap on future dropdowns
                    button:HookScript("OnHide", function(self)
                        if self.customFontLayer then
                            self.customFontLayer:Hide()
                        end
                    end)
                end

                local fs = button.customFontLayer.fs
                local fontPath = LSM:Fetch(LSM.MediaType.FONT, fontName)
                if fontPath then
                    fs:SetFont(fontPath, 14, "")
                end
                fs:SetText(fontName)

                button.customFontLayer:Show()

                -- Hide the original text
                if button.fontString then
                    button.fontString:SetAlpha(0)
                end
            end)
        end
    end)

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
    local nameplateCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    nameplateCheck:SetPoint("TOPLEFT", fontDropDown, "BOTTOMLEFT", 0, -10)
    nameplateCheck.text:SetText("Exclude Nameplates")
    nameplateCheck:SetChecked(addonTable.db.excludeNameplates)
    local reloadButton = self:CreateReloadButton(panel, nameplateCheck.text, 10, 0, C_UI.Reload)
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
    nameplateCheck:SetScript("OnClick", function(self)
        addonTable.db.excludeNameplates = self:GetChecked()
        addonTable:ReplaceAllFonts()
        UpdateNameplateReload()
    end)

    local flagsHeader = self:CreateSectionHeader(panel, "Flags", nameplateCheck)
    local flagRowAnchor = CreateFrame("Frame", nil, panel)
    flagRowAnchor:SetSize(1, 1)
    flagRowAnchor:SetPoint("TOP", flagsHeader, "BOTTOM", 0, -15)
    flagRowAnchor:SetPoint("LEFT", panel, "LEFT", 20, 0)
    flagRowAnchor:SetPoint("RIGHT", panel, "RIGHT", -20, 0)
    local flagsDescription = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    flagsDescription:SetPoint("TOP", flagRowAnchor, "BOTTOM", 0, -50)
    flagsDescription:SetSize(500, 40)
    -- Manually set the color on this specific string to block SetTextColor from updating the alpha, ensuring the text stays hidden
    -- Not fully sure I understand how that works but it works
    flagsDescription:SetTextColor(1, 1, 1, 1)
    flagsDescription:SetAlpha(0)
    local monoCheck = self:CreateTriStateCheck("Monochrome", "MONOCHROME", panel, flagsDescription,
        "Renders the font without antialiasing",
        flagRowAnchor,
        70, true)
    local outlineCheck = self:CreateTriStateCheck("Outline", "OUTLINE", panel, flagsDescription,
        "Renders the font with a black outline",
        monoCheck,
        135)
    self:CreateTriStateCheck("Thick", "THICKOUTLINE", panel, flagsDescription,
        "Renders the font with a thick black outline",
        outlineCheck, 100)

    local offsetHeader = self:CreateSectionHeader(panel, "Offsets", flagsDescription)
    local sizeSlider = self:CreateSlider("Size", "Size", panel, -10, 10, 0.5, addonTable.db.offsets,
        "height",
        offsetHeader,
        100, -30)
    local spaceSlider = self:CreateSlider("Spacing", "Spacing", panel, -10, 10, 0.5, addonTable.db.offsets,
        "spacing",
        sizeSlider, 0, -40)
    local shadowXSlider = self:CreateSlider("ShadowX", "Shadow X", panel, -10, 10, 0.5,
        addonTable.db.offsets.shadow, "x",
        offsetHeader, 330, -30)
    self:CreateSlider("ShadowY", "Shadow Y", panel, -10, 10, 0.5, addonTable.db.offsets.shadow, "y",
        shadowXSlider, 0, -40)

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
