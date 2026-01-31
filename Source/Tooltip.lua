local addonName, addonTable = ...
local LSM = LibStub("LibSharedMedia-3.0")

local function FormatValue(val, type)
    if type == "number" then
        return string.format("%.1f", val or 0)
    elseif type == "color" then
        -- Returns a color swatch string
        local r = math.floor((val.r or 0) * 255)
        local g = math.floor((val.g or 0) * 255)
        local b = math.floor((val.b or 0) * 255)
        -- Explicit RGB tinting to ensure visibility.
        return string.format("|TInterface\\Buttons\\WHITE8x8:12:12:0:0:8:8:0:1:0:1:%d:%d:%d|t", r, g, b)
    elseif type == "flags" then
        if not val or val == "" then return "None" end
        return val
    elseif type == "font" then
        return val and val:match("([^/\\]+)$") or "-"
    else
        return tostring(val or "-")
    end
end

-- Helper: Get short font name
local function GetFontNameFromPath(path)
    if not path then return nil end
    local list = LSM:HashTable(LSM.MediaType.FONT)
    for name, p in pairs(list) do
        if p:lower() == path:lower() then return name end
    end
    return path:match("([^/\\]+)$") or path
end

function addonTable:CreateComparisonTooltip()
    if self.comparisonTooltip then return self.comparisonTooltip end

    local tooltip = CreateFrame("Frame", addonName .. "ComparisonTooltip", UIParent, "BackdropTemplate")
    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:EnableMouse(true)
    table.insert(UISpecialFrames, tooltip:GetName())

    tooltip:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    tooltip:SetBackdropColor(0.08, 0.08, 0.1, 0.95)
    tooltip:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    tooltip:SetWidth(300)
    tooltip:SetHeight(1) -- Start collapsed

    local content = CreateFrame("Frame", nil, tooltip)
    tooltip.content = content
    content:SetPoint("TOPLEFT", 15, -15)
    content:SetPoint("BOTTOMRIGHT", -15, 15)
    content:SetAlpha(0)

    -- Title
    content.title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    content.title:SetPoint("TOPLEFT", 0, 0)
    content.title:SetPoint("TOPRIGHT", content:GetWidth(), 0)
    content.title:SetTextColor(1, 0.82, 0) -- Gold

    -- Subtitle
    content.subTitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    content.subTitle:SetPoint("TOPLEFT", content.title, "BOTTOMLEFT", 0, -4)
    content.subTitle:SetPoint("TOPRIGHT", content.title, "BOTTOMRIGHT", 0, -4)
    content.subTitle:SetJustifyH("RIGHT")

    local separator = content:CreateTexture(nil, "ARTWORK")
    separator:SetColorTexture(0.3, 0.3, 0.3, 0.5)
    separator:SetHeight(1)
    separator:SetPoint("TOPLEFT", content.subTitle, "BOTTOMLEFT", 0, -8)
    separator:SetPoint("RIGHT", 0, 0)
    content.separator = separator

    content.rows = {}
    local prevObj = separator
    local rowsConfig = {
        { label = "Font",         key = "font",    type = "font" },
        { label = "Height",       key = "height",  type = "number" },
        { label = "Flags",        key = "flags",   type = "flags" },
        { label = "Spacing",      key = "spacing", type = "number" },
        { label = "Text Color",   key = "text",    type = "color" },
        { label = "Shadow Color", key = "shadow",  type = "color" },
        { label = "Shadow X",     key = "shadowX", type = "number" },
        { label = "Shadow Y",     key = "shadowY", type = "number" },
    }

    for i, config in ipairs(rowsConfig) do
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(22)
        row:SetPoint("TOPLEFT", prevObj, "BOTTOMLEFT", 0, -4)
        row:SetPoint("RIGHT", 0, 0)
        row.key = config.key
        row.type = config.type

        -- Toggle Button
        local toggle = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        toggle:SetSize(20, 20)
        toggle:SetPoint("LEFT", 0, 0)
        row.toggle = toggle

        -- Label
        row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        row.label:SetText(config.label)
        row.label:SetTextColor(1, 0.82, 0) -- Gold

        -- Value Text (Non-Edit Mode)
        row.val = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        row.val:SetPoint("RIGHT", 0, 0)

        -- Status Icon (Non-Edit Mode, used for swatches)
        local statusIcon = row:CreateTexture(nil, "ARTWORK")
        statusIcon:SetSize(14, 14)
        statusIcon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
        statusIcon:SetDesaturated(true) -- Allow recoloring from gold
        statusIcon:SetPoint("RIGHT", row.val, "LEFT", -5, 0)
        statusIcon:Hide()
        row.statusIcon = statusIcon

        -- Reset Button (Edit Mode)
        local resetButton = CreateFrame("Button", nil, row)
        resetButton:SetSize(16, 16)
        resetButton:SetNormalAtlas("transmog-icon-remove")
        resetButton:SetHighlightAtlas("transmog-icon-remove")
        resetButton:GetHighlightTexture():SetAlpha(0.5)
        resetButton:SetPoint("RIGHT", 0, 0)
        resetButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Reset to global settings")
            GameTooltip:Show()
        end)
        resetButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row.resetBtn = resetButton

        -- Editor Container (Edit Mode)
        local editorFrame = CreateFrame("Frame", nil, row)
        editorFrame:SetHeight(20)
        -- Anchors are set dynamically in ShowComparison to align columns
        row.editorFrame = editorFrame

        if config.type == "color" then
            local swatch = CreateFrame("Button", nil, editorFrame)
            swatch:SetSize(20, 20)
            swatch:SetPoint("RIGHT", 0, 0)
            swatch.bg = swatch:CreateTexture(nil, "BACKGROUND")
            swatch.bg:SetAllPoints()
            swatch.bg:SetColorTexture(1, 1, 1)
            row.editorWidget = swatch
        elseif config.type == "font" then
            local dropdown = addonTable:CreateFontDropdown(editorFrame)
            dropdown:SetHeight(20)
            -- Anchor to both sides so it fills the frame
            dropdown:SetPoint("LEFT", 0, 0)
            dropdown:SetPoint("RIGHT", 0, 0)
            row.editorWidget = dropdown
        else
            local editBox = CreateFrame("EditBox", nil, editorFrame, "InputBoxTemplate")
            editBox:SetHeight(20)
            -- Anchor to both sides so it fills the frame
            editBox:SetPoint("LEFT", 0, 0)
            editBox:SetPoint("RIGHT", 0, 0)
            editBox:SetAutoFocus(false)
            row.editorWidget = editBox
        end

        content.rows[config.label] = row
        prevObj = row
    end

    -- Animation Logic
    tooltip.animState = "CLOSED"
    tooltip.targetHeight = 0
    tooltip.animSpeed = 8
    tooltip.fadeSpeed = 0.1
    tooltip:SetScript("OnUpdate", function(self, elapsed)
        if self.animState == "OPENING" then
            local h = self:GetHeight()
            local diff = self.targetHeight - h
            if math.abs(diff) < 0.5 then
                self:SetHeight(self.targetHeight)
                local a = self.content:GetAlpha()
                a = a + (elapsed / self.fadeSpeed)
                if a >= 1 then
                    self.content:SetAlpha(1)
                    self.animState = "OPEN"
                else
                    self.content:SetAlpha(a)
                end
            else
                self:SetHeight(h + (diff * self.animSpeed * elapsed))
            end
        elseif self.animState == "CLOSING" then
            local a = self.content:GetAlpha()
            if a > 0 then
                a = a - (elapsed / self.fadeSpeed)
                self.content:SetAlpha(math.max(a, 0))
            else
                local h = self:GetHeight()
                if h <= 2 then
                    self:SetHeight(1)
                    self:Hide()
                    self.animState = "CLOSED"
                else
                    local newHeight = h + ((0 - h) * self.animSpeed * elapsed)
                    self:SetHeight(newHeight)

                    -- Fade out if height is small to avoid border clipping
                    if newHeight < 20 then
                        self:SetAlpha(math.min(1, newHeight / 20))
                    end
                end
            end
        end
    end)

    self.comparisonTooltip = tooltip
    return tooltip
end

function addonTable:ShowComparison(anchorFrame, fontName)
    local tooltip = self:CreateComparisonTooltip()
    local content = tooltip.content
    local isEditing = (self.inspectedFont == fontName)

    content.title:SetText(fontName)
    content.subTitle:SetText("|cffffffffOriginal|r |cffFFD100/|r |cff00ccffGlobal|r |cffFFD100/|r |cff00ff00Override|r")

    local original = self.originalValues[fontName]
    local fontObj = _G[fontName]
    local specific = self.db.specific[fontName]
    local disabled = specific and specific.disabled or {}

    local function Refresh()
        self:ReplaceFont(fontName)
        if self.UpdateAdvancedListIcons then self:UpdateAdvancedListIcons() end
        self:ShowComparison(anchorFrame, fontName)
    end

    local function SaveSpecific(key, value)
        self.db.specific[fontName] = self.db.specific[fontName] or {}
        self.db.specific[fontName][key] = value
        Refresh()
    end

    local function ClearSpecific(key)
        if self.db.specific[fontName] then
            self.db.specific[fontName][key] = nil
        end
        Refresh()
    end

    local function SetDisabled(key, isDisabled)
        self.db.specific[fontName] = self.db.specific[fontName] or {}
        self.db.specific[fontName].disabled = self.db.specific[fontName].disabled or {}
        if isDisabled then
            self.db.specific[fontName].disabled[key] = true
        else
            self.db.specific[fontName].disabled[key] = nil
        end
        Refresh()
    end

    local function FillRow(label, currVal, type, specificKey)
        local row = content.rows[label]
        if not row then return end

        if not original then
            row.val:SetText("|cff808080No Data|r")
            row.editorFrame:Hide()
            row.resetBtn:Hide()
            row.toggle:Hide()
            row.statusIcon:Hide()
            return
        end

        local isSpecific = specific and specific[specificKey] ~= nil
        local isDisabled = disabled[specificKey]
        local isManaged = not isDisabled

        -- Color Logic
        local valueColor = "|cff00ccff"       -- Blue (Global/Modified default)
        local iconR, iconG, iconB = 0, 0.8, 1 -- Blue

        if isDisabled then
            valueColor = "|cffffffff" -- White (Disabled/Original)
            iconR, iconG, iconB = 1, 1, 1
        elseif isSpecific then
            valueColor = "|cff00ff00" -- Green (Specific)
            iconR, iconG, iconB = 0, 1, 0
        end

        -- Toggle & Reset
        if isEditing then
            row.toggle:Show()
            row.toggle:SetChecked(isManaged)
            row.toggle:SetScript("OnClick", function(self)
                SetDisabled(specificKey, not self:GetChecked())
            end)
            row.label:SetPoint("LEFT", row.toggle, "RIGHT", 5, 0)

            row.resetBtn:SetShown(isSpecific and isManaged)
            row.resetBtn:SetScript("OnClick", function() ClearSpecific(specificKey) end)
        else
            row.toggle:Hide()
            row.resetBtn:Hide()
            row.label:SetPoint("LEFT", 0, 0)
        end

        -- Content Display
        if isEditing and isManaged then
            -- EDIT MODE
            row.val:Hide()
            row.statusIcon:Hide()
            row.editorFrame:Show()
            local widget = row.editorWidget

            if type == "color" then
                widget.bg:SetColorTexture(currVal.r, currVal.g, currVal.b)
                widget:SetScript("OnClick", function()
                    local function ColorCallback()
                        local r, g, b = ColorPickerFrame:GetColorRGB()
                        local a = ColorPickerFrame:GetColorAlpha()
                        if not a and ColorPickerFrame.GetOpacity then a = ColorPickerFrame:GetOpacity() end
                        SaveSpecific(specificKey, { r = r, g = g, b = b, a = a })
                    end
                    ColorPickerFrame:SetupColorPickerAndShow({
                        r = currVal.r,
                        g = currVal.g,
                        b = currVal.b,
                        opacity = currVal.a or 1,
                        hasOpacity = true,
                        swatchFunc = ColorCallback,
                        opacityFunc = ColorCallback
                    })
                end)
            elseif type == "font" then
                self:SetupFontMenu(widget,
                    function() return currVal end,
                    function(val) SaveSpecific(specificKey, val) end
                )
            else
                -- Format numbers (e.g. 10.0) so they don't appear as 10.000000953674
                local text = currVal
                if type == "number" then
                    text = string.format("%.1f", currVal or 0)
                end

                widget:SetText(text)
                widget:SetScript("OnEnterPressed", function(self)
                    local text = self:GetText()
                    local val = text
                    if type == "number" then val = tonumber(text) or 0 end
                    self:ClearFocus()
                    SaveSpecific(specificKey, val)
                end)
            end
        else
            -- NON-EDIT MODE
            row.editorFrame:Hide()
            row.val:Show()

            -- Show icon for swatches in non-edit mode
            if type == "color" then
                row.statusIcon:Show()
                row.statusIcon:SetVertexColor(iconR, iconG, iconB)
            else
                row.statusIcon:Hide()
            end

            local text = string.format("%s%s|r", valueColor, FormatValue(currVal, type))
            row.val:SetText(text)
        end
    end

    if original and fontObj then
        local _, curHeight, curFlags = fontObj:GetFont()
        local r, g, b = fontObj:GetTextColor()
        local sr, sg, sb = fontObj:GetShadowColor()
        local sx, sy = fontObj:GetShadowOffset()

        local currentFile, _, _ = fontObj:GetFont()
        local currentName = GetFontNameFromPath(currentFile)
        if specific and specific.font then currentName = specific.font end

        FillRow("Font", currentName, "font", "font")
        FillRow("Height", curHeight, "number", "height")
        FillRow("Flags", curFlags, "flags", "flags")
        FillRow("Spacing", fontObj:GetSpacing(), "number", "spacing")
        FillRow("Text Color", { r = r, g = g, b = b }, "color", "text")
        FillRow("Shadow Color", { r = sr, g = sg, b = sb }, "color", "shadow")
        FillRow("Shadow X", sx, "number", "shadowX")
        FillRow("Shadow Y", sy, "number", "shadowY")
    end

    -- Sizing Logic
    -- We calculate the width required for Non-Edit mode (Label + Value).
    -- This ensures the tooltip size is consistent regardless of Edit Mode.
    local maxTextWidth = 0
    local maxLabelWidth = 0

    -- 1. Check Title Width
    local titleWidth = content.title:GetStringWidth()
    if titleWidth > maxTextWidth then maxTextWidth = titleWidth end

    -- 2. Check Row Widths (Label + Value) and track max label for alignment
    for _, row in pairs(content.rows) do
        local labelW = row.label:GetStringWidth()
        if labelW > maxLabelWidth then maxLabelWidth = labelW end

        local rowWidth = labelW + row.val:GetStringWidth() + 40
        if rowWidth > maxTextWidth then maxTextWidth = rowWidth end
    end

    -- 3. Set Tooltip Width
    tooltip:SetWidth(math.max(300, maxTextWidth + 30))

    -- 4. Dynamic Layout for Edit Mode
    if isEditing then
        for _, row in pairs(content.rows) do
            if row.editorFrame then
                row.editorFrame:ClearAllPoints()
                -- Right anchor: Reset button (or right edge if hidden)
                row.editorFrame:SetPoint("RIGHT", row.resetBtn, "LEFT", -5, 0)

                -- Left anchor: Align to the longest label + Toggle width + Gaps
                -- Toggle(20) + Gap(5) + maxLabelWidth + Gap(10)
                row.editorFrame:SetPoint("LEFT", row, "LEFT", 20 + 5 + maxLabelWidth + 10, 0)
            end
        end
    end

    tooltip:ClearAllPoints()
    tooltip:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 5, 0)
    tooltip:Show()
    tooltip:SetAlpha(1) -- Reset alpha since it fades during close
    tooltip.targetHeight = 20 + 15 + 8 + (8 * 26) + 30
    content:SetAlpha(0)
    if tooltip.animState == "CLOSED" then tooltip:SetHeight(1) end
    tooltip.animState = "OPENING"
end

function addonTable:HideComparison()
    local tooltip = self.comparisonTooltip
    if tooltip then tooltip.animState = "CLOSING" end
end
