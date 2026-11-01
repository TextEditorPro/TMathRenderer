program Demo;

uses
  Vcl.Forms,
  MathRenderer.Types in '..\..\Source\MathRenderer.Types.pas',
  MathRenderer.FontMetricsData in '..\..\Source\MathRenderer.FontMetricsData.pas',
  MathRenderer.FontMetrics in '..\..\Source\MathRenderer.FontMetrics.pas',
  MathRenderer.SymbolData in '..\..\Source\MathRenderer.SymbolData.pas',
  MathRenderer.Symbols in '..\..\Source\MathRenderer.Symbols.pas',
  MathRenderer.ParseTree in '..\..\Source\MathRenderer.ParseTree.pas',
  MathRenderer.Parser in '..\..\Source\MathRenderer.Parser.pas',
  MathRenderer.Options in '..\..\Source\MathRenderer.Options.pas',
  MathRenderer.Boxes in '..\..\Source\MathRenderer.Boxes.pas',
  MathRenderer.Builder in '..\..\Source\MathRenderer.Builder.pas',
  MathRenderer.Fonts in '..\..\Source\MathRenderer.Fonts.pas',
  MathRenderer.SvgData in '..\..\Source\MathRenderer.SvgData.pas',
  MathRenderer.Painter in '..\..\Source\MathRenderer.Painter.pas',
  MathRenderer in '..\..\Source\MathRenderer.pas',
  Demo.MainForm in 'Demo.MainForm.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'MathRenderer Demo';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
