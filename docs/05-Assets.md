# 05 · Assets: what's needed, what's a placeholder

**No uploaded Roblox assets ship with this project.** Everything visible is built from code, so the game runs as soon as the scripts are in place. Each placeholder below says what replaces it and where the replacement goes.

## Placeholder inventory
| Area | Placeholder now | Replace with | Where |
|---|---|---|---|
| NPC models (5) | Procedural block figures (`Controllers/PlaceholderRig`) with horns, scales, tail, hats, text-drawn faces | Rigged models | `ReplicatedStorage.HearthscaleAssets.NPCs.<npcId>` (Model). Picked up automatically |
| NPC expressions | Procedural tail, head and arm motion, smoke particles, blush, text faces (`Controllers/Expressions`) | Animation assets (and face textures or FACS) | `Config.Animations.saffron.<emote>` ids. Procedural tail motion still runs on Motor6Ds named `Tail1..N` |
| World | Blockout village (`Services/WorldBuilder`) | Modelled map | Copy `Workspace.HearthscaleWorld`, rebuild it, keep the `Anchors` model ([04](04-Setup.md#replacing-the-placeholder-map)) |
| Pickups and fireflies | Neon spheres | Small models (mushroom, mitten, flower, tag, lantern, firefly) | `Controllers/WorldObjects`, `UI/Minigames/CollectGame` |
| Portraits | Coloured circle with initial | 512×512 bust portraits per emotion (minimum: one each) | `Config.Portraits` |
| Item icons | Emoji | 256×256 icons | `Content/Items.luau` → add `image = "rbxassetid://…"` |
| HUD icons | Emoji (📖 🎒 💛 ⚙️) | 128×128 icons | `UI/Theme.Icons` |
| Music | None (silent) | 5 loops | `Config.Audio.Music` |
| SFX | None (silent) | 9 effects | `Config.Audio.Sfx` |
| Fonts | FredokaOne / Nunito (built-in Roblox fonts) | Optional | `UI/Theme.Fonts` |

## Character art specs (Roblox-practical)
- **Rig:** R15-compatible skinned mesh (Blender → FBX → Studio **3D Importer**). Add tail bones (`Tail1`–`Tail4`, Saffron; `Tail1`–`Tail5`, Cinderra) and two horn bones for the dragons.
- **Tris:** ≤ 10k per hero (Saffron, Cinderra), ≤ 6k for villagers. **Textures:** 1–2 × 1024² (albedo; optional normal and roughness via SurfaceAppearance).
- **Scale:** Saffron about 1.1× a default avatar's height; Cinderra about 1.2×; Pim about 0.85×.
- **Face:** a Dynamic Head (FACS) is best for expressions. Swappable face decals per emotion also work.
- **Model requirements for auto-pickup:** a `Model` whose `PrimaryPart` is `HumanoidRootPart`, plus a `Humanoid` (or AnimationController) with an `Animator` if you want animations. The NPC controller anchors the root, places it on the ground at the anchor, and adds the Talk prompt, name tag and quest marker.

### Saffron: visual brief
Tall, confident posture. Big **curling amber horns**, round **spectacles**, copper-red **scale plates** on her cheekbones and forearms, and a thick tapering **tail** with a gold tip. Outfit: cream shirt with rolled sleeves, **slate-blue waistcoat**, pocketed work apron, boots. **Modest and non-suggestive** (see compliance #6). Palette: skin `#F1C7A1`, scales `#C9512F`, hair `#7B2D1E`, horns `#EBC57D`, outfit `#3F5E78`, accent `#E9B44C`, eyes `#F2A51A`.

### Other characters
| Character | Brief |
|---|---|
| Cinderra | Grey hair, huge back-swept dark horns, ember-red scales, travelling cloak, stern posture |
| Mabel | Round and cheerful, flour-dusted apron, rolled sleeves |
| Pim | Short, anxious, very tall top hat, mayoral sash, spectacles |
| Wren | Lanky young adult, goggles on forehead, tool belt, soot smudges |

## Animations to make (per dragon; villagers need the first five)
| Id key (`Config.Animations.saffron`) | Description | Loop |
|---|---|---|
| `idle` | Weight shift, slow tail sway | yes |
| `talk` | Hand gestures | yes |
| `happy` | Bounce, fast tail wag | yes |
| `laugh` | Head back, shoulders shake | no |
| `sad` | Shoulders drop, tail droops | yes |
| `flustered` | Covers face, tail curls, smoke puff (keep the particle) | no |
| `annoyed` | Arms crossed, tail thumps | yes |
| `surprised` | Startle, tail straight up | no |
| `thoughtful` | Hand on chin, head tilt | yes |
| `determined` | Fists, chin up | yes |
| `tender` | Soft smile, hands clasped, tail curls toward the player | yes |
| `breatheFire` | Finale: inhale, fire breath (pair with a fire particle) | no |

Upload each as an Animation owned by the experience owner (user or group) and paste its id into `Config.Animations`.

## Audio list
| Key | Mood |
|---|---|
| Music `village` | Warm acoustic waltz, music-box motif for Saffron |
| Music `night` | Sparse celesta and strings for Stargazer Hill |
| Music `tension` | Low strings and brass for Cinderra and Lanternfall Eve |
| Music `finale` | Building theme for the summit |
| Music `ending` | Gentle reprise |
| SFX `click`, `toast`, `questComplete`, `milestone`, `pickup`, `smokePuff`, `success`, `fail`, `typewriter` | UI and feedback sounds |

Only use audio you own or have a licence for. Roblox's Creator Store has licensed tracks, and you may upload your own audio within Roblox's rules. Leaving an id empty simply mutes that sound.

## Map list (for the art pass)
Village square (fountain, 8 lantern posts, notice board, lantern table) · Keeping House (open shopfront, counter, sorting table, four hoard shelves, balloon wreck on the roof) · Crumb's Bakery · Town Hall · Lamplighter's Workshop (plus your balloon under repair) · Mirror Pond (dock, reeds) · Glowcap Woods (about 40 trees) · Old Bridge ruins (two cliffs, gorge, charred beams) · Stargazer Hill · Hearthpeak switchback trail and summit with the iron brazier. All locations are public spaces (no bedrooms or bathrooms; see compliance).
