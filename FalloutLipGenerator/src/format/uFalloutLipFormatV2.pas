(*
  Fallout Lip Generator - Updated LIP Format Handler
  
  This unit handles the ACTUAL Fallout 2 .LIP file format (Version 2)
  as reverse-engineered from the game executable.
  
  Format specification:
  - Version 2 format with ACM file references
  - Phoneme codes (0x00-0x29) mapping to FRM frames
  - Marker-based timing system
  
  Copyright (c) 2026
  License: MIT
*)

unit uFalloutLipFormatV2;

interface

uses
  Classes, SysUtils, Math, uSignalAnalysis, uFalloutLipFormat;

const
  // LIP file version (Fallout 2 uses version 2)
  LIP_VERSION_2 = 2;
  
  // Magic value always present
  // FIXED: Actual Fallout 2 files have magic 0x00580000 (bytes: 00 00 58 00)
  LIP_MAGIC = $00580000;
  
  // Maximum phonemes
  MAX_PHONEMES = 10000;
  
  // ACM filename length
  ACM_NAME_LENGTH = 8;
  
  // Phoneme codes (0x00-0x29)
  PHONEME_COUNT = 42; // 0x00 to 0x29 inclusive
  
  // Phoneme to FRM frame mapping
  // Maps phoneme codes to mouth states in the 9-frame FRM files
  PHONEME_TO_FRAME: array[0..PHONEME_COUNT - 1] of Integer = (
    -1,  // 0x00: Silent (no mouth movement)
     3,  // 0x01: i: (bee) -> Frame 3
     1,  // 0x02: ɪ (busy) -> Frame 1
     1,  // 0x03: eɪ (bay) -> Frame 1
     3,  // 0x04: e (end) -> Frame 3
     1,  // 0x05: æ (cat) -> Frame 1
     1,  // 0x06: ɑ: (arm) -> Frame 1
     1,  // 0x07: ɔ: (paw) -> Frame 1
     7,  // 0x08: oʊ (open) -> Frame 7
     8,  // 0x09: ʊ (wolf) -> Frame 8
     7,  // 0x0A: u: (dew) -> Frame 7
     3,  // 0x0B: ʊəʳ (cure) -> Frame 3
     1,  // 0x0C: ɒ (slaw) -> Frame 1
     8,  // 0x0D: ʌ (lug) -> Frame 8
     1,  // 0x0E: aɪ (sky) -> Frame 1
     7,  // 0x0F: aʊ (now) -> Frame 7
     7,  // 0x10: ɔɪ (join) -> Frame 7
     6,  // 0x11: p (pin) -> Frame 6
     6,  // 0x12: b (bug) -> Frame 6
     2,  // 0x13: t (tip) -> Frame 2
     2,  // 0x14: d (dad) -> Frame 2
     2,  // 0x15: k (cat) -> Frame 2
     2,  // 0x16: g (gun) -> Frame 2
     4,  // 0x17: f (fat) -> Frame 4
     4,  // 0x18: v (vine) -> Frame 4
     5,  // 0x19: θ (thongs) -> Frame 5
     5,  // 0x1A: ð (leather) -> Frame 5
     2,  // 0x1B: s (sit) -> Frame 2
     2,  // 0x1C: z (zed) -> Frame 2
     2,  // 0x1D: ʃ (sham) -> Frame 2
     2,  // 0x1E: ʒ (treasure) -> Frame 2
     2,  // 0x1F: h (hop) -> Frame 2
     2,  // 0x20: m (man) -> Frame 6 (same as p/b group)
     2,  // 0x21: n (net) -> Frame 2
     2,  // 0x22: ŋ (ring) -> Frame 2
     5,  // 0x23: l (live) -> Frame 5
     8,  // 0x24: w (wit) -> Frame 8
     2,  // 0x25: j (you) -> Frame 2
     2,  // 0x26: r (run) -> Frame 2
     2,  // 0x27: tʃ (chip) -> Frame 2
     2,  // 0x28: dʒ (jam) -> Frame 2
     8   // 0x29: ** (unused) -> Frame 8
  );

type
  { LIP file header (Version 2) }
  TLipFileHeaderV2 = packed record
    Version: LongWord;           // File type version (2)
    Magic: LongWord;             // Always 0x00005800
    Unknown1: LongWord;          // Usually 0
    Unknown2: LongWord;          // Usually 0
    ACMFileLength: LongWord;     // Length of unpacked ACM file
    NumPhonemes: LongWord;       // Total number of phoneme codes
    Unknown3: LongWord;          // Usually 0
    NumMarkers: LongWord;        // NumPhonemes + 1
    ACMFileName: array[0..7] of AnsiChar;  // ACM filename (null-terminated)
    VocMarker: array[0..3] of AnsiChar;    // "VOC" + null
  end;

  { Phoneme entry }
  TPhonemeEntry = record
    Code: Byte;                   // Phoneme code (0x00-0x29)
  end;

  { Marker entry }
  TMarkerEntry = packed record
    MarkerType: LongWord;        // 0 or 1 (silence/word start)
    SampleOffset: LongWord;      // Offset in unpacked ACM
  end;

  { Fallout LIP file (Version 2) }
  TFalloutLipFileV2 = class
  private
    FHeader: TLipFileHeaderV2;
    FPhonemes: array of TPhonemeEntry;
    FMarkers: array of TMarkerEntry;
    FFileName: string;
    
    function GetPhoneme(Index: Integer): TPhonemeEntry;
    function GetMarker(Index: Integer): TMarkerEntry;
    function GetPhonemeCount: Integer;
    function GetMarkerCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    
    { Load LIP file from disk }
    function LoadFromFile(const FileName: string): Boolean;
    
    { Load LIP file from stream }
    function LoadFromStream(Stream: TStream): Boolean;
    
    { Save LIP file to disk }
    function SaveToFile(const FileName: string): Boolean;
    
    { Save LIP file to stream }
    function SaveToStream(Stream: TStream): Boolean;
    
    { Convert from lip frames (backward compatibility) }
    procedure FromLipFrames(const LipFrames: TLipFrameArray; 
      const ACMFileName: string = '');
    
    { Convert to lip frames (for compatibility with existing code) }
    function ToLipFrames: TLipFrameArray;
    
    { Validate LIP file structure }
    function IsValid: Boolean;
    
    { Export debug information }
    function ExportDebugInfo: string;
    
    { Export to JSON }
    function ExportToJSON: string;
    
    { Export hex dump for debugging }
    function ExportHexDump: string;
    
    { Get duration in seconds }
    function GetDuration: Double;
    
    { Properties }
    property FileName: string read FFileName write FFileName;
    property Header: TLipFileHeaderV2 read FHeader;
    property Phonemes[Index: Integer]: TPhonemeEntry read GetPhoneme;
    property Markers[Index: Integer]: TMarkerEntry read GetMarker;
    property PhonemeCount: Integer read GetPhonemeCount;
    property MarkerCount: Integer read GetMarkerCount;
  end;

  { LIP Version 2 serializer }
  TFalloutLipSerializerV2 = class
  private
    FDebugMode: Boolean;
  public
    constructor Create;
    
    { Serialize lip frames to Fallout LIP V2 format }
    function Serialize(const LipFrames: TLipFrameArray; 
      const ACMFileName: string = ''): TFalloutLipFileV2;
    
    { Deserialize Fallout LIP V2 file to lip frames }
    function Deserialize(LipFile: TFalloutLipFileV2): TLipFrameArray;
    
    { Convert lip frames to binary data }
    function FramesToBinary(const LipFrames: TLipFrameArray; 
      const ACMFileName: string = ''): TBytes;
    
    { Convert binary data to lip frames }
    function BinaryToFrames(const Data: TBytes): TLipFrameArray;
    
    { Validate LIP binary data }
    function ValidateBinaryData(const Data: TBytes): Boolean;
    
    { Compare two LIP files }
    function CompareLipFiles(const File1, File2: string): string;
    
    property DebugMode: Boolean read FDebugMode write FDebugMode;
  end;

implementation

function ACMFileNameToString(const Value: array of AnsiChar): string;
var
  Len: Integer;
begin
  Len := 0;
  while (Len < Length(Value)) and (Value[Len] <> #0) do
    Inc(Len);

  SetString(Result, PAnsiChar(@Value[0]), Len);
  Result := TrimRight(Result);
end;

{ TFalloutLipFileV2 }

constructor TFalloutLipFileV2.Create;
begin
  inherited Create;
  
  // Initialize header
  FillChar(FHeader, SizeOf(FHeader), 0);
  FHeader.Version := LIP_VERSION_2;
  FHeader.Magic := LIP_MAGIC;
  FHeader.Unknown1 := 0;
  FHeader.Unknown2 := 0;
  FHeader.ACMFileLength := 0;
  FHeader.NumPhonemes := 0;
  FHeader.Unknown3 := 0;
  FHeader.NumMarkers := 0;
  FillChar(FHeader.ACMFileName, ACM_NAME_LENGTH, 0);
  FHeader.VocMarker[0] := 'V';
  FHeader.VocMarker[1] := 'O';
  FHeader.VocMarker[2] := 'C';
  FHeader.VocMarker[3] := #0;
  
  SetLength(FPhonemes, 0);
  SetLength(FMarkers, 0);
  FFileName := '';
end;

destructor TFalloutLipFileV2.Destroy;
begin
  SetLength(FPhonemes, 0);
  SetLength(FMarkers, 0);
  inherited;
end;

function TFalloutLipFileV2.GetPhoneme(Index: Integer): TPhonemeEntry;
begin
  if (Index >= 0) and (Index < Length(FPhonemes)) then
    Result := FPhonemes[Index]
  else
    raise ELipFormatError.CreateFmt('Phoneme index out of bounds: %d', [Index]);
end;

function TFalloutLipFileV2.GetMarker(Index: Integer): TMarkerEntry;
begin
  if (Index >= 0) and (Index < Length(FMarkers)) then
    Result := FMarkers[Index]
  else
    raise ELipFormatError.CreateFmt('Marker index out of bounds: %d', [Index]);
end;

function TFalloutLipFileV2.GetPhonemeCount: Integer;
begin
  Result := Length(FPhonemes);
end;

function TFalloutLipFileV2.GetMarkerCount: Integer;
begin
  Result := Length(FMarkers);
end;

function TFalloutLipFileV2.GetDuration: Double;
begin
  // Duration is based on last marker's sample offset
  // Marker offsets are stored as sampleRate * 4 byte positions.
  if (Length(FMarkers) > 0) and (FMarkers[High(FMarkers)].SampleOffset > 0) then
    Result := FMarkers[High(FMarkers)].SampleOffset / (22050.0 * 4.0)
  else
    Result := 0.0;
end;

function TFalloutLipFileV2.LoadFromFile(const FileName: string): Boolean;
var
  Stream: TStream;
begin
  Result := False;
  
  if not FileExists(FileName) then
    raise ELipReadError.CreateFmt('File not found: %s', [FileName]);
  
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := LoadFromStream(Stream);
    if Result then
      FFileName := FileName;
  finally
    Stream.Free;
  end;
end;

function TFalloutLipFileV2.LoadFromStream(Stream: TStream): Boolean;
var
  I: Integer;
begin
  Result := False;
  
  // Read header
  if Stream.Read(FHeader, SizeOf(FHeader)) <> SizeOf(FHeader) then
    raise ELipReadError.Create('Cannot read LIP file header');
  
  // Validate version
  if FHeader.Version <> LIP_VERSION_2 then
    raise ELipReadError.CreateFmt('Unsupported LIP version: %d', [FHeader.Version]);
  
  // Validate magic
  if FHeader.Magic <> LIP_MAGIC then
    raise ELipReadError.CreateFmt('Invalid LIP magic: $%8.8x', [FHeader.Magic]);
  
  // Validate phoneme count
  if FHeader.NumPhonemes > MAX_PHONEMES then
    raise ELipReadError.CreateFmt('Invalid phoneme count: %d', [FHeader.NumPhonemes]);
  
  // Validate marker count
  if FHeader.NumMarkers <> FHeader.NumPhonemes + 1 then
    raise ELipReadError.Create('Invalid marker count');
  
  // Read phonemes
  SetLength(FPhonemes, FHeader.NumPhonemes);
  if FHeader.NumPhonemes > 0 then
  begin
    if Stream.Read(FPhonemes[0], FHeader.NumPhonemes * SizeOf(TPhonemeEntry)) <>
       FHeader.NumPhonemes * SizeOf(TPhonemeEntry) then
      raise ELipReadError.Create('Cannot read phoneme data');
  end;
  
  // Read markers
  SetLength(FMarkers, FHeader.NumMarkers);
  if FHeader.NumMarkers > 0 then
  begin
    if Stream.Read(FMarkers[0], FHeader.NumMarkers * SizeOf(TMarkerEntry)) <>
       FHeader.NumMarkers * SizeOf(TMarkerEntry) then
      raise ELipReadError.Create('Cannot read marker data');
  end;
  
  Result := True;
end;

function TFalloutLipFileV2.SaveToFile(const FileName: string): Boolean;
var
  Stream: TStream;
begin
  Result := False;
  
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    Result := SaveToStream(Stream);
    if Result then
      FFileName := FileName;
  finally
    Stream.Free;
  end;
end;

function TFalloutLipFileV2.SaveToStream(Stream: TStream): Boolean;
begin
  Result := False;
  
  // Update header
  FHeader.NumPhonemes := Length(FPhonemes);
  FHeader.NumMarkers := Length(FMarkers);
  
  // Write header
  if Stream.Write(FHeader, SizeOf(FHeader)) <> SizeOf(FHeader) then
    raise ELipWriteError.Create('Cannot write LIP file header');
  
  // Write phonemes
  if Length(FPhonemes) > 0 then
  begin
    if Stream.Write(FPhonemes[0], Length(FPhonemes) * SizeOf(TPhonemeEntry)) <>
       Length(FPhonemes) * SizeOf(TPhonemeEntry) then
      raise ELipWriteError.Create('Cannot write phoneme data');
  end;
  
  // Write markers
  if Length(FMarkers) > 0 then
  begin
    if Stream.Write(FMarkers[0], Length(FMarkers) * SizeOf(TMarkerEntry)) <>
       Length(FMarkers) * SizeOf(TMarkerEntry) then
      raise ELipWriteError.Create('Cannot write marker data');
  end;
  
  Result := True;
end;

procedure TFalloutLipFileV2.FromLipFrames(const LipFrames: TLipFrameArray;
  const ACMFileName: string);
var
  I, J: Integer;
  FrameDuration, CurrentTime: Double;
  PhonemeCode: Integer;
  SampleRate: Integer;
begin
  // Clear existing data
  SetLength(FPhonemes, 0);
  SetLength(FMarkers, 0);

  // Clear entire header first, then set fields explicitly
  FillChar(FHeader, SizeOf(FHeader), 0);
  
  // Set VocMarker - this is critical for file validation
  FHeader.VocMarker[0] := 'V';
  FHeader.VocMarker[1] := 'O';
  FHeader.VocMarker[2] := 'C';
  FHeader.VocMarker[3] := #0;
  
  // Copy ACM filename (1-indexed Pascal string, so I+1)
  if Length(ACMFileName) > 0 then
  begin
    for I := 0 to Min(Length(ACMFileName) - 1, ACM_NAME_LENGTH - 1) do
      FHeader.ACMFileName[I] := AnsiChar(ACMFileName[I + 1]);
  end;
  
  // Set version and magic
  FHeader.Version := LIP_VERSION_2;
  FHeader.Magic := LIP_MAGIC;
  
  if Length(LipFrames) = 0 then
  begin
    FHeader.Unknown1 := 0;
    FHeader.Unknown2 := 0;
    FHeader.ACMFileLength := 0;
    FHeader.NumPhonemes := 0;
    FHeader.Unknown3 := 0;
    FHeader.NumMarkers := 1;

    SetLength(FMarkers, 1);
    FMarkers[0].MarkerType := 1;
    FMarkers[0].SampleOffset := 0;
    Exit;
  end;
  
  // Estimate sample rate (22050 Hz for ACM)
  SampleRate := 22050;
  
  // Count non-silent frames
  J := 0;
  for I := 0 to High(LipFrames) do
  begin
    if LipFrames[I].MouthState <> msClosed then
      Inc(J);
  end;
  
  // Allocate arrays
  SetLength(FPhonemes, J);
  SetLength(FMarkers, J + 1); // +1 for initial silence marker
  
  // Set header fields
  FHeader.Unknown1 := 0;
  FHeader.Unknown2 := 0;
  FHeader.NumPhonemes := J;
  FHeader.Unknown3 := 0;
  FHeader.NumMarkers := J + 1;
  
  // First marker is always silence at time 0
  FMarkers[0].MarkerType := 1;
  FMarkers[0].SampleOffset := 0;
  
  // Convert lip frames to phonemes and markers
  J := 0;
  CurrentTime := 0.0;
  FrameDuration := LipFrames[0].Duration;
  
  for I := 0 to High(LipFrames) do
  begin
    if LipFrames[I].MouthState <> msClosed then
    begin
      // Map mouth state to phoneme code
      // This is a simplified mapping - in reality, you'd need
      // proper phoneme detection
      case LipFrames[I].MouthState of
        msSmallOpen: PhonemeCode := $11; // p-like
        msMediumOpen: PhonemeCode := $13; // t-like
        msWideOpen: PhonemeCode := $08; // oʊ-like
      else
        PhonemeCode := $01; // i:-like
      end;
      
      Inc(J);
      if J <= High(FPhonemes) then
      begin
        FPhonemes[J - 1].Code := PhonemeCode;
        FMarkers[J].MarkerType := 1;
        FMarkers[J].SampleOffset := Round(CurrentTime * SampleRate * 4);
      end;
    end;
    
    CurrentTime := CurrentTime + FrameDuration;
  end;
  
  // Calculate ACM file length (approximate)
  if Length(FMarkers) > 0 then
    FHeader.ACMFileLength := FMarkers[High(FMarkers)].SampleOffset;
end;

function TFalloutLipFileV2.ToLipFrames: TLipFrameArray;
var
  I, J, FrameCount: Integer;
  SampleRate: Integer;
  FrameDuration, CurrentTime, NextTime: Double;
  MouthState: TMouthState;
begin
  if Length(FMarkers) < 2 then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  
  SampleRate := 22050;
  FrameDuration := 1.0 / 12.0; // Default 12 FPS
  
  // Calculate total duration
  Result := nil;
  
  // Convert markers to lip frames
  // Skip first marker (silence)
  for I := 1 to High(FMarkers) do
  begin
    // Calculate time for this phoneme
    CurrentTime := FMarkers[I].SampleOffset / (SampleRate * 4);
    if I < High(FMarkers) then
      NextTime := FMarkers[I + 1].SampleOffset / (SampleRate * 4)
    else
      NextTime := GetDuration;

    FrameDuration := Max(0.0, NextTime - CurrentTime);
    if FrameDuration = 0.0 then
      FrameDuration := 1.0 / 12.0;
    
    // Determine mouth state from phoneme code
    if FPhonemes[I - 1].Code <= High(PHONEME_TO_FRAME) then
      J := PHONEME_TO_FRAME[FPhonemes[I - 1].Code]
    else
      J := -1;
    
    case J of
      -1: MouthState := msClosed;
      0..2: MouthState := msSmallOpen;
      3..5: MouthState := msMediumOpen;
    else
      MouthState := msWideOpen;
    end;
    
    // Add frame (simplified - one frame per phoneme)
    FrameCount := Length(Result);
    SetLength(Result, FrameCount + 1);
    Result[FrameCount].Time := CurrentTime;
    Result[FrameCount].MouthState := MouthState;
    Result[FrameCount].Intensity := 0.8;
    Result[FrameCount].Duration := FrameDuration;
  end;
end;

function TFalloutLipFileV2.IsValid: Boolean;
var
  I: Integer;
begin
  Result := False;
  
  // Check version
  if FHeader.Version <> LIP_VERSION_2 then
    Exit;
  
  // Check magic
  if FHeader.Magic <> LIP_MAGIC then
    Exit;
  
  // Check phoneme count
  if FHeader.NumPhonemes > MAX_PHONEMES then
    Exit;
  
  // Check marker count
  if FHeader.NumMarkers <> FHeader.NumPhonemes + 1 then
    Exit;
  
  // Check VOC marker
  if (FHeader.VocMarker[0] <> 'V') or
     (FHeader.VocMarker[1] <> 'O') or
     (FHeader.VocMarker[2] <> 'C') or
     (FHeader.VocMarker[3] <> #0) then
    Exit;
  
  // Check phoneme codes are valid
  for I := 0 to Length(FPhonemes) - 1 do
  begin
    if FPhonemes[I].Code > $29 then
      Exit;
  end;
  
  // Check markers
  for I := 0 to Length(FMarkers) - 1 do
  begin
    if FMarkers[I].MarkerType > 1 then
      Exit;
  end;
  
  // First marker should be type 1 with offset 0
  if (Length(FMarkers) > 0) and
     ((FMarkers[0].MarkerType <> 1) or (FMarkers[0].SampleOffset <> 0)) then
    Exit;
  
  Result := True;
end;

function TFalloutLipFileV2.ExportDebugInfo: string;
var
  I: Integer;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Add('=== Fallout LIP File V2 Debug Information ===');
    SL.Add('');
    SL.Add(Format('File: %s', [FFileName]));
    SL.Add(Format('Version: %d', [FHeader.Version]));
    SL.Add(Format('Magic: $%8.8x', [FHeader.Magic]));
    SL.Add(Format('Phoneme Count: %d', [FHeader.NumPhonemes]));
    SL.Add(Format('Marker Count: %d', [FHeader.NumMarkers]));
    SL.Add(Format('ACM File Length: %d bytes', [FHeader.ACMFileLength]));
    SL.Add(Format('ACM File Name: %s', [ACMFileNameToString(FHeader.ACMFileName)]));
    SL.Add('');
    
    if Length(FPhonemes) > 0 then
    begin
      SL.Add('--- Phonemes ---');
      SL.Add(Format('%-6s %-10s %-10s', ['Index', 'Code', 'Hex']));
      for I := 0 to Min(High(FPhonemes), 99) do
      begin
        SL.Add(Format('%-6d $%-9.2x $%-9.2x',
          [I, FPhonemes[I].Code, FPhonemes[I].Code]));
      end;
      if Length(FPhonemes) > 100 then
        SL.Add(Format('... and %d more phonemes', [Length(FPhonemes) - 100]));
      SL.Add('');
    end;
    
    if Length(FMarkers) > 0 then
    begin
      SL.Add('--- Markers ---');
      SL.Add(Format('%-6s %-12s %-15s', ['Index', 'Type', 'Sample Offset']));
      for I := 0 to Min(High(FMarkers), 99) do
      begin
        SL.Add(Format('%-6d %-12d %-15d',
          [I, FMarkers[I].MarkerType, FMarkers[I].SampleOffset]));
      end;
      if Length(FMarkers) > 100 then
        SL.Add(Format('... and %d more markers', [Length(FMarkers) - 100]));
    end;
    
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function TFalloutLipFileV2.ExportToJSON: string;
var
  I: Integer;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Add('{');
    SL.Add(Format('  "version": %d,', [FHeader.Version]));
    SL.Add(Format('  "phonemeCount": %d,', [FHeader.NumPhonemes]));
    SL.Add(Format('  "markerCount": %d,', [FHeader.NumMarkers]));
    SL.Add(Format('  "acmFileLength": %d,', [FHeader.ACMFileLength]));
    SL.Add(Format('  "acmFileName": "%s",', [ACMFileNameToString(FHeader.ACMFileName)]));
    SL.Add('  "phonemes": [');
    
    for I := 0 to High(FPhonemes) do
    begin
      SL.Add(Format('    %d', [FPhonemes[I].Code]));
      if I < High(FPhonemes) then
        SL.Add(',');
    end;
    
    SL.Add('  ],');
    SL.Add('  "markers": [');
    
    for I := 0 to High(FMarkers) do
    begin
      SL.Add(Format('    {"type": %d, "offset": %d}',
        [FMarkers[I].MarkerType, FMarkers[I].SampleOffset]));
      if I < High(FMarkers) then
        SL.Add(',');
    end;
    
    SL.Add('  ]');
    SL.Add('}');
    
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function TFalloutLipFileV2.ExportHexDump: string;
var
  I: Integer;
  SL: TStringList;
  Stream: TMemoryStream;
  Buffer: TBytes;
begin
  SL := TStringList.Create;
  Stream := TMemoryStream.Create;
  try
    SaveToStream(Stream);
    SetLength(Buffer, Stream.Size);
    Stream.Position := 0;
    Stream.ReadBuffer(Buffer[0], Stream.Size);
    
    SL.Add('--- LIP V2 Hex Dump ---');
    SL.Add(Format('Total Size: %d bytes', [Length(Buffer)]));
    SL.Add('');
    
    for I := 0 to Length(Buffer) - 1 do
    begin
      if (I mod 16) = 0 then
      begin
        if I > 0 then
          SL.Add('');
        SL.Add(Format('%4.4x: ', [I]));
      end;
      SL.Strings[SL.Count - 1] := SL.Strings[SL.Count - 1] + Format('%2.2x ', [Buffer[I]]);
    end;
    
    Result := SL.Text;
  finally
    Stream.Free;
    SL.Free;
  end;
end;

{ TFalloutLipSerializerV2 }

constructor TFalloutLipSerializerV2.Create;
begin
  inherited Create;
  FDebugMode := False;
end;

function TFalloutLipSerializerV2.Serialize(
  const LipFrames: TLipFrameArray; const ACMFileName: string): TFalloutLipFileV2;
begin
  Result := TFalloutLipFileV2.Create;
  try
    Result.FromLipFrames(LipFrames, ACMFileName);
  except
    Result.Free;
    raise;
  end;
end;

function TFalloutLipSerializerV2.Deserialize(
  LipFile: TFalloutLipFileV2): TLipFrameArray;
begin
  Result := LipFile.ToLipFrames;
end;

function TFalloutLipSerializerV2.FramesToBinary(
  const LipFrames: TLipFrameArray; const ACMFileName: string): TBytes;
var
  LipFile: TFalloutLipFileV2;
  Stream: TMemoryStream;
  Size: Integer;
begin
  LipFile := TFalloutLipFileV2.Create;
  Stream := TMemoryStream.Create;
  try
    LipFile.FromLipFrames(LipFrames, ACMFileName);
    LipFile.SaveToStream(Stream);
    
    Size := Stream.Size;
    SetLength(Result, Size);
    
    if Size > 0 then
    begin
      Stream.Position := 0;
      Stream.Read(Result[0], Size);
    end;
  finally
    Stream.Free;
    LipFile.Free;
  end;
end;

function TFalloutLipSerializerV2.BinaryToFrames(
  const Data: TBytes): TLipFrameArray;
var
  LipFile: TFalloutLipFileV2;
  Stream: TMemoryStream;
begin
  LipFile := TFalloutLipFileV2.Create;
  Stream := TMemoryStream.Create;
  try
    if Length(Data) > 0 then
    begin
      Stream.Write(Data[0], Length(Data));
      Stream.Position := 0;
      
      if not LipFile.LoadFromStream(Stream) then
        raise ELipFormatError.Create('Failed to parse LIP V2 binary data');
    end;
    
    Result := LipFile.ToLipFrames;
  finally
    Stream.Free;
    LipFile.Free;
  end;
end;

function TFalloutLipSerializerV2.ValidateBinaryData(
  const Data: TBytes): Boolean;
var
  LipFile: TFalloutLipFileV2;
  Stream: TMemoryStream;
begin
  Result := False;
  
  if Length(Data) < SizeOf(TLipFileHeaderV2) then
    Exit;
  
  LipFile := TFalloutLipFileV2.Create;
  Stream := TMemoryStream.Create;
  try
    Stream.Write(Data[0], Length(Data));
    Stream.Position := 0;
    
    Result := LipFile.LoadFromStream(Stream) and LipFile.IsValid;
  finally
    Stream.Free;
    LipFile.Free;
  end;
end;

function TFalloutLipSerializerV2.CompareLipFiles(
  const File1, File2: string): string;
var
  Lip1, Lip2: TFalloutLipFileV2;
  SL: TStringList;
  I, MinPhonemes: Integer;
  DiffCount: Integer;
begin
  Lip1 := TFalloutLipFileV2.Create;
  Lip2 := TFalloutLipFileV2.Create;
  SL := TStringList.Create;
  try
    if not Lip1.LoadFromFile(File1) then
      raise ELipReadError.CreateFmt('Cannot load file: %s', [File1]);
    
    if not Lip2.LoadFromFile(File2) then
      raise ELipReadError.CreateFmt('Cannot load file: %s', [File2]);
    
    SL.Add('=== Fallout LIP V2 File Comparison ===');
    SL.Add('');
    SL.Add(Format('File 1: %s', [File1]));
    SL.Add(Format('File 2: %s', [File2]));
    SL.Add('');
    SL.Add('--- Header Comparison ---');
    SL.Add(Format('Version Match: %s (%d vs %d)',
      [BoolToStr(Lip1.Header.Version = Lip2.Header.Version, True),
       Lip1.Header.Version, Lip2.Header.Version]));
    SL.Add(Format('Phoneme Count Match: %s (%d vs %d)',
      [BoolToStr(Lip1.Header.NumPhonemes = Lip2.Header.NumPhonemes, True),
       Lip1.Header.NumPhonemes, Lip2.Header.NumPhonemes]));
    SL.Add(Format('Duration Match: %s (%.3f vs %.3f sec)',
      [BoolToStr(Abs(Lip1.GetDuration - Lip2.GetDuration) < 0.001, True),
       Lip1.GetDuration, Lip2.GetDuration]));
    SL.Add('');
    
    // Compare phonemes
    MinPhonemes := Min(Lip1.PhonemeCount, Lip2.PhonemeCount);
    DiffCount := 0;
    
    SL.Add('--- Phoneme Differences ---');
    
    for I := 0 to MinPhonemes - 1 do
    begin
      if Lip1.Phonemes[I].Code <> Lip2.Phonemes[I].Code then
      begin
        Inc(DiffCount);
        if DiffCount <= 10 then
        begin
          SL.Add(Format('Phoneme %d: $%2.2x vs $%2.2x',
            [I, Lip1.Phonemes[I].Code, Lip2.Phonemes[I].Code]));
        end;
      end;
    end;
    
    if DiffCount > 10 then
      SL.Add(Format('... and %d more differences', [DiffCount - 10]));
    
    SL.Add('');
    SL.Add(Format('Total Phoneme Differences: %d out of %d', 
      [DiffCount, MinPhonemes]));
    
    if Lip1.PhonemeCount <> Lip2.PhonemeCount then
      SL.Add(Format('Phoneme count mismatch: %d difference',
        [Abs(Lip1.PhonemeCount - Lip2.PhonemeCount)]));
    
    Result := SL.Text;
  finally
    SL.Free;
    Lip2.Free;
    Lip1.Free;
  end;
end;

end.
