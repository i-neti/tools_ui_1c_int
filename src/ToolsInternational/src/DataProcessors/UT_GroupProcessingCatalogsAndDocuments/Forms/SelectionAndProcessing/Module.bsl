&AtClient
Var ProcessingDragAndDrop;

&AtServer
Function ОписаниеТипа(ТипСтрокой) Export

	МассивТипов = New Array;
	МассивТипов.Add(Type(ТипСтрокой));
	TypeDescription = New TypeDescription(МассивТипов);

	Return TypeDescription;

EndFunction

// вОписаниеТипа()

&AtServer
Function GetListTypesObjects()
	
	ТЗ = FormDataToValue(TableFieldTypesObjects, Type("ValueTable"));

	ListOfSelected = New ValueList;
	ListOfSelected.LoadValues(ТЗ.UnloadColumn("TableName"));

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
		If AccessRight("Browse", Catalog) Then
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
		If AccessRight("Browse", Document) Then
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

	InConfigurationYesCategories = Metadata.Catalogs.Find("КатегорииОбъектов") <> Undefined;
	InConfigurationYesProperties = Metadata.ChartsOfCharacteristicTypes.Find("ObjectProperties") <> Undefined;
	InConfigurationYesOrderManagement = Metadata.InformationRegisters.Find(
		"НоменклатураНеиспользуемаяВВебУправленииЗаказами") <> Undefined;

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
//	УстановитьВидимостьДоступность();
	QueryText = GetQueryText();
	ArbitraryQueryText = QueryText;
	DataSelection = Undefined;
	QueryParameters.Clear();
EndProcedure

&AtServer
Function GenerateSearchConditionByString()
	SearchConditionByString = "";

	If SearchString <> "" Then
		ИскомыйОбъект = SearchObject;
		ОбъектМетаданных = Metadata.FindByFullName(ИскомыйОбъект.Type + "." + ИскомыйОбъект.Name);

		SearchConditionByString = "";

		StringForSearch = StrReplace(SearchString, """", """""");

		If ИскомыйОбъект.Type = "Catalog" Then
			If ОбъектМетаданных.DescriptionLength <> 0 Then
				If SearchConditionByString <> "" Then
					SearchConditionByString = SearchConditionByString + " OR ";
				EndIf;
				SearchConditionByString = SearchConditionByString + " Title ПОДОБНО ""%" + StringForSearch + "%""";
			EndIf;

			If ОбъектМетаданных.CodeLength <> 0 And ОбъектМетаданных.CodeType
				= Metadata.ObjectProperties.CatalogCodeType.String Then
				If SearchConditionByString <> "" Then
					SearchConditionByString = SearchConditionByString + " OR ";
				EndIf;
				SearchConditionByString = SearchConditionByString + " Code ПОДОБНО ""%" + StringForSearch + "%""";
			EndIf;
		ElsIf ИскомыйОбъект.Type = "Document" Then
			If ОбъектМетаданных.NumberType = Metadata.ObjectProperties.DocumentNumberType.String Then
				If SearchConditionByString <> "" Then
					SearchConditionByString = SearchConditionByString + " OR ";
				EndIf;
				SearchConditionByString = SearchConditionByString + " Number ПОДОБНО ""%" + StringForSearch + "%""";
			EndIf;
		EndIf;

		For Each Attribute In ОбъектМетаданных.Attributes Do
			If Attribute.Type.ContainsType(Type("String")) Then
				If SearchConditionByString <> "" Then
					SearchConditionByString = SearchConditionByString + " OR ";
				EndIf;
				SearchConditionByString = SearchConditionByString + Attribute.Name + " ПОДОБНО ""%" + StringForSearch + "%""";
			EndIf;
		EndDo;
	EndIf;

	Return SearchConditionByString;
EndFunction

&AtServer
Function GetQueryText()

	ИскомыйОбъект = SearchObject;
	ОбъектМетаданных = Metadata.FindByFullName(ИскомыйОбъект.Type + "." + ИскомыйОбъект.Name);
	Condition = "";

	QueryText = "Select 
				   |	Reference As Object, 
				   |	Presentation";

	If ИскомыйОбъект.Type = "Catalog" Then
		If ОбъектМетаданных.DefaultPresentation
			<> Metadata.ObjectProperties.CatalogMainPresentation.AsDescription Then
			If ОбъектМетаданных.DescriptionLength <> 0 Then
				QueryText = QueryText + ", 
											  |	Title";
			EndIf;
			If ОбъектМетаданных.CodeLength <> 0 Then
				Condition = "Code";
			EndIf;
		EndIf;
		If ОбъектМетаданных.DefaultPresentation
			<> Metadata.ObjectProperties.CatalogMainPresentation.AsCode Then
			If ОбъектМетаданных.CodeLength <> 0 Then
				QueryText = QueryText + ",
											  |	Code";
			EndIf;
			If ОбъектМетаданных.DescriptionLength <> 0 Then
				Condition = "Title";
			EndIf;
		EndIf;
	ElsIf ИскомыйОбъект.Type = "Document" Then
		Condition = "Date, Number";
	EndIf;

	For Each Attribute In ОбъектМетаданных.Attributes Do
		QueryText = QueryText + ",
									  |	" + Attribute.Name;
	EndDo;

	QueryText = QueryText + Chars.LF + "ИЗ" + Chars.LF;
	QueryText = QueryText + "	" + ИскомыйОбъект.Type + "." + ОбъектМетаданных.Name + " AS _Table" + Chars.LF;

	For Each ТЧ In ОбъектМетаданных.TabularSections Do
		For Each ТЧР In ТЧ.Attributes Do
			If Condition <> "" Then
				Condition = Condition + ",";
			EndIf;
			Condition = Condition + ТЧ.Name + "." + ТЧР.Name + ".* AS " + ТЧ.Name + ТЧР.Name;
		EndDo;
	EndDo;

	//If Condition <> "" Then
	//	QueryText = QueryText + "{ГДЕ " + Condition + "}" + Chars.LF;
	//EndIf;

	//If SearchConditionByString <> "" Then
	//	QueryText = QueryText + "ГДЕ " + SearchConditionByString + Chars.LF;
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
										  |ГДЕ 
										  |	" + ListConditions;
		EndIf;

		QueryTextEnding = "";

		If Object.ObjectType = 1 Then

			QueryTextEnding = QueryTextEnding + "
															|УПОРЯДОЧИТЬ ПО
															|	Ш_Дата,
															|	Object";
			FieldsSort = "Ш_Дата,Object";

		Else

			QueryTextEnding = QueryTextEnding + "
															|УПОРЯДОЧИТЬ ПО
															|	Ш_Вид,
															|	Object";
			FieldsSort = "Ш_Вид,Object";

		EndIf;

		If Object.ProcessTabularParts Then
			QueryTextEnding = QueryTextEnding + ",
															|	Т_ТЧ,
															|	Т_НомерСтроки";
			FieldsSort = FieldsSort + ",Т_ТЧ,Т_НомерСтроки";
		EndIf;

		Query.Text = Query.Text + QueryTextEnding;

	EndIf;

	Try
		ТЗ = Query.Execute().Unload();
	Except
		Message(ErrorDescription());
		Return;
	EndTry;

	ArrayAttributes = New Array;
	ArrayAttributes.Add("Object");
	ArrayAttributes.Add("Picture");
	ArrayAttributes.Add("StartChoosing");

	CreateColumns(ТЗ, ArrayAttributes);

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
		Row.StartChoosing = Selection;
	EndDo;
EndProcedure

&AtClient
Procedure ExecuteProcessing(Command)
	
	For Each String In SelectedDataProcessors Do
		UserInterruptProcessing();

		If Not String.StartChoosing Then
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
			Message("Processing " + FormName + " недоступна для типа <" + SearchObject.Type + ">");
			Continue;
		EndIf;

		Processing = GetForm(GetFullFormName(ProcessingFormName), StructureParameters, ThisForm);
		Processing.ЗагрузитьНастройку();
		Processing.ExecuteProcessing();
	EndDo;
	
EndProcedure

&AtServer
Procedure CreateColumns(ТЗ, МассивРеквизитовПоУмолчанию = Undefined) Export
	
	ТаблицаЭлемент = Items.FoundObjects;

	//очистка
	For Each ДобавленныйЭлемент In AddedItems Do
		Items.Delete(Items[ДобавленныйЭлемент.Value]);
	EndDo;
	AddedItems.Clear();

	//добавляем реквизиты
	ArrayAttributes = New Array;
	For Each Column In ТЗ.Cols Do
		If МассивРеквизитовПоУмолчанию <> Undefined And МассивРеквизитовПоУмолчанию.Find(Column.Name)
			<> Undefined Then
			Continue;
		EndIf;

		ColumnType = String(Column.ValueType);
		If Column.Name = "Presentation" Or Find(ColumnType, "Хранилище значения") > 0 Then
			Continue;
		EndIf;

		FormAttribute = New FormAttribute(Column.Name, Column.ValueType, ТаблицаЭлемент.Name);

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

	//добавляем элементы управления
	For Each Attribute In ArrayAttributes Do
		AddedAttributes.Add(Attribute.Path + "." + Attribute.Name);

		Item = Items.Add(ТаблицаЭлемент.Name + Attribute.Name, Type("FormField"), ТаблицаЭлемент);
		Item.Type = FormFieldType.TextBox;
		Item.DataPath = ТаблицаЭлемент.Name + "." + Attribute.Name;
		Item.ReadOnly = True;

		AddedItems.Add(Item.Name);
	EndDo;

	//заполнение данными
	РедТЗ = FormAttributeToValue(ТаблицаЭлемент.Name);
	РедТЗ.Clear();
	For Each Стр In ТЗ Do
		НовСтр = РедТЗ.Add();
		FillPropertyValues(НовСтр, Стр);

		НовСтр.StartChoosing = True;

		//If SearchObject = Undefined Then
		//	Continue;
		//EndIf;
		If Object.ObjectType = 0 Then //"Catalog" Then
			If Стр.Object.IsFolder Then
				If Стр.Object.DeletionMark Then
					НовСтр.Picture = 3;
				Else
					НовСтр.Picture = 0;
				EndIf;
			Else
				If Стр.Object.DeletionMark Then
					НовСтр.Picture = 4;
				Else
					НовСтр.Picture = 1;
				EndIf;
			EndIf;
		Else
			If Стр.Object.Posted Then
				НовСтр.Picture = 7;
			ElsIf Стр.Object.DeletionMark Then
				НовСтр.Picture = 8;
			Else
				НовСтр.Picture = 6;
			EndIf;
		EndIf;
	EndDo;

	ValueToFormAttribute(РедТЗ, ТаблицаЭлемент.Name);
	
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
//	УстановитьВидимостьДоступность();
	SetPicturesProcessing();
EndProcedure

&AtClient
Procedure ДоступныеОбработкиВыбор(Item, SelectedRow, Field, StandardProcessing)
	
	If TableFieldTypesObjects.Count() = 0 Then
		Return;
	EndIf;

	StandardProcessing = False;

	RowIndex = Items.AvailableDataProcessors.CurrentLine;
	CurrentLine = AvailableDataProcessors.FindByID(RowIndex);

	StructureParameters = FormAStructureOfParameters();
	StructureParameters.Setting = CurrentLine.Setting[0].Value;

	Parent = CurrentLine.GetParent();
	If Parent = Undefined Then
		If Not ProcessingAvailable(?(Object.ObjectType = 0, "Catalog", "Document"), CurrentLine.FormName) Then
			ShowMessageBox( , "Данная обработка недоступна для типа <" + ?(Object.ObjectType = 0, "Catalog",
				"Document") + ">");
			Return;
		EndIf;

		StructureParameters.Settings = FormTheSettings(Item.CurrentData);
		StructureParameters.Insert("Parent", CurrentLine.GetID());
		StructureParameters.Insert("CurrentLine", Undefined);

		ИмяФормыДляОткрытия=GetFullFormName(CurrentLine.FormName);
	Else
		If Not ProcessingAvailable(?(Object.ObjectType = 0, "Catalog", "Document"), Parent.FormName) Then
			ShowMessageBox( , "Данная обработка недоступна для типа <" + ?(Object.ObjectType = 0, "Catalog",
				"Document") + ">");
			Return;
		EndIf;

		StructureParameters.Settings = FormTheSettings(Parent);
		StructureParameters.Insert("Parent", Parent.GetID());
		StructureParameters.Insert("CurrentLine", RowIndex);

		ИмяФормыДляОткрытия=GetFullFormName(Parent.FormName);
	EndIf;

	OpenForm(ИмяФормыДляОткрытия, StructureParameters, ThisObject, , , ,
		New NotifyDescription("ДоступныеОбработкиВыборЗавершение", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure ДоступныеОбработкиВыборЗавершение(Result, AdditionalParameters) Export
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
	StructureSelection.Insert("StartChoosing", True);
	StructureParameters.Insert("FoundObjects", FoundObjects.Unload(StructureSelection,
		"Object").UnloadColumn("Object"));

	Return StructureParameters;
	
EndFunction

&AtClient
Procedure ДоступныеОбработкиBeforeAddRow(Item, Cancel, Copy, Parent, Group)
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
				ShowMessageBox( , "Данная обработка недоступна для типа <" + ?(Object.ObjectType = 0,
					"Catalog", "Document") + ">");
				Cancel = True;
				Return;
			EndIf;

			Cancel = Not GetForm(GetFullFormName(Item.CurrentData.FormName)).мИспользоватьНастройки;
			If Not Cancel Then
			//свое добавление
				Cancel = True;
				AddRow(Item.CurrentData);
			EndIf;
		EndIf;
	Else
		If Not ProcessingAvailable(?(Object.ObjectType = 0, "Catalog", "Document"),
			Item.CurrentData.GetParent().FormName) Then
			ShowMessageBox( , "Данная обработка недоступна для типа <" + ?(Object.ObjectType = 0, "Catalog",
				"Document") + ">");
			Cancel = True;
			Return;
		EndIf;
		Cancel = True;
		If Not Copy Then
			If GetForm(GetFullFormName(
				Item.CurrentData.GetParent().FormName)).мИспользоватьНастройки Then
				AddRow(Item.CurrentData.GetParent());
			EndIf;
		Else
			CurrentData = Item.CurrentData;
			Parent = Item.CurrentData.GetParent();
			NewLine = AddRow(Parent);

			If Not CurrentData.Setting[0].Value = Undefined Then
				НоваяНастройка = New Structure;
				For Each РеквизитНастройки In CurrentData.Setting[0].Value Do
				//@skip-warning
					Value = РеквизитНастройки.Value;
					Execute ("НоваяНастройка.Insert(String(РеквизитНастройки.Key), Value);");
				EndDo;

				NewLine.Setting[0].Value = НоваяНастройка;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Function AddRow(CurrentLine)

	NewLine = CurrentLine.GetItems().Add();

	Setting = New Structure;
	Setting.Insert("Processing", CurrentLine.Processing);
	Setting.Insert("Other", Undefined);

	NewLine.Setting.Add(Setting);

	Items.AvailableDataProcessors.CurrentLine = NewLine.GetID();
	Items.AvailableDataProcessors.ChangeRow();

	Return NewLine;
	
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
Procedure ДоступныеОбработкиПередНачаломИзменения(Item, Cancel)
	If TableFieldTypesObjects.Count() = 0 Then
		Return;
	EndIf;

	If Item.CurrentData.GetParent() = Undefined Then
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure ДоступныеОбработкиПередУдалением(Item, Cancel)
	If Item.CurrentData.GetParent() = Undefined Then
		Return;
	EndIf;

	Cancel=True;

	ShowQueryBox(New NotifyDescription("ДоступныеОбработкиПередУдалениемЗавершение", ThisForm,
		New Structure("CurrentLine", Item.CurrentLine)), "Delete настройку?", QuestionDialogMode.OKCancel, ,
		DialogReturnCode.OK);
EndProcedure

&AtClient
Procedure ДоступныеОбработкиПередУдалениемЗавершение(ResultQuestion, AdditionalParameters) Export

	CurrentLine = AdditionalParameters.CurrentLine;
	If ResultQuestion = DialogReturnCode.OK Then
		ПараметрыОтбора = New Structure;
		ПараметрыОтбора.Insert("RowAvailableDataProcessor", CurrentLine);

		МассивДляУдаления = SelectedDataProcessors.FindRows(ПараметрыОтбора);
		For IndexOf = 0 To МассивДляУдаления.Count() - 1 Do
			SelectedDataProcessors.Delete(МассивДляУдаления[IndexOf]);
		EndDo;
	EndIf;

EndProcedure

&AtClient
Procedure ДоступныеОбработкиНачалоПеретаскивания(Item, DragParameters, StandardProcessing)
	
	If Not CheckAvailabilityProcessing() Then
		StandardProcessing = False;
		ShowMessageBox( , "Данная обработка недоступна для типа <" + ?(Object.ObjectType = 0, "Catalog",
			"Document") + ">");
		Return;
	EndIf;

	ProcessingDragAndDrop = True;
	
EndProcedure

&AtClient
Function CheckAvailabilityProcessing()
	
	RowIndex = Items.AvailableDataProcessors.CurrentLine;
	CurrentLine = AvailableDataProcessors.FindByID(RowIndex);

	Parent = CurrentLine.GetParent();
	If Parent = Undefined Then
		Return ProcessingAvailable(?(Object.ObjectType = 0, "Catalog", "Document"), CurrentLine.FormName);
	EndIf;

	Return ProcessingAvailable(?(Object.ObjectType = 0, "Catalog", "Document"), Parent.FormName);
	
EndFunction

&AtClient
Procedure ВыбранныеОбработкиПеретаскивание(Item, DragParameters, StandardProcessing, String, Field)
	
	If Not ProcessingDragAndDrop Then
		Return;
	EndIf;

	For Each СтрВыбранных In DragParameters.Value Do
		СтрДоступных = AvailableDataProcessors.FindByID(СтрВыбранных.GetID());

		НовСтр = SelectedDataProcessors.Add();
		НовСтр.ProcessingSetting = СтрДоступных.Processing;
		НовСтр.RowAvailableDataProcessor = СтрДоступных.GetID();
		НовСтр.StartChoosing = True;
		НовСтр.Setting = СтрДоступных.Setting;
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
		Row.StartChoosing = Selection;
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
Procedure ДоступныеОбработкиПриОкончанииРедактирования(Item, NewLine, ОтменаРедактирования)
	If Item.CurrentData.GetParent() = Undefined Then
		Return;
	EndIf;

	Setting = Item.CurrentData.Setting[0].Value;
	Setting.Processing = Item.CurrentData.Processing;
EndProcedure

&AtClient
Procedure SetPicturesProcessing()
	For Each Row In AvailableDataProcessors.GetItems() Do
		Row.Picture = PictureLib.Processing;
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

	Items.TableFieldTypesObjects.Update();
	
EndProcedure

Function TruncateArray(Array, Array2)
	
	Мас = New Array;

	For Each CurrentElement In Array Do
		If Array2.Find(CurrentElement) = Undefined Then
			Continue;
		EndIf;

		Мас.Add(CurrentElement);
	EndDo;

	Return Мас;
	
EndFunction

&AtServer
Procedure QueryInitialization()

	масЗапросовПоОбъектам = New Array;

	ВсегоСтрок = TableFieldTypesObjects.Count();
	//If ВсегоСтрок = 0 Then
	//	If Not QueryBuilder = Undefined And Not QueryBuilder.Filter = Undefined Then
	//		КоличествоОтборов = QueryBuilder.Filter.Count();
	//		For IndexOf = 1 To КоличествоОтборов Do
	//			QueryBuilder.Filter.Delete(КоличествоОтборов - IndexOf);
	//		EndDo; 
	//	EndIf; 
	//	QueryBuilder = Undefined;
	//	Return;
	//EndIf;	
	//If QueryBuilder = Undefined Then
	//	QueryBuilder = New QueryBuilder;
	//EndIf; 


	///============================= ИНИЦИАЛИЦАЗИЯ ПЕРЕМЕННЫХ
	MetadataObjects = Metadata[?(Object.ObjectType = 1, "Documents", "Catalogs")];
	ИмяТипаТаблицы = ?(Object.ObjectType = 1, "Document", "Catalog");
	Prefix = ?(Object.ProcessTabularParts, "Reference.", "");

	МассивТипов = New Array;
	МассивТипов.Add(Type("ValueStorage"));
	ОписаниеТипаХранилище = New TypeDescription(МассивТипов);

	МассивТипов = New Array;
	ViewList.Clear(); //      = New ValueList;
	СтруктураРеквизитовШапки = New Structure;
	СтруктураРеквизитовТЧ = New Structure;
	СтруктураТиповОбъектов = New Structure;
	СтруктураКатегорий = New Structure;
	СтруктураСвойств = New Structure;
	//	МассивНастроекОтбора     = New Array;
	TableAttributes.Clear();

	ViewNameSingleType = Undefined;
	ПрошлоеЗначение = Undefined;
	///============================= ПОДСЧЕТ ОДОИМЕННЫХ РЕКВИЗИТОВ
	For Each String In TableFieldTypesObjects Do

		If Not Object.ProcessTabularParts Then
			ViewName = String.TableName;
			ИмяТЧ="";
		Else
			ПозТЧК = Find(String.TableName, ".");
			ViewName = Left(String.TableName, ПозТЧК - 1);
			ИмяТЧ = Mid(String.TableName, ПозТЧК + 1);
		EndIf;

		If MetadataObjects.Find(ViewName) = Undefined Then
			Continue;
		EndIf;

		МетаданныеСтрокиОбъектов=MetadataObjects[ViewName];

		МетаданныеРеквизитов = МетаданныеСтрокиОбъектов.Attributes;

		If Object.ProcessTabularParts Then
			МетаданныеРеквизитовТЧ = МетаданныеСтрокиОбъектов.TabularSections[ИмяТЧ].Attributes;
		EndIf;

		If Object.ObjectType = 1 Then
			If МетаданныеСтрокиОбъектов.NumberLength > 0 Then
				СтруктураРеквизитовШапки.Insert("Number", ?(СтруктураРеквизитовШапки.Property("Number",
					ПрошлоеЗначение), ПрошлоеЗначение + 1, 1));
			EndIf;

			Filter = New Structure;
			Filter.Insert("Name", "Number");
			Filter.Insert("ЭтоТЧ", False);
			ArrayString = TableAttributes.FindRows(Filter);
			If МетаданныеСтрокиОбъектов.NumberType = Metadata.ObjectProperties.DocumentNumberType.String Then
				ТекТип = ОписаниеТипа("String");
			Else
				ТекТип = ОписаниеТипа("Number");
			EndIf;

			If ArrayString.Count() > 0 Then
				СтрокаРеквизитов = ArrayString[0];
			Else
				СтрокаРеквизитов = TableAttributes.Add();
				СтрокаРеквизитов.Name = "Number";
				СтрокаРеквизитов.Presentation = "Number";
				СтрокаРеквизитов.Type = ТекТип;
				СтрокаРеквизитов.ЭтоТЧ = False;
			EndIf;

			СтрокаРеквизитов.Type = New TypeDescription(TruncateArray(СтрокаРеквизитов.Type.Types(), ТекТип.Types()));

			СтруктураРеквизитовШапки.Insert("Date", ?(СтруктураРеквизитовШапки.Property("Date", ПрошлоеЗначение), ПрошлоеЗначение
				+ 1, 1));

			Filter = New Structure;
			Filter.Insert("Name", "Date");
			Filter.Insert("ЭтоТЧ", False);
			ArrayString = TableAttributes.FindRows(Filter);
			ТекТип = ОписаниеТипа("Date");

			If ArrayString.Count() > 0 Then
				СтрокаРеквизитов = ArrayString[0];
			Else
				СтрокаРеквизитов = TableAttributes.Add();
				СтрокаРеквизитов.Name = "Date";
				СтрокаРеквизитов.Presentation = "Date";
				СтрокаРеквизитов.Type = ТекТип;
				СтрокаРеквизитов.ЭтоТЧ = False;
			EndIf;
			СтрокаРеквизитов.Type = New TypeDescription(TruncateArray(СтрокаРеквизитов.Type.Types(), ТекТип.Types()));

			СтруктураРеквизитовШапки.Insert("Posted", ?(СтруктураРеквизитовШапки.Property("Posted",
				ПрошлоеЗначение), ПрошлоеЗначение + 1, 1));

			Filter = New Structure;
			Filter.Insert("Name", "Posted");
			Filter.Insert("ЭтоТЧ", False);
			ArrayString = TableAttributes.FindRows(Filter);
			ТекТип = ОписаниеТипа("Boolean");

			If ArrayString.Count() > 0 Then
				СтрокаРеквизитов = ArrayString[0];
			Else
				СтрокаРеквизитов = TableAttributes.Add();
				СтрокаРеквизитов.Name = "Posted";
				СтрокаРеквизитов.Presentation = "Posted";
				СтрокаРеквизитов.Type = ТекТип;
				СтрокаРеквизитов.ЭтоТЧ = False;
			EndIf;
			СтрокаРеквизитов.Type = New TypeDescription(TruncateArray(СтрокаРеквизитов.Type.Types(), ТекТип.Types()));
		Else
			If МетаданныеСтрокиОбъектов.CodeLength > 0 Then
				СтруктураРеквизитовШапки.Insert("Code", ?(СтруктураРеквизитовШапки.Property("Code", ПрошлоеЗначение), ПрошлоеЗначение
					+ 1, 1));

				Filter = New Structure;
				Filter.Insert("Name", "Code");
				Filter.Insert("ЭтоТЧ", False);
				ArrayString = TableAttributes.FindRows(Filter);
				If МетаданныеСтрокиОбъектов.CodeType = Metadata.ObjectProperties.CatalogCodeType.String Then
					ТекТип = ОписаниеТипа("String");
				Else
					ТекТип = ОписаниеТипа("Number");
				EndIf;

				If ArrayString.Count() > 0 Then
					СтрокаРеквизитов = ArrayString[0];
				Else
					СтрокаРеквизитов = TableAttributes.Add();
					СтрокаРеквизитов.Name = "Code";
					СтрокаРеквизитов.Presentation = "Code";
					СтрокаРеквизитов.Type = ТекТип;
					СтрокаРеквизитов.ЭтоТЧ = False;
				EndIf;
				СтрокаРеквизитов.Type = New TypeDescription(TruncateArray(СтрокаРеквизитов.Type.Types(), ТекТип.Types()));
			EndIf;

			If МетаданныеСтрокиОбъектов.DescriptionLength > 0 Then
				СтруктураРеквизитовШапки.Insert("Title", ?(СтруктураРеквизитовШапки.Property("Title",
					ПрошлоеЗначение), ПрошлоеЗначение + 1, 1));

				Filter = New Structure;
				Filter.Insert("Name", "Title");
				Filter.Insert("ЭтоТЧ", False);
				ArrayString = TableAttributes.FindRows(Filter);
				ТекТип = ОписаниеТипа("String");

				If ArrayString.Count() > 0 Then
					СтрокаРеквизитов = ArrayString[0];
				Else
					СтрокаРеквизитов = TableAttributes.Add();
					СтрокаРеквизитов.Name = "Title";
					СтрокаРеквизитов.Presentation = "Title";
					СтрокаРеквизитов.Type = ТекТип;
					СтрокаРеквизитов.ЭтоТЧ = False;
				EndIf;
				СтрокаРеквизитов.Type = New TypeDescription(TruncateArray(СтрокаРеквизитов.Type.Types(), ТекТип.Types()));
			EndIf;
		EndIf;

		If ViewNameSingleType = Undefined Then
			ViewNameSingleType = ViewName;
		ElsIf ViewNameSingleType <> ViewName Then
			ViewNameSingleType = False;
		EndIf;

		For Each РеквизитМетаданного In MetadataObjects[ViewName].Attributes Do

			If РеквизитМетаданного.Type = ОписаниеТипаХранилище Then
				Continue;
			ElsIf РеквизитМетаданного.Name = "Type" Then
				Continue;
			EndIf;

			СтруктураРеквизитовШапки.Insert(РеквизитМетаданного.Name, ?(СтруктураРеквизитовШапки.Property(
				РеквизитМетаданного.Name, ПрошлоеЗначение), ПрошлоеЗначение + 1, 1));

			Filter = New Structure;
			Filter.Insert("Name", РеквизитМетаданного.Name);
			Filter.Insert("ЭтоТЧ", False);
			ArrayString = TableAttributes.FindRows(Filter);

			If ArrayString.Count() > 0 Then
				СтрокаРеквизитов = ArrayString[0];
			Else
				СтрокаРеквизитов = TableAttributes.Add();
				СтрокаРеквизитов.Name = РеквизитМетаданного.Name;
				СтрокаРеквизитов.Presentation = РеквизитМетаданного.Synonym;
				СтрокаРеквизитов.Type = РеквизитМетаданного.Type;
				СтрокаРеквизитов.ЭтоТЧ = False;
			EndIf;

			СтрокаРеквизитов.Type = New TypeDescription(TruncateArray(СтрокаРеквизитов.Type.Types(),
				РеквизитМетаданного.Type.Types()));

		EndDo;

		If Object.ProcessTabularParts Then

			For Each РеквизитМетаданного In МетаданныеРеквизитовТЧ Do

				If РеквизитМетаданного.Type = ОписаниеТипаХранилище Then
					Continue;
				EndIf;

				СтруктураРеквизитовТЧ.Insert(РеквизитМетаданного.Name, ?(СтруктураРеквизитовТЧ.Property(
					РеквизитМетаданного.Name, ПрошлоеЗначение), ПрошлоеЗначение + 1, 1));

				Filter = New Structure;
				Filter.Insert("Name", РеквизитМетаданного.Name);
				Filter.Insert("ЭтоТЧ", True);
				ArrayString = TableAttributes.FindRows(Filter);

				If ArrayString.Count() > 0 Then
					СтрокаРеквизитов = ArrayString[0];
				Else
					СтрокаРеквизитов = TableAttributes.Add();
					СтрокаРеквизитов.Name = РеквизитМетаданного.Name;
					СтрокаРеквизитов.Presentation = РеквизитМетаданного.Synonym;
					СтрокаРеквизитов.Type = РеквизитМетаданного.Type;
					СтрокаРеквизитов.ЭтоТЧ = True;
				EndIf;

				СтрокаРеквизитов.Type = New TypeDescription(TruncateArray(СтрокаРеквизитов.Type.Types(),
					РеквизитМетаданного.Type.Types()));
			EndDo;
		EndIf;
		СтруктураТиповОбъектов.Insert(MetadataObjects[ViewName].Name, Type(ИмяТипаТаблицы + "Reference." + ViewName));
	EndDo;
	If ViewNameSingleType = False Then
		ViewNameSingleType = Undefined;
	EndIf;
	ВКонфигурацииЕстьОстаткиНоменклатуры = Not Metadata.AccumulationRegisters.Find("ТоварыНаСкладах") = Undefined;
	КонтрольОстатковНоменклатуры = (Object.ObjectType = 0) And (ViewNameSingleType = "Номенклатура")
		And ВКонфигурацииЕстьОстаткиНоменклатуры;
		//
	ДоступностьВВебПриложенииНоменклатуры = InConfigurationYesOrderManagement And (Object.ObjectType = 0)
		And (ViewNameSingleType = "Номенклатура");

		///============================= ОПРЕДЕЛЕНИЕ ОБЩИХ СВОЙСТВ And КАТЕГОРИЙ
	For Each KeyAndValue In СтруктураТиповОбъектов Do
		МассивТипов.Add(KeyAndValue.Value);
	EndDo;
	//	ОписаниеВсехТипов = New TypeDescription(МассивТипов);


	///============================= ОПРЕДЕЛЕНИЕ СОСТАВА РЕКВИЗИТОВ
	Счетчик = 0;
	For Each KeyAndValue In СтруктураРеквизитовТЧ Do

		If Not KeyAndValue.Value = ВсегоСтрок Then

			СтруктураРеквизитовТЧ.Delete(KeyAndValue.Key);

		Else
			Счетчик = Счетчик + 1;
			СтруктураРеквизитовТЧ.Insert(KeyAndValue.Key, "Т_" + KeyAndValue.Key);

		EndIf;

	EndDo;

	Счетчик = 0;
	For Each KeyAndValue In СтруктураРеквизитовШапки Do

		If Not KeyAndValue.Value = ВсегоСтрок Then

			СтруктураРеквизитовШапки.Delete(KeyAndValue.Key);

		Else
			Счетчик = Счетчик + 1;
			СтруктураРеквизитовШапки.Insert(KeyAndValue.Key, "Ш_" + KeyAndValue.Key);
		EndIf;

	EndDo;

	///============================= ОПРЕДЕЛЕНИЕ ПОРЯДКА And ПРЕДСТАВЛЕНИЯ РЕКВИЗИТОВ
	ViewList.Add("Type " + ИмяТипаТаблицы + "а", "Ш_Вид");
	ViewList.Add("Type " + ИмяТипаТаблицы + "а", "Ш_ВидПредставление");
	ViewList.Add("Reference", "Object");

	If Object.ProcessTabularParts Then

		ViewList.Add("Name ТЧ", "Т_ТЧ");
		ViewList.Add("Name ТЧ", "Т_ТЧПредставление");
		ViewList.Add("№ строки", "Т_НомерСтроки");

		For Each KeyAndValue In СтруктураРеквизитовТЧ Do
			ViewList.Add(МетаданныеРеквизитовТЧ[KeyAndValue.Key].Presentation(),
				KeyAndValue.Value);
		EndDo;

	EndIf;

	ViewList.Add(Prefix + "Check удаления", "Ш_ПометкаУдаления");

	If Object.ObjectType = 0 And Not ViewNameSingleType = Undefined Then

		If MetadataObjects[ViewNameSingleType].Owners.Count() > 0 Then

			СтруктураРеквизитовШапки.Insert("Owner", "Ш_Владелец");

		EndIf;

		If MetadataObjects[ViewNameSingleType].Hierarchical Then

			СтруктураРеквизитовШапки.Insert("Parent", "Ш_Родитель");

		EndIf;

	EndIf;

	//If КонтрольОстатковНоменклатуры Then
	//	
	//	СписокПредставлений.Add(Prefix+"Balance товара","Р_Остаток");
	//	СписокПредставлений.Add(Prefix+"Balance-Резерв товара","Р_Резерв");
	//	
	//EndIf;

	//If ДоступностьВВебПриложенииНоменклатуры Then
	//	
	//	СписокПредставлений.Add(Prefix+"Доступна в веб-приложении ""Управление заказами""","П_ДоступнаВВебПриложенииУпрЗаказами");
	//	
	//EndIf;
	For Each KeyAndValue In СтруктураРеквизитовШапки Do
		МетаданныеРеквизита = МетаданныеРеквизитов.Find(KeyAndValue.Key);
		If Not МетаданныеРеквизита = Undefined Then
			ViewList.Add(Prefix + МетаданныеРеквизита.Presentation(), KeyAndValue.Value);
		Else
			ViewList.Add(Prefix + KeyAndValue.Key, KeyAndValue.Value);
		EndIf;

	EndDo;

	For Each KeyAndValue In СтруктураКатегорий Do
		ViewList.Add(KeyAndValue.Value, KeyAndValue.Key);
	EndDo;

	For Each KeyAndValue In СтруктураСвойств Do
		ViewList.Add(KeyAndValue.Value, KeyAndValue.Key);
	EndDo;

	///============================= ДОБАВЛЕНИЕ ОБЩИХ РЕКВИЗИТОВ
	СтруктураРеквизитовШапки.Insert("DeletionMark", "Ш_ПометкаУдаления");

	If Object.ProcessTabularParts Then
		СтруктураРеквизитовТЧ.Insert("LineNumber", "Т_НомерСтроки");
	EndIf;

	///============================= ФОРМИРОВАНИЕ ТЕКСТА ЗАПРОСА
	QueryTextEnding = "";

	//If Object.ObjectType = 1 Then
	//	
	//	QueryTextEnding = QueryTextEnding + "
	//	|УПОРЯДОЧИТЬ ПО
	//	|	Ш_Дата,
	//	|	Object";
	//	FieldsSort = "Ш_Дата,Object";
	//	
	//Else
	//	
	//	QueryTextEnding = QueryTextEnding + "
	//	|УПОРЯДОЧИТЬ ПО
	//	|	Ш_Вид,
	//	|	Object";
	//	FieldsSort = "Ш_Вид,Object";
	//	
	//EndIf;
	//
	//If Object.ProcessTabularParts Then
	//	QueryTextEnding = QueryTextEnding + ",
	//	|	Т_ТЧ,
	//	|	Т_НомерСтроки";
	//	FieldsSort = FieldsSort + ",Т_ТЧ,Т_НомерСтроки";
	//EndIf;
	QueryText = "";

	For Each String In TableFieldTypesObjects Do

		If Not Object.ProcessTabularParts Then
			ViewName = String.TableName;
		Else
			ПозТЧК = Find(String.TableName, ".");
			ViewName = Left(String.TableName, ПозТЧК - 1);
			ИмяТЧ = Mid(String.TableName, ПозТЧК + 1);
		EndIf;

		If MetadataObjects.Find(ViewName) = Undefined Then
			Continue;
		EndIf;

		МетаданныеСтрокиОбъектов=MetadataObjects[ViewName];

		МетаданныеРеквизитов = МетаданныеСтрокиОбъектов.Attributes;

		If Object.ProcessTabularParts Then
			МетаданныеРеквизитовТЧ = МетаданныеСтрокиОбъектов.TabularSections[ИмяТЧ].Attributes;
		EndIf;

		TableName = ИмяТипаТаблицы + "." + String.TableName;
		ПсевдонимТаблицы = StrReplace(TableName, ".", "_");

		///============================= ФОРМИРОВАНИЕ ТЕКСТА ЗАПРОСА ПО РЕКВИЗИТАМ
		QueryTextObject = "";
		QueryTextObject = QueryTextObject + "" + Chars.LF + "	""" + ViewName + """ КАК Ш_Вид";
		QueryTextObject = QueryTextObject + "," + Chars.LF + "	""" + StrReplace(
			MetadataObjects[ViewName].Presentation(), """", "") + """ КАК Ш_ВидПредставление";
		QueryTextObject = QueryTextObject + "," + Chars.LF + "	" + ПсевдонимТаблицы + "." + Prefix
			+ "Reference КАК Object";

		For Each KeyAndValue In СтруктураРеквизитовШапки Do
			МетаданноеРеквизита = МетаданныеРеквизитов.Find(KeyAndValue.Key);
			If Not МетаданноеРеквизита = Undefined And МетаданноеРеквизита.Type.ContainsType(Type("String"))
				And МетаданноеРеквизита.Type.StringQualifiers.Length = 0 Then
				QueryTextObject = QueryTextObject + "," + Chars.LF + "	ПОДСТРОКА(" + ПсевдонимТаблицы + "."
					+ Prefix + KeyAndValue.Key + ",1," + RestrictionOnStringsUnlimitedLength + ")";
			Else
				QueryTextObject = QueryTextObject + "," + Chars.LF + "	" + ПсевдонимТаблицы + "." + Prefix
					+ KeyAndValue.Key;
			EndIf;
			QueryTextObject = QueryTextObject + " КАК " + KeyAndValue.Value;
		EndDo;

		If Object.ProcessTabularParts Then

			QueryTextObject = QueryTextObject + "," + Chars.LF + "	""" + ИмяТЧ + """ КАК Т_ТЧ";
			QueryTextObject = QueryTextObject + "," + Chars.LF + "	"""
				+ МетаданныеСтрокиОбъектов.TabularSections[ИмяТЧ].Presentation() + """ КАК Т_ТЧПредставление";

			For Each KeyAndValue In СтруктураРеквизитовТЧ Do

				МетаданноеРеквизита = МетаданныеРеквизитовТЧ.Find(KeyAndValue.Key);

				If Not МетаданноеРеквизита = Undefined And МетаданноеРеквизита.Type.ContainsType(Type("String"))
					And МетаданноеРеквизита.Type.StringQualifiers.Length = 0 Then

					QueryTextObject = QueryTextObject + "," + Chars.LF + "	ПОДСТРОКА(" + ПсевдонимТаблицы
						+ "." + KeyAndValue.Key + ",1," + RestrictionOnStringsUnlimitedLength + ")";

				Else

					QueryTextObject = QueryTextObject + "," + Chars.LF + "	" + ПсевдонимТаблицы + "."
						+ KeyAndValue.Key;

				EndIf;

				QueryTextObject = QueryTextObject + " КАК " + KeyAndValue.Value;

			EndDo;
		EndIf;

		///============================= ФОРМИРОВАНИЕ ТЕКСТА ЗАПРОСА ПО СВОЙСТВАМ And КАТЕГОРИЯМ
		If SelectionByCategories Then
		//
			//For каждого KeyAndValue In СтруктураКатегорий Do
			//	
			//	QueryTextObject = QueryTextObject + "," + Chars.LF + 
			//	"	ВЫБОР КОГДА Таблица_"+KeyAndValue.Key+".Category ЕСТЬ NULL ТОГДА ЛОЖЬ ИНАЧЕ ИСТИНА КОНЕЦ КАК " + KeyAndValue.Key;
			//	
			//EndDo; 
		EndIf;

		If SelectionByProperties Then

		//For каждого KeyAndValue In СтруктураСвойств Do
			//	
			//	QueryTextObject = QueryTextObject + "," + Chars.LF + "	Таблица_"+KeyAndValue.Key+".Value КАК "+KeyAndValue.Key;
			//	
			//EndDo; 
		EndIf;

		///============================= ФОРМИРОВАНИЕ ТЕКСТА ЗАПРОСА ПО ОСТАТКАМ НОМЕНКЛАТУРЫ
		If КонтрольОстатковНоменклатуры Then

		//QueryTextObject = QueryTextObject + "," + "
			//|	ЕСТЬNULL(Таблица_Р_Остаток.КоличествоОстаток,0) Как Р_Остаток,
			//|	ЕСТЬNULL(Таблица_Р_Остаток.КоличествоОстаток, 0) - ЕСТЬNULL(Таблица_Р_Резерв.КоличествоОстаток, 0) КАК Р_Резерв";
		EndIf;

		If ДоступностьВВебПриложенииНоменклатуры Then

		//QueryTextObject = QueryTextObject + "," + "
			//|	ВЫБОР
			//|		КОГДА Таблица_П_Веб.Номенклатура ЕСТЬ NULL ТОГДА True
			//|		ИНАЧЕ False
			//|	КОНЕЦ КАК П_ДоступнаВВебПриложенииУпрЗаказами";
		EndIf;

		///============================= ФОРМИРОВАНИЕ ТЕКСТА ЗАПРОСА ПО "ИЗ" And "СОЕДИНЕНИЕ"
		QueryTextObject = QueryTextObject + Chars.LF + "ИЗ" + Chars.LF + "	" + TableName + " КАК "
			+ ПсевдонимТаблицы;
		If SelectionByCategories Then
		//
			//For каждого KeyAndValue In СтруктураКатегорий Do
			//	
			//	QueryTextObject = QueryTextObject + "
			//	|	ЛЕВОЕ СОЕДИНЕНИЕ InformationRegister.КатегорииОбъектов КАК Таблица_"+KeyAndValue.Key+"
			//	|		ПО " + ПсевдонимТаблицы + ".Reference = Таблица_"+KeyAndValue.Key+".Object
			//	|		And (Таблица_"+KeyAndValue.Key+".Category = &"+KeyAndValue.Key+")";
			//	
			//	
			//EndDo;
		EndIf;

		If SelectionByProperties Then

		//For каждого KeyAndValue In СтруктураСвойств Do
			//	
			//	QueryTextObject = QueryTextObject + "
			//	|	ЛЕВОЕ СОЕДИНЕНИЕ InformationRegister.ЗначенияСвойствОбъектов КАК Таблица_"+KeyAndValue.Key+"
			//	|		ПО " + ПсевдонимТаблицы + ".Reference = Таблица_"+KeyAndValue.Key+".Object
			//	|		And (Таблица_"+KeyAndValue.Key+".Property = &"+KeyAndValue.Key+")";
			//	
			//EndDo;
		EndIf;

		If КонтрольОстатковНоменклатуры Then

		//QueryTextObject = QueryTextObject + "," + "
			//|	ЛЕВОЕ СОЕДИНЕНИЕ AccumulationRegister.ТоварыНаСкладах.Balance КАК Таблица_Р_Остаток
			//|		ПО " + ПсевдонимТаблицы + ".Reference = Таблица_Р_Остаток.Номенклатура
			//|	ЛЕВОЕ СОЕДИНЕНИЕ AccumulationRegister.ТоварыВРезервеНаСкладах.Balance КАК Таблица_Р_Резерв
			//|		ПО " + ПсевдонимТаблицы + ".Reference = Таблица_Р_Резерв.Номенклатура";
			//
		EndIf;

		If ДоступностьВВебПриложенииНоменклатуры Then

		//QueryTextObject = QueryTextObject + "," + "
			//|	ЛЕВОЕ СОЕДИНЕНИЕ InformationRegister.НоменклатураНеиспользуемаяВВебУправленииЗаказами КАК Таблица_П_Веб
			//|	ПО " + ПсевдонимТаблицы + ".Reference = Таблица_П_Веб.Номенклатура";
			//
		EndIf;

		If Object.ObjectType = 0 And МетаданныеСтрокиОбъектов.Hierarchical And МетаданныеСтрокиОбъектов.HierarchyType
			= Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then

			QueryTextObject = QueryTextObject + "
													  |ГДЕ
													  |	" + ПсевдонимТаблицы + ".Reference.IsFolder = ЛОЖЬ";

		EndIf;

		QueryText = ?(QueryText = "", "StartChoosing ", QueryText + Chars.LF + Chars.LF + "ОБЪЕДИНИТЬ ВСЕ"
			+ Chars.LF + Chars.LF + "Select") + QueryTextObject;

		QueryTextObject = "StartChoosing " + QueryTextObject + QueryTextEnding;
		масЗапросовПоОбъектам.Add(QueryTextObject);

	EndDo;

	QueryText = QueryText + QueryTextEnding;

	NewQueryText = "StartChoosing РАЗРЕШЕННЫЕ * ИЗ (" + QueryText + ") КАК _Table";

		///============================= СОХРАНЕНИЕ НАСТРОЕК ОТБОРА ПРЕДЫДУЩЕГО ЗАПРОСА
	//For IndexOf = 0 To ПостроительЗапроса_Отбор.Count() - 1 Do
	//	МассивНастроекОтбора.Add(ПостроительЗапроса_Отбор.Get(IndexOf));
	//EndDo; 

	///============================= ИНИЦИАЛИЗАЦИЯ ТЕКСТА And ПОЛЕЙ ЗАПРОСА


	//QueryText = GetQueryText();
	QueryText = NewQueryText;
	ArbitraryQueryText = QueryText;
	DataSelection = Undefined;
	QueryParameters.Clear();

	//QueryBuilder.Text = QueryText;
	//QueryBuilder.FillSettings();
	//
	//КоличествоПолей = QueryBuilder.AvailableFields.Count();
	//For к = 0 To КоличествоПолей - 1 Do
	//	ДоступноеПоле = QueryBuilder.AvailableFields[КоличествоПолей - к - 1];
	//	
	//	If QueryBuilder.SelectedFields.Find(ДоступноеПоле.Name) = Undefined Then
	//		QueryBuilder.AvailableFields.Delete(ДоступноеПоле);
	//	EndIf;
	//EndDo;
	//
	//КоличествоПолей = QueryBuilder.SelectedFields.Count();
	//For к = 0 To КоличествоПолей - 1 Do
	//	FieldName = QueryBuilder.SelectedFields[КоличествоПолей - к - 1].Name;
	//	ДоступноеПоле = QueryBuilder.AvailableFields.Find(FieldName);
	//	QueryBuilder.AvailableFields.Move(ДоступноеПоле,-1000);
	//	
	//EndDo;
	// 
	//
	//For каждого ЭлементПредставления In СписокПредставлений Do
	//	ДоступноеПоле = QueryBuilder.AvailableFields.Find(ЭлементПредставления.Presentation);
	//	If Not ДоступноеПоле = Undefined Then
	//		
	//		ДоступноеПоле.Presentation = ПолучитьПредставление(ЭлементПредставления);
	//		If Left(ДоступноеПоле.Name , 2) = "С_" Then
	//			ДоступноеПоле.ValueType = СтруктураСвойств[ДоступноеПоле.Name].ValueType;
	//		EndIf; 
	//		
	//	EndIf;
	//	 
	//EndDo; 
	//
	//FilterAvailableFields = QueryBuilder.Filter.GetAvailableFields();
	//FilterAvailableFields.Delete(FilterAvailableFields.Ш_ВидПредставление);
	//FilterAvailableFields.Ш_Ссылка.Fields.Clear();
	////FilterAvailableFields.Delete(FilterAvailableFields.Ш_Ссылка);
	//If Object.ProcessTabularParts Then
	//	FilterAvailableFields.Delete(FilterAvailableFields.Т_ТЧПредставление);
	//	FilterAvailableFields.Delete(FilterAvailableFields.Т_ТЧ);
	//EndIf; 
	//
	/////============================= ВОССТАНОВЛЕНИЕ НАСТРОЕК ОТБОРА ПРЕДЫДУЩЕГО ЗАПРОСА
	//For каждого FilterItem In МассивНастроекОтбора Do
	//	ДоступноеПоле = FilterAvailableFields.Find(FilterItem.DataPath);
	//	Try
	//		НовыйЭлементОтбора = QueryBuilder.Filter.Add(FilterItem.DataPath);
	//		НовыйЭлементОтбора.Use = FilterItem.Use;
	//		НовыйЭлементОтбора.ComparisonType = FilterItem.ComparisonType;
	//		НовыйЭлементОтбора.Value = FilterItem.Value;
	//		НовыйЭлементОтбора.ValueFrom = FilterItem.ValueFrom;
	//		НовыйЭлементОтбора.ValueTo = FilterItem.ValueTo;
	//	Except
	//	EndTry; 
	//EndDo; 
	//
	//
	ПредопределенныеРеквизиты = New ValueList;
	//Template = GetTemplate("ПредопределенныеРеквизиты");
	//Region = Template.Areas[?(Object.ObjectType = 0,"Catalogs","Documents")];
	//Счетчик = 0;
	//ВидОбъекта = "*";
	//For к =  Region.Top To Region.Bottom Do
	//	
	//	ТекВидОбъекта = TrimAll(Template.Region("R"+к+"C1").Text);
	//	
	//	If  ТекВидОбъекта <> "" Then
	//		If ТекВидОбъекта = "*" Then
	//			ВидОбъекта = ТекВидОбъекта;
	//		Else
	//			ВидОбъекта = ТекВидОбъекта;
	//		EndIf; 
	//		
	//	EndIf;
	//	
	//	If ViewNameSingleType = ВидОбъекта ИЛИ ВидОбъекта = "*" Then
	//		
	//		ПолноеИмяРеквизита = TrimAll(Template.Region("R"+к+"C2").Text);
	//		LongDesc = TrimAll(Template.Region("R"+к+"C3").Text);
	//		ЧерезТочку = False;
	//		ПозТЧК = Find(ПолноеИмяРеквизита,".");
	//		ЭтоСоставнойРеквизит = Not(ПозТЧК = 0);
	//		ИмяКорня = "Ш_"+?(ПозТЧК = 0,ПолноеИмяРеквизита,Left(ПолноеИмяРеквизита,ПозТЧК-1));
	//		//CustomField = QueryBuilder.AvailableFields.Find(ИмяКорня);
	//		//While Not ПозТЧК = 0 And Not CustomField = Undefined Do
	//		//	ПолноеИмяРеквизита = Mid(ПолноеИмяРеквизита,ПозТЧК+1);
	//		//	ПозТЧК = Find(ПолноеИмяРеквизита,".");
	//		//	CustomField = CustomField.Fields.Find(?(ПозТЧК = 0,ПолноеИмяРеквизита,Left(ПолноеИмяРеквизита,ПозТЧК-1)));
	//		//	ЧерезТочку = True;
	//		//EndDo; 
	//		//If Not CustomField = Undefined Then
	//			If ЭтоСоставнойРеквизит Then
	//				Счетчик = Счетчик+1;
	//				//QueryBuilder.SelectedFields.Add(CustomField.DataPath,"Д_"+Счетчик);
	//				СписокПредставлений.Add(LongDesc,"Д_"+Счетчик);
	//				ПредопределенныеРеквизиты.Add(New Structure("Name,CustomField","Д_"+Счетчик,CustomField),LongDesc);
	//			Else
	//				ПредопределенныеРеквизиты.Add(New Structure("Name,CustomField",CustomField.Name,CustomField),LongDesc);
	//			EndIf; 
	//			
	//		//EndIf; 
	//		
	//	EndIf; 
	//EndDo; 
	////
	/////============================= 
	//ПостроительЗапроса_Отбор = QueryBuilder.Filter;
	//QueryBuilder.PresentationAdding = PresentationAdditionType.DontAdd;
	ОтображаемыеКолонки = New Structure("Ш_ВидПредставление,Ш_Ссылка");
	If Object.ProcessTabularParts Then
		ОтображаемыеКолонки.Insert("Т_ТЧПредставление");
		ОтображаемыеКолонки.Insert("Т_НомерСтроки");
	EndIf;
	mShapedMode = New Structure("ViewList,DataSelected,ViewNameSingleType,ПредопределенныеРеквизиты,ОтображаемыеКолонки,СтруктураСвойств,СтруктураКатегорий",
		ViewList, False, ViewNameSingleType, ПредопределенныеРеквизиты, ОтображаемыеКолонки, СтруктураСвойств,
		СтруктураКатегорий);

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

		ViewName = ArrayName[0];
		If MetadataObjects.Find(ViewName) = Undefined Then
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

