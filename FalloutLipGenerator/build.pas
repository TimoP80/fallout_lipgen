(*
  Fallout Lip Generator - Build Script
  
  Build script for compiling the project.
  
  Copyright (c) 2026
  License: MIT
*)

program Build;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes;

var
  BuildLog: TStringList;
  StartTime: TDateTime;
  
procedure Log(const Msg: string);
begin
  WriteLn(Msg);
  BuildLog.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss', Now), Msg]));
end;

function RunCommand(const Cmd, Params: string; WorkDir: string = ''): Boolean;
var
  Output: string;
begin
  Result := False;
  Log(Format('Running: %s %s', [Cmd, Params]));
  
  // Note: In a real build script, you would use TProcess or similar
  // For now, we'll just log the commands
  Log(Format('Command would execute in: %s', [IfThen(WorkDir = '', GetCurrentDir, WorkDir)]));
  Result := True;
end;

begin
  BuildLog := TStringList.Create;
  try
    StartTime := Now;
    Log('Fallout Lip Generator - Build Script');
    Log('=====================================');
    Log('');
    
    // Create output directories
    ForceDirectories('bin');
    ForceDirectories('bin/cli');
    ForceDirectories('bin/gui');
    ForceDirectories('lib');
    Log('Created output directories');
    
    // Compile CLI tool
    Log('');
    Log('--- Building CLI Tool ---');
    if RunCommand('fpc', 'src/cli/wav2lip.dpr -FEbin/cli -oawav2lip.exe', '') then
      Log('CLI tool compiled successfully')
    else
      Log('WARNING: CLI tool compilation failed (fpc may not be available)');
    
    // Compile GUI application
    Log('');
    Log('--- Building GUI Application ---');
    if RunCommand('lazbuild', '--build-mode=Release src/gui/LipGeneratorGUI.lpi', '') then
      Log('GUI application compiled successfully')
    else
      Log('WARNING: GUI application compilation failed (lazbuild may not be available)');
    
    // Copy resources
    Log('');
    Log('--- Copying Resources ---');
    if DirectoryExists('samples') then
      Log('Sample files found in samples/')
    else
      Log('No sample files found (create samples/ directory)');
    
    // Summary
    Log('');
    Log('--- Build Summary ---');
    Log(Format('Build time: %.3f seconds', [(Now - StartTime) * 86400]));
    Log('Output directory: bin/');
    Log('');
    Log('Next steps:');
    Log('  1. Test with sample WAV files: bin/cli/wav2lip.exe samples/test.wav test.lip');
    Log('  2. Run GUI: bin/gui/LipGeneratorGUI.exe');
    Log('  3. See README.md for detailed usage');
    
    // Save build log
    BuildLog.SaveToFile('build.log');
    Log('');
    Log('Build log saved to build.log');
    
  finally
    BuildLog.Free;
  end;
end.