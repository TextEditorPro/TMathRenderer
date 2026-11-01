unit MathRenderer;

interface

uses
  Winapi.Windows, System.Classes, System.Generics.Collections, System.SysUtils, System.Types, Vcl.Graphics, MathRenderer.Boxes,
  MathRenderer.Fonts, MathRenderer.Types;

type
  TMathImageFormat = (ifEMF, ifPNG);

  TMathImage = record
    Baseline: Integer;
    Data: TBytes;
    Height: Integer;
    MimeType: string;
    TagData: TBytes;
    TagWidth: Integer;
    Width: Integer;
  end;

  TMathBoxExtent = record
    Ascent: Integer;
    Descent: Integer;
    Left: Double;
    Width: Integer;
  end;

  TMathCacheEntry = record
    EquationNumbers: Integer;
    FirstEquationNumber: Integer;
    HTML: string;
  end;

  TMathFormula = record
    DisplayMode: Boolean;
    Source: string;
    TeX: string;
  end;

  TMathMarkdownConverter = reference to function(const AMarkdown: string): string;

  TMathRenderer = class(TObject)
  strict private
    FAntialiasedFonts: TMathFontCache;
    FBackgroundColor: TColor;
    FCache: TDictionary<string, TMathCacheEntry>;
    FColor: TColor;
    FDefaultQualityFonts: TMathFontCache;
    FEquationNumber: Integer;
    FFontName: string;
    FFontSize: Integer;
    FImageFormat: TMathImageFormat;
    FInlineDescent: Integer;
    FInlineTextHeight: Integer;
    FMacros: TDictionary<string, string>;
    FMaxCacheCount: Integer;
    FMaxImagePixels: Int64;
    FMaxSize: Double;
    FMetafileMicrometersX: Double;
    FMetafileMicrometersY: Double;
    FMinRuleThickness: Double;
    FPixelRatio: Double;
    FPixelsPerInch: Integer;
    FScale: Double;
    FThrowOnError: Boolean;
    function BuildImage(const ATeX: string; const ADisplayMode: Boolean): TMathImage;
    function CacheKey(const ATeX: string; const ADisplayMode: Boolean): string;
    function CreateMetafileHandle(const ARoot: TMathBox; const AWidth: Integer; const AHeight: Integer; const AOriginX: Double;
      const ABaseline: Double; const AEmPixels: Double): HENHMETAFILE;
    function EncodeImage(const ABox: TMathBox; const AExtent: TMathBoxExtent; const AHeight: Integer; const ABaseline: Integer;
      const AEmPixels: Double; const APadding: Integer; out AMimeType: string): TBytes;
    function GetEmPixels: Double;
    function GetImagePixelsPerInch: Integer;
    function InsertMath(const AHTML: string; const AFormulas: TList<TMathFormula>): string;
    function MeasureBox(const ABox: TMathBox; const AEmPixels: Double; const APadding: Integer): TMathBoxExtent;
    procedure GetInlineAlignment(out ATextHeight: Integer; out ADescent: Integer);
    procedure MacrosChanged(Sender: TObject; const AItem: string; AAction: TCollectionNotification);
    procedure SetBackgroundColor(const AValue: TColor);
    procedure SetColor(const AValue: TColor);
    procedure SetFontName(const AValue: string);
    procedure SetFontSize(const AValue: Integer);
    procedure SetImageFormat(const AValue: TMathImageFormat);
    procedure SetMaxImagePixels(const AValue: Int64);
    procedure SetMaxSize(const AValue: Double);
    procedure SetMinRuleThickness(const AValue: Double);
    procedure SetPixelRatio(const AValue: Double);
    procedure SetPixelsPerInch(const AValue: Integer);
    procedure SetScale(const AValue: Double);
    procedure SetThrowOnError(const AValue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    function RenderToHTML(const ATeX: string; const ADisplayMode: Boolean = False): string;
    function RenderToImage(const ATeX: string; const ADisplayMode: Boolean = False): TMathImage;
    function ReplaceMathInHTML(const AHTML: string): string;
    function ReplaceMathInMarkdown(const AMarkdown: string; const AConvertToHTML: TMathMarkdownConverter): string;
    procedure ClearCache;
    property BackgroundColor: TColor read FBackgroundColor write SetBackgroundColor;
    property Color: TColor read FColor write SetColor;
    property EquationNumber: Integer read FEquationNumber write FEquationNumber;
    property FontName: string read FFontName write SetFontName;
    property FontSize: Integer read FFontSize write SetFontSize;
    property ImageFormat: TMathImageFormat read FImageFormat write SetImageFormat;
    property Macros: TDictionary<string, string> read FMacros;
    property MaxCacheCount: Integer read FMaxCacheCount write FMaxCacheCount;
    property MaxImagePixels: Int64 read FMaxImagePixels write SetMaxImagePixels;
    property MaxSize: Double read FMaxSize write SetMaxSize;
    property MinRuleThickness: Double read FMinRuleThickness write SetMinRuleThickness;
    property PixelRatio: Double read FPixelRatio write SetPixelRatio;
    property PixelsPerInch: Integer read FPixelsPerInch write SetPixelsPerInch;
    property Scale: Double read FScale write SetScale;
    property ThrowOnError: Boolean read FThrowOnError write SetThrowOnError;
  end;

const
  MATH_DEFAULT_SCALE = 1.21;

function EscapeHTML(const AText: string): string;

implementation

uses
  System.Character, System.Math, System.NetEncoding, Vcl.Imaging.pngimage, MathRenderer.Builder, MathRenderer.FontMetrics,
  MathRenderer.Painter, MathRenderer.Parser, MathRenderer.ParseTree;

const
  MAX_IMAGE_SIDE = 32767;
  PADDING_EM = 0.08;
  ERROR_COLOR = '#cc0000';
  MATH_PLACEHOLDER_START = #$E000;
  MATH_PLACEHOLDER_END = #$E001;

function EscapeHTML(const AText: string): string;
begin
  var LBuilder := TStringBuilder.Create(AText.Length + 16);
  try
    for var LIndex := 1 to AText.Length do
    case AText[LIndex] of
      '&':
        LBuilder.Append('&amp;');
      '<':
        LBuilder.Append('&lt;');
      '>':
        LBuilder.Append('&gt;');
      '"':
        LBuilder.Append('&quot;');
      '''':
        LBuilder.Append('&#39;');
    else
      LBuilder.Append(AText[LIndex]);
    end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function ErrorHTML(const ATeX: string; const AMessage: string): string;
begin
  Result := Format('<span style="color:%s" title="%s">%s</span>', [ERROR_COLOR, EscapeHTML(AMessage), EscapeHTML(ATeX)]);
end;

function DecodeHTMLEntities(const AText: string): string;
begin
  if Pos('&', AText) = 0 then
    Exit(AText);

  var LBuilder := TStringBuilder.Create(AText.Length);
  try
    var LIndex := 1;
    var LEnd: Integer;
    var LEntity: string;
    var LCode: Integer;

    while LIndex <= AText.Length do
    begin
      if AText[LIndex] = '&' then
      begin
        LEnd := Pos(';', AText, LIndex);

        if (LEnd > LIndex) and (LEnd - LIndex <= 10) then
        begin
          LEntity := Copy(AText, LIndex + 1, LEnd - LIndex - 1);
          LCode := -1;

          if LEntity = 'amp' then
            LCode := Ord('&')
          else
          if LEntity = 'lt' then
            LCode := Ord('<')
          else
          if LEntity = 'gt' then
            LCode := Ord('>')
          else
          if LEntity = 'quot' then
            LCode := Ord('"')
          else
          if (LEntity = 'apos') or (LEntity = '#39') then
            LCode := Ord('''')
          else
          if LEntity = 'nbsp' then
            LCode := Ord(' ')
          else
          if LEntity.StartsWith('#x') or LEntity.StartsWith('#X') then
            LCode := StrToIntDef('$' + LEntity.Substring(2), -1)
          else
          if LEntity.StartsWith('#') then
            LCode := StrToIntDef(LEntity.Substring(1), -1);

          if (LCode >= 0) and (LCode <= $10FFFF) then
          begin
            LBuilder.Append(Char.ConvertFromUtf32(LCode));
            LIndex := LEnd + 1;

            Continue;
          end;
        end;
      end;

      LBuilder.Append(AText[LIndex]);
      Inc(LIndex);
    end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

{ TMathRenderer }

constructor TMathRenderer.Create;
begin
  inherited Create;

  FCache := TDictionary<string, TMathCacheEntry>.Create;
  FDefaultQualityFonts := TMathFontCache.Create(DEFAULT_QUALITY);
  FAntialiasedFonts := TMathFontCache.Create(ANTIALIASED_QUALITY);
  FMacros := TDictionary<string, string>.Create;
  FMacros.OnValueNotify := MacrosChanged;
  FBackgroundColor := clWhite;
  FColor := clBlack;
  FEquationNumber := 1;
  FFontName := 'Segoe UI';
  FFontSize := 12;
  FImageFormat := ifEMF;
  FMaxCacheCount := 1000;
  FMaxImagePixels := 16 * 1024 * 1024;
  FMaxSize := MaxDouble;
  FMinRuleThickness := 0;
  FPixelRatio := 1;
  FPixelsPerInch := 96;
  FScale := MATH_DEFAULT_SCALE;
  FThrowOnError := False;
end;

destructor TMathRenderer.Destroy;
begin
  FMacros.OnValueNotify := nil;
  FMacros.Free;
  FAntialiasedFonts.Free;
  FDefaultQualityFonts.Free;
  FCache.Free;

  inherited Destroy;
end;

procedure TMathRenderer.ClearCache;
begin
  FCache.Clear;
  FDefaultQualityFonts.Clear;
  FAntialiasedFonts.Clear;
  FInlineTextHeight := 0;
  FMetafileMicrometersX := 0;
end;

procedure TMathRenderer.MacrosChanged(Sender: TObject; const AItem: string; AAction: TCollectionNotification);
begin
  ClearCache;
end;

procedure TMathRenderer.SetBackgroundColor(const AValue: TColor);
begin
  if FBackgroundColor = AValue then
    Exit;

  FBackgroundColor := AValue;
  ClearCache;
end;

procedure TMathRenderer.SetColor(const AValue: TColor);
begin
  if FColor = AValue then
    Exit;

  FColor := AValue;
  ClearCache;
end;

procedure TMathRenderer.SetFontName(const AValue: string);
begin
  if FFontName = AValue then
    Exit;

  FFontName := AValue;
  ClearCache;
end;

procedure TMathRenderer.SetFontSize(const AValue: Integer);
begin
  if FFontSize = AValue then
    Exit;

  FFontSize := AValue;
  ClearCache;
end;

procedure TMathRenderer.SetImageFormat(const AValue: TMathImageFormat);
begin
  if FImageFormat = AValue then
    Exit;

  FImageFormat := AValue;
  ClearCache;
end;

procedure TMathRenderer.SetMaxImagePixels(const AValue: Int64);
begin
  if FMaxImagePixels = AValue then
    Exit;

  FMaxImagePixels := AValue;
  ClearCache;
end;

procedure TMathRenderer.SetMaxSize(const AValue: Double);
begin
  if FMaxSize = AValue then
    Exit;

  FMaxSize := AValue;
  ClearCache;
end;

procedure TMathRenderer.SetMinRuleThickness(const AValue: Double);
begin
  if FMinRuleThickness = AValue then
    Exit;

  FMinRuleThickness := AValue;
  ClearCache;
end;

procedure TMathRenderer.SetPixelRatio(const AValue: Double);
begin
  if AValue <= 0 then
    raise EArgumentOutOfRangeException.Create('PixelRatio must be greater than zero');

  if FPixelRatio = AValue then
    Exit;

  FPixelRatio := AValue;
  ClearCache;
end;

procedure TMathRenderer.SetPixelsPerInch(const AValue: Integer);
begin
  if FPixelsPerInch = AValue then
    Exit;

  FPixelsPerInch := AValue;
  ClearCache;
end;

procedure TMathRenderer.SetScale(const AValue: Double);
begin
  if FScale = AValue then
    Exit;

  FScale := AValue;
  ClearCache;
end;

procedure TMathRenderer.SetThrowOnError(const AValue: Boolean);
begin
  if FThrowOnError = AValue then
    Exit;

  FThrowOnError := AValue;
  ClearCache;
end;

function TMathRenderer.GetEmPixels: Double;
begin
  Result := FFontSize * GetImagePixelsPerInch / 72 * FScale;
end;

function TMathRenderer.GetImagePixelsPerInch: Integer;
begin
  Result := Round(FPixelsPerInch * FPixelRatio);
end;

procedure TMathRenderer.GetInlineAlignment(out ATextHeight: Integer; out ADescent: Integer);
begin
  if FInlineTextHeight > 0 then
  begin
    ATextHeight := FInlineTextHeight;
    ADescent := FInlineDescent;

    Exit;
  end;

  var LDC: HDC := CreateCompatibleDC(0);
  try
    var LFont: HFONT := CreateFont(-MulDiv(FFontSize, GetImagePixelsPerInch, 72), 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET,
      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH, PChar(FFontName));
    try
      SelectObject(LDC, LFont);

      var LTextMetric: TTextMetric;

      GetTextMetrics(LDC, LTextMetric);
      FInlineTextHeight := LTextMetric.tmHeight;
      FInlineDescent := LTextMetric.tmDescent;
      ATextHeight := FInlineTextHeight;
      ADescent := FInlineDescent;
    finally
      DeleteObject(LFont);
    end;
  finally
    DeleteDC(LDC);
  end;
end;

procedure GetMetafileMicrometersPerPixel(out AHorizontal: Double; out AVertical: Double);
var
  LMetafile: HENHMETAFILE;
  LHeader: TEnhMetaHeader;
begin
  var LDC: HDC := GetDC(0);
  try
    var LFrame := Rect(0, 0, 100, 100);
    LMetafile := CloseEnhMetaFile(CreateEnhMetaFile(LDC, nil, @LFrame, nil));
  finally
    ReleaseDC(0, LDC);
  end;

  try
    GetEnhMetaFileHeader(LMetafile, SizeOf(LHeader), @LHeader);
    AHorizontal := LHeader.szlMicrometers.cx / LHeader.szlDevice.cx;
    AVertical := LHeader.szlMicrometers.cy / LHeader.szlDevice.cy;
  finally
    DeleteEnhMetaFile(LMetafile);
  end;
end;

function TMathRenderer.CreateMetafileHandle(const ARoot: TMathBox; const AWidth: Integer; const AHeight: Integer; const AOriginX: Double;
  const ABaseline: Double; const AEmPixels: Double): HENHMETAFILE;
begin
  if FMetafileMicrometersX = 0 then
    GetMetafileMicrometersPerPixel(FMetafileMicrometersX, FMetafileMicrometersY);

  var LFrame := Rect(0, 0, Round((AWidth - 1) * FMetafileMicrometersX / 10), Round((AHeight - 1) * FMetafileMicrometersY / 10));
  var LDC: HDC;
  var LReferenceDC: HDC := GetDC(0);
  try
    LDC := CreateEnhMetaFile(LReferenceDC, nil, @LFrame, nil);
  finally
    ReleaseDC(0, LReferenceDC);
  end;

  if LDC = 0 then
    RaiseLastOSError;

  SetMapMode(LDC, MM_ANISOTROPIC);
  SetWindowExtEx(LDC, AWidth * UNITS_PER_PIXEL, AHeight * UNITS_PER_PIXEL, nil);
  SetViewportExtEx(LDC, AWidth, AHeight, nil);
  SetBkMode(LDC, TRANSPARENT);
  SetTextAlign(LDC, TA_LEFT or TA_BASELINE or TA_NOUPDATECP);

  SelectObject(LDC, GetStockObject(NULL_PEN));
  SelectObject(LDC, GetStockObject(NULL_BRUSH));
  Rectangle(LDC, 0, 0, AWidth * UNITS_PER_PIXEL, AHeight * UNITS_PER_PIXEL);

  var LPainter := TMathPainter.Create(LDC, AEmPixels * UNITS_PER_PIXEL, AOriginX * UNITS_PER_PIXEL, ABaseline * UNITS_PER_PIXEL, FColor,
    if FImageFormat = ifPNG then FAntialiasedFonts else FDefaultQualityFonts, FAntialiasedFonts);
  try
    LPainter.DrawBox(ARoot, 0, 0, 1);
  finally
    LPainter.Free;
  end;

  Result := CloseEnhMetaFile(LDC);
end;

function TMathRenderer.MeasureBox(const ABox: TMathBox; const AEmPixels: Double; const APadding: Integer): TMathBoxExtent;
var
  LBounds: TRectF;
begin
  ABox.Measure;

  var LPainter := TMathPainter.Create(0, 1, 0, 0, FColor, FDefaultQualityFonts, FAntialiasedFonts);
  try
    LPainter.DrawBox(ABox, 0, 0, 1);
    LBounds := LPainter.Bounds;
  finally
    LPainter.Free;
  end;

  Result.Left := Min(0, LBounds.Left);
  Result.Width := Ceil((Max(ABox.Advance, LBounds.Right) - Result.Left) * AEmPixels) + 2 * APadding;
  Result.Ascent := Ceil(Max(ABox.Height, -LBounds.Top) * AEmPixels) + APadding;
  Result.Descent := Ceil(Max(ABox.Depth, LBounds.Bottom) * AEmPixels) + APadding;
end;

function TMathRenderer.EncodeImage(const ABox: TMathBox; const AExtent: TMathBoxExtent; const AHeight: Integer; const ABaseline: Integer;
  const AEmPixels: Double; const APadding: Integer; out AMimeType: string): TBytes;
begin
  var LMetafile: HENHMETAFILE := CreateMetafileHandle(ABox, AExtent.Width, AHeight, APadding - AExtent.Left * AEmPixels, ABaseline, AEmPixels);
  try
    if FImageFormat = ifEMF then
    begin
      var LSize: UINT := GetEnhMetaFileBits(LMetafile, 0, nil);

      SetLength(Result, LSize);
      GetEnhMetaFileBits(LMetafile, LSize, @Result[0]);
      AMimeType := 'image/x-emf';

      Exit;
    end;

    var LBitmap := TBitmap.Create(AExtent.Width, AHeight);
    try
      LBitmap.PixelFormat := pf24bit;
      LBitmap.Canvas.Brush.Color := FBackgroundColor;
      LBitmap.Canvas.FillRect(Rect(0, 0, AExtent.Width, AHeight));

      PlayEnhMetaFile(LBitmap.Canvas.Handle, LMetafile, Rect(0, 0, AExtent.Width, AHeight));

      var LPng := TPngImage.Create;
      try
        LPng.Assign(LBitmap);

        var LStream := TBytesStream.Create;
        try
          LPng.SaveToStream(LStream);
          Result := Copy(LStream.Bytes, 0, LStream.Size);
        finally
          LStream.Free;
        end;
      finally
        LPng.Free;
      end;
    finally
      LBitmap.Free;
    end;

    AMimeType := 'image/png';
  finally
    DeleteEnhMetaFile(LMetafile);
  end;
end;

function TMathRenderer.BuildImage(const ATeX: string; const ADisplayMode: Boolean): TMathImage;
begin
  Result := Default(TMathImage);

  var LSettings := TMathSettings.Default;

  LSettings.DisplayMode := ADisplayMode;
  LSettings.ThrowOnError := FThrowOnError;
  LSettings.ErrorColor := ERROR_COLOR;
  LSettings.MinRuleThickness := FMinRuleThickness;
  LSettings.MaxSize := FMaxSize;
  LSettings.Macros := FMacros;

  var LTree: TMathNodeList;
  var LArena := TMathParseArena.Create;
  try
    var LParser := TMathParser.Create(ATeX, LSettings, LArena);
    try
      LTree := LParser.Parse;
    finally
      LParser.Free;
    end;

    var LBuilder := TMathBuilder.Create(LArena, LSettings, MeasureText);
    try
      LBuilder.EquationNumber := FEquationNumber;

      var LRoot := LBuilder.Build(LTree);

      FEquationNumber := LBuilder.EquationNumber;

      var LEmPixels: Double := GetEmPixels;
      var LPadding := Ceil(PADDING_EM * LEmPixels);
      var LExtent := MeasureBox(LRoot, LEmPixels, LPadding);
      var LAscent := LExtent.Ascent;
      var LDescent := LExtent.Descent;
      var LTagExtent: TMathBoxExtent;

      if Assigned(LBuilder.Tag) then
      begin
        LTagExtent := MeasureBox(LBuilder.Tag, LEmPixels, LPadding);
        LAscent := Max(LAscent, LTagExtent.Ascent);
        LDescent := Max(LDescent, LTagExtent.Descent);
      end;

      var LTopPadding := 0;

      Result.Height := LAscent + LDescent;

      if not ADisplayMode then
      begin
        var LTextHeight: Integer;
        var LTextDescent: Integer;

        GetInlineAlignment(LTextHeight, LTextDescent);

        var LCenterOffset := LTextHeight div 2 - LTextDescent;

        if LAscent - 2 * LCenterOffset >= LDescent then
          Result.Height := 2 * (LAscent - LCenterOffset)
        else
        begin
          LTopPadding := LDescent + 2 * LCenterOffset - LAscent;
          Result.Height := 2 * (LDescent + LCenterOffset);
        end;
      end;

      Result.Baseline := LTopPadding + LAscent;
      Result.Width := LExtent.Width;

      if (Result.Width > MAX_IMAGE_SIDE) or (Result.Height > MAX_IMAGE_SIDE) or (Int64(Result.Width) * Result.Height > FMaxImagePixels) then
        raise EMathParseError.CreateFmt('Formula is too large: %d x %d pixels', [Result.Width, Result.Height]);

      Result.Data := EncodeImage(LRoot, LExtent, Result.Height, Result.Baseline, LEmPixels, LPadding, Result.MimeType);

      if Assigned(LBuilder.Tag) then
      begin
        Result.TagWidth := LTagExtent.Width;
        Result.TagData := EncodeImage(LBuilder.Tag, LTagExtent, Result.Height, Result.Baseline, LEmPixels, LPadding, Result.MimeType);
      end;
    finally
      LBuilder.Free;
    end;
  finally
    LArena.Free;
  end;
end;

function TMathRenderer.RenderToImage(const ATeX: string; const ADisplayMode: Boolean = False): TMathImage;
begin
  Result := BuildImage(ATeX, ADisplayMode);
end;

function TMathRenderer.CacheKey(const ATeX: string; const ADisplayMode: Boolean): string;
begin
  Result := (if ADisplayMode then 'D' else 'I') + ATeX;
end;

function TMathRenderer.RenderToHTML(const ATeX: string; const ADisplayMode: Boolean = False): string;
var
  LEntry: TMathCacheEntry;
  LImageHTML: string;
  LTagHTML: string;
begin
  var LKey := CacheKey(ATeX, ADisplayMode);

  if FCache.TryGetValue(LKey, LEntry) and ((LEntry.EquationNumbers = 0) or (LEntry.FirstEquationNumber = FEquationNumber)) then
  begin
    Inc(FEquationNumber, LEntry.EquationNumbers);

    Exit(LEntry.HTML);
  end;

  var LFirstNumber := FEquationNumber;

  try
    var LImage := BuildImage(ATeX, ADisplayMode);
    var LImagePixelsPerInch := GetImagePixelsPerInch;
    var LWidth := MulDiv(LImage.Width, FPixelsPerInch, LImagePixelsPerInch);
    var LHeight := MulDiv(LImage.Height, FPixelsPerInch, LImagePixelsPerInch);
    var LTagWidth := MulDiv(LImage.TagWidth, FPixelsPerInch, LImagePixelsPerInch);

    var LBase64 := TBase64Encoding.Create(0);
    try
      LImageHTML := Format('<img src="data:%s;base64,%s" width="%d" height="%d" alt="%s"', [LImage.MimeType,
        LBase64.EncodeBytesToString(LImage.Data), LWidth, LHeight, EscapeHTML(ATeX)]);

      if Length(LImage.TagData) > 0 then
        LTagHTML := Format('<img src="data:%s;base64,%s" width="%d" height="%d">', [LImage.MimeType,
          LBase64.EncodeBytesToString(LImage.TagData), LTagWidth, LHeight])
      else
        LTagHTML := '';
    finally
      LBase64.Free;
    end;

    if ADisplayMode and not LTagHTML.IsEmpty then
      Result := Format('<table width="100%%" cellspacing="0" cellpadding="0" style="margin-top:0.5em;margin-bottom:0.5em">' +
        '<tr><td width="%d"></td><td style="text-align:center">%s></td><td width="%d" style="text-align:right">%s</td></tr>' +
        '</table>', [LTagWidth, LImageHTML, LTagWidth, LTagHTML])
    else
    if ADisplayMode then
      Result := '<div style="text-align:center;margin-top:0.5em;margin-bottom:0.5em">' + LImageHTML + '></div>'
    else
      Result := LImageHTML + ' style="vertical-align:middle">';
  except
    on LException: EMathParseError do
    begin
      if FThrowOnError then
        raise;

      Result := ErrorHTML(ATeX, LException.Message);
    end;
    on LException: EOutOfResources do
      Exit(ErrorHTML(ATeX, LException.Message));
    on LException: EOSError do
      Exit(ErrorHTML(ATeX, LException.Message));
  end;

  if FCache.Count >= FMaxCacheCount then
    FCache.Clear;

  LEntry.HTML := Result;
  LEntry.FirstEquationNumber := LFirstNumber;
  LEntry.EquationNumbers := FEquationNumber - LFirstNumber;
  FCache.AddOrSetValue(LKey, LEntry);
end;

type
  TMathSourceKind = (skHTML, skMarkdown);

function StartsAt(const AText: string; const ASubText: string; const APosition: Integer): Boolean;
begin
  Result := (APosition >= 1) and (APosition + ASubText.Length - 1 <= AText.Length) and
    CompareMem(@AText[APosition], Pointer(ASubText), ASubText.Length * SizeOf(Char));
end;

function IsTagStart(const AText: string; const APosition: Integer): Boolean;
begin
  Result := (AText[APosition] = '<') and (APosition < AText.Length) and CharInSet(AText[APosition + 1], ['a'..'z', 'A'..'Z', '/', '!']);
end;

function TagNameOf(const ATag: string): string;
begin
  var LStart := 2;

  if (ATag.Length > 1) and (ATag[2] = '/') then
    LStart := 3;

  var LEnd := LStart;

  while (LEnd <= ATag.Length) and CharInSet(ATag[LEnd], ['a'..'z', 'A'..'Z', '0'..'9']) do
    Inc(LEnd);

  Result := LowerCase(Copy(ATag, LStart, LEnd - LStart));
end;

function IsSkippedElement(const AName: string): Boolean;
begin
  Result := (AName = 'code') or (AName = 'pre') or (AName = 'script') or (AName = 'style') or (AName = 'textarea');
end;

function ScanTag(const AHTML: string; const AIndex: Integer; var ASkipDepth: Integer): Integer;
begin
  Result := Pos('>', AHTML, AIndex);

  if Result = 0 then
    Result := AHTML.Length;

  var LTag := Copy(AHTML, AIndex, Result - AIndex + 1);

  if IsSkippedElement(TagNameOf(LTag)) then
  begin
    if LTag.StartsWith('</') then
      ASkipDepth := Max(0, ASkipDepth - 1)
    else
    if not LTag.EndsWith('/>') then
      Inc(ASkipDepth);
  end;
end;

function IsBlankLineAt(const AText: string; const APosition: Integer): Boolean;
begin
  if not CharInSet(AText[APosition], [#10, #13]) then
    Exit(False);

  var LPosition := APosition + 1;

  if (AText[APosition] = #13) and (LPosition <= AText.Length) and (AText[LPosition] = #10) then
    Inc(LPosition);

  while (LPosition <= AText.Length) and CharInSet(AText[LPosition], [' ', #9]) do
    Inc(LPosition);

  Result := (LPosition <= AText.Length) and CharInSet(AText[LPosition], [#10, #13]);
end;

function FindMathClose(const AText: string; const ADelimiter: string; const AStart: Integer; const ASingleDollar: Boolean;
  const ASourceKind: TMathSourceKind): Integer;
begin
  var LPosition := AStart;

  while LPosition <= AText.Length do
  begin
    if ((ASourceKind = skHTML) and IsTagStart(AText, LPosition)) or ((ASourceKind = skMarkdown) and IsBlankLineAt(AText, LPosition)) then
      Exit(0);

    if (AText[LPosition] = '\') and ASingleDollar then
    begin
      Inc(LPosition, 2);

      Continue;
    end;

    if StartsAt(AText, ADelimiter, LPosition) then
    begin
      if not ASingleDollar then
        Exit(LPosition);

      if (LPosition > AStart) and (AText[LPosition - 1] <> ' ') and
        ((LPosition = AText.Length) or not CharInSet(AText[LPosition + 1], ['0'..'9'])) then
        Exit(LPosition);
    end;

    Inc(LPosition);
  end;

  Result := 0;
end;

function TryFindMath(const AText: string; const AIndex: Integer; const ASourceKind: TMathSourceKind; out AFormula: TMathFormula;
  out AEndIndex: Integer): Boolean;

  function TryDelimiters(const AOpen: string; const AClose: string; const ADisplayMode: Boolean; const ASingleDollar: Boolean): Boolean;
  begin
    Result := False;

    if not StartsAt(AText, AOpen, AIndex) then
      Exit;

    if ASingleDollar and ((AIndex = AText.Length) or CharInSet(AText[AIndex + 1], [' ', #9, #10, #13])) then
      Exit;

    var LClose := FindMathClose(AText, AClose, AIndex + AOpen.Length, ASingleDollar, ASourceKind);

    if LClose = 0 then
      Exit;

    var LTeX := Copy(AText, AIndex + AOpen.Length, LClose - AIndex - AOpen.Length);

    if ASourceKind = skHTML then
      LTeX := DecodeHTMLEntities(LTeX);

    if LTeX.Trim.IsEmpty then
      Exit;

    AEndIndex := LClose + AClose.Length;
    AFormula.DisplayMode := ADisplayMode;
    AFormula.Source := Copy(AText, AIndex, AEndIndex - AIndex);
    AFormula.TeX := LTeX;

    Result := True;
  end;

begin
  Result := TryDelimiters('$$', '$$', True, False) or TryDelimiters('\[', '\]', True, False) or TryDelimiters('\(', '\)', False, False) or
    TryDelimiters('$', '$', False, True);
end;

function NextLineStart(const AText: string; const AIndex: Integer): Integer;
begin
  Result := AIndex;

  while (Result <= AText.Length) and not CharInSet(AText[Result], [#10, #13]) do
    Inc(Result);

  if (Result <= AText.Length) and (AText[Result] = #13) then
    Inc(Result);

  if (Result <= AText.Length) and (AText[Result] = #10) then
    Inc(Result);
end;

function BacktickRunLength(const AText: string; const AIndex: Integer): Integer;
begin
  Result := 0;

  while (AIndex + Result <= AText.Length) and (AText[AIndex + Result] = '`') do
    Inc(Result);
end;

function FencedCodeEnd(const AText: string; const AIndex: Integer; out AInfo: string; out AContentStart: Integer;
  out AContentEnd: Integer): Integer;

  function RestOfLineIsBlank(const APosition: Integer): Boolean;
  begin
    var LPosition := APosition;

    while (LPosition <= AText.Length) and CharInSet(AText[LPosition], [' ', #9]) do
      Inc(LPosition);

    Result := (LPosition > AText.Length) or CharInSet(AText[LPosition], [#10, #13]);
  end;

  function FenceLength(const ALineStart: Integer; out AFenceCharacter: Char; out AFenceEnd: Integer): Integer;
  begin
    var LPosition := ALineStart;

    while (LPosition <= AText.Length) and CharInSet(AText[LPosition], [' ', #9]) do
      Inc(LPosition);

    AFenceCharacter := #0;
    AFenceEnd := LPosition;

    if (LPosition > AText.Length) or not CharInSet(AText[LPosition], ['`', '~']) then
      Exit(0);

    AFenceCharacter := AText[LPosition];
    Result := 0;

    while (LPosition + Result <= AText.Length) and (AText[LPosition + Result] = AFenceCharacter) do
      Inc(Result);

    AFenceEnd := LPosition + Result;

    if Result < 3 then
      Result := 0;
  end;

begin
  AInfo := '';
  AContentStart := 0;
  AContentEnd := 0;

  var LOpenCharacter: Char;
  var LOpenEnd: Integer;
  var LOpenLength := FenceLength(AIndex, LOpenCharacter, LOpenEnd);

  if LOpenLength = 0 then
    Exit(0);

  var LLineStart := NextLineStart(AText, AIndex);
  var LInfo := Copy(AText, LOpenEnd, LLineStart - LOpenEnd).Trim;

  if (LOpenCharacter = '`') and LInfo.Contains('`') then
    Exit(0);

  var LSpace := LInfo.IndexOfAny([' ', #9]);

  AInfo := if LSpace < 0 then LInfo else LInfo.Substring(0, LSpace);
  AContentStart := LLineStart;

  var LCloseCharacter: Char;
  var LCloseEnd: Integer;

  while LLineStart <= AText.Length do
  begin
    if (FenceLength(LLineStart, LCloseCharacter, LCloseEnd) >= LOpenLength) and (LCloseCharacter = LOpenCharacter) and
      RestOfLineIsBlank(LCloseEnd) then
    begin
      AContentEnd := LLineStart;

      Exit(NextLineStart(AText, LLineStart));
    end;

    LLineStart := NextLineStart(AText, LLineStart);
  end;

  AContentEnd := AText.Length + 1;
  Result := AText.Length + 1;
end;

function CodeSpanEnd(const AText: string; const AIndex: Integer): Integer;
begin
  var LOpenLength := BacktickRunLength(AText, AIndex);
  var LPosition := AIndex + LOpenLength;
  var LCloseLength: Integer;

  while LPosition <= AText.Length do
  begin
    if IsBlankLineAt(AText, LPosition) then
      Exit(0);

    if AText[LPosition] = '`' then
    begin
      LCloseLength := BacktickRunLength(AText, LPosition);

      if LCloseLength = LOpenLength then
        Exit(LPosition + LCloseLength);

      Inc(LPosition, LCloseLength);

      Continue;
    end;

    Inc(LPosition);
  end;

  Result := 0;
end;

function SkippedElementEnd(const AText: string; const AIndex: Integer): Integer;
begin
  if not IsTagStart(AText, AIndex) or (AText[AIndex + 1] = '/') then
    Exit(0);

  var LTagEnd := Pos('>', AText, AIndex);

  if LTagEnd = 0 then
    Exit(0);

  var LTag := Copy(AText, AIndex, LTagEnd - AIndex + 1);
  var LName := TagNameOf(LTag);

  if not IsSkippedElement(LName) then
    Exit(0);

  if LTag.EndsWith('/>') then
    Exit(LTagEnd + 1);

  var LClose := Pos('</' + LName, LowerCase(AText), LTagEnd + 1);

  if LClose = 0 then
    Exit(AText.Length + 1);

  var LCloseEnd := Pos('>', AText, LClose);

  Result := if LCloseEnd = 0 then AText.Length + 1 else LCloseEnd + 1;
end;

function ExtractMathFromMarkdown(const AMarkdown: string; const AFormulas: TList<TMathFormula>): string;
var
  LBuilder: TStringBuilder;
  LContentEnd: Integer;
  LContentStart: Integer;
  LEndIndex: Integer;
  LFormula: TMathFormula;
  LIndex: Integer;
  LInfo: string;
  LPosition: Integer;
  LRunLength: Integer;

  procedure AppendPlaceholder;
  begin
    LBuilder.Append(MATH_PLACEHOLDER_START).Append(AFormulas.Count).Append(MATH_PLACEHOLDER_END);
    AFormulas.Add(LFormula);
  end;

begin
  LBuilder := TStringBuilder.Create(AMarkdown.Length);
  try
    LIndex := 1;

    while LIndex <= AMarkdown.Length do
    begin
      LEndIndex := 0;

      if (LIndex = 1) or CharInSet(AMarkdown[LIndex - 1], [#10, #13]) then
      begin
        LEndIndex := FencedCodeEnd(AMarkdown, LIndex, LInfo, LContentStart, LContentEnd);

        if (LEndIndex > 0) and (LContentEnd <= AMarkdown.Length) and SameText(LInfo, 'math') and
          not Copy(AMarkdown, LContentStart, LContentEnd - LContentStart).Trim.IsEmpty then
        begin
          LFormula.DisplayMode := True;
          LFormula.Source := Copy(AMarkdown, LIndex, LEndIndex - LIndex);
          LFormula.TeX := Copy(AMarkdown, LContentStart, LContentEnd - LContentStart).Trim;
          LPosition := LIndex;

          while (LPosition < LEndIndex) and CharInSet(AMarkdown[LPosition], [' ', #9]) do
            Inc(LPosition);

          LBuilder.Append(AMarkdown, LIndex - 1, LPosition - LIndex);
          AppendPlaceholder;

          LPosition := LEndIndex;

          while (LPosition > LIndex) and CharInSet(AMarkdown[LPosition - 1], [#10, #13]) do
            Dec(LPosition);

          LBuilder.Append(AMarkdown, LPosition - 1, LEndIndex - LPosition);
          LIndex := LEndIndex;

          Continue;
        end;
      end;

      if (LEndIndex = 0) and (AMarkdown[LIndex] = '$') and (LIndex < AMarkdown.Length) and (AMarkdown[LIndex + 1] = '`') then
      begin
        LPosition := CodeSpanEnd(AMarkdown, LIndex + 1);
        LRunLength := BacktickRunLength(AMarkdown, LIndex + 1);

        if (LPosition > 0) and (LPosition <= AMarkdown.Length) and (AMarkdown[LPosition] = '$') then
        begin
          LFormula.DisplayMode := False;
          LFormula.Source := Copy(AMarkdown, LIndex, LPosition + 1 - LIndex);
          LFormula.TeX := Copy(AMarkdown, LIndex + 1 + LRunLength, LPosition - LRunLength - (LIndex + 1 + LRunLength));

          if not LFormula.TeX.Trim.IsEmpty then
          begin
            AppendPlaceholder;
            LIndex := LPosition + 1;

            Continue;
          end;
        end;
      end;

      if LEndIndex = 0 then
      case AMarkdown[LIndex] of
        '`':
          begin
            LEndIndex := CodeSpanEnd(AMarkdown, LIndex);

            if LEndIndex = 0 then
              LEndIndex := LIndex + BacktickRunLength(AMarkdown, LIndex);
          end;
        '<':
          LEndIndex := SkippedElementEnd(AMarkdown, LIndex);
        '\':
          if (LIndex < AMarkdown.Length) and CharInSet(AMarkdown[LIndex + 1], ['\', '$']) then
            LEndIndex := LIndex + 2;
      end;

      if LEndIndex > 0 then
      begin
        LBuilder.Append(AMarkdown, LIndex - 1, LEndIndex - LIndex);
        LIndex := LEndIndex;

        Continue;
      end;

      if CharInSet(AMarkdown[LIndex], ['$', '\']) and TryFindMath(AMarkdown, LIndex, skMarkdown, LFormula, LEndIndex) then
      begin
        AppendPlaceholder;
        LIndex := LEndIndex;

        Continue;
      end;

      LBuilder.Append(AMarkdown[LIndex]);
      Inc(LIndex);
    end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TryReadPlaceholder(const AText: string; const AIndex: Integer; const AFormulas: TList<TMathFormula>;
  out AFormula: TMathFormula; out AEndIndex: Integer): Boolean;
var
  LFormulaIndex: Integer;
begin
  if AText[AIndex] <> MATH_PLACEHOLDER_START then
    Exit(False);

  var LPlaceholderEnd := Pos(MATH_PLACEHOLDER_END, AText, AIndex);

  Result := (LPlaceholderEnd > 0) and TryStrToInt(Copy(AText, AIndex + 1, LPlaceholderEnd - AIndex - 1), LFormulaIndex) and
    (LFormulaIndex >= 0) and (LFormulaIndex < AFormulas.Count);

  if Result then
  begin
    AFormula := AFormulas[LFormulaIndex];
    AEndIndex := LPlaceholderEnd + 1;
  end;
end;

function PlaceholdersToSource(const ATag: string; const AFormulas: TList<TMathFormula>): string;
var
  LEndIndex: Integer;
  LFormula: TMathFormula;
begin
  if Pos(MATH_PLACEHOLDER_START, ATag) = 0 then
    Exit(ATag);

  var LBuilder := TStringBuilder.Create(ATag.Length * 2);
  try
    var LIndex := 1;

    while LIndex <= ATag.Length do
    if TryReadPlaceholder(ATag, LIndex, AFormulas, LFormula, LEndIndex) then
    begin
      LBuilder.Append(EscapeHTML(LFormula.Source));
      LIndex := LEndIndex;
    end
    else
    begin
      LBuilder.Append(ATag[LIndex]);
      Inc(LIndex);
    end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TMathRenderer.InsertMath(const AHTML: string; const AFormulas: TList<TMathFormula>): string;
var
  LBuilder: TStringBuilder;
  LEndIndex: Integer;
  LFormula: TMathFormula;
  LIndex: Integer;
  LRunStart: Integer;
  LSkipDepth: Integer;
  LTagEnd: Integer;
begin
  FEquationNumber := 1;
  LBuilder := TStringBuilder.Create(AHTML.Length * 2);
  try
    LIndex := 1;
    LSkipDepth := 0;

    while LIndex <= AHTML.Length do
    begin
      LRunStart := LIndex;

      while (LIndex <= AHTML.Length) and (AHTML[LIndex] <> '<') and (AHTML[LIndex] <> MATH_PLACEHOLDER_START) do
        Inc(LIndex);

      if LIndex > LRunStart then
        LBuilder.Append(AHTML, LRunStart - 1, LIndex - LRunStart);

      if LIndex > AHTML.Length then
        Break;

      if IsTagStart(AHTML, LIndex) and (Pos('>', AHTML, LIndex) > 0) then
      begin
        LTagEnd := ScanTag(AHTML, LIndex, LSkipDepth);
        LBuilder.Append(PlaceholdersToSource(Copy(AHTML, LIndex, LTagEnd - LIndex + 1), AFormulas));
        LIndex := LTagEnd + 1;

        Continue;
      end;

      if TryReadPlaceholder(AHTML, LIndex, AFormulas, LFormula, LEndIndex) then
      begin
        LIndex := LEndIndex;

        if LSkipDepth > 0 then
          LBuilder.Append(EscapeHTML(LFormula.Source))
        else
        if LFormula.DisplayMode then
        begin
          if (LBuilder.Length >= 3) and (LBuilder.ToString(LBuilder.Length - 3, 3) = '<p>') and StartsAt(AHTML, '</p>', LIndex) then
          begin
            LBuilder.Length := LBuilder.Length - 3;
            Inc(LIndex, 4);
          end
          else
          if StartsAt(AHTML, '<br>', LIndex) then
            Inc(LIndex, 4);

          LBuilder.Append(RenderToHTML(LFormula.TeX, True));
        end
        else
          LBuilder.Append(RenderToHTML(LFormula.TeX));

        Continue;
      end;

      LBuilder.Append(AHTML[LIndex]);
      Inc(LIndex);
    end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TMathRenderer.ReplaceMathInHTML(const AHTML: string): string;
var
  LBuilder: TStringBuilder;
  LEndIndex: Integer;
  LFormula: TMathFormula;
  LIndex: Integer;
  LRunStart: Integer;
  LSkipDepth: Integer;
  LTagEnd: Integer;
begin
  FEquationNumber := 1;
  LBuilder := TStringBuilder.Create(AHTML.Length * 2);
  try
    LIndex := 1;
    LSkipDepth := 0;

    while LIndex <= AHTML.Length do
    begin
      LRunStart := LIndex;

      while (LIndex <= AHTML.Length) and not CharInSet(AHTML[LIndex], ['<', '$', '\']) do
        Inc(LIndex);

      if LIndex > LRunStart then
        LBuilder.Append(AHTML, LRunStart - 1, LIndex - LRunStart);

      if LIndex > AHTML.Length then
        Break;

      if IsTagStart(AHTML, LIndex) then
      begin
        LTagEnd := ScanTag(AHTML, LIndex, LSkipDepth);
        LBuilder.Append(AHTML, LIndex - 1, LTagEnd - LIndex + 1);
        LIndex := LTagEnd + 1;

        Continue;
      end;

      if LSkipDepth = 0 then
      begin
        if StartsAt(AHTML, '\$', LIndex) then
        begin
          LBuilder.Append('$');
          Inc(LIndex, 2);

          Continue;
        end;

        if TryFindMath(AHTML, LIndex, skHTML, LFormula, LEndIndex) then
        begin
          LBuilder.Append(RenderToHTML(LFormula.TeX, LFormula.DisplayMode));
          LIndex := LEndIndex;

          Continue;
        end;
      end;

      LBuilder.Append(AHTML[LIndex]);
      Inc(LIndex);
    end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TMathRenderer.ReplaceMathInMarkdown(const AMarkdown: string; const AConvertToHTML: TMathMarkdownConverter): string;
begin
  var LFormulas := TList<TMathFormula>.Create;
  try
    Result := InsertMath(AConvertToHTML(ExtractMathFromMarkdown(AMarkdown, LFormulas)), LFormulas);
  finally
    LFormulas.Free;
  end;
end;

end.
