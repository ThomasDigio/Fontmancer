local addonName = ...
local AceAddon = LibStub("AceAddon-3.0")

---@class Fontmancer: AceAddon
local Fontmancer = AceAddon:GetAddon(addonName)

function Fontmancer:HookCallbacks()
    local callbackFrame = CreateFrame("FRAME")
    local fontStringMeta = getmetatable(callbackFrame:CreateFontString()).__index
    self:HookFontCallback(fontStringMeta)
    self:HookTextColorCallback(fontStringMeta)
    self:HookShadowColorCallback(fontStringMeta)
end

function Fontmancer:HookFontCallback(table)
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

function Fontmancer:HookTextColorCallback(table)
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

function Fontmancer:HookShadowColorCallback(fontStringMeta)
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
        local textRed, textGreen, textBlue, textAlpha = font:GetTextColor()
        local shadowRed, shadowGreen, shadowBlue, shadowAlpha = font:GetShadowColor()
        local shadowX, shadowY = font:GetShadowOffset()
        self.originalFonts[fontName] = {
            colours = {
                text = { r = textRed, g = textGreen, b = textBlue, a = textAlpha },
                shadow = { r = shadowRed, g = shadowGreen, b = shadowBlue, a = shadowAlpha }
            },
            flags = flags,
            height = height,
            indent = font:GetIndentedWordWrap(),
            offsets = {
                shadow = { x = shadowX, y = shadowY },
                spacing = font:GetSpacing()
            }
        }
    end
end
