# 03 · Production roadmap

## First release (bounded scope)
**One complete story:** beginning (Ch. 1), middle (Ch. 2–4) and ending (Ch. 5 plus epilogue). It has five characters, ten locations, eleven quests, five activities, five relationship milestones and four endings (three in the friendship edition). Players can replay from the start and keep their endings gallery.

**Out of scope for the first release:** more love interests, any player-to-player features, monetisation, voice acting, localisation, a custom map beyond the blockout, and post-game content beyond epilogue chat.

## Status legend
- ✅ **Done in code.** Implemented, linted, and covered by the automated Lune tests (content validation, system unit tests, full-story simulations, server integration with mocked Roblox services).
- 🧪 **Needs Studio verification.** Written against the Roblox API and compile/lint-checked, but **not run in Roblox Studio**. I had no access to Studio, so visuals, input feel, camera, mobile layout and real DataStores are untested.
- 🟨 **Placeholder.** Works now, but should be replaced with real assets.
- ⬜ **Future work.**

## Stages

### Stage 0: Pre-production ✅
- **Deliverables:** policy check ([01](01-Compliance.md)), game design ([02](02-GameDesign.md)), this roadmap.
- **Exit check:** edition strategy decided (romance edition = Restricted; friendship edition via `RomanceEnabled = false`).

### Stage 1: Vertical slice (Chapter 1) ✅ code · 🧪 Studio
- **Goal:** meet the dragon, have a branching conversation, finish a quest and a shared activity, unlock a milestone, and leave and rejoin with progress kept.
- **Implementation:** the engine (`Systems/*`), Ch. 1 content (`saffron_meet`, `saffron_catalogue`, `saffron_strays`, `saffron_report_4112`, three return scenes), the `act_catalogue` sort minigame, `DataService` (locks, retries, autosave, failure handling), `GameService`, the placeholder world, HUD, dialogue, journal, bag, bond, settings, toasts, intro and local NPCs.
- **Setup:** [04-Setup.md](04-Setup.md), *First run* and *Vertical slice walkthrough*.
- **Automated checks:** `server: Chapter 1 vertical slice works end to end through requests`; `server: leave and rejoin (even on another server) keeps all progress`; content validator; transactional dialogue tests.
- **Manual checks:** [07-TestPlan.md](07-TestPlan.md) §A–C.

### Stage 2: Chapter 2 (*The Guttering Flame*) ✅ code · 🧪 Studio
- **Implementation:** quests `q_lanternfall`, `q_pond` and `q_old_bridge`; the fishing timing game; glowcap collectibles; the reach-location objective; the Friend and Confidant milestones; the gift system and hub chat topics (boundaries: tail, mother, flirting).
- **Checks:** gift rules (cooldown, diminishing returns, insults, soft cap); milestone ordering; a full playthrough for each strategy; manual §D.

### Stage 3: Chapter 3 (*What the Hoard Remembers*) ✅ code · 🧪 Studio
- **Implementation:** the letter, hidden hoard clues and the lantern (decision D2), Stargazer Hill night scene, the firefly collect game (server-validated positions), the romance opening (gated by milestone and trust; shown as a locked choice with its reason).
- **Checks:** `activities: collect points are validated`; friendship edition hides all romance; manual §E.

### Stage 4: Chapter 4 (*Lanternfall Eve*) ✅ code · 🧪 Studio
- **Implementation:** Cinderra's arrival, the coats scene, the lantern-rune sequence game, the "What are we?" decision (Saffron accepts, gently declines, or says it's too soon, depending on trust and romance).
- **Checks:** `romance can't be ground out — she declines without enough trust`; manual §F.

### Stage 5: Finale, endings, epilogue ✅ code · 🧪 Studio
- **Implementation:** summit scene with optional reconciliation, the finale timing game (Resolve widens it), four endings with conditional epilogue paragraphs, epilogue lines for every NPC, endings gallery, start a new story.
- **Checks:** every ending reached by a matching simulated player; 60 random players never soft-lock; manual §G.

### Stage 6: Content-complete polish 🧪 / 🟨 (next, needs Studio)
1. **Studio pass (first):** run [07-TestPlan.md](07-TestPlan.md) on desktop, phone, tablet and gamepad. Fix layout and feel issues: UI sizes, camera framing, prompt distances, timing difficulty.
2. **Art:** replace the placeholder rigs and blockout with real models ([05-Assets.md](05-Assets.md)). Saffron comes first.
3. **Animation:** upload the expression animations and fill in `Config.Animations`.
4. **Audio:** add music and SFX you own or have licensed; fill in `Config.Audio`.
5. **Portraits and icons:** fill in `Config.Portraits` and the item `image` fields.
6. **Balancing:** see the tuning notes below.
7. **Compliance:** questionnaire, Restricted label for the romance edition, and the unresolved items in [01](01-Compliance.md).

### Stage 7: Release ⬜
Private beta with friends (adults only for the romance edition) → fix → publish → watch errors in the Developer Console and DataStore budget usage.

### Future work (after release) ⬜
- Side stories: Mabel's bakery rivalry, Wren's Hearthflame apprenticeship, a Cinderra visit.
- Seasonal "Lanternfall again" event using the existing data-driven quests.
- More activities that reuse the four minigame kinds (cooking: sequence; stargazing constellations: sort).
- Accessibility: colour-blind safe palette option, dyslexia-friendly font option, captions for SFX.
- Localisation (all text is in data modules, ready for a translation table).
- Analytics: milestone timing and ending distribution (Roblox AnalyticsService).
- Optional: move dialogue text to ServerStorage to reduce spoiler data-mining.

## Rough schedule (assumptions)
This assumes **one programmer-designer plus part-time art and audio**. Code for Stages 1–5 is already written; the estimates cover verification, art and polish.

| Work | Estimate |
|---|---|
| Studio verification and fixes (Stage 6.1) | 1–2 weeks |
| Saffron model, rig, tail bones and 10 expression animations | 3–5 weeks |
| Four supporting characters (simpler rigs) | 2–4 weeks |
| Real map (10 locations) | 3–6 weeks |
| Audio (5 music loops, 9 SFX) | 1–2 weeks (licensed) or 3–5 (commissioned) |
| Balancing, device QA, beta | 2–3 weeks |
| **Total to release** | **about 3–5 months** |

## Tuning notes (from the simulations)
These are numbers from `tests/specs/03_playthrough.luau` with an attentive player who chats and gives liked gifts:

| After chapter | Trust | Affinity | Romance (romance route) |
|---|---|---|---|
| 1 | 11 | 9 | 0 |
| 2 | 49 | 45 | 3 |
| 3 | 62 | 57 | 21 |
| 4 | 70 | 62 | 33 |

- A kind player who **skips chats and gifts** still finishes on *Kindred Sparks* but only reaches **Friend**. Optional content matters, yet isn't required.
- **Random-choice players** end on *A Stranger's Lantern* about 80% of the time. That's intended: random picks include pushing and dismissive answers. If beta players find it harsh, lower the finale threshold (`statBelow trust 40` in `saffron_summit`) or raise trust rewards in Ch. 2.
- Thresholds live in data: `Content/Milestones.luau`, `Content/Dialogue/SaffronStory.luau` (`rc` and `a4` branches) and `Config.SoftAffinityCap`.
