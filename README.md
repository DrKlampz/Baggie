# Baggie

One bag window for WoW: Forever where **you choose where items sit**.

Your backpack and bags open in a single window. Save an item to a spot and it stays in that spot: when you use it up, the spot stays reserved (shown as a faded icon), and the next one you pick up goes right back to it.

## Saving an item to a spot

- **Alt+click** an item to save it to the spot it is in. Alt+click it again to free the spot.
- Dropping an item on a faded spot puts it in your first empty bag slot, and it shows up in the saved spot.
- A small gold mark on an item means it has a saved spot. Spots are saved per character, by item (so every stack of Hearthstone lands in the same cell).

Spots are virtual. Baggie never moves anything in your real bags, so it is instant and safe. If saved spots would push a real item off the bottom of the window, the window grows by a row so nothing is ever hidden.

## Bank

The bank and guild bank open as Baggie windows too, with the same saved spots. A **Deposit** button opens a menu of quick deposits from your bags (or Ctrl+Alt+click an item). On a character that has not bought a bank tab yet, the window says so and shows a **Buy tab** button with the price. Escape closes the bank and ends the banker conversation properly.

## Quest item cleanup

Shift+Alt+click a quest item to mark it with a small red cross. Alt+click the minimap button (or type `/baggie toss`) to destroy the marked items. Baggie reads the game's own quest log and keeps anything a quest you have could still want (Questie, if installed, adds a second check). If it cannot read the log it keeps everything, it checks again just before each item goes, and it asks you to confirm first. `/baggie toss list` shows the marks and `/baggie toss clear` removes them.

## Glows

New items, quest items, quest starters and currencies each have their own glow switch and color under `/baggie options`. Currencies that the game files as quest items (Blood Shard and the like) only glow if you turn that on. New-item glow only marks items that came in from outside (loot, mail, bank, vendor, trade). Items that start a quest also get a yellow ! in the middle of the slot until you accept the quest (optional). Quality glows have their own brightness slider, and one more sets how far all the glows reach past the slot.

## Also

- Search box: dims everything that does not match a name or item type.
- Quality borders, dimmed grey junk, cooldowns, free slot counter, money.
- Sort button (manual only, uses the game's own bag sort). Bags never rearrange on their own.
- Options window (`/baggie options`): themes and color pickers for the window, title bar, slots and borders; border style and thickness; slot size, spacing and padding; gold and slot-counter display; item level; vendor helpers and more. Backgrounds, borders, fonts, glows and text positions are all adjustable. Right-click the minimap button for the options. The bank and guild bank open as Baggie windows too. Window backgrounds include textures and a custom texture path, every color can be copied and pasted as a hex code, and opacity is adjustable for the window, border and title bar.
- When **Follow GreedUI** is enabled, its look is applied only while Baggie draws its windows. Your Baggie settings and profiles are not rewritten; turn sync off to immediately restore Baggie's saved appearance.
- Replaces the default bag windows and the bag keys (B, F12 etc.). `/baggie default` gives the default bags back.

## Commands

| Command | What it does |
|---|---|
| `/baggie` | Open or close the bags |
| `/baggie pins` | List saved spots |
| `/baggie unpin all` | Free every saved spot |
| `/baggie cols 4-24` | Cells per row |
| `/baggie scale 0.6-1.6` | Window size |
| `/baggie borders` | Quality borders on or off |
| `/baggie keyring` | Show or hide the keyring |
| `/baggie default` | Switch between Baggie and the default bags |
| `/baggie toss [list|clear]` | Destroy marked quest items, list or clear the marks |
| `/baggie reset` | Put the window back at its default position |

MIT licensed.
