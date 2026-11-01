unit MathRenderer.Types;

interface

uses
  System.SysUtils;

type
  EMathParseError = class(Exception);

  TMathMode = (mmMath, mmText);

  TMathFont = (mfNone, mfAMSRegular, mfCaligraphicRegular, mfFrakturRegular, mfMainBold, mfMainBoldItalic, mfMainItalic, mfMainRegular,
    mfMathBoldItalic, mfMathItalic, mfSansSerifBold, mfSansSerifItalic, mfSansSerifRegular, mfScriptRegular, mfSize1Regular, mfSize2Regular,
    mfSize3Regular, mfSize4Regular, mfTypewriterRegular);

  TMathSymbolFont = (sfMain, sfAMS);

  TMathSymbolGroup = (sgAccentToken, sgBin, sgClose, sgInner, sgMathOrd, sgOpToken, sgOpen, sgPunct, sgRel, sgSpacing, sgTextOrd);

  TMathCharacterMetricsEntry = record
    CharCode: Integer;
    Depth: Double;
    Height: Double;
    Italic: Double;
    Skew: Double;
    Width: Double;
  end;

  TMathFontMetricsRange = record
    First: Integer;
    Count: Integer;
  end;

  TMathSymbolDefinition = record
    Name: string;
    Font: TMathSymbolFont;
    Group: TMathSymbolGroup;
    Replace: string;
  end;
  PMathSymbolDefinition = ^TMathSymbolDefinition;

  TMathUnicodeSymbol = record
    Name: string;
    Value: string;
  end;

  TMathUnicodeAccent = record
    Accent: string;
    TextCommand: string;
    MathCommand: string;
  end;

  TMathSvgPath = record
    Name: string;
    Data: string;
  end;

  TMathMeasurement = record
    Number: Double;
    MeasurementUnit: string;
    class function Create(const ANumber: Double; const AMeasurementUnit: string): TMathMeasurement; static;
  end;

  TMathLapAlignment = (laNone, laLeft, laRight, laCenter);

  TMathStyleName = (snNone, snDisplay, snText, snScript, snScriptScript);

  TMathColorKind = (ckDefault, ckTransparent, ckValue);

  TMathColor = record
    Kind: TMathColorKind;
    Value: Cardinal;
    class function Default: TMathColor; static;
    class function Transparent: TMathColor; static;
    function IsEqual(const AColor: TMathColor): Boolean;
  end;

const
  MATH_CLASS_ORD = 'mord';
  MATH_CLASS_OP = 'mop';
  MATH_CLASS_BIN = 'mbin';
  MATH_CLASS_REL = 'mrel';
  MATH_CLASS_OPEN = 'mopen';
  MATH_CLASS_CLOSE = 'mclose';
  MATH_CLASS_PUNCT = 'mpunct';
  MATH_CLASS_INNER = 'minner';

  STYLE_NAMES: array [TMathStyleName] of string = ('', 'display', 'text', 'script', 'scriptscript');

function IsMathClass(const AClassName: string): Boolean;
function TryParseMathColor(const AText: string; out AColor: TMathColor): Boolean;

implementation

type
  TMathNamedColor = record
    Name: string;
    Value: Cardinal;
  end;

const
  NAMED_COLORS: array [0..147] of TMathNamedColor = (
    (Name: 'aliceblue'; Value: $F0F8FF), (Name: 'antiquewhite'; Value: $FAEBD7), (Name: 'aqua'; Value: $00FFFF),
    (Name: 'aquamarine'; Value: $7FFFD4), (Name: 'azure'; Value: $F0FFFF), (Name: 'beige'; Value: $F5F5DC),
    (Name: 'bisque'; Value: $FFE4C4), (Name: 'black'; Value: $000000), (Name: 'blanchedalmond'; Value: $FFEBCD),
    (Name: 'blue'; Value: $0000FF), (Name: 'blueviolet'; Value: $8A2BE2), (Name: 'brown'; Value: $A52A2A),
    (Name: 'burlywood'; Value: $DEB887), (Name: 'cadetblue'; Value: $5F9EA0), (Name: 'chartreuse'; Value: $7FFF00),
    (Name: 'chocolate'; Value: $D2691E), (Name: 'coral'; Value: $FF7F50), (Name: 'cornflowerblue'; Value: $6495ED),
    (Name: 'cornsilk'; Value: $FFF8DC), (Name: 'crimson'; Value: $DC143C), (Name: 'cyan'; Value: $00FFFF),
    (Name: 'darkblue'; Value: $00008B), (Name: 'darkcyan'; Value: $008B8B), (Name: 'darkgoldenrod'; Value: $B8860B),
    (Name: 'darkgray'; Value: $A9A9A9), (Name: 'darkgreen'; Value: $006400), (Name: 'darkgrey'; Value: $A9A9A9),
    (Name: 'darkkhaki'; Value: $BDB76B), (Name: 'darkmagenta'; Value: $8B008B), (Name: 'darkolivegreen'; Value: $556B2F),
    (Name: 'darkorange'; Value: $FF8C00), (Name: 'darkorchid'; Value: $9932CC), (Name: 'darkred'; Value: $8B0000),
    (Name: 'darksalmon'; Value: $E9967A), (Name: 'darkseagreen'; Value: $8FBC8F), (Name: 'darkslateblue'; Value: $483D8B),
    (Name: 'darkslategray'; Value: $2F4F4F), (Name: 'darkslategrey'; Value: $2F4F4F), (Name: 'darkturquoise'; Value: $00CED1),
    (Name: 'darkviolet'; Value: $9400D3), (Name: 'deeppink'; Value: $FF1493), (Name: 'deepskyblue'; Value: $00BFFF),
    (Name: 'dimgray'; Value: $696969), (Name: 'dimgrey'; Value: $696969), (Name: 'dodgerblue'; Value: $1E90FF),
    (Name: 'firebrick'; Value: $B22222), (Name: 'floralwhite'; Value: $FFFAF0), (Name: 'forestgreen'; Value: $228B22),
    (Name: 'fuchsia'; Value: $FF00FF), (Name: 'gainsboro'; Value: $DCDCDC), (Name: 'ghostwhite'; Value: $F8F8FF),
    (Name: 'gold'; Value: $FFD700), (Name: 'goldenrod'; Value: $DAA520), (Name: 'gray'; Value: $808080),
    (Name: 'green'; Value: $008000), (Name: 'greenyellow'; Value: $ADFF2F), (Name: 'grey'; Value: $808080),
    (Name: 'honeydew'; Value: $F0FFF0), (Name: 'hotpink'; Value: $FF69B4), (Name: 'indianred'; Value: $CD5C5C),
    (Name: 'indigo'; Value: $4B0082), (Name: 'ivory'; Value: $FFFFF0), (Name: 'khaki'; Value: $F0E68C),
    (Name: 'lavender'; Value: $E6E6FA), (Name: 'lavenderblush'; Value: $FFF0F5), (Name: 'lawngreen'; Value: $7CFC00),
    (Name: 'lemonchiffon'; Value: $FFFACD), (Name: 'lightblue'; Value: $ADD8E6), (Name: 'lightcoral'; Value: $F08080),
    (Name: 'lightcyan'; Value: $E0FFFF), (Name: 'lightgoldenrodyellow'; Value: $FAFAD2), (Name: 'lightgray'; Value: $D3D3D3),
    (Name: 'lightgreen'; Value: $90EE90), (Name: 'lightgrey'; Value: $D3D3D3), (Name: 'lightpink'; Value: $FFB6C1),
    (Name: 'lightsalmon'; Value: $FFA07A), (Name: 'lightseagreen'; Value: $20B2AA), (Name: 'lightskyblue'; Value: $87CEFA),
    (Name: 'lightslategray'; Value: $778899), (Name: 'lightslategrey'; Value: $778899), (Name: 'lightsteelblue'; Value: $B0C4DE),
    (Name: 'lightyellow'; Value: $FFFFE0), (Name: 'lime'; Value: $00FF00), (Name: 'limegreen'; Value: $32CD32),
    (Name: 'linen'; Value: $FAF0E6), (Name: 'magenta'; Value: $FF00FF), (Name: 'maroon'; Value: $800000),
    (Name: 'mediumaquamarine'; Value: $66CDAA), (Name: 'mediumblue'; Value: $0000CD), (Name: 'mediumorchid'; Value: $BA55D3),
    (Name: 'mediumpurple'; Value: $9370DB), (Name: 'mediumseagreen'; Value: $3CB371), (Name: 'mediumslateblue'; Value: $7B68EE),
    (Name: 'mediumspringgreen'; Value: $00FA9A), (Name: 'mediumturquoise'; Value: $48D1CC), (Name: 'mediumvioletred'; Value: $C71585),
    (Name: 'midnightblue'; Value: $191970), (Name: 'mintcream'; Value: $F5FFFA), (Name: 'mistyrose'; Value: $FFE4E1),
    (Name: 'moccasin'; Value: $FFE4B5), (Name: 'navajowhite'; Value: $FFDEAD), (Name: 'navy'; Value: $000080),
    (Name: 'oldlace'; Value: $FDF5E6), (Name: 'olive'; Value: $808000), (Name: 'olivedrab'; Value: $6B8E23),
    (Name: 'orange'; Value: $FFA500), (Name: 'orangered'; Value: $FF4500), (Name: 'orchid'; Value: $DA70D6),
    (Name: 'palegoldenrod'; Value: $EEE8AA), (Name: 'palegreen'; Value: $98FB98), (Name: 'paleturquoise'; Value: $AFEEEE),
    (Name: 'palevioletred'; Value: $DB7093), (Name: 'papayawhip'; Value: $FFEFD5), (Name: 'peachpuff'; Value: $FFDAB9),
    (Name: 'peru'; Value: $CD853F), (Name: 'pink'; Value: $FFC0CB), (Name: 'plum'; Value: $DDA0DD),
    (Name: 'powderblue'; Value: $B0E0E6), (Name: 'purple'; Value: $800080), (Name: 'rebeccapurple'; Value: $663399),
    (Name: 'red'; Value: $FF0000), (Name: 'rosybrown'; Value: $BC8F8F), (Name: 'royalblue'; Value: $4169E1),
    (Name: 'saddlebrown'; Value: $8B4513), (Name: 'salmon'; Value: $FA8072), (Name: 'sandybrown'; Value: $F4A460),
    (Name: 'seagreen'; Value: $2E8B57), (Name: 'seashell'; Value: $FFF5EE), (Name: 'sienna'; Value: $A0522D),
    (Name: 'silver'; Value: $C0C0C0), (Name: 'skyblue'; Value: $87CEEB), (Name: 'slateblue'; Value: $6A5ACD),
    (Name: 'slategray'; Value: $708090), (Name: 'slategrey'; Value: $708090), (Name: 'snow'; Value: $FFFAFA),
    (Name: 'springgreen'; Value: $00FF7F), (Name: 'steelblue'; Value: $4682B4), (Name: 'tan'; Value: $D2B48C),
    (Name: 'teal'; Value: $008080), (Name: 'thistle'; Value: $D8BFD8), (Name: 'tomato'; Value: $FF6347),
    (Name: 'turquoise'; Value: $40E0D0), (Name: 'violet'; Value: $EE82EE), (Name: 'wheat'; Value: $F5DEB3),
    (Name: 'white'; Value: $FFFFFF), (Name: 'whitesmoke'; Value: $F5F5F5), (Name: 'yellow'; Value: $FFFF00),
    (Name: 'yellowgreen'; Value: $9ACD32)
  );

class function TMathMeasurement.Create(const ANumber: Double; const AMeasurementUnit: string): TMathMeasurement;
begin
  Result.Number := ANumber;
  Result.MeasurementUnit := AMeasurementUnit;
end;

class function TMathColor.Default: TMathColor;
begin
  Result.Kind := ckDefault;
  Result.Value := 0;
end;

class function TMathColor.Transparent: TMathColor;
begin
  Result.Kind := ckTransparent;
  Result.Value := 0;
end;

function TMathColor.IsEqual(const AColor: TMathColor): Boolean;
begin
  Result := (Kind = AColor.Kind) and (Value = AColor.Value);
end;

function IsMathClass(const AClassName: string): Boolean;
begin
  Result := (AClassName = MATH_CLASS_ORD) or (AClassName = MATH_CLASS_OP) or (AClassName = MATH_CLASS_BIN) or
    (AClassName = MATH_CLASS_REL) or (AClassName = MATH_CLASS_OPEN) or (AClassName = MATH_CLASS_CLOSE) or
    (AClassName = MATH_CLASS_PUNCT) or (AClassName = MATH_CLASS_INNER);
end;

function TryHexToCardinal(const AText: string; out AValue: Cardinal): Boolean;
var
  LValue: Integer;
begin
  Result := TryStrToInt('$' + AText, LValue);

  if Result then
    AValue := Cardinal(LValue);
end;

function TryParseMathColor(const AText: string; out AColor: TMathColor): Boolean;
var
  LValue: Cardinal;
begin
  AColor := TMathColor.Default;

  var LLowerText := AText.ToLower;

  if LLowerText.StartsWith('#') then
  begin
    var LHex := LLowerText.Substring(1);

    if (LHex.Length = 3) or (LHex.Length = 4) then
      LHex := LHex[1] + LHex[1] + LHex[2] + LHex[2] + LHex[3] + LHex[3]
    else
    if LHex.Length = 8 then
      LHex := LHex.Substring(0, 6);

    if (LHex.Length <> 6) or not TryHexToCardinal(LHex, LValue) then
      Exit(False);

    AColor.Kind := ckValue;
    AColor.Value := LValue;

    Exit(True);
  end;

  for var LIndex := Low(NAMED_COLORS) to High(NAMED_COLORS) do
  if NAMED_COLORS[LIndex].Name = LLowerText then
  begin
    AColor.Kind := ckValue;
    AColor.Value := NAMED_COLORS[LIndex].Value;

    Exit(True);
  end;

  Result := False;
end;

end.
