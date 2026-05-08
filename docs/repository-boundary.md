# v003 repository boundary (planning)

Mirrors the v002 boundary rule. The IP-core never references a
specific model or board name inside `rtl/`, `compatibility/`, or
`formal/` paths. Application repos pin this package at a SHA
reachable from `pccx-v003/main`.

See:
- canonical: <https://pccx.pages.dev/en/docs/v003/repository-boundary.html>
- v002 boundary rule: <https://pccx.pages.dev/en/docs/reference/boundary-rule.html>
