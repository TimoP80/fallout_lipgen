(*
  Fallout Lip Generator - GUI Application
  
  Main project file for the GUI version.
  
  Copyright (c) 2026
  License: MIT
*)

program LipGeneratorGUI;

uses
  Forms,
  uMainForm in 'uMainForm.pas',
  uLipGenerator in '..\core\uLipGenerator.pas',
  uWavReader in '..\audio\uWavReader.pas',
  uAudioBuffer in '..\audio\uAudioBuffer.pas',
  uSignalAnalysis in '..\lip\uSignalAnalysis.pas',
  uFalloutLipFormat in '..\format\uFalloutLipFormat.pas',
  uFalloutLipFormatV2 in '..\format\uFalloutLipFormatV2.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Fallout Lip Generator';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.