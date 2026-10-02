# In Character Forever

This is the **WoW Forever** edition of [Blackacre: In Character](https://github.com/khallammarellus-rgb/blackacre-in-character) Designed to be a journal and RPG enhancing add on for WoW roleplay. This is the foundational add on for its extensions
A WoW add-on for in-character, immersive roleplay.

**Version:** 2.0.0-dev
**Target:** WoW Forever
**Repo:** https://github.com/khallammarellus-rgb/blackacre-in-character-forever · Retail sibling: https://github.com/khallammarellus-rgb/blackacre-in-character

---

## Install

1. Download the latest release zip, or on GitHub use **Code → Download ZIP**.
2. Copy these four folders into your WoW Forever `Interface\AddOns` folder:
   `Blackacre`, `Blackacre_Tome`, `Blackacre_Survival`, `Blackacre_Presence`.
   (In a GitHub ZIP they sit inside the `blackacre-in-character-forever-main` folder; copy the four folders, not that outer folder.)
3. Character select → AddOns → enable the **In Character Forever** group → `/reload`.

## Player Maintenance
Data is saved under SavedVariables per profile generated.

Slash aliases: **`/ba`**, **`/blackacre`**, and legacy **`/ic`**.

---

## Slash commands

| Command | Description |
|---|---|
| `/ba` | Tool Box (beacon, seeking, bulletins) |
| `/ba journal` | Open your journal |
| `/ba quests` | Quest Index: every quest you've taken up and finished |
| `/ba config` | Settings |
| `/ba voice` | Settings → Voice |
| `/ba honor` | Settings → Survival honor rules |
| `/ba survival` | Condition meters |
| `/ba eat` / `drink` / `rest` | Survival recovery |
| `/ba beacon` / `/ba bulletin` | Emit a beacon / post a bulletin |
| `/ba export profile` | Full profile backup |
| `/ba packages` | Loaded add-ons + version |

---

## Legal

World of Warcraft © Blizzard Entertainment. This is a fan add-on, not affiliated with Blizzard.

## License

The add-on's own code and text are released under the [MIT License](LICENSE). That covers only this project's work: Warcraft names and lore belong to Blizzard, and the bundled libraries and fonts keep their own licenses (see `Blackacre/Libs/LICENSES.txt` and `Blackacre/Media/Fonts/FONTS.txt`).

Found a bug? Open an issue on this repository. The in-game report window (Shift+Right-click the minimap button) fills in the details for you.

## Credits

Full credits are in-game under Settings → Credits. Thanks also to the Texture Atlas Viewer add-on developer for making the visuals entirely possible. Claude IDE extensions used in VS code to run lua checkers and assist.
