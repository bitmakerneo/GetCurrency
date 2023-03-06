unit usrvMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs;

type
  TNBRBCurrencyService = class(TService)
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceBeforeUninstall(Sender: TService);
    procedure ServiceShutdown(Sender: TService);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure ServiceExecute(Sender: TService);
  private
  public
    constructor Create(aOwner: TComponent); override;

    function GetServiceController: TServiceController; override;
  end;

var
  gGetCurrencyService: TNBRBCurrencyService;

implementation

{$R *.dfm}

uses
  Registry,
  uEngine, uCommon;


resourcestring
  rsDescription = 'Загрузка официальных курсов валют Национального банка Республики Беларусь.';

const
  cRegistryKey = '\SYSTEM\CurrentControlSet\Services\';
  cRegistryValueName = 'Description';

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  gGetCurrencyService.Controller(CtrlCode);
end;

{ TNBRBCurrencyService }

constructor TNBRBCurrencyService.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
end;

function TNBRBCurrencyService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TNBRBCurrencyService.ServiceAfterInstall(Sender: TService);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);

  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey(cRegistryKey + Name, False{aCanCreate}) then
    begin
      Reg.WriteString(cRegistryValueName, rsDescription);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TNBRBCurrencyService.ServiceBeforeUninstall(Sender: TService);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);

  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey(cRegistryKey + Name, False{aCanCreate}) then
    begin
      Reg.DeleteValue(cRegistryValueName);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TNBRBCurrencyService.ServiceContinue(Sender: TService; var Continued: Boolean);
begin
  Continued := True;
  AddLog('ServiceContinue');
end;

procedure TNBRBCurrencyService.ServiceExecute(Sender: TService);
const
  cInterval = 1000 * 60 * 5;
var
  i: Integer;
begin
  AddLog('ServiceExecute...');

   while not Terminated do
   begin
     if GetNewCurrencies then
       Break;

    for i := 0 to cInterval - 1 do
    begin
     if Terminated then
       Break;

      TThread.Sleep(16);;
      ServiceThread.ProcessRequests(True{WaitForMessage});
    end;
  end;

  Status := csStopped;
  DoShutdown;

  AddLog('ServiceExecute... DONE');
end;

procedure TNBRBCurrencyService.ServicePause(Sender: TService; var Paused: Boolean);
begin
  AddLog('ServicePause');
  Paused := True;
end;

procedure TNBRBCurrencyService.ServiceShutdown(Sender: TService);
begin
  AddLog('ServiceShutdown');
end;

procedure TNBRBCurrencyService.ServiceStart(Sender: TService; var Started: Boolean);
begin
  AddLog('ServiceStart');
  Started := True;
end;

procedure TNBRBCurrencyService.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  AddLog('ServiceStop');
  Stopped := True;
end;

end.
