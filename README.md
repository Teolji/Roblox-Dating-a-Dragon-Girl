# Hearthscale: A Kettlewick Story

A cozy, funny, story-driven Roblox game about the friendship (and, in the 18+ edition, possible romance) between you and **Saffron Ignavarre**, a proud fire dragon who runs a village Lost & Found and hasn't breathed real fire in eight years.

> Your balloon crashes through her roof. She logs you as lost property: **Item #4112**. Before Lanternfall night, the two of you will decide what kind of flame you'll keep.

**Read first: [docs/01-Compliance.md](docs/01-Compliance.md).** Roblox only allows romantic themes in experiences labelled **Restricted** (age-verified 18+). The project therefore has a one-line switch, `Config.RomanceEnabled`, that produces an all-ages **friendship edition** which is still a complete story.

## What's in the box
| | |
|---|---|
| **Story** | 5 chapters plus an epilogue, 11 quests, 33 conversations (315 dialogue nodes, ~6,300 words), 4 endings (romance, friendship, bittersweet, low-trust) |
| **Characters** | Saffron (the dragon: personal goals, flaws, boundaries, can say no); Mabel, Pim, Wren and Cinderra |
| **Relationship** | Trust / Affinity / Romance / Her Resolve. Five milestones that never regress, with a live checklist for the next one. Choices remembered across chapters |
| **Gifts** | Character-specific tiers and reactions; one gift per adventure; diminishing repeats; soft caps, so there's no gift grinding |
| **Activities** | Sorting the hoard, pond fishing, firefly catching (in the world), lantern-rune memory, the Hearthflame finale. All scored on the server |
| **UI** | Objective card and waypoint, dialogue box, journal (quests, story, what you know about Saffron, endings gallery), bag with gift mode, bond screen, settings (text speed, volume, UI size, reduce motion, …), toasts, chapter cards |
| **Controls** | Touch, keyboard and mouse, gamepad |
| **Saves** | DataStore with session locking, retries, autosave, shutdown flush, graceful failure (play continues, nothing overwritten), schema sanitising and migrations |
| **Multiplayer safety** | Each player's story, NPC placement, pickups and sky are local to them. There are no player-to-player romance features |

## Quick start
```bash
rokit install                                   # rojo, lune, selene, stylua (pinned in rokit.toml)
rojo build default.project.json -o Hearthscale.rbxlx
# open Hearthscale.rbxlx in Roblox Studio → Game Settings → Security →
# enable "Studio Access to API Services" → Play
```
No tools? Copy the files into Studio by hand. **Exact Explorer locations and step-by-step assembly:** [docs/04-Setup.md](docs/04-Setup.md).

## Status (honest)
| | |
|---|---|
| ✅ Implemented and automatically tested | Story engine, all content, server request handling, saving and session locks, every ending reachable, no soft-locks (60 random simulated players), friendship edition, leave and rejoin persistence (server code run under Lune with mocked Roblox services) |
| 🧪 Written but **not run in Roblox Studio** | All client code (UI, camera, input, NPC rigs, minigame screens) and the placeholder world. It compiles, lints clean against the Roblox API, and Rojo builds the place, but nobody has played it in Studio yet. See [docs/07-TestPlan.md](docs/07-TestPlan.md) |
| 🟨 Placeholders | Character models (procedural block figures with horns and tails), animations (procedural), map (blockout), icons (emoji), portraits (initials), **no audio**. See [docs/05-Assets.md](docs/05-Assets.md) |
| ⬜ Future | Art and audio pass, Studio and device QA, balancing from playtests, side stories, localisation. See [docs/03-Roadmap.md](docs/03-Roadmap.md) |

## Documentation
1. [Compliance: Roblox rules on romance, and the changes they required](docs/01-Compliance.md)
2. [Game design](docs/02-GameDesign.md)
3. [Production roadmap, stages, tuning notes](docs/03-Roadmap.md)
4. [Setup: Explorer locations, assembly, publishing](docs/04-Setup.md)
5. [Assets: required models, animations, audio; placeholder list](docs/05-Assets.md)
6. [Authoring guide: dialogue, quests, items, activities, endings as data](docs/06-Authoring.md)
7. [Test plan: what's verified, and the manual Studio checklist](docs/07-TestPlan.md)

## Repository layout
```
src/shared   → ReplicatedStorage.Hearthscale            Config, Content (all story data), Systems (pure Luau engine), Util
src/server   → ServerScriptService.HearthscaleServer    Main + DataService, GameService, WorldBuilder
src/client   → StarterPlayerScripts.HearthscaleClient   Main + Controllers (NPCs, world, camera, input) + UI
tests/       → Lune test suite (content validation, unit tests, playthrough sims, server integration)
docs/        → design and production documents
```

## Checks
```bash
lune run tests/run.luau             # 54 tests
lune run tests/check_build.luau     # compile every script, inspect the built place
selene src tests && stylua --check src tests
```
