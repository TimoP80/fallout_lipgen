# Changelog

All notable changes to this project will be documented in this file.

## 2026-05-26

### Fixed

- **LIP V2 header initialization for Anchorite compatibility**: Fixed critical bug in `src/format/uFalloutLipFormatV2.pas` where the `VocMarker` field was not being properly initialized when generating LIP files. The `VocMarker` field (should be "VOC" + null terminator) was being left as zeros, causing Anchorite's LIP editor to reject files with "Invalid LIP file format" error. Changed `FillChar(FHeader.ACMFileName, ...)` to `FillChar(FHeader, SizeOf(FHeader), 0)` to clear the entire header, then explicitly set `VocMarker` to 'V', 'O', 'C', #0.

## 2026-05-24

### Fixed

- **Delphi compilation errors in text-guided lip generation**: Fixed syntax errors in `uLipGenerator.pas` related to undeclared `Analyzer` variable and broken if/else block structure in `GenerateFromBuffer` function. Updated references to use correct `memDialogText` control instead of non-existent `edtDialogText`. Modified `GenerateFromBuffer` to call `GenerateLipFramesWithText` directly as a standalone function from `uSignalAnalysis.pas`.

### Changed

- **GUI text input control**: Updated main form to use `TMemo` (`memDialogText`) for multi-line dialog text input instead of `TEdit`, enabling better text-guided lip generation workflow.

## 2026-05-20

### Fixed

- **Spanish MFA phoneme table** (`VOC/VOCK/phonemes/phonemes_spanish_mfa.py`): The labial-velar approximant `/w/` was incorrectly mapped to code `0x23`, colliding with `/l/` (lateral alveolar). Corrected to `0x24` (FRM frame 8 — wide open), matching the Pascal `PHONEME_TO_FRAME` reference in `uFalloutLipFormatV2.pas:78`. All 10 remaining language phoneme modules (English ×2, Russian, German, French, Italian, Hungarian, Polish, Portuguese, Czech) were diffed against the Pascal reference and the previous VOCK release — no further code-value discrepancies found.

### Added

- **`config.py` to VOCK pipeline** (`VOC/VOCK/config.py`): New central configuration module. All paths, LUFS target, MFA conda environment name, and default language are now declared here. `vock.py` and `dict_lookup.py` both read from it — eliminates hard-coded paths and partial-command-line overrides.
- **Language auto-detection in `config.py`**: `LANGUAGE` field sets the default for the `--language` flag. All 10 supported languages (`arpabet`, `english`, `spanish`, `russian`, `french`, `german`, `czech`, `hungarian`, `italian`, `polish`, `portuguese`) are documented in `config.py` and mirrored in `LANGUAGE_CONFIG`.
- **`--language` flag to `vock.py`**: A new top-level CLI argument replaces the old `--mfa-env` positional override. Usage: `python3 vock.py --language spanish`.
- **All 10 language-specific custom dictionaries** under `VOC/VOCK/dictionaries/` (`custom.<lang>.dict`): Pre-populated with common Fallout 2 game nouns (`geck`, `mynoc`, `tribals`, `hassleful`) to reduce `spn` assignment out of the box.
- **`pip_install_guide.md`**: Step-by-step pip-based installation for Windows and Linux, covering project dependencies.
- **`text_guide.md`**: Phoneme usage guide with examples and a phoneme symbol table.
- **`rgba_color_picker.md`**: Examples for color picking, complementing the existing RGB reference.

### Changed

- **VOCK phoneme module API**: Each language module now exports `PHONEME_TABLE` (a `dict[str, int]`) instead of `ARPA_TO_LIP` / `ENGLISH_IPA_TO_LIP` / `SPANISH_IPA_TO_LIP`, etc. Per-module helper functions (`arpa_to_lip_code`, `ipa_to_lip_code`) were removed in favour of the shared `make_phoneme_converter()` closure in `vock.py`, which strips MFA stress/length markers before lookup. GUI and pipeline constants:
  | Constant | vock.py | Pascal |
  |---|---|---|
  | `LIP_VERSION` | `0x00000002` | `LIP_VERSION_2 = 2` ✓ |
  | `LIP_UNKNOWN` | `0x00005800` | `LIP_MAGIC = $00005800` ✓ |
  | `LIP_SAMPLE_RATE` | `22050` Hz | `LIP_SAMPLE_RATE = 22050` ✓ |
  | `LIP_MULTIPLIER` | `2` | `LIP_MULTIPLIER = 2` ✓ |

---

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
