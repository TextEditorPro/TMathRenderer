unit Demo.MainForm;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, Vcl.ComCtrls, Vcl.Controls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics,
  Vcl.Samples.Spin, Vcl.StdCtrls, MathRenderer;

type
  TMainForm = class(TForm)
    ButtonCopyHTML: TButton;
    ButtonSave: TButton;
    CheckBoxDisplayMode: TCheckBox;
    ColorBoxBackground: TColorBox;
    ColorBoxColor: TColorBox;
    ComboBoxExamples: TComboBox;
    ComboBoxFormat: TComboBox;
    ImageFormula: TImage;
    ImageTag: TImage;
    LabelBackground: TLabel;
    LabelColor: TLabel;
    LabelExamples: TLabel;
    LabelFontSize: TLabel;
    LabelFormat: TLabel;
    LabelTeX: TLabel;
    MemoTeX: TMemo;
    PanelSettings: TPanel;
    SaveDialog: TSaveDialog;
    ScrollBoxPreview: TScrollBox;
    SpinEditFontSize: TSpinEdit;
    StatusBar: TStatusBar;
    TimerRender: TTimer;
    procedure ButtonCopyHTMLClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure ComboBoxExamplesChange(Sender: TObject);
    procedure ControlChange(Sender: TObject);
    procedure FormAfterMonitorDpiChanged(Sender: TObject; OldDPI: Integer; NewDPI: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerRenderTimer(Sender: TObject);
  strict private
    FRenderer: TMathRenderer;
    function HTMLPage: string;
    procedure ApplySettings;
    procedure RenderFormula;
    procedure ShowImage(const AImage: TImage; const AData: TBytes; const AWidth: Integer; const AHeight: Integer);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.Diagnostics, System.IOUtils, Vcl.Clipbrd, Vcl.Imaging.pngimage, MathRenderer.Types;

type
  TExample = record
    DisplayMode: Boolean;
    Name: string;
    TeX: string;
  end;

const
  EXAMPLES: array [0..9] of TExample = (
    (DisplayMode: True; Name: 'Quadratic formula'; TeX: 'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}'),
    (DisplayMode: False; Name: 'Euler''s identity (inline)'; TeX: 'e^{i\pi} + 1 = 0'),
    (DisplayMode: True; Name: 'Gaussian integral'; TeX: '\int_{-\infty}^{\infty} e^{-x^2}\,dx = \sqrt{\pi}'),
    (DisplayMode: True; Name: 'Sum of squares'; TeX: '\sum_{k=1}^{n} k^2 = \frac{n(n+1)(2n+1)}{6}'),
    (DisplayMode: True; Name: 'Matrix'; TeX: 'A = \begin{pmatrix} a_{11} & a_{12} \\ a_{21} & a_{22} \end{pmatrix}'),
    (DisplayMode: True; Name: 'Cases'; TeX: '|x| = \begin{cases} x & \text{if } x \ge 0 \\ -x & \text{otherwise} \end{cases}'),
    (DisplayMode: True; Name: 'Numbered equations'; TeX: '\begin{align} (a+b)^2 &= a^2 + 2ab + b^2 \\ (a-b)^2 &= a^2 - 2ab + b^2 \end{align}'),
    (DisplayMode: True; Name: 'Maxwell''s equations'; TeX: '\begin{aligned} \nabla \cdot \vec{E} &= \frac{\rho}{\varepsilon_0} \\ \nabla \times \vec{B} &= \mu_0 \vec{J} + \mu_0 \varepsilon_0 \frac{\partial \vec{E}}{\partial t} \end{aligned}'),
    (DisplayMode: True; Name: 'Commutative diagram'; TeX: '\begin{CD} A @>f>> B \\ @VgVV @VVhV \\ C @>>k> D \end{CD}'),
    (DisplayMode: False; Name: 'Arrows and boxes (inline)'; TeX: 'A \xrightarrow[\text{below}]{\text{above}} B \quad \boxed{E = mc^2} \quad \overbrace{a + b}^{n}'));

  IMAGE_MARGIN = 16;
  TAG_GAP = 32;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FRenderer := TMathRenderer.Create;

  for var LIndex := Low(EXAMPLES) to High(EXAMPLES) do
    ComboBoxExamples.Items.Add(EXAMPLES[LIndex].Name);

  ComboBoxExamples.ItemIndex := 0;
  ComboBoxExamplesChange(ComboBoxExamples);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FRenderer.Free;
end;

procedure TMainForm.FormAfterMonitorDpiChanged(Sender: TObject; OldDPI: Integer; NewDPI: Integer);
begin
  RenderFormula;
end;

procedure TMainForm.ComboBoxExamplesChange(Sender: TObject);
begin
  if ComboBoxExamples.ItemIndex < 0 then
    Exit;

  MemoTeX.Text := EXAMPLES[ComboBoxExamples.ItemIndex].TeX;
  CheckBoxDisplayMode.Checked := EXAMPLES[ComboBoxExamples.ItemIndex].DisplayMode;
  RenderFormula;
end;

procedure TMainForm.ControlChange(Sender: TObject);
begin
  TimerRender.Enabled := False;
  TimerRender.Enabled := True;
end;

procedure TMainForm.TimerRenderTimer(Sender: TObject);
begin
  RenderFormula;
end;

procedure TMainForm.ApplySettings;
begin
  FRenderer.FontName := Font.Name;
  FRenderer.FontSize := SpinEditFontSize.Value;
  FRenderer.PixelsPerInch := CurrentPPI;
  FRenderer.Color := ColorBoxColor.Selected;
  FRenderer.BackgroundColor := ColorBoxBackground.Selected;
  FRenderer.ImageFormat := if ComboBoxFormat.ItemIndex = 1 then ifPNG else ifEMF;

  ScrollBoxPreview.Color := ColorBoxBackground.Selected;
end;

procedure TMainForm.RenderFormula;
var
  LStopwatch: TStopwatch;
  LImage: TMathImage;
begin
  TimerRender.Enabled := False;

  ApplySettings;

  LStopwatch := TStopwatch.StartNew;

  try
    LImage := FRenderer.RenderToImage(MemoTeX.Text, CheckBoxDisplayMode.Checked);
  except
    on LException: EMathParseError do
    begin
      StatusBar.SimpleText := LException.Message;

      Exit;
    end;
  end;

  ShowImage(ImageFormula, LImage.Data, LImage.Width, LImage.Height);
  ImageTag.Visible := Length(LImage.TagData) > 0;

  if ImageTag.Visible then
  begin
    ShowImage(ImageTag, LImage.TagData, LImage.TagWidth, LImage.Height);
    ImageTag.Left := ImageFormula.Left + ImageFormula.Width + TAG_GAP;
  end;

  StatusBar.SimpleText := Format('%d x %d pixels, baseline %d pixels from the top, rendered in %.1f ms',
    [LImage.Width, LImage.Height, LImage.Baseline, LStopwatch.Elapsed.TotalMilliseconds]);
end;

procedure TMainForm.ShowImage(const AImage: TImage; const AData: TBytes; const AWidth: Integer; const AHeight: Integer);
var
  LGraphic: TGraphic;
begin
  if FRenderer.ImageFormat = ifPNG then
    LGraphic := TPngImage.Create
  else
    LGraphic := TMetafile.Create;

  try
    var LStream := TBytesStream.Create(AData);
    try
      LGraphic.LoadFromStream(LStream);
    finally
      LStream.Free;
    end;

    AImage.Picture.Assign(LGraphic);
  finally
    LGraphic.Free;
  end;

  AImage.SetBounds(IMAGE_MARGIN, IMAGE_MARGIN, AWidth, AHeight);
end;

{ A saved page is opened in a web browser, and browsers do not show Enhanced Metafiles, so its images are PNG }
function TMainForm.HTMLPage: string;
begin
  var LFormat := FRenderer.ImageFormat;

  FRenderer.ImageFormat := ifPNG;
  try
    Result := Format('<!doctype html>%s<html><head><meta charset="utf-8"><title>MathRenderer</title></head>%s' +
      '<body style="font-family:''%s''; font-size:%dpt">%s%s%s</body></html>%s', [sLineBreak, sLineBreak, Font.Name,
      SpinEditFontSize.Value, sLineBreak, FRenderer.RenderToHTML(MemoTeX.Text, CheckBoxDisplayMode.Checked), sLineBreak,
      sLineBreak]);
  finally
    FRenderer.ImageFormat := LFormat;
  end;
end;

procedure TMainForm.ButtonSaveClick(Sender: TObject);
begin
  SaveDialog.FilterIndex := if FRenderer.ImageFormat = ifPNG then 2 else 1;

  if not SaveDialog.Execute then
    Exit;

  ApplySettings;

  var LExtension := LowerCase(ExtractFileExt(SaveDialog.FileName));

  if LExtension = '.html' then
    TFile.WriteAllText(SaveDialog.FileName, HTMLPage, TEncoding.UTF8)
  else
  begin
    var LFormat := FRenderer.ImageFormat;

    FRenderer.ImageFormat := if LExtension = '.png' then ifPNG else ifEMF;
    try
      TFile.WriteAllBytes(SaveDialog.FileName, FRenderer.RenderToImage(MemoTeX.Text, CheckBoxDisplayMode.Checked).Data);
    finally
      FRenderer.ImageFormat := LFormat;
    end;
  end;

  StatusBar.SimpleText := 'Saved ' + SaveDialog.FileName;
end;

procedure TMainForm.ButtonCopyHTMLClick(Sender: TObject);
begin
  ApplySettings;

  Clipboard.AsText := FRenderer.RenderToHTML(MemoTeX.Text, CheckBoxDisplayMode.Checked);

  if FRenderer.ImageFormat = ifEMF then
    StatusBar.SimpleText := 'Copied the HTML of the formula to the clipboard; its Enhanced Metafile shows in Windows HTML ' +
      'components but not in web browsers, which need PNG'
  else
    StatusBar.SimpleText := 'Copied the HTML of the formula to the clipboard';
end;

end.
