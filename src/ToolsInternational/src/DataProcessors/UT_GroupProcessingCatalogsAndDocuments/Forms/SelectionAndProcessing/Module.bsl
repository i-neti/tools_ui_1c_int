&AtClient
Var ProcessingDragAndDrop;

&AtServer
Function TypeDescription(TypeString) Export

	ArrayTypes = New Array;
	ArrayTypes.Add(Type(TypeString));
	TypeDescription = New TypeDescription(ArrayTypes);

	Return TypeDescription;

EndFunction


&AtServer
Function GetListTypesObjects()
	ValueTable = FormDataToValue(TableFieldTypesObjects, Type("ValueTable"));

	ListOfSelected = New ValueList;
	ListOfSelected.LoadValues(ValueTable.UnloadColumn("TableName"));

	Return ListOfSelected;
EndFunction

&AtClient
Procedure OpenFormSelectionTable()
	StructureParameters = New Structure;
	StructureParameters.Insert("ObjectType", Object.ObjectType);
	StructureParameters.Insert("ProcessTabularParts", Object.ProcessTabularParts);
	StructureParameters.Insert("ListOfSelected", GetListTypesObjects());

	OpenForm(GetFullFormName("FormSelectionTables"), StructureParameters, ThisObject, , , ,
		New NotifyDescription("OpenFormSelectionTableEnd", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure OpenFormSelectionTableEnd(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;

	TableFieldTypesObjects.Clear();
	For Each Value In Result Do

		String = TableFieldTypesObjects.Add();
		String.TableName = Value.Value;
		String.PresentationTable = Value.Presentation;

	EndDo;
	QueryInitialization();

EndProcedure

// () 
&AtClient
Procedure TableFieldTypesObjectsBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	OpenFormSelectionTable();
	Cancel = True;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
//	ProcessingDragAndDrop = False;
	ChoiceList = Items.SearchObject.ChoiceList;
	Items.SearchObject.ChoiceListHeight = 15;

	For Each Catalog In Metadata.Catalogs Do
		If AccessRight("View", Catalog) Then
			CatalogName = Catalog.Synonym;
			If CatalogName = "" Then
				CatalogName = Catalog.Name;
			EndIf;

			Structure = New Structure;
			Structure.Insert("Type", "Catalog");
			Structure.Insert("Name", Catalog.Name);
			Structure.Insert("Presentation", CatalogName);

			ChoiceList.Add(Structure, CatalogName, , PictureLib.Catalog);
		EndIf;
	EndDo;

	For Each Document In Metadata.Documents Do
		If AccessRight("View", Document) Then
			DocumentName = Document.Synonym;
			If DocumentName = "" Then
				DocumentName = Document.Name;
			EndIf;

			Structure = New Structure;
			Structure.Insert("Type", "Document");
			Structure.Insert("Name", Document.Name);
			Structure.Insert("Presentation", DocumentName);

			ChoiceList.Add(Structure, DocumentName, , PictureLib.Document);
		EndIf;
	EndDo;

	FormAttributeToValue("Object").DownloadDataProcessors(ThisForm, AvailableDataProcessors, SelectedDataProcessors);

	InConfigurationYesCategories = Metadata.Catalogs.Find("CategoriesObjects") <> Undefined;
	InConfigurationYesProperties = Metadata.ChartsOfCharacteristicTypes.Find("ObjectProperties") <> Undefined;
	InConfigurationYesOrderManagement = Metadata.InformationRegisters.Find(
		"ProductsUnusedInWebOrderManagement") <> Undefined;

	UT_Forms.CreateWriteParametersAttributesFormOnCreateAtServer(ThisObject,
		Items.GroupParametersRecord);
	UT_Common.ToolFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SearchObjectOnChange(Item)
	SearchObjectOnChangeAtServer();
EndProcedure

&AtServer
Procedure SearchObjectOnChangeAtServer()
//	SetVisibleAvalible();
	QueryText = GetQueryText();
	ArbitraryQueryText = QueryText;
	DataSelection = Undefined;
	QueryParameters.Clear();
EndProcedure

&AtServer
Function GenerateSearchConditionByString()
	SearchConditionByString = "";

	If SearchString <> "" Then
		SearchableObject = SearchObject;
		MetadataObject = Metadata.FindByFullName(SearchableObject.Type + "." + SearchableObject.Name);

		SearchConditionByString = "";

		StringForSearch = StrReplace(SearchString, """", """""");

		If SearchableObject.Type = "Catalog" Then
			If MetadataObject.DescriptionLength <> 0 Then
				If SearchConditionByString <> "" Then
					SearchConditionByString = SearchConditionByString + " OR ";
				EndIf;
				SearchConditionByString = SearchConditionByString + " Description LIKE ""%" + StringForSearch + "%""";
			EndIf;

			If MetadataObject.CodeLength <> 0 And MetadataObject.CodeType
				= Metadata.ObjectProperties.CatalogCodeType.String Then
				If SearchConditionByString <> "" Then
					SearchConditionByString = SearchConditionByString + " OR ";
				EndIf;
				SearchConditionByString = SearchConditionByString + " Code LIKE ""%" + StringForSearch + "%""";
			EndIf;
		ElsIf SearchableObject.Type = "Document" Then
			If MetadataObject.NumberType = Metadata.ObjectProperties.DocumentNumberType.String Then
				If SearchConditionByString <> "" Then
					SearchConditionByString = SearchConditionByString + " OR ";
				EndIf;
				SearchConditionByString = SearchConditionByString + " Number LIKE ""%" + StringForSearch + "%""";
			EndIf;
		EndIf;

		For Each Attribute In MetadataObject.Attributes Do
			If Attribute.Type.ContainsType(Type("String")) Then
				If SearchConditionByString <> "" Then
					SearchConditionByString = SearchConditionByString + " OR ";
				EndIf;
				SearchConditionByString = SearchConditionByString + Attribute.Name + " LIKE ""%" + StringForSearch + "%""";
			EndIf;
		EndDo;
	EndIf;

	Return SearchConditionByString;
EndFunction

&AtServer
Function GetQueryText()

	SearchableObject = SearchObject;
	MetadataObject = Metadata.FindByFullName(SearchableObject.Type + "." + SearchableObject.Name);
	Condition = "";

	QueryText = "Select 
				   |	Ref As Object, 
				   |	Presentation";

	If SearchableObject.Type = "Catalog" Then
		If MetadataObject.DefaultPresentation
			<> Metadata.ObjectProperties.CatalogMainPresentation.AsDescription Then
			If MetadataObject.DescriptionLength <> 0 Then
				QueryText = QueryText + ", 
											  |	Description";
			EndIf;
			If MetadataObject.CodeLength <> 0 Then
				Condition = "Code";
			EndIf;
		EndIf;
		If MetadataObject.DefaultPresentation
			<> Metadata.ObjectProperties.CatalogMainPresentation.AsCode Then
			If MetadataObject.CodeLength <> 0 Then
				QueryText = QueryText + ",
											  |	Code";
			EndIf;
			If MetadataObject.DescriptionLength <> 0 Then
				Condition = "Description";
			EndIf;
		EndIf;
	ElsIf SearchableObject.Type = "Document" Then
		Condition = "Date, Number";
	EndIf;

	For Each Attribute In MetadataObject.Attributes Do
		QueryText = QueryText + ",
									  |	" + Attribute.Name;
	EndDo;

	QueryText = QueryText + Chars.LF + "FROM" + Chars.LF;
	QueryText = QueryText + "	" + SearchableObject.Type + "." + MetadataObject.Name + " AS _Table" + Chars.LF;

	For Each TabularSection In MetadataObject.TabularSections Do
		For Each AttributeTP In TabularSection.Attributes Do
			If Condition <> "" Then
				Condition = Condition + ",";
			EndIf;
			Condition = Condition + TabularSection.Name + "." + AttributeTP.Name + ".* AS " + TabularSection.Name + AttributeTP.Name;
		EndDo;
	EndDo;

	//If Condition <> "" Then
	//	QueryText = QueryText + "{WHERE " + Condition + "}" + Chars.LF;
	//EndIf;

	//If SearchConditionByString <> "" Then
	//	QueryText = QueryText + "WHERE " + SearchConditionByString + Chars.LF;
	//EndIf;
	Return QueryText;	
EndFunction

&AtClient
Procedure SearchObjectChoiceProcessing(Item, SelectedValue, StandardProcessing)
	StandardProcessing = False;

	If ValueIsFilled(SelectedValue) Then
		SearchObjectRepresentation = SelectedValue.Presentation;
		SearchObject = SelectedValue;
	Else
		SearchObjectRepresentation = "";
		SearchObject = Undefined;
	EndIf;

	SearchObjectOnChangeAtServer();
EndProcedure

&AtClient
Procedure FindLinks(Command)
	Status(Nstr("ru = 'Поиск ссылок...';en = 'Search for links...'"));
	FindLinksByFilter();
	Items.GroupPages.CurrentPage = Items.GroupFoundObjects;
EndProcedure

&AtServer
Procedure FindLinksByFilter()

	DataProcessorObject = FormAttributeToValue("Object");

	Query = New Query;

	If Object.SearchMode = 1 Then
		Query.Text = ArbitraryQueryText;
		For Each RowParameters In QueryParameters Do
			If RowParameters.ThisExpression Then
				Query.SetParameter(RowParameters.ParameterName, Eval(RowParameters.ParameterValue));
			Else
				Query.SetParameter(RowParameters.ParameterName, RowParameters.ParameterValue);
			EndIf;
		EndDo;
	Else
		Query.Text = QueryText;
		SearchConditionByString = GenerateSearchConditionByString();
		ListConditions = SearchConditionByString;

		If DataSelection <> Undefined Then
			For Each FilterItem In DataSelection.Filter.Items Do
				If Not FilterItem.Use Then
					Continue;
				EndIf;

				IndexOf = DataSelection.Filter.Items.IndexOf(FilterItem);
				ParameterName = StrReplace(String(FilterItem.LeftValue) + IndexOf, ".", "");

				ListConditions = ListConditions + ?(ListConditions = "", "", "
																		  |	And ")
					+ DataProcessorObject.GetComparisonType(FilterItem.LeftValue, FilterItem.ComparisonType,
					ParameterName);

				If TypeOf(FilterItem.RightValue) = Type("StandardBeginningDate") Then
					Query.SetParameter(ParameterName, FilterItem.RightValue.Date);
				Else
					Query.SetParameter(ParameterName, FilterItem.RightValue);
				EndIf;
			EndDo;
		EndIf;

		If ListConditions <> "" Then
			Query.Text = Query.Text + "
										  |WHERE 
										  |	" + ListConditions;
		EndIf;

		QueryTextEnding = "";

		If Object.ObjectType = 1 Then

			QueryTextEnding = QueryTextEnding + "
															|ORDER BY
															|	H_Date,
															|	Object";
			FieldsSort = "H_Date,Object";

		Else

			QueryTextEnding = QueryTextEnding + "
															|ORDER BY
															|	H_Kind,
															|	Object";
			FieldsSort = "H_Kind,Object";

		EndIf;

		If Object.ProcessTabularParts Then
			QueryTextEnding = QueryTextEnding + ",
															|	T_TP,
															|	T_LineNumber";
			FieldsSort = FieldsSort + ",T_TP,T_LineNumber";
		EndIf;

		Query.Text = Query.Text + QueryTextEnding;

	EndIf;

	Try
		ValueTable = Query.Execute().Unload();
	Except
		Message(ErrorDescription());
		Return;
	EndTry;

	ArrayAttributes = New Array;
	ArrayAttributes.Add("Object");
	ArrayAttributes.Add("Picture");
	ArrayAttributes.Add("Choose");

	CreateColumns(ValueTable, ArrayAttributes);

EndProcedure

&AtClient
Procedure CheckAll(Command)
	SelectItems(True);
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	SelectItems(False);
EndProcedure

&AtServer
Procedure SelectItems(Selection)
	For Each Row In FoundObjects Do
		Row.Choose = Selection;
	EndDo;
EndProcedure

&AtClient
Procedure ExecuteProcessing(Command)
	For Each String In SelectedDataProcessors Do
		UserInterruptProcessing();

		If Not String.Choose Then
			Continue;
		EndIf;

		Row = AvailableDataProcessors.FindByID(String.RowAvailableDataProcessor);
		Parent = Row.GetParent();

		StructureParameters = FormAStructureOfParameters();
		StructureParameters.Setting = Row.Setting[0].Value;

		If Parent = Undefined Then
			ProcessingFormName = Row.FormName;

			StructureParameters.Settings = FormTheSettings(Row);
			StructureParameters.Insert("Parent", Row.GetID());
			StructureParameters.Insert("CurrentLine", Undefined);
		Else
			ProcessingFormName = Parent.FormName;

			StructureParameters.Settings = FormTheSettings(Parent);
			StructureParameters.Insert("Parent", Parent.GetID());
			StructureParameters.Insert("CurrentLine", String.RowAvailableDataProcessor);
		EndIf;

		If Not ProcessingAvailable(?(Object.ObjectType = 0, "Catalog", "Document"), ProcessingFormName) Then
			Message(StrTemplate(NSTR("ru = 'Обработка %1 недоступна для типа <%2>';en = 'Data processor %1 unavailable for type < %2 >'"),FormName,SearchObject.Type));
			Continue;
		EndIf;

		Processing = GetForm(GetFullFormName(ProcessingFormName), StructureParameters, ThisForm);
		Processing.DownloadSettings();
		Processing.ExecuteProcessing();
	EndDo;
EndProcedure

&AtServer
Procedure CreateColumns(ValueTable, ArrayAttributesDefault = Undefined) Export
	TableItem = Items.FoundObjects;

	//clear
	For Each AddedItem In AddedItems Do
		Items.Delete(Items[AddedItem.Value]);
	EndDo;
	AddedItems.Clear();

	//add attributes
	ArrayAttributes = New Array;
	For Each Column In ValueTable.Columns Do
		If ArrayAttributesDefault <> Undefined And ArrayAttributesDefault.Find(Column.Name)
			<> Undefined Then
			Continue;
		EndIf;

		ColumnType = String(Column.ValueType);
		If Column.Name = "Presentation" Or (Find(ColumnType, "Value storage") > 0 Or Find(ColumnType, "Хранилище значения") > 0) Then
			Continue;
		EndIf;

		FormAttribute = New FormAttribute(Column.Name, Column.ValueType, TableItem.Name);

		Presentation = "";

		For Each Item In ViewList Do
			If Item.Presentation = Column.Name Then
				Presentation = Item.Value;
				Break;
			EndIf;
		EndDo;

		FormAttribute.Title = Presentation;
		ArrayAttributes.Add(FormAttribute);
	EndDo;

	ChangeAttributes(ArrayAttributes, AddedAttributes.UnloadValues());
	AddedAttributes.Clear();

	//adding controls
	For Each Attribute In ArrayAttributes Do
		AddedAttributes.Add(Attribute.Path + "." + Attribute.Name);

		Item = Items.Add(TableItem.Name + Attribute.Name, Type("FormField"), TableItem);
		Item.Type = FormFieldType.TextBox;
		Item.DataPath = TableItem.Name + "." + Attribute.Name;
		Item.ReadOnly = True;

		AddedItems.Add(Item.Name);
	EndDo;

	//data filling
	EditingValueTable = FormAttributeToValue(TableItem.Name);
	EditingValueTable.Clear();
	For Each Row In ValueTable Do
		NewRow = EditingValueTable.Add();
		FillPropertyValues(NewRow, Row);

		NewRow.Choose = True;

		//If SearchObject = Undefined Then
		//	Continue;
		//EndIf;
		If Object.ObjectType = 0 Then //"Catalog" Then
			If Row.Object.IsFolder Then
				If Row.Object.DeletionMark Then
					NewRow.Picture = 3;
				Else
					NewRow.Picture = 0;
				EndIf;
			Else
				If Row.Object.DeletionMark Then
					NewRow.Picture = 4;
				Else
					NewRow.Picture = 1;
				EndIf;
			EndIf;
		Else
			If Row.Object.Posted Then
				NewRow.Picture = 7;
			ElsIf Row.Object.DeletionMark Then
				NewRow.Picture = 8;
			Else
				NewRow.Picture = 6;
			EndIf;
		EndIf;
	EndDo;

	ValueToFormAttribute(EditingValueTable, TableItem.Name);
EndProcedure

&AtServer
Function GetFullFormName(NameDesiredForm)
	ArrayString = StrSplit(ThisForm.FormName, ".");
	ArrayString[ArrayString.Count() - 1] = NameDesiredForm;

	Return StrConcat(ArrayString, ".");
EndFunction

&AtClient
Procedure Filter(Command)
	If TableFieldTypesObjects.Count() = 0 Then
		Return;
	EndIf;

	StructureParameters = New Structure;
	StructureParameters.Insert("QueryText", QueryText);
	StructureParameters.Insert("ArbitraryQueryText", ArbitraryQueryText);
	StructureParameters.Insert("SearchString", SearchString);
	StructureParameters.Insert("Settings", DataSelection);
	StructureParameters.Insert("ListOfSelected", GetListTypesObjects());
	StructureParameters.Insert("SearchMode", Object.SearchMode);
	StructureParameters.Insert("QueryParameters", QueryParameters);
	StructureParameters.Insert("ViewList", ViewList);

	OpenForm(GetFullFormName("FormSelection"), StructureParameters, ThisObject, , , ,
		New NotifyDescription("FilterEnd", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure FilterEnd(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;

	ProcessSelectionResult(Result);
EndProcedure

&AtServer
Procedure ProcessSelectionResult(ResultSelection)
	DataSelection = ResultSelection.Settings;
	SearchString = ResultSelection.SearchString;
	QueryParameters.Load(ResultSelection.QueryParameters.Unload());

	QueryText = ResultSelection.QueryText;
	ArbitraryQueryText = ResultSelection.ArbitraryQueryText;
	Object.SearchMode = ResultSelection.SearchMode;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
//	SetVisibleAvalible();
	SetPicturesProcessing();
EndProcedure

&AtClient
Procedure AvailableDataProcessorsSelection(Item, SelectedRow, Field, StandardProcessing)
	If TableFieldTypesObjects.Count() = 0 Then
		Return;
	EndIf;

	StandardProcessing = False;

	RowIndex = Items.AvailableDataProcessors.CurrentRow;
	CurrentLine = AvailableDataProcessors.FindByID(RowIndex);

	StructureParameters = FormAStructureOfParameters();
	StructureParameters.Setting = CurrentLine.Setting[0].Value;

	Parent = CurrentLine.GetParent();
	If Parent = Undefined Then
		If Not ProcessingAvailable(?(Object.ObjectType = 0, "Catalog", "Document"), CurrentLine.FormName) Then
			Message = StrTemplate(Nstr("ru = 'Данная обработка недоступна для типа <%1>';en = 'This processing is not available for type <%1>'")
				, ?(Object.ObjectType = 0, Nstr("ru = 'Справочник';en = 'Catalog'"), Nstr("ru = 'Документ';en = 'Document'")));
			ShowMessageBox( , Message);
			Return;
		EndIf;
		StructureParameters.Settings = FormTheSettings(Item.CurrentData);
		StructureParameters.Insert("Parent", CurrentLine.GetID());
		StructureParameters.Insert("CurrentLine", Undefined);

		FormNameToOpen = GetFullFormName(CurrentLine.FormName);
	Else
		If Not ProcessingAvailable(?(Object.ObjectType = 0, "Catalog", "Document"), Parent.FormName) Then
			Message = StrTemplate(Nstr("ru = 'Данная обработка недоступна для типа <%1>';en = 'This processing is not available for type <%1>'")
				, ?(Object.ObjectType = 0, Nstr("ru = 'Справочник';en = 'Catalog'"), Nstr("ru = 'Документ';en = 'Document'")));
			ShowMessageBox( , Message);
			Return;
		EndIf;

		StructureParameters.Settings = FormTheSettings(Parent);
		StructureParameters.Insert("Parent", Parent.GetID());
		StructureParameters.Insert("CurrentLine", RowIndex);

		FormNameToOpen = GetFullFormName(Parent.FormName);
	EndIf;
	OpenForm(FormNameToOpen, StructureParameters, ThisObject, , , ,
		New NotifyDescription("AvailableDataProcessorsSelectionEnd", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure AvailableDataProcessorsSelectionEnd(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
EndProcedure

&AtServer
Function FormAStructureOfParameters()
	StructureParameters = New Structure;
	StructureParameters.Insert("Setting", Undefined);
	StructureParameters.Insert("Settings", New Array);
	StructureParameters.Insert("ObjectType", Object.ObjectType);
	StructureParameters.Insert("TableAttributes", TableAttributes);
	StructureParameters.Insert("ProcessTabularParts", Object.ProcessTabularParts);
	StructureParameters.Insert("ListOfSelected", GetListTypesObjects());
	StructureParameters.Insert("TableFieldTypesObjects", TableFieldTypesObjects);

	StructureParameters.Insert("FoundObjectsTP", FoundObjects);

	StructureSelection = New Structure;
	StructureSelection.Insert("Choose", True);
	StructureParameters.Insert("FoundObjects", FoundObjects.Unload(StructureSelection,
		"Object").UnloadColumn("Object"));

	Return StructureParameters;
EndFunction

&AtClient
Procedure AvailableDataProcessorsBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	If TableFieldTypesObjects.Count() = 0 Then
		Return;
	EndIf;

	If Item.CurrentData = Undefined Then
		Cancel = True;
	EndIf;

	If Item.CurrentData.GetParent() = Undefined Then
		If Copy Then
			Cancel = True;
		Else
			If Not ProcessingAvailable(?(Object.ObjectType = 0, "Catalog", "Document"),
				Item.CurrentData.FormName) Then
				Message = StrTemplate(Nstr("ru = 'Данная обработка недоступна для типа <%1>';en = 'This processing is not available for type <%1>'")
				, ?(Object.ObjectType = 0, Nstr("ru = 'Справочник';en = 'Catalog'"), Nstr("ru = 'Документ';en = 'Document'")));
				ShowMessageBox( , Message);
				Cancel = True;
				Return;
			EndIf;
			Cancel = Not GetForm(GetFullFormName(Item.CurrentData.FormName)).mUseSettings;
			If Not Cancel Then
			//your addition
				Cancel = True;
				AddRow(Item.CurrentData);
			EndIf;
		EndIf;
	Else
		If Not ProcessingAvailable(?(Object.ObjectType = 0, "Catalog", "Document"),
			Item.CurrentData.GetParent().FormName) Then
			Message = StrTemplate(Nstr("ru = 'Данная обработка недоступна для типа <%1>';en = 'This processing is not available for type <%1>'")
				, ?(Object.ObjectType = 0, Nstr("ru = 'Справочник';en = 'Catalog'"), Nstr("ru = 'Документ';en = 'Document'")));
			ShowMessageBox( , Message);
			Cancel = True;
			Return;
		EndIf;
		Cancel = True;
		If Not Copy Then
			If GetForm(GetFullFormName(
				Item.CurrentData.GetParent().FormName)).mUseSettings Then
				AddRow(Item.CurrentData.GetParent());
			EndIf;
		Else
			CurrentData = Item.CurrentData;
			Parent = Item.CurrentData.GetParent();
			NewRow = AddRow(Parent);
			If Not CurrentData.Setting[0].Value = Undefined Then
				NewSetting = New Structure;
				For Each AttributeSetting In CurrentData.Setting[0].Value Do
				//@skip-warning
					Value = AttributeSetting.Value;
					Execute ("NewSetting.Insert(String(AttributeSetting.Key), Value);");
				EndDo;

				NewRow.Setting[0].Value = NewSetting;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Function AddRow(CurrentLine)

	NewRow = CurrentLine.GetItems().Add();

	Setting = New Structure;
	Setting.Insert("Processing", CurrentLine.Processing);
	Setting.Insert("Other", Undefined);

	NewRow.Setting.Add(Setting);

	Items.AvailableDataProcessors.CurrentLine = NewRow.GetID();
	Items.AvailableDataProcessors.ChangeRow();

	Return NewRow;
EndFunction

&AtClient
Function FormTheSettings(CurrentLine)

	ArraySettings = New Array;
	For Each Row In CurrentLine.GetItems() Do
		If Row.Setting[0].Value = Undefined Then
			Continue;
		EndIf;

		ArraySettings.Add(Row.Setting[0].Value);
	EndDo;

	Return ArraySettings;
EndFunction

&AtClient
Procedure AvailableDataProcessorsBeforeRowChange(Item, Cancel)
	If TableFieldTypesObjects.Count() = 0 Then
		Return;
	EndIf;

	If Item.CurrentData.GetParent() = Undefined Then
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure AvailableDataProcessorsBeforeDeleteRow(Item, Cancel)
	
	If Item.CurrentData.GetParent() = Undefined Then
		Return;
	EndIf;

	Cancel=True;
	ShowQueryBox(New NotifyDescription("AvailableDataProcessorsBeforeDeleteRowEnd", ThisForm,
		New Structure("CurrentLine", Item.CurrentLine)),NSTR("ru = 'Удалить настройку?';en = 'Delete setting ?'"), QuestionDialogMode.OKCancel, ,
		DialogReturnCode.OK);
EndProcedure

&AtClient
Procedure AvailableDataProcessorsBeforeDeleteRowEnd(ResultQuestion, AdditionalParameters) Export

	CurrentLine = AdditionalParameters.CurrentLine;
	If ResultQuestion = DialogReturnCode.OK Then
		SelectionParameters = New Structure;
		SelectionParameters.Insert("RowAvailableDataProcessor", CurrentLine);

		ArrayToDelete = SelectedDataProcessors.FindRows(SelectionParameters);
		For IndexOf = 0 To ArrayToDelete.Count() - 1 Do
			SelectedDataProcessors.Delete(ArrayToDelete[IndexOf]);
		EndDo;
	EndIf;

EndProcedure

&AtClient
Procedure AvailableDataProcessorsDragStart(Item, DragParameters, StandardProcessing)
	If Not CheckAvailabilityProcessing() Then
		StandardProcessing = False;
		Message = StrTemplate(Nstr("ru = 'Данная обработка недоступна для типа <%1>';en = 'This processing is not available for type <%1>'")
				, ?(Object.ObjectType = 0, Nstr("ru = 'Справочник';en = 'Catalog'"), Nstr("ru = 'Документ';en = 'Document'")));
		ShowMessageBox( , Message);
		Return;
	EndIf;
	ProcessingDragAndDrop = True;
EndProcedure

&AtClient
Function CheckAvailabilityProcessing()
	RowIndex = Items.AvailableDataProcessors.CurrentRow;
	CurrentLine = AvailableDataProcessors.FindByID(RowIndex);

	Parent = CurrentLine.GetParent();
	If Parent = Undefined Then
		Return ProcessingAvailable(?(Object.ObjectType = 0, "Catalog", "Document"), CurrentLine.FormName);
	EndIf;

	Return ProcessingAvailable(?(Object.ObjectType = 0, "Catalog", "Document"), Parent.FormName);
EndFunction

&AtClient
Procedure SelectedDataProcessorsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	If Not ProcessingDragAndDrop Then
		Return;
	EndIf;

	For Each RowSelected In DragParameters.Value Do
		RowAvailable = AvailableDataProcessors.FindByID(RowSelected.GetID());

		NewRow = SelectedDataProcessors.Add();
		NewRow.ProcessingSetting = RowAvailable.Processing;
		NewRow.RowAvailableDataProcessor = RowAvailable.GetID();
		NewRow.Choose = True;
		NewRow.Setting = RowAvailable.Setting;
	EndDo;

	ProcessingDragAndDrop = False;
EndProcedure

&AtClient
Procedure CheckAllDataProcessors(Command)
	CheckDataProcessors(True);
EndProcedure

&AtClient
Procedure UncheckAllDataProcessors(Command)
	CheckDataProcessors(False);
EndProcedure

&AtServer
Procedure CheckDataProcessors(Selection)
	For Each Row In SelectedDataProcessors Do
		Row.Choose = Selection;
	EndDo;
EndProcedure

&AtClient
Function ProcessingAvailable(CheckedObjectType = "", ProcessingName)

	If IsBlankString(CheckedObjectType) Then
		Return False;
	EndIf;

	Try
		TypesOfProcessedObjects = GetForm(GetFullFormName(ProcessingName)).mTypesOfProcessedObjects;
	Except
		ShowMessageBox( , ErrorDescription());
		Return False;
	EndTry;

	If ProcessingName = "RenumberingObjects" Then
		If TableFieldTypesObjects.Count() > 1 Then
			Message(Nstr("ru = 'Выбрано более одного вида объектов. Перенумерация невозможна';en = 'More than one type of objects has been selected. Renumbering is not possible'"));
			Return False;
		EndIf;

		If Object.ProcessTabularParts Then
			Message(Nstr("ru = 'Перенумерация при обработке табличных частей запрещена';en = 'Renumbering is prohibited when processing tabular parts'"));
			Return False;
		EndIf;
	EndIf;

	If TypesOfProcessedObjects = Undefined Then
		Return True;
	Else
		If Find(TypesOfProcessedObjects, CheckedObjectType) Then
			Return True;
		Else
			Return False;
		EndIf;
	EndIf;
EndFunction

&AtClient
Procedure AvailableDataProcessorsEditEnd(Item, NewRow, CancelEdit)
	If Item.CurrentData.GetParent() = Undefined Then
		Return;
	EndIf;

	Setting = Item.CurrentData.Setting[0].Value;
	Setting.Processing = Item.CurrentData.Processing;
EndProcedure

&AtClient
Procedure SetPicturesProcessing()
	For Each Row In AvailableDataProcessors.GetItems() Do
		Row.Picture = PictureLib.DataProcessor;
	EndDo;
EndProcedure

&AtClient
Procedure TableFieldTypesObjectsBeforeRowChange(Item, Cancel)
	OpenFormSelectionTable();
	Cancel = True;
EndProcedure

&AtClient
Procedure TableFieldTypesObjectsBeforeDeleteRow(Item, Cancel)
	
	Cancel=True;
	
	CurrentLine = Items.TableFieldTypesObjects.CurrentData.GetID();
	AdditionalParametersNotify = New Structure("CurrentLine", CurrentLine);
	CheckNecessaryClearResults(
			New NotifyDescription("TableFieldTypesObjectsBeforeDeleteRowEnd", 
										ThisObject, 
										AdditionalParametersNotify
									)
	);
	
EndProcedure

&AtClient
Procedure TableFieldTypesObjectsBeforeDeleteRowEnd(Result, AdditionalParameters) Export
	If Not Result Then
		Return;
	EndIf;

	CurrentLine = AdditionalParameters.CurrentLine;
	TableFieldTypesObjects.Delete(TableFieldTypesObjects.FindByID(CurrentLine));

	Items.TableFieldTypesObjects.Refresh();
EndProcedure
Function TruncateArray(Array, Array2)
	Arr = New Array;

	For Each CurrentElement In Array Do
		If Array2.Find(CurrentElement) = Undefined Then
			Continue;
		EndIf;

		Arr.Add(CurrentElement);
	EndDo;

	Return Arr;
EndFunction

&AtServer
Procedure QueryInitialization()

	ArrayQueriesToObjects = New Array;

	TotalRows = TableFieldTypesObjects.Count();
	//If TotalRows = 0 Then
	//	If Not QueryBuilder = Undefined And Not QueryBuilder.Filter = Undefined Then
	//		FiltersCount = QueryBuilder.Filter.Count();
	//		For IndexOf = 1 To FiltersCount Do
	//			QueryBuilder.Filter.Delete(FiltersCount - IndexOf);
	//		EndDo; 
	//	EndIf; 
	//	QueryBuilder = Undefined;
	//	Return;
	//EndIf;	
	//If QueryBuilder = Undefined Then
	//	QueryBuilder = New QueryBuilder;
	//EndIf; 


	///============================= INITIALIZING VARIABLES
	MetadataObjects = Metadata[?(Object.ObjectType = 1, "Documents", "Catalogs")];
	TableTypeName = ?(Object.ObjectType = 1, "Document", "Catalog");
	Prefix = ?(Object.ProcessTabularParts, "Ref.", "");

	ArrayTypes = New Array;
	ArrayTypes.Add(Type("ValueStorage"));
	DescriptionTypeStorage = New TypeDescription(ArrayTypes);

	ArrayTypes = New Array;
	ViewList.Clear(); //      = New ValueList;
	StructureAttributesHeaders = New Structure;
	StructureAttributesTP = New Structure;
	StructureTypesObjects = New Structure;
	StructureCategories = New Structure;
	StructureProperties = New Structure;
	//	ArraySettingsFilter     = New Array;
	TableAttributes.Clear();

	KindNameSingleType = Undefined;
	PastValue = Undefined;
	///============================= COUNTING OF NAMED DETAILS
	For Each String In TableFieldTypesObjects Do

		If Not Object.ProcessTabularParts Then
			KindName = String.TableName;
			NameTP="";
		Else
			PositionTP = Find(String.TableName, ".");
			KindName = Left(String.TableName, PositionTP - 1);
			NameTP = Mid(String.TableName, PositionTP + 1);
		EndIf;

		If MetadataObjects.Find(KindName) = Undefined Then
			Continue;
		EndIf;

		MetadataRowObjects = MetadataObjects[KindName];

		MatadataAttributes = MetadataRowObjects.Attributes;

		If Object.ProcessTabularParts Then
			MetadataAttributesTP = MetadataRowObjects.TabularSections[NameTP].Attributes;
		EndIf;

		If Object.ObjectType = 1 Then
			If MetadataRowObjects.NumberLength > 0 Then
				StructureAttributesHeaders.Insert("Number", ?(StructureAttributesHeaders.Property("Number",
					PastValue), PastValue + 1, 1));
			EndIf;

			Filter = New Structure;
			Filter.Insert("Name", "Number");
			Filter.Insert("ThisTP", False);
			ArrayString = TableAttributes.FindRows(Filter);
			If MetadataRowObjects.NumberType = Metadata.ObjectProperties.DocumentNumberType.String Then
				CurrentType = TypeDescription("String");
			Else
				CurrentType = TypeDescription("Number");
			EndIf;

			If ArrayString.Count() > 0 Then
				RowAttributes = ArrayString[0];
			Else
				RowAttributes = TableAttributes.Add();
				RowAttributes.Name = "Number";
				RowAttributes.Presentation = "Number";
				RowAttributes.Type = CurrentType;
				RowAttributes.ThisTP = False;
			EndIf;

			RowAttributes.Type = New TypeDescription(TruncateArray(RowAttributes.Type.Types(), CurrentType.Types()));

			StructureAttributesHeaders.Insert("Date", ?(StructureAttributesHeaders.Property("Date", PastValue), PastValue
				+ 1, 1));

			Filter = New Structure;
			Filter.Insert("Name", "Date");
			Filter.Insert("ThisTP", False);
			ArrayString = TableAttributes.FindRows(Filter);
			CurrentType = TypeDescription("Date");

			If ArrayString.Count() > 0 Then
				RowAttributes = ArrayString[0];
			Else
				RowAttributes = TableAttributes.Add();
				RowAttributes.Name = "Date";
				RowAttributes.Presentation = "Date";
				RowAttributes.Type = CurrentType;
				RowAttributes.ThisTP = False;
			EndIf;
			RowAttributes.Type = New TypeDescription(TruncateArray(RowAttributes.Type.Types(), CurrentType.Types()));

			StructureAttributesHeaders.Insert("Posted", ?(StructureAttributesHeaders.Property("Posted",
				PastValue), PastValue + 1, 1));

			Filter = New Structure;
			Filter.Insert("Name", "Posted");
			Filter.Insert("ThisTP", False);
			ArrayString = TableAttributes.FindRows(Filter);
			CurrentType = TypeDescription("Boolean");

			If ArrayString.Count() > 0 Then
				RowAttributes = ArrayString[0];
			Else
				RowAttributes = TableAttributes.Add();
				RowAttributes.Name = "Posted";
				RowAttributes.Presentation = "Posted";
				RowAttributes.Type = CurrentType;
				RowAttributes.ThisTP = False;
			EndIf;
			RowAttributes.Type = New TypeDescription(TruncateArray(RowAttributes.Type.Types(), CurrentType.Types()));
		Else
			If MetadataRowObjects.CodeLength > 0 Then
				StructureAttributesHeaders.Insert("Code", ?(StructureAttributesHeaders.Property("Code", PastValue), PastValue
					+ 1, 1));

				Filter = New Structure;
				Filter.Insert("Name", "Code");
				Filter.Insert("ThisTP", False);
				ArrayString = TableAttributes.FindRows(Filter);
				If MetadataRowObjects.CodeType = Metadata.ObjectProperties.CatalogCodeType.String Then
					CurrentType = TypeDescription("String");
				Else
					CurrentType = TypeDescription("Number");
				EndIf;

				If ArrayString.Count() > 0 Then
					RowAttributes = ArrayString[0];
				Else
					RowAttributes = TableAttributes.Add();
					RowAttributes.Name = "Code";
					RowAttributes.Presentation = "Code";
					RowAttributes.Type = CurrentType;
					RowAttributes.ThisTP = False;
				EndIf;
				RowAttributes.Type = New TypeDescription(TruncateArray(RowAttributes.Type.Types(), CurrentType.Types()));
			EndIf;

			If MetadataRowObjects.DescriptionLength > 0 Then
				StructureAttributesHeaders.Insert("Description", ?(StructureAttributesHeaders.Property("Description",
					PastValue), PastValue + 1, 1));

				Filter = New Structure;
				Filter.Insert("Name", "Description");
				Filter.Insert("ThisTP", False);
				ArrayString = TableAttributes.FindRows(Filter);
				CurrentType = TypeDescription("String");

				If ArrayString.Count() > 0 Then
					RowAttributes = ArrayString[0];
				Else
					RowAttributes = TableAttributes.Add();
					RowAttributes.Name = "Description";
					RowAttributes.Presentation = "Description";
					RowAttributes.Type = CurrentType;
					RowAttributes.ThisTP = False;
				EndIf;
				RowAttributes.Type = New TypeDescription(TruncateArray(RowAttributes.Type.Types(), CurrentType.Types()));
			EndIf;
		EndIf;

		If KindNameSingleType = Undefined Then
			KindNameSingleType = KindName;
		ElsIf KindNameSingleType <> KindName Then
			KindNameSingleType = False;
		EndIf;

		For Each AttributeMetadata In MetadataObjects[KindName].Attributes Do

			If AttributeMetadata.Type = DescriptionTypeStorage Then
				Continue;
			ElsIf AttributeMetadata.Name = "Type" Then
				Continue;
			EndIf;

			StructureAttributesHeaders.Insert(AttributeMetadata.Name, ?(StructureAttributesHeaders.Property(
				AttributeMetadata.Name, PastValue), PastValue + 1, 1));

			Filter = New Structure;
			Filter.Insert("Name", AttributeMetadata.Name);
			Filter.Insert("ThisTP", False);
			ArrayString = TableAttributes.FindRows(Filter);

			If ArrayString.Count() > 0 Then
				RowAttributes = ArrayString[0];
			Else
				RowAttributes = TableAttributes.Add();
				RowAttributes.Name = AttributeMetadata.Name;
				RowAttributes.Presentation = AttributeMetadata.Synonym;
				RowAttributes.Type = AttributeMetadata.Type;
				RowAttributes.ThisTP = False;
			EndIf;

			RowAttributes.Type = New TypeDescription(TruncateArray(RowAttributes.Type.Types(),
				AttributeMetadata.Type.Types()));

		EndDo;

		If Object.ProcessTabularParts Then

			For Each AttributeMetadata In MetadataAttributesTP Do

				If AttributeMetadata.Type = DescriptionTypeStorage Then
					Continue;
				EndIf;

				StructureAttributesTP.Insert(AttributeMetadata.Name, ?(StructureAttributesTP.Property(
					AttributeMetadata.Name, PastValue), PastValue + 1, 1));

				Filter = New Structure;
				Filter.Insert("Name", AttributeMetadata.Name);
				Filter.Insert("ThisTP", True);
				ArrayString = TableAttributes.FindRows(Filter);

				If ArrayString.Count() > 0 Then
					RowAttributes = ArrayString[0];
				Else
					RowAttributes = TableAttributes.Add();
					RowAttributes.Name = AttributeMetadata.Name;
					RowAttributes.Presentation = AttributeMetadata.Synonym;
					RowAttributes.Type = AttributeMetadata.Type;
					RowAttributes.ThisTP = True;
				EndIf;

				RowAttributes.Type = New TypeDescription(TruncateArray(RowAttributes.Type.Types(),
					AttributeMetadata.Type.Types()));
			EndDo;
		EndIf;
		StructureTypesObjects.Insert(MetadataObjects[KindName].Name, Type(TableTypeName + "Ref." + KindName));
	EndDo;
	If KindNameSingleType = False Then
		KindNameSingleType = Undefined;
	EndIf;
	InConfigurationIsBalanceProducts = Not Metadata.AccumulationRegisters.Find("GoodsInWarehouses") = Undefined;
	ControlBalanceProducts = (Object.ObjectType = 0) And (KindNameSingleType = "Products")
		And InConfigurationIsBalanceProducts;
		//
	AccessibilityInWebApplicationProducts = InConfigurationYesOrderManagement And (Object.ObjectType = 0)
		And (KindNameSingleType = "Products");

		///============================= DEFINITION OF GENERAL PROPERTIES AND CATEGORIES
	For Each KeyAndValue In StructureTypesObjects Do
		ArrayTypes.Add(KeyAndValue.Value);
	EndDo;
	//	AllTypesDescription = New TypeDescription(ArrayTypes);


	///============================= DETERMINATION OF THE COMPOSITION OF DETAILS
	Counter = 0;
	For Each KeyAndValue In StructureAttributesTP Do

		If Not KeyAndValue.Value = TotalRows Then

			StructureAttributesTP.Delete(KeyAndValue.Key);

		Else
			Counter = Counter + 1;
			StructureAttributesTP.Insert(KeyAndValue.Key, "Т_" + KeyAndValue.Key);

		EndIf;

	EndDo;

	Counter = 0;
	For Each KeyAndValue In StructureAttributesHeaders Do

		If Not KeyAndValue.Value = TotalRows Then

			StructureAttributesHeaders.Delete(KeyAndValue.Key);

		Else
			Counter = Counter + 1;
			StructureAttributesHeaders.Insert(KeyAndValue.Key, "H_" + KeyAndValue.Key);
		EndIf;

	EndDo;

	///============================= DETERMINING THE ORDER AND PRESENTING DETAILS
	ViewList.Add("Type " + TableTypeName + "а", "H_Kind");
	ViewList.Add("Type " + TableTypeName + "а", "H_KindRepresentation");
	ViewList.Add("Ref", "Object");

	If Object.ProcessTabularParts Then

		ViewList.Add(Nstr("ru = 'Имя ТЧ';en = 'Name TP'"), "T_TP");
		ViewList.Add(Nstr("ru = 'Имя ТЧ';en = 'Name TP'"), "T_TPPresentation");
		ViewList.Add(Nstr("ru = '№ строки';en = '№ line'"), "T_LineNumber");

		For Each KeyAndValue In StructureAttributesTP Do
			ViewList.Add(MetadataAttributesTP[KeyAndValue.Key].Presentation(),
				KeyAndValue.Value);
		EndDo;

	EndIf;

	ViewList.Add(Prefix + "Deletion mark", "H_DeletionMark");

	If Object.ObjectType = 0 And Not KindNameSingleType = Undefined Then

		If MetadataObjects[KindNameSingleType].Owners.Count() > 0 Then

			StructureAttributesHeaders.Insert("Owner", "H_Owner");

		EndIf;

		If MetadataObjects[KindNameSingleType].Hierarchical Then

			StructureAttributesHeaders.Insert("Parent", "H_Parent");

		EndIf;

	EndIf;

	//If ControlBalanceProducts Then
	//	
	//	ListPresentations.Add(Prefix+"Balance товара","R_Balance");
	//	ListPresentations.Add(Prefix+"Balance-Резерв товара","R_Reserve");
	//	
	//EndIf;

	//If AccessibilityInWebApplicationProducts Then
	//	
	//	ListPresentations.Add(Prefix+"Avalible in web-application "Orders managment""","P_AvalibleInWebAppOrdersManagment);
	//	
	//EndIf;
	For Each KeyAndValue In StructureAttributesHeaders Do
		MatadataAttribute = MatadataAttributes.Find(KeyAndValue.Key);
		If Not MatadataAttribute = Undefined Then
			ViewList.Add(Prefix + MatadataAttribute.Presentation(), KeyAndValue.Value);
		Else
			ViewList.Add(Prefix + KeyAndValue.Key, KeyAndValue.Value);
		EndIf;

	EndDo;

	For Each KeyAndValue In StructureCategories Do
		ViewList.Add(KeyAndValue.Value, KeyAndValue.Key);
	EndDo;

	For Each KeyAndValue In StructureProperties Do
		ViewList.Add(KeyAndValue.Value, KeyAndValue.Key);
	EndDo;

	///============================= ADDING COMMON ATTRIBUTES
	StructureAttributesHeaders.Insert("DeletionMark", "H_DeletionMark");

	If Object.ProcessTabularParts Then
		StructureAttributesTP.Insert("LineNumber", "T_LineNumber");
	EndIf;

	///============================= FORMING THE QUERY TEXT
	QueryTextEnding = "";

	//If Object.ObjectType = 1 Then
	//	
	//	QueryTextEnding = QueryTextEnding + "
	//	|ORDER BY
	//	|	H_Date,
	//	|	Object";
	//	FieldsSort = "H_Date,Object";
	//	
	//Else
	//	
	//	QueryTextEnding = QueryTextEnding + "
	//	|ORDER BY
	//	|	H_Kind,
	//	|	Object";
	//	FieldsSort = "H_Kind,Object";
	//	
	//EndIf;
	//
	//If Object.ProcessTabularParts Then
	//	QueryTextEnding = QueryTextEnding + ",
	//	|	T_TP,
	//	|	T_LineNumber";
	//	FieldsSort = FieldsSort + ",T_TP,T_LineNumber";
	//EndIf;
	QueryText = "";

	For Each String In TableFieldTypesObjects Do

		If Not Object.ProcessTabularParts Then
			KindName = String.TableName;
		Else
			PositionTP = Find(String.TableName, ".");
			KindName = Left(String.TableName, PositionTP - 1);
			NameTP = Mid(String.TableName, PositionTP + 1);
		EndIf;

		If MetadataObjects.Find(KindName) = Undefined Then
			Continue;
		EndIf;

		MetadataRowObjects=MetadataObjects[KindName];

		MatadataAttributes = MetadataRowObjects.Attributes;

		If Object.ProcessTabularParts Then
			MetadataAttributesTP = MetadataRowObjects.TabularSections[NameTP].Attributes;
		EndIf;

		TableName = TableTypeName + "." + String.TableName;
		AliasTable = StrReplace(TableName, ".", "_");

		///============================= FORMING THE QUERY TEXT BY ATTRIBUTES
		QueryTextObject = "";
		QueryTextObject = QueryTextObject + "" + Chars.LF + "	""" + KindName + """ AS H_Kind";
		QueryTextObject = QueryTextObject + "," + Chars.LF + "	""" + StrReplace(
			MetadataObjects[KindName].Presentation(), """", "") + """ AS H_KindRepresentation";
		QueryTextObject = QueryTextObject + "," + Chars.LF + "	" + AliasTable + "." + Prefix
			+ "Ref AS Object";

		For Each KeyAndValue In StructureAttributesHeaders Do
			MatadataAttribute = MatadataAttributes.Find(KeyAndValue.Key);
			If Not MatadataAttribute = Undefined And MatadataAttribute.Type.ContainsType(Type("String"))
				And MatadataAttribute.Type.StringQualifiers.Length = 0 Then
				QueryTextObject = QueryTextObject + "," + Chars.LF + "	SUBSTRING(" + AliasTable + "."
					+ Prefix + KeyAndValue.Key + ",1," + RestrictionOnStringsUnlimitedLength + ")";
			Else
				QueryTextObject = QueryTextObject + "," + Chars.LF + "	" + AliasTable + "." + Prefix
					+ KeyAndValue.Key;
			EndIf;
			QueryTextObject = QueryTextObject + " AS " + KeyAndValue.Value;
		EndDo;

		If Object.ProcessTabularParts Then

			QueryTextObject = QueryTextObject + "," + Chars.LF + "	""" + NameTP + """ AS T_TP";
			QueryTextObject = QueryTextObject + "," + Chars.LF + "	"""
				+ MetadataRowObjects.TabularSections[NameTP].Presentation() + """ AS T_TPPresentation";

			For Each KeyAndValue In StructureAttributesTP Do

				MatadataAttribute = MetadataAttributesTP.Find(KeyAndValue.Key);

				If Not MatadataAttribute = Undefined And MatadataAttribute.Type.ContainsType(Type("String"))
					And MatadataAttribute.Type.StringQualifiers.Length = 0 Then

					QueryTextObject = QueryTextObject + "," + Chars.LF + "	SUBSTRING(" + AliasTable
						+ "." + KeyAndValue.Key + ",1," + RestrictionOnStringsUnlimitedLength + ")";

				Else

					QueryTextObject = QueryTextObject + "," + Chars.LF + "	" + AliasTable + "."
						+ KeyAndValue.Key;

				EndIf;

				QueryTextObject = QueryTextObject + " AS " + KeyAndValue.Value;

			EndDo;
		EndIf;

		///============================= FORMING THE QUERY TEXT BY PROPERTIES AND CATEGORIES
		If SelectionByCategories Then
		//
			//For Each KeyAndValue In StructureCategories Do
			//	
			//	QueryTextObject = QueryTextObject + "," + Chars.LF + 
			//	"	SELECT THEN Table_"+KeyAndValue.Key+".Category IS NULL THEN FALSE ELSE TRUE END AS " + KeyAndValue.Key;
			//	
			//EndDo; 
		EndIf;

		If SelectionByProperties Then

		//For Each KeyAndValue In StructureProperties Do
			//	
			//	QueryTextObject = QueryTextObject + "," + Chars.LF + "	Table_"+KeyAndValue.Key+".Value AS "+KeyAndValue.Key;
			//	
			//EndDo; 
		EndIf;

		///============================= FORMING THE QUERY TEXT BY BALANCE PRODUCTS
		If ControlBalanceProducts Then

		//QueryTextObject = QueryTextObject + "," + "
			//|	ЕСТЬNULL(Table_R_Balance.QuantityBalance,0) AS R_Balance,
			//|	ЕСТЬNULL(Table_R_Balance.QuantityBalance, 0) - ЕСТЬNULL(Table_R_Reserve.QuantityBalance, 0) AS R_Reserve";
		EndIf;

		If AccessibilityInWebApplicationProducts Then

		//QueryTextObject = QueryTextObject + "," + "
			//|	CASE
			//|		WHEN Table_П_Веб.Products IS NULL THEN True
			//|		ELSE False
			//|	END AS P_AvalibleInWebAppOrdersManagment";
		EndIf;

		///============================= FORMING THE QUERY TEXT BY "WHERE" And "JOIN"
		QueryTextObject = QueryTextObject + Chars.LF + "FROM" + Chars.LF + "	" + TableName + " AS "
			+ AliasTable;
		If SelectionByCategories Then
		//
			//For Each KeyAndValue In StructureCategories Do
			//	
			//	QueryTextObject = QueryTextObject + "
			//	|	LEFT JOIN InformationRegister.CategoriesObjects AS Table_"+KeyAndValue.Key+"
			//	|		ПО " + AliasTable + ".Ref = Table_"+KeyAndValue.Key+".Object
			//	|		And (Table_"+KeyAndValue.Key+".Category = &"+KeyAndValue.Key+")";
			//	
			//	
			//EndDo;
		EndIf;

		If SelectionByProperties Then

		//For Each KeyAndValue In StructureProperties Do
			//	
			//	QueryTextObject = QueryTextObject + "
			//	|	LEFT JOIN InformationRegister.ЗначенияСвойствОбъектов AS Table_"+KeyAndValue.Key+"
			//	|		ПО " + AliasTable + ".Ref = Table_"+KeyAndValue.Key+".Object
			//	|		And (Table_"+KeyAndValue.Key+".Property = &"+KeyAndValue.Key+")";
			//	
			//EndDo;
		EndIf;

		If ControlBalanceProducts Then

		//QueryTextObject = QueryTextObject + "," + "
			//|	LEFT JOIN AccumulationRegister.GoodsInWarehouses.Balance AS Table_R_Balance
			//|		ПО " + AliasTable + ".Ref = Table_R_Balance.Products
			//|	LEFT JOIN AccumulationRegister.ТоварыВРезервеНаСкладах.Balance AS Table_R_Reserve
			//|		ПО " + AliasTable + ".Ref = Table_R_Reserve.Products";
			//
		EndIf;

		If AccessibilityInWebApplicationProducts Then

			//QueryTextObject = QueryTextObject + "," + "
			//|	LEFT JOIN InformationRegister.ProductsUnusedInWebOrderManagement AS Table_П_Веб
			//|	ПО " + AliasTable + ".Ref = Table_P_Web.Products";
			//
		EndIf;

		If Object.ObjectType = 0 And MetadataRowObjects.Hierarchical And MetadataRowObjects.HierarchyType
			= Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then

			QueryTextObject = QueryTextObject + "
													  |WHERE
													  |	" + AliasTable + ".Ref.IsFolder = FALSE";

		EndIf;

		QueryText = ?(QueryText = "", "SELECT ", QueryText + Chars.LF + Chars.LF + "UNION ALL"
			+ Chars.LF + Chars.LF + "SELECT") + QueryTextObject;

		QueryTextObject = "SELECT " + QueryTextObject + QueryTextEnding;
		ArrayQueriesToObjects.Add(QueryTextObject);

	EndDo;

	QueryText = QueryText + QueryTextEnding;

	NewQueryText = "SELECT ALLOWED * FROM (" + QueryText + ") AS _Table";

		///============================= SAVING PREVIOUS QUERY SELECT SETTINGS
	//For IndexOf = 0 To QueryBuilder_Filter.Count() - 1 Do
	//	ArraySettingsFilter.Add(QueryBuilder_Filter.Get(IndexOf));
	//EndDo; 

	///============================= INITIALIZING TEXT AND QUERY FIELDS


	//QueryText = GetQueryText();
	QueryText = NewQueryText;
	ArbitraryQueryText = QueryText;
	DataSelection = Undefined;
	QueryParameters.Clear();

	//QueryBuilder.Text = QueryText;
	//QueryBuilder.FillSettings();
	//
	//NumberOfFields = QueryBuilder.AvailableFields.Count();
	//For к = 0 To NumberOfFields - 1 Do
	//	AvailableField = QueryBuilder.AvailableFields[NumberOfFields - к - 1];
	//	
	//	If QueryBuilder.SelectedFields.Find(AvailableField.Name) = Undefined Then
	//		QueryBuilder.AvailableFields.Delete(AvailableField);
	//	EndIf;
	//EndDo;
	//
	//NumberOfFields = QueryBuilder.SelectedFields.Count();
	//For к = 0 To NumberOfFields - 1 Do
	//	FieldName = QueryBuilder.SelectedFields[NumberOfFields - к - 1].Name;
	//	AvailableField = QueryBuilder.AvailableFields.Find(FieldName);
	//	QueryBuilder.AvailableFields.Move(AvailableField,-1000);
	//	
	//EndDo;
	// 
	//
	//For Each ItemPresentations In ListPresentations Do
	//	AvailableField = QueryBuilder.AvailableFields.Find(ItemPresentations.Presentation);
	//	If Not AvailableField = Undefined Then
	//		
	//		AvailableField.Presentation = GetPresentation(ItemPresentations);
	//		If Left(AvailableField.Name , 2) = "С_" Then
	//			AvailableField.ValueType = StructureProperties[AvailableField.Name].ValueType;
	//		EndIf; 
	//		
	//	EndIf;
	//	 
	//EndDo; 
	//
	//FilterAvailableFields = QueryBuilder.Filter.GetAvailableFields();
	//FilterAvailableFields.Delete(FilterAvailableFields.H_KindRepresentation);
	//FilterAvailableFields.H_Ref.Fields.Clear();
	////FilterAvailableFields.Delete(FilterAvailableFields.H_Ref);
	//If Object.ProcessTabularParts Then
	//	FilterAvailableFields.Delete(FilterAvailableFields.T_TPPresentation);
	//	FilterAvailableFields.Delete(FilterAvailableFields.T_TP);
	//EndIf; 
	//
	/////============================= RESTORING THE SELECTING SETTINGS OF THE PREVIOUS QUERY
	//For Each FilterItem In ArraySettingsFilter Do
	//	AvailableField = FilterAvailableFields.Find(FilterItem.DataPath);
	//	Try
	//		NewFilterItem = QueryBuilder.Filter.Add(FilterItem.DataPath);
	//		NewFilterItem.Use = FilterItem.Use;
	//		NewFilterItem.ComparisonType = FilterItem.ComparisonType;
	//		NewFilterItem.Value = FilterItem.Value;
	//		NewFilterItem.ValueFrom = FilterItem.ValueFrom;
	//		NewFilterItem.ValueTo = FilterItem.ValueTo;
	//	Except
	//	EndTry; 
	//EndDo; 
	//
	//
	PredefinedAttributes = New ValueList;
	//Template = GetTemplate("PredefinedAttributes");
	//Region = Template.Areas[?(Object.ObjectType = 0,"Catalogs","Documents")];
	//Counter = 0;
	//ObjectType = "*";
	//For к =  Region.Top To Region.Bottom Do
	//	
	//	CurrentTypeObject = TrimAll(Template.Region("R"+к+"C1").Text);
	//	
	//	If  CurrentTypeObject <> "" Then
	//		If CurrentTypeObject = "*" Then
	//			ObjectType = CurrentTypeObject;
	//		Else
	//			ObjectType = CurrentTypeObject;
	//		EndIf; 
	//		
	//	EndIf;
	//	
	//	If KindNameSingleType = ObjectType ИЛИ ObjectType = "*" Then
	//		
	//		FullNameAttribute = TrimAll(Template.Region("R"+к+"C2").Text);
	//		LongDesc = TrimAll(Template.Region("R"+к+"C3").Text);
	//		ЧерезТочку = False;
	//		PositionTP = Find(FullNameAttribute,".");
	//		ItIsCompoundAttribute = Not(PositionTP = 0);
	//		ИмяКорня = "H_"+?(PositionTP = 0,FullNameAttribute,Left(FullNameAttribute,PositionTP-1));
	//		//CustomField = QueryBuilder.AvailableFields.Find(ИмяКорня);
	//		//While Not PositionTP = 0 And Not CustomField = Undefined Do
	//		//	FullNameAttribute = Mid(FullNameAttribute,PositionTP+1);
	//		//	PositionTP = Find(FullNameAttribute,".");
	//		//	CustomField = CustomField.Fields.Find(?(PositionTP = 0,FullNameAttribute,Left(FullNameAttribute,PositionTP-1)));
	//		//	ЧерезТочку = True;
	//		//EndDo; 
	//		//If Not CustomField = Undefined Then
	//			If ItIsCompoundAttribute Then
	//				Counter = Counter+1;
	//				//QueryBuilder.SelectedFields.Add(CustomField.DataPath,"Д_"+Counter);
	//				ListPresentations.Add(LongDesc,"Д_"+Counter);
	//				PredefinedAttributes.Add(New Structure("Name,CustomField","Д_"+Counter,CustomField),LongDesc);
	//			Else
	//				PredefinedAttributes.Add(New Structure("Name,CustomField",CustomField.Name,CustomField),LongDesc);
	//			EndIf; 
	//			
	//		//EndIf; 
	//		
	//	EndIf; 
	//EndDo; 
	////
	/////============================= 
	//QueryBuilder_Filter = QueryBuilder.Filter;
	//QueryBuilder.PresentationAdding = PresentationAdditionType.DontAdd;
	DisplayedColumns = New Structure("H_KindRepresentation,H_Ref");
	If Object.ProcessTabularParts Then
		DisplayedColumns.Insert("T_TPPresentation");
		DisplayedColumns.Insert("T_LineNumber");
	EndIf;
	mShapedMode = New Structure("ViewList,DataSelected,KindNameSingleType,PredefinedAttributes,DisplayedColumns,StructureProperties,StructureCategories",
		ViewList, False, KindNameSingleType, PredefinedAttributes, DisplayedColumns, StructureProperties,
		StructureCategories);

EndProcedure

// QueryInitialization() 
&AtClient
Procedure CheckNecessaryClearResults(CompletionNotifyDescription)

	AdditionalParametersNotify = New Structure;
	AdditionalParametersNotify.Insert("CompletionNotifyDescription", CompletionNotifyDescription);

	If Not mShapedMode = Undefined And mShapedMode.DataSelected Then
		QuestionAboutCleaningSelectionResult(New NotifyDescription("CheckNecessaryClearResultsEnd",
			ThisObject, AdditionalParametersNotify));
	EndIf;

	CheckNecessaryClearResultsEnd(True, AdditionalParametersNotify);
EndProcedure

&AtClient
Procedure CheckNecessaryClearResultsEnd(Result, AdditionalParameters) Export
	CompletionNotifyDescription = AdditionalParameters.CompletionNotifyDescription;
	If Result Then
		ClearResults();
		mShapedMode = Undefined;
	EndIf;

	ExecuteNotifyProcessing(CompletionNotifyDescription, Result);
EndProcedure
&AtClient
Procedure QuestionAboutCleaningSelectionResult(CompletionNotifyDescription) Export
	Answer = Undefined;
	Message = Nstr("ru = 'Результат отбора будет очищен. Продолжить?';en = 'The selection result will be cleared. Proceed?'");
	ShowQueryBox(New NotifyDescription("QuestionAboutCleaningSelectionResultEnd", ThisForm,
		New Structure("CompletionNotifyDescription", CompletionNotifyDescription)),
		Message, QuestionDialogMode.OKCancel);
EndProcedure

&AtClient
Procedure QuestionAboutCleaningSelectionResultEnd(ResultQuestion, AdditionalParameters) Export

	CompletionNotifyDescription = AdditionalParameters.CompletionNotifyDescription;
	Result = ResultQuestion = DialogReturnCode.Cancel;
	ExecuteNotifyProcessing(CompletionNotifyDescription, Result);

EndProcedure

// () 
&AtClient
Procedure TableFieldTypesObjectsAfterDeleteRow(Item)
	CheckNecessaryClearResults(New NotifyDescription("TableFieldTypesObjectsAfterDeleteRowEnd",
		ThisObject));
EndProcedure

&AtClient
Procedure TableFieldTypesObjectsAfterDeleteRowEnd(Result, AdditionalParameters) Export
	If Result Then
		QueryInitialization();
	EndIf;
EndProcedure
Procedure ClearResults()
	FoundObjects.Clear();
EndProcedure

// () 
&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	ArrayOfStringsToDelete = New Array;
	MetadataObjects = Metadata[?(Object.ObjectType = 1, "Documents", "Catalogs")];

	For Each RowTable In TableFieldTypesObjects Do
		ArrayName = StrSplit(RowTable.TableName, ".");

		KindName = ArrayName[0];
		If MetadataObjects.Find(KindName) = Undefined Then
			ArrayOfStringsToDelete.Add(RowTable);
		EndIf;
	EndDo;
	
	// Delete what we can't process now
	For Each StringToRemove In ArrayOfStringsToDelete Do
		TableFieldTypesObjects.Delete(StringToRemove);
	EndDo;

	QueryInitialization();
	FormAttributeToValue("Object").DownloadDataProcessors(ThisForm, AvailableDataProcessors, SelectedDataProcessors);

EndProcedure

&AtClient
Procedure ProcessTabularPartsOnChange(Item)
	CheckNecessaryClearResults(New NotifyDescription("ProcessTabularPartsOnChangeEnd",
		ThisObject, New Structure("Item", Item)));
EndProcedure

&AtClient
Procedure ProcessTabularPartsOnChangeEnd(Result, AdditionalParameters) Export
	Item = AdditionalParameters.Item;
	If Result Then
		TableFieldTypesObjects.Clear();
		QueryInitialization();
	Else
		Item.Value = Not Item.Value;
	EndIf;
EndProcedure

&AtClient
Procedure ObjectTypeOnChange(Item)
	TableFieldTypesObjects.Clear();
	QueryInitialization();
EndProcedure

&AtClient
Procedure FoundObjectsSelection(Item, SelectedRow, Field, StandardProcessing)
	CurrentData = FoundObjects.FindByID(SelectedRow);
	ShowValue(Undefined, CurrentData.Object);
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_SetWriteSettings(Command)
	UT_CommonClient.EditWriteSettings(ThisObject);
EndProcedure

&AtClient
Procedure EditObject(Command)
	CurrentData = Items.FoundObjects.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	UT_CommonClient.EditObject(CurrentData.Object);
EndProcedure

&AtClient
Procedure Attachable_ExecuteToolsCommonCommand(Command) Export
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ThisObject, Command);
EndProcedure

