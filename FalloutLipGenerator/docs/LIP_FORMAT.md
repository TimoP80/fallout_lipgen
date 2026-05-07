# Fallout LIP File Format Documentation

## Overview

The `.LIP` file format is used by Fallout 1 and Fallout 2 for lip-sync animation data in talking head sequences. This document describes the binary format specification and provides implementation details for reading and writing LIP files.

## File Structure

### Header (24 bytes)

| Offset | Size | Type | Description |
|--------|------|------|-------------|
| 0x00 | 4 | char[4] | File signature: `'L' 'I' 'P' '\0'` |
| 0x04 | 2 | uint16 | Version number (typically 1) |
| 0x06 | 2 | uint16 | Number of animation frames |
| 0x08 | 2 | uint16 | Frames per second (10, 12, or 15) |
| 0x0A | 4 | uint32 | Duration in milliseconds |
| 0x0E | 8 | byte[8] | Reserved (must be zero) |

### Frame Table (variable)

Array of frame entries, each 6 bytes:

| Offset | Size | Type | Description |
|--------|------|------|-------------|
| 0x00 | 2 | uint16 | Time offset from start (milliseconds) |
| 0x02 | 1 | uint8 | Mouth state (0-3) |
| 0x03 | 1 | uint8 | Intensity (0-255) |
| 0x04 | 1 | uint8 | Reserved (must be zero) |

### Extended Data (optional)

If present, follows the frame table:

| Offset | Size | Type | Description |
|--------|------|------|-------------|
| 0x00 | 1 | uint8 | Phoneme code |
| 0x01 | 1 | uint8 | Confidence (0-100) |
| 0x02 | 2 | uint8[2] | Reserved |

## Data Types

### Mouth States

| Value | Constant | Description |
|-------|----------|-------------|
| 0 | LIP_MOUTH_CLOSED | Mouth closed (silence) |
| 1 | LIP_MOUTH_SMALL_OPEN | Slight opening (m, b, p) |
| 2 | LIP_MOUTH_MEDIUM_OPEN | Medium opening (n, d, t) |
| 3 | LIP_MOUTH_WIDE_OPEN | Wide opening (a, o, e) |

### Frame Timing

- Time offsets are relative to the start of the animation
- Must be monotonically increasing
- Maximum value: 65535 ms (~65 seconds)
- Typical precision: 83 ms (at 12 FPS)

### Intensity Values

- 0 = No mouth movement
- 255 = Maximum mouth opening
- Maps to visual blend weights in the engine

## Implementation Details

### Pascal Record Definitions

```pascal
{ LIP file header }
TLipFileHeader = packed record
  Signature: array[0..3] of AnsiChar;  // 'LIP' + null
  Version: Word;                        // Version number
  FrameCount: Word;                     // Number of frames
  FPS: Word;                            // Frames per second
  Duration: LongWord;                   // Duration in milliseconds
  Reserved: array[0..7] of Byte;        // Reserved
end;

{ Lip frame entry }
TLipFrameEntry = packed record
  TimeOffset: Word;                     // Time offset in ms
  MouthState: Byte;                     // Mouth state (0-3)
  Intensity: Byte;                      // Intensity (0-255)
  Reserved: Byte;                       // Reserved
end;
```

### C/C++ Definitions

```c
#pragma pack(push, 1)
typedef struct {
    char signature[4];      // 'L', 'I', 'P', '\0'
    uint16_t version;       // Version number
    uint16_t frameCount;    // Number of frames
    uint16_t fps;           // Frames per second
    uint32_t duration;      // Duration in milliseconds
    uint8_t reserved[8];    // Reserved
} LipHeader;

typedef struct {
    uint16_t timeOffset;    // Time offset in milliseconds
    uint8_t mouthState;     // Mouth state (0-3)
    uint8_t intensity;      // Intensity (0-255)
    uint8_t reserved;       // Reserved
} LipFrameEntry;
#pragma pack(pop)
```

### Python Definitions

```python
import struct
from dataclasses import dataclass

@dataclass
class LipHeader:
    signature: bytes  # 4 bytes
    version: int      # H
    frame_count: int  # H
    fps: int          # H
    duration: int     # I
    reserved: bytes   # 8 bytes
    
    def pack(self):
        return struct.pack('<4sHHHI8s',
            self.signature,
            self.version,
            self.frame_count,
            self.fps,
            self.duration,
            self.reserved)

@dataclass
class LipFrame:
    time_offset: int   # H
    mouth_state: int   # B
    intensity: int     # B
    reserved: int      # B
    
    def pack(self):
        return struct.pack('<HBBxB',
            self.time_offset,
            self.mouth_state,
            self.intensity,
            self.reserved)
```

## Reading LIP Files

### Algorithm

1. Open file in binary mode
2. Read 24-byte header
3. Validate signature ('LIP\0')
4. Validate version (should be 1)
5. Validate FPS (should be 10, 12, or 15)
6. Read frameCount × 6 bytes of frame data
7. (Optional) Read extended data if present
8. Validate frame time offsets are monotonic

### Pascal Implementation

```pascal
function LoadLipFile(const FileName: string): Boolean;
var
  Stream: TFileStream;
  Header: TLipFileHeader;
  Frames: array of TLipFrameEntry;
  I: Integer;
begin
  Result := False;
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
    // Read header
    if Stream.Read(Header, SizeOf(Header)) <> SizeOf(Header) then
      Exit;
    
    // Validate signature
    if (Header.Signature[0] <> 'L') or
       (Header.Signature[1] <> 'I') or
       (Header.Signature[2] <> 'P') or
       (Header.Signature[3] <> #0) then
      Exit;
    
    // Validate version
    if Header.Version <> 1 then
      Exit;
    
    // Validate frame count
    if Header.FrameCount > 10000 then
      Exit;
    
    // Read frames
    SetLength(Frames, Header.FrameCount);
    if Header.FrameCount > 0 then
    begin
      if Stream.Read(Frames[0], Header.FrameCount * 6) <>
         Header.FrameCount * 6 then
        Exit;
    end;
    
    // Validate monotonic time offsets
    for I := 1 to High(Frames) do
      if Frames[I].TimeOffset < Frames[I-1].TimeOffset then
        Exit;
    
    Result := True;
  finally
    Stream.Free;
  end;
end;
```

## Writing LIP Files

### Algorithm

1. Calculate duration from last frame time offset
2. Fill header with appropriate values
3. Write 24-byte header
4. Write frame data (6 bytes per frame)
5. (Optional) Write extended data
6. Flush and close file

### Pascal Implementation

```pascal
function SaveLipFile(const FileName: string; 
  const Frames: array of TLipFrameEntry; FPS: Word): Boolean;
var
  Stream: TFileStream;
  Header: TLipFileHeader;
  I: Integer;
begin
  Result := False;
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    // Fill header
    Header.Signature := 'LIP'#0;
    Header.Version := 1;
    Header.FrameCount := Length(Frames);
    Header.FPS := FPS;
    
    if Length(Frames) > 0 then
      Header.Duration := Frames[High(Frames)].TimeOffset
    else
      Header.Duration := 0;
    
    FillChar(Header.Reserved, 8, 0);
    
    // Write header
    Stream.Write(Header, SizeOf(Header));
    
    // Write frames
    for I := 0 to High(Frames) do
      Stream.Write(Frames[I], 6);
    
    Result := True;
  finally
    Stream.Free;
  end;
end;
```

## Validation Rules

### Header Validation

- [ ] Signature must be 'LIP\0'
- [ ] Version must be 1
- [ ] FPS must be 10, 12, or 15
- [ ] Frame count must be ≤ 10000 (practical limit)
- [ ] Reserved bytes must be zero

### Frame Validation

- [ ] Mouth state must be 0-3
- [ ] Time offsets must be monotonically increasing
- [ ] Time offsets must not exceed 65535
- [ ] First frame time offset should be 0
- [ ] Reserved byte must be 0

### Consistency Checks

- [ ] Duration should match last frame time offset
- [ ] Frame count should match actual data
- [ ] File size should be 24 + (frameCount × 6) + (optional extended data)

## Common Pitfalls

### Endianness

- All values are little-endian
- x86/x64 systems are little-endian by default
- ARM systems may require byte swapping

### Alignment

- Use `packed record` in Pascal to avoid padding
- Use `#pragma pack(1)` in C/C++
- Structure size should be exactly 24 bytes (header) and 6 bytes (frame)

### String Handling

- Signature is 4 bytes, not null-terminated string
- Compare individual bytes, not as string

### Reserved Fields

- Must be zero when writing
- Should be ignored when reading
- May be used in future versions

## Example Files

### Minimal File (1 frame)

```
Offset  Hex Dump                          ASCII
------  --------------------------------  -----
0000    4C 49 50 00 01 00 01 00 0C 00 00 00  LIP............
000C    00 00 00 00 00 00 00 00              ........
0014    00 00 00 00 00 00                    ......
```

Interpretation:
- Signature: 'LIP\0'
- Version: 1
- Frame count: 1
- FPS: 12
- Duration: 0 ms
- 1 frame at time 0, mouth closed, intensity 0

### Typical File (10 frames, 12 FPS)

```
Offset  Hex Dump                          ASCII
------  --------------------------------  -----
0000    4C 49 50 00 01 00 0A 00 0C 00       LIP..........
...
0016    00 00 00 00 00 00                   ...... Frame 0
001C    58 02 01 80 00 00                   X.....  Frame 1 (500ms, small open)
0022    B0 04 02 C0 00 00                   ......  Frame 2 (1200ms, medium open)
...
```

## Performance Considerations

### Memory Usage

- Header: 24 bytes
- Per frame: 6 bytes
- 1000 frames = ~6 KB
- Typical file size: 1-10 KB

### Loading Speed

- Entire file can be memory-mapped
- No compression to decompress
- Fast random access to frames

### Frame Interpolation

- Engine may interpolate between frames
- Time offsets don't need to match FPS exactly
- Can have variable frame timing

## Compatibility Notes

### Fallout 1

- Uses same format
- May have different FPS preferences
- Check original game files for reference

### Fallout 2

- Standard format as documented
- 12 FPS is most common
- Used in all talking head sequences

### Community Edition

- Fully compatible
- No modifications to format
- Works with sfall

### Modding Tools

- Most tools use this specification
- Some add extended data section
- Backward compatible (ignore unknown data)

## References

- Original Fallout 2 game files
- Interplay documentation (if available)
- Community reverse engineering efforts
- sfall source code

## Change Log

### Version 1.0 (2026-05-07)
- Initial specification
- Based on reverse engineering
- Compatible with Fallout 2

## License

This documentation is released under MIT License.

## Contact

For corrections or additions, please contribute to the project repository.
