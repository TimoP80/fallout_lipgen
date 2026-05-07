(*
  Fallout Lip Generator - Example Usage
  
  Example programs demonstrating various use cases.
  
  Copyright (c) 2026
  License: MIT
*)

program Examples;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, uFalloutLipGenerator;

{ Example 1: Basic WAV to LIP conversion }
procedure Example1_BasicConversion;
var
  Generator: TLipGenerator;
  Result: TLipGenResult;
begin
  WriteLn('Example 1: Basic WAV to LIP Conversion');
  WriteLn('=======================================');
  
  Generator := TLipGenerator.Create;
  try
    // Use default options
    Result := Generator.GenerateFromFile('dialogue.wav', 'dialogue.lip');
    
    if Result.Success then
    begin
      WriteLn('Success!');
      WriteLn(Format('  Frames: %d', [Result.FrameCount]));
      WriteLn(Format('  Duration: %.3f seconds', [Result.Duration]));
      WriteLn(Format('  Processing time: %.3f seconds', [Result.ProcessingTime]));
    end
    else
    begin
      WriteLn('Failed: ' + Result.ErrorMessage);
    end;
    
    Result.Warnings.Free;
  finally
    Generator.Free;
  end;
  
  WriteLn;
end;

{ Example 2: Custom options }
procedure Example2_CustomOptions;
var
  Generator: TLipGenerator;
  Result: TLipGenResult;
begin
  WriteLn('Example 2: Custom Options');
  WriteLn('==========================');
  
  Generator := TLipGenerator.Create;
  try
    // Configure custom options
    Generator.Options.FPS := 15;
    Generator.Options.Threshold := 0.1;
    Generator.Options.Normalize := True;
    Generator.Options.IncludeExtendedData := True;
    Generator.Options.DebugMode := True;
    
    Result := Generator.GenerateFromFile('speech.wav', 'speech.lip');
    
    if Result.Success then
    begin
      WriteLn('Success with custom options!');
      WriteLn(Format('  FPS: %d', [Generator.Options.FPS]));
      WriteLn(Format('  Threshold: %.2f', [Generator.Options.Threshold]));
      WriteLn(Format('  Frames: %d', [Result.FrameCount]));
    end
    else
    begin
      WriteLn('Failed: ' + Result.ErrorMessage);
    end;
    
    Result.Warnings.Free;
  finally
    Generator.Free;
  end;
  
  WriteLn;
end;

{ Example 3: Batch processing }
procedure Example3_BatchProcessing;
var
  Generator: TLipGenerator;
  Inputs, Outputs: TStringList;
  Results: TArray<TLipGenResult>;
  I: Integer;
begin
  WriteLn('Example 3: Batch Processing');
  WriteLn('============================');
  
  Generator := TLipGenerator.Create;
  Inputs := TStringList.Create;
  Outputs := TStringList.Create;
  try
    // Add files to batch
    Inputs.Add('line01.wav');
    Outputs.Add('line01.lip');
    Inputs.Add('line02.wav');
    Outputs.Add('line02.lip');
    Inputs.Add('line03.wav');
    Outputs.Add('line03.lip');
    
    // Process batch
    Results := Generator.BatchProcess(Inputs, Outputs);
    
    // Show results
    for I := 0 to High(Results) do
    begin
      WriteLn(Format('  %s -> %s: %s',
        [ExtractFileName(Inputs[I]),
         ExtractFileName(Outputs[I]),
         IfThen(Results[I].Success, 'OK', 'FAILED')]));
      
      if not Results[I].Success then
        WriteLn('    Error: ' + Results[I].ErrorMessage);
      
      Results[I].Warnings.Free;
    end;
  finally
    Outputs.Free;
    Inputs.Free;
    Generator.Free;
  end;
  
  WriteLn;
end;

{ Example 4: Analyze existing LIP file }
procedure Example4_AnalyzeLipFile;
var
  Generator: TLipGenerator;
  LipFile: TFalloutLipFile;
  JSON, Debug: string;
begin
  WriteLn('Example 4: Analyze Existing LIP File');
  WriteLn('======================================');
  
  Generator := TLipGenerator.Create;
  LipFile := TFalloutLipFile.Create;
  try
    // Load existing LIP file
    if LipFile.LoadFromFile('existing.lip') then
    begin
      WriteLn('File loaded successfully');
      WriteLn(Format('  Frames: %d', [LipFile.FrameCount]));
      WriteLn(Format('  FPS: %d', [LipFile.Header.FPS]));
      WriteLn(Format('  Duration: %.3f seconds', [LipFile.Duration]));
      
      // Export to JSON
      JSON := Generator.ExportToJSON('existing.lip');
      WriteLn('');
      WriteLn('JSON Export (first 500 chars):');
      WriteLn(Copy(JSON, 1, 500));
      
      // Export debug info
      Debug := Generator.ExportDebugInfo('existing.lip');
      WriteLn('');
      WriteLn('Debug Info (first 500 chars):');
      WriteLn(Copy(Debug, 1, 500));
    end
    else
    begin
      WriteLn('Failed to load LIP file');
    end;
  finally
    LipFile.Free;
    Generator.Free;
  end;
  
  WriteLn;
end;

{ Example 5: Compare two LIP files }
procedure Example5_CompareFiles;
var
  Generator: TLipGenerator;
  Comparison: string;
begin
  WriteLn('Example 5: Compare Two LIP Files');
  WriteLn('==================================');
  
  Generator := TLipGenerator.Create;
  try
    Comparison := Generator.CompareFiles('original.lip', 'generated.lip');
    WriteLn(Comparison);
  finally
    Generator.Free;
  end;
  
  WriteLn;
end;

{ Example 6: Direct audio buffer processing }
procedure Example6_AudioBufferProcessing;
var
  Generator: TLipGenerator;
  Reader: TWavReader;
  Buffer: TAudioBuffer;
  Frames: TLipFrameArray;
  I: Integer;
begin
  WriteLn('Example 6: Direct Audio Buffer Processing');
  WriteLn('==========================================');
  
  Generator := TLipGenerator.Create;
  Reader := nil;
  Buffer := nil;
  try
    // Load WAV file
    Reader := TWavReader.Create('audio.wav');
    Buffer := Reader.LoadToBuffer;
    
    WriteLn(Format('Loaded audio: %.3f seconds', [Buffer.Duration]));
    
    // Generate lip frames directly
    Frames := Generator.GenerateLipFrames(Buffer);
    
    WriteLn(Format('Generated %d frames', [Length(Frames)]));
    
    // Show first 10 frames
    WriteLn('');
    WriteLn('First 10 frames:');
    for I := 0 to Min(9, High(Frames)) do
    begin
      WriteLn(Format('  Frame %d: Time=%.3fs, State=%s, Intensity=%.2f',
        [I,
         Frames[I].Time,
         MouthStateToString(Frames[I].MouthState),
         Frames[I].Intensity]));
    end;
    
    // Save to LIP file
    var LipFile: TFalloutLipFile := TFalloutLipFile.Create;
    try
      LipFile.FromLipFrames(Frames, 12);
      LipFile.SaveToFile('output.lip');
      WriteLn('');
      WriteLn('Saved to output.lip');
    finally
      LipFile.Free;
    end;
    
  finally
    Buffer.Free;
    Reader.Free;
    Generator.Free;
  end;
  
  WriteLn;
end;

{ Example 7: Signal analysis }
procedure Example7_SignalAnalysis;
var
  Analyzer: TAudioAnalyzer;
  Reader: TWavReader;
  Buffer: TAudioBuffer;
  Envelope: array of Double;
  Silence: array of TPointF;
  I: Integer;
begin
  WriteLn('Example 7: Signal Analysis');
  WriteLn('===========================');
  
  Analyzer := TAudioAnalyzer.Create(22050);
  Reader := nil;
  Buffer := nil;
  try
    // Load audio
    Reader := TWavReader.Create('audio.wav');
    Buffer := Reader.LoadToBuffer;
    
    // Calculate energy envelope
    Envelope := Analyzer.CalculateEnergyEnvelope(Buffer);
    WriteLn(Format('Calculated envelope with %d samples', [Length(Envelope)]));
    
    // Detect silence
    Silence := Analyzer.DetectSilence(Buffer, 0.05);
    WriteLn(Format('Detected %d silence regions', [Length(Silence) div 2]));
    
    // Show silence regions
    for I := 0 to (Length(Silence) div 2) - 1 do
    begin
      WriteLn(Format('  Silence %d: %.3f - %.3f seconds',
        [I + 1, Silence[I*2].X, Silence[I*2].Y]));
    end;
    
  finally
    Buffer.Free;
    Reader.Free;
    Analyzer.Free;
  end;
  
  WriteLn;
end;

{ Main program }
begin
  WriteLn('Fallout Lip Generator - Example Programs');
  WriteLn('=========================================');
  WriteLn('');
  
  // Note: These examples assume WAV files exist
  // Uncomment the examples you want to run
  
  // Example1_BasicConversion;
  // Example2_CustomOptions;
  // Example3_BatchProcessing;
  // Example4_AnalyzeLipFile;
  // Example5_CompareFiles;
  // Example6_AudioBufferProcessing;
  // Example7_SignalAnalysis;
  
  WriteLn('Note: To run examples, uncomment them in the source code.');
  WriteLn('Make sure the required WAV files exist in the current directory.');
  WriteLn('');
  WriteLn('Press Enter to exit...');
  ReadLn;
end.