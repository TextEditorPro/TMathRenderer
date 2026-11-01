program ConsoleDemo;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  System.IOUtils,
  Vcl.Graphics,
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
  MathRenderer.Types in '..\..\Source\MathRenderer.Types.pas';

type
  TOutputKind = (okPNG, okEMF, okHTML);

  TDemoOptions = record
    BackgroundColor: TColor;
    Color: TColor;
    DisplayMode: Boolean;
    FontName: string;
    FontSize: Integer;
    HTMLImageFormat: TMathImageFormat;
    InputFileName: string;
    OutputFileName: string;
    OutputKind: TOutputKind;
    PixelsPerInch: Integer;
    TeX: string;
    ThrowOnError: Boolean;
  end;

const
  OUTPUT_EXTENSIONS: array [TOutputKind] of string = ('.png', '.emf', '.html');

procedure WriteUsage;
begin
  Writeln('Renders TeX math with MathRenderer.');
  Writeln;
  Writeln('Usage: ConsoleDemo [options] <TeX>');
  Writeln('       ConsoleDemo [options] --html <input.html>');
  Writeln;
  Writeln('Options:');
  Writeln('  -d, --display            Display mode (centered, larger operators) instead of inline');
  Writeln('  -f, --format png|emf|html');
  Writeln('                           Output format, png by default; html writes a page with the formula');
  Writeln('  -o, --output <file>      Output file, formula.png, formula.emf or formula.html by default');
  Writeln('  -s, --size <points>      Font size of the surrounding text, 12 by default');
  Writeln('      --font <name>        Font of the surrounding text, Segoe UI by default');
  Writeln('  -c, --color <color>      Color of the math, as #RRGGBB or a name such as navy, black by default');
  Writeln('  -b, --background <color> Background of PNG images, white by default');
  Writeln('      --ppi <number>       Pixels per inch, 96 by default');
  Writeln('      --html <file>        Replace every $...$, $$...$$, \(...\) and \[...\] in an HTML file');
  Writeln('      --html-images png|emf');
  Writeln('                           Images of HTML output, png by default; web browsers do not show emf');
  Writeln('      --throw-on-error     Fail on unknown commands instead of showing them in red');
  Writeln('  -h, --help               Show this text');
  Writeln;
  Writeln('Examples:');
  Writeln('  ConsoleDemo "x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}"');
  Writeln('  ConsoleDemo -d -f emf -o integral.emf "\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}"');
  Writeln('  ConsoleDemo -s 16 -c navy -f html "\begin{pmatrix} a & b \\ c & d \end{pmatrix}"');
  Writeln('  ConsoleDemo --html answer.html -o answer.math.html');
end;

function ParseColor(const AText: string): TColor;
var
  LColor: TMathColor;
begin
  if not TryParseMathColor(AText, LColor) or (LColor.Kind <> ckValue) then
    raise EArgumentException.CreateFmt('Unknown color: %s', [AText]);

  Result := RGB((LColor.Value shr 16) and $FF, (LColor.Value shr 8) and $FF, LColor.Value and $FF);
end;

function ParseOutputKind(const AText: string): TOutputKind;
begin
  for var LKind := Low(TOutputKind) to High(TOutputKind) do
  if SameText('.' + AText, OUTPUT_EXTENSIONS[LKind]) then
    Exit(LKind);

  raise EArgumentException.CreateFmt('Unknown format: %s', [AText]);
end;

function ParseImageFormat(const AText: string): TMathImageFormat;
begin
  if SameText(AText, 'png') then
    Exit(ifPNG);

  if SameText(AText, 'emf') then
    Exit(ifEMF);

  raise EArgumentException.CreateFmt('Unknown image format: %s', [AText]);
end;

function ParseInteger(const AOption: string; const AText: string): Integer;
begin
  if not TryStrToInt(AText, Result) or (Result <= 0) then
    raise EArgumentException.CreateFmt('%s needs a positive number, not %s', [AOption, AText]);
end;

function ParseCommandLine(out AOptions: TDemoOptions): Boolean;
var
  LIndex: Integer;
  LArgument: string;

  function NextValue: string;
  begin
    if LIndex >= ParamCount then
      raise EArgumentException.CreateFmt('%s needs a value', [LArgument]);

    Inc(LIndex);
    Result := ParamStr(LIndex);
  end;

begin
  AOptions := Default(TDemoOptions);
  AOptions.BackgroundColor := clWhite;
  AOptions.Color := clBlack;
  AOptions.FontName := 'Segoe UI';
  AOptions.FontSize := 12;
  AOptions.HTMLImageFormat := ifPNG;
  AOptions.PixelsPerInch := 96;
  LIndex := 1;

  while LIndex <= ParamCount do
  begin
    LArgument := ParamStr(LIndex);

    if (LArgument = '-h') or (LArgument = '--help') or (LArgument = '/?') then
      Exit(False)
    else
    if (LArgument = '-d') or (LArgument = '--display') then
      AOptions.DisplayMode := True
    else
    if (LArgument = '-f') or (LArgument = '--format') then
      AOptions.OutputKind := ParseOutputKind(NextValue)
    else
    if (LArgument = '-o') or (LArgument = '--output') then
      AOptions.OutputFileName := NextValue
    else
    if (LArgument = '-s') or (LArgument = '--size') then
      AOptions.FontSize := ParseInteger(LArgument, NextValue)
    else
    if LArgument = '--font' then
      AOptions.FontName := NextValue
    else
    if (LArgument = '-c') or (LArgument = '--color') then
      AOptions.Color := ParseColor(NextValue)
    else
    if (LArgument = '-b') or (LArgument = '--background') then
      AOptions.BackgroundColor := ParseColor(NextValue)
    else
    if LArgument = '--ppi' then
      AOptions.PixelsPerInch := ParseInteger(LArgument, NextValue)
    else
    if LArgument = '--html' then
      AOptions.InputFileName := NextValue
    else
    if LArgument = '--html-images' then
      AOptions.HTMLImageFormat := ParseImageFormat(NextValue)
    else
    if LArgument = '--throw-on-error' then
      AOptions.ThrowOnError := True
    else
    if LArgument.StartsWith('--') or ((LArgument.Length = 2) and (LArgument[1] = '-') and CharInSet(LArgument[2], ['a'..'z'])) then
      raise EArgumentException.CreateFmt('Unknown option: %s', [LArgument])
    else
    if AOptions.TeX.IsEmpty then
      AOptions.TeX := LArgument
    else
      AOptions.TeX := AOptions.TeX + ' ' + LArgument;

    Inc(LIndex);
  end;

  if not AOptions.InputFileName.IsEmpty then
    AOptions.OutputKind := okHTML;

  if AOptions.OutputFileName.IsEmpty then
  begin
    if AOptions.InputFileName.IsEmpty then
      AOptions.OutputFileName := 'formula' + OUTPUT_EXTENSIONS[AOptions.OutputKind]
    else
      AOptions.OutputFileName := TPath.ChangeExtension(AOptions.InputFileName, '.math.html');
  end;

  Result := not AOptions.TeX.IsEmpty or not AOptions.InputFileName.IsEmpty;
end;

function HTMLPage(const AOptions: TDemoOptions; const ABody: string): string;
begin
  Result := Format('<!doctype html>%s<html><head><meta charset="utf-8"><title>MathRenderer</title></head>%s' +
    '<body style="font-family:''%s''; font-size:%dpt">%s%s%s</body></html>%s', [sLineBreak, sLineBreak, AOptions.FontName,
    AOptions.FontSize, sLineBreak, ABody, sLineBreak, sLineBreak]);
end;

procedure WriteImage(const ARenderer: TMathRenderer; const AOptions: TDemoOptions);
var
  LImage: TMathImage;
  LTagFileName: string;
begin
  ARenderer.ImageFormat := if AOptions.OutputKind = okEMF then ifEMF else ifPNG;
  LImage := ARenderer.RenderToImage(AOptions.TeX, AOptions.DisplayMode);
  TFile.WriteAllBytes(AOptions.OutputFileName, LImage.Data);
  Writeln(Format('Wrote %s: %d x %d pixels, baseline %d pixels from the top', [AOptions.OutputFileName, LImage.Width,
    LImage.Height, LImage.Baseline]));

  if Length(LImage.TagData) > 0 then
  begin
    LTagFileName := TPath.ChangeExtension(AOptions.OutputFileName, '.tag' + TPath.GetExtension(AOptions.OutputFileName));
    TFile.WriteAllBytes(LTagFileName, LImage.TagData);
    Writeln(Format('Wrote %s: the equation number, %d x %d pixels', [LTagFileName, LImage.TagWidth, LImage.Height]));
  end;
end;

procedure WriteHTML(const ARenderer: TMathRenderer; const AOptions: TDemoOptions);
var
  LBody: string;
begin
  ARenderer.ImageFormat := AOptions.HTMLImageFormat;

  if AOptions.InputFileName.IsEmpty then
    LBody := HTMLPage(AOptions, ARenderer.RenderToHTML(AOptions.TeX, AOptions.DisplayMode))
  else
    LBody := ARenderer.ReplaceMathInHTML(TFile.ReadAllText(AOptions.InputFileName, TEncoding.UTF8));

  TFile.WriteAllText(AOptions.OutputFileName, LBody, TEncoding.UTF8);
  Writeln('Wrote ', AOptions.OutputFileName);
end;

var
  LOptions: TDemoOptions;
  LRenderer: TMathRenderer;
begin
  try
    if not ParseCommandLine(LOptions) then
    begin
      WriteUsage;

      Exit;
    end;

    LRenderer := TMathRenderer.Create;
    try
      LRenderer.BackgroundColor := LOptions.BackgroundColor;
      LRenderer.Color := LOptions.Color;
      LRenderer.FontName := LOptions.FontName;
      LRenderer.FontSize := LOptions.FontSize;
      LRenderer.PixelsPerInch := LOptions.PixelsPerInch;
      LRenderer.ThrowOnError := LOptions.ThrowOnError;

      if LOptions.OutputKind = okHTML then
        WriteHTML(LRenderer, LOptions)
      else
        WriteImage(LRenderer, LOptions);
    finally
      LRenderer.Free;
    end;
  except
    on LException: Exception do
    begin
      Writeln(ErrOutput, LException.Message);
      ExitCode := 1;
    end;
  end;
end.
