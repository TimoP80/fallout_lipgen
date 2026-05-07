(*
  Fallout Lip Generator - Main Lip Generation Engine
  
  This unit orchestrates the lip-sync generation process:
  - Loads WAV files
  - Analyzes audio signals
  - Generates lip frames
  - Serializes to Fallout LIP format
  
  Copyright (c) 2026
  License: MIT
*)

unit uLipGenerator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uWavReader, uAudioBuffer, uSignalAnalysis, uFalloutLipFormat;

type
  { Progress callback type }
  TProgressCallback = procedure(Progress: Integer; const Status: string) of object;

  { Lip generation options }
  TLipGenOptions = record
    FPS: Integer;                    // Target FPS (10, 12, 15)
    Threshold: Double;               // Energy threshold for phoneme detection
    Normalize: Boolean;              // Normalize audio before processing
    IncludeExtendedData: Boolean;    // Include extended frame data
    MinSilenceDuration: Double;      // Minimum silence duration (seconds)
    MinPhonemeDuration: Double;      // Minimum phoneme duration (seconds)
    DebugMode: Boolean;              // Enable debug output
  end;

  { Default lip generation options }
  function DefaultLipGenOptions: TLipGenOptions;

  { Lip generation result }
  TLipGenResult = record
    Success: Boolean;                // Generation succeeded
    ErrorMessage: string;            // Error message if failed
    InputFile: string;               // Source WAV file
    OutputFile: string;              // Output LIP file
    Duration: Double;                // Audio duration (seconds)
    FrameCount: Integer;             // Number of frames generated
    ProcessingTime: Double;          // Processing time (seconds)
    Warnings: TStringList;           // Any warnings during processing
  end;

  { Main lip generator class }
  TLipGenerator = class
  private
    FOptions: TLipGenOptions;
    FOnProgress: TProgressCallback;
    FDebugLog: TStringList;
    
    procedure DoProgress(Progress: Integer; const Status: string);
    procedure LogDebug(const Msg: string);
    function ValidateOptions: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    
    { Generate LIP file from WAV file }
    function GenerateFromFile(const InputWav, OutputLip: string): TLipGenResult;
    
    { Generate LIP file from audio buffer }
    function GenerateFromBuffer(Buffer: TAudioBuffer; const OutputLip: string): TLipGenResult;
    
    { Generate lip frames from audio buffer }
    function GenerateLipFrames(Buffer: TAudioBuffer): TLipFrameArray;
    
    { Batch process multiple files }
    function BatchProcess(const InputList, OutputList: TStringList): TArray<TLipGenResult>;
    
    { Export debug information }
    function ExportDebugInfo(const LipFile: string): string;
    
    { Export to JSON }
    function ExportToJSON(const LipFile: string): string;
    
    { Compare two LIP files }
    function CompareFiles(const LipFile1, LipFile2: string): string;
    
    { Validate LIP file }
    function ValidateLipFile(const LipFile: string): Boolean;
    
    { Get audio info }
    function GetAudioInfo(const WavFile: string): string;
    
    { Properties }
    property Options: TLipGenOptions read FOptions write FOptions;
    property OnProgress: TProgressCallback read FOnProgress write FOnProgress;
    property DebugLog: TStringList read FDebugLog;
  end;

implementation

{ Helper functions }

function DefaultLipGenOptions: TLipGenOptions;
begin
  Result.FPS := 12;
  Result.Threshold := 0.08;
  Result.Normalize := True;
  Result.IncludeExtendedData := False;
  Result.MinSilenceDuration := 0.1;
  Result.MinPhonemeDuration := 0.05;
  Result.DebugMode := False;
end;

{ TLipGenerator }

constructor TLipGenerator.Create;
begin
  inherited Create;
  FOptions := DefaultLipGenOptions;
  FDebugLog := TStringList.Create;
end;

destructor TLipGenerator.Destroy;
begin
  FDebugLog.Free;
  inherited;
end;

procedure TLipGenerator.DoProgress(Progress: Integer; const Status: string);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Progress, Status);
end;

procedure TLipGenerator.LogDebug(const Msg: string);
begin
  if FOptions.DebugMode then
  begin
    FDebugLog.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss.zzz', Now), Msg]));
  end;
end;

function TLipGenerator.ValidateOptions: Boolean;
begin
  Result := False;
  
  // Validate FPS
  if not (FOptions.FPS in [10, 12, 15]) then
  begin
    LogDebug(Format('Invalid FPS: %d', [FOptions.FPS]));
    Exit;
  end;
  
  // Validate threshold
  if (FOptions.Threshold <= 0) or (FOptions.Threshold > 1) then
  begin
    LogDebug(Format('Invalid threshold: %.3f', [FOptions.Threshold]));
    Exit;
  end;
  
  // Validate durations
  if FOptions.MinSilenceDuration < 0 then
  begin
    LogDebug('MinSilenceDuration cannot be negative');
    Exit;
  end;
  
  if FOptions.MinPhonemeDuration < 0 then
  begin
    LogDebug('MinPhonemeDuration cannot be negative');
    Exit;
  end;
  
  Result := True;
end;

function TLipGenerator.GenerateFromFile(const InputWav, OutputLip: string): TLipGenResult;
var
  WavReader: TWavReader;
  AudioBuffer: TAudioBuffer;
  StartTime: TDateTime;
begin
  // Initialize result
  FillChar(Result, SizeOf(Result), 0);
  Result.InputFile := InputWav;
  Result.OutputFile := OutputLip;
  Result.Warnings := TStringList.Create;
  
  try
    // Validate options
    if not ValidateOptions then
    begin
      Result.ErrorMessage := 'Invalid generation options';
      Exit;
    end;
    
    // Check input file exists
    if not FileExists(InputWav) then
    begin
      Result.ErrorMessage := Format('Input file not found: %s', [InputWav]);
      Exit;
    end;
    
    DoProgress(10, 'Loading WAV file...');
    LogDebug(Format('Loading WAV file: %s', [InputWav]));
    
    StartTime := Now;
    
    // Load WAV file
    try
      WavReader := TWavReader.Create(InputWav);
      try
        // Check format support
        if not WavReader.IsFormatSupported then
        begin
          Result.ErrorMessage := Format('Unsupported WAV format: %d channels, %d bits/sample',
            [WavReader.Channels, WavReader.BitsPerSample]);
          Exit;
        end;
        
        // Load to buffer
        AudioBuffer := WavReader.LoadToBuffer;
        try
          Result.Duration := AudioBuffer.Duration;
          LogDebug(Format('Loaded audio: %.3f seconds, %d samples, %d Hz',
            [AudioBuffer.Duration, AudioBuffer.SampleCount, AudioBuffer.SampleRate]));
          
          DoProgress(30, 'Normalizing audio...');
          
          // Normalize if requested
          if FOptions.Normalize then
          begin
            AudioBuffer.Normalize;
            LogDebug('Audio normalized');
          end;
          
          DoProgress(50, 'Generating lip frames...');
          
          // Generate lip frames
          Result.Success := GenerateFromBuffer(AudioBuffer, OutputLip).Success;
          Result.ErrorMessage := GenerateFromBuffer(AudioBuffer, OutputLip).ErrorMessage;
          Result.FrameCount := GenerateFromBuffer(AudioBuffer, OutputLip).FrameCount;
          
        finally
          AudioBuffer.Free;
        end;
      finally
        WavReader.Free;
      end;
    except
      on E: Exception do
      begin
        Result.ErrorMessage := Format('Error loading WAV file: %s', [E.Message]);
        Exit;
      end;
    end;
    
    Result.ProcessingTime := (Now - StartTime) * 86400; // Convert to seconds
    
    if Result.Success then
      DoProgress(100, 'Generation complete!')
    else
      DoProgress(0, 'Generation failed');
    
  finally
    // Result.Warnings will be freed by caller
  end;
end;

function TLipGenerator.GenerateFromBuffer(Buffer: TAudioBuffer; const OutputLip: string): TLipGenResult;
var
  LipFrames: TLipFrameArray;
  LipFile: TFalloutLipFile;
  Serializer: TFalloutLipSerializer;
  StartTime: TDateTime;
  I: Integer;
begin
  // Initialize result
  FillChar(Result, SizeOf(Result), 0);
  Result.OutputFile := OutputLip;
  Result.Duration := Buffer.Duration;
  Result.Warnings := TStringList.Create;
  
  try
    // Validate options
    if not ValidateOptions then
    begin
      Result.ErrorMessage := 'Invalid generation options';
      Exit;
    end;
    
    StartTime := Now;
    
    DoProgress(60, 'Analyzing audio signal...');
    LogDebug('Starting signal analysis');
    
    // Generate lip frames
    LipFrames := GenerateLipFrames(Buffer);
    
    Result.FrameCount := Length(LipFrames);
    LogDebug(Format('Generated %d lip frames', [Result.FrameCount]));
    
    DoProgress(80, 'Serializing to LIP format...');
    
    // Create serializer
    Serializer := TFalloutLipSerializer.Create;
    try
      Serializer.IncludeExtendedData := FOptions.IncludeExtendedData;
      Serializer.DebugMode := FOptions.DebugMode;
      
      // Serialize to LIP file
      LipFile := Serializer.Serialize(LipFrames, FOptions.FPS);
      try
        LipFile.FileName := OutputLip;
        
        // Save to file
        if not LipFile.SaveToFile(OutputLip) then
        begin
          Result.ErrorMessage := Format('Failed to save LIP file: %s', [OutputLip]);
          Exit;
        end;
        
        LogDebug(Format('Saved LIP file: %s', [OutputLip]));
        Result.Success := True;
        
        // Add warnings for unusual conditions
        if Result.FrameCount = 0 then
          Result.Warnings.Add('No frames generated - audio may be silent');
        
        if Buffer.Duration < 0.1 then
          Result.Warnings.Add('Audio duration is very short (< 100ms)');
        
        // Check for long silence periods
        if Result.FrameCount > 0 then
        begin
          for I := 0 to Min(Result.FrameCount - 1, 9) do
          begin
            if LipFrames[I].MouthState = msClosed then
            begin
              Result.Warnings.Add(Format('Extended silence detected at %.3fs', [LipFrames[I].Time]));
              Break;
            end;
          end;
        end;
        
      finally
        LipFile.Free;
      end;
    finally
      Serializer.Free;
    end;
    
    Result.ProcessingTime := (Now - StartTime) * 86400;
    
    DoProgress(100, 'Generation complete!');
    
  except
    on E: Exception do
    begin
      Result.ErrorMessage := Format('Error during generation: %s', [E.Message]);
      Result.Success := False;
    end;
  end;
end;

function TLipGenerator.GenerateLipFrames(Buffer: TAudioBuffer): TLipFrameArray;
var
  Analyzer: TAudioAnalyzer;
begin
  Analyzer := TAudioAnalyzer.Create(Buffer.SampleRate);
  try
    // Configure analyzer
    Analyzer.Threshold := FOptions.Threshold;
    Analyzer.MinSilenceDuration := FOptions.MinSilenceDuration;
    Analyzer.MinPhonemeDuration := FOptions.MinPhonemeDuration;
    
    // Generate frames
    Result := Analyzer.GenerateLipFrames(Buffer, FOptions.FPS);
    
    LogDebug(Format('Analysis complete: %d frames generated', [Length(Result)]));
  finally
    Analyzer.Free;
  end;
end;

function TLipGenerator.BatchProcess(const InputList, OutputList: TStringList): TArray<TLipGenResult>;
var
  I, Count: Integer;
begin
  Count := Min(InputList.Count, OutputList.Count);
  SetLength(Result, Count);
  
  for I := 0 to Count - 1 do
  begin
    DoProgress(Round((I / Count) * 100), Format('Processing %d of %d...', [I + 1, Count]));
    
    Result[I] := GenerateFromFile(InputList[I], OutputList[I]);
    
    LogDebug(Format('Batch item %d: %s -> %s (%s)',
      [I + 1,
       InputList[I],
       OutputList[I],
       IfThen(Result[I].Success, 'Success', Result[I].ErrorMessage)]));
  end;
  
  DoProgress(100, 'Batch processing complete');
end;

function TLipGenerator.ExportDebugInfo(const LipFile: string): string;
var
  Lip: TFalloutLipFile;
begin
  Lip := TFalloutLipFile.Create;
  try
    if Lip.LoadFromFile(LipFile) then
      Result := Lip.ExportDebugInfo
    else
      Result := Format('Failed to load LIP file: %s', [LipFile]);
  finally
    Lip.Free;
  end;
end;

function TLipGenerator.ExportToJSON(const LipFile: string): string;
var
  Lip: TFalloutLipFile;
begin
  Lip := TFalloutLipFile.Create;
  try
    if Lip.LoadFromFile(LipFile) then
      Result := Lip.ExportToJSON
    else
      Result := Format('{"error": "Failed to load LIP file: %s"}', [LipFile]);
  finally
    Lip.Free;
  end;
end;

function TLipGenerator.CompareFiles(const LipFile1, LipFile2: string): string;
var
  Serializer: TFalloutLipSerializer;
begin
  Serializer := TFalloutLipSerializer.Create;
  try
    Result := Serializer.CompareLipFiles(LipFile1, LipFile2);
  finally
    Serializer.Free;
  end;
end;

function TLipGenerator.ValidateLipFile(const LipFile: string): Boolean;
var
  Lip: TFalloutLipFile;
begin
  Lip := TFalloutLipFile.Create;
  try
    Result := Lip.LoadFromFile(LipFile) and Lip.IsValid;
  finally
    Lip.Free;
  end;
end;

function TLipGenerator.GetAudioInfo(const WavFile: string): string;
var
  WavReader: TWavReader;
begin
  WavReader := TWavReader.Create(WavFile);
  try
    Result := Format('File: %s'#13#10 +
      'Duration: %.3f seconds'#13#10 +
      'Sample Rate: %d Hz'#13#10 +
      'Bits per Sample: %d'#13#10 +
      'Channels: %d'#13#10 +
      'Data Size: %d bytes'#13#10 +
      'Format Supported: %s',
      [WavFile,
       WavReader.Duration,
       WavReader.SampleRate,
       WavReader.BitsPerSample,
       WavReader.Channels,
       WavReader.DataSize,
       BoolToStr(WavReader.IsFormatSupported, True)]);
  finally
    WavReader.Free;
  end;
end;

end.