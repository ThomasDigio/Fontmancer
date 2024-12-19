local addonName = ...
local AceAddon = LibStub("AceAddon-3.0")

---@class Fontmancer: AceAddon
local Fontmancer = AceAddon:GetAddon(addonName)

function Fontmancer:ApplyCallbacks()
    local callbackFrame = CreateFrame("FRAME")
    local fontStringMeta = getmetatable(callbackFrame:CreateFontString()).__index
    self:ApplyFontCallback(fontStringMeta)
    self:ApplyTextColorCallback(fontStringMeta)
    self:ApplyShadowColorCallback(fontStringMeta)
end

function Fontmancer:ApplyFontCallback(table)
    hooksecurefunc(table, "SetFont", function(fontString, r, g, b, a, isFontmancerCall)
        if not isFontmancerCall then
            local fontObject = fontString:GetFontObject()
            if not fontObject then
                return
            end

            local fontName = fontObject:GetName()
            if (self.originalFonts[fontName]) then
                -- TODO
            end
        end
    end)
end

function Fontmancer:ApplyTextColorCallback(table)
    hooksecurefunc(table, "SetTextColor", function(fontString, r, g, b, a, isFontmancerCall)
        if not isFontmancerCall then
            local fontObject = fontString:GetFontObject()
            if not fontObject then
                return
            end

            local fontName = fontObject:GetName()
            if (self.originalFonts[fontName]) then
                self.originalFonts[fontName].colours.text.r = r
                self.originalFonts[fontName].colours.text.g = g
                self.originalFonts[fontName].colours.text.b = b
                if a ~= nil then
                    self.originalFonts[fontName].colours.text.a = a
                end
            end
        end
    end)
end

function Fontmancer:ApplyShadowColorCallback(fontStringMeta)
    hooksecurefunc(fontStringMeta, "SetShadowColor", function(fontString, r, g, b, a, isFontmancerCall)
        if not isFontmancerCall then
            local fontObject = fontString:GetFontObject()
            if not fontObject then
                return
            end

            local fontName = fontObject:GetName()
            if (self.originalFonts[fontName]) then
                self.originalFonts[fontName].colours.shadow.r = r
                self.originalFonts[fontName].colours.shadow.g = g
                self.originalFonts[fontName].colours.shadow.b = b
                if a ~= nil then
                    self.originalFonts[fontName].colours.shadow.a = a
                end
            end
        end
    end)
end

function Fontmancer:StoreOriginals(fontName, font)
    if not self.originalFonts[fontName] then
        local _, height, flags = font:GetFont()
        self.originalFonts[fontName] = {
            height = height,
            flags = flags,
            spacing = font:GetSpacing(),
            indent = font:GetIndentedWordWrap()
        }

        local textRed, textGreen, textBlue, textAlpha = font:GetTextColor()
        self.originalFonts[fontName].colour = { r = textRed, g = textGreen, b = textBlue, a = textAlpha }

        local shadowRed, shadowGreen, shadowBlue, shadowAlpha = font:GetShadowColor()
        local shadowX, shadowY = font:GetShadowOffset()
        self.originalFonts[fontName].shadow = { colour = { r = shadowRed, g = shadowGreen, b = shadowBlue, a = shadowAlpha }, offset = { x = shadowX, y = shadowY } }
    end
end
