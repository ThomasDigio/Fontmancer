local addonName, addonTable = ...

-- Callbacks are here to:
-- 1. Handle font instances added after the initial run
-- 2. Handle updates to already processed font instances; we don't want said updates to override our customisation
function addonTable:HookCallbacks()
    local fontMeta = getmetatable(CreateFont("FontmancerHookFont")).__index
    local fontStringMeta = getmetatable(UIParent:CreateFontString()).__index

    local function HookCallback(method, handler)
        local function PostHook(fontInstance, ...)
            if self.isUpdating then return end

            local fontName = fontInstance:GetName() or fontInstance:GetDebugName()
            self:StoreOriginals(fontName, fontInstance)
            handler(fontName, fontInstance, ...)
        end

        hooksecurefunc(fontMeta, method, PostHook)
        hooksecurefunc(fontStringMeta, method, PostHook)
    end

    HookCallback("SetFont", function(name, fontInstance, fontFile, height, flags)
        self.originalValues[name].height = height
        self.originalValues[name].flags = flags or self.originalValues[name].flags or ""
        self:ApplyFont(name, fontInstance)
    end)

    HookCallback("SetFontHeight", function(name, fontInstance, height)
        self.originalValues[name].height = height
        self:ApplyFont(name, fontInstance)
    end)

    HookCallback("SetSpacing", function(name, fontInstance, spacing)
        self.originalValues[name].offsets.spacing = spacing
        self:ApplySpacing(name, fontInstance)
    end)

    HookCallback("SetTextColor", function(name, fontInstance, r, g, b, a)
        self.originalValues[name].colours.text = {
            r = r,
            g = g,
            b = b,
            a = a or self.originalValues[name].colours.text.a or 1
        }
        self:ApplyTextColour(name, fontInstance)
    end)

    HookCallback("SetAlpha", function(name, fontInstance, alpha)
        self.originalValues[name].colours.text.a = alpha
        self:ApplyTextColour(name, fontInstance)
    end)

    HookCallback("SetShadowColor", function(name, fontInstance, r, g, b, a)
        self.originalValues[name].colours.shadow = {
            r = r,
            g = g,
            b = b,
            a = a or self.originalValues[name].colours.shadow.a or 1
        }
        self:ApplyShadowColour(name, fontInstance)
    end)

    HookCallback("SetShadowOffset", function(name, fontInstance, x, y)
        self.originalValues[name].offsets.shadow = { x = x, y = y }
        self:ApplyShadowOffset(name, fontInstance)
    end)
end
