object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Fallout Lip Generator'
  ClientHeight = 871
  ClientWidth = 960
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 15
  object lblTitle: TLabel
    Left = 16
    Top = 16
    Width = 152
    Height = 21
    Caption = 'Fallout Lip Generator'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblVersion: TLabel
    Left = 16
    Top = 40
    Width = 56
    Height = 15
    Caption = 'Version 1.0'
  end
  object lblInputFile: TLabel
    Left = 16
    Top = 76
    Width = 56
    Height = 15
    Caption = 'Input WAV'
  end
  object lblOutputFile: TLabel
    Left = 16
    Top = 108
    Width = 57
    Height = 15
    Caption = 'Output LIP'
  end
  object lblFPS: TLabel
    Left = 16
    Top = 140
    Width = 19
    Height = 15
    Caption = 'FPS'
  end
  object lblThreshold: TLabel
    Left = 200
    Top = 140
    Width = 53
    Height = 15
    Caption = 'Threshold'
  end
  object lblThresholdVal: TLabel
    Left = 640
    Top = 140
    Width = 69
    Height = 15
    Caption = 'Threshold: --'
  end
  object pbLipSync: TPaintBox
    Left = 489
    Top = 627
    Width = 433
    Height = 196
    OnMouseDown = pbLipSyncMouseDown
    OnPaint = pbLipSyncPaint
  end
  object edtInputFile: TEdit
    Left = 88
    Top = 72
    Width = 560
    Height = 23
    TabOrder = 0
  end
  object edtOutputFile: TEdit
    Left = 88
    Top = 104
    Width = 560
    Height = 23
    TabOrder = 1
  end
  object cmbFPS: TComboBox
    Left = 88
    Top = 136
    Width = 89
    Height = 23
    Style = csDropDownList
    TabOrder = 2
    OnChange = cmbFPSChange
  end
  object edtThreshold: TEdit
    Left = 272
    Top = 136
    Width = 89
    Height = 23
    TabOrder = 3
    OnChange = edtThresholdChange
  end
  object chkNormalize: TCheckBox
    Left = 384
    Top = 138
    Width = 89
    Height = 17
    Caption = 'Normalize'
    Checked = True
    State = cbChecked
    TabOrder = 4
  end
  object chkExtendedData: TCheckBox
    Left = 480
    Top = 138
    Width = 113
    Height = 17
    Caption = 'Extended Data'
    TabOrder = 5
  end
  object chkDebug: TCheckBox
    Left = 600
    Top = 138
    Width = 65
    Height = 17
    Caption = 'Debug'
    TabOrder = 6
  end
  object gbAudioInfo: TGroupBox
    Left = 16
    Top = 176
    Width = 280
    Height = 136
    Caption = 'Audio Info'
    TabOrder = 7
    object lblAudioFile: TLabel
      Left = 12
      Top = 24
      Width = 74
      Height = 15
      Caption = 'No file loaded'
    end
    object lblAudioDuration: TLabel
      Left = 12
      Top = 52
      Width = 46
      Height = 15
      Caption = 'Duration'
    end
    object lblAudioDurationVal: TLabel
      Left = 120
      Top = 52
      Width = 10
      Height = 15
      Caption = '--'
    end
    object lblAudioSampleRate: TLabel
      Left = 12
      Top = 72
      Width = 65
      Height = 15
      Caption = 'Sample Rate'
    end
    object lblAudioSampleRateVal: TLabel
      Left = 120
      Top = 72
      Width = 10
      Height = 15
      Caption = '--'
    end
    object lblBitsPerSample: TLabel
      Left = 12
      Top = 92
      Width = 81
      Height = 15
      Caption = 'Bits Per Sample'
    end
    object lblBitsPerSampleVal: TLabel
      Left = 120
      Top = 92
      Width = 10
      Height = 15
      Caption = '--'
    end
    object lblChannels: TLabel
      Left = 12
      Top = 112
      Width = 49
      Height = 15
      Caption = 'Channels'
    end
    object lblChannelsVal: TLabel
      Left = 120
      Top = 112
      Width = 10
      Height = 15
      Caption = '--'
    end
  end
  object gbLipInfo: TGroupBox
    Left = 16
    Top = 321
    Width = 280
    Height = 121
    Caption = 'LIP Info'
    TabOrder = 8
    object lblLipFile: TLabel
      Left = 12
      Top = 24
      Width = 74
      Height = 15
      Caption = 'No file loaded'
    end
    object lblLipDuration: TLabel
      Left = 12
      Top = 52
      Width = 46
      Height = 15
      Caption = 'Duration'
    end
    object lblLipDurationVal: TLabel
      Left = 120
      Top = 52
      Width = 10
      Height = 15
      Caption = '--'
    end
    object lblLipFrameCount: TLabel
      Left = 12
      Top = 72
      Width = 69
      Height = 15
      Caption = 'Frame Count'
    end
    object lblLipFrameCountVal: TLabel
      Left = 120
      Top = 72
      Width = 10
      Height = 15
      Caption = '--'
    end
    object lblLipFPS: TLabel
      Left = 12
      Top = 92
      Width = 19
      Height = 15
      Caption = 'FPS'
    end
    object lblLipFPSVal: TLabel
      Left = 120
      Top = 92
      Width = 10
      Height = 15
      Caption = '--'
    end
  end
  object gbBatch: TGroupBox
    Left = 312
    Top = 321
    Width = 280
    Height = 128
    Caption = 'Batch Queue'
    TabOrder = 9
    object lbBatchList: TListBox
      Left = 12
      Top = 24
      Width = 256
      Height = 93
      ItemHeight = 15
      TabOrder = 0
    end
  end
  object gbWaveform: TGroupBox
    Left = 302
    Top = 182
    Width = 632
    Height = 308
    Caption = 'Waveform'
    TabOrder = 10
    object pbWaveform: TPaintBox
      Left = 12
      Top = 24
      Width = 608
      Height = 272
      OnPaint = pbWaveformPaint
    end
  end
  object gbGeneration: TGroupBox
    Left = 16
    Top = 451
    Width = 280
    Height = 128
    Caption = 'Generation Options'
    TabOrder = 11
    object lblDialogText: TLabel
      Left = 12
      Top = 24
      Width = 61
      Height = 15
      Caption = 'Dialog Text:'
    end
    object memDialogText: TMemo
      Left = 12
      Top = 40
      Width = 256
      Height = 73
      Lines.Strings = (
        '')
      TabOrder = 0
      OnChange = memDialogTextChange
    end
  end
  object btnGenerate: TButton
    Left = 674
    Top = 34
    Width = 120
    Height = 25
    Caption = 'Generate'
    TabOrder = 12
    OnClick = btnGenerateClick
  end
  object btnAddToBatch: TButton
    Left = 802
    Top = 34
    Width = 120
    Height = 25
    Caption = 'Add To Batch'
    TabOrder = 13
    OnClick = btnAddToBatchClick
  end
  object btnClearBatch: TButton
    Left = 674
    Top = 66
    Width = 120
    Height = 25
    Caption = 'Clear Batch'
    TabOrder = 14
    OnClick = btnClearBatchClick
  end
  object btnRemoveFromBatch: TButton
    Left = 802
    Top = 66
    Width = 120
    Height = 25
    Caption = 'Remove Selected'
    TabOrder = 15
    OnClick = btnRemoveFromBatchClick
  end
  object btnLoadWavUI: TButton
    Left = 674
    Top = 102
    Width = 120
    Height = 25
    Action = actLoadWav
    TabOrder = 16
  end
  object btnLoadLipUI: TButton
    Left = 802
    Top = 102
    Width = 120
    Height = 25
    Action = actLoadLip
    TabOrder = 17
  end
  object btnValidateUI: TButton
    Left = 674
    Top = 134
    Width = 120
    Height = 25
    Action = actValidate
    TabOrder = 18
  end
  object btnCompareUI: TButton
    Left = 802
    Top = 134
    Width = 120
    Height = 25
    Action = actCompare
    TabOrder = 19
  end
  object ProgressBar1: TProgressBar
    Left = 24
    Top = 585
    Width = 928
    Height = 17
    TabOrder = 20
  end
  object sbMain: TStatusBar
    Left = 0
    Top = 852
    Width = 960
    Height = 19
    Panels = <>
    SimplePanel = True
    ExplicitTop = 941
  end
  object ActionList1: TActionList
    Left = 888
    Top = 16
    object actGenerate: TAction
      Caption = 'Generate'
      OnExecute = actGenerateExecute
    end
    object actLoadWav: TAction
      Caption = 'Load WAV...'
      OnExecute = actLoadWavExecute
    end
    object actLoadLip: TAction
      Caption = 'Load LIP...'
      OnExecute = actLoadLipExecute
    end
    object actValidate: TAction
      Caption = 'Validate'
      OnExecute = actValidateExecute
    end
    object actCompare: TAction
      Caption = 'Compare'
      OnExecute = actCompareExecute
    end
    object actExportJSON: TAction
      Caption = 'Export JSON'
      OnExecute = actExportJSONExecute
    end
    object actExportDebug: TAction
      Caption = 'Export Debug'
      OnExecute = actExportDebugExecute
    end
    object actNew: TAction
      Caption = 'New'
      OnExecute = actNewExecute
    end
    object actQuit: TAction
      Caption = 'Quit'
      OnExecute = actQuitExecute
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 568
    Top = 16
  end
  object SaveDialog1: TSaveDialog
    Left = 568
    Top = 64
  end
  object tmrProgress: TTimer
    Enabled = False
    Interval = 100
    OnTimer = tmrProgressTimer
    Left = 568
    Top = 112
  end
end
