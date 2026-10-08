# Baggie

One bag window for WoW: Forever where **you choose where items sit**.

Your backpack and bags open in a single window. Save an item to a spot and it stays in that spot: when you use it up, the spot stays reserved (shown as a faded icon), and the next one you pick up goes right back to it.

## Saving an item to a spot

- **Alt+click** an item, then **Alt+click** the cell where it should sit.
- Or press the **Pin** button, click an item, then click its spot. Click Pin again to leave pin mode.
- **Alt+right-click** a saved cell (or right-click in pin mode) to free it.
- Dropping an item on a faded spot puts it in your first empty bag slot, and it shows up in the saved spot.
- A small gold mark on an item means it has a saved spot. Spots are saved per character, by item (so every stack of Hearthstone lands in the same cell).

Spots are virtual. Baggie never moves anything in your real bags, so it is instant and safe. If saved spots would push a real item off the bottom of the window, the window grows by a row so nothing is ever hidden.

## Also

- Search box: dims everything that does not match a name or item type.
- Quality borders, dimmed grey junk, cooldowns, free slot counter, money.
- Sort button (uses the game's own bag sort).
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
| `/baggie reset` | Put the window back at its default position |

MIT licensed.
