unit MathRenderer.Options;

interface

uses
  System.Generics.Collections, MathRenderer.FontMetrics, MathRenderer.Types;

type
  TMathStyle = record
  strict private
    FId: Integer;
  public
    class function Create(const AId: Integer): TMathStyle; static;
    class function Display: TMathStyle; static;
    class function Script: TMathStyle; static;
    class function ScriptScript: TMathStyle; static;
    class function Text: TMathStyle; static;
    class operator Equal(const ALeft: TMathStyle; const ARight: TMathStyle): Boolean;
    class operator NotEqual(const ALeft: TMathStyle; const ARight: TMathStyle): Boolean;
    function Cramp: TMathStyle;
    function Cramped: Boolean;
    function FractionDenominator: TMathStyle;
    function FractionNumerator: TMathStyle;
    function IsTight: Boolean;
    function Size: Integer;
    function Subscript: TMathStyle;
    function Superscript: TMathStyle;
    function TextStyle: TMathStyle;
    property Id: Integer read FId;
  end;

  TMathOptions = class;
  TMathOptionsList = TObjectList<TMathOptions>;

  TMathOptions = class(TObject)
  strict private
    FColor: TMathColor;
    FFont: string;
    FFontFamily: string;
    FFontShape: string;
    FFontWeight: string;
    FMaxSize: Double;
    FMinRuleThickness: Double;
    FOwner: TMathOptionsList;
    FPhantom: Boolean;
    FSize: Integer;
    FSizeMultiplier: Double;
    FStyle: TMathStyle;
    FTextSize: Integer;
    function Clone: TMathOptions;
  public
    constructor Create(const AOwner: TMathOptionsList; const AStyle: TMathStyle; const AMaxSize: Double;
      const AMinRuleThickness: Double);
    function BaseSizingMultiplier: Double;
    function FontMetrics: PMathGlobalMetrics;
    function GetColor: TMathColor;
    function HavingBaseSizing: TMathOptions;
    function HavingBaseStyle(const AStyle: TMathStyle): TMathOptions; overload;
    function HavingBaseStyle: TMathOptions; overload;
    function HavingCrampedStyle: TMathOptions;
    function HavingSize(const ASize: Integer): TMathOptions;
    function HavingStyle(const AStyle: TMathStyle): TMathOptions;
    function WithColor(const AColor: TMathColor): TMathOptions;
    function WithFont(const AFont: string): TMathOptions;
    function WithPhantom: TMathOptions;
    function WithTextFontFamily(const AFontFamily: string): TMathOptions;
    function WithTextFontShape(const AFontShape: string): TMathOptions;
    function WithTextFontWeight(const AFontWeight: string): TMathOptions;
    property Color: TMathColor read FColor;
    property Font: string read FFont;
    property FontFamily: string read FFontFamily;
    property FontShape: string read FFontShape;
    property FontWeight: string read FFontWeight;
    property MaxSize: Double read FMaxSize;
    property MinRuleThickness: Double read FMinRuleThickness;
    property Phantom: Boolean read FPhantom;
    property Size: Integer read FSize;
    property SizeMultiplier: Double read FSizeMultiplier;
    property Style: TMathStyle read FStyle;
    property TextSize: Integer read FTextSize;
  end;

const
  BASE_SIZE = 6;

  SIZE_MULTIPLIERS: array [1..11] of Double = (0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.2, 1.44, 1.728, 2.074, 2.488);

function CalculateSize(const AMeasurement: TMathMeasurement; const AOptions: TMathOptions): Double;
function MeasurementFromMu(const AMu: Double): TMathMeasurement; inline;

implementation

uses
  System.Math, MathRenderer.Parser;

const
  STYLE_DISPLAY = 0;
  STYLE_TEXT = 2;
  STYLE_SCRIPT = 4;
  STYLE_SCRIPTSCRIPT = 6;

  STYLE_SUPERSCRIPT: array [0..7] of Integer = (4, 5, 4, 5, 6, 7, 6, 7);
  STYLE_SUBSCRIPT: array [0..7] of Integer = (5, 5, 5, 5, 7, 7, 7, 7);
  STYLE_FRACTION_NUMERATOR: array [0..7] of Integer = (2, 3, 4, 5, 6, 7, 6, 7);
  STYLE_FRACTION_DENOMINATOR: array [0..7] of Integer = (3, 3, 5, 5, 7, 7, 7, 7);
  STYLE_CRAMP: array [0..7] of Integer = (1, 1, 3, 3, 5, 5, 7, 7);
  STYLE_TEXT_STYLE: array [0..7] of Integer = (0, 1, 2, 3, 2, 3, 2, 3);
  SIZE_STYLE_MAP: array [1..11, 1..3] of Integer = ((1, 1, 1), (2, 1, 1), (3, 1, 1), (4, 2, 1), (5, 2, 1), (6, 3, 1),
    (7, 4, 2), (8, 6, 3), (9, 7, 6), (10, 8, 7), (11, 10, 9));
  UNIT_PT: array [0..11] of string = ('pt', 'mm', 'cm', 'in', 'bp', 'pc', 'dd', 'cc', 'nd', 'nc', 'sp', 'px');
  UNIT_PT_VALUE: array [0..11] of Double = (1, 7227 / 2540, 7227 / 254, 72.27, 803 / 800, 12, 1238 / 1157, 14856 / 1157,
    685 / 642, 1370 / 107, 1 / 65536, 803 / 800);

{ TMathStyle }

class function TMathStyle.Create(const AId: Integer): TMathStyle;
begin
  Result.FId := AId;
end;

class function TMathStyle.Display: TMathStyle;
begin
  Result := Create(STYLE_DISPLAY);
end;

class function TMathStyle.Text: TMathStyle;
begin
  Result := Create(STYLE_TEXT);
end;

class function TMathStyle.Script: TMathStyle;
begin
  Result := Create(STYLE_SCRIPT);
end;

class function TMathStyle.ScriptScript: TMathStyle;
begin
  Result := Create(STYLE_SCRIPTSCRIPT);
end;

class operator TMathStyle.Equal(const ALeft: TMathStyle; const ARight: TMathStyle): Boolean;
begin
  Result := ALeft.FId = ARight.FId;
end;

class operator TMathStyle.NotEqual(const ALeft: TMathStyle; const ARight: TMathStyle): Boolean;
begin
  Result := ALeft.FId <> ARight.FId;
end;

function TMathStyle.Size: Integer;
begin
  Result := FId div 2;
end;

function TMathStyle.Cramped: Boolean;
begin
  Result := Odd(FId);
end;

function TMathStyle.Superscript: TMathStyle;
begin
  Result := Create(STYLE_SUPERSCRIPT[FId]);
end;

function TMathStyle.Subscript: TMathStyle;
begin
  Result := Create(STYLE_SUBSCRIPT[FId]);
end;

function TMathStyle.FractionNumerator: TMathStyle;
begin
  Result := Create(STYLE_FRACTION_NUMERATOR[FId]);
end;

function TMathStyle.FractionDenominator: TMathStyle;
begin
  Result := Create(STYLE_FRACTION_DENOMINATOR[FId]);
end;

function TMathStyle.Cramp: TMathStyle;
begin
  Result := Create(STYLE_CRAMP[FId]);
end;

function TMathStyle.TextStyle: TMathStyle;
begin
  Result := Create(STYLE_TEXT_STYLE[FId]);
end;

function TMathStyle.IsTight: Boolean;
begin
  Result := Size >= 2;
end;

{ TMathOptions }

function SizeAtStyle(const ASize: Integer; const AStyle: TMathStyle): Integer;
begin
  Result := if AStyle.Size < 2 then ASize else SIZE_STYLE_MAP[ASize, AStyle.Size];
end;

constructor TMathOptions.Create(const AOwner: TMathOptionsList; const AStyle: TMathStyle; const AMaxSize: Double;
  const AMinRuleThickness: Double);
begin
  inherited Create;

  FOwner := AOwner;
  FOwner.Add(Self);
  FStyle := AStyle;
  FColor := TMathColor.Default;
  FSize := BASE_SIZE;
  FTextSize := BASE_SIZE;
  FSizeMultiplier := SIZE_MULTIPLIERS[BASE_SIZE];
  FMaxSize := AMaxSize;
  FMinRuleThickness := AMinRuleThickness;
end;

function TMathOptions.Clone: TMathOptions;
begin
  Result := TMathOptions.Create(FOwner, FStyle, FMaxSize, FMinRuleThickness);

  Result.FColor := FColor;
  Result.FFont := FFont;
  Result.FFontFamily := FFontFamily;
  Result.FFontShape := FFontShape;
  Result.FFontWeight := FFontWeight;
  Result.FPhantom := FPhantom;
  Result.FSize := FSize;
  Result.FSizeMultiplier := FSizeMultiplier;
  Result.FTextSize := FTextSize;
end;

function TMathOptions.HavingStyle(const AStyle: TMathStyle): TMathOptions;
begin
  if FStyle = AStyle then
    Exit(Self);

  Result := Clone;

  Result.FStyle := AStyle;
  Result.FSize := SizeAtStyle(FTextSize, AStyle);
  Result.FSizeMultiplier := SIZE_MULTIPLIERS[Result.FSize];
end;

function TMathOptions.HavingCrampedStyle: TMathOptions;
begin
  Result := HavingStyle(FStyle.Cramp);
end;

function TMathOptions.HavingSize(const ASize: Integer): TMathOptions;
begin
  if (FSize = ASize) and (FTextSize = ASize) then
    Exit(Self);

  Result := Clone;

  Result.FStyle := FStyle.TextStyle;
  Result.FSize := ASize;
  Result.FTextSize := ASize;
  Result.FSizeMultiplier := SIZE_MULTIPLIERS[ASize];
end;

function TMathOptions.HavingBaseStyle(const AStyle: TMathStyle): TMathOptions;
begin
  var LWantSize := SizeAtStyle(BASE_SIZE, AStyle);

  if (FSize = LWantSize) and (FTextSize = BASE_SIZE) and (FStyle = AStyle) then
    Exit(Self);

  Result := Clone;

  Result.FStyle := AStyle;
  Result.FSize := LWantSize;
  Result.FSizeMultiplier := SIZE_MULTIPLIERS[LWantSize];
end;

function TMathOptions.HavingBaseStyle: TMathOptions;
begin
  Result := HavingBaseStyle(FStyle.TextStyle);
end;

function TMathOptions.HavingBaseSizing: TMathOptions;
begin
  Result := Clone;

  Result.FStyle := FStyle.TextStyle;

  case FStyle.Id of
    4, 5: Result.FSize := 3;
    6, 7: Result.FSize := 1;
  else
    Result.FSize := 6;
  end;

  Result.FSizeMultiplier := SIZE_MULTIPLIERS[Result.FSize];
end;

function TMathOptions.BaseSizingMultiplier: Double;
begin
  Result := SIZE_MULTIPLIERS[BASE_SIZE] / FSizeMultiplier;
end;

function TMathOptions.WithColor(const AColor: TMathColor): TMathOptions;
begin
  Result := Clone;

  Result.FColor := AColor;
end;

function TMathOptions.WithPhantom: TMathOptions;
begin
  Result := Clone;

  Result.FPhantom := True;
end;

function TMathOptions.WithFont(const AFont: string): TMathOptions;
begin
  Result := Clone;

  Result.FFont := AFont;
end;

function TMathOptions.WithTextFontFamily(const AFontFamily: string): TMathOptions;
begin
  Result := Clone;

  Result.FFontFamily := AFontFamily;
  Result.FFont := '';
end;

function TMathOptions.WithTextFontWeight(const AFontWeight: string): TMathOptions;
begin
  Result := Clone;

  Result.FFontWeight := AFontWeight;
  Result.FFont := '';
end;

function TMathOptions.WithTextFontShape(const AFontShape: string): TMathOptions;
begin
  Result := Clone;

  Result.FFontShape := AFontShape;
  Result.FFont := '';
end;

function TMathOptions.FontMetrics: PMathGlobalMetrics;
begin
  Result := GetGlobalMetrics(FSize);
end;

function TMathOptions.GetColor: TMathColor;
begin
  Result := if FPhantom then TMathColor.Transparent else FColor;
end;

{ Units }

function MeasurementFromMu(const AMu: Double): TMathMeasurement;
begin
  Result := TMathMeasurement.Create(AMu, 'mu');
end;

function CalculateSize(const AMeasurement: TMathMeasurement; const AOptions: TMathOptions): Double;
var
  LScale: Double;
begin
  for var LIndex := Low(UNIT_PT) to High(UNIT_PT) do
  if UNIT_PT[LIndex] = AMeasurement.MeasurementUnit then
  begin
    LScale := UNIT_PT_VALUE[LIndex] / AOptions.FontMetrics.PtPerEm / AOptions.SizeMultiplier;

    Exit(Min(AMeasurement.Number * LScale, AOptions.MaxSize));
  end;

  if AMeasurement.MeasurementUnit = 'mu' then
    LScale := AOptions.FontMetrics.CssEmPerMu
  else
  begin
    var LUnitOptions := if AOptions.Style.IsTight then AOptions.HavingStyle(AOptions.Style.TextStyle) else AOptions;

    if AMeasurement.MeasurementUnit = 'ex' then
      LScale := LUnitOptions.FontMetrics.XHeight
    else
    if AMeasurement.MeasurementUnit = 'em' then
      LScale := LUnitOptions.FontMetrics.Quad
    else
      raise ParseMathError('Invalid unit: ''' + AMeasurement.MeasurementUnit + '''');

    if LUnitOptions <> AOptions then
      LScale := LScale * LUnitOptions.SizeMultiplier / AOptions.SizeMultiplier;
  end;

  Result := Min(AMeasurement.Number * LScale, AOptions.MaxSize);
end;

end.
