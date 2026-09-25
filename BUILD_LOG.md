# Build log — Blackacre: In Character Forever

## Fork point

Forked from [Blackacre: In Character](https://github.com/khallammarellus-rgb/blackacre-in-character) (the Retail repo) at commit `e7a5370` on 2026-09-25, with full commit history preserved (not squashed or reset). Both repos are identical up to that commit and diverge only from here forward.

## Why the split

Retail has ~20 years of quests, lore, and canon to build features on. WoW Forever is new content on a mainline-style client (interface `16001`, Camelot), and there isn't yet enough verified quest/canon depth to build the same features Retail has (Paths / Alternate Start, most notably). Keeping both flavors in one repo behind a compat flag meant a Retail-focused change could quietly break Forever and vice versa. Splitting into two repos means each can evolve on its own terms. See [`docs/RETAIL-VS-FOREVER.md`](docs/RETAIL-VS-FOREVER.md) for the full breakdown of what each flavor does and doesn't have.

## What changed in this fork at the split (2026-09-25)

- `Blackacre.toc` and the three package TOCs: dropped the Retail `## Interface: 120007` line, kept only `16001` / Camelot.
- `Blackacre.toc`: title updated to "Blackacre: In Character Forever," notes updated, `X-Website` points at this repo, `## OptionalDeps: totalRP3` removed (Forever has no TRP3 port — `Blackacre.Compat.SupportsTRP3()` already gates this in code, this just matches it in the manifest).
- `README.md`: rewritten as the Forever-only fork README, links back to the Retail repo, flags that Retail-only packages (Roadmap, Afterlife, Hardcore, PvP, Life Paths) are still present as of this split but are not being actively developed here and are slated for a later removal pass — not an oversight.

Nothing else changed yet. Feature work, the open SavedVariables bug investigation, and the Retail-only package removal pass all come after this.
