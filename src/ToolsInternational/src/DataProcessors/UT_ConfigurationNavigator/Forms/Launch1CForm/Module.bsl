#Region PlatfromOldVersionsSupport

&AtClientAtServerNoContext
Function vStrFind(Line, SearchSubstring, SearchDirection = 1, Val StartIndex = Undefined, EntryNumber = 1)
	Return Find(Line, SearchSubstring);
EndFunction

&AtClientAtServerNoContext
Function vStrTemplate(Template, V1 = Undefined, V2 = Undefined)
	Result = Template;
	If V1 <> Undefined Then
		Result = StrReplace(Result, "%1", V1);
	EndIf;
	If V2 <> Undefined Then
		Result = StrReplace(Result, "%2", V2);
	EndIf;

	Return Result;
EndFunction

#EndRegion
&AtClient
Procedure OnOpen(Cancel)
	Server = "SRV:3541";
	InfoBase = "TEST";

	RunMode = 4;

	Dir1C = BinDir();

	Position = StrFind(Dir1C, "\", SearchDirection.FromEnd, , 3);
	If Position <> 0 Then
		Dir1C = Left(Dir1C, Position);
		Starter1C = Dir1C + "common\1cestart.exe";
	EndIf;

EndProcedure
&AtClient
Procedure Run1C(Command)
	CommandLine = vGenerateCommandLine();
	If Not IsBlankString(CommandLine) Then
		Try
			BeginRunningApplication(New NotifyDescription("vAfterRunApplication", ThisForm), CommandLine);
		Except
			Message(ErrorDescription());
		EndTry;
	EndIf;
EndProcedure

&AtClient
Procedure vAfterRunApplication(CodeReturn, AdditionalParameters = Undefined) Export
	// fake procedure for compatible with different versions of 1C Platform
EndProcedure

&AtClient
Procedure Starter1СStartChoice(Item, ChoiceData, StandardProcessing)
			StandardProcessing = False;

	Dialog = New FileDialog(FileDialogMode.Open);

	Dialog.Title = "ru = 'Путь к стартеру 1С';en = 'Path to 1C starter'";
	Dialog.Filter = "ru = 'Стартер 1С|1cestart.exe';en = 'Starter 1С|1cestart.exe'";
	Dialog.CheckFileExist = True;
	If IsBlankString(Starter1C) Then
		Dialog.Directory = BinDir();
	Иначе
		Dialog.Directory = vFileDirectory(Starter1C);
		Dialog.FullFileName = Starter1C;
	EndIf;
	Dialog.Show(New NotifyDescription("Starter1СStartChoiceAfter", ThisForm));
EndProcedure

&AtClient
Procedure Starter1СStartChoiceAfter(SelectedFiles, AdditionalParameters = Undefined) Export
	If SelectedFiles <> Undefined Then
		Starter1C = SelectedFiles[0];
	EndIf;
EndProcedure

&AtClient
Function vFileDirectory(FullFileName)
	Position = StrFind(FullFileName, "\", SearchDirection.FromEnd, , 1);
	If Position = 0 Then
		Return FullFileName;
	Else
		Return Left(FullFileName, Position);
	EndIf;
EndFunction

&AtClient
Function vGenerateCommandLine()
	If IsBlankString(Starter1C) Then
		Message("ru = 'Не задан Стартер 1С';en = 'Starter 1C is not set'");
		Return "";
	ElsIf IsBlankString(Server) Then
		Message("ru = 'Не задан сервер приложений 1С';en = '1C application server is not specified'");
		Return "";
	ElsIf IsBlankString(InfoBase) Then
		Message("ru = 'Не задана база данных на сервере приложений 1С';en = 'Infobase is not specified on the 1C application server'");
		Return "";
	EndIf;

	RunString = Starter1C;

	If RunMode = 1 Then
		RunString = RunString + " DESIGNER";
	ElsIf RunMode = 2 Then
		RunString = RunString + " ENTERPRISE /RunModeOrdinaryApplication";
	ElsIf RunMode = 3 Then
		RunString = RunString + " ENTERPRISE /RunModeManagedApplication";
	ElsIf RunMode = 4 Then
		RunString = RunString + " ENTERPRISE";
	EndIf;

	RunString = vStrTemplate(RunString + " /S %1\%2", Server, InfoBase);
	If Not IsBlankString(AdditionalParameters) Then
		RunString = RunString + " " + AdditionalParameters;
	EndIf;

	Return RunString;
EndFunction

&AtClient
Procedure GenerateCommandLine(Command)
	CommandLine = vGenerateCommandLine();
EndProcedure