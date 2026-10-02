local L = LibStub("AceLocale-2.2"):new("ZOMGLog")

L:RegisterTranslations("koKR", function() return {
    Behaviour = "동작",
    Changed = "변경됨",
    ["Changed %s's exception - %s from %s to %s"] = "%s의 예외 변경 - %s: %s에서 %s(으)로",
    ["Changed %s's template - %s from %s to %s"] = "%s의 서식 변경 - %s: %s에서 %s(으)로",
    Clear = "초기화",
    ["Cleared %s's exceptions for %s"] = "%s의 %s에 대한 예외 사항을 삭제했습니다",
    ["Clear the log"] = "기록 초기화",
    ["Event Logging"] = "이벤트 기록",
    ["Generated automatic template"] = "자동 서식이 생성되었습니다",
    ["Loaded template '%s'"] = "'%s' 서식을 불러왔습니다",
    Log = "기록",
    ["Log behaviour"] = "기록 동작",
    Merge = "병합",
    ["Merge similar entries within 15 seconds. Avoids confusion with cycling through buffs to get to desired one giving multiple log entries."] = "15초 이내의 유사한 항목을 병합합니다. 원하는 효과를 얻기 위해 버프를 순환할 때 수많은 기록 항목이 생성되는 혼란을 방지합니다.",
    Open = "열기",
    ["Remotely changed"] = "원격으로 변경됨",
    ["Saved template '%s'"] = "'%s' 서식을 저장했습니다",
    ["%s %s's exception - %s from %s to %s"] = "%s %s의 예외 - %s: %s에서 %s(으)로",
    ["%s %s's template - %s from %s to %s"] = "%s %s의 서식 - %s: %s에서 %s(으)로",
    ["View the log"] = "기록 보기",
} end)