local L = LibStub("AceLocale-2.2"):new("ZOMGLog")

L:RegisterTranslations("zhTW", function() return {
    Behaviour = "行為設定",
    Changed = "已變更",
    ["Changed %s's exception - %s from %s to %s"] = "變更了 %s 的例外規則 - %s 從 %s 改為 %s",
    ["Changed %s's template - %s from %s to %s"] = "變更了 %s 的範本 - %s 從 %s 改為 %s",
    Clear = "清除",
    ["Cleared %s's exceptions for %s"] = "已清除 %s 關於 %s 的例外規則",
    ["Clear the log"] = "清除日誌",
    ["Event Logging"] = "事件日誌記錄",
    ["Generated automatic template"] = "已建立自動範本",
    ["Loaded template '%s'"] = "已載入範本 '%s'",
    Log = "日誌",
    ["Log behaviour"] = "日誌行為",
    Merge = "合併",
    ["Merge similar entries within 15 seconds. Avoids confusion with cycling through buffs to get to desired one giving multiple log entries."] = "合併15秒內的相似項目。避免在循環切換增益以獲取所需增益時產生多條日誌紀錄造成的混亂。",
    Open = "開啟",
    ["Remotely changed"] = "遠端變更",
    ["Saved template '%s'"] = "已儲存範本 '%s'",
    ["%s %s's exception - %s from %s to %s"] = "%s %s 的例外規則 - %s 從 %s 改為 %s",
    ["%s %s's template - %s from %s to %s"] = "%s %s 的範本 - %s 從 %s 改為 %s",
    ["View the log"] = "檢視日誌",
} end)