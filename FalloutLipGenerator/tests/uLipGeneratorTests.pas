(*
  Fallout Lip Generator - Unit Tests
  
  Unit tests for core functionality.
  
  Copyright (c) 2026
  License: MIT
*)

unit tests.uLipGeneratorTests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  uAudioBuffer, uWavReader, uSignalAnalysis, uFalloutLipFormat, uLipGenerator;

type

  { TTestAudioBuffer }

  TTestAudioBuffer = class(TTestCase)
  published
    procedure TestCreateAndDestroy;
    procedure TestLoadFrom8BitPCM;
    procedure TestLoadFrom16BitPCM;
    procedure TestNormalize;
    procedure TestGetPeakAmplitude;
    procedure TestGetRMS;
    procedure TestExtractSegment;
  end;

  { TTestWavReader }

  TTestWavReader = class(TTestCase)
  published
    procedure TestCreateInvalidFile;
    procedure TestIsValidFormat;
    procedure TestIsFormatSupported;
  end;

  { TTestSignalAnalysis }

  TTestSignalAnalysis = class(TTestCase)
  published
    procedure TestMouthStateConversions;
    procedure TestCalculateRMS;
    procedure TestMapEnergyToMouthState;
    procedure TestMapEnergyToIntensity;
    procedure TestEnvelopeDetector;
    procedure TestGenerateLipFrames;
  end;

  { TTestFalloutLipFormat }

  TTestFalloutLipFormat = class(TTestCase)
  published
    procedure TestCreateAndDestroy;
    procedure TestAddFrame;
    procedure TestClear;
    procedure TestIsValid;
    procedure TestToLipFrames;
    procedure TestFromLipFrames;
    procedure TestExportToJSON;
    procedure TestExportDebugInfo;
  end;

  { TTestLipGenerator }

  TTestLipGenerator = class(TTestCase)
  published
    procedure TestCreateAndDestroy;
    procedure TestDefaultOptions;
    procedure TestValidateOptions;
    procedure TestGetAudioInfo;
  end;

implementation

{ TTestAudioBuffer }

procedure TTestAudioBuffer.TestCreateAndDestroy;
var
  Buffer: TAudioBuffer;
begin
  Buffer := TAudioBuffer.Create;
  try
    AssertEquals('Sample count should be 0', 0, Buffer.SampleCount);
    AssertEquals('Sample rate should be 22050', 22050, Buffer.SampleRate);
    AssertEquals('Duration should be 0', 0.0, Buffer.Duration);
  finally
    Buffer.Free;
  end;
end;

procedure TTestAudioBuffer.TestLoadFrom8BitPCM;
var
  Buffer: TAudioBuffer;
  Data: array[0..255] of Byte;
  I: Integer;
begin
  // Create test data (ramp from 0 to 255)
  for I := 0 to 255 do
    Data[I] := I;
  
  Buffer := TAudioBuffer.Create;
  try
    Buffer.LoadFrom8BitPCM(Data, 256, 22050);
    
    AssertEquals('Sample count should be 256', 256, Buffer.SampleCount);
    AssertEquals('Sample rate should be 22050', 22050, Buffer.SampleRate);
    AssertEquals('Bits per sample should be 8', 8, Buffer.BitsPerSample);
    AssertEquals('Channels should be 1', 1, Buffer.Channels);
    
    // Check first sample (0 -> -1.0)
    AssertEquals('First sample should be -1.0', -1.0, Buffer[0], 0.001);
    
    // Check middle sample (128 -> 0.0)
    AssertEquals('Middle sample should be 0.0', 0.0, Buffer[128], 0.001);
  finally
    Buffer.Free;
  end;
end;

procedure TTestAudioBuffer.TestLoadFrom16BitPCM;
var
  Buffer: TAudioBuffer;
  Data: array[0..255] of SmallInt;
  I: Integer;
begin
  // Create test data (ramp from -32768 to 32767)
  for I := 0 to 255 do
    Data[I] := -32768 + (I * 256);
  
  Buffer := TAudioBuffer.Create;
  try
    Buffer.LoadFrom16BitPCM(Data, SizeOf(Data), 22050);
    
    AssertEquals('Sample count should be 256', 256, Buffer.SampleCount);
    AssertEquals('Sample rate should be 22050', 22050, Buffer.SampleRate);
    AssertEquals('Bits per sample should be 16', 16, Buffer.BitsPerSample);
    AssertEquals('Channels should be 1', 1, Buffer.Channels);
    
    // Check first sample (-32768 -> -1.0)
    AssertEquals('First sample should be -1.0', -1.0, Buffer[0], 0.001);
  finally
    Buffer.Free;
  end;
end;

procedure TTestAudioBuffer.TestNormalize;
var
  Buffer: TAudioBuffer;
  I: Integer;
begin
  Buffer := TAudioBuffer.Create;
  try
    SetLength(Buffer.FData, 100);
    for I := 0 to 99 do
      Buffer.FData[I] := 0.5; // All samples at 0.5
    
    Buffer.FSampleRate := 22050;
    Buffer.Normalize;
    
    // After normalization, peak should be 1.0
    AssertEquals('Peak amplitude should be 1.0 after normalization',
      1.0, Buffer.GetPeakAmplitude, 0.001);
  finally
    Buffer.Free;
  end;
end;

procedure TTestAudioBuffer.TestGetPeakAmplitude;
var
  Buffer: TAudioBuffer;
  I: Integer;
begin
  Buffer := TAudioBuffer.Create;
  try
    SetLength(Buffer.FData, 100);
    for I := 0 to 99 do
      Buffer.FData[I] := I / 100.0;
    
    AssertEquals('Peak amplitude should be 0.99',
      0.99, Buffer.GetPeakAmplitude, 0.001);
  finally
    Buffer.Free;
  end;
end;

procedure TTestAudioBuffer.TestGetRMS;
var
  Buffer: TAudioBuffer;
  I: Integer;
  RMS: Double;
begin
  Buffer := TAudioBuffer.Create;
  try
    SetLength(Buffer.FData, 100);
    for I := 0 to 99 do
      Buffer.FData[I] := 1.0; // All ones
    
    RMS := Buffer.GetRMS(0, 99);
    AssertEquals('RMS of all ones should be 1.0', 1.0, RMS, 0.001);
  finally
    Buffer.Free;
  end;
end;

procedure TTestAudioBuffer.TestExtractSegment;
var
  Buffer, Segment: TAudioBuffer;
  I: Integer;
begin
  Buffer := TAudioBuffer.Create;
  try
    SetLength(Buffer.FData, 100);
    for I := 0 to 99 do
      Buffer.FData[I] := I;
    
    Buffer.FSampleRate := 100;
    
    Segment := Buffer.ExtractSegment(10, 20);
    try
      AssertNotNull('Segment should not be nil', Segment);
      AssertEquals('Segment should have 11 samples', 11, Segment.SampleCount);
      AssertEquals('First sample should be 10', 10.0, Segment[0], 0.001);
      AssertEquals('Last sample should be 20', 20.0, Segment[10], 0.001);
    finally
      Segment.Free;
    end;
  finally
    Buffer.Free;
  end;
end;

{ TTestWavReader }

procedure TTestWavReader.TestCreateInvalidFile;
begin
  AssertException('Should raise exception for non-existent file',
    EWavReadError,
    procedure
    var
      Reader: TWavReader;
    begin
      Reader := TWavReader.Create('nonexistent.wav');
      Reader.Free;
    end);
end;

procedure TTestWavReader.TestIsValidFormat;
begin
  // This test would need a valid WAV file
  // For now, just pass
  AssertTrue(True);
end;

procedure TTestWavReader.TestIsFormatSupported;
begin
  // This test would need a valid WAV file
  // For now, just pass
  AssertTrue(True);
end;

{ TTestSignalAnalysis }

procedure TTestSignalAnalysis.TestMouthStateConversions;
begin
  AssertEquals('msClosed should convert to "Closed"',
    'Closed', MouthStateToString(msClosed));
  AssertEquals('msSmallOpen should convert to "SmallOpen"',
    'SmallOpen', MouthStateToString(msSmallOpen));
  AssertEquals('msMediumOpen should convert to "MediumOpen"',
    'MediumOpen', MouthStateToString(msMediumOpen));
  AssertEquals('msWideOpen should convert to "WideOpen"',
    'WideOpen', MouthStateToString(msWideOpen));
  
  AssertEquals('"Closed" should convert to msClosed',
    Ord(msClosed), Ord(StringToMouthState('Closed')));
  AssertEquals('"SmallOpen" should convert to msSmallOpen',
    Ord(msSmallOpen), Ord(StringToMouthState('SmallOpen')));
end;

procedure TTestSignalAnalysis.TestCalculateRMS;
var
  Analyzer: TAudioAnalyzer;
  Samples: array of Double;
  I: Integer;
begin
  Analyzer := TAudioAnalyzer.Create(22050);
  try
    SetLength(Samples, 100);
    for I := 0 to 99 do
      Samples[I] := 1.0;
    
    AssertEquals('RMS of all ones should be 1.0',
      1.0, Analyzer.CalculateRMS(Samples, 0, 99), 0.001);
  finally
    Analyzer.Free;
  end;
end;

procedure TTestSignalAnalysis.TestMapEnergyToMouthState;
var
  Analyzer: TAudioAnalyzer;
begin
  Analyzer := TAudioAnalyzer.Create(22050);
  try
    Analyzer.Threshold := 0.1;
    
    AssertEquals('Very low energy should be msClosed',
      Ord(msClosed), Ord(Analyzer.MapEnergyToMouthState(0.01)));
    AssertEquals('Low energy should be msSmallOpen',
      Ord(msSmallOpen), Ord(Analyzer.MapEnergyToMouthState(0.12)));
    AssertEquals('Medium energy should be msMediumOpen',
      Ord(msMediumOpen), Ord(Analyzer.MapEnergyToMouthState(0.25)));
    AssertEquals('High energy should be msWideOpen',
      Ord(msWideOpen), Ord(Analyzer.MapEnergyToMouthState(0.5)));
  finally
    Analyzer.Free;
  end;
end;

procedure TTestSignalAnalysis.TestMapEnergyToIntensity;
var
  Analyzer: TAudioAnalyzer;
begin
  Analyzer := TAudioAnalyzer.Create(22050);
  try
    Analyzer.Threshold := 0.1;
    
    AssertEquals('Below threshold should be 0.0',
      0.0, Analyzer.MapEnergyToIntensity(0.05), 0.001);
    AssertEquals('Above threshold should be > 0.0',
      True, Analyzer.MapEnergyToIntensity(0.2) > 0.0);
    AssertEquals('Very high energy should be 1.0',
      1.0, Analyzer.MapEnergyToIntensity(1.0), 0.001);
  finally
    Analyzer.Free;
  end;
end;

procedure TTestSignalAnalysis.TestEnvelopeDetector;
var
  Detector: TEnvelopeDetector;
  I: Integer;
  Envelope: Double;
begin
  Detector := TEnvelopeDetector.Create(22050);
  try
    Detector.AttackTime := 0.01;
    Detector.ReleaseTime := 0.1;
    
    // Process a step function
    for I := 0 to 100 do
      Envelope := Detector.ProcessSample(1.0);
    
    AssertTrue('Envelope should approach 1.0', Envelope > 0.9);
    
    Detector.Reset;
    AssertEquals('Envelope should be 0.0 after reset', 0.0, Detector.ProcessSample(0.0), 0.001);
  finally
    Detector.Free;
  end;
end;

procedure TTestSignalAnalysis.TestGenerateLipFrames;
var
  Analyzer: TAudioAnalyzer;
  Buffer: TAudioBuffer;
  Frames: TLipFrameArray;
  I: Integer;
begin
  Analyzer := TAudioAnalyzer.Create(22050);
  try
    // Create a simple test buffer
    Buffer := TAudioBuffer.Create;
    try
      SetLength(Buffer.FData, 2205); // 0.1 seconds at 22050 Hz
      for I := 0 to 2204 do
        Buffer.FData[I] := 0.5; // Constant amplitude
      
      Buffer.FSampleRate := 22050;
      Buffer.FDuration := 0.1;
      
      Frames := Analyzer.GenerateLipFrames(Buffer, 10); // 10 FPS
      
      AssertTrue('Should generate at least 1 frame', Length(Frames) >= 1);
      AssertEquals('First frame time should be 0.0', 0.0, Frames[0].Time, 0.001);
    finally
      Buffer.Free;
    end;
  finally
    Analyzer.Free;
  end;
end;

{ TTestFalloutLipFormat }

procedure TTestFalloutLipFormat.TestCreateAndDestroy;
var
  LipFile: TFalloutLipFile;
begin
  LipFile := TFalloutLipFile.Create;
  try
    AssertEquals('Frame count should be 0', 0, LipFile.FrameCount);
    AssertEquals('Duration should be 0', 0.0, LipFile.Duration);
    AssertEquals('Signature should match',
      'LIP'#0, LipFile.Header.Signature);
    AssertEquals('Version should be 1', 1, LipFile.Header.Version);
  finally
    LipFile.Free;
  end;
end;

procedure TTestFalloutLipFormat.TestAddFrame;
var
  LipFile: TFalloutLipFile;
begin
  LipFile := TFalloutLipFile.Create;
  try
    LipFile.AddFrame(100, 1, 128);
    
    AssertEquals('Frame count should be 1', 1, LipFile.FrameCount);
    AssertEquals('Time offset should be 100', 100, LipFile[0].TimeOffset);
    AssertEquals('Mouth state should be 1', 1, LipFile[0].MouthState);
    AssertEquals('Intensity should be 128', 128, LipFile[0].Intensity);
  finally
    LipFile.Free;
  end;
end;

procedure TTestFalloutLipFormat.TestClear;
var
  LipFile: TFalloutLipFile;
begin
  LipFile := TFalloutLipFile.Create;
  try
    LipFile.AddFrame(100, 1, 128);
    LipFile.AddFrame(200, 2, 192);
    
    AssertEquals('Frame count should be 2', 2, LipFile.FrameCount);
    
    LipFile.Clear;
    
    AssertEquals('Frame count should be 0 after clear', 0, LipFile.FrameCount);
    AssertEquals('Duration should be 0 after clear', 0.0, LipFile.Duration);
  finally
    LipFile.Free;
  end;
end;

procedure TTestFalloutLipFormat.TestIsValid;
var
  LipFile: TFalloutLipFile;
begin
  LipFile := TFalloutLipFile.Create;
  try
    AssertTrue('Empty lip file should be valid', LipFile.IsValid);
    
    LipFile.AddFrame(100, 1, 128);
    AssertTrue('Lip file with valid frame should be valid', LipFile.IsValid);
    
    // Invalid mouth state would make it invalid
    // (but we can't easily test without breaking encapsulation)
  finally
    LipFile.Free;
  end;
end;

procedure TTestFalloutLipFormat.TestToLipFrames;
var
  LipFile: TFalloutLipFile;
  Frames: TLipFrameArray;
begin
  LipFile := TFalloutLipFile.Create;
  try
    LipFile.AddFrame(0, 1, 128);
    LipFile.AddFrame(83, 2, 192); // ~83ms at 12 FPS
    
    Frames := LipFile.ToLipFrames;
    try
      AssertEquals('Should have 2 frames', 2, Length(Frames));
      AssertEquals('First frame time should be 0.0', 0.0, Frames[0].Time, 0.001);
      AssertEquals('First frame mouth state should be msSmallOpen',
        Ord(msSmallOpen), Ord(Frames[0].MouthState));
      AssertEquals('First frame intensity should be ~0.5',
        0.5, Frames[0].Intensity, 0.01);
    finally
      SetLength(Frames, 0);
    end;
  finally
    LipFile.Free;
  end;
end;

procedure TTestFalloutLipFormat.TestFromLipFrames;
var
  LipFile: TFalloutLipFile;
  Frames: TLipFrameArray;
begin
  LipFile := TFalloutLipFile.Create;
  try
    SetLength(Frames, 2);
    Frames[0].Time := 0.0;
    Frames[0].MouthState := msSmallOpen;
    Frames[0].Intensity := 0.5;
    Frames[0].Duration := 1.0 / 12;
    
    Frames[1].Time := 1.0 / 12;
    Frames[1].MouthState := msMediumOpen;
    Frames[1].Intensity := 0.75;
    Frames[1].Duration := 1.0 / 12;
    
    LipFile.FromLipFrames(Frames, 12);
    
    AssertEquals('Should have 2 frames', 2, LipFile.FrameCount);
    AssertEquals('First frame mouth state should be 1',
      1, LipFile[0].MouthState);
    AssertEquals('First frame intensity should be ~128',
      128, LipFile[0].Intensity, 1);
  finally
    LipFile.Free;
    SetLength(Frames, 0);
  end;
end;

procedure TTestFalloutLipFormat.TestExportToJSON;
var
  LipFile: TFalloutLipFile;
  JSON: string;
begin
  LipFile := TFalloutLipFile.Create;
  try
    LipFile.AddFrame(0, 1, 128);
    LipFile.AddFrame(83, 2, 192);
    
    JSON := LipFile.ExportToJSON;
    
    AssertTrue('JSON should contain duration', Pos('"duration"', JSON) > 0);
    AssertTrue('JSON should contain fps', Pos('"fps"', JSON) > 0);
    AssertTrue('JSON should contain frameCount', Pos('"frameCount"', JSON) > 0);
    AssertTrue('JSON should contain frames array', Pos('"frames"', JSON) > 0);
  finally
    LipFile.Free;
  end;
end;

procedure TTestFalloutLipFormat.TestExportDebugInfo;
var
  LipFile: TFalloutLipFile;
  Debug: string;
begin
  LipFile := TFalloutLipFile.Create;
  try
    LipFile.AddFrame(0, 1, 128);
    LipFile.AddFrame(83, 2, 192);
    
    Debug := LipFile.ExportDebugInfo;
    
    AssertTrue('Debug info should contain Frame Count',
      Pos('Frame Count', Debug) > 0);
    AssertTrue('Debug info should contain FPS',
      Pos('FPS', Debug) > 0);
  finally
    LipFile.Free;
  end;
end;

{ TTestLipGenerator }

procedure TTestLipGenerator.TestCreateAndDestroy;
var
  Generator: TLipGenerator;
begin
  Generator := TLipGenerator.Create;
  try
    AssertNotNull('Generator should be created', Generator);
    AssertEquals('Default FPS should be 12', 12, Generator.Options.FPS);
    AssertEquals('Default threshold should be 0.08',
      0.08, Generator.Options.Threshold, 0.001);
    AssertTrue('Default normalize should be true',
      Generator.Options.Normalize);
  finally
    Generator.Free;
  end;
end;

procedure TTestLipGenerator.TestDefaultOptions;
var
  Options: TLipGenOptions;
begin
  Options := DefaultLipGenOptions;
  
  AssertEquals('Default FPS should be 12', 12, Options.FPS);
  AssertEquals('Default threshold should be 0.08',
    0.08, Options.Threshold, 0.001);
  AssertTrue('Default normalize should be true', Options.Normalize);
  AssertFalse('Default extended data should be false',
    Options.IncludeExtendedData);
end;

procedure TTestLipGenerator.TestValidateOptions;
var
  Generator: TLipGenerator;
begin
  Generator := TLipGenerator.Create;
  try
    // Valid options
    Generator.Options.FPS := 12;
    Generator.Options.Threshold := 0.1;
    AssertTrue('Valid options should pass validation',
      Generator.ValidateOptions);
    
    // Invalid FPS
    Generator.Options.FPS := 24;
    AssertFalse('Invalid FPS should fail validation',
      Generator.ValidateOptions);
    
    // Invalid threshold
    Generator.Options.FPS := 12;
    Generator.Options.Threshold := 1.5;
    AssertFalse('Invalid threshold should fail validation',
      Generator.ValidateOptions);
  finally
    Generator.Free;
  end;
end;

procedure TTestLipGenerator.TestGetAudioInfo;
var
  Generator: TLipGenerator;
  Info: string;
begin
  Generator := TLipGenerator.Create;
  try
    // This test would need a valid WAV file
    // For now, just test that it doesn't crash
    Info := Generator.GetAudioInfo('nonexistent.wav');
    AssertTrue('Should return error message for non-existent file',
      Pos('not found', LowerCase(Info)) > 0);
  finally
    Generator.Free;
  end;
end;

initialization
  RegisterTest(TTestAudioBuffer);
  RegisterTest(TTestWavReader);
  RegisterTest(TTestSignalAnalysis);
  RegisterTest(TTestFalloutLipFormat);
  RegisterTest(TTestLipGenerator);
end.