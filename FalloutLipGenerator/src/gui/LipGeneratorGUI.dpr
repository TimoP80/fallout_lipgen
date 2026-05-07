(*
  Fallout Lip Generator - GUI Application
  
  Main project file for the GUI version.
  
  Copyright (c) 2026
  License: MIT
*)

program LipGeneratorGUI;

uses
  Forms,
  uMainForm in 'uMainForm.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Fallout Lip Generator';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.