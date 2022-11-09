#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTests") Then
		Return;
	EndIf;

	CheckPlatformVersionAndCompatibilityMode();

	OperatingModeAtClient = (OperatingModeAtClientOrAtServer = 0);

	Items.ExportFileName.Enabled = Not OperatingModeAtClient;

	ObjectAtServer = FormAttributeToValue("Object");
	ObjectAtServer.Initializing();

	ValueToFormAttribute(ObjectAtServer.MetadataTree, "Object.MetadataTree");

	File = New File(ExportFileName);
	Object.UseFastInfoSetFormat = (File.Extension = ".fi");

	ExportMode = (Items.ModeGroup.CurrentPage = Items.ModeGroup.ChildItems.ExportGroup);

	UT_Common.ToolFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)

	OperatingModeAtClient = (OperatingModeAtClientOrAtServer = 0);
	
	Items.ExportFileName.Enabled = Not OperatingModeAtClient;
	
	File = New File(ExportFileName);
	Object.UseFastInfoSetFormat = (File.Extension = ".fi");
	
	ExportMode = (Items.ModeGroup.CurrentPage = Items.ModeGroup.ChildItems.ExportGroup);

EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	ChoiceProcessingAtServer(SelectedValue);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "QueryConsoleSettingsFormClosed" Then
		FillPropertyValues(ThisObject, Parameter);
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExportFileNameOnChange(Item)
	
	File = New File(ExportFileName);
	Object.UseFastInfoSetFormat = (File.Extension = ".fi");
	
EndProcedure

&AtClient
Procedure ExportFileNameOnOpen(Item, StandardProcessing)

	OpenInApplication(Item, "ExportFileName", StandardProcessing);

EndProcedure

&AtClient
Procedure ExportFileNameStartChoice(Item, ChoiceData, StandardProcessing)

	ProcessFileChoiceStart(StandardProcessing);

EndProcedure

&AtClient
Procedure UseFastInfoSetFormatOnChange(Item)
	
	If Object.UseFastInfoSetFormat Then
		ExportFileName = StrReplace(ExportFileName, ".xml", ".fi");
	Else
		ExportFileName = StrReplace(ExportFileName, ".fi", ".xml");
	EndIf;
	
EndProcedure

&AtClient
Procedure ModeGroupOnCurrentPageChange(Item, CurrentPage)

	ExportMode = (Items.ModeGroup.CurrentPage = Items.ModeGroup.ChildItems.ExportGroup);

EndProcedure

&AtClient
Procedure AdditionalObjectsToExportOnChange(Item)

	If Item.CurrentData <> Undefined And ValueIsFilled(Item.CurrentData.Object) Then
		
		Item.CurrentData.ObjectForQueryName = ObjectNameByTypeForQuery(Item.CurrentData.Object);
		
	EndIf;

EndProcedure

//@skip-check module-unused-method
&AtClient
Procedure ImportFileNameOpen(Item, StandardProcessing)
	
	OpenInApplication(Item, "ImportFileName", StandardProcessing);

EndProcedure

//@skip-check module-unused-method
&AtClient
Procedure ImportFileNameStartChoice(Item, ChoiceData, StandardProcessing)

	ProcessFileChoiceStart(StandardProcessing);

EndProcedure

&AtClient
Procedure ObjectsTypeToExportStartChoice(Item, ChoiceData, StandardProcessing)
	UT_CommonClient.EditType(ObjectsTypeToExport, 0, StandardProcessing, Item,
		New NotifyDescription("ObjectsTypeToExportStartChoiceCompletion", ThisObject), "Refs");
EndProcedure

&AtClient
Procedure ObjectsTypeToExportStartChoiceCompletion(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;

	ObjectsTypeToExport = Result;
EndProcedure

#EndRegion

#Region MetadataTreeFormTableItemsEventHandlers

&AtClient
Procedure MetadataTreeExportDataOnChange(Item)

	CurrentData = Items.MetadataTree.CurrentData;
	
	If CurrentData.ExportData = 2 Then
		CurrentData.ExportData = 0;
	EndIf;

	SetChildItemsMarks(CurrentData, "ExportData");
	SetParentItemsMarks(CurrentData, "ExportData");

	CurrentDataName = Items.MetadataTree.CurrentData.MetadataFullName;

	//ResultTableFilter.Clear();
	PrepareSelectedObjectsList(CurrentDataName, Items.MetadataTree.CurrentData.MetadataObjectName);

EndProcedure

&AtClient
Procedure MetadataTreeExportIfNecessaryOnChange(Item)
	
	CurrentData = Items.MetadataTree.CurrentData;
	
	If CurrentData.ExportIfNecessary = 2 Then
		CurrentData.ExportIfNecessary = 0;
	EndIf;

	SetChildItemsMarks(CurrentData, "ExportIfNecessary");
	SetParentItemsMarks(CurrentData, "ExportIfNecessary");

EndProcedure

#EndRegion

#Region AdditionalObjectsForExportFormTableItemsEventHandlers

&AtClient
Procedure AdditionalObjectsToExportBeforeAddRow(Item, Cancel, Clone, Parent, Folder)

	Item.CurrentItem.TypeRestriction = ObjectsTypeToExport;

EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure AddFromQuery(Command)

	OpenForm(QueryConsoleFormName(), QueryConsoleParameters(), ThisObject);

EndProcedure

&AtClient
Procedure ClearAdditionalObjectsToExport(Command)

	Object.AdditionalObjectsToExport.Clear();

EndProcedure

&AtClient
Procedure ExportData(Command)

	Object.StartDate = ExportPeriod.StartDate;
	Object.EndDate = ExportPeriod.EndDate;

	ClearMessages();

	If Not OperatingModeAtClient Then
		
		If IsBlankString(ExportFileName) Then
			
			MessageText = NStr("ru = 'Поле ""Имя файла"" не заполнено'; en = 'The File name field is not filled.'");
			MessageToUser(MessageText, "ExportFileName");
			Return;
			
		EndIf;
		
	EndIf;

	Status(NStr("ru = 'Выполняется выгрузка данных. Пожалуйста, подождите...'; en = 'Export data. Please wait...'"));

	FileAddressInTempStorage = "";
	ExportDataAtServer(FileAddressInTempStorage);
	
	If OperatingModeAtClient And Not IsBlankString(FileAddressInTempStorage) Then
		
		FileName = ?(Object.UseFastInfoSetFormat, NStr("ru = 'Файл выгрузки.fi'; en = 'Export file.fi'"), NStr("ru = 'Файл выгрузки.xml'; en = 'Export file.xml'"));
		GetFile(FileAddressInTempStorage, FileName);
		
	EndIf;

EndProcedure

&AtClient
Procedure ImportData(Command)

	ClearMessages();
	FileAddressInTempStorage = "";

	//	If OperatingModeAtClient Then

	//NotifyDescription = New NotifyDescription("ImportDataCompletion", ThisObject);
	//BeginPutFileAtServer(NotifyDescription,,,FileAddressInTempStorage,, ThisForm.UUID);
	Mode = FileDialogMode.Open;
	FileOpenDialog = New FileDialog(Mode);
	FileOpenDialog.FullFileName = "";
	//Filter = NStr("ru = 'XML файлы'; en = 'XML files'")	+ "(*.xml)|*.xml";
	//FileOpenDialog.Filter = Filter;
	FileOpenDialog.Multiselect = False;
	FileOpenDialog.Title = NStr("ru = 'Выберите файлы'; en = 'Select files'");

	NotifyDescription = New NotifyDescription("ImportDataCompletion", ThisObject);
	BeginPuttingFiles(NotifyDescription, FileAddressInTempStorage, FileOpenDialog, True,
		UUID);

EndProcedure

&AtClient
Procedure QueryConsoleSettings(Command)

	FormParameters = New Structure;
	FormParameters.Insert("QueryConsoleUsageOption", QueryConsoleUsageOption);
	FormParameters.Insert("PathToExternalQueryConsole", PathToExternalQueryConsole);

	OpenForm(QueryConsoleSettingsFormName(), FormParameters);

EndProcedure

&AtClient
Procedure RecalculateDataToExportByRef(Command)

	Status(NStr("ru = 'Выполняется поиск объектов метаданных, которые могут быть выгружены по ссылкам...'; en = 'Searching for the metadata objects available to export by refs...'"));
	SaveTreeView(Object.MetadataTree.GetItems());
	RecalculateDataToExportByRefAtServer();
	RestoreTreeView(Object.MetadataTree.GetItems());

EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_ExecuteToolsCommonCommand(Command) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ThisObject, Command);
EndProcedure



#EndRegion

#Region Private

&AtServer
Function QueryConsoleFormName()

	If QueryConsoleUsageOption = 0 Then

		DataProcessor = FormAttributeToValue("Object");
		FormID = ".Form.SelectFromQuery";

	ElsIf QueryConsoleUsageOption = 1 Then

		DataProcessor = DataProcessors.UT_QueryConsole.Create();
		FormID = ".Form";

	Else //QueryConsoleUsageOption = 2
		DataProcessor = ExternalDataProcessors.Create(PathToExternalQueryConsole);
		FormID = ".ObjectForm";

	EndIf;

	Return DataProcessor.Metadata().FullName() + FormID;

EndFunction

&AtServer
Function QueryConsoleSettingsFormName()

	DataProcessor = FormAttributeToValue("Object");
	SettingsFormName = DataProcessor.Metadata().FullName() + ".Form.QueryConsoleSettings";
	
	Return SettingsFormName;

EndFunction

&AtClient
Function QueryConsoleParameters()

	FormParameters = New Structure;

	If QueryConsoleUsageOption = 0 Then

		FormParameters.Insert("QueryConsoleUsageOption", QueryConsoleUsageOption);
		FormParameters.Insert("PathToExternalQueryConsole", PathToExternalQueryConsole);

	Else

		FormParameters.Insert("Title", NStr("ru='Выбор данных для выгрузки'; en = 'Choose data for export'"));
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("CloseOnChoice", False);

	EndIf;

	Return FormParameters;

EndFunction

&AtClient
Procedure OpenInApplication(Item, DataPath, StandardProcessing)
	StandardProcessing = False;

	File = New File(Item.EditText);

	File.BeginCheckingExistence(New NotifyDescription("OpenInApplicationCompletion", ThisForm,
		New Structure("DataPath, Item", DataPath, Item)));

EndProcedure

&AtClient
Procedure OpenInApplicationCompletion(Exists, AdditionalParameters) Export

	DataPath = AdditionalParameters.DataPath;
	Item = AdditionalParameters.Item;
	If Exists Then

		BeginRunningApplication(UT_CommonClient.ApplicationRunEmptyNotifyDescription(),
			Item.EditText);

	Else

		MessageToUser(NStr("ru = 'Файл не найден'; en = 'File not found'"), DataPath);

	EndIf;

EndProcedure

&AtClient
Procedure OperatingModeOnChange()

	OperatingModeAtClient = (OperatingModeAtClientOrAtServer = 0);

	Items.ExportFileName.Enabled = Not OperatingModeAtClient;
	Items.ImportFileName.Enabled = Not OperatingModeAtClient;

EndProcedure

&AtClientAtServerNoContext
Procedure MessageToUser(Text, DataPath = "")

	Message = New UserMessage;
	Message.Text = Text;
	Message.DataPath = DataPath;
	Message.Message();

EndProcedure

&AtClient
Procedure ProcessFileChoiceStart(StandardProcessing)

	StandardProcessing = False;
	DialogMode = ?(ExportMode, FileDialogMode.Save, FileDialogMode.Open);
	FileDialog = New FileDialog(DialogMode);
	FileDialog.CheckFileExist = Not ExportMode;
	FileDialog.Multiselect = False;
	FileDialog.Title = NStr("ru = 'Задайте имя файла выгрузки'; en = 'Specify export file name'");
	FileDialog.FullFileName = ?(ExportMode, ExportFileName, ImportFileName);
	
	FileDialog.Filter = "Format export(*.xml)|*.xml|FastInfoSet (*.fi)|*.fi|All files (*.*)|*.*";
	FileDialog.Show(New NotifyDescription("ProcessFileChoiceStartCompletion", ThisForm,
		New Structure("FileDialog", FileDialog)));

EndProcedure

&AtClient
Procedure ProcessFileChoiceStartCompletion(SelectedFiles, AdditionalParameters) Export

	FileDialog = AdditionalParameters.FileDialog;
	If (SelectedFiles <> Undefined) Then
		If ExportMode Then
			ExportFileName = FileDialog.FullFileName;
		Else
			ImportFileName = FileDialog.FullFileName;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure SetChildItemsMarks(CurrRow, CheckBoxName)

	RowChildItems = CurrRow.GetItems();

	If ChildItems.Count() = 0 Then
		Return;
	EndIf;

	For Each Row In RowChildItems Do

		Row[CheckBoxName] = CurrRow[CheckBoxName];

		SetChildItemsMarks(Row, CheckBoxName);

	EndDo;

EndProcedure

&AtClient
Procedure SetParentItemsMarks(CurrRow, CheckBoxName)

	Parent = CurrRow.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf;

	CurrStatus = Parent[CheckBoxName];

	EnabledItemsFound = False;
	DisabledItemsFound = False;

	For Each Row In Parent.GetItems() Do
		If Row[CheckBoxName] = 0 Then
			DisabledItemsFound = True;
		ElsIf Row[CheckBoxName] = 1 Or Row[CheckBoxName] = 2 Then
			EnabledItemsFound = True;
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

	If Enable = CurrStatus Then
		Return;
	Else
		Parent[CheckBoxName] = Enable;
		SetParentItemsMarks(Parent, CheckBoxName);
	EndIf;

EndProcedure

&AtServer
Procedure ExportDataAtServer(FileAddressInTempStorage)

	FilterTable1 = FormAttributeToValue("FilterTable");

	If OperatingModeAtClient Then

		Extension = ?(Object.UseFastInfoSetFormat, ".fi", ".xml");
		TempFileName = GetTempFileName(Extension);

	Else

		TempFileName = ExportFileName;

	EndIf;

	ObjectAtServer = FormAttributeToValue("Object");
	FillMetadataTreeAtServer(ObjectAtServer);

	ObjectAtServer.ExecuteExport(TempFileName, , FilterTable1);

	If OperatingModeAtClient Then

		File = New File(TempFileName);

		If File.Exists() Then

			BinaryData = New BinaryData(TempFileName);
			FileAddressInTempStorage = PutToTempStorage(BinaryData, UUID);
			DeleteFiles(TempFileName);

		EndIf;

	EndIf;

EndProcedure

&AtServer
Procedure SetMarksOfDataToExport(SourceTreeRows, TreeToReplaceRows)
	
	ColumnExport = TreeToReplaceRows.UnloadColumn("ExportData");
	SourceTreeRows.LoadColumn(ColumnExport, "ExportData");
	
	ColumnExportIfNecessary = TreeToReplaceRows.UnloadColumn("ExportIfNecessary");
	SourceTreeRows.LoadColumn(ColumnExportIfNecessary, "ExportIfNecessary");
	
	ColumnExpanded = TreeToReplaceRows.UnloadColumn("Expanded");
	SourceTreeRows.LoadColumn(ColumnExpanded, "Expanded");
	
	For Each SourceTreeRow In SourceTreeRows Do
		
		RowIndex = SourceTreeRows.IndexOf(SourceTreeRow);
		TreeToChangeRow = TreeToReplaceRows.Get(RowIndex);
		
		SetMarksOfDataToExport(SourceTreeRow.Rows, TreeToChangeRow.Rows);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ImportDataCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	If Not Result Then
		Return;
	EndIf;

	Status(NStr("ru = 'Выполняется загрузка данных. Пожалуйста, подождите...'; en = 'Import data. Please wait...'"));

	ImportDataAtServer(Address);

EndProcedure

&AtServer
Procedure ImportDataAtServer(FileAddressInTempStorage, Extension = "xml")

	BinaryData = GetFromTempStorage(FileAddressInTempStorage);
	TempFileName = GetTempFileName(Extension);
	BinaryData.Write(TempFileName);

	FormAttributeToValue("Object").ExecuteImport(TempFileName);

	File = New File(TempFileName);

	If File.Exists() Then

		DeleteFiles(TempFileName);

	EndIf;

EndProcedure

&AtServer
Procedure RecalculateDataToExportByRefAtServer()

	ObjectAtServer = FormAttributeToValue("Object");
	FillMetadataTreeAtServer(ObjectAtServer);
	ObjectAtServer.ExportContent(True);
	ValueToFormAttribute(ObjectAtServer.MetadataTree, "Object.MetadataTree");

EndProcedure

&AtServer
Procedure FillMetadataTreeAtServer(ObjectAtServer)

	MetadataTree = FormAttributeToValue("Object.MetadataTree");

	ObjectAtServer.Initializing();

	SetMarksOfDataToExport(ObjectAtServer.MetadataTree.Rows, MetadataTree.Rows);

EndProcedure

&AtClient
Procedure SaveTreeView(TreeRows)

	For Each Row In TreeRows Do
		
		RowID=Row.GetID();
		Row.Expanded = Items.MetadataTree.Expanded(RowID);
		
		SaveTreeView(Row.GetItems());
		
	EndDo;
	
EndProcedure

&AtClient
Procedure RestoreTreeView(TreeRows)

	For Each Row In TreeRows Do
		
		RowID=Row.GetID();
		If Row.Expanded Then
			Items.MetadataTree.Expand(RowID);
		EndIf;

		RestoreTreeView(Row.GetItems());

	EndDo;

EndProcedure

&AtServerNoContext
Function ObjectNameByTypeForQuery(Ref)
	
	ObjectMetadata = Ref.Metadata();
	MetadataName = ObjectMetadata.Name;
	
	NameForQuery = "";
	
	If Metadata.Catalogs.Contains(ObjectMetadata) Then
		NameForQuery = "Catalog";
	ElsIf Metadata.Documents.Contains(ObjectMetadata) Then
		NameForQuery = "Document";
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(ObjectMetadata) Then
		NameForQuery = "ChartOfCharacteristicTypes";
	ElsIf Metadata.ChartsOfAccounts.Contains(ObjectMetadata) Then
		NameForQuery = "ChartOfAccounts";
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(ObjectMetadata) Then
		NameForQuery = "ChartOfCalculationTypes";
	ElsIf Metadata.ExchangePlans.Contains(ObjectMetadata) Then
		NameForQuery = "ExchangePlan";
	ElsIf Metadata.BusinessProcesses.Contains(ObjectMetadata) Then
		NameForQuery = "BusinessProcess";
	ElsIf Metadata.Tasks.Contains(ObjectMetadata) Then
		NameForQuery = "Task";
	EndIf;
	
	If IsBlankString(NameForQuery) Then
		Return "";
	Else
		Return NameForQuery + "." + MetadataName;
	EndIf;
	
EndFunction

&AtServer
Procedure ChoiceProcessingAtServer(SelectedValues)
	
	If TypeOf(SelectedValues) = Type("Structure") Then
		
		QueryResult = GetFromTempStorage(SelectedValues.ChoiceData);
		
		If TypeOf(QueryResult)=Type("Array") Then
			
			QueryResult = QueryResult[QueryResult.UBound()];
			
			If QueryResult.Columns.Find("Ref") <> Undefined Then
				SelectedRefs = QueryResult.Unload();
			EndIf;
			
		EndIf;
		
	Else
		
		SelectedRefs = SelectedValues;
		
	EndIf;
	
	For Each Value In SelectedRefs Do
		
		NewRow = Object.AdditionalObjectsToExport.Add();
		NewRow.Object = Value.Ref;
		NewRow.ObjectForQueryName = ObjectNameByTypeForQuery(Value.Ref);
		
	EndDo
	
EndProcedure

&AtClient
Procedure OperatingModeAtClientOrAtServerOnChange(Item)

	OperatingModeOnChange();

EndProcedure

//@skip-warning
&AtClient
Procedure ImportAtClientOrAtServerOnChange(Элемент)

	OperatingModeOnChange();

EndProcedure

//@skip-warning
&AtServer
Function CheckPlatformVersionAndCompatibilityMode()

	Information = New SystemInfo;
	If Not (Left(Information.AppVersion, 3) = "8.3"
		AND (Metadata.CompatibilityMode = Metadata.ObjectProperties.CompatibilityMode.DontUse
		Or (Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_1
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_2_13
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_2_16"]
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_1"]
		AND Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_2"]))) Then
		
		Raise NStr("ru = 'Обработка предназначена для запуска на версии платформы
			|1С:Предприятие 8.3 с отключенным режимом совместимости или выше'; 
			|en = 'The data processor is intended for use with 
			|1C:Enterprise 8.3 or later, with disabled compatibility mode'");
		
	EndIf;

EndFunction

//@skip-warning
&AtClient
Procedure MetadataTreeOnChange(Item)
// Insert handler content.
EndProcedure

&AtServer
Procedure InitializeDCS()

	DataCompositionSchema = New DataCompositionSchema;
	NewSource = DataCompositionSchema.DataSources.Add();
	NewSource.Name = "DataSource1";
	NewSource.DataSourceType = "Local";

	NewDataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetObject"));
	NewDataSet.DataSource = "Local";

	NewDataSet.Name = "Main";
	NewDataSet.ObjectName = "Main";
	NewDataSet.DataSource = "DataSource1";

	MetadataTable.Clear();

	CommonAttributesTable = New ValueTable;

	CommonAttributesTable.Columns.Add("MetadataObject");
	CommonAttributesTable.Columns.Add("AttributeCount");
	CommonAttributesTable.Columns.Add("Header");

	RefTypesArray = New Array;

	For Each ObjectsItem In ChoiceResult Do

		If ObjectsItem.Value = "Catalogs" Then

			TypeString = "CatalogRef.";

		ElsIf ObjectsItem.Value = "Documents" Then

			TypeString = "DocumentRef.";

		ElsIf ObjectsItem.Value = "ChartsOfCalculationTypes" Then

			TypeString = "ChartOfCalculationTypesRef.";

		ElsIf ObjectsItem.Value = "ChartsOfCharacteristicTypes" Then

			TypeString = "ChartOfCharacteristicTypesRef.";

		ElsIf ObjectsItem.Value = "BusinessProcesses" Then

			TypeString = "BusinessProcessRef.";

		ElsIf ObjectsItem.Value = "Tasks" Then

			TypeString = "TaskRef.";
		ElsIf ObjectsItem.Value = "Constants" Then

			TypeString = "ConstantManager.";
		ElsIf ObjectsItem.Value = "ExchangePlans" Then
			TypeString = "ExchangePlanRef.";
		ElsIf ObjectsItem.Value = "ChartsOfAccounts" Then
			TypeString = "ChartOfAccountsRef.";
		ElsIf ObjectsItem.Value = "Sequences" Then
			TypeString = "SequenceManager.";
		ElsIf ObjectsItem.Value = "InformationRegisters" Then
			TypeString = "InformationRegisterManager.";
		ElsIf ObjectsItem.Value = "AccumulationRegisters" Then
			TypeString = "AccumulationRegisterManager.";
		ElsIf ObjectsItem.Value = "AccountingRegisters" Then
			TypeString = "AccountingRegisterManager.";
		EndIf;

		RefTypesArray.Add(Type(TypeString + ObjectsItem));

	EndDo;

	For Each ChoiceObject In ChoiceResult Do

		If ChoiceObject.Value = "InformationRegisters" Or ChoiceObject.Value = "AccumulationRegisters"
			Or ChoiceObject.Value = "AccountingRegisters" Then

			For Each MetadataObject In Metadata[ChoiceObject.Value][String(ChoiceObject)].Attributes Do

				NewRow = MetadataTable.Add();

				NewRow.AttributeName = MetadataObject.Name;
				NewRow.AttributeSynonym = MetadataObject.Synonym;
				NewRow.TypeDescription = ExcludeInvalidTypes(MetadataObject.Type);
				NewRow.MetadataObject = ChoiceObject.Value;

			EndDo;

			For Each MetadataObject In Metadata[ChoiceObject.Value][String(
				ChoiceObject)].StandardAttributes Do

				If MetadataObject.Name = "Predefined" Or MetadataObject.Name = "IsFolder"
					Or MetadataObject.Name = "Ref" Then

					Continue;

				Else

					NewRow = MetadataTable.Add();

					NewRow.AttributeName = MetadataObject.Name;
					NewRow.AttributeSynonym = MetadataObject.Name;
					NewRow.TypeDescription = ExcludeInvalidTypes(MetadataObject.Type);
					NewRow.MetadataObject = ChoiceObject.Value;

				EndIf;

			EndDo;

			For Each MetadataObject In Metadata[ChoiceObject.Value][String(ChoiceObject)].Dimensions Do

				NewRow = MetadataTable.Add();

				NewRow.AttributeName = MetadataObject.Name;
				NewRow.AttributeSynonym = MetadataObject.Synonym;
				NewRow.TypeDescription = ExcludeInvalidTypes(MetadataObject.Type);
				NewRow.MetadataObject = ChoiceObject.Value;

			EndDo;

			For Each MetadataObject In Metadata[ChoiceObject.Value][String(ChoiceObject)].Resources Do

				NewRow = MetadataTable.Add();

				NewRow.AttributeName = MetadataObject.Name;
				NewRow.AttributeSynonym = MetadataObject.Synonym;
				NewRow.TypeDescription = ExcludeInvalidTypes(MetadataObject.Type);
				NewRow.MetadataObject = ChoiceObject.Value;

			EndDo;

		ElsIf ChoiceObject.Value <> "Constants" And ChoiceObject.Value <> "Sequences" Then
			AttributeCount = Metadata[ChoiceObject.Value][String(ChoiceObject)].Attributes.Count();

			For Each MetadataObject In Metadata[ChoiceObject.Value][String(ChoiceObject)].Attributes Do

				NewRow = MetadataTable.Add();

				NewRow.AttributeName = MetadataObject.Name;
				NewRow.AttributeSynonym = MetadataObject.Synonym;
				NewRow.TypeDescription = ExcludeInvalidTypes(MetadataObject.Type);
				NewRow.MetadataObject = ChoiceObject.Value;

			EndDo;

			For Each MetadataObject In Metadata[ChoiceObject.Value][String(
				ChoiceObject)].StandardAttributes Do

				If MetadataObject.Name = "Predefined" Or MetadataObject.Name = "IsFolder"
					Or MetadataObject.Name = "Ref" Then

					Continue;

				Else

					NewRow = MetadataTable.Add();

					NewRow.AttributeName = MetadataObject.Name;
					NewRow.AttributeSynonym = MetadataObject.Name;
					NewRow.TypeDescription = ExcludeInvalidTypes(MetadataObject.Type);
					NewRow.MetadataObject = ChoiceObject.Value;

				EndIf;

			EndDo;
		ElsIf ChoiceObject.Value = "Constants" Then
			NewRow = MetadataTable.Add();
			MetadataObject = Metadata[ChoiceObject.Value][String(ChoiceObject)];

			NewRow.AttributeName = MetadataObject.Name;
			NewRow.AttributeSynonym = MetadataObject.Name;
			NewRow.TypeDescription = ExcludeInvalidTypes(MetadataObject.Type);
			NewRow.MetadataObject = ChoiceObject.Value;
		ElsIf ChoiceObject.Value = "Sequences" Then

			For Each MetadataObject In Metadata[ChoiceObject.Value][String(ChoiceObject)].Dimensions Do
				If MetadataObject.Name = "Predefined" Or MetadataObject.Name = "IsFolder"
					Or MetadataObject.Name = "Ref" Then
					Continue;
				Else
					NewRow = MetadataTable.Add();
					NewRow.AttributeName = MetadataObject.Name;
					NewRow.AttributeSynonym = MetadataObject.Name;
					NewRow.TypeDescription = ExcludeInvalidTypes(MetadataObject.Type);
					NewRow.MetadataObject = ChoiceObject.Value;
				EndIf;
			EndDo;

		EndIf;

		If ChoiceObject.Value = "Tasks" Then

			AttributeCount = AttributeCount + Metadata[ChoiceObject.Value][String(
				ChoiceObject)].AddressingAttributes.Count();

			For Each MetadataObject In Metadata[ChoiceObject.Value] Do
				For Each MetadataObject1 In MetadataObject.AddressingAttributes Do

					NewRow = MetadataTable.Add();

					NewRow.AttributeName = MetadataObject1.Name;
					NewRow.AttributeSynonym = MetadataObject1.Synonym;
					NewRow.TypeDescription = ExcludeInvalidTypes(MetadataObject1.Type);
					NewRow.MetadataObject = ChoiceObject.Value;

				EndDo;
			EndDo;

		EndIf;

		If ChoiceObject.Value = "InformationRegisters" Or ChoiceObject.Value = "AccumulationRegisters"
			Or ChoiceObject.Value = "AccountingRegisters" Then
			AttributeCount = Metadata[ChoiceObject.Value][String(
				ChoiceObject)].StandardAttributes.Count() + Metadata[ChoiceObject.Value][String(
				ChoiceObject)].StandardAttributes.Count() + Metadata[ChoiceObject.Value][String(
				ChoiceObject)].Dimensions.Count() + Metadata[ChoiceObject.Value][String(
				ChoiceObject)].Resources.Count();

			NewRow = CommonAttributesTable.Add();

			NewRow.MetadataObject = ChoiceObject;
			NewRow.AttributeCount = AttributeCount;
			NewRow.Header = True;

		ElsIf ChoiceObject.Value <> "Constants" And ChoiceObject.Value <> "Sequences" Then

			AttributeCount = AttributeCount + Metadata[ChoiceObject.Value][String(
				ChoiceObject)].StandardAttributes.Count();

			NewRow = CommonAttributesTable.Add();

			NewRow.MetadataObject = ChoiceObject;
			NewRow.AttributeCount = AttributeCount;
			NewRow.Header = True;
		ElsIf ChoiceObject.Value = "Constants" Then
			AttributeCount = 1;
			NewRow = CommonAttributesTable.Add();
			NewRow.MetadataObject = ChoiceObject;
			NewRow.AttributeCount = AttributeCount;
			NewRow.Header = True;

			//
		ElsIf ChoiceObject.Value = "Sequences" Then

			AttributeCount = Metadata[ChoiceObject.Value][String(ChoiceObject)].Dimensions.Count();

			NewRow = CommonAttributesTable.Add();

			NewRow.MetadataObject = ChoiceObject;
			NewRow.AttributeCount = AttributeCount;
			NewRow.Header = True;

		EndIf;
 
		If ChoiceObject.Value="AccountingRegisters"  And Metadata[ChoiceObject.Value][String(ChoiceObject)].Correspondence Then
			NewRow = MetadataTable.Add();
            NewRow.AttributeName = "AccountDr";
            NewRow.AttributeSynonym = "AccountDr";
            NewRow.TypeDescription = ChartsOfAccounts.AllRefsType(); 
            NewRow.MetadataObject = ChoiceObject.Value;
                
            NewRow = MetadataTable.Add();
            NewRow.AttributeName = "AccountCr";
            NewRow.AttributeSynonym = "AccountCr";
            NewRow.TypeDescription = ChartsOfAccounts.AllRefsType(); 
            NewRow.MetadataObject = ChoiceObject.Value;
		EndIf;

	EndDo;

	CommonAttributesTable.Sort("AttributeCount asc");

	CommonAttributesTable.GroupBy("AttributeCount,MetadataObject,Header", "");

	If CommonAttributesTable.Count() > 1 Then

		ExcludeUniqueAttributes(CommonAttributesTable, False);

	EndIf;

	TypeDescriptionRef = New TypeDescription(RefTypesArray);

	NewRow = MetadataTable.Add();

	NewRow.AttributeName = "Ref";
	NewRow.AttributeSynonym = "Ref";
	NewRow.TypeDescription = TypeDescriptionRef;

	MetadataTable.Sort("Header asc,AttributeName asc");

	For Each AttributeItem In MetadataTable Do

		AttributeName = StrReplace(AttributeItem.AttributeName, ".", "*$");
		//AttributeName=AttributeItem.AttributeName;
		NewDataSetField = NewDataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		NewDataSetField.Title = AttributeItem.AttributeSynonym;

		NewDataSetField.Field = AttributeName;
		NewDataSetField.ValueType = AttributeItem.TypeDescription;
		NewDataSetField.DataPath = AttributeName;

		If AttributeItem.AttributeName = "TSName" Then

			NewDataSetField.UseRestriction.Condition = True;
			NewDataSetField.UseRestriction.Order = True;

		EndIf;

	EndDo;

	CompositionSettings = DataCompositionSchema.DefaultSettings;

	NewGroup = CompositionSettings.Structure.Add(Type("DataCompositionGroup"));
	NewGroup.Use = True;

	For Each AttributeItem In MetadataTable Do

		NewDataCompositionField = NewGroup.GroupFields.Items.Add(Type(
			"DataCompositionGroupField"));
		NewDataCompositionField.Use = True;

		NewDataCompositionField.Field = New DataCompositionField(AttributeItem.AttributeName);

		SelectedField = NewGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedField.Use = True;
		SelectedField.Title = AttributeItem.AttributeSynonym;
		SelectedField.Field = New DataCompositionField(AttributeItem.AttributeName);

	EndDo;

	DCSAddress = PutToTempStorage(DataCompositionSchema, ThisForm.UUID);

	SettingsSource = New DataCompositionAvailableSettingsSource(DCSAddress);

	Object.Composer.Initialize(SettingsSource);

	Object.Composer.LoadSettings(DataCompositionSchema.DefaultSettings);

	If ObjectType = "Documents" Then

		NewSortField = Object.Composer.Settings.Order.Items.Add(Type(
			"DataCompositionOrderItem"));
		NewSortField.Field = New DataCompositionField("Date");

		NewSortField = Object.Composer.Settings.Order.Items.Add(Type(
			"DataCompositionOrderItem"));
		NewSortField.Field = New DataCompositionField("Ref");

	ElsIf ObjectType = "ChartsOfCharacteristicTypes" Then

		InitializeAdditionalCharacteristicsFilter();

	EndIf;

EndProcedure

&AtServer
Procedure InitializeAdditionalCharacteristicsFilter()

	TypeDescription = New TypeDescription;

	For Each SelectedCharacteristic In ChoiceResult Do

		CharacteristicValueTypes = Metadata.ChartsOfCharacteristicTypes[SelectedCharacteristic.Value].Type;
		TypeDescription = New TypeDescription(TypeDescription, CharacteristicValueTypes.Types());

	EndDo;

//	CharacteristicValueType = New TypeDescription(TypeDescription);

EndProcedure

&AtServer
Procedure PrepareSelectedObjectsList(CurrentDataName, MetadataObjectName)

	ChoiceResult = New ValueList;
	PrepareSelectedItemsList(ChoiceResult, CurrentDataName, MetadataObjectName);

	FilterCache = Object.Composer.Settings.Filter.Items;

	If ChoiceResult <> Undefined Then

		MetadataTable.Clear();
		ObjectTypesTable.Clear();

		For Each ResultItem In ChoiceResult Do

			NewRow = ObjectTypesTable.Add();
			NewRow.TableName = ResultItem.Value;
			NewRow.TablePresentation = ResultItem.Presentation;

		EndDo;

		InitializeDCS();

	EndIf;

	VisibleColumnsCache.Clear();

	RestoreFilterFromCache(Object.Composer.Settings.Filter.Items, FilterCache,
		Object.Composer.Settings.Filter.FilterAvailableFields);

	ClearCA();

EndProcedure

&AtServer
Procedure ClearCA()
	;

	If ThisForm.ConditionalAppearance.Items.Count() > 0 Then

		ThisForm.ConditionalAppearance.Items.Clear();

	EndIf;

EndProcedure

&AtServer
Procedure PrepareSelectedItemsList(ChoiceList, CurrentDataName, MetadataObjectName)

	ObjectAtServer = FormAttributeToValue("Object");
	//ValueToFormAttribute(ObjectAtServer.MetadataTree, "Object.MetadataTree");
	MetadataTree1 = ObjectAtServer.MetadataTree;
	//FormAttributeToValue("MetadataTree");
	ItemGroupsList = MetadataTree1.Rows[0].Rows;

	For Each RowItem In ItemGroupsList Do
	//If RowItem.ExportData>0 Then
		For Each MetadataItem In RowItem.Rows Do
			If MetadataItem.MetadataFullName = CurrentDataName And MetadataItem.MetadataObjectName
				= MetadataObjectName Then
				ChoiceList.Add(RowItem.MetadataFullName, MetadataItem.MetadataFullName);
				Break;
			EndIf;
		EndDo;
		//EndIf;
	EndDo;

EndProcedure

&AtServer
Function ExcludeInvalidTypes(AttributeType)

	InvalidTypesArray = GetInvalidTypes();

	ExcludedTypesArray = New Array;

	For Each InvalidItem In InvalidTypesArray Do

		If AttributeType.ContainsType(InvalidItem) Then

			ExcludedTypesArray.Add(InvalidItem);

		EndIf;

	EndDo;

	If ExcludedTypesArray.Count() = 0 Then

		AttributeDetails = AttributeType;

	Else

		AttributeDetails = New TypeDescription(AttributeType, , ExcludedTypesArray);

	EndIf;

	Return AttributeDetails;

EndFunction

&AtServer
Procedure ExcludeUniqueAttributes(CommonAttributesTable, ProcessTS)

	CountTable = CommonAttributesTable.Copy();

	ResultTable = MetadataTable.Unload();

	CountTable.Columns.Add("Count");

	For Each Row In CountTable Do
		Row.Count = 1;
	EndDo;

	CountTable.Collapse("Header", "Count");

	ResultTable.Columns.Add("Count");
	//ResultTable.Columns.Add("Header");
	For Each Row In ResultTable Do
		Row.Count = 1;
		If Not ProcessTS Then
			Row.Header = True;
		ElsIf Upper(Left(Row.AttributeName, 6)) = "REF" Then
			Row.Header = True;
		Else
			Row.Header = False;
		EndIf;
	EndDo;

	//  Adjusting the number qualifiers to the same type.
	For Each Row In ResultTable Do
		If TrimAll(Row.TypeDescription) = "Number" Then
			Digits = Row.TypeDescription.NumberQualifiers.Digits;
			FractionDigits = Row.TypeDescription.NumberQualifiers.FractionDigits;
			//AllowedSign=Row.TypeDescription.NumberQualifiers.AllowedSign;
			Array = New Array;
			Array.Add(Type("Number"));

			NumberParameters = New NumberQualifiers(Digits, FractionDigits);

			Row.TypeDescription = New TypeDescription(Array, , , NumberParameters);

		EndIf;
	EndDo;

	ResultTable.Collapse("AttributeName,AttributeSynonym,TypeDescription,Header", "Count");

	// Deleting the non-duplicating items. 
	MaxCount = 0;
	For Each VRow In ResultTable Do
		If VRow.Count > MaxCount Then
			MaxCount = VRow.Count;
		EndIf;

	EndDo;

	Count = ResultTable.Количество();
	//MaxCount=ТаблКолич.Количество();
	While Count > 0 Do
		Row = ResultTable[Count - 1];
		If Row.Count <> MaxCount Then
			ResultTable.Delete(Row);
		EndIf;
		Count = Count - 1;
	EndDo;

	ResultTable.Collapse("AttributeName,AttributeSynonym,TypeDescription,Header", "");

	MetadataTable.Clear();
	MetadataTable.Load(ResultTable);

EndProcedure

&AtServerNoContext
Function GetInvalidTypes()

	InvalidTypesArray = New Array;
	InvalidTypesArray.Add(Type("ValueStorage"));

	Return InvalidTypesArray;

EndFunction

&AtClient
Procedure CopyFilter(Command)
// Insert handler content.
	CurrentDataName = Items.MetadataTree.CurrentData.MetadataFullName;
//	CurrentRow = Items.MetadataTree.CurrentRow;
//	CurrentData = Items.MetadataTree.CurrentData;
	CurrentItem = Items.MetadataTree.CurrentItem;

	CopyFilterAtServer(CurrentDataName);

EndProcedure

// Walks the tree and sets the ExportData checkbox.
&AtServer
Procedure CopyFilterAtServer(CurrentDataName)

	Tree1 = Object.MetadataTree.GetItems();

	//FormAttributeToValue("Object.MetadataTree");
	ObjectRef = FormAttributeToValue("Object");

	CurrFilterTable = ObjectRef.Composer.Settings.Filter;

	FilterTable1 = FormAttributeToValue("FilterTable");
//	CurrentTreeRowNo = 0;

	For Each ParentRow In Tree1[0].GetItems() Do
		If ParentRow.MetadataFullName <> "Constants" Then
			For Each TreeBranch In ParentRow.GetItems() Do
				TreeBranchSelect = False;

				If ParentRow.MetadataFullName = "Sequences" Then
					MetadataDimensions = Metadata[ParentRow.MetadataFullName][TreeBranch.MetadataFullName].Dimensions;
					For Each FilterRow In CurrFilterTable.Items Do
						For Each DimensionRow In MetadataDimensions Do
							If DimensionRow.Name = String(FilterRow.LeftValue) Then
								TreeBranchSelect = True;
								//Message(DimensionRow.Name);
								Found = False;
								For Each FilterRowTable In FilterTable1 Do
									If FilterRowTable.AttributeName = TreeBranch.MetadataFullName Then
										Found = True;
										FoundAttribute = False;
										For Each FilterRowTableFilter In FilterRowTable.Filter.Items Do
											If FilterRowTableFilter.LeftValue = FilterRow.LeftValue Then
												FoundAttribute = True;
												FillPropertyValues(FilterRowTableFilter, FilterRow);

												Break;
											EndIf;
										EndDo;
										If Not FoundAttribute Then

											NewField = FilterRowTable.Filter.Items.Add(Type(
												"DataCompositionFilterItem"));
											FillPropertyValues(NewField, FilterRow);

										EndIf;

										Break;
									EndIf;
								EndDo;

								If Not Found Then
								//NewRow.AttributeName=CurrentDataName;
									NewRow = FilterTable1.Add();
									NewRow.AttributeName = TreeBranch.MetadataFullName;
									NewRow.MetadataObjectName = ParentRow.MetadataFullName;

									NewField = NewRow.Filter.Items.Add(Type(
										"DataCompositionFilterItem"));
									FillPropertyValues(NewField, FilterRow);

								EndIf;

							EndIf;
						EndDo;
					EndDo;
				ElsIf ParentRow.MetadataFullName = "InformationRegisters"
					Or ParentRow.MetadataFullName = "AccumulationRegisters"
					Or ParentRow.MetadataFullName = "AccountingRegisters" Then

					MetadataDimensions = Metadata[ParentRow.MetadataFullName][TreeBranch.MetadataFullName].Dimensions;
					For Each FilterRow In CurrFilterTable.Items Do
						For Each DimensionRow In MetadataDimensions Do
							If DimensionRow.Name = String(FilterRow.LeftValue) Then
								TreeBranchSelect = True;

								Found = False;
								For Each FilterRowTable In FilterTable1 Do
									If FilterRowTable.AttributeName = TreeBranch.MetadataFullName Then
										Found = True;
										FoundAttribute = False;
										For Each FilterRowTableFilter In FilterRowTable.Filter.Items Do
											If FilterRowTableFilter.LeftValue = FilterRow.LeftValue Then
												FoundAttribute = True;
												FillPropertyValues(FilterRowTableFilter, FilterRow);

												Break;
											EndIf;
										EndDo;
										If Not FoundAttribute Then

											NewField = FilterRowTable.Filter.Items.Add(Type(
												"DataCompositionFilterItem"));
											FillPropertyValues(NewField, FilterRow);

										EndIf;

										Break;
									EndIf;
								EndDo;

								If Not Found Then
								//NewRow.AttributeName=CurrentDataName;
									NewRow = FilterTable1.Add();
									NewRow.AttributeName = TreeBranch.MetadataFullName;
									NewRow.MetadataObjectName = ParentRow.MetadataFullName;
									NewField = NewRow.Filter.Items.Add(Type(
										"DataCompositionFilterItem"));
									FillPropertyValues(NewField, FilterRow);

								EndIf;

								//Message(DimensionRow.Name);
							EndIf;
						EndDo;
					EndDo;

					MetadataAttributes = Metadata[ParentRow.MetadataFullName][TreeBranch.MetadataFullName].Attributes;
					For Each FilterRow In CurrFilterTable.Items Do
						For Each AttributesRow In MetadataAttributes Do
							If AttributesRow.Name = String(FilterRow.LeftValue) Then
								TreeBranchSelect = True;

								Found = False;
								For Each FilterRowTable In FilterTable1 Do
									If FilterRowTable.AttributeName = TreeBranch.MetadataFullName Then
										Found = True;
										FoundAttribute = False;
										For Each FilterRowTableFilter In FilterRowTable.Filter.Items Do
											If FilterRowTableFilter.LeftValue = FilterRow.LeftValue Then
												FoundAttribute = True;
												FillPropertyValues(FilterRowTableFilter, FilterRow);

												Break;
											EndIf;
										EndDo;
										If Not FoundAttribute Then

											NewField = FilterRowTable.Filter.Items.Add(Type(
												"DataCompositionFilterItem"));
											FillPropertyValues(NewField, FilterRow);

										EndIf;

										Break;
									EndIf;
								EndDo;

								If Not Found Then
								//NewRow.AttributeName=CurrentDataName;
									NewRow = FilterTable1.Add();
									NewRow.AttributeName = TreeBranch.MetadataFullName;
									NewRow.MetadataObjectName = ParentRow.MetadataFullName;

									NewField = NewRow.Filter.Items.Add(Type(
										"DataCompositionFilterItem"));
									FillPropertyValues(NewField, FilterRow);

								EndIf;

								//Message(AttributesRow.Name);
							EndIf;
						EndDo;
					EndDo;

					MetadataAttributes = Metadata[ParentRow.MetadataFullName][TreeBranch.MetadataFullName].StandardAttributes;
					For Each FilterRow In CurrFilterTable.Items Do
						For Each AttributesRow In MetadataAttributes Do
							If AttributesRow.Name = String(FilterRow.LeftValue) Then
								TreeBranchSelect = True;

								Found = False;
								For Each FilterRowTable In FilterTable1 Do
									If FilterRowTable.AttributeName = TreeBranch.MetadataFullName Then
										Found = True;
										FoundAttribute = False;
										For Each FilterRowTableFilter In FilterRowTable.Filter.Items Do
											If FilterRowTableFilter.LeftValue = FilterRow.LeftValue Then
												FoundAttribute = True;
												FillPropertyValues(FilterRowTableFilter, FilterRow);

												Break;
											EndIf;
										EndDo;
										If Not FoundAttribute Then

											NewField = FilterRowTable.Filter.Items.Add(Type(
												"DataCompositionFilterItem"));
											FillPropertyValues(NewField, FilterRow);

										EndIf;

										Break;
									EndIf;
								EndDo;

								If Not Found Then
								//NewRow.AttributeName=CurrentDataName;
									NewRow = FilterTable1.Add();
									NewRow.AttributeName = TreeBranch.MetadataFullName;
									NewRow.MetadataObjectName = ParentRow.MetadataFullName;
									NewField = NewRow.Filter.Items.Add(Type(
										"DataCompositionFilterItem"));
									FillPropertyValues(NewField, FilterRow);

								EndIf;

								//Message(AttributesRow.Name);
							EndIf;
						EndDo;
					EndDo;

				Else
					MetadataAttributes = Metadata[ParentRow.MetadataFullName][TreeBranch.MetadataFullName].Attributes;
					StandardAttributes = Metadata[ParentRow.MetadataFullName][TreeBranch.MetadataFullName].StandardAttributes;
					For Each FilterRow In CurrFilterTable.Items Do

						For Each AttributesRow In MetadataAttributes Do
							If AttributesRow.Name = String(FilterRow.LeftValue) Then
								TreeBranchSelect = True;

								// Adding filter to table.
								// Searching for an existing filter, if not found, adding a new one.
								// If filter is found, searching for an existing filter attribute, if found, replacing.
								// If not found, adding a new attribute. 
								Found = False;
								For Each FilterRowTable In FilterTable1 Do
									If FilterRowTable.AttributeName = TreeBranch.MetadataFullName Then
										Found = True;
										FoundAttribute = False;
										For Each FilterRowTableFilter In FilterRowTable.Filter.Items Do
											If FilterRowTableFilter.LeftValue = FilterRow.LeftValue Then
												FoundAttribute = True;
												FillPropertyValues(FilterRowTableFilter, FilterRow);

												Break;
											EndIf;
										EndDo;
										If Not FoundAttribute Then

											NewField = FilterRowTable.Filter.Items.Add(Type(
												"DataCompositionFilterItem"));
											FillPropertyValues(NewField, FilterRow);

										EndIf;

										Break;
									EndIf;
								EndDo;

								If Not Found Then
								//NewRow.AttributeName=CurrentDataName;
									NewRow = FilterTable1.Add();
									NewRow.AttributeName = TreeBranch.MetadataFullName;
									NewRow.MetadataObjectName = ParentRow.MetadataFullName;

									NewField = NewRow.Filter.Items.Add(Type(
										"DataCompositionFilterItem"));
									FillPropertyValues(NewField, FilterRow);

								EndIf;
							EndIf;
						EndDo;

						For Each AttributesRow In StandardAttributes Do
							If AttributesRow.Name = String(FilterRow.LeftValue) Then
								TreeBranchSelect = True;

								// Adding filter to table.
								// Searching for an existing filter, if not found, adding a new one.
								// If filter is found, searching for an existing filter attribute, if found, replacing.
								// If not found, adding a new attribute. 
								Found = False;
								For Each FilterRowTable In FilterTable1 Do
									If FilterRowTable.AttributeName = TreeBranch.MetadataFullName Then
										Found = True;
										FoundAttribute = False;
										For Each FilterRowTableFilter In FilterRowTable.Filter.Items Do
											If FilterRowTableFilter.LeftValue = FilterRow.LeftValue Then
												FoundAttribute = True;
												FillPropertyValues(FilterRowTableFilter, FilterRow);

												Break;
											EndIf;
										EndDo;
										If Not FoundAttribute Then
											NewField = FilterRowTable.Filter.Items.Add(Type(
												"DataCompositionFilterItem"));
											FillPropertyValues(NewField, FilterRow);
										EndIf;
										Break;
									EndIf;
								EndDo;

								If Not Found Then
									NewRow = FilterTable1.Add();
									NewRow.AttributeName = TreeBranch.MetadataFullName;
									NewRow.MetadataObjectName = ParentRow.MetadataFullName;

									NewField = NewRow.Filter.Items.Add(Type(
										"DataCompositionFilterItem"));
									FillPropertyValues(NewField, FilterRow);
								EndIf;
							EndIf;
							//
							//
						EndDo;
						If Find(String(FilterRow.LeftValue), ".") > 0 Then
							Found8 = False;
							For Each AttributesRow In StandardAttributes Do
								If Left(FilterRow.LeftValue, Find(String(FilterRow.LeftValue), ".")
									- 1) = AttributesRow.Name Then
									If FindAttributeInMetadataAttributesTree(
										Metadata[ParentRow.MetadataFullName][TreeBranch.MetadataFullName],
										Left(FilterRow.LeftValue, Find(String(FilterRow.LeftValue), ".")
										- 1), Right(FilterRow.LeftValue, StrLen(FilterRow.LeftValue)
										- Find(String(FilterRow.LeftValue), "."))) Then
										TreeBranchSelect = True;
										Found = False;
										For Each FilterRowTable In FilterTable1 Do
											If FilterRowTable.AttributeName = TreeBranch.MetadataFullName Then
												Found = True;
												FoundAttribute = False;
												For Each FilterRowTableFilter In FilterRowTable.Filter.Items Do
													If FilterRowTableFilter.LeftValue
														= FilterRow.LeftValue Then
														FoundAttribute = True;
														FillPropertyValues(FilterRowTableFilter, FilterRow);

														Break;
													EndIf;
												EndDo;
												If Not FoundAttribute Then
													NewField = FilterRowTable.Filter.Items.Add(Type(
														"DataCompositionFilterItem"));
													FillPropertyValues(NewField, FilterRow);
												EndIf;
												Break;
											EndIf;
										EndDo;

										If Not Found Then
											NewRow = FilterTable1.Add();
											NewRow.AttributeName = TreeBranch.MetadataFullName;
											NewRow.MetadataObjectName = ParentRow.MetadataFullName;

											NewField = NewRow.Filter.Items.Add(Type(
												"DataCompositionFilterItem"));
											FillPropertyValues(NewField, FilterRow);
										EndIf;

										Break;
									EndIf;
								EndIf;
							EndDo;
							If Not Found8 Then
								For Each AttributesRow In MetadataAttributes Do
									If Left(FilterRow.LeftValue, Find(String(FilterRow.LeftValue), ".")
										- 1) = AttributesRow.Name Then
										If FindAttributeInMetadataAttributesTree(
											Metadata[ParentRow.MetadataFullName][TreeBranch.MetadataFullName],
											Left(FilterRow.LeftValue, Find(String(FilterRow.LeftValue),
											".") - 1), Right(FilterRow.LeftValue, StrLen(
											FilterRow.LeftValue) - Find(String(FilterRow.LeftValue),
											"."))) Then
											TreeBranchSelect = True;
											Found = False;
											For Each FilterRowTable In FilterTable1 Do
												If FilterRowTable.AttributeName = TreeBranch.MetadataFullName Then
													Found = True;
													FoundAttribute = False;
													For Each FilterRowTableFilter In FilterRowTable.Filter.Items Do
														If FilterRowTableFilter.LeftValue
															= FilterRow.LeftValue Then
															FoundAttribute = True;
															FillPropertyValues(FilterRowTableFilter,
																FilterRow);

															Break;
														EndIf;
													EndDo;
													If Not FoundAttribute Then
														NewField = FilterRowTable.Filter.Items.Add(Type(
															"DataCompositionFilterItem"));
														FillPropertyValues(NewField, FilterRow);
													EndIf;
													Break;
												EndIf;
											EndDo;

											If Not Found Then
												NewRow = FilterTable1.Добавить();
												NewRow.AttributeName = TreeBranch.MetadataFullName;
												NewRow.MetadataObjectName = ParentRow.MetadataFullName;

												NewField = NewRow.Filter.Items.Add(Type(
													"DataCompositionFilterItem"));
												FillPropertyValues(NewField, FilterRow);
											EndIf;

											Break;
										EndIf;
									EndIf;
								EndDo;
							EndIf;
						EndIf;

					EndDo;
				EndIf;
				If TreeBranchSelect And Not TreeBranch.Select Then
					TreeBranch.PictureIndex = TreeBranch.PictureIndex + 1;
					TreeBranch.Select = TreeBranchSelect;
				EndIf;

			EndDo;
		EndIf;

	EndDo;

	ValueToFormAttribute(FilterTable1, "FilterTable");

EndProcedure

&AtServer
Function FindAttributeInMetadataAttributesTree(Metadata1, Attribute2, String1)
	ReturnValue = False;

	//Metadata.FindByType(Row.Type.Types()[0])
	Attributes1 = Metadata1.Attributes;

	StandardAttributes1 = Metadata1.StandardAttributes;

	For Each Row In StandardAttributes1 Do
		If Row.Name = Attribute2 Then

			If Not (String(Row.Type.Types()[0]) = "String" Or String(Row.Type.Types()[0]) = "Date" Or String(
				Row.Type.Types()[0]) = "Number" Or String(Row.Type.Types()[0]) = "Boolean") Then

				Metadata2 = Metadata.FindByType(Row.Type.Types()[0]);

				Attributes3 = Metadata2.Attributes;
				StandardAttributes3 = Metadata2.StandardAttributes;

				If Find(String1, ".") > 0 Then
					ReturnValue = FindAttributeInMetadataAttributesTree(Metadata2, Left(String1, Find(String1, ".")
						- 1), Right(String1, StrLen(String1) - Find(String1, ".")));
				Else
					For Each Row In StandardAttributes3 Do
						If Row.Name = String1 Then
							ReturnValue = True;
							Break;
						EndIf;
					EndDo;

					If Not ReturnValue Then
						For Each Row In Attributes3 Do
							If Row.Name = String1 Then
								ReturnValue = True;
								Break;
							EndIf;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
			//ReturnValue=True;
			Break;
		EndIf;
	EndDo;

	If Not ReturnValue Then
		For Each Row In Attributes1 Do
			If Row.Name = Attribute2 Then

				If Not (String(Row.Type.Types()[0]) = "String" Or String(Row.Type.Types()[0]) = "Date" Or String(
					Row.Type.Types()[0]) = "Number" Or String(Row.Type.Types()[0]) = "Boolean") Then

					Metadata2 = Metadata.FindByType(Row.Type.Types()[0]);

					Attributes3 = Metadata2.Attributes;
					StandardAttributes3 = Metadata2.StandardAttributes;
					If Find(String1, ".") > 0 Then
						ReturnValue = FindAttributeInMetadataAttributesTree(Metadata2, Left(String1, Find(
							String1, ".") - 1), Right(String1, StrLen(String1) - Find(String1, ".")));
					Else

						For Each Row In StandardAttributes3 Do
							If Row.Name = String1 Then
								ReturnValue = True;
								Break;
							EndIf;
						EndDo;

						If Not ReturnValue Then
							For Each Row In Attributes3 Do
								If Row.Name = String1 Then
									ReturnValue = True;
									Break;
								EndIf;
							EndDo;
						EndIf;
					EndIf;
				EndIf;
				//ReturnValue=True;
				Break;
			EndIf;
		EndDo;
	EndIf;

	Return ReturnValue;
EndFunction

&AtClient
Procedure MetadataTreeOnActivateRow(Item)
// Insert handler content.
	CurrentDataName = Items.MetadataTree.CurrentData.MetadataFullName;

	//ResultTableFilter.Clear();
	PrepareSelectedObjectsList(CurrentDataName, Items.MetadataTree.CurrentData.MetadataObjectName);

	RefreshFilterOnActivateAtServer(CurrentDataName, Items.MetadataTree.CurrentData.MetadataObjectName);

EndProcedure

&AtServer
Procedure RefreshFilterOnActivateAtServer(CurrentDataName, MetadataObjectName)
	;

	//	ObjectAtServer = FormAttributeToValue("Object");
	//ValueToFormAttribute(ObjectAtServer.MetadataTree, "Object.MetadataTree");
	//	MetadataTree1 = ObjectAtServer.MetadataTree;

	FilterTable1 = FormAttributeToValue("FilterTable");

	Filter = Object.Composer.Settings.Filter;
	Filter.Items.Clear();

	For Each Row In FilterTable1 Do
		If Row.AttributeName = CurrentDataName And Row.MetadataObjectName = MetadataObjectName Then

			RestoreFilterFromCache(Filter.Items, Row.Filter.Items, Row.Filter.FilterAvailableFields);

			//NewField  = Filter.Items.Add(Type("DataCompositionFilterItem"));
			//FillPropertyValues(NewField, Row.Filter);
			//		
			//ObjectAtServer.Composer.Settings.Filter.Items.Add(Row.Filter);
			//=Row.Filter;
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure FilterOnEditEnd(Item, NewRow, CancelEdit)
		// Insert handler content.
	If Not CancelEdit Then

		Select = RefreshFilterTableAtServer(Items.MetadataTree.CurrentData.MetadataFullName,
			Items.MetadataTree.CurrentData.MetadataObjectName);

		If Select And Not Items.MetadataTree.CurrentData.Select Then
			ThisForm.Items.MetadataTree.CurrentData.PictureIndex = ThisForm.Items.MetadataTree.CurrentData.PictureIndex
				+ 1;
		ElsIf Not (Select And Items.MetadataTree.CurrentData.Select) Then
			ThisForm.Items.MetadataTree.CurrentData.PictureIndex = ThisForm.Items.MetadataTree.CurrentData.PictureIndex
				- 1;
		EndIf;

		Items.MetadataTree.CurrentData.Select = Select;

	EndIf;

EndProcedure

&AtServer
Procedure RestoreFilterFromCache(FilterItems, FilterCache, FilterAvailableFields)

	If FilterCache.Count() > 0 Then

		For Each FilterItem In FilterCache Do

			If TypeOf(FilterItem) = Type("DataCompositionFilterItemGroup") Then

				NewField = FilterItems.Add(Type("DataCompositionFilterItemGroup"));
				FillPropertyValues(NewField, FilterItem);
				RestoreFilterFromCache(NewField.Items, FilterItem.Items, FilterAvailableFields);

			Else

				If Object.Composer.Settings.Filter.FilterAvailableFields.FindField(FilterItem.LeftValue)
					<> Undefined Then

					NewField = FilterItems.Add(Type("DataCompositionFilterItem"));
					FillPropertyValues(NewField, FilterItem);

				EndIf;

			EndIf;

		EndDo;

	EndIf;

EndProcedure

//@skip-warning
Procedure SetFilterAvailableFields(Filter, FilterAvailableFields)
EndProcedure

&AtServer
Function RefreshFilterTableAtServer(MetadataFullName, MetadataObjectName)

	FilterRef = Object.Composer.Settings.Filter;

	FilterTable1 = FormAttributeToValue("FilterTable");

	Count = FilterTable1.Count();
	While Count > 0 Do
		Row = FilterTable1[Count - 1];
		If Row.AttributeName = MetadataFullName And Row.MetadataObjectName = MetadataObjectName Then
			FilterTable1.Delete(Row);
		EndIf;

		Count = Count - 1;
	EndDo;

	Select = False;

	//Found=Find(MetadataFullName, "AttributeName");
	//
	//If Found>0 Then
	//	NewRow=FilterTable1[Found];
	//	NewRow.Filter=FilterRef;
	//Else
	If FilterRef.Items.Count() > 0 Then
		NewRow = FilterTable1.Add();
		NewRow.AttributeName = MetadataFullName;
		NewRow.MetadataObjectName = MetadataObjectName;

		RestoreFilterFromCache(NewRow.Filter.Items, FilterRef.Items, FilterRef.FilterAvailableFields);
		SetFilterAvailableFields(NewRow.Filter, FilterRef.FilterAvailableFields);
		//NewRow.Filter=FilterRef;
		//EndIf;
		Select = True;
	Else
		Select = False;
	EndIf;

	ValueToFormAttribute(FilterTable1, "FilterTable");

	//MetadataTree1= FormAttributeToValue("Object.MetadataTree");
	//ValueToFormAttribute(ObjectAtServer.MetadataTree, "Object.MetadataTree");
	//MetadataTree1 = ObjectAtServer.MetadataTree;
	Return Select;

EndFunction

&AtClient
Procedure FilterAfterDeleteRow(Item)

	Select = RefreshFilterTableAtServer(Items.MetadataTree.CurrentData.MetadataFullName,
		Items.MetadataTree.CurrentData.MetadataObjectName);

	If Select And Not Items.MetadataTree.CurrentData.Select Then
		ThisForm.Items.MetadataTree.CurrentData.PictureIndex = ThisForm.Items.MetadataTree.CurrentData.PictureIndex
			+ 1;
	ElsIf Not (Select And Items.MetadataTree.CurrentData.Select) Then
		ThisForm.Items.MetadataTree.CurrentData.PictureIndex = ThisForm.Items.MetadataTree.CurrentData.PictureIndex
			- 1;
	EndIf;

	Items.MetadataTree.CurrentData.Select = Select;

EndProcedure

&AtServer
Procedure DeleteFilterAtServer()
// Insert handler content.
	FilterTable1 = FormAttributeToValue("FilterTable");

	FilterTable1.Clear();

	ValueToFormAttribute(FilterTable1, "FilterTable");

	Object.Composer.Settings.Filter.Items.Clear();

	Tree1 = Object.MetadataTree.GetItems();

	For Each ParentRow In Tree1[0].GetItems() Do
		For Each TreeBranch In ParentRow.GetItems() Do
			If TreeBranch.Select Then
				TreeBranch.PictureIndex = TreeBranch.PictureIndex - 1;
				TreeBranch.Select = False;
			EndIf;
		EndDo;
	EndDo;

EndProcedure

&AtClient
Procedure DeleteFilter(Command)
	DeleteFilterAtServer();
EndProcedure

&AtServer
Procedure DeletePredefinedItemsAtServer()
// Insert handler content.
	For Each Row In Metadata.ChartsOfAccounts Do
		Query = New Query;
		Query.Text = "SELECT
					 |	" + Row.Name + ".Ref AS Ref
									   |FROM
									   |	ChartOfAccounts." + Row.Name + " AS " + Row.Name + "
																							   |WHERE
																							   |	"
			+ Row.Name + ".Predefined";

		ExportTable = Query.Execute().Unload();

		Count = ExportTable.Count();

		While Count > 0 Do
			Object1 = ExportTable[Count - 1].Ref.GetObject();
			If Object1 <> Undefined Then
				Try
					Object1.DataExchange.Load = True;
					Object1.Delete();
				Except
				EndTry;
			EndIf;
			Count = Count - 1;
		EndDo;
	EndDo;

	For Each Row In Metadata.Catalogs Do
		Query = New Query;
		Query.Text = "SELECT
					 |	" + Row.Name + ".Ref AS Ref
									   |FROM
									   |	Catalog." + Row.Name + " AS " + Row.Name + "
																					   |WHERE
																					   |	"
			+ Row.Name + ".Predefined";

		ExportTable = Query.Execute().Unload();

		Count = ExportTable.Count();

		While Count > 0 Do
			Object1 = ExportTable[Count - 1].Ref.GetObject();
			If Object1 <> Undefined Then
				Try
					Object1.DataExchange.Load = True;
					Object1.Delete();
				Except
				EndTry;
			EndIf;
			Count = Count - 1;
		EndDo;
	EndDo;

	For Each Row In Metadata.ChartsOfCharacteristicTypes Do
		Query = New Query;
		Query.Text = "SELECT
					 |	" + Row.Name + ".Ref AS Ref
									   |FROM
									   |	ChartOfCharacteristicTypes." + Row.Name + " AS " + Row.Name + "
																										  |WHERE
																										  |	"
			+ Row.Name + ".Predefined";

		ExportTable = Query.Execute().Unload();

		Count = ExportTable.Count();

		While Count > 0 Do
			Object1 = ExportTable[Count - 1].Ref.GetObject();
			If Object1 <> Undefined Then
				Try
					Object1.DataExchange.Load = True;
					Object1.Delete();
				Except
				EndTry;
			EndIf;
			Count = Count - 1;
		EndDo;
	EndDo;

	For Each Row In Metadata.ChartsOfCalculationTypes Do
		Query = New Query;
		Query.Text = "SELECT
					 |	" + Row.Name + ".Ref AS Ref
									   |FROM
									   |	ChartOfCalculationTypes." + Row.Name + " AS " + Row.Name + "
																									   |WHERE
																									   |	"
			+ Row.Name + ".Predefined";

		ExportTable = Query.Execute().Unload();

		Count = ExportTable.Count();

		While Count > 0 Do
			Object1 = ExportTable[Count - 1].Ref.GetObject();
			If Object1 <> Undefined Then
				Try
					Object1.DataExchange.Load = True;
					Object1.Delete();
				Except
				EndTry;
			EndIf;
			Count = Count - 1;
		EndDo;
	EndDo;

EndProcedure

&AtClient
Procedure DeletePredefinedItems(Command)

	Mode = QuestionDialogMode.YesNo;
	Notification = New NotifyDescription("AfterCloseQuery", ThisObject, Parameters);
	ShowQueryBox(Notification, НСтр("ru = 'Внимание! после удаления всех предопределенных элементов будет нарушена структура данных и   
									|Вы, возможно, не сможете зайти в программу снова (!) 
									|Вы готовы сразу после выполнения загрузить новые предопределенные элементы из файла ?
									|Продолжить выполнение операции?';" + " en = 'Warning! After the deleting predefined items  structure of the data will be broken 
																		  |and you will not start the programm. Did you prepared to load the predefined items from file ?
																		  |Do you want to continue?'"), Mode, 0);
		//...
EndProcedure

&AtClient
Procedure AfterCloseQuery(Result, Parameters) Export
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;

	DeletePredefinedItemsAtServer();

	//...
EndProcedure

&AtClient
Procedure CheckSelected(Command)

	SelectedRows = Items.MetadataTree.SelectedRows;

	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;

	For Each Row In SelectedRows Do
		If TypeOf(Row) = Type("Number") Then
			RowData = Items.MetadataTree.RowData(Row);
		Else
			RowData = Row;
		EndIf;
		//	
		RowData.ExportData = True;
	EndDo;
	//
	//		ThisForm.RefreshDataRepresentation(Items.MetadataTree);
EndProcedure

&AtClient
Procedure UncheckSelected(Command)

	SelectedRows = Items.MetadataTree.SelectedRows;

	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;

	For Each Row In SelectedRows Do
		If TypeOf(Row) = Type("Number") Then
			RowData = Items.MetadataTree.RowData(Row);
		Else
			RowData = Row;
		EndIf;
		//	
		RowData.ExportData = False;
	EndDo;
	//
	//		ThisForm.RefreshDataRepresentation(Items.MetadataTree);
EndProcedure

//ThisForm.Items.MetadataTree.CurrentData.PictureIndex=4;

#EndRegion