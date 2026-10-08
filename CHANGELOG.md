# Changelog

## v0.2.1
- Theme, border style, layout, gold and counter choices are dropdown menus instead of buttons you click through.
- New "Show bags" option: a row under your items showing your equipped bag slots. Click a slot to pick up the bag, or drop a bag on it to equip it.
- Keyring: Baggie now also asks the game's keyring size and says so when the character has no keyring slots. `/baggie debug` prints the keyring numbers.

## v0.2.0
- Look customizer: theme presets (dark gold, midnight blue, slate, forest, crimson, parchment) plus color pickers for the window background, border and title, title bar, slot background and item borders.
- Item borders: by quality (with a minimum quality), one custom color on items, one color on every slot, or none; adjustable thickness. Crisp pixel borders replace the old glow.
- Sizes: slot size, icon padding inside slots, space between slots, window padding.
- Bottom line: choose how gold shows (coin icons, colored g/s/c, gold only, hidden), how the slot counter shows (used / total, free of total, free only, hidden) and its text size.
- The Pin button is gone. Alt+click an item saves its spot, Alt+click again frees it.

## v0.1.7
- Saving is one click now: Alt+click an item and it is saved to the spot it is sitting in. Alt+click it again (or its empty spot) to free it. The Pin button works the same without Alt. No more picking a target cell.

## v0.1.6
- Saving an item only works on an empty slot now. Clicking a slot that already holds another item is refused with a message, so saving never shuffles your other items around.

## v0.1.5
- Stops the blue glow on slots after /reload. That was the game's own "new item" glow from its button template; Baggie now silences all of the template's glows and draws only its own.

## v0.1.4
- Fixes the "Baggie has been blocked from an action only available to the Blizzard UI" popup. Baggie no longer replaces the click and drag scripts on the game's item buttons (that tainted using and equipping items); Alt+click and Pin mode now use a transparent overlay of Baggie's own.
- If the game blocks something anyway, Baggie prints which action it was.

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
