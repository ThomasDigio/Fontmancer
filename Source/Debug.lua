local addonName, addonTable = ...

-- Set to true while debugging locally; keep false committed
addonTable.DEBUG_MODE = false

if not addonTable.DEBUG_MODE then
    local cleanupFrame = CreateFrame("Frame")
    cleanupFrame:RegisterEvent("PLAYER_LOGIN")
    cleanupFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_LOGIN")
        if FontmancerDB then
            FontmancerDB.debug = nil
        end
    end)
    return
end

local debugState = {
    sessionStart = date and date("%Y-%m-%d %H:%M:%S") or "unknown",
    clientBuild = GetBuildInfo and table.concat({ GetBuildInfo() }, " / ") or "unknown",
    metrics = {},
    logs = {},
    inspected = {}
}

function addonTable:DebugLog(message)
    local entry = string.format("[%.2fms] %s", debugprofilestop and debugprofilestop() or 0, tostring(message))
    table.insert(debugState.logs, entry)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffee992bFontmancer Debug:|r " .. tostring(message))
    end
end

-- Wrap core methods to track call counts and execution time (in ms)
local trackedMethods = {
    "GetExclusionState",
    "StoreOriginals",
    "UpdateInstance",
    "UpdateAllStoredInstances",
    "ApplyFont",
    "ApplySpacing",
    "ApplyTextColour",
    "ApplyShadowColour",
    "ApplyShadowOffset"
}

for _, methodName in ipairs(trackedMethods) do
    local originalMethod = addonTable[methodName]
    if type(originalMethod) == "function" then
        debugState.metrics[methodName] = { calls = 0, totalMs = 0, maxMs = 0 }
        addonTable[methodName] = function(self, ...)
            local metric = debugState.metrics[methodName]
            metric.calls = metric.calls + 1
            local start = debugprofilestop and debugprofilestop() or 0
            local r1, r2, r3, r4 = originalMethod(self, ...)
            local elapsed = (debugprofilestop and debugprofilestop() or 0) - start
            metric.totalMs = metric.totalMs + elapsed
            if elapsed > metric.maxMs then
                metric.maxMs = elapsed
            end
            return r1, r2, r3, r4
        end
    end
end

local function SnapshotDebugState()
    if not FontmancerDB then return end

    local storedCount = 0
    for _ in pairs(addonTable.originalValues) do
        storedCount = storedCount + 1
    end

    FontmancerDB.debug = {
        sessionStart = debugState.sessionStart,
        lastSnapshot = date and date("%Y-%m-%d %H:%M:%S") or "unknown",
        version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "unknown",
        clientBuild = debugState.clientBuild,
        selectedFont = addonTable.db and addonTable.db.selectedFont or nil,
        globalFonts = {
            DAMAGE_TEXT_FONT = DAMAGE_TEXT_FONT,
            UNIT_NAME_FONT = UNIT_NAME_FONT,
            STANDARD_TEXT_FONT = STANDARD_TEXT_FONT,
            NAMEPLATE_FONT = NAMEPLATE_FONT
        },
        storedInstancesCount = storedCount,
        metrics = debugState.metrics,
        logs = debugState.logs,
        inspected = debugState.inspected
    }
end

local debugFrame = CreateFrame("Frame")
debugFrame:RegisterEvent("PLAYER_LOGIN")
debugFrame:RegisterEvent("PLAYER_LOGOUT")
debugFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
            SnapshotDebugState()
            addonTable:DebugLog(
                "Debug mode active. Use /fmdebug [status|reset|inspect <name>] and /reload to flush to SavedVariables.")
        end)
    elseif event == "PLAYER_LOGOUT" then
        SnapshotDebugState()
    end
end)

SLASH_FONTMANCERDEBUG1 = "/fmdebug"
SlashCmdList["FONTMANCERDEBUG"] = function(msg)
    local cmd, arg = (msg or ""):match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "reset" then
        for _, metric in pairs(debugState.metrics) do
            metric.calls = 0
            metric.totalMs = 0
            metric.maxMs = 0
        end
        wipe(debugState.logs)
        wipe(debugState.inspected)
        SnapshotDebugState()
        addonTable:DebugLog("Metrics and logs reset.")
    elseif cmd == "inspect" and arg ~= "" then
        local query = arg:lower()
        local matches = 0
        for name, orig in pairs(addonTable.originalValues) do
            if string.find(name:lower(), query, 1, true) then
                matches = matches + 1
                local inst = orig.instance
                local curFile, curHeight, curFlags
                if inst and inst.GetFont then
                    curFile, curHeight, curFlags = inst:GetFont()
                end
                debugState.inspected[name] = {
                    original = {
                        file = orig.file,
                        height = orig.height,
                        flags = orig.flags,
                        spacing = orig.offsets and orig.offsets.spacing
                    },
                    current = {
                        file = addonTable:CanAccessValue(curFile) and curFile or "<secret>",
                        height = addonTable:CanAccessValue(curHeight) and curHeight or "<secret>",
                        flags = addonTable:CanAccessValue(curFlags) and curFlags or "<secret>"
                    }
                }
            end
        end
        SnapshotDebugState()
        addonTable:DebugLog(string.format(
            "Inspected %d matching instances for '%s' (saved to FontmancerDB.debug.inspected).", matches, arg))
    else
        SnapshotDebugState()
        local d = FontmancerDB and FontmancerDB.debug
        if d then
            addonTable:DebugLog(string.format(
                "Stored instances: %d | ApplyFont: %d calls (%.2fms) | GetExclusionState: %d calls (%.2fms)",
                d.storedInstancesCount,
                d.metrics.ApplyFont and d.metrics.ApplyFont.calls or 0,
                d.metrics.ApplyFont and d.metrics.ApplyFont.totalMs or 0,
                d.metrics.GetExclusionState and d.metrics.GetExclusionState.calls or 0,
                d.metrics.GetExclusionState and d.metrics.GetExclusionState.totalMs or 0
            ))
        end
    end
end
