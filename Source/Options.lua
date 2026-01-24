local addonName, addonTable = ...
local LSM = LibStub("LibSharedMedia-3.0")

addonTable.scrollContent = nil

function addonTable:CreateOptionsPanel()
    local panel = CreateFrame("Frame", addonName .. "OptionsPanel")

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    self.scrollContent = CreateFrame("Frame", nil, scrollFrame)
    self.scrollContent:SetSize(600, 700)
    scrollFrame:SetScrollChild(self.scrollContent)

    local title = self.scrollContent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 15, -15)
    title:SetText(self.metadata.TITLE)

    local aboutHeader = self:CreateSectionHeader(self.scrollContent, "About", title)
    local aboutLogo = self.scrollContent:CreateTexture(nil, "ARTWORK")
    aboutLogo:SetSize(64, 64)
    aboutLogo:SetPoint("TOPLEFT", aboutHeader, "BOTTOMLEFT", 10, -15)
    aboutLogo:SetTexture(self.metadata.LOGO_PATH)
    local aboutDescription = self.scrollContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    aboutDescription:SetPoint("LEFT", aboutLogo, "RIGHT", 35, -5)
    aboutDescription:SetText(self.metadata.DESCRIPTION)

    local fontHeader = self:CreateSectionHeader(self.scrollContent, "Font", aboutLogo)
    local fontDropDown = CreateFrame("DropdownButton", addonName .. "FontDropDown", self.scrollContent,
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

    local warningFrame = CreateFrame("Frame", nil, self.scrollContent)
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
    local nameplateCheck = CreateFrame("CheckButton", nil, self.scrollContent, "UICheckButtonTemplate")
    nameplateCheck:SetPoint("TOPLEFT", fontDropDown, "BOTTOMLEFT", 0, -10)
    nameplateCheck.text:SetText("Exclude Nameplates")
    nameplateCheck:SetChecked(addonTable.db.excludeNameplates)
    local reloadButton = CreateFrame("Button", nil, self.scrollContent)
    reloadButton:SetSize(15, 15)
    reloadButton:SetPoint("LEFT", nameplateCheck.text, "RIGHT", 10, 0)
    reloadButton:SetNormalAtlas("UI-RefreshButton")
    reloadButton:SetScript("OnClick", C_UI.Reload)
    reloadButton:SetAlpha(0)
    local buttonTexture = reloadButton:GetNormalTexture()
    local animIn = buttonTexture:CreateAnimationGroup()
    local rotateIn = animIn:CreateAnimation("Rotation")
    rotateIn:SetDegrees(-25)
    rotateIn:SetDuration(0.2)
    animIn:SetScript("OnFinished", function() buttonTexture:SetRotation(math.rad(-25)) end)
    local animOut = buttonTexture:CreateAnimationGroup()
    local rotateOut = animOut:CreateAnimation("Rotation")
    rotateOut:SetDegrees(25)
    rotateOut:SetDuration(0.2)
    animOut:SetScript("OnFinished", function() buttonTexture:SetRotation(0) end)
    reloadButton:SetScript("OnEnter", function()
        animIn:Play()
    end)
    reloadButton:SetScript("OnLeave", function()
        if animIn:IsPlaying() then
            animIn:Stop()
            buttonTexture:SetRotation(0)
        else
            buttonTexture:SetRotation(math.rad(-25))
            animOut:Play()
        end
    end)
    local reloadWarning = self.scrollContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
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

    local flagsHeader = self:CreateSectionHeader(self.scrollContent, "Flags", nameplateCheck)
    local flagRowAnchor = CreateFrame("Frame", nil, self.scrollContent)
    flagRowAnchor:SetSize(1, 1)
    flagRowAnchor:SetPoint("TOP", flagsHeader, "BOTTOM", 0, -15)
    flagRowAnchor:SetPoint("LEFT", self.scrollContent, "LEFT", 20, 0)
    flagRowAnchor:SetPoint("RIGHT", self.scrollContent, "RIGHT", -20, 0)
    local flagsDescription = self.scrollContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    flagsDescription:SetPoint("TOP", flagRowAnchor, "BOTTOM", 0, -50)
    flagsDescription:SetSize(500, 40)
    -- Manually set the color on this specific string to block SetTextColor from updating the alpha, ensuring the text stays hidden
    -- Not fully sure I understand how that works but it works
    flagsDescription:SetTextColor(1, 1, 1, 1)
    flagsDescription:SetAlpha(0)
    local monoCheck = self:CreateTriStateCheck("Monochrome", "MONOCHROME", flagsDescription,
        "Renders the font without antialiasing",
        flagRowAnchor,
        70, true)
    local outlineCheck = self:CreateTriStateCheck("Outline", "OUTLINE", flagsDescription,
        "Renders the font with a black outline",
        monoCheck,
        135)
    self:CreateTriStateCheck("Thick", "THICKOUTLINE", flagsDescription,
        "Renders the font with a thick black outline",
        outlineCheck, 100)

    local offsetHeader = self:CreateSectionHeader(self.scrollContent, "Offsets", flagsDescription)
    local sizeSlider = self:CreateSlider("Size", "Size", -10, 10, 0.5, addonTable.db.offsets, "height",
        offsetHeader,
        100, -30)
    local spaceSlider = self:CreateSlider("Spacing", "Spacing", -10, 10, 0.5, addonTable.db.offsets, "spacing",
        sizeSlider, 0, -40)
    local shadowXSlider = self:CreateSlider("ShadowX", "Shadow X", -10, 10, 0.5, addonTable.db.offsets.shadow, "x",
        offsetHeader, 330, -30)
    self:CreateSlider("ShadowY", "Shadow Y", -10, 10, 0.5, addonTable.db.offsets.shadow, "y",
        shadowXSlider, 0, -40)

    local colourHeader = self:CreateSectionHeader(self.scrollContent, "Colours", spaceSlider)
    self:CreateColourPicker("text", addonTable.db.colours.text, colourHeader, 100, -20,
        addonTable.ApplyTextColour)
    self:CreateColourPicker("shadow", addonTable.db.colours.shadow, colourHeader, 330, -20,
        addonTable.ApplyShadowColour)

    -- Register with Blizzard settings
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Fontmancer")
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category
end
