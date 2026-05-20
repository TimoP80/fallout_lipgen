# Fallout Lip Generator

A modern Object Pascal / Delphi library and toolset for generating classic Fallout 1 / Fallout 2 compatible .LIP files from .WAV voice audio files for use with talking head animations.

## Overview

This project provides a complete solution for Fallout modders to create lip-sync animation files that work with:
- Fallout 2 Community Edition
- sfall
- Classic Fallout executables
- Talking head mods

The library reverse-engineers and recreates Fallout .LIP lip-sync generation behavior, producing binary .LIP files that closely mimic original Interplay behavior.

## Features

### Core Library
- **WAV Audio Processing**: Load uncompressed PCM .wav files (8-bit / 16-bit, mono)
- **Signal Analysis**: Energy-based phoneme approximation, envelope detection, silence detection
- **Lip Generation**: Frame-based mouth movement timing with configurable FPS (10, 12, 15)
- **Format Serialization**: Binary .LIP file generation compatible with Fallout engines

### Tools
- **CLI Tool** (`wav2lip.exe`): Command-line utility for batch processing
- **GUI Application**: Modern desktop interface with waveform preview and batch queue

### Analysis Utilities
- Read and parse existing .LIP files
- Export debug information (text and JSON)
- Compare generated vs original files
- Hex viewer/debug mode
- Timing visualization

## Architecture

```
FalloutLipGenerator/
├── src/
│   ├── audio/          # Audio processing (WAV reading, buffer management)
│   ├── lip/            # Signal analysis (envelope, phoneme detection)
│   ├── format/         # LIP format serialization
│   ├── core/           # Main lip generation engine
│   ├── cli/            # Command-line interface
│   └── gui/            # Graphical user interface
├── tests/              # Unit tests
├── samples/            # Sample audio files
└── docs/               # Documentation
```

### Key Units

- **uAudioBuffer.pas**: Audio buffer management and PCM format handling
- **uWavReader.pas**: WAV file parsing and loading
- **uSignalAnalysis.pas**: Signal processing and lip frame generation
- **uFalloutLipFormat.pas**: Fallout LIP file format serialization
- **uLipGenerator.pas**: Main orchestration engine
- **wav2lip.dpr**: CLI tool entry point
- **LipGeneratorGUI.dpr**: GUI application entry point

## Installation

### Requirements
- Delphi 11+ or FreePascal/Lazarus (cross-compatible)
- No external proprietary dependencies
- Windows (primary), Linux/macOS (via FreePascal)

### Building

1. Open the project in Delphi or Lazarus
2. Compile `src/cli/wav2lip.dpr` for CLI tool
3. Compile `src/gui/LipGeneratorGUI.dpr` for GUI application
4. Or use included build scripts

### Quick Start

```pascal
uses uFalloutLipGenerator;

var
  Generator: TLipGenerator;
  Result: TLipGenResult;
begin
  Generator := TLipGenerator.Create;
  try
    Generator.Options.FPS := 12;
    Generator.Options.Threshold := 0.08;
    Generator.Options.Normalize := True;
    
    Result := Generator.GenerateFromFile('dialogue.wav', 'dialogue.lip');
    
    if Result.Success then
      WriteLn('Generated ', Result.FrameCount, ' frames')
    else
      WriteLn('Error: ', Result.ErrorMessage);
  finally
    Generator.Free;
  end;
end;
```

## Usage

### Command-Line Interface

```bash
# Basic usage
wav2lip input.wav output.lip

# With options
wav2lip input.wav output.lip --fps 15 --threshold 0.1 --debug

# Export debug information
wav2lip input.wav output.lip --export-json debug.json --export-debug debug.txt

# Compare LIP files
wav2lip --compare original.lip generated.lip

# Validate LIP file
wav2lip --validate output.lip
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--fps 10\|12\|15` | Target FPS | 12 |
| `--threshold 0.08` | Energy threshold | 0.08 |
| `--normalize` | Normalize audio | on |
| `--nonormalize` | Disable normalization | off |
| `--extended` | Include extended data | off |
| `--debug` | Enable debug output | off |
| `--export-json FILE` | Export to JSON | - |
| `--export-debug FILE` | Export debug info | - |
| `--compare FILE` | Compare with LIP file | - |
| `--validate` | Validate LIP file | off |
| `--batch` | Batch processing mode | off |

### GUI Application

The GUI provides:
- WAV file browser with drag-and-drop
- Real-time waveform preview
- Batch conversion queue
- Lip frame timeline visualization
- Playback preview
- Settings editor
- Progress reporting
- Logging console

### API Reference

#### TLipGenerator

Main class for lip-sync generation.

```pascal
type
  TLipGenOptions = record
    FPS: Integer;              // 10, 12, or 15
    Threshold: Double;         // Energy threshold (0.0-1.0)
    Normalize: Boolean;        // Normalize audio
    IncludeExtendedData: Boolean; // Include extended frame data
    MinSilenceDuration: Double; // Minimum silence (seconds)
    MinPhonemeDuration: Double;  // Minimum phoneme (seconds)
    DebugMode: Boolean;        // Enable debug output
  end;

  TLipGenResult = record
    Success: Boolean;
    ErrorMessage: string;
    InputFile: string;
    OutputFile: string;
    Duration: Double;
    FrameCount: Integer;
    ProcessingTime: Double;
    Warnings: TStringList;
  end;

function GenerateFromFile(const InputWav, OutputLip: string): TLipGenResult;
function GenerateFromBuffer(Buffer: TAudioBuffer; const OutputLip: string): TLipGenResult;
function GenerateLipFrames(Buffer: TAudioBuffer): TLipFrameArray;
function BatchProcess(const InputList, OutputList: TStringList): TArray<TLipGenResult>;
```

#### TAudioAnalyzer

Signal analysis for phoneme detection.

```pascal
function GenerateLipFrames(buffer: TAudioBuffer; fps: Integer): TLipFrameArray;
function DetectPhonemeSegments(buffer: TAudioBuffer): array of TPointF;
function CalculateEnergyEnvelope(buffer: TAudioBuffer): array of Double;
function DetectSilence(buffer: TAudioBuffer; threshold: Double): array of TPointF;
```

#### TFalloutLipFile

LIP file serialization.

```pascal
function LoadFromFile(const FileName: string): Boolean;
function SaveToFile(const FileName: string): Boolean;
function ExportToJSON: string;
function ExportDebugInfo: string;
procedure FromLipFrames(const LipFrames: TLipFrameArray; FPS: Integer);
function ToLipFrames: TLipFrameArray;
```

## Fallout LIP Format

### File Structure

```
Offset  Size    Description
------  ----    -----------
0x00    4       Signature ('LIP' + null)
0x04    2       Version (1)
0x06    2       Frame count
0x08    2       FPS (10, 12, or 15)
0x0A    4       Duration (milliseconds)
0x0E    8       Reserved
0x16    -       Frame table (variable)
```

### Frame Entry

```
Offset  Size    Description
------  ----    -----------
0x00    2       Time offset (milliseconds)
0x02    1       Mouth state (0-3)
0x03    1       Intensity (0-255)
0x04    1       Reserved
```

### Mouth States

| Value | State | Description |
|-------|-------|-------------|
| 0 | Closed | Mouth closed / silence |
| 1 | SmallOpen | Slight opening (m, b, p) |
| 2 | MediumOpen | Medium opening (n, d, t) |
| 3 | WideOpen | Wide opening (a, o, e) |

## Algorithm Details

### Energy-Based Phoneme Approximation

1. **Envelope Detection**: Extract amplitude envelope using attack/release smoothing
2. **Silence Detection**: Identify regions below threshold
3. **Energy Mapping**: Map RMS energy to mouth states
4. **Temporal Smoothing**: Apply minimum duration constraints
5. **Frame Quantization**: Generate frames at target FPS

### Signal Processing

- **Window Size**: 20ms (configurable)
- **Hop Size**: 10ms (configurable)
- **Attack Time**: 10ms
- **Release Time**: 100ms
- **RMS Calculation**: Root mean square over window

## Compatibility

### Tested With
- Fallout 2 Community Edition
- sfall 4.x+
- Classic Fallout 2 (1.0.x)
- MIB88 Megamod
- Various talking head mods

### File Format Compatibility
- Original Interplay .LIP files: Read/Write
- Generated files: Compatible with all Fallout engines
- No modern format dependencies

## Examples

### Example 1: Basic Conversion

```pascal
var
  Generator: TLipGenerator;
begin
  Generator := TLipGenerator.Create;
  try
    Generator.Options.FPS := 12;
    Generator.Options.Threshold := 0.08;
    Generator.GenerateFromFile('hello.wav', 'hello.lip');
  finally
    Generator.Free;
  end;
end;
```

### Example 2: Batch Processing

```pascal
var
  Generator: TLipGenerator;
  Inputs, Outputs: TStringList;
  Results: TArray<TLipGenResult>;
  I: Integer;
begin
  Generator := TLipGenerator.Create;
  Inputs := TStringList.Create;
  Outputs := TStringList.Create;
  try
    Inputs.Add('line1.wav');
    Outputs.Add('line1.lip');
    Inputs.Add('line2.wav');
    Outputs.Add('line2.lip');
    
    Results := Generator.BatchProcess(Inputs, Outputs);
    
    for I := 0 to High(Results) do
      WriteLn(Format('%s: %s', [Results[I].OutputFile,
        IfThen(Results[I].Success, 'OK', 'FAILED')]));
  finally
    Outputs.Free;
    Inputs.Free;
    Generator.Free;
  end;
end;
```

### Example 3: Custom Analysis

```pascal
var
  Reader: TWavReader;
  Buffer: TAudioBuffer;
  Analyzer: TAudioAnalyzer;
  Envelope: array of Double;
  Silence: array of TPointF;
  I: Integer;
begin
  Reader := TWavReader.Create('audio.wav');
  try
    Buffer := Reader.LoadToBuffer;
    try
      Analyzer := TAudioAnalyzer.Create(Buffer.SampleRate);
      try
        // Get energy envelope
        Envelope := Analyzer.CalculateEnergyEnvelope(Buffer);
        
        // Detect silence
        Silence := Analyzer.DetectSilence(Buffer, 0.05);
        
        // Output results
        for I := 0 to High(Silence) do
          WriteLn(Format('Silence: %.3f - %.3f sec', 
            [Silence[I].X, Silence[I].Y]));
      finally
        Analyzer.Free;
      end;
    finally
      Buffer.Free;
    end;
  finally
    Reader.Free;
  end;
end;
```

## Performance

- **Processing Speed**: ~100x real-time (100 seconds audio in 1 second)
- **Memory Usage**: ~10MB per minute of audio
- **File Size**: ~2KB per second of audio (LIP format)

## Troubleshooting

### Issue: Generated LIP file doesn't work in-game
**Solution**: Ensure FPS matches your mod's expectations (12 FPS is standard)

### Issue: Mouth movements too fast/slow
**Solution**: Adjust threshold value (lower = more sensitive, higher = less sensitive)

### Issue: No mouth movements generated
**Solution**: Check audio levels; try normalizing or lowering threshold

### Issue: Unsupported WAV format
**Solution**: Convert to uncompressed PCM, 8-bit or 16-bit, mono

## Contributing

Contributions welcome! Areas for improvement:
- AI-assisted phoneme detection
- Papagayo import/export
- Real-time preview animation
- Additional format support

## License

MIT License - see LICENSE file for details

## Credits

- Reverse engineering based on original Fallout 2 engine behavior
- Inspired by LipSync Pro and similar tools
- Built with Object Pascal / Delphi / FreePascal

## Support

For issues, questions, or contributions:
- GitHub: https://github.com/yourusername/fallout-lip-generator
- Documentation: See docs/ directory
- Examples: See samples/ directory

## Version History

- **1.1** (2026-05-20): VOCK pipeline integration and phoneme table alignment
  - `PHONEME_TABLE` export convention established across all 10 language phoneme modules, replacing the older per-file helper-function pattern — runtime lookup is now entirely driven by the Pascal DEVICE and Python `vock.py`.
  - Spanish MFA table corrected: `/w/` remapped from `0x23` to `0x24` to eliminate collision with `/l/` and match the Pascal `PHONEME_TO_FRAME` reference.
  - All 10 phoneme modules validated against Pascal `PHONEME_TO_FRAME` in `src/format/uFalloutLipFormatV2.pas` — zero code-value discrepancies across English ×2, Spanish, Russian, German, French, Italian, Hungarian, Polish, Portuguese, Czech.
  - `config.py` added to VOCK pipeline (paths, LUFS, MFA env, default language).
  - `dict_lookup.py` updated: accepts phonetic language name as positional argument (e.g. `python3 dict_lookup.py english_us_arpa`), auto-discovers MFA dictionaries in default locations, loads custom dictionary from `dictionaries/` folder when present.
  - 10 language-specific custom dictionaries added under `dictionaries/` with pre-loaded Fallout 2 nouns (`geck`, `mynoc`, `tribals`, `hassleful`).
  - Helper functions for text-to-phoneme encoding are now type-safe and callable from Pascal via the FFI boundary.
  - Several improvements to the lip-sync generation model (text guidance response format, return-code mapping, error-lookup alignment).

- **1.0** (2026-05-07): Initial release
  - Core lip generation engine
  - CLI and GUI tools
  - Fallout LIP format support
  - Signal analysis and envelope detection
  - Batch processing
  - Debug export (JSON and text)
