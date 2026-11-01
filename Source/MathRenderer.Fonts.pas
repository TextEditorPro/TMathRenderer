unit MathRenderer.Fonts;

interface

uses
  Winapi.Windows, System.Generics.Collections, MathRenderer.Types;

type
  TMathFontKey = record
    Font: TMathFont;
    Height: Integer;
  end;

  TMathFontCache = class(TObject)
  strict private
    FFonts: TDictionary<TMathFontKey, HFONT>;
    FQuality: Byte;
  public
    constructor Create(const AQuality: Byte = DEFAULT_QUALITY);
    destructor Destroy; override;
    function GetFont(const AFont: TMathFont; const AHeight: Integer): HFONT;
    procedure Clear;
  end;

const
  FALLBACK_FONT_NAME = 'Times New Roman';

function CreateMathFont(const AFont: TMathFont; const AHeight: Integer; const AQuality: Byte = DEFAULT_QUALITY): HFONT;
function FontHasGlyphs(const AFont: TMathFont; const AText: string): Boolean;
function GetGlyphIndices(const ADC: HDC; const AText: string; out AIndices: TArray<Word>): Boolean;
function MeasureText(const AText: string; const AFont: TMathFont): Double;

implementation

{$R MathRenderer.Fonts.res}

uses
  System.Classes, System.SyncObjs, System.SysUtils;

const
  MEASURE_FONT_HEIGHT = 1000;

  FONT_RESOURCES: array [TMathFont] of string = ('', 'KATEX_AMS_REGULAR', 'KATEX_CALIGRAPHIC_REGULAR', 'KATEX_FRAKTUR_REGULAR',
    'KATEX_MAIN_BOLD', 'KATEX_MAIN_BOLDITALIC', 'KATEX_MAIN_ITALIC', 'KATEX_MAIN_REGULAR', 'KATEX_MATH_BOLDITALIC',
    'KATEX_MATH_ITALIC', 'KATEX_SANSSERIF_BOLD', 'KATEX_SANSSERIF_ITALIC', 'KATEX_SANSSERIF_REGULAR', 'KATEX_SCRIPT_REGULAR',
    'KATEX_SIZE1_REGULAR', 'KATEX_SIZE2_REGULAR', 'KATEX_SIZE3_REGULAR', 'KATEX_SIZE4_REGULAR', 'KATEX_TYPEWRITER_REGULAR');

  FONT_FACE_NAMES: array [TMathFont] of string = (FALLBACK_FONT_NAME, 'KaTeX_AMS', 'KaTeX_Caligraphic', 'KaTeX_Fraktur',
    'KaTeX_Main', 'KaTeX_Main', 'KaTeX_Main', 'KaTeX_Main', 'KaTeX_Math', 'KaTeX_Math', 'KaTeX_SansSerif', 'KaTeX_SansSerif',
    'KaTeX_SansSerif', 'KaTeX_Script', 'KaTeX_Size1', 'KaTeX_Size2', 'KaTeX_Size3', 'KaTeX_Size4', 'KaTeX_Typewriter');

  BOLD_FONTS = [mfMainBold, mfMainBoldItalic, mfMathBoldItalic, mfSansSerifBold];
  ITALIC_FONTS = [mfMainBoldItalic, mfMainItalic, mfMathBoldItalic, mfMathItalic, mfSansSerifItalic];

type
  TMathFontResources = class(TObject)
  strict private
    FAdvances: TDictionary<string, Double>;
    FFontHandles: TList<THandle>;
    FMeasureDC: HDC;
    FMeasureFonts: TMathFontCache;
    FMeasureLock: TCriticalSection;
    class var FInstance: TMathFontResources;
    class destructor ReleaseInstance;
    procedure LoadFonts;
  public
    constructor Create;
    destructor Destroy; override;
    function FontHasGlyphs(const AFont: TMathFont; const AText: string): Boolean;
    class function Instance: TMathFontResources;
    function MeasureText(const AText: string; const AFont: TMathFont): Double;
  end;

function ReadBigEndianWord(const AData: TBytes; const AOffset: Integer): Word; inline;
begin
  Result := (AData[AOffset] shl 8) or AData[AOffset + 1];
end;

function ReadBigEndianCardinal(const AData: TBytes; const AOffset: Integer): Cardinal; inline;
begin
  Result := (Cardinal(AData[AOffset]) shl 24) or (Cardinal(AData[AOffset + 1]) shl 16) or (Cardinal(AData[AOffset + 2]) shl 8) or
    AData[AOffset + 3];
end;

procedure WriteBigEndianWord(var AData: TBytes; const AOffset: Integer; const AValue: Word); inline;
begin
  AData[AOffset] := AValue shr 8;
  AData[AOffset + 1] := AValue and $FF;
end;

procedure WriteBigEndianCardinal(var AData: TBytes; const AOffset: Integer; const AValue: Cardinal); inline;
begin
  AData[AOffset] := AValue shr 24;
  AData[AOffset + 1] := (AValue shr 16) and $FF;
  AData[AOffset + 2] := (AValue shr 8) and $FF;
  AData[AOffset + 3] := AValue and $FF;
end;

{ Font checksums are sums modulo 2^32, so these Cardinal sums are meant to overflow, also in builds with overflow checks }
{$IFOPT Q+}
  {$DEFINE MATH_RENDERER_OVERFLOW_CHECKS}
  {$Q-}
{$ENDIF}

function CalculateChecksum(const AData: TBytes; const AOffset: Integer; const ALength: Integer): Cardinal;
begin
  Result := 0;

  var LIndex := 0;
  var LWord: Cardinal;

  while LIndex < ALength do
  begin
    LWord := 0;

    for var LByte := 0 to 3 do
    begin
      LWord := LWord shl 8;

      if (LIndex + LByte < ALength) and (AOffset + LIndex + LByte < Length(AData)) then
        LWord := LWord or AData[AOffset + LIndex + LByte];
    end;

    Result := Result + LWord;
    Inc(LIndex, 4);
  end;
end;

procedure MarkItalic(var AData: TBytes);
const
  FS_SELECTION_ITALIC = $0001;
  FS_SELECTION_REGULAR = $0040;
  MAC_STYLE_ITALIC = $0002;
  OS2_FS_SELECTION_OFFSET = 62;
  HEAD_CHECKSUM_ADJUSTMENT_OFFSET = 8;
  HEAD_MAC_STYLE_OFFSET = 44;
var
  LRecord: Integer;
  LTag: string;
  LTableOffset: Integer;
  LTableLength: Integer;
begin
  var LTableCount := ReadBigEndianWord(AData, 4);
  var LHeadOffset := -1;

  for var LIndex := 0 to LTableCount - 1 do
  begin
    LRecord := 12 + 16 * LIndex;
    LTag := Chr(AData[LRecord]) + Chr(AData[LRecord + 1]) + Chr(AData[LRecord + 2]) + Chr(AData[LRecord + 3]);
    LTableOffset := ReadBigEndianCardinal(AData, LRecord + 8);
    LTableLength := ReadBigEndianCardinal(AData, LRecord + 12);

    if LTag = 'OS/2' then
      WriteBigEndianWord(AData, LTableOffset + OS2_FS_SELECTION_OFFSET,
        (ReadBigEndianWord(AData, LTableOffset + OS2_FS_SELECTION_OFFSET) or FS_SELECTION_ITALIC) and not FS_SELECTION_REGULAR)
    else
    if LTag = 'head' then
    begin
      LHeadOffset := LTableOffset;
      WriteBigEndianWord(AData, LTableOffset + HEAD_MAC_STYLE_OFFSET, ReadBigEndianWord(AData, LTableOffset + HEAD_MAC_STYLE_OFFSET) or MAC_STYLE_ITALIC);
      WriteBigEndianCardinal(AData, LTableOffset + HEAD_CHECKSUM_ADJUSTMENT_OFFSET, 0);
    end
    else
      Continue;

    WriteBigEndianCardinal(AData, LRecord + 4, CalculateChecksum(AData, LTableOffset, LTableLength));
  end;

  if LHeadOffset >= 0 then
    WriteBigEndianCardinal(AData, LHeadOffset + HEAD_CHECKSUM_ADJUSTMENT_OFFSET, $B1B0AFBA - CalculateChecksum(AData, 0, Length(AData)));
end;

{$IFDEF MATH_RENDERER_OVERFLOW_CHECKS}
  {$Q+}
  {$UNDEF MATH_RENDERER_OVERFLOW_CHECKS}
{$ENDIF}

{ TMathFontResources }

constructor TMathFontResources.Create;
begin
  inherited Create;

  FFontHandles := TList<THandle>.Create;
  LoadFonts;
  FAdvances := TDictionary<string, Double>.Create;
  FMeasureLock := TCriticalSection.Create;
  FMeasureFonts := TMathFontCache.Create;
  FMeasureDC := CreateCompatibleDC(0);
end;

destructor TMathFontResources.Destroy;
begin
  DeleteDC(FMeasureDC);
  FMeasureFonts.Free;
  FMeasureLock.Free;
  FAdvances.Free;

  for var LIndex := 0 to FFontHandles.Count - 1 do
    RemoveFontMemResourceEx(FFontHandles[LIndex]);

  FFontHandles.Free;

  inherited Destroy;
end;

class destructor TMathFontResources.ReleaseInstance;
begin
  FInstance.Free;
end;

class function TMathFontResources.Instance: TMathFontResources;
var
  LInstance: TMathFontResources;
begin
  Result := FInstance;

  if Assigned(Result) then
    Exit;

  LInstance := TMathFontResources.Create;
  Result := TInterlocked.CompareExchange<TMathFontResources>(FInstance, LInstance, nil);

  if Assigned(Result) then
    LInstance.Free
  else
    Result := LInstance;
end;

procedure TMathFontResources.LoadFonts;
var
  LResource: TResourceStream;
  LData: TBytes;
  LFontCount: DWORD;
  LHandle: THandle;
begin
  for var LFont := Succ(Low(TMathFont)) to High(TMathFont) do
  begin
    LResource := TResourceStream.Create(HInstance, FONT_RESOURCES[LFont], RT_RCDATA);
    try
      SetLength(LData, LResource.Size);
      LResource.ReadBuffer(LData[0], LResource.Size);
    finally
      LResource.Free;
    end;

    if LFont in ITALIC_FONTS then
      MarkItalic(LData);

    LFontCount := 0;
    LHandle := AddFontMemResourceEx(@LData[0], Length(LData), nil, @LFontCount);

    if LHandle <> 0 then
      FFontHandles.Add(LHandle);
  end;
end;

function TMathFontResources.FontHasGlyphs(const AFont: TMathFont; const AText: string): Boolean;
var
  LIndices: TArray<Word>;
begin
  if AFont = mfNone then
    Exit(False);

  FMeasureLock.Enter;
  try
    SelectObject(FMeasureDC, FMeasureFonts.GetFont(AFont, MEASURE_FONT_HEIGHT));

    Result := GetGlyphIndices(FMeasureDC, AText, LIndices);
  finally
    FMeasureLock.Leave;
  end;
end;

function TMathFontResources.MeasureText(const AText: string; const AFont: TMathFont): Double;
var
  LKey: string;
  LSize: TSize;
  LIndices: TArray<Word>;
  LWidths: TArray<Integer>;
begin
  LKey := Chr(Ord(AFont)) + AText;

  FMeasureLock.Enter;
  try
    if FAdvances.TryGetValue(LKey, Result) then
      Exit;
  finally
    FMeasureLock.Leave;
  end;

  var LFont := if FontHasGlyphs(AFont, AText) then AFont else mfNone;

  FMeasureLock.Enter;
  try
    SelectObject(FMeasureDC, FMeasureFonts.GetFont(LFont, MEASURE_FONT_HEIGHT));

    Result := 0;

    if (LFont <> mfNone) and GetGlyphIndices(FMeasureDC, AText, LIndices) then
    begin
      SetLength(LWidths, Length(LIndices));

      if GetCharWidthI(FMeasureDC, 0, Length(LIndices), @LIndices[0], LWidths[0]) then
      for var LIndex := 0 to High(LWidths) do
        Result := Result + LWidths[LIndex] / MEASURE_FONT_HEIGHT;
    end
    else
    if GetTextExtentPoint32W(FMeasureDC, PChar(AText), AText.Length, LSize) then
      Result := LSize.cx / MEASURE_FONT_HEIGHT;

    FAdvances.AddOrSetValue(LKey, Result);
  finally
    FMeasureLock.Leave;
  end;
end;

{ Functions }

function CreateMathFont(const AFont: TMathFont; const AHeight: Integer; const AQuality: Byte = DEFAULT_QUALITY): HFONT;
var
  LLogFont: TLogFont;
begin
  if AFont <> mfNone then
    TMathFontResources.Instance;

  FillChar(LLogFont, SizeOf(LLogFont), 0);

  LLogFont.lfHeight := -AHeight;
  LLogFont.lfWeight := if AFont in BOLD_FONTS then FW_BOLD else FW_NORMAL;
  LLogFont.lfItalic := if AFont in ITALIC_FONTS then 1 else 0;
  LLogFont.lfCharSet := DEFAULT_CHARSET;
  LLogFont.lfOutPrecision := if AFont = mfNone then OUT_DEFAULT_PRECIS else OUT_TT_ONLY_PRECIS;
  LLogFont.lfQuality := AQuality;
  StrPLCopy(LLogFont.lfFaceName, FONT_FACE_NAMES[AFont], Length(LLogFont.lfFaceName) - 1);

  Result := CreateFontIndirect(LLogFont);
end;

function GetGlyphIndices(const ADC: HDC; const AText: string; out AIndices: TArray<Word>): Boolean;
begin
  SetLength(AIndices, AText.Length);

  Result := not AText.IsEmpty and (Winapi.Windows.GetGlyphIndicesW(ADC, PChar(AText), AText.Length, @AIndices[0], GGI_MARK_NONEXISTING_GLYPHS) <> GDI_ERROR);

  if Result then
  for var LIndex := 0 to High(AIndices) do
  if AIndices[LIndex] = $FFFF then
    Exit(False);
end;

function FontHasGlyphs(const AFont: TMathFont; const AText: string): Boolean;
begin
  Result := TMathFontResources.Instance.FontHasGlyphs(AFont, AText);
end;

function MeasureText(const AText: string; const AFont: TMathFont): Double;
begin
  Result := TMathFontResources.Instance.MeasureText(AText, AFont);
end;

{ TMathFontCache }

constructor TMathFontCache.Create(const AQuality: Byte = DEFAULT_QUALITY);
begin
  inherited Create;

  FQuality := AQuality;
  FFonts := TDictionary<TMathFontKey, HFONT>.Create;
end;

destructor TMathFontCache.Destroy;
begin
  Clear;
  FFonts.Free;

  inherited Destroy;
end;

procedure TMathFontCache.Clear;
begin
  for var LFont in FFonts.Values do
    DeleteObject(LFont);

  FFonts.Clear;
end;

function TMathFontCache.GetFont(const AFont: TMathFont; const AHeight: Integer): HFONT;
var
  LKey: TMathFontKey;
begin
  LKey.Font := AFont;
  LKey.Height := AHeight;

  if not FFonts.TryGetValue(LKey, Result) then
  begin
    Result := CreateMathFont(AFont, AHeight, FQuality);
    FFonts.Add(LKey, Result);
  end;
end;

end.
