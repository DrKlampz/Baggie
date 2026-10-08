# Changelog

## v0.1.3
- Saving an item to a spot now reserves that spot. Whatever was sitting there is bumped to a free cell (your old spot is left empty), and Baggie never swaps two items around.
- Trying to save onto a spot already saved for another item is refused with a message; Alt+right-click that spot to free it first.

## v0.1.2
- Nothing sorts itself any more. Items now sit in real bag order by default; a saved spot just swaps its item into place. The old items-first packing is still there as the "Compact" layout option.
- New options window (`/baggie options` or the Options button): layout, columns, slot size, scale, background opacity, quality borders, grey dimming, item level on gear, keyring, saved-spot mark and empty-spot opacity, share saved spots across characters, search box / footer / sort button toggles, lock position, open at vendor / mail / bank / auction house, Sell junk button, optional auto-sell of grey items (off by default).
- `/baggie layout real|compact`.

## v0.1.1
- Items draw with Baggie's own icon, count and slot background instead of relying on the game's item button template, and /baggie debug prints what Baggie sees.

## v0.1.0
- First release: one window for the backpack and bags, with saved spots. Alt+click an item then a cell to save it there; spots stay reserved when the item runs out.
- Search, quality borders, cooldowns, junk dimming, free slot counter, money, sort button.
- Replaces the default bag windows and bag keys; `/baggie default` brings them back.
