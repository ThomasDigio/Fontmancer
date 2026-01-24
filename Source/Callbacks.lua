local addonName, addonTable = ...

function addonTable:HookCallbacks()
    local fontMeta = getmetatable(CreateFont("FontmancerHookFont")).__index

    local function hook(method, handler)
        hooksecurefunc(fontMeta, method, function(fontInstance, ...)
            local fontName = fontInstance:GetName()
            if not fontName or self.isUpdating then return end
            self:StoreOriginals(fontName, fontInstance)
            handler(fontName, fontInstance, ...)
        end)
    end

    hook("SetFont", function(name, font, fontFile, height, flags)
        self.originalFonts[name].height = height
        self.originalFonts[name].flags = flags or self.originalFonts[name].flags or ""
        self:ApplyFont(name, font)
    end)

    hook("SetSpacing", function(name, font, spacing)
        self.originalFonts[name].offsets.spacing = spacing
        self:ApplySpacing(name, font)
    end)

    hook("SetTextColor", function(name, font, r, g, b, a)
        self.originalFonts[name].colours.text = {
            r = r,
            g = g,
            b = b,
            a = a or self.originalFonts[name].colours.text.a or 1
        }
        self:ApplyTextColour(name, font)
    end)

    hook("SetShadowColor", function(name, font, r, g, b, a)
        self.originalFonts[name].colours.shadow = {
            r = r,
            g = g,
            b = b,
            a = a or self.originalFonts[name].colours.shadow.a or 1
        }
        self:ApplyShadowColour(name, font)
    end)

    hook("SetShadowOffset", function(name, font, x, y)
        self.originalFonts[name].offsets.shadow = { x = x, y = y }
        self:ApplyShadowOffset(name, font)
    end)
end
