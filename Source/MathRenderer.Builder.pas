unit MathRenderer.Builder;

interface

uses
  System.Generics.Collections, MathRenderer.Boxes, MathRenderer.FontMetrics, MathRenderer.Options, MathRenderer.Parser,
  MathRenderer.ParseTree, MathRenderer.Types;

type
  TMathMeasureTextFunction = reference to function(const AText: string; const AFont: TMathFont): Double;

  TMathRealGroup = (rgFalse, rgTrue, rgRoot);

  TMathVListPosition = (vpIndividualShift, vpTop, vpBottom, vpShift, vpFirstBaseline);

  TMathVListChild = record
    Element: TMathBox;
    IsKern: Boolean;
    MarginLeft: Double;
    MarginRight: Double;
    Shift: Double;
    Size: Double;
    class function Elem(const AElement: TMathBox; const AShift: Double = 0; const AMarginLeft: Double = 0;
      const AMarginRight: Double = 0): TMathVListChild; static;
    class function Kern(const ASize: Double): TMathVListChild; static;
  end;

  TMathDelimiterKind = (dkSmall, dkLarge, dkStack);

  TMathDelimiterType = record
    Kind: TMathDelimiterKind;
    Size: Integer;
    Style: TMathStyle;
  end;

  TMathTraversalLevel = class(TObject)
  public
    Index: Integer;
    Nodes: TMathBoxList;
  end;

  TMathTraversalPrevious = record
    InsertIndex: Integer;
    Level: TMathTraversalLevel;
    Node: TMathBox;
  end;

  TMathTraversalCallback = reference to function(const ANode: TMathBox; const APrevious: TMathBox): TMathBox;

  TMathBuilder = class(TObject)
  strict private
    FArena: TMathParseArena;
    FBoxes: TObjectList<TMathBox>;
    FEquationNumber: Integer;
    FLists: TObjectList<TMathBoxList>;
    FMeasureText: TMathMeasureTextFunction;
    FOptions: TMathOptionsList;
    FSettings: TMathSettings;
    FTag: TMathBox;
    function AssembleSupSub(const ABase: TMathBox; const ASupGroup: TMathParseNode; const ASubGroup: TMathParseNode;
      const AOptions: TMathOptions; const AStyle: TMathStyle; const ASlant: Double; const ABaseShift: Double): TMathBox;
    function BoldSymbolFont(const AValue: string; const AMode: TMathMode; const AIsMathOrd: Boolean; out AFontClass: string): TMathFont;
    function BuildAccent(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildAccentUnder(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildArray(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildAtom(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildCdLabel(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildCdLabelParent(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildDelimSizing(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildEnclose(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildEquationNumber(const AOptions: TMathOptions): TMathBox;
    function BuildExpression(const AExpression: TMathNodeList; const AOptions: TMathOptions; const ARealGroup: TMathRealGroup;
      const ALeftSurrounding: string = ''; const ARightSurrounding: string = ''): TMathBoxList;
    function BuildGenFrac(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildGroup(const AGroup: TMathParseNode; const AOptions: TMathOptions; const ABaseOptions: TMathOptions = nil): TMathBox;
    function BuildGroupByType(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildHorizBrace(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildLap(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildLeftRight(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildOp(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildOperatorName(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildOverline(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildRule(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildSmash(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildSpacing(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildSqrt(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildSupSub(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildText(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildUnderline(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildVerb(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function BuildXArrow(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function CanCombine(const APrevious: TMathSymbolBox; const ANext: TMathSymbolBox): Boolean;
    function ComputeAdvances(const AText: string; const AFont: TMathFont): TArray<Double>;
    function GetDelimiterMetrics(const ASymbol: string; const AFont: TMathFont; out AHeight: Double; out ADepth: Double;
      out AWidth: Double): Boolean;
    function GetTypeOfBox(const ABox: TMathBox; const ARightSide: Boolean = False; const AUseSide: Boolean = False): string;
    function LookupSymbol(const AValue: string; const AFont: TMathFont; const AMode: TMathMode; out AReplaced: string;
      out AMetrics: TMathCharacterMetrics): Boolean;
    function MakeCustomSizedDelim(const ADelimiter: string; const AHeight: Double; const ACenter: Boolean; const AOptions: TMathOptions;
      const AMode: TMathMode; const AClasses: array of string): TMathBox;
    function MakeFragment(const AChildren: TMathBoxList): TMathSpanBox;
    function MakeGlue(const AMeasurement: TMathMeasurement; const AOptions: TMathOptions): TMathBox;
    function MakeLargeDelim(const ADelimiter: string; const ASize: Integer; const ACenter: Boolean;
      const AOptions: TMathOptions; const AMode: TMathMode; const AClasses: array of string): TMathBox;
    function MakeLeftRightDelim(const ADelimiter: string; const AHeight: Double; const ADepth: Double;
      const AOptions: TMathOptions; const AMode: TMathMode; const AClasses: array of string): TMathBox;
    function MakeLineSpan(const AClassName: string; const AOptions: TMathOptions; const AThickness: Double = 0): TMathRuleBox;
    function MakeList: TMathBoxList; overload;
    function MakeList(const ABoxes: array of TMathBox): TMathBoxList; overload;
    function MakeNullDelimiter(const AOptions: TMathOptions; const AClasses: array of string): TMathBox;
    function MakeOrd(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
    function MakeSizedDelim(const ADelimiter: string; const ASize: Integer; const AOptions: TMathOptions; const AMode: TMathMode;
      const AClasses: array of string): TMathBox;
    function MakeSmallDelim(const ADelimiter: string; const AStyle: TMathStyle; const ACenter: Boolean; const AOptions: TMathOptions;
      const AMode: TMathMode; const AClasses: array of string): TMathBox;
    function MakeSpan(const AClasses: array of string; const AChildren: array of TMathBox; const AOptions: TMathOptions = nil): TMathSpanBox; overload;
    function MakeSpan(const AClasses: array of string; const AChildren: TMathBoxList; const AOptions: TMathOptions = nil): TMathSpanBox; overload;
    function MakeStaticSvg(const AName: string; const AOptions: TMathOptions): TMathSvgBox;
    function MakeStretchySvg(const ALabel: string; const ABase: TMathParseNode; const AOptions: TMathOptions): TMathSvgBox;
    function MakeSqrtImage(const AHeight: Double; const AOptions: TMathOptions; out ARuleWidth: Double; out AAdvanceWidth: Double): TMathSurdBox;
    function MakeStackedDelim(const ADelimiter: string; const AHeightTotal: Double; const ACenter: Boolean; const AOptions: TMathOptions;
      const AMode: TMathMode; const AClasses: array of string): TMathBox;
    function MakeSymbol(const AValue: string; const AFont: TMathFont; const AMode: TMathMode; const AOptions: TMathOptions;
      const AClasses: array of string): TMathSymbolBox;
    function MakeVList(const APosition: TMathVListPosition; const APositionData: Double; const AChildren: array of TMathVListChild;
      const AOptions: TMathOptions): TMathVListBox;
    function MathSym(const AValue: string; const AMode: TMathMode; const AOptions: TMathOptions; const AClasses: array of string): TMathSymbolBox;
    function NewBox<T: TMathBox>(const ABox: T): T;
    function SizingGroup(const AValue: TMathNodeList; const AOptions: TMathOptions; const ABaseOptions: TMathOptions): TMathBox;
    function StyleWrap(const ADelimiter: TMathBox; const AToStyle: TMathStyle; const AOptions: TMathOptions; const AClasses: array of string): TMathSpanBox;
    function TraverseSequence(const ADelimiter: string; const AHeight: Double; const ASequence: array of TMathDelimiterType;
      const AOptions: TMathOptions): TMathDelimiterType;
    function WrapFragment(const AGroup: TMathBox; const AOptions: TMathOptions): TMathBox;
    procedure ApplySizingClasses(const ABox: TMathBox; const ANewOptions: TMathOptions; const AOldOptions: TMathOptions);
    procedure CenterSpan(const ASpan: TMathBox; const AOptions: TMathOptions; const AStyle: TMathStyle);
    procedure TraverseNonSpaceNodes(const ANodes: TMathBoxList; const ACallback: TMathTraversalCallback; var APrevious: TMathTraversalPrevious;
      const ANext: TMathBox; const AIsRoot: Boolean; const ALevels: TObjectList<TMathTraversalLevel>);
    procedure TryCombineChars(const AChars: TMathBoxList);
  public
    constructor Create(const AArena: TMathParseArena; const ASettings: TMathSettings; const AMeasureText: TMathMeasureTextFunction);
    destructor Destroy; override;
    function Build(const ATree: TMathNodeList): TMathBox;
    property EquationNumber: Integer read FEquationNumber write FEquationNumber;
    property Tag: TMathBox read FTag;
  end;

implementation

uses
  System.Math, System.SysUtils, MathRenderer.SvgData, MathRenderer.Symbols;

type
  TMathStretchyImage = record
    Name: string;
    Paths: array [0..2] of string;
    MinWidth: Double;
    ViewBoxHeight: Double;
    Align: TMathSvgAlign;
  end;

const
  STRETCHY_IMAGES: array [0..41] of TMathStretchyImage = (
    (Name: 'overrightarrow'; Paths: ('rightarrow', '', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMax),
    (Name: 'underrightarrow'; Paths: ('rightarrow', '', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMax),
    (Name: 'overleftarrow'; Paths: ('leftarrow', '', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMin),
    (Name: 'underleftarrow'; Paths: ('leftarrow', '', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMin),
    (Name: 'xrightarrow'; Paths: ('rightarrow', '', ''); MinWidth: 1.469; ViewBoxHeight: 522; Align: saMax),
    (Name: 'xleftarrow'; Paths: ('leftarrow', '', ''); MinWidth: 1.469; ViewBoxHeight: 522; Align: saMin),
    (Name: 'Overrightarrow'; Paths: ('doublerightarrow', '', ''); MinWidth: 0.888; ViewBoxHeight: 560; Align: saMax),
    (Name: 'xRightarrow'; Paths: ('doublerightarrow', '', ''); MinWidth: 1.526; ViewBoxHeight: 560; Align: saMax),
    (Name: 'xLeftarrow'; Paths: ('doubleleftarrow', '', ''); MinWidth: 1.526; ViewBoxHeight: 560; Align: saMin),
    (Name: 'overleftharpoon'; Paths: ('leftharpoon', '', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMin),
    (Name: 'xleftharpoonup'; Paths: ('leftharpoon', '', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMin),
    (Name: 'xleftharpoondown'; Paths: ('leftharpoondown', '', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMin),
    (Name: 'overrightharpoon'; Paths: ('rightharpoon', '', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMax),
    (Name: 'xrightharpoonup'; Paths: ('rightharpoon', '', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMax),
    (Name: 'xrightharpoondown'; Paths: ('rightharpoondown', '', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMax),
    (Name: 'xlongequal'; Paths: ('longequal', '', ''); MinWidth: 0.888; ViewBoxHeight: 334; Align: saMin),
    (Name: 'xtwoheadleftarrow'; Paths: ('twoheadleftarrow', '', ''); MinWidth: 0.888; ViewBoxHeight: 334; Align: saMin),
    (Name: 'xtwoheadrightarrow'; Paths: ('twoheadrightarrow', '', ''); MinWidth: 0.888; ViewBoxHeight: 334; Align: saMax),
    (Name: 'overleftrightarrow'; Paths: ('leftarrow', 'rightarrow', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMin),
    (Name: 'underleftrightarrow'; Paths: ('leftarrow', 'rightarrow', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMin),
    (Name: 'overbrace'; Paths: ('leftbrace', 'midbrace', 'rightbrace'); MinWidth: 1.6; ViewBoxHeight: 548; Align: saMin),
    (Name: 'underbrace'; Paths: ('leftbraceunder', 'midbraceunder', 'rightbraceunder'); MinWidth: 1.6; ViewBoxHeight: 548; Align: saMin),
    (Name: 'xleftrightarrow'; Paths: ('leftarrow', 'rightarrow', ''); MinWidth: 1.75; ViewBoxHeight: 522; Align: saMin),
    (Name: 'xLeftrightarrow'; Paths: ('doubleleftarrow', 'doublerightarrow', ''); MinWidth: 1.75; ViewBoxHeight: 560; Align: saMin),
    (Name: 'xrightleftharpoons'; Paths: ('leftharpoondownplus', 'rightharpoonplus', ''); MinWidth: 1.75; ViewBoxHeight: 716; Align: saMin),
    (Name: 'xleftrightharpoons'; Paths: ('leftharpoonplus', 'rightharpoondownplus', ''); MinWidth: 1.75; ViewBoxHeight: 716; Align: saMin),
    (Name: 'xhookleftarrow'; Paths: ('leftarrow', 'righthook', ''); MinWidth: 1.08; ViewBoxHeight: 522; Align: saMin),
    (Name: 'xhookrightarrow'; Paths: ('lefthook', 'rightarrow', ''); MinWidth: 1.08; ViewBoxHeight: 522; Align: saMin),
    (Name: 'overlinesegment'; Paths: ('leftlinesegment', 'rightlinesegment', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMin),
    (Name: 'underlinesegment'; Paths: ('leftlinesegment', 'rightlinesegment', ''); MinWidth: 0.888; ViewBoxHeight: 522; Align: saMin),
    (Name: 'overbracket'; Paths: ('leftbracketover', 'rightbracketover', ''); MinWidth: 1.6; ViewBoxHeight: 440; Align: saMin),
    (Name: 'underbracket'; Paths: ('leftbracketunder', 'rightbracketunder', ''); MinWidth: 1.6; ViewBoxHeight: 410; Align: saMin),
    (Name: 'overgroup'; Paths: ('leftgroup', 'rightgroup', ''); MinWidth: 0.888; ViewBoxHeight: 342; Align: saMin),
    (Name: 'undergroup'; Paths: ('leftgroupunder', 'rightgroupunder', ''); MinWidth: 0.888; ViewBoxHeight: 342; Align: saMin),
    (Name: 'xmapsto'; Paths: ('leftmapsto', 'rightarrow', ''); MinWidth: 1.5; ViewBoxHeight: 522; Align: saMin),
    (Name: 'xtofrom'; Paths: ('leftToFrom', 'rightToFrom', ''); MinWidth: 1.75; ViewBoxHeight: 528; Align: saMin),
    (Name: 'xrightleftarrows'; Paths: ('baraboveleftarrow', 'rightarrowabovebar', ''); MinWidth: 1.75; ViewBoxHeight: 901; Align: saMin),
    (Name: 'xrightequilibrium'; Paths: ('baraboveshortleftharpoon', 'rightharpoonaboveshortbar', ''); MinWidth: 1.75; ViewBoxHeight: 716; Align: saMin),
    (Name: 'xleftequilibrium'; Paths: ('shortbaraboveleftharpoon', 'shortrightharpoonabovebar', ''); MinWidth: 1.75; ViewBoxHeight: 716; Align: saMin),
    (Name: '\cdrightarrow'; Paths: ('rightarrow', '', ''); MinWidth: 3.0; ViewBoxHeight: 522; Align: saMax),
    (Name: '\cdleftarrow'; Paths: ('leftarrow', '', ''); MinWidth: 3.0; ViewBoxHeight: 522; Align: saMin),
    (Name: '\cdlongequal'; Paths: ('longequal', '', ''); MinWidth: 3.0; ViewBoxHeight: 334; Align: saMin));

  CLASS_MATH_NORMAL = 'mathnormal';
  CLASS_SIZING = 'katex-sizing';
  CLASS_TIGHT = 'mtight';

  SIZE_TO_MAX_HEIGHT: array [0..4] of Double = (0, 1.2, 1.8, 2.4, 3.0);

  LAP_IN_EMS = 0.008;
  LINE_HEIGHT = 1.2;
  VEC_WIDTH = 0.471;

  STACK_LARGE_DELIMITERS: array [0..20] of string = ('(', '\lparen', ')', '\rparen', '[', '\lbrack', ']', '\rbrack', '\{',
    '\lbrace', '\}', '\rbrace', '\lfloor', '\rfloor', #$230A, #$230B, '\lceil', '\rceil', #$2308, #$2309, '\surd');
  STACK_ALWAYS_DELIMITERS: array [0..21] of string = ('\uparrow', '\downarrow', '\updownarrow', '\Uparrow', '\Downarrow',
    '\Updownarrow', '|', '\|', '\vert', '\Vert', '\lvert', '\rvert', '\lVert', '\rVert', '\lgroup', '\rgroup', #$27EE,
    #$27EF, '\lmoustache', '\rmoustache', #$23B0, #$23B1);
  STACK_NEVER_DELIMITERS: array [0..7] of string = ('<', '>', '\langle', '\rangle', '/', '\backslash', '\lt', '\gt');

function IsInList(const AText: string; const AList: array of string): Boolean;
begin
  for var LIndex := Low(AList) to High(AList) do
  if AList[LIndex] = AText then
    Exit(True);

  Result := False;
end;

function DelimiterType(const AKind: TMathDelimiterKind; const AStyleOrSize: Integer): TMathDelimiterType;
begin
  Result.Kind := AKind;
  Result.Size := 0;
  Result.Style := TMathStyle.Text;

  if AKind = dkSmall then
    Result.Style := TMathStyle.Create(AStyleOrSize)
  else
  if AKind = dkLarge then
    Result.Size := AStyleOrSize;
end;

function StackNeverDelimiterSequence: TArray<TMathDelimiterType>;
begin
  Result := [DelimiterType(dkSmall, TMathStyle.ScriptScript.Id), DelimiterType(dkSmall, TMathStyle.Script.Id),
    DelimiterType(dkSmall, TMathStyle.Text.Id), DelimiterType(dkLarge, 1), DelimiterType(dkLarge, 2),
    DelimiterType(dkLarge, 3), DelimiterType(dkLarge, 4)];
end;

function StackAlwaysDelimiterSequence: TArray<TMathDelimiterType>;
begin
  Result := [DelimiterType(dkSmall, TMathStyle.ScriptScript.Id), DelimiterType(dkSmall, TMathStyle.Script.Id),
    DelimiterType(dkSmall, TMathStyle.Text.Id), DelimiterType(dkStack, 0)];
end;

function StackLargeDelimiterSequence: TArray<TMathDelimiterType>;
begin
  Result := [DelimiterType(dkSmall, TMathStyle.ScriptScript.Id), DelimiterType(dkSmall, TMathStyle.Script.Id),
    DelimiterType(dkSmall, TMathStyle.Text.Id), DelimiterType(dkLarge, 1), DelimiterType(dkLarge, 2),
    DelimiterType(dkLarge, 3), DelimiterType(dkLarge, 4), DelimiterType(dkStack, 0)];
end;

function StyleFromName(const AName: TMathStyleName): TMathStyle;
begin
  case AName of
    snDisplay:
      Result := TMathStyle.Display;
    snScript:
      Result := TMathStyle.Script;
    snScriptScript:
      Result := TMathStyle.ScriptScript;
  else
    Result := TMathStyle.Text;
  end;
end;

function SizeFont(const ASize: Integer): TMathFont;
begin
  case ASize of
    1: Result := mfSize1Regular;
    2: Result := mfSize2Regular;
    3: Result := mfSize3Regular;
  else
    Result := mfSize4Regular;
  end;
end;

function MathFontFromName(const AName: string): TMathFont;
begin
  if AName = 'mathbf' then
    Result := mfMainBold
  else
  if AName = 'mathrm' then
    Result := mfMainRegular
  else
  if (AName = 'textit') or (AName = 'mathit') then
    Result := mfMainItalic
  else
  if AName = 'mathnormal' then
    Result := mfMathItalic
  else
  if AName = 'mathsfit' then
    Result := mfSansSerifItalic
  else
  if AName = 'mathbb' then
    Result := mfAMSRegular
  else
  if AName = 'mathcal' then
    Result := mfCaligraphicRegular
  else
  if AName = 'mathfrak' then
    Result := mfFrakturRegular
  else
  if AName = 'mathscr' then
    Result := mfScriptRegular
  else
  if AName = 'mathsf' then
    Result := mfSansSerifRegular
  else
  if AName = 'mathtt' then
    Result := mfTypewriterRegular
  else
    Result := mfNone;
end;

function RetrieveTextFontName(const AFontFamily: string; const AFontWeight: string; const AFontShape: string): TMathFont;
var
  LBold: Boolean;
  LItalic: Boolean;
begin
  LBold := AFontWeight = 'textbf';
  LItalic := AFontShape = 'textit';

  if AFontFamily = 'amsrm' then
    Result := mfAMSRegular
  else
  if AFontFamily = 'textsf' then
  begin
    if LBold then
      Result := mfSansSerifBold
    else
    if LItalic then
      Result := mfSansSerifItalic
    else
      Result := mfSansSerifRegular;
  end
  else
  if AFontFamily = 'texttt' then
    Result := mfTypewriterRegular
  else
  if LBold and LItalic then
    Result := mfMainBoldItalic
  else
  if LBold then
    Result := mfMainBold
  else
  if LItalic then
    Result := mfMainItalic
  else
    Result := mfMainRegular;
end;

{ TMathVListChild }

class function TMathVListChild.Elem(const AElement: TMathBox; const AShift: Double = 0; const AMarginLeft: Double = 0;
  const AMarginRight: Double = 0): TMathVListChild;
begin
  Result.Element := AElement;
  Result.IsKern := False;
  Result.Shift := AShift;
  Result.MarginLeft := AMarginLeft;
  Result.MarginRight := AMarginRight;
  Result.Size := 0;
end;

class function TMathVListChild.Kern(const ASize: Double): TMathVListChild;
begin
  Result.Element := nil;
  Result.IsKern := True;
  Result.Size := ASize;
  Result.Shift := 0;
  Result.MarginLeft := 0;
  Result.MarginRight := 0;
end;

{ TMathBuilder }

constructor TMathBuilder.Create(const AArena: TMathParseArena; const ASettings: TMathSettings;
  const AMeasureText: TMathMeasureTextFunction);
begin
  inherited Create;

  FArena := AArena;
  FSettings := ASettings;
  FMeasureText := AMeasureText;
  FEquationNumber := 1;
  FBoxes := TObjectList<TMathBox>.Create(True);
  FLists := TObjectList<TMathBoxList>.Create(True);
  FOptions := TMathOptionsList.Create(True);
end;

destructor TMathBuilder.Destroy;
begin
  FOptions.Free;
  FLists.Free;
  FBoxes.Free;

  inherited Destroy;
end;

function TMathBuilder.Build(const ATree: TMathNodeList): TMathBox;
begin
  FTag := nil;

  var LStyle := if FSettings.DisplayMode then TMathStyle.Display else TMathStyle.Text;
  var LOptions := TMathOptions.Create(FOptions, LStyle, FSettings.MaxSize, FSettings.MinRuleThickness);
  var LTree := ATree;
  var LTagNodes: TMathNodeList := nil;

  if (LTree.Count = 1) and (LTree[0].NodeType = ntTag) then
  begin
    LTagNodes := LTree[0].TagBody;
    LTree := LTree[0].Body;
  end;

  var LExpression := BuildExpression(LTree, LOptions, rgRoot);

  if (LExpression.Count = 2) and (bfTag in LExpression[1].Flags) then
  begin
    FTag := LExpression[1];
    LExpression.Delete(1);
  end;

  if Assigned(LTagNodes) then
  begin
    FTag := MakeSpan([], BuildExpression(LTagNodes, LOptions, rgTrue), LOptions);
    FTag.Flags := [bfTag];
  end;

  var LLines := MakeList;
  var LLine := MakeList;
  var LLineMarginTop: Double := 0;
  var LLineMarginTops: TArray<Double> := nil;

  for var LIndex := 0 to LExpression.Count - 1 do
  if bfNewLine in LExpression[LIndex].Flags then
  begin
    LLines.Add(MakeSpan(['katex-base'], LLine));
    LLineMarginTops := LLineMarginTops + [LLineMarginTop];
    LLineMarginTop := LExpression[LIndex].MarginTop;
    LLine := MakeList;
  end
  else
    LLine.Add(LExpression[LIndex]);

  if LLines.Count = 0 then
    Exit(MakeSpan(['katex-html'], LLine));

  LLines.Add(MakeSpan(['katex-base'], LLine));
  LLineMarginTops := LLineMarginTops + [LLineMarginTop];

  var LStack := NewBox(TMathVListBox.Create(['katex-html']));

  LStack.Alignment := if FSettings.DisplayMode then vaCenter else vaLeft;

  var LBaseline: Double := 0;
  var LLineBox: TMathBox;
  var LItem: TMathVListItem;

  for var LIndex := 0 to LLines.Count - 1 do
  begin
    LLineBox := LLines[LIndex];

    if LIndex > 0 then
      LBaseline := LBaseline - Max(LINE_HEIGHT, LLines[LIndex - 1].Depth + LLineBox.Height) - LLineMarginTops[LIndex];

    LItem := Default(TMathVListItem);
    LItem.Element := LLineBox;
    LItem.Baseline := LBaseline;
    LStack.Items.Add(LItem);
  end;

  LStack.Height := LLines[0].Height;
  LStack.Depth := LLines.Last.Depth - LBaseline;

  Result := LStack;
end;

function TMathBuilder.NewBox<T>(const ABox: T): T;
begin
  FBoxes.Add(ABox);

  Result := ABox;
end;

function TMathBuilder.MakeList: TMathBoxList;
begin
  Result := TMathBoxList.Create;
  FLists.Add(Result);
end;

function TMathBuilder.MakeList(const ABoxes: array of TMathBox): TMathBoxList;
begin
  Result := MakeList;

  for var LIndex := Low(ABoxes) to High(ABoxes) do
    Result.Add(ABoxes[LIndex]);
end;

function TMathBuilder.LookupSymbol(const AValue: string; const AFont: TMathFont; const AMode: TMathMode;
  out AReplaced: string; out AMetrics: TMathCharacterMetrics): Boolean;
var
  LSymbol: PMathSymbolDefinition;
begin
  AReplaced := AValue;

  if FindSymbol(AMode, AValue, LSymbol) and not LSymbol.Replace.IsEmpty then
    AReplaced := LSymbol.Replace;

  Result := GetCharacterMetrics(AReplaced, AFont, AMode, AMetrics);
end;

function TMathBuilder.ComputeAdvances(const AText: string; const AFont: TMathFont): TArray<Double>;
begin
  Result := nil;

  var LIndex := 1;
  var LCharacter: string;

  while LIndex <= AText.Length do
  begin
    if (Ord(AText[LIndex]) >= $D800) and (Ord(AText[LIndex]) <= $DBFF) and (LIndex < AText.Length) then
      LCharacter := Copy(AText, LIndex, 2)
    else
      LCharacter := AText[LIndex];

    Result := Result + [FMeasureText(LCharacter, AFont)];

    if LCharacter.Length = 2 then
      Result := Result + [0];

    Inc(LIndex, LCharacter.Length);
  end;
end;

function TMathBuilder.MakeSymbol(const AValue: string; const AFont: TMathFont; const AMode: TMathMode; const AOptions: TMathOptions;
  const AClasses: array of string): TMathSymbolBox;
var
  LReplaced: string;
  LMetrics: TMathCharacterMetrics;
begin
  Result := NewBox(TMathSymbolBox.Create(AClasses));

  if LookupSymbol(AValue, AFont, AMode, LReplaced, LMetrics) then
  begin
    Result.Height := LMetrics.Height;
    Result.Depth := LMetrics.Depth;
    Result.Italic := if (AMode = mmText) or (AOptions.Font = 'mathit') then 0 else LMetrics.Italic;
    Result.Skew := LMetrics.Skew;
  end;

  Result.Text := LReplaced;
  Result.Font := AFont;
  Result.Advances := ComputeAdvances(LReplaced, AFont);
  Result.MaxFontSize := AOptions.SizeMultiplier;

  if AOptions.Style.IsTight then
    Result.AddClass(CLASS_TIGHT);

  Result.Color := AOptions.GetColor;
end;

function TMathBuilder.MathSym(const AValue: string; const AMode: TMathMode; const AOptions: TMathOptions;
  const AClasses: array of string): TMathSymbolBox;
var
  LReplaced: string;
  LMetrics: TMathCharacterMetrics;
  LSymbol: PMathSymbolDefinition;
begin
  if (AOptions.Font = 'boldsymbol') and LookupSymbol(AValue, mfMainBold, AMode, LReplaced, LMetrics) then
  begin
    Result := MakeSymbol(AValue, mfMainBold, AMode, AOptions, AClasses);
    Result.AddClass('mathbf');
  end
  else
  if (AValue = '\') or not FindSymbol(AMode, AValue, LSymbol) or (LSymbol.Font = sfMain) then
    Result := MakeSymbol(AValue, mfMainRegular, AMode, AOptions, AClasses)
  else
  begin
    Result := MakeSymbol(AValue, mfAMSRegular, AMode, AOptions, AClasses);
    Result.AddClass('amsrm');
  end;
end;

function TMathBuilder.BoldSymbolFont(const AValue: string; const AMode: TMathMode; const AIsMathOrd: Boolean;
  out AFontClass: string): TMathFont;
var
  LReplaced: string;
  LMetrics: TMathCharacterMetrics;
begin
  if AIsMathOrd and LookupSymbol(AValue, mfMathBoldItalic, AMode, LReplaced, LMetrics) then
  begin
    AFontClass := 'boldsymbol';

    Exit(mfMathBoldItalic);
  end;

  AFontClass := 'mathbf';

  Result := mfMainBold;
end;

function TMathBuilder.MakeOrd(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
var
  LMode: TMathMode;

  function MakeOrdSymbol(const AValue: string; const AFont: TMathFont; const AExtraClasses: array of string): TMathSymbolBox;
  begin
    var LClasses: TArray<string> := [MATH_CLASS_ORD];

    for var LIndex := Low(AExtraClasses) to High(AExtraClasses) do
      LClasses := LClasses + [AExtraClasses[LIndex]];

    Result := MakeSymbol(AValue, AFont, LMode, AOptions, LClasses);
  end;

begin
  LMode := AGroup.Mode;

  var LIsMathOrd := AGroup.NodeType = ntMathOrd;
  var LText := AGroup.Text;
  var LUseFont := (LMode = mmMath) or ((LMode = mmText) and not AOptions.Font.IsEmpty);
  var LFontOrFamily := if LUseFont then AOptions.Font else AOptions.FontFamily;
  var LFontName: TMathFont;
  var LFontClasses: TArray<string>;
  var LFontClass: string;

  if not LFontOrFamily.IsEmpty then
  begin
    if LFontOrFamily = 'boldsymbol' then
    begin
      LFontName := BoldSymbolFont(LText, LMode, LIsMathOrd, LFontClass);
      LFontClasses := [LFontClass];
    end
    else
    if LUseFont then
    begin
      LFontName := MathFontFromName(AOptions.Font);
      LFontClasses := [AOptions.Font];
    end
    else
    begin
      LFontName := RetrieveTextFontName(AOptions.FontFamily, AOptions.FontWeight, AOptions.FontShape);
      LFontClasses := [AOptions.FontFamily, AOptions.FontWeight, AOptions.FontShape];
    end;

    var LReplaced: string;
    var LMetrics: TMathCharacterMetrics;

    if (LFontName <> mfNone) and LookupSymbol(LText, LFontName, LMode, LReplaced, LMetrics) then
      Exit(MakeOrdSymbol(LText, LFontName, LFontClasses))
    else
    if IsLigature(LText) and (LFontName = mfTypewriterRegular) then
    begin
      var LParts := MakeList;

      for var LIndex := 1 to LText.Length do
        LParts.Add(MakeOrdSymbol(LText[LIndex], LFontName, LFontClasses));

      Exit(MakeFragment(LParts));
    end;
  end;

  if LIsMathOrd then
    Exit(MakeOrdSymbol(LText, mfMathItalic, [CLASS_MATH_NORMAL]));

  var LSymbol: PMathSymbolDefinition;

  if FindSymbol(LMode, LText, LSymbol) and (LSymbol.Font = sfAMS) then
  begin
    var LSymbolBox := MakeOrdSymbol(LText, RetrieveTextFontName('amsrm', AOptions.FontWeight, AOptions.FontShape),
      ['amsrm', AOptions.FontWeight, AOptions.FontShape]);

    Exit(LSymbolBox);
  end;

  Result := MakeOrdSymbol(LText, RetrieveTextFontName('textrm', AOptions.FontWeight, AOptions.FontShape),
    [AOptions.FontWeight, AOptions.FontShape]);
end;

function TMathBuilder.CanCombine(const APrevious: TMathSymbolBox; const ANext: TMathSymbolBox): Boolean;
begin
  if (APrevious.ClassText <> ANext.ClassText) or (APrevious.Skew <> ANext.Skew) or
    (APrevious.MaxFontSize <> ANext.MaxFontSize) or ((APrevious.Italic <> 0) and APrevious.HasClass(CLASS_MATH_NORMAL)) then
    Exit(False);

  if APrevious.ClassCount = 1 then
  begin
    var LClassName := APrevious.FirstClass;

    if (LClassName = MATH_CLASS_BIN) or (LClassName = MATH_CLASS_ORD) then
      Exit(False);
  end;

  Result := (APrevious.Font = ANext.Font) and APrevious.Color.IsEqual(ANext.Color) and (APrevious.Scale = ANext.Scale) and
    (APrevious.ShiftX = ANext.ShiftX) and (APrevious.ShiftY = ANext.ShiftY);
end;

procedure TMathBuilder.TryCombineChars(const AChars: TMathBoxList);
var
  LPrevious: TMathSymbolBox;
  LNext: TMathSymbolBox;
begin
  var LIndex := 0;

  while LIndex < AChars.Count - 1 do
  begin
    if (AChars[LIndex] is TMathSymbolBox) and (AChars[LIndex + 1] is TMathSymbolBox) then
    begin
      LPrevious := TMathSymbolBox(AChars[LIndex]);
      LNext := TMathSymbolBox(AChars[LIndex + 1]);

      if CanCombine(LPrevious, LNext) then
      begin
        LPrevious.Append(LNext);
        LPrevious.Height := Max(LPrevious.Height, LNext.Height);
        LPrevious.Depth := Max(LPrevious.Depth, LNext.Depth);
        LPrevious.Italic := LNext.Italic;
        AChars.Delete(LIndex + 1);

        Continue;
      end;
    end;

    Inc(LIndex);
  end;
end;

function TMathBuilder.MakeSpan(const AClasses: array of string; const AChildren: TMathBoxList; const AOptions: TMathOptions = nil): TMathSpanBox;
begin
  Result := NewBox(TMathSpanBox.Create(AClasses));

  if Assigned(AChildren) then
    Result.Children.AddRange(AChildren);

  if Assigned(AOptions) and AOptions.Style.IsTight then
    Result.AddClass(CLASS_TIGHT);

  Result.SizeFromChildren;
end;

function TMathBuilder.MakeSpan(const AClasses: array of string; const AChildren: array of TMathBox; const AOptions: TMathOptions = nil): TMathSpanBox;
begin
  Result := MakeSpan(AClasses, MakeList(AChildren), AOptions);
end;

function TMathBuilder.MakeFragment(const AChildren: TMathBoxList): TMathSpanBox;
begin
  Result := MakeSpan([], AChildren);
  Result.IsFragment := True;
end;

function TMathBuilder.WrapFragment(const AGroup: TMathBox; const AOptions: TMathOptions): TMathBox;
begin
  if (AGroup is TMathSpanBox) and TMathSpanBox(AGroup).IsFragment then
    Result := MakeSpan([], [AGroup], AOptions)
  else
    Result := AGroup;
end;

function TMathBuilder.MakeLineSpan(const AClassName: string; const AOptions: TMathOptions; const AThickness: Double = 0): TMathRuleBox;
begin
  Result := NewBox(TMathRuleBox.Create([AClassName]));

  if AOptions.Style.IsTight then
    Result.AddClass(CLASS_TIGHT);

  Result.Height := Max(if AThickness <> 0 then AThickness else AOptions.FontMetrics.DefaultRuleThickness, AOptions.MinRuleThickness);
  Result.StretchWidth := True;
  Result.Color := AOptions.GetColor;
end;

function TMathBuilder.MakeGlue(const AMeasurement: TMathMeasurement; const AOptions: TMathOptions): TMathBox;
begin
  Result := MakeSpan([], [], AOptions);
  Result.Flags := [bfSpace];
  Result.MarginRight := CalculateSize(AMeasurement, AOptions);
end;

procedure TMathBuilder.ApplySizingClasses(const ABox: TMathBox; const ANewOptions: TMathOptions; const AOldOptions: TMathOptions);
begin
  if ANewOptions.Size <> AOldOptions.Size then
  begin
    ABox.AddClass(CLASS_SIZING);
    ABox.Scale := ABox.Scale * ANewOptions.SizeMultiplier / AOldOptions.SizeMultiplier;
  end;
end;

function TMathBuilder.MakeVList(const APosition: TMathVListPosition; const APositionData: Double; const AChildren: array of TMathVListChild;
  const AOptions: TMathOptions): TMathVListBox;
begin
  var LChildren: TArray<TMathVListChild> := nil;
  var LDepth: Double;
  var LCurrentPosition: Double;

  if APosition = vpIndividualShift then
  begin
    LChildren := [AChildren[0]];
    LDepth := -AChildren[0].Shift - AChildren[0].Element.Depth;
    LCurrentPosition := LDepth;

    var LDifference: Double;

    for var LIndex := 1 to High(AChildren) do
    begin
      LDifference := -AChildren[LIndex].Shift - LCurrentPosition - AChildren[LIndex].Element.Depth;
      LChildren := LChildren + [TMathVListChild.Kern(LDifference - (AChildren[LIndex - 1].Element.Height + AChildren[LIndex - 1].Element.Depth))];
      LCurrentPosition := LCurrentPosition + LDifference;
      LChildren := LChildren + [AChildren[LIndex]];
    end;
  end
  else
  begin
    for var LIndex := Low(AChildren) to High(AChildren) do
      LChildren := LChildren + [AChildren[LIndex]];

    case APosition of
      vpTop:
        begin
          var LBottom: Double := APositionData;

          for var LIndex := 0 to High(LChildren) do
          if LChildren[LIndex].IsKern then
            LBottom := LBottom - LChildren[LIndex].Size
          else
            LBottom := LBottom - LChildren[LIndex].Element.Height - LChildren[LIndex].Element.Depth;

          LDepth := LBottom;
        end;
      vpBottom:
        LDepth := -APositionData;
      vpShift:
        LDepth := -LChildren[0].Element.Depth - APositionData;
    else
      LDepth := -LChildren[0].Element.Depth;
    end;
  end;

  Result := NewBox(TMathVListBox.Create(['vlist-t']));

  var LMinimumPosition: Double := LDepth;
  var LMaximumPosition: Double := LDepth;
  var LItem: TMathVListItem;

  LCurrentPosition := LDepth;

  for var LIndex := 0 to High(LChildren) do
  begin
    if LChildren[LIndex].IsKern then
      LCurrentPosition := LCurrentPosition + LChildren[LIndex].Size
    else
    begin
      LItem.Element := LChildren[LIndex].Element;
      LItem.Baseline := LCurrentPosition + LItem.Element.Depth;
      LItem.MarginLeft := LChildren[LIndex].MarginLeft;
      LItem.MarginRight := LChildren[LIndex].MarginRight;
      Result.Items.Add(LItem);
      LCurrentPosition := LCurrentPosition + LItem.Element.Height + LItem.Element.Depth;
    end;

    LMinimumPosition := Min(LMinimumPosition, LCurrentPosition);
    LMaximumPosition := Max(LMaximumPosition, LCurrentPosition);
  end;

  Result.Height := LMaximumPosition;
  Result.Depth := -LMinimumPosition;
end;

function TMathBuilder.GetTypeOfBox(const ABox: TMathBox; const ARightSide: Boolean = False; const AUseSide: Boolean = False): string;
var
  LNode: TMathBox;
  LChildren: TMathBoxList;
begin
  if not Assigned(ABox) then
    Exit('');

  LNode := ABox;

  if AUseSide then
  while (LNode is TMathSpanBox) and TMathSpanBox(LNode).IsFragment do
  begin
    LChildren := TMathSpanBox(LNode).Children;

    if LChildren.Count = 0 then
      Break;

    LNode := if ARightSide then LChildren.Last else LChildren.First;
  end;

  Result := LNode.FirstClass;

  if not IsMathClass(Result) then
    Result := '';
end;

procedure TMathBuilder.TraverseNonSpaceNodes(const ANodes: TMathBoxList; const ACallback: TMathTraversalCallback;
  var APrevious: TMathTraversalPrevious; const ANext: TMathBox; const AIsRoot: Boolean; const ALevels: TObjectList<TMathTraversalLevel>);
begin
  var LLevel := TMathTraversalLevel.Create;

  ALevels.Add(LLevel);

  LLevel.Nodes := ANodes;
  LLevel.Index := 0;

  if Assigned(ANext) then
    ANodes.Add(ANext);

  var LNode: TMathBox;
  var LNonSpace: Boolean;

  while LLevel.Index < ANodes.Count do
  begin
    LNode := ANodes[LLevel.Index];

    if (LNode is TMathSpanBox) and TMathSpanBox(LNode).IsFragment then
    begin
      TraverseNonSpaceNodes(TMathSpanBox(LNode).Children, ACallback, APrevious, nil, AIsRoot, ALevels);
      Inc(LLevel.Index);

      Continue;
    end;

    LNonSpace := not (bfSpace in LNode.Flags);

    if LNonSpace then
    begin
      var LResult: TMathBox := ACallback(LNode, APrevious.Node);

      if Assigned(LResult) then
      begin
        if Assigned(APrevious.Level) then
        begin
          APrevious.Level.Nodes.Insert(APrevious.InsertIndex + 1, LResult);
          Inc(APrevious.Level.Index);
        end
        else
        begin
          ANodes.Insert(0, LResult);
          Inc(LLevel.Index);
        end;
      end;

      APrevious.Node := LNode;
    end
    else
    if AIsRoot and (bfNewLine in LNode.Flags) then
      APrevious.Node := MakeSpan(['leftmost'], []);

    APrevious.Level := LLevel;
    APrevious.InsertIndex := LLevel.Index;
    Inc(LLevel.Index);
  end;

  if Assigned(ANext) then
    ANodes.Delete(ANodes.Count - 1);
end;

function SpacingBetween(const ALeftType: string; const ARightType: string; const ATight: Boolean): Double;
const
  THIN_SPACE = 3;
  MEDIUM_SPACE = 4;
  THICK_SPACE = 5;
begin
  Result := 0;

  if ATight then
  begin
    if (ARightType = MATH_CLASS_OP) and ((ALeftType = MATH_CLASS_ORD) or (ALeftType = MATH_CLASS_OP) or
      (ALeftType = MATH_CLASS_CLOSE) or (ALeftType = MATH_CLASS_INNER)) then
      Result := THIN_SPACE
    else
    if (ALeftType = MATH_CLASS_OP) and (ARightType = MATH_CLASS_ORD) then
      Result := THIN_SPACE;

    Exit;
  end;

  if ALeftType = MATH_CLASS_ORD then
  begin
    if (ARightType = MATH_CLASS_OP) or (ARightType = MATH_CLASS_INNER) then
      Result := THIN_SPACE
    else
    if ARightType = MATH_CLASS_BIN then
      Result := MEDIUM_SPACE
    else
    if ARightType = MATH_CLASS_REL then
      Result := THICK_SPACE;
  end
  else
  if ALeftType = MATH_CLASS_OP then
  begin
    if (ARightType = MATH_CLASS_ORD) or (ARightType = MATH_CLASS_OP) or (ARightType = MATH_CLASS_INNER) then
      Result := THIN_SPACE
    else
    if ARightType = MATH_CLASS_REL then
      Result := THICK_SPACE;
  end
  else
  if ALeftType = MATH_CLASS_BIN then
  begin
    if (ARightType = MATH_CLASS_ORD) or (ARightType = MATH_CLASS_OP) or (ARightType = MATH_CLASS_OPEN) or
      (ARightType = MATH_CLASS_INNER) then
      Result := MEDIUM_SPACE;
  end
  else
  if ALeftType = MATH_CLASS_REL then
  begin
    if (ARightType = MATH_CLASS_ORD) or (ARightType = MATH_CLASS_OP) or (ARightType = MATH_CLASS_OPEN) or
      (ARightType = MATH_CLASS_INNER) then
      Result := THICK_SPACE;
  end
  else
  if ALeftType = MATH_CLASS_CLOSE then
  begin
    if (ARightType = MATH_CLASS_OP) or (ARightType = MATH_CLASS_INNER) then
      Result := THIN_SPACE
    else
    if ARightType = MATH_CLASS_BIN then
      Result := MEDIUM_SPACE
    else
    if ARightType = MATH_CLASS_REL then
      Result := THICK_SPACE;
  end
  else
  if ALeftType = MATH_CLASS_PUNCT then
  begin
    if ARightType = MATH_CLASS_REL then
      Result := THICK_SPACE
    else
    if (ARightType = MATH_CLASS_ORD) or (ARightType = MATH_CLASS_OP) or (ARightType = MATH_CLASS_OPEN) or
      (ARightType = MATH_CLASS_CLOSE) or (ARightType = MATH_CLASS_PUNCT) or (ARightType = MATH_CLASS_INNER) then
      Result := THIN_SPACE;
  end
  else
  if ALeftType = MATH_CLASS_INNER then
  begin
    if ARightType = MATH_CLASS_BIN then
      Result := MEDIUM_SPACE
    else
    if ARightType = MATH_CLASS_REL then
      Result := THICK_SPACE
    else
    if (ARightType = MATH_CLASS_ORD) or (ARightType = MATH_CLASS_OP) or (ARightType = MATH_CLASS_OPEN) or
      (ARightType = MATH_CLASS_PUNCT) or (ARightType = MATH_CLASS_INNER) then
      Result := THIN_SPACE;
  end;
end;

function TMathBuilder.BuildExpression(const AExpression: TMathNodeList; const AOptions: TMathOptions;
  const ARealGroup: TMathRealGroup; const ALeftSurrounding: string = ''; const ARightSurrounding: string = ''): TMathBoxList;
begin
  var LGroups := MakeList;
  var LOutput: TMathBox;

  for var LIndex := 0 to AExpression.Count - 1 do
  begin
    LOutput := BuildGroup(AExpression[LIndex], AOptions);

    if (LOutput is TMathSpanBox) and TMathSpanBox(LOutput).IsFragment then
      LGroups.AddRange(TMathSpanBox(LOutput).Children)
    else
      LGroups.Add(LOutput);
  end;

  TryCombineChars(LGroups);

  if ARealGroup = rgFalse then
    Exit(LGroups);

  var LGlueOptions := AOptions;
  var LNode: TMathParseNode;

  if AExpression.Count = 1 then
  begin
    LNode := AExpression[0];

    if LNode.NodeType = ntSizing then
      LGlueOptions := AOptions.HavingSize(LNode.Size)
    else
    if (LNode.NodeType = ntStyling) and (LNode.Style <> snNone) then
      LGlueOptions := AOptions.HavingStyle(StyleFromName(LNode.Style));
  end;

  var LDummyPrevious := MakeSpan([if ALeftSurrounding.IsEmpty then 'leftmost' else ALeftSurrounding], [], AOptions);
  var LDummyNext := MakeSpan([if ARightSurrounding.IsEmpty then 'rightmost' else ARightSurrounding], [], AOptions);
  var LPrevious: TMathTraversalPrevious;

  var LLevels := TObjectList<TMathTraversalLevel>.Create(True);
  try
    LPrevious := Default(TMathTraversalPrevious);
    LPrevious.Node := LDummyPrevious;
    TraverseNonSpaceNodes(LGroups,
      function(const ANode: TMathBox; const APrevious: TMathBox): TMathBox
      begin
        var LPreviousType := APrevious.FirstClass;
        var LType := ANode.FirstClass;

        if (LPreviousType = MATH_CLASS_BIN) and ((LType = 'rightmost') or (LType = MATH_CLASS_REL) or (LType = MATH_CLASS_CLOSE) or (LType = MATH_CLASS_PUNCT)) then
          APrevious.SetFirstClass(MATH_CLASS_ORD)
        else
        if (LType = MATH_CLASS_BIN) and ((LPreviousType = 'leftmost') or (LPreviousType = MATH_CLASS_BIN) or (LPreviousType = MATH_CLASS_OPEN) or
          (LPreviousType = MATH_CLASS_REL) or (LPreviousType = MATH_CLASS_OP) or (LPreviousType = MATH_CLASS_PUNCT)) then
          ANode.SetFirstClass(MATH_CLASS_ORD);

        Result := nil;
      end, LPrevious, LDummyNext, ARealGroup = rgRoot, LLevels);

    LPrevious := Default(TMathTraversalPrevious);
    LPrevious.Node := LDummyPrevious;
    TraverseNonSpaceNodes(LGroups,
      function(const ANode: TMathBox; const APrevious: TMathBox): TMathBox
      begin
        Result := nil;

        var LPreviousType := GetTypeOfBox(APrevious);
        var LType := GetTypeOfBox(ANode);

        if LPreviousType.IsEmpty or LType.IsEmpty then
          Exit;

        var LSpace: Double := SpacingBetween(LPreviousType, LType, ANode.HasClass(CLASS_TIGHT));

        if LSpace > 0 then
          Result := MakeGlue(MeasurementFromMu(LSpace), LGlueOptions);
      end, LPrevious, LDummyNext, ARealGroup = rgRoot, LLevels);
  finally
    LLevels.Free;
  end;

  Result := LGroups;
end;

function TMathBuilder.MakeNullDelimiter(const AOptions: TMathOptions; const AClasses: array of string): TMathBox;
begin
  var LClasses: TArray<string> := nil;

  for var LIndex := Low(AClasses) to High(AClasses) do
    LClasses := LClasses + [AClasses[LIndex]];

  Result := MakeSpan(LClasses + ['nulldelimiter'], []);

  if AOptions.Size <> BASE_SIZE then
  begin
    Result.AddClass(CLASS_SIZING);
    Result.Scale := AOptions.BaseSizingMultiplier;
  end;

  Result.SetFixedWidth(0.12);
end;

function TMathBuilder.BuildGroup(const AGroup: TMathParseNode; const AOptions: TMathOptions; const ABaseOptions: TMathOptions = nil): TMathBox;
begin
  if not Assigned(AGroup) then
    Exit(MakeSpan([], []));

  Result := BuildGroupByType(AGroup, AOptions);

  if Assigned(ABaseOptions) and (AOptions.Size <> ABaseOptions.Size) then
  begin
    Result := MakeSpan([], [Result], AOptions);

    ApplySizingClasses(Result, AOptions, ABaseOptions);

    var LMultiplier: Double := AOptions.SizeMultiplier / ABaseOptions.SizeMultiplier;

    Result.Height := Result.Height * LMultiplier;
    Result.Depth := Result.Depth * LMultiplier;
  end;
end;

function TMathBuilder.SizingGroup(const AValue: TMathNodeList; const AOptions: TMathOptions; const ABaseOptions: TMathOptions): TMathBox;
begin
  var LInner := BuildExpression(AValue, AOptions, rgFalse);
  var LMultiplier: Double := AOptions.SizeMultiplier / ABaseOptions.SizeMultiplier;

  for var LIndex := 0 to LInner.Count - 1 do
  begin
    if (AOptions.Size <> ABaseOptions.Size) and not LInner[LIndex].HasClass(CLASS_SIZING) then
      LInner[LIndex].AddClass(CLASS_SIZING);

    LInner[LIndex].ApplySizing(LMultiplier);
  end;

  Result := MakeFragment(LInner);
end;

function TMathBuilder.BuildGroupByType(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  case AGroup.NodeType of
    ntMathOrd, ntTextOrd:
      Result := MakeOrd(AGroup, AOptions);
    ntAtom:
      Result := BuildAtom(AGroup, AOptions);
    ntSpacing:
      Result := BuildSpacing(AGroup, AOptions);
    ntOrdGroup:
      if AGroup.Semisimple then
        Result := MakeFragment(BuildExpression(AGroup.Body, AOptions, rgFalse))
      else
        Result := MakeSpan([MATH_CLASS_ORD], BuildExpression(AGroup.Body, AOptions, rgTrue), AOptions);
    ntSupSub:
      Result := BuildSupSub(AGroup, AOptions);
    ntGenFrac:
      Result := BuildGenFrac(AGroup, AOptions);
    ntSqrt:
      Result := BuildSqrt(AGroup, AOptions);
    ntOp:
      Result := BuildOp(AGroup, AOptions);
    ntOperatorName:
      Result := BuildOperatorName(AGroup, AOptions);
    ntAccent:
      Result := BuildAccent(AGroup, AOptions);
    ntDelimSizing:
      Result := BuildDelimSizing(AGroup, AOptions);
    ntLeftRight:
      Result := BuildLeftRight(AGroup, AOptions);
    ntMiddle:
      if AGroup.Delimiter = '.' then
        Result := MakeNullDelimiter(AOptions, [])
      else
      begin
        Result := MakeSizedDelim(AGroup.Delimiter, 1, AOptions, AGroup.Mode, []);
        Result.MiddleDelimiter := AGroup.Delimiter;
        Result.MiddleOptions := AOptions;
      end;
    ntFont:
      Result := BuildGroup(AGroup.Child, AOptions.WithFont(AGroup.Font));
    ntText:
      Result := BuildText(AGroup, AOptions);
    ntStyling:
      begin
        var LOptions := if AGroup.Style = snNone then AOptions else AOptions.HavingStyle(StyleFromName(AGroup.Style));

        if AGroup.ResetFont then
          LOptions := LOptions.WithFont('');

        Result := SizingGroup(AGroup.Body, LOptions, AOptions);
      end;
    ntSizing:
      Result := SizingGroup(AGroup.Body, AOptions.HavingSize(AGroup.Size), AOptions);
    ntColor:
      begin
        var LColor: TMathColor;

        if not TryParseMathColor(AGroup.Color, LColor) then
          LColor := AOptions.Color;

        Result := MakeFragment(BuildExpression(AGroup.Body, AOptions.WithColor(LColor), rgFalse));
      end;
    ntKern:
      Result := MakeGlue(AGroup.Dimension, AOptions);
    ntOverline:
      Result := BuildOverline(AGroup, AOptions);
    ntUnderline:
      Result := BuildUnderline(AGroup, AOptions);
    ntPhantom:
      Result := MakeFragment(BuildExpression(AGroup.Body, AOptions.WithPhantom, rgFalse));
    ntVPhantom:
      begin
        var LInner := MakeSpan(['katex-inner'], [BuildGroup(AGroup.Child, AOptions.WithPhantom)]);
        var LFix := MakeSpan(['katex-fix'], []);

        Result := MakeSpan([MATH_CLASS_ORD, 'rlap'], [LInner, LFix], AOptions);
        Result.SetFixedWidth(0);
        TMathSpanBox(Result).LapAlignment := laRight;
      end;
    ntMClass:
      Result := MakeSpan([AGroup.MathClass], BuildExpression(AGroup.Body, AOptions, rgTrue), AOptions);
    ntLap:
      Result := BuildLap(AGroup, AOptions);
    ntSmash:
      Result := BuildSmash(AGroup, AOptions);
    ntRaiseBox:
      Result := MakeVList(vpShift, -CalculateSize(AGroup.Dimension, AOptions),
        [TMathVListChild.Elem(BuildGroup(AGroup.Child, AOptions))], AOptions);
    ntRule:
      Result := BuildRule(AGroup, AOptions);
    ntMathChoice:
      begin
        var LBody: TMathNodeList;

        case AOptions.Style.Size of
          0:
            LBody := AGroup.DisplayBody;
          2:
            LBody := AGroup.ScriptBody;
          3:
            LBody := AGroup.ScriptScriptBody;
        else
          LBody := AGroup.TextBody;
        end;

        Result := MakeFragment(BuildExpression(LBody, AOptions, rgFalse));
      end;
    ntArray:
      Result := BuildArray(AGroup, AOptions);
    ntCr:
      begin
        Result := MakeSpan([], [], AOptions);
        Result.Flags := [bfSpace];

        if AGroup.NewLine then
        begin
          Result.Flags := Result.Flags + [bfNewLine];

          if AGroup.HasDimension then
            Result.MarginTop := CalculateSize(AGroup.Dimension, AOptions);
        end;
      end;
    ntAccentUnder:
      Result := BuildAccentUnder(AGroup, AOptions);
    ntHorizBrace:
      Result := BuildHorizBrace(AGroup, AOptions);
    ntXArrow:
      Result := BuildXArrow(AGroup, AOptions);
    ntEnclose:
      Result := BuildEnclose(AGroup, AOptions);
    ntPmb:
      begin
        var LSpan := MakeSpan([AGroup.MathClass], BuildExpression(AGroup.Body, AOptions, rgTrue), AOptions);

        LSpan.ShadowOffsetX := 0.02;
        LSpan.ShadowOffsetY := 0.01;

        Result := LSpan;
      end;
    ntVCenter:
      begin
        var LInner := BuildGroup(AGroup.Child, AOptions);
        var LAxisHeight: Double := AOptions.FontMetrics.AxisHeight;

        Result := MakeVList(vpShift, 0.5 * ((LInner.Height - LAxisHeight) - (LInner.Depth + LAxisHeight)), [TMathVListChild.Elem(LInner)], AOptions);
      end;
    ntVerb:
      Result := BuildVerb(AGroup, AOptions);
    ntReflectBox:
      begin
        var LSpan := MakeSpan([MATH_CLASS_ORD, 'reflectbox'], [BuildGroup(AGroup.Child, AOptions)], AOptions);

        LSpan.Mirrored := True;

        Result := LSpan;
      end;
    ntCdLabel:
      Result := BuildCdLabel(AGroup, AOptions);
    ntCdLabelParent:
      Result := BuildCdLabelParent(AGroup, AOptions);
  else
    raise ParseMathError('Got group of unknown type');
  end;
end;

function TMathBuilder.BuildAtom(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
const
  FAMILY_CLASSES: array [TMathSymbolGroup] of string = ('', MATH_CLASS_BIN, MATH_CLASS_CLOSE, MATH_CLASS_INNER, '', '', MATH_CLASS_OPEN,
    MATH_CLASS_PUNCT, MATH_CLASS_REL, '', '');
begin
  Result := MathSym(AGroup.Text, AGroup.Mode, AOptions, [FAMILY_CLASSES[AGroup.Family]]);
end;

function TMathBuilder.BuildSpacing(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  if (AGroup.Text = ' ') or (AGroup.Text = '\ ') or (AGroup.Text = '~') or (AGroup.Text = '\space') or
    (AGroup.Text = '\nobreakspace') then
  begin
    var LClassName := if (AGroup.Text = '~') or (AGroup.Text = '\nobreakspace') then 'nobreak' else '';

    if AGroup.Mode = mmText then
    begin
      Result := MakeOrd(AGroup, AOptions);
      Result.AddClass(LClassName);
    end
    else
    begin
      Result := MakeSpan([LClassName], [MathSym(AGroup.Text, AGroup.Mode, AOptions, [])], AOptions);
      Result.Flags := [bfSpace];
    end;
  end
  else
  if (AGroup.Text = '\nobreak') or (AGroup.Text = '\allowbreak') then
  begin
    Result := MakeSpan([Copy(AGroup.Text, 2, MaxInt)], [], AOptions);
    Result.Flags := [bfSpace];
  end
  else
    raise ParseMathError(Format('Unknown type of space "%s"', [AGroup.Text]));
end;

function TMathBuilder.BuildSupSub(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LBaseNode := AGroup.Base;

  if Assigned(LBaseNode) then
  begin
    if (LBaseNode.NodeType = ntOp) and LBaseNode.Limits and ((AOptions.Style.Size = TMathStyle.Display.Size) or LBaseNode.AlwaysHandleSupSub) then
      Exit(BuildOp(AGroup, AOptions));

    if (LBaseNode.NodeType = ntOperatorName) and LBaseNode.AlwaysHandleSupSub and ((AOptions.Style.Size = TMathStyle.Display.Size) or LBaseNode.Limits) then
      Exit(BuildOperatorName(AGroup, AOptions));

    if (LBaseNode.NodeType = ntAccent) and IsCharacterBox(LBaseNode.Base) then
      Exit(BuildAccent(AGroup, AOptions));

    if (LBaseNode.NodeType = ntHorizBrace) and (not Assigned(AGroup.Subscript) = LBaseNode.IsOver) then
      Exit(BuildHorizBrace(AGroup, AOptions));
  end;

  var LBase := BuildGroup(LBaseNode, AOptions);
  var LSupBox: TMathBox := nil;
  var LSubBox: TMathBox := nil;
  var LMetrics := AOptions.FontMetrics;
  var LSupShift: Double := 0;
  var LSubShift: Double := 0;
  var LIsCharacterBox := Assigned(LBaseNode) and IsCharacterBox(LBaseNode);
  var LNewOptions: TMathOptions;

  if Assigned(AGroup.Superscript) then
  begin
    LNewOptions := AOptions.HavingStyle(AOptions.Style.Superscript);
    LSupBox := BuildGroup(AGroup.Superscript, LNewOptions, AOptions);

    if not LIsCharacterBox then
      LSupShift := LBase.Height - LNewOptions.FontMetrics.SupDrop * LNewOptions.SizeMultiplier / AOptions.SizeMultiplier;
  end;

  if Assigned(AGroup.Subscript) then
  begin
    LNewOptions := AOptions.HavingStyle(AOptions.Style.Subscript);
    LSubBox := BuildGroup(AGroup.Subscript, LNewOptions, AOptions);

    if not LIsCharacterBox then
      LSubShift := LBase.Depth + LNewOptions.FontMetrics.SubDrop * LNewOptions.SizeMultiplier / AOptions.SizeMultiplier;
  end;

  var LMinimumSupShift: Double;

  if AOptions.Style = TMathStyle.Display then
    LMinimumSupShift := LMetrics.Sup1
  else
  if AOptions.Style.Cramped then
    LMinimumSupShift := LMetrics.Sup3
  else
    LMinimumSupShift := LMetrics.Sup2;

  var LMarginRight: Double := (0.5 / LMetrics.PtPerEm) / AOptions.SizeMultiplier;
  var LMarginLeft: Double := 0;

  if Assigned(LSubBox) and ((LBase is TMathSymbolBox) or (Assigned(LBaseNode) and (LBaseNode.NodeType = ntOp) and
    ((LBaseNode.Name = '\oiint') or (LBaseNode.Name = '\oiiint')))) then
    LMarginLeft := -LBase.Italic;

  var LSupSub: TMathBox;

  if Assigned(LSupBox) and Assigned(LSubBox) then
  begin
    LSupShift := Max(Max(LSupShift, LMinimumSupShift), LSupBox.Depth + 0.25 * LMetrics.XHeight);
    LSubShift := Max(LSubShift, LMetrics.Sub2);

    var LMaximumWidth: Double := 4 * LMetrics.DefaultRuleThickness;

    if (LSupShift - LSupBox.Depth) - (LSubBox.Height - LSubShift) < LMaximumWidth then
    begin
      LSubShift := LMaximumWidth - (LSupShift - LSupBox.Depth) + LSubBox.Height;

      var LPsi: Double := 0.8 * LMetrics.XHeight - (LSupShift - LSupBox.Depth);

      if LPsi > 0 then
      begin
        LSupShift := LSupShift + LPsi;
        LSubShift := LSubShift - LPsi;
      end;
    end;

    LSupSub := MakeVList(vpIndividualShift, 0, [TMathVListChild.Elem(LSubBox, LSubShift, LMarginLeft, LMarginRight),
      TMathVListChild.Elem(LSupBox, -LSupShift, 0, LMarginRight)], AOptions);
  end
  else
  if Assigned(LSubBox) then
  begin
    LSubShift := Max(Max(LSubShift, LMetrics.Sub1), LSubBox.Height - 0.8 * LMetrics.XHeight);
    LSupSub := MakeVList(vpShift, LSubShift, [TMathVListChild.Elem(LSubBox, 0, LMarginLeft, LMarginRight)], AOptions);
  end
  else
  if Assigned(LSupBox) then
  begin
    LSupShift := Max(Max(LSupShift, LMinimumSupShift), LSupBox.Depth + 0.25 * LMetrics.XHeight);
    LSupSub := MakeVList(vpShift, -LSupShift, [TMathVListChild.Elem(LSupBox, 0, 0, LMarginRight)], AOptions);
  end
  else
    raise ParseMathError('supsub must have either sup or sub.');

  var LMathClass := GetTypeOfBox(LBase, True, True);

  if LMathClass.IsEmpty then
    LMathClass := MATH_CLASS_ORD;

  Result := MakeSpan([LMathClass], [LBase, MakeSpan(['msupsub'], [LSupSub])], AOptions);
end;

function TMathBuilder.BuildGenFrac(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LStyle := AOptions.Style;
  var LNewOptions := AOptions.HavingStyle(LStyle.FractionNumerator);
  var LNumerator := BuildGroup(AGroup.Numerator, LNewOptions, AOptions);
  var LStrutHeight: Double;
  var LStrutDepth: Double;

  if AGroup.Continued then
  begin
    LStrutHeight := 8.5 / AOptions.FontMetrics.PtPerEm;
    LStrutDepth := 3.5 / AOptions.FontMetrics.PtPerEm;
    LNumerator.Height := Max(LNumerator.Height, LStrutHeight);
    LNumerator.Depth := Max(LNumerator.Depth, LStrutDepth);
  end;

  LNewOptions := AOptions.HavingStyle(LStyle.FractionDenominator);

  var LDenominator := BuildGroup(AGroup.Denominator, LNewOptions, AOptions);
  var LRule: TMathRuleBox;
  var LRuleWidth: Double;
  var LRuleSpacing: Double;

  if AGroup.HasBarLine then
  begin
    LRule := MakeLineSpan('frac-line', AOptions, if AGroup.HasBarSize then CalculateSize(AGroup.BarSize, AOptions) else 0);

    LRuleWidth := LRule.Height;
    LRuleSpacing := LRule.Height;
  end
  else
  begin
    LRule := nil;
    LRuleWidth := 0;
    LRuleSpacing := AOptions.FontMetrics.DefaultRuleThickness;
  end;

  var LNumeratorShift: Double;
  var LClearance: Double;
  var LDenominatorShift: Double;

  if LStyle.Size = TMathStyle.Display.Size then
  begin
    LNumeratorShift := AOptions.FontMetrics.Num1;
    LClearance := if LRuleWidth > 0 then 3 * LRuleSpacing else 7 * LRuleSpacing;
    LDenominatorShift := AOptions.FontMetrics.Denom1;
  end
  else
  begin
    if LRuleWidth > 0 then
    begin
      LNumeratorShift := AOptions.FontMetrics.Num2;
      LClearance := LRuleSpacing;
    end
    else
    begin
      LNumeratorShift := AOptions.FontMetrics.Num3;
      LClearance := 3 * LRuleSpacing;
    end;

    LDenominatorShift := AOptions.FontMetrics.Denom2;
  end;

  var LFraction: TMathVListBox;

  if Assigned(LRule) then
  begin
    var LAxisHeight: Double := AOptions.FontMetrics.AxisHeight;

    if (LNumeratorShift - LNumerator.Depth) - (LAxisHeight + 0.5 * LRuleWidth) < LClearance then
      LNumeratorShift := LNumeratorShift + LClearance - ((LNumeratorShift - LNumerator.Depth) - (LAxisHeight + 0.5 * LRuleWidth));

    if (LAxisHeight - 0.5 * LRuleWidth) - (LDenominator.Height - LDenominatorShift) < LClearance then
      LDenominatorShift := LDenominatorShift + LClearance - ((LAxisHeight - 0.5 * LRuleWidth) - (LDenominator.Height - LDenominatorShift));

    LFraction := MakeVList(vpIndividualShift, 0, [TMathVListChild.Elem(LDenominator, LDenominatorShift),
      TMathVListChild.Elem(LRule, -(LAxisHeight - 0.5 * LRuleWidth)), TMathVListChild.Elem(LNumerator, -LNumeratorShift)], AOptions);
  end
  else
  begin
    var LCandidateClearance: Double := (LNumeratorShift - LNumerator.Depth) - (LDenominator.Height - LDenominatorShift);

    if LCandidateClearance < LClearance then
    begin
      LNumeratorShift := LNumeratorShift + 0.5 * (LClearance - LCandidateClearance);
      LDenominatorShift := LDenominatorShift + 0.5 * (LClearance - LCandidateClearance);
    end;

    LFraction := MakeVList(vpIndividualShift, 0, [TMathVListChild.Elem(LDenominator, LDenominatorShift),
      TMathVListChild.Elem(LNumerator, -LNumeratorShift)], AOptions);
  end;

  LFraction.Alignment := vaCenter;

  LNewOptions := AOptions.HavingStyle(LStyle);
  LFraction.Height := LFraction.Height * LNewOptions.SizeMultiplier / AOptions.SizeMultiplier;
  LFraction.Depth := LFraction.Depth * LNewOptions.SizeMultiplier / AOptions.SizeMultiplier;

  var LDelimiterSize: Double;

  if LStyle.Size = TMathStyle.Display.Size then
    LDelimiterSize := AOptions.FontMetrics.Delim1
  else
  if LStyle.Size = TMathStyle.ScriptScript.Size then
    LDelimiterSize := AOptions.HavingStyle(TMathStyle.Script).FontMetrics.Delim2
  else
    LDelimiterSize := AOptions.FontMetrics.Delim2;

  var LLeftDelimiter: TMathBox;

  if AGroup.LeftDelimiter.IsEmpty then
    LLeftDelimiter := MakeNullDelimiter(AOptions, [MATH_CLASS_OPEN])
  else
    LLeftDelimiter := MakeCustomSizedDelim(AGroup.LeftDelimiter, LDelimiterSize, True, AOptions.HavingStyle(LStyle), AGroup.Mode, [MATH_CLASS_OPEN]);

  var LRightDelimiter: TMathBox;

  if AGroup.Continued then
    LRightDelimiter := MakeSpan([], [])
  else
  if AGroup.RightDelimiter.IsEmpty then
    LRightDelimiter := MakeNullDelimiter(AOptions, [MATH_CLASS_CLOSE])
  else
    LRightDelimiter := MakeCustomSizedDelim(AGroup.RightDelimiter, LDelimiterSize, True, AOptions.HavingStyle(LStyle),
      AGroup.Mode, [MATH_CLASS_CLOSE]);

  var LFractionSpan: TMathBox := MakeSpan(['mfrac'], [LFraction]);

  Result := MakeSpan([MATH_CLASS_ORD], [LLeftDelimiter, LFractionSpan, LRightDelimiter], AOptions);

  ApplySizingClasses(Result, LNewOptions, AOptions);
end;

function TMathBuilder.MakeSqrtImage(const AHeight: Double; const AOptions: TMathOptions; out ARuleWidth: Double; out AAdvanceWidth: Double): TMathSurdBox;
begin
  var LNewOptions := AOptions.HavingBaseSizing;
  var LDelimiter := TraverseSequence('\surd', AHeight * LNewOptions.SizeMultiplier, StackLargeDelimiterSequence, LNewOptions);
  var LSizeMultiplier: Double := LNewOptions.SizeMultiplier;
  var LExtraVinculum: Double := Max(0, AOptions.MinRuleThickness - AOptions.FontMetrics.SqrtRuleThickness);

  Result := NewBox(TMathSurdBox.Create(['hide-tail']));
  Result.Color := AOptions.GetColor;

  var LTexHeight: Double;
  var LGlyphScale: Double;
  var LGlyph: TMathBox;

  case LDelimiter.Kind of
    dkSmall:
      begin
        if AHeight < 1.0 then
          LSizeMultiplier := 1.0
        else
        if AHeight < 1.4 then
          LSizeMultiplier := 0.7;

        LTexHeight := (1.0 + LExtraVinculum) / LSizeMultiplier;
        AAdvanceWidth := 0.833 / LSizeMultiplier;
        Result.MinWidth := 0.853;
        LGlyph := MakeSymbol('\surd', mfMainRegular, mmMath, AOptions, []);
        LGlyphScale := 1 / LSizeMultiplier;
        Result.SurdBaseline := LTexHeight - LExtraVinculum - LGlyphScale * LGlyph.Height;
      end;
    dkLarge:
      begin
        LTexHeight := (SIZE_TO_MAX_HEIGHT[LDelimiter.Size] + LExtraVinculum) / LSizeMultiplier;
        AAdvanceWidth := 1.0 / LSizeMultiplier;
        Result.MinWidth := 1.02;
        LGlyph := MakeSymbol('\surd', SizeFont(LDelimiter.Size), mmMath, AOptions, []);
        LGlyphScale := 1 / LSizeMultiplier;
        Result.SurdBaseline := LTexHeight - LExtraVinculum - LGlyphScale * LGlyph.Height;
      end;
  else
    begin
      LTexHeight := AHeight + LExtraVinculum;
      AAdvanceWidth := 1.056;
      Result.MinWidth := 0.742;
      LGlyph := MakeStackedDelim('\surd', AHeight * AOptions.SizeMultiplier, False, AOptions, mmMath, []);
      LGlyphScale := 1;
      Result.SurdBaseline := LTexHeight - LExtraVinculum - LGlyph.Height;
    end;
  end;

  Result.Surd := LGlyph;
  Result.SurdScale := LGlyphScale;
  Result.VinculumStart := AAdvanceWidth;
  Result.VinculumThickness := AOptions.FontMetrics.SqrtRuleThickness * LGlyphScale + LExtraVinculum;
  Result.Height := LTexHeight;
  Result.StretchWidth := True;

  ARuleWidth := (AOptions.FontMetrics.SqrtRuleThickness + LExtraVinculum) * LSizeMultiplier;
end;

function TMathBuilder.BuildSqrt(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LInner := BuildGroup(AGroup.Child, AOptions.HavingCrampedStyle);

  if LInner.Height = 0 then
    LInner.Height := AOptions.FontMetrics.XHeight;

  LInner := WrapFragment(LInner, AOptions);

  var LMetrics: PMathGlobalMetrics := AOptions.FontMetrics;
  var LTheta: Double := LMetrics.DefaultRuleThickness;
  var LPhi: Double := LTheta;

  if AOptions.Style.Id < TMathStyle.Text.Id then
    LPhi := AOptions.FontMetrics.XHeight;

  var LLineClearance: Double := LTheta + LPhi / 4;
  var LMinimumDelimiterHeight: Double := LInner.Height + LInner.Depth + LLineClearance + LTheta;
  var LRuleWidth: Double;
  var LAdvanceWidth: Double;
  var LImage := MakeSqrtImage(LMinimumDelimiterHeight, AOptions, LRuleWidth, LAdvanceWidth);
  var LDelimiterDepth: Double := LImage.Height - LRuleWidth;

  if LDelimiterDepth > LInner.Height + LInner.Depth + LLineClearance then
    LLineClearance := (LLineClearance + LDelimiterDepth - LInner.Height - LInner.Depth) / 2;

  var LImageShift: Double := LImage.Height - LInner.Height - LLineClearance - LRuleWidth;

  LInner.PaddingLeft := LAdvanceWidth;

  var LBody := MakeVList(vpFirstBaseline, 0, [TMathVListChild.Elem(LInner), TMathVListChild.Kern(-(LInner.Height + LImageShift)),
    TMathVListChild.Elem(LImage), TMathVListChild.Kern(LRuleWidth)], AOptions);

  if not Assigned(AGroup.Index) then
    Exit(MakeSpan([MATH_CLASS_ORD, 'sqrt'], [LBody], AOptions));

  var LNewOptions := AOptions.HavingStyle(TMathStyle.ScriptScript);
  var LRoot := BuildGroup(AGroup.Index, LNewOptions, AOptions);
  var LToShift: Double := 0.6 * (LBody.Height - LBody.Depth);
  var LRootVList := MakeVList(vpShift, -LToShift, [TMathVListChild.Elem(LRoot)], AOptions);
  var LRootWrap: TMathBox := MakeSpan(['katex-root'], [LRootVList]);

  LRootWrap.MarginLeft := 5 / 18;
  LRootWrap.MarginRight := -10 / 18;

  Result := MakeSpan([MATH_CLASS_ORD, 'sqrt'], [LRootWrap, LBody], AOptions);
end;

function TMathBuilder.AssembleSupSub(const ABase: TMathBox; const ASupGroup: TMathParseNode; const ASubGroup: TMathParseNode;
  const AOptions: TMathOptions; const AStyle: TMathStyle; const ASlant: Double; const ABaseShift: Double): TMathBox;
begin
  var LBase: TMathBox := MakeSpan([], [ABase]);
  var LSubIsSingleCharacter := Assigned(ASubGroup) and IsCharacterBox(ASubGroup);
  var LMetrics: PMathGlobalMetrics := AOptions.FontMetrics;
  var LSup: TMathBox := nil;
  var LSub: TMathBox := nil;
  var LSupKern: Double := 0;
  var LSubKern: Double := 0;

  if Assigned(ASupGroup) then
  begin
    LSup := BuildGroup(ASupGroup, AOptions.HavingStyle(AStyle.Superscript), AOptions);
    LSupKern := Max(LMetrics.BigOpSpacing1, LMetrics.BigOpSpacing3 - LSup.Depth);
  end;

  if Assigned(ASubGroup) then
  begin
    LSub := BuildGroup(ASubGroup, AOptions.HavingStyle(AStyle.Subscript), AOptions);
    LSubKern := Max(LMetrics.BigOpSpacing2, LMetrics.BigOpSpacing4 - LSub.Height);
  end;

  var LFinalGroup: TMathVListBox;

  if Assigned(LSup) and Assigned(LSub) then
    LFinalGroup := MakeVList(vpBottom, LMetrics.BigOpSpacing5 + LSub.Height + LSub.Depth + LSubKern + LBase.Depth + ABaseShift,
      [TMathVListChild.Kern(LMetrics.BigOpSpacing5), TMathVListChild.Elem(LSub, 0, -ASlant), TMathVListChild.Kern(LSubKern),
      TMathVListChild.Elem(LBase), TMathVListChild.Kern(LSupKern), TMathVListChild.Elem(LSup, 0, ASlant),
      TMathVListChild.Kern(LMetrics.BigOpSpacing5)], AOptions)
  else
  if Assigned(LSub) then
    LFinalGroup := MakeVList(vpTop, LBase.Height - ABaseShift, [TMathVListChild.Kern(LMetrics.BigOpSpacing5),
      TMathVListChild.Elem(LSub, 0, -ASlant), TMathVListChild.Kern(LSubKern), TMathVListChild.Elem(LBase)], AOptions)
  else
  if Assigned(LSup) then
    LFinalGroup := MakeVList(vpBottom, LBase.Depth + ABaseShift, [TMathVListChild.Elem(LBase),
      TMathVListChild.Kern(LSupKern), TMathVListChild.Elem(LSup, 0, ASlant), TMathVListChild.Kern(LMetrics.BigOpSpacing5)],
      AOptions)
  else
    Exit(LBase);

  LFinalGroup.Alignment := vaCenter;

  var LParts := MakeList([LFinalGroup]);

  if Assigned(LSub) and (ASlant <> 0) and not LSubIsSingleCharacter then
  begin
    var LSpacer: TMathBox := MakeSpan([], [], AOptions);

    LSpacer.Flags := [bfSpace];
    LSpacer.MarginRight := ASlant;
    LParts.Insert(0, LSpacer);
  end;

  Result := MakeSpan([MATH_CLASS_OP, 'op-limits'], LParts, AOptions);
end;

function TMathBuilder.BuildOp(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LSupGroup: TMathParseNode := nil;
  var LSubGroup: TMathParseNode := nil;
  var LHasLimits := False;
  var LGroup: TMathParseNode;

  if AGroup.NodeType = ntSupSub then
  begin
    LSupGroup := AGroup.Superscript;
    LSubGroup := AGroup.Subscript;
    LGroup := AGroup.Base;
    LHasLimits := True;
  end
  else
    LGroup := AGroup;

  var LStyle := AOptions.Style;
  var LLarge := (LStyle.Size = TMathStyle.Display.Size) and LGroup.Symbol and (LGroup.Name <> '\smallint');
  var LBase: TMathBox;

  if LGroup.Symbol then
  begin
    var LName := LGroup.Name;

    if LName = '\oiint' then
      LName := '\iint'
    else
    if LName = '\oiiint' then
      LName := '\iiint';

    LBase := MakeSymbol(LName, if LLarge then mfSize2Regular else mfSize1Regular, mmMath, AOptions,
      [MATH_CLASS_OP, 'op-symbol', if LLarge then 'large-op' else 'small-op']);

    if LName <> LGroup.Name then
    begin
      var LItalic: Double := LBase.Italic;
      var LOval: TMathBox := MakeStaticSvg(Copy(LGroup.Name, 2, MaxInt) + 'Size' + (if LLarge then '2' else '1'), AOptions);

      LBase := MakeVList(vpIndividualShift, 0, [TMathVListChild.Elem(LBase, 0), TMathVListChild.Elem(LOval, if LLarge then 0.08 else 0)], AOptions);
      LBase.SetFirstClass(MATH_CLASS_OP);
      LBase.Italic := LItalic;
    end;
  end
  else
  if LGroup.HasBody then
  begin
    var LInner := BuildExpression(LGroup.Body, AOptions, rgTrue);

    if (LInner.Count = 1) and (LInner[0] is TMathSymbolBox) then
    begin
      LBase := LInner[0];
      LBase.SetFirstClass(MATH_CLASS_OP);
    end
    else
      LBase := MakeSpan([MATH_CLASS_OP], LInner, AOptions);
  end
  else
  begin
    var LOutput := MakeList;

    for var LIndex := 2 to LGroup.Name.Length do
      LOutput.Add(MathSym(LGroup.Name[LIndex], LGroup.Mode, AOptions, []));

    LBase := MakeSpan([MATH_CLASS_OP], LOutput, AOptions);
  end;

  var LBaseShift: Double := 0;
  var LSlant: Double := 0;

  if ((LBase is TMathSymbolBox) or (LGroup.Name = '\oiint') or (LGroup.Name = '\oiiint')) and not LGroup.SuppressBaseShift then
  begin
    LBaseShift := (LBase.Height - LBase.Depth) / 2 - AOptions.FontMetrics.AxisHeight;
    LSlant := LBase.Italic;
  end;

  if LHasLimits then
    Exit(AssembleSupSub(LBase, LSupGroup, LSubGroup, AOptions, LStyle, LSlant, LBaseShift));

  if LBaseShift <> 0 then
    LBase.ShiftY := LBaseShift;

  Result := LBase;
end;

function TMathBuilder.BuildOperatorName(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LSupGroup: TMathParseNode := nil;
  var LSubGroup: TMathParseNode := nil;
  var LHasLimits := False;
  var LGroup: TMathParseNode;

  if AGroup.NodeType = ntSupSub then
  begin
    LSupGroup := AGroup.Superscript;
    LSubGroup := AGroup.Subscript;
    LGroup := AGroup.Base;
    LHasLimits := True;
  end
  else
    LGroup := AGroup;

  var LBase: TMathBox;

  if LGroup.Body.Count > 0 then
  begin
    var LBody := FArena.NewList;
    var LChild: TMathParseNode;
    var LTextOrd: TMathParseNode;

    for var LIndex := 0 to LGroup.Body.Count - 1 do
    begin
      LChild := LGroup.Body[LIndex];

      if IsSymbolNode(LChild) then
      begin
        LTextOrd := FArena.NewNode(ntTextOrd, LChild.Mode);
        LTextOrd.Text := LChild.Text;
        LBody.Add(LTextOrd);
      end
      else
        LBody.Add(LChild);
    end;

    var LExpression := BuildExpression(LBody, AOptions.WithFont('mathrm'), rgTrue);
    var LSymbol: TMathSymbolBox;
    var LText: string;

    for var LIndex := 0 to LExpression.Count - 1 do
    if LExpression[LIndex] is TMathSymbolBox then
    begin
      LSymbol := TMathSymbolBox(LExpression[LIndex]);
      LText := LSymbol.Text.Replace(#$2212, '-').Replace(#$2217, '*');

      if LText <> LSymbol.Text then
      begin
        LSymbol.Text := LText;
        LSymbol.Advances := ComputeAdvances(LText, LSymbol.Font);
      end;
    end;

    LBase := MakeSpan([MATH_CLASS_OP], LExpression, AOptions);
  end
  else
    LBase := MakeSpan([MATH_CLASS_OP], [], AOptions);

  Result := if LHasLimits then AssembleSupSub(LBase, LSupGroup, LSubGroup, AOptions, AOptions.Style, 0, 0) else LBase;
end;

function TMathBuilder.BuildAccent(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LSupSubGroup: TMathSpanBox := nil;
  var LBaseNode: TMathParseNode;
  var LGroup: TMathParseNode;

  if AGroup.NodeType = ntSupSub then
  begin
    LGroup := AGroup.Base;
    LBaseNode := LGroup.Base;
    AGroup.Base := LBaseNode;
    try
      LSupSubGroup := BuildGroup(AGroup, AOptions) as TMathSpanBox;
    finally
      AGroup.Base := LGroup;
    end;
  end
  else
  begin
    LGroup := AGroup;
    LBaseNode := LGroup.Base;
  end;

  var LBody := BuildGroup(LBaseNode, AOptions.HavingCrampedStyle);
  var LMustShift := LGroup.IsShifty and IsCharacterBox(LBaseNode);
  var LSkew: Double := 0;
  var LBaseSymbol: TMathBox;

  if LMustShift then
  begin
    LBaseSymbol := LBody;

    while (LBaseSymbol is TMathSpanBox) and (TMathSpanBox(LBaseSymbol).Children.Count = 1) do
      LBaseSymbol := TMathSpanBox(LBaseSymbol).Children[0];

    if LBaseSymbol is TMathSymbolBox then
      LSkew := LBaseSymbol.Skew;
  end;

  var LAccentBelow := LGroup.LabelText = '\c';
  var LClearance: Double := if LAccentBelow then LBody.Height + LBody.Depth else Min(LBody.Height, AOptions.FontMetrics.XHeight);
  var LAccentNode: TMathParseNode;
  var LAccent: TMathBox;
  var LAccentBody: TMathBox;

  if LGroup.IsStretchy then
    LAccentBody := MakeVList(vpFirstBaseline, 0, [TMathVListChild.Elem(LBody), TMathVListChild.Elem(MakeStretchySvg(LGroup.LabelText,
      LBaseNode, AOptions), 0, if LSkew > 0 then 2 * LSkew else 0)], AOptions)
  else
  begin
    if LGroup.LabelText = '\vec' then
    begin
      LAccent := MakeSymbol(#$20D7, mfMainRegular, LGroup.Mode, AOptions, [MATH_CLASS_ORD]);
      TMathSymbolBox(LAccent).Advances := [VEC_WIDTH];
      LAccent.ShiftX := VEC_WIDTH;
    end
    else
    begin
      LAccentNode := FArena.NewNode(ntTextOrd, LGroup.Mode);
      LAccentNode.Text := LGroup.LabelText;
      LAccent := MakeOrd(LAccentNode, AOptions);
    end;

    LAccent.Italic := 0;
    LAccent.Measure;

    var LWidth: Double := LAccent.Width;

    if LAccentBelow then
      LClearance := LClearance + LAccent.Depth;

    LAccentBody := MakeSpan(['accent-body'], [LAccent]);

    var LAccentFull := LGroup.LabelText = '\textcircled';

    if LAccentFull then
    begin
      LAccentBody.AddClass('accent-full');
      LClearance := LBody.Height;
    end;

    var LLeft: Double := LSkew;

    if not LAccentFull then
    begin
      LLeft := LLeft - LWidth / 2;
      LAccentBody.SetFixedWidth(0);
    end;

    LAccentBody.ShiftX := LLeft;

    if LGroup.LabelText = '\textcircled' then
      LAccentBody.ShiftY := 0.2;

    LAccentBody := MakeVList(vpFirstBaseline, 0, [TMathVListChild.Elem(LBody), TMathVListChild.Kern(-LClearance),
      TMathVListChild.Elem(LAccentBody)], AOptions);
  end;

  TMathVListBox(LAccentBody).Alignment := vaCenter;

  var LAccentWrap: TMathBox := MakeSpan([MATH_CLASS_ORD, 'katex-accent'], [LAccentBody], AOptions);

  if Assigned(LSupSubGroup) then
  begin
    LSupSubGroup.Children[0] := LAccentWrap;
    LSupSubGroup.Height := Max(LAccentWrap.Height, LSupSubGroup.Height);
    LSupSubGroup.SetFirstClass(MATH_CLASS_ORD);

    Exit(LSupSubGroup);
  end;

  Result := LAccentWrap;
end;

function TMathBuilder.GetDelimiterMetrics(const ASymbol: string; const AFont: TMathFont; out AHeight: Double; out ADepth: Double; out AWidth: Double): Boolean;
begin
  var LReplaced := ASymbol;
  var LSymbol: PMathSymbolDefinition;

  if FindSymbol(mmMath, ASymbol, LSymbol) and not LSymbol.Replace.IsEmpty then
    LReplaced := LSymbol.Replace;

  var LMetrics: TMathCharacterMetrics;

  Result := GetCharacterMetrics(LReplaced, AFont, mmMath, LMetrics);

  if not Result then
    raise ParseMathError(Format('Unsupported symbol %s and font size', [ASymbol]));

  AHeight := LMetrics.Height;
  ADepth := LMetrics.Depth;
  AWidth := LMetrics.Width;
end;

function TMathBuilder.StyleWrap(const ADelimiter: TMathBox; const AToStyle: TMathStyle; const AOptions: TMathOptions;
  const AClasses: array of string): TMathSpanBox;
begin
  var LNewOptions := AOptions.HavingBaseStyle(AToStyle);

  Result := MakeSpan(AClasses, [ADelimiter], AOptions);

  ApplySizingClasses(Result, LNewOptions, AOptions);

  var LMultiplier: Double := LNewOptions.SizeMultiplier / AOptions.SizeMultiplier;

  Result.Height := Result.Height * LMultiplier;
  Result.Depth := Result.Depth * LMultiplier;
end;

procedure TMathBuilder.CenterSpan(const ASpan: TMathBox; const AOptions: TMathOptions; const AStyle: TMathStyle);
begin
  var LNewOptions := AOptions.HavingBaseStyle(AStyle);
  var LShift: Double := (1 - AOptions.SizeMultiplier / LNewOptions.SizeMultiplier) * AOptions.FontMetrics.AxisHeight;

  ASpan.AddClass('delimcenter');
  ASpan.ShiftY := LShift;
  ASpan.Height := ASpan.Height - LShift;
  ASpan.Depth := ASpan.Depth + LShift;
end;

function TMathBuilder.MakeSmallDelim(const ADelimiter: string; const AStyle: TMathStyle; const ACenter: Boolean;
  const AOptions: TMathOptions; const AMode: TMathMode; const AClasses: array of string): TMathBox;
begin
  Result := StyleWrap(MakeSymbol(ADelimiter, mfMainRegular, AMode, AOptions, []), AStyle, AOptions, AClasses);

  if ACenter then
    CenterSpan(Result, AOptions, AStyle);
end;

function TMathBuilder.MakeLargeDelim(const ADelimiter: string; const ASize: Integer; const ACenter: Boolean; const AOptions: TMathOptions;
  const AMode: TMathMode; const AClasses: array of string): TMathBox;
begin
  var LInner: TMathBox := MakeSymbol(ADelimiter, SizeFont(ASize), AMode, AOptions, []);
  Result := StyleWrap(MakeSpan(['delimsizing', 'size' + IntToStr(ASize)], [LInner], AOptions), TMathStyle.Text, AOptions,
    AClasses);

  if ACenter then
    CenterSpan(Result, AOptions, TMathStyle.Text);
end;

function TMathBuilder.MakeStackedDelim(const ADelimiter: string; const AHeightTotal: Double; const ACenter: Boolean;
  const AOptions: TMathOptions; const AMode: TMathMode; const AClasses: array of string): TMathBox;
var
  LFont: TMathFont;

  function MakeGlyphSpan(const ASymbol: string): TMathVListChild;
  var
    LPiece: TMathSpanBox;
  begin
    LPiece := MakeSpan(['delimsizinginner'], [MakeSpan([], [MakeSymbol(ASymbol, LFont, AMode, AOptions, [])])]);
    LPiece.Flags := [bfDelimiterPiece];
    Result := TMathVListChild.Elem(LPiece);
  end;

  function MakeInner(const ASymbol: string; const AInnerHeight: Double): TMathVListChild;
  var
    LRepeatBox: TMathRepeatBox;
    LGlyphHeight: Double;
    LGlyphDepth: Double;
    LGlyphWidth: Double;
  begin
    GetDelimiterMetrics(ASymbol, LFont, LGlyphHeight, LGlyphDepth, LGlyphWidth);
    LRepeatBox := NewBox(TMathRepeatBox.Create([]));
    LRepeatBox.Text := ASymbol;
    LRepeatBox.Font := LFont;
    LRepeatBox.GlyphHeight := LGlyphHeight;
    LRepeatBox.GlyphDepth := LGlyphDepth;
    LRepeatBox.GlyphWidth := LGlyphWidth;
    LRepeatBox.Height := AInnerHeight;
    LRepeatBox.Color := AOptions.GetColor;

    Result := TMathVListChild.Elem(LRepeatBox);
  end;

begin
  var LTop := ADelimiter;
  var LRepeat := ADelimiter;
  var LBottom := ADelimiter;
  var LMiddle := '';

  LFont := mfSize1Regular;

  if ADelimiter = '\uparrow' then
  begin
    LRepeat := #$23D0;
    LBottom := #$23D0;
  end
  else
  if ADelimiter = '\Uparrow' then
  begin
    LRepeat := #$2016;
    LBottom := #$2016;
  end
  else
  if ADelimiter = '\downarrow' then
  begin
    LTop := #$23D0;
    LRepeat := #$23D0;
  end
  else
  if ADelimiter = '\Downarrow' then
  begin
    LTop := #$2016;
    LRepeat := #$2016;
  end
  else
  if ADelimiter = '\updownarrow' then
  begin
    LTop := '\uparrow';
    LRepeat := #$23D0;
    LBottom := '\downarrow';
  end
  else
  if ADelimiter = '\Updownarrow' then
  begin
    LTop := '\Uparrow';
    LRepeat := #$2016;
    LBottom := '\Downarrow';
  end
  else
  if IsInList(ADelimiter, ['|', '\lvert', '\rvert', '\vert']) then
    LRepeat := #$2223
  else
  if IsInList(ADelimiter, ['\|', '\lVert', '\rVert', '\Vert']) then
    LRepeat := #$2225
  else
  if (ADelimiter = '[') or (ADelimiter = '\lbrack') then
  begin
    LTop := #$23A1;
    LRepeat := #$23A2;
    LBottom := #$23A3;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = ']') or (ADelimiter = '\rbrack') then
  begin
    LTop := #$23A4;
    LRepeat := #$23A5;
    LBottom := #$23A6;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = '\lfloor') or (ADelimiter = #$230A) then
  begin
    LTop := #$23A2;
    LRepeat := #$23A2;
    LBottom := #$23A3;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = '\lceil') or (ADelimiter = #$2308) then
  begin
    LTop := #$23A1;
    LRepeat := #$23A2;
    LBottom := #$23A2;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = '\rfloor') or (ADelimiter = #$230B) then
  begin
    LTop := #$23A5;
    LRepeat := #$23A5;
    LBottom := #$23A6;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = '\rceil') or (ADelimiter = #$2309) then
  begin
    LTop := #$23A4;
    LRepeat := #$23A5;
    LBottom := #$23A5;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = '(') or (ADelimiter = '\lparen') then
  begin
    LTop := #$239B;
    LRepeat := #$239C;
    LBottom := #$239D;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = ')') or (ADelimiter = '\rparen') then
  begin
    LTop := #$239E;
    LRepeat := #$239F;
    LBottom := #$23A0;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = '\{') or (ADelimiter = '\lbrace') then
  begin
    LTop := #$23A7;
    LMiddle := #$23A8;
    LBottom := #$23A9;
    LRepeat := #$23AA;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = '\}') or (ADelimiter = '\rbrace') then
  begin
    LTop := #$23AB;
    LMiddle := #$23AC;
    LBottom := #$23AD;
    LRepeat := #$23AA;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = '\lgroup') or (ADelimiter = #$27EE) then
  begin
    LTop := #$23A7;
    LBottom := #$23A9;
    LRepeat := #$23AA;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = '\rgroup') or (ADelimiter = #$27EF) then
  begin
    LTop := #$23AB;
    LBottom := #$23AD;
    LRepeat := #$23AA;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = '\lmoustache') or (ADelimiter = #$23B0) then
  begin
    LTop := #$23A7;
    LBottom := #$23AD;
    LRepeat := #$23AA;
    LFont := mfSize4Regular;
  end
  else
  if (ADelimiter = '\rmoustache') or (ADelimiter = #$23B1) then
  begin
    LTop := #$23AB;
    LBottom := #$23A9;
    LRepeat := #$23AA;
    LFont := mfSize4Regular;
  end
  else
  if ADelimiter = '\surd' then
  begin
    LTop := #$E001;
    LRepeat := #$E000;
    LBottom := #$23B7;
    LFont := mfSize4Regular;
  end;

  var LHeight: Double;
  var LDepth: Double;
  var LWidth: Double;

  GetDelimiterMetrics(LTop, LFont, LHeight, LDepth, LWidth);

  var LTopHeightTotal: Double := LHeight + LDepth;

  GetDelimiterMetrics(LRepeat, LFont, LHeight, LDepth, LWidth);

  var LRepeatHeightTotal: Double := LHeight + LDepth;

  GetDelimiterMetrics(LBottom, LFont, LHeight, LDepth, LWidth);

  var LBottomHeightTotal: Double := LHeight + LDepth;
  var LMiddleHeightTotal: Double := 0;
  var LMiddleFactor := 1;

  if not LMiddle.IsEmpty then
  begin
    GetDelimiterMetrics(LMiddle, LFont, LHeight, LDepth, LWidth);
    LMiddleHeightTotal := LHeight + LDepth;
    LMiddleFactor := 2;
  end;

  var LMinimumHeight: Double := LTopHeightTotal + LBottomHeightTotal + LMiddleHeightTotal;
  var LRepeatCount: Integer;
  var LRealHeightTotal: Double;

  if ADelimiter = '\surd' then
    LRealHeightTotal := Max(AHeightTotal, LMinimumHeight)
  else
  begin
    LRepeatCount := Max(0, Ceil((AHeightTotal - LMinimumHeight) / (LMiddleFactor * LRepeatHeightTotal)));
    LRealHeightTotal := LMinimumHeight + LRepeatCount * LMiddleFactor * LRepeatHeightTotal;
  end;

  var LAxisHeight: Double := AOptions.FontMetrics.AxisHeight;

  if ACenter then
    LAxisHeight := LAxisHeight * AOptions.SizeMultiplier;

  LDepth := LRealHeightTotal / 2 - LAxisHeight;

  var LStack: TArray<TMathVListChild> := [MakeGlyphSpan(LBottom), TMathVListChild.Kern(-LAP_IN_EMS)];
  var LInnerHeight: Double;

  if LMiddle.IsEmpty then
  begin
    LInnerHeight := LRealHeightTotal - LTopHeightTotal - LBottomHeightTotal + 2 * LAP_IN_EMS;
    LStack := LStack + [MakeInner(LRepeat, LInnerHeight)];
  end
  else
  begin
    LInnerHeight := (LRealHeightTotal - LTopHeightTotal - LBottomHeightTotal - LMiddleHeightTotal) / 2 + 2 * LAP_IN_EMS;
    LStack := LStack + [MakeInner(LRepeat, LInnerHeight), TMathVListChild.Kern(-LAP_IN_EMS), MakeGlyphSpan(LMiddle),
      TMathVListChild.Kern(-LAP_IN_EMS), MakeInner(LRepeat, LInnerHeight)];
  end;

  LStack := LStack + [TMathVListChild.Kern(-LAP_IN_EMS), MakeGlyphSpan(LTop)];

  var LNewOptions := AOptions.HavingBaseStyle(TMathStyle.Text);
  var LInner := MakeVList(vpBottom, if ADelimiter = '\surd' then 0 else LDepth, LStack, LNewOptions);

  Result := StyleWrap(MakeSpan(['delimsizing', 'mult'], [LInner], LNewOptions), TMathStyle.Text, AOptions, AClasses);
end;

function TMathBuilder.TraverseSequence(const ADelimiter: string; const AHeight: Double; const ASequence: array of TMathDelimiterType;
  const AOptions: TMathOptions): TMathDelimiterType;
begin
  var LStart := Min(2, 3 - AOptions.Style.Size);
  var LFont: TMathFont;
  var LHeight: Double;
  var LDepth: Double;
  var LWidth: Double;
  var LHeightDepth: Double;

  for var LIndex := LStart to High(ASequence) do
  begin
    if ASequence[LIndex].Kind = dkStack then
      Break;

    LFont := if ASequence[LIndex].Kind = dkSmall then mfMainRegular else SizeFont(ASequence[LIndex].Size);
    GetDelimiterMetrics(ADelimiter, LFont, LHeight, LDepth, LWidth);
    LHeightDepth := LHeight + LDepth;

    if ASequence[LIndex].Kind = dkSmall then
      LHeightDepth := LHeightDepth * AOptions.HavingBaseStyle(ASequence[LIndex].Style).SizeMultiplier;

    if LHeightDepth > AHeight then
      Exit(ASequence[LIndex]);
  end;

  Result := ASequence[High(ASequence)];
end;

function NormalizeDelimiter(const ADelimiter: string): string;
begin
  if (ADelimiter = '<') or (ADelimiter = '\lt') or (ADelimiter = #$27E8) then
    Result := '\langle'
  else
  if (ADelimiter = '>') or (ADelimiter = '\gt') or (ADelimiter = #$27E9) then
    Result := '\rangle'
  else
    Result := ADelimiter;
end;

function TMathBuilder.MakeSizedDelim(const ADelimiter: string; const ASize: Integer; const AOptions: TMathOptions; const AMode: TMathMode;
  const AClasses: array of string): TMathBox;
begin
  var LDelimiter := NormalizeDelimiter(ADelimiter);

  if IsInList(LDelimiter, STACK_LARGE_DELIMITERS) or IsInList(LDelimiter, STACK_NEVER_DELIMITERS) then
    Result := MakeLargeDelim(LDelimiter, ASize, False, AOptions, AMode, AClasses)
  else
  if IsInList(LDelimiter, STACK_ALWAYS_DELIMITERS) then
    Result := MakeStackedDelim(LDelimiter, SIZE_TO_MAX_HEIGHT[ASize], False, AOptions, AMode, AClasses)
  else
    raise ParseMathError('Illegal delimiter: ''' + LDelimiter + '''');
end;

function TMathBuilder.MakeCustomSizedDelim(const ADelimiter: string; const AHeight: Double; const ACenter: Boolean;
  const AOptions: TMathOptions; const AMode: TMathMode; const AClasses: array of string): TMathBox;
begin
  var LDelimiter := NormalizeDelimiter(ADelimiter);
  var LDelimiterType: TMathDelimiterType;

  if IsInList(LDelimiter, STACK_NEVER_DELIMITERS) then
    LDelimiterType := TraverseSequence(LDelimiter, AHeight, StackNeverDelimiterSequence, AOptions)
  else
  if IsInList(LDelimiter, STACK_LARGE_DELIMITERS) then
    LDelimiterType := TraverseSequence(LDelimiter, AHeight, StackLargeDelimiterSequence, AOptions)
  else
    LDelimiterType := TraverseSequence(LDelimiter, AHeight, StackAlwaysDelimiterSequence, AOptions);

  case LDelimiterType.Kind of
    dkSmall:
      Result := MakeSmallDelim(LDelimiter, LDelimiterType.Style, ACenter, AOptions, AMode, AClasses);
    dkLarge:
      Result := MakeLargeDelim(LDelimiter, LDelimiterType.Size, ACenter, AOptions, AMode, AClasses);
  else
    Result := MakeStackedDelim(LDelimiter, AHeight, ACenter, AOptions, AMode, AClasses);
  end;
end;

function TMathBuilder.MakeLeftRightDelim(const ADelimiter: string; const AHeight: Double; const ADepth: Double;
  const AOptions: TMathOptions; const AMode: TMathMode; const AClasses: array of string): TMathBox;
const
  DELIMITER_FACTOR = 901;
begin
  var LAxisHeight: Double := AOptions.FontMetrics.AxisHeight * AOptions.SizeMultiplier;
  var LDelimiterExtend: Double := 5.0 / AOptions.FontMetrics.PtPerEm;
  var LMaximumDistanceFromAxis: Double := Max(AHeight - LAxisHeight, ADepth + LAxisHeight);
  var LTotalHeight: Double := Max(LMaximumDistanceFromAxis / 500 * DELIMITER_FACTOR, 2 * LMaximumDistanceFromAxis - LDelimiterExtend);

  Result := MakeCustomSizedDelim(ADelimiter, LTotalHeight, True, AOptions, AMode, AClasses);
end;

function TMathBuilder.BuildDelimSizing(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  if AGroup.Delimiter = '.' then
    Result := MakeSpan([AGroup.MathClass], [])
  else
    Result := MakeSizedDelim(AGroup.Delimiter, AGroup.Size, AOptions, AGroup.Mode, [AGroup.MathClass]);
end;

function TMathBuilder.BuildLeftRight(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LInner := BuildExpression(AGroup.Body, AOptions, rgTrue, MATH_CLASS_OPEN, MATH_CLASS_CLOSE);
  var LInnerHeight: Double := 0;
  var LInnerDepth: Double := 0;
  var LHadMiddle := False;

  for var LIndex := 0 to LInner.Count - 1 do
  if LInner[LIndex].IsMiddle then
    LHadMiddle := True
  else
  begin
    LInnerHeight := Max(LInner[LIndex].Height, LInnerHeight);
    LInnerDepth := Max(LInner[LIndex].Depth, LInnerDepth);
  end;

  LInnerHeight := LInnerHeight * AOptions.SizeMultiplier;
  LInnerDepth := LInnerDepth * AOptions.SizeMultiplier;

  var LLeftDelimiter: TMathBox;

  if AGroup.LeftDelimiter = '.' then
    LLeftDelimiter := MakeNullDelimiter(AOptions, [MATH_CLASS_OPEN])
  else
    LLeftDelimiter := MakeLeftRightDelim(AGroup.LeftDelimiter, LInnerHeight, LInnerDepth, AOptions, AGroup.Mode, [MATH_CLASS_OPEN]);

  LInner.Insert(0, LLeftDelimiter);

  if LHadMiddle then
  for var LIndex := 1 to LInner.Count - 1 do
  if LInner[LIndex].IsMiddle then
    LInner[LIndex] := MakeLeftRightDelim(LInner[LIndex].MiddleDelimiter, LInnerHeight, LInnerDepth, TMathOptions(LInner[LIndex].MiddleOptions), AGroup.Mode, []);

  var LRightDelimiter: TMathBox;

  if AGroup.RightDelimiter = '.' then
    LRightDelimiter := MakeNullDelimiter(AOptions, [MATH_CLASS_CLOSE])
  else
  begin
    var LColorOptions := AOptions;
    var LColor: TMathColor;

    if not AGroup.RightColor.IsEmpty and TryParseMathColor(AGroup.RightColor, LColor) then
      LColorOptions := AOptions.WithColor(LColor);

    LRightDelimiter := MakeLeftRightDelim(AGroup.RightDelimiter, LInnerHeight, LInnerDepth, LColorOptions, AGroup.Mode, [MATH_CLASS_CLOSE]);
  end;

  LInner.Add(LRightDelimiter);

  Result := MakeSpan([MATH_CLASS_INNER], LInner, AOptions);
end;

function TMathBuilder.BuildText(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LFont := AGroup.Font;
  var LOptions: TMathOptions;

  if (LFont = '\textrm') or (LFont = '\textnormal') then
    LOptions := AOptions.WithTextFontFamily('textrm')
  else
  if LFont = '\textsf' then
    LOptions := AOptions.WithTextFontFamily('textsf')
  else
  if LFont = '\texttt' then
    LOptions := AOptions.WithTextFontFamily('texttt')
  else
  if LFont = '\textbf' then
    LOptions := AOptions.WithTextFontWeight('textbf')
  else
  if LFont = '\textmd' then
    LOptions := AOptions.WithTextFontWeight('textmd')
  else
  if LFont = '\emph' then
    LOptions := AOptions.WithTextFontShape(if AOptions.FontShape = 'textit' then 'textup' else 'textit')
  else
  if LFont = '\textit' then
    LOptions := AOptions.WithTextFontShape('textit')
  else
  if LFont = '\textup' then
    LOptions := AOptions.WithTextFontShape('textup')
  else
    LOptions := AOptions;

  Result := MakeSpan([MATH_CLASS_ORD, 'text'], BuildExpression(AGroup.Body, LOptions, rgTrue), LOptions);
end;

function TMathBuilder.BuildVerb(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LOptions := AOptions.HavingStyle(AOptions.Style.TextStyle);
  var LText := AGroup.Text.Replace(' ', if AGroup.IsStarred then #$2423 else #$00A0);
  var LBody := MakeList;

  for var LIndex := 1 to LText.Length do
    LBody.Add(MakeSymbol(if LText[LIndex] = '~' then '\textasciitilde' else string(LText[LIndex]), mfTypewriterRegular, AGroup.Mode,
      LOptions, [MATH_CLASS_ORD, 'texttt']));

  TryCombineChars(LBody);

  Result := MakeSpan([MATH_CLASS_ORD, 'text'], LBody, LOptions);

  ApplySizingClasses(Result, LOptions, AOptions);
end;

function TMathBuilder.BuildOverline(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LInnerGroup := BuildGroup(AGroup.Child, AOptions.HavingCrampedStyle);
  var LLine := MakeLineSpan('overline-line', AOptions);
  var LDefaultRuleThickness: Double := AOptions.FontMetrics.DefaultRuleThickness;

  Result := MakeSpan([MATH_CLASS_ORD, 'katex-overline'], [MakeVList(vpFirstBaseline, 0, [TMathVListChild.Elem(LInnerGroup),
    TMathVListChild.Kern(3 * LDefaultRuleThickness), TMathVListChild.Elem(LLine), TMathVListChild.Kern(LDefaultRuleThickness)], AOptions)], AOptions);
end;

function TMathBuilder.BuildUnderline(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LInnerGroup := BuildGroup(AGroup.Child, AOptions);
  var LLine := MakeLineSpan('underline-line', AOptions);
  var LDefaultRuleThickness: Double := AOptions.FontMetrics.DefaultRuleThickness;

  Result := MakeSpan([MATH_CLASS_ORD, 'katex-underline'], [MakeVList(vpTop, LInnerGroup.Height,
    [TMathVListChild.Kern(LDefaultRuleThickness), TMathVListChild.Elem(LLine),
    TMathVListChild.Kern(3 * LDefaultRuleThickness), TMathVListChild.Elem(LInnerGroup)], AOptions)], AOptions);
end;

function TMathBuilder.BuildLap(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
const
  LAP_CLASSES: array [TMathLapAlignment] of string = ('', 'llap', 'rlap', 'clap');
var
  LInner: TMathBox;
begin
  if AGroup.Alignment = laCenter then
  begin
    LInner := MakeSpan([], [BuildGroup(AGroup.Child, AOptions)]);
    LInner := MakeSpan(['katex-inner'], [LInner], AOptions);
  end
  else
    LInner := MakeSpan(['katex-inner'], [BuildGroup(AGroup.Child, AOptions)]);

  var LFix: TMathBox := MakeSpan(['katex-fix'], []);
  var LNode := MakeSpan([LAP_CLASSES[AGroup.Alignment]], [LInner, LFix], AOptions);

  LNode.SetFixedWidth(0);
  LNode.LapAlignment := AGroup.Alignment;

  Result := MakeSpan([MATH_CLASS_ORD, 'katex-vbox'], [MakeSpan(['katex-thinbox'], [LNode], AOptions)], AOptions);
end;

function TMathBuilder.BuildSmash(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LNode := MakeSpan([], [BuildGroup(AGroup.Child, AOptions)]);

  if not AGroup.SmashHeight and not AGroup.SmashDepth then
    Exit(LNode);

  if AGroup.SmashHeight then
    LNode.Height := 0;

  if AGroup.SmashDepth then
    LNode.Depth := 0;

  if AGroup.SmashHeight and AGroup.SmashDepth then
    Exit(MakeSpan([MATH_CLASS_ORD, 'katex-smash'], [LNode], AOptions));

  for var LIndex := 0 to LNode.Children.Count - 1 do
  begin
    if AGroup.SmashHeight then
      LNode.Children[LIndex].Height := 0;

    if AGroup.SmashDepth then
      LNode.Children[LIndex].Depth := 0;
  end;

  Result := MakeSpan([MATH_CLASS_ORD], [MakeVList(vpFirstBaseline, 0, [TMathVListChild.Elem(LNode)], AOptions)], AOptions);
end;

function TMathBuilder.BuildRule(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LRule: TMathRuleBox := NewBox(TMathRuleBox.Create([MATH_CLASS_ORD, 'katex-rule']));

  if AOptions.Style.IsTight then
    LRule.AddClass(CLASS_TIGHT);

  var LWidth: Double := CalculateSize(AGroup.RuleWidth, AOptions);
  var LHeight: Double := CalculateSize(AGroup.RuleHeight, AOptions);
  var LShift: Double := if AGroup.HasShift then CalculateSize(AGroup.RuleShift, AOptions) else 0;

  LRule.SetFixedWidth(LWidth);
  LRule.Height := LHeight + LShift;
  LRule.Depth := -LShift;
  LRule.Color := AOptions.GetColor;

  Result := LRule;
end;

function FindSvgPath(const AName: string): string;
begin
  for var LIndex := Low(SVG_PATHS) to High(SVG_PATHS) do
  if SVG_PATHS[LIndex].Name = AName then
    Exit(SVG_PATHS[LIndex].Data);

  raise ParseMathError('No SVG path ' + AName);
end;

function TMathBuilder.MakeStaticSvg(const AName: string; const AOptions: TMathOptions): TMathSvgBox;
var
  LWidth: Double;
  LHeight: Double;
begin
  if AName = 'oiintSize1' then
  begin
    LWidth := 0.957;
    LHeight := 0.499;
  end
  else
  if AName = 'oiintSize2' then
  begin
    LWidth := 1.472;
    LHeight := 0.659;
  end
  else
  if AName = 'oiiintSize1' then
  begin
    LWidth := 1.304;
    LHeight := 0.499;
  end
  else
  begin
    LWidth := 1.98;
    LHeight := 0.659;
  end;

  Result := NewBox(TMathSvgBox.Create(['katex-overlay']));
  Result.AddPart(FindSvgPath(AName), saMin, srFull);
  Result.ViewBoxWidth := 1000 * LWidth;
  Result.ViewBoxHeight := 1000 * LHeight;
  Result.SetFixedWidth(LWidth);
  Result.Height := LHeight;
  Result.Color := AOptions.GetColor;
end;

function TMathBuilder.MakeStretchySvg(const ALabel: string; const ABase: TMathParseNode; const AOptions: TMathOptions): TMathSvgBox;
const
  IMAGE_INDICES: array [0..5] of Integer = (1, 1, 2, 2, 3, 3);
  HAT_VIEW_BOX_WIDTHS: array [0..4] of Double = (0, 1062, 2364, 2364, 2364);
  HAT_VIEW_BOX_HEIGHTS: array [0..4] of Double = (0, 239, 300, 360, 420);
  HAT_HEIGHTS: array [0..5] of Double = (0, 0.24, 0.3, 0.3, 0.36, 0.42);
  TILDE_VIEW_BOX_WIDTHS: array [0..4] of Double = (0, 600, 1033, 2339, 2340);
  TILDE_VIEW_BOX_HEIGHTS: array [0..4] of Double = (0, 260, 286, 306, 312);
  TILDE_HEIGHTS: array [0..5] of Double = (0, 0.26, 0.286, 0.3, 0.306, 0.34);
begin
  var LLabel := Copy(ALabel, 2, MaxInt);

  Result := NewBox(TMathSvgBox.Create([]));
  Result.Color := AOptions.GetColor;
  Result.StretchWidth := True;

  if Assigned(ABase) and ((LLabel = 'widehat') or (LLabel = 'widecheck') or (LLabel = 'widetilde') or (LLabel = 'utilde')) then
  begin
    var LCharacterCount := if ABase.NodeType = ntOrdGroup then ABase.Body.Count else 1;
    var LIsHat := (LLabel = 'widehat') or (LLabel = 'widecheck');
    var LPathName: string;
    var LHeight: Double;

    if LCharacterCount > 5 then
    begin
      if LIsHat then
      begin
        Result.ViewBoxHeight := 420;
        Result.ViewBoxWidth := 2364;
        LHeight := 0.42;
        LPathName := LLabel + '4';
      end
      else
      begin
        Result.ViewBoxHeight := 312;
        Result.ViewBoxWidth := 2340;
        LHeight := 0.34;
        LPathName := 'tilde4';
      end;
    end
    else
    begin
      var LImageIndex := IMAGE_INDICES[LCharacterCount];

      if LIsHat then
      begin
        Result.ViewBoxWidth := HAT_VIEW_BOX_WIDTHS[LImageIndex];
        Result.ViewBoxHeight := HAT_VIEW_BOX_HEIGHTS[LImageIndex];
        LHeight := HAT_HEIGHTS[LImageIndex];
        LPathName := LLabel + IntToStr(LImageIndex);
      end
      else
      begin
        Result.ViewBoxWidth := TILDE_VIEW_BOX_WIDTHS[LImageIndex];
        Result.ViewBoxHeight := TILDE_VIEW_BOX_HEIGHTS[LImageIndex];
        LHeight := TILDE_HEIGHTS[LImageIndex];
        LPathName := 'tilde' + IntToStr(LImageIndex);
      end;
    end;

    Result.Stretch := True;
    Result.AddPart(FindSvgPath(LPathName), saMin, srFull);
    Result.Height := LHeight;

    Exit;
  end;

  var LFound := False;
  var LImage: TMathStretchyImage;

  for var LIndex := Low(STRETCHY_IMAGES) to High(STRETCHY_IMAGES) do
  if STRETCHY_IMAGES[LIndex].Name = LLabel then
  begin
    LImage := STRETCHY_IMAGES[LIndex];
    LFound := True;

    Break;
  end;

  if not LFound then
    raise ParseMathError(Format('No SVG data for "%s".', [LLabel]));

  Result.ViewBoxWidth := 400000;
  Result.ViewBoxHeight := LImage.ViewBoxHeight;
  Result.MinWidth := LImage.MinWidth;
  Result.Height := LImage.ViewBoxHeight / 1000;

  if LImage.Paths[1].IsEmpty then
    Result.AddPart(FindSvgPath(LImage.Paths[0]), LImage.Align, srFull)
  else
  if LImage.Paths[2].IsEmpty then
  begin
    Result.AddPart(FindSvgPath(LImage.Paths[0]), saMin, srLeftHalf);
    Result.AddPart(FindSvgPath(LImage.Paths[1]), saMax, srRightHalf);
  end
  else
  begin
    Result.AddPart(FindSvgPath(LImage.Paths[0]), saMin, srBraceLeft);
    Result.AddPart(FindSvgPath(LImage.Paths[1]), saMid, srBraceCenter);
    Result.AddPart(FindSvgPath(LImage.Paths[2]), saMax, srBraceRight);
  end;
end;

function TMathBuilder.BuildAccentUnder(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LInnerGroup := BuildGroup(AGroup.Base, AOptions);
  var LAccentBody: TMathBox := MakeStretchySvg(AGroup.LabelText, AGroup.Base, AOptions);
  var LKern: Double := if AGroup.LabelText = '\utilde' then 0.12 else 0;

  Result := MakeSpan([MATH_CLASS_ORD, 'accentunder'], [MakeVList(vpTop, LInnerGroup.Height, [TMathVListChild.Elem(LAccentBody),
    TMathVListChild.Kern(LKern), TMathVListChild.Elem(LInnerGroup)], AOptions)], AOptions);
end;

function TMathBuilder.BuildHorizBrace(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LStyle := AOptions.Style;
  var LSupSubGroup: TMathBox := nil;
  var LGroup: TMathParseNode;

  if AGroup.NodeType = ntSupSub then
  begin
    if Assigned(AGroup.Superscript) then
      LSupSubGroup := BuildGroup(AGroup.Superscript, AOptions.HavingStyle(LStyle.Superscript), AOptions)
    else
      LSupSubGroup := BuildGroup(AGroup.Subscript, AOptions.HavingStyle(LStyle.Subscript), AOptions);

    LGroup := AGroup.Base;
  end
  else
    LGroup := AGroup;

  var LBody := BuildGroup(LGroup.Base, AOptions.HavingBaseStyle(TMathStyle.Display));
  var LBraceBody: TMathBox := MakeStretchySvg(LGroup.LabelText, LGroup.Base, AOptions);
  var LClass := if LGroup.IsOver then 'mover' else 'munder';
  var LVList: TMathVListBox;

  if LGroup.IsOver then
    LVList := MakeVList(vpFirstBaseline, 0, [TMathVListChild.Elem(LBody), TMathVListChild.Kern(0.1),
      TMathVListChild.Elem(LBraceBody)], AOptions)
  else
    LVList := MakeVList(vpBottom, LBody.Depth + 0.1 + LBraceBody.Height, [TMathVListChild.Elem(LBraceBody),
      TMathVListChild.Kern(0.1), TMathVListChild.Elem(LBody)], AOptions);

  LVList.Alignment := vaCenter;

  if Assigned(LSupSubGroup) then
  begin
    var LVSpan: TMathBox := MakeSpan([MATH_CLASS_INNER, LClass], [LVList], AOptions);

    if LGroup.IsOver then
      LVList := MakeVList(vpFirstBaseline, 0, [TMathVListChild.Elem(LVSpan), TMathVListChild.Kern(0.2),
        TMathVListChild.Elem(LSupSubGroup)], AOptions)
    else
      LVList := MakeVList(vpBottom, LVSpan.Depth + 0.2 + LSupSubGroup.Height + LSupSubGroup.Depth,
        [TMathVListChild.Elem(LSupSubGroup), TMathVListChild.Kern(0.2), TMathVListChild.Elem(LVSpan)], AOptions);

    LVList.Alignment := vaCenter;
  end;

  Result := MakeSpan([MATH_CLASS_INNER, LClass], [LVList], AOptions);
end;

function TMathBuilder.BuildXArrow(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LStyle := AOptions.Style;
  var LPadClass: string;
  var LPadLeft: Double;
  var LPadRight: Double;

  if AGroup.LabelText.StartsWith('\x') then
  begin
    LPadClass := 'x-arrow-pad';
    LPadLeft := 0.5;
    LPadRight := 0.5;
  end
  else
  begin
    LPadClass := 'cd-arrow-pad';
    LPadLeft := 0.27778;
    LPadRight := 0.55556;
  end;

  var LUpperGroup := WrapFragment(BuildGroup(AGroup.Child, AOptions.HavingStyle(LStyle.Superscript), AOptions), AOptions);

  LUpperGroup.AddClass(LPadClass);
  LUpperGroup.PaddingLeft := LUpperGroup.PaddingLeft + LPadLeft;
  LUpperGroup.PaddingRight := LUpperGroup.PaddingRight + LPadRight;

  var LLowerGroup: TMathBox := nil;

  if Assigned(AGroup.Below) then
  begin
    LLowerGroup := WrapFragment(BuildGroup(AGroup.Below, AOptions.HavingStyle(LStyle.Subscript), AOptions), AOptions);
    LLowerGroup.AddClass(LPadClass);
    LLowerGroup.PaddingLeft := LLowerGroup.PaddingLeft + LPadLeft;
    LLowerGroup.PaddingRight := LLowerGroup.PaddingRight + LPadRight;
  end;

  var LArrowBody: TMathBox := MakeStretchySvg(AGroup.LabelText, nil, AOptions);
  var LAxisHeight: Double := AOptions.FontMetrics.AxisHeight;
  var LArrowShift: Double := -LAxisHeight + 0.5 * LArrowBody.Height;
  var LUpperShift: Double := -LAxisHeight - 0.5 * LArrowBody.Height - 0.111;

  if (LUpperGroup.Depth > 0.25) or (AGroup.LabelText = '\xleftequilibrium') then
    LUpperShift := LUpperShift - LUpperGroup.Depth;

  var LVList: TMathVListBox;

  if Assigned(LLowerGroup) then
  begin
    var LLowerShift: Double := -LAxisHeight + LLowerGroup.Height + 0.5 * LArrowBody.Height + 0.111;

    LVList := MakeVList(vpIndividualShift, 0, [TMathVListChild.Elem(LUpperGroup, LUpperShift),
      TMathVListChild.Elem(LArrowBody, LArrowShift), TMathVListChild.Elem(LLowerGroup, LLowerShift)], AOptions);
  end
  else
    LVList := MakeVList(vpIndividualShift, 0, [TMathVListChild.Elem(LUpperGroup, LUpperShift),
      TMathVListChild.Elem(LArrowBody, LArrowShift)], AOptions);

  LVList.Alignment := vaCenter;

  Result := MakeSpan([MATH_CLASS_REL, 'x-arrow'], [LVList], AOptions);
end;

function TMathBuilder.BuildCdLabel(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
const
  LABEL_BOX_BOTTOM = 0.389;
begin
  var LOptions := AOptions.HavingStyle(AOptions.Style.Superscript);
  var LLabel := WrapFragment(BuildGroup(AGroup.Child, LOptions, AOptions), AOptions);
  var LLabelScale: Double := LOptions.SizeMultiplier / AOptions.SizeMultiplier;
  var LWrapper := MakeSpan([], [LLabel]);

  LWrapper.Flags := [bfCdLabel];
  LWrapper.SetFixedWidth(0);
  LWrapper.ShiftY := -LLabelScale * (0.8 - LLabel.Depth) - Max(LABEL_BOX_BOTTOM * LLabelScale, LLabel.Depth);

  LWrapper.LapAlignment := AGroup.Alignment;
  LWrapper.ShiftX := if AGroup.Alignment = laLeft then -0.3 * LLabelScale else 0.3 * LLabelScale;

  LWrapper.Height := 0;
  LWrapper.Depth := 0;

  Result := LWrapper;
end;

function TMathBuilder.BuildCdLabelParent(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  Result := WrapFragment(BuildGroup(AGroup.Child, AOptions), AOptions);
  Result.AddClass('cd-vert-arrow');

  if not (Result is TMathSpanBox) then
    Exit;

  Result.Measure;

  var LChild: TMathBox;
  var LArrowWidth: Double := Result.Width;

  for var LIndex := 0 to TMathSpanBox(Result).Children.Count - 1 do
  begin
    LChild := TMathSpanBox(Result).Children[LIndex];

    if not (bfCdLabel in LChild.Flags) then
      Continue;

    if TMathSpanBox(LChild).LapAlignment = laLeft then
      LChild.ShiftX := LChild.ShiftX + LArrowWidth / 2
    else
      LChild.ShiftX := LChild.ShiftX - LArrowWidth / 2;

    LChild.ShiftY := LChild.ShiftY + Result.Depth;
  end;
end;

function TMathBuilder.BuildEnclose(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
begin
  var LInner := WrapFragment(BuildGroup(AGroup.Child, AOptions), AOptions);
  var LLabel := Copy(AGroup.LabelText, 2, MaxInt);
  var LScale: Double := AOptions.SizeMultiplier;
  var LIsSingleCharacter := IsCharacterBox(AGroup.Child);
  var LHasBackground := not AGroup.BackgroundColor.IsEmpty;
  var LImage: TMathBox;
  var LImageShift: Double;
  var LLineWeight: Double;
  var LClearance: Double;
  var LAngleHeight: Double;
  var LViewBoxHeight: Double;
  var LSvg: TMathSvgBox;
  var LFrame: TMathFrameBox;
  var LTopPad: Double;
  var LBottomPad: Double;
  var LRuleThickness: Double;
  var LColor: TMathColor;
  var LVList: TMathVListBox;

  if LLabel = 'sout' then
  begin
    LFrame := NewBox(TMathFrameBox.Create(['katex-stretchy', 'katex-sout']));
    LFrame.Height := AOptions.FontMetrics.DefaultRuleThickness / LScale;
    LFrame.BorderBottom := 0.08;
    LFrame.BorderColor := AOptions.GetColor;
    LFrame.StretchWidth := True;
    LImage := LFrame;
    LImageShift := -0.5 * AOptions.FontMetrics.XHeight;
  end
  else
  if LLabel = 'phase' then
  begin
    LLineWeight := CalculateSize(TMathMeasurement.Create(0.6, 'pt'), AOptions);
    LClearance := CalculateSize(TMathMeasurement.Create(0.35, 'ex'), AOptions);
    LScale := LScale / AOptions.HavingBaseSizing.SizeMultiplier;
    LAngleHeight := LInner.Height + LInner.Depth + LLineWeight + LClearance;
    LInner.PaddingLeft := LAngleHeight / 2 + LLineWeight;
    LViewBoxHeight := Floor(1000 * LAngleHeight * LScale);
    LSvg := NewBox(TMathSvgBox.Create(['hide-tail']));
    LSvg.AddPart(Format('M400000 %s H0 L%s 0 l65 45 L145 %s H400000z', [FloatToStr(LViewBoxHeight, TFormatSettings.Invariant),
      FloatToStr(LViewBoxHeight / 2, TFormatSettings.Invariant), FloatToStr(LViewBoxHeight - 80, TFormatSettings.Invariant)]), saMin, srFull);
    LSvg.ViewBoxWidth := 400000;
    LSvg.ViewBoxHeight := LViewBoxHeight;
    LSvg.Height := LViewBoxHeight / 1000;
    LSvg.StretchWidth := True;
    LSvg.Color := AOptions.GetColor;
    LImage := LSvg;
    LImageShift := LInner.Depth + LLineWeight + LClearance;
  end
  else
  begin
    if LLabel.Contains('cancel') then
    begin
      if not LIsSingleCharacter then
      begin
        LInner.AddClass('cancel-pad');
        LInner.PaddingLeft := LInner.PaddingLeft + 0.2;
        LInner.PaddingRight := LInner.PaddingRight + 0.2;
      end;
    end
    else
    if LLabel = 'angl' then
    begin
      LInner.AddClass('anglpad');
      LInner.PaddingLeft := LInner.PaddingLeft + 0.03889;
      LInner.PaddingRight := LInner.PaddingRight + 0.03889;
    end
    else
    begin
      LInner.AddClass('boxpad');
      LInner.PaddingLeft := LInner.PaddingLeft + 0.3;
      LInner.PaddingRight := LInner.PaddingRight + 0.3;
    end;

    LRuleThickness := 0;

    if LLabel.Contains('box') then
    begin
      LRuleThickness := Max(AOptions.FontMetrics.FBoxRule, AOptions.MinRuleThickness);
      LTopPad := AOptions.FontMetrics.FBoxSep + (if LLabel = 'colorbox' then 0 else LRuleThickness);
      LBottomPad := LTopPad;
    end
    else
    if LLabel = 'angl' then
    begin
      LRuleThickness := Max(AOptions.FontMetrics.DefaultRuleThickness, AOptions.MinRuleThickness);
      LTopPad := 4 * LRuleThickness;
      LBottomPad := Max(0, 0.25 - LInner.Depth);
    end
    else
    begin
      LTopPad := if LIsSingleCharacter then 0.2 else 0;
      LBottomPad := LTopPad;
    end;

    LFrame := NewBox(TMathFrameBox.Create(['katex-stretchy', LLabel]));
    LFrame.Height := LInner.Height + LInner.Depth + LTopPad + LBottomPad;
    LFrame.StretchWidth := True;
    LFrame.BorderColor := AOptions.GetColor;

    if LLabel = 'cancel' then
      LFrame.CancelLines := [clForward]
    else
    if LLabel = 'bcancel' then
      LFrame.CancelLines := [clBackward]
    else
    if LLabel = 'xcancel' then
      LFrame.CancelLines := [clForward, clBackward];

    LFrame.LineWidth := 0.046;

    if (LLabel = 'fbox') or (LLabel = 'boxed') or (LLabel = 'fcolorbox') then
      LFrame.SetBorder(LRuleThickness)
    else
    if LLabel = 'angl' then
    begin
      LFrame.BorderTop := LRuleThickness;
      LFrame.BorderRight := LRuleThickness;
      LFrame.MarginRight := 0.03889;
    end;

    LImageShift := LInner.Depth + LBottomPad;

    if LHasBackground then
    begin
      if TryParseMathColor(AGroup.BackgroundColor, LColor) then
        LFrame.BackgroundColor := LColor;

      if not AGroup.BorderColor.IsEmpty and TryParseMathColor(AGroup.BorderColor, LColor) then
        LFrame.BorderColor := LColor;
    end;

    LImage := LFrame;
  end;

  if LHasBackground then
    LVList := MakeVList(vpIndividualShift, 0, [TMathVListChild.Elem(LImage, LImageShift), TMathVListChild.Elem(LInner, 0)], AOptions)
  else
    LVList := MakeVList(vpIndividualShift, 0, [TMathVListChild.Elem(LInner, 0), TMathVListChild.Elem(LImage, LImageShift)], AOptions);

  if LLabel.Contains('cancel') then
  begin
    LVList.Height := LInner.Height;
    LVList.Depth := LInner.Depth;
  end;

  if LLabel.Contains('cancel') and not LIsSingleCharacter then
  begin
    Result := MakeSpan([MATH_CLASS_ORD, 'cancel-lap'], [LVList], AOptions);
    Result.MarginLeft := -0.2;
    Result.MarginRight := -0.2;
  end
  else
    Result := MakeSpan([MATH_CLASS_ORD], [LVList], AOptions);
end;

function TMathBuilder.BuildEquationNumber(const AOptions: TMathOptions): TMathBox;
begin
  var LText := '(' + IntToStr(FEquationNumber) + ')';

  Inc(FEquationNumber);

  var LBody := FArena.NewList;
  var LCharacter: TMathParseNode;

  for var LIndex := 1 to LText.Length do
  begin
    LCharacter := FArena.NewNode(ntTextOrd, mmText);
    LCharacter.Text := LText[LIndex];
    LBody.Add(LCharacter);
  end;

  Result := MakeSpan(['eqn-num'], BuildExpression(LBody, AOptions.WithTextFontFamily('textrm'), rgFalse), AOptions);
end;

function TMathBuilder.BuildArray(const AGroup: TMathParseNode; const AOptions: TMathOptions): TMathBox;
type
  TMathOutputRow = record
    Cells: TArray<TMathBox>;
    Depth: Double;
    Height: Double;
    Position: Double;
  end;

  TMathHorizontalLine = record
    IsDashed: Boolean;
    Position: Double;
  end;

var
  LHorizontalLines: TArray<TMathHorizontalLine>;
  LTotalHeight: Double;
  LDescriptions: TArray<TMathAlignSpec>;
  LColumns: TMathBoxList;

  procedure SetHorizontalLinePositions(const ALines: TArray<Boolean>);
  var
    LLineInfo: TMathHorizontalLine;
  begin
    for var LIndex := 0 to High(ALines) do
    begin
      if LIndex > 0 then
        LTotalHeight := LTotalHeight + 0.25;

      LLineInfo.Position := LTotalHeight;
      LLineInfo.IsDashed := ALines[LIndex];
      LHorizontalLines := LHorizontalLines + [LLineInfo];
    end;
  end;

  function DescriptionAt(const AIndex: Integer; out ADescription: TMathAlignSpec): Boolean;
  begin
    Result := (AIndex >= 0) and (AIndex < Length(LDescriptions));

    if Result then
      ADescription := LDescriptions[AIndex]
    else
      ADescription := Default(TMathAlignSpec);
  end;

  procedure AddColumnSeparation(const AWidth: Double);
  var
    LSpace: TMathBox;
  begin
    LSpace := MakeSpan(['arraycolsep'], []);
    LSpace.SetFixedWidth(AWidth);

    LColumns.Add(LSpace);
  end;

begin
  var LRowCount := AGroup.Rows.Count;
  var LColumnCount := 0;
  var LRows: TArray<TMathOutputRow>;

  SetLength(LRows, LRowCount);

  LHorizontalLines := nil;

  var LRuleThickness: Double := Max(AOptions.FontMetrics.ArrayRuleWidth, AOptions.MinRuleThickness);
  var LPoint: Double := 1 / AOptions.FontMetrics.PtPerEm;
  var LArrayColumnSeparation: Double := 5 * LPoint;

  if AGroup.ColSeparationType = csSmall then
    LArrayColumnSeparation := 0.2778 * (AOptions.HavingStyle(TMathStyle.Script).SizeMultiplier / AOptions.SizeMultiplier);

  var LJot: Double := 3 * LPoint;
  var LArraySkip: Double;

  if AGroup.ColSeparationType = csCD then
    LArraySkip := AGroup.ArrayStretch * CalculateSize(TMathMeasurement.Create(3, 'ex'), AOptions)
  else
    LArraySkip := AGroup.ArrayStretch * 12 * LPoint;

  var LStrutHeight: Double := 0.7 * LArraySkip;
  var LStrutDepth: Double := 0.3 * LArraySkip;

  LTotalHeight := 0;

  SetHorizontalLinePositions(AGroup.HLinesBeforeRow[0]);

  var LHeight: Double;
  var LDepth: Double;
  var LCell: TMathBox;
  var LGap: Double;

  for var LRow := 0 to LRowCount - 1 do
  begin
    LHeight := LStrutHeight;
    LDepth := LStrutDepth;
    LColumnCount := Max(LColumnCount, AGroup.Rows[LRow].Count);
    SetLength(LRows[LRow].Cells, AGroup.Rows[LRow].Count);

    for var LIndex := 0 to AGroup.Rows[LRow].Count - 1 do
    begin
      LCell := BuildGroup(AGroup.Rows[LRow][LIndex], AOptions);
      LDepth := Max(LDepth, LCell.Depth);
      LHeight := Max(LHeight, LCell.Height);
      LRows[LRow].Cells[LIndex] := LCell;
    end;

    LGap := 0;

    if (LRow < Length(AGroup.RowGaps)) and AGroup.RowGaps[LRow].HasSize then
    begin
      LGap := CalculateSize(AGroup.RowGaps[LRow].Size, AOptions);

      if LGap > 0 then
      begin
        LGap := LGap + LStrutDepth;
        LDepth := Max(LDepth, LGap);
        LGap := 0;
      end;
    end;

    if AGroup.AddJot and (LRow < LRowCount - 1) then
      LDepth := LDepth + LJot;

    LRows[LRow].Height := LHeight;
    LRows[LRow].Depth := LDepth;
    LTotalHeight := LTotalHeight + LHeight;
    LRows[LRow].Position := LTotalHeight;
    LTotalHeight := LTotalHeight + LDepth + LGap;

    if LRow + 1 < Length(AGroup.HLinesBeforeRow) then
      SetHorizontalLinePositions(AGroup.HLinesBeforeRow[LRow + 1]);
  end;

  var LOffset: Double := LTotalHeight / 2 + AOptions.FontMetrics.AxisHeight;

  LDescriptions := AGroup.Columns;
  LColumns := MakeList;

  var LTagChildren: TArray<TMathVListChild> := nil;
  var LHasTags: Boolean := False;

  if AGroup.HasTags then
  for var LRow := 0 to High(AGroup.RowTags) do
  if AGroup.RowTags[LRow].Kind <> tkNone then
    LHasTags := True;

  var LTagSpan: TMathBox;

  if LHasTags then
  for var LRow := 0 to LRowCount - 1 do
  begin
    case AGroup.RowTags[LRow].Kind of
      tkAutomatic:
        LTagSpan := BuildEquationNumber(AOptions);
      tkManual:
        LTagSpan := MakeSpan([], BuildExpression(AGroup.RowTags[LRow].Body, AOptions, rgTrue), AOptions);
    else
      LTagSpan := MakeSpan([], [], AOptions);
    end;

    LTagSpan.Depth := LRows[LRow].Depth;
    LTagSpan.Height := LRows[LRow].Height;
    LTagChildren := LTagChildren + [TMathVListChild.Elem(LTagSpan, LRows[LRow].Position - LOffset)];
  end;

  var LColumn := 0;
  var LDescriptionIndex := 0;
  var LDescription: TMathAlignSpec;
  var LHasDescription: Boolean;
  var LFirstSeparator: Boolean;
  var LSeparator: TMathRuleBox;
  var LShift: Double;
  var LSeparatorWidth: Double;
  var LColumnChildren: TArray<TMathVListChild>;
  var LColumnVList: TMathVListBox;
  var LAlign: TMathColumnAlign;
  var LTableBody: TMathBox;
  var LLine: TMathRuleBox;
  var LDashes: TMathRuleBox;
  var LLineChildren: TArray<TMathVListChild>;
  var LTagColumn: TMathBox;

  while (LColumn < LColumnCount) or (LDescriptionIndex < Length(LDescriptions)) do
  begin
    LHasDescription := DescriptionAt(LDescriptionIndex, LDescription);
    LFirstSeparator := True;

    while LHasDescription and LDescription.IsSeparator do
    begin
      if not LFirstSeparator then
        AddColumnSeparation(AOptions.FontMetrics.DoubleRuleSep);

      LSeparator := NewBox(TMathRuleBox.Create(['vertical-separator']));

      if AOptions.Style.IsTight then
        LSeparator.AddClass(CLASS_TIGHT);

      LSeparator.SetFixedWidth(LRuleThickness);
      LSeparator.MarginLeft := -LRuleThickness / 2;
      LSeparator.MarginRight := -LRuleThickness / 2;
      LSeparator.Dashed := LDescription.IsDashed;
      LSeparator.Color := AOptions.GetColor;
      LShift := LTotalHeight - LOffset;
      LSeparator.SetDrawExtent(LTotalHeight - LShift, LShift);
      LColumns.Add(LSeparator);
      Inc(LDescriptionIndex);
      LHasDescription := DescriptionAt(LDescriptionIndex, LDescription);
      LFirstSeparator := False;
    end;

    if LColumn < LColumnCount then
    begin
      if (LColumn > 0) or AGroup.HSkipBeforeAndAfter then
      begin
        LSeparatorWidth := if LHasDescription and LDescription.HasPregap then LDescription.Pregap else LArrayColumnSeparation;

        if LSeparatorWidth <> 0 then
          AddColumnSeparation(LSeparatorWidth);
      end;

      LColumnChildren := nil;

      for var LRow := 0 to LRowCount - 1 do
      if LColumn < Length(LRows[LRow].Cells) then
      begin
        LCell := LRows[LRow].Cells[LColumn];
        LCell.Depth := LRows[LRow].Depth;
        LCell.Height := LRows[LRow].Height;
        LColumnChildren := LColumnChildren + [TMathVListChild.Elem(LCell, LRows[LRow].Position - LOffset)];
      end;

      LAlign := if LHasDescription then LDescription.Align else caCenter;
      LColumnVList := MakeVList(vpIndividualShift, 0, LColumnChildren, AOptions);

      case LAlign of
        caLeft:
          LColumnVList.Alignment := vaLeft;
        caRight:
          LColumnVList.Alignment := vaRight;
      else
        LColumnVList.Alignment := vaCenter;
      end;

      LColumns.Add(MakeSpan(['col-align-' + COLUMN_ALIGN_LETTERS[LAlign]], [LColumnVList]));

      if (LColumn < LColumnCount - 1) or AGroup.HSkipBeforeAndAfter then
      begin
        LSeparatorWidth := if LHasDescription and LDescription.HasPostgap then LDescription.Postgap else LArrayColumnSeparation;

        if LSeparatorWidth <> 0 then
          AddColumnSeparation(LSeparatorWidth);
      end;
    end;

    Inc(LColumn);
    Inc(LDescriptionIndex);
  end;

  LTableBody := MakeSpan(['mtable'], LColumns);

  if Length(LHorizontalLines) > 0 then
  begin
    LLine := MakeLineSpan('katex-hline', AOptions, LRuleThickness);
    LDashes := MakeLineSpan('katex-hdashline', AOptions, LRuleThickness);
    LDashes.Dashed := True;
    LLineChildren := [TMathVListChild.Elem(LTableBody, 0)];

    for var LIndex := High(LHorizontalLines) downto 0 do
      LLineChildren := LLineChildren + [TMathVListChild.Elem(if LHorizontalLines[LIndex].IsDashed then LDashes else LLine,
        LHorizontalLines[LIndex].Position - LOffset)];

    LTableBody := MakeVList(vpIndividualShift, 0, LLineChildren, AOptions);
  end;

  if Length(LTagChildren) = 0 then
    Exit(MakeSpan([MATH_CLASS_ORD], [LTableBody], AOptions));

  LTagColumn := MakeSpan([], [MakeVList(vpIndividualShift, 0, LTagChildren, AOptions)], AOptions);
  LTagColumn.Flags := [bfTag];

  Result := MakeFragment(MakeList([LTableBody, LTagColumn]));
end;

end.
