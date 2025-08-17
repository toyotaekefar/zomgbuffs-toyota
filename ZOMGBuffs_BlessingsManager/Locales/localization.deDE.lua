local L = LibStub("AceLocale-2.2"):new("ZOMGBlessingsManager")

L:RegisterTranslations("deDE", function() return
--[===[@debug@
{
}
--@end-debug@]===]
{
	["Allow remote buff requests via the !zomg whisper command"] = "Erlaube Einteilungsanfragen von anderen über das !zomg Flüsterkommando erlauben",
	["Alt-Click to size window"] = "Alt-Klick um die Fenstergröße anzupassen",
	["Assigned %s to buff %s on %s (by request of %s)"] = "%s eingeteilt, um %s auf %s zu wirken (auf Anfrage von %s)",
	["Auto Assign"] = "Autom. Einteilung",
	["Automatically assign all player roles"] = "Alle Spielerrollen automatisch verteilen",
	["Automatically assign players to sub-classes based on talent spec"] = "Alle Spieler automatisch anhand ihrer Talentspezialisierung den Unter-Klassen zuteilen",
	["Automatically open the class split frame when defining the sub-class buff assignments"] = "Öffne das Unterklassenfenster automatisch bei der definierung von Unterklassen Stärkungszaubern",
	["Auto-Open Class Split"] = "Klassenaufteilung automatisch öffnen",
	["Auto Roles"] = "Autom. Rollen",
	Autosave = "Automatisch speichern",
	Behaviour = "Verhalten",
	["Blessings Manager configuration"] = "Segen Manager Konfiguration",
	["Blessings Manager master template received from %s. Stored in local templates as |cFFFFFF80%s|r"] = "Segen Manager Master Vorlage erhalten von %s. Lokal gespeichert als |cFFFFFF80%s|r",
	bok = "SdK",
	bol = "SdW",
	bom = "SdM",
	bos = "SdR",
	bow = "Bogen",
	Broadcast = "Syncronisieren",
	["Broadcast these templates to all paladins (Simply a refresh)"] = "Syncronisiert die Buffeinteilungen mit anderen Paladinen (Aktualisierung)",
	["Caster DPS"] = "Schadenszauberwirker",
	["Change how many groups are included in template generation and Paladin inclusion"] = "Ändere die Anzahl der Schlachtzugsrelevanten Gruppen. (Paladine in anderen Gruppen werden Ausgeblendet)",
	CHATHELP = "Hilfe",
	CHATHELPRESPONSE1 = "Benutze: '!zomg +buff -buff', wovon +buff der Segen ist, den du willst (z.B.: +SdM) und -buff ist der Segen, der Ersetzt werden soll (z.B.: -SdW). Verschiedene Synonyme funktionieren ebenfalls für die + und - Segen Namen, z.B.: SDW sdw weisheit.",
	CHATHELPRESPONSE2 = "Es ist für dich irrelevant (du kannst dies jedoch mit '!zomg' abfragen), von wem deine Buffs kommen",
	CHATHELPRESPONSE3 = "Beispiel: '!zomg -sdw +sdk' - Fragt an, dass du Segen der Könige anstelle von Segen der Weisheit erhälst",
	CHATHELPRESPONSE4 = "Beispiel: '!zomg -könige +macht' - Fragt an, dass du Segen der Macht anstelle von Segen der Könige erhälst",
	["Chat Interface"] = "Chat Interface",
	["Chat interface configuration"] = "Chat Interface Konfiguration",
	["Cleaned %d players from the stored sub-class list"] = "Säuberte %d Spieler von der gespeicherten Unter-Klassen Liste",
	Cleanup = "Säubern",
	["Cleanup options"] = "Säuberungsoptionen",
	Clear = "Löschen",
	["Clear All"] = "Alles Löschen",
	["Clear all single buff exceptions"] = "Lösche alle Einzelausnahmen",
	["Click to scale window"] = "Klicken um Fenstergröße zu ändern",
	Configure = "Konfigurieren",
	["Configure the automatic template generation"] = "Einstellungen für den automatischen Vorlagen Generator",
	Default = "Standard",
	["%d Group"] = "%d Gruppe",
	["%d Groups"] = "%d Gruppen",
	Display = "Anzeige",
	["Display configuration"] = "Anzeigeeinstellungen",
	Exceptions = "Ausnahmen",
	Finish = "Fertig",
	["Finish configuring template"] = "Konfigurationsvorlage fertigstellen",
	Generate = "Generieren",
	["Generate automatic templates from manager's main template. This will broadcast new templates to all paladins, so only use at start of raid to set initial configuration. Changes made later by individual paladins will be reflected in the blessings grid."] = "Generiert eine automatische Vorlage von der Manager Hauptvorlage. Anschliesend wird die neue Vorlage an alle Paladine gesendet. Diese Initialkonfiguration muss nur zu Beginn eines Schlachtzuges stattfinden. Spätere Änderungen von einzelnen Paladinen werden automatisch in der Tabelle dargestellt.",
	["Generating Blessing Assignments for groups 1 to %d"] = "Erzeuge Segen Einteilung für Gruppen 1 bis %s",
	Greyouts = "Ausgrauen",
	Healer = "Heiler",
	Help = "Hilfe",
	HELP_TEXT = [=[Der Segen Manager besitzt zwei Modi. Der Standardmodus zeigt die Segen Einteilungen für jeden Paladin im Schlachtzug an. Der Konfigurationsmodus erlaubt dir unabhängig von der Anwesenheit anderer Paladine, eine Stärkungszauber-Prioritätenliste für jede Klasse und ihren Unterklassen zu erstellen. Diese Prioritätenliste wird dann automatisch angewandt sobald du die "Generieren" Schaltfläche im Standardmodus benutzt.

Die Liste der Paladine zeigt ihren Namen und einige relevante Zusatzinformationen, wie z.B. die verfügbaren Segen (als Symbol), Talentspezialisierung und ihre ZOMGBuffs Version (oder ob es sich um PallyPower Benutzer handelt)

|cFFFF8080Rote Symbole|r zeigen Stärkungszauberkonflikte an (z.B. bei gleicher Einteilung bei zwei Paladinen).
|cFF8080FFBlaue Sybbole|r zeigen Ausnahmen für diese Zelle an.

|cFFFFFFFFStandardmodus|r
|cFFFFFF80Linksklick|r auf ein Symbol um durch die Segen dieses Paladins und dieser Klasse zu wechselnan.
|cFFFFFF80Shift+Linksklick|r auf ein Symbol um durch die Segen dieses Paladins für alle Klassen zu wechselnan.
|cFFFFFF80Rechtsklick|r auf ein Symbol um Ausnahmen für einzelne Spieler zu wählen. Hiermit kann man z.B. allen Druiden den großen Segen der Weisheit zuweisen, einem einzenen Wilder Kampf Druide jedoch einen kleinen Segen der Macht.

|cFFFFFFFFKonfigurationsmodus|r
Es ist wichtig, zu verstehen, dass die Reihenfolge der Segen in diesem Modus die Anzahl der anwesenden Paladine in jedem möglichen Schlachtzug wiedergibt. Bei sorgfältiger Voreinstellung sollte der Segen-Generator nur selten Anlass zu manuellen Nachbesserungen geben. Angenommen, es befindet sich nur ein Paladin im Schlachtzug, dann werden automatisch die Segen aus der ersten Zeile zugeteilt. Bei zwei Paladinen würden die ersten beiden Zeilen zugewiesen werden usw.

|cFFFFFF80Linksklick|r auf ein Symbol um durch die Segen für diese Zeile und Klasse zu wechseln.

Beim Überfahren einer Klasse mit der Maus öffenen sich die Unter-Klassen, welche auf genau dem gleichen Wege einzustellen sind. Beachte, dass sich beim Überfahren auch das Klassen-Aufteilungs-Fenster öffnet, welches individuelle Voreinstellungen für einzelne Spieler und deren Unter-Klasse ermöglicht.

|cFFFFFFFFKonfigurationsschaltfläche|r
Wechselt zwischen den beiden Modi (Standard und Konfiguration).

|cFFFFFFFFGenerator-Schaltfläche|r
Generiert eine automatische Segen Einteilung für alle anwesenden Paladine, abhängig von den Voreinstellungen des Konfigurationsmodus. Hierbei werden Talentspezialisierungen der einzelnen Paladine berücksichtigt, sodass z.B. Klassen, für die Segen der Macht eine höhere Bedeutung hat, vorzugsweise auch einen verbesserten Segen der Macht erhalten.

|cFFFFFFFFSyncronosieren-Schaltfläche|r
Syncronisiert bzw. sendet die aktuelle Segen Einteilung erneut. Wichtig nach einem Absturz von WoW, Verbindungsabbrüchen, etc.]=],
	["Free Assign"] = "Freie Zuteilung",
	["Free Assign Desc"] = "Erlaubt anderen Spielern, Deine Segenzuteilung zu verändern, ohne Gruppenleiter oder Schlachtzug-Assistent zu sein.",
	HELP_TITLE = "Segen Manager Hilfe",
	Highlights = "Hervorhebungen",
	["Highlight the selected row and column in the manager"] = "Hebe die ausgewählten Spalten und Zeilen im Manager hervor",
	Holy = "Heilig",
	king = "König",
	kings = "Könige",
	light = "Licht",
	Manager = "Manager",
	["Melee DPS"] = "Nahkämpfer",
	might = "Macht",
	None = "Keine",
	["Non-Guildies"] = "Nicht-Gildenmitglieder",
	["Non-Raid Members"] = "Nicht-Schlachtzugsmitglieder",
	Open = "Öffnen",
	["Open Blessings Manager"] = [=[Segen Manager öffnen
|cFF80FF80Hinweis:|r Du kannst den Segen Manager auch mit Alt-Klick auf dein Minikarten Symbol öffnen.]=],
	["Other behaviour"] = "Anderes Verhalten",
	[ [=[PallyPower users are in the raid and you are NOT promoted
PallyPower only accepts assignment changes from promoted players]=] ] = [=[Es befinden sich PallyPower Benutzer im Schlachtzug und du besitzt KEINE Assistenzrechte
PallyPower aktzeptiert lediglich Einteilungen von berechtigten Spielern]=],
	["<player name>"] = "<Spieler Name>",
	["Player sub-class assignments received from %s"] = "Spieler Unter-Klassen Zuweisung von %s erhalten",
	Ranks = "Ränge",
	["Remote Buff Requests"] = "Stärkungszauberanfragen",
	["Remove all exceptions for this cell"] = "Entferne alle Ausnahmen für diese Zelle",
	sal = "Erl",
	salv = "Erlö",
	salvation = "Erlösung",
	san = "Ref",
	sanc = "Refu",
	sanctuary = "Refugium",
	["%s And these single buffs afterwards:"] = "%s Und diese Einzelstärkungszauber dannach",
	["%s Assigned %s to %s"] = "%s Eingeteilt %s für %s",
	["%s Could not interpret %s"] = "%s Konnte nicht interprätieren %s",
	["Select the guild ranks to include"] = "Wähle die zu beinhaltenden Gildenränge aus",
	Send = "Senden",
	["Send assignments to paladins without ZOMGBuffs or PallyPower via whispers?"] = "Sende Einteilungen zu Paladinen ohne ZOMGBuffs oder PallyPower per Flüsternachricht?",
	["Send Blessings Manager master template to another player"] = "Sende Segen Manager master Vorlage an anderen Spieler",
	["Send Blessings Manager sub-class assignments"] = "Sende Segen Manager Unter-Klassen Einteilungen",
	["Send options"] = "Sendeoptionen",
	["Show Exceptions"] = "Zeige Ausnahmen an",
	["Show first 3 exception icons if any exist for a cell. Note that this option is automatically enabled for cells which do not have a greater blessing defined"] = "Zeige die ersten drei Ausnahmesymbole für jede Zelle (sofern vorhanden). Diese Option ist automatisch für alle Zellen aktiviert, in denen kein großer Segen definiert ist",
	["Single target exception for %s"] = "Einzelne Ausnahmen für %s",
	["%s is offline, template not sent"] = "%s ist offline, Vorlage nicht übermittelt",
	SPLITTITLE = "Klassenaufteilung",
	["%s Remote control of buff settings is not enabled"] = "%s Fremdbestimmung von Stärkungszaubern ist derzeit nicht eingeschaltet",
	["%s %s is not allowed to do that"] = "%s %s hat nicht die Berechtigung das zu tun",
	["%s skipped because no %s present"] = "%s übersprungen, weil keine %s anwesend sind",
	["%s %s, Please use these buff settings:"] = "%s %s, bitte benutze folgende Stärkungszaubereinstellungen",
	["Strip non-existant raid members from the stored sub-class definitions"] = "Entferne nicht-existente Schlachtzugsmitglieder in den gespeicherten Unterklassen Definitionen",
	["Strip non-guildies from the stored sub-class definitions"] = "Entferne nicht-Gildenmitglieder in den gespeicherten Unterklassen Definitionen",
	["Sub-Class Assignments"] = "Unter-Klassen Einteilung",
	["Synchronised group count with %s to %d because of pending blessing assignments"] = "Syncronisiere Gruppenanzahl mit %s zu %d wegen ausstehender Segen Einteilungen",
	["%s You don't get %s from anyone"] = "%s Du bekommst %s von niemandem",
	["%s Your Paladin buffs come from:"] = "%s Deine Paladin Stärkungszauber werden gewirkt von:",
	Tank = "Tank",
	Template = "Vorlage",
	["Template configuration"] = "Vorlagenkonfiguration",
	Templates = "Vorlagen",
	TITLE = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|cFFFFFFFFSegen Manager|r",
	TITLE_CONFIGURE = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|cFFFFFFFFSegen Manager |cFF808080(konfigurieren)|r",
	["Unit exceptions"] = "Einheit Ausnahmen",
	Unlock = "Freischalten",
	["Unlock undetected mod users for editing"] = "Erlaube Benutzern fremder Addons, deine Einstellungen zu ändern",
	["Use Guild Roster"] = "Benutze Mitgliedsliste deiner Gilde",
	["Warning!"] = "Warnung!",
	["Warning: Couldn't assign row %d exception of %s for %s to anyone"] = "Warnung: Ausnahme %s für %s in Zeile %d konnte für niemanden zugewiesen werden",
	["What the hell am I looking at?"] = "Wo zur Hölle schaue ich hin?!",
	Whispers = "Flüsternachrichten",
	wis = "weish.",
	wisdom = "Weisheit",
}

end)
