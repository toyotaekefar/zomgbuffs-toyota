local L = LibStub("AceLocale-2.2"):new("ZOMGBlessingsManager")

L:RegisterTranslations("zhCN", function() return
--[===[@debug@
{
}
--@end-debug@]===]
{
	["Allow remote buff requests via the !zomg whisper command"] = "允许别人通过!zomg密语命令请求你Buff",
	["Alt-Click to size window"] = "Alt点击设置窗口大小",
	["Assigned %s to buff %s on %s (by request of %s)"] = "分配 %s Buff %s 给 %s (基于 %s 的请求)",
	["Auto Assign"] = "自动分配",
	["Automatically assign all player roles"] = "自动分配所有玩家的角色类型",
	["Automatically assign players to sub-classes based on talent spec"] = "依据天赋设置自动分配玩家次级职业",
	["Automatically open the class split frame when defining the sub-class buff assignments"] = "在定义次级职业Buff分配的时候自动开启职业分离框体",
	["Auto-Open Class Split"] = "自动开启职业分离",
	["Auto Roles"] = "自动分配角色",
	Autosave = "自动保存",
	Behaviour = "行为",
	["Blessings Manager configuration"] = "祝福管理器配置",
	["Blessings Manager master template received from %s. Stored in local templates as |cFFFFFF80%s|r"] = "祝福管理器从 %s 处收到了主模版，并在本地模板中保存为|cFFFFFF80%s|r",
	bok = "bok",
	bol = "bol",
	bom = "bom",
	bos = "bos",
	bow = "bow",
	Broadcast = "群发",
	["Broadcast these templates to all paladins (Simply a refresh)"] = "将这些模板群发给所有的圣骑士（简单刷新下）",
	["Caster DPS"] = "法系DPS",
	["Change how many groups are included in template generation and Paladin inclusion"] = "更改在方案生成中包含有多少队伍以及多少骑士",
	CHATHELP = "help",
	CHATHELPRESPONSE1 = "用法：“!zomg +buff -buff”，其中 +buff 是你想要的Buff（例如：+力量），-buff 是你想用来替换的Buff(例如：-智慧)。用到的法术的名字有一些同义词，例如：bow BOW 智慧。",
	CHATHELPRESPONSE2 = "谁负责施放这个Buff对你来说并不重要（但是你可以通过只输入 !zomg 命令进行查询）",
	CHATHELPRESPONSE3 = "举例：“!zomg -智慧 +王者” - 将会请求对你施放王者祝福，替换掉智慧祝福",
	CHATHELPRESPONSE4 = "举例：“!zomg -王者 +光明” - 将会请求对你施放光明祝福，替换掉王者祝福",
	["Chat Interface"] = "聊天界面",
	["Chat interface configuration"] = "聊天界面配置",
	["Cleaned %d players from the stored sub-class list"] = "从已保存的次级职业列表中清除了%d名玩家",
	Cleanup = "清理",
	["Cleanup options"] = "清理选项",
	Clear = "清除",
	["Clear All"] = "全部清除",
	["Clear all single buff exceptions"] = "清除全部的单体Buff例外",
	["Click to scale window"] = "点击缩放窗口",
	Configure = "配置",
	["Configure the automatic template generation"] = "配置自动模板生成选项",
	Default = "默认",
	["%d Group"] = "%d队",
	["%d Groups"] = "%d队",
	Display = "显示",
	["Display configuration"] = "显示配置",
	Exceptions = "例外",
	Finish = "完成",
	["Finish configuring template"] = "完成模板配置",
	Generate = "生成",
	["Generate automatic templates from manager's main template. This will broadcast new templates to all paladins, so only use at start of raid to set initial configuration. Changes made later by individual paladins will be reflected in the blessings grid."] = "从管理器主模版自动生成模板并群发给所有的圣骑士，所以在RAID开始时这么做以设置初始设定。随后各骑士独立的更改会反映在祝福格上。",
	["Generating Blessing Assignments for groups 1 to %d"] = "为队伍1至%d生成祝福分配方案",
	["Grey out invalid Drag'n'Drop target cells"] = "将无效的拖放目标格子灰掉",
	Greyouts = "无效指示",
	Healer = "治疗",
	Help = "帮助",
	HELP_TEXT = [=[祝福管理器有两种模式。默认模式只是简单地显示团队里每个圣骑士的祝福配置。配置模式允许你设置每个职业的默认祝福，而不管有没有骑士存在。这些默认值在普通模式下点击“生成”按钮时会自动分配。

圣骑士列表显示了他们的名字以及一些相关信息例如以图标形式显示的有效祝福，天赋配置，以及ZOMGBuffs版本

|cFFFF8080红色图标|r表明了一个有冲突的Buff。
|cFF8080FF蓝色图标|r表明了这个格子例外。

|cFFFFFFFF普通模式|r
|cFFFFFF80鼠标左键|r点击一个图标会为那个职业在那个骑士所拥有的祝福之间循环切换。
|cFFFFFF80Shift+鼠标左键|r点击一个图标会为所有职业在那个骑士所拥有的祝福之间循环切换。
|cFFFFFF80鼠标右键|r点击一个图标会为单个玩家设立一个例外。意思是说，假设所有的德鲁伊都被Buff完强效智慧祝福后，你可能会有一个野德需要Buff力量祝福取代智慧祝福。

|cFFFFFFFF配置模式|r
在这个模式下，重要的是要认识到祝福的顺序表明了在任何Raid中可能出现的骑士的数量。假如设置正确，你应该很少会更改这个配置。因此，假设你只有一名骑士在团队中，自动分配的祝福方案将来自于第一行，两名骑士的话，将使用第一行和第二行，以此类推。

|cFFFFFF80鼠标左键|r点击一个图标会为那个职业在那一行的祝福之间循环切换。

鼠标划过某个具有次级职业定义的职业将会展开以显示次级职业，以同样的方式设置这些职业。注意次级职业分离窗口同样也会打开，以便将玩家移动到属于他们正确的次级职业栏位中去。

|cFFFFFFFF配置按钮|r
在两个模式之间切换（普通和配置模式）。

|cFFFFFFFF生成按钮|r
以全局模板自动分配当前的圣骑士，同时还检查天赋设置，因此例如拥有强化力量祝福天赋的骑士将会被优先分配Buff力量祝福。

|cFFFFFFFF群发按钮|r
将当前的祝福配置重新群发一遍，用在某人掉线重新登录魔兽这样的情况上。

]=],
	["Free Assign"] = "自由配置",
	["Free Assign Desc"] = "允许其他非团队领袖/助理人员更改你的祝福配置",
	HELP_TITLE = "祝福管理器帮助",
	Highlights = "高亮",
	["Highlight the selected row and column in the manager"] = "在管理器内高亮所选择的行和列",
	Holy = "神圣",
	king = "王者",
	kings = "king",
	light = "光明",
	Manager = "管理器",
	["Melee DPS"] = "肉搏DPS",
	might = "力量",
	None = "无",
	["Non-Guildies"] = "非公会成员",
	["Non-Raid Members"] = "非团队成员",
	Open = "打开",
	["Open Blessings Manager"] = "打开祝福管理器",
	["Other behaviour"] = "其他行为",
	[ [=[PallyPower users are in the raid and you are NOT promoted
PallyPower only accepts assignment changes from promoted players]=] ] = [=[团队里有PallyPower用户，而你不是团队助理
PallyPower只接受助理以上的玩家的分配]=],
	["<player name>"] = "<玩家姓名>",
	["Player sub-class assignments received from %s"] = "从 %s 处收到玩家次级职业分配",
	Ranks = "级别",
	["Remote Buff Requests"] = "远程Buff请求",
	["Remove all exceptions for this cell"] = "为这个格子移除所有例外",
	sal = "sal",
	salv = "salv",
	salvation = "拯救",
	san = "san",
	sanc = "sanc",
	sanctuary = "庇护",
	["%s And these single buffs afterwards:"] = "%s以及这些单体Buff在此之后：",
	["%s Assigned %s to %s"] = "%s 分配了 %s 给 %s",
	["%s Could not interpret %s"] = "%s 无法解释 %s",
	["Select the guild ranks to include"] = "选择要包含的公会级别",
	Send = "发送",
	["Send assignments to paladins without ZOMGBuffs or PallyPower via whispers?"] = "即便圣骑士没有ZOMGBuffs或者PallyPower插件也对其发送分配密语？",
	["Send Blessings Manager master template to another player"] = "将祝福管理器的主模版发送给其他玩家",
	["Send Blessings Manager sub-class assignments"] = "发送祝福管理器次级职业分配",
	["Send options"] = "发送选项",
	["Show Exceptions"] = "显示例外",
	["Show first 3 exception icons if any exist for a cell. Note that this option is automatically enabled for cells which do not have a greater blessing defined"] = "如果某个格有例外则显示其前三个例外图标。注意当某格子没有定义强效祝福的时候该功能自动启用。",
	["Single target exception for %s"] = "Single target exception for %s",
	["%s is offline, template not sent"] = "%s不在线，模板未能发送",
	SPLITTITLE = "职业分离",
	["%s Remote control of buff settings is not enabled"] = "%s Buff设定远程控制没有开启",
	["%s %s is not allowed to do that"] = "%s %s 不允许那样做",
	["%s skipped because no %s present"] = "已跳过 %s 因为没有 %s 存在",
	["%s %s, Please use these buff settings:"] = "%s %s，请使用以下Buff设置：",
	["Strip non-existant raid members from the stored sub-class definitions"] = "从次级职业定义中剔除非团队成员",
	["Strip non-guildies from the stored sub-class definitions"] = "从次级职业定义中剔除非公会成员",
	["Sub-Class Assignments"] = "次级职业分配",
	["Synchronised group count with %s to %d because of pending blessing assignments"] = "已与 %s 同步队伍数量为 %d 因为未处理的祝福分配",
	["%s You don't get %s from anyone"] = "%s 你没有从任何人那里得到 %s",
	["%s Your Paladin buffs come from:"] = "%s 你的骑士Buff来自：",
	Tank = "坦克",
	Template = "模板",
	["Template configuration"] = "模板配置",
	Templates = "模板",
	TITLE = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|cFFFFFFFF祝福管理器|r",
	TITLE_CONFIGURE = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|cFFFFFFFF祝福管理器|cFF808080(配置模式)|r",
	["Unit exceptions"] = "单位例外",
	Unlock = "解锁",
	["Unlock undetected mod users for editing"] = "解锁编辑未检测的插件用户",
	["Use Guild Roster"] = "使用公会名单",
	["Warning!"] = "警告！",
	["Warning: Couldn't assign row %d exception of %s for %s to anyone"] = "Warning: Couldn't assign row %d exception of %s for %s to anyone",
	["What the hell am I looking at?"] = "这他喵的都是些什么？",
	Whispers = "密语",
	wis = "wis",
	wisdom = "智慧",
}

end)
