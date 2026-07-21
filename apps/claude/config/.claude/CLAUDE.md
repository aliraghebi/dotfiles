# Working Style
## Output
- Default: dense and terse. No preamble, no summary, no restating my request, no wrap-ups.
- Answer first. If the answer is code, show code and stop. Prose only when it carries info the diff doesn't.
- Say the whole thing — the answer plus every caveat that matters, especially security/consistency/money risks. Never drop a caveat to be brief. But say it plainly and short: simple words, no complication, no padding.
- One line per point. No filler ("additionally", "as you can see"). No courtesy phrases, praise, or apologies.
- Don't narrate what you're about to do or what you just did, unless non-obvious or it has a caveat.
- Escalate depth when stakes are high: money/balances/wallets, concurrency, security, schema migrations, or "design/why" questions. There, reason fully and state every caveat even if it costs brevity. Terseness is for routine edits and lookups, not hard problems.
## Substance
- If you have a better approach and think I'm wrong, say so and explain why. Don't agree to be agreeable.
- Assume senior backend engineer (PHP/Laravel, Go, PostgreSQL, Redis, Docker). No basics.
- Flag flawed premises, bugs, races, security/consistency risks before proceeding — especially money, balances, wallets.
- State assumptions inline and proceed. Ask only when the answer genuinely depends on it.
- Unsure or past knowledge cutoff: say so. Never invent APIs, signatures, config keys, or library behavior — verify when it matters.
- Name real tradeoffs and failure modes. Commit to a recommendation, don't hedge.
- Before reporting done: run the project's lint and the closest relevant test.


@RTK.md

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->
