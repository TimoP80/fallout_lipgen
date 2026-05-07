object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Fallout Lip Generator'
  ClientHeight = 640
  ClientWidth = 960
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object lblTitle: TLabel
    Left = 16
    Top = 16
    Width = 170
    Height = 21
    Caption = 'Fallout Lip Generator'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblVersion: TLabel
    Left = 16
    Top = 42
    Width = 65
    Height = 15
    Caption = 'Version 1.0'
  end
  object lblInputFile: TLabel
    Left = 16
    Top = 76
    Width = 54
    Height = 15
    Caption = 'Input WAV'
  end
  object lblOutputFile: TLabel
    Left = 16
    Top = 108
    Width = 56
    Height = 15
    Caption = 'Output LIP'
  end
  object lblFPS: TLabel
    Left = 16
    Top = 140
    Width = 20
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
    Width = 77
    Height = 15
    Caption = 'Threshold: --'
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
      Width = 85
      Height = 15
      Caption = 'No file loaded'
    end
    object lblAudioDuration: TLabel
      Left = 12
      Top = 52
      Width = 49
      Height = 15
      Caption = 'Duration'
    end
    object lblAudioDurationVal: TLabel
      Left = 120
      Top = 52
      Width = 12
      Height = 15
      Caption = '--'
    end
    object lblAudioSampleRate: TLabel
      Left = 12
      Top = 72
      Width = 68
      Height = 15
      Caption = 'Sample Rate'
    end
    object lblAudioSampleRateVal: TLabel
      Left = 120
      Top = 72
      Width = 12
      Height = 15
      Caption = '--'
    end
    object lblBitsPerSample: TLabel
      Left = 12
      Top = 92
      Width = 83
      Height = 15
      Caption = 'Bits Per Sample'
    end
    object lblBitsPerSampleVal: TLabel
      Left = 120
      Top = 92
      Width = 12
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
      Width = 12
      Height = 15
      Caption = '--'
    end
  end
  object gbLipInfo: TGroupBox
    Left = 16
    Top = 320
    Width = 280
    Height = 112
    Caption = 'LIP Info'
    TabOrder = 8
    object lblLipFile: TLabel
      Left = 12
      Top = 24
      Width = 85
      Height = 15
      Caption = 'No file loaded'
    end
    object lblLipDuration: TLabel
      Left = 12
      Top = 52
      Width = 49
      Height = 15
      Caption = 'Duration'
    end
    object lblLipDurationVal: TLabel
      Left = 120
      Top = 52
      Width = 12
      Height = 15
      Caption = '--'
    end
    object lblLipFrameCount: TLabel
      Left = 12
      Top = 72
      Width = 67
      Height = 15
      Caption = 'Frame Count'
    end
    object lblLipFrameCountVal: TLabel
      Left = 120
      Top = 72
      Width = 12
      Height = 15
      Caption = '--'
    end
    object lblLipFPS: TLabel
      Left = 12
      Top = 92
      Width = 20
      Height = 15
      Caption = 'FPS'
    end
    object lblLipFPSVal: TLabel
      Left = 120
      Top = 92
      Width = 12
      Height = 15
      Caption = '--'
    end
  end
  object gbBatch: TGroupBox
    Left = 16
    Top = 440
    Width = 280
    Height = 144
    Caption = 'Batch Queue'
    TabOrder = 9
    object lbBatchList: TListBox
      Left = 12
      Top = 24
      Width = 256
      Height = 109
      ItemHeight = 15
      TabOrder = 0
    end
  end
  object gbWaveform: TGroupBox
    Left = 312
    Top = 176
    Width = 632
    Height = 408
    Caption = 'Waveform'
    TabOrder = 10
    object pbWaveform: TPaintBox
      Left = 12
      Top = 24
      Width = 608
      Height = 372
      OnPaint = pbWaveformPaint
    end
  end
  object btnGenerate: TButton
    Left = 672
    Top = 72
    Width = 120
    Height = 25
    Caption = 'Generate'
    TabOrder = 11
    OnClick = btnGenerateClick
  end
  object btnAddToBatch: TButton
    Left = 800
    Top = 72
    Width = 120
    Height = 25
    Caption = 'Add To Batch'
    TabOrder = 12
    OnClick = btnAddToBatchClick
  end
  object btnClearBatch: TButton
    Left = 672
    Top = 104
    Width = 120
    Height = 25
    Caption = 'Clear Batch'
    TabOrder = 13
    OnClick = btnClearBatchClick
  end
  object btnRemoveFromBatch: TButton
    Left = 800
    Top = 104
    Width = 120
    Height = 25
    Caption = 'Remove Selected'
    TabOrder = 14
    OnClick = btnRemoveFromBatchClick
  end
  object btnLoadWavUI: TButton
    Left = 672
    Top = 136
    Width = 120
    Height = 25
    Action = actLoadWav
    TabOrder = 15
  end
  object btnLoadLipUI: TButton
    Left = 800
    Top = 136
    Width = 120
    Height = 25
    Action = actLoadLip
    TabOrder = 16
  end
  object btnValidateUI: TButton
    Left = 672
    Top = 592
    Width = 120
    Height = 25
    Action = actValidate
    TabOrder = 17
  end
  object btnCompareUI: TButton
    Left = 800
    Top = 592
    Width = 120
    Height = 25
    Action = actCompare
    TabOrder = 18
  end
  object ProgressBar1: TProgressBar
    Left = 16
    Top = 592
    Width = 640
    Height = 17
    TabOrder = 19
  end
  object sbMain: TStatusBar
    Left = 0
    Top = 621
    Width = 960
    Height = 19
    Panels = <>
    SimplePanel = True
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
    Left = 888
    Top = 64
  end
  object SaveDialog1: TSaveDialog
    Left = 888
    Top = 112
  end
  object tmrProgress: TTimer
    Enabled = False
    Interval = 100
    OnTimer = tmrProgressTimer
    Left = 888
    Top = 160
  end
end
