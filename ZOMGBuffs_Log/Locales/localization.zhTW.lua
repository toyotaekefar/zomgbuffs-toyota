local L = LibStub("AceLocale-2.2"):new("ZOMGLog")

L:RegisterTranslations("zhTW", function() return
--[===[@debug@
{
}
--@end-debug@]===]
{
	Behaviour = "行為",
	Changed = "已更改",
	["Changed %s's exception - %s from %s to %s"] = "%s的例外已更改 - %s從%s到%s",
	["Changed %s's template - %s from %s to %s"] = "%s的範本已更改 - %s從%s到%s",
	Clear = "清除",
	["Cleared %s's exceptions for %s"] = "清除了%s的例外給%s",
	["Clear the log"] = "清除日誌",
	["Event Logging"] = "開啟日誌記錄",
	["Generated automatic template"] = "自動範本已生成",
	["Loaded template '%s'"] = "範本“%s”已載入",
	Log = "日誌",
	["Log behaviour"] = "記錄行為",
	Merge = "合併",
	["Merge similar entries within 15 seconds. Avoids confusion with cycling through buffs to get to desired one giving multiple log entries."] = "合併15秒以內類似的條目。以避免在Buff中迴圈為了找到一個合適的Buff而導致的多條日誌資訊。",
	Open = "打開",
	["Remotely changed"] = "已遠端更改",
	["Saved template '%s'"] = "範本“%s”已儲存",
	["%s %s's exception - %s from %s to %s"] = "%s %s的例外 - %s 來自 %s 給 %s",
	["%s %s's template - %s from %s to %s"] = "%s %s的範本 - %s 來自 %s 給 %s",
	["View the log"] = "查看日誌",
}

end)
