local L = LibStub("AceLocale-2.2"):new("ZOMGLog")

L:RegisterTranslations("zhCN", function() return {
    Behaviour = "行为设置",
    Changed = "已修改",
    ["Changed %s's exception - %s from %s to %s"] = "修改了 %s 的例外规则 - %s 从 %s 改为 %s",
    ["Changed %s's template - %s from %s to %s"] = "修改了 %s 的模板 - %s 从 %s 改为 %s",
    Clear = "清除",
    ["Cleared %s's exceptions for %s"] = "已清除 %s 关于 %s 的例外规则",
    ["Clear the log"] = "清除日志",
    ["Event Logging"] = "事件日志记录",
    ["Generated automatic template"] = "已生成自动模板",
    ["Loaded template '%s'"] = "已加载模板 '%s'",
    Log = "日志",
    ["Log behaviour"] = "日志行为",
    Merge = "合并",
    ["Merge similar entries within 15 seconds. Avoids confusion with cycling through buffs to get to desired one giving multiple log entries."] = "合并15秒内的相似条目。避免在循环切换增益以获取所需增益时产生多条日志记录造成的混乱。",
    Open = "打开",
    ["Remotely changed"] = "远程修改",
    ["Saved template '%s'"] = "已保存模板 '%s'",
    ["%s %s's exception - %s from %s to %s"] = "%s %s 的例外规则 - %s 从 %s 改为 %s",
    ["%s %s's template - %s from %s to %s"] = "%s %s 的模板 - %s 从 %s 改为 %s",
    ["View the log"] = "查看日志",
} end)