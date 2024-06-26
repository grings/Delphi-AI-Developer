unit DelphiAIDev.Chat.View;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.StrUtils,
  System.Variants,
  System.Classes,
  System.JSON,
  System.Threading,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  System.ImageList,
  Vcl.ImgList,
  DockForm,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.Menus,
  Vcl.Buttons,
  Clipbrd,
  DelphiAIDev.Types,
  DelphiAIDev.Consts,
  DelphiAIDev.Chat,
  DelphiAIDev.Settings,
  DelphiAIDev.ModuleCreator;

type
  TDelphiAIDevChatView = class(TDockableForm)
    ImageList1: TImageList;
    pMenuMemoReturn: TPopupMenu;
    Cut1: TMenuItem;
    Copy1: TMenuItem;
    Paste1: TMenuItem;
    SelectAll1: TMenuItem;
    pnBack: TPanel;
    pnBackQuestion: TPanel;
    mmQuestion: TMemo;
    N1: TMenuItem;
    mmReturn: TRichEdit;
    Splitter1: TSplitter;
    pnWait: TPanel;
    ShapeWait: TShape;
    pnWaitCaption: TPanel;
    pMenuCurrentAI: TPopupMenu;
    Gemini1: TMenuItem;
    ChatGPT1: TMenuItem;
    pnBackStatusBar: TPanel;
    lbCurrentAI: TLabel;
    StatusBar1: TStatusBar;
    pnCommands: TPanel;
    btnCopy: TSpeedButton;
    btnInsertAtCursor: TSpeedButton;
    btnMoreActions: TSpeedButton;
    ShapeCommands: TShape;
    btnSend: TButton;
    pMenuMoreActions: TPopupMenu;
    SaveContentToFile1: TMenuItem;
    btnCreateNewUnit: TSpeedButton;
    ClearContent1: TMenuItem;
    Clear1: TMenuItem;
    N2: TMenuItem;
    WordWrap1: TMenuItem;
    pnBackConfigurableButtons: TPanel;
    btnUseCurrentUnitCode: TButton;
    btnCodeOnly: TButton;
    btnDefaultsQuestions: TButton;
    pMenuQuestions: TPopupMenu;
    procedure FormShow(Sender: TObject);
    procedure cBoxSizeFontKeyPress(Sender: TObject; var Key: Char);
    procedure Cut1Click(Sender: TObject);
    procedure Copy1Click(Sender: TObject);
    procedure Paste1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSendClick(Sender: TObject);
    procedure mmQuestionKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCopyClick(Sender: TObject);
    procedure btnInsertAtCursorClick(Sender: TObject);
    procedure SelectAll1Click(Sender: TObject);
    procedure mmQuestionChange(Sender: TObject);
    procedure mmQuestionKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure lbCurrentAIClick(Sender: TObject);
    procedure Gemini1Click(Sender: TObject);
    procedure pMenuCurrentAIPopup(Sender: TObject);
    procedure btnMoreActionsClick(Sender: TObject);
    procedure SaveContentToFile1Click(Sender: TObject);
    procedure btnCreateNewUnitClick(Sender: TObject);
    procedure ClearContent1Click(Sender: TObject);
    procedure btnUseCurrentUnitCodeClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure WordWrap1Click(Sender: TObject);
    procedure btnCodeOnlyClick(Sender: TObject);
    procedure btnDefaultsQuestionsClick(Sender: TObject);
  private
    FChat: TDelphiAIDevChat;
    FSettings: TDelphiAIDevSettings;
    LbtnUseCurrentUnitCodeWidth: Integer;
    LbtnCodeOnlyWidth: Integer;
    procedure ReadFromFile;
    procedure WriteToFile;
    procedure InitializeRichEditReturn;
    procedure ProcessSend;
    procedure AddResponseSimple(const AString: string);
    procedure AddResponseComplete(const AStrings: TStrings);
    procedure AddResponseLine(const ALineStr: string);
    procedure Last;
    function GetSelectedTextOrAllFromReturn: string;
    function GetSelectedTextOrAllOrAbort: string;
    procedure WaitingFormOFF;
    procedure WaitingFormON;
    procedure ConfLabelCurrentAI;
    procedure ConfScreenOnShow;
    procedure ChangeUseCurrentUnitCode;
    procedure ChangeCodeOnly;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  DelphiAIDevChatView: TDelphiAIDevChatView;

procedure RegisterSelf;
procedure Unregister;
procedure DelphiAIDevChatViewShowDockableForm;

implementation

uses
  DeskUtil,
  DelphiAIDev.Utils,
  DelphiAIDev.Utils.OTA;

{$R *.dfm}

procedure RegisterSelf;
begin
  if(not Assigned(DelphiAIDevChatView))then
    DelphiAIDevChatView := TDelphiAIDevChatView.Create(nil);

  if(@RegisterFieldAddress <> nil)then
    RegisterFieldAddress(DelphiAIDevChatView.Name, @DelphiAIDevChatView);

  RegisterDesktopFormClass(TDelphiAIDevChatView, DelphiAIDevChatView.Name, DelphiAIDevChatView.Name);
end;

procedure Unregister;
begin
  if(@UnRegisterFieldAddress <> nil)then
    UnRegisterFieldAddress(@DelphiAIDevChatView);
  FreeAndNil(DelphiAIDevChatView);
end;

procedure DelphiAIDevChatViewShowDockableForm;
begin
  ShowDockableForm(DelphiAIDevChatView);
  FocusWindow(DelphiAIDevChatView);
end;

constructor TDelphiAIDevChatView.Create(AOwner: TComponent);
begin
  inherited;
  DeskSection := Self.Name;
  AutoSave := True;
  SaveStateNecessary := True;

  FChat := TDelphiAIDevChat.Create;
  FSettings := FChat.Settings.GetInstance;
  pnWait.Visible := False;
  LbtnUseCurrentUnitCodeWidth := btnUseCurrentUnitCode.Width;
  LbtnCodeOnlyWidth := btnCodeOnly.Width;
end;

destructor TDelphiAIDevChatView.Destroy;
begin
  FChat.Free;
  inherited;
end;

procedure TDelphiAIDevChatView.FormShow(Sender: TObject);
begin
  Self.ConfScreenOnShow;
  Self.InitializeRichEditReturn;
  Self.ReadFromFile;
  //Self.GetSelectedBlockForQuestion;

  TUtils.MemoFocusOnTheEnd(mmQuestion);
end;
procedure TDelphiAIDevChatView.ConfScreenOnShow;
begin
  TUtilsOTA.IDEThemingAll(TDelphiAIDevChatView, Self);
  Self.Constraints.MinWidth := 150;
  Self.Constraints.MinHeight := 150;

  btnMoreActions.Font.Color := TUtilsOTA.ActiveThemeColorDefault;

  ShapeCommands.Left := 0;
  ShapeCommands.Top := 0;
  ShapeCommands.Width := ShapeCommands.Parent.Width;
  ShapeCommands.Height := ShapeCommands.Parent.Height;
end;

procedure TDelphiAIDevChatView.FormActivate(Sender: TObject);
begin
  Self.ConfLabelCurrentAI;
end;

procedure TDelphiAIDevChatView.mmQuestionChange(Sender: TObject);
begin
  if mmQuestion.Lines.Count >= 7 then
    mmQuestion.ScrollBars := ssVertical
  else
    mmQuestion.ScrollBars := ssNone;
end;

procedure TDelphiAIDevChatView.mmQuestionKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift)and(Key = VK_RETURN) then
  begin
    btnSend.Click;
    Key := 0;
  end
end;

procedure TDelphiAIDevChatView.mmQuestionKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift)and(Key = 65)then
  begin
    mmQuestion.SelectAll;
    Key := 0;
  end;
end;

procedure TDelphiAIDevChatView.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Self.WriteToFile;
  Self.WaitingFormOFF;
end;

procedure TDelphiAIDevChatView.FormResize(Sender: TObject);
const
  CAPTION_UseCurrentUnitCode = 'Use current unit code in query';
  CAPTION_CodeOnly = 'Code only';
begin
  if(Self.Width > 530)then
  begin
    btnUseCurrentUnitCode.Caption := CAPTION_UseCurrentUnitCode;
    btnUseCurrentUnitCode.Width := LbtnUseCurrentUnitCodeWidth;
    btnUseCurrentUnitCode.ImageAlignment := TImageAlignment.iaLeft;

    btnCodeOnly.Caption := CAPTION_CodeOnly;
    btnCodeOnly.Width := LbtnCodeOnlyWidth;
    btnCodeOnly.ImageAlignment := TImageAlignment.iaLeft;
  end
  else
  begin
    btnUseCurrentUnitCode.Caption := '';
    btnUseCurrentUnitCode.Width := btnSend.Width;
    btnUseCurrentUnitCode.ImageAlignment := TImageAlignment.iaCenter;

    btnCodeOnly.Caption := '';
    btnCodeOnly.Width := btnSend.Width;
    btnCodeOnly.ImageAlignment := TImageAlignment.iaCenter;
  end;
end;

procedure TDelphiAIDevChatView.ReadFromFile;
begin
  if(FileExists(TUtils.GetPathFileChat))then
    mmReturn.Lines.LoadFromFile(TUtils.GetPathFileChat)
end;

procedure TDelphiAIDevChatView.SelectAll1Click(Sender: TObject);
begin
  mmReturn.SelectAll;
end;

procedure TDelphiAIDevChatView.WriteToFile;
begin
  mmReturn.Lines.SaveToFile(TUtils.GetPathFileChat);
end;

procedure TDelphiAIDevChatView.cBoxSizeFontKeyPress(Sender: TObject; var Key: Char);
begin
  if not(CharInSet(Key, ['0'..'9', #8]))then
    Key := #0;
end;

procedure TDelphiAIDevChatView.Cut1Click(Sender: TObject);
begin
  mmReturn.CutToClipboard;
end;

procedure TDelphiAIDevChatView.Copy1Click(Sender: TObject);
begin
  mmReturn.CopyToClipboard;
end;

procedure TDelphiAIDevChatView.Paste1Click(Sender: TObject);
begin
  mmReturn.PasteFromClipboard;
end;

procedure TDelphiAIDevChatView.btnUseCurrentUnitCodeClick(Sender: TObject);
begin
  Self.ChangeUseCurrentUnitCode;
end;

procedure TDelphiAIDevChatView.btnDefaultsQuestionsClick(Sender: TObject);
begin
  pMenuQuestions.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TDelphiAIDevChatView.ChangeUseCurrentUnitCode;
begin
  if btnUseCurrentUnitCode.ImageIndex = 0 then
    btnUseCurrentUnitCode.ImageIndex := 1
  else
    btnUseCurrentUnitCode.ImageIndex := 0;
end;

procedure TDelphiAIDevChatView.btnCodeOnlyClick(Sender: TObject);
begin
  Self.ChangeCodeOnly;
end;

procedure TDelphiAIDevChatView.ChangeCodeOnly;
begin
  if btnCodeOnly.ImageIndex = 2 then
    btnCodeOnly.ImageIndex := 3
  else
    btnCodeOnly.ImageIndex := 2;
end;

procedure TDelphiAIDevChatView.btnSendClick(Sender: TObject);
begin
  Self.ProcessSend;
end;

procedure TDelphiAIDevChatView.ProcessSend;
var
  LTask: ITask;
  LQuestion: string;
begin
  if mmQuestion.Lines.Text.Trim.IsEmpty then
    TUtils.ShowMsgAndAbort('No questions have been added', mmQuestion);

  mmReturn.Lines.Clear;
  Self.WaitingFormON;

  LQuestion := '';

  if btnUseCurrentUnitCode.ImageIndex = 1 then
    LQuestion := TUtilsOTA.GetSelectedBlockOrAllCodeUnit.Trim + sLineBreak;

  if btnCodeOnly.ImageIndex = 3 then
    LQuestion := LQuestion + 'Fa�a a seguinte a��o sem adicionar coment�rios: ' + sLineBreak;

  LQuestion := LQuestion + mmQuestion.Lines.Text;

  LTask := TTask.Create(
    procedure
    begin
      try
        try
          FChat.ProcessSend(LQuestion);
        except
          on E: Exception do
            TThread.Synchronize(nil,
              procedure
              begin
                Self.AddResponseSimple('Unable to perform processing.' + sLineBreak + E.Message);
                Abort;
              end);
        end;

        TThread.Synchronize(nil,
          procedure
          begin
            mmReturn.Lines.BeginUpdate;
            try
              //Optional use of one of the following lines
              Self.AddResponseComplete(FChat.Response);
              //Self.AddResponseSimple(FChat.Response.Text);
            finally
              mmReturn.Lines.EndUpdate;
            end;
          end);
      finally
        TThread.Synchronize(nil,
          procedure
          begin
            Self.WaitingFormOFF;
          end);
      end;
    end);
  LTask.Start;
end;

procedure TDelphiAIDevChatView.AddResponseSimple(const AString: string);
begin
  Self.Last;
  mmReturn.SelAttributes.Color := TUtilsOTA.ActiveThemeColorDefault;
  mmReturn.SelAttributes.Style := [];
  mmReturn.Lines.Add(AString);
  Self.Last;
end;

//Add line-by-line response to color where Delphi code is
procedure TDelphiAIDevChatView.AddResponseComplete(const AStrings: TStrings);
var
  LLineNum: Integer;
  LLineStr: string;
  FCodeStarted: Boolean;
begin
  mmReturn.Lines.Clear;
  mmReturn.SelAttributes.Color := TUtilsOTA.ActiveThemeColorDefault;
  mmReturn.SelAttributes.Style := [];

  FCodeStarted := False;
  for LLineNum := 0 to Pred(AStrings.Count) do
  begin
    LLineStr := AStrings[LLineNum].TrimRight;

    if not FCodeStarted then
    begin
      if TUtils.CodeIdMarkBeginCode(LLineStr) then
      begin
        FCodeStarted := True;
        Continue;
      end;
    end;

    if LLineStr.Trim = TConsts.MARK_END then
    begin
      FCodeStarted := False;
      mmReturn.SelAttributes.Color := TUtilsOTA.ActiveThemeColorDefault;
      Continue;
    end;

    if FCodeStarted then
    begin
      if (FSettings.ColorHighlightCodeDelphiUse) and (FSettings.ColorHighlightCodeDelphi <> clNone) then
        mmReturn.SelAttributes.Color := FSettings.ColorHighlightCodeDelphi
      else
        mmReturn.SelAttributes.Color := TUtilsOTA.ActiveThemeForCode;
    end
    else
      mmReturn.SelAttributes.Color := TUtilsOTA.ActiveThemeColorDefault;

    //Optional use of one of the following lines
    //mmReturn.Lines.Add(LLineStr);
    Self.AddResponseLine(LLineStr); //.Replace(TConsts.MARK_BEGIN_PASCAL2, '', [rfReplaceAll, rfIgnoreCase])
  end;
  Self.Last;
end;

//Bold in words between Backtick
procedure TDelphiAIDevChatView.AddResponseLine(const ALineStr: string);
const
  BACKTICK = '`';
var
  i: Integer;
  LCurrentLetter: Char;
  LNextLetter: Char;
  LLineStarted: Boolean;
  LCodeStarted: Boolean;
begin
  if not ALineStr.Contains(BACKTICK) then
  begin
    mmReturn.Lines.Add(IFThen(ALineStr.IsEmpty, ' ', ALineStr));
    Exit;
  end;

  LLineStarted := False;
  LCodeStarted := False;
  for i := 0 to ALineStr.Length do
  begin
    LCurrentLetter := ALineStr[i];
    LNextLetter := ALineStr[Succ(i)];

    if not LCodeStarted then
    begin
      if(LCurrentLetter = BACKTICK)and(LNextLetter <> BACKTICK)then
      begin
        LCodeStarted := True;
        Continue;
      end;
    end;

    if(LCurrentLetter = BACKTICK)and(LNextLetter <> BACKTICK)then
    begin
      LCodeStarted := False;
      mmReturn.SelAttributes.Style := [];
      Continue;
    end;

    SendMessage(mmReturn.Handle, WM_VSCROLL, SB_BOTTOM, 0);
    if LCodeStarted then
      mmReturn.SelAttributes.Style := [fsBold]
    else
      mmReturn.SelAttributes.Style := [];

    if LLineStarted then
      mmReturn.SelText := LCurrentLetter
    else
    begin
      mmReturn.Lines.Add('');
      mmReturn.SelText := LCurrentLetter;

      LLineStarted := True;
    end;
    SendMessage(mmReturn.Handle, WM_VSCROLL, SB_BOTTOM, 0);
  end;
  mmReturn.SelText := ' ';
  SendMessage(mmReturn.Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

procedure TDelphiAIDevChatView.WaitingFormON;
begin
  pnWait.Visible := False;
  TUtils.CenterPanel(pnWait, mmReturn);
  pnWait.Visible := True;
end;

procedure TDelphiAIDevChatView.WordWrap1Click(Sender: TObject);
begin
  if WordWrap1.Checked then
    mmReturn.ScrollBars := ssVertical
  else
    mmReturn.ScrollBars := ssBoth;
end;

procedure TDelphiAIDevChatView.WaitingFormOFF;
begin
  pnWait.Visible := False;
end;

procedure TDelphiAIDevChatView.Last;
begin
  SendMessage(mmReturn.Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

procedure TDelphiAIDevChatView.lbCurrentAIClick(Sender: TObject);
begin
  pMenuCurrentAI.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

function TDelphiAIDevChatView.GetSelectedTextOrAllFromReturn: string;
begin
  if not mmReturn.SelText.Trim.IsEmpty then
    Result := mmReturn.SelText
  else
    Result := mmReturn.Lines.Text;
end;

function TDelphiAIDevChatView.GetSelectedTextOrAllOrAbort: string;
begin
  Result := Self.GetSelectedTextOrAllFromReturn;
  if Result.Trim.IsEmpty then
    TUtils.ShowMsgAndAbort('There is no data to be used in this action');
end;

procedure TDelphiAIDevChatView.btnInsertAtCursorClick(Sender: TObject);
var
 LText: string;
begin
  LText := Self.GetSelectedTextOrAllOrAbort;
  TUtilsOTA.DeleteBlockTextSelectedInEditor;
  TUtilsOTA.InsertBlockTextIntoEditor(LText);
end;

procedure TDelphiAIDevChatView.btnCopyClick(Sender: TObject);
var
 LText: string;
begin
  LText := Self.GetSelectedTextOrAllOrAbort;
  Clipboard.AsText := LText;
end;

procedure TDelphiAIDevChatView.btnCreateNewUnitClick(Sender: TObject);
var
 LText: string;
begin
  LText := Self.GetSelectedTextOrAllOrAbort;
  TDelphiAIDevModuleCreator.New.CreateNewUnit(LText);
end;

procedure TDelphiAIDevChatView.SaveContentToFile1Click(Sender: TObject);
var
  LFileName: string;
begin
  Self.GetSelectedTextOrAllOrAbort;

  LFileName := TUtils.GetFileName('rtf');
  mmReturn.Lines.SaveToFile(LFileName);
  TUtils.ShowV('File saved successfully');
end;

procedure TDelphiAIDevChatView.ClearContent1Click(Sender: TObject);
begin
  mmReturn.Lines.Clear;
end;

procedure TDelphiAIDevChatView.btnMoreActionsClick(Sender: TObject);
begin
  pMenuMoreActions.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TDelphiAIDevChatView.InitializeRichEditReturn;
begin
  mmReturn.Lines.Clear;
  mmReturn.SelAttributes.Name := 'Courier New';
  mmReturn.SelAttributes.Size := 10;

  if TUtilsOTA.ActiveThemeIsDark then
  begin
    mmReturn.Color := $004A4136;
    mmReturn.SelAttributes.Color := clWhite;
  end
  else
  begin
    mmReturn.Color := clWindow;
    mmReturn.SelAttributes.Color := clWindowText;
  end;
end;

procedure TDelphiAIDevChatView.pMenuCurrentAIPopup(Sender: TObject);
begin
  Gemini1.Checked := False;
  ChatGPT1.Checked := False;
  case FSettings.AIDefault of
    TC4DAIsAvailable.Gemini:
      Gemini1.Checked := True;
    TC4DAIsAvailable.OpenAI:
      ChatGPT1.Checked := True;
  end;
end;

procedure TDelphiAIDevChatView.ConfLabelCurrentAI;
begin
  lbCurrentAI.Caption := FSettings.AIDefault.ToString;

  case FSettings.AIDefault of
    TC4DAIsAvailable.Gemini:
      lbCurrentAI.Hint := FSettings.ModelGemini;
    TC4DAIsAvailable.OpenAI:
      lbCurrentAI.Hint := FSettings.ModelOpenAI;
  end;
end;

procedure TDelphiAIDevChatView.Gemini1Click(Sender: TObject);
var
  LTag: Integer;
begin
  //*SEVERAL
  LTag := TMenuItem(Sender).Tag;
  if not(LTag in [0, 1])then
    Exit;

  FSettings.AIDefault := TC4DAIsAvailable(LTag);
  FSettings.SaveData;
  Self.ConfLabelCurrentAI;
end;

initialization

finalization
  Unregister;

end.
