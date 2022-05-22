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

//@skip-warning
&AtClient
Procedure ImportFileNameOpen(Item, StandardProcessing)
	
	OpenInApplication(Item, "ImportFileName", StandardProcessing);

EndProcedure

//@skip-warning
&AtClient
Procedure ImportFileNameStartChoice(Item, ChoiceData, StandardProcessing)

	ProcessFileChoiceStart(StandardProcessing);

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

// Обходим дерево и проставляем флажок выводить
&AtServer
Procedure CopyFilterAtServer(ТекущиеДанныеИмя)

	Дерево1 = Object.MetadataTree.GetItems();

	//FormAttributeToValue("Object.MetadataTree");
	ОбъектСсылка = FormAttributeToValue("Object");

	ТаблицаОтбораТекущ = ОбъектСсылка.Composer.Настройки.Filter;

	ТаблицаОтбора1 = FormAttributeToValue("ТаблицаОтбора");
//	НомерТекущейСтрокиДерева = 0;

	For Each СтрокаРодитель Из Дерево1[0].GetItems() Do
		If СтрокаРодитель.MetadataFullName <> "Константы" Then
			For Each ВетвьДерева Из СтрокаРодитель.GetItems() Do
				ВетвьДереваВыделить = False;

				If СтрокаРодитель.MetadataFullName = "Последовательности" Then
					МетадатаИзмерения = Метаданные[СтрокаРодитель.MetadataFullName][ВетвьДерева.MetadataFullName].Измерения;
					For Each СтрокаОтбора Из ТаблицаОтбораТекущ.Элементы Do
						For Each СтрокаИзмерения Из МетадатаИзмерения Do
							If СтрокаИзмерения.Имя = Строка(СтрокаОтбора.ЛевоеЗначение) Then
								ВетвьДереваВыделить = True;
								//Сообщить(СтрокаИзмерения.Имя);
								Найдено = False;
								For Each СтрокаОтбораТаблица Из ТаблицаОтбора1 Do
									If СтрокаОтбораТаблица.ИмяРеквизита = ВетвьДерева.MetadataFullName Then
										Найдено = True;
										НайденоРеквизит = False;
										For Each СтрокаОтбораТаблицаОтбор Из СтрокаОтбораТаблица.Filter.Элементы Do
											If СтрокаОтбораТаблицаОтбор.ЛевоеЗначение = СтрокаОтбора.ЛевоеЗначение Then
												НайденоРеквизит = True;
												FillPropertyValues(СтрокаОтбораТаблицаОтбор, СтрокаОтбора);

												Break;
											EndIf;
										EndDo;
										If Не НайденоРеквизит Then

											НовоеПоле = СтрокаОтбораТаблица.Filter.Элементы.Добавить(Тип(
												"ЭлементОтбораКомпоновкиДанных"));
											FillPropertyValues(НовоеПоле, СтрокаОтбора);

										EndIf;

										Break;
									EndIf;
								EndDo;

								If Не Найдено Then
								//НоваяСтрока.ИмяРеквизита=ТекущиеДанныеИмя;
									НоваяСтрока = ТаблицаОтбора1.Добавить();
									НоваяСтрока.ИмяРеквизита = ВетвьДерева.MetadataFullName;
									НоваяСтрока.ИмяОбъектаМетаданных = СтрокаРодитель.MetadataFullName;

									НовоеПоле = НоваяСтрока.Filter.Элементы.Добавить(Тип(
										"ЭлементОтбораКомпоновкиДанных"));
									FillPropertyValues(НовоеПоле, СтрокаОтбора);

								EndIf;

							EndIf;
						EndDo;
					EndDo;
				ElsIf СтрокаРодитель.MetadataFullName = "РегистрыСведений"
					Или СтрокаРодитель.MetadataFullName = "РегистрыНакопления"
					Или СтрокаРодитель.MetadataFullName = "РегистрыБухгалтерии" Then

					МетадатаИзмерения = Метаданные[СтрокаРодитель.MetadataFullName][ВетвьДерева.MetadataFullName].Измерения;
					For Each СтрокаОтбора Из ТаблицаОтбораТекущ.Элементы Do
						For Each СтрокаИзмерения Из МетадатаИзмерения Do
							If СтрокаИзмерения.Имя = Строка(СтрокаОтбора.ЛевоеЗначение) Then
								ВетвьДереваВыделить = True;

								Найдено = False;
								For Each СтрокаОтбораТаблица Из ТаблицаОтбора1 Do
									If СтрокаОтбораТаблица.ИмяРеквизита = ВетвьДерева.MetadataFullName Then
										Найдено = True;
										НайденоРеквизит = False;
										For Each СтрокаОтбораТаблицаОтбор Из СтрокаОтбораТаблица.Filter.Элементы Do
											If СтрокаОтбораТаблицаОтбор.ЛевоеЗначение = СтрокаОтбора.ЛевоеЗначение Then
												НайденоРеквизит = True;
												FillPropertyValues(СтрокаОтбораТаблицаОтбор, СтрокаОтбора);

												Break;
											EndIf;
										EndDo;
										If Не НайденоРеквизит Then

											НовоеПоле = СтрокаОтбораТаблица.Filter.Элементы.Добавить(Тип(
												"ЭлементОтбораКомпоновкиДанных"));
											FillPropertyValues(НовоеПоле, СтрокаОтбора);

										EndIf;

										Break;
									EndIf;
								EndDo;

								If Не Найдено Then
								//НоваяСтрока.ИмяРеквизита=ТекущиеДанныеИмя;
									НоваяСтрока = ТаблицаОтбора1.Добавить();
									НоваяСтрока.ИмяРеквизита = ВетвьДерева.MetadataFullName;
									НоваяСтрока.ИмяОбъектаМетаданных = СтрокаРодитель.MetadataFullName;
									НовоеПоле = НоваяСтрока.Filter.Элементы.Добавить(Тип(
										"ЭлементОтбораКомпоновкиДанных"));
									FillPropertyValues(НовоеПоле, СтрокаОтбора);

								EndIf;

								//Сообщить(СтрокаИзмерения.Имя);
							EndIf;
						EndDo;
					EndDo;

					Метадатареквизиты = Метаданные[СтрокаРодитель.MetadataFullName][ВетвьДерева.MetadataFullName].Реквизиты;
					For Each СтрокаОтбора Из ТаблицаОтбораТекущ.Элементы Do
						For Each СтрокаРеквизиты Из Метадатареквизиты Do
							If СтрокаРеквизиты.Имя = Строка(СтрокаОтбора.ЛевоеЗначение) Then
								ВетвьДереваВыделить = True;

								Найдено = False;
								For Each СтрокаОтбораТаблица Из ТаблицаОтбора1 Do
									If СтрокаОтбораТаблица.ИмяРеквизита = ВетвьДерева.MetadataFullName Then
										Найдено = True;
										НайденоРеквизит = False;
										For Each СтрокаОтбораТаблицаОтбор Из СтрокаОтбораТаблица.Filter.Элементы Do
											If СтрокаОтбораТаблицаОтбор.ЛевоеЗначение = СтрокаОтбора.ЛевоеЗначение Then
												НайденоРеквизит = True;
												FillPropertyValues(СтрокаОтбораТаблицаОтбор, СтрокаОтбора);

												Break;
											EndIf;
										EndDo;
										If Не НайденоРеквизит Then

											НовоеПоле = СтрокаОтбораТаблица.Filter.Элементы.Добавить(Тип(
												"ЭлементОтбораКомпоновкиДанных"));
											FillPropertyValues(НовоеПоле, СтрокаОтбора);

										EndIf;

										Break;
									EndIf;
								EndDo;

								If Не Найдено Then
								//НоваяСтрока.ИмяРеквизита=ТекущиеДанныеИмя;
									НоваяСтрока = ТаблицаОтбора1.Добавить();
									НоваяСтрока.ИмяРеквизита = ВетвьДерева.MetadataFullName;
									НоваяСтрока.ИмяОбъектаМетаданных = СтрокаРодитель.MetadataFullName;

									НовоеПоле = НоваяСтрока.Filter.Элементы.Добавить(Тип(
										"ЭлементОтбораКомпоновкиДанных"));
									FillPropertyValues(НовоеПоле, СтрокаОтбора);

								EndIf;

								//Сообщить(СтрокаРеквизиты.Имя);
							EndIf;
						EndDo;
					EndDo;

					Метадатареквизиты = Метаданные[СтрокаРодитель.MetadataFullName][ВетвьДерева.MetadataFullName].StandardAttributes;
					For Each СтрокаОтбора Из ТаблицаОтбораТекущ.Элементы Do
						For Each СтрокаРеквизиты Из Метадатареквизиты Do
							If СтрокаРеквизиты.Имя = Строка(СтрокаОтбора.ЛевоеЗначение) Then
								ВетвьДереваВыделить = True;

								Найдено = False;
								For Each СтрокаОтбораТаблица Из ТаблицаОтбора1 Do
									If СтрокаОтбораТаблица.ИмяРеквизита = ВетвьДерева.MetadataFullName Then
										Найдено = True;
										НайденоРеквизит = False;
										For Each СтрокаОтбораТаблицаОтбор Из СтрокаОтбораТаблица.Filter.Элементы Do
											If СтрокаОтбораТаблицаОтбор.ЛевоеЗначение = СтрокаОтбора.ЛевоеЗначение Then
												НайденоРеквизит = True;
												FillPropertyValues(СтрокаОтбораТаблицаОтбор, СтрокаОтбора);

												Break;
											EndIf;
										EndDo;
										If Не НайденоРеквизит Then

											НовоеПоле = СтрокаОтбораТаблица.Filter.Элементы.Добавить(Тип(
												"ЭлементОтбораКомпоновкиДанных"));
											FillPropertyValues(НовоеПоле, СтрокаОтбора);

										EndIf;

										Break;
									EndIf;
								EndDo;

								If Не Найдено Then
								//НоваяСтрока.ИмяРеквизита=ТекущиеДанныеИмя;
									НоваяСтрока = ТаблицаОтбора1.Добавить();
									НоваяСтрока.ИмяРеквизита = ВетвьДерева.MetadataFullName;
									НоваяСтрока.ИмяОбъектаМетаданных = СтрокаРодитель.MetadataFullName;
									НовоеПоле = НоваяСтрока.Filter.Элементы.Добавить(Тип(
										"ЭлементОтбораКомпоновкиДанных"));
									FillPropertyValues(НовоеПоле, СтрокаОтбора);

								EndIf;

								//Сообщить(СтрокаРеквизиты.Имя);
							EndIf;
						EndDo;
					EndDo;

				Else
					Метадатареквизиты = Метаданные[СтрокаРодитель.MetadataFullName][ВетвьДерева.MetadataFullName].Реквизиты;
					StandardAttributes = Метаданные[СтрокаРодитель.MetadataFullName][ВетвьДерева.MetadataFullName].StandardAttributes;
					For Each СтрокаОтбора Из ТаблицаОтбораТекущ.Элементы Do

						For Each СтрокаРеквизиты Из Метадатареквизиты Do
							If СтрокаРеквизиты.Имя = Строка(СтрокаОтбора.ЛевоеЗначение) Then
								ВетвьДереваВыделить = True;

								//  Добавляем Filter в таблицу
								// Ищем существующий Filter в таблице, If нет то добавляем новый
								// If находим то ищем существующий реквизит отбора, If находим заменяем его
								// If нет то просто дабавляем 
								Найдено = False;
								For Each СтрокаОтбораТаблица Из ТаблицаОтбора1 Do
									If СтрокаОтбораТаблица.ИмяРеквизита = ВетвьДерева.MetadataFullName Then
										Найдено = True;
										НайденоРеквизит = False;
										For Each СтрокаОтбораТаблицаОтбор Из СтрокаОтбораТаблица.Filter.Элементы Do
											If СтрокаОтбораТаблицаОтбор.ЛевоеЗначение = СтрокаОтбора.ЛевоеЗначение Then
												НайденоРеквизит = True;
												FillPropertyValues(СтрокаОтбораТаблицаОтбор, СтрокаОтбора);

												Break;
											EndIf;
										EndDo;
										If Не НайденоРеквизит Then

											НовоеПоле = СтрокаОтбораТаблица.Filter.Элементы.Добавить(Тип(
												"ЭлементОтбораКомпоновкиДанных"));
											FillPropertyValues(НовоеПоле, СтрокаОтбора);

										EndIf;

										Break;
									EndIf;
								EndDo;

								If Не Найдено Then
								//НоваяСтрока.ИмяРеквизита=ТекущиеДанныеИмя;
									НоваяСтрока = ТаблицаОтбора1.Добавить();
									НоваяСтрока.ИмяРеквизита = ВетвьДерева.MetadataFullName;
									НоваяСтрока.ИмяОбъектаМетаданных = СтрокаРодитель.MetadataFullName;

									НовоеПоле = НоваяСтрока.Filter.Элементы.Добавить(Тип(
										"ЭлементОтбораКомпоновкиДанных"));
									FillPropertyValues(НовоеПоле, СтрокаОтбора);

								EndIf;
							EndIf;
						EndDo;

						For Each СтрокаРеквизиты Из StandardAttributes Do
							If СтрокаРеквизиты.Имя = Строка(СтрокаОтбора.ЛевоеЗначение) Then
								ВетвьДереваВыделить = True;

								//  Добавляем Filter в таблицу
								// Ищем существующий Filter в таблице, If нет то добавляем новый
								// If находим то ищем существующий реквизит отбора, If находим заменяем его
								// If нет то просто дабавляем 
								Найдено = False;
								For Each СтрокаОтбораТаблица Из ТаблицаОтбора1 Do
									If СтрокаОтбораТаблица.ИмяРеквизита = ВетвьДерева.MetadataFullName Then
										Найдено = True;
										НайденоРеквизит = False;
										For Each СтрокаОтбораТаблицаОтбор Из СтрокаОтбораТаблица.Filter.Элементы Do
											If СтрокаОтбораТаблицаОтбор.ЛевоеЗначение = СтрокаОтбора.ЛевоеЗначение Then
												НайденоРеквизит = True;
												FillPropertyValues(СтрокаОтбораТаблицаОтбор, СтрокаОтбора);

												Break;
											EndIf;
										EndDo;
										If Не НайденоРеквизит Then
											НовоеПоле = СтрокаОтбораТаблица.Filter.Элементы.Добавить(Тип(
												"ЭлементОтбораКомпоновкиДанных"));
											FillPropertyValues(НовоеПоле, СтрокаОтбора);
										EndIf;
										Break;
									EndIf;
								EndDo;

								If Не Найдено Then
									НоваяСтрока = ТаблицаОтбора1.Добавить();
									НоваяСтрока.ИмяРеквизита = ВетвьДерева.MetadataFullName;
									НоваяСтрока.ИмяОбъектаМетаданных = СтрокаРодитель.MetadataFullName;

									НовоеПоле = НоваяСтрока.Filter.Элементы.Добавить(Тип(
										"ЭлементОтбораКомпоновкиДанных"));
									FillPropertyValues(НовоеПоле, СтрокаОтбора);
								EndIf;
							EndIf;
							//
							//
						EndDo;
						If Найти(Строка(СтрокаОтбора.ЛевоеЗначение), ".") > 0 Then
							найдено8 = False;
							For Each СтрокаРеквизиты Из StandardAttributes Do
								If Лев(СтрокаОтбора.ЛевоеЗначение, Найти(Строка(СтрокаОтбора.ЛевоеЗначение), ".")
									- 1) = СтрокаРеквизиты.Имя Then
									If НайтиРеквизитВДеревеРевизитовМетаданных(
										Метаданные[СтрокаРодитель.MetadataFullName][ВетвьДерева.MetadataFullName],
										Лев(СтрокаОтбора.ЛевоеЗначение, Найти(Строка(СтрокаОтбора.ЛевоеЗначение), ".")
										- 1), Прав(СтрокаОтбора.ЛевоеЗначение, СтрДлина(СтрокаОтбора.ЛевоеЗначение)
										- Найти(Строка(СтрокаОтбора.ЛевоеЗначение), "."))) Then
										ВетвьДереваВыделить = True;
										Найдено = False;
										For Each СтрокаОтбораТаблица Из ТаблицаОтбора1 Do
											If СтрокаОтбораТаблица.ИмяРеквизита = ВетвьДерева.MetadataFullName Then
												Найдено = True;
												НайденоРеквизит = False;
												For Each СтрокаОтбораТаблицаОтбор Из СтрокаОтбораТаблица.Filter.Элементы Do
													If СтрокаОтбораТаблицаОтбор.ЛевоеЗначение
														= СтрокаОтбора.ЛевоеЗначение Then
														НайденоРеквизит = True;
														FillPropertyValues(СтрокаОтбораТаблицаОтбор, СтрокаОтбора);

														Break;
													EndIf;
												EndDo;
												If Не НайденоРеквизит Then
													НовоеПоле = СтрокаОтбораТаблица.Filter.Элементы.Добавить(Тип(
														"ЭлементОтбораКомпоновкиДанных"));
													FillPropertyValues(НовоеПоле, СтрокаОтбора);
												EndIf;
												Break;
											EndIf;
										EndDo;

										If Не Найдено Then
											НоваяСтрока = ТаблицаОтбора1.Добавить();
											НоваяСтрока.ИмяРеквизита = ВетвьДерева.MetadataFullName;
											НоваяСтрока.ИмяОбъектаМетаданных = СтрокаРодитель.MetadataFullName;

											НовоеПоле = НоваяСтрока.Filter.Элементы.Добавить(Тип(
												"ЭлементОтбораКомпоновкиДанных"));
											FillPropertyValues(НовоеПоле, СтрокаОтбора);
										EndIf;

										Break;
									EndIf;
								EndIf;
							EndDo;
							If Не найдено8 Then
								For Each СтрокаРеквизиты Из Метадатареквизиты Do
									If Лев(СтрокаОтбора.ЛевоеЗначение, Найти(Строка(СтрокаОтбора.ЛевоеЗначение), ".")
										- 1) = СтрокаРеквизиты.Имя Then
										If НайтиРеквизитВДеревеРевизитовМетаданных(
											Метаданные[СтрокаРодитель.MetadataFullName][ВетвьДерева.MetadataFullName],
											Лев(СтрокаОтбора.ЛевоеЗначение, Найти(Строка(СтрокаОтбора.ЛевоеЗначение),
											".") - 1), Прав(СтрокаОтбора.ЛевоеЗначение, СтрДлина(
											СтрокаОтбора.ЛевоеЗначение) - Найти(Строка(СтрокаОтбора.ЛевоеЗначение),
											"."))) Then
											ВетвьДереваВыделить = True;
											Найдено = False;
											For Each СтрокаОтбораТаблица Из ТаблицаОтбора1 Do
												If СтрокаОтбораТаблица.ИмяРеквизита = ВетвьДерева.MetadataFullName Then
													Найдено = True;
													НайденоРеквизит = False;
													For Each СтрокаОтбораТаблицаОтбор Из СтрокаОтбораТаблица.Filter.Элементы Do
														If СтрокаОтбораТаблицаОтбор.ЛевоеЗначение
															= СтрокаОтбора.ЛевоеЗначение Then
															НайденоРеквизит = True;
															FillPropertyValues(СтрокаОтбораТаблицаОтбор,
																СтрокаОтбора);

															Break;
														EndIf;
													EndDo;
													If Не НайденоРеквизит Then
														НовоеПоле = СтрокаОтбораТаблица.Filter.Элементы.Добавить(Тип(
															"ЭлементОтбораКомпоновкиДанных"));
														FillPropertyValues(НовоеПоле, СтрокаОтбора);
													EndIf;
													Break;
												EndIf;
											EndDo;

											If Не Найдено Then
												НоваяСтрока = ТаблицаОтбора1.Добавить();
												НоваяСтрока.ИмяРеквизита = ВетвьДерева.MetadataFullName;
												НоваяСтрока.ИмяОбъектаМетаданных = СтрокаРодитель.MetadataFullName;

												НовоеПоле = НоваяСтрока.Filter.Элементы.Добавить(Тип(
													"ЭлементОтбораКомпоновкиДанных"));
												FillPropertyValues(НовоеПоле, СтрокаОтбора);
											EndIf;

											Break;
										EndIf;
									EndIf;
								EndDo;
							EndIf;
						EndIf;

					EndDo;
				EndIf;
				If ВетвьДереваВыделить И Не ВетвьДерева.Выделить Then
					ВетвьДерева.PictureIndex = ВетвьДерева.PictureIndex + 1;
					ВетвьДерева.Выделить = ВетвьДереваВыделить;
				EndIf;

			EndDo;
		EndIf;

	EndDo;

	ValueToFormAttribute(ТаблицаОтбора1, "ТаблицаОтбора");

EndProcedure

&AtServer
Function НайтиРеквизитВДеревеРевизитовМетаданных(Метаданные1, Реквизит2, Строка1)
	ВозвращЗначение = False;

	//Метаданные.НайтиПоТипу(Строка.Тип.Типы()[0])
	Реквизиты1 = Метаданные1.Реквизиты;

	StandardAttributes1 = Метаданные1.StandardAttributes;

	For Each Строка Из StandardAttributes1 Do
		If Строка.имя = Реквизит2 Then

			If Не (Строка(Строка.Тип.Типы()[0]) = "Строка" Или Строка(Строка.Тип.Типы()[0]) = "Дата" Или Строка(
				Строка.Тип.Типы()[0]) = "Число" Или Строка(Строка.Тип.Типы()[0]) = "Булево") Then

				Метадата2 = Метаданные.НайтиПоТипу(Строка.Тип.Типы()[0]);

				Реквизиты3 = Метадата2.Реквизиты;
				StandardAttributes3 = Метадата2.StandardAttributes;

				If найти(Строка1, ".") > 0 Then
					ВозвращЗначение = НайтиРеквизитВДеревеРевизитовМетаданных(Метадата2, Лев(Строка1, найти(Строка1, ".")
						- 1), Прав(Строка1, СтрДлина(Строка1) - найти(Строка1, ".")));
				Else
					For Each Строка Из StandardAttributes3 Do
						If Строка.имя = Строка1 Then
							ВозвращЗначение = True;
							Break;
						EndIf;
					EndDo;

					If Не ВозвращЗначение Then
						For Each Строка Из Реквизиты3 Do
							If Строка.имя = Строка1 Then
								ВозвращЗначение = True;
								Break;
							EndIf;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
			//ВозвращЗначение=True;
			Break;
		EndIf;
	EndDo;

	If Не ВозвращЗначение Then
		For Each Строка Из Реквизиты1 Do
			If Строка.имя = Реквизит2 Then

				If Не (Строка(Строка.Тип.Типы()[0]) = "Строка" Или Строка(Строка.Тип.Типы()[0]) = "Дата" Или Строка(
					Строка.Тип.Типы()[0]) = "Число" Или Строка(Строка.Тип.Типы()[0]) = "Булево") Then

					Метадата2 = Метаданные.НайтиПоТипу(Строка.Тип.Типы()[0]);

					Реквизиты3 = Метадата2.Реквизиты;
					StandardAttributes3 = Метадата2.StandardAttributes;
					If найти(Строка1, ".") > 0 Then
						ВозвращЗначение = НайтиРеквизитВДеревеРевизитовМетаданных(Метадата2, Лев(Строка1, найти(
							Строка1, ".") - 1), Прав(Строка1, СтрДлина(Строка1) - найти(Строка1, ".")));
					Else

						For Each Строка Из StandardAttributes3 Do
							If Строка.имя = Строка1 Then
								ВозвращЗначение = True;
								Break;
							EndIf;
						EndDo;

						If Не ВозвращЗначение Then
							For Each Строка Из Реквизиты3 Do
								If Строка.имя = Строка1 Then
									ВозвращЗначение = True;
									Break;
								EndIf;
							EndDo;
						EndIf;
					EndIf;
				EndIf;
				//ВозвращЗначение=True;
				Break;
			EndIf;
		EndDo;
	EndIf;

	Return ВозвращЗначение;
EndFunction

&AtClient
Procedure MetadataTreeOnActivateRow(Элемент)
// Вставить содержимое обработчика.
	ТекущиеДанныеИмя = Элементы.MetadataTree.ТекущиеДанные.MetadataFullName;

	//ТаблицаРезультатОтбор.Очистить();
	PrepareSelectedObjectsList(ТекущиеДанныеИмя, Элементы.MetadataTree.ТекущиеДанные.ИмяОбъектаМетаданных);

	ОбновитьОтборПоАктивизацииНаСервере(ТекущиеДанныеИмя, Элементы.MetadataTree.ТекущиеДанные.ИмяОбъектаМетаданных);

EndProcedure

&AtServer
Procedure ОбновитьОтборПоАктивизацииНаСервере(ТекущиеДанныеИмя, ИмяОбъектаМетаданных)
	;

	//	ОбъектНаСервере = FormAttributeToValue("Object");
	//ValueToFormAttribute(ОбъектНаСервере.MetadataTree, "Object.MetadataTree");
	//	MetadataTree1 = ОбъектНаСервере.MetadataTree;

	ТаблицаОтбора1 = FormAttributeToValue("ТаблицаОтбора");

	Отбор = Object.Composer.Настройки.Filter;
	Отбор.Элементы.Очистить();

	For Each Строка Из ТаблицаОтбора1 Do
		If Строка.ИмяРеквизита = ТекущиеданныеИмя И Строка.ИмяОбъектаМетаданных = ИмяОбъектаМетаданных Then

			RestoreFilterFromCache(Отбор.Элементы, Строка.Filter.Элементы, Строка.Filter.ДоступныеПоляОтбора);

			//НовоеПоле  = Filter.Элементы.Добавить(Тип("ЭлементОтбораКомпоновкиДанных"));
			//FillPropertyValues(НовоеПоле, Строка.Filter);
			//		
			//ОбъектНаСервере.Composer.Настройки.Filter.Элементы.Добавить(Строка.Filter);
			//=Строка.Filter;
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure FilterOnEditEnd(Элемент, НоваяСтрока, ОтменаРедактирования)
		// Вставить содержимое обработчика.
	If Не ОтменаРедактирования Then

		Выделить = ОбновитьТаблицуОтборанаСервере(Элементы.MetadataTree.ТекущиеДанные.ПолноеИмяМетаданных,
			Элементы.MetadataTree.ТекущиеДанные.ИмяОбъектаМетаданных);

		If Выделить И Не Элементы.MetadataTree.ТекущиеДанные.Выделить Then
			ThisForm.Элементы.MetadataTree.ТекущиеДанные.PictureIndex = ThisForm.Элементы.MetadataTree.ТекущиеДанные.PictureIndex
				+ 1;
		ElsIf Не (Выделить И Элементы.MetadataTree.ТекущиеДанные.Выделить) Then
			ThisForm.Элементы.MetadataTree.ТекущиеДанные.PictureIndex = ThisForm.Элементы.MetadataTree.ТекущиеДанные.PictureIndex
				- 1;
		EndIf;

		Элементы.MetadataTree.ТекущиеДанные.Выделить = Выделить;

	EndIf;

EndProcedure

&AtServer
Procedure RestoreFilterFromCache(ЭлементыОтбора, КэшОтбора, ОтборДоступныеПоляОтбора)

	If КэшОтбора.Количество() > 0 Then

		For Each ЭлементОтбора Из КэшОтбора Do

			If ТипЗнч(ЭлементОтбора) = Тип("ГруппаЭлементовОтбораКомпоновкиДанных") Then

				НовоеПоле = ЭлементыОтбора.Добавить(Тип("ГруппаЭлементовОтбораКомпоновкиДанных"));
				FillPropertyValues(НовоеПоле, ЭлементОтбора);
				RestoreFilterFromCache(НовоеПоле.Элементы, ЭлементОтбора.Элементы, ОтборДоступныеПоляОтбора);

			Else

				If Object.Composer.Настройки.Filter.ДоступныеПоляОтбора.НайтиПоле(ЭлементОтбора.ЛевоеЗначение)
					<> Undefined Then

					НовоеПоле = ЭлементыОтбора.Добавить(Тип("ЭлементОтбораКомпоновкиДанных"));
					FillPropertyValues(НовоеПоле, ЭлементОтбора);

				EndIf;

			EndIf;

		EndDo;

	EndIf;

EndProcedure

//@skip-warning
Procedure УстановитьДоступныеПоляДляОтбора(Отбор, ОтборДоступныеПоляОтбора)
EndProcedure

&AtServer
Function ОбновитьТаблицуОтборанаСервере(ПолноеИмяМетаданных, ИмяОбъектаМетаданных)

	ОтборСсылка = Object.Composer.Настройки.Filter;

	ТаблицаОтбора1 = FormAttributeToValue("ТаблицаОтбора");

	Колво = ТаблицаОтбора1.Количество();
	Пока Колво > 0 Do
		Строка = ТаблицаОтбора1[КолВо - 1];
		If Строка.ИмяРеквизита = ПолноеИмяМетаданных И Строка.ИмяОбъектаМетаданных = ИмяОбъектаМетаданных Then
			ТаблицаОтбора1.Удалить(Строка);
		EndIf;

		КолВо = КолВо - 1;
	EndDo;

	Выделить = False;

	//Найдено=Найти(MetadataFullName, "ИмяРеквизита");
	//
	//If Найдено>0 Then
	//	НоваяСтрока=ТаблицаОтбора1[Найдено];
	//	НоваяСтрока.Filter=ОтборСсылка;
	//Else
	If ОтборСсылка.Элементы.Количество() > 0 Then
		НоваяСтрока = ТаблицаОтбора1.Добавить();
		НоваяСтрока.ИмяРеквизита = ПолноеИмяМетаданных;
		НоваяСтрока.ИмяОбъектаМетаданных = ИмяОбъектаМетаданных;

		RestoreFilterFromCache(НоваяСтрока.Filter.Элементы, ОтборСсылка.Элементы, ОтборСсылка.ДоступныеПоляОтбора);
		УстановитьДоступныеПоляДляОтбора(НоваяСтрока.Отбор, ОтборСсылка.ДоступныеПоляОтбора);
		//НоваяСтрока.Filter=ОтборСсылка;
		//EndIf;
		Выделить = True;
	Else
		Выделить = False;
	EndIf;

	ValueToFormAttribute(ТаблицаОтбора1, "ТаблицаОтбора");

	//MetadataTree1= FormAttributeToValue("Object.MetadataTree");
	//ValueToFormAttribute(ОбъектНаСервере.MetadataTree, "Object.MetadataTree");
	//MetadataTree1 = ОбъектНаСервере.MetadataTree;
	Return Выделить;

EndFunction

&AtClient
Procedure FilterAfterDeleteRow(Элемент)

	Выделить = ОбновитьТаблицуОтборанаСервере(Элементы.MetadataTree.ТекущиеДанные.ПолноеИмяМетаданных,
		Элементы.MetadataTree.ТекущиеДанные.ИмяОбъектаМетаданных);

	If Выделить И Не Элементы.MetadataTree.ТекущиеДанные.Выделить Then
		ThisForm.Элементы.MetadataTree.ТекущиеДанные.PictureIndex = ThisForm.Элементы.MetadataTree.ТекущиеДанные.PictureIndex
			+ 1;
	ElsIf Не (Выделить И Элементы.MetadataTree.ТекущиеДанные.Выделить) Then
		ThisForm.Элементы.MetadataTree.ТекущиеДанные.PictureIndex = ThisForm.Элементы.MetadataTree.ТекущиеДанные.PictureIndex
			- 1;
	EndIf;

	Элементы.MetadataTree.ТекущиеДанные.Выделить = Выделить;

EndProcedure

&AtServer
Procedure УдалитьОтборНаСервере()
// Вставить содержимое обработчика.
	ТаблицаОтбора1 = FormAttributeToValue("ТаблицаОтбора");

	ТаблицаОтбора1.Очистить();

	ValueToFormAttribute(ТаблицаОтбора1, "ТаблицаОтбора");

	Object.Composer.Настройки.Filter.Элементы.Очистить();

	Дерево1 = Object.MetadataTree.GetItems();

	For Each СтрокаРодитель Из Дерево1[0].GetItems() Do
		For Each ВетвьДерева Из СтрокаРодитель.GetItems() Do
			If ВетвьДерева.Выделить Then
				ВетвьДерева.PictureIndex = ВетвьДерева.PictureIndex - 1;
				ВетвьДерева.Выделить = False;
			EndIf;
		EndDo;
	EndDo;

EndProcedure

&AtClient
Procedure DeleteFilter(Команда)
	УдалитьОтборНаСервере();
EndProcedure

&AtServer
Procedure УдалитьПредопределенныеНаСервере()
// Вставить содержимое обработчика.
	For Each Строка Из Метаданные.ПланыСчетов Do
		Запрос = New запрос;
		Запрос.Текст = "ВЫБРАТЬ
					   |	" + Строка.Имя + ".Ссылка КАК Ссылка
											 |ИЗ
											 |	ПланСчетов." + Строка.Имя + " КАК " + Строка.Имя + "
																									 |ГДЕ
																									 |	"
			+ Строка.Имя + ".Предопределенный";

		Выгрузка = Запрос.Выполнить().Выгрузить();

		КолВо = Выгрузка.Количество();

		Пока КолВо > 0 Do
			Объект1 = Выгрузка[КолВо - 1].Ссылка.ПолучитьОбъект();
			If Объект1 <> Undefined Then
				Попытка
					Объект1.ОбменДанными.Загрузка = True;
					Объект1.Удалить();
				Исключение
				КонецПопытки;
			EndIf;
			КолВо = КолВо - 1;
		EndDo;
	EndDo;

	For Each Строка Из Метаданные.Справочники Do
		Запрос = New запрос;
		Запрос.Текст = "ВЫБРАТЬ
					   |	" + Строка.Имя + ".Ссылка КАК Ссылка
											 |ИЗ
											 |	Справочник." + Строка.Имя + " КАК " + Строка.Имя + "
																									 |ГДЕ
																									 |	"
			+ Строка.Имя + ".Предопределенный";

		Выгрузка = Запрос.Выполнить().Выгрузить();

		КолВо = Выгрузка.Количество();

		Пока КолВо > 0 Do
			Объект1 = Выгрузка[КолВо - 1].Ссылка.ПолучитьОбъект();
			If Объект1 <> Undefined Then
				Попытка
					Объект1.ОбменДанными.Загрузка = True;
					Объект1.Удалить();
				Исключение
				КонецПопытки;
			EndIf;
			КолВо = КолВо - 1;
		EndDo;
	EndDo;

	For Each Строка Из Метаданные.ПланыВидовХарактеристик Do
		Запрос = New запрос;
		Запрос.Текст = "ВЫБРАТЬ
					   |	" + Строка.Имя + ".Ссылка КАК Ссылка
											 |ИЗ
											 |	ПланВидовХарактеристик." + Строка.Имя + " КАК " + Строка.Имя + "
																												 |ГДЕ
																												 |	"
			+ Строка.Имя + ".Предопределенный";

		Выгрузка = Запрос.Выполнить().Выгрузить();

		КолВо = Выгрузка.Количество();

		Пока КолВо > 0 Do
			Объект1 = Выгрузка[КолВо - 1].Ссылка.ПолучитьОбъект();
			If Объект1 <> Undefined Then
				Попытка
					Объект1.ОбменДанными.Загрузка = True;
					Объект1.Удалить();
				Исключение
				КонецПопытки;
			EndIf;
			КолВо = КолВо - 1;
		EndDo;
	EndDo;

	For Each Строка Из Метаданные.ПланыВидовРасчета Do
		Запрос = New запрос;
		Запрос.Текст = "ВЫБРАТЬ
					   |	" + Строка.Имя + ".Ссылка КАК Ссылка
											 |ИЗ
											 |	ПланВидовРасчета." + Строка.Имя + " КАК " + Строка.Имя + "
																										   |ГДЕ
																										   |	"
			+ Строка.Имя + ".Предопределенный";

		Выгрузка = Запрос.Выполнить().Выгрузить();

		КолВо = Выгрузка.Количество();

		Пока КолВо > 0 Do
			Объект1 = Выгрузка[КолВо - 1].Ссылка.ПолучитьОбъект();
			If Объект1 <> Undefined Then
				Попытка
					Объект1.ОбменДанными.Загрузка = True;
					Объект1.Удалить();
				Исключение
				КонецПопытки;
			EndIf;
			КолВо = КолВо - 1;
		EndDo;
	EndDo;

EndProcedure

&AtClient
Procedure DeletePredefinedItems(Команда)

	Режим = РежимДиалогаВопрос.ДаНет;
	Оповещение = New NotifyDescription("ПослеЗакрытияВопроса", ThisObject, Parameters);
	ПоказатьВопрос(Оповещение, НСтр("ru = 'Внимание! после удаления всех предопределенных элементов будет нарушена Structure данных и   
									|Вы, возможно, не сможете зайти в программу снова (!) 
									|Вы готовы сразу после выполнения загрузить новые предопределенные элементы из файла ?
									|Continue выполнение операции?';" + " en = 'Warning! after the deleting predefined elements  structure of the data will be broken 
																		  |and you will not start the programm. Do you prepared to download the predefined elements from file ?
																		  |Do you want to continue?'"), Режим, 0);
		//...
EndProcedure

&AtClient
Procedure ПослеЗакрытияВопроса(Результат, Parameters) Export
	If Результат = КодReturnаДиалога.Нет Then
		Return;
	EndIf;

	УдалитьПредопределенныеНаСервере();

	//...
EndProcedure

&AtClient
Procedure CheckSelected(Команда)

	ВыделенныеСтроки = Элементы.MetadataTree.ВыделенныеСтроки;

	If ВыделенныеСтроки.Количество() = 0 Then
		Return;
	EndIf;

	For Each Стр Из ВыделенныеСтроки Do
		If ТипЗнч(Стр) = Тип("Число") Then
			ДанныеСтроки = Элементы.MetadataTree.ДанныеСтроки(Стр);
		Else
			ДанныеСтроки = Стр;
		EndIf;
		//	
		ДанныеСтроки.ExportData = True;
	EndDo;
	//
	//		ThisForm.ОбновитьОтображениеДанных(Элементы.MetadataTree);
EndProcedure

&AtClient
Procedure UncheckSelected(Команда)

	ВыделенныеСтроки = Элементы.MetadataTree.ВыделенныеСтроки;

	If ВыделенныеСтроки.Количество() = 0 Then
		Return;
	EndIf;

	For Each Стр Из ВыделенныеСтроки Do
		If ТипЗнч(Стр) = Тип("Число") Then
			ДанныеСтроки = Элементы.MetadataTree.ДанныеСтроки(Стр);
		Else
			ДанныеСтроки = Стр;
		EndIf;
		//	
		ДанныеСтроки.ExportData = False;
	EndDo;
	//
	//		ThisForm.ОбновитьОтображениеДанных(Элементы.MetadataTree);
EndProcedure

//ThisForm.Элементы.MetadataTree.ТекущиеДанные.PictureIndex=4;

#EndRegion