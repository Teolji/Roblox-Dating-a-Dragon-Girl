# 06 · Authoring content (dialogue, quests, items, activities, endings)

All story content is **data** under `src/shared/Content`. The systems in `src/shared/Systems` interpret it, so adding a scene, quest or item never needs new code. After any edit, run `lune run tests/run.luau`. The validator reports broken ids, unreachable nodes, dead-end choices, flags that are checked but never set, and events nothing emits. The server repeats this check at startup and prints `[Hearthscale content]` warnings in Studio.

## Conditions (`when`, `requires`, `condition`)
A **list** means *all*; a **table** means *every clause*.
```lua
{ flag = "met_saffron" }                      { notFlag = "leaving" }
{ stat = { "trust", 40 } }                     { statBelow = { "trust", 40 } }
{ quest = { "q_pond", "complete" } }           -- notStarted | active | complete | started
{ questStep = { "q_pond", "talk" } }           { item = { "glowcap", 5 } }
{ chapter = 2 }  { chapterMin = 2 }  { chapterMax = 3 }
{ milestone = "friend" }                       -- this rank or higher
{ milestoneIs = "sweetheart" }                 { canReachMilestone = "friend" }
{ path = "romance" }                           { romance = true }   -- edition gate
{ activity = "act_fishing" }                   { giftReady = true }
{ ending = "two_flames" }  { anyEnding = true }  { noEnding = true }
{ any = { ... } }  { all = { ... } }  { ["not"] = { ... } }
```

## Effects (`effects`, `onEnd`, `rewards`, `onStart`, `onComplete`, `onReach`)
```lua
{ flag = "x" } / { flag = { "a", "b" } }       { unflag = "x" }
{ stat = { "trust", 3 } }                      { stat = { { "trust", 3 }, { "affinity", 2 } } }
{ softStat = { "affinity", 1 } }               -- capped by Config.SoftAffinityCap
{ give = "honey_bun" } / { give = { "glowcap", 2 } }    { take = { "glowcap", 5 } }
{ startQuest = "q_pond" }                      { event = "talk:saffron_pond_talk" }
{ path = "friendship" }                        { chapter = 3 }
{ startActivity = "act_fishing" }              { action = { action = "openGift", npc = "saffron" } }
{ toast = "Text" }                             { resolveEnding = true }
```
Romance stat changes and `path = "romance"` do nothing in the friendship edition.

## Conversations (`Content/Dialogue/*.luau`)
```lua
my_scene = {
	npc = "saffron",
	priority = 900,              -- highest available wins; hub menus use 0; ≥800 shows "!"
	when = { questStep = { "q_x", "talk" } },
	repeatable = false,          -- default: plays once
	romance = false,             -- true = romance edition only
	start = "a1",
	nodes = {
		a1 = { emote = "happy", text = "Hello, {player}.", next = "a2" },
		a2 = { speaker = "narrator", text = "She polishes a spoon.", next = "a3" },
		a3 = {
			text = "Well?",
			choices = {
				{ text = "Kind reply", tag = "kind", effects = { stat = { "trust", 2 } }, next = "b1" },
				{ text = "Romantic reply", tag = "romance", romance = true,
				  when = { milestone = "confidant" },
				  lockedText = "(Shown greyed out with this hint until the condition passes.)",
				  next = "b2" },
				{ text = "Goodbye." },               -- no next = end
			},
		},
		b1 = { branch = { { when = { stat = { "trust", 30 } }, next = "c1" }, { next = "c2" } } },
		-- ...
	},
	onEnd = { event = "talk:my_scene" },        -- usually completes a quest objective
}
```
- **Speakers:** a character id, `"narrator"` (italic, no portrait) or `"player"`. The default is the conversation's `npc`.
- **Emotes:** neutral, happy, laugh, flustered, annoyed, sad, surprised, thoughtful, determined, smug, tender.
- **Tokens:** `{player}` (display name), `{saffron}` (what the player may call her at this milestone), `{festival}` (countdown), `{hint}` (current objective hint).
- **Rules the validator enforces:** every choice list has at least one always-available choice; every `branch` ends with an unconditional option; every node is reachable.
- **`once = "key"`** on a choice makes it usable a single time (chat topics).
- **Tags** are never shown. Test bots use them to play styles, so tag new choices (`kind`, `joke`, `respect`, `push`, `romance`, …).
- Conversations are **transactional**: nothing is committed until the scene ends, so walking away mid-scene changes nothing.

## Quests (`Content/Quests.luau`)
```lua
q_example = {
	title = "Title", chapter = 2, order = 45, summary = "Journal text.",
	steps = {
		{ id = "find", text = "Step text", hint = "What Saffron says if asked",
		  onStart = { give = "map" },
		  objectives = {
		    { id = "caps", text = "Gather caps", event = "collect:glowcap", count = 5 },
		    { id = "trust", text = "Earn her trust", condition = { stat = { "trust", 30 } } },
		  } },
	},
	rewards = { startQuest = "q_next" },
}
```
Event sources: conversations (`event = ...` effects), collectibles (`collect:<group or id>`), activities (`activity:<id>`) and locations (`reach:<id>`). Start quests from `Story.StoryRules`, a reward, or a dialogue effect.

## Story rules (`Content/Story.luau`)
One-shot reactions: `{ id = "chapter3", when = <cond>, effects = { chapter = 3, startQuest = "q_letter" } }`.

## Items and gifts
- `Content/Items.luau`: `{ name, description, icon, image?, giftable?, quest? }`.
- `Content/Characters.luau` → `saffron.gifts.tiers[itemId] = "loved" | "liked" | "neutral" | "disliked" | "hated"`, plus optional `reactions[itemId] = { first = {text, emote}, again = {...}, tooMany = {...}, effects = ... }`.

## Activities (`Content/Activities.luau`)
`kind` is one of `sort | timing | sequence | collect`; `params` are per kind (see existing entries). `tiers` are ascending `min` scores with optional `effects` (first clear) and a partner `line`. `rewards.first` and `rewards.again` (soft-capped, limited replays). `resolveWidthBonus` scales timing zones with Saffron's Resolve.

## World (`Content/World.luau`)
- **Anchors:** `Name = { x, y, z [, yawDegrees] }`.
- **Collectibles:** `{ name, anchor, group?, when?, effects, text?, color? }`.
- **Locations:** `{ name, anchor, radius }`, which fire `reach:<id>`.
- **NPC stations:** `Characters.<id>.stations`, first match wins: `{ when = ..., anchor = "X" }` or `{ when = ..., hidden = true }`.

## Endings (`Content/Endings.luau`)
Checked in order when `resolveEnding` runs; **the last one must be an unconditional, non-romance fallback**. `paragraphs` mix plain strings and `{ when = ..., text = ... }` variants.

## Adding a new romance-only scene safely
1. Mark the choice or conversation `romance = true`.
2. Gate it on closeness (`milestone`, `stat`) and give it a `lockedText` so players see that she needs more trust.
3. Keep it non-sexual and in a public setting ([01-Compliance.md](01-Compliance.md)).
4. Run the tests. `friendship edition hides all romance` fails if a romance choice leaks.
