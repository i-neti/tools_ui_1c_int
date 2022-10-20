#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	FilterBySettingsStorages.Add("FormDataSettingsStorage", NStr("ru = 'Хранилище настроек данных форм';en = 'Form data settings storage'"));
	FilterBySettingsStorages.Add("CommonSettingsStorage", NStr("ru = 'Хранилище общих настроек';en = 'Common settings storage'"));
	FilterBySettingsStorages.Add("DynamicListsUserSettingsStorage", NStr(
		"ru = 'Хранилище пользовательских настроек динамических списков';en = 'Dynamic lists user settings storage'"));
	FilterBySettingsStorages.Add("ReportsUserSettingsStorage", NStr(
		"ru = 'Хранилище пользовательских настроек отчетов';en = 'Reports user settings storage'"));
	FilterBySettingsStorages.Add("SystemSettingsStorage", NStr("ru = 'Хранилище системных настроек';en = 'System settings storage'"));

	UpdateUsersTable();
	
	UT_Common.ToolFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
		
	// Initial filling of settings tree
	UpdateOwnerSettings(Undefined);
	
	// Managing the appearance of the form
	UpdateItemsPresentation();

	Items.SelectedSettingsTable.RowFilter = New FixedStructure("Check", True);

EndProcedure

&AtClient
Procedure UpdateOwnerSettings(Command)

	UpdateOwnerSettingsAtServer();

	Items.ConfigurationTree.Expand(
		ConfigurationTree.GetItems()[0].GetID());

EndProcedure

&AtClient
Procedure ConfigurationObjectsRepresentationVariantOnChange(Item)
	
	UpdateItemsPresentation(Item.Name);
	UpdateOwnerSettings(Undefined);
	
EndProcedure

&AtClient
Procedure ConfigurationTreeCheckOnChange(Item)
	CurrentData = Items.ConfigurationTree.CurrentData;
	CheckManagement(CurrentData);
EndProcedure

&AtClient
Procedure ConfigurationTreeOnActivateRow(Item)
	CurrentData = Items.ConfigurationTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	Items.SettingsTable.RowFilter = ?(CurrentData.FilterID = 0, Undefined,
		New FixedStructure("FilterID" + CurrentData.Level, CurrentData.FilterID));

EndProcedure

&AtClient
Procedure DeselectSetting(Command)

	For Each SelectedRow In Items.SelectedSettingsTable.SelectedRows Do

		String = SettingsTable.FindByID(SelectedRow);
		If String <> Undefined Then
			String.Check = False;
		EndIf;

	EndDo;

EndProcedure

&AtClient
Procedure SettingsTableCheckOnChange(Item)
		TreeRow = Items.ConfigurationTree.CurrentData;
	If TreeRow = Undefined Then
		Return;
	EndIf;

	FilterParameters = New Structure;
	FilterParameters.Insert("FilterID" + TreeRow.Level, TreeRow.FilterID);
	FoundedRows = SettingsTable.FindRows(FilterParameters);
	If FoundedRows <> Undefined Then
		SettingsCount = FoundedRows.Count();
	EndIf;

	FilterParameters.Insert("Check", True);
	FoundedRows = SettingsTable.FindRows(FilterParameters);
	If FoundedRows <> Undefined Then
		ChecksCount = FoundedRows.Count();
	EndIf;

	If ChecksCount = 0 Then
		TreeRow.Check = 0;
	ElsIf ChecksCount <> SettingsCount Then
		TreeRow.Check = 2;
	Else
		TreeRow.Check = 1;
	EndIf;

	CheckManagement(TreeRow, False);
EndProcedure

&AtClient
Procedure SettingsTableSettingsAdditionalOpening(Item, StandardProcessing)
		StandardProcessing = False;

	CurrentData = Items.SettingsTable.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	ViewSettingsAtServer(CurrentData.SettingsStorageName, CurrentData.ObjectKey, CurrentData.SettingsKey,
		SettingsOwner);
EndProcedure

&AtClient
Procedure ShowSelectedSettings(Command)
	Items.ConfigurationTreeShowSelectedSettings.Check = Not Items.ConfigurationTreeShowSelectedSettings.Check;
	UpdateItemsPresentation("ShowSelectedSettings");
EndProcedure

&AtClient
Procedure SettingsOwnerOnChange(Item)
	UpdateOwnerSettings(Undefined);
EndProcedure

&AtClient
Procedure SettingsOwnerClearing(Item, StandardProcessing)
	UpdateOwnerSettings(Undefined);
EndProcedure

&AtClient
Procedure ShowSelectedUsers(Command)
	Items.CancelSearchShowSelectedUsers.Check = Not Items.CancelSearchShowSelectedUsers.Check;
	UpdateItemsPresentation("ShowSelectedUsers");
EndProcedure

&AtClient
Procedure UsersTableCheckOnChange(Item)
		CurrentData = Items.Users.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	If CurrentData.Check Then
		CurrentData.Check = False;
	EndIf;
EndProcedure

&AtClient
Procedure DeleteSelectedSettings(Command)
	
	// Checks
	HaveError = False;
	Filter = New Structure("Check", True);
	FoundedRows = SettingsTable.FindRows(Filter);
	If FoundedRows.Count() = 0 Then
		UT_CommonClientServer.MessageToUser(NStr("ru = 'Не выбраны настройки для удаления';en = 'Not selected settings to delete'"), , , ,
			HaveError);
	EndIf;

	If HaveError Then
		Return;
	EndIf;

	ShowQueryBox(
		New NotifyDescription("QueryDeleteSettingsEnd", ThisForm), StrTemplate(NStr(
		"ru = 'Удалить выбранные настройки у пользователя %1?';en = 'Delete selected settings for user %1?'"), SettingsOwner), QuestionDialogMode.YesNo, ,
		DialogReturnCode.None, NStr("ru = 'Внимание!';en = 'Attention!'"));

EndProcedure

&AtClient
Procedure CopySelectedSettings(Command)
	
	// Checks
	HaveError = False;
	Filter = New Structure("Check", True);
	FoundedRows = SettingsTable.FindRows(Filter);
	If FoundedRows.Count() = 0 Then
		UT_CommonClientServer.MessageToUser(NStr("ru = 'Не выбраны настройки для копирования';en = 'Settings for copying not selected'"), , , ,
			HaveError);
	EndIf;
	FoundedRows = Users.FindRows(Filter);
	If FoundedRows.Count() = 0 Then
		UT_CommonClientServer.MessageToUser(NStr("ru = 'Не указаны пользователи (кому копировать)';en = 'Users are not specified (to whom to copy)'"),
			, , , HaveError);
	EndIf;

	If HaveError Then
		Return;
	EndIf;

	ShowQueryBox(
		New NotifyDescription("QueryCopySettingsEnd", ThisForm), NStr(
		"ru = 'Копировать выбранные настройки выбранным пользователям?';en = 'Copy selected settings to selected users?'"), QuestionDialogMode.YesNo, ,
		DialogReturnCode.None, NStr("ru = 'Внимание!';en = 'Attention!'"));

EndProcedure

&AtClient
Procedure TextOfFilterBySettingsStoragesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	FilterBySettingsStorages.ShowCheckItems(
		New NotifyDescription("ChangingFilterBySettingsStoragesEnd", ThisForm));
EndProcedure

&AtClient
Procedure TextOfFilterBySettingsStoragesClearing(Item, StandardProcessing)
	StandardProcessing = False;
	TextOfFilterBySettingsStorages = "";
	FilterBySettingsStorages.FillChecks(False);
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_ExecuteToolsCommonCommand(Command) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ThisObject, Command);
EndProcedure

#EndRegion

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

#Region ProcessingNotifyEnd

&AtClient
Procedure QueryDeleteSettingsEnd(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.None Then
		Return;
	EndIf;

	DeleteSelectedSettingsAtServer();

	UpdateOwnerSettings(Undefined);

EndProcedure

&AtClient
Procedure QueryCopySettingsEnd(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.None Then
		Return;
	EndIf;

	CopySelectedSettingsAtServer();

	ShowMessageBox( , NStr("ru = 'Копирование настроек выполнено';en = 'Copying settings is done'"));

EndProcedure

&AtClient
Procedure ChangingFilterBySettingsStoragesEnd(List, AdditionalParameters) Export

	If List = Undefined Then
		Return;
	EndIf;

	TextOfFilterBySettingsStorages = "";
	For Each ListItem In List Do
		If ListItem.Check Then
			TextOfFilterBySettingsStorages = TextOfFilterBySettingsStorages + ?(TextOfFilterBySettingsStorages = "",
				"", "; ") + ListItem.Presentation;
		EndIf;
	EndDo;

	UpdateOwnerSettings(Undefined);

EndProcedure

#EndRegion

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

#Region Private

&AtServer
Procedure UpdateUsersTable()

	Users.Clear();

	IbUsers=InfoBaseUsers.GetUsers();
	For Each IBUser In IbUsers Do
		NewRow=Users.Add();
		NewRow.Name=IBUser.Name;
		NewRow.FullName=IBUser.FullName;
		NewRow.Picture=0;
		NewRow.UUID=IBUser.UUID;

	EndDo;

EndProcedure

&AtClient
Procedure UpdateItemsPresentation(FormItems = Undefined)

	// Prepare array  names  of form items , the representation of which needs to be updated
	FormItemsArray = New Array;
	If TypeOf(FormItems) = Type("String") Then
		FormItemsArray = StrSplit(FormItems, ",");
	EndIf;

	If FormItemsArray.Count() = 0 Or FormItemsArray.Find("ConfigurationObjectsRepresentationVariant") <> Undefined Then
		Items.ConfigurationTreeByName.Visible = (ConfigurationObjectsRepresentationVariant = 0);
		Items.ConfigurationTreeBySynonym.Visible = (ConfigurationObjectsRepresentationVariant = 1);
	EndIf;

	If FormItemsArray.Count() = 0 Or FormItemsArray.Find("ShowSelectedSettings") <> Undefined Then
		Items.GroupSelectedSettings.Visible = Items.ConfigurationTreeShowSelectedSettings.Check;
		Items.ConfigurationTreeShowSelectedSettings.Title = ?(Items.GroupSelectedSettings.Visible,
			NStr("ru = 'Скрыть выбранные настройки';en = 'Hide selected settings'"), NStr("ru = 'Показать выбранные настройки';en = 'Show selected settings'"));
	EndIf;

	If FormItemsArray.Count() = 0 Or FormItemsArray.Find("ShowSelectedUsers") <> Undefined Then
		Items.Users.RowFilter = ?(Items.CancelSearchShowSelectedUsers.Check,
			New FixedStructure("Check", True), Undefined);
		Items.CancelSearchShowSelectedUsers.Title = ?(
			Items.Users.RowFilter <> Undefined, NStr("ru = 'Показать всех';en = 'Show all'"), NStr(
			"ru = 'Показать выбранных';en = 'Show selected'"));
	EndIf;	
	
	//If FormItemsArray.Count() = 0 Then
	//The condition describes the properties of the elements,
	// which are updated independently of the passed FormItems parameter
	//EndIf;

EndProcedure

&AtServer
Procedure UpdateOwnerSettingsAtServer()

	// Initialize configuration tree  and clear it
	ValuesTree = FormAttributeToValue("ConfigurationTree");
	ValuesTree.Rows.Clear();
	// Initialize settings table and clear it
	ValueTable = FormAttributeToValue("SettingsTable");
	ValueTable.Clear();
	
	// Create row for configuration tree
	ConfigurationTreeRow = ValuesTree.Rows.Add();
	ConfigurationTreeRow.PresentationName = Metadata.Name + NStr("ru = ' (Все настройки)';en = ' (All settings)'");
	ConfigurationTreeRow.PresentationSynonym = Metadata.Synonym + NStr("ru = ' (Все настройки)';en = ' (All settings)'");
	ConfigurationTreeRow.Order = 0;
	//ConfigurationTreeRow.Picture = 0;
	TreeRowOther = ConfigurationTreeRow.Rows.Add();
	TreeRowOther.PresentationName = NStr("ru = 'Прочее';en = 'Other'");
	TreeRowOther.PresentationSynonym = TreeRowOther.PresentationName;
	TreeRowOther.Order = 900;
	TreeRowOther.Path = "Other";
	TreeRowOther.FilterID = 1;
	//TreeRowOther.Picture = 0;
	
	// Parameters for create tree nodes
	AdditionalParameters = InitializeParametersForCreateConfigurationTree(ValueTable);
	AdditionalParameters.Insert("ConfigurationTreeRow", ConfigurationTreeRow);
	AdditionalParameters.Insert("TreeRowOther", TreeRowOther);
	
	// Get user settings
	Filter = New Structure("User", SettingsOwner);
	For Each ListItem In FilterBySettingsStorages Do
		If ListItem.Check Or IsBlankString(TextOfFilterBySettingsStorages) Then

			SettingsStorageName = ListItem.Value;
			Selection = Eval(SettingsStorageName).Select(Filter);
			AdditionalParameters.SettingsStorageName = SettingsStorageName;
				
				// filing tree
			ExtendSettingsTree(Selection, SettingsStorageName, AdditionalParameters);

		EndIf;
	EndDo; 
		
	// Send values to form 
	ValueToFormAttribute(ValuesTree, "ConfigurationTree");
	ValueToFormAttribute(AdditionalParameters.SettingsValueTable, "SettingsTable");

EndProcedure

&AtServer
Procedure ExtendSettingsTree(Selection, SettingsStorageName, AdditionalParameters)

	ConfigurationTreeRow = AdditionalParameters.ConfigurationTreeRow;
	TreeRowOther = AdditionalParameters.TreeRowOther;
	
	// Do for user settings
	While Selection.Next() Do
		
		// Decompose ObjectKey to Array(10)
		KeysArray = StrSplit(Selection.ObjectKey, "/", True);
		ItemsCountInArray = KeysArray.Count();
		For Index = ItemsCountInArray To 9 Do
			KeysArray.Add("");
		EndDo;
		
		// Decompose settings object Key  to Array(10)
		ConfigurationObjectPath = ?(KeysArray[0] = "Common" And KeysArray[1] = "TableSearchHistory", KeysArray[2],
			KeysArray[0]);
		PathArray = StrSplit(ConfigurationObjectPath, ".", True);
		ItemsCountInArray = PathArray.Count();
		For Index = ItemsCountInArray To 9 Do
			PathArray.Add("");
		EndDo;
		
		// Run recursive creation of settings tree row
		AdditionalParameters.Insert("ConfigurationTreeRow", ConfigurationTreeRow);
		AdditionalParameters.Insert("PathArray", PathArray);
		AdditionalParameters.Insert("SettingsSelections", Selection);
		CheckedProperty = StrReplace(PathArray[0], " ", "");
		Try
			If AdditionalParameters.PredefinedConfigurationBranches.Property(CheckedProperty) Then
				CreateConfigurationBranch(ConfigurationTreeRow, AdditionalParameters);
			Else
				CreateConfigurationBranch(TreeRowOther, AdditionalParameters);
			EndIf;
		Except
		EndTry;
	EndDo;

EndProcedure

&AtServer
Function InitializeParametersForCreateConfigurationTree(SettingsValueTable)

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SettingsStorageName", "");
	AdditionalParameters.Insert("SettingsValueTable", SettingsValueTable);
	AdditionalParameters.Insert("PictureNumber", 0);
	AdditionalParameters.Insert("FilterIDCounter", 2);
	AdditionalParameters.Insert("PredefinedConfigurationBranches", New Structure);
	AdditionalParameters.PredefinedConfigurationBranches.Insert("Common", "Common");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("Subsystem", "Subsystem");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("SettingsStorage", "SettingsStorage");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("ExchangePlan", "ExchangePlan");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("CommonForm", "CommonForm");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("Constant", "Constant");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("Catalog", "Catalog");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("Document", "Document");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("DocumentJournal", "DocumentJournal");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("Enum", "Enum");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("Report", "Report");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("ExternalReport", "ExternalReport");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("Processing", "Processing");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("ExternalDataProcessor", "ExternalDataProcessor");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("ChartOfCharacteristicTypes",
		"ChartOfCharacteristicTypes");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("ChartOfAccounts", "ChartOfAccounts");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("ChartOfCalculationTypes", "ChartOfCalculationTypes");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("InformationRegister", "InformationRegister");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("AccumulationRegister", "AccumulationRegister");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("AccountingRegister", "AccountingRegister");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("CalculationRegister", "CalculationRegister");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("BusinessProcess", "BusinessProcess");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("Task", "Task");
	AdditionalParameters.PredefinedConfigurationBranches.Insert("ExternalDataSource", "ExternalDataSource");

	Return AdditionalParameters;

EndFunction

&AtServer
Procedure CreateConfigurationBranch(ParentRow, AdditionalParameters, Level = 0)
	
	// add setting "Path" , to make the tree look like the configuration tree in the 1C Designer
	If Level = 0 And (AdditionalParameters.PathArray[Level] = "CommonForm"
		Or AdditionalParameters.PathArray[Level] = "SettingsStorage"
		Or AdditionalParameters.PathArray[Level] = "ExchangePlan" Or AdditionalParameters.PathArray[Level]
		= "Subsystem") Then
		AdditionalParameters.PathArray.Insert(0, "Common");
	EndIf; 
	
	// SearchPath, it is needed so that the branches of the settings tree are not duplicated
	SearchPath = ?(Level = 0, "", ParentRow.Path + ".") + AdditionalParameters.PathArray[Level];
	
	// Find exist branch
	TreeRow = ParentRow.Rows.Find(SearchPath, "Path", False);
	If TreeRow = Undefined Then		
		
		// Not found. Create new branch
		TreeRow = ParentRow.Rows.Add();
		TreeRow.Path = SearchPath;
		TreeRow.Level = Level;
		TreeRow.FilterID = AdditionalParameters.FilterIDCounter;
		AdditionalParameters.FilterIDCounter = AdditionalParameters.FilterIDCounter + 1;
		// Fill tree rows columns
		FillConfigurationTreeRow(TreeRow, AdditionalParameters, Level);

	EndIf;

	If AdditionalParameters.PathArray[Level + 1] <> "" And Level < 3 Then
		// Recursion
		CreateConfigurationBranch(TreeRow, AdditionalParameters, Level + 1);

	Else
		// Add row to settings table of current tree row
		SettingsTableRow = AdditionalParameters.SettingsValueTable.Add();
		SettingsTableRow.SettingsStorageName = AdditionalParameters.SettingsStorageName;
		SettingsTableRow.SettingsAdditional = AdditionalParameters.SettingsSelections.Settings;
		FillPropertyValues(SettingsTableRow, AdditionalParameters.SettingsSelections);
		SetFilterID(SettingsTableRow, TreeRow);

	EndIf; 
		
	// Sort tree level  depending on the display option of the view. Either by name or by synonym
	ParentRow.Rows.Sort(
		?(ConfigurationObjectsRepresentationVariant = 0, "Order, PresentationName", "Order, PresentationSynonym"));

EndProcedure

&AtServer
Function FillConfigurationTreeRow(TreeRow, AdditionalParameters, IndexOf)
	
	// Values by default
	TreeRow.PresentationName = AdditionalParameters.PathArray[IndexOf];
	TreeRow.PresentationSynonym = AdditionalParameters.PathArray[IndexOf];
	TreeRow.Order = 999;

	If AdditionalParameters.PathArray[IndexOf] = AdditionalParameters.PredefinedConfigurationBranches.Common Then
		TreeRow.PresentationName = "Common";
		TreeRow.Order = 10;
		//TreeRow.Picture = 0;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.Subsystem Then
		TreeRow.PresentationName = "Subsystems";
		TreeRow.PresentationSynonym = "Subsystems";
		TreeRow.MetadataObjectsClass = "Subsystem";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 20;
		//TreeRow.Picture = 0;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.SettingsStorage Then
		TreeRow.PresentationName = "Settings storages";
		TreeRow.PresentationSynonym = "Settings storage";
		TreeRow.MetadataObjectsClass = "SettingsStorage";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 21;
		//TreeRow.Picture = 0;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.ExchangePlan Then
		TreeRow.PresentationName = "Exchange plans";
		TreeRow.PresentationSynonym = "Exchange plans";
		TreeRow.MetadataObjectsClass = "ExchangePlan";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 22;
		//TreeRow.Picture = 0;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.CommonForm Then
		TreeRow.PresentationName = "Common forms";
		TreeRow.PresentationSynonym = "Common forms";
		TreeRow.MetadataObjectsClass = "CommonForm";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 23;
		TreeRow.Picture = 1;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.Constant Then
		TreeRow.PresentationName = "Constants";
		TreeRow.PresentationSynonym = "Constants";
		TreeRow.MetadataObjectsClass = "Constant";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 30;
		//TreeRow.Picture = 0;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.Catalog Then
		TreeRow.PresentationName = "Catalogs";
		TreeRow.PresentationSynonym = "Catalogs";
		TreeRow.MetadataObjectsClass = "Catalog";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 31;
		TreeRow.Picture = 2;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.Document Then
		TreeRow.PresentationName = "Documents";
		TreeRow.PresentationSynonym = "Documents";
		TreeRow.MetadataObjectsClass = "Document";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 32;
		TreeRow.Picture = 3;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.DocumentJournal Then
		TreeRow.PresentationName = "Document journals";
		TreeRow.PresentationSynonym = "Document journals";
		TreeRow.MetadataObjectsClass = "DocumentJournal";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 33;
		TreeRow.Picture = 4;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.Enum Then
		TreeRow.PresentationName = "Enums";
		TreeRow.PresentationSynonym = "Enums";
		TreeRow.MetadataObjectsClass = "Enum";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 34;
		//TreeRow.Picture = 3;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.Report Then
		TreeRow.PresentationName = "Reports";
		TreeRow.PresentationSynonym = "Reports";
		TreeRow.MetadataObjectsClass = "Report";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 35;
		TreeRow.Picture = 5;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.ExternalReport Then
		TreeRow.PresentationName = "ExternalReports";
		TreeRow.PresentationSynonym = "ExternalReports";
		TreeRow.Order = 36;
		TreeRow.Picture = 6;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.Processing Then
		TreeRow.PresentationName = "DataProcessors";
		TreeRow.PresentationSynonym = "DataProcessors";
		TreeRow.MetadataObjectsClass = "DataProcessor";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 37;
		TreeRow.Picture = 7;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.ExternalDataProcessor Then
		TreeRow.PresentationName = "ExternalDataProcessors";
		TreeRow.PresentationSynonym = "ExternalDataProcessors";
		TreeRow.Order = 38;
		TreeRow.Picture = 8;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.ChartOfCharacteristicTypes Then
		TreeRow.PresentationName = "Chart of characteristic types";
		TreeRow.PresentationSynonym = "Chart of characteristic types";
		TreeRow.MetadataObjectsClass = "ChartOfCharacteristicTypes";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 39;
		TreeRow.Picture = 9;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.ChartOfAccounts Then
		TreeRow.PresentationName = "Chart of accounts";
		TreeRow.PresentationSynonym = "Chart of accounts";
		TreeRow.MetadataObjectsClass = "ChartOfAccounts";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 40;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.ChartOfCalculationTypes Then
		TreeRow.PresentationName = "Chart of calculation types";
		TreeRow.PresentationSynonym = "Chart of calculation types";
		TreeRow.MetadataObjectsClass = "ChartOfCalculationTypes";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 41;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.InformationRegister Then
		TreeRow.PresentationName = "Information registers";
		TreeRow.PresentationSynonym = "Information registers";
		TreeRow.MetadataObjectsClass = "InformationRegister";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 42;
		TreeRow.Picture = 10;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.AccumulationRegister Then
		TreeRow.PresentationName = "Accumulation register";
		TreeRow.PresentationSynonym = "Accumulation registers";
		TreeRow.MetadataObjectsClass = "AccumulationRegister";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 43;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.AccountingRegister Then
		TreeRow.PresentationName = "Accounting registers";
		TreeRow.PresentationSynonym = "Accounting registers";
		TreeRow.MetadataObjectsClass = "AccountingRegister";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 44;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.CalculationRegister Then
		TreeRow.PresentationName = "Calculation registers";
		TreeRow.PresentationSynonym = "Calculation registers";
		TreeRow.MetadataObjectsClass = "CalculationRegister";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 45;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.BusinessProcess Then
		TreeRow.PresentationName = "Business-processes";
		TreeRow.PresentationSynonym = "Business-processes";
		TreeRow.MetadataObjectsClass = "BusinessProcess";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 46;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.Task Then
		TreeRow.PresentationName = "Tasks";
		TreeRow.PresentationSynonym = "Tasks";
		TreeRow.MetadataObjectsClass = "Task";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 47;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.PathArray[IndexOf]
		= AdditionalParameters.PredefinedConfigurationBranches.ExternalDataSource Then
		TreeRow.PresentationName = "External data sources";
		TreeRow.PresentationSynonym = "External data sources";
		TreeRow.MetadataObjectsClass = "ExternalDataSource";
		TreeRow.GeneratePresentationOfChildRowsFromMetadataSynonyms = True;
		TreeRow.Order = 48;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.PathArray[IndexOf] = "Form" Then
		TreeRow.PresentationName = "Forms";
		TreeRow.PresentationSynonym = "Forms";
		TreeRow.Picture = 1;

	Else
		TreeRow.Picture = AdditionalParameters.PictureNumber;

	EndIf;

	AdditionalParameters.PictureNumber = TreeRow.Picture;
	
	// Fill columns   PresentationSynonym, MissingInConfiguration of tree
	If IndexOf > 0 And TreeRow.Parent.GeneratePresentationOfChildRowsFromMetadataSynonyms Then
		MetadataObject = Metadata.FindByFullName(TreeRow.Parent.MetadataObjectsClass + "."
			+ AdditionalParameters.PathArray[IndexOf]);
		If MetadataObject = Undefined Then
			TreeRow.MissingInConfiguration = True;
			SetMissingInConfiguration(TreeRow);
		Else
			TreeRow.PresentationSynonym = MetadataObject.Synonym;
		EndIf;
	EndIf;

EndFunction

&AtServer
Procedure SetFilterID(SettingsTableRow, TreeRow)

	SettingsTableRow["FilterID" + TreeRow.Level] = TreeRow.FilterID;

	TreeRow.SettingsCount = TreeRow.SettingsCount + 1;

	ParentRow = TreeRow.Parent;
	If ParentRow.Parent <> Undefined Then
		// Recursion
		SetFilterID(SettingsTableRow, ParentRow);
	EndIf;

EndProcedure

&AtServer
Procedure SetMissingInConfiguration(TreeRow)

	TreeRow.MissingInConfiguration = True;

	ParentRow = TreeRow.Parent;
	If ParentRow.Parent <> Undefined Then
		// Recursion
		SetMissingInConfiguration(ParentRow);
	EndIf;

EndProcedure

&AtServer
Procedure DeleteSelectedSettingsAtServer()
	FilterParameters = New Structure;
	FilterParameters.Insert("Check", True);
	FoundedRows = SettingsTable.FindRows(FilterParameters);
	For Each String In FoundedRows Do
		SettingsStorage = Eval(String.SettingsStorageName);
		SettingsStorage.Delete(String.ObjectKey, String.SettingsKey, SettingsOwner);
	EndDo;

EndProcedure

&AtServer
Procedure CopySelectedSettingsAtServer()

	Filter = New Structure("Check", True);

	SelectedUsers = Users.FindRows(Filter);

	SelectedSettings = SettingsTable.FindRows(Filter);

	For Each RowUser In SelectedUsers Do
		For Each SettingRow In SelectedSettings Do

			SettingsStorage = Eval(SettingRow.SettingsStorageName);

			Filter = New Structure;
			Filter.Insert("ObjectKey", SettingRow.ObjectKey);
			Filter.Insert("SettingsKey", SettingRow.SettingsKey);
			Filter.Insert("User", RowUser.Name);
			
			
			// Get settings for copying  Selection SourceSettingsSelection must have one item
			SourceSettingsSelection = SettingsStorage.Select(Filter);
			SourceSettingsSelection.Next();
			
			// Copy setting to new user
			SettingsStorage.Save(
				SettingRow.ObjectKey, SettingRow.SettingsKey, SourceSettingsSelection.Settings,
				SettingRow.Presentation, RowUser.Name);

		EndDo;
	EndDo;

EndProcedure

&AtServer
Procedure ViewSettingsAtServer(SettingsStorageName, ObjectKey, SettingsKey, UserName)

	Filter = New Structure;
	Filter.Insert("ObjectKey", ObjectKey);
	Filter.Insert("SettingsKey", SettingsKey);
	Filter.Insert("User", UserName);

	Selection = Eval(SettingsStorageName).Select(Filter);
	Selection.Next();

	SettingsContent = Selection.Settings;

EndProcedure

#EndRegion

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

#Region Other

#Region Checks_Management

&AtClient
Procedure SetCheckForChilds(TreeItem, Check)
	
	// Set check
	TreeItem.Check = Check;

	FilterParameters = New Structure;
	FilterParameters.Insert("FilterID" + TreeItem.Level, TreeItem.FilterID);
	FilterParameters.Insert("Check", Not Check);
	FoundedRows = SettingsTable.FindRows(FilterParameters);
	For Each String In FoundedRows Do
		String.Check = (Check = 1);
	EndDo; 
	
	// Recursive set of check for child tree rows
	For Each Child In TreeItem.GetItems() Do
		SetCheckForChilds(Child, Check);
	EndDo;

EndProcedure

&AtClient
Procedure SetCheckForParents(TreeItem, Check)
	
	// Set check
	TreeItem.Check = Check;	
	
	//  Recursive set of check of parent tree rows
	ParentItem = TreeItem.GetParent();
	If Not ParentItem = Undefined Then
		
		// Calculate count of cheked items at child level
		CheckedItemsCount = 0;
		GreyItemsCount = 0;
		ParentChildItems = ParentItem.GetItems();
		For Each Child In ParentChildItems Do
			CheckedItemsCount = CheckedItemsCount + ?(Child.Check = 1, 1, 0);
			GreyItemsCount = GreyItemsCount + ?(Child.Check = 2, 1, 0);
		EndDo;
		
		// Set checks
		If CheckedItemsCount = 0 And GreyItemsCount = 0 Then
			SetCheckForParents(ParentItem, 0);
		ElsIf CheckedItemsCount = ParentChildItems.Count() Then
			SetCheckForParents(ParentItem, 1);
		Else
			SetCheckForParents(ParentItem, 2);
		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure CheckManagement(TreeItem, CutGreyCheck = True)

	If TreeItem = Undefined Then
		Return;
	EndIf;
	
	// Cut grey check, think that off check
	If CutGreyCheck And TreeItem.Check = 2 Then
		TreeItem.Check = 0;
	EndIf;

	SetCheckForChilds(TreeItem, TreeItem.Check);
	SetCheckForParents(TreeItem, TreeItem.Check);

EndProcedure

#EndRegion

#EndRegion