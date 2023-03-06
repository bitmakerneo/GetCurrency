unit ufrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmMain = class(TForm)
    btnGetCurrency: TButton;
    procedure btnGetCurrencyClick(Sender: TObject);
  private
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  uEngine, uCommon;

procedure TfrmMain.btnGetCurrencyClick(Sender: TObject);
var
  aResult: Boolean;
  aMessage: string;
begin
  AddLog('GetNewCurrencies...');

  aResult := GetNewCurrencies;

  aMessage := Format('GetNewCurrencies... %s', [BoolToStr(aResult, True{aUseBoolStrs})]);

  AddLog(aMessage);

  ShowMessage(aMessage);
end;

end.
