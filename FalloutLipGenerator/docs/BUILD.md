# Fallout Lip Generator - Build Instructions

## Quick Start

### Windows (Delphi)

1. Open Delphi 11 or later
2. Open `src/cli/wav2lip.dpr` to build CLI tool
3. Open `src/gui/LipGeneratorGUI.dpr` to build GUI application
4. Compile and run

### Cross-Platform (FreePascal/Lazarus)

1. Install Lazarus 2.2+ with FPC 3.2+
2. Open project files in Lazarus
3. Build all units
4. Compile executables

### Using the Build Script

```bash
# Compile build script
fpc build.pas

# Run build
./build
```

## Project Structure

```
FalloutLipGenerator/
├── src/
│   ├── audio/          # Audio processing
│   │   ├── uAudioBuffer.pas    # Audio buffer management
│   │   └── uWavReader.pas      # WAV file reader
│   ├── lip/            # Signal analysis
│   │   └── uSignalAnalysis.pas # Lip generation algorithms
│   ├── format/         # File format handling
│   │   └── uFalloutLipFormat.pas # LIP file serialization
│   ├── core/           # Core engine
│   │   └── uLipGenerator.pas   # Main generator
│   ├── cli/            # Command-line interface
│   │   └── wav2lip.dpr         # CLI entry point
│   ├── gui/            # Graphical interface
│   │   ├── LipGeneratorGUI.dpr # GUI entry point
│   │   └── uMainForm.pas       # Main form
│   └── uFalloutLipGenerator.pas # Public API
├── tests/              # Unit tests
│   └── uLipGeneratorTests.pas
├── samples/            # Sample audio files
├── docs/               # Documentation
├── bin/                # Build output
├── build.pas           # Build script
├── README.md           # Main documentation
└── kilo.json           # Project configuration
```

## Dependencies

- **None** - Pure Object Pascal implementation
- No external libraries required
- No DLLs or runtime dependencies

## Unit Dependencies

```
uLipGenerator
  ├── uAudioBuffer
  ├── uWavReader
  ├── uSignalAnalysis
  │   └── uAudioBuffer
  └── uFalloutLipFormat
      └── uSignalAnalysis
```

## Building Units

All units compile with standard Delphi or FreePascal settings:
- Syntax mode: `{$mode objfpc}` or `{$mode delphi}`
- No special compiler directives required
- Unicode support built-in

## Testing

Run unit tests with:

```bash
# Using FPCUnit
fpc testrunner.pas
./testrunner

# Or use Lazarus test runner
lazarus --build-test-runner
```

## Distribution

### Windows
- Single executable (no DLLs)
- No installation required
- Portable application

### Linux/macOS
- Compile with FPC
- May require GTK2 (GUI)
- Static linking recommended

## Optimization

For release builds:
- Enable optimizations (`-O3`)
- Disable debug info (`-g-`)
- Strip symbols (`-s`)
- Use release mode in Lazarus

## Troubleshooting

### Compilation Errors

**"Unit not found"**
- Ensure all source files are in correct directories
- Check search paths in project options
- Verify unit names match file names

**"Syntax error"**
- Ensure Delphi mode or ObjFPC mode is set
- Check for missing semicolons or keywords

**"Out of memory"**
- Increase heap size for large audio files
- Process in chunks if necessary

### Runtime Errors

**"Invalid WAV format"**
- Ensure file is uncompressed PCM
- Check bit depth (8 or 16-bit)
- Verify mono channel

**"Access violation"**
- Check file paths exist
- Verify memory allocation for large files
- Ensure proper cleanup in exception handlers

## Continuous Integration

Example GitHub Actions workflow:

```yaml
name: Build
on: [push, pull_request]
jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build CLI
        run: |
          "C:\Program Files\Embarcadero\Studio\22.0\bin\msbuild.exe" src/cli/wav2lip.dproj
      - name: Build GUI
        run: |
          "C:\Program Files\Embarcadero\Studio\22.0\bin\msbuild.exe" src/gui/LipGeneratorGUI.dproj
```

## Version Control

Recommended `.gitignore`:

```
# Build outputs
*.exe
*.dll
*.so
*.dylib
*.o
*.ppu
*.dcu

# IDE files
*.dsk
*.local
*.identcache
*.tvsconfig

# User files
*.lip
*.wav

# Logs
*.log
build.log
```

## License

MIT License - see LICENSE file for details
