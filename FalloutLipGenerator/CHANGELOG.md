# Changelog

All notable changes to this project will be documented in this file.

## 2026-05-07

### Fixed
- Restored Delphi-compatible type declarations and dynamic array aliases in `src/lip/uSignalAnalysis.pas`.
- Fixed `src/format/uFalloutLipFormat.pas` header signature initialization and timing visualization frame-duration handling.
- Repaired `src/core/uLipGenerator.pas` type section structure and missing `Math` dependency.
- Fixed `src/gui/uMainForm.pas` record-property assignment issues, VCL `MessageDlg` usage, and added a matching `src/gui/uMainForm.dfm` resource.
- Fixed `src/cli/wav2lip.dpr` Delphi compilation issues around option assignment, callback binding, export file writing, and FPC-only compiler directives.

### Verified
- `dcc32` compilation succeeds for the tracked CLI and GUI entrypoints after the above fixes.
