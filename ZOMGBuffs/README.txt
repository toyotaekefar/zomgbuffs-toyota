ZOMGBuffs
Zek <Bloodhoof-EU>

ZOMGBuffs
All in one buffing mod for all classes. Paladin buff generated assignments based on Paladin capabilities and raid member sub-classes (druid tank vs. druid healer etc.). Plus overview of important raid buffs, and instant access rebuff on right click.

Main Mod
- Responsible for loading class specific modules.
- Has FuBar/Minimap icon for options menu (Sorry, I just don't like Waterfall at all), and info tooltip.
- Single click minimap icon to quickly enable/disable auto-buffing.
- Raid popup list with complete buff overview (just mouseover the floating ZOMG icon).
  + Highlights missing buffs for whole raid at a glance.
  + Shows time remaining on your buffs on whole raid.
  + Allows instant rebuff with Right-Click as assigned by seperately loaded modules, without having to muck around finding the player in the raid frames.
  + Shows in-combat reminder (swirly thing around icon) if someone needs a rebuff mid-fight.
- Auto Buy reagents to defined levels.

ZOMGSelfBuffs
- Handles all self buffing needs including temporary weapon enchants and poisons.
- Can remind you in-combat when something needs rebuffing.
- Special cases to auto buff Crusader Aura for paladins when mounted, and aspect of cheetah for hunters in cities.

ZOMGBlessings
- Remembers buffs assigned per class.
- Remembers single buffs done after class buffs, and will repeat this as required.
- Single exception icons can be shown when you enter combat to show a constant reminder during long fights for those that have single buffs. A simple click will rebuff them.
- You can either set blessings up via the Blessings Manager, or use the minimap tooltip dropdown to cycle buffs, or you can simeple buff someone from your action bars and that buff will be remembered for that target, whether that's class or single buffs.

ZOMGBlessingsManager
- Auto Generate buff assignments based on a defined template, with facility to divide players into sub-classes (tank vs. dps warrior, healer vs tank druid etc.). Click the Configure button in the manager to show the global template, and click the Help button for more information on this.
  Generated buff assignments will try to:
  + Allocate Might and Wisdom to paladins with improved versions.
  + Assign the same buff to a paladin where possible, for clarity when viewing the manager and when people ask "Who's doing XXX".
- Change buffing assignments (group and single) of any paladin via the manager on the fly.
- Interfaces seamlessly with users of PallyPower allowing them to benefit from the auto-generated templates. Note that PallyPower uses slightly different rules for who may set blessings and generally they need to be promoted in raid.
- Chat interface (Default is disabled) which allows any player to query who is buffing them with what. Whisper triggers: !buff and !zomg - Both the same.
- Chat responder can be accessed from anyone who is running the Blessings Manager and is either a Paladin, a Raid Leader or a Raid Assistant.
- Remote chat lets players change what they're being buffed.
  Examples:
    !buff                       - Show what I'm being buffed with.
    !buff ?                     - Show help
    !buff -bok +bom             - I want BOM instead of BOK
    !buff -light +kings         - I want Kings instead of Light.
- Alt-Click minimap icon to accessing Blessings Manager quickly.

At first glance the Manager is a lot to take in, but don't be afraid. Just try to think of it as two seperate windows.

In configure mode, the rows have absolutely nothing to do with any paladins you may or may not have in the raid. But rather, the first row is what you want when you have 1 paladin, two rows for when you have two palas and so on. So you setup the priority for buffs from row 1 down to row 6. The default should suit most people, but tastes vary.

Some of the classes expand into multiple colums as their header suggests for different sub-classes with their own buff priority order.

Then, back in normal mode, you have say 2 palas and you click generate and it'll pick off the first two rows of the configured template (if a buff is not doable, say you had sanctuary on row 2 and noone can do it, then 3rd buff is picked out).

These buffs are then applied to the paladins in raid on a best fit basis. First kings and sanctuary are given out, then imp wis and imp might. The remainder are filled in with the preference to keep buffs on the same row where possible.

Any single exceptions are then done, based on who you put into which subclasses. Note that the most dominant sub-class is picked to do the group buff for any class, to limit the number of single casts as much as possible. Group buffs are kept wherever possible, so it doen't matter that kings is group buffed on priority row 1, and playerX needs kings as a single exception on row 2. It'll see that and put their exception on the other buff which is not common.

ZOMGBuffTehRaid
- Group class buffing module for Mages, Priests, Druids, Shamans and Warlocks.
- Allows you to define which groups you're responsible for.
- Enable or Disable buffs by clicking on the minimap tooltip for that buff.
- Single target (non group buffs) can be enabled on a per-person basis by tickboxes in the raid popup list.
  + Click to toggle one player.
  + Right-Click to toggle everyone.
  + Alt-Click to toggle class.
  + Shift-Click to toggle party.
- Tracking Icon for Fear Ward and Earthen Shield. Showing time left and stack count when applicable, and allowing easy click rebuff.

Common Behaviour for Buffing modules
- Manually casting a buff will be remembered (with a few exceptions which shouldn't) as the new required auto buff.
- Click the tooltip sectoin for that mod will cycle through buffs.
- Shift Clicking the tooltip section for that mod will remove it's entry from the template.
- Template save/load/conditionals.
- Simple mousewheel rebuffing in one common interface.
- Simple Right-Click rebuffing of your defined buffs for whichever module you have loaded
- Definable pre-expiry rebuff setting.
- Options to auto-learn in or out of combat. Auto learn means that if you cast a spell, then it'll assume you want this from now on and rebuff as needed.
- Options to not buff when:
  + Not everyone in raid is present (definable to a % of people present).
  + Not everyone in a party is present.
  + You are resting.
  + You are low on mana.
  + You have the Spirit Tap buff (geiv mana regen!).
  + You are stealthed.
  + You are shapeshifted.
