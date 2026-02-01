local addonName, addonTable = ...
local LSM = LibStub("LibSharedMedia-3.0")

function addonTable:CreatePanelHeader(panel)
    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(25, 25)
    logo:SetPoint("TOPLEFT", 15, -15)
    logo:SetTexture(self.metadata.LOGO_PATH)
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 10, -2)
    title:SetText(self.metadata.TITLE)
    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("LEFT", title, "RIGHT", 20, 0)
    description:SetText(self.metadata.DESCRIPTION)
    return logo
end

function addonTable:CreateSectionHeader(parent, text, relativeTo)
    local headerFrame = CreateFrame("Frame", nil, parent)
    headerFrame:SetHeight(20)
    headerFrame:SetPoint("TOP", relativeTo, "BOTTOM", 0, -20)
    headerFrame:SetPoint("LEFT", parent, "LEFT", 10, 0)
    headerFrame:SetPoint("RIGHT", parent, "RIGHT", -10, 0)

    local headerText = headerFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    headerText:SetText(text)
    headerText:SetPoint("CENTER")

    local leftLine = headerFrame:CreateTexture(nil, "ARTWORK")
    leftLine:SetHeight(15)
    leftLine:SetAtlas("AftLevelup-CloudyLineLeft")
    leftLine:SetPoint("LEFT", headerFrame, "LEFT")
    leftLine:SetPoint("RIGHT", headerText, "LEFT", -5, 0)

    local rightLine = headerFrame:CreateTexture(nil, "ARTWORK")
    rightLine:SetHeight(15)
    rightLine:SetAtlas("AftLevelup-CloudyLineRight")
    rightLine:SetPoint("LEFT", headerText, "RIGHT", 5, 0)
    rightLine:SetPoint("RIGHT", headerFrame, "RIGHT")

    return headerFrame
end

function addonTable:CreateCheckbox(label, key, parent, onEnter, onLeave)
    local button = CreateFrame("CheckButton", key, parent, "SettingsCheckboxTemplate")
    button.text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    button.text:SetPoint("LEFT", button, "RIGHT", 5, 0)
    button.text:SetText(label)
    button:SetScript("OnEnter", function()
        if onEnter then onEnter(button) end
    end)
    button:SetScript("OnLeave", function()
        if onLeave then onLeave(button) end
    end)
    return button
end

function addonTable:CreateTriStateCheckbox(label, key, parent, descriptionFrame, descriptionText)
    local button = self:CreateCheckbox(label, nil, parent, function()
        local state = addonTable.db.flags[key]
        local subText = ""
        if state == false then
            subText = "|cff808080(Left as default)|r"
        elseif state == true then
            subText = "|cff00ff00(Applied everywhere)|r"
        else
            subText = "|cffff0000(Removed everywhere)|r"
        end

        descriptionFrame:SetText(descriptionText .. "\n" .. subText)
        UIFrameFadeIn(descriptionFrame, 0.2, descriptionFrame:GetAlpha(), 1)
    end, function()
        UIFrameFadeOut(descriptionFrame, 0.2, descriptionFrame:GetAlpha(), 0)
    end)
    button.text:SetFontObject("GameFontNormalLarge") -- Makes the text a bit larger

    local function UpdateVisuals()
        local state = addonTable.db.flags[key]
        local tex = button:GetCheckedTexture()
        if state == false then
            button:SetChecked(false)
        elseif state == true then
            button:SetChecked(true)
            tex:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        else
            button:SetChecked(true)
            tex:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        end
    end

    button:SetScript("OnClick", function()
        local current = addonTable.db.flags[key]
        if current == false then
            addonTable.db.flags[key] = true
        elseif current == true then
            addonTable.db.flags[key] = nil
        else
            addonTable.db.flags[key] = false
        end
        UpdateVisuals()
        addonTable:UpdateAllStoredInstances()
        button:GetScript("OnEnter")(button)
    end)

    UpdateVisuals()
    return button
end

function addonTable:CreateSlider(name, label, parent, minVal, maxVal, step, dbTable, dbKey, anchor, relativeTo,
                                 relativeAnchor, xOffset, yOffset)
    local slider = CreateFrame("Frame", addonName .. name .. "Slider", parent, "MinimalSliderWithSteppersTemplate")
    slider:Init(dbTable[dbKey], minVal, maxVal, (maxVal - minVal) / step, nil)

    slider:SetWidth(160)
    slider:SetPoint(anchor, relativeTo, relativeAnchor, xOffset, yOffset)

    slider.Text = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    slider.Text:SetPoint("RIGHT", slider, "LEFT", -10, 0)
    slider.Text:SetJustifyH("RIGHT")

    slider.FormatValue = function(self, value)
        if step % 1 == 0 then
            return string.format("%d", value)
        else
            return string.format("%.1f", value)
        end
    end
    local function UpdateText(value)
        slider.Text:SetText(label .. ": " .. slider:FormatValue(value))
    end
    UpdateText(dbTable[dbKey])

    slider:RegisterCallback("OnValueChanged", function(self, value)
        dbTable[dbKey] = value
        UpdateText(value)
        addonTable:UpdateAllStoredInstances()
    end)

    return slider
end

function addonTable:CreateColourPicker(label, parent, dbTable, callbackFunc)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(200, 30)

    local checkbox = self:CreateCheckbox("Override " .. label .. " colour", nil, frame)
    checkbox:SetPoint("LEFT", 0, 0)
    checkbox:SetChecked(dbTable.isEnabled)
    checkbox:SetScript("OnClick", function(self)
        dbTable.isEnabled = self:GetChecked()

        if dbTable.isEnabled then
            addonTable:UpdateAllStoredInstances()
        else
            addonTable:UpdateAllStoredInstances(callbackFunc)
        end
    end)

    local swatch = CreateFrame("Button", nil, frame)
    swatch:SetSize(20, 20)
    swatch:SetPoint("LEFT", checkbox.text, "RIGHT", 10, 0)
    local bg = swatch:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(dbTable.r, dbTable.g, dbTable.b)
    swatch.bg = bg
    swatch:SetScript("OnClick", function()
        local oldR, oldG, oldB, oldA = dbTable.r, dbTable.g, dbTable.b, dbTable.a

        local function ColorCallback()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = ColorPickerFrame:GetColorAlpha()
            if not a and ColorPickerFrame.GetOpacity then a = ColorPickerFrame:GetOpacity() end

            dbTable.r, dbTable.g, dbTable.b, dbTable.a = r, g, b, a
            swatch.bg:SetColorTexture(r, g, b)

            if dbTable.isEnabled then addonTable:UpdateAllStoredInstances() end
        end

        ColorPickerFrame:SetupColorPickerAndShow({
            r = dbTable.r,
            g = dbTable.g,
            b = dbTable.b,
            opacity = dbTable.a,
            hasOpacity = true,
            swatchFunc = ColorCallback,
            opacityFunc = ColorCallback,
            cancelFunc = function()
                dbTable.r, dbTable.g, dbTable.b, dbTable.a = oldR, oldG, oldB, oldA
                swatch.bg:SetColorTexture(oldR, oldG, oldB)
                if dbTable.isEnabled then addonTable:UpdateAllStoredInstances() end
            end
        })
    end)
    return frame
end

function addonTable:CreateReloadButton(parent, relativeTo, xOffset, yOffset, callback)
    local reloadButton = CreateFrame("Button", nil, parent)
    reloadButton:SetSize(15, 15)
    reloadButton:SetPoint("LEFT", relativeTo, "RIGHT", xOffset, yOffset)
    reloadButton:SetNormalAtlas("UI-RefreshButton")
    reloadButton:SetHighlightAtlas("UI-RefreshButton")
    reloadButton:GetHighlightTexture():SetAlpha(0.5)

    local buttonTexture = reloadButton:GetNormalTexture()

    -- Click animation
    local animClick = buttonTexture:CreateAnimationGroup()
    local rotateClick = animClick:CreateAnimation("Rotation")
    rotateClick:SetDegrees(-360)
    rotateClick:SetDuration(0.5)
    rotateClick:SetSmoothing("OUT")
    reloadButton:SetScript("OnClick", function()
        animClick:Stop()
        animClick:Play()
        if callback then callback() end
    end)

    -- Hover animation
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
    return reloadButton
end

function addonTable:CreateFontDropdown(parent)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    return dropdown
end

function addonTable:SetupFontMenu(dropdown, getVal, setVal)
    dropdown:SetText(getVal() or "Select Font")
    dropdown:SetupMenu(function(dropdown, rootDescription)
        local fonts = LSM:HashTable(LSM.MediaType.FONT)
        local sorted = {}
        for k in pairs(fonts) do table.insert(sorted, k) end
        table.sort(sorted)

        for _, fontName in ipairs(sorted) do
            local radioButton = rootDescription:CreateRadio(fontName,
                function() return getVal() == fontName end,
                function()
                    setVal(fontName)
                    dropdown:SetText(fontName)
                end)

            -- Custom dropdown styling to preview the font
            -- We can't directly edit the button's font string for some stupid bs reason so we have to do this bs workaround that I hate
            -- IT'S BS
            radioButton:AddInitializer(function(button)
                local overlay

                -- We scan children to find it because 'button.overlay' references are often wiped during recycling
                for _, child in ipairs({ button:GetChildren() }) do
                    if child.IsFontmancerPreview then
                        overlay = child
                        break
                    end
                end

                if not overlay then
                    overlay = CreateFrame("Frame", nil, button)
                    overlay:SetAllPoints(button)

                    overlay.IsFontmancerPreview = true

                    overlay.fontString = overlay:CreateFontString(nil, "ARTWORK")
                    overlay.fontString:SetPoint("LEFT", button, "LEFT", 25, 0)

                    overlay:SetScript("OnUpdate", function(self)
                        -- If the parent's default text is visible, it means the button has been reset for a non-Fontmancer menu
                        if self:GetParent().fontString:GetAlpha() > 0 then
                            self:Hide()
                        end
                    end)
                end

                local fontPath = LSM:Fetch(LSM.MediaType.FONT, fontName)
                if fontPath then
                    overlay.fontString:SetFont(fontPath, 14, "")
                end

                overlay.fontString:SetText(fontName) -- Must be set after the font

                -- Hide the original text and show the overlay instead
                button.fontString:SetAlpha(0)
                overlay:Show()
            end)
        end

        rootDescription:SetScrollMode(300) -- Needs to be done last
    end)
end

function addonTable:CreateFadeTooltip(parent)
    local tooltip = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    tooltip:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    tooltip:SetBackdropColor(0.08, 0.08, 0.1, 0.9)
    tooltip:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:Hide()

    tooltip.text = tooltip:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tooltip.text:SetPoint("TOPLEFT", 10, -10)
    tooltip.text:SetPoint("BOTTOMRIGHT", -10, 10)
    tooltip.text:SetJustifyH("CENTER")

    function tooltip:ShowMessage(owner, text)
        self:SetPoint("BOTTOM", owner, "TOP", 0, 5)
        self.text:SetText(text)
        -- Dynamic width based on text, capped at half screen width
        self:SetWidth(math.min(GetScreenWidth() * 0.5, self.text:GetStringWidth() + 20))
        self:SetHeight(self.text:GetStringHeight() + 20)

        UIFrameFadeIn(self, 0.2, 0, 1)
    end

    function tooltip:HideMessage()
        UIFrameFadeOut(self, 0.2, self:GetAlpha(), 0)
    end

    return tooltip
end
