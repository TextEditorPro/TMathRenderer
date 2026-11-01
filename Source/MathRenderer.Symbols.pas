unit MathRenderer.Symbols;

interface

uses
  MathRenderer.Types;

function FindSymbol(const AMode: TMathMode; const AName: string; out ASymbol: PMathSymbolDefinition): Boolean;
function FindUnicodeAccentCommand(const AAccent: string; const AMode: TMathMode; out ACommand: string): Boolean;
function FindUnicodeSymbol(const ACharacter: string; out ADecomposition: string): Boolean;
function IsExtraLatin(const ACharacter: string): Boolean;
function IsLigature(const AText: string): Boolean;
function IsSymbolDefined(const AName: string): Boolean;

implementation

uses
  System.Generics.Collections, System.SyncObjs, System.SysUtils, MathRenderer.SymbolData;

type
  TMathSymbolLookups = class(TObject)
  strict private
    FMathSymbols: TDictionary<string, Integer>;
    FTextSymbols: TDictionary<string, Integer>;
    FUnicodeSymbols: TDictionary<string, string>;
    class var FInstance: TMathSymbolLookups;
    class destructor ReleaseInstance;
  public
    constructor Create;
    destructor Destroy; override;
    class function Instance: TMathSymbolLookups;
    property MathSymbols: TDictionary<string, Integer> read FMathSymbols;
    property TextSymbols: TDictionary<string, Integer> read FTextSymbols;
    property UnicodeSymbols: TDictionary<string, string> read FUnicodeSymbols;
  end;

constructor TMathSymbolLookups.Create;
begin
  inherited Create;

  FMathSymbols := TDictionary<string, Integer>.Create(Length(MATH_SYMBOLS));

  for var LIndex := Low(MATH_SYMBOLS) to High(MATH_SYMBOLS) do
    FMathSymbols.AddOrSetValue(MATH_SYMBOLS[LIndex].Name, LIndex);

  FTextSymbols := TDictionary<string, Integer>.Create(Length(TEXT_SYMBOLS));

  for var LIndex := Low(TEXT_SYMBOLS) to High(TEXT_SYMBOLS) do
    FTextSymbols.AddOrSetValue(TEXT_SYMBOLS[LIndex].Name, LIndex);

  FUnicodeSymbols := TDictionary<string, string>.Create(Length(UNICODE_SYMBOLS));

  for var LIndex := Low(UNICODE_SYMBOLS) to High(UNICODE_SYMBOLS) do
    FUnicodeSymbols.AddOrSetValue(UNICODE_SYMBOLS[LIndex].Name, UNICODE_SYMBOLS[LIndex].Value);
end;

destructor TMathSymbolLookups.Destroy;
begin
  FMathSymbols.Free;
  FTextSymbols.Free;
  FUnicodeSymbols.Free;

  inherited Destroy;
end;

class destructor TMathSymbolLookups.ReleaseInstance;
begin
  FInstance.Free;
end;

class function TMathSymbolLookups.Instance: TMathSymbolLookups;
begin
  Result := FInstance;

  if Assigned(Result) then
    Exit;

  var LInstance := TMathSymbolLookups.Create;

  Result := TInterlocked.CompareExchange<TMathSymbolLookups>(FInstance, LInstance, nil);

  if Assigned(Result) then
    LInstance.Free
  else
    Result := LInstance;
end;

function FindSymbol(const AMode: TMathMode; const AName: string; out ASymbol: PMathSymbolDefinition): Boolean;
var
  LIndex: Integer;
begin
  ASymbol := nil;

  if AMode = mmMath then
  begin
    Result := TMathSymbolLookups.Instance.MathSymbols.TryGetValue(AName, LIndex);

    if Result then
      ASymbol := @MATH_SYMBOLS[LIndex];
  end
  else
  begin
    Result := TMathSymbolLookups.Instance.TextSymbols.TryGetValue(AName, LIndex);

    if Result then
      ASymbol := @TEXT_SYMBOLS[LIndex];
  end;
end;

function FindUnicodeAccentCommand(const AAccent: string; const AMode: TMathMode; out ACommand: string): Boolean;
begin
  ACommand := '';

  for var LIndex := Low(UNICODE_ACCENTS) to High(UNICODE_ACCENTS) do
  if UNICODE_ACCENTS[LIndex].Accent = AAccent then
  begin
    if AMode = mmMath then
      ACommand := UNICODE_ACCENTS[LIndex].MathCommand;

    if ACommand.IsEmpty then
      ACommand := UNICODE_ACCENTS[LIndex].TextCommand;

    Exit(not ACommand.IsEmpty);
  end;

  Result := False;
end;

function FindUnicodeSymbol(const ACharacter: string; out ADecomposition: string): Boolean;
begin
  Result := TMathSymbolLookups.Instance.UnicodeSymbols.TryGetValue(ACharacter, ADecomposition);
end;

function IsExtraLatin(const ACharacter: string): Boolean;
begin
  Result := (ACharacter.Length = 1) and (Pos(ACharacter, EXTRA_LATIN) > 0);
end;

function IsLigature(const AText: string): Boolean;
begin
  for var LIndex := Low(LIGATURES) to High(LIGATURES) do
  if LIGATURES[LIndex] = AText then
    Exit(True);

  Result := False;
end;

function IsSymbolDefined(const AName: string): Boolean;
begin
  Result := TMathSymbolLookups.Instance.MathSymbols.ContainsKey(AName) or TMathSymbolLookups.Instance.TextSymbols.ContainsKey(AName);
end;

end.
