unit MathRenderer.FontMetrics;

interface

uses
  MathRenderer.Types;

type
  TMathCharacterMetrics = record
    Depth: Double;
    Height: Double;
    Italic: Double;
    Skew: Double;
    Width: Double;
  end;

  TMathGlobalMetrics = record
    Slant: Double;
    Space: Double;
    Stretch: Double;
    Shrink: Double;
    XHeight: Double;
    Quad: Double;
    ExtraSpace: Double;
    Num1: Double;
    Num2: Double;
    Num3: Double;
    Denom1: Double;
    Denom2: Double;
    Sup1: Double;
    Sup2: Double;
    Sup3: Double;
    Sub1: Double;
    Sub2: Double;
    SupDrop: Double;
    SubDrop: Double;
    Delim1: Double;
    Delim2: Double;
    AxisHeight: Double;
    DefaultRuleThickness: Double;
    BigOpSpacing1: Double;
    BigOpSpacing2: Double;
    BigOpSpacing3: Double;
    BigOpSpacing4: Double;
    BigOpSpacing5: Double;
    SqrtRuleThickness: Double;
    PtPerEm: Double;
    DoubleRuleSep: Double;
    ArrayRuleWidth: Double;
    FBoxSep: Double;
    FBoxRule: Double;
    CssEmPerMu: Double;
  end;
  PMathGlobalMetrics = ^TMathGlobalMetrics;

function GetCharacterMetrics(const ACharacter: string; const AFont: TMathFont; const AMode: TMathMode; out AMetrics: TMathCharacterMetrics): Boolean;
function GetGlobalMetrics(const ASize: Integer): PMathGlobalMetrics;
function HasCharacterMetrics(const ACharCode: Integer; const AFont: TMathFont): Boolean;
function IsSupportedCodepoint(const ACodepoint: Integer): Boolean;

implementation

uses
  System.SysUtils, MathRenderer.FontMetricsData;

const
  { Index 0 is textstyle (cmsy10), 1 is scriptstyle (cmsy7) and 2 is scriptscriptstyle (cmsy5) }
  GLOBAL_METRICS: array [0..2] of TMathGlobalMetrics = (
    (Slant: 0.250; Space: 0; Stretch: 0; Shrink: 0; XHeight: 0.431; Quad: 1.000; ExtraSpace: 0; Num1: 0.677; Num2: 0.394;
     Num3: 0.444; Denom1: 0.686; Denom2: 0.345; Sup1: 0.413; Sup2: 0.363; Sup3: 0.289; Sub1: 0.150; Sub2: 0.247; SupDrop: 0.386;
     SubDrop: 0.050; Delim1: 2.390; Delim2: 1.010; AxisHeight: 0.250; DefaultRuleThickness: 0.04; BigOpSpacing1: 0.111;
     BigOpSpacing2: 0.166; BigOpSpacing3: 0.2; BigOpSpacing4: 0.6; BigOpSpacing5: 0.1; SqrtRuleThickness: 0.04; PtPerEm: 10.0;
     DoubleRuleSep: 0.2; ArrayRuleWidth: 0.04; FBoxSep: 0.3; FBoxRule: 0.04; CssEmPerMu: 1.000 / 18),
    (Slant: 0.250; Space: 0; Stretch: 0; Shrink: 0; XHeight: 0.431; Quad: 1.171; ExtraSpace: 0; Num1: 0.732; Num2: 0.384;
     Num3: 0.471; Denom1: 0.752; Denom2: 0.344; Sup1: 0.503; Sup2: 0.431; Sup3: 0.286; Sub1: 0.143; Sub2: 0.286; SupDrop: 0.353;
     SubDrop: 0.071; Delim1: 1.700; Delim2: 1.157; AxisHeight: 0.250; DefaultRuleThickness: 0.049; BigOpSpacing1: 0.111;
     BigOpSpacing2: 0.166; BigOpSpacing3: 0.2; BigOpSpacing4: 0.611; BigOpSpacing5: 0.143; SqrtRuleThickness: 0.04;
     PtPerEm: 10.0; DoubleRuleSep: 0.2; ArrayRuleWidth: 0.04; FBoxSep: 0.3; FBoxRule: 0.04; CssEmPerMu: 1.171 / 18),
    (Slant: 0.250; Space: 0; Stretch: 0; Shrink: 0; XHeight: 0.431; Quad: 1.472; ExtraSpace: 0; Num1: 0.925; Num2: 0.387;
     Num3: 0.504; Denom1: 1.025; Denom2: 0.532; Sup1: 0.504; Sup2: 0.404; Sup3: 0.294; Sub1: 0.200; Sub2: 0.400; SupDrop: 0.494;
     SubDrop: 0.100; Delim1: 1.980; Delim2: 1.420; AxisHeight: 0.250; DefaultRuleThickness: 0.049; BigOpSpacing1: 0.111;
     BigOpSpacing2: 0.166; BigOpSpacing3: 0.2; BigOpSpacing4: 0.611; BigOpSpacing5: 0.143; SqrtRuleThickness: 0.04;
     PtPerEm: 10.0; DoubleRuleSep: 0.2; ArrayRuleWidth: 0.04; FBoxSep: 0.3; FBoxRule: 0.04; CssEmPerMu: 1.472 / 18)
  );

  { Metric substitutes for Cyrillic U+0410..U+044F }
  CYRILLIC_METRIC_SUBSTITUTES = 'ABBFAEK3NNKNMHONPCTyOXUhWWBXB3XR' + 'abaryemennnnmnonpcoybxnnwwamaemr';

function FindMetricsEntry(const AFont: TMathFont; const ACharCode: Integer; out AMetrics: TMathCharacterMetrics): Boolean;
begin
  var LLow := FONT_METRICS_RANGES[AFont].First;
  var LHigh := LLow + FONT_METRICS_RANGES[AFont].Count - 1;
  var LMiddle: Integer;

  while LLow <= LHigh do
  begin
    LMiddle := (LLow + LHigh) div 2;

    if FONT_METRICS_DATA[LMiddle].CharCode < ACharCode then
      LLow := LMiddle + 1
    else
    if FONT_METRICS_DATA[LMiddle].CharCode > ACharCode then
      LHigh := LMiddle - 1
    else
    begin
      AMetrics.Depth := FONT_METRICS_DATA[LMiddle].Depth;
      AMetrics.Height := FONT_METRICS_DATA[LMiddle].Height;
      AMetrics.Italic := FONT_METRICS_DATA[LMiddle].Italic;
      AMetrics.Skew := FONT_METRICS_DATA[LMiddle].Skew;
      AMetrics.Width := FONT_METRICS_DATA[LMiddle].Width;

      Exit(True);
    end;
  end;

  Result := False;
end;

function HasCharacterMetrics(const ACharCode: Integer; const AFont: TMathFont): Boolean;
var
  LMetrics: TMathCharacterMetrics;
begin
  Result := (AFont <> mfNone) and FindMetricsEntry(AFont, ACharCode, LMetrics);
end;

function GetMetricSubstitute(const ACharCode: Integer): Integer;
begin
  case ACharCode of
    $00C5:
      Result := Ord('A');
    $00D0:
      Result := Ord('D');
    $00DE:
      Result := Ord('o');
    $00E5:
      Result := Ord('a');
    $00F0:
      Result := Ord('d');
    $00FE:
      Result := Ord('o');
    $0410..$044F:
      Result := Ord(CYRILLIC_METRIC_SUBSTITUTES[ACharCode - $0410 + 1]);
  else
    Result := -1;
  end;
end;

function IsSupportedCodepoint(const ACodepoint: Integer): Boolean;
begin
  case ACodepoint of
    $0100..$024F, $0300..$036F, $0400..$04FF, $0530..$058F, $0900..$109F, $10A0..$10FF, $3000..$30FF, $4E00..$9FAF, $FF00..$FF60, $AC00..$D7AF:
      Result := True;
  else
    Result := False;
  end;
end;

function GetCharacterMetrics(const ACharacter: string; const AFont: TMathFont; const AMode: TMathMode; out AMetrics: TMathCharacterMetrics): Boolean;
begin
  if (AFont = mfNone) or ACharacter.IsEmpty then
    Exit(False);

  var LCharCode := Ord(ACharacter[1]);

  if FindMetricsEntry(AFont, LCharCode, AMetrics) then
    Exit(True);

  var LSubstitute := GetMetricSubstitute(LCharCode);

  if (LSubstitute >= 0) and FindMetricsEntry(AFont, LSubstitute, AMetrics) then
    Exit(True);

  if (AMode = mmText) and IsSupportedCodepoint(LCharCode) then
    Exit(FindMetricsEntry(AFont, Ord('M'), AMetrics));

  Result := False;
end;

function GetGlobalMetrics(const ASize: Integer): PMathGlobalMetrics;
begin
  if ASize >= 5 then
    Result := @GLOBAL_METRICS[0]
  else
  if ASize >= 3 then
    Result := @GLOBAL_METRICS[1]
  else
    Result := @GLOBAL_METRICS[2];
end;

end.
