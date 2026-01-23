local addonName, addonTable = ...

function addonTable:CreateSectionHeader(parent, text, relativeTo)
    local headerFrame = CreateFrame("Frame", nil, parent)
    headerFrame:SetHeight(20)
    headerFrame:SetPoint("TOP", relativeTo, "BOTTOM", 0, -20)
    headerFrame:SetPoint("LEFT", parent, "LEFT", 10, 0)
    headerFrame:SetPoint("RIGHT", parent, "RIGHT", -10, 0)

    local headerText = headerFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerText:SetText(text)
    headerText:SetTextColor(1, 0.82, 0)
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

function addonTable:CreateTriStateCheck(label, key, descriptionFrame, descriptionText, relativeTo, xOffset, isFirst)
    local button = CreateFrame("CheckButton", nil, self.scrollContent, "UICheckButtonTemplate")
    if isFirst then
        button:SetPoint("TOPLEFT", relativeTo, "TOPLEFT", xOffset, 0)
    else
        button:SetPoint("LEFT", relativeTo, "RIGHT", xOffset, 0)
    end

    button.text:SetText(label)
    button.text:SetFontObject("GameFontNormalLarge")
    button.text:SetTextColor(1, 0.82, 0)

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
        addonTable:ReplaceAllFonts()
        button:GetScript("OnEnter")(button)
    end)

    button:SetScript("OnEnter", function()
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
    end)

    button:SetScript("OnLeave", function()
        UIFrameFadeOut(descriptionFrame, 0.2, descriptionFrame:GetAlpha(), 0)
    end)

    UpdateVisuals()
    return button
end

function addonTable:CreateSlider(name, text, minVal, maxVal, step, dbTable, dbKey, relativeTo, xOff, yOff)
    local slider = CreateFrame("Slider", addonName .. name .. "Slider", self.scrollContent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", xOff, yOff)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(dbTable[dbKey])
    _G[slider:GetName() .. "Low"]:SetText(minVal)
    _G[slider:GetName() .. "High"]:SetText(maxVal)
    _G[slider:GetName() .. "Text"]:SetText(text .. ": " .. dbTable[dbKey])

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        dbTable[dbKey] = value
        _G[self:GetName() .. "Text"]:SetText(text .. ": " .. value)
        addonTable:ReplaceAllFonts()
    end)
    return slider
end

function addonTable:CreateColourPicker(label, dbTable, relativeTo, xOff, yOff, callbackFunc)
    local frame = CreateFrame("Frame", nil, self.scrollContent)
    frame:SetSize(200, 30)
    frame:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", xOff, yOff)

    local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    check:SetPoint("LEFT", 0, 0)
    check.text:SetText("Override " .. label .. " colour")
    check:SetChecked(dbTable.isEnabled)

    local swatch = CreateFrame("Button", nil, frame)
    swatch:SetSize(20, 20)
    swatch:SetPoint("LEFT", check.text, "RIGHT", 10, 0)
    local bg = swatch:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(dbTable.r, dbTable.g, dbTable.b)
    swatch.bg = bg

    check:SetScript("OnClick", function(self)
        dbTable.isEnabled = self:GetChecked()

        if dbTable.isEnabled then
            addonTable:ReplaceAllFonts()
        else
            addonTable:ReplaceAllFonts(callbackFunc)
        end
    end)

    swatch:SetScript("OnClick", function()
        local oldR, oldG, oldB, oldA = dbTable.r, dbTable.g, dbTable.b, dbTable.a

        local function ColorCallback()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = ColorPickerFrame:GetColorAlpha()
            if not a and ColorPickerFrame.GetOpacity then a = ColorPickerFrame:GetOpacity() end

            dbTable.r, dbTable.g, dbTable.b, dbTable.a = r, g, b, a
            swatch.bg:SetColorTexture(r, g, b)

            if dbTable.isEnabled then addonTable:ReplaceAllFonts() end
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
                if dbTable.isEnabled then addonTable:ReplaceAllFonts() end
            end
        })
    end)
end
