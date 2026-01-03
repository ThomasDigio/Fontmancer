local addonName = ...
local AceAddon = LibStub("AceAddon-3.0")

---@class Fontmancer: AceAddon
local Fontmancer = AceAddon:GetAddon(addonName)

function Fontmancer:HookCallbacks()
    local fontMeta = getmetatable(CreateFont("FontmancerHookFont")).__index
    self:HookFontCallback(fontMeta)
    self:HookSpacingCallback(fontMeta)
    self:HookTextColorCallback(fontMeta)
    self:HookShadowColorCallback(fontMeta)
    self:HookShadowOffsetCallback(fontMeta)
end

function Fontmancer:HookFontCallback(metaTable)
    hooksecurefunc(metaTable, "SetFont", function(fontInstance, fontFile, height, flags)
        if self.isUpdating then return end
        local fontName = fontInstance:GetName()
        if not fontName then return end
        if not self.originalFonts[fontName] then
            self.originalFonts[fontName] = {}
        end
        self.originalFonts[fontName].height = height
        self.originalFonts[fontName].flags = flags or self.originalFonts[fontName].flags or ""
        self:ApplyFont(fontName, fontInstance)
    end)
end

function Fontmancer:HookSpacingCallback(metaTable)
    hooksecurefunc(metaTable, "SetSpacing", function(fontInstance, spacing)
        if self.isUpdating then return end
        local fontName = fontInstance:GetName()
        if not fontName then return end
        if not self.originalFonts[fontName] then
            self.originalFonts[fontName] = {}
        end
        self.originalFonts[fontName].offsets.spacing = spacing
        self:ApplySpacing(fontName, fontInstance)
    end)
end

function Fontmancer:HookTextColorCallback(metaTable)
    hooksecurefunc(metaTable, "SetTextColor", function(fontInstance, r, g, b, a)
        if self.isUpdating then return end
        local fontName = fontInstance:GetName()
        if not fontName then return end
        if not self.originalFonts[fontName] then
            self.originalFonts[fontName] = {}
        end
        self.originalFonts[fontName].colours.text = {
            r = r,
            g = g,
            b = b,
            a = a or
                self.originalFonts[fontName].colours.text.a or 1
        }
        self:ApplyTextColour(fontName, fontInstance)
    end)
end

function Fontmancer:HookShadowColorCallback(metaTable)
    hooksecurefunc(metaTable, "SetShadowColor", function(fontInstance, r, g, b, a)
        if self.isUpdating then return end
        local fontName = fontInstance:GetName()
        if not fontName then return end
        if not self.originalFonts[fontName] then
            self.originalFonts[fontName] = {}
        end
        self.originalFonts[fontName].colours.shadow = {
            r = r,
            g = g,
            b = b,
            a = a or
                self.originalFonts[fontName].colours.shadow.a or 1
        }
        self:ApplyShadowColour(fontName, fontInstance)
    end)
end

function Fontmancer:HookShadowOffsetCallback(metaTable)
    hooksecurefunc(metaTable, "SetShadowOffset", function(fontInstance, x, y)
        if self.isUpdating then return end
        local fontName = fontInstance:GetName()
        if not fontName then return end
        if not self.originalFonts[fontName] then
            self.originalFonts[fontName] = {}
        end
        self.originalFonts[fontName].offsets.shadow = { x = x, y = y }
        self:ApplyShadowOffset(fontName, fontInstance)
    end)
end

function Fontmancer:HookIndentCallback(metaTable)
    hooksecurefunc(metaTable, "SetIndentedWordWrap", function(fontInstance, indent)
        if self.isUpdating then return end
        local fontName = fontInstance:GetName()
        if not fontName then return end
        if not self.originalFonts[fontName] then
            self.originalFonts[fontName] = {}
        end
        self.originalFonts[fontName].indent = indent
        self:ApplyIndent(fontName, fontInstance)
    end)
end
