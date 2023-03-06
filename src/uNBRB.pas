unit uNBRB;

interface

uses
  Generics.Collections,
  REST.Json.Types;

type
  TCurrencyRate = class
    [JSONName('Cur_ID')]
    OID: Integer;
    [JSONName('Date')]
    Date: TDateTime;
    [JSONName('Cur_Abbreviation')]
    Code: string;
    [JSONName('Cur_Scale')]
    Quantity: Integer;
    [JSONName('Cur_Name')]
    Name: string;
    [JSONName('Cur_OfficialRate')]
    Rate: Currency;
  end;

  TRates = array of TCurrencyRate;

  TNBRBRates = class
  private
    fDate: TDateTime;
    fData: string;
    fItems: TObjectList<TCurrencyRate>;
    function GetItem(const aIndex: Integer): TCurrencyRate;
    function GetItemCount: Integer;
  protected
    procedure Clear;
    function GetUrl: RawByteString;
    procedure Serialize;
  public
    constructor Create(const aDate: TDateTime); virtual;
    destructor Destroy; override;

    procedure Execute;

    property Date: TDateTime read fDate;
    property Items[const aIndex: Integer]: TCurrencyRate read GetItem; default;
    property ItemCount: Integer read GetItemCount;
  end;

implementation

uses
  Classes, SysUtils, DateUtils, JSON, REST.Json,
  SynCrtSock,
  uCommon;

{ TNBRBRates }

procedure TNBRBRates.Clear;
begin
  fData := '';
  fItems.Clear;
end;

constructor TNBRBRates.Create(const aDate: TDateTime);
begin
  inherited Create;
  fDate := IncDay(aDate, 1{aNumberOfDays});
  fData := '';
  fItems := TObjectList<TCurrencyRate>.Create(True{aOwnsObjects});
end;

destructor TNBRBRates.Destroy;
begin
  Clear;
  FreeAndNil({var}fItems);
  inherited Destroy;
end;

procedure TNBRBRates.Execute;
var
  aResponse: TMemoryStream;
  aUrl, aRawData: RawByteString;
begin
  aUrl := GetUrl;

  try
    aResponse := TMemoryStream.Create;

    aRawData := RawByteString(TWinHTTP.Get(aUrl));

    aResponse.WriteBuffer({var}Pointer(aRawData)^, System.Length(aRawData));
    aResponse.SaveToFile(GetWorkPath + 'rates.json');

    fData := UTF8ToString(aRawData);
  finally
    FreeAndNil({var}aResponse);
  end;

  Serialize;
end;

function TNBRBRates.GetItem(const aIndex: Integer): TCurrencyRate;
begin
  Result := fItems[aIndex];
end;

function TNBRBRates.GetItemCount: Integer;
begin
  Result := fItems.Count;
end;

function TNBRBRates.GetUrl: RawByteString;
const
  cUrl = 'https://www.nbrb.by/api/exrates/rates?ondate=%d-%d-%d&periodicity=0';
var
  aYear, aMonth, aDay: Word;
begin
  aYear := 0;
  aMonth := 0;
  aDay := 0;

  DecodeDate(fDate, {var}aYear, {var}aMonth, {var}aDay);

  Result := RawByteString(Format(cUrl, [aYear, aMonth, aDay]));
end;

procedure TNBRBRates.Serialize;
var
  aRate: TCurrencyRate;
  aJsonArray: TJSONArray;
  aJsonValue: TJSonValue;
  aArrayElement: TJSonValue;
begin
  aJsonValue := TJSonObject.ParseJSONValue(fData);
  try
    aJsonArray := aJsonValue as TJSONArray;
    fItems.Capacity := SizeOf(IntPtr) * aJsonArray.Count;
    for aArrayElement in aJsonArray do
    begin
      aRate := TJSON.JsonToObject<TCurrencyRate>(aArrayElement.ToJSON);
      fItems.Add(aRate);
    end;
  finally
    FreeAndNil({var}aJsonValue);
  end;
end;

end.
