# Changelog

## v0.8.12

- New: a vendor whose chat window offers only "I would like to buy from you" now opens its shop straight away. Nothing is picked when the chat also has a quest or any other choice, and holding Shift shows the chat window instead. Turn it off in Options > Vendors and mail

## v0.8.11

- New: crests for the window watermark. Pick one from the watermark/emblem list in the Look options: the Horde and Alliance crests, the Alliance lion, Kirin Tor, a Horde symbol, and a crest for every race (Human, Dwarf, Night Elf, Gnome, Draenei, Worgen, Orc, Troll, Tauren, Forsaken, Blood Elf, Goblin, Pandaren). The race and faction crests always show in their own colors
- Fixed: after a /reload in combat the bag window came up with its slots piled in a corner of the screen. The first layout after a load is now done even in combat (and redone when combat ends if the game refuses part of it), instead of waiting until combat is over

## v0.8.10

- The bag window is now an explicitly secure frame, so the bag key can show it in combat. For troubleshooting: /run BaggieDB.keyDebug=true makes the bag key print what it did
- Fixed: bags could not be clicked or opened in combat (seen in dungeons). Baggie kept its window on standby with the mouse switched off, and the game does not let an add-on switch the mouse back on in combat, so the window could appear but its slots did nothing. The bag keys now open and close the window through a secure button that the game allows in combat, and the slots stay clickable. Opening the bags from the bag bar or the minimap button in combat still waits until combat ends. To get the old standby behaviour back: /run BaggieDB.combatSafe=true then /reload

## v0.8.9

- Bankers that ask "Would you rather trust your goods with a goblin?" now open the bank straight away: Baggie picks "I would like to check my deposit box" for you. Hold Shift to see the choices, or turn it off under Vendors and mail

- Fixed make-room never destroying anything: the game blocks add-ons from destroying items from the loot event (it was logged as blocked) while Baggie wrongly said it had. Baggie now asks with a Destroy button, and a click goes through
- Full bags and the loot has a quest item: if no grey item is left, Baggie now destroys the cheapest white or green item to make room (one per quest item). It never destroys rare or better, quest items, bags, saved-spot items or the hearthstone. Turn it off under Vendors and mail

## v0.8.8

- Internal update to the shared window look code. Nothing you will notice changed


## v0.8.7

- Fixed right-clicking items such as copper bars with the bank open not going into the bank: the special-bag step could pick your own carried Reagent Bag or a bank tab you have not bought as its target. It now only looks at real bank bags and bought tabs, and if a move does not go through it hands the click back to the game
- Grey items are now sold automatically when you open a vendor (turn it off under Vendors and mail). It says how many were sold and for how much, skips grey items a vendor will not buy, and never touches white or better items
- The Sell junk button does the same and reports the gold

## v0.8.6

- Redrawn anarchy symbol with a hand-brushed, worn look

## v0.8.5

- New background symbols: sword, crossed swords, shield, sun and paw print
- The background symbol can now be rotated and mirrored

## v0.8.4

- New background symbols: Celtic cross, anarchy, peace sign, skull and crossbones, radiation, atom, infinity, lightning bolt, anchor, Helm of Awe, valknut, Eye of Providence, triskele and fleur-de-lis
- The background symbol can now be moved left, right, up and down, and resized
- Picking a color for a piece of artwork now turns its own-color option on, so the color changes at once

## v0.8.3
- Every piece of artwork (corners, crest, edge pattern, title banner, divider, middle emblem) can now have its own color. New "Your file" emblem slots show your own faction, race and city images from the Media folder.

## v0.8.2
- More emblems: religious, Wiccan, Pagan, Druid, Satanic and occult symbols from many faiths, and the names are tidied.
- The artwork can have a color of its own (Artwork section): corners, crest, edges, banner, divider and the middle emblem.
- The close button in the top right can be restyled (the game's X, boxed, plain, red, filled or hidden) with its own size and color.
- The game-icon emblems (faction crests, race and city icons) are removed; looks that used them show your class emblem.
- Fixed the list preview staying open after a pick; the divider under the title no longer runs through the search row.

## v0.8.1
- Options and Look are now one window with two tabs (top right).
- Emblem list: Pinnacle star, Sunburst, Crown, Crossed swords, Flame and Compass rose; the game's own race sigils and city banners (Stormwind, Orgrimmar and the rest); religious symbols (cross, Celtic cross, Star of David, crescent and star, Wheel of Dharma, yin and yang, ankh, lotus, hamsa, triquetra, torii gate).
- Pointing at an entry in the emblem, corner, crest, edge, banner and divider lists shows a small preview of it.
- The Horde and Alliance crests use the game's round PvP emblem; the title banner is centered with the title.

## v0.8.0
- Gradients: pick both colors, each end's opacity, vertical, horizontal, diagonal, middle-out or center-to-borders, over or instead of the background texture; plus a theme with its own emblem, corners, crest and edge for every talent spec, and a "My spec" automatic theme.
- Look profiles: save your look under a name and switch between saved looks at any time; every character remembers which profile it wears (Look panel, top).
- World of Warcraft flavored art, all optional: nine class themes (Warrior to Druid) with an original emblem, corner pieces, crest and colors for each class, plus a "My class (automatic art)" theme that picks yours; Blue and gold kingdom, Red and iron war camp, Moonlit grove and Plaguelands themes; new spiked corners, horn, crescent and skull crests, and an iron spike edge. The emblem in the middle of the window can also show your class or your talent tree using the game's own icons. Find them in the window options under Colors > Theme and Artwork.
- More optional artwork for the window box: ornament strips along the edges (rope, chain, pearls, runes, vine), a banner behind the title (ribbon, riveted plaque, scroll, jeweled plate), a divider with an ornament under the title, and a faint emblem in the middle of the window (compass rose, shield, laurel wreath, star, runic rings). All in the new Artwork section of the window options; the eight art themes now use them, and the crest sits above the top edge.
- New optional artwork in the window look: seven textured backgrounds (wood planks, aged paper, arcane starfield, runed slate, riveted iron, damask tapestry, dragon scales), five carved corner pieces (filigree, vines, runes, iron plates, arcane sigil), four crests for the top edge (winged, jeweled, scrollwork, crown), and eight ready-made art themes (Arcane library, Dwarven forge, Elven glade, Old tome, Runestone, Royal court, Dragonscale, Oak lodge). Pick them in the window options (Colors > Theme, Background, Border > Corner artwork and Crest). Everything is off until you choose it and syncs between your add-ons like the rest of the look.
- Works completely on its own. If another add-on that draws upgrade arrows on bag items is installed, Baggie shows them; if not, nothing changes and nothing errors.
- Full bags while looting: Baggie now destroys your cheapest grey items to make room, as many as the loot needs, and keeps doing it on every full-bag loot attempt until no grey item is left. Then it puts a trash can on the cheapest white item as a hint (it never destroys white items for you). Both are on by default and each has its own checkbox in Options > Vendors and mail, so you can turn them off.
- Removed the add-on-to-add-on theming hooks and cross-add-on names from the window look code; the shared look sync between your add-ons works the same.
- Escape now always closes the inventory window, whichever way it was opened, instead of opening the game menu.
- The "Pulse the flair" option now also pulses the edge finish (soft, bevel, double line and glow), not just the corner studs.

## v0.7.0
- Baggie now uses the same Look window as your other add-ons for its inventory, bank and guild bank windows: all the colors, backgrounds, textures, border styles and finishes, depth, buttons, fonts and text outline. Your old Baggie colors and borders carry over. Open it from Options > Window look.
- Look sync: the first time your add-ons meet, they now all take on the same look right away instead of waiting for you to change something.

## v0.6.10
- Your custom look is now shared with your other add-ons: change colors, background, border or opacity in one and the rest follow (the newest change wins). It is on by default; untick "Sync my look with my other add-ons" in the options to turn it off.

## v0.6.9
- Fix: the bag window and the bag keys now work in combat. The bag slots are secure buttons, which makes the window protected, so the game refused to show or hide it in a fight. The window now stays on standby (shown, invisible, mouse off) and only fades in or out in combat, and the bag keys click a button of Baggie's own instead of running the game's bag functions. Slots opened for the first time in combat can be seen but not clicked until combat ends. To go back to the old behaviour: /run BaggieDB.combatSafe=false then /reload.
- The minimap button's Alt-click now opens the options (it no longer destroys marked quest items).

## v0.6.8
- Fix: the item tooltip no longer vanishes while you are hovering a bag item. Any bag change (a cooldown, a stat update, loot, a durability tick in a fight) redrew the slots and could drop the tooltip; it now comes right back, in and out of combat. The tooltip is also put back if it disappears on its own while the mouse rests on an item.

## v0.6.7
- Fix: freeing a saved spot no longer makes the item jump. The item is first put into the bag slot it is drawn in, so the window always matches your real bags.

## v0.6.6
- Fix: new loot (auto loot, pickups, deliveries) no longer settles in a slot you saved for a different item. It is moved to the first free slot that is not saved for something else, and the first-free-slot setting now skips saved spots too.

## v0.6.5
- Fix: the Buy tab button in the bank window is no longer hidden behind the window background.

## v0.6.4
- Money display rebuilt: Coin icons now show real gold, silver and copper pictures (before they looked the same as the colored letters). New: plain white letters, gold and silver only, short numbers (12.3k), options to hide silver or copper, and a thousands separator.
- Fonts: the font pack now ships inside Baggie (over 100 fonts) for the title, counts and bottom line.
- Colors: the slot options only show what applies to the chosen slot style (flat color, gradient or tile), the textured tiles show their texture instead of a flat grey, and your own color changes are no longer overwritten at every login by GreedUI. GreedUI's look is applied when its theme changes.
- Bank: the game blocks add-ons from buying a bank tab, so Buy tab now opens the game's own bank window for the purchase and hides it again afterwards.

## v0.6.3
- Fix: characters with two-part names no longer share saved slots with each other.
- New: items you cannot use or equip get a red tint (Options > Slots and text).
- New: ammo stays in your quiver or ammo pouch; strays are moved back out of combat.
- Fix: divider line, search box and toggle buttons in the bag window.
- New: /issues log of problems.

## v0.6.2
- New: a yellow ! in the middle of any item that starts a quest (the kind you right-click to accept), so you can tell you have not used it yet. It disappears once the quest is accepted. Works in the bags, bank and guild bank; turn it off under Item glows ("Yellow ! in the middle of items that start a quest").
- New: "Gray out grey items" (Options > Slots and text, on by default) takes the color out of grey-quality icons in the bags, bank and guild bank. "Dim grey items" still fades them separately; use either or both.
- New glow sliders (Options > Item glows): "Item quality glow brightness" (separate from the quest and new-item glow brightness) and "Glow size", which sets how far every glow reaches past the slot. Both apply to the bags, bank and guild bank.

## v0.6.1
- Glow: when a new quest item (or quest starter, currency or high-quality item) is moused over, the green new-item glow goes away and its own glow takes over right away instead of leaving the item with none.

## v0.6.0
- Quest item cleanup: Shift+Alt+click a quest item to mark it (small red cross), then Alt+click the minimap button or type /baggie toss to destroy the marked ones. Reads the game's own quest log and keeps anything a quest in it could want (Questie, if you have it, adds a second check); keeps everything if it can't read the log; checks again just before each item goes and asks you to confirm first.
- Item glows: separate switch and color for quest items, quest starters and currencies (Blood Shard and the like no longer glow as quest items unless you turn that on).
- Saved spots: one item can be saved to several spots, new items go to the first free cell, and the padlock shows only on the stack in its saved spot. The bank follows the same rules and has quick-deposit from your bags (Ctrl+Alt+click, or the Deposit menu).
- Bank: one Deposit button with a menu instead of five buttons; Escape now properly ends the banker conversation; no phantom slots before a bank tab is bought, with a Buy tab button.
- The gold and slot-count line at the bottom now sits on its own top layer, so nothing in the window can cover it.
- New-item glow now only marks items that came into your bags from outside (loot, mail, bank, vendor, trade). Moving or swapping items inside the bags no longer lights them up.
- Characters window (shift-click the minimap button): delete a character's saved spots, and deleted characters are spotted and removed automatically.

## v0.5.1
- Bank: your own Reagent Bag no longer shows up in the bank window.
- Bank: bank tabs you haven't unlocked yet are no longer drawn as if they were open slots.

## v0.4.0
- The Options window is redesigned: a flatter, cleaner look, sections you can collapse, and three tabs. **Inventory** is your bags, **Bank** and **Guild Bank** each have their own tab. A "Sync all windows" switch at the top makes the bank and guild bank follow the Inventory look; turn it off and each window keeps its own colors, textures, opacity, borders, text and glows. Slot size, spacing, padding and slots per row are always set per window.
- Sorting the bank no longer fights special bags: Baggie checks each bag's type more carefully, and if the game ever says an item doesn't fit a bag, the sort stops and puts the item back instead of repeating the error.
- The bank and the guild bank now open as Baggie windows: same look, search, junk dimming, item level and glows as your bags, with your bank bags in one window, a bag-slot row and a Buy bag slot button; the guild bank has its tabs plus Deposit and Withdraw. Slots per row is adjustable. The bank and guild bank windows have Sort buttons (the bank sorts all bank bags, the guild bank sorts the current tab if you have the rights), more room between slots (adjustable), and each bank bag starts on its own row. The guild bank also shows the game's "no permission" message. If anything goes wrong, the game's own bank window is put back, and Options can turn each replacement off.
- Window background: six new textures (leather, stone, linen, carbon fiber, brushed metal, a light-to-dark fade), a Custom texture choice that takes any file path or a SharedMedia background name, and an option to show textures in their own colors instead of tinted.
- Opacity: the window opacity slider now goes down to fully clear, and the border and title bar have their own opacity sliders.
- Every color has a hex box (for example #E0B04A): copy it with Ctrl+C or paste one from another add-on with Ctrl+V and press Enter. It also reads three numbers such as 224 176 74.
- Minimap button: click to open or close your bags, right-click for options, drag to move it. The Options button is gone from the bag window (`/baggie options` still works, and `/baggie minimap` hides or shows the button).
- Much more customization in Options: window background texture (solid, dark panel, parchment, marble, rock, tooltip), window border style and thickness, optional title bar, title text, size and font, slot background style and opacity, trimmed icon edges, fonts, stack count and item level size and corner, item level colored by quality, grey item opacity, saved-spot mark color and size, and four more themes (Ember, Void purple, Frost, Black and white).
- Item glows (Options > Item glows): quest items, and items that start a quest, glow gold in your bags so you can spot them at a glance. Optional glows for high-quality items (choose the quality it starts at) and for new arrivals, which glow until you point at them. A brightness slider controls all of them.

## v0.3.0
- New option "New items go to the first free slot" (on by default): when loot or a purchase arrives, only that item is moved into the first empty slot, so no gaps open up at the front on their own. Nothing else is ever touched, and anything you move yourself stays put. Gaps you leave are filled by the next new item.
- Baggie no longer sorts or moves anything on its own: the layout is plain bag order and new items land wherever the game puts them. The Sort button now uses Baggie's own sort instead of the game's (which left gaps): it only runs when you click it and packs everything to the front, grouped by type, quality, then name. Quivers and special bags are left alone. Items you saved to a spot stay in that spot; everything else is packed around them.
- New layout "Bag order, new items fill gaps" (Options, or `/baggie layout gaps`): every slot stays where it is, but a new item shows in the top-most empty cell instead of wherever the game put it. Nothing is pushed to the front and nothing physically moves. Items you move yourself are left alone.

## v0.2.10
- Baggie is now on Wago Addons, so the Wago app can install and update it.

## v0.2.8
- Right-click use of items that cast a spell (Lesser Astral Essence, soul stones, grimoires) was still blocked. Baggie no longer replaces the game's bag functions (ToggleBackpack, OpenAllBags and the rest); it hooks them instead and moves the default bag windows out of sight, the way other bag addons do.

## v0.2.7
- Windows no longer bleed through each other: clicking the Baggie window or its options raises the whole window above other addon windows.

## v0.2.6
- Fixed the stack count showing twice (one on top of the other); the item buttons now only show Baggie's own count.

## v0.2.5
- Right-clicking a soul stone or grimoire (items that cast a spell) could still show the "blocked from an action only available to the Blizzard UI" message. Baggie now builds its item buttons the same way the game's own bags do, and the message names what was blocked.

## v0.2.4
- Real cause of items jumping after a drop: a saved spot swaps places with the slot in its cell, and if you dropped an item into that swapped-in cell Baggie moved it to the last free cell on the next refresh. Swaps are now plain swaps, so a dropped item stays where you put it.
- Right-clicking items (recipes, food, anything usable) in Baggie could trigger the game's "blocked from an action only available to the Blizzard UI" message. Baggie no longer attaches anything to the game's item buttons beyond drawing them.

## v0.2.3
- Fixes the bag row saying your bag slots are empty: newer game versions moved the bag-slot lookup, so Baggie now uses the new one and falls back to the standard slot numbers.
- A "Search:" label sits next to the search box.

## v0.2.2
- The reagent bag and the keyring now sit in their own labeled sections under your main bags, kept apart from the backpack and bag slots. Options: "Show reagent bag", "Show keyring" and "Label and separate those sections".
- The bag row also shows the reagent bag slot (set apart from the others) on games that have one.
- Saved spots apply to the main bags only.

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
