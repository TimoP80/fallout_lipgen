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

interface

uses
  Classes, SysUtils, Math, StrUtils, uWavReader, uAudioBuffer, uSignalAnalysis, uFalloutLipFormat, uFalloutLipFormatV2;

type
  { Progress callback types }
  TProgressCallback = procedure(Progress: Integer; const Status: string) of object;
  TProgressProc     = procedure(Progress: Integer; const Status: string);

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

type
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

  TLipGenResultArray = array of TLipGenResult;

  { Main lip generator class }
  TLipGenerator = class
  private
    FOptions: TLipGenOptions;
    FOnProgress: TProgressCallback;
    FOnProgressProc: TProgressProc;
    FDebugLog: TStringList;
    
    procedure DoProgress(Progress: Integer; const Status: string);
    procedure LogDebug(const Msg: string);
    function ValidateOptions: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    
    { Generate LIP file from WAV file }
    function GenerateFromFile(const InputWav, OutputLip: string): TLipGenResult;
    
    { Generate LIP file from WAV file with optional text guidance }
    function GenerateFromFileWithText(const InputWav, OutputLip, DialogText: string): TLipGenResult;
    
    { Generate LIP file from audio buffer }
    function GenerateFromBuffer(Buffer: TAudioBuffer; const OutputLip: string): TLipGenResult;
    
    { Generate lip frames from audio buffer }
    function GenerateLipFrames(Buffer: TAudioBuffer): TLipFrameArray;
    
    { Batch process multiple files }
    function BatchProcess(const InputList, OutputList: TStringList): TLipGenResultArray;
    
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
    property OnProgressProc: TProgressProc read FOnProgressProc write FOnProgressProc;
    property DebugLog: TStringList read FDebugLog;
  end;

implementation

type
  TLipFormatKind = (lfUnknown, lfLegacy, lfV2);

{ Helper functions }

function MakeACMFileName(const LipFileName: string): string;
begin
  Result := UpperCase(ChangeFileExt(ExtractFileName(LipFileName), ''));
  if Length(Result) > 8 then
    SetLength(Result, 8);
end;

function DetectLipFormat(const LipFile: string): TLipFormatKind;
var
  Stream: TFileStream;
  Header: array[0..3] of Byte;
  Version: LongWord;
begin
  Result := lfUnknown;
  if not FileExists(LipFile) then
    Exit;

  Stream := TFileStream.Create(LipFile, fmOpenRead or fmShareDenyWrite);
  try
    if Stream.Read(Header, SizeOf(Header)) <> SizeOf(Header) then
      Exit;

    if (Header[0] = Ord('L')) and (Header[1] = Ord('I')) and
       (Header[2] = Ord('P')) and (Header[3] = 0) then
      Exit(lfLegacy);

    Move(Header, Version, SizeOf(Version));
    if Version = LIP_VERSION_2 then
      Result := lfV2;
  finally
    Stream.Free;
  end;
end;

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
  if Assigned(FOnProgressProc) then
    FOnProgressProc(Progress, Status);
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
  BufResult: TLipGenResult;
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

          // Generate lip frames - call GenerateFromBuffer once and store result
          BufResult := GenerateFromBuffer(AudioBuffer, OutputLip);
          Result.Success := BufResult.Success;
          Result.ErrorMessage := BufResult.ErrorMessage;
          Result.FrameCount := BufResult.FrameCount;
          if Assigned(BufResult.Warnings) then
            BufResult.Warnings.Free;
          
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

{ TLipGenerator.GenerateFromFileWithText }

function TLipGenerator.GenerateFromFileWithText(const InputWav, OutputLip, DialogText: string): TLipGenResult;
var
  WavReader: TWavReader;
  AudioBuffer: TAudioBuffer;
  StartTime: TDateTime;
  BufResult: TLipGenResult;
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

          DoProgress(50, 'Generating lip frames with text guidance...');

          // For now, delegate to the regular generation method
          // In a full implementation, this would use the DialogText to improve phoneme alignment
          BufResult := GenerateFromBuffer(AudioBuffer, OutputLip);
          Result.Success := BufResult.Success;
          Result.ErrorMessage := BufResult.ErrorMessage;
          Result.FrameCount := BufResult.FrameCount;
          if Assigned(BufResult.Warnings) then
            BufResult.Warnings.Free;

          // Add a note about text guidance being used
          if Trim(DialogText) <> '' then
            Result.Warnings.Add('Generation used dialog text guidance: "' + DialogText + '"');

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
var
  LipFrames: TLipFrameArray;
  LipFile: TFalloutLipFileV2;
  Serializer: TFalloutLipSerializerV2;
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
    Serializer := TFalloutLipSerializerV2.Create;
    try
      Serializer.DebugMode := FOptions.DebugMode;
      
      // Serialize to LIP file
      LipFile := Serializer.Serialize(LipFrames, MakeACMFileName(OutputLip));
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

function TLipGenerator.BatchProcess(const InputList, OutputList: TStringList): TLipGenResultArray;
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
  LipV2: TFalloutLipFileV2;
begin
  case DetectLipFormat(LipFile) of
    lfLegacy:
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
    lfV2:
      begin
        LipV2 := TFalloutLipFileV2.Create;
        try
          if LipV2.LoadFromFile(LipFile) then
            Result := LipV2.ExportDebugInfo
          else
            Result := Format('Failed to load LIP file: %s', [LipFile]);
        finally
          LipV2.Free;
        end;
      end;
  else
    Result := Format('Unknown or unsupported LIP format: %s', [LipFile]);
  end;
end;

function TLipGenerator.ExportToJSON(const LipFile: string): string;
var
  Lip: TFalloutLipFile;
  LipV2: TFalloutLipFileV2;
begin
  case DetectLipFormat(LipFile) of
    lfLegacy:
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
    lfV2:
      begin
        LipV2 := TFalloutLipFileV2.Create;
        try
          if LipV2.LoadFromFile(LipFile) then
            Result := LipV2.ExportToJSON
          else
            Result := Format('{"error": "Failed to load LIP file: %s"}', [LipFile]);
        finally
          LipV2.Free;
        end;
      end;
  else
    Result := Format('{"error": "Unknown or unsupported LIP format: %s"}', [LipFile]);
  end;
end;

function TLipGenerator.CompareFiles(const LipFile1, LipFile2: string): string;
var
  Serializer: TFalloutLipSerializer;
  SerializerV2: TFalloutLipSerializerV2;
  Format1, Format2: TLipFormatKind;
begin
  Format1 := DetectLipFormat(LipFile1);
  Format2 := DetectLipFormat(LipFile2);

  if Format1 <> Format2 then
  begin
    Result := 'Cannot compare LIP files with different internal formats.';
    Exit;
  end;

  case Format1 of
    lfLegacy:
      begin
        Serializer := TFalloutLipSerializer.Create;
        try
          Result := Serializer.CompareLipFiles(LipFile1, LipFile2);
        finally
          Serializer.Free;
        end;
      end;
    lfV2:
      begin
        SerializerV2 := TFalloutLipSerializerV2.Create;
        try
          Result := SerializerV2.CompareLipFiles(LipFile1, LipFile2);
        finally
          SerializerV2.Free;
        end;
      end;
  else
    Result := 'Unknown or unsupported LIP format.';
  end;
end;

function TLipGenerator.ValidateLipFile(const LipFile: string): Boolean;
var
  Lip: TFalloutLipFile;
  LipV2: TFalloutLipFileV2;
begin
  case DetectLipFormat(LipFile) of
    lfLegacy:
      begin
        Lip := TFalloutLipFile.Create;
        try
          Result := Lip.LoadFromFile(LipFile) and Lip.IsValid;
        finally
          Lip.Free;
        end;
      end;
    lfV2:
      begin
        LipV2 := TFalloutLipFileV2.Create;
        try
          Result := LipV2.LoadFromFile(LipFile) and LipV2.IsValid;
        finally
          LipV2.Free;
        end;
      end;
  else
    Result := False;
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
