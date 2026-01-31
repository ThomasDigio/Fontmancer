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
        "Hover over any frame, and a tooltip will appear\n It will show all font instances used by said frame")
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

function addonTable:GetFontStrings(frame)
    local fontStrings = {}
    local seen = {}

    local function AddIfNotSeen(obj)
        if obj and not seen[obj] then
            seen[obj] = true
            table.insert(fontStrings, obj)
        end
    end

    -- Check if the object itself is a font string
    local isPossiblyFontString, isFontString = pcall(function() return frame:IsObjectType("FontString") end)
    if isPossiblyFontString and isFontString then
        AddIfNotSeen(frame)
    end

    -- Check if the object has a direct font string
    if frame.GetFontString and frame:GetFontString() then
        AddIfNotSeen(frame:GetFontString())
    end

    -- Check if the object's regions is/has a font string
    local hasPossiblyRegions, regions = pcall(function() return { frame:GetRegions() } end)
    if hasPossiblyRegions then
        for _, region in pairs(regions) do
            for _, fontObjects in ipairs(self:GetFontStrings(region)) do
                AddIfNotSeen(fontObjects)
            end
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

    -- Standard UI frames, can't use GetMouseFoci as that ignores non-interactive stuff
    local frame = EnumerateFrames()
    while frame do
        if not frame:IsForbidden() then
            local isPossiblyVisible, isVisible = pcall(function() return frame:IsVisible() end)
            if isPossiblyVisible and isVisible then
                local isPossiblyHovered, isHovered = pcall(function() return frame:IsMouseOver() end)
                if isPossiblyHovered and isHovered then
                    table.insert(focusedFrames, frame)
                end
            end
        end
        frame = EnumerateFrames(frame)
    end

    -- Nameplates
    local function TryAddNameplate(nameplate)
        if not nameplate:IsForbidden() then
            table.insert(focusedFrames, nameplate)
        end
    end

    if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
        local nameplate = C_NamePlate.GetNamePlateForUnit("mouseover")
        if nameplate then
            TryAddNameplate(nameplate)
            TryAddNameplate(nameplate.UnitFrame)
        end
    end

    return focusedFrames
end

function addonTable:PopulateTooltip()
    self:ClearTooltip()

    local focusedFrames = self:GetFocusedFrames()

    -- Sort by visual stacking order
    table.sort(focusedFrames, function(a, b)
        return (a:GetFrameLevel() or 0) > (b:GetFrameLevel() or 0)
    end)

    for _, focusedFrame in pairs(focusedFrames) do
        if focusedFrame ~= WorldFrame and focusedFrame ~= UIParent then
            local fontStrings = self:GetFontStrings(focusedFrame)

            if #fontStrings > 0 then
                local headerColour = self.databaseDefaults.colours.text
                self.inspectorTooltip:AddLine(focusedFrame:GetDebugName(), headerColour.r, headerColour.g, headerColour
                    .b)

                for _, fontString in pairs(fontStrings) do
                    local fontStringName = fontString:GetName() or fontString:GetDebugName() or "Anonymous"
                    local fontName = fontString:GetFontObject():GetName()
                    self.inspectorTooltip:AddLine("  - " ..
                        fontStringName .. ": |cffffffff" .. fontName .. "|r")
                end
                self.inspectorTooltip:AddLine(" ")
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
