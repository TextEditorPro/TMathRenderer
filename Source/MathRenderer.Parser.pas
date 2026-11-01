unit MathRenderer.Parser;

interface

uses
  System.Generics.Collections, MathRenderer.ParseTree, MathRenderer.Types;

type
  TMathToken = record
    NoExpand: Boolean;
    Position: Integer;
    Text: string;
    TreatAsRelax: Boolean;
    class function Create(const AText: string; const APosition: Integer = -1): TMathToken; static;
  end;
  TMathTokenArray = TArray<TMathToken>;

  TMathSettings = record
    DisplayMode: Boolean;
    ErrorColor: string;
    Macros: TDictionary<string, string>;
    MaxExpand: Integer;
    MaxSize: Double;
    MinRuleThickness: Double;
    ThrowOnError: Boolean;
    class function Default: TMathSettings; static;
  end;

  TMathArgType = (atDefault, atColor, atSize, atRaw, atOriginal, atHBox, atPrimitive, atMath, atText);

  TMathFunctionKind = (fkAboveFrac, fkAboveInfix, fkAccent, fkAccentUnder, fkBinRel, fkBoldSymbol, fkCdLabel, fkCdLabelParent, fkChar,
    fkColor, fkCr, fkDefinition, fkDelimSizing, fkEnclose, fkEnvironment, fkFont, fkFutureLet, fkGenFrac, fkGenFracGeneral, fkGlobal,
    fkHBox, fkHLine, fkHorizBrace, fkHtmlMathMl, fkInfix, fkKern, fkLap, fkLeft, fkLet, fkMathChoice, fkMathOp, fkMathShift, fkMClass,
    fkMiddle, fkMismatchedMath, fkOldFont, fkOperatorName, fkOpIntegral, fkOpLimits, fkOpNoLimits, fkOpSymbol, fkOverline, fkPhantom,
    fkPmb, fkRaiseBox, fkReflectBox, fkRelax, fkRight, fkRule, fkSizing, fkSmash, fkSqrt, fkStackRel, fkStyling, fkText, fkTextAccent,
    fkTextColor, fkUnderline, fkVCenter, fkVerb, fkVPhantom, fkXArrow);

  TMathFunctionSpec = record
    AllowedInArgument: Boolean;
    AllowedInMath: Boolean;
    AllowedInText: Boolean;
    ArgTypes: TArray<TMathArgType>;
    Infix: Boolean;
    Kind: TMathFunctionKind;
    NumArgs: Integer;
    NumOptionalArgs: Integer;
    Primitive: Boolean;
  end;

  TMathBuiltInMacro = (bmCDots, bmChar, bmChemistry, bmDots, bmDotsC, bmDotsO, bmFirstOfTwo, bmIfNextChar, bmNewCommand,
    bmPhysicalUnit, bmProvideCommand, bmRenewCommand, bmSecondOfTwo, bmTagLiteral, bmTextOrMath);

  TMathMacroKind = (mkString, mkTokens, mkBuiltIn);

  TMathMacro = record
    BuiltIn: TMathBuiltInMacro;
    Delimiters: TArray<TArray<string>>;
    Kind: TMathMacroKind;
    NumArgs: Integer;
    Text: string;
    Tokens: TMathTokenArray;
    Unexpandable: Boolean;
    class function FromText(const AText: string): TMathMacro; static;
  end;

  TMathLexer = class(TObject)
  strict private
    FCommentCatcode: Boolean;
    FInput: string;
    FPosition: Integer;
    function IsCombiningMark(const AIndex: Integer): Boolean;
    function SkipCombiningMarks(const AIndex: Integer): Integer;
    function TryLexVerb(const AStart: Integer; out AEnd: Integer): Boolean;
  public
    constructor Create(const AInput: string);
    function Lex: TMathToken;
  end;

  TMathNamespaceUndo = record
    Existed: Boolean;
    Macro: TMathMacro;
  end;

  TMathNamespace = class(TObject)
  strict private
    FCurrent: TDictionary<string, TMathMacro>;
    FUndoStack: TObjectList<TDictionary<string, TMathNamespaceUndo>>;
    procedure RecordUndo(const AName: string; const AExists: Boolean; const AMacro: TMathMacro; const AGlobal: Boolean);
  public
    constructor Create(const AMacros: TDictionary<string, string>);
    destructor Destroy; override;
    function Get(const AName: string; out AMacro: TMathMacro): Boolean;
    function Has(const AName: string): Boolean;
    procedure BeginGroup;
    procedure EndGroup;
    procedure EndGroups;
    procedure RemoveMacro(const AName: string; const AGlobal: Boolean = False);
    procedure SetMacro(const AName: string; const AMacro: TMathMacro; const AGlobal: Boolean = False);
  end;

  TMathMacroArgument = record
    EndToken: TMathToken;
    StartToken: TMathToken;
    Tokens: TMathTokenArray;
  end;

  TMathAutoTag = (atUndefined, atFalse, atTrue);

  TMathArrayParameters = record
    AddJot: Boolean;
    ArrayStretch: Double;
    AutoTag: TMathAutoTag;
    ColSeparationType: TMathColumnSeparation;
    Columns: TArray<TMathAlignSpec>;
    EmptySingleRow: Boolean;
    HSkipBeforeAndAfter: Boolean;
    MaxNumCols: Integer;
    SingleRow: Boolean;
  end;

  TMathMacroExpander = class(TObject)
  strict private
    FExpansionCount: Integer;
    FLexer: TMathLexer;
    FMacros: TMathNamespace;
    FMode: TMathMode;
    FSettings: TMathSettings;
    FStack: TList<TMathToken>;
    function ExpandBuiltIn(const AMacro: TMathMacro; out AExpansion: TMathMacro): Boolean;
    function GetExpansion(const AName: string; out AExpansion: TMathMacro): Boolean;
    function LexString(const AText: string): TMathTokenArray;
    function NewCommand(const AExistsOK: Boolean; const ANonExistsOK: Boolean; const ASkipIfExists: Boolean): string;
    procedure CountExpansion(const AAmount: Integer);
  public
    constructor Create(const AInput: string; const ASettings: TMathSettings);
    destructor Destroy; override;
    function ConsumeArg(const ADelimiters: array of string): TMathMacroArgument;
    function ConsumeArgs(const ANumArgs: Integer; const ADelimiters: TArray<TArray<string>> = nil): TArray<TMathTokenArray>;
    function ExpandAfterFuture: TMathToken;
    function ExpandMacroAsText(const AName: string; out AText: string): Boolean;
    function ExpandNextToken: TMathToken;
    function ExpandOnce(const AExpandableOnly: Boolean = False): Integer;
    function ExpandTokens(const ATokens: TMathTokenArray): TMathTokenArray;
    function Future: TMathToken;
    function IsDefined(const AName: string): Boolean;
    function IsExpandable(const AName: string): Boolean;
    function PopToken: TMathToken;
    function ScanArgument(const AIsOptional: Boolean; out AStartToken: TMathToken): Boolean;
    procedure BeginGroup;
    procedure ConsumeSpaces;
    procedure EndGroup;
    procedure EndGroups;
    procedure PushToken(const AToken: TMathToken);
    procedure PushTokens(const ATokens: TMathTokenArray);
    procedure SwitchMode(const AMode: TMathMode);
    property Macros: TMathNamespace read FMacros;
    property Mode: TMathMode read FMode;
  end;

  TMathParser = class(TObject)
  strict private
    FArena: TMathParseArena;
    FGullet: TMathMacroExpander;
    FHasNextToken: Boolean;
    FLeftRightDepth: Integer;
    FMode: TMathMode;
    FNestingDepth: Integer;
    FNextToken: TMathToken;
    FSettings: TMathSettings;
    function CallFunction(const AName: string; const AArgs: TArray<TMathParseNode>; const AOptionalArgs: TArray<TMathParseNode>;
      const AToken: TMathToken; const ABreakOnTokenText: string): TMathParseNode;
    function CheckControlSequence(const AToken: TMathToken): string;
    function Fetch: TMathToken;
    function FormatUnsupportedCommand(const AText: string): TMathParseNode;
    function HandleInfixNodes(const ABody: TMathNodeList): TMathNodeList;
    function HandleSupSubscript(const AName: string): TMathParseNode;
    function NewNode(const ANodeType: TMathNodeType): TMathParseNode;
    function OrdArgument(const ANode: TMathParseNode): TMathNodeList;
    function ParseArgumentGroup(const AOptional: Boolean; const AHasMode: Boolean; const AMode: TMathMode): TMathParseNode;
    function ParseAtom(const ABreakOnTokenText: string): TMathParseNode;
    function ParseCD: TMathParseNode;
    function ParseColorGroup(const AOptional: Boolean): TMathParseNode;
    function ParseExpression(const ABreakOnInfix: Boolean; const ABreakOnTokenText: string = ''): TMathNodeList;
    function ParseFunction(const ABreakOnTokenText: string; const AName: string): TMathParseNode;
    function ParseGroup(const AName: string; const ABreakOnTokenText: string = ''): TMathParseNode;
    function ParseGroupOfType(const AName: string; const AType: TMathArgType; const AOptional: Boolean): TMathParseNode;
    function ParseArray(const AParameters: TMathArrayParameters; const AStyle: TMathStyleName): TMathParseNode;
    function ParseDefinition(const AName: string): TMathParseNode;
    function ParseEnvironment(const AName: string; const AArgs: TArray<TMathParseNode>): TMathParseNode;
    function ParseEnvironmentCommand(const AName: string; const ANameGroup: TMathParseNode): TMathParseNode;
    function ParseHorizontalLines: TArray<Boolean>;
    function ParseSizeGroup(const AOptional: Boolean): TMathParseNode;
    function ParseSizeRegexGroup: string;
    function ParseStringGroup(const AOptional: Boolean; out AText: string): Boolean;
    function ParseSymbol: TMathParseNode;
    function ReadRightHandSide: TMathToken;
    function SubParse(const ATokens: TMathTokenArray): TMathNodeList;
    procedure Consume;
    procedure ConsumeSpaces;
    procedure EnterNesting;
    procedure Expect(const AText: string; const AConsume: Boolean = True);
    procedure FormLigatures(const AGroup: TMathNodeList);
    procedure LetCommand(const AName: string; const AToken: TMathToken; const AGlobal: Boolean);
    procedure ParseArguments(const AFunctionName: string; const ASpec: TMathFunctionSpec; out AArgs: TArray<TMathParseNode>;
      out AOptionalArgs: TArray<TMathParseNode>);
    procedure SwitchMode(const ANewMode: TMathMode);
  public
    constructor Create(const AInput: string; const ASettings: TMathSettings; const AArena: TMathParseArena);
    destructor Destroy; override;
    function Parse: TMathNodeList;
  end;

const
  EOF_TOKEN = 'EOF';

function FindFunction(const AName: string; out ASpec: TMathFunctionSpec): Boolean;
function ParseMathError(const AMessage: string; const APosition: Integer = -1): EMathParseError;

implementation

uses
  System.Character, System.Math, System.SyncObjs, System.SysUtils, MathRenderer.Chemistry, MathRenderer.Symbols;

type
  TMathParserDefinitions = class(TObject)
  strict private
    FBuiltInMacros: TDictionary<string, TMathMacro>;
    FFunctions: TDictionary<string, TMathFunctionSpec>;
    class var FInstance: TMathParserDefinitions;
    class destructor ReleaseInstance;
    procedure RegisterFunction(const ANames: array of string; const AKind: TMathFunctionKind; const ANumArgs: Integer;
      const AArgTypes: array of TMathArgType; const AAllowedInText: Boolean = False; const AAllowedInArgument: Boolean = False;
      const APrimitive: Boolean = False; const ANumOptionalArgs: Integer = 0; const AAllowedInMath: Boolean = True;
      const AInfix: Boolean = False);
    procedure RegisterFunctions;
    procedure RegisterMacro(const AName: string; const AText: string); overload;
    procedure RegisterMacro(const AName: string; const ABuiltIn: TMathBuiltInMacro); overload;
    procedure RegisterMacros;
  public
    constructor Create;
    destructor Destroy; override;
    class function Instance: TMathParserDefinitions;
    property BuiltInMacros: TDictionary<string, TMathMacro> read FBuiltInMacros;
    property Functions: TDictionary<string, TMathFunctionSpec> read FFunctions;
  end;

function ParseMathError(const AMessage: string; const APosition: Integer = -1): EMathParseError;
begin
  if APosition >= 0 then
    Result := EMathParseError.CreateFmt('%s at position %d', [AMessage, APosition + 1])
  else
    Result := EMathParseError.Create(AMessage);
end;

function FindFunction(const AName: string; out ASpec: TMathFunctionSpec): Boolean;
begin
  Result := TMathParserDefinitions.Instance.Functions.TryGetValue(AName, ASpec);
end;

function IsImplicitCommand(const AName: string): Boolean;
begin
  Result := (AName = '^') or (AName = '_') or (AName = '\limits') or (AName = '\nolimits');
end;

function IsLetter(const AChar: Char): Boolean; inline;
begin
  Result := CharInSet(AChar, ['a'..'z', 'A'..'Z']);
end;

function IsSpaceChar(const AChar: Char): Boolean; inline;
begin
  Result := CharInSet(AChar, [' ', #13, #10, #9]);
end;

function IsHexText(const AText: string): Boolean;
begin
  for var LIndex := 1 to AText.Length do
  if not CharInSet(AText[LIndex], ['0'..'9', 'a'..'f', 'A'..'F']) then
    Exit(False);

  Result := True;
end;

function IsHighSurrogateChar(const AChar: Char): Boolean; inline;
begin
  Result := (Ord(AChar) >= $D800) and (Ord(AChar) <= $DBFF);
end;

function IsLowSurrogateChar(const AChar: Char): Boolean; inline;
begin
  Result := (Ord(AChar) >= $DC00) and (Ord(AChar) <= $DFFF);
end;

{ TMathToken }

class function TMathToken.Create(const AText: string; const APosition: Integer = -1): TMathToken;
begin
  Result.Text := AText;
  Result.Position := APosition;
  Result.NoExpand := False;
  Result.TreatAsRelax := False;
end;

{ TMathSettings }

class function TMathSettings.Default: TMathSettings;
begin
  Result.DisplayMode := False;
  Result.ErrorColor := '#cc0000';
  Result.Macros := nil;
  Result.MaxExpand := 1000;
  Result.MaxSize := MaxDouble;
  Result.MinRuleThickness := 0;
  Result.ThrowOnError := False;
end;

{ TMathLexer }

constructor TMathLexer.Create(const AInput: string);
begin
  inherited Create;

  FInput := AInput;
  FPosition := 1;
  FCommentCatcode := True;
end;

function TMathLexer.IsCombiningMark(const AIndex: Integer): Boolean;
begin
  Result := (AIndex <= FInput.Length) and (Ord(FInput[AIndex]) >= $0300) and (Ord(FInput[AIndex]) <= $036F);
end;

function TMathLexer.SkipCombiningMarks(const AIndex: Integer): Integer;
begin
  Result := AIndex;

  while IsCombiningMark(Result) do
    Inc(Result);
end;

function TMathLexer.TryLexVerb(const AStart: Integer; out AEnd: Integer): Boolean;
begin
  Result := False;
  AEnd := 0;

  if Copy(FInput, AStart, 5) <> '\verb' then
    Exit;

  var LDelimiterIndex := AStart + 5;

  if LDelimiterIndex > FInput.Length then
    Exit;

  if FInput[LDelimiterIndex] = '*' then
    Inc(LDelimiterIndex)
  else
  if IsLetter(FInput[LDelimiterIndex]) then
    Exit;

  AEnd := LDelimiterIndex + 1;

  while AEnd <= FInput.Length do
  begin
    if FInput[AEnd] = FInput[LDelimiterIndex] then
      Exit(True);

    if CharInSet(FInput[AEnd], [#10, #13]) or (FInput[AEnd] = #$2028) or (FInput[AEnd] = #$2029) then
      Exit;

    Inc(AEnd);
  end;
end;

function TMathLexer.Lex: TMathToken;
begin
  var LStart := FPosition;

  if FPosition > FInput.Length then
    Exit(TMathToken.Create(EOF_TOKEN, LStart - 1));

  var LChar := FInput[FPosition];
  var LIndex := FPosition;
  var LText: string;
  var LVerbEnd: Integer;

  if IsSpaceChar(LChar) then
  begin
    while (LIndex <= FInput.Length) and IsSpaceChar(FInput[LIndex]) do
      Inc(LIndex);

    LText := ' ';
  end
  else
  if (LChar = '\') and TryLexVerb(LIndex, LVerbEnd) then
  begin
    LText := Copy(FInput, LStart, LVerbEnd - LStart + 1);
    LIndex := LVerbEnd + 1;
  end
  else
  if LChar = '\' then
  begin
    if (LIndex < FInput.Length) and IsSpaceChar(FInput[LIndex + 1]) then
    begin
      Inc(LIndex);

      if FInput[LIndex] = #10 then
        Inc(LIndex)
      else
      begin
        while (LIndex <= FInput.Length) and CharInSet(FInput[LIndex], [' ', #13, #9]) do
          Inc(LIndex);

        if (LIndex <= FInput.Length) and (FInput[LIndex] = #10) then
          Inc(LIndex);
      end;

      while (LIndex <= FInput.Length) and CharInSet(FInput[LIndex], [' ', #13, #9]) do
        Inc(LIndex);

      LText := '\ ';
    end
    else
    if (LIndex < FInput.Length) and (IsLetter(FInput[LIndex + 1]) or (FInput[LIndex + 1] = '@')) then
    begin
      Inc(LIndex);

      while (LIndex <= FInput.Length) and (IsLetter(FInput[LIndex]) or (FInput[LIndex] = '@')) do
        Inc(LIndex);

      LText := Copy(FInput, LStart, LIndex - LStart);

      while (LIndex <= FInput.Length) and IsSpaceChar(FInput[LIndex]) do
        Inc(LIndex);
    end
    else
    if (LIndex < FInput.Length) and not IsHighSurrogateChar(FInput[LIndex + 1]) and
      not IsLowSurrogateChar(FInput[LIndex + 1]) then
    begin
      LText := Copy(FInput, LStart, 2);
      Inc(LIndex, 2);
    end
    else
      raise ParseMathError(Format('Unexpected character: ''%s''', [LChar]), LStart - 1);
  end
  else
  begin
    var LCode := Ord(LChar);

    if IsHighSurrogateChar(LChar) and (LIndex < FInput.Length) and IsLowSurrogateChar(FInput[LIndex + 1]) then
      LIndex := SkipCombiningMarks(LIndex + 2)
    else
    if ((LCode >= $21) and (LCode <= $5B)) or ((LCode >= $5D) and (LCode <= $2027)) or ((LCode >= $202A) and (LCode <= $D7FF)) or (LCode >= $F900) then
      LIndex := SkipCombiningMarks(LIndex + 1)
    else
      raise ParseMathError(Format('Unexpected character: ''%s''', [LChar]), LStart - 1);

    LText := Copy(FInput, LStart, LIndex - LStart);
  end;

  FPosition := LIndex;

  if FCommentCatcode and (LText = '%') then
  begin
    LIndex := Pos(#10, FInput, FPosition);

    FPosition := if LIndex = 0 then FInput.Length + 1 else LIndex + 1;

    Exit(Lex);
  end;

  Result := TMathToken.Create(LText, LStart - 1);
end;

{ TMathNamespace }

constructor TMathNamespace.Create(const AMacros: TDictionary<string, string>);
var
  LMacro: TMathMacro;
begin
  inherited Create;

  FCurrent := TDictionary<string, TMathMacro>.Create;
  FUndoStack := TObjectList<TDictionary<string, TMathNamespaceUndo>>.Create(True);

  if Assigned(AMacros) then
  for var LPair in AMacros do
  begin
    LMacro := Default(TMathMacro);
    LMacro.Kind := mkString;
    LMacro.Text := LPair.Value;

    FCurrent.AddOrSetValue(LPair.Key, LMacro);
  end;
end;

destructor TMathNamespace.Destroy;
begin
  FUndoStack.Free;
  FCurrent.Free;

  inherited Destroy;
end;

procedure TMathNamespace.BeginGroup;
begin
  FUndoStack.Add(TDictionary<string, TMathNamespaceUndo>.Create);
end;

procedure TMathNamespace.EndGroup;
begin
  if FUndoStack.Count = 0 then
    raise ParseMathError('Unbalanced namespace destruction: attempt to pop global namespace');

  var LUndo := FUndoStack.Extract(FUndoStack.Last);
  try
    for var LPair in LUndo do
    if LPair.Value.Existed then
      FCurrent.AddOrSetValue(LPair.Key, LPair.Value.Macro)
    else
      FCurrent.Remove(LPair.Key);
  finally
    LUndo.Free;
  end;
end;

procedure TMathNamespace.EndGroups;
begin
  while FUndoStack.Count > 0 do
    EndGroup;
end;

function TMathNamespace.Get(const AName: string; out AMacro: TMathMacro): Boolean;
begin
  Result := FCurrent.TryGetValue(AName, AMacro) or TMathParserDefinitions.Instance.BuiltInMacros.TryGetValue(AName, AMacro);
end;

function TMathNamespace.Has(const AName: string): Boolean;
begin
  Result := FCurrent.ContainsKey(AName) or TMathParserDefinitions.Instance.BuiltInMacros.ContainsKey(AName);
end;

procedure TMathNamespace.RecordUndo(const AName: string; const AExists: Boolean; const AMacro: TMathMacro; const AGlobal: Boolean);
var
  LUndo: TMathNamespaceUndo;
begin
  if AGlobal then
  begin
    for var LIndex := 0 to FUndoStack.Count - 1 do
      FUndoStack[LIndex].Remove(AName);

    if FUndoStack.Count > 0 then
    begin
      LUndo.Existed := AExists;
      LUndo.Macro := AMacro;

      FUndoStack.Last.AddOrSetValue(AName, LUndo);
    end;
  end
  else
  if FUndoStack.Count > 0 then
  begin
    var LTop := FUndoStack.Last;

    if not LTop.ContainsKey(AName) then
    begin
      LUndo.Existed := FCurrent.TryGetValue(AName, LUndo.Macro);

      LTop.Add(AName, LUndo);
    end;
  end;
end;

procedure TMathNamespace.RemoveMacro(const AName: string; const AGlobal: Boolean = False);
begin
  RecordUndo(AName, False, Default(TMathMacro), AGlobal);

  FCurrent.Remove(AName);
end;

procedure TMathNamespace.SetMacro(const AName: string; const AMacro: TMathMacro; const AGlobal: Boolean = False);
begin
  RecordUndo(AName, True, AMacro, AGlobal);
  FCurrent.AddOrSetValue(AName, AMacro);
end;

{ TMathMacroExpander }

constructor TMathMacroExpander.Create(const AInput: string; const ASettings: TMathSettings);
begin
  inherited Create;

  FSettings := ASettings;
  FExpansionCount := 0;
  FLexer := TMathLexer.Create(AInput);
  FMacros := TMathNamespace.Create(ASettings.Macros);
  FMode := mmMath;
  FStack := TList<TMathToken>.Create;
end;

destructor TMathMacroExpander.Destroy;
begin
  FStack.Free;
  FMacros.Free;
  FLexer.Free;

  inherited Destroy;
end;

procedure TMathMacroExpander.SwitchMode(const AMode: TMathMode);
begin
  FMode := AMode;
end;

procedure TMathMacroExpander.BeginGroup;
begin
  FMacros.BeginGroup;
end;

procedure TMathMacroExpander.EndGroup;
begin
  FMacros.EndGroup;
end;

procedure TMathMacroExpander.EndGroups;
begin
  FMacros.EndGroups;
end;

function TMathMacroExpander.Future: TMathToken;
begin
  if FStack.Count = 0 then
    PushToken(FLexer.Lex);

  Result := FStack.Last;
end;

function TMathMacroExpander.PopToken: TMathToken;
begin
  Future;

  Result := FStack.Last;

  FStack.Delete(FStack.Count - 1);
end;

procedure TMathMacroExpander.PushToken(const AToken: TMathToken);
begin
  FStack.Add(AToken);
end;

procedure TMathMacroExpander.PushTokens(const ATokens: TMathTokenArray);
begin
  FStack.AddRange(ATokens);
end;

function TMathMacroExpander.ScanArgument(const AIsOptional: Boolean; out AStartToken: TMathToken): Boolean;
var
  LArgument: TMathMacroArgument;
begin
  if AIsOptional then
  begin
    ConsumeSpaces;

    if Future.Text <> '[' then
      Exit(False);

    AStartToken := PopToken;
    LArgument := ConsumeArg([']']);
  end
  else
  begin
    LArgument := ConsumeArg([]);
    AStartToken := LArgument.StartToken;
  end;

  PushToken(TMathToken.Create(EOF_TOKEN, LArgument.EndToken.Position));
  PushTokens(LArgument.Tokens);

  Result := True;
end;

procedure TMathMacroExpander.ConsumeSpaces;
begin
  while Future.Text = ' ' do
    FStack.Delete(FStack.Count - 1);
end;

function TMathMacroExpander.ConsumeArg(const ADelimiters: array of string): TMathMacroArgument;
var
  LToken: TMathToken;
  LExpected: string;
begin
  var LIsDelimited := Length(ADelimiters) > 0;

  if not LIsDelimited then
    ConsumeSpaces;

  Result.StartToken := Future;

  var LDepth := 0;
  var LMatch := 0;
  var LTokens := TList<TMathToken>.Create;
  try
    repeat
      LToken := PopToken;
      LTokens.Add(LToken);

      if LToken.Text = '{' then
        Inc(LDepth)
      else
      if LToken.Text = '}' then
      begin
        Dec(LDepth);

        if LDepth = -1 then
          raise ParseMathError('Extra }', LToken.Position);
      end
      else
      if LToken.Text = EOF_TOKEN then
      begin
        LExpected := if LIsDelimited then ADelimiters[LMatch] else '}';

        raise ParseMathError(Format('Unexpected end of input in a macro argument, expected ''%s''', [LExpected]),
          LToken.Position);
      end;

      if LIsDelimited then
      begin
        if ((LDepth = 0) or ((LDepth = 1) and (ADelimiters[LMatch] = '{'))) and (LToken.Text = ADelimiters[LMatch]) then
        begin
          Inc(LMatch);

          if LMatch = Length(ADelimiters) then
          begin
            LTokens.DeleteRange(LTokens.Count - LMatch, LMatch);

            Break;
          end;
        end
        else
          LMatch := 0;
      end;
    until (LDepth = 0) and not LIsDelimited;

    if (Result.StartToken.Text = '{') and (LTokens.Count > 0) and (LTokens.Last.Text = '}') then
    begin
      LTokens.Delete(LTokens.Count - 1);
      LTokens.Delete(0);
    end;

    LTokens.Reverse;
    Result.Tokens := LTokens.ToArray;
    Result.EndToken := LToken;
  finally
    LTokens.Free;
  end;
end;

function TMathMacroExpander.ConsumeArgs(const ANumArgs: Integer; const ADelimiters: TArray<TArray<string>> = nil): TArray<TMathTokenArray>;
var
  LToken: TMathToken;
begin
  if Assigned(ADelimiters) then
  begin
    if Length(ADelimiters) <> ANumArgs + 1 then
      raise ParseMathError('The length of delimiters doesn''t match the number of args!');

    for var LIndex := 0 to High(ADelimiters[0]) do
    begin
      LToken := PopToken;

      if LToken.Text <> ADelimiters[0][LIndex] then
        raise ParseMathError('Use of the macro doesn''t match its definition', LToken.Position);
    end;
  end;

  SetLength(Result, ANumArgs);

  for var LIndex := 0 to ANumArgs - 1 do
  if Assigned(ADelimiters) then
    Result[LIndex] := ConsumeArg(ADelimiters[LIndex + 1]).Tokens
  else
    Result[LIndex] := ConsumeArg([]).Tokens;
end;

procedure TMathMacroExpander.CountExpansion(const AAmount: Integer);
begin
  Inc(FExpansionCount, AAmount);

  if FExpansionCount > FSettings.MaxExpand then
    raise ParseMathError('Too many expansions: infinite loop or need to increase maxExpand setting');
end;

function TMathMacroExpander.ExpandOnce(const AExpandableOnly: Boolean = False): Integer;
var
  LMacro: TMathMacro;
  LToken: TMathToken;
begin
  var LTopToken := PopToken;
  var LFound := not LTopToken.NoExpand and GetExpansion(LTopToken.Text, LMacro);

  if not LFound or (AExpandableOnly and LMacro.Unexpandable) then
  begin
    if AExpandableOnly and not LFound and LTopToken.Text.StartsWith('\') and not IsDefined(LTopToken.Text) then
      raise ParseMathError('Undefined control sequence: ' + LTopToken.Text, LTopToken.Position);

    PushToken(LTopToken);

    Exit(-1);
  end;

  CountExpansion(1);

  var LExpansion := LMacro.Tokens;
  var LNumArgs := LMacro.NumArgs;
  var LArgs := ConsumeArgs(LNumArgs, LMacro.Delimiters);

  if LNumArgs > 0 then
  begin
    var LTokens := TList<TMathToken>.Create;
    try
      LTokens.AddRange(LExpansion);

      var LIndex := LTokens.Count - 1;

      while LIndex >= 0 do
      begin
        LToken := LTokens[LIndex];

        if LToken.Text = '#' then
        begin
          if LIndex = 0 then
            raise ParseMathError('Incomplete placeholder at end of macro body', LToken.Position);

          Dec(LIndex);
          LToken := LTokens[LIndex];

          if LToken.Text = '#' then
            LTokens.Delete(LIndex + 1)
          else
          if (LToken.Text.Length = 1) and CharInSet(LToken.Text[1], ['1'..'9']) then
          begin
            var LArgumentNumber := Ord(LToken.Text[1]) - Ord('0');

            if LArgumentNumber > LNumArgs then
              raise ParseMathError('Not a valid argument number', LToken.Position);

            LTokens.DeleteRange(LIndex, 2);
            LTokens.InsertRange(LIndex, LArgs[LArgumentNumber - 1]);
          end
          else
            raise ParseMathError('Not a valid argument number', LToken.Position);
        end;

        Dec(LIndex);
      end;

      LExpansion := LTokens.ToArray;
    finally
      LTokens.Free;
    end;
  end;

  PushTokens(LExpansion);

  Result := Length(LExpansion);
end;

function TMathMacroExpander.ExpandAfterFuture: TMathToken;
begin
  ExpandOnce;

  Result := Future;
end;

function TMathMacroExpander.ExpandNextToken: TMathToken;
begin
  while True do
  if ExpandOnce < 0 then
  begin
    Result := FStack.Last;
    FStack.Delete(FStack.Count - 1);

    if Result.TreatAsRelax then
      Result.Text := '\relax';

    Exit;
  end;
end;

function TMathMacroExpander.ExpandTokens(const ATokens: TMathTokenArray): TMathTokenArray;
var
  LToken: TMathToken;
begin
  var LOutput := TList<TMathToken>.Create;
  try
    var LOldStackLength := FStack.Count;

    PushTokens(ATokens);

    while FStack.Count > LOldStackLength do
    if ExpandOnce(True) < 0 then
    begin
      LToken := FStack.Last;

      FStack.Delete(FStack.Count - 1);

      if LToken.TreatAsRelax then
      begin
        LToken.NoExpand := False;
        LToken.TreatAsRelax := False;
      end;

      LOutput.Add(LToken);
    end;

    CountExpansion(LOutput.Count);

    Result := LOutput.ToArray;
  finally
    LOutput.Free;
  end;
end;

function TMathMacroExpander.ExpandMacroAsText(const AName: string; out AText: string): Boolean;
begin
  AText := '';

  if not FMacros.Has(AName) then
    Exit(False);

  var LTokens := ExpandTokens([TMathToken.Create(AName)]);

  for var LIndex := 0 to High(LTokens) do
    AText := AText + LTokens[LIndex].Text;

  Result := True;
end;

function TMathMacroExpander.IsExpandable(const AName: string): Boolean;
var
  LMacro: TMathMacro;
  LSpec: TMathFunctionSpec;
begin
  if FMacros.Get(AName, LMacro) then
    Exit((LMacro.Kind <> mkTokens) or not LMacro.Unexpandable);

  Result := FindFunction(AName, LSpec) and not LSpec.Primitive;
end;

function TMathMacroExpander.LexString(const AText: string): TMathTokenArray;
begin
  var LLexer := TMathLexer.Create(AText);
  var LTokens := TList<TMathToken>.Create;
  try
    var LToken := LLexer.Lex;

    while LToken.Text <> EOF_TOKEN do
    begin
      LTokens.Add(LToken);
      LToken := LLexer.Lex;
    end;

    LTokens.Reverse;

    Result := LTokens.ToArray;
  finally
    LTokens.Free;
    LLexer.Free;
  end;
end;

function TMathMacroExpander.NewCommand(const AExistsOK: Boolean; const ANonExistsOK: Boolean; const ASkipIfExists: Boolean): string;
begin
  var LArgument := ConsumeArg([]).Tokens;

  if Length(LArgument) <> 1 then
    raise ParseMathError('\newcommand''s first argument must be a macro name');

  var LName := LArgument[0].Text;
  var LExists := IsDefined(LName);

  if LExists and not AExistsOK then
    raise ParseMathError(Format('\newcommand{%s} attempting to redefine %s; use \renewcommand', [LName, LName]));

  if not LExists and not ANonExistsOK then
    raise ParseMathError(Format('\renewcommand{%s} when command %s does not yet exist; use \newcommand', [LName, LName]));

  var LNumArgs := 0;

  LArgument := ConsumeArg([]).Tokens;

  if (Length(LArgument) = 1) and (LArgument[0].Text = '[') then
  begin
    var LArgumentText := '';
    var LToken := ExpandNextToken;

    while (LToken.Text <> ']') and (LToken.Text <> EOF_TOKEN) do
    begin
      LArgumentText := LArgumentText + LToken.Text;
      LToken := ExpandNextToken;
    end;

    if not TryStrToInt(LArgumentText.Trim, LNumArgs) then
      raise ParseMathError('Invalid number of arguments: ' + LArgumentText);

    LArgument := ConsumeArg([]).Tokens;
  end;

  if not (LExists and ASkipIfExists) then
  begin
    var LMacro := Default(TMathMacro);

    LMacro.Kind := mkTokens;
    LMacro.Tokens := LArgument;
    LMacro.NumArgs := LNumArgs;
    FMacros.SetMacro(LName, LMacro);
  end;

  Result := '';
end;

function TMathMacroExpander.ExpandBuiltIn(const AMacro: TMathMacro; out AExpansion: TMathMacro): Boolean;
const
  SPACE_AFTER_DOTS: array [0..18] of string = (')', ']', '\rbrack', '\}', '\rbrace', '\rangle', '\rceil', '\rfloor',
    '\rgroup', '\rmoustache', '\right', '\bigr', '\biggr', '\Bigr', '\Biggr', '$', ';', '.', ',');
  DOTSB_TOKENS: array [0..37] of string = ('\not', '+', '=', '<', '>', '-', '*', ':', '\DOTSB', '\coprod', '\bigvee',
    '\bigwedge', '\biguplus', '\bigcap', '\bigcup', '\prod', '\sum', '\bigotimes', '\bigoplus', '\bigodot', '\bigsqcup',
    '\And', '\longrightarrow', '\Longrightarrow', '\longleftarrow', '\Longleftarrow', '\longleftrightarrow',
    '\Longleftrightarrow', '\mapsto', '\longmapsto', '\hookrightarrow', '\doteq', '\mathbin', '\mathrel', '\relbar',
    '\Relbar', '\xrightarrow', '\xleftarrow');
  DOTSI_TOKENS: array [0..6] of string = ('\int', '\oint', '\iint', '\iiint', '\iiiint', '\idotsint', '\DOTSI');

  function IsInList(const AText: string; const AList: array of string): Boolean;
  begin
    for var LIndex := Low(AList) to High(AList) do
    if AList[LIndex] = AText then
      Exit(True);

    Result := False;
  end;

  function Expand(const AText: string): Boolean;
  begin
    AExpansion := TMathMacro.FromText(AText);

    Result := True;
  end;

  function ExpandTokens(const ATokenArray: TMathTokenArray): Boolean;
  begin
    AExpansion := Default(TMathMacro);
    AExpansion.Kind := mkTokens;
    AExpansion.Tokens := ATokenArray;

    Result := True;
  end;

  function TagLiteral: string;
  var
    LMacro: TMathMacro;
  begin
    if FMacros.Get('\df@tag', LMacro) then
      raise ParseMathError('Multiple \tag');

    Result := '\gdef\df@tag{\text{#1}}';
  end;

  function ParseCharNumber: string;
  const
    DIGITS = '0123456789abcdef';
  var
    LNumber: Int64;
  begin
    var LToken := PopToken;
    var LBase := 10;

    if LToken.Text = '''' then
    begin
      LBase := 8;
      LToken := PopToken;
    end
    else
    if LToken.Text = '"' then
    begin
      LBase := 16;
      LToken := PopToken;
    end
    else
    if LToken.Text = '`' then
    begin
      LToken := PopToken;

      if LToken.Text.StartsWith('\') then
        LNumber := Ord(LToken.Text[2])
      else
      if LToken.Text = EOF_TOKEN then
        raise ParseMathError('\char` missing argument')
      else
        LNumber := Ord(LToken.Text[1]);

      Exit(Format('\@char{%d}', [LNumber]));
    end;

    var LDigit := if LToken.Text.Length = 1 then Pos(LowerCase(LToken.Text), DIGITS) - 1 else -1;

    if (LDigit < 0) or (LDigit >= LBase) then
      raise ParseMathError(Format('Invalid base-%d digit %s', [LBase, LToken.Text]));

    LNumber := LDigit;

    while True do
    begin
      LToken := Future;
      LDigit := if LToken.Text.Length = 1 then Pos(LowerCase(LToken.Text), DIGITS) - 1 else -1;

      if (LDigit < 0) or (LDigit >= LBase) then
        Break;

      LNumber := LNumber * LBase + LDigit;
      PopToken;
    end;

    Result := Format('\@char{%d}', [LNumber]);
  end;

  function ArgumentText(const ATokens: TMathTokenArray): string;
  begin
    Result := '';

    if Length(ATokens) = 0 then
      Exit;

    var LExpectedPosition := ATokens[High(ATokens)].Position;

    for var LIndex := High(ATokens) downto 0 do
    begin
      if (ATokens[LIndex].Position >= 0) and (ATokens[LIndex].Position > LExpectedPosition) then
        Result := Result + ' ';

      Result := Result + ATokens[LIndex].Text;
      LExpectedPosition := ATokens[LIndex].Position + ATokens[LIndex].Text.Length;
    end;
  end;

var
  LArgs: TArray<TMathTokenArray>;
  LNext: string;
  LDots: string;
  LSymbol: PMathSymbolDefinition;
begin
  case AMacro.BuiltIn of
    bmFirstOfTwo:
      begin
        LArgs := ConsumeArgs(2);

        Result := ExpandTokens(LArgs[0]);
      end;
    bmSecondOfTwo:
      begin
        LArgs := ConsumeArgs(2);

        Result := ExpandTokens(LArgs[1]);
      end;
    bmIfNextChar:
      begin
        LArgs := ConsumeArgs(3);
        ConsumeSpaces;

        if (Length(LArgs[0]) = 1) and (LArgs[0][0].Text = Future.Text) then
          Result := ExpandTokens(LArgs[1])
        else
          Result := ExpandTokens(LArgs[2]);
      end;
    bmTextOrMath:
      begin
        LArgs := ConsumeArgs(2);

        if FMode = mmText then
          Result := ExpandTokens(LArgs[0])
        else
          Result := ExpandTokens(LArgs[1]);
      end;
    bmChar:
      Result := Expand(ParseCharNumber);
    bmChemistry:
      Result := Expand('{' + ChemistryToTeX(ArgumentText(ConsumeArgs(1)[0])) + '}');
    bmPhysicalUnit:
      Result := Expand('{' + PhysicalUnitToTeX(ArgumentText(ConsumeArgs(1)[0])) + '}');
    bmNewCommand:
      Result := Expand(NewCommand(False, True, False));
    bmRenewCommand:
      Result := Expand(NewCommand(True, False, False));
    bmProvideCommand:
      Result := Expand(NewCommand(True, True, True));
    bmDots:
      begin
        LDots := '\dotso';
        LNext := ExpandAfterFuture.Text;

        if IsInList(LNext, DOTSI_TOKENS) then
          LDots := '\dotsi'
        else
        if LNext = ',' then
          LDots := '\dotsc'
        else
        if LNext = '\DOTSX' then
          LDots := '\dotsx'
        else
        if IsInList(LNext, DOTSB_TOKENS) or LNext.StartsWith('\not') then
          LDots := '\dotsb'
        else
        if FindSymbol(mmMath, LNext, LSymbol) and (LSymbol.Group in [sgBin, sgRel]) then
          LDots := '\dotsb';

        Result := Expand(LDots);
      end;
    bmDotsO:
      Result := Expand(if IsInList(Future.Text, SPACE_AFTER_DOTS) then '\ldots\,' else '\ldots');
    bmDotsC:
      begin
        LNext := Future.Text;

        Result := Expand(if IsInList(LNext, SPACE_AFTER_DOTS) and (LNext <> ',') then '\ldots\,' else '\ldots');
      end;
    bmCDots:
      Result := Expand(if IsInList(Future.Text, SPACE_AFTER_DOTS) then '\@cdots\,' else '\@cdots');
    bmTagLiteral:
      Result := Expand(TagLiteral);
  else
    Result := False;
  end;
end;

function TMathMacroExpander.GetExpansion(const AName: string; out AExpansion: TMathMacro): Boolean;
var
  LMacro: TMathMacro;
  LBuiltInExpansion: TMathMacro;
begin
  AExpansion := Default(TMathMacro);

  if not FMacros.Get(AName, LMacro) then
    Exit(False);

  if AName = '%' then
    Exit(False);

  if LMacro.Kind = mkBuiltIn then
  begin
    if not ExpandBuiltIn(LMacro, LBuiltInExpansion) then
      Exit(False);

    LMacro := LBuiltInExpansion;
  end;

  if LMacro.Kind = mkString then
  begin
    AExpansion.Kind := mkTokens;

    if LMacro.Text.Contains('#') then
    begin
      var LStripped := LMacro.Text.Replace('##', '');

      while LStripped.Contains('#' + IntToStr(AExpansion.NumArgs + 1)) do
        Inc(AExpansion.NumArgs);
    end;

    AExpansion.Tokens := LexString(LMacro.Text);
  end
  else
    AExpansion := LMacro;

  Result := True;
end;

class function TMathMacro.FromText(const AText: string): TMathMacro;
begin
  Result := Default(TMathMacro);
  Result.Kind := mkString;
  Result.Text := AText;
end;

function TMathMacroExpander.IsDefined(const AName: string): Boolean;
var
  LSpec: TMathFunctionSpec;
begin
  Result := FMacros.Has(AName) or FindFunction(AName, LSpec) or IsSymbolDefined(AName) or IsImplicitCommand(AName);
end;

{ TMathParser }

constructor TMathParser.Create(const AInput: string; const ASettings: TMathSettings; const AArena: TMathParseArena);
begin
  inherited Create;

  FMode := mmMath;
  FSettings := ASettings;
  FArena := AArena;
  FGullet := TMathMacroExpander.Create(AInput, ASettings);
  FLeftRightDepth := 0;
  FHasNextToken := False;
end;

procedure TMathParser.EnterNesting;
const
  MAX_NESTING_DEPTH = 200;
begin
  Inc(FNestingDepth);

  if FNestingDepth > MAX_NESTING_DEPTH then
    raise ParseMathError('Formula is nested too deeply');
end;

destructor TMathParser.Destroy;
begin
  FGullet.Free;

  inherited Destroy;
end;

function TMathParser.NewNode(const ANodeType: TMathNodeType): TMathParseNode;
begin
  Result := FArena.NewNode(ANodeType, FMode);
end;

function TMathParser.OrdArgument(const ANode: TMathParseNode): TMathNodeList;
begin
  if ANode.NodeType = ntOrdGroup then
    Result := ANode.Body
  else
    Result := FArena.NewList([ANode]);
end;

procedure TMathParser.Expect(const AText: string; const AConsume: Boolean = True);
begin
  var LToken := Fetch;

  if LToken.Text <> AText then
    raise ParseMathError(Format('Expected ''%s'', got ''%s''', [AText, LToken.Text]), LToken.Position);

  if AConsume then
    Consume;
end;

procedure TMathParser.Consume;
begin
  FHasNextToken := False;
end;

function TMathParser.Fetch: TMathToken;
begin
  if not FHasNextToken then
  begin
    FNextToken := FGullet.ExpandNextToken;
    FHasNextToken := True;
  end;

  Result := FNextToken;
end;

procedure TMathParser.SwitchMode(const ANewMode: TMathMode);
begin
  FMode := ANewMode;
  FGullet.SwitchMode(ANewMode);
end;

function TMathParser.Parse: TMathNodeList;
var
  LMacro: TMathMacro;
begin
  FGullet.BeginGroup;
  try
    Result := ParseExpression(False);
    Expect(EOF_TOKEN);
    FGullet.EndGroup;
  finally
    FGullet.EndGroups;
  end;

  if FGullet.Macros.Get('\df@tag', LMacro) then
  begin
    if not FSettings.DisplayMode then
      raise ParseMathError('\tag works only in display equations');

    var LTag := FArena.NewNode(ntTag, mmText);

    LTag.Body := Result;
    LTag.TagBody := SubParse([TMathToken.Create('\df@tag')]);

    Result := FArena.NewList([LTag]);
  end;
end;

function TMathParser.SubParse(const ATokens: TMathTokenArray): TMathNodeList;
begin
  var LOldToken := FNextToken;
  var LOldHasToken := FHasNextToken;

  Consume;

  FGullet.PushToken(TMathToken.Create('}'));
  FGullet.PushTokens(ATokens);
  Result := ParseExpression(False);
  Expect('}');

  FNextToken := LOldToken;
  FHasNextToken := LOldHasToken;
end;

function TMathParser.ParseHorizontalLines: TArray<Boolean>;
begin
  Result := nil;

  ConsumeSpaces;

  var LNext := Fetch.Text;

  if LNext = '\relax' then
  begin
    Consume;
    ConsumeSpaces;
    LNext := Fetch.Text;
  end;

  while (LNext = '\hline') or (LNext = '\hdashline') do
  begin
    Consume;
    Result := Result + [LNext = '\hdashline'];
    ConsumeSpaces;
    LNext := Fetch.Text;
  end;
end;

function TMathParser.ParseArray(const AParameters: TMathArrayParameters; const AStyle: TMathStyleName): TMathParseNode;
var
  LHorizontalLines: TArray<TArray<Boolean>>;
  LTags: TArray<TMathRowTag>;
  LMacro: TMathMacro;

  procedure BeginRow;
  begin
    if AParameters.AutoTag = atTrue then
      FGullet.Macros.SetMacro('\@eqnsw', TMathMacro.FromText('1'), True);
  end;

  procedure EndRow;
  var
    LTag: TMathRowTag;
    LSwitch: TMathMacro;
  begin
    if AParameters.AutoTag = atUndefined then
      Exit;

    LTag := Default(TMathRowTag);

    if FGullet.Macros.Get('\df@tag', LMacro) then
    begin
      LTag.Kind := tkManual;
      LTag.Body := SubParse([TMathToken.Create('\df@tag')]);
      FGullet.Macros.RemoveMacro('\df@tag', True);
    end
    else
    if (AParameters.AutoTag = atTrue) and FGullet.Macros.Get('\@eqnsw', LSwitch) and (LSwitch.Text = '1') then
      LTag.Kind := tkAutomatic;

    LTags := LTags + [LTag];
  end;

begin
  EnterNesting;
  FGullet.BeginGroup;

  if not AParameters.SingleRow then
    FGullet.Macros.SetMacro('\cr', TMathMacro.FromText('\\\relax'));

  var LArrayStretch: Double := AParameters.ArrayStretch;
  var LStretchText: string;

  if LArrayStretch = 0 then
  begin
    if FGullet.ExpandMacroAsText('\arraystretch', LStretchText) then
    begin
      LArrayStretch := StrToFloatDef(LStretchText.Trim, 0, TFormatSettings.Invariant);

      if LArrayStretch <= 0 then
        raise ParseMathError('Invalid \arraystretch: ' + LStretchText);
    end
    else
      LArrayStretch := 1;
  end;

  FGullet.BeginGroup;

  var LRow := FArena.NewList;
  var LRows := FArena.NewRows;

  LRows.Add(LRow);

  var LRowGaps: TArray<TMathRowGap> := nil;
  var LCellBody: TMathNodeList;
  var LCell: TMathParseNode;
  var LStyling: TMathParseNode;
  var LNext: string;
  var LRowGap: TMathRowGap;
  var LSize: TMathParseNode;
  var LLastTag: TMathRowTag;

  LTags := nil;
  BeginRow;
  LHorizontalLines := [ParseHorizontalLines];

  while True do
  begin
    LCellBody := ParseExpression(False, if AParameters.SingleRow then '\end' else '\\');
    FGullet.EndGroup;
    FGullet.BeginGroup;
    LCell := NewNode(ntOrdGroup);
    LCell.Body := LCellBody;

    if AStyle <> snNone then
    begin
      LStyling := NewNode(ntStyling);
      LStyling.Style := AStyle;
      LStyling.ResetFont := True;
      LStyling.Body := FArena.NewList([LCell]);
      LCell := LStyling;
    end;

    LRow.Add(LCell);

    LNext := Fetch.Text;

    if LNext = '&' then
    begin
      if (AParameters.MaxNumCols > 0) and (LRow.Count = AParameters.MaxNumCols) and
        (AParameters.SingleRow or (AParameters.ColSeparationType <> csDefault)) then
        raise ParseMathError('Too many tab characters: &', Fetch.Position);

      Consume;
    end
    else
    if LNext = '\end' then
    begin
      EndRow;
      LLastTag := if Length(LTags) > 0 then LTags[High(LTags)] else Default(TMathRowTag);

      if (LRow.Count = 1) and (LCell.NodeType = ntStyling) and (LCell.Body.Count = 1) and
        (LCell.Body[0].NodeType = ntOrdGroup) and (LCell.Body[0].Body.Count = 0) and
        ((LRows.Count > 1) or not AParameters.EmptySingleRow) and (LLastTag.Kind <> tkManual) and
        not ((AParameters.AutoTag = atTrue) and (LLastTag.Kind = tkAutomatic)) then
        LRows.Delete(LRows.Count - 1);

      if Length(LHorizontalLines) < LRows.Count + 1 then
        LHorizontalLines := LHorizontalLines + [nil];

      Break;
    end
    else
    if LNext = '\\' then
    begin
      Consume;
      LRowGap := Default(TMathRowGap);

      if FGullet.Future.Text <> ' ' then
      begin
        LSize := ParseSizeGroup(True);

        if Assigned(LSize) then
        begin
          LRowGap.HasSize := True;
          LRowGap.Size := LSize.Value;
        end;
      end;

      LRowGaps := LRowGaps + [LRowGap];
      EndRow;
      LHorizontalLines := LHorizontalLines + [ParseHorizontalLines];
      LRow := FArena.NewList;
      LRows.Add(LRow);
      BeginRow;
    end
    else
      raise ParseMathError('Expected & or \\ or \cr or \end', Fetch.Position);
  end;

  FGullet.EndGroup;
  FGullet.EndGroup;

  Result := NewNode(ntArray);
  Result.AddJot := AParameters.AddJot;
  Result.ArrayStretch := LArrayStretch;
  Result.Rows := LRows;
  Result.Columns := AParameters.Columns;
  Result.RowGaps := LRowGaps;
  Result.HSkipBeforeAndAfter := AParameters.HSkipBeforeAndAfter;
  Result.HLinesBeforeRow := LHorizontalLines;
  Result.ColSeparationType := AParameters.ColSeparationType;
  Result.HasTags := AParameters.AutoTag <> atUndefined;
  Result.RowTags := LTags;

  Dec(FNestingDepth);
end;

function TMathParser.ParseEnvironment(const AName: string; const AArgs: TArray<TMathParseNode>): TMathParseNode;

  function CellStyle: TMathStyleName;
  begin
    Result := if AName.StartsWith('d') then snDisplay else snText;
  end;

  function TryColumnAlign(const AText: string; out AAlign: TMathColumnAlign): Boolean;
  begin
    for var LAlignment := Low(TMathColumnAlign) to High(TMathColumnAlign) do
    if COLUMN_ALIGN_LETTERS[LAlignment] = AText then
    begin
      AAlign := LAlignment;

      Exit(True);
    end;

    Result := False;
  end;

  procedure ValidateDisplayMode;
  begin
    if not FSettings.DisplayMode then
      raise ParseMathError(Format('{%s} can be used only in display mode.', [AName]));
  end;

  function AutoTag: TMathAutoTag;
  begin
    if AName.Contains('ed') then
      Result := atUndefined
    else
    if AName.Contains('*') then
      Result := atFalse
    else
      Result := atTrue;
  end;

  function ColumnSymbols(const AArgument: TMathParseNode): TMathNodeList;
  begin
    if IsSymbolNode(AArgument) then
      Result := FArena.NewList([AArgument])
    else
    if AArgument.NodeType = ntOrdGroup then
      Result := AArgument.Body
    else
      raise ParseMathError('Invalid column alignment');
  end;

  function WrapInDelimiters(const AArray: TMathParseNode; const ALeft: string; const ARight: string): TMathParseNode;
  begin
    Result := NewNode(ntLeftRight);
    Result.Body := FArena.NewList([AArray]);
    Result.LeftDelimiter := ALeft;
    Result.RightDelimiter := ARight;
  end;

begin
  EnterNesting;

  var LParameters := Default(TMathArrayParameters);
  var LText: string;
  var LDelimiters: TArray<string>;
  var LColumnAlign: TMathColumnAlign;
  var LColumnCount: Integer;
  var LCells: Integer;
  var LIndexCell: Integer;
  var LMathCount: Integer;
  var LIsAligned: Boolean;
  var LEmptyGroup: TMathParseNode;
  var LAlign: TMathColumnAlign;
  var LPregap: Double;

  if (AName = 'array') or (AName = 'darray') or (AName = 'subarray') then
  begin
    var LColumnNodes := ColumnSymbols(AArgs[0]);

    for var LIndex := 0 to LColumnNodes.Count - 1 do
    begin
      if not IsSymbolNode(LColumnNodes[LIndex]) then
        raise ParseMathError('Invalid column alignment');

      LText := LColumnNodes[LIndex].Text;

      if (AName = 'subarray') and not ((LText = 'l') or (LText = 'c')) then
        raise ParseMathError('Unknown column alignment: ' + LText)
      else
      if TryColumnAlign(LText, LColumnAlign) then
        LParameters.Columns := LParameters.Columns + [TMathAlignSpec.Column(LColumnAlign)]
      else
      if (LText = '|') or (LText = ':') then
        LParameters.Columns := LParameters.Columns + [TMathAlignSpec.SeparatorLine(LText = ':')]
      else
        raise ParseMathError('Unknown column alignment: ' + LText);
    end;

    if AName = 'subarray' then
    begin
      if Length(LParameters.Columns) > 1 then
        raise ParseMathError('{subarray} can contain only one column');

      LParameters.ArrayStretch := 0.5;
      Result := ParseArray(LParameters, snScript);

      if (Result.Rows.Count > 0) and (Result.Rows[0].Count > 1) then
        raise ParseMathError('{subarray} can contain only one column');
    end
    else
    begin
      LParameters.HSkipBeforeAndAfter := True;
      LParameters.MaxNumCols := Length(LParameters.Columns);
      Result := ParseArray(LParameters, CellStyle);
    end;
  end
  else
  if AName.Replace('*', '').EndsWith('matrix') and (AName <> 'smallmatrix') then
  begin
    LColumnAlign := caCenter;

    if AName.EndsWith('*') then
    begin
      ConsumeSpaces;

      if Fetch.Text = '[' then
      begin
        Consume;
        ConsumeSpaces;
        if not TryColumnAlign(Fetch.Text, LColumnAlign) then
          raise ParseMathError('Expected l or c or r', Fetch.Position);

        Consume;
        ConsumeSpaces;
        Expect(']');
      end;
    end;

    LParameters.Columns := [TMathAlignSpec.Column(LColumnAlign)];
    Result := ParseArray(LParameters, CellStyle);
    LColumnCount := 0;

    for var LIndex := 0 to Result.Rows.Count - 1 do
      LColumnCount := Max(LColumnCount, Result.Rows[LIndex].Count);

    LParameters.Columns := nil;

    for var LIndex := 1 to LColumnCount do
      LParameters.Columns := LParameters.Columns + [TMathAlignSpec.Column(LColumnAlign)];

    Result.Columns := LParameters.Columns;
    LText := AName.Replace('*', '');

    if LText = 'pmatrix' then
      LDelimiters := ['(', ')']
    else
    if LText = 'bmatrix' then
      LDelimiters := ['[', ']']
    else
    if LText = 'Bmatrix' then
      LDelimiters := ['\{', '\}']
    else
    if LText = 'vmatrix' then
      LDelimiters := ['|', '|']
    else
    if LText = 'Vmatrix' then
      LDelimiters := ['\Vert', '\Vert']
    else
      LDelimiters := nil;

    if Assigned(LDelimiters) then
      Result := WrapInDelimiters(Result, LDelimiters[0], LDelimiters[1]);
  end
  else
  if AName = 'smallmatrix' then
  begin
    LParameters.ArrayStretch := 0.5;
    Result := ParseArray(LParameters, snScript);
    Result.ColSeparationType := csSmall;
  end
  else
  if (AName = 'cases') or (AName = 'dcases') or (AName = 'rcases') or (AName = 'drcases') then
  begin
    LParameters.ArrayStretch := 1.2;
    LParameters.Columns := [TMathAlignSpec.ColumnWithGaps(caLeft, 0, 1.0), TMathAlignSpec.ColumnWithGaps(caLeft, 0, 0)];
    Result := ParseArray(LParameters, CellStyle);

    if AName.Contains('r') then
      Result := WrapInDelimiters(Result, '.', '\}')
    else
      Result := WrapInDelimiters(Result, '\{', '.');
  end
  else
  if (AName = 'align') or (AName = 'align*') or (AName = 'aligned') or (AName = 'split') or (AName = 'alignat') or
    (AName = 'alignat*') or (AName = 'alignedat') then
  begin
    if not AName.Contains('ed') then
      ValidateDisplayMode;

    LParameters.AddJot := True;
    LParameters.AutoTag := if AName = 'split' then atUndefined else AutoTag;
    LParameters.EmptySingleRow := True;
    LParameters.ColSeparationType := if AName.Contains('at') then csAlignAt else csAlign;
    LParameters.MaxNumCols := if AName = 'split' then 2 else 0;
    Result := ParseArray(LParameters, snDisplay);

    LMathCount := 0;
    LColumnCount := 0;

    if (Length(AArgs) > 0) and (AArgs[0].NodeType = ntOrdGroup) then
    begin
      LText := '';

      for var LIndex := 0 to AArgs[0].Body.Count - 1 do
        LText := LText + AArgs[0].Body[LIndex].Text;

      if not TryStrToInt(LText, LMathCount) or (LMathCount < 1) then
        raise ParseMathError('Number of columns should be a positive integer');

      LColumnCount := LMathCount * 2;
    end;

    LIsAligned := LColumnCount = 0;

    for var LRowIndex := 0 to Result.Rows.Count - 1 do
    begin
      LCells := Result.Rows[LRowIndex].Count;
      LIndexCell := 1;

      while LIndexCell < LCells do
      begin
        LEmptyGroup := NewNode(ntOrdGroup);
        LEmptyGroup.Body := FArena.NewList;
        Result.Rows[LRowIndex][LIndexCell].Body[0].Body.Insert(0, LEmptyGroup);
        Inc(LIndexCell, 2);
      end;

      if not LIsAligned then
      begin
        if LMathCount < LCells div 2 then
          raise ParseMathError(Format('Too many math in a row: expected %d, but got %d', [LMathCount, LCells div 2]));
      end
      else
      if LColumnCount < LCells then
        LColumnCount := LCells;
    end;

    LParameters.Columns := nil;

    for var LIndex := 0 to LColumnCount - 1 do
    begin
      LAlign := caRight;
      LPregap := 0;

      if Odd(LIndex) then
        LAlign := caLeft
      else
      if (LIndex > 0) and LIsAligned then
        LPregap := 1;

      LParameters.Columns := LParameters.Columns + [TMathAlignSpec.ColumnWithGaps(LAlign, LPregap, 0)];
    end;

    Result.Columns := LParameters.Columns;
    Result.ColSeparationType := if LIsAligned then csAlign else csAlignAt;
  end
  else
  if (AName = 'gathered') or (AName = 'gather') or (AName = 'gather*') then
  begin
    if AName <> 'gathered' then
      ValidateDisplayMode;

    LParameters.Columns := [TMathAlignSpec.Column(caCenter)];
    LParameters.AddJot := True;
    LParameters.ColSeparationType := csGather;
    LParameters.AutoTag := AutoTag;
    LParameters.EmptySingleRow := True;

    Result := ParseArray(LParameters, snDisplay);
  end
  else
  if (AName = 'equation') or (AName = 'equation*') then
  begin
    ValidateDisplayMode;
    LParameters.AutoTag := AutoTag;
    LParameters.EmptySingleRow := True;
    LParameters.SingleRow := True;
    LParameters.MaxNumCols := 1;

    Result := ParseArray(LParameters, snDisplay);
  end
  else
  if AName = 'CD' then
  begin
    ValidateDisplayMode;
    Result := ParseCD;
  end
  else
    raise ParseMathError('No such environment: ' + AName);

  Dec(FNestingDepth);
end;

function TMathParser.ParseCD: TMathParseNode;
var
  LLabels: array [0..1] of TMathParseNode;
  LToken: TMathToken;

  function NewCell: TMathParseNode;
  begin
    Result := FArena.NewNode(ntStyling, mmMath);
    Result.Style := snDisplay;
    Result.ResetFont := True;
    Result.Body := FArena.NewList;
  end;

  function NewOrdGroup(const ABody: TMathNodeList): TMathParseNode;
  begin
    Result := FArena.NewNode(ntOrdGroup, mmMath);
    Result.Body := ABody;
  end;

  function IsStartOfArrow(const ANode: TMathParseNode): Boolean;
  begin
    Result := (ANode.NodeType = ntTextOrd) and (ANode.Text = '@');
  end;

  function IsLabelEnd(const ANode: TMathParseNode; const AEndCharacter: string): Boolean;
  begin
    Result := (ANode.NodeType in [ntMathOrd, ntAtom]) and (ANode.Text = AEndCharacter);
  end;

  function MakeArrow(const AArrowCharacter: string): TMathParseNode;
  var
    LArrow: TMathParseNode;
  begin
    if AArrowCharacter = '>' then
      Result := CallFunction('\\cdrightarrow', [LLabels[0]], [LLabels[1]], LToken, '')
    else
    if AArrowCharacter = '<' then
      Result := CallFunction('\\cdleftarrow', [LLabels[0]], [LLabels[1]], LToken, '')
    else
    if (AArrowCharacter = 'A') or (AArrowCharacter = 'V') then
    begin
      LArrow := FArena.NewNode(ntAtom, mmMath);
      LArrow.Text := if AArrowCharacter = 'A' then '\uparrow' else '\downarrow';
      LArrow.Family := sgRel;
      Result := CallFunction('\\cdparent', [NewOrdGroup(FArena.NewList([CallFunction('\\cdleft', [LLabels[0]], [], LToken, ''),
        CallFunction('\Big', [LArrow], [], LToken, ''), CallFunction('\\cdright', [LLabels[1]], [], LToken, '')]))], [],
        LToken, '');
    end
    else
    if AArrowCharacter = '=' then
      Result := CallFunction('\\cdlongequal', [], [], LToken, '')
    else
    if AArrowCharacter = '|' then
    begin
      LArrow := FArena.NewNode(ntTextOrd, mmMath);
      LArrow.Text := '\Vert';
      Result := CallFunction('\Big', [LArrow], [], LToken, '');
    end
    else
    begin
      Result := FArena.NewNode(ntTextOrd, mmMath);
      Result.Text := ' ';
    end;
  end;

begin
  LToken := TMathToken.Create('');

  var LParsedRows := FArena.NewRows;
  var LNext: string;
  var LRows: TMathNodeRows;
  var LRow: TMathNodeList;
  var LRowNodes: TMathNodeList;
  var LCell: TMathParseNode;
  var LWrappedArrow: TMathParseNode;
  var LNodeIndex: Integer;
  var LArrowCharacter: string;
  var LInLabel: Boolean;
  var LColumns: TArray<TMathAlignSpec>;
  var LHorizontalLines: TArray<TArray<Boolean>>;

  FGullet.BeginGroup;
  FGullet.Macros.SetMacro('\cr', TMathMacro.FromText('\\\relax'));
  FGullet.BeginGroup;

  while True do
  begin
    LParsedRows.Add(ParseExpression(False, '\\'));
    FGullet.EndGroup;
    FGullet.BeginGroup;
    LNext := Fetch.Text;

    if (LNext = '&') or (LNext = '\\') then
      Consume
    else
    if LNext = '\end' then
    begin
      if LParsedRows.Last.Count = 0 then
        LParsedRows.Delete(LParsedRows.Count - 1);

      Break;
    end
    else
      raise ParseMathError('Expected \\ or \cr or \end', Fetch.Position);
  end;

  LRow := FArena.NewList;
  LRows := FArena.NewRows;
  LRows.Add(LRow);

  for var LRowIndex := 0 to LParsedRows.Count - 1 do
  begin
    LRowNodes := LParsedRows[LRowIndex];
    LCell := NewCell;
    LNodeIndex := 0;

    while LNodeIndex < LRowNodes.Count do
    begin
      if not IsStartOfArrow(LRowNodes[LNodeIndex]) then
        LCell.Body.Add(LRowNodes[LNodeIndex])
      else
      begin
        LRow.Add(LCell);
        Inc(LNodeIndex);

        if (LNodeIndex >= LRowNodes.Count) or not IsSymbolNode(LRowNodes[LNodeIndex]) then
          raise ParseMathError('Expected one of "<>AV=|." after @');

        LArrowCharacter := LRowNodes[LNodeIndex].Text;
        LLabels[0] := NewOrdGroup(FArena.NewList);
        LLabels[1] := NewOrdGroup(FArena.NewList);

        if (LArrowCharacter = '<') or (LArrowCharacter = '>') or (LArrowCharacter = 'A') or (LArrowCharacter = 'V') then
        begin
          for var LLabelIndex := 0 to 1 do
          begin
            LInLabel := True;

            for var LLabelNode := LNodeIndex + 1 to LRowNodes.Count - 1 do
            begin
              if IsLabelEnd(LRowNodes[LLabelNode], LArrowCharacter) then
              begin
                LInLabel := False;
                LNodeIndex := LLabelNode;

                Break;
              end;

              if IsStartOfArrow(LRowNodes[LLabelNode]) then
                raise ParseMathError('Missing a ' + LArrowCharacter + ' character to complete a CD arrow.');

              LLabels[LLabelIndex].Body.Add(LRowNodes[LLabelNode]);
            end;

            if LInLabel then
              raise ParseMathError('Missing a ' + LArrowCharacter + ' character to complete a CD arrow.');
          end;
        end
        else
        if not ((LArrowCharacter = '=') or (LArrowCharacter = '|') or (LArrowCharacter = '.')) then
          raise ParseMathError('Expected one of "<>AV=|." after @');

        LWrappedArrow := NewCell;
        LWrappedArrow.Body.Add(MakeArrow(LArrowCharacter));
        LRow.Add(LWrappedArrow);
        LCell := NewCell;
      end;

      Inc(LNodeIndex);
    end;

    if not Odd(LRowIndex) then
      LRow.Add(LCell)
    else
    if LRow.Count > 0 then
      LRow.Delete(0);

    LRow := FArena.NewList;
    LRows.Add(LRow);
  end;

  FGullet.EndGroup;
  FGullet.EndGroup;

  LColumns := nil;

  for var LIndex := 1 to LRows[0].Count do
    LColumns := LColumns + [TMathAlignSpec.ColumnWithGaps(caCenter, 0.25, 0.25)];

  SetLength(LHorizontalLines, LRows.Count + 1);

  Result := FArena.NewNode(ntArray, mmMath);
  Result.Rows := LRows;
  Result.ArrayStretch := 1;
  Result.AddJot := True;
  Result.RowGaps := [Default(TMathRowGap)];
  Result.Columns := LColumns;
  Result.ColSeparationType := csCD;
  Result.HLinesBeforeRow := LHorizontalLines;
end;

procedure TMathParser.LetCommand(const AName: string; const AToken: TMathToken; const AGlobal: Boolean);
var
  LMacro: TMathMacro;
  LToken: TMathToken;
begin
  if not FGullet.Macros.Get(AToken.Text, LMacro) then
  begin
    LToken := AToken;
    LToken.NoExpand := True;
    LMacro := Default(TMathMacro);
    LMacro.Kind := mkTokens;
    LMacro.Tokens := [LToken];
    LMacro.Unexpandable := not FGullet.IsExpandable(AToken.Text);
  end;

  FGullet.Macros.SetMacro(AName, LMacro, AGlobal);
end;

function TMathParser.ParseDefinition(const AName: string): TMathParseNode;
begin
  var LToken := FGullet.PopToken;
  var LName := LToken.Text;

  if (LName = '\') or (LName = '{') or (LName = '}') or (LName = '$') or (LName = '&') or (LName = '#') or (LName = '^') or
    (LName = '_') or (LName = EOF_TOKEN) then
    raise ParseMathError('Expected a control sequence', LToken.Position);

  var LNumArgs := 0;
  var LHasInsert := False;
  var LDelimiters: TArray<TArray<string>> := [nil];
  var LInsert: TMathToken;
  var LTokens: TMathTokenArray;
  var LExpanded: TMathTokenArray;
  var LMacro: TMathMacro;

  while FGullet.Future.Text <> '{' do
  begin
    LToken := FGullet.PopToken;

    if LToken.Text = '#' then
    begin
      if FGullet.Future.Text = '{' then
      begin
        LInsert := FGullet.Future;
        LHasInsert := True;
        LDelimiters[LNumArgs] := LDelimiters[LNumArgs] + ['{'];

        Break;
      end;

      LToken := FGullet.PopToken;

      if not ((LToken.Text.Length = 1) and CharInSet(LToken.Text[1], ['1'..'9'])) then
        raise ParseMathError(Format('Invalid argument number "%s"', [LToken.Text]));

      if StrToInt(LToken.Text) <> LNumArgs + 1 then
        raise ParseMathError(Format('Argument number "%s" out of order', [LToken.Text]));

      Inc(LNumArgs);
      LDelimiters := LDelimiters + [nil];
    end
    else
    if LToken.Text = EOF_TOKEN then
      raise ParseMathError('Expected a macro definition')
    else
      LDelimiters[LNumArgs] := LDelimiters[LNumArgs] + [LToken.Text];
  end;

  LTokens := FGullet.ConsumeArg([]).Tokens;

  if LHasInsert then
    LTokens := [LInsert] + LTokens;

  if (AName = '\edef') or (AName = '\xdef') then
  begin
    LExpanded := FGullet.ExpandTokens(LTokens);
    SetLength(LTokens, Length(LExpanded));

    for var LIndex := 0 to High(LExpanded) do
      LTokens[High(LExpanded) - LIndex] := LExpanded[LIndex];
  end;

  LMacro := Default(TMathMacro);
  LMacro.Kind := mkTokens;
  LMacro.Tokens := LTokens;
  LMacro.NumArgs := LNumArgs;
  LMacro.Delimiters := LDelimiters;
  FGullet.Macros.SetMacro(LName, LMacro, (AName = '\gdef') or (AName = '\xdef'));

  Result := NewNode(ntInternal);
end;

procedure TMathParser.ConsumeSpaces;
begin
  while Fetch.Text = ' ' do
    Consume;
end;

function TMathParser.ParseExpression(const ABreakOnInfix: Boolean; const ABreakOnTokenText: string = ''): TMathNodeList;
var
  LToken: TMathToken;
  LAtom: TMathParseNode;
  LSpec: TMathFunctionSpec;
begin
  EnterNesting;

  Result := FArena.NewList;

  while True do
  begin
    if FMode = mmMath then
      ConsumeSpaces;

    LToken := Fetch;

    if (LToken.Text = '}') or (LToken.Text = '\endgroup') or (LToken.Text = '\end') or (LToken.Text = '\right') or
      (LToken.Text = '&') then
      Break;

    if not ABreakOnTokenText.IsEmpty and (LToken.Text = ABreakOnTokenText) then
      Break;

    if ABreakOnInfix and FindFunction(LToken.Text, LSpec) and LSpec.Infix then
      Break;

    LAtom := ParseAtom(ABreakOnTokenText);

    if not Assigned(LAtom) then
      Break
    else
    if LAtom.NodeType = ntInternal then
      Continue;

    Result.Add(LAtom);
  end;

  if FMode = mmText then
    FormLigatures(Result);

  Result := HandleInfixNodes(Result);
  Dec(FNestingDepth);
end;

function TMathParser.HandleInfixNodes(const ABody: TMathNodeList): TMathNodeList;
var
  LFunctionName: string;
  LNumerator: TMathParseNode;
  LDenominator: TMathParseNode;
  LNoToken: TMathToken;
begin
  var LOverIndex := -1;

  for var LIndex := 0 to ABody.Count - 1 do
  if ABody[LIndex].NodeType = ntInfix then
  begin
    if LOverIndex <> -1 then
      raise ParseMathError('only one infix operator per group');

    LOverIndex := LIndex;
    LFunctionName := ABody[LIndex].ReplaceWith;
  end;

  if LOverIndex = -1 then
    Exit(ABody);

  var LNumeratorBody := FArena.NewList;
  var LDenominatorBody := FArena.NewList;

  for var LIndex := 0 to LOverIndex - 1 do
    LNumeratorBody.Add(ABody[LIndex]);

  for var LIndex := LOverIndex + 1 to ABody.Count - 1 do
    LDenominatorBody.Add(ABody[LIndex]);

  if (LNumeratorBody.Count = 1) and (LNumeratorBody[0].NodeType = ntOrdGroup) then
    LNumerator := LNumeratorBody[0]
  else
  begin
    LNumerator := NewNode(ntOrdGroup);
    LNumerator.Body := LNumeratorBody;
  end;

  if (LDenominatorBody.Count = 1) and (LDenominatorBody[0].NodeType = ntOrdGroup) then
    LDenominator := LDenominatorBody[0]
  else
  begin
    LDenominator := NewNode(ntOrdGroup);
    LDenominator.Body := LDenominatorBody;
  end;

  LNoToken := TMathToken.Create('');

  if LFunctionName = '\\abovefrac' then
    Result := FArena.NewList([CallFunction(LFunctionName, [LNumerator, ABody[LOverIndex], LDenominator], [], LNoToken, '')])
  else
    Result := FArena.NewList([CallFunction(LFunctionName, [LNumerator, LDenominator], [], LNoToken, '')]);
end;

function TMathParser.HandleSupSubscript(const AName: string): TMathParseNode;
begin
  var LSymbolToken := Fetch;
  Consume;
  ConsumeSpaces;

  repeat
    Result := ParseGroup(AName);
  until not Assigned(Result) or (Result.NodeType <> ntInternal);

  if not Assigned(Result) then
    raise ParseMathError(Format('Expected group after ''%s''', [LSymbolToken.Text]), LSymbolToken.Position);
end;

function TMathParser.FormatUnsupportedCommand(const AText: string): TMathParseNode;
begin
  var LTextNode := NewNode(ntText);

  LTextNode.Body := FArena.NewList;

  var LCharacter: TMathParseNode;

  for var LIndex := 1 to AText.Length do
  begin
    LCharacter := FArena.NewNode(ntTextOrd, mmText);
    LCharacter.Text := AText[LIndex];
    LTextNode.Body.Add(LCharacter);
  end;

  Result := NewNode(ntColor);
  Result.Color := FSettings.ErrorColor;
  Result.Body := FArena.NewList([LTextNode]);
end;

function TMathParser.ParseAtom(const ABreakOnTokenText: string): TMathParseNode;
begin
  var LBase := ParseGroup('atom', ABreakOnTokenText);

  if Assigned(LBase) and (LBase.NodeType = ntInternal) then
    Exit(LBase);

  if FMode = mmText then
    Exit(LBase);

  var LSuperscript: TMathParseNode := nil;
  var LSubscript: TMathParseNode := nil;
  var LToken: TMathToken;
  var LPrime: TMathParseNode;
  var LPrimes: TMathNodeList;

  while True do
  begin
    ConsumeSpaces;
    LToken := Fetch;

    if (LToken.Text = '\limits') or (LToken.Text = '\nolimits') or (LToken.Text = '\displaylimits') then
    begin
      if Assigned(LBase) and (LBase.NodeType = ntOp) then
      begin
        LBase.Limits := LToken.Text <> '\nolimits';
        LBase.AlwaysHandleSupSub := LToken.Text <> '\displaylimits';
      end
      else
      if Assigned(LBase) and (LBase.NodeType = ntOperatorName) then
      begin
        if LBase.AlwaysHandleSupSub then
          LBase.Limits := LToken.Text = '\limits';
      end
      else
        raise ParseMathError('Limit controls must follow a math operator', LToken.Position);

      Consume;
    end
    else
    if LToken.Text = '^' then
    begin
      if Assigned(LSuperscript) then
        raise ParseMathError('Double superscript', LToken.Position);

      LSuperscript := HandleSupSubscript('superscript');
    end
    else
    if LToken.Text = '_' then
    begin
      if Assigned(LSubscript) then
        raise ParseMathError('Double subscript', LToken.Position);

      LSubscript := HandleSupSubscript('subscript');
    end
    else
    if LToken.Text = '''' then
    begin
      if Assigned(LSuperscript) then
        raise ParseMathError('Double superscript', LToken.Position);

      LPrime := NewNode(ntTextOrd);
      LPrime.Text := '\prime';
      LPrimes := FArena.NewList([LPrime]);
      Consume;

      while Fetch.Text = '''' do
      begin
        LPrimes.Add(LPrime);
        Consume;
      end;

      if Fetch.Text = '^' then
        LPrimes.Add(HandleSupSubscript('superscript'));

      LSuperscript := NewNode(ntOrdGroup);
      LSuperscript.Body := LPrimes;
    end
    else
      Break;
  end;

  if Assigned(LSuperscript) or Assigned(LSubscript) then
  begin
    Result := NewNode(ntSupSub);
    Result.Base := LBase;
    Result.Superscript := LSuperscript;
    Result.Subscript := LSubscript;
  end
  else
    Result := LBase;
end;

function TMathParser.ParseFunction(const ABreakOnTokenText: string; const AName: string): TMathParseNode;
begin
  var LToken := Fetch;
  var LSpec: TMathFunctionSpec;

  if not FindFunction(LToken.Text, LSpec) then
    Exit(nil);

  Consume;

  if not AName.IsEmpty and (AName <> 'atom') and not LSpec.AllowedInArgument then
    raise ParseMathError(Format('Got function ''%s'' with no arguments as %s', [LToken.Text, AName]), LToken.Position)
  else
  if (FMode = mmText) and not LSpec.AllowedInText then
    raise ParseMathError(Format('Can''t use function ''%s'' in text mode', [LToken.Text]), LToken.Position)
  else
  if (FMode = mmMath) and not LSpec.AllowedInMath then
    raise ParseMathError(Format('Can''t use function ''%s'' in math mode', [LToken.Text]), LToken.Position);

  var LArgs: TArray<TMathParseNode>;
  var LOptionalArgs: TArray<TMathParseNode>;

  ParseArguments(LToken.Text, LSpec, LArgs, LOptionalArgs);

  Result := CallFunction(LToken.Text, LArgs, LOptionalArgs, LToken, ABreakOnTokenText);
end;

procedure TMathParser.ParseArguments(const AFunctionName: string; const ASpec: TMathFunctionSpec; out AArgs: TArray<TMathParseNode>;
  out AOptionalArgs: TArray<TMathParseNode>);
begin
  AArgs := nil;
  AOptionalArgs := nil;

  var LTotalArgs := ASpec.NumArgs + ASpec.NumOptionalArgs;
  var LArgType: TMathArgType;
  var LIsOptional: Boolean;
  var LArgument: TMathParseNode;

  for var LIndex := 0 to LTotalArgs - 1 do
  begin
    LArgType := if LIndex < Length(ASpec.ArgTypes) then ASpec.ArgTypes[LIndex] else atDefault;
    LIsOptional := LIndex < ASpec.NumOptionalArgs;

    if (ASpec.Primitive and (LArgType = atDefault)) or ((ASpec.Kind = fkSqrt) and (LIndex = 1) and not Assigned(AOptionalArgs[0])) then
      LArgType := atPrimitive;

    LArgument := ParseGroupOfType(Format('argument to ''%s''', [AFunctionName]), LArgType, LIsOptional);

    if LIsOptional then
      AOptionalArgs := AOptionalArgs + [LArgument]
    else
    if Assigned(LArgument) then
      AArgs := AArgs + [LArgument]
    else
      raise ParseMathError('Null argument, please report this as a bug');
  end;
end;

function TMathParser.ParseGroupOfType(const AName: string; const AType: TMathArgType; const AOptional: Boolean): TMathParseNode;
begin
  case AType of
    atColor:
      Result := ParseColorGroup(AOptional);
    atSize:
      Result := ParseSizeGroup(AOptional);
    atMath:
      Result := ParseArgumentGroup(AOptional, True, mmMath);
    atText:
      Result := ParseArgumentGroup(AOptional, True, mmText);
    atHBox:
      begin
        var LGroup := ParseArgumentGroup(AOptional, True, mmText);

        if Assigned(LGroup) then
        begin
          Result := FArena.NewNode(ntStyling, LGroup.Mode);
          Result.Body := FArena.NewList([LGroup]);
          Result.Style := snText;
          Result.ResetFont := True;
        end
        else
          Result := nil;
      end;
    atRaw:
      begin
        FGullet.ConsumeSpaces;

        var LText: string;

        if ParseStringGroup(AOptional, LText) then
        begin
          Result := FArena.NewNode(ntTextOrd, mmText);
          Result.Text := LText;
        end
        else
          Result := nil;
      end;
    atPrimitive:
      begin
        if AOptional then
          raise ParseMathError('A primitive argument cannot be optional');

        Result := ParseGroup(AName);

        if not Assigned(Result) then
          raise ParseMathError('Expected group as ' + AName, Fetch.Position);
      end;
  else
    Result := ParseArgumentGroup(AOptional, False, mmMath);
  end;
end;

function TMathParser.ParseStringGroup(const AOptional: Boolean; out AText: string): Boolean;
begin
  AText := '';

  var LStartToken: TMathToken;

  if not FGullet.ScanArgument(AOptional, LStartToken) then
    Exit(False);

  var LToken := Fetch;

  while LToken.Text <> EOF_TOKEN do
  begin
    AText := AText + LToken.Text;
    Consume;
    LToken := Fetch;
  end;

  Consume;

  Result := True;
end;

function TMathParser.ParseColorGroup(const AOptional: Boolean): TMathParseNode;
begin
  var LText: string;

  if not ParseStringGroup(AOptional, LText) then
    Exit(nil);

  var LIsValid: Boolean;

  if LText.StartsWith('#') then
  begin
    var LHexLength := LText.Length - 1;

    LIsValid := (LHexLength in [3, 4, 6, 8]) and IsHexText(Copy(LText, 2, MaxInt));
  end
  else
  if (LText.Length = 6) and IsHexText(LText) then
  begin
    LIsValid := True;
    LText := '#' + LText;
  end
  else
  begin
    LIsValid := not LText.IsEmpty;

    for var LIndex := 1 to LText.Length do
    if not IsLetter(LText[LIndex]) then
      LIsValid := False;
  end;

  if not LIsValid then
    raise ParseMathError(Format('Invalid color: ''%s''', [LText]));

  Result := NewNode(ntColorToken);
  Result.Color := LText;
end;

function IsSizePrefix(const AText: string): Boolean;
var
  LIndex: Integer;
  LLength: Integer;

  procedure SkipSpaces;
  begin
    while (LIndex <= LLength) and (AText[LIndex] = ' ') do
      Inc(LIndex);
  end;

begin
  LIndex := 1;
  LLength := AText.Length;

  if (LIndex <= LLength) and CharInSet(AText[LIndex], ['-', '+']) then
    Inc(LIndex);

  SkipSpaces;

  if LIndex > LLength then
    Exit(True);

  while (LIndex <= LLength) and CharInSet(AText[LIndex], ['0'..'9']) do
    Inc(LIndex);

  if (LIndex <= LLength) and (AText[LIndex] = '.') then
  begin
    Inc(LIndex);

    while (LIndex <= LLength) and CharInSet(AText[LIndex], ['0'..'9']) do
      Inc(LIndex);
  end;

  SkipSpaces;

  var LLetters := 0;

  while (LIndex <= LLength) and CharInSet(AText[LIndex], ['a'..'z']) do
  begin
    Inc(LIndex);
    Inc(LLetters);
  end;

  if LLetters > 2 then
    Exit(False);

  SkipSpaces;

  Result := LIndex > LLength;
end;

function TryParseMeasurement(const AText: string; out AMeasurement: TMathMeasurement): Boolean;
begin
  var LFormatSettings := TFormatSettings.Invariant;
  var LIndex: Integer;
  var LStart: Integer;
  var LSign: string;
  var LNumberText: string;
  var LNumber: Double;

  for LStart := 1 to AText.Length do
  begin
    LIndex := LStart;
    LSign := '';

    if CharInSet(AText[LIndex], ['-', '+']) then
    begin
      LSign := AText[LIndex];
      Inc(LIndex);
    end;

    while (LIndex <= AText.Length) and (AText[LIndex] = ' ') do
      Inc(LIndex);

    LNumberText := '';

    while (LIndex <= AText.Length) and CharInSet(AText[LIndex], ['0'..'9']) do
    begin
      LNumberText := LNumberText + AText[LIndex];
      Inc(LIndex);
    end;

    if (LIndex <= AText.Length) and (AText[LIndex] = '.') then
    begin
      LNumberText := LNumberText + '.';
      Inc(LIndex);

      while (LIndex <= AText.Length) and CharInSet(AText[LIndex], ['0'..'9']) do
      begin
        LNumberText := LNumberText + AText[LIndex];
        Inc(LIndex);
      end;
    end;

    if (LNumberText = '') or (LNumberText = '.') then
      Continue;

    while (LIndex <= AText.Length) and (AText[LIndex] = ' ') do
      Inc(LIndex);

    if (LIndex + 1 <= AText.Length) and CharInSet(AText[LIndex], ['a'..'z']) and CharInSet(AText[LIndex + 1], ['a'..'z']) then
    begin
      if LNumberText.StartsWith('.') then
        LNumberText := '0' + LNumberText;

      if LNumberText.EndsWith('.') then
        LNumberText := LNumberText + '0';

      LNumber := StrToFloat(LNumberText, LFormatSettings);

      if LSign = '-' then
        LNumber := -LNumber;

      AMeasurement := TMathMeasurement.Create(LNumber, Copy(AText, LIndex, 2));

      Exit(True);
    end;
  end;

  Result := False;
end;

function IsValidUnit(const AUnit: string): Boolean;
begin
  Result := (AUnit = 'pt') or (AUnit = 'mm') or (AUnit = 'cm') or (AUnit = 'in') or (AUnit = 'bp') or (AUnit = 'pc') or
    (AUnit = 'dd') or (AUnit = 'cc') or (AUnit = 'nd') or (AUnit = 'nc') or (AUnit = 'sp') or (AUnit = 'px') or
    (AUnit = 'ex') or (AUnit = 'em') or (AUnit = 'mu');
end;

function TMathParser.ParseSizeRegexGroup: string;
begin
  var LFirstToken := Fetch;

  Result := '';

  var LToken := Fetch;

  while (LToken.Text <> EOF_TOKEN) and IsSizePrefix(Result + LToken.Text) do
  begin
    Result := Result + LToken.Text;
    Consume;
    LToken := Fetch;
  end;

  if Result.IsEmpty then
    raise ParseMathError(Format('Invalid size: ''%s''', [LFirstToken.Text]), LFirstToken.Position);
end;

function TMathParser.ParseSizeGroup(const AOptional: Boolean): TMathParseNode;
begin
  var LIsBlank := False;

  FGullet.ConsumeSpaces;

  var LText: string;

  if not AOptional and (FGullet.Future.Text <> '{') then
    LText := ParseSizeRegexGroup
  else
  if not ParseStringGroup(AOptional, LText) then
    Exit(nil);

  if not AOptional and LText.IsEmpty then
  begin
    LText := '0pt';
    LIsBlank := True;
  end;

  var LMeasurement: TMathMeasurement;

  if not TryParseMeasurement(LText, LMeasurement) then
    raise ParseMathError(Format('Invalid size: ''%s''', [LText]));

  if not IsValidUnit(LMeasurement.MeasurementUnit) then
    raise ParseMathError(Format('Invalid unit: ''%s''', [LMeasurement.MeasurementUnit]));

  Result := NewNode(ntSize);
  Result.Value := LMeasurement;
  Result.IsBlank := LIsBlank;
end;

function TMathParser.ParseArgumentGroup(const AOptional: Boolean; const AHasMode: Boolean; const AMode: TMathMode): TMathParseNode;
begin
  var LStartToken: TMathToken;

  if not FGullet.ScanArgument(AOptional, LStartToken) then
    Exit(nil);

  var LOuterMode := FMode;

  if AHasMode then
    SwitchMode(AMode);

  FGullet.BeginGroup;

  var LExpression := ParseExpression(False, EOF_TOKEN);

  Expect(EOF_TOKEN);
  FGullet.EndGroup;

  Result := NewNode(ntOrdGroup);
  Result.Body := LExpression;

  if AHasMode then
    SwitchMode(LOuterMode);
end;

function TMathParser.ParseGroup(const AName: string; const ABreakOnTokenText: string = ''): TMathParseNode;
begin
  EnterNesting;

  var LFirstToken := Fetch;

  if (LFirstToken.Text = '{') or (LFirstToken.Text = '\begingroup') then
  begin
    Consume;

    var LGroupEnd := if LFirstToken.Text = '{' then '}' else '\endgroup';

    FGullet.BeginGroup;

    var LExpression := ParseExpression(False, LGroupEnd);

    Expect(LGroupEnd);
    FGullet.EndGroup;

    Result := NewNode(ntOrdGroup);
    Result.Body := LExpression;
    Result.Semisimple := LFirstToken.Text = '\begingroup';
  end
  else
  begin
    Result := ParseFunction(ABreakOnTokenText, AName);

    if not Assigned(Result) then
      Result := ParseSymbol;

    if not Assigned(Result) and LFirstToken.Text.StartsWith('\') and not IsImplicitCommand(LFirstToken.Text) then
    begin
      if FSettings.ThrowOnError then
        raise ParseMathError('Undefined control sequence: ' + LFirstToken.Text, LFirstToken.Position);

      Result := FormatUnsupportedCommand(LFirstToken.Text);
      Consume;
    end;
  end;

  Dec(FNestingDepth);
end;

procedure TMathParser.FormLigatures(const AGroup: TMathNodeList);
begin
  var LCount := AGroup.Count - 1;
  var LIndex := 0;
  var LNode: TMathParseNode;
  var LNext: TMathParseNode;
  var LCombined: TMathParseNode;
  var LLength: Integer;

  while LIndex < LCount do
  begin
    LNode := AGroup[LIndex];
    LNext := AGroup[LIndex + 1];

    if (LNode.NodeType = ntTextOrd) and (LNext.NodeType = ntTextOrd) then
    begin
      LLength := 0;

      if (LNode.Text = '-') and (LNext.Text = '-') then
      begin
        if (LIndex + 1 < LCount) and (AGroup[LIndex + 2].NodeType = ntTextOrd) and (AGroup[LIndex + 2].Text = '-') then
          LLength := 3
        else
          LLength := 2;
      end
      else
      if ((LNode.Text = '''') or (LNode.Text = '`')) and (LNext.Text = LNode.Text) then
        LLength := 2;

      if LLength > 0 then
      begin
        LCombined := FArena.NewNode(ntTextOrd, mmText);
        LCombined.Text := StringOfChar(LNode.Text[1], LLength);
        AGroup.DeleteRange(LIndex, LLength);
        AGroup.Insert(LIndex, LCombined);
        Dec(LCount, LLength - 1);
      end;
    end;

    Inc(LIndex);
  end;
end;

function TMathParser.ParseSymbol: TMathParseNode;
begin
  var LNucleus := Fetch;
  var LText := LNucleus.Text;

  if LText.IsEmpty or (LText = EOF_TOKEN) then
    Exit(nil);

  if LText.StartsWith('\verb') and (LText.Length > 5) and not IsLetter(LText[6]) then
  begin
    Consume;
    LText := Copy(LText, 6, MaxInt);
    Result := FArena.NewNode(ntVerb, mmText);
    Result.IsStarred := LText.StartsWith('*');

    if Result.IsStarred then
      LText := Copy(LText, 2, MaxInt);

    if (LText.Length < 2) or (LText[1] <> LText[LText.Length]) then
      raise ParseMathError('\verb assertion failed -- please report what input caused this bug');

    Result.Text := Copy(LText, 2, LText.Length - 2);

    Exit;
  end;

  var LDecomposition: string;
  var LSymbol: PMathSymbolDefinition;

  if FindUnicodeSymbol(LText[1], LDecomposition) and not FindSymbol(FMode, LText[1], LSymbol) then
    LText := LDecomposition + Copy(LText, 2, MaxInt);

  var LAccentStart := LText.Length + 1;

  while (LAccentStart > 2) and (Ord(LText[LAccentStart - 1]) >= $0300) and (Ord(LText[LAccentStart - 1]) <= $036F) do
    Dec(LAccentStart);

  var LAccents := Copy(LText, LAccentStart, MaxInt);

  if not LAccents.IsEmpty then
  begin
    LText := Copy(LText, 1, LAccentStart - 1);

    if LText = 'i' then
      LText := #$0131
    else
    if LText = 'j' then
      LText := #$0237;
  end;

  if FindSymbol(FMode, LText, LSymbol) then
  begin
    case LSymbol.Group of
      sgBin, sgClose, sgInner, sgOpen, sgPunct, sgRel:
        begin
          Result := NewNode(ntAtom);
          Result.Family := LSymbol.Group;
        end;
      sgAccentToken:
        Result := NewNode(ntAccentToken);
      sgMathOrd:
        Result := NewNode(ntMathOrd);
      sgOpToken:
        Result := NewNode(ntOpToken);
      sgSpacing:
        Result := NewNode(ntSpacing);
    else
      Result := NewNode(ntTextOrd);
    end;

    Result.Text := LText;
  end
  else
  if Ord(LText[1]) >= $80 then
  begin
    Result := FArena.NewNode(ntTextOrd, mmText);
    Result.Text := LText;
  end
  else
    Exit(nil);

  Consume;

  var LCommand: string;
  var LAccentNode: TMathParseNode;

  for var LIndex := 1 to LAccents.Length do
  begin
    if not FindUnicodeAccentCommand(LAccents[LIndex], FMode, LCommand) then
      raise ParseMathError(Format('Unknown accent '' %s''', [LAccents[LIndex]]), LNucleus.Position);

    LAccentNode := NewNode(ntAccent);
    LAccentNode.LabelText := LCommand;
    LAccentNode.IsStretchy := False;
    LAccentNode.IsShifty := True;
    LAccentNode.Base := Result;

    Result := LAccentNode;
  end;
end;

function GlobalCommandName(const AName: string): string;
begin
  if AName = '\global' then
    Result := '\global'
  else
  if (AName = '\long') or (AName = '\\globallong') then
    Result := '\\globallong'
  else
  if (AName = '\def') or (AName = '\gdef') then
    Result := '\gdef'
  else
  if (AName = '\edef') or (AName = '\xdef') then
    Result := '\xdef'
  else
  if AName = '\let' then
    Result := '\\globallet'
  else
  if AName = '\futurelet' then
    Result := '\\globalfuture'
  else
    Result := '';
end;

function EnvironmentArgumentCount(const AName: string; out ACount: Integer): Boolean;
const
  ENVIRONMENTS: array [0..31] of string = ('array', 'darray', 'subarray', 'alignat', 'alignat*', 'alignedat', 'matrix', 'pmatrix',
    'bmatrix', 'Bmatrix', 'vmatrix', 'Vmatrix', 'matrix*', 'pmatrix*', 'bmatrix*', 'Bmatrix*', 'vmatrix*', 'Vmatrix*', 'smallmatrix',
    'cases', 'dcases', 'rcases', 'drcases', 'align', 'align*', 'aligned', 'split', 'gathered', 'gather', 'gather*', 'equation', 'CD');
begin
  ACount := 0;

  for var LIndex := Low(ENVIRONMENTS) to High(ENVIRONMENTS) do
  if ENVIRONMENTS[LIndex] = AName then
  begin
    if LIndex <= 5 then
      ACount := 1;

    Exit(True);
  end;

  Result := AName = 'equation*';
end;

function TMathParser.CallFunction(const AName: string; const AArgs: TArray<TMathParseNode>;
  const AOptionalArgs: TArray<TMathParseNode>; const AToken: TMathToken; const ABreakOnTokenText: string): TMathParseNode;
const
  NON_STRETCHY_ACCENTS: array [0..10] of string = ('\acute', '\grave', '\ddot', '\tilde', '\bar', '\breve', '\check', '\hat', '\vec',
    '\dot', '\mathring');
  SIZE_FUNCTIONS: array [1..11] of string = ('\tiny', '\sixptsize', '\scriptsize', '\footnotesize', '\small', '\normalsize', '\large',
    '\Large', '\LARGE', '\huge', '\Huge');
  FRACTION_STYLES: array [0..3] of TMathStyleName = (snDisplay, snText, snScript, snScriptScript);

  function IsInList(const AText: string; const AList: array of string): Boolean;
  begin
    for var LIndex := Low(AList) to High(AList) do
    if AList[LIndex] = AText then
      Exit(True);

    Result := False;
  end;

  function NormalizeArgument(const AArgument: TMathParseNode): TMathParseNode;
  begin
    if (AArgument.NodeType = ntOrdGroup) and (AArgument.Body.Count = 1) then
      Result := AArgument.Body[0]
    else
      Result := AArgument;
  end;

  function CheckDelimiter(const AArgument: TMathParseNode): string;
  const
    DELIMITERS: array [0..57] of string = ('(', '\lparen', ')', '\rparen', '[', '\lbrack', ']', '\rbrack', '\{', '\lbrace',
      '\}', '\rbrace', '\lfloor', '\rfloor', #$230A, #$230B, '\lceil', '\rceil', #$2308, #$2309, '<', '>', '\langle', #$27E8,
      '\rangle', #$27E9, '\lt', '\gt', '\lvert', '\rvert', '\lVert', '\rVert', '\lgroup', '\rgroup', #$27EE, #$27EF,
      '\lmoustache', '\rmoustache', #$23B0, #$23B1, '/', '\backslash', '|', '\vert', '\|', '\Vert', '\uparrow', '\Uparrow',
      '\downarrow', '\Downarrow', '\updownarrow', '\Updownarrow', '.', '\lbrace', '\rbrace', '\lvert', '\rvert', '\vert');
  var
    LDelimiterNode: TMathParseNode;
  begin
    LDelimiterNode := NormalizeArgument(AArgument);

    if IsSymbolNode(LDelimiterNode) and IsInList(LDelimiterNode.Text, DELIMITERS) then
      Result := LDelimiterNode.Text
    else
    if IsSymbolNode(LDelimiterNode) then
      raise ParseMathError(Format('Invalid delimiter ''%s'' after ''%s''', [LDelimiterNode.Text, AName]))
    else
      raise ParseMathError('Invalid delimiter type after ''' + AName + '''');
  end;

  function BinRelClass(const AArgument: TMathParseNode): string;
  var
    LAtom: TMathParseNode;
  begin
    LAtom := AArgument;

    if (AArgument.NodeType = ntOrdGroup) and (AArgument.Body.Count > 0) then
      LAtom := AArgument.Body[0];

    if (LAtom.NodeType = ntAtom) and (LAtom.Family = sgBin) then
      Result := MATH_CLASS_BIN
    else
    if (LAtom.NodeType = ntAtom) and (LAtom.Family = sgRel) then
      Result := MATH_CLASS_REL
    else
      Result := MATH_CLASS_ORD;
  end;

  function WrapWithStyle(const AFraction: TMathParseNode; const AStyle: TMathStyleName): TMathParseNode;
  begin
    if AStyle = snNone then
      Exit(AFraction);

    Result := FArena.NewNode(ntStyling, AFraction.Mode);
    Result.Style := AStyle;
    Result.Body := FArena.NewList([AFraction]);
  end;

  function DelimiterFromValue(const AArgument: TMathParseNode; const AFamily: TMathSymbolGroup): string;
  var
    LValueNode: TMathParseNode;
  begin
    LValueNode := NormalizeArgument(AArgument);
    Result := '';

    if (LValueNode.NodeType = ntAtom) and (LValueNode.Family = AFamily) and (LValueNode.Text <> '.') then
      Result := LValueNode.Text;
  end;

  function NewOp(const ALimits: Boolean; const ASymbol: Boolean; const AOpName: string): TMathParseNode;
  begin
    Result := NewNode(ntOp);
    Result.Limits := ALimits;
    Result.Symbol := ASymbol;
    Result.Name := AOpName;
  end;

  function SingleCharacterOpName(const AText: string): string;
  begin
    case Ord(AText[1]) of
      $220F: Result := '\prod';
      $2210: Result := '\coprod';
      $2211: Result := '\sum';
      $22C0: Result := '\bigwedge';
      $22C1: Result := '\bigvee';
      $22C2: Result := '\bigcap';
      $22C3: Result := '\bigcup';
      $2A00: Result := '\bigodot';
      $2A01: Result := '\bigoplus';
      $2A02: Result := '\bigotimes';
      $2A04: Result := '\biguplus';
      $2A06: Result := '\bigsqcup';
      $222B: Result := '\int';
      $222C: Result := '\iint';
      $222D: Result := '\iiint';
      $222E: Result := '\oint';
      $222F: Result := '\oiint';
      $2230: Result := '\oiiint';
    else
      Result := AText;
    end;
  end;

begin
  var LSpec: TMathFunctionSpec;

  if not FindFunction(AName, LSpec) then
    raise ParseMathError('No function handler for ' + AName);

  var LNode: TMathParseNode;
  var LBody: TMathNodeList;
  var LCode: Int64;
  var LText: string;
  var LOuterMode: TMathMode;
  var LClose: string;
  var LBaseOp: TMathParseNode;
  var LSupSub: TMathParseNode;
  var LRight: TMathParseNode;
  var LMacro: TMathMacro;
  var LMiddle: TMathToken;
  var LToken: TMathToken;

  case LSpec.Kind of
    fkAccent:
      begin
        Result := NewNode(ntAccent);
        Result.LabelText := AName;
        Result.IsStretchy := not IsInList(AName, NON_STRETCHY_ACCENTS);
        Result.IsShifty := not Result.IsStretchy or (AName = '\widehat') or (AName = '\widetilde') or (AName = '\widecheck');
        Result.Base := NormalizeArgument(AArgs[0]);
      end;
    fkTextAccent:
      begin
        Result := NewNode(ntAccent);
        Result.Mode := mmText;
        Result.LabelText := AName;
        Result.IsStretchy := False;
        Result.IsShifty := True;
        Result.Base := AArgs[0];
      end;
    fkTextColor:
      begin
        Result := NewNode(ntColor);
        Result.Color := AArgs[0].Color;
        Result.Body := OrdArgument(AArgs[1]);
      end;
    fkColor:
      begin
        LMacro := Default(TMathMacro);
        LMacro.Kind := mkString;
        LMacro.Text := AArgs[0].Color;
        FGullet.Macros.SetMacro('\current@color', LMacro);

        LBody := ParseExpression(True, ABreakOnTokenText);
        Result := NewNode(ntColor);
        Result.Color := AArgs[0].Color;
        Result.Body := LBody;
      end;
    fkDelimSizing:
      begin
        Result := NewNode(ntDelimSizing);
        Result.Delimiter := CheckDelimiter(AArgs[0]);

        if AName.StartsWith('\bigg') or AName.StartsWith('\Bigg') then
          Result.Size := if AName[2] = 'b' then 3 else 4
        else
          Result.Size := if AName[2] = 'b' then 1 else 2;

        case AName[AName.Length] of
          'l': Result.MathClass := MATH_CLASS_OPEN;
          'r': Result.MathClass := MATH_CLASS_CLOSE;
          'm': Result.MathClass := MATH_CLASS_REL;
        else
          Result.MathClass := MATH_CLASS_ORD;
        end;
      end;
    fkRight:
      begin
        Result := NewNode(ntLeftRightRight);
        Result.Delimiter := CheckDelimiter(AArgs[0]);

        if FGullet.Macros.Get('\current@color', LMacro) then
          Result.Color := LMacro.Text;
      end;
    fkLeft:
      begin
        LText := CheckDelimiter(AArgs[0]);
        Inc(FLeftRightDepth);
        LBody := ParseExpression(False);
        Dec(FLeftRightDepth);
        Expect('\right', False);
        LRight := ParseFunction('', '');

        if not Assigned(LRight) or (LRight.NodeType <> ntLeftRightRight) then
          raise ParseMathError('Expected \right');

        Result := NewNode(ntLeftRight);
        Result.Body := LBody;
        Result.LeftDelimiter := LText;
        Result.RightDelimiter := LRight.Delimiter;
        Result.RightColor := LRight.Color;
      end;
    fkMiddle:
      begin
        LText := CheckDelimiter(AArgs[0]);

        if FLeftRightDepth = 0 then
          raise ParseMathError('\middle without preceding \left');

        Result := NewNode(ntMiddle);
        Result.Delimiter := LText;
      end;
    fkFont:
      begin
        Result := NewNode(ntFont);

        if AName = '\Bbb' then
          Result.Font := 'mathbb'
        else
        if AName = '\bold' then
          Result.Font := 'mathbf'
        else
        if AName = '\frak' then
          Result.Font := 'mathfrak'
        else
          Result.Font := Copy(AName, 2, MaxInt);

        Result.Child := NormalizeArgument(AArgs[0]);
      end;
    fkBoldSymbol:
      begin
        LNode := NewNode(ntFont);
        LNode.Font := 'boldsymbol';
        LNode.Child := AArgs[0];

        Result := NewNode(ntMClass);
        Result.MathClass := BinRelClass(AArgs[0]);
        Result.Body := FArena.NewList([LNode]);
        Result.IsCharacterBox := IsCharacterBox(AArgs[0]);
      end;
    fkOldFont:
      begin
        LBody := ParseExpression(True, ABreakOnTokenText);
        LNode := NewNode(ntOrdGroup);
        LNode.Body := LBody;

        Result := NewNode(ntFont);
        Result.Font := 'math' + Copy(AName, 2, MaxInt);
        Result.Child := LNode;
      end;
    fkGenFrac:
      begin
        Result := NewNode(ntGenFrac);
        Result.Numerator := AArgs[0];
        Result.Denominator := AArgs[1];
        Result.HasBarLine := (AName = '\cfrac') or (AName = '\dfrac') or (AName = '\frac') or (AName = '\tfrac');

        if (AName = '\dbinom') or (AName = '\binom') or (AName = '\tbinom') then
        begin
          Result.LeftDelimiter := '(';
          Result.RightDelimiter := ')';
        end
        else
        if AName = '\\bracefrac' then
        begin
          Result.LeftDelimiter := '\{';
          Result.RightDelimiter := '\}';
        end
        else
        if AName = '\\brackfrac' then
        begin
          Result.LeftDelimiter := '[';
          Result.RightDelimiter := ']';
        end;

        Result.Continued := AName = '\cfrac';

        if Result.Continued or AName.StartsWith('\d') then
          Result := WrapWithStyle(Result, snDisplay)
        else
        if AName.StartsWith('\t') then
          Result := WrapWithStyle(Result, snText);
      end;
    fkInfix, fkAboveInfix:
      begin
        Result := NewNode(ntInfix);

        if AName = '\over' then
          Result.ReplaceWith := '\frac'
        else
        if AName = '\choose' then
          Result.ReplaceWith := '\binom'
        else
        if AName = '\atop' then
          Result.ReplaceWith := '\\atopfrac'
        else
        if AName = '\brace' then
          Result.ReplaceWith := '\\bracefrac'
        else
        if AName = '\brack' then
          Result.ReplaceWith := '\\brackfrac'
        else
        begin
          Result.ReplaceWith := '\\abovefrac';
          Result.Value := AArgs[0].Value;
        end;
      end;
    fkGenFracGeneral:
      begin
        Result := NewNode(ntGenFrac);
        Result.Numerator := AArgs[4];
        Result.Denominator := AArgs[5];
        Result.LeftDelimiter := DelimiterFromValue(AArgs[0], sgOpen);
        Result.RightDelimiter := DelimiterFromValue(AArgs[1], sgClose);

        if AArgs[2].IsBlank then
          Result.HasBarLine := True
        else
        begin
          Result.BarSize := AArgs[2].Value;
          Result.HasBarSize := True;
          Result.HasBarLine := AArgs[2].Value.Number > 0;
        end;

        LText := '';
        LNode := AArgs[3];

        if LNode.NodeType = ntOrdGroup then
        begin
          if LNode.Body.Count > 0 then
            LText := LNode.Body[0].Text;
        end
        else
          LText := LNode.Text;

        if (LText.Length = 1) and CharInSet(LText[1], ['0'..'3']) then
          Result := WrapWithStyle(Result, FRACTION_STYLES[Ord(LText[1]) - Ord('0')]);
      end;
    fkAboveFrac:
      begin
        Result := NewNode(ntGenFrac);
        Result.Numerator := AArgs[0];
        Result.Denominator := AArgs[2];
        Result.BarSize := AArgs[1].Value;
        Result.HasBarSize := True;
        Result.HasBarLine := AArgs[1].Value.Number > 0;
      end;
    fkKern:
      begin
        Result := NewNode(ntKern);
        Result.Dimension := AArgs[0].Value;
      end;
    fkLap:
      begin
        Result := NewNode(ntLap);

        if AName = '\mathllap' then
          Result.Alignment := laLeft
        else
        if AName = '\mathclap' then
          Result.Alignment := laCenter
        else
          Result.Alignment := laRight;

        Result.Child := AArgs[0];
      end;
    fkMathChoice:
      begin
        Result := NewNode(ntMathChoice);
        Result.DisplayBody := OrdArgument(AArgs[0]);
        Result.TextBody := OrdArgument(AArgs[1]);
        Result.ScriptBody := OrdArgument(AArgs[2]);
        Result.ScriptScriptBody := OrdArgument(AArgs[3]);
      end;
    fkMClass:
      begin
        Result := NewNode(ntMClass);
        Result.MathClass := 'm' + Copy(AName, 6, MaxInt);
        Result.Body := OrdArgument(AArgs[0]);
        Result.IsCharacterBox := IsCharacterBox(AArgs[0]);
      end;
    fkBinRel:
      begin
        Result := NewNode(ntMClass);
        Result.MathClass := BinRelClass(AArgs[0]);
        Result.Body := OrdArgument(AArgs[1]);
        Result.IsCharacterBox := IsCharacterBox(AArgs[1]);
      end;
    fkStackRel:
      begin
        LBaseOp := FArena.NewNode(ntOp, AArgs[1].Mode);
        LBaseOp.Limits := True;
        LBaseOp.AlwaysHandleSupSub := True;
        LBaseOp.Symbol := False;
        LBaseOp.SuppressBaseShift := AName <> '\stackrel';
        LBaseOp.HasBody := True;
        LBaseOp.Body := OrdArgument(AArgs[1]);

        LSupSub := FArena.NewNode(ntSupSub, AArgs[0].Mode);
        LSupSub.Base := LBaseOp;

        if AName = '\underset' then
          LSupSub.Subscript := AArgs[0]
        else
          LSupSub.Superscript := AArgs[0];

        Result := NewNode(ntMClass);
        Result.MathClass := if AName = '\stackrel' then MATH_CLASS_REL else BinRelClass(AArgs[1]);
        Result.Body := FArena.NewList([LSupSub]);
        Result.IsCharacterBox := IsCharacterBox(LSupSub);
      end;
    fkOpSymbol:
      Result := NewOp(True, True, SingleCharacterOpName(AName));
    fkMathOp:
      begin
        Result := NewOp(False, False, '');
        Result.HasBody := True;
        Result.Body := OrdArgument(AArgs[0]);
      end;
    fkOpNoLimits:
      Result := NewOp(False, False, AName);
    fkOpLimits:
      Result := NewOp(True, False, AName);
    fkOpIntegral:
      Result := NewOp(False, True, SingleCharacterOpName(AName));
    fkOperatorName:
      begin
        Result := NewNode(ntOperatorName);
        Result.Body := OrdArgument(AArgs[0]);
        Result.AlwaysHandleSupSub := AName = '\operatornamewithlimits';
        Result.Limits := False;
      end;
    fkOverline:
      begin
        Result := NewNode(ntOverline);
        Result.Child := AArgs[0];
      end;
    fkUnderline:
      begin
        Result := NewNode(ntUnderline);
        Result.Child := AArgs[0];
      end;
    fkPhantom:
      begin
        Result := NewNode(ntPhantom);
        Result.Body := OrdArgument(AArgs[0]);
      end;
    fkVPhantom:
      begin
        Result := NewNode(ntVPhantom);
        Result.Child := AArgs[0];
      end;
    fkRaiseBox:
      begin
        Result := NewNode(ntRaiseBox);
        Result.Dimension := AArgs[0].Value;
        Result.Child := AArgs[1];
      end;
    fkRelax:
      Result := NewNode(ntInternal);
    fkRule:
      begin
        Result := NewNode(ntRule);
        Result.HasShift := Assigned(AOptionalArgs[0]);

        if Result.HasShift then
          Result.RuleShift := AOptionalArgs[0].Value;

        Result.RuleWidth := AArgs[0].Value;
        Result.RuleHeight := AArgs[1].Value;
      end;
    fkSizing:
      begin
        LBody := ParseExpression(False, ABreakOnTokenText);
        Result := NewNode(ntSizing);
        Result.Body := LBody;

        for var LIndex := Low(SIZE_FUNCTIONS) to High(SIZE_FUNCTIONS) do
        if SIZE_FUNCTIONS[LIndex] = AName then
          Result.Size := LIndex;
      end;
    fkSmash:
      begin
        Result := NewNode(ntSmash);
        Result.Child := AArgs[0];
        Result.SmashHeight := True;
        Result.SmashDepth := True;

        if Assigned(AOptionalArgs[0]) and (AOptionalArgs[0].NodeType = ntOrdGroup) then
        begin
          Result.SmashHeight := False;
          Result.SmashDepth := False;

          for var LIndex := 0 to AOptionalArgs[0].Body.Count - 1 do
          begin
            LText := AOptionalArgs[0].Body[LIndex].Text;

            if LText = 't' then
              Result.SmashHeight := True
            else
            if LText = 'b' then
              Result.SmashDepth := True
            else
            begin
              Result.SmashHeight := False;
              Result.SmashDepth := False;

              Break;
            end;
          end;
        end;
      end;
    fkSqrt:
      begin
        Result := NewNode(ntSqrt);
        Result.Child := AArgs[0];
        Result.Index := AOptionalArgs[0];
      end;
    fkStyling:
      begin
        LBody := ParseExpression(True, ABreakOnTokenText);
        Result := NewNode(ntStyling);

        for var LStyle := snDisplay to High(TMathStyleName) do
        if AName = '\' + STYLE_NAMES[LStyle] + 'style' then
          Result.Style := LStyle;

        Result.Body := LBody;
      end;
    fkText:
      begin
        Result := NewNode(ntText);
        Result.Body := OrdArgument(AArgs[0]);
        Result.Font := AName;
      end;
    fkChar:
      begin
        LText := '';

        if AArgs[0].NodeType = ntOrdGroup then
        for var LIndex := 0 to AArgs[0].Body.Count - 1 do
          LText := LText + AArgs[0].Body[LIndex].Text;

        if not TryStrToInt64(LText, LCode) then
          raise ParseMathError('\@char has non-numeric argument ' + LText);

        if (LCode < 0) or (LCode > $10FFFF) then
          raise ParseMathError('\@char with invalid code point ' + LText);

        Result := NewNode(ntTextOrd);
        Result.Text := Char.ConvertFromUtf32(LCode);
      end;
    fkMathShift:
      begin
        LOuterMode := FMode;
        SwitchMode(mmMath);
        LClose := if AName = '\(' then '\)' else '$';
        LBody := ParseExpression(False, LClose);
        Expect(LClose);
        SwitchMode(LOuterMode);

        Result := NewNode(ntStyling);
        Result.Style := snText;
        Result.ResetFont := True;
        Result.Body := LBody;
      end;
    fkMismatchedMath:
      raise ParseMathError('Mismatched ' + AName);
    fkHBox:
      begin
        Result := NewNode(ntStyling);
        Result.Style := snNone;
        Result.ResetFont := True;
        Result.Body := OrdArgument(AArgs[0]);
      end;
    fkHtmlMathMl:
      begin
        Result := NewNode(ntOrdGroup);
        Result.Body := OrdArgument(AArgs[0]);
        Result.Semisimple := True;
      end;
    fkEnvironment:
      Result := ParseEnvironmentCommand(AName, AArgs[0]);
    fkCr:
      begin
        Result := NewNode(ntCr);
        Result.NewLine := True;

        if FGullet.Future.Text = '[' then
        begin
          LNode := ParseSizeGroup(True);
          Result.HasDimension := Assigned(LNode);

          if Result.HasDimension then
            Result.Dimension := LNode.Value;
        end;
      end;
    fkHLine:
      raise ParseMathError(AName + ' valid only within array environment');
    fkGlobal:
      begin
        ConsumeSpaces;
        LText := GlobalCommandName(Fetch.Text);

        if LText.IsEmpty then
          raise ParseMathError('Invalid token after macro prefix', Fetch.Position);

        if (AName = '\global') or (AName = '\\globallong') then
          FNextToken.Text := LText;

        Result := ParseFunction('', '');

        if not Assigned(Result) or (Result.NodeType <> ntInternal) then
          raise ParseMathError('Invalid token after macro prefix');
      end;
    fkDefinition:
      Result := ParseDefinition(AName);
    fkLet:
      begin
        LText := CheckControlSequence(FGullet.PopToken);
        FGullet.ConsumeSpaces;
        LetCommand(LText, ReadRightHandSide, AName = '\\globallet');
        Result := NewNode(ntInternal);
      end;
    fkFutureLet:
      begin
        LText := CheckControlSequence(FGullet.PopToken);
        LMiddle := FGullet.PopToken;
        LToken := FGullet.PopToken;
        LetCommand(LText, LToken, AName = '\\globalfuture');
        FGullet.PushToken(LToken);
        FGullet.PushToken(LMiddle);
        Result := NewNode(ntInternal);
      end;
    fkAccentUnder:
      begin
        Result := NewNode(ntAccentUnder);
        Result.LabelText := AName;
        Result.Base := AArgs[0];
      end;
    fkHorizBrace:
      begin
        Result := NewNode(ntHorizBrace);
        Result.LabelText := AName;
        Result.IsOver := AName.Contains('\over');
        Result.Base := AArgs[0];
      end;
    fkXArrow:
      begin
        Result := NewNode(ntXArrow);
        Result.LabelText := AName;
        Result.Child := if Length(AArgs) > 0 then AArgs[0] else nil;
        Result.Below := if Length(AOptionalArgs) > 0 then AOptionalArgs[0] else nil;
      end;
    fkEnclose:
      begin
        Result := NewNode(ntEnclose);
        Result.LabelText := AName;

        if AName = '\colorbox' then
        begin
          Result.BackgroundColor := AArgs[0].Color;
          Result.Child := AArgs[1];
        end
        else
        if AName = '\fcolorbox' then
        begin
          Result.BorderColor := AArgs[0].Color;
          Result.BackgroundColor := AArgs[1].Color;
          Result.Child := AArgs[2];
        end
        else
          Result.Child := AArgs[0];
      end;
    fkPmb:
      begin
        Result := NewNode(ntPmb);
        Result.MathClass := BinRelClass(AArgs[0]);
        Result.Body := OrdArgument(AArgs[0]);
      end;
    fkVCenter:
      begin
        Result := NewNode(ntVCenter);
        Result.Child := AArgs[0];
      end;
    fkVerb:
      raise ParseMathError('\verb ended by end of line instead of matching delimiter');
    fkReflectBox:
      begin
        Result := NewNode(ntReflectBox);
        Result.Child := AArgs[0];
      end;
    fkCdLabel:
      begin
        Result := NewNode(ntCdLabel);
        Result.Alignment := if AName = '\\cdleft' then laLeft else laRight;
        Result.Child := AArgs[0];
      end;
    fkCdLabelParent:
      begin
        Result := NewNode(ntCdLabelParent);
        Result.Child := AArgs[0];
      end;
  else
    raise ParseMathError('No function handler for ' + AName);
  end;
end;

function TMathParser.CheckControlSequence(const AToken: TMathToken): string;
begin
  Result := AToken.Text;

  if (Result = '\') or (Result = '{') or (Result = '}') or (Result = '$') or (Result = '&') or (Result = '#') or (Result = '^') or
    (Result = '_') or (Result = EOF_TOKEN) then
    raise ParseMathError('Expected a control sequence', AToken.Position);
end;

function TMathParser.ReadRightHandSide: TMathToken;
begin
  Result := FGullet.PopToken;

  if Result.Text = '=' then
  begin
    Result := FGullet.PopToken;

    if Result.Text = ' ' then
      Result := FGullet.PopToken;
  end;
end;

function TMathParser.ParseEnvironmentCommand(const AName: string; const ANameGroup: TMathParseNode): TMathParseNode;
begin
  if ANameGroup.NodeType <> ntOrdGroup then
    raise ParseMathError('Invalid environment name');

  var LName := '';

  for var LIndex := 0 to ANameGroup.Body.Count - 1 do
  begin
    if not IsSymbolNode(ANameGroup.Body[LIndex]) then
      raise ParseMathError('Environment name should contain only text characters and spaces');

    LName := LName + ANameGroup.Body[LIndex].Text;
  end;

  if AName = '\end' then
  begin
    Result := NewNode(ntEnvironment);
    Result.Name := LName;

    Exit;
  end;

  var LCount: Integer;

  if not EnvironmentArgumentCount(LName, LCount) then
    raise ParseMathError('No such environment: ' + LName);

  var LSpec := Default(TMathFunctionSpec);

  LSpec.Kind := fkEnvironment;
  LSpec.NumArgs := LCount;

  var LArgs: TArray<TMathParseNode>;
  var LOptionalArgs: TArray<TMathParseNode>;

  ParseArguments('\begin{' + LName + '}', LSpec, LArgs, LOptionalArgs);

  Result := ParseEnvironment(LName, LArgs);

  Expect('\end', False);

  var LEndToken := Fetch;
  var LEnd := ParseFunction('', '');

  if not Assigned(LEnd) or (LEnd.NodeType <> ntEnvironment) or (LEnd.Name <> LName) then
    raise ParseMathError(Format('Mismatch: \begin{%s} matched by \end{%s}', [LName, if Assigned(LEnd) then LEnd.Name else '']),
      LEndToken.Position);
end;

{ TMathParserDefinitions }

constructor TMathParserDefinitions.Create;
begin
  inherited Create;

  FFunctions := TDictionary<string, TMathFunctionSpec>.Create;
  FBuiltInMacros := TDictionary<string, TMathMacro>.Create;

  RegisterFunctions;
  RegisterMacros;
end;

destructor TMathParserDefinitions.Destroy;
begin
  FBuiltInMacros.Free;
  FFunctions.Free;

  inherited Destroy;
end;

class destructor TMathParserDefinitions.ReleaseInstance;
begin
  FInstance.Free;
end;

class function TMathParserDefinitions.Instance: TMathParserDefinitions;
begin
  Result := FInstance;

  if Assigned(Result) then
    Exit;

  var LInstance := TMathParserDefinitions.Create;

  Result := TInterlocked.CompareExchange<TMathParserDefinitions>(FInstance, LInstance, nil);

  if Assigned(Result) then
    LInstance.Free
  else
    Result := LInstance;
end;

procedure TMathParserDefinitions.RegisterFunction(const ANames: array of string; const AKind: TMathFunctionKind; const ANumArgs: Integer;
  const AArgTypes: array of TMathArgType; const AAllowedInText: Boolean = False; const AAllowedInArgument: Boolean = False;
  const APrimitive: Boolean = False; const ANumOptionalArgs: Integer = 0; const AAllowedInMath: Boolean = True; const AInfix: Boolean = False);
var
  LSpec: TMathFunctionSpec;
begin
  LSpec.Kind := AKind;
  LSpec.NumArgs := ANumArgs;
  LSpec.NumOptionalArgs := ANumOptionalArgs;
  LSpec.AllowedInText := AAllowedInText;
  LSpec.AllowedInMath := AAllowedInMath;
  LSpec.AllowedInArgument := AAllowedInArgument;
  LSpec.Primitive := APrimitive;
  LSpec.Infix := AInfix;
  SetLength(LSpec.ArgTypes, Length(AArgTypes));

  for var LIndex := Low(AArgTypes) to High(AArgTypes) do
    LSpec.ArgTypes[LIndex] := AArgTypes[LIndex];

  for var LIndex := Low(ANames) to High(ANames) do
    FFunctions.AddOrSetValue(ANames[LIndex], LSpec);
end;

procedure TMathParserDefinitions.RegisterFunctions;
begin
  RegisterFunction(['\acute', '\grave', '\ddot', '\tilde', '\bar', '\breve', '\check', '\hat', '\vec', '\dot', '\mathring',
    '\widecheck', '\widehat', '\widetilde', '\overrightarrow', '\overleftarrow', '\Overrightarrow', '\overleftrightarrow',
    '\overgroup', '\overlinesegment', '\overleftharpoon', '\overrightharpoon'], fkAccent, 1, []);
  RegisterFunction(['\''', '\`', '\^', '\~', '\=', '\u', '\.', '\"', '\c', '\r', '\H', '\v', '\textcircled'], fkTextAccent, 1,
    [atPrimitive], True);
  RegisterFunction(['\textcolor'], fkTextColor, 2, [atColor, atOriginal], True);
  RegisterFunction(['\color'], fkColor, 1, [atColor], True);
  RegisterFunction(['\bigl', '\Bigl', '\biggl', '\Biggl', '\bigr', '\Bigr', '\biggr', '\Biggr', '\bigm', '\Bigm', '\biggm',
    '\Biggm', '\big', '\Big', '\bigg', '\Bigg'], fkDelimSizing, 1, [atPrimitive]);
  RegisterFunction(['\right'], fkRight, 1, [], False, False, True);
  RegisterFunction(['\left'], fkLeft, 1, [], False, False, True);
  RegisterFunction(['\middle'], fkMiddle, 1, [], False, False, True);
  RegisterFunction(['\mathrm', '\mathit', '\mathbf', '\mathnormal', '\mathsfit', '\mathbb', '\mathcal', '\mathfrak',
    '\mathscr', '\mathsf', '\mathtt', '\Bbb', '\bold', '\frak'], fkFont, 1, [], False, True);
  RegisterFunction(['\boldsymbol', '\bm'], fkBoldSymbol, 1, []);
  RegisterFunction(['\rm', '\sf', '\tt', '\bf', '\it', '\cal'], fkOldFont, 0, [], True);
  RegisterFunction(['\cfrac', '\dfrac', '\frac', '\tfrac', '\dbinom', '\binom', '\tbinom', '\\atopfrac', '\\bracefrac',
    '\\brackfrac'], fkGenFrac, 2, [], False, True);
  RegisterFunction(['\over', '\choose', '\atop', '\brace', '\brack'], fkInfix, 0, [], False, False, False, 0, True, True);
  RegisterFunction(['\genfrac'], fkGenFracGeneral, 6, [atMath, atMath, atSize, atText, atMath, atMath], False, True);
  RegisterFunction(['\above'], fkAboveInfix, 1, [atSize], False, False, False, 0, True, True);
  RegisterFunction(['\\abovefrac'], fkAboveFrac, 3, [atMath, atSize, atMath]);
  RegisterFunction(['\kern', '\mkern', '\hskip', '\mskip'], fkKern, 1, [atSize], True, False, True);
  RegisterFunction(['\mathllap', '\mathrlap', '\mathclap'], fkLap, 1, [], True);
  RegisterFunction(['\mathchoice'], fkMathChoice, 4, [], False, False, True);
  RegisterFunction(['\mathord', '\mathbin', '\mathrel', '\mathopen', '\mathclose', '\mathpunct', '\mathinner'], fkMClass, 1,
    [], False, False, True);
  RegisterFunction(['\@binrel'], fkBinRel, 2, []);
  RegisterFunction(['\stackrel', '\overset', '\underset'], fkStackRel, 2, []);
  RegisterFunction(['\coprod', '\bigvee', '\bigwedge', '\biguplus', '\bigcap', '\bigcup', '\intop', '\prod', '\sum',
    '\bigotimes', '\bigoplus', '\bigodot', '\bigsqcup', '\smallint', #$220F, #$2210, #$2211, #$22C0, #$22C1, #$22C2, #$22C3,
    #$2A00, #$2A01, #$2A02, #$2A04, #$2A06], fkOpSymbol, 0, []);
  RegisterFunction(['\mathop'], fkMathOp, 1, [], False, False, True);
  RegisterFunction(['\arcsin', '\arccos', '\arctan', '\arctg', '\arcctg', '\arg', '\ch', '\cos', '\cosec', '\cosh', '\cot',
    '\cotg', '\coth', '\csc', '\ctg', '\cth', '\deg', '\dim', '\exp', '\hom', '\ker', '\lg', '\ln', '\log', '\sec', '\sin',
    '\sinh', '\sh', '\tan', '\tanh', '\tg', '\th'], fkOpNoLimits, 0, []);
  RegisterFunction(['\det', '\gcd', '\inf', '\lim', '\max', '\min', '\Pr', '\sup'], fkOpLimits, 0, []);
  RegisterFunction(['\int', '\iint', '\iiint', '\oint', '\oiint', '\oiiint', #$222B, #$222C, #$222D, #$222E, #$222F, #$2230],
    fkOpIntegral, 0, [], False, True);
  RegisterFunction(['\operatorname@', '\operatornamewithlimits'], fkOperatorName, 1, []);
  RegisterFunction(['\overline'], fkOverline, 1, []);
  RegisterFunction(['\underline'], fkUnderline, 1, [], True);
  RegisterFunction(['\phantom'], fkPhantom, 1, [], True);
  RegisterFunction(['\vphantom'], fkVPhantom, 1, [], True);
  RegisterFunction(['\raisebox'], fkRaiseBox, 2, [atSize, atHBox], True);
  RegisterFunction(['\relax'], fkRelax, 0, [], True, True);
  RegisterFunction(['\rule'], fkRule, 2, [atSize, atSize, atSize], True, False, False, 1);
  RegisterFunction(['\tiny', '\sixptsize', '\scriptsize', '\footnotesize', '\small', '\normalsize', '\large', '\Large',
    '\LARGE', '\huge', '\Huge'], fkSizing, 0, [], True);
  RegisterFunction(['\smash'], fkSmash, 1, [], True, False, False, 1);
  RegisterFunction(['\sqrt'], fkSqrt, 1, [], False, False, False, 1);
  RegisterFunction(['\displaystyle', '\textstyle', '\scriptstyle', '\scriptscriptstyle'], fkStyling, 0, [], True, False, True);
  RegisterFunction(['\text', '\textrm', '\textsf', '\texttt', '\textnormal', '\textbf', '\textmd', '\textit', '\textup',
    '\emph'], fkText, 1, [atText], True, True);
  RegisterFunction(['\@char'], fkChar, 1, [], True);
  RegisterFunction(['\(', '$'], fkMathShift, 0, [], True, False, False, 0, False);
  RegisterFunction(['\)', '\]'], fkMismatchedMath, 0, [], True, False, False, 0, False);
  RegisterFunction(['\hbox'], fkHBox, 1, [atText], True, False, True);
  RegisterFunction(['\html@mathml'], fkHtmlMathMl, 2, [], True, True);
  RegisterFunction(['\begin', '\end'], fkEnvironment, 1, [atText]);
  RegisterFunction(['\\'], fkCr, 0, [], True);
  RegisterFunction(['\hline', '\hdashline'], fkHLine, 0, [], True);
  RegisterFunction(['\global', '\long', '\\globallong'], fkGlobal, 0, [], True);
  RegisterFunction(['\def', '\gdef', '\edef', '\xdef'], fkDefinition, 0, [], True, False, True);
  RegisterFunction(['\let', '\\globallet'], fkLet, 0, [], True, False, True);
  RegisterFunction(['\futurelet', '\\globalfuture'], fkFutureLet, 0, [], True, False, True);
  RegisterFunction(['\underleftarrow', '\underrightarrow', '\underleftrightarrow', '\undergroup', '\underlinesegment',
    '\utilde'], fkAccentUnder, 1, []);
  RegisterFunction(['\overbrace', '\underbrace', '\overbracket', '\underbracket'], fkHorizBrace, 1, []);
  RegisterFunction(['\xleftarrow', '\xrightarrow', '\xLeftarrow', '\xRightarrow', '\xleftrightarrow', '\xLeftrightarrow',
    '\xhookleftarrow', '\xhookrightarrow', '\xmapsto', '\xrightharpoondown', '\xrightharpoonup', '\xleftharpoondown',
    '\xleftharpoonup', '\xrightleftharpoons', '\xleftrightharpoons', '\xlongequal', '\xtwoheadrightarrow',
    '\xtwoheadleftarrow', '\xtofrom', '\xrightleftarrows', '\xrightequilibrium', '\xleftequilibrium', '\\cdrightarrow',
    '\\cdleftarrow', '\\cdlongequal'], fkXArrow, 1, [], False, False, False, 1);
  RegisterFunction(['\colorbox'], fkEnclose, 2, [atColor, atHBox], True);
  RegisterFunction(['\fcolorbox'], fkEnclose, 3, [atColor, atColor, atHBox], True);
  RegisterFunction(['\fbox'], fkEnclose, 1, [atHBox], True);
  RegisterFunction(['\cancel', '\bcancel', '\xcancel', '\phase'], fkEnclose, 1, []);
  RegisterFunction(['\sout'], fkEnclose, 1, [], True);
  RegisterFunction(['\angl'], fkEnclose, 1, [atHBox]);
  RegisterFunction(['\pmb'], fkPmb, 1, [], True);
  RegisterFunction(['\vcenter'], fkVCenter, 1, [atOriginal]);
  RegisterFunction(['\verb'], fkVerb, 0, [], True);
  RegisterFunction(['\reflectbox'], fkReflectBox, 1, [atHBox], True);
  RegisterFunction(['\mathreflectbox'], fkReflectBox, 1, [atMath]);
  RegisterFunction(['\\cdleft', '\\cdright'], fkCdLabel, 1, []);
  RegisterFunction(['\\cdparent'], fkCdLabelParent, 1, []);
end;

procedure TMathParserDefinitions.RegisterMacro(const AName: string; const AText: string);
begin
  var LMacro := Default(TMathMacro);

  LMacro.Kind := mkString;
  LMacro.Text := AText;

  FBuiltInMacros.AddOrSetValue(AName, LMacro);
end;

procedure TMathParserDefinitions.RegisterMacro(const AName: string; const ABuiltIn: TMathBuiltInMacro);
begin
  var LMacro := Default(TMathMacro);

  LMacro.Kind := mkBuiltIn;
  LMacro.BuiltIn := ABuiltIn;

  FBuiltInMacros.AddOrSetValue(AName, LMacro);
end;

procedure TMathParserDefinitions.RegisterMacros;
begin
  RegisterMacro('\@firstoftwo', bmFirstOfTwo);
  RegisterMacro('\@secondoftwo', bmSecondOfTwo);
  RegisterMacro('\@ifnextchar', bmIfNextChar);
  RegisterMacro('\@ifstar', '\@ifnextchar *{\@firstoftwo{#1}}');
  RegisterMacro('\TextOrMath', bmTextOrMath);
  RegisterMacro('\ce', bmChemistry);
  RegisterMacro('\pu', bmPhysicalUnit);
  RegisterMacro('\sideset', '\mathop{{\vphantom{#3}}#1#3\nolimits#2}\displaylimits');
  RegisterMacro('\char', bmChar);
  RegisterMacro('\newcommand', bmNewCommand);
  RegisterMacro('\renewcommand', bmRenewCommand);
  RegisterMacro('\providecommand', bmProvideCommand);
  RegisterMacro('\bgroup', '{');
  RegisterMacro('\egroup', '}');
  RegisterMacro('~', '\nobreakspace');
  RegisterMacro('\lq', '`');
  RegisterMacro('\rq', '''');
  RegisterMacro('\aa', '\r a');
  RegisterMacro('\AA', '\r A');
  RegisterMacro('\textcopyright', '\html@mathml{\textcircled{c}}{\char`'#$00A9'}');
  RegisterMacro('\copyright', '\TextOrMath{\textcopyright}{\text{\textcopyright}}');
  RegisterMacro('\textregistered', '\html@mathml{\textcircled{\scriptsize R}}{\char`'#$00AE'}');
  RegisterMacro(#$212C, '\mathscr{B}');
  RegisterMacro(#$2130, '\mathscr{E}');
  RegisterMacro(#$2131, '\mathscr{F}');
  RegisterMacro(#$210B, '\mathscr{H}');
  RegisterMacro(#$2110, '\mathscr{I}');
  RegisterMacro(#$2112, '\mathscr{L}');
  RegisterMacro(#$2133, '\mathscr{M}');
  RegisterMacro(#$211B, '\mathscr{R}');
  RegisterMacro(#$212D, '\mathfrak{C}');
  RegisterMacro(#$210C, '\mathfrak{H}');
  RegisterMacro(#$2128, '\mathfrak{Z}');
  RegisterMacro('\Bbbk', '\Bbb{k}');
  RegisterMacro('\llap', '\mathllap{\textrm{#1}}');
  RegisterMacro('\rlap', '\mathrlap{\textrm{#1}}');
  RegisterMacro('\clap', '\mathclap{\textrm{#1}}');
  RegisterMacro('\mathstrut', '\vphantom{(}');
  RegisterMacro('\underbar', '\underline{\text{#1}}');
  RegisterMacro('\not', '\html@mathml{\mathrel{\mathrlap\@not}\nobreak}{\char"338}');
  RegisterMacro('\neq', '\html@mathml{\mathrel{\not=}}{\mathrel{\char`'#$2260'}}');
  RegisterMacro('\ne', '\neq');
  RegisterMacro(#$2260, '\neq');
  RegisterMacro('\notin', '\html@mathml{\mathrel{{\in}\mathllap{/\mskip1mu}}}{\mathrel{\char`'#$2209'}}');
  RegisterMacro(#$2209, '\notin');
  RegisterMacro(#$2258, '\html@mathml{\mathrel{=\kern{-1em}\raisebox{0.4em}{$\scriptsize\frown$}}}{\mathrel{\char`'#$2258'}}');
  RegisterMacro(#$2259, '\html@mathml{\stackrel{\tiny\wedge}{=}}{\mathrel{\char`'#$2258'}}');
  RegisterMacro(#$225A, '\html@mathml{\stackrel{\tiny\vee}{=}}{\mathrel{\char`'#$225A'}}');
  RegisterMacro(#$225B, '\html@mathml{\stackrel{\scriptsize\star}{=}}{\mathrel{\char`'#$225B'}}');
  RegisterMacro(#$225D, '\html@mathml{\stackrel{\tiny\mathrm{def}}{=}}{\mathrel{\char`'#$225D'}}');
  RegisterMacro(#$225E, '\html@mathml{\stackrel{\tiny\mathrm{m}}{=}}{\mathrel{\char`'#$225E'}}');
  RegisterMacro(#$225F, '\html@mathml{\stackrel{\tiny?}{=}}{\mathrel{\char`'#$225F'}}');
  RegisterMacro(#$27C2, '\perp');
  RegisterMacro(#$203C, '\mathclose{!\mkern-0.8mu!}');
  RegisterMacro(#$220C, '\notni');
  RegisterMacro(#$231C, '\ulcorner');
  RegisterMacro(#$231D, '\urcorner');
  RegisterMacro(#$231E, '\llcorner');
  RegisterMacro(#$231F, '\lrcorner');
  RegisterMacro(#$00A9, '\copyright');
  RegisterMacro(#$00AE, '\textregistered');
  RegisterMacro('\ulcorner', '\html@mathml{\@ulcorner}{\mathop{\char"231c}}');
  RegisterMacro('\urcorner', '\html@mathml{\@urcorner}{\mathop{\char"231d}}');
  RegisterMacro('\llcorner', '\html@mathml{\@llcorner}{\mathop{\char"231e}}');
  RegisterMacro('\lrcorner', '\html@mathml{\@lrcorner}{\mathop{\char"231f}}');
  RegisterMacro('\vdots', '{\varvdots\rule{0pt}{15pt}}');
  RegisterMacro(#$22EE, '\vdots');
  RegisterMacro('\varGamma', '\mathit{\Gamma}');
  RegisterMacro('\varDelta', '\mathit{\Delta}');
  RegisterMacro('\varTheta', '\mathit{\Theta}');
  RegisterMacro('\varLambda', '\mathit{\Lambda}');
  RegisterMacro('\varXi', '\mathit{\Xi}');
  RegisterMacro('\varPi', '\mathit{\Pi}');
  RegisterMacro('\varSigma', '\mathit{\Sigma}');
  RegisterMacro('\varUpsilon', '\mathit{\Upsilon}');
  RegisterMacro('\varPhi', '\mathit{\Phi}');
  RegisterMacro('\varPsi', '\mathit{\Psi}');
  RegisterMacro('\varOmega', '\mathit{\Omega}');
  RegisterMacro('\colon', '\nobreak\mskip2mu\mathpunct{}\mathchoice{\mkern-3mu}{\mkern-3mu}{}{}{:}\mskip6mu\relax');
  RegisterMacro('\iff', '\DOTSB\;\Longleftrightarrow\;');
  RegisterMacro('\implies', '\DOTSB\;\Longrightarrow\;');
  RegisterMacro('\impliedby', '\DOTSB\;\Longleftarrow\;');
  RegisterMacro('\dddot', '{\overset{\raisebox{-0.1ex}{\normalsize ...}}{#1}}');
  RegisterMacro('\ddddot', '{\overset{\raisebox{-0.1ex}{\normalsize ....}}{#1}}');
  RegisterMacro('\dots', bmDots);
  RegisterMacro('\dotso', bmDotsO);
  RegisterMacro('\dotsc', bmDotsC);
  RegisterMacro('\cdots', bmCDots);
  RegisterMacro('\dotsb', '\cdots');
  RegisterMacro('\dotsm', '\cdots');
  RegisterMacro('\dotsi', '\!\cdots');
  RegisterMacro('\dotsx', '\ldots\,');
  RegisterMacro('\DOTSI', '\relax');
  RegisterMacro('\DOTSB', '\relax');
  RegisterMacro('\DOTSX', '\relax');
  RegisterMacro('\tmspace', '\TextOrMath{\kern#1#3}{\mskip#1#2}\relax');
  RegisterMacro('\,', '\tmspace+{3mu}{.1667em}');
  RegisterMacro('\thinspace', '\,');
  RegisterMacro('\>', '\mskip{4mu}');
  RegisterMacro('\:', '\tmspace+{4mu}{.2222em}');
  RegisterMacro('\medspace', '\:');
  RegisterMacro('\;', '\tmspace+{5mu}{.2777em}');
  RegisterMacro('\thickspace', '\;');
  RegisterMacro('\!', '\tmspace-{3mu}{.1667em}');
  RegisterMacro('\negthinspace', '\!');
  RegisterMacro('\negmedspace', '\tmspace-{4mu}{.2222em}');
  RegisterMacro('\negthickspace', '\tmspace-{5mu}{.277em}');
  RegisterMacro('\enspace', '\kern.5em ');
  RegisterMacro('\enskip', '\hskip.5em\relax');
  RegisterMacro('\quad', '\hskip1em\relax');
  RegisterMacro('\qquad', '\hskip2em\relax');
  RegisterMacro('\bmod', '\mathchoice{\mskip1mu}{\mskip1mu}{\mskip5mu}{\mskip5mu}\mathbin{\rm mod}' +
    '\mathchoice{\mskip1mu}{\mskip1mu}{\mskip5mu}{\mskip5mu}');
  RegisterMacro('\pod', '\allowbreak\mathchoice{\mkern18mu}{\mkern8mu}{\mkern8mu}{\mkern8mu}(#1)');
  RegisterMacro('\pmod', '\pod{{\rm mod}\mkern6mu#1}');
  RegisterMacro('\mod', '\allowbreak\mathchoice{\mkern18mu}{\mkern12mu}{\mkern12mu}{\mkern12mu}{\rm mod}\,\,#1');
  RegisterMacro('\TeX', '\textrm{\html@mathml{T\kern-.1667em\raisebox{-.5ex}{E}\kern-.125emX}{TeX}}');
  RegisterMacro('\LaTeX', '\textrm{\html@mathml{L\kern-.36em\raisebox{0.2156em}{\scriptstyle A}\kern-.15em\TeX}{LaTeX}}');
  RegisterMacro('\KaTeX', '\textrm{\html@mathml{K\kern-.17em\raisebox{0.2156em}{\scriptstyle A}\kern-.15em\TeX}{KaTeX}}');
  RegisterMacro('\hspace', '\@ifstar\@hspacer\@hspace');
  RegisterMacro('\@hspace', '\hskip #1\relax');
  RegisterMacro('\@hspacer', '\rule{0pt}{0pt}\hskip #1\relax');
  RegisterMacro('\ordinarycolon', ':');
  RegisterMacro('\vcentcolon', '\mathrel{\mathop\ordinarycolon}');
  RegisterMacro('\dblcolon', '\html@mathml{\mathrel{\vcentcolon\mathrel{\mkern-.9mu}\vcentcolon}}{\mathop{\char"2237}}');
  RegisterMacro('\coloneqq', '\html@mathml{\mathrel{\vcentcolon\mathrel{\mkern-1.2mu}=}}{\mathop{\char"2254}}');
  RegisterMacro('\Coloneqq', '\html@mathml{\mathrel{\dblcolon\mathrel{\mkern-1.2mu}=}}{\mathop{\char"2237\char"3d}}');
  RegisterMacro('\coloneq', '\html@mathml{\mathrel{\vcentcolon\mathrel{\mkern-1.2mu}\mathrel{-}}}{\mathop{\char"3a\char"2212}}');
  RegisterMacro('\Coloneq', '\html@mathml{\mathrel{\dblcolon\mathrel{\mkern-1.2mu}\mathrel{-}}}{\mathop{\char"2237\char"2212}}');
  RegisterMacro('\eqqcolon', '\html@mathml{\mathrel{=\mathrel{\mkern-1.2mu}\vcentcolon}}{\mathop{\char"2255}}');
  RegisterMacro('\Eqqcolon', '\html@mathml{\mathrel{=\mathrel{\mkern-1.2mu}\dblcolon}}{\mathop{\char"3d\char"2237}}');
  RegisterMacro('\eqcolon', '\html@mathml{\mathrel{\mathrel{-}\mathrel{\mkern-1.2mu}\vcentcolon}}{\mathop{\char"2239}}');
  RegisterMacro('\Eqcolon', '\html@mathml{\mathrel{\mathrel{-}\mathrel{\mkern-1.2mu}\dblcolon}}{\mathop{\char"2212\char"2237}}');
  RegisterMacro('\colonapprox', '\html@mathml{\mathrel{\vcentcolon\mathrel{\mkern-1.2mu}\approx}}{\mathop{\char"3a\char"2248}}');
  RegisterMacro('\Colonapprox', '\html@mathml{\mathrel{\dblcolon\mathrel{\mkern-1.2mu}\approx}}{\mathop{\char"2237\char"2248}}');
  RegisterMacro('\colonsim', '\html@mathml{\mathrel{\vcentcolon\mathrel{\mkern-1.2mu}\sim}}{\mathop{\char"3a\char"223c}}');
  RegisterMacro('\Colonsim', '\html@mathml{\mathrel{\dblcolon\mathrel{\mkern-1.2mu}\sim}}{\mathop{\char"2237\char"223c}}');
  RegisterMacro(#$2237, '\dblcolon');
  RegisterMacro(#$2239, '\eqcolon');
  RegisterMacro(#$2254, '\coloneqq');
  RegisterMacro(#$2255, '\eqqcolon');
  RegisterMacro(#$2A74, '\Coloneqq');
  RegisterMacro('\ratio', '\vcentcolon');
  RegisterMacro('\coloncolon', '\dblcolon');
  RegisterMacro('\colonequals', '\coloneqq');
  RegisterMacro('\coloncolonequals', '\Coloneqq');
  RegisterMacro('\equalscolon', '\eqqcolon');
  RegisterMacro('\equalscoloncolon', '\Eqqcolon');
  RegisterMacro('\colonminus', '\coloneq');
  RegisterMacro('\coloncolonminus', '\Coloneq');
  RegisterMacro('\minuscolon', '\eqcolon');
  RegisterMacro('\minuscoloncolon', '\Eqcolon');
  RegisterMacro('\coloncolonapprox', '\Colonapprox');
  RegisterMacro('\coloncolonsim', '\Colonsim');
  RegisterMacro('\simcolon', '\mathrel{\sim\mathrel{\mkern-1.2mu}\vcentcolon}');
  RegisterMacro('\simcoloncolon', '\mathrel{\sim\mathrel{\mkern-1.2mu}\dblcolon}');
  RegisterMacro('\approxcolon', '\mathrel{\approx\mathrel{\mkern-1.2mu}\vcentcolon}');
  RegisterMacro('\approxcoloncolon', '\mathrel{\approx\mathrel{\mkern-1.2mu}\dblcolon}');
  RegisterMacro('\notni', '\html@mathml{\not\ni}{\mathrel{\char`'#$220C'}}');
  RegisterMacro('\limsup', '\DOTSB\operatorname*{lim\,sup}');
  RegisterMacro('\liminf', '\DOTSB\operatorname*{lim\,inf}');
  RegisterMacro('\injlim', '\DOTSB\operatorname*{inj\,lim}');
  RegisterMacro('\projlim', '\DOTSB\operatorname*{proj\,lim}');
  RegisterMacro('\varlimsup', '\DOTSB\operatorname*{\overline{lim}}');
  RegisterMacro('\varliminf', '\DOTSB\operatorname*{\underline{lim}}');
  RegisterMacro('\gvertneqq', '\html@mathml{\@gvertneqq}{'#$2269'}');
  RegisterMacro('\lvertneqq', '\html@mathml{\@lvertneqq}{'#$2268'}');
  RegisterMacro('\ngeqq', '\html@mathml{\@ngeqq}{'#$2271'}');
  RegisterMacro('\ngeqslant', '\html@mathml{\@ngeqslant}{'#$2271'}');
  RegisterMacro('\nleqq', '\html@mathml{\@nleqq}{'#$2270'}');
  RegisterMacro('\nleqslant', '\html@mathml{\@nleqslant}{'#$2270'}');
  RegisterMacro('\nshortmid', '\html@mathml{\@nshortmid}{'#$2224'}');
  RegisterMacro('\nshortparallel', '\html@mathml{\@nshortparallel}{'#$2226'}');
  RegisterMacro('\nsubseteqq', '\html@mathml{\@nsubseteqq}{'#$2288'}');
  RegisterMacro('\nsupseteqq', '\html@mathml{\@nsupseteqq}{'#$2289'}');
  RegisterMacro('\varsubsetneq', '\html@mathml{\@varsubsetneq}{'#$228A'}');
  RegisterMacro('\varsubsetneqq', '\html@mathml{\@varsubsetneqq}{'#$2ACB'}');
  RegisterMacro('\varsupsetneq', '\html@mathml{\@varsupsetneq}{'#$228B'}');
  RegisterMacro('\varsupsetneqq', '\html@mathml{\@varsupsetneqq}{'#$2ACC'}');
  RegisterMacro('\imath', '\html@mathml{\@imath}{'#$0131'}');
  RegisterMacro('\jmath', '\html@mathml{\@jmath}{'#$0237'}');
  RegisterMacro('\llbracket', '\html@mathml{\mathopen{[\mkern-3.2mu[}}{\mathopen{\char`'#$27E6'}}');
  RegisterMacro('\rrbracket', '\html@mathml{\mathclose{]\mkern-3.2mu]}}{\mathclose{\char`'#$27E7'}}');
  RegisterMacro(#$27E6, '\llbracket');
  RegisterMacro(#$27E7, '\rrbracket');
  RegisterMacro('\lBrace', '\html@mathml{\mathopen{\{\mkern-3.2mu[}}{\mathopen{\char`'#$2983'}}');
  RegisterMacro('\rBrace', '\html@mathml{\mathclose{]\mkern-3.2mu\}}}{\mathclose{\char`'#$2984'}}');
  RegisterMacro(#$2983, '\lBrace');
  RegisterMacro(#$2984, '\rBrace');
  RegisterMacro('\minuso', '\mathbin{\html@mathml{{\mathrlap{\mathchoice{\kern{0.145em}}{\kern{0.145em}}{\kern{0.1015em}}' +
    '{\kern{0.0725em}}\circ}{-}}}{\char`'#$29B5'}}');
  RegisterMacro(#$29B5, '\minuso');
  RegisterMacro('\darr', '\downarrow');
  RegisterMacro('\dArr', '\Downarrow');
  RegisterMacro('\Darr', '\Downarrow');
  RegisterMacro('\lang', '\langle');
  RegisterMacro('\rang', '\rangle');
  RegisterMacro('\uarr', '\uparrow');
  RegisterMacro('\uArr', '\Uparrow');
  RegisterMacro('\Uarr', '\Uparrow');
  RegisterMacro('\N', '\mathbb{N}');
  RegisterMacro('\R', '\mathbb{R}');
  RegisterMacro('\Z', '\mathbb{Z}');
  RegisterMacro('\alef', '\aleph');
  RegisterMacro('\alefsym', '\aleph');
  RegisterMacro('\Alpha', '\mathrm{A}');
  RegisterMacro('\Beta', '\mathrm{B}');
  RegisterMacro('\bull', '\bullet');
  RegisterMacro('\Chi', '\mathrm{X}');
  RegisterMacro('\clubs', '\clubsuit');
  RegisterMacro('\cnums', '\mathbb{C}');
  RegisterMacro('\Complex', '\mathbb{C}');
  RegisterMacro('\Dagger', '\ddagger');
  RegisterMacro('\diamonds', '\diamondsuit');
  RegisterMacro('\empty', '\emptyset');
  RegisterMacro('\Epsilon', '\mathrm{E}');
  RegisterMacro('\Eta', '\mathrm{H}');
  RegisterMacro('\exist', '\exists');
  RegisterMacro('\harr', '\leftrightarrow');
  RegisterMacro('\hArr', '\Leftrightarrow');
  RegisterMacro('\Harr', '\Leftrightarrow');
  RegisterMacro('\hearts', '\heartsuit');
  RegisterMacro('\image', '\Im');
  RegisterMacro('\infin', '\infty');
  RegisterMacro('\Iota', '\mathrm{I}');
  RegisterMacro('\isin', '\in');
  RegisterMacro('\Kappa', '\mathrm{K}');
  RegisterMacro('\larr', '\leftarrow');
  RegisterMacro('\lArr', '\Leftarrow');
  RegisterMacro('\Larr', '\Leftarrow');
  RegisterMacro('\lrarr', '\leftrightarrow');
  RegisterMacro('\lrArr', '\Leftrightarrow');
  RegisterMacro('\Lrarr', '\Leftrightarrow');
  RegisterMacro('\Mu', '\mathrm{M}');
  RegisterMacro('\natnums', '\mathbb{N}');
  RegisterMacro('\Nu', '\mathrm{N}');
  RegisterMacro('\Omicron', '\mathrm{O}');
  RegisterMacro('\plusmn', '\pm');
  RegisterMacro('\rarr', '\rightarrow');
  RegisterMacro('\rArr', '\Rightarrow');
  RegisterMacro('\Rarr', '\Rightarrow');
  RegisterMacro('\real', '\Re');
  RegisterMacro('\reals', '\mathbb{R}');
  RegisterMacro('\Reals', '\mathbb{R}');
  RegisterMacro('\Rho', '\mathrm{P}');
  RegisterMacro('\sdot', '\cdot');
  RegisterMacro('\sect', '\S');
  RegisterMacro('\spades', '\spadesuit');
  RegisterMacro('\sub', '\subset');
  RegisterMacro('\sube', '\subseteq');
  RegisterMacro('\supe', '\supseteq');
  RegisterMacro('\Tau', '\mathrm{T}');
  RegisterMacro('\thetasym', '\vartheta');
  RegisterMacro('\weierp', '\wp');
  RegisterMacro('\Zeta', '\mathrm{Z}');
  RegisterMacro('\argmin', '\DOTSB\operatorname*{arg\,min}');
  RegisterMacro('\argmax', '\DOTSB\operatorname*{arg\,max}');
  RegisterMacro('\plim', '\DOTSB\mathop{\operatorname{plim}}\limits');
  RegisterMacro('\bra', '\mathinner{\langle{#1}|}');
  RegisterMacro('\ket', '\mathinner{|{#1}\rangle}');
  RegisterMacro('\braket', '\mathinner{\langle{#1}\rangle}');
  RegisterMacro('\Bra', '\left\langle#1\right|');
  RegisterMacro('\Ket', '\left|#1\right\rangle');
  RegisterMacro('\hphantom', '\smash{\phantom{#1}}');
  RegisterMacro('\newline', '\\\relax');
  RegisterMacro('\boxed', '\fbox{$\displaystyle{#1}$}');
  RegisterMacro('\substack', '\begin{subarray}{c}#1\end{subarray}');
  RegisterMacro('\tag', '\@ifstar\tag@literal\tag@paren');
  RegisterMacro('\tag@paren', '\tag@literal{({#1})}');
  RegisterMacro('\tag@literal', bmTagLiteral);
  RegisterMacro('\nonumber', '\gdef\@eqnsw{0}');
  RegisterMacro('\notag', '\nonumber');
  RegisterMacro('\varinjlim', '\DOTSB\operatorname*{\underrightarrow{lim}}');
  RegisterMacro('\varprojlim', '\DOTSB\operatorname*{\underleftarrow{lim}}');
  RegisterMacro('\angln', '{\angl n}');
  RegisterMacro('\operatorname', '\@ifstar\operatornamewithlimits\operatorname@');
end;

end.
