-- In Character Forever - English Text

local L = LibStub("AceLocale-3.0"):NewLocale("Blackacre", "enUS", true)
if not L then return end

-- Brand / core
L["ADDON_NAME"] = "Blackacre"
L["PRINT_PREFIX"] = "|cffc9a227Blackacre:|r "
L["NEED_PACKAGE"] = "%s requires the |cffc9a227%s|r package (enable it in AddOns)."

-- Slash help (short)
L["HELP_HEADER"] = "Commands: /ba (or /blackacre, /ic)"
L["HELP_TOME"] = "journal — open your journal"
L["HELP_SURVIVAL"] = "survival — condition meters"
L["HELP_PACKAGES"] = "packages — list loaded packages"

-- Options (AceConfig)
L["OPTIONS_TITLE"] = "Blackacre"
L["OPTIONS_DESC"] = "In Character: A journaling and immersive way to dive into your original character but also connect with others."
L["OPT_MINIMAP"] = "Show minimap button"
L["OPT_MINIMAP_DESC"] = ""
L["OPT_QUIET"] = "Disable toast sounds"
L["OPT_QUIET_DESC"] = ""
L["OPT_PROFILES"] = "Profiles"
L["OPT_PROFILES_DESC"] = "AceDB profiles for Blackacre options (does not rewrite your Tome history)."

-- Theme / UX short tags (for later UI)
L["TOME_SUBTITLE"] = "One book for the road — pages turn; windows do not stack"
L["SURVIVAL_TITLE"] = "Condition"
