# Developer Documentation Style — Heavy Reference

Detail backing the **Developer Documentation Style** context of `technical-writing`. Read this when the audience is software developers or technical practitioners. Apply these rules during the Draft phase.

## 1. Reference hierarchy

Resolve style questions in this order:

1. **Project-specific style** — your project's overrides and product-specific terms.
2. **This guide** — the Google developer documentation style guide.
3. **Third-party references** — when neither above answers:
   - Spelling: [Merriam-Webster](https://www.merriam-webster.com/).
   - Nontechnical style: *The Chicago Manual of Style*, 17th edition.
   - Technical style: [Microsoft Writing Style Guide](https://docs.microsoft.com/style-guide/welcome/).

Do not write a house style guide. If your team coins a term absent from these references, maintain a local usage sheet for that term only.

## 2. Voice & tone

Write conversationally but not too informally. The reader is a professional; respect their time.

| Rule | Example |
|---|---|
| Use contractions | "don't", "can't", "won't" — not "do not", "cannot" |
| Second person ("you") | "You can configure the client…" not "The user can…" |
| Present tense | "The function returns…" not "The function will return…" |
| Active voice | "The server sends a response." not "A response is sent." |
| No arrogance | Avoid "simply", "just", "obviously", "of course" |

| ❌ Condescending | ✅ Neutral |
|---|---|
| "Just call the API and you're done." | "Call the API to complete the request." |
| "Obviously, the cache expires." | "The cache expires after 5 minutes." |

## 3. Sentence case headings

Headings and titles use **sentence case**: capitalize the first word only, plus proper nouns and the first word after a colon.

| ❌ Title case | ✅ Sentence case |
|---|---|
| "Configuring The Client" | "Configuring the client" |
| "API Reference" | "API reference" |
| "How To Use Flags" | "How to use flags" |

Keep headings short. Use noun phrases or question forms, not full sentences, unless the heading is a procedural step.

## 4. Word list rules

Common terms where Google style diverges from generic usage:

| ❌ Avoid | ✅ Use | Note |
|---|---|---|
| log in, login | sign in, sign-in | "sign in" (verb), "sign-in" (noun/adjective) |
| tap | click | Except genuine touch interfaces |
| whether | if | Unless contrasting alternatives explicitly |
| allow, enable | let | "lets you" over "allows you to" |
| utilize | use | Always |
| leverage | use | Always |
| in order to | to | Always |
| via | through, by | Except Latin-accepted contexts (via an API) |
| please | (omit) | Adds no information |
| note that, please note | (omit) | State the fact directly |

For terms not listed here, consult the full [Google word list](https://developers.google.com/style/word-list).

## 5. Punctuation

| Mark | Rule |
|---|---|
| Oxford comma | Optional but consistent within a document. Prefer including it. |
| Em-dash (—) | For asides and emphasis. No spaces around it. |
| En-dash (–) | For ranges: "pages 10–12", "ages 5–8". |
| Slash | Avoid. Rewrite with "or" or "and". |
| Semicolon | Allowed but short sentences preferred. Split if a sentence runs long. |
| Period inside quotes | "Call it 'done.'" not "Call it 'done'." |
| Colon | Lowercase the first word after a colon unless it starts a proper noun or a complete quoted sentence. |

| ❌ Slash | ✅ Rewrite |
|---|---|
| "client/server" | "client and server" |
| "read/write" | "read or write" |

## 6. Formatting & organization

- **Lists** require a lead sentence ending in a colon and parallel items (same part of speech).
- **Numbered lists** for procedural steps the reader performs in order.
- **Bulleted lists** for unordered items the reader scans.
- **Tables** when the reader looks up a value by row and column.
- **Procedures**: number each step; one action per step; start with an imperative verb.
- **Notes and notices**: use a callout (`> **Note:**`) sparingly; reserve `> **Warning:**` for risk of data loss or injury.

Maximum 7 ± 2 items per list. Beyond that, group into sub-lists or a table.

## 7. Code in text & samples

| Element | Format |
|---|---|
| Inline code, filenames, commands | Backticks: `resolveKey`, `config.json` |
| Code samples | Fenced blocks with a language: ` ```ts ` |
| Placeholders | Italic with angle brackets: `<your-api-key>` |
| UI elements | Bold: **File** > **Save** |
| Command-line output | Fenced block, `text` language |

```text
❌ "Enter your key in the box."
✅ "Enter <your-api-key> in the **API key** field."
```

Code samples must be complete and runnable. Prefer one excellent example over several mediocre ones.

## 8. Cross-references & linking

- Link text describes the target, not the act of clicking.
- Anchor text identifies the destination by name or topic.
- Avoid multiple links to the same target in one paragraph.
- Do not link the same phrase repeatedly across a document.

| ❌ Vague | ✅ Descriptive |
|---|---|
| "Click [here](...) to learn more." | "See the [authentication guide](...) for details." |
| "[Read this](...)." | "Read the [rate limiting reference](...)." |

## 9. API reference comments

Document APIs with standard comment tags. Keep descriptions to one sentence.

| Tag | Use |
|---|---|
| `@param` | Name and describe each parameter. |
| `@return` | Describe the return value; state the type. |
| `@throws` or `@exception` | Name the exception and the condition that triggers it. |
| `@deprecated` | State the replacement and the removal version. |

Reference-doc verbs: use the present tense. "Returns", "Throws", "Sets", "Gets" — not "Will return", "Should throw".

```text
❌ "This function will return the user's profile."
✅ "Returns the user profile for the given ID."
```

## 10. Inclusive & accessible

- Use gender-neutral language. Prefer "they" over "he/she".
- Avoid figurative language that excludes: "master/slave" → "primary/replica"; "whitelist" → "allowlist"; "blacklist" → "blocklist".
- Provide `alt` text for every image. Describe the content, not the file name.
- Do not rely on color alone to convey information. Pair color with text or shape.
- Keep headings in a valid outline: H1 → H2 → H3, no skipped levels.
- Avoid all-caps paragraphs; screen readers spell them out letter by letter.

## Sources

- Google developer documentation style guide — <https://developers.google.com/style>
- Google technical writing resources — <https://developers.google.com/tech-writing/resources>
- Microsoft Writing Style Guide — <https://learn.microsoft.com/style-guide/>
- *The Chicago Manual of Style*, 17th edition