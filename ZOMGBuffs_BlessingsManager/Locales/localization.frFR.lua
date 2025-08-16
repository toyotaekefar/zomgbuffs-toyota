local L = LibStub("AceLocale-2.2"):new("ZOMGBlessingsManager")

L:RegisterTranslations("frFR", function() return
--[===[@debug@
{
}
--@end-debug@]===]
{
	["Allow remote buff requests via the !zomg whisper command"] = "Autorise les requêtes distante de buff par la commande en chuchotement !zomg",
	["Alt-Click to size window"] = "Alt-clique pour changer la taille de la fenêtre",
	["Assigned %s to buff %s on %s (by request of %s)"] = "Assignation de %s pour buffer %s sur %s (sur la demande de %s)",
	["Auto Assign"] = "Répartir auto.",
	["Automatically assign all player roles"] = "Assigner automatiquement tout les rôles des joueurs",
	["Automatically assign players to sub-classes based on talent spec"] = "Assigne automatiquement les joueurs aux sous-classes en se basant sur leurs talents",
	["Automatically open the class split frame when defining the sub-class buff assignments"] = "Déploie automatiquement la fenêtre de séparation de classe lors de la configuration des buffs pour les sous-classes",
	["Auto-Open Class Split"] = "Déploiement automatique des sous-classes",
	["Auto Roles"] = "Rôles automatiques",
	Autosave = "Sauvegarde automatique",
	Behaviour = "Comportement",
	["Blessings Manager configuration"] = "Configuration du Gestionnaire de bénédiction",
	["Blessings Manager master template received from %s. Stored in local templates as |cFFFFFF80%s|r"] = "Modèle référence du Gestionnaire de bénédiction reçu de %s. Stocker en modèle local comme |cFFFFFF80%s|r",
	bok = "BoK",
	bol = "BoL",
	bom = "PA",
	bos = "BoS",
	bow = "sag",
	Broadcast = "Diffuser",
	["Broadcast these templates to all paladins (Simply a refresh)"] = "Diffuse ces modèles à tous les paladins (simple rafraîchissement)",
	["Caster DPS"] = "DPS distant",
	["Change how many groups are included in template generation and Paladin inclusion"] = "Changer le nombre de groupes inclus dans la génération du modèle de bénés", -- Needs review
	CHATHELP = "Aide",
	CHATHELPRESPONSE1 = "Usage: '!zomg +buff -buff', where +buff is the buff you want (ie: +bom) and -buff is the buff you want replace with it (ie: -bow). Various synonyms will work for the + and - buff names, ie: BOW bow wisdom.",
	CHATHELPRESPONSE2 = "Who does the buffs is not important for you to know (but you can query this with just '!zomg')",
	CHATHELPRESPONSE3 = "Example: '!zomg -bow +bok' - Will request that you get Kings instead of Wisdom",
	CHATHELPRESPONSE4 = "Example: '!zomg -kings +light' - Will request that you get Light instead of Kings",
	["Chat Interface"] = "Interface de discussion",
	["Chat interface configuration"] = "Configuration de l'interface de discussion",
	["Cleaned %d players from the stored sub-class list"] = "A retiré %d joueurs de la liste des sous clasess",
	Cleanup = "Nettoyage",
	["Cleanup options"] = "Options de nettoyage",
	Clear = "Vider",
	["Clear All"] = "Vider tout",
	["Clear all single buff exceptions"] = "Efface tout les exceptions de buff simple",
	["Click to scale window"] = "Cliquer pour changer l'echelle de la fenêtre",
	Configure = "Configurer",
	["Configure the automatic template generation"] = "Configure la génération automatique de modèle",
	Default = "Défaut",
	["%d Group"] = "%d Groupe",
	["%d Groups"] = "%d Groupes",
	Display = "Afficher",
	["Display configuration"] = "Affiche la configuration",
	Exceptions = "Exceptions",
	Finish = "Terminer",
	["Finish configuring template"] = "Termine la configuration du modèle",
	Generate = "Générer",
	["Generate automatic templates from manager's main template. This will broadcast new templates to all paladins, so only use at start of raid to set initial configuration. Changes made later by individual paladins will be reflected in the blessings grid."] = "Genère automatiquement les modèles à partir du modèle référence du gestionnaire. Ceci diffusera les nouveau modèles à tous les paladins, à n'utiliser qu'en début de raid. Tout changement fait individuellement par les paladins sera visible dans la grille des bénédictions",
	["Generating Blessing Assignments for groups 1 to %d"] = "Générer les assignements de bénédictions pour les groupes 1 à %d",
	["Grey out invalid Drag'n'Drop target cells"] = "Griser les cellules cibles invalides lors d'un Glisser-déposer", -- Needs review
	Greyouts = "Grisés",
	Healer = "Soin",
	Help = "Aide",
	HELP_TEXT = [=[The Blessings Manager has two modes. The default mode simple shows the current blessings configuration for each paladin in the raid. The configure mode allows you to setup the default blessings per class, regardless of paladins present. These defaults can then be auto assigned by the 'Generate' button when in normal mode.

The list of paladins shows their name along with some relevant information such as available blessings (as icons), talent spec, and ZOMGBuffs version

|cFFFF8080Red Icons|r indicate a conflicting buff. |cFF8080FFBlue Icons|r indicate exceptions for this cell.

|cFFFFFFFFNormal Mode|r
|cFFFFFF80Left Click|r an icon to cycle through the blessings for that paladin and that class.
|cFFFFFF80Right Click|r an icon to set an exception for a single player. That is to say, after the druids have been buffed with Greater Blessing of Wisdom for example, you may have a feral druid that requires Blessing of Might instead.

|cFFFFFFFFConfigure Mode|r
It is important to realise that the order of the blessings in this mode represents how many paladins you may have present in any given raid. Setup correctly you should rarely need to change this configuration. So, assuming you had one paladin in a raid, the auto assigned blessings would be taken from row 1. Two paladins would take from rows 1 and 2 and so on.

|cFFFFFF80Left Click|r an icon to cycle through the blessings for that line and that class.

Mousing over a class with sub-classes defined will expand that class to show the sub-classes. Set these classes up in the same way. Note that the sub-class split window will also open to allow you to move players into their correct sub-classes.

|cFFFFFFFFConfigure Button|r
This will toggle between the two modes (normal and configure).

|cFFFFFFFFGenerate Button|r
This will assign paladins present with blessings based on the configured global template, taking into account talents so that paladins with Improved Blessing of Might, for example, will be favored to buff this blessing.

|cFFFFFFFFBroadcast Button|r
This will simply re-broadcast the current blessing layout, should anyone need this after a WoW crash for example.

]=],
	["Free Assign"] = "Assignement libre",
	["Free Assign Desc"] = "Autoriser les autres à changer vos bénédictions sans être leader/assistant",
	HELP_TITLE = "Blessing Manager Help",
	Highlights = "Surlignements",
	["Highlight the selected row and column in the manager"] = "Surligne les colonnes et lignes sélectionnées dans le gestionnaire",
	Holy = "Sacré",
	king = "Roi",
	kings = "Rois",
	light = "Lumière",
	Manager = "Gestionnaire",
	["Melee DPS"] = "DPS cac",
	might = "Puissance",
	None = "Aucun",
	["Non-Guildies"] = "Hors guilde",
	["Non-Raid Members"] = "Membres hors raid",
	Open = "Ouvrir",
	["Open Blessings Manager"] = "Ouvrir le Gestionnaire de bénédiction",
	["Other behaviour"] = "Comportement divers",
	[ [=[PallyPower users are in the raid and you are NOT promoted
PallyPower only accepts assignment changes from promoted players]=] ] = [=[Il y a des utilisateurs de PallyPower dans le raid et vous n'avez PAS de promotion
PallyPower n'accepte que les changements d'assignations de joueur promus]=],
	["<player name>"] = "<nom du joueur>",
	["Player sub-class assignments received from %s"] = "Assignation des joueurs en sous-classes reçu de %s",
	Ranks = "Rangs",
	["Remote Buff Requests"] = "Requête distante de buff",
	["Remove all exceptions for this cell"] = "Efface toutes les exceptions pour cette cellule",
	sal = "Salut",
	salv = "Salut",
	salvation = "Salut",
	san = "Sanc",
	sanc = "Sanc",
	sanctuary = "Sanctuaire",
	["%s And these single buffs afterwards:"] = "%s Puis ces buffs unitaires :",
	["%s Assigned %s to %s"] = "%s assigné de %s à %s",
	["%s Could not interpret %s"] = "%s ne comprends pas %s",
	["Select the guild ranks to include"] = "Sélectionner les rangs de guilde à inclure",
	Send = "Envoyer",
	["Send assignments to paladins without ZOMGBuffs or PallyPower via whispers?"] = "Envoyer les assignations de buffs aux paladins sans ZOMGBuffs ou PallyPower via les chuchotements ?",
	["Send Blessings Manager master template to another player"] = "Envoie le modèle référence du Gestionnaire de bénédiction à un autre joueur",
	["Send Blessings Manager sub-class assignments"] = "Envoie au Gestionnaire de bénédiction les assignations des sous-classes",
	["Send options"] = "Options d'envoie",
	["Show Exceptions"] = "Montres les exceptions",
	["Single target exception for %s"] = "Exception de cible unique pour %s",
	["%s is offline, template not sent"] = "%s est hors-ligne, le modèle n'a pas été envoyé",
	SPLITTITLE = "Sous-classes",
	["%s Remote control of buff settings is not enabled"] = "%s le contrôle a distance de la gestion des buffs n'est pas activé",
	["%s %s is not allowed to do that"] = "%s %s n'est pas autorisé à faire ceci",
	["%s skipped because no %s present"] = "%s passé parce qu'aucun %s présent",
	["%s %s, Please use these buff settings:"] = "%s %s, Merci d'utiliser cette configuration de buff :",
	["Strip non-existant raid members from the stored sub-class definitions"] = "Retire les joueurs non présent dans le raid de l'assignation aux sous classes",
	["Strip non-guildies from the stored sub-class definitions"] = "Retire les joueurs hors guilde de l'assignation aux sous classes",
	["Sub-Class Assignments"] = "Assignation des sous-classes",
	["%s You don't get %s from anyone"] = "%s vous ne recevez de personne %s",
	["%s Your Paladin buffs come from:"] = "%s votre buffs Paladin vient de :",
	Tank = "Tank",
	Template = "Modèle",
	["Template configuration"] = "Configuration du modèle",
	Templates = "Modèles",
	TITLE = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|cFFFFFFFF Gestionnaire de bénédiction|r",
	TITLE_CONFIGURE = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|cFFFFFFFF Gestionnaire de bénédiction |cFF808080(configuration)|r",
	["Unit exceptions"] = "Exceptions d'unité",
	Unlock = "Dévéruiller",
	["Unlock undetected mod users for editing"] = "Dévérouille les utilisateurs sans addons détecté pour édition",
	["Use Guild Roster"] = "Utiliser le roster de la guilde",
	["Warning!"] = "Attention !",
	["Warning: Couldn't assign row %d exception of %s for %s to anyone"] = "Attention : Il est impossible d'assigner à quelqu'un la ligne %d d'exception de %s pour %s",
	["What the hell am I looking at?"] = "Qu'est ce que je suis en train de faire...?",
	Whispers = "Chuchotements",
	wis = "sag",
	wisdom = "sagesse",
}

end)
