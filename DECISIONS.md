## 2026-08-12 — Adopt main/ + snapshots/ layout

- **Context:** The repo previously had `.git` and all tracked files directly at
  `hdd-health-check-repo/` root — no separation between the git working tree and any historical
  snapshot mechanism. The `project-management` skill was updated to formalize a `main/`
  (git-tracked working tree) + `snapshots/` (read-only, `git archive`-exported per tag) layout,
  and this project is being normalized to match it — same pattern applied to
  [[project_krm_search_system]].
- **Decision:** Move all existing repo content (including `.git`) into `main/`, add an empty
  `snapshots/` sibling. This is a purely local filesystem reorganization — `main/`'s git remote
  (`origin` → `github.com/CharlesGool/hdd-health-check`) is unchanged, and the repository content
  as seen on GitHub is unaffected (the repo root on GitHub still shows `hdd-health-check.sh` at
  the top level, since that's what's inside `main/`'s git tree).
- **Rejected:** Leaving the repo flat with no `main/`/`snapshots/` split — would leave this
  project inconsistent with the skill's now-standard layout, and with no defined mechanism for
  freezing a read-only copy of each tagged release going forward.
- **Consequences:** Future releases follow the full skill checklist (tag + `git archive` snapshot
  into `snapshots/vX.Y.Z/`, frozen read-only). The first tag, `v1.0.0`, matches the `VERSION="1.0"`
  already hardcoded in `hdd-health-check.sh` at the time of this normalization pass — no version
  bump, just formalizing what was already the de facto v1.0 release as a proper git tag.

## 2026-08-13 — Finish the stalled v1.0.0 normalization; fix bugs found along the way; standardize against the current skill

- **Context:** This project's 2026-08-12 normalization was left incomplete: the doc set (CHANGELOG/DECISIONS/DESIGN/DESIGN.zh/README.zh/STATUS, plus a README.md edit) was `git add`-staged but never committed, no `v1.0.0` tag was ever created despite `STATUS.md` claiming "v1.0.0 (tagged)", and `STATUS.md`'s `Snapshots:` field pointed at a nonexistent path (`hdd-health-check-repo/snapshots/`, a leftover from before the project's folder was first renamed). Separately, the `project-management` skill has moved on since 2026-08-12: the working-tree folder convention is now `repo/` not `main/`, and public repos must not carry a Notion URL or local/NAS paths in `STATUS.md`.
- **Decision:** Renamed `main/` → `repo/` (matching the current skill; this project had missed that migration). While reviewing the staged docs before committing them, found and fixed a real bug present in all 4 doc files (README.md, README.zh.md, DESIGN.md, DESIGN.zh.md): every install/setup snippet told the reader to `cd hdd-health-check-repo/main`, a path that has never existed in the actual GitHub repo (whose tree has `hdd-health-check.sh` directly at root — `main/`/`repo/` is purely this machine's local convention, never pushed). Fixed to `git clone https://github.com/CharlesGool/hdd-health-check.git && cd hdd-health-check`. Also found Traditional Chinese characters (報告/綜合評分/健康等級結論/文檔/退出碼/結束進程/腳本/偵測/靜默失敗) mixed into README.zh.md's otherwise-Simplified "Verify it works" section and converted them to Simplified. Unified all four docs' bilingual header format to the current skill's convention. Rewrote `.gitignore` to match the current template in full (the existing one was a stale partial subset). Desensitized `STATUS.md` for this public repo (Notion URL and local/NAS paths moved to the new `.local-notes.md`, outside `repo/`).
- **Rejected:** Treating the previously-staged content as already correct and just committing it as-is — it contained the `hdd-health-check-repo/main` path bug in 4 places, which would have shipped broken install instructions in the first public tag.
- **Rejected:** Running a live SMART scan against this machine's disk to satisfy the release gate's "clean environment test" — the only block device present is a hypervisor virtual disk with no real SMART data, and `smartmontools` isn't installed here; installing a system package and scanning a fake disk wouldn't meaningfully validate the HDD-specific logic anyway. Verification for this pass was limited to `bash -n` syntax check and confirming `--help` runs cleanly; the script's real-world correctness rests on it already being in informal use before the 2026-08-12 normalization (see decision above), documented as a known-issue caveat in `STATUS.md` rather than silently treated as equivalent to a real clean-install test.
- **Consequences:** `v1.0.0` ships with corrected install instructions instead of the broken staged version. Anyone who copy-pasted the old `cd hdd-health-check-repo/main` snippet before this fix would have hit a "no such directory" error immediately after cloning.

## 2026-08-13 — Replace the public repository with a clean noreply history

- **Context:** The release-level sensitive-info review for this standardization pass found that the repo's only existing commit ("Initial commit: HDD health check script for Debian/Ubuntu"), already pushed to the public `CharlesGool/hdd-health-check` repo, carried a personal Gmail address in its author/committer metadata, not the project's GitHub noreply identity. This is the same category of finding Anytls-Serve hit and remediated on 2026-08-12. The user confirmed proceeding with the same remediation approach rather than treating the address as acceptable to leave public or deciding case-by-case.
- **Decision:** Made the original repository private and renamed it `hdd-health-check-private-archive`, preserving the original commit and its (bad-identity) metadata intact as a private backup. Rebuilt a single clean commit for `v1.0.0` — the full normalized tree (script, license, bilingual docs) — authored and committed with the GitHub noreply address, and tagged `v1.0.0` on it as an annotated tag using the same identity. Created the replacement `CharlesGool/hdd-health-check` privately, to be pushed and audited before being made public again.
- **Rejected:** Force-pushing a rewritten history to the original public repository, or preserving the original two-commit granularity (Initial commit + normalization) with only the identity fields rewritten. Squashing to one clean commit was chosen over an identity-only rewrite because the "Initial commit" content was fully superseded by this pass anyway (broken install paths, incomplete docs) — there was no reason to publish an intermediate state that was never actually correct.
- **Consequences:** The public commit hash for `v1.0.0` differs from anything in the private archive; the two histories share no commits. Existing clones or forks of the old public repo do not automatically migrate, and prior exposure of the Gmail address cannot be guaranteed erased from third-party caches or forks made before this remediation.
