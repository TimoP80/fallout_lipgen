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

### Enhanced
- **Audio subsystem**: Refactored `src/audio/uAudioBuffer.pas` to expose `GetDataPointer` for direct sample access and removed public raw `Data` array property. Simplified `src/audio/uWavReader.pas` to validate headers separately and delegate PCM conversion to `TAudioBuffer.LoadFromPCM`.
- **LIP V2 format**: Corrected duration calculation in `src/format/uFalloutLipFormatV2.pas` to divide by `(SampleRate * 4)` instead of raw `SampleRate`. Added `ACMFileNameToString` helper for safe string conversion. Improved `Serialize` to handle empty input gracefully and always initialize required header fields.
- **Core engine**: `src/core/uLipGenerator.pas` now auto-detects LIP format (legacy vs V2) via `DetectLipFormat` and routes all generation output to V2 (`TFalloutLipSerializerV2`). Export/compare/validate functions dispatch to the correct format implementation.
- **GUI**: `src/gui/uMainForm.pas` loads V2 LIP files preferentially and falls back to legacy. Auto-populates output filename from input (`.wav` → `.lip`). `src/gui/LipGeneratorGUI.dpr` simplified by removing unused FPC/LCL directives.
