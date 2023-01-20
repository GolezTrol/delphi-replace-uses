program ReplaceUses;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Diagnostics,
  uReplacer in 'uReplacer.pas';


begin
  var s := TStopwatch.StartNew;

  var ini := ChangeFileExt(ParamStr(0), '.ini');
  var r := TReplacer.Create;
  r.Initialize(ini);
  r.Run();

  WriteLn('Done in ', s.ElapsedMilliseconds, 'ms.');

  WriteLn('Hit key');
  ReadLn;
end.

