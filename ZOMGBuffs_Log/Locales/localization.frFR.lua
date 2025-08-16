local L = LibStub("AceLocale-2.2"):new("ZOMGLog")

L:RegisterTranslations("frFR", function() return
--[===[@debug@
{
}
--@end-debug@]===]
{
	Behaviour = "Comportement",
	Changed = "Changé",
	["Changed %s's exception - %s from %s to %s"] = "Exception de %s modifié - %s de %s à %s",
	["Changed %s's template - %s from %s to %s"] = "Modèle de %s modifié - %s de %s à %s", -- Needs review
	Clear = "Vider",
	["Cleared %s's exceptions for %s"] = "Exception de %s vidé pour %s", -- Needs review
	["Clear the log"] = "Vider le journal",
	["Event Logging"] = "Journalisation des évènements",
	["Generated automatic template"] = "Génération automatique du modèle",
	["Loaded template '%s'"] = "Modèle '%s' chargé", -- Needs review
	Log = "Journal",
	["Log behaviour"] = "Comportement du journal", -- Needs review
	Merge = "Fusionner",
	["Merge similar entries within 15 seconds. Avoids confusion with cycling through buffs to get to desired one giving multiple log entries."] = "Fusionne les entrées similaires sur 15s successives. Evite les problèmes de confusion avec les cycles de buffs afin d'obtenir le buff désiré.",
	Open = "Ouvrir",
	["Remotely changed"] = "Changé à distance", -- Needs review
	["Saved template '%s'"] = "Modèle '%s' sauvegardé", -- Needs review
	["%s %s's exception - %s from %s to %s"] = "%s Exception de %s - %s de %s à %s", -- Needs review
	["%s %s's template - %s from %s to %s"] = "%s Modèle de %s - %s de %s à %s", -- Needs review
	["View the log"] = "Voir le journal",
}

end)
