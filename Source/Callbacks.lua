local addonName, addonTable = ...

-- Callbacks are here to:
-- 1. Handle font instances added after the initial run
-- 2. Handle updates to already processed font instances; we don't want said updates to override our customisation
function addonTable:HookCallbacks()
    local fontMeta = getmetatable(CreateFont("FontmancerHookFont")).__index
    local fontStringMeta = getmetatable(UIParent:CreateFontString()).__index
    -- Weak-keyed cache mapping fontInstance -> resolved fontName (or false if permanently skipped)
    local instanceNames = setmetatable({}, { __mode = "k" })

    local function HookCallback(method, handler)
        local function PostHook(fontInstance, ...)
            if self.isUpdating or not self.db.enableHooks then return end
            if not self:CanAccessValue(fontInstance) or (issecrettable and issecrettable(fontInstance)) then return end
            if fontInstance.IsForbidden and fontInstance:IsForbidden() then return end
            if fontInstance.IsFontmancerPreview then return end

            local fontName = instanceNames[fontInstance]
            if fontName == false then
                return
            elseif not fontName then
                -- Skip if SetFont is explicitly disallowed on this instance (e.g. Blizzard_Menu compositor fontStrings)
                if rawget(fontInstance, "SetFont") ~= nil then
                    instanceNames[fontInstance] = false
                    return
                end

                -- Skip if the font instance is a font string from a modern dropdown menu radio button because it's forbidden to set their font,
                -- or from Blizzard_CombatText (which inherits from CombatTextFont and uses SetTextHeight scaling that SetFont corrupts)
                if fontInstance.GetParent then
                    local parent = fontInstance:GetParent()
                    if not self:CanAccessValue(parent) then return end
                    if parent then
                        if parent.IsForbidden and parent:IsForbidden() then
                            return
                        end
                        if (parent.IsObjectType and parent:IsObjectType("Button")) or (CombatText and parent == CombatText) then
                            instanceNames[fontInstance] = false
                            return
                        end
                    end
                end

                fontName = fontInstance:GetName()
                if not self:CanAccessValue(fontName) then fontName = nil end
                if not fontName and fontInstance.GetDebugName then
                    fontName = fontInstance:GetDebugName()
                    if not self:CanAccessValue(fontName) then fontName = nil end
                end
                if not fontName then
                    fontName = tostring(fontInstance)
                    if not self:CanAccessValue(fontName) then return end
                end

                if self:GetExclusionState(fontName) == "FULL" then return end

                -- Ignore non-SetFont calls (e.g. Pool_HideAndSetToDefaults calling SetAlpha) on FontStrings that have no font yet
                if method ~= "SetFont" and not self.originalValues[fontName] then
                    local fontFile = fontInstance:GetFont()
                    if not self:CanAccessValue(fontFile) or not fontFile then
                        return
                    end
                end

                self:StoreOriginals(fontName, fontInstance)
                instanceNames[fontInstance] = fontName
            elseif self:GetExclusionState(fontName) == "FULL" then
                return
            end

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
        local orig = self.originalValues[name]
        if self:CanAccessAllValues(r, g, b, a) and r and g and b then
            local textColour = orig.colours.text
            textColour.r = r
            textColour.g = g
            textColour.b = b
            textColour.a = a or textColour.a or 1
        end
        local specific = self.db.specific[name]
        local origFlags = orig.flags
        if self.db.colours.text.isEnabled
            or self.db.flags.OUTLINE
            or self.db.flags.THICKOUTLINE
            or (origFlags and origFlags ~= "" and string.find(origFlags, "OUTLINE", 1, true))
            or (specific and (specific.text or specific.flags or (specific.disabled and specific.disabled.text))) then
            self:ApplyTextColour(name, fontInstance)
        end
    end)

    HookCallback("SetAlpha", function(name, fontInstance, alpha)
        if self:CanAccessValue(alpha) and alpha then
            self.originalValues[name].colours.text.a = alpha
            local specific = self.db.specific[name]
            if self.db.colours.text.isEnabled or (specific and (specific.text or (specific.disabled and specific.disabled.text))) then
                self:ApplyTextColour(name, fontInstance, false, true)
            end
        end
    end)

    HookCallback("SetShadowColor", function(name, fontInstance, r, g, b, a)
        if self:CanAccessAllValues(r, g, b, a) and r and g and b then
            local shadowColour = self.originalValues[name].colours.shadow
            shadowColour.r = r
            shadowColour.g = g
            shadowColour.b = b
            shadowColour.a = a or shadowColour.a or 1
        end
        local specific = self.db.specific[name]
        if self.db.colours.shadow.isEnabled or (specific and (specific.shadow or (specific.disabled and specific.disabled.shadow))) then
            self:ApplyShadowColour(name, fontInstance)
        end
    end)

    HookCallback("SetShadowOffset", function(name, fontInstance, x, y)
        if self:CanAccessAllValues(x, y) and x and y then
            local shadowOffset = self.originalValues[name].offsets.shadow
            shadowOffset.x = x
            shadowOffset.y = y
        end
        self:ApplyShadowOffset(name, fontInstance)
    end)
end
