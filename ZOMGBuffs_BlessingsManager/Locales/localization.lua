local L = LibStub("AceLocale-2.2"):new("ZOMGBlessingsManager")

L:RegisterTranslations("enUS", function() return {
	["Allow remote buff requests via the !zomg whisper command"] = "Allow remote buff requests via the !zomg whisper command",
	["Alt-Click to size window"] = "Alt-Click to size window",
	["Assigned %s to buff %s on %s (by request of %s)"] = "Assigned %s to buff %s on %s (by request of %s)",
	["Auto Assign"] = "Auto Assign",
	["Automatically assign all player roles"] = "Automatically assign all player roles",
	["Automatically assign players to sub-classes based on talent spec"] = "Automatically assign players to sub-classes based on talent spec",
	["Automatically open the class split frame when defining the sub-class buff assignments"] = "Automatically open the class split frame when defining the sub-class buff assignments",
	["Auto-Open Class Split"] = "Auto-Open Class Split",
	["Auto Roles"] = "Auto Roles",
	Autosave = "Autosave",
	Behaviour = "Behaviour",
	["Blessings Manager configuration"] = "Blessings Manager configuration",
	["Blessings Manager master template received from %s. Stored in local templates as |cFFFFFF80%s|r"] = "Blessings Manager master template received from %s. Stored in local templates as |cFFFFFF80%s|r",
	bok = "bok",
	bol = "bol",
	bom = "bom",
	bos = "bos",
	bow = "bow",
	Broadcast = "Broadcast",
	["Broadcast these templates to all paladins (Simply a refresh)"] = "Broadcast these templates to all paladins (Simply a refresh)",
	["Caster DPS"] = "Caster DPS",
	["Change how many groups are included in template generation and Paladin inclusion"] = "Change how many groups are included in template generation and Paladin inclusion",
	CHATHELP = "help",
	CHATHELPRESPONSE1 = "Usage: '!zomg +buff -buff', where +buff is the buff you want (ie: +bom) and -buff is the buff you want replace with it (ie: -bow). Various synonyms will work for the + and - buff names, ie: BOW bow wisdom.",
	CHATHELPRESPONSE2 = "Who does the buffs is not important for you to know (but you can query this with just '!zomg')",
	CHATHELPRESPONSE3 = "Example: '!zomg -bow +bok' - Will request that you get Kings instead of Wisdom",
	CHATHELPRESPONSE4 = "Example: '!zomg -kings +light' - Will request that you get Light instead of Kings",
	["Chat Interface"] = "Chat Interface",
	["Chat interface configuration"] = "Chat interface configuration",
	["Cleaned %d players from the stored sub-class list"] = "Cleaned %d players from the stored sub-class list",
	Cleanup = "Cleanup",
	["Cleanup options"] = "Cleanup options",
	Clear = "Clear",
	["Clear All"] = "Clear All",
	["Clear all single buff exceptions"] = "Clear all single buff exceptions",
	["Click to scale window"] = "Click to scale window",
	Configure = "Configure",
	["Configure the automatic template generation"] = "Configure the automatic template generation",
	Default = "Default",
	["%d Group"] = "%d Group",
	["%d Groups"] = "%d Groups",
	Display = "Display",
	["Display configuration"] = "Display configuration",
	Exceptions = "Exceptions",
	Finish = "Finish",
	["Finish configuring template"] = "Finish configuring template",
	Generate = "Generate",
	["Generate automatic templates from manager's main template. This will broadcast new templates to all paladins, so only use at start of raid to set initial configuration. Changes made later by individual paladins will be reflected in the blessings grid."] = "Generate automatic templates from manager's main template. This will broadcast new templates to all paladins, so only use at start of raid to set initial configuration. Changes made later by individual paladins will be reflected in the blessings grid.",
	["Generating Blessing Assignments for groups 1 to %d"] = "Generating Blessing Assignments for groups 1 to %d",
	["Grey out invalid Drag'n'Drop target cells"] = "Grey out invalid Drag'n'Drop target cells",
	Greyouts = "Greyouts",
	Healer = "Healer",
	Help = "Help",
	HELP_TEXT = "The Blessings Manager has two modes. The default mode simple shows the current blessings configuration for each paladin in the raid. The configure mode allows you to setup the default blessings per class, regardless of paladins present. These defaults can then be auto assigned by the 'Generate' button when in normal mode.\
\
The list of paladins shows their name along with some relevant information such as available blessings (as icons), talent spec, and ZOMGBuffs version\
\
|cFFFF8080Red Icons|r indicate a conflicting buff.\
|cFF8080FFBlue Icons|r indicate exceptions for this cell.\
\
|cFFFFFFFFNormal Mode|r\
|cFFFFFF80Left Click|r an icon to cycle through the blessings for that paladin and that class.\
|cFFFFFF80Right Click|r an icon to set an exception for a single player. That is to say, after the druids have been buffed with Greater Blessing of Wisdom for example, you may have a feral druid that requires Blessing of Might instead.\
\
|cFFFFFFFFConfigure Mode|r\
It is important to realise that the order of the blessings in this mode represents how many paladins you may have present in any given raid. Setup correctly you should rarely need to change this configuration. So, assuming you had one paladin in a raid, the auto assigned blessings would be taken from row 1. Two paladins would take from rows 1 and 2 and so on.\
\
|cFFFFFF80Left Click|r an icon to cycle through the blessings for that line and that class.\
\
Mousing over a class with sub-classes defined will expand that class to show the sub-classes. Set these classes up in the same way. Note that the sub-class split window will also open to allow you to move players into their correct sub-classes.\
\
|cFFFFFFFFConfigure Button|r\
This will toggle between the two modes (normal and configure).\
\
|cFFFFFFFFGenerate Button|r\
This will assign paladins present with blessings based on the configured global template, taking into account talents so that paladins with Improved Blessing of Might, for example, will be favored to buff this blessing.\
\
|cFFFFFFFFBroadcast Button|r\
This will simply re-broadcast the current blessing layout, should anyone need this after a WoW crash for example.\
\
",
	["Free Assign"] = "Free assignment",
	["Free Assign Desc"] = "Allow others to change your blessings without being leader/promoted",
	HELP_TITLE = "Blessing Manager Help",
	Highlights = "Highlights",
	["Highlight the selected row and column in the manager"] = "Highlight the selected row and column in the manager",
	Holy = "Holy",
	king = "king",
	kings = "kings",
	light = "light",
	Manager = "Manager",
	["Melee DPS"] = "Melee DPS",
	might = "might",
	None = "None",
	["Non-Guildies"] = "Non-Guildies",
	["Non-Raid Members"] = "Non-Raid Members",
	Open = "Open",
	["Open Blessings Manager"] = "Open Blessings Manager\
|cFF80FF80Note:|r you can also open the Blessings Manager by Alt-Clicking on the minimap icon.",
	["Other behaviour"] = "Other behaviour",
	["PallyPower users are in the raid and you are NOT promoted\
PallyPower only accepts assignment changes from promoted players"] = "PallyPower users are in the raid and you are NOT promoted\
PallyPower only accepts assignment changes from promoted players",
	["<player name>"] = "<player name>",
	["Player sub-class assignments received from %s"] = "Player sub-class assignments received from %s",
	Ranks = "Ranks",
	["Remote Buff Requests"] = "Remote Buff Requests",
	["Remove all exceptions for this cell"] = "Remove all exceptions for this cell",
	sal = "sal",
	salv = "salv",
	salvation = "salvation",
	san = "san",
	sanc = "sanc",
	sanctuary = "sanctuary",
	["%s And these single buffs afterwards:"] = "%s And these single buffs afterwards:",
	["%s Assigned %s to %s"] = "%s Assigned %s to %s",
	["%s Could not interpret %s"] = "%s Could not interpret %s",
	["Select the guild ranks to include"] = "Select the guild ranks to include",
	Send = "Send",
	["Send assignments to paladins without ZOMGBuffs or PallyPower via whispers?"] = "Send assignments to paladins without ZOMGBuffs or PallyPower via whispers?",
	["Send Blessings Manager master template to another player"] = "Send Blessings Manager master template to another player",
	["Send Blessings Manager sub-class assignments"] = "Send Blessings Manager sub-class assignments",
	["Send options"] = "Send options",
	["Show Exceptions"] = "Show Exceptions",
	["Show first 3 exception icons if any exist for a cell. Note that this option is automatically enabled for cells which do not have a greater blessing defined"] = "Show first 3 exception icons if any exist for a cell. Note that this option is automatically enabled for cells which do not have a greater blessing defined",
	["Single target exception for %s"] = "Single target exception for %s",
	["%s is offline, template not sent"] = "%s is offline, template not sent",
	SPLITTITLE = "Class Split",
	["%s Remote control of buff settings is not enabled"] = "%s Remote control of buff settings is not enabled",
	["%s %s is not allowed to do that"] = "%s %s is not allowed to do that",
	["%s skipped because no %s present"] = "%s skipped because no %s present",
	["%s %s, Please use these buff settings:"] = "%s %s, Please use these buff settings:",
	["Strip non-existant raid members from the stored sub-class definitions"] = "Strip non-existant raid members from the stored sub-class definitions",
	["Strip non-guildies from the stored sub-class definitions"] = "Strip non-guildies from the stored sub-class definitions",
	["Sub-Class Assignments"] = "Sub-Class Assignments",
	["Synchronised group count with %s to %d because of pending blessing assignments"] = "Synchronised group count with %s to %d because of pending blessing assignments",
	["%s You don't get %s from anyone"] = "%s You don't get %s from anyone",
	["%s Your Paladin buffs come from:"] = "%s Your Paladin buffs come from:",
	Tank = "Tank",
	Template = "Template",
	["Template configuration"] = "Template configuration",
	Templates = "Templates",
	TITLE = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|cFFFFFFFFBlessings Manager|r",
	TITLE_CONFIGURE = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|cFFFFFFFFBlessings Manager |cFF808080(configure)|r",
	["Unit exceptions"] = "Unit exceptions",
	Unlock = "Unlock",
	["Unlock undetected mod users for editing"] = "Unlock undetected mod users for editing",
	["Use Guild Roster"] = "Use Guild Roster",
	["Warning!"] = "Warning!",
	["Warning: Couldn't assign row %d exception of %s for %s to anyone"] = "Warning: Couldn't assign row %d exception of %s for %s to anyone",
	["What the hell am I looking at?"] = "What the hell am I looking at?",
	Whispers = "Whispers",
	wis = "wis",
	wisdom = "wisdom",
} end)
