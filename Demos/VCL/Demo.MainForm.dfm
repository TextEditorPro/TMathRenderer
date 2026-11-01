object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MathRenderer Demo'
  ClientHeight = 600
  ClientWidth = 880
  Color = clBtnFace
  Constraints.MinHeight = 400
  Constraints.MinWidth = 700
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnAfterMonitorDpiChanged = FormAfterMonitorDpiChanged
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object PanelSettings: TPanel
    Left = 0
    Top = 0
    Width = 880
    Height = 200
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      880
      200)
    object LabelExamples: TLabel
      Left = 12
      Top = 10
      Width = 49
      Height = 15
      Caption = 'Examples'
    end
    object LabelTeX: TLabel
      Left = 12
      Top = 62
      Width = 19
      Height = 15
      Caption = 'TeX'
    end
    object LabelFontSize: TLabel
      Left = 600
      Top = 62
      Width = 68
      Height = 15
      Anchors = [akTop, akRight]
      Caption = 'Font size (pt)'
    end
    object LabelColor: TLabel
      Left = 600
      Top = 96
      Width = 29
      Height = 15
      Anchors = [akTop, akRight]
      Caption = 'Color'
    end
    object LabelBackground: TLabel
      Left = 600
      Top = 130
      Width = 64
      Height = 15
      Anchors = [akTop, akRight]
      Caption = 'Background'
    end
    object LabelFormat: TLabel
      Left = 600
      Top = 164
      Width = 38
      Height = 15
      Anchors = [akTop, akRight]
      Caption = 'Format'
    end
    object ComboBoxExamples: TComboBox
      Left = 12
      Top = 28
      Width = 320
      Height = 23
      Style = csDropDownList
      DropDownCount = 10
      TabOrder = 0
      OnChange = ComboBoxExamplesChange
    end
    object ButtonSave: TButton
      Left = 344
      Top = 27
      Width = 100
      Height = 25
      Caption = 'Save...'
      TabOrder = 1
      OnClick = ButtonSaveClick
    end
    object ButtonCopyHTML: TButton
      Left = 452
      Top = 27
      Width = 100
      Height = 25
      Caption = 'Copy HTML'
      TabOrder = 2
      OnClick = ButtonCopyHTMLClick
    end
    object MemoTeX: TMemo
      Left = 12
      Top = 80
      Width = 570
      Height = 108
      Anchors = [akLeft, akTop, akRight]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 3
      OnChange = ControlChange
    end
    object CheckBoxDisplayMode: TCheckBox
      Left = 600
      Top = 30
      Width = 260
      Height = 19
      Anchors = [akTop, akRight]
      Caption = 'Display mode'
      TabOrder = 4
      OnClick = ControlChange
    end
    object SpinEditFontSize: TSpinEdit
      Left = 700
      Top = 58
      Width = 80
      Height = 24
      Anchors = [akTop, akRight]
      MaxValue = 72
      MinValue = 6
      TabOrder = 5
      Value = 12
      OnChange = ControlChange
    end
    object ColorBoxColor: TColorBox
      Left = 700
      Top = 92
      Width = 160
      Height = 22
      Style = [cbStandardColors, cbExtendedColors, cbCustomColor, cbPrettyNames]
      Anchors = [akTop, akRight]
      TabOrder = 6
      OnChange = ControlChange
    end
    object ColorBoxBackground: TColorBox
      Left = 700
      Top = 126
      Width = 160
      Height = 22
      Selected = clWhite
      Style = [cbStandardColors, cbExtendedColors, cbCustomColor, cbPrettyNames]
      Anchors = [akTop, akRight]
      TabOrder = 7
      OnChange = ControlChange
    end
    object ComboBoxFormat: TComboBox
      Left = 700
      Top = 160
      Width = 160
      Height = 23
      Style = csDropDownList
      Anchors = [akTop, akRight]
      ItemIndex = 1
      TabOrder = 8
      Text = 'PNG'
      OnChange = ControlChange
      Items.Strings = (
        'Enhanced Metafile'
        'PNG')
    end
  end
  object ScrollBoxPreview: TScrollBox
    Left = 0
    Top = 200
    Width = 880
    Height = 381
    Align = alClient
    Color = clWhite
    ParentColor = False
    TabOrder = 1
    object ImageFormula: TImage
      Left = 16
      Top = 16
      Width = 100
      Height = 50
      Stretch = True
    end
    object ImageTag: TImage
      Left = 148
      Top = 16
      Width = 40
      Height = 50
      Stretch = True
      Visible = False
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 581
    Width = 880
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object TimerRender: TTimer
    Enabled = False
    Interval = 300
    OnTimer = TimerRenderTimer
    Left = 820
    Top = 220
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'png'
    FileName = 'formula'
    Filter = 
      'Enhanced Metafile (*.emf)|*.emf|PNG image (*.png)|*.png|HTML pag' +
      'e (*.html)|*.html'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 820
    Top = 280
  end
end
