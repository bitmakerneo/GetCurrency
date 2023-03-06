unit uEngine;

interface

function GetNewCurrencies: Boolean;

implementation

uses
  Classes, SysUtils,
  Ora,
  uNBRB, uCommon;

procedure ExecuteSQL(const aSession: TOraSession; const aSql: string);
var
  aQuery: TOraQuery;
begin
  aQuery := TOraQuery.Create(nil{aOwner});
  try
    aQuery.Session := aSession;
    aQuery.SQL.Text := aSql;
    aQuery.Open;
  finally
    FreeAndNil({var}aQuery);
  end;
end;

procedure InsertSQL(const aSession: TOraSession; const aTableName: string; const aFieldNames: array of string; const aFieldValues: array of Variant);
const
  cInsertSql = ' INSERT INTO %s (%s) VALUES (%s) ';
var
  i: integer;
  aQuery: TOraQuery;
  aFields, aInFields, aSQLText: string;
begin
  aFields := '';
  aInFields := '';
  for i := Low(aFieldNames) to High(aFieldNames) do
  begin
    aFields := aFields + aFieldNames[i] + ', ';
    aInFields := aInFields + ':in_' + aFieldNames[i] + ', ';
  end;

  System.Delete({var}aFields, Length(aFields) - 1, 2);
  System.Delete({var}aInFields, Length(aInFields) - 1, 2);

  aQuery := TOraQuery.Create(nil{aOwner});
  try
    aQuery.Session := aSession;

    aSQLText := Format(cInsertSql, [aTableName, aFields, aInFields]);
    aQuery.SQL.Add(aSQLText);

    for i := Low(aFieldValues) to High(aFieldValues) do
      aQuery.Params[i].Value := aFieldValues[i];

    aQuery.ExecSQL;
  finally
    FreeAndNil({var}aQuery);
  end;
end;

procedure InsertXML(const aSession: TOraSession; const aDate: TDateTime);
var
  aOraSql: TOraStoredProc;
begin
  aOraSql := TOraStoredProc.Create(nil{aOwner});
  try
    aOraSql.Session := aSession;
    aOraSql.StoredProcName := 'IMPORT_CURS_XML';
    aOraSql.PrepareSQL;
    aOraSql.ParamByName('MATCH_DATE').AsDate := aDate;
    aOraSql.ExecProc;
  finally
    FreeAndNil({var}aOraSql);
  end;
end;

procedure CopyRates(const aSession: TOraSession);
var
  aOraSql: TOraStoredProc;
begin
  aOraSql := TOraStoredProc.Create(nil{aOwner});
  try
    aOraSql.Session := aSession;
    aOraSql.StoredProcName := 'COPY_DATA_TO_CURS_XML';
    aOraSql.ExecProc;
  finally
    FreeAndNil({var}aOraSql);
  end;
end;

function CheckAvailabilityOfExchangeRates(const aSession: TOraSession): Boolean;
var
  aDate: TDateTime;
  aQuery: TOraQuery;
begin
  AddLog('CheckAvailabilityOfExchangeRates... Start');

  aDate := cNullDate;
  aQuery := TOraQuery.Create(nil{aOwner});
  try
    aQuery.Session := aSession;
    aQuery.SQL.Text := 'SELECT CREATE_DATE FROM CURS_XML_NOW';
    try
      aQuery.Execute;
    except
      on E:Exception do
      begin
        AddLog('Message: %s', [E.Message]);
      end;
    end;
    if not aQuery.EOF then
    begin
      aDate := aQuery.FieldByName('CREATE_DATE').Value;
      AddLog('Found date: %s', [FormatDateTime('YYYY-MM-DD', aDate)]);
      Result := aDate < Trunc(Now);
    end
    else
      Result := True;
  finally
    FreeAndNil({var}aQuery);
  end;

  if Result and (aDate <> cNullDate) then
  begin
    ExecuteSQL(aSession, 'DELETE FROM CURS_XML_NOW');
  end;

  AddLog('CheckAvailabilityOfExchangeRates... %s', [BoolToStr(Result, True{aUseBoolStrs})]);
end;

procedure DoWork(const aSession: TOraSession);

  procedure _InitXml(const aData: TStrings; const aDate: TDateTime);
  begin
    aData.Add('<?xml version="1.0" encoding="UTF-8"?>');
    aData.Add('<DailyExRates>');
    aData.Add(Format(#9'<DateExRates>"%s"</DateExRates>', [FormatDateTime('DD.MM.YYYY', aDate)]));
  end;

  procedure _AppendXml(const aData: TStrings; const aRate: TCurrencyRate);
  begin
    aData.Add(Format(#9'<ExRateCurrency Id="%d">', [aRate.OID]));
    aData.Add(Format(#9#9'<ExRateCharCode>%s</ExRateCharCode>', [aRate.Code]));
    aData.Add(Format(#9#9'<ExRateScale>%d</ExRateScale>', [aRate.Quantity]));
    aData.Add(Format(#9#9'<ExRate>%.4f</ExRate>', [aRate.Rate]));
    aData.Add(#9'</ExRateCurrency>');
  end;

  procedure _FinishXml(const aData: TStrings);
  begin
    aData.Add('</DailyExRates>');
  end;

  procedure _InsertRate(const aRate: TCurrencyRate);
  begin
    InsertSQL(aSession, 'CURS_XML_NOW', ['CREATE_DATE','OID','CODE','NAME','RATE','QUANTITY'],
       [aRate.Date, aRate.OID, aRate.Code, aRate.Name, aRate.Rate, aRate.Quantity]);
  end;

var
  i: Integer;
  aXmlData: TStringList;
  aRates: TNBRBRates;
  aRate: TCurrencyRate;
begin
  aRates := TNBRBRates.Create(System.SysUtils.Now);
  try
    aRates.Execute;

    aXmlData := TStringList.Create;

    _InitXml(aXmlData, aRates.Date);

    if aRates.ItemCount > 0 then
    begin
      for i := 0 to aRates.ItemCount - 1 do
      begin
        aRate := aRates[i];
        _InsertRate(aRate);
        _AppendXml(aXmlData, aRate);
      end;
    end;

    _FinishXml(aXmlData);

    aXmlData.SaveToFile(GetRatesFileName, TEncoding.UTF8);
    InsertXML(aSession, aRates.Date);

    CopyRates(aSession);
  finally
    FreeAndNil({var}aXmlData);
    FreeAndNil({var}aRates);
  end;
end;

function GetNewCurrencies: Boolean;
var
  aSession: TOraSession;
begin
  AddLog('GetNewCurrencies... Start');
  Result := False;

  aSession := TOraSession.Create(nil{aOwner});
  try
    aSession.Options.Direct := True;
    aSession.ConnectString := GetConnectionUrl;
    AddLog('GetConnectionUrl: %s', [GetConnectionUrl]);
    try
      AddLog('Session.Connect... Start');
      aSession.Connect;
      if aSession.Connected then
      begin
        AddLog('Session.Connect... OK');

        if CheckAvailabilityOfExchangeRates(aSession) then
        begin
          Result := True;
          DoWork(aSession);
          aSession.Commit;
          AddLog('Session.Commit');
        end
        else
        begin
          AddLog('Session.Rollback');
          aSession.Rollback;
        end;
        aSession.Disconnect;
      end;
    except
    end;
  finally
    FreeAndNil({var}aSession);
  end;

  AddLog('GetNewCurrencies... %s', [BoolToStr(Result, True{aUseBoolStrs})]);
end;

end.
