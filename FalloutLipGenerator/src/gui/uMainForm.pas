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
  uWavReader, uAudioBuffer, uSignalAnalysis, uFalloutLipFormat, uFalloutLipFormatV2, System.Actions;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    // Labels
    lblTitle: TLabel;
    lblVersion: TLabel;
    lblInputFile: TLabel;
    lblOutputFile: TLabel;
    lblFPS: TLabel;
    lblThreshold: TLabel;
    lblThresholdVal: TLabel;
    // Input controls
    edtInputFile: TEdit;
    edtOutputFile: TEdit;
    cmbFPS: TComboBox;
    edtThreshold: TEdit;
    chkNormalize: TCheckBox;
    chkExtendedData: TCheckBox;
    chkDebug: TCheckBox;
    // Group boxes and their children
    gbAudioInfo: TGroupBox;
    lblAudioFile: TLabel;
    lblAudioDuration: TLabel;
    lblAudioDurationVal: TLabel;
    lblAudioSampleRate: TLabel;
    lblAudioSampleRateVal: TLabel;
    lblBitsPerSample: TLabel;
    lblBitsPerSampleVal: TLabel;
    lblChannels: TLabel;
    lblChannelsVal: TLabel;
    gbLipInfo: TGroupBox;
    lblLipFile: TLabel;
    lblLipDuration: TLabel;
    lblLipDurationVal: TLabel;
    lblLipFrameCount: TLabel;
    lblLipFrameCountVal: TLabel;
    lblLipFPS: TLabel;
    lblLipFPSVal: TLabel;
    gbBatch: TGroupBox;
    lbBatchList: TListBox;
    gbWaveform: TGroupBox;
    pbWaveform: TPaintBox;
        gbGeneration: TGroupBox;
    // Buttons
    btnGenerate: TButton;
    btnAddToBatch: TButton;
    btnClearBatch: TButton;
    btnRemoveFromBatch: TButton;
    btnLoadWavUI: TButton;
    btnLoadLipUI: TButton;
    btnValidateUI: TButton;
    btnCompareUI: TButton;
  // Progress / status
  ProgressBar1: TProgressBar;
  sbMain: TStatusBar;
  // Actions
  ActionList1: TActionList;
  actGenerate: TAction;
  actLoadWav: TAction;
  actLoadLip: TAction;
  actValidate: TAction;
  actCompare: TAction;
  actExportJSON: TAction;
  actExportDebug: TAction;
  actNew: TAction;
  actQuit: TAction;
  // Dialogs + timer + lip sync paintbox + dialog text memo
  OpenDialog1: TOpenDialog;
  SaveDialog1: TSaveDialog;
  tmrProgress: TTimer;
  pbLipSync: TPaintBox;
  memDialogText: TMemo;
    // Event handlers
    procedure actCompareExecute(Sender: TObject);
    procedure actExportDebugExecute(Sender: TObject);
    procedure actExportJSONExecute(Sender: TObject);
    procedure actGenerateExecute(Sender: TObject);
    procedure actLoadLipExecute(Sender: TObject);
    procedure actLoadWavExecute(Sender: TObject);
    procedure actNewExecute(Sender: TObject);
    procedure actQuitExecute(Sender: TObject);
    procedure actValidateExecute(Sender: TObject);
    procedure btnAddToBatchClick(Sender: TObject);
    procedure btnClearBatchClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnRemoveFromBatchClick(Sender: TObject);
    procedure cmbFPSChange(Sender: TObject);
    procedure edtThresholdChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pbWaveformPaint(Sender: TObject);
    procedure pbLipSyncPaint(Sender: TObject);
    procedure pbLipSyncMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure tmrProgressTimer(Sender: TObject);
    procedure memDialogTextChange(Sender: TObject);
  private
    FGenerator: TLipGenerator;
    FWavReader: TWavReader;
    FAudioBuffer: TAudioBuffer;
    FLipFile: TFalloutLipFile;
    FLipFileV2: TFalloutLipFileV2;
    FWaveformData: array of Double;
    FLipFrames: TLipFrameArray;
    FProcessing: Boolean;
    FCurrentProgress: Integer;
    
    procedure UpdateControls;
    procedure UpdateAudioInfo;
    procedure UpdateLipInfo;
    procedure UpdateWaveform;
    procedure UpdateLipSync;
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
  FLipFrames := nil;
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

  FLipFrames := nil;
  
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
  // Defensive checks for components that might not be fully initialized
  // This helps prevent Access Violations if the DFM is incomplete or mismatched.

  // Actions
  if Assigned(ActionList1) then
  begin
    if Assigned(actGenerate) and Assigned(edtInputFile) and Assigned(edtOutputFile) then
      actGenerate.Enabled := (edtInputFile.Text <> '') and (edtOutputFile.Text <> '') and not FProcessing
    else if Assigned(actGenerate) then
      actGenerate.Enabled := False;

    if Assigned(actLoadWav) then
      actLoadWav.Enabled := not FProcessing;

    if Assigned(actLoadLip) then
      actLoadLip.Enabled := not FProcessing;

    if Assigned(actValidate) and Assigned(edtOutputFile) then
      actValidate.Enabled := (edtOutputFile.Text <> '') and FileExists(edtOutputFile.Text)
    else if Assigned(actValidate) then
      actValidate.Enabled := False;

    if Assigned(actCompare) and Assigned(edtOutputFile) then
      actCompare.Enabled := (edtOutputFile.Text <> '') and FileExists(edtOutputFile.Text)
    else if Assigned(actCompare) then
      actCompare.Enabled := False;

    if Assigned(actExportJSON) and Assigned(edtOutputFile) then
      actExportJSON.Enabled := (edtOutputFile.Text <> '') and FileExists(edtOutputFile.Text)
    else if Assigned(actExportJSON) then
      actExportJSON.Enabled := False;

    if Assigned(actExportDebug) and Assigned(edtOutputFile) then
      actExportDebug.Enabled := (edtOutputFile.Text <> '') and FileExists(edtOutputFile.Text)
    else if Assigned(actExportDebug) then
      actExportDebug.Enabled := False;
  end; // End of ActionList1 check

  // Buttons
  if Assigned(btnGenerate) and Assigned(actGenerate) then
    btnGenerate.Enabled := actGenerate.Enabled
  else if Assigned(btnGenerate) then
    btnGenerate.Enabled := False;

  if Assigned(btnAddToBatch) and Assigned(edtInputFile) and Assigned(edtOutputFile) then
    btnAddToBatch.Enabled := (edtInputFile.Text <> '') and (edtOutputFile.Text <> '') and not FProcessing
  else if Assigned(btnAddToBatch) then
    btnAddToBatch.Enabled := False;

  if Assigned(btnClearBatch) and Assigned(lbBatchList) then
    btnClearBatch.Enabled := (lbBatchList.Items.Count > 0) and not FProcessing
  else if Assigned(btnClearBatch) then
    btnClearBatch.Enabled := False;

  if Assigned(btnRemoveFromBatch) and Assigned(lbBatchList) then
    btnRemoveFromBatch.Enabled := (lbBatchList.ItemIndex >= 0) and not FProcessing
  else if Assigned(btnRemoveFromBatch) then
    btnRemoveFromBatch.Enabled := False;

  // Other controls
  if Assigned(cmbFPS) then
    cmbFPS.Enabled := not FProcessing;

  if Assigned(edtThreshold) then
    edtThreshold.Enabled := not FProcessing;

  if Assigned(chkNormalize) then
    chkNormalize.Enabled := not FProcessing;

  if Assigned(chkExtendedData) then
    chkExtendedData.Enabled := not FProcessing;

if Assigned(chkDebug) then
     chkDebug.Enabled := not FProcessing;

   if Assigned(memDialogText) then
     memDialogText.Enabled := not FProcessing;

  // Update progress bar and status bar
  if Assigned(ProgressBar1) then
    ProgressBar1.Enabled := FProcessing;

  if Assigned(sbMain) then
    sbMain.Enabled := True; // Always enabled, but content changes

  // Paint boxes
  if Assigned(pbWaveform) then
    pbWaveform.Enabled := True;
  if Assigned(pbLipSync) then
    pbLipSync.Enabled := True;
end;

procedure TfrmMain.UpdateAudioInfo;
begin
  if Assigned(FWavReader) and FWavReader.IsValid then
  begin
    if Assigned(lblAudioFile) and Assigned(edtInputFile) then lblAudioFile.Caption := ExtractFileName(edtInputFile.Text);
    if Assigned(lblAudioDurationVal) then lblAudioDurationVal.Caption := Format('%.3f seconds', [FWavReader.Duration]);
    if Assigned(lblAudioSampleRateVal) then lblAudioSampleRateVal.Caption := Format('%d Hz', [FWavReader.SampleRate]);
    if Assigned(lblBitsPerSampleVal) then lblBitsPerSampleVal.Caption := Format('%d bits', [FWavReader.BitsPerSample]);
    if Assigned(lblChannelsVal) then lblChannelsVal.Caption := Format('%d channel(s)', [FWavReader.Channels]);
  end
  else
  begin
    if Assigned(lblAudioFile) then lblAudioFile.Caption := 'No file loaded';
    if Assigned(lblAudioDurationVal) then lblAudioDurationVal.Caption := '--';
    if Assigned(lblAudioSampleRateVal) then lblAudioSampleRateVal.Caption := '--';
    if Assigned(lblBitsPerSampleVal) then lblBitsPerSampleVal.Caption := '--';
    if Assigned(lblChannelsVal) then lblChannelsVal.Caption := '--';
  end;
end;

procedure TfrmMain.UpdateLipInfo;
begin
  if Assigned(FLipFileV2) and FLipFileV2.IsValid then
  begin
    if Assigned(lblLipFile) and Assigned(edtOutputFile) then lblLipFile.Caption := ExtractFileName(edtOutputFile.Text);
    if Assigned(lblLipDurationVal) then lblLipDurationVal.Caption := Format('%.3f seconds', [FLipFileV2.GetDuration]);
    if Assigned(lblLipFrameCountVal) then lblLipFrameCountVal.Caption := Format('%d phonemes', [FLipFileV2.PhonemeCount]);
    if Assigned(lblLipFPSVal) then lblLipFPSVal.Caption := 'V2';
  end
  else if Assigned(FLipFile) and FLipFile.IsValid then
  begin
    if Assigned(lblLipFile) and Assigned(edtOutputFile) then lblLipFile.Caption := ExtractFileName(edtOutputFile.Text);
    if Assigned(lblLipDurationVal) then lblLipDurationVal.Caption := Format('%.3f seconds', [FLipFile.Duration]);
    if Assigned(lblLipFrameCountVal) then lblLipFrameCountVal.Caption := Format('%d frames', [FLipFile.FrameCount]);
    if Assigned(lblLipFPSVal) then lblLipFPSVal.Caption := Format('%d FPS', [FLipFile.Header.FPS]);
  end
  else
  begin
    if Assigned(lblLipFile) then lblLipFile.Caption := 'No file loaded';
    if Assigned(lblLipDurationVal) then lblLipDurationVal.Caption := '--';
    if Assigned(lblLipFrameCountVal) then lblLipFrameCountVal.Caption := '--';
    if Assigned(lblLipFPSVal) then lblLipFPSVal.Caption := '--';
  end;
end;

procedure TfrmMain.UpdateWaveform;
begin
  pbWaveform.Invalidate;
end;

procedure TfrmMain.UpdateLipSync;
begin
  pbLipSync.Invalidate;
end;

procedure TfrmMain.UpdateThresholdLabel;
begin
  if Assigned(lblThresholdVal) and Assigned(edtThreshold) then
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
    if Assigned(edtInputFile) then edtInputFile.Text := FileName;
    if Assigned(edtOutputFile) then edtOutputFile.Text := ChangeFileExt(FileName, '.lip');
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
    
    // Extract lip frames for visualization
    FLipFrames := nil;
    if Assigned(FLipFileV2) then
      FLipFrames := FLipFileV2.ToLipFrames
    else if Assigned(FLipFile) then
      FLipFrames := FLipFile.ToLipFrames;

    // Update display (ensure edtOutputFile is assigned)
    if Assigned(edtOutputFile) then edtOutputFile.Text := FileName;
    UpdateLipInfo;
    UpdateLipSync;
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
    if Assigned(cmbFPS) then Options.FPS := StrToIntDef(Trim(Copy(cmbFPS.Text, 1, Pos(' ', cmbFPS.Text + ' ') - 1)), 12);
    if Assigned(edtThreshold) then Options.Threshold := StrToFloatDef(edtThreshold.Text, 0.08);
    if Assigned(chkNormalize) then Options.Normalize := chkNormalize.Checked;
    if Assigned(chkExtendedData) then Options.IncludeExtendedData := chkExtendedData.Checked;
    if Assigned(chkDebug) then Options.DebugMode := chkDebug.Checked;
    FGenerator.Options := Options;
    FGenerator.OnProgress := UpdateProgress;

    // Generate
    if Trim(memDialogText.Text) <> '' then
      GenResult := FGenerator.GenerateFromFileWithText(edtInputFile.Text, edtOutputFile.Text, memDialogText.Text)
    else
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
        if Assigned(edtOutputFile) then DebugFile := ChangeFileExt(edtOutputFile.Text, '.debug.txt');
        with TStringList.Create do
        try
          if Assigned(edtOutputFile) then Text := FGenerator.ExportDebugInfo(edtOutputFile.Text);
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
    UpdateControls; // Ensure controls are updated after processing
    if Assigned(ProgressBar1) then ProgressBar1.Position := 0;
    if Assigned(sbMain) then sbMain.SimpleText := 'Ready';
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
  MessageDlg(Msg, mtError, [mbOK], 0); // Ensure MessageDlg is properly called
  if Assigned(sbMain) then sbMain.SimpleText := Format('Error: %s', [Msg]);
end;

procedure TfrmMain.ShowInfoMessage(const Msg: string);
begin
  if Assigned(sbMain) then sbMain.SimpleText := Msg;
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
      if Assigned(edtOutputFile) then Comparison := FGenerator.CompareFiles(edtOutputFile.Text, CompareDialog.FileName);
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

procedure TfrmMain.actQuitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  // Initial UI refresh after the form is fully shown
  UpdateControls;
  UpdateAudioInfo;
  UpdateLipInfo;
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
    if Assigned(edtInputFile) and Assigned(edtOutputFile) then AddToBatch(edtInputFile.Text, edtOutputFile.Text);
    if Assigned(edtInputFile) then ShowInfoMessage(Format('Added to batch: %s', [ExtractFileName(edtInputFile.Text)]));
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
  if Assigned(lbBatchList) and (lbBatchList.ItemIndex >= 0) then
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
  I, X, Y, CenterY, DrawingHeight: Integer;
  Scale: Double;
begin
  if Assigned(pbWaveform) then with pbWaveform.Canvas do
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
      DrawingHeight := pbWaveform.Height div 2 - 10;

      // Calculate scaling
      Scale := DrawingHeight / 1.0; // Normalized to 1.0

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

procedure TfrmMain.pbLipSyncPaint(Sender: TObject);
var
  I, X, Y, BarHeight: Integer;
  TimeScale, Duration: Double;
  FrameTime: Double;
  LColor: TColor;
begin
  if not Assigned(pbLipSync) then Exit;

  with pbLipSync.Canvas do
  begin
    // Clear background
    Brush.Color := clWhite;
    FillRect(pbLipSync.ClientRect);
    
    // Draw legend
    Font.Size := 8;
    TextOut(10, 5, 'Gray=Closed, Green=Small, Yellow=Medium, Red=Wide (Click to edit)');
    
    // Draw grid
    Pen.Color := clSilver;
    Pen.Style := psDot;
    
    // Horizontal lines
    for I := 0 to 4 do
    begin
      Y := (I * pbLipSync.Height) div 4;
      MoveTo(0, Y);
      LineTo(pbLipSync.Width, Y);
    end;
    
    // Vertical lines
    for I := 0 to 10 do
    begin
      X := (I * pbLipSync.Width) div 10;
      MoveTo(X, 0);
      LineTo(X, pbLipSync.Height);
    end;
    
    // Draw lip sync frames if available
    if Length(FLipFrames) > 0 then
    begin
      // Calculate time scale
      Duration := 0.0;
      if Assigned(FWavReader) and FWavReader.IsValid then
        Duration := FWavReader.Duration
      else if Length(FLipFrames) > 0 then
        Duration := FLipFrames[High(FLipFrames)].Time + FLipFrames[High(FLipFrames)].Duration;
      
      if Duration > 0 then
        TimeScale := pbLipSync.Width / Duration
      else
        TimeScale := 1.0;
      
      BarHeight := pbLipSync.Height - 25; // Leave space for legend
      
      for I := 0 to High(FLipFrames) do
      begin
        // Determine color based on mouth state
        case FLipFrames[I].MouthState of
          msClosed: LColor := clGray;
          msSmallOpen: LColor := clLime;
          msMediumOpen: LColor := clYellow;
          msWideOpen: LColor := clRed;
        else
          LColor := clBlack;
        end;
        
        // Draw frame bar
        Brush.Color := LColor;
        Pen.Color := LColor;
        Pen.Style := psSolid;
        
        FrameTime := FLipFrames[I].Time;
        X := Round(FrameTime * TimeScale);
        Y := 20; // Below legend
        
        // Draw a vertical bar for each frame
        Rectangle(X, Y, X + Max(1, Round(FLipFrames[I].Duration * TimeScale)), Y + BarHeight);
      end;
    end;
    
    // Draw border
    Pen.Color := clBlack;
    Pen.Style := psSolid;
    Pen.Width := 1;
    Rectangle(0, 0, pbLipSync.Width, pbLipSync.Height);
  end;
end;

procedure TfrmMain.pbLipSyncMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Duration: Double;
  TimeScale: Double;
  ClickTime: Double;
  I: Integer;
  NewState: TMouthState;
begin
  if Length(FLipFrames) = 0 then
    Exit;
  
  // Calculate time scale
  Duration := 0.0;
  if Assigned(FWavReader) and FWavReader.IsValid then
    Duration := FWavReader.Duration
  else if Length(FLipFrames) > 0 then
    Duration := FLipFrames[High(FLipFrames)].Time + FLipFrames[High(FLipFrames)].Duration;
  
  if Duration <= 0 then
    Exit;
  
  TimeScale := pbLipSync.Width / Duration;
  ClickTime := X / TimeScale;
  
  // Find the frame at this time
  for I := 0 to High(FLipFrames) do
  begin
    if (ClickTime >= FLipFrames[I].Time) and (ClickTime < FLipFrames[I].Time + FLipFrames[I].Duration) then
    begin
      // Cycle through mouth states
      case FLipFrames[I].MouthState of
        msClosed: NewState := msSmallOpen;
        msSmallOpen: NewState := msMediumOpen;
        msMediumOpen: NewState := msWideOpen;
        msWideOpen: NewState := msClosed;
      end;
      
      FLipFrames[I].MouthState := NewState;
      UpdateLipSync;
      Break;
    end;
  end;
end;

procedure TfrmMain.tmrProgressTimer(Sender: TObject);
begin
  // Progress timer - can be used for animation
end;

procedure TfrmMain.memDialogTextChange(Sender: TObject);
begin
  // Intentionally left empty - dialog text is only used during generation
end;

end.
