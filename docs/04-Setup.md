# 04 · Setup: Explorer locations, assembly and publishing

Use **Option A (Rojo)** if you can install tools; it's one command. **Option B (manual)** needs only Roblox Studio. Both produce the same Explorer tree.

## Explorer locations (exact)

```
ReplicatedStorage
└─ Hearthscale                       Folder          ← src/shared
   ├─ Config                         ModuleScript    (edition switch, tuning, asset ids)
   ├─ Net                            ModuleScript    (remote names)
   ├─ WorldAnchors                   ModuleScript    (anchor name → CFrame)
   ├─ Content                        ModuleScript    ← Content/init.luau
   │  ├─ Activities                  ModuleScript
   │  ├─ Characters                  ModuleScript
   │  ├─ Endings                     ModuleScript
   │  ├─ Items                       ModuleScript
   │  ├─ Milestones                  ModuleScript
   │  ├─ Quests                      ModuleScript
   │  ├─ Story                       ModuleScript    (chapters, story rules, notes)
   │  ├─ World                       ModuleScript    (anchors, collectibles, locations)
   │  └─ Dialogue                    ModuleScript    ← Dialogue/init.luau
   │     ├─ SaffronStory             ModuleScript
   │     ├─ SaffronHub               ModuleScript
   │     └─ Villagers                ModuleScript
   ├─ Systems                        Folder
   │  ├─ Activities, Conditions, ContentValidator, Dialogue,
   │  │  Gifts, Minigames, Rules, SaveSchema, World           (ModuleScripts)
   └─ Util                           Folder
      └─ Prng, Signal, Tables                                  (ModuleScripts)
   (Remotes                          Folder — created at runtime by the server)

ServerScriptService
└─ HearthscaleServer                 Folder          ← src/server
   ├─ Main                           Script          ← Main.server.luau
   └─ Services                       Folder
      ├─ DataService                 ModuleScript
      ├─ GameService                 ModuleScript
      └─ WorldBuilder                ModuleScript

StarterPlayer
└─ StarterPlayerScripts
   └─ HearthscaleClient              Folder          ← src/client
      ├─ Main                        LocalScript     ← Main.client.luau
      ├─ Controllers                 Folder
      │  └─ Ambience, Audio, CameraController, Expressions, Input,
      │     NPCController, Objectives, PlaceholderRig, Session,
      │     Waypoint, WorldObjects                              (ModuleScripts)
      └─ UI                          Folder
         ├─ BondUI, DialogueUI, EndingUI, HUD, IntroUI, InventoryUI,
         │  JournalUI, Root, SettingsUI, Theme, Toasts          (ModuleScripts)
         └─ Minigames                Folder
            └─ CollectGame, MinigameHost, SequenceGame,
               SortGame, TimingGame                             (ModuleScripts)

Workspace (built at runtime if missing)
└─ HearthscaleWorld                  Folder   (placeholder blockout map)
   ├─ Anchors                        Model    ModelStreamingMode = Persistent
   └─ Beacon                         Model    Persistent (the Hearthflame)

Optional art (you add later)
ReplicatedStorage
└─ HearthscaleAssets                 Folder
   └─ NPCs                           Folder
      └─ saffron / mabel / pim / wren / cinderra     Model (replaces placeholder rigs)
```

The file name rule is the Rojo convention: `X.server.luau` → **Script**, `X.client.luau` → **LocalScript**, `init.luau` → makes its folder a **ModuleScript**, any other `X.luau` → **ModuleScript** named `X`.

## Option A: Rojo (recommended)
1. Install the toolchain with [Rokit](https://github.com/rojo-rbx/rokit): `rokit install` in the repo root (versions are pinned in `rokit.toml`). Install the **Rojo Studio plugin** from inside Studio (Rojo's docs explain how).
2. **Quick build:** `rojo build default.project.json -o Hearthscale.rbxlx`, then open `Hearthscale.rbxlx` in Studio.
   **Live sync instead:** open a new *Baseplate* place, run `rojo serve`, and click **Connect** in the Rojo plugin.
3. Continue with *First run in Studio* below.

## Option B: manual (Studio only)
1. Create a new **Baseplate** place.
2. In **ReplicatedStorage** create a Folder `Hearthscale`. For each file under `src/shared`, create the matching object from the tree above and paste in the file's contents:
   - `Content/init.luau` goes **into the `Content` ModuleScript itself**. Its siblings (`Activities.luau`, …) become **child ModuleScripts of `Content`**.
   - `Content/Dialogue/init.luau` goes into a **`Dialogue` ModuleScript under `Content`**, with `SaffronStory`, `SaffronHub` and `Villagers` as its children.
3. In **ServerScriptService** create Folder `HearthscaleServer`, add a **Script** named `Main` (paste `src/server/Main.server.luau`) and a Folder `Services` with the three ModuleScripts.
4. In **StarterPlayer → StarterPlayerScripts** create Folder `HearthscaleClient`, add a **LocalScript** named `Main` (paste `src/client/Main.client.luau`), and recreate the `Controllers`, `UI` and `UI/Minigames` folders with their ModuleScripts.
5. Names are case-sensitive and must match exactly, because scripts find each other with `script.Parent.<Name>`.

## First run in Studio
1. To test **real saving**, publish the place once (*File → Publish to Roblox*), then turn on **Game Settings → Security → Enable Studio Access to API Services**. If the place is unpublished or API access is off, the game still runs immediately: it uses an in-memory store, warns in Output, and the HUD shows "Studio test mode · not saved".
2. Press **Play**. Check the Output window:
   - `[Hearthscale] server ready (romance edition)`. If you see any `[Hearthscale content]` warnings, a data table has a broken reference.
   - The placeholder village appears (the default Baseplate and SpawnLocation are removed).
3. On a new story you'll see the intro, then Saffron (the placeholder dragon) behind the Keeping House counter with a "!" over her head.

### Vertical slice walkthrough (about 10 minutes)
1. Talk to Saffron (**E**, gamepad **X**, or tap the prompt). Pick any reply; branches change Trust and Affinity, and later lines.
2. Choose **"Let's sort."** and play *Cataloguing the Hoard* (tap a shelf or press 1–4).
3. Return the rolling pin (Mabel, bakery), the spectacles (Pim, Town Hall) and the hook (Wren, workshop). The waypoint shows the way.
4. Report back to Saffron. You get the **Assistant Keeper** milestone (banner) and Chapter 2 begins.
5. Open **Bond (K)** for the milestone checklist and **Journal (J)** for quests.
6. **Persistence test:** stop the session, press Play again. You should be in Chapter 2 with the same milestone, items and journal. (This needs a published place with API access on. In memory mode, progress lasts only for one test session.)
7. **Multiple players:** *Test → Clients and Servers → 2 players*. Each player sees their own Saffron in their own chapter and can't see the other's conversations.

## Switching editions
`ReplicatedStorage.Hearthscale.Config.RomanceEnabled`:
- `true`: romance edition. **Requires a Restricted maturity label (18+ age-verified)** before anything romantic goes live. See [01-Compliance.md](01-Compliance.md).
- `false`: friendship edition. Romance choices, scenes, milestone and ending are removed. Existing romance saves load safely (path → friendship, Sweethearts → Confidant).

To ship both, publish **two separate experiences** from the same files, with only this flag changed.

## Replacing the placeholder map
1. Play once in Studio. Select `Workspace.HearthscaleWorld` in the running server view, **copy** it, stop, and **paste** it into Workspace in edit mode.
2. Edit the map freely. Keep the **`Anchors`** model and its part names, and **move anchor parts** to reposition NPCs, pickups and activity spots. Moved parts override the coordinates in `Content/World.luau`.
3. Keep `Beacon/Hearthflame` (the client animates it) or update `Controllers/Ambience`.
4. Optionally set `Config.BuildPlaceholderWorld = false`.

## Publishing checklist
1. **File → Publish to Roblox.** Use a neutral name such as *Hearthscale: A Kettlewick Story*. Don't put romance or dating words in the title or description (see compliance).
2. **Creator Dashboard → your experience → Configure → Questionnaire.** For the romance edition, **verify that you are 18+ first**, then answer *romantic themes: yes*, so the experience gets the **Restricted** label **before** players can see romance content. For the friendship edition, answer accurately from the friendship content.
3. Make sure DataStores work in production (they do by default for published places).
4. Run the [manual test plan](07-TestPlan.md) on a phone, a tablet, desktop and a gamepad.
5. Re-read the Community Standards and Restricted Content Policy (open items in [01-Compliance.md](01-Compliance.md#unresolved-requirements-could-not-verify-from-here)).

## Command-line checks (no Studio needed)
```
lune run tests/run.luau            # 54 tests: content, systems, full playthroughs, server integration
lune run tests/check_build.luau    # compile every script + inspect the Rojo-built place
selene src tests                   # lint with Roblox API definitions
stylua --check src tests           # formatting
```
