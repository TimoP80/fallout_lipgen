(*
  Fallout Lip Generator - GUI Application
  
  Main form for the lip-sync generation GUI.
  Provides visual tools for WAV file analysis and LIP file generation.
  
  Copyright (c) 2026
  License: MIT
*)

unit uMainForm;


interface

uses
  Classes, SysUtils, Math, System.UITypes, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Menus, ActnList, Buttons, Grids, uLipGenerator,
  uWavReader, uAudioBuffer, uFalloutLipFormat, uFalloutLipFormatV2;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    actCompare: TAction;
    actExportDebug: TAction;
    actExportJSON: TAction;
    actGenerate: TAction;
    actLoadWav: TAction;
    actLoadLip: TAction;
    actNew: TAction;
    actOpen: TAction;
    actQuit: TAction;
    actSave: TAction;
    actSaveAs: TAction;
    actValidate: TAction;
    ActionList1: TActionList;
    btnAddToBatch: TButton;
    btnClearBatch: TButton;
    btnGenerate: TButton;
    btnRemoveFromBatch: TButton;
    chkDebug: TCheckBox;
    chkExtendedData: TCheckBox;
    chkNormalize: TCheckBox;
    cmbFPS: TComboBox;
    edtInputFile: TEdit;
    edtOutputFile: TEdit;
    edtThreshold: TEdit;
    gbAudioInfo: TGroupBox;
    gbBatch: TGroupBox;
    gbGeneration: TGroupBox;
    gbLipInfo: TGroupBox;
    gbWaveform: TGroupBox;
    lblAudioDuration: TLabel;
    lblAudioDurationVal: TLabel;
    lblAudioFile: TLabel;
    lblAudioSampleRate: TLabel;
    lblAudioSampleRateVal: TLabel;
    lblBitsPerSample: TLabel;
    lblBitsPerSampleVal: TLabel;
    lblChannels: TLabel;
    lblChannelsVal: TLabel;
    lblFPS: TLabel;
    lblInputFile: TLabel;
    lblLipDuration: TLabel;
    lblLipDurationVal: TLabel;
    lblLipFile: TLabel;
    lblLipFrameCount: TLabel;
    lblLipFrameCountVal: TLabel;
    lblLipFPS: TLabel;
    lblLipFPSVal: TLabel;
    lblOutputFile: TLabel;
    lblThreshold: TLabel;
    lblThresholdVal: TLabel;
    lblTitle: TLabel;
    lblVersion: TLabel;
    lbBatchList: TListBox;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    MenuItem19: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem20: TMenuItem;
    MenuItem21: TMenuItem;
    MenuItem22: TMenuItem;
    MenuItem23: TMenuItem;
    MenuItem24: TMenuItem;
    MenuItem25: TMenuItem;
    MenuItem26: TMenuItem;
    MenuItem27: TMenuItem;
    MenuItem28: TMenuItem;
    MenuItem29: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem30: TMenuItem;
    MenuItem31: TMenuItem;
    MenuItem32: TMenuItem;
    MenuItem33: TMenuItem;
    MenuItem34: TMenuItem;
    MenuItem35: TMenuItem;
    MenuItem36: TMenuItem;
    MenuItem37: TMenuItem;
    MenuItem38: TMenuItem;
    MenuItem39: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem40: TMenuItem;
    MenuItem41: TMenuItem;
    MenuItem42: TMenuItem;
    MenuItem43: TMenuItem;
    MenuItem44: TMenuItem;
    MenuItem45: TMenuItem;
    MenuItem46: TMenuItem;
    MenuItem47: TMenuItem;
    MenuItem48: TMenuItem;
    MenuItem49: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem50: TMenuItem;
    MenuItem51: TMenuItem;
    MenuItem52: TMenuItem;
    MenuItem53: TMenuItem;
    MenuItem54: TMenuItem;
    MenuItem55: TMenuItem;
    MenuItem56: TMenuItem;
    MenuItem57: TMenuItem;
    MenuItem58: TMenuItem;
    MenuItem59: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem60: TMenuItem;
    MenuItem61: TMenuItem;
    MenuItem62: TMenuItem;
    MenuItem63: TMenuItem;
    MenuItem64: TMenuItem;
    MenuItem65: TMenuItem;
    MenuItem66: TMenuItem;
    MenuItem67: TMenuItem;
    MenuItem68: TMenuItem;
    MenuItem69: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem70: TMenuItem;
    MenuItem71: TMenuItem;
    MenuItem72: TMenuItem;
    MenuItem73: TMenuItem;
    MenuItem74: TMenuItem;
    MenuItem75: TMenuItem;
    MenuItem76: TMenuItem;
    MenuItem77: TMenuItem;
    MenuItem78: TMenuItem;
    MenuItem79: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem80: TMenuItem;
    MenuItem81: TMenuItem;
    MenuItem82: TMenuItem;
    MenuItem83: TMenuItem;
    MenuItem84: TMenuItem;
    MenuItem85: TMenuItem;
    MenuItem86: TMenuItem;
    MenuItem87: TMenuItem;
    MenuItem88: TMenuItem;
    MenuItem89: TMenuItem;
    MenuItem9: TMenuItem;
    MenuItem90: TMenuItem;
    MenuItem91: TMenuItem;
    MenuItem92: TMenuItem;
    MenuItem93: TMenuItem;
    MenuItem94: TMenuItem;
    MenuItem95: TMenuItem;
    MenuItem96: TMenuItem;
    MenuItem97: TMenuItem;
    MenuItem98: TMenuItem;
    MenuItem99: TMenuItem;
    OpenDialog1: TOpenDialog;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    pbWaveform: TPaintBox;
    ProgressBar1: TProgressBar;
    SaveDialog1: TSaveDialog;
    sbMain: TStatusBar;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    tmrProgress: TTimer;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    procedure actCompareExecute(Sender: TObject);
    procedure actExportDebugExecute(Sender: TObject);
    procedure actExportJSONExecute(Sender: TObject);
    procedure actGenerateExecute(Sender: TObject);
    procedure actLoadLipExecute(Sender: TObject);
    procedure actLoadWavExecute(Sender: TObject);
    procedure actNewExecute(Sender: TObject);
    procedure actOpenExecute(Sender: TObject);
    procedure actQuitExecute(Sender: TObject);
    procedure actSaveAsExecute(Sender: TObject);
    procedure actSaveExecute(Sender: TObject);
    procedure actValidateExecute(Sender: TObject);
    procedure btnAddToBatchClick(Sender: TObject);
    procedure btnClearBatchClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnRemoveFromBatchClick(Sender: TObject);
    procedure cmbFPSChange(Sender: TObject);
    procedure edtThresholdChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pbWaveformPaint(Sender: TObject);
    procedure tmrProgressTimer(Sender: TObject);
  private
    FGenerator: TLipGenerator;
    FWavReader: TWavReader;
    FAudioBuffer: TAudioBuffer;
    FLipFile: TFalloutLipFile;
    FLipFileV2: TFalloutLipFileV2;
    FWaveformData: array of Double;
    FProcessing: Boolean;
    FCurrentProgress: Integer;
    
    procedure UpdateControls;
    procedure UpdateAudioInfo;
    procedure UpdateLipInfo;
    procedure UpdateWaveform;
    procedure UpdateThresholdLabel;
    procedure LoadWavFile(const FileName: string);
    procedure LoadLipFile(const FileName: string);
    procedure GenerateLipFile;
    procedure AddToBatch(const InputFile, OutputFile: string);
    procedure ClearBatch;
    procedure ShowErrorMessage(const Msg: string);
    procedure ShowInfoMessage(const Msg: string);
    procedure UpdateProgress(Progress: Integer; const Status: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

{ TfrmMain }

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  FGenerator := TLipGenerator.Create;
  FWavReader := nil;
  FAudioBuffer := nil;
  FLipFile := nil;
  FLipFileV2 := nil;
  FProcessing := False;
  FCurrentProgress := 0;
  
  // Initialize FPS combo
  cmbFPS.Items.Add('10 FPS');
  cmbFPS.Items.Add('12 FPS');
  cmbFPS.Items.Add('15 FPS');
  cmbFPS.ItemIndex := 1; // 12 FPS default
  
  // Set default threshold
  edtThreshold.Text := '0.08';
  
  // Update controls
  UpdateControls;
  UpdateThresholdLabel;
end;

destructor TfrmMain.Destroy;
begin
  ClearBatch;
  
  if Assigned(FAudioBuffer) then
    FAudioBuffer.Free;
  
  if Assigned(FWavReader) then
    FWavReader.Free;
  
  if Assigned(FLipFile) then
    FLipFile.Free;

  if Assigned(FLipFileV2) then
    FLipFileV2.Free;
  
  FGenerator.Free;
  
  inherited Destroy;
end;

procedure TfrmMain.UpdateControls;
begin
  actGenerate.Enabled := (edtInputFile.Text <> '') and (edtOutputFile.Text <> '');
  actLoadWav.Enabled := not FProcessing;
  actLoadLip.Enabled := not FProcessing;
  actValidate.Enabled := (edtOutputFile.Text <> '') and FileExists(edtOutputFile.Text);
  actCompare.Enabled := (edtOutputFile.Text <> '') and FileExists(edtOutputFile.Text);
  actExportJSON.Enabled := (edtOutputFile.Text <> '') and FileExists(edtOutputFile.Text);
  actExportDebug.Enabled := (edtOutputFile.Text <> '') and FileExists(edtOutputFile.Text);
  btnGenerate.Enabled := actGenerate.Enabled and not FProcessing;
  btnAddToBatch.Enabled := (edtInputFile.Text <> '') and (edtOutputFile.Text <> '');
  btnClearBatch.Enabled := lbBatchList.Items.Count > 0;
  btnRemoveFromBatch.Enabled := lbBatchList.ItemIndex >= 0;
  cmbFPS.Enabled := not FProcessing;
  edtThreshold.Enabled := not FProcessing;
  chkNormalize.Enabled := not FProcessing;
  chkExtendedData.Enabled := not FProcessing;
  chkDebug.Enabled := not FProcessing;
end;

procedure TfrmMain.UpdateAudioInfo;
begin
  if Assigned(FWavReader) and FWavReader.IsValid then
  begin
    lblAudioFile.Caption := ExtractFileName(edtInputFile.Text);
    lblAudioDurationVal.Caption := Format('%.3f seconds', [FWavReader.Duration]);
    lblAudioSampleRateVal.Caption := Format('%d Hz', [FWavReader.SampleRate]);
    lblBitsPerSampleVal.Caption := Format('%d bits', [FWavReader.BitsPerSample]);
    lblChannelsVal.Caption := Format('%d channel(s)', [FWavReader.Channels]);
  end
  else
  begin
    lblAudioFile.Caption := 'No file loaded';
    lblAudioDurationVal.Caption := '--';
    lblAudioSampleRateVal.Caption := '--';
    lblBitsPerSampleVal.Caption := '--';
    lblChannelsVal.Caption := '--';
  end;
end;

procedure TfrmMain.UpdateLipInfo;
begin
  if Assigned(FLipFileV2) and FLipFileV2.IsValid then
  begin
    lblLipFile.Caption := ExtractFileName(edtOutputFile.Text);
    lblLipDurationVal.Caption := Format('%.3f seconds', [FLipFileV2.GetDuration]);
    lblLipFrameCountVal.Caption := Format('%d phonemes', [FLipFileV2.PhonemeCount]);
    lblLipFPSVal.Caption := 'V2';
  end
  else if Assigned(FLipFile) and FLipFile.IsValid then
  begin
    lblLipFile.Caption := ExtractFileName(edtOutputFile.Text);
    lblLipDurationVal.Caption := Format('%.3f seconds', [FLipFile.Duration]);
    lblLipFrameCountVal.Caption := Format('%d frames', [FLipFile.FrameCount]);
    lblLipFPSVal.Caption := Format('%d FPS', [FLipFile.Header.FPS]);
  end
  else
  begin
    lblLipFile.Caption := 'No file loaded';
    lblLipDurationVal.Caption := '--';
    lblLipFrameCountVal.Caption := '--';
    lblLipFPSVal.Caption := '--';
  end;
end;

procedure TfrmMain.UpdateWaveform;
begin
  pbWaveform.Invalidate;
end;

procedure TfrmMain.UpdateThresholdLabel;
begin
  lblThresholdVal.Caption := Format('Threshold: %s', [edtThreshold.Text]);
end;

procedure TfrmMain.LoadWavFile(const FileName: string);
var
  Step, I: Integer;
begin
  try
    // Free existing resources
    if Assigned(FAudioBuffer) then
      FreeAndNil(FAudioBuffer);

    if Assigned(FWavReader) then
      FreeAndNil(FWavReader);

    // Load WAV file
    FWavReader := TWavReader.Create(FileName);

    if not FWavReader.IsFormatSupported then
    begin
      ShowErrorMessage('Unsupported WAV format. Please use uncompressed PCM WAV files (8-bit or 16-bit, mono).');
      FreeAndNil(FWavReader);
      Exit;
    end;

    // Load to buffer
    FAudioBuffer := FWavReader.LoadToBuffer;

    // Normalize if checked
    if chkNormalize.Checked and Assigned(FAudioBuffer) then
      FAudioBuffer.Normalize;

    // Update display
    edtInputFile.Text := FileName;
    edtOutputFile.Text := ChangeFileExt(FileName, '.lip');
    UpdateAudioInfo;

    // Generate waveform data
    if Assigned(FAudioBuffer) then
    begin
      SetLength(FWaveformData, Min(FAudioBuffer.SampleCount, 10000));

      // Downsample for display
      if FAudioBuffer.SampleCount > 10000 then
      begin
        Step := FAudioBuffer.SampleCount div 10000;
        for I := 0 to 9999 do
          FWaveformData[I] := FAudioBuffer[I * Step];
      end
      else
      begin
        for I := 0 to FAudioBuffer.SampleCount - 1 do
          FWaveformData[I] := FAudioBuffer[I];
      end;
    end;

    UpdateWaveform;
    UpdateControls;

    ShowInfoMessage(Format('Loaded WAV file: %s (%.3f seconds)', [FileName, FWavReader.Duration]));

  except
    on E: Exception do
    begin
      ShowErrorMessage(Format('Error loading WAV file: %s', [E.Message]));
      FreeAndNil(FWavReader);
      FreeAndNil(FAudioBuffer);
    end;
  end;
end;

procedure TfrmMain.LoadLipFile(const FileName: string);
begin
  try
    // Free existing lip file
    if Assigned(FLipFile) then
      FreeAndNil(FLipFile);
    if Assigned(FLipFileV2) then
      FreeAndNil(FLipFileV2);
    
    FLipFileV2 := TFalloutLipFileV2.Create;
    try
      if not (FLipFileV2.LoadFromFile(FileName) and FLipFileV2.IsValid) then
        FreeAndNil(FLipFileV2);
    except
      FreeAndNil(FLipFileV2);
    end;

    if not Assigned(FLipFileV2) then
    begin
      // Load legacy LIP file
      FLipFile := TFalloutLipFile.Create;
      
      if not FLipFile.LoadFromFile(FileName) then
      begin
        ShowErrorMessage('Failed to load LIP file');
        FreeAndNil(FLipFile);
        Exit;
      end;
      
      if not FLipFile.IsValid then
      begin
        ShowErrorMessage('Invalid LIP file format');
        FreeAndNil(FLipFile);
        Exit;
      end;
    end;
    
    // Update display
    edtOutputFile.Text := FileName;
    UpdateLipInfo;
    UpdateControls;
    
    if Assigned(FLipFileV2) then
      ShowInfoMessage(Format('Loaded LIP file: %s (%d phonemes)', [FileName, FLipFileV2.PhonemeCount]))
    else
      ShowInfoMessage(Format('Loaded LIP file: %s (%d frames)', [FileName, FLipFile.FrameCount]));
    
  except
    on E: Exception do
    begin
      ShowErrorMessage(Format('Error loading LIP file: %s', [E.Message]));
      FreeAndNil(FLipFile);
    end;
  end;
end;

procedure TfrmMain.GenerateLipFile;
var
  GenResult: TLipGenResult;
  DebugFile: string;
  Options: TLipGenOptions;
begin
  if FProcessing then
    Exit;

  FProcessing := True;
  FCurrentProgress := 0;

  try
    // Configure generator
    Options := FGenerator.Options;
    Options.FPS := StrToIntDef(Trim(Copy(cmbFPS.Text, 1, Pos(' ', cmbFPS.Text + ' ') - 1)), 12);
    Options.Threshold := StrToFloatDef(edtThreshold.Text, 0.08);
    Options.Normalize := chkNormalize.Checked;
    Options.IncludeExtendedData := chkExtendedData.Checked;
    Options.DebugMode := chkDebug.Checked;
    FGenerator.Options := Options;
    FGenerator.OnProgress := UpdateProgress;

    // Generate
    GenResult := FGenerator.GenerateFromFile(edtInputFile.Text, edtOutputFile.Text);

    if GenResult.Success then
    begin
      ShowInfoMessage(Format('LIP file generated successfully!'#13#10 +
        'Frames: %d'#13#10 +
        'Duration: %.3f seconds'#13#10 +
        'Processing time: %.3f seconds',
        [GenResult.FrameCount, GenResult.Duration, GenResult.ProcessingTime]));

      // Load generated file
      LoadLipFile(edtOutputFile.Text);

      // Export debug info if requested
      if chkDebug.Checked then
      begin
        DebugFile := ChangeFileExt(edtOutputFile.Text, '.debug.txt');
        with TStringList.Create do
        try
          Text := FGenerator.ExportDebugInfo(edtOutputFile.Text);
          SaveToFile(DebugFile);
        finally
          Free;
        end;
        ShowInfoMessage(Format('Debug info saved to: %s', [DebugFile]));
      end;
    end
    else
    begin
      ShowErrorMessage(Format('Generation failed: %s', [GenResult.ErrorMessage]));
    end;

    // Free warnings
    if Assigned(GenResult.Warnings) then
      GenResult.Warnings.Free;

  finally
    FProcessing := False;
    FCurrentProgress := 0;
    UpdateControls;
    ProgressBar1.Position := 0;
    sbMain.SimpleText := 'Ready';
  end;
end;

procedure TfrmMain.AddToBatch(const InputFile, OutputFile: string);
begin
  lbBatchList.Items.Add(Format('%s -> %s', [ExtractFileName(InputFile), ExtractFileName(OutputFile)]));
  lbBatchList.Items.Objects[lbBatchList.Items.Count - 1] := TObject.Create;
  // Store file paths in object (simplified)
  UpdateControls;
end;

procedure TfrmMain.ClearBatch;
begin
  lbBatchList.Clear;
  UpdateControls;
end;

procedure TfrmMain.ShowErrorMessage(const Msg: string);
begin
  MessageDlg(Msg, mtError, [mbOK], 0);
  sbMain.SimpleText := Format('Error: %s', [Msg]);
end;

procedure TfrmMain.ShowInfoMessage(const Msg: string);
begin
  sbMain.SimpleText := Msg;
end;

procedure TfrmMain.UpdateProgress(Progress: Integer; const Status: string);
begin
  FCurrentProgress := Progress;
  ProgressBar1.Position := Progress;
  sbMain.SimpleText := Status;
  Application.ProcessMessages;
end;

procedure TfrmMain.actCompareExecute(Sender: TObject);
var
  CompareDialog: TOpenDialog;
  Comparison: string;
begin
  if not FileExists(edtOutputFile.Text) then
  begin
    ShowErrorMessage('Please generate or load a LIP file first');
    Exit;
  end;
  
  CompareDialog := TOpenDialog.Create(Self);
  try
    CompareDialog.Filter := 'LIP files (*.lip)|*.lip|All files (*.*)|*.*';
    CompareDialog.Title := 'Select LIP file to compare';
    
    if CompareDialog.Execute then
    begin
      Comparison := FGenerator.CompareFiles(edtOutputFile.Text, CompareDialog.FileName);
      ShowMessage(Comparison);
    end;
  finally
    CompareDialog.Free;
  end;
end;

procedure TfrmMain.actExportDebugExecute(Sender: TObject);
var
  SaveDialog: TSaveDialog;
begin
  if not FileExists(edtOutputFile.Text) then
  begin
    ShowErrorMessage('Please generate or load a LIP file first');
    Exit;
  end;
  
  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
    SaveDialog.FileName := ChangeFileExt(ExtractFileName(edtOutputFile.Text), '.debug.txt');
    
    if SaveDialog.Execute then
    begin
      with TStringList.Create do
      try
        Text := FGenerator.ExportDebugInfo(edtOutputFile.Text);
        SaveToFile(SaveDialog.FileName);
        ShowInfoMessage(Format('Debug info saved to: %s', [SaveDialog.FileName]));
      finally
        Free;
      end;
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TfrmMain.actExportJSONExecute(Sender: TObject);
var
  SaveDialog: TSaveDialog;
begin
  if not FileExists(edtOutputFile.Text) then
  begin
    ShowErrorMessage('Please generate or load a LIP file first');
    Exit;
  end;
  
  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';
    SaveDialog.FileName := ChangeFileExt(ExtractFileName(edtOutputFile.Text), '.json');
    
    if SaveDialog.Execute then
    begin
      with TStringList.Create do
      try
        Text := FGenerator.ExportToJSON(edtOutputFile.Text);
        SaveToFile(SaveDialog.FileName);
        ShowInfoMessage(Format('JSON exported to: %s', [SaveDialog.FileName]));
      finally
        Free;
      end;
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TfrmMain.actGenerateExecute(Sender: TObject);
begin
  GenerateLipFile;
end;

procedure TfrmMain.actLoadLipExecute(Sender: TObject);
begin
  OpenDialog1.Filter := 'LIP files (*.lip)|*.lip|All files (*.*)|*.*';
  OpenDialog1.Title := 'Load LIP File';
  
  if OpenDialog1.Execute then
    LoadLipFile(OpenDialog1.FileName);
end;

procedure TfrmMain.actLoadWavExecute(Sender: TObject);
begin
  OpenDialog1.Filter := 'WAV files (*.wav)|*.wav|All files (*.*)|*.*';
  OpenDialog1.Title := 'Load WAV File';
  
  if OpenDialog1.Execute then
    LoadWavFile(OpenDialog1.FileName);
end;

procedure TfrmMain.actNewExecute(Sender: TObject);
begin
  // Clear all
  edtInputFile.Text := '';
  edtOutputFile.Text := '';
  
  if Assigned(FAudioBuffer) then
    FreeAndNil(FAudioBuffer);
  
  if Assigned(FWavReader) then
    FreeAndNil(FWavReader);
  
  if Assigned(FLipFile) then
    FreeAndNil(FLipFile);
  
  if Assigned(FLipFileV2) then
    FreeAndNil(FLipFileV2);
  
  SetLength(FWaveformData, 0);
  
  UpdateAudioInfo;
  UpdateLipInfo;
  UpdateWaveform;
  UpdateControls;
  
  sbMain.SimpleText := 'Ready';
end;

procedure TfrmMain.actOpenExecute(Sender: TObject);
begin
  // Not implemented
end;

procedure TfrmMain.actQuitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.actSaveAsExecute(Sender: TObject);
begin
  // Not implemented
end;

procedure TfrmMain.actSaveExecute(Sender: TObject);
begin
  // Not implemented
end;

procedure TfrmMain.actValidateExecute(Sender: TObject);
begin
  if not FileExists(edtOutputFile.Text) then
  begin
    ShowErrorMessage('Please generate or load a LIP file first');
    Exit;
  end;
  
  if FGenerator.ValidateLipFile(edtOutputFile.Text) then
    ShowInfoMessage('LIP file validation: PASSED')
  else
    ShowErrorMessage('LIP file validation: FAILED');
end;

procedure TfrmMain.btnAddToBatchClick(Sender: TObject);
begin
  if (edtInputFile.Text <> '') and (edtOutputFile.Text <> '') then
  begin
    AddToBatch(edtInputFile.Text, edtOutputFile.Text);
    ShowInfoMessage(Format('Added to batch: %s', [ExtractFileName(edtInputFile.Text)]));
  end;
end;

procedure TfrmMain.btnClearBatchClick(Sender: TObject);
begin
  ClearBatch;
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
begin
  GenerateLipFile;
end;

procedure TfrmMain.btnRemoveFromBatchClick(Sender: TObject);
begin
  if lbBatchList.ItemIndex >= 0 then
  begin
    lbBatchList.Items.Delete(lbBatchList.ItemIndex);
    UpdateControls;
  end;
end;

procedure TfrmMain.cmbFPSChange(Sender: TObject);
begin
  UpdateControls;
end;

procedure TfrmMain.edtThresholdChange(Sender: TObject);
begin
  UpdateThresholdLabel;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Set form title
  Caption := 'Fallout Lip Generator';
  lblTitle.Caption := 'Fallout Lip Generator';
  lblVersion.Caption := 'Version 1.0';
  
  // Initialize
  UpdateControls;
  UpdateThresholdLabel;
  
  sbMain.SimpleText := 'Ready';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Cleanup handled in destructor
end;

procedure TfrmMain.pbWaveformPaint(Sender: TObject);
var
  I, X, Y, CenterY, Height: Integer;
  Scale: Double;
begin
  with pbWaveform.Canvas do
  begin
    // Clear background
    Brush.Color := clWhite;
    FillRect(pbWaveform.ClientRect);
    
    // Draw grid
    Pen.Color := clSilver;
    Pen.Style := psDot;
    CenterY := pbWaveform.Height div 2;
    
    // Horizontal center line
    MoveTo(0, CenterY);
    LineTo(pbWaveform.Width, CenterY);
    
    // Vertical lines
    for I := 0 to 10 do
    begin
      X := (I * pbWaveform.Width) div 10;
      MoveTo(X, 0);
      LineTo(X, pbWaveform.Height);
    end;
    
    // Draw waveform if available
    if Length(FWaveformData) > 0 then
    begin
      Pen.Color := clBlue;
      Pen.Style := psSolid;
      Pen.Width := 1;
      
      CenterY := pbWaveform.Height div 2;
      Height := pbWaveform.Height div 2 - 10;
      
      // Calculate scaling
      Scale := Height / 1.0; // Normalized to 1.0
      
      MoveTo(0, CenterY);
      
      for I := 0 to High(FWaveformData) do
      begin
        X := (I * pbWaveform.Width) div High(FWaveformData);
        Y := CenterY - Round(FWaveformData[I] * Scale);
        
        // Clamp to visible area
        if Y < 0 then Y := 0;
        if Y >= pbWaveform.Height then Y := pbWaveform.Height - 1;
        
        if I = 0 then
          MoveTo(X, Y)
        else
          LineTo(X, Y);
      end;
    end;
    
    // Draw border
    Pen.Color := clBlack;
    Pen.Style := psSolid;
    Pen.Width := 1;
    Rectangle(0, 0, pbWaveform.Width, pbWaveform.Height);
  end;
end;

procedure TfrmMain.tmrProgressTimer(Sender: TObject);
begin
  // Progress timer - can be used for animation
end;

end.
