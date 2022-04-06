
///////////////////////////////////////////////////////////////////////////////
// PRIVATE

&AtServer
Function DataProcessorID()
	DataProcessorObject = FormAttributeToValue("Object");
	Return DataProcessorObject.Metadata().FullName();
EndFunction

// Displays error message and sets Cancel to True.
// If at client or at server, displays message in message window.
// If external connection, raises exception.
//
// Parameters:
//  MessageText - String - message text.
//  Cancel      - Boolean, (optional) cancel flag.
//
&AtServerNoContext
Procedure mErrorMessage(MessageText, Cancel = False, Title = "") Export

	InternalMessageBegin    = Find(MessageText, "{");
	InternalMessageEnd = Find(MessageText, "}:");
	If InternalMessageEnd > 0 And InternalMessageBegin > 0 Then
		MessageText = Left(MessageText, (InternalMessageBegin - 1)) + Mid(MessageText,
			(InternalMessageEnd + 2));
	EndIf;

	Cancel = True;

	If ValueIsFilled(Title) Then
		Message(Title);
		Title = "";
	EndIf;

	Message(MessageText, MessageStatus.Important);

EndProcedure

// Splits the string into several strings by the specified separator. The separator can be any length.
// If space is used as a separator, adjacent spaces are treated as one separator, 
// leading and trailing spaces of the Str parameter are ignored.
// 
// Example:
//		mSplitStringIntoSubstringsArray(",qu,,,mu", ",")
//			- returns an array of five items, three of which are empty strings;
//		mSplitStringIntoSubstringsArray(" qu   mu", " ")
//			- returns an array of two items: "qu", "mu".
//
//	Parameters:
//		Str - String - a delimited text.
//		Separator - String - a text separator, "," by default.
//
//
//	Return value:
//		Array - an array of strings.
//
&AtServer
Function mSplitStringIntoSubstringsArray(Val Str, Separator = ",")

	StringArray = New Array;
	If Separator = " " Then
		Str = TrimAll(Str);
		While 1 = 1 Do
			Pos = Find(Str, Separator);
			If Pos = 0 Then
				StringArray.Add(Str);
				Return StringArray;
			EndIf;
			StringArray.Add(Left(Str, Pos - 1));
			Str = TrimL(Mid(Str, Pos));
		EndDo;
	Else
		SeparatorLength = StrLen(Separator);
		While 1 = 1 Do
			Pos = Find(Str, Separator);
			If Pos = 0 Then
				StringArray.Add(Str);
				Return StringArray;
			EndIf;
			StringArray.Add(Left(Str, Pos - 1));
			Str = Mid(Str, Pos + SeparatorLength);
		EndDo;
	EndIf;

EndFunction

// Adjusts a string presentation of number to its value.
//
// Parameters:
//  Presentation - String - a number presentation.
//  TypeDescription - TypeDescription - a description of number type.
//  Comment - String - an error description.
//
// Return value:
//  Number - Adjusted value.
//
&AtServer
Function mAdjustToNumber(Presentation, Val TypeDescription = Undefined, Comment = "")

	If TypeDescription = Undefined Then
		TypeDescription = New TypeDescription("Number");
	EndIf;

	PresentationLower = Lower(Presentation);
	If PresentationLower = "yes" Or PresentationLower = "True" Or PresentationLower = "enabled" Then
		Return 1;
	ElsIf PresentationLower = "no" Or PresentationLower = "False" Or PresentationLower = "disabled" Then
		Return 0;
	EndIf;

	Result = StrReplace(Presentation, " ", "");
	Try
		Result = Number(Result);
	Except
		Comment = NStr("ru = 'Неправильный формат числа'; en = 'Incorrect number format'");
		Return 0;
	EndTry;

	Result1 = TypeDescription.AdjustValue(Result);

	If Not Result1 = Result Then
		Comment = NStr("ru = 'Недопустимое числовое значение'; en = 'Invalid number value'");
	EndIf;

	Return Result1;

EndFunction // mAdjustToNumber()

// Adjusts a string presentation of date to its value.
//
// Parameters:
//  Presentation - String - a date presentation.
//  AttributeType - TypeDescription - a description of date type.
//  Comment - String - an error description.
//
// Return value:
//  Date - Adjusted value.
//
&AtServer
Function mAdjustToDate(Presentation, AttributeType, Comment = "")

	Result = AttributeType.ПривестиЗначение(Presentation);
	If Result = '00010101' Then

		FractionsArray = GetDatePresentationFractions(Presentation);
		If AttributeType.DateQualifiers.DateFractions = DateFractions.Time Then

			Try

				If FractionsArray.Count() = 3 Then
					Result = Date(1, 1, 1, FractionsArray[0], FractionsArray[1], FractionsArray[2]);
				ElsIf FractionsArray.Count() = 6 Then
					Result = Date(1, 1, 1, FractionsArray[3], FractionsArray[4], FractionsArray[5]);
				EndIf;

			Except
				Comment = NStr("ru = 'Неправильный формат даты'; en = 'Invalid date format'");
			EndTry;

		ElsIf FractionsArray.Count() = 3 Or FractionsArray.Count() = 6 Then

			If FractionsArray[0] >= 1000 Then
				Temp = FractionsArray[0];
				FractionsArray[0] = FractionsArray[2];
				FractionsArray[2] = Temp;
			EndIf;

			If FractionsArray[2] < 100 Then
				FractionsArray[2] = FractionsArray[2] + ?(FractionsArray[2] < 30, 2000, 1900);
			EndIf;

			Try
				If FractionsArray.Count() = 3 Or AttributeType.DateQualifiers.DateFractions = DateFractions.Date Then
					Result = Date(FractionsArray[2], FractionsArray[1], FractionsArray[0]);
				Else
					Result = Date(FractionsArray[2], FractionsArray[1], FractionsArray[0], FractionsArray[3],
						FractionsArray[4], FractionsArray[5]);
				EndIf;
			Except
				Comment = NStr("ru = 'Неправильный формат даты'; en = 'Invalid date format'");
			EndTry;

		EndIf;

	EndIf;

	Return Result;

EndFunction

// Returns date presentation fractions.
//
// Parameters:
//  Presentation - String - date presentation.
//
// Return valus:
//  Array - date fractions.
//
&AtServer
Function GetDatePresentationFractions(Val Presentation)

	FractionsArray = New Array;
	BeginOfDigit = 0;
	For k = 1 To StrLen(Presentation) Do

		Char = Mid(Presentation, k, 1);
		IsDigit = Char >= "0" And Char <= "9";

		If IsDigit Then

			If BeginOfDigit = 0 Then
				BeginOfDigit = k;
			EndIf;

		Else

			If Not BeginOfDigit = 0 Then
				FractionsArray.Add(Number(Mid(Presentation, BeginOfDigit, k - BeginOfDigit)));
			EndIf;

			BeginOfDigit = 0;
		EndIf;

	EndDo;

	If Not BeginOfDigit = 0 Then
		FractionsArray.Add(Number(Mid(Presentation, BeginOfDigit)));
	EndIf;

	Return FractionsArray;
EndFunction // ()

// Returns manager by value type.
//
// Parameters:
//  ValueType - Type - type of value to get manager.
//
// Return value:
//  CatalogManager, DocumentManager, etc.
//
&AtServer
Function GetManagerByType(ValueType) Export

	If Not ValueType = Undefined Then
		MetadataObjectManagers = New Structure("Catalogs, Enums, Documents, ChartsOfCharacteristicTypes, ChartsOfAccounts, ChartsOfCalculationTypes, BusinessProcesses, Tasks",
			Catalogs, Enums, Documents, ChartsOfCharacteristicTypes, ChartsOfAccounts, ChartsOfCalculationTypes,
			BusinessProcesses, Tasks);
		For Each MetadataObjectManager In MetadataObjectManagers Do
			If MetadataObjectManager.Value.AllRefsType().ContainsType(ValueType) Then
				Manager = MetadataObjectManager.Value[Metadata.FindByType(ValueType).Name];
				Break;
			EndIf;
		EndDo;
		Return Manager;
	Else
		Return Undefined;
	EndIf;

EndFunction

&AtServer
Function GetTypeDescription(AttributeTypesDescription) Export

	TypesDescription = "";

	For Each Type In AttributeTypesDescription.Types() Do
		TypeMetadata = Metadata.FindByType(Type);
		If Not TypeMetadata = Undefined Then
			TypeDescription = TypeMetadata.FullName();
		ElsIf Type = Type("String") Then

			TypeDescription = "String";
			If AttributeTypesDescription.StringQualifiers.Length Then
				TypeDescription = TypeDescription + ", " + AttributeTypesDescription.StringQualifiers.Length;
				If AttributeTypesDescription.StringQualifiers.AllowedLength = AllowedLength.Fixed Then
					TypeDescription = TypeDescription + ", " + AllowedLength.Fixed;
				EndIf;
			EndIf;

		ElsIf Type = Type("Number") Then
			TypeDescription = "Number" + ", " + AttributeTypesDescription.NumberQualifiers.Digits + ", "
				+ AttributeTypesDescription.NumberQualifiers.FractionDigits + ?(
				AttributeTypesDescription.NumberQualifiers.AllowedSign = AllowedSign.Nonnegative,
				", Nonnegative", "");
		ElsIf Type = Type("Date") Then
			TypeDescription = "" + AttributeTypesDescription.DateQualifiers.DateFractions;
		ElsIf Type = Type("Boolean") Then
			TypeDescription = "Boolean";
		Else
			Continue;
		EndIf;

		TypesDescription = ?(IsBlankString(TypesDescription), "", TypesDescription + Chars.LF) + TypeDescription;

	EndDo;

	Return TypesDescription;

EndFunction // GetTypeDescription()

////////////////////////////////////////////////////////////////////////////////
//

&AtServer
Function mRestoreValue(Name)
	Return FormDataSettingsStorage.Load(DataProcessorID(), Name);
EndFunction

&AtServer
Procedure mSaveValue(Name, Val Value)

	If TypeOf(Value) = Type("FormDataCollection") Then

		Value = FormDataToValue(Value, Type("ValueTable"));

	EndIf;

	FormDataSettingsStorage.Save(DataProcessorID(), Name, Value);

EndProcedure

// Returns setting from saved settings list.
//
// Parameters:
//  SettingsList - ValueList - a list of saved settings.
//
// Return value:
//  Arbitrary - a value of setting. 
//
&AtServer
Function GetDefaultSetting(SettingsList)

	SourceMetadata = GetSourceMetadata();

	If SourceMetadata = Undefined Then
		Return Undefined;
	EndIf;
	//VT = FormAttributeToValue("SavedSettingsList");
	For Each ListRow In SettingsList Do
		If ListRow.Check Then
			Return ListRow.Value;
		EndIf;
	EndDo;
	Return Undefined;

EndFunction // ()

////////////////////////////////////////////////////////////////////////////////
//

// Fills SourceTabularSection form item choice list.
//
&AtServer
Procedure SetTabularSectionsList()

	ChoiceList = Items.SourceTabularSection.ChoiceList;
	ChoiceList.Clear();
	If Object.SourceRef = Undefined Then
		Return;
	EndIf;
	For Each TabularSection In Object.SourceRef.Metadata().TabularSections Do
		ChoiceList.Add(TabularSection.Name, TabularSection.Presentation());
	EndDo;
	If Not IsBlankString(Object.SourceTabularSection) And ChoiceList.FindByValue(Object.SourceTabularSection)
		= Undefined Then
		Object.SourceTabularSection = "";
	EndIf;

EndProcedure // ()

// Generates a structure of columns of imported attributes from ImportedAttributesTable table.
//
&AtServer
Procedure GenerateColumnsStructure()

	ColumnNumber = 1;
	Columns = New Structure;

	VT = FormAttributeToValue("ImportedAttributesTable");

	TempColumns = VT.CopyColumns();
	For Each ImportedAttribute In VT Do
		Column = New Structure;
		For Each ImportedAttributesColumn In TempColumns.Columns Do
			If Not Object.ManualSpreadsheetDocumentColumnsNumeration And ImportedAttributesColumn.Name
				= "ColumnNumber" Then
				If ImportedAttribute.Check Then
					Column.Insert("ColumnNumber", ColumnNumber);
					ColumnNumber = ColumnNumber + 1;
				Else
					Column.Insert("ColumnNumber", 0);
				EndIf;
			Else
				Column.Insert(ImportedAttributesColumn.Name,
					ImportedAttribute[ImportedAttributesColumn.Name]);
			EndIf;

		EndDo;

		Columns.Insert(Column.AttributeName, Column);

	EndDo;

	Object.AdditionalProperties.Insert("Columns", Columns);

EndProcedure // ()

// Generates a spreadsheet document header according to imported attributes table.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - spreadsheet document to generate a header.
//
&AtServer
Procedure GenerateSpreadsheetDocumentHeader(SpreadsheetDocument)

	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 1);

	VT = FormAttributeToValue("ImportedAttributesTable");

	Table = VT.Copy();
	Table.Sort("ColumnNumber");

	Columns = Object.AdditionalProperties.Columns;

	For Each KeyValue In Columns Do
		ImportedAttribute = KeyValue.Value;
		ColumnNumber = ImportedAttribute.ColumnNumber;
		If Not ImportedAttribute.Check Or ColumnNumber = 0 Then
			Continue;
		EndIf;

		If ImportedAttribute.ColumnWidth = 0 Then

			ColumnWidth = 40;
			If ImportedAttribute.TypeDescription.Types().Count() = 1 Then
				FirstType = ImportedAttribute.TypeDescription.Types()[0];
				If FirstType = Type("String") Then
					If ImportedAttribute.TypeDescription.StringQualifiers.Length = 0 Then
						ColumnWidth = 80;
					Else
						ColumnWidth = Min(Max(ImportedAttribute.TypeDescription.StringQualifiers.Length, 10), 80);
					EndIf;
				ElsIf FirstType = Type("Number") Then
					ColumnWidth = Max(ImportedAttribute.TypeDescription.NumberQualifiers.Digits, 10);
				ElsIf FirstType = Type("Boolean") Then
					ColumnWidth = 10;
				EndIf;
			EndIf;
		Else
			ColumnWidth = ImportedAttribute.ColumnWidth;
		EndIf;
		Area = SpreadsheetDocument.Area("R1C" + ColumnNumber);
		HasText = Not IsBlankString(Area.Text);
		Area.Text       = ?(HasText, Area.Text + Chars.LF, "") + ImportedAttribute.AttributePresentation;
		Area.Details = ImportedAttribute.AttributeName;
		Area.BackColor = StyleColors.FormBackColor;
		Area.Outline(Line, Line, Line, Line);

		ColumnArea = SpreadsheetDocument.Area("C" + ColumnNumber);
		ColumnArea.ColumnWidth = ?(HasText, Max(ColumnArea.ColumnWidth, ColumnWidth), ColumnWidth);

	EndDo;

EndProcedure // GenerateSpreadsheetDocumentHeader()

// Returns source metadata.
//
// Return value:
//  Metadata object.
//
&AtServer
Function GetSourceMetadata()

	If Object.ImportMode = 0 Then
		If Not IsBlankString(Object.CatalogObjectType) Then
			Return Metadata.Catalogs.Find(Object.CatalogObjectType);
		EndIf;
	ElsIf Object.ImportMode = 1 Then
		If Not Object.SourceRef = Undefined And Not Object.SourceTabularSection = Undefined Then
			Return Object.SourceRef.Metadata().TabularSections.Find(Object.SourceTabularSection);
		EndIf;
	ElsIf Object.ImportMode = 2 Then
		If Not IsBlankString(Object.RegisterTypeName) Then
			Return Metadata.InformationRegisters.Find(Object.RegisterTypeName);
		EndIf;
	EndIf;

	Return Undefined;

EndFunction // ()

&AtServer
Function SelectedMetadataExists()

	Return Not GetSourceMetadata() = Undefined;

EndFunction // SelectedMetadataExists()

&AtServer
Function GetSourceQuestionText()

	SourceMetadata = GetSourceMetadata();

	Error = "";
	SourceQuestionText = "";

	If Object.ImportMode = 0 Then
		SourceQuestionText = UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'элементов в справочник: ""%1""'; en = 'Import items into %1 catalog'"), SourceMetadata.Presentation());

	ElsIf Object.ImportMode = 1 Then

		If Object.SourceRef.IsEmpty() Then
			Error = NStr("ru = 'Не выбрана ссылка'; en = 'Reference not selected.'");
		Else
			SourceObject = Object.SourceRef.GetObject();
			SourceQuestionText = UT_StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'строк в табличную часть: ""%1""'; en = 'Import rows into %1 tabular section'"), SourceMetadata.Presentation());
		EndIf;

	ElsIf Object.ImportMode = 2 Then

		SourceQuestionText = UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'записей в регистр сведений: ""%1""'; en = 'Import records into %1 information register'"), SourceMetadata.Представление());

	EndIf;

	Return New Structure("Error, QuestionText", Error, SourceQuestionText);

EndFunction

&AtServer
Function ImportDataServer()

	WriteObject = True;
	FolderCreationEnabled = False;

	GenerateColumnsStructure();

	SourceMetadata = GetSourceMetadata();

	Columns = Object.AdditionalProperties.Колонки;

	If Object.ImportMode = 0 Then
		Source = Catalogs[Object.CatalogObjectType].EmptyRef();
	ElsIf Object.ImportMode = 1 Then
		SourceObject = Object.SourceRef.GetObject();
		Source = SourceObject[Object.SourceTabularSection];
	EndIf;

	SourceQuestionText = GetSourceQuestionText().QuestionText;
	ItemsCount = SpreadsheetDocument.TableHeight - Object.SpreadsheetDocumentFirstDataRow + 1;

	Query = Undefined;
	If Object.ImportMode = 0 Then

		FolderCreationEnabled = FolderCreationEnabled(SourceMetadata);
		SearchRows = ImportedAttributesTable.FindRows(New Structure("SearchField,Check", True, True));
		If Not SearchRows.Count() = 0 Then

			QueryText = "Select Top 1
						   |Catalog.Ref AS Ref
						   |From Catalog." + SourceMetadata.Name + " AS Catalog
																		|Where";

			For Each SearchRow In SearchRows Do
				QueryText = QueryText + "
											  |Catalog." + SearchRow.AttributeName + " = &"
					+ SearchRow.AttributeName + "
												  |AND";

			EndDo;

			QueryText = Left(QueryText, StrLen(QueryText) - 2);
			Query = New Query(QueryText);
		EndIf;
	ElsIf Object.ImportMode = 1 Then

		Source.Clear();
	ElsIf Object.ImportMode = 2 Then

		RegisterDimensions = New Structure;
		For Each Column In Columns Do
			If Column.Value.PossibleSearchField Then
				RegisterDimensions.Insert(Column.Key, Column.Value);
			EndIf;
		EndDo;
	EndIf;
	Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выполняется загрузка %1'; en = '%1 is in progress.'"), SourceQuestionText),
	MessageStatus.Information);
	Message(NStr("ru = 'Всего: '; en = 'Total: '") + ItemsCount, MessageStatus.Information);
	Message("---------------------------------------------", MessageStatus.WithoutStatus);
	CurrentRowNumber = 0;
	Imported = 0;
	For K = Object.SpreadsheetDocumentFirstDataRow To SpreadsheetDocument.TableHeight Do
		CurrentRowNumber = CurrentRowNumber + 1;
		CellsTexts = Undefined;
		Cancel = False;
		CurrentRow = RowFillControl(SpreadsheetDocument, K, CellsTexts);
		If Object.ImportMode = 0 Then

			ImportedObject = Undefined;
			If Not Query = Undefined Then
				ErrorString = "";
				For Each SearchRow In SearchRows Do

					AttributeValue = Undefined;

					CurrentRow.Property(SearchRow.AttributeName, AttributeValue);
					If IsBlankString(AttributeValue) Then
						ErrorString = ?(IsBlankString(ErrorString), "", ErrorString + ", ")
							+ SearchRow.AttributePresentation;
					Else
						Query.SetParameter(SearchRow.AttributeName, CurrentRow[SearchRow.AttributeName]);
					EndIf;

				EndDo;

				If Not IsBlankString(ErrorString) Then
					Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Строка %1 не может быть записана. Не указано значение ключевых реквизитов: %2';
							 |en = 'Unable to write row %1. Key attributes %2 are not defined.'"), CurrentRowNumber, ErrorString),
						MessageStatus.Important);
					Continue;
				EndIf;

				Selection = Query.Execute().Select();
				If Selection.Next() Then
					ImportedObject = Selection.Ref.GetObject();
				EndIf;

			EndIf;

			ObjectFound = Not ImportedObject = Undefined;
			If Not ObjectFound Then
				If Object.DontCreateNewItems Then
					Continue;
				ElsIf FolderCreationEnabled And CurrentRow.IsFolder Then
					ImportedObject = Catalogs[SourceMetadata.Name].CreateFolder();
				Else
					ImportedObject = Catalogs[SourceMetadata.Name].CreateItem();
				EndIf;

			EndIf;
		ElsIf Object.ImportMode = 1 Then
			ImportedObject = Source.Add();
			ObjectFound = False;
		ElsIf Object.ImportMode = 2 Then
			ImportedObject = InformationRegisters[SourceMetadata.Name].CreateRecordManager();
			For Each KeyValue In CurrentRow Do

				If RegisterDimensions.Property(KeyValue.Key) Then
					ImportedObject[KeyValue.Key] = KeyValue.Value;
				EndIf;

			EndDo;

			If Not Object.ReplaceExistingRecords Then
				ImportedObject.Read();
				ObjectFound = ImportedObject.Selected();
			Else
				ObjectFound = False;
			EndIf;

		EndIf;

		For Each KeyValue In CurrentRow Do
			
			If KeyValue.Key = "IsFolder" Then
				Continue;	
			EndIf; 

			If Not ObjectFound Or Columns[KeyValue.Key].Check Then
				Try
					ImportedObject[KeyValue.Key] = KeyValue.Value;
				Except
					mErrorMessage(UT_StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка при установке значения реквизита ""%1""'; en = '%1 attribute value setting error.'") + ErrorDescription(), KeyValue.Key));
					Cancel = True;
					Break;
				EndTry;
			EndIf;

		EndDo;

		If Object.ImportMode = 0 Then
			If Not Cancel And WriteObject(ImportedObject, CellsTexts, Object.BeforeWriteObject,
				Object.OnWriteObject) Then
				Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '%1 %2 справочника: %3'; en = 'Catalog %2 %3 was %1.'"),
						?(ObjectFound, NStr("ru = 'Изменен'; en = 'changed'"), NStr("ru = 'Загружен'; en = 'imported'")),
						?(ImportedObject.IsFolder, NStr("ru = 'группа'; en = 'folder'"), NStr("ru = 'элемент'; en = 'item'")),
						ImportedObject.Ref), 
					MessageStatus.Information);
				Imported = Imported + 1;
			Else
				Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Объект не %1. %2 справочника: %3'; en = 'Object was not %1. Catalog %2 %3.'"),
						?(ObjectFound, NStr("ru = 'изменен'; en = 'changed'"), NStr("ru = 'загружен'; en = 'imported'")),
						?(ImportedObject.IsFolder, NStr("ru = 'Группа'; en = 'folder'"), NStr("ru = 'Элемент'; en = 'item'")),
						ImportedObject),
					MessageStatus.Important);
			EndIf;
		ElsIf Object.ImportMode = 1 Then

			If Not AfterAddRowEventHandler(SourceObject, ImportedObject, CellsTexts,
				Object.AfterAddRow) Then
				Cancel = True;
			EndIf;

			If Not Cancel Then
				Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Добавлена строка: %1; 'Row %1 added.'"), (Imported + 1)));
			Else
				Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'При добавлении строки %1 возникли ошибки.'; en = 'An error occured while adding row %1.'"), (Imported + 1)));
				WriteObject = False;
			EndIf;

			Imported = Imported + 1;

		ElsIf Object.ImportMode = 2 Then
			If Not Cancel And WriteObject(ImportedObject, CellsTexts, Object.BeforeWriteObject,
				Object.OnWriteObject) Then
				Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '%1 запись № %2.'; en = 'Record %2 was %1.'"),
					?(ObjectFound, NStr("ru = 'Изменена'; en = 'changed'"), NStr("ru = 'Добавлена'; en = 'added'")), CurrentRowNumber));
				Imported = Imported + 1;
			Else
				Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Запись не %1. № записи: %2.'; en = 'Record was not %1. Record no. %2.'"),
					?(ObjectFound, NStr("ru = 'изменена'; en = 'changed'"), NStr("ru = 'загружена'; en = 'imported'")), CurrentRowNumber), 
				MessageStatus.Important);
			EndIf;
		EndIf;

	EndDo;
	Message("---------------------------------------------", MessageStatus.WithoutStatus);

	If Object.ImportMode = 1 Then
		If WriteObject And WriteObject(SourceObject, "", Object.BeforeWriteObject,
			Object.OnWriteObject) Then

			Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Выполнена загрузка %1'; en = '%1 was executed'"), SourceQuestionText), 
			MessageStatus.Information);
			Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 из %2 элементов.'; en = '%1 out of %2 items.'"), Imported, ItemsCount), 
			MessageStatus.Information);
			Return True;
		Else
			Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Объект не записан: %1.'; en = 'Object %1 was not written.'"), ImportedObject),
			MessageStatus.Important);
			Return False;
		EndIf;
	ElsIf Object.ImportMode = 0 Then
		Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выполнена загрузка %1'; en = '%1 was executed'"), SourceQuestionText), 
		MessageStatus.Information);
		Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1 из %2 элементов.'; en = '%1 out of %2 items.'"), Imported, ItemsCount), 
		MessageStatus.Information);
		Return True;
	ElsIf Object.ImportMode = 2 Then
		Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выполнена загрузка %1'; en = '%1 was executed'"), SourceQuestionText), 
		MessageStatus.Information);
		Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1 из %2 записей.'; en = '%1 out of %2 records.'"), Imported, ItemsCount), 
		MessageStatus.Information);
		Return True;
	EndIf;

EndFunction

// Function определяет возможность создания группы для переданного метаданного
//
// Параметры:
//  МетаданныеИсточника - Метаданные - Метаданные загружаемого объекта
//
// Возвращаемое значение:
//  Булево - признак возможности создания группы
//
&AtServer
Function FolderCreationEnabled(Знач МетаданныеИсточника)
	
	Return МетаданныеИсточника.Иерархический 
			И МетаданныеИсточника.ВидИерархии = Метаданные.СвойстваОбъектов.ВидИерархии.ИерархияГруппИЭлементов;

EndFunction // ()

// Function вычисляет значение ячейки для режима "Вычислять"
//
// Параметры:
//  Expression - програмный код, который необходимо выполнить
//  ТекущиеДанные  - структура загруженных значений
//  ТекстЯчейки    - текст текущей ячейки
//  ТекстыЯчеек    - массив текстов ячеек строки
//  Результат      - результат вычисления
//
// Возвращаемое значение:
//  Структура, сордержащая Результат и ОписаниеОшибки
&AtServerБезКонтекста
Function ВычислитьЗначениеЯчейки(Знач Выражение, Знач ТекущиеДанные, Знач ТекстЯчейки, Знач ТекстыЯчеек, Знач Результат)

	ТекстЯчейки = СокрЛП(ТекстЯчейки);
	ОписаниеОшибки = "";
	Try
		Выполнить (Выражение);
	Except
		mErrorMessage(ОписаниеОшибки());
	EndTry;

	Return Новый Структура("Результат,ОписаниеОшибки", Результат, ОписаниеОшибки);

EndFunction // ВычислитьЗначениеЯчейки(ТекущаяСтрока,Представление)()

// Function записывает объект в информационную базу данных, используя
// события определенные пользователем в форме редактирования событий
//
// Параметры:
//  Объект      - записываемый объект
//  ТекстыЯчеек - массив текстов ячеек, загружаемой строки
//
// Возвращаемое значение:
//  True, If объект записан, False - Else
//
&AtServerNoContext
Function WriteObject(Объект, ТекстыЯчеек = Undefined, ПередЗаписьюОбъекта, ПриЗаписиОбъекта)

	Отказ = False;
	НачатьТранзакцию();
	If Не IsBlankString(ПередЗаписьюОбъекта) Then
		Try
			Выполнить (ПередЗаписьюОбъекта);
			If Отказ Then
				ОписаниеОшибки = "";//Установлен отказ перед записью объекта
			EndIf;
		Except
			Отказ = True;
			ОписаниеОшибки = ОписаниеОшибки();
		EndTry;
	EndIf;

	If Не Отказ Then
		Try
			Объект.Записать();
		Except
			Отказ = True;
			ОписаниеОшибки = ОписаниеОшибки();
		EndTry;
	EndIf;

	If Не Отказ И Не IsBlankString(ПриЗаписиОбъекта) Then

		Try
			Выполнить (ПриЗаписиОбъекта);
			If Отказ Then
				ОписаниеОшибки = "";//Установлен отказ при записи объекта
			EndIf;

		Except
			Отказ = True;
			ОписаниеОшибки = ОписаниеОшибки();
		EndTry;

		If Не Отказ Then
			Try
				Объект.Записать();
			Except
				Отказ = True;
				ОписаниеОшибки = ОписаниеОшибки();
			EndTry;
		EndIf;

	EndIf;

	If Не Отказ Then
		ЗафиксироватьТранзакцию();
	Else
		mErrorMessage(ОписаниеОшибки);
		ОтменитьТранзакцию();
	EndIf;

	Return Не Отказ;

EndFunction // ()

// Function обрабатывает событие "После добавления строки",
// определенное пользователем в форме редактирования событий
//
// Параметры:
//  Объект      - записываемый объект
//  ТекущиеДанные  - структура загруженных значений
//  ТекстыЯчеек    - массив текстов ячеек строки
//
// Возвращаемое значение:
//  True, If в событие "После добавления строки" не был установлен Отказ, False - Else
//
&AtServerNoContext
Function AfterAddRowEventHandler(Объект, ТекущиеДанные, ТекстыЯчеек, ПослеДобавленияСтроки)

	Try

		Выполнить (ПослеДобавленияСтроки);

	Except

		mErrorMessage(ОписаниеОшибки());
		Return False;

	EndTry;

	Return True;

EndFunction // ()

////////////////////////////////////////////////////////////////////////////////
//

// Procedure выполняет контроль заполнения данных табличного документа
// сообщает об ошибках и устанавливает коментарии к ошибочным ячейкам
//
// Параметры:
//  SpreadsheetDocument - SpreadsheetDocument, у которого необходимо сформировать шапку
//  Индикатор         - Элемент управления индикатор, в котором необходимо отображать процент выполнения операции
//
&AtServer
Procedure КонтрольЗаполнения(ТабличныйДокумент) Export

	КоличествоЭлементов = ТабличныйДокумент.ВысотаТаблицы - Object.SpreadsheetDocumentFirstDataRow + 1;

	КоличествоОшибок = 0;
	Для К = 0 По КоличествоЭлементов - 1 Do
		//Состояние("Выполняется контроль заполнения строки № " + (К + 1));
		RowFillControl(ТабличныйДокумент, К + Object.SpreadsheetDocumentFirstDataRow, ,
			КоличествоОшибок);
	EndDo;

	Сообщить("Контроль заполнения завершен. Проверено строк: " + КоличествоЭлементов);
	If КоличествоОшибок Then
		Сообщить("Выявлено ячеек, содержащих ошибки/неоднозначное представление: " + КоличествоОшибок);
	Else
		Сообщить("Ячеек, содержащих ошибки не выявлено");
	EndIf;

EndProcedure // FillControl()

// Function выполняет контроль заполнения строки данных табличного документа
// сообщает об ошибках и устанавливает коментарии к ошибочным ячейкам
//
// Параметры:
//  SpreadsheetDocument - SpreadsheetDocument, у которого необходимо сформировать шапку
//  НомерСтроки       - Число, номер строки табличного документа
//  ТекстыЯчеек    - возвращает массив текстов ячеек строки,
//
// Возвращаемое значение:
//  структура, ключ - Имя загружаемого реквизита, Значение - Значение загружаемого реквизита
//
&AtServer
Function RowFillControl(ТабличныйДокумент, НомерСтроки, ТекстыЯчеек = Undefined, КоличествоОшибок = 0)

	ТекстыЯчеек = Новый Массив;
	ТекстыЯчеек.Добавить(Undefined);
	Для к = 1 По ТабличныйДокумент.ШиринаТаблицы Do
		ТекстыЯчеек.Добавить(СокрЛП(ТабличныйДокумент.Область("R" + Формат(НомерСтроки, "ЧГ=") + "C" + Формат(К,
			"ЧГ=")).Текст));
	EndDo;

	Колонки = Object.AdditionalProperties.Колонки;

	ТекущаяСтрока     = Новый Структура;
	For Each КлючИЗначение Из Колонки Do

		Колонка = КлючИЗначение.Значение;

		If Колонка.Check Then

			If Колонка.ImportMode = "Устанавливать" Then

				Результат = Колонка.DefaultValue;
				ТекущаяСтрока.Вставить(Колонка.ИмяРеквизита, Результат);

			ElsIf Не Колонка.ColumnNumber = 0 Then

				If Не ОбработатьОбласть(ТабличныйДокумент.Область("R" + Формат(НомерСтроки, "ЧГ=") + "C" + Формат(
					Колонка.НомерКолонки, "ЧГ=")), Колонка, ТекущаяСтрока, ТекстыЯчеек) Then
					КоличествоОшибок = КоличествоОшибок + 1;
				EndIf;

			ElsIf Колонка.ImportMode = "Вычислять" Then

				Вычисление  = ВычислитьЗначениеЯчейки(Колонка.Выражение, ТекущаяСтрока, "", ТекстыЯчеек,
					Колонка.ЗначениеПоУмолчанию);
				Результат   = Вычисление.Результат;
				Примечание  = Вычисление.ОписаниеОшибки;

				If Не ValueIsFilled(Результат) Then
					Результат = Колонка.DefaultValue;
				EndIf;

				ТекущаяСтрока.Вставить(Колонка.ИмяРеквизита, Результат);

				If Не IsBlankString(Примечание) Then
					Сообщить("Строка [" + НомерСтроки + "](" + Колонка.AttributePresentation + "): " + Примечание);
					КоличествоОшибок = КоличествоОшибок + 1;
				EndIf;

			EndIf;

		EndIf;

	EndDo;
	Return ТекущаяСтрока;

EndFunction

// Procedure выполняет обработку области табличного документа:
// заполняет расшифровку по представлению ячейки в соответствии со структурой загружаемых реквизитов
// сообщает об ошибке и устанавливает коментарий, If ячейка содержит ошибку
//
// Параметры:
//  Область - область табличного документа
//  Колонка - Структура, свойства, в соответствии с которыми необходимо выполнить обработку области
//  ТекущиеДанные  - структура загруженных значений
//  ТекстыЯчеек    - массив текстов ячеек строки
//
&AtServer
Function ОбработатьОбласть(Область, Колонка, ТекущиеДанные, ТекстыЯчеек)

	Представление = Область.Текст;
	Примечание = "";

	If Колонка.ImportMode = "Вычислять" Then

		Вычисление = ВычислитьЗначениеЯчейки(Колонка.Выражение, ТекущиеДанные, Представление, ТекстыЯчеек,
			Колонка.ЗначениеПоУмолчанию);
		If Не IsBlankString(Вычисление.ОписаниеОшибки) Then
			Результат   = Undefined;
			Примечание = "" + Вычисление.ОписаниеОшибки;
		Else
			Результат = Вычисление.Результат;
		EndIf;

	ElsIf IsBlankString(Представление) Then
		Результат = Undefined;
	Else
		НайденныеЗначения = ПолучитьВозможныеЗначения(Колонка, Представление, Примечание, ТекущиеДанные);

		If НайденныеЗначения.Количество() = 0 Then

			Примечание = "Не найден" + ?(Примечание = "", "", Символы.ПС + Примечание);
			Результат = Undefined;

		ElsIf НайденныеЗначения.Количество() = 1 Then

			Результат = НайденныеЗначения[0];
		Else

			Примечание = "Не однозначное представление. Вариантов: " + НайденныеЗначения.Количество() + ?(Примечание
				= "", "", Символы.ПС + Примечание);

			Нашли = False;
			НашлиЗначениеПоУмолчанию = False;
			For Each НайденноеЗначение Из НайденныеЗначения Do
				If НайденноеЗначение = Область.Расшифровка Then
					Нашли = True;
					Прервать;
				EndIf;
				If НайденноеЗначение = Колонка.DefaultValue Then
					НашлиЗначениеПоУмолчанию = True;
				EndIf;
			EndDo;

			If Не Нашли Then

				If НашлиЗначениеПоУмолчанию Then
					НайденноеЗначение = Колонка.DefaultValue;
				Else
					НайденноеЗначение = НайденныеЗначения[0];
				EndIf;
			EndIf;
			Результат = НайденноеЗначение;
		EndIf;
	EndIf;

	If Не ValueIsFilled(Результат) Then
		Результат = Колонка.DefaultValue;
	EndIf;

	ТекущиеДанные.Вставить(Колонка.ИмяРеквизита, Результат);

	Область.Расшифровка = Результат;
	Область.Примечание.Текст = Примечание;

	If Не IsBlankString(Примечание) Then
		Сообщить("Ячейка[" + Область.Имя + "](" + Колонка.AttributePresentation + "): " + Примечание);
	EndIf;

	Return IsBlankString(Примечание);

EndFunction

// Function возвращает массив возможных значений для текущей колонки по представлению
//
// Параметры:
//  Колонка - Структура, свойства, в соответствии с которыми необходимо получить возможные значения
//  Представление - Строка, по которой необходимо вернуть массив значений
//  Примечание    - массив текстов ячеек строки
//  ТекущиеДанные  - структура загруженных значений
//
// Возвращаемое значение:
//  массив возможных значений
//
&AtServer
Function ПолучитьВозможныеЗначения(Колонка, Представление, Примечание, ТекущиеДанные)
	Примечание = "";

	НайденныеЗначения = Новый Массив;

	If IsBlankString(Представление) Then

		Return НайденныеЗначения;

	Else
		СвязьПоТипу = Undefined;
		If Не IsBlankString(Колонка.СвязьПоТипу) Then

			If ТипЗНЧ(Колонка.СвязьПоТипу) = Тип("Строка") Then
				ТекущиеДанные.Свойство(Колонка.СвязьПоТипу, СвязьПоТипу);
			Else
				СвязьПоТипу = Колонка.LinkByType;
			EndIf;
			If Не СвязьПоТипу = Undefined Then

				ЭлементСвязиПоТипу = Колонка.LinkByTypeItem;
				If ЭлементСвязиПоТипу = 0 Then
					ЭлементСвязиПоТипу = 1;
				EndIf;
				ВидыСубконто = СвязьПоТипу.ВидыСубконто;
				If ЭлементСвязиПоТипу > ВидыСубконто.Количество() Then
					Return НайденныеЗначения;
				EndIf;
				Тип = СвязьПоТипу.ВидыСубконто[ЭлементСвязиПоТипу - 1].ВидСубконто.ТипЗначения;
			Else
				Тип = Колонка.TypeDescription;
			EndIf;

		Else
			Тип = Колонка.TypeDescription;
		EndIf;
	EndIf;
	ПримитивныеТипы = Новый Структура("Число, Строка, Дата, Булево", Тип("Число"), Тип("Строка"), Тип("Дата"), Тип(
		"Булево"));
	For Each ТипРеквизита Из Тип.Типы() Do

		If ТипРеквизита = ПримитивныеТипы.Число Или ТипРеквизита = ПримитивныеТипы.Булево Then
			НайденныеЗначения.Добавить(mAdjustToNumber(Представление, Колонка.ОписаниеТипов, Примечание));
		ElsIf ТипРеквизита = ПримитивныеТипы.Строка Или ТипРеквизита = ПримитивныеТипы.Дата Then
			НайденныеЗначения.Добавить(mAdjustToDate(Представление, Колонка.ОписаниеТипов, Примечание));

		Else

			МетаданныеТипа = Метаданные.НайтиПоТипу(ТипРеквизита);

			If Перечисления.ТипВсеСсылки().СодержитТип(ТипРеквизита) Then
				
				//Это Перечисление
				For Each Перечисление Из GetManagerByType(ТипРеквизита) Do
					If Строка(Перечисление) = Представление Then
						НайденныеЗначения.Добавить(Перечисление);
					EndIf;
				EndDo;

			ElsIf Документы.ТипВсеСсылки().СодержитТип(ТипРеквизита) Then
				
				//Это документ

				Менеджер = GetManagerByType(ТипРеквизита);
				If Колонка.SearchBy = "Номер" Then
					//НайденноеЗначение = Менеджер.НайтиПоКоду(Представление);
				ElsIf Колонка.SearchBy = "Дата" Then
					//НайденноеЗначение = Менеджер.Найти
				Else

					ДлиннаСинонима = StrLen("" + МетаданныеТипа);

					If Лев(Представление, ДлиннаСинонима) = "" + МетаданныеТипа Then
						НомерИДата = СокрЛП(Сред(Представление, ДлиннаСинонима + 1));
						ПозицияОт = Найти(НомерИДата, " от ");
						If Не ПозицияОт = 0 Then
							НомерДок = Лев(НомерИДата, ПозицияОт - 1);
							Try
								ДатаДок  = Дата(Сред(НомерИДата, ПозицияОт + 4));
							Except
								ДатаДок = Undefined;
							EndTry;
							If Не ДатаДок = Undefined Then
								НайденноеЗначение = Менеджер.НайтиПоНомеру(НомерДок, ДатаДок);
								If Не НайденноеЗначение.Пустая() Then
									НайденныеЗначения.Добавить(НайденноеЗначение);
								EndIf;
							EndIf;
						EndIf;
					EndIf;

				EndIf;

			ElsIf Не МетаданныеТипа = Undefined Then

				ИскатьПо = Колонка.SearchBy;
				ЭтоСправочник = Справочники.ТипВсеСсылки().СодержитТип(ТипРеквизита);
				If IsBlankString(ИскатьПо) Then
					СтрокаОсновногоПредставления = Строка(МетаданныеТипа.ОсновноеПредставление);

					If СтрокаОсновногоПредставления = "ВВидеКода" Then
						ИскатьПо = "Код";
					ElsIf СтрокаОсновногоПредставления = "ВВидеНаименования" Then
						ИскатьПо = "Наименование";
					ElsIf СтрокаОсновногоПредставления = "ВВидеНомера" Then
						ИскатьПо = "Номер";
					EndIf;
				EndIf;
				Запрос = Новый Запрос;
				Запрос.Текст = "ВЫБРАТЬ
							   |	_Таблица.Ссылка
							   |ИЗ
							   |	" + МетаданныеТипа.ПолноеИмя() + " КАК _Таблица
																	 |ГДЕ";

				Запрос.Текст = Запрос.Текст + "
											  |	_Таблица." + ИскатьПо + " = &Представление";
				Запрос.УстановитьПараметр("Представление", Представление);

				If ЭтоСправочник И Не IsBlankString(Колонка.СвязьПоВладельцу) И МетаданныеТипа.Владельцы.Количество() Then

					СвязьПоВладельцу = Undefined;
					If ТипЗНЧ(Колонка.СвязьПоВладельцу) = Тип("Строка") Then
						ТекущиеДанные.Свойство(Колонка.СвязьПоВладельцу, СвязьПоВладельцу);
					Else
						СвязьПоВладельцу = Колонка.LinkByOwner;
					EndIf;

					If Не СвязьПоВладельцу = Undefined Then
						Запрос.Текст = Запрос.Текст + "
													  |	И _Таблица.Владелец = &LinkByOwner";
						Запрос.УстановитьПараметр("LinkByOwner", СвязьПоВладельцу);
					EndIf;

				EndIf;

				Выборка =  Запрос.Выполнить().Выбрать();

				Пока Выборка.Следующий() Do
					НайденныеЗначения.Добавить(Выборка.Ссылка);
				EndDo;
			Else
				Примечание = "Не описан способ поиска";
				Примечание = "Для Колонки не определен тип значения";
			EndIf;
		EndIf;

	EndDo;
	Return НайденныеЗначения;
EndFunction // ()

////////////////////////////////////////////////////////////////////////////////
//

// Function возвращает массив, элементами которого выступают возможные имена представления загружаемого реквизита
//
// Параметры:
//  ЗагружаемыйРеквизит - Строка таблицы значений загружаемого реквизита
//
// Возвращаемое значение:
//  список значений; значение списка - строка имя представления
//
&AtServer
Function ПолучитьСписокИменПредставлений(ОписаниеТипов)

	СписокВыбора = Новый СписокЗначений;
	If ОписаниеТипов.Типы().Количество() = 1 Then

		Тип = ОписаниеТипов.Типы()[0];

		МетаданныеТипа      = Метаданные.НайтиПоТипу(Тип);
		ЭтоСправочник       = Справочники.ТипВсеСсылки().СодержитТип(Тип);
		ЭтоСчет             = ПланыСчетов.ТипВсеСсылки().СодержитТип(Тип);
		ЭтоВидХарактеристик = ПланыВидовХарактеристик.ТипВсеСсылки().СодержитТип(Тип);
		If ЭтоСправочник Или ЭтоСчет Или ЭтоВидХарактеристик Then

			ЕстьКод = МетаданныеТипа.ДлинаКода > 0;
			ЕстьИмя = МетаданныеТипа.ДлинаНаименования > 0;

			ВидОсновногоПредставление = ?(ЭтоСправочник, Метаданные.СвойстваОбъектов.ОсновноеПредставлениеСправочника,
				?(ЭтоСчет, Метаданные.СвойстваОбъектов.ОсновноеПредставлениеСчета,
				Метаданные.СвойстваОбъектов.ОсновноеПредставлениеВидаХарактеристики));

			If МетаданныеТипа.ОсновноеПредставление = ВидОсновногоПредставление.ВВидеКода Then

				If ЕстьКод Then
					СписокВыбора.Добавить("Код", "Код");
				EndIf;

				If ЕстьИмя Then
					СписокВыбора.Добавить("Наименование", "Наименование");
				EndIf;

			Else

				If ЕстьИмя Then
					СписокВыбора.Добавить("Наименование", "Наименование");
				EndIf;

				If ЕстьКод Then
					СписокВыбора.Добавить("Код", "Код");
				EndIf;

			EndIf;

			For Each Реквизит Из МетаданныеТипа.Реквизиты Do

				If Не Реквизит.Индексирование = Метаданные.СвойстваОбъектов.Индексирование.НеИндексировать
					И Реквизит.Тип.Типы().Количество() = 1 И Реквизит.Тип.Типы()[0] = Тип("Строка") Then

					СписокВыбора.Добавить(Реквизит.Имя, Реквизит.Представление());

				EndIf;

			EndDo;
		Else
		
		EndIf;

	EndIf;
	Return СписокВыбора;
EndFunction // ()

// Function возвращает список, элементами которого выступают возможные связи по типу для загружаемого реквизита
//
// Параметры:
//  ЗагружаемыйРеквизит - Строка таблицы значений загружаемого реквизита
//
// Возвращаемое значение:
//  список значений; значение списка - строка имя колонки связи или ссылка на элемент связи
//
&AtServer
Function ПолучитьСписокСвязейПоТипу(ЗагружаемыйРеквизит, ТЗ)

	СписокВыбора = Новый СписокЗначений;

	ВозможныеПланыСчетов = Новый Структура;
	For Each ПланСчетов Из Метаданные.ПланыСчетов Do
		Try
			If ПланСчетов.ВидыСубконто.Тип = ЗагружаемыйРеквизит.TypeDescription Then

				ВозможныеПланыСчетов.Вставить(ПланСчетов.Имя, ПланыСчетов[ПланСчетов.Имя]);

			EndIf;
		Except

		EndTry;
	EndDo;

	For Each ПланСчетов Из ВозможныеПланыСчетов Do
		ТипЗНЧПланСчетов = ТипЗНЧ(ПланСчетов.Значение.ПустаяСсылка());
		For Each КолонкаСвязиПоТипу Из ТЗ Do
			If КолонкаСвязиПоТипу.TypeDescription.Типы()[0] = ТипЗНЧПланСчетов Then
				СписокВыбора.Добавить(КолонкаСвязиПоТипу.ИмяРеквизита, КолонкаСвязиПоТипу.ИмяРеквизита);
			EndIf;
		EndDo;
	EndDo;

	If Не ВозможныеПланыСчетов.Количество() = 0 Then
		СписокВыбора.Добавить(Undefined, "< пустое значение >");
	EndIf;

	For Each ПланСчетов Из ВозможныеПланыСчетов Do
		СписокВыбора.Добавить("ПланСчетовСсылка." + ПланСчетов.Ключ, "<" + ПланСчетов.Ключ + ">");
	EndDo;

	Return СписокВыбора;
EndFunction // ()

// Function возвращает список, элементами которого выступают возможные связи по владельцу для загружаемого реквизита
//
// Параметры:
//  ЗагружаемыйРеквизит - Строка таблицы значений загружаемого реквизита
//
// Возвращаемое значение:
//  список значений; значение списка - строка имя колонки связи или ссылка на элемент связи
//
&AtServer
Function ПолучитьСписокСвязейПоВладельцу(ОписаниеТипов, ТаблицаКолонок)

	ЕстьТипСамогоОбъекта = False;
	МетаданныеИсточника = GetSourceMetadata();
	If Object.ImportMode = 0 Then
		ОписаниеТиповСправочника = Тип(СтрЗаменить(МетаданныеИсточника.ПолноеИмя(), ".", "Ссылка."));
	Else
		ОписаниеТиповСправочника = Undefined;
	EndIf;

	СписокВыбора = Новый СписокЗначений;
	ТипыВладельцев = Новый Соответствие;
	For Each ТипКолонки Из ОписаниеТипов.Типы() Do
		If Справочники.ТипВсеСсылки().СодержитТип(ТипКолонки) Then
			For Each Владелец Из Метаданные.НайтиПоТипу(ТипКолонки).Владельцы Do
				ТипВладельца   = Тип(СтрЗаменить(Владелец.ПолноеИмя(), ".", "Ссылка."));
				If ТипыВладельцев[ТипВладельца] = Undefined Then

					If ТипВладельца = ОписаниеТиповСправочника Then

						ЕстьТипСамогоОбъекта = True;

					EndIf;

					ТипыВладельцев.Вставить(Владелец.ПолноеИмя(), Владелец.ПолноеИмя());
					For Each КолонкаСвязиПоВладельцу Из ТаблицаКолонок Do
						If КолонкаСвязиПоВладельцу.TypeDescription.Типы()[0] = ТипВладельца
							И СписокВыбора.FindByValue(КолонкаСвязиПоВладельцу.ИмяРеквизита) = Undefined Then
							// Возможно надо будет по всем типам проходить
							СписокВыбора.Добавить(КолонкаСвязиПоВладельцу.ИмяРеквизита,
								КолонкаСвязиПоВладельцу.ИмяРеквизита);
						EndIf;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndDo;

	If Не ТипыВладельцев.Количество() = 0 Then
		СписокВыбора.Добавить(Undefined, "< пустое значение >");
	EndIf;
	For Each КлючИЗначение Из ТипыВладельцев Do
		СписокВыбора.Добавить(КлючИЗначение.Значение, "<" + КлючИЗначение.Значение + ">");
	EndDo;

	If ЕстьТипСамогоОбъекта Then

		СписокВыбора.Вставить(0, "<Создаваемый объект>", "<Создаваемый объект>");

	EndIf;

	Return СписокВыбора;

EndFunction // ()

// Возвращает список выбора, закэшированный в таблице значений для реквизита
//
// Параметры
//  AttributeName  - Строка - Имя реквизита, для которого нужно
//		получить связанный список выбора
//
// Возвращаемое значение:
//   СписокЗначений - список значений для выбора для этого реквизита
//
&AtServer
Function ПолучитьСписокВыбораСвязиПоВладельцу(ИмяРеквизита)

	ТЗ = FormAttributeToValue("СпискиВыбораСвязиПоВладельцу");
	Стр = ТЗ.Найти(ИмяРеквизита, "AttributeName");

	Return Стр.СписокВыбора;

EndFunction // ПолучитьСписокВыбораСвязиПоВладельцу()

// Сохраняет в кэше список выбора для реквизита
//
// Параметры
//  AttributeName  - Строка - Имя реквизита, для которого нужно
//		сохранить связанный список выбора
//  НовыйСписокВыбора  - СписокЗначений - сохраняемый список значений
//
&AtServer
Procedure СохранитьСписокВыбораСвязиПоВладельцу(ИмяРеквизита, Знач НовыйСписокВыбора)

	ТЗ = FormAttributeToValue("СпискиВыбораСвязиПоВладельцу");
	Стр = ТЗ.Найти(ИмяРеквизита, "AttributeName");
	Стр.СписокВыбора = НовыйСписокВыбора;
	ЗначениеВРеквизитФормы(ТЗ, "СпискиВыбораСвязиПоВладельцу");

EndProcedure // СохранитьСписокВыбораСвязиПоВладельцу()

&AtServer
Procedure КонтрольЗаполненияСервер()

	GenerateColumnsStructure();
	КоличествоЭлементов = SpreadsheetDocument.ВысотаТаблицы - Object.SpreadsheetDocumentFirstDataRow + 1;

	КоличествоОшибок = 0;
	Для К = 0 По КоличествоЭлементов - 1 Do
		//Состояние("Выполняется контроль заполнения строки № " + (К + 1));
		RowFillControl(SpreadsheetDocument, К + Object.SpreadsheetDocumentFirstDataRow, ,
			КоличествоОшибок);
	EndDo;

	Сообщить("Контроль заполнения завершен. Проверено строк: " + КоличествоЭлементов);
	If КоличествоОшибок Then
		Сообщить("Выявлено ячеек, содержащих ошибки/неоднозначное представление: " + КоличествоОшибок);
	Else
		Сообщить("Ячеек, содержащих ошибки не выявлено");
	EndIf;

EndProcedure // КонтрольЗаполненияСервер()

////////////////////////////////////////////////////////////////////////////////
//

// Заполняет настройки колонок по умолчанию или по переданным настройкам
//
// Параметры:
//  Настройки - табличный документ или Undefined
//
&AtServer
Procedure ЗаполнитьНастройкиКолонок(Настройки)

	ПередЗаписьюОбъекта   = "";
	ПриЗаписиОбъекта      = "";
	ПослеДобавленияСтроки = "";

	If ТипЗнч(Настройки) = Тип("SpreadsheetDocument") Then

		ВерсияОбработки = СокрЛП(Настройки.Область("R1C5").Текст);
		If ВерсияОбработки = "1.2" Then
			ТекущаяСтрока = 11; //Строка с которой начинается таблица реквизитов
		ElsIf ВерсияОбработки = "1.3" Then
			ТекущаяСтрока = 11; //Строка с которой начинается таблица реквизитов			
		Else
			ВерсияОбработки = "1.1";
			ТекущаяСтрока = 9; //Строка с которой начинается таблица реквизитов
		EndIf;
		Try

			ТекстВосстановленногоРежимаЗагрузки = СокрЛП(Настройки.Область(?(ВерсияОбработки = "1.1", "R1", "R2")
				+ "C5").Текст);
			If ТекстВосстановленногоРежимаЗагрузки = "в справочник" Или ТекстВосстановленногоРежимаЗагрузки = "" Then
				ВосстановленныйРежимЗагрузки = 0;
			ElsIf ТекстВосстановленногоРежимаЗагрузки = "в табличную часть" Или ТекстВосстановленногоРежимаЗагрузки
				= "Х" Then
				ВосстановленныйРежимЗагрузки = 1;
			ElsIf ТекстВосстановленногоРежимаЗагрузки = "в регистр сведений" Then
				ВосстановленныйРежимЗагрузки = 2;
			EndIf;

			МетаданныеОбъекта = Метаданные.НайтиПоПолномуИмени(Настройки.Область(?(ВерсияОбработки = "1.1", "R2", "R3")
				+ "C5").Текст);
			If МетаданныеОбъекта = Undefined Then
				ВызватьExcept "Неправильный формат файла";
			EndIf;

			If ВосстановленныйРежимЗагрузки = 0 Then
				ВосстановленныйСсылкаИсточника = Новый (СтрЗаменить(МетаданныеОбъекта.ПолноеИмя(), ".", "Ссылка."));
			ElsIf ВосстановленныйРежимЗагрузки = 1 Then
				ВосстановленныйСсылкаИсточника = Новый (СтрЗаменить(МетаданныеОбъекта.Родитель().ПолноеИмя(), ".",
					"Ссылка."));
			Else
				ВосстановленныйСсылкаИсточника = Undefined;
			EndIf;
			
			//SourceRef = ПустаяСсылка();
			СтруктураУмолчаний = Новый Структура;
			ТекущаяСтрокаОбласти = "R" + Формат(ТекущаяСтрока, "ЧГ=");
			ИмяРеквизита = Настройки.Область(ТекущаяСтрокаОбласти + "C2").Текст;
			Пока Не IsBlankString(ИмяРеквизита) Do
				СтруктураУмолчанияРеквизита = Новый Структура;
				СтруктураУмолчанияРеквизита.Вставить("AttributeName", ИмяРеквизита);
				СтруктураУмолчанияРеквизита.Вставить("Check", Не IsBlankString(Настройки.Область(ТекущаяСтрокаОбласти
					+ "C1").Текст));
				СтруктураУмолчанияРеквизита.Вставить("SearchField", Не IsBlankString(Настройки.Область(
					ТекущаяСтрокаОбласти + "C3").Текст));

				Типы = Новый Массив;
				ОписаниеТиповСтрокой = Настройки.Область(ТекущаяСтрокаОбласти + "C4").Текст;
				Для к = 1 По СтрЧислоСтрок(ОписаниеТиповСтрокой) Do

					кс = Undefined;
					кч = Undefined;
					кд = Undefined;
					МассивЧастейТипа = mSplitStringIntoSubstringsArray(НРег(СокрЛП(СтрПолучитьСтроку(
						ОписаниеТиповСтрокой, к))), ",");
					If МассивЧастейТипа.Количество() = 0 Then
						Продолжить;
					ElsIf Найти(МассивЧастейТипа[0], ".") Then
						Тип = Тип(СтрЗаменить(МассивЧастейТипа[0], ".", "Ссылка."));
					ElsIf МассивЧастейТипа[0] = "строка" Then
						Тип = Тип("Строка");
						If МассивЧастейТипа.Количество() = 2 Then
							кс = Новый КвалификаторыСтроки(mAdjustToNumber(МассивЧастейТипа[1]),
								ДопустимаяДлина.Переменная);
						ElsIf МассивЧастейТипа.Количество() = 3 Then
							кс = Новый КвалификаторыСтроки(mAdjustToNumber(МассивЧастейТипа[1]),
								ДопустимаяДлина.Фиксированная);
						Else
							кс = Новый КвалификаторыСтроки;
						EndIf;
					ElsIf МассивЧастейТипа[0] = "число" Then
						Тип = Тип("Число");
						кч = Новый КвалификаторыЧисла(mAdjustToNumber(МассивЧастейТипа[1]), mAdjustToNumber(
							МассивЧастейТипа[2]), ?(МассивЧастейТипа.Количество() = 4, ДопустимыйЗнак.Неотрицательный,
							ДопустимыйЗнак.Любой));
					ElsIf МассивЧастейТипа[0] = "булево" Then
						Тип = Тип("Булево");
					ElsIf МассивЧастейТипа[0] = "дата" Then
						Тип = Тип("Дата");
						кд = Новый КвалификаторыДаты(ЧастиДаты.Дата);
					ElsIf МассивЧастейТипа[0] = "время" Then
						Тип = Тип("Дата");
						кд = Новый КвалификаторыДаты(ЧастиДаты.Время);
					ElsIf МассивЧастейТипа[0] = "дата и время" Then
						Тип = Тип("Дата");
						кд = Новый КвалификаторыДаты(ЧастиДаты.ДатаВремя);
					Else
						Продолжить;
					EndIf;
					Типы.Добавить(Тип);
				EndDo;
				ОписаниеТипов = Новый ОписаниеТипов(Типы, кч, кс, кд);
				СтруктураУмолчанияРеквизита.Вставить("TypeDescription", ОписаниеТипов);

				РежимЗагрузкиРеквизита = Настройки.Область(ТекущаяСтрокаОбласти + "C5").Текст;

				СтруктураУмолчанияРеквизита.Вставить("ImportMode", РежимЗагрузкиРеквизита);

				ЗначениеПоУмолчанию = Настройки.Область(ТекущаяСтрокаОбласти + "C6").Текст;
				СтруктураУмолчанияРеквизита.Вставить("DefaultValue", ?(IsBlankString(ЗначениеПоУмолчанию),
					ОписаниеТипов.ПривестиЗначение(Undefined), ЗначениеИзСтрокиВнутр(ЗначениеПоУмолчанию)));

				If РежимЗагрузкиРеквизита = "Вычислять" Then
					СтруктураУмолчанияРеквизита.Вставить("Expression", Настройки.Область(ТекущаяСтрокаОбласти
						+ "C7").Текст);
				Else
					СтруктураУмолчанияРеквизита.Вставить("SearchBy", Настройки.Область(ТекущаяСтрокаОбласти
						+ "C7").Текст);

					СвязьПоВладельцу   = Настройки.Область(ТекущаяСтрокаОбласти + "C8").Текст;
					СтруктураУмолчанияРеквизита.Вставить("LinkByOwner", ?(Лев(СвязьПоВладельцу, 1) = "{",
						ЗначениеИзСтрокиВнутр(СвязьПоВладельцу), СвязьПоВладельцу));

					СвязьПоТипу        = Настройки.Область(ТекущаяСтрокаОбласти + "C9").Текст;
					СтруктураУмолчанияРеквизита.Вставить("LinkByType", ?(Лев(СвязьПоТипу, 1) = "{",
						ЗначениеИзСтрокиВнутр(СвязьПоТипу), СвязьПоТипу));

					СтруктураУмолчанияРеквизита.Вставить("LinkByTypeItem", mAdjustToNumber(Настройки.Область(
						ТекущаяСтрокаОбласти + "C10").Текст));
				EndIf;
				If ВерсияОбработки = "1.3" Then
					СтруктураУмолчанияРеквизита.Вставить("ColumnNumber", mAdjustToNumber(Настройки.Область(
						ТекущаяСтрокаОбласти + "C11").Текст));
				EndIf;

				СтруктураУмолчаний.Вставить(ИмяРеквизита, СтруктураУмолчанияРеквизита);
				ТекущаяСтрока = ТекущаяСтрока + 1;
				ТекущаяСтрокаОбласти = "R" + Формат(ТекущаяСтрока, "ЧГ=");
				ИмяРеквизита = Настройки.Область(ТекущаяСтрокаОбласти + "C2").Текст;

			EndDo;

		Except
			mErrorMessage(ОписаниеОшибки());
		EndTry;
		
		//МетаданныеИсточника = GetSourceMetadata();
		//If МетаданныеИсточника = Undefined Then
		//	Return;
		//EndIf;

		Object.ImportMode   = ВосстановленныйРежимЗагрузки;
		If ВосстановленныйРежимЗагрузки = 0 Then
			Object.CatalogObjectType = МетаданныеОбъекта.Имя;
		ElsIf ВосстановленныйРежимЗагрузки = 1 Then
			//Объект.SourceRef = ВосстановленныйСсылкаИсточника;
			Object.SourceTabularSection = ?(ВосстановленныйРежимЗагрузки, МетаданныеОбъекта.Имя, Undefined);
		ElsIf ВосстановленныйРежимЗагрузки = 2 Then
			Object.RegisterTypeName = МетаданныеОбъекта.Имя;
		EndIf;
		Object.DontCreateNewItems                 = Не IsBlankString(Настройки.Область(?(ВерсияОбработки = "1.1",
			"R3", "R4") + "C5").Текст);
		Object.ReplaceExistingRecords = ?(ВерсияОбработки = "1.1", False, Не IsBlankString(Настройки.Область(
			"R5C5").Текст));
		Object.ManualSpreadsheetDocumentColumnsNumeration = Не IsBlankString(Настройки.Область(?(ВерсияОбработки = "1.1",
			"R4", "R6") + "C5").Текст);
		Object.SpreadsheetDocumentFirstDataRow     = mAdjustToNumber(Настройки.Область(?(ВерсияОбработки = "1.1",
			"R5", "R7") + "C5").Текст);

		Object.BeforeWriteObject = Настройки.Область("R" + Формат(ТекущаяСтрока + 2, "ЧГ=") + "C3").Текст;
		Object.OnWriteObject    = Настройки.Область("R" + Формат(ТекущаяСтрока + 3, "ЧГ=") + "C3").Текст;

		If Object.ImportMode Then
			Object.AfterAddRow = Настройки.Область("R" + Формат(ТекущаяСтрока + 4, "ЧГ=") + "C3").Текст;
		EndIf;

		ТекущаяСтрока = ТекущаяСтрока + 1;

	EndIf;
	Оформление = Undefined;
	//МетаданныеИсточника = GetSourceMetadata();

	ТЗ = FormAttributeToValue("ImportedAttributesTable");

	ТЗ.Очистить();

	If Object.ImportMode = 0 Then
		ЗаполнитьНастройкиКолонокСправочника(ТЗ);
	ElsIf Object.ImportMode = 1 Then
		ЗаполнитьНастройкиКолонокТабличнойЧасти(ТЗ);
	ElsIf Object.ImportMode = 2 Then
		ЗаполнитьНастройкиКолонокРегистраСведений(ТЗ);
	EndIf;

	If Не СтруктураУмолчаний = Undefined Then

		НомерКолонкиОформления = 0;
		НомерКолонки = 1;
		For Each КлючИЗначение Из СтруктураУмолчаний Do
			Колонка = КлючИЗначение.Значение;
			ЗагружаемыйРеквизит = ТЗ.Найти(Колонка.ИмяРеквизита, "AttributeName");
			If Не ЗагружаемыйРеквизит = Undefined Then
				Индекс = ТЗ.Индекс(ЗагружаемыйРеквизит);
				If Индекс >= НомерКолонкиОформления Then
					ЗаполнитьЗначенияСвойств(ЗагружаемыйРеквизит, Колонка);

					ТЗ.Сдвинуть(ЗагружаемыйРеквизит, НомерКолонкиОформления - Индекс);
					If Колонка.Check И Не ВерсияОбработки = "1.3" Then
						ЗагружаемыйРеквизит.ColumnNumber = НомерКолонки;
						НомерКолонки = НомерКолонки + 1;
					EndIf;
					НомерКолонкиОформления = НомерКолонкиОформления + 1;

				EndIf;
			EndIf;

		EndDo;

	Else
		НомерКолонки = 1;
		For Each ЗагружаемыйРеквизит Из ТЗ Do

			ЗагружаемыйРеквизит.Check      = True;
			ЗагружаемыйРеквизит.ColumnNumber = НомерКолонки;
			НомерКолонки = НомерКолонки + 1;

		EndDo;

	EndIf;

	For Each ЗагружаемыйРеквизит Из ТЗ Do
		If ЗагружаемыйРеквизит.ImportMode = "Вычислять" Then
			ЗагружаемыйРеквизит.AdditionalConditionsPresentation = ЗагружаемыйРеквизит.Expression;
		Else
			ЗагружаемыйРеквизит.AdditionalConditionsPresentation = ?(IsBlankString(ЗагружаемыйРеквизит.ИскатьПо), "", "Искать по "
				+ ЗагружаемыйРеквизит.SearchBy) + ?(IsBlankString(ЗагружаемыйРеквизит.СвязьПоВладельцу), "",
				" по владельцу " + ЗагружаемыйРеквизит.LinkByOwner);
		EndIf;
	EndDo;

	ЗначениеВРеквизитФормы(ТЗ, "ImportedAttributesTable");

EndProcedure // ()

// Заполняет настройки колонок по умолчанию для табличной части
//
&AtServer
Procedure ЗаполнитьНастройкиКолонокТабличнойЧасти(ТЗ)

	МетаданныеИсточника = GetSourceMetadata();

	If МетаданныеИсточника = Undefined Then
		Return;
	EndIf;

	For Each Реквизит Из МетаданныеИсточника.Реквизиты Do
		ЗагружаемыйРеквизит                        = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = Реквизит.Имя;
		ЗагружаемыйРеквизит.AttributePresentation = Реквизит.Представление();
		ЗагружаемыйРеквизит.TypeDescription = МетаданныеИсточника.Реквизиты[ЗагружаемыйРеквизит.AttributeName].Тип;
	EndDo;

	For Each ЗагружаемыйРеквизит Из ТЗ Do

		СписокВыбора = ПолучитьСписокИменПредставлений(ЗагружаемыйРеквизит.ОписаниеТипов);
		ЗагружаемыйРеквизит.SearchBy = ?(СписокВыбора.Количество() = 0, "", СписокВыбора[0].Значение);

		СписокВыбора = ПолучитьСписокСвязейПоВладельцу(ЗагружаемыйРеквизит.ОписаниеТипов, ТЗ);
		ЗагружаемыйРеквизит.LinkByOwner = ?(СписокВыбора.Количество() = 0, "", СписокВыбора[0].Значение);

		СписокВыбора = ПолучитьСписокСвязейПоТипу(ЗагружаемыйРеквизит, ТЗ);
		If СписокВыбора.Количество() = 0 Then
			ЗагружаемыйРеквизит.LinkByType = "";
			ЗагружаемыйРеквизит.LinkByTypeItem = 0;
		Else
			ЗагружаемыйРеквизит.LinkByType = СписокВыбора[0].Значение;
			If Найти(ЗагружаемыйРеквизит.ИмяРеквизита, "3") <> 0 Then

				ЗагружаемыйРеквизит.LinkByTypeItem = 3;

			ElsIf Найти(ЗагружаемыйРеквизит.ИмяРеквизита, "2") <> 0 Then

				ЗагружаемыйРеквизит.LinkByTypeItem = 2;

			Else

				ЗагружаемыйРеквизит.LinkByTypeItem = 1;

			EndIf;

		EndIf;

		ЗагружаемыйРеквизит.DefaultValue = ЗагружаемыйРеквизит.TypeDescription.ПривестиЗначение(Undefined);
		ЗагружаемыйРеквизит.AvailableTypes = ЗагружаемыйРеквизит.TypeDescription;
		ЗагружаемыйРеквизит.ImportMode = "Искать";
	EndDo;

EndProcedure // ()

// Заполняет настройки колонок по умолчанию для справочника
//
&AtServer
Procedure ЗаполнитьНастройкиКолонокСправочника(ТЗ)

	МетаданныеИсточника = GetSourceMetadata();

	If МетаданныеИсточника = Undefined Then
		Return;
	EndIf;

	If МетаданныеИсточника.ДлинаКода > 0 Then

		ЗагружаемыйРеквизит = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = "Код";
		ЗагружаемыйРеквизит.AttributePresentation = "Код";
		ЗагружаемыйРеквизит.PossibleSearchField   =  True;

		If МетаданныеИсточника.ТипКода = Метаданные.СвойстваОбъектов.ТипКодаСправочника.Строка Then
			ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов("Строка", ,
				Новый КвалификаторыСтроки(МетаданныеИсточника.ДлинаКода));
		Else
			ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов("Число", , ,
				Новый КвалификаторыЧисла(МетаданныеИсточника.ДлинаКода));
		EndIf;

	EndIf;

	If МетаданныеИсточника.ДлинаНаименования > 0 Then

		ЗагружаемыйРеквизит = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = "Наименование";
		ЗагружаемыйРеквизит.AttributePresentation = "Наименование";
		ЗагружаемыйРеквизит.PossibleSearchField   =  True;
		ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов("Строка", ,
			Новый КвалификаторыСтроки(МетаданныеИсточника.ДлинаНаименования));

	EndIf;

	If МетаданныеИсточника.Владельцы.Количество() > 0 Then

		ЗагружаемыйРеквизит = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = "Владелец";
		ЗагружаемыйРеквизит.AttributePresentation = "Владелец";
		ЗагружаемыйРеквизит.PossibleSearchField   =  True;

		СтрокаОписанияТипов = "";

		For Each Владелец Из МетаданныеИсточника.Владельцы Do
			СтрокаОписанияТипов = ?(IsBlankString(СтрокаОписанияТипов), "", СтрокаОписанияТипов + ", ")
				+ Владелец.ПолноеИмя();
		EndDo;

		СтрокаОписанияТипов = СтрЗаменить(СтрокаОписанияТипов, ".", "Ссылка.");
		ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов(СтрокаОписанияТипов);

	EndIf;

	If МетаданныеИсточника.Иерархический Then

		ЗагружаемыйРеквизит = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = "Родитель";
		ЗагружаемыйРеквизит.AttributePresentation = "Родитель";
		ЗагружаемыйРеквизит.PossibleSearchField   = True;
		ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов(СтрЗаменить(МетаданныеИсточника.ПолноеИмя(), ".",
			"Ссылка."));
		
		If МетаданныеИсточника.ВидИерархии = Метаданные.СвойстваОбъектов.ВидИерархии.ИерархияГруппИЭлементов Then
			ЗагружаемыйРеквизит = ТЗ.Добавить();
			ЗагружаемыйРеквизит.AttributeName           = "ЭтоГруппа";
			ЗагружаемыйРеквизит.AttributePresentation = "ЭтоГруппа";
			ЗагружаемыйРеквизит.PossibleSearchField   = True;
			ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов("Булево");
		EndIf; 

	EndIf;

	For Each Реквизит Из МетаданныеИсточника.Реквизиты Do
		If Не Реквизит.Использование = Метаданные.СвойстваОбъектов.ИспользованиеРеквизита.ДляГруппы Then
			ЗагружаемыйРеквизит                        = ТЗ.Добавить();
			ЗагружаемыйРеквизит.AttributeName           = Реквизит.Имя;
			ЗагружаемыйРеквизит.AttributePresentation = Реквизит.Представление();
			ЗагружаемыйРеквизит.PossibleSearchField   = Не Реквизит.Индексирование
				= Метаданные.СвойстваОбъектов.Индексирование.НеИндексировать;
			ЗагружаемыйРеквизит.TypeDescription = МетаданныеИсточника.Реквизиты[ЗагружаемыйРеквизит.AttributeName].Тип;
		EndIf;
	EndDo;

	For Each ЗагружаемыйРеквизит Из ТЗ Do

		СписокВыбора = ПолучитьСписокИменПредставлений(ЗагружаемыйРеквизит.ОписаниеТипов);
		ЗагружаемыйРеквизит.SearchBy = ?(СписокВыбора.Количество() = 0, "", СписокВыбора[0].Значение);

		СписокВыбора = ПолучитьСписокСвязейПоВладельцу(ЗагружаемыйРеквизит.ОписаниеТипов, ТЗ);
		ЗагружаемыйРеквизит.LinkByOwner = ?(СписокВыбора.Количество() = 0, "", СписокВыбора[0].Значение);

		СписокВыбора = ПолучитьСписокСвязейПоТипу(ЗагружаемыйРеквизит, ТЗ);
		If СписокВыбора.Количество() = 0 Then
			ЗагружаемыйРеквизит.LinkByType = "";
			ЗагружаемыйРеквизит.LinkByTypeItem = 0;
		Else
			ЗагружаемыйРеквизит.LinkByType = СписокВыбора[0].Значение;
			If Найти(ЗагружаемыйРеквизит.ИмяРеквизита, "3") <> 0 Then

				ЗагружаемыйРеквизит.LinkByTypeItem = 3;

			ElsIf Найти(ЗагружаемыйРеквизит.ИмяРеквизита, "2") <> 0 Then

				ЗагружаемыйРеквизит.LinkByTypeItem = 2;

			Else

				ЗагружаемыйРеквизит.LinkByTypeItem = 1;

			EndIf;
		EndIf;

		ЗагружаемыйРеквизит.DefaultValue = ЗагружаемыйРеквизит.TypeDescription.ПривестиЗначение(Undefined);
		ЗагружаемыйРеквизит.AvailableTypes = ЗагружаемыйРеквизит.TypeDescription;
		ЗагружаемыйРеквизит.ImportMode = "Искать";
	EndDo;
EndProcedure // ()

// Заполняет настройки колонок по умолчанию для регистра сведений
//
&AtServer
Procedure ЗаполнитьНастройкиКолонокРегистраСведений(ТЗ)

	МетаданныеИсточника = GetSourceMetadata();

	If МетаданныеИсточника = Undefined Then
		Return;
	EndIf;

	If Не МетаданныеИсточника.ПериодичностьРегистраСведений
		= Метаданные.СвойстваОбъектов.ПериодичностьРегистраСведений.Непериодический Then

		ЗагружаемыйРеквизит = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = "Период";
		ЗагружаемыйРеквизит.AttributePresentation = "Период";
		ЗагружаемыйРеквизит.PossibleSearchField = True;
		ЗагружаемыйРеквизит.SearchField           = True;

		ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов("Дата", , , ,
			Новый КвалификаторыДаты(ЧастиДаты.ДатаВремя));

	EndIf;

	For Each Реквизит Из МетаданныеИсточника.Измерения Do
		ЗагружаемыйРеквизит                        = ТЗ.Добавить();
		ЗагружаемыйРеквизит.PossibleSearchField = True;
		ЗагружаемыйРеквизит.AttributeName           = Реквизит.Имя;
		ЗагружаемыйРеквизит.AttributePresentation = Реквизит.Представление();
		ЗагружаемыйРеквизит.TypeDescription = МетаданныеИсточника.Измерения[ЗагружаемыйРеквизит.AttributeName].Тип;
	EndDo;

	For Each Реквизит Из МетаданныеИсточника.Ресурсы Do
		ЗагружаемыйРеквизит                        = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = Реквизит.Имя;
		ЗагружаемыйРеквизит.AttributePresentation = Реквизит.Представление();
		ЗагружаемыйРеквизит.TypeDescription = МетаданныеИсточника.Ресурсы[ЗагружаемыйРеквизит.AttributeName].Тип;
	EndDo;

	For Each Реквизит Из МетаданныеИсточника.Реквизиты Do
		ЗагружаемыйРеквизит                        = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = Реквизит.Имя;
		ЗагружаемыйРеквизит.AttributePresentation = Реквизит.Представление();
		ЗагружаемыйРеквизит.TypeDescription = МетаданныеИсточника.Реквизиты[ЗагружаемыйРеквизит.AttributeName].Тип;
	EndDo;

	For Each ЗагружаемыйРеквизит Из ТЗ Do

		СписокВыбора = ПолучитьСписокИменПредставлений(ЗагружаемыйРеквизит.ОписаниеТипов);
		ЗагружаемыйРеквизит.SearchBy = ?(СписокВыбора.Количество() = 0, "", СписокВыбора[0].Значение);

		СписокВыбора = ПолучитьСписокСвязейПоВладельцу(ЗагружаемыйРеквизит.ОписаниеТипов, ТЗ);
		ЗагружаемыйРеквизит.LinkByOwner = ?(СписокВыбора.Количество() = 0, "", СписокВыбора[0].Значение);

		СписокВыбора = ПолучитьСписокСвязейПоТипу(ЗагружаемыйРеквизит, ТЗ);
		If СписокВыбора.Количество() = 0 Then
			ЗагружаемыйРеквизит.LinkByType = "";
			ЗагружаемыйРеквизит.LinkByTypeItem = 0;
		Else
			ЗагружаемыйРеквизит.LinkByType = СписокВыбора[0].Значение;
			If Найти(ЗагружаемыйРеквизит.ИмяРеквизита, "3") <> 0 Then

				ЗагружаемыйРеквизит.LinkByTypeItem = 3;

			ElsIf Найти(ЗагружаемыйРеквизит.ИмяРеквизита, "2") <> 0 Then

				ЗагружаемыйРеквизит.LinkByTypeItem = 2;

			Else

				ЗагружаемыйРеквизит.LinkByTypeItem = 1;

			EndIf;
		EndIf;

		ЗагружаемыйРеквизит.DefaultValue = ЗагружаемыйРеквизит.TypeDescription.ПривестиЗначение(Undefined);
		ЗагружаемыйРеквизит.AvailableTypes = ЗагружаемыйРеквизит.TypeDescription;
		ЗагружаемыйРеквизит.ImportMode = "Искать";
	EndDo;
EndProcedure // ()

// Function формирует табличный документ с настройками обработки
&AtServer
Function ПолучитьНастройки()

	МетаданныеОбъекта = GetSourceMetadata();

	If МетаданныеОбъекта = Undefined Then
		Return Undefined;
	EndIf;

	ВидОбъекта     = МетаданныеОбъекта.ПолноеИмя();

	ДокументРезультат = Новый ТабличныйДокумент;
	ОбработкаОбъект = FormAttributeToValue("Object");
	Макет = ОбработкаОбъект.ПолучитьМакетОбработки("МакетСохраненияНастроек");

	ОбластьШапки = Макет.ПолучитьОбласть("Шапка");
	If Object.ImportMode = 0 Then
		ОбластьШапки.Параметры.ImportMode = "в справочник";
	ElsIf Object.ImportMode = 1 Then
		ОбластьШапки.Параметры.ImportMode = "в табличную часть";
	ElsIf Object.ImportMode = 2 Then
		ОбластьШапки.Параметры.ImportMode = "в регистр сведений";
	EndIf;

	ОбластьШапки.Параметры.ВидОбъекта                                = ВидОбъекта;
	ОбластьШапки.Параметры.DontCreateNewItems                 = ?(Object.DontCreateNewItems, "Х", "");
	ОбластьШапки.Параметры.ReplaceExistingRecords                 = ?(Object.ReplaceExistingRecords, "Х", "");
	ОбластьШапки.Параметры.ManualSpreadsheetDocumentColumnsNumeration = ?(
		Object.ManualSpreadsheetDocumentColumnsNumeration, "Х", "");
	ОбластьШапки.Параметры.SpreadsheetDocumentFirstDataRow     = Object.SpreadsheetDocumentFirstDataRow;

	ДокументРезультат.Вывести(ОбластьШапки);

	ТЗ = FormAttributeToValue("ImportedAttributesTable");

	For Each ЗагружаемыйРеквизит Из ТЗ Do
		ОбластьСтроки = Макет.ПолучитьОбласть("Строка" + ?(ЗагружаемыйРеквизит.ImportMode = "Вычислять", "Expression",
			""));

		ОбластьСтроки.Параметры.Check      = ?(ЗагружаемыйРеквизит.Пометка, "Х", "");
		ОбластьСтроки.Параметры.AttributeName = ЗагружаемыйРеквизит.AttributeName;
		ОбластьСтроки.Параметры.SearchField   = ?(ЗагружаемыйРеквизит.ПолеПоиска, "Х", "");

		ОбластьСтроки.Параметры.TypeDescription       = GetTypeDescription(ЗагружаемыйРеквизит.ОписаниеТипов);

		ОбластьСтроки.Параметры.ImportMode       = ЗагружаемыйРеквизит.ImportMode;
		If ЗагружаемыйРеквизит.TypeDescription.ПривестиЗначение(Undefined) = ЗагружаемыйРеквизит.DefaultValue Then
			ОбластьСтроки.Параметры.DefaultValue = "";
		Else
			ОбластьСтроки.Параметры.DefaultValue = ЗначениеВСтрокуВнутр(ЗагружаемыйРеквизит.ЗначениеПоУмолчанию);
		EndIf;

		If ЗагружаемыйРеквизит.ImportMode = "Вычислять" Then

			ОбластьСтроки.Параметры.Expression           = ЗагружаемыйРеквизит.Expression;

		Else
			ОбластьСтроки.Параметры.SearchBy            = ЗагружаемыйРеквизит.SearchBy;
			ОбластьСтроки.Параметры.LinkByOwner    = ?(ТипЗнч(ЗагружаемыйРеквизит.СвязьПоВладельцу) = Тип(
				"Строка"), ЗагружаемыйРеквизит.СвязьПоВладельцу, ЗначениеВСтрокуВнутр(
				ЗагружаемыйРеквизит.СвязьПоВладельцу));
			ОбластьСтроки.Параметры.LinkByType         = ?(ТипЗнч(ЗагружаемыйРеквизит.СвязьПоТипу) = Тип("Строка"),
				ЗагружаемыйРеквизит.СвязьПоТипу, ЗначениеВСтрокуВнутр(ЗагружаемыйРеквизит.СвязьПоТипу));
			ОбластьСтроки.Параметры.LinkByTypeItem  = ЗагружаемыйРеквизит.LinkByTypeItem;
		EndIf;
		// Добавлен параметр ColumnNumber
		ОбластьСтроки.Параметры.ColumnNumber			= ЗагружаемыйРеквизит.ColumnNumber;

		ДокументРезультат.Вывести(ОбластьСтроки);

	EndDo;

	ОбластьПодвала = Макет.ПолучитьОбласть("Events");
	ОбластьПодвала.Параметры.BeforeWriteObject = Object.BeforeWriteObject;
	ОбластьПодвала.Параметры.OnWriteObject = Object.OnWriteObject;
	ДокументРезультат.Вывести(ОбластьПодвала);
	If Object.ImportMode Then

		ОбластьПодвала = Макет.ПолучитьОбласть("СобытияПослеДобавленияСтроки");
		ОбластьПодвала.Параметры.AfterAddRow = Object.AfterAddRow;
		ДокументРезультат.Вывести(ОбластьПодвала);

	EndIf;

	Return ДокументРезультат;

EndFunction

// Function читает mxl-файл с настройками обработки
&AtServer
Function ПрочитатьНастройкиНаСервере(АдресХранилища)

	Данные = ПолучитьИзВременногоХранилища(АдресХранилища);

	ИмяФайлаВременное = ПолучитьИмяВременногоФайла("mxl");
	ВремДок = Новый ТабличныйДокумент;
	Данные.Записать(ИмяФайлаВременное);
	ВремДок.Прочитать(ИмяФайлаВременное);
	УдалитьФайлы(ИмяФайлаВременное);

	Return ВремДок;
EndFunction

// Function возвращает содержимое mxl-файла с настройками обработки
&НаКлиенте
Function мПрочитатьНастройкиИзФайла(ИмяФайла)

	ДанныеФайла = Новый ДвоичныеДанные(ИмяФайла);

	АдресФайла = "";
	АдресФайла = ПоместитьВоВременноеХранилище(ДанныеФайла, ЭтаФорма.УникальныйИдентификатор);

	Return ПрочитатьНастройкиНаСервере(АдресФайла);

EndFunction

&AtServer
Procedure СкопироватьНастройки(Знач Источник, Приемник)
	
	//If ТипЗнч(Источник) = Тип("FormDataCollection") Then
	//	Источник = FormDataToValue(Источник, Тип("ValueTable"));
	//Else
	If Не ТипЗнч(Источник) = Тип("ValueTable") Then
		Return;
	EndIf;

	Приемник.Очистить();

	For Each Стр Из Источник Do
		НовСтр = Приемник.Добавить();
		ЗаполнитьЗначенияСвойств(НовСтр, Стр);
	EndDo;

EndProcedure

&AtServer
Procedure ПриЗакрытииНаСервере()

	mSaveValue("ImportMode", Object.ImportMode);
	mSaveValue("SourceRef", Object.SourceRef);
	mSaveValue("SourceTabularSection", Object.SourceTabularSection);
	mSaveValue("RegisterTypeName", Object.RegisterTypeName);
	mSaveValue("CatalogObjectType", Object.CatalogObjectType);

EndProcedure // ПриЗакрытииНаСервере()

////////////////////////////////////////////////////////////////////////////////
//

&AtServer
Procedure ОбновитьДанныеТабличногоДокументаСервер()

	SpreadsheetDocument.Очистить();

	GenerateColumnsStructure();
	GenerateSpreadsheetDocumentHeader(SpreadsheetDocument);

	НомерСтроки = Object.SpreadsheetDocumentFirstDataRow;

	МетаданныеИсточника = GetSourceMetadata();
	If Object.ImportMode = 0 Или Object.ImportMode = 2 Или МетаданныеИсточника = Undefined Then
		Return;
	EndIf;

	Источник = Object.SourceRef[Object.SourceTabularSection];
	
	//ТЗ = FormAttributeToValue("ImportedAttributesTable");

	For Each Строка Из Источник Do

		НомерКолонки = 0;

		For Each ЗагружаемыйРеквизит Из ImportedAttributesTable Do

			If ЗагружаемыйРеквизит.Check Then

				If Object.ManualSpreadsheetDocumentColumnsNumeration Then
					НомерКолонки = ЗагружаемыйРеквизит.ColumnNumber;
				Else
					НомерКолонки = НомерКолонки + 1;
				EndIf;

				Область = SpreadsheetDocument.Область("R" + Формат(НомерСтроки, "ЧГ=") + "C" + НомерКолонки);
				Значение = Строка[ЗагружаемыйРеквизит.AttributeName];

				Try
					Представление = Значение[ЗагружаемыйРеквизит.SearchBy];

				Except

					Представление = Значение;

				EndTry;

				Область.Текст = Представление;
				Область.Расшифровка = Значение;

			EndIf;

		EndDo;

		НомерСтроки = НомерСтроки + 1;
	EndDo;

EndProcedure // ОбновитьДанныеТабличногоДокументаСервер()

&НаКлиенте
Procedure ОбновитьДанныеТабличногоДокумента(Знач Оповещение, БезВопросов = False)

	If (Object.ImportMode = 0 Или Object.ImportMode = 2) И Элементы.SpreadsheetDocument.Высота > 1 И Не БезВопросов Then
		ПоказатьВопрос(Новый ОписаниеОповещения("ОбновитьДанныеТабличногоДокументаЗавершение", ЭтаФорма,
			Новый Структура("Оповещение", Оповещение)), "Табличный документ содержит данные. Очистить?",
			РежимДиалогаВопрос.ДаНет);
		Return;
	Else
		ОбновитьДанныеТабличногоДокументаСервер();
	EndIf;

	ОбновитьДанныеТабличногоДокументаФрагмент(Оповещение);
EndProcedure

&НаКлиенте
Procedure ОбновитьДанныеТабличногоДокументаЗавершение(РезультатВопроса, ДополнительныеПараметры) Export

	Оповещение = ДополнительныеПараметры.Оповещение;
	If РезультатВопроса = КодReturnаДиалога.Да Then
		ОбновитьДанныеТабличногоДокументаСервер();
		ВыполнитьОбработкуОповещения(Оповещение);
		Return;
	EndIf;

	ОбновитьДанныеТабличногоДокументаФрагмент(Оповещение);

EndProcedure

&НаКлиенте
Procedure ОбновитьДанныеТабличногоДокументаФрагмент(Знач Оповещение)

	ВыполнитьОбработкуОповещения(Оповещение);

EndProcedure

// Function считывает в табличный документ данные из файла в формате Excel
//
// Параметры:
//  SpreadsheetDocument  - SpreadsheetDocument, в который необходимо прочитать данные
//  ИмяФайла           - имя файла в формате Excel, из которого необходимо прочитать данные
//  НомерЛистаExcel    - номер листа книги Excel, из которого необходимо прочитать данные
//
// Возвращаемое значение:
//  True, If файл прочитан, False - Else
//
&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзExcel(ИмяФайла, НомерЛистаExcel = 1) Export

	НачатьПроверкуСуществованияФайла(ИмяФайла,
		Новый ОписаниеОповещения("мПрочитатьТабличныйДокументИзExcelЗаверешениеПроверкиСуществованияФайла", ЭтотОбъект,
		Новый Структура("ИмяФайла,НомерЛистаExcel", ИмяФайла, НомерЛистаExcel)));

EndProcedure // ()

&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзExcelЗаверешениеПроверкиСуществованияФайла(Существует, ДополнительныеПараметры) Export
	If Не Существует Then
		Сообщить("Файл не существует!");
		Return;
	EndIf;
	НомерЛистаExcel=ДополнительныеПараметры.НомерЛистаExcel;
	ИмяФайла=ДополнительныеПараметры.ИмяФайла;

	xlLastCell = 11;
	Try
		Excel = Новый COMОбъект("Excel.Application");
		Excel.WorkBooks.Open(ИмяФайла);
		Сообщить("Обработка файла Microsoft Excel...");
		ExcelЛист = Excel.Sheets(НомерЛистаExcel);
	Except
		Сообщить("Ошибка. Возможно неверно указан номер листа книги Excel.");
		Return;

	EndTry;

	SpreadsheetDocument = Новый ТабличныйДокумент;

	ActiveCell = Excel.ActiveCell.SpecialCells(xlLastCell);
	RowCount = ActiveCell.Row;
	ColumnCount = ActiveCell.Column;
	Для Column = 1 По ColumnCount Do
		SpreadsheetDocument.Область("C" + Формат(Column, "ЧГ=")).ColumnWidth = ExcelЛист.Columns(Column).ColumnWidth;
	EndDo;
	Для Row = 1 По RowCount Do

		Для Column = 1 По ColumnCount Do
			SpreadsheetDocument.Область("R" + Формат(Row, "ЧГ=") + "C" + Формат(Column, "ЧГ=")).Текст = ExcelЛист.Cells(
				Row, Column).Text;
		EndDo;

	EndDo;

	Excel.WorkBooks.Close();
	Excel = 0;
EndProcedure

// Function считывает в табличный документ данные из файла в формате TXT
//
// Параметры:
//  SpreadsheetDocument  - SpreadsheetDocument, в который необходимо прочитать данные
//  ИмяФайла           - имя файла в формате TXT, из которого необходимо прочитать данные
//
// Возвращаемое значение:
//  True, If файл прочитан, False - Else
//
&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзТекста(ИмяФайла) Export

	ВыбФайл = Новый Файл(ИмяФайла);
	ВыбФайл.НачатьПроверкуСуществования(
		Новый ОписаниеОповещения("мПрочитатьТабличныйДокументИзТекстаЗавершениеПроверкиСуществованияФайла", ЭтаФорма,
		Новый Структура("ИмяФайла", ИмяФайла)));

EndProcedure

&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзТекстаЗавершениеПроверкиСуществованияФайла(Существует, ДополнительныеПараметры) Export

	ИмяФайла = ДополнительныеПараметры.ИмяФайла;
	If Существует Then
		ТекстовыйДокумент = Новый ТекстовыйДокумент;
		ТекстовыйДокумент.НачатьЧтение(Новый ОписаниеОповещения("мПрочитатьТабличныйДокументИзТекстаЗавершение",
			ЭтотОбъект, Новый Структура("ТекстовыйДокумент", ТекстовыйДокумент),
			"мПрочитатьТабличныйДокументИзТекстаЗавершениеОшибкаЧтения", ЭтотОбъект), ИмяФайла);

	Else
		Сообщить("Файл не существует!");

	EndIf;

EndProcedure // ()

&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзТекстаЗавершение(ДополнительныеПараметры) Export
	ТекстовыйДокумент=ДополнительныеПараметры.ТекстовыйДокумент;

	SpreadsheetDocument = Новый ТабличныйДокумент;
	Для ТекущаяСтрока = 1 По ТекстовыйДокумент.КоличествоСтрок() Do
		ТекущаяКолонка = 0;
		For Each Значение Из mSplitStringIntoSubstringsArray(ТекстовыйДокумент.ПолучитьСтроку(ТекущаяСтрока),
			Символы.Таб) Do
			ТекущаяКолонка = ТекущаяКолонка + 1;
			SpreadsheetDocument.Область("R" + Формат(ТекущаяСтрока, "ЧГ=") + "C" + Формат(ТекущаяКолонка,
				"ЧГ=")).Текст = Значение;

		EndDo;

	EndDo;
EndProcedure

&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзТекстаЗавершениеОшибкаЧтения(ИнформацияОбОшибке, СтандартнаяОбработка,
	ДополнительныеПараметры) Export
	СтандартнаяОбработка=False;
	Сообщить("Ошибка открытия файла!");
EndProcedure

&НаКлиенте
Procedure НачатьПроверкуСуществованияФайла(ИмяФайла, ОписаниеОповещенияОЗавершении)
	ВыбФайл = Новый Файл(ИмяФайла);
	ВыбФайл.НачатьПроверкуСуществования(ОписаниеОповещенияОЗавершении);
EndProcedure

// Function считывает в табличный документ данные из файла в формате dBase III (*.dbf)
//
// Параметры:
//  SpreadsheetDocument  - SpreadsheetDocument, в который необходимо прочитать данные
//  ИмяФайла           - имя файла в формате TXT, из которого необходимо прочитать данные
//
// Возвращаемое значение:
//  True, If файл прочитан, False - Else
//
&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзDBF(ИмяФайла) Export
	НачатьПроверкуСуществованияФайла(ИмяФайла,
		Новый ОписаниеОповещения("мПрочитатьТабличныйДокументИзDBFЗавершениеПроверкиСуществованияФайла", ЭтотОбъект,
		Новый Структура("ИмяФайла", ИмяФайла)));
EndProcedure // ()

&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзDBFЗавершениеПроверкиСуществованияФайла(Существует, ДополнительныеПараметры) Export
	If Не Существует Then
		Сообщить("Файл не существует!");
		Return;
	EndIf;

#If Не ВебКлиент Then

	ИмяФайла=ДополнительныеПараметры.ИмяФайла;

	XBase  = Новый XBase;
	XBase.Кодировка = ПредопределенноеЗначение("КодировкаXBase.OEM");
	Try
		XBase.ОткрытьФайл(ИмяФайла);
	Except
		Сообщить("Ошибка открытия файла!");
		Return;
	EndTry;

	SpreadsheetDocument = Новый ТабличныйДокумент;
	ТекущаяСтрока = 1;
	ТекущаяКолонка = 0;
	For Each Поле Из XBase.поля Do
		ТекущаяКолонка = ТекущаяКолонка + 1;
		SpreadsheetDocument.Область("R" + Формат(ТекущаяСтрока, "ЧГ=") + "C" + Формат(ТекущаяКолонка,
			"ЧГ=")).Текст = Поле.Имя;
	EndDo;
	Рез = XBase.Первая();
	Пока Не XBase.ВКонце() Do
		ТекущаяСтрока = ТекущаяСтрока + 1;

		ТекущаяКолонка = 0;
		For Each Поле Из XBase.поля Do
			ТекущаяКолонка = ТекущаяКолонка + 1;
			SpreadsheetDocument.Область("R" + Формат(ТекущаяСтрока, "ЧГ=") + "C" + Формат(ТекущаяКолонка,
				"ЧГ=")).Текст = XBase.ПолучитьЗначениеПоля(ТекущаяКолонка - 1);
		EndDo;

		XBase.Следующая();
	EndDo;
#Else
		ПоказатьПредупреждение(Undefined, "Чтение DBF файлов недоступно в веб клиенте");
#EndIf

EndProcedure

&AtServer
Procedure ПрочитатьТабличныйДокументИзMXLНаСервере(АдресХранилища)

	Данные = ПолучитьИзВременногоХранилища(АдресХранилища);

	ИмяФайлаВременное = ПолучитьИмяВременногоФайла("mxl");

	Данные.Записать(ИмяФайлаВременное);
	SpreadsheetDocument.Прочитать(ИмяФайлаВременное);
	УдалитьФайлы(ИмяФайлаВременное);

EndProcedure // ПрочитатьТабличныйДокументИзMXLНаСервере()

&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзMXL(ИмяФайла)

	ДанныеФайла = Новый ДвоичныеДанные(ИмяФайла);

	АдресФайла = "";
	АдресФайла = ПоместитьВоВременноеХранилище(ДанныеФайла, ЭтаФорма.УникальныйИдентификатор);

	ПрочитатьТабличныйДокументИзMXLНаСервере(АдресФайла);

EndProcedure // ()

////////////////////////////////////////////////////////////////////////////////
//

&НаКлиенте
Procedure УправлениеВидимостью()

	РежимЗагрузки = Object.ImportMode;
	РучнаяНумерацияКолонокТабличногоДокумента = Object.ManualSpreadsheetDocumentColumnsNumeration;

	If РежимЗагрузки = 0 Then
		ТекЭлемент = Элементы.ImportToCatalogGroup;
	ElsIf РежимЗагрузки = 1 Then
		ТекЭлемент = Элементы.ImportToTabularSectionGroup;
	ElsIf РежимЗагрузки = 2 Then
		ТекЭлемент = Элементы.ImportToInformationRegisterGroup;
	Else
		Return; // Неизвестный режим
	EndIf;
	If Не Элементы.ModeBarGroup.ТекущаяСтраница = ТекЭлемент Then
		Элементы.ModeBarGroup.ТекущаяСтраница = ТекЭлемент;
	EndIf;

	Элементы.ImportedAttributesTableSearchField.Видимость         = РежимЗагрузки = 0;

	Элементы.DontCreateNewItems.Видимость = РежимЗагрузки = 0;
	Элементы.ReplaceExistingRecords.Видимость = РежимЗагрузки = 2;

	ДоступностьКнопкиСохранитьЗначения    = SelectedMetadataExists();
	ДоступностьКнопкиВосстановитьЗначения = False; //Не СписокСохраненныхНастроек.Количество() = 0;

	Элементы.SaveValues.Доступность = False; //ДоступностьКнопкиСохранитьЗначения;
	Элементы.RestoreValues.Доступность = ДоступностьКнопкиВосстановитьЗначения;

	Элементы.SaveValuesToFile.Доступность = ДоступностьКнопкиСохранитьЗначения;

	Элементы.ImportedAttributesTableColumnNumber.Видимость = РучнаяНумерацияКолонокТабличногоДокумента;
	Элементы.RenumberColumns.Доступность = РучнаяНумерацияКолонокТабличногоДокумента;
	Элементы.ManualSpreadsheetDocumentColumnsNumeration.Check = РучнаяНумерацияКолонокТабличногоДокумента;

EndProcedure // УправлениеВидимостью()

// Procedure выполняет установку реквизитов, связанных с источником данных
//
&AtServer
Procedure УстановитьИсточник(СписокНастроек = Undefined)

	Источник        = Undefined;
	ОбъектИсточника = Undefined;
	//СписокСохраненныхНастроек.Очистить();
	ПрошлыйМетаданныеСсылкиИсточника = Undefined;
	МетаданныеИсточника = GetSourceMetadata();
	If МетаданныеИсточника = Undefined Then
		ImportedAttributesTable.Очистить();
	Else
		Врем = mRestoreValue(МетаданныеИсточника.ПолноеИмя());
		//If НЕ СписокНастроек = Undefined Then
		//	СкопироватьНастройки(Врем, СписокНастроек);
		//	Настройка = GetDefaultSetting(СписокНастроек);
		//	ВосстановитьНастройкиИзСписка(Настройка);
		//Else
		//	ВосстановитьНастройкиИзСписка(Undefined);
		ЗаполнитьНастройкиКолонок(Undefined);
		//EndIf;
	EndIf;

	ОбновитьДанныеТабличногоДокументаСервер();

	СпискиВыбораСвязиПоВладельцу.Очистить();

	ТЗ = FormAttributeToValue("ImportedAttributesTable");

	For Each ЗагружаемыйРеквизит Из ТЗ Do

		СтрокаСписка = СпискиВыбораСвязиПоВладельцу.Добавить();
		СтрокаСписка.AttributeName = ЗагружаемыйРеквизит.AttributeName;
		СтрокаСписка.СписокВыбора = ПолучитьСписокСвязейПоВладельцу(ЗагружаемыйРеквизит.ОписаниеТипов, ТЗ);
	EndDo;

EndProcedure

// Procedure выполняет инициализацию служебных переменных и констант модуля
//
&AtServer
Procedure Инициализация()

	Object.AdditionalProperties = Новый Структура;

	Object.AdditionalProperties.Вставить("ПримитивныеТипы", Новый Структура("Число, Строка, Дата, Булево", Тип(
		"Число"), Тип("Строка"), Тип("Дата"), Тип("Булево")));

	If Object.SpreadsheetDocumentFirstDataRow < 2 Then
		Object.SpreadsheetDocumentFirstDataRow = 2;
	EndIf;

	Object.AdditionalProperties.Вставить("Колонки", Новый Структура);

EndProcedure // ()

///////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ КОМАНД

&НаКлиенте
Procedure ImportCommand(Команда)

	СтруктураТекстВопроса = GetSourceQuestionText();
	КоличествоЭлементов = SpreadsheetDocument.ВысотаТаблицы - Object.SpreadsheetDocumentFirstDataRow + 1;
	If Не IsBlankString(СтруктураТекстВопроса.Ошибка) Then
		ПоказатьПредупреждение( , СтруктураТекстВопроса.Ошибка, , "Ошибка при загрузке!");
	Else
		ПоказатьВопрос(Новый ОписаниеОповещения("КомандаЗагрузитьЗавершение", ЭтаФорма), "Import "
			+ КоличествоЭлементов + СтруктураТекстВопроса.ТекстВопроса, РежимДиалогаВопрос.ДаНет);
	EndIf;

EndProcedure

&НаКлиенте
Procedure КомандаЗагрузитьЗавершение(РезультатВопроса, ДополнительныеПараметры) Export

	If РезультатВопроса = КодReturnаДиалога.Да Then
		ОчиститьСообщения();
		ImportDataServer();
	EndIf;

EndProcedure
&НаКлиенте
Procedure OpenCommand(Команда)

	ДиалогВыбораФайла = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Открытие);

	ДиалогВыбораФайла.Заголовок = "Прочитать табличный документ из файла";
	ДиалогВыбораФайла.Фильтр    = "Табличный документ (*.mxl)|*.mxl|Лист Excel (*.xls,*.xlsx)|*.xls;*.xlsx|Текстовый документ (*.txt)|*.txt|dBase III (*.dbf)|*.dbf|";
	ДиалогВыбораФайла.Показать(Новый ОписаниеОповещения("КомандаОткрытьЗавершение", ЭтаФорма,
		Новый Структура("ДиалогВыбораФайла", ДиалогВыбораФайла)));

EndProcedure

&НаКлиенте
Procedure КомандаОткрытьЗавершение(ВыбранныеФайлы, ДополнительныеПараметры) Export

	ДиалогВыбораФайла = ДополнительныеПараметры.ДиалогВыбораФайла;
	If (ВыбранныеФайлы <> Undefined) Then

		SpreadsheetDocument = Элементы.SpreadsheetDocument;
		ФайлНаДиске = Новый Файл(ДиалогВыбораФайла.ПолноеИмяФайла);
		If нРег(ФайлНаДиске.Расширение) = ".mxl" Then
			мПрочитатьТабличныйДокументИзMXL(ДиалогВыбораФайла.ПолноеИмяФайла);
		ElsIf нРег(ФайлНаДиске.Расширение) = ".xls" Или нРег(ФайлНаДиске.Расширение) = ".xlsx" Then
			мПрочитатьТабличныйДокументИзExcel(ДиалогВыбораФайла.ПолноеИмяФайла);
		ElsIf нРег(ФайлНаДиске.Расширение) = ".txt" Then
			мПрочитатьТабличныйДокументИзТекста(ДиалогВыбораФайла.ПолноеИмяФайла);
		ElsIf нРег(ФайлНаДиске.Расширение) = ".dbf" Then
			мПрочитатьТабличныйДокументИзDBF(ДиалогВыбораФайла.ПолноеИмяФайла);
		EndIf;
		УправлениеВидимостью();
	EndIf;

EndProcedure

&НаКлиенте
Procedure SaveCommand(Команда)

	ДиалогВыбораФайла = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Сохранение);

	ДиалогВыбораФайла.Заголовок = "Сохранить табличный документ в файл";
	ДиалогВыбораФайла.Фильтр    = "Табличный документ (*.mxl)|*.mxl|Лист Excel (*.xls)|*.xls|Текстовый документ (*.txt)|*.txt|";
	ДиалогВыбораФайла.Показать(Новый ОписаниеОповещения("КомандаСохранитьЗавершение", ЭтаФорма,
		Новый Структура("ДиалогВыбораФайла", ДиалогВыбораФайла)));

EndProcedure

&НаКлиенте
Procedure КомандаСохранитьЗавершение(ВыбранныеФайлы, ДополнительныеПараметры) Export

	ДиалогВыбораФайла = ДополнительныеПараметры.ДиалогВыбораФайла;
	If (ВыбранныеФайлы <> Undefined) Then

		SpreadsheetDocument = Элементы.SpreadsheetDocument;
		ФайлНаДиске = Новый Файл(ДиалогВыбораФайла.ПолноеИмяФайла);
		If нРег(ФайлНаДиске.Расширение) = ".mxl" Then
			SpreadsheetDocument.НачатьЗапись(Undefined, ДиалогВыбораФайла.ПолноеИмяФайла,
				ТипФайлаТабличногоДокумента.MXL);
		ElsIf нРег(ФайлНаДиске.Расширение) = ".xls" Then
			SpreadsheetDocument.НачатьЗапись(Undefined, ДиалогВыбораФайла.ПолноеИмяФайла,
				ТипФайлаТабличногоДокумента.XLS);
		ElsIf нРег(ФайлНаДиске.Расширение) = ".txt" Then
			SpreadsheetDocument.НачатьЗапись(Undefined, ДиалогВыбораФайла.ПолноеИмяФайла,
				ТипФайлаТабличногоДокумента.TXT);
		EndIf;

	EndIf;

EndProcedure

&НаКлиенте
Procedure RefreshCommand(Команда)
	ОбновитьДанныеТабличногоДокумента(Undefined);
EndProcedure

&НаКлиенте
Procedure FillControlCommand(Команда)
	КонтрольЗаполненияСервер();
EndProcedure

&НаКлиенте
Procedure NextNoteCommand(Команда)
	
	//SpreadsheetDocument = Элементы.SpreadsheetDocument;

	Нашли = False;

	Колонка = SpreadsheetDocument.ТекущаяОбласть.Лево + 1;
	Строка  = SpreadsheetDocument.ТекущаяОбласть.Верх;

	Пока Не Нашли И Строка <= SpreadsheetDocument.ВысотаТаблицы Do

		Пока Не Нашли И Колонка <= SpreadsheetDocument.ШиринаТаблицы Do

			Область = SpreadsheetDocument.Область("R" + Формат(Строка, "ЧГ=") + "C" + Формат(Колонка, "ЧГ="));
			Нашли = Не IsBlankString(Область.Примечание.Текст);

			Колонка = Колонка + 1;
		EndDo;
		Строка = Строка + 1;
		Колонка = 1;
	EndDo;

	If Нашли Then
		SpreadsheetDocument.ТекущаяОбласть = Область;
	Else
		Сообщить("Достигнут конец документа", СтатусСообщения.Информация);
	EndIf;

EndProcedure

&НаКлиенте
Procedure PreviousNoteCommand(Команда)
	
	//SpreadsheetDocument = Элементы.SpreadsheetDocument;

	Нашли = False;

	Колонка = SpreadsheetDocument.ТекущаяОбласть.Лево - 1;
	Строка  = SpreadsheetDocument.ТекущаяОбласть.Верх;

	Пока Не Нашли И Строка > 0 Do

		Пока Не Нашли И Колонка > 0 Do

			Область = SpreadsheetDocument.Область("R" + Формат(Строка, "ЧГ=") + "C" + Формат(Колонка, "ЧГ="));
			Нашли = Не IsBlankString(Область.Примечание.Текст);

			Колонка = Колонка - 1;
		EndDo;
		Строка = Строка - 1;
		Колонка = SpreadsheetDocument.ШиринаТаблицы;
	EndDo;

	If Нашли Then
		SpreadsheetDocument.ТекущаяОбласть = Область;
	Else
		Сообщить("Достигнуто начало документа", СтатусСообщения.Информация);
	EndIf;

EndProcedure

&НаКлиенте
Procedure RestoreValuesFromFileCommand(Команда)

	ДиалогВыбораФайла = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Открытие);
	ДиалогВыбораФайла.Заголовок	= "Восстановить значения из файла";
	ДиалогВыбораФайла.Фильтр	= "Настройка загрузки в табличный документ (*.mxlz)|*.mxlz|Все файлы (*.*)|*.*|";

	ДиалогВыбораФайла.Показать(Новый ОписаниеОповещения("КомандаВосстановитьЗначенияИзФайлаЗавершение1", ЭтаФорма,
		Новый Структура("ДиалогВыбораФайла", ДиалогВыбораФайла)));

EndProcedure

&НаКлиенте
Procedure КомандаВосстановитьЗначенияИзФайлаЗавершение1(ВыбранныеФайлы, ДополнительныеПараметры) Export

	ДиалогВыбораФайла = ДополнительныеПараметры.ДиалогВыбораФайла;
	If (ВыбранныеФайлы <> Undefined) Then
		Настройки = мПрочитатьНастройкиИзФайла(ДиалогВыбораФайла.ПолноеИмяФайла);
		ЗаполнитьНастройкиКолонок(Настройки);
		SetTabularSectionsList();
		ОбновитьДанныеТабличногоДокумента(Новый ОписаниеОповещения("КомандаВосстановитьЗначенияИзФайлаЗавершение",
			ЭтаФорма), True);
	Else
		КомандаВосстановитьЗначенияИзФайлаФрагмент();
	EndIf;

EndProcedure

&НаКлиенте
Procedure КомандаВосстановитьЗначенияИзФайлаЗавершение(Результат, ДополнительныеПараметры) Export

	КомандаВосстановитьЗначенияИзФайлаФрагмент();

EndProcedure

&НаКлиенте
Procedure КомандаВосстановитьЗначенияИзФайлаФрагмент()

	УправлениеВидимостью();

EndProcedure

&НаКлиенте
Procedure SaveValuesToFileCommand(Команда)

	Настройки = ПолучитьНастройки();
	If Настройки = Undefined Then
		Return;
	EndIf;

	ДиалогВыбораФайла = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Сохранение);

	ДиалогВыбораФайла.Заголовок = "Сохранить значения настройки в файл";
	ДиалогВыбораФайла.Фильтр    = "Настройка загрузки в табличный документ (*.mxlz)|*.mxlz|Все файлы (*.*)|*.*|";
	ДиалогВыбораФайла.Показать(Новый ОписаниеОповещения("КомандаСохранитьЗначенияВФайлЗавершение", ЭтаФорма,
		Новый Структура("ДиалогВыбораФайла, Настройки", ДиалогВыбораФайла, Настройки)));

EndProcedure

&НаКлиенте
Procedure КомандаСохранитьЗначенияВФайлЗавершение(ВыбранныеФайлы, ДополнительныеПараметры) Export

	ДиалогВыбораФайла = ДополнительныеПараметры.ДиалогВыбораФайла;
	Настройки = ДополнительныеПараметры.Настройки;
	If (ВыбранныеФайлы <> Undefined) Then

		Настройки.НачатьЗапись(Undefined, ДиалогВыбораФайла.ПолноеИмяФайла);

	EndIf;

EndProcedure

&НаКлиенте
Procedure RestoreValuesCommand(Команда)

	ФормаВыбораНастройки = ПолучитьФорму(DataProcessorID() + ".Форма.ФормаВыбораНастройки", , ЭтаФорма);
	ФормаВыбораНастройки.СписокНастроек = СписокСохраненныхНастроек;
	ТекущиеДанные = ФормаВыбораНастройки.Открыть();
	If Не ТекущиеДанные = Undefined Then
		ЗаполнитьНастройкиКолонок(ТекущиеДанные.Значение);
	EndIf;

	mSaveValue(DataProcessorID(), ФормаВыбораНастройки.СписокНастроек);

EndProcedure

&НаКлиенте
Procedure SaveValuesCommand(Команда)

	ФормаСохраненияНастройки = ПолучитьФорму(DataProcessorID() + ".Форма.ФормаСохраненияНастройки", , ЭтаФорма);
	If Не СписокСохраненныхНастроек.Количество() = 0 Then
		//ФормаСохраненияНастройки.СписокНастроек = СписокСохраненныхНастроек;
		For Each Стр Из СписокСохраненныхНастроек Do

			НовСтр = ФормаСохраненияНастройки.СписокНастроек.Добавить();
			НовСтр.Check = Стр.Check;
			НовСтр.Представление = Стр.Представление;

		EndDo;
	EndIf;

	ТекущиеДанные = ФормаСохраненияНастройки.Открыть();

	If Не ТекущиеДанные = Undefined Then
		
		//ПолучитьНастройкиСписком(ТекущиеДанные.Значение);
		//СкопироватьНастройки(ФормаСохраненияНастройки.СписокНастроек);
		//УстановитьТекущиеНастройки(СписокСохраненныхНастроек, ТекущиеДанные.Check, ТекущиеДанные.Представление, ПолучитьСтруктуруНастроек());
		mSaveValue(DataProcessorID(), СписокСохраненныхНастроек);

	EndIf;

EndProcedure

&НаКлиенте
Procedure RereadCommand(Команда)
	ЗаполнитьНастройкиКолонок(Undefined);
EndProcedure

&НаКлиенте
Procedure CheckAllCommand(Команда)
	For Each ЗагружаемыйРеквизит Из ImportedAttributesTable Do
		ЗагружаемыйРеквизит.Check = True;
	EndDo;
EndProcedure

&НаКлиенте
Procedure UncheckAllCommand(Команда)
	For Each ЗагружаемыйРеквизит Из ImportedAttributesTable Do
		ЗагружаемыйРеквизит.Check = False;
	EndDo;
EndProcedure

&НаКлиенте
Procedure ManualSpreadsheetDocumentColumnsNumerationCommand(Команда)
	Элементы.ManualSpreadsheetDocumentColumnsNumeration.Check = Не Элементы.ManualSpreadsheetDocumentColumnsNumeration.Check;
	Object.ManualSpreadsheetDocumentColumnsNumeration = Элементы.ManualSpreadsheetDocumentColumnsNumeration.Check;
	УправлениеВидимостью();
EndProcedure

&НаКлиенте
Procedure RenumberColumnsCommand(Команда)
	НомерКолонки = 1;
	For Each Реквизит Из ImportedAttributesTable Do
		If Реквизит.Check Then
			If Не Реквизит.ColumnNumber = НомерКолонки Then
				Реквизит.ColumnNumber = НомерКолонки;
			EndIf;
			НомерКолонки = НомерКолонки + 1;
		Else
			Реквизит.ColumnNumber = 0;
		EndIf;

		If Реквизит.ColumnNumber = 0 И Реквизит.ImportMode = "Искать" Then
			Реквизит.ImportMode = "Устанавливать";
		ElsIf Не Реквизит.ColumnNumber = 0 И Реквизит.ImportMode = "Устанавливать" Then
			Реквизит.ImportMode = "Искать";
		EndIf;

	EndDo;
EndProcedure

&НаКлиенте
Procedure EventsCommand(Команда)

	ФормаРедактированиеСобытий = ПолучитьФорму(DataProcessorID() + ".Форма.ФормаРедактированияСобытий", ,
		ЭтаФорма);

	ФормаРедактированиеСобытий.ImportMode = Object.ImportMode;

	ФормаРедактированиеСобытий.BeforeWriteObject.УстановитьТекст(Object.BeforeWriteObject);
	ФормаРедактированиеСобытий.OnWriteObject.УстановитьТекст(Object.OnWriteObject);
	ФормаРедактированиеСобытий.AfterAddRow.УстановитьТекст(Object.AfterAddRow);

	ФормаРедактированиеСобытий.Открыть();

	If True = True Then

		Object.BeforeWriteObject   = ФормаРедактированиеСобытий.BeforeWriteObject.ПолучитьТекст();
		Object.OnWriteObject      = ФормаРедактированиеСобытий.OnWriteObject.ПолучитьТекст();
		Object.AfterAddRow = ФормаРедактированиеСобытий.AfterAddRow.ПолучитьТекст();

	EndIf;

EndProcedure

//@skip-warning
&НаКлиенте
Procedure Attachable_ExecuteToolsCommonCommand(Команда) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ЭтотОбъект, Команда);
EndProcedure



///////////////////////////////////////////////////////////////////////////////
// ПРЕДОПРЕДЕЛЁННЫЕ ОБРАБОТЧИКИ ФОРМЫ

&AtServer
Procedure ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)

	For Each МДСправочник Из Метаданные.Справочники Do
		Элементы.ObjectType.СписокВыбора.Добавить(МДСправочник.Имя, МДСправочник.Синоним);
	EndDo;
	МДНезависимый = Метаданные.СвойстваОбъектов.РежимЗаписиРегистра.Независимый;
	For Each МДРегистрСведений Из Метаданные.РегистрыСведений Do
		If МДРегистрСведений.РежимЗаписи = МДНезависимый Then
			Элементы.RegisterTypeName.СписокВыбора.Добавить(МДРегистрСведений.Имя, МДРегистрСведений.Синоним);
		EndIf;
	EndDo;

	Типы = Новый Массив;
	ВидыТипов = Новый Структура("Справочники,Документы");
	For Each КлючИЗначение Из ВидыТипов Do
		For Each ОбъектМетаданных Из Метаданные[КлючИЗначение.Ключ] Do
			If ОбъектМетаданных.ТабличныеЧасти.Количество() Then
				Типы.Добавить(Тип(СтрЗаменить(ОбъектМетаданных.ПолноеИмя(), ".", "Ссылка.")));
			EndIf;
		EndDo;
	EndDo;

	Элементы.SourceRef.ОграничениеТипа = Новый ОписаниеТипов(Типы);

	Object.ImportMode           = mRestoreValue("ImportMode");
	Object.RegisterTypeName         = mRestoreValue("RegisterTypeName");
	Object.CatalogObjectType   = mRestoreValue("CatalogObjectType");
	Object.SourceRef         = mRestoreValue("SourceRef");

	SetTabularSectionsList();

	ТабличнаяЧастьИсточника = mRestoreValue("SourceTabularSection");

	Инициализация();

	УстановитьИсточник();

	ОбновитьДанныеТабличногоДокументаСервер();
	
	UT_Common.ToolFormOnCreateAtServer(ЭтотОбъект, Отказ, СтандартнаяОбработка);

EndProcedure

&НаКлиенте
Procedure ПриОткрытии(Отказ)
	СисИнфо = Новый СистемнаяИнформация;
	If Лев(СисИнфо.ВерсияПриложения, 3) = "8.3" Then
		Выполнить ("Элементы.SourceRef.ОтображениеКнопкиВыбора = ОтображениеКнопкиВыбора.ОтображатьВПолеВвода;");
		Выполнить ("Элементы.ТаблицаЗагружаемыхРеквизитовЗначениеПоУмолчанию.ОтображениеКнопкиВыбора = ОтображениеКнопкиВыбора.ОтображатьВПолеВвода;");
	EndIf;

	УправлениеВидимостью();
EndProcedure

&НаКлиенте
Procedure ПриЗакрытии()
	ПриЗакрытииНаСервере();
EndProcedure


///////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ ЭЛЕМЕНТОВ ФОРМЫ

&НаКлиенте
Procedure ImportModeOnChange(Элемент)
	Object.CatalogObjectType	= Undefined;
	Object.SourceRef			= Undefined;
	Object.RegisterTypeName			= Undefined;
	Object.SourceTabularSection	= Undefined;
	SetTabularSectionsList();
	УстановитьИсточник();
	УправлениеВидимостью();
EndProcedure

&НаКлиенте
Procedure ObjectTypeOnChange(Элемент)
	УстановитьИсточник();
	УправлениеВидимостью();
EndProcedure

&НаКлиенте
Procedure ObjectTypeOpening(Элемент, СтандартнаяОбработка)
	СтандартнаяОбработка = False;
	If IsBlankString(Object.CatalogObjectType) Then
		Return;
	EndIf;

	Форма = ПолучитьФорму("Справочник." + Object.CatalogObjectType + ".ФормаСписка");
	Форма.Открыть();
EndProcedure

&НаКлиенте
Procedure SourceRefOnChange(Элемент)
	SetTabularSectionsList();
	УстановитьИсточник();
EndProcedure

&НаКлиенте
Procedure SourceTabularSectionOnChange(Элемент)
	УстановитьИсточник();
	УправлениеВидимостью();
EndProcedure

&НаКлиенте
Procedure RegisterTypeNameOnChange(Элемент)
	УстановитьИсточник();
	УправлениеВидимостью();
EndProcedure

&НаКлиенте
Procedure RegisterTypeNameOpening(Элемент, СтандартнаяОбработка)
	СтандартнаяОбработка = False;
	If IsBlankString(Object.RegisterTypeName) Then
		Return;
	EndIf;

	Форма = ПолучитьФорму("РегистрСведений." + Object.RegisterTypeName + ".ФормаСписка");
	Форма.Открыть();
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ ТАБЛИЦЫ ЗНАЧЕНИЙ ЗАГРУЖАЕМЫХ РЕКВИЗИТОВ

&НаКлиенте
Procedure ImportedAttributesTableTypeDescriptionStartChoice(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	ТекДанные = Элементы.ImportedAttributesTable.ТекущиеДанные;
	Элемент.AvailableTypes = ТекДанные.AvailableTypes;
EndProcedure

&НаКлиенте
Procedure ImportedAttributesTableAdditionalConditionsPresentationStartChoice(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	ТекДанные = Элементы.ImportedAttributesTable.ТекущиеДанные;
	СтандартнаяОбработка = False;
	If ТекДанные.ImportMode = "Вычислять" Then
		ФормаРедактированияВыражения = ПолучитьФорму(DataProcessorID() + ".Форма.ФормаРедактированияВыражения", ,
			ЭтаФорма);

		ПолеТекстовогоДокумента = ФормаРедактированияВыражения.ПолеТекстовогоДокумента;
		ПолеТекстовогоДокумента.УстановитьТекст(ТекДанные.Выражение);

		ФормаРедактированияВыражения.Открыть();
		//If ФормаРедактированияВыражения.Open() = True Then
		//	ТекДанные.Expression = ПолеТекстовогоДокумента.ПолучитьТекст();
		//EndIf;
	Else
		ДоступныеТипы	= ТекДанные.TypeDescription;
		СписокВыбораВладельца	= ПолучитьСписокВыбораСвязиПоВладельцу(ТекДанные.AttributeName);
		ФормаРедактированияСвязи = ПолучитьФорму(DataProcessorID() + ".Форма.ФормаРедактированияСвязи", ,
			ЭтаФорма);
		ФормаРедактированияСвязи.ИспользуемыеТипы = ДоступныеТипы;
		ФормаРедактированияСвязи.SearchBy = ТекДанные.SearchBy;
		ФормаРедактированияСвязи.ИспользоватьВладельца = (СписокВыбораВладельца.Количество() > 0);
		ФормаРедактированияСвязи.LinkByOwner = ТекДанные.LinkByOwner;

		СписокВыбораИскатьПо = ПолучитьСписокИменПредставлений(ТекДанные.ОписаниеТипов);
		Сп = ФормаРедактированияСвязи.Элементы.SearchBy.СписокВыбора;
		Сп.Очистить();
		For Each ЭлСписка Из СписокВыбораИскатьПо Do
			Сп.Добавить(ЭлСписка.Значение, ЭлСписка.Представление);
		EndDo;

		Сп = ФормаРедактированияСвязи.Элементы.LinkByOwner.СписокВыбора;
		Сп.Очистить();
		For Each ЭлСписка Из СписокВыбораВладельца Do
			Сп.Добавить(ЭлСписка.Значение, ЭлСписка.Представление);
		EndDo;
		ФормаРедактированияСвязи.Открыть();
		//If ФормаРедактированияСвязи.Open() = True Then
		//	ТекДанные.SearchBy = ФормаРедактированияСвязи.SearchBy;
		//	ТекДанные.LinkByOwner = ФормаРедактированияСвязи.LinkByOwner;
		//EndIf;
	EndIf;
	//If ТекДанные.ImportMode = "Вычислять" Then
	//	ТекДанные.AdditionalConditionsPresentation = ТекДанные.Expression;
	//Else
	//	ТекДанные.AdditionalConditionsPresentation = ?(IsBlankString(ТекДанные.SearchBy), "", "Искать по "+ТекДанные.SearchBy)
	//			+?(IsBlankString(ТекДанные.LinkByOwner), "", " по владельцу "+ТекДанные.LinkByOwner);
	//EndIf;
EndProcedure

&НаКлиенте
Procedure ImportedAttributesTableAdditionalConditionsPresentationClearing(Элемент, СтандартнаяОбработка)
	ТекДанные = Элементы.ImportedAttributesTable.ТекущиеДанные;
	ТекДанные.AdditionalConditionsPresentation = "";
	ТекДанные.SearchBy = "";
	ТекДанные.LinkByOwner = "";
EndProcedure

&НаКлиенте
Procedure ImportedAttributesTableImportModeOnChange(Элемент)
	ТекДанные = Элементы.ImportedAttributesTable.ТекущиеДанные;
	If ТекДанные.ImportMode = "Вычислять" Then
		ТекДанные.AdditionalConditionsPresentation = ТекДанные.Expression;
	Else
		ТекДанные.AdditionalConditionsPresentation = ?(IsBlankString(ТекДанные.SearchBy), "", "Искать по " + ТекДанные.SearchBy)
			+ ?(IsBlankString(ТекДанные.СвязьПоВладельцу), "", " по владельцу " + ТекДанные.LinkByOwner);
	EndIf;
EndProcedure

&НаКлиенте
Procedure ОбработкаВыбора(ВыбранноеЗначение, ИсточникВыбора)
	If ТипЗнч(ВыбранноеЗначение) = Тип("Структура") Then

		If ВыбранноеЗначение.Источник = "ФормаРедактированияСобытий" И ВыбранноеЗначение.Результат = True Then
			Object.BeforeWriteObject		= ВыбранноеЗначение.BeforeWriteObject;
			Object.OnWriteObject			= ВыбранноеЗначение.OnWriteObject;
			Object.AfterAddRow	= ВыбранноеЗначение.AfterAddRow;
		ElsIf ВыбранноеЗначение.Источник = "ФормаРедактированияВыражения" И ВыбранноеЗначение.Результат = True Then
			ТекДанные = Элементы.ImportedAttributesTable.ТекущиеДанные;
			ТекДанные.Expression = ВыбранноеЗначение.Expression;
			ТекДанные.AdditionalConditionsPresentation = ТекДанные.Expression;
		ElsIf ВыбранноеЗначение.Источник = "ФормаРедактированияСвязи" И ВыбранноеЗначение.Результат = True Then
			ТекДанные = Элементы.ImportedAttributesTable.ТекущиеДанные;
			ТекДанные.SearchBy = ВыбранноеЗначение.SearchBy;
			ТекДанные.LinkByOwner = ВыбранноеЗначение.LinkByOwner;
			ТекДанные.AdditionalConditionsPresentation = ?(IsBlankString(ТекДанные.SearchBy), "", "Искать по "
				+ ТекДанные.SearchBy) + ?(IsBlankString(ТекДанные.СвязьПоВладельцу), "", " по владельцу "
				+ ТекДанные.LinkByOwner);
		EndIf;

	EndIf;
EndProcedure
