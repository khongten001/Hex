unit hxUtils;

{$mode objfpc}{$H+}

interface

uses
  LazLoggerbase,
  LCLIntf, LCLType, Classes, SysUtils, Graphics, IniFiles, Forms,
  hxGlobal, hxHexEditor;

// Ini file
function CreateIniFile : TCustomIniFile;
function GetIniFileName: String;

procedure ReadFormFromIni(AIniFile: TCustomIniFile; AForm: TForm; ASection: String;
  APositionOnly: Boolean = false);
procedure ReadColorsFromIni(AIniFile: TCustomIniFile; ASection: String; AMode: TScreenMode);
procedure ReadGuiParamsFromIni(AIniFile: TCustomIniFile; ASection: String);
procedure ReadParamsFromIni(AIniFile: TCustomIniFile; ASection: String);

procedure WriteFormToIni(AIniFile: TCustomIniFile; AForm: TForm; ASection: String);
procedure WriteColorsToIni(AIniFile: TCustomIniFile; ASection: String; AMode: TScreenMode);
procedure WriteGuiParamsToIni(AIniFile: TCustomIniFile; ASection: String);
procedure WriteParamsToIni(AIniFile: TCustomIniFile; ASection: String);

procedure ApplyColorsToHexEditor(const AParams: TColorParams; AHexEditor: THxHexEditor);
procedure ApplyParamsToHexEditor(const AParams: THexParams; AHexEditor: THxHexEditor);

// Simple dialogs
function Confirm(const AMsg: string): boolean;
procedure ErrorMsg(const AMsg: string);

// Exception
procedure ErrorFmt(const AMsg: string; AParams: Array of const);

// Colors
function IsDarkMode: Boolean;
function GetScreenMode: TScreenMode;


implementation

uses
  TypInfo, LazFileUtils, Dialogs;


{==============================================================================}
{  Ini file                                                                    }
{==============================================================================}

function CreateIniFile : TCustomIniFile;
var
  fn: String;
  dir: String;
begin
  fn := GetIniFileName;
  dir := ExtractFileDir(fn);
  ForceDirectories(dir);
  result := TMemIniFile.Create(fn);
end;

function GetIniFileName: String;
begin
  Result :=
    AppendPathDelim(GetAppConfigDir(false)) +
    ChangeFileExt(ExtractFileName(Application.ExeName), '.cfg');
end;

procedure ReadColorsFromIni(AIniFile: TCustomIniFile; ASection: String; AMode: TScreenMode);
begin
  with ColorParams[AMode] do
  begin
    BackgroundColor := TColor(AIniFile.ReadInteger(ASection,
      'BackgroundColor', Integer(BackgroundColor)));
    ActiveFieldBackgroundColor := TColor(AIniFile.ReadInteger(ASection,
      'ActiveFieldBackgroundColor', Integer(ActiveFieldBackgroundColor)));
    OffsetBackgroundColor := TColor(AIniFile.ReadInteger(ASection,
      'OffsetBackgroundColor', Integer(OffsetBackgroundColor)));
    OffsetForegroundColor := TColor(AIniFile.ReadInteger(ASection,
      'OffsetForegroundColor', Integer(OffsetForegroundColor)));
    CurrentOffsetBackgroundColor := TColor(AIniFile.ReadInteger(ASection,
      'CurrentOffsetBackgroundColor', Integer(CurrentOffsetBackgroundColor)));
    CurrentOffsetForegroundColor := TColor(AIniFile.ReadInteger(ASection,
      'CurrentOffsetForegroundColor', Integer(CurrentOffsetForegroundColor)));
    ChangedBackgroundColor := TColor(AIniFile.ReadInteger(ASection,
      'ChangedBackgroundColor', Integer(ChangedBackgroundColor)));
    ChangedForegroundColor := TColor(AIniFile.ReadInteger(ASection,
      'ChangedForegroundColor', Integer(ChangedForegroundColor)));
    EvenColumnForeGroundColor := TColor(AIniFile.ReadInteger(ASection,
      'EvenColumnForegroundColor', Integer(EvenColumnForegroundColor)));
    OddColumnForegroundColor := TColor(AIniFile.ReadInteger(ASection,
      'OddColumnForegroundColor', Integer(OddColumnForegroundColor)));
    CharFieldForegroundColor := TColor(AIniFile.ReadInteger(ASection,
      'CharFieldForegroundColor', Integer(CharFieldForegroundColor)));
  end;
end;

procedure ReadFormFromIni(AIniFile: TCustomIniFile; AForm: TForm;
  ASection: String; APositionOnly: Boolean = false);
var
  s: String;
  ws: TWindowState;
  L, T, W, H: integer;
  R: TRect;
begin
  with AIniFile do
  begin
    s := ReadString(ASection, 'WindowState', '');
    if s = '' then
      ws := AForm.WindowState
    else
      ws := TWindowState(GetEnumValue(TypeInfo(TWindowState), s));
    AForm.WindowState := ws;
    if ws = wsNormal then
    begin
      L := ReadInteger(ASection, 'Left', AForm.Left);
      T := ReadInteger(ASection, 'Top',  AForm.Top);
      if APositionOnly then
      begin
        W := AForm.Width;
        H := AForm.Height;
      end else
      begin
        W := ReadInteger(ASection, 'Width',  AForm.Width);
        H := ReadInteger(ASection, 'Height', AForm.Height);
      end;
      R := Screen.WorkAreaRect;
      if W > R.Width then W := R.Width;
      if H > R.Height then H := R.Height;
      if L < R.Left then L := R.Left;
      if T < R.Top then T := R.Top;
      if L + W > R.Right then
        L := R.Right - W - GetSystemMetrics(SM_CXSIZEFRAME);
      if T + H > R.Bottom then
        T := R.Bottom - H - GetSystemMetrics(SM_CYCAPTION) - GetSystemMetrics(SM_CYSIZEFRAME);
      AForm.SetBounds(L, T, W, H);
      AForm.Position := poDesigned;
    end;
  end;
end;

procedure ReadGUIParamsFromIni(AIniFile: TCustomIniFile; ASection: String);
var
  s: String;
begin
  with AIniFile do
  begin
    s := ReadString(ASection, 'IconSet', '');
    if s <> '' then
      GuiParams.IconSet := TIconSet(GetEnumValue(TypeInfo(TIconSet), s));
  end;
end;

procedure ReadParamsFromIni(AIniFile: TCustomIniFile; ASection: String);
var
  i: Integer;
  s: String;
  sa: TStringArray;
  dt: TDataType;
begin
  with HexParams do
  begin
    ViewOnly := AIniFile.ReadBool(ASection, 'ViewOnly', ViewOnly);
    WriteProtected := AIniFile.ReadBool(ASection, 'WriteProtected', WriteProtected);
    AllowInsertMode := AIniFile.ReadBool(ASection, 'AllowInsertMode', AllowInsertMode);
    InsertMode := AIniFile.ReadBool(ASection, 'InsertMode', InsertMode);
    BigEndian := AIniFile.ReadBool(ASection, 'BigEndian', BigEndian);

    s := AIniFile.ReadString(ASection, 'OffsetDisplay.Base', '');
    if s <> '' then
      OffsetDisplayBase := TOffsetDisplayBase(GetEnumValue(TypeInfo(TOffsetDisplayBase), s));
    OffsetDisplayHexPrefix := AIniFile.ReadString(ASection, 'OffsetDisplay.HexPrefix', OffsetDisplayHexPrefix);
    RulerVisible := AIniFile.ReadBool(ASection, 'Ruler.Visible', RulerVisible);
    s := AIniFile.ReadString('Params', 'Ruler.NumberBase', '');
    if s <> '' then
      RulerNumberBase := TOffsetDisplayBase(GetEnumValue(TypeInfo(TOffsetDisplayBase), s));
    BytesPerRow := AIniFile.ReadInteger(ASection, 'BytesPerRow', BytesPerRow);
    BytesPerColumn := AIniFile.ReadInteger(ASection, 'BytesPerColumn', BytesPerColumn);
    MaskChar := char(AIniFile.ReadInteger(ASection, 'MaskChar', ord(MaskChar)));
    FontName := AIniFile.ReadString(ASection, 'FontName', FontName);
    FontSize := AIniFile.ReadInteger(ASection, 'FontSize', FontSize);
    HexLowercase := AIniFile.ReadBool(ASection, 'HexLowercase', HexLowercase);
    DrawGutter3D := AIniFile.ReadBool(ASection, 'DrawGutter3D', DrawGutter3D);

    { Data Viewer }

    DataViewerVisible := AIniFile.ReadBool(ASection, 'DataViewer.Visible', DataViewerVisible);
    s := AIniFile.ReadString(ASection, 'DataViewer.Position', '');
    if s <> '' then
      DataViewerPosition := TViewerPosition(GetEnumValue(TypeInfo(TViewerPosition), s));
    s := UpperCase(AIniFile.ReadString(ASection, 'DataViewer.DataTypes', ''));
    if s <> '' then
    begin
      s := ';' + s + ';';
      DataViewerDataTypes := [];
      for dt := dtFirstNumericDataType to dtLastNumericDataType do
        if pos(';' + UpperCase(DataTypeNames[dt]) + ';', s) <> 0 then
          Include(DataViewerDataTypes, dt);
    end;
    s := AIniFile.ReadString(ASection, 'DataViewer.ColWidths', '');
    if s <> '' then
    begin
      sa := s.Split(',');
      for i:=0 to High(sa) do
        if i <= High(DataViewerColWidths) then
          TryStrToInt(sa[i], DataViewerColWidths[i]);
    end;

    { Object viewer }

    ObjectViewerVisible := AIniFile.ReadBool(ASection, 'ObjectViewer.Visible', ObjectViewerVisible);
    s := AIniFile.ReadString(ASection, 'ObjectViewer.Position', '');
    if s <> '' then
      ObjectViewerPosition := TViewerPosition(GetEnumValue(TypeInfo(TViewerPosition), s));
    ObjectViewerInfoHeight := AIniFile.ReadInteger(ASection, 'ObjectViewer.InfoHeight', ObjectViewerInfoHeight);

    { RecordViewer }

    RecordViewerVisible := AIniFile.ReadBool(ASection, 'RecordViewer.Visible', RecordViewerVisible);
    s := AIniFile.ReadString(ASection, 'RecordViewer.Position', '');
    if s <> '' then
      RecordViewerPosition := TViewerPosition(GetEnumValue(TypeInfo(TViewerPosition), s));

    s := AIniFile.ReadString(ASection, 'RecordViewer.ColWidths', '');
    if s <> '' then
    begin
      sa := s.Split(',');
      for i:=0 to High(sa) do
        if i <= High(RecordViewerColWidths) then
          TryStrToInt(sa[i], RecordViewerColWidths[i]);
    end;

    SettingsPageIndex := AIniFile.ReadInteger(ASection, 'SettingsPageIndex', SettingsPageIndex);
  end;
end;

procedure WriteColorsToIni(AIniFile: TCustomIniFile; ASection: String; AMode: TScreenMode);
begin
  with ColorParams[AMode] do
  begin
    AIniFile.EraseSection(ASection);

    AIniFile.WriteInteger(ASection, 'BackgroundColor',
      Integer(BackgroundColor));
    AIniFile.WriteInteger(ASection, 'ActiveFieldBackgroundColor',
      Integer(ActiveFieldBackgroundColor));
    AIniFile.WriteInteger(ASection, 'OffsetBackgroundColor',
      Integer(OffsetBackgroundColor));
    AIniFile.WriteInteger(ASection, 'OffsetForegroundColor',
      Integer(OffsetForegroundColor));
    AIniFile.WriteInteger(ASection, 'CurrentOffsetBackgroundColor',
      Integer(CurrentOffsetBackgroundColor));
    AIniFile.WriteInteger(ASection, 'CurrentOffsetForegroundColor',
      Integer(CurrentOffsetForegroundColor));
    AIniFile.WriteInteger(ASection, 'ChangedBackgroundColor',
      Integer(ChangedBackgroundColor));
    AIniFile.WriteInteger(ASection, 'ChangedForegroundColor',
      Integer(ChangedForegroundColor));
    AIniFile.WriteInteger(ASection, 'EvenColumnForegroundColor',
      Integer(EvenColumnForegroundColor));
    AIniFile.WriteInteger(ASection, 'OddColumnForegroundColor',
      Integer(OddColumnForegroundColor));
    AIniFile.WriteInteger(ASection, 'CharFieldForegroundColor',
      Integer(CharFieldForegroundColor));
  end;
end;

procedure WriteFormToIni(AIniFile: TCustomIniFile; AForm: TForm; ASection: string);
begin
  with AIniFile do
  begin
    EraseSection(ASection);

    WriteString(ASection, 'WindowState', GetEnumName(TypeInfo(TWindowState), integer(AForm.WindowState)));
    if AForm.WindowState = wsNormal then
    begin
      WriteInteger(ASection, 'Left',   AForm.Left);
      WriteInteger(ASection, 'Top',    AForm.Top);
      WriteInteger(ASection, 'Width',  AForm.ClientWidth);
      WriteInteger(ASection, 'Height', AForm.ClientHeight);
    end;
  end;
end;

procedure WriteGuiParamsToIni(AIniFile: TCustomIniFile; ASection: String);
var
  s: String;
begin
  with GUIParams do
  begin
    AIniFile.EraseSection(ASection);
    s := GetEnumName(TypeInfo(TIconSet), Integer(IconSet));
    AIniFile.WriteString(ASection, 'IconSet', s);
  end;
end;

procedure WriteParamsToIni(AIniFile: TCustomIniFile; ASection: String);
var
  s: String;
  dt: TDataType;
  i: Integer;
begin
  with HexParams do
  begin
    AIniFile.EraseSection(ASection);

    AIniFile.WriteInteger(ASection, 'SettingsPageIndex',
      SettingsPageIndex);

    AIniFile.WriteBool(ASection, 'ViewOnly',
      ViewOnly);
    AIniFile.WriteBool(ASection, 'WriteProtected',
      WriteProtected);
    AIniFile.WriteBool(ASection, 'AllowInsertMode',
      AllowInsertMode);
    AIniFile.WriteBool(ASection, 'InsertMode',
      InsertMode);
    AIniFile.WriteBool(ASection, 'BigEndian',
      BigEndian);
    AIniFile.WriteString(ASection, 'OffsetDisplay.Base',
      GetEnumName(TypeInfo(TOffsetDisplayBase), integer(OffsetDisplayBase)));
    AIniFile.WriteString(ASection, 'OffsetDisplay.HexPrefix',
      OffsetDisplayHexPrefix);
    AIniFile.WriteBool(ASection, 'Ruler.Visible',
      RulerVisible);
    AIniFile.WriteString(ASection, 'Ruler.NumberBase',
      GetEnumName(TypeInfo(TOffsetDisplayBase), integer(RulerNumberBase)));
    AIniFile.WriteInteger(ASection, 'BytesPerRow',
      BytesPerRow);
    AIniFile.WriteInteger(ASection, 'BytesPerColumn',
      BytesPerColumn);
    AIniFile.WriteInteger(ASection, 'MaskChar', ord(MaskChar));

    AIniFile.WriteString(ASection, 'FontName',
      FontName);
    AIniFile.WriteInteger(ASection, 'FontSize',
      FontSize);
    AIniFile.WriteBool(ASection, 'HexLowercase',
      HexLowercase);
    AIniFile.WriteBool(ASection, 'DrawGutter3D',
      DrawGutter3D);


    { Data viewer }

    AIniFile.WriteBool(ASection, 'DataViewer.Visible',
      DataViewerVisible);
    AIniFile.WriteString(ASection, 'DataViewer.Position',
      GetEnumName(TypeInfo(TViewerPosition), integer(DataViewerPosition)));
    s := '';
    for dt := dtFirstNumericDataType to dtLastNumericDataType do
      if dt in DataViewerDataTypes then s := s + DataTypeNames[dt] + ';';
    if s <> '' then Delete(s, Length(s), 1);
    AIniFile.WriteString(ASection, 'DataViewer.DataTypes', s);
    s := IntToStr(HexParams.DataViewerColWidths[0]);
    for i := 1 to High(TDataViewerColWidths) do
      s := s + ',' + IntToStr(HexParams.DataViewerColWidths[i]);
    AIniFile.WriteString(ASection, 'DataViewer.ColWidths', s);

    { Object viewer }

    AIniFile.WriteBool(ASection, 'ObjectViewer.Visible',
      ObjectViewerVisible);
    AIniFile.WriteString(ASection, 'ObjectViewer.Position',
      GetEnumName(TypeInfo(TViewerPosition), integer(ObjectViewerPosition)));
    AIniFile.WriteInteger(ASection, 'ObjectViewer.InfoHeight',
      ObjectViewerInfoHeight);

    { Record viewer }

    AIniFile.WriteBool(ASection, 'RecordViewer.Visible',
      RecordViewerVisible);
    AIniFile.WriteString(ASection, 'RecordViewer.Position',
      GetEnumName(TypeInfo(TViewerPosition), integer(RecordViewerPosition)));
    s := IntToStr(HexParams.RecordViewerColWidths[0]);
    for i := 1 to High(TRecordViewerColWidths) do
      s := s + ',' + IntToStr(HexParams.RecordViewerColWidths[i]);
    AIniFile.WriteString(ASection, 'RecordViewer.ColWidths', s);
  end;
end;

procedure ApplyColorsToHexEditor(const AParams: TColorParams;
  AHexEditor: THxHexEditor);
begin
  if Assigned(AHexEditor) then
  begin
    AHexEditor.Colors.Background := AParams.BackgroundColor;
    AHexEditor.Colors.ActiveFieldBackground := AParams.ActiveFieldBackgroundColor;
    AHexEditor.Colors.OffsetBackground := AParams.OffsetBackgroundColor;
    AHexEditor.Colors.Offset := AParams.OffsetForegroundColor;
    AHexEditor.Colors.CurrentOffsetBackground := AParams.CurrentOffsetBackgroundColor;
    AHexEditor.Colors.CurrentOffset := AParams.CurrentOffsetForegroundColor;
    AHexEditor.Colors.EvenColumn := AParams.EvenColumnForegroundColor;
    AHexEditor.Colors.OddColumn := AParams.OddColumnForegroundColor;
    AHexEditor.Colors.ChangedBackground := AParams.ChangedBackgroundColor;
    AHexEditor.Colors.ChangedText := AParams.ChangedForegroundColor;
    AHexEditor.Font.Color := AParams.CharFieldForegroundColor;
  end;
end;

procedure ApplyParamsToHexEditor(const AParams: THexParams;
  AHexEditor: THxHexEditor);
begin
  if Assigned(AHexEditor) then
  begin
    AHexEditor.ReadOnlyView := AParams.ViewOnly;
    AHexEditor.ReadOnlyFile := AParams.WriteProtected;
    AHexEditor.AllowInsertMode := AParams.AllowInsertMode;
    AHexEditor.InsertMode := AParams.InsertMode;
    // To do: Big endian

    AHexEditor.OffsetFormat := AParams.GetOffsetFormat;
    AHexEditor.ShowRuler := AParams.RulerVisible;
    case AParams.RulerNumberBase of
      odbDec: AHexEditor.RulerNumberBase := 10;
      odbHex: AHexEditor.RulerNumberBase := 16;
      odbOct: AHexEditor.RulerNumberBase := 8;
    end;
    AHexEditor.BytesPerRow := AParams.BytesPerRow;
    AHexEditor.BytesPerColumn := AParams.BytesPerColumn;
    AHexEditor.MaskChar := AParams.MaskChar;

    AHexEditor.Font.Name := AParams.FontName;
    AHexEditor.Font.Size := AParams.FontSize;
    AHexEditor.HexLowercase := AParams.HexLowerCase;
    AHexEditor.DrawGutter3D := AParams.DrawGutter3D;
  end;
end;

{==============================================================================}
{  Dialogs                                                                     }
{==============================================================================}

function Confirm(const AMsg: string): boolean;
begin
  Result := MessageDlg(AMsg, mtConfirmation, mbYesNoCancel, 0) = idYes;
end;

procedure ErrorMsg(const AMsg: string);
begin
  MessageDlg(AMsg, mtError, [mbOK], 0);
end;


{==============================================================================}
{  Exception                                                                   }
{==============================================================================}

procedure ErrorFmt(const AMsg: string; AParams: Array of const);
begin
  raise EHexError.CreateFmt(AMsg, AParams);
end;


{==============================================================================}
{  Colors                                                                      }
{==============================================================================}

function IsDarkMode: Boolean;
var
  c: TColor;
begin
  c := ColorToRGB(clWindow);
  Result := (Red(c) + Green(c) + blue(c)) div 3 < 128;
end;

function GetScreenMode: TScreenMode;
begin
  if IsDarkMode then Result := smDarkMode else Result := smLightMode;
end;


end.

