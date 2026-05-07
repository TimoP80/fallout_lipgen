(*
  Fallout Lip Generator - Fallout LIP Format Serialization Unit
  
  This unit handles reading and writing Fallout 1/2 compatible .LIP files.
  The .LIP format stores lip-sync animation data for talking heads.
  
  File Format Structure (based on reverse engineering):
  - Header with file signature and metadata
  - Frame table with timing and mouth state data
  - Optional extended data section
  
  Copyright (c) 2026
  License: MIT
*)

unit uFalloutLipFormat;

interface

uses
  Classes, SysUtils, Math, StrUtils, uSignalAnalysis;

const
  // Fallout LIP file signature
  LIP_SIGNATURE: array[0..3] of AnsiChar = ('L', 'I', 'P', #0);
  
  // Supported FPS values
  LIP_FPS_10 = 10;
  LIP_FPS_12 = 12;
  LIP_FPS_15 = 15;
  
  // Mouth state values (matching Fallout internal representation)
  LIP_MOUTH_CLOSED = 0;
  LIP_MOUTH_SMALL_OPEN = 1;
  LIP_MOUTH_MEDIUM_OPEN = 2;
  LIP_MOUTH_WIDE_OPEN = 3;

  // Maximum frames in a LIP file (practical limit)
  MAX_LIP_FRAMES = 10000;

type
  { Fallout LIP file header }
  TLipFileHeader = packed record
    Signature: array[0..3] of AnsiChar;  // 'LIP' + null terminator
    Version: Word;                        // Version number (typically 1)
    FrameCount: Word;                     // Number of frames
    FPS: Word;                            // Frames per second (10, 12, or 15)
    Duration: LongWord;                   // Duration in milliseconds
    Reserved: array[0..7] of Byte;        // Reserved for future use
  end;

  { Lip frame entry in the frame table }
  TLipFrameEntry = packed record
    TimeOffset: Word;                     // Time offset in milliseconds from start
    MouthState: Byte;                     // Mouth state (0-3)
    Intensity: Byte;                      // Intensity (0-255)
    Reserved: Byte;                       // Reserved
  end;

  { Extended frame information (optional) }
  TLipFrameExtended = packed record
    PhonemeCode: Byte;                    // Phoneme approximation code
    Confidence: Byte;                     // Confidence level (0-100)
    Reserved2: array[0..1] of Byte;
  end;

  { Fallout LIP file structure }
  TFalloutLipFile = class
  private
    FHeader: TLipFileHeader;
    FFrames: array of TLipFrameEntry;
    FExtendedFrames: array of TLipFrameExtended;
    FHasExtendedData: Boolean;
    FFileName: string;
    
    function GetFrame(Index: Integer): TLipFrameEntry;
    function GetFrameCount: Integer;
    function GetDuration: Double;
    procedure SetFrame(Index: Integer; const Value: TLipFrameEntry);
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
    
    { Add a frame }
    procedure AddFrame(TimeOffset: Word; MouthState, Intensity: Byte);
    
    { Clear all frames }
    procedure Clear;
    
    { Validate LIP file structure }
    function IsValid: Boolean;
    
    { Convert to lip frames array }
    function ToLipFrames: TLipFrameArray;
    
    { Export debug information }
    function ExportDebugInfo: string;
    
    { Export to JSON }
    function ExportToJSON: string;
    
    { Import from lip frames array }
    procedure FromLipFrames(const LipFrames: TLipFrameArray; FPS: Integer);
    
    { Properties }
    property FileName: string read FFileName write FFileName;
    property Header: TLipFileHeader read FHeader;
    property Frames[Index: Integer]: TLipFrameEntry read GetFrame write SetFrame; default;
    property FrameCount: Integer read GetFrameCount;
    property Duration: Double read GetDuration;
    property HasExtendedData: Boolean read FHasExtendedData write FHasExtendedData;
  end;

  { LIP file serializer }
  TFalloutLipSerializer = class
  private
    FIncludeExtendedData: Boolean;
    FDebugMode: Boolean;
  public
    constructor Create;
    
    { Serialize lip frames to Fallout LIP format }
    function Serialize(const LipFrames: TLipFrameArray; FPS: Integer): TFalloutLipFile;
    
    { Deserialize Fallout LIP file to lip frames }
    function Deserialize(LipFile: TFalloutLipFile): TLipFrameArray;
    
    { Convert lip frames to binary data }
    function FramesToBinary(const LipFrames: TLipFrameArray; FPS: Integer): TBytes;
    
    { Convert binary data to lip frames }
    function BinaryToFrames(const Data: TBytes): TLipFrameArray;
    
    { Validate LIP binary data }
    function ValidateBinaryData(const Data: TBytes): Boolean;
    
    { Compare two LIP files }
    function CompareLipFiles(const File1, File2: string): string;
    
    property IncludeExtendedData: Boolean read FIncludeExtendedData write FIncludeExtendedData;
    property DebugMode: Boolean read FDebugMode write FDebugMode;
  end;

  { LIP file reader utility }
  TLipFileReader = class
  private
    FLipFile: TFalloutLipFile;
  public
    constructor Create;
    destructor Destroy; override;
    
    { Read and parse LIP file }
    function ReadFile(const FileName: string): Boolean;
    
    { Get frame at specific time }
    function GetFrameAtTime(TimeSeconds: Double): TLipFrameEntry;
    
    { Get mouth state at specific time }
    function GetMouthStateAtTime(TimeSeconds: Double): Integer;
    
    { Export hex dump }
    function ExportHexDump: string;
    
    { Export timing visualization }
    function ExportTimingVisualization(Width: Integer = 80): string;
    
    property LipFile: TFalloutLipFile read FLipFile;
  end;

  { Exceptions }
  ELipFormatError = class(Exception);
  ELipReadError = class(Exception);
  ELipWriteError = class(Exception);

implementation

{ TFalloutLipFile }

constructor TFalloutLipFile.Create;
begin
  inherited Create;
  
  // Initialize header
  FillChar(FHeader, SizeOf(FHeader), 0);
  Move(LIP_SIGNATURE, FHeader.Signature, SizeOf(FHeader.Signature));
  FHeader.Version := 1;
  FHeader.FPS := LIP_FPS_12;
  FHeader.Duration := 0;
  
  SetLength(FFrames, 0);
  SetLength(FExtendedFrames, 0);
  FHasExtendedData := False;
  FFileName := '';
end;

destructor TFalloutLipFile.Destroy;
begin
  Clear;
  inherited;
end;

function TFalloutLipFile.GetFrame(Index: Integer): TLipFrameEntry;
begin
  if (Index >= 0) and (Index < Length(FFrames)) then
    Result := FFrames[Index]
  else
    raise ELipFormatError.CreateFmt('Frame index out of bounds: %d', [Index]);
end;

function TFalloutLipFile.GetFrameCount: Integer;
begin
  Result := Length(FFrames);
end;

function TFalloutLipFile.GetDuration: Double;
begin
  Result := FHeader.Duration / 1000.0;
end;

procedure TFalloutLipFile.SetFrame(Index: Integer; const Value: TLipFrameEntry);
begin
  if (Index >= 0) and (Index < Length(FFrames)) then
    FFrames[Index] := Value
  else
    raise ELipFormatError.CreateFmt('Frame index out of bounds: %d', [Index]);
end;

function TFalloutLipFile.LoadFromFile(const FileName: string): Boolean;
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

function TFalloutLipFile.LoadFromStream(Stream: TStream): Boolean;
var
  I: Integer;
  ExtendedDataOffset: LongWord;
begin
  Result := False;
  
  // Read header
  if Stream.Read(FHeader, SizeOf(FHeader)) <> SizeOf(FHeader) then
    raise ELipReadError.Create('Cannot read LIP file header');
  
  // Validate signature
  if (FHeader.Signature[0] <> 'L') or (FHeader.Signature[1] <> 'I') or
     (FHeader.Signature[2] <> 'P') or (FHeader.Signature[3] <> #0) then
    raise ELipReadError.Create('Invalid LIP file signature');
  
  // Validate frame count
  if FHeader.FrameCount > MAX_LIP_FRAMES then
    raise ELipReadError.CreateFmt('Invalid frame count: %d', [FHeader.FrameCount]);
  
  // Read frame table
  SetLength(FFrames, FHeader.FrameCount);
  
  if FHeader.FrameCount > 0 then
  begin
    if Stream.Read(FFrames[0], FHeader.FrameCount * SizeOf(TLipFrameEntry)) <>
       FHeader.FrameCount * SizeOf(TLipFrameEntry) then
      raise ELipReadError.Create('Cannot read LIP frame table');
  end;
  
  // Check for extended data (optional)
  ExtendedDataOffset := SizeOf(FHeader) + (FHeader.FrameCount * SizeOf(TLipFrameEntry));
  
  if Stream.Position < Stream.Size then
  begin
    FHasExtendedData := True;
    SetLength(FExtendedFrames, FHeader.FrameCount);
    
    if Stream.Read(FExtendedFrames[0], FHeader.FrameCount * SizeOf(TLipFrameExtended)) <=
       (FHeader.FrameCount * SizeOf(TLipFrameExtended) - 1) then
    begin
      // Extended data might not be complete, but that's okay
      FHasExtendedData := True;
    end;
  end
  else
  begin
    FHasExtendedData := False;
    SetLength(FExtendedFrames, 0);
  end;
  
  Result := True;
end;

function TFalloutLipFile.SaveToFile(const FileName: string): Boolean;
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

function TFalloutLipFile.SaveToStream(Stream: TStream): Boolean;
var
  I: Integer;
begin
  Result := False;
  
  // Update header
  FHeader.FrameCount := Length(FFrames);
  
  // Calculate duration
  if (FHeader.FrameCount > 0) and (FHeader.FPS > 0) then
    FHeader.Duration := Round((FHeader.FrameCount / FHeader.FPS) * 1000)
  else
    FHeader.Duration := 0;
  
  // Write header
  if Stream.Write(FHeader, SizeOf(FHeader)) <> SizeOf(FHeader) then
    raise ELipWriteError.Create('Cannot write LIP file header');
  
  // Write frame table
  if FHeader.FrameCount > 0 then
  begin
    if Stream.Write(FFrames[0], FHeader.FrameCount * SizeOf(TLipFrameEntry)) <>
       FHeader.FrameCount * SizeOf(TLipFrameEntry) then
      raise ELipWriteError.Create('Cannot write LIP frame table');
  end;
  
  // Write extended data if present
  if FHasExtendedData and (Length(FExtendedFrames) = FHeader.FrameCount) then
  begin
    if Stream.Write(FExtendedFrames[0], FHeader.FrameCount * SizeOf(TLipFrameExtended)) <>
       FHeader.FrameCount * SizeOf(TLipFrameExtended) then
      raise ELipWriteError.Create('Cannot write LIP extended data');
  end;
  
  Result := True;
end;

procedure TFalloutLipFile.AddFrame(TimeOffset: Word; MouthState, Intensity: Byte);
var
  Index: Integer;
begin
  Index := Length(FFrames);
  SetLength(FFrames, Index + 1);
  
  FFrames[Index].TimeOffset := TimeOffset;
  FFrames[Index].MouthState := MouthState;
  FFrames[Index].Intensity := Intensity;
  FFrames[Index].Reserved := 0;
  
  // Update header
  FHeader.FrameCount := Length(FFrames);
end;

procedure TFalloutLipFile.Clear;
begin
  SetLength(FFrames, 0);
  SetLength(FExtendedFrames, 0);
  FHasExtendedData := False;
  
  FillChar(FHeader, SizeOf(FHeader), 0);
  Move(LIP_SIGNATURE, FHeader.Signature, SizeOf(FHeader.Signature));
  FHeader.Version := 1;
  FHeader.FPS := LIP_FPS_12;
end;

function TFalloutLipFile.IsValid: Boolean;
var
  I: Integer;
begin
  Result := False;
  
  // Check signature
  if (FHeader.Signature[0] <> 'L') or (FHeader.Signature[1] <> 'I') or
     (FHeader.Signature[2] <> 'P') or (FHeader.Signature[3] <> #0) then
    Exit;
  
  // Check version
  if FHeader.Version <> 1 then
    Exit;
  
  // Check frame count
  if FHeader.FrameCount > MAX_LIP_FRAMES then
    Exit;
  
  // Check FPS
  if not (FHeader.FPS in [LIP_FPS_10, LIP_FPS_12, LIP_FPS_15]) then
    Exit;
  
  // Check frame data
  for I := 0 to Length(FFrames) - 1 do
  begin
    if FFrames[I].MouthState > LIP_MOUTH_WIDE_OPEN then
      Exit;
    
    // Time offsets should be monotonically increasing
    if (I > 0) and (FFrames[I].TimeOffset < FFrames[I-1].TimeOffset) then
      Exit;
  end;
  
  Result := True;
end;

function TFalloutLipFile.ToLipFrames: TLipFrameArray;
var
  I: Integer;
  FrameDuration: Double;
begin
  if FHeader.FPS = 0 then
    FrameDuration := 1.0 / LIP_FPS_12
  else
    FrameDuration := 1.0 / FHeader.FPS;
  
  SetLength(Result, FHeader.FrameCount);
  
  for I := 0 to FHeader.FrameCount - 1 do
  begin
    Result[I].Time := FFrames[I].TimeOffset / 1000.0;
    Result[I].MouthState := IndexToMouthState(FFrames[I].MouthState);
    Result[I].Intensity := FFrames[I].Intensity / 255.0;
    Result[I].Duration := FrameDuration;
  end;
end;

function TFalloutLipFile.ExportDebugInfo: string;
var
  I: Integer;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Add('=== Fallout LIP File Debug Information ===');
    SL.Add('');
    SL.Add(Format('File: %s', [FFileName]));
    SL.Add(Format('Signature: %s', [FHeader.Signature]));
    SL.Add(Format('Version: %d', [FHeader.Version]));
    SL.Add(Format('Frame Count: %d', [FHeader.FrameCount]));
    SL.Add(Format('FPS: %d', [FHeader.FPS]));
    SL.Add(Format('Duration: %.3f seconds', [GetDuration]));
    SL.Add(Format('Has Extended Data: %s', [BoolToStr(FHasExtendedData, True)]));
    SL.Add('');
    SL.Add('--- Frame Table ---');
    SL.Add(Format('%-6s %-12s %-12s %-10s %-10s', ['Index', 'Time (ms)', 'Time (s)', 'Mouth', 'Intensity']));
    
    for I := 0 to Min(FHeader.FrameCount - 1, 99) do // Limit output
    begin
      SL.Add(Format('%-6d %-12d %-12.3f %-12s %-10d',
        [I,
         FFrames[I].TimeOffset,
         FFrames[I].TimeOffset / 1000.0,
         MouthStateToString(IndexToMouthState(FFrames[I].MouthState)),
         FFrames[I].Intensity]));
    end;
    
    if FHeader.FrameCount > 100 then
      SL.Add(Format('... and %d more frames', [FHeader.FrameCount - 100]));
    
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function TFalloutLipFile.ExportToJSON: string;
var
  I: Integer;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Add('{');
    SL.Add(Format('  "duration": %.3f,', [GetDuration]));
    SL.Add(Format('  "fps": %d,', [FHeader.FPS]));
    SL.Add(Format('  "frameCount": %d,', [FHeader.FrameCount]));
    SL.Add('  "frames": [');
    
    for I := 0 to FHeader.FrameCount - 1 do
    begin
      SL.Add(Format('    {"time": %.3f, "mouth": %d, "intensity": %d}',
        [FFrames[I].TimeOffset / 1000.0,
         FFrames[I].MouthState,
         FFrames[I].Intensity]));
      
      if I < FHeader.FrameCount - 1 then
        SL.Add(',');
    end;
    
    SL.Add('  ]');
    SL.Add('}');
    
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

procedure TFalloutLipFile.FromLipFrames(const LipFrames: TLipFrameArray; FPS: Integer);
var
  I: Integer;
  FrameDuration: Double;
begin
  Clear;
  
  // Set FPS
  case FPS of
    10: FHeader.FPS := LIP_FPS_10;
    12: FHeader.FPS := LIP_FPS_12;
    15: FHeader.FPS := LIP_FPS_15;
  else
    FHeader.FPS := LIP_FPS_12;
  end;
  
  FrameDuration := 1.0 / FPS;
  
  // Convert lip frames to LIP format
  SetLength(FFrames, Length(LipFrames));
  
  for I := 0 to Length(LipFrames) - 1 do
  begin
    FFrames[I].TimeOffset := Round(LipFrames[I].Time * 1000);
    FFrames[I].MouthState := MouthStateToIndex(LipFrames[I].MouthState);
    FFrames[I].Intensity := Round(LipFrames[I].Intensity * 255);
    FFrames[I].Reserved := 0;
  end;
  
  FHeader.FrameCount := Length(FFrames);
  FHeader.Duration := Round((FHeader.FrameCount / FPS) * 1000);
end;

{ TFalloutLipSerializer }

constructor TFalloutLipSerializer.Create;
begin
  inherited Create;
  FIncludeExtendedData := False;
  FDebugMode := False;
end;

function TFalloutLipSerializer.Serialize(const LipFrames: TLipFrameArray; FPS: Integer): TFalloutLipFile;
begin
  Result := TFalloutLipFile.Create;
  try
    Result.FromLipFrames(LipFrames, FPS);
    Result.HasExtendedData := FIncludeExtendedData;
  except
    Result.Free;
    raise;
  end;
end;

function TFalloutLipSerializer.Deserialize(LipFile: TFalloutLipFile): TLipFrameArray;
begin
  Result := LipFile.ToLipFrames;
end;

function TFalloutLipSerializer.FramesToBinary(const LipFrames: TLipFrameArray; FPS: Integer): TBytes;
var
  LipFile: TFalloutLipFile;
  Stream: TMemoryStream;
  Size: Integer;
begin
  LipFile := TFalloutLipFile.Create;
  Stream := TMemoryStream.Create;
  try
    LipFile.FromLipFrames(LipFrames, FPS);
    LipFile.HasExtendedData := FIncludeExtendedData;
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

function TFalloutLipSerializer.BinaryToFrames(const Data: TBytes): TLipFrameArray;
var
  LipFile: TFalloutLipFile;
  Stream: TMemoryStream;
begin
  LipFile := TFalloutLipFile.Create;
  Stream := TMemoryStream.Create;
  try
    if Length(Data) > 0 then
    begin
      Stream.Write(Data[0], Length(Data));
      Stream.Position := 0;
      
      if not LipFile.LoadFromStream(Stream) then
        raise ELipFormatError.Create('Failed to parse LIP binary data');
    end;
    
    Result := LipFile.ToLipFrames;
  finally
    Stream.Free;
    LipFile.Free;
  end;
end;

function TFalloutLipSerializer.ValidateBinaryData(const Data: TBytes): Boolean;
var
  LipFile: TFalloutLipFile;
  Stream: TMemoryStream;
begin
  Result := False;
  
  if Length(Data) < SizeOf(TLipFileHeader) then
    Exit;
  
  LipFile := TFalloutLipFile.Create;
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

function TFalloutLipSerializer.CompareLipFiles(const File1, File2: string): string;
var
  Lip1, Lip2: TFalloutLipFile;
  SL: TStringList;
  I, MinFrames: Integer;
  DiffCount: Integer;
begin
  Lip1 := TFalloutLipFile.Create;
  Lip2 := TFalloutLipFile.Create;
  SL := TStringList.Create;
  try
    if not Lip1.LoadFromFile(File1) then
      raise ELipReadError.CreateFmt('Cannot load file: %s', [File1]);
    
    if not Lip2.LoadFromFile(File2) then
      raise ELipReadError.CreateFmt('Cannot load file: %s', [File2]);
    
    SL.Add('=== LIP File Comparison ===');
    SL.Add('');
    SL.Add(Format('File 1: %s', [File1]));
    SL.Add(Format('File 2: %s', [File2]));
    SL.Add('');
    SL.Add('--- Header Comparison ---');
    SL.Add(Format('FPS Match: %s (%d vs %d)',
      [BoolToStr(Lip1.Header.FPS = Lip2.Header.FPS, True),
       Lip1.Header.FPS, Lip2.Header.FPS]));
    SL.Add(Format('Frame Count Match: %s (%d vs %d)',
      [BoolToStr(Lip1.Header.FrameCount = Lip2.Header.FrameCount, True),
       Lip1.Header.FrameCount, Lip2.Header.FrameCount]));
    SL.Add(Format('Duration Match: %s (%.3f vs %.3f sec)',
      [BoolToStr(Abs(Lip1.GetDuration - Lip2.GetDuration) < 0.001, True),
       Lip1.GetDuration, Lip2.GetDuration]));
    SL.Add('');
    
    // Compare frames
    MinFrames := Min(Lip1.FrameCount, Lip2.FrameCount);
    DiffCount := 0;
    
    SL.Add('--- Frame Differences ---');
    
    for I := 0 to MinFrames - 1 do
    begin
      if (Lip1[I].MouthState <> Lip2[I].MouthState) or
         (Lip1[I].Intensity <> Lip2[I].Intensity) or
         (Abs(Lip1[I].TimeOffset - Lip2[I].TimeOffset) > 10) then
      begin
        Inc(DiffCount);
        if DiffCount <= 10 then // Show first 10 differences
        begin
          SL.Add(Format('Frame %d: Time %d vs %d ms, Mouth %d vs %d, Intensity %d vs %d',
            [I,
             Lip1[I].TimeOffset, Lip2[I].TimeOffset,
             Lip1[I].MouthState, Lip2[I].MouthState,
             Lip1[I].Intensity, Lip2[I].Intensity]));
        end;
      end;
    end;
    
    if DiffCount > 10 then
      SL.Add(Format('... and %d more differences', [DiffCount - 10]));
    
    SL.Add('');
    SL.Add(Format('Total Differences: %d out of %d frames', [DiffCount, MinFrames]));
    
    if Lip1.FrameCount <> Lip2.FrameCount then
      SL.Add(Format('Frame count mismatch: %d extra frames in %s',
        [Abs(Lip1.FrameCount - Lip2.FrameCount),
         IfThen(Lip1.FrameCount > Lip2.FrameCount, File1, File2)]));
    
    Result := SL.Text;
  finally
    SL.Free;
    Lip2.Free;
    Lip1.Free;
  end;
end;

{ TLipFileReader }

constructor TLipFileReader.Create;
begin
  inherited Create;
  FLipFile := TFalloutLipFile.Create;
end;

destructor TLipFileReader.Destroy;
begin
  FLipFile.Free;
  inherited;
end;

function TLipFileReader.ReadFile(const FileName: string): Boolean;
begin
  Result := FLipFile.LoadFromFile(FileName);
end;

function TLipFileReader.GetFrameAtTime(TimeSeconds: Double): TLipFrameEntry;
var
  TimeMS: Integer;
  I: Integer;
begin
  TimeMS := Round(TimeSeconds * 1000);
  
  // Find the frame at or just before the given time
  Result.TimeOffset := 0;
  Result.MouthState := 0;
  Result.Intensity := 0;
  Result.Reserved := 0;
  
  for I := 0 to FLipFile.FrameCount - 1 do
  begin
    if FLipFile[I].TimeOffset <= TimeMS then
      Result := FLipFile[I]
    else
      Break;
  end;
end;

function TLipFileReader.GetMouthStateAtTime(TimeSeconds: Double): Integer;
begin
  Result := GetFrameAtTime(TimeSeconds).MouthState;
end;

function TLipFileReader.ExportHexDump: string;
var
  Stream: TStream;
  Buffer: array[0..15] of Byte;
  BytesRead, I, J: Integer;
  Line: string;
begin
  Result := '';
  
  if not FileExists(FLipFile.FileName) then
    Exit;
  
  Stream := TFileStream.Create(FLipFile.FileName, fmOpenRead or fmShareDenyRead);
  try
    while Stream.Position < Stream.Size do
    begin
      BytesRead := Stream.Read(Buffer, SizeOf(Buffer));
      
      Line := Format('%8.8x: ', [Stream.Position - BytesRead]);
      
      // Hex values
      for I := 0 to 15 do
      begin
        if I < BytesRead then
          Line := Line + Format('%2.2x ', [Buffer[I]])
        else
          Line := Line + '   ';
        
        if I = 7 then
          Line := Line + ' ';
      end;
      
      Line := Line + '  ';
      
      // ASCII representation
      for I := 0 to BytesRead - 1 do
      begin
        if (Buffer[I] >= 32) and (Buffer[I] <= 126) then
          Line := Line + Chr(Buffer[I])
        else
          Line := Line + '.';
      end;
      
      Result := Result + Line + #13#10;
    end;
  finally
    Stream.Free;
  end;
end;

function TLipFileReader.ExportTimingVisualization(Width: Integer): string;
var
  I, BarWidth, Pos: Integer;
  SL: TStringList;
  TotalDuration: Double;
  Scale: Double;
  FrameDuration: Double;
  Bar: string;
begin
  SL := TStringList.Create;
  try
    if FLipFile.FrameCount = 0 then
      Exit('No frames to visualize');
    
    TotalDuration := FLipFile.GetDuration;
    Scale := Width / TotalDuration;
    
    SL.Add('=== Lip Sync Timing Visualization ===');
    SL.Add('');
    SL.Add(Format('Duration: %.3f seconds', [TotalDuration]));
    SL.Add(Format('Frame Count: %d', [FLipFile.FrameCount]));
    SL.Add(Format('FPS: %d', [FLipFile.Header.FPS]));
    SL.Add('');
    
    for I := 0 to FLipFile.FrameCount - 1 do
    begin
      if I < FLipFile.FrameCount - 1 then
        FrameDuration := (FLipFile[I + 1].TimeOffset - FLipFile[I].TimeOffset) / 1000.0
      else if FLipFile.Header.FPS > 0 then
        FrameDuration := 1.0 / FLipFile.Header.FPS
      else
        FrameDuration := TotalDuration / Max(FLipFile.FrameCount, 1);

      BarWidth := Round(FrameDuration * Scale);
      if BarWidth < 1 then BarWidth := 1;
      
      case FLipFile[I].MouthState of
        0: Bar := StringOfChar('.', BarWidth);
        1: Bar := StringOfChar('-', BarWidth);
        2: Bar := StringOfChar('=', BarWidth);
        3: Bar := StringOfChar('#', BarWidth);
      else
        Bar := StringOfChar('?', BarWidth);
      end;
      
      SL.Add(Format('%6.3fs [%s] %s',
        [FLipFile[I].TimeOffset / 1000.0,
         Bar,
         MouthStateToString(IndexToMouthState(FLipFile[I].MouthState))]));
    end;
    
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

end.
