local addonName = ...
local AceAddon = LibStub("AceAddon-3.0")

---@class Fontmancer: AceAddon
local Fontmancer = AceAddon:GetAddon(addonName)

function Fontmancer:HookCallbacks()
    local fontMeta = getmetatable(CreateFont("FontmancerHookFont")).__index
    self:HookFontCallback(fontMeta)
    self:HookTextColorCallback(fontMeta)
    self:HookShadowColorCallback(fontMeta)
end

function Fontmancer:HookFontCallback(metaTable)
    hooksecurefunc(metaTable, "SetFont", function(fontInstance, fontFile, height, flags, isFontmancerCall)
        if not isFontmancerCall then
            local fontName = fontInstance:GetName()
            if not self.originalFonts[fontName] then
                self.originalFonts[fontName] = {}
            end
            self.originalFonts[fontName].height = height
            self.originalFonts[fontName].flags = flags or self.originalFonts[fontName].flags or "" -- flags can be nil
            self:ApplyFont(fontName, fontInstance)
        end
    end)
end

function Fontmancer:HookTextColorCallback(metaTable)
    hooksecurefunc(metaTable, "SetTextColor", function(fontInstance, r, g, b, a, isFontmancerCall)
        if not isFontmancerCall then
            self:ApplyTextColour(fontInstance:GetName(), fontInstance)
        end
    end)
end

function Fontmancer:HookShadowColorCallback(metaTable)
    hooksecurefunc(metaTable, "SetShadowColor", function(fontInstance, r, g, b, a, isFontmancerCall)
        if not isFontmancerCall then
            self:ApplyShadowColour(fontInstance:GetName(), fontInstance)
        end
    end)
end
