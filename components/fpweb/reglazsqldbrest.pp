unit reglazsqldbrest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, PropEdits, ComponentEditors, ProjectIntf,
  sqldbrestschema,
  sqldbrestcsv ,sqldbrestxml, sqldbrestcds,
  sqldbrestio, sqldbrestauth, sqldbrestbridge, sqldbrestmodule;

Type

  { ---------------------------------------------------------------------
    Property editors
    ---------------------------------------------------------------------}

  { TSQLDBConnectionTypePropertyEditor }

  TSQLDBConnectionTypePropertyEditor = class(TStringPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const NewValue: ansistring); override;
  end;

  { TSQLDBRestDefaultConnectionPropertyEditor }

  TSQLDBRestDefaultConnectionPropertyEditor = class(TStringPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const NewValue: ansistring); override;
  end;

  { TSQLDBRestInOutFormatPropertyEditor }

  TSQLDBRestInOutFormatPropertyEditor = class(TStringPropertyEditor)
  public
    Class Function StreamType : TRestStreamerType; virtual; abstract;
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const NewValue: ansistring); override;
  end;

  { TSQLDBRestInputFormatPropertyEditor }

  TSQLDBRestInputFormatPropertyEditor = class(TSQLDBRestInOutFormatPropertyEditor)
    Class Function StreamType : TRestStreamerType; override;
  end;

  { TSQLDBRestOutputFormatPropertyEditor }

  TSQLDBRestOutputFormatPropertyEditor = class(TSQLDBRestInOutFormatPropertyEditor)
    Class Function StreamType : TRestStreamerType; override;
  end;

  { TSQLDBRestResourceNamePropertyEditor }

  TSQLDBRestResourceNamePropertyEditor = class(TStringPropertyEditor)
  protected
    function GetResourceList: TSQLDBRestResourceList;virtual;
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;


  { ---------------------------------------------------------------------
    Component editors
    ---------------------------------------------------------------------}

  { TSQLDBRestSchemaComponentEditor }

  TSQLDBRestSchemaComponentEditor = class(TComponentEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  { TSQLDBRestDispatcherComponentEditor }

  TSQLDBRestDispatcherComponentEditor = class(TComponentEditor)
  private
    procedure ExposeConnection(D: TSQLDBRestDispatcher);
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  { ---------------------------------------------------------------------
    Rest Module
    ---------------------------------------------------------------------}


  TFileRestModule = class(TFileDescPascalUnitWithResource)
  public
    constructor Create; override;
    function GetInterfaceUsesSection: string; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function GetImplementationSource(const Filename, SourceName, ResourceName: string): string;override;
  end;

Procedure Register;

implementation

uses
  // Lazarus
  LResources, codecache, Forms, Dialogs, SrcEditorIntf,  lazideintf, FormEditingIntf, codetoolmanager,
  // FPC
  sqldb, sqldbrestini,
  // This package
  frmsqldbrestselectconn,
  frmsqldbrestdispatchini,
  reslazsqldbrest;

Var
  FileDescriptorRestModule: TFileRestModule;

Procedure Register;

begin
  RegisterComponents('fpWeb',[
    TSQLDBRESTDispatcher,
    TSQLDBRESTSchema,
    TRESTBasicAuthenticator,
    TSQLDBRestBusinessProcessor
  ]);
  RegisterPropertyEditor(TypeInfo(AnsiString),
    TSQLDBRestConnection, 'ConnectionType', TSQLDBConnectionTypePropertyEditor);
  RegisterPropertyEditor(TypeInfo(AnsiString),
    TSQLDBRestDispatcher, 'OutputFormat', TSQLDBRestOutputFormatPropertyEditor);
  RegisterPropertyEditor(TypeInfo(AnsiString),
    TSQLDBRestDispatcher, 'InputFormat', TSQLDBRestInPutFormatPropertyEditor);
  RegisterPropertyEditor(TypeInfo(UTF8String),
    TSQLDBRestDispatcher, 'DefaultConnection', TSQLDBRestDefaultConnectionPropertyEditor);
  RegisterPropertyEditor(TypeInfo(UTF8String),
    TSQLDBRestBusinessProcessor,'ResourceName',TSQLDBRestResourceNamePropertyEditor);
  RegisterComponentEditor(TSQLDBRESTSchema,TSQLDBRESTSchemaComponentEditor);
  RegisterComponentEditor(TSQLDBRestDispatcher,TSQLDBRestDispatcherComponentEditor);

  FileDescriptorRestModule:=TFileRestModule.Create;
  RegisterProjectFileDescriptor(FileDescriptorRestModule);
  FormEditingHook.RegisterDesignerBaseClass(TSQLDBRestModule);

end;

{ TSQLDBRestSchemaComponentEditor }
Function GetFileName(var aFileName : UTF8String; aFilters : UTF8String; ForSave : Boolean = False) : Boolean;


Var
  Dlg : TFileDialog;

begin
  if forSave then
    begin
    DLG:=TSaveDialog.Create(Application);
    With TSaveDialog(DLG) do
      Options:=Options+[ofPathMustExist,ofOverwritePrompt];
    end
  else
    begin
    DLG:=TOpenDialog.Create(Application);
    With TOpenDialog(DLG) do
      Options:=Options+[ofFileMustExist];
    end;
  try
    DLG.FileName:=aFileName;
    DLG.Filter:=aFilters;
    DLG.DefaultExt:=ExtractFileExt(aFileName);
    Result:=Dlg.Execute;
    if Result then
      aFileName:=DLG.FileName;
  finally
    Dlg.Free;
  end;
end;

{ TSQLDBRestResourceNamePropertyEditor }

function TSQLDBRestResourceNamePropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paSortList, paValueList, paRevertable];
end;

function TSQLDBRestResourceNamePropertyEditor.GetResourceList : TSQLDBRestResourceList;

Var
  S : TSQLDBRestSchema;
  C : TPersistent;

begin
  Result:=Nil;
  C:=TPersistent(GetComponent(0));
  if not (Assigned(C) and (C is TSQLDBRestBusinessProcessor)) then
    exit;
  S:=TSQLDBRestBusinessProcessor(C).Schema;
  if Assigned(S) then
    Result:=S.Resources;
end;

procedure TSQLDBRestResourceNamePropertyEditor.GetValues(Proc: TGetStrProc);

Var
  L : TSQLDBRestResourceList;
  i : Integer;

begin
  L:=GetResourceList;
  if Not Assigned(L) then
   exit;
  For I:=0 to L.Count-1 do
    Proc(L[i].ResourceName);
end;


{ TSQLDBRestDefaultConnectionPropertyEditor }

function TSQLDBRestDefaultConnectionPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paSortList, paValueList, paRevertable];
end;

procedure TSQLDBRestDefaultConnectionPropertyEditor.GetValues(Proc: TGetStrProc);

Var
  I : Integer;
  D : TSQLDBRestDispatcher;

begin
  D:=GetComponent(0) as TSQLDBRestDispatcher;
  for I:=0 to D.Connections.Count-1 do
    Proc(D.Connections[i].Name);
end;

procedure TSQLDBRestDefaultConnectionPropertyEditor.SetValue(const NewValue: ansistring
  );
begin
  inherited SetValue(NewValue);
end;

{ TSQLDBRestOutputFormatPropertyEditor }

class function TSQLDBRestOutputFormatPropertyEditor.StreamType: TRestStreamerType;
begin
    Result:=rstOutput;
end;

{ TSQLDBRestInputFormatPropertyEditor }

class function TSQLDBRestInputFormatPropertyEditor.StreamType: TRestStreamerType;
begin
  Result:=rstInput;
end;

{ TSQLDBRestInOutFormatPropertyEditor }

function TSQLDBRestInOutFormatPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paSortList, paValueList, paRevertable];
end;

procedure TSQLDBRestInOutFormatPropertyEditor.GetValues(Proc: TGetStrProc);
Var
  L : TStringList;
  I : Integer;
begin
  L:=TStringList.Create;
  try
    TStreamerFactory.GetStreamerList(L,StreamType);
    for I:=0 to L.Count-1 do
      Proc(L[i]);
  finally
    L.Free;
  end;
end;

procedure TSQLDBRestInOutFormatPropertyEditor.SetValue(
  const NewValue: ansistring);
begin
  inherited SetValue(NewValue);
end;

{ TSQLDBRestDispatcherComponentEditor }

procedure TSQLDBRestDispatcherComponentEditor.ExposeConnection(D : TSQLDBRestDispatcher);

Var
  C : TSQLDBRestConnection;
  aSchema : TSQLDBRestSchema;
  aOptions : TRestFieldOptions;

begin
  C:=SelectRestConnection(D.Connections,aOptions);
  if C=Nil then
    exit;
  aSchema:=D.ExposeConnection(Designer.LookupRoot,C,Nil,aOptions);
  aSchema.Name:=Designer.CreateUniqueComponentName(aSchema.ClassName);
  // Todo: add Aschema to form.
end;

procedure TSQLDBRestDispatcherComponentEditor.ExecuteVerb(Index: Integer);
Var
  FN : UTF8String;
  D : TSQLDBRestDispatcher;
  OI : TDispatcherIniOptions;

begin
  D:=Component as TSQLDBRestDispatcher;
  Case Index of
    0 :
      ExposeConnection(D);
    1,2 :
      begin
      FN:=Component.Name+'.ini';
      if GetDispatchLoadSaveOptions(Index=1,OI) then
        if GetFileName(FN,'INI Files|*.ini|All files|'+allFilesMask,Index=1) then
          if Index=0 then
            D.SaveToFile(FN,OI)
          else
            D.LoadFromFile(FN,OI);
      end;
  end;
end;

function TSQLDBRestDispatcherComponentEditor.GetVerb(Index: Integer): string;
begin
  Case Index of
    0 : Result:=SExposeAConnection;
    1 : Result:=SSaveSettingsToIni;
    2 : Result:=SLoadSettingsFromIni;
  end;
end;

function TSQLDBRestDispatcherComponentEditor.GetVerbCount: Integer;
begin
  Result:=3;
end;

procedure TSQLDBRestSchemaComponentEditor.ExecuteVerb(Index: Integer);

Var
  FN : UTF8String;
  S : TSQLDBRestSchema;

begin
  S:=Component as TSQLDBRestSchema;
  Case Index of
    0,1 :
      begin
      FN:=Component.Name+'.json';
      if GetFileName(FN, Format(SJSONFilesFilter, [allFilesMask]), Index=0) then
        if Index=0 then
          S.SaveToFile(FN)
        else
          S.LoadFromFile(FN);
      end;
  end;
end;

function TSQLDBRestSchemaComponentEditor.GetVerb(Index: Integer): string;
begin
  Case Index of
    0 : Result:=SSaveSchemaToJSONFile;
    1 : Result:=SLoadSchemaFromJSONFile;
  end;
end;

function TSQLDBRestSchemaComponentEditor.GetVerbCount: Integer;
begin
  Result:=2;
end;

function TSQLDBConnectionTypePropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paSortList, paValueList, paRevertable];
end;

procedure TSQLDBConnectionTypePropertyEditor.GetValues(Proc: TGetStrProc);
Var
  L : TStringList;
  I : Integer;
begin
  L:=TStringList.Create;
  try
    GetConnectionList(L);
    for I:=0 to L.Count-1 do
      Proc(L[i]);
  finally
    L.Free;
  end;
end;

procedure TSQLDBConnectionTypePropertyEditor.SetValue(const NewValue: ansistring);
var
  Comp: TPersistent;
  Code: TCodeBuffer;
  ConnDef: TConnectionDef;
  SrcEdit: TSourceEditorInterface;
begin
  if not LazarusIDE.BeginCodeTools then
    Exit;
  SrcEdit := SourceEditorManagerIntf.ActiveEditor;
  if SrcEdit=nil then
    Exit;
  Code := TCodeBuffer(SrcEdit.CodeToolsBuffer);
  if Code = nil then
    Exit;
  Comp := GetComponent(0);
  if Comp is TSQLConnector then
  begin
    ConnDef := GetConnectionDef(NewValue);
    if Assigned(ConnDef) then
      CodeToolBoss.AddUnitToMainUsesSection(Code, ConnDef.UnitName, '');
  end;
  inherited;
end;

{ TFileDescHTMLModule }

constructor TFileRestModule.Create;
begin
  inherited Create;
  Name:='SQLDB REST Bridge Module';
  ResourceClass:=TSQLDBRestModule;
  UseCreateFormStatements:=true;
end;

function TFileRestModule.GetInterfaceUsesSection: string;
begin
  Result:='SysUtils, Classes ';
  if (GetResourceType = rtLRS) then
    Result :=  Result+ ', LResources, ';
  Result:=Result+',HTTPDefs, fpHTTP, sqldbrestmodule, sqldbrestbridge';
end;

function TFileRestModule.GetLocalizedName: string;
begin
  Result:=SSQLDBRESTModule;
end;

function TFileRestModule.GetLocalizedDescription: string;
begin
  Result:=SSQLDBRESTModuleDesc;
end;

function TFileRestModule.GetImplementationSource(const Filename, SourceName, ResourceName: string): string;

begin
  Result:=Inherited GetImplementationSource(FileName,SourceName,ResourceName);
  if GetResourceType = rtRes then
    Result:=Result+'initialization'+LineEnding;
  Result:=Result+'  T'+ResourceName+'.RegisterModule(''REST'');'+LineEnding;
end;


initialization
  {$i lazsqldbrest_images.inc}
end.
