///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
// Translated by Neti Company
///////////////////////////////////////////////////////////////////////////////////////////////////////
#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Checking the access rights must be the first action in this procedure.
	If Not AccessRight("Administration", Metadata) Then
		Raise NStr("ru = 'Использование обработки в интерактивном режиме доступно только администратору.'; en = 'Running the data processor manually requires administrator rights.'");
	EndIf;
	
	CheckPlatformVersionAndCompatibilityMode();
	
	Object.IsInteractiveMode = True;
	Object.SafeMode = True;
	Object.ExchangeLogFileEncoding = "TextEncoding.UTF8";

	FormHeader = NStr("ru = 'Универсальный обмен данными в формате XML (%DataProcessorVersion%)'; en = 'Universal data exchange in XML format (%DataProcessorVersion%)'");
	FormHeader = StrReplace(FormHeader, "%DataProcessorVersion%", ObjectVersionAsStringAtServer());
	
	Title = FormHeader;
	
	FillTypeAvailableToDeleteList();
	UT_Common.ToolFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.RulesFileName.ChoiceList.LoadValues(ExchangeRules.UnloadValues());
	Items.ExchangeFileName.ChoiceList.LoadValues(DataImportFromFile.UnloadValues());
	Items.DataFileName.ChoiceList.LoadValues(DataExportToFile.UnloadValues());
	
	OnPeriodChange();
	
	OnChangeChangesRegistrationDeletionType();
	
	ClearDataImportFileData();
	
	DirectExport = ?(Object.DirectReadingFromDestinationIB, 1, 0);

	SavedImportMode = (Object.ExchangeMode = "Import");

	If SavedImportMode Then
		
		// Setting the appropriate page.
		Items.FormMainPanel.CurrentPage = Items.FormMainPanel.ChildItems.Import;
		
	EndIf;

	ProcessTransactionManagementItemsEnabled();
	
	ExpandTreeRows(DataToDelete, Items.DataToDelete, "Check");
	
	ArchiveFileOnValueChange();
	DirectExportOnValueChange();
	
	ChangeProcessingMode(IsClient);

	#If WebClient Then
		Items.ExportDebugPages.CurrentPage = Items.ExportDebugPages.ChildItems.WebClientExportGroup;
		Items.ImportDebugPages.CurrentPage = Items.ImportDebugPages.ChildItems.WebClientImportGroup;
		Object.HandlersDebugModeFlag = False;
	#EndIf
	
	SetDebugCommandsEnabled();
	
	If SavedImportMode And Object.AutomaticDataImportSettings <> 0 Then

		If Object.AutomaticDataImportSettings = 1 Then

			NotifyDescription = New NotifyDescription("OnOpenCompletion", ThisObject);
			ShowQueryBox(NotifyDescription, NStr("ru = 'Выполнить загрузку данных из файла обмена?'; en = 'Do you want to import data from the exchange file?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
			
		Else
			
			OnOpenCompletion(DialogReturnCode.Yes, Undefined);
			
		EndIf;
		
	EndIf;
	
	If Not IsWindowsClient() Then
		Items.CDGroup.CurrentPage = Items.CDGroup.ChildItems.LinuxGroup;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpenCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		ExecuteImportFromForm();
		ExportPeriodPresentation = PeriodPresentation(Object.StartDate, Object.EndDate);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ArchiveFileOnChange(Item)
	
	ArchiveFileOnValueChange();
	
EndProcedure

&AtClient
Procedure RulesFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectFile(Item, ThisObject, "RulesFileName", True, , False, True);
	
EndProcedure

&AtClient
Procedure RulesFileNameOpening(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DirectExportOnChange(Item)
	
	DirectExportOnValueChange();
	
EndProcedure

&AtClient
Procedure FormMainPanelOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage.Name = "Export" Then
		
		Object.ExchangeMode = "Export";
		
	ElsIf CurrentPage.Name = "Import" Then
		
		Object.ExchangeMode = "Import";
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DebugModeFlagOnChange(Item)
	
	If Object.DebugModeFlag Then
		
		Object.UseTransactions = False;
				
	EndIf;
	
	ProcessTransactionManagementItemsEnabled();

EndProcedure

&AtClient
Procedure ProcessedObjectsCountToUpdateStatusOnChange(Item)

	If Object.ProcessedObjectsCountToUpdateStatus = 0 Then
		Object.ProcessedObjectsCountToUpdateStatus = 100;
	EndIf;

EndProcedure

&AtClient
Procedure ExchangeFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectFile(Item, ThisObject, "ExchangeFileName", False, , Object.ArchiveFile);
	
EndProcedure

&AtClient
Procedure ExchangeLogFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectFile(Item, Object, "ExchangeLogFileName", False, "txt", False);
	
EndProcedure

&AtClient
Procedure ImportExchangeLogFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectFile(Item, Object, "ImportExchangeLogFileName", False, "txt", False);
	
EndProcedure

&AtClient
Procedure DataFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectFile(Item, ThisObject, "DataFileName", False, , Object.ArchiveFile);
	
EndProcedure

&AtClient
Procedure InfobaseConnectionDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	FileSelectionDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	
	FileSelectionDialog.Title = NStr("ru = 'Выберите каталог информационной базы'; en = 'Select infobase directory'");
	FileSelectionDialog.Directory = Object.InfobaseToConnectDirectory;
	FileSelectionDialog.CheckFileExist = True;
	
	Notification = New NotifyDescription("InfobaseConnectionDirectoryChoiceProcessing", ThisObject);
	FileSelectionDialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure InfobaseConnectionDirectoryChoiceProcessing(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Object.InfobaseConnectionDirectory = SelectedFiles[0];
	
EndProcedure

&AtClient
Procedure ExchangeLogFileNameOpening(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ImportExchangeLogFileNameOpening(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure InfobaseConnectionDirectoryOpening(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure InfobaseConnectionWindowsAuthenticationOnChange(Item)

	Items.InfobaseConnectionUsername.Enabled = Not Object.InfobaseConnectionWindowsAuthentication;
	Items.InfobaseConnectionPassword.Enabled = Not Object.InfobaseConnectionWindowsAuthentication;

EndProcedure

&AtClient
Procedure RulesFileNameOnChange(Item)
	
	File = New File(RulesFileName);
	
	Notification = New NotifyDescription("RulesFileNameAfterExistenceCheck", ThisObject);
	File.BeginCheckingExistence(Notification);
	
EndProcedure

&AtClient
Procedure RulesFileNameAfterExistenceCheck(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		MessageToUser(NStr("ru = 'Не найден файл правил обмена'; en = 'Exchange rules file not found'"), "RulesFileName");
		SetImportRulesFlag(False);
		Return;
	EndIf;
	
	If RuleAndExchangeFileNamesMatch() Then
		Return;
	EndIf;
	
	NotifyDescription = New NotifyDescription("RulesFileNameOnChangeCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, NStr("ru = 'Загрузить правила обмена данными?'; en = 'Do you want to import data exchange rules?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure RulesFileNameOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		ExecuteImportExchangeRules();
		
	Else
		
		SetImportRulesFlag(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExchangeFileNameOpening(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExchangeFileNameOnChange(Item)
	
	ClearDataImportFileData();
	
EndProcedure

&AtClient
Procedure UseTransactionsOnChange(Item)
	
	ProcessTransactionManagementItemsEnabled();
	
EndProcedure

&AtClient
Procedure ImportHandlersDebugModeFlagOnChange(Item)
	
	SetDebugCommandsEnabled();
	
EndProcedure

&AtClient
Procedure ExportHandlerDebugModeFlagOnChange(Item)
	
	SetDebugCommandsEnabled();
	
EndProcedure

&AtClient
Procedure DataFileNameOpening(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DataFileNameOnChange(Item)
	
	If EmptyAttributeValue(DataFileName, "DataFileName", Items.DataFileName.Title)
		Or RuleAndExchangeFileNamesMatch() Then
		Return;
	EndIf;
	
	Object.ExchangeFileName = DataFileName;
	
	File = New File(Object.ExchangeFileName);
	Object.ArchiveFile = (Upper(File.Extension) = Upper(".zip"));
	
EndProcedure

&AtClient
Procedure ConnectedInfobaseTypeOnChange(Item)

	ConnectedInfobaseTypeOnValueChange();

EndProcedure

&AtClient
Procedure PlatformVersionForInfobaseConnectionOnChange(Item)

	If IsBlankString(Object.PlatformVersionForInfobaseConnection) Then

		Object.PlatformVersionForInfobaseConnection = "V8";

	EndIf;

EndProcedure

&AtClient
Procedure ChangesRegistrationDeletionTypeForExportedExchangeNodes(Элемент)

	OnChangeChangesRegistrationDeletionType();
	
EndProcedure

&AtClient
Procedure ExportPeriodOnChange(Item)
	
	OnPeriodChange();
	
EndProcedure

&AtClient
Procedure DeletionPeriodOnChange(Item)
	
	OnPeriodChange();
	
EndProcedure

&AtClient
Procedure SafeImportOnChange(Item)
	
	ChangeSafeImportMode();
	
EndProcedure

&AtClient
Procedure ImportRulesFileNameStartChoice(Item, ChoiceData, StandardProcessing)

	SelectFile(Item, ThisObject, "ImportRulesFileName", True, , False, True);
	
EndProcedure

&НаКлиенте
Процедура ImportRulesFileNameOnChange(Item)

	PutImportRulesFileInStorage();
	
EndProcedure

#EndRegion

#Region ExportRulesTableFormTableItemsEventHandlers

&AtClient
Procedure ExportRulesTableBeforeRowChange(Item, Cancel)
	
	If Item.CurrentItem.Name = "ExchangeNodeRef" Then
		
		If Item.CurrentData.IsFolder Then
			Cancel = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportRulesTableOnChange(Item)
	
	If Item.CurrentItem.Name = "DER" Then
		
		curRow = Item.CurrentData;
		
		If curRow.Check = 2 Then
			curRow.Check = 0;
		EndIf;

		SetChildMarks(curRow, "Check");
		SetParentMarks(curRow, "Check");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportRulesTableFilterStartChoice(Item, ChoiceData, StandardProcessing)

	CurrentRow = Items.ExportRulesTable.CurrentData;

	If CurrentRow = Undefined Then
		StandardProcessing = False;
		Return;
	EndIf;

	If CurrentRow.MetadataName = "" Then
		StandardProcessing = False;
		Return;
	EndIf;

	SettingsComposer = InitExportRulesFilterSettingsComposer(
		Items.ExportRulesTable.CurrentRow);
	CurrentRow.Filter = SettingsComposer.Settings.Filter;

EndProcedure
&AtClient
Procedure ExportRulesTableFilterOnChange(Item)
	CurrentRow = Items.ExportRulesTable.CurrentData;
	If CurrentRow.Filter.Items.Count() > 0 Then
		CurrentRow.UseFilter = True;
	Else
		CurrentRow.UseFilter = False;
	EndIf;
EndProcedure

&AtClient
Procedure ExportRulesTableFilterClearing(Item, StandardProcessing)
	CurrentRow = Items.ExportRulesTable.CurrentData;
	If CurrentRow.Filter.Items.Count() > 0 Then
		CurrentRow.UseFilter = True;
	Else
		CurrentRow.UseFilter = False;
	EndIf;
EndProcedure

#EndRegion

#Region DataToDeleteFormTableItemEventHandlers

&AtClient
Procedure DataToDeleteOnChange(Item)
	
	curRow = Item.CurrentData;
	
	SetChildMarks(curRow, "Check");
	SetParentMarks(curRow, "Check");

EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ConnectionTest(Command)
	
	EstablishConnectionWithDestinationIBAtServer();
	
EndProcedure

&AtClient
Procedure GetExchangeFileInfo(Command)
	
	FileAddress = "";
	
	If IsClient Then
		
		NotifyDescription = New NotifyDescription("GetExchangeFileInfoCompletion", ThisObject);
		BeginPutFile(NotifyDescription, FileAddress, , , UUID);
		
	Else
		
		GetExchangeFileInfoCompletion(True, FileAddress, "", Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetExchangeFileInfoCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		
		Try
			
			OpenImportFileAtServer(Address);
			ExportPeriodPresentation = PeriodPresentation(Object.StartDate, Object.EndDate);
			
		Except
			
			MessageToUser(NStr("ru = 'Не удалось прочитать файл обмена.'; en = 'Cannot read the exchange file.'"));
			ClearDataImportFileData();
			
		EndTry;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeletionCheckAll(Command)
	
	For Each Row In DataToDelete.GetItems() Do
		
		Row.Check = 1;
		SetChildMarks(Row, "Check");
		
	EndDo;
	
EndProcedure

&AtClient
Procedure DeletionUncheckAll(Command)
	
	For Each Row In DataToDelete.GetItems() Do
		Row.Check = 0;
		SetChildMarks(Row, "Check");
	EndDo;
	
EndProcedure

&AtClient
Procedure DeletionDelete(Command)
	
	NotifyDescription = New NotifyDescription("DeletionDeleteCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, NStr("ru = 'Удалить выбранные данные в информационной базе?'; en = 'Do you want to delete selected data?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure DeletionDeleteCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		DeleteAtServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportCheckAll(Command)

	For Each Row In Object.ExportRulesTable.GetItems() Do
		Row.Check = 1;
		SetChildMarks(Row, "Check");
	EndDo;
	
EndProcedure

&AtClient
Procedure ExportUncheckAll(Command)

	For Each Row In Object.ExportRulesTable.GetItems() Do
		Row.Check = 0;
		SetChildMarks(Row, "Check");
	EndDo;
	
EndProcedure

&AtClient
Procedure ExportUncheckAllExchangeNodes(Command)

	FillExchangeNodeInTreeRowsAtServer(Undefined);

EndProcedure

&AtClient
Procedure ExportSetExchangeNode(Command)

	If Items.ExportRulesTable.CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillExchangeNodeInTreeRowsAtServer(Items.ExportRulesTable.CurrentData.ExchangeNodeRef);

EndProcedure

&AtClient
Procedure SaveParameters(Command)
	
	SaveParametersAtServer();
	
EndProcedure

&AtClient
Procedure RestoreParameters(Command)
	
	RestoreParametersAtServer();
	
EndProcedure

&AtClient
Procedure ExportDebugSetup(Command)
	
	Object.ExchangeRulesFileName = FileNameAtServerOrClient(RulesFileName, RulesFileAddressInStorage);
	
	OpenHandlerDebugSetupForm(True);
	
EndProcedure

&AtClient
Procedure AtClient(Command)
	
	If Not IsClient Then
		
		IsClient = True;
		
		ChangeProcessingMode(IsClient);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AtServer(Command)
	
	If IsClient Then
		
		IsClient = False;
		
		ChangeProcessingMode(IsClient);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDebugSetup(Command)
	
	ExchangeFileAddressInStorage = "";
	FileNameForExtension = "";
	
	If IsClient Then
		
		NotifyDescription = New NotifyDescription("ImportDebugSetupCompletion", ThisObject);
		BeginPutFile(NotifyDescription, ExchangeFileAddressInStorage, , , UUID);

	Else
		
		If EmptyAttributeValue(ExchangeFileName, "ExchangeFileName", Items.ExchangeFileName.Title) Then
			Return;
		EndIf;
		
		ImportDebugSetupCompletion(True, ExchangeFileAddressInStorage, FileNameForExtension, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDebugSetupCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		
		Object.ExchangeFileName = FileNameAtServerOrClient(ExchangeFileName ,Address, SelectedFileName);
		
		OpenHandlerDebugSetupForm(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteExport(Command)
	
	ExecuteExportFromForm();
	
EndProcedure

&AtClient
Procedure ExecuteImport(Command)
	
	ExecuteImportFromForm();
	
EndProcedure

&AtClient
Procedure ReadExchangeRules(Command)
	
	If Not IsWindowsClient() AND DirectExport = 1 Then
		ShowMessageBox(,NStr("ru = 'Прямое подключение к информационной базе поддерживается только в клиенте под управлением ОС Windows.'; en = 'Direct connection to the infobase is available only on a client running Windows OS.'"));
		Return;
	EndIf;
	
	FileNameForExtension = "";
	
	If IsClient Then
		
		NotifyDescription = New NotifyDescription("ReadExchangeRulesCompletion", ThisObject);
		BeginPutFile(NotifyDescription, RulesFileAddressInStorage, , , UUID);
		
	Else
		
		RulesFileAddressInStorage = "";
		If EmptyAttributeValue(RulesFileName, "RulesFileName", Items.RulesFileName.Title) Then
			Return;
		EndIf;
		
		ReadExchangeRulesCompletion(True, RulesFileAddressInStorage, FileNameForExtension, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReadExchangeRulesCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		
		RulesFileAddressInStorage = Address;
		
		ExecuteImportExchangeRules(Address, SelectedFileName);
		
		If Object.ErrorFlag Then
			
			SetImportRulesFlag(False);
			
		Else
			
			SetImportRulesFlag(True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UT_WebServiceConnectionTest(Command)
	Path=Object.UT_DestinationPublicationAddress + "/hs/tools-ui-1c/exchange";

	AddlParameters=New Structure;
	AddlParameters.Insert("Timeout", 10);

	Authentication=New Structure;
	Authentication.Insert("Username", Object.InfobaseConnectionUsername);
	Authentication.Insert("Password", Object.InfobaseConnectionPassword);
	AddlParameters.Insert("Authentication", Authentication);

	Try
		ConnectionResult=UT_HTTPConnector.Get(Path, , AddlParameters);
		ConnectionResult=UT_HTTPConnector.AsText(ConnectionResult);
	Except
		ConnectionResult=Undefined;
		MessageToUser(ErrorDescription());
	EndTry;
	If ConnectionResult = "OK" Then
		ShowMessageBox( , NStr("ru = 'Тест подключения пройден успешно'; en = 'Connection success'"));
	EndIf;
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_ExecuteToolsCommonCommand(Command) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ThisObject, Command);
EndProcedure


#EndRegion

#Region Private

// Opens an exchange file in an external application.
//
// Parameters:
// 	- FileName - String - a file name.
//  - StandardProcessing - Boolean - a standard processing flag.
// 
&AtClient
Procedure OpenInApplication(FileName, StandardProcessing = False)
	
	StandardProcessing = False;
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("FileName", FileName);
	AdditionalParameters.Insert("NotifyDescription", New NotifyDescription);
	
	File = New File(FileName);

	NotifyDescription = New NotifyDescription("AfterDetermineFileExistence", ThisObject,
		AdditionalParameters);
	File.BeginCheckingExistence(NotifyDescription);

EndProcedure

// Continuation of the procedure (see above).
&AtClient
Procedure AfterDetermineFileExistence(Exists, AdditionalParameters) Export
	
	If Exists Then
		BeginRunningApplication(AdditionalParameters.NotifyDescription, AdditionalParameters.FileName);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearDataImportFileData()

	Object.ExchangeRulesVersion = "";
	Object.DataExportDate = "";
	ExportPeriodPresentation = "";

EndProcedure

&AtClient
Procedure ProcessTransactionManagementItemsEnabled()
	
	Items.UseTransactions.Enabled = Not Object.DebugModeFlag;
	
	Items.ObjectsPerTransaction.Enabled = Object.UseTransactions;
	
EndProcedure

&AtClient
Procedure ArchiveFileOnValueChange()
	
	If Object.ArchiveFile Then
		DataFileName = StrReplace(DataFileName, ".xml", ".zip");
	Else
		DataFileName = StrReplace(DataFileName, ".zip", ".xml");
	EndIf;
	
	Items.ExchangeFileCompressionPassword.Enabled = Object.ArchiveFile;
	
EndProcedure

&AtServer
Procedure FillExchangeNodeInTreeRows(Tree, ExchangeNode)
	
	For Each Row In Tree Do
		
		If Row.IsFolder Then
			
			FillExchangeNodeInTreeRows(Row.GetItems(), ExchangeNode);
			
		Else
			
			Row.ExchangeNodeRef = ExchangeNode;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Function RuleAndExchangeFileNamesMatch()
	
	If Upper(TrimAll(RulesFileName)) = Upper(TrimAll(DataFileName)) Then
		
		MessageToUser(NStr("ru = 'Файл правил обмена не может совпадать с файлом данных.
		|Выберите другой файл для выгрузки данных.'; 
		|en = 'Exchange rule file cannot match the data file.
		|Select another file to export the data to.'"));
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// Fills a value tree with metadata objects available for deletion
&AtServer
Procedure FillTypeAvailableToDeleteList()
	
	DataTree = FormAttributeToValue("DataToDelete");
	
	DataTree.Rows.Clear();
	
	TreeRow = DataTree.Rows.Add();
	TreeRow.Presentation = NStr("ru = 'Справочники'; en = 'Catalogs'");
	
	For each MetadataObject In Metadata.Catalogs Do
		
		If Not AccessRight("Delete", MetadataObject) Then
			Continue;
		EndIf;
		
		MDRow = TreeRow.Rows.Add();
		MDRow.Presentation = MetadataObject.Name;
		MDRow.Metadata = "CatalogRef." + MetadataObject.Name;
		
	EndDo;
	
	TreeRow = DataTree.Rows.Add();
	TreeRow.Presentation = NStr("ru = 'Планы видов характеристик'; en = 'Charts of characteristic types'");
	
	For each MetadataObject In Metadata.ChartsOfCharacteristicTypes Do
		
		If Not AccessRight("Delete", MetadataObject) Then
			Continue;
		EndIf;
		
		MDRow = TreeRow.Rows.Add();
		MDRow.Presentation = MetadataObject.Name;
		MDRow.Metadata = "ChartOfCharacteristicTypesRef." + MetadataObject.Name;
		
	EndDo;
	
	TreeRow = DataTree.Rows.Add();
	TreeRow.Presentation = NStr("ru = 'Документы'; en = 'Documents'");
	
	For each MetadataObject In Metadata.Documents Do
		
		If Not AccessRight("Delete", MetadataObject) Then
			Continue;
		EndIf;
		
		MDRow = TreeRow.Rows.Add();
		MDRow.Presentation = MetadataObject.Name;
		MDRow.Metadata = "DocumentRef." + MetadataObject.Name;
		
	EndDo;
	
	TreeRow = DataTree.Rows.Add();
	TreeRow.Presentation = "InformationRegisters";
	
	For each MetadataObject In Metadata.InformationRegisters Do
		
		If Not AccessRight("Update", MetadataObject) Then
			Continue;
		EndIf;
		
		Subordinate = (MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate);
		If Subordinate Then Continue EndIf;
		
		MDRow = TreeRow.Rows.Add();
		MDRow.Presentation = MetadataObject.Name;
		MDRow.Metadata = "InformationRegisterRecord." + MetadataObject.Name;
		
	EndDo;
	
	ValueToFormAttribute(DataTree, "DataToDelete");
	
EndProcedure

// Returns data processor version
&AtServer
Function ObjectVersionAsStringAtServer()
	
	Return FormAttributeToValue("Object").ObjectVersionAsString();
	
EndFunction

&AtClient
Procedure ExecuteImportExchangeRules(RulesFileAddressInStorage = "", FileNameForExtension = "")
	
	Object.ErrorFlag = False;
	
	ImportExchangeRulesAndParametersAtServer(RulesFileAddressInStorage, FileNameForExtension);
	
	If Object.ErrorFlag Then
		
		SetImportRulesFlag(False);
		
	Else
		
		SetImportRulesFlag(True);
		ExpandTreeRows(Object.ExportRulesTable, Items.ExportRulesTable, "Check");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandTreeRows(DataTree, PresentationOnForm, CheckBoxName)
	
	TreeRows = DataTree.GetItems();
	
	For Each Row In TreeRows Do
		
		RowID=Row.GetID();
		PresentationOnForm.Expand(RowID, False);
		EnableParentIfChildItemsEnabled(Row, CheckBoxName);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure EnableParentIfChildItemsEnabled(TreeRow, CheckBoxName)
	
	Enable = TreeRow[CheckBoxName];
	
	For Each ChildRow In TreeRow.GetItems() Do
		
		If ChildRow[CheckBoxName] = 1 Then
			
			Enable = 1;
			
		EndIf;
		
		If ChildRow.GetItems().Count() > 0 Then
			
			EnableParentIfChildItemsEnabled(ChildRow, CheckBoxName);
			
		EndIf;
		
	EndDo;
	
	TreeRow[CheckBoxName] = Enable;
	
EndProcedure

&AtClient
Procedure OnPeriodChange()
	
	Object.StartDate = ExportPeriod.StartDate;
	Object.EndDate = ExportPeriod.EndDate;
	
EndProcedure

&AtServer
Procedure ImportExchangeRulesAndParametersAtServer(RulesFileAddressInStorage, FileNameForExtension)

	ExchangeRulesFileName = FileNameAtServerOrClient(RulesFileName ,RulesFileAddressInStorage, FileNameForExtension);

	If ExchangeRulesFileName = Undefined Then
		
		Return;
		
	Else
		
		Object.ExchangeRulesFileName = ExchangeRulesFileName;
		
	EndIf;
	
	ObjectForServer = FormAttributeToValue("Object");
	ObjectForServer.ExportRulesTable = FormAttributeToValue("Object.ExportRulesTable");
	ObjectForServer.ParametersSettingsTable = FormAttributeToValue("Object.ParametersSettingsTable");

	ObjectForServer.ImportExchangeRules();
	ObjectForServer.InitializeInitialParameterValues();
	ObjectForServer.Parameters.Clear();
	Object.ErrorFlag = ObjectForServer.ErrorFlag;
	
	If IsClient Then
		
		DeleteFiles(Object.ExchangeRulesFileName);
		
	EndIf;

	ValueToFormAttribute(ObjectForServer.ExportRulesTable, "Object.ExportRulesTable");
	ValueToFormAttribute(ObjectForServer.ParametersSettingsTable, "Object.ParametersSettingsTable");

EndProcedure

// Opens file selection dialog.
//
&AtClient
Procedure SelectFile(Item, StorageObject, PropertyName, CheckForExistence, Val DefaultExtension = "xml",
	ArchiveDataFile = True, RulesFileSelection = False)

	FileSelectionDialog = New FileDialog(FileDialogMode.Open);

	If DefaultExtension = "txt" Then
		
		FileSelectionDialog.Filter = "Exchange log file (*.txt)|*.txt";
		FileSelectionDialog.DefaultExt = "txt";

	ElsIf Object.ExchangeMode = "Export" Then

		If ArchiveDataFile Then
			
			FileSelectionDialog.Filter = "Archive data file (*.zip)|*.zip";
			FileSelectionDialog.DefaultExt = "zip";

		ElsIf RulesFileSelection Then
			
			FileSelectionDialog.Filter = "Data file (*.xml)|*.xml|Archive data file (*.zip)|*.zip";
			FileSelectionDialog.DefaultExt = "xml";

		Else
			
			FileSelectionDialog.Filter = "Data file (*.xml)|*.xml";
			FileSelectionDialog.DefaultExt = "xml";
			
		EndIf;

	Else
		If RulesFileSelection Then
			FileSelectionDialog.Filter = "Data file (*.xml)|*.xml";
			FileSelectionDialog.DefaultExt = "xml";
		Else
			FileSelectionDialog.Filter = "Data file (*.xml)|*.xml|Archive data file (*.zip)|*.zip";
			FileSelectionDialog.DefaultExt = "xml";
		EndIf;
	EndIf;

	FileSelectionDialog.Title = NStr("ru = 'Выберите файл'; en = 'Select file'");
	FileSelectionDialog.Preview = False;
	FileSelectionDialog.FilterIndex = 0;
	FileSelectionDialog.FullFileName = Item.EditText;
	FileSelectionDialog.CheckFileExist = CheckForExistence;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StorageObject", StorageObject);
	AdditionalParameters.Insert("PropertyName",    PropertyName);
	AdditionalParameters.Insert("Item",        Item);
	
	Notification = New NotifyDescription("FileSelectionDialogChoiceProcessing", ThisObject, AdditionalParameters);
	FileSelectionDialog.Show(Notification);
	
EndProcedure

// Parameters:
//   SelectedFiles - Array
//   	- String - a file selection result.
//   AdditionalParameters - Structure - an arbitrary additional parameters:
//     * StorageObject - Structure, ClientApplicationForm - an object to store the properties.
//     * PropertyName - String - a storage object property name.
//     * Item - FormField - a file selection event source.
//
&AtClient
Procedure FileSelectionDialogChoiceProcessing(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.StorageObject[AdditionalParameters.PropertyName] = SelectedFiles[0];
	
	Item = AdditionalParameters.Item;
	
	If Item = Items.RulesFileName Then
		RulesFileNameOnChange(Item);
	ElsIf Item = Items.ExchangeFileName Then
		ExchangeFileNameOnChange(Item);
	ElsIf Item = Items.DataFileName Then
		DataFileNameOnChange(Item);
	ElsIf Item = Items.ImportRulesFileName Then
		ImportRulesFileNameOnChange(Item);
	EndIf;

EndProcedure

&AtServer
Procedure EstablishConnectionWithDestinationIBAtServer()
	
	ObjectForServer = FormAttributeToValue("Object");
	FillPropertyValues(ObjectForServer, Object);
	ConnectionResult = ObjectForServer.EstablishConnectionWithDestinationIB();
	
	If ConnectionResult <> Undefined Then
		
		MessageToUser(NStr("ru = 'Подключение успешно установлено.'; en = 'Connection established.'"));
		
	EndIf;
	
EndProcedure

// Sets mark value in child tree rows according to the mark value in the current row.
// 
//
// Parameters:
//  CurRow      - a value tree row.
//  CheckBoxName - a checkbox name in the tree.
// 
&AtClient
Procedure SetChildMarks(curRow, CheckBoxName)
	
	ChildElements = curRow.GetItems();
	
	If ChildElements.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Row In ChildElements Do
		
		Row[CheckBoxName] = curRow[CheckBoxName];
		
		SetChildMarks(Row, CheckBoxName);
		
	EndDo;
		
EndProcedure

// Sets mark values in parent tree rows according to the mark value in the current row.
// 
//
// Parameters:
//  CurRow      - a value tree row.
//  CheckBoxName - a checkbox name in the tree.
// 
&AtClient
Procedure SetParentMarks(curRow, CheckBoxName)
	
	Parent = curRow.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf; 
	
	CurState = Parent[CheckBoxName];
	
	EnabledItemsFound  = False;
	DisabledItemsFound = False;
	
	For Each Row In Parent.GetItems() Do
		If Row[CheckBoxName] = 0 Then
			DisabledItemsFound = True;
		ElsIf Row[CheckBoxName] = 1
			Or Row[CheckBoxName] = 2 Then
			EnabledItemsFound  = True;
		EndIf; 
		If EnabledItemsFound And DisabledItemsFound Then
			Break;
		EndIf; 
	EndDo;
	
	If EnabledItemsFound And DisabledItemsFound Then
		Enable = 2;
	ElsIf EnabledItemsFound And (Not DisabledItemsFound) Then
		Enable = 1;
	ElsIf (Not EnabledItemsFound) And DisabledItemsFound Then
		Enable = 0;
	ElsIf (Not EnabledItemsFound) And (Not DisabledItemsFound) Then
		Enable = 2;
	EndIf;
	
	If Enable = CurState Then
		Return;
	Else
		Parent[CheckBoxName] = Enable;
		SetParentMarks(Parent, CheckBoxName);
	EndIf; 
	
EndProcedure

&AtServer
Procedure OpenImportFileAtServer(FileAddress)
	
	If IsClient Then
		
		BinaryData = GetFromTempStorage (FileAddress);
		AddressOnServer = GetTempFileName(".xml");
		// Temporary file is deleted not via DeleteFiles(AddressOnServer), but via
		// DeleteFiles(Object.ExchangeFileName) below.
		BinaryData.Write(AddressOnServer);
		Object.ExchangeFileName = AddressOnServer;
		
	Else
		
		FileOnServer = New File(ExchangeFileName);
		
		If Not FileOnServer.Exist() Then
			
			MessageToUser(NStr("ru = 'Не найден файл обмена на сервере.'; en = 'Exchange file not found on the server.'"), "ExchangeFileName");
			Return;
			
		EndIf;
		
		Object.ExchangeFileName = ExchangeFileName;
		
	EndIf;
	
	ObjectForServer = FormAttributeToValue("Object");
	
	ObjectForServer.OpenImportFile(True);
	
	Object.StartDate = ObjectForServer.StartDate;
	Object.EndDate = ObjectForServer.EndDate;
	Object.DataExportDate = ObjectForServer.DataExportDate;
	Object.ExchangeRulesVersion = ObjectForServer.ExchangeRulesVersion;
	Object.Comment = ObjectForServer.Comment;
	
EndProcedure

// Deletes marked metadata tree rows.
//
&AtServer
Procedure DeleteAtServer()
	
	ObjectForServer = FormAttributeToValue("Object");
	DataToDeleteTree = FormAttributeToValue("DataToDelete");
	
	ObjectForServer.InitManagersAndMessages();
	
	For Each TreeRow In DataToDeleteTree.Rows Do
		
		For Each MDRow In TreeRow.Rows Do
			
			If Not MDRow.Check Then
				Continue;
			EndIf;
			
			TypeString = MDRow.Metadata;
			ObjectForServer.DeleteObjectsOfType(TypeString);
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Sets an exchange node at tree rows.
//
&AtServer
Procedure FillExchangeNodeInTreeRowsAtServer(ExchangeNode)
	
	FillExchangeNodeInTreeRows(Object.ExportRulesTable.GetItems(), ExchangeNode);
	
EndProcedure

// Saves parameter values.
//
&AtServer
Procedure SaveParametersAtServer()
	
	ParametersTable = FormAttributeToValue("Object.ParametersSettingsTable");

	SavedParameters = New Map;
	
	For Each TableRow In ParametersTable Do
		SavedParameters.Insert(TableRow.Description, TableRow.Value);
	EndDo;
	
	SystemSettingsStorage.Save("UniversalDataExchangeXML", "Parameters", SavedParameters);
	
EndProcedure

// Restores parameter values
//
&AtServer
Procedure RestoreParametersAtServer()
	
	ParametersTable = FormAttributeToValue("Object.ParametersSettingsTable");
	RestoredParameters = SystemSettingsStorage.Load("UniversalDataExchangeXML", "Parameters");
	
	If TypeOf(RestoredParameters) <> Type("Map") Then
		Return;
	EndIf;
	
	If RestoredParameters.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Param In RestoredParameters Do
		
		ParameterName = Param.Key;
		
		TableRow = ParametersTable.Find(Param.Key, "Description");
		
		If TableRow <> Undefined Then
			
			TableRow.Value = Param.Value;
			
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(ParametersTable, "Object.ParametersSettingsTable");

EndProcedure

// Performs interactive data export.
//
&AtClient
Procedure ExecuteImportFromForm()
	
	FileAddress = "";
	FileNameForExtension = "";
	
	AddRowToChoiceList(Items.ExchangeFileName.ChoiceList, ExchangeFileName, DataImportFromFile);
	
	If IsClient Then
		
		NotifyDescription = New NotifyDescription("ExecuteImportFromFormCompletion", ThisObject);
		BeginPutFile(NotifyDescription, FileAddress, , , UUID);

	Else
		
		If EmptyAttributeValue(ExchangeFileName, "ExchangeFileName", Items.ExchangeFileName.Title) Then
			Return;
		EndIf;
		
		ExecuteImportFromFormCompletion(True, FileAddress, FileNameForExtension, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteImportFromFormCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		
		ExecuteImportAtServer(Address, SelectedFileName);
		
		OpenExchangeLogDataIfNecessary();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteImportAtServer(FileAddress, FileNameForExtension)
	
	FileToImportName = FileNameAtServerOrClient(ExchangeFileName ,FileAddress, FileNameForExtension);
	
	If FileToImportName = Undefined Then
		
		Return;
		
	Else
		
		Object.ExchangeFileName = FileToImportName;
		
	EndIf;
	
	If Object.SafeImport Then
		If IsTempStorageURL(ImportRulesFileAddressInStorage) Then
			BinaryData = GetFromTempStorage(ImportRulesFileAddressInStorage);
			AddressOnServer = GetTempFileName("xml");
			// Temporary file is deleted not via DeleteFiles(AddressOnServer), but via
			// DeleteFiles(Object.ExchangeRuleFileName) below.
			BinaryData.Write(AddressOnServer);
			Object.ExchangeRulesFileName = AddressOnServer;
		Else
			MessageToUser(NStr("ru = 'Не указан файл правил для загрузки данных.'; en = 'File of data import rules is not specified.'"));
			Return;
		EndIf;
	EndIf;
	
	ObjectForServer = FormAttributeToValue("Object");
	FillPropertyValues(ObjectForServer, Object);
	ObjectForServer.ExecuteImport();
	
	Try
		
		If Not IsBlankString(FileAddress) Then
			DeleteFiles(FileToImportName);
		EndIf;
		
	Except
		WriteLogEvent(NStr("ru = 'Универсальный обмен данными в формате XML'; en = 'Universal data exchange in XML format'", ObjectForServer.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	ObjectForServer.Parameters.Clear();
	ValueToFormAttribute(ObjectForServer, "Object");
	
	RulesAreImported = False;
	Items.FormExecuteExport.Enabled = False;
	Items.ExportNoteLabel.Visible = True;
	Items.ExportDebugAvailableGroup.Enabled = False;
	
EndProcedure

&AtServer
Function FileNameAtServerOrClient(AttributeName ,Val FileAddress, Val FileNameForExtension = ".xml",
	CreateNew = False, CheckForExistence = True)
	
	FileName = Undefined;
	
	If IsClient Then
		
		If CreateNew Then
			
			Extension = ? (Object.ArchiveFile, ".zip", ".xml");
			
			FileName = GetTempFileName(Extension);
			
		Else
			
			Extension = FileExtention(FileNameForExtension);
			BinaryData = GetFromTempStorage(FileAddress);
			AddressOnServer = GetTempFileName(Extension);
			// The temporary file is deleted not via the DeleteFiles(AddressOnServer), but via 
			// DeleteFiles(Object.ExchangeRulesFileName) and DeleteFiles(Object.ExchangeFileName) below.
			BinaryData.Write(AddressOnServer);
			FileName = AddressOnServer;
			
		EndIf;
		
	Else
		
		FileOnServer = New File(AttributeName);
		
		If Not FileOnServer.Exist() And CheckForExistence Then
			
			MessageToUser(NStr("ru = 'Указанный файл не существует.'; en = 'The file does not exist.'"));
			
		Else
			
			FileName = AttributeName;
			
		EndIf;
		
	EndIf;
	
	Return FileName;
	
EndFunction

&AtServer
Function FileExtention(Val FileName)
	
	PointPosition = LastSeparator(FileName);
	
	Extension = Right(FileName,StrLen(FileName) - PointPosition + 1);
	
	Return Extension;
	
EndFunction

&AtServer
Function LastSeparator(StringWithSeparator, Separator = ".")
	
	StringLength = StrLen(StringWithSeparator);
	
	While StringLength > 0 Do
		
		If Mid(StringWithSeparator, StringLength, 1) = Separator Then
			
			Return StringLength; 
			
		EndIf;
		
		StringLength = StringLength - 1;
		
	EndDo;

EndFunction

&AtClient
Procedure ExecuteExportFromForm()
	
	// Adding rule file name and data file name to the selection list.
	AddRowToChoiceList(Items.RulesFileName.ChoiceList, RulesFileName, ExchangeRules);
	
	If Not Object.DirectReadFromDestinationIB And Not IsClient Then
		
		If RuleAndExchangeFileNamesMatch() Then
			Return;
		EndIf;
		
		AddRowToChoiceList(Items.DataFileName.ChoiceList, DataFileName, DataExportToFile);
		
	EndIf;
	
	DataFileAddressInStorage = ExecuteExportAtServer();
	
	If DataFileAddressInStorage = Undefined Then
		Return;
	EndIf;
	
	ExpandTreeRows(Object.ExportRulesTable, Items.ExportRulesTable, "Check");

	If IsClient And Not DirectExport And Not Object.ErrorFlag Then
		
		FileToSaveName = ?(Object.ArchiveFile, NStr("ru = 'Файл выгрузки.zip'; en = 'Export file.zip'"),NStr("ru = 'Файл выгрузки.xml'; en = 'Export file.xml'"));
		
		GetFile(DataFileAddressInStorage, FileToSaveName)
		
	EndIf;
	
	OpenExchangeLogDataIfNecessary();
	
EndProcedure

&AtServer
Function ExecuteExportAtServer()
	
	Object.ExchangeRulesFileName = FileNameAtServerOrClient(RulesFileName, RulesFileAddressInStorage);
	
	If Not DirectExport Then
		
		TempDataFileName = FileNameAtServerOrClient(DataFileName, "",,True, False);
		
		If TempDataFileName = Undefined Then
			
			MessageToUser(NStr("ru = 'Не определен файл данных'; en = 'Data file not specified'"));
			Return Undefined;
			
		Else
			
			Object.ExchangeFileName = TempDataFileName;
			
		EndIf;
	//UT++
	ElsIf DirectExport = 2 Then
		TempDataFileName=GetTempFileName(".xml");
		Object.ExchangeFileName = TempDataFileName;
		Object.UT_ExportViaWebService=True;
	//UT--

	EndIf;

	ExportRulesTable = FormAttributeToValue("Object.ExportRulesTable");
	ParametersSettingsTable = FormAttributeToValue("Object.ParametersSettingsTable");

	ObjectForServer = FormAttributeToValue("Object");
	FillPropertyValues(ObjectForServer, Object);
	
	If ObjectForServer.HandlersDebugModeFlag Then
		
		Cancel = False;
		
		File = New File(ObjectForServer.EventHandlerExternalDataProcessorFileName);
		
		If Not File.Exist() Then
			
			MessageToUser(NStr("ru = 'Файл внешней обработки отладчиков событий не существует на сервере'; en = 'Event debugger external data processor file does not exist on the server'"));
			Return Undefined;
			
		EndIf;
		
		ObjectForServer.ExportEventHandlers(Cancel);
		
		If Cancel Then
			
			MessageToUser(NStr("ru = 'Не удалось выгрузить обработчики событий'; en = 'Cannot export event handlers'"));
			Return "";
			
		EndIf;
		
	Else
		
		ObjectForServer.ImportExchangeRules();
		ObjectForServer.InitializeInitialParameterValues();
		
	EndIf;

	ChangeExportRulesTree(ObjectForServer.ExportRulesTable.Rows, ExportRulesTable.Rows);
	ChangeParametersTable(ObjectForServer.ParametersSettingsTable, ParametersSettingsTable);

	ObjectForServer.ExecuteExport();
	ObjectForServer.ExportRulesTable = FormAttributeToValue("Object.ExportRulesTable");

	If IsClient AND Not DirectExport Then
		
		DataFileAddress = PutToTempStorage(New BinaryData(Object.ExchangeFileName), UUID);
		DeleteFiles(Object.ExchangeFileName);
	
	//UT++
	ElsIf DirectExport = 2 Then
		DataFileAddress = "";
		DeleteFiles(Object.ExchangeFileName);
			
	//УИ--	

	Else
		
		DataFileAddress = "";
		
	EndIf;
	
	If IsClient Then
		
		DeleteFiles(ObjectForServer.ExchangeRulesFileName);

	EndIf;

	ObjectForServer.Parameters.Clear();
	ValueToFormAttribute(ObjectForServer, "Object");
	
	Return DataFileAddress;
	
EndFunction

&AtClient
Procedure SetDebugCommandsEnabled()
	
	Items.ImportDebugSetup.Enabled = Object.HandlersDebugModeFlag;
	Items.ExportDebugSetup.Enabled = Object.HandlersDebugModeFlag;
	
EndProcedure

// Modifies a DER tree according to the tree specified in the form
//
&AtServer
Procedure ChangeExportRulesTree(SourceTreeRows, TreeToReplaceRows)

	CheckColumn = TreeToReplaceRows.UnloadColumn("Check");
	SourceTreeRows.LoadColumn(CheckColumn, "Check");
	NodeColumn = TreeToReplaceRows.UnloadColumn("ExchangeNodeRef");
	SourceTreeRows.LoadColumn(NodeColumn, "ExchangeNodeRef");

	UseFilterColumn = TreeToReplaceRows.UnloadColumn("UseFilter");
	SourceTreeRows.LoadColumn(UseFilterColumn, "UseFilter");

	FilterColumn = TreeToReplaceRows.UnloadColumn("Filter");
	SourceTreeRows.LoadColumn(FilterColumn, "Filter");

	MetadataNameColumn = TreeToReplaceRows.UnloadColumn("MetadataName");
	SourceTreeRows.LoadColumn(MetadataNameColumn, "MetadataName");
	For Each SourceTreeRow In SourceTreeRows Do
		
		RowIndex = SourceTreeRows.IndexOf(SourceTreeRow);
		TreeToChangeRow = TreeToReplaceRows.Get(RowIndex);
		
		ChangeExportRulesTree(SourceTreeRow.Rows, TreeToChangeRow.Rows);
		
	EndDo;
	
EndProcedure

// Changed parameter table according the table in the form.
//
&AtServer
Procedure ChangeParametersTable(BaseTable, FormTable)
	
	DescriptionColumn = FormTable.UnloadColumn("Description");
	BaseTable.LoadColumn(DescriptionColumn, "Description");
	ValueColumn = FormTable.UnloadColumn("Value");
	BaseTable.LoadColumn(ValueColumn, "Value");
	
EndProcedure

&AtClient
Procedure DirectExportOnValueChange()
	
	ExportParameters = Items.ExportParameters;
	
	//UT++
//	ExportParameters.CurrentPage = ?(DirectExport = 0,
//										  ExportParameters.ChildItems.ExportToFile,
//										  ExportParameters.ChildItems.ExportToDestinationIB);
	If DirectExport = 0 Then
		ExportParameters.CurrentPage=ExportParameters.ChildItems.ExportToFile;
	ElsIf DirectExport = 1 Then
		ExportParameters.CurrentPage=ExportParameters.ChildItems.ExportToDestinationIB;
	Else
		ExportParameters.CurrentPage=ExportParameters.ChildItems.UT_ExportViaWebServiceGroup;
	EndIf;

	Object.UT_ExportViaWebService=(DirectExport = 2);
	//UT--

	Object.DirectReadFromDestinationIB = (DirectExport = 1);

	ConnectedInfobaseTypeOnValueChange();

EndProcedure

&AtClient
Procedure ConnectedInfobaseTypeOnValueChange()
	
	InfobaseType = Items.InfobaseType;
	InfobaseType.CurrentPage = ?(Object.ConnectedInfobaseType, InfobaseType.ChildItems.FileInfobase,
								InfobaseType.ChildItems.ServerInfobase);
	
EndProcedure

&AtClient
Procedure AddRowToChoiceList(ValueListToSave, SavingValue, ParameterNameToSave)
	
	If IsBlankString(SavingValue) Then
		Return;
	EndIf;
	
	FoundItem = ValueListToSave.FindByValue(SavingValue);
	If FoundItem <> Undefined Then
		ValueListToSave.Delete(FoundItem);
	EndIf;
	
	ValueListToSave.Insert(0, SavingValue);
	
	While ValueListToSave.Count() > 10 Do
		ValueListToSave.Delete(ValueListToSave.Count() - 1);
	EndDo;
	
	ParameterNameToSave = ValueListToSave;
	
EndProcedure

&AtClient
Procedure OpenHandlerDebugSetupForm(EventHandlersFromRulesFile)

	DataProcessorName = Left(FormName, LastSeparator(FormName));
	FormNameToCall = DataProcessorName + "HandlerDebugSetupManagedForm";
	
	FormParameters = New Structure;
	FormParameters.Insert("EventHandlerExternalDataProcessorFileName", Object.EventHandlerExternalDataProcessorFileName);
	FormParameters.Insert("AlgorithmsDebugMode", Object.AlgorithmDebugMode);
	FormParameters.Insert("ExchangeRulesFileName", Object.ExchangeRulesFileName);
	FormParameters.Insert("ExchangeFileName", Object.ExchangeFileName);
	FormParameters.Insert("ReadEventHandlersFromExchangeRulesFile", EventHandlersFromRulesFile);
	FormParameters.Insert("DataProcessorName", DataProcessorName);

	Mode = FormWindowOpeningMode.LockOwnerWindow;
	Handler = New NotifyDescription("OpenHandlerDebugSetupFormCompletion", ThisObject, EventHandlersFromRulesFile);
	
	OpenForm(FormNameToCall, FormParameters, ThisObject,,,,Handler, Mode);
	
EndProcedure

&AtClient
Procedure OpenHandlerDebugSetupFormCompletion(DebugParameters, EventHandlersFromRulesFile) Export
	
	If DebugParameters <> Undefined Then
		
		FillPropertyValues(Object, DebugParameters);
		
		If IsClient Then
			
			If EventHandlersFromRulesFile Then
				
				FileName = Object.ExchangeRulesFileName;
				
			Else
				
				FileName = Object.ExchangeFileName;
				
			EndIf;
			
			Notification = New NotifyDescription("OpenHandlersDebugSettingsFormCompletionFileDeletion", ThisObject);
			BeginDeletingFiles(Notification, FileName);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenHandlersDebugSettingsFormCompletionFileDeletion(AdditionalParameters) Export
	
	Return;
	
EndProcedure

&AtClient
Procedure ChangeFileLocation()
	
	Items.RulesFileName.Visible = Not IsClient;
	Items.DataFileName.Visible = Not IsClient;
	Items.ExchangeFileName.Visible = Not IsClient;
	Items.SafeImportGroup.Visible = Not IsClient;
	
	SetImportRulesFlag(False);
	
EndProcedure

&AtClient
Procedure ChangeProcessingMode(RunMode)
	
	ModeGroup = CommandBar.ChildItems.ProcessingMode.ChildItems;
	
	ModeGroup.FormAtClient.Check = RunMode;
	ModeGroup.FormAtServer.Check = Not RunMode;
	
	CommandBar.ChildItems.ProcessingMode.Title = 
	?(RunMode, NStr("ru = 'Режим работы (на клиенте)'; en = 'Mode (client)'"), NStr("ru = 'Режим работы (на сервере)'; en = 'Mode (server)'"));
	
	Object.ExportRulesTable.GetItems().Clear();
	Object.ParametersSettingsTable.Clear();

	ChangeFileLocation();

EndProcedure

&AtClient
Procedure OpenExchangeLogDataIfNecessary()
	
	If Not Object.OpenExchangeLogAfterExecutingOperations Then
		Return;
	EndIf;
	
#If Not WebClient Then
		
	If Not IsBlankString(Object.ExchangeLogFileName) Then
		OpenInApplication(Object.ExchangeLogFileName);
	EndIf;

	If Object.DirectReadFromDestinationIB Then

		Object.ImportExchangeLogFileName = GetLogNameForSecondCOMConnectionInfobaseAtServer();

		If Not IsBlankString(Object.ImportExchangeLogFileName) Then
			OpenInApplication(Object.ImportExchangeLogFileName);
		EndIf;

	EndIf;

#EndIf

EndProcedure

&AtServer
Function GetLogNameForSecondCOMConnectionInfobaseAtServer()

	Return FormAttributeToValue("Object").GetLogNameForCOMConnectionSecondInfobase();

EndFunction

&AtClient
Function EmptyAttributeValue(Attribute, DataPath, Title)
	
	If IsBlankString(Attribute) Then
		
		MessageText = NStr("ru = 'Поле ""%1"" не заполнено'; en = 'Field ""%1"" is blank'");
		MessageText = StrReplace(MessageText, "%1", Title);
		
		MessageToUser(MessageText, DataPath);
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

&AtClient
Procedure SetImportRulesFlag(Flag)
	
	RulesAreImported = Flag;
	Items.FormExecuteExport.Enabled = Flag;
	Items.ExportNoteLabel.Visible = Not Flag;
	Items.ExportDebugGroup.Enabled = Flag;
	
EndProcedure

&AtClient
Procedure OnChangeChangesRegistrationDeletionType()
	
	If IsBlankString(ChangesRegistrationDeletionTypeForExportedExchangeNodes) Then
		Object.ChangesRegistrationDeletionTypeForExportedExchangeNodes = 0;
	Else
		Object.ChangesRegistrationDeletionTypeForExportedExchangeNodes = Number(ChangesRegistrationDeletionTypeForExportedExchangeNodes);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure MessageToUser(Text, DataPath = "")
	
	Message = New UserMessage;
	Message.Text = Text;
	Message.DataPath = DataPath;
	Message.Message();
	
EndProcedure

// Returns True if the client application is running on Windows.
//
&AtClient
Function IsWindowsClient()
	
	SystemInfo = New SystemInfo;
	
	IsWindowsClient = SystemInfo.PlatformType = PlatformType.Windows_x86
	             OR SystemInfo.PlatformType = PlatformType.Windows_x86_64;
	
	Return IsWindowsClient;
	
EndFunction

&AtServer
Procedure CheckPlatformVersionAndCompatibilityMode()
	
	Information = New SystemInfo;
	If Not (Left(Information.AppVersion, 3) = "8.3"
		And (Metadata.CompatibilityMode = Metadata.ObjectProperties.CompatibilityMode.DontUse
		Or (Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_1
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_2_13
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_2_16"]
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_1"]
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_2"]))) Then
		
		Raise NStr("ru = 'Обработка предназначена для запуска на версии платформы
			|1С:Предприятие 8.3 с отключенным режимом совместимости или выше'; 
			|en = 'The data processor is intended for use with 
			|1C:Enterprise 8.3 or later, with disabled compatibility mode'");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeSafeImportMode(Interactively = True)
	
	Items.SafeImportGroup.Enabled = Object.SafeImport;
	
	ThroughStorage = IsClient;
	#If WebClient Then
		ThroughStorage = True;
	#EndIf
	
	If Object.SafeImport AND ThroughStorage Then
		PutImportRulesFileInStorage();
	EndIf;
	
EndProcedure

&AtClient
Procedure PutImportRulesFileInStorage()
	
	ThroughStorage = IsClient;
	#If WebClient Then
		ThroughStorage = True;
	#EndIf
	
	FileAddress = "";
	NotifyDescription = New NotifyDescription("PutImportRulesFileInStorageCompletion", ThisObject);

	If ThroughStorage Then
		BeginPutFile(NotifyDescription, FileAddress, , , UUID);
	Else
		BeginPutFile(NotifyDescription, FileAddress, ImportRulesFileName, False, UUID);
	EndIf;

EndProcedure

&AtClient
Procedure PutImportRulesFileInStorageCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		ImportRulesFileAddressInStorage = Address;
	EndIf;
	
EndProcedure
&AtServer
Function InitExportRulesFilterSettingsComposer(Val RowIndex = Undefined,
	Val MetadataTreeRow = Undefined)

	If MetadataTreeRow = Undefined Then
		MetadataTreeRow = Object.ExportRulesTable.FindByID(RowIndex);
	EndIf;

	DataProcessorObject = FormAttributeToValue("Object");
	QueryText = DataProcessorObject.GetRowQueryText(MetadataTreeRow, False);
	DataCompositionSchema = DataProcessorObject.DataCompositionSchema(QueryText);
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(PutToTempStorage(
		DataCompositionSchema, UUID)));
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);

	AdditionalFiltersExists  = MetadataTreeRow.Filter.Items.Count() <> 0;

	If AdditionalFiltersExists Then
		UT_CommonClientServer.CopyItems(SettingsComposer.Settings.Filter,
			MetadataTreeRow.Filter);
	EndIf;

	Return SettingsComposer;

EndFunction
#EndRegion