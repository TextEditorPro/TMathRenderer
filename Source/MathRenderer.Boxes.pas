unit MathRenderer.Boxes;

interface

uses
  System.Generics.Collections, MathRenderer.Types;

type
  TMathBox = class;
  TMathBoxList = TList<TMathBox>;

  TMathBoxFlag = (bfCdLabel, bfDelimiterPiece, bfNewLine, bfSpace, bfTag);
  TMathBoxFlags = set of TMathBoxFlag;

  TMathBox = class(TObject)
  strict private
    FClasses: TArray<string>;
    FDepth: Double;
    FFixedWidth: Double;
    FFlags: TMathBoxFlags;
    FHasFixedWidth: Boolean;
    FHeight: Double;
    FItalic: Double;
    FMarginLeft: Double;
    FMarginRight: Double;
    FMarginTop: Double;
    FMiddleDelimiter: string;
    FMiddleOptions: TObject;
    FPaddingLeft: Double;
    FPaddingRight: Double;
    FScale: Double;
    FShiftX: Double;
    FShiftY: Double;
    FSkew: Double;
    FStretchWidth: Boolean;
    FWidth: Double;
  public
    constructor Create(const AClasses: array of string);
    function Advance: Double;
    function ClassCount: Integer;
    function ClassText: string;
    function FirstClass: string;
    function HasClass(const AClassName: string): Boolean;
    function IsMiddle: Boolean;
    procedure AddClass(const AClassName: string);
    procedure ApplySizing(const AMultiplier: Double);
    procedure Measure; virtual;
    procedure SetFirstClass(const AClassName: string);
    procedure SetFixedWidth(const AWidth: Double);
    property Depth: Double read FDepth write FDepth;
    property FixedWidth: Double read FFixedWidth;
    property Flags: TMathBoxFlags read FFlags write FFlags;
    property HasFixedWidth: Boolean read FHasFixedWidth;
    property Height: Double read FHeight write FHeight;
    property Italic: Double read FItalic write FItalic;
    property MarginLeft: Double read FMarginLeft write FMarginLeft;
    property MarginRight: Double read FMarginRight write FMarginRight;
    property MarginTop: Double read FMarginTop write FMarginTop;
    property MiddleDelimiter: string read FMiddleDelimiter write FMiddleDelimiter;
    property MiddleOptions: TObject read FMiddleOptions write FMiddleOptions;
    property PaddingLeft: Double read FPaddingLeft write FPaddingLeft;
    property PaddingRight: Double read FPaddingRight write FPaddingRight;
    property Scale: Double read FScale write FScale;
    property ShiftX: Double read FShiftX write FShiftX;
    property ShiftY: Double read FShiftY write FShiftY;
    property Skew: Double read FSkew write FSkew;
    property StretchWidth: Boolean read FStretchWidth write FStretchWidth;
    property Width: Double read FWidth write FWidth;
  end;

  TMathSymbolBox = class(TMathBox)
  strict private
    FAdvances: TArray<Double>;
    FColor: TMathColor;
    FFont: TMathFont;
    FMaxFontSize: Double;
    FText: string;
  public
    procedure Append(const ABox: TMathSymbolBox);
    procedure Measure; override;
    property Advances: TArray<Double> read FAdvances write FAdvances;
    property Color: TMathColor read FColor write FColor;
    property Font: TMathFont read FFont write FFont;
    property MaxFontSize: Double read FMaxFontSize write FMaxFontSize;
    property Text: string read FText write FText;
  end;

  TMathSpanBox = class(TMathBox)
  strict private
    FChildren: TMathBoxList;
    FIsFragment: Boolean;
    FLapAlignment: TMathLapAlignment;
    FMirrored: Boolean;
    FShadowOffsetX: Double;
    FShadowOffsetY: Double;
  public
    constructor Create(const AClasses: array of string);
    destructor Destroy; override;
    function ContentWidth: Double;
    function HasShadow: Boolean;
    procedure Measure; override;
    procedure SizeFromChildren;
    property Children: TMathBoxList read FChildren;
    property IsFragment: Boolean read FIsFragment write FIsFragment;
    property LapAlignment: TMathLapAlignment read FLapAlignment write FLapAlignment;
    property Mirrored: Boolean read FMirrored write FMirrored;
    property ShadowOffsetX: Double read FShadowOffsetX write FShadowOffsetX;
    property ShadowOffsetY: Double read FShadowOffsetY write FShadowOffsetY;
  end;

  TMathVListItem = record
    Baseline: Double;
    Element: TMathBox;
    MarginLeft: Double;
    MarginRight: Double;
  end;

  TMathVListAlignment = (vaLeft, vaCenter, vaRight);

  TMathVListBox = class(TMathBox)
  strict private
    FAlignment: TMathVListAlignment;
    FItems: TList<TMathVListItem>;
  public
    constructor Create(const AClasses: array of string);
    destructor Destroy; override;
    procedure Measure; override;
    property Alignment: TMathVListAlignment read FAlignment write FAlignment;
    property Items: TList<TMathVListItem> read FItems;
  end;

  TMathRuleBox = class(TMathBox)
  strict private
    FColor: TMathColor;
    FDashed: Boolean;
    FDrawDepth: Double;
    FDrawHeight: Double;
    FHasDrawExtent: Boolean;
  public
    procedure Measure; override;
    procedure SetDrawExtent(const AHeight: Double; const ADepth: Double);
    property Color: TMathColor read FColor write FColor;
    property Dashed: Boolean read FDashed write FDashed;
    property DrawDepth: Double read FDrawDepth;
    property DrawHeight: Double read FDrawHeight;
    property HasDrawExtent: Boolean read FHasDrawExtent;
  end;

  TMathSvgAlign = (saMin, saMid, saMax);

  TMathSvgRegion = (srFull, srLeftHalf, srRightHalf, srBraceLeft, srBraceCenter, srBraceRight);

  TMathSvgPart = record
    Align: TMathSvgAlign;
    PathData: string;
    Region: TMathSvgRegion;
  end;

  TMathSvgBox = class(TMathBox)
  strict private
    FColor: TMathColor;
    FMinWidth: Double;
    FParts: TArray<TMathSvgPart>;
    FStretch: Boolean;
    FViewBoxHeight: Double;
    FViewBoxWidth: Double;
  public
    procedure AddPart(const APathData: string; const AAlign: TMathSvgAlign; const ARegion: TMathSvgRegion);
    procedure Measure; override;
    property Color: TMathColor read FColor write FColor;
    property MinWidth: Double read FMinWidth write FMinWidth;
    property Parts: TArray<TMathSvgPart> read FParts;
    property Stretch: Boolean read FStretch write FStretch;
    property ViewBoxHeight: Double read FViewBoxHeight write FViewBoxHeight;
    property ViewBoxWidth: Double read FViewBoxWidth write FViewBoxWidth;
  end;

  TMathCancelLine = (clForward, clBackward);
  TMathCancelLines = set of TMathCancelLine;

  TMathFrameBox = class(TMathBox)
  strict private
    FBackgroundColor: TMathColor;
    FBorderBottom: Double;
    FBorderColor: TMathColor;
    FBorderLeft: Double;
    FBorderRight: Double;
    FBorderTop: Double;
    FCancelLines: TMathCancelLines;
    FLineWidth: Double;
  public
    procedure Measure; override;
    procedure SetBorder(const AWidth: Double);
    property BackgroundColor: TMathColor read FBackgroundColor write FBackgroundColor;
    property BorderBottom: Double read FBorderBottom write FBorderBottom;
    property BorderColor: TMathColor read FBorderColor write FBorderColor;
    property BorderLeft: Double read FBorderLeft write FBorderLeft;
    property BorderRight: Double read FBorderRight write FBorderRight;
    property BorderTop: Double read FBorderTop write FBorderTop;
    property CancelLines: TMathCancelLines read FCancelLines write FCancelLines;
    property LineWidth: Double read FLineWidth write FLineWidth;
  end;

  TMathRepeatBox = class(TMathBox)
  strict private
    FColor: TMathColor;
    FFont: TMathFont;
    FGlyphDepth: Double;
    FGlyphHeight: Double;
    FGlyphWidth: Double;
    FText: string;
  public
    procedure Measure; override;
    property Color: TMathColor read FColor write FColor;
    property Font: TMathFont read FFont write FFont;
    property GlyphDepth: Double read FGlyphDepth write FGlyphDepth;
    property GlyphHeight: Double read FGlyphHeight write FGlyphHeight;
    property GlyphWidth: Double read FGlyphWidth write FGlyphWidth;
    property Text: string read FText write FText;
  end;

  TMathSurdBox = class(TMathBox)
  strict private
    FColor: TMathColor;
    FMinWidth: Double;
    FSurd: TMathBox;
    FSurdBaseline: Double;
    FSurdScale: Double;
    FVinculumStart: Double;
    FVinculumThickness: Double;
  public
    procedure Measure; override;
    property Color: TMathColor read FColor write FColor;
    property MinWidth: Double read FMinWidth write FMinWidth;
    property Surd: TMathBox read FSurd write FSurd;
    property SurdBaseline: Double read FSurdBaseline write FSurdBaseline;
    property SurdScale: Double read FSurdScale write FSurdScale;
    property VinculumStart: Double read FVinculumStart write FVinculumStart;
    property VinculumThickness: Double read FVinculumThickness write FVinculumThickness;
  end;

implementation

uses
  System.Math, System.SysUtils;

{ TMathBox }

constructor TMathBox.Create(const AClasses: array of string);
begin
  inherited Create;

  SetLength(FClasses, Length(AClasses));

  for var LIndex := Low(AClasses) to High(AClasses) do
    FClasses[LIndex] := AClasses[LIndex];

  FScale := 1;
end;

function TMathBox.Advance: Double;
begin
  Result := FScale * (FMarginLeft + FPaddingLeft + FWidth + FPaddingRight + FMarginRight);
end;

function TMathBox.ClassCount: Integer;
begin
  Result := Length(FClasses);
end;

function TMathBox.ClassText: string;
begin
  Result := '';

  for var LIndex := 0 to High(FClasses) do
  if not FClasses[LIndex].IsEmpty then
  begin
    if not Result.IsEmpty then
      Result := Result + ' ';

    Result := Result + FClasses[LIndex];
  end;
end;

function TMathBox.FirstClass: string;
begin
  Result := if Length(FClasses) > 0 then FClasses[0] else '';
end;

function TMathBox.HasClass(const AClassName: string): Boolean;
begin
  for var LIndex := 0 to High(FClasses) do
  if FClasses[LIndex] = AClassName then
    Exit(True);

  Result := False;
end;

function TMathBox.IsMiddle: Boolean;
begin
  Result := not FMiddleDelimiter.IsEmpty;
end;

procedure TMathBox.AddClass(const AClassName: string);
begin
  FClasses := FClasses + [AClassName];
end;

procedure TMathBox.ApplySizing(const AMultiplier: Double);
begin
  FScale := FScale * AMultiplier;
  FHeight := FHeight * AMultiplier;
  FDepth := FDepth * AMultiplier;
end;

procedure TMathBox.Measure;
begin
  if FHasFixedWidth then
    FWidth := FFixedWidth;
end;

procedure TMathBox.SetFirstClass(const AClassName: string);
begin
  if Length(FClasses) > 0 then
    FClasses[0] := AClassName
  else
    FClasses := [AClassName];
end;

procedure TMathBox.SetFixedWidth(const AWidth: Double);
begin
  FFixedWidth := AWidth;
  FHasFixedWidth := True;
end;

{ TMathSymbolBox }

procedure TMathSymbolBox.Append(const ABox: TMathSymbolBox);
begin
  FText := FText + ABox.Text;
  FAdvances := FAdvances + ABox.Advances;
end;

procedure TMathSymbolBox.Measure;
begin
  Width := 0;

  for var LIndex := 0 to High(FAdvances) do
    Width := Width + FAdvances[LIndex];

  MarginRight := if Italic > 0 then Italic else 0;
end;

{ TMathSpanBox }

constructor TMathSpanBox.Create(const AClasses: array of string);
begin
  inherited Create(AClasses);

  FChildren := TMathBoxList.Create;
end;

destructor TMathSpanBox.Destroy;
begin
  FChildren.Free;

  inherited Destroy;
end;

function TMathSpanBox.ContentWidth: Double;
begin
  Result := 0;

  for var LIndex := 0 to FChildren.Count - 1 do
    Result := Result + FChildren[LIndex].Advance;
end;

function TMathSpanBox.HasShadow: Boolean;
begin
  Result := (FShadowOffsetX <> 0) or (FShadowOffsetY <> 0);
end;

procedure TMathSpanBox.Measure;
begin
  for var LIndex := 0 to FChildren.Count - 1 do
    FChildren[LIndex].Measure;


  Width := if HasFixedWidth then FixedWidth else ContentWidth;
end;

procedure TMathSpanBox.SizeFromChildren;
var
  LHeight: Double;
  LDepth: Double;
begin
  LHeight := 0;
  LDepth := 0;

  for var LIndex := 0 to FChildren.Count - 1 do
  begin
    LHeight := Max(LHeight, FChildren[LIndex].Height);
    LDepth := Max(LDepth, FChildren[LIndex].Depth);
  end;

  Height := LHeight;
  Depth := LDepth;
end;

{ TMathVListBox }

constructor TMathVListBox.Create(const AClasses: array of string);
begin
  inherited Create(AClasses);

  FItems := TList<TMathVListItem>.Create;
end;

destructor TMathVListBox.Destroy;
begin
  FItems.Free;

  inherited Destroy;
end;

procedure TMathVListBox.Measure;
var
  LItem: TMathVListItem;
  LElementWidth: Double;
begin
  Width := 0;

  for var LIndex := 0 to FItems.Count - 1 do
  begin
    LItem := FItems[LIndex];
    LItem.Element.Measure;
    LElementWidth := if LItem.Element.StretchWidth then 0 else LItem.Element.Advance;

    if LItem.Element is TMathSurdBox then
      LElementWidth := TMathSurdBox(LItem.Element).MinWidth * LItem.Element.Scale
    else
    if (LItem.Element is TMathSvgBox) and LItem.Element.StretchWidth then
      LElementWidth := TMathSvgBox(LItem.Element).MinWidth * LItem.Element.Scale;

    Width := Max(Width, LItem.MarginLeft + LElementWidth + LItem.MarginRight);
  end;
end;

{ TMathRuleBox }

procedure TMathRuleBox.Measure;
begin
  Width := if HasFixedWidth then FixedWidth else 0;
end;

procedure TMathRuleBox.SetDrawExtent(const AHeight: Double; const ADepth: Double);
begin
  FDrawHeight := AHeight;
  FDrawDepth := ADepth;
  FHasDrawExtent := True;
end;

{ TMathSvgBox }

procedure TMathSvgBox.AddPart(const APathData: string; const AAlign: TMathSvgAlign; const ARegion: TMathSvgRegion);
var
  LPart: TMathSvgPart;
begin
  LPart.PathData := APathData;
  LPart.Align := AAlign;
  LPart.Region := ARegion;
  FParts := FParts + [LPart];
end;

procedure TMathSvgBox.Measure;
begin
  Width := if HasFixedWidth then FixedWidth else 0;
end;

{ TMathFrameBox }

procedure TMathFrameBox.Measure;
begin
  Width := 0;
end;

procedure TMathFrameBox.SetBorder(const AWidth: Double);
begin
  FBorderTop := AWidth;
  FBorderRight := AWidth;
  FBorderBottom := AWidth;
  FBorderLeft := AWidth;
end;

{ TMathRepeatBox }

procedure TMathRepeatBox.Measure;
begin
  Width := FGlyphWidth;
end;

{ TMathSurdBox }

procedure TMathSurdBox.Measure;
begin
  FSurd.Measure;
  Width := FMinWidth;
end;

end.
