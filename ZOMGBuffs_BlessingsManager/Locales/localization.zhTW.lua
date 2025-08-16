local L = LibStub("AceLocale-2.2"):new("ZOMGBlessingsManager")

L:RegisterTranslations("zhTW", function() return
--[===[@debug@
{
}
--@end-debug@]===]
{
	["Allow remote buff requests via the !zomg whisper command"] = "允許別人通過!zomg密語命令請求你Buff",
	["Alt-Click to size window"] = "Alt點擊設置視窗大小",
	["Assigned %s to buff %s on %s (by request of %s)"] = "分配 %s Buff %s 給 %s (基於 %s 的請求)",
	["Auto Assign"] = "自動分配",
	["Automatically assign all player roles"] = "自動分配所有玩家的職能",
	["Automatically assign players to sub-classes based on talent spec"] = "依據天賦設置自動分配玩家次級職業",
	["Automatically open the class split frame when defining the sub-class buff assignments"] = "在定義次級職業Buff分配的時候自動開啟職業分離框體",
	["Auto-Open Class Split"] = "自動開啟職業分離",
	["Auto Roles"] = "自動職能",
	Autosave = "自動保存",
	Behaviour = "行為",
	["Blessings Manager configuration"] = "祝福管理器配置",
	["Blessings Manager master template received from %s. Stored in local templates as |cFFFFFF80%s|r"] = "祝福管理器從 %s 處收到了主模版，並在本地範本中保存為|cFFFFFF80%s|r",
	bok = "bok",
	bol = "bol",
	bom = "bom",
	bos = "bos",
	bow = "bow",
	Broadcast = "群發",
	["Broadcast these templates to all paladins (Simply a refresh)"] = "將這些範本群發給所有的聖騎士（簡單刷新下）",
	["Caster DPS"] = "法系DPS",
	["Change how many groups are included in template generation and Paladin inclusion"] = "更改在方案生成中包含有多少隊伍以及多少騎士",
	CHATHELP = "help",
	CHATHELPRESPONSE1 = "用法：“!zomg +buff -buff”，其中 +buff 是你想要的Buff（例如：+力量），-buff 是你想用來替換的Buff(例如：-智慧)。用到的法術的名字有一些同義詞，例如：bow BOW 智慧。",
	CHATHELPRESPONSE2 = "誰負責施放這個Buff對你來說並不重要（但是你可以通過只輸入 !zomg 命令進行查詢）",
	CHATHELPRESPONSE3 = "舉例：“!zomg -智慧 +王者” - 將會請求對你施放王者祝福，替換掉智慧祝福",
	CHATHELPRESPONSE4 = "舉例：“!zomg -王者 +光明” - 將會請求對你施放光明祝福，替換掉王者祝福",
	["Chat Interface"] = "聊天介面",
	["Chat interface configuration"] = "聊天介面配置",
	["Cleaned %d players from the stored sub-class list"] = "從已保存的次級職業列表中清除了%d名玩家",
	Cleanup = "清理",
	["Cleanup options"] = "清理選項",
	Clear = "清除",
	["Clear All"] = "全部清除",
	["Clear all single buff exceptions"] = "清除全部的單體Buff例外",
	["Click to scale window"] = "點擊縮放窗口",
	Configure = "配置",
	["Configure the automatic template generation"] = "配置自動範本生成選項",
	Default = "默認",
	["%d Group"] = "%d隊",
	["%d Groups"] = "%d隊",
	Display = "顯示",
	["Display configuration"] = "顯示配置",
	Exceptions = "例外",
	Finish = "完成",
	["Finish configuring template"] = "完成範本配置",
	Generate = "生成",
	["Generate automatic templates from manager's main template. This will broadcast new templates to all paladins, so only use at start of raid to set initial configuration. Changes made later by individual paladins will be reflected in the blessings grid."] = "從管理器主模版自動生成範本並群發給所有的聖騎士，所以在RAID開始時這麼做以設置初始設定。隨後各騎士獨立的更改會反映在祝福格上。",
	["Generating Blessing Assignments for groups 1 to %d"] = "為隊伍1至%d生成祝福分配方案",
	["Grey out invalid Drag'n'Drop target cells"] = "將無效的拖放目標格子灰掉",
	Greyouts = "無效指示",
	Healer = "治療",
	Help = "説明",
	HELP_TEXT = [=[祝福管理器有兩種模式。默認模式只是簡單地顯示團隊裏每個聖騎士的祝福配置。配置模式允許你設置每個職業的默認祝福，而不管有沒有騎士存在。這些預設值在普通模式下點擊“生成”按鈕時會自動分配。

聖騎士列表顯示了他們的名字以及一些相關資訊例如以圖示形式顯示的有效祝福，天賦配置，以及ZOMGBuffs版本

|cFFFF8080紅色圖示|r表明了一個有衝突的Buff。
|cFF8080FF藍色圖示|r表明了這個格子例外。

|cFFFFFFFF普通模式|r
|cFFFFFF80滑鼠左鍵|r點擊一個圖示會為那個職業在那個騎士所擁有的祝福之間迴圈切換。
|cFFFFFF80滑鼠右鍵|r點擊一個圖示會為單個玩家設立一個例外。意思是說，假設所有的德魯伊都被Buff完強效智慧祝福後，你可能會有一個野德需要Buff力量祝福取代智慧祝福。

|cFFFFFFFF配置模式|r
在這個模式下，重要的是要認識到祝福的順序表明了在任何Raid中可能出現的騎士的數量。假如設置正確，你應該很少會更改這個配置。因此，假設你只有一名騎士在團隊中，自動分配的祝福方案將來自于第一行，兩名騎士的話，將使用第一行和第二行，以此類推。

|cFFFFFF80滑鼠左鍵|r點擊一個圖示會為那個職業在那一行的祝福之間迴圈切換。

滑鼠劃過某個具有次級職業定義的職業將會展開以顯示次級職業，以同樣的方式設置這些職業。注意次級職業分離視窗同樣也會打開，以便將玩家移動到屬於他們正確的次級職業欄位中去。

|cFFFFFFFF配置按鈕|r
在兩個模式之間切換（普通和配置模式）。

|cFFFFFFFF生成按鈕|r
以全局範本自動分配當前的聖騎士，同時還檢查天賦設置，因此例如擁有強化力量祝福天賦的騎士將會被優先分配Buff力量祝福。

|cFFFFFFFF群發按鈕|r
將當前的祝福配置重新群發一遍，用在某人掉線重新登錄魔獸這樣的情況上。

]=],
	HELP_TITLE = "祝福管理器幫助",
	Highlights = "高亮",
	["Highlight the selected row and column in the manager"] = "在管理器內高亮所選擇的行和列",
	Holy = "神聖",
	king = "王者",
	kings = "king",
	light = "光明",
	Manager = "管理器",
	["Melee DPS"] = "肉搏DPS",
	might = "力量",
	None = "無",
	["Non-Guildies"] = "非公會成員",
	["Non-Raid Members"] = "非團隊成員",
	Open = "打開",
	["Open Blessings Manager"] = "打開祝福管理器",
	["Other behaviour"] = "其他行為",
	[ [=[PallyPower users are in the raid and you are NOT promoted
PallyPower only accepts assignment changes from promoted players]=] ] = [=[團隊裏有PallyPower用戶，而你不是團隊助理
PallyPower只接受助理以上的玩家的分配]=],
	["<player name>"] = "<玩家姓名>",
	["Player sub-class assignments received from %s"] = "從 %s 處收到玩家次級職業分配",
	Ranks = "級別",
	["Remote Buff Requests"] = "遠程Buff請求",
	["Remove all exceptions for this cell"] = "為這個格子移除所有例外",
	sal = "sal",
	salv = "salv",
	salvation = "拯救",
	san = "san",
	sanc = "sanc",
	sanctuary = "庇護",
	["%s And these single buffs afterwards:"] = "%s以及這些單體Buff在此之後：",
	["%s Assigned %s to %s"] = "%s 分配了 %s 給 %s",
	["%s Could not interpret %s"] = "%s 無法解釋 %s",
	["Select the guild ranks to include"] = "選擇要包含的公會級別",
	Send = "發送",
	["Send assignments to paladins without ZOMGBuffs or PallyPower via whispers?"] = "即便聖騎士沒有ZOMGBuffs或者PallyPower插件也對其發送分配密語？",
	["Send Blessings Manager master template to another player"] = "將祝福管理器的主模版發送給其他玩家",
	["Send Blessings Manager sub-class assignments"] = "發送祝福管理器次級職業分配",
	["Send options"] = "發送選項",
	["Show Exceptions"] = "顯示例外",
	["Show first 3 exception icons if any exist for a cell. Note that this option is automatically enabled for cells which do not have a greater blessing defined"] = "如果某個格有例外則顯示其前三個例外圖示。注意當某格子沒有定義強效祝福的時候該功能自動啟用。",
	["Single target exception for %s"] = "Single target exception for %s",
	["%s is offline, template not sent"] = "%s不線上，範本未能發送",
	SPLITTITLE = "職業分離",
	["%s Remote control of buff settings is not enabled"] = "%s Buff設定遠端控制沒有開啟",
	["%s %s is not allowed to do that"] = "%s %s 不允許那樣做",
	["%s skipped because no %s present"] = "已跳過 %s 因為沒有 %s 存在",
	["%s %s, Please use these buff settings:"] = "%s %s，請使用以下Buff設置：",
	["Strip non-existant raid members from the stored sub-class definitions"] = "從次級職業定義中剔除非團隊成員",
	["Strip non-guildies from the stored sub-class definitions"] = "從次級職業定義中剔除非公會成員",
	["Sub-Class Assignments"] = "次級職業分配",
	["Synchronised group count with %s to %d because of pending blessing assignments"] = "已與 %s 同步隊伍數量為 %d 因為未處理的祝福分配",
	["%s You don't get %s from anyone"] = "%s 你沒有從任何人那裏得到 %s",
	["%s Your Paladin buffs come from:"] = "%s 你的騎士Buff來自：",
	Tank = "坦克",
	Template = "範本",
	["Template configuration"] = "範本配置",
	Templates = "範本",
	TITLE = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|cFFFFFFFF祝福管理器|r",
	TITLE_CONFIGURE = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|cFFFFFFFF祝福管理器|cFF808080(配置模式)|r",
	["Unit exceptions"] = "單位例外",
	Unlock = "解鎖",
	["Unlock undetected mod users for editing"] = "解鎖編輯未檢測的插件用戶",
	["Use Guild Roster"] = "使用公會名單",
	["Warning!"] = "警告！",
	["Warning: Couldn't assign row %d exception of %s for %s to anyone"] = "Warning: Couldn't assign row %d exception of %s for %s to anyone",
	["What the hell am I looking at?"] = "這他喵的都是些什麼？",
	Whispers = "密語",
	wis = "wis",
	wisdom = "智慧",
}

end)
