local addonName, addonTable = ...

-- Callbacks are here to:
-- 1. Handle font instances added after the initial run
-- 2. Handle updates to already processed font instances; we don't want said updates to override our customisation
function addonTable:HookCallbacks()
    local fontMeta = getmetatable(CreateFont("FontmancerHookFont")).__index
    local fontStringMeta = getmetatable(UIParent:CreateFontString()).__index

    local function HookCallback(method, handler)
        local function PostHook(fontInstance, ...)
            if self.isUpdating or not self.db.enableHooks then return end
            if not self:CanAccessValue(fontInstance) or (issecrettable and issecrettable(fontInstance)) then return end
            if fontInstance.IsForbidden and fontInstance:IsForbidden() then return end
            if fontInstance.IsFontmancerPreview then return end

            -- Skip if SetFont is explicitly disallowed on this instance (e.g. Blizzard_Menu compositor fontStrings)
            if rawget(fontInstance, "SetFont") ~= nil then return end

            -- Skip if the font instance is a font string from a modern dropdown menu radio button because it's forbidden to set their font
            if fontInstance.GetParent then
                local parent = fontInstance:GetParent()
                if not self:CanAccessValue(parent) then return end
                if parent then
                    if parent.IsForbidden and parent:IsForbidden() then
                        return
                    end
                    if parent.IsObjectType and parent:IsObjectType("Button") then
                        return
                    end
                end
            end

            local fontName = fontInstance:GetName()
            if not self:CanAccessValue(fontName) then fontName = nil end
            if not fontName and fontInstance.GetDebugName then
                fontName = fontInstance:GetDebugName()
                if not self:CanAccessValue(fontName) then fontName = nil end
            end
            if not fontName then
                fontName = tostring(fontInstance)
                if not self:CanAccessValue(fontName) then return end
            end

            local exclusionState = self:GetExclusionState(fontName)
            if exclusionState == "FULL" then return end

            self:StoreOriginals(fontName, fontInstance)
            handler(fontName, fontInstance, ...)
        end

        hooksecurefunc(fontMeta, method, PostHook)
        hooksecurefunc(fontStringMeta, method, PostHook)
    end

    HookCallback("SetFont", function(name, fontInstance, fontFile, height, flags)
        if self:CanAccessValue(fontFile) then
            self.originalValues[name].file = fontFile
        end
        if self:CanAccessValue(height) and height then
            self.originalValues[name].height = height
        end
        if self:CanAccessValue(flags) then
            self.originalValues[name].flags = flags or self.originalValues[name].flags or ""
        end
        self:ApplyFont(name, fontInstance)
    end)

    HookCallback("SetFontHeight", function(name, fontInstance, height)
        if self:CanAccessValue(height) and height then
            self.originalValues[name].height = height
            self:ApplyFont(name, fontInstance)
        end
    end)

    HookCallback("SetSpacing", function(name, fontInstance, spacing)
        if self:CanAccessValue(spacing) and spacing then
            self.originalValues[name].offsets.spacing = spacing
            self:ApplySpacing(name, fontInstance)
        end
    end)

    HookCallback("SetTextColor", function(name, fontInstance, r, g, b, a)
        if self:CanAccessAllValues(r, g, b, a) and r and g and b then
            self.originalValues[name].colours.text = {
                r = r,
                g = g,
                b = b,
                a = a or self.originalValues[name].colours.text.a or 1
            }
        end
        self:ApplyTextColour(name, fontInstance)
    end)

    HookCallback("SetAlpha", function(name, fontInstance, alpha)
        if self:CanAccessValue(alpha) and alpha then
            self.originalValues[name].colours.text.a = alpha
            self:ApplyTextColour(name, fontInstance)
        end
    end)

    HookCallback("SetShadowColor", function(name, fontInstance, r, g, b, a)
        if self:CanAccessAllValues(r, g, b, a) and r and g and b then
            self.originalValues[name].colours.shadow = {
                r = r,
                g = g,
                b = b,
                a = a or self.originalValues[name].colours.shadow.a or 1
            }
        end
        self:ApplyShadowColour(name, fontInstance)
    end)

    HookCallback("SetShadowOffset", function(name, fontInstance, x, y)
        if self:CanAccessAllValues(x, y) and x and y then
            self.originalValues[name].offsets.shadow = { x = x, y = y }
        end
        self:ApplyShadowOffset(name, fontInstance)
    end)
end
