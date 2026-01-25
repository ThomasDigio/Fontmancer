local addonName, addonTable = ...

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
    else
        return tostring(val or "-")
    end
end


function addonTable:CreateComparisonTooltip()
    if self.comparisonTooltip then return self.comparisonTooltip end

    local tooltip = CreateFrame("Frame", addonName .. "ComparisonTooltip", UIParent, "BackdropTemplate")
    tooltip:SetFrameStrata("TOOLTIP")

    -- Rounded borders using UI-Tooltip-Border
    tooltip:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    tooltip:SetBackdropColor(0.08, 0.08, 0.1, 0.95)
    tooltip:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    tooltip:SetWidth(300) -- Initial default, will be overridden dynamically
    tooltip:SetHeight(1)  -- Start collapsed

    local content = CreateFrame("Frame", nil, tooltip)
    tooltip.content = content
    content:SetPoint("TOPLEFT", 15, -15)
    content:SetPoint("BOTTOMRIGHT", -15, 15)
    content:SetAlpha(0)
    content.title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    content.title:SetPoint("TOPLEFT", 0, 0)
    content.title:SetPoint("TOPRIGHT", content:GetWidth(), 0)
    content.subTitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    content.subTitle:SetPoint("TOPLEFT", content.title, "BOTTOMLEFT", 0, -4)
    content.subTitle:SetPoint("TOPRIGHT", content.title, "BOTTOMRIGHT", 0, -4)
    content.subTitle:SetJustifyH("RIGHT")
    content.subTitle:SetText("Original  ->  Current")

    local separator = content:CreateTexture(nil, "ARTWORK")
    separator:SetColorTexture(0.3, 0.3, 0.3, 0.5)
    separator:SetHeight(1)
    separator:SetPoint("TOPLEFT", content.subTitle, "BOTTOMLEFT", 0, -8)
    separator:SetPoint("RIGHT", 0, 0)
    content.separator = separator

    content.rows = {}
    local prevObj = separator
    for i, label in ipairs({ "Height", "Flags", "Spacing", "Text Color", "Shadow Color", "Shadow X", "Shadow Y" }) do
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(18)
        row:SetPoint("TOPLEFT", prevObj, "BOTTOMLEFT", 0, -4)
        row:SetPoint("RIGHT", 0, 0)
        row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        row.label:SetPoint("LEFT", 0, 0)
        row.label:SetText(label)
        row.val = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        row.val:SetPoint("RIGHT", 0, 0)
        content.rows[label] = row
        prevObj = row
    end

    tooltip.animState = "CLOSED" -- CLOSED, OPENING, OPEN, CLOSING
    tooltip.targetHeight = 0
    tooltip.animSpeed = 8        -- Speed of the slide
    tooltip.fadeSpeed = 0.1      -- Speed of the text fade
    tooltip:SetScript("OnUpdate", function(self, elapsed)
        if self.animState == "OPENING" then
            -- Animate Height
            local h = self:GetHeight()
            local diff = self.targetHeight - h

            if math.abs(diff) < 0.5 then
                self:SetHeight(self.targetHeight)
                -- Height done, start fading content
                local a = self.content:GetAlpha()
                a = a + (elapsed / self.fadeSpeed)
                if a >= 1 then
                    self.content:SetAlpha(1)
                    self.animState = "OPEN"
                else
                    self.content:SetAlpha(a)
                end
            else
                -- Smooth slide
                self:SetHeight(h + (diff * self.animSpeed * elapsed))
            end
        elseif self.animState == "CLOSING" then
            -- Animate Content Fade Out FIRST
            local a = self.content:GetAlpha()
            if a > 0 then
                a = a - (elapsed / self.fadeSpeed)
                self.content:SetAlpha(math.max(a, 0))
            else
                -- Once content is gone, Shrink Height
                local h = self:GetHeight()
                if h <= 2 then
                    self:SetHeight(1)
                    self:Hide()
                    self.animState = "CLOSED"
                else
                    self:SetHeight(h + ((0 - h) * self.animSpeed * elapsed))
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

    content.title:SetText(fontName)

    local original = self.originalFonts[fontName]
    local fontObj = _G[fontName]

    local function FillRow(label, origVal, currVal, type)
        local row = content.rows[label]
        if not row then return end

        if not original then
            row.val:SetText("|cff808080No Data|r")
            return
        end

        local changed
        if type == "color" then
            changed = (origVal.r ~= currVal.r or origVal.g ~= currVal.g or origVal.b ~= currVal.b)
        else
            changed = (origVal ~= currVal)
        end

        -- Original value is always White
        -- Current value is Green if changed, or White if same
        local origColor = "|cffffffff"
        local currColor = changed and "|cff00ff00" or "|cffffffff"

        local text = string.format("%s%s|r  ->  %s%s|r", origColor, FormatValue(origVal, type), currColor,
            FormatValue(currVal, type))
        row.val:SetText(text)
    end

    if original and fontObj then
        local _, curHeight, curFlags = fontObj:GetFont()
        local r, g, b = fontObj:GetTextColor()
        local sr, sg, sb = fontObj:GetShadowColor()
        local sx, sy = fontObj:GetShadowOffset()

        FillRow("Height", original.height, curHeight, "number")
        FillRow("Flags", original.flags, curFlags, "flags")
        FillRow("Spacing", original.offsets.spacing, fontObj:GetSpacing(), "number")
        FillRow("Text Color", original.colours.text, { r = r, g = g, b = b }, "color")
        FillRow("Shadow Color", original.colours.shadow, { r = sr, g = sg, b = sb }, "color")
        FillRow("Shadow X", original.offsets.shadow.x, sx, "number")
        FillRow("Shadow Y", original.offsets.shadow.y, sy, "number")
    end

    -- We measure all the text strings to find the widest row
    local maxTextWidth = 0
    local titleWidth = content.title:GetStringWidth()
    if titleWidth > maxTextWidth then maxTextWidth = titleWidth end
    for _, row in pairs(content.rows) do
        local width = row.label:GetStringWidth() + row.val:GetStringWidth() + 40 -- 40px padding between label and value
        if width > maxTextWidth then maxTextWidth = width end
    end

    -- Apply Width (with outer padding included, e.g. +30px total for left/right margins)
    tooltip:SetWidth(math.max(300, maxTextWidth + 30))

    -- Setup Position & Visibility
    tooltip:ClearAllPoints()
    tooltip:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 5, 0)
    tooltip:Show()

    -- Title (20) + SubTitle (15) + Separator (8) + 7 Rows * (18+4) + Padding (30)
    tooltip.targetHeight = 20 + 15 + 8 + (7 * 22) + 30

    -- Start Animation
    content:SetAlpha(0)
    if tooltip.animState == "CLOSED" then
        tooltip:SetHeight(1)
    end
    tooltip.animState = "OPENING"
end

function addonTable:HideComparison()
    local tooltip = self.comparisonTooltip
    if tooltip then
        tooltip.animState = "CLOSING"
    end
end

function addonTable:CreateAdvancedOptionsPanel()
    local panel = CreateFrame("Frame", addonName .. "AdvancedPanel")
    panel.name = "Advanced"
    local logo = self:CreatePanelHeader(panel)

    local listingHeader = self:CreateSectionHeader(panel, "Listing", logo)

    local searchBox = CreateFrame("EditBox", nil, panel, "SearchBoxTemplate")
    searchBox:SetSize(400, 22)
    searchBox:SetPoint("TOPLEFT", listingHeader, "BOTTOMLEFT", 5, -15)
    searchBox:SetAutoFocus(false)
    searchBox.Instructions:SetText("Search for a specific font instance")
    local UpdateList -- Forward declaration
    self:CreateReloadButton(panel, searchBox, 10, 0, function() UpdateList() end)

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

        button.isInitialized = true
    end

    UpdateList = function()
        local width = scrollFrame:GetWidth()
        if width > 0 then content:SetWidth(width) end
        buttonPool:ReleaseAll()

        local search = searchBox:GetText():lower()
        local keys = {}
        for k in pairs(self.originalFonts) do
            if search == "" or k:lower():find(search) then
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

            button:SetScript("OnEnter", function(self)
                addonTable:ShowComparison(self, fontName)
            end)
            button:SetScript("OnLeave", function(self)
                addonTable:HideComparison()
            end)

            button:Show()
            totalHeight = totalHeight + 20
        end
        content:SetHeight(math.max(totalHeight, 100))
    end
    searchBox:HookScript("OnTextChanged", UpdateList)
    panel:SetScript("OnShow", UpdateList)

    -- Register with Blizzard settings
    Settings.RegisterCanvasLayoutSubcategory(self.settingsCategory, panel, "Advanced")
end
