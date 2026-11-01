unit MathRenderer.Chemistry;

interface

function ChemistryToTeX(const AText: string): string;
function PhysicalUnitToTeX(const AText: string): string;

implementation

uses
  System.SysUtils;

type
  TChemistryArrow = record
    Command: string;
    Text: string;
  end;

const
  CHEMISTRY_ARROWS: array [0..6] of TChemistryArrow = (
    (Command: '\xrightleftarrows'; Text: '<-->'),
    (Command: '\xrightequilibrium'; Text: '<=>>'),
    (Command: '\xleftequilibrium'; Text: '<<=>'),
    (Command: '\xrightleftharpoons'; Text: '<=>'),
    (Command: '\xleftrightarrow'; Text: '<->'),
    (Command: '\xrightarrow'; Text: '->'),
    (Command: '\xleftarrow'; Text: '<-'));
  SCRIPT_BASE = '{\vphantom{A}}';

function IsDigit(const ACharacter: Char): Boolean;
begin
  Result := CharInSet(ACharacter, ['0'..'9']);
end;

function IsLetter(const ACharacter: Char): Boolean;
begin
  Result := CharInSet(ACharacter, ['a'..'z', 'A'..'Z']);
end;

function IsSpace(const ACharacter: Char): Boolean;
begin
  Result := CharInSet(ACharacter, [' ', #9, #10, #13]);
end;

function GroupEnd(const AText: string; const AIndex: Integer; const AOpen: Char; const AClose: Char): Integer;
begin
  if (AIndex > AText.Length) or (AText[AIndex] <> AOpen) then
    Exit(0);

  var LDepth := 0;

  for var LIndex := AIndex to AText.Length do
  if AText[LIndex] = AOpen then
    Inc(LDepth)
  else
  if AText[LIndex] = AClose then
  begin
    Dec(LDepth);

    if LDepth = 0 then
      Exit(LIndex + 1);
  end;

  Result := 0;
end;

function ReadScript(const AText: string; var AIndex: Integer): string;
begin
  if (AIndex <= AText.Length) and (AText[AIndex] = '{') then
  begin
    var LEnd := GroupEnd(AText, AIndex, '{', '}');

    if LEnd > 0 then
    begin
      Result := Copy(AText, AIndex + 1, LEnd - AIndex - 2);
      AIndex := LEnd;

      Exit;
    end;
  end;

  var LStart := AIndex;

  while (AIndex <= AText.Length) and (IsDigit(AText[AIndex]) or CharInSet(AText[AIndex], ['+', '-'])) do
    Inc(AIndex);

  Result := Copy(AText, LStart, AIndex - LStart);
end;

function UprightScript(const AScript: string): string;
begin
  for var LCharacter in AScript do
  if IsLetter(LCharacter) then
    Exit('\mathrm{' + AScript + '}');

  Result := AScript;
end;

function ChemistryToTeX(const AText: string): string;
var
  LBuilder: TStringBuilder;
  LHasBase: Boolean;
  LIndex: Integer;
  LLastWasScript: Boolean;
  LPreviousWasWord: Boolean;
  LSpaceBefore: Boolean;

  function SpaceAfter: Boolean;
  begin
    Result := (LIndex > AText.Length) or IsSpace(AText[LIndex]);
  end;

  procedure AppendWord(const ATeX: string);
  begin
    if LSpaceBefore and LPreviousWasWord then
      LBuilder.Append('\ ');

    LBuilder.Append(ATeX);
    LPreviousWasWord := True;
    LSpaceBefore := False;
  end;

  procedure AppendOperator(const ATeX: string);
  begin
    LBuilder.Append(' ').Append(ATeX).Append(' ');
    LHasBase := False;
    LLastWasScript := False;
    LPreviousWasWord := False;
    LSpaceBefore := False;
  end;

  procedure AppendScript(const AMark: Char; const AScript: string);
  begin
    if not LLastWasScript then
      LBuilder.Append(SCRIPT_BASE);

    if AMark = '_' then
      LBuilder.Append('_{\smash[t]{').Append(UprightScript(AScript)).Append('}}')
    else
      LBuilder.Append('^{').Append(UprightScript(AScript)).Append('}');

    LLastWasScript := True;
  end;

  function TryArrow: Boolean;
  begin
    for var LArrow in CHEMISTRY_ARROWS do
    if Copy(AText, LIndex, LArrow.Text.Length) = LArrow.Text then
    begin
      Inc(LIndex, LArrow.Text.Length);

      var LAbove := '';
      var LBelow := '';
      var LEnd := GroupEnd(AText, LIndex, '[', ']');

      if LEnd > 0 then
      begin
        LAbove := ChemistryToTeX(Copy(AText, LIndex + 1, LEnd - LIndex - 2));
        LIndex := LEnd;
        LEnd := GroupEnd(AText, LIndex, '[', ']');

        if LEnd > 0 then
        begin
          LBelow := ChemistryToTeX(Copy(AText, LIndex + 1, LEnd - LIndex - 2));
          LIndex := LEnd;
        end;
      end;

      AppendOperator(LArrow.Command + (if LBelow.IsEmpty then '' else '[' + LBelow + ']') + '{' + LAbove + '}');

      Exit(True);
    end;

    Result := False;
  end;

begin
  LBuilder := TStringBuilder.Create;
  try
    LIndex := 1;
    LHasBase := False;
    LLastWasScript := False;
    LPreviousWasWord := False;
    LSpaceBefore := False;

    while LIndex <= AText.Length do
    begin
      var LCharacter := AText[LIndex];

      if IsSpace(LCharacter) then
      begin
        LSpaceBefore := True;
        LHasBase := False;
        LLastWasScript := False;
        Inc(LIndex);

        Continue;
      end;

      if TryArrow then
        Continue;

      var LStart := LIndex;

      Inc(LIndex);

      case LCharacter of
        '+', '-':
          if LHasBase and not LSpaceBefore and ((LCharacter = '+') or SpaceAfter or CharInSet(AText[LIndex], [')', ']'])) then
            AppendScript('^', LCharacter)
          else
          if LHasBase and not LSpaceBefore then
          begin
            LBuilder.Append('{-}');
            LHasBase := False;
            LLastWasScript := False;
          end
          else
            AppendOperator(LCharacter);
        '=':
          if LHasBase and not LSpaceBefore then
          begin
            LBuilder.Append('{=}');
            LHasBase := False;
            LLastWasScript := False;
          end
          else
            AppendOperator('=');
        '#':
          begin
            LBuilder.Append('{\equiv}');
            LHasBase := False;
            LLastWasScript := False;
          end;
        '^', '_':
          if (LCharacter = '^') and (LSpaceBefore or not LHasBase) and SpaceAfter then
            AppendOperator('\uparrow{}')
          else
          if LHasBase then
            AppendScript(LCharacter, ReadScript(AText, LIndex))
          else
          begin
            if LSpaceBefore and LPreviousWasWord then
              LBuilder.Append('\ ');

            LBuilder.Append('{}').Append(LCharacter).Append('{').Append(ReadScript(AText, LIndex)).Append('}');

            if (LIndex <= AText.Length) and CharInSet(AText[LIndex], ['^', '_']) and (AText[LIndex] <> LCharacter) then
            begin
              LBuilder.Append(AText[LIndex]);
              Inc(LIndex);
              LBuilder.Append('{').Append(ReadScript(AText, LIndex)).Append('}');
            end;

            LSpaceBefore := False;
          end;
        '0'..'9':
          if LHasBase then
          begin
            while (LIndex <= AText.Length) and IsDigit(AText[LIndex]) do
              Inc(LIndex);

            AppendScript('_', Copy(AText, LStart, LIndex - LStart));
          end
          else
          begin
            while (LIndex <= AText.Length) and (IsDigit(AText[LIndex]) or
              (CharInSet(AText[LIndex], ['.', '/']) and (LIndex < AText.Length) and IsDigit(AText[LIndex + 1]))) do
              Inc(LIndex);

            AppendWord(Copy(AText, LStart, LIndex - LStart));
          end;
        'a'..'z', 'A'..'Z':
          begin
            while (LIndex <= AText.Length) and IsLetter(AText[LIndex]) do
              Inc(LIndex);

            var LWord := Copy(AText, LStart, LIndex - LStart);

            if (LWord = 'v') and (LSpaceBefore or not LHasBase) and SpaceAfter then
              AppendOperator('\downarrow{}')
            else
            begin
              AppendWord('\mathrm{' + LWord + '}');
              LHasBase := True;
              LLastWasScript := False;
            end;
          end;
        '(', '[':
          begin
            AppendWord(LCharacter);
            LHasBase := False;
            LLastWasScript := False;
            LPreviousWasWord := False;
          end;
        ')', ']':
          begin
            LBuilder.Append(LCharacter);
            LHasBase := True;
            LLastWasScript := False;
          end;
        '*', '.':
          AppendOperator('\cdot');
        '{':
          begin
            var LEnd := GroupEnd(AText, LStart, '{', '}');

            if LEnd = 0 then
              LEnd := AText.Length + 1;

            AppendWord('{' + ChemistryToTeX(Copy(AText, LStart + 1, LEnd - LStart - 2)) + '}');
            LIndex := LEnd;
            LHasBase := True;
            LLastWasScript := False;
          end;
        '$':
          begin
            var LEnd := Pos('$', AText, LIndex);

            if LEnd = 0 then
              LEnd := AText.Length + 1;

            AppendWord('{' + Copy(AText, LIndex, LEnd - LIndex) + '}');
            LIndex := LEnd + 1;
            LHasBase := True;
            LLastWasScript := False;
          end;
        '\':
          begin
            while (LIndex <= AText.Length) and IsLetter(AText[LIndex]) do
              Inc(LIndex);

            if LIndex = LStart + 1 then
              Inc(LIndex);

            AppendWord(Copy(AText, LStart, LIndex - LStart) + ' ');
            LHasBase := True;
            LLastWasScript := False;
          end;
      else
        begin
          AppendWord(LCharacter);
          LHasBase := False;
          LLastWasScript := False;
        end;
      end;
    end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function PhysicalUnitToTeX(const AText: string): string;
var
  LBuilder: TStringBuilder;
  LIndex: Integer;
begin
  LBuilder := TStringBuilder.Create;
  try
    var LText := AText.Trim;

    LIndex := 1;

    while (LIndex <= LText.Length) and (IsDigit(LText[LIndex]) or CharInSet(LText[LIndex], ['.', ',', '+', '-'])) do
      Inc(LIndex);

    LBuilder.Append(Copy(LText, 1, LIndex - 1).Replace('+-', '\pm '));

    if (LIndex < LText.Length) and CharInSet(LText[LIndex], ['e', 'E']) and
      (IsDigit(LText[LIndex + 1]) or CharInSet(LText[LIndex + 1], ['+', '-'])) then
    begin
      var LStart := LIndex + 1;

      Inc(LIndex, 2);

      while (LIndex <= LText.Length) and IsDigit(LText[LIndex]) do
        Inc(LIndex);

      LBuilder.Append('\cdot 10^{').Append(Copy(LText, LStart, LIndex - LStart)).Append('}');
    end;

    if (LIndex > 1) and (LIndex <= LText.Length) then
      LBuilder.Append('~');

    var LUnitBefore := False;

    while LIndex <= LText.Length do
    begin
      var LCharacter := LText[LIndex];
      var LStart := LIndex;

      Inc(LIndex);

      case LCharacter of
        ' ', #9:
          begin
            while (LIndex <= LText.Length) and CharInSet(LText[LIndex], [' ', #9]) do
              Inc(LIndex);

            if LUnitBefore and (LIndex <= LText.Length) then
              LBuilder.Append('\,');

            LUnitBefore := False;
          end;
        'a'..'z', 'A'..'Z', '\':
          begin
            while (LIndex <= LText.Length) and IsLetter(LText[LIndex]) do
              Inc(LIndex);

            var LUnit := Copy(LText, LStart, LIndex - LStart);

            LBuilder.Append(if LCharacter = '\' then LUnit + ' ' else '\mathrm{' + LUnit + '}');

            if (LIndex <= LText.Length) and (LText[LIndex] = '^') then
            begin
              Inc(LIndex);
              LBuilder.Append('^{').Append(ReadScript(LText, LIndex)).Append('}');
            end
            else
            if (LIndex <= LText.Length) and (IsDigit(LText[LIndex]) or (LText[LIndex] = '-')) then
              LBuilder.Append('^{').Append(ReadScript(LText, LIndex)).Append('}');

            LUnitBefore := True;
          end;
        '*', '.':
          begin
            LBuilder.Append('\cdot ');
            LUnitBefore := False;
          end;
      else
        begin
          LBuilder.Append(LCharacter);
          LUnitBefore := False;
        end;
      end;
    end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

end.
