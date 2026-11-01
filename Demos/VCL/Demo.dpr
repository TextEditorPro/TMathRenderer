program Demo;

uses
  Vcl.Forms,
  MathRenderer in '..\..\Source\MathRenderer.pas',
  MathRenderer.Boxes in '..\..\Source\MathRenderer.Boxes.pas',
  MathRenderer.Chemistry in '..\..\Source\MathRenderer.Chemistry.pas',
  MathRenderer.Builder in '..\..\Source\MathRenderer.Builder.pas',
  MathRenderer.FontMetrics in '..\..\Source\MathRenderer.FontMetrics.pas',
  MathRenderer.FontMetricsData in '..\..\Source\MathRenderer.FontMetricsData.pas',
  MathRenderer.Fonts in '..\..\Source\MathRenderer.Fonts.pas',
  MathRenderer.Options in '..\..\Source\MathRenderer.Options.pas',
  MathRenderer.Painter in '..\..\Source\MathRenderer.Painter.pas',
  MathRenderer.ParseTree in '..\..\Source\MathRenderer.ParseTree.pas',
  MathRenderer.Parser in '..\..\Source\MathRenderer.Parser.pas',
  MathRenderer.SvgData in '..\..\Source\MathRenderer.SvgData.pas',
  MathRenderer.SymbolData in '..\..\Source\MathRenderer.SymbolData.pas',
  MathRenderer.Symbols in '..\..\Source\MathRenderer.Symbols.pas',
  MathRenderer.Types in '..\..\Source\MathRenderer.Types.pas',
  Demo.MainForm in 'Demo.MainForm.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'MathRenderer Demo';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
