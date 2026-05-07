(*
  Fallout Lip Generator - WAV File Reader Unit
  
  This unit handles reading and parsing WAV audio files.
  Supports uncompressed PCM WAV files (8-bit and 16-bit, mono).
  
  Copyright (c) 2026
  License: MIT
*)

unit uWavReader;

interface

uses
  Classes, SysUtils, uAudioBuffer;

type
  { WAV file header structure }
  TWavHeader = packed record
    RiffId: array[0..3] of AnsiChar;      // 'RIFF'
    FileSize: LongWord;                   // File size - 8
    WaveId: array[0..3] of AnsiChar;      // 'WAVE'
    FmtId: array[0..3] of AnsiChar;       // 'fmt '
    FmtSize: LongWord;                    // Format chunk size (16 for PCM)
    AudioFormat: Word;                    // 1 = PCM
    NumChannels: Word;                    // Number of channels
    SampleRate: LongWord;                 // Sample rate (Hz)
    ByteRate: LongWord;                   // Byte rate
    BlockAlign: Word;                     // Block align
    BitsPerSample: Word;                  // Bits per sample
    DataId: array[0..3] of AnsiChar;      // 'data'
    DataSize: LongWord;                   // Data chunk size
  end;

  { WAV file reading exception }
  EWavReadError = class(Exception);

  { WAV file reader }
  TWavReader = class
  private
    FFileName: string;
    FHeader: TWavHeader;
    FIsValid: Boolean;
    
    function ValidateHeader: Boolean;
    function GetDuration: Double;
    function GetSampleRate: Integer;
    function GetBitsPerSample: Integer;
    function GetChannels: Integer;
    function GetDataSize: LongWord;
  public
    constructor Create(const AFileName: string);
    
    { Load WAV file and return audio buffer }
    function LoadToBuffer: TAudioBuffer;
    
    { Load WAV file from stream }
    function LoadFromStream(Stream: TStream): TAudioBuffer;
    
    { Check if file is valid WAV }
    function IsValid: Boolean;
    
    { Validate WAV format is supported }
    function IsFormatSupported: Boolean;
    
    { Properties }
    property FileName: string read FFileName;
    property Header: TWavHeader read FHeader;
    property Duration: Double read GetDuration;
    property SampleRate: Integer read GetSampleRate;
    property BitsPerSample: Integer read GetBitsPerSample;
    property Channels: Integer read GetChannels;
    property DataSize: LongWord read GetDataSize;
  end;

implementation

{ TWavReader }

constructor TWavReader.Create(const AFileName: string);
var
  Stream: TStream;
begin
  FFileName := AFileName;
  FIsValid := False;

  if not FileExists(AFileName) then
    raise EWavReadError.CreateFmt('File not found: %s', [AFileName]);

  { Read just the header to validate the file; PCM data is read on demand by LoadToBuffer }
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    if Stream.Read(FHeader, SizeOf(TWavHeader)) <> SizeOf(TWavHeader) then
      raise EWavReadError.Create('Invalid WAV file: cannot read header');
    FIsValid := ValidateHeader;
  finally
    Stream.Free;
  end;
end;

function TWavReader.ValidateHeader: Boolean;
begin
  Result := False;
  
  { Check RIFF header }
  if (FHeader.RiffId[0] <> 'R') or (FHeader.RiffId[1] <> 'I') or
     (FHeader.RiffId[2] <> 'F') or (FHeader.RiffId[3] <> 'F') then
    Exit;
  
  { Check WAVE identifier }
  if (FHeader.WaveId[0] <> 'W') or (FHeader.WaveId[1] <> 'A') or
     (FHeader.WaveId[2] <> 'V') or (FHeader.WaveId[3] <> 'E') then
    Exit;
  
  { Check fmt chunk }
  if (FHeader.FmtId[0] <> 'f') or (FHeader.FmtId[1] <> 'm') or
     (FHeader.FmtId[2] <> 't') or (FHeader.FmtId[3] <> ' ') then
    Exit;
  
  { Check audio format (1 = PCM) }
  if FHeader.AudioFormat <> 1 then
    Exit;
  
  { Check data chunk identifier }
  if (FHeader.DataId[0] <> 'd') or (FHeader.DataId[1] <> 'a') or
     (FHeader.DataId[2] <> 't') or (FHeader.DataId[3] <> 'a') then
    Exit;
  
  Result := True;
end;

function TWavReader.LoadFromStream(Stream: TStream): TAudioBuffer;
var
  TempBytes: array of Byte;
begin
  Result := nil;

  { Read header }
  if Stream.Read(FHeader, SizeOf(TWavHeader)) <> SizeOf(TWavHeader) then
    raise EWavReadError.Create('Invalid WAV file: cannot read header');

  FIsValid := ValidateHeader;
  if not FIsValid then
    raise EWavReadError.Create('Invalid or unsupported WAV format');

  { Check if format is supported }
  if not IsFormatSupported then
    raise EWavReadError.CreateFmt('Unsupported WAV format: %d channels, %d bits/sample',
      [FHeader.NumChannels, FHeader.BitsPerSample]);

  { Read raw PCM data }
  SetLength(TempBytes, FHeader.DataSize);
  if Stream.Read(TempBytes[0], FHeader.DataSize) <> LongInt(FHeader.DataSize) then
    raise EWavReadError.Create('Failed to read WAV data');

  { Create and populate audio buffer via public API }
  Result := TAudioBuffer.Create;
  try
    Result.LoadFromPCM(TempBytes[0], LongInt(FHeader.DataSize),
      FHeader.SampleRate, FHeader.BitsPerSample, FHeader.NumChannels);
  except
    Result.Free;
    raise;
  end;
end;

function TWavReader.LoadToBuffer: TAudioBuffer;
var
  Stream: TStream;
  TempBytes: array of Byte;
begin
  Stream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);
  try
    { Read header }
    if Stream.Read(FHeader, SizeOf(TWavHeader)) <> SizeOf(TWavHeader) then
      raise EWavReadError.Create('Invalid WAV file: cannot read header');

    FIsValid := ValidateHeader;
    if not FIsValid then
      raise EWavReadError.Create('Invalid or unsupported WAV format');

    if not IsFormatSupported then
      raise EWavReadError.CreateFmt('Unsupported WAV format: %d channels, %d bits/sample',
        [FHeader.NumChannels, FHeader.BitsPerSample]);

    { Read raw PCM bytes }
    SetLength(TempBytes, FHeader.DataSize);
    if Stream.Read(TempBytes[0], FHeader.DataSize) <> LongInt(FHeader.DataSize) then
      raise EWavReadError.Create('Failed to read WAV data');

    { Create buffer via public API }
    Result := TAudioBuffer.Create;
    try
      Result.LoadFromPCM(TempBytes[0], LongInt(FHeader.DataSize),
        FHeader.SampleRate, FHeader.BitsPerSample, FHeader.NumChannels);
    except
      Result.Free;
      raise;
    end;
  finally
    Stream.Free;
  end;
end;

function TWavReader.IsValid: Boolean;
begin
  Result := FIsValid;
end;

function TWavReader.IsFormatSupported: Boolean;
begin
  { Support mono, 8-bit or 16-bit PCM }
  Result := (FHeader.NumChannels = 1) and
            ((FHeader.BitsPerSample = 8) or (FHeader.BitsPerSample = 16)) and
            (FHeader.AudioFormat = 1); { PCM }
end;

function TWavReader.GetDuration: Double;
begin
  if FHeader.SampleRate > 0 then
    Result := FHeader.DataSize / (FHeader.SampleRate * FHeader.NumChannels * (FHeader.BitsPerSample div 8))
  else
    Result := 0;
end;

function TWavReader.GetSampleRate: Integer;
begin
  Result := FHeader.SampleRate;
end;

function TWavReader.GetBitsPerSample: Integer;
begin
  Result := FHeader.BitsPerSample;
end;

function TWavReader.GetChannels: Integer;
begin
  Result := FHeader.NumChannels;
end;

function TWavReader.GetDataSize: LongWord;
begin
  Result := FHeader.DataSize;
end;

end.