program TestGetCurrency;

uses
  Vcl.Forms,
  ufrmMain in 'ufrmMain.pas' {frmMain},
  uNBRB in '..\src\uNBRB.pas',
  uCommon in '..\src\uCommon.pas',
  uEngine in '..\src\uEngine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
