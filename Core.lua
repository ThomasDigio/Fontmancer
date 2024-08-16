local AceAddon = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

local optionOrder = 0
local function IncrementAndFetchOrder()
    optionOrder = optionOrder + 1
    return optionOrder
end

local function CreateSpacing(width)
    return {
        type = "description",
        name = " ",
        width = width,
        order = IncrementAndFetchOrder()
    }
end

local Fontmancer = AceAddon:NewAddon("Fontmancer")
Fontmancer.metadata = {
    TITLE = "Title",
    LOGO_PATH = "IconTexture",
    DESCRIPTION = "Notes"
}

Fontmancer.colour = "fff78c"
function Fontmancer:ColourText(text)
    return "|cff" .. self.colour .. text .. "|r"
end

function Fontmancer:OnInitialize()
    -- Fetch metadata
    for keyName, keyValue in pairs(self.metadata) do
        self.metadata[keyName] = C_AddOns.GetAddOnMetadata("Fontmancer", keyValue)
    end

    -- Initialise the database
    local databaseDefaults = {
        global = {
            delta = 0,
            selectedFont = nil
        }
    }
    self.db = AceDB:New("FontmancerDB", databaseDefaults)

    -- Create the options
    local options = {
        name = self.metadata.TITLE,
        handler = Fontmancer,
        type = "group",
        args = {
            -- ABOUT
            aboutHeader = {
                type = "header",
                name = "About",
                order = IncrementAndFetchOrder()
            },
            spacing1 = CreateSpacing("full"),
            logoImage = {
                type = "description",
                name = " ",
                width = 0.5,
                image = self.metadata.LOGO_PATH,
                imageWidth = 64,
                imageHeight = 64,
                order = IncrementAndFetchOrder()
            },
            spacing2 = CreateSpacing(0.1),
            description = {
                type = "description",
                name = self.metadata.DESCRIPTION,
                fontSize = "medium",
                width = 3.1,
                order = IncrementAndFetchOrder()
            },
            -- CONFIG
            header = {
                type = "header",
                name = "Config",
                order = IncrementAndFetchOrder()
            },
            spacing3 = CreateSpacing("full"),
            fontSelector = {
                type = "select",
                name = "Font",
                desc = "Choose the font to apply to all UI elements (add new fonts with SharedMedia)",
                dialogControl = "LSM30_Font",
                values = LSM:HashTable(LSM.MediaType.FONT),
                get = function(_)
                    return self.db.global.selectedFont
                end,
                set = function(_, value)
                    self.db.global.selectedFont = value
                    self:ApplyFont()
                end,
                order = IncrementAndFetchOrder(),
            },
            spacing4 = CreateSpacing("full"),
            deltaSelector = {
                type = "range",
                name = "Delta",
                desc = "Optional delta value used to adjust your font size",
                min = -10,
                max = 10,
                step = 0.5,
                get = function(_)
                    return self.db.global.delta
                end,
                set = function(_, value)
                    self.db.global.delta = value
                    self:ApplyFont()
                end,
                order = IncrementAndFetchOrder(),
            },
            -- spacing5 = createSpacing(0.1),
            -- deltaReload = {
            --     type = "execute",
            --     name = "",
            --     desc = "Just like a " .. self:colourText("/reload") .. " or " .. self:colourText("/reloadui"),
            --     image = "Interface\\AddOns\\Fontmancer\\Assets\\Reload.png",
            --     imageWidth = 16,
            --     imageHeight = 16,
            --     func = function()
            --         C_UI.Reload()
            --     end,
            --     disabled = function()
            --         return self.db.global.delta == initialDelta
            --     end,
            --     width = 0.2,
            --     order = optionOrderPlusPlus(),
            -- },
            -- deltaWarning = {
            --     type = "description",
            --     name = "|cffff9900You will need to reload your UI for that option to take effect!|r",
            --     width = 2,
            --     order = optionOrderPlusPlus()
            -- }
        }
    }
    AceConfig:RegisterOptionsTable(self.name, options)
    AceConfigDialog:AddToBlizOptions(self.name)
end

function Fontmancer:OnEnable()
    self:ApplyFont()
end

function Fontmancer:ApplyFont()
    local selectedFont = self.db.global.selectedFont
    if not selectedFont then
        return
    end

    -- TODO
    -- for frameName in pairs(_G) do
    --     local frame = _G[frameName]
    --     if type(frame) == "table" and frame and frame.IsForbidden and not frame:IsForbidden() and frame.GetFont then
    --         if frame:GetFont() then
    --             print(frameName .. frame:GetFont())
    --         end
    --     end
    -- end

    local fetchedFont = LSM:Fetch(LSM.MediaType.FONT, selectedFont)
    for _, fontObjectName in pairs(self.fontObjectNames) do
        local _, height, flags = _G[fontObjectName]:GetFont()

        -- Store the original height so we can apply the delta without needing to reload the UI
        if not Fontmancer.originalFontHeights[fontObjectName] then
            Fontmancer.originalFontHeights[fontObjectName] = height
        end

        local newHeight = max(Fontmancer.originalFontHeights[fontObjectName] + self.db.global.delta, 0.5)
        _G[fontObjectName]:SetFont(fetchedFont, newHeight, flags)
    end
end

Fontmancer.originalFontHeights = {}
-- List taken from the FontObject alias in the WoW API VSCode extension, Annotations/Widget/UIType/Font.lua
Fontmancer.fontObjectNames = {
    "AchievementCriteriaFont",
    "AchievementDateFont",
    "AchievementDescriptionFont",
    "AchievementFont_Small",
    "AchievementPointsFont",
    "AchievementPointsFontSmall",
    "ArtifactAppearanceSetHighlightFont",
    "ArtifactAppearanceSetNormalFont",
    "BossEmoteNormalHuge",
    "ChatBubbleFont",
    "ChatFontNormal",
    "ChatFontSmall",
    "CombatLogFont",
    "CombatTextFont",
    "CombatTextFontOutline",
    "CommentatorCCFont",
    "CommentatorDampeningFont",
    "CommentatorFontMedium",
    "CommentatorFontSmall",
    "CommentatorTeamNameFont",
    "CommentatorTeamScoreFont",
    "CommentatorVictoryFanfare",
    "CommentatorVictoryFanfareTeam",
    "ConsoleFontNormal",
    "ConsoleFontSmall",
    "CoreAbilityFont",
    "DestinyFontHuge",
    "DestinyFontLarge",
    "DestinyFontMed",
    "DialogButtonHighlightText",
    "DialogButtonNormalText",
    "ErrorFont",
    "Fancy12Font",
    "Fancy14Font",
    "Fancy16Font",
    "Fancy18Font",
    "Fancy20Font",
    "Fancy22Font",
    "Fancy24Font",
    "Fancy27Font",
    "Fancy30Font",
    "Fancy32Font",
    "Fancy48Font",
    "FocusFontSmall",
    "FriendsFont_11",
    "FriendsFont_Large",
    "FriendsFont_Normal",
    "FriendsFont_Small",
    "FriendsFont_UserText",
    "Game10Font_o1",
    "Game11Font",
    "Game11Font_o1",
    "Game11Font_Shadow",
    "Game120Font",
    "Game12Font",
    "Game12Font_o1",
    "Game13Font",
    "Game13Font_o1",
    "Game13FontShadow",
    "Game15Font",
    "Game15Font_o1",
    "Game15Font_Shadow",
    "Game16Font",
    "Game17Font_Shadow",
    "Game18Font",
    "Game19Font",
    "Game20Font",
    "Game21Font",
    "Game22Font",
    "Game24Font",
    "Game27Font",
    "Game30Font",
    "Game32Font",
    "Game32Font_Shadow2",
    "Game36Font",
    "Game36Font_Shadow2",
    "Game40Font",
    "Game40Font_Shadow2",
    "Game42Font",
    "Game46Font",
    "Game46Font_Shadow2",
    "Game48Font",
    "Game48FontShadow",
    "Game52Font_Shadow2",
    "Game58Font_Shadow2",
    "Game60Font",
    "Game69Font_Shadow2",
    "Game72Font",
    "Game72Font_Shadow",
    "GameFont72Highlight",
    "GameFont72HighlightShadow",
    "GameFont72Normal",
    "GameFont72NormalShadow",
    "GameFont_Gigantic",
    "GameFontBlack",
    "GameFontBlackMedium",
    "GameFontBlackSmall",
    "GameFontBlackSmall2",
    "GameFontBlackTiny",
    "GameFontBlackTiny2",
    "GameFontDarkGraySmall",
    "GameFontDisable",
    "GameFontDisableHuge",
    "GameFontDisableLarge",
    "GameFontDisableLeft",
    "GameFontDisableMed2",
    "GameFontDisableMed3",
    "GameFontDisableOutline22",
    "GameFontDisableSmall",
    "GameFontDisableSmall2",
    "GameFontDisableSmallLeft",
    "GameFontDisableTiny",
    "GameFontDisableTiny2",
    "GameFontGreen",
    "GameFontGreenLarge",
    "GameFontGreenSmall",
    "GameFontHighlight",
    "GameFontHighlightCenter",
    "GameFontHighlightExtraSmall",
    "GameFontHighlightExtraSmallLeft",
    "GameFontHighlightExtraSmallLeftTop",
    "GameFontHighlightHuge",
    "GameFontHighlightHuge2",
    "GameFontHighlightLarge",
    "GameFontHighlightLarge2",
    "GameFontHighlightLeft",
    "GameFontHighlightMed2",
    "GameFontHighlightMedium",
    "GameFontHighlightOutline",
    "GameFontHighlightOutline22",
    "GameFontHighlightRight",
    "GameFontHighlightShadowHuge2",
    "GameFontHighlightShadowOutline22",
    "GameFontHighlightSmall",
    "GameFontHighlightSmall2",
    "GameFontHighlightSmallLeft",
    "GameFontHighlightSmallLeftTop",
    "GameFontHighlightSmallOutline",
    "GameFontHighlightSmallRight",
    "GameFontNormal",
    "GameFontNormal_NoShadow",
    "GameFontNormalCenter",
    "GameFontNormalGraySmall",
    "GameFontNormalHuge",
    "GameFontNormalHuge2",
    "GameFontNormalHuge3",
    "GameFontNormalHuge3Outline",
    "GameFontNormalHuge4",
    "GameFontNormalHuge4Outline",
    "GameFontNormalHugeBlack",
    "GameFontNormalHugeOutline",
    "GameFontNormalLarge",
    "GameFontNormalLarge2",
    "GameFontNormalLargeLeft",
    "GameFontNormalLargeLeftTop",
    "GameFontNormalLargeOutline",
    "GameFontNormalLeft",
    "GameFontNormalLeftBottom",
    "GameFontNormalLeftGreen",
    "GameFontNormalLeftGrey",
    "GameFontNormalLeftLightGreen",
    "GameFontNormalLeftOrange",
    "GameFontNormalLeftRed",
    "GameFontNormalLeftYellow",
    "GameFontNormalMed1",
    "GameFontNormalMed2",
    "GameFontNormalMed2Outline",
    "GameFontNormalMed3",
    "GameFontNormalMed3Outline",
    "GameFontNormalOutline",
    "GameFontNormalOutline22",
    "GameFontNormalRight",
    "GameFontNormalShadowHuge2",
    "GameFontNormalShadowOutline22",
    "GameFontNormalSmall",
    "GameFontNormalSmall2",
    "GameFontNormalSmallBattleNetBlueLeft",
    "GameFontNormalSmallLeft",
    "GameFontNormalTiny",
    "GameFontNormalTiny2",
    "GameFontNormalWTF2",
    "GameFontNormalWTF2Outline",
    "GameFontRed",
    "GameFontRedLarge",
    "GameFontRedSmall",
    "GameFontWhite",
    "GameFontWhiteSmall",
    "GameFontWhiteTiny",
    "GameFontWhiteTiny2",
    "GameNormalNumberFont",
    "GameTooltipHeader",
    "GameTooltipHeaderText",
    "GameTooltipText",
    "GameTooltipTextSmall",
    "IMEHighlight",
    "IMENormal",
    "InvoiceFont_Med",
    "InvoiceFont_Small",
    "InvoiceTextFontNormal",
    "InvoiceTextFontSmall",
    "ItemTextFontNormal",
    "MailFont_Large",
    "MailTextFontNormal",
    "MissionCombatTextFontOutline",
    "MovieSubtitleFont",
    "NewSubSpellFont",
    "Number11Font",
    "Number11FontWhite",
    "Number12Font",
    "Number12Font_o1",
    "Number13Font",
    "Number13FontGray",
    "Number13FontRed",
    "Number13FontWhite",
    "Number13FontYellow",
    "Number14FontGray",
    "Number14FontGreen",
    "Number14FontRed",
    "Number14FontWhite",
    "Number15Font",
    "Number15FontWhite",
    "Number16Font",
    "Number18Font",
    "Number18FontWhite",
    "NumberFont_GameNormal",
    "NumberFont_Normal_Med",
    "NumberFont_Outline_Huge",
    "NumberFont_Outline_Large",
    "NumberFont_Outline_Med",
    "NumberFont_OutlineThick_Mono_Small",
    "NumberFont_Shadow_Large",
    "NumberFont_Shadow_Med",
    "NumberFont_Shadow_Small",
    "NumberFont_Shadow_Tiny",
    "NumberFont_Small",
    "NumberFontNormal",
    "NumberFontNormalGray",
    "NumberFontNormalHuge",
    "NumberFontNormalLarge",
    "NumberFontNormalLargeRight",
    "NumberFontNormalLargeRightGray",
    "NumberFontNormalLargeRightRed",
    "NumberFontNormalLargeRightYellow",
    "NumberFontNormalLargeYellow",
    "NumberFontNormalRight",
    "NumberFontNormalRightGray",
    "NumberFontNormalRightGreen",
    "NumberFontNormalRightRed",
    "NumberFontNormalRightYellow",
    "NumberFontNormalSmall",
    "NumberFontNormalSmallGray",
    "NumberFontNormalYellow",
    "NumberFontSmallBattleNetBlueLeft",
    "NumberFontSmallWhiteLeft",
    "NumberFontSmallYellowLeft",
    "ObjectiveFont",
    "ObjectiveTrackerHeaderFont",
    "ObjectiveTrackerLineFont",
    "OptionsFontHighlight",
    "OptionsFontHighlightSmall",
    "OptionsFontLarge",
    "OptionsFontLeft",
    "OptionsFontSmall",
    "OptionsFontSmallLeft",
    "PriceFont",
    "PriceFontGray",
    "PriceFontGreen",
    "PriceFontRed",
    "PriceFontWhite",
    "PriceFontYellow",
    "PVPInfoTextFont",
    "QuestDifficulty_Difficult",
    "QuestDifficulty_Header",
    "QuestDifficulty_Impossible",
    "QuestDifficulty_Standard",
    "QuestDifficulty_Trivial",
    "QuestDifficulty_VeryDifficult",
    "QuestFont",
    "QuestFont_30",
    "QuestFont_39",
    "QuestFont_Enormous",
    "QuestFont_Huge",
    "QuestFont_Large",
    "QuestFont_Outline_Huge",
    "QuestFont_Shadow_Enormous",
    "QuestFont_Shadow_Huge",
    "QuestFont_Shadow_Small",
    "QuestFont_Shadow_Super_Huge",
    "QuestFont_Super_Huge",
    "QuestFont_Super_Huge_Outline",
    "QuestFontHighlightHuge",
    "QuestFontLeft",
    "QuestFontNormalHuge",
    "QuestFontNormalLarge",
    "QuestFontNormalSmall",
    "QuestMapRewardsFont",
    "QuestTitleFont",
    "QuestTitleFontBlackShadow",
    "ReputationDetailFont",
    "SpellFont_Small",
    "SplashHeaderFont",
    "SubSpellFont",
    "SubZoneTextFont",
    "System15Font",
    "System_IME",
    "SystemFont22_Outline",
    "SystemFont22_Shadow_Outline",
    "SystemFont_Huge1",
    "SystemFont_Huge1_Outline",
    "SystemFont_Huge2",
    "SystemFont_Huge4",
    "SystemFont_InverseShadow_Small",
    "SystemFont_Large",
    "SystemFont_LargeNamePlate",
    "SystemFont_LargeNamePlateFixed",
    "SystemFont_Med1",
    "SystemFont_Med2",
    "SystemFont_Med3",
    "SystemFont_NamePlate",
    "SystemFont_NamePlateCastBar",
    "SystemFont_NamePlateFixed",
    "SystemFont_Outline",
    "SystemFont_Outline_Small",
    "SystemFont_Outline_WTF2",
    "SystemFont_OutlineThick_Huge2",
    "SystemFont_OutlineThick_Huge4",
    "SystemFont_OutlineThick_WTF",
    "SystemFont_Shadow_Huge1",
    "SystemFont_Shadow_Huge2",
    "SystemFont_Shadow_Huge2_Outline",
    "SystemFont_Shadow_Huge3",
    "SystemFont_Shadow_Huge4",
    "SystemFont_Shadow_Huge4_Outline",
    "SystemFont_Shadow_Large",
    "SystemFont_Shadow_Large2",
    "SystemFont_Shadow_Large_Outline",
    "SystemFont_Shadow_Med1",
    "SystemFont_Shadow_Med1_Outline",
    "SystemFont_Shadow_Med2",
    "SystemFont_Shadow_Med2_Outline",
    "SystemFont_Shadow_Med3",
    "SystemFont_Shadow_Med3_Outline",
    "SystemFont_Shadow_Outline_Huge3",
    "SystemFont_Shadow_Small",
    "SystemFont_Shadow_Small2",
    "SystemFont_Small",
    "SystemFont_Small2",
    "SystemFont_Tiny",
    "SystemFont_Tiny2",
    "SystemFont_World",
    "SystemFont_World_ThickOutline",
    "SystemFont_WTF2",
    "TextStatusBarText",
    "TextStatusBarTextLarge",
    "Tooltip_Med",
    "Tooltip_Small",
    "VehicleMenuBarStatusBarText",
    "WhiteNormalNumberFont",
    "WorldMapTextFont",
    "ZoneTextFont"
}
