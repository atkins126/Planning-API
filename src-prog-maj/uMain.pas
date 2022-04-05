unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, uPlanning,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.Layouts, FMX.ListView, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit;

type
  TfrmMain = class(TForm)
    EventsList: TListView;
    UserArray: TLayout;
    EventArray: TPanel;
    lblLabel: TLabel;
    edtLabel: TEdit;
    lblType: TLabel;
    edtType: TEdit;
    lblLanguage: TLabel;
    edtLanguage: TEdit;
    lblURL: TLabel;
    edtStartTime: TEdit;
    lblStartDate: TLabel;
    edtStopTime: TEdit;
    lblStartTime: TLabel;
    edtURL: TEdit;
    lblStoptime: TLabel;
    edtStartDate: TEdit;
    GridPanelLayout1: TGridPanelLayout;
    btnSave: TButton;
    btnCancel: TButton;
    ToolBar1: TToolBar;
    btnSaveToServer: TButton;
    btnAddEvent: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure EventsListItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure btnSaveToServerClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnAddEventClick(Sender: TObject);
  private
    FEditedEvent: tplanningevent;
    { D�clarations priv�es }
    procedure APIErrorEvent(HTTPStatusCode: integer; ErrorText: string);
    procedure APISaveErrorEvent(HTTPStatusCode: integer; ErrorText: string);
    procedure APIReadyEvent;
    procedure APIAfterSave;
    procedure SetEditedEvent(const Value: tplanningevent);
    procedure initEventListItem(item: TListViewItem; event: tplanningevent);
  public
    { D�clarations publiques }
    Planning: tplanning;
    property EditedEvent: tplanningevent read FEditedEvent write SetEditedEvent;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses uPlanningConsts;

procedure TfrmMain.APIAfterSave;
begin
  // TODO : � completer
  // TODO : d�bloquer champs de saisie une fois la fin de la sauvegarde
end;

procedure TfrmMain.APIErrorEvent(HTTPStatusCode: integer; ErrorText: string);
begin
  showmessage(HTTPStatusCode.ToString + ' - ' + ErrorText);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  EventArray.Visible := false;
  UserArray.enabled := false;
  EditedEvent := nil;
  Planning := tplanning.CreateFromURL(CPlanningServerURL, APIReadyEvent,
    APIErrorEvent);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  Planning.Free;
end;

procedure TfrmMain.initEventListItem(item: TListViewItem;
  event: tplanningevent);
begin
  item.Text := event.EventLabel;
  item.detail := event.EventType + ' | ' + event.EventStartDate + ' | ' +
    event.EventStarttime;
  item.Tagobject := event;
end;

procedure TfrmMain.SetEditedEvent(const Value: tplanningevent);
begin
  if assigned(FEditedEvent) then
  begin
    // TODO : Il existe d�j� un truc en ajout ou mise � jour, doit-on l'�craser ?
  end;

  FEditedEvent := Value;

  if assigned(FEditedEvent) then
  begin
    edtLabel.Text := FEditedEvent.EventLabel;
    edtType.Text := FEditedEvent.EventType;
    edtLanguage.Text := FEditedEvent.EventLanguage;
    edtURL.Text := FEditedEvent.EventURL;
    edtStartDate.Text := FEditedEvent.EventStartDate;
    edtStartTime.Text := FEditedEvent.EventStarttime;
    edtStopTime.Text := FEditedEvent.EventStopTime;
  end;
end;

procedure TfrmMain.APIReadyEvent;
var
  i: integer;
  item: TListViewItem;
begin
{$IFDEF DEBUG}
  showmessage('Chargement termin�. ' + Planning.Count.ToString +
    ' �v�nements dans le planning');
{$ENDIF}

  EventsList.Items.Clear;
  for i := 0 to Planning.Count - 1 do
    initEventListItem(EventsList.Items.Add, Planning[i]);

  UserArray.enabled := true;
end;

procedure TfrmMain.APISaveErrorEvent(HTTPStatusCode: integer;
  ErrorText: string);
begin
  APIErrorEvent(HTTPStatusCode, ErrorText);
  // TODO : d�bloquer champs de saisie une fois la fin de la sauvegarde
end;

procedure TfrmMain.btnAddEventClick(Sender: TObject);
begin
  EditedEvent := nil;

  edtLabel.Text := '';
  edtType.Text := '';
  edtLanguage.Text := '';
  edtURL.Text := '';
  edtStartDate.Text := '';
  edtStartTime.Text := '';
  edtStopTime.Text := '';

  EventArray.Visible := true;
end;

procedure TfrmMain.btnCancelClick(Sender: TObject);
begin
  EventArray.Visible := false;
  EditedEvent := nil;
end;

procedure TfrmMain.btnSaveClick(Sender: TObject);
var
  event: tplanningevent;
begin
  if assigned(EditedEvent) then
    event := EditedEvent
  else
    event := tplanningevent.CreateFromJSONObject(nil);

  event.EventLabel := edtLabel.Text;
  event.EventType := edtType.Text;
  event.EventLanguage := edtLanguage.Text;
  event.EventURL := edtURL.Text;
  event.EventStartDate := edtStartDate.Text;
  event.EventStarttime := edtStartTime.Text;
  event.EventStopTime := edtStopTime.Text;

  if assigned(EventsList.Selected) and (EventsList.Selected.Tagobject = event)
    and (EventsList.Selected is TListViewItem) then
    initEventListItem((EventsList.Selected as TListViewItem), event)
  else
    initEventListItem(EventsList.Items.Add, event);

  EventArray.Visible := false;
  EditedEvent := nil;
end;

procedure TfrmMain.btnSaveToServerClick(Sender: TObject);
begin
  Planning.onSaveError := APISaveErrorEvent;
  Planning.onAfterSave := APIAfterSave;
  // TODO : bloquer champs de saisie en attendant la fin de la sauvegarde
  Planning.Save;
end;

procedure TfrmMain.EventsListItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  if assigned(AItem) and assigned(AItem.Tagobject) and
    (AItem.Tagobject is tplanningevent) then
  begin
    EditedEvent := AItem.Tagobject as tplanningevent;
    EventArray.Visible := true;
  end;
end;

initialization

{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
{$ENDIF}

end.