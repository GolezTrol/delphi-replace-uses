unit uReplacer;

interface

uses
  System.SysUtils,
  System.IniFiles,
  System.Classes,
  System.RegularExpressions,
  System.IoUtils,
  System.Generics.Collections;

// Pattern for 3 groups, of which the second is the unit name.
const
  SearchTemplate = '(uses[^;]*(?:,|\s))({unit})((?:(?:,|\s)[^;]*)?;)';
  ReplaceTemplate = '\1{unit}\3';

type
  TReplaceConfig = record
    OldName: String;
    NewName: String;
    Pattern: String;
    Replace: String;
    RegEx: TRegEx;
  end;

  TReplacer = class
  private
    FFiles: TArray<string>;
    FRegexList: TDictionary<string, TReplaceConfig>;
  public
    constructor Create;
    procedure Initialize(AIniFile: String);
    procedure InitUses(AUses: TStrings);
    procedure InitFiles(ADirectories: TStrings; AHow: TSearchOption);
    procedure Run;
  end;

implementation

{ TReplacer }

constructor TReplacer.Create;
begin
  FRegexList := TDictionary<String, TReplaceConfig>.Create;
end;

procedure TReplacer.InitFiles(ADirectories: TStrings; AHow: TSearchOption);
begin
  for var d in ADirectories do
  begin
    FFiles := FFiles + TDirectory.GetFiles(d, '*.pas', AHow);
    FFiles := FFiles + TDirectory.GetFiles(d, '*.dpr', AHow);
  end;
end;

procedure TReplacer.Initialize(AIniFile: String);
begin
  WriteLn(AInifile);
  SetLength(FFiles, 0);
  FRegexList.Clear;

  var ini := TMemIniFile.Create(AIniFile);

  var f := TStringList.Create;
  ini.ReadSectionValues('TopLevel', f);
  InitFiles(f, TSearchOption.soTopDirectoryOnly);
  ini.ReadSectionValues('Recursive', f);
  InitFiles(f, TSearchOption.soAllDirectories);

  var u := TStringList.Create;
  ini.ReadSectionValues('Uses', u);
  InitUses(u);
end;

procedure TReplacer.InitUses(AUses: TStrings);
begin
  var config := default(TReplaceConfig);
  for var i := 0 to AUses.Count - 1 do
  try
    config := default(TReplaceConfig);
    config.OldName := AUses.Names[i];
    config.NewName := AUses.ValueFromIndex[i];
    config.Pattern := SearchTemplate.Replace('{unit}', config.OldName, []);
    config.Replace := ReplaceTemplate.Replace('{unit}', config.NewName, []);
    config.RegEx := TRegEx.Create(config.Pattern, [roIgnoreCase, roNotEmpty]);
    FRegexList.Add(config.OldName, config);
  except
    raise Exception.CreateFmt('Faal %s op %d', [config.OldName, i]);
  end;
end;

procedure TReplacer.Run;
var
  Buff: TBytes;
  Encoding: TEncoding;
  BOMLength: Integer;
begin
  Writeln(Length(FFiles), ' source files');
  Writeln(FRegexList.Count, ' patterns');
  for var k in FRegexList.Keys do
    WriteLn(FRegexList[k].Pattern, ' --> ', FRegexList[k].Replace);

  var i: Integer := 1;
  var fc: Integer := 0;
  for var fn in FFiles do
  begin
    Encoding := nil;
    Buff := TFile.ReadAllBytes(fn);
    BOMLength := TEncoding.GetBufferEncoding(Buff, Encoding);
    var o := Encoding.GetString(Buff, BOMLength, Length(Buff) - BOMLength);
    var s := o;

    for var c in FRegexList.Values do
    begin
      s := c.RegEx.Replace(s, c.Replace);
    end;

    if o <> s then
    begin
      TFile.WriteAllText(fn, s, Encoding);
      WriteLn(i, '/', Length(FFiles), '  ', fn);
      fc := 0
    end;
    Inc(i);
    Inc(fc);
    if (fc mod 100) = 0 then // Some feedback if no files were modified in a while
      WriteLn(i, '/', Length(FFiles), ' ...');
  end;
end;

end.

