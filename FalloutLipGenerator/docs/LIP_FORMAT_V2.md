# Fallout LIP File Format - Complete Specification

## Overview

The `.LIP` file format is used by Fallout 1 and Fallout 2 for lip-sync animation data in talking head sequences. This document describes the **actual Fallout 2 binary format (Version 2)** as reverse-engineered from the game executable.

## Important Note on FRM Files

Before understanding LIP files, you must understand FRM files:

### FRM File Naming Convention

```
RootSuffix1Suffix2[Suffix3].frm
```

- **Root**: 5-character root name (e.g., "ELDER")
- **Suffix1** (1 char): Disposition
  - `g` = Good
  - `n` = Neutral  
  - `b` = Bad
- **Suffix2** (1 char): File contents
  - `v` = Unknown (unused)
  - `f` = Fidget animation
  - `n` = Transition animation
  - `p` = Phoneme animation (9 frames)
- **Suffix3** (1+ chars): Index for fidget files (1, 2, 3...)

### Examples

- `eldergp.frm` - Good disposition, phoneme animation
- `eldernf.frm` - Neutral disposition, fidget animation  
- `elderbn.frm` - Bad to neutral transition

### Heads.lst File

Located in `/data/art/heads/`, defines available fidget files:

```
ROOT X Y Z
```

Where:
- ROOT = Root filename
- X = Number of "good" fidget files
- Y = Number of "neutral" fidget files  
- Z = Number of "bad" fidget files

### Phoneme FRM Files

- Must have **at least 9 frames**
- Engine uses only first 9 frames
- Each frame corresponds to a mouth position
- LIP file phoneme codes map to these frames

## File Structure - Version 2

### Header (44 bytes)

| Offset | Size | Type | Description |
|--------|------|------|-------------|
| 0x0000 | 4 | uint32 | Version number (2 for Fallout 2) |
| 0x0004 | 4 | uint32 | Magic: always `0x00005800` |
| 0x0008 | 4 | uint32 | Unknown (usually 0) |
| 0x000C | 4 | uint32 | Unknown (usually 0) |
| 0x0010 | 4 | uint32 | Length of unpacked ACM file |
| 0x0014 | 4 | uint32 | NUM-OF-PHONEMES: Phoneme count |
| 0x0018 | 4 | uint32 | Unknown (usually 0) |
| 0x001C | 4 | uint32 | NUM-OF-MARKERS: Always PHONEMES + 1 |
| 0x0020 | 8 | char[8] | ACM filename (null-terminated) |
| 0x0028 | 4 | char[4] | "VOC" + null terminator |

### Phoneme Table (variable)

Array of bytes, one per phoneme:

| Offset | Size | Type | Description |
|--------|------|------|-------------|
| 0x002C | 1 | uint8 | PHONEM-0: First phoneme code |
| 0x002D | 1 | uint8 | PHONEM-1: Second phoneme code |
| ... | ... | ... | ... |
| 0x002C + N | 1 | uint8 | PHONEM-N: Last phoneme code |

### Marker Table (variable)

Array of 8-byte entries (one per phoneme + 1):

For each marker i from 0 to NUM-OF-PHONEMES:

| Offset | Size | Type | Description |
|--------|------|------|-------------|
| 0x002C + N + (i×8) | 4 | uint32 | MARKER-TYPE: 0 or 1 |
| 0x002C + N + (i×8) + 4 | 4 | uint32 | MARKER-SAMPLE: Sample offset |

## Data Types

### Version
- Must be `2` for Fallout 2
- Read by fallout2.exe to determine format

### Magic Value
- Always `0x00005800`
- Read but never used by game

### Unknown Fields
- Usually set to `0x00000000`
- Read by game but not used

### ACM File Length
- Length of unpacked ACM audio file
- Divided by phoneme count (result not used)
- Probably vestigial from development

### Number of Phonemes
- Total phoneme codes in file
- Each corresponds to one frame in FRM file

### Number of Markers
- Always `NUM-OF-PHONEMES + 1`
- Extra marker is initial silence

### ACM Filename
- 8-byte null-terminated string
- Corresponds to .ACM audio file
- Example: "DLG001  " (padded with spaces)

### VOC Marker
- Always "VOC" + null
- Historical: game converts .VOC to .ACM
- Kept for compatibility

### Phoneme Codes

Single byte values from `0x00` to `0x29` (0-41 decimal):

| Code | IPA | Sound | FRM Frame | Description |
|------|-----|-------|-----------|-------------|
| 0x00 | N/A | Silent | 0 | No mouth movement |
| 0x01 | i: | bee | 3 | |
| 0x02 | ɪ | busy | 1 | |
| 0x03 | eɪ | bay | 1 | |
| 0x04 | e | end | 3 | |
| 0x05 | æ | cat | 1 | |
| 0x06 | ɑ: | arm | 1 | |
| 0x07 | ɔ: | paw | 1 | |
| 0x08 | oʊ | open | 7 | |
| 0x09 | ʊ | wolf | 8 | |
| 0x0A | u: | dew | 7 | |
| 0x0B | ʊəʳ | cure | 3 | |
| 0x0C | ɒ | slaw | 1 | |
| 0x0D | ʌ | lug | 8 | |
| 0x0E | aɪ | sky | 1 | |
| 0x0F | aʊ | now | 7 | |
| 0x10 | ɔɪ | join | 7 | |
| 0x11 | p | pin | 6 | |
| 0x12 | b | bug | 6 | |
| 0x13 | t | tip | 2 | |
| 0x14 | d | dad | 2 | |
| 0x15 | k | cat | 2 | |
| 0x16 | g | gun | 2 | |
| 0x17 | f | fat | 4 | |
| 0x18 | v | vine | 4 | |
| 0x19 | θ | thongs | 5 | |
| 0x1A | ð | leather | 5 | |
| 0x1B | s | sit | 2 | |
| 0x1C | z | zed | 2 | |
| 0x1D | ʃ | sham | 2 | |
| 0x1E | ʒ | treasure | 2 | |
| 0x1F | h | hop | 2 | |
| 0x20 | m | man | 6 | |
| 0x21 | n | net | 2 | |
| 0x22 | ŋ | ring | 2 | |
| 0x23 | l | live | 5 | |
| 0x24 | w | wit | 8 | |
| 0x25 | j | you | 2 | |
| 0x26 | r | run | 2 | |
| 0x27 | tʃ | chip | 2 | |
| 0x28 | dʒ | jam | 2 | |
| 0x29 | ** | (unused) | 8 | |

### Marker Types

- **0**: Phoneme in middle of word (not used in practice)
- **1**: Silence or word start
  - First marker (index 0) is always type 1, sample 0
  - All other markers in Fallout 2 are type 1

### Sample Offset Calculation

```
offset = time_in_seconds × 4 × sample_rate
```

Where:
- `time_in_seconds` = When phoneme occurs in audio
- `sample_rate` = 22100 Hz (ACM files)
- `4` = Mystery multiplier (possibly 16-bit stereo → 4 bytes)

Example: Phoneme at 2.13 seconds
```
2.13 × 4 × 22100 = 188,292 bytes
0x0002E138 in hex
```

## Example File

Minimal LIP file with 2 phonemes:

```
Offset  Hex Dump                          ASCII
------  --------------------------------  -----
0000    02 00 00 00 00 58 00 00      LIP header start
0008    00 00 00 00 00 00 00 00      version=2, magic=0x5800
0010    44 AC 00 00 02 00 00 00      ACM len=43332, phonemes=2
0018    00 00 00 00 03 00 00 00      unknown=0, markers=3
0020    44 4C 47 30 30 31 20 20      ACM file: "DLG001  "
0028    56 4F 43 00                   VOC\0
002C    01                            Phoneme 0: 0x01 (i:)
002D    08                            Phoneme 1: 0x08 (oʊ)
002E    01 00 00 00                   Marker 0: type=1, offset=0
0032    00 00 00 00                   Marker 1: type=1, offset=0
0036    38 31 03 00                   Marker 2: type=1, offset=188292
```

## Implementation Details

### Pascal Record Definitions

```pascal
{ LIP V2 file header }
TLipFileHeaderV2 = packed record
  Version: LongWord;           // = 2
  Magic: LongWord;             // = $00005800
  Unknown1: LongWord;          // Usually 0
  Unknown2: LongWord;          // Usually 0
  ACMFileLength: LongWord;     // Unpacked ACM length
  NumPhonemes: LongWord;       // Phoneme count
  Unknown3: LongWord;          // Usually 0
  NumMarkers: LongWord;        // = NumPhonemes + 1
  ACMFileName: array[0..7] of AnsiChar;  // Null-terminated
  VocMarker: array[0..3] of AnsiChar;    // "VOC" + null
end;

{ Phoneme entry }
TPhonemeEntry = record
  Code: Byte;                   // 0x00-0x29
end;

{ Marker entry }
TMarkerEntry = packed record
  MarkerType: LongWord;        // 0 or 1
  SampleOffset: LongWord;      // Offset in ACM
end;
```

### Reading Algorithm

1. Open file in binary mode
2. Read 44-byte header
3. Validate:
   - Version = 2
   - Magic = 0x00005800
   - NumMarkers = NumPhonemes + 1
   - VocMarker = "VOC\0"
4. Read NumPhonemes bytes of phoneme data
5. Read NumMarkers × 8 bytes of marker data
6. Validate each phoneme code ≤ 0x29
7. Validate each marker type ≤ 1
8. Validate first marker: type=1, offset=0

### Writing Algorithm

1. Fill header with appropriate values
2. Write 44-byte header
3. Write phoneme data (1 byte per phoneme)
4. Write marker data (8 bytes per marker)
5. Flush and close

## Compatibility Notes

### Fallout 1
- Uses same Version 2 format
- May have different ACM file naming
- Check original game files

### Fallout 2
- Standard format as documented
- All fields as specified
- 22100 Hz ACM audio

### Community Edition
- Fully compatible
- No modifications to format
- Works with sfall

### Modding Tools
- Most tools use this specification
- Some add extended data (ignored by game)
- Backward compatible

## Common Pitfalls

### Endianness
- All values are little-endian
- x86/x64 are little-endian
- ARM may need byte swapping

### Alignment
- Use `packed record` in Pascal
- Use `#pragma pack(1)` in C/C++
- Header = exactly 44 bytes
- Marker = exactly 8 bytes

### String Handling
- ACM filename is 8 bytes (not null-terminated in field)
- Actually null-terminated per spec
- May have trailing spaces

### Reserved Fields
- Must be zero when writing
- Should be ignored when reading
- May be used in future versions

## Performance

### Memory
- Header: 44 bytes
- Per phoneme: 1 byte
- Per marker: 8 bytes
- Typical file: 1-5 KB

### Speed
- Entire file can be memory-mapped
- No compression to decompress
- Fast random access

## Frame Timing

### FRM Frame Rate
- Talking heads: ~10-12 FPS
- Each phoneme = 1 FRM frame
- Duration = 1/FPS seconds

### LIP to FRM Mapping
```
LIP phoneme code → FRM frame number → Display duration
```

Example at 12 FPS:
- Code 0x01 (i:) → Frame 3 → 83ms
- Code 0x08 (oʊ) → Frame 7 → 83ms

## Troubleshooting

### LIP Doesn't Work in Game
- Check version = 2
- Check magic = 0x00005800
- Verify NumMarkers = NumPhonemes + 1
- Ensure corresponding FRM file exists

### Wrong Mouth Movements
- Check phoneme codes match FRM frames
- Verify marker timing
- Check ACM file exists and is valid

### File Won't Load
- Check file size ≥ 44 bytes
- Verify header values
- Check for file corruption

## References

- Fallout 2 executable (fallout2.exe)
- Original game data files
- Community reverse engineering
- sfall source code

## Change Log

### Version 1.0 (2026-05-07)
- Initial specification
- Based on Fallout 2 reverse engineering
- Complete field documentation

## License

This documentation is released under MIT License.
