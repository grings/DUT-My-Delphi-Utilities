# ToDo — LDU

## Code review findings — ALL 8 FIXED 2026-08-03 (Opus 5)

The review that produced this list is done. Kept as a record of what changed and why.

| # | Finding | Fix applied |
|---|---|---|
| 1 | `DoSave` read `FFound` while `Finalize` read `SearchResults.Last.Found` — two parallel "found" signals | Deleted `TBaseAgent.FFound`. `SearchResults.Last.Found` is now the only signal. **Worse than reported:** `TAgent_TryExcept` reassigned `FFound` on *every loop iteration*, so after the loop it held the verdict of the LAST line only — in Replace mode the file was written (and `uMyLog` added to the uses) only when the very last line examined happened to be a match. That per-line verdict is now a real local (`IsSwallowed`). |
| 2 | `TAgent_FixLineEndings` shadowed the base `FFound` -> `DoSave` always saw FALSE -> Replace silently never wrote | Local field deleted; the comparison is inlined in the `if`. |
| 3 | Hard `as TCategoryPanelSurface` cast (MainForm.pas) | `is`-test + `Continue` before the cast. |
| 4 | `SaveSettings` bailed when the INI did not exist -> first run lost `LastPath` forever | `FileExists` guard removed from Save (kept on Load). |
| 5 | Agent destructors touched `FormSettings.Container` after AppData may have freed the form | The three settings forms are now created with a NIL owner, so the agent owns them outright and nothing can free them first. An `if Assigned` guard would NOT have worked — the reference dangles, it never becomes NIL. |
| 6 | Unbounded `Positions[]` access in FormEditor (`scrollToPos`, `showDetails`) | Real bounds checks replace the `Assert` — asserts are compiled out in Release, so the Assert only hid the crash in Debug. |
| 7 | `dutCodeFormat.Execute` wrote a new file unconditionally, ignoring `Replace` | Write wrapped in `if Replace`. |
| 8 | Bare `except` in FormColorPicker swallowed everything | Replaced with `TryStringToColor` — a half-typed color is the normal case here, not an exceptional one. No exception handling needed. |

## Open

- `dutWin64Pointer.pas:103` — the `Pointer()` typecast scan ignores only `NativeInt`/`NativeUInt`. Per the note in the code it should also accept `Pointer(UIntPtr)`.
- ` Tool - TextReplace\dutTextReplace.pas` is not wired into any project.
