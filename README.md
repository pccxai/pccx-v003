# PCCX v003 — IP-core planning package

> **PCCX™ v003 is a planning package**, not a stable RTL release.

This repository is the canonical home for the next-generation PCCX™
v003 IP-core line. It mirrors the layout of the published `pccx-v002`
package (`LLM/`, `Vision/`, `Voice/`, `common/`, `compatibility/`,
`docs/`, `tests/`, `scripts/`) and exists so external consumers have
a single, predictable location to track v003 architecture planning
material.

## Status

- **Planning / evidence-gated.** No reusable v003 RTL has been
  published yet.
- No bitstream, no timing closure, no board runtime, no
  tokens-per-second, no FPS, no mAP claim.
- [`pccxai/pccx-LLM-v003`](https://github.com/pccxai/pccx-LLM-v003) was
  a historical temporary feeder for early v003 LLM planning. It is now
  superseded / retired and is no longer an active public track. Any new
  reusable v003 LLM material belongs under `LLM/` of this repository.

## What this package will hold (target shape)

| Directory | Target content |
| --- | --- |
| `LLM/` | reusable LLM RTL, sim/tb, formal harness, scripts |
| `Vision/` | reusable Vision RTL (subject to compatibility review with `pccxai/pccx-vision-v001`) |
| `Voice/` | reusable Voice RTL when a substrate is decided |
| `common/` | shared packages, interfaces, wrappers |
| `compatibility/` | `v003-contract.yaml` plus register / memory / top-interface frozen documents |
| `docs/` | per-domain READMEs and the v003 contract narrative |
| `tests/` | shared test fixtures, intake tests for absorbed material |
| `scripts/` | filelist, build, claim-scan, repo-boundary scripts |

## Boundary rule (unchanged from v002)

The model and the board consume the IP core. The IP core never
references a specific model or board name inside its `rtl/`,
`compatibility/`, or `formal/` paths. Application repositories pin
this package at a SHA that is reachable from `pccx-v003/main`.

## Canonical docs

- Project site: <https://pccx.pages.dev/en/>
- v003 planning pages: <https://pccx.pages.dev/en/docs/v003/>
- v002 contract narrative (reference): <https://pccx.pages.dev/en/docs/reference/v002-contract.html>

## Trackers

- v002/v003 consolidation: [pccxai/pccx#61](https://github.com/pccxai/pccx/issues/61)
- v003 planning: [pccxai/pccx#64](https://github.com/pccxai/pccx/issues/64)
- vision-v001 absorption: [pccxai/pccx#65](https://github.com/pccxai/pccx/issues/65)

## Trademark

`PCCX™` is a mark used by the PCCX project. Korean trademark
applications are pending in Classes 09 and 42. Registration has not
been granted; do not use `PCCX®` until the central trademark policy
is updated. See the canonical policy at
[`pccxai/pccx/TRADEMARKS.md`](https://github.com/pccxai/pccx/blob/main/TRADEMARKS.md).

## License

Apache License 2.0 — see [`LICENSE`](LICENSE).
