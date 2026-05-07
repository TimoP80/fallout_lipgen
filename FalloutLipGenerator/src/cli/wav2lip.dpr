(*
  Fallout Lip Generator - Command Line Interface
  
  Command-line tool for converting WAV files to Fallout LIP format.
  
  Usage:
    wav2lip input.wav output.lip [options]
    
  Options:
    --fps 10|12|15       Set target FPS (default: 12)
    --threshold 0.08     Set energy threshold (default: 0.08)
    --normalize          Normalize audio (default: on)
    --nonormalize        Disable normalization
    --extended           Include extended frame data
    --debug              Enable debug output
    --export-json FILE   Export debug info to JSON
    --export-debug FILE  Export debug info to text
    --compare FILE       Compare with another LIP file
    --validate           Validate generated LIP file
    --batch              Process multiple files (input/output pairs)
    --help               Show this help
    
  Examples:
    wav2lip dialogue.wav dialogue.lip
    wav2lip input.wav output.lip --fps 15 --threshold 0.1 --debug
    wav2lip --compare original.lip generated.lip
    
  Copyright (c) 2026
  License: MIT
*)

program wav2lip;

uses
  SysUtils, Classes, uLipGenerator, uWavReader;

type
  { Command line options }
  TCommandLineOptions = record
    InputFile: string;
    OutputFile: string;
    FPS: Integer;
    Threshold: Double;
    Normalize: Boolean;
    ExtendedData: Boolean;
    DebugMode: Boolean;
    ExportJSON: string;
    ExportDebug: string;
    CompareFile: string;
    Validate: Boolean;
    BatchMode: Boolean;
    ShowHelp: Boolean;
  end;

{ Parse command line arguments }
function ParseCommandLine(var Options: TCommandLineOptions): Boolean;
var
  I: Integer;
  Arg: string;
begin
  Result := True;
  
  // Initialize options
  FillChar(Options, SizeOf(Options), 0);
  Options.FPS := 12;
  Options.Threshold := 0.08;
  Options.Normalize := True;
  Options.ShowHelp := False;
  
  I := 1;
  while I <= ParamCount do
  begin
    Arg := ParamStr(I);
    
    if (Arg = '--help') or (Arg = '-h') or (Arg = '/?') then
    begin
      Options.ShowHelp := True;
      Exit;
    end
    else if (I = 1) and (Arg[1] <> '-') and (Pos('.wav', LowerCase(Arg)) > 0) then
    begin
      // First non-option argument is input file
      Options.InputFile := Arg;
    end
    else if (I = 2) and (Options.InputFile <> '') and (Arg[1] <> '-') then
    begin
      // Second non-option argument is output file
      Options.OutputFile := Arg;
    end
    else if Arg = '--fps' then
    begin
      Inc(I);
      if I <= ParamCount then
        Options.FPS := StrToIntDef(ParamStr(I), 12)
      else
      begin
        WriteLn('Error: --fps requires a value (10, 12, or 15)');
        Result := False;
        Exit;
      end;
    end
    else if Arg = '--threshold' then
    begin
      Inc(I);
      if I <= ParamCount then
        Options.Threshold := StrToFloatDef(ParamStr(I), 0.08)
      else
      begin
        WriteLn('Error: --threshold requires a value');
        Result := False;
        Exit;
      end;
    end
    else if Arg = '--normalize' then
      Options.Normalize := True
    else if Arg = '--nonormalize' then
      Options.Normalize := False
    else if Arg = '--extended' then
      Options.ExtendedData := True
    else if Arg = '--debug' then
      Options.DebugMode := True
    else if Arg = '--export-json' then
    begin
      Inc(I);
      if I <= ParamCount then
        Options.ExportJSON := ParamStr(I)
      else
      begin
        WriteLn('Error: --export-json requires a filename');
        Result := False;
        Exit;
      end;
    end
    else if Arg = '--export-debug' then
    begin
      Inc(I);
      if I <= ParamCount then
        Options.ExportDebug := ParamStr(I)
      else
      begin
        WriteLn('Error: --export-debug requires a filename');
        Result := False;
        Exit;
      end;
    end
    else if Arg = '--compare' then
    begin
      Inc(I);
      if I <= ParamCount then
        Options.CompareFile := ParamStr(I)
      else
      begin
        WriteLn('Error: --compare requires a filename');
        Result := False;
        Exit;
      end;
    end
    else if Arg = '--validate' then
      Options.Validate := True
    else if Arg = '--batch' then
      Options.BatchMode := True
    else if Arg[1] = '-' then
    begin
      WriteLn('Error: Unknown option: ', Arg);
      Result := False;
      Exit;
    end
    else
    begin
      // Additional non-option arguments
      if Options.InputFile = '' then
        Options.InputFile := Arg
      else if Options.OutputFile = '' then
        Options.OutputFile := Arg;
    end;
    
    Inc(I);
  end;
  
  // Validate required arguments
  if not Options.ShowHelp and not Options.BatchMode then
  begin
    if Options.InputFile = '' then
    begin
      WriteLn('Error: Input file is required');
      Result := False;
    end
    else if Options.CompareFile = '' then
    begin
      // Normal mode requires output file
      if Options.OutputFile = '' then
      begin
        WriteLn('Error: Output file is required');
        Result := False;
      end;
    end;
  end;
end;

{ Show help message }
procedure ShowHelp;
begin
  WriteLn('Fallout Lip Generator - Command Line Interface');
  WriteLn('Usage: wav2lip input.wav output.lip [options]');
  WriteLn('');
  WriteLn('Options:');
  WriteLn('  --fps 10|12|15       Set target FPS (default: 12)');
  WriteLn('  --threshold 0.08     Set energy threshold (default: 0.08)');
  WriteLn('  --normalize          Normalize audio (default: on)');
  WriteLn('  --nonormalize        Disable normalization');
  WriteLn('  --extended           Include extended frame data');
  WriteLn('  --debug              Enable debug output');
  WriteLn('  --export-json FILE   Export debug info to JSON');
  WriteLn('  --export-debug FILE  Export debug info to text');
  WriteLn('  --compare FILE       Compare with another LIP file');
  WriteLn('  --validate           Validate generated LIP file');
  WriteLn('  --batch              Process multiple files (input/output pairs)');
  WriteLn('  --help               Show this help');
  WriteLn('');
  WriteLn('Examples:');
  WriteLn('  wav2lip dialogue.wav dialogue.lip');
  WriteLn('  wav2lip input.wav output.lip --fps 15 --threshold 0.1 --debug');
  WriteLn('  wav2lip --compare original.lip generated.lip');
  WriteLn('');
  WriteLn('Supported formats:');
  WriteLn('  - Uncompressed PCM WAV files');
  WriteLn('  - 8-bit or 16-bit samples');
  WriteLn('  - Mono audio');
  WriteLn('  - Any sample rate (22050 Hz recommended)');
end;

{ Progress callback }
procedure ProgressCallback(Progress: Integer; const Status: string);
begin
  Write(Format(#13'Progress: %3d%% - %s', [Progress, Status]));
end;

{ Main program }
var
  Generator: TLipGenerator;
  Options: TCommandLineOptions;
  GenOptions: TLipGenOptions;
  GenResult: TLipGenResult;
  WavReader: TWavReader;
  ExportList: TStringList;
  I: Integer;
begin
  // Parse command line
  if not ParseCommandLine(Options) then
  begin
    WriteLn('Use --help for usage information');
    Exit;
  end;
  
  // Show help if requested
  if Options.ShowHelp then
  begin
    ShowHelp;
    Exit;
  end;
  
  // Create generator
  Generator := TLipGenerator.Create;
  GenResult.Warnings := nil;
  WavReader := nil;
  ExportList := nil;
  try
    // Configure generator
    GenOptions := Generator.Options;
    GenOptions.FPS := Options.FPS;
    GenOptions.Threshold := Options.Threshold;
    GenOptions.Normalize := Options.Normalize;
    GenOptions.IncludeExtendedData := Options.ExtendedData;
    GenOptions.DebugMode := Options.DebugMode;
    Generator.Options := GenOptions;
    Generator.OnProgressProc := ProgressCallback;
    
    // Handle compare mode
    if Options.CompareFile <> '' then
    begin
      WriteLn('Comparing LIP files...');
      WriteLn('');
      WriteLn(Generator.CompareFiles(Options.InputFile, Options.CompareFile));
      Exit;
    end;
    
    // Handle batch mode
    if Options.BatchMode then
    begin
      WriteLn('Batch mode not fully implemented in CLI version');
      WriteLn('Use GUI version for batch processing');
      Exit;
    end;
    
    // Normal mode: convert single file
    WriteLn('Fallout Lip Generator - CLI');
    WriteLn('============================');
    WriteLn('');
    WriteLn(Format('Input:  %s', [Options.InputFile]));
    WriteLn(Format('Output: %s', [Options.OutputFile]));
    WriteLn(Format('FPS: %d', [Options.FPS]));
    WriteLn(Format('Threshold: %.3f', [Options.Threshold]));
    WriteLn(Format('Normalize: %s', [BoolToStr(Options.Normalize, True)]));
    WriteLn('');
    
    // Check if input file exists
    if not FileExists(Options.InputFile) then
    begin
      WriteLn(Format('Error: Input file not found: %s', [Options.InputFile]));
      Exit;
    end;
    
    // If input is WAV, show info
    if LowerCase(ExtractFileExt(Options.InputFile)) = '.wav' then
    begin
      try
        WavReader := nil;
        WavReader := TWavReader.Create(Options.InputFile);
        try
          WriteLn('Audio Information:');
          WriteLn(Format('  Duration: %.3f seconds', [WavReader.Duration]));
          WriteLn(Format('  Sample Rate: %d Hz', [WavReader.SampleRate]));
          WriteLn(Format('  Bits per Sample: %d', [WavReader.BitsPerSample]));
          WriteLn(Format('  Channels: %d', [WavReader.Channels]));
          WriteLn('');
        finally
          WavReader.Free;
        end;
      except
        // Ignore errors
      end;
    end;
    
    // Generate LIP file
    WriteLn('Generating...');
    GenResult := Generator.GenerateFromFile(Options.InputFile, Options.OutputFile);
    
    WriteLn('');
    
    if GenResult.Success then
    begin
      WriteLn('Success!');
      WriteLn(Format('Output file: %s', [GenResult.OutputFile]));
      WriteLn(Format('Duration: %.3f seconds', [GenResult.Duration]));
      WriteLn(Format('Frames generated: %d', [GenResult.FrameCount]));
      WriteLn(Format('Processing time: %.3f seconds', [GenResult.ProcessingTime]));
      
      // Export JSON debug info if requested
      if Options.ExportJSON <> '' then
      begin
        WriteLn('');
        WriteLn(Format('Exporting JSON to: %s', [Options.ExportJSON]));
        ExportList := TStringList.Create;
        try
          ExportList.Text := Generator.ExportToJSON(Options.OutputFile);
          ExportList.SaveToFile(Options.ExportJSON);
        finally
          ExportList.Free;
          ExportList := nil;
        end;
      end;
      
      if Options.ExportDebug <> '' then
      begin
        WriteLn('');
        WriteLn(Format('Exporting debug info to: %s', [Options.ExportDebug]));
        ExportList := TStringList.Create;
        try
          ExportList.Text := Generator.ExportDebugInfo(Options.OutputFile);
          ExportList.SaveToFile(Options.ExportDebug);
        finally
          ExportList.Free;
          ExportList := nil;
        end;
      end;
      
      // Validate if requested
      if Options.Validate then
      begin
        WriteLn('');
        WriteLn('Validating LIP file...');
        if Generator.ValidateLipFile(Options.OutputFile) then
          WriteLn('Validation: PASSED')
        else
          WriteLn('Validation: FAILED');
      end;
      
      // Show warnings
      if Assigned(GenResult.Warnings) and (GenResult.Warnings.Count > 0) then
      begin
        WriteLn('');
        WriteLn('Warnings:');
        for I := 0 to GenResult.Warnings.Count - 1 do
          WriteLn(Format('  - %s', [GenResult.Warnings[I]]));
      end;
      
      // Show debug log if enabled
      if Options.DebugMode and (Generator.DebugLog.Count > 0) then
      begin
        WriteLn('');
        WriteLn('Debug Log:');
        for I := 0 to Generator.DebugLog.Count - 1 do
          WriteLn(Format('  %s', [Generator.DebugLog[I]]));
      end;
    end
    else
    begin
      WriteLn('Error: ' + GenResult.ErrorMessage);
      ExitCode := 1;
    end;
    
  finally
    ExportList.Free;
    Generator.Free;
    if Assigned(GenResult.Warnings) then
      GenResult.Warnings.Free;
  end;
end.
