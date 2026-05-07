(*
  Fallout Lip Generator - Audio Buffer Unit
  
  This unit provides audio buffer management for WAV file processing.
  Handles loading, storing, and basic manipulation of PCM audio data.
  
  Copyright (c) 2026
  License: MIT
*)

unit uAudioBuffer;

interface

uses
  Classes, SysUtils, Math;

type
  { Supported PCM formats }
  TPCMFormat = (
    pfUnknown,
    pf8BitMono,
    pf16BitMono
  );

  { Audio sample buffer - stores normalized float samples (-1.0 to 1.0) }
  TAudioBuffer = class
  private
    FData: array of Double;
    FSampleRate: Integer;
    FDuration: Double;
    FFormat: TPCMFormat;
    FBitsPerSample: Integer;
    FChannels: Integer;
    
    function GetSample(Index: Integer): Double;
    function GetSampleCount: Integer;
    procedure SetSample(Index: Integer; const Value: Double);
  public
    constructor Create;
    destructor Destroy; override;
    
    { Load from raw PCM data }
    procedure LoadFromPCM(const Buffer; BufferSize: Integer; 
      SampleRate, BitsPerSample, Channels: Integer);
    
    { Load from 8-bit PCM }
    procedure LoadFrom8BitPCM(const Buffer; BufferSize: Integer; SampleRate: Integer);
    
    { Load from 16-bit PCM }
    procedure LoadFrom16BitPCM(const Buffer; BufferSize: Integer; SampleRate: Integer);
    
    { Normalize audio to full scale }
    procedure Normalize;
    
    { Get peak amplitude }
    function GetPeakAmplitude: Double;
    
    { Get RMS amplitude over a range }
    function GetRMS(StartIndex, EndIndex: Integer): Double;
    
    { Extract a segment }
    function ExtractSegment(StartSample, EndSample: Integer): TAudioBuffer;
    
    { Properties }
    { Direct access to underlying sample data for signal processing }
    function GetDataPointer: PDouble;

    property Samples[Index: Integer]: Double read GetSample write SetSample; default;
    property SampleCount: Integer read GetSampleCount;
    property SampleRate: Integer read FSampleRate write FSampleRate;
    property Duration: Double read FDuration;
    property Format: TPCMFormat read FFormat;
    property BitsPerSample: Integer read FBitsPerSample;
    property Channels: Integer read FChannels;
  end;

implementation

{ TAudioBuffer }

constructor TAudioBuffer.Create;
begin
  inherited;
  FSampleRate := 22050;
  FFormat := pfUnknown;
  FBitsPerSample := 0;
  FChannels := 0;
  FDuration := 0;
  SetLength(FData, 0);
end;

destructor TAudioBuffer.Destroy;
begin
  SetLength(FData, 0);
  inherited;
end;

function TAudioBuffer.GetSample(Index: Integer): Double;
begin
  if (Index >= 0) and (Index < Length(FData)) then
    Result := FData[Index]
  else
    Result := 0.0;
end;

function TAudioBuffer.GetSampleCount: Integer;
begin
  Result := Length(FData);
end;

procedure TAudioBuffer.SetSample(Index: Integer; const Value: Double);
begin
  if (Index >= 0) and (Index < Length(FData)) then
    FData[Index] := EnsureRange(Value, -1.0, 1.0);
end;

procedure TAudioBuffer.LoadFromPCM(const Buffer; BufferSize: Integer; 
  SampleRate, BitsPerSample, Channels: Integer);
begin
  FSampleRate := SampleRate;
  FBitsPerSample := BitsPerSample;
  FChannels := Channels;
  
  case BitsPerSample of
    8:
      begin
        FFormat := pf8BitMono;
        LoadFrom8BitPCM(Buffer, BufferSize, SampleRate);
      end;
    16:
      begin
        FFormat := pf16BitMono;
        LoadFrom16BitPCM(Buffer, BufferSize, SampleRate);
      end;
  else
    FFormat := pfUnknown;
    raise Exception.CreateFmt('Unsupported PCM format: %d bits', [BitsPerSample]);
  end;
  
  if SampleRate > 0 then
    FDuration := Length(FData) / SampleRate
  else
    FDuration := 0;
end;

procedure TAudioBuffer.LoadFrom8BitPCM(const Buffer; BufferSize: Integer; SampleRate: Integer);
var
  P: PByte;
  I: Integer;
  Sample8: Byte;
begin
  FSampleRate := SampleRate;
  FBitsPerSample := 8;
  FChannels := 1;
  FFormat := pf8BitMono;
  
  SetLength(FData, BufferSize);
  P := @Buffer;
  
  for I := 0 to BufferSize - 1 do
  begin
    Sample8 := P^;
    { Convert 8-bit unsigned (0-255) to float (-1.0 to 1.0) }
    FData[I] := (Sample8 - 128) / 128.0;
    Inc(P);
  end;
  
  FDuration := BufferSize / SampleRate;
end;

procedure TAudioBuffer.LoadFrom16BitPCM(const Buffer; BufferSize: Integer; SampleRate: Integer);
var
  P: PSmallInt;
  I, SampleCount: Integer;
  Sample16: SmallInt;
begin
  FSampleRate := SampleRate;
  FBitsPerSample := 16;
  FChannels := 1;
  FFormat := pf16BitMono;
  
  SampleCount := BufferSize div SizeOf(SmallInt);
  SetLength(FData, SampleCount);
  P := @Buffer;
  
  for I := 0 to SampleCount - 1 do
  begin
    Sample16 := P^;
    { Convert 16-bit signed to float (-1.0 to 1.0) }
    FData[I] := Sample16 / 32768.0;
    Inc(P);
  end;
  
  FDuration := SampleCount / SampleRate;
end;

procedure TAudioBuffer.Normalize;
var
  I: Integer;
  Peak: Double;
  Scale: Double;
begin
  Peak := GetPeakAmplitude;
  if Peak > 0 then
  begin
    Scale := 1.0 / Peak;
    for I := 0 to Length(FData) - 1 do
      FData[I] := FData[I] * Scale;
  end;
end;

function TAudioBuffer.GetPeakAmplitude: Double;
var
  I: Integer;
  AbsVal: Double;
begin
  Result := 0.0;
  for I := 0 to Length(FData) - 1 do
  begin
    AbsVal := Abs(FData[I]);
    if AbsVal > Result then
      Result := AbsVal;
  end;
end;

function TAudioBuffer.GetRMS(StartIndex, EndIndex: Integer): Double;
var
  I, Count: Integer;
  SumSquares: Double;
begin
  if StartIndex < 0 then StartIndex := 0;
  if EndIndex >= Length(FData) then EndIndex := Length(FData) - 1;
  if StartIndex > EndIndex then Exit(0.0);
  
  Count := EndIndex - StartIndex + 1;
  SumSquares := 0.0;
  
  for I := StartIndex to EndIndex do
    SumSquares := SumSquares + Sqr(FData[I]);
  
  Result := Sqrt(SumSquares / Count);
end;

function TAudioBuffer.GetDataPointer: PDouble;
begin
  if Length(FData) > 0 then
    Result := @FData[0]
  else
    Result := nil;
end;

function TAudioBuffer.ExtractSegment(StartSample, EndSample: Integer): TAudioBuffer;
var
  I, Len: Integer;
begin
  if StartSample < 0 then StartSample := 0;
  if EndSample >= Length(FData) then EndSample := Length(FData) - 1;
  if StartSample > EndSample then Exit(nil);
  
  Result := TAudioBuffer.Create;
  Len := EndSample - StartSample + 1;
  SetLength(Result.FData, Len);
  
  for I := 0 to Len - 1 do
    Result.FData[I] := FData[StartSample + I];
  
  Result.FSampleRate := FSampleRate;
  Result.FBitsPerSample := FBitsPerSample;
  Result.FChannels := FChannels;
  Result.FFormat := FFormat;
  Result.FDuration := Len / FSampleRate;
end;

end.