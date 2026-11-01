unit MathRenderer.ParseTree;

interface

uses
  System.Generics.Collections, MathRenderer.Types;

type
  TMathNodeType = (ntAccent, ntAccentToken, ntAccentUnder, ntArray, ntAtom, ntCdLabel, ntCdLabelParent, ntColor, ntColorToken, ntCr,
    ntDelimSizing, ntEnclose, ntEnvironment, ntFont, ntGenFrac, ntHorizBrace, ntInfix, ntInternal, ntKern, ntLap, ntLeftRight,
    ntLeftRightRight, ntMathChoice, ntMathOrd, ntMClass, ntMiddle, ntOp, ntOpToken, ntOperatorName, ntOrdGroup, ntOverline, ntPhantom,
    ntPmb, ntRaiseBox, ntReflectBox, ntRule, ntSize, ntSizing, ntSmash, ntSpacing, ntSqrt, ntStyling, ntSupSub, ntTag, ntText, ntTextOrd,
    ntUnderline, ntVCenter, ntVerb, ntVPhantom, ntXArrow);

  TMathParseNode = class;
  TMathNodeList = TList<TMathParseNode>;
  TMathNodeRows = TList<TMathNodeList>;

  TMathColumnAlign = (caCenter, caLeft, caRight);
  TMathColumnSeparation = (csDefault, csAlign, csAlignAt, csGather, csSmall, csCD);

  TMathAlignSpec = record
    Align: TMathColumnAlign;
    HasPostgap: Boolean;
    HasPregap: Boolean;
    IsDashed: Boolean;
    IsSeparator: Boolean;
    Postgap: Double;
    Pregap: Double;
    class function Column(const AAlign: TMathColumnAlign): TMathAlignSpec; static;
    class function ColumnWithGaps(const AAlign: TMathColumnAlign; const APregap: Double; const APostgap: Double): TMathAlignSpec; static;
    class function SeparatorLine(const AIsDashed: Boolean): TMathAlignSpec; static;
  end;

  TMathRowGap = record
    HasSize: Boolean;
    Size: TMathMeasurement;
  end;

  TMathTagKind = (tkNone, tkAutomatic, tkManual);

  TMathRowTag = record
    Body: TMathNodeList;
    Kind: TMathTagKind;
  end;

  TMathParseNode = class(TObject)
  strict private
    FAddJot: Boolean;
    FAlignment: TMathLapAlignment;
    FAlwaysHandleSupSub: Boolean;
    FArrayStretch: Double;
    FBackgroundColor: string;
    FBarSize: TMathMeasurement;
    FBase: TMathParseNode;
    FBelow: TMathParseNode;
    FBody: TMathNodeList;
    FBorderColor: string;
    FChild: TMathParseNode;
    FColSeparationType: TMathColumnSeparation;
    FColumns: TArray<TMathAlignSpec>;
    FColor: string;
    FContinued: Boolean;
    FDelimiter: string;
    FDenominator: TMathParseNode;
    FDimension: TMathMeasurement;
    FDisplayBody: TMathNodeList;
    FFamily: TMathSymbolGroup;
    FFont: string;
    FHasBarLine: Boolean;
    FHasBarSize: Boolean;
    FHasBody: Boolean;
    FHasDimension: Boolean;
    FHasShift: Boolean;
    FHasTags: Boolean;
    FHLinesBeforeRow: TArray<TArray<Boolean>>;
    FHSkipBeforeAndAfter: Boolean;
    FIndex: TMathParseNode;
    FIsBlank: Boolean;
    FIsCharacterBox: Boolean;
    FIsOver: Boolean;
    FIsShifty: Boolean;
    FIsStarred: Boolean;
    FIsStretchy: Boolean;
    FLabel: string;
    FLeftDelimiter: string;
    FLimits: Boolean;
    FMathClass: string;
    FMode: TMathMode;
    FName: string;
    FNewLine: Boolean;
    FNodeType: TMathNodeType;
    FNumerator: TMathParseNode;
    FParentIsSupSub: Boolean;
    FReplaceWith: string;
    FResetFont: Boolean;
    FRightColor: string;
    FRightDelimiter: string;
    FRowGaps: TArray<TMathRowGap>;
    FRows: TMathNodeRows;
    FRowTags: TArray<TMathRowTag>;
    FRuleHeight: TMathMeasurement;
    FRuleShift: TMathMeasurement;
    FRuleWidth: TMathMeasurement;
    FScriptBody: TMathNodeList;
    FScriptScriptBody: TMathNodeList;
    FSemisimple: Boolean;
    FSize: Integer;
    FSmashDepth: Boolean;
    FSmashHeight: Boolean;
    FStyle: TMathStyleName;
    FSubscript: TMathParseNode;
    FSuperscript: TMathParseNode;
    FSuppressBaseShift: Boolean;
    FSymbol: Boolean;
    FTagBody: TMathNodeList;
    FText: string;
    FTextBody: TMathNodeList;
    FValue: TMathMeasurement;
  public
    constructor Create(const ANodeType: TMathNodeType; const AMode: TMathMode);
    property AddJot: Boolean read FAddJot write FAddJot;
    property Alignment: TMathLapAlignment read FAlignment write FAlignment;
    property AlwaysHandleSupSub: Boolean read FAlwaysHandleSupSub write FAlwaysHandleSupSub;
    property ArrayStretch: Double read FArrayStretch write FArrayStretch;
    property BackgroundColor: string read FBackgroundColor write FBackgroundColor;
    property BarSize: TMathMeasurement read FBarSize write FBarSize;
    property Base: TMathParseNode read FBase write FBase;
    property Below: TMathParseNode read FBelow write FBelow;
    property Body: TMathNodeList read FBody write FBody;
    property BorderColor: string read FBorderColor write FBorderColor;
    property Child: TMathParseNode read FChild write FChild;
    property ColSeparationType: TMathColumnSeparation read FColSeparationType write FColSeparationType;
    property Columns: TArray<TMathAlignSpec> read FColumns write FColumns;
    property Color: string read FColor write FColor;
    property Continued: Boolean read FContinued write FContinued;
    property Delimiter: string read FDelimiter write FDelimiter;
    property Denominator: TMathParseNode read FDenominator write FDenominator;
    property Dimension: TMathMeasurement read FDimension write FDimension;
    property DisplayBody: TMathNodeList read FDisplayBody write FDisplayBody;
    property Family: TMathSymbolGroup read FFamily write FFamily;
    property Font: string read FFont write FFont;
    property HasBarLine: Boolean read FHasBarLine write FHasBarLine;
    property HasBarSize: Boolean read FHasBarSize write FHasBarSize;
    property HasBody: Boolean read FHasBody write FHasBody;
    property HasDimension: Boolean read FHasDimension write FHasDimension;
    property HasShift: Boolean read FHasShift write FHasShift;
    property HasTags: Boolean read FHasTags write FHasTags;
    property HLinesBeforeRow: TArray<TArray<Boolean>> read FHLinesBeforeRow write FHLinesBeforeRow;
    property HSkipBeforeAndAfter: Boolean read FHSkipBeforeAndAfter write FHSkipBeforeAndAfter;
    property Index: TMathParseNode read FIndex write FIndex;
    property IsBlank: Boolean read FIsBlank write FIsBlank;
    property IsCharacterBox: Boolean read FIsCharacterBox write FIsCharacterBox;
    property IsOver: Boolean read FIsOver write FIsOver;
    property IsShifty: Boolean read FIsShifty write FIsShifty;
    property IsStarred: Boolean read FIsStarred write FIsStarred;
    property IsStretchy: Boolean read FIsStretchy write FIsStretchy;
    property LabelText: string read FLabel write FLabel;
    property LeftDelimiter: string read FLeftDelimiter write FLeftDelimiter;
    property Limits: Boolean read FLimits write FLimits;
    property MathClass: string read FMathClass write FMathClass;
    property Mode: TMathMode read FMode write FMode;
    property Name: string read FName write FName;
    property NewLine: Boolean read FNewLine write FNewLine;
    property NodeType: TMathNodeType read FNodeType;
    property Numerator: TMathParseNode read FNumerator write FNumerator;
    property ParentIsSupSub: Boolean read FParentIsSupSub write FParentIsSupSub;
    property ReplaceWith: string read FReplaceWith write FReplaceWith;
    property ResetFont: Boolean read FResetFont write FResetFont;
    property RightColor: string read FRightColor write FRightColor;
    property RightDelimiter: string read FRightDelimiter write FRightDelimiter;
    property RowGaps: TArray<TMathRowGap> read FRowGaps write FRowGaps;
    property Rows: TMathNodeRows read FRows write FRows;
    property RowTags: TArray<TMathRowTag> read FRowTags write FRowTags;
    property RuleHeight: TMathMeasurement read FRuleHeight write FRuleHeight;
    property RuleShift: TMathMeasurement read FRuleShift write FRuleShift;
    property RuleWidth: TMathMeasurement read FRuleWidth write FRuleWidth;
    property ScriptBody: TMathNodeList read FScriptBody write FScriptBody;
    property ScriptScriptBody: TMathNodeList read FScriptScriptBody write FScriptScriptBody;
    property Semisimple: Boolean read FSemisimple write FSemisimple;
    property Size: Integer read FSize write FSize;
    property SmashDepth: Boolean read FSmashDepth write FSmashDepth;
    property SmashHeight: Boolean read FSmashHeight write FSmashHeight;
    property Style: TMathStyleName read FStyle write FStyle;
    property Subscript: TMathParseNode read FSubscript write FSubscript;
    property Superscript: TMathParseNode read FSuperscript write FSuperscript;
    property SuppressBaseShift: Boolean read FSuppressBaseShift write FSuppressBaseShift;
    property Symbol: Boolean read FSymbol write FSymbol;
    property TagBody: TMathNodeList read FTagBody write FTagBody;
    property Text: string read FText write FText;
    property TextBody: TMathNodeList read FTextBody write FTextBody;
    property Value: TMathMeasurement read FValue write FValue;
  end;

  TMathParseArena = class(TObject)
  strict private
    FObjects: TObjectList<TObject>;
  public
    constructor Create;
    destructor Destroy; override;
    function NewList: TMathNodeList; overload;
    function NewList(const ANodes: array of TMathParseNode): TMathNodeList; overload;
    function NewNode(const ANodeType: TMathNodeType; const AMode: TMathMode): TMathParseNode;
    function NewRows: TMathNodeRows;
  end;

const
  COLUMN_ALIGN_LETTERS: array [TMathColumnAlign] of string = ('c', 'l', 'r');

function GetBaseElement(const ANode: TMathParseNode): TMathParseNode;
function IsCharacterBox(const ANode: TMathParseNode): Boolean;
function IsSymbolNode(const ANode: TMathParseNode): Boolean;

implementation

constructor TMathParseNode.Create(const ANodeType: TMathNodeType; const AMode: TMathMode);
begin
  inherited Create;

  FNodeType := ANodeType;
  FMode := AMode;
end;

constructor TMathParseArena.Create;
begin
  inherited Create;

  FObjects := TObjectList<TObject>.Create(True);
end;

destructor TMathParseArena.Destroy;
begin
  FObjects.Free;

  inherited Destroy;
end;

function TMathParseArena.NewList: TMathNodeList;
begin
  Result := TMathNodeList.Create;
  FObjects.Add(Result);
end;

function TMathParseArena.NewList(const ANodes: array of TMathParseNode): TMathNodeList;
begin
  Result := NewList;

  for var LIndex := Low(ANodes) to High(ANodes) do
    Result.Add(ANodes[LIndex]);
end;

function TMathParseArena.NewNode(const ANodeType: TMathNodeType; const AMode: TMathMode): TMathParseNode;
begin
  Result := TMathParseNode.Create(ANodeType, AMode);
  FObjects.Add(Result);
end;

function TMathParseArena.NewRows: TMathNodeRows;
begin
  Result := TMathNodeRows.Create;
  FObjects.Add(Result);
end;

{ TMathAlignSpec }

class function TMathAlignSpec.Column(const AAlign: TMathColumnAlign): TMathAlignSpec;
begin
  Result := Default(TMathAlignSpec);
  Result.Align := AAlign;
end;

class function TMathAlignSpec.ColumnWithGaps(const AAlign: TMathColumnAlign; const APregap: Double; const APostgap: Double): TMathAlignSpec;
begin
  Result := Column(AAlign);
  Result.Pregap := APregap;
  Result.Postgap := APostgap;
  Result.HasPregap := True;
  Result.HasPostgap := True;
end;

class function TMathAlignSpec.SeparatorLine(const AIsDashed: Boolean): TMathAlignSpec;
begin
  Result := Default(TMathAlignSpec);
  Result.IsSeparator := True;
  Result.IsDashed := AIsDashed;
end;

function GetBaseElement(const ANode: TMathParseNode): TMathParseNode;
begin
  case ANode.NodeType of
    ntOrdGroup, ntColor:
      if ANode.Body.Count = 1 then
        Result := GetBaseElement(ANode.Body[0])
      else
        Result := ANode;
    ntFont:
      Result := GetBaseElement(ANode.Child);
  else
    Result := ANode;
  end;
end;

function IsCharacterBox(const ANode: TMathParseNode): Boolean;
begin
  Result := GetBaseElement(ANode).NodeType in [ntMathOrd, ntTextOrd, ntAtom];
end;

function IsSymbolNode(const ANode: TMathParseNode): Boolean;
begin
  Result := ANode.NodeType in [ntAccentToken, ntAtom, ntMathOrd, ntOpToken, ntSpacing, ntTextOrd];
end;

end.
