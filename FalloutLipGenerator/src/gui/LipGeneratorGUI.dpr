(*
  Fallout Lip Generator - GUI Application
  
  Main project file for the GUI version.
  
  Copyright (c) 2026
  License: MIT
*)

program LipGeneratorGUI;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  uMainForm in 'uMainForm.pas' {frmMain};

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.Title := 'Fallout Lip Generator';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.