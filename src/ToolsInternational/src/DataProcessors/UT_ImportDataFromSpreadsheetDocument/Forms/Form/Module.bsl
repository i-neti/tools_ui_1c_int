
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

// Checks if folders are available for metadata type.
//
// Parameters:
//  SourceMetadata - Metadata - object metadata.
//
// Return value:
//  Boolean - True, if folders are available.
//
&AtServer
Function FolderCreationEnabled(Val SourceMetadata)
	
	Return SourceMetadata.Hierarchical 
			And SourceMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems;

EndFunction // ()

// Evaluates cell value for Evaluate mode.
//
// Parameters:
//  Expression - String - a code to execute.
//  CurrentData  - Structure - imported values.
//  CellText    - String - a text of a current cell.
//  CellsTexts    - Array - a texts of a current row cells.
//  Result      - Arbitrary - a result of a code execution.
//
// Return value:
//  Structure - Result and ErrorDescription.
//
&AtServerNoContext
Function EvaluateCellValue(Val Expression, Val CurrentData, Val CellText, Val CellsTexts, Val Result)

	CellText = TrimAll(CellText);
	ErrorDescription = "";
	Try
		Execute (Expression);
	Except
		mErrorMessage(ErrorDescription());
	EndTry;

	Return New Structure("Result,ErrorDescription", Result, ErrorDescription);

EndFunction

// Writes an object to the infodatabase
// using events defined by the user in the event edit form.
//
// Parameters:
//  Object - CatalogObject, DocumentObject, etc - an object to write.
//  CellsTexts - Array - a texts of a imported row cells.
//  BeforeWriteObject - String - before write event handler.
//  OnWriteObject - String - on write event handler.
//
// Return value:
//  Boolean - True, If object successfully written, False - if there was an error.
//
&AtServerNoContext
Function WriteObject(Object, CellsTexts = Undefined, BeforeWriteObject, OnWriteObject)

	Cancel = False;
	BeginTransaction();
	If Not IsBlankString(BeforeWriteObject) Then
		Try
			Execute (BeforeWriteObject);
			If Cancel Then
				ErrorDescription = "";//Cancel was set to True in the BeforeWriteObject event handler
			EndIf;
		Except
			Cancel = True;
			ErrorDescription = ErrorDescription();
		EndTry;
	EndIf;

	If Not Cancel Then
		Try
			Object.Write();
		Except
			Cancel = True;
			ErrorDescription = ErrorDescription();
		EndTry;
	EndIf;

	If Not Cancel And Not IsBlankString(OnWriteObject) Then

		Try
			Execute (OnWriteObject);
			If Cancel Then
				ErrorDescription = "";//Cancel was set to True in the OnWriteObject event handler
			EndIf;

		Except
			Cancel = True;
			ErrorDescription = ErrorDescription();
		EndTry;

		If Not Cancel Then
			Try
				Object.Write();
			Except
				Cancel = True;
				ErrorDescription = ErrorDescription();
			EndTry;
		EndIf;

	EndIf;

	If Not Cancel Then
		CommitTransaction();
	Else
		mErrorMessage(ErrorDescription);
		RollbackTransaction();
	EndIf;

	Return Not Cancel;

EndFunction // ()

// Executes the AfterAddRow event handler
// defined by the user in the event edit form.
//
// Parameters:
//  Object - CatalogObject, DocumentObject, etc - an object to write.
//  CurrentData  - Structure - imported values.
//  CellsTexts    - Array - a texts of a current row cells.
//  AfterAddRow - String - after add row event handler.
//
// Return value:
//  True, If Cancel was not set in the AfterAddRow event handler.
//
&AtServerNoContext
Function AfterAddRowEventHandler(Object, CurrentData, CellsTexts, AfterAddRow)

	Try

		Execute (AfterAddRow);

	Except

		mErrorMessage(ErrorDescription());
		Return False;

	EndTry;

	Return True;

EndFunction // ()

////////////////////////////////////////////////////////////////////////////////
//

// Controls a spreadsheet document data filling.
// Messages an errors and sets an error cells comments.
//
// Parameters:
//  SpreadsheetDocument - spreadsheet document to generate the header.
//
&AtServer
Procedure FillControl(SpreadsheetDocument) Export

	ItemCount = SpreadsheetDocument.TableHeight - Object.SpreadsheetDocumentFirstDataRow + 1;

	ErrorCount = 0;
	For K = 0 To ItemCount - 1 Do
		//Status(UT_StringFunctionsClientServer.SubstituteParametersToString(
		//NStr("ru = 'Выполняется контроль заполнения строки № %1'; en = 'Row no. %1 fill control is in progress.'"), (К + 1)));
		RowFillControl(SpreadsheetDocument, K + Object.SpreadsheetDocumentFirstDataRow, ,
			ErrorCount);
	EndDo;

	Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Контроль заполнения завершен. Проверено строк: %1'; en = 'Fill control completed. %1 rows was checked.'"), ItemCount));
	If ErrorCount Then
		Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выявлено ячеек, содержащих ошибки/неоднозначное представление: %1'; en = '%1 cells with errors/ambiguous presentation was found.'"), ErrorCount));
	Else
		Message(NStr("ru = 'Ячеек, содержащих ошибки не выявлено'; en = 'No error cell was found.'"));
	EndIf;

EndProcedure // FillControl()

// Controls a spreadsheet document row data filling.
// Messages an errors and writes an error cells comments.
//
// Параметры:
//  SpreadsheetDocument - spreadsheet document to generate the header.
//  RowNumber       - Number - spreadsheet document row number.
//  CellsTexts    - Array - a texts of a row cells.
//  ErrorCount 	- Number - a count of errors.
//
// Return value:
//  Structure - 
//  	Key - imported attrubure name.
//  	Value - imported attribute value.
//
&AtServer
Function RowFillControl(SpreadsheetDocument, RowNumber, CellsTexts = Undefined, ErrorCount = 0)

	CellsTexts = New Array;
	CellsTexts.Add(Undefined);
	For K = 1 To SpreadsheetDocument.TableWidth Do
		CellsTexts.Add(TrimAll(SpreadsheetDocument.Area("R" + Format(RowNumber, "NG=") + "C" + Format(K,
			"NG=")).Text));
	EndDo;

	Columns = Object.AdditionalProperties.Columns;

	CurrentRow     = New Structure;
	For Each KeyValue In Columns Do

		Column = KeyValue.Value;

		If Column.Check Then

			If Column.ImportMode = "Set" Then

				Result = Column.DefaultValue;
				CurrentRow.Insert(Column.AttributeName, Result);

			ElsIf Not Column.ColumnNumber = 0 Then

				If Not ProcessArea(SpreadsheetDocument.Area("R" + Format(RowNumber, "NG=") + "C" + Format(
					Column.ColumnNumber, "NG=")), Column, CurrentRow, CellsTexts) Then
					ErrorCount = ErrorCount + 1;
				EndIf;

			ElsIf Column.ImportMode = "Evaluate" Then

				Evaluation  = EvaluateCellValue(Column.Expression, CurrentRow, "", CellsTexts,
					Column.DefaultValue);
				Result   = Evaluation.Result;
				Note  = Evaluation.ErrorDescription;

				If Not ValueIsFilled(Result) Then
					Result = Column.DefaultValue;
				EndIf;

				CurrentRow.Insert(Column.AttributeName, Result);

				If Not IsBlankString(Note) Then
					Message(NStr("ru = 'Строка ['; en = 'Row ['") + RowNumber + "](" + Column.AttributePresentation + "): " + Note);
					ErrorCount = ErrorCount + 1;
				EndIf;

			EndIf;

		EndIf;

	EndDo;
	Return CurrentRow;

EndFunction

// Processes a spreadsheet document area:
// fills the details by the cell presentation according to imported attributes structure.
// If the cell contains an error, messages an error and writes a comment.
//
// Parameters:
//  Area - SpreadsheetDocumentRange - spreadsheet document cells range.
//  Column - Structure - properties, according to which the processing will be executed.
//  CurrentData  - Structure - imported values.
//  CellsTexts    - Array - a texts of a row cells.
//
&AtServer
Function ProcessArea(Area, Column, CurrentData, CellsTexts)

	Presentation = Area.Text;
	Note = "";

	If Column.ImportMode = "Evaluate" Then

		Evaluation = EvaluateCellValue(Column.Expression, CurrentData, Presentation, CellsTexts,
			Column.DefaultValue);
		If Not IsBlankString(Evaluation.ErrorDescription) Then
			Result   = Undefined;
			Note = "" + Evaluation.ErrorDescription;
		Else
			Result = Evaluation.Result;
		EndIf;

	ElsIf IsBlankString(Presentation) Then
		Result = Undefined;
	Else
		FoundValues = GetPossibleValues(Column, Presentation, Note, CurrentData);

		If FoundValues.Count() = 0 Then

			Note = NStr("ru = 'Не найден'; en = 'Not found'") + ?(Note = "", "", Chars.LF + Note);
			Result = Undefined;

		ElsIf FoundValues.Count() = 1 Then

			Result = FoundValues[0];
		Else

			Note = UT_StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не однозначное представление. Вариантов: %1'; en = 'Ambiguous presentation. %1 options.'"), FoundValues.Количество()) + 
				?(Note = "", "", Chars.LF + Note);

			Found = False;
			FoundDefaultValue = False;
			For Each FoundValue In FoundValues Do
				If FoundValue = Area.Details Then
					Found = True;
					Break;
				EndIf;
				If FoundValue = Column.DefaultValue Then
					FoundDefaultValue = True;
				EndIf;
			EndDo;

			If Not Found Then

				If FoundDefaultValue Then
					FoundValue = Column.DefaultValue;
				Else
					FoundValue = FoundValues[0];
				EndIf;
			EndIf;
			Result = FoundValue;
		EndIf;
	EndIf;

	If Not ValueIsFilled(Result) Then
		Result = Column.DefaultValue;
	EndIf;

	CurrentData.Insert(Column.AttributeName, Result);

	Area.Details = Result;
	Area.Note.Text = Note;

	If Не IsBlankString(Note) Then
		Message(NStr("ru = 'Ячейка['; en = 'Cell['") + Area.Name + "](" + Column.AttributePresentation + "): " + Note);
	EndIf;

	Return IsBlankString(Note);

EndFunction

// Returns an array of current row possible values by presentation.
//
// Parameters:
//  Column - Structure - properties, according to which the possible values will be getting.
//  Presentation - String - string, by which the possible values will be getting.
//  Note    - Array - a texts of a row cells.
//  CurrentData  - Structure - imported values.
//
// Return value:
//  Array of possible values.
//
&AtServer
Function GetPossibleValues(Column, Presentation, Note, CurrentData)
	Note = "";

	FoundValues = New Array;

	If IsBlankString(Presentation) Then

		Return FoundValues;

	Else
		LinkByType = Undefined;
		If Not IsBlankString(Column.LinkByType) Then

			If TypeOf(Column.LinkByType) = Type("String") Then
				CurrentData.Property(Column.LinkByType, LinkByType);
			Else
				LinkByType = Column.LinkByType;
			EndIf;
			If Not LinkByType = Undefined Then

				LinkByTypeItem = Column.LinkByTypeItem;
				If LinkByTypeItem = 0 Then
					LinkByTypeItem = 1;
				EndIf;
				ExtDimensionTypes = LinkByType.ExtDimensionTypes;
				If LinkByTypeItem > ExtDimensionTypes.Count() Then
					Return FoundValues;
				EndIf;
				Type = LinkByType.ExtDimensionTypes[LinkByTypeItem - 1].ExtDimensionType.ValueType;
			Else
				Type = Column.TypeDescription;
			EndIf;

		Else
			Type = Column.TypeDescription;
		EndIf;
	EndIf;
	PrimitiveTypes = New Structure("Number, String, Date, Boolean", Type("Number"), Type("String"), Type("Date"), Type(
		"Boolean"));
	For Each AttributeType In Type.Types() Do

		If AttributeType = PrimitiveTypes.Number Or AttributeType = PrimitiveTypes.Boolean Then
			FoundValues.Add(mAdjustToNumber(Presentation, Column.TypeDescription, Note));
		ElsIf AttributeType = PrimitiveTypes.String Или AttributeType = PrimitiveTypes.Date Then
			FoundValues.Add(mAdjustToDate(Presentation, Column.TypeDescription, Note));

		Else

			TypeMetadata = Metadata.FindByType(AttributeType);

			If Enums.AllRefsType().ContainsType(AttributeType) Then
				
				//Enumeration
				For Each Enum In GetManagerByType(AttributeType) Do
					If String(Enum) = Presentation Then
						FoundValues.Add(Enum);
					EndIf;
				EndDo;

			ElsIf Documents.AllRefsType().ContainsType(AttributeType) Then
				
				//Document

				Manager = GetManagerByType(AttributeType);
				If Column.SearchBy = "Number" Then
					//FoundValue = Manager.FindByCode(Presentation);
				ElsIf Column.SearchBy = "Date" Then
					//FoundValue = Manager.Find
				Else

					SynonymLength = StrLen("" + TypeMetadata);

					If Left(Presentation, SynonymLength) = "" + TypeMetadata Then
						NumberAndDate = TrimAll(Mid(Presentation, SynonymLength + 1));
						PositionFrom = Find(NumberAndDate, NStr("ru = ' от '; en = ' from '"));
						If Not PositionFrom = 0 Then
							DocNumber = Left(NumberAndDate, PositionFrom - 1);
							Try
								DocDate  = Date(Mid(NumberAndDate, PositionFrom + 4));
							Except
								DocDate = Undefined;
							EndTry;
							If Not DocDate = Undefined Then
								FoundValue = Manager.FindByNumber(DocNumber, DocDate);
								If Not FoundValue.IsEmpty() Then
									FoundValues.Add(FoundValue);
								EndIf;
							EndIf;
						EndIf;
					EndIf;

				EndIf;

			ElsIf Not TypeMetadata = Undefined Then

				SearchBy = Column.SearchBy;
				IsCatalog = Catalogs.AllRefsType().ContainsType(AttributeType);
				If IsBlankString(SearchBy) Then
					DefaultPresentationString = String(TypeMetadata.DefaultPresentation);

					If DefaultPresentationString = "AsCode" Then
						SearchBy = "Code";
					ElsIf DefaultPresentationString = "AsDescription" Then
						SearchBy = "Description";
					ElsIf DefaultPresentationString = "AsNumber" Then
						SearchBy = "Number";
					EndIf;
				EndIf;
				Query = New Query;
				Query.Text = "SELECT
							 |	_Table.Ref
							 |FROM
							 |	" + TypeMetadata.FullName() + " AS _Table
															  |WHERE";

				Query.Text = Query.Text + "
											  |	Table." + SearchBy + " = &Presentation";
				Query.SetParameter("Presentation", Presentation);

				If IsCatalog And Not IsBlankString(Column.LinkByOwner) And TypeMetadata.Owners.Count() Then

					LinkByOwner = Undefined;
					If TypeOf(Column.LinkByOwner) = Type("String") Then
						CurrentData.Property(Column.LinkByOwner, LinkByOwner);
					Else
						LinkByOwner = Column.LinkByOwner;
					EndIf;

					If Not LinkByOwner = Undefined Then
						Query.Text = Query.Text + "
													  |	AND _Table.Owner = &LinkByOwner";
						Query.SetParameter("LinkByOwner", LinkByOwner);
					EndIf;

				EndIf;

				Selection =  Query.Execute().Select();

				While Selection.Next() Do
					FoundValues.Add(Selection.Ref);
				EndDo;
			Else
				Note = NStr("ru = 'Не описан способ поиска'; en = 'Search type is not defined.'");
				Note = NStr("ru = 'Для Колонки не определен тип значения'; en = 'Column value type is not defined.'");
			EndIf;
		EndIf;

	EndDo;
	Return FoundValues;
EndFunction // ()

////////////////////////////////////////////////////////////////////////////////
//

// Returns an array of imported attribute possible presentations.
//
// Parameters:
//  TypeDescription - Type description.
//
// Return value:
//  Value list - presentations.
//
&AtServer
Function GetNamePresentationList(TypeDescription)

	ChioceList = New ValueList;
	If TypeDescription.Types().Count() = 1 Then

		Type = TypeDescription.Types()[0];

		TypeMetadata      = Метаданные.НайтиПоТипу(Type);
		IsCatalog       = Catalogs.AllRefsType().ContainsType(Type);
		IsAccount             = ChartsOfAccounts.AllRefsType().ContainsType(Type);
		IsCharacteristicType = ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type);
		If IsCatalog Or IsAccount Or IsCharacteristicType Then

			CodeExists = TypeMetadata.CodeLength > 0;
			NameExists = TypeMetadata.DescriptionLength > 0;

			DefaultPresentationType = ?(IsCatalog, Metadata.ObjectProperties.CatalogMainPresentation,
				?(IsAccount, Metadata.ObjectProperties.AccountMainPresentation,
				Metadata.ObjectProperties.CharacteristicTypeMainPresentation));

			If TypeMetadata.DefaultPresentation = DefaultPresentationType.AsCode Then

				If CodeExists Then
					ChioceList.Add("Code", "Code");
				EndIf;

				If NameExists Then
					ChioceList.Add("Description", "Description");
				EndIf;

			Else

				If NameExists Then
					ChioceList.Add("Description", "Description");
				EndIf;

				If CodeExists Then
					ChioceList.Add("Code", "Code");
				EndIf;

			EndIf;

			For Each Attribute In TypeMetadata.Attributes Do

				If Not Attribute.Indexing = Metadata.ObjectProperties.Indexing.DontIndex
					And Attribute.Type.Types().Count() = 1 And Attribute.Type.Types()[0] = Type("String") Then

					ChioceList.Add(Attribute.Name, Attribute.Presentation());

				EndIf;

			EndDo;
		Else
		
		EndIf;

	EndIf;
	Return ChioceList;
EndFunction // ()

// Returns a list of imported attribute links by type.
//
// Parameters:
//  ImportedAttribute - ValueTableRow - imported attribute.
//  VT - ValueTable - imported attributes table.
//
// Return value:
//  ValueList - list of link column names or link item references.
//
&AtServer
Function GetLinkByTypeList(ImportedAttribute, VT)

	ChoiceList = New ValueList;

	PossibleChartsOfAccounts = New Structure;
	For Each ChartOfAccounts In Metadata.ChartsOfAccounts Do
		Try
			If ChartOfAccounts.ExtDimensionTypes.Type = ImportedAttribute.TypeDescription Then

				PossibleChartsOfAccounts.Insert(ChartOfAccounts.Name, ChartsOfAccounts[ChartOfAccounts.Name]);

			EndIf;
		Except

		EndTry;
	EndDo;

	For Each ChartOfAccounts In PossibleChartsOfAccounts Do
		TypeOfChartOfAccounts = TypeOf(ChartOfAccounts.Value.EmptyRef());
		For Each LinkByTypeColumn In VT Do
			If LinkByTypeColumn.TypeDescription.Types()[0] = TypeOfChartOfAccounts Then
				ChoiceList.Add(LinkByTypeColumn.AttributeName, LinkByTypeColumn.AttributeName);
			EndIf;
		EndDo;
	EndDo;

	If Not PossibleChartsOfAccounts.Count() = 0 Then
		ChoiceList.Add(Undefined, NStr("ru = '< пустое значение >' en = '< empty value >'"));
	EndIf;

	For Each ChartOfAccounts In PossibleChartsOfAccounts Do
		ChoiceList.Add("ChartOfAccountsRef." + ChartOfAccounts.Key, "<" + ChartOfAccounts.Key + ">");
	EndDo;

	Return ChoiceList;
EndFunction // ()

// Returns a list of imported attribute links by owner.
//
// Parameters:
//  TypeDescription - type description.
//  ColumnTable - ValueTable - a table of link by owner columns.
//
// Return value:
//  ValueList - list of link column names or link item references.
//
&AtServer
Function GetLinkByOwnerList(TypeDescription, ColumnTable)

	ThisObjectTypeExists = False;
	SourceMetadata = GetSourceMetadata();
	If Object.ImportMode = 0 Then
		CatalogTypeDescription = Type(StrReplace(SourceMetadata.FullName(), ".", "Ref."));
	Else
		CatalogTypeDescription = Undefined;
	EndIf;

	ChoiceList = New ValueList;
	OwnerTypes = New Map;
	For Each ColumnType In TypeDescription.Types() Do
		If Catalogs.AllRefsType().ContainsType(ColumnType) Then
			For Each Owner In Metadata.FindByType(ColumnType).Owners Do
				OwnerType   = Type(StrReplace(Owner.FullName(), ".", "Ref."));
				If OwnerTypes[OwnerType] = Undefined Then

					If OwnerType = CatalogTypeDescription Then

						ThisObjectTypeExists = True;

					EndIf;

					OwnerTypes.Insert(Owner.FullName(), Owner.FullName());
					For Each LinkByOwnerColumn In ColumnTable Do
						If LinkByOwnerColumn.TypeDescription.Types()[0] = OwnerType
							And ChoiceList.FindByValue(LinkByOwnerColumn.AttributeName) = Undefined Then
							ChoiceList.Add(LinkByOwnerColumn.AttributeName,
								LinkByOwnerColumn.AttributeName);
						EndIf;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndDo;

	If Not OwnerTypes.Count() = 0 Then
		ChoiceList.Add(Undefined, NStr("ru = '< пустое значение >'; en = '< empty value >'"));
	EndIf;
	For Each KeyValue In OwnerTypes Do
		ChoiceList.Add(KeyValue.Value, "<" + KeyValue.Value + ">");
	EndDo;

	If ThisObjectTypeExists Then

		ChoiceList.Insert(0, NStr("ru = '<Создаваемый объект>'; en = '<This object>'"), NStr("ru = '<Создаваемый объект>'; en = '<This object>'"));

	EndIf;

	Return ChoiceList;

EndFunction // ()

// Returns a choice list cached in the attribute value table.
//
// Parameters:
//  AttributeName  - String - name of an attribute to get a related choice list.
//
// Return value:
//   ValueList - list of values to choice.
//
&AtServer
Function GetLinkByOwnerChoiceList(AttributeName)

	VT = FormAttributeToValue("LinkByOwnerChoiceLists");
	Str = VT.Find(AttributeName, "AttributeName");

	Return Str.ChioceList;

EndFunction // GetLinkByOwnerChoiceList()

// Saves an attribute chioce list to cache.
//
// Parameters:
//  AttributeName  - String - name of an attribute to save a related choice list.
//  NewChoiceList  - ValueList - list of values to save.
//
&AtServer
Procedure SaveLinkByOwnerChoiceList(AttributeName, Val NewChoiceList)

	VT = FormAttributeToValue("LinkByOwnerChoiceLists");
	Str = VT.Find(AttributeName, "AttributeName");
	Str.ChoiceList = NewChoiceList;
	ValueToFormAttribute(VT, "LinkByOwnerChoiceLists");

EndProcedure // SaveLinkByOwnerChoiceList()

&AtServer
Procedure FillControlServer()

	GenerateColumnsStructure();
	ItemCount = SpreadsheetDocument.TableHeight - Object.SpreadsheetDocumentFirstDataRow + 1;

	ErrorCount = 0;
	For K = 0 To ItemCount - 1 Do
		//Status(UT_StringFunctionsClientServer.SubstituteParametersToString(
		//NStr("ru = 'Выполняется контроль заполнения строки № %1'; en = 'Row no. %1 fill control is in progress.'"), (К + 1)));
		RowFillControl(SpreadsheetDocument, K + Object.SpreadsheetDocumentFirstDataRow, ,
			ErrorCount);
	EndDo;

	Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Контроль заполнения завершен. Проверено строк: %1'; en = 'Fill control completed. %1 rows was checked.'"), ItemCount));
	If ErrorCount Then
		Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выявлено ячеек, содержащих ошибки/неоднозначное представление: %1'; en = '%1 cells with errors/ambiguous presentation was found.'"), ErrorCount));
	Else
		Message(NStr("ru = 'Ячеек, содержащих ошибки не выявлено'; en = 'No error cell was found.'"));
	EndIf;

EndProcedure // FillControlServer()

////////////////////////////////////////////////////////////////////////////////
//

// Fills column settings by default or by passed settings.
//
// Parameters:
//  Settings - SpreadsheetDocument or Undefined.
//
&AtServer
Procedure FillColumnSettings(Settings)

	BeforeWriteObject   = "";
	OnWriteObject      = "";
	AfterAddRow = "";

	If TypeOf(Settings) = Type("SpreadsheetDocument") Then

		DataProcessorVersion = TrimAll(Settings.Area("R1C5").Text);
		If DataProcessorVersion = "1.2" Then
			CurrentRow = 11; //Attribute table start row
		ElsIf DataProcessorVersion = "1.3" Then
			CurrentRow = 11; //Attribute table start row			
		Else
			DataProcessorVersion = "1.1";
			CurrentRow = 9; //Attribute table start row
		EndIf;
		Try

			RestoredImportModeText = TrimAll(Settings.Area(?(DataProcessorVersion = "1.1", "R1", "R2")
				+ "C5").Text);
			If RestoredImportModeText = NStr("ru = 'в справочник'; en = 'to catalog'") Or RestoredImportModeText = "" Then
				RestoredImportMode = 0;
			ElsIf RestoredImportModeText = NStr("ru = 'в табличную часть'; en = 'to tabular section'") Or RestoredImportModeText = "Х" Then
				RestoredImportMode = 1;
			ElsIf RestoredImportModeText = NStr("ru = 'в регистр сведений'; en = 'to information register'") Then
				RestoredImportMode = 2;
			EndIf;

			ObjectMetadata = Metadata.FindByFullName(Settings.Area(?(DataProcessorVersion = "1.1", "R2", "R3")
				+ "C5").Text);
			If ObjectMetadata = Undefined Then
				Raise NStr("ru = 'Неправильный формат файла'; en = 'Invalid file format'");
			EndIf;

			If RestoredImportMode = 0 Then
				RestoredSourceRef = New (StrReplace(ObjectMetadata.FullName(), ".", "Ref."));
			ElsIf RestoredImportMode = 1 Then
				RestoredSourceRef = New (StrReplace(ObjectMetadata.Parent().FullName(), ".",
					"Ref."));
			Else
				RestoredSourceRef = Undefined;
			EndIf;
			
			//SourceRef = EmptyRef();
			DefaultsStructure = New Structure;
			CurrentAreaRow = "R" + Format(CurrentRow, "NG=");
			AttributeName = Settings.Area(CurrentAreaRow + "C2").Text;
			While Not IsBlankString(AttributeName) Do
				AttributeDefaultStructure = New Structure;
				AttributeDefaultStructure.Insert("AttributeName", AttributeName);
				AttributeDefaultStructure.Insert("Check", Not IsBlankString(Settings.Area(CurrentAreaRow
					+ "C1").Text));
				AttributeDefaultStructure.Insert("SearchField", Not IsBlankString(Settings.Area(
					CurrentAreaRow + "C3").Text));

				Types = New Array;
				TypeDescriptionString = Settings.Area(CurrentAreaRow + "C4").Text;
				For k = 1 To StrLineCount(TypeDescriptionString) Do

					sq = Undefined;
					nq = Undefined;
					dq = Undefined;
					TypeFractionsArray = mSplitStringIntoSubstringsArray(Lower(TrimAll(StrGetLine(
						TypeDescriptionString, k))), ",");
					If TypeFractionsArray.Count() = 0 Then
						Continue;
					ElsIf Find(TypeFractionsArray[0], ".") Then
						Type = Type(StrReplace(TypeFractionsArray[0], ".", "Ref."));
					ElsIf TypeFractionsArray[0] = NStr("ru = 'строка'; en = 'string'") Then
						Type = Type("String");
						If TypeFractionsArray.Count() = 2 Then
							sq = New StringQualifiers(mAdjustToNumber(TypeFractionsArray[1]),
								AllowedLength.Variable);
						ElsIf TypeFractionsArray.Count() = 3 Then
							sq = New StringQualifiers(mAdjustToNumber(TypeFractionsArray[1]),
								AllowedLength.Fixed);
						Else
							sq = New StringQualifiers;
						EndIf;
					ElsIf TypeFractionsArray[0] = NStr("ru = 'число'; en = 'number'") Then
						Type = Type("Number");
						nq = New NumberQualifiers(mAdjustToNumber(TypeFractionsArray[1]), mAdjustToNumber(
							TypeFractionsArray[2]), ?(TypeFractionsArray.Count() = 4, AllowedSign.Nonnegative,
							AllowedSign.Any));
					ElsIf TypeFractionsArray[0] = NStr("ru = 'булево'; en = 'boolean'") Then
						Type = Type("Boolean");
					ElsIf TypeFractionsArray[0] = NStr("ru = 'дата'; en = 'date'") Then
						Type = Type("Date");
						dq = New DateQualifiers(DateFractions.Date);
					ElsIf TypeFractionsArray[0] = NStr("ru = 'время'; en = 'time'") Then
						Type = Type("Date");
						dq = New DateQualifiers(DateFractions.Time);
					ElsIf TypeFractionsArray[0] = NStr("ru = 'дата и время'; en = 'date and time'") Then
						Type = Type("Date");
						dq = New DateQualifiers(DateFractions.DateTime);
					Else
						Continue;
					EndIf;
					Types.Add(Type);
				EndDo;
				TypeDescription = New TypeDescription(Types, nq, sq, dq);
				AttributeDefaultStructure.Insert("TypeDescription", TypeDescription);

				AttributeImportMode = Settings.Area(CurrentAreaRow + "C5").Text;

				AttributeDefaultStructure.Insert("ImportMode", AttributeImportMode);

				DefaultValue = Settings.Area(CurrentAreaRow + "C6").Text;
				AttributeDefaultStructure.Insert("DefaultValue", ?(IsBlankString(DefaultValue),
					TypeDescription.AdjustValue(Undefined), ValueFromStringInternal(DefaultValue)));

				If AttributeImportMode = "Evaluate" Then
					AttributeDefaultStructure.Insert("Expression", Settings.Area(CurrentAreaRow
						+ "C7").Text);
				Else
					AttributeDefaultStructure.Insert("SearchBy", Settings.Area(CurrentAreaRow
						+ "C7").Text);

					LinkByOwner   = Settings.Area(CurrentAreaRow + "C8").Text;
					AttributeDefaultStructure.Insert("LinkByOwner", ?(Left(LinkByOwner, 1) = "{",
						ValueFromStringInternal(LinkByOwner), LinkByOwner));

					LinkByType        = Settings.Area(CurrentAreaRow + "C9").Text;
					AttributeDefaultStructure.Insert("LinkByType", ?(Left(LinkByType, 1) = "{",
						ValueFromStringInternal(LinkByType), LinkByType));

					AttributeDefaultStructure.Insert("LinkByTypeItem", mAdjustToNumber(Settings.Area(
						CurrentAreaRow + "C10").Text));
				EndIf;
				If DataProcessorVersion = "1.3" Then
					AttributeDefaultStructure.Insert("ColumnNumber", mAdjustToNumber(Settings.Area(
						CurrentAreaRow + "C11").Text));
				EndIf;

				DefaultsStructure.Insert(AttributeName, AttributeDefaultStructure);
				CurrentRow = CurrentRow + 1;
				CurrentAreaRow = "R" + Format(CurrentRow, "NG=");
				AttributeName = Settings.Area(CurrentAreaRow + "C2").Text;

			EndDo;

		Except
			mErrorMessage(ErrorDescription());
		EndTry;
		
		//SourceMetadata = GetSourceMetadata();
		//If SourceMetadata = Undefined Then
		//	Return;
		//EndIf;

		Object.ImportMode   = RestoredImportMode;
		If RestoredImportMode = 0 Then
			Object.CatalogObjectType = ObjectMetadata.Name;
		ElsIf RestoredImportMode = 1 Then
			//Object.SourceRef = RestoredSourceRef;
			Object.SourceTabularSection = ?(RestoredImportMode, ObjectMetadata.Name, Undefined);
		ElsIf RestoredImportMode = 2 Then
			Object.RegisterTypeName = ObjectMetadata.Name;
		EndIf;
		Object.DontCreateNewItems                 = Not IsBlankString(Settings.Area(?(DataProcessorVersion = "1.1",
			"R3", "R4") + "C5").Text);
		Object.ReplaceExistingRecords = ?(DataProcessorVersion = "1.1", False, Not IsBlankString(Settings.Area(
			"R5C5").Text));
		Object.ManualSpreadsheetDocumentColumnsNumeration = Not IsBlankString(Settings.Area(?(DataProcessorVersion = "1.1",
			"R4", "R6") + "C5").Text);
		Object.SpreadsheetDocumentFirstDataRow     = mAdjustToNumber(Settings.Area(?(DataProcessorVersion = "1.1",
			"R5", "R7") + "C5").Text);

		Object.BeforeWriteObject = Settings.Area("R" + Format(CurrentRow + 2, "NG=") + "C3").Text;
		Object.OnWriteObject    = Settings.Area("R" + Format(CurrentRow + 3, "NG=") + "C3").Text;

		If Object.ImportMode Then
			Object.AfterAddRow = Settings.Area("R" + Format(CurrentRow + 4, "NG=") + "C3").Text;
		EndIf;

		CurrentRow = CurrentRow + 1;

	EndIf;
	Appearance = Undefined;
	//SourceMetadata = GetSourceMetadata();

	VT = FormAttributeToValue("ImportedAttributesTable");

	VT.Clear();

	If Object.ImportMode = 0 Then
		FillCatalogColumnSettings(VT);
	ElsIf Object.ImportMode = 1 Then
		FillTabularSectionColumnSettings(VT);
	ElsIf Object.ImportMode = 2 Then
		FillInformationRegisterColumnSettings(VT);
	EndIf;

	If Not DefaultsStructure = Undefined Then

		AppearanceColumnNumber = 0;
		ColumnNumber = 1;
		For Each KeyValue In DefaultsStructure Do
			Column = KeyValue.Value;
			ImportedAttribute = VT.Find(Column.AttributeName, "AttributeName");
			If Not ImportedAttribute = Undefined Then
				Index = VT.Index(ImportedAttribute);
				If Index >= AppearanceColumnNumber Then
					FillPropertyValues(ImportedAttribute, Column);

					VT.Move(ImportedAttribute, AppearanceColumnNumber - Index);
					If Column.Check And Not DataProcessorVersion = "1.3" Then
						ImportedAttribute.ColumnNumber = ColumnNumber;
						ColumnNumber = ColumnNumber + 1;
					EndIf;
					AppearanceColumnNumber = AppearanceColumnNumber + 1;

				EndIf;
			EndIf;

		EndDo;

	Else
		ColumnNumber = 1;
		For Each ImportedAttribute In VT Do

			ImportedAttribute.Check      = True;
			ImportedAttribute.ColumnNumber = ColumnNumber;
			ColumnNumber = ColumnNumber + 1;

		EndDo;

	EndIf;

	For Each ImportedAttribute In VT Do
		If ImportedAttribute.ImportMode = "Evaluate" Then
			ImportedAttribute.AdditionalConditionsPresentation = ImportedAttribute.Expression;
		Else
			ImportedAttribute.AdditionalConditionsPresentation = ?(IsBlankString(ImportedAttribute.SearchBy), "", NStr("ru = 'Искать по '; en = 'Search by '")
				+ ImportedAttribute.SearchBy) + ?(IsBlankString(ImportedAttribute.LinkByOwner), "",
				NStr("ru = ' по владельцу '; en = ' by owner '") + ImportedAttribute.LinkByOwner);
		EndIf;
	EndDo;

	ValueToFormAttribute(VT, "ImportedAttributesTable");

EndProcedure // ()

// Fills default column settings for tabular section.
//
&AtServer
Procedure FillTabularSectionColumnSettings(VT)

	SourceMetadata = GetSourceMetadata();

	If SourceMetadata = Undefined Then
		Return;
	EndIf;

	For Each Attribute In SourceMetadata.Attributes Do
		ImportedAttribute                        = VT.Add();
		ImportedAttribute.AttributeName           = Attribute.Name;
		ImportedAttribute.AttributePresentation = Attribute.Presentation();
		ImportedAttribute.TypeDescription = SourceMetadata.Attributes[ImportedAttribute.AttributeName].Type;
	EndDo;

	For Each ImportedAttribute In VT Do

		ChoiceList = GetNamePresentationList(ImportedAttribute.TypeDescription);
		ImportedAttribute.SearchBy = ?(ChoiceList.Count() = 0, "", ChoiceList[0].Value);

		ChoiceList = GetLinkByOwnerList(ImportedAttribute.TypeDescription, VT);
		ImportedAttribute.LinkByOwner = ?(ChoiceList.Count() = 0, "", ChoiceList[0].Value);

		ChoiceList = GetLinkByTypeList(ImportedAttribute, VT);
		If ChoiceList.Count() = 0 Then
			ImportedAttribute.LinkByType = "";
			ImportedAttribute.LinkByTypeItem = 0;
		Else
			ImportedAttribute.LinkByType = ChoiceList[0].Value;
			If Find(ImportedAttribute.AttributeName, "3") <> 0 Then

				ImportedAttribute.LinkByTypeItem = 3;

			ElsIf Find(ImportedAttribute.AttributeName, "2") <> 0 Then

				ImportedAttribute.LinkByTypeItem = 2;

			Else

				ImportedAttribute.LinkByTypeItem = 1;

			EndIf;

		EndIf;

		ImportedAttribute.DefaultValue = ImportedAttribute.TypeDescription.AdjustValue(Undefined);
		ImportedAttribute.AvailableTypes = ImportedAttribute.TypeDescription;
		ImportedAttribute.ImportMode = "Search";
	EndDo;

EndProcedure // ()

// Fills default column settings for catalog.
//
&AtServer
Procedure FillCatalogColumnSettings(VT)

	SourceMetadata = GetSourceMetadata();

	If SourceMetadata = Undefined Then
		Return;
	EndIf;

	If SourceMetadata.CodeLength > 0 Then

		ImportedAttribute = VT.Add();
		ImportedAttribute.AttributeName           = "Code";
		ImportedAttribute.AttributePresentation = "Code";
		ImportedAttribute.PossibleSearchField   =  True;

		If SourceMetadata.CodeType = Metadata.ObjectProperties.CatalogCodeType.String Then
			ImportedAttribute.TypeDescription = New TypeDescription("String", ,
				New StringQualifiers(SourceMetadata.CodeLength));
		Else
			ImportedAttribute.TypeDescription = New TypeDescription("Number", , ,
				New NumberQualifiers(SourceMetadata.CodeLength));
		EndIf;

	EndIf;

	If SourceMetadata.DescriptionLength > 0 Then

		ImportedAttribute = VT.Add();
		ImportedAttribute.AttributeName           = "Description";
		ImportedAttribute.AttributePresentation = "Description";
		ImportedAttribute.PossibleSearchField   =  True;
		ImportedAttribute.TypeDescription = New TypeDescription("String", ,
			New StringQualifiers(SourceMetadata.DescriptionLength));

	EndIf;

	If SourceMetadata.Owners.Count() > 0 Then

		ImportedAttribute = VT.Add();
		ImportedAttribute.AttributeName           = "Owner";
		ImportedAttribute.AttributePresentation = "Owner";
		ImportedAttribute.PossibleSearchField   =  True;

		TypeDescriptionString = "";

		For Each Owner In SourceMetadata.Owners Do
			TypeDescriptionString = ?(IsBlankString(TypeDescriptionString), "", TypeDescriptionString + ", ")
				+ Owner.FullName();
		EndDo;

		TypeDescriptionString = StrReplace(TypeDescriptionString, ".", "Ref.");
		ImportedAttribute.TypeDescription = New TypeDescription(TypeDescriptionString);

	EndIf;

	If SourceMetadata.Hierarchical Then

		ImportedAttribute = VT.Add();
		ImportedAttribute.AttributeName           = "Parent";
		ImportedAttribute.AttributePresentation = "Parent";
		ImportedAttribute.PossibleSearchField   = True;
		ImportedAttribute.TypeDescription = New TypeDescription(StrReplace(SourceMetadata.FullName(), ".",
			"Ref."));
		
		If SourceMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
			ImportedAttribute = VT.Add();
			ImportedAttribute.AttributeName           = "IsFolder";
			ImportedAttribute.AttributePresentation = "IsFolder";
			ImportedAttribute.PossibleSearchField   = True;
			ImportedAttribute.TypeDescription = New TypeDescription("Boolean");
		EndIf; 

	EndIf;

	For Each Attribute In SourceMetadata.Attributes Do
		If Not Attribute.Use = Metadata.ObjectProperties.AttributeUse.ForFolder Then
			ImportedAttribute                        = VT.Add();
			ImportedAttribute.AttributeName           = Attribute.Name;
			ImportedAttribute.AttributePresentation = Attribute.Presentation();
			ImportedAttribute.PossibleSearchField   = Not Attribute.Indexing
				= Metadata.ObjectProperties.Indexing.DontIndex;
			ImportedAttribute.TypeDescription = SourceMetadata.Attributes[ImportedAttribute.AttributeName].Type;
		EndIf;
	EndDo;

	For Each ImportedAttribute In VT Do

		ChoiceList = GetNamePresentationList(ImportedAttribute.TypeDescription);
		ImportedAttribute.SearchBy = ?(ChoiceList.Count() = 0, "", ChoiceList[0].Value);

		ChoiceList = GetLinkByOwnerList(ImportedAttribute.TypeDescription, VT);
		ImportedAttribute.LinkByOwner = ?(ChoiceList.Count() = 0, "", ChoiceList[0].Value);

		ChoiceList = GetLinkByTypeList(ImportedAttribute, VT);
		If ChoiceList.Count() = 0 Then
			ImportedAttribute.LinkByType = "";
			ImportedAttribute.LinkByTypeItem = 0;
		Else
			ImportedAttribute.LinkByType = ChoiceList[0].Value;
			If Find(ImportedAttribute.AttributeName, "3") <> 0 Then

				ImportedAttribute.LinkByTypeItem = 3;

			ElsIf Find(ImportedAttribute.AttributeName, "2") <> 0 Then

				ImportedAttribute.LinkByTypeItem = 2;

			Else

				ImportedAttribute.LinkByTypeItem = 1;

			EndIf;
		EndIf;

		ImportedAttribute.DefaultValue = ImportedAttribute.TypeDescription.AdjustValue(Undefined);
		ImportedAttribute.AvailableTypes = ImportedAttribute.TypeDescription;
		ImportedAttribute.ImportMode = "Search";
	EndDo;
EndProcedure // ()

// Fills default column settings for information register.
//
&AtServer
Procedure FillInformationRegisterColumnSettings(VT)

	SourceMetadata = GetSourceMetadata();

	If SourceMetadata = Undefined Then
		Return;
	EndIf;

	If Not SourceMetadata.InformationRegisterPeriodicity
		= Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then

		ImportedAttribute = VT.Add();
		ImportedAttribute.AttributeName           = "Period";
		ImportedAttribute.AttributePresentation = "Period";
		ImportedAttribute.PossibleSearchField = True;
		ImportedAttribute.SearchField           = True;

		ImportedAttribute.TypeDescription = New TypeDescription("Date", , , ,
			New DateQualifiers(DateFractions.DateTime));

	EndIf;

	For Each Attribute In SourceMetadata.Dimensions Do
		ImportedAttribute                        = VT.Add();
		ImportedAttribute.PossibleSearchField = True;
		ImportedAttribute.AttributeName           = Attribute.Name;
		ImportedAttribute.AttributePresentation = Attribute.Presentation();
		ImportedAttribute.TypeDescription = SourceMetadata.Dimensions[ImportedAttribute.AttributeName].Type;
	EndDo;

	For Each Attribute In SourceMetadata.Resources Do
		ImportedAttribute                        = VT.Add();
		ImportedAttribute.AttributeName           = Attribute.Name;
		ImportedAttribute.AttributePresentation = Attribute.Presentation();
		ImportedAttribute.TypeDescription = SourceMetadata.Resources[ImportedAttribute.AttributeName].Type;
	EndDo;

	For Each Attribute In SourceMetadata.Attributes Do
		ImportedAttribute                        = VT.Add();
		ImportedAttribute.AttributeName           = Attribute.Name;
		ImportedAttribute.AttributePresentation = Attribute.Presentation();
		ImportedAttribute.TypeDescription = SourceMetadata.Attributes[ImportedAttribute.AttributeName].Type;
	EndDo;

	For Each ImportedAttribute In VT Do

		ChoiceList = GetNamePresentationList(ImportedAttribute.TypeDescription);
		ImportedAttribute.SearchBy = ?(ChoiceList.Count() = 0, "", ChoiceList[0].Value);

		ChoiceList = GetLinkByOwnerList(ImportedAttribute.TypeDescription, VT);
		ImportedAttribute.LinkByOwner = ?(ChoiceList.Count() = 0, "", ChoiceList[0].Value);

		ChoiceList = GetLinkByTypeList(ImportedAttribute, VT);
		If ChoiceList.Count() = 0 Then
			ImportedAttribute.LinkByType = "";
			ImportedAttribute.LinkByTypeItem = 0;
		Else
			ImportedAttribute.LinkByType = ChoiceList[0].Value;
			If Find(ImportedAttribute.AttributeName, "3") <> 0 Then

				ImportedAttribute.LinkByTypeItem = 3;

			ElsIf Find(ImportedAttribute.AttributeName, "2") <> 0 Then

				ImportedAttribute.LinkByTypeItem = 2;

			Else

				ImportedAttribute.LinkByTypeItem = 1;

			EndIf;
		EndIf;

		ImportedAttribute.DefaultValue = ImportedAttribute.TypeDescription.AdjustValue(Undefined);
		ImportedAttribute.AvailableTypes = ImportedAttribute.TypeDescription;
		ImportedAttribute.ImportMode = "Search";
	EndDo;
EndProcedure // ()

// Generates a spreadsheet document with a data processor settings.
&AtServer
Function GetSettings()

	ObjectMetadata = GetSourceMetadata();

	If ObjectMetadata = Undefined Then
		Return Undefined;
	EndIf;

	ObjectType     = ObjectMetadata.FullName();

	ResultDocument = New SpreadsheetDocument;
	DataProcessorObject = FormAttributeToValue("Object");
	Template = DataProcessorObject.GetDataProcessorTemplate("SaveSettingsTemplate");

	HeaderArea = Template.GetArea("Header");
	If Object.ImportMode = 0 Then
		HeaderArea.Parameters.ImportMode = "to catalog";
	ElsIf Object.ImportMode = 1 Then
		HeaderArea.Parameters.ImportMode = "to tabular section";
	ElsIf Object.ImportMode = 2 Then
		HeaderArea.Parameters.ImportMode = "to information register";
	EndIf;

	HeaderArea.Parameters.ObjectType                                = ObjectType;
	HeaderArea.Parameters.DontCreateNewItems                 = ?(Object.DontCreateNewItems, "Х", "");
	HeaderArea.Parameters.ReplaceExistingRecords                 = ?(Object.ReplaceExistingRecords, "Х", "");
	HeaderArea.Parameters.ManualSpreadsheetDocumentColumnsNumeration = ?(
		Object.ManualSpreadsheetDocumentColumnsNumeration, "Х", "");
	HeaderArea.Parameters.SpreadsheetDocumentFirstDataRow     = Object.SpreadsheetDocumentFirstDataRow;

	ResultDocument.Put(HeaderArea);

	VT = FormAttributeToValue("ImportedAttributesTable");

	For Each ImportedAttribute In VT Do
		RowArea = Template.GetArea("Row" + ?(ImportedAttribute.ImportMode = "Evaluate", "Expression",
			""));

		RowArea.Parameters.Check      = ?(ImportedAttribute.Check, "Х", "");
		RowArea.Parameters.AttributeName = ImportedAttribute.AttributeName;
		RowArea.Parameters.SearchField   = ?(ImportedAttribute.SearchField, "Х", "");

		RowArea.Parameters.TypeDescription       = GetTypeDescription(ImportedAttribute.TypeDescription);

		RowArea.Parameters.ImportMode       = ImportedAttribute.ImportMode;
		If ImportedAttribute.TypeDescription.AdjustValue(Undefined) = ImportedAttribute.DefaultValue Then
			RowArea.Parameters.DefaultValue = "";
		Else
			RowArea.Parameters.DefaultValue = ValueToStringInternal(ImportedAttribute.DefaultValue);
		EndIf;

		If ImportedAttribute.ImportMode = "Evaluate" Then

			RowArea.Parameters.Expression           = ImportedAttribute.Expression;

		Else
			RowArea.Parameters.SearchBy            = ImportedAttribute.SearchBy;
			RowArea.Parameters.LinkByOwner    = ?(TypeOf(ImportedAttribute.LinkByOwner) = Type(
				"String"), ImportedAttribute.LinkByOwner, ValueToStringInternal(
				ImportedAttribute.LinkByOwner));
			RowArea.Parameters.LinkByType         = ?(TypeOf(ImportedAttribute.LinkByOwner) = Type("String"),
				ImportedAttribute.LinkByType, ValueToStringInternal(ImportedAttribute.LinkByType));
			RowArea.Parameters.LinkByTypeItem  = ImportedAttribute.LinkByTypeItem;
		EndIf;
		
		RowArea.Parameters.ColumnNumber			= ImportedAttribute.ColumnNumber;

		ResultDocument.Put(RowArea);

	EndDo;

	FooterArea = Template.GetArea("Events");
	FooterArea.Parameters.BeforeWriteObject = Object.BeforeWriteObject;
	FooterArea.Parameters.OnWriteObject = Object.OnWriteObject;
	ResultDocument.Put(FooterArea);
	If Object.ImportMode Then

		FooterArea = Template.GetArea("EventsAfterAddRow");
		FooterArea.Parameters.AfterAddRow = Object.AfterAddRow;
		ResultDocument.Put(FooterArea);

	EndIf;

	Return ResultDocument;

EndFunction

// Reads a MXL file with a data processor settings.
&AtServer
Function ReadSettingsAtServer(TempStorageAddress)

	Data = GetFromTempStorage(TempStorageAddress);

	TempFileName = GetTempFileName("mxl");
	TempDoc = New SpreadsheetDocument;
	Data.Write(TempFileName);
	TempDoc.Read(TempFileName);
	DeleteFiles(TempFileName);

	Return TempDoc;
EndFunction

// Returns a MXL file content with a data processor settings.
&AtClient
Function mReadSettingsFromFile(FileName)

	FileData = New BinaryData(FileName);

	FileAddress = "";
	FileAddress = PutToTempStorage(FileData, ThisForm.UUID);

	Return ReadSettingsAtServer(FileAddress);

EndFunction

&AtServer
Procedure CopySettings(Val Source, Destination)
	
	//If TypeOf(Source) = Type("FormDataCollection") Then
	//	Source = FormDataToValue(Source, Type("ValueTable"));
	//Else
	If Not TypeOf(Source) = Type("ValueTable") Then
		Return;
	EndIf;

	Destination.Clear();

	For Each Str In Source Do
		NewStr = Destination.Add();
		FillPropertyValues(NewStr, Str);
	EndDo;

EndProcedure

&AtServer
Procedure OnCloseAtServer()

	mSaveValue("ImportMode", Object.ImportMode);
	mSaveValue("SourceRef", Object.SourceRef);
	mSaveValue("SourceTabularSection", Object.SourceTabularSection);
	mSaveValue("RegisterTypeName", Object.RegisterTypeName);
	mSaveValue("CatalogObjectType", Object.CatalogObjectType);

EndProcedure // OnCloseAtServer()

////////////////////////////////////////////////////////////////////////////////
//

&AtServer
Procedure RefreshSpreadsheetDocumentDataServer()

	SpreadsheetDocument.Clear();

	GenerateColumnsStructure();
	GenerateSpreadsheetDocumentHeader(SpreadsheetDocument);

	RowNumber = Object.SpreadsheetDocumentFirstDataRow;

	SourceMetadata = GetSourceMetadata();
	If Object.ImportMode = 0 Or Object.ImportMode = 2 Or SourceMetadata = Undefined Then
		Return;
	EndIf;

	Source = Object.SourceRef[Object.SourceTabularSection];
	
	//VT = FormAttributeToValue("ImportedAttributesTable");

	For Each Row In Source Do

		ColumnNumber = 0;

		For Each ImportedAttribute In ImportedAttributesTable Do

			If ImportedAttribute.Check Then

				If Object.ManualSpreadsheetDocumentColumnsNumeration Then
					ColumnNumber = ImportedAttribute.ColumnNumber;
				Else
					ColumnNumber = ColumnNumber + 1;
				EndIf;

				Area = SpreadsheetDocument.Area("R" + Format(RowNumber, "NG=") + "C" + ColumnNumber);
				Value = Row[ImportedAttribute.AttributeName];

				Try
					Presentation = Value[ImportedAttribute.SearchBy];

				Except

					Presentation = Value;

				EndTry;

				Area.Text = Presentation;
				Area.Details = Value;

			EndIf;

		EndDo;

		RowNumber = RowNumber + 1;
	EndDo;

EndProcedure // RefreshSpreadsheetDocumentDataServer()

&AtClient
Procedure RefreshSpreadsheetDocumentData(Val Notification, WithoutQuestions = False)

	If (Object.ImportMode = 0 Or Object.ImportMode = 2) And Items.SpreadsheetDocument.Height > 1 And Not WithoutQuestions Then
		ShowQueryBox(New NotifyDescription("RefreshSpreadsheetDocumentDataCompletion", ThisForm,
			New Structure("Notification", Notification)), NStr("ru = 'Табличный документ содержит данные. Очистить?'; en = 'A spreadsheet document contains data. Do you want to clear it?'"),
			QuestionDialogMode.YesNo);
		Return;
	Else
		RefreshSpreadsheetDocumentDataServer();
	EndIf;

	RefreshSpreadsheetDocumentDataFragment(Notification);
EndProcedure

&AtClient
Procedure RefreshSpreadsheetDocumentDataCompletion(Result, AdditionalParameters) Export

	Notification = AdditionalParameters.Notification;
	If Result = DialogReturnCode.Yes Then
		RefreshSpreadsheetDocumentDataServer();
		ExecuteNotifyProcessing(Notification);
		Return;
	EndIf;

	RefreshSpreadsheetDocumentDataFragment(Notification);

EndProcedure

&AtClient
Procedure RefreshSpreadsheetDocumentDataFragment(Val Notification)

	ExecuteNotifyProcessing(Notification);

EndProcedure

// Imports a data from an Excel file to a spreadsheet document.
//
// Parameters:
//  FileName - String - a name of an Excel file to read.
//  ExcelSheetNumber - Number - a number of an Excel book sheet to read.
//
&AtClient
Procedure mImportSpreadsheetDocumentFromExcel(FileName, ExcelSheetNumber = 1) Export

	BeginCheckingFileExistence(FileName,
		New NotifyDescription("mImportSpreadsheetDocumentFromExcelCheckingFileExistenceCompletion", ThisObject,
		New Structure("FileName,ExcelSheetNumber", FileName, ExcelSheetNumber)));

EndProcedure // ()

&AtClient
Procedure mImportSpreadsheetDocumentFromExcelCheckingFileExistenceCompletion(Exist, AdditionalParameters) Export
	If Not Exist Then
		Message(NStr("ru = 'Файл не существует!'; en = 'File does not exist.'"));
		Return;
	EndIf;
	ExcelSheetNumber=AdditionalParameters.ExcelSheetNumber;
	FileName=AdditionalParameters.FileName;

	xlLastCell = 11;
	Try
		Excel = New COMObject("Excel.Application");
		Excel.WorkBooks.Open(FileName);
		Message(NStr("ru = 'Обработка файла Microsoft Excel...'; Microsoft Excel file is processed..."));
		ExcelSheet = Excel.Sheets(ExcelSheetNumber);
	Except
		Message(NStr("ru = 'Ошибка. Возможно неверно указан номер листа книги Excel.'; en = 'Cannot read the sheet. Probably the sheet number is incorrect.'"));
		Return;

	EndTry;

	SpreadsheetDocument = New SpreadsheetDocument;

	ActiveCell = Excel.ActiveCell.SpecialCells(xlLastCell);
	RowCount = ActiveCell.Row;
	ColumnCount = ActiveCell.Column;
	Для Column = 1 По ColumnCount Do
		SpreadsheetDocument.Area("C" + Format(Column, "NG=")).ColumnWidth = ExcelSheet.Columns(Column).ColumnWidth;
	EndDo;
	For Row = 1 To RowCount Do

		For Column = 1 To ColumnCount Do
			SpreadsheetDocument.Area("R" + Format(Row, "NG=") + "C" + Format(Column, "NG=")).Text = ExcelSheet.Cells(
				Row, Column).Text;
		EndDo;

	EndDo;

	Excel.WorkBooks.Close();
	Excel = 0;
EndProcedure

// Imports a data from a TXT file to a spreadsheet document.
//
// Parameters:
//  FileName - String - a name of a TXT file to read.
//
&AtClient
Procedure mImportSpreadsheetDocumentFromText(FileName) Export

	SelFile = New File(FileName);
	SelFile.BeginCheckingExistence(
		New NotifyDescription("mImportSpreadsheetDocumentFromTextCheckingFileExistenceCompletion", ThisForm,
		New Structure("FileName", FileName)));

EndProcedure

&AtClient
Procedure mImportSpreadsheetDocumentFromTextCheckingFileExistenceCompletion(Exist, AdditionalParameters) Export

	FileName = AdditionalParameters.FileName;
	If Exist Then
		TextDocument = New TextDocument;
		TextDocument.BeginReading(New NotifyDescription("mImportSpreadsheetDocumentFromTextCompletion",
			ThisObject, New Structure("TextDocument", TextDocument),
			"mImportSpreadsheetDocumentFromTextCompletionReadError", ThisObject), FileName);

	Else
		Message(NStr("ru = 'Файл не существует!'; en = 'File does not exist.'"));

	EndIf;

EndProcedure // ()

&AtClient
Procedure mImportSpreadsheetDocumentFromTextCompletion(AdditionalParameters) Export
	TextDocument=AdditionalParameters.TextDocument;

	SpreadsheetDocument = New SpreadsheetDocument;
	For CurrentLine = 1 To TextDocument.LineCount() Do
		CurrentColumn = 0;
		For Each Value In mSplitStringIntoSubstringsArray(TextDocument.GetLine(CurrentLine),
			Chars.Tab) Do
			CurrentColumn = CurrentColumn + 1;
			SpreadsheetDocument.Area("R" + Format(CurrentLine, "NG=") + "C" + Format(CurrentColumn,
				"NG=")).Text = Value;

		EndDo;

	EndDo;
EndProcedure

&AtClient
Procedure mImportSpreadsheetDocumentFromTextCompletionReadError(ErrorInfo, StandardProcessing,
	AdditionalParameters) Export
	StandardProcessing=False;
	Message(NStr("ru = 'Ошибка открытия файла!'; en = 'A file read error occured.'"));
EndProcedure

&AtClient
Procedure BeginCheckingFileExistence(FileName, CompletionNotifyDescription)
	SelFile = New File(FileName);
	SelFile.BeginCheckingExistence(CompletionNotifyDescription);
EndProcedure

// Imports a data from a dBase III (*.dbf) file to a spreadsheet document.
//
// Parameters:
//  FileName - String - a name of a dBase III file to read.
//
&AtClient
Procedure mImportSpreadsheetDocumentFromDBF(FileName) Export
	BeginCheckingFileExistence(FileName,
		New NotifyDescription("mImportSpreadsheetDocumentFromDBFCheckingFileExistenceCompletion", ThisObject,
		New Structure("FileName", FileName)));
EndProcedure // ()

&AtClient
Procedure mImportSpreadsheetDocumentFromDBFCheckingFileExistenceCompletion(Exist, AdditionalParameters) Export
	If Not Exist Then
		Message(NStr("ru = 'Файл не существует!'; en = 'File does not exist.'"));
		Return;
	EndIf;

#If Not WebClient Then

	FileName=AdditionalParameters.FileName;

	XBase  = New XBase;
	XBase.Encoding = PredefinedValue("XBaseEncoding.OEM");
	Try
		XBase.OpenFile(FileName);
	Except
		Message(NStr("ru = 'Ошибка открытия файла!'; en = 'A file read error occured.'"));
		Return;
	EndTry;

	SpreadsheetDocument = New SpreadsheetDocument;
	CurrentRow = 1;
	CurrentColumn = 0;
	For Each Field In XBase.Fields Do
		CurrentColumn = CurrentColumn + 1;
		SpreadsheetDocument.Area("R" + Format(CurrentRow, "NG=") + "C" + Format(CurrentColumn,
			"NG=")).Text = Field.Name;
	EndDo;
	Res = XBase.First();
	While Not XBase.EOF() Do
		CurrentRow = CurrentRow + 1;

		CurrentColumn = 0;
		For Each Field In XBase.Fields Do
			CurrentColumn = CurrentColumn + 1;
			SpreadsheetDocument.Area("R" + Format(CurrentRow, "NG=") + "C" + Format(CurrentColumn,
				"NG=")).Text = XBase.GetFieldValue(CurrentColumn - 1);
		EndDo;

		XBase.Next();
	EndDo;
#Else
		ShowMessageBox(Undefined, NStr("ru = 'Чтение DBF файлов недоступно в веб клиенте'; en = 'DBF file reading is not possible at web-client.'"));
#EndIf

EndProcedure

&AtServer
Procedure ReadSpreadsheetDocumentFromMXLAtServer(TempStorageAddress)

	Data = GetFromTempStorage(TempStorageAddress);

	TempFileName = GetTempFileName("mxl");

	Data.Write(TempFileName);
	SpreadsheetDocument.Read(TempFileName);
	DeleteFiles(TempFileName);

EndProcedure // ReadSpreadsheetDocumentFromMXLAtServer()

&AtClient
Procedure mReadSpreadsheetDocumentFromMXL(FileName)

	FileData = New BinaryData(FileName);

	FileAddress = "";
	FileAddress = PutToTempStorage(FileData, ThisForm.UUID);

	ReadSpreadsheetDocumentFromMXLAtServer(FileAddress);

EndProcedure // ()

////////////////////////////////////////////////////////////////////////////////
//

&AtClient
Procedure VisibilityControl()

	ImportMode = Object.ImportMode;
	ManualSpreadsheetDocumentColumnsNumeration = Object.ManualSpreadsheetDocumentColumnsNumeration;

	If ImportMode = 0 Then
		CurItem = Items.ImportToCatalogGroup;
	ElsIf ImportMode = 1 Then
		CurItem = Items.ImportToTabularSectionGroup;
	ElsIf ImportMode = 2 Then
		CurItem = Items.ImportToInformationRegisterGroup;
	Else
		Return; // Unknown mode.
	EndIf;
	If Не Items.ModeBarGroup.CurrentPage = CurItem Then
		Items.ModeBarGroup.CurrentPage = CurItem;
	EndIf;

	Items.ImportedAttributesTableSearchField.Visible         = ImportMode = 0;

	Items.DontCreateNewItems.Visible = ImportMode = 0;
	Items.ReplaceExistingRecords.Visible = ImportMode = 2;

	SaveValuesButtonAvailability    = SelectedMetadataExists();
	RestoreValuesButtonAvailability = False; //Not SavedSettingsList.Count() = 0;

	Items.SaveValues.Enabled = False; //SaveValuesButtonAvailability;
	Items.RestoreValues.Enabled = RestoreValuesButtonAvailability;

	Items.SaveValuesToFile.Enabled = SaveValuesButtonAvailability;

	Items.ImportedAttributesTableColumnNumber.Visible = ManualSpreadsheetDocumentColumnsNumeration;
	Items.RenumberColumns.Enabled = ManualSpreadsheetDocumentColumnsNumeration;
	Items.ManualSpreadsheetDocumentColumnsNumeration.Check = ManualSpreadsheetDocumentColumnsNumeration;

EndProcedure // VisibilityControl()

// Sets an attributes associated with a data source.
//
&AtServer
Procedure SetSource(SettingsList = Undefined)

	Source        = Undefined;
	SourceObject = Undefined;
	//SavedSettingsList.Clear();
	PreviousSourceReferenceMetadata = Undefined;
	SourceMetadata = GetSourceMetadata();
	If SourceMetadata = Undefined Then
		ImportedAttributesTable.Clear();
	Else
		Temp = mRestoreValue(SourceMetadata.FullName());
		//If Not SettingsList = Undefined Then
		//	CopySettings(Temp, SettingsList);
		//	Setting = GetDefaultSetting(SettingsList);
		//	RestoreSettingsFromList(Setting);
		//Else
		//	RestoreSettingsFromList(Undefined);
		FillColumnSettings(Undefined);
		//EndIf;
	EndIf;

	RefreshSpreadsheetDocumentDataServer();

	LinkByOwnerChoiceLists.Clear();

	VT = FormAttributeToValue("ImportedAttributesTable");

	For Each ImportedAttribute In VT Do

		ListRow = LinkByOwnerChoiceLists.Add();
		ListRow.AttributeName = ImportedAttribute.AttributeName;
		ListRow.ChoiceList = GetLinkByOwnerList(ImportedAttribute.TypeDescription, VT);
	EndDo;

EndProcedure

// Procedure выполняет инициализацию служебных переменных и констант модуля
//
&AtServer
Procedure Initialization()

	Object.AdditionalProperties = New Structure;

	Object.AdditionalProperties.Insert("PrimitiveTypes", New Structure("Number, String, Date, Boolean", Type(
		"Number"), Type("String"), Type("Date"), Type("Boolean")));

	If Object.SpreadsheetDocumentFirstDataRow < 2 Then
		Object.SpreadsheetDocumentFirstDataRow = 2;
	EndIf;

	Object.AdditionalProperties.Insert("Columns", New Structure);

EndProcedure // ()

///////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ КОМАНД

&AtClient
Procedure ImportCommand(Command)

	QuestionTextStructure = GetSourceQuestionText();
	ItemCount = SpreadsheetDocument.TableHeight - Object.SpreadsheetDocumentFirstDataRow + 1;
	If Not IsBlankString(QuestionTextStructure.Error) Then
		ShowMessageBox( , QuestionTextStructure.Error, , NStr("ru = 'Ошибка при загрузке!'; en = 'An import error occured.'"));
	Else
		ShowQueryBox(New NotifyDescription("ImportCommandCompletion", ThisForm), "Import "
			+ ItemCount + QuestionTextStructure.QuestionText, QuestionDialogMode.YesNo);
	EndIf;

EndProcedure

&AtClient
Procedure ImportCommandCompletion(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		ClearMessages();
		ImportDataServer();
	EndIf;

EndProcedure
&AtClient
Procedure OpenCommand(Command)

	FileDialog = New FileDialog(FileDialogMode.Open);

	FileDialog.Title = NStr("ru = 'Прочитать табличный документ из файла'; en = 'Import a spreadsheet document from file'");
	FileDialog.Filter    = NStr("ru = 'Табличный документ (*.mxl)|*.mxl|Лист Excel (*.xls,*.xlsx)|*.xls;*.xlsx|Текстовый документ (*.txt)|*.txt|dBase III (*.dbf)|*.dbf|';
								|en = 'Spreadsheet document (*.mxl)|*.mxl|Excel sheet (*.xls,*.xlsx)|*.xls;*.xlsx|Text document (*.txt)|*.txt|dBase III (*.dbf)|*.dbf|'");
	FileDialog.Show(New NotifyDescription("OpenCommandCompletion", ThisForm,
		New Structure("FileDialog", FileDialog)));

EndProcedure

&AtClient
Procedure OpenCommandCompletion(SelectedFiles, AdditionalParameters) Export

	FileDialog = AdditionalParameters.FileDialog;
	If (SelectedFiles <> Undefined) Then

		SpreadsheetDocument = Items.SpreadsheetDocument;
		FileOnDisk = New File(FileDialog.FullFileName);
		If Lower(FileOnDisk.Extension) = ".mxl" Then
			mReadSpreadsheetDocumentFromMXL(FileDialog.FullFileName);
		ElsIf Lower(FileOnDisk.Extension) = ".xls" Or Lower(FileOnDisk.Extension) = ".xlsx" Then
			mImportSpreadsheetDocumentFromExcel(FileDialog.FullFileName);
		ElsIf Lower(FileOnDisk.Extension) = ".txt" Then
			mImportSpreadsheetDocumentFromText(FileDialog.FullFileName);
		ElsIf Lower(FileOnDisk.Extension) = ".dbf" Then
			mImportSpreadsheetDocumentFromDBF(FileDialog.FullFileName);
		EndIf;
		VisibilityControl();
	EndIf;

EndProcedure

&AtClient
Procedure SaveCommand(Command)

	FileDialog = New FileDialog(FileDialogMode.Save);

	FileDialog.Title = NStr("ru = 'Сохранить табличный документ в файл'; en = 'Save a spreadsheet document to file'");
	FileDialog.Filter    = NStr("ru = 'Табличный документ (*.mxl)|*.mxl|Лист Excel (*.xls)|*.xls|Текстовый документ (*.txt)|*.txt|'
								|en = 'Spreadsheet document (*.mxl)|*.mxl|Excel sheet (*.xls)|*.xls|Text document (*.txt)|*.txt|'");
	FileDialog.Show(New NotifyDescription("SaveCommandCompletion", ThisForm,
		New Structure("FileDialog", FileDialog)));

EndProcedure

&AtClient
Procedure SaveCommandCompletion(SelectedFiles, AdditionalParameters) Export

	FileDialog = AdditionalParameters.FileDialog;
	If (SelectedFiles <> Undefined) Then

		SpreadsheetDocument = Items.SpreadsheetDocument;
		FileOnDisk = New File(FileDialog.FullFileName);
		If Lower(FileOnDisk.Extension) = ".mxl" Then
			SpreadsheetDocument.BeginWriting(Undefined, FileDialog.FullFileName,
				SpreadsheetDocumentFileType.MXL);
		ElsIf Lower(FileOnDisk.Extension) = ".xls" Then
			SpreadsheetDocument.BeginWriting(Undefined, FileDialog.FullFileName,
				SpreadsheetDocumentFileType.XLS);
		ElsIf Lower(FileOnDisk.Extension) = ".txt" Then
			SpreadsheetDocument.BeginWriting(Undefined, FileDialog.FullFileName,
				SpreadsheetDocumentFileType.TXT);
		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure RefreshCommand(Command)
	RefreshSpreadsheetDocumentData(Undefined);
EndProcedure

&AtClient
Procedure FillControlCommand(Command)
	FillControlServer();
EndProcedure

&AtClient
Procedure NextNoteCommand(Command)
	
	//SpreadsheetDocument = Items.SpreadsheetDocument;

	Found = False;

	Column = SpreadsheetDocument.CurrentArea.Left + 1;
	Row  = SpreadsheetDocument.CurrentArea.Top;

	While Not Found And Row <= SpreadsheetDocument.TableHeight Do

		While Not Found And Column <= SpreadsheetDocument.TableWidth Do

			Area = SpreadsheetDocument.Area("R" + Format(Row, "NG=") + "C" + Format(Column, "NG="));
			Found = Not IsBlankString(Area.Comment.Text);

			Column = Column + 1;
		EndDo;
		Row = Row + 1;
		Column = 1;
	EndDo;

	If Found Then
		SpreadsheetDocument.CurrentArea = Area;
	Else
		Message(NStr("ru = 'Достигнут конец документа'; en = 'End of document reached.'"), MessageStatus.Information);
	EndIf;

EndProcedure

&AtClient
Procedure PreviousNoteCommand(Command)
	
	//SpreadsheetDocument = Items.SpreadsheetDocument;

	Found = False;

	Column = SpreadsheetDocument.CurrentArea.Left - 1;
	Row  = SpreadsheetDocument.CurrentArea.Top;

	While Not Found And Row > 0 Do

		While Not Found And Column > 0 Do

			Area = SpreadsheetDocument.Area("R" + Format(Row, "NG=") + "C" + Format(Column, "NG="));
			Found = Not IsBlankString(Area.Comment.Text);

			Column = Column - 1;
		EndDo;
		Row = Row - 1;
		Column = SpreadsheetDocument.TableWidth;
	EndDo;

	If Found Then
		SpreadsheetDocument.CurrentArea = Area;
	Else
		Message(NStr("ru = 'Достигнуто начало документа'; en = 'Start of document reached.'"), MessageStatus.Information);
	EndIf;

EndProcedure

&AtClient
Procedure RestoreValuesFromFileCommand(Command)

	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Title	= NStr("ru = 'Восстановить значения из файла'; en = 'Restore values from file'");
	FileDialog.Filter	= NStr("ru = 'Настройка загрузки в табличный документ (*.mxlz)|*.mxlz|Все файлы (*.*)|*.*|'
							   |en = 'Spreadsheet document import settings (*.mxlz)|*.mxlz|All files (*.*)|*.*|'");

	FileDialog.Show(New NotifyDescription("RestoreValuesFromFileCommandCompletion1", ThisForm,
		New Structure("FileDialog", FileDialog)));

EndProcedure

&AtClient
Procedure RestoreValuesFromFileCommandCompletion1(SelectedFiles, AdditionalParameters) Export

	FileDialog = AdditionalParameters.FileDialog;
	If (SelectedFiles <> Undefined) Then
		Settings = mReadSettingsFromFile(FileDialog.FullFileName);
		FillColumnSettings(Settings);
		SetTabularSectionsList();
		RefreshSpreadsheetDocumentData(New NotifyDescription("RestoreValuesFromFileCommandCompletion",
			ThisForm), True);
	Else
		RestoreValuesFromFileCommandFragment();
	EndIf;

EndProcedure

&AtClient
Procedure RestoreValuesFromFileCommandCompletion(Result, AdditionalParameters) Export

	RestoreValuesFromFileCommandFragment();

EndProcedure

&AtClient
Procedure RestoreValuesFromFileCommandFragment()

	VisibilityControl();

EndProcedure

&AtClient
Procedure SaveValuesToFileCommand(Command)

	Settings = GetSettings();
	If Settings = Undefined Then
		Return;
	EndIf;

	FileDialog = New FileDialog(FileDialogMode.Save);

	FileDialog.Title = NStr("ru = 'Сохранить значения настройки в файл'; en = 'Save setting values to file'");
	FileDialog.Filter    = NStr("ru = 'Настройка загрузки в табличный документ (*.mxlz)|*.mxlz|Все файлы (*.*)|*.*|'
								|en = 'Spreadsheet document import settings (*.mxlz)|*.mxlz|All Files (*.*)|*.*|'");
	FileDialog.Show(New NotifyDescription("SaveValuesToFileCommandCompletion", ThisForm,
		New Structure("FileDialog, Settings", FileDialog, Settings)));

EndProcedure

&AtClient
Procedure SaveValuesToFileCommandCompletion(SelectedFiles, AdditionalParameters) Export

	FileDialog = AdditionalParameters.FileDialog;
	Settings = AdditionalParameters.Settings;
	If (SelectedFiles <> Undefined) Then

		Settings.BeginWriting(Undefined, FileDialog.FullFileName);

	EndIf;

EndProcedure

&AtClient
Procedure RestoreValuesCommand(Command)

	SelectSettingForm = GetForm(DataProcessorID() + ".Form.SelectSettingForm", , ThisForm);
	SelectSettingForm.SettingsList = SavedSettingsList;
	CurrentData = SelectSettingForm.Открыть();
	If Not CurrentData = Undefined Then
		FillColumnSettings(CurrentData.Value);
	EndIf;

	mSaveValue(DataProcessorID(), SelectSettingForm.SettingsList);

EndProcedure

&AtClient
Procedure SaveValuesCommand(Command)

	SaveSettingForm = GetForm(DataProcessorID() + ".Form.SaveSettingForm", , ThisForm);
	If Not SavedSettingsList.Count() = 0 Then
		//SaveSettingForm.SettingsList = SavedSettingsList;
		For Each Row In SavedSettingsList Do

			NewRow = SaveSettingForm.SettingsList.Add();
			NewRow.Check = Row.Check;
			NewRow.Presentation = Row.Presentation;

		EndDo;
	EndIf;

	CurrentData = SaveSettingForm.Open();

	If Not CurrentData = Undefined Then
		
		//GetSettingsList(CurrentData.Value);
		//CopySettings(SaveSettingForm.SettingsList);
		//SetCurrentSettings(SavedSettingsList, CurrentData.Check, CurrentData.Presentation, GetSettingsStructure());
		mSaveValue(DataProcessorID(), SavedSettingsList);

	EndIf;

EndProcedure

&AtClient
Procedure RereadCommand(Command)
	FillColumnSettings(Undefined);
EndProcedure

&AtClient
Procedure CheckAllCommand(Command)
	For Each ImportedAttribute In ImportedAttributesTable Do
		ImportedAttribute.Check = True;
	EndDo;
EndProcedure

&AtClient
Procedure UncheckAllCommand(Command)
	For Each ImportedAttribute In ImportedAttributesTable Do
		ImportedAttribute.Check = False;
	EndDo;
EndProcedure

&AtClient
Procedure ManualSpreadsheetDocumentColumnsNumerationCommand(Command)
	Items.ManualSpreadsheetDocumentColumnsNumeration.Check = Not Элементы.ManualSpreadsheetDocumentColumnsNumeration.Check;
	Object.ManualSpreadsheetDocumentColumnsNumeration = Items.ManualSpreadsheetDocumentColumnsNumeration.Check;
	VisibilityControl();
EndProcedure

&AtClient
Procedure RenumberColumnsCommand(Command)
	ColumnNumber = 1;
	For Each Attribute In ImportedAttributesTable Do
		If Attribute.Check Then
			If Not Attribute.ColumnNumber = ColumnNumber Then
				Attribute.ColumnNumber = ColumnNumber;
			EndIf;
			ColumnNumber = ColumnNumber + 1;
		Else
			Attribute.ColumnNumber = 0;
		EndIf;

		If Attribute.ColumnNumber = 0 And Attribute.ImportMode = "Search" Then
			Attribute.ImportMode = "Set";
		ElsIf Not Attribute.ColumnNumber = 0 And Attribute.ImportMode = "Set" Then
			Attribute.ImportMode = "Search";
		EndIf;

	EndDo;
EndProcedure

&AtClient
Procedure EventsCommand(Command)

	EditEventsForm = GetForm(DataProcessorID() + ".Form.EditEventsForm", ,
		ThisForm);

	EditEventsForm.ImportMode = Object.ImportMode;

	EditEventsForm.BeforeWriteObject.SetText(Object.BeforeWriteObject);
	EditEventsForm.OnWriteObject.SetText(Object.OnWriteObject);
	EditEventsForm.AfterAddRow.SetText(Object.AfterAddRow);

	EditEventsForm.Open();

	If True = True Then

		Object.BeforeWriteObject   = EditEventsForm.BeforeWriteObject.GetText();
		Object.OnWriteObject      = EditEventsForm.OnWriteObject.GetText();
		Object.AfterAddRow = EditEventsForm.AfterAddRow.GetText();

	EndIf;

EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_ExecuteToolsCommonCommand(Command) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ThisObject, Command);
EndProcedure



///////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	For Each MDCatalog In Metadata.Catalogs Do
		Items.ObjectType.ChoiceList.Add(MDCatalog.Name, MDCatalog.Synonym);
	EndDo;
	MDIndependent = Metadata.ObjectProperties.RegisterWriteMode.Independent;
	For Each MDInformationRegister In Metadata.InformationRegisters Do
		If MDInformationRegister.WriteMode = MDIndependent Then
			Items.RegisterTypeName.ChoiceList.Add(MDInformationRegister.Name, MDInformationRegister.Synonym);
		EndIf;
	EndDo;

	Types = New Array;
	TypeKinds = New Structure("Catalogs,Documents");
	For Each KeyValue In TypeKinds Do
		For Each MetadataObject In Metadata[KeyValue.Key] Do
			If MetadataObject.TabularSections.Count() Then
				Types.Add(Type(StrReplace(MetadataObject.FullName(), ".", "Ref.")));
			EndIf;
		EndDo;
	EndDo;

	Items.SourceRef.TypeRestriction = New TypeDescription(Types);

	Object.ImportMode           = mRestoreValue("ImportMode");
	Object.RegisterTypeName         = mRestoreValue("RegisterTypeName");
	Object.CatalogObjectType   = mRestoreValue("CatalogObjectType");
	Object.SourceRef         = mRestoreValue("SourceRef");

	SetTabularSectionsList();

	SourceTabularSection = mRestoreValue("SourceTabularSection");

	Initialization();

	SetSource();

	RefreshSpreadsheetDocumentDataServer();
	
	UT_Common.ToolFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SysInfo = New SystemInfo;
	If Left(SysInfo.AppVersion, 3) = "8.3" Then
		Execute ("Items.SourceRef.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInInputField;");
		Execute ("Items.ImportedAttributesTableDefaultValue.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInInputField;");
	EndIf;

	VisibilityControl();
EndProcedure

&AtClient
Procedure OnClose(Exit)
	OnCloseAtServer();
EndProcedure



///////////////////////////////////////////////////////////////////////////////
// FORM ITEMS EVENT HANDLERS

&AtClient
Procedure ImportModeOnChange(Item)
	Object.CatalogObjectType	= Undefined;
	Object.SourceRef			= Undefined;
	Object.RegisterTypeName			= Undefined;
	Object.SourceTabularSection	= Undefined;
	SetTabularSectionsList();
	SetSource();
	VisibilityControl();
EndProcedure

&AtClient
Procedure ObjectTypeOnChange(Item)
	SetSource();
	VisibilityControl();
EndProcedure

&AtClient
Procedure ObjectTypeOpening(Item, StandardProcessing)
	StandardProcessing = False;
	If IsBlankString(Object.CatalogObjectType) Then
		Return;
	EndIf;

	Form = GetForm("Catalog" + Object.CatalogObjectType + ".ListForm");
	Form.Open();
EndProcedure

&AtClient
Procedure SourceRefOnChange(Item)
	SetTabularSectionsList();
	SetSource();
EndProcedure

&AtClient
Procedure SourceTabularSectionOnChange(Item)
	SetSource();
	VisibilityControl();
EndProcedure

&AtClient
Procedure RegisterTypeNameOnChange(Item)
	SetSource();
	VisibilityControl();
EndProcedure

&AtClient
Procedure RegisterTypeNameOpening(Item, StandardProcessing)
	StandardProcessing = False;
	If IsBlankString(Object.RegisterTypeName) Then
		Return;
	EndIf;

	Form = GetForm("InformationRegister." + Object.RegisterTypeName + ".ListForm");
	Form.Open();
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// ImportedAttributesTable TABLE ITEMS EVENT HANDLERS

&AtClient
Procedure ImportedAttributesTableTypeDescriptionStartChoice(Item, ChoiceData, StandardProcessing)
	CurData = Items.ImportedAttributesTable.CurrentData;
	Item.AvailableTypes = CurData.AvailableTypes;
EndProcedure

&AtClient
Procedure ImportedAttributesTableAdditionalConditionsPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	CurData = Items.ImportedAttributesTable.CurrentData;
	StandardProcessing = False;
	If CurData.ImportMode = "Evaluate" Then
		EditExpressionForm = GetForm(DataProcessorID() + ".Form.EditExpressionForm", ,
			ThisForm);

		TextDocumentField = EditExpressionForm.TextDocumentField;
		TextDocumentField.SetText(CurData.Expression);

		EditExpressionForm.Open();
		//If EditExpressionForm.Open() = True Then
		//	CurData.Expression = TextDocumentField.GetText();
		//EndIf;
	Else
		AvailableTypes	= CurData.TypeDescription;
		OwnerChoiceList	= GetLinkByOwnerChoiceList(CurData.AttributeName);
		EditLinkForm = GetForm(DataProcessorID() + ".Form.EditLinkForm", ,
			ThisForm);
		EditLinkForm.UsedTypes = AvailableTypes;
		EditLinkForm.SearchBy = CurData.SearchBy;
		EditLinkForm.UseOwner = (OwnerChoiceList.Count() > 0);
		EditLinkForm.LinkByOwner = CurData.LinkByOwner;

		ChoiceListSearchBy = GetNamePresentationList(CurData.TypeDescription);
		List = EditLinkForm.Items.SearchBy.ChoiceList;
		List.Clear();
		For Each ListItem In ChoiceListSearchBy Do
			List.Add(ListItem.Value, ListItem.Presentation);
		EndDo;

		List = EditLinkForm.Item.LinkByOwner.ChoiceList;
		List.Clear();
		For Each ListItem In OwnerChoiceList Do
			List.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		EditLinkForm.Open();
		//If EditLinkForm.Open() = True Then
		//	CurData.SearchBy = EditLinkForm.SearchBy;
		//	CurData.LinkByOwner = EditLinkForm.LinkByOwner;
		//EndIf;
	EndIf;
	//If CurData.ImportMode = "Evaluate" Then
	//	CurData.AdditionalConditionsPresentation = CurData.Expression;
	//Else
	//	CurData.AdditionalConditionsPresentation = ?(IsBlankString(CurData.SearchBy), "", NStr("ru = 'Искать по '; en = 'Search by '")+CurData.SearchBy)
	//			+?(IsBlankString(CurData.LinkByOwner), "", NStr("ru = ' по владельцу '; en = ' by owner '")+CurData.LinkByOwner);
	//EndIf;
EndProcedure

&AtClient
Procedure ImportedAttributesTableAdditionalConditionsPresentationClearing(Item, StandardProcessing)
	CurData = Items.ImportedAttributesTable.CurrentData;
	CurData.AdditionalConditionsPresentation = "";
	CurData.SearchBy = "";
	CurData.LinkByOwner = "";
EndProcedure

&AtClient
Procedure ImportedAttributesTableImportModeOnChange(Item)
	CurData = Items.ImportedAttributesTable.CurrentData;
	If CurData.ImportMode = "Evaluate" Then
		CurData.AdditionalConditionsPresentation = CurData.Expression;
	Else
		CurData.AdditionalConditionsPresentation = ?(IsBlankString(CurData.SearchBy), "", NStr("ru = 'Искать по '; en = 'Search by '") + CurData.SearchBy)
			+ ?(IsBlankString(CurData.LinkByOwner), "", NStr("ru = ' по владельцу '; en = ' by owner '") + CurData.LinkByOwner);
	EndIf;
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	If TypeOf(SelectedValue) = Type("Structure") Then

		If SelectedValue.Source = "EditEventsForm" И SelectedValue.Result = True Then
			Object.BeforeWriteObject		= SelectedValue.BeforeWriteObject;
			Object.OnWriteObject			= SelectedValue.OnWriteObject;
			Object.AfterAddRow	= SelectedValue.AfterAddRow;
		ElsIf SelectedValue.Source = "EditExpressionForm" И SelectedValue.Result = True Then
			CurData = Items.ImportedAttributesTable.CurrentData;
			CurData.Expression = SelectedValue.Expression;
			CurData.AdditionalConditionsPresentation = CurData.Expression;
		ElsIf SelectedValue.Source = "EditLinkForm" И SelectedValue.Result = True Then
			CurData = Items.ImportedAttributesTable.CurrentData;
			CurData.SearchBy = SelectedValue.SearchBy;
			CurData.LinkByOwner = SelectedValue.LinkByOwner;
			CurData.AdditionalConditionsPresentation = ?(IsBlankString(CurData.SearchBy), "", NStr("ru = 'Искать по '; en = 'Search by '")
				+ CurData.SearchBy) + ?(IsBlankString(CurData.СвязьПоВладельцу), "", NStr("ru = ' по владельцу '; en = ' by owner '")
				+ CurData.LinkByOwner);
		EndIf;

	EndIf;
EndProcedure
