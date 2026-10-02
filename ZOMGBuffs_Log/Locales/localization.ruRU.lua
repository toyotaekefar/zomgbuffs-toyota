local L = LibStub("AceLocale-2.2"):new("ZOMGLog")

L:RegisterTranslations("ruRU", function() return {
    Behaviour = "Поведение",
    Changed = "Изменено",
    ["Changed %s's exception - %s from %s to %s"] = "Изменено исключение %s — %s с %s на %s",
    ["Changed %s's template - %s from %s to %s"] = "Изменён шаблон %s — %s с %s на %s",
    Clear = "Очистить",
    ["Cleared %s's exceptions for %s"] = "Очищены исключения %s для %s",
    ["Clear the log"] = "Очистить журнал",
    ["Event Logging"] = "Запись событий",
    ["Generated automatic template"] = "Сгенерирован автоматический шаблон",
    ["Loaded template '%s'"] = "Загружен шаблон '%s'",
    Log = "Журнал",
    ["Log behaviour"] = "Поведение журнала",
    Merge = "Объединять",
    ["Merge similar entries within 15 seconds. Avoids confusion with cycling through buffs to get to desired one giving multiple log entries."] = "Объединять похожие записи в течение 15 секунд. Помогает избежать замусоривания журнала множественными записями при переборе баффов.",
    Open = "Открыть",
    ["Remotely changed"] = "Изменено удалённо",
    ["Saved template '%s'"] = "Сохранён шаблон '%s'",
    ["%s %s's exception - %s from %s to %s"] = "%s исключение %s — %s с %s на %s",
    ["%s %s's template - %s from %s to %s"] = "%s шаблон %s — %s с %s на %s",
    ["View the log"] = "Просмотреть журнал",
} end)