# 07 · Test plan

## What has actually been verified
| Check | Tool | Result |
|---|---|---|
| Every `.luau` file compiles | `lune run tests/check_build.luau` (Luau compiler in Lune 0.10.5) | ✅ 60 files |
| Rojo builds the place and the Explorer layout and classes are right | `rojo build` (7.7.1) + Lune place inspection | ✅ |
| Lint with Roblox API definitions | `selene src tests` (0.31.0, std generated from the current Roblox API dump) | ✅ 0 errors, 0 warnings |
| Formatting | `stylua --check` (2.6.0) | ✅ |
| Content consistency (ids, graph, flags, events, anchors) | `01_content` | ✅ |
| System unit tests (conditions, rules, dialogue, gifts, minigames, saves, world) | `02_systems` | ✅ |
| Full-story simulations for every ending, friendship edition, 60 random players, JSON save round-trip after **every** action | `03_playthrough` | ✅ |
| Server integration with mocked Roblox services (vertical slice through requests, validation, rate limit, leave/rejoin across servers, session locks, save failures, autosave, shutdown flush, reach triggers, two players per server) | `04_server` | ✅ |
| **Anything inside Roblox Studio or on a device** | — | ❌ **Not run**: no Studio access in this environment |

Run all of it with:
```
lune run tests/run.luau && rojo build default.project.json -o build/Hearthscale.rbxlx && lune run tests/check_build.luau && selene src tests && stylua --check src tests
```

## Manual Studio test plan (to do)
Test on **desktop (keyboard and mouse)**, **phone** (Studio device emulator plus a real device), **tablet** and **gamepad**. Enable *Studio Access to API Services* for the save tests.

### A · Boot and HUD
- [ ] Output shows `server ready`, with no `[Hearthscale content]` warnings and no script errors (server or client).
- [ ] The placeholder village is built and you spawn near the Keeping House.
- [ ] The intro plays on a new story, can be skipped with tap, Space or A, and doesn't replay after rejoining.
- [ ] The objective card shows Chapter 1. Tapping it opens the Journal.
- [ ] The HUD buttons work (tap and click) and the hotkeys J, B, K, P work. Gamepad: D-pad opens menus, B closes them.
- [ ] Phone: nothing overlaps the Roblox top bar, thumbstick or jump button; text is readable; panels scroll.

### B · Dialogue
- [ ] Prompt "Talk · Saffron" appears near her (E / X / tap). A "!" marks pending story scenes.
- [ ] Typewriter text can be skipped; Space, Enter or A continues; 1–4 pick choices; gamepad selection works.
- [ ] Movement and jump are locked during dialogue; the camera frames Saffron (unless reduce motion or cinematic camera is off).
- [ ] Emotes visibly change the face, tail, smoke and blush on the placeholder.
- [ ] ✕ mid-scene leaves without changing anything (the scene can be replayed). ✕ on the last line counts as finished.
- [ ] Locked romance choices show grey with their hint (romance edition only).

### C · Vertical slice and persistence
- [ ] Complete Chapter 1 as described in [04-Setup.md](04-Setup.md#vertical-slice-walkthrough-about-10-minutes).
- [ ] Sorting game: tap and keys work, the timer runs, results appear, and Saffron's line plays.
- [ ] Assistant Keeper banner appears; the Bond screen shows the checklist for Friend.
- [ ] **Stop and Play again:** progress, inventory, milestone and settings are kept; the HUD shows "Saved ✓" after changes.
- [ ] Turn API access off: the game still runs and the HUD shows "Studio test mode · not saved".
- [ ] Two-player test (*Clients and Servers*): each client sees Saffron at their own station, and one player's scenes or gifts never affect the other.

### D · Chapter 2
- [ ] The Mayor is in the square. Glowcaps appear only during that step, the waypoint points to the nearest, and the counter goes up to 5.
- [ ] Fishing: the timing bar is responsive on touch, mouse, Space and A.
- [ ] Pond heart-to-heart → Friend milestone (when stats allow). Name tokens switch to "Saffron".
- [ ] Old Bridge: the reach trigger fires on the cliff top, and the full or partial story depends on trust.
- [ ] Gifts: refused at Stranger; one per progress beat; repeated items give smaller reactions; the Fire Starter upsets her.

### E · Chapter 3
- [ ] Hoard clues spawn inside the Keeping House, then the lantern appears.
- [ ] The night sky changes for Stargazer Hill. Fireflies: walking into a mote collects it (the server checks distance) and Finish works.
- [ ] Romance edition: the confession choice is locked until Confidant with trust 40.

### F · Chapter 4
- [ ] Cinderra appears in the square (and not earlier). Lantern runes: the pattern is visible and input works on all devices.
- [ ] "What are we?": verify all three of Saffron's answers (accept, decline, too soon) by adjusting stats in the server view.

### G · Finale and endings
- [ ] The trail is climbable on all devices, and the summit reach trigger fires.
- [ ] Each of the four endings can be reached; the ending card shows after dialogue closes.
- [ ] The Hearthflame changes brightness by chapter and ending.
- [ ] Endings gallery lets you read endings again; *New story* restarts with the intro and keeps the gallery.
- [ ] Friendship edition (`RomanceEnabled = false`): no ♥ choices, no Sweethearts milestone, no romance ending.

### H · Robustness
- [ ] Spam-click prompts and buttons: no duplicated rewards and no stuck UI.
- [ ] Leave mid-minigame or mid-dialogue, then rejoin: no partial rewards and the story is still progressable.
- [ ] Throttle the network (Studio settings): UI waits for responses and nothing double-submits.
- [ ] Memory and frame time are acceptable on a low-end phone (the placeholder map is roughly 500 parts).
