# 01 · Roblox policy check (romance, maturity, access)

**Checked:** 11 October 2026, before implementation.
**Bottom line:** A romance storyline is allowed on Roblox **only in an experience rated _Restricted_**, which only **age-verified players aged 18+** can play. Hearthscale therefore ships as **two editions from one codebase**:

| Edition | `Config.RomanceEnabled` | Who can play | What changes |
|---|---|---|---|
| **Romance edition** | `true` | Age-verified 18+ only (Restricted label) | Full story, including the romance path and the *Two Flames* ending |
| **Friendship edition** | `false` | Wider audience (you get the label from the questionnaire) | All romance-tagged choices, scenes, the *Sweethearts* milestone and the romance ending are removed at runtime. The story stays complete, with three endings including the friendship ending |

## What the official sources say

### Content maturity & compliance (Roblox Creator Docs)
Source: [create.roblox.com/docs/production/promotion/content-maturity](https://create.roblox.com/docs/production/promotion/content-maturity). The page's live URL was blocked from this environment, so I read the same page from Roblox's official docs repository, [Roblox/creator-docs `content-maturity.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/content-maturity.md), on its `main` branch, on 11 Oct 2026.

- **Romantic themes are defined as** "non-sexual expressions of love or affection, such as a quick kiss on the mouth."
- "If your experience includes (**including in the title**) romantic themes and/or primarily takes place in private spaces or settings intended for adults, you must disclose it within the Maturity & Compliance Questionnaire, and it will **only be available to age-verified players that are at least 18 years old**."
- Restricted-label description: "May contain … **romantic themes** …"
- "Games rated **Restricted** are only accessible to age-verified Roblox users 18 and older."
- "If your experience is going to have Restricted content, it must **first receive a Restricted maturity label** … You must not add any restricted content to your experience before adding content maturity information." The creator also has to verify that they are 18+ before the questionnaire can produce a Restricted label.
- "Realistic or excessive depictions of … romantic themes **may be moderated regardless of your experience's content maturity label**" (this applies to uploaded assets such as images and meshes).
- Restricted experiences "are unplayable for players who created their accounts or are located in certain countries or regions, such as Korea, Saudi Arabia, and Türkiye."
- "If an experience does not have … content maturity information, Roblox restricts the playability of the experience on the platform for all players."
- "Private spaces" means places designed for sleeping, changing or bathing, such as bedrooms, bathroom stalls or small tents. A game set mainly in private spaces, or in adult venues like bars and clubs, also needs disclosure and gets the 18+ treatment.

### Community Standards and the Restricted Content Policy
Sources: [Roblox Community Standards](https://about.roblox.com/community-standards), the [Restricted Content Policy](https://en.help.roblox.com/hc/en-us/articles/15869919570708-Restricted-Content-Policy), and [Clarifying Our Policy on Romantic and Sexual Content (Aug 2025)](https://about.roblox.com/newsroom/2025/08/extending-roblox-policy-on-romantic-and-sexual-content).
> ⚠️ **Not read directly.** The network policy here blocked roblox.com domains, so these points come from search-result excerpts of those pages. Read the pages yourself before publishing (see *Unresolved* below).

- The general standards say Roblox is not the place to seek offline or online romantic connections. They prohibit romantic or flirtatious content outside the rules for Restricted experiences, which the Restricted Content Policy covers.
- Sexual content is prohibited everywhere, including content, settings or behaviour that *implies* sexual activity (the August 2025 clarification).
- Unrated experiences can only be played by the developer and their collaborators.

## Where the concept conflicts with these rules, and what I changed

| # | Conflict | Change made |
|---|---|---|
| 1 | A romantic relationship with an NPC is a "romantic theme", so the experience must be **Restricted (18+, age-verified)** | Romance edition = Restricted. A `RomanceEnabled = false` friendship edition is built in and tested, so the same project can reach a wider audience |
| 2 | The title counts ("including in the title"). The repository name *Dating a Dragon Girl* would force Restricted on any edition and sounds like a dating sim | Original title **Hearthscale: A Kettlewick Story**, which has no romance wording. Keep "dating" out of the experience's title, description, thumbnails and tags for both editions |
| 3 | Romance must stay non-sexual, including anything implied | Most physical affection is hand-holding and a dragon "brow touch" (forehead to forehead). No kisses are shown, though Restricted would allow a quick one. No suggestive lines, no bedrooms, no overnight scenes |
| 4 | Private spaces and adult venues raise the rating | Every location is public: shop counter, square, bakery, pond, hill, ruins, summit. No bars, bedrooms or bathrooms |
| 5 | Roblox forbids seeking romance between users | **No player-to-player romance or pairing features.** Each player's story is private, and other players can't see your NPCs, dialogue or relationship. There are no couple emotes, private rooms or "date another player" mechanics |
| 6 | Romantic content in uploaded art may be moderated whatever the label | Art direction requires the dragon to be **clearly adult and modestly dressed** (waistcoat, rolled sleeves, apron), with no suggestive proportions or poses ([05-Assets.md](05-Assets.md)) |
| 7 | The love interest must be unambiguously adult | Saffron is "two hundred and nine (twenty-six, in dragon years)". This is said in dialogue and in her bio, and a test enforces it. All romance is between adults |
| 8 | Unrated experiences can't be played publicly | Publishing checklist: complete the Maturity & Compliance Questionnaire **before** enabling romance content ([04-Setup.md](04-Setup.md#publishing-checklist)) |
| 9 | Some regions block Restricted experiences | Expect the romance edition to be unavailable there. The friendship edition is the fallback |

## Other compliance notes for this design
- **No free-form user text.** Players never type names or messages into the game, so no TextService filtering is needed. If you add naming or notes later, filter them with `TextService:FilterStringAsync`.
- **No AI chat.** Dialogue is fully scripted. Adding LLM-driven conversations would change the questionnaire answers. One Roblox help-centre summary listed "extended AI interactions" under Restricted, so re-check this before adding it.
- **No monetisation in the first release.** If you add any, follow the questionnaire's paid random items and paid item trading rules, and respect `PolicyService`.
- **Answer the questionnaire from the most mature content.** The romance edition must be declared Restricted, with the romantic themes descriptor.

## Unresolved requirements (could not verify from here)
1. Read the full current **Community Standards** and **Restricted Content Policy** pages. They couldn't be fetched from this environment, and search excerpts are not a substitute.
2. Confirm the **minimum age**. Creator docs and the Content Maturity Labels help page say **18+**. A Parental Controls help article (in search results) says "17+ age-verified". I designed for **18+**.
3. Confirm the exact list of regions where Restricted experiences are unavailable, and plan for those players.
4. Re-check before each content update. These policies changed in 2021, 2023 and 2025.
