local addonName = ...
local AceAddon = LibStub("AceAddon-3.0")
local AceGUI = LibStub("AceGUI-3.0")

---@class Fontmancer: AceAddon
local Fontmancer = AceAddon:GetAddon(addonName)

function Fontmancer:PopulateList(container)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    container:AddChild(scroll)

    local fontList = {}
    for frameName, fontInfo in pairs(Fontmancer.originalFonts) do
        table.insert(fontList, {
            name = frameName,
            font = select(1, GetRegion(frameName):GetFont()),
            size = fontInfo.height,
            flags = fontInfo.flags or "None",
            color = fontInfo.colour,
            shadow = fontInfo.shadow
        })
    end

    local headers = { "Name", "Font", "Size", "Flags", "Color", "Shadow" }
    for _, header in ipairs(headers) do
        local headerLabel = AceGUI:Create("Label")
        headerLabel:SetText(header)
        headerLabel:SetWidth(150)
        headerLabel:SetFont(GameFontNormalLarge:GetFont())
        scroll:AddChild(headerLabel)
    end

    for _, fontData in ipairs(fontList) do
        local nameLabel = AceGUI:Create("Label")
        nameLabel:SetText(fontData.name)
        nameLabel:SetWidth(150)
        scroll:AddChild(nameLabel)

        local fontLabel = AceGUI:Create("Label")
        fontLabel:SetText(fontData.font)
        fontLabel:SetWidth(150)
        scroll:AddChild(fontLabel)

        local sizeLabel = AceGUI:Create("Label")
        sizeLabel:SetText(tostring(fontData.size))
        sizeLabel:SetWidth(150)
        scroll:AddChild(sizeLabel)

        local flagsLabel = AceGUI:Create("Label")
        flagsLabel:SetText(fontData.flags)
        flagsLabel:SetWidth(150)
        scroll:AddChild(flagsLabel)

        local colorLabel = AceGUI:Create("Label")
        local colorText = string.format("%.2f, %.2f, %.2f, %.2f",
            fontData.color.r, fontData.color.g, fontData.color.b, fontData.color.a)
        colorLabel:SetText(colorText)
        colorLabel:SetWidth(150)
        scroll:AddChild(colorLabel)

        local shadowLabel = AceGUI:Create("Label")
        local shadowText = string.format("Offset: (%.2f, %.2f), Color: (%.2f, %.2f, %.2f, %.2f)",
            fontData.shadow.offset.x, fontData.shadow.offset.y,
            fontData.shadow.colour.r, fontData.shadow.colour.g, fontData.shadow.colour.b, fontData.shadow.colour.a)
        shadowLabel:SetText(shadowText)
        shadowLabel:SetWidth(150)
        scroll:AddChild(shadowLabel)
    end
end
