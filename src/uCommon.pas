unit uCommon;

interface

const
  cNullDate: TDateTime = 0.0;

procedure AddLog(const aMessage: string); overload;
procedure AddLog(const aMessage: string; const aArgs: array of const); overload;

function GetWorkPath: string;
function GetConnectionUrl: string;
function GetRatesFileName: string;

implementation

uses
  Windows, SysUtils, IniFiles;

var
  gModuleFileName: string = '';
  gLogFileName: string = '';
  gWorkPath: string = '';
  gConnectionUrl: string = '';
  gOptionsFileName: string = '';
  gRatesFileName: string = '';
  aCriticalSection: TRTLCriticalSection;

function GetWorkPath: string;
begin
  Result := gWorkPath;
end;

function GetConnectionUrl: string;
var
  aIniFile: TIniFile;
begin
  Result := gConnectionUrl;
  if Result <> '' then
    Exit;

  aIniFile := TIniFile.Create(gOptionsFileName);
  try
    if aIniFile.SectionExists('main') then
    begin
      gConnectionUrl := aIniFile.ReadString('main', 'ConnectionUrl', ''{aDefault});
      Result := gConnectionUrl;
    end;
  finally
    FreeAndNil({var}aIniFile);
  end;
end;

function GetRatesFileName: string;
begin
  Result := gRatesFileName;
end;

procedure AddLog(const aMessage: string);
var
  F: TextFile;
begin
  EnterCriticalSection({var}aCriticalSection);
  try
    Assign({var}F, gLogFileName);

    if FileExists(gLogFileName) then
      Append({var}F)
    else
      Rewrite({var}F);

    try
      Writeln({var}F, FormatDateTime('YYYY-MM-DD hh:mm:ss.zzz', SysUtils.Now) + ':  ' + aMessage);
      Flush({var}F);
    finally
      Close({var}F);
    end;
  finally
    LeaveCriticalSection(aCriticalSection);
  end;
end;

procedure AddLog(const aMessage: string; const aArgs: array of const); overload;
begin
  AddLog(Format(aMessage, aArgs));
end;


procedure Init;
const
  cLogFileExtension = '.log';
  cOptionsFileExtension = '.ini';
  cRatesFileName = 'Rates.xml';
begin
  if gModuleFileName = '' then
    gModuleFileName := GetModuleName(HInstance);

  if gWorkPath = '' then
    gWorkPath := ExtractFilePath(gModuleFileName);

  if gLogFileName = '' then
    gLogFileName := ChangeFileExt(gModuleFileName, cLogFileExtension);

  if gOptionsFileName = '' then
    gOptionsFileName := ChangeFileExt(gModuleFileName, cOptionsFileExtension);

  if gRatesFileName = '' then
    gRatesFileName := gRatesFileName + cRatesFileName;

  InitializeCriticalSection(aCriticalSection);
end;

procedure Done;
begin
 DeleteCriticalSection(aCriticalSection);
end;

initialization
  Init;

finalization
  Done;

end.
