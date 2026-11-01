unit MathRenderer.Painter;

interface

uses
  Winapi.GDIPOBJ, Winapi.Windows, System.SysUtils, System.Types, Vcl.Graphics, MathRenderer.Boxes, MathRenderer.Fonts, MathRenderer.Types;

type
  TMathRasterProcedure = reference to procedure(const AGraphics: TGPGraphics; const AOffsetX: Double; const AOffsetY: Double);

  TMathPainter = class(TObject)
  strict private
    FBounds: TRectF;
    FDC: HDC;
    FDefaultColor: TColor;
    FFonts: TMathFontCache;
    FGrayscaleFonts: TMathFontCache;
    FGrayscaleText: Boolean;
    FMirrorDepth: Integer;
    FMirrorOffset: Double;
    FMirrorScale: Double;
    FOriginX: Double;
    FOriginY: Double;
    FShadowOffsetX: Double;
    FShadowOffsetY: Double;
    FUnitsPerEm: Double;
    function ColorToRGB(const AColor: TMathColor; out ARGB: COLORREF): Boolean;
    function ToLogical(const AValue: Double): Integer; inline;
    function ToLogicalX(const AValue: Double): Integer; inline;
    function ToLogicalY(const AValue: Double): Integer; inline;
    function ToPixelX(const AValue: Double): Double; inline;
    function ToPixelY(const AValue: Double): Double; inline;
    procedure DrawDashedRectangle(const ALeft: Double; const ATop: Double; const ARight: Double; const ABottom: Double; const AColor: TMathColor);
    procedure DrawFrame(const ABox: TMathFrameBox; const AX: Double; const ABaseline: Double; const AScale: Double; const AOuterScale: Double; const AWidth: Double);
    procedure DrawRaster(const ALeft: Double; const ATop: Double; const ARight: Double; const ABottom: Double; const ADraw: TMathRasterProcedure);
    procedure DrawRepeat(const ABox: TMathRepeatBox; const AX: Double; const ABaseline: Double; const AScale: Double; const AOuterScale: Double);
    procedure DrawRule(const ABox: TMathRuleBox; const AX: Double; const ABaseline: Double; const AScale: Double; const AOuterScale: Double; const AContainerWidth: Double);
    procedure DrawSpan(const ABox: TMathSpanBox; const AX: Double; const ABaseline: Double; const AScale: Double);
    procedure DrawSurd(const ABox: TMathSurdBox; const AX: Double; const ABaseline: Double; const AScale: Double; const AContainerWidth: Double);
    procedure DrawSvg(const ABox: TMathSvgBox; const AX: Double; const ABaseline: Double; const AScale: Double; const AOuterScale: Double; const AWidth: Double);
    procedure DrawSymbol(const ABox: TMathSymbolBox; const AX: Double; const ABaseline: Double; const AScale: Double);
    procedure DrawText(const AText: string; const AFont: TMathFont; const AAdvances: TArray<Double>; const AX: Double; const ABaseline: Double;
      const AScale: Double; const AColor: COLORREF; const AFonts: TMathFontCache);
    procedure DrawVList(const ABox: TMathVListBox; const AX: Double; const ABaseline: Double; const AScale: Double);
    procedure FillRectangle(const ALeft: Double; const ATop: Double; const ARight: Double; const ABottom: Double; const AColor: TMathColor);
    procedure IncludeBounds(const ALeft: Double; const ATop: Double; const ARight: Double; const ABottom: Double);
  public
    constructor Create(const ADC: HDC; const AUnitsPerEm: Double; const AOriginX: Double; const AOriginY: Double; const ADefaultColor: TColor;
      const AFonts: TMathFontCache; const AGrayscaleFonts: TMathFontCache);
    procedure DrawBox(const ABox: TMathBox; const AX: Double; const ABaseline: Double; const AScale: Double; const AContainerWidth: Double = 0);
    property Bounds: TRectF read FBounds;
  end;

const
  UNITS_PER_PIXEL = 16;

procedure AddSvgPath(const APath: TGPGraphicsPath; const AData: string; const AScaleX: Double; const AScaleY: Double; const AOffsetX: Double; const AOffsetY: Double);

implementation

uses
  Winapi.GDIPAPI, System.Math;

{ SVG paths }

procedure AddSvgPath(const APath: TGPGraphicsPath; const AData: string; const AScaleX: Double; const AScaleY: Double; const AOffsetX: Double; const AOffsetY: Double);
var
  LIndex: Integer;
  LCurrentX: Double;
  LCurrentY: Double;
  LControlX: Double;
  LControlY: Double;
  LPreviousCommand: Char;
  LValues: array [0..5] of Double;

  function PointAt(const AX: Double; const AY: Double): TGPPointF;
  begin
    Result := MakePoint(Single(AOffsetX + AX * AScaleX), Single(AOffsetY + AY * AScaleY));
  end;

  procedure SkipSeparators;
  begin
    while (LIndex <= AData.Length) and CharInSet(AData[LIndex], [' ', ',', #9, #10, #13]) do
      Inc(LIndex);
  end;

  function HasNumber: Boolean;
  begin
    SkipSeparators;

    Result := (LIndex <= AData.Length) and CharInSet(AData[LIndex], ['0'..'9', '.', '-', '+']);
  end;

  function ReadNumber: Double;
  begin
    SkipSeparators;

    var LStart := LIndex;
    var LHasDot := False;

    if (LIndex <= AData.Length) and CharInSet(AData[LIndex], ['-', '+']) then
      Inc(LIndex);

    while LIndex <= AData.Length do
    begin
      if CharInSet(AData[LIndex], ['0'..'9']) then
        Inc(LIndex)
      else
      if (AData[LIndex] = '.') and not LHasDot then
      begin
        LHasDot := True;
        Inc(LIndex);
      end
      else
      if CharInSet(AData[LIndex], ['e', 'E']) then
      begin
        Inc(LIndex);

        if (LIndex <= AData.Length) and CharInSet(AData[LIndex], ['-', '+']) then
          Inc(LIndex);
      end
      else
        Break;
    end;

    Result := StrToFloat(Copy(AData, LStart, LIndex - LStart), TFormatSettings.Invariant);
  end;

  procedure ReadValues(const ACount: Integer);
  begin
    for var LValue := 0 to ACount - 1 do
      LValues[LValue] := ReadNumber;
  end;

  procedure AddCubic(const AX1: Double; const AY1: Double; const AX2: Double; const AY2: Double; const AX: Double; const AY: Double);
  begin
    APath.AddBezier(PointAt(LCurrentX, LCurrentY), PointAt(AX1, AY1), PointAt(AX2, AY2), PointAt(AX, AY));

    LControlX := AX2;
    LControlY := AY2;
    LCurrentX := AX;
    LCurrentY := AY;
  end;

  procedure AddQuadratic(const AX1: Double; const AY1: Double; const AX: Double; const AY: Double);
  begin
    APath.AddBezier(PointAt(LCurrentX, LCurrentY), PointAt(LCurrentX + 2 / 3 * (AX1 - LCurrentX),
      LCurrentY + 2 / 3 * (AY1 - LCurrentY)), PointAt(AX + 2 / 3 * (AX1 - AX), AY + 2 / 3 * (AY1 - AY)), PointAt(AX, AY));

    LControlX := AX1;
    LControlY := AY1;
    LCurrentX := AX;
    LCurrentY := AY;
  end;

  procedure AddLineTo(const AX: Double; const AY: Double);
  begin
    APath.AddLine(PointAt(LCurrentX, LCurrentY), PointAt(AX, AY));

    LCurrentX := AX;
    LCurrentY := AY;
  end;

  function ReflectedControlX(const ACommands: TSysCharSet): Double;
  begin
    Result := if CharInSet(LPreviousCommand, ACommands) then 2 * LCurrentX - LControlX else LCurrentX;
  end;

  function ReflectedControlY(const ACommands: TSysCharSet): Double;
  begin
    Result := if CharInSet(LPreviousCommand, ACommands) then 2 * LCurrentY - LControlY else LCurrentY;
  end;

begin
  APath.SetFillMode(FillModeWinding);

  LIndex := 1;
  LCurrentX := 0;
  LCurrentY := 0;
  LControlX := 0;
  LControlY := 0;
  LPreviousCommand := ' ';

  var LStartX: Double := 0;
  var LStartY: Double := 0;
  var LCommand: Char := ' ';
  var LRelative: Boolean;
  var LX1: Double;
  var LY1: Double;

  while True do
  begin
    SkipSeparators;

    if LIndex > AData.Length then
      Break;

    if CharInSet(AData[LIndex], ['A'..'Z', 'a'..'z']) then
    begin
      LCommand := AData[LIndex];
      Inc(LIndex);
    end
    else
    if CharInSet(LCommand, ['M', 'm']) then
      LCommand := if LCommand = 'M' then 'L' else 'l';

    LRelative := CharInSet(LCommand, ['a'..'z']);

    case UpCase(LCommand) of
      'M':
        begin
          ReadValues(2);

          if LRelative then
          begin
            LCurrentX := LCurrentX + LValues[0];
            LCurrentY := LCurrentY + LValues[1];
          end
          else
          begin
            LCurrentX := LValues[0];
            LCurrentY := LValues[1];
          end;

          APath.StartFigure;
          LStartX := LCurrentX;
          LStartY := LCurrentY;
        end;
      'L':
        begin
          ReadValues(2);

          if LRelative then
            AddLineTo(LCurrentX + LValues[0], LCurrentY + LValues[1])
          else
            AddLineTo(LValues[0], LValues[1]);
        end;
      'H':
        begin
          ReadValues(1);
          AddLineTo(if LRelative then LCurrentX + LValues[0] else LValues[0], LCurrentY);
        end;
      'V':
        begin
          ReadValues(1);
          AddLineTo(LCurrentX, if LRelative then LCurrentY + LValues[0] else LValues[0]);
        end;
      'C':
        begin
          ReadValues(6);

          if LRelative then
            AddCubic(LCurrentX + LValues[0], LCurrentY + LValues[1], LCurrentX + LValues[2], LCurrentY + LValues[3], LCurrentX + LValues[4], LCurrentY + LValues[5])
          else
            AddCubic(LValues[0], LValues[1], LValues[2], LValues[3], LValues[4], LValues[5]);
        end;
      'S':
        begin
          ReadValues(4);
          LX1 := ReflectedControlX(['C', 'c', 'S', 's']);
          LY1 := ReflectedControlY(['C', 'c', 'S', 's']);

          if LRelative then
            AddCubic(LX1, LY1, LCurrentX + LValues[0], LCurrentY + LValues[1], LCurrentX + LValues[2],
              LCurrentY + LValues[3])
          else
            AddCubic(LX1, LY1, LValues[0], LValues[1], LValues[2], LValues[3]);
        end;
      'Q':
        begin
          ReadValues(4);

          if LRelative then
            AddQuadratic(LCurrentX + LValues[0], LCurrentY + LValues[1], LCurrentX + LValues[2], LCurrentY + LValues[3])
          else
            AddQuadratic(LValues[0], LValues[1], LValues[2], LValues[3]);
        end;
      'T':
        begin
          ReadValues(2);
          LX1 := ReflectedControlX(['Q', 'q', 'T', 't']);
          LY1 := ReflectedControlY(['Q', 'q', 'T', 't']);

          if LRelative then
            AddQuadratic(LX1, LY1, LCurrentX + LValues[0], LCurrentY + LValues[1])
          else
            AddQuadratic(LX1, LY1, LValues[0], LValues[1]);
        end;
      'Z':
        begin
          APath.CloseFigure;
          LCurrentX := LStartX;
          LCurrentY := LStartY;
        end;
    else
      raise EMathParseError.Create('Unsupported SVG path command ' + LCommand);
    end;

    LPreviousCommand := LCommand;

    if UpCase(LCommand) = 'Z' then
      LCommand := ' '
    else
    if not HasNumber then
      LCommand := ' ';
  end;
end;

{ TMathPainter }

constructor TMathPainter.Create(const ADC: HDC; const AUnitsPerEm: Double; const AOriginX: Double; const AOriginY: Double;
  const ADefaultColor: TColor; const AFonts: TMathFontCache; const AGrayscaleFonts: TMathFontCache);
begin
  inherited Create;

  FDC := ADC;
  FUnitsPerEm := AUnitsPerEm;
  FOriginX := AOriginX;
  FOriginY := AOriginY;
  FDefaultColor := ADefaultColor;
  FFonts := AFonts;
  FGrayscaleFonts := AGrayscaleFonts;
  FMirrorScale := 1;
end;

function TMathPainter.ToLogical(const AValue: Double): Integer;
begin
  Result := Round(AValue * FUnitsPerEm);
end;

function TMathPainter.ToLogicalX(const AValue: Double): Integer;
begin
  Result := Round(FOriginX + AValue * FUnitsPerEm);
end;

function TMathPainter.ToLogicalY(const AValue: Double): Integer;
begin
  Result := Round(FOriginY + AValue * FUnitsPerEm);
end;

function TMathPainter.ToPixelX(const AValue: Double): Double;
begin
  Result := (FOriginX + AValue * FUnitsPerEm) / UNITS_PER_PIXEL;
end;

function TMathPainter.ToPixelY(const AValue: Double): Double;
begin
  Result := (FOriginY + AValue * FUnitsPerEm) / UNITS_PER_PIXEL;
end;

function TMathPainter.ColorToRGB(const AColor: TMathColor; out ARGB: COLORREF): Boolean;
begin
  case AColor.Kind of
    ckTransparent:
      Exit(False);
    ckValue:
      ARGB := RGB((AColor.Value shr 16) and $FF, (AColor.Value shr 8) and $FF, AColor.Value and $FF);
  else
    ARGB := Vcl.Graphics.ColorToRGB(FDefaultColor);
  end;

  Result := True;
end;

procedure TMathPainter.IncludeBounds(const ALeft: Double; const ATop: Double; const ARight: Double; const ABottom: Double);
begin
  var LLeft: Double := FMirrorScale * ALeft + FMirrorOffset;
  var LRight: Double := FMirrorScale * ARight + FMirrorOffset;

  FBounds.Left := Min(FBounds.Left, Min(LLeft, LRight));
  FBounds.Top := Min(FBounds.Top, ATop);
  FBounds.Right := Max(FBounds.Right, Max(LLeft, LRight));
  FBounds.Bottom := Max(FBounds.Bottom, ABottom);
end;

procedure TMathPainter.FillRectangle(const ALeft: Double; const ATop: Double; const ARight: Double; const ABottom: Double;
  const AColor: TMathColor);
var
  LRGB: COLORREF;
  LRect: TRect;
  LBrush: HBRUSH;
begin
  if (FDC = 0) or not ColorToRGB(AColor, LRGB) then
    Exit;

  LRect.Left := Round(ToLogicalX(ALeft) / UNITS_PER_PIXEL) * UNITS_PER_PIXEL;
  LRect.Right := Max(LRect.Left + UNITS_PER_PIXEL, Round(ToLogicalX(ARight) / UNITS_PER_PIXEL) * UNITS_PER_PIXEL);
  LRect.Top := Round(ToLogicalY(ATop) / UNITS_PER_PIXEL) * UNITS_PER_PIXEL;
  LRect.Bottom := Max(LRect.Top + UNITS_PER_PIXEL, Round(ToLogicalY(ABottom) / UNITS_PER_PIXEL) * UNITS_PER_PIXEL);

  if ARight <= ALeft then
    Exit;

  LBrush := CreateSolidBrush(LRGB);
  try
    Winapi.Windows.FillRect(FDC, LRect, LBrush);
  finally
    DeleteObject(LBrush);
  end;
end;

procedure TMathPainter.DrawDashedRectangle(const ALeft: Double; const ATop: Double; const ARight: Double; const ABottom: Double; const AColor: TMathColor);
begin
  var LVertical := (ABottom - ATop) > (ARight - ALeft);
  var LLength: Double := if LVertical then ABottom - ATop else ARight - ALeft;
  var LThickness: Double := if LVertical then ARight - ALeft else ABottom - ATop;
  var LDash: Double := Max(3 * LThickness, 3 * UNITS_PER_PIXEL / FUnitsPerEm);
  var LPosition: Double := 0;

  while LPosition < LLength do
  begin
    if LVertical then
      FillRectangle(ALeft, ATop + LPosition, ARight, ATop + Min(LLength, LPosition + LDash), AColor)
    else
      FillRectangle(ALeft + LPosition, ATop, ALeft + Min(LLength, LPosition + LDash), ABottom, AColor);

    LPosition := LPosition + 2 * LDash;
  end;
end;

procedure TMathPainter.DrawRaster(const ALeft: Double; const ATop: Double; const ARight: Double; const ABottom: Double; const ADraw: TMathRasterProcedure);
begin
  if FDC = 0 then
    Exit;

  var LLeft: Double := Min(FMirrorScale * ALeft + FMirrorOffset, FMirrorScale * ARight + FMirrorOffset);
  var LRight: Double := Max(FMirrorScale * ALeft + FMirrorOffset, FMirrorScale * ARight + FMirrorOffset);
  var LLeftPixel := Floor(ToPixelX(LLeft)) - 1;
  var LTopPixel := Floor(ToPixelY(ATop)) - 1;
  var LWidth := Ceil(ToPixelX(LRight)) + 1 - LLeftPixel;
  var LHeight := Ceil(ToPixelY(ABottom)) + 1 - LTopPixel;

  if (LWidth <= 0) or (LHeight <= 0) then
    Exit;

  var LBitmap := TGPBitmap.Create(LWidth, LHeight, PixelFormat32bppPARGB);
  try
    var LGraphics := TGPGraphics.Create(LBitmap);
    try
      LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
      LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
      LGraphics.Clear(MakeColor(0, 0, 0, 0));

      if FMirrorDepth > 0 then
      begin
        var LMatrix := TGPMatrix.Create(FMirrorScale, 0, 0, 1, FOriginX / UNITS_PER_PIXEL * (1 - FMirrorScale) +
          FMirrorOffset * FUnitsPerEm / UNITS_PER_PIXEL + LLeftPixel * (FMirrorScale - 1), 0);
        try
          LGraphics.SetTransform(LMatrix);
        finally
          LMatrix.Free;
        end;
      end;

      ADraw(LGraphics, -LLeftPixel, -LTopPixel);
    finally
      LGraphics.Free;
    end;

    var LInfo: TBitmapInfo;

    FillChar(LInfo, SizeOf(LInfo), 0);
    LInfo.bmiHeader.biSize := SizeOf(LInfo.bmiHeader);
    LInfo.bmiHeader.biWidth := LWidth;
    LInfo.bmiHeader.biHeight := -LHeight;
    LInfo.bmiHeader.biPlanes := 1;
    LInfo.bmiHeader.biBitCount := 32;

    var LBits: Pointer;

    var LDib: HBITMAP := CreateDIBSection(0, LInfo, DIB_RGB_COLORS, LBits, 0, 0);

    if LDib = 0 then
      Exit;


    var LData: TBitmapData;

    var LMemoryDC: HDC := CreateCompatibleDC(0);
    try
      LBitmap.LockBits(MakeRect(0, 0, LWidth, LHeight), ImageLockModeRead, PixelFormat32bppPARGB, LData);
      try
        for var LRow := 0 to LHeight - 1 do
          Move(PByte(LData.Scan0)[LRow * LData.Stride], PByte(LBits)[LRow * LWidth * 4], LWidth * 4);
      finally
        LBitmap.UnlockBits(LData);
      end;

      SelectObject(LMemoryDC, LDib);

      var LBlend: TBlendFunction;

      LBlend.BlendOp := AC_SRC_OVER;
      LBlend.BlendFlags := 0;
      LBlend.SourceConstantAlpha := 255;
      LBlend.AlphaFormat := AC_SRC_ALPHA;

      var LTransform: TXForm;

      if FMirrorDepth > 0 then
      begin
        GetWorldTransform(FDC, LTransform);
        ModifyWorldTransform(FDC, LTransform, MWT_IDENTITY);
      end;

      Winapi.Windows.AlphaBlend(FDC, LLeftPixel * UNITS_PER_PIXEL, LTopPixel * UNITS_PER_PIXEL, LWidth * UNITS_PER_PIXEL,
        LHeight * UNITS_PER_PIXEL, LMemoryDC, 0, 0, LWidth, LHeight, LBlend);

      if FMirrorDepth > 0 then
        SetWorldTransform(FDC, LTransform);
    finally
      DeleteDC(LMemoryDC);
      DeleteObject(LDib);
    end;
  finally
    LBitmap.Free;
  end;
end;

procedure TMathPainter.DrawText(const AText: string; const AFont: TMathFont; const AAdvances: TArray<Double>;
  const AX: Double; const ABaseline: Double; const AScale: Double; const AColor: COLORREF; const AFonts: TMathFontCache);
var
  LIndices: TArray<Word>;
  LDistances: TArray<Integer>;
  LUseGlyphIndices: Boolean;

  procedure DrawGlyphs(const ALogicalX: Integer; const ALogicalY: Integer);
  begin
    if LUseGlyphIndices then
      ExtTextOutW(FDC, ALogicalX, ALogicalY, ETO_GLYPH_INDEX, nil, PChar(@LIndices[0]), Length(LIndices), @LDistances[0])
    else
      ExtTextOutW(FDC, ALogicalX, ALogicalY, 0, nil, PChar(AText), AText.Length, @LDistances[0]);
  end;

begin
  if (FDC = 0) or AText.IsEmpty then
    Exit;

  var LHeight := Max(1, ToLogical(AScale));

  SelectObject(FDC, AFonts.GetFont(AFont, LHeight));

  LUseGlyphIndices := (AFont <> mfNone) and GetGlyphIndices(FDC, AText, LIndices);

  if not LUseGlyphIndices then
    SelectObject(FDC, AFonts.GetFont(mfNone, LHeight));

  SetLength(LDistances, AText.Length);

  var LPosition: Double := AX;
  var LPreviousX := ToLogicalX(LPosition);
  var LNextX: Integer;

  for var LIndex := 0 to AText.Length - 1 do
  begin
    if LIndex <= High(AAdvances) then
      LPosition := LPosition + AAdvances[LIndex] * AScale;

    LNextX := ToLogicalX(LPosition);
    LDistances[LIndex] := LNextX - LPreviousX;
    LPreviousX := LNextX;
  end;

  SetTextColor(FDC, AColor);

  if (FShadowOffsetX <> 0) or (FShadowOffsetY <> 0) then
    DrawGlyphs(ToLogicalX(AX) + Sign(FShadowOffsetX) * Max(UNITS_PER_PIXEL, Abs(ToLogical(FShadowOffsetX))),
      ToLogicalY(ABaseline + FShadowOffsetY));

  DrawGlyphs(ToLogicalX(AX), ToLogicalY(ABaseline));
end;

procedure TMathPainter.DrawSymbol(const ABox: TMathSymbolBox; const AX: Double; const ABaseline: Double;
  const AScale: Double);
var
  LRGB: COLORREF;
begin
  if ColorToRGB(ABox.Color, LRGB) then
    DrawText(ABox.Text, ABox.Font, ABox.Advances, AX, ABaseline, AScale, LRGB, if FGrayscaleText then FGrayscaleFonts else FFonts);
end;

procedure TMathPainter.DrawSpan(const ABox: TMathSpanBox; const AX: Double; const ABaseline: Double; const AScale: Double);
begin
  var LX: Double := AX;

  case ABox.LapAlignment of
    laLeft:
      LX := AX - ABox.ContentWidth * AScale;
    laCenter:
      LX := AX - ABox.ContentWidth * AScale / 2;
  end;

  var LSavedShadowOffsetX: Double := FShadowOffsetX;
  var LSavedShadowOffsetY: Double := FShadowOffsetY;
  var LSavedGrayscaleText := FGrayscaleText;
  var LSavedMirrorOffset: Double := FMirrorOffset;
  var LSavedMirrorScale: Double := FMirrorScale;
  var LSavedGraphicsMode := 0;

  if bfDelimiterPiece in ABox.Flags then
    FGrayscaleText := True;

  if ABox.HasShadow then
  begin
    FShadowOffsetX := ABox.ShadowOffsetX * AScale;
    FShadowOffsetY := ABox.ShadowOffsetY * AScale;
  end;

  var LDoubleAxis: Double;
  var LSavedTransform: TXForm;

  if ABox.Mirrored then
  begin
    LDoubleAxis := 2 * (FOriginX + (LX + ABox.Width * AScale / 2) * FUnitsPerEm);

    if FDC <> 0 then
      LDoubleAxis := Round(LDoubleAxis / UNITS_PER_PIXEL) * UNITS_PER_PIXEL;

    FMirrorOffset := FMirrorOffset + FMirrorScale * (LDoubleAxis - 2 * FOriginX) / FUnitsPerEm;
    FMirrorScale := -FMirrorScale;
    Inc(FMirrorDepth);

    if FDC <> 0 then
    begin
      LSavedGraphicsMode := SetGraphicsMode(FDC, GM_ADVANCED);

      GetWorldTransform(FDC, LSavedTransform);

      var LMirror: TXForm;

      LMirror.eM11 := -1;
      LMirror.eM12 := 0;
      LMirror.eM21 := 0;
      LMirror.eM22 := 1;
      LMirror.eDx := LDoubleAxis;
      LMirror.eDy := 0;
      ModifyWorldTransform(FDC, LMirror, MWT_LEFTMULTIPLY);
    end;
  end;

  try
    for var LIndex := 0 to ABox.Children.Count - 1 do
    begin
      DrawBox(ABox.Children[LIndex], LX, ABaseline, AScale);
      LX := LX + ABox.Children[LIndex].Advance * AScale;
    end;
  finally
    FShadowOffsetX := LSavedShadowOffsetX;
    FShadowOffsetY := LSavedShadowOffsetY;
    FGrayscaleText := LSavedGrayscaleText;

    if ABox.Mirrored then
    begin
      FMirrorOffset := LSavedMirrorOffset;
      FMirrorScale := LSavedMirrorScale;
      Dec(FMirrorDepth);

      if FDC <> 0 then
      begin
        SetWorldTransform(FDC, LSavedTransform);
        SetGraphicsMode(FDC, LSavedGraphicsMode);
      end;
    end;
  end;
end;

procedure TMathPainter.DrawVList(const ABox: TMathVListBox; const AX: Double; const ABaseline: Double; const AScale: Double);
var
  LItem: TMathVListItem;
  LAvailableWidth: Double;
  LElementWidth: Double;
  LOffset: Double;
begin
  for var LIndex := 0 to ABox.Items.Count - 1 do
  begin
    LItem := ABox.Items[LIndex];

    LAvailableWidth := ABox.Width - LItem.MarginLeft - LItem.MarginRight;
    LElementWidth := if LItem.Element.StretchWidth then LAvailableWidth else LItem.Element.Advance;
    LOffset := LItem.MarginLeft;

    case ABox.Alignment of
      vaCenter:
        LOffset := LOffset + (LAvailableWidth - LElementWidth) / 2;
      vaRight:
        LOffset := LOffset + LAvailableWidth - LElementWidth;
    end;

    DrawBox(LItem.Element, AX + LOffset * AScale, ABaseline - LItem.Baseline * AScale, AScale, LAvailableWidth * AScale);
  end;
end;

procedure TMathPainter.DrawRepeat(const ABox: TMathRepeatBox; const AX: Double; const ABaseline: Double; const AScale: Double; const AOuterScale: Double);
var
  LRGB: COLORREF;
begin
  if (FDC = 0) or not ColorToRGB(ABox.Color, LRGB) then
    Exit;

  var LTop: Double := ABaseline - ABox.Height * AOuterScale;
  var LGlyphHeight: Double := (ABox.GlyphHeight + ABox.GlyphDepth) * AScale;

  if LGlyphHeight <= 0 then
    Exit;

  var LCount := Max(1, Ceil((ABaseline - LTop) / LGlyphHeight));
  var LStep: Double := if LCount > 1 then (ABaseline - LTop - LGlyphHeight) / (LCount - 1) else 0;

  for var LIndex := 0 to LCount - 1 do
  begin
    SaveDC(FDC);
    try
      var LClip := Rect(ToLogicalX(AX - AScale), ToLogicalY(if LIndex = LCount - 1 then LTop else ABaseline - (LIndex + 1) * LStep),
        ToLogicalX(AX + (ABox.GlyphWidth + 1) * AScale), ToLogicalY(ABaseline - LIndex * LStep));
      IntersectClipRect(FDC, LClip.Left, LClip.Top, LClip.Right, LClip.Bottom);
      DrawText(ABox.Text, ABox.Font, [ABox.GlyphWidth], AX, ABaseline - LIndex * LStep - ABox.GlyphDepth * AScale, AScale,
        LRGB, FGrayscaleFonts);
    finally
      RestoreDC(FDC, -1);
    end;
  end;
end;

procedure TMathPainter.DrawSurd(const ABox: TMathSurdBox; const AX: Double; const ABaseline: Double; const AScale: Double;
  const AContainerWidth: Double);
begin
  DrawBox(ABox.Surd, AX, ABaseline - ABox.SurdBaseline * AScale, AScale * ABox.SurdScale);

  var LTop: Double := ABaseline - ABox.Height * AScale;

  FillRectangle(AX + ABox.VinculumStart * AScale, LTop, AX + Max(AContainerWidth, ABox.MinWidth * AScale),
    LTop + ABox.VinculumThickness * AScale, ABox.Color);
end;

procedure TMathPainter.DrawRule(const ABox: TMathRuleBox; const AX: Double; const ABaseline: Double; const AScale: Double;
  const AOuterScale: Double; const AContainerWidth: Double);
begin
  var LWidth: Double := if ABox.StretchWidth then AContainerWidth else ABox.Width * AScale;
  var LTop: Double;
  var LBottom: Double;

  if ABox.HasDrawExtent then
  begin
    LTop := ABaseline - ABox.DrawHeight * AScale;
    LBottom := ABaseline + ABox.DrawDepth * AScale;
  end
  else
  begin
    LTop := ABaseline - ABox.Height * AOuterScale;
    LBottom := ABaseline + ABox.Depth * AOuterScale;
  end;

  IncludeBounds(AX, LTop, AX + LWidth, LBottom);

  if ABox.Dashed then
    DrawDashedRectangle(AX, LTop, AX + LWidth, LBottom, ABox.Color)
  else
    FillRectangle(AX, LTop, AX + LWidth, LBottom, ABox.Color);
end;

procedure TMathPainter.DrawSvg(const ABox: TMathSvgBox; const AX: Double; const ABaseline: Double; const AScale: Double;
  const AOuterScale: Double; const AWidth: Double);
var
  LRGB: COLORREF;
begin
  var LTop: Double := ABaseline - ABox.Height * AOuterScale;
  var LHeight: Double := ABox.Height * AOuterScale;

  IncludeBounds(AX, LTop, AX + AWidth, ABaseline);

  if (FDC = 0) or (AWidth <= 0) or not ColorToRGB(ABox.Color, LRGB) then
    Exit;

  DrawRaster(AX, LTop, AX + AWidth, ABaseline,
    procedure(const AGraphics: TGPGraphics; const AOffsetX: Double; const AOffsetY: Double)
    var
      LPath: TGPGraphicsPath;
      LScaleX: Double;
      LScaleY: Double;
      LRegionLeft: Double;
      LRegionRight: Double;
      LPathX: Double;
    begin
      var LLeft: Double := ToPixelX(AX) + AOffsetX;
      var LTopPixel: Double := ToPixelY(LTop) + AOffsetY;
      var LWidthPixels: Double := AWidth * FUnitsPerEm / UNITS_PER_PIXEL;
      var LHeightPixels: Double := LHeight * FUnitsPerEm / UNITS_PER_PIXEL;
      var LBrush := TGPSolidBrush.Create(MakeColor(255, GetRValue(LRGB), GetGValue(LRGB), GetBValue(LRGB)));
      try
        for var LPart in ABox.Parts do
        begin
          LPath := TGPGraphicsPath.Create;
          try
            if ABox.Stretch then
            begin
              LScaleX := LWidthPixels / ABox.ViewBoxWidth;
              LScaleY := LHeightPixels / ABox.ViewBoxHeight;
              LRegionLeft := 0;
              LRegionRight := LWidthPixels;
              LPathX := 0;
            end
            else
            begin
              LScaleX := LHeightPixels / ABox.ViewBoxHeight;
              LScaleY := LScaleX;

              case LPart.Region of
                srLeftHalf:
                  begin
                    LRegionLeft := 0;
                    LRegionRight := 0.502 * LWidthPixels;
                  end;
                srRightHalf:
                  begin
                    LRegionLeft := LWidthPixels - 0.502 * LWidthPixels;
                    LRegionRight := LWidthPixels;
                  end;
                srBraceLeft:
                  begin
                    LRegionLeft := 0;
                    LRegionRight := 0.251 * LWidthPixels;
                  end;
                srBraceCenter:
                  begin
                    LRegionLeft := 0.25 * LWidthPixels;
                    LRegionRight := 0.75 * LWidthPixels;
                  end;
                srBraceRight:
                  begin
                    LRegionLeft := LWidthPixels - 0.251 * LWidthPixels;
                    LRegionRight := LWidthPixels;
                  end;
              else
                begin
                  LRegionLeft := 0;
                  LRegionRight := LWidthPixels;
                end;
              end;

              case LPart.Align of
                saMid:
                  LPathX := (LRegionLeft + LRegionRight - ABox.ViewBoxWidth * LScaleX) / 2;
                saMax:
                  LPathX := LRegionRight - ABox.ViewBoxWidth * LScaleX;
              else
                LPathX := LRegionLeft;
              end;
            end;

            AddSvgPath(LPath, LPart.PathData, LScaleX, LScaleY, LLeft + LPathX, LTopPixel);
            AGraphics.SetClip(MakeRect(Single(LLeft + LRegionLeft), Single(LTopPixel), Single(LRegionRight - LRegionLeft),
              Single(LHeightPixels)));
            AGraphics.FillPath(LBrush, LPath);
            AGraphics.ResetClip;
          finally
            LPath.Free;
          end;
        end;
      finally
        LBrush.Free;
      end;
    end);
end;

procedure TMathPainter.DrawFrame(const ABox: TMathFrameBox; const AX: Double; const ABaseline: Double; const AScale: Double; const AOuterScale: Double; const AWidth: Double);
begin
  var LTop: Double := ABaseline - ABox.Height * AOuterScale;
  var LBottom: Double := ABaseline + ABox.Depth * AOuterScale;
  var LRight: Double := AX + AWidth;

  IncludeBounds(AX, LTop, LRight, LBottom);

  if FDC = 0 then
    Exit;

  if ABox.BackgroundColor.Kind <> ckDefault then
    FillRectangle(AX, LTop, LRight, LBottom, ABox.BackgroundColor);

  if ABox.BorderTop > 0 then
    FillRectangle(AX, LTop, LRight, LTop + ABox.BorderTop * AScale, ABox.BorderColor);

  if ABox.BorderBottom > 0 then
    FillRectangle(AX, LBottom - ABox.BorderBottom * AScale, LRight, LBottom, ABox.BorderColor);

  if ABox.BorderLeft > 0 then
    FillRectangle(AX, LTop, AX + ABox.BorderLeft * AScale, LBottom, ABox.BorderColor);

  if ABox.BorderRight > 0 then
    FillRectangle(LRight - ABox.BorderRight * AScale, LTop, LRight, LBottom, ABox.BorderColor);

  var LRGB: COLORREF;

  if (ABox.CancelLines <> []) and ColorToRGB(ABox.BorderColor, LRGB) then
    DrawRaster(AX, LTop, LRight, LBottom,
      procedure(const AGraphics: TGPGraphics; const AOffsetX: Double; const AOffsetY: Double)
      begin
        var LLeftPixel: Single := ToPixelX(AX) + AOffsetX;
        var LTopPixel: Single := ToPixelY(LTop) + AOffsetY;
        var LRightPixel: Single := ToPixelX(LRight) + AOffsetX;
        var LBottomPixel: Single := ToPixelY(LBottom) + AOffsetY;
        var LPen := TGPPen.Create(MakeColor(255, GetRValue(LRGB), GetGValue(LRGB), GetBValue(LRGB)), Max(1, ABox.LineWidth * AScale * FUnitsPerEm / UNITS_PER_PIXEL));
        try
          if clForward in ABox.CancelLines then
            AGraphics.DrawLine(LPen, LLeftPixel, LBottomPixel, LRightPixel, LTopPixel);

          if clBackward in ABox.CancelLines then
            AGraphics.DrawLine(LPen, LLeftPixel, LTopPixel, LRightPixel, LBottomPixel);
        finally
          LPen.Free;
        end;
      end);
end;

procedure TMathPainter.DrawBox(const ABox: TMathBox; const AX: Double; const ABaseline: Double; const AScale: Double; const AContainerWidth: Double = 0);
begin
  var LScale: Double := AScale * ABox.Scale;
  var LX: Double := AX + LScale * (ABox.MarginLeft + ABox.PaddingLeft + ABox.ShiftX);
  var LBaseline: Double := ABaseline + LScale * ABox.ShiftY;
  var LWidth: Double := if ABox.StretchWidth then AContainerWidth else ABox.Width * LScale;

  if ABox is TMathSymbolBox then
  begin
    IncludeBounds(LX, LBaseline - ABox.Height * AScale, LX + (ABox.Width + Max(ABox.Italic, 0)) * LScale +
      Max(FShadowOffsetX, 0), LBaseline + ABox.Depth * AScale + Max(FShadowOffsetY, 0));
    DrawSymbol(TMathSymbolBox(ABox), LX, LBaseline, LScale);
  end
  else
  if ABox is TMathSpanBox then
    DrawSpan(TMathSpanBox(ABox), LX, LBaseline, LScale)
  else
  if ABox is TMathVListBox then
    DrawVList(TMathVListBox(ABox), LX, LBaseline, LScale)
  else
  if ABox is TMathRuleBox then
    DrawRule(TMathRuleBox(ABox), LX, LBaseline, LScale, AScale, AContainerWidth)
  else
  if ABox is TMathRepeatBox then
  begin
    IncludeBounds(LX, LBaseline - ABox.Height * AScale, LX + ABox.Width * LScale, LBaseline);
    DrawRepeat(TMathRepeatBox(ABox), LX, LBaseline, LScale, AScale);
  end
  else
  if ABox is TMathSurdBox then
    DrawSurd(TMathSurdBox(ABox), LX, LBaseline, LScale, AContainerWidth)
  else
  if ABox is TMathSvgBox then
    DrawSvg(TMathSvgBox(ABox), LX, LBaseline, LScale, AScale, Max(LWidth, TMathSvgBox(ABox).MinWidth * LScale))
  else
  if ABox is TMathFrameBox then
    DrawFrame(TMathFrameBox(ABox), LX, LBaseline, LScale, AScale, LWidth);
end;

end.
