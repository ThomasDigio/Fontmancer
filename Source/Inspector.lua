local addonName, addonTable = ...

addonTable.isInspecting = false
addonTable.inspectorWindowBackground = nil
addonTable.inspectorWindow = nil
addonTable.inspectorTooltip = nil
addonTable.tooltipUpdater = nil

function addonTable:InitialiseInspector()
    -- Create the window to exit inspection mode
    self.inspectorWindowBackground = CreateFrame("Frame", "FontmancerInspectorBackground")
    self.inspectorWindowBackground:SetSize(300, 125)
    self.inspectorWindowBackground:SetPoint("CENTER")
    self.inspectorWindowBackground:SetFrameStrata("DIALOG")
    self.inspectorWindowBackground:SetToplevel(true)
    self.inspectorWindowBackground:SetMovable(true)
    self.inspectorWindowBackground:SetScript("OnMouseDown", function(selfWindow)
        selfWindow:StartMoving()
    end)
    self.inspectorWindowBackground:SetScript("OnMouseUp", function(selfWindow)
        selfWindow:StopMovingOrSizing()
    end)
    self.inspectorWindowBackground:Hide()
    self.inspectorWindow = CreateFrame("Frame", "FontmancerInspectorWindow", self.inspectorWindowBackground,
        "DialogBorderTemplate")
    self.inspectorWindow.text = self.inspectorWindow:CreateFontString("FontmancerInspectorDescription", "OVERLAY",
        "GameFontNormalSmall")
    self.inspectorWindow.text:SetPoint("CENTER", self.inspectorWindow, "CENTER", 0, 10)
    self.inspectorWindow.text:SetText(
        "Hover over any frame, and a tooltip will appear\n It will show you all the texts used by said frame")
    local inspectorHeader = CreateFrame("Frame", "FontmancerInspectorHeader", self.inspectorWindow,
        "DialogHeaderTemplate")
    inspectorHeader.text = inspectorHeader:CreateFontString("FontmancerInspectorHeaderText", "OVERLAY", "GameFontNormal")
    inspectorHeader.text:SetPoint("CENTER")
    inspectorHeader.text:SetText("Inspector")
    local exitButton = CreateFrame("Button", "FontmancerInspectorExitButton", self.inspectorWindow,
        "GameMenuButtonTemplate")
    exitButton:SetPoint("CENTER", self.inspectorWindow, "BOTTOM", 0, 30)
    exitButton:SetText("Exit")
    exitButton:SetScript("OnClick", function()
        self:ToggleInspection()
    end)

    -- Create the tooltip that will contain the results
    self.inspectorTooltip = CreateFrame("GameTooltip", "FontmancerInspectorTooltip", UIParent, "GameTooltipTemplate")
end

function addonTable:ConcatenateFontTables(firstTable, secondTable)
    for _, value in pairs(secondTable) do
        table.insert(firstTable, value)
    end

    return firstTable
end

function addonTable:GetInspectedFonts(frame)
    local fontStrings = {}

    -- Check if the object itself is a font string
    local isPossiblyFontString, isFontString = pcall(function() return frame:IsObjectType("FontString") end)
    if isPossiblyFontString and isFontString then
        table.insert(fontStrings, frame)
    end

    -- Check if the object has a direct font string
    if frame.GetFontString and frame:GetFontString() then
        table.insert(fontStrings, frame:GetFontString())
    end

    -- Check if the object's regions is/has a font string
    local hasPossiblyRegions, regions = pcall(function() return frame:GetRegions() end)
    if hasPossiblyRegions then
        for _, region in pairs({ regions }) do
            fontStrings = self:ConcatenateFontTables(fontStrings, self:GetInspectedFonts(region))
        end
    end

    -- Check if the object's children is/has a font string
    local hasPossiblyChildren, children = pcall(function() return frame:GetChildren() end)
    if hasPossiblyChildren then
        for _, child in pairs({ children }) do
            fontStrings = self:ConcatenateFontTables(fontStrings, self:GetInspectedFonts(child))
        end
    end

    return fontStrings
end

function addonTable:ClearTooltip()
    self.inspectorTooltip:Hide()
    self.inspectorTooltip:ClearLines()

    -- Also have to reset the owner for it to show
    self.inspectorTooltip:SetOwner(self.inspectorWindow, "ANCHOR_NONE")
    self.inspectorTooltip:SetPoint("TOPLEFT", self.inspectorWindow, "TOPRIGHT", 0, 0)
end

function addonTable:GetFocusedFrames()
    local focusedFrames = {}
    local frame = EnumerateFrames()
    while frame do
        local isPossiblyShown, isShown = pcall(function() return frame:IsShown() end)
        local isPossiblyVisible, isVisible = pcall(function() return frame:IsVisible() end)
        local isPossiblyHovered, isHovered = pcall(function() return frame:IsMouseOver() end)
        if isPossiblyShown and isShown and isPossiblyVisible and isVisible and isPossiblyHovered and isHovered then
            table.insert(focusedFrames, frame)
        end
        frame = EnumerateFrames(frame)
    end
    return focusedFrames
end

function addonTable:PopulateTooltip()
    if not self.isInspecting then
        return
    end

    self:ClearTooltip()

    local headerColour = self.databaseDefaults.colours.text
    for _, focusedFrame in pairs(self:GetFocusedFrames()) do
        if focusedFrame ~= WorldFrame and focusedFrame ~= UIParent then
            self.inspectorTooltip:AddLine(focusedFrame:GetDebugName(), headerColour.r,
                headerColour.g, headerColour.b)

            local fonts = self:GetInspectedFonts(focusedFrame)
            if #fonts > 0 then
                self.inspectorTooltip:AddLine(" Has text:")
                for _, fontString in pairs(fonts) do
                    self.inspectorTooltip:AddLine("  " .. fontString:GetDebugName())
                end
            else
                self.inspectorTooltip:AddLine(" Has no text")
            end
        end
    end

    self.inspectorTooltip:Show()
end

function addonTable:ToggleInspection()
    self.isInspecting = not self.isInspecting

    if self.isInspecting then
        self.inspectorWindowBackground:Show()
        self.tooltipUpdater = C_Timer.NewTicker(0.5, function()
            self:PopulateTooltip()
        end)
    else
        self.tooltipUpdater:Cancel()
        self:ClearTooltip()
        self.inspectorWindowBackground:Hide()
    end
end
